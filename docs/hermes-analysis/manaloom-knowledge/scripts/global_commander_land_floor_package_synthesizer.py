#!/usr/bin/env python3
"""Synthesize a multi-swap land floor package before candidate copy.

The land floor policy builder can show that a deck needs several more lands.
Materializing only the top single pair leaves the floor unrepaired. This report
zips unique named-land candidates with unique reviewable nonland cuts until the
land gap is covered, then hands that package to the isolated candidate-copy
materializer.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

from global_commander_deck_contract_audit import REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_LAND_FLOOR_POLICY_REPORT = REPORT_DIR / "global_commander_land_floor_policy_builder_20260706_current.json"
DEFAULT_NAMED_LAND_POOL_REPORT = (
    REPORT_DIR / "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.json"
)
DEFAULT_LAND_CUT_MODEL_REPORT = (
    REPORT_DIR / "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_land_floor_package_synthesizer_20260706_deck612"

READY_STATUS = "land_floor_package_synthesized_candidate_copy_ready"
BLOCKED_STATUS = "land_floor_package_blocks_insufficient_unique_pairs"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def by_deck(rows: list[Mapping[str, Any]]) -> dict[str, Mapping[str, Any]]:
    return {str(row.get("deck_id")): row for row in rows if row.get("deck_id") is not None}


def first_ready_land_floor_deck(payload: Mapping[str, Any], deck_id: str | None = None) -> Mapping[str, Any]:
    rows = [
        row
        for row in payload.get("deck_policy_rows") or []
        if str(row.get("status") or "") == "land_floor_policy_ready_for_pair_preflight_no_deck_action"
    ]
    if deck_id:
        rows = [row for row in rows if str(row.get("deck_id")) == str(deck_id)]
    if not rows:
        raise RuntimeError("no ready land floor policy deck found")
    return rows[0]


def unique_cards(rows: list[Mapping[str, Any]], name_key: str) -> list[Mapping[str, Any]]:
    seen: set[str] = set()
    result: list[Mapping[str, Any]] = []
    for row in rows:
        name = str(row.get(name_key) or "")
        key = normalize_name(name)
        if not key or key in seen:
            continue
        seen.add(key)
        result.append(row)
    return result


def synthesize_pairs(
    *,
    floor_row: Mapping[str, Any],
    named_land_pool: Mapping[str, Any],
    cut_pool: Mapping[str, Any],
) -> list[dict[str, Any]]:
    gap = max(0, as_int(floor_row.get("target_land_floor")) - as_int(floor_row.get("current_land_count")))
    lands = unique_cards(list(named_land_pool.get("top_candidates") or []), "card_name")
    cuts = unique_cards(list(cut_pool.get("top_cut_candidates") or []), "card_name")
    pairs: list[dict[str, Any]] = []
    for land, cut in zip(lands[:gap], cuts[:gap]):
        pairs.append(
            {
                "add": land.get("card_name"),
                "cut": cut.get("card_name"),
                "role": "land",
                "add_score": as_int(land.get("score")),
                "cut_score": as_int(cut.get("score")),
                "pair_score": as_int(land.get("score")) + as_int(cut.get("score")),
                "add_status": land.get("status"),
                "cut_status": cut.get("status"),
                "cut_roles": list(cut.get("roles") or []),
                "mutation_allowed": False,
            }
        )
    return pairs


def build_report(
    *,
    land_floor_policy_payload: dict[str, Any],
    named_land_pool_payload: dict[str, Any],
    land_cut_model_payload: dict[str, Any],
    deck_id: str | None = None,
    land_floor_policy_report_path: Path = DEFAULT_LAND_FLOOR_POLICY_REPORT,
    named_land_pool_report_path: Path = DEFAULT_NAMED_LAND_POOL_REPORT,
    land_cut_model_report_path: Path = DEFAULT_LAND_CUT_MODEL_REPORT,
) -> dict[str, Any]:
    floor_row = first_ready_land_floor_deck(land_floor_policy_payload, deck_id=deck_id)
    selected_deck_id = str(floor_row.get("deck_id") or "")
    named_by_deck = by_deck(list(named_land_pool_payload.get("candidate_pools") or []))
    cut_by_deck = by_deck(list(land_cut_model_payload.get("deck_cut_pools") or []))
    named_pool = named_by_deck.get(selected_deck_id) or {}
    cut_pool = cut_by_deck.get(selected_deck_id) or {}
    gap = max(0, as_int(floor_row.get("target_land_floor")) - as_int(floor_row.get("current_land_count")))
    pairs = synthesize_pairs(floor_row=floor_row, named_land_pool=named_pool, cut_pool=cut_pool)
    status = READY_STATUS if gap > 0 and len(pairs) >= gap else BLOCKED_STATUS
    candidate_copy_allowed_now = status == READY_STATUS
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_land_floor_package_synthesizer",
        "status": status,
        "input_artifacts": {
            "land_floor_policy_report": rel(land_floor_policy_report_path),
            "named_land_pool_report": rel(named_land_pool_report_path),
            "land_cut_model_report": rel(land_cut_model_report_path),
        },
        "source_db": land_cut_model_payload.get("source_db"),
        "mutation_allowed": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": candidate_copy_allowed_now,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "summary": {
            "deck_id": selected_deck_id,
            "deck_name": floor_row.get("deck_name"),
            "commander": floor_row.get("commander"),
            "current_land_count": as_int(floor_row.get("current_land_count")),
            "target_land_floor": as_int(floor_row.get("target_land_floor")),
            "land_gap": gap,
            "selected_pair_count": len(pairs),
            "available_named_land_count": len(named_pool.get("top_candidates") or []),
            "available_cut_count": len(cut_pool.get("top_cut_candidates") or []),
            "candidate_copy_allowed_now": candidate_copy_allowed_now,
            "next_gate": (
                "materialize_land_floor_package_candidate_copy"
                if candidate_copy_allowed_now
                else "expand_named_land_or_cut_pool_before_land_floor_candidate_copy"
            ),
        },
        "pairs": pairs,
        "candidate_copy_blockers": []
        if candidate_copy_allowed_now
        else ["insufficient_unique_named_lands_or_cuts_to_cover_land_floor_gap"],
        "policy": {
            "package_boundary": "This is a review-only land-floor package for isolated candidate copy.",
            "floor_boundary": "The package must cover the full land gap; single swaps are blocked when the floor remains unrepaired.",
            "battle_boundary": "Battle gate and promotion stay closed after materialization until core, strategy, battle, and replay gates pass.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Land Floor Package Synthesizer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- commander: `{summary['commander']}`",
        f"- current_land_count: `{summary['current_land_count']}`",
        f"- target_land_floor: `{summary['target_land_floor']}`",
        f"- land_gap: `{summary['land_gap']}`",
        f"- selected_pair_count: `{summary['selected_pair_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Package Pairs",
        "",
        "| # | Add Land | Cut | Pair Score | Cut Roles |",
        "| ---: | --- | --- | ---: | --- |",
    ]
    for index, pair in enumerate(payload.get("pairs") or [], start=1):
        lines.append(
            "| {index} | `{add}` | `{cut}` | {score} | `{roles}` |".format(
                index=index,
                add=pair.get("add"),
                cut=pair.get("cut"),
                score=pair.get("pair_score"),
                roles=",".join(pair.get("cut_roles") or []),
            )
        )
    if not payload.get("pairs"):
        lines.append("|  | none | none | 0 | - |")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    if not payload["candidate_copy_blockers"]:
        lines.append("- none")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--land-floor-policy-report", type=Path, default=DEFAULT_LAND_FLOOR_POLICY_REPORT)
    parser.add_argument("--named-land-pool-report", type=Path, default=DEFAULT_NAMED_LAND_POOL_REPORT)
    parser.add_argument("--land-cut-model-report", type=Path, default=DEFAULT_LAND_CUT_MODEL_REPORT)
    parser.add_argument("--deck-id")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        land_floor_policy_payload=load_json(args.land_floor_policy_report),
        named_land_pool_payload=load_json(args.named_land_pool_report),
        land_cut_model_payload=load_json(args.land_cut_model_report),
        deck_id=args.deck_id,
        land_floor_policy_report_path=args.land_floor_policy_report,
        named_land_pool_report_path=args.named_land_pool_report,
        land_cut_model_report_path=args.land_cut_model_report,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0 if payload["candidate_copy_allowed_now"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
