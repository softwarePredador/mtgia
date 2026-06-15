#!/usr/bin/env python3
"""Loss-Mode-Driven Swap Suggester.

Cruza dados de 3 fontes para sugerir swaps direcionados:
1. Loss tags do baseline (screw, flood, out-valued, etc.)
2. Card impact WDWR (cartas que correlacionam com vitoria/derrota)
3. Card pool disponivel (known_cards_generated.json)
"""

import argparse, json, os, sqlite3, sys
from collections import defaultdict

SCRIPT_DIR = os.environ.get(
    "BATTLE_SCRIPTS_DIR",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts",
)
sys.path.insert(0, SCRIPT_DIR)

def classify_replays_by_turn(replay_dir: str) -> dict[str, int]:
    """Classifica perdas por heuristica de turno (fallback sem loss tags no engine)."""
    tags = defaultdict(int)
    for f in sorted(os.listdir(replay_dir)):
        if not f.endswith(".jsonl"):
            continue
        try:
            spells_cast = 0
            max_turn = 0
            won = False
            for line in open(os.path.join(replay_dir, f)):
                line = line.strip()
                if not line:
                    continue
                try:
                    evt = json.loads(line)
                except json.JSONDecodeError:
                    continue
                t = evt.get("turn", 0)
                max_turn = max(max_turn, t)
                if evt.get("event") == "spell_cast":
                    spells_cast += 1
                if evt.get("event") == "game_ended":
                    if evt.get("result") == "win" or evt.get("won"):
                        won = True
            if not won:
                if max_turn <= 5 and spells_cast <= 3:
                    tags["screw"] += 1
                elif max_turn >= 8 and spells_cast <= 4:
                    tags["out-valued"] += 1
                else:
                    tags["combat-damage"] += 1
        except Exception:
            pass
    return dict(tags)


def suggest_swaps_by_loss_mode(
    loss_tags: dict[str, int],
    card_impact: dict[str, dict],
    known_cards_path: str | None = None,
    min_sample_size: int = 10,
) -> list[dict]:
    """Gera sugestoes de swap baseadas no modo de derrota dominante e WDWR."""

    suggestions = []

    # Mapeia loss tag -> categoria de carta que ajudaria
    LOSS_TO_CATEGORY = {
        "screw": "ramp",           # mana shortage -> precisa de mais ramp
        "flood": "draw",           # muita terra -> precisa de card draw/filter
        "out-valued": "draw",      # perdeu em valor -> mais card advantage
        "out-comboed": "protection", # morreu pra combo -> stax/counters
        "combat-damage": "removal",  # morreu por dano -> mais removal
        "bad-mulligan": "draw",      # mulligan ruim -> card selection
        "commander-removed": "protection", # commander morto -> protecao
    }

    # Indica cartas que RESOLVEM cada loss mode
    LOSS_TO_CARD_TYPE = {
        "screw": ["ramp", "ritual", "mana_rock", "land"],
        "flood": ["draw", "card_advantage", "wheel", "scry"],
        "out-valued": ["draw", "card_advantage", "engine", "recursion"],
        "out-comboed": ["protection", "stax", "counter", "removal"],
        "combat-damage": ["removal", "board_wipe", "protection"],
        "bad-mulligan": ["draw", "scry", "tutor"],
        "commander-removed": ["protection", "hexproof", "indestructible"],
    }

    total_losses = sum(loss_tags.values())
    if total_losses == 0:
        return suggestions

    # Ordena loss tags por frequencia
    sorted_tags = sorted(loss_tags.items(), key=lambda x: -x[1])
    dominant_tag = sorted_tags[0][0]
    dominant_pct = sorted_tags[0][1] / total_losses * 100

    # Sugestao principal baseada no modo de derrota dominante
    category = LOSS_TO_CATEGORY.get(dominant_tag, "draw")
    card_types = LOSS_TO_CARD_TYPE.get(dominant_tag, [])

    # Encontra cartas com alto WDWR na categoria alvo
    category_cards = []
    for card, stats in card_impact.items():
        if int(stats.get("sample_size") or stats.get("seen") or 0) < min_sample_size:
            continue
        cat = stats.get("category", "")
        # Match by card role or effect
        if any(t in cat.lower() for t in card_types):
            category_cards.append((card, stats.get("wdwr", 0), stats.get("seen", 0)))

    category_cards.sort(key=lambda x: -x[1])

    suggestions.append({
        "loss_mode": dominant_tag,
        "frequency": f"{sorted_tags[0][1]}/{total_losses} ({dominant_pct:.0f}%)",
        "recommended_category": category,
        "rationale": f"Deck perde {dominant_pct:.0f}% das partidas por {dominant_tag}. "
                     f"Adicionar {category} com alto WDWR.",
        "top_candidates": [
            {"card": c[0], "wdwr": c[1], "seen": c[2]}
            for c in category_cards[:5]
        ],
        "loss_breakdown": {
            tag: f"{count}/{total_losses} ({count/total_losses*100:.0f}%)"
            for tag, count in sorted_tags
        },
    })

    # Segunda sugestao: carta com WDWR mais baixo que deveria ser cortada
    worst_cards = sorted(card_impact.items(), key=lambda x: x[1].get("wdwr", 0))
    for card, stats in worst_cards[:3]:
        if int(stats.get("sample_size") or stats.get("seen") or 0) >= min_sample_size and stats.get("wdwr", 0) < 30:
            suggestions.append({
                "loss_mode": "cut_candidate",
                "card": card,
                "wdwr": stats["wdwr"],
                "seen": stats["seen"],
                "rationale": f"{card} tem WDWR={stats['wdwr']}% (visto {stats['seen']}x). "
                             f"Alto potencial de corte.",
            })

    return suggestions


def main():
    parser = argparse.ArgumentParser(description="Loss-Mode Swap Suggester")
    parser.add_argument("--loss-tags-json", help="JSON with loss tag counts")
    parser.add_argument("--impact-json", help="JSON with WDWR/PWR data")
    parser.add_argument("--replay-dir",
        default="/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_replays")
    parser.add_argument("--min-sample-size", type=int, default=10)
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    # 1. Carrega card impact (sempre necessario)
    card_impact = {}
    if args.impact_json and os.path.exists(args.impact_json):
        card_impact = json.load(open(args.impact_json))

    if not card_impact:
        print("Computing card impact from replays...")
        card_impact = compute_impact_from_replays(args.replay_dir)

    if not card_impact:
        print("No impact data found. Run generate_card_replays.py first.")
        return 1

    # 2. Carrega loss tags (opcional, usa heuristica fallback)
    loss_tags = {}
    if args.loss_tags_json and os.path.exists(args.loss_tags_json):
        loss_tags = json.load(open(args.loss_tags_json))

    if not loss_tags:
        loss_tags = classify_replays_by_turn(args.replay_dir)

    # 3. Gera sugestoes
    suggestions = suggest_swaps_by_loss_mode(
        loss_tags if loss_tags else {},
        card_impact,
        min_sample_size=args.min_sample_size,
    )

    if args.report:
        print(f"\n# Loss-Mode-Driven Swap Suggestions\n")
        for s in suggestions:
            if s.get("loss_mode") == "cut_candidate":
                print(f"## ✂️ Cut Candidate")
                print(f"- **{s['card']}**: WDWR={s['wdwr']}%, seen {s['seen']}x")
                print(f"- {s['rationale']}\n")
            else:
                print(f"## 🔴 Dominant Loss Mode: {s['loss_mode']} ({s['frequency']})")
                print(f"### Recommended: add {s['recommended_category']}")
                print(f"- {s['rationale']}")
                print(f"\n### Loss Breakdown")
                for tag, freq in s['loss_breakdown'].items():
                    pct_text = freq.split("(")[-1].split("%")[0]
                    try:
                        bar = "█" * max(1, int(float(pct_text) // 5))
                    except ValueError:
                        bar = ""
                    print(f"- {tag}: {freq} {bar}")
                print(f"\n### Top {s['recommended_category']} Candidates (by WDWR)")
                for c in s['top_candidates']:
                    print(f"- {c['card'][:40]:40s} WDWR={c['wdwr']}%")
                print()
    else:
        for s in suggestions:
            if s.get("loss_mode") == "cut_candidate":
                print(f"  CUT: {s['card'][:35]:35s} WDWR={s['wdwr']}%")
            else:
                print(f"\n  LOSS MODE: {s['loss_mode']} ({s['frequency']})")
                print(f"  → Add {s['recommended_category']}:")
                for c in s['top_candidates'][:3]:
                    print(f"    {c['card'][:35]:35s} WDWR={c['wdwr']}%")

    return 0


def compute_loss_tags_from_replays(replay_dir: str) -> dict[str, int]:
    """Extrai loss tags dos replays JSONL."""
    tags = defaultdict(int)
    for f in sorted(os.listdir(replay_dir)):
        if not f.endswith(".jsonl"):
            continue
        try:
            for line in open(os.path.join(replay_dir, f)):
                line = line.strip()
                if not line or '"game_ended"' not in line:
                    continue
                evt = json.loads(line)
                reason = str(evt.get("reason", ""))
                result = evt.get("result", "")
                if result != "win" and "tags=" in reason:
                    # Extract tags from reason: "life_zero|tags=screw+combat-damage"
                    tags_part = reason.split("tags=")[-1].split("|")[0]
                    for t in tags_part.split("+"):
                        tags[t.strip()] += 1
        except Exception:
            pass
    return dict(tags)


def compute_impact_from_replays(replay_dir: str) -> dict:
    """Computa WDWR a partir dos replays."""
    games = {}

    for f in sorted(os.listdir(replay_dir)):
        if not f.endswith(".jsonl"):
            continue
        gid = f.replace(".jsonl", "")
        games[gid] = {"cards_seen": set(), "cards_cast": set(), "won": False}

        try:
            for line in open(os.path.join(replay_dir, f)):
                line = line.strip()
                if not line:
                    continue
                try:
                    evt = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if evt.get("event") == "spell_cast" and evt.get("player") == "Lorehold":
                    cn = evt.get("card", "")
                    if cn:
                        games[gid]["cards_seen"].add(cn)

                if evt.get("event") == "game_ended":
                    if evt.get("result") == "win" or evt.get("won") or "elimination" in str(evt.get("reason", "")):
                        games[gid]["won"] = True
        except Exception:
            pass

    stats = defaultdict(lambda: {"seen": 0, "won_when_seen": 0})
    total_games = len(games)
    total_wins = sum(1 for game in games.values() if game["won"])
    for gid, g in games.items():
        won = g["won"]
        for c in g["cards_seen"]:
            stats[c]["seen"] += 1
            if won:
                stats[c]["won_when_seen"] += 1

    result = {}
    for c, s in stats.items():
        if s["seen"] < 3:
            continue
        not_seen = max(0, total_games - s["seen"])
        won_when_not_seen = max(0, total_wins - s["won_when_seen"])
        wdwr = round(s["won_when_seen"] / s["seen"] * 100, 1)
        wns_wr = round(won_when_not_seen / not_seen * 100, 1) if not_seen > 0 else None
        result[c] = {
            "wdwr": wdwr,
            "seen": s["seen"],
            "sample_size": s["seen"],
            "sample_quality": "low_sample" if s["seen"] < 10 else "usable",
            "won_when_seen": s["won_when_seen"],
            "not_seen": not_seen,
            "won_when_not_seen": won_when_not_seen,
            "wns_wr": wns_wr,
            "delta_vs_not_seen": round(wdwr - wns_wr, 1) if isinstance(wns_wr, (int, float)) else None,
        }
    return result


if __name__ == "__main__":
    sys.exit(main())
