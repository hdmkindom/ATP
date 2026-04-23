"""LeanSearch tool-call tracing for ATP run artifacts."""

from __future__ import annotations

import json
from contextvars import ContextVar, Token
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from time import perf_counter
from typing import Any


_ACTIVE_LEANSEARCH_SESSION: ContextVar["LeanSearchArchiveSession | None"] = ContextVar(
    "active_leansearch_archive_session",
    default=None,
)
_LEANSEARCH_PATCHED = False


@dataclass(frozen=True)
class LeanSearchTraceRecord:
    """单次 LeanSearch 调用的归档记录。"""

    search_index: int
    timestamp_tag: str
    json_path: str
    text_path: str


class LeanSearchArchiveSession:
    """单个场景尝试期间的 LeanSearch 调用归档会话。"""

    def __init__(self, attempt_dir: Path, enabled: bool = True):
        """
        函数 `__init__` 初始化 LeanSearch 归档会话。
        输入：
          - attempt_dir: Path -- 当前场景尝试目录。
          - enabled: bool -- 是否启用 LeanSearch 归档。
        输出：
          - None -- 构造函数仅初始化状态。
        """
        self.attempt_dir = attempt_dir
        self.enabled = enabled
        self.trace_dir = attempt_dir / "leansearch"
        self.index_path = self.trace_dir / "index.json"
        self.records: list[LeanSearchTraceRecord] = []
        self._counter = 0
        self._token: Token | None = None

    def __enter__(self) -> "LeanSearchArchiveSession":
        """
        函数 `__enter__` 激活当前场景的 LeanSearch 归档上下文。
        它会安装 LeanSearch 包装器，并把当前会话放入 `ContextVar` 供异步工具调用读取。
        输入：
          - 无。
        输出：
          - LeanSearchArchiveSession -- 当前归档会话对象。
        """
        install_leansearch_trace_hook()
        if not self.enabled:
            return self
        self.trace_dir.mkdir(parents=True, exist_ok=True)
        self._token = _ACTIVE_LEANSEARCH_SESSION.set(self)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """
        函数 `__exit__` 结束 LeanSearch 归档上下文并写出索引文件。
        输入：
          - exc_type: type | None -- 上下文退出时的异常类型。
          - exc_val: BaseException | None -- 上下文退出时的异常对象。
          - exc_tb: Any -- 上下文退出时的 traceback。
        输出：
          - None -- 仅执行上下文清理与索引写出。
        """
        if self.enabled:
            self._write_index()
        if self._token is not None:
            _ACTIVE_LEANSEARCH_SESSION.reset(self._token)
            self._token = None

    def record_search(
        self,
        query: str,
        config: Any,
        result_text: str | None,
        error: str | None,
        duration_seconds: float,
    ) -> None:
        """
        函数 `record_search` 记录一次 LeanSearch 查询结果。
        它会立即把查询参数、返回文本、异常和耗时写入当前场景的归档目录。
        输入：
          - query: str -- LeanSearch 查询词。
          - config: Any -- LeanSearch 配置对象。
          - result_text: str | None -- 查询返回的格式化文本。
          - error: str | None -- 查询异常文本；成功时为空。
          - duration_seconds: float -- 本次查询耗时（秒）。
        输出：
          - None -- 结果会立即写入磁盘。
        """
        if not self.enabled:
            return

        timestamp_tag = datetime.now().strftime("%m%d%H%M")
        self._counter += 1
        stem = f"{timestamp_tag}_search{self._counter:02d}"
        payload = {
            "search_index": self._counter,
            "timestamp": datetime.now().isoformat(),
            "timestamp_tag": timestamp_tag,
            "query": query,
            "server_url": getattr(config, "server_url", None),
            "max_results": getattr(config, "max_results", None),
            "timeout": getattr(config, "timeout", None),
            "max_retries": getattr(config, "max_retries", None),
            "retry_delay": getattr(config, "retry_delay", None),
            "duration_seconds": round(float(duration_seconds), 6),
            "error": error,
            "result_text": result_text or "",
        }

        json_path = self.trace_dir / f"{stem}.json"
        text_path = self.trace_dir / f"{stem}.txt"
        json_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        text_path.write_text((result_text or error or "") + ("\n" if (result_text or error) else ""), encoding="utf-8")
        self.records.append(
            LeanSearchTraceRecord(
                search_index=self._counter,
                timestamp_tag=timestamp_tag,
                json_path=str(json_path),
                text_path=str(text_path),
            )
        )
        self._write_index()

    def artifact_paths(self) -> dict[str, str]:
        """
        函数 `artifact_paths` 返回当前会话生成的 LeanSearch 归档路径。
        输入：
          - 无。
        输出：
          - dict[str, str] -- LeanSearch 目录与索引文件路径。
        """
        if not self.enabled:
            return {}
        return {
            "leansearch_trace_dir": str(self.trace_dir),
            "leansearch_trace_index": str(self.index_path),
        }

    def search_count(self) -> int:
        """
        函数 `search_count` 返回当前尝试归档到的 LeanSearch 查询次数。
        输入：
          - 无。
        输出：
          - int -- 当前已记录的查询次数。
        """
        return len(self.records)

    def _write_index(self) -> None:
        """
        函数 `_write_index` 把当前 LeanSearch 记录写入索引 JSON。
        输入：
          - 无。
        输出：
          - None -- 索引文件会被写入磁盘。
        """
        if not self.enabled:
            return
        payload = {
            "search_count": len(self.records),
            "records": [
                {
                    "search_index": record.search_index,
                    "timestamp_tag": record.timestamp_tag,
                    "json_path": record.json_path,
                    "text_path": record.text_path,
                }
                for record in self.records
            ],
        }
        self.trace_dir.mkdir(parents=True, exist_ok=True)
        self.index_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )


def install_leansearch_trace_hook() -> None:
    """
    函数 `install_leansearch_trace_hook` 为 ax-prover 的 LeanSearch 工具安装 ATP 归档包装器。
    它只会安装一次，后续重复调用不会重复包裹。
    输入：
      - 无。
    输出：
      - None -- 原地修改 ax-prover 的 `lean_search` 函数引用。
    """
    global _LEANSEARCH_PATCHED
    if _LEANSEARCH_PATCHED:
        return

    from ax_prover.tools import lean_search as lean_search_module

    original_lean_search = lean_search_module.lean_search

    async def wrapped_lean_search(query: str, config: Any) -> str:
        recorder = _ACTIVE_LEANSEARCH_SESSION.get()
        started = perf_counter()
        try:
            result = await original_lean_search(query, config)
        except Exception as exc:
            if recorder is not None:
                recorder.record_search(
                    query=query,
                    config=config,
                    result_text=None,
                    error=f"{type(exc).__name__}: {exc}",
                    duration_seconds=perf_counter() - started,
                )
            raise

        if recorder is not None:
            recorder.record_search(
                query=query,
                config=config,
                result_text=result,
                error=None,
                duration_seconds=perf_counter() - started,
            )
        return result

    lean_search_module.lean_search = wrapped_lean_search
    _LEANSEARCH_PATCHED = True

