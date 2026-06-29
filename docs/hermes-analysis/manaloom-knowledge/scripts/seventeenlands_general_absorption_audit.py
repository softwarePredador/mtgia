#!/usr/bin/env python3
"""Summarize what ManaLoom can safely absorb from a 17Lands replay profile."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


DEFAULT_PROFILE_JSON = Path(
    "docs/hermes-analysis/master_optimizer_reports/"
    "seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json"
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def first_ranked_payload(rows: Any) -> dict[str, Any]:
    if isinstance(rows, list) and rows and isinstance(rows[0], Mapping):
        return dict(rows[0])
    return {}


def build_absorption_audit(profile: Mapping[str, Any], *, profile_path: Path) -> dict[str, Any]:
    summary = profile.get("sample_summary") or {}
    if not isinstance(summary, Mapping):
        summary = {}
    coverage = profile.get("manaloom_signal_coverage") or {}
    if not isinstance(coverage, Mapping):
        coverage = {}
    card_metrics = summary.get("card_observation_metrics") or {}
    if not isinstance(card_metrics, Mapping):
        card_metrics = {}

    battle_ready = bool(coverage.get("battle_prior_ready"))
    score_ready = bool(coverage.get("deckbuilder_access_gate_ready"))
    status = "general_absorption_ready" if battle_ready and score_ready else "needs_more_history"

    absorbed = [
        {
            "component": "seventeenlands_replay_profile.py",
            "contract": "general_signal_coverage",
            "evidence": "profile.manaloom_signal_coverage",
            "status": "implemented",
        },
        {
            "component": "seventeenlands_replay_profile.py",
            "contract": "card_access_vs_use_metrics",
            "evidence": "profile.sample_summary.card_observation_metrics",
            "status": "implemented" if bool(card_metrics) else "missing",
        },
        {
            "component": "seventeenlands_battle_prior_compare.py",
            "contract": "candidate_scoreability_thresholds",
            "evidence": "--min-accessed-games, --min-used-events, --min-trace-count",
            "status": "implemented",
        },
        {
            "component": "battle/deckbuilder methodology",
            "contract": "17lands_is_behavior_prior_not_rules_oracle",
            "evidence": "profile.not_recommended_use",
            "status": "enforced_by_report_boundary",
        },
    ]

    return {
        "absorbed_into_manaloom": absorbed,
        "blocked_uses": list(profile.get("not_recommended_use") or []),
        "card_observation_metric_sample": {
            "top_by_direct_use_first": first_ranked_payload(
                card_metrics.get("top_by_direct_use")
            ),
            "top_by_natural_access_first": first_ranked_payload(
                card_metrics.get("top_by_natural_access")
            ),
            "top_by_total_observations_first": first_ranked_payload(
                card_metrics.get("top_by_total_observations")
            ),
        },
        "generated_at": utc_now(),
        "general_adjustments": list(profile.get("manaloom_general_adjustments") or []),
        "postgres_writes": False,
        "profile_path": str(profile_path),
        "source": profile.get("source"),
        "source_db_mutated": False,
        "source_evidence": {
            "field_count": (profile.get("header") or {}).get("field_count"),
            "max_turn_column": (profile.get("header") or {}).get("max_turn_column"),
            "rows_sampled": profile.get("rows_sampled"),
            "signal_coverage": coverage,
            "turn_behavior_turn_count": len(summary.get("turn_behavior_metrics") or {}),
        },
        "status": status,
    }


def render_markdown(audit: Mapping[str, Any]) -> str:
    lines = [
        "# 17Lands General Absorption Audit",
        "",
        f"- Generated at: `{audit['generated_at']}`",
        f"- Status: `{audit['status']}`",
        f"- Source: `{audit.get('source')}`",
        f"- Profile: `{audit['profile_path']}`",
        f"- PostgreSQL writes: `{audit['postgres_writes']}`",
        f"- Source DB mutated: `{audit['source_db_mutated']}`",
        "",
        "## Source Evidence",
        "",
        f"- `{audit['source_evidence']}`",
        "",
        "## Absorbed Into ManaLoom",
        "",
    ]
    for item in audit["absorbed_into_manaloom"]:
        lines.append(
            f"- {item['component']}: `{item['status']}` - {item['contract']} ({item['evidence']})"
        )
    lines.extend(["", "## General Adjustments", ""])
    for item in audit["general_adjustments"]:
        lines.append(
            f"- {item['area']}: `{item['status']}` - {item['adjustment']}"
        )
    lines.extend(["", "## Card Observation Metric Sample", ""])
    for key, value in audit["card_observation_metric_sample"].items():
        lines.append(f"- {key}: `{value}`")
    lines.extend(["", "## Blocked Uses", ""])
    for item in audit["blocked_uses"]:
        lines.append(f"- {item}")
    lines.append("")
    return "\n".join(lines)


def run(*, profile_path: Path) -> dict[str, Any]:
    profile = load_json(profile_path)
    return build_absorption_audit(profile, profile_path=profile_path)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile-json", type=Path, default=DEFAULT_PROFILE_JSON)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-md", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    audit = run(profile_path=args.profile_json)
    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(stable_json(audit) + "\n", encoding="utf-8")
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(audit), encoding="utf-8")
    if not args.output_json and not args.output_md:
        sys.stdout.write(stable_json(audit) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
