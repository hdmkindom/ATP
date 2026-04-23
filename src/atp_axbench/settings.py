"""Project-level YAML settings."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from omegaconf import OmegaConf

from .paths import CONFIG_ROOT


@dataclass(frozen=True)
class ExecutionSettings:
    """执行期相关配置。"""

    prebuild_repo: bool = True
    restore_source_after_run: bool = True
    default_repeats: int = 1
    persist_successful_proofs: bool = False
    persist_last_attempt_on_failure: bool = False
    disable_langsmith_tracing: bool = True
    archive_source_snapshots: bool = True
    archive_iteration_snapshots: bool = True
    max_llm_requests_per_attempt: int = 0


@dataclass(frozen=True)
class ConsoleSettings:
    """终端展示与日志外观配置。"""

    enable_color: bool = True
    show_banner: bool = True
    suppress_known_build_fallback_warning: bool = True


@dataclass(frozen=True)
class RuntimeStatusSettings:
    """运行状态与简单时间预测配置。"""

    enabled: bool = True
    show_time: bool = True
    history_file: str = "ATP/artifacts/runtime_history.json"
    default_seconds_per_formal_scenario: float = 180.0


@dataclass(frozen=True)
class ProjectSettings:
    """ATP 项目的总配置对象。"""

    catalog_path: str = "ATP/config/theorem_catalog.yaml"
    experiment_ax_config: tuple[str, ...] = ("ATP/config/ax_prover_experiment.yaml",)
    doctor_ax_config: tuple[str, ...] = ("ATP/config/ax_prover_doctor.yaml",)
    artifacts_dir: str = "ATP/artifacts"
    execution: ExecutionSettings = field(default_factory=ExecutionSettings)
    console: ConsoleSettings = field(default_factory=ConsoleSettings)
    runtime_status: RuntimeStatusSettings = field(default_factory=RuntimeStatusSettings)


def load_project_settings(config_path: Path | None = None) -> ProjectSettings:
    """
    函数 `load_project_settings` 从 YAML 文件加载 ATP 项目设置。
    它负责解析项目总配置、执行配置、终端配置与简单运行状态配置，并组装成 `ProjectSettings`。
    输入：
      - config_path: Path | None -- 可选的项目配置文件路径；为空时使用默认配置文件。
    输出：
      - ProjectSettings -- 已解析完成的项目设置对象。
    """
    raw_path = config_path or CONFIG_ROOT / "project.yaml"
    raw = OmegaConf.to_container(OmegaConf.load(raw_path), resolve=True)
    assert isinstance(raw, dict)

    execution_raw = raw.get("execution", {})
    console_raw = raw.get("console", {})
    runtime_status_raw = raw.get("runtime_status", {})
    return ProjectSettings(
        catalog_path=str(raw.get("catalog_path", "ATP/config/theorem_catalog.yaml")),
        experiment_ax_config=tuple(raw.get("experiment_ax_config", [])),
        doctor_ax_config=tuple(raw.get("doctor_ax_config", [])),
        artifacts_dir=str(raw.get("artifacts_dir", "ATP/artifacts")),
        execution=ExecutionSettings(
            prebuild_repo=bool(execution_raw.get("prebuild_repo", True)),
            restore_source_after_run=bool(execution_raw.get("restore_source_after_run", True)),
            default_repeats=int(execution_raw.get("default_repeats", 1)),
            persist_successful_proofs=bool(
                execution_raw.get("persist_successful_proofs", False)
            ),
            persist_last_attempt_on_failure=bool(
                execution_raw.get("persist_last_attempt_on_failure", False)
            ),
            disable_langsmith_tracing=bool(
                execution_raw.get("disable_langsmith_tracing", True)
            ),
            archive_source_snapshots=bool(
                execution_raw.get("archive_source_snapshots", True)
            ),
            archive_iteration_snapshots=bool(
                execution_raw.get("archive_iteration_snapshots", True)
            ),
            max_llm_requests_per_attempt=int(
                execution_raw.get("max_llm_requests_per_attempt", 0)
            ),
        ),
        console=ConsoleSettings(
            enable_color=bool(console_raw.get("enable_color", True)),
            show_banner=bool(console_raw.get("show_banner", True)),
            suppress_known_build_fallback_warning=bool(
                console_raw.get("suppress_known_build_fallback_warning", True)
            ),
        ),
        runtime_status=RuntimeStatusSettings(
            enabled=bool(runtime_status_raw.get("enabled", True)),
            show_time=bool(runtime_status_raw.get("show_time", True)),
            history_file=str(
                runtime_status_raw.get("history_file", "ATP/artifacts/runtime_history.json")
            ),
            default_seconds_per_formal_scenario=float(
                runtime_status_raw.get("default_seconds_per_formal_scenario", 180.0)
            ),
        ),
    )
