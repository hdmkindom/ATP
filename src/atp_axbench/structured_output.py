"""ATP compatibility layer for provider-specific structured output modes."""

from __future__ import annotations

import json
import sys
from typing import Any, Callable

from langchain_core.language_models import LanguageModelInput
from langchain_core.messages import HumanMessage, ToolMessage
from pydantic import BaseModel

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
        strategy = strategy_from_provider_config(_provider_config_dict(llm_config))
        model_names = _model_name_candidates(_model_name(llm_config))
        base_url = _normalize_base_url(_provider_config_dict(llm_config).get("base_url"))

        for model_name in model_names:
            _strategy_by_model[model_name] = strategy
            _strategy_by_model_and_base_url[(model_name, base_url)] = strategy

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
        invoke_messages = add_json_schema_instruction(messages, schema)
        if _contains_tool_message(messages):
            return await llm.ainvoke(invoke_messages)
        return await llm.ainvoke(invoke_messages, response_format={"type": "json_object"})
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
    if isinstance(messages, list):
        return any(isinstance(message, ToolMessage) for message in messages)
    return isinstance(messages, ToolMessage)
