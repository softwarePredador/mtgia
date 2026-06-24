#!/usr/bin/env python3
"""Historical Lorehold deck-builder entrypoint.

This file is intentionally non-operational. It used a hardcoded, collection
driven heuristic and predated the current rule-readiness, baseline hash, and
safe battle-benchmark workflow.

Use `lorehold_ideal_deck_candidate_matrix.py` to build the candidate matrix,
then route approved candidates through the master optimizer/slot scan gates.
"""

from __future__ import annotations

import sys


def main() -> int:
    print("status=historical_disabled")
    print("replacement=lorehold_ideal_deck_candidate_matrix.py")
    print("reason=hardcoded_legacy_builder_not_safe_for_current_lorehold_flow")
    print("next=generate_matrix_then_use_slot_optimizer_with_baseline_hash_guard")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
