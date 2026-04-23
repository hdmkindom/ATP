import os
import asyncio
from pathlib import Path
import tempfile

from atp_axbench.runner import (
    _reset_ax_tool_runtime_state,
    build_ax_config,
    format_scenario_divider,
)


def test_build_ax_config_can_source_api_key_and_strip_empty_base_url():
    """验证 build_ax_config 会同步 API key 并清理空 base_url。"""
    original_api_key = os.environ.get("OPENAI_API_KEY")
    try:
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "llm.yaml"
            config_path.write_text(
                """
prover:
  prover_llm:
    model: openai:gpt-4.1-mini
    provider_config:
      api_key: yaml-inline-key
      base_url: ""
      temperature: 0
""".strip(),
                encoding="utf-8",
            )

            ax_config = build_ax_config((str(config_path),), "ping")
            provider_config = ax_config.prover.prover_llm.provider_config
            assert os.environ.get("OPENAI_API_KEY") == "yaml-inline-key"
            assert "base_url" not in provider_config
            assert provider_config["api_key"] == "yaml-inline-key"
    finally:
        if original_api_key is None:
            os.environ.pop("OPENAI_API_KEY", None)
        else:
            os.environ["OPENAI_API_KEY"] = original_api_key


def test_build_ax_config_can_source_openai_compatible_key_from_custom_env():
    """验证 ATP 可通过 `api_key_env` 读取自定义环境变量，并在最终 provider 配置中移除该辅助字段。"""
    original_openai_api_key = os.environ.get("OPENAI_API_KEY")
    original_nebius_api_key = os.environ.get("NEBIUS_API_KEY")
    try:
        os.environ.pop("OPENAI_API_KEY", None)
        os.environ["NEBIUS_API_KEY"] = "nebius-env-key"
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "llm.yaml"
            config_path.write_text(
                """
prover:
  prover_llm:
    model: openai:deepseek-ai/DeepSeek-R1-0528
    provider_config:
      api_key_env: NEBIUS_API_KEY
      base_url: https://api.tokenfactory.nebius.com/v1
      use_responses_api: false
      reasoning: null
      temperature: null
  memory_config:
    class_name: ExperienceProcessor
    init_args:
      llm_config:
        model: openai:deepseek-ai/DeepSeek-R1-0528
        provider_config:
          api_key_env: NEBIUS_API_KEY
          base_url: https://api.tokenfactory.nebius.com/v1
          use_responses_api: false
""".strip(),
                encoding="utf-8",
            )

            ax_config = build_ax_config((str(config_path),), "ping")
            provider_config = ax_config.prover.prover_llm.provider_config
            memory_provider_config = ax_config.prover.memory_config.init_args["llm_config"][
                "provider_config"
            ]

            assert os.environ.get("OPENAI_API_KEY") == "nebius-env-key"
            assert provider_config["base_url"] == "https://api.tokenfactory.nebius.com/v1"
            assert provider_config["use_responses_api"] is False
            assert "api_key_env" not in provider_config
            assert "api_key_env" not in memory_provider_config
    finally:
        if original_openai_api_key is None:
            os.environ.pop("OPENAI_API_KEY", None)
        else:
            os.environ["OPENAI_API_KEY"] = original_openai_api_key

        if original_nebius_api_key is None:
            os.environ.pop("NEBIUS_API_KEY", None)
        else:
            os.environ["NEBIUS_API_KEY"] = original_nebius_api_key


def test_build_ax_config_reads_memory_and_search_tools_from_yaml_only():
    """验证实验配置中的 memory_config 与 proposer_tools 直接来自 YAML。"""
    ax_config = build_ax_config(("ATP/config/ax_prover_experiment.yaml",), "ping")
    proposer_tools = ax_config.prover.proposer_tools
    memory_llm_config = ax_config.prover.memory_config.init_args["llm_config"]

    assert list(proposer_tools.keys()) == ["search_lean"]
    assert proposer_tools["search_lean"]["max_results"] == 6
    assert memory_llm_config["model"] == ax_config.prover.prover_llm.model


def test_format_scenario_divider_uses_short_terminal_friendly_layout():
    """验证场景分隔线采用 `--T1-free------` 这类紧凑格式。"""
    divider = format_scenario_divider("T1.free")
    repeated_divider = format_scenario_divider("T1.free", attempt_index=2)

    assert divider.startswith("--T1-free")
    assert divider.endswith("------")
    assert repeated_divider.startswith("--T1-free-a2")


def test_reset_ax_tool_runtime_state_closes_stale_lean_search_session():
    """验证 ATP 会在场景前后关闭 LeanSearch 的全局 session，避免跨题复用旧事件循环。"""
    from ax_prover.tools import lean_search as lean_search_module

    original_session = getattr(lean_search_module, "_lean_search_session", None)

    class DummySession:
        def __init__(self):
            self.closed = False

        async def close(self):
            self.closed = True

    dummy = DummySession()
    lean_search_module._lean_search_session = dummy
    try:
        asyncio.run(_reset_ax_tool_runtime_state())
        assert dummy.closed is True
        assert lean_search_module._lean_search_session is None
    finally:
        lean_search_module._lean_search_session = original_session
