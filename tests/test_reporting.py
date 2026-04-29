from datetime import datetime

from atp_axbench.models import ScenarioResult
from atp_axbench.reporting import render_run_summary_markdown


def test_markdown_summary_contains_scenario_row():
    """验证 Markdown 汇总会生成场景结果行。"""
    result = ScenarioResult(
        scenario_key="T1.free",
        theorem_id="T1",
        mode_family="free",
        attempt_index=1,
        target_file="ATP/temTH/CandidateTheorems/T1/Free.lean",
        theorem_name="candidate_T1_free",
        success=True,
        valid=True,
        started_at=datetime(2026, 4, 5, 1, 0, 0),
        finished_at=datetime(2026, 4, 5, 1, 1, 0),
    )
    markdown = render_run_summary_markdown([result], {"repo_root": "/tmp/repo"})
    assert "| T1.free | yes | yes | 0 | 0.00 |  |" in markdown
