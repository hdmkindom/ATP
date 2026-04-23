"""Artifact writing and human-readable summaries."""

from __future__ import annotations

import json
from dataclasses import asdict, is_dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

from .models import DoctorReport, ScenarioResult


def attempt_directory(output_dir: Path, scenario_key: str, attempt_index: int) -> Path:
    """
    函数 `attempt_directory` 计算单个场景尝试的专属输出目录。
    它会把场景键转换为文件系统友好的目录名，并按尝试编号分层存放。
    输入：
      - output_dir: Path -- 本次批量运行的根输出目录。
      - scenario_key: str -- 场景标识，例如 `T1.free`。
      - attempt_index: int -- 当前场景的第几次尝试。
    输出：
      - Path -- 当前场景尝试对应的输出目录路径。
    """
    scenario_dir = scenario_key.replace(".", "_")
    return output_dir / "scenarios" / scenario_dir / f"attempt_{attempt_index:02d}"


def write_text_artifact(path: Path, content: str) -> str:
    """
    函数 `write_text_artifact` 把文本内容写入指定的归档文件。
    输入：
      - path: Path -- 目标文件路径。
      - content: str -- 需要写入的文本内容。
    输出：
      - str -- 已写入文件的绝对路径字符串。
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return str(path)


def write_scenario_artifacts(
    attempt_dir: Path,
    result: ScenarioResult,
    final_file_content: str,
) -> dict[str, str]:
    """
    函数 `write_scenario_artifacts` 写入单次场景尝试的最终结果文件。
    它会保存结构化结果 JSON 以及最终 Lean 快照。
    输入：
      - attempt_dir: Path -- 当前场景尝试的输出目录。
      - result: ScenarioResult -- 当前尝试的结构化运行结果。
      - final_file_content: str -- 运行结束时读取到的最终 Lean 文件内容。
    输出：
      - dict[str, str] -- 关键归档文件路径的字典。
    """
    attempt_dir.mkdir(parents=True, exist_ok=True)
    slug = scenario_slug(result.scenario_key, result.attempt_index)
    result_path = attempt_dir / f"{slug}.json"
    proof_path = attempt_dir / f"{slug}.lean"
    write_json(result_path, result)
    proof_path.write_text(final_file_content, encoding="utf-8")
    return {"result_json": str(result_path), "proof_snapshot": str(proof_path)}


def write_run_summary(
    output_dir: Path,
    results: list[ScenarioResult],
    metadata: dict[str, Any] | None = None,
) -> dict[str, str]:
    """
    函数 `write_run_summary` 写入批量运行的总汇总文件。
    它会同时生成 JSON 与 Markdown 两份汇总，方便机器读取与人工浏览。
    输入：
      - output_dir: Path -- 本次批量运行的根输出目录。
      - results: list[ScenarioResult] -- 所有场景尝试的结果列表。
      - metadata: dict[str, Any] | None -- 可选的批量运行元信息。
    输出：
      - dict[str, str] -- 汇总 JSON 与 Markdown 的路径字典。
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    summary_json_path = output_dir / "summary.json"
    summary_md_path = output_dir / "summary.md"
    payload = {
        "metadata": metadata or {},
        "results": [to_jsonable(result) for result in results],
    }
    summary_json_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    summary_md_path.write_text(
        render_run_summary_markdown(results, metadata or {}),
        encoding="utf-8",
    )
    return {
        "summary_json": str(summary_json_path),
        "summary_markdown": str(summary_md_path),
    }


def write_doctor_report(output_dir: Path, report: DoctorReport) -> dict[str, str]:
    """
    函数 `write_doctor_report` 写入 doctor 命令的检查报告。
    它会生成结构化 JSON 与面向人工阅读的 Markdown。
    输入：
      - output_dir: Path -- doctor 输出目录。
      - report: DoctorReport -- doctor 聚合报告对象。
    输出：
      - dict[str, str] -- doctor 结果文件路径字典。
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "doctor.json"
    md_path = output_dir / "doctor.md"
    write_json(json_path, report)
    md_path.write_text(render_doctor_markdown(report), encoding="utf-8")
    return {"doctor_json": str(json_path), "doctor_markdown": str(md_path)}


def render_run_summary_markdown(
    results: list[ScenarioResult],
    metadata: dict[str, Any],
) -> str:
    """
    函数 `render_run_summary_markdown` 渲染批量运行的 Markdown 汇总表。
    输入：
      - results: list[ScenarioResult] -- 所有场景尝试结果。
      - metadata: dict[str, Any] -- 本次批量运行的元信息。
    输出：
      - str -- 渲染完成的 Markdown 文本。
    """
    lines = ["# ATP Ax-Prover Run Summary", ""]
    if metadata:
        for key, value in metadata.items():
            lines.append(f"- **{key}**: {value}")
        lines.append("")

    lines.append("| Scenario | Success | Valid | Iter | Time (s) | Error |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for result in results:
        error = result.error or ""
        lines.append(
            "| "
            f"{result.scenario_key} | "
            f"{_bool_word(result.success)} | "
            f"{_bool_word(result.valid)} | "
            f"{result.iterations} | "
            f"{result.elapsed_seconds:.2f} | "
            f"{error} |"
        )
    return "\n".join(lines) + "\n"


def render_doctor_markdown(report: DoctorReport) -> str:
    """
    函数 `render_doctor_markdown` 渲染 doctor 报告的 Markdown 版本。
    输入：
      - report: DoctorReport -- doctor 聚合报告。
    输出：
      - str -- 可直接写入文档的 Markdown 文本。
    """
    lines = ["# ATP Ax-Prover Doctor", ""]
    lines.append(f"- **started_at**: {report.started_at.isoformat()}")
    lines.append(f"- **finished_at**: {report.finished_at.isoformat()}")
    lines.append("")
    lines.append("| Check | Status | Duration (s) | Message |")
    lines.append("| --- | --- | --- | --- |")
    for check in report.checks:
        lines.append(
            f"| {check.name} | {check.status} | {check.duration_seconds:.2f} | {check.message} |"
        )
    return "\n".join(lines) + "\n"


def write_json(path: Path, obj: Any) -> None:
    """
    函数 `write_json` 将对象序列化为 JSON 并写入文件。
    输入：
      - path: Path -- 目标 JSON 文件路径。
      - obj: Any -- 待序列化对象。
    输出：
      - None -- 结果直接写入磁盘。
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(to_jsonable(obj), ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def to_jsonable(obj: Any) -> Any:
    """
    函数 `to_jsonable` 把 dataclass、时间对象与路径对象转换成 JSON 兼容结构。
    输入：
      - obj: Any -- 任意待转换对象。
    输出：
      - Any -- JSON 可序列化的对象。
    """
    if is_dataclass(obj):
        return {key: to_jsonable(value) for key, value in asdict(obj).items()}
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, Path):
        return str(obj)
    if isinstance(obj, dict):
        return {str(key): to_jsonable(value) for key, value in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [to_jsonable(value) for value in obj]
    return obj


def scenario_slug(scenario_key: str, attempt_index: int) -> str:
    """
    函数 `scenario_slug` 生成场景尝试的稳定文件名前缀。
    输入：
      - scenario_key: str -- 场景标识。
      - attempt_index: int -- 尝试编号。
    输出：
      - str -- 适合写入文件名的 slug 字符串。
    """
    return scenario_key.replace(".", "_") + f"_attempt{attempt_index:02d}"


def _bool_word(value: bool) -> str:
    """
    函数 `_bool_word` 将布尔值转成汇总表使用的字符串。
    输入：
      - value: bool -- 待转换的布尔值。
    输出：
      - str -- `yes` 或 `no`。
    """
    return "yes" if value else "no"
