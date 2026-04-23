"""Minimal prompt adapter for ATP scenarios."""

from __future__ import annotations

from .models import ModeFamily, ScenarioSpec


def render_user_comments(scenario: ScenarioSpec) -> str:
    """
    函数 `render_user_comments` 返回写入 ax-prover `prover.user_comments` 的附加提示。
    ATP 不重写 ax-prover 的主 system prompt，而是根据“当前题目 + 当前模式”选择对应的
    theorem-level 指令文本，并仅在该场景运行时作为 `user_comments` 注入。ax-prover 会把
    这段文本追加到它自己的 proposer / reviewer system prompt 中，因此这里是“按场景附加说明”，
    不是“全局 prompt”，也不是“替换 prover prompt”。
    输入：
      - scenario: ScenarioSpec -- 当前需要运行的场景对象。
    输出：
      - str -- 需要注入到 `prover.user_comments` 的文本；为空时返回空串。
    """
    theorem = scenario.theorem
    if theorem is None:
        return scenario.user_comments.strip()

    if scenario.mode_family == ModeFamily.FREE.value:
        return theorem.free_instruction.strip()
    if scenario.mode_family == ModeFamily.DISABLE.value:
        return theorem.disable_instruction.strip()

    if scenario.route_hint == "routeA":
        return theorem.route_a.strip()
    if scenario.route_hint == "routeB":
        return theorem.route_b.strip()

    return scenario.user_comments.strip()
