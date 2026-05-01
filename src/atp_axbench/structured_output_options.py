"""Configuration parsing for ATP structured-output compatibility."""

from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Any

STRUCTURED_OUTPUT_FINALIZATION_NATIVE_TOOL_PROTOCOL = "native_tool_protocol"
STRUCTURED_OUTPUT_FINALIZATION_SUMMARIZED_PROMPT = "summarized_prompt"

VALID_STRUCTURED_OUTPUT_FINALIZATION_MODES = {
    STRUCTURED_OUTPUT_FINALIZATION_NATIVE_TOOL_PROTOCOL,
    STRUCTURED_OUTPUT_FINALIZATION_SUMMARIZED_PROMPT,
}

STRUCTURED_OUTPUT_PROVIDER_CONFIG_KEYS = frozenset(
    {
        "structured_output_strategy",
        "structured_output_timeout_seconds",
        "structured_output_finalization_mode",
        "structured_output_finalization_prefer_streaming",
        "structured_output_finalization_task_max_chars",
        "structured_output_tool_summary_max_chars",
        "structured_output_tool_message_max_chars",
        "structured_output_repair_response_max_chars",
    }
)


@dataclass(frozen=True)
class StructuredOutputOptions:
    """ATP-only knobs for provider structured-output shims."""

    timeout_seconds: float | None = None
    finalization_mode: str = STRUCTURED_OUTPUT_FINALIZATION_NATIVE_TOOL_PROTOCOL
    finalization_prefer_streaming: bool = True
    finalization_task_max_chars: int = 9000
    tool_summary_max_chars: int = 8000
    tool_message_max_chars: int = 1200
    repair_response_max_chars: int = 3000

    @property
    def uses_native_tool_protocol(self) -> bool:
        return self.finalization_mode == STRUCTURED_OUTPUT_FINALIZATION_NATIVE_TOOL_PROTOCOL

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


DEFAULT_STRUCTURED_OUTPUT_OPTIONS = StructuredOutputOptions()


def structured_output_options_from_provider_config(
    provider_config: dict[str, Any],
) -> StructuredOutputOptions:
    """Parse ATP structured-output options from a provider config dictionary."""

    return StructuredOutputOptions(
        timeout_seconds=_positive_float_or_none(
            provider_config.get("structured_output_timeout_seconds"),
            "structured_output_timeout_seconds",
        ),
        finalization_mode=_finalization_mode(
            provider_config.get("structured_output_finalization_mode")
        ),
        finalization_prefer_streaming=_bool_option(
            provider_config.get("structured_output_finalization_prefer_streaming"),
            default=DEFAULT_STRUCTURED_OUTPUT_OPTIONS.finalization_prefer_streaming,
            name="structured_output_finalization_prefer_streaming",
        ),
        finalization_task_max_chars=_positive_int_option(
            provider_config.get("structured_output_finalization_task_max_chars"),
            default=DEFAULT_STRUCTURED_OUTPUT_OPTIONS.finalization_task_max_chars,
            name="structured_output_finalization_task_max_chars",
        ),
        tool_summary_max_chars=_positive_int_option(
            provider_config.get("structured_output_tool_summary_max_chars"),
            default=DEFAULT_STRUCTURED_OUTPUT_OPTIONS.tool_summary_max_chars,
            name="structured_output_tool_summary_max_chars",
        ),
        tool_message_max_chars=_positive_int_option(
            provider_config.get("structured_output_tool_message_max_chars"),
            default=DEFAULT_STRUCTURED_OUTPUT_OPTIONS.tool_message_max_chars,
            name="structured_output_tool_message_max_chars",
        ),
        repair_response_max_chars=_positive_int_option(
            provider_config.get("structured_output_repair_response_max_chars"),
            default=DEFAULT_STRUCTURED_OUTPUT_OPTIONS.repair_response_max_chars,
            name="structured_output_repair_response_max_chars",
        ),
    )


def _positive_float_or_none(raw_value: Any, name: str) -> float | None:
    if raw_value in (None, ""):
        return None
    value = float(raw_value)
    if value <= 0:
        raise ValueError(f"{name} must be a positive number of seconds.")
    return value


def _positive_int_option(raw_value: Any, *, default: int, name: str) -> int:
    if raw_value in (None, ""):
        return default
    value = int(raw_value)
    if value <= 0:
        raise ValueError(f"{name} must be a positive integer.")
    return value


def _bool_option(raw_value: Any, *, default: bool, name: str) -> bool:
    if raw_value in (None, ""):
        return default
    if isinstance(raw_value, bool):
        return raw_value
    if isinstance(raw_value, str):
        normalized = raw_value.strip().lower()
        if normalized in {"1", "true", "yes", "on"}:
            return True
        if normalized in {"0", "false", "no", "off"}:
            return False
    raise ValueError(f"{name} must be a boolean.")


def _finalization_mode(raw_value: Any) -> str:
    if raw_value in (None, ""):
        return DEFAULT_STRUCTURED_OUTPUT_OPTIONS.finalization_mode
    mode = str(raw_value).strip()
    if mode not in VALID_STRUCTURED_OUTPUT_FINALIZATION_MODES:
        valid = ", ".join(sorted(VALID_STRUCTURED_OUTPUT_FINALIZATION_MODES))
        raise ValueError(
            f"structured_output_finalization_mode {mode!r} is invalid; expected one of: {valid}"
        )
    return mode
