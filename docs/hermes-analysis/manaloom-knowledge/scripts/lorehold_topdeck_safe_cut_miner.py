#!/usr/bin/env python3
"""Mine safe-cut availability for the current Lorehold topdeck targets.

The forced-access plan can design microbenchmarks, but execution still needs a
copied lab package with a named safe temporary cut. This read-only miner checks
whether the current 607 cut evidence has any such slot for Penance, Galvanoth,
Dragon's Rage Channeler, Valakut Awakening, or Wheel of Fortune.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_MICROBENCHMARK_PLAN = (
    REPORT_DIR / "lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current.json"
)
DEFAULT_TRACE_CUT_EXPANDER = (
    REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_safe_cut_miner_20260705_current"

TARGET_LANES = {
    "Penance": {"topdeck_setup", "topdeck_miracle_setup", "draw", "protection", "contextual"},
    "Galvanoth": {"topdeck_setup", "topdeck_miracle_setup", "spell_velocity", "big_spell_value", "contextual"},
    "Dragon's Rage Channeler": {"topdeck_setup", "topdeck_miracle_setup", "spell_velocity", "contextual"},
    "Valakut Awakening // Valakut Stoneforge": {"hand_filter", "draw", "spell_velocity", "contextual"},
    "Wheel of Fortune": {"hand_filter", "draw", "spell_velocity", "contextual"},
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


def microbenchmark_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [dict(row) for row in as_list(payload.get("microbenchmarks")) if isinstance(row, Mapping)]
    rows.sort(key=lambda row: (as_int(row.get("learning_priority_rank")) or 999, str(row.get("card_name") or "")))
    return rows


def cut_rows(trace_expander: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [dict(row) for row in as_list(trace_expander.get("all_cut_slots")) if isinstance(row, Mapping)]
    rows.sort(
        key=lambda row: (
            {
                "seed_safe_ready": 0,
                "reviewable_evidence_gap": 1,
                "same_lane_hard_blocked": 2,
                "hard_blocked": 3,
            }.get(str(row.get("actionability") or ""), 9),
            -as_int(row.get("score")),
            str(row.get("card_name") or ""),
        )
    )
    return rows


def lanes_for(card_name: str) -> set[str]:
    return set(TARGET_LANES.get(card_name, set()))


def cut_row_brief(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "card_name": row.get("card_name") or "",
        "lane": row.get("lane") or "",
        "actionability": row.get("actionability") or "",
        "status": row.get("status") or "",
        "score": as_int(row.get("score")),
        "recommended_action": row.get("recommended_action") or "",
        "absolute_blockers": as_list(row.get("absolute_blockers")),
        "evidence_gap_blockers": as_list(row.get("evidence_gap_blockers")),
        "all_blockers": as_list(row.get("all_blockers")),
    }


def package_cut_briefs(micro_row: Mapping[str, Any]) -> list[dict[str, Any]]:
    cuts: list[dict[str, Any]] = []
    for package in as_list(micro_row.get("existing_packages")):
        if not isinstance(package, Mapping):
            continue
        for cut in as_list(package.get("cuts")):
            cuts.append(
                {
                    "package_key": package.get("package_key") or "",
                    "cut": cut,
                    "package_status": package.get("status") or "",
                    "package_decision": package.get("decision") or "",
                    "prior_evidence_status": package.get("prior_evidence_status") or "",
                    "cut_safety_status": package.get("cut_safety_status") or "",
                    "prior_delta_pp": package.get("prior_delta_pp"),
                }
            )
    return cuts


def candidate_cut_assessment(micro_row: Mapping[str, Any], cuts: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    card_name = str(micro_row.get("card_name") or "")
    target_lanes = lanes_for(card_name)
    same_lane_rows = [row for row in cuts if str(row.get("lane") or "") in target_lanes]
    seed_safe = [
        row
        for row in same_lane_rows
        if str(row.get("actionability") or "") == "seed_safe_ready"
        or str(row.get("actionability") or "") == "seed_safe_cut_ready"
    ]
    reviewable = [row for row in same_lane_rows if str(row.get("actionability") or "") == "reviewable_evidence_gap"]
    same_lane_hard = [row for row in same_lane_rows if str(row.get("actionability") or "") == "same_lane_hard_blocked"]
    hard = [row for row in same_lane_rows if str(row.get("actionability") or "") == "hard_blocked"]
    attempted_cuts = package_cut_briefs(micro_row)
    if seed_safe:
        status = "seed_safe_cut_available_for_microbenchmark"
        next_action = "build_lab_package_manifest_with_seed_safe_cut"
    elif reviewable:
        status = "reviewable_same_lane_cut_gap"
        next_action = "review_cut_safety_before_forced_access"
    else:
        status = "no_current_safe_cut_for_target"
        next_action = "mine_new_nonanchor_cut_evidence_before_forced_access"
    if str(micro_row.get("package_execution_status") or "").startswith("blocked_prior_reject"):
        next_action = "do_not_retest_prior_pair; mine_new_cut_and_failure_hypothesis"
    elif str(micro_row.get("package_execution_status") or "").startswith("blocked_cut_safety"):
        next_action = "find_nonprotected_same_lane_cut_before_forced_access"
    elif str(micro_row.get("package_execution_status") or "") == "blocked_prior_reject_and_cut_safety":
        next_action = "do_not_reuse_blocked_cut; mine_new_same_lane_cut_model"
    return {
        "card_name": card_name,
        "target_lanes": sorted(target_lanes),
        "microbenchmark_design_allowed": bool(micro_row.get("design_allowed_now")),
        "microbenchmark_runnable_now": False,
        "package_execution_status": micro_row.get("package_execution_status") or "",
        "safe_cut_status": status,
        "seed_safe_same_lane_count": len(seed_safe),
        "reviewable_same_lane_gap_count": len(reviewable),
        "same_lane_hard_blocked_count": len(same_lane_hard),
        "hard_blocked_same_lane_count": len(hard),
        "attempted_package_cut_count": len(attempted_cuts),
        "attempted_package_cuts": attempted_cuts,
        "seed_safe_candidates": [cut_row_brief(row) for row in seed_safe[:10]],
        "reviewable_candidates": [cut_row_brief(row) for row in reviewable[:10]],
        "same_lane_hard_blocked": [cut_row_brief(row) for row in same_lane_hard[:10]],
        "top_same_lane_near_misses": [cut_row_brief(row) for row in same_lane_rows[:10]],
        "next_action": next_action,
    }


def status_for(summary: Mapping[str, Any]) -> str:
    if as_int(summary.get("seed_safe_cut_candidate_count")):
        return "topdeck_safe_cut_miner_found_seed_safe_cut_review_required"
    if as_int(summary.get("reviewable_same_lane_gap_count")):
        return "topdeck_safe_cut_miner_reviewable_gaps_keep_607"
    return "topdeck_safe_cut_miner_no_current_safe_cut_keep_607"


def build_report(
    *,
    microbenchmark_plan: Mapping[str, Any],
    trace_cut_expander: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    cuts = cut_rows(trace_cut_expander)
    rows = [candidate_cut_assessment(row, cuts) for row in microbenchmark_rows(microbenchmark_plan)]
    seed_safe_count = sum(as_int(row["seed_safe_same_lane_count"]) for row in rows)
    reviewable_count = sum(as_int(row["reviewable_same_lane_gap_count"]) for row in rows)
    same_lane_hard_count = sum(as_int(row["same_lane_hard_blocked_count"]) for row in rows)
    attempted_cut_count = sum(as_int(row["attempted_package_cut_count"]) for row in rows)
    action_counts = Counter(str(row.get("safe_cut_status") or "") for row in rows)
    package_counts = Counter(str(row.get("package_execution_status") or "") for row in rows)
    summary = {
        "target_count": len(rows),
        "seed_safe_cut_candidate_count": seed_safe_count,
        "reviewable_same_lane_gap_count": reviewable_count,
        "same_lane_hard_blocked_count": same_lane_hard_count,
        "attempted_package_cut_count": attempted_cut_count,
        "runnable_now_count": 0,
        "natural_promotion_allowed_count": 0,
        "action_counts": dict(sorted(action_counts.items())),
        "package_execution_counts": dict(sorted(package_counts.items())),
        "trace_cut_expander_status": trace_cut_expander.get("status") or "",
        "trace_cut_expander_summary": {
            "seed_safe_ready_count": as_int(as_dict(trace_cut_expander.get("summary")).get("seed_safe_ready_count")),
            "reviewable_evidence_gap_count": as_int(
                as_dict(trace_cut_expander.get("summary")).get("reviewable_evidence_gap_count")
            ),
            "same_lane_hard_blocked_count": as_int(
                as_dict(trace_cut_expander.get("summary")).get("same_lane_hard_blocked_count")
            ),
            "hard_blocked_count": as_int(as_dict(trace_cut_expander.get("summary")).get("hard_blocked_count")),
        },
        "deck_607_mutated": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "recommended_next_action": "do_not_run_forced_access_until_new_nonanchor_cut_evidence",
    }
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_safe_cut_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status_for(summary),
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": summary,
        "target_cut_assessments": rows,
        "decision": {
            "allow_forced_access_execution_now": False,
            "allow_deck_mutation_now": False,
            "allow_natural_gate_now": False,
            "promotion_allowed": False,
            "reason": (
                "Current 607 cut evidence has no seed-safe or reviewable same-lane cut for the "
                "topdeck forced-access targets. Existing attempted cuts are either prior rejects "
                "or protected by cut safety."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = as_dict(payload.get("summary"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Safe Cut Miner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- target_count: `{summary['target_count']}`",
        f"- seed_safe_cut_candidate_count: `{summary['seed_safe_cut_candidate_count']}`",
        f"- reviewable_same_lane_gap_count: `{summary['reviewable_same_lane_gap_count']}`",
        f"- same_lane_hard_blocked_count: `{summary['same_lane_hard_blocked_count']}`",
        f"- attempted_package_cut_count: `{summary['attempted_package_cut_count']}`",
        f"- recommended_next_action: `{summary['recommended_next_action']}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")

    lines.extend(["", "## Target Cut Assessments", ""])
    lines.append("| Card | Safe-cut status | Seed-safe | Reviewable | Same-lane hard | Attempted cuts | Next action |")
    lines.append("| --- | --- | ---: | ---: | ---: | ---: | --- |")
    for row in as_list(payload.get("target_cut_assessments")):
        lines.append(
            "| {card} | `{status}` | {seed} | {review} | {same} | {attempted} | `{next}` |".format(
                card=row.get("card_name") or "",
                status=row.get("safe_cut_status") or "",
                seed=row.get("seed_safe_same_lane_count") or 0,
                review=row.get("reviewable_same_lane_gap_count") or 0,
                same=row.get("same_lane_hard_blocked_count") or 0,
                attempted=row.get("attempted_package_cut_count") or 0,
                next=row.get("next_action") or "",
            )
        )

    lines.extend(["", "## Attempted Package Cuts", ""])
    for row in as_list(payload.get("target_cut_assessments")):
        lines.append(f"### {row.get('card_name')}")
        cuts = as_list(row.get("attempted_package_cuts"))
        if not cuts:
            lines.append("- No existing package cuts found.")
            continue
        for cut in cuts:
            lines.append(
                "- `{cut}` via `{package}`: decision `{decision}`, prior `{prior}`, cut safety `{safety}`.".format(
                    cut=cut.get("cut") or "",
                    package=cut.get("package_key") or "",
                    decision=cut.get("package_decision") or "",
                    prior=cut.get("prior_evidence_status") or "",
                    safety=cut.get("cut_safety_status") or "",
                )
            )

    lines.extend(["", "## Decision", ""])
    lines.append(f"- allow_forced_access_execution_now: `{str(decision['allow_forced_access_execution_now']).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision['allow_deck_mutation_now']).lower()}`")
    lines.append(f"- allow_natural_gate_now: `{str(decision['allow_natural_gate_now']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
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
    parser.add_argument("--microbenchmark-plan", type=Path, default=DEFAULT_MICROBENCHMARK_PLAN)
    parser.add_argument("--trace-cut-expander", type=Path, default=DEFAULT_TRACE_CUT_EXPANDER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "microbenchmark_plan": args.microbenchmark_plan,
        "trace_cut_expander": args.trace_cut_expander,
    }
    payload = build_report(
        microbenchmark_plan=read_json(args.microbenchmark_plan),
        trace_cut_expander=read_json(args.trace_cut_expander),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
