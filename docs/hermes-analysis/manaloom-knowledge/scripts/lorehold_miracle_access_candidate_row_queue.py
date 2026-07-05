#!/usr/bin/env python3
"""Build the Lorehold miracle-access candidate-row queue.

This read-only queue tries to convert post-identity Lorehold candidates into
the row schema required by the miracle-access structure matrix. It can produce
blocked rows, but it cannot materialize a deck or run battle.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_MATRIX = (
    REPORT_DIR / "lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.json"
)
DEFAULT_POST_IDENTITY = REPORT_DIR / "lorehold_post_identity_queue_split_20260705_current.json"
DEFAULT_CUT_MINER = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_miracle_access_candidate_row_queue_20260705_current_relearn"
)

MIRACLE_ACCESS_LANE_TO_MATRIX = {
    "topdeck_miracle_access": ["topdeck_miracle_access", "turn_cycle_miracle_mana"],
    "miracle_finisher": ["approach_finisher_conversion", "topdeck_miracle_access"],
    "spell_scry_pressure": ["spell_volume_density", "pressure_survival_floor"],
    "rummage_pressure_access": ["topdeck_miracle_access", "pressure_survival_floor"],
    "storm_combo_pressure": ["pressure_survival_floor"],
}

ROW_BLOCKER_EXPLANATIONS = {
    "verified_battle_rule_missing": "runtime rule is not verified for candidate use",
    "named_safe_cut_missing": "no named same-lane cut exists for current 607",
    "combo_runtime_required": "combo package must be modeled before matrix scoring",
    "full_shell_contract_required": "this belongs to a separate full-shell fork",
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


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def normalize(value: str) -> str:
    return " ".join(str(value or "").strip().lower().split())


def relevant_post_identity_cards(post_identity: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in as_list(post_identity.get("cards")):
        if not isinstance(row, Mapping):
            continue
        lane = str(row.get("lane") or "")
        if lane in MIRACLE_ACCESS_LANE_TO_MATRIX:
            rows.append(dict(row))
    return sorted(
        rows,
        key=lambda row: (
            as_int(row.get("priority_rank")) if row.get("priority_rank") is not None else 99,
            str(row.get("card_name") or ""),
        ),
    )


def ready_cut_rows(cut_miner: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for key in ("ready_seed_safe_cuts", "seed_safe_cut_candidates"):
        for row in as_list(cut_miner.get(key)):
            if isinstance(row, Mapping) and row.get("card_name"):
                rows.append(dict(row))
    return rows


def blocker_reasons(blockers: list[Any]) -> list[str]:
    reasons = []
    for blocker in blockers:
        key = str(blocker)
        reasons.append(ROW_BLOCKER_EXPLANATIONS.get(key, key))
    return reasons


def can_score_row(card: Mapping[str, Any], cuts: list[Mapping[str, Any]], matrix_summary: Mapping[str, Any]) -> bool:
    if matrix_summary.get("selected_contract_key") != "miracle_access_first_shell_contract":
        return False
    if as_int(matrix_summary.get("contract_aggregate_blocker_count")) > 0:
        return False
    if not cuts:
        return False
    if as_int(card.get("verified_auto_rule_count")) <= 0:
        return False
    blockers = {str(blocker) for blocker in as_list(card.get("blockers"))}
    disallowed = {
        "verified_battle_rule_missing",
        "named_safe_cut_missing",
        "combo_runtime_required",
        "full_shell_contract_required",
    }
    return not bool(blockers & disallowed)


def build_candidate_row(card: Mapping[str, Any], cut: Mapping[str, Any] | None) -> dict[str, Any]:
    card_name = str(card.get("card_name") or "")
    lane = str(card.get("lane") or "")
    return {
        "candidate_key": "miracle_access_row_" + normalize(card_name).replace(" ", "_").replace(",", ""),
        "add_card": card_name,
        "cut_card": cut.get("card_name") if cut else None,
        "lane": lane,
        "matrix_cells": MIRACLE_ACCESS_LANE_TO_MATRIX.get(lane, []),
        "same_lane_cut_reason": cut.get("lane") if cut else "",
        "protected_anchor_impact": "unproven_until_cut_is_named_and_trace_checked",
        "expected_metric_lift": card.get("value_role") or card.get("deckbuilding_value") or "",
        "rule_runtime_status": "verified_auto_rule" if as_int(card.get("verified_auto_rule_count")) > 0 else "runtime_missing_or_manual_review",
        "source_provenance": as_list(card.get("source_keys")),
        "floor_risk": "unknown_until_matrix_scored",
        "source_required_contract": card.get("required_contract") or "",
    }


def classify_rows(
    cards: list[Mapping[str, Any]],
    cuts: list[Mapping[str, Any]],
    matrix_summary: Mapping[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    ready: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    first_cut = cuts[0] if cuts else None
    for card in cards:
        row = build_candidate_row(card, first_cut if can_score_row(card, cuts, matrix_summary) else None)
        row_blockers = list(as_list(card.get("blockers")))
        if not cuts and "named_safe_cut_missing" not in row_blockers:
            row_blockers.append("named_safe_cut_missing")
        if matrix_summary.get("selected_contract_key") != "miracle_access_first_shell_contract":
            row_blockers.append("matrix_contract_missing")
        if as_int(matrix_summary.get("contract_aggregate_blocker_count")) > 0:
            row_blockers.append("matrix_contract_blockers_not_cleared")
        if can_score_row(card, cuts, matrix_summary):
            ready.append(row)
        else:
            row["blockers"] = sorted({str(item) for item in row_blockers})
            row["blocker_reasons"] = blocker_reasons(row["blockers"])
            blocked.append(row)
    return ready, blocked


def decision_status(
    *,
    matrix_summary: Mapping[str, Any],
    source_candidate_count: int,
    ready_count: int,
) -> tuple[str, str]:
    if matrix_summary.get("selected_contract_key") != "miracle_access_first_shell_contract":
        return (
            "miracle_access_candidate_row_queue_blocked_missing_matrix_contract",
            "rerun_miracle_access_structure_matrix_contract",
        )
    if source_candidate_count == 0:
        return (
            "miracle_access_candidate_row_queue_blocked_no_source_candidates",
            "refresh_post_identity_or_external_candidate_sources",
        )
    if ready_count == 0:
        return (
            "miracle_access_candidate_row_queue_blocked_no_scoreable_rows_keep_607",
            "resolve_runtime_and_named_same_lane_cut_before_matrix_scoring",
        )
    return (
        "miracle_access_candidate_rows_ready_for_matrix_scoring_no_battle",
        "feed_candidate_rows_into_structure_matrix_scoring_no_battle",
    )


def build_report(
    *,
    matrix_contract: Mapping[str, Any],
    post_identity: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    value_model: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    matrix_summary = summary(matrix_contract)
    cut_summary = summary(cut_miner)
    value_summary = summary(value_model)
    cards = relevant_post_identity_cards(post_identity)
    cuts = ready_cut_rows(cut_miner)
    ready, blocked = classify_rows(cards, cuts, matrix_summary)
    status, next_action = decision_status(
        matrix_summary=matrix_summary,
        source_candidate_count=len(cards),
        ready_count=len(ready),
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_miracle_access_candidate_row_queue",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "status": status,
        "summary": {
            "decision_status": status,
            "source_candidate_count": len(cards),
            "scoreable_candidate_row_count": len(ready),
            "blocked_candidate_row_count": len(blocked),
            "named_seed_safe_cut_count": as_int(cut_summary.get("named_seed_safe_cut_count")),
            "matrix_contract_blocker_count": as_int(matrix_summary.get("contract_aggregate_blocker_count")),
            "matrix_scoring_allowed_now": bool(ready),
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "value_model_quantity_total": as_int(value_summary.get("quantity_total")),
            "recommended_next_action": next_action,
        },
        "candidate_rows": ready,
        "blocked_candidate_rows": blocked,
        "available_named_seed_safe_cuts": cuts,
        "source_evidence": {
            "matrix_summary": matrix_summary,
            "post_identity_summary": summary(post_identity),
            "cut_miner_summary": cut_summary,
            "value_model_summary": value_summary,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "matrix_scoring_allowed_now": bool(ready),
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "Post-identity candidates exist, but each current miracle-access row "
                "is blocked by runtime, named cut, or uncleared matrix-contract gates."
            )
            if not ready
            else (
                "Candidate rows are scoreable by the matrix, but materialization, "
                "battle, and promotion remain closed."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_candidate_deck_from_blocked_rows",
                "resolve verified runtime for top-priority rows",
                "find named same-lane non-anchor cuts before scoring",
                "keep battle closed until matrix scoring and trace floors pass",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Miracle Access Candidate Row Queue",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Source candidates: `{summary_row['source_candidate_count']}`",
        f"- Scoreable candidate rows: `{summary_row['scoreable_candidate_row_count']}`",
        f"- Blocked candidate rows: `{summary_row['blocked_candidate_row_count']}`",
        f"- Named seed-safe cuts: `{summary_row['named_seed_safe_cut_count']}`",
        f"- Matrix scoring allowed now: `{str(summary_row['matrix_scoring_allowed_now']).lower()}`",
        f"- Candidate deck materialization allowed now: `{str(summary_row['candidate_deck_materialization_allowed_now']).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row['natural_battle_gate_allowed_now']).lower()}`",
        f"- Recommended next action: `{summary_row['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Scoreable Candidate Rows", ""])
    if payload.get("candidate_rows"):
        lines.append("| Add | Cut | Lane | Matrix Cells |")
        lines.append("| --- | --- | --- | --- |")
        for row in as_list(payload.get("candidate_rows")):
            lines.append(
                "| {add} | {cut} | `{lane}` | `{cells}` |".format(
                    add=row.get("add_card") or "",
                    cut=row.get("cut_card") or "",
                    lane=row.get("lane") or "",
                    cells=", ".join(as_list(row.get("matrix_cells"))),
                )
            )
    else:
        lines.append("- None.")
    lines.extend(["", "## Blocked Candidate Rows", ""])
    if payload.get("blocked_candidate_rows"):
        lines.append("| Add | Lane | Matrix Cells | Blockers |")
        lines.append("| --- | --- | --- | --- |")
        for row in as_list(payload.get("blocked_candidate_rows")):
            lines.append(
                "| {add} | `{lane}` | `{cells}` | `{blockers}` |".format(
                    add=row.get("add_card") or "",
                    lane=row.get("lane") or "",
                    cells=", ".join(as_list(row.get("matrix_cells"))),
                    blockers=", ".join(as_list(row.get("blockers"))),
                )
            )
    else:
        lines.append("- None.")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- matrix_scoring_allowed_now: `{str(decision['matrix_scoring_allowed_now']).lower()}`")
    lines.append(f"- candidate_deck_materialization_allowed_now: `{str(decision['candidate_deck_materialization_allowed_now']).lower()}`")
    lines.append(f"- natural_battle_allowed_now: `{str(decision['natural_battle_allowed_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
    lines.append("")
    return "\n".join(lines)


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
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--post-identity", type=Path, default=DEFAULT_POST_IDENTITY)
    parser.add_argument("--cut-miner", type=Path, default=DEFAULT_CUT_MINER)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "matrix": args.matrix,
        "post_identity": args.post_identity,
        "cut_miner": args.cut_miner,
        "value_model": args.value_model,
    }
    payload = build_report(
        matrix_contract=read_json(args.matrix),
        post_identity=read_json(args.post_identity),
        cut_miner=read_json(args.cut_miner),
        value_model=read_json(args.value_model),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
