"""Utilities for checking whether ATP's configured LLM is using reasoning mode."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
from time import perf_counter
from typing import Any

from ax_prover.prover.agent import create_llm

from .runner import build_ax_config


def _mask_secret(value: Any) -> Any:
    """
    函数 `_mask_secret` 对可能包含密钥的值做简单脱敏。
    输入：
      - value: Any -- 任意待显示的值。
    输出：
      - Any -- 如果是长字符串则返回脱敏后的版本，否则原样返回。
    """
    if not isinstance(value, str):
        return value
    if len(value) <= 8:
        return "***"
    return f"{value[:4]}***{value[-4:]}"


def _mask_provider_config(provider_config: dict[str, Any]) -> dict[str, Any]:
    """
    函数 `_mask_provider_config` 脱敏 provider_config 中的敏感字段。
    输入：
      - provider_config: dict[str, Any] -- 原始 provider 配置。
    输出：
      - dict[str, Any] -- 适合打印到终端或写入 JSON 的脱敏副本。
    """
    masked = deepcopy(provider_config)
    for key in ("api_key", "apiToken", "token"):
        if key in masked:
            masked[key] = _mask_secret(masked[key])
    return masked


def _reasoning_overlay(reasoning_effort: str | None) -> dict[str, Any]:
    """
    函数 `_reasoning_overlay` 为 ax-prover 配置构造临时 reasoning 覆盖层。
    当前默认只写入 `reasoning: {effort: ...}`。
    这是因为在本地 `langchain-openai + Responses API` 组合下，`reasoning_effort`
    虽然能通过对象初始化，但真实调用时会触发 `Responses.create() got an unexpected keyword argument 'reasoning_effort'`。
    输入：
      - reasoning_effort: str | None -- 目标思考强度，例如 `high` 或 `xhigh`；为空时返回空覆盖层。
    输出：
      - dict[str, Any] -- 可直接传给 `build_ax_config` 的字典覆盖层。
    """
    if not reasoning_effort:
        return {}
    return {
        "prover": {
            "prover_llm": {
                "provider_config": {
                    "reasoning": {"effort": reasoning_effort},
                }
            }
        }
    }


def collect_reasoning_diagnostics(
    ax_config_paths: tuple[str, ...],
    reasoning_effort: str | None = None,
) -> dict[str, Any]:
    """
    函数 `collect_reasoning_diagnostics` 收集当前 ATP 配置与 LangChain 实际 LLM 对象的 reasoning 诊断信息。
    输入：
      - ax_config_paths: tuple[str, ...] -- 需要叠加的 ax-prover YAML 配置路径。
      - reasoning_effort: str | None -- 可选的临时 reasoning 覆盖强度；为空时按当前配置原样检查。
    输出：
      - dict[str, Any] -- 包含最终 provider_config、LLM 类名、reasoning 字段与 `_default_params` 的结构化诊断结果。
    """
    extra_overlays: list[Any] = []
    overlay = _reasoning_overlay(reasoning_effort)
    if overlay:
        extra_overlays.append(overlay)

    ax_config = build_ax_config(
        (*ax_config_paths, *extra_overlays),
        user_comments="ATP reasoning probe.",
        disable_langsmith_tracing=True,
    )
    llm_config = ax_config.prover.prover_llm
    llm = create_llm(llm_config)

    diagnostics = {
        "model": llm_config.model,
        "config_provider_config": _mask_provider_config(
            deepcopy(getattr(llm_config, "provider_config", {}) or {})
        ),
        "llm_class": f"{llm.__class__.__module__}.{llm.__class__.__name__}",
        "llm_attrs": {
            "model_name": getattr(llm, "model_name", None),
            "temperature": getattr(llm, "temperature", None),
            "reasoning": getattr(llm, "reasoning", None),
            "reasoning_effort": getattr(llm, "reasoning_effort", None),
            "use_responses_api": getattr(llm, "use_responses_api", None),
            "model_kwargs": deepcopy(getattr(llm, "model_kwargs", {}) or {}),
            "_default_params": deepcopy(getattr(llm, "_default_params", {}) or {}),
        },
    }
    return diagnostics


def run_live_reasoning_probe(
    ax_config_paths: tuple[str, ...],
    prompt: str,
    reasoning_effort: str | None = None,
) -> dict[str, Any]:
    """
    函数 `run_live_reasoning_probe` 用当前 ATP 配置真实调用一次模型，并记录耗时与返回元数据。
    输入：
      - ax_config_paths: tuple[str, ...] -- 需要叠加的 ax-prover YAML 配置路径。
      - prompt: str -- 实际发送给模型的探测提示。
      - reasoning_effort: str | None -- 可选的临时 reasoning 覆盖强度；为空时按当前配置原样调用。
    输出：
      - dict[str, Any] -- 包含诊断信息、调用耗时、返回内容预览与 usage/response metadata 的结构化结果。
    """
    diagnostics = collect_reasoning_diagnostics(
        ax_config_paths=ax_config_paths,
        reasoning_effort=reasoning_effort,
    )

    extra_overlays: list[Any] = []
    overlay = _reasoning_overlay(reasoning_effort)
    if overlay:
        extra_overlays.append(overlay)

    ax_config = build_ax_config(
        (*ax_config_paths, *extra_overlays),
        user_comments="ATP reasoning probe.",
        disable_langsmith_tracing=True,
    )
    llm = create_llm(ax_config.prover.prover_llm)

    started = perf_counter()
    try:
        message = llm.invoke(prompt)
    except Exception as exc:
        return {
            "diagnostics": diagnostics,
            "prompt": prompt,
            "elapsed_seconds": round(perf_counter() - started, 6),
            "error": f"{type(exc).__name__}: {exc}",
        }

    elapsed_seconds = round(perf_counter() - started, 6)

    result = {
        "diagnostics": diagnostics,
        "prompt": prompt,
        "elapsed_seconds": elapsed_seconds,
        "response_preview": str(getattr(message, "content", ""))[:1000],
        "usage_metadata": deepcopy(getattr(message, "usage_metadata", None)),
        "response_metadata": deepcopy(getattr(message, "response_metadata", None)),
        "additional_kwargs": deepcopy(getattr(message, "additional_kwargs", None)),
    }
    return result


def reasoning_report_json(
    ax_config_paths: tuple[str, ...],
    prompt: str | None = None,
    compare_effort: str | None = None,
    live: bool = False,
) -> dict[str, Any]:
    """
    函数 `reasoning_report_json` 生成当前配置与可选 reasoning 覆盖层的完整诊断报告。
    输入：
      - ax_config_paths: tuple[str, ...] -- 需要叠加的 ax-prover YAML 配置路径。
      - prompt: str | None -- 若启用 live probe，则作为实际发送给模型的提示。
      - compare_effort: str | None -- 可选的对照思考强度，例如 `high`。
      - live: bool -- 是否执行真实 API 调用。
    输出：
      - dict[str, Any] -- 结构化报告，可直接写入 JSON。
    """
    report: dict[str, Any] = {
        "current": run_live_reasoning_probe(ax_config_paths, prompt, None)
        if live
        else collect_reasoning_diagnostics(ax_config_paths, None)
    }
    if compare_effort:
        report["compare"] = {
            "reasoning_effort": compare_effort,
            "result": run_live_reasoning_probe(ax_config_paths, prompt or "", compare_effort)
            if live
            else collect_reasoning_diagnostics(ax_config_paths, compare_effort),
        }
    return report


def write_reasoning_report(path: Path, report: dict[str, Any]) -> None:
    """
    函数 `write_reasoning_report` 将 reasoning 诊断结果写入 JSON 文件。
    输入：
      - path: Path -- 输出 JSON 路径。
      - report: dict[str, Any] -- 需要写入的结构化报告。
    输出：
      - None -- 结果会写入磁盘。
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
