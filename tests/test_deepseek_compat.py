from langchain_core.messages import AIMessage, HumanMessage, ToolMessage
from langchain_core.tools import tool

from atp_axbench.deepseek_compat import install_deepseek_compat_patches


@tool
def lookup(query: str) -> str:
    """Look up a Lean theorem."""
    return query


def test_deepseek_bind_tools_defaults_to_strict_tools():
    """验证 DeepSeek 绑定工具时默认生成 strict tool schema，兼容 parse + response_format。"""
    try:
        from langchain_deepseek import ChatDeepSeek
    except ImportError:
        return

    install_deepseek_compat_patches()
    model = ChatDeepSeek(model="deepseek-v4-pro", api_key="dummy", base_url="https://api.deepseek.com")

    bound = model.bind_tools([lookup])

    tool_spec = bound.kwargs["tools"][0]
    assert tool_spec["function"]["strict"] is True
    assert tool_spec["function"]["parameters"]["additionalProperties"] is False


def test_deepseek_payload_preserves_reasoning_content_for_tool_call():
    """验证 DeepSeek thinking + tool call 下一轮请求会带回 reasoning_content。"""
    try:
        from langchain_deepseek import ChatDeepSeek
    except ImportError:
        return

    install_deepseek_compat_patches()
    model = ChatDeepSeek(model="deepseek-v4-pro", api_key="dummy")
    assistant_message = AIMessage(
        content="",
        additional_kwargs={"reasoning_content": "I should search Lean first."},
        tool_calls=[
            {
                "name": "search_lean",
                "args": {"query": "Nat.add_zero"},
                "id": "call_1",
                "type": "tool_call",
            }
        ],
    )

    payload = model._get_request_payload(
        [
            HumanMessage(content="Prove the theorem."),
            assistant_message,
            ToolMessage(content="Nat.add_zero", tool_call_id="call_1"),
        ]
    )

    assert payload["messages"][1]["role"] == "assistant"
    assert payload["messages"][1]["reasoning_content"] == "I should search Lean first."


def test_deepseek_payload_does_not_replay_reasoning_without_tool_call():
    """验证普通 assistant 消息不会把旧 reasoning_content 塞回 DeepSeek payload。"""
    try:
        from langchain_deepseek import ChatDeepSeek
    except ImportError:
        return

    install_deepseek_compat_patches()
    model = ChatDeepSeek(model="deepseek-v4-pro", api_key="dummy")
    assistant_message = AIMessage(
        content='{"updated_theorem":"theorem t : True := by trivial"}',
        additional_kwargs={"reasoning_content": "Final private reasoning."},
    )

    payload = model._get_request_payload(
        [
            HumanMessage(content="Return JSON."),
            assistant_message,
        ]
    )

    assert payload["messages"][1]["role"] == "assistant"
    assert "reasoning_content" not in payload["messages"][1]


def test_deepseek_reasoning_extraction_reads_additional_kwargs():
    """验证 ATP patch 让 ax-prover 能从 DeepSeek additional_kwargs 中读取 reasoning。"""
    import ax_prover.utils.llm as llm_utils

    install_deepseek_compat_patches()
    response = AIMessage(
        content='{"updated_theorem":"theorem t : True := by trivial"}',
        additional_kwargs={"reasoning_content": "DeepSeek thinking trace."},
    )

    assert llm_utils.get_reasoning(response) == "DeepSeek thinking trace."
