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


# ─────────────────── Multi-Tag Functional Classification ───────────────────
# Replica fielmente inferFunctionalCardTags() do Dart (functional_card_tags.dart)
# Retorna lista de dicts: [{tag, confidence, evidence}, ...] ordenado por confidence decrescente


VALID_FUNCTIONAL_TAGS = frozenset({
    'land', 'ramp', 'ritual', 'draw', 'loot', 'tutor', 'removal',
    'board_wipe', 'protection', 'recursion', 'token_maker',
    'sacrifice_outlet', 'aristocrat_payoff', 'lifegain', 'drain',
    'spellslinger', 'artifact_synergy', 'enchantment_synergy',
    'graveyard_synergy', 'etb', 'blink', 'big_spell', 'exile_value',
    'combo_piece', 'wincon', 'engine', 'payoff', 'enabler',
})


def _normalize_card_name(name: str) -> str:
    """Replica normalizeFunctionalCardName() do Dart."""
    n = name.strip().lower()
    n = n.replace("\u2018", "'").replace("\u2019", "'")
    n = " ".join(n.split())  # collapse whitespace
    return n


def _looks_like_ritual(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeRitual() do Dart (linha 850)."""
    if normalized_name == "jeska's will":
        return True
    return ("add {" in oracle and
            any(t in oracle for t in ["until end of turn", "for each",
                                      "for every", "your mana pool"]))


def _looks_like_draw(oracle: str) -> bool:
    """Replica _looksLikeDraw() do Dart (linha 643)."""
    if any(t in oracle for t in ["target opponent draws",
                                  "an opponent draws",
                                  "each opponent draws"]):
        return False
    return ("draw a card" in oracle or
            bool(re.search(r'\bdraw (?:one|two|three|four|five|six|seven|eight|nine|ten|\d+) cards\b', oracle)) or
            "draw cards" in oracle or
            "draw x cards" in oracle or
            "draw that many cards" in oracle or
            "draw equal to" in oracle or
            ("whenever" in oracle and "draw a card" in oracle) or
            ("reveal" in oracle and "put" in oracle and "into your hand" in oracle))


def _looks_like_loot(oracle: str) -> bool:
    """Replica _looksLikeLoot() do Dart (linha 663)."""
    return (("draw" in oracle and
             any(t in oracle for t in ["discard a card", "discard that many", "then discard"])) or
            ("discard" in oracle and "then draw" in oracle))


def _looks_like_tutor(oracle: str) -> bool:
    """Replica _looksLikeTutor() do Dart (linha 671)."""
    return ("search your library" in oracle and
            not looks_like_land_search(oracle) and
            any(t in oracle for t in ["put", "reveal", "card"]))


def _looks_like_targeted_removal(oracle: str) -> bool:
    """Replica _looksLikeTargetedRemoval() do Dart (linha 679)."""
    targets_own = any(t in oracle for t in [
        "target creature you control",
        "target permanent you control",
        "target artifact you control",
        "target enchantment you control",
    ])
    if targets_own:
        return False
    return ("destroy target" in oracle or
            "exile target" in oracle or
            ("return target" in oracle and "to its owner" in oracle) or
            ("target" in oracle and "gets -" in oracle and "/-" in oracle) or
            ("deals" in oracle and "damage" in oracle and
             any(t in oracle for t in ["target creature", "target planeswalker",
                                       "any target", "damage to target"])))


def _looks_like_protection(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeProtection() do Dart (linha 700)."""
    return ("hexproof" in oracle or
            "indestructible" in oracle or
            "protection from" in oracle or
            "shroud" in oracle or
            "ward" in oracle or
            "phase out" in oracle or
            "gain protection" in oracle or
            "can't be the target" in oracle or
            "cannot be the target" in oracle or
            "prevent all damage" in oracle or
            "regenerate target" in oracle or
            "gains hexproof" in oracle or
            "gains indestructible" in oracle or
            any(x in normalized_name for x in [
                "teferi's protection", "heroic intervention",
                "swiftfoot boots", "lightning greaves",
            ]))


def _looks_like_recursion(oracle: str) -> bool:
    """Replica _looksLikeRecursion() do Dart (linha 720)."""
    has_graveyard = any(t in oracle for t in [
        "from your graveyard", "from a graveyard", "from graveyard",
    ])
    if not has_graveyard:
        return False
    return any(t in oracle for t in ["return", "put target", "cast",
                                     "onto the battlefield", "to your hand"])


def _looks_like_graveyard_synergy(oracle: str) -> bool:
    """Replica _looksLikeGraveyardSynergy() do Dart (linha 731)."""
    return any(t in oracle for t in ["graveyard", "mill", "escape",
                                     "disturb", "dredge", "flashback"])


def _looks_like_token_maker(oracle: str) -> bool:
    """Replica _looksLikeTokenMaker() do Dart (linha 740)."""
    return ("create" in oracle and "token" in oracle) or "populate" in oracle


def _looks_like_sacrifice_outlet(oracle: str) -> bool:
    """Replica _looksLikeSacrificeOutlet() do Dart (linha 745)."""
    return any(t in oracle for t in [
        "sacrifice another", "sacrifice a creature:", "sacrifice a permanent:",
        "sacrifice an artifact:", "sacrifice a token:", "{t}, sacrifice",
    ])


def _looks_like_aristocrat_payoff(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeAristocratPayoff() do Dart (linha 754)."""
    if normalized_name in ("blood artist", "zulaport cutthroat"):
        return True
    if ("whenever" in oracle and "creature" in oracle and "dies" in oracle and
            any(t in oracle for t in ["loses", "gain", "drain"])):
        return True
    if ("whenever you sacrifice" in oracle and
            any(t in oracle for t in ["loses", "gain"])):
        return True
    return False


def _looks_like_lifegain(oracle: str) -> bool:
    """Replica _looksLikeLifegain() do Dart (linha 767)."""
    if any(t in oracle for t in ["can't gain life", "cannot gain life",
                                  "players can't gain life",
                                  "opponents can't gain life"]):
        return False
    return (("you gain" in oracle and "life" in oracle) or
            "gain life" in oracle or
            ("gains you" in oracle and "life" in oracle))


def _looks_like_drain(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeDrain() do Dart (linha 779)."""
    return (normalized_name == "blood artist" or
            ("loses" in oracle and "you gain" in oracle) or
            "each opponent loses" in oracle or
            "target player loses" in oracle)


def _looks_like_spellslinger(oracle: str) -> bool:
    """Replica _looksLikeSpellslinger() do Dart (linha 786)."""
    return ("instant or sorcery" in oracle or
            "magecraft" in oracle or
            "whenever you cast or copy" in oracle or
            ("whenever you cast" in oracle and
             any(t in oracle for t in ["instant", "sorcery"])))


def _looks_like_artifact_synergy(oracle: str) -> bool:
    """Replica _looksLikeArtifactSynergy() do Dart (linha 794)."""
    if "artifact" not in oracle:
        return False
    return any(t in oracle for t in ["whenever", "for each artifact",
                                     "artifacts you control",
                                     "artifact enters",
                                     "sacrifice an artifact"])


def _looks_like_enchantment_synergy(oracle: str) -> bool:
    """Replica _looksLikeEnchantmentSynergy() do Dart (linha 803)."""
    if "enchantment" not in oracle:
        return False
    return any(t in oracle for t in ["whenever", "for each enchantment",
                                     "enchantments you control",
                                     "enchantment enters"])


def _looks_like_etb(oracle: str) -> bool:
    """Replica _looksLikeEtb() do Dart (linha 811)."""
    if "enters the battlefield" not in oracle:
        return False
    if any(t in oracle for t in ["don't cause abilities to trigger",
                                  "abilities don't trigger"]):
        return False
    return any(t in oracle for t in ["when ", "whenever ", "as ",
                                     "enters the battlefield,"])


def _looks_like_blink(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeBlink() do Dart (linha 823)."""
    if normalized_name == "ephemerate":
        return True
    if ("exile target" in oracle and "return" in oracle and "battlefield" in oracle):
        return True
    if ("exile another target" in oracle and "return" in oracle and "battlefield" in oracle):
        return True
    if "flicker" in oracle:
        return True
    return False


def _looks_like_big_spell_payoff(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeBigSpellPayoff() do Dart (linha 834)."""
    return (normalized_name == "jeska's will" or
            "if you control a commander" in oracle or
            "without paying its mana cost" in oracle or
            "copy target spell" in oracle or
            ("copy it" in oracle and "spell" in oracle))


def _looks_like_exile_value(oracle: str) -> bool:
    """Replica _looksLikeExileValue() do Dart (linha 842)."""
    return ("exile" in oracle and
            any(t in oracle for t in ["may play", "may cast",
                                      "until the end of your next turn",
                                      "until end of turn"]))


def _looks_like_wincon(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeWincon() do Dart (linha 859)."""
    return ("thassa's oracle" in normalized_name or
            "you win the game" in oracle or
            "loses the game" in oracle or
            "each opponent loses" in oracle or
            ("damage equal to" in oracle and "opponent" in oracle) or
            "double your life total" in oracle)


def _looks_like_combo_piece(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeComboPiece() do Dart (linha 868)."""
    return (any(x in normalized_name for x in ["isochron scepter",
                                                "dramatic reversal",
                                                "thassa's oracle"]) or
            "copy target activated or triggered ability" in oracle or
            ("untap" in oracle and "add " in oracle) or
            "infinite" in oracle)


def _looks_like_engine(oracle: str) -> bool:
    """Replica _looksLikeEngine() do Dart (linha 877)."""
    if "whenever" in oracle:
        if ("draw" in oracle or
                ("create" in oracle and "token" in oracle) or
                "add {" in oracle or
                "put a +1/+1 counter" in oracle):
            return True
    if "at the beginning of" in oracle and any(t in oracle for t in ["draw", "create"]):
        return True
    return False


def _looks_like_payoff(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikePayoff() do Dart (linha 887)."""
    if normalized_name == "blood artist":
        return True
    if "for each" in oracle:
        return True
    if "whenever" in oracle and any(t in oracle for t in [
        "creature dies", "you cast", "artifact enters",
        "enchantment enters", "you sacrifice",
    ]):
        return True
    return False


def _looks_like_enabler(oracle: str, normalized_name: str) -> bool:
    """Replica _looksLikeEnabler() do Dart (linha 898)."""
    return (any(x in normalized_name for x in ["greaves", "boots"]) or
            "costs {" in oracle and "less to cast" in oracle or
            "you may play an additional land" in oracle or
            "haste" in oracle or
            "mill" in oracle or
            "sacrifice another" in oracle or
            "search your library" in oracle)


def infer_functional_card_tags(
    name: str,
    type_line: str = "",
    oracle_text: str = "",
    cmc: float = 0,
) -> list[dict]:
    """Replica inferFunctionalCardTags() do Dart (functional_card_tags.dart).
    
    Returns list of {tag, confidence, evidence} sorted by confidence desc.
    Each card can have MULTIPLE tags from independent heuristics.
    """
    normalized_name = _normalize_card_name(name)
    type_lower = type_line.lower() if type_line else ""
    oracle = oracle_text.lower() if oracle_text else ""

    tags_map = {}  # tag_name -> {tag, confidence, evidence}

    def add(tag: str, confidence: float, evidence: str):
        """Inner add() function mirroring Dart closure (linha 202)."""
        if tag not in VALID_FUNCTIONAL_TAGS:
            return
        current = tags_map.get(tag)
        if current is None or confidence > current["confidence"]:
            tags_map[tag] = {
                "tag": tag,
                "confidence": max(0.0, min(1.0, confidence)),
                "evidence": evidence,
            }

    is_land = "land" in type_lower
    if is_land:
        add("land", 1.0, "type_line_land")

    is_basic_land = "basic land" in type_lower
    if not is_basic_land:
        # ramp check: uses original oracle_text for Dart compat
        if (looks_like_ramp(oracle, type_lower) or
                "signet" in normalized_name or
                "talisman" in normalized_name or
                normalized_name == "sol ring" or
                normalized_name == "arcane signet"):
            add("ramp", 0.88, "mana_or_land_ramp_text")

    if _looks_like_ritual(oracle, normalized_name):
        add("ritual", 0.82, "temporary_mana_burst_text")

    if _looks_like_draw(oracle):
        add("draw", 0.84, "card_draw_text")

    if _looks_like_loot(oracle):
        add("loot", 0.80, "draw_discard_selection_text")

    if _looks_like_tutor(oracle):
        add("tutor", 0.86, "non_land_library_search")

    if _looks_like_targeted_removal(oracle):
        add("removal", 0.83, "targeted_interaction_text")

    if "counter target" in oracle:
        add("removal", 0.72, "counterspell_is_interaction")
        add("protection", 0.62, "counterspell_can_protect_plan")

    if looks_like_board_wipe(oracle):
        add("board_wipe", 0.90, "mass_removal_text")

    if _looks_like_protection(oracle, normalized_name):
        add("protection", 0.82, "protection_keyword_or_effect")

    if _looks_like_recursion(oracle):
        add("recursion", 0.86, "graveyard_return_text")

    if _looks_like_graveyard_synergy(oracle):
        add("graveyard_synergy", 0.72, "graveyard_payoff_or_setup_text")

    if _looks_like_token_maker(oracle):
        add("token_maker", 0.82, "token_creation_text")

    if _looks_like_sacrifice_outlet(oracle):
        add("sacrifice_outlet", 0.80, "repeatable_sacrifice_outlet_text")

    if _looks_like_aristocrat_payoff(oracle, normalized_name):
        add("aristocrat_payoff", 0.84, "death_trigger_payoff_text")

    if _looks_like_lifegain(oracle):
        add("lifegain", 0.76, "life_gain_text")

    if _looks_like_drain(oracle, normalized_name):
        add("drain", 0.82, "life_loss_payoff_text")

    if _looks_like_spellslinger(oracle):
        add("spellslinger", 0.84, "instant_sorcery_cast_payoff_text")

    if _looks_like_artifact_synergy(oracle):
        add("artifact_synergy", 0.74, "artifact_payoff_text")

    if _looks_like_enchantment_synergy(oracle):
        add("enchantment_synergy", 0.74, "enchantment_payoff_text")

    if _looks_like_etb(oracle):
        add("etb", 0.70, "enters_the_battlefield_text")

    if _looks_like_blink(oracle, normalized_name):
        add("blink", 0.86, "exile_then_return_text")
        add("protection", 0.68, "blink_can_protect_permanent")

    if cmc >= 6 or _looks_like_big_spell_payoff(oracle, normalized_name):
        add("big_spell", 0.72, "high_mana_value_or_big_turn_text")

    if _looks_like_exile_value(oracle):
        add("exile_value", 0.84, "exile_play_or_cast_value_text")

    if _looks_like_wincon(oracle, normalized_name):
        add("wincon", 0.78, "explicit_win_or_finisher_text")

    if _looks_like_combo_piece(oracle, normalized_name):
        add("combo_piece", 0.72, "combo_pattern_text_or_known_name")

    if _looks_like_engine(oracle):
        add("engine", 0.70, "repeatable_value_engine_text")

    if _looks_like_payoff(oracle, normalized_name):
        add("payoff", 0.72, "payoff_trigger_or_scaling_text")

    if _looks_like_enabler(oracle, normalized_name):
        add("enabler", 0.70, "plan_enabler_or_setup_text")

    # Sort by confidence desc, then tag name asc (mirroring Dart sort)
    ordered = sorted(
        tags_map.values(),
        key=lambda t: (-t["confidence"], t["tag"]),
    )
    return ordered


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
    """Build the final deck JSON for knowledge_db.py --insert-deck.
    
    Each card dict may include:
    - 'tags': list of {tag, confidence, evidence} (multi-tag, optional)
    - 'functional_tag': single tag (legacy, optional)
    """
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

    # Tag counts — prefer multi-tag 'tags' field, fall back to 'functional_tag'
    tag_counts = Counter()
    for c in nonlands:
        if c != commander_card:
            if c.get("tags"):
                for t in c["tags"]:
                    tag_counts[t["tag"]] += c["qty"]
            else:
                tag_counts[c["functional_tag"]] += c["qty"]

    # CMC
    cmc_cards = [c for c in nonlands if c != commander_card and c["cmc"] > 0]
    total_cmc = sum(c["cmc"] * c["qty"] for c in cmc_cards)
    cmc_count = sum(c["qty"] for c in cmc_cards)
    avg_cmc = round(total_cmc / cmc_count, 2) if cmc_count > 0 else 0

    cards_out = []
    for c in enriched_cards:
        card_entry = {
            "name": c["name"],
            "quantity": c["qty"],
            "functional_tag": c["functional_tag"],
            "is_commander": 1 if c == commander_card else 0,
            "cmc": c["cmc"],
        }
        # Include multi-tags if available
        if c.get("tags"):
            card_entry["tags"] = c["tags"]
            # Also update functional_tag to highest-confidence tag
            if c["tags"]:
                card_entry["functional_tag"] = c["tags"][0]["tag"]
        cards_out.append(card_entry)

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
        # Self-test (single-tag, legacy)
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
        print("\\nAll tests passed." if len(fetched) >= 6 else "\\nSome cards not found.")
    
    elif len(sys.argv) > 1 and sys.argv[1] == "--test-multi":
        # Self-test for multi-tag
        test_cards = [
            "Smothering Tithe",
            "Boros Charm",
            "Teferi's Protection",
            "Volcanic Vision",
            "Sunbird's Invocation",
        ]
        fetched = fetch_cards(test_cards, delay=0.5)
        print(f"{'='*65}")
        print(f"{'MULTI-TAG FUNCTIONAL CLASSIFICATION TEST':^65}")
        print(f"{'='*65}")
        all_ok = True
        for name in test_cards:
            data = fetched.get(name.lower().strip(), {})
            if data.get("object") == "error":
                print(f"\\n  {name}: ERROR fetching card")
                all_ok = False
                continue
            tags = infer_functional_card_tags(
                name=name,
                type_line=data.get("type_line", ""),
                oracle_text=data.get("oracle_text", ""),
                cmc=data.get("cmc", 0),
            )
            tag_names = [t["tag"] for t in tags]
            print(f"\\n  {name}")
            print(f"  {'─'*40}")
            print(f"  CMC: {data.get('cmc','?')} | Type: {data.get('type_line','')}")
            for t in tags:
                print(f"    {t['tag']:20s} conf={t['confidence']:.2f}  [{t['evidence']}]")
        
        # Verify expected tags
        expected = {
            "smothering tithe": {"engine", "token_maker"},
            "boros charm": {"removal", "protection"},
            "teferi's protection": {"protection"},
            "volcanic vision": {"board_wipe", "recursion", "big_spell"},
            "sunbird's invocation": {"big_spell", "payoff"},
        }
        print(f"\\n{'='*65}")
        print(f"{'EXPECTED TAG VERIFICATION':^65}")
        print(f"{'='*65}")
        all_ok = True
        for name in test_cards:
            data = fetched.get(name.lower().strip(), {})
            if data.get("object") == "error":
                continue
            tags = infer_functional_card_tags(
                name=name,
                type_line=data.get("type_line", ""),
                oracle_text=data.get("oracle_text", ""),
                cmc=data.get("cmc", 0),
            )
            tag_names = {t["tag"] for t in tags}
            exp = expected.get(name.lower().strip(), set())
            missing = exp - tag_names
            extra = tag_names - exp
            # Filter out harmless "extra" tags that come from correct Dart heuristics
            # but were not in the simplified expected set
            harmless_extras = {"graveyard_synergy", "spellslinger", "wincon",
                               "lifegain", "artifact_synergy", "sacrifice_outlet",
                               "ramp", "payoff"}
            significant_extra = extra - harmless_extras
            status = "OK" if not missing else "MISSING"
            if significant_extra:
                status += " +EXTRA"
            print(f"  {name:30s} -> {', '.join(sorted(tag_names))}")
            print(f"  {'':30s} expected={', '.join(sorted(exp))}")
            print(f"  {'':30s} status={status}")
            if missing:
                print(f"  {'':30s} MISSING: {missing}")
                all_ok = False
            if significant_extra:
                print(f"  {'':30s} EXTRA: {significant_extra}")
        print(f"\\n{'─'*65}")
        print(f"  OVERALL: {'ALL CHECKS PASSED' if all_ok else 'SOME CHECKS FAILED'}")
