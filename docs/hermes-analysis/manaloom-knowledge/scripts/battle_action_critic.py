#!/usr/bin/env python3
"""Per-action critic for a single Hermes battle replay.

This is intentionally stricter and more verbose than aggregate win-rate reports.
It reads structured replay events plus optional decision traces and produces a
human-reviewable ledger: every gameplay action gets a verdict, evidence and any
finding that should be investigated before trusting the replay as training data.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict, deque
from pathlib import Path
from typing import Any


ACTION_EVENTS = {
    "additional_cost_failed",
    "commander_cast",
    "combat",
    "combat_result",
    "combat_step",
    "creature_cast",
    "cost_paid",
    "end_step_instant",
    "flashback_cast",
    "game_won",
    "land_played",
    "miracle_cast",
    "multi_defender_attack",
    "player_eliminated",
    "redirect_removal_resolved",
    "recursion_resolved",
    "removal_resolved",
    "replacement_applied",
    "spell_cast",
    "spell_countered",
    "spell_exiled_from_stack",
    "spell_resolved",
    "trigger_put_on_stack",
    "trigger_resolved",
    "tutor_resolved",
    "turn_end",
    "turn_start",
}

TECHNICAL_EVENTS = {
    "cast_announced",
    "cast_illegal",
    "mana_refreshed",
    "priority_pass",
}

CARD_ACTION_EVENTS = {
    "commander_cast",
    "creature_cast",
    "end_step_instant",
    "flashback_cast",
    "land_played",
    "miracle_cast",
    "spell_cast",
    "spell_resolved",
    "spell_countered",
    "spell_exiled_from_stack",
    "redirect_removal_resolved",
}

TARGETED_REMOVAL_EFFECTS = {"remove_creature", "remove_permanent", "remove_artifact_or_3dmg"}

NO_MAX_HAND_SIZE_PERMANENTS = {
    "decanter of endless water",
    "library of leng",
    "reliquary tower",
    "spellbook",
    "thought vessel",
    "venser's journal",
    "wizard class",
}

DECISION_ACTION_EVENTS = {
    "commander_cast",
    "creature_cast",
    "combat",
    "combat_step",
    "end_step_instant",
    "miracle_cast",
    "spell_cast",
}

EVENT_CONTRACT_OVERRIDES = {
    "activated_ability_skipped": (
        "ignored_with_reason",
        "activation was considered but skipped; no action legality verdict expected.",
    ),
    "activated_ability": (
        "strategy_signal",
        "resolved activated ability; renderer/decision trace carry the action-specific context.",
    ),
    "additional_cost_paid": (
        "technical",
        "additional cost ledger detail; primary payment is audited through cost_paid.",
    ),
    "adventure_cast": (
        "strategy_signal",
        "alternate cast mode represented in stack/cast context and human replay.",
    ),
    "adventure_creature_cast_from_exile": (
        "strategy_signal",
        "follow-up adventure creature cast represented in stack/cast context and human replay.",
    ),
    "adventure_exiled": (
        "technical",
        "adventure spell exile ledger after the spell half resolves.",
    ),
    "airbend_creature_cast_from_exile": (
        "strategy_signal",
        "airbend alternate exile cast represented in stack/cast context and human replay.",
    ),
    "airbend_other_creatures_resolved": (
        "strategy_signal",
        "Avatar's Wrath airbend resolution changes creature zones and non-hand cast permissions.",
    ),
    "aetherflux_reservoir_resolved": (
        "strategy_signal",
        "Aetherflux Reservoir permanent resolution is engine context for later spell-cast lifegain.",
    ),
    "approach_cast_tracked": (
        "strategy_signal",
        "Approach cast count is tracked for first/second-resolution outcome context.",
    ),
    "approach_first_resolution": (
        "strategy_signal",
        "first Approach resolution changes library placement and future win-condition context.",
    ),
    "attachment_sba": (
        "ignored_with_reason",
        "state-based attachment cleanup; legality is checked by the SBA helper.",
    ),
    "attack_prevented_by_orims_chant": (
        "strategy_signal",
        "kicked Orim's Chant prevented creatures from being declared as attackers.",
    ),
    "battle_back_face_cast": (
        "strategy_signal",
        "battle transformation/cast signal consumed by replay and future strategy checks.",
    ),
    "battle_damage": (
        "renderer_only",
        "battle damage state evidence for replay continuity.",
    ),
    "board_wipe_resolved": (
        "strategy_signal",
        "board wipe resolution is consumed by decision strategy and replay state checks.",
    ),
    "cannot_lose_turn_resolved": (
        "strategy_signal",
        "cannot-lose effect is game-state strategy context, not a standalone action verdict.",
    ),
    "cantrip_mana_filter_artifact_resolved": (
        "strategy_signal",
        "cantrip/filter resolution is represented by card-flow and decision context.",
    ),
    "chaos_warp_reveal_resolved": (
        "strategy_signal",
        "Chaos Warp reveal/placement outcome is card-specific resolution evidence.",
    ),
    "composite_rule_component_resolved": (
        "strategy_signal",
        "component of a composite rule; consumed with the parent composite resolution.",
    ),
    "composite_rule_resolved": (
        "strategy_signal",
        "composite rule resolution signal consumed by replay/forensic checks.",
    ),
    "compensation_tokens_created": (
        "renderer_only",
        "compensation token creation is replay state evidence for resolved removal.",
    ),
    "copy_creature_token_failed": (
        "ignored_with_reason",
        "copy-token path was considered but skipped or failed with reason metadata.",
    ),
    "copy_creature_token_created": (
        "renderer_only",
        "token creation is rendered as state evidence, not a decision/action verdict.",
    ),
    "copy_spell_no_stack_target": (
        "ignored_with_reason",
        "copy-spell card had no legal stack target and intentionally resolved without creating a fake engine.",
    ),
    "counters_cancelled": (
        "ignored_with_reason",
        "state-based counter cleanup; not a player decision action.",
    ),
    "creature_to_battlefield": (
        "renderer_only",
        "battlefield placement state evidence for human replay continuity.",
    ),
    "damage_resolved": (
        "renderer_only",
        "life-change explanation for human replay continuity.",
    ),
    "damage_wipe_resolved": (
        "strategy_signal",
        "damage wipe resolution is consumed by replay and strategy checks.",
    ),
    "damage_wipe_treasure_resolved": (
        "strategy_signal",
        "variable damage wipe plus treasure creation result is consumed by replay and strategy checks.",
    ),
    "demonstrate_resolved": (
        "strategy_signal",
        "demonstrate copy choice and resulting free-cast resolutions are card-specific strategy context.",
    ),
    "dragons_approach_dragon_tutored": (
        "strategy_signal",
        "Dragon's Approach tutor result is combo/finisher context for replay checks.",
    ),
    "dragons_approach_resolved": (
        "strategy_signal",
        "Dragon's Approach resolution is card-specific damage/tutor context.",
    ),
    "draw_cards_resolved": (
        "strategy_signal",
        "draw resolution is card-flow evidence consumed by replay/strategy context.",
    ),
    "draw_equal_to_discarded_hand_resolved": (
        "strategy_signal",
        "discard-hand-then-draw resolution is card-flow evidence consumed by replay/strategy context.",
    ),
    "dig_to_hand_resolved": (
        "strategy_signal",
        "look-at-top-cards selection resolution is card-flow evidence consumed by replay/strategy context.",
    ),
    "top_nonland_free_cast": (
        "strategy_signal",
        "free cast of the revealed exiled nonland card is represented by spell_cast/spell_resolved ledger events.",
    ),
    "top_nonland_free_cast_resolved": (
        "strategy_signal",
        "top-library reveal, exile, and free-cast result is card-flow evidence consumed by replay/strategy context.",
    ),
    "end_step_token_sacrificed": (
        "renderer_only",
        "scheduled token cleanup state evidence.",
    ),
    "end_step_token_exiled": (
        "renderer_only",
        "scheduled token exile cleanup state evidence.",
    ),
    "end_step_token_death_draw_resolved": (
        "technical",
        "token death-trigger draw ledger after scheduled end-step cleanup.",
    ),
    "class_level_gained": (
        "strategy_signal",
        "class level activation is represented in replay state and decision context.",
    ),
    "class_level_trigger_resolved": (
        "strategy_signal",
        "class level trigger resolution is card-flow evidence consumed by replay/strategy context.",
    ),
    "class_level_trigger_skipped": (
        "ignored_with_reason",
        "class level trigger was considered but skipped because no legal effect remained.",
    ),
    "discard_modal_trigger_resolved": (
        "strategy_signal",
        "discard-trigger modal resolution changes card/resource/life context for replay checks.",
    ),
    "etb_land_ramp_skipped": (
        "ignored_with_reason",
        "enter-the-battlefield land ramp was considered but skipped because its condition failed.",
    ),
    "etb_recursion_resolved": (
        "strategy_signal",
        "enter-the-battlefield recursion resolution is card-flow evidence consumed by replay context.",
    ),
    "etb_removal_resolved": (
        "strategy_signal",
        "enter-the-battlefield removal resolution is board-state evidence consumed by replay checks.",
    ),
    "etb_removal_skipped": (
        "ignored_with_reason",
        "enter-the-battlefield removal was considered but skipped because no legal target existed.",
    ),
    "etb_tutor_resolved": (
        "strategy_signal",
        "enter-the-battlefield tutor resolution is card-flow evidence consumed by replay/strategy context.",
    ),
    "equipment_attached": (
        "renderer_only",
        "attachment state evidence, not a standalone strategy action.",
    ),
    "equipment_unattached": (
        "renderer_only",
        "attachment state evidence, not a standalone strategy action.",
    ),
    "extra_combat_cap_reached": (
        "ignored_with_reason",
        "extra combat was blocked by cap and should carry cap reason metadata.",
    ),
    "extra_combat_scheduled": (
        "strategy_signal",
        "future-combat scheduling signal for strategy/replay context.",
    ),
    "extra_combat_taken": (
        "strategy_signal",
        "extra-combat consumption signal for strategy/replay context.",
    ),
    "extra_turn_cap_reached": (
        "ignored_with_reason",
        "extra turn was blocked by cap and should carry cap reason metadata.",
    ),
    "extra_turn_scheduled": (
        "strategy_signal",
        "future-turn scheduling signal for strategy/replay context.",
    ),
    "extra_turn_taken": (
        "strategy_signal",
        "extra-turn consumption signal for strategy/replay context.",
    ),
    "flashback_cast": (
        "strategy_signal",
        "alternate graveyard cast mode represented in stack/cast context and human replay.",
    ),
    "flashback_exiled": (
        "technical",
        "flashback replacement-zone ledger after a tracked graveyard cast resolves.",
    ),
    "game_lost": (
        "strategy_signal",
        "game loss terminal state consumed by replay outcome checks.",
    ),
    "game_win_prevented": (
        "strategy_signal",
        "win-prevention signal consumed by game-outcome and replay checks.",
    ),
    "graveyard_flashback_granted": (
        "strategy_signal",
        "Past in Flames style permission grant is card-flow evidence for later flashback casts.",
    ),
    "hand_filter_resolved": (
        "strategy_signal",
        "hand filtering resolution is card-flow evidence consumed by replay/strategy context.",
    ),
    "hate_artifact_resolved": (
        "strategy_signal",
        "hate artifact resolution is effect evidence consumed by replay/forensic checks.",
    ),
    "imprint_failed": (
        "ignored_with_reason",
        "imprint path was considered but skipped or failed with reason metadata.",
    ),
    "imprint_resolved": (
        "strategy_signal",
        "imprint resolution is resource-context evidence for later cast decisions.",
    ),
    "invoke_calamity_free_cast": (
        "strategy_signal",
        "Invoke Calamity free-cast signal is represented by spell_cast/spell_resolved ledger events.",
    ),
    "invoke_calamity_resolved": (
        "strategy_signal",
        "Invoke Calamity aggregate resolution is recursion/free-cast outcome context.",
    ),
    "instant_removal": (
        "forensic_card_event",
        "instant removal is a card-event kind checked by forensic lineage.",
    ),
    "land_ramp_resolved": (
        "strategy_signal",
        "land ramp resolution is resource-development evidence for replay/strategy context.",
    ),
    "land_recursion_creature_resolved": (
        "strategy_signal",
        "land recursion creature resolution is resource-development evidence.",
    ),
    "land_recursion_resolved": (
        "strategy_signal",
        "land recursion resolution is resource-development evidence.",
    ),
    "land_tax_trigger_skipped": (
        "ignored_with_reason",
        "Land Tax upkeep trigger was considered but skipped because its condition or targets were unavailable.",
    ),
    "land_tax_trigger_resolved": (
        "strategy_signal",
        "Land Tax upkeep tutor resolution is card-flow/resource evidence.",
    ),
    "lander_token_created": (
        "renderer_only",
        "token creation is rendered as state evidence, not a standalone action verdict.",
    ),
    "life_artifact_resolved": (
        "strategy_signal",
        "life artifact resolution is effect evidence consumed by replay state checks.",
    ),
    "life_totals_redistributed": (
        "strategy_signal",
        "life-total redistribution result is consumed by replay and strategy checks.",
    ),
    "one_ring_burden_life_loss": (
        "strategy_signal",
        "The One Ring burden life loss is upkeep state evidence consumed by replay state checks.",
    ),
    "mill_resolved": (
        "strategy_signal",
        "library mill resolution changes deck state and future draw-loss risk for replay/strategy checks.",
    ),
    "jeskas_will_resolved": (
        "strategy_signal",
        "Jeska's Will mode result changes mana/card-flow context for strategy review.",
    ),
    "loot_resolved": (
        "strategy_signal",
        "loot resolution is card-flow evidence consumed by replay/strategy context.",
    ),
    "loyalty_ability_activated": (
        "strategy_signal",
        "planeswalker loyalty activation is represented in replay state and decision context.",
    ),
    "lorehold_upkeep_rummage": (
        "strategy_signal",
        "decision-trace backed upkeep rummage signal.",
    ),
    "lorehold_upkeep_rummage_skipped": (
        "ignored_with_reason",
        "upkeep rummage was considered and skipped.",
    ),
    "multi_target_resolution": (
        "forensic_card_event",
        "multi-target spell resolution is effect evidence consumed by forensic/replay checks.",
    ),
    "mizzix_mastery_copy_cast": (
        "strategy_signal",
        "Mizzix's Mastery copy-cast event is recursion/copy-spell resolution context.",
    ),
    "mizzix_mastery_resolved": (
        "strategy_signal",
        "Mizzix's Mastery aggregate resolution is recursion/copy-spell outcome context.",
    ),
    "modal_boros_charm_resolved": (
        "strategy_signal",
        "Boros Charm modal resolution is protection/damage context for replay checks.",
    ),
    "modal_spell_resolved": (
        "strategy_signal",
        "modal spell resolution is effect evidence consumed by replay/strategy context.",
    ),
    "multikicker_paid": (
        "technical",
        "kicker payment ledger detail; primary cast remains the audited action.",
    ),
    "paradigm_exiled": (
        "renderer_only",
        "library/exile state transition for Paradigm Shift-style effects.",
    ),
    "pile_selection_draw_resolved": (
        "strategy_signal",
        "Fact-or-Fiction style pile selection is card-flow evidence consumed by replay/strategy context.",
    ),
    "permanent_moved_by_sba": (
        "ignored_with_reason",
        "state-based permanent movement; not a player decision action.",
    ),
    "phase_creatures_resolved": (
        "strategy_signal",
        "phase effect resolution is board-state evidence for replay/forensic checks.",
    ),
    "phase_out_resolved": (
        "strategy_signal",
        "phase-out resolution is protection/combat-prevention context.",
    ),
    "planeswalker_damage": (
        "renderer_only",
        "planeswalker damage state evidence for replay continuity.",
    ),
    "prepared_copies_removed": (
        "technical",
        "scheduled copy cleanup ledger detail.",
    ),
    "prepared_copy_created": (
        "renderer_only",
        "copy setup state evidence for later replay resolution.",
    ),
    "powerbalance_trigger_resolved": (
        "strategy_signal",
        "Powerbalance trigger resolution is topdeck/free-cast context for replay checks.",
    ),
    "protection_resolved": (
        "strategy_signal",
        "protection effect resolution is consumed by replay/forensic checks.",
    ),
    "protection_from_everything_granted": (
        "strategy_signal",
        "temporary protection-from-everything grant is consumed by replay damage-prevention checks.",
    ),
    "random_discard_after_tutor": (
        "strategy_signal",
        "Gamble-style random discard after tutor changes card-flow/resource context.",
    ),
    "rebound_cast": (
        "strategy_signal",
        "rebound recast is represented in stack/cast context and human replay.",
    ),
    "rebound_exiled": (
        "technical",
        "rebound replacement-zone ledger after a tracked spell resolves.",
    ),
    "rebound_skipped": (
        "ignored_with_reason",
        "rebound permission was checked and intentionally skipped with reason metadata.",
    ),
    "removal_countered_by_ward": (
        "strategy_signal",
        "ward counter result is stack/interaction context for replay checks.",
    ),
    "replacement_exiled_on_resolution": (
        "technical",
        "replacement exile zone movement after spell resolution.",
    ),
    "spell_exiled_from_stack": (
        "strategy_signal",
        "stack-targeted exile interaction resolved; spell_cast and target fields carry legality context.",
    ),
    "ripple_trigger_resolved": (
        "strategy_signal",
        "ripple resolution changes cast/card-flow context for replay checks.",
    ),
    "ritual_mana_added": (
        "strategy_signal",
        "ritual mana addition is resource-development evidence.",
    ),
    "saga_chapter_progressed": (
        "strategy_signal",
        "saga progression signal consumed through decision/replay context.",
    ),
    "saga_chapter_resolved": (
        "strategy_signal",
        "saga resolution signal consumed through decision/replay context.",
    ),
    "saga_sacrificed_by_sba": (
        "ignored_with_reason",
        "state-based action cleanup after final saga chapter.",
    ),
    "self_exiled_on_resolution": (
        "technical",
        "self-exile replacement zone movement after resolution.",
    ),
    "spell_copied": (
        "strategy_signal",
        "copy-spell stack event changes future resolution context.",
    ),
    "spell_copy_ceased_to_exist": (
        "technical",
        "copied spell cleanup after stack resolution.",
    ),
    "spell_shuffled_into_library_on_resolution": (
        "strategy_signal",
        "self-shuffle on resolution changes library/card-flow context for replay checks.",
    ),
    "static_enter_tapped_applied": (
        "technical",
        "static tapped-entry replacement was applied during zone movement.",
    ),
    "station_activated": (
        "strategy_signal",
        "station activation is represented in replay state and decision context.",
    ),
    "steal_all_creatures_resolved": (
        "strategy_signal",
        "mass creature-control resolution changes board and damage context for replay checks.",
    ),
    "surge_to_victory_resolved": (
        "strategy_signal",
        "Surge to Victory resolution creates delayed combat/free-cast context for replay checks.",
    ),
    "thassa_oracle_resolved": (
        "strategy_signal",
        "Thassa's Oracle enter-the-battlefield check is terminal-combo context for outcome validation.",
    ),
    "token_ceased_to_exist": (
        "renderer_only",
        "token zone cleanup state evidence.",
    ),
    "tokens_created": (
        "renderer_only",
        "token creation is rendered as board-state evidence, not a standalone action verdict.",
    ),
    "topdeck_manipulation_activated": (
        "strategy_signal",
        "topdeck manipulation is represented in decision trace score components.",
    ),
    "treasure_created": (
        "renderer_only",
        "token/resource state evidence, not a standalone action verdict.",
    ),
    "tutor_life_loss_resolved": (
        "strategy_signal",
        "tutor life-loss rider changes life total context for replay and strategy checks.",
    ),
    "trigger_skipped": (
        "ignored_with_reason",
        "trigger path was checked and skipped with reason metadata.",
    ),
    "utility_artifact_activated": (
        "strategy_signal",
        "utility artifact activation is represented in decision trace score components.",
    ),
    "utility_land_activated": (
        "strategy_signal",
        "utility land activation is represented in decision trace score components.",
    ),
    "utility_land_triggered": (
        "strategy_signal",
        "utility land trigger is replay state context.",
    ),
    "ward_countered": (
        "strategy_signal",
        "ward counter result is stack/interaction context for replay checks.",
    ),
    "ward_paid": (
        "technical",
        "ward payment ledger detail; primary interaction remains the audited action.",
    ),
    "warp_cast": (
        "strategy_signal",
        "alternate warp cast mode represented in stack/cast context and human replay.",
    ),
    "warp_exiled_end_step": (
        "technical",
        "warp delayed exile ledger detail.",
    ),
    "warp_recast_from_exile": (
        "strategy_signal",
        "warp recast is represented in stack/cast context and human replay.",
    ),
    "wheel_resolved": (
        "strategy_signal",
        "wheel decision/effect signal consumed by strategy review.",
    ),
    "worldfire_resolved": (
        "strategy_signal",
        "Worldfire-style reset resolution is consumed by strategy and replay outcome checks.",
    ),
}

SEVERITY_ORDER = {
    "ok": 0,
    "info": 1,
    "low": 2,
    "medium": 3,
    "high": 4,
    "critical": 5,
}


def load_jsonl(path: Path, *, replay_id: str | None = None) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for index, line in enumerate(handle, start=1):
            text = line.strip()
            if not text:
                continue
            payload = json.loads(text)
            payload.setdefault("event_index", index)
            if replay_id:
                payload.setdefault("replay_id", replay_id)
            rows.append(payload)
    return rows


def md(value: Any) -> str:
    return str(value if value is not None else "").replace("|", "\\|").replace("\n", " ")


def event_label(event: dict[str, Any]) -> str:
    card = event.get("card")
    if card:
        return str(card)
    if event.get("target"):
        return f"target={event.get('target')}"
    if event.get("defender"):
        return f"defender={event.get('defender')}"
    if event.get("reason"):
        return str(event.get("reason"))
    return "-"


def event_player(event: dict[str, Any]) -> str:
    return str(
        event.get("player")
        or event.get("attacker")
        or event.get("defender")
        or event.get("controller")
        or event.get("active_player")
        or "?"
    )


def event_turn(event: dict[str, Any]) -> Any:
    return event.get("turn", "?")


def event_phase(event: dict[str, Any]) -> str:
    return str(event.get("phase") or "-")


def type_line(event: dict[str, Any]) -> str:
    return str(event.get("type_line") or "")


def is_land_event(event: dict[str, Any]) -> bool:
    return event.get("effect") == "land" or "land" in type_line(event).lower()


def is_card_spell_event(event: dict[str, Any]) -> bool:
    return event.get("event") in {
        "commander_cast",
        "creature_cast",
        "end_step_instant",
        "miracle_cast",
        "spell_cast",
    }


def has_declared_target(event: dict[str, Any]) -> bool:
    if event.get("target"):
        return True
    targets = event.get("targets")
    return isinstance(targets, list) and len(targets) > 0


def is_spell_copy_resolution(event: dict[str, Any]) -> bool:
    return (
        event.get("event") == "spell_resolved"
        and (
            event.get("role") == "copy"
            or event.get("source_zone") == "stack_copy"
            or event.get("destination") == "ceased_to_exist"
            or event.get("cast_pipeline") in {"spell_copy", "spell_copy_resolution"}
        )
    )


def action_finding(
    severity: str,
    code: str,
    detail: str,
    recommendation: str,
) -> dict[str, str]:
    return {
        "severity": severity,
        "code": code,
        "detail": detail,
        "recommendation": recommendation,
    }


def max_severity(findings: list[dict[str, str]]) -> str:
    if not findings:
        return "ok"
    return max(findings, key=lambda f: SEVERITY_ORDER.get(f["severity"], 0))["severity"]


def decision_key(decision: dict[str, Any]) -> tuple[Any, str, str]:
    chosen = decision.get("chosen_option") or {}
    card = str(chosen.get("card") or "")
    return (decision.get("turn", "?"), str(decision.get("player") or "?"), card)


def build_decision_index(decisions: list[dict[str, Any]]) -> dict[tuple[Any, str, str], deque[dict[str, Any]]]:
    index: dict[tuple[Any, str, str], deque[dict[str, Any]]] = defaultdict(deque)
    for decision in decisions:
        key = decision_key(decision)
        index[key].append(decision)
    return index


def pop_matching_decision(
    decision_index: dict[tuple[Any, str, str], deque[dict[str, Any]]],
    event: dict[str, Any],
) -> dict[str, Any] | None:
    key = (event.get("turn", "?"), str(event.get("player") or "?"), str(event.get("card") or ""))
    queue = decision_index.get(key)
    if not queue:
        return None
    event_phase = str(event.get("phase") or "")
    if event_phase:
        for decision in list(queue):
            if str(decision.get("phase") or "") == event_phase:
                queue.remove(decision)
                return decision
        for decision in list(queue):
            if not decision.get("phase"):
                queue.remove(decision)
                return decision
        return None
    return queue.popleft()


def classify_event_contract(kind: str) -> tuple[str, str]:
    if kind in ACTION_EVENTS:
        return "action_audited", "included in ACTION_EVENTS and receives action critic checks."
    if kind in TECHNICAL_EVENTS:
        return "technical", "technical ledger event; included only in ledger mode."
    return EVENT_CONTRACT_OVERRIDES.get(
        kind,
        ("unclassified", "event type has no explicit action contract classification."),
    )


def normalize_permanent_name(value: Any) -> str:
    text = str(value or "").strip().lower()
    text = text.replace("\u2018", "'").replace("\u2019", "'")
    return re.sub(r"\s+", " ", text)


def turn_end_has_no_max_hand_size(event: dict[str, Any]) -> bool:
    if event.get("no_max_hand_size") is True:
        return True
    for permanent in event.get("board_snapshot") or []:
        if not isinstance(permanent, dict):
            continue
        if permanent.get("no_max_hand_size") is True:
            return True
        if normalize_permanent_name(permanent.get("name")) in NO_MAX_HAND_SIZE_PERMANENTS:
            return True
    return False


def summarize_event_contract(events: list[dict[str, Any]]) -> dict[str, Any]:
    event_type_counts = Counter(str(event.get("event") or "missing") for event in events)
    event_class_counts: Counter[str] = Counter()
    event_type_class_counts: Counter[str] = Counter()
    event_rows: list[dict[str, Any]] = []
    unclassified_types: list[str] = []

    for kind, count in sorted(event_type_counts.items()):
        classification, reason = classify_event_contract(kind)
        event_class_counts[classification] += count
        event_type_class_counts[classification] += 1
        if classification == "unclassified":
            unclassified_types.append(kind)
        event_rows.append({
            "event": kind,
            "count": count,
            "classification": classification,
            "reason": reason,
        })

    return {
        "events_total": sum(event_type_counts.values()),
        "event_types_total": len(event_type_counts),
        "event_class_counts": dict(sorted(event_class_counts.items())),
        "event_type_class_counts": dict(sorted(event_type_class_counts.items())),
        "events_unclassified": int(event_class_counts.get("unclassified", 0)),
        "event_types_unclassified": unclassified_types,
        "event_rows": event_rows,
    }


def criticize_actions(
    events: list[dict[str, Any]],
    decisions: list[dict[str, Any]] | None = None,
    *,
    include_technical: bool = False,
) -> dict[str, Any]:
    decisions = decisions or []
    event_contract = summarize_event_contract(events)
    decision_index = build_decision_index(decisions)
    cast_stack: dict[tuple[Any, str, str], list[dict[str, Any]]] = defaultdict(list)
    land_plays: Counter[tuple[Any, str, Any]] = Counter()
    alive_players: dict[Any, dict[str, bool]] = defaultdict(dict)
    game_won_seen: set[Any] = set()
    action_rows: list[dict[str, Any]] = []

    action_number = 0
    for event in events:
        kind = event.get("event")
        if kind in TECHNICAL_EVENTS and not include_technical:
            continue
        if kind not in ACTION_EVENTS and not include_technical:
            continue

        action_number += 1
        player = event_player(event)
        turn = event_turn(event)
        phase = event_phase(event)
        replay_id = event.get("replay_id", "external")
        findings: list[dict[str, str]] = []
        evidence: list[str] = []

        if turn == "?" and kind not in {"trigger_put_on_stack", "replacement_applied"}:
            findings.append(action_finding(
                "low",
                "missing_turn",
                "Action event has no turn field.",
                "Include turn in emitted event for full replay traceability.",
            ))

        if kind in CARD_ACTION_EVENTS:
            source = str(event.get("rule_source") or "missing")
            status = str(event.get("rule_review_status") or "missing")
            effect = str(event.get("effect") or "unknown")
            if kind == "spell_countered":
                effect = str(event.get("effect") or "counter")
            evidence.append(f"rule={source}/{status}")
            evidence.append(f"effect={effect}")
            if source == "missing" or status == "missing":
                findings.append(action_finding(
                    "low",
                    "missing_rule_metadata",
                    "Card action is missing rule source/review status.",
                    "Emit rule_source and rule_review_status for every card action.",
                ))
            elif status in {"needs_review", "unknown"}:
                findings.append(action_finding(
                    "low",
                    "review_rule_used",
                    f"Action used rule status {status}.",
                    "Keep this action audit-only until the card rule is verified.",
                ))

        if kind == "cost_paid":
            evidence.append(f"card={event.get('card', '-')}")
            evidence.append(f"cost={event.get('locked_cost', '-')}")
            evidence.append(f"mana={event.get('mana_before', '-')}->{event.get('mana_after', '-')}")
            evidence.append(f"life={event.get('life_before', '-')}->{event.get('life_after', '-')}")

        effect = str(event.get("effect") or "")
        if kind in {"end_step_instant", "spell_cast", "spell_resolved"} and effect == "counter":
            if not event.get("target") and not event.get("stack_object"):
                findings.append(action_finding(
                    "high",
                    "counter_without_stack_target",
                    "Counterspell action lacks target/stack object evidence.",
                    "Emit target, stack object and result, or block the counter as no_legal_target/fizzled.",
                ))
            if kind == "spell_resolved":
                findings.append(action_finding(
                    "high",
                    "counter_resolved_as_normal_spell",
                    "Counterspell resolved as a normal spell action instead of a stack interaction result.",
                    "Route counters through spell_countered/fizzled/no_legal_target events before strategy learning.",
                ))

        if (
            kind
            in {"cast_announced", "end_step_instant", "miracle_cast", "spell_cast", "spell_resolved"}
            and effect in TARGETED_REMOVAL_EFFECTS
        ):
            if not has_declared_target(event):
                findings.append(action_finding(
                    "high",
                    "targeted_removal_without_declared_target",
                    "Targeted removal action lacks declared target metadata.",
                    "Declare and persist target metadata at cast time, then revalidate the same target at resolution.",
                ))
            evidence.append(f"target={event.get('target') or '-'}")

        if kind == "spell_resolved":
            def _resolution_field_missing(field):
                value = event.get(field)
                if field == "resolved_from_stack":
                    return value is None
                return value in (None, "", [], {})

            missing_resolution_fields = [
                field
                for field in (
                    "phase",
                    "priority_window",
                    "stack_object",
                    "stack_depth",
                    "source_zone",
                    "from_zone",
                    "to_zone",
                    "destination",
                    "zone_after",
                    "resolved_from_stack",
                    "result",
                    "cast_pipeline",
                    "locked_cost",
                )
                if _resolution_field_missing(field)
            ]
            evidence.append(f"resolved_from_stack={event.get('resolved_from_stack', '-')}")
            evidence.append(f"destination={event.get('destination') or event.get('zone_after') or event.get('to_zone') or '-'}")
            if missing_resolution_fields:
                findings.append(action_finding(
                    "medium",
                    "spell_resolved_without_resolution_provenance",
                    "spell_resolved lacks required provenance: "
                    + ", ".join(sorted(set(missing_resolution_fields))),
                    "Emit resolution provenance on spell_resolved or add an explicit linked-zone waiver.",
                ))

        if kind == "spell_countered":
            evidence.append(f"target={event.get('target') or '-'}")
            evidence.append(f"stack_object={event.get('stack_object') or '-'}")
            evidence.append(f"result={event.get('result') or '-'}")
            evidence.append(f"phase={event.get('phase') or '-'}")
            evidence.append(f"priority_window={event.get('priority_window') or '-'}")
            if not event.get("target") or not event.get("stack_object"):
                findings.append(action_finding(
                    "high",
                    "counter_without_stack_target",
                    "Counter event lacks target or stack object.",
                    "Emit both target and stack_object for every counter interaction.",
                ))
            if not event.get("phase") or not event.get("priority_window"):
                findings.append(action_finding(
                    "medium",
                    "counter_without_priority_window",
                    "Counter event lacks priority provenance.",
                    "Emit phase and priority_window for every counter interaction.",
                ))
            if event.get("result") not in {"countered", "fizzled", "no_legal_target"}:
                findings.append(action_finding(
                    "medium",
                    "counter_without_result",
                    "Counter event lacks a legal interaction result.",
                    "Record result as countered, fizzled or no_legal_target.",
                ))

        if kind == "redirect_removal_resolved":
            result = event.get("result")
            required_redirect_fields = [
                "redirected_object",
                "old_target",
                "new_target",
                "target_type",
            ]
            evidence.append(f"redirected_object={event.get('redirected_object') or '-'}")
            evidence.append(f"old_target={event.get('old_target') or '-'}")
            evidence.append(f"new_target={event.get('new_target') or '-'}")
            evidence.append(f"legal_redirect_opportunity={event.get('legal_redirect_opportunity')}")
            evidence.append(f"target_change_applied={event.get('target_change_applied')}")
            evidence.append(f"result={result or '-'}")
            if result == "redirected":
                missing_redirect_fields = [
                    field
                    for field in required_redirect_fields
                    if event.get(field) in (None, "", [], {})
                ]
                if (
                    missing_redirect_fields
                    or event.get("legal_redirect_opportunity") is not True
                    or event.get("target_change_applied") is not True
                ):
                    findings.append(action_finding(
                        "high",
                        "redirect_without_target_change_provenance",
                        "Redirect effect resolved without complete target-change provenance.",
                        "Emit redirected_object, old_target, new_target, target_type, legal opportunity and applied change.",
                    ))
            elif result not in {"no_redirect_target", "no_legal_new_target"}:
                findings.append(action_finding(
                    "medium",
                    "redirect_without_result",
                    "Redirect effect lacks a legal interaction result.",
                    "Record result as redirected, no_redirect_target or no_legal_new_target.",
                ))

        if kind == "trigger_put_on_stack":
            trigger_source = event.get("source") or event.get("card")
            trigger_name = (
                event.get("trigger")
                or event.get("trigger_event")
                or event.get("event_type")
            )
            stack_order = event.get("stack_depth")
            if stack_order is None:
                stack_order = event.get("timestamp")
            evidence.append(f"source={trigger_source or '-'}")
            evidence.append(f"trigger={trigger_name or '-'}")
            evidence.append(f"stack={stack_order if stack_order is not None else '-'}")
            if not trigger_source or not trigger_name or stack_order is None:
                findings.append(action_finding(
                    "high",
                    "trigger_without_auditable_stack_metadata",
                    "Trigger reached the stack without source, trigger name or stack order metadata.",
                    "Emit source/card, trigger and stack_depth/timestamp for every trigger_put_on_stack event.",
                ))

        if kind == "replacement_applied":
            affected = event.get("card") or event.get("affected_object")
            affected_player = event.get("affected_player")
            source = event.get("source")
            reason = event.get("reason")
            causal_event = event.get("causal_event")
            replacements = event.get("replacements") or []
            from_zone = event.get("from_zone")
            to_zone = event.get("to_zone")
            event_type = event.get("event_type")
            amount = event.get("amount")
            delta = event.get("delta")
            original_amount = event.get("original_amount")
            final_amount = event.get("final_amount")
            original_delta = event.get("original_delta")
            final_delta = event.get("final_delta")
            replacement_rule_source = event.get("replacement_rule_source")
            replacement_rule_sources = event.get("replacement_rule_sources") or []
            evidence.append(f"card={affected or '-'}")
            evidence.append(f"affected_player={affected_player or '-'}")
            evidence.append(f"source={source or '-'}")
            evidence.append(f"reason={reason or '-'}")
            evidence.append(f"zone={from_zone or '-'}->{to_zone or '-'}")
            evidence.append(f"value={original_amount if original_amount is not None else original_delta}->{final_amount if final_amount is not None else final_delta}")
            evidence.append(f"replacement_rule_source={replacement_rule_source or '-'}")
            has_life_or_damage_metadata = (
                event_type in {"damage", "life_change"}
                and bool(affected_player)
                and (amount is not None or delta is not None)
                and (original_amount is not None or original_delta is not None)
                and (final_amount is not None or final_delta is not None)
            )
            has_zone_metadata = bool(affected and from_zone and to_zone)
            if not replacements or not (has_zone_metadata or has_life_or_damage_metadata):
                findings.append(action_finding(
                    "high",
                    "replacement_without_zone_or_object_metadata",
                    "Replacement event lacks affected object, zone transition, life/damage metadata or replacement list.",
                    "Emit affected object plus from/to zones for zone changes, or affected player plus amount/delta for life and damage replacements.",
                ))
            if not source and not replacement_rule_source and not replacement_rule_sources and not reason and not causal_event:
                findings.append(action_finding(
                    "high",
                    "replacement_without_causal_metadata",
                    "Replacement event lacks source, reason and causal_event metadata.",
                    "Emit the causal spell/ability/rule or a structured justification before accepting the replacement.",
                ))

        if kind == "land_played":
            land_plays[(replay_id, player, turn)] += 1
            if not is_land_event(event):
                findings.append(action_finding(
                    "critical",
                    "nonland_played_as_land",
                    "Event land_played does not look like a land.",
                    "Fix card classification before trusting this replay.",
                ))
            if land_plays[(replay_id, player, turn)] > 1:
                findings.append(action_finding(
                    "high",
                    "multiple_land_plays",
                    "Player played more than one land in the same turn.",
                    "Only allow this with an explicit extra-land effect in the event metadata.",
                ))

        if kind in {"spell_cast", "creature_cast", "commander_cast", "miracle_cast", "end_step_instant", "flashback_cast"}:
            if is_land_event(event):
                findings.append(action_finding(
                    "critical",
                    "land_cast_as_spell",
                    "A land-like card was cast as a spell.",
                    "Fix land/spell classification before using this replay.",
                ))
            if kind != "commander_cast":
                cast_stack[(replay_id, player, str(event.get("card") or ""))].append(event)

        if kind == "spell_resolved":
            key = (replay_id, player, str(event.get("card") or ""))
            if is_spell_copy_resolution(event):
                evidence.append("copy_resolution=true")
            elif cast_stack.get(key):
                cast_stack[key].pop()
            else:
                findings.append(action_finding(
                    "medium",
                    "resolve_without_cast",
                    "Spell resolved without a prior tracked cast in this replay.",
                    "Check stack emission order or add explicit synthetic-source metadata.",
                ))

        if kind == "combat_step":
            attackers = event.get("attackers")
            if attackers is not None and not attackers:
                findings.append(action_finding(
                    "low",
                    "empty_attack",
                    "Combat step has no attackers.",
                    "Prefer omitting combat_step or marking it as no_attack decision.",
                ))
            total_power = event.get("total_power")
            if total_power is not None and float(total_power or 0) < 0:
                findings.append(action_finding(
                    "critical",
                    "negative_combat_power",
                    "Combat total_power is negative.",
                    "Fix combat stat calculation.",
                ))
            evidence.append(f"target={event.get('target') or event.get('defender') or '-'}")
            evidence.append(f"power={event.get('total_power', event.get('power', '-'))}")

        if kind == "combat_result":
            damage = event.get("damage")
            if damage is not None and float(damage or 0) < 0:
                findings.append(action_finding(
                    "critical",
                    "negative_damage",
                    "Combat result has negative damage.",
                    "Fix damage assignment.",
                ))
            evidence.append(f"damage={damage if damage is not None else '-'}")
            evidence.append(f"target_life={event.get('target_life', '-')}")

        if kind == "turn_end":
            hand = int(event.get("hand") or 0)
            evidence.append(f"hand={hand}")
            evidence.append(f"board={event.get('board', '-')}")
            evidence.append(f"grave={event.get('graveyard', '-')}")
            if hand > 7 and not turn_end_has_no_max_hand_size(event):
                findings.append(action_finding(
                    "critical",
                    "cleanup_hand_size",
                    f"Turn ended with hand size {hand} > 7.",
                    "Fix cleanup discard or max hand size handling.",
                ))

        if kind == "player_eliminated":
            eliminated = str(event.get("player") or event.get("target") or "?")
            alive_players[replay_id][eliminated] = False
            evidence.append(f"reason={event.get('reason', '-')}")

        if kind == "turn_start":
            alive_players[replay_id].setdefault(player, True)
            evidence.append(f"life={event.get('life', '-')}")
            evidence.append(f"hand={event.get('hand', '-')}")

        if kind == "game_won":
            game_won_seen.add(replay_id)
            evidence.append(f"winner={player}")

        decision = None
        if kind in DECISION_ACTION_EVENTS and event.get("card"):
            decision = pop_matching_decision(decision_index, event)
            if decision:
                evidence.append(f"decision={decision.get('decision_id')}")
                if not decision.get("score_components"):
                    findings.append(action_finding(
                        "low",
                        "empty_decision_score",
                        "Matching decision trace has empty score_components.",
                        "Populate score_components for auditability.",
                    ))
            elif kind in {"spell_cast", "creature_cast", "commander_cast"}:
                findings.append(action_finding(
                    "low",
                    "missing_decision_trace",
                    "Action has no matching decision trace.",
                    "Emit a decision trace for cast/combat choices.",
                ))

        action_rows.append({
            "action_id": f"action-{action_number:06d}",
            "event_index": event.get("event_index", action_number),
            "replay_id": replay_id,
            "turn": turn,
            "phase": phase,
            "player": player,
            "event": kind,
            "label": event_label(event),
            "verdict": max_severity(findings),
            "evidence": "; ".join(evidence) if evidence else "-",
            "findings": findings,
        })

    replay_ids = {row["replay_id"] for row in action_rows} or {"external"}
    for replay_id in replay_ids:
        players = alive_players.get(replay_id, {})
        alive_count = sum(1 for alive in players.values() if alive)
        if players and alive_count <= 1 and replay_id not in game_won_seen:
            action_number += 1
            survivor = next((player for player, alive in players.items() if alive), "?")
            action_rows.append({
                "action_id": f"action-{action_number:06d}",
                "event_index": "-",
                "replay_id": replay_id,
                "turn": "postgame",
                "phase": "-",
                "player": survivor,
                "event": "postgame_consistency",
                "label": "winner inference",
                "verdict": "medium",
                "evidence": f"alive_players={alive_count}; survivor={survivor}",
                "findings": [action_finding(
                    "medium",
                    "missing_game_won",
                    "Replay reached one surviving player but emitted no game_won event.",
                    "Emit game_won when multiplayer game closes by elimination.",
                )],
            })

    counts = Counter(row["verdict"] for row in action_rows)
    findings = [
        {
            **finding,
            "action_id": row["action_id"],
            "turn": row["turn"],
            "phase": row["phase"],
            "player": row["player"],
            "event": row["event"],
            "label": row["label"],
        }
        for row in action_rows
        for finding in row["findings"]
    ]
    return {
        "summary": {
            "events_total": event_contract["events_total"],
            "event_types_total": event_contract["event_types_total"],
            "event_contract": event_contract,
            "events_unclassified": event_contract["events_unclassified"],
            "event_types_unclassified": event_contract["event_types_unclassified"],
            "total_actions": len(action_rows),
            "verdict_counts": dict(sorted(counts.items())),
            "findings": len(findings),
            "technical_events_included": include_technical,
            "technical_events_mode": "ledger" if include_technical else "default_action_only",
        },
        "actions": action_rows,
        "findings": findings,
    }


def render_markdown(result: dict[str, Any]) -> str:
    summary = result["summary"]
    lines = [
        "# Battle Action Critic",
        "",
        "## Summary",
        "",
        f"- total_actions: {summary['total_actions']}",
        f"- events_total: {summary.get('events_total', 0)}",
        f"- event_types_total: {summary.get('event_types_total', 0)}",
        f"- event_contract_class_counts: `{json.dumps(summary.get('event_contract', {}).get('event_class_counts', {}), sort_keys=True)}`",
        f"- events_unclassified: {summary.get('events_unclassified', 0)}",
        f"- event_types_unclassified: `{json.dumps(summary.get('event_types_unclassified', []), sort_keys=True)}`",
        f"- findings: {summary['findings']}",
        f"- verdict_counts: `{json.dumps(summary['verdict_counts'], sort_keys=True)}`",
        f"- technical_events_included: {summary['technical_events_included']}",
        f"- technical_events_mode: {summary.get('technical_events_mode', 'default_action_only')}",
        "",
        "## Findings",
        "",
    ]
    if result["findings"]:
        lines.extend([
            "| Severity | Action | Turn | Player | Event | Finding | Recommendation |",
            "| --- | --- | ---: | --- | --- | --- | --- |",
        ])
        for finding in result["findings"]:
            lines.append(
                "| {severity} | {action_id} | {turn} | {player} | {event} | {detail} | {recommendation} |".format(
                    severity=md(finding["severity"]),
                    action_id=md(finding["action_id"]),
                    turn=md(finding["turn"]),
                    player=md(finding["player"]),
                    event=md(finding["event"]),
                    detail=md(finding["detail"]),
                    recommendation=md(finding["recommendation"]),
                )
            )
    else:
        lines.append("- No action findings.")
    lines.extend([
        "",
        "## Action Ledger",
        "",
        "| Action | Line | Turn | Phase | Player | Event | Label | Verdict | Evidence |",
        "| --- | ---: | ---: | --- | --- | --- | --- | --- | --- |",
    ])
    for row in result["actions"]:
        lines.append(
            "| {action_id} | {event_index} | {turn} | {phase} | {player} | {event} | {label} | {verdict} | {evidence} |".format(
                action_id=md(row["action_id"]),
                event_index=md(row["event_index"]),
                turn=md(row["turn"]),
                phase=md(row["phase"]),
                player=md(row["player"]),
                event=md(row["event"]),
                label=md(row["label"]),
                verdict=md(row["verdict"]),
                evidence=md(row["evidence"]),
            )
        )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Criticize every gameplay action in a Hermes battle replay.")
    parser.add_argument("--events", required=True, type=Path, help="Structured replay JSONL.")
    parser.add_argument("--decision-trace", type=Path, help="Decision trace JSONL.")
    parser.add_argument("--output", type=Path, help="Markdown report output.")
    parser.add_argument("--json-output", type=Path, help="Machine-readable JSON report output.")
    parser.add_argument("--include-technical", action="store_true", help="Include priority/mana/cast-announced events.")
    args = parser.parse_args()

    events = load_jsonl(args.events)
    decisions = load_jsonl(args.decision_trace) if args.decision_trace and args.decision_trace.exists() else []
    result = criticize_actions(events, decisions, include_technical=args.include_technical)
    markdown = render_markdown(result)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
