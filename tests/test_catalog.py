from atp_axbench.catalog import default_catalog_path, load_catalog
from atp_axbench.settings import load_project_settings


def test_catalog_contains_expected_number_of_scenarios():
    """验证场景目录包含预期数量的场景。"""
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))
    assert len(catalog.scenarios) == 41
    assert "test.smoke" in catalog.scenarios
    assert "T1.free" in catalog.scenarios
    assert "T10.routeB" in catalog.scenarios


def test_selector_expands_a_theorem_to_its_four_modes():
    """验证题号选择器会展开成四个正式模式。"""
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))
    selected = catalog.resolve_selectors(["T2"])
    assert [scenario.scenario_key for scenario in selected] == [
        "T2.free",
        "T2.disable",
        "T2.routeA",
        "T2.routeB",
    ]


def test_candidate_prompt_text_lives_on_theorem_metadata_not_scenario_copy():
    """验证候选题 prompt 来源保存在 theorem-level 四模式字段，而不是场景内联副本。"""
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))

    theorem = catalog.theorems["T2"]
    free_scenario = catalog.scenarios["T2.free"]
    disable_scenario = catalog.scenarios["T2.disable"]
    guided_scenario = catalog.scenarios["T2.routeA"]

    assert theorem.free_instruction
    assert theorem.disable_instruction
    assert theorem.route_a
    assert theorem.route_b
    assert free_scenario.user_comments == ""
    assert disable_scenario.user_comments == ""
    assert guided_scenario.user_comments == ""


def test_candidate_theorem_yaml_only_uses_four_prompt_fields():
    """验证正式候选题 YAML 只保留四个 theorem-level prompt 字段。"""
    from omegaconf import OmegaConf

    settings = load_project_settings()
    raw = OmegaConf.to_container(
        OmegaConf.load(default_catalog_path(settings.catalog_path)),
        resolve=True,
    )

    for theorem_id, theorem_data in raw["candidate_theorems"].items():
        assert tuple(theorem_data.keys()) == (
            "free_instruction",
            "disable_instruction",
            "route_a",
            "route_b",
        ), theorem_id


def test_catalog_rejects_candidate_routes_extension_syntax():
    """验证候选题不再接受 `routes:` 扩展写法，prompt 来源必须回到四个标准字段。"""
    import tempfile
    from pathlib import Path

    with tempfile.TemporaryDirectory() as temp_dir:
        config_path = Path(temp_dir) / "catalog.yaml"
        config_path.write_text(
            """
test_cases: {}
candidate_theorems:
  T11:
    free_instruction: Explore freely.
    disable_instruction: Avoid the short route.
    routes:
      routeA:
        instruction: Use route A.
      routeB:
        instruction: Use route B.
""".strip(),
            encoding="utf-8",
        )

        try:
            load_catalog(config_path)
        except ValueError as exc:
            assert "不再支持 `routes:`" in str(exc)
        else:  # pragma: no cover - defensive branch
            raise AssertionError("expected ValueError for candidate theorem routes syntax")


def test_catalog_rejects_candidate_scenarios_extension_syntax():
    """验证候选题不再接受 `scenarios:` 扩展写法。"""
    import tempfile
    from pathlib import Path

    with tempfile.TemporaryDirectory() as temp_dir:
        config_path = Path(temp_dir) / "catalog.yaml"
        config_path.write_text(
            """
test_cases: {}
candidate_theorems:
  T11:
    free_instruction: Explore freely.
    disable_instruction: Avoid the short route.
    route_a: Use route A.
    route_b: Use route B.
    scenarios:
      free:
        mode_family: free
        file_name: Free.lean
        prompt: Explore freely.
""".strip(),
            encoding="utf-8",
        )

        try:
            load_catalog(config_path)
        except ValueError as exc:
            assert "不再支持 `scenarios:`" in str(exc)
        else:  # pragma: no cover - defensive branch
            raise AssertionError("expected ValueError for candidate theorem scenarios syntax")


def test_catalog_rejects_nested_route_mapping_syntax():
    """验证 `route_a` / `route_b` 现在必须是纯文本字符串。"""
    import tempfile
    from pathlib import Path

    with tempfile.TemporaryDirectory() as temp_dir:
        config_path = Path(temp_dir) / "catalog.yaml"
        config_path.write_text(
            """
test_cases: {}
candidate_theorems:
  T11:
    free_instruction: Explore freely.
    disable_instruction: Avoid the short route.
    route_a:
      instruction: Use route A.
    route_b: Use route B.
""".strip(),
            encoding="utf-8",
        )

        try:
            load_catalog(config_path)
        except TypeError as exc:
            assert "route_a" in str(exc)
            assert "必须是字符串提示文本" in str(exc)
        else:  # pragma: no cover - defensive branch
            raise AssertionError("expected TypeError for nested route syntax")
