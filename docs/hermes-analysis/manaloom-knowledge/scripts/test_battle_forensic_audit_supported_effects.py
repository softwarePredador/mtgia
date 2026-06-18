#!/usr/bin/env python3
"""Regression coverage for forensic audit effect support drift."""

from __future__ import annotations

import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("battle_forensic_audit.py")
spec = importlib.util.spec_from_file_location(
    "battle_forensic_audit_under_test",
    MODULE_PATH,
)
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


def test_supported_effects_cover_live_engine_handlers():
    assert "hand_filter" in audit.SUPPORTED_EFFECTS
    assert "copy_creature_token" in audit.SUPPORTED_EFFECTS


if __name__ == "__main__":
    tests = [
        test_supported_effects_cover_live_engine_handlers,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
