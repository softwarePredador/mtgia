#!/usr/bin/env python3
"""Scout new Lorehold topdeck cut evidence after the named frontier closed.

This artifact is learning-only. It consumes the post-frontier router, the
non-anchor cut model, the trace cut expander, the value model, and the exposure
profile to decide what evidence must be collected next. It never makes a cut
safe, never mutates deck 607, and never opens a natural battle gate.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from collections.abc import Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_POST_NAMED_ROUTER = (
    REPORT_DIR / "lorehold_post_named_frontier_next_evidence_router_20260705_current.json"
)
DEFAULT_NONANCHOR_MODEL = (
    REPORT_DIR / "lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json"
)
DEFAULT_TRACE_CUT_EXPANDER = (
    REPORT_DIR / "lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json"
)
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_EXPOSURE_PROFILE = (
    REPORT_DIR / "lorehold_card_exposure_profile_20260704_role_tag_repair_deck607.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_topdeck_new_cut_evidence_scout_20260705_current"

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

FLOOR_LANES = {
    "basic_floor",
    "board_wipe",
    "early_mana",
    "fetch_or_search_fixing",
    "land",
    "mana_base",
    "miracle_conversion_finisher",
    "protection",
    "ramp",
    "structural_ramp_floor",
    "typed_dual_or_fetch_target",
    "untapped_or_multiplayer_fixing",
    "utility_engine_land",
    "wincon",
}

EVIDENCE_ADJACENT_LANES = {
    "contextual",
    "draw",
    "engine",
    "hand_filter",
    "instant_sorcery_spell",
    "spell_velocity",
    "topdeck_miracle_engine",
    "topdeck_miracle_setup",
    "topdeck_setup",
}

EXTERNAL_RESEARCH_CONTEXT = [
    {
        "source": "Wizards Commander banned and restricted list",
        "url": "https://magic.wizards.com/en/banned-restricted-list",
        "learning": "Legality is only the first gate. A legal card still needs color identity, ownership, local runtime support, lane fit, cut proof, and battle evidence.",
    },
    {
        "source": "Wizards Commander Brackets Beta",
        "url": "https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta",
        "learning": "High-impact fast mana can change deck power expectations, so ManaLoom treats Game Changer/fast-mana staples as bracket and cut-evidence questions, not automatic upgrades.",
    },
    {
        "source": "EDHREC Lorehold, the Historian upgraded spellslinger",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/upgraded/spellslinger",
        "learning": "The public Lorehold surface reinforces Topdeck, Spellslinger, Discard, and Burn lanes; public inclusion is discovery evidence, not 607 promotion proof.",
    },
    {
        "source": "Scryfall Dragon's Rage Channeler",
        "url": "https://scryfall.com/search?q=%21%22Dragon%27s+Rage+Channeler%22",
        "learning": "Dragon's Rage Channeler remains a plausible one-mana topdeck smoothing probe, but needs a non-anchor same-lane cut before any execution.",
    },
    {
        "source": "Scryfall Mana Vault",
        "url": "https://scryfall.com/search?q=%21%22Mana+Vault%22",
        "learning": "Mana Vault is treated as a powerful fast-mana staple idea, not an available 607 change without ownership and distinct cut evidence.",
    },
    {
        "source": "Scryfall The One Ring",
        "url": "https://scryfall.com/search?q=%21%22The+One+Ring%22",
        "learning": "The One Ring is treated as a powerful generic card-advantage idea, not a 607 upgrade without a same-lane local cut model.",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def normalize_name(name: Any) -> str:
    return str(name or "").strip().lower()


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


def as_float(value: Any) -> float:
    try:
        return float(value or 0)
    except (TypeError, ValueError):
        return 0.0


def summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    return as_dict(payload.get("summary"))


def missing_inputs(payloads: Mapping[str, Mapping[str, Any]]) -> list[str]:
    return [key for key, payload in payloads.items() if not payload]


def all_blockers(row: Mapping[str, Any]) -> set[str]:
    blockers: set[str] = set()
    blockers.update(str(item) for item in as_list(row.get("absolute_blockers")))
    blockers.update(str(item) for item in as_list(row.get("hard_stop_blockers")))
    blockers.update(str(item) for item in as_list(row.get("all_blockers")))
    return {item for item in blockers if item}


def rows_by_name(rows: list[Any], name_key: str = "card_name") -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        name = normalize_name(row.get(name_key))
        if name:
            index[name] = dict(row)
    return index


def primary_clean_target(nonanchor_model: Mapping[str, Any]) -> dict[str, Any]:
    target_models = [
        dict(row)
        for row in as_list(nonanchor_model.get("target_cut_models"))
        if isinstance(row, Mapping)
    ]
    for row in target_models:
        if row.get("clean_prior_target"):
            return row
    primary_name = summary(nonanchor_model).get("primary_target")
    for row in target_models:
        if row.get("card_name") == primary_name:
            return row
    return target_models[0] if target_models else {}


def hard_blocked_same_lane_slots(primary_target: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(primary_target.get("top_blocked_same_lane_slots")):
        if not isinstance(row, Mapping):
            continue
        rows.append(
            {
                "card_name": row.get("card_name") or "",
                "lane": row.get("lane") or "",
                "unique_exposure_count": as_int(row.get("unique_exposure_count")),
                "hard_stop_blockers": as_list(row.get("hard_stop_blockers")),
            }
        )
    return rows


def deckbuilding_priority_rules(value_model: Mapping[str, Any]) -> dict[str, Any]:
    value_summary = summary(value_model)
    mana = as_dict(value_summary.get("mana_foundation"))
    return {
        "land_quantity_floor": as_int(mana.get("land_quantity")),
        "ramp_quantity_floor": as_int(mana.get("ramp_quantity")),
        "mana_sources_land_plus_ramp_floor": as_int(mana.get("mana_sources_land_plus_ramp")),
        "role_profile": as_dict(value_summary.get("role_profile")),
        "protected_lanes": sorted(FLOOR_LANES),
        "policy": [
            "lands, ramp, protection, miracle finishers, and commander center are not generic cuts",
            "external staple strength can create a hypothesis but cannot create a cut",
            "same-lane proof, cut-safety proof, runtime support, and battle evidence are separate gates",
            "deck 607 remains the protected baseline while safe_cut_ready_count is zero",
        ],
    }


def candidate_priority(
    *,
    value_row: Mapping[str, Any],
    exposure_row: Mapping[str, Any],
    exact_lane_overlap: bool,
) -> tuple[int, float, int, str]:
    value_score = as_float(value_row.get("value_score"))
    unique_exposure = as_int(exposure_row.get("unique_exposure_count"))
    exact_bonus = 0 if exact_lane_overlap else 1
    return (exact_bonus, value_score, unique_exposure, str(value_row.get("card_name") or ""))


def classify_internal_candidate(
    *,
    value_row: Mapping[str, Any],
    exposure_row: Mapping[str, Any],
    cut_row: Mapping[str, Any],
    target_lanes: set[str],
    hard_blocked_names: set[str],
) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    card_name = str(value_row.get("card_name") or "")
    if not card_name:
        return None, None
    if normalize_name(card_name) in hard_blocked_names:
        return None, None
    lanes = {str(item) for item in as_list(value_row.get("lanes")) if item}
    cut_lane = str(cut_row.get("lane") or "")
    if cut_lane:
        lanes.add(cut_lane)
    blockers = all_blockers(cut_row)
    hard_blockers = sorted(blockers & HARD_STOP_BLOCKERS)
    floor_lanes = sorted(lanes & FLOOR_LANES)
    cut_policy = str(value_row.get("cut_policy") or "")
    value_score = as_float(value_row.get("value_score"))
    unique_exposure = as_int(exposure_row.get("unique_exposure_count") or cut_row.get("unique_exposure_count"))
    direct_event_count = as_int(exposure_row.get("direct_event_count") or cut_row.get("direct_event_count"))
    exact_lane_overlap = bool(lanes & target_lanes)
    adjacent_lane_overlap = bool(lanes & EVIDENCE_ADJACENT_LANES)
    low_value_or_low_exposure = value_score <= 35 or unique_exposure <= 25
    blocked_reasons = []
    if hard_blockers:
        blocked_reasons.extend(hard_blockers)
    if floor_lanes:
        blocked_reasons.append("floor_lane")
    if cut_policy.startswith("no_generic_cut"):
        blocked_reasons.append("no_generic_cut_policy")
    if not exact_lane_overlap and not adjacent_lane_overlap:
        blocked_reasons.append("no_target_or_adjacent_lane_overlap")
    if not low_value_or_low_exposure:
        blocked_reasons.append("not_low_value_or_low_exposure")
    base = {
        "card_name": card_name,
        "value_score": value_score,
        "value_tier": value_row.get("value_tier") or "",
        "functional_tag": value_row.get("functional_tag") or "",
        "lanes": sorted(lanes),
        "cut_policy": cut_policy,
        "runtime_ready": bool(value_row.get("runtime_ready")),
        "unique_exposure_count": unique_exposure,
        "direct_event_count": direct_event_count,
        "trace_actionability": cut_row.get("actionability") or "",
        "trace_status": cut_row.get("status") or "",
        "trace_recommended_action": cut_row.get("recommended_action") or cut_row.get("investigation_action") or "",
        "hard_stop_blockers": hard_blockers,
        "floor_lanes": floor_lanes,
        "exact_target_lane_overlap": exact_lane_overlap,
        "adjacent_lane_overlap": adjacent_lane_overlap,
    }
    if blocked_reasons:
        if low_value_or_low_exposure:
            blocked = dict(base)
            blocked["blocked_reasons"] = sorted(set(blocked_reasons))
            blocked["evidence_status"] = "blocked_internal_near_miss"
            return None, blocked
        return None, None
    if not low_value_or_low_exposure:
        return None, None
    target = dict(base)
    target["evidence_status"] = (
        "review_only_same_lane_evidence_target"
        if exact_lane_overlap
        else "review_only_lane_reclassification_required"
    )
    target["safe_cut_ready"] = False
    target["matrix_candidate_allowed_now"] = False
    target["natural_battle_gate_allowed_now"] = False
    target["required_evidence_before_cut"] = [
        "new_trace_or_microbenchmark_that_proves_redundant_role",
        "explicit_same_lane_or_lane_reclassification_contract",
        "cut_safety_row_without_hard_stop_blockers",
        "runtime_support_and_equal_gate_before_any_natural_battle",
    ]
    return target, None


def internal_evidence_targets(
    *,
    value_model: Mapping[str, Any],
    exposure_profile: Mapping[str, Any],
    trace_cut_expander: Mapping[str, Any],
    primary_target: Mapping[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    value_rows = [
        dict(row)
        for row in as_list(value_model.get("all_card_values"))
        if isinstance(row, Mapping)
        and not row.get("protected_anchor")
        and not row.get("is_commander")
    ]
    exposure_by_name = rows_by_name(as_list(exposure_profile.get("card_profiles")))
    cut_by_name = rows_by_name(as_list(trace_cut_expander.get("all_cut_slots")))
    target_lanes = {str(item) for item in as_list(primary_target.get("target_lanes")) if item}
    hard_blocked_names = {
        normalize_name(row.get("card_name"))
        for row in hard_blocked_same_lane_slots(primary_target)
        if row.get("card_name")
    }
    targets: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    for value_row in value_rows:
        name = normalize_name(value_row.get("card_name"))
        target, blocked_row = classify_internal_candidate(
            value_row=value_row,
            exposure_row=exposure_by_name.get(name, {}),
            cut_row=cut_by_name.get(name, {}),
            target_lanes=target_lanes,
            hard_blocked_names=hard_blocked_names,
        )
        if target:
            targets.append(target)
        if blocked_row:
            blocked.append(blocked_row)
    targets.sort(
        key=lambda row: candidate_priority(
            value_row=row,
            exposure_row=row,
            exact_lane_overlap=bool(row.get("exact_target_lane_overlap")),
        )
    )
    blocked.sort(
        key=lambda row: candidate_priority(
            value_row=row,
            exposure_row=row,
            exact_lane_overlap=bool(row.get("exact_target_lane_overlap")),
        )
    )
    return targets[:12], blocked[:12]


def evidence_requests(
    *,
    primary_target: Mapping[str, Any],
    hard_blocked_slots: list[dict[str, Any]],
    internal_targets: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    primary_name = primary_target.get("card_name") or "Dragon's Rage Channeler"
    requests = [
        {
            "request_key": "dragon_rage_channeler_new_nonanchor_same_lane_cut_evidence",
            "target_card": primary_name,
            "scout_status": "external_or_new_trace_required",
            "current_hard_blocked_same_lane_slot_count": len(hard_blocked_slots),
            "current_hard_blocked_slots": hard_blocked_slots,
            "internal_review_only_target_count": len(internal_targets),
            "required_evidence": [
                "find a non-protected low-exposure card outside the current hard-blocked slots",
                "prove same-lane redundancy or document a lane reclassification before any cut",
                "produce a cut-safety row with zero hard-stop blockers",
                "run forced-access only after a named safe cut exists",
            ],
            "execution_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
        },
        {
            "request_key": "external_topdeck_corpus_refresh",
            "target_card": primary_name,
            "scout_status": "discovery_only",
            "required_evidence": [
                "refresh Scryfall/EDHREC candidate context",
                "map public candidates to ManaLoom ownership, legality, runtime support, and local lanes",
                "do not convert public inclusion into deck mutation without local cut evidence",
            ],
            "execution_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
        },
        {
            "request_key": "mana_and_staple_routes_deferred",
            "target_card": "",
            "scout_status": "deferred_until_distinct_trace",
            "required_evidence": [
                "do not retest exact Plateau pairs without distinct mana-equivalence trace",
                "do not retest Mana Vault or The One Ring without same-lane local cut evidence",
            ],
            "execution_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
        },
    ]
    return requests


def build_report(
    *,
    post_named_router: Mapping[str, Any],
    nonanchor_model: Mapping[str, Any],
    trace_cut_expander: Mapping[str, Any],
    value_model: Mapping[str, Any],
    exposure_profile: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    payloads = {
        "post_named_router": post_named_router,
        "nonanchor_model": nonanchor_model,
        "trace_cut_expander": trace_cut_expander,
        "value_model": value_model,
        "exposure_profile": exposure_profile,
    }
    missing = missing_inputs(payloads)
    router_summary = summary(post_named_router)
    primary_target = {} if missing else primary_clean_target(nonanchor_model)
    hard_blocked_slots = [] if missing else hard_blocked_same_lane_slots(primary_target)
    targets: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    if not missing:
        targets, blocked = internal_evidence_targets(
            value_model=value_model,
            exposure_profile=exposure_profile,
            trace_cut_expander=trace_cut_expander,
            primary_target=primary_target,
        )
    selected_route = router_summary.get("selected_next_route") or ""
    route_matches = selected_route == "topdeck_new_cut_evidence_scout"
    if missing:
        status = "topdeck_new_cut_evidence_scout_inputs_missing_keep_607"
        next_action = "rerun_missing_inputs_before_topdeck_new_cut_evidence_scout"
    elif targets:
        status = "topdeck_new_cut_evidence_scout_review_only_targets_keep_607"
        next_action = "review_internal_targets_and_collect_new_trace_before_any_cut"
    else:
        status = "topdeck_new_cut_evidence_scout_learning_targets_only_keep_607"
        next_action = "collect_external_or_new_trace_evidence_for_drc_nonanchor_cut"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_topdeck_new_cut_evidence_scout",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "selected_next_route_from_router": selected_route,
            "router_selected_topdeck_new_cut_evidence_scout": route_matches,
            "primary_target": primary_target.get("card_name") or "",
            "primary_target_model_status": primary_target.get("model_status") or "",
            "hard_blocked_same_lane_slot_count": len(hard_blocked_slots),
            "internal_candidate_count": len(targets),
            "reviewable_internal_evidence_target_count": len(targets),
            "blocked_internal_near_miss_count": len(blocked),
            "safe_cut_ready_count": 0,
            "matrix_candidate_row_eligible_count": 0,
            "microbenchmark_runnable_count": 0,
            "candidate_deck_materialization_allowed_now": False,
            "forced_access_allowed_now": False,
            "structure_matrix_allowed_now": False,
            "natural_battle_gate_allowed_now": False,
            "promotion_allowed_now": False,
            "missing_inputs": missing,
            "recommended_next_action": next_action,
        },
        "deckbuilding_priority_rules": deckbuilding_priority_rules(value_model),
        "external_research_context": EXTERNAL_RESEARCH_CONTEXT,
        "hard_blocked_same_lane_slots": hard_blocked_slots,
        "internal_evidence_targets": targets,
        "blocked_internal_near_misses": blocked,
        "evidence_requests": [] if missing else evidence_requests(
            primary_target=primary_target,
            hard_blocked_slots=hard_blocked_slots,
            internal_targets=targets,
        ),
        "source_evidence": {
            "post_named_router_summary": router_summary,
            "nonanchor_model_summary": summary(nonanchor_model),
            "trace_cut_expander_summary": summary(trace_cut_expander),
            "value_model_summary": summary(value_model),
            "exposure_profile_summary": as_dict(exposure_profile.get("scan_summary")),
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "allow_deck_mutation_now": False,
            "allow_candidate_materialization_now": False,
            "allow_structure_matrix_now": False,
            "allow_forced_access_now": False,
            "allow_natural_battle_gate_now": False,
            "promotion_allowed": False,
            "reason": (
                "The router selected a topdeck cut-evidence scout, but the current "
                "non-anchor model has no safe cut. Internal targets, if any, are "
                "review-only evidence work and do not authorize a deck change."
            )
            if not missing
            else "At least one required source report is missing.",
            "next_actions": [
                next_action,
                "do_not_mutate_deck_607",
                "do_not_promote_mana_vault_or_the_one_ring_without_new_same_lane_cut_evidence",
                "do_not_open_natural_battle_gate_until_safe_cut_and_matrix_rows_exist",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = summary(payload)
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Topdeck New Cut Evidence Scout",
        "",
        f"- Generated at: `{payload.get('generated_at')}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload.get('status')}`",
        f"- Router route: `{summary_row.get('selected_next_route_from_router')}`",
        f"- Primary target: `{summary_row.get('primary_target')}`",
        f"- Hard-blocked same-lane slots: `{summary_row.get('hard_blocked_same_lane_slot_count')}`",
        f"- Internal review-only targets: `{summary_row.get('reviewable_internal_evidence_target_count')}`",
        f"- Safe cut ready: `{summary_row.get('safe_cut_ready_count')}`",
        f"- Matrix candidate rows: `{summary_row.get('matrix_candidate_row_eligible_count')}`",
        f"- Natural battle gate allowed: `{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    rules = as_dict(payload.get("deckbuilding_priority_rules"))
    lines.extend(["", "## Deckbuilding Priority Rules", ""])
    lines.append(f"- land_quantity_floor: `{rules.get('land_quantity_floor')}`")
    lines.append(f"- ramp_quantity_floor: `{rules.get('ramp_quantity_floor')}`")
    lines.append(f"- mana_sources_land_plus_ramp_floor: `{rules.get('mana_sources_land_plus_ramp_floor')}`")
    for rule in as_list(rules.get("policy")):
        lines.append(f"- {rule}")
    lines.extend(["", "## Hard-Blocked Same-Lane Slots", ""])
    for row in as_list(payload.get("hard_blocked_same_lane_slots")):
        if not isinstance(row, Mapping):
            continue
        blockers = ", ".join(as_list(row.get("hard_stop_blockers"))[:6])
        lines.append(
            f"- `{row.get('card_name')}` ({row.get('lane')}): exposure=`{row.get('unique_exposure_count')}` blockers={blockers}"
        )
    lines.extend(["", "## Internal Evidence Targets", ""])
    if not as_list(payload.get("internal_evidence_targets")):
        lines.append("- none")
    for row in as_list(payload.get("internal_evidence_targets")):
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "- `{}`: `{}` value=`{}` exposure=`{}` lanes=`{}`".format(
                row.get("card_name"),
                row.get("evidence_status"),
                row.get("value_score"),
                row.get("unique_exposure_count"),
                ",".join(as_list(row.get("lanes"))),
            )
        )
    lines.extend(["", "## Blocked Near Misses", ""])
    for row in as_list(payload.get("blocked_internal_near_misses"))[:8]:
        if not isinstance(row, Mapping):
            continue
        lines.append(
            "- `{}`: value=`{}` exposure=`{}` blockers=`{}`".format(
                row.get("card_name"),
                row.get("value_score"),
                row.get("unique_exposure_count"),
                ",".join(as_list(row.get("blocked_reasons"))[:6]),
            )
        )
    lines.extend(["", "## Evidence Requests", ""])
    for row in as_list(payload.get("evidence_requests")):
        if not isinstance(row, Mapping):
            continue
        lines.append(f"- `{row.get('request_key')}`: `{row.get('scout_status')}`")
    lines.extend(["", "## External Research Context", ""])
    for row in as_list(payload.get("external_research_context")):
        if not isinstance(row, Mapping):
            continue
        lines.append(f"- `{row.get('source')}`: {row.get('url')}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision.get('keep_607_as_protected_baseline')).lower()}`")
    lines.append(f"- allow_deck_mutation_now: `{str(decision.get('allow_deck_mutation_now')).lower()}`")
    lines.append(f"- allow_candidate_materialization_now: `{str(decision.get('allow_candidate_materialization_now')).lower()}`")
    lines.append(f"- allow_structure_matrix_now: `{str(decision.get('allow_structure_matrix_now')).lower()}`")
    lines.append(f"- allow_forced_access_now: `{str(decision.get('allow_forced_access_now')).lower()}`")
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
    parser.add_argument("--post-named-router", type=Path, default=DEFAULT_POST_NAMED_ROUTER)
    parser.add_argument("--nonanchor-model", type=Path, default=DEFAULT_NONANCHOR_MODEL)
    parser.add_argument("--trace-cut-expander", type=Path, default=DEFAULT_TRACE_CUT_EXPANDER)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--exposure-profile", type=Path, default=DEFAULT_EXPOSURE_PROFILE)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "exposure_profile": args.exposure_profile,
        "nonanchor_model": args.nonanchor_model,
        "post_named_router": args.post_named_router,
        "trace_cut_expander": args.trace_cut_expander,
        "value_model": args.value_model,
    }
    payload = build_report(
        post_named_router=read_json(args.post_named_router),
        nonanchor_model=read_json(args.nonanchor_model),
        trace_cut_expander=read_json(args.trace_cut_expander),
        value_model=read_json(args.value_model),
        exposure_profile=read_json(args.exposure_profile),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "primary_target": payload["summary"]["primary_target"],
                "internal_candidate_count": payload["summary"]["internal_candidate_count"],
                "safe_cut_ready_count": payload["summary"]["safe_cut_ready_count"],
                "json": rel(json_path),
                "markdown": rel(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
