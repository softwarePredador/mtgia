#!/usr/bin/env python3
"""
Lorehold Battle Analyst — Win Rate Estimator
Simula goldfish (deck jogando sozinho) e mede velocidade de vitória.
Não depende de API externa — roda local com dados do SQLite.
"""
import sqlite3
import random
import json
import os
from datetime import datetime, timezone
from pathlib import Path

DB_PATH = "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
LOG_PATH = "docs/hermes-analysis/manaloom-knowledge/decks/lorehold-the-historian/BATTLE_LOG.md"


def load_deck(deck_id=6):
    """Load deck from SQLite."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT dc.card_name, dc.quantity, dc.cmc, dc.functional_tag,
               COALESCE(c.oracle_text, '') as oracle_text
        FROM deck_cards dc
        LEFT JOIN cards c ON LOWER(c.name) = LOWER(dc.card_name)
        WHERE dc.deck_id = ?
    """, (deck_id,)).fetchall()
    conn.close()
    
    deck = []
    for row in rows:
        for _ in range(row["quantity"]):
            deck.append({
                "name": row["card_name"],
                "cmc": row["cmc"] or 0,
                "tag": row["functional_tag"] or "unknown",
                "oracle": (row["oracle_text"] or "").lower(),
            })
    return deck


def is_land(card):
    return card["tag"] == "land" or "land" in card["oracle"][:50]


def is_ramp(card):
    return card["tag"] in ("ramp", "ritual") or "add {" in card["oracle"] or "search your library for a basic land" in card["oracle"]


def is_draw(card):
    return card["tag"] == "draw" or "draw a card" in card["oracle"]


def is_removal(card):
    return card["tag"] in ("removal", "board_wipe") or "destroy target" in card["oracle"] or "exile target" in card["oracle"]


def is_wincon(card):
    return card["tag"] in ("wincon", "combo_piece", "payoff") or "you win the game" in card["oracle"] or "opponent loses the game" in card["oracle"]


def goldfish_sim(deck, turns=10, trials=500):
    """
    Simulate goldfish games. A deck "wins" if it can present a win condition
    and has protection/removal to survive.
    
    Simplified model:
    - Draw 7, mulligan if <2 lands or >5 lands or no play by T3
    - Each turn: play land, play spells if mana allows
    - Win if: resolved wincon + survived long enough
    """
    wins = 0
    turns_to_win = []
    dead_draws = 0
    
    for _ in range(trials):
        deck_copy = list(deck)
        random.shuffle(deck_copy)
        hand = deck_copy[:7]
        library = deck_copy[7:]
        
        # Mulligan decision
        lands_in_hand = sum(1 for c in hand if is_land(c))
        playable_by_t3 = sum(1 for c in hand if c["cmc"] <= 3 and not is_land(c))
        
        mulligans = 0
        while (lands_in_hand < 2 or lands_in_hand > 5 or playable_by_t3 == 0) and mulligans < 2:
            mulligans += 1
            random.shuffle(deck_copy)
            hand = deck_copy[:7]
            library = deck_copy[7:]
            lands_in_hand = sum(1 for c in hand if is_land(c))
            playable_by_t3 = sum(1 for c in hand if c["cmc"] <= 3 and not is_land(c))
        
        battlefield = []
        graveyard = []
        mana_available = 0
        wincon_resolved = False
        win_turn = None
        
        for turn in range(1, turns + 1):
            # Draw
            if library:
                hand.append(library.pop(0))
            
            # Play land
            land_in_hand = [c for c in hand if is_land(c)]
            if land_in_hand:
                land = land_in_hand[0]
                hand.remove(land)
                battlefield.append(land)
                mana_available += 1
            
            # Play spells
            hand.sort(key=lambda c: c["cmc"])
            for card in list(hand):
                if card["cmc"] <= mana_available:
                    hand.remove(card)
                    mana_available -= card["cmc"]
                    
                    if is_ramp(card):
                        mana_available += 1  # Simplified: ramp gives +1 mana
                    if is_draw(card):
                        if library:
                            hand.append(library.pop(0))
                    if is_removal(card):
                        pass  # Keeps us alive
                    if is_wincon(card):
                        wincon_resolved = True
                        win_turn = turn
            
            # Check survival (simplified: need removal or wincon by turn 6-8)
            if turn >= 6 and not wincon_resolved:
                has_interaction = any(is_removal(c) or is_draw(c) for c in battlefield + hand)
                if not has_interaction:
                    break  # Died to opponent threat
        
        if wincon_resolved:
            wins += 1
            turns_to_win.append(win_turn)
        else:
            dead_draws += 1
    
    win_rate = (wins / trials) * 100
    avg_turns = sum(turns_to_win) / len(turns_to_win) if turns_to_win else 0
    
    return {
        "trials": trials,
        "wins": wins,
        "win_rate_pct": round(win_rate, 1),
        "avg_turns_to_win": round(avg_turns, 1),
        "dead_draws": dead_draws,
        "mulligan_forced_pct": round((trials - wins - dead_draws) / trials * 100, 1) if trials > 0 else 0,
    }


def load_previous_result():
    """Load the previous simulation result for delta comparison."""
    if not os.path.exists(LOG_PATH):
        return None
    
    with open(LOG_PATH) as f:
        content = f.read()
    
    # Extract last win_rate_pct from the log
    import re
    matches = re.findall(r'Win Rate: (\d+\.?\d*)%', content)
    if len(matches) >= 2:
        return float(matches[-2])
    return None


def main():
    deck = load_deck()
    print(f"Loaded {len(deck)} cards from SQLite")
    
    lands = sum(1 for c in deck if is_land(c))
    ramp = sum(1 for c in deck if is_ramp(c))
    draw = sum(1 for c in deck if is_draw(c))
    removal = sum(1 for c in deck if is_removal(c))
    wincons = sum(1 for c in deck if is_wincon(c))
    print(f"  Lands={lands}, Ramp={ramp}, Draw={draw}, Removal={removal}, Wincons={wincons}")
    
    result = goldfish_sim(deck, trials=1000)
    previous = load_previous_result()
    
    delta_str = ""
    if previous is not None:
        delta = result["win_rate_pct"] - previous
        direction = "+" if delta >= 0 else ""
        delta_str = f"  Delta: {direction}{delta:.1f}pp (was {previous:.1f}%)"
    
    print(f"\nResults (1000 trials):")
    print(f"  Win Rate: {result['win_rate_pct']}%{delta_str}")
    print(f"  Avg Turns to Win: {result['avg_turns_to_win']}")
    print(f"  Dead Draws: {result['dead_draws']}")
    
    # Write to battle log
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    
    with open(LOG_PATH, "a") as f:
        f.write(f"""
## [{timestamp}] Goldfish Battle Analysis

| Métrica | Valor |
|---|---|
| Trials | {result['trials']} |
| Win Rate | {result['win_rate_pct']}% |
| Avg Turns to Win | {result['avg_turns_to_win']} |
| Dead Draws | {result['dead_draws']} |
| Lands | {lands} |
| Ramp | {ramp} |
| Draw | {draw} |
| Removal | {removal} |
| Wincons | {wincons} |
{delta_str if delta_str else ""}
---
""")
    
    print(f"\nBattle log updated: {LOG_PATH}")
    
    # Signal: improvement or regression
    if previous is not None and result['win_rate_pct'] < previous - 1:
        print("⚠️  WIN RATE DROPPED — evolution should review recent swaps")
    elif previous is not None and result['win_rate_pct'] > previous + 3:
        print("✅ WIN RATE IMPROVED — swaps are working!")


if __name__ == "__main__":
    main()
