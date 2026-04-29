from atp_axbench.reasoning_probe import collect_reasoning_diagnostics


def test_collect_reasoning_diagnostics_reports_high_reasoning_in_current_experiment_profile():
    """验证 reasoning probe 能报告当前 experiment 配置的实际模型与 reasoning 状态。"""
    report = collect_reasoning_diagnostics(("ATP/config/ax_prover_experiment.yaml",))
    llm_attrs = report["llm_attrs"]
    assert report["model"] == "deepseek:deepseek-v4-pro"
    assert llm_attrs["reasoning"] is None
    assert llm_attrs["reasoning_effort"] == "high"


def test_collect_reasoning_diagnostics_can_apply_temporary_reasoning_override():
    """验证 reasoning probe 可通过临时覆盖层把高思考参数传给 LangChain。"""
    report = collect_reasoning_diagnostics(
        ("ATP/config/ax_prover_experiment.yaml",),
        reasoning_effort="high",
    )
    llm_attrs = report["llm_attrs"]
    assert llm_attrs["reasoning"] == {"effort": "high"}
    assert llm_attrs["reasoning_effort"] == "high"
