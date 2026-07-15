#!/usr/bin/env python3
from __future__ import annotations

import ast
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent


def test_manual_test_entrypoints_reference_defined_symbols() -> None:
    failures: list[str] = []
    for path in sorted(SCRIPT_DIR.glob("test_*.py")):
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        definitions = {
            node.name
            for node in tree.body
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef))
        }
        for node in ast.walk(tree):
            if not isinstance(node, (ast.Assign, ast.AnnAssign)):
                continue
            targets = node.targets if isinstance(node, ast.Assign) else [node.target]
            if not any(
                isinstance(target, ast.Name) and target.id in {"tests", "checks"}
                for target in targets
            ):
                continue
            if node.value is None:
                continue
            for child in ast.walk(node.value):
                if (
                    isinstance(child, ast.Name)
                    and isinstance(child.ctx, ast.Load)
                    and child.id.startswith("test_")
                    and child.id not in definitions
                ):
                    failures.append(f"{path.name}:{child.lineno}:{child.id}")

    assert not failures, "undefined manual test entrypoints: " + ", ".join(failures)


if __name__ == "__main__":
    test_manual_test_entrypoints_reference_defined_symbols()
    print("test_battle_script_entrypoint_symbols.py: ok")
