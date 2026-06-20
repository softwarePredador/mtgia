#!/usr/bin/env python3
"""Generate a structured step-by-step replay from Battle Analyst events."""

import importlib.util
import json
import os
import random
from pathlib import Path


BATTLE_PATH = os.environ.get(
    "BATTLE_ANALYST_PATH",
    str(Path(__file__).with_name("battle_analyst_v9.py")),
)
OUT = os.environ.get("REPLAY_OUT", "/tmp/battle_full_replay.txt")
EVENTS_OUT = os.environ.get("REPLAY_EVENTS_OUT", str(Path(OUT).with_suffix(".jsonl")))
DECISION_TRACE_OUT = os.environ.get(
    "DECISION_TRACE_OUT",
    str(Path(EVENTS_OUT).with_suffix(".decision_trace.jsonl")),
)
DECK_PROVENANCE_OUT = os.environ.get(
    "REPLAY_DECK_PROVENANCE_OUT",
    str(Path(EVENTS_OUT).with_suffix(".deck_provenance.json")),
)


def is_land_like(card):
    type_line = str(card.get("type_line") or "").lower()
    effect = str(card.get("effect") or "").lower()
    tags = {str(tag).lower() for tag in (card.get("functional_tags") or [])}
    return effect == "land" or "land" in type_line or "land" in tags


def deck_metrics(deck):
    cards = list(deck or [])
    lands = [card for card in cards if is_land_like(card)]
    nonlands = [card for card in cards if not is_land_like(card)]
    avg_cmc = sum(float(card.get("cmc") or 0) for card in nonlands) / max(1, len(nonlands))
    curve = {str(index): 0 for index in range(7)}
    curve["7+"] = 0
    for card in nonlands:
        try:
            cmc = int(float(card.get("cmc") or 0))
        except (TypeError, ValueError):
            cmc = 0
        bucket = "7+" if cmc >= 7 else str(max(0, cmc))
        curve[bucket] += 1
    return {
        "card_count": len(cards),
        "lands": len(lands),
        "nonlands": len(nonlands),
        "avg_cmc_nonlands": round(avg_cmc, 3),
        "curve": curve,
    }


def write_provenance_line(replay, item):
    metrics = item["metrics"]
    replay.write(
        "  {name}: source={source_kind} metrics={metrics_basis} "
        "cards={card_count} lands={lands} avg_nonland_cmc={avg_cmc:.2f} "
        "curve={curve} blockers={blockers}\n".format(
            name=item["name"],
            source_kind=item["source_kind"],
            metrics_basis=item["metrics_basis"],
            card_count=metrics["card_count"],
            lands=metrics["lands"],
            avg_cmc=metrics["avg_cmc_nonlands"],
            curve=json.dumps(metrics["curve"], sort_keys=True),
            blockers=item.get("blocker_domain") or "none",
        )
    )


def format_cost(cost):
    if not isinstance(cost, dict):
        return str(cost if cost not in (None, "") else "{}")
    parts = []
    generic = int(cost.get("generic") or 0)
    if generic:
        parts.append(f"generic={generic}")
    colored = cost.get("colored") or {}
    for color, amount in sorted(colored.items()):
        if amount:
            parts.append(f"{color}={amount}")
    for key in (
        "hybrid",
        "phyrexian",
        "phyrexian_hybrid",
        "monocolored_hybrid",
        "additional_costs",
    ):
        value = cost.get(key)
        if value:
            parts.append(f"{key}={value}")
    return "{" + ", ".join(parts) + "}" if parts else "{}"


def format_list(value):
    if not value:
        return "-"
    if isinstance(value, (list, tuple)):
        return ", ".join(str(item) for item in value) or "-"
    return str(value)


def format_board_snapshot(snapshot, limit=12):
    if not snapshot:
        return "-"
    names = []
    for item in snapshot[:limit]:
        if isinstance(item, dict):
            name = str(item.get("name") or "?")
            flags = []
            if item.get("tapped"):
                flags.append("tapped")
            effect = item.get("effect")
            if effect and effect not in {"land", "creature"}:
                flags.append(str(effect))
            names.append(name + (f" ({', '.join(flags)})" if flags else ""))
        else:
            names.append(str(item))
    if len(snapshot) > limit:
        names.append(f"+{len(snapshot) - limit} more")
    return ", ".join(names)


def format_life_note(data):
    parts = []
    if "life_before" in data or "life_after" in data:
        parts.append(f"life={data.get('life_before', '?')}->{data.get('life_after', '?')}")
    if data.get("life_paid"):
        parts.append(f"life_paid={data.get('life_paid')}")
    if data.get("life_gained"):
        parts.append(f"life_gained={data.get('life_gained')}")
    return " ".join(parts)


def write_replay_event(replay, event, data):
    if event == "turn_start":
        replay.write(
            "\nTURN {turn} - {player} | Life={life} Hand={hand} Board={board}\n".format(
                **data
            )
        )
    elif event == "land_played":
        replay.write(
            "  PLAY LAND {player}: {card} mana+={mana_produced} "
            "pool={mana_pool_after} rule={rule_source}/{rule_review_status}\n".format(
                **{
                    **data,
                    "mana_produced": data.get("mana_produced", "?"),
                    "mana_pool_after": data.get("mana_pool_after", {}),
                    "rule_source": data.get("rule_source", "?"),
                    "rule_review_status": data.get("rule_review_status", "?"),
                }
            )
        )
    elif event == "cast_announced":
        replay.write(
            "  ANNOUNCE {player}: {card} role={role} phase={phase} "
            "locked_cost={locked_cost} targets={targets}\n".format(
                **{
                    **data,
                    "locked_cost": format_cost(data.get("locked_cost")),
                    "targets": format_list(data.get("targets")),
                    "role": data.get("role", "-"),
                    "phase": data.get("phase", "-"),
                }
            )
        )
    elif event == "cost_paid":
        replay.write(
            "  PAY COST {player}: {card} cost={locked_cost} "
            "mana {mana_before}->{mana_after} life {life_before}->{life_after} "
            "life_paid={life_paid} pool={mana_pool_after}\n".format(
                **{
                    **data,
                    "locked_cost": format_cost(data.get("locked_cost")),
                    "life_paid": data.get("life_paid", 0),
                    "mana_pool_after": data.get("mana_pool_after", {}),
                }
            )
        )
    elif event == "cast_illegal":
        replay.write(
            "  ILLEGAL CAST {player}: {card} reason={reason} "
            "locked_cost={locked_cost} phase={phase}\n".format(
                **{
                    **data,
                    "locked_cost": format_cost(data.get("locked_cost")),
                    "reason": data.get("reason", "?"),
                    "phase": data.get("phase", "-"),
                }
            )
        )
    elif event in {
        "spell_cast",
        "creature_cast",
        "commander_cast",
        "miracle_cast",
        "end_step_instant",
        "adventure_cast",
        "adventure_creature_cast_from_exile",
    }:
        label = "CAST CREATURE" if event == "creature_cast" else "CAST"
        if event == "commander_cast":
            label = "CAST COMMANDER"
        elif event == "end_step_instant":
            label = "CAST INSTANT"
        replay.write(
            "  {label} {player}: {card} (CMC={cmc}) [{effect}] "
            "phase={phase} cost={locked_cost} rule={rule_source}/{rule_review_status}\n".format(
                **{
                    **data,
                    "label": label,
                    "cmc": data.get("cmc", "?"),
                    "effect": data.get("effect", "unknown"),
                    "phase": data.get("phase", "-"),
                    "locked_cost": format_cost(data.get("locked_cost")),
                    "rule_source": data.get("rule_source", "?"),
                    "rule_review_status": data.get("rule_review_status", "?"),
                }
            )
        )
    elif event == "spell_resolved":
        replay.write(
            "  RESOLVE SPELL {player}: {card} (CMC={cmc}) [{effect}] "
            "rule={rule_source}/{rule_review_status}\n".format(
                **{
                    **data,
                    "rule_source": data.get("rule_source", "?"),
                    "rule_review_status": data.get("rule_review_status", "?"),
                }
            )
        )
    elif event == "spell_countered":
        replay.write(
            "  COUNTER {player}: {counter} -> target={target} "
            "stack_object={stack_object} result={result} "
            "phase={phase} priority_window={priority_window} cost={cost}\n".format(
                **{
                    **data,
                    "target": data.get("target", "?"),
                    "stack_object": data.get("stack_object", data.get("target", "?")),
                    "result": data.get("result", "countered"),
                    "phase": data.get("phase", "?"),
                    "priority_window": data.get("priority_window", "?"),
                }
            )
        )
    elif event == "damage_resolved":
        life_note = format_life_note(data)
        replay.write(
            "  DAMAGE {player}: {card} -> {target} amount={amount} "
            "result={result} cause={cause}{life_note}\n".format(
                **{
                    **data,
                    "target": data.get("target_player") or data.get("target") or "?",
                    "amount": data.get("amount", "?"),
                    "result": data.get("result", "?"),
                    "cause": (
                        data.get("cause")
                        or data.get("effect")
                        or data.get("reason")
                        or data.get("source")
                        or data.get("card")
                        or "?"
                    ),
                    "life_note": f" {life_note}" if life_note else "",
                }
            )
        )
    elif event == "mana_refreshed":
        replay.write(
            "  MANA {player}: {mana} available "
            "({sources} sources, {treasures} treasures, pool={mana_pool})\n".format(
                **{**data, "mana_pool": data.get("mana_pool", {})},
            )
        )
    elif event == "trigger_put_on_stack":
        replay.write(
            "  TRIGGER {controller}: {source} event={trigger_event} "
            "stack={stack_depth}\n".format(
                **{
                    **data,
                    "controller": data.get("controller", data.get("player", "?")),
                    "source": data.get("source", data.get("card", "?")),
                    "trigger_event": data.get(
                        "trigger_event",
                        data.get("event_type", data.get("trigger", "?")),
                    ),
                    "stack_depth": data.get("stack_depth", data.get("timestamp", "?")),
                }
            )
        )
    elif event == "trigger_resolved":
        trigger_kind = (
            data.get("activation_kind")
            or data.get("trigger_kind")
            or data.get("trigger")
            or data.get("trigger_event")
            or data.get("event_type")
            or "?"
        )
        trigger_spell = data.get("trigger_spell")
        trigger_note = f" trigger_spell={trigger_spell}" if trigger_spell else ""
        replay.write(
            "  RESOLVE ABILITY {player}: {card} kind={activation_kind}{trigger_note}\n".format(
                **{
                    **data,
                    "card": data.get("card", data.get("source", "?")),
                    "activation_kind": trigger_kind,
                    "trigger_note": trigger_note,
                }
            )
        )
    elif event.endswith("_activated") or event == "activated_ability":
        replay.write(
            "  ACTIVATE {player}: {card} kind={activation_kind} mana_paid={mana_paid}{life_note}\n".format(
                **{
                    **data,
                    "card": data.get("card", data.get("source", "?")),
                    "activation_kind": data.get("activation_kind", "?"),
                    "mana_paid": data.get("mana_paid", data.get("activation_cost_generic", "-")),
                    "life_note": f" {format_life_note(data)}" if format_life_note(data) else "",
                }
            )
        )
    elif event == "combat":
        replay.write(
            "  COMBAT {attacker} -> {target}: "
            "{attackers} attackers, {blockers} blockers, "
            "{multi_blocks} gang blocks, {total_power} power "
            "(reason={target_reason}, target_life={target_life_before})\n".format(
                **{**data, "multi_blocks": data.get("multi_blocks", 0)},
            )
        )
    elif event == "combat_result":
        replay.write(
            "  DAMAGE {attacker} -> {target}: "
            "{damage_to_player} player damage, target life {target_life_after}, "
            "target_dead={target_dead}\n".format(**data)
        )
    elif event == "removal_resolved":
        replay.write(
            "  REMOVAL {player}: {card} removed {target} from {target_player}\n".format(
                **data
            )
        )
    elif event == "tutor_resolved":
        replay.write(
            "  TUTOR {player}: {card} found {found} ({target_type})\n".format(
                **data
            )
        )
    elif event == "turn_end":
        replay.write(
            "  END {player}: Life={life} Hand={hand} Board={board} "
            "Grave={graveyard} Discarded={discarded} "
            "Permanents=[{permanents}]\n".format(
                **{
                    **data,
                    "permanents": format_board_snapshot(data.get("board_snapshot") or []),
                }
            )
        )
    elif event == "player_eliminated":
        replay.write(
            "  >>> DIED: {player} ({reason}) <<<\n".format(**data)
        )
    elif event == "game_won":
        replay.write(
            "  >>> WIN: {player} ({reason}) turn {turn} <<<\n".format(**data)
        )
    elif format_life_note(data):
        replay.write(
            "  LIFE {player}: event={event} card={card} {life_note}\n".format(
                **{
                    **data,
                    "event": event,
                    "player": data.get("player", data.get("target", "?")),
                    "card": data.get("card", data.get("source", "-")),
                    "life_note": format_life_note(data),
                }
            )
        )


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_analyst_replay", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    battle = load_battle()

    Path(OUT).parent.mkdir(parents=True, exist_ok=True)
    Path(EVENTS_OUT).parent.mkdir(parents=True, exist_ok=True)
    Path(DECISION_TRACE_OUT).parent.mkdir(parents=True, exist_ok=True)
    replay_id = f"seed_{os.environ.get('REPLAY_SEED', '42')}"
    if hasattr(battle, "reset_decision_trace_counter"):
        battle.reset_decision_trace_counter()
    with (
        open(OUT, "w", encoding="utf-8") as replay,
        open(EVENTS_OUT, "w", encoding="utf-8") as events,
        open(DECISION_TRACE_OUT, "w", encoding="utf-8") as decisions,
    ):
        def log(event, data):
            events.write(
                json.dumps(
                    {
                        "event": event,
                        "replay_id": replay_id,
                        **data,
                    },
                    ensure_ascii=True,
                    sort_keys=True,
                    default=str,
                )
                + "\n"
            )
            events.flush()
            write_replay_event(replay, event, data)
            replay.flush()

        def log_decision(data):
            payload = {**data, "replay_id": data.get("replay_id") or replay_id}
            decisions.write(
                json.dumps(payload, ensure_ascii=True, sort_keys=True, default=str)
                + "\n"
            )
            decisions.flush()

        battle.REPLAY_EVENT_HANDLER = log
        battle.DECISION_TRACE_HANDLER = log_decision
        if hasattr(battle, "load_deck_with_construction_report"):
            commander, deck, construction_report = battle.load_deck_with_construction_report()
        else:
            commander, deck = battle.load_deck()
            construction_report = {}
        learned = battle.load_learned_opponents()
        source = learned if learned and len(learned) >= 3 else battle.OPPONENT_ARCHETYPES
        rng = random.Random(int(os.environ.get("REPLAY_SEED", "42")))
        picked = rng.sample(source, 3) if len(source) >= 3 else list(source)

        replay.write("=" * 70 + "\n")
        replay.write("BATTLE v10.3 - STRUCTURED REPLAY\n")
        replay.write(f"Commander: {commander['name']}\n")
        evaluation_target = (
            battle.evaluation_target_player_name()
            if hasattr(battle, "evaluation_target_player_name")
            else ""
        )
        evaluation_mode = (
            {
                "target_pressure": "target-deck-under-pressure",
                "table_intent": "table-intent-realistic",
                "free_for_all": "free-for-all",
            }.get(battle.battle_evaluation_mode(), battle.battle_evaluation_mode())
            if hasattr(battle, "battle_evaluation_mode")
            else ("target-deck-under-pressure" if evaluation_target else "free-for-all")
        )
        replay.write(f"Evaluation mode: {evaluation_mode}\n")
        if evaluation_target:
            replay.write(f"Evaluation target player: {evaluation_target}\n")
        replay.write(f"Opponents available: {len(source)}\n")
        replay.write(
            "Opponents picked: "
            + ", ".join(profile.get("name", "?") for profile in picked)
            + "\n"
        )
        replay.write("=" * 70 + "\n")

        lorehold = battle.Player(
            "Lorehold", commander, deck, is_human=True, strategy="spellslinger"
        )
        provenance = [
            {
                "name": "Lorehold",
                "source_kind": "sqlite_deck_cards",
                "source_ref": "deck_id:6",
                "metrics_basis": "runtime_derived_from_resolved_card_list",
                "cached_metadata_used_for_metrics": False,
                "metrics": deck_metrics(deck),
                "construction_report": construction_report,
                "blocker_domain": (
                    "deck_source"
                    if construction_report and not construction_report.get("is_valid", True)
                    else "none"
                ),
            }
        ]
        opponents = []
        for profile in picked:
            if profile.get("is_real") and profile.get("built_deck"):
                opp_cmd = battle.learned_opponent_commander_card(profile)
                opp = battle.Player(
                    profile["name"],
                    opp_cmd,
                    profile["built_deck"],
                    strategy=profile.get("strategy", "midrange"),
                )
                provenance.append({
                    "name": profile["name"],
                    "source_kind": "learned_decks",
                    "source_ref": f"learned_deck:{profile.get('learned_deck_id')}",
                    "source_system": profile.get("source"),
                    "source_card_count": profile.get("source_card_count"),
                    "battle_card_count": profile.get("battle_card_count"),
                    "metrics_basis": "runtime_derived_from_resolved_built_deck",
                    "cached_metadata_used_for_metrics": False,
                    "metrics": deck_metrics(profile["built_deck"]),
                    "commander": {
                        "name": opp_cmd.get("oracle_name") or opp_cmd.get("name"),
                        "cmc": opp_cmd.get("cmc"),
                        "mana_cost": opp_cmd.get("mana_cost"),
                        "type_line": opp_cmd.get("type_line"),
                        "power": opp_cmd.get("power"),
                        "toughness": opp_cmd.get("toughness"),
                        "metadata_source": opp_cmd.get("_commander_metadata_source"),
                    },
                    "blocker_domain": "none",
                })
            else:
                generated_deck = battle.generate_opponent_deck(profile)
                opp = battle.Player(
                    profile["name"],
                    battle.get_opponent_commander(profile),
                    generated_deck,
                    strategy=profile["strategy"],
                )
                provenance.append({
                    "name": profile["name"],
                    "source_kind": "generated_archetype",
                    "source_ref": str(profile.get("name") or "generic"),
                    "metrics_basis": "runtime_derived_from_generated_deck",
                    "cached_metadata_used_for_metrics": False,
                    "metrics": deck_metrics(generated_deck),
                    "blocker_domain": "none",
                })
            opponents.append(opp)

        all_players = [lorehold] + opponents
        stack = battle.Stack()

        replay.write("\nDECK SOURCE PROVENANCE\n")
        replay.write(
            "  Metrics are derived from the resolved runtime card lists; cached learned-deck metadata is not used for replay lands/CMC/curve.\n"
        )
        replay.write(
            "  Deck-source blockers are reported separately from battle-engine action/strategy/forensic blockers.\n"
        )
        for item in provenance:
            write_provenance_line(replay, item)
        Path(DECK_PROVENANCE_OUT).parent.mkdir(parents=True, exist_ok=True)
        Path(DECK_PROVENANCE_OUT).write_text(
            json.dumps(
                {
                    "replay_id": replay_id,
                    "metrics_policy": "runtime_derived_from_resolved_card_lists",
                    "cached_metadata_used_for_replay_metrics": False,
                    "blocker_domain_policy": (
                        "deck_source_or_legality_findings_are_reported_separately_from_battle_engine_findings"
                    ),
                    "decks": provenance,
                },
                indent=2,
                sort_keys=True,
                default=str,
            ),
            encoding="utf-8",
        )

        replay.write("\nMULLIGANS\n")
        for player in all_players:
            mulligans = battle.play_mulligan(player, rng)
            lands = sum(1 for card in player.hand if battle.is_land(card))
            replay.write(
                f"  {player.name}: {mulligans} mulligan(s), "
                f"{len(player.hand)} cards, {lands} lands\n"
            )

        turn = 0
        winner = None
        while turn < 25 and winner is None:
            turn += 1
            alive = [player for player in all_players if player.is_alive()]
            if len(alive) <= 1:
                winner = alive[0] if alive else None
                break
            for player in all_players:
                if not player.is_alive():
                    continue
                others = [other for other in all_players if other is not player]
                battle.play_turn_v8(player, others, all_players, turn, rng, stack)
                if not lorehold.is_alive():
                    winner = next(
                        (
                            candidate
                            for candidate in all_players
                            if candidate is not lorehold and candidate.is_alive()
                        ),
                        player if player is not lorehold and player.is_alive() else None,
                    )
                    break
                winner = next(
                    (candidate for candidate in all_players if candidate.has_won()),
                    None,
                )
                if winner is None:
                    survivors = [
                        candidate for candidate in all_players if candidate.is_alive()
                    ]
                    if len(survivors) <= 1:
                        winner = survivors[0] if survivors else None
                if winner is not None:
                    break

        replay.write(f"\nGAME OVER - Turn {turn}\n")
        reason = winner.win_reason if winner and winner.win_reason else (
            "elimination" if winner else "stall"
        )
        if winner and not winner.win_reason:
            log(
                "game_won",
                {
                    "player": winner.name,
                    "reason": reason,
                    "turn": turn,
                    "source": "replay_wrapper_survivor_inference",
                },
            )
        replay.write(f"Winner: {winner.name if winner else 'none'} ({reason})\n")
        for player in all_players:
            replay.write(
                f"{player.name}: {'ALIVE' if player.is_alive() else 'DEAD'} "
                f"Life={player.life} Hand={len(player.hand)}\n"
            )

    print(f"Replay: {OUT}")
    print(f"Replay events: {EVENTS_OUT}")
    print(f"Decision trace: {DECISION_TRACE_OUT}")


if __name__ == "__main__":
    main()
