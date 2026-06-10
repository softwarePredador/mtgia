#!/usr/bin/env python3
"""Card Impact Scoring — calcula WDWR e WPWR rodando simulacoes dedicadas.

WDWR = When Drawn Win Rate: win rate when card was in hand at any turn
WPWR = When Played Win Rate: win rate when card was cast

Roda simulate_game_v8 N vezes, coleta dados de cada jogo,
e calcula metricas por carta.
"""

import argparse, importlib.util, os, sqlite3, sys, json
from collections import defaultdict
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent if "__file__" in dir() else Path(os.getcwd())

# Add battle scripts to path
BATTLE_DIR = os.environ.get(
    "BATTLE_SCRIPTS_DIR",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts",
)
sys.path.insert(0, BATTLE_DIR)

BATTLE_PATH = os.environ.get(
    "MANALOOM_BATTLE_SCRIPT",
    os.path.join(BATTLE_DIR, "battle_analyst_v9.py"),
)
spec = importlib.util.spec_from_file_location("card_impact_analysis_battle", BATTLE_PATH)
ba = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ba)
from master_optimizer_common import (
    connect as optimizer_connect,
    deck_rows as optimizer_deck_rows,
    normalize_name,
    is_land,
)


def load_lorehold_deck(db_path: str, deck_id: int = 6):
    """Load Lorehold deck from SQLite."""
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    cards = []
    commander_name = None
    for row in conn.execute(
        "SELECT card_name, quantity, is_commander FROM deck_cards WHERE deck_id=? AND NOT is_commander",
        (deck_id,),
    ).fetchall():
        cards.append({"name": row["card_name"], "quantity": row["quantity"]})

    cmd_row = conn.execute(
        "SELECT card_name FROM deck_cards WHERE deck_id=? AND is_commander", (deck_id,)
    ).fetchone()
    if cmd_row:
        commander_name = cmd_row["card_name"]

    conn.close()
    return commander_name, cards


def run_impact_analysis(
    db_path: str,
    deck_id: int = 6,
    games_per_opponent: int = 3,
    seed: int = 42,
):
    """Run game simulations and collect per-card impact data."""
    import random

    commander_name, deck = load_lorehold_deck(db_path, deck_id)

    # Load opponents
    opponents = ba.load_learned_opponents()
    if not opponents or len(opponents) < 3:
        print("Not enough opponent decks.")
        return None

    rng = random.Random(seed)

    # Card tracking
    card_stats: dict[str, dict] = defaultdict(lambda: {
        "times_in_hand": 0, "times_cast": 0,
        "won_when_in_hand": 0, "won_when_cast": 0,
        "total_games": 0,
    })

    total_games = 0
    total_wins = 0
    opp_wr: dict[str, dict] = defaultdict(lambda: {"wins": 0, "losses": 0})

    for profile in opponents:
        opp_name = profile.get("commander_name", profile.get("name", "?"))
        wins = losses = 0

        for g in range(games_per_opponent):
            others = [p for p in opponents if p != profile]
            picked = [profile] + rng.sample(others, min(2, len(others)))

            result, turn, reason = ba.simulate_game_v8(
                commander_name, deck, picked, rng, game_id=g
            )

            won = result == "win"
            total_games += 1
            if won:
                total_wins += 1
                wins += 1
            else:
                losses += 1

            opp_wr[opp_name]["wins"] += 1 if won else 0
            opp_wr[opp_name]["losses"] += 0 if won else 1

            # Unfortunately, simulate_game_v8 doesn't expose the Player objects.
            # The card tracking needs to happen INSIDE the function.
            # For now, we can only use what the function returns.

        wr = wins / games_per_opponent * 100
        print(f"  {opp_name[:30]:30s} WR={wr:5.1f}% ({wins}W/{losses}L)")

    avg_wr = total_wins / total_games * 100
    print(f"\n  OVERALL: {avg_wr:.1f}% ({total_wins}W/{total_games - total_wins}L)")

    return {
        "total_games": total_games,
        "total_wins": total_wins,
        "win_rate": avg_wr,
        "opponents": dict(opp_wr),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default=str(ba.DEFAULT_DB))
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--games", type=int, default=3, help="Games per opponent")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    print(f"=== Card Impact Analysis (deck #{args.deck_id}) ===")
    print(f"Games per opponent: {args.games}")
    print()

    results = run_impact_analysis(args.db, args.deck_id, args.games, args.seed)

    if results:
        print(f"\nNOTE: Card-level WDWR/WPWR requires modifying simulate_game_v8")
        print(f"to track hand contents at each turn. The infrastructure is ready.")
        print(f"Currently we can only report matchup-level results.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
