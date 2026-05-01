"""Health checks for the ATP ax-prover harness."""

from __future__ import annotations

import importlib
import time
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

from .catalog import ScenarioCatalog
from .models import DoctorReport, HealthCheckResult
from .paths import REPO_ROOT
from .reporting import write_doctor_report
from .runner import build_ax_config, prebuild_repo, run_single_scenario
from .settings import ProjectSettings

_PROVIDER_API_KEYS = {
    "openai": "OPENAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "google_genai": "GOOGLE_API_KEY",
    "deepseek": "DEEPSEEK_API_KEY",
}

_PROVIDER_DEPENDENCIES = {
    "deepseek": ("langchain_deepseek", "langchain-deepseek"),
}

_OPENAI_COMPATIBLE_PROVIDERS = {"openai", "deepseek"}


def run_doctor(
    settings: ProjectSettings,
    catalog: ScenarioCatalog,
    ax_config_paths: tuple[str, ...],
    output_dir: Path,
    skip_llm_ping: bool = False,
    skip_proof: bool = False,
) -> DoctorReport:
    """
    函数 `run_doctor` 运行环境、配置和冒烟测试检查。
    它接受项目设置、场景目录、ax 配置路径、输出目录以及两个可选参数来跳过 LLM ping 和冒烟测试。
    输入：
      - settings: ProjectSettings -- ATP 项目的总设置对象。
      - catalog: ScenarioCatalog -- 已加载的场景目录。
      - ax_config_paths: tuple[str, ...] -- 需要叠加的 ax-prover 配置路径。
      - output_dir: Path -- doctor 输出目录。
      - skip_llm_ping: bool -- 是否跳过实际 LLM 联通性检查。
      - skip_proof: bool -- 是否跳过 smoke proof。
    输出：
      - DoctorReport -- 聚合后的 doctor 检查报告。
    """
    checks: list[HealthCheckResult] = []
    started_at = datetime.now()
    ax_config = build_ax_config(
        ax_config_paths,
        "ATP doctor health check.",
        disable_langsmith_tracing=settings.execution.disable_langsmith_tracing,
        console_settings=settings.console,
    )

    checks.append(_run_check("ax_prover_import", _check_ax_prover_import))
    checks.append(_run_check("llm_credentials", lambda: _check_llm_credentials(ax_config)))
    checks.append(_run_check("llm_base_url", lambda: _check_base_url(ax_config)))
    checks.append(_run_check("provider_dependency", lambda: _check_provider_dependency(ax_config)))
    checks.append(_run_check("lean_repo_build", lambda: _check_build(ax_config)))
    checks.append(_run_check("template_smoke_file", lambda: _check_test_file(ax_config)))

    if skip_llm_ping:
        checks.append(_skipped_check("llm_ping", "Skipped by CLI flag."))
    else:
        checks.append(_run_check("llm_ping", lambda: _check_llm_ping(ax_config)))

    if skip_proof:
        checks.append(_skipped_check("smoke_proof", "Skipped by CLI flag."))
    else:
        smoke_scenario = catalog.scenarios["test.smoke"]
        checks.append(
            _run_check(
                "smoke_proof",
                lambda: _check_smoke_proof(
                    settings=settings,
                    ax_config_paths=ax_config_paths,
                    output_dir=output_dir,
                    scenario=smoke_scenario,
                ),
            )
        )

    report = DoctorReport(
        started_at=started_at,
        finished_at=datetime.now(),
        checks=checks,
    )
    write_doctor_report(output_dir, report)
    return report


def _check_ax_prover_import() -> str:
    """
    函数 `_check_ax_prover_import` 检查 ax-prover 包是否可导入。
    输入：
      - 无。
    输出：
      - str -- 导入成功后的说明文本。
    """
    import ax_prover

    return f"ax_prover import ok ({ax_prover.__file__})"


def _check_llm_credentials(ax_config) -> str:
    """
    函数 `_check_llm_credentials` 检查当前 provider 所需的 API key 是否存在。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- 凭据检查结果说明。
    """
    import os

    provider = _provider_name(ax_config)
    env_name = _PROVIDER_API_KEYS.get(provider)
    if env_name is None:
        return f"No credential check rule for provider {provider}."
    if not os.environ.get(env_name):
        raise RuntimeError(f"{env_name} is not set.")
    return f"{env_name} is set for provider {provider}."


def _check_provider_dependency(ax_config) -> str:
    """
    函数 `_check_provider_dependency` 检查当前 provider 对应的 LangChain 集成包是否可导入。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- 依赖检查结果说明。
    """
    provider = _provider_name(ax_config)
    dependency = _PROVIDER_DEPENDENCIES.get(provider)
    if dependency is None:
        return f"No extra provider package is required for provider {provider}."

    module_name, package_name = dependency
    try:
        importlib.import_module(module_name)
    except ImportError as exc:
        raise RuntimeError(
            f"Provider {provider} requires `{package_name}`. Install it in the active "
            f"environment with: conda run -n axprover python -m pip install {package_name}"
        ) from exc
    return f"Provider dependency `{package_name}` is importable for provider {provider}."


def _check_base_url(ax_config) -> str:
    """
    函数 `_check_base_url` 检查模型 provider 的 `base_url` 配置是否合法。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- `base_url` 检查结果说明。
    """
    base_url = _base_url(ax_config)
    if not base_url:
        return "No base_url configured; provider default endpoint will be used."
    parsed = urlparse(base_url)
    if not parsed.scheme or not parsed.netloc:
        raise RuntimeError(f"Invalid base_url: {base_url}")
    provider = _provider_name(ax_config)
    if provider in _OPENAI_COMPATIBLE_PROVIDERS and parsed.path.rstrip("/").endswith("/chat/completions"):
        raise RuntimeError(
            "For OpenAI-compatible providers, `base_url` must be the API root rather than the final "
            f"`/chat/completions` endpoint. Use something like `{parsed.scheme}://{parsed.netloc}/v1` instead of `{base_url}`."
        )
    if provider in _OPENAI_COMPATIBLE_PROVIDERS and parsed.path.rstrip("/").endswith("/responses"):
        raise RuntimeError(
            "For OpenAI-compatible providers, `base_url` must be the API root rather than the final "
            f"`/responses` endpoint. Use something like `{parsed.scheme}://{parsed.netloc}/v1` instead of `{base_url}`."
        )
    if provider == "openai" and parsed.path in {"", "/"}:
        return (
            f"base_url looks syntactically valid but has no explicit API path: {base_url}. "
            "Many OpenAI-compatible relays expect a `/v1` suffix."
        )
    return f"base_url looks valid: {base_url}"


def _check_build(ax_config) -> str:
    """
    函数 `_check_build` 检查 Lean 仓库是否能够成功预构建。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- 构建成功说明。
    """
    success, output = prebuild_repo(ax_config)
    if not success:
        raise RuntimeError(output)
    return "Lean repository build succeeded."


def _check_test_file(ax_config) -> str:
    """
    函数 `_check_test_file` 检查 smoke Lean 模板文件是否能被 Lean 正常解析。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- 检查成功说明。
    """
    import asyncio

    from ax_prover.utils.build import check_lean_file

    smoke_file = "ATP/temTH/testTH/test.lean"
    success, message = asyncio.run(
        check_lean_file(
            str(REPO_ROOT),
            smoke_file,
            ax_config.runtime.lean,
            asyncio.Semaphore(1),
            show_warnings=False,
            build=False,
        )
    )
    if not success:
        raise RuntimeError(message)
    return f"Lean can parse {smoke_file}."


def _check_llm_ping(ax_config) -> str:
    """
    函数 `_check_llm_ping` 直接调用模型执行一次最小联通性验证。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- 模型 ping 成功后的响应说明。
    """
    from ax_prover.utils.llm import create_llm

    llm = create_llm(ax_config.prover.prover_llm)
    try:
        response = llm.invoke("Reply with exactly PONG.")
    except Exception as exc:
        raise RuntimeError(_diagnose_llm_ping_failure(ax_config, exc)) from exc
    text = getattr(response, "text", str(response))
    if "PONG" not in text:
        raise RuntimeError(f"Unexpected ping response: {text}")
    return f"LLM ping succeeded with response: {text}"


def _check_smoke_proof(
    settings: ProjectSettings,
    ax_config_paths: tuple[str, ...],
    output_dir: Path,
    scenario,
) -> str:
    """
    函数 `_check_smoke_proof` 运行一次最小 smoke theorem 证明检查。
    输入：
      - settings: ProjectSettings -- ATP 项目设置。
      - ax_config_paths: tuple[str, ...] -- 需要叠加的 ax-prover 配置路径。
      - output_dir: Path -- doctor 输出目录。
      - scenario: Any -- smoke 测试场景对象。
    输出：
      - str -- smoke proof 成功说明。
    """
    result = run_single_scenario(
        scenario=scenario,
        settings=settings,
        ax_config_paths=ax_config_paths,
        attempt_index=1,
        output_dir=output_dir / "smoke_proof",
        persist=False,
    )
    if not result.success:
        raise RuntimeError(result.error or "ax-prover did not prove the smoke theorem.")
    if not result.valid:
        raise RuntimeError("Smoke proof finished but ATP marked the result invalid.")
    return "ax-prover proved the smoke theorem successfully."


def _run_check(name: str, fn) -> HealthCheckResult:
    """
    函数 `_run_check` 执行单个 doctor 检查并统一封装结果。
    输入：
      - name: str -- 检查项名称。
      - fn: callable -- 实际执行检查的函数。
    输出：
      - HealthCheckResult -- 单项检查结果对象。
    """
    started = time.perf_counter()
    try:
        message = fn()
        status = "ok"
        details = {}
    except Exception as exc:  # pragma: no cover - integration boundary
        message = f"{type(exc).__name__}: {exc}"
        status = "error"
        details = {}
    duration = time.perf_counter() - started
    return HealthCheckResult(
        name=name,
        status=status,
        message=message,
        duration_seconds=duration,
        details=details,
    )


def _skipped_check(name: str, message: str) -> HealthCheckResult:
    """
    函数 `_skipped_check` 生成一个被跳过的 doctor 检查结果。
    输入：
      - name: str -- 检查项名称。
      - message: str -- 跳过原因说明。
    输出：
      - HealthCheckResult -- 标记为 skipped 的检查结果对象。
    """
    return HealthCheckResult(
        name=name,
        status="skipped",
        message=message,
        duration_seconds=0.0,
    )


def _provider_name(ax_config) -> str:
    """
    函数 `_provider_name` 从 ax-prover 配置中提取模型 provider 名称。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str -- provider 名称，例如 `openai`。
    """
    model = ax_config.prover.prover_llm.model
    return model.split(":", 1)[0]


def _base_url(ax_config) -> str | None:
    """
    函数 `_base_url` 读取当前 prover_llm 的 `base_url`。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
    输出：
      - str | None -- `base_url` 字符串；未配置时返回 `None`。
    """
    provider_config = getattr(ax_config.prover.prover_llm, "provider_config", {}) or {}
    return provider_config.get("base_url")


def _diagnose_llm_ping_failure(ax_config, exc: Exception) -> str:
    """
    函数 `_diagnose_llm_ping_failure` 把底层 LLM 异常转换成更可读的诊断说明。
    输入：
      - ax_config: Any -- ax-prover 配置对象。
      - exc: Exception -- 底层抛出的异常。
    输出：
      - str -- 面向用户的诊断信息。
    """
    message = f"{type(exc).__name__}: {exc}"
    provider = _provider_name(ax_config)
    base_url = _base_url(ax_config)
    parsed = urlparse(base_url) if base_url else None
    if (
        provider == "openai"
        and base_url
        and parsed is not None
        and parsed.path.rstrip("/").endswith("/chat/completions")
        and ("responses" in str(exc) or "404" in str(exc))
    ):
        return (
            f"{message}. The configured OpenAI-compatible `base_url` points to the final "
            f"`/chat/completions` endpoint instead of the API root: {base_url}. "
            "The SDK appends resource paths itself, so you should configure the API root such as "
            "`https://host/v1`, not `https://host/v1/chat/completions`."
        )
    if (
        provider == "openai"
        and base_url
        and parsed is not None
        and parsed.path in {"", "/"}
        and (
            "model_dump" in str(exc)
            or "choices" in str(exc)
        )
    ):
        return (
            f"{message}. The configured OpenAI-compatible `base_url` appears to point at a website "
            f"root instead of a chat-completions API endpoint: {base_url}. "
            "If you are using a relay or proxy, configure the full API root such as `https://host/v1`; "
            "if you want the official provider endpoint, leave `base_url` empty or null in YAML."
        )
    return message
