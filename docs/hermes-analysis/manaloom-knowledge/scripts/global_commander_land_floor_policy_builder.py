#!/usr/bin/env python3
"""Calibrate global Commander land floor policy before candidate copy.

This report follows ``global_commander_role_axis_policy_builder`` when the
selected non-exhausted axis is ``land``. It joins the existing mana-base profile,
named land pool, and land add/cut model so the next action is a bounded preflight
queue, not an implicit deck mutation.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_ROLE_AXIS_POLICY_REPORT = (
    REPORT_DIR / "global_commander_role_axis_policy_builder_20260706_post_ramp_axis_exhaustion_current.json"
)
DEFAULT_MANA_BASE_PROFILE_REPORT = (
    REPORT_DIR / "global_commander_mana_base_profile_20260705_global_goal_hermes_only.json"
)
DEFAULT_NAMED_LAND_POOL_REPORT = (
    REPORT_DIR / "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.json"
)
DEFAULT_LAND_CUT_MODEL_REPORT = (
    REPORT_DIR / "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.json"
)
DEFAULT_BATTLE_FEEDBACK_REPORT = (
    REPORT_DIR / "global_commander_battle_feedback_model_20260706_larger_gate_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_land_floor_policy_builder_20260706_current"

LAND_POLICY_READY_STATUS = "land_floor_policy_ready_for_pair_preflight_no_deck_action"
LAND_POLICY_BLOCKED_STATUS = "land_floor_policy_blocks_until_inputs_ready"
BATTLE_FEEDBACK_BLOCKED_STATUS = "blocked_by_protected_baseline_package_feedback"
BATTLE_FEEDBACK_NEXT_GATE = "replace_failed_package_source_lane_or_cut_set_before_land_floor_preflight"
EXPECTED_LAND_AXIS_GATE = "calibrate_land_floor_policy_before_candidate_copy"


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


def normalized_card_set(cards: object) -> set[str]:
    if not isinstance(cards, list):
        return set()
    return {str(card or "").strip().casefold() for card in cards if str(card or "").strip()}


def blocked_package_feedback_by_deck(
    battle_feedback_payload: Mapping[str, Any] | None,
) -> dict[str, list[dict[str, Any]]]:
    blocked: dict[str, list[dict[str, Any]]] = {}
    if not battle_feedback_payload:
        return blocked
    for row in battle_feedback_payload.get("package_feedback") or []:
        if not isinstance(row, Mapping):
            continue
        if str(row.get("package_status") or "") != "package_blocked_by_protected_baseline_gate":
            continue
        deck_id = str(row.get("deck_id") or "")
        if not deck_id:
            continue
        evidence = row.get("primary_evidence") if isinstance(row.get("primary_evidence"), Mapping) else {}
        blocked.setdefault(deck_id, []).append(
            {
                "package_status": row.get("package_status"),
                "recommendation": row.get("recommendation"),
                "added_cards": list(row.get("added_cards") or []),
                "cut_cards": list(row.get("cut_cards") or []),
                "added_card_keys": normalized_card_set(row.get("added_cards")),
                "cut_card_keys": normalized_card_set(row.get("cut_cards")),
                "artifact_path": evidence.get("artifact_path"),
                "classification": evidence.get("classification"),
                "candidate_vs_immediate_base_win_delta": evidence.get("candidate_vs_immediate_base_win_delta"),
                "candidate_vs_protected_win_delta": evidence.get("candidate_vs_protected_win_delta"),
                "protected_baseline_key": evidence.get("protected_baseline_key"),
            }
        )
    return blocked


def blocked_feedback_for_pair(
    *,
    deck_id: str,
    pair: Mapping[str, Any] | None,
    blocked_feedback: Mapping[str, list[dict[str, Any]]],
) -> dict[str, Any] | None:
    if not pair:
        return None
    add_key = str(pair.get("add") or "").strip().casefold()
    cut_key = str(pair.get("cut") or "").strip().casefold()
    if not add_key or not cut_key:
        return None
    for feedback in blocked_feedback.get(deck_id, []):
        if add_key in feedback.get("added_card_keys", set()) and cut_key in feedback.get("cut_card_keys", set()):
            return {key: value for key, value in feedback.items() if not key.endswith("_keys")}
    return None


def land_axis_policy_row(role_axis_policy_payload: Mapping[str, Any]) -> Mapping[str, Any] | None:
    for row in role_axis_policy_payload.get("axis_policy_rows") or []:
        if str(row.get("role") or "") == "land":
            return row
    return None


def policy_allows_land_floor(role_axis_policy_payload: Mapping[str, Any]) -> bool:
    summary = role_axis_policy_payload.get("summary") or {}
    return (
        str(summary.get("top_policy_role") or "") == "land"
        and str(summary.get("top_policy_status") or "") == "role_axis_policy_ready_for_floor_calibration"
        and str(summary.get("next_gate") or "") == EXPECTED_LAND_AXIS_GATE
    )


def best_pair(pool: Mapping[str, Any]) -> Mapping[str, Any] | None:
    pairs = list(pool.get("pair_hypotheses") or [])
    if not pairs:
        return None
    return sorted(
        pairs,
        key=lambda row: (-as_int(row.get("pair_score")), str(row.get("add") or ""), str(row.get("cut") or "")),
    )[0]


def deck_policy_status(
    *,
    role_axis_policy_payload: Mapping[str, Any],
    profile: Mapping[str, Any] | None,
    candidate_pool: Mapping[str, Any] | None,
    cut_pool: Mapping[str, Any] | None,
) -> str:
    if not policy_allows_land_floor(role_axis_policy_payload):
        return "blocked_role_axis_policy_not_land_floor"
    if not profile:
        return "blocked_missing_mana_profile"
    if str(profile.get("status") or "") != "mana_profile_ready_for_named_land_candidate_pool":
        return "blocked_mana_profile_not_ready"
    if not candidate_pool or not (candidate_pool.get("top_candidates") or []):
        return "blocked_no_named_land_candidates"
    if not cut_pool or str(cut_pool.get("status") or "") != "review_cut_pool_ready":
        return "blocked_no_reviewable_land_cut_pool"
    if not best_pair(cut_pool):
        return "blocked_no_reviewable_land_add_cut_pair"
    return LAND_POLICY_READY_STATUS


def build_deck_policy_rows(
    *,
    role_axis_policy_payload: Mapping[str, Any],
    mana_profile_payload: Mapping[str, Any],
    named_land_pool_payload: Mapping[str, Any],
    land_cut_model_payload: Mapping[str, Any],
    battle_feedback_payload: Mapping[str, Any] | None = None,
) -> list[dict[str, Any]]:
    profiles = by_deck(list(mana_profile_payload.get("profiles") or []))
    candidate_pools = by_deck(list(named_land_pool_payload.get("candidate_pools") or []))
    cut_pools = by_deck(list(land_cut_model_payload.get("deck_cut_pools") or []))
    blocked_feedback = blocked_package_feedback_by_deck(battle_feedback_payload)
    deck_ids = sorted(set(profiles) | set(candidate_pools) | set(cut_pools))
    rows: list[dict[str, Any]] = []
    for deck_id in deck_ids:
        profile = profiles.get(deck_id)
        candidate_pool = candidate_pools.get(deck_id)
        cut_pool = cut_pools.get(deck_id)
        pair = best_pair(cut_pool or {})
        status = deck_policy_status(
            role_axis_policy_payload=role_axis_policy_payload,
            profile=profile,
            candidate_pool=candidate_pool,
            cut_pool=cut_pool,
        )
        battle_feedback = None
        if status == LAND_POLICY_READY_STATUS:
            battle_feedback = blocked_feedback_for_pair(
                deck_id=deck_id,
                pair=pair,
                blocked_feedback=blocked_feedback,
            )
            if battle_feedback:
                status = BATTLE_FEEDBACK_BLOCKED_STATUS
        land_gap = as_int((profile or {}).get("land_gap"))
        row = {
            "deck_id": deck_id,
            "deck_name": (profile or candidate_pool or cut_pool or {}).get("deck_name"),
            "commander": (profile or candidate_pool or cut_pool or {}).get("commander"),
            "status": status,
            "current_land_count": as_int((profile or {}).get("current_land_count")),
            "target_land_floor": as_int((profile or {}).get("target_land_floor")),
            "land_gap": land_gap,
            "recommended_land_classes": list((profile or {}).get("recommended_land_classes") or []),
            "named_land_candidate_count": as_int((candidate_pool or {}).get("candidate_count")),
            "cut_candidate_count": as_int((cut_pool or {}).get("cut_candidate_count")),
            "pair_hypothesis_count": len((cut_pool or {}).get("pair_hypotheses") or []),
            "top_pair": dict(pair) if pair else None,
            "preflight_score": land_gap * 100 + as_int((pair or {}).get("pair_score")),
            "battle_feedback": battle_feedback,
            "candidate_copy_allowed": False,
            "battle_gate_allowed": False,
            "promotion_allowed": False,
            "mutation_allowed": False,
            "next_gate": (
                "run_candidate_copy_materializer_for_land_floor_pair_after_commander_source_lane"
                if status == LAND_POLICY_READY_STATUS
                else (
                    BATTLE_FEEDBACK_NEXT_GATE
                    if status == BATTLE_FEEDBACK_BLOCKED_STATUS
                    else "repair_land_floor_policy_inputs_before_candidate_copy"
                )
            ),
        }
        rows.append(row)
    rows.sort(
        key=lambda row: (
            row["status"] != LAND_POLICY_READY_STATUS,
            -as_int(row.get("preflight_score")),
            str(row.get("commander") or ""),
            str(row.get("deck_id") or ""),
        )
    )
    return rows


def choose_status(deck_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if not deck_rows:
        return ("land_floor_policy_blocks_no_decks", "rerun_mana_base_profile_and_land_candidate_pool")
    if any(row.get("status") == LAND_POLICY_READY_STATUS for row in deck_rows):
        return ("land_floor_policy_ready_no_deck_action", str(deck_rows[0].get("next_gate") or ""))
    return (LAND_POLICY_BLOCKED_STATUS, str(deck_rows[0].get("next_gate") or ""))


def build_report(
    *,
    role_axis_policy_payload: dict[str, Any],
    mana_profile_payload: dict[str, Any],
    named_land_pool_payload: dict[str, Any],
    land_cut_model_payload: dict[str, Any],
    battle_feedback_payload: dict[str, Any] | None = None,
    role_axis_policy_report_path: Path = DEFAULT_ROLE_AXIS_POLICY_REPORT,
    mana_profile_report_path: Path = DEFAULT_MANA_BASE_PROFILE_REPORT,
    named_land_pool_report_path: Path = DEFAULT_NAMED_LAND_POOL_REPORT,
    land_cut_model_report_path: Path = DEFAULT_LAND_CUT_MODEL_REPORT,
    battle_feedback_report_path: Path = DEFAULT_BATTLE_FEEDBACK_REPORT,
) -> dict[str, Any]:
    land_axis = land_axis_policy_row(role_axis_policy_payload)
    deck_rows = build_deck_policy_rows(
        role_axis_policy_payload=role_axis_policy_payload,
        mana_profile_payload=mana_profile_payload,
        named_land_pool_payload=named_land_pool_payload,
        land_cut_model_payload=land_cut_model_payload,
        battle_feedback_payload=battle_feedback_payload,
    )
    status, next_gate = choose_status(deck_rows)
    status_counts = Counter(str(row.get("status") or "unknown") for row in deck_rows)
    ready_rows = [row for row in deck_rows if row.get("status") == LAND_POLICY_READY_STATUS]
    battle_feedback_blocked_rows = [row for row in deck_rows if row.get("status") == BATTLE_FEEDBACK_BLOCKED_STATUS]
    top = deck_rows[0] if deck_rows else {}
    candidate_copy_blockers = [
        "land_floor_policy_is_not_materialization_permission",
        "candidate_copy_requires_isolated_db_materializer_and_commander_source_lane",
        "structure_and_legality_recheck_required_after_any_copy",
        "strategy_matrix_battle_gate_and_replay_trace_remain_closed",
        "deck_607_is_benchmark_evidence_only_not_global_template",
    ]
    if battle_feedback_blocked_rows:
        candidate_copy_blockers.append("battle_feedback_blocked_land_preflight_requires_new_source_lane_or_cut_set")
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_land_floor_policy_builder",
        "status": status,
        "input_artifacts": {
            "role_axis_policy_report": rel(role_axis_policy_report_path),
            "mana_base_profile_report": rel(mana_profile_report_path),
            "named_land_pool_report": rel(named_land_pool_report_path),
            "land_cut_model_report": rel(land_cut_model_report_path),
            "battle_feedback_report": rel(battle_feedback_report_path),
        },
        "mutation_allowed": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "summary": {
            "land_axis_policy_status": (land_axis or {}).get("status", "missing"),
            "land_axis_policy_next_gate": (land_axis or {}).get("next_gate", "missing"),
            "deck_policy_count": len(deck_rows),
            "ready_pair_preflight_deck_count": len(ready_rows),
            "battle_feedback_blocked_land_preflight_count": len(battle_feedback_blocked_rows),
            "blocked_deck_count": len(deck_rows) - len(ready_rows),
            "status_counts": dict(sorted(status_counts.items())),
            "top_deck_id": top.get("deck_id", ""),
            "top_commander": top.get("commander", ""),
            "top_land_gap": top.get("land_gap", 0),
            "top_pair_add": (top.get("top_pair") or {}).get("add", ""),
            "top_pair_cut": (top.get("top_pair") or {}).get("cut", ""),
            "candidate_copy_allowed_count": 0,
            "battle_gate_allowed_count": 0,
            "next_gate": next_gate,
        },
        "deck_policy_rows": deck_rows,
        "candidate_copy_blockers": candidate_copy_blockers,
        "policy": {
            "land_floor_boundary": "This report calibrates land floor priority and pair preflight only; it does not copy, mutate, battle, or promote decks.",
            "source_boundary": "Named land candidates and cuts are inherited from prior review-only reports and remain hypotheses.",
            "floor_boundary": "Land additions must repair actual land quantity or color access gaps and must cut nonland spell slots.",
            "battle_boundary": "Battle gates stay closed until an isolated candidate copy is structurally rechecked and the added land/cut decision has trace evidence.",
            "feedback_boundary": "A land-floor add/cut pair that belongs to a package blocked by protected-baseline battle feedback must change source lane, cut set, or strategy before re-entering preflight.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Land Floor Policy Builder",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- deck_policy_count: `{summary['deck_policy_count']}`",
        f"- ready_pair_preflight_deck_count: `{summary['ready_pair_preflight_deck_count']}`",
        f"- battle_feedback_blocked_land_preflight_count: `{summary['battle_feedback_blocked_land_preflight_count']}`",
        f"- blocked_deck_count: `{summary['blocked_deck_count']}`",
        f"- top_deck_id: `{summary['top_deck_id']}`",
        f"- top_commander: `{summary['top_commander']}`",
        f"- top_land_gap: `{summary['top_land_gap']}`",
        f"- top_pair_add: `{summary['top_pair_add']}`",
        f"- top_pair_cut: `{summary['top_pair_cut']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Deck Policy Queue",
        "",
        "| Deck | Commander | Status | Land Gap | Current/Floor | Candidates | Pairs | Top Add | Top Cut | Next Gate |",
        "| --- | --- | --- | ---: | --- | ---: | ---: | --- | --- | --- |",
    ]
    for row in payload["deck_policy_rows"]:
        pair = row.get("top_pair") or {}
        lines.append(
            "| `{deck}` | `{commander}` | `{status}` | {gap} | `{current}/{floor}` | {candidates} | {pairs} | `{add}` | `{cut}` | `{next}` |".format(
                deck=f"{row.get('deck_name')} ({row.get('deck_id')})".replace("|", "/"),
                commander=str(row.get("commander") or "").replace("|", "/"),
                status=row.get("status"),
                gap=row.get("land_gap"),
                current=row.get("current_land_count"),
                floor=row.get("target_land_floor"),
                candidates=row.get("named_land_candidate_count"),
                pairs=row.get("pair_hypothesis_count"),
                add=pair.get("add", "-"),
                cut=pair.get("cut", "-"),
                next=row.get("next_gate"),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--role-axis-policy-report", type=Path, default=DEFAULT_ROLE_AXIS_POLICY_REPORT)
    parser.add_argument("--mana-base-profile-report", type=Path, default=DEFAULT_MANA_BASE_PROFILE_REPORT)
    parser.add_argument("--named-land-pool-report", type=Path, default=DEFAULT_NAMED_LAND_POOL_REPORT)
    parser.add_argument("--land-cut-model-report", type=Path, default=DEFAULT_LAND_CUT_MODEL_REPORT)
    parser.add_argument("--battle-feedback-report", type=Path, default=DEFAULT_BATTLE_FEEDBACK_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()

    payload = build_report(
        role_axis_policy_payload=load_json(args.role_axis_policy_report),
        mana_profile_payload=load_json(args.mana_base_profile_report),
        named_land_pool_payload=load_json(args.named_land_pool_report),
        land_cut_model_payload=load_json(args.land_cut_model_report),
        battle_feedback_payload=load_json(args.battle_feedback_report),
        role_axis_policy_report_path=args.role_axis_policy_report,
        mana_profile_report_path=args.mana_base_profile_report,
        named_land_pool_report_path=args.named_land_pool_report,
        land_cut_model_report_path=args.land_cut_model_report,
        battle_feedback_report_path=args.battle_feedback_report,
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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
