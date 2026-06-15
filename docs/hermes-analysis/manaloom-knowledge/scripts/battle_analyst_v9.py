#!/usr/bin/env python3
"""
Lorehold Battle Analyst v8 — Interactive Commander Simulator
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
import sqlite3, random, json, os, re, copy, sys
from datetime import datetime, timezone
from collections import defaultdict

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR and SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

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

DB = os.environ.get(
    "MANALOOM_KNOWLEDGE_DB",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
)
KNOWLEDGE_DIR = os.environ.get(
    "MANALOOM_KNOWLEDGE_DIR",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge",
)
LOG_PATH = f"{KNOWLEDGE_DIR}/decks/lorehold-the-historian/BATTLE_LOG.md"

REPLAY_EVENT_HANDLER = None
DECISION_TRACE_HANDLER = None
DECISION_TRACE_COUNTER = 0
DECISION_TRACE_SCHEMA_VERSION = "decision_trace_v1"
DECISION_STRATEGY_VERSION = "battle_decision_strategy_v1_2026_06_15"
HIGH_IMPACT_PAYOFF_EFFECTS = {
    "approach",
    "board_wipe",
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
ENGINE_METRICS = None


def emit_replay_event(event, **data):
    """Emit optional structured replay events without affecting simulation."""
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
            "rejected_options": list(rejected_options or []),
            "score_components": dict(score_components or {"heuristic": 0}),
            "rule_source": rule_source or "unknown",
            "rule_status": rule_status or "unknown",
            "confidence": confidence,
            "expected_benefit_score": expected_benefit_score,
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

KNOWN_CARDS = {
    "Teferi's Protection": {"effect": "phase_out", "instant": True},
    "Boros Charm": {"effect": "modal_boros_charm", "instant": True},
    "Deflecting Swat": {"effect": "redirect_removal", "instant": True},
    "Grand Abolisher": {"effect": "silence_opponents"},
    "Austere Command": {"effect": "board_wipe", "selective": True},
    "Blasphemous Act": {"effect": "board_wipe"},
    "Call Forth the Tempest": {"effect": "damage_wipe", "token_maker": True},
    "Approach of the Second Sun": {"effect": "approach", "gain_life": 7},
    "Insurrection": {"effect": "steal_all_creatures"},
    "Mizzix's Mastery": {"effect": "overload_recursion"},
    "Storm Herd": {"effect": "token_maker", "token_count": "life_total"},
    "Surge to Victory": {"effect": "pump_all", "recursion": True},
    "Rite of the Dragoncaller": {"effect": "token_maker", "token_count": 4, "token_power": 5},
    "Brass's Bounty": {"effect": "token_maker", "token_count": "lands"},
    "Akroma's Will": {"effect": "pump_all", "instant": True,
        "keywords": ["flying","double_strike","vigilance","lifelink","protection_all","indestructible"]},
    "The One Ring": {"effect": "draw_engine", "burden": True},
    "Wedding Ring": {"effect": "draw_engine", "symmetric": True},
    "Victory Chimes": {"effect": "draw_engine", "untap": True},
    "Sensei's Divining Top": {"effect": "topdeck_manipulation"},
    "Scroll Rack": {"effect": "topdeck_manipulation"},
    "Sol Ring": {"effect": "ramp_permanent", "mana_produced": 2},
    "Arcane Signet": {"effect": "ramp_permanent", "mana_produced": 1},
    "Boros Signet": {"effect": "ramp_permanent", "mana_produced": 1},
    "Talisman of Conviction": {"effect": "ramp_permanent", "mana_produced": 1},
    "Double Vision": {"effect": "copy_spell"},
    "Arcane Bombardment": {"effect": "copy_spell", "repeatable": True},
    "Enlightened Tutor": {"effect": "tutor", "target": "artifact_or_enchantment", "instant": True},
    "Gamble": {"effect": "tutor", "target": "any", "discard_risk": True},
    "Smothering Tithe": {"effect": "ramp_engine", "trigger": "opponent_draw"},
    "Jeska's Will": {"effect": "ramp_ritual", "mana_produced": 7},
    "Esper Sentinel": {"effect": "draw_engine", "trigger": "opponent_spell"},
    "Lorehold, the Historian": {"effect": "commander", "is_commander": True, "haste": True},
    "Chaos Warp": {"effect": "remove_permanent", "instant": True},
    "Path to Exile": {"effect": "remove_creature", "instant": True},
    "Swords to Plowshares": {"effect": "remove_creature", "instant": True},
    "Abrade": {"effect": "remove_artifact_or_3dmg", "instant": True},
    "Generous Gift": {"effect": "remove_permanent", "instant": True},
    "Deflecting Swat": {"effect": "redirect_removal", "instant": True},
    "Dragon's Approach": {"effect": "dragons_approach", "damage": 3},
    "Dance with Calamity": {"effect": "exile_value", "miracle": True},
    "Reforge the Soul": {"effect": "draw_cards", "count": 7, "miracle": "1R"},
    "Lumra, Bellow of the Woods": {
        "effect": "land_recursion_creature",
        "mill_count": 4,
        "power_equals_lands": True,
        "toughness_equals_lands": True,
        "keywords": ["vigilance", "reach"],
    },
    "Walking Ballista": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "activated_damage": True,
        "is_creature_permanent": True,
    },
    "Springheart Nantuko": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "landfall_token_maker": True,
        "token_power": 1,
        "token_toughness": 1,
        "is_creature_permanent": True,
    },
    "Stridehangar Automaton": {
        "effect": "creature",
        "power": 1,
        "toughness": 4,
        "keywords": ["flying"],
        "artifact_token_replacement": True,
        "thopter_lord": True,
        "is_creature_permanent": True,
    },
    "Demand Answers": {"effect": "draw_cards", "count": 2, "instant": True},
    "Reckless Impulse": {"effect": "draw_cards", "count": 2},
    "Food Chain": {"effect": "ramp_engine", "requires_creature_resource": True},
    "Chromatic Orrery": {
        "effect": "ramp_permanent",
        "mana_produced": 5,
        "produces": "WUBRGC",
    },
    "Wheel of Misfortune": {"effect": "draw_cards", "count": 7},
    "Strike It Rich": {"effect": "treasure_maker", "treasure_count": 1},
    "Sami's Curiosity": {"effect": "lander_token_maker", "life_gain": 2, "token_count": 1},
    "Sticky Fingers": {
        "effect": "ramp_engine",
        "trigger": "combat_damage_to_player",
        "aura": True,
        "grants_keywords": ["menace"],
        "treasure_on_combat_damage": 1,
        "draw_on_enchanted_death": 1,
    },
    "Desperate Ritual": {"effect": "ramp_ritual", "mana_produced": 3, "instant": True},
    "Diabolic Intent": {
        "effect": "tutor",
        "target": "any",
        "requires_sacrifice_creature": True,
    },
    "Noxious Revival": {"effect": "recursion", "count": 1, "instant": True},
    "Burgeoning": {"effect": "ramp_engine", "trigger": "opponent_land_play"},
    "Last Chance": {"effect": "extra_turn", "turns": 1, "lose_after_extra_turn": True},
    "Shore Up": {"effect": "protect_creature", "instant": True, "power_boost": 1, "toughness_boost": 1, "untap": True},
    "Goblin Engineer": {"effect": "creature", "power": 1, "toughness": 2, "is_creature_permanent": True},
    "Ugin, the Spirit Dragon": {"effect": "board_wipe", "selective": True},
    "Sylvan Safekeeper": {"effect": "creature", "power": 1, "toughness": 1, "is_creature_permanent": True},
    "Sowing Mycospawn": {"effect": "creature", "power": 3, "toughness": 3, "is_creature_permanent": True},
    "Force of Negation": {"effect": "counter", "instant": True},
    "Staff of Compleation": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "All Is Dust": {"effect": "board_wipe"},
    "Ruthless Technomancer": {"effect": "creature", "power": 2, "toughness": 4, "is_creature_permanent": True},
    "Deathrite Shaman": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRG",
        "is_creature_permanent": True,
    },
    "Summon: Bahamut": {"effect": "creature", "power": 9, "toughness": 9, "keywords": ["flying"], "is_creature_permanent": True},
    "The Eternity Elevator": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Hedron Archive": {"effect": "ramp_permanent", "mana_produced": 2, "produces": "C"},
    "Staff of Domination": {"effect": "draw_cards", "count": 1},
    "Manifold Key": {"effect": "ramp_engine"},
    "Unwinding Clock": {"effect": "ramp_engine", "trigger": "artifact_untap"},
    "Misdirection": {"effect": "redirect_removal", "instant": True},
    "Bloom Tender": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 2,
        "produces": "WUBRG",
        "is_creature_permanent": True,
    },
    "Pyretic Ritual": {"effect": "ramp_ritual", "mana_produced": 3, "instant": True},
    "Devoted Druid": {
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Krark-Clan Ironworks": {"effect": "ramp_engine", "requires_artifact_resource": True},
    "Talisman of Indulgence": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "BRC"},
    "Spider-Punk": {"effect": "creature", "power": 2, "toughness": 1, "keywords": ["haste"], "is_creature_permanent": True},
    "Thran Dynamo": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Altar of Dementia": {"effect": "unknown"},
    "Impulsive Pilferer": {"effect": "creature", "power": 1, "toughness": 1, "is_creature_permanent": True},
    "Elves of Deep Shadow": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "B",
        "is_creature_permanent": True,
    },
    "Worldly Tutor": {"effect": "tutor", "target": "creature", "instant": True},
    "Miscast": {"effect": "counter", "target": "instant_or_sorcery", "instant": True, "tax": 3},
    "Spell Pierce": {"effect": "counter", "instant": True},
    "Mana Leak": {"effect": "counter", "instant": True},
    "The Soul Stone": {"effect": "recursion", "count": 1},
    "Trophy Mage": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Fabricate": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Expedition Map": {"effect": "tutor", "target": "land"},
    "Lively Dirge": {"effect": "recursion", "count": 1},
    "Glaring Fleshraker": {"effect": "token_maker", "token_count": 1, "token_power": 0, "token_toughness": 1},
    "Forsaken Monument": {"effect": "pump_all", "keywords": [], "power_multiplier": 1},
    "Hullbreaker Horror": {"effect": "remove_permanent"},
    "Windfall": {"effect": "draw_cards", "count": 7},
    "Wan Shi Tong, Librarian": {"effect": "draw_engine", "trigger": "historic_spell"},
    "Mirage Mirror": {"effect": "ramp_engine"},
    "Force of Vigor": {"effect": "remove_permanent", "instant": True},
    "Training Grounds": {"effect": "ramp_engine"},
    "Freed from the Real": {"effect": "ramp_engine"},
    "Bolas's Citadel": {"effect": "topdeck_manipulation"},
    "Dimir Signet": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "UB"},
    "Bender's Waterskin": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Isochron Scepter": {"effect": "copy_spell"},
    "Inspiring Statuary": {"effect": "ramp_engine"},
    "Praetor's Grasp": {"effect": "tutor", "target": "any"},
    "Sylvan Scrying": {"effect": "tutor", "target": "land"},
    "Wild Growth": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "G"},
    "Counterspell": {"effect": "counter", "instant": True},
    "Nature's Claim": {
        "effect": "remove_permanent",
        "instant": True,
        "target": "artifact_or_enchantment",
        "target_controller_gains_life": 4,
    },
    "Formidable Speaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Soul-Guide Lantern": {"effect": "hate_artifact", "sacrifice_draw": 1},
    "Open the Omenpaths": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "instant": True,
        "restricted_to_creature_or_enchantment": True,
    },
    "Runaway Steam-Kin": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "red_spell_counter_mana_engine": True,
        "is_creature_permanent": True,
    },
    "Jaxis, the Troublemaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Jin-Gitaxias, Progress Tyrant": {
        "effect": "copy_spell",
        "power": 5,
        "toughness": 5,
        "is_creature_permanent": True,
    },
    "Mirrormade": {"effect": "unknown"},
    "Nezahal, Primal Tide": {
        "effect": "draw_engine",
        "trigger": "opponent_noncreature_spell",
        "power": 7,
        "toughness": 7,
        "is_creature_permanent": True,
        "uncounterable": True,
    },
    "Ugin, Eye of the Storms": {
        "effect": "remove_permanent",
        "target": "colored_permanent",
    },
    "Squee, the Immortal": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Fierce Empath": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "creature_cmc_6_plus",
    },
    "Rionya, Fire Dancer": {
        "effect": "creature",
        "power": 3,
        "toughness": 4,
        "is_creature_permanent": True,
        "begin_combat_copy_engine": True,
    },
    "Cursed Mirror": {
        "effect": "ramp_permanent",
        "mana_produced": 1,
        "produces": "R",
    },
    "Mystic Forge": {"effect": "topdeck_manipulation"},
    "Sneak Attack": {"effect": "unknown"},
    "Eldritch Evolution": {
        "effect": "tutor",
        "target": "creature_to_battlefield",
        "requires_sacrifice_creature": True,
        "exiles_self": True,
    },
    "Stoneforge Mystic": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_creature_permanent": True,
        "etb_tutor_target": "equipment",
    },
    "Reprieve": {"effect": "counter", "instant": True, "draw_on_counter": 1},
    "Splendid Reclamation": {"effect": "land_recursion"},
    "Vandalblast": {"effect": "remove_permanent", "target": "artifact"},
    "Delivery Moogle": {
        "effect": "creature",
        "power": 3,
        "toughness": 2,
        "keywords": ["flying"],
        "is_creature_permanent": True,
        "etb_tutor_target": "cheap_artifact",
    },
    "Galadriel's Dismissal": {"effect": "phase_creatures", "instant": True},
    "Bottle-Cap Blast": {"effect": "deal_damage", "amount": 5, "instant": True},
    "Mechanized Warfare": {"effect": "unknown"},
    "Cloud of Faeries": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Rampant Growth": {"effect": "land_ramp", "land_count": 1, "basic_only": True},
    "Springbloom Druid": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_land_ramp_count": 2,
        "etb_requires_sacrifice_land": True,
        "basic_only": True,
    },
    "Tannuk, Memorial Ensign": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "is_creature_permanent": True,
        "landfall_damage_each_opponent": 1,
        "landfall_second_draw": True,
    },
    "Commandeer": {"effect": "counter", "instant": True},
    "Roiling Regrowth": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
        "requires_sacrifice_land": True,
        "land_enters_tapped": True,
        "instant": True,
    },
    "Echoes of Eternity": {"effect": "copy_spell", "colorless_only": True},
    "Pest Infestation": {
        "effect": "remove_permanent",
        "target": "artifact_or_enchantment",
    },
    "Reckless Handling": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Spellseeker": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "cheap_instant_or_sorcery",
    },
    "Snakeskin Veil": {
        "effect": "protect_creature",
        "instant": True,
        "power_boost": 1,
        "toughness_boost": 1,
    },
    "Omnath, Locus of Rage": {
        "effect": "creature",
        "power": 5,
        "toughness": 5,
        "is_creature_permanent": True,
        "landfall_token_maker": True,
        "token_power": 5,
        "token_toughness": 5,
    },
    "Fog": {"effect": "unknown", "instant": True},
    "Grist, the Hunger Tide": {"effect": "commander", "is_commander": True},
    "Amphibian Downpour": {
        "effect": "remove_creature",
        "instant": True,
        "target": "creature",
    },
    "Oswald Fiddlebender": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Brainstorm": {"effect": "draw_cards", "count": 1, "instant": True},
    "Talisman of Creativity": {
        "effect": "ramp_permanent",
        "mana_produced": 1,
        "produces": "URC",
    },
    "Mishra's Bauble": {"effect": "draw_cards", "count": 1},
    "Harrow": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
        "requires_sacrifice_land": True,
        "land_enters_tapped": False,
        "instant": True,
    },
    "Solemn Simulacrum": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
        "etb_land_ramp_count": 1,
        "basic_only": True,
    },
    "Snake Umbra": {"effect": "unknown"},
    "Sakura-Tribe Elder": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Explore": {"effect": "draw_cards", "count": 1},
    "Gitaxian Probe": {"effect": "draw_cards", "count": 1},
    "Artist's Talent": {"effect": "draw_engine"},
    "Helm of Awakening": {"effect": "ramp_engine"},
    "Dragon's Rage Channeler": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Migration Path": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
    },
    "Cryptolith Rite": {"effect": "ramp_engine"},
    "Tireless Tracker": {
        "effect": "creature",
        "power": 3,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Gravecrawler": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
        "cant_block": True,
    },
    "Kozilek's Command": {
        "effect": "remove_creature",
        "target": "creature",
        "instant": True,
    },
    "Demonic Counsel": {"effect": "tutor", "target": "any"},
    "Assassin's Trophy": {
        "effect": "remove_permanent",
        "target": "nonland",
        "instant": True,
    },
    "Deadly Rollick": {
        "effect": "remove_creature",
        "target": "creature",
        "instant": True,
    },
    "Persist": {
        "effect": "recursion",
        "target": "creature",
        "destination": "battlefield",
        "count": 1,
    },
    "Cityscape Leveler": {
        "effect": "creature",
        "power": 8,
        "toughness": 8,
        "keywords": ["trample"],
        "is_creature_permanent": True,
    },
    "Skullclamp": {"effect": "passive"},
    "Reanimate": {
        "effect": "recursion",
        "target": "creature",
        "destination": "battlefield",
        "count": 1,
    },
    "Harmonize": {"effect": "draw_cards", "count": 3},
    "Wheel of Fate": {"effect": "draw_cards", "count": 7},
    "Search for Tomorrow": {
        "effect": "land_ramp",
        "land_count": 1,
        "basic_only": True,
    },
    "Blind Obedience": {"effect": "passive"},
    "Cultivate": {
        "effect": "land_ramp",
        "land_count": 1,
        "basic_only": True,
    },
    "Monologue Tax": {"effect": "ramp_engine", "trigger": "opponent_second_spell"},
    "Talisman of Resilience": {
        "effect": "ramp_permanent",
        "mana_produced": 1,
        "produces": "BGC",
    },
    "Sylvan Library": {"effect": "passive"},
    "Entomb": {"effect": "tutor", "target": "graveyard", "instant": True},
    "Explosive Vegetation": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
    },
    "Necromancy": {
        "effect": "recursion",
        "target": "creature",
        "destination": "battlefield",
        "count": 1,
    },
    "Unmarked Grave": {"effect": "tutor", "target": "graveyard_nonlegendary"},
    "Carpet of Flowers": {"effect": "ramp_engine"},
    "Teferi, Time Raveler": {"effect": "passive"},
    "Plague Myr": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["infect"],
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "Elvish Reclaimer": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "land_tutor_activated": True,
        "is_creature_permanent": True,
    },
    "Zuran Orb": {"effect": "life_artifact", "sacrifice_land_gain_life": 2},
    "Vexing Bauble": {
        "effect": "hate_artifact",
        "counters_free_spells": True,
        "sacrifice_draw": 1,
    },
    # Runtime Commander/cEDH staples promoted after Hermes forensic audit.
    "Pact of Negation": {"effect": "counter", "instant": True},
    "Force of Will": {"effect": "counter", "instant": True},
    "Mindbreak Trap": {"effect": "counter", "instant": True},
    "Swan Song": {"effect": "counter", "instant": True},
    "Pyroblast": {"effect": "counter", "instant": True, "target": "blue_spell_or_permanent"},
    "Red Elemental Blast": {"effect": "counter", "instant": True, "target": "blue_spell_or_permanent"},
    "Mental Misstep": {"effect": "counter", "instant": True},
    "An Offer You Can't Refuse": {"effect": "counter", "instant": True},
    "Silence": {"effect": "silence_spell", "instant": True},
    "Orim's Chant": {"effect": "silence_spell", "instant": True},
    "Demonic Tutor": {"effect": "tutor", "target": "any"},
    "Vampiric Tutor": {"effect": "tutor", "target": "any", "instant": True},
    "Imperial Seal": {"effect": "tutor", "target": "any"},
    "Mystical Tutor": {"effect": "tutor", "target": "instant_or_sorcery", "instant": True},
    "Green Sun's Zenith": {"effect": "tutor", "target": "green_creature_to_battlefield"},
    "Beseech the Mirror": {"effect": "tutor", "target": "any"},
    "Wishclaw Talisman": {"effect": "tutor", "target": "any"},
    "Land Tax": {"effect": "passive"},
    "Weathered Wayfarer": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Imperial Recruiter": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "small_creature",
    },
    "Recruiter of the Guard": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "small_creature",
    },
    "Mother of Runes": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Giver of Runes": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Drannith Magistrate": {
        "effect": "passive",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Grafdigger's Cage": {"effect": "passive"},
    "Rapid Hybridization": {"effect": "remove_creature", "instant": True, "target": "creature"},
    "Into the Flood Maw": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Chain of Vapor": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Orcish Bowmasters": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["flash"],
        "is_creature_permanent": True,
    },
    "Mana Vault": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Mox Diamond": {
        "effect": "ramp_permanent",
        "mana_produced": 1,
        "produces": "WUBRGC",
        "requires_discard_land": True,
    },
    "Chrome Mox": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Mox Amber": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Mox Opal": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Fellwar Stone": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Ruby Medallion": {"effect": "ramp_engine"},
    "Grim Monolith": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Lotus Petal": {"effect": "ramp_ritual", "mana_produced": 1, "produces": "WUBRGC"},
    "Lion's Eye Diamond": {"effect": "ramp_ritual", "mana_produced": 3, "produces": "WUBRGC"},
    "Rite of Flame": {"effect": "ramp_ritual", "mana_produced": 2},
    "Dark Ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "Seething Song": {"effect": "ramp_ritual", "mana_produced": 5},
    "Cabal Ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "Brightstone Ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "Mystic Remora": {"effect": "draw_engine", "trigger": "opponent_noncreature_spell"},
    "Rhystic Study": {"effect": "draw_engine", "trigger": "opponent_spell"},
    "Wheel of Fortune": {"effect": "draw_cards", "count": 7},
    "Faithless Looting": {"effect": "draw_cards", "count": 2},
    "Consider": {"effect": "draw_cards", "count": 1, "instant": True},
    "Expedite": {"effect": "draw_cards", "count": 1},
    "Crimson Wisps": {"effect": "draw_cards", "count": 1, "instant": True},
    "Valakut Awakening": {"effect": "draw_cards", "count": 3, "instant": True},
    "Underworld Breach": {"effect": "passive"},
    "Past in Flames": {"effect": "recursion", "target": "instant_or_sorcery", "count": 3},
    "Sevinne's Reclamation": {"effect": "recursion", "count": 1},
    "Nature's Rhythm": {"effect": "recursion", "count": 1},
    "Twinflame": {"effect": "token_maker", "token_count": 1, "token_power": 2, "token_haste": True},
    "Heat Shimmer": {"effect": "token_maker", "token_count": 1, "token_power": 2, "token_haste": True},
    "Hangarback Walker": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Aetherflux Reservoir": {"effect": "finisher"},
    "Thassa's Oracle": {"effect": "finisher"},
    "Brain Freeze": {"effect": "finisher"},
    "Grapeshot": {"effect": "deal_damage", "amount": 1},
    "Guttersnipe": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "trigger": "instant_sorcery_cast",
        "trigger_effect": "damage_each_opponent",
        "damage": 2,
        "is_creature_permanent": True,
    },
    "Fiery Emancipation": {"effect": "passive"},
    "Final Fortune": {"effect": "extra_turn", "turns": 1, "lose_after_extra_turn": True},
    "Flawless Maneuver": {"effect": "indestructible", "instant": True},
    "Tezzeret, Cruel Captain": {"effect": "passive"},
    "Agatha's Soul Cauldron": {"effect": "passive"},
    "Retraction Helix": {"effect": "remove_permanent", "target": "nonland", "instant": True},
    "Fierce Guardianship": {"effect": "counter", "instant": True},
    "Flusterstorm": {"effect": "counter", "instant": True},
    "Flare of Denial": {"effect": "counter", "instant": True},
    "Daze": {"effect": "counter", "instant": True},
    "Sink into Stupor": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Finale of Devastation": {"effect": "tutor", "target": "green_creature_to_battlefield"},
    "Longshot, Rebel Bowman": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "keywords": ["reach"],
        "trigger": "instant_sorcery_cast",
        "trigger_effect": "damage_each_opponent",
        "damage": 2,
        "is_creature_permanent": True,
    },
    "Insidious Roots": {"effect": "passive"},
    "Pinnacle Monk": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "keywords": ["prowess"],
        "is_creature_permanent": True,
    },
    "Flashback": {"effect": "recursion", "target": "instant_or_sorcery", "count": 1, "instant": True},
    "Eternal Witness": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Ranger-Captain of Eos": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
        "etb_tutor_target": "small_creature",
    },
    "Snap": {"effect": "remove_creature", "instant": True, "target": "creature"},
    "Transmute Artifact": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Urza, Lord High Artificer": {
        "effect": "creature",
        "power": 1,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Chains of Mephistopheles": {"effect": "passive"},
    "Might of the Meek": {"effect": "draw_cards", "count": 1, "instant": True},
    "Overmaster": {"effect": "draw_cards", "count": 1},
    "Repurposing Bay": {"effect": "passive"},
    "Molten Duplication": {"effect": "token_maker", "token_count": 1, "token_power": 2, "token_haste": True},
    "Muse Seeker": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Ashling, Flame Dancer": {
        "effect": "creature",
        "power": 4,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Simulacrum Synthesizer": {"effect": "passive"},
    "Knight of the Reliquary": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "land_tutor_activated": True,
        "is_creature_permanent": True,
    },
    "Touch the Spirit Realm": {"effect": "remove_permanent", "target": "artifact_or_creature"},
    "Survival of the Fittest": {"effect": "passive"},
    "Kozilek, Butcher of Truth": {
        "effect": "creature",
        "power": 12,
        "toughness": 12,
        "is_creature_permanent": True,
    },
    "Ulamog, the Infinite Gyre": {
        "effect": "creature",
        "power": 10,
        "toughness": 10,
        "keywords": ["indestructible"],
        "is_creature_permanent": True,
    },
    "Forensic Gadgeteer": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Abrupt Decay": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Invasion of Ikoria": {"effect": "tutor", "target": "green_creature_to_battlefield"},
    "Intuition": {"effect": "tutor", "target": "any", "instant": True},
    "Fell the Profane": {"effect": "remove_creature", "instant": True, "target": "creature"},
    "Seal of Primordium": {"effect": "passive"},
    "Worldfire": {"effect": "board_wipe"},
    "Voice of Victory": {
        "effect": "silence_opponents",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Grim Tutor": {"effect": "tutor", "target": "any"},
    "Archdruid's Charm": {"effect": "remove_permanent", "instant": True, "target": "artifact_or_enchantment"},
    "Summoner's Pact": {"effect": "tutor", "target": "green_creature", "instant": True},
    "Step Through": {"effect": "remove_creature", "target": "creature"},
    "Illicit Shipment": {"effect": "tutor", "target": "any"},
    "Electro, Assaulting Battery": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Vilis, Broker of Blood": {
        "effect": "creature",
        "power": 8,
        "toughness": 8,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Boggart Trawler": {
        "effect": "creature",
        "power": 3,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Guild Artisan": {"effect": "passive"},
    "Golgari Grave-Troll": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Aether Spellbomb": {"effect": "passive"},
    "Thrasios, Triton Hero": {
        "effect": "creature",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Urza's Bauble": {"effect": "passive"},
    "Emerald Charm": {"effect": "remove_permanent", "instant": True, "target": "enchantment"},
    "Sewer-veillance Cam": {"effect": "passive"},
    "Metalworker": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 2,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "Scour for Scrap": {"effect": "tutor", "target": "artifact_or_enchantment", "instant": True},
    "Demonic Collusion": {"effect": "tutor", "target": "any"},
    "Borne Upon a Wind": {"effect": "draw_cards", "count": 1, "instant": True},
    "Ad Nauseam": {"effect": "draw_cards", "count": 5, "instant": True},
    "Demonic Consultation": {"effect": "tutor", "target": "any", "instant": True},
    "Tainted Pact": {"effect": "tutor", "target": "any", "instant": True},
    "Chord of Calling": {"effect": "tutor", "target": "creature_to_battlefield", "instant": True},
    "Crop Rotation": {
        "effect": "land_ramp",
        "land_count": 1,
        "requires_sacrifice_land": True,
        "land_enters_tapped": False,
        "land_target_kind": "any",
        "instant": True,
    },
    "Birgi, God of Storytelling": {
        "effect": "ramp_engine",
        "mana_produced": 1,
        "produces": "R",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Culling the Weak": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "produces": "B",
        "requires_sacrifice_creature": True,
        "instant": True,
    },
    "Culling Ritual": {"effect": "ramp_ritual", "mana_produced": 4, "produces": "BG"},
    "Mana Geyser": {"effect": "ramp_ritual", "mana_produced": 7, "produces": "R"},
    "Rain of Filth": {"effect": "ramp_ritual", "mana_produced": 3, "produces": "B", "instant": True},
    "Simian Spirit Guide": {"effect": "ramp_ritual", "mana_produced": 1, "produces": "R", "instant": True},
    "Unexpected Windfall": {
        "effect": "treasure_maker",
        "treasure_count": 2,
        "draw_count": 2,
        "requires_discard_card": True,
        "instant": True,
    },
    "Birds of Paradise": {
        "effect": "creature",
        "power": 0,
        "toughness": 1,
        "keywords": ["flying"],
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Delighted Halfling": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "Fyndhorn Elves": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Wall of Roots": {
        "effect": "creature",
        "power": 0,
        "toughness": 5,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Relic of Legends": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Springleaf Drum": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Ragavan, Nimble Pilferer": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "keywords": ["haste"],
        "is_creature_permanent": True,
    },
    "Professional Face-Breaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "keywords": ["menace"],
        "is_creature_permanent": True,
    },
    "Storm-Kiln Artist": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "The Gitrog Monster": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["deathtouch"],
        "is_creature_permanent": True,
    },
    "Faerie Mastermind": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "keywords": ["flash", "flying"],
        "is_creature_permanent": True,
    },
    "Dualcaster Mage": {
        "effect": "copy_spell",
        "power": 2,
        "toughness": 2,
        "keywords": ["flash"],
        "is_creature_permanent": True,
    },
    "Hexing Squelcher": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Allosaurus Shepherd": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Enduring Vitality": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "keywords": ["vigilance"],
        "is_creature_permanent": True,
    },
    "Badgermole Cub": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "The Cabbage Merchant": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Tavern Scoundrel": {
        "effect": "creature",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Copy Enchantment": {"effect": "passive"},
    "Thousand-Year Elixir": {"effect": "passive"},
    "Clock of Omens": {"effect": "passive"},
    "The Reality Chip": {
        "effect": "topdeck_manipulation",
        "power": 0,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Mnemonic Betrayal": {"effect": "passive"},
    "Reverberate": {"effect": "copy_spell", "instant": True},
    "Reiterate": {"effect": "copy_spell", "instant": True},
    "Arcane Denial": {"effect": "counter", "instant": True},
    "Negate": {"effect": "counter", "instant": True},
    "Wash Away": {"effect": "counter", "instant": True},
    "Power Sink": {"effect": "counter", "instant": True},
    "Louisoix's Sacrifice": {"effect": "counter", "instant": True},
    "Condescend": {"effect": "counter", "instant": True},
    "Twisted Image": {"effect": "draw_cards", "count": 1, "instant": True},
    "Drift of Phantasms": {
        "effect": "tutor",
        "target": "cmc_3",
        "power": 0,
        "toughness": 5,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Tymna the Weaver": {
        "effect": "draw_engine",
        "trigger": "combat_damage_to_player",
        "power": 2,
        "toughness": 2,
        "keywords": ["lifelink"],
        "is_creature_permanent": True,
    },
    "Nexus of Becoming": {
        "effect": "draw_engine",
        "trigger": "begin_combat",
    },
    "Feed the Swarm": {"effect": "remove_permanent", "target": "creature_or_enchantment"},
    "Bitter Downfall": {"effect": "remove_creature", "target": "creature", "instant": True},
    "Seedship Impact": {"effect": "remove_permanent", "target": "artifact_or_enchantment", "instant": True},
    "Cyclonic Rift": {"effect": "remove_permanent", "target": "nonland", "instant": True},
    "Snapback": {"effect": "remove_creature", "target": "creature", "instant": True},
    "Eldrazi Confluence": {"effect": "remove_permanent", "target": "nonland", "instant": True},
    "Spine of Ish Sah": {"effect": "remove_permanent", "target": "permanent"},
    "Analyze the Pollen": {"effect": "tutor", "target": "land"},
    "Gifts Ungiven": {"effect": "tutor", "target": "any", "instant": True},
    "Eladamri's Call": {"effect": "tutor", "target": "creature", "instant": True},
    "Tezzeret the Seeker": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Dryad's Revival": {"effect": "recursion", "count": 1},
    "Deep Analysis": {"effect": "draw_cards", "count": 2},
    "Boon of the Wish-Giver": {"effect": "draw_cards", "count": 4},
    "Timetwister": {"effect": "draw_cards", "count": 7},
    "Roiling Dragonstorm": {"effect": "draw_cards", "count": 2},
    "Rise of the Eldrazi": {"effect": "extra_turn", "turns": 1, "exiles_self": True},
    "Living Death": {"effect": "board_wipe"},
    "Legolas's Quick Reflexes": {
        "effect": "protect_creature",
        "instant": True,
        "untap": True,
    },
    "Biosynthic Burst": {
        "effect": "protect_creature",
        "instant": True,
        "untap": True,
        "power_boost": 1,
        "toughness_boost": 1,
    },
    "Momentary Blink": {"effect": "phase_creatures", "instant": True},
    "Turn to Mist": {"effect": "phase_creatures", "instant": True},
    "Fiery Inscription": {"effect": "passive"},
    "Prismatic Undercurrents": {"effect": "passive"},
    "Necrodominance": {"effect": "passive"},
    "Altar of the Wretched": {"effect": "passive"},
    "Skyclave Apparition": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Karmic Guide": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "keywords": ["flying"],
        "etb_recursion_count": 1,
        "etb_recursion_target": "creature",
        "etb_recursion_destination": "battlefield",
        "is_creature_permanent": True,
    },
    "Archaeomancer": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "etb_recursion_count": 1,
        "etb_recursion_target": "instant_or_sorcery",
        "is_creature_permanent": True,
    },
    "Dawnbringer Cleric": {
        "effect": "creature",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Restoration Angel": {
        "effect": "creature",
        "power": 3,
        "toughness": 4,
        "keywords": ["flash", "flying"],
        "is_creature_permanent": True,
    },
    "Myr Battlesphere": {
        "effect": "creature",
        "power": 4,
        "toughness": 7,
        "etb_token_count": 4,
        "etb_token_power": 1,
        "etb_token_toughness": 1,
        "etb_token_name": "Myr",
        "etb_artifact_tokens": True,
        "is_creature_permanent": True,
    },
    "Goblin Cratermaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Monstrosity of the Lake": {
        "effect": "creature",
        "power": 4,
        "toughness": 6,
        "is_creature_permanent": True,
    },
    "Glacier Godmaw": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["trample", "vigilance", "haste"],
        "is_creature_permanent": True,
    },
    "Disciple of Freyalise": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Fiend Artisan": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Scryb Ranger": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["flash", "flying"],
        "is_creature_permanent": True,
    },
    "Shelob, Dread Weaver": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Rampaging War Mammoth": {
        "effect": "creature",
        "power": 9,
        "toughness": 7,
        "keywords": ["trample"],
        "is_creature_permanent": True,
    },
    "Duplicant": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Rydia, Summoner of Mist": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "keywords": ["haste"],
        "is_creature_permanent": True,
    },
    "Knuckles the Echidna": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "keywords": ["double_strike", "trample", "haste"],
        "is_creature_permanent": True,
    },
    "Shambling Ghast": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "They Came from the Pipes": {
        "effect": "token_maker",
        "token_count": 2,
        "token_power": 2,
        "token_toughness": 2,
    },
    "Map the Frontier": {"effect": "land_ramp", "land_count": 2, "basic_only": True},
    "Metamorphosis": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "requires_sacrifice_creature": True,
    },
    "Far Wanderings": {"effect": "land_ramp", "land_count": 1, "basic_only": True},
    "Herigast, Erupting Nullkite": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["flying"],
        "etb_draw_count": 3,
        "is_creature_permanent": True,
    },
    "Mind Stone": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "C"},
    "Commander's Sphere": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Azorius Signet": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WU"},
    "Talisman of Progress": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WU"},
    "Talisman of Dominance": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "UB"},
    "Talisman of Impulse": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "RG"},
    "Fractured Powerstone": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "C"},
    "Worn Powerstone": {"effect": "ramp_permanent", "mana_produced": 2, "produces": "C"},
    "Basalt Monolith": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Everflowing Chalice": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "C"},
    "Wayfarer's Bauble": {"effect": "land_ramp", "land_count": 1, "basic_only": True},
    "Manamorphose": {
        "effect": "treasure_maker",
        "treasure_count": 2,
        "draw_count": 1,
        "instant": True,
    },
    "Thrill of Possibility": {
        "effect": "draw_cards",
        "count": 2,
        "requires_discard_card": True,
        "instant": True,
    },
    "Fact or Fiction": {"effect": "draw_cards", "count": 3, "instant": True},
    "Peer into the Abyss": {"effect": "draw_cards", "count": 10},
    "Relic of Sauron": {"effect": "ramp_permanent", "mana_produced": 2, "produces": "UBR"},
    "Dramatic Reversal": {"effect": "ramp_ritual", "mana_produced": 2, "instant": True},
    "Flare of Duplication": {"effect": "copy_spell", "instant": True},
    "Run Away Together": {"effect": "remove_creature", "target": "creature", "instant": True},
    "Deafening Silence": {"effect": "passive"},
    "Monument to Endurance": {"effect": "passive"},
    "Growing Rites of Itlimoc": {"effect": "topdeck_manipulation"},
    "In the Darkness Bind Them": {
        "effect": "token_maker",
        "token_count": 3,
        "token_power": 3,
        "token_toughness": 3,
    },
    "Kinnan, Bonder Prodigy": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Ignoble Hierarch": {
        "effect": "creature",
        "power": 0,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "BRG",
        "is_creature_permanent": True,
    },
    "Noble Hierarch": {
        "effect": "creature",
        "power": 0,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "GWU",
        "is_creature_permanent": True,
    },
    "Avacyn's Pilgrim": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "W",
        "is_creature_permanent": True,
    },
    "Elvish Mystic": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Gilded Goose": {
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "keywords": ["flying"],
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
        "creates_food_on_etb": True,
    },
    "Elvish Spirit Guide": {"effect": "ramp_ritual", "mana_produced": 1, "produces": "G", "instant": True},
    "Tinder Wall": {
        "effect": "creature",
        "power": 0,
        "toughness": 3,
        "is_mana_source": True,
        "mana_produced": 2,
        "produces": "R",
        "is_creature_permanent": True,
    },
    "Ornithopter of Paradise": {
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "keywords": ["flying"],
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Myr Convert": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Circle of Dreams Druid": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 3,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Selvala, Heart of the Wilds": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_mana_source": True,
        "mana_produced": 3,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Magda, Brazen Outlaw": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Lotho, Corrupt Shirriff": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Notion Thief": {
        "effect": "creature",
        "power": 3,
        "toughness": 1,
        "keywords": ["flash"],
        "is_creature_permanent": True,
    },
    "Charming Prince": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Mulldrifter": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "keywords": ["flying"],
        "etb_draw_count": 2,
        "is_creature_permanent": True,
    },
    "Treasonous Ogre": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "R",
        "is_creature_permanent": True,
    },
    "Cavern-Hoard Dragon": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["flying", "haste", "trample"],
        "is_creature_permanent": True,
    },
    "Voltaic Key": {"effect": "passive"},
    "Lavaspur Boots": {"effect": "equipment_haste_shroud"},
    "Defense Grid": {"effect": "passive"},
    "Imposter Mech": {"effect": "passive"},
    "Page, Loose Leaf": {
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "\"Name Sticker\" Goblin": {"effect": "ramp_ritual", "mana_produced": 4, "produces": "R"},
    "The Balrog of Moria": {
        "effect": "creature",
        "power": 8,
        "toughness": 8,
        "is_creature_permanent": True,
    },
    "Burnt Offering": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "produces": "BR",
        "requires_sacrifice_creature": True,
        "instant": True,
    },
    "Sylvan Tutor": {"effect": "tutor", "target": "creature"},
    "Gene Pollinator": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Deadpool, Trading Card": {
        "effect": "creature",
        "power": 5,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Displace": {"effect": "phase_creatures", "instant": True},
    "Goblin Welder": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Greedy Freebooter": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Splinter's Technique": {"effect": "tutor", "target": "any"},
    "Vibrance": {
        "effect": "creature",
        "power": 4,
        "toughness": 4,
        "is_creature_permanent": True,
    },
}

HANDCRAFTED_KNOWN_CARDS = set(KNOWN_CARDS)

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
    type_line = str(card.get("type_line") or "")
    oracle_text = str(card.get("oracle_text") or "")
    text = f"{type_line}\n{oracle_text}".lower()

    if "land" in type_line.lower():
        normalized["effect"] = "land"
        normalized.pop("instant", None)
        normalized.pop("miracle", None)
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
        if re.search(r"\b(destroy|exile)\s+target\s+artifact\b", text):
            normalized["effect"] = "remove_permanent"
            return normalized
        normalized["effect"] = (
            "remove_creature" if "target creature" in text else "remove_permanent"
        )
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
    confidence=0.0,
    rule_version=None,
    logical_rule_key=None,
    oracle_hash=None,
):
    annotated = dict(effect_data)
    annotated.setdefault("_rule_source", source)
    annotated.setdefault("_rule_review_status", review_status)
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
    return fields


# ── KNOWN_CARDS Auto-Generator Loader (v8.4) ──
# Loads generated entries from known_cards_generated.json (handcrafted takes priority)
_gen_json_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'known_cards_generated.json')
if os.path.exists(_gen_json_path):
    try:
        with open(_gen_json_path) as _f:
            _generated = json.load(_f)
        for _name, _entry in _generated.items():
            if _name not in KNOWN_CARDS:  # never override handcrafted
                KNOWN_CARDS[_name] = _entry
    except Exception: pass
def get_card_effect(card):
    name = card.get("name", "")
    if name in HANDCRAFTED_KNOWN_CARDS:
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                KNOWN_CARDS[name],
                source="known_cards_manual",
                review_status="verified",
                confidence=1.0,
            ),
        )
    if battle_rule_registry is not None:
        rule = battle_rule_registry.lookup_battle_card_rule(DB, name)
        if rule and rule.get("effect_json"):
            effect = with_rule_metadata(
                rule["effect_json"],
                source=rule.get("source", "battle_card_rules"),
                review_status=rule.get("review_status", "unknown"),
                confidence=rule.get("confidence", 0.0),
                rule_version=rule.get("rule_version"),
                logical_rule_key=rule.get("logical_rule_key"),
                oracle_hash=rule.get("oracle_hash"),
            )
            return normalize_effect_by_oracle(card, effect)
    if name in KNOWN_CARDS:
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                KNOWN_CARDS[name],
                source="known_cards_generated",
                review_status="needs_review",
                confidence=0.55,
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
        for source in sources:
            produced = source.get("mana_produced", 1) if isinstance(source, dict) else 1
            colors = source_colors(source)
            # A source with multiple options is treated as flexible generic unless
            # the imported data specifies one concrete produced color.
            color = colors[0] if len(colors) == 1 else "generic"
            self.mana_pool.add(color, produced)
        emit_replay_event(
            "mana_refreshed",
            player=self.name,
            mana=self.available_mana(),
            sources=len(sources),
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

    def is_alive(self): return self.life > 0

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
                   "overload_recursion", "pump_all", "token_maker"}
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
        for _ in range(bottom_count):
            if player.hand:
                c = player.hand.pop(rng.randint(0, len(player.hand) - 1))
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
            "effect": (
                _opening_hand_effect(card).get("effect")
                or card.get("effect")
                or card.get("tag")
                or "unknown"
            ) if isinstance(card, dict) else "unknown",
        }
        for card in hand
    ]


def _opening_hand_can_satisfy_basic_additional_costs(card, effect_data, lands):
    if effect_data.get("requires_discard_land") and lands < 2:
        return False
    if effect_data.get("requires_sacrifice_land") and lands < 2:
        return False
    return True


def _opening_hand_has_early_plan(hand, lands):
    nonlands = [c for c in hand if not is_effective_land(c)]
    if not nonlands:
        return False, "all_lands", {}

    early_turn_window = 2 if lands == 2 else (4 if lands >= 5 else 3)
    evaluated = []
    for card in nonlands:
        effect_data = _opening_hand_effect(card)
        effect = effect_data.get("effect") or card.get("effect") or card.get("tag")
        cmc = _opening_hand_card_cmc(card)
        evaluated.append({
            "card": card.get("name", "?"),
            "cmc": cmc,
            "effect": effect,
        })
        if effect in ("counter", "unknown"):
            continue
        if effect == "ramp_ritual":
            continue
        if not _opening_hand_can_satisfy_basic_additional_costs(card, effect_data, lands):
            continue
        if cmc <= early_turn_window:
            return True, f"early_play:{card.get('name', '?')}:{cmc:g}", {
                "early_play": card.get("name", "?"),
                "early_play_cmc": cmc,
                "early_turn_window": early_turn_window,
                "evaluated_nonlands": evaluated,
            }

    for card in nonlands:
        effect_data = _opening_hand_effect(card)
        effect = effect_data.get("effect") or card.get("effect") or card.get("tag")
        cmc = _opening_hand_card_cmc(card)
        if effect in ("ramp_permanent", "land_ramp", "mana_dork") and cmc <= 2:
            if _opening_hand_can_satisfy_basic_additional_costs(card, effect_data, lands):
                return True, f"early_ramp:{card.get('name', '?')}:{cmc:g}", {
                    "early_ramp": card.get("name", "?"),
                    "early_ramp_cmc": cmc,
                    "early_turn_window": early_turn_window,
                    "evaluated_nonlands": evaluated,
                }

    return False, "no_play_before_turn_3", {
        "early_turn_window": early_turn_window,
        "evaluated_nonlands": evaluated,
    }


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
    if len(high_cost_cards) >= 3 and not has_plan:
        base["risk_flags"].append("expensive_dead_hand")
    return {
        **base,
        **plan_details,
        "keep": has_plan,
        "reason": reason if has_plan else "no_early_game_plan",
    }


def mulligan_decision(hand):
    evaluation = mulligan_evaluation(hand)
    return evaluation["keep"], 7


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
            },
            {
                "action": "mulligan",
                "lands": evaluation.get("lands"),
                "nonlands": evaluation.get("nonlands"),
                "reason": evaluation.get("reason"),
            },
        ],
        chosen_option={
            "action": chosen_action,
            "mulligan_count": mulligan_count,
            "forced_keep": forced_keep,
        },
        rejected_options=[
            {
                "action": "keep" if chosen_action == "mulligan" else "mulligan",
                "rejected_reason": "opening_hand_policy",
            }
        ],
        score_components={
            "lands": evaluation.get("lands"),
            "nonlands": evaluation.get("nonlands"),
            "colors": evaluation.get("colors"),
            "early_play": evaluation.get("early_play"),
            "early_ramp": evaluation.get("early_ramp"),
            "early_turn_window": evaluation.get("early_turn_window"),
            "high_cost_cards": evaluation.get("high_cost_cards"),
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
        move_creature_from_battlefield(target_controller, target)
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
    return next((player for player in all_players if player.has_won()), None)


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
        emit_decision_trace(
            decision_type="pass_no_action",
            player=active_player,
            turn=turn,
            phase=phase,
            available_options=[{"action": "pass"}],
            chosen_option={"action": "pass"},
            rejected_options=[],
            score_components={"stack_empty": 1, "main_phase_action_taken": 0},
            rule_source="battle_heuristic",
            rule_status="heuristic",
            confidence="medium",
            expected_benefit_score=0,
            actual_outcome="priority_pass",
            reason="empty_stack_no_action",
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
                    if eff.get("effect") in ("phase_out", "indestructible", "modal_boros_charm"):
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

    if effect_name == "draw_cards":
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
    return False, "last_land_spend_without_clear_payoff"


def pay_additional_card_costs(player, card, effect_data, *, turn=None):
    """Pay non-mana costs that materially affect battlefield validity."""
    if (
        not effect_data.get("requires_discard_card")
        and not effect_data.get("requires_discard_land")
        and not effect_data.get("requires_sacrifice_creature")
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
    if effect_data.get("requires_sacrifice_creature"):
        sacrifice = next(
            (
                permanent
                for permanent in player.battlefield
                if is_battlefield_creature(permanent)
                and not permanent.get("is_commander")
            ),
            None,
        )
        sacrifice = sacrifice or next(
            (
                permanent
                for permanent in player.battlefield
                if is_battlefield_creature(permanent)
            ),
            None,
        )
        if not sacrifice:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="sacrifice_creature",
                turn=turn,
            )
            return False
        destination = move_creature_from_battlefield(player, sacrifice)
        emit_replay_event(
            "additional_cost_paid",
            player=player.name,
            card=card.get("name", "?"),
            cost="sacrifice_creature",
            sacrificed=sacrifice.get("name", "?"),
            destination=destination,
            turn=turn,
        )
    return True


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


def should_cast_board_wipe(player, opponents):
    return board_wipe_decision_context(player, opponents)["timing_justified"]


def should_cast_wheel(player, opponents, effect_data):
    return wheel_decision_context(
        player,
        opponents,
        int(effect_data.get("count") or 0),
    )["timing_justified"]


def resolve_wheel_like_draw(player, opponents, card, draw_count, turn, rng):
    participants = [participant for participant in [player] + list(opponents) if participant.is_alive()]
    results = []
    total_opponent_drawn = 0
    for participant in participants:
        discarded_cards = list(participant.hand)
        participant.hand = []
        participant.graveyard.extend(discarded_cards)
        drawn = participant.draw(draw_count, rng)
        if participant is not player:
            total_opponent_drawn += len(drawn)
        results.append({
            "player": participant.name,
            "discarded": len(discarded_cards),
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
    count = int(effect_data.get("count") or 0)
    return count >= 7 or any(
        marker in name
        for marker in ("wheel", "windfall", "timetwister", "reforge")
    )


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
    elif effect in ("wincon", "approach", "finisher", "overload_recursion") and turn >= 5:
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
        if not isinstance(permanent, dict) or not permanent.get("land_tutor_activated"):
            continue
        if permanent.get("tapped") or permanent.get("summoning_sick"):
            continue
        if player.available_mana() < 2 or controlled_land_count(player) <= 1:
            continue
        land_to_sacrifice = next(
            (land for land in player.battlefield if isinstance(land, dict) and is_effective_land(land)),
            None,
        )
        land_to_find = next(
            (candidate for candidate in player.library if isinstance(candidate, dict) and is_effective_land(candidate)),
            None,
        )
        if not land_to_sacrifice or not land_to_find:
            continue
        player.spend_mana(2)
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
            return True

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
                    candidates.append((cmd, player.commander_tax))
            for candidate in player.hand:
                if candidate is ritual_card or is_effective_land(candidate):
                    continue
                candidate_effect = get_card_effect(candidate)
                if candidate_effect.get("effect") in ("counter", "unknown", "ramp_ritual"):
                    continue
                if not can_cast_in_phase(candidate, candidate_effect, phase):
                    continue
                candidates.append((candidate, 0))
            return candidates

        before = {
            id(candidate)
            for candidate, additional_generic in playable_candidates()
            if player.can_pay_card(candidate, additional_generic)
        }
        pool_snapshot = player.mana_pool.snapshot()
        restricted_snapshot = copy.deepcopy(player.restricted_mana)
        treasures_snapshot = player.treasures
        life_snapshot = player.life
        try:
            # Keep this check aligned with the current ritual resolution path.
            player.mana_pool.add_generic(ritual_mana_produced(player, ritual_effect))
            for candidate, additional_generic in playable_candidates():
                if id(candidate) in before:
                    continue
                if player.can_pay_card(candidate, additional_generic):
                    return True
            return False
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

    def restore_mana_snapshot(pool_snapshot, restricted_snapshot, treasures_snapshot, life_snapshot):
        for color, amount in pool_snapshot.items():
            setattr(player.mana_pool, color, amount)
        player.restricted_mana = restricted_snapshot
        player.treasures = treasures_snapshot
        player.life = life_snapshot

    def ramp_permanent_unlocks_meaningful_action(ramp_card, ramp_effect, *, allowed_roles=None):
        """Permanent fast mana may spend scarce land only with immediate payoff."""
        allowed_roles = set(allowed_roles or [])
        produced_mana = int(ramp_effect.get("mana_produced", 1) or 1)
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
                    return True
            return False
        finally:
            restore_mana_snapshot(pool_snapshot, restricted_snapshot, treasures_snapshot, life_snapshot)

    def ramp_resource_unlocks_same_turn_action(ramp_card, ramp_effect):
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
                return False
            count = int(ramp_effect.get("land_count") or ramp_effect.get("lands_to_battlefield") or 1)
            _targets, target_options = choose_land_ramp_targets(player, ramp_effect, count)
            allowed, _reason = land_sacrifice_has_strategic_benefit(
                strategic_risk_flags,
                target_options,
                count,
            )
            return allowed
        if not ramp_effect.get("requires_discard_land"):
            return True
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
            return False
        if not (
            "spending_last_land" in strategic_risk_flags
            or "spending_unique_color_land" in strategic_risk_flags
        ):
            return True
        return ramp_permanent_unlocks_meaningful_action(
            ramp_card,
            ramp_effect,
            allowed_roles={"commander"},
        )

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
        ramp_cards = [
            c for c in player.hand
            if player.can_pay_card(c)
            and get_card_effect(c).get("effect") in (
                "land_ramp",
                "land_recursion",
                "ramp_permanent",
                "ramp_engine",
                "ramp_ritual",
            )
            and ramp_resource_unlocks_same_turn_action(c, get_card_effect(c))
        ]
        for c in ramp_cards[:2]:
            eff = get_card_effect(c)
            if (
                c in player.hand
                and player.can_pay_card(c)
                and ramp_resource_unlocks_same_turn_action(c, eff)
            ):
                cast_ctx = begin_cast_context(player, c, phase, effect_data=eff, role="ramp")
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
                            action="cast_ramp",
                        )
                        for option_card in ramp_cards[:8]
                    ],
                    chosen_option=decision_card_option(c, eff, action="cast_ramp"),
                    rejected_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
                            action="defer_ramp",
                        )
                        for option_card in ramp_cards
                        if option_card is not c
                    ][:8],
                    score_components={
                        "role": "ramp",
                        "mana_before": mana,
                        "ramp_options": len(ramp_cards),
                        "unlocks_same_turn_action": 1
                        if eff.get("effect") == "ramp_ritual"
                        else 0,
                        "requires_discard_land": bool(eff.get("requires_discard_land")),
                        "requires_sacrifice_land": bool(eff.get("requires_sacrifice_land")),
                    },
                    rule_source=fields.get("rule_source", "battle_heuristic"),
                    rule_status=fields.get("rule_review_status", "heuristic"),
                    confidence="medium",
                    expected_benefit_score=max(1, int(c.get("cmc", 0) or 0) + 10),
                    actual_outcome="cast_and_resolve_ramp",
                    reason="early_mana_development",
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
                        "requires_discard_land": bool(eff.get("requires_discard_land")),
                        "requires_sacrifice_land": bool(eff.get("requires_sacrifice_land")),
                    },
                    risk_flags=[
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
                        )
                        if flag
                    ],
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
                    player.battlefield.append(permanent)
                    if is_mana_source_permanent(permanent):
                        colors = source_colors(permanent)
                        player.mana_pool.add(colors[0], permanent.get("mana_produced", 1))
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
                elif (
                    eff.get("effect") == "draw_cards"
                    and is_wheel_like_card(c, eff)
                    and not should_cast_wheel(player, opponents, eff)
                ):
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
            if (
                eff.get("effect") == "draw_cards"
                and is_wheel_like_card(c, eff)
                and not should_cast_wheel(player, opponents, eff)
            ):
                continue
            if eff.get("effect") == "creature":
                if not is_main_phase: continue  # creatures only in main phase
                cast_ctx = begin_cast_context(player, c, phase, effect_data=eff, role="creature")
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
                    chosen_option=decision_card_option(c, eff, action="cast_creature"),
                    rejected_options=[
                        decision_card_option(
                            option_card,
                            get_card_effect(option_card),
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
                    expected_benefit_score=max(1, int(c.get("power", 0) or 0) + int(c.get("cmc", 0) or 0)),
                    actual_outcome="creature_to_battlefield",
                    reason="lowest_cmc_castable_creature",
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

    if effect == "land": pass
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
    elif effect == "land_recursion_creature":
        resolve_land_recursion_creature(player, card, effect_data, turn)
    elif effect == "draw_cards":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            finish_resolved_spell(player, card, turn=turn)
            return
        n = effect_data.get("count", 2)
        if is_wheel_like_card(card, effect_data):
            context = wheel_decision_context(player, opponents, int(n or 0))
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
            resolve_wheel_like_draw(player, opponents, card, int(n or 0), turn, rng)
        else:
            player.draw(n, rng)
        finish_resolved_spell(player, card, turn=turn)
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
                move_creature_from_battlefield(opp, t)
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
            for c in p.battlefield:
                if is_battlefield_creature(c):
                    creatures_seen += 1
                    # v8: indestructible per-creature
                    if c.get("indestructible"):
                        survivors.append(c)
                        protected += 1
                        continue
                    unprotected_seen += 1
                    move_creature_from_battlefield(p, c)
                    destroyed += 1
                else:
                    survivors.append(c)
            p.battlefield = survivors
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
            player.win_reason = "approach"
            emit_replay_event(
                "game_won",
                player=player.name,
                reason="approach",
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
        player.draw(n, rng)
        for _ in range(min(n, len(player.hand))):
            if player.hand:
                player.graveyard.append(player.hand.pop(rng.randint(0, len(player.hand) - 1)))
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
            if is_battlefield_creature(c):
                c["summoning_sick"] = False
    # Return phased out permanents (v7 fix: should be upkeep, keeping simple here)
    player.battlefield.extend(player.phased_out)
    player.phased_out = []
    player.life_cant_change = False
    player.protection_from_everything = False
    player.refresh_mana_sources(turn)

    # ── UPKEEP (v8.3: The One Ring burden = draw 1 per turn if on board) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and c.get("burden"):
            for _ in range(sum(1 for _ in player.battlefield if isinstance(_, dict) and _.get("effect") == "draw_engine")):
                player.draw(1, rng)

    # ── DRAW ──
    drawn_for_turn = player.draw(1, rng)
    if check_sbas(all_players):
        return

    # v8: MIRACLE check
    if player.is_human and drawn_for_turn and player.cards_drawn_this_turn == 1:
        lorehold_on_board = any(isinstance(c, dict) and c.get("name") == "Lorehold, the Historian" for c in player.battlefield)
        last_drawn = drawn_for_turn[-1]
        if last_drawn and is_instant_or_sorcery_spell(last_drawn):
            miracle_cost = 2  # Lorehold gives miracle {2}
            if last_drawn.get("name") == "Reforge the Soul":
                miracle_cost = 2  # 1R but simplified
            mana = player.available_mana()
            if mana >= miracle_cost and lorehold_on_board:
                eff = get_card_effect(last_drawn)
                player.hand.remove(last_drawn)
                player.spend_mana(miracle_cost)
                emit_replay_event(
                    "miracle_cast",
                    player=player.name,
                    card=last_drawn.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=last_drawn.get("type_line", ""),
                    miracle_cost=miracle_cost,
                    lorehold_on_board=lorehold_on_board,
                    cards_drawn_this_turn=player.cards_drawn_this_turn,
                    turn=turn,
                    **replay_rule_fields(eff),
                )
                stack.push(last_drawn, player, eff)
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)

    # ── PRECOMBAT MAIN ──
    total_mana = player.available_mana()
    lands_in_hand = [c for c in player.hand if is_effective_land(c)]  # v10.2
    if lands_in_hand and player.lands_played_this_turn < player.max_lands_per_turn:
        land = lands_in_hand[0]
        eff = get_card_effect(land)
        player.hand.remove(land)
        land_permanent = enrich_card({**land, "effect": "land"})
        player.battlefield.append(land_permanent)
        player.lands_played_this_turn += 1
        player.mana_pool.add(source_colors(land_permanent)[0], 1)
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
    if game_winner(all_players):
        return
    if check_sbas(all_players): return


    # ── END STEP (v8.3) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and not c.get("burden"):
            player.draw(1, rng)
    process_warp_end_step(player, turn)
    
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
    while len(player.hand) > 7:
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


def main():
    metrics_path = os.environ.get("MANALOOM_ENGINE_METRICS_OUT")
    if metrics_path:
        set_engine_metrics(EngineMetrics())

    print("=" * 60)
    print("BATTLE ANALYST v8 — Interactive Commander (Priority + Stack + Miracle)")
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
    print(f"v8: Priority, Stack, Instant/Sorcery Timing, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste")

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

    GAMES = 50
    rng = random.Random(42)

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
    print(f"\n  OVERALL v8: WR={avg_wr:.1f}% ({total_wins}W/{total_losses}L/{total_stalls}S)")

    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(LOG_PATH, "a") as f:
        f.write(f"\n## [{ts}] Battle Analyst v8 — Interactive Commander\n")
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
