#!/usr/bin/env python3
"""
Lorehold Battle Analyst v9 — Interactive Commander Simulator
Fase A: Priority, Stack, Instant/Sorcery Timing
+ Fase B: Miracle (Lorehold core mechanic)
+ Fase C: SBAs, Boros Charm modal, Double Strike fix, Indestructible per-creature

Regras implementadas agora:
- Priority System (CR 117): cada jogador recebe prioridade por turno
- Stack LIFO (CR 405): spells resolvem em ordem reversa
- Instant vs Sorcery timing: instants podem ser conjurados em resposta
- Counterspells: oponentes podem counterar spells ameacadoras
- State-Based Actions (CR 704): verificadas apos cada spell resolver
- Miracle (CR 702.94): Lorehold da miracle {2} a instants/sorceries na mao
- Boros Charm modal: escolhe indestructible ou double strike por contexto
- Double Strike fix: 2x dano total (nao 3x)
- Indestructible per-creature: board wipe respeita indestructible individual
- Lifelink: life gain ao causar dano
- Haste: Lorehold nao tem summoning sickness
"""
import argparse
import sqlite3, random, json, os, re, copy, sys
from datetime import datetime, timezone
from collections import defaultdict
from itertools import combinations
from pathlib import Path

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR and SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

SCRIPT_DIR_PATH = Path(SCRIPT_DIR)
LOCAL_KNOWLEDGE_DIR = SCRIPT_DIR_PATH.parent
REMOTE_KNOWLEDGE_DIR = Path("/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge")


def _resolve_knowledge_dir() -> Path:
    env_dir = os.environ.get("MANALOOM_KNOWLEDGE_DIR")
    if env_dir:
        return Path(env_dir)
    if REMOTE_KNOWLEDGE_DIR.exists():
        return REMOTE_KNOWLEDGE_DIR
    return LOCAL_KNOWLEDGE_DIR


def _resolve_knowledge_db() -> Path:
    env_db = os.environ.get("MANALOOM_KNOWLEDGE_DB")
    if env_db:
        return Path(env_db)
    remote_db = REMOTE_KNOWLEDGE_DIR / "scripts" / "knowledge.db"
    if remote_db.exists():
        return remote_db
    return SCRIPT_DIR_PATH / "knowledge.db"

from battle_mana_cost_support import (
    MANA_SYMBOL_TO_POOL,
    card_mana_cost,
    merge_mana_costs,
    parse_mana_cost,
    replay_cost_snapshot,
    variable_mana_symbol_count,
)
from battle_card_characteristics_support import (
    adventure_spell_card,
    card_has_color,
    compute_color_identity,
    get_card_characteristics,
    has_power_toughness_box,
    is_adventure_card,
    is_commander_eligible_card,
    is_creature_card,
    is_vehicle_or_spacecraft_card,
    read_json_list,
)
from battle_land_support import (
    BASIC_LAND_COLORS,
    KNOWN_LAND_NAMES,
    is_land,
    normalize_card_name,
    source_colors,
)
from battle_zone_transition_support import (
    finish_countered_spell as _finish_countered_spell,
    finish_resolved_spell as _finish_resolved_spell,
    get_lki,
    move_creature_from_battlefield as _move_creature_from_battlefield,
    move_permanent_from_battlefield as _move_permanent_from_battlefield,
    move_to_exile,
)
from battle_replacement_support import (
    ReplacementEvent,
    ReplacementRegistry as _ReplacementRegistry,
    add_damage_prevention_shield,
    change_life as _change_life,
    deal_damage as _deal_damage,
    gain_life as _gain_life,
)
from battle_sba_support import (
    cancel_plus_minus_counters as _cancel_plus_minus_counters,
    check_illegal_attachments as _check_illegal_attachments,
    check_saga_final_chapter as _check_saga_final_chapter,
    check_sbas as _check_sbas,
    check_sbas_until_stable as _check_sbas_until_stable,
    check_token_lifecycle as _check_token_lifecycle,
)

try:
    import battle_rule_registry
except Exception:
    battle_rule_registry = None

from known_cards_fallback_snapshot import (
    extract_snapshot_effect_and_metadata,
    load_snapshot_file,
    resolve_canonical_snapshot_path,
)

DB = os.environ.get(
    "MANALOOM_KNOWLEDGE_DB",
    str(_resolve_knowledge_db()),
)
KNOWLEDGE_DIR = os.environ.get(
    "MANALOOM_KNOWLEDGE_DIR",
    str(_resolve_knowledge_dir()),
)
LOG_PATH = f"{KNOWLEDGE_DIR}/decks/lorehold-the-historian/BATTLE_LOG.md"

REPLAY_EVENT_HANDLER = None
DECISION_TRACE_HANDLER = None
DECISION_TRACE_COUNTER = 0
CURRENT_REPLAY_TURN = None
DECISION_TRACE_SCHEMA_VERSION = "decision_trace_v1"
DECISION_STRATEGY_VERSION = "battle_decision_strategy_v1_2026_06_15"
HIGH_IMPACT_PAYOFF_EFFECTS = {
    "approach",
    "board_wipe",
    "copy_creature_token",
    "copy_spell",
    "draw_engine",
    "finisher",
    "overload_recursion",
    "protection",
    "remove_creature",
    "remove_permanent",
    "silence_opponents",
    "steal_all_creatures",
    "token_maker",
    "wincon",
}
OPENING_HAND_REACTIVE_EFFECTS = {
    "counter",
    "indestructible",
    "protection",
    "remove_creature",
    "remove_permanent",
    "silence_opponents",
    "silence_spell",
}
OPENING_HAND_CARD_FLOW_EFFECTS = {
    "draw_cards",
    "draw_engine",
    "impulse_draw",
    "loot_draw",
    "rummage",
    "topdeck_setup",
    "tutor",
}
OPENING_HAND_RAMP_EFFECTS = {
    "land_ramp",
    "mana_dork",
    "ramp_engine",
    "ramp_permanent",
}
ENGINE_METRICS = None


def emit_replay_event(event, **data):
    """Emit optional structured replay events without affecting simulation."""
    if "turn" not in data and CURRENT_REPLAY_TURN is not None:
        data["turn"] = CURRENT_REPLAY_TURN
    if ENGINE_METRICS is not None:
        try:
            ENGINE_METRICS.record_event(event, data)
        except Exception:
            pass
    if REPLAY_EVENT_HANDLER is None:
        return
    try:
        REPLAY_EVENT_HANDLER(event, data)
    except Exception:
        pass


def reset_decision_trace_counter():
    """Reset per-replay decision IDs without touching simulation state."""
    global DECISION_TRACE_COUNTER
    DECISION_TRACE_COUNTER = 0


def _next_decision_id(replay_id=None):
    global DECISION_TRACE_COUNTER
    DECISION_TRACE_COUNTER += 1
    prefix = replay_id or "decision"
    return f"{prefix}-{DECISION_TRACE_COUNTER:06d}"


def decision_card_option(card, effect_data=None, score=None, action=None, **extra):
    """Small, stable card/action snapshot for decision trace JSONL."""
    if card is None:
        option = {"action": action or "none"}
    elif isinstance(card, dict):
        effect_data = effect_data or get_card_effect(card)
        option = {
            "card": card.get("name", "?"),
            "action": action or "cast",
            "effect": effect_data.get("effect", card.get("effect", "unknown")),
            "cmc": card.get("cmc", 0),
            "type_line": card.get("type_line", ""),
        }
    else:
        option = {"action": action or str(card)}
    if score is not None:
        option["score"] = score
    option.update({k: v for k, v in extra.items() if v is not None})
    return option


def _option_identity(option):
    if not isinstance(option, dict):
        return str(option)
    return str(option.get("card") or option.get("action") or option)


def _option_score(option, fallback=None):
    if not isinstance(option, dict):
        return fallback
    value = option.get("score", fallback)
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def _comparative_option_scores(chosen, options, rejected_options, expected_benefit_score):
    chosen_score = _option_score(chosen, fallback=expected_benefit_score)
    available_scored = []
    for option in options:
        score = _option_score(option)
        if score is None:
            continue
        available_scored.append(
            {
                "option": _option_identity(option),
                "score": score,
            }
        )
    rejected_scored = []
    for option in rejected_options:
        score = _option_score(option)
        if score is None:
            continue
        rejected_scored.append(
            {
                "option": _option_identity(option),
                "score": score,
            }
        )
    best_available = max((item["score"] for item in available_scored), default=chosen_score)
    best_rejected = max((item["score"] for item in rejected_scored), default=None)
    score_gap = None
    if chosen_score is not None and best_rejected is not None:
        score_gap = chosen_score - best_rejected
    return chosen_score, available_scored, rejected_scored, best_available, best_rejected, score_gap


def _default_strategic_principle(decision_type, reason=None):
    if decision_type == "mulligan_decision":
        return "opening_hand_must_have_mana_and_early_plan"
    if decision_type == "cast_spell":
        return "spend_mana_only_for_curve_plan_or_material_advantage"
    if decision_type == "response":
        return "use_interaction_on_lethal_engines_or_high_impact_threats"
    if decision_type == "combat_attack":
        return "attack_target_selected_by_lethal_threat_and_table_position"
    if decision_type == "pass_no_action":
        return "pass_when_no_profitable_or_legal_action_is_available"
    return reason or decision_type or "battle_heuristic"


def emit_decision_trace(
    *,
    decision_type,
    player,
    turn,
    phase,
    available_options,
    chosen_option,
    rejected_options=None,
    score_components=None,
    rule_source="heuristic",
    rule_status="heuristic",
    confidence="medium",
    expected_benefit_score=0,
    actual_outcome=None,
    reason=None,
    replay_id=None,
    strategic_principle=None,
    heuristic_version=None,
    resource_delta=None,
    risk_flags=None,
    alternatives_considered=None,
    rejected_reason=None,
    expected_payoff_reason=None,
):
    """Emit optional decision trace data without changing battle behavior."""
    if DECISION_TRACE_HANDLER is None:
        return
    try:
        options = list(available_options or [])
        chosen = chosen_option or {"action": "pass"}
        chosen_key = _option_identity(chosen)
        if chosen_key and all(_option_identity(option) != chosen_key for option in options):
            options.insert(0, chosen)
        rejected = list(rejected_options or [])
        (
            chosen_option_score,
            available_option_scores,
            rejected_option_scores,
            best_available_option_score,
            best_rejected_option_score,
            score_gap_vs_best_rejected,
        ) = _comparative_option_scores(
            chosen,
            options,
            rejected,
            expected_benefit_score,
        )
        payload = {
            "schema_version": DECISION_TRACE_SCHEMA_VERSION,
            "decision_id": _next_decision_id(replay_id),
            "replay_id": replay_id,
            "turn": turn,
            "phase": phase,
            "player": getattr(player, "name", str(player)),
            "decision_type": decision_type,
            "available_options": options,
            "chosen_option": chosen,
            "rejected_options": rejected,
            "score_components": dict(score_components or {"heuristic": 0}),
            "rule_source": rule_source or "unknown",
            "rule_status": rule_status or "unknown",
            "confidence": confidence,
            "expected_benefit_score": expected_benefit_score,
            "expected_payoff_reason": expected_payoff_reason or reason,
            "actual_outcome": actual_outcome,
            "reason": reason,
            "strategic_principle": strategic_principle
            or _default_strategic_principle(decision_type, reason),
            "heuristic_version": heuristic_version or DECISION_STRATEGY_VERSION,
            "resource_delta": dict(resource_delta or {}),
            "risk_flags": list(risk_flags or []),
            "alternatives_considered": list(
                alternatives_considered if alternatives_considered is not None else options
            ),
            "rejected_reason": rejected_reason,
            "chosen_option_score": chosen_option_score,
            "available_option_scores": available_option_scores,
            "rejected_option_scores": rejected_option_scores,
            "best_available_option_score": best_available_option_score,
            "best_rejected_option_score": best_rejected_option_score,
            "score_gap_vs_best_rejected": score_gap_vs_best_rejected,
        }
        DECISION_TRACE_HANDLER(payload)
    except Exception:
        pass


class ReplacementRegistry:
    """Local proxy that keeps replacement replay events bound to this module."""

    @staticmethod
    def process_event(event):
        return _ReplacementRegistry.process_event(
            event,
            emit_replay_event=emit_replay_event,
        )


def change_life(player, delta):
    return _change_life(player, delta, emit_replay_event=emit_replay_event)


def deal_damage(player, amount):
    return _deal_damage(player, amount, emit_replay_event=emit_replay_event)


def gain_life(player, amount, cap=40):
    return _gain_life(player, amount, cap=cap, emit_replay_event=emit_replay_event)


class EngineMetrics:
    """Lightweight health telemetry for battle-engine simulations."""

    def __init__(self):
        self.counters = defaultdict(int)
        self.event_counts = defaultdict(int)
        self.max_stack_depth = 0
        self.warnings = []

    def increment(self, name, amount=1):
        self.counters[name] += amount

    def record_stack_depth(self, depth):
        self.max_stack_depth = max(self.max_stack_depth, int(depth or 0))

    def record_event(self, event, data=None):
        self.event_counts[event] += 1
        if event == "replacement_applied":
            self.increment("replacement_events")
        elif event == "cast_announced":
            self.increment("cast_announcements")
        elif event == "cast_illegal":
            self.increment("illegal_casts")
        elif event == "permanent_moved_by_sba":
            self.increment("sba_permanent_moves")
        elif event == "player_eliminated":
            self.increment("player_eliminations")
        if data and data.get("warning"):
            self.warnings.append(data["warning"])

    def snapshot(self):
        return {
            "counters": dict(self.counters),
            "event_counts": dict(self.event_counts),
            "max_stack_depth": self.max_stack_depth,
            "warnings": list(self.warnings),
        }


def set_engine_metrics(metrics):
    global ENGINE_METRICS
    ENGINE_METRICS = metrics
    return metrics


def clear_engine_metrics():
    global ENGINE_METRICS
    ENGINE_METRICS = None


def record_engine_metric(name, amount=1):
    if ENGINE_METRICS is not None:
        ENGINE_METRICS.increment(name, amount)


def record_stack_depth(depth):
    if ENGINE_METRICS is not None:
        ENGINE_METRICS.record_stack_depth(depth)


def write_engine_metrics_snapshot(path, metadata=None):
    if ENGINE_METRICS is None or not path:
        return None
    payload = {
        "schema_version": "battle_engine_metrics_v1",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "metadata": metadata or {},
        **ENGINE_METRICS.snapshot(),
    }
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    tmp_path = f"{path}.tmp"
    with open(tmp_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=True, sort_keys=True, indent=2)
        handle.write("\n")
    os.replace(tmp_path, path)
    return payload


def replay_card_snapshot(card):
    """Small JSON-safe card summary for turn-by-turn replay audits."""
    if not isinstance(card, dict):
        return {"name": str(card)}
    return {
        "name": card.get("name", "?"),
        "power": card.get("power"),
        "toughness": card.get("toughness"),
        "cmc": card.get("cmc"),
        "keywords": [
            keyword
            for keyword in (
                "flying",
                "reach",
                "trample",
                "deathtouch",
                "first_strike",
                "double_strike",
                "lifelink",
                "indestructible",
                "haste",
                "vigilance",
                "shroud",
            )
            if card.get(keyword)
        ],
        "is_commander": bool(card.get("is_commander")),
        "type_line": card.get("type_line", ""),
        "tapped": bool(card.get("tapped")),
        "summoning_sick": bool(card.get("summoning_sick")),
    }


class CastingContext:
    """Minimal CR 601.2 casting context with locked cost and legality state."""

    def __init__(
        self,
        card,
        controller,
        phase,
        *,
        additional_generic=0,
        role="normal",
        modes=None,
        alternative_cost=None,
        x_value=0,
        targets=None,
        additional_costs=None,
        source_zone="hand",
        alternative_cost_kind=None,
    ):
        self.card = card
        self.controller = controller
        self.phase = phase
        self.additional_generic = additional_generic
        self.role = role
        self.modes = list(modes or [])
        self.alternative_cost = alternative_cost
        self.x_value = max(0, int(x_value or 0))
        self.targets = list(targets or [])
        self.additional_costs = list(additional_costs or [])
        self.source_zone = source_zone
        self.alternative_cost_kind = alternative_cost_kind
        self.locked_cost = None
        self.effect_data = {}
        self.is_legal = False
        self.paid = False

    def to_replay_fields(self):
        return {
            "cast_pipeline": "601.2_minimal",
            "locked_cost": replay_cost_snapshot(self.locked_cost),
            "additional_generic": self.additional_generic,
            "alternative_cost": self.alternative_cost,
            "x_value": self.x_value,
            "additional_costs": list(self.additional_costs),
            "modes": list(self.modes),
            "targets": list(self.targets),
            "role": self.role,
            "source_zone": self.source_zone,
            "alternative_cost_kind": self.alternative_cost_kind,
        }


def can_cast_in_phase(card, effect_data, phase):
    if is_effective_land(card):
        return False
    if effect_data.get("effect") == "counter":
        return False
    if effect_data.get("effect") == "creature" and phase not in MAIN_PHASES:
        return False
    if is_sorcery(card) and phase not in MAIN_PHASES:
        return False
    return True


def begin_cast_context(
    player,
    card,
    phase,
    *,
    additional_generic=0,
    effect_data=None,
    role="normal",
    modes=None,
    alternative_cost=None,
    x_value=0,
    targets=None,
    additional_costs=None,
    source_zone="hand",
    alternative_cost_kind=None,
):
    """Announce and lock cost for a simplified CR 601.2 cast."""
    ctx = CastingContext(
        card,
        player,
        phase,
        additional_generic=additional_generic,
        role=role,
        modes=modes,
        alternative_cost=alternative_cost,
        x_value=x_value,
        targets=targets,
        additional_costs=additional_costs,
        source_zone=source_zone,
        alternative_cost_kind=alternative_cost_kind,
    )
    ctx.effect_data = effect_data or get_card_effect(card)
    ctx.is_legal = can_cast_in_phase(card, ctx.effect_data, phase)
    ctx.locked_cost = card_mana_cost(
        card,
        additional_generic,
        alternative_cost=alternative_cost,
        x_value=ctx.x_value,
        additional_costs=ctx.additional_costs,
    )
    emit_replay_event(
        "cast_announced",
        player=player.name,
        card=card.get("name", "?"),
        effect=ctx.effect_data.get("effect", "unknown"),
        phase=phase,
        **ctx.to_replay_fields(),
        **replay_rule_fields(ctx.effect_data),
    )
    return ctx


def commit_cast_payment(ctx):
    """Pay the previously locked cost. Returns False without mutating hand/stack."""
    if not ctx.is_legal:
        emit_replay_event(
            "cast_illegal",
            player=ctx.controller.name,
            card=ctx.card.get("name", "?"),
            phase=ctx.phase,
            reason="illegal_timing_or_type",
            **ctx.to_replay_fields(),
        )
        return False
    if not ctx.controller.can_pay(ctx.locked_cost):
        emit_replay_event(
            "cast_illegal",
            player=ctx.controller.name,
            card=ctx.card.get("name", "?"),
            phase=ctx.phase,
            reason="cannot_pay_locked_cost",
            **ctx.to_replay_fields(),
        )
        return False
    ctx.paid = ctx.controller.spend_mana(ctx.locked_cost)
    if not ctx.paid:
        return False
    return True


CONTINUOUS_SUBLAYER_ORDER = {
    "7a": 0,
    "7b": 1,
    "7c": 2,
    "7d": 3,
    "7e": 4,
}


class ContinuousEffect:
    """Serializable continuous effect record for deterministic layer ordering."""

    def __init__(
        self,
        effect_id,
        layer,
        effect_type,
        value=None,
        *,
        timestamp=0,
        sublayer=None,
        depends_on=None,
    ):
        self.effect_id = effect_id
        self.layer = layer
        self.effect_type = effect_type
        self.value = value
        self.timestamp = timestamp
        self.sublayer = sublayer
        self.depends_on = list(depends_on or [])


def _continuous_effect_from_raw(raw):
    if isinstance(raw, ContinuousEffect):
        return raw
    return ContinuousEffect(
        raw.get("effect_id") or raw.get("id") or raw.get("effect_type", "effect"),
        raw.get("layer"),
        raw.get("effect_type"),
        raw.get("value"),
        timestamp=raw.get("timestamp", 0),
        sublayer=raw.get("sublayer"),
        depends_on=raw.get("depends_on") or [],
    )


def order_continuous_effects(effects):
    """Order effects by layer/sublayer/dependency/timestamp (CR 613, simplified)."""
    normalized = [_continuous_effect_from_raw(effect) for effect in effects]
    ordered = []
    remaining = list(normalized)
    applied_ids = set()
    while remaining:
        ready = [
            effect
            for effect in remaining
            if all(dep in applied_ids for dep in effect.depends_on)
        ]
        if not ready:
            ready = list(remaining)
        ready.sort(
            key=lambda effect: (
                int(effect.layer or 0),
                CONTINUOUS_SUBLAYER_ORDER.get(str(effect.sublayer or ""), -1),
                int(effect.timestamp or 0),
                str(effect.effect_id),
            )
        )
        chosen = ready[0]
        ordered.append(chosen)
        applied_ids.add(chosen.effect_id)
        remaining.remove(chosen)
    return ordered


def _card_types(card):
    return [part.strip() for part in str(card.get("type_line") or "").split() if part.strip()]


def _set_card_types(card, types):
    card["type_line"] = " ".join(dict.fromkeys(types))


def _abilities(card):
    current = card.get("abilities", [])
    if isinstance(current, str):
        return [current]
    return list(current or [])


def _set_abilities(card, abilities):
    card["abilities"] = list(dict.fromkeys(abilities))


def is_planeswalker_permanent(card):
    return isinstance(card, dict) and "planeswalker" in str(card.get("type_line") or "").lower()


def is_battle_permanent(card):
    return isinstance(card, dict) and "battle" in str(card.get("type_line") or "").lower()


def handle_planeswalker_etb(card, controller=None):
    if not isinstance(card, dict):
        return card
    card["loyalty"] = int(card.get("loyalty", card.get("starting_loyalty", 3)) or 0)
    card["loyalty_used_this_turn"] = False
    if controller is not None:
        card["controller"] = controller.name
    return card


def can_activate_loyalty(player, planeswalker, phase, stack):
    return (
        is_planeswalker_permanent(planeswalker)
        and planeswalker in player.battlefield
        and not planeswalker.get("loyalty_used_this_turn")
        and phase in MAIN_PHASES
        and stack.empty()
    )


def activate_loyalty_ability(player, planeswalker, loyalty_delta, phase, stack):
    if not can_activate_loyalty(player, planeswalker, phase, stack):
        return False
    planeswalker["loyalty"] = int(planeswalker.get("loyalty", 0) or 0) + int(loyalty_delta)
    planeswalker["loyalty_used_this_turn"] = True
    emit_replay_event(
        "loyalty_ability_activated",
        player=player.name,
        card=planeswalker.get("name", "?"),
        loyalty_delta=loyalty_delta,
        loyalty_after=planeswalker.get("loyalty", 0),
        phase=phase,
    )
    return True


def damage_to_planeswalker(source, planeswalker, amount):
    if not is_planeswalker_permanent(planeswalker) or amount <= 0:
        return False
    planeswalker["loyalty"] = int(planeswalker.get("loyalty", 0) or 0) - int(amount)
    emit_replay_event(
        "planeswalker_damage",
        source=source.get("name", "?") if isinstance(source, dict) else source,
        card=planeswalker.get("name", "?"),
        amount=amount,
        loyalty_after=planeswalker.get("loyalty", 0),
    )
    return True


def handle_siege_etb(card, controller, opponents):
    if not isinstance(card, dict):
        return card
    card["defense"] = int(card.get("defense", card.get("starting_defense", 5)) or 0)
    card["protector"] = opponents[0].name if opponents else None
    card["controller"] = controller.name if controller is not None else card.get("controller")
    return card


def battle_takes_damage(battle_card, amount):
    if not is_battle_permanent(battle_card) or amount <= 0:
        return False
    battle_card["defense"] = int(battle_card.get("defense", 0) or 0) - int(amount)
    emit_replay_event(
        "battle_damage",
        card=battle_card.get("name", "?"),
        amount=amount,
        defense_after=battle_card.get("defense", 0),
        protector=battle_card.get("protector"),
    )
    return True


def resolve_battle_back_face(controller, battle_card):
    """Basic Siege reward: cast/put the back face onto the battlefield."""
    back_face = battle_card.get("back_face") if isinstance(battle_card, dict) else None
    if not isinstance(back_face, dict):
        return None
    permanent = prepare_entering_permanent(enrich_card(copy.deepcopy(back_face)))
    permanent["controller"] = controller.name
    permanent["cast_from_battle_back_face"] = True
    if is_creature_card(permanent):
        permanent["effect"] = "creature"
        permanent["haste"] = has_haste(permanent)
        permanent["summoning_sick"] = not permanent["haste"]
        permanent["tapped"] = False
    controller.battlefield.append(permanent)
    emit_replay_event(
        "battle_back_face_cast",
        player=controller.name,
        battle=battle_card.get("name", "?"),
        card=permanent.get("name", "?"),
        type_line=permanent.get("type_line", ""),
    )
    return permanent


def modern_ability_word_signals(card):
    """Telemetry-only detection for modern ability words.

    These words do not enforce rules by themselves; they mark cards that need
    spent-mana, zone-change or spell-targeting context.
    """
    if not isinstance(card, dict):
        return []
    text = str(card.get("oracle_text", "") or "").lower()
    signals = []
    for word in (
        "void",
        "repartee",
        "opus",
        "increment",
        "infusion",
        "converge",
    ):
        if re.search(rf"\b{word}\b", text):
            signals.append(word)
    return signals


def is_warp_card(card):
    return isinstance(card, dict) and bool(card.get("warp_cost") or card.get("warp"))


def cast_warp_spell_from_hand(player, card, turn, phase):
    """Cast a permanent for its warp cost and schedule end-step exile."""
    if phase not in MAIN_PHASES or not is_warp_card(card) or card not in player.hand:
        return False
    warp_cost = card.get("warp_cost") or card.get("warp")
    effect_data = get_card_effect(card)
    ctx = begin_cast_context(
        player,
        card,
        phase,
        effect_data=effect_data,
        role="warp",
        alternative_cost=warp_cost,
        source_zone="hand",
        alternative_cost_kind="warp",
    )
    if not commit_cast_payment(ctx):
        return False
    player.hand.remove(card)
    permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
    permanent["_warped_this_turn"] = True
    permanent["_warp_pending_exile_turn"] = turn
    permanent["_warp_recast_available"] = False
    if is_creature_card(permanent):
        permanent["effect"] = "creature"
        permanent["haste"] = has_haste(permanent)
        permanent["summoning_sick"] = not permanent["haste"]
        permanent["tapped"] = False
    player.battlefield.append(permanent)
    emit_replay_event(
        "warp_cast",
        player=player.name,
        card=card.get("name", "?"),
        warp_cost=warp_cost,
        turn=turn,
        phase=phase,
        **ctx.to_replay_fields(),
        **replay_rule_fields(effect_data),
    )
    return True


def process_warp_end_step(player, turn):
    """Exile warped permanents at the next end step and allow future recast."""
    moved = []
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict) or not permanent.get("_warped_this_turn"):
            continue
        if permanent.get("_warp_pending_exile_turn") != turn:
            continue
        player.battlefield.remove(permanent)
        permanent["_warped_this_turn"] = False
        permanent["_warp_recast_available"] = True
        move_to_exile(player, permanent, reason="warp", turn=turn)
        moved.append(permanent.get("name", "?"))
    if moved:
        emit_replay_event("warp_exiled_end_step", player=player.name, cards=moved, turn=turn)
    return moved


def cast_warp_card_from_exile(player, card, turn, phase):
    """Recast a card previously exiled by warp using its normal cost."""
    if phase not in MAIN_PHASES or not isinstance(card, dict):
        return False
    if not card.get("_warp_recast_available") or card not in player.exile:
        return False
    effect_data = get_card_effect(card)
    ctx = begin_cast_context(
        player,
        card,
        phase,
        effect_data=effect_data,
        role="warp_recast",
        source_zone="exile",
    )
    if not commit_cast_payment(ctx):
        return False
    player.exile.remove(card)
    permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
    permanent.pop("_warp_recast_available", None)
    permanent.pop("_exile_reason", None)
    if is_creature_card(permanent):
        permanent["effect"] = "creature"
        permanent["haste"] = has_haste(permanent)
        permanent["summoning_sick"] = not permanent["haste"]
        permanent["tapped"] = False
    player.battlefield.append(permanent)
    emit_replay_event(
        "warp_recast_from_exile",
        player=player.name,
        card=card.get("name", "?"),
        turn=turn,
        phase=phase,
        **ctx.to_replay_fields(),
        **replay_rule_fields(effect_data),
    )
    return True


def cast_flashback_spell_from_graveyard(player, card, opponents, all_players, turn, phase, stack, rng):
    """Cast an instant/sorcery from graveyard for flashback, exiling on resolution."""
    if not isinstance(card, dict) or card not in player.graveyard:
        return False
    flashback_cost = card.get("flashback_cost") or card.get("flashback")
    if not flashback_cost:
        return False
    if not is_instant(card) and not (is_sorcery(card) and phase in MAIN_PHASES):
        return False
    effect_data = get_card_effect(card)
    ctx = begin_cast_context(
        player,
        card,
        phase,
        effect_data=effect_data,
        role="flashback",
        alternative_cost=flashback_cost,
        source_zone="graveyard",
        alternative_cost_kind="flashback",
    )
    if not commit_cast_payment(ctx):
        return False
    player.graveyard.remove(card)
    flashback_copy = copy.deepcopy(card)
    flashback_copy["_flashback_cast"] = True
    emit_replay_event(
        "flashback_cast",
        player=player.name,
        card=card.get("name", "?"),
        flashback_cost=flashback_cost,
        turn=turn,
        phase=phase,
        **ctx.to_replay_fields(),
        **replay_rule_fields(effect_data),
    )
    trigger_spell_cast_engines(
        player, all_players, flashback_copy, turn, phase, stack=stack, active_player=player
    )
    trigger_opponent_spell_draw_engines(
        player,
        opponents,
        flashback_copy,
        turn,
        phase,
        rng,
        stack=stack,
        active_player=player,
        all_players=all_players,
    )
    stack.push(flashback_copy, player, effect_data)
    return True


def is_station_card(card):
    return isinstance(card, dict) and (
        "station" in str(card.get("type_line", "")).lower()
        or bool(card.get("station_threshold"))
    )


def activate_station_ability(player, station, tapper, phase, stack):
    """Minimal station action: tap another creature and add charge counters."""
    if phase not in MAIN_PHASES or not stack.empty():
        return False
    if station not in player.battlefield or tapper not in player.battlefield:
        return False
    if station is tapper or not is_station_card(station) or not is_battlefield_creature(tapper):
        return False
    if tapper.get("tapped") or tapper.get("summoning_sick"):
        return False
    tapper["tapped"] = True
    added = int(tapper.get("power") or 0)
    station["charge_counters"] = int(station.get("charge_counters") or 0) + max(0, added)
    threshold = int(station.get("station_threshold") or station.get("unlock_threshold") or 0)
    if threshold and station["charge_counters"] >= threshold:
        station["station_online"] = True
        if is_vehicle_or_spacecraft_card(station):
            station["effect"] = "creature"
    emit_replay_event(
        "station_activated",
        player=player.name,
        card=station.get("name", "?"),
        tapper=tapper.get("name", "?"),
        counters_added=max(0, added),
        total_counters=station["charge_counters"],
        station_online=bool(station.get("station_online")),
        phase=phase,
    )
    return True


def prepare_spell_copy(player, source_card, prepared_creature, turn):
    """Create a castable prepared copy in exile linked to a creature."""
    if not isinstance(source_card, dict) or not isinstance(prepared_creature, dict):
        return None
    prepared_copy = get_card_characteristics(source_card, "exile", cast_mode="prepare")
    prepared_copy["_prepared_copy"] = True
    prepared_copy["_prepared_source_name"] = source_card.get("name")
    prepared_copy["_prepared_creature_id"] = id(prepared_creature)
    prepared_copy["_prepared_available"] = True
    move_to_exile(player, prepared_copy, reason="prepare", turn=turn)
    emit_replay_event(
        "prepared_copy_created",
        player=player.name,
        source=source_card.get("name", "?"),
        card=prepared_copy.get("name", "?"),
        prepared_creature=prepared_creature.get("name", "?"),
        turn=turn,
    )
    return prepared_copy


def cleanup_prepared_copies(player, prepared_creature):
    """Remove prepared copies when the linked creature is no longer prepared."""
    removed = []
    creature_id = id(prepared_creature)
    for card in list(player.exile):
        if isinstance(card, dict) and card.get("_prepared_creature_id") == creature_id:
            player.exile.remove(card)
            removed.append(card.get("name", "?"))
    if removed:
        emit_replay_event(
            "prepared_copies_removed",
            player=player.name,
            prepared_creature=prepared_creature.get("name", "?"),
            cards=removed,
        )
    return removed


def resolve_paradigm_spell(player, card, turn):
    """Track a resolved Paradigm spell as a future first-main copy source."""
    if not isinstance(card, dict):
        return None
    paradigm_card = copy.deepcopy(card)
    paradigm_card["_paradigm_available"] = True
    move_to_exile(player, paradigm_card, reason="paradigm", turn=turn)
    emit_replay_event(
        "paradigm_exiled",
        player=player.name,
        card=card.get("name", "?"),
        turn=turn,
    )
    return paradigm_card


def create_lander_token(player, name="Lander Token"):
    token = create_creature_token(
        player,
        name=name,
        power=1,
        toughness=1,
        artifact=True,
    )
    token["subtype"] = "Lander"
    token["lander_token"] = True
    return token


def finish_countered_spell(player, card):
    return _finish_countered_spell(player, card, move_to_exile_func=move_to_exile)


def finish_resolved_spell(player, card, turn=None):
    return _finish_resolved_spell(
        player,
        card,
        turn=turn,
        move_to_exile_func=move_to_exile,
        emit_replay_event=emit_replay_event,
    )


def commander_origin_id(card, owner_name=None):
    """Stable identity for one physical commander across zone changes."""
    if not isinstance(card, dict):
        return "unknown"
    explicit = card.get("commander_origin_id") or card.get("_commander_origin_id")
    if explicit:
        return str(explicit)
    origin = (
        card.get("oracle_id")
        or card.get("scryfall_id")
        or f"{owner_name or card.get('owner') or '?'}:{card.get('name', '?')}"
    )
    card["_commander_origin_id"] = str(origin)
    return str(origin)


def commander_damage_key(defender_name, commander_card, owner_name=None):
    return f"{defender_name}::{commander_origin_id(commander_card, owner_name)}"


def commander_damage_target_from_key(key):
    return str(key).split("::", 1)[0]


def commander_damage_lethal_entries(player):
    ledger = getattr(player, "commander_damage_by_source", None)
    if ledger:
        for key, damage in ledger.items():
            if damage >= 21:
                yield commander_damage_target_from_key(key), damage, key
        return
    for target_name, damage in player.commander_damage.items():
        if damage >= 21:
            yield target_name, damage, None


def apply_continuous_effects(card, effects):
    """Return a characteristics snapshot after applying continuous effects."""
    result = copy.deepcopy(card)
    applied = []
    for effect in order_continuous_effects(effects):
        value = effect.value
        if effect.layer == 1 and effect.effect_type == "copy" and isinstance(value, dict):
            result.update(copy.deepcopy(value))
        elif effect.layer == 2 and effect.effect_type == "set_controller":
            result["controller"] = value
        elif effect.layer == 3 and effect.effect_type == "replace_text" and isinstance(value, dict):
            result["oracle_text"] = str(result.get("oracle_text") or "").replace(
                str(value.get("from", "")),
                str(value.get("to", "")),
            )
        elif effect.layer == 4:
            types = _card_types(result)
            if effect.effect_type == "set_type":
                types = list(value or [])
            elif effect.effect_type == "add_type":
                types.extend(list(value or []))
            elif effect.effect_type == "remove_type":
                remove = set(value or [])
                types = [card_type for card_type in types if card_type not in remove]
            _set_card_types(result, types)
        elif effect.layer == 5:
            colors = list(result.get("colors") or [])
            if effect.effect_type == "set_color":
                colors = list(value or [])
            elif effect.effect_type == "add_color":
                colors.extend(list(value or []))
            result["colors"] = list(dict.fromkeys(colors))
        elif effect.layer == 6:
            abilities = _abilities(result)
            if effect.effect_type == "add_ability":
                abilities.extend(list(value or []))
            elif effect.effect_type == "remove_ability":
                remove = set(value or [])
                abilities = [ability for ability in abilities if ability not in remove]
            _set_abilities(result, abilities)
        elif effect.layer == 7:
            if effect.effect_type in ("set_pt", "cda_set_pt") and isinstance(value, dict):
                result["power"] = value.get("power", result.get("power", 0))
                result["toughness"] = value.get("toughness", result.get("toughness", 0))
            elif effect.effect_type in ("modify_pt", "counter_pt") and isinstance(value, dict):
                result["power"] = int(result.get("power") or 0) + int(value.get("power", 0) or 0)
                result["toughness"] = int(result.get("toughness") or 0) + int(value.get("toughness", 0) or 0)
            elif effect.effect_type == "switch_pt":
                result["power"], result["toughness"] = result.get("toughness", 0), result.get("power", 0)
        applied.append(effect.effect_id)
    result["_continuous_effects_applied"] = applied
    return result


SELF_KEYWORD_ABILITIES = {
    "flying",
    "reach",
    "trample",
    "deathtouch",
    "first_strike",
    "double_strike",
    "lifelink",
    "indestructible",
    "haste",
    "vigilance",
    "flash",
    "menace",
    "infect",
}


def _keyword_values(card):
    keyword_values = card.get("keywords") or []
    if isinstance(keyword_values, str):
        keyword_values = read_json_list(keyword_values) or [keyword_values]
    return {
        str(value).lower().replace(" ", "_")
        for value in keyword_values
        if str(value).strip()
    }


def _oracle_self_keyword_values(card):
    oracle_text = str(card.get("oracle_text") or "").strip()
    if not oracle_text:
        return set()
    first_line = oracle_text.splitlines()[0].strip()
    first_line = re.sub(r"\([^)]*\)", "", first_line).strip().rstrip(".")
    if not first_line:
        return set()
    parts = [
        part.strip().lower().replace(" ", "_")
        for part in re.split(r"[,;]", first_line)
        if part.strip()
    ]
    if not parts or any(part not in SELF_KEYWORD_ABILITIES for part in parts):
        return set()
    return set(parts)


def enrich_card(card):
    """Preserve imported metadata and expose only self-owned combat keywords."""
    enriched = dict(card)
    keyword_values = _oracle_self_keyword_values(enriched)
    if enriched.get("_keywords_are_self") or not str(enriched.get("oracle_text") or "").strip():
        keyword_values |= _keyword_values(enriched)
    for keyword in SELF_KEYWORD_ABILITIES:
        if keyword in keyword_values:
            enriched[keyword] = True
    return enriched


def card_has_keyword(card, keyword):
    """Check explicit fields plus self-owned keyword abilities only."""
    if not isinstance(card, dict):
        return False
    normalized_keyword = str(keyword or "").lower().replace(" ", "_")
    if card.get(normalized_keyword):
        return True
    if normalized_keyword in _oracle_self_keyword_values(card):
        return True
    if card.get("_keywords_are_self") or not str(card.get("oracle_text") or "").strip():
        return normalized_keyword in _keyword_values(card)
    return False


def has_haste(card):
    return card_has_keyword(card, "haste")


def has_vigilance(card):
    return card_has_keyword(card, "vigilance")


def is_battlefield_creature(card):
    """Permanent-level creature check; effects can add extra roles."""
    if not isinstance(card, dict):
        return False
    return (
        card.get("effect") == "creature"
        or bool(card.get("is_creature_permanent"))
        or "creature" in str(card.get("type_line") or "").lower()
    )


def is_mana_source_permanent(source):
    if source == "land":
        return True
    if not isinstance(source, dict):
        return False
    if source.get("effect") in ("land", "ramp_permanent"):
        return True
    if source.get("is_mana_source"):
        return True
    return source.get("effect") == "ramp_engine" and source.get("mana_produced") is not None


def is_legendary_creature_or_planeswalker_permanent(card):
    if not isinstance(card, dict):
        return False
    type_line = str(card.get("type_line") or "").lower()
    return "legendary" in type_line and (
        "creature" in type_line or "planeswalker" in type_line
    )


def mana_source_production_for_state(player, source):
    if source == "land":
        return 1
    if not isinstance(source, dict):
        return 0
    normalized_name = normalize_card_name(source.get("name", ""))
    if normalized_name == "mox amber":
        if not any(
            is_legendary_creature_or_planeswalker_permanent(permanent)
            for permanent in player.battlefield
            if isinstance(permanent, dict)
        ):
            return 0
    return int(source.get("mana_produced", 1) or 0)


def numeric_stat(value):
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def load_card_oracle_cache(conn, names):
    """Load production card metadata previously synced into local SQLite."""
    normalized_names = sorted({normalize_card_name(name) for name in names if name})
    if not normalized_names:
        return {}
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='card_oracle_cache'"
    ).fetchone()
    if not table:
        return {}

    cache = {}
    for index in range(0, len(normalized_names), 500):
        chunk = normalized_names[index:index + 500]
        placeholders = ",".join("?" for _ in chunk)
        rows = conn.execute(f"""
            SELECT normalized_name, name, mana_cost, colors_json,
                   color_identity_json, type_line, oracle_text, cmc, power,
                   toughness, keywords_json, scryfall_id
            FROM card_oracle_cache
            WHERE normalized_name IN ({placeholders})
        """, chunk).fetchall()
        for row in rows:
            cache[row["normalized_name"]] = {
                "oracle_name": row["name"],
                "mana_cost": row["mana_cost"],
                "colors": read_json_list(row["colors_json"]),
                "color_identity": read_json_list(row["color_identity_json"]),
                "type_line": row["type_line"],
                "oracle_text": row["oracle_text"],
                "cmc": row["cmc"],
                "power": numeric_stat(row["power"]),
                "toughness": numeric_stat(row["toughness"]),
                "keywords": read_json_list(row["keywords_json"]),
                "scryfall_id": row["scryfall_id"],
            }
    return cache


def merge_oracle_metadata(card, oracle_cache):
    metadata = oracle_cache.get(normalize_card_name(card.get("name")))
    if not metadata:
        return card
    enriched = dict(card)
    for key in (
        "mana_cost",
        "type_line",
        "oracle_text",
        "cmc",
        "power",
        "toughness",
        "scryfall_id",
        "oracle_name",
    ):
        value = metadata.get(key)
        if value is not None and value != "":
            enriched[key] = value
    for key in ("colors", "color_identity", "keywords"):
        value = metadata.get(key)
        if value:
            enriched[key] = value
    return enriched


# ═══════════════════════════════════════════
# DECK LOADING
# ═══════════════════════════════════════════

def normalize_functional_tag(value):
    return re.sub(r"\s+", "_", str(value or "").strip().lower())


def functional_tags_from_values(tags_value=None, fallback_tag=None):
    tags = []
    for raw in read_json_list(tags_value):
        tag = normalize_functional_tag(raw)
        if tag and tag != "unknown" and tag not in tags:
            tags.append(tag)
    fallback = normalize_functional_tag(fallback_tag)
    if fallback and fallback != "unknown" and fallback not in tags:
        tags.append(fallback)
    return tags


def card_functional_tags(card):
    tags = []
    for raw in card.get("functional_tags") or []:
        tag = normalize_functional_tag(raw)
        if tag and tag != "unknown" and tag not in tags:
            tags.append(tag)
    fallback = normalize_functional_tag(card.get("tag"))
    if fallback and fallback != "unknown" and fallback not in tags:
        tags.append(fallback)
    return tags


def card_has_functional_tag(card, *tags):
    wanted = {normalize_functional_tag(tag) for tag in tags}
    return bool(wanted.intersection(card_functional_tags(card)))


def commander_deck_color_identity(cards):
    colors = set()
    for card in cards:
        colors.update(compute_color_identity(card))
    return sorted(colors)


def card_allows_multiple_copies(card):
    if not isinstance(card, dict):
        return False
    type_line = str(card.get("type_line") or "")
    if "Basic" in type_line and "Land" in type_line:
        return True
    if normalize_card_name(card.get("name")) in {
        "plains",
        "island",
        "swamp",
        "mountain",
        "forest",
        "wastes",
    }:
        return True
    oracle = str(card.get("oracle_text") or "").lower()
    return "a deck can have any number of cards named" in oracle


def deck_card_singleton_key(card):
    card_id = str(card.get("card_id") or "").strip()
    if card_id:
        return f"id:{card_id}"
    return f"name:{normalize_card_name(card.get('oracle_name') or card.get('name'))}"


def build_deck_construction_report(commanders, deck, expected_format="commander"):
    commanders = list(commanders or [])
    deck = list(deck or [])
    commander_colors = set(commander_deck_color_identity(commanders))
    singleton_counts = defaultdict(lambda: {"count": 0, "card": None})

    for card in deck:
        if card_allows_multiple_copies(card):
            continue
        key = deck_card_singleton_key(card)
        singleton_counts[key]["count"] += 1
        singleton_counts[key]["card"] = card

    singleton_violations = []
    for entry in singleton_counts.values():
        if entry["count"] <= 1:
            continue
        card = entry["card"] or {}
        singleton_violations.append({
            "name": card.get("oracle_name") or card.get("name") or "Unknown",
            "count": entry["count"],
            "card_id": card.get("card_id") or "",
        })

    color_identity_checked = bool(commanders)
    off_color_cards = []
    if color_identity_checked:
        for card in deck:
            card_colors = set(compute_color_identity(card))
            extra_colors = sorted(card_colors - commander_colors)
            if not extra_colors:
                continue
            off_color_cards.append({
                "name": card.get("oracle_name") or card.get("name") or "Unknown",
                "card_id": card.get("card_id") or "",
                "color_identity": sorted(card_colors),
                "off_identity_colors": extra_colors,
            })

    main_quantity = len(deck)
    commander_count = len(commanders)
    total_quantity = main_quantity + commander_count
    issues = []
    if expected_format == "commander":
        if commander_count != 1:
            issues.append(f"expected_1_commander_found_{commander_count}")
        if main_quantity != 99:
            issues.append(f"expected_99_main_cards_found_{main_quantity}")
        if total_quantity != 100:
            issues.append(f"expected_100_total_cards_found_{total_quantity}")
        if singleton_violations:
            issues.append("singleton_violations")
        if off_color_cards:
            issues.append("off_color_cards")
        if not color_identity_checked:
            issues.append("color_identity_not_checked_without_commander")

    return {
        "format": expected_format,
        "is_valid": not issues,
        "issues": issues,
        "commander_count": commander_count,
        "commander_names": [
            card.get("oracle_name") or card.get("name") or "Unknown"
            for card in commanders
        ],
        "commander_color_identity": sorted(commander_colors),
        "main_quantity": main_quantity,
        "total_quantity": total_quantity,
        "singleton_violations": singleton_violations,
        "off_color_cards": off_color_cards,
        "color_identity_checked": color_identity_checked,
    }


def load_deck_cards(deck_id=6):
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    columns = {row[1] for row in conn.execute("PRAGMA table_info(deck_cards)")}
    functional_tags_expr = (
        "functional_tags_json"
        if "functional_tags_json" in columns
        else "'[]' AS functional_tags_json"
    )
    card_id_expr = "card_id" if "card_id" in columns else "NULL AS card_id"
    semantics_hash_expr = (
        "semantics_hash" if "semantics_hash" in columns else "NULL AS semantics_hash"
    )
    rows = conn.execute("""
        SELECT card_name, quantity, CAST(COALESCE(cmc,0) AS REAL) as cmc,
               COALESCE(functional_tag,'unknown') as functional_tag,
               {functional_tags_expr},
               type_line, oracle_text, is_commander,
               {card_id_expr},
               {semantics_hash_expr}
        FROM deck_cards WHERE deck_id=?
    """.format(
        functional_tags_expr=functional_tags_expr,
        card_id_expr=card_id_expr,
        semantics_hash_expr=semantics_hash_expr,
    ), (deck_id,)).fetchall()
    oracle_cache = load_card_oracle_cache(conn, [row["card_name"] for row in rows])
    conn.close()
    commanders = []
    deck = []
    for row in rows:
        qty = row["quantity"] or 1
        functional_tags = functional_tags_from_values(
            row["functional_tags_json"],
            row["functional_tag"],
        )
        card = merge_oracle_metadata({
            "name": row["card_name"],
            "cmc": float(row["cmc"] or 0),
            "tag": functional_tags[0] if functional_tags else (row["functional_tag"] or "unknown"),
            "functional_tags": functional_tags,
            "type_line": row["type_line"] or "",
            "oracle_text": row["oracle_text"] or "",
            "is_commander": bool(row["is_commander"]),
            "card_id": row["card_id"] or "",
            "semantic_hash": row["semantics_hash"] or "",
            "semantics_hash": row["semantics_hash"] or "",
        }, oracle_cache)
        card = enrich_card(card)
        if card["is_commander"]:
            for _ in range(qty):
                commanders.append(card)
        else:
            for _ in range(qty): deck.append(card)
    return commanders, deck


def load_deck(deck_id=6):
    commanders, deck = load_deck_cards(deck_id)
    commander = commanders[-1] if commanders else None
    return commander, deck


def load_deck_with_construction_report(deck_id=6):
    commanders, deck = load_deck_cards(deck_id)
    commander = commanders[-1] if commanders else None
    report = build_deck_construction_report(commanders, deck)
    return commander, deck, report

# ═══════════════════════════════════════════
# CARD EFFECTS
# ═══════════════════════════════════════════

KNOWN_CARDS = {}
# Manual runtime rules are intentionally empty in normal operation. Tests or
# incident waivers may inject explicit entries, but production semantics must
# come from battle_card_rules or the canonical snapshot. Generated legacy known
# cards are intentionally not a battle runtime fallback anymore: the current
# canonical snapshot fully covers that file and avoids stale generated effects.
HANDCRAFTED_KNOWN_CARD_RULES = {}
HANDCRAFTED_KNOWN_CARDS = set()

# Cards listed here intentionally bypass card_battle_rules and resolve from the
# handcrafted table first. Keep this empty by default and require an explicit
# operational waiver for any temporary runtime-first exception.
# Runtime hotfixes for cards whose reviewed battle semantics need to override
# stale promoted rows until the canonical snapshot/SQLite pipeline is refreshed.
# Keep empty by default; any temporary waiver must be audited and short-lived.
MANUAL_RULE_RUNTIME_WAIVERS = set()

TAG_EFFECTS = {
    "ramp": {"effect": "ramp_permanent", "mana_produced": 1},
    "ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "draw": {"effect": "draw_cards", "count": 2},
    "removal": {"effect": "remove_creature"},
    "board_wipe": {"effect": "board_wipe"},
    "protection": {"effect": "indestructible", "duration": 1},
    "token_maker": {"effect": "token_maker", "token_count": 5, "token_power": 2},
    "wincon": {"effect": "finisher"},
    "tutor": {"effect": "tutor", "target": "any"},
    "recursion": {"effect": "recursion", "count": 2},
    "pump": {"effect": "pump_one", "power_boost": 3},
    "loot": {"effect": "loot", "count": 1},
}


def replay_card_identity_fields(card):
    """Return stable card identity fields already present on the card object."""
    fields = {}
    card_id = card.get("card_id") or card.get("card_uuid")
    semantic_hash = card.get("semantic_hash") or card.get("semantics_hash")
    if card_id:
        fields["card_id"] = card_id
    if semantic_hash:
        fields["semantic_hash"] = semantic_hash
    return fields


def annotate_effect_identity(card, effect_data):
    annotated = dict(effect_data)
    for key, value in replay_card_identity_fields(card).items():
        annotated.setdefault(key, value)
    return annotated


def normalize_effect_by_oracle(card, effect_data):
    """Correct broad generated/tag mistakes using imported oracle metadata."""
    normalized = annotate_effect_identity(card, effect_data)
    effect = normalized.get("effect", "unknown")
    normalized_name = normalize_card_name(card.get("name", ""))
    type_line = str(card.get("type_line") or "")
    oracle_text = str(card.get("oracle_text") or "")
    text = f"{type_line}\n{oracle_text}".lower()

    if effect == "worldfire_reset":
        return normalized

    if (
        "exile all permanents" in text
        and "exile all cards from all hands and graveyards" in text
        and "life total becomes 1" in text
    ):
        normalized["effect"] = "worldfire_reset"
        return normalized

    type_line_lower = type_line.lower()
    is_split_spell_land = "//" in type_line and any(
        spell_kind in type_line_lower
        for spell_kind in ("instant", "sorcery", "creature", "artifact", "enchantment")
    )
    if "land" in type_line_lower and not is_split_spell_land:
        normalized["effect"] = "land"
        normalized.pop("instant", None)
        normalized.pop("miracle", None)
        if normalized_name == "ancient tomb":
            # Under the current pooled-mana abstraction, Ancient Tomb cannot
            # expose {C}{C} passively or it becomes free fast mana. Model it as
            # one baseline colorless source plus one contextual bonus mana that
            # costs life only when the simulator chooses to use it.
            normalized["produces"] = "C"
            normalized["mana_produced"] = 1
            normalized["ancient_tomb_bonus_mana"] = 1
            normalized["ancient_tomb_bonus_life_cost"] = 2
            normalized["utility_land_profile"] = "ancient_tomb_contextual_fast_mana_v1"
        return normalized

    if "counter target" in text:
        normalized["effect"] = "counter"
        normalized["instant"] = True
        return normalized

    if "return target spell" in text:
        normalized["effect"] = "counter"
        normalized["instant"] = True
        return normalized

    if re.search(r"\b(destroy|exile)\s+target\b", text):
        is_immediate_spell = "instant" in type_line.lower() or "sorcery" in type_line.lower()
        if (
            not is_immediate_spell
            and effect not in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg")
        ):
            return normalized
        if (
            normalized.get("effect") == "overload_recursion"
            and "graveyard" in text
            and ("instant" in text or "sorcery" in text)
        ):
            return normalized
        if normalized.get("effect") == "remove_artifact_or_3dmg":
            return normalized
        if re.search(r"\b(destroy|exile)\s+target\s+artifact\s+or\s+enchantment\b", text):
            normalized["effect"] = "remove_permanent"
            normalized["target"] = "artifact_or_enchantment"
            return normalized
        if re.search(r"\b(destroy|exile)\s+target\s+artifact(?:[.;\n]|$)", text):
            normalized["effect"] = "remove_permanent"
            normalized["target"] = "artifact"
            return normalized
        if re.search(r"\b(destroy|exile)\s+target\s+enchantment(?:[.;\n]|$)", text):
            normalized["effect"] = "remove_permanent"
            normalized["target"] = "enchantment"
            return normalized
        if "target nonland permanent" in text:
            normalized["effect"] = "remove_permanent"
            normalized["target"] = "nonland_permanent"
            return normalized
        if "target creature" in text:
            normalized["effect"] = "remove_creature"
            normalized["target"] = "creature"
        else:
            normalized["effect"] = "remove_permanent"
        return normalized

    if "from your graveyard" in text and re.search(r"\breturn target\b", text):
        is_immediate_spell = "instant" in type_line.lower() or "sorcery" in type_line.lower()
        if not is_immediate_spell and effect not in ("recursion", "overload_recursion"):
            return normalized
        normalized["effect"] = "recursion"
        return normalized

    if re.search(r"\breturn target\b", text):
        normalized["effect"] = "remove_permanent"
        return normalized

    if (
        ("return each" in text or "return all" in text)
        and "nonland permanent" in text
    ):
        normalized["effect"] = "board_wipe"
        return normalized

    if (
        effect == "silence_opponents"
        and "can't be countered" in text
        and not re.search(r"opponents? can't cast", text)
        and "can't cast spells" not in text
    ):
        if "creature" in type_line.lower():
            normalized["effect"] = "creature"
        else:
            normalized["effect"] = "unknown"
    return normalized


def with_rule_metadata(
    effect_data,
    *,
    source,
    review_status="heuristic",
    execution_status="auto",
    confidence=0.0,
    rule_version=None,
    logical_rule_key=None,
    oracle_hash=None,
):
    annotated = dict(effect_data)
    annotated.setdefault("_rule_source", source)
    annotated.setdefault("_rule_review_status", review_status)
    annotated.setdefault("_rule_execution_status", execution_status)
    annotated.setdefault("_rule_confidence", confidence)
    if rule_version is not None:
        annotated.setdefault("_rule_version", rule_version)
    if logical_rule_key:
        annotated.setdefault("_rule_logical_key", logical_rule_key)
    if oracle_hash:
        annotated.setdefault("_rule_oracle_hash", oracle_hash)
    return annotated


def replay_rule_fields(effect_data):
    """Expose rule provenance in structured replay events."""
    fields = {
        "rule_source": effect_data.get("_rule_source", "unknown"),
        "rule_review_status": effect_data.get("_rule_review_status", "unknown"),
        "rule_execution_status": effect_data.get("_rule_execution_status", "auto"),
        "rule_confidence": effect_data.get("_rule_confidence", 0.0),
        "rule_version": effect_data.get("_rule_version"),
    }
    optional_fields = {
        "card_id": effect_data.get("card_id"),
        "semantic_hash": effect_data.get("semantic_hash")
        or effect_data.get("semantics_hash"),
        "rule_logical_key": effect_data.get("_rule_logical_key"),
        "rule_oracle_hash": effect_data.get("_rule_oracle_hash"),
        "variant_kind": effect_data.get("variant_kind"),
        "source_zone": effect_data.get("source_zone"),
        "alternative_cost_kind": effect_data.get("alternative_cost_kind")
        or effect_data.get("alternate_cost_kind"),
    }
    for key, value in optional_fields.items():
        if value not in (None, "", [], {}):
            fields[key] = value
    rule_alternative_count = len(effect_data.get("_rule_alternatives") or [])
    if rule_alternative_count:
        fields["rule_alternative_count"] = rule_alternative_count
    blocked_alternative_count = len(effect_data.get("_rule_blocked_alternatives") or [])
    if blocked_alternative_count:
        fields["rule_blocked_alternative_count"] = blocked_alternative_count
    runtime_selection = effect_data.get("_rule_runtime_selection") or {}
    selection_mode = runtime_selection.get("selection_mode")
    if selection_mode:
        fields["rule_runtime_selection_mode"] = selection_mode
    merged_annotation_count = runtime_selection.get("merged_annotation_count")
    if merged_annotation_count:
        fields["rule_merged_annotation_count"] = merged_annotation_count
    composite_component_count = len(effect_data.get("_composite_rule_components") or [])
    if composite_component_count:
        fields["composite_rule_component_count"] = composite_component_count
    return fields


CANONICAL_FALLBACK_KNOWN_CARDS = set()


COMPOSABLE_RESOLUTION_EFFECTS = {
    "draw_cards",
    "remove_creature",
    "remove_permanent",
    "remove_artifact_or_3dmg",
    "ramp_ritual",
    "treasure_maker",
    "token_maker",
    "extra_turn",
    "extra_combat",
}

COMPOSITE_BLOCKING_EFFECT_KEYS = {
    "additional_cost",
    "sacrifice",
    "sacrifice_land",
    "sacrifice_creature",
    "sacrifice_artifact",
    "discard_land",
    "exiles_self",
    "trigger",
    "activated",
    "static",
}

SAFE_RUNTIME_SECONDARY_ANNOTATION_KEYS = {
    "requires_discard_card",
    "requires_discard_land",
    "requires_sacrifice_creature",
    "requires_sacrifice_green_creature",
    "requires_sacrifice_land",
}

SAFE_RUNTIME_SECONDARY_DESCRIPTOR_KEYS = {
    "effect",
    "cmc",
    "battle_model_scope",
    "sorcery",
    "instant",
    "target",
    "timing",
    "subtype",
}


def _battle_rule_summary(rule):
    effect = rule.get("effect_json") or {}
    deck_role = rule.get("deck_role_json") or {}
    return {
        "logical_rule_key": rule.get("logical_rule_key"),
        "effect": effect.get("effect"),
        "category": deck_role.get("category"),
        "source": rule.get("source"),
        "review_status": rule.get("review_status"),
        "execution_status": rule.get("execution_status", "auto"),
        "confidence": rule.get("confidence"),
    }


def _rule_execution_status(rule):
    return str(rule.get("execution_status") or "auto").lower()


def _select_primary_runtime_rule(rules):
    for rule in rules:
        if not rule or not rule.get("effect_json"):
            continue
        execution_status = _rule_execution_status(rule)
        if execution_status in {"annotation_only", "review_only", "disabled"}:
            continue
        review_status = str(rule.get("review_status") or "").lower()
        if review_status not in {"verified", "active"}:
            continue
        return rule
    return None


def _runtime_rule_skip_reason(rule):
    """Explain why a second rule for the same card is not auto-executed."""
    effect = rule.get("effect_json") or {}
    execution_status = _rule_execution_status(rule)
    if execution_status == "disabled":
        return "execution_status_disabled"
    if execution_status == "review_only":
        return "execution_status_review_only"
    if execution_status == "annotation_only":
        return "execution_status_annotation_only"
    review_status = str(rule.get("review_status") or "").lower()
    if review_status not in {"verified", "active"}:
        return "review_status_not_runtime_safe"
    if effect.get("activated_mana_ability") or effect.get("ability_kind") == "activated":
        return "activated_ability_requires_executor"
    if effect.get("trigger") or effect.get("ability_kind") == "triggered":
        return "trigger_requires_event_hook"
    if effect.get("ability_kind") == "static":
        return "static_effect_requires_state_layer"
    for key in COMPOSITE_BLOCKING_EFFECT_KEYS:
        if effect.get(key):
            return f"blocked_by_{key}"
    if effect.get("compose_on_resolution") is True and effect.get("effect") in COMPOSABLE_RESOLUTION_EFFECTS:
        return "composable_but_not_opted_as_primary"
    return "multi_rule_requires_explicit_selector"


def _annotate_runtime_rule_selection(effect, rules, *, selection_mode):
    annotated = dict(effect)
    annotated["_rule_runtime_selection"] = {
        "selection_mode": selection_mode,
        "selected_logical_rule_key": annotated.get("_rule_logical_key"),
        "selected_effect": annotated.get("effect"),
        "rule_count": len(rules),
    }
    annotated["_rule_alternatives"] = [
        _battle_rule_summary(rule)
        for rule in rules
        if rule
    ]
    blocked = []
    selected_key = str(annotated.get("_rule_logical_key") or "")
    for rule in rules:
        if not rule:
            continue
        if str(rule.get("logical_rule_key") or "") == selected_key:
            continue
        summary = _battle_rule_summary(rule)
        summary["runtime_reason"] = _runtime_rule_skip_reason(rule)
        blocked.append(summary)
    if blocked:
        annotated["_rule_blocked_alternatives"] = blocked
        annotated["_rule_runtime_selection"]["blocked_alternative_count"] = len(blocked)
    return annotated


def _build_runtime_rule_selection_with_merged_annotations(
    effect,
    rules,
    *,
    selection_mode,
    merged_rules,
    blocked_rules,
):
    annotated = dict(effect)
    annotated["_rule_runtime_selection"] = {
        "selection_mode": selection_mode,
        "selected_logical_rule_key": annotated.get("_rule_logical_key"),
        "selected_effect": annotated.get("effect"),
        "rule_count": len(rules),
        "merged_annotation_count": len(merged_rules),
    }
    annotated["_rule_alternatives"] = [
        _battle_rule_summary(rule)
        for rule in rules
        if rule
    ]
    if merged_rules:
        annotated["_rule_merged_alternatives"] = [
            _battle_rule_summary(rule)
            for rule in merged_rules
            if rule
        ]
    if blocked_rules:
        annotated["_rule_blocked_alternatives"] = blocked_rules
        annotated["_rule_runtime_selection"]["blocked_alternative_count"] = len(blocked_rules)
    return annotated


def _annotated_battle_rule_effect(rule):
    return with_rule_metadata(
        rule.get("effect_json") or {},
        source=rule.get("source", "battle_card_rules"),
        review_status=rule.get("review_status", "unknown"),
        execution_status=rule.get("execution_status", "auto"),
        confidence=rule.get("confidence", 0.0),
        rule_version=rule.get("rule_version"),
        logical_rule_key=rule.get("logical_rule_key"),
        oracle_hash=rule.get("oracle_hash"),
    )


def _extract_runtime_safe_secondary_annotations(primary_effect, rule):
    """Allow secondary rules to contribute only non-executable cost metadata."""
    effect = rule.get("effect_json") or {}
    execution_status = _rule_execution_status(rule)
    if execution_status in {"disabled", "review_only"}:
        return None
    review_status = str(rule.get("review_status") or "").lower()
    if review_status not in {"verified", "active"}:
        return None
    if effect.get("activated_mana_ability") or effect.get("ability_kind") in {"triggered", "activated", "static"}:
        return None
    if effect.get("trigger"):
        return None
    if effect.get("compose_on_resolution") is True and effect.get("effect") in COMPOSABLE_RESOLUTION_EFFECTS:
        return None
    effect_name = effect.get("effect")
    primary_effect_name = primary_effect.get("effect")
    if effect_name not in (None, "", "passive", primary_effect_name):
        return None
    if (
        effect.get("target")
        and primary_effect.get("target")
        and effect.get("target") != primary_effect.get("target")
    ):
        return None
    annotations = {}
    for key in SAFE_RUNTIME_SECONDARY_ANNOTATION_KEYS:
        value = effect.get(key)
        if value not in (None, False, "", [], {}):
            annotations[key] = value
    if not annotations:
        return None
    allowed_keys = SAFE_RUNTIME_SECONDARY_ANNOTATION_KEYS | SAFE_RUNTIME_SECONDARY_DESCRIPTOR_KEYS
    for key, value in effect.items():
        if key in allowed_keys:
            continue
        if value not in (None, False, "", [], {}):
            return None
    return annotations


def _is_composable_resolution_rule(rule):
    """Only opt-in, trusted same-resolution components can execute together."""
    effect = rule.get("effect_json") or {}
    execution_status = _rule_execution_status(rule)
    if execution_status not in {"auto", "executable"}:
        return False
    review_status = str(rule.get("review_status") or "").lower()
    if review_status not in {"verified", "active"}:
        return False
    if effect.get("compose_on_resolution") is not True:
        return False
    if effect.get("effect") not in COMPOSABLE_RESOLUTION_EFFECTS:
        return False
    for key in COMPOSITE_BLOCKING_EFFECT_KEYS:
        if effect.get(key):
            return False
    if effect.get("ability_kind") in {"triggered", "activated", "static"}:
        return False
    return True


def _build_composite_battle_rule_effect(card, rules):
    composable_rules = [
        rule
        for rule in rules
        if rule and rule.get("effect_json") and _is_composable_resolution_rule(rule)
    ]
    if len(composable_rules) < 2:
        return None
    components = []
    skipped = []
    for rule in rules:
        if not rule or not rule.get("effect_json"):
            continue
        if not _is_composable_resolution_rule(rule):
            skipped.append(_battle_rule_summary(rule))
            continue
        components.append(
            normalize_effect_by_oracle(
                card,
                _annotated_battle_rule_effect(rule),
            )
        )
    if len(components) < 2:
        return None
    confidence_values = [
        float(component.get("_rule_confidence") or 0.0)
        for component in components
    ]
    logical_keys = [
        str(component.get("_rule_logical_key") or "")
        for component in components
        if component.get("_rule_logical_key")
    ]
    composite = dict(components[0])
    composite["effect"] = "composite_resolution"
    composite["_rule_source"] = "battle_card_rules_composite"
    composite["_rule_review_status"] = "verified"
    composite["_rule_confidence"] = min(confidence_values) if confidence_values else 0.0
    composite["_rule_logical_key"] = "+".join(logical_keys)
    composite["_composite_rule_components"] = components
    composite["_composite_skipped_rules"] = skipped
    return _annotate_runtime_rule_selection(
        composite,
        rules,
        selection_mode="composite_resolution",
    )


def _build_primary_effect_with_safe_secondary_annotations(card, rules):
    if len(rules) < 2:
        return None
    primary_rule = _select_primary_runtime_rule(rules)
    if primary_rule is None:
        return None
    primary = normalize_effect_by_oracle(
        card,
        _annotated_battle_rule_effect(primary_rule),
    )
    merged_rules = []
    blocked_rules = []
    selected_key = str(primary.get("_rule_logical_key") or "")
    for rule in rules:
        if not rule:
            continue
        if str(rule.get("logical_rule_key") or "") == selected_key:
            continue
        annotations = _extract_runtime_safe_secondary_annotations(primary, rule)
        if annotations:
            primary.update(annotations)
            merged_rules.append(rule)
            continue
        summary = _battle_rule_summary(rule)
        summary["runtime_reason"] = _runtime_rule_skip_reason(rule)
        blocked_rules.append(summary)
    if not merged_rules:
        return None
    return _build_runtime_rule_selection_with_merged_annotations(
        primary,
        rules,
        selection_mode="single_selected_with_safe_annotations",
        merged_rules=merged_rules,
        blocked_rules=blocked_rules,
    )


def _load_known_cards_into_runtime(path: str | os.PathLike[str], *, bucket: set[str] | None = None) -> None:
    try:
        decoded = load_snapshot_file(path)
    except Exception:
        return
    for card_name, entry in decoded.items():
        if card_name in KNOWN_CARDS:
            continue
        KNOWN_CARDS[card_name] = entry
        if bucket is not None:
            bucket.add(card_name)


# ── KNOWN_CARDS fallback loaders ──
# The canonical snapshot mirrors reviewed SQLite battle_card_rules for degraded
# runtime operation. If a card is absent from the registry and the snapshot, it
# must fall through to explicit functional/effect/type heuristics instead of the
# older generated JSON.
_canonical_snapshot_path = resolve_canonical_snapshot_path()
if _canonical_snapshot_path.exists():
    _load_known_cards_into_runtime(
        _canonical_snapshot_path,
        bucket=CANONICAL_FALLBACK_KNOWN_CARDS,
    )

def get_card_effect(card):
    name = card.get("name", "")
    lookup_names = [name]
    if isinstance(name, str) and " // " in name:
        front_face = name.split(" // ", 1)[0].strip()
        if front_face and front_face not in lookup_names:
            lookup_names.append(front_face)
    for lookup_name in lookup_names:
        if (
            lookup_name in MANUAL_RULE_RUNTIME_WAIVERS
            and lookup_name in HANDCRAFTED_KNOWN_CARD_RULES
        ):
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    HANDCRAFTED_KNOWN_CARD_RULES[lookup_name],
                    source="known_cards_manual",
                    review_status="verified",
                    confidence=1.0,
                ),
            )
    if battle_rule_registry is not None:
        for lookup_name in lookup_names:
            if hasattr(battle_rule_registry, "lookup_battle_card_rule_list"):
                rules = battle_rule_registry.lookup_battle_card_rule_list(DB, lookup_name)
            else:
                rule = battle_rule_registry.lookup_battle_card_rule(DB, lookup_name)
                rules = [rule] if rule else []
            if any(rule and rule.get("effect_json") for rule in rules):
                composite_effect = _build_composite_battle_rule_effect(card, rules)
                if composite_effect is not None:
                    return composite_effect
                enriched_effect = _build_primary_effect_with_safe_secondary_annotations(card, rules)
                if enriched_effect is not None:
                    return enriched_effect
                rule = _select_primary_runtime_rule(rules)
                if rule is not None:
                    effect = _annotate_runtime_rule_selection(
                        _annotated_battle_rule_effect(rule),
                        rules,
                        selection_mode="single_selected",
                    )
                    return normalize_effect_by_oracle(card, effect)
    for lookup_name in lookup_names:
        if lookup_name in HANDCRAFTED_KNOWN_CARDS:
            handcrafted_effect = HANDCRAFTED_KNOWN_CARD_RULES.get(lookup_name)
            if handcrafted_effect is None:
                handcrafted_effect = {}
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    handcrafted_effect,
                    source="known_cards_manual",
                    review_status="verified",
                    confidence=1.0,
                ),
            )
    for lookup_name in lookup_names:
        if lookup_name in CANONICAL_FALLBACK_KNOWN_CARDS:
            effect_json, metadata = extract_snapshot_effect_and_metadata(KNOWN_CARDS[lookup_name])
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    effect_json,
                    source="known_cards_canonical_snapshot",
                    review_status=str(metadata.get("battle_rule_review_status") or "unknown"),
                    execution_status=str(metadata.get("battle_rule_execution_status") or "auto"),
                    confidence=float(metadata.get("battle_rule_confidence") or 0.0),
                    rule_version=metadata.get("battle_rule_version"),
                    logical_rule_key=metadata.get("battle_rule_logical_key"),
                    oracle_hash=metadata.get("battle_rule_oracle_hash"),
                ),
            )
    for tag in card_functional_tags(card):
        if tag not in TAG_EFFECTS:
            continue
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                TAG_EFFECTS[tag],
                source="functional_tags_json",
                review_status="heuristic",
                confidence=0.35,
            ),
        )
    effect = card.get("effect", "")
    effect_map = {"ramp": "ramp_permanent", "removal": "remove_creature",
                  "board_wipe": "board_wipe", "wincon": "finisher", "draw": "draw_cards",
                  "counter": "counter", "land": "land", "extra_combat": "extra_combat"}
    if effect in effect_map:
        if effect == "extra_combat":
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    {
                        "effect": "extra_combat",
                        "combats": card.get("combats", card.get("extra_combats", 1)),
                        "untap_creatures": card.get("untap_creatures", True),
                    },
                    source="card_effect_field",
                    review_status="heuristic",
                    confidence=0.25,
                ),
            )
        if effect == "ramp":
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    {"effect": "ramp_permanent", "mana_produced": 1},
                    source="card_effect_field",
                    review_status="heuristic",
                    confidence=0.25,
                ),
            )
        if effect == "wincon":
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    {"effect": "finisher"},
                    source="card_effect_field",
                    review_status="heuristic",
                    confidence=0.25,
                ),
            )
        if effect == "draw":
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    {"effect": "draw_cards", "count": 2},
                    source="card_effect_field",
                    review_status="heuristic",
                    confidence=0.25,
                ),
            )
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                {"effect": effect_map[effect]},
                source="card_effect_field",
                review_status="heuristic",
                confidence=0.25,
            ),
        )
    if "land" in card.get("type_line", "").lower():
        return annotate_effect_identity(
            card,
            with_rule_metadata(
                {"effect": "land"},
                source="type_line_land",
                review_status="fact",
                confidence=0.75,
            ),
        )
    if effect == "creature" or "creature" in card.get("type_line", "").lower():
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                {"effect": "creature", "power": card.get("power", 2)},
                source="type_line_creature",
                review_status="fact",
                confidence=0.65,
            ),
        )
    return normalize_effect_by_oracle(
        card,
        with_rule_metadata(
            {"effect": "unknown"},
            source="unknown",
            review_status="missing",
            confidence=0.0,
        ),
    )

def is_instant(card):
    """v8: Check if a card can be cast at instant speed."""
    if is_effective_land(card):
        return False
    name = card.get("name", "")
    tl = card.get("type_line", "")
    if "Instant" in tl:
        return True
    if card_has_keyword(card, "flash"):
        return True
    if any(card_type in tl for card_type in ("Sorcery", "Creature", "Artifact", "Enchantment", "Planeswalker", "Battle")):
        return False
    if get_card_effect(card).get("instant"):
        return True
    if name in KNOWN_CARDS and KNOWN_CARDS[name].get("instant"):
        return True
    return False

def is_sorcery(card):
    if is_effective_land(card):
        return False
    return "Sorcery" in card.get("type_line", "")


def is_instant_or_sorcery_spell(card):
    """Strict spell type check for effects that care about instant/sorcery cards."""
    if is_effective_land(card):
        return False
    tl = card.get("type_line", "")
    return "Instant" in tl or "Sorcery" in tl


def is_modeled_battle_card(card):
    return get_card_effect(card).get("effect") != "unknown"

# ═══════════════════════════════════════════
# OPPONENTS
# ═══════════════════════════════════════════

OPPONENT_ARCHETYPES = [
    {"name": "Aggro (Krenko)", "archetype": "aggro", "life": 40,
     "lands": 34, "ramp": 8, "removal": 5, "counters": 0,
     "creatures": 35, "wincons": 3, "draw": 4, "wipe": 2, "avg_cmc": 2.5, "strategy": "rush",
     "commander_name": "Krenko, Mob Boss", "commander_cmc": 4},
    {"name": "Control (Atraxa)", "archetype": "control", "life": 40,
     "lands": 37, "ramp": 12, "removal": 12, "counters": 6,
     "creatures": 15, "wincons": 3, "draw": 6, "wipe": 6, "avg_cmc": 3.2, "strategy": "control",
     "commander_name": "Atraxa, Praetors' Voice", "commander_cmc": 4},
    {"name": "Combo (Kinnan)", "archetype": "combo", "life": 40,
     "lands": 30, "ramp": 15, "removal": 6, "counters": 8,
     "creatures": 18, "wincons": 4, "draw": 8, "wipe": 1, "avg_cmc": 2.1, "strategy": "combo",
     "commander_name": "Kinnan, Bonder Prodigy", "commander_cmc": 2},
    {"name": "Midrange (Korvold)", "archetype": "midrange", "life": 40,
     "lands": 36, "ramp": 12, "removal": 8, "counters": 2,
     "creatures": 25, "wincons": 3, "draw": 6, "wipe": 3, "avg_cmc": 3.0, "strategy": "value",
     "commander_name": "Korvold, Fae-Cursed King", "commander_cmc": 5},
    {"name": "Spellslinger (Niv)", "archetype": "spellslinger", "life": 40,
     "lands": 36, "ramp": 10, "removal": 10, "counters": 5,
     "creatures": 10, "wincons": 3, "draw": 8, "wipe": 3, "avg_cmc": 2.8, "strategy": "spells",
     "commander_name": "Niv-Mizzet, Parun", "commander_cmc": 6},
    {"name": "Stax (Winota)", "archetype": "stax", "life": 40,
     "lands": 35, "ramp": 8, "removal": 8, "counters": 0,
     "creatures": 30, "wincons": 3, "draw": 3, "wipe": 2, "avg_cmc": 2.6, "strategy": "stax",
     "commander_name": "Winota, Joiner of Forces", "commander_cmc": 4},
]

def generate_opponent_deck(profile):
    deck = []
    for _ in range(profile["lands"]):
        deck.append({"name": "Land", "cmc": 0, "tag": "land", "effect": "land", "type_line": "Land"})
    for _ in range(profile["ramp"]):
        deck.append({"name": "Ramp Card", "cmc": max(1, profile["avg_cmc"] - 0.5), "tag": "ramp", "effect": "ramp"})
    for _ in range(profile["removal"]):
        deck.append({"name": "Removal", "cmc": max(1, profile["avg_cmc"] - 1), "tag": "removal", "effect": "removal"})
    for _ in range(profile["creatures"]):
        pwr = max(1, int(profile["avg_cmc"]))
        deck.append({"name": "Creature", "cmc": profile["avg_cmc"], "tag": "creature", "effect": "creature", "power": pwr, "type_line": "Creature"})
    for _ in range(profile["wincons"]):
        deck.append({"name": "Wincon", "cmc": max(3, profile["avg_cmc"] + 1), "tag": "wincon", "effect": "wincon"})
    for _ in range(profile["draw"]):
        deck.append({"name": "Draw Spell", "cmc": max(2, profile["avg_cmc"] - 0.5), "tag": "draw", "effect": "draw"})
    for _ in range(profile.get("wipe", 2)):
        deck.append({"name": "Board Wipe", "cmc": 4, "tag": "board_wipe", "effect": "board_wipe"})
    for _ in range(profile.get("counters", 0)):
        deck.append({"name": "Counterspell", "cmc": 2, "tag": "counter", "effect": "counter", "instant": True, "type_line": "Instant"})
    while len(deck) < 99:
        deck.append({"name": "Filler Creature", "cmc": profile["avg_cmc"], "tag": "creature", "effect": "creature", "power": 2, "type_line": "Creature"})
    return deck[:99]

def get_opponent_commander(profile):
    return {"name": profile["commander_name"], "cmc": profile["commander_cmc"],
            "tag": "creature", "effect": "creature",
            "power": max(2, profile["commander_cmc"]),
            "type_line": "Legendary Creature", "is_commander": True, "owner": profile["name"]}

# ═══════════════════════════════════════════
# PLAYER STATE
# ═══════════════════════════════════════════

class ManaPool:
    def __init__(self): self.generic = self.white = self.blue = self.black = self.red = self.green = self.colorless = self.wildcard = 0
    def total(self): return self.generic + self.white + self.blue + self.black + self.red + self.green + self.colorless + self.wildcard
    def add_generic(self, n): self.generic += n
    def add(self, color, amount=1):
        if color not in ("generic", "white", "blue", "black", "red", "green", "colorless", "wildcard"):
            color = "generic"
        setattr(self, color, getattr(self, color) + amount)
    def snapshot(self):
        return {
            color: getattr(self, color)
            for color in ("generic", "white", "blue", "black", "red", "green", "colorless", "wildcard")
        }
    def spend(self, amount):
        if amount < 0 or amount > self.total():
            return False
        remaining = amount
        for color in ("generic", "colorless", "wildcard", "white", "blue", "black", "red", "green"):
            available = getattr(self, color)
            used = min(available, remaining)
            setattr(self, color, available - used)
            remaining -= used
            if remaining == 0:
                break
        return True
    def empty(self):
        self.generic = self.white = self.blue = self.black = self.red = self.green = self.colorless = self.wildcard = 0

class Player:
    def shuffle(self, rng): rng.shuffle(self.library)

    def draw(self, n=1, rng=None):
        drawn = []
        turn_marker = CURRENT_REPLAY_TURN
        if turn_marker is not None and getattr(self, "_cards_drawn_turn_marker", None) != turn_marker:
            self.cards_drawn_this_turn = 0
            self._cards_drawn_turn_marker = turn_marker
        for _ in range(n):
            if self.library:
                c = self.library.pop(0)
                self.hand.append(c)
                drawn.append(c)
                self.cards_drawn_this_turn += 1
            else:
                self.failed_draw_from_empty_library = True
        return drawn

    def __init__(self, name, commander, deck, is_human=False, strategy="midrange"):
        self.name = name
        self.commander = commander
        self.command_zone = [commander] if commander else []
        self.commander_tax = 0
        self.library = list(deck)
        self.hand = []
        self.battlefield = []
        self.phased_out = []
        self.graveyard = []
        self.exile = []
        self.life = 40
        self.commander_damage = defaultdict(int)
        self.commander_damage_by_source = defaultdict(int)
        self.mana_pool = ManaPool()
        self.restricted_mana = {}
        self.lands_played_this_turn = 0
        self.max_lands_per_turn = 1
        self.is_human = is_human
        self.strategy = strategy
        self.indestructible = False
        self.life_cant_change = False
        self.protection_from_everything = False
        self.cannot_lose_this_turn = False
        self.damage_life_floor = None
        self.damage_prevention_shields = []
        self.silenced_opponents = False
        self.silenced_opponents_until_eot = False
        self.approach_count = 0
        self.treasures = 0
        self.draw_engines = 0
        self.copy_engines = 0
        self.counters_available = 0
        self.threat_level = 0  # v8.1: archenemy tracking
        self.approach_revealed = []  # v8.1: opponents who know approach was cast
        self.extra_turns = 0
        self.extra_turn_loss_pending = 0
        self.extra_combats = 0
        self.eliminated = False
        self.poison = 0  # v9
        self.win_reason = None
        self.cards_drawn_this_turn = 0
        self._cards_drawn_turn_marker = None
        self.failed_draw_from_empty_library = False

    def refresh_mana_sources(self, turn=None):
        """Untap mana sources once for this player's turn."""
        self.mana_pool.empty()
        self.restricted_mana = {}
        sources = [
            source
            for source in self.battlefield
            if is_mana_source_permanent(source)
            and not (
                is_battlefield_creature(source)
                and source.get("is_mana_source")
                and source.get("summoning_sick")
            )
        ]
        active_sources = 0
        for source in sources:
            produced = mana_source_production_for_state(self, source)
            if produced <= 0:
                continue
            colors = source_colors(source)
            # A source with multiple options is treated as flexible generic unless
            # the imported data specifies one concrete produced color.
            color = colors[0] if len(colors) == 1 else "generic"
            self.mana_pool.add(color, produced)
            active_sources += 1
        emit_replay_event(
            "mana_refreshed",
            player=self.name,
            mana=self.available_mana(),
            sources=active_sources,
            mana_pool=self.mana_pool.snapshot(),
            treasures=self.treasures,
            turn=turn,
        )

    def available_mana(self):
        return self.mana_pool.total() + self.treasures

    def add_restricted_mana(self, amount, restriction, color="wildcard"):
        restriction = str(restriction or "").strip().lower()
        if not restriction or amount <= 0:
            return
        color = color if color in ("generic", "white", "blue", "black", "red", "green", "colorless", "wildcard") else "generic"
        bucket = self.restricted_mana.setdefault(restriction, defaultdict(int))
        bucket[color] += int(amount)

    def _payment_plan(self, cost):
        parsed = (
            cost
            if isinstance(cost, dict) and "colored" in cost
            else parse_mana_cost(cost, cost if isinstance(cost, (int, float)) else 0)
        )
        pool = self.mana_pool.snapshot()
        restricted_pool = {
            restriction: defaultdict(int, dict(colors))
            for restriction, colors in self.restricted_mana.items()
        }
        treasures = self.treasures
        life_payment = 0
        spend_tags = set(parsed.get("spend_tags", []))
        restriction_aliases = {
            "creature_only": "creature_spell",
            "creature_spell_only": "creature_spell",
            "artifact_only": "artifact_spell",
            "artifact_spell_only": "artifact_spell",
            "instant_or_sorcery_only": "instant_or_sorcery_spell",
            "instant_or_sorcery_spell_only": "instant_or_sorcery_spell",
            "noncreature_only": "noncreature_spell",
            "noncreature_spell_only": "noncreature_spell",
        }

        def allowed_restrictions():
            allowed = []
            for restriction in restricted_pool:
                tag = restriction_aliases.get(restriction, restriction)
                if tag == "any_spell" or tag in spend_tags:
                    allowed.append(restriction)
            return allowed

        def restricted_color_available(color):
            available = 0
            for restriction in allowed_restrictions():
                colors = restricted_pool[restriction]
                available += colors[color] + colors["wildcard"]
            return available

        def spend_restricted_color_up_to(color, amount=1):
            remaining = int(amount or 0)
            spent = 0
            for restriction in allowed_restrictions():
                colors = restricted_pool[restriction]
                for candidate in (color, "wildcard"):
                    paid = min(colors[candidate], remaining)
                    colors[candidate] -= paid
                    spent += paid
                    remaining -= paid
                    if remaining == 0:
                        return spent
            return spent

        def restricted_generic_available():
            available = 0
            for restriction in allowed_restrictions():
                colors = restricted_pool[restriction]
                available += sum(colors[color] for color in (
                    "generic",
                    "colorless",
                    "wildcard",
                    "white",
                    "blue",
                    "black",
                    "red",
                    "green",
                ))
            return available

        def spend_restricted_generic_up_to(amount):
            remaining = int(amount or 0)
            spent = 0
            for restriction in allowed_restrictions():
                colors = restricted_pool[restriction]
                for color in (
                    "generic",
                    "colorless",
                    "wildcard",
                    "white",
                    "blue",
                    "black",
                    "red",
                    "green",
                ):
                    paid = min(colors[color], remaining)
                    colors[color] -= paid
                    spent += paid
                    remaining -= paid
                    if remaining == 0:
                        return spent
            return spent

        def spend_generic(amount):
            nonlocal treasures
            generic_missing = int(amount or 0)
            for color in (
                "generic",
                "colorless",
                "wildcard",
                "white",
                "blue",
                "black",
                "red",
                "green",
            ):
                paid = min(pool[color], generic_missing)
                pool[color] -= paid
                generic_missing -= paid
                if generic_missing == 0:
                    return True
            restricted_available = restricted_generic_available()
            if restricted_available:
                if restricted_available + treasures < generic_missing:
                    return False
                generic_missing -= spend_restricted_generic_up_to(generic_missing)
                if generic_missing == 0:
                    return True
            if generic_missing > treasures:
                return False
            treasures -= generic_missing
            return True

        for color, required in parsed["colored"].items():
            paid = min(pool[color], required)
            pool[color] -= paid
            missing = required - paid
            wildcard_paid = min(pool["wildcard"], missing)
            pool["wildcard"] -= wildcard_paid
            missing -= wildcard_paid
            restricted_available = restricted_color_available(color)
            if missing and restricted_available:
                if restricted_available + treasures < missing:
                    return None
                missing -= spend_restricted_color_up_to(color, missing)
            if missing > treasures:
                return None
            treasures -= missing

        for color in parsed.get("phyrexian", []):
            if pool[color] > 0:
                pool[color] -= 1
            elif pool["wildcard"] > 0:
                pool["wildcard"] -= 1
            elif spend_restricted_color_up_to(color):
                pass
            elif treasures > 0:
                treasures -= 1
            elif self.life - life_payment >= 2:
                life_payment += 2
            else:
                return None

        for options in parsed.get("phyrexian_hybrid", []):
            chosen = next((color for color in options if pool[color] > 0), None)
            if chosen:
                pool[chosen] -= 1
            elif pool["wildcard"] > 0:
                pool["wildcard"] -= 1
            elif any(spend_restricted_color_up_to(color) for color in options):
                pass
            elif treasures > 0:
                treasures -= 1
            elif self.life - life_payment >= 2:
                life_payment += 2
            else:
                return None

        for options in parsed["hybrid"]:
            chosen = next((color for color in options if pool[color] > 0), None)
            if chosen:
                pool[chosen] -= 1
            elif pool["wildcard"] > 0:
                pool["wildcard"] -= 1
            elif any(spend_restricted_color_up_to(color) for color in options):
                pass
            elif treasures > 0:
                treasures -= 1
            else:
                return None

        for option in parsed.get("monocolored_hybrid", []):
            color = option.get("color")
            generic_amount = int(option.get("generic", 2) or 2)
            if color and pool[color] > 0:
                pool[color] -= 1
            elif pool["wildcard"] > 0:
                pool["wildcard"] -= 1
            elif color and spend_restricted_color_up_to(color):
                pass
            elif treasures > 0:
                treasures -= 1
            elif not spend_generic(generic_amount):
                return None

        if not spend_generic(parsed["generic"]):
            return None
        return pool, treasures, life_payment, restricted_pool

    def can_pay(self, cost):
        return self._payment_plan(cost) is not None

    def can_pay_card(self, card, additional_generic=0):
        return self.can_pay(card_mana_cost(card, additional_generic))

    def spend_mana(self, cost):
        """Spend colored/generic mana and flexible Treasure according to a real cost."""
        plan = self._payment_plan(cost)
        if plan is None:
            return False
        pool, self.treasures, life_payment, restricted_pool = plan
        for color, amount in pool.items():
            setattr(self.mana_pool, color, amount)
        self.restricted_mana = {
            restriction: defaultdict(
                int,
                {
                    color: amount
                    for color, amount in colors.items()
                    if amount > 0
                },
            )
            for restriction, colors in restricted_pool.items()
            if any(amount > 0 for amount in colors.values())
        }
        if life_payment:
            self.life -= life_payment
        return True

    def spend_card_mana(self, card, additional_generic=0):
        return self.spend_mana(card_mana_cost(card, additional_generic))

    def is_alive(self):
        return not self.eliminated and (
            self.life > 0 or self.cannot_lose_this_turn
        )

    def has_won(self): return self.win_reason is not None

    def untapped_creatures(self):
        return [c for c in self.battlefield if is_battlefield_creature(c)
                and not c.get("tapped", False) and (not c.get("summoning_sick", False) or has_haste(c))]

    def creatures_for_blocking(self):
        return [c for c in self.battlefield if is_battlefield_creature(c)
                and not c.get("tapped", False)]

    def has_counterspell(self):
        """Return whether a real counterspell in hand can currently be paid for."""
        return bool(self.counterspell_cards(castable_only=True))

    def counterspell_cards(self, castable_only=False):
        counters = [
            card
            for card in self.hand
            if get_card_effect(card).get("effect") == "counter"
            or card.get("effect") == "counter"
            or card_has_functional_tag(card, "counter", "protection")
        ]
        if castable_only:
            counters = [
                card for card in counters
                if self.can_pay_card(card)
            ]
        return counters

    def use_counterspell(self, turn=None, target_card=None):
        counters = self.counterspell_cards(castable_only=True)
        if not counters:
            self.counters_available = len(self.counterspell_cards())
            return None
        counter = min(counters, key=lambda card: card.get("cmc", 0))
        cost = counter.get("cmc", 0)
        if not self.spend_card_mana(counter):
            return None
        self.hand.remove(counter)
        self.graveyard.append(counter)
        self.counters_available = len(self.counterspell_cards())
        effect = get_card_effect(counter)
        draw_count = int(effect.get("draw_on_counter") or 0)
        if draw_count:
            self.draw(draw_count, random.Random(turn or 0))
        emit_replay_event(
            "spell_countered",
            player=self.name,
            counter=counter.get("name", "?"),
            target=(target_card or {}).get("name", "?"),
            cost=cost,
            cards_drawn=draw_count,
            turn=turn,
        )
        return counter

# ═══════════════════════════════════════════
# STACK (v8)
# ═══════════════════════════════════════════

_pending_triggers = []
_trigger_counter = 0


def clear_pending_triggers():
    """Clear queued triggers between simulations/tests."""
    global _pending_triggers, _trigger_counter
    _pending_triggers = []
    _trigger_counter = 0


def enqueue_trigger(source, event_type, controller, resolver, data=None):
    """Queue a triggered ability for APNAP ordering before it reaches the stack."""
    global _trigger_counter
    _pending_triggers.append(
        {
            "source": source,
            "event_type": event_type,
            "controller": controller,
            "resolver": resolver,
            "data": data or {},
            "timestamp": _trigger_counter,
        }
    )
    _trigger_counter += 1


def flush_triggers_in_apnap(active_player, all_players, stack):
    """Put queued triggers on the stack in APNAP order (CR 603.3b)."""
    if not _pending_triggers:
        return 0

    turn_order = [active_player] + [p for p in all_players if p != active_player]
    queued = list(_pending_triggers)
    _pending_triggers.clear()
    pushed = 0

    for player in turn_order:
        player_triggers = [
            trigger for trigger in queued if trigger.get("controller") == player
        ]
        player_triggers.sort(key=lambda trigger: trigger.get("timestamp", 0))
        for trigger in player_triggers:
            source = trigger.get("source") or {}
            source_name = source.get("name", "?") if isinstance(source, dict) else str(source)
            stack.push(
                {
                    "name": source_name,
                    "type_line": "Triggered Ability",
                    "is_triggered_ability": True,
                },
                player,
                {
                    "effect": "triggered_ability",
                    "trigger": trigger.get("event_type"),
                    "resolver": trigger.get("resolver"),
                    "timestamp": trigger.get("timestamp", 0),
                    **(trigger.get("data") or {}),
                },
            )
            emit_replay_event(
                "trigger_put_on_stack",
                player=player.name,
                card=source_name,
                trigger=trigger.get("event_type"),
                timestamp=trigger.get("timestamp", 0),
            )
            pushed += 1

    return pushed


def resolve_or_enqueue_trigger(
    controller,
    source,
    event_type,
    resolver,
    *,
    stack=None,
    active_player=None,
    all_players=None,
    data=None,
):
    """Resolve immediately for legacy direct calls, or enqueue for game-stack flows."""
    if stack is None or active_player is None or all_players is None:
        resolver()
        return
    enqueue_trigger(source, event_type, controller, resolver, data=data)


def copy_spell_on_stack(original, controller, stack):
    """v9: Copy a spell on the stack (CR 706.10).
    The copy is NOT cast — triggers that care about casting do not fire.
    """
    if not isinstance(original, dict):
        return None
    copy = {
        "name": original.get("name", ""),
        "cmc": original.get("cmc", 0),
        "type_line": original.get("type_line", ""),
        "effect": original.get("effect", ""),
        "is_copy": True,
        "was_cast": False,
        "controller": controller.name,
        "colors": original.get("colors", []),
        "modes": original.get("modes", []),
        "targets": original.get("targets", []),
    }
    item = StackItem(copy, controller, {})
    item.was_cast = False
    stack.push(item)
    return item

class StackItem:
    def __init__(self, card, controller, effect_data):
        self.card = card
        self.controller = controller
        self.effect_data = effect_data
        self.countered = False


def is_effective_land(card):
    """Land detection after executable rule normalization."""
    if is_land(card):
        return True
    if not isinstance(card, dict):
        return False
    try:
        return get_card_effect(card).get("effect") == "land"
    except Exception:
        return False

class Stack:
    def __init__(self): self.items = []
    def push(self, card, controller=None, effect_data=None):
        if isinstance(card, StackItem) and controller is None:
            self.items.append(card)
            record_engine_metric("stack_pushes")
            record_stack_depth(len(self.items))
            return
        self.items.append(StackItem(card, controller, effect_data or {}))
        record_engine_metric("stack_pushes")
        record_stack_depth(len(self.items))
    def resolve_top(self):
        if self.items:
            item = self.items.pop()
            record_engine_metric("stack_resolutions")
            if not item.countered:
                return item
            finish_countered_spell(item.controller, item.card)
        return None
    def top_is_threat(self):
        """Is the top spell threatening enough for opponents to counter?"""
        if not self.items: return False
        effect = self.items[-1].effect_data.get("effect", "")
        threats = {"board_wipe", "finisher", "approach", "steal_all_creatures",
                   "overload_recursion", "pump_all", "token_maker", "copy_creature_token",
                   "worldfire_reset"}
        return effect in threats
    def empty(self): return len(self.items) == 0

# ═══════════════════════════════════════════
# GAME SIMULATOR v8
# ═══════════════════════════════════════════

def play_mulligan(player, rng):
    player.shuffle(rng)
    player.hand = player.draw(7, rng)
    evaluation = mulligan_evaluation(player.hand)
    mulligan_count = 0
    _emit_mulligan_decision_trace(
        player,
        evaluation,
        mulligan_count=mulligan_count,
        chosen_action="keep" if evaluation["keep"] else "mulligan",
        bottomed_cards=[],
    )
    while not evaluation["keep"] and mulligan_count < 3:  # v10.2 fix
        mulligan_count += 1
        player.library = player.hand + player.library
        player.hand = []
        player.shuffle(rng)
        player.hand = player.draw(7, rng)
        bottomed_cards = []
        bottom_count = max(0, mulligan_count - 1)  # free first
        for c in choose_mulligan_bottom_cards(player.hand, bottom_count):
            if c in player.hand:
                player.hand.remove(c)
                bottomed_cards.append(c.get("name", "?") if isinstance(c, dict) else str(c))
                player.library.append(c)
        evaluation = mulligan_evaluation(player.hand)
        forced_keep = not evaluation["keep"] and mulligan_count >= 3
        _emit_mulligan_decision_trace(
            player,
            evaluation,
            mulligan_count=mulligan_count,
            chosen_action="keep" if evaluation["keep"] or forced_keep else "mulligan",
            bottomed_cards=bottomed_cards,
            forced_keep=forced_keep,
        )
    return mulligan_count


def _opening_hand_card_cmc(card):
    try:
        return float(card.get("cmc") or 0)
    except Exception:
        return 99.0


def _opening_hand_effect(card):
    try:
        return get_card_effect(card)
    except Exception:
        return {}


def _opening_hand_effect_name(card, effect_data=None):
    if not isinstance(card, dict):
        return "unknown"
    effect_data = effect_data or _opening_hand_effect(card)
    resolved = effect_data.get("effect")
    if resolved and resolved != "unknown":
        return resolved
    return card.get("effect") or card.get("tag") or "unknown"


def _opening_hand_colors(hand):
    colors = []
    for card in hand:
        if not is_effective_land(card):
            continue
        for color in source_colors(card):
            if color not in colors:
                colors.append(color)
    return sorted(colors)


def _opening_hand_summary(hand):
    return [
        {
            "name": card.get("name", "?") if isinstance(card, dict) else str(card),
            "cmc": _opening_hand_card_cmc(card) if isinstance(card, dict) else 0,
            "type_line": card.get("type_line", "") if isinstance(card, dict) else "",
            "is_land": bool(is_effective_land(card)),
            "effect": _opening_hand_effect_name(card) if isinstance(card, dict) else "unknown",
        }
        for card in hand
    ]


def _opening_hand_land_options(hand):
    return [
        card
        for card in hand
        if isinstance(card, dict) and is_effective_land(card)
    ]


def _opening_hand_virtual_mana_pool(lands):
    pool = ManaPool()
    for land in lands:
        colors = source_colors(land)
        color = colors[0] if len(colors) == 1 else "wildcard"
        pool.add(color, 1)
    return pool


def _opening_hand_subset_can_pay_cost(card, land_subset):
    if not isinstance(card, dict):
        return False
    ghost = Player("__opening_hand__", None, [])
    ghost.mana_pool = _opening_hand_virtual_mana_pool(land_subset)
    ghost.treasures = 0
    ghost.restricted_mana = {}
    return ghost.can_pay(card_mana_cost(card))


def _opening_hand_card_is_color_live(card, hand, max_lands_available):
    if not isinstance(card, dict):
        return False
    lands = _opening_hand_land_options(hand)
    if not lands:
        return False
    usable_lands = min(len(lands), max(1, int(max_lands_available or 0)))
    if usable_lands <= 0:
        return False
    if usable_lands >= len(lands):
        return _opening_hand_subset_can_pay_cost(card, lands)
    for subset in combinations(lands, usable_lands):
        if _opening_hand_subset_can_pay_cost(card, subset):
            return True
    return False


def _opening_hand_can_satisfy_basic_additional_costs(card, effect_data, lands):
    if effect_data.get("requires_discard_land") and lands < 2:
        return False
    if effect_data.get("requires_sacrifice_land") and lands < 2:
        return False
    return True


def _opening_hand_ramp_card_is_live(card, effect_data, hand, lands, early_turn_window):
    if not _opening_hand_can_satisfy_basic_additional_costs(card, effect_data, lands):
        return False
    if not _opening_hand_card_is_color_live(card, hand, early_turn_window):
        return False
    if not effect_data.get("requires_legendary_creature_or_planeswalker_for_mana"):
        return True
    for candidate in hand:
        if candidate is card or not isinstance(candidate, dict):
            continue
        type_line = str(candidate.get("type_line") or "").lower()
        if "legendary" not in type_line:
            continue
        if "creature" not in type_line and "planeswalker" not in type_line:
            continue
        if (
            _opening_hand_card_cmc(candidate) <= max(2, early_turn_window)
            and _opening_hand_card_is_color_live(candidate, hand, early_turn_window)
        ):
            return True
    return False


def _opening_hand_role(card, effect_data):
    effect = _opening_hand_effect_name(card, effect_data)
    type_line = str(card.get("type_line") or "").lower()

    if effect in OPENING_HAND_RAMP_EFFECTS:
        return "ramp"
    if effect in OPENING_HAND_CARD_FLOW_EFFECTS:
        return "card_flow"
    if effect in OPENING_HAND_REACTIVE_EFFECTS:
        return "interaction"
    if effect == "ramp_ritual":
        return "one_shot_ramp"
    if effect in HIGH_IMPACT_PAYOFF_EFFECTS:
        return "payoff"
    if "creature" in type_line:
        return "board"
    if any(token in type_line for token in ("artifact", "enchantment", "planeswalker", "battle")):
        return "engine"
    return "other"


def _opening_hand_has_early_plan(hand, lands):
    nonlands = [c for c in hand if not is_effective_land(c)]
    if not nonlands:
        return False, "all_lands", {}

    early_turn_window = 2 if lands == 2 else (4 if lands >= 5 else 3)
    evaluated = []
    live_ramp = []
    card_flow = []
    proactive_board = []
    early_engines = []
    reactive_only = []
    off_color_early = []
    for card in nonlands:
        effect_data = _opening_hand_effect(card)
        effect = _opening_hand_effect_name(card, effect_data)
        cmc = _opening_hand_card_cmc(card)
        role = _opening_hand_role(card, effect_data)
        additional_costs_live = _opening_hand_can_satisfy_basic_additional_costs(
            card, effect_data, lands
        )
        color_live = _opening_hand_card_is_color_live(card, hand, early_turn_window)
        evaluated.append({
            "card": card.get("name", "?"),
            "cmc": cmc,
            "effect": effect,
            "role": role,
            "additional_costs_live": additional_costs_live,
            "color_live": color_live,
        })
        if cmc > early_turn_window:
            continue
        if not additional_costs_live:
            continue
        if not color_live:
            off_color_early.append((card, cmc, role))
            continue
        if role == "ramp":
            if _opening_hand_ramp_card_is_live(card, effect_data, hand, lands, early_turn_window):
                live_ramp.append((card, cmc))
            continue
        if role == "card_flow":
            card_flow.append((card, cmc))
            continue
        if role == "engine":
            early_engines.append((card, cmc))
            continue
        if role == "interaction":
            reactive_only.append((card, cmc))
            continue
        if role in ("board", "other") and effect not in ("unknown", "ramp_ritual"):
            proactive_board.append((card, cmc))

    high_cost_count = sum(
        1
        for card in nonlands
        if isinstance(card, dict) and _opening_hand_card_cmc(card) >= 7
    )
    plan_details = {
        "early_turn_window": early_turn_window,
        "evaluated_nonlands": evaluated,
        "live_ramp_count": len(live_ramp),
        "card_flow_count": len(card_flow),
        "engine_count": len(early_engines),
        "proactive_board_count": len(proactive_board),
        "reactive_only_count": len(reactive_only),
        "off_color_early_count": len(off_color_early),
        "off_color_early_cards": [card.get("name", "?") for card, _cmc, _role in off_color_early[:4]],
        "high_cost_cluster_count": high_cost_count,
    }

    if live_ramp:
        chosen, cmc = sorted(live_ramp, key=lambda item: (item[1], item[0].get("name", "")))[0]
        return True, f"early_ramp:{chosen.get('name', '?')}:{cmc:g}", {
            **plan_details,
            "early_ramp": chosen.get("name", "?"),
            "early_ramp_cmc": cmc,
            "plan_role": "ramp",
        }

    if card_flow:
        chosen, cmc = sorted(card_flow, key=lambda item: (item[1], item[0].get("name", "")))[0]
        return True, f"early_card_flow:{chosen.get('name', '?')}:{cmc:g}", {
            **plan_details,
            "early_play": chosen.get("name", "?"),
            "early_play_cmc": cmc,
            "plan_role": "card_flow",
        }

    if early_engines:
        chosen, cmc = sorted(early_engines, key=lambda item: (item[1], item[0].get("name", "")))[0]
        return True, f"early_engine:{chosen.get('name', '?')}:{cmc:g}", {
            **plan_details,
            "early_play": chosen.get("name", "?"),
            "early_play_cmc": cmc,
            "plan_role": "engine",
        }

    if off_color_early and not (proactive_board or reactive_only):
        return False, "no_castable_early_play_by_color", plan_details

    if lands >= 5 and reactive_only and not proactive_board:
        return False, "land_heavy_reactive_only", plan_details

    if high_cost_count >= 3 and len(proactive_board) < 2:
        return False, "expensive_cluster_without_setup", plan_details

    if proactive_board:
        chosen, cmc = sorted(proactive_board, key=lambda item: (item[1], item[0].get("name", "")))[0]
        return True, f"early_play:{chosen.get('name', '?')}:{cmc:g}", {
            **plan_details,
            "early_play": chosen.get("name", "?"),
            "early_play_cmc": cmc,
            "plan_role": "board",
        }

    if reactive_only:
        return False, "reactive_only_opener", plan_details

    return False, "no_play_before_turn_3", plan_details


def _mulligan_bottom_priority(card, hand, land_count):
    if not isinstance(card, dict):
        return 0
    if is_effective_land(card):
        if land_count <= 3:
            return -100
        return 35 + max(0, land_count - 4) * 20

    effect_data = _opening_hand_effect(card)
    effect = _opening_hand_effect_name(card, effect_data)
    cmc = _opening_hand_card_cmc(card)
    priority = cmc * 8

    if cmc >= 7:
        priority += 60
    elif cmc >= 5:
        priority += 25

    early_window = 2 if land_count == 2 else (4 if land_count >= 5 else 3)
    if cmc <= early_window and effect not in ("counter", "unknown"):
        priority -= 70
    if not _opening_hand_card_is_color_live(card, hand, early_window):
        priority += 120

    if effect in ("ramp_permanent", "land_ramp", "mana_dork") and cmc <= 2:
        if _opening_hand_ramp_card_is_live(card, effect_data, hand, land_count, early_window):
            priority -= 90
        else:
            priority += 30

    if effect in ("remove_creature", "remove_permanent", "counter", "protection") and cmc <= 2:
        priority -= 45

    if effect in HIGH_IMPACT_PAYOFF_EFFECTS and cmc <= 4:
        priority -= 20

    if not _opening_hand_can_satisfy_basic_additional_costs(card, effect_data, land_count):
        priority += 55

    return priority


def choose_mulligan_bottom_cards(hand, bottom_count):
    """Choose London Mulligan bottom cards by strategic opening-hand policy."""
    if bottom_count <= 0:
        return []
    candidates = [card for card in hand if isinstance(card, dict)]
    if not candidates:
        return list(hand[:bottom_count])

    land_count = sum(1 for card in hand if is_effective_land(card))
    ranked = sorted(
        enumerate(candidates),
        key=lambda item: (
            -_mulligan_bottom_priority(item[1], hand, land_count),
            item[0],
        ),
    )
    return [card for _index, card in ranked[:bottom_count]]


def mulligan_evaluation(hand):
    lands = sum(1 for c in hand if is_effective_land(c))
    nonlands = len(hand) - lands
    high_cost_cards = [
        c.get("name", "?")
        for c in hand
        if isinstance(c, dict)
        and not is_effective_land(c)
        and _opening_hand_card_cmc(c) >= 7
    ]
    base = {
        "lands": lands,
        "nonlands": nonlands,
        "colors": _opening_hand_colors(hand),
        "hand_summary": _opening_hand_summary(hand),
        "high_cost_cards": high_cost_cards,
        "risk_flags": [],
    }
    if lands < 2:
        base["risk_flags"].append("mana_screw")
        return {
            **base,
            "keep": False,
            "reason": "too_few_lands",
        }
    if lands > 5:
        base["risk_flags"].append("mana_flood")
        return {
            **base,
            "keep": False,
            "reason": "too_many_lands",
        }

    has_plan, reason, plan_details = _opening_hand_has_early_plan(hand, lands)
    if not has_plan:
        base["risk_flags"].append("no_early_game_plan")
    if reason == "reactive_only_opener":
        base["risk_flags"].append("reactive_only_opener")
    if reason == "land_heavy_reactive_only":
        base["risk_flags"].append("land_heavy_low_action")
    if reason == "no_castable_early_play_by_color":
        base["risk_flags"].append("off_color_early_hand")
    if reason == "expensive_cluster_without_setup":
        base["risk_flags"].append("expensive_dead_hand")
    if len(high_cost_cards) >= 3 and not has_plan:
        base["risk_flags"].append("expensive_dead_hand")
    return {
        **base,
        **plan_details,
        "keep": has_plan,
        "reason": reason if reason else "no_early_game_plan",
    }


def mulligan_decision(hand):
    evaluation = mulligan_evaluation(hand)
    return evaluation["keep"], 7


def _mulligan_trace_keep_score(evaluation):
    """Trace-only score for explaining keep vs mulligan choices."""
    score = 0.0
    lands = int(evaluation.get("lands") or 0)
    if 2 <= lands <= 4:
        score += 4.0
    elif lands in (1, 5):
        score -= 2.0
    else:
        score -= 5.0

    if evaluation.get("early_ramp"):
        score += 3.0
    if evaluation.get("early_play"):
        score += 2.5
    if (evaluation.get("card_flow_count") or 0) > 0:
        score += 1.5
    if (evaluation.get("proactive_board_count") or 0) > 0:
        score += 1.0
    if (evaluation.get("off_color_early_count") or 0) > 0:
        score -= 2.0
    if (evaluation.get("high_cost_cluster_count") or 0) >= 3:
        score -= 4.0

    score -= len(evaluation.get("risk_flags") or []) * 2.0
    score += 3.0 if evaluation.get("keep") else -3.0
    return round(score, 2)


def _emit_mulligan_decision_trace(
    player,
    evaluation,
    *,
    mulligan_count,
    chosen_action,
    bottomed_cards,
    forced_keep=False,
):
    risk_flags = list(evaluation.get("risk_flags") or [])
    if forced_keep:
        risk_flags.append("forced_keep_after_mulligan_cap")
    hand_summary = evaluation.get("hand_summary") or []
    keep_score = _mulligan_trace_keep_score(evaluation)
    mulligan_score = -keep_score
    chosen_score = keep_score if chosen_action == "keep" else mulligan_score
    rejected_score = keep_score if chosen_action == "mulligan" else mulligan_score
    emit_decision_trace(
        decision_type="mulligan_decision",
        player=player,
        turn=0,
        phase="pregame",
        available_options=[
            {
                "action": "keep",
                "lands": evaluation.get("lands"),
                "nonlands": evaluation.get("nonlands"),
                "reason": evaluation.get("reason"),
                "score": keep_score,
            },
            {
                "action": "mulligan",
                "lands": evaluation.get("lands"),
                "nonlands": evaluation.get("nonlands"),
                "reason": evaluation.get("reason"),
                "score": mulligan_score,
                "available": not forced_keep,
            },
        ],
        chosen_option={
            "action": chosen_action,
            "mulligan_count": mulligan_count,
            "forced_keep": forced_keep,
            "score": chosen_score,
        },
        rejected_options=[
            {
                "action": "keep" if chosen_action == "mulligan" else "mulligan",
                "rejected_reason": "opening_hand_policy",
                "score": rejected_score,
            }
        ],
        score_components={
            "lands": evaluation.get("lands"),
            "nonlands": evaluation.get("nonlands"),
            "colors": evaluation.get("colors"),
            "early_play": evaluation.get("early_play"),
            "early_ramp": evaluation.get("early_ramp"),
            "early_turn_window": evaluation.get("early_turn_window"),
            "plan_role": evaluation.get("plan_role"),
            "card_flow_count": evaluation.get("card_flow_count"),
            "proactive_board_count": evaluation.get("proactive_board_count"),
            "reactive_only_count": evaluation.get("reactive_only_count"),
            "off_color_early_count": evaluation.get("off_color_early_count"),
            "off_color_early_cards": evaluation.get("off_color_early_cards"),
            "high_cost_cards": evaluation.get("high_cost_cards"),
            "high_cost_cluster_count": evaluation.get("high_cost_cluster_count"),
            "keep": evaluation.get("keep"),
        },
        rule_source="battle_opening_hand_policy",
        rule_status="heuristic",
        confidence="medium",
        expected_benefit_score=1 if evaluation.get("keep") else -1,
        actual_outcome=chosen_action,
        reason=evaluation.get("reason"),
        strategic_principle="opening_hand_must_have_mana_colors_and_playable_curve",
        resource_delta={
            "mulligans_taken": mulligan_count,
            "cards_in_hand": len(player.hand),
            "bottomed_cards": bottomed_cards,
        },
        risk_flags=risk_flags,
        alternatives_considered=hand_summary,
        rejected_reason="hand_lacks_keep_criteria" if chosen_action == "mulligan" else None,
    )

def cancel_plus_minus_counters(all_players):
    return _cancel_plus_minus_counters(
        all_players,
        numeric_stat=numeric_stat,
        emit_replay_event=emit_replay_event,
    )


def check_illegal_attachments(all_players):
    return _check_illegal_attachments(
        all_players,
        is_battlefield_creature=is_battlefield_creature,
        is_effective_land=is_effective_land,
        is_artifact_permanent=is_artifact_permanent,
        emit_replay_event=emit_replay_event,
    )


def check_saga_final_chapter(all_players):
    return _check_saga_final_chapter(
        all_players,
        numeric_stat=numeric_stat,
        emit_replay_event=emit_replay_event,
    )


def check_sbas(all_players):
    return _check_sbas(
        all_players,
        commander_damage_lethal_entries=commander_damage_lethal_entries,
        numeric_stat=numeric_stat,
        cancel_plus_minus_counters_func=cancel_plus_minus_counters,
        check_illegal_attachments_func=check_illegal_attachments,
        check_saga_final_chapter_func=check_saga_final_chapter,
        check_token_lifecycle_func=check_token_lifecycle,
        move_creature_from_battlefield=move_creature_from_battlefield,
        move_to_exile=move_to_exile,
        resolve_battle_back_face=resolve_battle_back_face,
        is_planeswalker_permanent=is_planeswalker_permanent,
        is_battle_permanent=is_battle_permanent,
        emit_replay_event=emit_replay_event,
    )


def check_token_lifecycle(all_players):
    return _check_token_lifecycle(
        all_players,
        emit_replay_event=emit_replay_event,
    )

def check_sbas_until_stable(all_players):
    return _check_sbas_until_stable(
        all_players,
        check_sbas_func=check_sbas,
        record_engine_metric=record_engine_metric,
    )



def _normalize_color_symbol(color):
    text = str(color or "").strip().lower()
    aliases = {
        "w": "white",
        "u": "blue",
        "b": "black",
        "r": "red",
        "g": "green",
    }
    return aliases.get(text, text)


def target_matches_type(target, target_type):
    """Minimal target selector matcher used before spell resolution."""
    target_type = str(target_type or "").lower()
    if not target_type:
        return True
    if target_type in ("creature", "target_creature"):
        return is_battlefield_creature(target)
    if target_type in ("artifact", "artifact_permanent"):
        return is_artifact_permanent(target)
    if target_type in ("enchantment", "enchantment_permanent"):
        return is_enchantment_permanent(target)
    if target_type in ("artifact_or_enchantment", "artifact_enchantment"):
        return is_artifact_permanent(target) or is_enchantment_permanent(target)
    if target_type == "artifact_or_creature":
        return is_artifact_permanent(target) or is_battlefield_creature(target)
    if target_type == "creature_or_enchantment":
        return is_battlefield_creature(target) or is_enchantment_permanent(target)
    if target_type == "colored_permanent":
        return is_colored_permanent(target)
    if target_type in ("nonland", "nonland_permanent"):
        return not is_effective_land(target)
    if target_type in ("permanent", "any"):
        return True
    return True


def is_legal_target(spell, target, controller, all_players=None, target_type=None, target_controller=None):
    """v9: Check if a target is still legal for a spell/ability (CR 608.2b)."""
    if not isinstance(target, dict):
        return False
    if target_type and not target_matches_type(target, target_type):
        return False
    if target.get("protection_from_everything"):
        return False
    if target.get("eliminated"):
        return False
    # Hexproof: can't be targeted by opponents
    target_controller_name = (
        target.get("controller")
        or target.get("owner")
        or getattr(target_controller, "name", None)
    )
    if target.get("hexproof") and controller.name != target_controller_name:
        return False
    # Shroud: can't be targeted at all
    if target.get("shroud"):
        return False
    # Protection from source's color
    protections = target.get("protection_from", [])
    if isinstance(protections, str):
        protections = [protections]
    protections = {_normalize_color_symbol(color) for color in protections}
    source_colors = spell.get("colors") or spell.get("color_identity") or []
    if isinstance(source_colors, str):
        source_colors = read_json_list(source_colors) or [source_colors]
    source_colors = {_normalize_color_symbol(color) for color in source_colors}
    if any(c in protections for c in source_colors):
        return False
    # Ward: doesn't affect legality, only triggers on cast
    return True


def targeting_decision(spell, target, controller, *, target_controller=None, target_type=None):
    legal = is_legal_target(
        spell,
        target,
        controller,
        target_type=target_type,
        target_controller=target_controller,
    )
    return {
        "targeting_pipeline": "targeting_formal_minimal",
        "target_name": target.get("name", "?") if isinstance(target, dict) else "?",
        "target_type": target_type or "any",
        "target_legal": legal,
        "target_controller": getattr(target_controller, "name", None),
    }


def controller_for_target(players, target):
    for candidate in players:
        if target in getattr(candidate, "battlefield", []):
            return candidate
    return None


def resolve_multi_target_removal(player, opponents, card, effect_data, turn, rng):
    """Resolve declared removal targets independently (CR 608.2b partial resolution)."""
    declared_targets = effect_data.get("declared_targets") or []
    if not declared_targets:
        return False
    target_type = str(effect_data.get("target") or "").lower()
    if not target_type:
        target_type = "creature" if effect_data.get("effect") == "remove_creature" else "nonland_permanent"

    resolved = []
    illegal = []
    ward_countered = []
    players = [player] + list(opponents)
    for entry in declared_targets:
        target = entry.get("target") if isinstance(entry, dict) else entry
        target_controller = (
            entry.get("controller") if isinstance(entry, dict) else None
        ) or controller_for_target(players, target)
        decision = targeting_decision(
            card,
            target,
            player,
            target_controller=target_controller,
            target_type=target_type,
        )
        if not decision["target_legal"] or target_controller is None:
            illegal.append(decision["target_name"])
            continue
        if check_ward(target, card, player, rng):
            ward_countered.append(decision["target_name"])
            continue
        move_permanent_from_battlefield(target_controller, target)
        resolved.append(decision["target_name"])

    emit_replay_event(
        "multi_target_resolution",
        player=player.name,
        card=card.get("name", "?"),
        target_type=target_type,
        declared=len(declared_targets),
        resolved=resolved,
        illegal=illegal,
        ward_countered=ward_countered,
        turn=turn,
    )
    return True

def game_winner(all_players):
    for player in all_players:
        if not player.has_won():
            continue
        blocked = any(
            opponent is not player
            and opponent.is_alive()
            and getattr(opponent, "cannot_lose_this_turn", False)
            for opponent in all_players
        )
        if not blocked:
            return player
    return None


MAIN_PHASES = {"precombat_main", "postcombat_main"}


def priority_order_from(active_player, all_players):
    if active_player in all_players:
        idx = all_players.index(active_player)
        ordered = [all_players[(idx + i) % len(all_players)] for i in range(len(all_players))]
    else:
        ordered = list(all_players)
    return [player for player in ordered if player.is_alive()]


def emit_priority_pass_sequence(active_player, all_players, turn, phase=None, reason=None, stack_item=None):
    order = priority_order_from(active_player, all_players)
    record_engine_metric("priority_passes", len(order))
    stack_top = None
    if stack_item is not None:
        stack_top = stack_item.card.get("name", "?") if isinstance(stack_item.card, dict) else str(stack_item.card)
    for index, player in enumerate(order, start=1):
        emit_replay_event(
            "priority_pass",
            active_player=active_player.name,
            player=player.name,
            pass_index=index,
            phase=phase,
            reason=reason,
            stack_top=stack_top,
            turn=turn,
        )
    return order


def _is_reactive_interaction_card(card, effect_data):
    effect = str(effect_data.get("effect") or card.get("effect") or "").lower()
    if effect in (
        "counter",
        "phase_out",
        "indestructible",
        "cannot_lose_turn",
        "modal_boros_charm",
        "remove_creature",
        "remove_permanent",
        "remove_artifact_or_enchantment",
        "bounce",
    ):
        return True
    return is_instant(card) or card_has_functional_tag(card, "counter", "protection", "removal")


def _pass_option_trace_score(card, effect_data, *, payable, phase_legal, reactive, main_phase_relevant):
    cmc = int(float(card.get("cmc") or 0))
    effect = str(effect_data.get("effect") or card.get("effect") or card.get("tag") or "").lower()
    score = 0.0
    if payable:
        score += 3.0
    else:
        score -= max(1.0, float(cmc))
    if phase_legal:
        score += 3.0
    if reactive:
        score += 2.0
    if effect in OPENING_HAND_RAMP_EFFECTS:
        score += 2.5
    elif effect in OPENING_HAND_CARD_FLOW_EFFECTS:
        score += 2.0
    elif effect in OPENING_HAND_REACTIVE_EFFECTS:
        score += 1.5
    elif effect in HIGH_IMPACT_PAYOFF_EFFECTS:
        score += 1.0
    if main_phase_relevant and not reactive and phase_legal:
        score += 1.0
    return round(score, 2)


def describe_pass_no_action(player, phase):
    nonland_cards = [
        card
        for card in player.hand
        if isinstance(card, dict) and not is_effective_land(card)
    ]
    available_options = [{"action": "pass"}]
    alternatives = []
    castable_now = []
    reactive_options = []
    affordable_cards = []
    main_phase_relevant = phase in MAIN_PHASES
    minimum_cmc = None

    for card in nonland_cards:
        effect_data = get_card_effect(card)
        cmc = int(float(card.get("cmc") or 0))
        payable = bool(player.can_pay_card(card))
        phase_legal = bool(can_cast_in_phase(card, effect_data, phase))
        if minimum_cmc is None or cmc < minimum_cmc:
            minimum_cmc = cmc
        option_score = _pass_option_trace_score(
            card,
            effect_data,
            payable=payable,
            phase_legal=phase_legal,
            reactive=_is_reactive_interaction_card(card, effect_data),
            main_phase_relevant=main_phase_relevant,
        )
        option = decision_card_option(
            card,
            effect_data,
            action="consider",
            score=option_score,
            payable=payable,
            phase_legal=phase_legal,
            reactive=_is_reactive_interaction_card(card, effect_data),
        )
        alternatives.append(option)
        if payable:
            affordable_cards.append(option)
        if payable and phase_legal:
            castable_now.append(option)
        if payable and _is_reactive_interaction_card(card, effect_data):
            reactive_options.append(option)

    score_components = {
        "stack_empty": 1,
        "main_phase_action_taken": 0,
        "phase_is_main": 1 if main_phase_relevant else 0,
        "hand_nonland_count": len(nonland_cards),
        "affordable_card_count": len(affordable_cards),
        "castable_now_count": len(castable_now),
        "reactive_option_count": len(reactive_options),
        "available_mana": player.available_mana(),
        "minimum_hand_cmc": minimum_cmc or 0,
    }
    risk_flags = []

    if main_phase_relevant:
        if castable_now:
            available_options.extend(castable_now[:8])
            if castable_now and len(castable_now) == len(reactive_options):
                reason = "hold_instant_speed_interaction"
                risk_flags.append("holding_instant_speed_interaction")
            else:
                reason = "defer_low_value_main_phase_action"
                risk_flags.append("low_value_main_phase_lines_only")
        elif reactive_options:
            available_options.extend(reactive_options[:8])
            reason = "hold_instant_speed_interaction"
            risk_flags.append("holding_instant_speed_interaction")
        elif affordable_cards:
            reason = "phase_or_heuristic_restriction_blocks_line"
            risk_flags.append("phase_restricted_action")
        elif nonland_cards:
            reason = "no_affordable_nonland_action"
            risk_flags.append("mana_constrained_hand")
        else:
            reason = "no_nonland_resources_available"
            risk_flags.append("empty_nonland_hand")
    else:
        if reactive_options:
            available_options.extend(reactive_options[:8])
            reason = "reactive_window_held"
            risk_flags.append("holding_instant_speed_interaction")
        elif nonland_cards:
            reason = "no_reactive_action_in_window"
            risk_flags.append("phase_restricted_action")
        else:
            reason = "no_nonland_resources_available"
            risk_flags.append("empty_nonland_hand")

    chosen_option = {"action": "pass", "reason": reason, "score": 0}
    rejected_options = [
        {**option, "action": "defer"}
        for option in available_options[1:9]
    ]
    return {
        "available_options": available_options,
        "chosen_option": chosen_option,
        "rejected_options": rejected_options,
        "alternatives_considered": alternatives[:12],
        "score_components": score_components,
        "risk_flags": sorted(set(risk_flags)),
        "reason": reason,
    }


def priority_round(active_player, all_players, stack, turn, rng, phase=None):
    """v9: Priority round with optional empty-stack window during main phases."""
    record_engine_metric("priority_rounds")
    flush_triggers_in_apnap(active_player, all_players, stack)

    if stack.empty():
        if phase in MAIN_PHASES and active_player.is_alive():
            opponents = [p for p in all_players if p != active_player and p.is_alive()]
            acted = cast_spells_v8(
                active_player,
                opponents,
                all_players,
                turn,
                phase,
                stack,
                rng,
                max_actions=1,
            )
            if acted:
                check_sbas_until_stable(all_players)
                flush_triggers_in_apnap(active_player, all_players, stack)
                return True
        emit_priority_pass_sequence(
            active_player,
            all_players,
            turn,
            phase=phase,
            reason="empty_stack",
        )
        pass_context = describe_pass_no_action(active_player, phase)
        emit_decision_trace(
            decision_type="pass_no_action",
            player=active_player,
            turn=turn,
            phase=phase,
            available_options=pass_context["available_options"],
            chosen_option=pass_context["chosen_option"],
            rejected_options=pass_context["rejected_options"],
            score_components=pass_context["score_components"],
            rule_source="battle_heuristic",
            rule_status="heuristic",
            confidence="medium",
            expected_benefit_score=0,
            actual_outcome="priority_pass",
            reason=pass_context["reason"],
            heuristic_version=DECISION_STRATEGY_VERSION,
            risk_flags=pass_context["risk_flags"],
            alternatives_considered=pass_context["alternatives_considered"],
            rejected_reason="preserve_resources_or_no_profitable_line",
        )
        return False

    order = priority_order_from(active_player, all_players)

    # v8.2: Score the top spell
    top_item = stack.items[-1] if stack.items else None
    if not top_item:
        return False
    if top_item.countered:
        stack.resolve_top()
        return False
    score = threat_score(top_item.effect_data.get("effect", ""), top_item.card.get("name", ""),
                         top_item.controller, all_players, turn)

    for player in order:
        if not player.is_alive():
            continue
        if player != top_item.controller and (
            top_item.controller.silenced_opponents
            or top_item.controller.silenced_opponents_until_eot
        ):
            continue
        if player.is_human:
            # Lorehold: use protection in response to high-threat spells
            if score >= 40:
                instants = [c for c in player.hand if is_instant(c) and player.can_pay_card(c)]
                for c in instants:
                    eff = get_card_effect(c)
                    if eff.get("effect") in ("phase_out", "indestructible", "modal_boros_charm", "cannot_lose_turn"):
                        if player.can_pay_card(c):
                            fields = replay_rule_fields(eff)
                            emit_decision_trace(
                                decision_type="response",
                                player=player,
                                turn=turn,
                                phase=phase,
                                available_options=[
                                    decision_card_option(
                                        option_card,
                                        get_card_effect(option_card),
                                        action="respond",
                                    )
                                    for option_card in instants[:8]
                                ],
                                chosen_option=decision_card_option(c, eff, action="protect"),
                                rejected_options=[
                                    decision_card_option(
                                        option_card,
                                        get_card_effect(option_card),
                                        action="reject_response",
                                    )
                                    for option_card in instants
                                    if option_card is not c
                                ][:8],
                                score_components={
                                    "stack_threat_score": score,
                                    "available_instants": len(instants),
                                },
                                rule_source=fields.get("rule_source", "battle_heuristic"),
                                rule_status=fields.get("rule_review_status", "heuristic"),
                                confidence="medium",
                                expected_benefit_score=score,
                                actual_outcome="protective_response_cast",
                                reason="high_threat_stack_response",
                            )
                            player.hand.remove(c)
                            player.spend_card_mana(c)
                            c["_response_to_effect"] = top_item.effect_data.get("effect")
                            emit_replay_event(
                                "spell_cast",
                                player=player.name,
                                card=c.get("name", "?"),
                                effect=eff.get("effect", "unknown"),
                                type_line=c.get("type_line", ""),
                                cmc=c.get("cmc", 0),
                                turn=turn,
                                phase=phase,
                                role="response",
                                response_to=top_item.card.get("name", "?"),
                                **replay_rule_fields(eff),
                            )
                            apply_effect_immediate(player, [p for p in all_players if p != player], c, turn, rng)
                            return True
        else:
            # v8.2: Smart counter decision based on threat score
            if player != top_item.controller and counter_worth(score, player, rng):
                counters = player.counterspell_cards(castable_only=True)
                counter = player.use_counterspell(turn, top_item.card)
                if counter:
                    fields = replay_rule_fields(get_card_effect(counter))
                    emit_decision_trace(
                        decision_type="response",
                        player=player,
                        turn=turn,
                        phase=phase,
                        available_options=[
                            decision_card_option(
                                option_card,
                                get_card_effect(option_card),
                                action="counter",
                            )
                            for option_card in counters[:8]
                        ],
                        chosen_option=decision_card_option(counter, get_card_effect(counter), action="counter"),
                        rejected_options=[
                            decision_card_option(
                                option_card,
                                get_card_effect(option_card),
                                action="reject_counter",
                            )
                            for option_card in counters
                            if option_card is not counter
                        ][:8],
                        score_components={
                            "stack_threat_score": score,
                            "counter_worth": 1,
                            "available_counters": len(counters),
                        },
                        rule_source=fields.get("rule_source", "battle_heuristic"),
                        rule_status=fields.get("rule_review_status", "heuristic"),
                        confidence="medium",
                        expected_benefit_score=score,
                        actual_outcome="counterspell_used",
                        reason="counter_high_threat_spell",
                    )
                    stack.items[-1].countered = True
                    return True

    # No one responded — resolve
    emit_priority_pass_sequence(
        active_player,
        all_players,
        turn,
        phase=phase,
        reason="stack_top_no_response",
        stack_item=top_item,
    )
    item = stack.resolve_top()
    if item:
        if item.effect_data.get("effect") == "triggered_ability":
            resolver = item.effect_data.get("resolver")
            if callable(resolver):
                resolver()
            if game_winner(all_players):
                return True
            check_sbas_until_stable(all_players)
            flush_triggers_in_apnap(active_player, all_players, stack)
            return True
        controller = item.controller
        opponents = [p for p in all_players if p != controller]
        apply_effect_immediate(controller, opponents, item.card, turn, rng)
        if game_winner(all_players):
            return True
        check_sbas_until_stable(all_players)
        flush_triggers_in_apnap(active_player, all_players, stack)
        if game_winner(all_players):
            return True
    return False


def run_priority_loop(active_player, all_players, stack, turn, phase, rng, max_empty_actions=3):
    """Run a bounded priority loop, including main-phase actions from empty stack.

    This keeps the simulator's current AI action model, but routes main-phase
    spell decisions through priority instead of bypassing `priority_round`.
    """
    acted = False
    empty_actions = 0

    while True:
        if game_winner(all_players):
            return acted
        if stack.empty() and not _pending_triggers:
            if phase not in MAIN_PHASES or empty_actions >= max_empty_actions:
                return acted
            if not priority_round(active_player, all_players, stack, turn, rng, phase=phase):
                return acted
            acted = True
            empty_actions += 1
            continue

        if priority_round(active_player, all_players, stack, turn, rng):
            acted = True
            continue
        return acted

def threat_score(effect_name, card_name, controller, all_players, turn):
    """v8.2: Calculate how threatening a spell is (0-100).
    Opponents use this to decide if they should respond."""
    score = 0

    # ── INSTANT WIN ──
    if effect_name == "approach":
        if controller.approach_count >= 1:
            return 100  # MUST counter (2nd cast = instant win)
        return 85  # v10.2: was 70 — higher counter priority

    if effect_name == "worldfire_reset":
        return 92

    # ── MASSIVE BOARD IMPACT ──
    if effect_name == "board_wipe":
        # Higher threat if caster has protection (asymmetric wipe)
        if controller.indestructible or controller.protection_from_everything:
            return 85
        # Higher threat if opponents have more creatures than caster
        caster_creatures = len(controller.untapped_creatures())
        opp_creatures = sum(len(o.untapped_creatures()) for o in all_players if o != controller and o.is_alive())
        if opp_creatures > caster_creatures * 2:
            return 75  # devastating for opponents
        return 45  # symmetric, fair

    if effect_name == "steal_all_creatures":
        total_stolen = sum(len([c for c in o.battlefield if is_battlefield_creature(c)])
                          for o in all_players if o != controller and o.is_alive())
        if total_stolen > 10:
            return 90
        return 65

    # ── WINCON SETUP ──
    if effect_name == "pump_all":
        creatures = [c for c in controller.battlefield if is_battlefield_creature(c)]
        total_power = sum(c.get("power", 2) for c in creatures)
        if total_power > 30:
            return 70  # lethal pump
        if total_power > 15:
            return 50
        return 30

    if effect_name == "copy_creature_token":
        creatures = [c for c in controller.battlefield if is_battlefield_creature(c)]
        return 45 if creatures else 10

    if effect_name == "token_maker":
        # How many tokens? If Storm Herd (life_total/2), it's a lot
        if controller.life > 30:
            return 60  # Storm Herd = 15+ tokens
        return 35

    if effect_name == "overload_recursion":
        spells_in_grave = sum(1 for c in controller.graveyard if isinstance(c, dict) and c.get("cmc", 0) > 0)
        if spells_in_grave > 10:
            return 80
        if spells_in_grave > 5:
            return 50
        return 30

    # ── REMOVAL ──
    if effect_name in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg"):
        # Counter-worthy only if it targets a key piece
        for opp in all_players:
            if opp == controller: continue
            if opp.is_alive():
                key_creatures = [c for c in opp.battlefield if isinstance(c, dict) and (
                    c.get("is_commander") or c.get("power", 0) > 5)]
                if key_creatures:
                    return 40  # targeting a key creature
        return 15  # minor removal

    # ── RAMP / DRAW ──
    if effect_name in ("ramp_permanent", "ramp_engine", "ramp_ritual"):
        mana_produced = 1 if effect_name == "ramp_permanent" else 3
        if turn <= 3:
            return 20  # early ramp is worth countering
        return 5  # late ramp, not worth

    if effect_name == "draw_engine":
        return controller.approach_count > 0 and 50 or 25  # higher threat if Approach was cast

    if effect_name in ("draw_cards", "hand_filter", "cantrip_mana_filter_artifact"):
        count = 2
        if controller.approach_count > 0 and count >= 2:
            return 45  # digging for Approach
        return 15

    if effect_name == "tutor":
        if controller.approach_count > 0:
            return 55  # tutoring for Approach
        return 25

    if effect_name == "extra_turn":
        return 65

    if effect_name == "extra_combat":
        return 45

    # ── PROTECTION ──
    if effect_name in ("phase_out", "indestructible"):
        # Cast in response to a wipe on the stack? High value
        return 30  # protection itself isn't threatening, but enables threats

    if effect_name == "finisher":
        return 60  # generic finisher, always dangerous

    if effect_name in ("silence_opponents", "silence_spell"):
        if controller.approach_count > 0:
            return 80  # silencing before Approach = can't counter
        return 50

    return 15  # default: minor threat

def counter_worth(threat_score, opp, rng):
    """v8.2: Should this opponent spend a counterspell on this threat?
    Returns True/False based on threat score and opponent's resources."""
    if not opp.has_counterspell():
        return False

    # Critical: Approach 2nd cast or lethal — always counter
    if threat_score >= 90:
        return True

    # High threat — counter if we have enough counterspells
    if threat_score >= 70:
        return rng.random() < 0.85

    # Medium threat — counter if we're not the target or have spare
    if threat_score >= 40:
        return rng.random() < 0.5

    # Low threat — only counter if we have many to spare
    if threat_score >= 20:
        return rng.random() < 0.2

    return False


def remember_until_eot(card, key):
    originals = card.setdefault("_until_eot_originals", {})
    if key not in originals:
        originals[key] = card.get(key, None)


def set_until_eot(card, key, value):
    remember_until_eot(card, key)
    card[key] = value


def clear_until_eot(player):
    """Restore temporary combat keywords/stat changes at cleanup."""
    zones = (player.battlefield, player.phased_out)
    for zone in zones:
        for card in zone:
            if not isinstance(card, dict):
                continue
            originals = card.pop("_until_eot_originals", {})
            for key, original in originals.items():
                if original is None:
                    card.pop(key, None)
                else:
                    card[key] = original
            card.pop("_landfall_triggers_this_turn", None)
    player.indestructible = False
    player.silenced_opponents_until_eot = False
    player.cannot_lose_this_turn = False
    player.damage_life_floor = None
    player.damage_prevention_shields = []


def grant_creatures_until_eot(player, *, keywords=(), power_multiplier=None):
    creatures = [
        card
        for card in player.battlefield
        if is_battlefield_creature(card)
    ]
    for creature in creatures:
        for keyword in keywords:
            if keyword == "protection_all":
                continue
            set_until_eot(creature, keyword, True)
        if power_multiplier:
            remember_until_eot(creature, "power")
            try:
                base_power = int(float(creature.get("power", 2)))
            except (TypeError, ValueError):
                base_power = 2
            creature["power"] = base_power * power_multiplier
    return len(creatures)


def move_creature_from_battlefield(owner, creature, reason=None, source=None, all_players=None):
    return _move_creature_from_battlefield(
        owner,
        creature,
        reason=reason,
        source=source,
        all_players=all_players,
        replacement_registry=ReplacementRegistry,
        replacement_event_cls=ReplacementEvent,
    )


def move_permanent_from_battlefield(owner, permanent, reason=None, source=None, all_players=None):
    return _move_permanent_from_battlefield(
        owner,
        permanent,
        reason=reason,
        source=source,
        all_players=all_players,
        replacement_registry=ReplacementRegistry,
        replacement_event_cls=ReplacementEvent,
    )


def is_artifact_permanent(card):
    if not isinstance(card, dict):
        return False
    type_line = str(card.get("type_line") or "").lower()
    return "artifact" in type_line or card.get("effect") in (
        "equipment_haste_shroud",
        "hate_artifact",
        "life_artifact",
        "ramp_permanent",
        "topdeck_manipulation",
    )


def is_enchantment_permanent(card):
    return isinstance(card, dict) and "enchantment" in str(card.get("type_line") or "").lower()


def is_colored_permanent(card):
    if not isinstance(card, dict):
        return False
    colors = card.get("colors") or card.get("color_identity") or []
    if isinstance(colors, str):
        colors = read_json_list(colors) or [colors]
    if colors:
        return any(str(color).upper() in {"W", "U", "B", "R", "G"} for color in colors)
    return bool(re.search(r"\{[WUBRG]\}", str(card.get("mana_cost") or "")))


def removal_target_candidates(player, effect_data=None, *, controller=None, source=None):
    effect_data = effect_data or {"effect": "remove_creature"}
    effect = effect_data.get("effect")
    target_type = str(effect_data.get("target") or "").lower()
    if not target_type:
        target_type = "creature" if effect == "remove_creature" else "nonland_permanent"

    candidates = []
    for card in player.battlefield:
        if not isinstance(card, dict):
            continue
        if not is_legal_target(
            source or effect_data,
            card,
            controller or player,
            target_type=target_type,
            target_controller=player,
        ):
            continue
        candidates.append(card)
    return candidates


def choose_best_creature_target(creatures):
    def target_priority(target):
        effect = get_card_effect(target).get("effect") or target.get("effect")
        if effect == "unknown":
            effect = target.get("effect")
        engine_priority = {
            "commander": 10,
            "combo": 9,
            "finisher": 8,
            "draw_engine": 7,
            "silence_opponents": 7,
            "ramp_engine": 6,
            "copy_spell": 6,
            "ripple_engine": 6,
            "hate_artifact": 5,
            "creature": 1,
        }.get(effect, 0)
        return (
            bool(target.get("is_commander")),
            engine_priority,
            int(target.get("cmc") or 0),
            int(target.get("power") or 0),
            int(target.get("toughness") or 0),
        )

    return max(
        creatures,
        key=target_priority,
    )


def _land_resource_cost_option(land, color_counts, *, zone):
    colors = list(source_colors(land)) if isinstance(land, dict) else []
    unique_colors = [color for color in colors if color_counts.get(color, 0) <= 1]
    type_line = str(land.get("type_line") or "") if isinstance(land, dict) else ""
    name = land.get("name", "?") if isinstance(land, dict) else str(land)
    is_basic = "basic" in type_line.lower() or name in BASIC_LAND_COLORS
    is_tapped = bool(land.get("tapped")) if isinstance(land, dict) else False
    risk_flags = []
    if unique_colors:
        risk_flags.append("spending_unique_color_land")
    if not colors:
        risk_flags.append("spending_unknown_color_land")
    return {
        "name": name,
        "zone": zone,
        "colors": colors,
        "unique_colors": unique_colors,
        "is_basic": is_basic,
        "is_tapped": is_tapped,
        "risk_flags": risk_flags,
        "selection_rank": (
            len(unique_colors),
            0 if is_tapped else 1,
            0 if is_basic else 1,
            name,
        ),
    }


def choose_land_for_resource_cost(lands, *, zone):
    """Choose a land to discard/sacrifice while preserving unique colors when possible."""
    candidates = [land for land in lands if isinstance(land, dict)]
    color_counts = defaultdict(int)
    for land in candidates:
        for color in source_colors(land):
            color_counts[color] += 1
    options = [
        _land_resource_cost_option(land, color_counts, zone=zone)
        for land in candidates
    ]
    if not options:
        return None, [], ["no_land_options"], None
    ranked = sorted(zip(candidates, options), key=lambda pair: pair[1]["selection_rank"])
    chosen, chosen_option = ranked[0]
    risk_flags = list(chosen_option.get("risk_flags") or [])
    if len(candidates) <= 1:
        risk_flags.append("spending_last_land")
    selection_reason = "prefer_redundant_tapped_basic_land_preserve_unique_colors"
    return chosen, options, sorted(set(risk_flags)), selection_reason


FETCH_LAND_NAMES = {
    "arid mesa",
    "bloodstained mire",
    "fabled passage",
    "flooded strand",
    "marsh flats",
    "misty rainforest",
    "polluted delta",
    "prismatic vista",
    "scalding tarn",
    "verdant catacombs",
    "windswept heath",
    "wooded foothills",
}


HIGH_VALUE_LAND_TARGETS = {
    "ancient tomb",
    "bojuka bog",
    "cabal coffers",
    "command tower",
    "dark depths",
    "field of the dead",
    "gaea's cradle",
    "nykthos, shrine to nyx",
    "strip mine",
    "thespian's stage",
    "wasteland",
}


def estimated_land_mana_value(land, player=None):
    name = normalize_card_name(land.get("name", "")) if isinstance(land, dict) else ""
    if name in FETCH_LAND_NAMES:
        return 0
    if name == "ancient tomb":
        return 2
    if name == "gaea's cradle" and player is not None:
        return max(
            1,
            sum(
                1
                for permanent in player.battlefield
                if isinstance(permanent, dict) and is_battlefield_creature(permanent)
            ),
        )
    colors = source_colors(land) if isinstance(land, dict) else ["generic"]
    return 1 if colors else 0


def land_ramp_target_option(land, effect_data, player):
    name = land.get("name", "?") if isinstance(land, dict) else str(land)
    normalized = normalize_card_name(name)
    colors = list(source_colors(land)) if isinstance(land, dict) else []
    enters_tapped = bool(effect_data.get("land_enters_tapped", True))
    mana_value = estimated_land_mana_value(land, player)
    is_fetch = normalized in FETCH_LAND_NAMES
    high_value = normalized in HIGH_VALUE_LAND_TARGETS
    score = mana_value * 20
    if not enters_tapped:
        score += 10
    if high_value:
        score += 25
    if is_fetch:
        score -= 15
    if "wildcard" in colors:
        score += 8
    if "generic" not in colors and colors:
        score += 4
    return {
        "name": name,
        "colors": colors,
        "enters_tapped": enters_tapped,
        "estimated_mana_value": mana_value,
        "is_fetch_land": is_fetch,
        "high_value_target": high_value,
        "score": score,
        "selection_rank": (-score, 1 if enters_tapped else 0, name),
    }


def choose_land_ramp_targets(player, effect_data, count):
    candidates = []
    for candidate in list(player.library):
        if not isinstance(candidate, dict) or not is_effective_land(candidate):
            continue
        if effect_data.get("basic_only") and "basic" not in str(candidate.get("type_line") or "").lower():
            continue
        candidates.append(candidate)
    options = [
        land_ramp_target_option(candidate, effect_data, player)
        for candidate in candidates
    ]
    ranked = sorted(zip(candidates, options), key=lambda pair: pair[1]["selection_rank"])
    chosen = ranked[:max(0, count)]
    return [pair[0] for pair in chosen], options


def land_sacrifice_has_strategic_benefit(strategic_risk_flags, target_options, count):
    risk = set(strategic_risk_flags or [])
    if not ({"spending_last_land", "spending_unique_color_land"} & risk):
        return True, "no_scarce_land_risk"
    if count >= 2:
        return True, "net_land_count_increase"
    if not target_options:
        return False, "no_land_ramp_target_context"
    selected = sorted(target_options, key=lambda item: item["selection_rank"])[:max(1, count)]
    best = selected[0]
    if best.get("high_value_target") and not best.get("is_fetch_land"):
        return True, "high_value_land_target"
    if not best.get("enters_tapped") and int(best.get("estimated_mana_value") or 0) >= 2:
        return True, "untapped_net_mana_upgrade"
    if "spending_unique_color_land" in risk:
        sacrificed_colors = set()
        # The target context alone cannot know the sacrificed land, so this
        # accepts only clear flexible fixing; otherwise the auditor must review.
        if "wildcard" in set(best.get("colors") or []):
            return True, "flexible_color_fixing"
    return False, "unique_color_loss_without_clear_replacement"


def self_sacrifice_land_tutor_has_strategic_benefit(player, target_options):
    if not target_options:
        return False, "no_land_ramp_target_context"

    current_lands = controlled_land_count(player)
    if current_lands <= 4:
        return True, "early_land_development"

    selected = sorted(target_options, key=lambda item: item["selection_rank"])[0]
    if selected.get("high_value_target"):
        return True, "high_value_land_target"

    target_colors = set(selected.get("colors") or [])
    if "wildcard" in target_colors:
        return True, "flexible_color_fixing"

    if current_lands <= 5:
        return True, "baseline_land_development"

    return False, "land_tutor_artifact_low_payoff"
    return False, "last_land_spend_without_clear_payoff"


def choose_creature_for_resource_cost(player, *, required_color=None):
    candidates = [
        permanent
        for permanent in player.battlefield
        if is_battlefield_creature(permanent)
    ]
    if required_color:
        candidates = [
            permanent
            for permanent in candidates
            if card_has_color(permanent, required_color)
        ]
    if not candidates:
        return None, [], "no_matching_creature"

    def selection_key(permanent):
        return (
            1 if permanent.get("is_commander") else 0,
            int(float(permanent.get("power") or 0)),
            int(float(permanent.get("toughness") or 0)),
            int(float(permanent.get("cmc") or 0)),
            permanent.get("name", ""),
        )

    ranked = sorted(candidates, key=selection_key)
    option_rows = []
    for rank, permanent in enumerate(ranked, start=1):
        option_rows.append(
            {
                "name": permanent.get("name", "?"),
                "selection_rank": rank,
                "is_commander": bool(permanent.get("is_commander")),
                "power": int(float(permanent.get("power") or 0)),
                "toughness": int(float(permanent.get("toughness") or 0)),
                "cmc": int(float(permanent.get("cmc") or 0)),
                "required_color": required_color,
            }
        )
    selection_reason = (
        "lowest_board_value_matching_required_color"
        if required_color
        else "lowest_board_value_creature"
    )
    return ranked[0], option_rows, selection_reason


def additional_card_costs_are_payable(player, card, effect_data):
    if effect_data.get("requires_discard_card"):
        discardable = [
            candidate
            for candidate in player.hand
            if isinstance(candidate, dict)
            and candidate is not card
            and not candidate.get("is_commander")
        ]
        if not discardable:
            return False
    if effect_data.get("requires_discard_land"):
        discardable_lands = [
            candidate
            for candidate in player.hand
            if isinstance(candidate, dict)
            and candidate is not card
            and is_land(candidate)
        ]
        if not discardable_lands:
            return False
    if effect_data.get("requires_sacrifice_green_creature"):
        creature, _options, _reason = choose_creature_for_resource_cost(
            player,
            required_color="G",
        )
        if creature is None:
            return False
    elif effect_data.get("requires_sacrifice_creature"):
        creature, _options, _reason = choose_creature_for_resource_cost(player)
        if creature is None:
            return False
    return True


def pay_additional_card_costs(player, card, effect_data, *, turn=None):
    """Pay non-mana costs that materially affect battlefield validity."""
    if (
        not effect_data.get("requires_discard_card")
        and not effect_data.get("requires_discard_land")
        and not effect_data.get("requires_sacrifice_creature")
        and not effect_data.get("requires_sacrifice_green_creature")
    ):
        return True
    if effect_data.get("requires_discard_card"):
        discard_any = next(
            (
                candidate
                for candidate in player.hand
                if isinstance(candidate, dict)
                and not candidate.get("is_commander")
            ),
            None,
        )
        if not discard_any:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="discard_card",
                turn=turn,
            )
            return False
        player.hand.remove(discard_any)
        player.graveyard.append(discard_any)
        emit_replay_event(
            "additional_cost_paid",
            player=player.name,
            card=card.get("name", "?"),
            cost="discard_card",
            discarded=discard_any.get("name", "?"),
            turn=turn,
        )
    if effect_data.get("requires_discard_land"):
        hand_lands = [
            candidate
            for candidate in player.hand
            if isinstance(candidate, dict) and is_land(candidate)
        ]
        discard, land_options, strategic_risk_flags, selection_reason = choose_land_for_resource_cost(
            hand_lands,
            zone="hand",
        )
        if not discard:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="discard_land",
                turn=turn,
                land_options=land_options,
                strategic_risk_flags=strategic_risk_flags,
            )
            return False
        player.hand.remove(discard)
        player.graveyard.append(discard)
        emit_replay_event(
            "additional_cost_paid",
            player=player.name,
            card=card.get("name", "?"),
            cost="discard_land",
            discarded=discard.get("name", "?"),
            turn=turn,
            land_options=land_options,
            selection_reason=selection_reason,
            strategic_risk_flags=strategic_risk_flags,
        )
    required_color = "G" if effect_data.get("requires_sacrifice_green_creature") else None
    if effect_data.get("requires_sacrifice_creature") or required_color:
        sacrifice, creature_options, selection_reason = choose_creature_for_resource_cost(
            player,
            required_color=required_color,
        )
        cost_name = "sacrifice_green_creature" if required_color else "sacrifice_creature"
        if not sacrifice:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost=cost_name,
                required_color=required_color,
                turn=turn,
            )
            return False
        destination = move_creature_from_battlefield(player, sacrifice)
        emit_replay_event(
            "additional_cost_paid",
            player=player.name,
            card=card.get("name", "?"),
            cost=cost_name,
            sacrificed=sacrifice.get("name", "?"),
            destination=destination,
            creature_options=creature_options,
            selection_reason=selection_reason,
            required_color=required_color,
            turn=turn,
        )
    return True


def chrome_mox_imprint_colors(card):
    """Return colors Chrome Mox can produce from a candidate imprint card."""
    if not isinstance(card, dict):
        return []
    explicit = card.get("colors") or card.get("color_identity")
    if isinstance(explicit, str):
        explicit = re.findall(r"[WUBRG]", explicit.upper())
    colors = [
        MANA_SYMBOL_TO_POOL.get(str(color).upper(), str(color).lower())
        for color in (explicit or [])
    ]
    return [
        color
        for color in colors
        if color in {"white", "blue", "black", "red", "green"}
    ]


def is_chrome_mox_imprint_candidate(card):
    if not isinstance(card, dict):
        return False
    if card.get("is_commander"):
        return False
    if is_effective_land(card) or is_land(card):
        return False
    if "artifact" in str(card.get("type_line") or "").lower():
        return False
    return bool(chrome_mox_imprint_colors(card))


def choose_chrome_mox_imprint_card(player, source_card):
    candidates = [
        candidate
        for candidate in player.hand
        if candidate is not source_card
        and is_chrome_mox_imprint_candidate(candidate)
    ]
    options = []
    critical_effects = {
        "approach",
        "board_wipe",
        "counter",
        "finisher",
        "protection",
        "remove_creature",
        "remove_permanent",
        "tutor",
        "wincon",
        "worldfire_reset",
    }
    for candidate in candidates:
        effect_data = get_card_effect(candidate)
        effect = str(effect_data.get("effect") or candidate.get("effect") or "unknown")
        cmc = _opening_hand_card_cmc(candidate)
        rank = 100
        if effect in {"unknown", "passive"}:
            rank -= 25
        if cmc >= 5:
            rank -= min(20, int(cmc) * 2)
        if effect in {"draw_cards", "ramp_ritual", "ramp_permanent"}:
            rank += 15
        if effect in critical_effects:
            rank += 60
        risk_flags = []
        if effect in critical_effects:
            risk_flags.append("imprinting_high_value_card")
        options.append(
            {
                "card": candidate.get("name", "?"),
                "cmc": cmc,
                "effect": effect,
                "colors": chrome_mox_imprint_colors(candidate),
                "selection_rank": rank,
                "risk_flags": risk_flags,
            }
        )
    options.sort(key=lambda option: (option["selection_rank"], option["cmc"], option["card"]))
    if not options:
        return None, [], ["no_valid_imprint_card"], "no_nonartifact_nonland_colored_card"
    chosen_name = options[0]["card"]
    chosen = next(candidate for candidate in candidates if candidate.get("name") == chosen_name)
    return (
        chosen,
        options,
        list(options[0].get("risk_flags") or []),
        "prefer_lowest_strategic_value_colored_nonartifact_nonland",
    )


def resolve_chrome_mox_imprint(player, permanent, source_card, *, turn=None):
    imprint, options, risk_flags, reason = choose_chrome_mox_imprint_card(player, source_card)
    if not imprint:
        permanent["mana_produced"] = 0
        emit_replay_event(
            "imprint_failed",
            player=player.name,
            card=source_card.get("name", "?"),
            cost="imprint_nonartifact_nonland",
            reason=reason,
            turn=turn,
            imprint_options=options,
            strategic_risk_flags=risk_flags,
        )
        return False
    player.hand.remove(imprint)
    player.exile.append(imprint)
    colors = chrome_mox_imprint_colors(imprint)
    permanent["imprinted_card"] = imprint.get("name", "?")
    permanent["imprinted_colors"] = colors
    permanent["produces"] = "".join(
        {
            "white": "W",
            "blue": "U",
            "black": "B",
            "red": "R",
            "green": "G",
        }[color]
        for color in ["white", "blue", "black", "red", "green"]
        if color in colors
    )
    permanent["mana_produced"] = 1 if colors else 0
    emit_replay_event(
        "imprint_resolved",
        player=player.name,
        card=source_card.get("name", "?"),
        imprinted=imprint.get("name", "?"),
        imprinted_colors=colors,
        turn=turn,
        imprint_options=options,
        selection_reason=reason,
        strategic_risk_flags=risk_flags,
    )
    return True


def everflowing_chalice_additional_costs(kicker_count):
    return ["{2}" for _ in range(max(0, int(kicker_count or 0)))]


def ritual_mana_produced(player, effect_data):
    threshold_count = effect_data.get("threshold_graveyard_count")
    threshold_mana = effect_data.get("threshold_mana_produced")
    if threshold_count and threshold_mana and len(player.graveyard) >= int(threshold_count):
        return int(threshold_mana)
    return int(effect_data.get("mana_produced", 3))


def controlled_land_count(player):
    return sum(1 for permanent in player.battlefield if isinstance(permanent, dict) and is_effective_land(permanent))


def battlefield_creature_stats(player):
    creatures = [
        permanent
        for permanent in player.battlefield
        if is_battlefield_creature(permanent)
    ]
    return {
        "count": len(creatures),
        "power": sum(int(creature.get("power") or 0) for creature in creatures),
        "toughness": sum(int(creature.get("toughness") or 0) for creature in creatures),
    }


def controlled_artifact_count(player):
    return sum(
        1
        for permanent in player.battlefield
        if isinstance(permanent, dict) and is_artifact_permanent(permanent)
    )


def controlled_artifact_count_for_search(player):
    """Battlefield artifact count plus simplified Treasure artifacts."""
    return controlled_artifact_count(player) + int(getattr(player, "treasures", 0) or 0)


def is_urzas_saga(permanent):
    return (
        isinstance(permanent, dict)
        and normalize_card_name(permanent.get("name", "")) == "urza's saga"
    )


def initialize_special_land_runtime_state(permanent, turn=None):
    if not isinstance(permanent, dict):
        return permanent
    if is_urzas_saga(permanent):
        permanent.setdefault("lore_counters", 1)
        permanent.setdefault("current_chapter", 1)
        permanent.setdefault("final_chapter", 3)
        if turn is not None:
            permanent.setdefault("saga_last_lore_turn", turn)
        permanent.setdefault("chapter_ability_pending", False)
    return permanent


def board_wipe_decision_context(player, opponents):
    own = battlefield_creature_stats(player)
    opposing = [battlefield_creature_stats(opp) for opp in opponents if opp.is_alive()]
    opponent_creatures = sum(item["count"] for item in opposing)
    opponent_power = sum(item["power"] for item in opposing)
    asymmetry = opponent_creatures - own["count"]
    lethal_pressure = opponent_power >= player.life
    behind_on_board = opponent_power > own["power"] or opponent_creatures > own["count"]
    rebuild_cards = [
        card
        for card in player.hand
        if isinstance(card, dict)
        and not is_effective_land(card)
        and get_card_effect(card).get("effect")
        in {"creature", "draw_cards", "draw_engine", "token_maker", "ramp_permanent", "land_ramp"}
    ]
    rebuild_engines = [
        permanent.get("name", "?")
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("effect") in {"draw_engine", "ramp_engine", "passive"}
    ]
    rebuild_plan = len(rebuild_cards) >= 2 or bool(rebuild_engines)
    justified = bool(asymmetry > 0 or lethal_pressure or behind_on_board or rebuild_plan)
    return {
        "own_creatures": own["count"],
        "own_power": own["power"],
        "opponent_creatures": opponent_creatures,
        "opponent_power": opponent_power,
        "asymmetry": asymmetry,
        "lethal_pressure": lethal_pressure,
        "behind_on_board": behind_on_board,
        "rebuild_cards_in_hand": len(rebuild_cards),
        "rebuild_engines": sorted(rebuild_engines)[:6],
        "rebuild_plan": rebuild_plan,
        "timing_justified": justified,
    }


def wheel_decision_context(player, opponents, draw_count):
    hand_size = len(player.hand)
    opponent_hands = [len(opp.hand) for opp in opponents if opp.is_alive()]
    opponent_refill_risk = sum(1 for size in opponent_hands if size < draw_count)
    net_cards_for_player = draw_count - hand_size
    opponent_net_cards = [
        draw_count - size
        for size in opponent_hands
    ]
    total_opponent_net_cards = sum(max(0, value) for value in opponent_net_cards)
    payoff_names = {
        permanent.get("name")
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("name") in {"Smothering Tithe", "Notion Thief", "Narset, Parter of Veils"}
    }
    payoff_expected = bool(payoff_names)
    timing_justified = (
        payoff_expected
        or (net_cards_for_player >= 4 and opponent_refill_risk == 0)
        or (net_cards_for_player >= 5 and total_opponent_net_cards <= net_cards_for_player)
    )
    return {
        "hand_size_before": hand_size,
        "draw_count": draw_count,
        "net_cards_for_player": net_cards_for_player,
        "opponent_hand_sizes": opponent_hands,
        "opponent_net_cards": opponent_net_cards,
        "total_opponent_net_cards": total_opponent_net_cards,
        "opponent_refill_risk": opponent_refill_risk,
        "wheel_payoffs": sorted(payoff_names),
        "payoff_expected": payoff_expected,
        "timing_justified": timing_justified,
        "model_scope": "multiplayer_discard_draw_v1",
    }


def process_upkeep_utility_lands(player, turn):
    """Resolve passive utility-land text that is low-risk under the current model."""
    triggers = 0
    artifact_count = controlled_artifact_count(player)
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict) or not is_effective_land(permanent):
            continue
        initialize_special_land_runtime_state(permanent, turn=None)
        if is_urzas_saga(permanent):
            current_chapter = max(
                int(permanent.get("current_chapter") or 1),
                int(permanent.get("lore_counters") or 0),
            )
            if permanent.get("saga_last_lore_turn") != turn and current_chapter < 3:
                next_chapter = current_chapter + 1
                permanent["current_chapter"] = next_chapter
                permanent["lore_counters"] = next_chapter
                permanent["saga_last_lore_turn"] = turn
                permanent["chapter_ability_pending"] = True
                emit_replay_event(
                    "saga_chapter_progressed",
                    player=player.name,
                    card=permanent.get("name", "?"),
                    chapter=next_chapter,
                    turn=turn,
                )
                if next_chapter == 3:
                    candidates = [
                        candidate
                        for candidate in player.library
                        if isinstance(candidate, dict)
                        and "artifact" in str(candidate.get("type_line") or "").lower()
                        and int(float(candidate.get("cmc") or 0)) <= 1
                        and "discard a land card" not in str(candidate.get("oracle_text") or "").lower()
                        and "imprint" not in str(candidate.get("oracle_text") or "").lower()
                    ]
                    scored_candidates = [
                        (
                            candidate,
                            *tutor_candidate_score(candidate, "artifact", player, [], turn),
                        )
                        for candidate in candidates
                    ]
                    scored_candidates.sort(
                        key=lambda item: (
                            -item[1],
                            int(float(item[0].get("cmc") or 0)),
                            item[0].get("name", ""),
                        )
                    )
                    found = None
                    found_score = 0
                    found_reason = "no_safe_artifact_target"
                    if scored_candidates:
                        found, found_score, found_reason = scored_candidates[0]
                        player.library.remove(found)
                        permanent_effect = get_card_effect(found)
                        found_permanent = prepare_entering_permanent(
                            enrich_card({**found, **permanent_effect})
                        )
                        if is_creature_card(found_permanent):
                            found_permanent["effect"] = "creature"
                        player.battlefield.append(found_permanent)
                    emit_decision_trace(
                        decision_type="saga_chapter_resolution",
                        player=player,
                        turn=turn,
                        phase="upkeep",
                        available_options=[
                            decision_card_option(
                                candidate,
                                get_card_effect(candidate),
                                score=score,
                                action="tutor_to_battlefield",
                                reason=reason,
                                target_type="artifact_cmc_1_or_less",
                            )
                            for candidate, score, reason in scored_candidates[:10]
                        ],
                        chosen_option=(
                            decision_card_option(
                                found,
                                get_card_effect(found),
                                score=found_score,
                                action="tutor_to_battlefield",
                                reason=found_reason,
                                target_type="artifact_cmc_1_or_less",
                            )
                            if found is not None
                            else {
                                "action": "resolve_without_target",
                                "target_type": "artifact_cmc_1_or_less",
                                "reason": found_reason,
                            }
                        ),
                        rejected_options=[
                            decision_card_option(
                                candidate,
                                get_card_effect(candidate),
                                score=score,
                                action="reject_tutor_target",
                                reason=reason,
                                target_type="artifact_cmc_1_or_less",
                            )
                            for candidate, score, reason in scored_candidates[1:10]
                        ],
                        score_components={
                            "chapter": 3,
                            "candidate_count": len(scored_candidates),
                            "selected_reason": found_reason,
                        },
                        rule_source="utility_land_activation_v1",
                        rule_status="verified",
                        confidence="medium",
                        expected_benefit_score=found_score,
                        reason="convert_final_saga_chapter_into_best_safe_artifact",
                        strategic_principle="tutor_best_low_cost_artifact_before_saga_leaves",
                        resource_delta={
                            "cards": 1 if found is not None else 0,
                            "lands": 0,
                            "selected": found.get("name", "?") if found is not None else None,
                            "zone_move": "library_to_battlefield",
                        },
                        risk_flags=[] if found is not None else ["no_safe_target"],
                        rejected_reason="lower_contextual_tutor_score",
                    )
                    emit_replay_event(
                        "saga_chapter_resolved",
                        player=player.name,
                        card=permanent.get("name", "?"),
                        chapter=3,
                        found=found.get("name", "?") if found is not None else None,
                        turn=turn,
                    )
                permanent["chapter_ability_pending"] = False
                triggers += 1
        if normalize_card_name(permanent.get("name", "")) == "inventors' fair":
            if artifact_count >= 3:
                gain_life(player, 1, cap=999)
                emit_replay_event(
                    "utility_land_triggered",
                    player=player.name,
                    card=permanent.get("name", "?"),
                    trigger_kind="upkeep_life_gain",
                    life_gained=1,
                    artifact_count=artifact_count,
                    turn=turn,
                )
                triggers += 1
    return triggers


def graveyard_enchantment_recovery_score(card, player, turn):
    effect_data = get_card_effect(card)
    effect = str(effect_data.get("effect") or card.get("effect") or "unknown")
    score = threat_score(effect, card.get("name", "?"), player, [player], turn)
    cmc = int(float(card.get("cmc") or 0))
    expected_next_turn_mana = max(controlled_land_count(player), 1) if player is not None else 1
    reason = "highest_contextual_enchantment_recovery_value"
    if effect in ("ramp_engine", "draw_engine", "topdeck_manipulation"):
        score = max(score, 70)
        if cmc <= expected_next_turn_mana + 1:
            score += 8
        reason = "recover_engine_enchantment"
    elif effect in ("token_maker", "finisher", "approach", "wincon"):
        score = max(score, 35)
        if cmc > expected_next_turn_mana + 1:
            score -= min((cmc - (expected_next_turn_mana + 1)) * 8, 32)
        reason = "recover_closing_enchantment"
    elif effect == "passive":
        score = max(score, 48)
        if cmc <= expected_next_turn_mana + 1:
            score += 6
        reason = "recover_static_value_enchantment"
    return score, reason


def should_cast_board_wipe(player, opponents):
    return board_wipe_decision_context(player, opponents)["timing_justified"]


def worldfire_decision_context(player, opponents):
    commander = None
    if player.command_zone:
        first = player.command_zone[0]
        if isinstance(first, dict):
            commander = first
    commander_tax = int(player.commander_tax or 0)
    floating_mana_after_reset = int(player.available_mana())
    treasures_before_reset = int(player.treasures or 0)
    commander_redeploy_available = False
    commander_name = None
    commander_effect = {}
    if commander is not None:
        commander_name = commander.get("name", "?")
        commander_effect = get_card_effect(commander)
        saved_treasures = player.treasures
        try:
            player.treasures = 0
            commander_redeploy_available = player.can_pay_card(
                commander,
                additional_generic=commander_tax,
            )
        finally:
            player.treasures = saved_treasures
    commander_immediate_damage = False
    if commander_redeploy_available:
        commander_immediate_damage = (
            commander_effect.get("effect") == "deal_damage"
            or int(commander_effect.get("damage") or 0) >= 1
            or int(commander_effect.get("etb_damage") or 0) >= 1
        )
    return {
        "model_scope": "worldfire_total_reset_v1",
        "floating_mana_after_reset": floating_mana_after_reset,
        "treasures_lost_to_reset": treasures_before_reset,
        "commander_name": commander_name,
        "commander_tax": commander_tax,
        "commander_redeploy_available": commander_redeploy_available,
        "commander_immediate_damage": commander_immediate_damage,
        "known_follow_up_line": commander_immediate_damage,
        "timing_justified": commander_immediate_damage,
        "opponents_alive": sum(1 for opp in opponents if opp.is_alive()),
    }


def should_cast_worldfire_reset(player, opponents):
    return worldfire_decision_context(player, opponents)["timing_justified"]


def should_cast_wheel(player, opponents, effect_data):
    draw_count = wheel_like_draw_count(
        effect_data if isinstance(effect_data, dict) and effect_data.get("name") else {},
        effect_data,
        player=player,
        opponents=opponents,
    )
    return wheel_decision_context(
        player,
        opponents,
        draw_count,
    )["timing_justified"]


def resolve_wheel_like_draw(player, opponents, card, draw_count, turn, rng):
    participants = [participant for participant in [player] + list(opponents) if participant.is_alive()]
    results = []
    total_opponent_drawn = 0
    for participant in participants:
        discarded_cards = list(participant.hand)
        participant.hand = []
        discard_resolution = resolve_effect_discard_cards(
            participant,
            discarded_cards,
            top_limit=draw_count,
        )
        drawn = participant.draw(draw_count, rng)
        if participant is not player:
            total_opponent_drawn += len(drawn)
        results.append({
            "player": participant.name,
            "discarded": len(discarded_cards),
            "discarded_to_top": [entry.get("name", "?") for entry in discard_resolution["to_top"]],
            "discarded_to_graveyard": [
                entry.get("name", "?") for entry in discard_resolution["to_graveyard"]
            ],
            "drawn": len(drawn),
            "hand_after": len(participant.hand),
        })
    payoff_names = {
        permanent.get("name")
        for permanent in player.battlefield
        if isinstance(permanent, dict)
    }
    treasures_created = 0
    if "Smothering Tithe" in payoff_names and total_opponent_drawn:
        treasures_created = min(total_opponent_drawn, 20)
        player.treasures += treasures_created
    emit_replay_event(
        "wheel_resolved",
        player=player.name,
        card=card.get("name", "?"),
        draw_count=draw_count,
        participants=results,
        opponent_cards_drawn=total_opponent_drawn,
        treasures_created=treasures_created,
        turn=turn,
    )
    return results


def is_wheel_like_card(card, effect_data):
    name = normalize_card_name(card.get("name", "")) if isinstance(card, dict) else ""
    count = wheel_like_draw_count(card, effect_data)
    return count >= 7 or any(
        marker in name
        for marker in ("wheel", "windfall", "timetwister", "reforge")
    )


def wheel_like_draw_count(card, effect_data, *, player=None, opponents=None):
    count = int(effect_data.get("count") or 0)
    if count > 0:
        return count
    name = normalize_card_name(card.get("name", "")) if isinstance(card, dict) else ""
    if any(marker in name for marker in ("wheel", "reforge", "timetwister")):
        return 7
    if "windfall" in name and player is not None:
        hand_sizes = [len(player.hand)]
        hand_sizes.extend(len(opp.hand) for opp in (opponents or []) if opp.is_alive())
        return max(hand_sizes) if hand_sizes else 0
    return 0


def move_zone_object_to_exile(owner, zone_name, card, *, reason=None, source=None, turn=None):
    if not isinstance(card, dict):
        zone = getattr(owner, zone_name, None)
        if isinstance(zone, list) and card in zone:
            zone.remove(card)
        move_to_exile(owner, card, reason=reason, turn=turn)
        return "exile"

    zone = getattr(owner, zone_name, None)
    if isinstance(zone, list) and card in zone:
        zone.remove(card)

    if zone_name == "battlefield":
        card["_lki_snapshot"] = {
            "name": card.get("name", card.get("card_name", "")),
            "power": card.get("power", 0),
            "toughness": card.get("toughness", 0),
            "cmc": card.get("cmc", 0),
            "type_line": card.get("type_line", ""),
            "is_commander": card.get("is_commander", False),
            "owner": card.get("owner", card.get("controller", "")),
        }
        card["_zone_id"] = card.get("_zone_id", 0) + 1
        card["_last_zone"] = "battlefield"

    if card.get("is_commander"):
        event = ReplacementRegistry.process_event(
            ReplacementEvent(
                "zone_change",
                affected_player=owner,
                card=card,
                from_zone=zone_name,
                to_zone="exile",
                source=source,
                reason=reason,
            )
        )
        if event.to_zone == "command_zone":
            owner.command_zone.append(card)
            return "command_zone"

    if zone_name == "battlefield" and (
        card.get("tag") == "token"
        or "token" in str(card.get("type_line") or "").lower()
    ):
        return "vanished_token"

    move_to_exile(owner, card, reason=reason, turn=turn)
    return "exile"


def commander_color_identity_count(player):
    commander = player.commander if isinstance(player.commander, dict) else None
    if commander is None and player.command_zone:
        first = player.command_zone[0]
        if isinstance(first, dict):
            commander = first
    if commander is None:
        return 1
    colors = compute_color_identity(commander)
    return len(colors) if colors else 1


def _can_pay_card_with_bonus_mana(
    player,
    card,
    *,
    bonus_amount=1,
    bonus_color="colorless",
    additional_generic=0,
):
    if bonus_amount <= 0:
        return player.can_pay_card(card, additional_generic=additional_generic)
    current = getattr(player.mana_pool, bonus_color, 0)
    setattr(player.mana_pool, bonus_color, current + int(bonus_amount))
    try:
        return player.can_pay_card(card, additional_generic=additional_generic)
    finally:
        setattr(player.mana_pool, bonus_color, current)


def ancient_tomb_unlock_candidates(player, opponents, all_players, turn):
    candidates = []

    if player.command_zone:
        commander = player.command_zone[0]
        commander_tax = int(player.commander_tax or 0)
        already_on_board = any(
            isinstance(permanent, dict)
            and permanent.get("name") == commander.get("name")
            for permanent in player.battlefield
        )
        if (
            not already_on_board
            and not player.can_pay_card(commander, additional_generic=commander_tax)
            and _can_pay_card_with_bonus_mana(
                player,
                commander,
                additional_generic=commander_tax,
            )
        ):
            effective_cost = int(float(commander.get("cmc") or 0)) + commander_tax
            score = max(36, effective_cost * 6)
            candidates.append(
                {
                    "card": commander,
                    "effect_data": get_card_effect(commander),
                    "score": score,
                    "reason": "unlock_commander_cast",
                    "unlock_type": "commander",
                    "cmc": effective_cost,
                }
            )

    for card in player.hand:
        if not isinstance(card, dict) or is_effective_land(card):
            continue
        effect_data = get_card_effect(card)
        effect = effect_data.get("effect", "unknown")
        if effect == "unknown":
            continue
        if player.can_pay_card(card):
            continue
        if not _can_pay_card_with_bonus_mana(player, card):
            continue
        if effect == "board_wipe" and not should_cast_board_wipe(player, opponents):
            continue
        if effect == "draw_cards" and is_wheel_like_card(card, effect_data):
            if not should_cast_wheel(player, opponents, {**effect_data, "name": card.get("name")}):
                continue

        cmc = int(float(card.get("cmc") or 0))
        score = threat_score(effect, card.get("name", "?"), player, all_players, turn)
        reason = "unlock_contextual_spell"
        if effect in ("ramp_permanent", "ramp_engine", "land_ramp", "ramp_ritual"):
            score += 26 if turn <= 4 else 14
            reason = "unlock_ramp_curve_step"
        elif effect in ("remove_creature", "remove_permanent", "counter", "protect_creature", "cannot_lose_turn"):
            score += 22
            reason = "unlock_interaction"
        elif effect in ("creature", "draw_engine", "topdeck_manipulation"):
            score += 18 if cmc <= 4 else 10
            reason = "unlock_board_or_engine_development"
        elif effect in ("finisher", "approach", "token_maker", "board_wipe", "worldfire_reset"):
            score += 24
            reason = "unlock_high_impact_spell"
        else:
            score += max(6, 14 - cmc)

        candidates.append(
            {
                "card": card,
                "effect_data": effect_data,
                "score": score,
                "reason": reason,
                "unlock_type": "spell",
                "cmc": cmc,
            }
        )

    candidates.sort(
        key=lambda item: (
            -int(item.get("score") or 0),
            int(item.get("cmc") or 0),
            item["card"].get("name", ""),
        )
    )
    return candidates


def sacrifice_mana_unlock_candidates(
    player,
    opponents,
    all_players,
    turn,
    *,
    bonus_amount,
    bonus_color="colorless",
):
    candidates = []

    if player.command_zone:
        commander = player.command_zone[0]
        commander_tax = int(player.commander_tax or 0)
        already_on_board = any(
            isinstance(permanent, dict)
            and permanent.get("name") == commander.get("name")
            for permanent in player.battlefield
        )
        if (
            not already_on_board
            and not player.can_pay_card(commander, additional_generic=commander_tax)
            and _can_pay_card_with_bonus_mana(
                player,
                commander,
                bonus_amount=bonus_amount,
                bonus_color=bonus_color,
                additional_generic=commander_tax,
            )
        ):
            effective_cost = int(float(commander.get("cmc") or 0)) + commander_tax
            score = max(40, effective_cost * 6)
            candidates.append(
                {
                    "card": commander,
                    "effect_data": get_card_effect(commander),
                    "score": score,
                    "reason": "unlock_commander_cast",
                    "unlock_type": "commander",
                    "cmc": effective_cost,
                }
            )

    for card in player.hand:
        if not isinstance(card, dict) or is_effective_land(card):
            continue
        effect_data = get_card_effect(card)
        effect = effect_data.get("effect", "unknown")
        if effect == "unknown":
            continue
        if player.can_pay_card(card):
            continue
        if not _can_pay_card_with_bonus_mana(
            player,
            card,
            bonus_amount=bonus_amount,
            bonus_color=bonus_color,
        ):
            continue
        if effect == "board_wipe" and not should_cast_board_wipe(player, opponents):
            continue
        if effect == "draw_cards" and is_wheel_like_card(card, effect_data):
            if not should_cast_wheel(player, opponents, {**effect_data, "name": card.get("name")}):
                continue

        cmc = int(float(card.get("cmc") or 0))
        score = threat_score(effect, card.get("name", "?"), player, all_players, turn)
        reason = "unlock_contextual_spell"
        if effect in ("ramp_permanent", "ramp_engine", "land_ramp", "ramp_ritual"):
            score += 24 if turn <= 4 else 12
            reason = "unlock_ramp_curve_step"
        elif effect in ("remove_creature", "remove_permanent", "counter", "protect_creature", "cannot_lose_turn"):
            score += 20
            reason = "unlock_interaction"
        elif effect in ("creature", "draw_engine", "topdeck_manipulation"):
            score += 16 if cmc <= 4 else 8
            reason = "unlock_board_or_engine_development"
        elif effect in ("finisher", "approach", "token_maker", "board_wipe", "worldfire_reset"):
            score += 26
            reason = "unlock_high_impact_spell"
        else:
            score += max(6, 14 - cmc)

        candidates.append(
            {
                "card": card,
                "effect_data": effect_data,
                "score": score,
                "reason": reason,
                "unlock_type": "spell",
                "cmc": cmc,
            }
        )

    candidates.sort(
        key=lambda item: (
            -int(item.get("score") or 0),
            int(item.get("cmc") or 0),
            item["card"].get("name", ""),
        )
    )
    return candidates


def activate_precombat_utility_mana_lands(
    player,
    opponents,
    all_players,
    turn,
    *,
    phase="precombat_main",
):
    if not player.is_alive():
        return 0

    battlefield_lands = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict) and is_effective_land(permanent)
    ]
    if not battlefield_lands:
        return 0

    ancient_tomb = next(
        (
            permanent
            for permanent in battlefield_lands
            if normalize_card_name(permanent.get("name", "")) == "ancient tomb"
            and not permanent.get("utility_land_used_this_turn")
        ),
        None,
    )
    if ancient_tomb is None:
        return 0

    if player.life <= 8:
        _utility_land_skip_event(
            player,
            ancient_tomb,
            turn,
            "life_too_low_for_ancient_tomb_acceleration",
            phase=phase,
            risk_flags=["low_life"],
        )
        return 0

    candidates = ancient_tomb_unlock_candidates(player, opponents, all_players, turn)
    if not candidates:
        _utility_land_skip_event(
            player,
            ancient_tomb,
            turn,
            "no_contextual_unlock_for_ancient_tomb",
            phase=phase,
        )
        return 0

    chosen = candidates[0]
    change_life(player, -2)
    player.mana_pool.add("colorless", 1)
    ancient_tomb["utility_land_used_this_turn"] = True

    available_options = [
        decision_card_option(
            item["card"],
            item["effect_data"],
            score=item["score"],
            action="unlock_with_ancient_tomb",
            unlock_type=item["unlock_type"],
            reason=item["reason"],
        )
        for item in candidates[:8]
    ]

    emit_decision_trace(
        decision_type="utility_land_activation",
        player=player,
        turn=turn,
        phase=phase,
        available_options=available_options,
        chosen_option=decision_card_option(
            chosen["card"],
            chosen["effect_data"],
            score=chosen["score"],
            action="activate_ancient_tomb",
            unlock_type=chosen["unlock_type"],
            reason=chosen["reason"],
        ),
        rejected_options=[
            decision_card_option(
                item["card"],
                item["effect_data"],
                score=item["score"],
                action="defer_unlock_with_ancient_tomb",
                unlock_type=item["unlock_type"],
                reason=item["reason"],
            )
            for item in candidates[1:8]
        ],
        score_components={
            "life_before": player.life + 2,
            "mana_before": player.available_mana() - 1,
            "mana_after": player.available_mana(),
            "candidate_count": len(candidates),
            "chosen_unlock_reason": chosen["reason"],
        },
        rule_source="utility_land_activation_v1",
        rule_status="verified",
        confidence="medium",
        expected_benefit_score=chosen["score"],
        actual_outcome="contextual_fast_mana_enabled",
        reason="pay_life_only_when_ancient_tomb_unlocks_relevant_action",
        strategic_principle="convert_life_into_mana_only_for_material_unlock",
        heuristic_version=DECISION_STRATEGY_VERSION,
        resource_delta={
            "life": -2,
            "mana": 1,
            "unlock_target": chosen["card"].get("name", "?"),
            "unlock_type": chosen["unlock_type"],
        },
        risk_flags=["life_payment", "fast_mana_land"],
        rejected_reason="lower_contextual_unlock_score",
    )
    emit_replay_event(
        "utility_land_activated",
        player=player.name,
        card=ancient_tomb.get("name", "?"),
        activation_kind="contextual_fast_mana",
        life_paid=2,
        bonus_mana=1,
        unlock_target=chosen["card"].get("name", "?"),
        unlock_reason=chosen["reason"],
        mana_after=player.available_mana(),
        life_after=player.life,
        phase=phase,
        turn=turn,
    )
    return 1


def _utility_land_skip_event(player, permanent, turn, reason, *, phase, risk_flags=None):
    emit_replay_event(
        "activated_ability_skipped",
        player=player.name,
        card=permanent.get("name", "?"),
        reason="strategic_guardrail",
        strategic_guardrail_reason=reason,
        strategic_risk_flags=list(risk_flags or []),
        phase=phase,
        turn=turn,
    )


def _utility_artifact_skip_event(player, permanent, turn, reason, *, phase, risk_flags=None):
    emit_replay_event(
        "activated_ability_skipped",
        player=player.name,
        card=permanent.get("name", "?"),
        reason="strategic_guardrail",
        strategic_guardrail_reason=reason,
        strategic_risk_flags=list(risk_flags or []),
        phase=phase,
        turn=turn,
    )


def _sacrifice_damage_skip_event(player, permanent, turn, reason, *, phase, risk_flags=None):
    emit_replay_event(
        "activated_ability_skipped",
        player=player.name,
        card=permanent.get("name", "?"),
        reason="strategic_guardrail",
        strategic_guardrail_reason=reason,
        strategic_risk_flags=list(risk_flags or []),
        activation_kind="sacrifice_creature_damage",
        phase=phase,
        turn=turn,
    )


def _is_expendable_sacrifice_creature(creature):
    if not isinstance(creature, dict) or not is_battlefield_creature(creature):
        return False
    if creature.get("is_commander"):
        return False
    if creature.get("is_mana_source"):
        return False
    return True


def _sacrifice_damage_creature_score(creature):
    type_line = str(creature.get("type_line") or "").lower()
    is_token = bool(creature.get("is_token")) or creature.get("tag") == "token" or "token" in type_line
    power = int(float(creature.get("power") or 0))
    toughness = int(float(creature.get("toughness") or 0))
    cmc = int(float(creature.get("cmc") or 0))
    score = 20
    if is_token:
        score += 18
    score -= power * 3 + toughness * 2 + cmc * 2
    if creature.get("summoning_sick"):
        score += 3
    return score


def activate_sacrifice_damage_outlets(player, opponents, all_players, turn, rng, *, phase="precombat_main"):
    """Activate simple sacrifice outlets that convert an expendable creature into damage.

    This is intentionally narrow: it models permanents such as Goblin
    Bombardment only when the rule explicitly marks a sacrifice-creature damage
    outlet. It does not make all activated abilities executable.
    """
    if not player.is_alive():
        return 0
    outlets = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and not permanent.get("utility_activation_used_this_turn")
        and (
            permanent.get("activated_sacrifice_creature_damage")
            or permanent.get("sacrifice_creature_damage")
            or permanent.get("effect") == "sacrifice_damage_outlet"
        )
    ]
    if not outlets:
        return 0
    targets = [opponent for opponent in opponents if opponent.is_alive()]
    if not targets:
        return 0

    for outlet in outlets:
        creatures = [
            creature
            for creature in player.battlefield
            if creature is not outlet and _is_expendable_sacrifice_creature(creature)
        ]
        if not creatures:
            _sacrifice_damage_skip_event(
                player,
                outlet,
                turn,
                "no_expendable_creature_to_sacrifice",
                phase=phase,
            )
            continue

        scored_creatures = sorted(
            (
                {
                    "creature": creature,
                    "score": _sacrifice_damage_creature_score(creature),
                }
                for creature in creatures
            ),
            key=lambda item: item["score"],
            reverse=True,
        )
        chosen_creature = scored_creatures[0]["creature"]
        if scored_creatures[0]["score"] < 18:
            _sacrifice_damage_skip_event(
                player,
                outlet,
                turn,
                "creature_cost_too_high_for_one_damage",
                phase=phase,
                risk_flags=["high_board_value_creature"],
            )
            continue

        target = min(targets, key=lambda opponent: opponent.life)
        damage = int(outlet.get("damage") or outlet.get("activation_damage") or 1)
        if chosen_creature in player.battlefield:
            player.battlefield.remove(chosen_creature)
        type_line = str(chosen_creature.get("type_line") or "").lower()
        is_token = (
            bool(chosen_creature.get("is_token"))
            or chosen_creature.get("tag") == "token"
            or "token" in type_line
        )
        if is_token:
            emit_replay_event(
                "token_ceased_to_exist",
                player=player.name,
                token=chosen_creature.get("name", "?"),
                from_zone="battlefield",
                turn=turn,
            )
        else:
            player.graveyard.append(chosen_creature)
        deal_damage(target, damage)
        outlet["utility_activation_used_this_turn"] = True

        available_options = [
            decision_card_option(
                item["creature"],
                action="sacrifice_for_damage",
                effect="sacrifice_damage_outlet",
                score=item["score"],
                target=target.name,
            )
            for item in scored_creatures[:8]
        ]
        emit_decision_trace(
            decision_type="activated_sacrifice_damage",
            player=player,
            turn=turn,
            phase=phase,
            available_options=available_options,
            chosen_option=available_options[0],
            rejected_options=available_options[1:],
            score_components={
                "damage": damage,
                "target": target.name,
                "target_life_after": target.life,
                "creature_options": len(scored_creatures),
            },
            rule_source=outlet.get("_rule_source", "focused_battle_rule_evidence"),
            rule_status=outlet.get("_rule_review_status", "needs_review"),
            confidence="medium",
            expected_benefit_score=available_options[0].get("score", 0),
            actual_outcome="creature_sacrificed_damage_dealt",
            reason="sacrifice_low_value_creature_for_relevant_damage",
            strategic_principle="convert_expendable_creature_into_reach_or_interaction",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta={
                "creatures": -1,
                "damage": damage,
                "target": target.name,
            },
            risk_flags=["sacrifice_creature"],
            rejected_reason="lower_sacrifice_value_score",
        )
        emit_replay_event(
            "activated_ability",
            player=player.name,
            card=outlet.get("name", "?"),
            activation_kind="sacrifice_creature_damage",
            sacrificed=chosen_creature.get("name", "?"),
            target=target.name,
            damage_dealt=damage,
            target_life_after=target.life,
            phase=phase,
            turn=turn,
            **replay_rule_fields(outlet),
        )
        check_sbas_until_stable(all_players)
        return 1
    return 0


def _has_attack_artifact_tutor_trigger(permanent):
    return bool(
        isinstance(permanent, dict)
        and (
            permanent.get("artifact_attack_tutor")
            or permanent.get("attack_artifact_tutor")
            or permanent.get("effect") == "attack_artifact_tutor"
        )
    )


def _artifact_search_candidates(player, target_cmc, opponents, turn, *, cmc_match="max"):
    candidates = []
    for candidate in list(player.library):
        if not isinstance(candidate, dict) or not is_artifact_permanent(candidate):
            continue
        try:
            cmc = int(float(candidate.get("cmc") or 0))
        except (TypeError, ValueError):
            cmc = 0
        if cmc_match == "exact":
            if cmc != target_cmc:
                continue
        elif cmc > target_cmc:
            continue
        score, reason = tutor_candidate_score(
            candidate,
            "artifact_to_battlefield",
            player,
            opponents,
            turn,
        )
        candidates.append(
            {
                "card": candidate,
                "score": score,
                "reason": reason,
                "cmc": cmc,
            }
        )
    candidates.sort(
        key=lambda item: (
            -item["score"],
            -item["cmc"],
            str(item["card"].get("name", "")),
        )
    )
    return candidates


def _attack_artifact_sacrifice_options(player, source, opponents, turn):
    options = []
    oracle_text = str(source.get("oracle_text") or "").lower()
    exact_plus_one = bool(
        source.get("artifact_tutor_cmc_mode") == "sacrificed_mana_value_plus"
        or "mana value equal to 1 plus the sacrificed artifact" in oracle_text
    )
    requires_noncreature = bool(
        source.get("artifact_tutor_sacrifice_noncreature")
        or "sacrifice a noncreature artifact" in oracle_text
    )
    enters_tapped = bool(
        source.get("artifact_tutor_enters_tapped")
        or "onto the battlefield tapped" in oracle_text
    )
    current_artifacts = controlled_artifact_count_for_search(player)
    if int(getattr(player, "treasures", 0) or 0) > 0:
        treasure_cmc = 0
        target_cmc = treasure_cmc + 1 if exact_plus_one else max(0, current_artifacts - 1)
        candidates = _artifact_search_candidates(
            player,
            target_cmc,
            opponents,
            turn,
            cmc_match="exact" if exact_plus_one else "max",
        )
        if candidates:
            options.append(
                {
                    "kind": "treasure",
                    "name": "Treasure token",
                    "permanent": None,
                    "score": 120 + candidates[0]["score"],
                    "target": candidates[0],
                    "target_cmc": target_cmc,
                    "cmc_match": "exact" if exact_plus_one else "max",
                    "enters_tapped": enters_tapped,
                    "reason": "sacrifice_expendable_treasure_for_artifact_tutor",
                }
            )

    for permanent in player.battlefield:
        if permanent is source or not isinstance(permanent, dict):
            continue
        if permanent.get("is_commander") or not is_artifact_permanent(permanent):
            continue
        try:
            cmc = int(float(permanent.get("cmc") or 0))
        except (TypeError, ValueError):
            cmc = 0
        type_line = str(permanent.get("type_line") or "").lower()
        if requires_noncreature and "creature" in type_line:
            continue
        target_cmc = cmc + 1 if exact_plus_one else max(0, current_artifacts - 1)
        candidates = _artifact_search_candidates(
            player,
            target_cmc,
            opponents,
            turn,
            cmc_match="exact" if exact_plus_one else "max",
        )
        if not candidates:
            continue
        is_token = bool(permanent.get("is_token")) or permanent.get("tag") == "token" or "token" in type_line
        permanent_score = 45
        if is_token:
            permanent_score += 25
        permanent_score -= cmc * 5
        if permanent.get("mana_produced") or permanent.get("effect") == "ramp_permanent":
            permanent_score -= 18
        if permanent_score < 20:
            continue
        options.append(
            {
                "kind": "permanent",
                "name": permanent.get("name", "?"),
                "permanent": permanent,
                "score": permanent_score + candidates[0]["score"],
                "target": candidates[0],
                "target_cmc": target_cmc,
                "cmc_match": "exact" if exact_plus_one else "max",
                "enters_tapped": enters_tapped,
                "reason": "sacrifice_low_value_artifact_for_artifact_tutor",
            }
        )

    options.sort(key=lambda item: (-item["score"], str(item["name"])))
    return options


def resolve_attack_artifact_tutor_trigger(player, source, opponents, all_players, turn, *, phase="combat"):
    """Resolve a narrow needs_review attack trigger: create Treasure, optionally artifact-tutor."""
    if not _has_attack_artifact_tutor_trigger(source) or source not in player.battlefield:
        return None

    player.treasures += 1
    options = _attack_artifact_sacrifice_options(player, source, opponents, turn)
    if not options:
        emit_decision_trace(
            decision_type="attack_trigger_artifact_tutor",
            player=player,
            turn=turn,
            phase=phase,
            available_options=[
                {
                    "action": "keep_treasure",
                    "card": source.get("name", "?"),
                    "score": 25,
                    "reason": "no_valid_artifact_tutor_target_after_optional_sacrifice",
                }
            ],
            chosen_option={
                "action": "keep_treasure",
                "card": source.get("name", "?"),
                "score": 25,
                "reason": "no_valid_artifact_tutor_target_after_optional_sacrifice",
            },
            rejected_options=[],
            score_components={
                "treasures_created": 1,
                "artifact_count_after_treasure": controlled_artifact_count_for_search(player),
                "candidate_count": 0,
            },
            rule_source=source.get("_rule_source", "focused_battle_rule_evidence"),
            rule_status=source.get("_rule_review_status", "needs_review"),
            confidence="low",
            expected_benefit_score=25,
            actual_outcome="treasure_created_no_artifact_tutor",
            reason="no_valid_artifact_tutor_target",
            strategic_principle="attack_triggers_should_convert_expendable_artifacts_only_when_payoff_exists",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta={"treasures": 1},
            risk_flags=["needs_review_attack_trigger", "no_tutor_target"],
        )
        emit_replay_event(
            "trigger_resolved",
            player=player.name,
            card=source.get("name", "?"),
            trigger="attack",
            activation_kind="artifact_attack_tutor",
            treasures_created=1,
            artifact_sacrificed=None,
            found=None,
            destination=None,
            phase=phase,
            turn=turn,
            **replay_rule_fields(source),
        )
        return {"treasures_created": 1, "artifact_sacrificed": None, "found": None}

    chosen = options[0]
    target = chosen["target"]["card"]
    if chosen["kind"] == "treasure":
        player.treasures = max(0, player.treasures - 1)
        sacrificed_name = "Treasure token"
    else:
        sacrificed = chosen["permanent"]
        sacrificed_name = sacrificed.get("name", "?")
        if sacrificed in player.battlefield:
            player.battlefield.remove(sacrificed)
        type_line = str(sacrificed.get("type_line") or "").lower()
        is_token = bool(sacrificed.get("is_token")) or sacrificed.get("tag") == "token" or "token" in type_line
        if is_token:
            emit_replay_event(
                "token_ceased_to_exist",
                player=player.name,
                token=sacrificed_name,
                from_zone="battlefield",
                turn=turn,
            )
        else:
            player.graveyard.append(sacrificed)

    player.library.remove(target)
    permanent_effect = get_card_effect(target)
    permanent = prepare_entering_permanent(enrich_card({**target, **permanent_effect}))
    if chosen.get("enters_tapped"):
        permanent["tapped"] = True
    player.battlefield.append(permanent)

    available_options = [
        {
            "action": "sacrifice_artifact_for_tutor",
            "card": option["name"],
            "target": option["target"]["card"].get("name", "?"),
            "score": option["score"],
            "target_cmc": option["target_cmc"],
            "cmc_match": option["cmc_match"],
            "reason": option["reason"],
        }
        for option in options[:8]
    ]
    emit_decision_trace(
        decision_type="attack_trigger_artifact_tutor",
        player=player,
        turn=turn,
        phase=phase,
        available_options=available_options,
        chosen_option=available_options[0],
        rejected_options=available_options[1:],
        score_components={
            "treasures_created": 1,
            "artifact_count_after_sacrifice": controlled_artifact_count_for_search(player),
            "candidate_count": len(
                _artifact_search_candidates(
                    player,
                    chosen["target_cmc"],
                    opponents,
                    turn,
                    cmc_match=chosen["cmc_match"],
                )
            ) + 1,
            "selected_target_reason": chosen["target"]["reason"],
        },
        rule_source=source.get("_rule_source", "focused_battle_rule_evidence"),
        rule_status=source.get("_rule_review_status", "needs_review"),
        confidence="medium",
        expected_benefit_score=chosen["score"],
        actual_outcome="artifact_sacrificed_artifact_tutored_to_battlefield",
        reason=chosen["reason"],
        strategic_principle="attack_triggers_should_convert_expendable_artifacts_only_when_payoff_exists",
        heuristic_version=DECISION_STRATEGY_VERSION,
        resource_delta={
            "treasures": 0 if chosen["kind"] == "treasure" else 1,
            "artifact_sacrificed": sacrificed_name,
            "found": target.get("name", "?"),
            "destination": "battlefield",
        },
        risk_flags=["needs_review_attack_trigger", "sacrifice_artifact", "library_search"],
        rejected_reason="lower_artifact_tutor_value_score",
    )
    emit_replay_event(
        "trigger_resolved",
        player=player.name,
        card=source.get("name", "?"),
        trigger="attack",
        activation_kind="artifact_attack_tutor",
        treasures_created=1,
        artifact_sacrificed=sacrificed_name,
        found=target.get("name", "?"),
        destination="battlefield",
        target_cmc=chosen["target_cmc"],
        cmc_match=chosen["cmc_match"],
        enters_tapped=bool(chosen.get("enters_tapped")),
        phase=phase,
        turn=turn,
        **replay_rule_fields(source),
    )
    check_sbas_until_stable(all_players)
    return {
        "treasures_created": 1,
        "artifact_sacrificed": sacrificed_name,
        "found": target.get("name", "?"),
    }


def creature_sacrifice_has_strategic_benefit(player, creature, chosen_unlock):
    if not isinstance(creature, dict) or chosen_unlock is None:
        return False, ["missing_context"], "missing_context"
    risk_flags = []
    if creature.get("is_commander"):
        risk_flags.append("sacrificing_commander")
    if creature.get("is_mana_source"):
        risk_flags.append("sacrificing_mana_creature")
    power = int(float(creature.get("power") or 0))
    toughness = int(float(creature.get("toughness") or 0))
    cmc = int(float(creature.get("cmc") or 0))
    type_line = str(creature.get("type_line") or "").lower()
    is_token = creature.get("tag") == "token" or "token" in type_line
    remaining_creatures = max(
        0,
        len(
            [
                permanent
                for permanent in player.battlefield
                if is_battlefield_creature(permanent)
            ]
        ) - 1,
    )
    if remaining_creatures <= 0:
        risk_flags.append("empty_board_after_sacrifice")
    if power >= 4 or toughness >= 4 or cmc >= 5:
        risk_flags.append("high_board_value_creature")

    creature_value = power * 4 + toughness * 3 + cmc * 2
    if creature.get("is_commander"):
        creature_value += 24
    if creature.get("is_mana_source"):
        creature_value += 8
    if is_token:
        creature_value = max(0, creature_value - 14)
    unlock_score = int(chosen_unlock.get("score") or 0)
    unlock_reason = str(chosen_unlock.get("reason") or "")

    if "sacrificing_commander" in risk_flags:
        return False, risk_flags, "commander_sacrifice_not_allowed_for_generic_unlock"
    if unlock_reason in {"unlock_high_impact_spell", "unlock_commander_cast"} and unlock_score >= max(18, creature_value):
        return True, risk_flags, "high_impact_unlock_outweighs_creature_cost"
    if unlock_score >= creature_value + 12:
        return True, risk_flags, "unlock_score_outweighs_creature_cost"
    return False, risk_flags, "creature_cost_outweighs_unlock"


def _capture_player_resource_state(player):
    return (
        player.mana_pool.snapshot(),
        copy.deepcopy(player.restricted_mana),
        player.treasures,
        player.life,
    )


def _restore_player_resource_state(player, snapshot):
    pool_snapshot, restricted_snapshot, treasures_snapshot, life_snapshot = snapshot
    for color, amount in pool_snapshot.items():
        setattr(player.mana_pool, color, amount)
    player.restricted_mana = restricted_snapshot
    player.treasures = treasures_snapshot
    player.life = life_snapshot


def _cantrip_filter_candidate_score(card, effect_data, player, turn):
    effect_name = str(effect_data.get("effect") or card.get("effect") or "unknown")
    score = threat_score(effect_name, card.get("name", ""), player, [player], turn)
    if effect_name in HIGH_IMPACT_PAYOFF_EFFECTS:
        score += 18
    elif effect_name in ("draw_cards", "draw_engine", "hand_filter", "cantrip_mana_filter_artifact"):
        score += 10
    elif effect_name in ("ramp_permanent", "ramp_engine", "land_ramp", "ramp_ritual"):
        score += 6
    score += min(6, int(float(card.get("cmc") or 0)))
    return max(score, 8)


def activate_sacrifice_mana_artifacts(
    player,
    opponents,
    all_players,
    turn,
    *,
    phase="precombat_main",
):
    if not player.is_alive() or phase not in MAIN_PHASES:
        return 0

    utility_artifacts = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("activated_mana_ability")
        and permanent.get("activation_cost") == "sacrifice_creature"
        and not permanent.get("utility_artifact_used_this_turn")
    ]
    if not utility_artifacts:
        return 0

    for permanent in utility_artifacts:
        bonus_amount = int(permanent.get("mana_produced") or 0)
        bonus_colors = source_colors(permanent)
        bonus_color = bonus_colors[0] if len(bonus_colors) == 1 else "colorless"
        if bonus_amount <= 0:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "no_bonus_mana_to_generate",
                phase=phase,
            )
            continue

        candidates = sacrifice_mana_unlock_candidates(
            player,
            opponents,
            all_players,
            turn,
            bonus_amount=bonus_amount,
            bonus_color=bonus_color,
        )
        if not candidates:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "no_contextual_unlock_for_sacrifice_mana_artifact",
                phase=phase,
            )
            continue

        creature, creature_options, selection_reason = choose_creature_for_resource_cost(player)
        if creature is None:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "no_creature_available_to_pay_activation_cost",
                phase=phase,
            )
            continue
        chosen = candidates[0]
        allowed, risk_flags, benefit_reason = creature_sacrifice_has_strategic_benefit(
            player,
            creature,
            chosen,
        )
        if not allowed:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                benefit_reason,
                phase=phase,
                risk_flags=risk_flags,
            )
            continue

        destination = move_creature_from_battlefield(player, creature)
        player.mana_pool.add(bonus_color, bonus_amount)
        permanent["utility_artifact_used_this_turn"] = True

        emit_decision_trace(
            decision_type="utility_artifact_activation",
            player=player,
            turn=turn,
            phase=phase,
            available_options=[
                decision_card_option(
                    option["card"],
                    option["effect_data"],
                    score=option["score"],
                    action="activate_sacrifice_mana_artifact",
                    unlock_reason=option["reason"],
                    unlock_type=option["unlock_type"],
                    produced_mana=bonus_amount,
                )
                for option in candidates[:8]
            ],
            chosen_option=decision_card_option(
                chosen["card"],
                chosen["effect_data"],
                score=chosen["score"],
                action="activate_sacrifice_mana_artifact",
                unlock_reason=chosen["reason"],
                unlock_type=chosen["unlock_type"],
                produced_mana=bonus_amount,
            ),
            rejected_options=[
                decision_card_option(
                    option["card"],
                    option["effect_data"],
                    score=option["score"],
                    action="defer_sacrifice_mana_artifact",
                    unlock_reason=option["reason"],
                    unlock_type=option["unlock_type"],
                    produced_mana=bonus_amount,
                )
                for option in candidates[1:8]
            ],
            score_components={
                "activation_cost": "sacrifice_creature",
                "sacrificed_creature": creature.get("name", "?"),
                "creature_selection_reason": selection_reason,
                "produced_mana": bonus_amount,
                "unlock_target": chosen["card"].get("name", "?"),
                "unlock_type": chosen["unlock_type"],
            },
            rule_source="utility_artifact_activation_v1",
            rule_status=permanent.get("_rule_review_status", "active"),
            confidence="medium",
            expected_benefit_score=chosen["score"],
            actual_outcome="creature_sacrificed_for_contextual_mana_unlock",
            reason="convert_low_value_creature_into_mana_only_when_unlock_is_real",
            strategic_principle="spend_creature_resource_only_for_material_unlock",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta={
                "creatures": -1,
                "mana": bonus_amount,
                "graveyard": 1,
                "unlock_target": chosen["card"].get("name", "?"),
                "unlock_type": chosen["unlock_type"],
                "destination": destination,
            },
            risk_flags=["sacrifice_creature", *risk_flags],
            rejected_reason="lower_contextual_unlock_score",
        )
        emit_replay_event(
            "utility_artifact_activated",
            player=player.name,
            card=permanent.get("name", "?"),
            activation_kind="sacrifice_creature_for_mana_unlock",
            sacrificed=creature.get("name", "?"),
            destination=destination,
            unlock_target=chosen["card"].get("name", "?"),
            unlock_type=chosen["unlock_type"],
            unlock_reason=chosen["reason"],
            mana_added=bonus_amount,
            mana_color=bonus_color,
            available_mana_after=player.available_mana(),
            creature_options=creature_options,
            selection_reason=selection_reason,
            strategic_risk_flags=risk_flags,
            strategic_benefit_reason=benefit_reason,
            phase=phase,
            turn=turn,
        )
        return 1

    return 0


def cantrip_mana_filter_unlock_options(player, permanent, turn, *, phase="precombat_main"):
    if phase != "precombat_main":
        return []
    activation_cost = int(permanent.get("activation_cost_generic") or 1)
    activation_colors = list(permanent.get("activation_add_colors") or [])
    if activation_cost <= 0 or not activation_colors:
        return []
    activation_cost_text = "{%d}" % activation_cost
    if not player.can_pay(activation_cost_text):
        return []

    options = []

    def maybe_add_option(card, effect_data, *, role, additional_generic=0, reason):
        if card is None:
            return
        if not can_cast_in_phase(card, effect_data, phase):
            return
        if player.can_pay_card(card, additional_generic):
            return
        chosen_color = None
        for color in activation_colors:
            snapshot = _capture_player_resource_state(player)
            try:
                if not player.spend_mana(activation_cost_text):
                    continue
                player.mana_pool.add(color, 1)
                if player.can_pay_card(card, additional_generic):
                    chosen_color = color
                    break
            finally:
                _restore_player_resource_state(player, snapshot)
        if chosen_color is None:
            return
        score = _cantrip_filter_candidate_score(card, effect_data, player, turn)
        if role == "commander":
            score += 12
        options.append(
            {
                "card": card,
                "effect_data": effect_data,
                "score": score,
                "color": chosen_color,
                "role": role,
                "reason": reason,
                "additional_generic": additional_generic,
            }
        )

    if player.command_zone:
        commander = player.command_zone[0]
        commander_present = any(
            isinstance(permanent_card, dict)
            and permanent_card.get("name") == commander.get("name")
            for permanent_card in player.battlefield
        )
        if not commander_present:
            commander_effect = get_card_effect(commander)
            maybe_add_option(
                commander,
                commander_effect,
                role="commander",
                additional_generic=player.commander_tax,
                reason="fix_color_for_commander_cast",
            )

    for card in player.hand:
        if not isinstance(card, dict) or is_effective_land(card):
            continue
        effect_data = get_card_effect(card)
        effect_name = str(effect_data.get("effect") or card.get("effect") or "unknown")
        if effect_name in ("unknown", "counter"):
            continue
        maybe_add_option(
            card,
            effect_data,
            role="hand_spell",
            reason="fix_color_for_contextual_spell",
        )

    options.sort(
        key=lambda item: (
            -item["score"],
            0 if item["role"] == "commander" else 1,
            int(float(item["card"].get("cmc") or 0)),
            item["card"].get("name", ""),
        )
    )
    return options


def activate_utility_artifacts(player, opponents, all_players, turn, rng, *, phase="postcombat_main"):
    if not player.is_alive():
        return 0

    utility_artifacts = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("effect") == "cantrip_mana_filter_artifact"
        and not permanent.get("utility_artifact_used_this_turn")
    ]

    hand_size = len(player.hand)
    preferred_order = ["chromatic star"]
    permanents_by_name = {
        normalize_card_name(permanent.get("name", "")): permanent
        for permanent in utility_artifacts
    }

    for normalized_name in preferred_order:
        permanent = permanents_by_name.get(normalized_name)
        if permanent is None:
            continue
        activation_cost = int(permanent.get("activation_cost_generic") or 1)
        activation_cost_text = "{%d}" % activation_cost
        draw_count = int(permanent.get("draw_on_self_sacrifice") or 1)

        if phase == "precombat_main":
            unlock_options = cantrip_mana_filter_unlock_options(
                player,
                permanent,
                turn,
                phase=phase,
            )
            if not unlock_options:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_contextual_unlock_for_cantrip_filter_artifact",
                    phase=phase,
                )
                continue
            chosen = unlock_options[0]
            if not player.spend_mana(activation_cost_text):
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_activation_cost",
                    phase=phase,
                )
                continue
            if permanent in player.battlefield:
                player.battlefield.remove(permanent)
            player.graveyard.append(permanent)
            player.mana_pool.add(chosen["color"], 1)
            drawn = player.draw(draw_count, rng)
            emit_decision_trace(
                decision_type="utility_artifact_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        option["card"],
                        option["effect_data"],
                        score=option["score"],
                        action="activate_filter_draw",
                        chosen_color=option["color"],
                        unlock_reason=option["reason"],
                        unlock_role=option["role"],
                    )
                    for option in unlock_options[:8]
                ],
                chosen_option=decision_card_option(
                    chosen["card"],
                    chosen["effect_data"],
                    score=chosen["score"],
                    action="activate_filter_draw",
                    chosen_color=chosen["color"],
                    unlock_reason=chosen["reason"],
                    unlock_role=chosen["role"],
                ),
                rejected_options=[
                    decision_card_option(
                        option["card"],
                        option["effect_data"],
                        score=option["score"],
                        action="defer_filter_draw",
                        chosen_color=option["color"],
                        unlock_reason=option["reason"],
                        unlock_role=option["role"],
                    )
                    for option in unlock_options[1:8]
                ],
                score_components={
                    "activation_cost_generic": activation_cost,
                    "cards_drawn": draw_count,
                    "unlock_target": chosen["card"].get("name", "?"),
                    "unlock_role": chosen["role"],
                },
                rule_source="utility_artifact_activation_v1",
                rule_status=permanent.get("_rule_review_status", "active"),
                confidence="medium",
                expected_benefit_score=chosen["score"],
                reason="cash_in_color_filter_cantrip_for_contextual_unlock",
                strategic_principle="convert_low_impact_artifact_into_color_fix_and_card_flow",
                heuristic_version=DECISION_STRATEGY_VERSION,
                resource_delta={
                    "cards": len(drawn),
                    "mana": 0,
                    "artifacts": -1,
                    "graveyard": 1,
                    "chosen_color": chosen["color"],
                    "unlock_target": chosen["card"].get("name", "?"),
                },
                risk_flags=["sacrifice_artifact", "temporary_color_fix"],
                rejected_reason="lower_contextual_unlock_score",
            )
            emit_replay_event(
                "utility_artifact_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="filter_draw_unlock",
                chosen_color=chosen["color"],
                unlock_target=chosen["card"].get("name", "?"),
                unlock_role=chosen["role"],
                mana_paid=activation_cost,
                cards_drawn=len(drawn),
                hand_before=hand_size,
                hand_after=len(player.hand),
                phase=phase,
                turn=turn,
            )
            return 1

        if phase == "postcombat_main":
            if hand_size > 2:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "hand_not_low_enough_for_cantrip_filter_cash_in",
                    phase=phase,
                )
                continue
            if player.available_mana() < activation_cost:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_cantrip_filter_cash_in",
                    phase=phase,
                )
                continue
            if not player.spend_mana(activation_cost_text):
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_activation_cost",
                    phase=phase,
                )
                continue
            if permanent in player.battlefield:
                player.battlefield.remove(permanent)
            player.graveyard.append(permanent)
            drawn = player.draw(draw_count, rng)
            emit_decision_trace(
                decision_type="utility_artifact_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        permanent,
                        action="cash_in_for_draw",
                        effect="cantrip_mana_filter_artifact",
                        score=26,
                    )
                ],
                chosen_option=decision_card_option(
                    permanent,
                    action="cash_in_for_draw",
                    effect="cantrip_mana_filter_artifact",
                    score=26,
                ),
                score_components={
                    "activation_cost_generic": activation_cost,
                    "cards_drawn": draw_count,
                    "hand_before": hand_size,
                    "hand_after": len(player.hand),
                },
                rule_source="utility_artifact_activation_v1",
                rule_status=permanent.get("_rule_review_status", "active"),
                confidence="medium",
                expected_benefit_score=26,
                reason="convert_idle_cantrip_artifact_into_refill",
                strategic_principle="cash_in_low_board_impact_artifact_when_hand_is_low",
                heuristic_version=DECISION_STRATEGY_VERSION,
                resource_delta={
                    "cards": len(drawn),
                    "mana": -activation_cost,
                    "artifacts": -1,
                    "graveyard": 1,
                },
                risk_flags=["sacrifice_artifact"],
            )
            emit_replay_event(
                "utility_artifact_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="cash_in_draw",
                mana_paid=activation_cost,
                cards_drawn=len(drawn),
                hand_before=hand_size,
                hand_after=len(player.hand),
                phase=phase,
                turn=turn,
            )
            return 1

    self_sacrifice_draw_artifacts = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("effect") != "cantrip_mana_filter_artifact"
        and (
            permanent.get("activated_self_sacrifice_draw")
            or permanent.get("activated_draw_on_self_sacrifice")
        )
        and not permanent.get("utility_artifact_used_this_turn")
    ]
    if phase != "postcombat_main" or not self_sacrifice_draw_artifacts:
        return 0

    for permanent in self_sacrifice_draw_artifacts:
        activation_cost = int(permanent.get("activation_cost_generic") or 1)
        if permanent.get("activation_requires_tap") and permanent.get("tapped"):
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "artifact_already_tapped_for_self_sacrifice_draw",
                phase=phase,
            )
            continue
        if not player.library:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "no_library_for_self_sacrifice_draw_artifact",
                phase=phase,
            )
            continue
        if hand_size > 2:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "hand_not_low_enough_for_self_sacrifice_draw_artifact",
                phase=phase,
            )
            continue
        if player.available_mana() < activation_cost:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "insufficient_mana_for_self_sacrifice_draw_artifact",
                phase=phase,
            )
            continue
        if not player.spend_mana("{%d}" % activation_cost):
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "failed_to_pay_activation_cost",
                phase=phase,
            )
            continue
        if permanent.get("activation_requires_tap"):
            permanent["tapped"] = True
        permanent["utility_artifact_used_this_turn"] = True
        if permanent in player.battlefield:
            player.battlefield.remove(permanent)
        player.graveyard.append(permanent)
        drawn = player.draw(1, rng)
        emit_decision_trace(
            decision_type="utility_artifact_activation",
            player=player,
            turn=turn,
            phase=phase,
            available_options=[
                decision_card_option(
                    permanent,
                    action="cash_in_for_draw",
                    effect=permanent.get("effect", "artifact"),
                    score=24,
                )
            ],
            chosen_option=decision_card_option(
                permanent,
                action="cash_in_for_draw",
                effect=permanent.get("effect", "artifact"),
                score=24,
            ),
            score_components={
                "activation_cost_generic": activation_cost,
                "cards_drawn": len(drawn),
                "hand_before": hand_size,
                "hand_after": len(player.hand),
            },
            rule_source="utility_artifact_activation_v1",
            rule_status=permanent.get("_rule_review_status", "active"),
            confidence="medium",
            expected_benefit_score=24,
            reason="cash_in_low_impact_artifact_for_card_when_hand_is_low",
            strategic_principle="convert_low_board_impact_artifact_into_refill_after_main_actions",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta={
                "cards": len(drawn),
                "mana": -activation_cost,
                "artifacts": -1,
                "graveyard": 1,
            },
            risk_flags=["sacrifice_artifact"],
        )
        emit_replay_event(
            "utility_artifact_activated",
            player=player.name,
            card=permanent.get("name", "?"),
            activation_kind="self_sacrifice_draw",
            mana_paid=activation_cost,
            cards_drawn=len(drawn),
            hand_before=hand_size,
            hand_after=len(player.hand),
            phase=phase,
            turn=turn,
        )
        return 1

    return 0


def _player_permanents_with_flag(player, flag):
    return [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict) and permanent.get(flag)
    ]


def _player_has_named_permanent(player, expected_name):
    normalized_expected = normalize_card_name(expected_name)
    for permanent in player.battlefield:
        if not isinstance(permanent, dict):
            continue
        if normalize_card_name(permanent.get("name", "")) == normalized_expected:
            return True
    return False


def player_has_no_maximum_hand_size(player):
    return bool(_player_permanents_with_flag(player, "no_max_hand_size"))


def player_has_discard_to_top_replacement(player):
    return bool(_player_permanents_with_flag(player, "discard_effect_to_top_replacement"))


def discard_replacement_priority(card, player):
    if not isinstance(card, dict):
        return -999
    if player_has_lorehold_miracle_engine(player):
        return lorehold_draw_priority(card, player)
    effect_data = get_card_effect(card)
    effect = str(effect_data.get("effect") or card.get("effect") or "unknown")
    cmc = int(_opening_hand_card_cmc(card) or 0)
    is_land_card = is_effective_land(card)
    if effect in {
        "counter",
        "remove_creature",
        "remove_permanent",
        "board_wipe",
        "protection",
        "phase_out",
        "tutor",
    }:
        return 140 + min(cmc, 6) * 3
    if effect in {"draw_cards", "draw_engine", "hand_filter", "cantrip_mana_filter_artifact"}:
        return 118 + min(cmc, 6) * 2
    if effect in {"ramp_permanent", "land_ramp", "ramp_ritual"}:
        return 108 + min(cmc, 5) * 2
    if is_instant_or_sorcery_spell(card):
        return 92 + min(cmc, 7) * 2
    if is_land_card:
        if controlled_land_count(player) <= 3:
            return 88
        return 18
    if effect == "finisher":
        return 72 + min(cmc, 8)
    if cmc >= 6:
        return 44
    return 58


def resolve_effect_discard_cards(player, discarded_cards, *, top_limit=None):
    cards = [card for card in discarded_cards if isinstance(card, dict)]
    if not cards:
        return {
            "to_top": [],
            "to_graveyard": [],
            "used_replacement": False,
        }

    if not player_has_discard_to_top_replacement(player):
        player.graveyard.extend(cards)
        return {
            "to_top": [],
            "to_graveyard": cards,
            "used_replacement": False,
        }

    scored_cards = sorted(
        cards,
        key=lambda card: (
            -discard_replacement_priority(card, player),
            -int(_opening_hand_card_cmc(card) or 0),
            card.get("name", "?"),
        ),
    )
    threshold = 90 if top_limit and top_limit > 0 else 110
    chosen_to_top = []
    for card in scored_cards:
        if discard_replacement_priority(card, player) < threshold:
            continue
        if top_limit is not None and len(chosen_to_top) >= top_limit:
            break
        chosen_to_top.append(card)

    top_keys = {id(card) for card in chosen_to_top}
    to_graveyard = [card for card in cards if id(card) not in top_keys]
    player.graveyard.extend(to_graveyard)
    for card in reversed(chosen_to_top):
        player.library.insert(0, card)
    return {
        "to_top": chosen_to_top,
        "to_graveyard": to_graveyard,
        "used_replacement": bool(chosen_to_top),
    }


def player_has_lorehold_miracle_engine(player):
    return bool(_player_permanents_with_flag(player, "opponent_upkeep_rummage")) or _player_has_named_permanent(
        player,
        "Lorehold, the Historian",
    )


def lorehold_miracle_cost(player):
    permanents = _player_permanents_with_flag(player, "grants_miracle_cost")
    if not permanents:
        return 2 if _player_has_named_permanent(player, "Lorehold, the Historian") else None
    costs = [
        int(permanent.get("grants_miracle_cost") or 0)
        for permanent in permanents
        if int(permanent.get("grants_miracle_cost") or 0) > 0
    ]
    return min(costs) if costs else None


def lorehold_draw_priority(card, player):
    if not isinstance(card, dict):
        return -999
    effect_data = get_card_effect(card)
    effect = str(effect_data.get("effect") or card.get("effect") or "unknown")
    cmc = int(_opening_hand_card_cmc(card) or 0)
    normalized_name = normalize_card_name(card.get("name", ""))
    if normalized_name == "approach of the second sun":
        return 220
    if is_instant_or_sorcery_spell(card):
        base = 140 + min(cmc, 8) * 5
        if effect in {
            "board_wipe",
            "draw_cards",
            "remove_creature",
            "remove_permanent",
            "tutor",
            "worldfire_reset",
        }:
            base += 12
        return base
    if effect in {"draw_cards", "draw_engine", "hand_filter", "topdeck_manipulation"}:
        return 70
    if effect in {"ramp_permanent", "land_ramp", "ramp_engine"}:
        return 48
    if is_effective_land(card):
        return 18 if controlled_land_count(player) < 4 else 4
    return 20 + min(cmc, 6)


def activate_lorehold_topdeck_artifacts(
    player,
    turn,
    rng,
    *,
    phase="opponent_upkeep",
    all_players=None,
    stack=None,
):
    if not player.is_alive() or not player_has_lorehold_miracle_engine(player):
        return 0

    exchange_artifacts = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("effect") == "topdeck_manipulation"
        and permanent.get("hand_to_top_exchange")
        and not permanent.get("requires_sacrifice_artifact")
        and not permanent.get("draw_count")
        and not permanent.get("utility_artifact_used_this_turn")
    ]
    if phase in {"upkeep", "opponent_upkeep"} and exchange_artifacts and player.library:
        for permanent in exchange_artifacts:
            activation_cost = int(permanent.get("activation_cost_generic") or 1)
            if player.available_mana() < activation_cost:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_scroll_rack_exchange",
                    phase=phase,
                )
                continue

            hand_candidates = [
                card
                for card in player.hand
                if isinstance(card, dict) and is_instant_or_sorcery_spell(card)
            ]
            if not hand_candidates:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_hand_spell_worth_setting_as_first_draw",
                    phase=phase,
                )
                continue

            top_before = player.library[0]
            top_before_score = lorehold_draw_priority(top_before, player)
            scored_hand = sorted(
                (
                    {
                        "card": card,
                        "score": lorehold_draw_priority(card, player),
                    }
                    for card in hand_candidates
                ),
                key=lambda item: (
                    -item["score"],
                    int(_opening_hand_card_cmc(item["card"]) or 0),
                    item["card"].get("name", "?"),
                ),
            )
            chosen_hand = scored_hand[0]
            if (
                chosen_hand["score"] < 130
                or chosen_hand["score"] <= top_before_score
            ):
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "top_library_card_already_good_enough_for_first_draw",
                    phase=phase,
                )
                continue
            if not player.spend_mana(activation_cost):
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_scroll_rack_exchange_cost",
                    phase=phase,
                )
                continue

            player.hand.remove(chosen_hand["card"])
            gained_from_top = player.library.pop(0)
            player.hand.append(gained_from_top)
            player.library.insert(0, chosen_hand["card"])
            permanent["utility_artifact_used_this_turn"] = True
            permanent["tapped"] = True

            emit_decision_trace(
                decision_type="utility_artifact_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        item["card"],
                        score=item["score"],
                        action="set_hand_spell_as_next_draw",
                        effect="topdeck_manipulation",
                    )
                    for item in scored_hand
                ],
                chosen_option=decision_card_option(
                    chosen_hand["card"],
                    score=chosen_hand["score"],
                    action="activate_scroll_rack_exchange",
                    effect="topdeck_manipulation",
                ),
                rejected_options=[
                    decision_card_option(
                        item["card"],
                        score=item["score"],
                        action="leave_in_hand",
                        effect="topdeck_manipulation",
                    )
                    for item in scored_hand[1:]
                ],
                score_components={
                    "activation_cost_generic": activation_cost,
                    "cards_exchanged": 1,
                    "top_before": top_before.get("name", "?"),
                    "top_after": chosen_hand["card"].get("name", "?"),
                    "hand_to_top": chosen_hand["card"].get("name", "?"),
                },
                rule_source="lorehold_topdeck_support_v1",
                rule_status=permanent.get("_rule_review_status", "active"),
                confidence="medium",
                expected_benefit_score=chosen_hand["score"],
                actual_outcome="hand_spell_moved_to_top_for_next_draw",
                reason="convert_high_priority_hand_spell_into_next_first_draw",
                strategic_principle="spend_small_mana_only_when_scroll_rack materially upgrades the next Lorehold draw",
                heuristic_version=DECISION_STRATEGY_VERSION,
                resource_delta={
                    "mana": -activation_cost,
                    "top_before": top_before.get("name", "?"),
                    "top_after": chosen_hand["card"].get("name", "?"),
                    "hand_gained": gained_from_top.get("name", "?"),
                },
                risk_flags=["upkeep_mana_spend", "delayed_first_draw_setup", "engine_piece_tapped"],
                rejected_reason="lower_first_draw_priority_than_selected_hand_spell",
            )
            emit_replay_event(
                "topdeck_manipulation_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="scroll_rack_single_exchange_for_lorehold",
                top_before=top_before.get("name", "?"),
                top_after=chosen_hand["card"].get("name", "?"),
                hand_to_top=chosen_hand["card"].get("name", "?"),
                hand_gained=gained_from_top.get("name", "?"),
                exchange_count=1,
                phase=phase,
                turn=turn,
            )
            return 1

    brainstone_artifacts = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("effect") == "topdeck_manipulation"
        and permanent.get("requires_sacrifice_artifact")
        and int(permanent.get("draw_count") or 0) >= 3
        and int(permanent.get("put_from_hand_on_top_count") or 0) >= 2
        and not permanent.get("utility_artifact_used_this_turn")
    ]
    if phase in {"upkeep", "opponent_upkeep"} and brainstone_artifacts and player.library:
        for permanent in brainstone_artifacts:
            activation_cost = int(permanent.get("activation_cost_generic") or 2)
            draw_count = int(permanent.get("draw_count") or 3)
            putback_count = int(permanent.get("put_from_hand_on_top_count") or 2)
            miracle_cost = lorehold_miracle_cost(player)
            if miracle_cost is None:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_lorehold_miracle_cost_for_brainstone_line",
                    phase=phase,
                )
                continue
            if player.cards_drawn_this_turn != 0:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "brainstone_not_first_draw_window",
                    phase=phase,
                )
                continue
            if len(player.library) < draw_count:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "not_enough_library_for_brainstone_draw",
                    phase=phase,
                )
                continue
            first_draw_candidate = player.library[0]
            first_draw_score = lorehold_draw_priority(first_draw_candidate, player)
            if (
                first_draw_score < 130
                or not is_instant_or_sorcery_spell(first_draw_candidate)
            ):
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "brainstone_first_draw_not_miracle_candidate",
                    phase=phase,
                )
                continue
            expected_putback_slots = sum(
                1 for card in player.hand if isinstance(card, dict)
            ) + sum(
                1
                for card in player.library[1:draw_count]
                if isinstance(card, dict)
            )
            if expected_putback_slots < putback_count:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "not_enough_non_miracle_cards_for_brainstone_putback",
                    phase=phase,
                )
                continue
            if player.available_mana() < activation_cost + miracle_cost:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_brainstone_plus_miracle",
                    phase=phase,
                )
                continue
            if not player.spend_mana("{%d}" % activation_cost):
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_brainstone_activation_cost",
                    phase=phase,
                )
                continue

            if permanent in player.battlefield:
                player.battlefield.remove(permanent)
            permanent["utility_artifact_used_this_turn"] = True
            permanent["tapped"] = True
            player.graveyard.append(permanent)
            drawn = player.draw(draw_count, rng)
            if not drawn:
                continue
            first_drawn = drawn[0]
            putback_candidates = [
                card
                for card in player.hand
                if isinstance(card, dict) and card is not first_drawn
            ]
            if len(putback_candidates) < putback_count:
                _utility_artifact_skip_event(
                    player,
                    permanent,
                    turn,
                    "not_enough_non_miracle_cards_for_brainstone_putback",
                    phase=phase,
                )
                continue
            putback_cards = sorted(
                putback_candidates,
                key=lambda card: (
                    lorehold_draw_priority(card, player),
                    int(_opening_hand_card_cmc(card) or 0),
                    card.get("name", "?"),
                ),
            )[:putback_count]
            for card in putback_cards:
                player.hand.remove(card)
            for card in reversed(putback_cards):
                player.library.insert(0, card)

            emit_decision_trace(
                decision_type="utility_artifact_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        first_draw_candidate,
                        score=first_draw_score,
                        action="activate_brainstone_for_first_draw_miracle",
                        effect="topdeck_manipulation",
                    )
                ],
                chosen_option=decision_card_option(
                    first_draw_candidate,
                    score=first_draw_score,
                    action="activate_brainstone_for_first_draw_miracle",
                    effect="topdeck_manipulation",
                ),
                score_components={
                    "activation_cost_generic": activation_cost,
                    "draw_count": len(drawn),
                    "putback_count": len(putback_cards),
                    "first_draw": first_drawn.get("name", "?"),
                    "miracle_cost": miracle_cost,
                },
                rule_source="lorehold_topdeck_support_v1",
                rule_status=permanent.get("_rule_review_status", "active"),
                confidence="medium",
                expected_benefit_score=first_draw_score,
                actual_outcome="brainstone_first_draw_miracle_window",
                reason="use_brainstone_when_first_draw_is_known_miracle_win_line",
                strategic_principle="sacrifice topdeck tool only when the first draw immediately enables a high-priority miracle",
                heuristic_version=DECISION_STRATEGY_VERSION,
                resource_delta={
                    "mana": -activation_cost,
                    "artifacts": -1,
                    "graveyard": 1,
                    "drawn": [card.get("name", "?") for card in drawn],
                    "putback": [card.get("name", "?") for card in putback_cards],
                },
                risk_flags=["sacrifice_artifact", "multi_draw_first_card_miracle"],
                rejected_reason="requires_first_draw_miracle_candidate",
            )
            emit_replay_event(
                "topdeck_manipulation_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="brainstone_draw_three_put_two_back_for_miracle",
                first_draw=first_drawn.get("name", "?"),
                drawn=[card.get("name", "?") for card in drawn],
                putback=[card.get("name", "?") for card in putback_cards],
                phase=phase,
                turn=turn,
            )
            try_lorehold_miracle_cast(
                player,
                drawn,
                turn,
                phase,
                all_players,
                rng,
                stack,
                source="brainstone_first_draw",
                miracle_candidate=first_drawn,
            )
            return 1

    utility_artifacts = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict)
        and permanent.get("effect") == "topdeck_manipulation"
        and permanent.get("peek_top_count")
        and permanent.get("reorder_top")
        and not permanent.get("utility_artifact_used_this_turn")
    ]
    if not utility_artifacts or len(player.library) < 2:
        return 0

    for permanent in utility_artifacts:
        activation_cost = int(permanent.get("activation_cost_generic") or 1)
        if player.available_mana() < activation_cost:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "insufficient_mana_for_topdeck_reorder",
                phase=phase,
            )
            continue

        peek_count = max(2, int(permanent.get("peek_top_count") or 3))
        visible = [card for card in player.library[:peek_count] if isinstance(card, dict)]
        if len(visible) < 2:
            continue

        scored = [
            {"card": card, "score": lorehold_draw_priority(card, player)}
            for card in visible
        ]
        current_top_score = scored[0]["score"]
        scored_sorted = sorted(
            scored,
            key=lambda item: (
                -item["score"],
                int(_opening_hand_card_cmc(item["card"]) or 0),
                item["card"].get("name", "?"),
            ),
        )
        best = scored_sorted[0]
        miracle_cost = lorehold_miracle_cost(player)
        can_draw_put_self_for_miracle = (
            all_players is not None
            and stack is not None
            and bool(permanent.get("activated_draw_put_self_on_top"))
            and player.cards_drawn_this_turn == 0
            and miracle_cost is not None
            and is_instant_or_sorcery_spell(visible[0])
            and current_top_score >= 130
            and player.available_mana() >= miracle_cost
        )
        if can_draw_put_self_for_miracle:
            drawn = player.draw(1, rng)
            relocated_permanent = {
                key: value
                for key, value in dict(permanent).items()
                if key not in {"utility_artifact_used_this_turn", "tapped"}
            }
            if permanent in player.battlefield:
                player.battlefield.remove(permanent)
            player.library.insert(0, relocated_permanent)
            emit_decision_trace(
                decision_type="utility_artifact_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        item["card"],
                        score=item["score"],
                        action="draw_first_card_for_miracle",
                        effect="topdeck_manipulation",
                    )
                    for item in scored_sorted
                ],
                chosen_option=decision_card_option(
                    visible[0],
                    score=current_top_score,
                    action="activate_topdeck_draw_put_self_on_top",
                    effect="topdeck_manipulation",
                ),
                rejected_options=[
                    decision_card_option(
                        item["card"],
                        score=item["score"],
                        action="leave_below_top",
                        effect="topdeck_manipulation",
                    )
                    for item in scored_sorted[1:]
                ],
                score_components={
                    "activation_cost_generic": 0,
                    "peek_top_count": len(visible),
                    "top_before": visible[0].get("name", "?"),
                    "top_after": relocated_permanent.get("name", "?"),
                    "miracle_cost": miracle_cost,
                },
                rule_source="lorehold_topdeck_support_v1",
                rule_status=permanent.get("_rule_review_status", "active"),
                confidence="medium",
                expected_benefit_score=current_top_score,
                actual_outcome="top_card_drawn_for_miracle_window",
                reason="use_top_draw_mode_when_top_card_is_already_best_and_castable",
                strategic_principle="consume_topdeck_engine_piece_only_when_it_immediately_unlocks_a_high_priority_miracle_draw",
                heuristic_version=DECISION_STRATEGY_VERSION,
                resource_delta={
                    "mana": 0,
                    "top_before": visible[0].get("name", "?"),
                    "top_after": relocated_permanent.get("name", "?"),
                    "drawn": drawn[-1].get("name", "?") if drawn else None,
                },
                risk_flags=["topdeck_draw", "engine_piece_relocated_to_library"],
                rejected_reason="top_card_not_good_enough_to_consume_engine_piece",
            )
            emit_replay_event(
                "topdeck_manipulation_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="draw_put_self_on_top_for_miracle",
                top_before=visible[0].get("name", "?"),
                top_after=relocated_permanent.get("name", "?"),
                drawn=drawn[-1].get("name", "?") if drawn else None,
                peek_count=len(visible),
                phase=phase,
                turn=turn,
            )
            try_lorehold_miracle_cast(
                player,
                drawn,
                turn,
                phase,
                all_players,
                rng,
                stack,
                source="senseis_top_draw",
            )
            return 1
        if best["score"] <= current_top_score or best["card"] is visible[0]:
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "top_card_already_best_for_lorehold_draw",
                phase=phase,
            )
            continue
        if not player.spend_mana(activation_cost):
            _utility_artifact_skip_event(
                player,
                permanent,
                turn,
                "failed_to_pay_topdeck_reorder_cost",
                phase=phase,
            )
            continue

        player.library = [item["card"] for item in scored_sorted] + player.library[len(visible):]
        permanent["utility_artifact_used_this_turn"] = True
        emit_decision_trace(
            decision_type="utility_artifact_activation",
            player=player,
            turn=turn,
            phase=phase,
            available_options=[
                decision_card_option(
                    item["card"],
                    score=item["score"],
                    action="reorder_topdeck_for_miracle",
                    effect="topdeck_manipulation",
                )
                for item in scored_sorted
            ],
            chosen_option=decision_card_option(
                best["card"],
                score=best["score"],
                action="activate_topdeck_reorder",
                effect="topdeck_manipulation",
            ),
            rejected_options=[
                decision_card_option(
                    item["card"],
                    score=item["score"],
                    action="leave_below_top",
                    effect="topdeck_manipulation",
                )
                for item in scored_sorted[1:]
            ],
            score_components={
                "activation_cost_generic": activation_cost,
                "peek_top_count": len(visible),
                "top_before": visible[0].get("name", "?"),
                "top_after": best["card"].get("name", "?"),
            },
            rule_source="lorehold_topdeck_support_v1",
            rule_status=permanent.get("_rule_review_status", "active"),
            confidence="medium",
            expected_benefit_score=best["score"],
            actual_outcome="topdeck_reordered_for_first_draw",
            reason="reorder_top_cards_to_improve_lorehold_first_draw",
            strategic_principle="spend_small_mana_only_when_topdeck_tool_materially_improves_first_draw",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta={
                "mana": -activation_cost,
                "top_before": visible[0].get("name", "?"),
                "top_after": best["card"].get("name", "?"),
            },
            risk_flags=["upkeep_mana_spend", "topdeck_reorder"],
            rejected_reason="lower_first_draw_priority",
        )
        emit_replay_event(
            "topdeck_manipulation_activated",
            player=player.name,
            card=permanent.get("name", "?"),
            activation_kind="peek_reorder_for_lorehold",
            top_before=visible[0].get("name", "?"),
            top_after=best["card"].get("name", "?"),
            peek_count=len(visible),
            phase=phase,
            turn=turn,
        )
        return 1
    return 0


def choose_lorehold_rummage_discard(player):
    candidates = [card for card in player.hand if isinstance(card, dict)]
    if not candidates:
        return None, None, [], False, []

    lands_in_hand = sum(1 for card in candidates if is_effective_land(card))
    battlefield_lands = controlled_land_count(player)
    can_replace_to_top = player_has_discard_to_top_replacement(player)
    scored = []
    for card in candidates:
        cmc = int(_opening_hand_card_cmc(card) or 0)
        effect = get_card_effect(card).get("effect", card.get("effect", "unknown"))
        is_land_card = is_effective_land(card)
        instant_or_sorcery = is_instant_or_sorcery_spell(card)
        score = 0
        reason = "keep_card"
        use_top_replacement = False
        risk_flags = []
        if can_replace_to_top and instant_or_sorcery:
            score = 130 + min(cmc, 8) * 4
            reason = "redraw_spell_as_first_draw_for_miracle"
            use_top_replacement = True
        elif is_land_card and lands_in_hand >= 2 and battlefield_lands >= 4:
            score = 88
            reason = "discard_excess_land_for_new_draw"
        elif not is_land_card and cmc >= 7:
            score = 72
            reason = "pitch_dead_high_cmc_spell"
        elif not is_land_card and cmc >= 5 and effect not in {"draw_cards", "topdeck_manipulation"}:
            score = 54
            reason = "pitch_slow_noncritical_spell"
        elif is_land_card and battlefield_lands >= 5:
            score = 34
            reason = "discard_flood_land"
        else:
            risk_flags.append("card_may_be_too_valuable_to_pitch")
        if score <= 0:
            continue
        scored.append(
            {
                "card": card,
                "score": score,
                "reason": reason,
                "use_top_replacement": use_top_replacement,
                "risk_flags": risk_flags,
            }
        )
    if not scored:
        return None, None, [], False, []
    scored.sort(
        key=lambda item: (
            -item["score"],
            0 if item["use_top_replacement"] else 1,
            -int(_opening_hand_card_cmc(item["card"]) or 0),
            item["card"].get("name", "?"),
        )
    )
    chosen = scored[0]
    return (
        chosen["card"],
        chosen["reason"],
        chosen["risk_flags"],
        bool(chosen["use_top_replacement"]),
        scored,
    )


def try_lorehold_miracle_cast(
    player,
    drawn_for_turn,
    turn,
    phase,
    all_players,
    rng,
    stack,
    *,
    source,
    miracle_candidate=None,
):
    if not player.is_human or not drawn_for_turn:
        return False
    if miracle_candidate is None and player.cards_drawn_this_turn != 1:
        return False
    if miracle_candidate is not None and drawn_for_turn[0] is not miracle_candidate:
        return False
    miracle_cost = lorehold_miracle_cost(player)
    if miracle_cost is None:
        return False
    last_drawn = miracle_candidate or drawn_for_turn[-1]
    if not last_drawn or not is_instant_or_sorcery_spell(last_drawn):
        return False
    if player.available_mana() < miracle_cost:
        return False
    eff = get_card_effect(last_drawn)
    if last_drawn not in player.hand:
        return False
    opponents = [candidate for candidate in all_players if candidate is not player]
    if eff.get("effect") == "board_wipe" and not should_cast_board_wipe(player, opponents):
        return False
    if eff.get("effect") == "worldfire_reset" and not should_cast_worldfire_reset(player, opponents):
        return False
    if eff.get("effect") == "draw_cards" and is_wheel_like_card(last_drawn, eff):
        if not should_cast_wheel(player, opponents, {**eff, "name": last_drawn.get("name")}):
            return False
    player.hand.remove(last_drawn)
    player.spend_mana(miracle_cost)
    emit_replay_event(
        "miracle_cast",
        player=player.name,
        card=last_drawn.get("name", "?"),
        effect=eff.get("effect", "unknown"),
        type_line=last_drawn.get("type_line", ""),
        miracle_cost=miracle_cost,
        lorehold_on_board=True,
        cards_drawn_this_turn=player.cards_drawn_this_turn,
        phase=phase,
        source=source,
        turn=turn,
        **replay_rule_fields(eff),
    )
    stack.push(last_drawn, player, eff)
    while not stack.empty():
        priority_round(player, all_players, stack, turn, rng)
    return True


def process_lorehold_opponent_upkeep_rummage(active_player, all_players, turn, rng, stack):
    triggered = 0
    for player in all_players:
        if player is active_player or not player.is_alive():
            continue
        if not player_has_lorehold_miracle_engine(player):
            continue

        activate_lorehold_topdeck_artifacts(
            player,
            turn,
            rng,
            phase="opponent_upkeep",
            all_players=all_players,
            stack=stack,
        )
        if player.has_won():
            return triggered
        discarded, discard_reason, risk_flags, use_top_replacement, scored_options = choose_lorehold_rummage_discard(player)
        if discarded is None:
            emit_replay_event(
                "lorehold_upkeep_rummage_skipped",
                player=player.name,
                active_player=active_player.name,
                reason="no_strategic_discard_candidate",
                turn=turn,
            )
            continue
        if discarded not in player.hand:
            continue

        player.hand.remove(discarded)
        if use_top_replacement:
            player.library.insert(0, discarded)
            discard_destination = "top_of_library"
        else:
            player.graveyard.append(discarded)
            discard_destination = "graveyard"
        drawn = player.draw(1, rng)
        drawn_name = drawn[-1].get("name", "?") if drawn else None
        available_options = []
        seen_option_keys = set()
        for scored in scored_options:
            card = scored["card"]
            option = decision_card_option(
                card,
                score=scored["score"],
                action="discard_for_lorehold_rummage",
                effect=get_card_effect(card).get("effect", card.get("effect", "unknown")),
            )
            option_key = (
                option.get("card"),
                option.get("action"),
                option.get("effect"),
                option.get("cmc"),
                option.get("type_line"),
            )
            if option_key in seen_option_keys:
                continue
            seen_option_keys.add(option_key)
            available_options.append(option)
        chosen_rummage_option = decision_card_option(
            discarded,
            score=lorehold_draw_priority(discarded, player),
            action="discard_for_lorehold_rummage",
            effect=get_card_effect(discarded).get("effect", discarded.get("effect", "unknown")),
        )
        chosen_rummage_key = (
            chosen_rummage_option.get("card"),
            chosen_rummage_option.get("action"),
            chosen_rummage_option.get("effect"),
            chosen_rummage_option.get("cmc"),
            chosen_rummage_option.get("type_line"),
        )
        rejected_rummage_options = [
            option
            for option in available_options
            if (
                option.get("card"),
                option.get("action"),
                option.get("effect"),
                option.get("cmc"),
                option.get("type_line"),
            )
            != chosen_rummage_key
        ]
        emit_decision_trace(
            decision_type="lorehold_upkeep_rummage",
            player=player,
            turn=turn,
            phase="opponent_upkeep",
            available_options=available_options,
            chosen_option=chosen_rummage_option,
            rejected_options=rejected_rummage_options,
            score_components={
                "discard_destination": discard_destination,
                "drawn_card": drawn_name,
                "miracle_cost": lorehold_miracle_cost(player),
            },
            rule_source="lorehold_opponent_upkeep_rummage_v1",
            rule_status="active",
            confidence="medium",
            expected_benefit_score=lorehold_draw_priority(discarded, player),
            actual_outcome="discard_then_draw",
            reason=discard_reason,
            strategic_principle="convert_opponent_upkeep_draw_into_miracle_window_only_when_discard_is_contextually_defensible",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta={
                "hand": 0,
                "graveyard": 0 if use_top_replacement else 1,
                "library_top": discarded.get("name", "?") if use_top_replacement else None,
                "drawn": drawn_name,
            },
            risk_flags=risk_flags,
            rejected_reason="lower_lorehold_rummage_value",
        )
        emit_replay_event(
            "lorehold_upkeep_rummage",
            player=player.name,
            active_player=active_player.name,
            discarded=discarded.get("name", "?"),
            discard_destination=discard_destination,
            drawn=drawn_name,
            replacement_used=use_top_replacement,
            reason=discard_reason,
            turn=turn,
        )
        try_lorehold_miracle_cast(
            player,
            drawn,
            turn,
            "opponent_upkeep",
            all_players,
            rng,
            stack,
            source="lorehold_opponent_upkeep_rummage",
        )
        triggered += 1
    return triggered


def activate_utility_lands(player, turn, rng, *, phase="postcombat_main"):
    """Use safe card-draw utility lands without pretending to judge every spot.

    This is intentionally narrow: prefer card advantage only when the hand is
    low and the land either preserves board resources (War Room) or is clearly
    expendable (Sunbaked Canyon).
    """
    if not player.is_alive():
        return 0

    battlefield_lands = [
        permanent
        for permanent in player.battlefield
        if isinstance(permanent, dict) and is_effective_land(permanent)
    ]
    if not battlefield_lands:
        return 0

    hand_size = len(player.hand)
    land_count = len(battlefield_lands)
    activations = 0

    preferred_order = [
        "urza's saga",
        "war room",
        "sunbaked canyon",
        "inventors' fair",
        "hall of heliod's generosity",
    ]
    permanents_by_name = {
        normalize_card_name(permanent.get("name", "")): permanent
        for permanent in battlefield_lands
    }

    for normalized_name in preferred_order:
        permanent = permanents_by_name.get(normalized_name)
        if permanent is None or permanent.get("utility_land_used_this_turn"):
            continue

        if normalized_name == "urza's saga":
            initialize_special_land_runtime_state(permanent, turn=None)
            current_chapter = max(
                int(permanent.get("current_chapter") or 1),
                int(permanent.get("lore_counters") or 0),
            )
            if current_chapter != 2:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "urzas_saga_not_on_construct_chapter",
                    phase=phase,
                )
                continue
            if player.available_mana() < 2:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_urzas_saga_construct",
                    phase=phase,
                )
                continue
            if not player.spend_mana(2):
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_generic_cost",
                    phase=phase,
                )
                continue
            token = create_creature_token(
                player,
                name="Construct Token",
                power=0,
                toughness=0,
                artifact=True,
            )
            token["type_line"] = "Artifact Creature Token — Construct"
            token["subtype"] = "Construct"
            artifact_count_after = controlled_artifact_count(player)
            token["power"] = artifact_count_after
            token["toughness"] = artifact_count_after
            token["urzas_saga_construct"] = True
            permanent["utility_land_used_this_turn"] = True
            emit_decision_trace(
                decision_type="utility_land_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        permanent,
                        action="activate_construct_token",
                        score=34,
                        effect="token_maker",
                    )
                ],
                chosen_option=decision_card_option(
                    permanent,
                    action="activate_construct_token",
                    score=34,
                    effect="token_maker",
                ),
                score_components={
                    "chapter": current_chapter,
                    "artifact_count_after": artifact_count_after,
                    "mana_spend_penalty": -2,
                },
                rule_source="utility_land_activation_v1",
                rule_status="verified",
                confidence="medium",
                expected_benefit_score=34,
                reason="convert_limited_saga_window_into_board_material",
                strategic_principle="use_chapter_two_window_for_construct_pressure",
                resource_delta={
                    "tokens": 1,
                    "mana": -2,
                    "artifact_count_after": artifact_count_after,
                },
                risk_flags=[],
            )
            emit_replay_event(
                "utility_land_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="construct_token",
                token=token.get("name", "?"),
                token_power=token.get("power"),
                token_toughness=token.get("toughness"),
                artifact_count_after=artifact_count_after,
                mana_paid=2,
                phase=phase,
                turn=turn,
            )
            activations += 1
            break

        if normalized_name == "war room":
            if not player.library:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_library_for_card_draw_land",
                    phase=phase,
                )
                continue
            life_cost = commander_color_identity_count(player)
            if hand_size > 3:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "hand_not_low_enough_for_card_draw_land",
                    phase=phase,
                )
                continue
            if player.available_mana() < 4:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_card_draw_land",
                    phase=phase,
                )
                continue
            if player.life <= life_cost + 4:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "life_too_low_for_war_room_activation",
                    phase=phase,
                    risk_flags=["low_life"],
                )
                continue
            if not player.spend_mana(3):
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_generic_cost",
                    phase=phase,
                )
                continue
            change_life(player, -life_cost)
            drawn = player.draw(1, rng)
            permanent["utility_land_used_this_turn"] = True
            emit_decision_trace(
                decision_type="utility_land_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        permanent,
                        action="activate",
                        score=38,
                        effect="card_draw_land",
                    )
                ],
                chosen_option=decision_card_option(
                    permanent,
                    action="activate",
                    score=38,
                    effect="card_draw_land",
                ),
                score_components={
                    "hand_low_bonus": 18,
                    "resource_preservation_bonus": 12,
                    "life_cost_penalty": -life_cost,
                    "mana_spend_penalty": -3,
                },
                rule_source="utility_land_activation_v1",
                rule_status="verified",
                confidence="medium",
                expected_benefit_score=38,
                reason="convert_safe_mana_into_card_without_losing_land",
                strategic_principle="convert_safe_resource_into_cards",
                resource_delta={"cards": len(drawn), "life": -life_cost, "mana": -3, "lands": 0},
                risk_flags=["life_payment"],
            )
            emit_replay_event(
                "utility_land_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="draw_card",
                cards_drawn=len(drawn),
                life_paid=life_cost,
                mana_paid=3,
                hand_before=hand_size,
                hand_after=len(player.hand),
                lands_after=controlled_land_count(player),
                phase=phase,
                turn=turn,
            )
            activations += 1
            break

        if normalized_name == "sunbaked canyon":
            if not player.library:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_library_for_sacrifice_draw_land",
                    phase=phase,
                )
                continue
            if hand_size > 2:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "hand_not_low_enough_for_sacrifice_draw_land",
                    phase=phase,
                )
                continue
            if land_count <= 3:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "too_few_lands_to_sacrifice_draw_land",
                    phase=phase,
                    risk_flags=["spending_last_safe_land_slot"],
                )
                continue
            if player.available_mana() < 2:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_sacrifice_draw_land",
                    phase=phase,
                )
                continue
            if not player.spend_mana(1):
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_generic_cost",
                    phase=phase,
                )
                continue
            if permanent in player.battlefield:
                player.battlefield.remove(permanent)
            player.graveyard.append(permanent)
            drawn = player.draw(1, rng)
            emit_decision_trace(
                decision_type="utility_land_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        permanent,
                        action="activate",
                        score=28,
                        effect="sacrifice_draw_land",
                    )
                ],
                chosen_option=decision_card_option(
                    permanent,
                    action="activate",
                    score=28,
                    effect="sacrifice_draw_land",
                ),
                score_components={
                    "hand_low_bonus": 18,
                    "flood_relief_bonus": 10 if land_count >= 5 else 4,
                    "land_loss_penalty": -12,
                    "mana_spend_penalty": -1,
                },
                rule_source="utility_land_activation_v1",
                rule_status="verified",
                confidence="medium",
                expected_benefit_score=28,
                reason="cash_in_expendable_land_for_card",
                strategic_principle="convert_expendable_land_into_card",
                resource_delta={"cards": len(drawn), "life": 0, "mana": -1, "lands": -1},
                risk_flags=["sacrifice_land"],
            )
            emit_replay_event(
                "utility_land_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="sacrifice_draw",
                cards_drawn=len(drawn),
                mana_paid=1,
                hand_before=hand_size,
                hand_after=len(player.hand),
                lands_after=controlled_land_count(player),
                phase=phase,
                turn=turn,
            )
            activations += 1
            break

        if normalized_name == "inventors' fair":
            if not player.library:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_library_for_inventors_fair_tutor",
                    phase=phase,
                )
                continue
            artifact_count = controlled_artifact_count(player)
            if artifact_count < 3:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "artifact_threshold_not_met_for_inventors_fair",
                    phase=phase,
                    risk_flags=["artifact_threshold_missing"],
                )
                continue
            if hand_size > 2:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "hand_not_low_enough_for_inventors_fair_tutor",
                    phase=phase,
                )
                continue
            if player.available_mana() < 5:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_inventors_fair_tutor",
                    phase=phase,
                )
                continue
            candidates = [
                candidate
                for candidate in player.library
                if isinstance(candidate, dict)
                and "artifact" in str(candidate.get("type_line") or "").lower()
            ]
            if not candidates:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_artifact_tutor_target",
                    phase=phase,
                )
                continue
            scored_candidates = [
                (
                    candidate,
                    *tutor_candidate_score(candidate, "artifact_or_enchantment", player, [], turn),
                )
                for candidate in candidates
            ]
            scored_candidates.sort(
                key=lambda item: (
                    -item[1],
                    -int(float(item[0].get("cmc") or 0)),
                    item[0].get("name", ""),
                )
            )
            found, found_score, found_reason = scored_candidates[0]
            if not player.spend_mana(4):
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_generic_cost",
                    phase=phase,
                )
                continue
            if permanent in player.battlefield:
                player.battlefield.remove(permanent)
            player.graveyard.append(permanent)
            player.library.remove(found)
            player.hand.append(found)
            emit_decision_trace(
                decision_type="utility_land_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        candidate,
                        get_card_effect(candidate),
                        score=score,
                        action="activate_tutor_target",
                        reason=reason,
                        target_type="artifact",
                    )
                    for candidate, score, reason in scored_candidates[:10]
                ],
                chosen_option=decision_card_option(
                    found,
                    get_card_effect(found),
                    score=found_score,
                    action="activate_tutor_target",
                    reason=found_reason,
                    target_type="artifact",
                ),
                rejected_options=[
                    decision_card_option(
                        candidate,
                        get_card_effect(candidate),
                        score=score,
                        action="reject_tutor_target",
                        reason=reason,
                        target_type="artifact",
                    )
                    for candidate, score, reason in scored_candidates[1:10]
                ],
                score_components={
                    "artifact_threshold_bonus": 12,
                    "hand_low_bonus": 16,
                    "selected_reason": found_reason,
                    "artifact_count": artifact_count,
                    "mana_spend_penalty": -4,
                    "land_loss_penalty": -1,
                },
                rule_source="utility_land_activation_v1",
                rule_status="verified",
                confidence="medium",
                expected_benefit_score=found_score,
                reason="convert_boarded_artifact_threshold_into_best_artifact",
                strategic_principle="cash_in_utility_land_for_contextual_artifact",
                resource_delta={
                    "cards": 1,
                    "mana": -4,
                    "lands": -1,
                    "selected": found.get("name", "?"),
                },
                risk_flags=["sacrifice_land"],
                rejected_reason="lower_contextual_tutor_score",
            )
            emit_replay_event(
                "utility_land_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="artifact_tutor",
                found=found.get("name", "?"),
                artifact_count=artifact_count,
                mana_paid=4,
                hand_before=hand_size,
                hand_after=len(player.hand),
                lands_after=controlled_land_count(player),
                phase=phase,
                turn=turn,
            )
            activations += 1
            break

        if normalized_name == "hall of heliod's generosity":
            if hand_size > 2:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "hand_not_low_enough_for_hall_recursion",
                    phase=phase,
                )
                continue
            if player.available_mana() < 3:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "insufficient_mana_for_hall_recursion",
                    phase=phase,
                )
                continue
            if not player.can_pay("{1}{W}"):
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "missing_white_mana_for_hall_recursion",
                    phase=phase,
                    risk_flags=["color_requirement_unmet"],
                )
                continue
            candidates = [
                candidate
                for candidate in player.graveyard
                if isinstance(candidate, dict)
                and "enchantment" in str(candidate.get("type_line") or "").lower()
            ]
            if not candidates:
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "no_enchantment_to_recover",
                    phase=phase,
                )
                continue
            scored_candidates = [
                (
                    candidate,
                    *graveyard_enchantment_recovery_score(candidate, player, turn),
                )
                for candidate in candidates
            ]
            scored_candidates.sort(
                key=lambda item: (
                    -item[1],
                    -int(float(item[0].get("cmc") or 0)),
                    item[0].get("name", ""),
                )
            )
            found, found_score, found_reason = scored_candidates[0]
            if not player.spend_mana("{1}{W}"):
                _utility_land_skip_event(
                    player,
                    permanent,
                    turn,
                    "failed_to_pay_colored_cost",
                    phase=phase,
                )
                continue
            player.graveyard.remove(found)
            player.library.insert(0, found)
            permanent["utility_land_used_this_turn"] = True
            emit_decision_trace(
                decision_type="utility_land_activation",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        candidate,
                        get_card_effect(candidate),
                        score=score,
                        action="recover_to_top",
                        reason=reason,
                    )
                    for candidate, score, reason in scored_candidates[:10]
                ],
                chosen_option=decision_card_option(
                    found,
                    get_card_effect(found),
                    score=found_score,
                    action="recover_to_top",
                    reason=found_reason,
                ),
                rejected_options=[
                    decision_card_option(
                        candidate,
                        get_card_effect(candidate),
                        score=score,
                        action="reject_recovery_target",
                        reason=reason,
                    )
                    for candidate, score, reason in scored_candidates[1:10]
                ],
                score_components={
                    "hand_low_bonus": 14,
                    "engine_or_value_bonus": found_score,
                    "mana_spend_penalty": -2,
                },
                rule_source="utility_land_activation_v1",
                rule_status="verified",
                confidence="medium",
                expected_benefit_score=found_score,
                reason="secure_next_draw_with_best_graveyard_enchantment",
                strategic_principle="convert_idle_land_slot_into_next_draw_quality",
                resource_delta={
                    "cards": 0,
                    "mana": -2,
                    "lands": 0,
                    "selected": found.get("name", "?"),
                    "zone_move": "graveyard_to_library_top",
                },
                risk_flags=[],
                rejected_reason="lower_contextual_recovery_score",
            )
            emit_replay_event(
                "utility_land_activated",
                player=player.name,
                card=permanent.get("name", "?"),
                activation_kind="graveyard_enchantment_to_top",
                found=found.get("name", "?"),
                mana_paid=2,
                hand_before=hand_size,
                hand_after=len(player.hand),
                library_top=found.get("name", "?"),
                phase=phase,
                turn=turn,
            )
            activations += 1
            break

    return activations


def tutor_destination_for_target_type(target_type):
    if target_type in ("graveyard", "graveyard_nonlegendary"):
        return "graveyard"
    if str(target_type).endswith("_to_battlefield"):
        return "battlefield"
    return "hand"


def tutor_candidate_score(candidate, target_type, player, opponents, turn):
    effect_data = get_card_effect(candidate)
    effect = str(effect_data.get("effect") or candidate.get("effect") or "unknown")
    cmc = int(float(candidate.get("cmc") or 0))
    lands = controlled_land_count(player)
    opponent_creatures = sum(
        battlefield_creature_stats(opp)["count"]
        for opp in opponents
        if opp.is_alive()
    )
    score = threat_score(effect, candidate.get("name", ""), player, [player] + list(opponents), turn)
    reason = "highest_contextual_value"
    if target_type == "land" or (is_effective_land(candidate) and lands < 3):
        score += 80 if lands < 3 else 25
        reason = "fix_mana_or_land_drop"
    elif effect in ("ramp_permanent", "land_ramp", "ramp_engine") and lands < 4:
        score += 65
        reason = "accelerate_underdeveloped_mana"
    elif effect in ("remove_creature", "remove_permanent", "board_wipe") and opponent_creatures >= 3:
        score += 55
        reason = "find_interaction_for_board_pressure"
    elif effect in ("draw_engine", "topdeck_manipulation") and turn <= 5:
        score += 50
        reason = "establish_value_engine"
    elif effect in ("wincon", "approach", "finisher", "overload_recursion", "worldfire_reset") and turn >= 5:
        score += 70
        reason = "find_closing_line"
    elif str(target_type).endswith("_to_battlefield") and is_creature_card(candidate):
        score += max(20, cmc * 5)
        reason = "battlefield_tutor_prefers_material_impact"
    return score, reason


def create_creature_token(
    player,
    *,
    name="Token",
    power=2,
    toughness=None,
    haste=False,
    flying=False,
    artifact=False,
):
    token = {
        "name": name,
        "cmc": 0,
        "tag": "token",
        "effect": "creature",
        "type_line": "Artifact Creature Token" if artifact else "Creature Token",
        "power": power,
        "toughness": toughness if toughness is not None else power,
        "haste": bool(haste),
        "summoning_sick": not bool(haste),
        "tapped": False,
    }
    if flying:
        token["flying"] = True
        token["keywords"] = ["flying"]
    player.battlefield.append(token)

    if artifact:
        replacement_engines = [
            permanent
            for permanent in player.battlefield
            if isinstance(permanent, dict) and permanent.get("artifact_token_replacement")
        ]
        for _ in replacement_engines:
            player.battlefield.append(
                {
                    "name": "Thopter Token",
                    "cmc": 0,
                    "tag": "token",
                    "effect": "creature",
                    "type_line": "Artifact Creature Token — Thopter",
                    "power": 1,
                    "toughness": 1,
                    "flying": True,
                    "keywords": ["flying"],
                    "summoning_sick": True,
                    "tapped": False,
                }
            )
    return token


def prepare_entering_permanent(permanent):
    """Apply shared creature-entry state for permanents with engine effects."""
    if not isinstance(permanent, dict):
        return permanent
    if is_battlefield_creature(permanent):
        permanent["haste"] = has_haste(permanent)
        permanent["summoning_sick"] = not permanent["haste"]
        permanent["tapped"] = False
        try:
            permanent["power"] = int(permanent.get("power") or 1)
        except (TypeError, ValueError):
            permanent["power"] = 1
        try:
            permanent["toughness"] = int(permanent.get("toughness") or permanent["power"] or 1)
        except (TypeError, ValueError):
            permanent["toughness"] = permanent["power"] or 1
    return permanent


def trigger_landfall(
    player,
    land_permanent,
    turn,
    source_event,
    opponents=None,
    *,
    stack=None,
    active_player=None,
    all_players=None,
):
    def resolve_landfall():
        created = []
        for permanent in list(player.battlefield):
            if not isinstance(permanent, dict) or not permanent.get("landfall_token_maker"):
                continue
            created.append(
                create_creature_token(
                    player,
                    name="Insect Token",
                    power=int(permanent.get("token_power") or 1),
                    toughness=int(permanent.get("token_toughness") or 1),
                )
            )
        if created:
            emit_replay_event(
                "trigger_resolved",
                player=player.name,
                card="; ".join(
                    sorted(
                        {
                            permanent.get("name", "?")
                            for permanent in player.battlefield
                            if isinstance(permanent, dict) and permanent.get("landfall_token_maker")
                        }
                    )
                ),
                trigger="landfall",
                trigger_land=land_permanent.get("name", "?") if isinstance(land_permanent, dict) else "Land",
                source_event=source_event,
                effect="token_maker",
                tokens_created=len(created),
                turn=turn,
            )
        trigger_opponents = opponents or []
        for permanent in list(player.battlefield):
            if not isinstance(permanent, dict) or not permanent.get("landfall_damage_each_opponent"):
                continue
            count = int(permanent.get("_landfall_triggers_this_turn") or 0) + 1
            permanent["_landfall_triggers_this_turn"] = count
            amount = int(permanent.get("landfall_damage_each_opponent") or 1)
            damaged = []
            for opponent in trigger_opponents:
                if opponent.is_alive() and deal_damage(opponent, amount):
                    damaged.append({"player": opponent.name, "life_after": opponent.life})
            drew = False
            if permanent.get("landfall_second_draw") and count == 2:
                player.draw(1, random.Random(turn + count))
                drew = True
            emit_replay_event(
                "trigger_resolved",
                player=player.name,
                card=permanent.get("name", "?"),
                trigger="landfall",
                trigger_land=land_permanent.get("name", "?") if isinstance(land_permanent, dict) else "Land",
                source_event=source_event,
                effect="damage_each_opponent",
                amount=amount,
                damaged=damaged,
                draw_card=drew,
                trigger_count_this_turn=count,
                turn=turn,
                **replay_rule_fields(permanent),
            )

    resolve_or_enqueue_trigger(
        player,
        land_permanent,
        "landfall",
        resolve_landfall,
        stack=stack,
        active_player=active_player,
        all_players=all_players,
    )


def sacrifice_land_for_effect(player, card, turn, *, required=True, effect_data=None):
    effect_data = effect_data or {}
    battlefield_lands = [
        candidate
        for candidate in player.battlefield
        if isinstance(candidate, dict) and is_effective_land(candidate)
    ]
    land, land_options, strategic_risk_flags, selection_reason = choose_land_for_resource_cost(
        battlefield_lands,
        zone="battlefield",
    )
    if not land:
        if required:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="sacrifice_land",
                turn=turn,
                land_options=land_options,
                strategic_risk_flags=strategic_risk_flags,
            )
        return None
    count = int(effect_data.get("land_count") or effect_data.get("lands_to_battlefield") or 1)
    _targets, target_options = choose_land_ramp_targets(player, effect_data, count)
    allowed, benefit_reason = land_sacrifice_has_strategic_benefit(
        strategic_risk_flags,
        target_options,
        count,
    )
    if not allowed:
        if required:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="sacrifice_land",
                reason="strategic_guardrail",
                turn=turn,
                land_options=land_options,
                land_ramp_target_options=target_options,
                strategic_risk_flags=strategic_risk_flags,
                strategic_guardrail_reason=benefit_reason,
            )
        return None
    player.battlefield.remove(land)
    player.graveyard.append(land)
    emit_replay_event(
        "additional_cost_paid",
        player=player.name,
        card=card.get("name", "?"),
        cost="sacrifice_land",
        sacrificed=land.get("name", "?"),
        turn=turn,
        land_options=land_options,
        land_ramp_target_options=target_options,
        selection_reason=selection_reason,
        strategic_risk_flags=strategic_risk_flags,
        strategic_benefit_reason=benefit_reason,
    )
    return land


def put_lands_from_library(player, card, effect_data, turn, *, opponents=None, source_event="land_ramp"):
    count = int(effect_data.get("land_count") or effect_data.get("lands_to_battlefield") or 1)
    if effect_data.get("requires_sacrifice_land") and not sacrifice_land_for_effect(
        player,
        card,
        turn,
        required=True,
        effect_data=effect_data,
    ):
        return []
    found = []
    chosen_targets, target_options = choose_land_ramp_targets(player, effect_data, count)
    for candidate in list(chosen_targets):
        if len(found) >= count:
            break
        if candidate not in player.library:
            continue
        player.library.remove(candidate)
        land = enrich_card({
            **candidate,
            "effect": "land",
            "tapped": bool(effect_data.get("land_enters_tapped", True)),
        })
        player.battlefield.append(land)
        trigger_landfall(player, land, turn, source_event, opponents=opponents)
        found.append(land)
    emit_replay_event(
        "land_ramp_resolved",
        player=player.name,
        card=card.get("name", "?"),
        found=[land.get("name", "?") for land in found],
        count=len(found),
        target_options=target_options,
        land_enters_tapped=bool(effect_data.get("land_enters_tapped", True)),
        turn=turn,
    )
    return found


def return_graveyard_lands_to_battlefield(player, card, turn, *, opponents=None, source_event="land_recursion"):
    returned = []
    for grave_card in list(player.graveyard):
        if isinstance(grave_card, dict) and is_effective_land(grave_card):
            player.graveyard.remove(grave_card)
            land = enrich_card({**grave_card, "effect": "land", "tapped": True})
            player.battlefield.append(land)
            trigger_landfall(player, land, turn, source_event, opponents=opponents)
            returned.append(land)
    emit_replay_event(
        "land_recursion_resolved",
        player=player.name,
        card=card.get("name", "?"),
        lands_returned=[land.get("name", "?") for land in returned],
        count=len(returned),
        turn=turn,
    )
    return returned


def trigger_opponent_land_play_engines(
    active_player,
    opponents,
    land_permanent,
    turn,
    *,
    stack=None,
    all_players=None,
):
    for opponent in opponents:
        if not opponent.is_alive():
            continue
        engines = [
            permanent
            for permanent in opponent.battlefield
            if isinstance(permanent, dict)
            and permanent.get("effect") == "ramp_engine"
            and permanent.get("trigger") == "opponent_land_play"
        ]
        if not engines:
            continue
        land_from_hand = next((card for card in opponent.hand if is_effective_land(card)), None)
        if not land_from_hand:
            continue
        def resolve_opponent_land_play(
            opponent=opponent,
            land_from_hand=land_from_hand,
            engine=engines[0],
        ):
            if land_from_hand not in opponent.hand:
                return
            opponent.hand.remove(land_from_hand)
            extra_land = enrich_card({**land_from_hand, "effect": "land"})
            opponent.battlefield.append(extra_land)
            trigger_landfall(opponent, extra_land, turn, "opponent_land_play")
            emit_replay_event(
                "trigger_resolved",
                player=opponent.name,
                card=engine.get("name", "?"),
                trigger="opponent_land_play",
                active_player=active_player.name,
                trigger_land=land_permanent.get("name", "?") if isinstance(land_permanent, dict) else "Land",
                effect="land",
                put_land=extra_land.get("name", "?"),
                turn=turn,
            )

        resolve_or_enqueue_trigger(
            opponent,
            engines[0],
            "opponent_land_play",
            resolve_opponent_land_play,
            stack=stack,
            active_player=active_player,
            all_players=all_players,
        )


def activate_land_tutor_creatures(player, turn):
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict):
            continue
        land_tutor_creature = bool(permanent.get("land_tutor_activated"))
        self_sacrifice_land_tutor = bool(permanent.get("activated_self_sacrifice_land_tutor"))
        if not land_tutor_creature and not self_sacrifice_land_tutor:
            continue
        if permanent.get("tapped"):
            continue
        if land_tutor_creature and permanent.get("summoning_sick"):
            continue
        activation_cost = int(permanent.get("activation_cost_generic") or 2)
        if player.available_mana() < activation_cost:
            continue

        type_line = str(permanent.get("type_line") or "").lower()
        is_creature = "creature" in type_line or permanent.get("effect") == "creature"
        effect_data = {
            **get_card_effect(permanent),
            **permanent,
            "land_count": 1,
            "lands_to_battlefield": 1,
            "land_enters_tapped": True,
        }
        chosen_targets, target_options = choose_land_ramp_targets(player, effect_data, 1)
        if self_sacrifice_land_tutor:
            current_lands = controlled_land_count(player)
            allowed, benefit_reason = self_sacrifice_land_tutor_has_strategic_benefit(
                player,
                target_options,
            )
            if not chosen_targets or not allowed:
                emit_replay_event(
                    "activated_ability_skipped",
                    player=player.name,
                    card=permanent.get("name", "?"),
                    effect="land_tutor",
                    reason="strategic_guardrail" if chosen_targets else "missing_land_or_target",
                    land_ramp_target_options=target_options,
                    strategic_guardrail_reason=benefit_reason,
                    turn=turn,
                )
                continue
            land_to_find = chosen_targets[0]
            if not player.spend_mana(activation_cost):
                emit_replay_event(
                    "activated_ability_skipped",
                    player=player.name,
                    card=permanent.get("name", "?"),
                    effect="land_tutor",
                    reason="failed_to_pay_activation_cost",
                    land_ramp_target_options=target_options,
                    strategic_guardrail_reason=benefit_reason,
                    turn=turn,
                )
                continue
            if permanent.get("activation_requires_tap"):
                permanent["tapped"] = True
            if permanent in player.battlefield:
                player.battlefield.remove(permanent)
            player.graveyard.append(permanent)
            player.library.remove(land_to_find)
            found_land = enrich_card({**land_to_find, "effect": "land", "tapped": True})
            player.battlefield.append(found_land)
            trigger_landfall(player, found_land, turn, "land_tutor_activated")
            emit_decision_trace(
                decision_type="utility_artifact_activation",
                player=player,
                turn=turn,
                phase="precombat_main",
                available_options=[
                    decision_card_option(
                        {"name": option["name"]},
                        score=option["score"],
                        action="activate_land_tutor_artifact",
                        effect="land_tutor",
                    )
                    for option in sorted(target_options, key=lambda item: item["selection_rank"])[:8]
                ],
                chosen_option=decision_card_option(
                    land_to_find,
                    score=next(
                        (option["score"] for option in target_options if option["name"] == land_to_find.get("name", "?")),
                        0,
                    ),
                    action="activate_land_tutor_artifact",
                    effect="land_tutor",
                ),
                score_components={
                    "activation_cost_generic": activation_cost,
                    "found_land": land_to_find.get("name", "?"),
                    "current_lands": current_lands,
                },
                rule_source="utility_artifact_activation_v1",
                rule_status=permanent.get("_rule_review_status", "active"),
                confidence="medium",
                expected_benefit_score=next(
                    (option["score"] for option in target_options if option["name"] == land_to_find.get("name", "?")),
                    0,
                ),
                actual_outcome="artifact_converted_into_tapped_land",
                reason="convert_low_impact_artifact_into_structural_land_development",
                strategic_principle="cash_in_land_tutor_artifact_when_it_improves_real_mana_development",
                heuristic_version=DECISION_STRATEGY_VERSION,
                resource_delta={
                    "artifacts": -1,
                    "graveyard": 1,
                    "lands": 1,
                    "found_land": land_to_find.get("name", "?"),
                },
                risk_flags=["sacrifice_artifact", "land_tutor"],
            )
            emit_replay_event(
                "activated_ability",
                player=player.name,
                card=permanent.get("name", "?"),
                effect="land_tutor",
                activation_kind="self_sacrifice_land_tutor_artifact",
                found=found_land.get("name", "?"),
                land_ramp_target_options=target_options,
                strategic_benefit_reason=benefit_reason,
                turn=turn,
            )
            return

        if controlled_land_count(player) <= 1:
            continue
        battlefield_lands = [
            land for land in player.battlefield
            if isinstance(land, dict) and is_effective_land(land)
        ]
        land_to_sacrifice, land_options, strategic_risk_flags, selection_reason = choose_land_for_resource_cost(
            battlefield_lands,
            zone="battlefield",
        )
        allowed, benefit_reason = land_sacrifice_has_strategic_benefit(
            strategic_risk_flags,
            target_options,
            1,
        )
        if not land_to_sacrifice or not chosen_targets or not allowed:
            emit_replay_event(
                "activated_ability_skipped",
                player=player.name,
                card=permanent.get("name", "?"),
                effect="land_tutor",
                reason="strategic_guardrail" if land_to_sacrifice and chosen_targets else "missing_land_or_target",
                land_options=land_options,
                land_ramp_target_options=target_options,
                strategic_risk_flags=strategic_risk_flags,
                strategic_guardrail_reason=benefit_reason,
                turn=turn,
            )
            continue
        land_to_find = chosen_targets[0]
        player.spend_mana(activation_cost)
        if is_creature:
            permanent["tapped"] = True
        player.battlefield.remove(land_to_sacrifice)
        player.graveyard.append(land_to_sacrifice)
        player.library.remove(land_to_find)
        found_land = enrich_card({**land_to_find, "effect": "land", "tapped": True})
        player.battlefield.append(found_land)
        trigger_landfall(player, found_land, turn, "land_tutor_activated")
        emit_replay_event(
            "activated_ability",
            player=player.name,
            card=permanent.get("name", "?"),
            effect="land_tutor",
            sacrificed=land_to_sacrifice.get("name", "?"),
            found=found_land.get("name", "?"),
            land_options=land_options,
            land_ramp_target_options=target_options,
            selection_reason=selection_reason,
            strategic_risk_flags=strategic_risk_flags,
            strategic_benefit_reason=benefit_reason,
            turn=turn,
        )
        return


def resolve_land_recursion_creature(player, card, effect_data, turn):
    permanent = enrich_card({**card, **effect_data})
    permanent["effect"] = "creature"
    permanent["haste"] = has_haste(permanent)
    permanent["summoning_sick"] = not permanent["haste"]
    permanent["tapped"] = False
    if effect_data.get("power_equals_lands") or effect_data.get("toughness_equals_lands"):
        lands = max(1, controlled_land_count(player))
        if effect_data.get("power_equals_lands"):
            permanent["power"] = lands
        if effect_data.get("toughness_equals_lands"):
            permanent["toughness"] = lands
    player.battlefield.append(permanent)

    milled = []
    for _ in range(int(effect_data.get("mill_count") or 0)):
        if not player.library:
            break
        milled_card = player.library.pop(0)
        player.graveyard.append(milled_card)
        milled.append(milled_card)

    returned = []
    for grave_card in list(player.graveyard):
        if isinstance(grave_card, dict) and is_effective_land(grave_card):
            player.graveyard.remove(grave_card)
            returned_land = enrich_card(grave_card)
            returned_land["effect"] = "land"
            returned_land["tapped"] = True
            player.battlefield.append(returned_land)
            trigger_landfall(player, returned_land, turn, "land_recursion")
            returned.append(returned_land)

    if effect_data.get("power_equals_lands") or effect_data.get("toughness_equals_lands"):
        lands_after = max(1, controlled_land_count(player))
        if effect_data.get("power_equals_lands"):
            permanent["power"] = lands_after
        if effect_data.get("toughness_equals_lands"):
            permanent["toughness"] = lands_after

    emit_replay_event(
        "land_recursion_creature_resolved",
        player=player.name,
        card=card.get("name", "?"),
        milled=[milled_card.get("name", "?") for milled_card in milled if isinstance(milled_card, dict)],
        lands_returned=[returned_land.get("name", "?") for returned_land in returned],
        power=permanent.get("power"),
        toughness=permanent.get("toughness"),
        turn=turn,
    )


def apply_equipment_haste_shroud(player, card, effect_data, turn):
    equipment = enrich_card({**card, **effect_data})
    equipment["effect"] = "equipment_haste_shroud"
    player.battlefield.append(equipment)
    creatures = [
        permanent
        for permanent in player.battlefield
        if is_battlefield_creature(permanent)
    ]
    if not creatures:
        emit_replay_event(
            "equipment_unattached",
            player=player.name,
            card=card.get("name", "?"),
            turn=turn,
        )
        return
    target = choose_best_creature_target(creatures)
    target["haste"] = True
    target["summoning_sick"] = False
    target["shroud"] = True
    emit_replay_event(
        "equipment_attached",
        player=player.name,
        card=card.get("name", "?"),
        target=target.get("name", "?"),
        grants=["haste", "shroud"],
        turn=turn,
    )


def resolve_hand_filter(player, card, effect_data, turn, rng):
    """Resolve Valakut Awakening-style bottom-then-draw filtering."""
    max_bottom = int(effect_data.get("max_bottom") or 3)
    draw_extra = int(effect_data.get("draw_extra") or 1)
    candidates = [
        candidate
        for candidate in player.hand
        if isinstance(candidate, dict)
        and candidate is not card
    ]
    land_count = sum(1 for candidate in candidates if is_effective_land(candidate))

    def candidate_bottom_profile(candidate):
        effect = get_card_effect(candidate).get("effect", candidate.get("effect", "unknown"))
        cmc = _opening_hand_card_cmc(candidate)
        is_land_card = is_effective_land(candidate)
        keep_effects = {
            "counter",
            "remove_creature",
            "remove_permanent",
            "protection",
            "phase_out",
            "tutor",
            "ramp_permanent",
            "land_ramp",
        }
        should_bottom = False
        urgency = 99
        reason = "keep"
        if effect in keep_effects:
            should_bottom = False
            urgency = 99
            reason = "keep_interaction_or_setup"
        elif is_land_card and land_count >= 4:
            should_bottom = True
            urgency = 20
            reason = "excess_land"
        elif cmc >= 7:
            should_bottom = True
            urgency = 10
            reason = "dead_high_cmc"
        elif cmc >= 5 and effect not in {"draw_cards", "hand_filter", "cantrip_mana_filter_artifact"}:
            should_bottom = True
            urgency = 30
            reason = "slow_noncritical_spell"
        elif effect in {"draw_cards", "hand_filter", "cantrip_mana_filter_artifact"} and cmc >= 5:
            should_bottom = True
            urgency = 25
            reason = "expensive_refill_spell"
        return {
            "candidate": candidate,
            "should_bottom": should_bottom,
            "urgency": urgency,
            "reason": reason,
            "cmc": cmc,
            "is_land_card": is_land_card,
            "effect": effect,
        }

    bottom_profiles = [
        profile
        for profile in (candidate_bottom_profile(candidate) for candidate in candidates)
        if profile["should_bottom"]
    ]
    bottom_profiles.sort(
        key=lambda profile: (
            profile["urgency"],
            0 if profile["is_land_card"] else 1,
            -profile["cmc"],
            profile["candidate"].get("name", "?"),
        )
    )
    to_bottom = [
        profile["candidate"]
        for profile in bottom_profiles[:max_bottom]
    ]
    for bottomed in to_bottom:
        if bottomed in player.hand:
            player.hand.remove(bottomed)
            player.library.append(bottomed)
    drawn = player.draw(len(to_bottom) + draw_extra, rng)
    emit_replay_event(
        "hand_filter_resolved",
        player=player.name,
        card=card.get("name", "?"),
        bottomed=[bottomed.get("name", "?") for bottomed in to_bottom],
        cards_drawn=[drawn_card.get("name", "?") for drawn_card in drawn if isinstance(drawn_card, dict)],
        draw_count=len(drawn),
        bottom_reasons=[
            {
                "card": profile["candidate"].get("name", "?"),
                "reason": profile["reason"],
            }
            for profile in bottom_profiles[:max_bottom]
        ],
        turn=turn,
        **replay_rule_fields(effect_data),
    )
    finish_resolved_spell(player, card, turn=turn)


def resolve_copy_creature_token(player, card, effect_data, turn):
    """Create a temporary token copy of one of the controller's creatures."""
    targets = [
        permanent
        for permanent in player.battlefield
        if is_battlefield_creature(permanent)
    ]
    if not targets:
        emit_replay_event(
            "copy_creature_token_failed",
            player=player.name,
            card=card.get("name", "?"),
            reason="no_creature_target",
            turn=turn,
            **replay_rule_fields(effect_data),
        )
        finish_resolved_spell(player, card, turn=turn)
        return None
    target = choose_best_creature_target(targets)
    token = copy.deepcopy(target)
    token["name"] = f"{target.get('name', 'Creature')} token"
    token["token"] = True
    token["copy_of"] = target.get("name", "?")
    token["is_commander"] = False
    token["haste"] = bool(effect_data.get("token_haste", True))
    token["summoning_sick"] = not token["haste"]
    token["tapped"] = False
    if effect_data.get("sacrifice_token_at_end_step"):
        token["sacrifice_at_end_step"] = True
    player.battlefield.append(token)
    emit_replay_event(
        "copy_creature_token_created",
        player=player.name,
        card=card.get("name", "?"),
        target=target.get("name", "?"),
        token=token.get("name", "?"),
        haste=token.get("haste"),
        sacrifice_at_end_step=bool(token.get("sacrifice_at_end_step")),
        turn=turn,
        **replay_rule_fields(effect_data),
    )
    finish_resolved_spell(player, card, turn=turn)
    return token


def process_end_step_token_sacrifices(player, turn):
    sacrificed = []
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict) or not permanent.get("sacrifice_at_end_step"):
            continue
        player.battlefield.remove(permanent)
        player.graveyard.append(permanent)
        sacrificed.append(permanent)
    if sacrificed:
        emit_replay_event(
            "end_step_token_sacrificed",
            player=player.name,
            tokens=[token.get("name", "?") for token in sacrificed],
            turn=turn,
        )
    return sacrificed


def apply_direct_damage(player, opponents, card, effect_data, turn, rng):
    raw_amount = effect_data.get("amount") or effect_data.get("damage") or 3
    if raw_amount == "x_available":
        amount = max(1, int(card.get("cmc") or 0), player.available_mana())
    else:
        amount = int(raw_amount)
    for opp in opponents:
        targets = [
            target
            for target in removal_target_candidates(opp, controller=player, source=card)
            if int(target.get("toughness") or target.get("power") or 2) <= amount
        ]
        if targets:
            target = choose_best_creature_target(targets)
            destination = move_creature_from_battlefield(opp, target)
            emit_replay_event(
                "damage_resolved",
                player=player.name,
                card=card.get("name", "?"),
                amount=amount,
                target_player=opp.name,
                target=target.get("name", "?"),
                result="creature_destroyed",
                destination=destination,
                turn=turn,
            )
            player.graveyard.append(card)
            return
    alive_opponents = [opp for opp in opponents if opp.is_alive()]
    if alive_opponents:
        target_player = min(alive_opponents, key=lambda opp: opp.life)
        dealt = deal_damage(target_player, amount)
        emit_replay_event(
            "damage_resolved",
            player=player.name,
            card=card.get("name", "?"),
            amount=amount,
            target_player=target_player.name,
            result="player_damage" if dealt else "prevented",
            life_after=target_player.life,
            turn=turn,
        )
    player.graveyard.append(card)


def trigger_spell_cast_engines(
    player,
    all_players,
    spell,
    turn,
    phase,
    *,
    stack=None,
    active_player=None,
):
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict):
            continue
        if permanent.get("trigger") != "spell_cast":
            continue
        mana_amount = int(permanent.get("spell_cast_add_mana") or 0)
        if mana_amount <= 0:
            continue
        mana_color = source_colors({"produces": permanent.get("spell_cast_mana_color") or permanent.get("produces")})
        color = mana_color[0] if mana_color else "generic"

        def resolve_spell_cast_mana_trigger(
            permanent=permanent,
            mana_amount=mana_amount,
            color=color,
        ):
            player.mana_pool.add(color, mana_amount)
            emit_replay_event(
                "trigger_resolved",
                player=player.name,
                card=permanent.get("name", "?"),
                trigger="spell_cast",
                trigger_spell=spell.get("name", "?"),
                effect="add_mana",
                mana_added=mana_amount,
                mana_color=color,
                mana_pool=player.mana_pool.snapshot(),
                turn=turn,
                phase=phase,
                **replay_rule_fields(permanent),
            )

        resolve_or_enqueue_trigger(
            player,
            permanent,
            "spell_cast",
            resolve_spell_cast_mana_trigger,
            stack=stack,
            active_player=active_player,
            all_players=all_players,
        )

    if not (is_instant(spell) or is_sorcery(spell)):
        return
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict):
            continue
        if permanent.get("trigger") != "instant_sorcery_cast":
            continue
        if permanent.get("trigger_effect") != "damage_each_opponent":
            continue
        amount = int(permanent.get("damage") or 2)
        def resolve_spell_cast_trigger(permanent=permanent, amount=amount):
            damaged = []
            for opponent in all_players:
                if opponent == player or not opponent.is_alive():
                    continue
                if deal_damage(opponent, amount):
                    damaged.append({"player": opponent.name, "life_after": opponent.life})
            emit_replay_event(
                "trigger_resolved",
                player=player.name,
                card=permanent.get("name", "?"),
                trigger="instant_sorcery_cast",
                trigger_spell=spell.get("name", "?"),
                effect="damage_each_opponent",
                amount=amount,
                damaged=damaged,
                turn=turn,
                phase=phase,
                **replay_rule_fields(permanent),
            )

        resolve_or_enqueue_trigger(
            player,
            permanent,
            "instant_sorcery_cast",
            resolve_spell_cast_trigger,
            stack=stack,
            active_player=active_player,
            all_players=all_players,
        )


def trigger_opponent_spell_draw_engines(
    caster,
    opponents,
    spell,
    turn,
    phase,
    rng,
    *,
    stack=None,
    active_player=None,
    all_players=None,
):
    spell_effect = get_card_effect(spell).get("effect")
    is_noncreature_spell = spell_effect != "creature"
    for opponent in opponents:
        for permanent in list(opponent.battlefield):
            if not isinstance(permanent, dict):
                continue
            if permanent.get("effect") != "draw_engine":
                continue
            trigger = permanent.get("trigger")
            if trigger not in ("opponent_spell", "opponent_noncreature_spell"):
                continue
            if trigger == "opponent_noncreature_spell" and not is_noncreature_spell:
                continue
            tax = int(permanent.get("tax") or 1)
            def resolve_opponent_draw_trigger(
                opponent=opponent,
                permanent=permanent,
                trigger=trigger,
                tax=tax,
            ):
                # Compact model: caster sometimes pays the tax when spare mana exists.
                can_pay_tax = caster.available_mana() >= tax
                pays_tax = can_pay_tax and rng.random() < 0.35
                if pays_tax:
                    caster.spend_mana(tax)
                    result = "tax_paid"
                else:
                    opponent.draw(1, rng)
                    result = "card_drawn"
                emit_replay_event(
                    "trigger_resolved",
                    player=opponent.name,
                    card=permanent.get("name", "?"),
                    trigger=trigger,
                    trigger_spell=spell.get("name", "?"),
                    effect="draw_cards",
                    result=result,
                    turn=turn,
                    phase=phase,
                    **replay_rule_fields(permanent),
                )

            resolve_or_enqueue_trigger(
                opponent,
                permanent,
                trigger,
                resolve_opponent_draw_trigger,
                stack=stack,
                active_player=active_player,
                all_players=all_players or [caster, *opponents],
            )




def check_ward(target, spell, controller, rng):
    """v9: Ward triggered ability (CR 702.21a).
    If target has ward, spell is countered unless controller pays cost."""
    ward_cost = target.get("ward_cost") or target.get("ward", 0)
    if ward_cost <= 0:
        return False  # No ward
    
    # Ward triggers: AI opponent pays 50% of the time if affordable
    can_pay = controller.available_mana() >= ward_cost
    if not can_pay:
        # Counter the spell (ward resolved)
        emit_replay_event("ward_countered", target=target.get("name"),
                         spell=spell.get("name"), ward_cost=ward_cost)
        return True  # Spell is countered
    
    # Decision: pay or let it be countered
    if controller.is_human or rng.random() < 0.5:
        # Pay ward cost
        controller.spend_mana(ward_cost)
        emit_replay_event("ward_paid", target=target.get("name"),
                         spell=spell.get("name"), ward_cost=ward_cost)
        return False  # Ward paid, spell proceeds
    else:
        emit_replay_event("ward_countered", target=target.get("name"),
                         spell=spell.get("name"), ward_cost=ward_cost)
        return True  # Spell countered by ward


def can_cast_adventure_spell(card, player, phase):
    if not is_adventure_card(card):
        return False
    adventure = adventure_spell_card(card)
    if not is_instant(adventure) and not (is_sorcery(adventure) and phase in MAIN_PHASES):
        return False
    return player.can_pay_card(adventure)


def cast_adventure_spell_from_hand(player, card, opponents, all_players, turn, phase, stack, rng):
    if not can_cast_adventure_spell(card, player, phase):
        return False
    adventure = adventure_spell_card(card)
    effect_data = get_card_effect(adventure)
    if effect_data.get("effect") in ("unknown", "land", "creature"):
        return False
    cast_ctx = begin_cast_context(
        player,
        adventure,
        phase,
        effect_data=effect_data,
        role="adventure",
        modes=["adventure"],
    )
    if not commit_cast_payment(cast_ctx):
        return False
    player.hand.remove(card)
    emit_replay_event(
        "adventure_cast",
        player=player.name,
        card=card.get("name", "?"),
        adventure=adventure.get("name", "?"),
        effect=effect_data.get("effect", "unknown"),
        type_line=adventure.get("type_line", ""),
        turn=turn,
        phase=phase,
        **cast_ctx.to_replay_fields(),
        **replay_rule_fields(effect_data),
    )
    trigger_spell_cast_engines(
        player, all_players, adventure, turn, phase, stack=stack, active_player=player
    )
    trigger_opponent_spell_draw_engines(
        player,
        opponents,
        adventure,
        turn,
        phase,
        rng,
        stack=stack,
        active_player=player,
        all_players=all_players,
    )
    stack.push(adventure, player, effect_data)
    return True


def cast_adventure_creature_from_exile(player, card, turn, phase):
    if phase not in MAIN_PHASES or not isinstance(card, dict) or not card.get("_adventure_available"):
        return False
    if not is_creature_card(card) or not player.can_pay_card(card):
        return False
    effect_data = get_card_effect(card)
    cast_ctx = begin_cast_context(
        player,
        card,
        phase,
        effect_data=effect_data,
        role="adventure_creature",
        modes=["creature_from_exile"],
    )
    if not commit_cast_payment(cast_ctx):
        return False
    player.exile.remove(card)
    permanent = enrich_card({**card, **effect_data})
    permanent.pop("_adventure_available", None)
    permanent.pop("_last_adventure_name", None)
    permanent["effect"] = "creature"
    permanent["haste"] = has_haste(permanent)
    permanent["summoning_sick"] = not permanent["haste"]
    permanent["tapped"] = False
    player.battlefield.append(permanent)
    emit_replay_event(
        "adventure_creature_cast_from_exile",
        player=player.name,
        card=card.get("name", "?"),
        type_line=permanent.get("type_line", ""),
        turn=turn,
        phase=phase,
        **cast_ctx.to_replay_fields(),
        **replay_rule_fields(effect_data),
    )
    return True


def cast_spells_v8(player, opponents, all_players, turn, phase, stack, rng, max_actions=None):
    """v8: Cast spells respecting instant/sorcery timing and stack."""
    mana = player.available_mana()
    if mana <= 0:
        has_free_castable = any(
            not is_effective_land(candidate)
            and player.can_pay_card(candidate)
            and can_cast_in_phase(candidate, get_card_effect(candidate), phase)
            and get_card_effect(candidate).get("effect") not in ("counter", "unknown")
            for candidate in player.hand
        )
        if not has_free_castable:
            return False

    actions_taken = 0

    def note_action():
        nonlocal actions_taken
        actions_taken += 1
        return max_actions is not None and actions_taken >= max_actions

    is_own_turn = (player == all_players[0]) or (turn > 0)
    is_main_phase = phase in ("precombat_main", "postcombat_main")

    def ritual_unlocks_same_turn_action(ritual_card, ritual_effect):
        """One-shot mana is only useful when it unlocks a new same-turn action."""
        if ritual_effect.get("effect") != "ramp_ritual":
            return {"unlocks_same_turn_action": False, "resource_gate": "not_one_shot_ritual"}

        def playable_candidates():
            candidates = []
            if is_main_phase and player.command_zone:
                cmd = player.command_zone[0]
                already_there = any(
                    isinstance(permanent, dict)
                    and permanent.get("name") == cmd.get("name")
                    for permanent in player.battlefield
                )
                if not already_there:
                    candidates.append((cmd, player.commander_tax, "commander"))
            for candidate in player.hand:
                if candidate is ritual_card or is_effective_land(candidate):
                    continue
                candidate_effect = get_card_effect(candidate)
                if candidate_effect.get("effect") in ("counter", "unknown", "ramp_ritual"):
                    continue
                if not can_cast_in_phase(candidate, candidate_effect, phase):
                    continue
                candidates.append((candidate, 0, candidate_effect.get("effect") or "spell"))
            return candidates

        before = {
            (id(candidate), role)
            for candidate, additional_generic, role in playable_candidates()
            if player.can_pay_card(candidate, additional_generic)
        }
        pool_snapshot = player.mana_pool.snapshot()
        restricted_snapshot = copy.deepcopy(player.restricted_mana)
        treasures_snapshot = player.treasures
        life_snapshot = player.life
        try:
            # Keep this check aligned with the current ritual resolution path.
            player.mana_pool.add_generic(ritual_mana_produced(player, ritual_effect))
            for candidate, additional_generic, role in playable_candidates():
                if (id(candidate), role) in before:
                    continue
                if player.can_pay_card(candidate, additional_generic):
                    effect_data = get_card_effect(candidate)
                    return {
                        "unlocks_same_turn_action": True,
                        "resource_gate": "one_shot_ritual_unlock",
                        "unlock_card": candidate.get("name", "?"),
                        "unlock_role": role,
                        "unlock_effect": effect_data.get("effect", "unknown"),
                        "unlock_reason": (
                            "same_turn_commander_cast"
                            if role == "commander"
                            else "same_turn_castable_spell"
                        ),
                    }
            return None
        finally:
            for color, amount in pool_snapshot.items():
                setattr(player.mana_pool, color, amount)
            player.restricted_mana = restricted_snapshot
            player.treasures = treasures_snapshot
            player.life = life_snapshot

    def playable_payoff_candidates(excluded_card=None):
        candidates = []
        if is_main_phase and player.command_zone:
            cmd = player.command_zone[0]
            already_there = any(
                isinstance(permanent, dict)
                and permanent.get("name") == cmd.get("name")
                for permanent in player.battlefield
            )
            if not already_there:
                candidates.append((cmd, player.commander_tax, "commander"))
        for candidate in player.hand:
            if candidate is excluded_card or is_effective_land(candidate):
                continue
            candidate_effect = get_card_effect(candidate)
            effect_name = str(candidate_effect.get("effect") or "unknown")
            if effect_name in ("counter", "unknown", "ramp_ritual", "ramp_permanent", "ramp_engine", "land_ramp", "land_recursion"):
                continue
            if effect_name not in HIGH_IMPACT_PAYOFF_EFFECTS:
                continue
            if not can_cast_in_phase(candidate, candidate_effect, phase):
                continue
            candidates.append((candidate, 0, "high_impact_spell"))
        return candidates

    def _payoff_context(candidate, additional_generic, role):
        effect_data = get_card_effect(candidate)
        locked_cost = card_mana_cost(candidate, additional_generic)
        nominal_cost = int(locked_cost.get("generic") or 0)
        nominal_cost += sum(int(amount or 0) for amount in (locked_cost.get("colored") or {}).values())
        nominal_cost += len(locked_cost.get("hybrid") or [])
        nominal_cost += len(locked_cost.get("phyrexian") or [])
        nominal_cost += len(locked_cost.get("phyrexian_hybrid") or [])
        nominal_cost += sum(
            int(option.get("generic") or 1)
            for option in (locked_cost.get("monocolored_hybrid") or [])
        )
        return {
            "unlock_card": candidate.get("name", "?"),
            "unlock_role": role,
            "unlock_effect": effect_data.get("effect", "unknown"),
            "unlock_reason": (
                "same_turn_commander_cast"
                if role == "commander"
                else "same_turn_high_impact_spell"
            ),
            "unlock_nominal_cost": nominal_cost,
        }

    def restore_mana_snapshot(pool_snapshot, restricted_snapshot, treasures_snapshot, life_snapshot):
        for color, amount in pool_snapshot.items():
            setattr(player.mana_pool, color, amount)
        player.restricted_mana = restricted_snapshot
        player.treasures = treasures_snapshot
        player.life = life_snapshot

    def ramp_permanent_unlocks_meaningful_action(ramp_card, ramp_effect, *, allowed_roles=None):
        """Permanent fast mana may spend scarce land only with immediate payoff."""
        allowed_roles = set(allowed_roles or [])
        produced_mana = mana_source_production_for_state(
            player,
            enrich_card({**ramp_card, **ramp_effect}),
        )
        if produced_mana <= 0:
            return None
        available_after_ramp = player.available_mana() + produced_mana

        def payoff_is_affordable_by_count(candidate, additional_generic):
            # Scarce-land fast mana is intentionally conservative: the
            # simulated payoff must be affordable by raw mana count as well as
            # by the richer payment planner, otherwise replays can claim Mox
            # unlocked a commander that still fails to cast in the real flow.
            locked_cost = card_mana_cost(candidate, additional_generic)
            nominal_cost = int(locked_cost.get("generic") or 0)
            nominal_cost += sum(int(amount or 0) for amount in (locked_cost.get("colored") or {}).values())
            nominal_cost += len(locked_cost.get("hybrid") or [])
            nominal_cost += len(locked_cost.get("phyrexian") or [])
            nominal_cost += len(locked_cost.get("phyrexian_hybrid") or [])
            nominal_cost += sum(
                int(option.get("generic") or 1)
                for option in (locked_cost.get("monocolored_hybrid") or [])
            )
            return available_after_ramp >= nominal_cost

        before = {
            (id(candidate), role)
            for candidate, additional_generic, role in playable_payoff_candidates(ramp_card)
            if not allowed_roles or role in allowed_roles
            if (
                player.can_pay_card(candidate, additional_generic)
                and payoff_is_affordable_by_count(candidate, additional_generic)
            )
        }
        pool_snapshot = player.mana_pool.snapshot()
        restricted_snapshot = copy.deepcopy(player.restricted_mana)
        treasures_snapshot = player.treasures
        life_snapshot = player.life
        try:
            colors = source_colors(enrich_card({**ramp_card, **ramp_effect}))
            player.mana_pool.add(colors[0] if colors else "generic", produced_mana)
            for candidate, additional_generic, role in playable_payoff_candidates(ramp_card):
                if allowed_roles and role not in allowed_roles:
                    continue
                if (id(candidate), role) in before:
                    continue
                if (
                    payoff_is_affordable_by_count(candidate, additional_generic)
                    and player.can_pay_card(candidate, additional_generic)
                ):
                    return {
                        "unlocks_same_turn_action": True,
                        "resource_gate": "permanent_ramp_unlock",
                        **_payoff_context(candidate, additional_generic, role),
                    }
            return None
        finally:
            restore_mana_snapshot(pool_snapshot, restricted_snapshot, treasures_snapshot, life_snapshot)

    def ramp_cast_plan(ramp_card, ramp_effect):
        """Build a payable cast plan for ramp cards with card-specific costs."""
        additional_costs = []
        modes = []
        metadata = {}
        if ramp_effect.get("multikicker_generic_cost"):
            cost = int(ramp_effect.get("multikicker_generic_cost") or 0)
            min_kicks = int(ramp_effect.get("min_kicker_count_for_mana") or 1)
            max_kicks = min(2, player.available_mana() // max(1, cost))
            kicker_count = 0
            for candidate_count in range(max_kicks, min_kicks - 1, -1):
                candidate_costs = everflowing_chalice_additional_costs(candidate_count)
                if player.can_pay(card_mana_cost(ramp_card, additional_costs=candidate_costs)):
                    kicker_count = candidate_count
                    additional_costs = candidate_costs
                    break
            if kicker_count < min_kicks:
                return None
            modes.append(f"multikicker:{kicker_count}")
            metadata["kicker_count"] = kicker_count
        if not player.can_pay(card_mana_cost(ramp_card, additional_costs=additional_costs)):
            return None
        return {
            "additional_costs": additional_costs,
            "modes": modes,
            **metadata,
        }

    def ramp_resource_strategy_context(ramp_card, ramp_effect):
        if ramp_cast_plan(ramp_card, ramp_effect) is None:
            return None
        if ramp_effect.get("requires_imprint_nonartifact_nonland"):
            imprint, _options, _risk_flags, _reason = choose_chrome_mox_imprint_card(
                player,
                ramp_card,
            )
            if not imprint:
                return None
            context = ramp_permanent_unlocks_meaningful_action(ramp_card, ramp_effect)
            if not context:
                return None
            return {
                **context,
                "resource_gate": "imprint_ramp_unlock",
                "imprint_card": imprint.get("name", "?"),
            }
        if ramp_effect.get("effect") == "ramp_ritual":
            return ritual_unlocks_same_turn_action(ramp_card, ramp_effect)
        if ramp_effect.get("requires_sacrifice_land"):
            battlefield_lands = [
                candidate
                for candidate in player.battlefield
                if isinstance(candidate, dict) and is_effective_land(candidate)
            ]
            sacrifice_land, _land_options, strategic_risk_flags, _selection_reason = choose_land_for_resource_cost(
                battlefield_lands,
                zone="battlefield",
            )
            if not sacrifice_land:
                return None
            count = int(ramp_effect.get("land_count") or ramp_effect.get("lands_to_battlefield") or 1)
            _targets, target_options = choose_land_ramp_targets(player, ramp_effect, count)
            allowed, benefit_reason = land_sacrifice_has_strategic_benefit(
                strategic_risk_flags,
                target_options,
                count,
            )
            if not allowed:
                return None
            return {
                "unlocks_same_turn_action": False,
                "resource_gate": "land_sacrifice_ramp",
                "strategic_risk_flags": strategic_risk_flags,
                "strategic_benefit_reason": benefit_reason,
                "resource_land": sacrifice_land.get("name", "?"),
                "target_land": (target_options[0]["name"] if target_options else None),
            }
        if not ramp_effect.get("requires_discard_land"):
            return {
                "unlocks_same_turn_action": False,
                "resource_gate": "ramp_without_scarce_land_cost",
                "strategic_benefit_reason": "no_scarce_land_risk",
            }
        hand_lands = [
            candidate
            for candidate in player.hand
            if isinstance(candidate, dict) and is_land(candidate)
        ]
        discard, _land_options, strategic_risk_flags, _selection_reason = choose_land_for_resource_cost(
            hand_lands,
            zone="hand",
        )
        if not discard:
            return None
        if not (
            "spending_last_land" in strategic_risk_flags
            or "spending_unique_color_land" in strategic_risk_flags
        ):
            return {
                "unlocks_same_turn_action": False,
                "resource_gate": "land_discard_ramp",
                "strategic_risk_flags": strategic_risk_flags,
                "strategic_benefit_reason": "no_scarce_land_risk",
                "resource_land": discard.get("name", "?"),
            }
        context = ramp_permanent_unlocks_meaningful_action(
            ramp_card,
            ramp_effect,
            allowed_roles={"commander"},
        )
        if not context:
            return None
        return {
            **context,
            "resource_gate": "land_discard_ramp",
            "strategic_risk_flags": strategic_risk_flags,
            "resource_land": discard.get("name", "?"),
        }

    # Track counters available (count counterspells in hand)
    player.counters_available = sum(
        1 for c in player.hand
        if c.get("effect") == "counter" or card_has_functional_tag(c, "counter", "protection")
    )

    # 1. Cast commander from command zone (main phase only)
    if is_main_phase and player.command_zone:
        cmd = player.command_zone[0]
        already_there = any(isinstance(c, dict) and c.get("name") == cmd.get("name") for c in player.battlefield)
        if already_there:
            cmd = None
    if is_main_phase and player.command_zone and cmd is not None:
        cmd_eff = get_card_effect(cmd)
        cast_ctx = begin_cast_context(
            player,
            cmd,
            phase,
            additional_generic=player.commander_tax,
            effect_data=cmd_eff,
            role="commander",
        )
        cost = cmd["cmc"] + player.commander_tax
        if commit_cast_payment(cast_ctx):
            player.command_zone.pop(0)
            cmd_copy = enrich_card(cmd)
            haste = has_haste(cmd_copy)
            if is_creature_card(cmd_copy):
                default_stat = max(2, int(float(cmd_copy.get("cmc") or cost or 2)))
                cmd_copy["effect"] = "creature"
                cmd_copy["power"] = cmd_copy.get("power") or default_stat
                cmd_copy["toughness"] = cmd_copy.get("toughness") or cmd_copy.get("power") or default_stat
            cmd_copy["summoning_sick"] = not haste
            cmd_copy["haste"] = haste
            if cmd_eff.get("effect") != "land_recursion_creature":
                player.battlefield.append(cmd_copy)
            player.commander_tax += 2
            fields = replay_rule_fields(cmd_eff)
            commander_score = max(20, int(cost or 0) * 5)
            emit_decision_trace(
                decision_type="cast_spell",
                player=player,
                turn=turn,
                phase=phase,
                available_options=[
                    decision_card_option(
                        cmd,
                        cmd_eff,
                        score=commander_score,
                        action="cast_commander",
                    )
                ],
                chosen_option=decision_card_option(
                    cmd,
                    cmd_eff,
                    score=commander_score,
                    action="cast_commander",
                ),
                rejected_options=[],
                score_components={
                    "commander_tax": player.commander_tax - 2,
                    "effective_cost": cost,
                    "mana_after_payment": player.available_mana(),
                },
                rule_source=fields.get("rule_source", "battle_heuristic"),
                rule_status=fields.get("rule_review_status", "heuristic"),
                confidence="medium",
                expected_benefit_score=commander_score,
                actual_outcome="commander_cast",
                reason="commander_available_and_affordable",
                strategic_principle="cast_commander_when_affordable_and_plan_relevant",
            )
            emit_replay_event(
                "commander_cast",
                player=player.name,
                card=cmd.get("name", "?"),
                effect=cmd_eff.get("effect", "unknown"),
                type_line=cmd_copy.get("type_line", ""),
                cost=cost,
                turn=turn,
                phase=phase,
                **cast_ctx.to_replay_fields(),
                **replay_rule_fields(cmd_eff),
            )
            trigger_spell_cast_engines(
                player, all_players, cmd, turn, phase, stack=stack, active_player=player
            )
            if cmd_eff.get("effect") == "land_recursion_creature":
                resolve_land_recursion_creature(player, cmd_copy, cmd_eff, turn)
            mana = player.available_mana()
            if note_action():
                return True

    if is_main_phase:
        for exiled_card in list(player.exile):
            if cast_warp_card_from_exile(player, exiled_card, turn, phase):
                if note_action():
                    return True
                break
            if cast_adventure_creature_from_exile(player, exiled_card, turn, phase):
                if note_action():
                    return True
                break

        for graveyard_card in list(player.graveyard):
            if cast_flashback_spell_from_graveyard(
                player,
                graveyard_card,
                opponents,
                all_players,
                turn,
                phase,
                stack,
                rng,
            ):
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)
                    if game_winner(all_players):
                        return True
                if note_action():
                    return True
                break

        for warp_card in list(player.hand):
            if cast_warp_spell_from_hand(player, warp_card, turn, phase):
                if note_action():
                    return True
                break

        for adventure_card in list(player.hand):
            if cast_adventure_spell_from_hand(
                player,
                adventure_card,
                opponents,
                all_players,
                turn,
                phase,
                stack,
                rng,
            ):
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)
                    if game_winner(all_players):
                        return True
                if note_action():
                    return True
                break

    # 2. Ramp (main phase only)
    if is_main_phase:
        ramp_contexts = {}
        for candidate in list(player.hand):
            effect = get_card_effect(candidate)
            if ramp_cast_plan(candidate, effect) is None:
                continue
            if effect.get("effect") not in (
                "land_ramp",
                "land_recursion",
                "ramp_permanent",
                "ramp_engine",
                "ramp_ritual",
            ):
                continue
            strategy_context = ramp_resource_strategy_context(candidate, effect)
            if strategy_context is None:
                continue
            ramp_contexts[id(candidate)] = strategy_context
        ramp_cards = [c for c in player.hand if id(c) in ramp_contexts]
        for c in ramp_cards[:2]:
            eff = get_card_effect(c)
            strategy_context = ramp_contexts.get(id(c))
            if (
                c in player.hand
                and ramp_cast_plan(c, eff) is not None
                and strategy_context is not None
            ):
                cast_plan = ramp_cast_plan(c, eff) or {}
                ramp_risk_flags = [
                    flag
                    for flag in (
                        "one_shot_mana"
                        if eff.get("effect") == "ramp_ritual"
                        else None,
                        "requires_land_discard"
                        if eff.get("requires_discard_land")
                        else None,
                        "requires_land_sacrifice"
                        if eff.get("requires_sacrifice_land")
                        else None,
                        "requires_imprint"
                        if eff.get("requires_imprint_nonartifact_nonland")
                        else None,
                        "multikicker_paid"
                        if cast_plan.get("kicker_count")
                        else None,
                    )
                    if flag
                ]
                ramp_risk_flags.extend(
                    flag for flag in (strategy_context.get("strategic_risk_flags") or [])
                    if flag and flag not in ramp_risk_flags
                )
                def ramp_trace_score(option_card, option_context):
                    base_score = max(1, int(option_card.get("cmc", 0) or 0) + 10)
                    if option_context.get("unlocks_same_turn_action"):
                        return base_score + 4
                    if option_context.get("strategic_benefit_reason") in (
                        "high_value_land_target",
                        "untapped_net_mana_upgrade",
                        "flexible_color_fixing",
                    ):
                        return base_score + 2
                    return base_score
                cast_ctx = begin_cast_context(
                    player,
                    c,
                    phase,
                    effect_data=eff,
                    role="ramp",
                    modes=cast_plan.get("modes"),
                    additional_costs=cast_plan.get("additional_costs"),
                )
                if not commit_cast_payment(cast_ctx):
                    continue
                fields = replay_rule_fields(eff)
                emit_decision_trace(
                    decision_type="cast_spell",
                    player=player,
                    turn=turn,
                    phase=phase,
                    available_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=ramp_trace_score(option_card, ramp_contexts[id(option_card)]),
                            action="cast_ramp",
                        )
                        for option_card in ramp_cards[:8]
                    ],
                    chosen_option=decision_card_option(
                        c,
                        eff,
                        score=ramp_trace_score(c, strategy_context),
                        action="cast_ramp",
                    ),
                    rejected_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=ramp_trace_score(option_card, ramp_contexts[id(option_card)]),
                            action="defer_ramp",
                        )
                        for option_card in ramp_cards
                        if option_card is not c
                    ][:8],
                    score_components={
                        "role": "ramp",
                        "mana_before": mana,
                        "ramp_options": len(ramp_cards),
                        "unlocks_same_turn_action": 1 if strategy_context.get("unlocks_same_turn_action") else 0,
                        "unlock_card": strategy_context.get("unlock_card"),
                        "unlock_role": strategy_context.get("unlock_role"),
                        "unlock_reason": strategy_context.get("unlock_reason"),
                        "strategic_benefit_reason": strategy_context.get("strategic_benefit_reason"),
                        "resource_gate": strategy_context.get("resource_gate"),
                        "requires_discard_land": bool(eff.get("requires_discard_land")),
                        "requires_sacrifice_land": bool(eff.get("requires_sacrifice_land")),
                        "requires_imprint_nonartifact_nonland": bool(
                            eff.get("requires_imprint_nonartifact_nonland")
                        ),
                        "multikicker_count": int(cast_plan.get("kicker_count") or 0),
                    },
                    rule_source=fields.get("rule_source", "battle_heuristic"),
                    rule_status=fields.get("rule_review_status", "heuristic"),
                    confidence="medium",
                    expected_benefit_score=ramp_trace_score(c, strategy_context),
                    actual_outcome="cast_and_resolve_ramp",
                    reason="early_mana_development",
                    expected_payoff_reason=(
                        strategy_context.get("unlock_reason")
                        or strategy_context.get("strategic_benefit_reason")
                        or "develop_mana_only_when_it_unlocks_or_preserves_plan"
                    ),
                    strategic_principle=(
                        "spend_ramp_resource_only_when_it_unlocks_or_accelerates_plan"
                    ),
                    heuristic_version=DECISION_STRATEGY_VERSION,
                    resource_delta={
                        "effect": eff.get("effect"),
                        "mana_before": mana,
                        "one_shot_mana": ritual_mana_produced(player, eff)
                        if eff.get("effect") == "ramp_ritual"
                        else 0,
                        "resource_gate": strategy_context.get("resource_gate"),
                        "unlock_card": strategy_context.get("unlock_card"),
                        "unlock_role": strategy_context.get("unlock_role"),
                        "unlock_effect": strategy_context.get("unlock_effect"),
                        "unlock_reason": strategy_context.get("unlock_reason"),
                        "unlock_nominal_cost": strategy_context.get("unlock_nominal_cost"),
                        "strategic_benefit_reason": strategy_context.get("strategic_benefit_reason"),
                        "resource_land": strategy_context.get("resource_land"),
                        "imprint_card": strategy_context.get("imprint_card"),
                        "requires_discard_land": bool(eff.get("requires_discard_land")),
                        "requires_sacrifice_land": bool(eff.get("requires_sacrifice_land")),
                        "requires_imprint_nonartifact_nonland": bool(
                            eff.get("requires_imprint_nonartifact_nonland")
                        ),
                        "multikicker_count": int(cast_plan.get("kicker_count") or 0),
                    },
                    risk_flags=ramp_risk_flags,
                    rejected_reason="deferred_lower_priority_ramp",
                )
                player.hand.remove(c)
                emit_replay_event(
                    "spell_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=c.get("type_line", ""),
                    cmc=c.get("cmc", 0),
                    turn=turn,
                    phase=phase,
                    **cast_ctx.to_replay_fields(),
                    **replay_rule_fields(eff),
                )
                if not pay_additional_card_costs(player, c, eff, turn=turn):
                    player.graveyard.append(c)
                    return False
                trigger_spell_cast_engines(
                    player, all_players, c, turn, phase, stack=stack, active_player=player
                )
                trigger_opponent_spell_draw_engines(
                    player,
                    opponents,
                    c,
                    turn,
                    phase,
                    rng,
                    stack=stack,
                    active_player=player,
                    all_players=all_players,
                )
                if eff.get("effect") == "ramp_ritual":
                    player.mana_pool.add_generic(ritual_mana_produced(player, eff))
                    player.graveyard.append(c)
                elif eff.get("effect") == "land_ramp":
                    put_lands_from_library(player, c, eff, turn, opponents=opponents, source_event="land_ramp")
                    player.graveyard.append(c)
                elif eff.get("effect") == "land_recursion":
                    return_graveyard_lands_to_battlefield(player, c, turn, opponents=opponents)
                    player.graveyard.append(c)
                else:
                    permanent = prepare_entering_permanent(enrich_card({**c, **eff}))
                    if eff.get("multikicker_generic_cost"):
                        kicker_count = int(cast_plan.get("kicker_count") or 0)
                        permanent["charge_counters"] = kicker_count
                        permanent["mana_produced"] = kicker_count
                        emit_replay_event(
                            "multikicker_paid",
                            player=player.name,
                            card=c.get("name", "?"),
                            kicker_count=kicker_count,
                            additional_costs=cast_plan.get("additional_costs") or [],
                            turn=turn,
                            phase=phase,
                        )
                    if eff.get("requires_imprint_nonartifact_nonland"):
                        resolve_chrome_mox_imprint(player, permanent, c, turn=turn)
                    player.battlefield.append(permanent)
                    if is_mana_source_permanent(permanent):
                        colors = source_colors(permanent)
                        produced = mana_source_production_for_state(player, permanent)
                        if produced > 0:
                            player.mana_pool.add(colors[0], produced)
                mana = player.available_mana()
                if note_action():
                    return True

    # 3. Cast spells to stack
    castable = [
        c for c in player.hand
        if not is_effective_land(c)
        and player.can_pay_card(c)
        and get_card_effect(c).get("effect") not in (
            "counter",
            "unknown",
            "ramp_ritual",
            "ramp_permanent",
            "ramp_engine",
            "land_ramp",
            "land_recursion",
        )
    ]
    # v8: Miracle check for Lorehold
    if player.is_human:
        lorehold_on_board = any(isinstance(c, dict) and c.get("name") == "Lorehold, the Historian" for c in player.battlefield)
        for c in castable[:]:
            if (is_sorcery(c) or is_instant(c)) and not is_main_phase:
                if not is_instant(c) or not lorehold_on_board:
                    castable.remove(c)  # can't cast sorcery outside main phase

    # Play spells in priority order
    # v8.2: Play spells needing priority in score order
    # Wincons / high-threat spells first (main phase only)
    if is_main_phase:
        # Sort by threat score (highest first — resolve big plays before small ones)
        scored = [(c, threat_score(get_card_effect(c).get("effect", ""), c.get("name", ""), player, all_players, turn)) for c in castable]
        scored.sort(key=lambda x: -x[1])
        
        wincons = [c for c, s in scored if s >= 50]
        if wincons:
            c = wincons[0]
            if c in player.hand and player.can_pay_card(c):
                eff = get_card_effect(c)
                if eff.get("effect") == "board_wipe" and not should_cast_board_wipe(player, opponents):
                    wincons = []
                elif eff.get("effect") == "worldfire_reset" and not should_cast_worldfire_reset(player, opponents):
                    wincons = []
                elif (
                    eff.get("effect") == "draw_cards"
                    and is_wheel_like_card(c, eff)
                    and not should_cast_wheel(player, opponents, {**eff, "name": c.get("name")})
                ):
                    wincons = []
                elif not additional_card_costs_are_payable(player, c, eff):
                    wincons = []
                if not wincons:
                    c = None
                    eff = None
            if c is not None and c in player.hand and player.can_pay_card(c):
                cast_ctx = begin_cast_context(player, c, phase, effect_data=eff, role="high_threat")
                if not commit_cast_payment(cast_ctx):
                    return False
                chosen_score = next((s for card_item, s in scored if card_item is c), scored[0][1])
                fields = replay_rule_fields(eff)
                emit_decision_trace(
                    decision_type="cast_spell",
                    player=player,
                    turn=turn,
                    phase=phase,
                    available_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=option_score,
                            action="cast",
                        )
                        for option_card, option_score in scored[:8]
                    ],
                    chosen_option=decision_card_option(c, eff, score=chosen_score, action="cast_high_threat"),
                    rejected_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=option_score,
                            action="defer_cast",
                        )
                        for option_card, option_score in scored
                        if option_card is not c
                    ][:8],
                    score_components={
                        "threat_score": chosen_score,
                        "castable_count": len(scored),
                        "mana_before": mana,
                    },
                    rule_source=fields.get("rule_source", "battle_heuristic"),
                    rule_status=fields.get("rule_review_status", "heuristic"),
                    confidence="medium",
                    expected_benefit_score=chosen_score,
                    actual_outcome="cast_to_stack",
                    reason="highest_threat_main_phase_spell",
                )
                player.hand.remove(c)
                emit_replay_event(
                    "spell_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=c.get("type_line", ""),
                    cmc=c.get("cmc", 0),
                    threat_score=scored[0][1],
                    turn=turn,
                    phase=phase,
                    **cast_ctx.to_replay_fields(),
                    **replay_rule_fields(eff),
                )
                if not pay_additional_card_costs(player, c, eff, turn=turn):
                    player.graveyard.append(c)
                    return False
                trigger_spell_cast_engines(
                    player, all_players, c, turn, phase, stack=stack, active_player=player
                )
                trigger_opponent_spell_draw_engines(
                    player,
                    opponents,
                    c,
                    turn,
                    phase,
                    rng,
                    stack=stack,
                    active_player=player,
                    all_players=all_players,
                )
                stack.push(c, player, eff)
                priority_round(player, all_players, stack, turn, rng)
                if game_winner(all_players):
                    return True
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)
                    if game_winner(all_players):
                        return True
                note_action()
                return True

    # Other spells: 2 per phase max
    remaining = sorted([c for c in castable if player.can_pay_card(c)], key=lambda c: c["cmc"])
    played = 0
    for c in remaining:
        if played >= 2: break
        if c in player.hand and player.can_pay_card(c):
            eff = get_card_effect(c)
            if eff.get("effect") == "board_wipe" and not should_cast_board_wipe(player, opponents):
                continue
            if eff.get("effect") == "worldfire_reset" and not should_cast_worldfire_reset(player, opponents):
                continue
            if (
                eff.get("effect") == "draw_cards"
                and is_wheel_like_card(c, eff)
                and not should_cast_wheel(player, opponents, {**eff, "name": c.get("name")})
            ):
                continue
            if eff.get("effect") == "creature":
                if not is_main_phase: continue  # creatures only in main phase
                cast_ctx = begin_cast_context(player, c, phase, effect_data=eff, role="creature")
                if not commit_cast_payment(cast_ctx):
                    continue
                creature_score = threat_score(
                    eff.get("effect", ""),
                    c.get("name", ""),
                    player,
                    all_players,
                    turn,
                )
                fields = replay_rule_fields(eff)
                emit_decision_trace(
                    decision_type="cast_spell",
                    player=player,
                    turn=turn,
                    phase=phase,
                    available_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=threat_score(
                                get_card_effect(option_card).get("effect", ""),
                                option_card.get("name", ""),
                                player,
                                all_players,
                                turn,
                            ),
                            action="cast",
                        )
                        for option_card in remaining[:8]
                    ],
                    chosen_option=decision_card_option(
                        c,
                        eff,
                        score=creature_score,
                        action="cast_creature",
                    ),
                    rejected_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=threat_score(
                                get_card_effect(option_card).get("effect", ""),
                                option_card.get("name", ""),
                                player,
                                all_players,
                                turn,
                            ),
                            action="defer_cast",
                        )
                        for option_card in remaining
                        if option_card is not c
                    ][:8],
                    score_components={
                        "role": "creature",
                        "cmc": c.get("cmc", 0),
                        "remaining_options": len(remaining),
                    },
                    rule_source=fields.get("rule_source", "battle_heuristic"),
                    rule_status=fields.get("rule_review_status", "heuristic"),
                    confidence="medium",
                    expected_benefit_score=creature_score,
                    actual_outcome="creature_to_battlefield",
                    reason="lowest_cmc_castable_creature",
                    expected_payoff_reason="deploy board presence at the best available mana slot",
                )
                player.hand.remove(c)
                c_copy = enrich_card({**c, **eff})
                c_copy["effect"] = "creature"
                c_copy["haste"] = has_haste(c_copy)
                c_copy["summoning_sick"] = not c_copy["haste"]
                c_copy["tapped"] = False
                player.battlefield.append(c_copy)
                emit_replay_event(
                    "creature_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    cmc=c.get("cmc", 0),
                    type_line=c_copy.get("type_line", ""),
                    power=c_copy.get("power"),
                    toughness=c_copy.get("toughness"),
                    effect=eff.get("effect", "creature"),
                    turn=turn,
                    phase=phase,
                    **cast_ctx.to_replay_fields(),
                    **replay_rule_fields(eff),
                )
                if eff.get("etb_land_ramp_count"):
                    etb_eff = {
                        **eff,
                        "land_count": int(eff.get("etb_land_ramp_count") or 1),
                        "requires_sacrifice_land": bool(eff.get("etb_requires_sacrifice_land")),
                    }
                    put_lands_from_library(
                        player,
                        c_copy,
                        etb_eff,
                        turn,
                        opponents=opponents,
                        source_event="etb_land_ramp",
                    )
                if eff.get("etb_draw_count"):
                    player.draw(int(eff.get("etb_draw_count") or 1), rng)
                if eff.get("etb_token_count"):
                    for _ in range(min(int(eff.get("etb_token_count") or 1), 20)):
                        create_creature_token(
                            player,
                            name=eff.get("etb_token_name", "Token"),
                            power=int(eff.get("etb_token_power") or 1),
                            toughness=int(eff.get("etb_token_toughness") or eff.get("etb_token_power") or 1),
                            artifact=bool(eff.get("etb_artifact_tokens")),
                        )
                if eff.get("etb_recursion_count"):
                    target_type = eff.get("etb_recursion_target")
                    destination = eff.get("etb_recursion_destination", "hand")
                    candidates = [
                        grave_card
                        for grave_card in player.graveyard
                        if isinstance(grave_card, dict)
                        and not is_land(grave_card)
                        and (
                            target_type != "creature"
                            or is_creature_card(grave_card)
                        )
                        and (
                            target_type == "creature"
                            or target_type != "instant_or_sorcery"
                            or is_instant_or_sorcery_spell(grave_card)
                        )
                    ]
                    for recovered_card in candidates[: int(eff.get("etb_recursion_count") or 1)]:
                        if recovered_card in player.graveyard:
                            player.graveyard.remove(recovered_card)
                            if destination == "battlefield":
                                permanent_effect = get_card_effect(recovered_card)
                                permanent = enrich_card({**recovered_card, **permanent_effect})
                                if is_creature_card(recovered_card):
                                    permanent["effect"] = "creature"
                                    permanent["haste"] = has_haste(permanent)
                                    permanent["summoning_sick"] = not permanent["haste"]
                                    permanent["tapped"] = False
                                player.battlefield.append(permanent)
                            else:
                                player.hand.append(recovered_card)
                played += 1
                if note_action():
                    return True
            else:
                if not additional_card_costs_are_payable(player, c, eff):
                    continue
                cast_ctx = begin_cast_context(player, c, phase, effect_data=eff, role="normal")
                if not commit_cast_payment(cast_ctx):
                    continue
                normal_score = threat_score(eff.get("effect", ""), c.get("name", ""), player, all_players, turn)
                fields = replay_rule_fields(eff)
                emit_decision_trace(
                    decision_type="cast_spell",
                    player=player,
                    turn=turn,
                    phase=phase,
                    available_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=threat_score(
                                get_card_effect(option_card).get("effect", ""),
                                option_card.get("name", ""),
                                player,
                                all_players,
                                turn,
                            ),
                            action="cast",
                        )
                        for option_card in remaining[:8]
                    ],
                    chosen_option=decision_card_option(c, eff, score=normal_score, action="cast_spell"),
                    rejected_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            score=threat_score(
                                get_card_effect(option_card).get("effect", ""),
                                option_card.get("name", ""),
                                player,
                                all_players,
                                turn,
                            ),
                            action="defer_cast",
                        )
                        for option_card in remaining
                        if option_card is not c
                    ][:8],
                    score_components={
                        "threat_score": normal_score,
                        "cmc": c.get("cmc", 0),
                        "remaining_options": len(remaining),
                    },
                    rule_source=fields.get("rule_source", "battle_heuristic"),
                    rule_status=fields.get("rule_review_status", "heuristic"),
                    confidence="medium",
                    expected_benefit_score=normal_score,
                    actual_outcome="cast_to_stack",
                    reason="lowest_cmc_castable_spell",
                    expected_payoff_reason="advance stack development with the best affordable spell line",
                )
                player.hand.remove(c)
                emit_replay_event(
                    "spell_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=c.get("type_line", ""),
                    cmc=c.get("cmc", 0),
                    turn=turn,
                    phase=phase,
                    **cast_ctx.to_replay_fields(),
                    **replay_rule_fields(eff),
                )
                if not pay_additional_card_costs(player, c, eff, turn=turn):
                    player.graveyard.append(c)
                    continue
                trigger_spell_cast_engines(
                    player, all_players, c, turn, phase, stack=stack, active_player=player
                )
                trigger_opponent_spell_draw_engines(
                    player,
                    opponents,
                    c,
                    turn,
                    phase,
                    rng,
                    stack=stack,
                    active_player=player,
                    all_players=all_players,
                )
                stack.push(c, player, eff)
                played += 1
                if note_action():
                    while not stack.empty():
                        priority_round(player, all_players, stack, turn, rng)
                        if game_winner(all_players):
                            return True
                    return True

# Resolve stack
    while not stack.empty():
        priority_round(player, all_players, stack, turn, rng)
        if game_winner(all_players):
            return True
    return actions_taken > 0


def resolve_composite_resolution_effect(player, opponents, card, effect_data, turn, rng):
    """Resolve opt-in same-spell components without moving the source card twice."""
    applied = []
    skipped = []
    components = effect_data.get("_composite_rule_components") or []
    for index, component in enumerate(components):
        component_effect = component.get("effect")
        component_fields = replay_rule_fields(component)
        outcome = "unsupported_component"
        if component_effect == "draw_cards":
            count = int(component.get("count") or component.get("amount") or component.get("draw_count") or 1)
            player.draw(max(0, count), rng)
            outcome = "cards_drawn"
            applied.append({"effect": component_effect, "count": count})
        elif component_effect == "ramp_ritual":
            produced = ritual_mana_produced(player, component)
            player.mana_pool.add_generic(produced)
            outcome = "ritual_mana_added"
            applied.append({"effect": component_effect, "mana_added": produced})
        elif component_effect == "treasure_maker":
            treasure_count = int(component.get("treasure_count") or 1)
            draw_count = int(component.get("draw_count") or 0)
            player.treasures += treasure_count
            if draw_count > 0:
                player.draw(draw_count, rng)
            outcome = "treasure_created"
            applied.append({
                "effect": component_effect,
                "treasures_created": treasure_count,
                "cards_drawn": draw_count,
            })
        elif component_effect == "token_maker":
            token_count = int(component.get("token_count") or 1)
            token_haste = bool(component.get("token_haste") or component.get("haste"))
            artifact_tokens = bool(component.get("artifact_tokens"))
            for _ in range(min(max(0, token_count), 20)):
                create_creature_token(
                    player,
                    power=component.get("token_power", 2),
                    toughness=component.get("token_toughness", component.get("token_power", 2)),
                    haste=token_haste,
                    artifact=artifact_tokens,
                )
            outcome = "tokens_created"
            applied.append({"effect": component_effect, "tokens_created": token_count})
        elif component_effect == "extra_turn":
            turns = int(component.get("turns") or 1)
            player.extra_turns += turns
            if component.get("lose_after_extra_turn"):
                player.extra_turn_loss_pending += turns
            outcome = "extra_turn_scheduled"
            applied.append({"effect": component_effect, "extra_turns": turns})
        elif component_effect == "extra_combat":
            combats = int(component.get("combats") or component.get("extra_combats") or 1)
            player.extra_combats += max(0, combats)
            if component.get("untap_creatures", True):
                for permanent in player.battlefield:
                    if is_battlefield_creature(permanent):
                        permanent["tapped"] = False
            outcome = "extra_combat_scheduled"
            applied.append({"effect": component_effect, "extra_combats": combats})
        elif component_effect in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg"):
            removed = False
            if resolve_multi_target_removal(player, opponents, card, component, turn, rng):
                removed = True
            else:
                for opp in opponents:
                    target_type = str(component.get("target") or "").lower()
                    if not target_type:
                        target_type = "creature" if component_effect == "remove_creature" else "nonland_permanent"
                    targets = removal_target_candidates(opp, component, controller=player, source=card)
                    if not targets:
                        continue
                    target = choose_best_creature_target(targets)
                    decision = targeting_decision(
                        card,
                        target,
                        player,
                        target_controller=opp,
                        target_type=target_type,
                    )
                    if check_ward(target, card, player, rng):
                        emit_replay_event(
                            "removal_countered_by_ward",
                            player=player.name,
                            card=card.get("name", "?"),
                            target_player=opp.name,
                            target=target.get("name", "?"),
                            component_index=index,
                            turn=turn,
                            **decision,
                        )
                        break
                    destination = move_creature_from_battlefield(opp, target)
                    emit_replay_event(
                        "removal_resolved",
                        player=player.name,
                        card=card.get("name", "?"),
                        target_player=opp.name,
                        target=target.get("name", "?"),
                        target_effect=get_card_effect(target).get("effect", target.get("effect")),
                        target_power=target.get("power"),
                        target_toughness=target.get("toughness"),
                        target_is_creature=is_battlefield_creature(target),
                        target_type_line=target.get("type_line", ""),
                        available_targets=len(targets),
                        destination=destination,
                        component_index=index,
                        turn=turn,
                        **decision,
                    )
                    removed = True
                    break
            outcome = "removal_resolved" if removed else "no_legal_target"
            applied.append({"effect": component_effect, "removed": removed})
        else:
            skipped.append({"effect": component_effect, "reason": "unsupported_component"})

        emit_replay_event(
            "composite_rule_component_resolved",
            player=player.name,
            card=card.get("name", "?"),
            component_index=index,
            component_effect=component_effect,
            outcome=outcome,
            turn=turn,
            **component_fields,
        )
    return {"applied": applied, "skipped": skipped}


def apply_effect_immediate(player, opponents, card, turn, rng):
    """v8: Apply card effect (called when spell resolves from stack)."""
    effect_data = get_card_effect(card)
    effect = effect_data.get("effect", "unknown")
    emit_replay_event(
        "spell_resolved",
        player=player.name,
        card=card.get("name", "?"),
        cmc=card.get("cmc", 0),
        type_line=card.get("type_line", ""),
        effect=effect,
        turn=turn,
        **replay_rule_fields(effect_data),
    )

    if effect == "composite_resolution":
        summary = resolve_composite_resolution_effect(
            player,
            opponents,
            card,
            effect_data,
            turn,
            rng,
        )
        emit_replay_event(
            "composite_rule_resolved",
            player=player.name,
            card=card.get("name", "?"),
            components_applied=len(summary["applied"]),
            components_skipped=len(summary["skipped"]),
            applied=summary["applied"],
            skipped=summary["skipped"],
            turn=turn,
            **replay_rule_fields(effect_data),
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "land": pass
    elif effect == "creature":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "creature"
        player.battlefield.append(permanent)
        if effect_data.get("etb_draw_count"):
            player.draw(int(effect_data.get("etb_draw_count") or 1), rng)
        emit_replay_event(
            "creature_to_battlefield",
            player=player.name,
            card=card.get("name", "?"),
            is_mana_source=bool(permanent.get("is_mana_source")),
            mana_produced=permanent.get("mana_produced"),
            summoning_sick=permanent.get("summoning_sick"),
            turn=turn,
        )
    elif effect == "passive":
        if is_instant(card) or is_sorcery(card):
            finish_resolved_spell(player, card, turn=turn)
        else:
            permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
            permanent["effect"] = "passive"
            player.battlefield.append(permanent)
    elif effect == "ramp_permanent":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            finish_resolved_spell(player, card, turn=turn)
            return
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        player.battlefield.append(permanent)
    elif effect == "ramp_ritual":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            finish_resolved_spell(player, card, turn=turn)
            return
        player.mana_pool.add_generic(ritual_mana_produced(player, effect_data))
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "ramp_engine":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "ramp_engine"
        player.battlefield.append(permanent)
        treasure_count = int(effect_data.get("enters_treasure") or 0)
        player.treasures += treasure_count
    elif effect == "draw_engine":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "draw_engine"
        player.battlefield.append(permanent)
        player.draw_engines += 1
        player.draw(1, rng)
    elif effect == "cantrip_mana_filter_artifact":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "cantrip_mana_filter_artifact"
        player.battlefield.append(permanent)
        emit_replay_event(
            "cantrip_mana_filter_artifact_resolved",
            player=player.name,
            card=card.get("name", "?"),
            activation_cost_generic=effect_data.get("activation_cost_generic"),
            draw_on_self_sacrifice=effect_data.get("draw_on_self_sacrifice"),
            battle_model_scope=effect_data.get("battle_model_scope"),
            turn=turn,
        )
    elif effect == "land_recursion_creature":
        resolve_land_recursion_creature(player, card, effect_data, turn)
    elif effect == "draw_cards":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            finish_resolved_spell(player, card, turn=turn)
            return
        n = effect_data.get("count", 2)
        if is_wheel_like_card(card, effect_data):
            wheel_draw_count = wheel_like_draw_count(
                card,
                effect_data,
                player=player,
                opponents=opponents,
            )
            context = wheel_decision_context(player, opponents, wheel_draw_count)
            risk_flags = []
            if (
                context["opponent_refill_risk"] > 0
                and not context["wheel_payoffs"]
                and not context["timing_justified"]
            ):
                risk_flags.append("opponent_refill_risk")
            if context["model_scope"] != "multiplayer_discard_draw_v1":
                risk_flags.append("wheel_model_simplified")
            expected_score = max(
                0,
                context["net_cards_for_player"] * 10
                - context["total_opponent_net_cards"] * 4
                + (25 if context["wheel_payoffs"] else 0),
            )
            emit_decision_trace(
                decision_type="wheel",
                player=player,
                turn=turn,
                phase="resolution",
                available_options=[
                    decision_card_option(card, effect_data, action="resolve_wheel"),
                    {"action": "defer_wheel_not_available_after_resolution"},
                ],
                chosen_option=decision_card_option(card, effect_data, action="resolve_wheel"),
                rejected_options=[{"action": "defer_wheel_not_available_after_resolution"}],
                score_components=context,
                rule_source=replay_rule_fields(effect_data).get("rule_source", "battle_heuristic"),
                rule_status=replay_rule_fields(effect_data).get("rule_review_status", "heuristic"),
                confidence="low" if "wheel_model_simplified" in risk_flags else "medium",
                expected_benefit_score=expected_score,
                actual_outcome="multiplayer_discard_draw_resolved",
                reason="wheel_like_draw_resolution",
                strategic_principle="wheel_only_when_refill_or_payoff_outweighs_opponent_refill",
                heuristic_version=DECISION_STRATEGY_VERSION,
                resource_delta=context,
                risk_flags=risk_flags,
                rejected_reason="spell_already_resolving",
            )
        if is_wheel_like_card(card, effect_data):
            resolve_wheel_like_draw(
                player,
                opponents,
                card,
                wheel_like_draw_count(
                    card,
                    effect_data,
                    player=player,
                    opponents=opponents,
                ),
                turn,
                rng,
            )
        else:
            drawn = player.draw(n, rng)
            emit_replay_event(
                "draw_cards_resolved",
                player=player.name,
                card=card.get("name", "?"),
                cards_drawn=len(drawn),
                requested_draw_count=int(n or 0),
                library_remaining=len(player.library),
                hand_size=len(player.hand),
                turn=turn,
                **replay_rule_fields(effect_data),
            )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "hand_filter":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            finish_resolved_spell(player, card, turn=turn)
            return
        resolve_hand_filter(player, card, effect_data, turn, rng)
    elif effect == "treasure_maker":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            finish_resolved_spell(player, card, turn=turn)
            return
        treasure_count = int(effect_data.get("treasure_count") or 1)
        player.treasures += treasure_count
        draw_count = int(effect_data.get("draw_count") or 0)
        if draw_count > 0:
            player.draw(draw_count, rng)
        emit_replay_event(
            "treasure_created",
            player=player.name,
            card=card.get("name", "?"),
            treasures_created=treasure_count,
            treasures=player.treasures,
            cards_drawn=draw_count,
            turn=turn,
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "lander_token_maker":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            finish_resolved_spell(player, card, turn=turn)
            return
        life_gain = int(effect_data.get("life_gain") or 0)
        if life_gain > 0:
            gain_life(player, life_gain)
        token_count = int(effect_data.get("token_count") or 1)
        for _ in range(max(0, min(token_count, 5))):
            create_lander_token(player)
        emit_replay_event(
            "lander_token_created",
            player=player.name,
            card=card.get("name", "?"),
            tokens_created=token_count,
            life_gained=life_gain,
            turn=turn,
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "land_ramp":
        put_lands_from_library(player, card, effect_data, turn, opponents=opponents, source_event="land_ramp")
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "land_recursion":
        return_graveyard_lands_to_battlefield(player, card, turn, opponents=opponents)
        finish_resolved_spell(player, card, turn=turn)
    elif effect in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg"):
        if resolve_multi_target_removal(player, opponents, card, effect_data, turn, rng):
            finish_resolved_spell(player, card, turn=turn)
            return
        for opp in opponents:
            target_type = str(effect_data.get("target") or "").lower()
            if not target_type:
                target_type = "creature" if effect == "remove_creature" else "nonland_permanent"
            targets = removal_target_candidates(opp, effect_data, controller=player, source=card)
            if targets:
                t = choose_best_creature_target(targets)
                decision = targeting_decision(
                    card,
                    t,
                    player,
                    target_controller=opp,
                    target_type=target_type,
                )
                if check_ward(t, card, player, rng):
                    emit_replay_event(
                        "removal_countered_by_ward",
                        player=player.name,
                        card=card.get("name", "?"),
                        target_player=opp.name,
                        target=t.get("name", "?"),
                        turn=turn,
                        **decision,
                    )
                    finish_resolved_spell(player, card, turn=turn)
                    return
                if effect_data.get("target_controller_gains_life"):
                    gain_life(opp, int(effect_data.get("target_controller_gains_life") or 0))
                if effect_data.get("uses_stat_modifier_removal"):
                    try:
                        power_delta = int(effect_data.get("power_boost") or 0)
                    except Exception:
                        power_delta = 0
                    try:
                        toughness_delta = int(effect_data.get("toughness_boost") or 0)
                    except Exception:
                        toughness_delta = 0
                    remember_until_eot(t, "power")
                    remember_until_eot(t, "toughness")
                    t["power"] = int(t.get("power") or 0) + power_delta
                    t["toughness"] = int(t.get("toughness") or 0) + toughness_delta
                    emit_replay_event(
                        "removal_resolved",
                        player=player.name,
                        card=card.get("name", "?"),
                        target_player=opp.name,
                        target=t.get("name", "?"),
                        target_effect=get_card_effect(t).get("effect", t.get("effect")),
                        target_power=t.get("power"),
                        target_toughness=t.get("toughness"),
                        target_is_creature=is_battlefield_creature(t),
                        target_type_line=t.get("type_line", ""),
                        available_targets=len(targets),
                        result="stat_modifier_until_eot_applied",
                        power_delta=power_delta,
                        toughness_delta=toughness_delta,
                        turn=turn,
                        **decision,
                    )
                    break
                emit_replay_event(
                    "removal_resolved",
                    player=player.name,
                    card=card.get("name", "?"),
                    target_player=opp.name,
                    target=t.get("name", "?"),
                    target_effect=get_card_effect(t).get("effect", t.get("effect")),
                    target_power=t.get("power"),
                    target_toughness=t.get("toughness"),
                    target_is_creature=is_battlefield_creature(t),
                    target_type_line=t.get("type_line", ""),
                    available_targets=len(targets),
                    turn=turn,
                    **decision,
                )
                move_permanent_from_battlefield(opp, t)
                break
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "deal_damage":
        apply_direct_damage(player, opponents, card, effect_data, turn, rng)
    elif effect == "equipment_haste_shroud":
        apply_equipment_haste_shroud(player, card, effect_data, turn)
    elif effect == "board_wipe":
        context = board_wipe_decision_context(player, opponents)
        risk_flags = []
        if not context["timing_justified"]:
            risk_flags.append("wipe_without_timing_justification")
        elif (
            context["asymmetry"] <= 0
            and not context["lethal_pressure"]
            and not context["rebuild_plan"]
            and not context["behind_on_board"]
        ):
            risk_flags.append("wipe_without_clear_asymmetry")
        fields = replay_rule_fields(effect_data)
        emit_decision_trace(
            decision_type="board_wipe",
            player=player,
            turn=turn,
            phase="resolution",
            available_options=[
                decision_card_option(card, effect_data, action="resolve_board_wipe"),
                {"action": "defer_wipe_not_available_after_resolution"},
            ],
            chosen_option=decision_card_option(card, effect_data, action="resolve_board_wipe"),
            rejected_options=[{"action": "defer_wipe_not_available_after_resolution"}],
            score_components=context,
            rule_source=fields.get("rule_source", "battle_heuristic"),
            rule_status=fields.get("rule_review_status", "heuristic"),
            confidence="medium",
            expected_benefit_score=(
                max(0, context["asymmetry"] * 10)
                + (40 if context["lethal_pressure"] else 0)
                + (20 if context["behind_on_board"] else 0)
                + (15 if context["rebuild_plan"] else 0)
            ),
            actual_outcome="board_wipe_resolved",
            reason="reset_board_state",
            strategic_principle="wipe_when_behind_under_lethal_pressure_or_asymmetric",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta=context,
            risk_flags=risk_flags,
            rejected_reason="spell_already_resolving",
        )
        destroyed = 0
        protected = 0
        creatures_seen = 0
        unprotected_seen = 0
        for p in [player] + list(opponents):
            survivors = []
            destroyed_cards = []
            for c in list(p.battlefield):
                if is_battlefield_creature(c):
                    creatures_seen += 1
                    # v8: indestructible per-creature
                    if c.get("indestructible"):
                        survivors.append(c)
                        protected += 1
                        continue
                    unprotected_seen += 1
                    destroyed_cards.append(c)
                    destroyed += 1
                else:
                    survivors.append(c)
            p.battlefield = survivors
            for c in destroyed_cards:
                move_creature_from_battlefield(p, c)
        emit_replay_event(
            "board_wipe_resolved",
            player=player.name,
            card=card.get("name", "?"),
            destroyed=destroyed,
            protected=protected,
            creatures_seen=creatures_seen,
            unprotected_seen=unprotected_seen,
            turn=turn,
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "worldfire_reset":
        context = worldfire_decision_context(player, opponents)
        risk_flags = []
        if not context["known_follow_up_line"]:
            risk_flags.append("worldfire_without_known_win_line")
        if context["treasures_lost_to_reset"] > 0:
            risk_flags.append("worldfire_exiles_treasure_stockpile")
        fields = replay_rule_fields(effect_data)
        emit_decision_trace(
            decision_type="worldfire_reset",
            player=player,
            turn=turn,
            phase="resolution",
            available_options=[
                decision_card_option(card, effect_data, action="resolve_worldfire_reset"),
                {"action": "defer_worldfire_not_available_after_resolution"},
            ],
            chosen_option=decision_card_option(card, effect_data, action="resolve_worldfire_reset"),
            rejected_options=[{"action": "defer_worldfire_not_available_after_resolution"}],
            score_components=context,
            rule_source=fields.get("rule_source", "battle_heuristic"),
            rule_status=fields.get("rule_review_status", "heuristic"),
            confidence="medium" if context["known_follow_up_line"] else "low",
            expected_benefit_score=95 if context["known_follow_up_line"] else 5,
            actual_outcome="worldfire_reset_resolved",
            reason="global_reset_requires_post_reset_win_line",
            strategic_principle="resolve_worldfire_only_with_known_post_reset_win_line",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta=context,
            risk_flags=risk_flags,
            rejected_reason="spell_already_resolving",
        )
        participants = [participant for participant in [player] + list(opponents) if participant.is_alive()]
        summary = []
        for participant in participants:
            zone_summary = {
                "player": participant.name,
                "battlefield_exiled": 0,
                "hand_exiled": 0,
                "graveyard_exiled": 0,
                "commanders_to_command_zone": 0,
                "tokens_vanished": 0,
                "life_before": participant.life,
                "life_after": participant.life,
            }
            for permanent in list(participant.battlefield):
                destination = move_zone_object_to_exile(
                    participant,
                    "battlefield",
                    permanent,
                    reason="worldfire",
                    source=card,
                    turn=turn,
                )
                if destination == "command_zone":
                    zone_summary["commanders_to_command_zone"] += 1
                elif destination == "vanished_token":
                    zone_summary["tokens_vanished"] += 1
                else:
                    zone_summary["battlefield_exiled"] += 1
            for hand_card in list(participant.hand):
                destination = move_zone_object_to_exile(
                    participant,
                    "hand",
                    hand_card,
                    reason="worldfire",
                    source=card,
                    turn=turn,
                )
                if destination == "command_zone":
                    zone_summary["commanders_to_command_zone"] += 1
                else:
                    zone_summary["hand_exiled"] += 1
            for grave_card in list(participant.graveyard):
                destination = move_zone_object_to_exile(
                    participant,
                    "graveyard",
                    grave_card,
                    reason="worldfire",
                    source=card,
                    turn=turn,
                )
                if destination == "command_zone":
                    zone_summary["commanders_to_command_zone"] += 1
                else:
                    zone_summary["graveyard_exiled"] += 1
            participant.treasures = 0
            if participant.life != 1:
                change_life(participant, 1 - participant.life)
            zone_summary["life_after"] = participant.life
            participant.draw_engines = 0
            participant.copy_engines = 0
            participant.counters_available = 0
            summary.append(zone_summary)
        emit_replay_event(
            "worldfire_resolved",
            player=player.name,
            card=card.get("name", "?"),
            participants=summary,
            turn=turn,
            **replay_rule_fields(effect_data),
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "phase_out":
        player.phased_out = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") not in ("land",)]
        player.battlefield = [c for c in player.battlefield if c == "land" or (isinstance(c, dict) and c.get("effect") == "land")]
        player.life_cant_change = True
        player.protection_from_everything = True
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "phase_creatures":
        targets = [c for c in player.battlefield if is_battlefield_creature(c)]
        player.phased_out.extend(targets)
        player.battlefield = [c for c in player.battlefield if c not in targets]
        emit_replay_event(
            "phase_creatures_resolved",
            player=player.name,
            card=card.get("name", "?"),
            phased=[c.get("name", "?") for c in targets],
            turn=turn,
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "cannot_lose_turn":
        player.cannot_lose_this_turn = True
        player.damage_life_floor = int(effect_data.get("life_floor_on_damage") or 1)
        emit_replay_event(
            "cannot_lose_turn_resolved",
            player=player.name,
            card=card.get("name", "?"),
            life_floor_on_damage=player.damage_life_floor,
            turn=turn,
            **replay_rule_fields(effect_data),
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "silence_opponents":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "silence_opponents"
        player.battlefield.append(permanent)
        player.silenced_opponents = True
    elif effect == "silence_spell":
        player.silenced_opponents_until_eot = True
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "indestructible":
        grant_creatures_until_eot(player, keywords=("indestructible",))
        player.indestructible = True
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "protect_creature":
        targets = [creature for creature in player.battlefield if is_battlefield_creature(creature)]
        if targets:
            target = choose_best_creature_target(targets)
            if effect_data.get("untap"):
                target["tapped"] = False
            remember_until_eot(target, "power")
            remember_until_eot(target, "toughness")
            target["power"] = int(target.get("power") or 0) + int(effect_data.get("power_boost") or 0)
            target["toughness"] = int(target.get("toughness") or 0) + int(effect_data.get("toughness_boost") or 0)
            set_until_eot(target, "shroud", True)
            emit_replay_event(
                "protection_resolved",
                player=player.name,
                card=card.get("name", "?"),
                target=target.get("name", "?"),
                grants=["shroud"],
                turn=turn,
            )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "modal_boros_charm":
        response_to = card.get("_response_to_effect")
        preferred_mode = card.get("preferred_mode")
        if preferred_mode == "double_strike" and response_to != "board_wipe":
            grant_creatures_until_eot(player, keywords=("double_strike",))
        else:
            grant_creatures_until_eot(player, keywords=("indestructible",))
            player.indestructible = True
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "approach":
        player.approach_count += 1
        gain_life(player, 7)
        # v8.1: THREAT — all opponents now know Approach was cast
        player.threat_level += 50  # massive threat spike
        for opp in opponents:
            if player.name not in opp.approach_revealed:
                opp.approach_revealed.append(player.name)
        if player.approach_count >= 2:
            blocked_by_grace = any(
                opp.is_alive() and getattr(opp, "cannot_lose_this_turn", False)
                for opp in opponents
            )
            if not blocked_by_grace:
                player.win_reason = "approach"
                emit_replay_event(
                    "game_won",
                    player=player.name,
                    reason="approach",
                    turn=turn,
                )
            else:
                emit_replay_event(
                    "game_win_prevented",
                    player=player.name,
                    reason="opponents_cannot_win_this_turn",
                    card=card.get("name", "?"),
                    turn=turn,
                )
            finish_resolved_spell(player, card, turn=turn)
            return
        if len(player.library) >= 7:
            player.library.insert(6, card)
        else:
            player.library.append(card)
    elif effect == "steal_all_creatures":
        total_power = 0
        for opp in opponents:
            creatures = [c for c in opp.battlefield if is_battlefield_creature(c)]
            for c in creatures:
                total_power += c.get("power", 2)
            opp.battlefield = [c for c in opp.battlefield if not is_battlefield_creature(c)]
        finish_resolved_spell(player, card, turn=turn)
        alive_opps = [o for o in opponents if o.is_alive()]
        if alive_opps and total_power > 0:
            dmg_each = total_power // len(alive_opps)
            for opp in alive_opps:
                deal_damage(opp, dmg_each)
    elif effect == "token_maker":
        token_count = effect_data.get("token_count", 5)
        if isinstance(token_count, str):
            if token_count == "life_total": token_count = player.life // 2
            elif token_count == "lands": token_count = controlled_land_count(player)
        token_count = int(token_count)
        token_haste = bool(effect_data.get("token_haste") or effect_data.get("haste"))
        artifact_tokens = bool(effect_data.get("artifact_tokens"))
        for _ in range(min(token_count, 20)):
            create_creature_token(
                player,
                power=effect_data.get("token_power", 2),
                toughness=effect_data.get("token_toughness", effect_data.get("token_power", 2)),
                haste=token_haste,
                artifact=artifact_tokens,
            )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "copy_creature_token":
        resolve_copy_creature_token(player, card, effect_data, turn)
    elif effect == "overload_recursion":
        spells = [c for c in player.graveyard if isinstance(c, dict) and c.get("cmc", 0) > 0]
        if player.copy_engines > 0: spells = spells * 2
        dmg = len(spells) * 3
        alive_opps = [o for o in opponents if o.is_alive()]
        if alive_opps:
            for opp in alive_opps: deal_damage(opp, dmg // len(alive_opps))
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "recursion":
        count = int(effect_data.get("count") or 2)
        target_type = effect_data.get("target")
        candidates = [
            grave_card
            for grave_card in player.graveyard
            if isinstance(grave_card, dict)
            and not is_land(grave_card)
            and (
                target_type != "creature"
                or is_creature_card(grave_card)
            )
            and (
                target_type == "creature"
                or is_instant(grave_card)
                or is_sorcery(grave_card)
                or get_card_effect(grave_card).get("effect") not in ("land", "unknown")
            )
        ]
        recovered = candidates[:count]
        destination = effect_data.get("destination", "hand")
        for recovered_card in recovered:
            if recovered_card in player.graveyard:
                player.graveyard.remove(recovered_card)
                if destination == "battlefield":
                    permanent_effect = get_card_effect(recovered_card)
                    permanent = enrich_card({**recovered_card, **permanent_effect})
                    if is_creature_card(recovered_card):
                        permanent["effect"] = "creature"
                        permanent["haste"] = has_haste(permanent)
                        permanent["summoning_sick"] = not permanent["haste"]
                        permanent["tapped"] = False
                    player.battlefield.append(permanent)
                else:
                    player.hand.append(recovered_card)
        emit_replay_event(
            "recursion_resolved",
            player=player.name,
            card=card.get("name", "?"),
            recovered=[recovered_card.get("name", "?") for recovered_card in recovered],
            destination=destination,
            turn=turn,
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "pump_all":
        kw = effect_data.get("keywords", [])
        combat_keywords = [
            keyword
            for keyword in ("flying", "double_strike", "lifelink", "indestructible")
            if keyword in kw
        ]
        power_multiplier = effect_data.get("power_multiplier")
        if power_multiplier is None and card.get("name") != "Akroma's Will":
            power_multiplier = 2
        grant_creatures_until_eot(
            player,
            keywords=combat_keywords,
            power_multiplier=power_multiplier,
        )
        if "indestructible" in combat_keywords:
            player.indestructible = True
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "copy_spell":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "copy_spell"
        player.battlefield.append(permanent)
        player.copy_engines += 1
    elif effect == "tutor":
        target_type = effect_data.get("target", "any")
        found = None
        candidates = []
        for c in player.library:
            if target_type == "any":
                candidates.append(c)
            elif target_type == "artifact_or_enchantment":
                # v8.3: Enlightened Tutor — finds Artifact or Enchantment by type_line
                tl = c.get("type_line", "")
                if ("Artifact" in tl or "Enchantment" in tl) and c.get("name") != "Approach of the Second Sun":
                    candidates.append(c)
            elif target_type == "land":
                if is_effective_land(c):
                    candidates.append(c)
            elif target_type in ("graveyard", "graveyard_nonlegendary"):
                if target_type == "graveyard" or "legendary" not in str(c.get("type_line") or "").lower():
                    candidates.append(c)
            elif target_type in ("creature", "creature_to_battlefield"):
                if is_creature_card(c):
                    candidates.append(c)
            elif target_type == "instant_or_sorcery":
                if is_instant_or_sorcery_spell(c):
                    candidates.append(c)
            elif target_type in ("green_creature", "green_creature_to_battlefield"):
                if is_creature_card(c) and card_has_color(c, "G"):
                    candidates.append(c)
        if candidates:
            scored_candidates = [
                (
                    candidate,
                    *tutor_candidate_score(candidate, target_type, player, opponents, turn),
                )
                for candidate in candidates
            ]
            scored_candidates.sort(key=lambda item: (-item[1], -int(float(item[0].get("cmc") or 0)), item[0].get("name", "")))
            found, found_score, found_reason = scored_candidates[0]
        else:
            scored_candidates = []
            found_score = 0
            found_reason = "no_candidate"
        fields = replay_rule_fields(effect_data)
        destination_preview = tutor_destination_for_target_type(target_type) if found else None
        emit_decision_trace(
            decision_type="tutor",
            player=player,
            turn=turn,
            phase="resolution",
            available_options=[
                decision_card_option(
                    candidate,
                    get_card_effect(candidate),
                    score=score,
                    action="tutor_candidate",
                    target_type=target_type,
                    destination=tutor_destination_for_target_type(target_type),
                    reason=reason,
                )
                for candidate, score, reason in scored_candidates[:10]
            ],
            chosen_option=decision_card_option(
                found,
                get_card_effect(found) if found else None,
                score=found_score,
                action="tutor_target" if found else "no_target",
                target_type=target_type,
                destination=destination_preview,
                reason=found_reason,
            ),
            rejected_options=[
                decision_card_option(
                    candidate,
                    get_card_effect(candidate),
                    score=score,
                    action="reject_tutor_candidate",
                    target_type=target_type,
                    destination=tutor_destination_for_target_type(target_type),
                    reason=reason,
                )
                for candidate, score, reason in scored_candidates[1:10]
            ],
            score_components={
                "target_type": target_type,
                "candidate_count": len(candidates),
                "selected_reason": found_reason,
                "lands": controlled_land_count(player),
                "opponent_creatures": sum(
                    battlefield_creature_stats(opp)["count"]
                    for opp in opponents
                    if opp.is_alive()
                ),
            },
            rule_source=fields.get("rule_source", "battle_heuristic"),
            rule_status=fields.get("rule_review_status", "heuristic"),
            confidence="medium" if found else "low",
            expected_benefit_score=found_score,
            actual_outcome="tutor_target_selected" if found else "no_target_found",
            reason=found_reason,
            strategic_principle="tutor_for_mana_interaction_engine_or_wincon_by_game_state",
            heuristic_version=DECISION_STRATEGY_VERSION,
            resource_delta={
                "target_type": target_type,
                "destination": destination_preview,
                "selected": found.get("name", "?") if found else None,
            },
            risk_flags=[] if found else ["no_tutor_target"],
            rejected_reason="lower_contextual_tutor_score",
        )
        if found:
            player.library.remove(found)
            if target_type in ("graveyard", "graveyard_nonlegendary"):
                player.graveyard.append(found)
                destination = "graveyard"
            elif str(target_type).endswith("_to_battlefield"):
                permanent_effect = get_card_effect(found)
                permanent = enrich_card({**found, **permanent_effect})
                if is_creature_card(found):
                    permanent["effect"] = "creature"
                    permanent["haste"] = has_haste(permanent)
                    permanent["summoning_sick"] = not permanent["haste"]
                    permanent["tapped"] = False
                player.battlefield.append(permanent)
                destination = "battlefield"
            else:
                player.hand.append(found)
                destination = "hand"
        else:
            destination = None
        emit_replay_event(
            "tutor_resolved",
            player=player.name,
            card=card.get("name", "?"),
            target_type=target_type,
            found=found.get("name", "?") if found else None,
            destination=destination,
            turn=turn,
        )
        if effect_data.get("exiles_self"):
            move_to_exile(player, card, reason="spell_exiles_self", turn=turn)
        else:
            finish_resolved_spell(player, card, turn=turn)
    elif effect == "topdeck_manipulation":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "topdeck_manipulation"
        player.battlefield.append(permanent)
        player.draw(1, rng)
    elif effect == "life_artifact":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "life_artifact"
        player.battlefield.append(permanent)
        emit_replay_event(
            "life_artifact_resolved",
            player=player.name,
            card=card.get("name", "?"),
            sacrifice_land_gain_life=effect_data.get("sacrifice_land_gain_life"),
            turn=turn,
        )
    elif effect == "hate_artifact":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "hate_artifact"
        player.battlefield.append(permanent)
        emit_replay_event(
            "hate_artifact_resolved",
            player=player.name,
            card=card.get("name", "?"),
            counters_free_spells=bool(effect_data.get("counters_free_spells")),
            sacrifice_draw=effect_data.get("sacrifice_draw"),
            turn=turn,
        )
    elif effect == "loot":
        n = effect_data.get("count", 1)
        drawn = player.draw(n, rng)
        discarded_cards = []
        for _ in range(min(n, len(player.hand))):
            if player.hand:
                discarded_cards.append(player.hand.pop(rng.randint(0, len(player.hand) - 1)))
        discard_resolution = resolve_effect_discard_cards(player, discarded_cards)
        emit_replay_event(
            "loot_resolved",
            player=player.name,
            card=card.get("name", "?"),
            cards_drawn=[drawn_card.get("name", "?") for drawn_card in drawn if isinstance(drawn_card, dict)],
            discarded_to_top=[entry.get("name", "?") for entry in discard_resolution["to_top"]],
            discarded_to_graveyard=[
                entry.get("name", "?") for entry in discard_resolution["to_graveyard"]
            ],
            replacement_used=discard_resolution["used_replacement"],
            turn=turn,
            **replay_rule_fields(effect_data),
        )
    elif effect == "finisher":
        creatures = [c for c in player.battlefield if is_battlefield_creature(c)]
        total_power = sum(c.get("power", 2) for c in creatures)
        if total_power > 0:
            alive_opps = [o for o in opponents if o.is_alive()]
            if alive_opps:
                deal_damage(rng.choice(alive_opps), total_power)
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "extra_turn":
        turns = int(effect_data.get("turns") or 1)
        player.extra_turns += turns
        if effect_data.get("lose_after_extra_turn"):
            player.extra_turn_loss_pending += turns
        emit_replay_event(
            "extra_turn_scheduled",
            player=player.name,
            card=card.get("name", "?"),
            extra_turns=player.extra_turns,
            lose_after_extra_turn=bool(effect_data.get("lose_after_extra_turn")),
            turn=turn,
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "extra_combat":
        combats = int(effect_data.get("combats") or effect_data.get("extra_combats") or 1)
        player.extra_combats += max(0, combats)
        if effect_data.get("untap_creatures", True):
            for permanent in player.battlefield:
                if is_battlefield_creature(permanent):
                    permanent["tapped"] = False
        emit_replay_event(
            "extra_combat_scheduled",
            player=player.name,
            card=card.get("name", "?"),
            extra_combats=player.extra_combats,
            untap_creatures=bool(effect_data.get("untap_creatures", True)),
            turn=turn,
        )
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "exile_value":
        # Dance with Calamity — exile top X, play for free
        X = max(3, player.available_mana() // 2)
        player.draw(min(X, 3), rng)
        finish_resolved_spell(player, card, turn=turn)
    elif effect == "redirect_removal":
        grant_creatures_until_eot(player, keywords=("indestructible",))
        player.indestructible = True
        finish_resolved_spell(player, card, turn=turn)

    elif effect == "ripple_engine":
        # Thrumming Stone — gives all spells ripple 4
        permanent = enrich_card({**card, **effect_data})
        permanent["effect"] = "ripple_engine"
        player.battlefield.append(permanent)
        player.copy_engines += 1  # reuse copy counter for ripple tracking

    elif effect == "dragons_approach":
        # Dragon's Approach — 3 damage to each opponent per copy
        # Count copies in graveyard for bonus damage
        grave_copies = sum(1 for c in player.graveyard if isinstance(c, dict) and c.get("name") == "Dragon's Approach")
        total_damage = 3 + grave_copies  # +3 per copy in grave
        for opp in opponents:
            if opp.is_alive():
                deal_damage(opp, total_damage)
        
        # Ripple: after casting, reveal top 4 and cast matching spells for free
        has_ripple = any(isinstance(c, dict) and c.get("effect") == "ripple_engine" for c in player.battlefield)
        if has_ripple and player.library:
            ripple_count = min(4, len(player.library))
            extra_casts = 0
            for i in range(ripple_count):
                if i >= len(player.library): break
                c = player.library[i]
                if isinstance(c, dict) and c.get("name") == "Dragon's Approach":
                    extra_casts += 1
                    # Cast it for free — deal damage again
                    for opp in opponents:
                        if opp.is_alive():
                            deal_damage(opp, total_damage)
                    # Remove from library
                    player.library.pop(i)
            if extra_casts > 0:
                print(f"  [RIPPLE] Cast {extra_casts} extra Dragon's Approach!")
        
        finish_resolved_spell(player, card, turn=turn)

    elif effect == "combo" and card.get("name") == "Dualcaster Mage":
        # Dualcaster enters, check if Twinflame is on the stack or was just cast
        # If another creature exists on board, the combo can fire
        creatures = [c for c in player.battlefield if is_battlefield_creature(c)]
        if creatures:
            # Check if Twinflame is in graveyard (was just used) OR in hand
            twinflame_used = any(c.get("name") == "Twinflame" for c in player.graveyard)
            twinflame_hand = any(c.get("name") == "Twinflame" for c in player.hand)
            if twinflame_used or twinflame_hand:
                # COMBO FIRES! Infinite hasty 2/2 tokens
                # Create enough tokens to kill all opponents
                total_opp_life = sum(o.life for o in opponents if o.is_alive())
                tokens_needed = max(1, total_opp_life // 2)  # 2/2 tokens
                for _ in range(min(tokens_needed, 50)):  # cap at 50 tokens
                    player.battlefield.append({
                        "name": "Dualcaster Token", "cmc": 0, "tag": "token",
                        "effect": "creature", "power": 2, "toughness": 2,
                        "haste": True, "summoning_sick": False,
                    })
                # Attack with all tokens immediately
                total_power = tokens_needed * 2
                alive_opps = [o for o in opponents if o.is_alive()]
                if alive_opps:
                    dmg_each = total_power // len(alive_opps)
                    for opp in alive_opps:
                        deal_damage(opp, dmg_each)
                print(f"  [COMBO] Dualcaster+Twinflame = {tokens_needed} hasty 2/2s! {total_power} total damage")
        
        permanent = enrich_card(dict(card))
        permanent["effect"] = "creature"
        permanent["haste"] = True
        permanent["summoning_sick"] = False
        permanent["tapped"] = False
        player.battlefield.append(permanent)

def beginning_of_combat_step(attacker, opponents, all_players, turn, rng, stack):
    emit_replay_event(
        "combat_step",
        step="beginning_of_combat",
        active_player=attacker.name,
        turn=turn,
    )
    run_priority_loop(attacker, all_players, stack, turn, "beginning_of_combat", rng)


def must_attack_if_able(creature):
    return bool(
        creature.get("must_attack")
        or creature.get("must_attack_if_able")
        or creature.get("must_attack_each_combat_if_able")
        or creature.get("attacks_each_combat_if_able")
    )


def cant_attack_alone(creature):
    return bool(
        creature.get("cant_attack_alone")
        or creature.get("cannot_attack_alone")
        or creature.get("can't_attack_alone")
    )


def should_attack_with_creature(creature):
    try:
        attack_power = int(creature.get("power", 0) or 0)
    except (TypeError, ValueError):
        attack_power = 0
    return attack_power > 0 or creature.get("attack_trigger") or must_attack_if_able(creature)


def apply_basic_attack_requirements(candidates):
    if len(candidates) == 1 and cant_attack_alone(candidates[0]):
        return []
    return candidates


def declare_attackers_step(attacker, opponents, turn):
    creatures = attacker.untapped_creatures()
    if not creatures:
        return None

    attackers = apply_basic_attack_requirements(
        [creature for creature in creatures if should_attack_with_creature(creature)]
    )
    if not attackers:
        return None

    for creature in attackers:
        if not has_vigilance(creature):
            creature["tapped"] = True

    alive_defenders = [o for o in opponents if o.is_alive()]
    if not alive_defenders:
        return None

    total_power = sum(a.get("power", 2) for a in attackers)
    lethal_targets = [opp for opp in alive_defenders if opp.life <= total_power]
    known_approach_casters = [
        opp for opp in alive_defenders if opp.name in attacker.approach_revealed
    ]

    # Visible lethal is always the best attack. Known alternate-win threats follow.
    if lethal_targets:
        target = min(lethal_targets, key=lambda opp: opp.life)
        target_reason = "lethal"
    elif known_approach_casters:
        target = max(
            known_approach_casters,
            key=lambda opp: (opp.approach_count, opp.threat_level, -opp.life),
        )
        target_reason = "known_approach"
    elif attacker.strategy in ("aggro", "rush"):
        target = min(alive_defenders, key=lambda o: o.life)
        target_reason = "aggro_low_life"
    elif attacker.strategy == "control":
        target = max(
            alive_defenders,
            key=lambda opp: (
                opp.threat_level,
                sum(
                    card.get("power", 0)
                    for card in opp.battlefield
                    if is_battlefield_creature(card)
                ),
                -opp.life,
            ),
        )
        target_reason = "control_high_threat"
    else:
        target = min(
            alive_defenders,
            key=lambda opp: (
                opp.life,
                -opp.threat_level,
                -sum(
                    card.get("power", 0)
                    for card in opp.battlefield
                    if is_battlefield_creature(card)
                ),
            ),
        )
        target_reason = "default_low_life"

    emit_decision_trace(
        decision_type="combat_attack",
        player=attacker,
        turn=turn,
        phase="combat",
        available_options=[
            {
                "action": "attack_player",
                "target": defender.name,
                "life": defender.life,
                "threat_level": defender.threat_level,
                "creatures": len(defender.creatures_for_blocking()),
                "approach_count": defender.approach_count,
            }
            for defender in alive_defenders
        ],
        chosen_option={
            "action": "attack_player",
            "target": target.name,
            "reason": target_reason,
        },
        rejected_options=[
            {
                "action": "reject_attack_target",
                "target": defender.name,
                "life": defender.life,
                "threat_level": defender.threat_level,
            }
            for defender in alive_defenders
            if defender is not target
        ],
        score_components={
            "attackers": len(attackers),
            "total_power": total_power,
            "target_life_before": target.life,
            "target_reason": target_reason,
            "multi_defender_available": int(len(alive_defenders) > 1),
        },
        rule_source="battle_heuristic",
        rule_status="heuristic",
        confidence="medium",
        expected_benefit_score=total_power,
        actual_outcome="attackers_declared",
        reason=target_reason,
    )

    emit_replay_event(
        "combat_step",
        step="declare_attackers",
        attacker=attacker.name,
        target=target.name,
        target_reason=target_reason,
        attackers=len(attackers),
        attackers_detail=[replay_card_snapshot(card) for card in attackers],
        turn=turn,
    )
    attack_groups = assign_attackers_to_defenders(
        attacker,
        attackers,
        alive_defenders,
        target,
        target_reason,
    )
    if len(attack_groups) > 1:
        emit_replay_event(
            "multi_defender_attack",
            attacker=attacker.name,
            groups=[
                {
                    "target": defender.name,
                    "attackers": [card.get("name", "?") for card in group_attackers],
                }
                for defender, group_attackers in attack_groups
            ],
            turn=turn,
        )
    return attackers, alive_defenders, target, target_reason, attack_groups


def assign_attackers_to_defenders(attacker, attackers, alive_defenders, primary_target, target_reason):
    """Allow Commander free-for-all attacks against multiple defending players."""
    if (
        len(alive_defenders) <= 1
        or len(attackers) <= 1
        or target_reason in ("lethal", "known_approach")
    ):
        return [(primary_target, list(attackers))]

    if attacker.strategy in ("aggro", "rush"):
        ordered_defenders = sorted(alive_defenders, key=lambda defender: defender.life)
    elif attacker.strategy == "control":
        ordered_defenders = sorted(
            alive_defenders,
            key=lambda defender: (
                -defender.threat_level,
                -sum(
                    card.get("power", 0)
                    for card in defender.battlefield
                    if is_battlefield_creature(card)
                ),
                defender.life,
            ),
        )
    else:
        ordered_defenders = sorted(
            alive_defenders,
            key=lambda defender: (defender.life, -defender.threat_level),
        )

    grouped = {defender.name: [defender, []] for defender in ordered_defenders}
    for index, creature in enumerate(
        sorted(attackers, key=lambda card: card.get("power", 2), reverse=True)
    ):
        defender = ordered_defenders[index % len(ordered_defenders)]
        grouped[defender.name][1].append(creature)
    return [
        (defender, group_attackers)
        for defender, group_attackers in grouped.values()
        if group_attackers
    ]


def combat_instant_removal_window(attacker, alive_defenders, attackers, turn, rng):
    # v8: Instant-speed removal window after attackers are declared.
    for opp in alive_defenders:
        if opp.is_human:
            continue
        removals = [
            c for c in opp.hand
            if get_card_effect(c).get("effect") in ("remove_creature",)
            and opp.can_pay_card(c)
        ]
        if removals and rng.random() < 0.3:
            c = rng.choice(removals)
            if c in opp.hand and opp.can_pay_card(c):
                opp.hand.remove(c)
                opp.spend_card_mana(c)
                valid_attackers = [
                    attacker_card
                    for attacker_card in attackers
                    if attacker_card in attacker.battlefield
                    and not attacker_card.get("shroud")
                    and not attacker_card.get("protection_from_everything")
                ]
                if valid_attackers:
                    eff = get_card_effect(c)
                    target = choose_best_creature_target(valid_attackers)
                    emit_replay_event(
                        "instant_removal",
                        player=opp.name,
                        card=c.get("name", "?"),
                        effect=eff.get("effect", "unknown"),
                        target_player=attacker.name,
                        target=target.get("name", "?"),
                        target_power=target.get("power"),
                        target_toughness=target.get("toughness"),
                        attackers_before=len(attackers),
                        turn=turn,
                        **replay_rule_fields(eff),
                    )
                    attackers.remove(target)
                    move_creature_from_battlefield(attacker, target)


def declare_blockers_step(target, attackers, turn, rng):
    # Only the attacked player can block. Multiple blockers may gang-block one attacker.
    block_assignments = []
    assigned_blockers = []
    for a in sorted(attackers, key=lambda creature: creature.get("power", 2), reverse=True):
        available = [
            blocker
            for blocker in target.creatures_for_blocking()
            if blocker not in assigned_blockers
            and (
                not a.get("flying")
                or blocker.get("flying")
                or blocker.get("reach")
            )
        ]
        lethal_attack = target.life <= a.get("power", 2)
        if not available or (not lethal_attack and rng.random() >= 0.35):
            block_assignments.append((a, []))
            continue
        blockers = []
        combined_power = 0
        for blocker in sorted(available, key=lambda creature: creature.get("power", 2), reverse=True):
            blockers.append(blocker)
            combined_power += blocker.get("power", 2)
            if combined_power >= a.get("toughness", a.get("power", 2)):
                break
        can_kill_attacker = combined_power >= a.get("toughness", a.get("power", 2))
        if not can_kill_attacker:
            blockers = blockers[:1] if lethal_attack else []
        elif not lethal_attack:
            attack_damage = a.get("power", 2)
            estimated_losses = 0
            for blocker in blockers:
                lethal_to_blocker = 1 if a.get("deathtouch") else blocker.get(
                    "toughness", blocker.get("power", 2)
                )
                if attack_damage >= lethal_to_blocker:
                    estimated_losses += 1
                    attack_damage -= lethal_to_blocker
            # Avoid an automatic full-board suicide unless it prevents lethal.
            if estimated_losses == len(blockers):
                blockers = []
        assigned_blockers.extend(blockers)
        block_assignments.append((a, blockers))
    emit_replay_event(
        "combat_step",
        step="declare_blockers",
        defender=target.name,
        attackers=len(attackers),
        blockers=sum(len(blockers) for _, blockers in block_assignments),
        multi_blocks=sum(1 for _, blockers in block_assignments if len(blockers) > 1),
        turn=turn,
    )
    return block_assignments


def combat_stat(card, key, fallback):
    try:
        return int(card.get(key, fallback))
    except (TypeError, ValueError):
        return fallback


def combat_lethal_damage_required(attacking_creature, blocker, marked_damage=None):
    if attacking_creature.get("deathtouch"):
        return 1
    marked_damage = marked_damage or {}
    already_marked = (
        marked_damage.get(id(blocker), 0)
        if hasattr(marked_damage, "get")
        else 0
    )
    return max(
        0,
        combat_stat(blocker, "toughness", combat_stat(blocker, "power", 2))
        - already_marked,
    )


def combat_damage_assignment_order(attacking_creature, blockers, marked_damage=None):
    """Deterministic attacker-side damage assignment order for multi-blocks."""
    def explicit_order(blocker):
        raw = blocker.get("damage_assignment_order", blocker.get("_damage_assignment_order"))
        if raw is None:
            return None
        try:
            return int(raw)
        except (TypeError, ValueError):
            return None

    def order_key(blocker):
        explicit = explicit_order(blocker)
        return (
            explicit is None,
            explicit if explicit is not None else 0,
            combat_lethal_damage_required(attacking_creature, blocker, marked_damage),
            -combat_stat(blocker, "power", 2),
            str(blocker.get("name", "")),
        )

    return sorted(blockers, key=order_key)


def combat_damage_steps(attacker, opponents, target, attackers, block_assignments, turn):
    combat_target_life_before = target.life
    combat_attacker_life_before = attacker.life

    def deal_player_damage(creature, damage=None):
        damage = combat_stat(creature, "power", 2) if damage is None else damage
        damage_dealt = deal_damage(target, damage)
        if damage_dealt and creature.get("lifelink"):
            gain_life(attacker, damage)
        if damage_dealt and creature.get("is_commander") and creature.get("owner") == attacker.name:
            source_key = commander_damage_key(target.name, creature, attacker.name)
            attacker.commander_damage_by_source[source_key] += damage
            attacker.commander_damage[target.name] += damage

    marked_damage = defaultdict(int)
    deathtouch_damage = set()

    def deals_in_phase(creature, first_strike_phase):
        if first_strike_phase:
            return creature.get("first_strike") or creature.get("double_strike")
        return not creature.get("first_strike") or creature.get("double_strike")

    def mark_damage(source, damaged, amount):
        if amount <= 0:
            return
        marked_damage[id(damaged)] += amount
        if source.get("deathtouch"):
            deathtouch_damage.add(id(damaged))

    def destroy_lethal_creatures():
        for owner, creatures in ((attacker, attackers), (target, target.creatures_for_blocking())):
            for creature in list(creatures):
                lethal = (
                    marked_damage[id(creature)]
                    >= combat_stat(
                        creature,
                        "toughness",
                        combat_stat(creature, "power", 2),
                    )
                    or id(creature) in deathtouch_damage
                )
                if lethal and not creature.get("indestructible") and creature in owner.battlefield:
                    move_creature_from_battlefield(owner, creature)

    def combat_damage_step(first_strike_phase):
        for attacking_creature, declared_blockers in block_assignments:
            if attacking_creature not in attacker.battlefield:
                continue
            surviving_blockers = [
                blocker for blocker in declared_blockers if blocker in target.battlefield
            ]

            if deals_in_phase(attacking_creature, first_strike_phase):
                remaining = combat_stat(attacking_creature, "power", 2)
                if not declared_blockers:
                    deal_player_damage(attacking_creature, remaining)
                else:
                    for blocker in combat_damage_assignment_order(
                        attacking_creature,
                        surviving_blockers,
                        marked_damage,
                    ):
                        lethal_needed = combat_lethal_damage_required(
                            attacking_creature,
                            blocker,
                            marked_damage,
                        )
                        assigned_damage = min(remaining, lethal_needed)
                        mark_damage(attacking_creature, blocker, assigned_damage)
                        remaining -= assigned_damage
                    if attacking_creature.get("trample") and remaining > 0:
                        deal_player_damage(attacking_creature, remaining)

            for blocker in surviving_blockers:
                if deals_in_phase(blocker, first_strike_phase):
                    mark_damage(
                        blocker,
                        attacking_creature,
                        combat_stat(blocker, "power", 2),
                    )

        destroy_lethal_creatures()

    if any(
        creature.get("first_strike") or creature.get("double_strike")
        for creature in attackers + target.creatures_for_blocking()
    ):
        emit_replay_event(
            "combat_step",
            step="first_strike_damage",
            attacker=attacker.name,
            target=target.name,
            turn=turn,
        )
        combat_damage_step(first_strike_phase=True)
    emit_replay_event(
        "combat_step",
        step="combat_damage",
        attacker=attacker.name,
        target=target.name,
        turn=turn,
    )
    combat_damage_step(first_strike_phase=False)

    # Check for commander damage kill
    for name, _, _ in commander_damage_lethal_entries(attacker):
        for opp in opponents:
            if opp.name == name:
                opp.life = 0

    emit_replay_event(
        "combat_result",
        attacker=attacker.name,
        target=target.name,
        target_life_after=target.life,
        attacker_life_after=attacker.life,
        damage_to_player=max(0, combat_target_life_before - target.life),
        target_life_before=combat_target_life_before,
        target_life_cant_change=bool(target.life_cant_change),
        target_protection_from_everything=bool(target.protection_from_everything),
        attackers_survived=sum(1 for card in attackers if card in attacker.battlefield),
        blockers_survived=len(target.creatures_for_blocking()),
        target_dead=not target.is_alive(),
        turn=turn,
    )


def trigger_end_of_combat(all_players, active_player, turn, stack):
    """Queue generic beginning-of-end-of-combat triggered abilities."""
    for controller in all_players:
        for permanent in list(controller.battlefield):
            if not isinstance(permanent, dict) or permanent.get("trigger") != "end_of_combat":
                continue
            effect = permanent.get("trigger_effect") or permanent.get("effect") or "none"
            draw_count = int(permanent.get("trigger_draw_count") or permanent.get("draw_count") or 0)
            life_gain = int(permanent.get("trigger_life_gain") or permanent.get("life_gain") or 0)

            def resolve_end_combat_trigger(
                controller=controller,
                permanent=permanent,
                effect=effect,
                draw_count=draw_count,
                life_gain=life_gain,
            ):
                drawn = []
                gained = 0
                if effect in ("draw", "end_of_combat_draw") and draw_count > 0:
                    drawn = controller.draw(draw_count)
                if effect in ("gain_life", "end_of_combat_gain_life") and life_gain > 0:
                    before = controller.life
                    gain_life(controller, life_gain)
                    gained = max(0, controller.life - before)
                emit_replay_event(
                    "trigger_resolved",
                    player=controller.name,
                    card=permanent.get("name", "?"),
                    trigger="end_of_combat",
                    effect=effect,
                    cards_drawn=len(drawn),
                    life_gained=gained,
                    turn=turn,
                )

            resolve_or_enqueue_trigger(
                controller,
                permanent,
                "end_of_combat",
                resolve_end_combat_trigger,
                stack=stack,
                active_player=active_player,
                all_players=all_players,
                data={
                    "trigger_effect": effect,
                    "trigger_draw_count": draw_count,
                    "trigger_life_gain": life_gain,
                },
            )


def end_of_combat_step(attacker, all_players, turn, rng, stack):
    emit_replay_event(
        "combat_step",
        step="end_of_combat",
        active_player=attacker.name,
        turn=turn,
    )
    trigger_end_of_combat(all_players, attacker, turn, stack)
    flush_triggers_in_apnap(attacker, all_players, stack)
    run_priority_loop(attacker, all_players, stack, turn, "end_of_combat", rng)


def combat_phase_v8(attacker, opponents, all_players, turn, rng, stack):
    beginning_of_combat_step(attacker, opponents, all_players, turn, rng, stack)
    declared = declare_attackers_step(attacker, opponents, turn)
    if not declared:
        return
    attackers, alive_defenders, target, target_reason, attack_groups = declared
    for attacking_creature in list(attackers):
        resolve_attack_artifact_tutor_trigger(
            attacker,
            attacking_creature,
            alive_defenders,
            all_players,
            turn,
            phase="combat",
        )

    total_power = sum(a.get("power", 2) for a in attackers)
    combat_instant_removal_window(attacker, alive_defenders, attackers, turn, rng)
    if not attackers:
        return

    live_attack_groups = [
        (group_target, [card for card in group_attackers if card in attackers])
        for group_target, group_attackers in attack_groups
    ]
    live_attack_groups = [
        (group_target, group_attackers)
        for group_target, group_attackers in live_attack_groups
        if group_attackers
    ]
    if not live_attack_groups:
        return

    grouped_block_assignments = [
        (group_target, group_attackers, declare_blockers_step(group_target, group_attackers, turn, rng))
        for group_target, group_attackers in live_attack_groups
    ]
    block_assignments = [
        assignment
        for _, _, group_assignments in grouped_block_assignments
        for assignment in group_assignments
    ]
    combat_target_life_before = target.life
    combat_attacker_life_before = attacker.life

    emit_replay_event(
        "combat",
        attacker=attacker.name,
        target=target.name,
        target_reason=target_reason,
        target_life_before=combat_target_life_before,
        attacker_life_before=combat_attacker_life_before,
        target_life_cant_change=bool(target.life_cant_change),
        target_protection_from_everything=bool(target.protection_from_everything),
        defenders=[
            {
                "name": defender.name,
                "life": defender.life,
                "threat_level": defender.threat_level,
                "creatures": len(defender.creatures_for_blocking()),
                "approach_count": defender.approach_count,
            }
            for defender in alive_defenders
        ],
        attackers=len(attackers),
        attackers_detail=[replay_card_snapshot(card) for card in attackers],
        attack_groups=[
            {
                "target": group_target.name,
                "attackers": [replay_card_snapshot(card) for card in group_attackers],
            }
            for group_target, group_attackers in live_attack_groups
        ],
        blockers=sum(len(blockers) for _, blockers in block_assignments),
        blockers_detail=[
            {
                "attacker": replay_card_snapshot(attacking_creature),
                "blockers": [replay_card_snapshot(blocker) for blocker in blockers],
            }
            for attacking_creature, blockers in block_assignments
        ],
        multi_blocks=sum(1 for _, blockers in block_assignments if len(blockers) > 1),
        total_power=total_power,
        turn=turn,
    )

    for group_target, group_attackers, group_block_assignments in grouped_block_assignments:
        combat_damage_steps(
            attacker,
            opponents,
            group_target,
            group_attackers,
            group_block_assignments,
            turn,
        )
    end_of_combat_step(attacker, all_players, turn, rng, stack)

def play_turn_v8(player, opponents, all_players, turn, rng, stack):
    """v8: Full turn with priority windows between phases."""
    global CURRENT_REPLAY_TURN
    CURRENT_REPLAY_TURN = turn
    if game_winner(all_players):
        return
    emit_replay_event(
        "turn_start",
        player=player.name,
        turn=turn,
        life=player.life,
        hand=len(player.hand),
        board=len(player.battlefield),
    )
    player.lands_played_this_turn = 0
    player.cards_drawn_this_turn = 0
    clear_until_eot(player)
    player.indestructible = False

    # ── UNTAP ──
    for c in player.battlefield:
        if isinstance(c, dict):
            c["tapped"] = False
            c["utility_land_used_this_turn"] = False
            c["utility_artifact_used_this_turn"] = False
            if is_battlefield_creature(c):
                c["summoning_sick"] = False
    # Return phased out permanents (v7 fix: should be upkeep, keeping simple here)
    player.battlefield.extend(player.phased_out)
    player.phased_out = []
    player.life_cant_change = False
    player.protection_from_everything = False
    player.refresh_mana_sources(turn)
    process_upkeep_utility_lands(player, turn)

    # ── UPKEEP (v8.3: The One Ring burden = draw 1 per turn if on board) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and c.get("burden"):
            for _ in range(sum(1 for _ in player.battlefield if isinstance(_, dict) and _.get("effect") == "draw_engine")):
                player.draw(1, rng)
    process_lorehold_opponent_upkeep_rummage(player, all_players, turn, rng, stack)
    activate_lorehold_topdeck_artifacts(
        player,
        turn,
        rng,
        phase="upkeep",
        all_players=all_players,
        stack=stack,
    )

    # ── DRAW ──
    drawn_for_turn = player.draw(1, rng)
    if check_sbas(all_players):
        return

    try_lorehold_miracle_cast(
        player,
        drawn_for_turn,
        turn,
        "draw_step",
        all_players,
        rng,
        stack,
        source="draw_step",
    )

    # ── PRECOMBAT MAIN ──
    total_mana = player.available_mana()
    lands_in_hand = [c for c in player.hand if is_effective_land(c)]  # v10.2
    if lands_in_hand and player.lands_played_this_turn < player.max_lands_per_turn:
        land = lands_in_hand[0]
        eff = get_card_effect(land)
        player.hand.remove(land)
        land_permanent = enrich_card({**land, **eff, "effect": "land"})
        initialize_special_land_runtime_state(land_permanent, turn)
        player.battlefield.append(land_permanent)
        player.lands_played_this_turn += 1
        player.mana_pool.add(
            source_colors(land_permanent)[0],
            int(land_permanent.get("mana_produced") or 1),
        )
        trigger_landfall(
            player,
            land_permanent,
            turn,
            "land_played",
            opponents=opponents,
            stack=stack,
            active_player=player,
            all_players=all_players,
        )
        trigger_opponent_land_play_engines(
            player,
            opponents,
            land_permanent,
            turn,
            stack=stack,
            all_players=all_players,
        )
        emit_replay_event(
            "land_played",
            player=player.name,
            card=land.get("name", "?"),
            effect=eff.get("effect", "land"),
            turn=turn,
            **replay_rule_fields(eff),
        )
        while not stack.empty() or _pending_triggers:
            priority_round(player, all_players, stack, turn, rng)
    activate_land_tutor_creatures(player, turn)
    activate_precombat_utility_mana_lands(
        player,
        opponents,
        all_players,
        turn,
        phase="precombat_main",
    )
    activate_sacrifice_mana_artifacts(
        player,
        opponents,
        all_players,
        turn,
        phase="precombat_main",
    )
    activate_utility_artifacts(
        player,
        opponents,
        all_players,
        turn,
        rng,
        phase="precombat_main",
    )
    run_priority_loop(player, all_players, stack, turn, "precombat_main", rng)
    if game_winner(all_players):
        return
    if check_sbas(all_players): return

    # ── TRIGGER: Smothering Tithe on opponent draws (during draw step above) ──
    for opp in opponents:
        if opp.is_alive():
            for c in opp.battlefield:
                if isinstance(c, dict) and c.get("effect") == "ramp_engine" and c.get("trigger") == "opponent_draw":
                    c["counter"] = c.get("counter", 0) + 1
                    # Creates a Treasure token (simplified as +1 treasure)
                    opp.treasures += 1


    # ── COMBAT ──
    if turn > 1:
        combat_phase_v8(player, opponents, all_players, turn, rng, stack)
        if game_winner(all_players):
            return
        if check_sbas(all_players): return
        extra_combats_taken = 0
        while (
            player.is_alive()
            and player.extra_combats > 0
            and not game_winner(all_players)
            and extra_combats_taken < 3
        ):
            player.extra_combats -= 1
            extra_combats_taken += 1
            emit_replay_event(
                "extra_combat_taken",
                player=player.name,
                turn=turn,
                extra_combat_index=extra_combats_taken,
                remaining_extra_combats=player.extra_combats,
            )
            combat_phase_v8(player, opponents, all_players, turn, rng, stack)
            if game_winner(all_players):
                return
            if check_sbas(all_players): return
        if player.extra_combats > 0 and extra_combats_taken >= 3:
            emit_replay_event(
                "extra_combat_cap_reached",
                player=player.name,
                turn=turn,
                remaining_extra_combats=player.extra_combats,
                cap=3,
            )

    # ── POSTCOMBAT MAIN ──
    total_mana = player.available_mana()
    run_priority_loop(player, all_players, stack, turn, "postcombat_main", rng)
    activate_utility_artifacts(
        player,
        opponents,
        all_players,
        turn,
        rng,
        phase="postcombat_main",
    )
    activate_utility_lands(player, turn, rng, phase="postcombat_main")
    if game_winner(all_players):
        return
    if check_sbas(all_players): return


    # ── END STEP (v8.3) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and not c.get("burden"):
            player.draw(1, rng)
    process_warp_end_step(player, turn)
    process_end_step_token_sacrifices(player, turn)
    
    # ── OPPONENT END STEP INTERACTION (NEW) ──
    # All opponents can cast instants on this player's end step
    if not (player.silenced_opponents or player.silenced_opponents_until_eot):
        for opp in opponents:
            if not opp.is_alive(): continue
            instants_in_hand = [
                c for c in opp.hand
                if not is_effective_land(c)
                and is_instant(c)
                and is_modeled_battle_card(c)
                and opp.can_pay_card(c)
            ]
            for c in instants_in_hand[:1]:  # 1 instant per opponent per end step
                if opp.can_pay_card(c):
                    eff = get_card_effect(c)
                    opp.hand.remove(c)
                    opp.spend_card_mana(c)
                    emit_replay_event(
                        "end_step_instant",
                        player=opp.name,
                        card=c.get("name", "?"),
                        effect=eff.get("effect", "unknown"),
                        type_line=c.get("type_line", ""),
                        instant_speed_reason="flash" if card_has_keyword(c, "flash") else "instant",
                        active_player=player.name,
                        turn=turn,
                        **replay_rule_fields(eff),
                    )
                    apply_effect_immediate(opp, [p for p in all_players if p != opp], c, turn, rng)


    # ── CLEANUP ──
    discarded = 0
    while len(player.hand) > 7 and not player_has_no_maximum_hand_size(player):
        worst = max(player.hand, key=lambda c: c.get("cmc", 0))
        player.hand.remove(worst)
        player.graveyard.append(worst)
        discarded += 1

    emit_replay_event(
        "turn_end",
        player=player.name,
        turn=turn,
        life=player.life,
        hand=len(player.hand),
        board=len(player.battlefield),
        graveyard=len(player.graveyard),
        discarded=discarded,
    )

    for participant in all_players:
        clear_until_eot(participant)

    # v8: SBA check at end of turn
    check_sbas(all_players)


def play_turn_sequence_v8(player, opponents, all_players, turn, rng, stack, max_extra_turns=5):
    """Play a normal turn, then any extra turns that player has earned."""
    play_turn_v8(player, opponents, all_players, turn, rng, stack)
    extra_turns_taken = 0
    while (
        player.is_alive()
        and player.extra_turns > 0
        and not game_winner(all_players)
        and extra_turns_taken < max_extra_turns
    ):
        player.extra_turns -= 1
        extra_turns_taken += 1
        emit_replay_event(
            "extra_turn_taken",
            player=player.name,
            turn=turn,
            extra_turn_index=extra_turns_taken,
            remaining_extra_turns=player.extra_turns,
        )
        play_turn_v8(player, opponents, all_players, turn, rng, stack)
        if player.extra_turn_loss_pending > 0 and player.is_alive() and not player.has_won():
            player.extra_turn_loss_pending -= 1
            player.life = 0
            emit_replay_event(
                "game_lost",
                player=player.name,
                reason="delayed_extra_turn_loss",
                turn=turn,
            )
            check_sbas(all_players)
            break
        check_sbas(all_players)
    if player.extra_turns > 0 and extra_turns_taken >= max_extra_turns:
        emit_replay_event(
            "extra_turn_cap_reached",
            player=player.name,
            turn=turn,
            remaining_extra_turns=player.extra_turns,
            cap=max_extra_turns,
        )


def simulate_game_with_real_opponents(my_commander, my_deck, opponent_data_list, rng, game_id=0):
    """Simulate game with real learned opponents (pre-built decks)."""
    clear_pending_triggers()
    turn, max_turns = 0, 35
    stack = Stack()

    lorehold = Player("Lorehold", my_commander, my_deck, is_human=True, strategy="spellslinger")
    opponents = []
    for opp_data in opponent_data_list:
        opp_cmd = {"name": opp_data["commander_name"], "cmc": 4, "tag": "creature", 
                   "type_line": "Legendary Creature", "is_commander": True, "owner": opp_data["name"]}
        opp = Player(opp_data["name"], opp_cmd, opp_data["deck"], strategy=opp_data.get("strategy", "midrange"))
        opponents.append(opp)

    all_players = [lorehold] + opponents
    approach_found = False
    approach_countered = 0

    for p in all_players:
        play_mulligan(p, rng)

    while lorehold.is_alive() and turn < max_turns:
        turn += 1
        alive = [p for p in all_players if p.is_alive()]
        if len(alive) <= 1:
            break

        for player in all_players:
            if not player.is_alive():
                continue
            others = [p for p in all_players if p != player]
            play_turn_sequence_v8(player, others, all_players, turn, rng, stack)
            if not player.is_alive():
                continue
            # Check any explicit alternate-win state.
            for p in all_players:
                if p.has_won():
                    return ("win" if p is lorehold else "loss"), turn, p.win_reason
            check_sbas_until_stable(all_players)
            if any(getattr(p, "eliminated", False) for p in all_players):
                break

    if lorehold.is_alive():
        alive_opps = sum(1 for o in opponents if o.is_alive())
        if alive_opps == 0:
            return "win", turn, "elimination"
        return "stall", turn, f"opponents_alive={alive_opps}"
    return "loss", turn, "life_zero"



def classify_loss(player, opponents, turn, result, reason):
    """v9: Root-cause canonical loss tagging (CR 104.2-104.5, 903.14)."""
    tags = []
    if result != "loss":
        return tags
    
    current_mana = player.available_mana() if hasattr(player, "available_mana") else 0
    lands_played = getattr(player, "lands_played_this_turn", 0)
    nonland_count = sum(1 for c in (player.graveyard + player.hand) if not is_land(c))
    mulligans = getattr(player, "_mulligan_count", 0)
    
    if turn >= 4 and current_mana < 3 and lands_played < 3:
        tags.append("screw")
    elif lands_played >= 7 and nonland_count <= 2:
        tags.append("flood")
    if mulligans >= 2 and turn < 6:
        tags.append("bad-mulligan")
    if getattr(player, "_commander_removals", 0) >= 3:
        tags.append("commander-removed")
    if turn >= 10 and "screw" not in tags and "flood" not in tags:
        tags.append("out-valued")
    
    # v9: Canonical loss taxonomy
    if getattr(player, "poison", 0) >= 10:
        tags.insert(0, "poison")
    if getattr(player, "lost_by_effect", False):
        tags.insert(0, "effect_says_lose")
    if getattr(player, "conceded", False):
        tags.insert(0, "concede")
    
    if not tags:
        tags.append("combat-damage")
    return tags

def simulate_game_v8(my_commander, my_deck, opp_profile, rng, game_id=0):
    clear_pending_triggers()
    turn, max_turns = 0, 35
    stack = Stack()

    lorehold = Player("Lorehold", my_commander, my_deck, is_human=True, strategy="spellslinger")
    opponents = []
    for profile in opp_profile:
        if profile.get("is_real") and profile.get("built_deck"):
            # Real learned deck — use pre-built deck list directly
            opp_cmd = {"name": profile["commander_name"], "cmc": 4, "tag": "creature",
                       "type_line": "Legendary Creature", "is_commander": True, "owner": profile["name"]}
            opp = Player(profile["name"], opp_cmd, profile["built_deck"], strategy=profile.get("strategy", "midrange"))
        else:
            opp_deck = generate_opponent_deck(profile)
            opp_cmd = get_opponent_commander(profile)
            opp = Player(profile["name"], opp_cmd, opp_deck, strategy=profile["strategy"])
        opponents.append(opp)

    all_players = [lorehold] + opponents

    # v8.3: Track Approach statistics
    approach_found = False
    approach_countered = 0
    approach_resolved = 0

    for p in all_players:
        play_mulligan(p, rng)

    while lorehold.is_alive() and turn < max_turns:
        turn += 1
        alive = [p for p in all_players if p.is_alive()]
        if len(alive) <= 1:
            break

        for player in all_players:
            if not player.is_alive():
                continue
            others = [p for p in all_players if p != player]
            play_turn_sequence_v8(player, others, all_players, turn, rng, stack)
            if not player.is_alive():
                continue
            # Check any explicit alternate-win state.
            for p in all_players:
                if p.has_won():
                    return ("win" if p is lorehold else "loss"), turn, p.win_reason
            check_sbas_until_stable(all_players)
            if any(getattr(p, "eliminated", False) for p in all_players):
                break

    if lorehold.is_alive():
        alive_opps = sum(1 for o in opponents if o.is_alive())
        if alive_opps == 0:
            return "win", turn, "elimination"
        return "stall", turn, f"opponents_alive={alive_opps}|found={approach_found}|countered={approach_countered}"
    return "loss", turn, f"life_zero|found={approach_found}|countered={approach_countered}"

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════


def load_learned_opponents():
    """Load real opponent decklists from learned_decks table."""
    try:
        conn = sqlite3.connect(DB)
        conn.row_factory = sqlite3.Row
        candidate_limit = int(os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_CANDIDATES", "96"))
        opponent_limit = int(os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_LIMIT", "12"))
        min_cards = int(os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_MIN_CARDS", "80"))
        rows = conn.execute(
            """
            SELECT *
            FROM learned_decks
            WHERE COALESCE(commander, '') != ''
              AND commander NOT LIKE '%Lorehold%'
              AND COALESCE(card_list, '') != ''
              AND length(card_list) >= 500
              AND COALESCE(card_count, 0) >= ?
            ORDER BY
              CASE WHEN source = 'pg_meta_decks' THEN 0 ELSE 1 END,
              COALESCE(card_count, 0) DESC,
              id DESC
            LIMIT ?
            """,
            (min_cards, candidate_limit),
        ).fetchall()
        decoded_rows = []
        cache_names = []
        for row in rows:
            card_data = decode_learned_card_list(row["card_list"])
            if len(card_data) < min_cards:
                continue
            decoded_rows.append((row, card_data))
            if row["commander"]:
                cache_names.append(row["commander"])
            cache_names.extend(
                c.get("name")
                for c in card_data
                if isinstance(c, dict) and c.get("name")
            )
        oracle_cache = load_card_oracle_cache(conn, cache_names)
        conn.close()
        decks = []
        for row, card_data in decoded_rows:
            deck = []
            commander_key = normalize_card_name(row["commander"])
            for raw_card in card_data:
                expanded_cards = expand_learned_card(raw_card)
                for c in expanded_cards:
                    if normalize_card_name(c.get("name")) == commander_key:
                        continue
                    if len(deck) >= 99:
                        break
                    deck.append(build_learned_battle_card(c, oracle_cache))
                if len(deck) >= 99:
                    break
            original_deck_count = len(deck)
            while len(deck) < 99:
                deck.append({
                    "name": "Filler",
                    "cmc": 3,
                    "tag": "creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "type_line": "Creature",
                })
            real_name = f"{row['commander']} #{row['id']} (real)"
            decks.append({
                "name": real_name, "archetype": row["archetype"] or "midrange",
                "source": row["source"],
                "learned_deck_id": row["id"],
                "source_card_count": row["card_count"],
                "battle_card_count": original_deck_count,
                "built_deck": deck,
                "commander_name": row["commander"],
                "strategy": infer_strategy(row["archetype"] or "midrange"),
                "life": 40, "lands": sum(1 for c in deck if c.get("effect") == "land"),
                "ramp": sum(1 for c in deck if c.get("effect") in ("ramp",)),
                "removal": sum(1 for c in deck if c.get("effect") in ("removal", "board_wipe")) ,
                "counters": sum(1 for c in deck if c.get("effect") == "counter"),
                "creatures": sum(1 for c in deck if c.get("effect") == "creature"),
                "avg_cmc": sum(c.get("cmc", 3) for c in deck) / max(1, len(deck)),
                "is_real": True,
            })
        seed = real_opponent_seed()
        rng = random.Random(seed)
        rng.shuffle(decks)
        decks = decks[:opponent_limit]
        if decks:
            print(
                f"Loaded {len(decks)} real opponent decks from {len(decoded_rows)} "
                f"valid candidates (seed={seed})"
            )
        return decks
    except Exception as e:
        print(f"load_learned_opponents: {e}")
        return []


def decode_learned_card_list(value):
    """Decode JSON card lists and legacy plain-text decklists into card entries."""
    if not value:
        return []
    text = str(value)
    try:
        decoded = json.loads(text)
    except Exception:
        decoded = None
    if isinstance(decoded, list):
        return decoded

    cards = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.lower() in ("deck", "commander", "sideboard", "maybeboard"):
            continue
        line = re.sub(r"^(sb:|sideboard:)\s*", "", line, flags=re.I).strip()
        match = re.match(r"^(\d+)\s*x?\s+(.+)$", line, flags=re.I)
        if not match:
            continue
        quantity = max(1, min(30, int(match.group(1))))
        name = re.sub(r"\s+\([^)]*\)\s*\d*\s*$", "", match.group(2)).strip()
        if name:
            cards.append({"name": name, "quantity": quantity})
    return cards


def expand_learned_card(card):
    if isinstance(card, str):
        return [{"name": card}]
    if not isinstance(card, dict):
        return []
    quantity = card.get("quantity", 1)
    try:
        quantity = int(quantity)
    except (TypeError, ValueError):
        quantity = 1
    quantity = max(1, min(30, quantity))
    base = dict(card)
    base.pop("quantity", None)
    return [dict(base) for _ in range(quantity)]


def infer_strategy(archetype):
    normalized = str(archetype or "").lower()
    if "stax" in normalized:
        return "stax"
    if "combo" in normalized or "storm" in normalized:
        return "combo"
    if "control" in normalized:
        return "control"
    if "aggro" in normalized or "rush" in normalized:
        return "rush"
    if "spell" in normalized:
        return "spells"
    if "midrange" in normalized or "value" in normalized:
        return "value"
    return "midrange"


def infer_battle_card_identity(card):
    role = normalize_functional_tag(card.get("role") or card.get("category") or card.get("tag") or "")
    roles = set(card_functional_tags(card))
    if role:
        roles.add(role)
    type_line = str(card.get("type_line") or "").lower()
    oracle_text = str(card.get("oracle_text") or "").lower()
    name = str(card.get("name") or "").lower()

    if "land" in roles or "land" in type_line or normalize_card_name(name) in KNOWN_LAND_NAMES:
        return "land", "land"
    if roles.intersection({"ramp", "rock", "ritual"}) or "add " in oracle_text or "treasure token" in oracle_text:
        return "ramp", "ramp"
    if roles.intersection({"counterspell", "counter"}) or "counter target" in oracle_text:
        return "counter", "counter"
    if (
        "exile all permanents" in oracle_text
        and "exile all cards from all hands and graveyards" in oracle_text
        and "life total becomes 1" in oracle_text
    ):
        return "wincon", "worldfire_reset"
    if roles.intersection({"board_wipe", "wipe", "sweeper"}) or "destroy all" in oracle_text or "exile all" in oracle_text:
        return "board_wipe", "board_wipe"
    if "removal" in roles or "destroy target" in oracle_text or "exile target" in oracle_text:
        return "removal", "removal"
    if roles.intersection({"draw", "cantrip", "wheel"}) or "draw" in oracle_text:
        return "draw", "draw"
    if "tutor" in roles or "search your library" in oracle_text:
        return "tutor", "tutor"
    if "protection" in roles or "indestructible" in oracle_text or "protection from" in oracle_text:
        return "protection", "protection"
    if roles.intersection({"wincon", "combo_piece"}) or "you win the game" in oracle_text:
        return "wincon", "wincon"
    if "creature" in roles or "creature" in type_line or "token" in name:
        return "creature", "creature"
    if "instant" in type_line:
        return "spell", "instant"
    if "sorcery" in type_line:
        return "spell", "sorcery"
    return "unknown", "unknown"


def build_learned_battle_card(card, oracle_cache):
    name = card.get("name", "?")
    imported = dict(card)
    imported["name"] = name
    imported = merge_oracle_metadata(imported, oracle_cache)
    tag, effect = infer_battle_card_identity(imported)
    cmc = imported.get("cmc")
    try:
        cmc = float(cmc if cmc is not None else 3)
    except (TypeError, ValueError):
        cmc = 3
    imported.update({
        "cmc": cmc,
        "tag": tag,
        "effect": effect,
        "type_line": imported.get("type_line") or ("Land" if effect == "land" else ("Creature" if effect == "creature" else "")),
        "is_commander": bool(imported.get("is_commander", False)),
    })
    if effect == "creature":
        default_power = max(1, int(cmc))
        imported["power"] = imported.get("power") or default_power
        imported["toughness"] = imported.get("toughness") or imported.get("power") or default_power
    else:
        imported["power"] = imported.get("power") or 0
        imported["toughness"] = imported.get("toughness") or 0
    return enrich_card(imported)


def real_opponent_seed():
    seed_raw = os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_SEED")
    if seed_raw:
        try:
            return int(seed_raw)
        except ValueError:
            return abs(hash(seed_raw)) % 1_000_000_000
    return int(datetime.now(timezone.utc).strftime("%Y%m%d%H"))


def parse_cli_args(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "Run the active ManaLoom Commander battle simulator against learned "
            "or generic opponents and print the aggregate results."
        )
    )
    parser.add_argument(
        "--games",
        type=int,
        default=50,
        help="games to run against each sampled opponent profile (default: 50)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="RNG seed for reproducible opponent sampling (default: 42)",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_cli_args(argv)
    metrics_path = os.environ.get("MANALOOM_ENGINE_METRICS_OUT")
    if metrics_path:
        set_engine_metrics(EngineMetrics())

    print("=" * 60)
    print("BATTLE ANALYST v9 — Interactive Commander (Priority + Stack + Miracle)")
    print("=" * 60)

    commander, deck, construction_report = load_deck_with_construction_report()
    lands = sum(1 for c in deck if card_has_functional_tag(c, "land") or "Land" in c.get("type_line", ""))
    ramp = sum(1 for c in deck if card_has_functional_tag(c, "ramp", "ritual"))
    removal = sum(1 for c in deck if card_has_functional_tag(c, "removal", "board_wipe"))
    nonlands = [c for c in deck if not card_has_functional_tag(c, "land")]
    avg_cmc = sum(c["cmc"] for c in nonlands) / max(1, len(nonlands))
    instants_in_deck = sum(1 for c in deck if is_instant(c))

    print(f"Commander: {commander['name'] if commander else 'NONE'}")
    print(f"Deck: 1+99 | L={lands} R={ramp} X={removal} CMC={avg_cmc:.2f} Instants={instants_in_deck}")
    if not construction_report["is_valid"]:
        print("Deck construction warnings: " + ", ".join(construction_report["issues"]))
    print("v9: Priority, Stack, Instant/Sorcery Timing, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste")

    # Check for learned decks first
    learned = load_learned_opponents()
    if learned and len(learned) >= 3:
        opponent_sources = learned
        opponent_kind = "real"
        print(f"\nUsing {len(learned)} REAL learned opponent decks")
    else:
        opponent_sources = OPPONENT_ARCHETYPES
        opponent_kind = "generic"
        print(f"\nUsing {len(OPPONENT_ARCHETYPES)} generic archetype profiles")

    GAMES = max(1, int(args.games))
    rng = random.Random(args.seed)

    results = []
    total_wins = total_losses = total_stalls = 0

    print(f"\n{GAMES} games vs each of {len(opponent_sources)} {opponent_kind} opponents (4-player)...\n")

    for profile in opponent_sources:
        wins = losses = stalls = 0
        win_turns = []
        win_reasons = defaultdict(int)

        for g in range(GAMES):
            others = [p for p in opponent_sources if p != profile]
            picked = [profile] + rng.sample(others, min(2, len(others)))
            # For learned decks, attach card list directly
            for p in picked:
                if p.get("is_real"):
                    # Card list is in profile data, pass through
                    pass
            result, turns, reason = simulate_game_v8(commander, deck, picked, rng, g)

            if result == "win":
                wins += 1
                win_turns.append(turns)
                win_reasons[reason] += 1
            elif result == "loss":
                losses += 1
            else:
                stalls += 1

        wr = wins / GAMES * 100
        avg_t = sum(win_turns) / len(win_turns) if win_turns else 0

        results.append({"opponent": profile.get("name", profile["name"]), "archetype": profile.get("archetype", "?"),
                        "wins": wins, "losses": losses, "stalls": stalls,
                        "win_rate": wr, "avg_win_turn": avg_t,
                        "win_reasons": dict(win_reasons)})

        total_wins += wins; total_losses += losses; total_stalls += stalls

        icon = "✅" if wr >= 55 else "⚖️" if wr >= 40 else "❌"
        details = ", ".join(f"{k}={v}" for k, v in win_reasons.items())
        print(f"  {icon} vs {profile.get('name', '?'):<30s} WR={wr:5.1f}% W={wins} L={losses} S={stalls} T={avg_t:.1f} [{details}]")

    total_g = GAMES * len(opponent_sources)
    avg_wr = total_wins / total_g * 100
    print(f"\n  OVERALL v9: WR={avg_wr:.1f}% ({total_wins}W/{total_losses}L/{total_stalls}S)")

    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(LOG_PATH, "a") as f:
        f.write(f"\n## [{ts}] Battle Analyst v9 — Interactive Commander\n")
        f.write(f"Games: {GAMES} 4-player | Deck: L={lands} R={ramp} X={removal} CMC={avg_cmc:.2f} Instants={instants_in_deck}\n")
        f.write(f"Opponents: {len(opponent_sources)} ({opponent_kind})\n\n")
        f.write(f"| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |\n")
        f.write(f"|:---------|----:|-----:|-------:|-------:|------:|:--------|\n")
        for r in results:
            reason_str = ", ".join(f"{k}={v}" for k, v in r["win_reasons"].items())
            f.write(f"| {r['opponent']} | {r['win_rate']:.1f}% | {r['wins']} | {r['losses']} | {r['stalls']} | {r['avg_win_turn']:.1f} | {reason_str} |\n")
        f.write(f"\n**Overall WR: {avg_wr:.1f}%** ({total_wins}W/{total_losses}L/{total_stalls}S)\n")
    print(f"\nLog: {LOG_PATH}")
    if metrics_path:
        write_engine_metrics_snapshot(
            metrics_path,
            {
                "battle_script": "battle_analyst_v9",
                "games_per_opponent": GAMES,
                "opponents": len(opponent_sources),
                "opponent_kind": opponent_kind,
                "total_games": total_g,
                "wins": total_wins,
                "losses": total_losses,
                "stalls": total_stalls,
                "win_rate": avg_wr,
            },
        )
        print(f"Engine metrics: {metrics_path}")

if __name__ == "__main__":
    main()
