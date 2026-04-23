"""Scenario catalog loader and selector logic."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping

from omegaconf import OmegaConf

from .models import ModeFamily, ScenarioSpec, TheoremSpec
from .paths import REPO_ROOT

_LEGACY_MODE_FILE_NAMES = {
    "free": "Free.lean",
    "disable": "Disable.lean",
    "routeA": "RouteA.lean",
    "routeB": "RouteB.lean",
}


@dataclass(frozen=True)
class ScenarioCatalog:
    """场景目录对象，提供顺序遍历与选择器解析能力。"""

    test_scenarios: dict[str, ScenarioSpec]
    theorems: dict[str, TheoremSpec]
    scenarios: dict[str, ScenarioSpec]

    def ordered_scenarios(self) -> list[ScenarioSpec]:
        """
        函数 `ordered_scenarios` 返回固定顺序的场景列表。
        输入：
          - 无。
        输出：
          - list[ScenarioSpec] -- 按测试、题号和场景顺序排序后的场景列表。
        """
        ordered_keys: list[str] = []
        ordered_keys.extend(sorted(self.test_scenarios))
        for theorem_id in sorted(self.theorems, key=_theorem_sort_key):
            theorem = self.theorems[theorem_id]
            ordered_keys.extend(f"{theorem_id}.{scenario_name}" for scenario_name in theorem.scenario_order)
        return [self.scenarios[key] for key in ordered_keys]

    def resolve_selectors(self, selectors: Iterable[str]) -> list[ScenarioSpec]:
        """
        函数 `resolve_selectors` 把用户输入的选择器展开成具体场景列表。
        输入：
          - selectors: Iterable[str] -- 用户输入的场景选择器集合。
        输出：
          - list[ScenarioSpec] -- 按固定顺序展开后的场景列表。
        """
        selectors = list(selectors)
        if not selectors:
            return [self.scenarios["test.smoke"]]

        resolved: dict[str, ScenarioSpec] = {}
        for selector in selectors:
            if selector in {"all", "*"}:
                for scenario in self.ordered_scenarios():
                    resolved[scenario.scenario_key] = scenario
                continue
            if selector == "candidates":
                for key, scenario in self.scenarios.items():
                    if not key.startswith("test."):
                        resolved[key] = scenario
                continue
            if selector == "test":
                for key, scenario in self.test_scenarios.items():
                    resolved[key] = scenario
                continue
            if selector in self.scenarios:
                resolved[selector] = self.scenarios[selector]
                continue
            if selector in self.theorems:
                theorem = self.theorems[selector]
                for scenario_name in theorem.scenario_order:
                    scenario = self.scenarios[f"{selector}.{scenario_name}"]
                    resolved[scenario.scenario_key] = scenario
                continue
            raise KeyError(f"Unknown scenario selector: {selector}")
        return [resolved[key] for key in self.ordered_scenarios_keys(resolved.keys())]

    def ordered_scenarios_keys(self, keys: Iterable[str]) -> list[str]:
        """
        函数 `ordered_scenarios_keys` 依据标准排序返回给定键集合的有序子集。
        输入：
          - keys: Iterable[str] -- 需要排序的场景键集合。
        输出：
          - list[str] -- 有序的场景键列表。
        """
        key_set = set(keys)
        return [scenario.scenario_key for scenario in self.ordered_scenarios() if scenario.scenario_key in key_set]


def load_catalog(config_path: Path) -> ScenarioCatalog:
    """
    函数 `load_catalog` 从 YAML 文件加载完整场景目录。
    它会读取测试场景与候选定理元数据。
    其中测试场景仍可直接写 `prompt`，而正式候选题固定使用
    `free_instruction / disable_instruction / route_a / route_b` 四种 prompt 入口。
    输入：
      - config_path: Path -- 题目目录 YAML 文件路径。
    输出：
      - ScenarioCatalog -- 已解析完成的场景目录对象。
    """
    raw = OmegaConf.to_container(OmegaConf.load(config_path), resolve=True)
    assert isinstance(raw, dict)

    test_scenarios = {
        f"test.{test_id}": ScenarioSpec(
            scenario_key=f"test.{test_id}",
            scenario_name=str(test_id),
            theorem_id=f"test.{test_id}",
            target_file=str(test_data["target_file"]),
            theorem_name=str(test_data["theorem_name"]),
            mode_family=ModeFamily.TEST.value,
            user_comments=str(test_data["prompt"]).strip(),
            tags=tuple(test_data.get("tags", [])),
        )
        for test_id, test_data in raw.get("test_cases", {}).items()
    }

    theorems: dict[str, TheoremSpec] = {}
    scenarios: dict[str, ScenarioSpec] = dict(test_scenarios)
    candidate_raw = raw.get("candidate_theorems", {})
    for theorem_id, theorem_data in candidate_raw.items():
        theorem_key = str(theorem_id)
        theorem_mapping = _coerce_mapping(theorem_data, context=f"candidate_theorems.{theorem_key}")
        scenario_payloads = _scenario_payloads_for_theorem(theorem_mapping)
        theorem = TheoremSpec(
            theorem_id=theorem_key,
            free_instruction=str(theorem_mapping.get("free_instruction", "")).strip(),
            disable_instruction=str(theorem_mapping.get("disable_instruction", "")).strip(),
            route_a=_load_route_instruction(theorem_mapping, "route_a"),
            route_b=_load_route_instruction(theorem_mapping, "route_b"),
            scenario_order=tuple(scenario_payloads.keys()),
        )
        theorems[theorem.theorem_id] = theorem
        scenarios.update(_load_candidate_scenarios(theorem, scenario_payloads))

    return ScenarioCatalog(
        test_scenarios=test_scenarios,
        theorems=theorems,
        scenarios=scenarios,
    )


def default_catalog_path(path_from_settings: str) -> Path:
    """
    函数 `default_catalog_path` 解析题目目录配置文件的绝对路径。
    输入：
      - path_from_settings: str -- 项目设置中的目录路径字符串。
    输出：
      - Path -- 解析完成的绝对路径。
    """
    candidate = Path(path_from_settings)
    if candidate.is_absolute():
        return candidate.resolve()
    return (REPO_ROOT / candidate).resolve()


def _load_route_instruction(theorem_data: Mapping[str, Any], field_name: str) -> str:
    """
    函数 `_load_route_instruction` 读取候选题的单条路线提示文本。
    当前候选题 YAML 中 `route_a` / `route_b` 都应是纯文本字符串。
    输入：
      - theorem_data: Mapping[str, Any] -- 单个候选定理的原始 YAML 数据。
      - field_name: str -- 路线字段名，只允许 `route_a` 或 `route_b`。
    输出：
      - str -- 该路线对应的提示文本。
    """
    if field_name not in {"route_a", "route_b"}:
        raise ValueError(f"Unsupported route field: {field_name}")

    if "routes" in theorem_data:
        raise ValueError(
            "candidate_theorems 现在不再支持 `routes:` 写法；请只使用 `route_a:` 和 `route_b:`。"
        )

    if field_name not in theorem_data:
        raise ValueError(
            f"candidate_theorems 缺少必需路线字段：{field_name}。"
            "每个候选题都应显式提供 `route_a` 和 `route_b`。"
        )

    raw = theorem_data[field_name]
    if not isinstance(raw, str):
        raise TypeError(
            f"candidate_theorems.{field_name} 必须是字符串提示文本，不再支持嵌套字典。"
        )
    return raw.strip()


def _scenario_payloads_for_theorem(
    theorem_data: Mapping[str, Any],
) -> dict[str, Mapping[str, Any]]:
    """
    函数 `_scenario_payloads_for_theorem` 为候选题固定构造四个标准场景。
    当前候选题 YAML 不再支持自定义 `scenarios` 扩展写法，以保持 prompt 入口只有
    `free_instruction / disable_instruction / route_a / route_b` 这四类字段。
    输入：
      - theorem_data: Mapping[str, Any] -- 单个候选定理的原始 YAML 数据。
    输出：
      - dict[str, Mapping[str, Any]] -- 固定四模式场景的原始数据映射。
    """
    if "scenarios" in theorem_data:
        raise ValueError(
            "candidate_theorems 现在不再支持 `scenarios:` 写法；"
            "请把题目级 prompt 只写在 `free_instruction`、`disable_instruction`、`route_a`、`route_b` 中。"
        )

    return {
        "free": {
            "mode_family": ModeFamily.FREE.value,
            "file_name": _LEGACY_MODE_FILE_NAMES["free"],
        },
        "disable": {
            "mode_family": ModeFamily.DISABLE.value,
            "file_name": _LEGACY_MODE_FILE_NAMES["disable"],
        },
        "routeA": {
            "mode_family": ModeFamily.GUIDED.value,
            "route_hint": "routeA",
            "file_name": _default_guided_file_name("routeA"),
        },
        "routeB": {
            "mode_family": ModeFamily.GUIDED.value,
            "route_hint": "routeB",
            "file_name": _default_guided_file_name("routeB"),
        },
    }


def _load_candidate_scenarios(
    theorem: TheoremSpec,
    scenario_payloads: Mapping[str, Mapping[str, Any]],
) -> dict[str, ScenarioSpec]:
    """
    函数 `_load_candidate_scenarios` 解析单个候选定理下的全部实验场景。
    输入：
      - theorem: TheoremSpec -- 单个候选定理的结构化元数据。
      - scenario_payloads: Mapping[str, Mapping[str, Any]] -- 原始场景定义。
    输出：
      - dict[str, ScenarioSpec] -- 场景键到场景对象的映射。
    """
    theorem_root = f"ATP/temTH/CandidateTheorems/{theorem.theorem_id}"
    built: dict[str, ScenarioSpec] = {}
    for scenario_name, scenario_data in scenario_payloads.items():
        scenario_key = f"{theorem.theorem_id}.{scenario_name}"
        target_file = str(
            scenario_data.get(
                "target_file",
                f"{theorem_root}/{scenario_data['file_name']}",
            )
        )
        mode_family = str(scenario_data.get("mode_family", scenario_name))
        route_hint = scenario_data.get("route_hint")
        if route_hint is None and mode_family == ModeFamily.GUIDED.value and scenario_name in {"routeA", "routeB"}:
            route_hint = scenario_name
        scenario_user_comments = scenario_data.get("user_comments")
        if scenario_user_comments is None and "prompt" in scenario_data:
            scenario_user_comments = scenario_data["prompt"]

        built[scenario_key] = ScenarioSpec(
            scenario_key=scenario_key,
            scenario_name=scenario_name,
            theorem_id=theorem.theorem_id,
            target_file=target_file,
            theorem_name=str(
                scenario_data.get(
                    "theorem_name",
                    f"candidate_{theorem.theorem_id}_{scenario_name}",
                )
            ),
            mode_family=mode_family,
            route_hint=str(route_hint) if route_hint is not None else None,
            theorem=theorem,
            user_comments=str(scenario_user_comments or "").strip(),
            tags=tuple(scenario_data.get("tags") or [theorem.theorem_id, scenario_name]),
        )
    return built


def _default_guided_file_name(route_key: str) -> str:
    """
    函数 `_default_guided_file_name` 为引导路线场景生成默认模板文件名。
    输入：
      - route_key: str -- 路线键。
    输出：
      - str -- 默认模板文件名。
    """
    if route_key.startswith("route") and len(route_key) > len("route"):
        suffix = route_key[len("route") :]
        return f"Route{suffix}.lean"
    return f"{route_key}.lean"


def _coerce_mapping(raw: Any, context: str) -> Mapping[str, Any]:
    """
    函数 `_coerce_mapping` 验证给定对象是否为字典映射。
    输入：
      - raw: Any -- 待验证对象。
      - context: str -- 错误信息中的上下文描述。
    输出：
      - Mapping[str, Any] -- 通过验证后的映射对象。
    """
    if not isinstance(raw, Mapping):
        raise TypeError(f"Expected mapping for {context}, got {type(raw).__name__}")
    return raw


def _theorem_sort_key(theorem_id: str) -> tuple[int, str]:
    """
    函数 `_theorem_sort_key` 生成候选定理编号的稳定排序键。
    输入：
      - theorem_id: str -- 定理编号，例如 `T10`。
    输出：
      - tuple[int, str] -- 用于排序的键。
    """
    if theorem_id.startswith("T") and theorem_id[1:].isdigit():
        return (int(theorem_id[1:]), theorem_id)
    return (10**9, theorem_id)
