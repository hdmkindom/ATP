"""ax-prover execution adapter for ATP benchmark scenarios."""

from __future__ import annotations

import asyncio
import contextlib
from datetime import datetime
import os
from pathlib import Path
from urllib.parse import urlparse
import warnings

from .console import (
    LLMRequestLimitExceeded,
    install_console_logging,
    install_llm_request_logging,
    llm_request_session,
)
from .deepseek_compat import install_deepseek_compat_patches
from .iteration_archive import ProposalArchiveSession
from .models import ScenarioResult, ScenarioSpec
from .paths import REPO_ROOT
from .prompts import render_user_comments
from .reporting import (
    attempt_directory,
    write_run_summary,
    write_scenario_artifacts,
    write_text_artifact,
    write_json,
)
from .runtime_monitor import BatchProgressTracker
from .settings import ProjectSettings
from .structured_output import register_structured_output_strategies

_PROVIDER_API_KEY_ENV = {
    "openai": "OPENAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "google_genai": "GOOGLE_API_KEY",
    "deepseek": "DEEPSEEK_API_KEY",
}

_ATP_PROVIDER_CONFIG_KEYS = {
    "api_key_env",
    "structured_output_strategy",
}


def build_ax_config(
    config_paths: tuple[str, ...],
    user_comments: str,
    disable_langsmith_tracing: bool = True,
    console_settings=None,
):
    """
    函数 `build_ax_config` 合并 ax-prover 配置并注入场景提示。
    它会加载 `.env.secrets`，必要时强制关闭 LangSmith，再返回已经合并好的 ax-prover 配置对象。
    输入：
      - config_paths: tuple[str, ...] -- 需要叠加的 ax-prover YAML 配置路径。
      - user_comments: str -- 注入到 ax-prover `prover.user_comments` 的场景提示。
      - disable_langsmith_tracing: bool -- 是否在当前进程中强制禁用 LangSmith。
      - console_settings: Any -- 可选的终端输出设置，用于给 ax-prover 日志安装颜色与过滤器。
    输出：
      - Any -- 已合并完成的 ax-prover 配置对象。
    """
    install_runtime_warning_filters()
    install_llm_request_logging()
    if disable_langsmith_tracing:
        _force_disable_langsmith()

    from ax_prover.config import Config
    from ax_prover.utils.config import load_env_secrets, merge_configs

    if console_settings is not None:
        install_console_logging(console_settings)
    load_env_secrets(REPO_ROOT)
    if disable_langsmith_tracing:
        _force_disable_langsmith()
    scoped_user_comments = user_comments.strip() or None

    ax_config = merge_configs(
        [
            Config(),
            *config_paths,
            {"prover": {"user_comments": scoped_user_comments}},
        ],
        folder=str(REPO_ROOT),
    )
    _apply_llm_credentials_from_config(ax_config)
    install_deepseek_compat_patches(ax_config)
    register_structured_output_strategies(ax_config)
    ax_config = _sanitize_ax_config(ax_config)
    return ax_config


def prebuild_repo(ax_config) -> tuple[bool, str]:
    """
    函数 `prebuild_repo` 调用 ax-prover 的仓库预构建逻辑。
    它会执行 `lake exe cache get` 与 `lake build`，并在 cache 失败但 build 成功时给出宽容处理。
    输入：
      - ax_config: Any -- ax-prover 的运行时配置对象。
    输出：
      - tuple[bool, str] -- 第一项表示是否允许继续运行，第二项是构建日志。
    """
    from ax_prover.utils.build import build_lean_repo

    success, output = build_lean_repo(str(REPO_ROOT), ax_config.runtime.lean)
    if success:
        return True, output

    build_ok = "=== lake build ===" in output and "Build completed successfully" in output
    cache_failed = "=== lake exe cache get ===" in output
    if build_ok and cache_failed:
        warning = (
            "Proceeding even though `lake exe cache get` failed, because `lake build` succeeded. "
            "This project currently has a mathlib toolchain cache mismatch."
        )
        return True, f"{warning}\n\n{output}"
    return False, output


def run_batch(
    scenarios: list[ScenarioSpec],
    settings: ProjectSettings,
    ax_config_paths: tuple[str, ...],
    repeats: int,
    output_dir: Path,
    persist: bool = False,
    skip_prebuild: bool = False,
    progress_tracker: BatchProgressTracker | None = None,
) -> list[ScenarioResult]:
    """
    函数 `run_batch` 运行一批 ATP 场景。
    它负责预构建、按场景和重复次数逐个执行，并在结束后写出批量汇总。
    输入：
      - scenarios: list[ScenarioSpec] -- 需要运行的场景列表。
      - settings: ProjectSettings -- ATP 项目设置。
      - ax_config_paths: tuple[str, ...] -- 需要叠加的 ax-prover 配置路径。
      - repeats: int -- 每个场景重复运行的次数。
      - output_dir: Path -- 本次批量运行的输出目录。
      - persist: bool -- 是否保留成功运行后的源文件修改。
      - skip_prebuild: bool -- 是否跳过预构建。
      - progress_tracker: BatchProgressTracker | None -- 可选的批量运行进度跟踪器。
    输出：
      - list[ScenarioResult] -- 所有场景尝试的结果列表。
    """
    if not scenarios:
        return []

    if not skip_prebuild and settings.execution.prebuild_repo:
        ax_config = build_ax_config(
            ax_config_paths,
            user_comments="ATP batch prebuild.",
            disable_langsmith_tracing=settings.execution.disable_langsmith_tracing,
            console_settings=settings.console,
        )
        build_success, build_output = prebuild_repo(ax_config)
        if not build_success:
            raise RuntimeError(f"Lean prebuild failed.\n{build_output}")

    results: list[ScenarioResult] = []
    interrupted = False
    try:
        for scenario in scenarios:
            for attempt_index in range(1, repeats + 1):
                if progress_tracker is not None:
                    progress_tracker.before_scenario(
                        scenario,
                        attempt_index,
                        format_scenario_divider(
                            scenario.scenario_key,
                            attempt_index if repeats > 1 else None,
                        ),
                    )
                result = run_single_scenario(
                    scenario=scenario,
                    settings=settings,
                    ax_config_paths=ax_config_paths,
                    attempt_index=attempt_index,
                    output_dir=output_dir,
                    persist=persist,
                    progress_tracker=progress_tracker,
                )
                results.append(result)
                if progress_tracker is not None:
                    progress_tracker.after_scenario(result, scenario, attempt_index)
    except KeyboardInterrupt:
        interrupted = True
        raise
    finally:
        metadata = {
            "repo_root": str(REPO_ROOT),
            "repeats": repeats,
            "scenario_count": len(scenarios),
            "interrupted": interrupted,
        }
        if progress_tracker is not None:
            metadata.update(progress_tracker.batch_metadata())
            progress_tracker.finalize()
        write_run_summary(
            output_dir,
            results,
            metadata=metadata,
        )
    return results


def format_scenario_divider(scenario_key: str, attempt_index: int | None = None) -> str:
    """
    函数 `format_scenario_divider` 生成场景运行之间的短分隔线。
    它会把 `T1.free` 之类的键格式化为 `--T1-free------`，便于在长日志中快速定位题目边界。
    输入：
      - scenario_key: str -- 场景键，例如 `T1.free`。
      - attempt_index: int | None -- 可选的重复运行编号；为空时不附加。
    输出：
      - str -- 适合直接打印到终端的分隔字符串。
    """
    label = scenario_key.replace(".", "-")
    if attempt_index is not None:
        label = f"{label}-a{attempt_index}"
    trailing_dashes = max(6, 18 - len(label))
    return f"--{label}{'-' * trailing_dashes}"


def run_single_scenario(
    scenario: ScenarioSpec,
    settings: ProjectSettings,
    ax_config_paths: tuple[str, ...],
    attempt_index: int,
    output_dir: Path,
    persist: bool = False,
    progress_tracker: BatchProgressTracker | None = None,
) -> ScenarioResult:
    """
    函数 `run_single_scenario` 运行单个场景的一次尝试。
    它会构建场景提示、执行 ax-prover、保存每轮快照和最终归档，并在默认情况下恢复模板文件。
    输入：
      - scenario: ScenarioSpec -- 当前需要运行的场景。
      - settings: ProjectSettings -- ATP 项目设置。
      - ax_config_paths: tuple[str, ...] -- 需要叠加的 ax-prover 配置路径。
      - attempt_index: int -- 当前场景的第几次尝试。
      - output_dir: Path -- 当前批量运行的根输出目录。
      - persist: bool -- 是否保留成功后的源文件修改。
      - progress_tracker: BatchProgressTracker | None -- 可选的批量运行状态跟踪器。
    输出：
      - ScenarioResult -- 当前尝试的结构化结果。
    """
    target_path = (REPO_ROOT / scenario.target_file).resolve()
    prompt = render_user_comments(scenario)
    started_at = datetime.now()
    original_content = target_path.read_text(encoding="utf-8")
    final_content = original_content
    restored_content = original_content
    attempt_dir = attempt_directory(output_dir, scenario.scenario_key, attempt_index)
    state = None
    archive_session = None
    original_snapshot_path = ""
    ax_config = None
    request_session = None

    if settings.execution.archive_source_snapshots:
        original_snapshot_path = write_text_artifact(
            attempt_dir / "source" / f"{started_at.strftime('%m%d%H%M')}_original.lean",
            original_content,
        )

    result = ScenarioResult(
        scenario_key=scenario.scenario_key,
        theorem_id=scenario.theorem_id,
        mode_family=scenario.mode_family,
        attempt_index=attempt_index,
        target_file=scenario.target_file,
        theorem_name=scenario.theorem_name,
        success=False,
        valid=False,
        prompt_excerpt=prompt[:1200],
        started_at=started_at,
    )

    try:
        ax_config = build_ax_config(
            ax_config_paths,
            prompt,
            disable_langsmith_tracing=settings.execution.disable_langsmith_tracing,
            console_settings=settings.console,
        )
        with ProposalArchiveSession(
            repo_root=REPO_ROOT,
            attempt_dir=attempt_dir,
            target_relative_path=scenario.target_file,
            enabled=settings.execution.archive_iteration_snapshots,
        ) as archive_session, llm_request_session(
            settings.execution.max_llm_requests_per_attempt
        ) as request_session:
            state = asyncio.run(_prove_item_with_ax(ax_config, scenario))
            archive_session.finalize_with_state(state)
        final_content = target_path.read_text(encoding="utf-8")

        result.success = bool(state.item.proven)
        result.valid = result.success
        result.summary = state.summary
        result.iterations = state.metrics.number_of_iterations
        result.compilation_errors = state.metrics.compilation_error_count
        result.build_timeouts = state.metrics.build_timeout_count
        result.reviewer_rejections = state.metrics.reviewer_rejections
        result.max_iterations_reached = state.metrics.max_iterations_reached
    except KeyboardInterrupt:
        if target_path.exists():
            final_content = target_path.read_text(encoding="utf-8")
        result.error = "KeyboardInterrupt: interrupted by user."
        raise
    except LLMRequestLimitExceeded as exc:
        if target_path.exists():
            final_content = target_path.read_text(encoding="utf-8")
        result.error = str(exc)
    except Exception as exc:  # pragma: no cover - integration boundary
        if target_path.exists():
            final_content = target_path.read_text(encoding="utf-8")
        result.error = _format_runtime_exception(ax_config, exc)
    finally:
        keep_changes = persist or (
            settings.execution.persist_successful_proofs and result.valid
        )
        if settings.execution.persist_last_attempt_on_failure and not result.valid:
            keep_changes = True
        if settings.execution.restore_source_after_run and not keep_changes:
            target_path.write_text(original_content, encoding="utf-8")
        restored_content = target_path.read_text(encoding="utf-8")
        result.finished_at = datetime.now()
        result.elapsed_seconds = (result.finished_at - started_at).total_seconds()
        if request_session is not None:
            result.llm_request_count = request_session.request_count
        result.artifact_paths = write_scenario_artifacts(attempt_dir, result, final_content)
        result.artifact_paths["attempt_dir"] = str(attempt_dir)
        if archive_session is not None and archive_session.artifact_paths():
            result.artifact_paths["iteration_snapshot_dir"] = str(attempt_dir / "iterations")
            result.artifact_paths["iteration_snapshot_files"] = ", ".join(
                archive_session.artifact_paths()
            )
        if settings.execution.archive_source_snapshots:
            if original_snapshot_path:
                result.artifact_paths["original_source_snapshot"] = original_snapshot_path
            result.artifact_paths["final_source_snapshot"] = write_text_artifact(
                attempt_dir / "source" / f"{result.finished_at.strftime('%m%d%H%M')}_final.lean",
                final_content,
            )
            result.artifact_paths["restored_source_snapshot"] = write_text_artifact(
                attempt_dir / "source" / f"{result.finished_at.strftime('%m%d%H%M')}_restored.lean",
                restored_content,
            )
        if state is not None:
            result.artifact_paths["message_trace_json"] = _write_message_trace(
                attempt_dir,
                state,
            )
        if "result_json" in result.artifact_paths:
            write_json(Path(result.artifact_paths["result_json"]), result)

    return result


async def _prove_item_with_ax(ax_config, scenario: ScenarioSpec):
    """
    函数 `_prove_item_with_ax` 调用 ax-prover 的底层 API 来证明指定目标。
    它会把 `ScenarioSpec` 转成 ax-prover 需要的 proving target，并执行单目标证明。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
      - scenario: ScenarioSpec -- 当前需要证明的场景。
    输出：
      - Any -- ax-prover 返回的最终状态对象。
    """
    from ax_prover.utils.proving import parse_prove_target, prove_single_item

    await _reset_ax_tool_runtime_state()

    target = f"{scenario.target_file}:{scenario.theorem_name}"
    items = parse_prove_target(str(REPO_ROOT), target)
    if len(items) != 1:
        raise ValueError(f"Expected exactly one proving target for {target}, got {len(items)}")
    thread_id = (
        f"atp_{scenario.scenario_key.replace('.', '_')}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    )
    try:
        return await prove_single_item(
            ax_config,
            str(REPO_ROOT),
            items[0],
            thread_id=thread_id,
        )
    finally:
        await _reset_ax_tool_runtime_state()


async def _reset_ax_tool_runtime_state() -> None:
    """
    函数 `_reset_ax_tool_runtime_state` 清理 ax-prover 工具层的跨场景运行态资源。
    当前主要用于关闭 LeanSearch 的全局 `aiohttp.ClientSession`，避免 ATP 在同一 Python 进程中
    通过多次 `asyncio.run(...)` 依次运行多个场景时，下一题复用上一题已绑定旧事件循环的会话。
    输入：
      - 无。
    输出：
      - None -- 原地关闭并清空已知的工具运行态缓存。
    """
    with contextlib.suppress(Exception):
        from ax_prover.tools import lean_search as lean_search_module

        session = getattr(lean_search_module, "_lean_search_session", None)
        if session is not None and not session.closed:
            await session.close()
        lean_search_module._lean_search_session = None


def _force_disable_langsmith() -> None:
    """
    函数 `_force_disable_langsmith` 在当前进程内硬关闭 LangSmith。
    它会清空 API key、关闭 tracing 标志，并清理 ax-prover 的 LangSmith 聚合器缓存。
    输入：
      - 无。
    输出：
      - None -- 仅修改当前进程环境变量与缓存状态。
    """
    for key in ("LANGSMITH_API_KEY", "LANGCHAIN_API_KEY"):
        os.environ[key] = ""
    for key in (
        "LANGSMITH_TRACING",
        "LANGCHAIN_TRACING",
        "LANGSMITH_TRACING_V2",
        "LANGCHAIN_TRACING_V2",
    ):
        os.environ[key] = "false"

    try:
        from ax_prover.utils.logging.langsmith import get_langsmith_aggregator

        get_langsmith_aggregator.cache_clear()
    except Exception:
        pass


def install_runtime_warning_filters() -> None:
    """
    函数 `install_runtime_warning_filters` 为 ATP 运行期安装定向告警过滤器。
    它只屏蔽已确认属于 LangChain/OpenAI 结构化输出序列化噪声的 Pydantic 告警，不影响真实异常。
    输入：
      - 无。
    输出：
      - None -- 仅修改当前进程的 warnings 过滤规则。
    """
    warnings.filterwarnings(
        "ignore",
        message=r"Pydantic serializer warnings:.*",
        category=UserWarning,
    )
    warnings.filterwarnings(
        "ignore",
        message=r".*serialized value may not be as expected.*",
        category=UserWarning,
    )


def _sanitize_ax_config(ax_config):
    """
    函数 `_sanitize_ax_config` 清理 ax-prover 配置中不应传递给 provider 的空值字段。
    它主要用于把 YAML 中留空的 `base_url` 等键移除，以便回退到 provider 默认端点。
    输入：
      - ax_config: Any -- 已合并的 ax-prover 配置对象。
    输出：
      - Any -- 清理完成后的 ax-prover 配置对象。
    """
    for llm_config in _iter_llm_configs(ax_config):
        _sanitize_llm_config(llm_config)
    return ax_config


def _sanitize_llm_config(llm_config) -> None:
    """
    函数 `_sanitize_llm_config` 清理单个 LLM 配置中的 provider 参数。
    输入：
      - llm_config: Any -- ax-prover 的单个 LLM 配置对象。
    输出：
      - None -- 原地更新 `provider_config`。
    """
    provider_config = _provider_config_dict(llm_config)
    sanitized = {
        key: value
        for key, value in provider_config.items()
        if key not in _ATP_PROVIDER_CONFIG_KEYS
        and value is not None
        and not (isinstance(value, str) and not value.strip())
    }
    _set_provider_config(llm_config, sanitized)


def _apply_llm_credentials_from_config(ax_config) -> None:
    """
    函数 `_apply_llm_credentials_from_config` 把 YAML 中声明的 API key 同步到当前进程环境。
    这样即使 ax-prover 仍优先检查环境变量，用户也可以只在 YAML 中维护接口密钥。
    输入：
      - ax_config: Any -- 已清理完成的 ax-prover 配置对象。
    输出：
      - None -- 仅更新当前进程环境变量。
    """
    for llm_config in _iter_llm_configs(ax_config):
        model = _model_name(llm_config)
        provider_config = _provider_config_dict(llm_config)
        model_provider = provider_config.get("model_provider")
        if isinstance(model_provider, str) and model_provider.strip():
            provider = model_provider.strip().replace("-", "_").lower()
        else:
            provider = model.split(":", 1)[0] if isinstance(model, str) and ":" in model else None
        env_name = _PROVIDER_API_KEY_ENV.get(provider)
        if env_name is None:
            continue
        api_key = _resolve_provider_api_key(provider_config)
        _validate_provider_api_key_source(model, provider_config, api_key)
        if api_key:
            os.environ[env_name] = str(api_key)


def _iter_llm_configs(ax_config) -> list:
    """
    函数 `_iter_llm_configs` 枚举当前 ax 配置中所有会触发真实模型调用的 LLM 配置。
    输入：
      - ax_config: Any -- 已合并的 ax-prover 配置对象。
    输出：
      - list -- prover、summary 以及 memory 中声明的 LLM 配置列表。
    """
    llm_configs = []

    prover_llm = getattr(ax_config.prover, "prover_llm", None)
    if prover_llm is not None:
        llm_configs.append(prover_llm)

    summarize_output = getattr(ax_config.prover, "summarize_output", None)
    summarize_llm = getattr(summarize_output, "llm", None)
    if summarize_llm is not None:
        llm_configs.append(summarize_llm)

    memory_config = getattr(ax_config.prover, "memory_config", None)
    init_args = getattr(memory_config, "init_args", {}) or {}
    memory_llm = init_args.get("llm_config") if isinstance(init_args, dict) else None
    if memory_llm is not None:
        llm_configs.append(memory_llm)

    return llm_configs


def _model_name(llm_config) -> str | None:
    """
    函数 `_model_name` 从对象或字典形式的 LLM 配置里读取模型名。
    输入：
      - llm_config: Any -- LLM 配置对象或字典。
    输出：
      - str | None -- 形如 `openai:gpt-5.2` 的模型名；缺失时返回 `None`。
    """
    if isinstance(llm_config, dict):
        model = llm_config.get("model")
        return str(model) if model is not None else None
    model = getattr(llm_config, "model", None)
    return str(model) if model is not None else None


def _provider_config_dict(llm_config) -> dict:
    """
    函数 `_provider_config_dict` 统一读取 LLM 配置中的 provider_config。
    输入：
      - llm_config: Any -- LLM 配置对象或字典。
    输出：
      - dict -- provider_config 的浅拷贝字典。
    """
    if isinstance(llm_config, dict):
        return dict(llm_config.get("provider_config", {}) or {})
    return dict(getattr(llm_config, "provider_config", None) or {})


def _set_provider_config(llm_config, provider_config: dict) -> None:
    """
    函数 `_set_provider_config` 将清理后的 provider_config 回写到 LLM 配置。
    输入：
      - llm_config: Any -- LLM 配置对象或字典。
      - provider_config: dict -- 需要写回的 provider 配置。
    输出：
      - None -- 原地修改传入的 LLM 配置。
    """
    if isinstance(llm_config, dict):
        llm_config["provider_config"] = provider_config
        return
    llm_config.provider_config = provider_config


def _resolve_provider_api_key(provider_config: dict) -> str | None:
    """
    函数 `_resolve_provider_api_key` 从 provider 配置里解析实际要使用的密钥。
    它优先使用内联 `api_key`，若未填写则尝试读取 ATP 扩展字段 `api_key_env`
    指向的环境变量，例如 `NEBIUS_API_KEY`。
    输入：
      - provider_config: dict -- provider 配置字典。
    输出：
      - str | None -- 解析出的密钥；未找到时返回 `None`。
    """
    api_key = provider_config.get("api_key")
    if api_key:
        return str(api_key)

    api_key_env = provider_config.get("api_key_env")
    if isinstance(api_key_env, str) and api_key_env.strip():
        env_name = api_key_env.strip()
        env_value = os.environ.get(env_name)
        if env_value:
            return env_value

    return None


def _validate_provider_api_key_source(
    model: str | None, provider_config: dict, api_key: str | None
) -> None:
    """
    函数 `_validate_provider_api_key_source` 校验显式声明的自定义密钥来源是否真实存在。
    如果 profile 写了 `api_key_env`，ATP 会要求该环境变量或内联 `api_key` 存在，避免误用
    当前进程里已有的 `OPENAI_API_KEY` 去请求 DashScope、Moonshot、Z.ai 等 OpenAI 兼容接口。
    输入：
      - model: str | None -- 当前 LLM 模型名。
      - provider_config: dict -- provider 配置字典。
      - api_key: str | None -- 已解析出的密钥。
    输出：
      - None -- 若缺少必需密钥则抛出 RuntimeError。
    """
    api_key_env = provider_config.get("api_key_env")
    if isinstance(api_key_env, str) and api_key_env.strip() and not api_key:
        raise RuntimeError(
            f"{api_key_env.strip()} is not set for {model}; set provider_config.api_key "
            f"or export {api_key_env.strip()} before running ATP."
        )


def _write_message_trace(attempt_dir: Path, state) -> str:
    """
    函数 `_write_message_trace` 将 ax-prover 的完整消息流写入 JSON 归档。
    输入：
      - attempt_dir: Path -- 当前场景尝试输出目录。
      - state: Any -- ax-prover 返回的最终状态对象。
    输出：
      - str -- 消息流归档 JSON 的路径。
    """
    payload = []
    for index, message in enumerate(state.messages, start=1):
        payload.append(
            {
                "index": index,
                "message_class": type(message).__name__,
                "type": getattr(message, "type", None),
                "content": getattr(message, "content", ""),
            }
        )
    trace_path = attempt_dir / "messages.json"
    write_json(trace_path, payload)
    return str(trace_path)


def _format_runtime_exception(ax_config, exc: Exception) -> str:
    """
    函数 `_format_runtime_exception` 将运行期底层异常转换成更可读的错误说明。
    输入：
      - ax_config: Any -- 当前运行的 ax-prover 配置对象；可能为 `None`。
      - exc: Exception -- 底层抛出的异常。
    输出：
      - str -- 适合写入结果归档的错误消息。
    """
    message = f"{type(exc).__name__}: {exc}"
    if ax_config is None:
        return message

    provider = _provider_name(ax_config)
    base_url = _base_url(ax_config)
    parsed = urlparse(base_url) if base_url else None
    if (
        provider == "openai"
        and base_url
        and parsed is not None
        and parsed.path.rstrip("/").endswith("/chat/completions")
        and ("responses" in str(exc) or "404" in str(exc))
    ):
        return (
            f"{message}. The configured OpenAI-compatible `base_url` points to the final "
            f"`/chat/completions` endpoint instead of the API root: {base_url}. "
            "The SDK appends resource paths itself, so you should configure the API root such as "
            "`https://host/v1`, not `https://host/v1/chat/completions`."
        )
    if (
        provider == "openai"
        and base_url
        and parsed is not None
        and parsed.path in {"", "/"}
        and ("model_dump" in str(exc) or "choices" in str(exc))
    ):
        return (
            f"{message}. The configured OpenAI-compatible `base_url` appears to point at a website "
            f"root instead of an API endpoint: {base_url}. "
            "If you are using a relay or proxy, configure the full API root such as `https://host/v1`; "
            "if you want the official provider endpoint, leave `base_url` empty or null in YAML."
        )
    return message


def _provider_name(ax_config) -> str:
    """
    函数 `_provider_name` 从 ax-prover 配置中提取模型 provider 名称。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- provider 名称，例如 `openai`。
    """
    model = ax_config.prover.prover_llm.model
    return model.split(":", 1)[0]


def _base_url(ax_config) -> str | None:
    """
    函数 `_base_url` 读取当前 prover_llm 的 `base_url`。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str | None -- `base_url` 字符串；未配置时返回 `None`。
    """
    provider_config = getattr(ax_config.prover.prover_llm, "provider_config", {}) or {}
    return provider_config.get("base_url")
