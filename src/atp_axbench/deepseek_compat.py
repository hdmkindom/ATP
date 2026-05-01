"""ATP runtime compatibility patches for DeepSeek thinking/tool calls."""

from __future__ import annotations

from typing import Any

from langchain_core.messages import AIMessage, BaseMessage

DEEPSEEK_PROVIDER_CONFIG_KEYS = frozenset({"deepseek_profile_max_input_tokens"})

_DEFAULT_DEEPSEEK_PROFILE_MAX_INPUT_TOKENS = 131072
_profile_max_input_tokens_by_model: dict[str, int] = {}


def install_deepseek_compat_patches(ax_config: Any | None = None) -> None:
    """
    函数 `install_deepseek_compat_patches` 安装 DeepSeek thinking/tool 的运行时兼容补丁。
    它只修改当前 Python 进程中的 LangChain / ax-prover 函数引用，不改 site-packages 文件。
    输入：
      - ax_config: Any | None -- 可选 ax-prover 配置；若提供，仅当其中出现 DeepSeek 模型时安装。
    输出：
      - None -- 原地完成当前进程内的补丁安装。
    """
    if ax_config is not None and not _config_uses_deepseek(ax_config):
        return

    if ax_config is not None:
        _register_deepseek_profile_options(ax_config)
    _install_deepseek_strict_tool_binding_patch()
    _install_deepseek_llm_profile_patch()
    _install_deepseek_reasoning_content_payload_patch()
    _install_get_reasoning_patch()


def _register_deepseek_profile_options(ax_config: Any) -> None:
    for llm_config in _iter_llm_configs(ax_config):
        model = _model_name(llm_config)
        if not model or not model.lower().startswith("deepseek:"):
            continue
        provider_config = _provider_config_dict(llm_config)
        max_input_tokens = _positive_int_option(
            provider_config.get("deepseek_profile_max_input_tokens"),
            default=_DEFAULT_DEEPSEEK_PROFILE_MAX_INPUT_TOKENS,
            name="deepseek_profile_max_input_tokens",
        )
        for model_name in _model_name_candidates(model):
            _profile_max_input_tokens_by_model[model_name] = max_input_tokens


def _install_deepseek_strict_tool_binding_patch() -> None:
    try:
        from langchain_deepseek import ChatDeepSeek
    except ImportError:
        return

    if getattr(ChatDeepSeek, "_atp_strict_tool_binding_patch_installed", False):
        return

    original_bind_tools = ChatDeepSeek.bind_tools

    def patched_bind_tools(
        self,
        tools,
        *,
        tool_choice=None,
        strict=None,
        parallel_tool_calls=None,
        **kwargs,
    ):
        if strict is None and tools:
            strict = True
        return original_bind_tools(
            self,
            tools,
            tool_choice=tool_choice,
            strict=strict,
            parallel_tool_calls=parallel_tool_calls,
            **kwargs,
        )

    ChatDeepSeek._atp_original_bind_tools = original_bind_tools
    ChatDeepSeek.bind_tools = patched_bind_tools
    ChatDeepSeek._atp_strict_tool_binding_patch_installed = True


def _install_deepseek_llm_profile_patch() -> None:
    try:
        import ax_prover.utils.llm as llm_module
    except ImportError:
        return

    if getattr(llm_module, "_atp_deepseek_llm_profile_patch_installed", False):
        return

    original_create_llm = llm_module.create_llm

    def patched_create_llm(config):
        llm = original_create_llm(config)
        if _llm_config_uses_deepseek(config):
            _ensure_deepseek_profile(llm, config)
        return llm

    llm_module._atp_original_create_llm = original_create_llm
    llm_module.create_llm = patched_create_llm
    llm_module._atp_deepseek_llm_profile_patch_installed = True

    try:
        import ax_prover.prover.agent as agent_module

        agent_module.create_llm = patched_create_llm
    except ImportError:
        pass


def _ensure_deepseek_profile(llm: Any, config: Any) -> None:
    profile = getattr(llm, "profile", None)
    if isinstance(profile, dict) and profile.get("max_input_tokens"):
        return

    max_input_tokens = _profile_max_input_tokens_for_config(config)
    new_profile = dict(profile or {})
    new_profile["max_input_tokens"] = max_input_tokens
    object.__setattr__(llm, "profile", new_profile)


def _profile_max_input_tokens_for_config(config: Any) -> int:
    for model_name in _model_name_candidates(_model_name(config)):
        max_input_tokens = _profile_max_input_tokens_by_model.get(model_name)
        if max_input_tokens is not None:
            return max_input_tokens
    return _DEFAULT_DEEPSEEK_PROFILE_MAX_INPUT_TOKENS


def _install_deepseek_reasoning_content_payload_patch() -> None:
    try:
        from langchain_deepseek import ChatDeepSeek
    except ImportError:
        return

    if getattr(ChatDeepSeek, "_atp_reasoning_content_payload_patch_installed", False):
        return

    original_get_request_payload = ChatDeepSeek._get_request_payload

    def patched_get_request_payload(self, input_, *, stop=None, **kwargs):
        payload = original_get_request_payload(self, input_, stop=stop, **kwargs)
        source_messages = _messages_from_input(input_)
        if not source_messages:
            return payload

        payload_messages = payload.get("messages", [])
        for source_message, payload_message in zip(source_messages, payload_messages, strict=False):
            reasoning_content = _tool_call_reasoning_content(source_message)
            if reasoning_content is not None and payload_message.get("role") == "assistant":
                payload_message["reasoning_content"] = reasoning_content
        return payload

    ChatDeepSeek._atp_original_get_request_payload = original_get_request_payload
    ChatDeepSeek._get_request_payload = patched_get_request_payload
    ChatDeepSeek._atp_reasoning_content_payload_patch_installed = True


def _install_get_reasoning_patch() -> None:
    try:
        import ax_prover.utils.llm as llm_module
    except ImportError:
        return

    if getattr(llm_module, "_atp_deepseek_get_reasoning_patch_installed", False):
        return

    original_get_reasoning = llm_module.get_reasoning

    def patched_get_reasoning(response):
        reasoning = original_get_reasoning(response)
        if reasoning:
            return reasoning
        return _message_reasoning_content(response) or ""

    llm_module._atp_original_get_reasoning = original_get_reasoning
    llm_module.get_reasoning = patched_get_reasoning
    llm_module._atp_deepseek_get_reasoning_patch_installed = True

    try:
        import ax_prover.prover.agent as agent_module

        agent_module.get_reasoning = patched_get_reasoning
    except ImportError:
        pass


def _tool_call_reasoning_content(message: BaseMessage) -> str | None:
    if not isinstance(message, AIMessage):
        return None
    if not (message.tool_calls or message.additional_kwargs.get("tool_calls")):
        return None
    return _message_reasoning_content(message)


def _message_reasoning_content(message: Any) -> str | None:
    additional_kwargs = getattr(message, "additional_kwargs", {}) or {}
    reasoning_content = additional_kwargs.get("reasoning_content")
    if isinstance(reasoning_content, str) and reasoning_content.strip():
        return reasoning_content
    return None


def _messages_from_input(input_: Any) -> list[BaseMessage]:
    if isinstance(input_, list) and all(isinstance(message, BaseMessage) for message in input_):
        return input_
    if isinstance(input_, tuple) and all(isinstance(message, BaseMessage) for message in input_):
        return list(input_)
    if hasattr(input_, "to_messages"):
        messages = input_.to_messages()
        if isinstance(messages, list):
            return [message for message in messages if isinstance(message, BaseMessage)]
    return []


def _config_uses_deepseek(ax_config: Any) -> bool:
    for llm_config in _iter_llm_configs(ax_config):
        model = _model_name(llm_config)
        if model and model.lower().startswith("deepseek:"):
            return True
    return False


def _llm_config_uses_deepseek(llm_config: Any) -> bool:
    model = _model_name(llm_config)
    return bool(model and model.lower().startswith("deepseek:"))


def _iter_llm_configs(ax_config: Any) -> list:
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


def _model_name(llm_config: Any) -> str | None:
    if isinstance(llm_config, dict):
        model = llm_config.get("model")
        return str(model) if model is not None else None
    model = getattr(llm_config, "model", None)
    return str(model) if model is not None else None


def _provider_config_dict(llm_config: Any) -> dict[str, Any]:
    if isinstance(llm_config, dict):
        return dict(llm_config.get("provider_config", {}) or {})
    return dict(getattr(llm_config, "provider_config", None) or {})


def _model_name_candidates(model: Any) -> list[str]:
    if model is None:
        return []
    model_text = str(model)
    candidates = [model_text]
    if ":" in model_text:
        candidates.append(model_text.split(":", 1)[1])
    return list(dict.fromkeys(candidates))


def _positive_int_option(raw_value: Any, *, default: int, name: str) -> int:
    if raw_value in (None, ""):
        return default
    value = int(raw_value)
    if value <= 0:
        raise ValueError(f"{name} must be a positive integer.")
    return value
