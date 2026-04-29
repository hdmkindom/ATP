#!/usr/bin/env python3
"""Convenience entrypoint for the ATP ax-prover harness."""

from pathlib import Path
import sys

ATP_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = ATP_ROOT / "src"
src_root_text = str(SRC_ROOT)
if src_root_text in sys.path:
    sys.path.remove(src_root_text)
sys.path.insert(0, src_root_text)

from atp_axbench.cli import main


if __name__ == "__main__":
    raise SystemExit(main())
