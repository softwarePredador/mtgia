#!/usr/bin/env python3
"""Generate a structured step-by-step replay from Battle Analyst events."""

import importlib.util
import json
import os
import random
from pathlib import Path


BATTLE_PATH = os.environ.get(
    "BATTLE_ANALYST_PATH",
    str(Path(__file__).with_name("battle_analyst_v8.py")),
)
OUT = os.environ.get("REPLAY_OUT", "/tmp/battle_full_replay.txt")
EVENTS_OUT = os.environ.get("REPLAY_EVENTS_OUT", str(Path(OUT).with_suffix(".jsonl")))


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_analyst_replay", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    battle = load_battle()

    with open(OUT, "w", encoding="utf-8") as replay, open(EVENTS_OUT, "w", encoding="utf-8") as events:
        def log(event, data):
            events.write(
                json.dumps(
                    {
                        "event": event,
                        **data,
                    },
                    ensure_ascii=True,
                    sort_keys=True,
                    default=str,
                )
                + "\n"
            )
            events.flush()
            if event == "turn_start":
                replay.write(
                    "\nTURN {turn} - {player} | Life={life} Hand={hand} Board={board}\n".format(
                        **data
                    )
                )
            elif event == "spell_resolved":
                replay.write(
                    "  RESOLVE {player}: {card} (CMC={cmc}) [{effect}]\n".format(
                        **data
                    )
                )
            elif event == "spell_countered":
                replay.write(
                    "  COUNTER {player}: {counter} countered {target} "
                    "(cost={cost})\n".format(**data)
                )
            elif event == "mana_refreshed":
                replay.write(
                    "  MANA {player}: {mana} available "
                    "({sources} sources, {treasures} treasures, pool={mana_pool})\n".format(
                        **{**data, "mana_pool": data.get("mana_pool", {})},
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
                    "Grave={graveyard} Discarded={discarded}\n".format(**data)
                )
            elif event == "player_eliminated":
                replay.write(
                    "  >>> DIED: {player} ({reason}) <<<\n".format(**data)
                )
            elif event == "game_won":
                replay.write(
                    "  >>> WIN: {player} ({reason}) turn {turn} <<<\n".format(**data)
                )
            replay.flush()

        battle.REPLAY_EVENT_HANDLER = log
        commander, deck = battle.load_deck()
        learned = battle.load_learned_opponents()
        source = learned if learned and len(learned) >= 3 else battle.OPPONENT_ARCHETYPES
        rng = random.Random(int(os.environ.get("REPLAY_SEED", "42")))
        picked = [source[0]] + rng.sample(source[1:], 2)

        replay.write("=" * 70 + "\n")
        replay.write("BATTLE v10.3 - STRUCTURED REPLAY\n")
        replay.write(f"Commander: {commander['name']}\n")
        replay.write(f"Opponents available: {len(source)}\n")
        replay.write("=" * 70 + "\n")

        lorehold = battle.Player(
            "Lorehold", commander, deck, is_human=True, strategy="spellslinger"
        )
        opponents = []
        for profile in picked:
            if profile.get("is_real") and profile.get("built_deck"):
                opp_cmd = {
                    "name": profile["commander_name"],
                    "cmc": 4,
                    "tag": "creature",
                    "type_line": "Legendary Creature",
                    "is_commander": True,
                    "owner": profile["name"],
                }
                opp = battle.Player(
                    profile["name"],
                    opp_cmd,
                    profile["built_deck"],
                    strategy=profile.get("strategy", "midrange"),
                )
            else:
                opp = battle.Player(
                    profile["name"],
                    battle.get_opponent_commander(profile),
                    battle.generate_opponent_deck(profile),
                    strategy=profile["strategy"],
                )
            opponents.append(opp)

        all_players = [lorehold] + opponents
        stack = battle.Stack()

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
        replay.write(f"Winner: {winner.name if winner else 'none'} ({reason})\n")
        for player in all_players:
            replay.write(
                f"{player.name}: {'ALIVE' if player.is_alive() else 'DEAD'} "
                f"Life={player.life} Hand={len(player.hand)}\n"
            )

    print(f"Replay: {OUT}")
    print(f"Replay events: {EVENTS_OUT}")


if __name__ == "__main__":
    main()
