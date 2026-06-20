#!/usr/bin/env python3
"""Audit current unknown battle cards against focused-template backlog plans."""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from collections import Counter
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
SERVER_BIN = REPO_ROOT / "server/bin"
REPORTS_DIR = REPO_ROOT / "docs/hermes-analysis/master_optimizer_reports"


BACKLOG_PLAN: dict[str, dict[str, Any]] = {
    "Banishing Knack": {
        "families": ["tap_untap_bounce_granted_ability"],
        "plan_status": "template_required",
        "next_fixture": "grant_activated_bounce_ability_replay",
        "owner": "battle-template-backlog",
    },
    "Flash Photography": {
        "families": ["copy_permanent_with_flash_or_flashback"],
        "plan_status": "template_required",
        "next_fixture": "copy_permanent_flash_timing_and_flashback_replay",
        "owner": "battle-template-backlog",
    },
    "Heroes' Hangout": {
        "families": ["impulse_topdeck_or_library_zone"],
        "plan_status": "template_required",
        "next_fixture": "modal_impulse_play_until_next_turn_replay",
        "owner": "battle-template-backlog",
    },
    "Hidden Strings": {
        "families": ["tap_untap_cipher_trigger"],
        "plan_status": "template_required",
        "next_fixture": "tap_untap_cipher_trigger_replay",
        "owner": "battle-template-backlog",
    },
    "Kindle the Inner Flame": {
        "families": ["copy_token_with_delayed_sacrifice", "graveyard_recast_replacement"],
        "plan_status": "template_required",
        "next_fixture": "copy_token_delayed_sacrifice_flashback_replay",
        "owner": "battle-template-backlog",
    },
    "Liquimetal Coating": {
        "families": ["type_change_continuous_effect"],
        "plan_status": "template_required",
        "next_fixture": "temporary_artifact_type_change_replay",
        "owner": "battle-template-backlog",
    },
    "Opera Love Song": {
        "families": ["impulse_topdeck_or_library_zone"],
        "plan_status": "template_required",
        "next_fixture": "instant_impulse_play_until_next_turn_replay",
        "owner": "battle-template-backlog",
    },
    "Submerge": {
        "families": ["alternative_cost_library_bounce"],
        "plan_status": "template_required",
        "next_fixture": "alternative_cost_top_of_library_bounce_replay",
        "owner": "battle-template-backlog",
    },
    "Ashnod's Transmogrant": {
        "families": ["counter_manipulation_and_type_change"],
        "plan_status": "template_required",
        "next_fixture": "counter_and_artifact_type_change_replay",
        "owner": "battle-template-backlog",
    },
    "Candelabra of Tawnos": {
        "families": ["utility_artifact_untap_x_lands"],
        "plan_status": "template_required",
        "next_fixture": "x_land_untap_activated_ability_replay",
        "owner": "battle-template-backlog",
    },
    "Clown Car": {
        "families": ["x_cost_counters_vehicle_token"],
        "plan_status": "template_required",
        "next_fixture": "x_cost_vehicle_counters_and_token_replay",
        "owner": "battle-template-backlog",
    },
    "Codex Shredder": {
        "families": ["mill_and_graveyard_return"],
        "plan_status": "template_required",
        "next_fixture": "mill_then_graveyard_return_activated_ability_replay",
        "owner": "battle-template-backlog",
    },
    "Copy Artifact": {
        "families": ["copy_artifact_static_as_enters"],
        "plan_status": "template_required",
        "next_fixture": "copy_artifact_as_enters_replay",
        "owner": "battle-template-backlog",
    },
    "Cryptic Coat": {
        "families": ["manifest_cloak_equipment"],
        "plan_status": "template_required",
        "next_fixture": "cloak_equipment_etb_attach_replay",
        "owner": "battle-template-backlog",
    },
    "Cursed Windbreaker": {
        "families": ["manifest_cloak_equipment"],
        "plan_status": "template_required",
        "next_fixture": "manifest_cloak_equipment_static_grant_replay",
        "owner": "battle-template-backlog",
    },
    "Dissection Tools": {
        "families": ["manifest_cloak_equipment"],
        "plan_status": "template_required",
        "next_fixture": "manifest_cloak_equipment_lifelink_replay",
        "owner": "battle-template-backlog",
    },
    "Firestorm": {
        "families": ["additional_cost_discard_multi_target_damage"],
        "plan_status": "template_required",
        "next_fixture": "discard_x_multi_target_damage_replay",
        "owner": "battle-template-backlog",
    },
    "God-Pharaoh's Statue": {
        "families": ["static_tax_and_opponent_life_loss"],
        "plan_status": "template_required",
        "next_fixture": "static_opponent_tax_and_end_step_life_loss_replay",
        "owner": "battle-template-backlog",
    },
    "Mine Collapse": {
        "families": ["alternative_cost_sacrifice_mountain_damage"],
        "plan_status": "template_required",
        "next_fixture": "sacrifice_mountain_alternative_cost_damage_replay",
        "owner": "battle-template-backlog",
    },
    "Nevermore": {
        "families": ["static_named_card_cast_restriction"],
        "plan_status": "template_required",
        "next_fixture": "named_card_cast_restriction_replay",
        "owner": "battle-template-backlog",
    },
    "Out of Time": {
        "families": ["phase_out_mass_removal_counters"],
        "plan_status": "template_required",
        "next_fixture": "mass_phase_out_duration_counters_replay",
        "owner": "battle-template-backlog",
    },
    "Power Artifact": {
        "families": ["cost_reduction_static_aura"],
        "plan_status": "template_required",
        "next_fixture": "enchanted_artifact_activation_cost_reduction_replay",
        "owner": "battle-template-backlog",
    },
    "Reality Acid": {
        "families": ["vanishing_sacrifice_trigger_removal"],
        "plan_status": "template_required",
        "next_fixture": "vanishing_sacrifice_enchanted_permanent_replay",
        "owner": "battle-template-backlog",
    },
    "Scroll of Fate": {
        "families": ["manifest_from_hand_activated_ability"],
        "plan_status": "template_required",
        "next_fixture": "manifest_card_from_hand_replay",
        "owner": "battle-template-backlog",
    },
    "Stoke the Flames": {
        "families": ["convoke_damage"],
        "plan_status": "template_required",
        "next_fixture": "convoke_damage_payment_replay",
        "owner": "battle-template-backlog",
    },
    "Sudden Shock": {
        "families": ["split_second_damage"],
        "plan_status": "template_required",
        "next_fixture": "split_second_damage_priority_lock_replay",
        "owner": "battle-template-backlog",
    },
    "Thorn of Amethyst": {
        "families": ["static_noncreature_tax"],
        "plan_status": "template_required",
        "next_fixture": "static_noncreature_spell_tax_replay",
        "owner": "battle-template-backlog",
    },
    "Tragic Arrogance": {
        "families": ["modal_mass_sacrifice_selection"],
        "plan_status": "template_required",
        "next_fixture": "per_player_permanent_type_choice_sacrifice_replay",
        "owner": "battle-template-backlog",
    },
    "Tyvar, Jubilant Brawler": {
        "families": ["planeswalker_static_and_activated_graveyard_ability"],
        "plan_status": "template_required",
        "next_fixture": "planeswalker_static_haste_and_graveyard_activation_replay",
        "owner": "battle-template-backlog",
    },
}


@dataclass
class BacklogItem:
    name: str
    type_line: str
    effect: str
    oracle_sample: str
    current_inferred_families: list[str]
    reviewed_families: list[str]
    focused_template_matches: list[str]
    plan_status: str
    waiver_status: str
    owner: str
    next_fixture: str
    flags: list[str]
    decks: list[str]
    risk_flags: list[str]


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def latest_coverage_json() -> Path:
    candidates = sorted(
        REPORTS_DIR.glob("battle_effect_coverage_audit_*runtime*.json"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    if not candidates:
        raise FileNotFoundError("No runtime battle effect coverage JSON found")
    return candidates[0]


def focused_template_matches(focused_module, card: dict[str, Any], families: list[str]) -> list[str]:
    draft = focused_module.DraftRecord(
        run_id="unknown_template_backlog_audit",
        card_name=str(card.get("name") or ""),
        oracle_id=None,
        set_code="",
        draft_rule_key="unknown_template_backlog_audit",
        proposed_status="needs_review",
        confidence="low",
        roles=[],
        effect_families=families,
        risk_flags=list(card.get("flags") or []),
        draft={"oracle_text_excerpt": str(card.get("oracle_sample") or "")},
    )
    matches: list[str] = []
    for name in sorted(dir(focused_module)):
        if not name.startswith("supports_") or not name.endswith("_template"):
            continue
        func = getattr(focused_module, name)
        try:
            if func(draft):
                matches.append(name)
        except Exception:
            continue
    return matches


def build_item(review_module, focused_module, card: dict[str, Any]) -> BacklogItem:
    name = str(card.get("name") or "")
    oracle_sample = str(card.get("oracle_sample") or "")
    current_families = review_module.infer_effect_families_from_text(oracle_sample)
    plan = BACKLOG_PLAN.get(name, {})
    reviewed_families = sorted(str(item) for item in plan.get("families", []))
    match_families = sorted(set(current_families) | set(reviewed_families))
    matches = focused_template_matches(focused_module, card, match_families)
    plan_status = str(plan.get("plan_status") or "missing_plan")
    if matches and plan_status == "template_required":
        plan_status = "focused_template_ready"
    waiver_status = str(plan.get("waiver_status") or "none")
    risk_flags: list[str] = []
    if not current_families:
        risk_flags.append("missing_current_inference")
    if not reviewed_families:
        risk_flags.append("missing_reviewed_family")
    if not matches:
        risk_flags.append("missing_focused_template")
    if plan_status == "missing_plan" and waiver_status == "none":
        risk_flags.append("missing_plan_or_waiver")
    return BacklogItem(
        name=name,
        type_line=str(card.get("type_line") or ""),
        effect=str(card.get("effect") or ""),
        oracle_sample=oracle_sample,
        current_inferred_families=current_families,
        reviewed_families=reviewed_families,
        focused_template_matches=matches,
        plan_status=plan_status,
        waiver_status=waiver_status,
        owner=str(plan.get("owner") or "unassigned"),
        next_fixture=str(plan.get("next_fixture") or ""),
        flags=[str(flag) for flag in card.get("flags") or []],
        decks=[str(deck) for deck in card.get("decks") or []],
        risk_flags=risk_flags,
    )


def build_audit(coverage_json: Path) -> dict[str, Any]:
    review_module = load_module(
        "manaloom_battle_rule_review_queue_for_unknown_template_audit",
        SERVER_BIN / "manaloom_battle_rule_review_queue.py",
    )
    focused_module = load_module(
        "manaloom_battle_rule_focused_evidence_for_unknown_template_audit",
        SERVER_BIN / "manaloom_battle_rule_focused_evidence.py",
    )
    coverage = json.loads(coverage_json.read_text(encoding="utf-8"))
    effect_unknown_cards = coverage.get("unknown_effect_cards") or []
    effect_unknown_status_counts = Counter(
        card.get("status") or "tracked_unknown_effect"
        for card in effect_unknown_cards
    )
    effect_unknown_source_counts = Counter(
        card.get("source") or "unknown"
        for card in effect_unknown_cards
    )
    items = [
        build_item(review_module, focused_module, card)
        for card in sorted(coverage.get("unknown_cards") or [], key=lambda row: row.get("name") or "")
    ]
    plan_status_counts = Counter(item.plan_status for item in items)
    reviewed_family_counts = Counter(
        family for item in items for family in item.reviewed_families
    )
    current_family_counts = Counter(
        family for item in items for family in item.current_inferred_families
    )
    summary = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "coverage_json": str(coverage_json),
        "unknown_cards": len(items),
        "source_unknown_cards": len(items),
        "effect_unknown_cards": len(effect_unknown_cards),
        "effect_unknown_source_counts": dict(sorted(effect_unknown_source_counts.items())),
        "effect_unknown_status_counts": dict(sorted(effect_unknown_status_counts.items())),
        "with_current_inferred_family": sum(1 for item in items if item.current_inferred_families),
        "without_current_inferred_family": sum(1 for item in items if not item.current_inferred_families),
        "with_reviewed_family": sum(1 for item in items if item.reviewed_families),
        "without_reviewed_family": sum(1 for item in items if not item.reviewed_families),
        "with_focused_template_match": sum(1 for item in items if item.focused_template_matches),
        "without_focused_template_match": sum(1 for item in items if not item.focused_template_matches),
        "with_plan_or_waiver": sum(
            1
            for item in items
            if item.plan_status != "missing_plan" or item.waiver_status != "none"
        ),
        "without_plan_or_waiver": sum(
            1
            for item in items
            if item.plan_status == "missing_plan" and item.waiver_status == "none"
        ),
        "plan_status_counts": dict(sorted(plan_status_counts.items())),
        "current_family_counts": dict(sorted(current_family_counts.items())),
        "reviewed_family_counts": dict(sorted(reviewed_family_counts.items())),
        "unknowns_without_plan_or_waiver": [
            item.name
            for item in items
            if item.plan_status == "missing_plan" and item.waiver_status == "none"
        ],
        "unknowns_without_reviewed_family": [
            item.name for item in items if not item.reviewed_families
        ],
        "unknowns_without_template": [
            item.name for item in items if not item.focused_template_matches
        ],
    }
    if summary["without_reviewed_family"] or summary["without_plan_or_waiver"]:
        summary["status"] = "review_required"
    elif summary["without_focused_template_match"]:
        summary["status"] = "focused_templates_missing"
    else:
        summary["status"] = "focused_template_backlog_ready"
    return {
        "summary": summary,
        "items": [asdict(item) for item in items],
    }


def render_list(values: list[str]) -> str:
    return ", ".join(values) if values else "-"


def render_markdown(audit: dict[str, Any]) -> str:
    summary = audit["summary"]
    rows = [
        "# Battle Unknown Template Backlog Audit",
        "",
        f"- Generated at: `{summary['generated_at']}`",
        f"- Coverage JSON: `{summary['coverage_json']}`",
        f"- Status: `{summary['status']}`",
        f"- Source-unknown cards: `{summary['source_unknown_cards']}`",
        f"- Effect-unknown cards: `{summary['effect_unknown_cards']}`",
        f"- Effect-unknown source counts: `{json.dumps(summary['effect_unknown_source_counts'], sort_keys=True)}`",
        f"- Effect-unknown status counts: `{json.dumps(summary['effect_unknown_status_counts'], sort_keys=True)}`",
        f"- With current inferred family: `{summary['with_current_inferred_family']}`",
        f"- Without current inferred family: `{summary['without_current_inferred_family']}`",
        f"- With reviewed family: `{summary['with_reviewed_family']}`",
        f"- Without reviewed family: `{summary['without_reviewed_family']}`",
        f"- With focused template match: `{summary['with_focused_template_match']}`",
        f"- Without focused template match: `{summary['without_focused_template_match']}`",
        f"- With plan or waiver: `{summary['with_plan_or_waiver']}`",
        f"- Without plan or waiver: `{summary['without_plan_or_waiver']}`",
        f"- Plan status counts: `{json.dumps(summary['plan_status_counts'], sort_keys=True)}`",
        f"- Reviewed family counts: `{json.dumps(summary['reviewed_family_counts'], sort_keys=True)}`",
        "",
        "## Per-Card Contract",
        "",
        "| Card | Current inferred families | Reviewed families | Focused template match | Plan | Owner | Next fixture | Risk flags |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for item in audit["items"]:
        rows.append(
            "| `{name}` | `{current}` | `{reviewed}` | `{templates}` | `{plan}` | `{owner}` | `{fixture}` | `{risks}` |".format(
                name=item["name"],
                current=render_list(item["current_inferred_families"]),
                reviewed=render_list(item["reviewed_families"]),
                templates=render_list(item["focused_template_matches"]),
                plan=item["plan_status"],
                owner=item["owner"],
                fixture=item["next_fixture"] or "-",
                risks=render_list(item["risk_flags"]),
            )
        )
    rows.extend(
        [
            "",
            "## Interpretation",
            "",
            "- `missing_focused_template` means the card still needs a narrow template, fixture, or waiver before promotion.",
            "- `backlog_manifest_ready` means every unknown card has a reviewed family and an explicit plan or waiver; it does not mean runtime support is complete.",
        ]
    )
    return "\n".join(rows) + "\n"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--coverage-json", type=Path, default=None)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-unplanned", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    coverage_json = args.coverage_json or latest_coverage_json()
    audit = build_audit(coverage_json)
    markdown = render_markdown(audit)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
        print(f"Markdown report: {args.output}")
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(
            json.dumps(audit, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(f"JSON report: {args.json_output}")
    if not args.output and not args.json_output:
        print(markdown)
    if args.fail_on_unplanned and audit["summary"]["without_plan_or_waiver"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
