#!/usr/bin/env python3
"""Build a blocked sidecar candidate queue for Lorehold topdeck learning.

This queue turns the value-model hypotheses into matrix-ready intent rows. A
row is only eligible for the structure matrix if it has a safe same-lane cut and
is not blocked by prior evidence. Current 607 data is expected to produce zero
eligible rows; that is a useful result, because it keeps sidecar learning honest
without materializing a deck.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_POST_SAFE_CUT_ROUTE = (
    REPORT_DIR / "lorehold_topdeck_post_safe_cut_route_20260705_current.json"
)
DEFAULT_HYPOTHESIS_QUEUE = (
    REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json"
)
DEFAULT_STRUCTURE_MATRIX = (
    REPORT_DIR / "lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.json"
)
DEFAULT_SAFE_CUT_MINER = REPORT_DIR / "lorehold_topdeck_safe_cut_miner_20260705_current.json"
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_sidecar_candidate_queue_20260705_current"

TOPDECK_PRIMARY_TARGETS = {
    "penance",
    "galvanoth",
    "dragon's rage channeler",
    "valakut awakening // valakut stoneforge",
    "wheel of fortune",
}

GENERIC_STAPLE_WATCHLIST = {
    "mana vault": {
        "lane": "early_mana_and_spell_chain_conversion",
        "reason": "fast mana is valuable, but 607 has no safe cut and prior evidence blocks retest.",
    },
    "the one ring": {
        "lane": "draw_and_resource_density",
        "reason": "generic draw is valuable, but it must prove it helps Lorehold's miracle/topdeck floor.",
    },
}

LANE_ORDER = {
    "topdeck_miracle_setup": 0,
    "mana_base_review": 10,
    "protection_window": 20,
    "spell_chain_conversion": 30,
    "interaction_pressure": 40,
    "combo_finishers": 50,
    "tutors_access": 60,
    "unclassified_variant_watchlist": 80,
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_dict(value: Any) -> dict[str, Any]:
    return dict(value) if isinstance(value, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def normalize_name(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().replace("’", "'").split())


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def priority_bucket(priority: str) -> int:
    if priority.startswith("P1_safe_cut"):
        return 0
    if priority.startswith("P1_forced"):
        return 1
    if priority.startswith("P2"):
        return 2
    if priority.startswith("P3"):
        return 3
    return 9


def lane_rank(lanes: list[Any], tag: str) -> int:
    normalized = [str(lane) for lane in lanes if str(lane)]
    if tag == "topdeck_access_sidecar_primary":
        return -10
    if not normalized:
        return 99
    return min(LANE_ORDER.get(lane, 90) for lane in normalized)


def sidecar_tag(card_name: str, row: Mapping[str, Any]) -> str:
    name = normalize_name(card_name)
    lanes = set(str(lane) for lane in as_list(row.get("hypothesis_lanes")))
    if name in TOPDECK_PRIMARY_TARGETS:
        return "topdeck_access_sidecar_primary"
    if name in GENERIC_STAPLE_WATCHLIST:
        return "generic_staple_learning_only"
    if "mana_base_review" in lanes or str(row.get("example_functional_tag") or "") == "land":
        return "mana_base_safe_cut_model"
    if "protection_window" in lanes:
        return "pressure_window_after_topdeck_floor"
    if "spell_chain_conversion" in lanes:
        return "spell_chain_after_miracle_floor"
    if "tutors_access" in lanes:
        return "tutor_learning_only_after_prior_reject"
    return "sidecar_watchlist"


def proposed_cut(row: Mapping[str, Any]) -> str:
    for key in ("proposed_cut_card", "same_lane_cut_card", "cut_card"):
        if row.get(key):
            return str(row[key])
    cuts = as_list(row.get("proposed_cuts"))
    return str(cuts[0]) if cuts else ""


def row_blockers(row: Mapping[str, Any], tag: str) -> list[str]:
    blockers: list[str] = []
    readiness = str(row.get("readiness_status") or "")
    cut = proposed_cut(row)
    if readiness in {"blocked_prior_reject", "prior_reject"}:
        blockers.append("prior_reject_requires_new_trace_hypothesis")
    if readiness not in {"safe_cut_ready", "seed_safe_cut_ready", "candidate_row_ready"}:
        blockers.append("needs_safe_cut_model")
    if not cut:
        blockers.append("missing_named_same_lane_cut")
    if tag == "generic_staple_learning_only":
        blockers.append("generic_staple_not_lorehold_specific_until_trace_proof")
    if tag in {"pressure_window_after_topdeck_floor", "spell_chain_after_miracle_floor"}:
        blockers.append("must_follow_topdeck_miracle_floor")
    return sorted(set(blockers))


def queue_row(row: Mapping[str, Any]) -> dict[str, Any]:
    card_name = str(row.get("card_name") or "")
    tag = sidecar_tag(card_name, row)
    blockers = row_blockers(row, tag)
    eligible = not blockers
    generic_policy = GENERIC_STAPLE_WATCHLIST.get(normalize_name(card_name), {})
    return {
        "candidate_key": "sidecar_" + normalize_name(card_name).replace(" ", "_").replace("/", "_"),
        "add_card": card_name,
        "cut_card": proposed_cut(row),
        "lane": ",".join(as_list(row.get("hypothesis_lanes"))) or str(row.get("example_functional_tag") or ""),
        "sidecar_tag": tag,
        "priority": row.get("priority") or "",
        "readiness_status": row.get("readiness_status") or "",
        "allowed_next_test": row.get("allowed_next_test") or "",
        "matrix_candidate_row_eligible_now": eligible,
        "candidate_deck_materialization_allowed_now": False,
        "forced_access_allowed_now": False,
        "natural_gate_allowed_now": False,
        "promotion_allowed_now": False,
        "blockers": blockers,
        "same_lane_cut_reason": (
            "named same-lane cut present"
            if proposed_cut(row)
            else "no named same-lane cut present"
        ),
        "protected_anchor_impact": "must_preserve_or_prove_same_lane_replacement",
        "expected_metric_lift": expected_metric_lift(tag),
        "rule_runtime_status": "requires_xmage_runtime_trace_before_materialization",
        "source_provenance": "lorehold_hypothesis_queue_from_value_model",
        "floor_risk": floor_risk(tag),
        "generic_staple_policy": generic_policy,
    }


def expected_metric_lift(tag: str) -> str:
    if tag == "topdeck_access_sidecar_primary":
        return "miracle_cast_and_topdeck_manipulation_floor_lift"
    if tag == "mana_base_safe_cut_model":
        return "mana_base_consistency_without_reducing_opponent_turn_mana"
    if tag == "pressure_window_after_topdeck_floor":
        return "fast_pressure_survival_after_miracle_floor_preserved"
    if tag == "generic_staple_learning_only":
        return "resource_density_only_if_trace_links_to_lorehold_floor"
    return "learning_signal_only_until_floor_defined"


def floor_risk(tag: str) -> str:
    if tag == "topdeck_access_sidecar_primary":
        return "can_improve_visibility_but_still_regress_win_conversion"
    if tag == "mana_base_safe_cut_model":
        return "land_swap_can_reduce_anchor_access_or_spell_density"
    if tag == "generic_staple_learning_only":
        return "generic_power_can_hide_lorehold_engine_regression"
    if tag == "pressure_window_after_topdeck_floor":
        return "protection_can_be_dead_if_topdeck_floor_stalls"
    return "unknown_until_trace_hypothesis_declared"


def queue_rows(hypothesis_queue: Mapping[str, Any], limit: int) -> list[dict[str, Any]]:
    rows = [
        queue_row(row)
        for row in as_list(hypothesis_queue.get("hypotheses"))
        if isinstance(row, Mapping) and row.get("card_name")
    ]
    rows.sort(
        key=lambda row: (
            priority_bucket(str(row.get("priority") or "")),
            lane_rank(str(row.get("lane") or "").split(","), str(row.get("sidecar_tag") or "")),
            0 if row.get("matrix_candidate_row_eligible_now") else 1,
            str(row.get("add_card") or ""),
        )
    )
    return rows[: max(1, limit)]


def input_health(payloads: Mapping[str, Mapping[str, Any]]) -> dict[str, Any]:
    missing = [key for key, payload in payloads.items() if not payload]
    return {
        "missing_inputs": missing,
        "all_required_inputs_present": not missing,
    }


def build_report(
    *,
    post_safe_cut_route: Mapping[str, Any],
    hypothesis_queue: Mapping[str, Any],
    structure_matrix: Mapping[str, Any],
    safe_cut_miner: Mapping[str, Any],
    value_model: Mapping[str, Any],
    paths: Mapping[str, Path],
    limit: int = 40,
) -> dict[str, Any]:
    payloads = {
        "post_safe_cut_route": post_safe_cut_route,
        "hypothesis_queue": hypothesis_queue,
        "structure_matrix": structure_matrix,
        "safe_cut_miner": safe_cut_miner,
        "value_model": value_model,
    }
    health = input_health(payloads)
    rows = queue_rows(hypothesis_queue, limit=limit) if not health["missing_inputs"] else []
    eligible_rows = [row for row in rows if row.get("matrix_candidate_row_eligible_now")]
    tag_counts = Counter(str(row.get("sidecar_tag") or "") for row in rows)
    readiness_counts = Counter(str(row.get("readiness_status") or "") for row in rows)
    blocker_counts = Counter(blocker for row in rows for blocker in as_list(row.get("blockers")))
    safe_summary = summary(safe_cut_miner)
    route_summary = summary(post_safe_cut_route)
    matrix_summary = summary(structure_matrix)
    value_summary = summary(value_model)
    status = (
        "topdeck_sidecar_candidate_queue_inputs_missing_keep_607"
        if health["missing_inputs"]
        else "topdeck_sidecar_candidate_queue_blocked_no_matrix_rows_keep_607"
    )
    if eligible_rows:
        status = "topdeck_sidecar_candidate_queue_has_matrix_rows_no_deck_materialization"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_sidecar_candidate_queue",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "queue_row_count": len(rows),
            "matrix_candidate_row_eligible_count": len(eligible_rows),
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "post_safe_cut_selected_route": route_summary.get("selected_route") or "",
            "safe_cut_seed_ready_count": as_int(safe_summary.get("seed_safe_cut_candidate_count")),
            "safe_cut_reviewable_count": as_int(safe_summary.get("reviewable_same_lane_gap_count")),
            "structure_matrix_scoring_allowed_now": bool(matrix_summary.get("matrix_scoring_allowed_now")),
            "value_model_land_quantity": as_int(
                as_dict(value_summary.get("mana_foundation")).get("land_quantity")
            ),
            "value_model_ramp_quantity": as_int(
                as_dict(value_summary.get("mana_foundation")).get("ramp_quantity")
            ),
            "tag_counts": dict(sorted(tag_counts.items())),
            "readiness_counts": dict(sorted(readiness_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "missing_inputs": as_list(health.get("missing_inputs")),
            "recommended_next_action": (
                "build_named_same_lane_cut_models_for_topdeck_and_mana_rows_before_matrix_scoring"
                if not eligible_rows
                else "feed_eligible_rows_to_structure_matrix_scoring_no_battle"
            ),
        },
        "candidate_queue": rows,
        "matrix_candidate_rows": [
            {
                key: row.get(key)
                for key in (
                    "candidate_key",
                    "add_card",
                    "cut_card",
                    "lane",
                    "same_lane_cut_reason",
                    "protected_anchor_impact",
                    "expected_metric_lift",
                    "rule_runtime_status",
                    "source_provenance",
                    "floor_risk",
                )
            }
            for row in eligible_rows
        ],
        "source_evidence": {
            "post_safe_cut_route_summary": route_summary,
            "hypothesis_queue_summary": summary(hypothesis_queue),
            "structure_matrix_summary": matrix_summary,
            "safe_cut_summary": safe_summary,
            "value_model_summary": value_summary,
            "input_health": health,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "matrix_candidate_rows_ready": bool(eligible_rows),
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The queue has learning rows, but no current row has the named "
                "same-lane cut and floor proof required by the structure matrix."
            )
            if not eligible_rows
            else (
                "Some rows have matrix shape, but materialization and battle remain "
                "closed until matrix scoring and trace floors pass."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_a_sidecar_deck_from_blocked_rows",
                "mine named same-lane cuts for topdeck and mana rows first",
                "keep Mana Vault and The One Ring as learning-only until new trace and cut proof exist",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Sidecar Candidate Queue",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Queue rows: `{summary_row['queue_row_count']}`",
        f"- Matrix candidate rows eligible: `{summary_row['matrix_candidate_row_eligible_count']}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row['candidate_deck_materialization_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Promotion allowed now: `{str(summary_row['promotion_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Queue Summary", ""])
    lines.append(f"- tag_counts: `{json.dumps(summary_row.get('tag_counts') or {}, sort_keys=True)}`")
    lines.append(
        f"- readiness_counts: `{json.dumps(summary_row.get('readiness_counts') or {}, sort_keys=True)}`"
    )
    lines.append(f"- blocker_counts: `{json.dumps(summary_row.get('blocker_counts') or {}, sort_keys=True)}`")
    lines.extend(["", "## Candidate Queue", ""])
    lines.append("| Card | Tag | Priority | Eligible | Blockers | Next test |")
    lines.append("| --- | --- | --- | ---: | --- | --- |")
    for row in as_list(payload.get("candidate_queue")):
        blockers = ", ".join(as_list(row.get("blockers"))[:4])
        lines.append(
            "| {card} | `{tag}` | `{priority}` | `{eligible}` | `{blockers}` | `{next}` |".format(
                card=row.get("add_card") or "",
                tag=row.get("sidecar_tag") or "",
                priority=row.get("priority") or "",
                eligible=str(bool(row.get("matrix_candidate_row_eligible_now"))).lower(),
                blockers=blockers,
                next=row.get("allowed_next_test") or "",
            )
        )
    lines.extend(["", "## Matrix Candidate Rows", ""])
    if as_list(payload.get("matrix_candidate_rows")):
        for row in as_list(payload.get("matrix_candidate_rows")):
            lines.append(
                "- `{candidate}` add `{add}` cut `{cut}` lane `{lane}`".format(
                    candidate=row.get("candidate_key") or "",
                    add=row.get("add_card") or "",
                    cut=row.get("cut_card") or "",
                    lane=row.get("lane") or "",
                )
            )
    else:
        lines.append("- None. Every current row is blocked before matrix scoring.")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- matrix_candidate_rows_ready: `{str(decision['matrix_candidate_rows_ready']).lower()}`")
    lines.append(f"- candidate_deck_materialization_allowed_now: `{str(decision['candidate_deck_materialization_allowed_now']).lower()}`")
    lines.append(f"- forced_access_allowed_now: `{str(decision['forced_access_allowed_now']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - {action}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--post-safe-cut-route", type=Path, default=DEFAULT_POST_SAFE_CUT_ROUTE)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--structure-matrix", type=Path, default=DEFAULT_STRUCTURE_MATRIX)
    parser.add_argument("--safe-cut-miner", type=Path, default=DEFAULT_SAFE_CUT_MINER)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--limit", type=int, default=40)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "post_safe_cut_route": args.post_safe_cut_route,
        "hypothesis_queue": args.hypothesis_queue,
        "structure_matrix": args.structure_matrix,
        "safe_cut_miner": args.safe_cut_miner,
        "value_model": args.value_model,
    }
    payload = build_report(
        post_safe_cut_route=read_json(args.post_safe_cut_route),
        hypothesis_queue=read_json(args.hypothesis_queue),
        structure_matrix=read_json(args.structure_matrix),
        safe_cut_miner=read_json(args.safe_cut_miner),
        value_model=read_json(args.value_model),
        paths=paths,
        limit=args.limit,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
