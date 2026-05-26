#!/usr/bin/env python3
"""
scryfall_classifier.py — Classificador funcional de cartas MTG baseado em oracle text.

Usa a Scryfall API para buscar dados de cartas e replica a logica deterministica
do ManaLoom (server/lib/ai/optimization_functional_roles.dart) para classificar
cada carta em tags funcionais.

Uso:
    from scryfall_classifier import classify_deck, fetch_cards_parallel
    deck = parse_decklist(texto_da_lista)
    cards = fetch_cards_parallel(deck)
    for card in cards:
        tag = classify_card(card)
        print(f"{card['name']} -> {tag}")
"""

import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Optional

# ─────────────────── Scryfall API ───────────────────

SCRYFALL_BASE = "https://api.scryfall.com"


def _fetch_single(name: str, retries: int = 3) -> dict[str, Any]:
    """Fetch a single card from Scryfall by exact name via curl, with retry."""
    import subprocess
    encoded = urllib.parse.quote(name)
    url = f"{SCRYFALL_BASE}/cards/named?exact={encoded}"
    for attempt in range(retries):
        try:
            r = subprocess.run(
                ["curl", "-sL", "--max-time", "10", url],
                capture_output=True, text=True, timeout=15
            )
            if r.returncode != 0:
                raise RuntimeError(f"curl returned {r.returncode}")
            data = json.loads(r.stdout)
            if data.get("object") == "card":
                return data
            # Try fuzzy
            fuzzy_url = f"{SCRYFALL_BASE}/cards/named?fuzzy={encoded}"
            r2 = subprocess.run(
                ["curl", "-sL", "--max-time", "10", fuzzy_url],
                capture_output=True, text=True, timeout=15
            )
            if r2.returncode == 0:
                data2 = json.loads(r2.stdout)
                if data2.get("object") == "card":
                    return data2
            return {"name": name, "object": "error", "status": "not_found"}
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(1)
                continue
            return {"name": name, "object": "error", "status": str(e)}
    return {"name": name, "object": "error", "status": "timeout"}


def fetch_cards(card_names: list[str], delay: float = 1.0) -> dict[str, dict]:
    """Fetch cards from Scryfall sequentially with delays to avoid rate limits.
    Returns dict[lowercase_name, card_data] with multiple alias keys.
    """
    results = {}
    seen = set()
    unique_names = []
    for n in card_names:
        norm = n.strip().lower()
        if norm not in seen:
            seen.add(norm)
            unique_names.append(n.strip())

    total = len(unique_names)
    for i, name in enumerate(unique_names):
        data = _fetch_single(name)
        if data.get("object") == "card":
            canonical = data["name"].lower().strip()
            results[canonical] = data
            results[name.lower().strip()] = data
            clean = canonical.replace("'", "").replace("\u2019", "").replace(",", "")
            clean = clean.replace("ó", "o").replace("é", "e").replace("í", "i")
            results[clean] = data
        else:
            results[name.lower().strip()] = data

        if (i + 1) % 10 == 0:
            print(f"  Fetch progress: {i + 1}/{total} cards", flush=True)

        if i < len(unique_names) - 1:
            time.sleep(delay)

    return results


# ─────────────────── Oracle Text Classification ───────────────────
# Replica fielmente a logica de classifyOptimizationFunctionalRole() em Dart


def looks_like_board_wipe(oracle: str) -> bool:
    """Replica looksLikeOptimizationBoardWipeText() do Dart."""
    own_board = "all creatures you control" in oracle or "each creature you control" in oracle
    combat_damage = "assigns combat damage" in oracle
    if own_board or combat_damage:
        return False
    return any([
        "destroy all" in oracle,
        "exile all" in oracle,
        "all creatures get -" in oracle,
        "all colored permanents" in oracle,
        "each player sacrifices all" in oracle,
        "each opponent sacrifices all" in oracle,
        "damage to each creature" in oracle,
        ("deals" in oracle and "damage" in oracle and "to each creature" in oracle),
    ])


def looks_like_land_search(oracle: str) -> bool:
    """Replica looksLikeOptimizationLandSearchText() do Dart."""
    return any(t in oracle for t in [
        "land card", "basic land", "forest card", "plains card",
        "island card", "swamp card", "mountain card",
    ])


def looks_like_ramp(oracle: str, type_line: str) -> bool:
    """Replica looksLikeOptimizationRampText() do Dart."""
    if "add {" in oracle or "mana of any" in oracle:
        return True
    if "search your library" in oracle and looks_like_land_search(oracle):
        return True
    if any(t in oracle for t in [
        "additional land this turn",
        "additional land on each of your turns",
        "put a land card from your hand onto the battlefield",
    ]):
        return True
    if "put up to" in oracle and "land cards" in oracle:
        return True
    if re.search(r"create \w+ treasure token", oracle):
        return True
    # Extra: artifact that produces mana
    if "artifact" in type_line and "add {" in oracle:
        return True
    return False


def classify_card(card_data: dict) -> str:
    """Replica classifyOptimizationFunctionalRole() do Dart.
    Returns one of: land, draw, removal, wipe, ramp, tutor, protection,
    creature, artifact, enchantment, planeswalker, utility.
    """
    name = card_data.get("name", "?")
    type_line = (card_data.get("type_line") or "").lower()
    oracle = (card_data.get("oracle_text") or "").lower()
    cmc = card_data.get("cmc", 0)

    # Land check — also catch basic lands by name heuristic
    if "land" in type_line:
        return "land"
    name_lower = name.lower()
    # Basic lands that might not have correct type_line in partial data
    basic_lands = {"mountain", "plains", "island", "swamp", "forest", "wastes"}
    if name_lower.rstrip("0123456789 ").rstrip() in basic_lands:
        return "land"
    if any(name_lower.startswith(b) for b in basic_lands):
        return "land"

    # draw
    if "draw" in oracle or "look at the top" in oracle:
        return "draw"
    if "scry" in oracle and "draw" in oracle:
        return "draw"

    # removal (spot)
    if any(t in oracle for t in [
        "destroy target", "exile target", "counter target",
    ]):
        return "removal"
    if "return target" in oracle and "to its owner" in oracle:
        return "removal"
    if "deals" in oracle and "damage" in oracle and any(t in oracle for t in [
        "target creature", "target planeswalker", "any target",
        "target attacking", "target blocking",
    ]):
        return "removal"

    # board wipe
    if looks_like_board_wipe(oracle):
        return "wipe"

    # ramp
    if looks_like_ramp(oracle, type_line):
        return "ramp"

    # tutor
    if "search your library" in oracle and "land" not in oracle:
        return "tutor"

    # protection
    if any(t in oracle for t in ["hexproof", "indestructible", "shroud", "ward"]):
        return "protection"

    # type-based fallback
    if "creature" in type_line:
        return "creature"
    if "artifact" in type_line:
        return "artifact"
    if "enchantment" in type_line:
        return "enchantment"
    if "planeswalker" in type_line:
        return "planeswalker"

    return "utility"


# ─────────────────── Deck Parsing ───────────────────


def parse_decklist(text: str) -> list[dict]:
    """Parse a text decklist into list of {name, qty, set_code, tag_comment}.
    Supports formats:
        Nx Card Name (set) [Tag] *F*
        Nx Card Name
    """
    cards = []
    for line in text.strip().split("\n"):
        line = line.strip()
        if not line:
            continue

        # extract quantity
        parts = line.split("x", 1)
        try:
            qty = int(parts[0].strip())
        except ValueError:
            continue
        rest = parts[1].strip() if len(parts) > 1 else ""

        # extract [Tag]
        tag = ""
        m = re.search(r'\[([^\]]*)\]', rest)
        if m:
            tag = m.group(1).strip()
            rest = rest.replace(m.group(0), "")

        # remove *F*
        rest = re.sub(r'\*F\*', "", rest).strip()

        # extract (set)
        set_code = ""
        set_match = re.search(r'\(([^)]*)\)', rest)
        if set_match:
            set_code = set_match.group(1).strip()
            rest = rest.replace(set_match.group(0), "")

        # Remove trailing collector number digits (for basic lands like "Mountain 481")
        rest = re.sub(r'\s+\d+\s*$', '', rest).strip()

        name = rest.strip()
        if name:
            cards.append({
                "name": name,
                "qty": qty,
                "set_code": set_code,
                "tag_comment": tag,
            })
    return cards


def classify_deck(cards_list: list[dict]) -> list[dict]:
    """Given a parsed decklist, fetch each card from Scryfall and classify it.
    Returns list of {name, qty, set_code, tag_comment, functional_tag, cmc, type_line, colors}
    """
    names = [c["name"] for c in cards_list]
    fetched = fetch_cards(names)

    enriched = []
    for c in cards_list:
        name = c["name"]
        norm = name.strip().lower()
        card_data = fetched.get(norm, {})
        tag = c["tag_comment"]

        # Check if Scryfall returned error
        if card_data.get("object") == "error":
            functional_tag = "unknown"
            cmc = 0
            type_line = ""
        else:
            functional_tag = classify_card(card_data)
            cmc = card_data.get("cmc", 0)
            type_line = card_data.get("type_line", "")

        # Honor user-provided tags when they are clear functional roles
        tag_lower = tag.lower()
        user_tag_map = {
            "ramp": "ramp",
            "draw": "draw",
            "tutor": "tutor",
            "interaction": "removal",
            "removal": "removal",
            "protection": "protection",
            "pay-offs": "wincon",
            "payoff": "wincon",
            "wincon": "wincon",
            "top deck manipulation": "engine",
            "topdeck": "engine",
        }
        override = user_tag_map.get(tag_lower)
        if override:
            functional_tag = override

        enriched.append({
            "name": name,
            "qty": c["qty"],
            "set_code": c["set_code"],
            "tag_comment": tag,
            "functional_tag": functional_tag,
            "cmc": cmc,
            "type_line": type_line,
        })
    return enriched


def build_deck_json(
    commander_name: str,
    enriched_cards: list[dict],
    archetype: str = "",
    bracket: int = 3,
    deck_name: str = "",
    source_name: str = "User provided decklist",
) -> dict:
    """Build the final deck JSON for knowledge_db.py --insert-deck."""
    from datetime import date

    # Separate commander, lands, nonlands
    commander_card = None
    lands = []
    nonlands = []
    for c in enriched_cards:
        nl = c["name"].lower()
        if commander_name.lower() in nl and ("commander" in c.get("tag_comment", "").lower() or "commander" in c["name"].lower()):
            commander_card = c
            nonlands.append(c)
        elif c["functional_tag"] == "land":
            lands.append(c)
        else:
            nonlands.append(c)

    if commander_card and commander_card not in nonlands:
        nonlands.append(commander_card)

    total_lands = sum(c["qty"] for c in lands)
    total_cards = sum(c["qty"] for c in enriched_cards)

    # Tag counts
    tag_counts = Counter()
    for c in nonlands:
        if c != commander_card:
            tag_counts[c["functional_tag"]] += c["qty"]

    # CMC
    cmc_cards = [c for c in nonlands if c != commander_card and c["cmc"] > 0]
    total_cmc = sum(c["cmc"] * c["qty"] for c in cmc_cards)
    cmc_count = sum(c["qty"] for c in cmc_cards)
    avg_cmc = round(total_cmc / cmc_count, 2) if cmc_count > 0 else 0

    cards_out = []
    for c in enriched_cards:
        cards_out.append({
            "name": c["name"],
            "quantity": c["qty"],
            "functional_tag": c["functional_tag"],
            "is_commander": 1 if c == commander_card else 0,
            "cmc": c["cmc"],
        })

    return {
        "commander": commander_name,
        "archetype": archetype,
        "color_identity": "RW",  # TODO: infer from Scryfall data
        "bracket": bracket,
        "source_name": source_name,
        "source_url": "",
        "source_type": "user_decklist",
        "deck_name": deck_name or f"{commander_name} Deck",
        "player_name": "",
        "placement": "",
        "tournament_date": "",
        "total_lands": total_lands,
        "avg_cmc": avg_cmc,
        "ramp_count": tag_counts.get("ramp", 0),
        "draw_count": tag_counts.get("draw", 0),
        "removal_count": tag_counts.get("removal", 0),
        "tutor_count": tag_counts.get("tutor", 0),
        "board_wipe_count": tag_counts.get("wipe", 0),
        "protection_count": tag_counts.get("protection", 0),
        "wincon_count": tag_counts.get("wincon", 0),
        "engine_count": tag_counts.get("engine", 0),
        "analysis_md_path": f"decks/{commander_name.lower().replace(' ', '-').replace(',', '')}/{date.today().isoformat()}-user-decklist.md",
        "cards": cards_out,
        "insights": [],
        "discrepancies": [],
    }


# ─────────────────── Main (CLI) ───────────────────

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        # Self-test
        test_cards = [
            "Sol Ring", "Swords to Plowshares", "Wrath of God",
            "Demonic Tutor", "Arcane Signet", "Rhystic Study",
            "Teferi's Protection", "Cultivate",
        ]
        fetched = fetch_cards(test_cards)
        for name in test_cards:
            data = fetched.get(name.lower().strip(), {})
            tag = classify_card(data)
            print(f"{name:35s} -> {tag:15s} (cmc={data.get('cmc','?')})")
        print("\nAll tests passed." if len(fetched) >= 6 else "\nSome cards not found.")
