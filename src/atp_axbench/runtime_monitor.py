"""Simple run-time progress and ETA tracking for ATP batches."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
import json
from pathlib import Path
import time
from typing import Any

from .console import format_duration, print_error, print_info, print_status, render_banner_block
from .models import ScenarioResult, ScenarioSpec
from .paths import REPO_ROOT
from .settings import ConsoleSettings, RuntimeStatusSettings


@dataclass
class RuntimeHistory:
    """运行时间历史文件的内存表示。"""

    version: int = 2
    last_updated_at: str | None = None
    seconds_per_formal_scenario: float | None = None
    recorded_formal_runs: int = 0
    recent_formal_runs: list[dict[str, Any]] = field(default_factory=list)


class BatchProgressTracker:
    """负责欢迎横幅、简单 ETA 预测与每题结束后的时间状态打印。"""

    def __init__(
        self,
        runtime_status: RuntimeStatusSettings,
        console: ConsoleSettings,
        scenarios: list[ScenarioSpec],
        repeats: int,
        ax_config,
        max_llm_requests_per_attempt: int = 0,
    ) -> None:
        self.runtime_status = runtime_status
        self.console = console
        self.scenarios = scenarios
        self.repeats = repeats
        self.ax_config = ax_config
        self.max_llm_requests_per_attempt = max_llm_requests_per_attempt
        self.started_at = time.perf_counter()
        self.history_path = (REPO_ROOT / runtime_status.history_file).resolve()
        self.history = load_runtime_history(self.history_path)
        self.completed_formal_attempts = 0
        self.completed_formal_seconds = 0.0
        self.total_attempts = len(scenarios) * repeats
        self.total_formal_attempts = sum(0 if _is_test_scenario(scenario) else 1 for scenario in scenarios) * repeats

    def print_banner(self) -> None:
        """
        函数 `print_banner` 打印本次运行的欢迎横幅与总体预估。
        输入：
          - 无。
        输出：
          - None -- 横幅直接打印到终端。
        """
        if not self.console.show_banner:
            return

        estimated_total_seconds, estimate_source = self.initial_estimate_seconds()
        lines = [
            "欢迎使用 ax-prover—ATP",
            f"本次使用的模型：{self.ax_config.prover.prover_llm.model}",
            f"最大证明轮次：{getattr(self.ax_config.prover, 'max_iterations', 0)}",
            "单次尝试模型请求上限："
            + (
                str(self.max_llm_requests_per_attempt)
                if self.max_llm_requests_per_attempt > 0
                else "不限制"
            ),
            f"运行轮数：{self.repeats}",
            f"场景尝试数量：总计 {self.total_attempts}，正式 {self.total_formal_attempts}",
            f"本次运行预估所需时间：{format_duration(estimated_total_seconds)}（{estimate_source}）",
            "作者：刘泽博",
        ]
        print(render_banner_block(lines, enable_color=self.console.enable_color), flush=True)

    def before_scenario(self, scenario: ScenarioSpec, attempt_index: int, divider: str) -> None:
        """
        函数 `before_scenario` 在场景开始前打印短分隔条。
        输入：
          - scenario: ScenarioSpec -- 当前场景。
          - attempt_index: int -- 当前重复编号。
          - divider: str -- 已格式化好的分隔条。
        输出：
          - None -- 分隔信息直接打印到终端。
        """
        print_status(divider, enable_color=self.console.enable_color)

    def after_scenario(
        self,
        result: ScenarioResult,
        scenario: ScenarioSpec,
        attempt_index: int,
    ) -> None:
        """
        函数 `after_scenario` 在单个场景完成后打印结果与时间状态。
        输入：
          - result: ScenarioResult -- 当前场景结果。
          - scenario: ScenarioSpec -- 当前场景描述。
          - attempt_index: int -- 当前重复编号。
        输出：
          - None -- 状态直接打印到终端。
        """
        del attempt_index
        elapsed_total = time.perf_counter() - self.started_at
        if not _is_test_scenario(scenario):
            self.completed_formal_attempts += 1
            self.completed_formal_seconds += result.elapsed_seconds

        summary = (
            f"{'✓' if result.valid else 'X'} {result.scenario_key} "
            f"attempt={result.attempt_index} "
            f"prover_iters={result.iterations} "
            f"success={result.success} valid={result.valid}"
        )
        if result.max_iterations_reached:
            summary += " maxed=True"

        if result.valid:
            print_info(summary, enable_color=self.console.enable_color)
        else:
            print_error(summary, enable_color=self.console.enable_color)
            if result.error:
                print_error(
                    f"X error: {_condense_error(result.error)}",
                    enable_color=self.console.enable_color,
                )

        if self.runtime_status.show_time:
            print_status(
                "TIME "
                f"已运行 {format_duration(elapsed_total)} | "
                f"当前题目 {format_duration(result.elapsed_seconds)} | "
                f"剩余预估 {format_duration(self.remaining_seconds_estimate())}",
                enable_color=self.console.enable_color,
            )

    def batch_metadata(self) -> dict[str, Any]:
        """
        函数 `batch_metadata` 返回本次运行可写入汇总文件的附加元信息。
        输入：
          - 无。
        输出：
          - dict[str, Any] -- 可并入 summary 元数据的键值字典。
        """
        estimated_total_seconds, estimate_source = self.initial_estimate_seconds()
        return {
            "elapsed_seconds": round(time.perf_counter() - self.started_at, 3),
            "estimated_total_seconds": round(estimated_total_seconds, 3),
            "estimate_source": estimate_source,
        }

    def finalize(self) -> None:
        """
        函数 `finalize` 在批量运行结束后写回新的简单平均时间估计。
        输入：
          - 无。
        输出：
          - None -- 结果写回到历史 JSON 文件。
        """
        if self.total_formal_attempts <= 0 or self.completed_formal_attempts <= 0:
            return

        average_seconds = self.completed_formal_seconds / self.completed_formal_attempts
        self.history.last_updated_at = datetime.now().isoformat()
        self.history.recorded_formal_runs += 1
        self.history.recent_formal_runs.append(
            {
                "timestamp": self.history.last_updated_at,
                "formal_attempts": self.completed_formal_attempts,
                "elapsed_seconds": round(self.completed_formal_seconds, 3),
                "average_seconds_per_scenario": round(average_seconds, 3),
            }
        )
        self.history.recent_formal_runs = self.history.recent_formal_runs[-20:]
        averages = [
            float(run["average_seconds_per_scenario"])
            for run in self.history.recent_formal_runs
            if run.get("average_seconds_per_scenario") is not None
        ]
        self.history.seconds_per_formal_scenario = (
            sum(averages) / len(averages) if averages else average_seconds
        )
        write_runtime_history(self.history_path, self.history)

    def initial_estimate_seconds(self) -> tuple[float, str]:
        """
        函数 `initial_estimate_seconds` 计算横幅中使用的初始总时长估计。
        输入：
          - 无。
        输出：
          - tuple[float, str] -- 第一项为估计秒数，第二项为估计来源说明。
        """
        if self.total_formal_attempts <= 0:
            return 0.0, "仅测试场景，不计入正式题估时"

        baseline = self.history.seconds_per_formal_scenario
        if baseline is None:
            baseline = self.runtime_status.default_seconds_per_formal_scenario
            source = "默认估计"
        else:
            source = "历史平均"
        return baseline * self.total_formal_attempts, source

    def remaining_seconds_estimate(self) -> float:
        """
        函数 `remaining_seconds_estimate` 计算当前运行剩余时间的简单动态估计。
        输入：
          - 无。
        输出：
          - float -- 剩余估计秒数。
        """
        remaining_formal_attempts = max(0, self.total_formal_attempts - self.completed_formal_attempts)
        if remaining_formal_attempts <= 0:
            return 0.0

        if self.completed_formal_attempts > 0:
            current_average = self.completed_formal_seconds / self.completed_formal_attempts
            return current_average * remaining_formal_attempts

        baseline = (
            self.history.seconds_per_formal_scenario
            or self.runtime_status.default_seconds_per_formal_scenario
        )
        return baseline * remaining_formal_attempts


def load_runtime_history(path: Path) -> RuntimeHistory:
    """
    函数 `load_runtime_history` 从历史文件中读取时间估计数据。
    输入：
      - path: Path -- 历史 JSON 文件路径。
    输出：
      - RuntimeHistory -- 解析后的历史对象。
    """
    if not path.exists():
        return RuntimeHistory()
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return RuntimeHistory()

    return RuntimeHistory(
        version=int(payload.get("version", 1)),
        last_updated_at=payload.get("last_updated_at"),
        seconds_per_formal_scenario=payload.get("seconds_per_formal_scenario")
        or payload.get("formal_seconds_per_scenario_ewma"),
        recorded_formal_runs=int(payload.get("recorded_formal_runs", 0)),
        recent_formal_runs=list(payload.get("recent_formal_runs", [])),
    )


def write_runtime_history(path: Path, history: RuntimeHistory) -> None:
    """
    函数 `write_runtime_history` 将时间估计历史对象写回到 JSON 文件。
    输入：
      - path: Path -- 历史文件路径。
      - history: RuntimeHistory -- 待写回的历史对象。
    输出：
      - None -- 结果直接落盘。
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": history.version,
        "last_updated_at": history.last_updated_at,
        "seconds_per_formal_scenario": history.seconds_per_formal_scenario,
        "recorded_formal_runs": history.recorded_formal_runs,
        "recent_formal_runs": history.recent_formal_runs,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def _is_test_scenario(scenario: ScenarioSpec) -> bool:
    """
    函数 `_is_test_scenario` 判断某个场景是否属于 `test.*` 冒烟范围。
    输入：
      - scenario: ScenarioSpec -- 当前场景。
    输出：
      - bool -- 若是测试场景则返回 `True`。
    """
    return scenario.scenario_key.startswith("test.")


def _condense_error(message: str) -> str:
    """
    函数 `_condense_error` 将多行运行错误压缩成适合终端单独打印的一行摘要。
    输入：
      - message: str -- 原始错误文本。
    输出：
      - str -- 截断后的单行错误摘要。
    """
    first_line = " ".join(part.strip() for part in message.strip().splitlines() if part.strip())
    if len(first_line) <= 220:
        return first_line
    return first_line[:217] + "..."
