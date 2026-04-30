"""Terminal colors, logging customization, and short status printers."""

from __future__ import annotations

from contextlib import contextmanager
from contextvars import ContextVar, Token
from datetime import datetime
import functools
import logging
from math import isfinite
from pathlib import Path
import sys
from time import monotonic
from typing import Any

from .settings import ConsoleSettings

INFO = "\033[34m"
DEBUG = "\033[32m"
WARNING = "\033[33m"
ERROR = "\033[31m"
STATUS = "\033[96m"
TOKEN = "\033[35m"
RESET = "\033[0m"

_ACTIVE_CONSOLE_SETTINGS = ConsoleSettings()
_LOGGING_PATCHED = False
_LLM_REQUEST_PATCHED = False
_LLM_PHASE_PATCHED = False
_LLM_REQUEST_COUNTER = 0
_TIMEOUT_LIKE_CONNECTION_SECONDS = 60.0
_ACTIVE_LLM_REQUEST_SESSION: ContextVar["LLMRequestSession | None"] = ContextVar(
    "active_llm_request_session",
    default=None,
)
_ACTIVE_LLM_REQUEST_PHASE: ContextVar["LLMRequestPhase | None"] = ContextVar(
    "active_llm_request_phase",
    default=None,
)


def colorize(text: str, color: str, enabled: bool = True) -> str:
    """
    函数 `colorize` 为终端文本添加 ANSI 颜色包裹。
    输入：
      - text: str -- 原始文本。
      - color: str -- ANSI 颜色前缀。
      - enabled: bool -- 是否启用颜色。
    输出：
      - str -- 着色后的文本；若关闭颜色则返回原文。
    """
    if not enabled:
        return text
    return f"{color}{text}{RESET}"


def format_duration(seconds: float | int | None) -> str:
    """
    函数 `format_duration` 将秒数格式化为 `HH:MM:SS`。
    输入：
      - seconds: float | int | None -- 原始秒数。
    输出：
      - str -- 人类可读的时长字符串。
    """
    if seconds is None or not isfinite(float(seconds)):
        return "--:--:--"
    total_seconds = max(0, int(round(float(seconds))))
    hours, remainder = divmod(total_seconds, 3600)
    minutes, secs = divmod(remainder, 60)
    return f"{hours:02d}:{minutes:02d}:{secs:02d}"


def format_count(value: int | float) -> str:
    """
    函数 `format_count` 将数值格式化为便于阅读的千分位形式。
    输入：
      - value: int | float -- 待显示的计数值。
    输出：
      - str -- 带千分位分隔符的字符串。
    """
    return f"{int(value):,}"


def print_info(message: str, enable_color: bool = True) -> None:
    """
    函数 `print_info` 以 INFO 颜色打印一行消息。
    输入：
      - message: str -- 需要打印的消息内容。
      - enable_color: bool -- 是否启用颜色。
    输出：
      - None -- 文本直接打印到终端。
    """
    print(colorize(message, INFO, enable_color), flush=True)


def print_warning(message: str, enable_color: bool = True) -> None:
    """
    函数 `print_warning` 以 WARNING 颜色打印一行消息。
    输入：
      - message: str -- 需要打印的消息内容。
      - enable_color: bool -- 是否启用颜色。
    输出：
      - None -- 文本直接打印到终端。
    """
    print(colorize(message, WARNING, enable_color), flush=True)


def print_error(message: str, enable_color: bool = True) -> None:
    """
    函数 `print_error` 以 ERROR 颜色打印一行消息。
    输入：
      - message: str -- 需要打印的消息内容。
      - enable_color: bool -- 是否启用颜色。
    输出：
      - None -- 文本直接打印到终端。
    """
    print(colorize(message, ERROR, enable_color), flush=True)


def print_status(message: str, enable_color: bool = True) -> None:
    """
    函数 `print_status` 以浅蓝色打印运行状态信息。
    输入：
      - message: str -- 需要打印的状态文本。
      - enable_color: bool -- 是否启用颜色。
    输出：
      - None -- 文本直接打印到终端。
    """
    print(colorize(message, STATUS, enable_color), flush=True)


def print_token(message: str, enable_color: bool = True) -> None:
    """
    函数 `print_token` 以紫色打印请求与 token 统计信息。
    输入：
      - message: str -- 需要打印的统计文本。
      - enable_color: bool -- 是否启用颜色。
    输出：
      - None -- 文本直接打印到终端。
    """
    print(colorize(message, TOKEN, enable_color), flush=True)


class _ColorizingFormatter(logging.Formatter):
    """将现有 formatter 的输出按日志级别加上 ANSI 颜色。"""

    def __init__(self, delegate: logging.Formatter, enable_color: bool):
        super().__init__()
        self.delegate = delegate
        self.enable_color = enable_color

    def format(self, record: logging.LogRecord) -> str:
        rendered = self.delegate.format(record)
        return colorize(rendered, _color_for_level(record.levelname), self.enable_color)


class _KnownAxNoiseFilter(logging.Filter):
    """过滤已知且无害的 ax-prover 构建噪声日志。"""

    def __init__(self, settings: ConsoleSettings):
        super().__init__()
        self.settings = settings

    def filter(self, record: logging.LogRecord) -> bool:
        if not self.settings.suppress_known_build_fallback_warning:
            return True
        message = record.getMessage()
        if "failed: unknown target. Falling back to 'lake env lean" in message:
            return False
        return True


def install_console_logging(settings: ConsoleSettings) -> None:
    """
    函数 `install_console_logging` 为 ax-prover 日志安装颜色与噪声过滤策略。
    它不会修改 ax-prover 源文件，而是在当前 Python 进程中替换 formatter 与 filter。
    输入：
      - settings: ConsoleSettings -- 终端展示设置。
    输出：
      - None -- 仅修改当前进程中的 logging 行为。
    """
    global _ACTIVE_CONSOLE_SETTINGS, _LOGGING_PATCHED
    _ACTIVE_CONSOLE_SETTINGS = settings

    try:
        import ax_prover.utils.logging.logger as ax_logger_module
    except Exception:
        return

    if not _LOGGING_PATCHED:
        original_setup_logger = ax_logger_module._setup_logger

        def _wrapped_setup_logger(name: str | None = None, level: str = "INFO") -> logging.Logger:
            logger = original_setup_logger(name=name, level=level)
            _apply_console_policy_to_logger(logger, _ACTIVE_CONSOLE_SETTINGS)
            return logger

        ax_logger_module._setup_logger = _wrapped_setup_logger
        _LOGGING_PATCHED = True

    for logger in _iter_ax_loggers():
        _apply_console_policy_to_logger(logger, settings)


def _iter_ax_loggers() -> list[logging.Logger]:
    """
    函数 `_iter_ax_loggers` 枚举当前进程中已经创建的 ax-prover 日志器。
    输入：
      - 无。
    输出：
      - list[logging.Logger] -- 所有 ax_prover 命名空间下的 logger 对象。
    """
    loggers: list[logging.Logger] = []
    for name, logger_ref in logging.Logger.manager.loggerDict.items():
        if name.startswith("ax_prover") and isinstance(logger_ref, logging.Logger):
            loggers.append(logger_ref)
    return loggers


def _apply_console_policy_to_logger(logger: logging.Logger, settings: ConsoleSettings) -> None:
    """
    函数 `_apply_console_policy_to_logger` 为单个 logger 应用颜色与过滤器。
    输入：
      - logger: logging.Logger -- 需要处理的日志器。
      - settings: ConsoleSettings -- 终端展示设置。
    输出：
      - None -- 原地修改 logger 的 handlers。
    """
    for handler in logger.handlers:
        existing_noise_filters = [
            existing for existing in handler.filters if isinstance(existing, _KnownAxNoiseFilter)
        ]
        if not existing_noise_filters:
            handler.addFilter(_KnownAxNoiseFilter(settings))
        else:
            for noise_filter in existing_noise_filters:
                noise_filter.settings = settings
        if isinstance(handler.formatter, _ColorizingFormatter):
            handler.formatter.enable_color = settings.enable_color
            continue
        if not isinstance(handler.formatter, _ColorizingFormatter):
            base_formatter = handler.formatter or logging.Formatter("%(message)s")
            handler.setFormatter(
                _ColorizingFormatter(base_formatter, enable_color=settings.enable_color)
            )


def _color_for_level(level_name: str) -> str:
    """
    函数 `_color_for_level` 根据日志级别名返回对应 ANSI 颜色。
    输入：
      - level_name: str -- 日志级别名称。
    输出：
      - str -- 颜色前缀。
    """
    normalized = level_name.upper()
    if normalized == "DEBUG":
        return DEBUG
    if normalized == "WARNING":
        return WARNING
    if normalized in {"ERROR", "CRITICAL"}:
        return ERROR
    return INFO


def render_banner_block(lines: list[str], enable_color: bool = True) -> str:
    """
    函数 `render_banner_block` 将多行欢迎文本包装为终端横幅。
    输入：
      - lines: list[str] -- 横幅正文各行。
      - enable_color: bool -- 是否启用颜色。
    输出：
      - str -- 渲染完成的横幅字符串。
    """
    border = "-" * 22
    payload = [border, *lines, border]
    return colorize("\n".join(payload), STATUS, enable_color)


def _debug_dump_settings(settings: Any) -> str:
    """
    函数 `_debug_dump_settings` 仅用于调试时显示当前 console 设置。
    输入：
      - settings: Any -- 任意设置对象。
    输出：
      - str -- 便于日志输出的字符串。
    """
    return str(settings)


class _TeeStream:
    """将终端输出同时写到原始流与日志文件。"""

    def __init__(self, original, sink):
        self.original = original
        self.sink = sink
        self.encoding = getattr(original, "encoding", "utf-8")

    def write(self, data: str) -> int:
        written = self.original.write(data)
        self.sink.write(data)
        return written

    def flush(self) -> None:
        self.original.flush()
        self.sink.flush()

    def isatty(self) -> bool:
        return bool(getattr(self.original, "isatty", lambda: False)())

    def fileno(self) -> int:
        return self.original.fileno()


@contextmanager
def capture_terminal_output(log_path: Path):
    """
    函数 `capture_terminal_output` 将当前进程的 stdout/stderr 终端输出同步写入文件。
    这样无论正常结束还是 `Ctrl+C` 中断，都能保留已经打印出来的全部日志。
    输入：
      - log_path: Path -- 终端输出日志文件路径。
    输出：
      - contextmanager -- 在上下文期间所有终端输出都会被 tee 到该文件。
    """
    log_path.parent.mkdir(parents=True, exist_ok=True)
    original_stdout = sys.stdout
    original_stderr = sys.stderr
    with log_path.open("a", encoding="utf-8", buffering=1) as sink:
        sink.write(f"\n===== ATP terminal session started at {datetime.now().isoformat()} =====\n")
        sys.stdout = _TeeStream(original_stdout, sink)
        sys.stderr = _TeeStream(original_stderr, sink)
        try:
            yield str(log_path)
        finally:
            sys.stdout.flush()
            sys.stderr.flush()
            sink.write(f"===== ATP terminal session ended at {datetime.now().isoformat()} =====\n")
            sink.flush()
            sys.stdout = original_stdout
            sys.stderr = original_stderr


class LLMRequestLimitExceeded(RuntimeError):
    """当单次场景尝试中的模型请求次数超过 ATP 限制时抛出。"""


class LLMRequestSession:
    """单次场景尝试期间的模型请求计数与上限控制。"""

    def __init__(self, max_requests: int | None = None):
        self.max_requests = max_requests if max_requests and max_requests > 0 else None
        self.request_count = 0
        self._token: Token | None = None

    def __enter__(self) -> "LLMRequestSession":
        self._token = _ACTIVE_LLM_REQUEST_SESSION.set(self)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        if self._token is not None:
            _ACTIVE_LLM_REQUEST_SESSION.reset(self._token)
            self._token = None

    def register_request(self, model_name: str, method_name: str) -> int:
        """
        函数 `register_request` 记录一次即将发出的模型请求，并在超过上限时抛出异常。
        输入：
          - model_name: str -- 当前模型名。
          - method_name: str -- 当前调用方法，例如 `invoke` 或 `ainvoke`。
        输出：
          - int -- 当前场景内的请求序号。
        """
        next_request_index = self.request_count + 1
        if self.max_requests is not None and next_request_index > self.max_requests:
            raise LLMRequestLimitExceeded(
                "LLM request limit reached for this attempt: "
                f"max_requests={self.max_requests}, blocked_request={next_request_index}, "
                f"method={method_name}, model={model_name}"
            )
        self.request_count = next_request_index
        return self.request_count


class LLMRequestPhase:
    """单个 ax-prover 节点阶段内的模型请求计数。"""

    def __init__(self, phase_name: str):
        self.phase_name = phase_name
        self.request_count = 0
        self._token: Token | None = None

    def __enter__(self) -> "LLMRequestPhase":
        self._token = _ACTIVE_LLM_REQUEST_PHASE.set(self)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        if self._token is not None:
            _ACTIVE_LLM_REQUEST_PHASE.reset(self._token)
            self._token = None

    def register_request(self) -> int:
        """
        函数 `register_request` 记录当前阶段内的一次模型请求。
        输入：
          - 无。
        输出：
          - int -- 当前阶段内的请求序号。
        """
        self.request_count += 1
        return self.request_count


@contextmanager
def llm_request_session(max_requests: int | None = None):
    """
    函数 `llm_request_session` 为当前上下文启用模型请求计数与可选上限控制。
    输入：
      - max_requests: int | None -- 单次上下文允许的最大请求数；为空或非正数表示不限制。
    输出：
      - contextmanager -- 退出后可通过返回对象读取 `request_count`。
    """
    session = LLMRequestSession(max_requests=max_requests)
    with session:
        yield session


@contextmanager
def llm_request_phase(phase_name: str):
    """
    函数 `llm_request_phase` 为当前上下文启用阶段内请求计数。
    输入：
      - phase_name: str -- 当前阶段名，例如 `proposer` 或 `reviewer`。
    输出：
      - contextmanager -- 退出后自动恢复上一层阶段上下文。
    """
    phase = LLMRequestPhase(phase_name=phase_name)
    with phase:
        yield phase


def install_llm_request_logging() -> None:
    """
    函数 `install_llm_request_logging` 为常见 provider 的真实模型请求打印一条 INFO 级终端日志。
    它只在 ATP 当前进程中打补丁，不修改 ax-prover 或 LangChain 源码。
    输入：
      - 无。
    输出：
      - None -- 后续每次 invoke/ainvoke 前都会打印请求信息。
    """
    global _LLM_REQUEST_PATCHED
    if _LLM_REQUEST_PATCHED:
        return

    targets: list[type] = []
    try:
        from langchain_openai import ChatOpenAI

        targets.append(ChatOpenAI)
    except Exception:
        pass
    try:
        from langchain_anthropic import ChatAnthropic

        targets.append(ChatAnthropic)
    except Exception:
        pass
    try:
        from langchain_google_genai import ChatGoogleGenerativeAI

        targets.append(ChatGoogleGenerativeAI)
    except Exception:
        pass
    try:
        from langchain_deepseek import ChatDeepSeek

        targets.append(ChatDeepSeek)
    except Exception:
        pass

    for cls in targets:
        _patch_llm_method(cls, "invoke", is_async=False)
        _patch_llm_method(cls, "ainvoke", is_async=True)

    _patch_ax_agent_request_phases()
    _LLM_REQUEST_PATCHED = True


def _patch_ax_agent_request_phases() -> None:
    """为 ax-prover 的主要 LLM 节点打阶段计数补丁。"""
    global _LLM_PHASE_PATCHED
    if _LLM_PHASE_PATCHED:
        return

    try:
        from ax_prover.prover.agent import ProverAgent
    except Exception:
        return

    _patch_ax_agent_async_method(ProverAgent, "_proposer_node", phase_name="proposer")
    _patch_ax_agent_async_method(ProverAgent, "_reviewer_node", phase_name="reviewer")
    _patch_ax_agent_async_method(
        ProverAgent,
        "_memory_processor_node",
        phase_name="memory",
    )
    _patch_ax_agent_async_method(
        ProverAgent,
        "_summarize_output_node",
        phase_name="summary",
    )
    _LLM_PHASE_PATCHED = True


def _patch_ax_agent_async_method(cls: type, method_name: str, phase_name: str) -> None:
    """为 ax-prover 的异步节点方法打阶段上下文补丁。"""
    original = getattr(cls, method_name, None)
    if original is None or getattr(original, "_atp_llm_phase_patched", False):
        return

    @functools.wraps(original)
    async def wrapped(self, *args, **kwargs):
        with llm_request_phase(phase_name):
            return await original(self, *args, **kwargs)

    wrapped._atp_llm_phase_patched = True
    setattr(cls, method_name, wrapped)


def _patch_llm_method(cls: type, method_name: str, is_async: bool) -> None:
    """为单个模型类的 invoke/ainvoke 打请求日志补丁。"""
    original = getattr(cls, method_name, None)
    if original is None or getattr(original, "_atp_llm_request_patched", False):
        return

    if is_async:

        @functools.wraps(original)
        async def wrapped(self, *args, **kwargs):
            request_id, model_name, scope_suffix = _print_llm_request(self, method_name)
            started_at = monotonic()
            try:
                return await original(self, *args, **kwargs)
            except Exception as exc:
                _print_llm_request_timeout_warning(
                    request_id=request_id,
                    model_name=model_name,
                    method_name=method_name,
                    scope_suffix=scope_suffix,
                    elapsed_seconds=monotonic() - started_at,
                    exc=exc,
                )
                raise

    else:

        @functools.wraps(original)
        def wrapped(self, *args, **kwargs):
            request_id, model_name, scope_suffix = _print_llm_request(self, method_name)
            started_at = monotonic()
            try:
                return original(self, *args, **kwargs)
            except Exception as exc:
                _print_llm_request_timeout_warning(
                    request_id=request_id,
                    model_name=model_name,
                    method_name=method_name,
                    scope_suffix=scope_suffix,
                    elapsed_seconds=monotonic() - started_at,
                    exc=exc,
                )
                raise

    wrapped._atp_llm_request_patched = True
    setattr(cls, method_name, wrapped)


def _print_llm_request(model_obj: Any, method_name: str) -> tuple[str, str, str]:
    """打印一条与终端风格一致的 LLM 请求日志，并返回请求标识信息。"""
    global _LLM_REQUEST_COUNTER
    model_name = _resolve_model_name(model_obj)
    session = _ACTIVE_LLM_REQUEST_SESSION.get()
    phase = _ACTIVE_LLM_REQUEST_PHASE.get()
    scoped_request_index = None
    if session is not None:
        scoped_request_index = session.register_request(
            model_name=model_name,
            method_name=method_name,
        )
    phase_request_index = None
    if phase is not None:
        phase_request_index = phase.register_request()
    _LLM_REQUEST_COUNTER += 1
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    request_label = _format_llm_request_label(
        phase=phase,
        phase_request_index=phase_request_index,
        attempt_request_index=scoped_request_index,
    )
    scope_suffix = _format_llm_request_scope_suffix(
        phase=phase,
        phase_request_index=phase_request_index,
        session=session,
        scoped_request_index=scoped_request_index,
    )
    print_info(
        f"{timestamp} - INFO - [llm_request] - Sending LLM request {request_label} "
        f"via {method_name} model={model_name}{scope_suffix}",
        enable_color=_ACTIVE_CONSOLE_SETTINGS.enable_color,
    )
    return request_label, model_name, scope_suffix


def _print_llm_request_timeout_warning(
    request_id: str,
    model_name: str,
    method_name: str,
    scope_suffix: str,
    elapsed_seconds: float,
    exc: Exception,
) -> None:
    """在 LLM 请求出现超时类失败时打印一条 WARNING。"""
    if not _is_timeout_like_llm_exception(exc, elapsed_seconds):
        return

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    detail = _format_exception_brief(exc)
    print_warning(
        f"{timestamp} - WARNING - [llm_request] - LLM request {request_id} "
        f"via {method_name} model={model_name}{scope_suffix} timed out after "
        f"{elapsed_seconds:.1f}s ({detail})",
        enable_color=_ACTIVE_CONSOLE_SETTINGS.enable_color,
    )


def _resolve_model_name(model_obj: Any) -> str:
    """解析终端日志中使用的模型名。"""
    return str(
        getattr(model_obj, "model_name", None)
        or getattr(model_obj, "model", None)
        or getattr(model_obj, "__class__", type(model_obj)).__name__
    )


def _format_llm_request_scope_suffix(
    phase: "LLMRequestPhase | None",
    phase_request_index: int | None,
    scoped_request_index: int | None,
    session: "LLMRequestSession | None" = None,
) -> str:
    """格式化单次尝试内的请求编号后缀。"""
    if phase is not None and phase.phase_name != "proposer":
        if session is not None and scoped_request_index is not None:
            return f" phase={phase.phase_name}"
        if phase_request_index is not None:
            return f" phase={phase.phase_name}"
    return ""


def _format_llm_request_label(
    phase: "LLMRequestPhase | None",
    phase_request_index: int | None,
    attempt_request_index: int | None,
) -> str:
    """格式化以“单次尝试总序号”为主的请求编号。"""
    total_index = attempt_request_index
    if total_index is None:
        total_index = phase_request_index
    if total_index is None:
        global _LLM_REQUEST_COUNTER
        total_index = _LLM_REQUEST_COUNTER + 1
    return f"#{total_index}"


def _is_timeout_like_llm_exception(exc: Exception, elapsed_seconds: float) -> bool:
    """判断异常是否应按“超时类 LLM 故障”打印 WARNING。"""
    timeout_types: tuple[type[BaseException], ...] = (TimeoutError,)
    httpx_timeout_types: tuple[type[BaseException], ...] = ()
    openai_timeout_types: tuple[type[BaseException], ...] = ()
    openai_connection_types: tuple[type[BaseException], ...] = ()

    try:
        import httpx

        httpx_timeout_types = (httpx.TimeoutException,)
    except Exception:
        pass

    try:
        from openai import APIConnectionError, APITimeoutError

        openai_timeout_types = (APITimeoutError,)
        openai_connection_types = (APIConnectionError,)
    except Exception:
        pass

    pending: list[BaseException] = [exc]
    visited: set[int] = set()
    while pending:
        current = pending.pop()
        current_id = id(current)
        if current_id in visited:
            continue
        visited.add(current_id)

        if isinstance(current, timeout_types + httpx_timeout_types + openai_timeout_types):
            return True

        current_name = current.__class__.__name__.lower()
        current_text = str(current).strip().lower()
        if "timeout" in current_name or "timed out" in current_text or "timeout" in current_text:
            return True

        if (
            openai_connection_types
            and isinstance(current, openai_connection_types)
            and elapsed_seconds >= _TIMEOUT_LIKE_CONNECTION_SECONDS
        ):
            return True

        for chained in (getattr(current, "__cause__", None), getattr(current, "__context__", None)):
            if chained is not None:
                pending.append(chained)
    return False


def _format_exception_brief(exc: BaseException) -> str:
    """生成适合终端单行展示的异常摘要。"""
    message = str(exc).strip() or "no details"
    return f"{exc.__class__.__name__}: {message}"
