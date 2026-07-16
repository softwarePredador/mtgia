#!/usr/bin/env python3
"""Forensic audit for one or more Hermes battle replays.

This script is intentionally more detailed than aggregate win-rate checks. It
answers: which cards were used, which rule source was trusted, which events used
needs_review/heuristic/unknown semantics, and which turn-level invariants broke.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import battle_rule_registry
import replay_decision_auditor


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_DB = battle_rule_registry.DEFAULT_DB
REPLAY_GENERATOR = SCRIPT_DIR / "battle_replay_v10_3.py"
REPORT_DIR = SCRIPT_DIR.parents[1] / "master_optimizer_reports"

SUPPORTED_EFFECTS = {
    "add_mana",
    "additional_land_play_static",
    "ad_nauseam",
    "aetherflux_lifegain",
    "aetherflux_reservoir",
    "approach",
    "aura_static_attachment",
    "attack_limit",
    "attack_tax",
    "airbend_other_creatures",
    "board_wipe",
    "blink",
    "blink_multiple",
    "brain_freeze",
    "combo",
    "composite_resolution",
    "commander",
    "cannot_lose_turn",
    "copy_creature_token",
    "copy_attached_creature_or_insect",
    "copy_permanent_etb",
    "copy_spell",
    "counter",
    "create_plant_token_plus_counters",
    "create_treasure",
    "creature",
    "damage_each_opponent",
    "damage_any_target",
    "damage_player_and_creatures",
    "damage_wipe",
    "damage_wipe_treasure",
    "deal_damage",
    "discard_trigger_modal_draw_treasure_opponent_life_loss",
    "dig_to_hand",
    "direct_damage",
    "dragons_approach",
    "draw_cards",
    "draw_engine",
    "equipment_static_attachment",
    "equipment_haste_shroud",
    "exile_artifact_enchantment_creature_convoke_wipe",
    "exile_each_opponent_nonland_until_source_leaves",
    "exile_graveyard_card_create_food",
    "exile_top_nonland_free_cast",
    "fated_clash_protect_then_destroy",
    "exile_value",
    "extra_turn",
    "finisher",
    "gift_hexproof_indestructible",
    "gift_destroy_all_creatures_return_own_destroyed_creature",
    "graveyard_flashback_grant",
    "graveyard_to_library_top",
    "hand_filter",
    "harnessed_blink",
    "hate_artifact",
    "indestructible",
    "land",
    "land_tax",
    "land_ramp",
    "land_recursion",
    "land_recursion_creature",
    "lander_token_maker",
    "life_artifact",
    "loot",
    "mill_engine",
    "modal_boros_charm",
    "overload_recursion",
    "opponent_graveyard_betrayal",
    "passive",
    "phase_out",
    "phase_creatures",
    "planeswalker",
    "pile_selection_draw",
    "protect_creature",
    "pump_all",
    "ramp_engine",
    "ramp_permanent",
    "ramp_ritual",
    "recursion",
    "redirect_removal",
    "redistribute_life_totals",
    "removal_destroy",
    "removal_exile",
    "remove_artifact_or_3dmg",
    "remove_creature",
    "remove_permanent",
    "rummage",
    "ripple_engine",
    "silence_opponents",
    "silence_spell",
    "selective_nonland_sacrifice",
    "static_cost_reduction",
    "steal_all_creatures",
    "sweeper_damage",
    "thassa_oracle",
    "token_maker",
    "topdeck_manipulation",
    "treasure_maker",
    "tutor",
    "tutor_artifact",
    "temporary_exile_return_next_end_step",
    "untap_lands",
    "untap_land_engine",
    "untap_tapped_permanent_etb_engine",
    "vow_counter_each_player_sacrifice_rest",
}

CARD_EVENT_KINDS = {
    "commander_cast",
    "creature_cast",
    "end_step_instant",
    "instant_removal",
    "land_played",
    "miracle_cast",
    "spell_cast",
    "spell_resolved",
    "trigger_resolved",
}

GAME_IMPACT_EFFECTS = {
    "additional_land_play_static",
    "aetherflux_lifegain",
    "aetherflux_reservoir",
    "approach",
    "attack_limit",
    "attack_tax",
    "airbend_other_creatures",
    "board_wipe",
    "blink_multiple",
    "brain_freeze",
    "counter",
    "cannot_lose_turn",
    "create_plant_token_plus_counters",
    "create_treasure",
    "damage_each_opponent",
    "damage_any_target",
    "damage_player_and_creatures",
    "damage_wipe",
    "damage_wipe_treasure",
    "deal_damage",
    "discard_trigger_modal_draw_treasure_opponent_life_loss",
    "equipment_static_attachment",
    "equipment_haste_shroud",
    "exile_artifact_enchantment_creature_convoke_wipe",
    "exile_each_opponent_nonland_until_source_leaves",
    "exile_graveyard_card_create_food",
    "exile_top_nonland_free_cast",
    "fated_clash_protect_then_destroy",
    "extra_turn",
    "finisher",
    "gift_hexproof_indestructible",
    "gift_destroy_all_creatures_return_own_destroyed_creature",
    "graveyard_flashback_grant",
    "harnessed_blink",
    "hate_artifact",
    "indestructible",
    "land_tax",
    "land_ramp",
    "land_recursion",
    "land_recursion_creature",
    "lander_token_maker",
    "life_artifact",
    "mill_engine",
    "modal_boros_charm",
    "overload_recursion",
    "phase_out",
    "phase_creatures",
    "planeswalker",
    "protect_creature",
    "pump_all",
    "recursion",
    "redistribute_life_totals",
    "removal_destroy",
    "remove_artifact_or_3dmg",
    "remove_creature",
    "remove_permanent",
    "rummage",
    "silence_opponents",
    "silence_spell",
    "selective_nonland_sacrifice",
    "steal_all_creatures",
    "sweeper_damage",
    "thassa_oracle",
    "token_maker",
    "treasure_maker",
    "tutor",
    "untap_tapped_permanent_etb_engine",
    "vow_counter_each_player_sacrifice_rest",
}

HEURISTIC_SOURCES = {
    "card_effect_field",
    "functional_tag",
    "functional_tags_json",
    "known_cards_generated",
    "type_line_creature",
    "unknown",
}

LEGACY_FALLBACK_SOURCES = {
    "known_cards_manual",
    "known_cards_generated",
}

TRUSTED_EVENT_RULE_OVERRIDE_SOURCES = {
    "manual_runtime_waiver",
}


def md(value: Any) -> str:
    return str(value if value is not None else "").replace("|", "\\|").replace("\n", " ")


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def load_events(path: Path, replay_id: str | None = None) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    replay_name = replay_id or path.stem
    with path.open("r", encoding="utf-8") as handle:
        for index, line in enumerate(handle, start=1):
            text = line.strip()
            if not text:
                continue
            try:
                event = json.loads(text)
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"Invalid JSONL at {path}:{index}: {exc}") from exc
            event.setdefault("replay_id", replay_name)
            event.setdefault("event_index", index)
            events.append(event)
    return events


def output_dir(report: bool, requested: str | None = None) -> Path:
    if requested:
        path = Path(requested)
    elif report:
        path = REPORT_DIR / "forensic_replays"
    else:
        path = Path(tempfile.mkdtemp(prefix="hermes_battle_forensic_"))
    path = path.resolve()
    path.mkdir(parents=True, exist_ok=True)
    return path


def generate_replay(seed: int, out_dir: Path) -> tuple[list[dict[str, Any]], Path, Path]:
    replay_txt = out_dir / f"battle_forensic_seed_{seed}.txt"
    replay_jsonl = out_dir / f"battle_forensic_seed_{seed}.jsonl"
    env = os.environ.copy()
    env.update(
        {
            "REPLAY_SEED": str(seed),
            "REPLAY_OUT": str(replay_txt),
            "REPLAY_EVENTS_OUT": str(replay_jsonl),
        }
    )
    completed = subprocess.run(
        [sys.executable, str(REPLAY_GENERATOR)],
        cwd=str(SCRIPT_DIR),
        env=env,
        capture_output=True,
        text=True,
        timeout=360,
    )
    if completed.returncode != 0:
        output = (completed.stdout or "") + "\n" + (completed.stderr or "")
        raise RuntimeError(f"Replay generation failed for seed {seed}:\n{output[-3000:]}")
    return load_events(replay_jsonl, replay_id=f"seed_{seed}"), replay_txt, replay_jsonl


def add_finding(
    findings: list[dict[str, Any]],
    severity: str,
    event: dict[str, Any],
    finding: str,
    recommendation: str,
) -> None:
    findings.append(
        {
            "severity": severity,
            "replay_id": event.get("replay_id", "?"),
            "turn": event.get("turn", "?"),
            "phase": event.get("phase") or "-",
            "player": event.get("player") or event.get("attacker") or "?",
            "event": event.get("event", "?"),
            "card": event.get("card") or "-",
            "effect": event.get("effect") or "-",
            "finding": finding,
            "recommendation": recommendation,
        }
    )


def rule_for_event(
    event: dict[str, Any],
    rules: dict[str, dict[str, Any]],
) -> dict[str, Any] | None:
    card = event.get("card")
    if card:
        rule = rules.get(battle_rule_registry.normalize_card_name(str(card)))
        if rule is not None:
            return rule
    logical_key = str(event.get("rule_logical_key") or "")
    if logical_key:
        for rule in rules.values():
            if str(rule.get("logical_rule_key") or "") == logical_key:
                return rule
    return None


def event_rule_source(event: dict[str, Any], rule: dict[str, Any] | None) -> str:
    return str(event.get("rule_source") or (rule or {}).get("source") or "missing")


def event_review_status(event: dict[str, Any], rule: dict[str, Any] | None) -> str:
    return str(event.get("rule_review_status") or (rule or {}).get("review_status") or "missing")


def event_effect(event: dict[str, Any], rule: dict[str, Any] | None) -> str:
    if event.get("effect"):
        return str(event["effect"])
    if rule:
        effect_json = rule.get("effect_json") or {}
        return str(effect_json.get("effect") or "unknown")
    return "unknown"


def event_logical_rule_key(event: dict[str, Any], rule: dict[str, Any] | None) -> str:
    return str(event.get("rule_logical_key") or (rule or {}).get("logical_rule_key") or "")


def event_card_id(event: dict[str, Any]) -> str:
    return str(event.get("card_id") or "")


def event_semantic_hash(event: dict[str, Any]) -> str:
    return str(event.get("semantic_hash") or event.get("semantics_hash") or "")


def event_has_explicit_oracle_effect_normalization(
    event: dict[str, Any],
    rule_effect: str,
) -> bool:
    return (
        bool(rule_effect)
        and event.get("rule_oracle_normalized_effect_from") == rule_effect
        and event.get("rule_oracle_normalized_effect_to") == event.get("effect")
    )


def event_has_accepted_compact_runtime_normalization(
    event: dict[str, Any],
    rule_effect: str,
) -> bool:
    runtime_effect = str(event.get("effect") or "")
    event_kind = str(event.get("event") or "")
    if event_kind == "land_played" and runtime_effect == "land" and rule_effect in {
        "ramp_permanent",
        "treasure_maker",
    }:
        return True
    return (rule_effect, runtime_effect) in {
        ("bounce", "remove_permanent"),
        ("modal_spell", "remove_permanent"),
        ("removal_destroy", "remove_permanent"),
        ("removal_exile", "remove_creature"),
        ("sweeper_damage", "damage_wipe"),
    }


def accepted_lineage_missing_reason(
    event: dict[str, Any],
    rule: dict[str, Any] | None,
    source: str,
    effect: str,
    missing_field: str,
) -> str:
    if source == "type_line_creature" and effect == "creature":
        return "type_line_creature_fact_no_rule_identity"
    if source == "manual_runtime_waiver":
        return "manual_runtime_waiver_without_pg_identity"
    if (
        event.get("event") == "land_played"
        and effect == "land"
        and source == "curated"
        and event.get("rule_logical_key")
        and missing_field in {"card_id", "semantic_hash"}
    ):
        return "land_played_curated_runtime_rule_without_pg_card_identity"
    if rule is not None and source in {"curated", "generated"}:
        if missing_field in {"card_id", "semantic_hash"}:
            return "battle_rule_registry_without_card_identity_columns"
        if missing_field == "rule_logical_key" and rule.get("logical_rule_key"):
            return "rule_registry_logical_key_available"
    if event.get("event") == "land_played" and effect == "land" and rule is not None:
        return "land_rule_registry_without_card_identity_columns"
    return ""


def audit_rule_provenance(
    events: list[dict[str, Any]],
    rules: dict[str, dict[str, Any]],
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    by_source: Counter[str] = Counter()
    by_status: Counter[str] = Counter()
    by_effect: Counter[str] = Counter()
    cards_by_status: dict[str, set[str]] = defaultdict(set)
    cards_by_source: dict[str, set[str]] = defaultdict(set)
    by_logical_rule_key: Counter[str] = Counter()
    missing_logical_rule_key = 0
    card_id_present = 0
    card_id_missing = 0
    card_id_missing_accepted = 0
    card_id_missing_unaccepted = 0
    semantic_hash_present = 0
    semantic_hash_missing = 0
    semantic_hash_missing_accepted = 0
    semantic_hash_missing_unaccepted = 0
    rule_logical_key_missing_accepted = 0
    rule_logical_key_missing_unaccepted = 0
    lineage_missing_waiver_reasons: Counter[str] = Counter()
    lineage_unaccepted_missing_samples: list[dict[str, Any]] = []
    unique_cards: set[str] = set()

    for event in events:
        if event.get("event") not in CARD_EVENT_KINDS:
            continue
        card = str(event.get("card") or "")
        if card:
            unique_cards.add(card)
        rule = rule_for_event(event, rules)
        source = event_rule_source(event, rule)
        status = event_review_status(event, rule)
        effect = event_effect(event, rule)
        logical_key = event_logical_rule_key(event, rule)
        card_id = event_card_id(event)
        semantic_hash = event_semantic_hash(event)
        by_source[source] += 1
        by_status[status] += 1
        by_effect[effect] += 1
        if logical_key:
            by_logical_rule_key[logical_key] += 1
        else:
            missing_logical_rule_key += 1
            reason = accepted_lineage_missing_reason(
                event, rule, source, effect, "rule_logical_key"
            )
            if reason:
                rule_logical_key_missing_accepted += 1
                lineage_missing_waiver_reasons[reason] += 1
            else:
                rule_logical_key_missing_unaccepted += 1
                if len(lineage_unaccepted_missing_samples) < 40:
                    lineage_unaccepted_missing_samples.append({
                        "event": event.get("event"),
                        "card": event.get("card"),
                        "effect": effect,
                        "source": source,
                        "missing_field": "rule_logical_key",
                    })
        if card_id:
            card_id_present += 1
        else:
            card_id_missing += 1
            reason = accepted_lineage_missing_reason(event, rule, source, effect, "card_id")
            if reason:
                card_id_missing_accepted += 1
                lineage_missing_waiver_reasons[reason] += 1
            else:
                card_id_missing_unaccepted += 1
                if len(lineage_unaccepted_missing_samples) < 40:
                    lineage_unaccepted_missing_samples.append({
                        "event": event.get("event"),
                        "card": event.get("card"),
                        "effect": effect,
                        "source": source,
                        "missing_field": "card_id",
                    })
        if semantic_hash:
            semantic_hash_present += 1
        else:
            semantic_hash_missing += 1
            reason = accepted_lineage_missing_reason(event, rule, source, effect, "semantic_hash")
            if reason:
                semantic_hash_missing_accepted += 1
                lineage_missing_waiver_reasons[reason] += 1
            else:
                semantic_hash_missing_unaccepted += 1
                if len(lineage_unaccepted_missing_samples) < 40:
                    lineage_unaccepted_missing_samples.append({
                        "event": event.get("event"),
                        "card": event.get("card"),
                        "effect": effect,
                        "source": source,
                        "missing_field": "semantic_hash",
                    })
        if card:
            cards_by_status[status].add(card)
            cards_by_source[source].add(card)

        if effect == "unknown":
            severity = "critical" if event.get("event") == "spell_resolved" else "high"
            add_finding(
                findings,
                severity,
                event,
                "Card event used unknown battle semantics.",
                "Create or correct card_battle_rules.effect_json, then replay this seed.",
            )
            continue

        if effect not in SUPPORTED_EFFECTS:
            add_finding(
                findings,
                "critical",
                event,
                f"Effect `{effect}` is not implemented by the active battle engine.",
                "Implement the effect branch or map the card to a supported approximation.",
            )

        if status == "needs_review" and not (
            event.get("event") == "land_played" and effect == "land"
        ):
            severity = "high" if effect in GAME_IMPACT_EFFECTS else "medium"
            add_finding(
                findings,
                severity,
                event,
                "Game event depended on a needs_review rule.",
                "Review oracle text/rulings, add a regression test if impactful, then promote to verified.",
            )

        if source in HEURISTIC_SOURCES and effect not in {"creature", "land"}:
            severity = "high" if event.get("event") == "spell_resolved" else "medium"
            add_finding(
                findings,
                severity,
                event,
                f"Game event depended on heuristic source `{source}`.",
                "Move this card into card_battle_rules with verified/active status.",
            )

        if rule is None and source in LEGACY_FALLBACK_SOURCES:
            add_finding(
                findings,
                "medium",
                event,
                "Card used legacy known-cards fallback but is absent from battle_card_rules cache.",
                "Sync card_battle_rules from PG and confirm the card exists in card_battle_rules.",
            )

        if rule is None and source == "known_cards_canonical_snapshot":
            add_finding(
                findings,
                "low",
                event,
                "Card used canonical snapshot fallback but is absent from live battle_card_rules cache.",
                "Refresh the SQLite/PG rule cache and regenerate the canonical snapshot if drift is expected.",
            )

        if rule and source not in TRUSTED_EVENT_RULE_OVERRIDE_SOURCES:
            rule_effect = str((rule.get("effect_json") or {}).get("effect") or "")
            is_trigger_effect = event.get("event") == "trigger_resolved"
            is_composite_effect = event.get("effect") == "composite_resolution"
            if (
                rule_effect
                and event.get("effect")
                and rule_effect != event["effect"]
                and not is_trigger_effect
                and not is_composite_effect
                and not event_has_explicit_oracle_effect_normalization(
                    event,
                    rule_effect,
                )
                and not event_has_accepted_compact_runtime_normalization(
                    event,
                    rule_effect,
                )
            ):
                add_finding(
                    findings,
                    "low",
                    event,
                    f"Runtime effect `{event['effect']}` differs from registry effect `{rule_effect}`.",
                    "Usually oracle normalization; review only if behavior looks wrong in replay.",
                )

        if event.get("event") == "miracle_cast":
            if event.get("lorehold_on_board") is not True:
                add_finding(
                    findings,
                    "critical",
                    event,
                    "Miracle cast without Lorehold marked as on-board.",
                    "Fix Lorehold miracle timing/state check.",
                )
            is_first_brainstone_draw = (
                event.get("source") == "brainstone_first_draw"
                and event.get("first_draw_miracle_candidate") is True
            )
            if int(event.get("cards_drawn_this_turn") or 0) != 1 and not is_first_brainstone_draw:
                add_finding(
                    findings,
                    "critical",
                    event,
                    "Miracle cast was not on the first real draw of the turn.",
                    "Fix draw-step miracle gate and add regression coverage.",
                )

    summary = {
        "card_event_count": sum(by_source.values()),
        "unique_cards": len(unique_cards),
        "by_source": dict(sorted(by_source.items())),
        "by_status": dict(sorted(by_status.items())),
        "by_effect": dict(sorted(by_effect.items())),
        "rule_logical_key_present": sum(by_logical_rule_key.values()),
        "rule_logical_key_missing": missing_logical_rule_key,
        "rule_logical_key_missing_accepted": rule_logical_key_missing_accepted,
        "rule_logical_key_missing_unaccepted": rule_logical_key_missing_unaccepted,
        "card_id_present": card_id_present,
        "card_id_missing": card_id_missing,
        "card_id_missing_accepted": card_id_missing_accepted,
        "card_id_missing_unaccepted": card_id_missing_unaccepted,
        "semantic_hash_present": semantic_hash_present,
        "semantic_hash_missing": semantic_hash_missing,
        "semantic_hash_missing_accepted": semantic_hash_missing_accepted,
        "semantic_hash_missing_unaccepted": semantic_hash_missing_unaccepted,
        "lineage_missing_waiver_reasons": dict(sorted(lineage_missing_waiver_reasons.items())),
        "lineage_unaccepted_missing_samples": lineage_unaccepted_missing_samples,
        "by_rule_logical_key": dict(by_logical_rule_key.most_common(40)),
        "cards_by_status": {
            status: sorted(cards)[:40] for status, cards in sorted(cards_by_status.items())
        },
        "cards_by_source": {
            source: sorted(cards)[:40] for source, cards in sorted(cards_by_source.items())
        },
    }
    return findings, summary


def severity_counts(findings: list[dict[str, Any]]) -> dict[str, int]:
    counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
    for finding in findings:
        severity = str(finding.get("severity") or "low")
        counts[severity] = counts.get(severity, 0) + 1
    return counts


def render_counter_table(title: str, values: dict[str, int]) -> list[str]:
    lines = [f"## {title}", "", "| Value | Count |", "| --- | ---: |"]
    if values:
        for key, value in sorted(values.items(), key=lambda item: (-item[1], item[0])):
            lines.append(f"| `{md(key)}` | {value} |")
    else:
        lines.append("| none | 0 |")
    lines.append("")
    return lines


def render_report(
    *,
    sqlite_db: Path,
    events: list[dict[str, Any]],
    replay_files: list[tuple[Path, Path]],
    rule_findings: list[dict[str, Any]],
    turn_findings: list[dict[str, Any]],
    summary: dict[str, Any],
) -> str:
    all_findings = rule_findings + turn_findings
    counts = severity_counts(all_findings)
    blocking = counts.get("critical", 0) + counts.get("high", 0)
    status = "blocked" if blocking else "ready_for_review"
    lines = [
        "# Hermes Battle Forensic Audit",
        "",
        f"- generated_at: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}",
        f"- status: {status}",
        f"- sqlite_db: `{sqlite_db}`",
        f"- structured_events: {len(events)}",
        f"- card_events: {summary.get('card_event_count', 0)}",
        f"- unique_cards_seen: {summary.get('unique_cards', 0)}",
        f"- rule_logical_key_present: {summary.get('rule_logical_key_present', 0)}",
        f"- rule_logical_key_missing: {summary.get('rule_logical_key_missing', 0)}",
        f"- rule_logical_key_missing_accepted: {summary.get('rule_logical_key_missing_accepted', 0)}",
        f"- rule_logical_key_missing_unaccepted: {summary.get('rule_logical_key_missing_unaccepted', 0)}",
        f"- card_id_present: {summary.get('card_id_present', 0)}",
        f"- card_id_missing: {summary.get('card_id_missing', 0)}",
        f"- card_id_missing_accepted: {summary.get('card_id_missing_accepted', 0)}",
        f"- card_id_missing_unaccepted: {summary.get('card_id_missing_unaccepted', 0)}",
        f"- semantic_hash_present: {summary.get('semantic_hash_present', 0)}",
        f"- semantic_hash_missing: {summary.get('semantic_hash_missing', 0)}",
        f"- semantic_hash_missing_accepted: {summary.get('semantic_hash_missing_accepted', 0)}",
        f"- semantic_hash_missing_unaccepted: {summary.get('semantic_hash_missing_unaccepted', 0)}",
        f"- findings_total: {len(all_findings)}",
        f"- critical: {counts.get('critical', 0)}",
        f"- high: {counts.get('high', 0)}",
        f"- medium: {counts.get('medium', 0)}",
        f"- low: {counts.get('low', 0)}",
        "",
        "## Replay Evidence",
        "",
    ]
    if replay_files:
        for txt, jsonl in replay_files:
            lines.append(f"- text: `{txt}`")
            lines.append(f"- events: `{jsonl}`")
    else:
        lines.append("- external JSONL replay was audited.")
    lines.append("")

    lines.extend(render_counter_table("Rule Sources Used", summary.get("by_source", {})))
    lines.extend(render_counter_table("Review Status Used", summary.get("by_status", {})))
    lines.extend(render_counter_table("Effects Seen", summary.get("by_effect", {})))
    lines.extend(
        render_counter_table(
            "Accepted Lineage Missing Waiver Reasons",
            summary.get("lineage_missing_waiver_reasons", {}),
        )
    )
    lines.extend(
        render_counter_table(
            "Rule Logical Keys Seen",
            summary.get("by_rule_logical_key", {}),
        )
    )

    lines.extend(
        [
            "## Findings",
            "",
            "| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |",
            "| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |",
        ]
    )
    if all_findings:
        severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
        for finding in sorted(
            all_findings,
            key=lambda item: (
                severity_order.get(str(item.get("severity")), 9),
                str(item.get("turn")),
                str(item.get("event")),
            ),
        ):
            row = {key: md(value) for key, value in finding.items()}
            lines.append(
                "| {severity} | {replay_id} | {turn} | {phase} | {player} | {event} | {card} | {effect} | {finding} | {recommendation} |".format(
                    severity=row.get("severity", "-"),
                    replay_id=row.get("replay_id", "-"),
                    turn=row.get("turn", "-"),
                    phase=row.get("phase", "-"),
                    player=row.get("player", "-"),
                    event=row.get("event", "-"),
                    card=row.get("card", "-"),
                    effect=row.get("effect", "-"),
                    finding=row.get("finding", "-"),
                    recommendation=row.get("recommendation", "-"),
                )
            )
    else:
        lines.append("| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |")

    lines.extend(
        [
            "",
            "## Promotion Rule",
            "",
            "- `critical` and `high` findings block trusting optimizer output from this replay.",
            "- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.",
            "- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.",
        ]
    )
    return "\n".join(lines) + "\n"


def write_report(markdown: str) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    path = REPORT_DIR / f"battle_forensic_audit_{utc_stamp()}.md"
    path.write_text(markdown, encoding="utf-8")
    return path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--events", type=Path, help="Audit an existing replay JSONL file.")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--generate", type=int, default=1, help="Number of fresh replays to generate.")
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--output-dir")
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--json-report", type=Path)
    parser.add_argument("--fail-on-high", action="store_true")
    args = parser.parse_args()

    events: list[dict[str, Any]] = []
    replay_files: list[tuple[Path, Path]] = []
    if args.events:
        events.extend(load_events(args.events))
    else:
        out_dir = output_dir(args.report, args.output_dir)
        for seed in range(args.seed, args.seed + max(1, args.generate)):
            generated, txt, jsonl = generate_replay(seed, out_dir)
            events.extend(generated)
            replay_files.append((txt, jsonl))

    rules = battle_rule_registry.load_active_battle_card_rules(args.sqlite_db)
    rule_findings, summary = audit_rule_provenance(events, rules)
    turn_findings = replay_decision_auditor.audit_turn_events(events)
    markdown = render_report(
        sqlite_db=args.sqlite_db,
        events=events,
        replay_files=replay_files,
        rule_findings=rule_findings,
        turn_findings=turn_findings,
        summary=summary,
    )
    print(markdown)
    if args.report:
        path = write_report(markdown)
        print(f"Report written: {path}")
    if args.json_report:
        payload = {
            "summary": summary,
            "rule_findings": rule_findings,
            "turn_findings": turn_findings,
            "replay_files": [
                {"text": str(txt), "events": str(jsonl)} for txt, jsonl in replay_files
            ],
        }
        args.json_report.write_text(
            json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    counts = severity_counts(rule_findings + turn_findings)
    if args.fail_on_high and counts.get("critical", 0) + counts.get("high", 0) > 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
