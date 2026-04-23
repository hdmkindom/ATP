"""Project path helpers."""

from pathlib import Path

PACKAGE_ROOT = Path(__file__).resolve().parent
SRC_ROOT = PACKAGE_ROOT.parent
ATP_ROOT = SRC_ROOT.parent
REPO_ROOT = ATP_ROOT.parent
CONFIG_ROOT = ATP_ROOT / "config"
DOC_ROOT = ATP_ROOT / "doc"
ARTIFACT_ROOT = ATP_ROOT / "artifacts"
