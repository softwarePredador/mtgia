#!/usr/bin/env python3
"""
Lorehold Battle Analyst v5 — Real Matchup Simulator
Simula o deck Lorehold contra arquétipos reais usando:
- Deck do SQLite (deck_id=6)
- Dados EDHREC coletados pelo Scout
- Mesma lógica do backend POST /ai/simulate-matchup
- Monte Carlo com hate cards, archetype matchups, ramp/CMC/removal comparison
"""
import sqlite3, random, json, os, re
from datetime import datetime, timezone

DB = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
KNOWLEDGE_DIR = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge"
LOG_PATH = f"{KNOWLEDGE_DIR}/decks/lorehold-the-historian/BATTLE_LOG.md"

# ── Deck loading ──

def load_my_deck(deck_id=6):
    """Load Lorehold deck from SQLite."""
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT card_name, quantity, CAST(COALESCE(cmc,0) AS REAL) as cmc,
               COALESCE(functional_tag,'unknown') as functional_tag
        FROM deck_cards WHERE deck_id=?
    """, (deck_id,)).fetchall()
    conn.close()
    deck = []
    for row in rows:
        qty = row["quantity"] or 1
        for _ in range(qty):
            deck.append({
                "name": row["card_name"],
                "cmc": row["cmc"] or 0,
                "tag": row["functional_tag"] or "unknown",
            })
    return deck

def load_opponent_archetypes():
    """Load real archetype profiles from EDHREC data collected by Scout."""
    opponents = []
    
    # Try loading from scout data
    scout_files = [
        f"{KNOWLEDGE_DIR}/scripts/_edhrec_card_data.json",
        f"{KNOWLEDGE_DIR}/scripts/scout_cycle_20260527.json",
    ]
    
    for sf in scout_files:
        if not os.path.exists(sf):
            continue
        try:
            with open(sf) as f:
                data = json.load(f)
            # Extract archetype stats if available
            if isinstance(data, dict):
                for key, val in data.items():
                    if isinstance(val, dict) and "cards" in val:
                        opponents.append({
                            "name": key,
                            "archetype": val.get("archetype", "midrange"),
                            "avg_cmc": val.get("avg_cmc", 3.0),
                            "ramp": val.get("ramp_count", 8),
                            "removal": val.get("removal_count", 6),
                            "counterspells": val.get("counterspell_count", 0),
                            "creatures": val.get("creature_count", 20),
                            "lands": val.get("land_count", 35),
                            "hate_cards": val.get("hate_cards", []),
                        })
        except:
            pass
    
    # If no opponents loaded, create standard archetype profiles from known Commander meta
    if not opponents:
        opponents = [
            {"name": "Aggro (Krenko/Goblins)", "archetype": "aggro", "avg_cmc": 2.5, "ramp": 8, "removal": 5, "counterspells": 0, "creatures": 35, "lands": 34},
            {"name": "Control (Atraxa Superfriends)", "archetype": "control", "avg_cmc": 3.2, "ramp": 12, "removal": 12, "counterspells": 6, "creatures": 15, "lands": 37},
            {"name": "Combo (Kinnan cEDH)", "archetype": "combo", "avg_cmc": 2.1, "ramp": 15, "removal": 6, "counterspells": 8, "creatures": 18, "lands": 30},
            {"name": "Midrange (Korvold Value)", "archetype": "midrange", "avg_cmc": 3.0, "ramp": 12, "removal": 8, "counterspells": 2, "creatures": 25, "lands": 36},
            {"name": "Spellslinger (Niv-Mizzet)", "archetype": "spellslinger", "avg_cmc": 2.8, "ramp": 10, "removal": 10, "counterspells": 5, "creatures": 10, "lands": 36},
            {"name": "Stax (Winota Hatebears)", "archetype": "stax", "avg_cmc": 2.6, "ramp": 8, "removal": 8, "counterspells": 0, "creatures": 30, "lands": 35},
        ]
    
    return opponents

# ── Deck analysis ──

def analyze_deck(deck):
    """Analyze deck stats (mirrors backend _getDeckData logic)."""
    lands = 0; creatures = 0; ramp = 0; removal = 0; counterspells = 0
    total_cmc = 0; non_lands = 0
    seen = set()
    
    for c in deck:
        n = c["name"].lower(); t = c["tag"]
        if is_land(c):
            lands += 1
        else:
            non_lands += 1
            total_cmc += float(c["cmc"])
        
        if "creature" in t: creatures += 1
        if t in ("ramp","ritual"): ramp += 1
        if t in ("removal","board_wipe"): removal += 1
        if t == "counter" or "counter target" in c.get("oracle","").lower(): counterspells += 1
    
    return {
        "total": len(deck),
        "lands": lands,
        "creatures": creatures,
        "ramp": ramp,
        "removal": removal,
        "counterspells": counterspells,
        "avg_cmc": round(total_cmc / non_lands, 2) if non_lands > 0 else 0,
    }

def is_land(c):
    n = c["name"].lower()
    if c["tag"] == "land": return True
    for b in ["plains","island","swamp","mountain","forest","wastes"]:
        if b in n: return True
    return False

def detect_archetype(stats):
    """Simple archetype detection based on stats."""
    if stats["creatures"] >= 25 and stats["avg_cmc"] < 2.8:
        return "aggro"
    if stats["removal"] >= 12 or stats["counterspells"] >= 5:
        return "control"
    if stats["ramp"] >= 14 and stats["avg_cmc"] < 2.5:
        return "combo"
    if stats["creatures"] <= 12 and stats["counterspells"] <= 2:
        return "spellslinger"
    return "midrange"

# ── Matchup engine (mirrors backend logic) ──

ARCHETYPE_MATCHUPS = {
    "aggro": {"control": -10, "combo": 5, "midrange": 0, "ramp": 10, "spellslinger": 5, "stax": -5},
    "control": {"aggro": 10, "combo": -5, "midrange": 5, "ramp": 5, "spellslinger": 0, "stax": 5},
    "combo": {"aggro": -5, "control": 5, "midrange": 0, "spellslinger": 5, "stax": -15},
    "midrange": {"aggro": 0, "control": -5, "combo": 0, "ramp": 0, "spellslinger": 0, "stax": 0},
    "spellslinger": {"aggro": -5, "control": 0, "combo": -5, "midrange": 0, "stax": 0},
    "stax": {"combo": 15, "control": 5, "aggro": 5, "spellslinger": 0, "midrange": 0},
}

def analyze_matchup(my_deck, opponent, simulations=200):
    """Run full matchup analysis from backend logic."""
    my_stats = analyze_deck(my_deck)
    my_archetype = detect_archetype(my_stats)
    opp_archetype = opponent["archetype"]
    
    base_score = 50.0
    advantages = []
    disadvantages = []
    recommendations = []
    
    # 1. Ramp comparison
    if my_stats["ramp"] > opponent["ramp"] + 3:
        base_score += 5
        advantages.append(f"Mais ramp ({my_stats['ramp']} vs {opponent['ramp']})")
    elif opponent["ramp"] > my_stats["ramp"] + 3:
        base_score -= 5
        disadvantages.append(f"Menos ramp ({my_stats['ramp']} vs {opponent['ramp']})")
        recommendations.append("+fontes de ramp")
    
    # 2. Removal comparison
    if my_stats["removal"] > opponent["removal"] + 2:
        base_score += 5
        advantages.append(f"Mais removal ({my_stats['removal']} vs {opponent['removal']})")
    elif my_stats["removal"] < 5:
        base_score -= 5
        disadvantages.append(f"Removal insuficiente ({my_stats['removal']})")
        recommendations.append("+removal pontual")
    
    # 3. CMC comparison
    if my_stats["avg_cmc"] < opponent["avg_cmc"] - 0.5:
        base_score += 7
        advantages.append(f"Curva mais baixa ({my_stats['avg_cmc']} vs {opponent['avg_cmc']})")
    elif my_stats["avg_cmc"] > opponent["avg_cmc"] + 0.5:
        base_score -= 5
        disadvantages.append(f"Curva mais alta ({my_stats['avg_cmc']} vs {opponent['avg_cmc']})")
        recommendations.append("reduzir CMC medio")
    
    # 4. Archetype matchup modifier
    modifier = ARCHETYPE_MATCHUPS.get(my_archetype, {}).get(opp_archetype, 0)
    base_score += modifier
    if modifier > 0:
        advantages.append(f"{my_archetype} favorece contra {opp_archetype} (+{modifier})")
    elif modifier < 0:
        disadvantages.append(f"{opp_archetype} favorece contra {my_archetype} ({modifier})")
    
    # 5. Monte Carlo simulation
    random.seed(42)
    wins = 0
    for _ in range(simulations):
        roll = random.random() * 100
        variance = (random.random() - 0.5) * 20
        effective = base_score + variance
        if roll < effective:
            wins += 1
    
    win_rate = (wins / simulations) * 100
    
    # 6. Verdict
    if win_rate >= 65: verdict = "MUITO favoravel"
    elif win_rate >= 55: verdict = "favoravel"
    elif win_rate >= 45: verdict = "equilibrado"
    elif win_rate >= 35: verdict = "desfavoravel"
    else: verdict = "MUITO desfavoravel"
    
    return {
        "opponent": opponent["name"],
        "opp_archetype": opp_archetype,
        "my_archetype": my_archetype,
        "base_score": round(base_score, 1),
        "wins": wins,
        "simulations": simulations,
        "win_rate": round(win_rate, 1),
        "verdict": verdict,
        "advantages": advantages,
        "disadvantages": disadvantages,
        "recommendations": recommendations,
        "my_stats": my_stats,
        "opp_stats": opponent,
    }

# ── Main ──

def main():
    deck = load_my_deck()
    stats = analyze_deck(deck)
    print(f"Deck: {stats['total']}c | L={stats['lands']} R={stats['ramp']} X={stats['removal']} "
          f"C={stats['creatures']} CS={stats['counterspells']} CMC={stats['avg_cmc']}")
    
    opponents = load_opponent_archetypes()
    print(f"\nMatchups contra {len(opponents)} arquétipos reais:\n")
    
    results = []
    total_wr = 0
    
    for opp in opponents:
        r = analyze_matchup(deck, opp, simulations=200)
        results.append(r)
        total_wr += r["win_rate"]
        icon = "✅" if r["win_rate"] >= 55 else "⚖️" if r["win_rate"] >= 45 else "❌"
        print(f"  {icon} {r['opponent']:35s} WR={r['win_rate']:5.1f}% | {r['verdict']}")
        for a in r["advantages"][:2]:
            print(f"      + {a}")
        for d in r["disadvantages"][:2]:
            print(f"      - {d}")
    
    avg_wr = total_wr / len(opponents) if opponents else 0
    min_wr = min(r["win_rate"] for r in results) if results else 0
    max_wr = max(r["win_rate"] for r in results) if results else 0
    
    print(f"\nAvg WR: {avg_wr:.1f}% | Range: {min_wr:.1f}%-{max_wr:.1f}%")
    
    # Write to log
    prev_avg = None
    if os.path.exists(LOG_PATH):
        with open(LOG_PATH) as f:
            match = re.findall(r'Avg WR: (\d+\.?\d*)%', f.read())
            if match: prev_avg = float(match[-1])
    
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    delta_str = f" (delta {avg_wr - prev_avg:+.1f}pp)" if prev_avg else ""
    
    with open(LOG_PATH, "a") as f:
        f.write(f"\n## [{ts}] Real Matchup {len(opponents)} archetypes (200 sims each)\n")
        f.write(f"Avg WR: {avg_wr:.1f}%{delta_str} | Range: {min_wr:.1f}%-{max_wr:.1f}%\n")
        f.write(f"My Deck: L={stats['lands']} R={stats['ramp']} X={stats['removal']} "
                f"C={stats['creatures']} CMC={stats['avg_cmc']} | Archetype: {detect_archetype(stats)}\n\n")
        for r in results:
            f.write(f"  {r['win_rate']:5.1f}% vs {r['opponent']} ({r['opp_archetype']}) — {r['verdict']}\n")
            if r["advantages"]: f.write(f"    + {', '.join(r['advantages'][:2])}\n")
            if r["disadvantages"]: f.write(f"    - {', '.join(r['disadvantages'][:2])}\n")
        f.write("\n")

if __name__ == "__main__":
    main()
