"""Structured-output finalization trace artifacts."""

from __future__ import annotations

from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass, field
from datetime import datetime
import json
from pathlib import Path
from typing import Any, Iterator

from langchain_core.messages import AIMessage, BaseMessage, ToolMessage


_ACTIVE_SESSION: ContextVar["FinalizationTraceSession | None"] = ContextVar(
    "atp_finalization_trace_session",
    default=None,
)
_CONTENT_EXCERPT_CHARS = 1200


@dataclass
class FinalizationTraceSession:
    """Per-attempt finalization trace writer."""

    attempt_dir: Path
    enabled: bool = True
    records: list[str] = field(default_factory=list)
    counter: int = 0

    @property
    def trace_dir(self) -> Path:
        return self.attempt_dir / "structured_output"

    def write_event(
        self,
        *,
        stage: str,
        input_messages: list[BaseMessage],
        outgoing_messages: list[BaseMessage] | None,
        timeout_seconds: float | None,
        response_format: Any,
        llm_has_bound_tools: bool,
        raw_tool_protocol_removed: bool,
        note: str | None = None,
    ) -> str | None:
        if not self.enabled:
            return None

        self.counter += 1
        timestamp = datetime.now()
        path = self.trace_dir / f"{timestamp.strftime('%m%d%H%M%S')}_{self.counter:02d}_{stage}.json"
        payload = {
            "stage": stage,
            "timestamp": timestamp.isoformat(),
            "timeout_seconds": timeout_seconds,
            "response_format": response_format,
            "llm_has_bound_tools": llm_has_bound_tools,
            "raw_tool_protocol_removed": raw_tool_protocol_removed,
            "note": note,
            "input": summarize_messages(input_messages),
            "outgoing": summarize_messages(outgoing_messages or []),
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        path_text = str(path)
        self.records.append(path_text)
        return path_text


@contextmanager
def finalization_trace_session(
    attempt_dir: Path,
    enabled: bool = True,
) -> Iterator[FinalizationTraceSession]:
    """Activate structured-output trace artifacts for one scenario attempt."""
    session = FinalizationTraceSession(attempt_dir=attempt_dir, enabled=enabled)
    token = _ACTIVE_SESSION.set(session)
    try:
        yield session
    finally:
        _ACTIVE_SESSION.reset(token)


def record_structured_output_event(
    *,
    stage: str,
    input_messages: list[BaseMessage],
    outgoing_messages: list[BaseMessage] | None,
    timeout_seconds: float | None,
    response_format: Any,
    llm_has_bound_tools: bool,
    raw_tool_protocol_removed: bool,
    note: str | None = None,
) -> str | None:
    """Write one structured-output trace event if a scenario attempt is active."""
    session = _ACTIVE_SESSION.get()
    if session is None:
        return None
    return session.write_event(
        stage=stage,
        input_messages=input_messages,
        outgoing_messages=outgoing_messages,
        timeout_seconds=timeout_seconds,
        response_format=response_format,
        llm_has_bound_tools=llm_has_bound_tools,
        raw_tool_protocol_removed=raw_tool_protocol_removed,
        note=note,
    )


def summarize_messages(messages: list[BaseMessage]) -> dict[str, Any]:
    """Return a compact, non-secret summary of LangChain messages."""
    message_summaries = []
    total_chars = 0
    tool_message_count = 0
    ai_tool_call_count = 0
    for index, message in enumerate(messages):
        content = str(getattr(message, "content", ""))
        total_chars += len(content)
        is_tool_message = isinstance(message, ToolMessage)
        if is_tool_message:
            tool_message_count += 1
        tool_calls = getattr(message, "tool_calls", []) or []
        additional_tool_calls = getattr(message, "additional_kwargs", {}).get("tool_calls") or []
        ai_tool_call_count += len(tool_calls) + len(additional_tool_calls)
        message_summaries.append(
            {
                "index": index,
                "type": type(message).__name__,
                "content_chars": len(content),
                "content_excerpt": _truncate(content, _CONTENT_EXCERPT_CHARS),
                "is_tool_message": is_tool_message,
                "tool_call_id": getattr(message, "tool_call_id", None),
                "ai_tool_call_count": len(tool_calls) + len(additional_tool_calls)
                if isinstance(message, AIMessage)
                else 0,
            }
        )

    return {
        "message_count": len(messages),
        "total_content_chars": total_chars,
        "tool_message_count": tool_message_count,
        "ai_tool_call_count": ai_tool_call_count,
        "messages": message_summaries,
    }


def _truncate(text: str, max_chars: int) -> str:
    if len(text) <= max_chars:
        return text
    omitted = len(text) - max_chars
    return f"{text[:max_chars]}\n... [truncated {omitted} chars]"
