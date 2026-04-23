"""Tiny zero-dependency test runner for ATP/tests."""

from __future__ import annotations

import importlib
import inspect
from pathlib import Path
import sys


ATP_ROOT = Path(__file__).resolve().parents[1]
TEST_ROOT = ATP_ROOT / "tests"
SRC_ROOT = ATP_ROOT / "src"

# 确保 ATP/src 和 ATP/tests 都在 sys.path 中，以便导入测试模块和被测试模块。
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))
if str(TEST_ROOT) not in sys.path:
    sys.path.insert(0, str(TEST_ROOT))


def main() -> int:
    """
    函数 `main` 运行 `ATP/tests` 目录中的零依赖测试。
    它会自动发现所有 `test_*.py` 中的测试函数并逐一执行。
    输出：
      - int -- 测试全部通过时返回 `0`，否则返回 `1`。
    """
    failures: list[str] = []
    module_names = sorted(
        path.stem
        for path in TEST_ROOT.glob("test_*.py")
        if path.name != "__init__.py"
    )

    for module_name in module_names:
        module = importlib.import_module(module_name)
        for name, obj in inspect.getmembers(module, inspect.isfunction):
            if not name.startswith("test_"):
                continue
            try:
                obj()
                print(f"PASS {module_name}.{name}")
            except Exception as exc:  # pragma: no cover - test runner boundary
                failures.append(f"{module_name}.{name}: {type(exc).__name__}: {exc}")
                print(f"FAIL {module_name}.{name}: {type(exc).__name__}: {exc}")

    if failures:
        print("\nFailures:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("\nAll ATP tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
