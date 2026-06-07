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

DB = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
KNOWLEDGE_DIR = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge"
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
            )
            if card.get(keyword)
        ],
        "is_commander": bool(card.get("is_commander")),
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


def enrich_card(card):
    """Preserve imported metadata and expose combat keywords as booleans."""
    enriched = dict(card)
    keyword_text = " ".join(enriched.get("keywords", []))
    keyword_text += " " + str(enriched.get("oracle_text", ""))
    normalized = keyword_text.lower().replace(" ", "_")
    for keyword in (
        "flying",
        "reach",
        "trample",
        "deathtouch",
        "first_strike",
        "double_strike",
        "lifelink",
        "indestructible",
    ):
        if keyword in normalized:
            enriched[keyword] = True
    return enriched


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
        return normalized

    if "counter target" in text:
        normalized["effect"] = "counter"
        normalized["instant"] = True
        return normalized

    if re.search(r"\b(destroy|exile)\s+target\b", text):
        normalized["effect"] = (
            "remove_creature" if "target creature" in text else "remove_permanent"
        )
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
    if name in KNOWN_CARDS:
        return normalize_effect_by_oracle(card, KNOWN_CARDS[name].copy())
    tag = card.get("tag", "")
    if tag in TAG_EFFECTS:
        return normalize_effect_by_oracle(card, TAG_EFFECTS[tag].copy())
    effect = card.get("effect", "")
    effect_map = {"ramp": "ramp_permanent", "removal": "remove_creature",
                  "board_wipe": "board_wipe", "wincon": "finisher", "draw": "draw_cards",
                  "counter": "counter", "land": "land"}
    if effect in effect_map:
        if effect == "ramp": return normalize_effect_by_oracle(card, {"effect": "ramp_permanent", "mana_produced": 1})
        if effect == "wincon": return normalize_effect_by_oracle(card, {"effect": "finisher"})
        if effect == "draw": return normalize_effect_by_oracle(card, {"effect": "draw_cards", "count": 2})
        return normalize_effect_by_oracle(card, {"effect": effect_map[effect]})
    if "land" in card.get("type_line", "").lower():
        return {"effect": "land"}
    if effect == "creature" or "creature" in card.get("type_line", "").lower():
        return normalize_effect_by_oracle(card, {"effect": "creature", "power": card.get("power", 2)})
    return normalize_effect_by_oracle(card, {"effect": "unknown"})

def is_instant(card):
    """v8: Check if a card can be cast at instant speed."""
    name = card.get("name", "")
    if name in KNOWN_CARDS and KNOWN_CARDS[name].get("instant"):
        return True
    tl = card.get("type_line", "")
    if "Instant" in tl: return True
    return False

def is_sorcery(card):
    return "Sorcery" in card.get("type_line", "")

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
        self.approach_count = 0
        self.treasures = 0
        self.draw_engines = 0
        self.copy_engines = 0
        self.counters_available = 0
        self.threat_level = 0  # v8.1: archenemy tracking
        self.approach_revealed = []  # v8.1: opponents who know approach was cast
        self.eliminated = False
        self.win_reason = None
        self.cards_drawn_this_turn = 0

    def refresh_mana_sources(self, turn=None):
        """Untap mana sources once for this player's turn."""
        self.mana_pool.empty()
        sources = [
            source
            for source in self.battlefield
            if source == "land"
            or (
                isinstance(source, dict)
                and source.get("effect") in ("land", "ramp_permanent", "ramp_engine")
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
        return [c for c in self.battlefield if isinstance(c, dict) and c.get("effect") == "creature"
                and not c.get("tapped", False) and not c.get("summoning_sick", False)]

    def creatures_for_blocking(self):
        return [c for c in self.battlefield if isinstance(c, dict) and c.get("effect") == "creature"
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
        emit_replay_event(
            "spell_countered",
            player=self.name,
            counter=counter.get("name", "?"),
            target=(target_card or {}).get("name", "?"),
            cost=cost,
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
        if not p.library and not p.hand and not p.eliminated:
            p.life = 0
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="deck_out")
            return True
    return False


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
        if player != top_item.controller and top_item.controller.silenced_opponents:
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
        total_stolen = sum(len([c for c in o.battlefield if isinstance(c, dict) and c.get("effect") == "creature"])
                          for o in all_players if o != controller and o.is_alive())
        if total_stolen > 10:
            return 90
        return 65

    # ── WINCON SETUP ──
    if effect_name == "pump_all":
        creatures = [c for c in controller.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
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

    # ── PROTECTION ──
    if effect_name in ("phase_out", "indestructible"):
        # Cast in response to a wipe on the stack? High value
        return 30  # protection itself isn't threatening, but enables threats

    if effect_name == "finisher":
        return 60  # generic finisher, always dangerous

    if effect_name == "silence_opponents":
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
    player.indestructible = False


def grant_creatures_until_eot(player, *, keywords=(), power_multiplier=None):
    creatures = [
        card
        for card in player.battlefield
        if isinstance(card, dict) and card.get("effect") == "creature"
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
                haste = cmd.get("haste") or "Haste" in cmd.get("type_line", "")
                cmd_copy["summoning_sick"] = not haste
                cmd_copy["haste"] = haste
                player.battlefield.append(cmd_copy)
                player.spend_card_mana(cmd, player.commander_tax)
                player.commander_tax += 2
                emit_replay_event(
                    "commander_cast",
                    player=player.name,
                    card=cmd.get("name", "?"),
                    cost=cost,
                    turn=turn,
                    phase=phase,
                )
                mana = player.available_mana()

    # 2. Ramp (main phase only)
    if is_main_phase:
        ramp_cards = [c for c in player.hand if player.can_pay_card(c) and get_card_effect(c).get("effect") in ("ramp_permanent", "ramp_engine", "ramp_ritual")]
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
                    cmc=c.get("cmc", 0),
                    turn=turn,
                    phase=phase,
                    role="ramp",
                )
                if eff.get("effect") == "ramp_ritual":
                    player.mana_pool.add_generic(eff.get("mana_produced", 3))
                    player.graveyard.append(c)
                else:
                    permanent = enrich_card({**c, **eff})
                    player.battlefield.append(permanent)
                    colors = source_colors(permanent)
                    player.mana_pool.add(colors[0], permanent.get("mana_produced", 1))
                mana = player.available_mana()

    # 3. Cast spells to stack
    castable = [
        c for c in player.hand
        if player.can_pay_card(c) and get_card_effect(c).get("effect") != "counter"
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
                    cmc=c.get("cmc", 0),
                    threat_score=scored[0][1],
                    turn=turn,
                    phase=phase,
                    role="high_threat",
                )
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
                c_copy = enrich_card(c)
                c_copy["summoning_sick"] = True
                c_copy["tapped"] = False
                player.battlefield.append(c_copy)
                emit_replay_event(
                    "creature_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    cmc=c.get("cmc", 0),
                    power=c_copy.get("power"),
                    toughness=c_copy.get("toughness"),
                    turn=turn,
                    phase=phase,
                )
                played += 1
            else:
                player.hand.remove(c)
                player.spend_card_mana(c)
                emit_replay_event(
                    "spell_cast",
                    player=player.name,
                    card=c.get("name", "?"),
                    effect=eff.get("effect", "unknown"),
                    cmc=c.get("cmc", 0),
                    turn=turn,
                    phase=phase,
                    role="normal",
                )
                stack.push(c, player, eff)
                played += 1

    
    # ── ESPER SENTINEL TRIGGER (noncreature spell cast) ──
    for opp in opponents:
        for c in opp.battlefield:
            if isinstance(c, dict) and c.get("effect") == "draw_engine" and c.get("trigger") == "opponent_spell":
                # Opponent may pay 1. 50% chance they don't
                if random.random() < 0.5:
                    opp.draw(1, rng)  # Esper owner draws

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
        effect=effect,
        turn=turn,
    )

    if effect == "land": pass
    elif effect == "ramp_permanent": player.battlefield.append(effect_data)
    elif effect == "ramp_ritual":
        player.mana_pool.add_generic(effect_data.get("mana_produced", 3))
        player.graveyard.append(card)
    elif effect == "ramp_engine":
        player.battlefield.append(effect_data)
        player.treasures += 1
    elif effect == "draw_engine":
        player.battlefield.append(effect_data)
        player.draw_engines += 1
        player.draw(1, rng)
    elif effect == "draw_cards":
        n = effect_data.get("count", 2)
        player.draw(n, rng)
        player.graveyard.append(card)
    elif effect in ("remove_creature", "remove_permanent", "remove_artifact_or_3dmg"):
        for opp in opponents:
            targets = [c for c in opp.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
            if targets:
                t = max(
                    targets,
                    key=lambda target: (
                        bool(target.get("is_commander")),
                        int(target.get("power") or 0),
                        int(target.get("toughness") or 0),
                        int(target.get("cmc") or 0),
                    ),
                )
                emit_replay_event(
                    "removal_resolved",
                    player=player.name,
                    card=card.get("name", "?"),
                    target_player=opp.name,
                    target=t.get("name", "?"),
                    target_power=t.get("power"),
                    target_toughness=t.get("toughness"),
                    available_targets=len(targets),
                    turn=turn,
                )
                opp.battlefield.remove(t)
                if t.get("is_commander"):
                    opp.command_zone.append(t)
                else:
                    opp.graveyard.append(t)
                break
        player.graveyard.append(card)
    elif effect == "board_wipe":
        destroyed = 0
        protected = 0
        creatures_seen = 0
        unprotected_seen = 0
        for p in [player] + list(opponents):
            survivors = []
            for c in p.battlefield:
                if isinstance(c, dict) and c.get("effect") == "creature":
                    creatures_seen += 1
                    # v8: indestructible per-creature
                    if c.get("indestructible"):
                        survivors.append(c)
                        protected += 1
                        continue
                    unprotected_seen += 1
                    if c.get("is_commander"):
                        p.command_zone.append(c)
                    else:
                        p.graveyard.append(c)
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
    elif effect == "silence_opponents":
        player.battlefield.append(effect_data)
        player.silenced_opponents = True
    elif effect == "indestructible":
        grant_creatures_until_eot(player, keywords=("indestructible",))
        player.indestructible = True
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
            creatures = [c for c in opp.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
            for c in creatures:
                total_power += c.get("power", 2)
            opp.battlefield = [c for c in opp.battlefield if not (isinstance(c, dict) and c.get("effect") == "creature")]
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
            elif token_count == "lands": token_count = sum(1 for c in player.battlefield if c == "land")
        token_count = int(token_count)
        for _ in range(min(token_count, 20)):
            player.battlefield.append({"name": "Token", "cmc": 0, "tag": "token", "effect": "creature", "power": effect_data.get("token_power", 2), "summoning_sick": False})
        player.graveyard.append(card)
    elif effect == "overload_recursion":
        spells = [c for c in player.graveyard if isinstance(c, dict) and c.get("cmc", 0) > 0]
        if player.copy_engines > 0: spells = spells * 2
        dmg = len(spells) * 3
        alive_opps = [o for o in opponents if o.is_alive()]
        if alive_opps:
            for opp in alive_opps: deal_damage(opp, dmg // len(alive_opps))
        player.graveyard.append(card)
    elif effect == "pump_all":
        kw = effect_data.get("keywords", [])
        combat_keywords = [
            keyword
            for keyword in ("flying", "double_strike", "lifelink", "indestructible")
            if keyword in kw
        ]
        power_multiplier = None if card.get("name") == "Akroma's Will" else 2
        grant_creatures_until_eot(
            player,
            keywords=combat_keywords,
            power_multiplier=power_multiplier,
        )
        if "indestructible" in combat_keywords:
            player.indestructible = True
        player.graveyard.append(card)
    elif effect == "copy_spell":
        player.battlefield.append(effect_data)
        player.copy_engines += 1
    elif effect == "tutor":
        target_type = effect_data.get("target", "any")
        found = None
        for c in player.library:
            if target_type == "any":
                found = c
                break
            elif target_type == "artifact_or_enchantment":
                # v8.3: Enlightened Tutor — finds Artifact or Enchantment by type_line
                tl = c.get("type_line", "")
                if ("Artifact" in tl or "Enchantment" in tl) and c.get("name") != "Approach of the Second Sun":
                    found = c
                    break
        if found:
            player.library.remove(found)
            player.hand.append(found)
        emit_replay_event(
            "tutor_resolved",
            player=player.name,
            card=card.get("name", "?"),
            target_type=target_type,
            found=found.get("name", "?") if found else None,
            turn=turn,
        )
        player.graveyard.append(card)
    elif effect == "topdeck_manipulation":
        player.battlefield.append(effect_data)
        player.draw(1, rng)
    elif effect == "loot":
        n = effect_data.get("count", 1)
        player.draw(n, rng)
        for _ in range(min(n, len(player.hand))):
            if player.hand:
                player.graveyard.append(player.hand.pop(rng.randint(0, len(player.hand) - 1)))
    elif effect == "finisher":
        creatures = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
        total_power = sum(c.get("power", 2) for c in creatures)
        if total_power > 0:
            alive_opps = [o for o in opponents if o.is_alive()]
            if alive_opps:
                deal_damage(rng.choice(alive_opps), total_power)
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
        player.battlefield.append(effect_data)
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
        creatures = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
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
        
        player.battlefield.append(dict(card))
        card["summoning_sick"] = False  # haste from combo

def combat_phase_v8(attacker, opponents, all_players, turn, rng, stack):
    creatures = attacker.untapped_creatures()
    if not creatures: return

    attackers = []
    for c in creatures:
        if not c.get("summoning_sick", False):
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
                if attackers:
                    target = max(
                        attackers,
                        key=lambda card: (
                            bool(card.get("is_commander")),
                            int(card.get("power") or 0),
                            int(card.get("toughness") or 0),
                            int(card.get("cmc") or 0),
                        ),
                    )
                    emit_replay_event(
                        "instant_removal",
                        player=opp.name,
                        card=c.get("name", "?"),
                        target_player=attacker.name,
                        target=target.get("name", "?"),
                        target_power=target.get("power"),
                        target_toughness=target.get("toughness"),
                        attackers_before=len(attackers),
                        turn=turn,
                    )
                    attackers.remove(target)
                    attacker.battlefield.remove(target)
                    if target.get("is_commander"):
                        attacker.command_zone.append(target)
                    else:
                        attacker.graveyard.append(target)

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
                    if isinstance(card, dict) and card.get("effect") == "creature"
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
                    if isinstance(card, dict) and card.get("effect") == "creature"
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
                    owner.battlefield.remove(creature)
                    owner.graveyard.append(creature)

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
        if isinstance(c, dict): c["tapped"] = False
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
    if not player.library and not player.hand:
        player.life = 0
        check_sbas(all_players)
        return

    # v8: MIRACLE check
    if player.is_human and drawn_for_turn and player.cards_drawn_this_turn == 1:
        lorehold_on_board = any(isinstance(c, dict) and c.get("name") == "Lorehold, the Historian" for c in player.battlefield)
        last_drawn = drawn_for_turn[-1]
        if last_drawn and (is_sorcery(last_drawn) or is_instant(last_drawn)):
            miracle_cost = 2  # Lorehold gives miracle {2}
            if last_drawn.get("name") == "Reforge the Soul":
                miracle_cost = 2  # 1R but simplified
            mana = player.available_mana()
            if mana >= miracle_cost and lorehold_on_board:
                player.hand.remove(last_drawn)
                player.spend_mana(miracle_cost)
                emit_replay_event(
                    "miracle_cast",
                    player=player.name,
                    card=last_drawn.get("name", "?"),
                    effect=get_card_effect(last_drawn).get("effect", "unknown"),
                    miracle_cost=miracle_cost,
                    turn=turn,
                )
                stack.push(last_drawn, player, get_card_effect(last_drawn))
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)

    # ── PRECOMBAT MAIN ──
    total_mana = player.available_mana()
    lands_in_hand = [c for c in player.hand if is_land(c)]  # v10.2
    if lands_in_hand and player.lands_played_this_turn < player.max_lands_per_turn:
        land = lands_in_hand[0]
        player.hand.remove(land)
        land_permanent = enrich_card({**land, "effect": "land"})
        player.battlefield.append(land_permanent)
        player.lands_played_this_turn += 1
        player.mana_pool.add(source_colors(land_permanent)[0], 1)
        emit_replay_event(
            "land_played",
            player=player.name,
            card=land.get("name", "?"),
            turn=turn,
        )
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
    if not player.silenced_opponents:
        for opp in opponents:
            if not opp.is_alive(): continue
            instants_in_hand = [c for c in opp.hand if is_instant(c) and opp.can_pay_card(c)]
            for c in instants_in_hand[:1]:  # 1 instant per opponent per end step
                if opp.can_pay_card(c):
                    opp.hand.remove(c)
                    opp.spend_card_mana(c)
                    emit_replay_event(
                        "end_step_instant",
                        player=opp.name,
                        card=c.get("name", "?"),
                        effect=get_card_effect(c).get("effect", "unknown"),
                        active_player=player.name,
                        turn=turn,
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
            play_turn_v8(player, others, all_players, turn, rng, stack)
            if not player.is_alive():
                continue
            # Check any explicit alternate-win state.
            for p in all_players:
                if p.has_won():
                    return ("win" if p is lorehold else "loss"), turn, p.win_reason
            if check_sbas(all_players):
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
            play_turn_v8(player, others, all_players, turn, rng, stack)
            if not player.is_alive():
                continue
            # Check any explicit alternate-win state.
            for p in all_players:
                if p.has_won():
                    return ("win" if p is lorehold else "loss"), turn, p.win_reason
            if check_sbas(all_players):
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

    if role == "land" or "land" in type_line:
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
    if "creature" in type_line or "token" in name:
        return "creature", "creature"
    if "instant" in type_line:
        return "spell", "instant"
    if "sorcery" in type_line:
        return "spell", "sorcery"
    return "creature", "creature"


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
        "type_line": imported.get("type_line") or ("Land" if effect == "land" else "Creature"),
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
