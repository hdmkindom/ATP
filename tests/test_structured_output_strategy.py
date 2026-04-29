import asyncio
from pathlib import Path
import tempfile

from langchain_core.messages import HumanMessage, ToolMessage
from pydantic import BaseModel

from atp_axbench.runner import build_ax_config
from atp_axbench.structured_output import (
    STRUCTURED_OUTPUT_JSON_OBJECT_WITH_SCHEMA_PROMPT,
    add_json_schema_instruction,
    ainvoke_retry_with_structured_output_strategy,
    resolve_strategy_for_llm,
    strategy_from_provider_config,
)


class TinyResult(BaseModel):
    answer: str


class FakeBaseLLM:
    model_name = "qwen3-max"
    openai_api_base = "https://dashscope.aliyuncs.com/compatible-mode/v1"


class FakeBoundLLM:
    def __init__(self):
        self.bound = FakeBaseLLM()
        self.messages = None
        self.kwargs = None

    async def ainvoke(self, messages, **kwargs):
        self.messages = messages
        self.kwargs = kwargs
        return HumanMessage(content='{"answer":"ok"}')


async def _fallback(messages, llm, schema):
    raise AssertionError("Fallback should not be used for json_object_with_schema_prompt.")


def test_strategy_from_provider_config_validates_known_values():
    """验证结构化输出策略字段会被明确校验。"""
    assert (
        strategy_from_provider_config(
            {"structured_output_strategy": "json_object_with_schema_prompt"}
        )
        == STRUCTURED_OUTPUT_JSON_OBJECT_WITH_SCHEMA_PROMPT
    )

    try:
        strategy_from_provider_config({"structured_output_strategy": "unknown"})
    except ValueError as exc:
        assert "Unsupported structured_output_strategy" in str(exc)
    else:
        raise AssertionError("Expected unknown structured_output_strategy to fail.")


def test_add_json_schema_instruction_appends_schema_prompt():
    """验证 JSON Object 策略会把 Pydantic schema 写入提示。"""
    messages = [HumanMessage(content="Return a tiny result.")]
    updated = add_json_schema_instruction(messages, TinyResult)

    assert len(updated) == 2
    assert updated[0] is messages[0]
    assert "Return exactly one valid JSON object" in updated[-1].content
    assert "answer" in updated[-1].content


def test_json_object_strategy_invokes_llm_with_json_object_response_format():
    """验证注册策略后，运行时调用会使用 JSON Object + schema prompt。"""
    with tempfile.TemporaryDirectory() as temp_dir:
        config_path = Path(temp_dir) / "qwen.yaml"
        config_path.write_text(
            """
prover:
  prover_llm:
    model: openai:qwen3-max
    provider_config:
      api_key: dummy
      base_url: https://dashscope.aliyuncs.com/compatible-mode/v1
      structured_output_strategy: json_object_with_schema_prompt
""".strip(),
            encoding="utf-8",
        )
        build_ax_config((str(config_path),), "ping")

    fake_llm = FakeBoundLLM()
    response = asyncio.run(
        ainvoke_retry_with_structured_output_strategy(
            messages=[HumanMessage(content="Return JSON.")],
            llm=fake_llm,
            schema=TinyResult,
            fallback=_fallback,
        )
    )

    assert response.content == '{"answer":"ok"}'
    assert fake_llm.kwargs == {"response_format": {"type": "json_object"}}
    assert "answer" in fake_llm.messages[-1].content
    assert resolve_strategy_for_llm(fake_llm) == STRUCTURED_OUTPUT_JSON_OBJECT_WITH_SCHEMA_PROMPT


def test_json_object_strategy_omits_response_format_after_tool_message():
    """验证工具调用后的结构化输出改用 schema prompt，避开 provider JSON mode/tool history 组合问题。"""
    with tempfile.TemporaryDirectory() as temp_dir:
        config_path = Path(temp_dir) / "qwen.yaml"
        config_path.write_text(
            """
prover:
  prover_llm:
    model: openai:qwen3-max
    provider_config:
      api_key: dummy
      base_url: https://dashscope.aliyuncs.com/compatible-mode/v1
      structured_output_strategy: json_object_with_schema_prompt
""".strip(),
            encoding="utf-8",
        )
        build_ax_config((str(config_path),), "ping")

    fake_llm = FakeBoundLLM()
    response = asyncio.run(
        ainvoke_retry_with_structured_output_strategy(
            messages=[
                HumanMessage(content="Return JSON."),
                ToolMessage(content="tool result", tool_call_id="call_1"),
            ],
            llm=fake_llm,
            schema=TinyResult,
            fallback=_fallback,
        )
    )

    assert response.content == '{"answer":"ok"}'
    assert fake_llm.kwargs == {}
    assert "answer" in fake_llm.messages[-1].content
