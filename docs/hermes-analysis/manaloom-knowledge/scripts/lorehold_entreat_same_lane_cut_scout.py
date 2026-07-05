#!/usr/bin/env python3
"""Scout Entreat same-lane cut safety before any Lorehold deck action.

The Entreat runtime primitive and SQL package can make the card executable, but
the Commander deckbuilding contract still requires a named same-lane cut before
matrix scoring, battle, or deck mutation. This auditor joins the current
miracle-access queue, Entreat runtime/package reports, the protected 607 value
model, and cut evidence miner. It is read-only by design.
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

DEFAULT_CANDIDATE_QUEUE = (
    REPORT_DIR
    / "lorehold_miracle_access_candidate_row_queue_20260705_post_authorized_full_validation.json"
)
DEFAULT_ENTREAT_PACKAGE = REPORT_DIR / "pg472_lorehold_entreat_x_token_rule_20260705_current.json"
DEFAULT_ENTREAT_PREFLIGHT = (
    REPORT_DIR / "lorehold_entreat_x_token_runtime_preflight_20260705_current.json"
)
DEFAULT_CUT_MINER = (
    REPORT_DIR / "lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "lorehold_entreat_same_lane_cut_scout_20260705_post_authorized_full_validation"
)

ENTREAT = "Entreat the Angels"
SAME_LANE_TAG = "miracle_conversion_finisher"
SAME_LANE_NAME_PRIORITY = {
    "Approach of the Second Sun": 1,
    "Storm Herd": 2,
    "Creative Technique": 3,
    "Mizzix's Mastery": 4,
    "Rise of the Eldrazi": 5,
    "Call Forth the Tempest": 6,
    "Hit the Mother Lode": 7,
    "Insurrection": 8,
    "Surge to Victory": 9,
    "Everything Comes to Dust": 10,
}
SAFE_CLASSIFICATIONS = {"seed_safe_cut_ready", "gate_ready_safe_same_lane"}
SAFE_STATUSES = {"ready", "seed_safe_cut_ready", "gate_ready_safe_same_lane"}
HARD_BLOCKER_FIELDS = ("hard_stop_blockers", "soft_evidence_blockers", "other_blockers")


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


def entreat_queue_row(candidate_queue: Mapping[str, Any]) -> dict[str, Any]:
    for key in ("candidate_rows", "blocked_candidate_rows"):
        for row in as_list(candidate_queue.get(key)):
            if isinstance(row, Mapping) and row.get("add_card") == ENTREAT:
                return dict(row)
    return {}


def index_by_card(rows: list[Any]) -> dict[str, dict[str, Any]]:
    indexed: dict[str, dict[str, Any]] = {}
    for row in rows:
        if isinstance(row, Mapping) and row.get("card_name"):
            indexed[str(row["card_name"])] = dict(row)
    return indexed


def value_same_lane_rows(value_model: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in as_list(value_model.get("all_card_values")):
        if not isinstance(row, Mapping):
            continue
        lanes = {str(lane) for lane in as_list(row.get("lanes"))}
        name = str(row.get("card_name") or "")
        if SAME_LANE_TAG in lanes or name in SAME_LANE_NAME_PRIORITY:
            rows.append(dict(row))
    rows.sort(
        key=lambda row: (
            SAME_LANE_NAME_PRIORITY.get(str(row.get("card_name") or ""), 99),
            -as_int(row.get("value_score")),
            str(row.get("card_name") or ""),
        )
    )
    return rows


def blocker_values(row: Mapping[str, Any]) -> list[str]:
    blockers: list[str] = []
    for field in HARD_BLOCKER_FIELDS:
        blockers.extend(str(item) for item in as_list(row.get(field)) if item)
    if row.get("blockers"):
        blockers.extend(str(item) for item in as_list(row.get("blockers")) if item)
    return sorted(set(blockers))


def scout_status(cut_row: Mapping[str, Any]) -> str:
    if not cut_row:
        return "blocked_missing_cut_evidence_row"
    classification = str(cut_row.get("classification") or "")
    status = str(cut_row.get("status") or "")
    blockers = blocker_values(cut_row)
    if classification in SAFE_CLASSIFICATIONS and status in SAFE_STATUSES and not blockers:
        return "safe_same_lane_cut_candidate"
    if classification == "closed_hard_stop_current_607":
        return "blocked_current_607_hard_stop"
    if status == "same_lane_only_not_seed_safe":
        return "blocked_same_lane_only_not_seed_safe"
    if blockers:
        return "blocked_cut_evidence_not_seed_safe"
    return "blocked_cut_not_seed_safe"


def investigation_action(row_status: str) -> str:
    return {
        "safe_same_lane_cut_candidate": "can_feed_candidate_queue_after_entreat_rule_is_active",
        "blocked_missing_cut_evidence_row": "produce_cut_evidence_before_any_score_or_battle",
        "blocked_current_607_hard_stop": "do_not_use_as_entreat_cut_under_current_607_contract",
        "blocked_same_lane_only_not_seed_safe": "benchmark_only_not_a_deck_cut_until_it_beats_607",
        "blocked_cut_evidence_not_seed_safe": "mine_or_retest_cut_safety_before_matrix_scoring",
        "blocked_cut_not_seed_safe": "audit_cut_before_use_no_deck_action",
    }.get(row_status, "audit_cut_before_use_no_deck_action")


def build_same_lane_rows(
    *,
    value_model: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
) -> list[dict[str, Any]]:
    cut_index = index_by_card(as_list(cut_miner.get("all_cut_rows")))
    rows: list[dict[str, Any]] = []
    for value_row in value_same_lane_rows(value_model):
        name = str(value_row.get("card_name") or "")
        cut_row = cut_index.get(name, {})
        status = scout_status(cut_row)
        rows.append(
            {
                "card_name": name,
                "functional_tag": value_row.get("functional_tag") or "",
                "lanes": as_list(value_row.get("lanes")),
                "value_tier": value_row.get("value_tier") or "",
                "value_score": as_int(value_row.get("value_score")),
                "cut_policy": value_row.get("cut_policy") or "",
                "protected_anchor": bool(value_row.get("protected_anchor")),
                "runtime_ready": bool(value_row.get("runtime_ready")),
                "cut_lane": cut_row.get("lane") or "",
                "cut_status": cut_row.get("status") or "",
                "cut_classification": cut_row.get("classification") or "",
                "unique_exposure_count": as_int(cut_row.get("unique_exposure_count")),
                "direct_event_count": as_int(cut_row.get("direct_event_count")),
                "blockers": blocker_values(cut_row),
                "scout_status": status,
                "investigation_action": investigation_action(status),
            }
        )
    return rows


def package_state(entreat_package: Mapping[str, Any]) -> dict[str, Any]:
    proposal = as_dict(entreat_package.get("proposal"))
    return {
        "package_generated": bool(proposal),
        "postgres_writes_executed": bool(entreat_package.get("postgres_writes_executed")),
        "review_status": proposal.get("review_status") or "",
        "execution_status": proposal.get("execution_status") or "",
        "battle_model_scope": as_dict(proposal.get("effect_json")).get("battle_model_scope") or "",
        "native_miracle_cost": as_dict(proposal.get("effect_json")).get("native_miracle_cost") or "",
        "normal_mana_cost": proposal.get("mana_cost") or "",
        "logical_rule_key": proposal.get("logical_rule_key") or "",
    }


def runtime_state(entreat_preflight: Mapping[str, Any]) -> dict[str, Any]:
    preflight_summary = summary(entreat_preflight)
    return {
        "runtime_primitive_ready": bool(preflight_summary.get("runtime_primitive_ready")),
        "entreat_active_rule_count": as_int(preflight_summary.get("entreat_active_rule_count")),
        "battle_ready_now_count": as_int(preflight_summary.get("battle_ready_now_count")),
        "preflight_status": entreat_preflight.get("status") or "",
    }


def decision_status(
    *,
    entreat_row: Mapping[str, Any],
    pkg: Mapping[str, Any],
    runtime: Mapping[str, Any],
    safe_cut_count: int,
    matrix_blocker_count: int,
) -> tuple[str, str, bool]:
    if not entreat_row:
        return (
            "entreat_same_lane_cut_scout_blocked_missing_entreat_candidate_row",
            "rerun_miracle_access_candidate_row_queue",
            False,
        )
    if not pkg.get("package_generated"):
        return (
            "entreat_same_lane_cut_scout_blocked_runtime_package_missing",
            "generate_entreat_runtime_package_before_cut_scoring",
            False,
        )
    if not runtime.get("runtime_primitive_ready"):
        return (
            "entreat_same_lane_cut_scout_blocked_runtime_primitive_incomplete",
            "finish_entreat_x_token_runtime_primitive",
            False,
        )
    if safe_cut_count == 0:
        return (
            "entreat_same_lane_cut_scout_blocked_no_safe_cut_keep_607",
            "do_not_score_entreat_until_pg_apply_and_safe_cut_evidence",
            False,
        )
    if not pkg.get("postgres_writes_executed") or as_int(runtime.get("entreat_active_rule_count")) <= 0:
        return (
            "entreat_same_lane_cut_scout_blocked_rule_not_applied_no_battle",
            "apply_entreat_rule_only_after_pg_precheck_then_refresh_candidate_queue",
            False,
        )
    if matrix_blocker_count > 0:
        return (
            "entreat_same_lane_cut_scout_ready_for_queue_refresh_no_battle",
            "rerun_candidate_queue_and_structure_matrix_before_battle",
            False,
        )
    return (
        "entreat_same_lane_cut_candidate_ready_for_matrix_scoring_no_battle",
        "feed_entreat_and_named_cut_into_matrix_scoring_no_battle",
        True,
    )


def build_report(
    *,
    candidate_queue: Mapping[str, Any],
    entreat_package: Mapping[str, Any],
    entreat_preflight: Mapping[str, Any],
    cut_miner: Mapping[str, Any],
    value_model: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    entreat_row = entreat_queue_row(candidate_queue)
    same_lane_rows = build_same_lane_rows(value_model=value_model, cut_miner=cut_miner)
    safe_rows = [row for row in same_lane_rows if row["scout_status"] == "safe_same_lane_cut_candidate"]
    blocked_rows = [row for row in same_lane_rows if row["scout_status"] != "safe_same_lane_cut_candidate"]
    pkg = package_state(entreat_package)
    runtime = runtime_state(entreat_preflight)
    matrix_blocker_count = as_int(summary(candidate_queue).get("matrix_contract_blocker_count"))
    status, next_action, matrix_scoring_allowed = decision_status(
        entreat_row=entreat_row,
        pkg=pkg,
        runtime=runtime,
        safe_cut_count=len(safe_rows),
        matrix_blocker_count=matrix_blocker_count,
    )
    status_counts = Counter(row["scout_status"] for row in same_lane_rows)
    blocker_counts = Counter(blocker for row in same_lane_rows for blocker in as_list(row.get("blockers")))
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_entreat_same_lane_cut_scout",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in paths.items()},
        "summary": {
            "decision_status": status,
            "entreat_candidate_row_found": bool(entreat_row),
            "entreat_lane": entreat_row.get("lane") or "",
            "package_generated": bool(pkg.get("package_generated")),
            "postgres_writes_executed": bool(pkg.get("postgres_writes_executed")),
            "runtime_primitive_ready": bool(runtime.get("runtime_primitive_ready")),
            "entreat_active_rule_count": as_int(runtime.get("entreat_active_rule_count")),
            "same_lane_candidate_count": len(same_lane_rows),
            "safe_cut_count": len(safe_rows),
            "blocked_same_lane_cut_count": len(blocked_rows),
            "matrix_contract_blocker_count": matrix_blocker_count,
            "matrix_scoring_allowed_now": matrix_scoring_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "deck_action_allowed_now": False,
            "status_counts": dict(sorted(status_counts.items())),
            "top_blocker_counts": dict(blocker_counts.most_common(12)),
            "recommended_next_action": next_action,
        },
        "entreat_candidate_row": entreat_row,
        "entreat_package_state": pkg,
        "entreat_runtime_state": runtime,
        "safe_same_lane_cut_candidates": safe_rows,
        "blocked_same_lane_cut_rows": blocked_rows,
        "same_lane_cut_rows": same_lane_rows,
        "source_evidence": {
            "candidate_queue_summary": summary(candidate_queue),
            "cut_miner_summary": summary(cut_miner),
            "value_model_summary": summary(value_model),
            "external_confirmation": {
                "scryfall": "https://scryfall.com/search?as=text&q=%21%22Entreat+the+Angels%22",
                "gatherer": "https://gatherer.wizards.com/search?cardName=Entreat_the_Angels",
                "interpretation": (
                    "External identity confirms Entreat as an X miracle token finisher; "
                    "deck promotion still depends on ManaLoom runtime apply and same-lane cut proof."
                ),
            },
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "deck_action_allowed": False,
            "matrix_scoring_allowed_now": matrix_scoring_allowed,
            "candidate_deck_materialization_allowed_now": False,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "pg_apply_required_before_battle": (
                not pkg.get("postgres_writes_executed")
                or as_int(runtime.get("entreat_active_rule_count")) <= 0
            ),
            "named_safe_cut_required_before_scoring": len(safe_rows) == 0,
            "reason": (
                "Entreat has a generated verified/auto package and the X-token runtime primitive "
                "is ready, but no protected-607 same-lane cut is seed-safe. The current shell "
                "therefore stays on 607 and Entreat remains a research candidate."
            )
            if len(safe_rows) == 0
            else (
                "A same-lane cut candidate exists, but deck materialization and battle remain "
                "closed until runtime apply, refreshed matrix scoring, and trace floors pass."
            ),
            "next_actions": [
                "do_not_mutate_deck_607",
                "do_not_materialize_entreat_candidate_deck",
                "do_not_run_natural_battle_until_entreat_rule_is_active_and_a_named_cut_is_seed_safe",
                "mine_or_generate_cut_evidence_for_low-risk_miracle-finisher_slots",
                "after_pg_apply_refresh_candidate_queue_and_structure_matrix_before_any_battle_gate",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = payload["summary"]
    lines = [
        "# Lorehold Entreat Same-Lane Cut Scout",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Decision status: `{summary_row['decision_status']}`",
        f"- Entreat candidate row found: `{str(summary_row['entreat_candidate_row_found']).lower()}`",
        f"- Package generated: `{str(summary_row['package_generated']).lower()}`",
        f"- PostgreSQL writes executed: `{str(summary_row['postgres_writes_executed']).lower()}`",
        f"- Runtime primitive ready: `{str(summary_row['runtime_primitive_ready']).lower()}`",
        f"- Entreat active rule count: `{summary_row['entreat_active_rule_count']}`",
        f"- Same-lane candidates reviewed: `{summary_row['same_lane_candidate_count']}`",
        f"- Safe same-lane cuts: `{summary_row['safe_cut_count']}`",
        f"- Blocked same-lane cuts: `{summary_row['blocked_same_lane_cut_count']}`",
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
    lines.extend(["", "## Entreat State", ""])
    pkg = as_dict(payload.get("entreat_package_state"))
    runtime = as_dict(payload.get("entreat_runtime_state"))
    lines.append(f"- battle_model_scope: `{pkg.get('battle_model_scope') or '-'}`")
    lines.append(f"- normal_mana_cost: `{pkg.get('normal_mana_cost') or '-'}`")
    lines.append(f"- native_miracle_cost: `{pkg.get('native_miracle_cost') or '-'}`")
    lines.append(f"- review/execution: `{pkg.get('review_status') or '-'}` / `{pkg.get('execution_status') or '-'}`")
    lines.append(f"- runtime preflight: `{runtime.get('preflight_status') or '-'}`")
    lines.extend(["", "## Same-Lane Cut Scout", ""])
    if payload.get("safe_same_lane_cut_candidates"):
        lines.append("| Cut | Lane | Value | Exposure | Action |")
        lines.append("| --- | --- | ---: | ---: | --- |")
        for row in as_list(payload.get("safe_same_lane_cut_candidates")):
            lines.append(
                f"| {row.get('card_name') or ''} | `{row.get('cut_lane') or ''}` | "
                f"{row.get('value_score') or 0} | {row.get('unique_exposure_count') or 0} | "
                f"`{row.get('investigation_action') or ''}` |"
            )
    else:
        lines.append("- None.")
    lines.extend(["", "## Blocked Same-Lane Rows", ""])
    lines.append("| Cut | Value Lanes | Cut Lane | Classification | Exposure | Blockers |")
    lines.append("| --- | --- | --- | --- | ---: | --- |")
    for row in as_list(payload.get("blocked_same_lane_cut_rows"))[:16]:
        lines.append(
            "| {card} | `{lanes}` | `{cut_lane}` | `{classification}` | {exposure} | {blockers} |".format(
                card=row.get("card_name") or "",
                lanes=", ".join(as_list(row.get("lanes"))),
                cut_lane=row.get("cut_lane") or "",
                classification=row.get("scout_status") or "",
                exposure=row.get("unique_exposure_count") or 0,
                blockers=", ".join(as_list(row.get("blockers"))) or "-",
            )
        )
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- deck_action_allowed: `{str(decision['deck_action_allowed']).lower()}`")
    lines.append(f"- pg_apply_required_before_battle: `{str(decision['pg_apply_required_before_battle']).lower()}`")
    lines.append(f"- named_safe_cut_required_before_scoring: `{str(decision['named_safe_cut_required_before_scoring']).lower()}`")
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
    parser.add_argument("--candidate-queue", type=Path, default=DEFAULT_CANDIDATE_QUEUE)
    parser.add_argument("--entreat-package", type=Path, default=DEFAULT_ENTREAT_PACKAGE)
    parser.add_argument("--entreat-preflight", type=Path, default=DEFAULT_ENTREAT_PREFLIGHT)
    parser.add_argument("--cut-miner", type=Path, default=DEFAULT_CUT_MINER)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "candidate_queue": args.candidate_queue,
        "entreat_package": args.entreat_package,
        "entreat_preflight": args.entreat_preflight,
        "cut_miner": args.cut_miner,
        "value_model": args.value_model,
    }
    payload = build_report(
        candidate_queue=read_json(args.candidate_queue),
        entreat_package=read_json(args.entreat_package),
        entreat_preflight=read_json(args.entreat_preflight),
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
