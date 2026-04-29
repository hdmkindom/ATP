from atp_axbench.settings import load_project_settings


def test_project_settings_exposes_persist_last_attempt_on_failure():
    """验证项目设置会正确读取失败时保留最后一次尝试的开关。"""
    settings = load_project_settings()
    assert hasattr(settings.execution, "persist_last_attempt_on_failure")
    assert hasattr(settings.execution, "max_llm_requests_per_attempt")
    assert settings.execution.max_llm_requests_per_attempt == 0


def test_project_settings_exposes_console_and_runtime_status_sections():
    """验证项目设置会暴露终端展示与运行状态的配置段。"""
    settings = load_project_settings()
    assert settings.console.enable_color is True
    assert settings.runtime_status.enabled is True
