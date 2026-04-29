from atp_axbench.catalog import default_catalog_path, load_catalog
from atp_axbench.prompts import render_user_comments
from atp_axbench.settings import load_project_settings


def test_disable_prompt_mentions_forbidden_route_family():
    """验证禁用模式从 theorem-level 的 disable_instruction 生成 user_comments。"""
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))
    scenario = catalog.scenarios["T6.disable"]
    assert scenario.theorem is not None
    prompt = render_user_comments(scenario)
    assert prompt == scenario.theorem.disable_instruction.strip()


def test_free_prompt_uses_free_instruction_from_catalog():
    """验证自由模式会从 theorem-level 的 free_instruction 生成 user_comments。"""
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))
    scenario = catalog.scenarios["T1.free"]
    assert scenario.theorem is not None
    prompt = render_user_comments(scenario)
    assert prompt == scenario.theorem.free_instruction.strip()


def test_guided_prompt_uses_route_instruction_only():
    """验证引导模式只注入当前路线 instruction 本身。"""
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))
    scenario = catalog.scenarios["T1.routeA"]
    assert scenario.theorem is not None
    prompt = render_user_comments(scenario)
    assert prompt == scenario.theorem.route_a.strip()


def test_test_prompt_keeps_smoke_instruction_short_and_direct():
    """验证 smoke 测试场景仍直接透传场景级 user_comments。"""
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))
    scenario = catalog.scenarios["test.smoke"]
    prompt = render_user_comments(scenario)
    assert prompt == scenario.user_comments.strip()
