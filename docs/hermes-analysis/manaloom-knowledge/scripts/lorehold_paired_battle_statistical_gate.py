#!/usr/bin/env python3
"""Reject the retired Lorehold paired-seed statistical design.

This compatibility entrypoint exists only so old automation fails with a
machine-readable disposition. XMage and Forge do not expose controllable RNG,
therefore ``paired_per_game_v1``, McNemar, and paired Newcombe results cannot
promote a deck. Use ``lorehold_independent_battle_statistical_gate.py``.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCHEMA_VERSION = "lorehold_historical_paired_design_rejection_v1"
REPLACEMENT = "lorehold_independent_battle_statistical_gate.py"


def build_rejection(*, generated_at: str | None = None) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": generated_at
        or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": "blocked",
        "decision": "reject_historical_candidate_keep_protected_baseline_607",
        "next_gate": "create_new_same_lane_hypothesis_then_run_independent_samples",
        "historical_evidence_only": True,
        "historical_sample_count": 384,
        "historical_candidate_wins": 138,
        "historical_baseline_wins": 95,
        "historical_blockers": [
            "engine_rng_not_controlled_by_seed",
            "paired_seed_design_invalid",
            "timeout_censoring_present",
            "critical_lumra_regression_9_of_32_to_5_of_32",
        ],
        "seed_pairing_claim": False,
        "superiority_proven": False,
        "promotion_allowed": False,
        "automatic_promotion_allowed": False,
        "automatic_mutation_performed": False,
        "baseline_deck_id": 607,
        "baseline_protected": True,
        "replacement": REPLACEMENT,
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    return "\n".join(
        [
            "# Historical Lorehold Paired Design Rejection",
            "",
            f"- status: `{report.get('status')}`",
            f"- decision: `{report.get('decision')}`",
            f"- next_gate: `{report.get('next_gate')}`",
            "- seed_pairing_claim: `false`",
            "- promotion_allowed: `false`",
            "- protected baseline: `deck 607`",
            f"- replacement: `{report.get('replacement')}`",
            "",
            "The 384 historical rows remain descriptive evidence only. Equal seed labels",
            "do not pair XMage or Forge RNG outcomes.",
            "",
            "## Blockers",
            "",
            *(f"- `{value}`" for value in report.get("historical_blockers") or []),
            "",
        ]
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-prefix", type=Path)
    # Accept retired arguments so existing callers get the explicit rejection
    # instead of an ambiguous argparse failure.
    parser.add_argument("--gate", action="append")
    parser.add_argument("--baseline-key")
    parser.add_argument("--candidate-key")
    parser.add_argument("--changes-json")
    parser.add_argument("--expected-source-db-sha256")
    parser.add_argument("--expected-candidate-db-sha256")
    parser.add_argument("--expected-matrix-sha256")
    parser.add_argument("--critical-pattern", action="append")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report = build_rejection()
    if args.out_prefix is not None:
        args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
        args.out_prefix.with_suffix(".json").write_text(
            json.dumps(report, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        args.out_prefix.with_suffix(".md").write_text(
            render_markdown(report),
            encoding="utf-8",
        )
    print(json.dumps(report, indent=2, sort_keys=True))
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
