from pathlib import Path
import tempfile

from atp_axbench.runtime_monitor import (
    RuntimeHistory,
    load_runtime_history,
    write_runtime_history,
)


def test_runtime_history_round_trip_preserves_simple_average():
    """验证运行时间历史文件可以正确写回并重新加载。"""
    history = RuntimeHistory(
        seconds_per_formal_scenario=123.5,
        recorded_formal_runs=2,
        recent_formal_runs=[{"average_seconds_per_scenario": 123.5}],
    )

    with tempfile.TemporaryDirectory() as temp_dir:
        history_path = Path(temp_dir) / "runtime_history.json"
        write_runtime_history(history_path, history)
        restored = load_runtime_history(history_path)

    assert restored.seconds_per_formal_scenario == 123.5
    assert restored.recorded_formal_runs == 2
