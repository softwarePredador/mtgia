#!/usr/bin/env python3
"""
Lorehold Battle Analyst v8 — Interactive Commander Simulator
Fase A: Priority, Stack, Instant/Sorcery Timing
+ Fase B: Miracle (Lorehold core mechanic)
+ Fase C: SBAs, Boros Charm modal, Double Strike fix, Indestructible per-creature

Regras implementadas agora:
- Priority System (CR 117): cada jogador recebe prioridade por turno
- Stack LIFO (CR 405): spells resolvem em ordem reversa
- Instant vs Sorcery timing: instants podem ser conjurados em resposta
- Counterspells: oponentes podem counterar spells ameacadoras
- State-Based Actions (CR 704): verificadas apos cada spell resolver
- Miracle (CR 702.94): Lorehold da miracle {2} a instants/sorceries na mao
- Boros Charm modal: escolhe indestructible ou double strike por contexto
- Double Strike fix: 2x dano total (nao 3x)
- Indestructible per-creature: board wipe respeita indestructible individual
- Lifelink: life gain ao causar dano
- Haste: Lorehold nao tem summoning sickness
"""
import sqlite3, random, json, os, re, copy
from datetime import datetime, timezone
from collections import defaultdict

try:
    import battle_rule_registry
except Exception:
    battle_rule_registry = None

DB = os.environ.get(
    "MANALOOM_KNOWLEDGE_DB",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
)
KNOWLEDGE_DIR = os.environ.get(
    "MANALOOM_KNOWLEDGE_DIR",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge",
)
LOG_PATH = f"{KNOWLEDGE_DIR}/decks/lorehold-the-historian/BATTLE_LOG.md"

REPLAY_EVENT_HANDLER = None


def emit_replay_event(event, **data):
    """Emit optional structured replay events without affecting simulation."""
    if REPLAY_EVENT_HANDLER is None:
        return
    try:
        REPLAY_EVENT_HANDLER(event, data)
    except Exception:
        pass


def replay_card_snapshot(card):
    """Small JSON-safe card summary for turn-by-turn replay audits."""
    if not isinstance(card, dict):
        return {"name": str(card)}
    return {
        "name": card.get("name", "?"),
        "power": card.get("power"),
        "toughness": card.get("toughness"),
        "cmc": card.get("cmc"),
        "keywords": [
            keyword
            for keyword in (
                "flying",
                "reach",
                "trample",
                "deathtouch",
                "first_strike",
                "double_strike",
                "lifelink",
                "indestructible",
                "haste",
                "vigilance",
                "shroud",
            )
            if card.get(keyword)
        ],
        "is_commander": bool(card.get("is_commander")),
        "type_line": card.get("type_line", ""),
        "tapped": bool(card.get("tapped")),
        "summoning_sick": bool(card.get("summoning_sick")),
    }


MANA_SYMBOL_TO_POOL = {
    "W": "white",
    "U": "blue",
    "B": "black",
    "R": "red",
    "G": "green",
    "C": "colorless",
}

BASIC_LAND_COLORS = {
    "Plains": "white",
    "Island": "blue",
    "Swamp": "black",
    "Mountain": "red",
    "Forest": "green",
    "Wastes": "colorless",
    "Ancient Den": "white",
    "Seat of the Synod": "blue",
    "Vault of Whispers": "black",
    "Great Furnace": "red",
    "Tree of Tales": "green",
}

KNOWN_LAND_NAMES = {
    name
    for name in (
        "plains",
        "island",
        "swamp",
        "mountain",
        "forest",
        "wastes",
        "high market",
        "tropical island",
        "tundra",
        "otawara, soaring city",
        "dryad arbor",
        "gaea's cradle",
        "havenwood battleground",
        "mishra's factory",
        "ancient tomb",
        "command tower",
        "exotic orchard",
        "fabled passage",
        "field of the dead",
        "reflecting pool",
        "reliquary tower",
        "strip mine",
        "wasteland",
        "wooded foothills",
        "windswept heath",
        "arid mesa",
        "scalding tarn",
        "misty rainforest",
        "verdant catacombs",
        "marsh flats",
        "polluted delta",
        "bloodstained mire",
        "flooded strand",
        "prismatic vista",
    )
}


def parse_mana_cost(cost, fallback_cmc=0):
    """Parse a mana cost into generic, colored, and flexible hybrid symbols."""
    if isinstance(cost, (int, float)):
        return {"generic": int(cost), "colored": defaultdict(int), "hybrid": []}
    if not cost:
        return {
            "generic": int(float(fallback_cmc or 0)),
            "colored": defaultdict(int),
            "hybrid": [],
        }

    parsed = {"generic": 0, "colored": defaultdict(int), "hybrid": []}
    for raw_symbol in re.findall(r"\{([^}]+)\}", str(cost).upper()):
        symbol = raw_symbol.strip()
        if symbol.isdigit():
            parsed["generic"] += int(symbol)
        elif symbol in ("X", "Y", "Z"):
            continue
        elif symbol in MANA_SYMBOL_TO_POOL:
            parsed["colored"][MANA_SYMBOL_TO_POOL[symbol]] += 1
        elif "/" in symbol:
            options = [
                MANA_SYMBOL_TO_POOL[part]
                for part in symbol.split("/")
                if part in MANA_SYMBOL_TO_POOL
            ]
            if options:
                parsed["hybrid"].append(options)
            elif any(part.isdigit() for part in symbol.split("/")):
                parsed["generic"] += 1
        else:
            parsed["generic"] += 1
    return parsed


def card_mana_cost(card, additional_generic=0):
    parsed = parse_mana_cost(card.get("mana_cost"), card.get("cmc", 0))
    parsed["generic"] += additional_generic
    return parsed


def source_colors(source):
    """Return pool colors a source can produce; unknown legacy sources are generic."""
    if source == "land":
        return ["generic"]
    if not isinstance(source, dict):
        return ["generic"]
    explicit = (
        source.get("produces")
        or source.get("produced_mana")
        or source.get("color_identity")
    )
    if isinstance(explicit, str):
        explicit = re.findall(r"[WUBRGC]", explicit.upper())
    if explicit:
        colors = [
            MANA_SYMBOL_TO_POOL.get(str(color).upper(), str(color).lower())
            for color in explicit
        ]
        valid = [color for color in colors if color in set(MANA_SYMBOL_TO_POOL.values())]
        return ["wildcard"] if len(valid) > 1 else (valid or ["generic"])
    basic_color = BASIC_LAND_COLORS.get(source.get("name", ""))
    return [basic_color] if basic_color else ["generic"]


SELF_KEYWORD_ABILITIES = {
    "flying",
    "reach",
    "trample",
    "deathtouch",
    "first_strike",
    "double_strike",
    "lifelink",
    "indestructible",
    "haste",
    "vigilance",
    "flash",
    "menace",
    "infect",
}


def _keyword_values(card):
    keyword_values = card.get("keywords") or []
    if isinstance(keyword_values, str):
        keyword_values = read_json_list(keyword_values) or [keyword_values]
    return {
        str(value).lower().replace(" ", "_")
        for value in keyword_values
        if str(value).strip()
    }


def _oracle_self_keyword_values(card):
    oracle_text = str(card.get("oracle_text") or "").strip()
    if not oracle_text:
        return set()
    first_line = oracle_text.splitlines()[0].strip()
    first_line = re.sub(r"\([^)]*\)", "", first_line).strip().rstrip(".")
    if not first_line:
        return set()
    parts = [
        part.strip().lower().replace(" ", "_")
        for part in re.split(r"[,;]", first_line)
        if part.strip()
    ]
    if not parts or any(part not in SELF_KEYWORD_ABILITIES for part in parts):
        return set()
    return set(parts)


def enrich_card(card):
    """Preserve imported metadata and expose only self-owned combat keywords."""
    enriched = dict(card)
    keyword_values = _oracle_self_keyword_values(enriched)
    if enriched.get("_keywords_are_self") or not str(enriched.get("oracle_text") or "").strip():
        keyword_values |= _keyword_values(enriched)
    for keyword in SELF_KEYWORD_ABILITIES:
        if keyword in keyword_values:
            enriched[keyword] = True
    return enriched


def card_has_keyword(card, keyword):
    """Check explicit fields plus self-owned keyword abilities only."""
    if not isinstance(card, dict):
        return False
    normalized_keyword = str(keyword or "").lower().replace(" ", "_")
    if card.get(normalized_keyword):
        return True
    if normalized_keyword in _oracle_self_keyword_values(card):
        return True
    if card.get("_keywords_are_self") or not str(card.get("oracle_text") or "").strip():
        return normalized_keyword in _keyword_values(card)
    return False


def has_haste(card):
    return card_has_keyword(card, "haste")


def has_vigilance(card):
    return card_has_keyword(card, "vigilance")


def is_battlefield_creature(card):
    """Permanent-level creature check; effects can add extra roles."""
    if not isinstance(card, dict):
        return False
    return (
        card.get("effect") == "creature"
        or bool(card.get("is_creature_permanent"))
        or "creature" in str(card.get("type_line") or "").lower()
    )


def is_mana_source_permanent(source):
    if source == "land":
        return True
    if not isinstance(source, dict):
        return False
    if source.get("effect") in ("land", "ramp_permanent"):
        return True
    if source.get("is_mana_source"):
        return True
    return source.get("effect") == "ramp_engine" and source.get("mana_produced") is not None


def normalize_card_name(name):
    return re.sub(r"\s+", " ", str(name or "").strip().lower())


def read_json_list(value):
    if not value:
        return []
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(value)
    except Exception:
        return []
    if isinstance(decoded, list):
        return decoded
    return []


def numeric_stat(value):
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def load_card_oracle_cache(conn, names):
    """Load production card metadata previously synced into local SQLite."""
    normalized_names = sorted({normalize_card_name(name) for name in names if name})
    if not normalized_names:
        return {}
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='card_oracle_cache'"
    ).fetchone()
    if not table:
        return {}

    cache = {}
    for index in range(0, len(normalized_names), 500):
        chunk = normalized_names[index:index + 500]
        placeholders = ",".join("?" for _ in chunk)
        rows = conn.execute(f"""
            SELECT normalized_name, name, mana_cost, colors_json,
                   color_identity_json, type_line, oracle_text, cmc, power,
                   toughness, keywords_json, scryfall_id
            FROM card_oracle_cache
            WHERE normalized_name IN ({placeholders})
        """, chunk).fetchall()
        for row in rows:
            cache[row["normalized_name"]] = {
                "oracle_name": row["name"],
                "mana_cost": row["mana_cost"],
                "colors": read_json_list(row["colors_json"]),
                "color_identity": read_json_list(row["color_identity_json"]),
                "type_line": row["type_line"],
                "oracle_text": row["oracle_text"],
                "cmc": row["cmc"],
                "power": numeric_stat(row["power"]),
                "toughness": numeric_stat(row["toughness"]),
                "keywords": read_json_list(row["keywords_json"]),
                "scryfall_id": row["scryfall_id"],
            }
    return cache


def merge_oracle_metadata(card, oracle_cache):
    metadata = oracle_cache.get(normalize_card_name(card.get("name")))
    if not metadata:
        return card
    enriched = dict(card)
    for key in (
        "mana_cost",
        "type_line",
        "oracle_text",
        "cmc",
        "power",
        "toughness",
        "scryfall_id",
        "oracle_name",
    ):
        value = metadata.get(key)
        if value is not None and value != "":
            enriched[key] = value
    for key in ("colors", "color_identity", "keywords"):
        value = metadata.get(key)
        if value:
            enriched[key] = value
    return enriched


# ═══════════════════════════════════════════
# DECK LOADING
# ═══════════════════════════════════════════

def load_deck(deck_id=6):
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT card_name, quantity, CAST(COALESCE(cmc,0) AS REAL) as cmc,
               COALESCE(functional_tag,'unknown') as functional_tag,
               type_line, oracle_text, is_commander
        FROM deck_cards WHERE deck_id=?
    """, (deck_id,)).fetchall()
    oracle_cache = load_card_oracle_cache(conn, [row["card_name"] for row in rows])
    conn.close()
    commander = None
    deck = []
    for row in rows:
        qty = row["quantity"] or 1
        card = merge_oracle_metadata({
            "name": row["card_name"],
            "cmc": float(row["cmc"] or 0),
            "tag": row["functional_tag"] or "unknown",
            "type_line": row["type_line"] or "",
            "oracle_text": row["oracle_text"] or "",
            "is_commander": bool(row["is_commander"]),
        }, oracle_cache)
        card = enrich_card(card)
        if card["is_commander"]: commander = card
        else:
            for _ in range(qty): deck.append(card)
    return commander, deck

# ═══════════════════════════════════════════
# CARD EFFECTS
# ═══════════════════════════════════════════

KNOWN_CARDS = {
    "Teferi's Protection": {"effect": "phase_out", "instant": True},
    "Boros Charm": {"effect": "modal_boros_charm", "instant": True},
    "Deflecting Swat": {"effect": "redirect_removal", "instant": True},
    "Grand Abolisher": {"effect": "silence_opponents"},
    "Austere Command": {"effect": "board_wipe", "selective": True},
    "Blasphemous Act": {"effect": "board_wipe"},
    "Call Forth the Tempest": {"effect": "damage_wipe", "token_maker": True},
    "Approach of the Second Sun": {"effect": "approach", "gain_life": 7},
    "Insurrection": {"effect": "steal_all_creatures"},
    "Mizzix's Mastery": {"effect": "overload_recursion"},
    "Storm Herd": {"effect": "token_maker", "token_count": "life_total"},
    "Surge to Victory": {"effect": "pump_all", "recursion": True},
    "Rite of the Dragoncaller": {"effect": "token_maker", "token_count": 4, "token_power": 5},
    "Brass's Bounty": {"effect": "token_maker", "token_count": "lands"},
    "Akroma's Will": {"effect": "pump_all", "instant": True,
        "keywords": ["flying","double_strike","vigilance","lifelink","protection_all","indestructible"]},
    "The One Ring": {"effect": "draw_engine", "burden": True},
    "Wedding Ring": {"effect": "draw_engine", "symmetric": True},
    "Victory Chimes": {"effect": "draw_engine", "untap": True},
    "Sensei's Divining Top": {"effect": "topdeck_manipulation"},
    "Scroll Rack": {"effect": "topdeck_manipulation"},
    "Sol Ring": {"effect": "ramp_permanent", "mana_produced": 2},
    "Arcane Signet": {"effect": "ramp_permanent", "mana_produced": 1},
    "Boros Signet": {"effect": "ramp_permanent", "mana_produced": 1},
    "Talisman of Conviction": {"effect": "ramp_permanent", "mana_produced": 1},
    "Double Vision": {"effect": "copy_spell"},
    "Arcane Bombardment": {"effect": "copy_spell", "repeatable": True},
    "Enlightened Tutor": {"effect": "tutor", "target": "artifact_or_enchantment", "instant": True},
    "Gamble": {"effect": "tutor", "target": "any", "discard_risk": True},
    "Smothering Tithe": {"effect": "ramp_engine", "trigger": "opponent_draw"},
    "Jeska's Will": {"effect": "ramp_ritual", "mana_produced": 7},
    "Esper Sentinel": {"effect": "draw_engine", "trigger": "opponent_spell"},
    "Lorehold, the Historian": {"effect": "commander", "is_commander": True, "haste": True},
    "Chaos Warp": {"effect": "remove_permanent", "instant": True},
    "Path to Exile": {"effect": "remove_creature", "instant": True},
    "Swords to Plowshares": {"effect": "remove_creature", "instant": True},
    "Abrade": {"effect": "remove_artifact_or_3dmg", "instant": True},
    "Generous Gift": {"effect": "remove_permanent", "instant": True},
    "Deflecting Swat": {"effect": "redirect_removal", "instant": True},
    "Dragon's Approach": {"effect": "dragons_approach", "damage": 3},
    "Dance with Calamity": {"effect": "exile_value", "miracle": True},
    "Reforge the Soul": {"effect": "draw_cards", "count": 7, "miracle": "1R"},
    "Lumra, Bellow of the Woods": {
        "effect": "land_recursion_creature",
        "mill_count": 4,
        "power_equals_lands": True,
        "toughness_equals_lands": True,
        "keywords": ["vigilance", "reach"],
    },
    "Walking Ballista": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "activated_damage": True,
        "is_creature_permanent": True,
    },
    "Springheart Nantuko": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "landfall_token_maker": True,
        "token_power": 1,
        "token_toughness": 1,
        "is_creature_permanent": True,
    },
    "Stridehangar Automaton": {
        "effect": "creature",
        "power": 1,
        "toughness": 4,
        "keywords": ["flying"],
        "artifact_token_replacement": True,
        "thopter_lord": True,
        "is_creature_permanent": True,
    },
    "Demand Answers": {"effect": "draw_cards", "count": 2, "instant": True},
    "Reckless Impulse": {"effect": "draw_cards", "count": 2},
    "Food Chain": {"effect": "ramp_engine", "requires_creature_resource": True},
    "Chromatic Orrery": {
        "effect": "ramp_permanent",
        "mana_produced": 5,
        "produces": "WUBRGC",
    },
    "Wheel of Misfortune": {"effect": "draw_cards", "count": 7},
    "Strike It Rich": {"effect": "treasure_maker", "treasure_count": 1},
    "Desperate Ritual": {"effect": "ramp_ritual", "mana_produced": 3, "instant": True},
    "Diabolic Intent": {
        "effect": "tutor",
        "target": "any",
        "requires_sacrifice_creature": True,
    },
    "Noxious Revival": {"effect": "recursion", "count": 1, "instant": True},
    "Burgeoning": {"effect": "ramp_engine", "trigger": "opponent_land_play"},
    "Last Chance": {"effect": "extra_turn", "turns": 1, "lose_after_extra_turn": True},
    "Shore Up": {"effect": "protect_creature", "instant": True, "power_boost": 1, "toughness_boost": 1, "untap": True},
    "Goblin Engineer": {"effect": "creature", "power": 1, "toughness": 2, "is_creature_permanent": True},
    "Ugin, the Spirit Dragon": {"effect": "board_wipe", "selective": True},
    "Sylvan Safekeeper": {"effect": "creature", "power": 1, "toughness": 1, "is_creature_permanent": True},
    "Sowing Mycospawn": {"effect": "creature", "power": 3, "toughness": 3, "is_creature_permanent": True},
    "Force of Negation": {"effect": "counter", "instant": True},
    "Staff of Compleation": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "All Is Dust": {"effect": "board_wipe"},
    "Ruthless Technomancer": {"effect": "creature", "power": 2, "toughness": 4, "is_creature_permanent": True},
    "Deathrite Shaman": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRG",
        "is_creature_permanent": True,
    },
    "Summon: Bahamut": {"effect": "creature", "power": 9, "toughness": 9, "keywords": ["flying"], "is_creature_permanent": True},
    "The Eternity Elevator": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Hedron Archive": {"effect": "ramp_permanent", "mana_produced": 2, "produces": "C"},
    "Staff of Domination": {"effect": "draw_cards", "count": 1},
    "Manifold Key": {"effect": "ramp_engine"},
    "Unwinding Clock": {"effect": "ramp_engine", "trigger": "artifact_untap"},
    "Misdirection": {"effect": "redirect_removal", "instant": True},
    "Bloom Tender": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 2,
        "produces": "WUBRG",
        "is_creature_permanent": True,
    },
    "Pyretic Ritual": {"effect": "ramp_ritual", "mana_produced": 3, "instant": True},
    "Devoted Druid": {
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Krark-Clan Ironworks": {"effect": "ramp_engine", "requires_artifact_resource": True},
    "Talisman of Indulgence": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "BRC"},
    "Spider-Punk": {"effect": "creature", "power": 2, "toughness": 1, "keywords": ["haste"], "is_creature_permanent": True},
    "Thran Dynamo": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Altar of Dementia": {"effect": "unknown"},
    "Impulsive Pilferer": {"effect": "creature", "power": 1, "toughness": 1, "is_creature_permanent": True},
    "Elves of Deep Shadow": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "B",
        "is_creature_permanent": True,
    },
    "Worldly Tutor": {"effect": "tutor", "target": "creature", "instant": True},
    "Spell Pierce": {"effect": "counter", "instant": True},
    "Mana Leak": {"effect": "counter", "instant": True},
    "The Soul Stone": {"effect": "recursion", "count": 1},
    "Trophy Mage": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Fabricate": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Expedition Map": {"effect": "tutor", "target": "land"},
    "Lively Dirge": {"effect": "recursion", "count": 1},
    "Glaring Fleshraker": {"effect": "token_maker", "token_count": 1, "token_power": 0, "token_toughness": 1},
    "Forsaken Monument": {"effect": "pump_all", "keywords": [], "power_multiplier": 1},
    "Hullbreaker Horror": {"effect": "remove_permanent"},
    "Windfall": {"effect": "draw_cards", "count": 7},
    "Wan Shi Tong, Librarian": {"effect": "draw_engine", "trigger": "historic_spell"},
    "Mirage Mirror": {"effect": "ramp_engine"},
    "Force of Vigor": {"effect": "remove_permanent", "instant": True},
    "Training Grounds": {"effect": "ramp_engine"},
    "Freed from the Real": {"effect": "ramp_engine"},
    "Bolas's Citadel": {"effect": "topdeck_manipulation"},
    "Dimir Signet": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "UB"},
    "Bender's Waterskin": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Isochron Scepter": {"effect": "copy_spell"},
    "Inspiring Statuary": {"effect": "ramp_engine"},
    "Praetor's Grasp": {"effect": "tutor", "target": "any"},
    "Sylvan Scrying": {"effect": "tutor", "target": "land"},
    "Wild Growth": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "G"},
    "Counterspell": {"effect": "counter", "instant": True},
    "Nature's Claim": {
        "effect": "remove_permanent",
        "instant": True,
        "target": "artifact_or_enchantment",
        "target_controller_gains_life": 4,
    },
    "Formidable Speaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Soul-Guide Lantern": {"effect": "hate_artifact", "sacrifice_draw": 1},
    "Open the Omenpaths": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "instant": True,
        "restricted_to_creature_or_enchantment": True,
    },
    "Jaxis, the Troublemaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Jin-Gitaxias, Progress Tyrant": {
        "effect": "copy_spell",
        "power": 5,
        "toughness": 5,
        "is_creature_permanent": True,
    },
    "Mirrormade": {"effect": "unknown"},
    "Nezahal, Primal Tide": {
        "effect": "draw_engine",
        "trigger": "opponent_noncreature_spell",
        "power": 7,
        "toughness": 7,
        "is_creature_permanent": True,
        "uncounterable": True,
    },
    "Ugin, Eye of the Storms": {
        "effect": "remove_permanent",
        "target": "colored_permanent",
    },
    "Squee, the Immortal": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Fierce Empath": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "creature_cmc_6_plus",
    },
    "Rionya, Fire Dancer": {
        "effect": "creature",
        "power": 3,
        "toughness": 4,
        "is_creature_permanent": True,
        "begin_combat_copy_engine": True,
    },
    "Cursed Mirror": {
        "effect": "ramp_permanent",
        "mana_produced": 1,
        "produces": "R",
    },
    "Mystic Forge": {"effect": "topdeck_manipulation"},
    "Sneak Attack": {"effect": "unknown"},
    "Eldritch Evolution": {
        "effect": "tutor",
        "target": "creature_to_battlefield",
        "requires_sacrifice_creature": True,
        "exiles_self": True,
    },
    "Stoneforge Mystic": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_creature_permanent": True,
        "etb_tutor_target": "equipment",
    },
    "Reprieve": {"effect": "counter", "instant": True, "draw_on_counter": 1},
    "Splendid Reclamation": {"effect": "land_recursion"},
    "Vandalblast": {"effect": "remove_permanent", "target": "artifact"},
    "Delivery Moogle": {
        "effect": "creature",
        "power": 3,
        "toughness": 2,
        "keywords": ["flying"],
        "is_creature_permanent": True,
        "etb_tutor_target": "cheap_artifact",
    },
    "Galadriel's Dismissal": {"effect": "phase_creatures", "instant": True},
    "Bottle-Cap Blast": {"effect": "deal_damage", "amount": 5, "instant": True},
    "Mechanized Warfare": {"effect": "unknown"},
    "Cloud of Faeries": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Rampant Growth": {"effect": "land_ramp", "land_count": 1, "basic_only": True},
    "Springbloom Druid": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_land_ramp_count": 2,
        "etb_requires_sacrifice_land": True,
        "basic_only": True,
    },
    "Tannuk, Memorial Ensign": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "is_creature_permanent": True,
        "landfall_damage_each_opponent": 1,
        "landfall_second_draw": True,
    },
    "Commandeer": {"effect": "counter", "instant": True},
    "Roiling Regrowth": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
        "requires_sacrifice_land": True,
        "instant": True,
    },
    "Echoes of Eternity": {"effect": "copy_spell", "colorless_only": True},
    "Pest Infestation": {
        "effect": "remove_permanent",
        "target": "artifact_or_enchantment",
    },
    "Reckless Handling": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Spellseeker": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "cheap_instant_or_sorcery",
    },
    "Snakeskin Veil": {
        "effect": "protect_creature",
        "instant": True,
        "power_boost": 1,
        "toughness_boost": 1,
    },
    "Omnath, Locus of Rage": {
        "effect": "creature",
        "power": 5,
        "toughness": 5,
        "is_creature_permanent": True,
        "landfall_token_maker": True,
        "token_power": 5,
        "token_toughness": 5,
    },
    "Fog": {"effect": "unknown", "instant": True},
    "Grist, the Hunger Tide": {"effect": "commander", "is_commander": True},
    "Amphibian Downpour": {
        "effect": "remove_creature",
        "instant": True,
        "target": "creature",
    },
    "Oswald Fiddlebender": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Brainstorm": {"effect": "draw_cards", "count": 1, "instant": True},
    "Talisman of Creativity": {
        "effect": "ramp_permanent",
        "mana_produced": 1,
        "produces": "URC",
    },
    "Mishra's Bauble": {"effect": "draw_cards", "count": 1},
    "Harrow": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
        "requires_sacrifice_land": True,
        "instant": True,
    },
    "Solemn Simulacrum": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
        "etb_land_ramp_count": 1,
        "basic_only": True,
    },
    "Snake Umbra": {"effect": "unknown"},
    "Sakura-Tribe Elder": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Explore": {"effect": "draw_cards", "count": 1},
    "Gitaxian Probe": {"effect": "draw_cards", "count": 1},
    "Artist's Talent": {"effect": "draw_engine"},
    "Helm of Awakening": {"effect": "ramp_engine"},
    "Dragon's Rage Channeler": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Migration Path": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
    },
    "Cryptolith Rite": {"effect": "ramp_engine"},
    "Tireless Tracker": {
        "effect": "creature",
        "power": 3,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Gravecrawler": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
        "cant_block": True,
    },
    "Kozilek's Command": {
        "effect": "remove_creature",
        "target": "creature",
        "instant": True,
    },
    "Demonic Counsel": {"effect": "tutor", "target": "any"},
    "Assassin's Trophy": {
        "effect": "remove_permanent",
        "target": "nonland",
        "instant": True,
    },
    "Deadly Rollick": {
        "effect": "remove_creature",
        "target": "creature",
        "instant": True,
    },
    "Persist": {
        "effect": "recursion",
        "target": "creature",
        "destination": "battlefield",
        "count": 1,
    },
    "Cityscape Leveler": {
        "effect": "creature",
        "power": 8,
        "toughness": 8,
        "keywords": ["trample"],
        "is_creature_permanent": True,
    },
    "Skullclamp": {"effect": "passive"},
    "Reanimate": {
        "effect": "recursion",
        "target": "creature",
        "destination": "battlefield",
        "count": 1,
    },
    "Harmonize": {"effect": "draw_cards", "count": 3},
    "Wheel of Fate": {"effect": "draw_cards", "count": 7},
    "Search for Tomorrow": {
        "effect": "land_ramp",
        "land_count": 1,
        "basic_only": True,
    },
    "Blind Obedience": {"effect": "passive"},
    "Cultivate": {
        "effect": "land_ramp",
        "land_count": 1,
        "basic_only": True,
    },
    "Monologue Tax": {"effect": "ramp_engine", "trigger": "opponent_second_spell"},
    "Talisman of Resilience": {
        "effect": "ramp_permanent",
        "mana_produced": 1,
        "produces": "BGC",
    },
    "Sylvan Library": {"effect": "passive"},
    "Entomb": {"effect": "tutor", "target": "graveyard", "instant": True},
    "Explosive Vegetation": {
        "effect": "land_ramp",
        "land_count": 2,
        "basic_only": True,
    },
    "Necromancy": {
        "effect": "recursion",
        "target": "creature",
        "destination": "battlefield",
        "count": 1,
    },
    "Unmarked Grave": {"effect": "tutor", "target": "graveyard_nonlegendary"},
    "Carpet of Flowers": {"effect": "ramp_engine"},
    "Teferi, Time Raveler": {"effect": "passive"},
    "Plague Myr": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["infect"],
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "Elvish Reclaimer": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "land_tutor_activated": True,
        "is_creature_permanent": True,
    },
    "Zuran Orb": {"effect": "life_artifact", "sacrifice_land_gain_life": 2},
    "Vexing Bauble": {
        "effect": "hate_artifact",
        "counters_free_spells": True,
        "sacrifice_draw": 1,
    },
    # Runtime Commander/cEDH staples promoted after Hermes forensic audit.
    "Pact of Negation": {"effect": "counter", "instant": True},
    "Force of Will": {"effect": "counter", "instant": True},
    "Mindbreak Trap": {"effect": "counter", "instant": True},
    "Swan Song": {"effect": "counter", "instant": True},
    "Pyroblast": {"effect": "counter", "instant": True, "target": "blue_spell_or_permanent"},
    "Red Elemental Blast": {"effect": "counter", "instant": True, "target": "blue_spell_or_permanent"},
    "Mental Misstep": {"effect": "counter", "instant": True},
    "An Offer You Can't Refuse": {"effect": "counter", "instant": True},
    "Silence": {"effect": "silence_spell", "instant": True},
    "Orim's Chant": {"effect": "silence_spell", "instant": True},
    "Demonic Tutor": {"effect": "tutor", "target": "any"},
    "Vampiric Tutor": {"effect": "tutor", "target": "any", "instant": True},
    "Imperial Seal": {"effect": "tutor", "target": "any"},
    "Mystical Tutor": {"effect": "tutor", "target": "instant_or_sorcery", "instant": True},
    "Green Sun's Zenith": {"effect": "tutor", "target": "green_creature_to_battlefield"},
    "Beseech the Mirror": {"effect": "tutor", "target": "any"},
    "Wishclaw Talisman": {"effect": "tutor", "target": "any"},
    "Land Tax": {"effect": "passive"},
    "Weathered Wayfarer": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Imperial Recruiter": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "small_creature",
    },
    "Recruiter of the Guard": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
        "etb_tutor_target": "small_creature",
    },
    "Mother of Runes": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Giver of Runes": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Drannith Magistrate": {
        "effect": "passive",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Grafdigger's Cage": {"effect": "passive"},
    "Rapid Hybridization": {"effect": "remove_creature", "instant": True, "target": "creature"},
    "Into the Flood Maw": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Chain of Vapor": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Orcish Bowmasters": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["flash"],
        "is_creature_permanent": True,
    },
    "Mana Vault": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Mox Diamond": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Chrome Mox": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Mox Amber": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Mox Opal": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Fellwar Stone": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Ruby Medallion": {"effect": "ramp_engine"},
    "Grim Monolith": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Lotus Petal": {"effect": "ramp_ritual", "mana_produced": 1, "produces": "WUBRGC"},
    "Lion's Eye Diamond": {"effect": "ramp_ritual", "mana_produced": 3, "produces": "WUBRGC"},
    "Rite of Flame": {"effect": "ramp_ritual", "mana_produced": 2},
    "Dark Ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "Seething Song": {"effect": "ramp_ritual", "mana_produced": 5},
    "Cabal Ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "Brightstone Ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "Mystic Remora": {"effect": "draw_engine", "trigger": "opponent_noncreature_spell"},
    "Rhystic Study": {"effect": "draw_engine", "trigger": "opponent_spell"},
    "Wheel of Fortune": {"effect": "draw_cards", "count": 7},
    "Faithless Looting": {"effect": "draw_cards", "count": 2},
    "Consider": {"effect": "draw_cards", "count": 1, "instant": True},
    "Expedite": {"effect": "draw_cards", "count": 1},
    "Crimson Wisps": {"effect": "draw_cards", "count": 1, "instant": True},
    "Valakut Awakening": {"effect": "draw_cards", "count": 3, "instant": True},
    "Underworld Breach": {"effect": "passive"},
    "Past in Flames": {"effect": "recursion", "target": "instant_or_sorcery", "count": 3},
    "Sevinne's Reclamation": {"effect": "recursion", "count": 1},
    "Nature's Rhythm": {"effect": "recursion", "count": 1},
    "Twinflame": {"effect": "token_maker", "token_count": 1, "token_power": 2, "token_haste": True},
    "Heat Shimmer": {"effect": "token_maker", "token_count": 1, "token_power": 2, "token_haste": True},
    "Hangarback Walker": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Aetherflux Reservoir": {"effect": "finisher"},
    "Thassa's Oracle": {"effect": "finisher"},
    "Brain Freeze": {"effect": "finisher"},
    "Grapeshot": {"effect": "deal_damage", "amount": 1},
    "Guttersnipe": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "trigger": "instant_sorcery_cast",
        "trigger_effect": "damage_each_opponent",
        "damage": 2,
        "is_creature_permanent": True,
    },
    "Fiery Emancipation": {"effect": "passive"},
    "Final Fortune": {"effect": "extra_turn", "turns": 1, "lose_after_extra_turn": True},
    "Flawless Maneuver": {"effect": "indestructible", "instant": True},
    "Tezzeret, Cruel Captain": {"effect": "passive"},
    "Agatha's Soul Cauldron": {"effect": "passive"},
    "Retraction Helix": {"effect": "remove_permanent", "target": "nonland", "instant": True},
    "Fierce Guardianship": {"effect": "counter", "instant": True},
    "Flusterstorm": {"effect": "counter", "instant": True},
    "Flare of Denial": {"effect": "counter", "instant": True},
    "Daze": {"effect": "counter", "instant": True},
    "Sink into Stupor": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Finale of Devastation": {"effect": "tutor", "target": "green_creature_to_battlefield"},
    "Longshot, Rebel Bowman": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "keywords": ["reach"],
        "trigger": "instant_sorcery_cast",
        "trigger_effect": "damage_each_opponent",
        "damage": 2,
        "is_creature_permanent": True,
    },
    "Insidious Roots": {"effect": "passive"},
    "Pinnacle Monk": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "keywords": ["prowess"],
        "is_creature_permanent": True,
    },
    "Flashback": {"effect": "recursion", "target": "instant_or_sorcery", "count": 1, "instant": True},
    "Eternal Witness": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Ranger-Captain of Eos": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
        "etb_tutor_target": "small_creature",
    },
    "Snap": {"effect": "remove_creature", "instant": True, "target": "creature"},
    "Transmute Artifact": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Urza, Lord High Artificer": {
        "effect": "creature",
        "power": 1,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Chains of Mephistopheles": {"effect": "passive"},
    "Might of the Meek": {"effect": "draw_cards", "count": 1, "instant": True},
    "Overmaster": {"effect": "draw_cards", "count": 1},
    "Repurposing Bay": {"effect": "passive"},
    "Molten Duplication": {"effect": "token_maker", "token_count": 1, "token_power": 2, "token_haste": True},
    "Muse Seeker": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Ashling, Flame Dancer": {
        "effect": "creature",
        "power": 4,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Simulacrum Synthesizer": {"effect": "passive"},
    "Knight of the Reliquary": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "land_tutor_activated": True,
        "is_creature_permanent": True,
    },
    "Touch the Spirit Realm": {"effect": "remove_permanent", "target": "artifact_or_creature"},
    "Survival of the Fittest": {"effect": "passive"},
    "Kozilek, Butcher of Truth": {
        "effect": "creature",
        "power": 12,
        "toughness": 12,
        "is_creature_permanent": True,
    },
    "Ulamog, the Infinite Gyre": {
        "effect": "creature",
        "power": 10,
        "toughness": 10,
        "keywords": ["indestructible"],
        "is_creature_permanent": True,
    },
    "Forensic Gadgeteer": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Abrupt Decay": {"effect": "remove_permanent", "instant": True, "target": "nonland"},
    "Invasion of Ikoria": {"effect": "tutor", "target": "green_creature_to_battlefield"},
    "Intuition": {"effect": "tutor", "target": "any", "instant": True},
    "Fell the Profane": {"effect": "remove_creature", "instant": True, "target": "creature"},
    "Seal of Primordium": {"effect": "passive"},
    "Worldfire": {"effect": "board_wipe"},
    "Voice of Victory": {
        "effect": "silence_opponents",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Grim Tutor": {"effect": "tutor", "target": "any"},
    "Archdruid's Charm": {"effect": "remove_permanent", "instant": True, "target": "artifact_or_enchantment"},
    "Summoner's Pact": {"effect": "tutor", "target": "green_creature", "instant": True},
    "Step Through": {"effect": "remove_creature", "target": "creature"},
    "Illicit Shipment": {"effect": "tutor", "target": "any"},
    "Electro, Assaulting Battery": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Vilis, Broker of Blood": {
        "effect": "creature",
        "power": 8,
        "toughness": 8,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Boggart Trawler": {
        "effect": "creature",
        "power": 3,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Guild Artisan": {"effect": "passive"},
    "Golgari Grave-Troll": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Aether Spellbomb": {"effect": "passive"},
    "Thrasios, Triton Hero": {
        "effect": "creature",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Urza's Bauble": {"effect": "passive"},
    "Emerald Charm": {"effect": "remove_permanent", "instant": True, "target": "enchantment"},
    "Sewer-veillance Cam": {"effect": "passive"},
    "Metalworker": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 2,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "Scour for Scrap": {"effect": "tutor", "target": "artifact_or_enchantment", "instant": True},
    "Demonic Collusion": {"effect": "tutor", "target": "any"},
    "Borne Upon a Wind": {"effect": "draw_cards", "count": 1, "instant": True},
    "Ad Nauseam": {"effect": "draw_cards", "count": 5, "instant": True},
    "Demonic Consultation": {"effect": "tutor", "target": "any", "instant": True},
    "Tainted Pact": {"effect": "tutor", "target": "any", "instant": True},
    "Chord of Calling": {"effect": "tutor", "target": "creature_to_battlefield", "instant": True},
    "Crop Rotation": {
        "effect": "land_ramp",
        "land_count": 1,
        "requires_sacrifice_land": True,
        "instant": True,
    },
    "Birgi, God of Storytelling": {
        "effect": "ramp_engine",
        "mana_produced": 1,
        "produces": "R",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Culling the Weak": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "produces": "B",
        "requires_sacrifice_creature": True,
        "instant": True,
    },
    "Culling Ritual": {"effect": "ramp_ritual", "mana_produced": 4, "produces": "BG"},
    "Mana Geyser": {"effect": "ramp_ritual", "mana_produced": 7, "produces": "R"},
    "Rain of Filth": {"effect": "ramp_ritual", "mana_produced": 3, "produces": "B", "instant": True},
    "Simian Spirit Guide": {"effect": "ramp_ritual", "mana_produced": 1, "produces": "R", "instant": True},
    "Unexpected Windfall": {
        "effect": "treasure_maker",
        "treasure_count": 2,
        "draw_count": 2,
        "requires_discard_card": True,
        "instant": True,
    },
    "Birds of Paradise": {
        "effect": "creature",
        "power": 0,
        "toughness": 1,
        "keywords": ["flying"],
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Delighted Halfling": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "Fyndhorn Elves": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Wall of Roots": {
        "effect": "creature",
        "power": 0,
        "toughness": 5,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Relic of Legends": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Springleaf Drum": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Ragavan, Nimble Pilferer": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "keywords": ["haste"],
        "is_creature_permanent": True,
    },
    "Professional Face-Breaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "keywords": ["menace"],
        "is_creature_permanent": True,
    },
    "Storm-Kiln Artist": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "The Gitrog Monster": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["deathtouch"],
        "is_creature_permanent": True,
    },
    "Faerie Mastermind": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "keywords": ["flash", "flying"],
        "is_creature_permanent": True,
    },
    "Dualcaster Mage": {
        "effect": "copy_spell",
        "power": 2,
        "toughness": 2,
        "keywords": ["flash"],
        "is_creature_permanent": True,
    },
    "Hexing Squelcher": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Allosaurus Shepherd": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Enduring Vitality": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "keywords": ["vigilance"],
        "is_creature_permanent": True,
    },
    "Badgermole Cub": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "The Cabbage Merchant": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Tavern Scoundrel": {
        "effect": "creature",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Copy Enchantment": {"effect": "passive"},
    "Thousand-Year Elixir": {"effect": "passive"},
    "Clock of Omens": {"effect": "passive"},
    "The Reality Chip": {
        "effect": "topdeck_manipulation",
        "power": 0,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Mnemonic Betrayal": {"effect": "passive"},
    "Reverberate": {"effect": "copy_spell", "instant": True},
    "Reiterate": {"effect": "copy_spell", "instant": True},
    "Arcane Denial": {"effect": "counter", "instant": True},
    "Negate": {"effect": "counter", "instant": True},
    "Wash Away": {"effect": "counter", "instant": True},
    "Power Sink": {"effect": "counter", "instant": True},
    "Louisoix's Sacrifice": {"effect": "counter", "instant": True},
    "Condescend": {"effect": "counter", "instant": True},
    "Twisted Image": {"effect": "draw_cards", "count": 1, "instant": True},
    "Drift of Phantasms": {
        "effect": "tutor",
        "target": "cmc_3",
        "power": 0,
        "toughness": 5,
        "keywords": ["flying"],
        "is_creature_permanent": True,
    },
    "Tymna the Weaver": {
        "effect": "draw_engine",
        "trigger": "combat_damage_to_player",
        "power": 2,
        "toughness": 2,
        "keywords": ["lifelink"],
        "is_creature_permanent": True,
    },
    "Nexus of Becoming": {
        "effect": "draw_engine",
        "trigger": "begin_combat",
    },
    "Feed the Swarm": {"effect": "remove_permanent", "target": "creature_or_enchantment"},
    "Bitter Downfall": {"effect": "remove_creature", "target": "creature", "instant": True},
    "Seedship Impact": {"effect": "remove_permanent", "target": "artifact_or_enchantment", "instant": True},
    "Cyclonic Rift": {"effect": "remove_permanent", "target": "nonland", "instant": True},
    "Snapback": {"effect": "remove_creature", "target": "creature", "instant": True},
    "Eldrazi Confluence": {"effect": "remove_permanent", "target": "nonland", "instant": True},
    "Spine of Ish Sah": {"effect": "remove_permanent", "target": "permanent"},
    "Analyze the Pollen": {"effect": "tutor", "target": "land"},
    "Gifts Ungiven": {"effect": "tutor", "target": "any", "instant": True},
    "Eladamri's Call": {"effect": "tutor", "target": "creature", "instant": True},
    "Tezzeret the Seeker": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Dryad's Revival": {"effect": "recursion", "count": 1},
    "Deep Analysis": {"effect": "draw_cards", "count": 2},
    "Boon of the Wish-Giver": {"effect": "draw_cards", "count": 4},
    "Timetwister": {"effect": "draw_cards", "count": 7},
    "Roiling Dragonstorm": {"effect": "draw_cards", "count": 2},
    "Rise of the Eldrazi": {"effect": "extra_turn", "turns": 1, "exiles_self": True},
    "Living Death": {"effect": "board_wipe"},
    "Legolas's Quick Reflexes": {
        "effect": "protect_creature",
        "instant": True,
        "untap": True,
    },
    "Biosynthic Burst": {
        "effect": "protect_creature",
        "instant": True,
        "untap": True,
        "power_boost": 1,
        "toughness_boost": 1,
    },
    "Momentary Blink": {"effect": "phase_creatures", "instant": True},
    "Turn to Mist": {"effect": "phase_creatures", "instant": True},
    "Fiery Inscription": {"effect": "passive"},
    "Prismatic Undercurrents": {"effect": "passive"},
    "Necrodominance": {"effect": "passive"},
    "Altar of the Wretched": {"effect": "passive"},
    "Skyclave Apparition": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Karmic Guide": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "keywords": ["flying"],
        "etb_recursion_count": 1,
        "etb_recursion_target": "creature",
        "etb_recursion_destination": "battlefield",
        "is_creature_permanent": True,
    },
    "Archaeomancer": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "etb_recursion_count": 1,
        "etb_recursion_target": "instant_or_sorcery",
        "is_creature_permanent": True,
    },
    "Dawnbringer Cleric": {
        "effect": "creature",
        "power": 1,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Restoration Angel": {
        "effect": "creature",
        "power": 3,
        "toughness": 4,
        "keywords": ["flash", "flying"],
        "is_creature_permanent": True,
    },
    "Myr Battlesphere": {
        "effect": "creature",
        "power": 4,
        "toughness": 7,
        "etb_token_count": 4,
        "etb_token_power": 1,
        "etb_token_toughness": 1,
        "etb_token_name": "Myr",
        "etb_artifact_tokens": True,
        "is_creature_permanent": True,
    },
    "Goblin Cratermaker": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Monstrosity of the Lake": {
        "effect": "creature",
        "power": 4,
        "toughness": 6,
        "is_creature_permanent": True,
    },
    "Glacier Godmaw": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["trample", "vigilance", "haste"],
        "is_creature_permanent": True,
    },
    "Disciple of Freyalise": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Fiend Artisan": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Scryb Ranger": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "keywords": ["flash", "flying"],
        "is_creature_permanent": True,
    },
    "Shelob, Dread Weaver": {
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Rampaging War Mammoth": {
        "effect": "creature",
        "power": 9,
        "toughness": 7,
        "keywords": ["trample"],
        "is_creature_permanent": True,
    },
    "Duplicant": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "is_creature_permanent": True,
    },
    "Rydia, Summoner of Mist": {
        "effect": "creature",
        "power": 1,
        "toughness": 2,
        "keywords": ["haste"],
        "is_creature_permanent": True,
    },
    "Knuckles the Echidna": {
        "effect": "creature",
        "power": 2,
        "toughness": 4,
        "keywords": ["double_strike", "trample", "haste"],
        "is_creature_permanent": True,
    },
    "Shambling Ghast": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "They Came from the Pipes": {
        "effect": "token_maker",
        "token_count": 2,
        "token_power": 2,
        "token_toughness": 2,
    },
    "Map the Frontier": {"effect": "land_ramp", "land_count": 2, "basic_only": True},
    "Metamorphosis": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "requires_sacrifice_creature": True,
    },
    "Far Wanderings": {"effect": "land_ramp", "land_count": 1, "basic_only": True},
    "Herigast, Erupting Nullkite": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["flying"],
        "etb_draw_count": 3,
        "is_creature_permanent": True,
    },
    "Mind Stone": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "C"},
    "Commander's Sphere": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WUBRGC"},
    "Azorius Signet": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WU"},
    "Talisman of Progress": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "WU"},
    "Talisman of Dominance": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "UB"},
    "Talisman of Impulse": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "RG"},
    "Fractured Powerstone": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "C"},
    "Worn Powerstone": {"effect": "ramp_permanent", "mana_produced": 2, "produces": "C"},
    "Basalt Monolith": {"effect": "ramp_permanent", "mana_produced": 3, "produces": "C"},
    "Everflowing Chalice": {"effect": "ramp_permanent", "mana_produced": 1, "produces": "C"},
    "Wayfarer's Bauble": {"effect": "land_ramp", "land_count": 1, "basic_only": True},
    "Manamorphose": {
        "effect": "treasure_maker",
        "treasure_count": 2,
        "draw_count": 1,
        "instant": True,
    },
    "Thrill of Possibility": {
        "effect": "draw_cards",
        "count": 2,
        "requires_discard_card": True,
        "instant": True,
    },
    "Fact or Fiction": {"effect": "draw_cards", "count": 3, "instant": True},
    "Peer into the Abyss": {"effect": "draw_cards", "count": 10},
    "Relic of Sauron": {"effect": "ramp_permanent", "mana_produced": 2, "produces": "UBR"},
    "Dramatic Reversal": {"effect": "ramp_ritual", "mana_produced": 2, "instant": True},
    "Flare of Duplication": {"effect": "copy_spell", "instant": True},
    "Run Away Together": {"effect": "remove_creature", "target": "creature", "instant": True},
    "Deafening Silence": {"effect": "passive"},
    "Monument to Endurance": {"effect": "passive"},
    "Growing Rites of Itlimoc": {"effect": "topdeck_manipulation"},
    "In the Darkness Bind Them": {
        "effect": "token_maker",
        "token_count": 3,
        "token_power": 3,
        "token_toughness": 3,
    },
    "Kinnan, Bonder Prodigy": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Ignoble Hierarch": {
        "effect": "creature",
        "power": 0,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "BRG",
        "is_creature_permanent": True,
    },
    "Noble Hierarch": {
        "effect": "creature",
        "power": 0,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "GWU",
        "is_creature_permanent": True,
    },
    "Avacyn's Pilgrim": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "W",
        "is_creature_permanent": True,
    },
    "Elvish Mystic": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Elvish Spirit Guide": {"effect": "ramp_ritual", "mana_produced": 1, "produces": "G", "instant": True},
    "Tinder Wall": {
        "effect": "creature",
        "power": 0,
        "toughness": 3,
        "is_mana_source": True,
        "mana_produced": 2,
        "produces": "R",
        "is_creature_permanent": True,
    },
    "Ornithopter of Paradise": {
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "keywords": ["flying"],
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Myr Convert": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Circle of Dreams Druid": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 3,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Selvala, Heart of the Wilds": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_mana_source": True,
        "mana_produced": 3,
        "produces": "WUBRGC",
        "is_creature_permanent": True,
    },
    "Magda, Brazen Outlaw": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Lotho, Corrupt Shirriff": {
        "effect": "creature",
        "power": 2,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Notion Thief": {
        "effect": "creature",
        "power": 3,
        "toughness": 1,
        "keywords": ["flash"],
        "is_creature_permanent": True,
    },
    "Charming Prince": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "is_creature_permanent": True,
    },
    "Mulldrifter": {
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "keywords": ["flying"],
        "etb_draw_count": 2,
        "is_creature_permanent": True,
    },
    "Treasonous Ogre": {
        "effect": "creature",
        "power": 2,
        "toughness": 3,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "R",
        "is_creature_permanent": True,
    },
    "Cavern-Hoard Dragon": {
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "keywords": ["flying", "haste", "trample"],
        "is_creature_permanent": True,
    },
    "Voltaic Key": {"effect": "passive"},
    "Lavaspur Boots": {"effect": "equipment_haste_shroud"},
    "Defense Grid": {"effect": "passive"},
    "Imposter Mech": {"effect": "passive"},
    "Page, Loose Leaf": {
        "effect": "creature",
        "power": 0,
        "toughness": 2,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "C",
        "is_creature_permanent": True,
    },
    "\"Name Sticker\" Goblin": {"effect": "ramp_ritual", "mana_produced": 4, "produces": "R"},
    "The Balrog of Moria": {
        "effect": "creature",
        "power": 8,
        "toughness": 8,
        "is_creature_permanent": True,
    },
    "Burnt Offering": {
        "effect": "ramp_ritual",
        "mana_produced": 4,
        "produces": "BR",
        "requires_sacrifice_creature": True,
        "instant": True,
    },
    "Sylvan Tutor": {"effect": "tutor", "target": "creature"},
    "Gene Pollinator": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_mana_source": True,
        "mana_produced": 1,
        "produces": "G",
        "is_creature_permanent": True,
    },
    "Deadpool, Trading Card": {
        "effect": "creature",
        "power": 5,
        "toughness": 3,
        "is_creature_permanent": True,
    },
    "Displace": {"effect": "phase_creatures", "instant": True},
    "Goblin Welder": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Greedy Freebooter": {
        "effect": "creature",
        "power": 1,
        "toughness": 1,
        "is_creature_permanent": True,
    },
    "Splinter's Technique": {"effect": "tutor", "target": "any"},
    "Vibrance": {
        "effect": "creature",
        "power": 4,
        "toughness": 4,
        "is_creature_permanent": True,
    },
}

HANDCRAFTED_KNOWN_CARDS = set(KNOWN_CARDS)

TAG_EFFECTS = {
    "ramp": {"effect": "ramp_permanent", "mana_produced": 1},
    "ritual": {"effect": "ramp_ritual", "mana_produced": 3},
    "draw": {"effect": "draw_cards", "count": 2},
    "removal": {"effect": "remove_creature"},
    "board_wipe": {"effect": "board_wipe"},
    "protection": {"effect": "indestructible", "duration": 1},
    "token_maker": {"effect": "token_maker", "token_count": 5, "token_power": 2},
    "wincon": {"effect": "finisher"},
    "tutor": {"effect": "tutor", "target": "any"},
    "recursion": {"effect": "recursion", "count": 2},
    "pump": {"effect": "pump_one", "power_boost": 3},
    "loot": {"effect": "loot", "count": 1},
}


def normalize_effect_by_oracle(card, effect_data):
    """Correct broad generated/tag mistakes using imported oracle metadata."""
    normalized = effect_data.copy()
    effect = normalized.get("effect", "unknown")
    type_line = str(card.get("type_line") or "")
    oracle_text = str(card.get("oracle_text") or "")
    text = f"{type_line}\n{oracle_text}".lower()

    if "land" in type_line.lower():
        normalized["effect"] = "land"
        normalized.pop("instant", None)
        normalized.pop("miracle", None)
        return normalized

    if "counter target" in text:
        normalized["effect"] = "counter"
        normalized["instant"] = True
        return normalized

    if "return target spell" in text:
        normalized["effect"] = "counter"
        normalized["instant"] = True
        return normalized

    if re.search(r"\b(destroy|exile)\s+target\b", text):
        is_immediate_spell = "instant" in type_line.lower() or "sorcery" in type_line.lower()
        if (
            not is_immediate_spell
            and effect not in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg")
        ):
            return normalized
        if (
            normalized.get("effect") == "overload_recursion"
            and "graveyard" in text
            and ("instant" in text or "sorcery" in text)
        ):
            return normalized
        if normalized.get("effect") == "remove_artifact_or_3dmg":
            return normalized
        if re.search(r"\b(destroy|exile)\s+target\s+artifact\b", text):
            normalized["effect"] = "remove_permanent"
            return normalized
        normalized["effect"] = (
            "remove_creature" if "target creature" in text else "remove_permanent"
        )
        return normalized

    if "from your graveyard" in text and re.search(r"\breturn target\b", text):
        is_immediate_spell = "instant" in type_line.lower() or "sorcery" in type_line.lower()
        if not is_immediate_spell and effect not in ("recursion", "overload_recursion"):
            return normalized
        normalized["effect"] = "recursion"
        return normalized

    if re.search(r"\breturn target\b", text):
        normalized["effect"] = "remove_permanent"
        return normalized

    if (
        ("return each" in text or "return all" in text)
        and "nonland permanent" in text
    ):
        normalized["effect"] = "board_wipe"
        return normalized

    if (
        effect == "silence_opponents"
        and "can't be countered" in text
        and not re.search(r"opponents? can't cast", text)
        and "can't cast spells" not in text
    ):
        if "creature" in type_line.lower():
            normalized["effect"] = "creature"
        else:
            normalized["effect"] = "unknown"
    return normalized


def with_rule_metadata(
    effect_data,
    *,
    source,
    review_status="heuristic",
    confidence=0.0,
    rule_version=None,
):
    annotated = dict(effect_data)
    annotated.setdefault("_rule_source", source)
    annotated.setdefault("_rule_review_status", review_status)
    annotated.setdefault("_rule_confidence", confidence)
    if rule_version is not None:
        annotated.setdefault("_rule_version", rule_version)
    return annotated


def replay_rule_fields(effect_data):
    """Expose rule provenance in structured replay events."""
    return {
        "rule_source": effect_data.get("_rule_source", "unknown"),
        "rule_review_status": effect_data.get("_rule_review_status", "unknown"),
        "rule_confidence": effect_data.get("_rule_confidence", 0.0),
        "rule_version": effect_data.get("_rule_version"),
    }


# ── KNOWN_CARDS Auto-Generator Loader (v8.4) ──
# Loads generated entries from known_cards_generated.json (handcrafted takes priority)
_gen_json_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'known_cards_generated.json')
if os.path.exists(_gen_json_path):
    try:
        with open(_gen_json_path) as _f:
            _generated = json.load(_f)
        for _name, _entry in _generated.items():
            if _name not in KNOWN_CARDS:  # never override handcrafted
                KNOWN_CARDS[_name] = _entry
    except Exception: pass
def get_card_effect(card):
    name = card.get("name", "")
    if name in HANDCRAFTED_KNOWN_CARDS:
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                KNOWN_CARDS[name],
                source="known_cards_manual",
                review_status="verified",
                confidence=1.0,
            ),
        )
    if battle_rule_registry is not None:
        rule = battle_rule_registry.lookup_battle_card_rule(DB, name)
        if rule and rule.get("effect_json"):
            effect = with_rule_metadata(
                rule["effect_json"],
                source=rule.get("source", "battle_card_rules"),
                review_status=rule.get("review_status", "unknown"),
                confidence=rule.get("confidence", 0.0),
                rule_version=rule.get("rule_version"),
            )
            return normalize_effect_by_oracle(card, effect)
    if name in KNOWN_CARDS:
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                KNOWN_CARDS[name],
                source="known_cards_generated",
                review_status="needs_review",
                confidence=0.55,
            ),
        )
    tag = card.get("tag", "")
    if tag in TAG_EFFECTS:
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                TAG_EFFECTS[tag],
                source="functional_tag",
                review_status="heuristic",
                confidence=0.35,
            ),
        )
    effect = card.get("effect", "")
    effect_map = {"ramp": "ramp_permanent", "removal": "remove_creature",
                  "board_wipe": "board_wipe", "wincon": "finisher", "draw": "draw_cards",
                  "counter": "counter", "land": "land"}
    if effect in effect_map:
        if effect == "ramp":
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    {"effect": "ramp_permanent", "mana_produced": 1},
                    source="card_effect_field",
                    review_status="heuristic",
                    confidence=0.25,
                ),
            )
        if effect == "wincon":
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    {"effect": "finisher"},
                    source="card_effect_field",
                    review_status="heuristic",
                    confidence=0.25,
                ),
            )
        if effect == "draw":
            return normalize_effect_by_oracle(
                card,
                with_rule_metadata(
                    {"effect": "draw_cards", "count": 2},
                    source="card_effect_field",
                    review_status="heuristic",
                    confidence=0.25,
                ),
            )
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                {"effect": effect_map[effect]},
                source="card_effect_field",
                review_status="heuristic",
                confidence=0.25,
            ),
        )
    if "land" in card.get("type_line", "").lower():
        return with_rule_metadata(
            {"effect": "land"},
            source="type_line_land",
            review_status="fact",
            confidence=0.75,
        )
    if effect == "creature" or "creature" in card.get("type_line", "").lower():
        return normalize_effect_by_oracle(
            card,
            with_rule_metadata(
                {"effect": "creature", "power": card.get("power", 2)},
                source="type_line_creature",
                review_status="fact",
                confidence=0.65,
            ),
        )
    return normalize_effect_by_oracle(
        card,
        with_rule_metadata(
            {"effect": "unknown"},
            source="unknown",
            review_status="missing",
            confidence=0.0,
        ),
    )

def is_instant(card):
    """v8: Check if a card can be cast at instant speed."""
    if is_effective_land(card):
        return False
    name = card.get("name", "")
    tl = card.get("type_line", "")
    if "Instant" in tl:
        return True
    if card_has_keyword(card, "flash"):
        return True
    if any(card_type in tl for card_type in ("Sorcery", "Creature", "Artifact", "Enchantment", "Planeswalker", "Battle")):
        return False
    if get_card_effect(card).get("instant"):
        return True
    if name in KNOWN_CARDS and KNOWN_CARDS[name].get("instant"):
        return True
    return False

def is_sorcery(card):
    if is_effective_land(card):
        return False
    return "Sorcery" in card.get("type_line", "")


def is_instant_or_sorcery_spell(card):
    """Strict spell type check for effects that care about instant/sorcery cards."""
    if is_effective_land(card):
        return False
    tl = card.get("type_line", "")
    return "Instant" in tl or "Sorcery" in tl


def card_has_color(card, symbol):
    values = card.get("color_identity") or card.get("colors") or []
    if isinstance(values, str):
        decoded = read_json_list(values)
        values = decoded or re.findall(r"[WUBRGC]", values.upper())
    return str(symbol).upper() in {str(value).upper() for value in values}


def is_creature_card(card):
    if not isinstance(card, dict):
        return False
    return "creature" in str(card.get("type_line") or "").lower()


def is_modeled_battle_card(card):
    return get_card_effect(card).get("effect") != "unknown"

# ═══════════════════════════════════════════
# OPPONENTS
# ═══════════════════════════════════════════

OPPONENT_ARCHETYPES = [
    {"name": "Aggro (Krenko)", "archetype": "aggro", "life": 40,
     "lands": 34, "ramp": 8, "removal": 5, "counters": 0,
     "creatures": 35, "wincons": 3, "draw": 4, "wipe": 2, "avg_cmc": 2.5, "strategy": "rush",
     "commander_name": "Krenko, Mob Boss", "commander_cmc": 4},
    {"name": "Control (Atraxa)", "archetype": "control", "life": 40,
     "lands": 37, "ramp": 12, "removal": 12, "counters": 6,
     "creatures": 15, "wincons": 3, "draw": 6, "wipe": 6, "avg_cmc": 3.2, "strategy": "control",
     "commander_name": "Atraxa, Praetors' Voice", "commander_cmc": 4},
    {"name": "Combo (Kinnan)", "archetype": "combo", "life": 40,
     "lands": 30, "ramp": 15, "removal": 6, "counters": 8,
     "creatures": 18, "wincons": 4, "draw": 8, "wipe": 1, "avg_cmc": 2.1, "strategy": "combo",
     "commander_name": "Kinnan, Bonder Prodigy", "commander_cmc": 2},
    {"name": "Midrange (Korvold)", "archetype": "midrange", "life": 40,
     "lands": 36, "ramp": 12, "removal": 8, "counters": 2,
     "creatures": 25, "wincons": 3, "draw": 6, "wipe": 3, "avg_cmc": 3.0, "strategy": "value",
     "commander_name": "Korvold, Fae-Cursed King", "commander_cmc": 5},
    {"name": "Spellslinger (Niv)", "archetype": "spellslinger", "life": 40,
     "lands": 36, "ramp": 10, "removal": 10, "counters": 5,
     "creatures": 10, "wincons": 3, "draw": 8, "wipe": 3, "avg_cmc": 2.8, "strategy": "spells",
     "commander_name": "Niv-Mizzet, Parun", "commander_cmc": 6},
    {"name": "Stax (Winota)", "archetype": "stax", "life": 40,
     "lands": 35, "ramp": 8, "removal": 8, "counters": 0,
     "creatures": 30, "wincons": 3, "draw": 3, "wipe": 2, "avg_cmc": 2.6, "strategy": "stax",
     "commander_name": "Winota, Joiner of Forces", "commander_cmc": 4},
]

def generate_opponent_deck(profile):
    deck = []
    for _ in range(profile["lands"]):
        deck.append({"name": "Land", "cmc": 0, "tag": "land", "effect": "land", "type_line": "Land"})
    for _ in range(profile["ramp"]):
        deck.append({"name": "Ramp Card", "cmc": max(1, profile["avg_cmc"] - 0.5), "tag": "ramp", "effect": "ramp"})
    for _ in range(profile["removal"]):
        deck.append({"name": "Removal", "cmc": max(1, profile["avg_cmc"] - 1), "tag": "removal", "effect": "removal"})
    for _ in range(profile["creatures"]):
        pwr = max(1, int(profile["avg_cmc"]))
        deck.append({"name": "Creature", "cmc": profile["avg_cmc"], "tag": "creature", "effect": "creature", "power": pwr, "type_line": "Creature"})
    for _ in range(profile["wincons"]):
        deck.append({"name": "Wincon", "cmc": max(3, profile["avg_cmc"] + 1), "tag": "wincon", "effect": "wincon"})
    for _ in range(profile["draw"]):
        deck.append({"name": "Draw Spell", "cmc": max(2, profile["avg_cmc"] - 0.5), "tag": "draw", "effect": "draw"})
    for _ in range(profile.get("wipe", 2)):
        deck.append({"name": "Board Wipe", "cmc": 4, "tag": "board_wipe", "effect": "board_wipe"})
    for _ in range(profile.get("counters", 0)):
        deck.append({"name": "Counterspell", "cmc": 2, "tag": "counter", "effect": "counter", "instant": True, "type_line": "Instant"})
    while len(deck) < 99:
        deck.append({"name": "Filler Creature", "cmc": profile["avg_cmc"], "tag": "creature", "effect": "creature", "power": 2, "type_line": "Creature"})
    return deck[:99]

def get_opponent_commander(profile):
    return {"name": profile["commander_name"], "cmc": profile["commander_cmc"],
            "tag": "creature", "effect": "creature",
            "power": max(2, profile["commander_cmc"]),
            "type_line": "Legendary Creature", "is_commander": True, "owner": profile["name"]}

# ═══════════════════════════════════════════
# PLAYER STATE
# ═══════════════════════════════════════════

class ManaPool:
    def __init__(self): self.generic = self.white = self.blue = self.black = self.red = self.green = self.colorless = self.wildcard = 0
    def total(self): return self.generic + self.white + self.blue + self.black + self.red + self.green + self.colorless + self.wildcard
    def add_generic(self, n): self.generic += n
    def add(self, color, amount=1):
        if color not in ("generic", "white", "blue", "black", "red", "green", "colorless", "wildcard"):
            color = "generic"
        setattr(self, color, getattr(self, color) + amount)
    def snapshot(self):
        return {
            color: getattr(self, color)
            for color in ("generic", "white", "blue", "black", "red", "green", "colorless", "wildcard")
        }
    def spend(self, amount):
        if amount < 0 or amount > self.total():
            return False
        remaining = amount
        for color in ("generic", "colorless", "wildcard", "white", "blue", "black", "red", "green"):
            available = getattr(self, color)
            used = min(available, remaining)
            setattr(self, color, available - used)
            remaining -= used
            if remaining == 0:
                break
        return True
    def empty(self):
        self.generic = self.white = self.blue = self.black = self.red = self.green = self.colorless = self.wildcard = 0

class Player:
    def shuffle(self, rng): rng.shuffle(self.library)

    def draw(self, n=1, rng=None):
        drawn = []
        for _ in range(n):
            if self.library:
                c = self.library.pop(0)
                self.hand.append(c)
                drawn.append(c)
                self.cards_drawn_this_turn += 1
            else:
                self.failed_draw_from_empty_library = True
        return drawn

    def __init__(self, name, commander, deck, is_human=False, strategy="midrange"):
        self.name = name
        self.commander = commander
        self.command_zone = [commander] if commander else []
        self.commander_tax = 0
        self.library = list(deck)
        self.hand = []
        self.battlefield = []
        self.phased_out = []
        self.graveyard = []
        self.exile = []
        self.life = 40
        self.commander_damage = defaultdict(int)
        self.mana_pool = ManaPool()
        self.lands_played_this_turn = 0
        self.max_lands_per_turn = 1
        self.is_human = is_human
        self.strategy = strategy
        self.indestructible = False
        self.life_cant_change = False
        self.protection_from_everything = False
        self.silenced_opponents = False
        self.silenced_opponents_until_eot = False
        self.approach_count = 0
        self.treasures = 0
        self.draw_engines = 0
        self.copy_engines = 0
        self.counters_available = 0
        self.threat_level = 0  # v8.1: archenemy tracking
        self.approach_revealed = []  # v8.1: opponents who know approach was cast
        self.extra_turns = 0
        self.extra_turn_loss_pending = 0
        self.eliminated = False
        self.poison = 0  # v9: poison counters
        self.win_reason = None
        self.cards_drawn_this_turn = 0
        self.failed_draw_from_empty_library = False

    def refresh_mana_sources(self, turn=None):
        """Untap mana sources once for this player's turn."""
        self.mana_pool.empty()
        sources = [
            source
            for source in self.battlefield
            if is_mana_source_permanent(source)
            and not (
                is_battlefield_creature(source)
                and source.get("is_mana_source")
                and source.get("summoning_sick")
            )
        ]
        for source in sources:
            produced = source.get("mana_produced", 1) if isinstance(source, dict) else 1
            colors = source_colors(source)
            # A source with multiple options is treated as flexible generic unless
            # the imported data specifies one concrete produced color.
            color = colors[0] if len(colors) == 1 else "generic"
            self.mana_pool.add(color, produced)
        emit_replay_event(
            "mana_refreshed",
            player=self.name,
            mana=self.available_mana(),
            sources=len(sources),
            mana_pool=self.mana_pool.snapshot(),
            treasures=self.treasures,
            turn=turn,
        )

    def available_mana(self):
        return self.mana_pool.total() + self.treasures

    def _payment_plan(self, cost):
        parsed = (
            cost
            if isinstance(cost, dict) and "colored" in cost
            else parse_mana_cost(cost, cost if isinstance(cost, (int, float)) else 0)
        )
        pool = self.mana_pool.snapshot()
        treasures = self.treasures

        for color, required in parsed["colored"].items():
            paid = min(pool[color], required)
            pool[color] -= paid
            missing = required - paid
            wildcard_paid = min(pool["wildcard"], missing)
            pool["wildcard"] -= wildcard_paid
            missing -= wildcard_paid
            if missing > treasures:
                return None
            treasures -= missing

        for options in parsed["hybrid"]:
            chosen = next((color for color in options if pool[color] > 0), None)
            if chosen:
                pool[chosen] -= 1
            elif pool["wildcard"] > 0:
                pool["wildcard"] -= 1
            elif treasures > 0:
                treasures -= 1
            else:
                return None

        generic = parsed["generic"]
        for color in ("generic", "colorless", "wildcard", "white", "blue", "black", "red", "green"):
            paid = min(pool[color], generic)
            pool[color] -= paid
            generic -= paid
            if generic == 0:
                break
        if generic > treasures:
            return None
        treasures -= generic
        return pool, treasures

    def can_pay(self, cost):
        return self._payment_plan(cost) is not None

    def can_pay_card(self, card, additional_generic=0):
        return self.can_pay(card_mana_cost(card, additional_generic))

    def spend_mana(self, cost):
        """Spend colored/generic mana and flexible Treasure according to a real cost."""
        plan = self._payment_plan(cost)
        if plan is None:
            return False
        pool, self.treasures = plan
        for color, amount in pool.items():
            setattr(self.mana_pool, color, amount)
        return True

    def spend_card_mana(self, card, additional_generic=0):
        return self.spend_mana(card_mana_cost(card, additional_generic))

    def is_alive(self): return self.life > 0

    def has_won(self): return self.win_reason is not None

    def untapped_creatures(self):
        return [c for c in self.battlefield if is_battlefield_creature(c)
                and not c.get("tapped", False) and (not c.get("summoning_sick", False) or has_haste(c))]

    def creatures_for_blocking(self):
        return [c for c in self.battlefield if is_battlefield_creature(c)
                and not c.get("tapped", False)]

    def has_counterspell(self):
        """Return whether a real counterspell in hand can currently be paid for."""
        return bool(self.counterspell_cards(castable_only=True))

    def counterspell_cards(self, castable_only=False):
        counters = [
            card
            for card in self.hand
            if get_card_effect(card).get("effect") == "counter"
            or card.get("effect") == "counter"
            or card.get("tag") == "counter"
        ]
        if castable_only:
            counters = [
                card for card in counters
                if self.can_pay_card(card)
            ]
        return counters

    def use_counterspell(self, turn=None, target_card=None):
        counters = self.counterspell_cards(castable_only=True)
        if not counters:
            self.counters_available = len(self.counterspell_cards())
            return None
        counter = min(counters, key=lambda card: card.get("cmc", 0))
        cost = counter.get("cmc", 0)
        if not self.spend_card_mana(counter):
            return None
        self.hand.remove(counter)
        self.graveyard.append(counter)
        self.counters_available = len(self.counterspell_cards())
        effect = get_card_effect(counter)
        draw_count = int(effect.get("draw_on_counter") or 0)
        if draw_count:
            self.draw(draw_count, random.Random(turn or 0))
        emit_replay_event(
            "spell_countered",
            player=self.name,
            counter=counter.get("name", "?"),
            target=(target_card or {}).get("name", "?"),
            cost=cost,
            cards_drawn=draw_count,
            turn=turn,
        )
        return counter

# ═══════════════════════════════════════════
# STACK (v8)
# ═══════════════════════════════════════════

class StackItem:
    def __init__(self, card, controller, effect_data):
        self.card = card
        self.controller = controller
        self.effect_data = effect_data
        self.countered = False


def is_land(card):
    """v10.2: Reliable land detection for PG-imported cards."""
    if not isinstance(card, dict):
        return card == "land" or str(card) == "land"
    if card.get("effect") == "land": return True
    if card.get("tag") == "land": return True
    if card.get("role") == "land": return True
    if "Land" in card.get("type_line", ""): return True
    name = card.get("name", "")
    if name in ("Plains","Island","Swamp","Mountain","Forest","Wastes"): return True
    if normalize_card_name(name) in KNOWN_LAND_NAMES:
        return True
    return False


def is_effective_land(card):
    """Land detection after executable rule normalization."""
    if is_land(card):
        return True
    if not isinstance(card, dict):
        return False
    try:
        return get_card_effect(card).get("effect") == "land"
    except Exception:
        return False

class Stack:
    def __init__(self): self.items = []
    def push(self, card, controller, effect_data):
        self.items.append(StackItem(card, controller, effect_data))
    def resolve_top(self):
        if self.items:
            item = self.items.pop()
            if not item.countered:
                return item
            item.controller.graveyard.append(item.card)
        return None
    def top_is_threat(self):
        """Is the top spell threatening enough for opponents to counter?"""
        if not self.items: return False
        effect = self.items[-1].effect_data.get("effect", "")
        threats = {"board_wipe", "finisher", "approach", "steal_all_creatures",
                   "overload_recursion", "pump_all", "token_maker"}
        return effect in threats
    def empty(self): return len(self.items) == 0

# ═══════════════════════════════════════════
# GAME SIMULATOR v8
# ═══════════════════════════════════════════

def play_mulligan(player, rng):
    player.shuffle(rng)
    player.hand = player.draw(7, rng)
    keep = mulligan_decision(player.hand)
    mulligan_count = 0
    while not keep[0] and mulligan_count < 3:  # v10.2 fix
        mulligan_count += 1
        player.library = player.hand + player.library
        player.hand = []
        player.shuffle(rng)
        player.hand = player.draw(7, rng)
        bottom_count = max(0, mulligan_count - 1)  # free first
        for _ in range(bottom_count):
            if player.hand:
                c = player.hand.pop(rng.randint(0, len(player.hand) - 1))
                player.library.append(c)
        keep = mulligan_decision(player.hand)
    return mulligan_count

def mulligan_decision(hand):
    lands = sum(1 for c in hand if is_land(c))  # v10.2
    return (2 <= lands <= 5), 7

def check_sbas(all_players):
    """v8: State-Based Actions after each spell resolution."""
    for p in all_players:
        if getattr(p, "failed_draw_from_empty_library", False) and not p.eliminated:
            p.life = 0
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="draw_from_empty_library")
            return True
        if p.life <= 0 and not p.eliminated:
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="life_zero")
            return True
        if p.eliminated:
            continue
        for name, dmg in p.commander_damage.items():
            if dmg >= 21:
                # Find the player who took this damage and kill them
                for op in all_players:
                    if op.name == name and not op.eliminated:
                        op.life = 0
                        op.eliminated = True
                        emit_replay_event(
                            "player_eliminated",
                            player=op.name,
                            reason="commander_damage",
                        )
                        return True
            return True
    return False



def check_sbas_until_stable(all_players):
    """v9: Loop SBAs until no more actions (CR 704.3)."""
    while check_sbas(all_players):
        pass

def game_winner(all_players):
    return next((player for player in all_players if player.has_won()), None)


def priority_round(active_player, all_players, stack, turn, rng):
    if stack.empty():
        return False

    idx = all_players.index(active_player)
    order = []
    for i in range(len(all_players)):
        order.append(all_players[(idx + i) % len(all_players)])

    # v8.2: Score the top spell
    top_item = stack.items[-1] if stack.items else None
    if not top_item:
        return False
    if top_item.countered:
        stack.resolve_top()
        return False
    score = threat_score(top_item.effect_data.get("effect", ""), top_item.card.get("name", ""),
                         top_item.controller, all_players, turn)

    for player in order:
        if not player.is_alive():
            continue
        if player != top_item.controller and (
            top_item.controller.silenced_opponents
            or top_item.controller.silenced_opponents_until_eot
        ):
            continue
        if player.is_human:
            # Lorehold: use protection in response to high-threat spells
            if score >= 40:
                instants = [c for c in player.hand if is_instant(c) and player.can_pay_card(c)]
                for c in instants:
                    eff = get_card_effect(c)
                    if eff.get("effect") in ("phase_out", "indestructible", "modal_boros_charm"):
                        if player.can_pay_card(c):
                            player.hand.remove(c)
                            player.spend_card_mana(c)
                            c["_response_to_effect"] = top_item.effect_data.get("effect")
                            apply_effect_immediate(player, [p for p in all_players if p != player], c, turn, rng)
                            return True
        else:
            # v8.2: Smart counter decision based on threat score
            if player != top_item.controller and counter_worth(score, player, rng):
                if player.use_counterspell(turn, top_item.card):
                    stack.items[-1].countered = True
                    return True

    # No one responded — resolve
    item = stack.resolve_top()
    if item:
        controller = item.controller
        opponents = [p for p in all_players if p != controller]
        apply_effect_immediate(controller, opponents, item.card, turn, rng)
        if game_winner(all_players):
            return True
        if check_sbas(all_players):
            return True
    return False

def threat_score(effect_name, card_name, controller, all_players, turn):
    """v8.2: Calculate how threatening a spell is (0-100).
    Opponents use this to decide if they should respond."""
    score = 0

    # ── INSTANT WIN ──
    if effect_name == "approach":
        if controller.approach_count >= 1:
            return 100  # MUST counter (2nd cast = instant win)
        return 85  # v10.2: was 70 — higher counter priority

    # ── MASSIVE BOARD IMPACT ──
    if effect_name == "board_wipe":
        # Higher threat if caster has protection (asymmetric wipe)
        if controller.indestructible or controller.protection_from_everything:
            return 85
        # Higher threat if opponents have more creatures than caster
        caster_creatures = len(controller.untapped_creatures())
        opp_creatures = sum(len(o.untapped_creatures()) for o in all_players if o != controller and o.is_alive())
        if opp_creatures > caster_creatures * 2:
            return 75  # devastating for opponents
        return 45  # symmetric, fair

    if effect_name == "steal_all_creatures":
        total_stolen = sum(len([c for c in o.battlefield if is_battlefield_creature(c)])
                          for o in all_players if o != controller and o.is_alive())
        if total_stolen > 10:
            return 90
        return 65

    # ── WINCON SETUP ──
    if effect_name == "pump_all":
        creatures = [c for c in controller.battlefield if is_battlefield_creature(c)]
        total_power = sum(c.get("power", 2) for c in creatures)
        if total_power > 30:
            return 70  # lethal pump
        if total_power > 15:
            return 50
        return 30

    if effect_name == "token_maker":
        # How many tokens? If Storm Herd (life_total/2), it's a lot
        if controller.life > 30:
            return 60  # Storm Herd = 15+ tokens
        return 35

    if effect_name == "overload_recursion":
        spells_in_grave = sum(1 for c in controller.graveyard if isinstance(c, dict) and c.get("cmc", 0) > 0)
        if spells_in_grave > 10:
            return 80
        if spells_in_grave > 5:
            return 50
        return 30

    # ── REMOVAL ──
    if effect_name in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg"):
        # Counter-worthy only if it targets a key piece
        for opp in all_players:
            if opp == controller: continue
            if opp.is_alive():
                key_creatures = [c for c in opp.battlefield if isinstance(c, dict) and (
                    c.get("is_commander") or c.get("power", 0) > 5)]
                if key_creatures:
                    return 40  # targeting a key creature
        return 15  # minor removal

    # ── RAMP / DRAW ──
    if effect_name in ("ramp_permanent", "ramp_engine", "ramp_ritual"):
        mana_produced = 1 if effect_name == "ramp_permanent" else 3
        if turn <= 3:
            return 20  # early ramp is worth countering
        return 5  # late ramp, not worth

    if effect_name == "draw_engine":
        return controller.approach_count > 0 and 50 or 25  # higher threat if Approach was cast

    if effect_name == "draw_cards":
        count = 2
        if controller.approach_count > 0 and count >= 2:
            return 45  # digging for Approach
        return 15

    if effect_name == "tutor":
        if controller.approach_count > 0:
            return 55  # tutoring for Approach
        return 25

    if effect_name == "extra_turn":
        return 65

    # ── PROTECTION ──
    if effect_name in ("phase_out", "indestructible"):
        # Cast in response to a wipe on the stack? High value
        return 30  # protection itself isn't threatening, but enables threats

    if effect_name == "finisher":
        return 60  # generic finisher, always dangerous

    if effect_name in ("silence_opponents", "silence_spell"):
        if controller.approach_count > 0:
            return 80  # silencing before Approach = can't counter
        return 50

    return 15  # default: minor threat

def counter_worth(threat_score, opp, rng):
    """v8.2: Should this opponent spend a counterspell on this threat?
    Returns True/False based on threat score and opponent's resources."""
    if not opp.has_counterspell():
        return False

    # Critical: Approach 2nd cast or lethal — always counter
    if threat_score >= 90:
        return True

    # High threat — counter if we have enough counterspells
    if threat_score >= 70:
        return rng.random() < 0.85

    # Medium threat — counter if we're not the target or have spare
    if threat_score >= 40:
        return rng.random() < 0.5

    # Low threat — only counter if we have many to spare
    if threat_score >= 20:
        return rng.random() < 0.2

    return False


def remember_until_eot(card, key):
    originals = card.setdefault("_until_eot_originals", {})
    if key not in originals:
        originals[key] = card.get(key, None)


def set_until_eot(card, key, value):
    remember_until_eot(card, key)
    card[key] = value


def clear_until_eot(player):
    """Restore temporary combat keywords/stat changes at cleanup."""
    zones = (player.battlefield, player.phased_out)
    for zone in zones:
        for card in zone:
            if not isinstance(card, dict):
                continue
            originals = card.pop("_until_eot_originals", {})
            for key, original in originals.items():
                if original is None:
                    card.pop(key, None)
                else:
                    card[key] = original
            card.pop("_landfall_triggers_this_turn", None)
    player.indestructible = False
    player.silenced_opponents_until_eot = False


def grant_creatures_until_eot(player, *, keywords=(), power_multiplier=None):
    creatures = [
        card
        for card in player.battlefield
        if is_battlefield_creature(card)
    ]
    for creature in creatures:
        for keyword in keywords:
            if keyword == "protection_all":
                continue
            set_until_eot(creature, keyword, True)
        if power_multiplier:
            remember_until_eot(creature, "power")
            try:
                base_power = int(float(creature.get("power", 2)))
            except (TypeError, ValueError):
                base_power = 2
            creature["power"] = base_power * power_multiplier
    return len(creatures)


def change_life(player, delta):
    if delta and (player.life_cant_change or player.protection_from_everything):
        return False
    player.life += delta
    return True


def deal_damage(player, amount):
    if amount <= 0:
        return False
    return change_life(player, -amount)


def gain_life(player, amount, cap=40):
    if amount <= 0 or player.life_cant_change or player.protection_from_everything:
        return False
    player.life = min(cap, player.life + amount)
    return True


def move_creature_from_battlefield(owner, creature):
    """Move a dead/sacrificed creature to the correct zone for this simulator."""
    if not isinstance(creature, dict):
        return "none"
    if creature in owner.battlefield:
        owner.battlefield.remove(creature)
    if creature.get("is_commander"):
        # v9: Commander replacement (CR 903.9a) — owner MAY move to CZ
        if owner.is_human:
            owner.command_zone.append(creature)
            return "command_zone"
        else:
            import random as _cr
            if _cr.random() < 0.7:
                owner.command_zone.append(creature)
                return "command_zone"
    if creature.get("tag") == "token" or "token" in str(creature.get("type_line") or "").lower():
        return "vanished_token"
    owner.graveyard.append(creature)
    return "graveyard"


def is_artifact_permanent(card):
    if not isinstance(card, dict):
        return False
    type_line = str(card.get("type_line") or "").lower()
    return "artifact" in type_line or card.get("effect") in (
        "equipment_haste_shroud",
        "hate_artifact",
        "life_artifact",
        "ramp_permanent",
        "topdeck_manipulation",
    )


def is_enchantment_permanent(card):
    return isinstance(card, dict) and "enchantment" in str(card.get("type_line") or "").lower()


def is_colored_permanent(card):
    if not isinstance(card, dict):
        return False
    colors = card.get("colors") or card.get("color_identity") or []
    if isinstance(colors, str):
        colors = read_json_list(colors) or [colors]
    if colors:
        return any(str(color).upper() in {"W", "U", "B", "R", "G"} for color in colors)
    return bool(re.search(r"\{[WUBRG]\}", str(card.get("mana_cost") or "")))


def removal_target_candidates(player, effect_data=None):
    effect_data = effect_data or {"effect": "remove_creature"}
    effect = effect_data.get("effect")
    target_type = str(effect_data.get("target") or "").lower()
    if not target_type:
        target_type = "creature" if effect == "remove_creature" else "nonland_permanent"

    candidates = []
    for card in player.battlefield:
        if not isinstance(card, dict):
            continue
        if card.get("shroud") or card.get("protection_from_everything"):
            continue
        if target_type in ("creature", "target_creature") and not is_battlefield_creature(card):
            continue
        if target_type in ("artifact", "artifact_permanent") and not is_artifact_permanent(card):
            continue
        if target_type in ("enchantment", "enchantment_permanent") and not is_enchantment_permanent(card):
            continue
        if target_type in ("artifact_or_enchantment", "artifact_enchantment") and not (
            is_artifact_permanent(card) or is_enchantment_permanent(card)
        ):
            continue
        if target_type == "colored_permanent" and not is_colored_permanent(card):
            continue
        if target_type in ("nonland_permanent", "permanent", "any") and is_effective_land(card):
            continue
        candidates.append(card)
    return candidates


def choose_best_creature_target(creatures):
    def target_priority(target):
        effect = get_card_effect(target).get("effect") or target.get("effect")
        engine_priority = {
            "commander": 10,
            "combo": 9,
            "finisher": 8,
            "draw_engine": 7,
            "silence_opponents": 7,
            "ramp_engine": 6,
            "copy_spell": 6,
            "ripple_engine": 6,
            "hate_artifact": 5,
            "creature": 1,
        }.get(effect, 0)
        return (
            bool(target.get("is_commander")),
            engine_priority,
            int(target.get("cmc") or 0),
            int(target.get("power") or 0),
            int(target.get("toughness") or 0),
        )

    return max(
        creatures,
        key=target_priority,
    )


def pay_additional_card_costs(player, card, effect_data, *, turn=None):
    """Pay non-mana costs that materially affect battlefield validity."""
    if (
        not effect_data.get("requires_discard_card")
        and not effect_data.get("requires_discard_land")
        and not effect_data.get("requires_sacrifice_creature")
    ):
        return True
    if effect_data.get("requires_discard_card"):
        discard_any = next(
            (
                candidate
                for candidate in player.hand
                if isinstance(candidate, dict)
                and not candidate.get("is_commander")
            ),
            None,
        )
        if not discard_any:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="discard_card",
                turn=turn,
            )
            return False
        player.hand.remove(discard_any)
        player.graveyard.append(discard_any)
        emit_replay_event(
            "additional_cost_paid",
            player=player.name,
            card=card.get("name", "?"),
            cost="discard_card",
            discarded=discard_any.get("name", "?"),
            turn=turn,
        )
    discard = next((candidate for candidate in player.hand if is_land(candidate)), None)
    if effect_data.get("requires_discard_land"):
        if not discard:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="discard_land",
                turn=turn,
            )
            return False
        player.hand.remove(discard)
        player.graveyard.append(discard)
        emit_replay_event(
            "additional_cost_paid",
            player=player.name,
            card=card.get("name", "?"),
            cost="discard_land",
            discarded=discard.get("name", "?"),
            turn=turn,
        )
    if effect_data.get("requires_sacrifice_creature"):
        sacrifice = next(
            (
                permanent
                for permanent in player.battlefield
                if is_battlefield_creature(permanent)
                and not permanent.get("is_commander")
            ),
            None,
        )
        sacrifice = sacrifice or next(
            (
                permanent
                for permanent in player.battlefield
                if is_battlefield_creature(permanent)
            ),
            None,
        )
        if not sacrifice:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="sacrifice_creature",
                turn=turn,
            )
            return False
        destination = move_creature_from_battlefield(player, sacrifice)
        emit_replay_event(
            "additional_cost_paid",
            player=player.name,
            card=card.get("name", "?"),
            cost="sacrifice_creature",
            sacrificed=sacrifice.get("name", "?"),
            destination=destination,
            turn=turn,
        )
    return True


def ritual_mana_produced(player, effect_data):
    threshold_count = effect_data.get("threshold_graveyard_count")
    threshold_mana = effect_data.get("threshold_mana_produced")
    if threshold_count and threshold_mana and len(player.graveyard) >= int(threshold_count):
        return int(threshold_mana)
    return int(effect_data.get("mana_produced", 3))


def controlled_land_count(player):
    return sum(1 for permanent in player.battlefield if isinstance(permanent, dict) and is_effective_land(permanent))


def create_creature_token(
    player,
    *,
    name="Token",
    power=2,
    toughness=None,
    haste=False,
    flying=False,
    artifact=False,
):
    token = {
        "name": name,
        "cmc": 0,
        "tag": "token",
        "effect": "creature",
        "type_line": "Artifact Creature Token" if artifact else "Creature Token",
        "power": power,
        "toughness": toughness if toughness is not None else power,
        "haste": bool(haste),
        "summoning_sick": not bool(haste),
        "tapped": False,
    }
    if flying:
        token["flying"] = True
        token["keywords"] = ["flying"]
    player.battlefield.append(token)

    if artifact:
        replacement_engines = [
            permanent
            for permanent in player.battlefield
            if isinstance(permanent, dict) and permanent.get("artifact_token_replacement")
        ]
        for _ in replacement_engines:
            player.battlefield.append(
                {
                    "name": "Thopter Token",
                    "cmc": 0,
                    "tag": "token",
                    "effect": "creature",
                    "type_line": "Artifact Creature Token — Thopter",
                    "power": 1,
                    "toughness": 1,
                    "flying": True,
                    "keywords": ["flying"],
                    "summoning_sick": True,
                    "tapped": False,
                }
            )
    return token


def prepare_entering_permanent(permanent):
    """Apply shared creature-entry state for permanents with engine effects."""
    if not isinstance(permanent, dict):
        return permanent
    if is_battlefield_creature(permanent):
        permanent["haste"] = has_haste(permanent)
        permanent["summoning_sick"] = not permanent["haste"]
        permanent["tapped"] = False
        try:
            permanent["power"] = int(permanent.get("power") or 1)
        except (TypeError, ValueError):
            permanent["power"] = 1
        try:
            permanent["toughness"] = int(permanent.get("toughness") or permanent["power"] or 1)
        except (TypeError, ValueError):
            permanent["toughness"] = permanent["power"] or 1
    return permanent


def trigger_landfall(player, land_permanent, turn, source_event, opponents=None):
    created = []
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict) or not permanent.get("landfall_token_maker"):
            continue
        created.append(
            create_creature_token(
                player,
                name="Insect Token",
                power=int(permanent.get("token_power") or 1),
                toughness=int(permanent.get("token_toughness") or 1),
            )
        )
    if created:
        emit_replay_event(
            "trigger_resolved",
            player=player.name,
            card="; ".join(
                sorted(
                    {
                        permanent.get("name", "?")
                        for permanent in player.battlefield
                        if isinstance(permanent, dict) and permanent.get("landfall_token_maker")
                    }
                )
            ),
            trigger="landfall",
            trigger_land=land_permanent.get("name", "?") if isinstance(land_permanent, dict) else "Land",
            source_event=source_event,
            effect="token_maker",
            tokens_created=len(created),
            turn=turn,
        )
    opponents = opponents or []
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict) or not permanent.get("landfall_damage_each_opponent"):
            continue
        count = int(permanent.get("_landfall_triggers_this_turn") or 0) + 1
        permanent["_landfall_triggers_this_turn"] = count
        amount = int(permanent.get("landfall_damage_each_opponent") or 1)
        damaged = []
        for opponent in opponents:
            if opponent.is_alive() and deal_damage(opponent, amount):
                damaged.append({"player": opponent.name, "life_after": opponent.life})
        drew = False
        if permanent.get("landfall_second_draw") and count == 2:
            player.draw(1, random.Random(turn + count))
            drew = True
        emit_replay_event(
            "trigger_resolved",
            player=player.name,
            card=permanent.get("name", "?"),
            trigger="landfall",
            trigger_land=land_permanent.get("name", "?") if isinstance(land_permanent, dict) else "Land",
            source_event=source_event,
            effect="damage_each_opponent",
            amount=amount,
            damaged=damaged,
            draw_card=drew,
            trigger_count_this_turn=count,
            turn=turn,
            **replay_rule_fields(permanent),
        )


def sacrifice_land_for_effect(player, card, turn, *, required=True):
    land = next(
        (candidate for candidate in player.battlefield if isinstance(candidate, dict) and is_effective_land(candidate)),
        None,
    )
    if not land:
        if required:
            emit_replay_event(
                "additional_cost_failed",
                player=player.name,
                card=card.get("name", "?"),
                cost="sacrifice_land",
                turn=turn,
            )
        return None
    player.battlefield.remove(land)
    player.graveyard.append(land)
    emit_replay_event(
        "additional_cost_paid",
        player=player.name,
        card=card.get("name", "?"),
        cost="sacrifice_land",
        sacrificed=land.get("name", "?"),
        turn=turn,
    )
    return land


def put_lands_from_library(player, card, effect_data, turn, *, opponents=None, source_event="land_ramp"):
    count = int(effect_data.get("land_count") or effect_data.get("lands_to_battlefield") or 1)
    if effect_data.get("requires_sacrifice_land") and not sacrifice_land_for_effect(player, card, turn, required=True):
        return []
    found = []
    for candidate in list(player.library):
        if len(found) >= count:
            break
        if not isinstance(candidate, dict) or not is_effective_land(candidate):
            continue
        if effect_data.get("basic_only") and "basic" not in str(candidate.get("type_line") or "").lower():
            continue
        player.library.remove(candidate)
        land = enrich_card({**candidate, "effect": "land", "tapped": True})
        player.battlefield.append(land)
        trigger_landfall(player, land, turn, source_event, opponents=opponents)
        found.append(land)
    emit_replay_event(
        "land_ramp_resolved",
        player=player.name,
        card=card.get("name", "?"),
        found=[land.get("name", "?") for land in found],
        count=len(found),
        turn=turn,
    )
    return found


def return_graveyard_lands_to_battlefield(player, card, turn, *, opponents=None, source_event="land_recursion"):
    returned = []
    for grave_card in list(player.graveyard):
        if isinstance(grave_card, dict) and is_effective_land(grave_card):
            player.graveyard.remove(grave_card)
            land = enrich_card({**grave_card, "effect": "land", "tapped": True})
            player.battlefield.append(land)
            trigger_landfall(player, land, turn, source_event, opponents=opponents)
            returned.append(land)
    emit_replay_event(
        "land_recursion_resolved",
        player=player.name,
        card=card.get("name", "?"),
        lands_returned=[land.get("name", "?") for land in returned],
        count=len(returned),
        turn=turn,
    )
    return returned


def trigger_opponent_land_play_engines(active_player, opponents, land_permanent, turn):
    for opponent in opponents:
        if not opponent.is_alive():
            continue
        engines = [
            permanent
            for permanent in opponent.battlefield
            if isinstance(permanent, dict)
            and permanent.get("effect") == "ramp_engine"
            and permanent.get("trigger") == "opponent_land_play"
        ]
        if not engines:
            continue
        land_from_hand = next((card for card in opponent.hand if is_effective_land(card)), None)
        if not land_from_hand:
            continue
        opponent.hand.remove(land_from_hand)
        extra_land = enrich_card({**land_from_hand, "effect": "land"})
        opponent.battlefield.append(extra_land)
        trigger_landfall(opponent, extra_land, turn, "opponent_land_play")
        emit_replay_event(
            "trigger_resolved",
            player=opponent.name,
            card=engines[0].get("name", "?"),
            trigger="opponent_land_play",
            active_player=active_player.name,
            trigger_land=land_permanent.get("name", "?") if isinstance(land_permanent, dict) else "Land",
            effect="land",
            put_land=extra_land.get("name", "?"),
            turn=turn,
        )


def activate_land_tutor_creatures(player, turn):
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict) or not permanent.get("land_tutor_activated"):
            continue
        if permanent.get("tapped") or permanent.get("summoning_sick"):
            continue
        if player.available_mana() < 2 or controlled_land_count(player) <= 1:
            continue
        land_to_sacrifice = next(
            (land for land in player.battlefield if isinstance(land, dict) and is_effective_land(land)),
            None,
        )
        land_to_find = next(
            (candidate for candidate in player.library if isinstance(candidate, dict) and is_effective_land(candidate)),
            None,
        )
        if not land_to_sacrifice or not land_to_find:
            continue
        player.spend_mana(2)
        permanent["tapped"] = True
        player.battlefield.remove(land_to_sacrifice)
        player.graveyard.append(land_to_sacrifice)
        player.library.remove(land_to_find)
        found_land = enrich_card({**land_to_find, "effect": "land", "tapped": True})
        player.battlefield.append(found_land)
        trigger_landfall(player, found_land, turn, "land_tutor_activated")
        emit_replay_event(
            "activated_ability",
            player=player.name,
            card=permanent.get("name", "?"),
            effect="land_tutor",
            sacrificed=land_to_sacrifice.get("name", "?"),
            found=found_land.get("name", "?"),
            turn=turn,
        )
        return


def resolve_land_recursion_creature(player, card, effect_data, turn):
    permanent = enrich_card({**card, **effect_data})
    permanent["effect"] = "creature"
    permanent["haste"] = has_haste(permanent)
    permanent["summoning_sick"] = not permanent["haste"]
    permanent["tapped"] = False
    if effect_data.get("power_equals_lands") or effect_data.get("toughness_equals_lands"):
        lands = max(1, controlled_land_count(player))
        if effect_data.get("power_equals_lands"):
            permanent["power"] = lands
        if effect_data.get("toughness_equals_lands"):
            permanent["toughness"] = lands
    player.battlefield.append(permanent)

    milled = []
    for _ in range(int(effect_data.get("mill_count") or 0)):
        if not player.library:
            break
        milled_card = player.library.pop(0)
        player.graveyard.append(milled_card)
        milled.append(milled_card)

    returned = []
    for grave_card in list(player.graveyard):
        if isinstance(grave_card, dict) and is_effective_land(grave_card):
            player.graveyard.remove(grave_card)
            returned_land = enrich_card(grave_card)
            returned_land["effect"] = "land"
            returned_land["tapped"] = True
            player.battlefield.append(returned_land)
            trigger_landfall(player, returned_land, turn, "land_recursion")
            returned.append(returned_land)

    if effect_data.get("power_equals_lands") or effect_data.get("toughness_equals_lands"):
        lands_after = max(1, controlled_land_count(player))
        if effect_data.get("power_equals_lands"):
            permanent["power"] = lands_after
        if effect_data.get("toughness_equals_lands"):
            permanent["toughness"] = lands_after

    emit_replay_event(
        "land_recursion_creature_resolved",
        player=player.name,
        card=card.get("name", "?"),
        milled=[milled_card.get("name", "?") for milled_card in milled if isinstance(milled_card, dict)],
        lands_returned=[returned_land.get("name", "?") for returned_land in returned],
        power=permanent.get("power"),
        toughness=permanent.get("toughness"),
        turn=turn,
    )


def apply_equipment_haste_shroud(player, card, effect_data, turn):
    equipment = enrich_card({**card, **effect_data})
    equipment["effect"] = "equipment_haste_shroud"
    player.battlefield.append(equipment)
    creatures = [
        permanent
        for permanent in player.battlefield
        if is_battlefield_creature(permanent)
    ]
    if not creatures:
        emit_replay_event(
            "equipment_unattached",
            player=player.name,
            card=card.get("name", "?"),
            turn=turn,
        )
        return
    target = choose_best_creature_target(creatures)
    target["haste"] = True
    target["summoning_sick"] = False
    target["shroud"] = True
    emit_replay_event(
        "equipment_attached",
        player=player.name,
        card=card.get("name", "?"),
        target=target.get("name", "?"),
        grants=["haste", "shroud"],
        turn=turn,
    )


def apply_direct_damage(player, opponents, card, effect_data, turn, rng):
    raw_amount = effect_data.get("amount") or effect_data.get("damage") or 3
    if raw_amount == "x_available":
        amount = max(1, int(card.get("cmc") or 0), player.available_mana())
    else:
        amount = int(raw_amount)
    for opp in opponents:
        targets = [
            target
            for target in removal_target_candidates(opp)
            if int(target.get("toughness") or target.get("power") or 2) <= amount
        ]
        if targets:
            target = choose_best_creature_target(targets)
            destination = move_creature_from_battlefield(opp, target)
            emit_replay_event(
                "damage_resolved",
                player=player.name,
                card=card.get("name", "?"),
                amount=amount,
                target_player=opp.name,
                target=target.get("name", "?"),
                result="creature_destroyed",
                destination=destination,
                turn=turn,
            )
            player.graveyard.append(card)
            return
    alive_opponents = [opp for opp in opponents if opp.is_alive()]
    if alive_opponents:
        target_player = min(alive_opponents, key=lambda opp: opp.life)
        dealt = deal_damage(target_player, amount)
        emit_replay_event(
            "damage_resolved",
            player=player.name,
            card=card.get("name", "?"),
            amount=amount,
            target_player=target_player.name,
            result="player_damage" if dealt else "prevented",
            life_after=target_player.life,
            turn=turn,
        )
    player.graveyard.append(card)


def trigger_spell_cast_engines(player, all_players, spell, turn, phase):
    if not (is_instant(spell) or is_sorcery(spell)):
        return
    for permanent in list(player.battlefield):
        if not isinstance(permanent, dict):
            continue
        if permanent.get("trigger") != "instant_sorcery_cast":
            continue
        if permanent.get("trigger_effect") != "damage_each_opponent":
            continue
        amount = int(permanent.get("damage") or 2)
        damaged = []
        for opponent in all_players:
            if opponent == player or not opponent.is_alive():
                continue
            if deal_damage(opponent, amount):
                damaged.append({"player": opponent.name, "life_after": opponent.life})
        emit_replay_event(
            "trigger_resolved",
            player=player.name,
            card=permanent.get("name", "?"),
            trigger="instant_sorcery_cast",
            trigger_spell=spell.get("name", "?"),
            effect="damage_each_opponent",
            amount=amount,
            damaged=damaged,
            turn=turn,
            phase=phase,
            **replay_rule_fields(permanent),
        )


def trigger_opponent_spell_draw_engines(caster, opponents, spell, turn, phase, rng):
    spell_effect = get_card_effect(spell).get("effect")
    is_noncreature_spell = spell_effect != "creature"
    for opponent in opponents:
        for permanent in list(opponent.battlefield):
            if not isinstance(permanent, dict):
                continue
            if permanent.get("effect") != "draw_engine":
                continue
            trigger = permanent.get("trigger")
            if trigger not in ("opponent_spell", "opponent_noncreature_spell"):
                continue
            if trigger == "opponent_noncreature_spell" and not is_noncreature_spell:
                continue
            tax = int(permanent.get("tax") or 1)
            # Compact model: caster sometimes pays the tax when spare mana exists.
            can_pay_tax = caster.available_mana() >= tax
            pays_tax = can_pay_tax and rng.random() < 0.35
            if pays_tax:
                caster.spend_mana(tax)
                result = "tax_paid"
            else:
                opponent.draw(1, rng)
                result = "card_drawn"
            emit_replay_event(
                "trigger_resolved",
                player=opponent.name,
                card=permanent.get("name", "?"),
                trigger=trigger,
                trigger_spell=spell.get("name", "?"),
                effect="draw_cards",
                result=result,
                turn=turn,
                phase=phase,
                **replay_rule_fields(permanent),
            )


def cast_spells_v8(player, opponents, all_players, turn, phase, stack, rng):
    """v8: Cast spells respecting instant/sorcery timing and stack."""
    mana = player.available_mana()
    if mana <= 0:
        return

    is_own_turn = (player == all_players[0]) or (turn > 0)
    is_main_phase = phase in ("precombat_main", "postcombat_main")

    # Track counters available (count counterspells in hand)
    player.counters_available = sum(1 for c in player.hand
                                    if c.get("effect") == "counter" or c.get("tag") == "counter")

    # 1. Cast commander from command zone (main phase only)
    if is_main_phase and player.command_zone:
        cmd = player.command_zone[0]
        cost = cmd["cmc"] + player.commander_tax
        if player.can_pay_card(cmd, player.commander_tax):
            already_there = any(isinstance(c, dict) and c.get("name") == cmd.get("name") for c in player.battlefield)
            if not already_there:
                player.command_zone.pop(0)
                cmd_copy = enrich_card(cmd)
                cmd_eff = get_card_effect(cmd)
                haste = has_haste(cmd_copy)
                if is_creature_card(cmd_copy):
                    default_stat = max(2, int(float(cmd_copy.get("cmc") or cost or 2)))
                    cmd_copy["effect"] = "creature"
                    cmd_copy["power"] = cmd_copy.get("power") or default_stat
                    cmd_copy["toughness"] = cmd_copy.get("toughness") or cmd_copy.get("power") or default_stat
                cmd_copy["summoning_sick"] = not haste
                cmd_copy["haste"] = haste
                if cmd_eff.get("effect") != "land_recursion_creature":
                    player.battlefield.append(cmd_copy)
                player.spend_card_mana(cmd, player.commander_tax)
                player.commander_tax += 2
                emit_replay_event(
                    "commander_cast",
                    player=player.name,
                    card=cmd.get("name", "?"),
                    effect=cmd_eff.get("effect", "unknown"),
                    type_line=cmd_copy.get("type_line", ""),
                    cost=cost,
                    turn=turn,
                    phase=phase,
                    **replay_rule_fields(cmd_eff),
                )
                if cmd_eff.get("effect") == "land_recursion_creature":
                    resolve_land_recursion_creature(player, cmd_copy, cmd_eff, turn)
                mana = player.available_mana()

    # 2. Ramp (main phase only)
    if is_main_phase:
        ramp_cards = [
            c for c in player.hand
            if player.can_pay_card(c)
            and get_card_effect(c).get("effect") in (
                "land_ramp",
                "land_recursion",
                "ramp_permanent",
                "ramp_engine",
                "ramp_ritual",
            )
        ]
        for c in ramp_cards[:2]:
            if c in player.hand and player.can_pay_card(c):
                player.hand.remove(c)
                player.spend_card_mana(c)
                eff = get_card_effect(c)
                emit_replay_event(
                    "spell_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=c.get("type_line", ""),
                    cmc=c.get("cmc", 0),
                    turn=turn,
                    phase=phase,
                    role="ramp",
                    **replay_rule_fields(eff),
                )
                if not pay_additional_card_costs(player, c, eff, turn=turn):
                    player.graveyard.append(c)
                    continue
                trigger_spell_cast_engines(player, all_players, c, turn, phase)
                trigger_opponent_spell_draw_engines(player, opponents, c, turn, phase, rng)
                if eff.get("effect") == "ramp_ritual":
                    player.mana_pool.add_generic(ritual_mana_produced(player, eff))
                    player.graveyard.append(c)
                elif eff.get("effect") == "land_ramp":
                    put_lands_from_library(player, c, eff, turn, opponents=opponents, source_event="land_ramp")
                    player.graveyard.append(c)
                elif eff.get("effect") == "land_recursion":
                    return_graveyard_lands_to_battlefield(player, c, turn, opponents=opponents)
                    player.graveyard.append(c)
                else:
                    permanent = prepare_entering_permanent(enrich_card({**c, **eff}))
                    player.battlefield.append(permanent)
                    if is_mana_source_permanent(permanent):
                        colors = source_colors(permanent)
                        player.mana_pool.add(colors[0], permanent.get("mana_produced", 1))
                mana = player.available_mana()

    # 3. Cast spells to stack
    castable = [
        c for c in player.hand
        if not is_effective_land(c)
        and player.can_pay_card(c)
        and get_card_effect(c).get("effect") not in ("counter", "unknown")
    ]
    # v8: Miracle check for Lorehold
    if player.is_human:
        lorehold_on_board = any(isinstance(c, dict) and c.get("name") == "Lorehold, the Historian" for c in player.battlefield)
        for c in castable[:]:
            if (is_sorcery(c) or is_instant(c)) and not is_main_phase:
                if not is_instant(c) or not lorehold_on_board:
                    castable.remove(c)  # can't cast sorcery outside main phase

    # Play spells in priority order
    # v8.2: Play spells needing priority in score order
    # Wincons / high-threat spells first (main phase only)
    if is_main_phase:
        # Sort by threat score (highest first — resolve big plays before small ones)
        scored = [(c, threat_score(get_card_effect(c).get("effect", ""), c.get("name", ""), player, all_players, turn)) for c in castable]
        scored.sort(key=lambda x: -x[1])
        
        wincons = [c for c, s in scored if s >= 50]
        if wincons:
            c = wincons[0]
            if c in player.hand and player.can_pay_card(c):
                player.hand.remove(c)
                player.spend_card_mana(c)
                eff = get_card_effect(c)
                emit_replay_event(
                    "spell_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=c.get("type_line", ""),
                    cmc=c.get("cmc", 0),
                    threat_score=scored[0][1],
                    turn=turn,
                    phase=phase,
                    role="high_threat",
                    **replay_rule_fields(eff),
                )
                trigger_spell_cast_engines(player, all_players, c, turn, phase)
                trigger_opponent_spell_draw_engines(player, opponents, c, turn, phase, rng)
                stack.push(c, player, eff)
                priority_round(player, all_players, stack, turn, rng)
                if game_winner(all_players):
                    return
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)
                    if game_winner(all_players):
                        return
                return

    # Other spells: 2 per phase max
    remaining = sorted([c for c in castable if player.can_pay_card(c)], key=lambda c: c["cmc"])
    played = 0
    for c in remaining:
        if played >= 2: break
        if c in player.hand and player.can_pay_card(c):
            eff = get_card_effect(c)
            if eff.get("effect") == "creature":
                if not is_main_phase: continue  # creatures only in main phase
                player.hand.remove(c)
                player.spend_card_mana(c)
                c_copy = enrich_card({**c, **eff})
                c_copy["effect"] = "creature"
                c_copy["haste"] = has_haste(c_copy)
                c_copy["summoning_sick"] = not c_copy["haste"]
                c_copy["tapped"] = False
                player.battlefield.append(c_copy)
                emit_replay_event(
                    "creature_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    cmc=c.get("cmc", 0),
                    type_line=c_copy.get("type_line", ""),
                    power=c_copy.get("power"),
                    toughness=c_copy.get("toughness"),
                    effect=eff.get("effect", "creature"),
                    turn=turn,
                    phase=phase,
                    **replay_rule_fields(eff),
                )
                if eff.get("etb_land_ramp_count"):
                    etb_eff = {
                        **eff,
                        "land_count": int(eff.get("etb_land_ramp_count") or 1),
                        "requires_sacrifice_land": bool(eff.get("etb_requires_sacrifice_land")),
                    }
                    put_lands_from_library(
                        player,
                        c_copy,
                        etb_eff,
                        turn,
                        opponents=opponents,
                        source_event="etb_land_ramp",
                    )
                if eff.get("etb_draw_count"):
                    player.draw(int(eff.get("etb_draw_count") or 1), rng)
                if eff.get("etb_token_count"):
                    for _ in range(min(int(eff.get("etb_token_count") or 1), 20)):
                        create_creature_token(
                            player,
                            name=eff.get("etb_token_name", "Token"),
                            power=int(eff.get("etb_token_power") or 1),
                            toughness=int(eff.get("etb_token_toughness") or eff.get("etb_token_power") or 1),
                            artifact=bool(eff.get("etb_artifact_tokens")),
                        )
                if eff.get("etb_recursion_count"):
                    target_type = eff.get("etb_recursion_target")
                    destination = eff.get("etb_recursion_destination", "hand")
                    candidates = [
                        grave_card
                        for grave_card in player.graveyard
                        if isinstance(grave_card, dict)
                        and not is_land(grave_card)
                        and (
                            target_type != "creature"
                            or is_creature_card(grave_card)
                        )
                        and (
                            target_type == "creature"
                            or target_type != "instant_or_sorcery"
                            or is_instant_or_sorcery_spell(grave_card)
                        )
                    ]
                    for recovered_card in candidates[: int(eff.get("etb_recursion_count") or 1)]:
                        if recovered_card in player.graveyard:
                            player.graveyard.remove(recovered_card)
                            if destination == "battlefield":
                                permanent_effect = get_card_effect(recovered_card)
                                permanent = enrich_card({**recovered_card, **permanent_effect})
                                if is_creature_card(recovered_card):
                                    permanent["effect"] = "creature"
                                    permanent["haste"] = has_haste(permanent)
                                    permanent["summoning_sick"] = not permanent["haste"]
                                    permanent["tapped"] = False
                                player.battlefield.append(permanent)
                            else:
                                player.hand.append(recovered_card)
                played += 1
            else:
                player.hand.remove(c)
                player.spend_card_mana(c)
                emit_replay_event(
                    "spell_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=c.get("type_line", ""),
                    cmc=c.get("cmc", 0),
                    turn=turn,
                    phase=phase,
                    role="normal",
                    **replay_rule_fields(eff),
                )
                trigger_spell_cast_engines(player, all_players, c, turn, phase)
                trigger_opponent_spell_draw_engines(player, opponents, c, turn, phase, rng)
                stack.push(c, player, eff)
                played += 1

# Resolve stack
    while not stack.empty():
        priority_round(player, all_players, stack, turn, rng)
        if game_winner(all_players):
            return

def apply_effect_immediate(player, opponents, card, turn, rng):
    """v8: Apply card effect (called when spell resolves from stack)."""
    effect_data = get_card_effect(card)
    effect = effect_data.get("effect", "unknown")
    emit_replay_event(
        "spell_resolved",
        player=player.name,
        card=card.get("name", "?"),
        cmc=card.get("cmc", 0),
        type_line=card.get("type_line", ""),
        effect=effect,
        turn=turn,
        **replay_rule_fields(effect_data),
    )

    if effect == "land": pass
    elif effect == "passive":
        if is_instant(card) or is_sorcery(card):
            player.graveyard.append(card)
        else:
            permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
            permanent["effect"] = "passive"
            player.battlefield.append(permanent)
    elif effect == "ramp_permanent":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            player.graveyard.append(card)
            return
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        player.battlefield.append(permanent)
    elif effect == "ramp_ritual":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            player.graveyard.append(card)
            return
        player.mana_pool.add_generic(ritual_mana_produced(player, effect_data))
        player.graveyard.append(card)
    elif effect == "ramp_engine":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "ramp_engine"
        player.battlefield.append(permanent)
        treasure_count = int(effect_data.get("enters_treasure") or 0)
        player.treasures += treasure_count
    elif effect == "draw_engine":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "draw_engine"
        player.battlefield.append(permanent)
        player.draw_engines += 1
        player.draw(1, rng)
    elif effect == "land_recursion_creature":
        resolve_land_recursion_creature(player, card, effect_data, turn)
    elif effect == "draw_cards":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            player.graveyard.append(card)
            return
        n = effect_data.get("count", 2)
        player.draw(n, rng)
        player.graveyard.append(card)
    elif effect == "treasure_maker":
        if not pay_additional_card_costs(player, card, effect_data, turn=turn):
            player.graveyard.append(card)
            return
        treasure_count = int(effect_data.get("treasure_count") or 1)
        player.treasures += treasure_count
        draw_count = int(effect_data.get("draw_count") or 0)
        if draw_count > 0:
            player.draw(draw_count, rng)
        emit_replay_event(
            "treasure_created",
            player=player.name,
            card=card.get("name", "?"),
            treasures_created=treasure_count,
            treasures=player.treasures,
            cards_drawn=draw_count,
            turn=turn,
        )
        player.graveyard.append(card)
    elif effect == "land_ramp":
        put_lands_from_library(player, card, effect_data, turn, opponents=opponents, source_event="land_ramp")
        player.graveyard.append(card)
    elif effect == "land_recursion":
        return_graveyard_lands_to_battlefield(player, card, turn, opponents=opponents)
        player.graveyard.append(card)
    elif effect in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg"):
        for opp in opponents:
            targets = removal_target_candidates(opp, effect_data)
            if targets:
                t = choose_best_creature_target(targets)
                if effect_data.get("target_controller_gains_life"):
                    gain_life(opp, int(effect_data.get("target_controller_gains_life") or 0))
                emit_replay_event(
                    "removal_resolved",
                    player=player.name,
                    card=card.get("name", "?"),
                    target_player=opp.name,
                    target=t.get("name", "?"),
                    target_effect=get_card_effect(t).get("effect", t.get("effect")),
                    target_power=t.get("power"),
                    target_toughness=t.get("toughness"),
                    target_is_creature=is_battlefield_creature(t),
                    target_type_line=t.get("type_line", ""),
                    available_targets=len(targets),
                    turn=turn,
                )
                move_creature_from_battlefield(opp, t)
                break
        player.graveyard.append(card)
    elif effect == "deal_damage":
        apply_direct_damage(player, opponents, card, effect_data, turn, rng)
    elif effect == "equipment_haste_shroud":
        apply_equipment_haste_shroud(player, card, effect_data, turn)
    elif effect == "board_wipe":
        destroyed = 0
        protected = 0
        creatures_seen = 0
        unprotected_seen = 0
        for p in [player] + list(opponents):
            survivors = []
            for c in p.battlefield:
                if is_battlefield_creature(c):
                    creatures_seen += 1
                    # v8: indestructible per-creature
                    if c.get("indestructible"):
                        survivors.append(c)
                        protected += 1
                        continue
                    unprotected_seen += 1
                    move_creature_from_battlefield(p, c)
                    destroyed += 1
                else:
                    survivors.append(c)
            p.battlefield = survivors
        emit_replay_event(
            "board_wipe_resolved",
            player=player.name,
            card=card.get("name", "?"),
            destroyed=destroyed,
            protected=protected,
            creatures_seen=creatures_seen,
            unprotected_seen=unprotected_seen,
            turn=turn,
        )
        player.graveyard.append(card)
    elif effect == "phase_out":
        player.phased_out = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") not in ("land",)]
        player.battlefield = [c for c in player.battlefield if c == "land" or (isinstance(c, dict) and c.get("effect") == "land")]
        player.life_cant_change = True
        player.protection_from_everything = True
        player.graveyard.append(card)
    elif effect == "phase_creatures":
        targets = [c for c in player.battlefield if is_battlefield_creature(c)]
        player.phased_out.extend(targets)
        player.battlefield = [c for c in player.battlefield if c not in targets]
        emit_replay_event(
            "phase_creatures_resolved",
            player=player.name,
            card=card.get("name", "?"),
            phased=[c.get("name", "?") for c in targets],
            turn=turn,
        )
        player.graveyard.append(card)
    elif effect == "silence_opponents":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "silence_opponents"
        player.battlefield.append(permanent)
        player.silenced_opponents = True
    elif effect == "silence_spell":
        player.silenced_opponents_until_eot = True
        player.graveyard.append(card)
    elif effect == "indestructible":
        grant_creatures_until_eot(player, keywords=("indestructible",))
        player.indestructible = True
        player.graveyard.append(card)
    elif effect == "protect_creature":
        targets = [creature for creature in player.battlefield if is_battlefield_creature(creature)]
        if targets:
            target = choose_best_creature_target(targets)
            if effect_data.get("untap"):
                target["tapped"] = False
            remember_until_eot(target, "power")
            remember_until_eot(target, "toughness")
            target["power"] = int(target.get("power") or 0) + int(effect_data.get("power_boost") or 0)
            target["toughness"] = int(target.get("toughness") or 0) + int(effect_data.get("toughness_boost") or 0)
            set_until_eot(target, "shroud", True)
            emit_replay_event(
                "protection_resolved",
                player=player.name,
                card=card.get("name", "?"),
                target=target.get("name", "?"),
                grants=["shroud"],
                turn=turn,
            )
        player.graveyard.append(card)
    elif effect == "modal_boros_charm":
        response_to = card.get("_response_to_effect")
        preferred_mode = card.get("preferred_mode")
        if preferred_mode == "double_strike" and response_to != "board_wipe":
            grant_creatures_until_eot(player, keywords=("double_strike",))
        else:
            grant_creatures_until_eot(player, keywords=("indestructible",))
            player.indestructible = True
        player.graveyard.append(card)
    elif effect == "approach":
        player.approach_count += 1
        gain_life(player, 7)
        # v8.1: THREAT — all opponents now know Approach was cast
        player.threat_level += 50  # massive threat spike
        for opp in opponents:
            if player.name not in opp.approach_revealed:
                opp.approach_revealed.append(player.name)
        if player.approach_count >= 2:
            player.win_reason = "approach"
            emit_replay_event(
                "game_won",
                player=player.name,
                reason="approach",
                turn=turn,
            )
            player.graveyard.append(card)
            return
        if len(player.library) >= 7:
            player.library.insert(6, card)
        else:
            player.library.append(card)
    elif effect == "steal_all_creatures":
        total_power = 0
        for opp in opponents:
            creatures = [c for c in opp.battlefield if is_battlefield_creature(c)]
            for c in creatures:
                total_power += c.get("power", 2)
            opp.battlefield = [c for c in opp.battlefield if not is_battlefield_creature(c)]
        player.graveyard.append(card)
        alive_opps = [o for o in opponents if o.is_alive()]
        if alive_opps and total_power > 0:
            dmg_each = total_power // len(alive_opps)
            for opp in alive_opps:
                deal_damage(opp, dmg_each)
    elif effect == "token_maker":
        token_count = effect_data.get("token_count", 5)
        if isinstance(token_count, str):
            if token_count == "life_total": token_count = player.life // 2
            elif token_count == "lands": token_count = controlled_land_count(player)
        token_count = int(token_count)
        token_haste = bool(effect_data.get("token_haste") or effect_data.get("haste"))
        artifact_tokens = bool(effect_data.get("artifact_tokens"))
        for _ in range(min(token_count, 20)):
            create_creature_token(
                player,
                power=effect_data.get("token_power", 2),
                toughness=effect_data.get("token_toughness", effect_data.get("token_power", 2)),
                haste=token_haste,
                artifact=artifact_tokens,
            )
        player.graveyard.append(card)
    elif effect == "overload_recursion":
        spells = [c for c in player.graveyard if isinstance(c, dict) and c.get("cmc", 0) > 0]
        if player.copy_engines > 0: spells = spells * 2
        dmg = len(spells) * 3
        alive_opps = [o for o in opponents if o.is_alive()]
        if alive_opps:
            for opp in alive_opps: deal_damage(opp, dmg // len(alive_opps))
        player.graveyard.append(card)
    elif effect == "recursion":
        count = int(effect_data.get("count") or 2)
        target_type = effect_data.get("target")
        candidates = [
            grave_card
            for grave_card in player.graveyard
            if isinstance(grave_card, dict)
            and not is_land(grave_card)
            and (
                target_type != "creature"
                or is_creature_card(grave_card)
            )
            and (
                target_type == "creature"
                or is_instant(grave_card)
                or is_sorcery(grave_card)
                or get_card_effect(grave_card).get("effect") not in ("land", "unknown")
            )
        ]
        recovered = candidates[:count]
        destination = effect_data.get("destination", "hand")
        for recovered_card in recovered:
            if recovered_card in player.graveyard:
                player.graveyard.remove(recovered_card)
                if destination == "battlefield":
                    permanent_effect = get_card_effect(recovered_card)
                    permanent = enrich_card({**recovered_card, **permanent_effect})
                    if is_creature_card(recovered_card):
                        permanent["effect"] = "creature"
                        permanent["haste"] = has_haste(permanent)
                        permanent["summoning_sick"] = not permanent["haste"]
                        permanent["tapped"] = False
                    player.battlefield.append(permanent)
                else:
                    player.hand.append(recovered_card)
        emit_replay_event(
            "recursion_resolved",
            player=player.name,
            card=card.get("name", "?"),
            recovered=[recovered_card.get("name", "?") for recovered_card in recovered],
            destination=destination,
            turn=turn,
        )
        player.graveyard.append(card)
    elif effect == "pump_all":
        kw = effect_data.get("keywords", [])
        combat_keywords = [
            keyword
            for keyword in ("flying", "double_strike", "lifelink", "indestructible")
            if keyword in kw
        ]
        power_multiplier = effect_data.get("power_multiplier")
        if power_multiplier is None and card.get("name") != "Akroma's Will":
            power_multiplier = 2
        grant_creatures_until_eot(
            player,
            keywords=combat_keywords,
            power_multiplier=power_multiplier,
        )
        if "indestructible" in combat_keywords:
            player.indestructible = True
        player.graveyard.append(card)
    elif effect == "copy_spell":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "copy_spell"
        player.battlefield.append(permanent)
        player.copy_engines += 1
    elif effect == "tutor":
        target_type = effect_data.get("target", "any")
        found = None
        candidates = []
        for c in player.library:
            if target_type == "any":
                candidates.append(c)
            elif target_type == "artifact_or_enchantment":
                # v8.3: Enlightened Tutor — finds Artifact or Enchantment by type_line
                tl = c.get("type_line", "")
                if ("Artifact" in tl or "Enchantment" in tl) and c.get("name") != "Approach of the Second Sun":
                    candidates.append(c)
            elif target_type == "land":
                if is_effective_land(c):
                    candidates.append(c)
            elif target_type in ("graveyard", "graveyard_nonlegendary"):
                if target_type == "graveyard" or "legendary" not in str(c.get("type_line") or "").lower():
                    candidates.append(c)
            elif target_type in ("creature", "creature_to_battlefield"):
                if is_creature_card(c):
                    candidates.append(c)
            elif target_type == "instant_or_sorcery":
                if is_instant_or_sorcery_spell(c):
                    candidates.append(c)
            elif target_type in ("green_creature", "green_creature_to_battlefield"):
                if is_creature_card(c) and card_has_color(c, "G"):
                    candidates.append(c)
        if candidates:
            found = max(candidates, key=lambda candidate: candidate.get("cmc", 0))
        if found:
            player.library.remove(found)
            if target_type in ("graveyard", "graveyard_nonlegendary"):
                player.graveyard.append(found)
                destination = "graveyard"
            elif str(target_type).endswith("_to_battlefield"):
                permanent_effect = get_card_effect(found)
                permanent = enrich_card({**found, **permanent_effect})
                if is_creature_card(found):
                    permanent["effect"] = "creature"
                    permanent["haste"] = has_haste(permanent)
                    permanent["summoning_sick"] = not permanent["haste"]
                    permanent["tapped"] = False
                player.battlefield.append(permanent)
                destination = "battlefield"
            else:
                player.hand.append(found)
                destination = "hand"
        else:
            destination = None
        emit_replay_event(
            "tutor_resolved",
            player=player.name,
            card=card.get("name", "?"),
            target_type=target_type,
            found=found.get("name", "?") if found else None,
            destination=destination,
            turn=turn,
        )
        if effect_data.get("exiles_self"):
            player.exile.append(card)
        else:
            player.graveyard.append(card)
    elif effect == "topdeck_manipulation":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "topdeck_manipulation"
        player.battlefield.append(permanent)
        player.draw(1, rng)
    elif effect == "life_artifact":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "life_artifact"
        player.battlefield.append(permanent)
        emit_replay_event(
            "life_artifact_resolved",
            player=player.name,
            card=card.get("name", "?"),
            sacrifice_land_gain_life=effect_data.get("sacrifice_land_gain_life"),
            turn=turn,
        )
    elif effect == "hate_artifact":
        permanent = prepare_entering_permanent(enrich_card({**card, **effect_data}))
        permanent["effect"] = "hate_artifact"
        player.battlefield.append(permanent)
        emit_replay_event(
            "hate_artifact_resolved",
            player=player.name,
            card=card.get("name", "?"),
            counters_free_spells=bool(effect_data.get("counters_free_spells")),
            sacrifice_draw=effect_data.get("sacrifice_draw"),
            turn=turn,
        )
    elif effect == "loot":
        n = effect_data.get("count", 1)
        player.draw(n, rng)
        for _ in range(min(n, len(player.hand))):
            if player.hand:
                player.graveyard.append(player.hand.pop(rng.randint(0, len(player.hand) - 1)))
    elif effect == "finisher":
        creatures = [c for c in player.battlefield if is_battlefield_creature(c)]
        total_power = sum(c.get("power", 2) for c in creatures)
        if total_power > 0:
            alive_opps = [o for o in opponents if o.is_alive()]
            if alive_opps:
                deal_damage(rng.choice(alive_opps), total_power)
        player.graveyard.append(card)
    elif effect == "extra_turn":
        turns = int(effect_data.get("turns") or 1)
        player.extra_turns += turns
        if effect_data.get("lose_after_extra_turn"):
            player.extra_turn_loss_pending += turns
        emit_replay_event(
            "extra_turn_scheduled",
            player=player.name,
            card=card.get("name", "?"),
            extra_turns=player.extra_turns,
            lose_after_extra_turn=bool(effect_data.get("lose_after_extra_turn")),
            turn=turn,
        )
        player.graveyard.append(card)
    elif effect == "exile_value":
        # Dance with Calamity — exile top X, play for free
        X = max(3, player.available_mana() // 2)
        player.draw(min(X, 3), rng)
        player.graveyard.append(card)
    elif effect == "redirect_removal":
        grant_creatures_until_eot(player, keywords=("indestructible",))
        player.indestructible = True
        player.graveyard.append(card)

    elif effect == "ripple_engine":
        # Thrumming Stone — gives all spells ripple 4
        permanent = enrich_card({**card, **effect_data})
        permanent["effect"] = "ripple_engine"
        player.battlefield.append(permanent)
        player.copy_engines += 1  # reuse copy counter for ripple tracking

    elif effect == "dragons_approach":
        # Dragon's Approach — 3 damage to each opponent per copy
        # Count copies in graveyard for bonus damage
        grave_copies = sum(1 for c in player.graveyard if isinstance(c, dict) and c.get("name") == "Dragon's Approach")
        total_damage = 3 + grave_copies  # +3 per copy in grave
        for opp in opponents:
            if opp.is_alive():
                deal_damage(opp, total_damage)
        
        # Ripple: after casting, reveal top 4 and cast matching spells for free
        has_ripple = any(isinstance(c, dict) and c.get("effect") == "ripple_engine" for c in player.battlefield)
        if has_ripple and player.library:
            ripple_count = min(4, len(player.library))
            extra_casts = 0
            for i in range(ripple_count):
                if i >= len(player.library): break
                c = player.library[i]
                if isinstance(c, dict) and c.get("name") == "Dragon's Approach":
                    extra_casts += 1
                    # Cast it for free — deal damage again
                    for opp in opponents:
                        if opp.is_alive():
                            deal_damage(opp, total_damage)
                    # Remove from library
                    player.library.pop(i)
            if extra_casts > 0:
                print(f"  [RIPPLE] Cast {extra_casts} extra Dragon's Approach!")
        
        player.graveyard.append(card)

    elif effect == "combo" and card.get("name") == "Dualcaster Mage":
        # Dualcaster enters, check if Twinflame is on the stack or was just cast
        # If another creature exists on board, the combo can fire
        creatures = [c for c in player.battlefield if is_battlefield_creature(c)]
        if creatures:
            # Check if Twinflame is in graveyard (was just used) OR in hand
            twinflame_used = any(c.get("name") == "Twinflame" for c in player.graveyard)
            twinflame_hand = any(c.get("name") == "Twinflame" for c in player.hand)
            if twinflame_used or twinflame_hand:
                # COMBO FIRES! Infinite hasty 2/2 tokens
                # Create enough tokens to kill all opponents
                total_opp_life = sum(o.life for o in opponents if o.is_alive())
                tokens_needed = max(1, total_opp_life // 2)  # 2/2 tokens
                for _ in range(min(tokens_needed, 50)):  # cap at 50 tokens
                    player.battlefield.append({
                        "name": "Dualcaster Token", "cmc": 0, "tag": "token",
                        "effect": "creature", "power": 2, "toughness": 2,
                        "haste": True, "summoning_sick": False,
                    })
                # Attack with all tokens immediately
                total_power = tokens_needed * 2
                alive_opps = [o for o in opponents if o.is_alive()]
                if alive_opps:
                    dmg_each = total_power // len(alive_opps)
                    for opp in alive_opps:
                        deal_damage(opp, dmg_each)
                print(f"  [COMBO] Dualcaster+Twinflame = {tokens_needed} hasty 2/2s! {total_power} total damage")
        
        permanent = enrich_card(dict(card))
        permanent["effect"] = "creature"
        permanent["haste"] = True
        permanent["summoning_sick"] = False
        permanent["tapped"] = False
        player.battlefield.append(permanent)

def combat_phase_v8(attacker, opponents, all_players, turn, rng, stack):
    creatures = attacker.untapped_creatures()
    if not creatures: return

    attackers = []
    for c in creatures:
        try:
            attack_power = int(c.get("power", 0) or 0)
        except (TypeError, ValueError):
            attack_power = 0
        if attack_power <= 0 and not c.get("attack_trigger"):
            continue
        if not c.get("summoning_sick", False) or has_haste(c):
            if not has_vigilance(c):
                c["tapped"] = True
            attackers.append(c)
    if not attackers: return

    alive_defenders = [o for o in opponents if o.is_alive()]
    if not alive_defenders: return

    # v8: Instant-speed removal window before combat damage
    for opp in alive_defenders:
        if opp.is_human: continue
        removals = [c for c in opp.hand if get_card_effect(c).get("effect") in ("remove_creature",) and opp.can_pay_card(c)]
        if removals and rng.random() < 0.3:
            c = rng.choice(removals)
            if c in opp.hand and opp.can_pay_card(c):
                opp.hand.remove(c)
                opp.spend_card_mana(c)
                # Remove one attacker
                valid_attackers = [
                    attacker_card
                    for attacker_card in attackers
                    if not attacker_card.get("shroud")
                    and not attacker_card.get("protection_from_everything")
                ]
                if valid_attackers:
                    eff = get_card_effect(c)
                    target = choose_best_creature_target(valid_attackers)
                    emit_replay_event(
                        "instant_removal",
                        player=opp.name,
                        card=c.get("name", "?"),
                        effect=eff.get("effect", "unknown"),
                        target_player=attacker.name,
                        target=target.get("name", "?"),
                        target_power=target.get("power"),
                        target_toughness=target.get("toughness"),
                        attackers_before=len(attackers),
                        turn=turn,
                        **replay_rule_fields(eff),
                    )
                    attackers.remove(target)
                    move_creature_from_battlefield(attacker, target)

    if not attackers: return

    total_power = sum(a.get("power", 2) for a in attackers)
    lethal_targets = [opp for opp in alive_defenders if opp.life <= total_power]
    known_approach_casters = [
        opp for opp in alive_defenders if opp.name in attacker.approach_revealed
    ]

    # Visible lethal is always the best attack. Known alternate-win threats follow.
    if lethal_targets:
        target = min(lethal_targets, key=lambda opp: opp.life)
        target_reason = "lethal"
    elif known_approach_casters:
        target = max(
            known_approach_casters,
            key=lambda opp: (opp.approach_count, opp.threat_level, -opp.life),
        )
        target_reason = "known_approach"
    elif attacker.strategy in ("aggro", "rush"):
        target = min(alive_defenders, key=lambda o: o.life)
        target_reason = "aggro_low_life"
    elif attacker.strategy == "control":
        target = max(
            alive_defenders,
            key=lambda opp: (
                opp.threat_level,
                sum(
                    card.get("power", 0)
                    for card in opp.battlefield
                    if is_battlefield_creature(card)
                ),
                -opp.life,
            ),
        )
        target_reason = "control_high_threat"
    else:
        target = min(
            alive_defenders,
            key=lambda opp: (
                opp.life,
                -opp.threat_level,
                -sum(
                    card.get("power", 0)
                    for card in opp.battlefield
                    if is_battlefield_creature(card)
                ),
            ),
        )
        target_reason = "default_low_life"

    # Only the attacked player can block. Multiple blockers may gang-block one attacker.
    block_assignments = []
    assigned_blockers = []
    for a in sorted(attackers, key=lambda creature: creature.get("power", 2), reverse=True):
        available = [
            blocker
            for blocker in target.creatures_for_blocking()
            if blocker not in assigned_blockers
            and (
                not a.get("flying")
                or blocker.get("flying")
                or blocker.get("reach")
            )
        ]
        lethal_attack = target.life <= a.get("power", 2)
        if not available or (not lethal_attack and rng.random() >= 0.35):
            block_assignments.append((a, []))
            continue
        blockers = []
        combined_power = 0
        for blocker in sorted(available, key=lambda creature: creature.get("power", 2), reverse=True):
            blockers.append(blocker)
            combined_power += blocker.get("power", 2)
            if combined_power >= a.get("toughness", a.get("power", 2)):
                break
        can_kill_attacker = combined_power >= a.get("toughness", a.get("power", 2))
        if not can_kill_attacker:
            blockers = blockers[:1] if lethal_attack else []
        elif not lethal_attack:
            attack_damage = a.get("power", 2)
            estimated_losses = 0
            for blocker in blockers:
                lethal_to_blocker = 1 if a.get("deathtouch") else blocker.get(
                    "toughness", blocker.get("power", 2)
                )
                if attack_damage >= lethal_to_blocker:
                    estimated_losses += 1
                    attack_damage -= lethal_to_blocker
            # Avoid an automatic full-board suicide unless it prevents lethal.
            if estimated_losses == len(blockers):
                blockers = []
        assigned_blockers.extend(blockers)
        block_assignments.append((a, blockers))

    combat_target_life_before = target.life
    combat_attacker_life_before = attacker.life

    emit_replay_event(
        "combat",
        attacker=attacker.name,
        target=target.name,
        target_reason=target_reason,
        target_life_before=combat_target_life_before,
        attacker_life_before=combat_attacker_life_before,
        target_life_cant_change=bool(target.life_cant_change),
        target_protection_from_everything=bool(target.protection_from_everything),
        defenders=[
            {
                "name": defender.name,
                "life": defender.life,
                "threat_level": defender.threat_level,
                "creatures": len(defender.creatures_for_blocking()),
                "approach_count": defender.approach_count,
            }
            for defender in alive_defenders
        ],
        attackers=len(attackers),
        attackers_detail=[replay_card_snapshot(card) for card in attackers],
        blockers=sum(len(blockers) for _, blockers in block_assignments),
        blockers_detail=[
            {
                "attacker": replay_card_snapshot(attacking_creature),
                "blockers": [replay_card_snapshot(blocker) for blocker in blockers],
            }
            for attacking_creature, blockers in block_assignments
        ],
        multi_blocks=sum(1 for _, blockers in block_assignments if len(blockers) > 1),
        total_power=total_power,
        turn=turn,
    )

    def stat(card, key, fallback):
        try:
            return int(card.get(key, fallback))
        except (TypeError, ValueError):
            return fallback

    def deal_player_damage(creature, damage=None):
        damage = stat(creature, "power", 2) if damage is None else damage
        damage_dealt = deal_damage(target, damage)
        if damage_dealt and creature.get("lifelink"):
            gain_life(attacker, damage)
        if damage_dealt and creature.get("is_commander") and creature.get("owner") == attacker.name:
            attacker.commander_damage[target.name] += damage

    marked_damage = defaultdict(int)
    deathtouch_damage = set()

    def deals_in_phase(creature, first_strike_phase):
        if first_strike_phase:
            return creature.get("first_strike") or creature.get("double_strike")
        return not creature.get("first_strike") or creature.get("double_strike")

    def mark_damage(source, damaged, amount):
        if amount <= 0:
            return
        marked_damage[id(damaged)] += amount
        if source.get("deathtouch"):
            deathtouch_damage.add(id(damaged))

    def destroy_lethal_creatures():
        for owner, creatures in ((attacker, attackers), (target, target.creatures_for_blocking())):
            for creature in list(creatures):
                lethal = (
                    marked_damage[id(creature)]
                    >= stat(creature, "toughness", stat(creature, "power", 2))
                    or id(creature) in deathtouch_damage
                )
                if lethal and not creature.get("indestructible") and creature in owner.battlefield:
                    move_creature_from_battlefield(owner, creature)

    def combat_damage_step(first_strike_phase):
        for attacking_creature, declared_blockers in block_assignments:
            if attacking_creature not in attacker.battlefield:
                continue
            surviving_blockers = [
                blocker for blocker in declared_blockers if blocker in target.battlefield
            ]

            if deals_in_phase(attacking_creature, first_strike_phase):
                remaining = stat(attacking_creature, "power", 2)
                if not declared_blockers:
                    deal_player_damage(attacking_creature, remaining)
                else:
                    for blocker in surviving_blockers:
                        lethal_needed = (
                            1
                            if attacking_creature.get("deathtouch")
                            else max(
                                0,
                                stat(blocker, "toughness", stat(blocker, "power", 2))
                                - marked_damage[id(blocker)],
                            )
                        )
                        assigned_damage = min(remaining, lethal_needed)
                        mark_damage(attacking_creature, blocker, assigned_damage)
                        remaining -= assigned_damage
                    if attacking_creature.get("trample") and remaining > 0:
                        deal_player_damage(attacking_creature, remaining)

            for blocker in surviving_blockers:
                if deals_in_phase(blocker, first_strike_phase):
                    mark_damage(blocker, attacking_creature, stat(blocker, "power", 2))

        destroy_lethal_creatures()

    if any(
        creature.get("first_strike") or creature.get("double_strike")
        for creature in attackers + target.creatures_for_blocking()
    ):
        combat_damage_step(first_strike_phase=True)
    combat_damage_step(first_strike_phase=False)

    # Check for commander damage kill
    for name, dmg in attacker.commander_damage.items():
        if dmg >= 21:
            for opp in opponents:
                if opp.name == name: opp.life = 0

    emit_replay_event(
        "combat_result",
        attacker=attacker.name,
        target=target.name,
        target_life_after=target.life,
        attacker_life_after=attacker.life,
        damage_to_player=max(0, combat_target_life_before - target.life),
        target_life_before=combat_target_life_before,
        target_life_cant_change=bool(target.life_cant_change),
        target_protection_from_everything=bool(target.protection_from_everything),
        attackers_survived=sum(1 for card in attackers if card in attacker.battlefield),
        blockers_survived=len(target.creatures_for_blocking()),
        target_dead=not target.is_alive(),
        turn=turn,
    )

def play_turn_v8(player, opponents, all_players, turn, rng, stack):
    """v8: Full turn with priority windows between phases."""
    if game_winner(all_players):
        return
    emit_replay_event(
        "turn_start",
        player=player.name,
        turn=turn,
        life=player.life,
        hand=len(player.hand),
        board=len(player.battlefield),
    )
    player.lands_played_this_turn = 0
    player.cards_drawn_this_turn = 0
    clear_until_eot(player)
    player.indestructible = False

    # ── UNTAP ──
    for c in player.battlefield:
        if isinstance(c, dict):
            c["tapped"] = False
            if is_battlefield_creature(c):
                c["summoning_sick"] = False
    # Return phased out permanents (v7 fix: should be upkeep, keeping simple here)
    player.battlefield.extend(player.phased_out)
    player.phased_out = []
    player.life_cant_change = False
    player.protection_from_everything = False
    player.refresh_mana_sources(turn)

    # ── UPKEEP (v8.3: The One Ring burden = draw 1 per turn if on board) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and c.get("burden"):
            for _ in range(sum(1 for _ in player.battlefield if isinstance(_, dict) and _.get("effect") == "draw_engine")):
                player.draw(1, rng)

    # ── DRAW ──
    drawn_for_turn = player.draw(1, rng)
    if check_sbas(all_players):
        return

    # v8: MIRACLE check
    if player.is_human and drawn_for_turn and player.cards_drawn_this_turn == 1:
        lorehold_on_board = any(isinstance(c, dict) and c.get("name") == "Lorehold, the Historian" for c in player.battlefield)
        last_drawn = drawn_for_turn[-1]
        if last_drawn and is_instant_or_sorcery_spell(last_drawn):
            miracle_cost = 2  # Lorehold gives miracle {2}
            if last_drawn.get("name") == "Reforge the Soul":
                miracle_cost = 2  # 1R but simplified
            mana = player.available_mana()
            if mana >= miracle_cost and lorehold_on_board:
                eff = get_card_effect(last_drawn)
                player.hand.remove(last_drawn)
                player.spend_mana(miracle_cost)
                emit_replay_event(
                    "miracle_cast",
                    player=player.name,
                    card=last_drawn.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    type_line=last_drawn.get("type_line", ""),
                    miracle_cost=miracle_cost,
                    lorehold_on_board=lorehold_on_board,
                    cards_drawn_this_turn=player.cards_drawn_this_turn,
                    turn=turn,
                    **replay_rule_fields(eff),
                )
                stack.push(last_drawn, player, eff)
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)

    # ── PRECOMBAT MAIN ──
    total_mana = player.available_mana()
    lands_in_hand = [c for c in player.hand if is_effective_land(c)]  # v10.2
    if lands_in_hand and player.lands_played_this_turn < player.max_lands_per_turn:
        land = lands_in_hand[0]
        eff = get_card_effect(land)
        player.hand.remove(land)
        land_permanent = enrich_card({**land, "effect": "land"})
        player.battlefield.append(land_permanent)
        player.lands_played_this_turn += 1
        player.mana_pool.add(source_colors(land_permanent)[0], 1)
        trigger_landfall(player, land_permanent, turn, "land_played", opponents=opponents)
        trigger_opponent_land_play_engines(player, opponents, land_permanent, turn)
        emit_replay_event(
            "land_played",
            player=player.name,
            card=land.get("name", "?"),
            effect=eff.get("effect", "land"),
            turn=turn,
            **replay_rule_fields(eff),
        )
    activate_land_tutor_creatures(player, turn)
    cast_spells_v8(player, opponents, all_players, turn, "precombat_main", stack, rng)
    if game_winner(all_players):
        return
    if check_sbas(all_players): return

    # ── TRIGGER: Smothering Tithe on opponent draws (during draw step above) ──
    for opp in opponents:
        if opp.is_alive():
            for c in opp.battlefield:
                if isinstance(c, dict) and c.get("effect") == "ramp_engine" and c.get("trigger") == "opponent_draw":
                    c["counter"] = c.get("counter", 0) + 1
                    # Creates a Treasure token (simplified as +1 treasure)
                    opp.treasures += 1


    # ── COMBAT ──
    if turn > 1:
        combat_phase_v8(player, opponents, all_players, turn, rng, stack)
        if game_winner(all_players):
            return
        if check_sbas(all_players): return

    # ── POSTCOMBAT MAIN ──
    total_mana = player.available_mana()
    cast_spells_v8(player, opponents, all_players, turn, "postcombat_main", stack, rng)
    if game_winner(all_players):
        return
    if check_sbas(all_players): return


    # ── END STEP (v8.3) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and not c.get("burden"):
            player.draw(1, rng)
    
    # ── OPPONENT END STEP INTERACTION (NEW) ──
    # All opponents can cast instants on this player's end step
    if not (player.silenced_opponents or player.silenced_opponents_until_eot):
        for opp in opponents:
            if not opp.is_alive(): continue
            instants_in_hand = [
                c for c in opp.hand
                if not is_effective_land(c)
                and is_instant(c)
                and is_modeled_battle_card(c)
                and opp.can_pay_card(c)
            ]
            for c in instants_in_hand[:1]:  # 1 instant per opponent per end step
                if opp.can_pay_card(c):
                    eff = get_card_effect(c)
                    opp.hand.remove(c)
                    opp.spend_card_mana(c)
                    emit_replay_event(
                        "end_step_instant",
                        player=opp.name,
                        card=c.get("name", "?"),
                        effect=eff.get("effect", "unknown"),
                        type_line=c.get("type_line", ""),
                        instant_speed_reason="flash" if card_has_keyword(c, "flash") else "instant",
                        active_player=player.name,
                        turn=turn,
                        **replay_rule_fields(eff),
                    )
                    apply_effect_immediate(opp, [p for p in all_players if p != opp], c, turn, rng)


    # ── CLEANUP ──
    discarded = 0
    while len(player.hand) > 7:
        worst = max(player.hand, key=lambda c: c.get("cmc", 0))
        player.hand.remove(worst)
        player.graveyard.append(worst)
        discarded += 1

    emit_replay_event(
        "turn_end",
        player=player.name,
        turn=turn,
        life=player.life,
        hand=len(player.hand),
        board=len(player.battlefield),
        graveyard=len(player.graveyard),
        discarded=discarded,
    )

    for participant in all_players:
        clear_until_eot(participant)

    # v8: SBA check at end of turn
    check_sbas(all_players)


def play_turn_sequence_v8(player, opponents, all_players, turn, rng, stack, max_extra_turns=5):
    """Play a normal turn, then any extra turns that player has earned."""
    play_turn_v8(player, opponents, all_players, turn, rng, stack)
    extra_turns_taken = 0
    while (
        player.is_alive()
        and player.extra_turns > 0
        and not game_winner(all_players)
        and extra_turns_taken < max_extra_turns
    ):
        player.extra_turns -= 1
        extra_turns_taken += 1
        emit_replay_event(
            "extra_turn_taken",
            player=player.name,
            turn=turn,
            extra_turn_index=extra_turns_taken,
            remaining_extra_turns=player.extra_turns,
        )
        play_turn_v8(player, opponents, all_players, turn, rng, stack)
        if player.extra_turn_loss_pending > 0 and player.is_alive() and not player.has_won():
            player.extra_turn_loss_pending -= 1
            player.life = 0
            emit_replay_event(
                "game_lost",
                player=player.name,
                reason="delayed_extra_turn_loss",
                turn=turn,
            )
            check_sbas(all_players)
            break
        check_sbas(all_players)
    if player.extra_turns > 0 and extra_turns_taken >= max_extra_turns:
        emit_replay_event(
            "extra_turn_cap_reached",
            player=player.name,
            turn=turn,
            remaining_extra_turns=player.extra_turns,
            cap=max_extra_turns,
        )


def simulate_game_with_real_opponents(my_commander, my_deck, opponent_data_list, rng, game_id=0):
    """Simulate game with real learned opponents (pre-built decks)."""
    turn, max_turns = 0, 35
    stack = Stack()

    lorehold = Player("Lorehold", my_commander, my_deck, is_human=True, strategy="spellslinger")
    opponents = []
    for opp_data in opponent_data_list:
        opp_cmd = {"name": opp_data["commander_name"], "cmc": 4, "tag": "creature", 
                   "type_line": "Legendary Creature", "is_commander": True, "owner": opp_data["name"]}
        opp = Player(opp_data["name"], opp_cmd, opp_data["deck"], strategy=opp_data.get("strategy", "midrange"))
        opponents.append(opp)

    all_players = [lorehold] + opponents
    approach_found = False
    approach_countered = 0

    for p in all_players:
        play_mulligan(p, rng)

    while lorehold.is_alive() and turn < max_turns:
        turn += 1
        alive = [p for p in all_players if p.is_alive()]
        if len(alive) <= 1:
            break

        for player in all_players:
            if not player.is_alive():
                continue
            others = [p for p in all_players if p != player]
            play_turn_sequence_v8(player, others, all_players, turn, rng, stack)
            if not player.is_alive():
                continue
            # Check any explicit alternate-win state.
            for p in all_players:
                if p.has_won():
                    return ("win" if p is lorehold else "loss"), turn, p.win_reason
            check_sbas_until_stable(all_players)
            if any(hasattr(p, "eliminated") and p.eliminated for p in all_players):
                break

    if lorehold.is_alive():
        alive_opps = sum(1 for o in opponents if o.is_alive())
        if alive_opps == 0:
            return "win", turn, "elimination"
        return "stall", turn, f"opponents_alive={alive_opps}"
    return "loss", turn, "life_zero"


def simulate_game_v8(my_commander, my_deck, opp_profile, rng, game_id=0):
    turn, max_turns = 0, 35
    stack = Stack()

    lorehold = Player("Lorehold", my_commander, my_deck, is_human=True, strategy="spellslinger")
    opponents = []
    for profile in opp_profile:
        if profile.get("is_real") and profile.get("built_deck"):
            # Real learned deck — use pre-built deck list directly
            opp_cmd = {"name": profile["commander_name"], "cmc": 4, "tag": "creature",
                       "type_line": "Legendary Creature", "is_commander": True, "owner": profile["name"]}
            opp = Player(profile["name"], opp_cmd, profile["built_deck"], strategy=profile.get("strategy", "midrange"))
        else:
            opp_deck = generate_opponent_deck(profile)
            opp_cmd = get_opponent_commander(profile)
            opp = Player(profile["name"], opp_cmd, opp_deck, strategy=profile["strategy"])
        opponents.append(opp)

    all_players = [lorehold] + opponents

    # v8.3: Track Approach statistics
    approach_found = False
    approach_countered = 0
    approach_resolved = 0

    for p in all_players:
        play_mulligan(p, rng)

    while lorehold.is_alive() and turn < max_turns:
        turn += 1
        alive = [p for p in all_players if p.is_alive()]
        if len(alive) <= 1:
            break

        for player in all_players:
            if not player.is_alive():
                continue
            others = [p for p in all_players if p != player]
            play_turn_sequence_v8(player, others, all_players, turn, rng, stack)
            if not player.is_alive():
                continue
            # Check any explicit alternate-win state.
            for p in all_players:
                if p.has_won():
                    return ("win" if p is lorehold else "loss"), turn, p.win_reason
            check_sbas_until_stable(all_players)
            if any(hasattr(p, "eliminated") and p.eliminated for p in all_players):
                break

    if lorehold.is_alive():
        alive_opps = sum(1 for o in opponents if o.is_alive())
        if alive_opps == 0:
            return "win", turn, "elimination"
        return "stall", turn, f"opponents_alive={alive_opps}|found={approach_found}|countered={approach_countered}"
    return "loss", turn, f"life_zero|found={approach_found}|countered={approach_countered}"

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════


def load_learned_opponents():
    """Load real opponent decklists from learned_decks table."""
    try:
        conn = sqlite3.connect(DB)
        conn.row_factory = sqlite3.Row
        candidate_limit = int(os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_CANDIDATES", "96"))
        opponent_limit = int(os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_LIMIT", "12"))
        min_cards = int(os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_MIN_CARDS", "80"))
        rows = conn.execute(
            """
            SELECT *
            FROM learned_decks
            WHERE COALESCE(commander, '') != ''
              AND commander NOT LIKE '%Lorehold%'
              AND COALESCE(card_list, '') != ''
              AND length(card_list) >= 500
              AND COALESCE(card_count, 0) >= ?
            ORDER BY
              CASE WHEN source = 'pg_meta_decks' THEN 0 ELSE 1 END,
              COALESCE(card_count, 0) DESC,
              id DESC
            LIMIT ?
            """,
            (min_cards, candidate_limit),
        ).fetchall()
        decoded_rows = []
        cache_names = []
        for row in rows:
            card_data = decode_learned_card_list(row["card_list"])
            if len(card_data) < min_cards:
                continue
            decoded_rows.append((row, card_data))
            if row["commander"]:
                cache_names.append(row["commander"])
            cache_names.extend(
                c.get("name")
                for c in card_data
                if isinstance(c, dict) and c.get("name")
            )
        oracle_cache = load_card_oracle_cache(conn, cache_names)
        conn.close()
        decks = []
        for row, card_data in decoded_rows:
            deck = []
            commander_key = normalize_card_name(row["commander"])
            for raw_card in card_data:
                expanded_cards = expand_learned_card(raw_card)
                for c in expanded_cards:
                    if normalize_card_name(c.get("name")) == commander_key:
                        continue
                    if len(deck) >= 99:
                        break
                    deck.append(build_learned_battle_card(c, oracle_cache))
                if len(deck) >= 99:
                    break
            original_deck_count = len(deck)
            while len(deck) < 99:
                deck.append({
                    "name": "Filler",
                    "cmc": 3,
                    "tag": "creature",
                    "effect": "creature",
                    "power": 2,
                    "toughness": 2,
                    "type_line": "Creature",
                })
            real_name = f"{row['commander']} #{row['id']} (real)"
            decks.append({
                "name": real_name, "archetype": row["archetype"] or "midrange",
                "source": row["source"],
                "learned_deck_id": row["id"],
                "source_card_count": row["card_count"],
                "battle_card_count": original_deck_count,
                "built_deck": deck,
                "commander_name": row["commander"],
                "strategy": infer_strategy(row["archetype"] or "midrange"),
                "life": 40, "lands": sum(1 for c in deck if c.get("effect") == "land"),
                "ramp": sum(1 for c in deck if c.get("effect") in ("ramp",)),
                "removal": sum(1 for c in deck if c.get("effect") in ("removal", "board_wipe")) ,
                "counters": sum(1 for c in deck if c.get("effect") == "counter"),
                "creatures": sum(1 for c in deck if c.get("effect") == "creature"),
                "avg_cmc": sum(c.get("cmc", 3) for c in deck) / max(1, len(deck)),
                "is_real": True,
            })
        seed = real_opponent_seed()
        rng = random.Random(seed)
        rng.shuffle(decks)
        decks = decks[:opponent_limit]
        if decks:
            print(
                f"Loaded {len(decks)} real opponent decks from {len(decoded_rows)} "
                f"valid candidates (seed={seed})"
            )
        return decks
    except Exception as e:
        print(f"load_learned_opponents: {e}")
        return []


def decode_learned_card_list(value):
    """Decode JSON card lists and legacy plain-text decklists into card entries."""
    if not value:
        return []
    text = str(value)
    try:
        decoded = json.loads(text)
    except Exception:
        decoded = None
    if isinstance(decoded, list):
        return decoded

    cards = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.lower() in ("deck", "commander", "sideboard", "maybeboard"):
            continue
        line = re.sub(r"^(sb:|sideboard:)\s*", "", line, flags=re.I).strip()
        match = re.match(r"^(\d+)\s*x?\s+(.+)$", line, flags=re.I)
        if not match:
            continue
        quantity = max(1, min(30, int(match.group(1))))
        name = re.sub(r"\s+\([^)]*\)\s*\d*\s*$", "", match.group(2)).strip()
        if name:
            cards.append({"name": name, "quantity": quantity})
    return cards


def expand_learned_card(card):
    if isinstance(card, str):
        return [{"name": card}]
    if not isinstance(card, dict):
        return []
    quantity = card.get("quantity", 1)
    try:
        quantity = int(quantity)
    except (TypeError, ValueError):
        quantity = 1
    quantity = max(1, min(30, quantity))
    base = dict(card)
    base.pop("quantity", None)
    return [dict(base) for _ in range(quantity)]


def infer_strategy(archetype):
    normalized = str(archetype or "").lower()
    if "stax" in normalized:
        return "stax"
    if "combo" in normalized or "storm" in normalized:
        return "combo"
    if "control" in normalized:
        return "control"
    if "aggro" in normalized or "rush" in normalized:
        return "rush"
    if "spell" in normalized:
        return "spells"
    if "midrange" in normalized or "value" in normalized:
        return "value"
    return "midrange"


def infer_battle_card_identity(card):
    role = str(card.get("role") or card.get("category") or card.get("tag") or "").lower()
    type_line = str(card.get("type_line") or "").lower()
    oracle_text = str(card.get("oracle_text") or "").lower()
    name = str(card.get("name") or "").lower()

    if role == "land" or "land" in type_line or normalize_card_name(name) in KNOWN_LAND_NAMES:
        return "land", "land"
    if role in ("ramp", "rock") or "add " in oracle_text or "treasure token" in oracle_text:
        return "ramp", "ramp"
    if role in ("counterspell", "counter") or "counter target" in oracle_text:
        return "counter", "counter"
    if role in ("board_wipe", "sweeper") or "destroy all" in oracle_text or "exile all" in oracle_text:
        return "board_wipe", "board_wipe"
    if role in ("removal",) or "destroy target" in oracle_text or "exile target" in oracle_text:
        return "removal", "removal"
    if role in ("draw", "cantrip", "wheel") or "draw" in oracle_text:
        return "draw", "draw"
    if role == "tutor" or "search your library" in oracle_text:
        return "tutor", "tutor"
    if role == "protection" or "indestructible" in oracle_text or "protection from" in oracle_text:
        return "protection", "protection"
    if role in ("wincon", "combo_piece") or "you win the game" in oracle_text:
        return "wincon", "wincon"
    if role == "creature" or "creature" in type_line or "token" in name:
        return "creature", "creature"
    if "instant" in type_line:
        return "spell", "instant"
    if "sorcery" in type_line:
        return "spell", "sorcery"
    return "unknown", "unknown"


def build_learned_battle_card(card, oracle_cache):
    name = card.get("name", "?")
    imported = dict(card)
    imported["name"] = name
    imported = merge_oracle_metadata(imported, oracle_cache)
    tag, effect = infer_battle_card_identity(imported)
    cmc = imported.get("cmc")
    try:
        cmc = float(cmc if cmc is not None else 3)
    except (TypeError, ValueError):
        cmc = 3
    imported.update({
        "cmc": cmc,
        "tag": tag,
        "effect": effect,
        "type_line": imported.get("type_line") or ("Land" if effect == "land" else ("Creature" if effect == "creature" else "")),
        "is_commander": bool(imported.get("is_commander", False)),
    })
    if effect == "creature":
        default_power = max(1, int(cmc))
        imported["power"] = imported.get("power") or default_power
        imported["toughness"] = imported.get("toughness") or imported.get("power") or default_power
    else:
        imported["power"] = imported.get("power") or 0
        imported["toughness"] = imported.get("toughness") or 0
    return enrich_card(imported)


def real_opponent_seed():
    seed_raw = os.environ.get("MANALOOM_BATTLE_REAL_OPPONENT_SEED")
    if seed_raw:
        try:
            return int(seed_raw)
        except ValueError:
            return abs(hash(seed_raw)) % 1_000_000_000
    return int(datetime.now(timezone.utc).strftime("%Y%m%d%H"))


def main():
    print("=" * 60)
    print("BATTLE ANALYST v8 — Interactive Commander (Priority + Stack + Miracle)")
    print("=" * 60)

    commander, deck = load_deck()
    lands = sum(1 for c in deck if c.get("tag") == "land" or "Land" in c.get("type_line", ""))
    ramp = sum(1 for c in deck if c.get("tag") in ("ramp", "ritual"))
    removal = sum(1 for c in deck if c.get("tag") in ("removal", "board_wipe"))
    nonlands = [c for c in deck if c.get("tag") != "land"]
    avg_cmc = sum(c["cmc"] for c in nonlands) / max(1, len(nonlands))
    instants_in_deck = sum(1 for c in deck if is_instant(c))

    print(f"Commander: {commander['name'] if commander else 'NONE'}")
    print(f"Deck: 1+99 | L={lands} R={ramp} X={removal} CMC={avg_cmc:.2f} Instants={instants_in_deck}")
    print(f"v8: Priority, Stack, Instant/Sorcery Timing, Counterspells, SBAs, Miracle, Boros Charm modal, Lifelink, Haste")

    # Check for learned decks first
    learned = load_learned_opponents()
    if learned and len(learned) >= 3:
        opponent_sources = learned
        opponent_kind = "real"
        print(f"\nUsing {len(learned)} REAL learned opponent decks")
    else:
        opponent_sources = OPPONENT_ARCHETYPES
        opponent_kind = "generic"
        print(f"\nUsing {len(OPPONENT_ARCHETYPES)} generic archetype profiles")

    GAMES = 50
    rng = random.Random(42)

    results = []
    total_wins = total_losses = total_stalls = 0

    print(f"\n{GAMES} games vs each of {len(opponent_sources)} {opponent_kind} opponents (4-player)...\n")

    for profile in opponent_sources:
        wins = losses = stalls = 0
        win_turns = []
        win_reasons = defaultdict(int)

        for g in range(GAMES):
            others = [p for p in opponent_sources if p != profile]
            picked = [profile] + rng.sample(others, min(2, len(others)))
            # For learned decks, attach card list directly
            for p in picked:
                if p.get("is_real"):
                    # Card list is in profile data, pass through
                    pass
            result, turns, reason = simulate_game_v8(commander, deck, picked, rng, g)

            if result == "win":
                wins += 1
                win_turns.append(turns)
                win_reasons[reason] += 1
            elif result == "loss":
                losses += 1
            else:
                stalls += 1

        wr = wins / GAMES * 100
        avg_t = sum(win_turns) / len(win_turns) if win_turns else 0

        results.append({"opponent": profile.get("name", profile["name"]), "archetype": profile.get("archetype", "?"),
                        "wins": wins, "losses": losses, "stalls": stalls,
                        "win_rate": wr, "avg_win_turn": avg_t,
                        "win_reasons": dict(win_reasons)})

        total_wins += wins; total_losses += losses; total_stalls += stalls

        icon = "✅" if wr >= 55 else "⚖️" if wr >= 40 else "❌"
        details = ", ".join(f"{k}={v}" for k, v in win_reasons.items())
        print(f"  {icon} vs {profile.get('name', '?'):<30s} WR={wr:5.1f}% W={wins} L={losses} S={stalls} T={avg_t:.1f} [{details}]")

    total_g = GAMES * len(opponent_sources)
    avg_wr = total_wins / total_g * 100
    print(f"\n  OVERALL v8: WR={avg_wr:.1f}% ({total_wins}W/{total_losses}L/{total_stalls}S)")

    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(LOG_PATH, "a") as f:
        f.write(f"\n## [{ts}] Battle Analyst v8 — Interactive Commander\n")
        f.write(f"Games: {GAMES} 4-player | Deck: L={lands} R={ramp} X={removal} CMC={avg_cmc:.2f} Instants={instants_in_deck}\n")
        f.write(f"Opponents: {len(opponent_sources)} ({opponent_kind})\n\n")
        f.write(f"| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |\n")
        f.write(f"|:---------|----:|-----:|-------:|-------:|------:|:--------|\n")
        for r in results:
            reason_str = ", ".join(f"{k}={v}" for k, v in r["win_reasons"].items())
            f.write(f"| {r['opponent']} | {r['win_rate']:.1f}% | {r['wins']} | {r['losses']} | {r['stalls']} | {r['avg_win_turn']:.1f} | {reason_str} |\n")
        f.write(f"\n**Overall WR: {avg_wr:.1f}%** ({total_wins}W/{total_losses}L/{total_stalls}S)\n")
    print(f"\nLog: {LOG_PATH}")

if __name__ == "__main__":
    main()
