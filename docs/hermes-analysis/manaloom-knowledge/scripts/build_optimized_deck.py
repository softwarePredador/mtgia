#!/usr/bin/env python3
"""Historical Lorehold deck-builder entrypoint.

This file is intentionally non-operational. It used a hardcoded, collection
driven heuristic and predated the current rule-readiness, baseline hash, and
safe battle-benchmark workflow.

Use `lorehold_variant_strategy_matrix.py` and `lorehold_variant_battle_gate.py`
under `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`.
"""

from __future__ import annotations

import sys


def main() -> int:
    print("status=historical_disabled")
    print("replacement=lorehold_variant_strategy_matrix.py_then_lorehold_variant_battle_gate.py")
    print("reason=hardcoded_legacy_builder_not_safe_for_current_lorehold_flow")
    print("next=generate_contract_matrix_then_run_equal_battle_gate")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
