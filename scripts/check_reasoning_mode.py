#!/usr/bin/env python3
"""Inspect whether ATP's configured model is actually using reasoning mode."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ATP_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = ATP_ROOT / "src"
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from atp_axbench.reasoning_probe import reasoning_report_json, write_reasoning_report


DEFAULT_PROMPT = (
    "Without tools, solve this short reasoning task carefully: "
    "find the smallest positive integer n such that n^2 ≡ -1 (mod 221). "
    "Reply in 2-4 short sentences and include the final integer clearly."
)


def main(argv: list[str] | None = None) -> int:
    """
    函数 `main` 是 reasoning mode 检查脚本的命令行入口。
    它会读取 ATP 的 experiment 配置，打印 LangChain 实际拿到的 reasoning 参数，并可选执行真实 API 调用做对照。
    输入：
      - argv: list[str] | None -- 可选的命令行参数列表；为空时使用进程参数。
    输出：
      - int -- 命令退出码。
    """
    parser = argparse.ArgumentParser(description="Check whether ATP's configured LLM is using reasoning mode.")
    parser.add_argument(
        "--ax-config",
        action="append",
        default=[],
        help="Extra ax-prover YAML config overlay(s).",
    )
    parser.add_argument(
        "--live",
        action="store_true",
        help="Actually invoke the configured model once (or twice if compare-effort is set).",
    )
    parser.add_argument(
        "--compare-effort",
        choices=["low", "medium", "high", "xhigh"],
        default=None,
        help="Compare the current config against a temporary reasoning override.",
    )
    parser.add_argument(
        "--prompt",
        default=DEFAULT_PROMPT,
        help="Prompt used for live probing.",
    )
    parser.add_argument(
        "--output-json",
        type=Path,
        default=None,
        help="Optional JSON output path for the structured report.",
    )
    args = parser.parse_args(argv)

    ax_config_paths = tuple(["ATP/config/ax_prover_experiment.yaml", *args.ax_config])
    report = reasoning_report_json(
        ax_config_paths=ax_config_paths,
        prompt=args.prompt,
        compare_effort=args.compare_effort,
        live=args.live,
    )

    print(json.dumps(report, ensure_ascii=False, indent=2))

    if args.output_json is not None:
        write_reasoning_report(args.output_json, report)
        print(f"\nWrote reasoning report to {args.output_json}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
