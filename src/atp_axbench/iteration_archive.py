"""Live and post-run proposal snapshot archiving utilities."""

from __future__ import annotations

import inspect
import json
from pathlib import Path
import shutil
from typing import Any

from .models import ProposalSnapshotRecord


class ProposalArchiveSession:
    """运行期 proposal 快照归档会话。"""

    def __init__(
        self,
        repo_root: Path,
        attempt_dir: Path,
        target_relative_path: str,
        enabled: bool = True,
    ):
        """
        函数 `__init__` 初始化单次运行的 proposal 快照归档器。
        它保存仓库根目录、尝试目录、目标文件路径以及是否启用归档，并为后续归档准备目录状态。
        输入：
          - repo_root: Path -- 仓库根目录。
          - attempt_dir: Path -- 当前场景尝试的输出目录。
          - target_relative_path: str -- 目标 Lean 文件相对于仓库根目录的路径。
          - enabled: bool -- 是否启用 proposal 快照归档。
        输出：
          - None -- 构造函数只初始化对象状态。
        """
        self.repo_root = repo_root
        self.attempt_dir = attempt_dir
        self.target_relative_path = target_relative_path
        self.enabled = enabled
        self.iteration_dir = attempt_dir / "iterations"
        self.workspace_dir = attempt_dir / "_iteration_workspace"
        self.records: list[ProposalSnapshotRecord] = []
        self._counter = 0
        self._original_init = None

    def __enter__(self) -> "ProposalArchiveSession":
        """
        函数 `__enter__` 安装 proposal 创建时的归档钩子。
        它会猴子补丁 `ProposalMessage.__init__`，在 proposer 节点生成新 proposal 时立即归档该轮完整文件。
        输入：
          - 无。
        输出：
          - ProposalArchiveSession -- 当前归档会话对象。
        """
        if not self.enabled:
            return self

        from ax_prover.models.messages import ProposalMessage

        self.iteration_dir.mkdir(parents=True, exist_ok=True)
        self.workspace_dir.mkdir(parents=True, exist_ok=True)
        self._original_init = ProposalMessage.__init__
        session = self

        def wrapped_init(proposal_self, *args, **kwargs):
            session._original_init(proposal_self, *args, **kwargs)
            if session._created_in_proposer_node():
                session.archive_live_proposal(proposal_self)

        ProposalMessage.__init__ = wrapped_init
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """
        函数 `__exit__` 恢复 proposal 钩子并清理归档工作区。
        它负责把 `ProposalMessage.__init__` 恢复成原始实现，并删除内部重建工作区。
        输入：
          - exc_type: type | None -- 上下文退出时的异常类型。
          - exc_val: BaseException | None -- 上下文退出时的异常对象。
          - exc_tb: Any -- 上下文退出时的 traceback。
        输出：
          - None -- 仅执行清理动作。
        """
        if self.enabled and self._original_init is not None:
            from ax_prover.models.messages import ProposalMessage

            ProposalMessage.__init__ = self._original_init
        shutil.rmtree(self.workspace_dir, ignore_errors=True)

    def archive_live_proposal(self, proposal) -> None:
        """
        函数 `archive_live_proposal` 在 proposer 节点生成新 proposal 时立即保存该轮文件。
        它会基于当前模板文件重建 ax-prover 在 builder 节点看到的完整 Lean 文件，并写入迭代归档目录。
        输入：
          - proposal: ProposalMessage -- ax-prover 当前轮生成的 proposal 对象。
        输出：
          - None -- 归档结果写入磁盘并更新内部记录。
        """
        if not self.enabled:
            return
        if proposal.location is None or proposal.location.path != self.target_relative_path:
            return

        timestamp_tag = _timestamp_tag()
        self._counter += 1
        stem = f"{timestamp_tag}_iter{self._counter:02d}"
        workspace_target = self.workspace_dir / self.target_relative_path
        workspace_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(self.repo_root / self.target_relative_path, workspace_target)

        metadata: dict[str, Any] = {
            "iteration_index": self._counter,
            "timestamp_tag": timestamp_tag,
            "location": proposal.location.formatted_context,
            "imports": proposal.imports,
            "opens": proposal.opens,
            "reasoning": proposal.reasoning,
            "rebuild_error": None,
        }

        try:
            from ax_prover.utils.files import edit_function, edit_imports, edit_opens

            if proposal.imports:
                imports_ok = edit_imports(
                    str(self.workspace_dir), self.target_relative_path, proposal.imports
                )
                if not imports_ok:
                    metadata["rebuild_error"] = "Failed to apply imports while rebuilding snapshot."
            if proposal.opens:
                opens_ok = edit_opens(str(self.workspace_dir), self.target_relative_path, proposal.opens)
                if not opens_ok:
                    metadata["rebuild_error"] = "Failed to apply opens while rebuilding snapshot."
            if proposal.code:
                function_ok = edit_function(str(self.workspace_dir), proposal.location, proposal.code)
                if not function_ok:
                    metadata["rebuild_error"] = "Failed to apply theorem body while rebuilding snapshot."
            snapshot_content = workspace_target.read_text(encoding="utf-8")
        except Exception as exc:  # pragma: no cover - file rebuild boundary
            snapshot_content = proposal.code
            metadata["rebuild_error"] = f"{type(exc).__name__}: {exc}"

        lean_path = self.iteration_dir / f"{stem}.lean"
        metadata_path = self.iteration_dir / f"{stem}.json"
        lean_path.write_text(snapshot_content, encoding="utf-8")
        metadata_path.write_text(
            json.dumps(metadata, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        self.records.append(
            ProposalSnapshotRecord(
                iteration_index=self._counter,
                timestamp_tag=timestamp_tag,
                lean_path=str(lean_path),
                metadata_path=str(metadata_path),
            )
        )

    def finalize_with_state(self, state) -> None:
        """
        函数 `finalize_with_state` 用最终状态补全每轮归档的反馈信息。
        它会按 proposal 顺序匹配后续 feedback，并把这些信息回填到每轮归档的 JSON 元数据中。
        输入：
          - state: Any -- ax-prover 返回的最终状态对象，通常是 `ProverAgentState`。
        输出：
          - None -- 仅更新归档元数据文件。
        """
        if not self.enabled or state is None:
            return

        iteration_payloads = _collect_iteration_payloads(state.messages)
        for record, payload in zip(self.records, iteration_payloads):
            metadata_path = Path(record.metadata_path)
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            metadata["feedback_messages"] = payload["feedback_messages"]
            metadata["message_count"] = payload["message_count"]
            metadata_path.write_text(
                json.dumps(metadata, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )

    def artifact_paths(self) -> list[str]:
        """
        函数 `artifact_paths` 返回当前会话生成的迭代 Lean 快照路径列表。
        输入：
          - 无。
        输出：
          - list[str] -- 当前尝试下所有迭代快照文件的绝对路径列表。
        """
        return [record.lean_path for record in self.records]

    def _created_in_proposer_node(self) -> bool:
        """
        函数 `_created_in_proposer_node` 判断当前 `ProposalMessage` 是否在 proposer 节点内创建。
        它通过调用栈筛掉状态反序列化等非实时创建路径，避免重复归档。
        输入：
          - 无。
        输出：
          - bool -- 若 proposal 由 proposer 节点实时生成则返回 `True`。
        """
        return any(frame.function == "_proposer_node" for frame in inspect.stack())


def _collect_iteration_payloads(messages: list[Any]) -> list[dict[str, Any]]:
    """
    函数 `_collect_iteration_payloads` 按 proposal 轮次收集其后的 feedback 消息。
    它将消息流拆成若干轮，每轮包含一个 proposal 和直到下一轮 proposal 之前的所有 feedback。
    输入：
      - messages: list[Any] -- ax-prover 完整消息序列。
    输出：
      - list[dict[str, Any]] -- 每轮的反馈与计数信息列表。
    """
    from ax_prover.models.messages import FeedbackMessage, ProposalMessage

    payloads: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    for message in messages:
        if isinstance(message, ProposalMessage):
            current = {"feedback_messages": [], "message_count": 1}
            payloads.append(current)
            continue
        if current is None:
            continue
        current["message_count"] += 1
        if isinstance(message, FeedbackMessage):
            current["feedback_messages"].append(
                {
                    "feedback_type": message.feedback_type,
                    "is_success": message.is_success,
                    "is_terminal": message.is_terminal,
                    "content": message.content,
                }
            )
    return payloads


def _timestamp_tag() -> str:
    """
    函数 `_timestamp_tag` 生成按月日时分排序的时间标签。
    输入：
      - 无。
    输出：
      - str -- 形如 `04051230` 的时间标签字符串。
    """
    from datetime import datetime

    return datetime.now().strftime("%m%d%H%M")
