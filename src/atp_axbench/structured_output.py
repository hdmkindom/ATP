"""ATP compatibility layer for provider-specific structured output modes."""

from __future__ import annotations

import asyncio
import json
import logging
import sys
from datetime import datetime
from typing import Any, Callable

from langchain_core.language_models import LanguageModelInput
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage, ToolMessage
from pydantic import BaseModel

from .finalization_trace import record_structured_output_event, summarize_messages

STRUCTURED_OUTPUT_OPENAI_SCHEMA = "openai_schema"
STRUCTURED_OUTPUT_JSON_OBJECT_WITH_SCHEMA_PROMPT = "json_object_with_schema_prompt"
STRUCTURED_OUTPUT_TOOL_STRICT_PROBE = "tool_strict_probe"

VALID_STRUCTURED_OUTPUT_STRATEGIES = {
    STRUCTURED_OUTPUT_OPENAI_SCHEMA,
    STRUCTURED_OUTPUT_JSON_OBJECT_WITH_SCHEMA_PROMPT,
    STRUCTURED_OUTPUT_TOOL_STRICT_PROBE,
}

_strategy_by_model_and_base_url: dict[tuple[str, str | None], str] = {}
_strategy_by_model: dict[str, str] = {}
_timeout_by_model_and_base_url: dict[tuple[str, str | None], float] = {}
_timeout_by_model: dict[str, float] = {}

_LOGGER = logging.getLogger(__name__)

_FINALIZATION_TASK_MAX_CHARS = 9000
_TOOL_SUMMARY_MAX_CHARS = 8000
_TOOL_MESSAGE_MAX_CHARS = 1200
_REPAIR_RESPONSE_MAX_CHARS = 3000


def register_structured_output_strategies(ax_config) -> None:
    """
    函数 `register_structured_output_strategies` 从 ax-prover 配置中收集 ATP 结构化输出策略。
    它会把 `provider_config.structured_output_strategy` 登记到运行期注册表，并在需要时安装
    ax-prover LLM 调用函数的本地 monkey patch；该函数只修改当前 Python 进程，不改 site-packages 文件。
    输入：
      - ax_config: Any -- 已合并但尚未清洗 provider_config 的 ax-prover 配置对象。
    输出：
      - None -- 原地更新当前进程内的结构化输出策略注册表。
    """
    has_non_default_strategy = False
    for llm_config in _iter_llm_configs(ax_config):
        provider_config = _provider_config_dict(llm_config)
        strategy = strategy_from_provider_config(provider_config)
        timeout_seconds = structured_output_timeout_from_provider_config(provider_config)
        model_names = _model_name_candidates(_model_name(llm_config))
        base_url = _normalize_base_url(provider_config.get("base_url"))

        for model_name in model_names:
            _strategy_by_model[model_name] = strategy
            _strategy_by_model_and_base_url[(model_name, base_url)] = strategy
            if timeout_seconds is not None:
                _timeout_by_model[model_name] = timeout_seconds
                _timeout_by_model_and_base_url[(model_name, base_url)] = timeout_seconds

        if strategy != STRUCTURED_OUTPUT_OPENAI_SCHEMA:
            has_non_default_strategy = True

    if has_non_default_strategy:
        install_structured_output_patch()


def strategy_from_provider_config(provider_config: dict[str, Any]) -> str:
    """
    函数 `strategy_from_provider_config` 解析并校验 ATP 结构化输出策略字段。
    输入：
      - provider_config: dict[str, Any] -- LLM provider 配置。
    输出：
      - str -- 结构化输出策略名称。
    """
    raw_strategy = provider_config.get(
        "structured_output_strategy", STRUCTURED_OUTPUT_OPENAI_SCHEMA
    )
    strategy = str(raw_strategy or STRUCTURED_OUTPUT_OPENAI_SCHEMA).strip()
    if strategy not in VALID_STRUCTURED_OUTPUT_STRATEGIES:
        valid = ", ".join(sorted(VALID_STRUCTURED_OUTPUT_STRATEGIES))
        raise ValueError(f"Unsupported structured_output_strategy {strategy!r}; expected one of: {valid}")
    return strategy


def structured_output_timeout_from_provider_config(provider_config: dict[str, Any]) -> float | None:
    """
    函数 `structured_output_timeout_from_provider_config` 解析 ATP 结构化输出请求硬超时。
    输入：
      - provider_config: dict[str, Any] -- LLM provider 配置。
    输出：
      - float | None -- 单次结构化输出调用的秒级超时；未配置时返回 None。
    """
    raw_timeout = provider_config.get("structured_output_timeout_seconds")
    if raw_timeout in (None, ""):
        return None
    timeout_seconds = float(raw_timeout)
    if timeout_seconds <= 0:
        raise ValueError(
            "structured_output_timeout_seconds must be a positive number of seconds."
        )
    return timeout_seconds


def install_structured_output_patch() -> None:
    """
    函数 `install_structured_output_patch` 安装 ax-prover 结构化输出调用的运行时补丁。
    它会优先保留 ax-prover 原始实现，然后只在当前 LLM 注册为 ATP 兼容策略时接管调用。
    输入：
      - 无。
    输出：
      - None -- 当前进程内完成补丁安装。
    """
    import ax_prover.utils.llm as llm_module

    if getattr(llm_module, "_atp_structured_output_patch_installed", False):
        return

    original = llm_module.ainvoke_retry_with_structured_output
    llm_module._atp_original_ainvoke_retry_with_structured_output = original

    async def patched_ainvoke_retry_with_structured_output(
        messages: LanguageModelInput, llm, schema: type[BaseModel] | BaseModel
    ):
        return await ainvoke_retry_with_structured_output_strategy(
            messages=messages,
            llm=llm,
            schema=schema,
            fallback=original,
        )

    llm_module.ainvoke_retry_with_structured_output = patched_ainvoke_retry_with_structured_output
    llm_module._atp_structured_output_patch_installed = True

    agent_module = sys.modules.get("ax_prover.prover.agent")
    if agent_module is not None:
        agent_module.ainvoke_retry_with_structured_output = (
            patched_ainvoke_retry_with_structured_output
        )


async def ainvoke_retry_with_structured_output_strategy(
    messages: LanguageModelInput,
    llm,
    schema: type[BaseModel] | BaseModel,
    fallback: Callable[[LanguageModelInput, Any, Any], Any],
):
    """
    函数 `ainvoke_retry_with_structured_output_strategy` 根据当前 LLM 选择结构化输出调用方式。
    输入：
      - messages: LanguageModelInput -- 原始 LangChain 消息。
      - llm: Any -- 可能已经绑定工具和 retry 的 LangChain runnable。
      - schema: type[BaseModel] | BaseModel -- ax-prover 期望的 Pydantic 输出 schema。
      - fallback: Callable -- ax-prover 原始结构化输出函数。
    输出：
      - Any -- LLM 返回消息。
    """
    strategy = resolve_strategy_for_llm(llm)
    if strategy == STRUCTURED_OUTPUT_JSON_OBJECT_WITH_SCHEMA_PROMPT:
        timeout_seconds = resolve_structured_output_timeout_for_llm(llm)
        source_messages = _message_list(messages)
        llm_has_tools = _llm_has_bound_tools(llm)
        if _contains_tool_message(messages):
            if llm_has_tools:
                invoke_messages = add_json_schema_instruction(messages, schema)
                return await _ainvoke_llm(
                    llm,
                    invoke_messages,
                    timeout_seconds=timeout_seconds,
                    stage="tool_intermediate",
                    input_messages=source_messages,
                    llm_has_bound_tools=llm_has_tools,
                    raw_tool_protocol_removed=False,
                )
            return await _ainvoke_tool_finalization(
                messages,
                llm,
                schema,
                timeout_seconds=timeout_seconds,
                llm_has_bound_tools=llm_has_tools,
            )
        invoke_messages = add_json_schema_instruction(messages, schema)
        return await _ainvoke_llm(
            llm,
            invoke_messages,
            timeout_seconds=timeout_seconds,
            stage="initial_with_tools" if llm_has_tools else "initial_structured",
            input_messages=source_messages,
            llm_has_bound_tools=llm_has_tools,
            raw_tool_protocol_removed=False,
            response_format={"type": "json_object"},
        )
    if strategy == STRUCTURED_OUTPUT_TOOL_STRICT_PROBE:
        return await fallback(messages, llm, schema)
    return await fallback(messages, llm, schema)


def add_json_schema_instruction(
    messages: LanguageModelInput, schema: type[BaseModel] | BaseModel
) -> LanguageModelInput:
    """
    函数 `add_json_schema_instruction` 为 JSON Object 模式追加严格 schema 提示。
    输入：
      - messages: LanguageModelInput -- 原始消息。
      - schema: type[BaseModel] | BaseModel -- 期望输出的 Pydantic schema。
    输出：
      - LanguageModelInput -- 附加 schema 约束后的消息。
    """
    schema_json = json.dumps(_schema_json(schema), ensure_ascii=False)
    instruction = HumanMessage(
        content=(
            "Return exactly one valid JSON object and no Markdown fences. "
            "The JSON object must conform to this schema:\n"
            f"{schema_json}"
        )
    )
    if isinstance(messages, list):
        return [*messages, instruction]
    return [messages, instruction]


def resolve_strategy_for_llm(llm) -> str:
    """
    函数 `resolve_strategy_for_llm` 根据 LangChain LLM 对象解析 ATP 结构化输出策略。
    输入：
      - llm: Any -- LangChain chat model 或绑定后的 runnable。
    输出：
      - str -- 结构化输出策略名称。
    """
    base_llm = _unwrap_bound_llm(llm)
    base_url = _normalize_base_url(
        getattr(base_llm, "openai_api_base", None)
        or getattr(base_llm, "base_url", None)
        or getattr(base_llm, "openai_api_base_url", None)
    )
    for model_name in _model_name_candidates(
        getattr(base_llm, "model_name", None)
        or getattr(base_llm, "model", None)
        or getattr(base_llm, "deployment_name", None)
    ):
        strategy = _strategy_by_model_and_base_url.get((model_name, base_url))
        if strategy:
            return strategy
        strategy = _strategy_by_model.get(model_name)
        if strategy:
            return strategy
    return STRUCTURED_OUTPUT_OPENAI_SCHEMA


def structured_output_registry_snapshot() -> dict[str, Any]:
    """
    函数 `structured_output_registry_snapshot` 返回当前策略注册表快照，供测试和诊断使用。
    输入：
      - 无。
    输出：
      - dict[str, Any] -- 可序列化的注册表摘要。
    """
    return {
        "by_model": dict(_strategy_by_model),
        "by_model_and_base_url": {
            f"{model}|{base_url or ''}": strategy
            for (model, base_url), strategy in _strategy_by_model_and_base_url.items()
        },
        "timeout_by_model": dict(_timeout_by_model),
        "timeout_by_model_and_base_url": {
            f"{model}|{base_url or ''}": timeout_seconds
            for (model, base_url), timeout_seconds in _timeout_by_model_and_base_url.items()
        },
    }


def _schema_json(schema: type[BaseModel] | BaseModel) -> dict[str, Any]:
    if isinstance(schema, type) and issubclass(schema, BaseModel):
        return schema.model_json_schema()
    if isinstance(schema, BaseModel):
        return schema.model_json_schema()
    if hasattr(schema, "model_json_schema"):
        return schema.model_json_schema()
    raise TypeError(f"Unsupported structured output schema: {schema!r}")


def _unwrap_bound_llm(llm):
    current = llm
    seen: set[int] = set()
    while hasattr(current, "bound") and id(current) not in seen:
        seen.add(id(current))
        next_current = current.bound
        if next_current is current:
            break
        current = next_current
    return current


def _iter_llm_configs(ax_config) -> list:
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


def _provider_config_dict(llm_config) -> dict:
    if isinstance(llm_config, dict):
        return dict(llm_config.get("provider_config", {}) or {})
    return dict(getattr(llm_config, "provider_config", None) or {})


def _model_name(llm_config) -> str | None:
    if isinstance(llm_config, dict):
        model = llm_config.get("model")
        return str(model) if model is not None else None
    model = getattr(llm_config, "model", None)
    return str(model) if model is not None else None


def _model_name_candidates(model: Any) -> list[str]:
    if model is None:
        return []
    model_text = str(model)
    candidates = [model_text]
    if ":" in model_text:
        candidates.append(model_text.split(":", 1)[1])
    return list(dict.fromkeys(candidates))


def _normalize_base_url(base_url: Any) -> str | None:
    if base_url is None:
        return None
    base_url_text = str(base_url).strip()
    if not base_url_text:
        return None
    return base_url_text.rstrip("/")


def _contains_tool_message(messages: LanguageModelInput) -> bool:
    return any(isinstance(message, ToolMessage) for message in _message_list(messages))


async def _ainvoke_llm(
    llm,
    messages: LanguageModelInput,
    *,
    timeout_seconds: float | None,
    stage: str,
    input_messages: list[BaseMessage] | None,
    llm_has_bound_tools: bool,
    raw_tool_protocol_removed: bool,
    response_format: Any = None,
    **kwargs,
):
    if response_format is not None:
        kwargs["response_format"] = response_format

    outgoing_messages = _message_list(messages)
    _record_structured_output_request(
        stage=stage,
        input_messages=input_messages or outgoing_messages,
        outgoing_messages=outgoing_messages,
        timeout_seconds=timeout_seconds,
        response_format=response_format,
        llm_has_bound_tools=llm_has_bound_tools,
        raw_tool_protocol_removed=raw_tool_protocol_removed,
    )
    request = llm.ainvoke(messages, **kwargs)
    if timeout_seconds is None:
        try:
            response = await request
            _print_structured_output_done(stage)
            return response
        except Exception as exc:
            _print_structured_output_error(stage, exc)
            raise
    try:
        response = await asyncio.wait_for(request, timeout=timeout_seconds)
        _print_structured_output_done(stage)
        return response
    except TimeoutError as exc:
        _LOGGER.warning(
            "ATP structured output request stage=%s exceeded %.1f seconds; aborting this LLM call.",
            stage,
            timeout_seconds,
        )
        raise TimeoutError(
            f"ATP structured output request stage={stage} exceeded {timeout_seconds:.1f} seconds"
        ) from exc
    except Exception as exc:
        _print_structured_output_error(stage, exc)
        raise


async def _ainvoke_tool_finalization(
    messages: LanguageModelInput,
    llm,
    schema: type[BaseModel] | BaseModel,
    *,
    timeout_seconds: float | None,
    llm_has_bound_tools: bool,
):
    source_messages = _message_list(messages)
    finalization_messages = build_tool_finalization_messages(messages, schema)
    response = await _ainvoke_llm(
        llm,
        finalization_messages,
        timeout_seconds=timeout_seconds,
        stage="tool_finalization",
        input_messages=source_messages,
        llm_has_bound_tools=llm_has_bound_tools,
        raw_tool_protocol_removed=True,
        response_format={"type": "json_object"},
    )
    if _response_needs_json_repair(response, schema):
        repair_messages = build_tool_finalization_repair_messages(
            messages=messages,
            schema=schema,
            bad_response_text=getattr(response, "text", str(response)),
        )
        response = await _ainvoke_llm(
            llm,
            repair_messages,
            timeout_seconds=timeout_seconds,
            stage="tool_repair",
            input_messages=source_messages,
            llm_has_bound_tools=llm_has_bound_tools,
            raw_tool_protocol_removed=True,
            response_format={"type": "json_object"},
        )
    return response


def resolve_structured_output_timeout_for_llm(llm) -> float | None:
    base_llm = _unwrap_bound_llm(llm)
    base_url = _normalize_base_url(
        getattr(base_llm, "openai_api_base", None)
        or getattr(base_llm, "base_url", None)
        or getattr(base_llm, "openai_api_base_url", None)
    )
    for model_name in _model_name_candidates(
        getattr(base_llm, "model_name", None)
        or getattr(base_llm, "model", None)
        or getattr(base_llm, "deployment_name", None)
    ):
        timeout_seconds = _timeout_by_model_and_base_url.get((model_name, base_url))
        if timeout_seconds is not None:
            return timeout_seconds
        timeout_seconds = _timeout_by_model.get(model_name)
        if timeout_seconds is not None:
            return timeout_seconds
    return None


def build_tool_finalization_messages(
    messages: LanguageModelInput,
    schema: type[BaseModel] | BaseModel,
) -> list[BaseMessage]:
    source_messages = _message_list(messages)
    task_text = _truncate(_task_text(source_messages), _FINALIZATION_TASK_MAX_CHARS)
    tool_summary = _tool_summary_text(source_messages)
    schema_json = json.dumps(_schema_json(schema), ensure_ascii=False)
    return [
        SystemMessage(
            content=(
                "ATP finalization mode: tool use is finished. You are no longer allowed "
                "to call tools or request more searches. Return one best-effort JSON object now."
            ).strip()
        ),
        HumanMessage(
            content=(
                "Use only the task excerpt and tool observations below. Do not continue "
                "analysis, do not emit DSML tags, and do not emit function calls.\n\n"
                "<original-task-excerpt>\n"
                f"{task_text}\n"
                "</original-task-excerpt>\n\n"
                "<tool-observations>\n"
                f"{tool_summary}\n"
                "</tool-observations>\n\n"
                "Return exactly one valid JSON object with no Markdown fences and no extra text. "
                "If the tool result is insufficient, still produce the best Lean proof attempt "
                "you can from the current information. The JSON object must conform to this schema:\n"
                f"{schema_json}"
            )
        ),
    ]


def build_tool_finalization_repair_messages(
    messages: LanguageModelInput,
    schema: type[BaseModel] | BaseModel,
    bad_response_text: str,
) -> list[BaseMessage]:
    finalization_messages = build_tool_finalization_messages(messages, schema)
    schema_json = json.dumps(_schema_json(schema), ensure_ascii=False)
    bad_response_excerpt = _truncate(str(bad_response_text), _REPAIR_RESPONSE_MAX_CHARS)
    finalization_messages.append(
        HumanMessage(
            content=(
                "The previous response was not valid JSON for the required schema. "
                "Ignore any DSML/tool_calls/function-call text and repair the answer now.\n\n"
                "<invalid-response-excerpt>\n"
                f"{bad_response_excerpt}\n"
                "</invalid-response-excerpt>\n\n"
                "Return exactly one valid JSON object and nothing else. Schema:\n"
                f"{schema_json}"
            )
        )
    )
    return finalization_messages


def _response_needs_json_repair(response: Any, schema: type[BaseModel] | BaseModel) -> bool:
    if getattr(response, "tool_calls", None):
        return True
    additional_kwargs = getattr(response, "additional_kwargs", {}) or {}
    if additional_kwargs.get("tool_calls"):
        return True
    response_text = getattr(response, "text", None)
    if response_text is None:
        response_text = getattr(response, "content", "")
    response_text = str(response_text)
    if "DSML" in response_text or "tool_calls" in response_text:
        return True
    try:
        if isinstance(schema, type) and issubclass(schema, BaseModel):
            schema.model_validate_json(response_text)
            return False
        if hasattr(schema, "model_validate_json"):
            schema.model_validate_json(response_text)
            return False
    except Exception:
        return True
    return False


def _llm_has_bound_tools(llm: Any) -> bool:
    current = llm
    seen: set[int] = set()
    while id(current) not in seen:
        seen.add(id(current))
        kwargs = getattr(current, "kwargs", None)
        if isinstance(kwargs, dict) and kwargs.get("tools"):
            return True
        bound = getattr(current, "bound", None)
        if bound is None or bound is current:
            break
        current = bound
    return False


def _record_structured_output_request(
    *,
    stage: str,
    input_messages: list[BaseMessage],
    outgoing_messages: list[BaseMessage],
    timeout_seconds: float | None,
    response_format: Any,
    llm_has_bound_tools: bool,
    raw_tool_protocol_removed: bool,
) -> None:
    input_summary = summarize_messages(input_messages)
    outgoing_summary = summarize_messages(outgoing_messages)
    artifact_path = record_structured_output_event(
        stage=stage,
        input_messages=input_messages,
        outgoing_messages=outgoing_messages,
        timeout_seconds=timeout_seconds,
        response_format=response_format,
        llm_has_bound_tools=llm_has_bound_tools,
        raw_tool_protocol_removed=raw_tool_protocol_removed,
    )
    artifact_suffix = f" artifact={artifact_path}" if artifact_path else ""
    _print_structured_output_info(
        "sending",
        stage=stage,
        timeout_seconds=timeout_seconds,
        response_format=response_format,
        llm_has_bound_tools=llm_has_bound_tools,
        raw_tool_protocol_removed=raw_tool_protocol_removed,
        input_summary=input_summary,
        outgoing_summary=outgoing_summary,
        artifact_suffix=artifact_suffix,
    )


def _print_structured_output_info(
    action: str,
    *,
    stage: str,
    timeout_seconds: float | None,
    response_format: Any,
    llm_has_bound_tools: bool,
    raw_tool_protocol_removed: bool,
    input_summary: dict[str, Any],
    outgoing_summary: dict[str, Any],
    artifact_suffix: str,
) -> None:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(
        f"{timestamp} - INFO - [structured_output] - {action} stage={stage} "
        f"timeout={timeout_seconds} response_format={_response_format_label(response_format)} "
        f"llm_has_tools={llm_has_bound_tools} raw_tool_protocol_removed={raw_tool_protocol_removed} "
        f"input_messages={input_summary['message_count']} input_chars={input_summary['total_content_chars']} "
        f"input_tool_messages={input_summary['tool_message_count']} input_ai_tool_calls={input_summary['ai_tool_call_count']} "
        f"outgoing_messages={outgoing_summary['message_count']} outgoing_chars={outgoing_summary['total_content_chars']} "
        f"outgoing_tool_messages={outgoing_summary['tool_message_count']} outgoing_ai_tool_calls={outgoing_summary['ai_tool_call_count']}"
        f"{artifact_suffix}",
        flush=True,
    )


def _print_structured_output_done(stage: str) -> None:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{timestamp} - INFO - [structured_output] - completed stage={stage}", flush=True)


def _print_structured_output_error(stage: str, exc: BaseException) -> None:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(
        f"{timestamp} - ERROR - [structured_output] - failed stage={stage} "
        f"error={type(exc).__name__}: {exc}",
        flush=True,
    )


def _response_format_label(response_format: Any) -> str:
    if response_format is None:
        return "none"
    if isinstance(response_format, dict):
        return str(response_format.get("type") or response_format)
    return type(response_format).__name__


def _message_list(messages: LanguageModelInput) -> list[BaseMessage]:
    if isinstance(messages, list):
        return [message for message in messages if isinstance(message, BaseMessage)]
    if isinstance(messages, tuple):
        return [message for message in messages if isinstance(message, BaseMessage)]
    if isinstance(messages, BaseMessage):
        return [messages]
    if hasattr(messages, "to_messages"):
        converted = messages.to_messages()
        if isinstance(converted, list):
            return [message for message in converted if isinstance(message, BaseMessage)]
    return []


def _system_text(messages: list[BaseMessage]) -> str:
    system_parts = [
        str(message.content)
        for message in messages
        if isinstance(message, SystemMessage) and str(message.content).strip()
    ]
    return "\n\n".join(system_parts) or "You are an LLM acting as a Lean 4 proof expert."


def _task_text(messages: list[BaseMessage]) -> str:
    task_parts = []
    for message in messages:
        if not isinstance(message, HumanMessage):
            continue
        content = str(message.content)
        if "Return exactly one valid JSON object" in content:
            continue
        if "NO MORE TOOL CALLS ALLOWED" in content:
            continue
        task_parts.append(content)
    return "\n\n".join(task_parts).strip() or "Complete the Lean proof."


def _tool_summary_text(messages: list[BaseMessage]) -> str:
    summaries: list[str] = []
    search_index = 1
    for index, message in enumerate(messages):
        if not isinstance(message, ToolMessage):
            continue
        call_description = _preceding_tool_call_description(messages, index)
        content = _truncate(str(message.content), _TOOL_MESSAGE_MAX_CHARS)
        summaries.append(
            f"Tool observation {search_index}: {call_description}\n{content}".strip()
        )
        search_index += 1
    summary = "\n\n".join(summaries)
    return _truncate(summary, _TOOL_SUMMARY_MAX_CHARS) or "No tool observations were available."


def _preceding_tool_call_description(messages: list[BaseMessage], tool_message_index: int) -> str:
    tool_message = messages[tool_message_index]
    tool_call_id = getattr(tool_message, "tool_call_id", None)
    for message in reversed(messages[:tool_message_index]):
        if not isinstance(message, AIMessage):
            continue
        for tool_call in getattr(message, "tool_calls", []) or []:
            if tool_call.get("id") != tool_call_id:
                continue
            return (
                f"{tool_call.get('name', 'tool')} "
                f"args={json.dumps(tool_call.get('args', {}), ensure_ascii=False)}"
            )
    return f"tool_call_id={tool_call_id}"


def _truncate(text: str, max_chars: int) -> str:
    if len(text) <= max_chars:
        return text
    omitted = len(text) - max_chars
    return f"{text[:max_chars]}\n... [truncated {omitted} chars]"
