"""Typed data models for the ATP benchmark harness."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum


class ModeFamily(StrEnum):
    TEST = "test"
    FREE = "free"
    DISABLE = "disable"
    GUIDED = "guided"


@dataclass(frozen=True)
class TheoremSpec:
    """候选定理的模式元数据。"""

    theorem_id: str
    free_instruction: str = ""
    disable_instruction: str = ""
    route_a: str = ""
    route_b: str = ""
    scenario_order: tuple[str, ...] = ()


@dataclass(frozen=True)
class ScenarioSpec:
    """单个可运行实验场景的静态描述。"""

    scenario_key: str
    scenario_name: str
    theorem_id: str
    target_file: str
    theorem_name: str
    mode_family: str
    route_hint: str | None = None
    theorem: TheoremSpec | None = None
    user_comments: str = ""
    tags: tuple[str, ...] = ()


@dataclass
class ScenarioResult:
    """单次场景运行后的结构化结果。"""

    scenario_key: str
    theorem_id: str
    mode_family: str
    attempt_index: int
    target_file: str
    theorem_name: str
    success: bool
    valid: bool
    summary: str = ""
    error: str | None = None
    prompt_excerpt: str = ""
    iterations: int = 0
    compilation_errors: int = 0
    build_timeouts: int = 0
    reviewer_rejections: int = 0
    max_iterations_reached: bool = False
    elapsed_seconds: float = 0.0
    llm_request_count: int = 0
    llm_failed_request_count: int = 0
    llm_input_tokens: int = 0
    llm_output_tokens: int = 0
    llm_total_tokens: int = 0
    started_at: datetime | None = None
    finished_at: datetime | None = None
    artifact_paths: dict[str, str] = field(default_factory=dict)


@dataclass
class HealthCheckResult:
    """单个 doctor 检查项的执行结果。"""

    name: str
    status: str
    message: str
    duration_seconds: float
    details: dict[str, str] = field(default_factory=dict)


@dataclass
class DoctorReport:
    """doctor 命令的聚合报告。"""

    started_at: datetime
    finished_at: datetime
    checks: list[HealthCheckResult]


@dataclass
class ProposalSnapshotRecord:
    """单轮 proposal 快照文件的索引记录。"""

    iteration_index: int
    timestamp_tag: str
    lean_path: str
    metadata_path: str
