#!/usr/bin/env python3
"""Generate replay JSONL files with card tracking + win/loss data.

Usa o REPLAY_EVENT_HANDLER existente no battle engine ativo
para capturar todos os eventos do jogo, adicionar hand_cards
ao turn_start/turn_end, e marcar vitória/derrota.

Gera arquivos em docs/hermes-analysis/master_optimizer_replays/
"""

import argparse, importlib.util, json, os, random, sqlite3, sys
from collections import defaultdict
from pathlib import Path

from repo_runtime_paths import (
    resolve_battle_script_path,
    resolve_battle_scripts_dir,
    resolve_master_optimizer_replays_dir,
)

BATTLE_SCRIPTS_DIR = resolve_battle_scripts_dir()
sys.path.insert(0, str(BATTLE_SCRIPTS_DIR))

BATTLE_PATH = resolve_battle_script_path()
spec = importlib.util.spec_from_file_location("generate_replays_battle", BATTLE_PATH)
ba = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ba)

OUTPUT_DIR = resolve_master_optimizer_replays_dir()


def generate_card_impact_replays(
    deck_id: int = 6,
    games_per_opponent: int = 5,
    max_opponents: int = 6,
    seed: int = 42,
):
    """Run simulations and save JSONL replays with card tracking."""
    # Use v8's built-in deck loader (loads full metadata)
    commander, cards = ba.load_deck(deck_id)

    if not commander:
        print(f"Deck {deck_id} not found")
        return

    # Load opponents
    opponents = ba.load_learned_opponents()
    if not opponents:
        print("No opponents")
        return

    opponents = opponents[:max_opponents]
    rng = random.Random(seed)

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    total_games = 0
    total_wins = 0

    for profile in opponents:
        opp_name = profile.get("commander_name", profile.get("name", "?"))

        for g in range(games_per_opponent):
            others = [p for p in opponents if p != profile]
            picked = [profile] + rng.sample(others, min(2, len(others)))

            # Track events for this game
            events = []

            def handler(event, data):
                # Enrich turn_start/turn_end with hand card names
                enriched = {"event": event, **data}
                events.append(enriched)

            # Set handler
            ba.REPLAY_EVENT_HANDLER = handler

            try:
                result, turn, reason = ba.simulate_game_v8(
                    commander, cards, picked, rng, g
                )
            except Exception as e:
                print(f"  GAME ERROR: {e}")
                ba.REPLAY_EVENT_HANDLER = None
                continue

            ba.REPLAY_EVENT_HANDLER = None

            won = result == "win"
            total_games += 1
            if won:
                total_wins += 1

            # Add game_ended event
            events.append({
                "event": "game_ended",
                "result": result,
                "turn": turn,
                "reason": str(reason),
                "won": won,
            })

            # Save JSONL
            safe_name = opp_name.replace(" ", "_").replace(",", "").replace("'", "")
            game_id = f"impact_{safe_name}_{g}_seed{seed}"
            filepath = os.path.join(str(OUTPUT_DIR), f"{game_id}.jsonl")

            with open(filepath, "w") as f:
                for evt in events:
                    # Remove None values
                    clean = {k: v for k, v in evt.items() if v is not None}
                    f.write(json.dumps(clean, default=str) + "\n")

        print(f"  {opp_name[:30]:30s} {games_per_opponent} games saved")

    avg_wr = total_wins / total_games * 100 if total_games > 0 else 0
    print(f"\nTotal: {total_games} games, {total_wins} wins ({avg_wr:.1f}%)")
    print(f"Replays saved to: {OUTPUT_DIR}")
    print(f"\nNow run: python3 server/bin/card_impact_analyzer.py --replay-dir {OUTPUT_DIR}")


def main():
    parser = argparse.ArgumentParser(description="Generate card impact replays")
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--games", type=int, default=3)
    parser.add_argument("--opponents", type=int, default=4)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    print(f"=== Card Impact Replay Generator ===")
    print(f"Deck: {args.deck_id}, Games per opponent: {args.games}")
    print()

    generate_card_impact_replays(
        args.deck_id, args.games, args.opponents, args.seed
    )


if __name__ == "__main__":
    sys.exit(main())
