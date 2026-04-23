"""Command line interface for ATP ax-prover experiments."""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

from .catalog import default_catalog_path, load_catalog
from .console import (
    capture_terminal_output,
    print_error,
    print_info,
    print_status,
    print_warning,
)
from .doctor import run_doctor
from .paths import REPO_ROOT
from .runner import build_ax_config, run_batch
from .runtime_monitor import BatchProgressTracker
from .settings import load_project_settings


def main(argv: list[str] | None = None) -> int:
    """
    函数 `main` 是 ATP CLI 的主入口。
    它负责解析命令行参数、加载项目设置与场景目录，并分发到 `list`、`run` 和 `doctor` 子命令。
    输入：
      - argv: list[str] | None -- 可选的命令行参数列表；为空时使用进程参数。
    输出：
      - int -- 命令退出码。
    """
    parser = argparse.ArgumentParser(
        description="ATP ax-prover benchmark harness",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list", help="List known scenarios")
    list_parser.add_argument(
        "--only",
        choices=["all", "candidates", "test"],
        default="all",
        help="Filter which scenarios are shown.",
    )

    run_parser = subparsers.add_parser("run", help="Run one or more ATP scenarios")
    run_parser.add_argument(
        "selectors",
        nargs="*",
        help="Scenario selectors such as `test`, `T1`, `T1.free`, or `all`.",
    )
    run_parser.add_argument(
        "--repeats",
        type=int,
        default=None,
        help="How many independent attempts to run per selected scenario.",
    )
    run_parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Directory for artifacts; default is ATP/artifacts/runs/<timestamp>.",
    )
    run_parser.add_argument(
        "--persist",
        action="store_true",
        help="Keep successful proof edits in the source file instead of restoring the template.",
    )
    run_parser.add_argument(
        "--skip-prebuild",
        action="store_true",
        help="Skip the repo-wide `lake build` step before the batch.",
    )
    run_parser.add_argument(
        "--ax-config",
        action="append",
        default=[],
        help="Extra ax-prover YAML config overlay(s).",
    )

    doctor_parser = subparsers.add_parser("doctor", help="Run environment health checks")
    doctor_parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Directory for doctor artifacts; default is ATP/artifacts/doctor/<timestamp>.",
    )
    doctor_parser.add_argument(
        "--skip-llm-ping",
        action="store_true",
        help="Skip the live LLM connectivity check.",
    )
    doctor_parser.add_argument(
        "--skip-proof",
        action="store_true",
        help="Skip the smoke theorem proof check.",
    )
    doctor_parser.add_argument(
        "--ax-config",
        action="append",
        default=[],
        help="Extra ax-prover YAML config overlay(s).",
    )

    args = parser.parse_args(argv)
    settings = load_project_settings()
    catalog = load_catalog(default_catalog_path(settings.catalog_path))

    if args.command == "list":
        return _handle_list(args.only, catalog)
    if args.command == "run":
        repeats = args.repeats or settings.execution.default_repeats
        scenarios = catalog.resolve_selectors(args.selectors or ["test"])
        output_dir = args.output_dir or _default_output_dir(settings.artifacts_dir, "runs")
        ax_config_paths = tuple([*settings.experiment_ax_config, *args.ax_config])
        with capture_terminal_output(output_dir / "terminal.log"):
            progress_tracker = None
            if settings.runtime_status.enabled:
                ax_config = build_ax_config(
                    ax_config_paths,
                    user_comments="ATP CLI run banner.",
                    disable_langsmith_tracing=settings.execution.disable_langsmith_tracing,
                    console_settings=settings.console,
                )
                progress_tracker = BatchProgressTracker(
                    runtime_status=settings.runtime_status,
                    console=settings.console,
                    scenarios=scenarios,
                    repeats=repeats,
                    ax_config=ax_config,
                    max_llm_requests_per_attempt=settings.execution.max_llm_requests_per_attempt,
                )
                progress_tracker.print_banner()

            try:
                results = run_batch(
                    scenarios=scenarios,
                    settings=settings,
                    ax_config_paths=ax_config_paths,
                    repeats=repeats,
                    output_dir=output_dir,
                    persist=args.persist,
                    skip_prebuild=args.skip_prebuild,
                    progress_tracker=progress_tracker,
                )
            except KeyboardInterrupt:
                print_warning(
                    "Interrupted by user. Partial artifacts and terminal log have been preserved.",
                    enable_color=settings.console.enable_color,
                )
                print_status(
                    f"Artifacts written to {output_dir}",
                    enable_color=settings.console.enable_color,
                )
                return 130

            if not settings.runtime_status.enabled:
                for result in results:
                    line = (
                        f"{'✓' if result.valid else 'X'} {result.scenario_key} "
                        f"attempt={result.attempt_index} "
                        f"prover_iters={result.iterations} "
                        f"maxed={result.max_iterations_reached} "
                        f"success={result.success} valid={result.valid}"
                    )
                    if result.valid:
                        print_info(line, enable_color=settings.console.enable_color)
                    else:
                        print_error(line, enable_color=settings.console.enable_color)
            print_status(
                f"Artifacts written to {output_dir}",
                enable_color=settings.console.enable_color,
            )
            return 0 if all(result.valid for result in results) else 1
    if args.command == "doctor":
        output_dir = args.output_dir or _default_output_dir(settings.artifacts_dir, "doctor")
        ax_config_paths = tuple([*settings.doctor_ax_config, *args.ax_config])
        with capture_terminal_output(output_dir / "terminal.log"):
            try:
                report = run_doctor(
                    settings=settings,
                    catalog=catalog,
                    ax_config_paths=ax_config_paths,
                    output_dir=output_dir,
                    skip_llm_ping=args.skip_llm_ping,
                    skip_proof=args.skip_proof,
                )
            except KeyboardInterrupt:
                print_warning(
                    "Doctor interrupted by user. Partial artifacts and terminal log have been preserved.",
                    enable_color=settings.console.enable_color,
                )
                print_status(
                    f"Doctor artifacts written to {output_dir}",
                    enable_color=settings.console.enable_color,
                )
                return 130

            for check in report.checks:
                message = f"{check.status.upper():7s} {check.name}: {check.message}"
                if check.status == "error":
                    print_error(message, enable_color=settings.console.enable_color)
                elif check.status == "skipped":
                    print_warning(message, enable_color=settings.console.enable_color)
                else:
                    print_info(message, enable_color=settings.console.enable_color)
            print_status(
                f"Doctor artifacts written to {output_dir}",
                enable_color=settings.console.enable_color,
            )
            return 0 if all(check.status != "error" for check in report.checks) else 1
    raise ValueError(f"Unsupported command: {args.command}")


def _handle_list(scope: str, catalog) -> int:
    """
    函数 `_handle_list` 输出符合过滤条件的场景列表。
    输入：
      - scope: str -- 列表过滤范围，取值为 `all`、`candidates` 或 `test`。
      - catalog: Any -- 已加载的场景目录对象。
    输出：
      - int -- 命令退出码。
    """
    scenarios = catalog.ordered_scenarios()
    for scenario in scenarios:
        if scope == "candidates" and scenario.scenario_key.startswith("test."):
            continue
        if scope == "test" and not scenario.scenario_key.startswith("test."):
            continue
        print(
            f"{scenario.scenario_key:12s} "
            f"mode={scenario.mode_family:8s} "
            f"target={scenario.target_file}"
        )
    return 0


def _default_output_dir(artifacts_dir: str, kind: str) -> Path:
    """
    函数 `_default_output_dir` 生成默认的输出目录路径。
    输入：
      - artifacts_dir: str -- 项目设置中的归档根目录。
      - kind: str -- 归档类型，例如 `runs` 或 `doctor`。
    输出：
      - Path -- 默认输出目录路径。
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return (REPO_ROOT / artifacts_dir / kind / timestamp).resolve()
