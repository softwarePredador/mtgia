#!/usr/bin/env python3
"""Synthesize the next Lorehold shell contract without mutating deck 607.

This read-only artifact is the deckbuilder-facing bridge between external
Commander learning and the current protected 607 evidence. It decides whether
the next shell is materializable, which cards are learning-only, which mana and
topdeck floors are protected, and what evidence must exist before any battle
gate can run.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CURRENT_BEST = REPORT_DIR / "lorehold_current_best_baseline_synthesis_20260705_current.json"
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_ENGINE_CONTRACT = (
    REPORT_DIR / "lorehold_guttersnipe_storm_kiln_hypothesis_contract_20260705_current_relearn.json"
)
DEFAULT_STAPLE_ACCESSIBILITY = (
    REPORT_DIR / "lorehold_staple_accessibility_freshness_audit_20260705_current.json"
)
DEFAULT_SIDECAR_CUT_PLANNER = (
    REPORT_DIR / "lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json"
)
DEFAULT_GAP_FLOOR_TRACE_MINER = (
    REPORT_DIR / "lorehold_gap_floor_trace_miner_20260705_current.json"
)
DEFAULT_ARTIFACT_AUDIT = (
    REPORT_DIR / "lorehold_artifact_contract_audit_20260705_governed_learning_artifacts_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_next_shell_contract_synthesis_20260705_current"

SHELL_KEY = "engine_preserving_pressure_conversion_shell_v1"
TARGET_ROUTE_KEY = "guttersnipe_storm_kiln_engine_preserving_pair"
PROTECTED_ANCHORS = [
    "Bender's Waterskin",
    "Victory Chimes",
    "Molecule Man",
    "The Scarlet Witch",
    "The Mind Stone",
    "Insurrection",
    "Storm Herd",
    "Creative Technique",
]

EXTERNAL_LEARNING_SNAPSHOT = {
    "checked_at": "2026-07-05",
    "sources": [
        {
            "source": "Wizards Commander banned list",
            "url": "https://magic.wizards.com/en/banned-restricted-list",
            "learning": (
                "Commander legality is an entry gate. Mana Vault and The One Ring "
                "are not deck-ready just because they are legal."
            ),
        },
        {
            "source": "Scryfall named-card legalities",
            "url": "https://scryfall.com",
            "learning": (
                "Mana Vault, The One Ring, Guttersnipe, and Storm-Kiln Artist are "
                "Commander-legal in the current external snapshot."
            ),
        },
        {
            "source": "EDHREC Lorehold optimized spellslinger",
            "url": "https://edhrec.com/average-decks/lorehold-the-historian/optimized/spellslinger",
            "learning": (
                "Public Lorehold spellslinger lists support Storm-Kiln Artist and "
                "spell-pressure cards as ideas, but popularity is priority evidence, "
                "not promotion permission."
            ),
        },
    ],
    "card_signals": [
        {
            "card_name": "Guttersnipe",
            "commander_legal": True,
            "public_role": "noncombat spell pressure",
            "internal_position": "target_add_learning_candidate",
        },
        {
            "card_name": "Storm-Kiln Artist",
            "commander_legal": True,
            "public_role": "spell-chain mana conversion",
            "internal_position": "target_add_learning_candidate",
        },
        {
            "card_name": "Mana Vault",
            "commander_legal": True,
            "public_role": "fast mana staple",
            "internal_position": "learning_only_blocked_prior_gate",
        },
        {
            "card_name": "The One Ring",
            "commander_legal": True,
            "public_role": "draw/protection resource engine",
            "internal_position": "learning_only_blocked_prior_gate",
        },
    ],
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


def card_rows_by_name(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for row in as_list(payload.get("cards")):
        if isinstance(row, Mapping) and row.get("card_name"):
            rows[str(row["card_name"])] = dict(row)
    return rows


def value_mana_floor(value_model: Mapping[str, Any]) -> dict[str, Any]:
    mana = as_dict(summary(value_model).get("mana_foundation"))
    return {
        "land_quantity": as_int(mana.get("land_quantity")),
        "ramp_quantity": as_int(mana.get("ramp_quantity")),
        "mana_sources_land_plus_ramp": as_int(mana.get("mana_sources_land_plus_ramp")),
        "artifact_ramp_quantity": as_int(mana.get("artifact_ramp_quantity")),
        "spell_ramp_quantity": as_int(mana.get("instant_sorcery_ramp_quantity")),
        "interpretation": mana.get("interpretation") or "",
        "land_groups": as_dict(mana.get("land_groups")),
    }


def floor_blocker_names(
    sidecar_cut_planner: Mapping[str, Any],
    gap_floor_trace_miner: Mapping[str, Any],
) -> list[str]:
    names = [str(name) for name in as_list(summary(sidecar_cut_planner).get("floor_trace_cut_blocker_names"))]
    if names:
        return names
    return [
        str(row.get("card_name"))
        for row in as_list(gap_floor_trace_miner.get("target_floor_summaries"))
        if isinstance(row, Mapping) and row.get("card_name")
    ]


def staple_learning_rows(staple_accessibility: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(staple_accessibility.get("cards")):
        if not isinstance(row, Mapping):
            continue
        rows.append(
            {
                "card_name": row.get("card_name") or "",
                "app_accessibility_label": row.get("app_accessibility_label") or "",
                "owned": bool(as_dict(row.get("collection")).get("owned")),
                "commander_legal": bool(as_dict(row.get("external")).get("commander_legal")),
                "game_changer": bool(as_dict(row.get("external")).get("game_changer")),
                "readiness_status": as_dict(row.get("hypothesis")).get("readiness_status") or "",
                "promotion_decision": as_dict(row.get("promotion")).get("decision") or "",
                "next_action": row.get("next_action") or "",
            }
        )
    return rows


def target_add_rows(engine_contract: Mapping[str, Any]) -> list[dict[str, Any]]:
    contract = as_dict(engine_contract.get("candidate_package_contract"))
    route = as_dict(engine_contract.get("route_evidence"))
    blocker_set = {str(item) for item in as_list(route.get("blockers"))}
    rows = []
    for card_name in as_list(contract.get("adds")):
        card_blockers = []
        if str(card_name) == "Guttersnipe":
            card_blockers = sorted(
                blocker for blocker in blocker_set if "guttersnipe" in blocker or "pressure" in blocker
            )
        elif str(card_name) == "Storm-Kiln Artist":
            card_blockers = sorted(
                blocker for blocker in blocker_set if "storm_kiln" in blocker or "conversion" in blocker
            )
        rows.append(
            {
                "card_name": str(card_name),
                "role": "noncombat_spell_pressure"
                if str(card_name) == "Guttersnipe"
                else "spell_chain_mana_conversion",
                "learning_position": "candidate_add_after_named_safe_cuts",
                "current_blockers": card_blockers,
            }
        )
    return rows


def protected_core(
    sidecar_cut_planner: Mapping[str, Any],
    gap_floor_trace_miner: Mapping[str, Any],
) -> dict[str, Any]:
    blockers = floor_blocker_names(sidecar_cut_planner, gap_floor_trace_miner)
    return {
        "protected_anchors": PROTECTED_ANCHORS,
        "floor_trace_cut_blockers": blockers,
        "combined_never_generic_cut": sorted(set(PROTECTED_ANCHORS + blockers)),
        "rule": (
            "These cards cannot be treated as generic cuts. A future replacement "
            "must be named, same-lane, floor-preserving, and gate-tested."
        ),
    }


def validation_errors(
    *,
    current_best: Mapping[str, Any],
    value_model: Mapping[str, Any],
    engine_contract: Mapping[str, Any],
    artifact_audit: Mapping[str, Any],
) -> list[str]:
    errors: list[str] = []
    current_summary = summary(current_best)
    artifact_gate = as_dict(artifact_audit.get("continuation_gate"))
    mana_floor = value_mana_floor(value_model)
    engine_summary = summary(engine_contract)

    if current_best.get("status") != "current_best_baseline_synthesis_keep_607":
        errors.append("current-best synthesis does not keep deck_607")
    if current_summary.get("top_deck_is_607") is not True:
        errors.append("current-best synthesis does not rank deck_607 first")
    if as_int(current_summary.get("current_positive_signal_count")) != 0:
        errors.append("current positive promotion or materialization signals remain")
    if artifact_gate.get("artifact_contract_status") != "pass":
        errors.append("artifact contract is not pass")
    if as_int(summary(artifact_audit).get("unknown_or_invalid_count")) != 0:
        errors.append("artifact audit still has unknown or invalid artifacts")
    if mana_floor["land_quantity"] != 34 or mana_floor["ramp_quantity"] != 15:
        errors.append("value model mana floor is not the protected 34 land / 15 ramp baseline")
    if engine_summary.get("target_route_key") != TARGET_ROUTE_KEY:
        errors.append("engine contract does not target the Guttersnipe + Storm-Kiln route")
    return errors


def materialization_status(
    *,
    validation: Sequence[str],
    engine_contract: Mapping[str, Any],
) -> tuple[str, bool, bool]:
    engine_summary = summary(engine_contract)
    if validation:
        return ("next_shell_contract_blocked_review_required", False, False)
    ready_for_matrix = engine_summary.get("structure_matrix_allowed_now") is True
    enough_cuts = as_int(engine_summary.get("available_named_seed_safe_cut_count")) >= as_int(
        engine_summary.get("required_cut_count")
    )
    if ready_for_matrix and enough_cuts:
        return ("next_shell_contract_ready_for_structure_matrix_not_deck_action", True, False)
    return ("next_shell_contract_written_not_materializable_keep_607", False, False)


def build_report(
    *,
    current_best: Mapping[str, Any],
    value_model: Mapping[str, Any],
    engine_contract: Mapping[str, Any],
    staple_accessibility: Mapping[str, Any],
    sidecar_cut_planner: Mapping[str, Any],
    gap_floor_trace_miner: Mapping[str, Any],
    artifact_audit: Mapping[str, Any],
    paths: Mapping[str, Path],
) -> dict[str, Any]:
    current_summary = summary(current_best)
    value_summary = summary(value_model)
    engine_summary = summary(engine_contract)
    planner_summary = summary(sidecar_cut_planner)
    artifact_summary = summary(artifact_audit)
    artifact_gate = as_dict(artifact_audit.get("continuation_gate"))
    validation = validation_errors(
        current_best=current_best,
        value_model=value_model,
        engine_contract=engine_contract,
        artifact_audit=artifact_audit,
    )
    status, materialization_allowed, deck_action_allowed = materialization_status(
        validation=validation,
        engine_contract=engine_contract,
    )
    mana_floor = value_mana_floor(value_model)
    core = protected_core(sidecar_cut_planner, gap_floor_trace_miner)
    staple_rows = staple_learning_rows(staple_accessibility)
    target_adds = target_add_rows(engine_contract)
    required_cut_count = as_int(engine_summary.get("required_cut_count"))
    available_cuts = as_int(engine_summary.get("available_named_seed_safe_cut_count"))

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_next_shell_contract_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "current_baseline": "deck_607",
        "status": status,
        "source_reports": {key: rel(path) for key, path in sorted(paths.items())},
        "summary": {
            "decision_status": status,
            "shell_key": SHELL_KEY,
            "target_route_key": TARGET_ROUTE_KEY,
            "target_adds": [row["card_name"] for row in target_adds],
            "artifact_contract_status": artifact_gate.get("artifact_contract_status"),
            "artifact_count": as_int(artifact_summary.get("artifact_count")),
            "unknown_or_invalid_count": as_int(artifact_summary.get("unknown_or_invalid_count")),
            "current_best_status": current_best.get("status") or "",
            "top_deck_is_607": bool(current_summary.get("top_deck_is_607")),
            "current_positive_signal_count": as_int(current_summary.get("current_positive_signal_count")),
            "land_quantity_floor": mana_floor["land_quantity"],
            "ramp_quantity_floor": mana_floor["ramp_quantity"],
            "mana_sources_land_plus_ramp_floor": mana_floor["mana_sources_land_plus_ramp"],
            "floor_trace_cut_blocker_count": len(core["floor_trace_cut_blockers"]),
            "protected_anchor_count": len(core["protected_anchors"]),
            "learning_only_staple_count": len(staple_rows),
            "required_cut_count": required_cut_count,
            "available_named_seed_safe_cut_count": available_cuts,
            "cut_shortage": max(0, required_cut_count - available_cuts),
            "sidecar_safe_cut_ready_count": as_int(planner_summary.get("safe_cut_ready_count")),
            "sidecar_matrix_candidate_row_eligible_count": as_int(
                planner_summary.get("matrix_candidate_row_eligible_count")
            ),
            "candidate_deck_materialization_allowed_now": materialization_allowed,
            "structure_matrix_allowed_now": bool(engine_summary.get("structure_matrix_allowed_now"))
            and materialization_allowed,
            "natural_battle_gate_allowed_now": False,
            "deck_action_allowed_now": deck_action_allowed,
            "promotion_allowed_now": False,
            "validation_error_count": len(validation),
            "recommended_next_action": (
                "mine_two_named_seed_safe_nonanchor_cuts_for_engine_preserving_shell"
                if not validation and not materialization_allowed
                else "run_structure_matrix_review_before_any_battle_gate"
                if materialization_allowed
                else "review_contract_errors_before_learning_execution"
            ),
        },
        "shell_contract": {
            "shell_key": SHELL_KEY,
            "purpose": (
                "Learn whether an engine-preserving pressure/conversion pair can "
                "challenge protected deck 607 without reducing mana, topdeck, miracle, "
                "protection, or fast-pressure floors."
            ),
            "target_adds": target_adds,
            "mana_floor": mana_floor,
            "role_profile": as_dict(value_summary.get("role_profile")),
            "lane_profile": as_dict(value_summary.get("lane_profile")),
            "protected_core": core,
            "learning_only_staples": staple_rows,
            "external_learning_snapshot": EXTERNAL_LEARNING_SNAPSHOT,
            "materialization_requirements": [
                "find_two_named_seed_safe_nonanchor_cuts",
                "do_not_cut_floor_trace_blockers_or_protected_anchors_as_generic_slots",
                "preserve_34_lands_15_ramp_49_land_plus_ramp_sources",
                "preserve_topdeck_miracle_and_lorehold_upkeep_rummage_floors",
                "show_direct_guttersnipe_damage_events_and_storm_kiln_treasure_events",
                "tie_or_improve_winota_fast_pressure_slice",
                "pass_structure_matrix_before_any_equal_battle_gate",
                "run_same_seed_same_opponent_gate_against_current_deck_607",
            ],
        },
        "evidence": {
            "current_best_summary": current_summary,
            "engine_contract_summary": engine_summary,
            "sidecar_cut_planner_summary": planner_summary,
            "staple_accessibility_summary": summary(staple_accessibility),
        },
        "decision": {
            "keep_607_as_protected_baseline": not validation,
            "deck_action_allowed": deck_action_allowed,
            "candidate_deck_materialization_allowed_now": materialization_allowed,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": (
                "The next learnable shell is Guttersnipe plus Storm-Kiln Artist, but "
                "current evidence has zero named seed-safe cuts and generic staples "
                "remain learning-only. Deck 607 stays protected."
            )
            if not validation and not materialization_allowed
            else "The shell has enough cut evidence for structure-matrix review, but not for deck action."
            if materialization_allowed
            else "One or more upstream contracts failed; review before any learning execution.",
            "next_actions": [
                "do_not_mutate_deck_607",
                "mine two named seed-safe non-anchor cuts for the engine-preserving pair",
                "keep Mana Vault and The One Ring as learning-only until new same-lane trace exists",
                "re-run artifact and current-best synthesis after the shell contract is generated",
            ],
        },
        "validation": {
            "status": "pass" if not validation else "fail",
            "errors": validation,
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary_row = as_dict(payload.get("summary"))
    contract = as_dict(payload.get("shell_contract"))
    decision = as_dict(payload.get("decision"))
    lines = [
        "# Lorehold Next Shell Contract Synthesis",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "- Deck 607 mutated: `false`",
        f"- Status: `{payload['status']}`",
        f"- Shell key: `{summary_row.get('shell_key')}`",
        f"- Target route: `{summary_row.get('target_route_key')}`",
        f"- Target adds: `{', '.join(as_list(summary_row.get('target_adds')))}`",
        f"- Mana floor: `{summary_row.get('land_quantity_floor')}` lands, "
        f"`{summary_row.get('ramp_quantity_floor')}` ramp, "
        f"`{summary_row.get('mana_sources_land_plus_ramp_floor')}` land+ramp sources",
        f"- Available named seed-safe cuts: `{summary_row.get('available_named_seed_safe_cut_count')}`",
        f"- Cut shortage: `{summary_row.get('cut_shortage')}`",
        f"- Candidate deck materialization allowed now: "
        f"`{str(summary_row.get('candidate_deck_materialization_allowed_now')).lower()}`",
        f"- Natural battle gate allowed now: "
        f"`{str(summary_row.get('natural_battle_gate_allowed_now')).lower()}`",
        f"- Promotion allowed now: `{str(summary_row.get('promotion_allowed_now')).lower()}`",
        f"- Recommended next action: `{summary_row.get('recommended_next_action')}`",
        "",
        "## Source Reports",
        "",
    ]
    for key, path in sorted(as_dict(payload.get("source_reports")).items()):
        lines.append(f"- `{key}`: `{path}`")
    lines.extend(["", "## Target Adds", ""])
    for row in as_list(contract.get("target_adds")):
        lines.append(
            f"- `{row.get('card_name')}`: role `{row.get('role')}`, "
            f"position `{row.get('learning_position')}`, blockers "
            f"`{', '.join(as_list(row.get('current_blockers'))) or '-'}`"
        )
    lines.extend(["", "## Protected Core", ""])
    core = as_dict(contract.get("protected_core"))
    lines.append(
        "- Protected anchors: "
        + ", ".join(f"`{name}`" for name in as_list(core.get("protected_anchors")))
    )
    lines.append(
        "- Floor-trace cut blockers: "
        + ", ".join(f"`{name}`" for name in as_list(core.get("floor_trace_cut_blockers")))
    )
    lines.extend(["", "## Learning-Only Staples", ""])
    for row in as_list(contract.get("learning_only_staples")):
        lines.append(
            f"- `{row.get('card_name')}`: `{row.get('app_accessibility_label')}`, "
            f"owned `{str(row.get('owned')).lower()}`, readiness `{row.get('readiness_status')}`, "
            f"promotion `{row.get('promotion_decision')}`"
        )
    lines.extend(["", "## Materialization Requirements", ""])
    for item in as_list(contract.get("materialization_requirements")):
        lines.append(f"- `{item}`")
    lines.extend(["", "## External Learning Snapshot", ""])
    for source in as_list(as_dict(contract.get("external_learning_snapshot")).get("sources")):
        lines.append(f"- `{source.get('source')}`: {source.get('url')} - {source.get('learning')}")
    lines.extend(["", "## Decision", ""])
    lines.append(
        f"- keep_607_as_protected_baseline: "
        f"`{str(decision.get('keep_607_as_protected_baseline')).lower()}`"
    )
    lines.append(f"- deck_action_allowed: `{str(decision.get('deck_action_allowed')).lower()}`")
    lines.append(
        "- candidate_deck_materialization_allowed_now: "
        f"`{str(decision.get('candidate_deck_materialization_allowed_now')).lower()}`"
    )
    lines.append(f"- promotion_allowed: `{str(decision.get('promotion_allowed')).lower()}`")
    lines.append(f"- reason: {decision.get('reason')}")
    lines.extend(["", "## Validation", ""])
    validation = as_dict(payload.get("validation"))
    if validation.get("errors"):
        for error in as_list(validation.get("errors")):
            lines.append(f"- ERROR: {error}")
    else:
        lines.append("- PASS: next shell is documented as learning-only under current evidence.")
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
    parser.add_argument("--current-best", type=Path, default=DEFAULT_CURRENT_BEST)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--engine-contract", type=Path, default=DEFAULT_ENGINE_CONTRACT)
    parser.add_argument("--staple-accessibility", type=Path, default=DEFAULT_STAPLE_ACCESSIBILITY)
    parser.add_argument("--sidecar-cut-planner", type=Path, default=DEFAULT_SIDECAR_CUT_PLANNER)
    parser.add_argument("--gap-floor-trace-miner", type=Path, default=DEFAULT_GAP_FLOOR_TRACE_MINER)
    parser.add_argument("--artifact-audit", type=Path, default=DEFAULT_ARTIFACT_AUDIT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = {
        "artifact_audit": args.artifact_audit,
        "current_best": args.current_best,
        "engine_contract": args.engine_contract,
        "gap_floor_trace_miner": args.gap_floor_trace_miner,
        "sidecar_cut_planner": args.sidecar_cut_planner,
        "staple_accessibility": args.staple_accessibility,
        "value_model": args.value_model,
    }
    payload = build_report(
        current_best=read_json(args.current_best),
        value_model=read_json(args.value_model),
        engine_contract=read_json(args.engine_contract),
        staple_accessibility=read_json(args.staple_accessibility),
        sidecar_cut_planner=read_json(args.sidecar_cut_planner),
        gap_floor_trace_miner=read_json(args.gap_floor_trace_miner),
        artifact_audit=read_json(args.artifact_audit),
        paths=paths,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 1 if payload["validation"]["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
