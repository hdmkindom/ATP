import json
from pathlib import Path
import tempfile

from atp_axbench.leansearch_trace import LeanSearchArchiveSession


def test_leansearch_archive_session_writes_search_records_and_index():
    """验证 LeanSearch 归档会话会为每次查询写出文本、JSON 和索引文件。"""
    with tempfile.TemporaryDirectory() as temp_dir:
        attempt_dir = Path(temp_dir) / "attempt"
        with LeanSearchArchiveSession(attempt_dir, enabled=True) as session:
            session.record_search(
                query="character sum over finite group",
                config=type("Cfg", (), {"server_url": "https://leansearch.net", "max_results": 6, "timeout": 60, "max_retries": 3, "retry_delay": 2})(),
                result_text="=== q (1 matches) ===\n\n• Foo.bar [theorem]",
                error=None,
                duration_seconds=1.25,
            )

        index = json.loads((attempt_dir / "leansearch" / "index.json").read_text(encoding="utf-8"))
        assert index["search_count"] == 1
        record = index["records"][0]
        json_payload = json.loads(Path(record["json_path"]).read_text(encoding="utf-8"))
        assert json_payload["query"] == "character sum over finite group"
        assert json_payload["server_url"] == "https://leansearch.net"
        assert "Foo.bar" in json_payload["result_text"]
        assert Path(record["text_path"]).read_text(encoding="utf-8").startswith("=== q")
