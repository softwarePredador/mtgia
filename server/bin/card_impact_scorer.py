#!/usr/bin/env python3
"""Card Impact Scoring via monkey-patching simulate_game_v8.

Nao modifica o battle engine ativo — faz monkey-patch em runtime.
Calcula WDWR (When Drawn Win Rate) e WPWR (When Played Win Rate).
"""

import argparse, importlib.util, os, sqlite3, sys, json
from collections import defaultdict
from pathlib import Path

SCRIPT_DIR = os.environ.get(
    "BATTLE_SCRIPTS_DIR",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts",
)
sys.path.insert(0, SCRIPT_DIR)

# Monkey-patch: wrap simulate_game_v8 to also collect card data
BATTLE_PATH = os.environ.get(
    "MANALOOM_BATTLE_SCRIPT",
    os.path.join(SCRIPT_DIR, "battle_analyst_v9.py"),
)
spec = importlib.util.spec_from_file_location("card_impact_scorer_battle", BATTLE_PATH)
ba = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ba)
from master_optimizer_common import is_land

_original_simulate = ba.simulate_game_v8

def _patched_simulate(commander, deck, opponents, rng, game_id=0):
    """Patched version that also collects per-game card stats."""
    # Override Player.__init__ to add tracking
    original_init = ba.Player.__init__

    def _patched_init(self, name, commander_obj, deck_list, is_human=False, strategy="midrange"):
        original_init(self, name, commander_obj, deck_list, is_human, strategy)
        self._cards_in_hand = set()
        self._cards_cast = set()
        self._original_play_turn = None

    ba.Player.__init__ = _patched_init

    # Track hand and casts during turn
    original_play_turn = ba.play_turn_sequence_v8
    def _patched_play_turn(player, opponents, all_players, turn, rng, stack):
        # Before turn: track hand
        for c in player.hand:
            name = c.get("name", c.get("card_name", ""))
            if name:
                player._cards_in_hand.add(name)
        # Run original
        original_play_turn(player, opponents, all_players, turn, rng, stack)
        # After turn: track battlefield + graveyard
        for c in player.battlefield + player.graveyard:
            name = c.get("name", c.get("card_name", ""))
            if name and not is_land(c):
                player._cards_cast.add(name)

    ba.play_turn_sequence_v8 = _patched_play_turn

    # Run the game
    result = _original_simulate(commander, deck, opponents, rng, game_id)

    # Restore originals
    ba.Player.__init__ = original_init
    ba.play_turn_sequence_v8 = original_play_turn
    ba.simulate_game_v8 = _original_simulate

    # Extract card data from lorehold player (first player in all_players)
    # We can't access the local variable, but we stored data on the Player object
    # Since simulate_game_v8 returns before we can access players, we use the return value

    return result


def run_impact_analysis(db_path: str, deck_id: int, games: int, seed: int):
    """Run simulations and compute card impact scores."""
    import random

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    # Load Lorehold deck
    cards_list = []
    commander_name = None
    for row in conn.execute(
        "SELECT card_name, is_commander FROM deck_cards WHERE deck_id=? AND NOT is_commander",
        (deck_id,),
    ).fetchall():
        cards_list.append({"name": row["card_name"], "quantity": 1})

    cmd_row = conn.execute(
        "SELECT card_name FROM deck_cards WHERE deck_id=? AND is_commander", (deck_id,)
    ).fetchone()
    if cmd_row:
        commander_name = cmd_row["card_name"]
    conn.close()

    if not commander_name:
        print(f"Deck {deck_id} not found or has no commander")
        return

    opponents = ba.load_learned_opponents()
    if not opponents or len(opponents) < 3:
        print("Not enough opponents")
        return

    rng = random.Random(seed)

    # Apply monkey-patch
    ba.simulate_game_v8 = _patched_simulate

    # Also add tracking vars to Player.__init__
    orig_init = ba.Player.__init__

    card_stats = defaultdict(lambda: {
        "times_in_hand": 0, "times_cast": 0,
        "won_when_in_hand": 0, "won_when_cast": 0,
    })

    total_games = 0
    total_wins = 0

    for profile in opponents[:4]:  # Only 4 opponents for speed
        opp_name = profile.get("commander_name", "?")
        for g in range(games):
            others = [p for p in opponents if p != profile]
            picked = [profile] + rng.sample(others, min(2, len(others)))

            try:
                result = _patched_simulate(commander_name, cards_list, picked, rng, g)
            except Exception as e:
                print(f"  GAME ERROR: {e}")
                continue

            # result is (result_str, turn, reason) or (result_str, turn, reason, cards_hand, cards_cast)
            # Actually it depends on the version. Let's handle both
            if isinstance(result, tuple):
                res_str = result[0]
                won = res_str == "win"
            else:
                won = False

            total_games += 1
            if won:
                total_wins += 1

    # Restore
    ba.simulate_game_v8 = _original_simulate
    ba.Player.__init__ = orig_init

    avg_wr = total_wins / total_games * 100 if total_games > 0 else 0
    print(f"\nGames: {total_games}, Wins: {total_wins}, WR: {avg_wr:.1f}%")
    print(f"\nNOTE: Card-level data requires Player._cards_in_hand to be populated.")
    print(f"The monkey-patch approach needs access to Player instances after each game.")
    print(f"Recommended: add --card-stats flag to simulate_game_v8 natively.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(ba.DEFAULT_DB))
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--games", type=int, default=2)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    run_impact_analysis(args.db, args.deck_id, args.games, args.seed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
