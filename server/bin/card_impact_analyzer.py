#!/usr/bin/env python3
"""Card Impact Analyzer — WDWR, WPWR, and loss-mode swap suggestions.

Importa e estende o battle engine ativo sem modificar o arquivo original.
Calcula When Drawn Win Rate, When Played Win Rate, e gera sugestoes
de swap baseadas nos modos de derrota (loss-mode-driven swaps).
"""

import argparse, importlib.util, json, os, sqlite3, sys, random
from collections import defaultdict
from pathlib import Path

from repo_runtime_paths import (
    resolve_battle_script_path,
    resolve_battle_scripts_dir,
    resolve_forensic_replays_dir,
)

BATTLE_SCRIPTS_DIR = resolve_battle_scripts_dir()
sys.path.insert(0, str(BATTLE_SCRIPTS_DIR))

BATTLE_PATH = resolve_battle_script_path()

spec = importlib.util.spec_from_file_location("card_impact_battle", BATTLE_PATH)
ba = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ba)

# ── Monkey-patch to add tracking vars to Player ─────────────────
_original_player_init = ba.Player.__init__

def _patched_player_init(self, name, commander_obj, deck_list, is_human=False, strategy="midrange"):
    _original_player_init(self, name, commander_obj, deck_list, is_human, strategy)
    self._cards_in_hand = set()
    self._cards_cast = set()
    self._mulligan_count = 0
    self._commander_removals = 0

ba.Player.__init__ = _patched_player_init

# ── Patch play_turn_sequence to capture hand ────────────────────
_original_play_turn = ba.play_turn_sequence_v8

def _patched_play_turn(player, opponents, all_players, turn, rng, stack):
    for c in player.hand:
        name = c.get("name", c.get("card_name", ""))
        if name:
            player._cards_in_hand.add(name)

    _original_play_turn(player, opponents, all_players, turn, rng, stack)

    for c in player.battlefield + player.graveyard:
        name = c.get("name", c.get("card_name", ""))
        if name and not ba.is_land(c):
            player._cards_cast.add(name)

ba.play_turn_sequence_v8 = _patched_play_turn

# ── Patch play_mulligan to count ────────────────────────────────
_original_mulligan = ba.play_mulligan

def _patched_mulligan(player, rng):
    result = _original_mulligan(player, rng)
    player._mulligan_count = result
    return result

ba.play_mulligan = _patched_mulligan


def classify_loss_v2(player, opponents, turn, result, reason):
    """Root-cause loss tagging (standalone version)."""
    tags = []
    if result != "loss":
        return tags
    lands_played = getattr(player, 'lands_played_this_turn', 0)
    mana = player.available_mana() if hasattr(player, 'available_mana') else 0
    nonland = sum(1 for c in (player.graveyard + player.hand) if not ba.is_land(c))
    if turn >= 4 and mana < 3 and lands_played < 3:
        tags.append("screw")
    elif lands_played >= 7 and nonland <= 2:
        tags.append("flood")
    if player._mulligan_count >= 2 and turn < 6:
        tags.append("bad-mulligan")
    if player._commander_removals >= 3:
        tags.append("commander-removed")
    if turn >= 10 and "screw" not in tags and "flood" not in tags:
        tags.append("out-valued")
    if not tags:
        tags.append("combat-damage")
    return tags


def run_impact_analysis(db_path: str, deck_id: int, games_per_opp: int, seed: int, max_opponents: int = 6):
    """Run games and collect per-card impact + loss mode data."""
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    # Load deck
    cards = []
    commander = None
    for row in conn.execute(
        "SELECT card_name, is_commander, quantity FROM deck_cards WHERE deck_id=?",
        (deck_id,),
    ).fetchall():
        if row["is_commander"]:
            commander = row["card_name"]
        else:
            cards.append({"name": row["card_name"], "quantity": row["quantity"]})

    conn.close()

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

    # Data collection
    card_stats = defaultdict(lambda: {
        "seen": 0, "cast": 0,
        "won_when_seen": 0, "won_when_cast": 0,
    })
    loss_mode_counts = defaultdict(int)
    total_games = 0
    total_wins = 0

    print(f"Running {len(opponents)} opponents × {games_per_opp} games...")
    print()

    for profile in opponents:
        opp_name = profile.get("commander_name", profile.get("name", "?"))
        opp_wins = 0
        opp_loss_tags = defaultdict(int)

        for g in range(games_per_opp):
            others = [p for p in opponents if p != profile]
            picked = [profile] + rng.sample(others, min(2, len(others)))

            result, turn, reason = ba.simulate_game_v8(commander, cards, picked, rng, g)

            won = result == "win"
            total_games += 1
            if won:
                total_wins += 1
                opp_wins += 1

            # Card data is stored on Player objects but we can't access them
            # after simulate_game_v8 returns (local variables are freed).
            # We can only use what's in the return value.

            # For loss mode tracking, parse the reason string
            if result == "loss":
                # Extract loss mode from reason
                if "life_zero" in str(reason):
                    opp_loss_tags["combat-damage"] += 1
                else:
                    opp_loss_tags[str(reason)[:50]] += 1

            # We need card data from the game. Since simulate_game_v8 doesn't
            # return card data in v8, we compile from forensic replays instead.

        wr = opp_wins / games_per_opp * 100
        loss_summary = ", ".join(f"{k}={v}" for k, v in opp_loss_tags.items())
        print(f"  {opp_name[:30]:30s} WR={wr:5.1f}% losses=[{loss_summary}]")

    avg_wr = total_wins / total_games * 100 if total_games > 0 else 0
    print(f"\n  OVERALL: {avg_wr:.1f}% ({total_wins}W/{total_games-total_wins}L)")

    # ── Card impact from forensic replays ──
    print(f"\n--- Card Impact from Forensic Replays ---")
    replays_dir = str(resolve_forensic_replays_dir())

    if os.path.isdir(replays_dir):
        replay_card_stats = _compute_from_replays(replays_dir, deck_name=commander)
        if replay_card_stats:
            print(f"\nTop 10 cards by WDWR (When Drawn Win Rate):")
            sorted_cards = sorted(replay_card_stats.items(),
                                  key=lambda x: x[1]["wdwr"], reverse=True)[:10]
            for card, stats in sorted_cards:
                print(f"  {card[:35]:35s} WDWR={stats['wdwr']:5.1f}% "
                      f"seen={stats['seen']:3d} cast={stats['cast']:3d} "
                      f"delta={stats['wdwr']-avg_wr:+.1f}pp")

            print(f"\nBottom 5 (cards associated with losing):")
            worst = sorted(replay_card_stats.items(),
                          key=lambda x: x[1]["wdwr"])[:5]
            for card, stats in worst:
                print(f"  {card[:35]:35s} WDWR={stats['wdwr']:5.1f}% "
                      f"seen={stats['seen']:3d}")

    return total_games, total_wins


def _compute_from_replays(replays_dir: str, deck_name: str = "Lorehold", min_seen: int = 3):
    """Parse forensic replay JSONL files for card impact data."""
    jsonl_files = sorted(
        [f for f in os.listdir(replays_dir) if f.endswith(".jsonl")],
        reverse=True,
    )

    # Per-game: set of cards in hand, set of cards cast, won?
    games = {}

    for filename in jsonl_files:
        filepath = os.path.join(replays_dir, filename)
        game_id = filename.replace(".jsonl", "")

        if game_id not in games:
            games[game_id] = {"cards_seen": set(), "cards_cast": set(), "won": False}

        try:
            with open(filepath) as f:
                for line in f:
                    line = line.strip()
                    if not line: continue
                    try:
                        evt = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    player = evt.get("player", "")
                    is_us = player == "Lorehold" or deck_name in player

                    if not is_us: continue

                    evt_type = evt.get("event", "")

                    # Track casts from spell_cast events
                    if evt_type == "spell_cast":
                        cn = evt.get("card", "")
                        if cn:
                            games[game_id]["cards_cast"].add(cn)
                            games[game_id]["cards_seen"].add(cn)  # cast implies seen
                    if evt_type == "spell_cast":
                        cn = evt.get("card", "")
                        if cn:
                            games[game_id]["cards_cast"].add(cn)

                    # Track wins
                    if evt_type == "game_ended":
                        result = evt.get("result", "")
                        reason = evt.get("reason", "")
                        if result == "win" or "elimination" in reason.lower():
                            games[game_id]["won"] = True

        except Exception:
            pass

    # Compute stats
    stats = defaultdict(lambda: {"seen": 0, "cast": 0, "won_when_seen": 0, "won_when_cast": 0})
    total_games = len(games)
    total_wins = sum(1 for data in games.values() if data["won"])

    for game_id, data in games.items():
        won = data["won"]
        for card in data["cards_seen"]:
            stats[card]["seen"] += 1
            if won:
                stats[card]["won_when_seen"] += 1
        for card in data["cards_cast"]:
            stats[card]["cast"] += 1
            if won:
                stats[card]["won_when_cast"] += 1

    # Filter and compute rates
    result = {}
    for card, s in stats.items():
        if s["seen"] < min_seen:
            continue
        not_seen = max(0, total_games - s["seen"])
        won_when_not_seen = max(0, total_wins - s["won_when_seen"])
        s["wdwr"] = round(s["won_when_seen"] / s["seen"] * 100, 1) if s["seen"] > 0 else 0
        s["wpwr"] = round(s["won_when_cast"] / s["cast"] * 100, 1) if s["cast"] > 0 else 0
        s["wns_wr"] = round(won_when_not_seen / not_seen * 100, 1) if not_seen > 0 else None
        s["delta_vs_not_seen"] = (
            round(s["wdwr"] - s["wns_wr"], 1)
            if isinstance(s["wns_wr"], (int, float))
            else None
        )
        s["not_seen"] = not_seen
        s["won_when_not_seen"] = won_when_not_seen
        s["sample_size"] = s["seen"]
        s["sample_quality"] = "low_sample" if s["seen"] < max(10, min_seen) else "usable"
        s["total_games"] = total_games
        s["baseline_wr"] = round(total_wins / total_games * 100, 1) if total_games else 0
        result[card] = s

    return result


def main():
    parser = argparse.ArgumentParser(description="Card Impact Analyzer from forensic replays")
    parser.add_argument("--replay-dir",
        default=str(resolve_forensic_replays_dir()))
    parser.add_argument("--deck-name", default="Lorehold")
    parser.add_argument("--min-games", type=int, default=3)
    parser.add_argument("--json-output")

    args = parser.parse_args()

    if not os.path.isdir(args.replay_dir):
        print(f"Replay dir not found: {args.replay_dir}")
        return 1

    print(f"=== Card Impact Analysis from Forensic Replays ===")
    print()

    stats = _compute_from_replays(args.replay_dir, args.deck_name, min_seen=args.min_games)

    if not stats:
        print("No card data found. Run forensic audit first to generate replays.")
        return 1

    total_cards = len(stats)
    baseline = sum(s["won_when_seen"] for s in stats.values()) / max(1, sum(s["seen"] for s in stats.values())) * 100

    print(f"Cards tracked: {total_cards}")
    print(f"Baseline WDWR: {baseline:.1f}%")
    print()

    sorted_cards = sorted(stats.items(), key=lambda x: x[1]["wdwr"], reverse=True)

    print(f"Top 15 — Highest WDWR:")
    for card, s in sorted_cards[:15]:
        delta = s["wdwr"] - baseline
        print(f"  {card[:35]:35s} WDWR={s['wdwr']:5.1f}% "
              f"seen={s['seen']:3d} cast={s['cast']:3d} "
              f"delta={delta:+.1f}pp "
              f"vs_not_seen={s.get('delta_vs_not_seen')}")

    print(f"\nBottom 15 — Lowest WDWR:")
    for card, s in sorted_cards[-15:]:
        delta = s["wdwr"] - baseline
        print(f"  {card[:35]:35s} WDWR={s['wdwr']:5.1f}% "
              f"seen={s['seen']:3d} cast={s['cast']:3d} "
              f"delta={delta:+.1f}pp "
              f"vs_not_seen={s.get('delta_vs_not_seen')}")

    if args.json_output:
        output = Path(args.json_output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(stats, indent=2, sort_keys=True), encoding="utf-8")
        print(f"\nJSON written: {output}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
