#!/usr/bin/env python3
"""Convenience entrypoint for the ATP ax-prover harness."""

from pathlib import Path
import sys

ATP_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = ATP_ROOT / "src"
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from atp_axbench.cli import main


if __name__ == "__main__":
    raise SystemExit(main())
