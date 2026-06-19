#!/usr/bin/env python3
"""Card Impact Analyzer — WDWR, WPWR, and loss-mode swap suggestions.

Importa e estende o battle engine ativo sem modificar o arquivo original.
Calcula When Drawn Win Rate, When Played Win Rate, e gera sugestoes
de swap baseadas nos modos de derrota (loss-mode-driven swaps).
"""

import argparse, hashlib, importlib.util, json, os, sqlite3, sys, random
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


def _is_deck_player(player_name: str, deck_name: str) -> bool:
    if not player_name:
        return False
    return player_name == deck_name or deck_name in player_name


def _event_card_name(evt: dict) -> str:
    return str(evt.get("card") or evt.get("card_name") or "").strip()


def _record_seen_card(games: dict, game_id: str, card_name: str) -> None:
    if card_name:
        games[game_id]["cards_seen"].add(card_name)


def _record_cast_card(games: dict, game_id: str, card_name: str) -> None:
    if card_name:
        games[game_id]["cards_cast"].add(card_name)
        games[game_id]["cards_seen"].add(card_name)


def _compute_from_replays(
    replays_dir: str,
    deck_name: str = "Lorehold",
    min_seen: int = 3,
    *,
    baseline_hash: str | None = None,
    min_usable_sample: int = 10,
):
    """Parse forensic replay JSONL files for Commander-safe card impact data.

    This is intentionally replay-derived. It does not ask the simulator to make
    new decisions and therefore can be used as a cheap post-run scorecard.
    """
    jsonl_files = sorted(
        [f for f in os.listdir(replays_dir) if f.endswith(".jsonl")],
        reverse=True,
    )
    replay_hash = hashlib.sha256()

    # Per-game: set of cards in hand, set of cards cast, won?
    games = {}

    for filename in jsonl_files:
        filepath = os.path.join(replays_dir, filename)
        game_id = filename.replace(".jsonl", "")

        if game_id not in games:
            games[game_id] = {"cards_seen": set(), "cards_cast": set(), "won": False}

        try:
            replay_hash.update(filename.encode("utf-8"))
            with open(filepath, "rb") as raw:
                content = raw.read()
            replay_hash.update(content)
            for line in content.decode("utf-8", errors="replace").splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    evt = json.loads(line)
                except json.JSONDecodeError:
                    continue

                player = evt.get("player", "")
                is_us = _is_deck_player(player, deck_name)
                evt_type = evt.get("event", "")

                if is_us:
                    if evt_type in {"spell_cast", "miracle_cast", "commander_cast"}:
                        _record_cast_card(games, game_id, _event_card_name(evt))
                    elif evt_type in {
                        "spell_resolved",
                        "topdeck_manipulation_activated",
                    }:
                        _record_seen_card(games, game_id, _event_card_name(evt))
                    if evt.get("drawn"):
                        drawn = evt.get("drawn")
                        if isinstance(drawn, list):
                            for card_name in drawn:
                                _record_seen_card(games, game_id, str(card_name))
                        else:
                            _record_seen_card(games, game_id, str(drawn))
                    for card_name in evt.get("drawn_cards") or []:
                        _record_seen_card(games, game_id, str(card_name))

                if evt_type == "game_won" and _is_deck_player(player, deck_name):
                    games[game_id]["won"] = True
                elif evt_type == "game_ended":
                    result = evt.get("result", "")
                    winner = str(evt.get("winner") or evt.get("player") or "")
                    if result == "win" and _is_deck_player(winner, deck_name):
                        games[game_id]["won"] = True
        except Exception:
            pass

    # Compute stats
    stats = defaultdict(lambda: {"seen": 0, "cast": 0, "won_when_seen": 0, "won_when_cast": 0})
    total_games = len(games)
    total_wins = sum(1 for data in games.values() if data["won"])
    baseline_wr = round(total_wins / total_games * 100, 1) if total_games else 0
    resolved_baseline_hash = baseline_hash or replay_hash.hexdigest()[:16]

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
        not_cast = max(0, total_games - s["cast"])
        won_when_not_cast = max(0, total_wins - s["won_when_cast"])
        seen_wr = round(s["won_when_seen"] / s["seen"] * 100, 1) if s["seen"] > 0 else 0
        cast_wr = round(s["won_when_cast"] / s["cast"] * 100, 1) if s["cast"] > 0 else None
        not_seen_wr = round(won_when_not_seen / not_seen * 100, 1) if not_seen > 0 else None
        not_cast_wr = round(won_when_not_cast / not_cast * 100, 1) if not_cast > 0 else None
        s["seen_wr"] = seen_wr
        s["cast_wr"] = cast_wr
        s["not_seen_wr"] = not_seen_wr
        s["not_cast_wr"] = not_cast_wr
        s["wdwr"] = seen_wr
        s["wpwr"] = cast_wr or 0
        s["wns_wr"] = not_seen_wr
        s["delta_vs_not_seen"] = (
            round(seen_wr - not_seen_wr, 1)
            if isinstance(not_seen_wr, (int, float))
            else None
        )
        s["delta_seen_vs_not_seen"] = s["delta_vs_not_seen"]
        s["delta_vs_baseline"] = round(seen_wr - baseline_wr, 1)
        s["delta_cast_vs_not_cast"] = (
            round(cast_wr - not_cast_wr, 1)
            if isinstance(cast_wr, (int, float)) and isinstance(not_cast_wr, (int, float))
            else None
        )
        s["not_seen"] = not_seen
        s["not_cast"] = not_cast
        s["won_when_not_seen"] = won_when_not_seen
        s["won_when_not_cast"] = won_when_not_cast
        s["sample_size"] = s["seen"]
        s["cast_sample_size"] = s["cast"]
        s["sample_quality"] = "low_sample" if s["seen"] < max(min_usable_sample, min_seen) else "usable"
        s["total_games"] = total_games
        s["baseline_wr"] = baseline_wr
        s["baseline_hash"] = resolved_baseline_hash
        result[card] = s

    return result


def _build_scorecard_summary(stats: dict) -> dict:
    """Build an operational conclusion around replay-derived card impact stats.

    The per-card metrics are useful, but they should not be treated as a swap
    gate unless the corpus has enough usable samples. This summary makes that
    guardrail explicit for Hermes/report consumers without changing the raw
    per-card JSON shape.
    """
    total_cards = len(stats)
    if not stats:
        return {
            "schema_version": "commander_safe_card_impact_summary_v1",
            "status": "blocked",
            "reason": "No replay-derived card data was found.",
            "cards_tracked": 0,
            "usable_cards": 0,
            "low_sample_cards": 0,
            "baseline_wr": 0,
            "baseline_hash": "unknown",
            "blockers": ["no_card_data"],
            "policy": {
                "auto_apply": False,
                "commander_safe": True,
                "requires_human_review_for_swaps": True,
            },
            "stats": stats,
        }

    values = list(stats.values())
    baseline_wr = values[0].get("baseline_wr", 0)
    baseline_hash = values[0].get("baseline_hash", "unknown")
    usable_cards = sum(1 for value in values if value.get("sample_quality") == "usable")
    low_sample_cards = sum(1 for value in values if value.get("sample_quality") == "low_sample")

    blockers = []
    status = "trusted"
    reason = "Replay corpus has usable per-card impact samples."

    if usable_cards == 0:
        status = "needs_more_samples"
        reason = "No tracked card reached the usable sample threshold."
        blockers.append("no_usable_card_samples")
    elif low_sample_cards > usable_cards:
        status = "needs_more_samples"
        reason = "Most tracked cards are still below the usable sample threshold."
        blockers.append("low_sample_majority")

    if baseline_hash == "unknown":
        status = "blocked"
        reason = "Baseline hash is unknown, so replay results are not reproducible."
        blockers.append("unknown_baseline_hash")

    return {
        "schema_version": "commander_safe_card_impact_summary_v1",
        "status": status,
        "reason": reason,
        "cards_tracked": total_cards,
        "usable_cards": usable_cards,
        "low_sample_cards": low_sample_cards,
        "baseline_wr": baseline_wr,
        "baseline_hash": baseline_hash,
        "blockers": blockers,
        "policy": {
            "auto_apply": False,
            "commander_safe": True,
            "requires_human_review_for_swaps": True,
        },
        "stats": stats,
    }


def main():
    parser = argparse.ArgumentParser(description="Card Impact Analyzer from forensic replays")
    parser.add_argument("--replay-dir",
        default=str(resolve_forensic_replays_dir()))
    parser.add_argument("--deck-name", default="Lorehold")
    parser.add_argument("--min-games", type=int, default=3)
    parser.add_argument("--min-usable-sample", type=int, default=10)
    parser.add_argument("--baseline-hash")
    parser.add_argument("--json-output")
    parser.add_argument("--json-summary-output")

    args = parser.parse_args()

    if not os.path.isdir(args.replay_dir):
        print(f"Replay dir not found: {args.replay_dir}")
        return 1

    print(f"=== Card Impact Analysis from Forensic Replays ===")
    print()

    stats = _compute_from_replays(
        args.replay_dir,
        args.deck_name,
        min_seen=args.min_games,
        baseline_hash=args.baseline_hash,
        min_usable_sample=args.min_usable_sample,
    )

    if not stats:
        print("No card data found. Run forensic audit first to generate replays.")
        return 1

    total_cards = len(stats)
    baseline = next(iter(stats.values())).get("baseline_wr", 0)
    baseline_hash = next(iter(stats.values())).get("baseline_hash", "unknown")
    summary = _build_scorecard_summary(stats)

    print(f"Cards tracked: {total_cards}")
    print(f"Baseline WR: {baseline:.1f}%")
    print(f"Baseline hash: {baseline_hash}")
    print(f"Scorecard status: {summary['status']} — {summary['reason']}")
    print()

    sorted_cards = sorted(stats.items(), key=lambda x: x[1]["wdwr"], reverse=True)

    print(f"Top 15 — Highest WDWR:")
    for card, s in sorted_cards[:15]:
        print(f"  {card[:35]:35s} seen_wr={s['seen_wr']:5.1f}% "
              f"seen={s['seen']:3d} cast={s['cast']:3d} "
              f"delta={s['delta_vs_baseline']:+.1f}pp "
              f"vs_not_seen={s.get('delta_seen_vs_not_seen')} "
              f"quality={s.get('sample_quality')}")

    print(f"\nBottom 15 — Lowest WDWR:")
    for card, s in sorted_cards[-15:]:
        print(f"  {card[:35]:35s} seen_wr={s['seen_wr']:5.1f}% "
              f"seen={s['seen']:3d} cast={s['cast']:3d} "
              f"delta={s['delta_vs_baseline']:+.1f}pp "
              f"vs_not_seen={s.get('delta_seen_vs_not_seen')} "
              f"quality={s.get('sample_quality')}")

    if args.json_output:
        output = Path(args.json_output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(stats, indent=2, sort_keys=True), encoding="utf-8")
        print(f"\nJSON written: {output}")

    if args.json_summary_output:
        output = Path(args.json_summary_output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(summary, indent=2, sort_keys=True),
            encoding="utf-8",
        )
        print(f"Summary JSON written: {output}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
