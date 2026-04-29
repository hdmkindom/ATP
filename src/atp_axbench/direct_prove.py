"""Minimal direct ax-prover CLI for proving a single Lean target."""

from __future__ import annotations

import argparse
import asyncio
from copy import deepcopy
from datetime import datetime
import json
import os
from pathlib import Path
from typing import Any, Sequence

from .console import (
    install_llm_request_logging,
    print_error,
    print_info,
    print_status,
    print_warning,
)
from .deepseek_compat import install_deepseek_compat_patches
from .paths import REPO_ROOT
from .runner import (
    _PROVIDER_API_KEY_ENV,
    _apply_llm_credentials_from_config,
    _force_disable_langsmith,
    _format_runtime_exception,
    _resolve_provider_api_key,
    _reset_ax_tool_runtime_state,
    _sanitize_ax_config,
    install_runtime_warning_filters,
    prebuild_repo,
)
from .settings import ConsoleSettings, load_project_settings
from .structured_output import register_structured_output_strategies


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """
    函数 `parse_args` 解析最小单题证明脚本的命令行参数。
    它支持直接覆盖 model、api_key、base_url 等 LLM 参数，并指定单个 Lean 目标进行证明。
    输入：
      - argv: Sequence[str] | None -- 可选的命令行参数序列；为空时读取进程实际参数。
    输出：
      - argparse.Namespace -- 解析完成后的参数对象。
    """
    parser = argparse.ArgumentParser(
        description=(
            "直接调用 ax-prover 证明单个 Lean 目标。"
            "目标格式为相对仓库根目录的 `path/to/file.lean:theorem_name`。"
        )
    )
    parser.add_argument(
        "--target",
        required=True,
        help="待证明目标，例如 ATP/temTH/CandidateTheorems/T9/Free.lean:candidate_T9_free",
    )
    parser.add_argument(
        "--ax-config",
        action="append",
        default=[],
        help=(
            "额外叠加的 ax-prover YAML 配置。"
            "不传时默认读取 ATP/config/ax_prover_experiment.yaml。"
        ),
    )
    parser.add_argument(
        "--bare-config",
        action="store_true",
        help="不读取 ATP 的默认 experiment 配置，只从空白 Config 加上命令行覆盖开始。",
    )
    parser.add_argument(
        "--model",
        default=None,
        help="LLM 模型标识，格式通常为 provider:model；不传时沿用默认 ax 配置中的模型。",
    )
    parser.add_argument(
        "--api-key",
        default=None,
        help="直接注入 provider API key；不传时沿用 YAML 或环境变量。",
    )
    parser.add_argument(
        "--base-url",
        default=None,
        help="直接注入 provider base_url；OpenAI 兼容中转一般应写到 API 根路径，例如 https://host/v1 。",
    )
    parser.add_argument(
        "--temperature",
        type=float,
        default=None,
        help="可选的 provider 温度覆盖。",
    )
    parser.add_argument(
        "--max-iterations",
        type=int,
        default=None,
        help="覆盖 prover.max_iterations；不传时沿用 ax YAML。",
    )
    parser.add_argument(
        "--max-tool-calls",
        type=int,
        default=None,
        help="覆盖 runtime.max_tool_calling_iterations；不传时沿用 ax YAML。",
    )
    parser.add_argument(
        "--log-level",
        choices=("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"),
        default=None,
        help="覆盖 ax-prover 运行日志级别。",
    )
    parser.add_argument(
        "--user-comments",
        default=None,
        help="额外注入给 ax-prover prover.user_comments 的提示文本。",
    )
    responses_group = parser.add_mutually_exclusive_group()
    responses_group.add_argument(
        "--use-responses-api",
        dest="use_responses_api",
        action="store_true",
        help="显式要求 OpenAI 兼容 provider 走 Responses API。",
    )
    responses_group.add_argument(
        "--use-chat-completions",
        dest="use_responses_api",
        action="store_false",
        help="显式要求 OpenAI 兼容 provider 不走 Responses API。",
    )
    parser.set_defaults(use_responses_api=None)
    summary_group = parser.add_mutually_exclusive_group()
    summary_group.add_argument(
        "--enable-summary",
        dest="enable_summary",
        action="store_true",
        help="开启 ax-prover 最终 summary 节点。",
    )
    summary_group.add_argument(
        "--disable-summary",
        dest="enable_summary",
        action="store_false",
        help="关闭 ax-prover 最终 summary 节点，减少一次额外模型调用。",
    )
    parser.set_defaults(enable_summary=False)
    parser.add_argument(
        "--skip-prebuild",
        action="store_true",
        help="跳过 `lake exe cache get` 与 `lake build` 预构建。",
    )
    parser.add_argument(
        "--output-json",
        default=None,
        help="可选的结果 JSON 输出路径。",
    )
    parser.add_argument(
        "--thread-id",
        default=None,
        help="可选的 ax-prover thread_id；不传时自动按时间生成。",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="只打印合并后的关键配置，不真正调用 ax-prover 证明。",
    )
    return parser.parse_args(argv)


def build_minimal_ax_config(
    config_paths: tuple[str, ...],
    model: str | None = None,
    api_key: str | None = None,
    base_url: str | None = None,
    temperature: float | None = None,
    use_responses_api: bool | None = None,
    max_iterations: int | None = None,
    max_tool_calls: int | None = None,
    log_level: str | None = None,
    enable_summary: bool | None = None,
    user_comments: str | None = None,
    disable_langsmith_tracing: bool = True,
    console_settings: ConsoleSettings | None = None,
):
    """
    函数 `build_minimal_ax_config` 构造单题直连脚本使用的 ax-prover 配置。
    它会先加载默认 ax YAML，再把命令行显式给出的 model、api_key、base_url 等字段覆盖进去，
    最后复用 ATP 的配置清洗、默认值补齐和密钥注入逻辑。
    输入：
      - config_paths: tuple[str, ...] -- 需要叠加的 ax-prover YAML 配置路径。
      - model: str | None -- 可选模型覆盖。
      - api_key: str | None -- 可选 API key 覆盖。
      - base_url: str | None -- 可选 base_url 覆盖。
      - temperature: float | None -- 可选温度覆盖。
      - use_responses_api: bool | None -- 是否显式设置 OpenAI 兼容 Responses API 开关。
      - max_iterations: int | None -- 可选主循环轮次覆盖。
      - max_tool_calls: int | None -- 可选工具往返轮次覆盖。
      - log_level: str | None -- 可选日志级别覆盖。
      - enable_summary: bool | None -- 可选 summary 开关覆盖。
      - user_comments: str | None -- 可选额外用户提示。
      - disable_langsmith_tracing: bool -- 是否在当前进程内强制关闭 LangSmith。
      - console_settings: ConsoleSettings | None -- 可选终端颜色与日志过滤设置。
    输出：
      - Any -- 合并、清洗并补齐后的 ax-prover 配置对象。
    """
    install_runtime_warning_filters()
    install_llm_request_logging()
    if disable_langsmith_tracing:
        _force_disable_langsmith()

    from ax_prover.config import Config, LLMConfig
    from ax_prover.utils.config import load_env_secrets, merge_configs
    from .console import install_console_logging

    if console_settings is not None:
        install_console_logging(console_settings)

    load_env_secrets(REPO_ROOT)
    if disable_langsmith_tracing:
        _force_disable_langsmith()

    base_config = merge_configs([Config(), *config_paths], folder=str(REPO_ROOT))
    base_prover_llm = getattr(base_config.prover, "prover_llm", None)
    resolved_model = model or getattr(base_prover_llm, "model", None)
    if not resolved_model:
        raise ValueError(
            "No prover model is configured. Pass `--model provider:model` or provide an ax YAML with prover.prover_llm."
        )

    base_model = getattr(base_prover_llm, "model", None)
    base_provider = base_model.split(":", 1)[0] if isinstance(base_model, str) and ":" in base_model else None
    resolved_provider = resolved_model.split(":", 1)[0] if ":" in resolved_model else None
    provider_config = (
        deepcopy(getattr(base_prover_llm, "provider_config", {}) or {})
        if base_provider == resolved_provider
        else {}
    )
    if api_key is not None:
        provider_config["api_key"] = api_key
    if base_url is not None:
        provider_config["base_url"] = base_url
    if temperature is not None:
        provider_config["temperature"] = temperature
    if use_responses_api is not None:
        provider_config["use_responses_api"] = use_responses_api

    retry_config = deepcopy(getattr(base_prover_llm, "retry_config", {}) or {})
    if not retry_config:
        retry_config = deepcopy(LLMConfig(model=resolved_model).retry_config)

    overlay: dict[str, Any] = {
        "prover": {
            "prover_llm": {
                "model": resolved_model,
                "provider_config": provider_config,
                "retry_config": retry_config,
            }
        }
    }

    if max_iterations is not None:
        overlay["prover"]["max_iterations"] = int(max_iterations)
    if enable_summary is not None:
        overlay["prover"]["summarize_output"] = {"enabled": bool(enable_summary)}
    if user_comments is not None:
        overlay["prover"]["user_comments"] = user_comments

    runtime_overlay: dict[str, Any] = {}
    if log_level is not None:
        runtime_overlay["log_level"] = log_level
    if max_tool_calls is not None:
        runtime_overlay["max_tool_calling_iterations"] = int(max_tool_calls)
    if runtime_overlay:
        overlay["runtime"] = runtime_overlay

    ax_config = merge_configs([base_config, overlay], folder=str(REPO_ROOT))
    _ensure_memory_llm_config(ax_config)
    _apply_llm_credentials_from_config(ax_config)
    install_deepseek_compat_patches(ax_config)
    register_structured_output_strategies(ax_config)
    ax_config = _sanitize_ax_config(ax_config)
    return ax_config


def _ensure_memory_llm_config(ax_config) -> None:
    """
    函数 `_ensure_memory_llm_config` 为直连脚本补齐 `ExperienceProcessor` 需要的 `llm_config`。
    ATP 主运行链依赖 YAML 显式声明该字段；这里只在单文件直连脚本使用 bare config 时，
    做一个最小的本地兜底，避免第一次失败进入 memory 节点后崩溃。
    输入：
      - ax_config: Any -- 已合并好的 ax-prover 配置对象。
    输出：
      - None -- 原地写回 memory_config.init_args.llm_config。
    """
    prover_llm = getattr(ax_config.prover, "prover_llm", None)
    memory_config = getattr(ax_config.prover, "memory_config", None)
    if prover_llm is None or memory_config is None:
        return
    if getattr(memory_config, "class_name", "") != "ExperienceProcessor":
        return

    init_args = dict(getattr(memory_config, "init_args", {}) or {})
    if init_args.get("llm_config"):
        return

    init_args["llm_config"] = {
        "model": prover_llm.model,
        "provider_config": deepcopy(getattr(prover_llm, "provider_config", {}) or {}),
        "retry_config": deepcopy(getattr(prover_llm, "retry_config", {}) or {}),
    }
    memory_config.init_args = init_args


async def prove_target_once(ax_config, target: str, thread_id: str | None = None):
    """
    函数 `prove_target_once` 用 ax-prover 证明单个 `path:theorem` 目标。
    它会解析 proving target、重置工具层运行态，并执行一次真正的 ax-prover 调用。
    输入：
      - ax_config: Any -- 已构造完成的 ax-prover 配置对象。
      - target: str -- 目标字符串，格式为 `relative/path.lean:theorem_name`。
      - thread_id: str | None -- 可选的 ax-prover 线程标识。
    输出：
      - Any -- ax-prover 返回的最终状态对象。
    """
    from ax_prover.utils.proving import parse_prove_target, prove_single_item

    await _reset_ax_tool_runtime_state()
    items = parse_prove_target(str(REPO_ROOT), target)
    if len(items) != 1:
        raise ValueError(f"Expected exactly one proving target for {target}, got {len(items)}")

    resolved_thread_id = thread_id or f"direct_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    try:
        return await prove_single_item(
            ax_config,
            str(REPO_ROOT),
            items[0],
            thread_id=resolved_thread_id,
        )
    finally:
        await _reset_ax_tool_runtime_state()


def write_result_json(output_path: Path, payload: dict[str, Any]) -> None:
    """
    函数 `write_result_json` 将最小脚本的结果摘要写入 JSON 文件。
    输入：
      - output_path: Path -- 输出 JSON 路径。
      - payload: dict[str, Any] -- 需要写入的结构化结果。
    输出：
      - None -- 文件会被直接写入到磁盘。
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def build_result_payload(target: str, ax_config, state) -> dict[str, Any]:
    """
    函数 `build_result_payload` 生成单题直连脚本的结构化结果摘要。
    输入：
      - target: str -- 原始 proving target 字符串。
      - ax_config: Any -- 当前运行使用的 ax-prover 配置对象。
      - state: Any -- ax-prover 返回的最终状态。
    输出：
      - dict[str, Any] -- 适合打印或写入 JSON 的结果字典。
    """
    last_feedback = getattr(state, "last_feedback", None)
    last_feedback_content = getattr(last_feedback, "content", "") if last_feedback else ""
    return {
        "target": target,
        "model": ax_config.prover.prover_llm.model,
        "base_url": getattr(ax_config.prover.prover_llm, "provider_config", {}).get("base_url"),
        "proven": bool(state.item.proven),
        "approved": bool(getattr(state, "approved", False)),
        "iterations": int(state.metrics.number_of_iterations),
        "compilation_errors": int(state.metrics.compilation_error_count),
        "build_timeouts": int(state.metrics.build_timeout_count),
        "reviewer_rejections": int(state.metrics.reviewer_rejections),
        "max_iterations_reached": bool(state.metrics.max_iterations_reached),
        "summary": state.summary,
        "last_feedback_type": type(last_feedback).__name__ if last_feedback else None,
        "last_feedback_content": last_feedback_content,
    }


def print_effective_config(target: str, ax_config) -> None:
    """
    函数 `print_effective_config` 打印最小脚本本次运行的关键 LLM 配置摘要。
    输入：
      - target: str -- 原始 proving target 字符串。
      - ax_config: Any -- 已构造完成的 ax-prover 配置对象。
    输出：
      - None -- 摘要直接打印到终端。
    """
    provider_config = deepcopy(getattr(ax_config.prover.prover_llm, "provider_config", {}) or {})
    provider = ax_config.prover.prover_llm.model.split(":", 1)[0]
    api_key_env = _PROVIDER_API_KEY_ENV.get(provider)
    api_key = _resolve_provider_api_key(provider_config) or (
        os.environ.get(api_key_env) if api_key_env else None
    )
    if api_key:
        provider_config["api_key"] = _mask_secret(str(api_key))
    print_status(f"Target: {target}")
    print_status(f"Model: {ax_config.prover.prover_llm.model}")
    print_status(f"Provider config: {json.dumps(provider_config, ensure_ascii=False, sort_keys=True)}")
    print_status(f"Max iterations: {ax_config.prover.max_iterations}")
    print_status(f"Max tool calls: {ax_config.runtime.max_tool_calling_iterations}")
    print_status(f"Summary enabled: {ax_config.prover.summarize_output.enabled}")
    print_status(f"Log level: {ax_config.runtime.log_level}")


def run_from_args(args: argparse.Namespace) -> int:
    """
    函数 `run_from_args` 根据解析后的命令行参数执行一次单题直连证明。
    它会构造 ax-prover 配置、按需预构建、运行证明并打印简短结果。
    输入：
      - args: argparse.Namespace -- 已解析完成的命令行参数。
    输出：
      - int -- 证明成功返回 `0`，失败返回 `1`。
    """
    settings = load_project_settings()
    config_paths = () if args.bare_config else tuple(args.ax_config or settings.experiment_ax_config)

    try:
        ax_config = build_minimal_ax_config(
            config_paths=config_paths,
            model=args.model,
            api_key=args.api_key,
            base_url=args.base_url,
            temperature=args.temperature,
            use_responses_api=args.use_responses_api,
            max_iterations=args.max_iterations,
            max_tool_calls=args.max_tool_calls,
            log_level=args.log_level,
            enable_summary=args.enable_summary,
            user_comments=args.user_comments,
            disable_langsmith_tracing=settings.execution.disable_langsmith_tracing,
            console_settings=settings.console,
        )
        print_effective_config(args.target, ax_config)

        if args.dry_run:
            print_info("Dry run completed; ax-prover was not invoked.")
            return 0

        if not args.skip_prebuild:
            print_info("Running Lean prebuild before proof attempt...")
            build_success, build_output = prebuild_repo(ax_config)
            if not build_success:
                print_error("Lean prebuild failed.")
                print_error(build_output)
                return 1

        print_info("Starting ax-prover...")
        state = asyncio.run(
            prove_target_once(
                ax_config=ax_config,
                target=args.target,
                thread_id=args.thread_id,
            )
        )
        payload = build_result_payload(args.target, ax_config, state)
        _print_result_payload(payload)
        if args.output_json:
            write_result_json(Path(args.output_json), payload)
            print_info(f"Result JSON written to {args.output_json}")
        return 0 if payload["proven"] else 1
    except KeyboardInterrupt:
        print_error("Interrupted by user.")
        return 1
    except Exception as exc:
        error_message = _format_runtime_exception(locals().get("ax_config"), exc)
        print_error(error_message)
        return 1


def main(argv: Sequence[str] | None = None) -> int:
    """
    函数 `main` 是最小单题证明脚本的主入口。
    输入：
      - argv: Sequence[str] | None -- 可选的命令行参数序列；为空时读取进程实际参数。
    输出：
      - int -- 进程退出码。
    """
    return run_from_args(parse_args(argv))


def _print_result_payload(payload: dict[str, Any]) -> None:
    """
    函数 `_print_result_payload` 将单题运行结果以紧凑形式打印到终端。
    输入：
      - payload: dict[str, Any] -- 结构化结果摘要。
    输出：
      - None -- 文本直接打印到终端。
    """
    if payload["proven"]:
        print_info(f"✓ Proved: {payload['target']}")
    else:
        print_error(f"X Failed: {payload['target']}")
    print_status(
        "Iterations={iterations}, compilation_errors={compilation_errors}, "
        "reviewer_rejections={reviewer_rejections}, build_timeouts={build_timeouts}, "
        "max_iterations_reached={max_iterations_reached}".format(**payload)
    )
    if payload["last_feedback_type"]:
        print_status(f"Last feedback: {payload['last_feedback_type']}")
    if payload["last_feedback_content"]:
        print_warning(payload["last_feedback_content"])
    if payload["summary"]:
        print_status(f"Summary: {payload['summary']}")


def _mask_secret(secret: str) -> str:
    """
    函数 `_mask_secret` 对 API key 等敏感字符串做简短脱敏显示。
    输入：
      - secret: str -- 原始敏感字符串。
    输出：
      - str -- 仅保留末尾少量字符的脱敏结果。
    """
    if len(secret) <= 6:
        return "*" * len(secret)
    return f"{'*' * (len(secret) - 4)}{secret[-4:]}"
