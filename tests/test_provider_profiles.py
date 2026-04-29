import os
from pathlib import Path
import tempfile
from urllib.parse import urlparse

from omegaconf import OmegaConf

from atp_axbench.runner import build_ax_config


DOMESTIC_PROFILE_NAMES = (
    "qwen3_max_json",
    "deepseek_thinking_json",
    "kimi_k25_thinking_json",
    "glm5_thinking_json",
)


def test_domestic_provider_profiles_use_api_roots_not_final_endpoints():
    """验证国内模型 profile 的 base_url 写 API 根路径，而不是最终 endpoint。"""
    config = OmegaConf.to_container(
        OmegaConf.load("ATP/config/ax_prover_profiles.yaml"),
        resolve=False,
    )
    profiles = config["llm_profiles"]

    for profile_name in DOMESTIC_PROFILE_NAMES:
        provider_config = profiles[profile_name]["provider_config"]
        base_url = provider_config.get("base_url")
        if not base_url:
            continue
        parsed = urlparse(base_url)
        path = parsed.path.rstrip("/")
        assert parsed.scheme in {"http", "https"}
        assert parsed.netloc
        assert not path.endswith("/chat/completions")
        assert not path.endswith("/responses")


def test_dashscope_api_key_env_is_synced_and_atp_fields_are_stripped():
    """验证 `api_key_env` 会同步到 OpenAI 兼容 provider，且 ATP 扩展字段不会传给 LangChain。"""
    original_openai_api_key = os.environ.get("OPENAI_API_KEY")
    original_dashscope_api_key = os.environ.get("DASHSCOPE_API_KEY")
    try:
        os.environ.pop("OPENAI_API_KEY", None)
        os.environ["DASHSCOPE_API_KEY"] = "dashscope-env-key"

        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "qwen.yaml"
            config_path.write_text(
                """
prover:
  prover_llm:
    model: openai:qwen3-max
    provider_config:
      api_key_env: DASHSCOPE_API_KEY
      base_url: https://dashscope.aliyuncs.com/compatible-mode/v1
      use_responses_api: false
      extra_body:
        enable_thinking: false
      structured_output_strategy: json_object_with_schema_prompt
  memory_config:
    class_name: ExperienceProcessor
    init_args:
      llm_config:
        model: openai:qwen3-max
        provider_config:
          api_key_env: DASHSCOPE_API_KEY
          base_url: https://dashscope.aliyuncs.com/compatible-mode/v1
          structured_output_strategy: json_object_with_schema_prompt
""".strip(),
                encoding="utf-8",
            )

            ax_config = build_ax_config((str(config_path),), "ping")
            provider_config = ax_config.prover.prover_llm.provider_config
            memory_provider_config = ax_config.prover.memory_config.init_args["llm_config"][
                "provider_config"
            ]

            assert os.environ.get("OPENAI_API_KEY") == "dashscope-env-key"
            assert provider_config["base_url"] == "https://dashscope.aliyuncs.com/compatible-mode/v1"
            assert provider_config["use_responses_api"] is False
            assert provider_config["extra_body"]["enable_thinking"] is False
            assert "api_key_env" not in provider_config
            assert "structured_output_strategy" not in provider_config
            assert "api_key_env" not in memory_provider_config
            assert "structured_output_strategy" not in memory_provider_config
    finally:
        if original_openai_api_key is None:
            os.environ.pop("OPENAI_API_KEY", None)
        else:
            os.environ["OPENAI_API_KEY"] = original_openai_api_key

        if original_dashscope_api_key is None:
            os.environ.pop("DASHSCOPE_API_KEY", None)
        else:
            os.environ["DASHSCOPE_API_KEY"] = original_dashscope_api_key


def test_deepseek_v4_profile_keeps_thinking_fields_and_strips_atp_fields():
    """验证 DeepSeek V4 Pro thinking profile 保留 provider 参数，但清理 ATP 扩展字段。"""
    original_deepseek_api_key = os.environ.get("DEEPSEEK_API_KEY")
    try:
        os.environ["DEEPSEEK_API_KEY"] = "deepseek-env-key"

        ax_config = build_ax_config(
            (
                "ATP/config/ax_prover_experiment.yaml",
                {"llm_runtime": {"shared_profile": "${llm_profiles.deepseek_thinking_json}"}},
            ),
            "ping",
        )
        provider_config = ax_config.prover.prover_llm.provider_config
        memory_provider_config = ax_config.prover.memory_config.init_args["llm_config"][
            "provider_config"
        ]

        assert ax_config.prover.prover_llm.model == "deepseek:deepseek-v4-pro"
        assert provider_config.get("api_key") or os.environ.get("DEEPSEEK_API_KEY")
        assert provider_config["base_url"] == "https://api.deepseek.com"
        assert provider_config["reasoning_effort"] == "high"
        assert provider_config["extra_body"]["thinking"]["type"] == "enabled"
        assert provider_config["max_tokens"] == 16000
        assert "api_key_env" not in provider_config
        assert "structured_output_strategy" not in provider_config
        assert "api_key_env" not in memory_provider_config
        assert "structured_output_strategy" not in memory_provider_config
    finally:
        if original_deepseek_api_key is None:
            os.environ.pop("DEEPSEEK_API_KEY", None)
        else:
            os.environ["DEEPSEEK_API_KEY"] = original_deepseek_api_key


def test_missing_custom_api_key_env_fails_before_reusing_openai_key():
    """验证声明自定义 `api_key_env` 后，不会误用已有 OPENAI_API_KEY。"""
    original_openai_api_key = os.environ.get("OPENAI_API_KEY")
    original_dashscope_api_key = os.environ.get("DASHSCOPE_API_KEY")
    try:
        os.environ["OPENAI_API_KEY"] = "ordinary-openai-key"
        os.environ.pop("DASHSCOPE_API_KEY", None)

        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "qwen.yaml"
            config_path.write_text(
                """
prover:
  prover_llm:
    model: openai:qwen3-max
    provider_config:
      api_key_env: DASHSCOPE_API_KEY
      base_url: https://dashscope.aliyuncs.com/compatible-mode/v1
""".strip(),
                encoding="utf-8",
            )

            try:
                build_ax_config((str(config_path),), "ping")
            except RuntimeError as exc:
                assert "DASHSCOPE_API_KEY is not set" in str(exc)
            else:
                raise AssertionError("Expected missing DASHSCOPE_API_KEY to fail.")
    finally:
        if original_openai_api_key is None:
            os.environ.pop("OPENAI_API_KEY", None)
        else:
            os.environ["OPENAI_API_KEY"] = original_openai_api_key

        if original_dashscope_api_key is None:
            os.environ.pop("DASHSCOPE_API_KEY", None)
        else:
            os.environ["DASHSCOPE_API_KEY"] = original_dashscope_api_key
