from pathlib import Path
import tempfile

import httpx
from openai import APIConnectionError

from atp_axbench.console import (
    LLMRequestLimitExceeded,
    _print_llm_request,
    _print_llm_request_timeout_warning,
    capture_terminal_output,
    llm_request_phase,
    llm_request_session,
)


def test_capture_terminal_output_writes_printed_content_to_log_file():
    """验证终端输出 tee 会把打印内容写入 terminal log。"""
    with tempfile.TemporaryDirectory() as temp_dir:
        log_path = Path(temp_dir) / "terminal.log"
        with capture_terminal_output(log_path):
            print("hello terminal capture")

        content = log_path.read_text(encoding="utf-8")
        assert "hello terminal capture" in content


def test_llm_request_session_blocks_requests_beyond_limit():
    """验证 LLM 请求会在超过单次尝试上限时被 ATP 拦截。"""

    class DummyModel:
        model_name = "dummy-model"

    with llm_request_session(max_requests=2) as session:
        _print_llm_request(DummyModel(), "invoke")
        _print_llm_request(DummyModel(), "invoke")
        try:
            _print_llm_request(DummyModel(), "invoke")
        except LLMRequestLimitExceeded as exc:
            assert "max_requests=2" in str(exc)
            assert "blocked_request=3" in str(exc)
        else:  # pragma: no cover - defensive branch
            raise AssertionError("expected request limit exception on the third request")

    assert session.request_count == 2


def test_llm_request_uses_attempt_total_counter_without_phase_reset():
    """验证日志请求号按单次尝试总序号连续增长，不会因 phase 切换而回到 `#1`。"""

    class DummyModel:
        model_name = "dummy-model"

    with tempfile.TemporaryDirectory() as temp_dir:
        log_path = Path(temp_dir) / "terminal.log"
        with capture_terminal_output(log_path):
            with llm_request_session(max_requests=10):
                with llm_request_phase("proposer"):
                    _print_llm_request(DummyModel(), "ainvoke")
                    _print_llm_request(DummyModel(), "ainvoke")
                with llm_request_phase("memory"):
                    _print_llm_request(DummyModel(), "ainvoke")
                with llm_request_phase("proposer"):
                    _print_llm_request(DummyModel(), "ainvoke")

        content = log_path.read_text(encoding="utf-8")
        assert "Sending LLM request #1 via ainvoke model=dummy-model" in content
        assert "Sending LLM request #2 via ainvoke model=dummy-model" in content
        assert "Sending LLM request #3 via ainvoke model=dummy-model phase=memory" in content
        assert "Sending LLM request #4 via ainvoke model=dummy-model" in content


def test_llm_request_timeout_warning_is_printed_for_timeout_error():
    """验证超时类异常会被 ATP 记录为终端 WARNING。"""

    class DummyModel:
        model_name = "dummy-model"

    with tempfile.TemporaryDirectory() as temp_dir:
        log_path = Path(temp_dir) / "terminal.log"
        with capture_terminal_output(log_path):
            request_id, model_name, scope_suffix = _print_llm_request(DummyModel(), "ainvoke")
            _print_llm_request_timeout_warning(
                request_id=request_id,
                model_name=model_name,
                method_name="ainvoke",
                scope_suffix=scope_suffix,
                elapsed_seconds=12.5,
                exc=TimeoutError("request timed out"),
            )

        content = log_path.read_text(encoding="utf-8")
        assert "WARNING - [llm_request]" in content
        assert "timed out after 12.5s" in content


def test_llm_request_timeout_warning_treats_long_connection_error_as_timeout():
    """验证长时间挂起后以连接错误结束的请求也会打印超时 WARNING。"""

    request = httpx.Request("POST", "https://example.com/v1/responses")
    exc = APIConnectionError(request=request)

    with tempfile.TemporaryDirectory() as temp_dir:
        log_path = Path(temp_dir) / "terminal.log"
        with capture_terminal_output(log_path):
            _print_llm_request_timeout_warning(
                request_id="#23",
                model_name="gpt-5.3-codex",
                method_name="ainvoke",
                scope_suffix="",
                elapsed_seconds=185.0,
                exc=exc,
            )

        content = log_path.read_text(encoding="utf-8")
        assert "LLM request #23" in content
        assert "timed out after 185.0s" in content
        assert "APIConnectionError" in content
