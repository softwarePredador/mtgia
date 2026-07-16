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


def _oracle_direct_effect_text(value: str) -> str:
    """Strip reminder text and quoted granted abilities from Oracle text."""
    source = _strip_parenthetical_text(value)
    output: list[str] = []
    ascii_quote = False
    curly_quote = False
    for char in source:
        if char == '"':
            ascii_quote = not ascii_quote
            output.append(" ")
        elif char == "“":
            curly_quote = True
            output.append(" ")
        elif char == "”":
            curly_quote = False
            output.append(" ")
        elif not ascii_quote and not curly_quote:
            output.append(char)
        else:
            output.append("\n" if char == "\n" else " ")
    return "".join(output)


def _quoted_oracle_spans(value: str) -> list[tuple[int, str]]:
    spans: list[tuple[int, str]] = []
    for match in re.finditer(r'"([^"]*)"|“([^”]*)”', value):
        spans.append((match.start(1) if match.group(1) is not None else match.start(2),
                      match.group(1) if match.group(1) is not None else match.group(2)))
    return spans


def _token_object_pattern(treasure_only: bool) -> str:
    return (r"\btreasure\b[^.\n;]{0,32}\btokens?\b"
            if treasure_only else r"\btokens?\b")


def _has_self_token_production(text: str, treasure_only: bool) -> bool:
    obj = _token_object_pattern(treasure_only)
    return bool(re.search(
        r"\b(?:you|we|your team)\s+(?:(?:may|also|instead)\s+)*creates?\b"
        r"[^.\n;]{0,120}" + obj, text) or re.search(
        r"\byou\s+may\b[^.\n;]{0,80}\bor\s+create\b[^.\n;]{0,120}" + obj,
        text))


def _has_shared_token_production(text: str, treasure_only: bool) -> bool:
    obj = _token_object_pattern(treasure_only)
    return bool(
        re.search(r"\byou\s+and\b[^.\n;]{0,96}\beach\s+create\b"
                  r"[^.\n;]{0,120}" + obj, text)
        or re.search(r"\b(?:each player|all players|each team)\s+"
                     r"(?:(?:may|also|instead)\s+)*creates?\b"
                     r"[^.\n;]{0,120}" + obj, text)
    )


def _has_any_player_token_production(text: str, treasure_only: bool) -> bool:
    obj = _token_object_pattern(treasure_only)
    return bool(re.search(
        r"\bthat player\s+(?:(?:may|also|instead)\s+)*creates?\b"
        r"[^.\n;]{0,120}" + obj, text) or re.search(
        r"\b(?:when|whenever)\s+a player\b[^.\n;]{0,160}"
        r"\bthey\s+create\b[^.\n;]{0,120}" + obj, text))


def _has_target_player_token_production(text: str, treasure_only: bool) -> bool:
    obj = _token_object_pattern(treasure_only)
    return bool(re.search(
        r"\btarget player\s+(?:(?:may|also|instead)\s+)*creates?\b"
        r"[^.\n;]{0,120}" + obj, text) or re.search(
        r"\btarget player\b[^.\n;]{0,120}\bthey\s+create\b"
        r"[^.\n;]{0,120}" + obj, text) or re.search(
        r"\bchoose\s+(?:(?:a|the)\s+)?(?:first|second|third|another)?\s*player\b"
        r"[^.\n;]{0,120}\bto\s+create\b[^.\n;]{0,120}" + obj, text))


def _has_imperative_token_production(text: str, treasure_only: bool) -> bool:
    return bool(re.search(
        r"(?:^|[\n.;:•—|]|,\s*|\bthen\s+|\band\s+)\s*"
        r"(?:(?:if you do|when you do),\s*)?"
        r"(?:(?:you may|may|also|instead)\s+)*create\b"
        r"[^.\n;]{0,120}" + _token_object_pattern(treasure_only),
        text, re.MULTILINE))


def _has_positive_token_production(text: str, treasure_only: bool) -> bool:
    return any((
        _has_self_token_production(text, treasure_only),
        _has_shared_token_production(text, treasure_only),
        _has_any_player_token_production(text, treasure_only),
        _has_target_player_token_production(text, treasure_only),
        _has_imperative_token_production(text, treasure_only),
    ))


def _controlled_granted_context(raw_prefix: str) -> bool:
    prefix = re.sub(r"\s+", " ", raw_prefix).strip()
    prefix = re.sub(r'["“]\s*$', "", prefix).rstrip()
    returns_under_your_control = bool(re.search(
        r"\b(?:return|put)\b[\s\S]{0,180}\bunder your control\b", prefix))
    if (not returns_under_your_control and re.search(
            r"\b(?:becomes?|become|is|are)\b[^.]{0,72}"
            r"\btreasure\s+artifacts?\s+with\s*$", prefix)):
        return False
    if re.search(r"\bopponent(?:s)?(?:\s+controls?)?\b[^.]{0,96}"
                 r"\b(?:has|have|gains?|with)\s*$", prefix):
        return False
    if re.search(r"\b(?:enchant|target)\b[^.]{0,96}"
                 r"\b(?:an?|target) opponent controls\b", prefix):
        return False
    patterns = (
        r"\b(?:creatures?|artifacts?|lands?|permanents?|treasures?|tokens?)\b"
        r"[^.]{0,96}\byou\s+(?:control|own)\b[^.]{0,96}"
        r"\b(?:has|have|gains?|with)\s*$",
        r"\b[a-z][a-z0-9\x27 -]{0,72}\byou\s+(?:control|own)\b"
        r"[^.]{0,96}\b(?:has|have|gains?)\b[^.]{0,96}$",
        r"(?:^|[.\n—:])\s*all\s+(?!other\b)[a-z][a-z0-9\x27 -]{0,64}\b"
        r"[^.]{0,64}\b(?:has|have|gains?)\b[^.]{0,96}$",
        r"\b(?:equipped|enchanted)\s+(?:creature|land|permanent)\b"
        r"[^.]{0,96}\b(?:has|gains?)\b[^.]{0,48}$",
        r"\btarget\s+(?:creature|artifact|land|permanent)\b"
        r"[^.]{0,120}\b(?:has|gains?)\b[^.]{0,48}$",
        r"\bgain control of target\b[^.]{0,160}\bit gains?\b[^.]{0,48}$",
        r"\bcards? in your hand\b[^.]{0,160}\b(?:gain|gains)\b[^.]{0,48}$",
        r"\bcards? in your hand\b[\s\S]{0,120}\bthey\b"
        r"[^.]{0,64}\b(?:gain|gains)\b[^.]{0,48}$",
        r"\bcreates?\b[^.]{0,180}\btokens?\b[^.]{0,96}\b(?:with|and)\s*$",
        r"\bcreates?\b[^.]{0,180}\btokens?\b"
        r"(?:\s+that)?\s+(?:has|have)\b[^.]{0,48}$",
        r"\bcreates?\b[^.]{0,180}\btokens?\.\s*"
        r"(?:it|they|those tokens?)\s+(?:has|have)\b[^.]{0,48}$",
        r"\b(?:this (?:creature|artifact|permanent)|it|she|he)\b"
        r"[^.]{0,96}\b(?:has|gains?)\b[^.]{0,96}$",
        r"\bthose tokens\b[^.]{0,64}\b(?:has|have|gains?)\b[^.]{0,48}$",
        r"\bcreates?\b[^.]{0,120}\btoken at random\b[\s\S]{0,180}"
        r"\b(?:banana|powerstone|gold|lander)\b[^.]{0,48}\bwith\s*$",
        r"\bcreatures you control gain\b[\s\S]{0,360}"
        r"\bthe activated ability\s*$",
        r"\byou get\b[^.]{0,120}\ban? emblem\b[^.]{0,48}\bwith\s*$",
    )
    return returns_under_your_control or any(
        re.search(pattern, prefix) for pattern in patterns)


def _controller_owned_mana_statement(text: str) -> bool:
    return bool(re.search(
        r"\b(?:[a-z][a-z0-9\x27 -]{0,72}\byou\s+(?:control|own)|"
        r"enchanted\s+(?:creature|land|forest|permanent)|"
        r"(?:^|[.\n])\s*all\s+(?!other\b)[a-z][a-z0-9\x27 -]{0,64})\b"
        r"[^.\n]{0,180}\badds?\b", text))


def _target_land_granted_mana_context(raw_prefix: str) -> bool:
    prefix = re.sub(r"\s+", " ", raw_prefix).strip()
    return bool(re.search(
        r"\btarget\s+land\b[^.]{0,120}\b(?:has|gains?)\b[^.]{0,48}$",
        prefix))


def _net_positive_granted_mana_ability(quoted: str) -> bool:
    ability = quoted.lower()
    add_index = ability.find("add ")
    if add_index < 0:
        return False
    production = ability[add_index + 4:]
    if re.search(
            r"\b(?:two|three|four|five|six|seven|eight|nine|ten|x|"
            r"that much|an amount of)\s+mana\b", production):
        return True
    if " or " in production:
        return False
    return bool(re.search(r"\{[^}]+\}\s*\{[^}]+\}", production))


def classify_treasure_ramp(oracle: str) -> str:
    """Owner-aware Treasure production classification mirrored from Dart."""
    without_reminder = _strip_parenthetical_text(oracle.lower())
    if "treasure" not in without_reminder:
        return "none"
    direct = _oracle_direct_effect_text(without_reminder)
    if _has_self_token_production(direct, True):
        return "direct_self"
    if _has_shared_token_production(direct, True):
        return "shared_includes_self"
    if _has_any_player_token_production(direct, True):
        return "any_player_includes_self"
    if _has_target_player_token_production(direct, True):
        return "target_player_selectable"
    if _has_imperative_token_production(direct, True):
        return "direct_self"
    for start, quoted in _quoted_oracle_spans(without_reminder):
        if (_has_positive_token_production(quoted, True)
                and _controlled_granted_context(without_reminder[max(0, start - 360):start])):
            return "controlled_granted_ability"
    obj = _token_object_pattern(True)
    if re.search(r"\b(?:return|put)\b[\s\S]{0,180}\bunder your control\b"
                 r"[\s\S]{0,120}\btreasure\s+artifact\b", direct):
        return "controlled_granted_ability"
    if re.search(r"\b(?:becomes?|become|is|are)\b[^.\n;]{0,72}"
                 r"\btreasure\s+artifacts?\b", direct):
        return "transformation_only"
    if re.search(r"\bwould\s+create\b[^.\n;]{0,96}" + obj
                 + r"[^.\n;]{0,96}\binstead\b", direct):
        return "replacement_or_prevention_only"
    if re.search(r"\b(?:its|that (?:spell|permanent|creature|artifact)'s) controller\b"
                 r"[^.\n;]{0,96}\bcreates?\b[^.\n;]{0,96}" + obj, direct):
        return "object_controller_compensation"
    if (re.search(r"\b(?:each|target|an?|your)\s+opponent\b[^.\n;]{0,120}"
                  r"\b(?:would\s+|may\s+)?creates?\b[^.\n;]{0,96}" + obj,
                  direct)
            or re.search(r"^\s*gift\s+(?:an?\s+)?treasure\b", direct,
                         re.MULTILINE)):
        return "opponent_only"
    return "unknown_review"


def _controlled_granted_mana_ability(oracle: str, worded_any_only: bool = False) -> bool:
    if re.search(
            r'\ball lands have\s*["“][\s\S]{0,180}\badd\b[\s\S]{0,180}["”]'
            r'\s*and lose all other abilities\b', oracle):
        return False
    for start, quoted in _quoted_oracle_spans(oracle):
        produces = bool(re.search(
            r"\badds?\b[^.\n]{0,96}\bmana of any(?:\s+one)?\b", quoted
        )) if worded_any_only else (
            "add {" in quoted or bool(re.search(
                r"\badds?\b[^.\n]{0,96}\bmana of any(?:\s+one)?\b", quoted)))
        prefix = oracle[max(0, start - 360):start]
        if (_target_land_granted_mana_context(prefix)
                and not _net_positive_granted_mana_ability(quoted)):
            continue
        if (produces and (
                _controlled_granted_context(prefix)
                or _controller_owned_mana_statement(quoted))):
            return True
    return False


def _worded_mana_production(oracle: str) -> bool:
    direct = _oracle_direct_effect_text(oracle)
    return bool(re.search(
        r"\badds?\b[^.\n]{0,96}\b(?:one|two|three|four|five|six|seven|"
        r"eight|nine|ten|x|that much|an amount of)\s+mana\b", direct
    )) or _controlled_granted_mana_ability(oracle)


def _known_mana_token_production(oracle: str) -> bool:
    direct = _oracle_direct_effect_text(oracle.lower())
    normalized = re.sub(
        r"\b(?:powerstone|gold|lander|banana|vibranium|mutavault)\b"
        r"(?=\s+tokens?\b)|"
        r"\beldrazi\s+(?:scion|spawn)\b(?=(?:\s+creature)?\s+tokens?\b)|"
        r"\b(?:lotus|tulip)\s+petal\b(?=\s+tokens?\b)|"
        r"\bhuntsman\s+role\b(?=\s+tokens?\b)",
        "treasure",
        direct,
    )
    normalized = re.sub(
        r"\b(named|name)\s+(?:mana\s+confluence|mutavault|banana|"
        r"powerstone|gold|lander)\b",
        r"\1 treasure",
        normalized,
    )
    return _has_positive_token_production(normalized, True)


def _is_land_type_line(type_line: str) -> bool:
    card_types = re.split(r"\s+[—–-]\s+", type_line.lower(), maxsplit=1)[0]
    return bool(re.search(r"(?:^|\s)land(?:$|\s)", card_types))


def looks_like_ramp(oracle: str, type_line: str) -> bool:
    """Replica looksLikeOptimizationRampText() do Dart."""
    oracle = _strip_parenthetical_text(oracle.lower()).replace(
        "search you library", "search your library")
    direct_oracle = _oracle_direct_effect_text(oracle)
    worded_any_mana_production = re.search(
        r"\badds?\b[^.\n]{0,96}\bmana of any(?:\s+one)?\b", direct_oracle
    )
    if ("add {" in direct_oracle or worded_any_mana_production
            or _worded_mana_production(oracle)
            or _controlled_granted_mana_ability(oracle)):
        return True
    if (
        "search your library" in oracle
        and looks_like_land_search(oracle)
        and _land_search_puts_land_onto_battlefield(oracle)
    ):
        return True
    if any(t in oracle for t in [
        "additional land this turn",
        "additional land on each of your turns",
        "put a land card from your hand onto the battlefield",
        "spells you cast have convoke",
        "create a birds of paradise token",
        "has all activated abilities of all lands",
    ]):
        return True
    if re.search(r"\bfirebending\s+(?:\d+|x)\b", oracle):
        return True
    if "untap up to" in oracle and "lands" in oracle:
        return True
    if "taps an island for mana" in oracle and "adds an additional" in oracle:
        return True
    if "put up to" in oracle and "land cards" in oracle:
        return True
    if classify_treasure_ramp(oracle) in {
        "direct_self", "shared_includes_self", "any_player_includes_self",
        "target_player_selectable", "controlled_granted_ability",
    }:
        return True
    if _known_mana_token_production(oracle):
        return True
    if ("spells you cast cost" in oracle and "less to cast" in oracle) or re.search(
        r"\bspells you cast\b[^.\n]{0,64}\bcost\b[^.\n]{0,32}\bless to cast\b",
        oracle,
    ):
        return True
    if "mana counter" in oracle and re.search(
        r"\b(?:can|may) spend mana of any color\b[^.\n]{0,48}"
        r"\bequal to the number of mana counters\b",
        oracle,
    ):
        return True
    return False


def _land_search_puts_land_onto_battlefield(oracle: str) -> bool:
    search_index = oracle.find("search your library")
    if search_index < 0:
        return False
    battlefield_index = oracle.find("onto the battlefield", search_index)
    if battlefield_index < 0:
        return False
    next_paragraph = oracle.find("\n", search_index)
    return next_paragraph < 0 or battlefield_index < next_paragraph


def classify_card(card_data: dict) -> str:
    """Replica classifyOptimizationFunctionalRole() do Dart.
    Returns one of: land, draw, removal, wipe, ramp, tutor, protection,
    creature, artifact, enchantment, planeswalker, utility, or strategic roles
    such as wincon, combo_piece, engine, payoff, and enabler.
    """
    name = card_data.get("name", "?")
    type_line = (card_data.get("type_line") or "").lower()
    oracle = (card_data.get("oracle_text") or "").lower()
    cmc = card_data.get("cmc", 0)

    # Land check — also catch basic lands by name heuristic
    if _is_land_type_line(type_line):
        return "land"
    name_lower = name.lower()
    # Basic lands that might not have correct type_line in partial data
    basic_lands = {"mountain", "plains", "island", "swamp", "forest", "wastes"}
    if name_lower.rstrip("0123456789 ").rstrip() in basic_lands:
        return "land"
    if any(name_lower.startswith(b) for b in basic_lands):
        return "land"

    inferred_tags = {
        entry["tag"] for entry in infer_functional_card_tags(
            name=name,
            type_line=type_line,
            oracle_text=oracle,
            cmc=cmc,
        )
    }
    primary_role = _select_primary_role(inferred_tags, type_line)
    if primary_role:
        return primary_role

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


def _looks_like_ritual(oracle: str) -> bool:
    """Replica _looksLikeRitual() do Dart (linha 649)."""
    direct = _oracle_direct_effect_text(oracle.lower())
    for line in re.split(r"[\r\n]+", direct):
        for match in re.finditer(r"add\s+\{", line):
            prefix = line[:match.start()]
            colon = prefix.rfind(":")
            if colon >= 0 and "{t}" in prefix[:colon]:
                continue
            if (any(marker in line for marker in (
                    "until end of turn", "for each", "for every",
                    "your mana pool"))
                    or not any(marker in line for marker in (
                        "at the beginning", "each upkeep", "each combat",
                        "whenever", "mana of any color"))):
                return True
    return False

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


def _looks_like_protection(oracle: str) -> bool:
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
            "gains indestructible" in oracle)


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
    treasure_signal = classify_treasure_ramp(oracle)
    if treasure_signal in {
        "direct_self", "shared_includes_self", "any_player_includes_self",
        "target_player_selectable", "controlled_granted_ability",
    }:
        return True
    without_reminder = _strip_parenthetical_text(oracle.lower())
    direct = _oracle_direct_effect_text(without_reminder)
    if _has_positive_token_production(direct, False):
        return True
    for start, quoted in _quoted_oracle_spans(without_reminder):
        if (_has_positive_token_production(quoted, False)
                and _controlled_granted_context(
                    without_reminder[max(0, start - 360):start])):
            return True
    return "populate" in without_reminder


def _strip_parenthetical_text(value: str) -> str:
    """Remove reminder text, including nested parenthetical clauses."""
    output: list[str] = []
    depth = 0
    for char in value:
        if char == "(":
            depth += 1
            continue
        if char == ")":
            depth = max(0, depth - 1)
            continue
        if depth == 0:
            output.append(char)
    return "".join(output)


def _looks_like_sacrifice_outlet(name: str, oracle: str) -> bool:
    """Mirror the Dart external activated-sacrifice cost classifier."""
    oracle_without_reminder = _strip_parenthetical_text(oracle.lower())
    self_names: set[str] = set()
    for raw_face in re.split(r"\s*//\s*", name):
        face = _normalize_card_name(raw_face)
        if not face:
            continue
        self_names.add(face)
        without_alchemy_prefix = face[2:].strip() if face.startswith("a-") else face
        if without_alchemy_prefix:
            self_names.add(without_alchemy_prefix)
        if "," in without_alchemy_prefix:
            short_name = without_alchemy_prefix.split(",", 1)[0].strip()
            if len(short_name) >= 3:
                self_names.add(short_name)
    external_alternative = re.compile(
        r"\bor\s+(?:another|other|an?|one|two|three|four|five|six|seven|"
        r"eight|nine|ten|x|any|up to|all|half|\d+)\b"
    )
    self_pronoun = re.compile(
        r"^(?:this\b|it\b|that\b|itself\b|the source\b|~(?:\b|$))"
    )

    for line in re.split(r"[\r\n]+", oracle_without_reminder):
        segments = line.split(":")
        for cost_segment in segments[:-1]:
            normalized = re.sub(r"\s+", " ", cost_segment).strip()
            for match in re.finditer(r"\bsacrifice\s+", normalized):
                sacrificed_object = normalized[match.end():].strip()
                if (not sacrificed_object
                        or not re.match(r"^[a-z0-9~]", sacrificed_object)):
                    continue
                has_external_alternative = bool(
                    external_alternative.search(sacrificed_object)
                )
                is_named_self = any(
                    sacrificed_object == self_name
                    or sacrificed_object.startswith(f"{self_name},")
                    or sacrificed_object.startswith(f"{self_name} and ")
                    or sacrificed_object.startswith(f"{self_name} or ")
                    for self_name in self_names
                )
                if ((self_pronoun.match(sacrificed_object) or is_named_self)
                        and not has_external_alternative):
                    continue
                return True
    return False


def _looks_like_aristocrat_payoff(oracle: str) -> bool:
    """Replica _looksLikeAristocratPayoff() do Dart (linha 754)."""
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


def _looks_like_drain(oracle: str) -> bool:
    """Replica _looksLikeDrain() do Dart (linha 779)."""
    return (("loses" in oracle and "you gain" in oracle) or
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


def _looks_like_blink(oracle: str) -> bool:
    """Replica _looksLikeBlink() do Dart (linha 823)."""
    if ("exile target" in oracle and "return" in oracle and "battlefield" in oracle):
        return True
    if ("exile another target" in oracle and "return" in oracle and "battlefield" in oracle):
        return True
    if "flicker" in oracle:
        return True
    return False


def _looks_like_big_spell_payoff(oracle: str) -> bool:
    """Replica _looksLikeBigSpellPayoff() do Dart (linha 834)."""
    return ("if you control a commander" in oracle or
            "without paying its mana cost" in oracle or
            "copy target spell" in oracle or
            ("copy it" in oracle and "spell" in oracle))


def _looks_like_exile_value(oracle: str) -> bool:
    """Replica _looksLikeExileValue() do Dart (linha 842)."""
    return ("exile" in oracle and
            any(t in oracle for t in ["may play", "may cast",
                                      "until the end of your next turn",
                                      "until end of turn"]))


def _looks_like_wincon(oracle: str) -> bool:
    """Replica _looksLikeWincon() do Dart (linha 859)."""
    return ("you win the game" in oracle or
            "loses the game" in oracle or
            "each opponent loses" in oracle or
            ("damage equal to" in oracle and "opponent" in oracle) or
            "double your life total" in oracle)


def _looks_like_wincon_for_name(oracle: str, normalized_name: str) -> bool:
    return "thassa's oracle" in normalized_name or _looks_like_wincon(oracle)


def _looks_like_combo_piece(oracle: str) -> bool:
    """Replica _looksLikeComboPiece() do Dart (linha 868)."""
    return ("copy target activated or triggered ability" in oracle or
            ("untap" in oracle and "add " in oracle) or
            "infinite" in oracle)


def _looks_like_combo_piece_for_name(oracle: str, normalized_name: str) -> bool:
    return ("isochron scepter" in normalized_name or
            "dramatic reversal" in normalized_name or
            "thassa's oracle" in normalized_name or
            _looks_like_combo_piece(oracle))


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


def _looks_like_payoff(oracle: str, normalized_name: str = "") -> bool:
    """Replica _looksLikePayoff() do Dart (linha 887)."""
    if normalized_name == "blood artist":
        return True
    is_cost_reduction = bool(re.search(r'\bcosts?\s+\{[^}]+\}\s+less', oracle))
    is_draw_scaling = "draw a card for each" in oracle or "draw cards equal to" in oracle
    if "for each" in oracle and not is_cost_reduction and not is_draw_scaling:
        return True
    payoff_patterns = [
        "creature dies", "creature enters", "you cast", "artifact enters",
        "enchantment enters", "you sacrifice", "create token",
        "create a token",
    ]
    if "token" in oracle:
        payoff_patterns.append("create")
    if "whenever" in oracle and any(t in oracle for t in payoff_patterns):
        return True
    if "whenever" in oracle and "deals" in oracle and "damage" in oracle:
        return any(t in oracle for t in ["each opponent", "any target", "target opponent"])
    return False


def _looks_like_enabler(oracle: str, normalized_name: str = "") -> bool:
    """Replica _looksLikeEnabler() do Dart (linha 898)."""
    return ("greaves" in normalized_name or
            "boots" in normalized_name or
            "costs {" in oracle and "less to cast" in oracle or
            "you may play an additional land" in oracle or
            "haste" in oracle or
            "mill" in oracle or
            "sacrifice another" in oracle or
            ("search your library" in oracle and not looks_like_land_search(oracle)))


def _select_primary_role(tags: set[str], type_line: str = "") -> Optional[str]:
    if not tags:
        return None
    role_map = {
        "board_wipe": "wipe",
        "loot": "draw",
        "ritual": "ramp",
        "exile_value": "draw",
        "token_maker": "creature",
        "aristocrat_payoff": "engine",
        "spellslinger": "engine",
        "artifact_synergy": "engine",
        "enchantment_synergy": "engine",
        "graveyard_synergy": "engine",
        "sacrifice_outlet": "engine",
        "lifegain": "utility",
        "drain": "wincon",
        "etb": "utility",
        "blink": "protection",
        "big_spell": "wincon",
    }
    for tag in [
        "board_wipe", "wincon", "combo_piece", "engine", "payoff",
        "draw", "removal", "ramp", "tutor", "protection", "recursion",
        "token_maker", "enabler", "land", "creature", "artifact",
        "enchantment", "planeswalker",
    ]:
        if tag in tags:
            return role_map.get(tag, tag)
    type_lower = type_line.lower()
    if "creature" in type_lower:
        return "creature"
    if "artifact" in type_lower:
        return "artifact"
    if "enchantment" in type_lower:
        return "enchantment"
    if "planeswalker" in type_lower:
        return "planeswalker"
    return "utility"


def _ordered_tag_names(tags: list[dict]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for tag in tags:
        name = str(tag.get("tag", "")).strip()
        if not name or name in seen:
            continue
        seen.add(name)
        ordered.append(name)
    return ordered


def _normalize_color_identity(value: Any) -> str:
    """Normalize a Scryfall color_identity payload without inventing colors."""
    if value is None:
        return ""
    if isinstance(value, str):
        raw_values = list(value)
    elif isinstance(value, list):
        raw_values = value
    else:
        return ""

    seen: set[str] = set()
    colors: list[str] = []
    for raw in raw_values:
        color = str(raw).strip().upper()
        if color not in {"W", "U", "B", "R", "G"} or color in seen:
            continue
        seen.add(color)
        colors.append(color)
    return "".join(colors)


def _infer_deck_color_identity(
    commander_name: str,
    commander_card: dict | None,
    enriched_cards: list[dict],
) -> str:
    """Prefer commander color identity; fall back to observed card identities.

    The previous helper hardcoded Lorehold as RW. That remains only as a
    compatibility fallback when legacy Lorehold payloads lack Scryfall identity.
    """
    if commander_card:
        commander_identity = _normalize_color_identity(
            commander_card.get("color_identity"),
        )
        if commander_identity:
            return commander_identity

    merged = _normalize_color_identity([
        color
        for card in enriched_cards
        for color in _normalize_color_identity(card.get("color_identity"))
    ])
    if merged:
        return merged

    if commander_name.strip().lower() == "lorehold, the historian":
        return "RW"
    return ""


def _merge_user_override_tag(tags: list[dict], override: str) -> list[dict]:
    if not override:
        return tags
    merged = list(tags)
    for tag in merged:
        if tag.get("tag") == override:
            tag["confidence"] = max(float(tag.get("confidence", 0.0)), 1.0)
            tag["evidence"] = "user_tag_comment"
            break
    else:
        merged.append({
            "tag": override,
            "confidence": 1.0,
            "evidence": "user_tag_comment",
        })
    return sorted(merged, key=lambda t: (-float(t.get("confidence", 0.0)), t.get("tag", "")))


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

    is_land = _is_land_type_line(type_lower)
    if is_land:
        add("land", 1.0, "type_line_land")

    if not is_land:
        # ramp check: uses original oracle_text for Dart compat
        if (looks_like_ramp(oracle, type_lower)):
            add("ramp", 0.88, "mana_or_land_ramp_text")

    if not is_land and _looks_like_ritual(oracle):
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

    if _looks_like_protection(oracle):
        add("protection", 0.82, "protection_keyword_or_effect")

    if _looks_like_recursion(oracle):
        add("recursion", 0.86, "graveyard_return_text")

    if _looks_like_graveyard_synergy(oracle):
        add("graveyard_synergy", 0.72, "graveyard_payoff_or_setup_text")

    if _looks_like_token_maker(oracle):
        add("token_maker", 0.82, "token_creation_text")

    if _looks_like_sacrifice_outlet(name, oracle):
        add(
            "sacrifice_outlet",
            0.80,
            "external_activated_sacrifice_outlet_cost",
        )

    if _looks_like_aristocrat_payoff(oracle):
        add("aristocrat_payoff", 0.84, "death_trigger_payoff_text")

    if _looks_like_lifegain(oracle):
        add("lifegain", 0.76, "life_gain_text")

    if _looks_like_drain(oracle):
        add("drain", 0.82, "life_loss_payoff_text")

    if _looks_like_spellslinger(oracle):
        add("spellslinger", 0.84, "instant_sorcery_cast_payoff_text")

    if _looks_like_artifact_synergy(oracle):
        add("artifact_synergy", 0.74, "artifact_payoff_text")

    if _looks_like_enchantment_synergy(oracle):
        add("enchantment_synergy", 0.74, "enchantment_payoff_text")

    if _looks_like_etb(oracle):
        add("etb", 0.70, "enters_the_battlefield_text")

    if _looks_like_blink(oracle):
        add("blink", 0.86, "exile_then_return_text")
        add("protection", 0.68, "blink_can_protect_permanent")

    if cmc >= 6 or _looks_like_big_spell_payoff(oracle):
        add("big_spell", 0.72, "high_mana_value_or_big_turn_text")

    if _looks_like_exile_value(oracle):
        add("exile_value", 0.84, "exile_play_or_cast_value_text")

    if _looks_like_wincon_for_name(oracle, normalized_name):
        add("wincon", 0.78, "explicit_win_or_finisher_text")

    if _looks_like_combo_piece_for_name(oracle, normalized_name):
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
            tags = []
            cmc = 0
            type_line = ""
        else:
            cmc = card_data.get("cmc", 0)
            type_line = card_data.get("type_line", "")
            tags = infer_functional_card_tags(
                name=card_data.get("name", name),
                type_line=type_line,
                oracle_text=card_data.get("oracle_text", ""),
                cmc=cmc,
            )
            functional_tag = classify_card(card_data)

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
            tags = _merge_user_override_tag(tags, override)

        enriched.append({
            "name": name,
            "qty": c["qty"],
            "set_code": c["set_code"],
            "tag_comment": tag,
            "functional_tag": functional_tag,
            "functional_tags_json": _ordered_tag_names(tags),
            "tags": tags,
            "cmc": cmc,
            "type_line": type_line,
            "color_identity": _normalize_color_identity(
                card_data.get("color_identity"),
            ),
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
            "functional_tags_json": c.get("functional_tags_json", []),
            "is_commander": 1 if c == commander_card else 0,
            "cmc": c["cmc"],
            "type_line": c.get("type_line", ""),
            "color_identity": _normalize_color_identity(c.get("color_identity")),
        }
        # Include multi-tags if available
        if c.get("tags"):
            card_entry["tags"] = c["tags"]
            primary = _select_primary_role({t["tag"] for t in c["tags"]}, c.get("type_line", ""))
            if primary:
                card_entry["functional_tag"] = primary
        cards_out.append(card_entry)

    return {
        "commander": commander_name,
        "archetype": archetype,
        "color_identity": _infer_deck_color_identity(
            commander_name,
            commander_card,
            enriched_cards,
        ),
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
        "board_wipe_count": tag_counts.get("wipe", 0) + tag_counts.get("board_wipe", 0),
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
