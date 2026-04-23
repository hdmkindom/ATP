import os
from pathlib import Path
import tempfile

from atp_axbench.direct_prove import build_minimal_ax_config


def test_build_minimal_ax_config_can_override_provider_fields_from_cli():
    """验证最小直连脚本可在保留基础 YAML 的同时覆盖 model/base_url/api_key 等字段。"""
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
      temperature: 0
      use_responses_api: true
  max_iterations: 9
runtime:
  max_tool_calling_iterations: 2
  log_level: INFO
""".strip(),
                encoding="utf-8",
            )

            ax_config = build_minimal_ax_config(
                config_paths=(str(config_path),),
                api_key="inline-openai-key",
                base_url="https://relay.example/v1",
                temperature=0.2,
                use_responses_api=False,
                max_iterations=3,
                max_tool_calls=5,
                log_level="DEBUG",
                enable_summary=False,
                user_comments="minimal direct test",
            )

            provider_config = ax_config.prover.prover_llm.provider_config
            assert ax_config.prover.prover_llm.model == "openai:gpt-4.1-mini"
            assert provider_config["api_key"] == "inline-openai-key"
            assert provider_config["base_url"] == "https://relay.example/v1"
            assert provider_config["temperature"] == 0.2
            assert provider_config["use_responses_api"] is False
            assert ax_config.prover.max_iterations == 3
            assert ax_config.runtime.max_tool_calling_iterations == 5
            assert str(ax_config.runtime.log_level) == "DEBUG"
            assert ax_config.prover.summarize_output.enabled is False
            assert ax_config.prover.user_comments == "minimal direct test"
            assert os.environ.get("OPENAI_API_KEY") == "inline-openai-key"
    finally:
        if original_api_key is None:
            os.environ.pop("OPENAI_API_KEY", None)
        else:
            os.environ["OPENAI_API_KEY"] = original_api_key


def test_build_minimal_ax_config_requires_a_model():
    """验证最小直连脚本在既无基础 YAML 模型也无命令行模型时会直接报错。"""
    try:
        build_minimal_ax_config(config_paths=(), model=None)
    except ValueError as exc:
        assert "No prover model is configured" in str(exc)
    else:  # pragma: no cover - defensive branch
        raise AssertionError("expected ValueError when no model is available")


def test_build_minimal_ax_config_can_source_custom_openai_compatible_env_key():
    """验证最小直连脚本也支持 `api_key_env` 形式的 OpenAI 兼容密钥。"""
    original_openai_api_key = os.environ.get("OPENAI_API_KEY")
    original_nebius_api_key = os.environ.get("NEBIUS_API_KEY")
    try:
        os.environ.pop("OPENAI_API_KEY", None)
        os.environ["NEBIUS_API_KEY"] = "nebius-direct-key"
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
""".strip(),
                encoding="utf-8",
            )

            ax_config = build_minimal_ax_config(
                config_paths=(str(config_path),),
            )

            provider_config = ax_config.prover.prover_llm.provider_config
            assert ax_config.prover.prover_llm.model == "openai:deepseek-ai/DeepSeek-R1-0528"
            assert provider_config["base_url"] == "https://api.tokenfactory.nebius.com/v1"
            assert provider_config["use_responses_api"] is False
            assert "api_key_env" not in provider_config
            assert os.environ.get("OPENAI_API_KEY") == "nebius-direct-key"
    finally:
        if original_openai_api_key is None:
            os.environ.pop("OPENAI_API_KEY", None)
        else:
            os.environ["OPENAI_API_KEY"] = original_openai_api_key

        if original_nebius_api_key is None:
            os.environ.pop("NEBIUS_API_KEY", None)
        else:
            os.environ["NEBIUS_API_KEY"] = original_nebius_api_key
