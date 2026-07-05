#!/usr/bin/env python3
"""Mine non-anchor same-lane cut models for Lorehold topdeck targets.

This read-only miner is the next step after the trace-evidence collector. It
does not make a cut safe; it checks whether the current 607 cut-slot evidence
contains a non-anchor same-lane candidate for each topdeck target, with
Dragon's Rage Channeler prioritized because it has no prior reject in the
current trace evidence.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_TRACE_EVIDENCE = (
    REPORT_DIR / "lorehold_topdeck_floor_trace_evidence_collector_20260705_current.json"
)
DEFAULT_SAFE_CUT_MINER = REPORT_DIR / "lorehold_topdeck_safe_cut_miner_20260705_current.json"
DEFAULT_TRACE_CUT_EXPANDER = (
    REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_nonanchor_cut_model_miner_20260705_current"


HARD_STOP_BLOCKERS = {
    "commander_never_cut",
    "cut_is_early_mana_floor_support",
    "cut_is_miracle_core_big_spell",
    "cut_is_protection_shell",
    "early_mana_floor_support",
    "mana_base_never_cut",
    "measured_high_cut_exposure",
    "miracle_or_finisher_core",
    "never_cut_lane",
    "never_cut_or_mana_base",
    "prior_rejected_cut",
    "prior_rejected_cut_slot",
    "prior_rejected_signature",
    "protected_cut",
    "protection_shell",
    "structural_dependency",
}

TARGET_ORDER = [
    "Dragon's Rage Channeler",
    "Penance",
    "Galvanoth",
    "Valakut Awakening // Valakut Stoneforge",
    "Wheel of Fortune",
]

EXTERNAL_REFRESH_NOTES = [
    {
        "source": "Scryfall Dragon's Rage Channeler",
        "url": "https://scryfall.com/search?q=dragon%27s+rage+channeler",
        "learning": "Noncreature spell surveil makes DRC a plausible low-cost topdeck smoothing target.",
        "guardrail": "Oracle text does not create a safe cut or prove it belongs in deck 607.",
    },
    {
        "source": "Scryfall Penance",
        "url": "https://scryfall.com/search?q=Penance",
        "learning": "Penance can put a card from hand on top of the library, matching Lorehold miracle timing.",
        "guardrail": "Card-mechanic fit still needs same-lane cut and local trace floors.",
    },
    {
        "source": "EDHREC Lorehold pages",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "learning": "Public Lorehold pages continue to surface topdeck/spellslinger signals.",
        "guardrail": "EDHREC is discovery/provenance, not deck-change proof.",
    },
]


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


def target_evidence_rows(trace_evidence: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("card_name") or ""): dict(row)
        for row in as_list(trace_evidence.get("target_evidence_rows"))
        if isinstance(row, Mapping) and row.get("card_name")
    }


def safe_cut_rows(safe_cut_miner: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("card_name") or ""): dict(row)
        for row in as_list(safe_cut_miner.get("target_cut_assessments"))
        if isinstance(row, Mapping) and row.get("card_name")
    }


def cut_slot_rows(trace_cut_expander: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [dict(row) for row in as_list(trace_cut_expander.get("all_cut_slots")) if isinstance(row, Mapping)]
    rows.sort(key=lambda row: (-as_int(row.get("score")), str(row.get("card_name") or "")))
    return rows


def all_blockers(row: Mapping[str, Any]) -> set[str]:
    blockers = set()
    blockers.update(str(item) for item in as_list(row.get("absolute_blockers")))
    blockers.update(str(item) for item in as_list(row.get("hard_stop_blockers")))
    blockers.update(str(item) for item in as_list(row.get("all_blockers")))
    return {item for item in blockers if item}


def blocker_brief(row: Mapping[str, Any]) -> dict[str, Any]:
    blockers = sorted(all_blockers(row))
    hard = [blocker for blocker in blockers if blocker in HARD_STOP_BLOCKERS]
    soft = [blocker for blocker in blockers if blocker not in HARD_STOP_BLOCKERS]
    return {
        "card_name": row.get("card_name") or "",
        "lane": row.get("lane") or "",
        "score": as_int(row.get("score")),
        "actionability": row.get("actionability") or "",
        "status": row.get("status") or "",
        "hard_stop_blockers": hard,
        "soft_blockers": soft,
        "recommended_action": row.get("recommended_action") or row.get("investigation_action") or "",
        "unique_exposure_count": as_int(row.get("unique_exposure_count")),
        "direct_event_count": as_int(row.get("direct_event_count")),
    }


def nonanchor_candidate_status(row: Mapping[str, Any]) -> tuple[str, list[str]]:
    blockers = all_blockers(row)
    hard = sorted(blocker for blocker in blockers if blocker in HARD_STOP_BLOCKERS)
    actionability = str(row.get("actionability") or "")
    if hard:
        return "blocked_by_hard_stop", hard
    if actionability in {"seed_safe_ready", "seed_safe_cut_ready"}:
        return "seed_safe_nonanchor_candidate", []
    if actionability == "reviewable_evidence_gap":
        return "reviewable_nonanchor_gap", sorted(blockers)
    return "missing_seed_safe_or_reviewable_status", sorted(blockers)


def model_for_target(
    *,
    card_name: str,
    trace_row: Mapping[str, Any],
    safe_row: Mapping[str, Any],
    cut_slots: list[Mapping[str, Any]],
) -> dict[str, Any]:
    target_lanes = set(str(lane) for lane in as_list(safe_row.get("target_lanes")))
    same_lane_slots = [slot for slot in cut_slots if str(slot.get("lane") or "") in target_lanes]
    seed_safe: list[dict[str, Any]] = []
    reviewable: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    status_counts: Counter[str] = Counter()
    blocker_counts: Counter[str] = Counter()
    for slot in same_lane_slots:
        status, blockers = nonanchor_candidate_status(slot)
        status_counts[status] += 1
        blocker_counts.update(blockers)
        brief = blocker_brief(slot)
        brief["nonanchor_status"] = status
        if status == "seed_safe_nonanchor_candidate":
            seed_safe.append(brief)
        elif status == "reviewable_nonanchor_gap":
            reviewable.append(brief)
        else:
            blocked.append(brief)
    prior_reject_count = as_int(trace_row.get("prior_reject_count"))
    clean_prior = prior_reject_count == 0
    if seed_safe:
        model_status = "nonanchor_seed_safe_cut_found_review_required"
        next_action = "build_lab_manifest_with_seed_safe_nonanchor_cut"
    elif reviewable:
        model_status = "nonanchor_reviewable_gap_found_keep_607"
        next_action = "review_gap_before_any_trace_execution"
    elif clean_prior:
        model_status = "clean_prior_target_blocked_no_nonanchor_cut"
        next_action = "mine_external_or_new_trace_evidence_for_nonanchor_cut"
    else:
        model_status = "prior_reject_target_blocked_no_nonanchor_cut"
        next_action = "do_not_retest_prior_pair_without_new_cut_model"
    return {
        "card_name": card_name,
        "target_lanes": sorted(target_lanes),
        "learning_priority_rank": as_int(trace_row.get("learning_priority_rank")),
        "trace_evidence_status": trace_row.get("trace_evidence_status") or "",
        "prior_reject_count": prior_reject_count,
        "clean_prior_target": clean_prior,
        "model_status": model_status,
        "same_lane_slot_count": len(same_lane_slots),
        "seed_safe_nonanchor_count": len(seed_safe),
        "reviewable_nonanchor_gap_count": len(reviewable),
        "blocked_same_lane_slot_count": len(blocked),
        "status_counts": dict(sorted(status_counts.items())),
        "blocker_counts": dict(sorted(blocker_counts.items())),
        "seed_safe_nonanchor_candidates": seed_safe[:10],
        "reviewable_nonanchor_gaps": reviewable[:10],
        "top_blocked_same_lane_slots": blocked[:12],
        "next_action": next_action,
        "deck_action_allowed_now": False,
        "candidate_materialization_allowed_now": False,
        "forced_access_allowed_now": False,
        "natural_battle_gate_allowed_now": False,
        "promotion_allowed_now": False,
    }


def ordered_target_names(trace_rows: Mapping[str, Mapping[str, Any]]) -> list[str]:
    names = [name for name in TARGET_ORDER if name in trace_rows]
    names.extend(sorted(name for name in trace_rows if name not in names))
    return names


def missing_inputs(payloads: Mapping[str, Mapping[str, Any]]) -> list[str]:
    return [key for key, payload in payloads.items() if not payload]


def build_report(
    *,
    trace_evidence: Mapping[str, Any],
    safe_cut_miner: Mapping[str, Any],
    trace_cut_expander: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "trace_evidence": trace_evidence,
        "safe_cut_miner": safe_cut_miner,
        "trace_cut_expander": trace_cut_expander,
    }
    missing = missing_inputs(payloads)
    trace_rows = target_evidence_rows(trace_evidence)
    safe_rows = safe_cut_rows(safe_cut_miner)
    cut_slots = cut_slot_rows(trace_cut_expander)
    target_models: list[dict[str, Any]] = []
    if not missing:
        for card_name in ordered_target_names(trace_rows):
            target_models.append(
                model_for_target(
                    card_name=card_name,
                    trace_row=trace_rows.get(card_name, {}),
                    safe_row=safe_rows.get(card_name, {}),
                    cut_slots=cut_slots,
                )
            )
    status_counts = Counter(str(row.get("model_status") or "") for row in target_models)
    seed_safe_count = sum(as_int(row.get("seed_safe_nonanchor_count")) for row in target_models)
    reviewable_count = sum(as_int(row.get("reviewable_nonanchor_gap_count")) for row in target_models)
    clean_prior_blocked = [
        row.get("card_name")
        for row in target_models
        if row.get("model_status") == "clean_prior_target_blocked_no_nonanchor_cut"
    ]
    primary = target_models[0] if target_models else {}
    if missing:
        status = "topdeck_nonanchor_cut_model_inputs_missing_keep_607"
        next_action = "rerun_missing_nonanchor_cut_inputs"
    elif seed_safe_count:
        status = "topdeck_nonanchor_cut_model_seed_safe_found_keep_607"
        next_action = "review_seed_safe_nonanchor_cut_before_any_forced_access"
    elif reviewable_count:
        status = "topdeck_nonanchor_cut_model_reviewable_gap_found_keep_607"
        next_action = "review_nonanchor_gap_before_any_forced_access"
    else:
        status = "topdeck_nonanchor_cut_model_none_found_keep_607"
        next_action = "collect_new_cut_evidence_or_define_new_shell_contract_before_execution"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_nonanchor_cut_model_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "external_refresh_notes": EXTERNAL_REFRESH_NOTES,
        "summary": {
            "decision_status": status,
            "missing_inputs": missing,
            "target_card_count": len(target_models),
            "primary_target": primary.get("card_name") or "",
            "primary_target_model_status": primary.get("model_status") or "",
            "primary_target_same_lane_slot_count": as_int(primary.get("same_lane_slot_count")),
            "seed_safe_nonanchor_count": seed_safe_count,
            "reviewable_nonanchor_gap_count": reviewable_count,
            "clean_prior_blocked_target_count": len(clean_prior_blocked),
            "clean_prior_blocked_targets": clean_prior_blocked,
            "microbenchmark_runnable_count": 0,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "structure_matrix_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "status_counts": dict(sorted(status_counts.items())),
            "recommended_next_action": next_action,
        },
        "target_cut_models": target_models,
        "source_evidence": {
            "trace_evidence_summary": summary(trace_evidence),
            "safe_cut_miner_summary": summary(safe_cut_miner),
            "trace_cut_expander_summary": summary(trace_cut_expander),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "allow_deck_mutation_now": False,
            "allow_candidate_materialization_now": False,
            "allow_forced_access_now": False,
            "allow_structure_matrix_now": False,
            "allow_natural_battle_gate_now": False,
            "promotion_allowed": False,
            "reason": (
                "The current cut-slot evidence has no seed-safe or reviewable non-anchor same-lane "
                "cut for the topdeck targets. Dragon's Rage Channeler remains the cleanest target "
                "by prior-result history, but its same-lane slots are hard-blocked."
            ),
            "next_actions": [
                next_action,
                "do_not_execute_forced_access_without_a_named_safe_cut",
                "do_not_reuse_protected_or_prior_rejected_cut_slots",
                "keep 607 protected until equal gate and trace evidence prove a replacement",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = summary(payload)
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck Non-Anchor Cut Model Miner",
        "",
        f"- Generated at: `{payload.get('generated_at')}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload.get('status')}`",
        f"- Primary target: `{summary_row.get('primary_target')}`",
        f"- Primary target status: `{summary_row.get('primary_target_model_status')}`",
        f"- Seed-safe non-anchor count: `{summary_row.get('seed_safe_nonanchor_count')}`",
        f"- Reviewable non-anchor gap count: `{summary_row.get('reviewable_nonanchor_gap_count')}`",
        f"- Forced access allowed now: `{str(summary_row.get('forced_access_allowed_now')).lower()}`",
        f"- Structure matrix allowed now: `{str(summary_row.get('structure_matrix_allowed_now')).lower()}`",
        f"- Natural battle gate allowed now: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed now: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Target Models", ""])
    lines.extend(
        [
            "| Card | Status | Same-Lane Slots | Seed-Safe | Reviewable | Prior Rejects | Next Action |",
            "| --- | --- | ---: | ---: | ---: | ---: | --- |",
        ]
    )
    for row in as_list(payload.get("target_cut_models")):
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "| `{card}` | `{status}` | {slots} | {safe} | {reviewable} | {rejects} | {next_action} |".format(
                card=row.get("card_name"),
                status=row.get("model_status"),
                slots=row.get("same_lane_slot_count"),
                safe=row.get("seed_safe_nonanchor_count"),
                reviewable=row.get("reviewable_nonanchor_gap_count"),
                rejects=row.get("prior_reject_count"),
                next_action=row.get("next_action"),
            )
        )
    lines.extend(["", "## Primary Target Blocked Slots", ""])
    primary_name = summary_row.get("primary_target")
    primary = next(
        (row for row in as_list(payload.get("target_cut_models")) if isinstance(row, Mapping) and row.get("card_name") == primary_name),
        {},
    )
    for row in as_list(as_dict(primary).get("top_blocked_same_lane_slots")):
        if isinstance(row, Mapping):
            blockers = ", ".join(as_list(row.get("hard_stop_blockers"))[:5])
            lines.append(
                f"- `{row.get('card_name')}` ({row.get('lane')}): `{row.get('nonanchor_status')}`; blockers: {blockers}"
            )
    lines.extend(["", "## External Refresh Notes", ""])
    for row in as_list(payload.get("external_refresh_notes")):
        if isinstance(row, Mapping):
            lines.append(f"- `{row.get('source')}`: {row.get('url')} - {row.get('guardrail')}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision.get('allow_deck_mutation_now')).lower()}`")
    lines.append(f"- allow_candidate_materialization_now: `{str(decision.get('allow_candidate_materialization_now')).lower()}`")
    lines.append(f"- allow_forced_access_now: `{str(decision.get('allow_forced_access_now')).lower()}`")
    lines.append(f"- allow_structure_matrix_now: `{str(decision.get('allow_structure_matrix_now')).lower()}`")
    lines.append(f"- allow_natural_battle_gate_now: `{str(decision.get('allow_natural_battle_gate_now')).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.append("- next_actions:")
    for action in as_list(decision.get("next_actions")):
        lines.append(f"  - `{action}`")
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
    parser.add_argument("--trace-evidence", type=Path, default=DEFAULT_TRACE_EVIDENCE)
    parser.add_argument("--safe-cut-miner", type=Path, default=DEFAULT_SAFE_CUT_MINER)
    parser.add_argument("--trace-cut-expander", type=Path, default=DEFAULT_TRACE_CUT_EXPANDER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "trace_evidence": args.trace_evidence,
        "safe_cut_miner": args.safe_cut_miner,
        "trace_cut_expander": args.trace_cut_expander,
    }
    payload = build_report(
        trace_evidence=read_json(args.trace_evidence),
        safe_cut_miner=read_json(args.safe_cut_miner),
        trace_cut_expander=read_json(args.trace_cut_expander),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "primary_target": payload["summary"]["primary_target"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
