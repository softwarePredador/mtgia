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

# ═══════════════════════════════════════════
# DECK LOADING
# ═══════════════════════════════════════════

def load_deck(deck_id=6):
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT card_name, quantity, CAST(COALESCE(cmc,0) AS REAL) as cmc,
               COALESCE(functional_tag,'unknown') as functional_tag,
               type_line, is_commander
        FROM deck_cards WHERE deck_id=?
    """, (deck_id,)).fetchall()
    conn.close()
    commander = None
    deck = []
    for row in rows:
        qty = row["quantity"] or 1
        card = {"name": row["card_name"], "cmc": float(row["cmc"] or 0),
                "tag": row["functional_tag"] or "unknown",
                "type_line": row["type_line"] or "",
                "is_commander": bool(row["is_commander"])}
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

def get_card_effect(card):
    name = card.get("name", "")
    if name in KNOWN_CARDS:
        return KNOWN_CARDS[name].copy()
    tag = card.get("tag", "")
    if tag in TAG_EFFECTS:
        return TAG_EFFECTS[tag].copy()
    effect = card.get("effect", "")
    effect_map = {"ramp": "ramp_permanent", "removal": "remove_creature",
                  "board_wipe": "board_wipe", "wincon": "finisher", "draw": "draw_cards",
                  "counter": "counter", "land": "land"}
    if effect in effect_map:
        if effect == "ramp": return {"effect": "ramp_permanent", "mana_produced": 1}
        if effect == "wincon": return {"effect": "finisher"}
        if effect == "draw": return {"effect": "draw_cards", "count": 2}
        return {"effect": effect_map[effect]}
    if effect == "creature" or "creature" in card.get("type_line", "").lower():
        return {"effect": "creature", "power": card.get("power", 2)}
    return {"effect": "unknown"}

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
    def __init__(self): self.generic = self.white = self.blue = self.black = self.red = self.green = self.colorless = 0
    def total(self): return self.generic + self.white + self.blue + self.black + self.red + self.green + self.colorless
    def add_generic(self, n): self.generic += n
    def spend(self, amount):
        self.generic = max(0, self.generic - amount)
    def empty(self):
        self.generic = self.white = self.blue = self.black = self.red = self.green = self.colorless = 0

class Player:
    def shuffle(self, rng): rng.shuffle(self.library)

    def draw(self, n=1, rng=None):
        drawn = []
        for _ in range(n):
            if self.library:
                c = self.library.pop(0)
                self.hand.append(c)
                drawn.append(c)
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

    def available_mana(self):
        if self.mana_pool.total() == 0:
            lands = sum(1 for c in self.battlefield if c == "land" or (isinstance(c, dict) and c.get("effect") == "land"))
            ramp_mana = sum(c.get("mana_produced", 1) if isinstance(c, dict) else 1
                            for c in self.battlefield
                            if isinstance(c, dict) and c.get("effect") in ("ramp_permanent", "ramp_engine"))
            self.mana_pool.add_generic(lands + ramp_mana + self.treasures)
        return self.mana_pool.total()

    def is_alive(self): return self.life > 0

    def untapped_creatures(self):
        return [c for c in self.battlefield if isinstance(c, dict) and c.get("effect") == "creature"
                and not c.get("tapped", False) and not c.get("summoning_sick", False)]

    def creatures_for_blocking(self):
        return [c for c in self.battlefield if isinstance(c, dict) and c.get("effect") == "creature"
                and not c.get("tapped", False)]

    def has_counterspell(self):
        """v8: Check if player has a counterspell available."""
        return self.counters_available > 0

    def use_counterspell(self):
        if self.counters_available > 0:
            self.counters_available -= 1
            return True
        return False

# ═══════════════════════════════════════════
# STACK (v8)
# ═══════════════════════════════════════════

class StackItem:
    def __init__(self, card, controller, effect_data):
        self.card = card
        self.controller = controller
        self.effect_data = effect_data
        self.countered = False

class Stack:
    def __init__(self): self.items = []
    def push(self, card, controller, effect_data):
        self.items.append(StackItem(card, controller, effect_data))
    def resolve_top(self):
        if self.items:
            item = self.items.pop()
            if not item.countered:
                return item
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
    while not keep and mulligan_count < 3:
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
    lands = sum(1 for c in hand if c.get("tag") == "land" or c.get("effect") == "land" or "Land" in c.get("type_line", ""))
    return (2 <= lands <= 5), 7

def check_sbas(all_players):
    """v8: State-Based Actions after each spell resolution."""
    for p in all_players:
        if p.life <= 0:
            return True  # player died
        for name, dmg in p.commander_damage.items():
            if dmg >= 21:
                # Find the player who took this damage and kill them
                for op in all_players:
                    if op.name == name:
                        op.life = 0
                        return True
        if not p.library and not p.hand:
            p.life = 0
            return True
    return False

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
    score = threat_score(top_item.effect_data.get("effect", ""), top_item.card.get("name", ""),
                         top_item.controller, all_players, turn)

    for player in order:
        if not player.is_alive():
            continue
        if player.is_human:
            # Lorehold: use protection in response to high-threat spells
            if score >= 40:
                instants = [c for c in player.hand if is_instant(c) and player.available_mana() >= c["cmc"]]
                for c in instants:
                    eff = get_card_effect(c)
                    if eff.get("effect") in ("phase_out", "indestructible", "modal_boros_charm"):
                        if player.available_mana() >= c["cmc"]:
                            player.hand.remove(c)
                            player.mana_pool.spend(c["cmc"])
                            apply_effect_immediate(player, [p for p in all_players if p != player], c, turn, rng)
                            return True
        else:
            # v8.2: Smart counter decision based on threat score
            if counter_worth(score, player, rng):
                if player.use_counterspell():
                    stack.items[-1].countered = True
                    return True

    # No one responded — resolve
    item = stack.resolve_top()
    if item:
        controller = item.controller
        opponents = [p for p in all_players if p != controller]
        apply_effect_immediate(controller, opponents, item.card, turn, rng)
        if check_sbas(all_players):
            return True
    return False

    # Turn order starting from active player
    idx = all_players.index(active_player)
    order = []
    for i in range(len(all_players)):
        order.append(all_players[(idx + i) % len(all_players)])

    threat = stack.top_is_threat()

    for player in order:
        if not player.is_alive():
            continue
        if player.is_human:
            # Lorehold: check if we have instant response
            instants = [c for c in player.hand if is_instant(c) and player.available_mana() >= c["cmc"]]
            if instants and threat:
                # Use protection in response to threatening spell
                for c in instants:
                    eff = get_card_effect(c)
                    if eff.get("effect") in ("phase_out", "indestructible", "modal_boros_charm"):
                        if player.available_mana() >= c["cmc"]:
                            player.hand.remove(c)
                            player.mana_pool.spend(c["cmc"])
                            apply_effect_immediate(player, [p for p in all_players if p != player], c, turn, rng)
                            return True
        else:
            # Opponent AI: counter threatening spells if possible
            if threat and player.has_counterspell():
                if player.use_counterspell():
                    stack.items[-1].countered = True
                    return True

    # No one responded — resolve top
    item = stack.resolve_top()
    if item:
        controller = item.controller
        opponents = [p for p in all_players if p != controller]
        apply_effect_immediate(controller, opponents, item.card, turn, rng)
        # Check SBAs after resolution
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
            return 100  # 2nd cast = instant win, MUST counter
        return 70  # 1st cast = strong threat, sets up win

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
        if mana >= cost:
            already_there = any(isinstance(c, dict) and c.get("name") == cmd.get("name") for c in player.battlefield)
            if not already_there:
                player.command_zone.pop(0)
                cmd_copy = dict(cmd)
                haste = cmd.get("haste") or "Haste" in cmd.get("type_line", "")
                cmd_copy["summoning_sick"] = not haste
                cmd_copy["haste"] = haste
                player.battlefield.append(cmd_copy)
                player.mana_pool.spend(cost)
                player.commander_tax += 2
                mana -= cost

    # 2. Ramp (main phase only)
    if is_main_phase:
        ramp_cards = [c for c in player.hand if c["cmc"] <= mana and get_card_effect(c).get("effect") in ("ramp_permanent", "ramp_engine", "ramp_ritual")]
        for c in ramp_cards[:2]:
            if c in player.hand and c["cmc"] <= mana:
                player.hand.remove(c)
                mana -= c["cmc"]
                eff = get_card_effect(c)
                if eff.get("effect") == "ramp_ritual":
                    mana += eff.get("mana_produced", 3)
                    player.graveyard.append(c)
                else:
                    player.battlefield.append(eff)

    # 3. Cast spells to stack
    castable = [c for c in player.hand if c["cmc"] <= mana]
    # v8: Miracle check for Lorehold
    if player.is_human:
        lorehold_on_board = any(isinstance(c, dict) and c.get("name") == "Lorehold, the Historian" for c in player.battlefield)
        for c in castable[:]:
            if (is_sorcery(c) or "Instant" in c.get("type_line", "")) and not is_main_phase:
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
            if c in player.hand and c["cmc"] <= player.available_mana():
                player.hand.remove(c)
                player.mana_pool.spend(c["cmc"])
                eff = get_card_effect(c)
                stack.push(c, player, eff)
                priority_round(player, all_players, stack, turn, rng)
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)
                return

    # Other spells: 2 per phase max
    remaining = sorted([c for c in castable if c["cmc"] <= player.available_mana()], key=lambda c: c["cmc"])
    played = 0
    for c in remaining:
        if played >= 2: break
        if c in player.hand and c["cmc"] <= player.available_mana():
            eff = get_card_effect(c)
            if eff.get("effect") == "creature":
                if not is_main_phase: continue  # creatures only in main phase
                player.hand.remove(c)
                player.mana_pool.spend(c["cmc"])
                c_copy = dict(c)
                c_copy["summoning_sick"] = True
                c_copy["tapped"] = False
                player.battlefield.append(c_copy)
                played += 1
            else:
                player.hand.remove(c)
                player.mana_pool.spend(c["cmc"])
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

def apply_effect_immediate(player, opponents, card, turn, rng):
    """v8: Apply card effect (called when spell resolves from stack)."""
    effect_data = get_card_effect(card)
    effect = effect_data.get("effect", "unknown")

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
                t = rng.choice(targets)
                opp.battlefield.remove(t)
                if t.get("is_commander"):
                    opp.command_zone.append(t)
                else:
                    opp.graveyard.append(t)
                break
        player.graveyard.append(card)
    elif effect == "board_wipe":
        for p in [player] + list(opponents):
            survivors = []
            for c in p.battlefield:
                if isinstance(c, dict) and c.get("effect") == "creature":
                    # v8: indestructible per-creature
                    if c.get("indestructible"):
                        survivors.append(c)
                        continue
                    if c.get("is_commander"):
                        p.command_zone.append(c)
                    else:
                        p.graveyard.append(c)
                else:
                    survivors.append(c)
            p.battlefield = survivors
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
    elif effect == "modal_boros_charm":
        # v8: Choose mode based on context
        # If there's a board wipe coming or on the stack, use indestructible
        in_combat = any(o.is_alive() for o in opponents)
        if player.indestructible:  # already protected
            # Use double strike in combat
            for c in player.battlefield:
                if isinstance(c, dict) and c.get("effect") == "creature":
                    c["double_strike"] = True
                    c["power"] = c.get("power", 2) * 2  # effectively double damage
        else:
            # Default: indestructible (most valuable)
            player.indestructible = True
        player.graveyard.append(card)
    elif effect == "approach":
        player.approach_count += 1
        player.life = min(40, player.life + 7)
        # v8.1: THREAT — all opponents now know Approach was cast
        player.threat_level += 50  # massive threat spike
        for opp in opponents:
            if player.name not in opp.approach_revealed:
                opp.approach_revealed.append(player.name)
        if player.approach_count >= 2:
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
                opp.life -= dmg_each
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
            for opp in alive_opps: opp.life -= dmg // len(alive_opps)
        player.graveyard.append(card)
    elif effect == "pump_all":
        kw = effect_data.get("keywords", [])
        for c in player.battlefield:
            if isinstance(c, dict) and c.get("effect") == "creature":
                c["power"] = c.get("power", 2) * 2
                if "flying" in kw: c["flying"] = True
                if "double_strike" in kw: c["double_strike"] = True
                if "lifelink" in kw: c["lifelink"] = True
                if "indestructible" in kw: c["indestructible"] = True
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
                rng.choice(alive_opps).life -= total_power
        player.graveyard.append(card)
    elif effect == "exile_value":
        # Dance with Calamity — exile top X, play for free
        X = max(3, player.available_mana() // 2)
        player.draw(min(X, 3), rng)
        player.graveyard.append(card)
    elif effect == "redirect_removal":
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
                opp.life -= total_damage
        
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
                            opp.life -= total_damage
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
                        opp.life -= dmg_each
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
        removals = [c for c in opp.hand if get_card_effect(c).get("effect") in ("remove_creature",) and opp.available_mana() >= c["cmc"]]
        if removals and rng.random() < 0.3:
            c = rng.choice(removals)
            if c in opp.hand and opp.available_mana() >= c["cmc"]:
                opp.hand.remove(c)
                opp.mana_pool.spend(c["cmc"])
                # Remove one attacker
                if attackers:
                    target = rng.choice(attackers)
                    attackers.remove(target)
                    attacker.battlefield.remove(target)
                    if target.get("is_commander"):
                        attacker.command_zone.append(target)
                    else:
                        attacker.graveyard.append(target)

    if not attackers: return

    # v8.1: Threat-based targeting
    # If any opponent has approach_revealed, focus fire that player
    archenemy = None
    for opp in alive_defenders:
        if attacker.name in opp.approach_revealed and opp.is_alive():
            archenemy = opp
            break
    
    if archenemy and attacker != archenemy:
        target = archenemy  # FOCUS FIRE on Approach caster
    elif attacker.is_human and attacker.threat_level > 30:
        pass  # Lorehold is archenemy — opponents already focusing us
    elif attacker.strategy in ("aggro", "rush"):
        target = min(alive_defenders, key=lambda o: o.life)
    elif attacker.strategy == "control":
        threat_targets = [o for o in alive_defenders if o.threat_level > 20]
        target = threat_targets[0] if threat_targets else max(alive_defenders, key=lambda o: o.life)
    else:
        target = max(alive_defenders, key=lambda o: o.life)

    # Declare blockers
    blockers = []
    for a in attackers:
        for opp in opponents:
            if opp.is_alive() and opp != attacker:
                available = [c for c in opp.creatures_for_blocking() if c not in blockers]
                if available and rng.random() < 0.5:
                    bc = [c for c in available if not c.get("flying") or a.get("flying")]
                    if bc:
                        blockers.append(rng.choice(bc))
                        break
        if len(blockers) >= len(attackers): break

    # ── FIRST STRIKE DAMAGE (v8: FIX — 1x per step, not 2x then 1x = 3x) ──
    first_strikers = [a for a in attackers if a.get("first_strike") or a.get("double_strike")]
    if first_strikers:
        for a in first_strikers:
            a_pwr = a.get("power", 2)
            blocked = False
            for b in blockers[:]:
                if b in target.battlefield:
                    if a_pwr >= b.get("power", 2):
                        target.battlefield.remove(b)
                        target.graveyard.append(b)
                        blockers.remove(b)
                    blocked = True
                    break
            if not blocked:
                target.life -= a_pwr
                # v8: lifelink
                if a.get("lifelink"):
                    attacker.life = min(40, attacker.life + a_pwr)
                if a.get("is_commander") and a.get("owner") == attacker.name:
                    attacker.commander_damage[target.name] += a_pwr

    blockers = [b for b in blockers if b in target.battlefield]

    # ── REGULAR COMBAT DAMAGE ──
    for a in attackers:
        a_pwr = a.get("power", 2)
        blocked = False
        for b in blockers[:]:
            if b in target.battlefield:
                if a_pwr >= b.get("power", 2):
                    target.battlefield.remove(b)
                    target.graveyard.append(b)
                    blockers.remove(b)
                blocked = True
                break
        if not blocked:
            target.life -= a_pwr
            if a.get("lifelink"):
                attacker.life = min(40, attacker.life + a_pwr)
            if a.get("is_commander") and a.get("owner") == attacker.name:
                attacker.commander_damage[target.name] += a_pwr

    # Check for commander damage kill
    for name, dmg in attacker.commander_damage.items():
        if dmg >= 21:
            for opp in opponents:
                if opp.name == name: opp.life = 0

def play_turn_v8(player, opponents, all_players, turn, rng, stack):
    """v8: Full turn with priority windows between phases."""
    player.mana_pool.empty()
    player.lands_played_this_turn = 0
    player.indestructible = False

    # ── UNTAP ──
    for c in player.battlefield:
        if isinstance(c, dict): c["tapped"] = False
    # Return phased out permanents (v7 fix: should be upkeep, keeping simple here)
    player.battlefield.extend(player.phased_out)
    player.phased_out = []
    player.life_cant_change = False
    player.protection_from_everything = False

    # ── UPKEEP (v8.3: The One Ring burden = draw 1 per turn if on board) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and c.get("burden"):
            for _ in range(sum(1 for _ in player.battlefield if isinstance(_, dict) and _.get("effect") == "draw_engine")):
                player.draw(1, rng)

        # ── DRAW ──
        player.draw(1, rng)
        if not player.library and not player.hand:
            player.life = 0; return

        # v8.3: Track if Approach is in hand or was drawn
        for c in player.hand:
            if c.get("name") == "Approach of the Second Sun":
                approach_found = True

    # v8: MIRACLE check
    if player.is_human and player.hand:
        lorehold_on_board = any(isinstance(c, dict) and c.get("name") == "Lorehold, the Historian" for c in player.battlefield)
        last_drawn = player.hand[-1] if player.hand else None
        if last_drawn and (is_sorcery(last_drawn) or "Instant" in last_drawn.get("type_line", "")):
            miracle_cost = 2  # Lorehold gives miracle {2}
            if last_drawn.get("name") == "Reforge the Soul":
                miracle_cost = 2  # 1R but simplified
            mana = player.available_mana()
            if mana >= miracle_cost and lorehold_on_board:
                player.hand.remove(last_drawn)
                player.mana_pool.spend(miracle_cost)
                stack.push(last_drawn, player, get_card_effect(last_drawn))
                while not stack.empty():
                    priority_round(player, all_players, stack, turn, rng)

    # ── PRECOMBAT MAIN ──
    total_mana = player.available_mana()
    lands_in_hand = [c for c in player.hand if c.get("effect") == "land" or c.get("tag") == "land" or "Land" in c.get("type_line", "")]
    if lands_in_hand and player.lands_played_this_turn < player.max_lands_per_turn:
        player.hand.remove(lands_in_hand[0])
        player.battlefield.append("land")
        player.lands_played_this_turn += 1
    cast_spells_v8(player, opponents, all_players, turn, "precombat_main", stack, rng)
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
        if check_sbas(all_players): return

    # ── POSTCOMBAT MAIN ──
    total_mana = player.available_mana()
    cast_spells_v8(player, opponents, all_players, turn, "postcombat_main", stack, rng)
    if check_sbas(all_players): return


    # ── END STEP (v8.3) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and not c.get("burden"):
            player.draw(1, rng)
    
    # ── OPPONENT END STEP INTERACTION (NEW) ──
    # All opponents can cast instants on this player's end step
    for opp in opponents:
        if not opp.is_alive(): continue
        instants_in_hand = [c for c in opp.hand if is_instant(c) and opp.available_mana() >= c["cmc"]]
        for c in instants_in_hand[:1]:  # 1 instant per opponent per end step
            if opp.available_mana() >= c["cmc"]:
                opp.hand.remove(c)
                opp.mana_pool.spend(c["cmc"])
                apply_effect_immediate(opp, [p for p in all_players if p != opp], c, turn, rng)


    # ── CLEANUP ──
    while len(player.hand) > 7:
        worst = max(player.hand, key=lambda c: c.get("cmc", 0))
        player.hand.remove(worst)
        player.graveyard.append(worst)

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
            if player.approach_count >= 2:
                return ("win" if player.is_human else "loss"), turn, "approach"
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
            if player.approach_count >= 2:
                return ("win" if player.is_human else "loss"), turn, "approach"
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
        rows = conn.execute("SELECT * FROM learned_decks WHERE commander NOT LIKE '%Lorehold%' ORDER BY id DESC LIMIT 12").fetchall()
        conn.close()
        decks = []
        for row in rows:
            try:
                card_data = json.loads(row["card_list"]) if row["card_list"] else []
            except:
                card_data = []
            deck = []
            for c in card_data:
                if isinstance(c, dict):
                    name = c.get("name", "?")
                    cmc = float(c.get("cmc", 3))
                    tl = c.get("type_line", "")
                    role = c.get("role", c.get("category", "creature"))
                    effect = "creature"; tag = "creature"
                    if role == "land": effect = "land"; tag = "land"; tl = tl or "Land"
                    elif role in ("ramp","rock"): effect = "ramp"; tag = "ramp"
                    elif role in ("removal","sweeper"): effect = "removal"; tag = "removal"
                    elif role == "board_wipe": effect = "board_wipe"; tag = "board_wipe"
                    elif role in ("draw","cantrip","wheel"): effect = "draw"; tag = "draw"
                    elif role in ("counterspell","counter"): effect = "counter"; tag = "counter"; tl = tl or "Instant"
                    elif role == "tutor": effect = "tutor"; tag = "tutor"
                    elif role == "protection": effect = "protection"; tag = "protection"
                    elif role in ("wincon","combo_piece"): effect = "wincon"; tag = "wincon"
                    deck.append({"name": name, "cmc": cmc, "tag": tag, "effect": effect,
                                 "power": max(1, int(cmc)) if effect == "creature" else 0,
                                 "type_line": tl, "is_commander": c.get("is_commander", False)})
            while len(deck) < 99:
                deck.append({"name": "Filler", "cmc": 3, "tag": "creature", "effect": "creature", "power": 2, "type_line": "Creature"})
            decks.append({
                "name": f"{row['commander']} (real)", "archetype": row["archetype"] or "midrange",
                "built_deck": deck,
                "commander_name": row["commander"],
                "strategy": (row["archetype"] or "midrange").split()[0].lower() if row["archetype"] else "midrange",
                "life": 40, "lands": sum(1 for c in deck if c.get("effect") == "land"),
                "ramp": sum(1 for c in deck if c.get("effect") in ("ramp",)),
                "removal": sum(1 for c in deck if c.get("effect") in ("removal", "board_wipe")),
                "counters": sum(1 for c in deck if c.get("effect") == "counter"),
                "creatures": sum(1 for c in deck if c.get("effect") == "creature"),
                "avg_cmc": sum(c.get("cmc", 3) for c in deck) / max(1, len(deck)),
                "is_real": True,
            })
        return decks
    except Exception as e:
        print(f"load_learned_opponents: {e}")
        return []


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
        print(f"\nUsing {len(learned)} REAL learned opponent decks")
    else:
        opponent_sources = OPPONENT_ARCHETYPES
        print(f"\nUsing {len(OPPONENT_ARCHETYPES)} generic archetype profiles")

    GAMES = 50
    rng = random.Random(42)

    results = []
    total_wins = total_losses = total_stalls = 0

    print(f"\n{GAMES} games vs each of {len(opponent_sources)} archetypes (4-player)...\n")

    for profile in opponent_sources:
        wins = losses = stalls = 0
        win_turns = []
        win_reasons = defaultdict(int)

        for g in range(GAMES):
            others = [p for p in opponent_sources if p != profile]
            picked = [profile] + rng.sample(others, 2)
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
        f.write(f"Opponents: {len(opponent_sources)} ({'real' if learned else 'generic'})\n\n")
        f.write(f"| Opponent | WR | Wins | Losses | Stalls | Avg T | Reasons |\n")
        f.write(f"|:---------|----:|-----:|-------:|-------:|------:|:--------|\n")
        for r in results:
            reason_str = ", ".join(f"{k}={v}" for k, v in r["win_reasons"].items())
            f.write(f"| {r['opponent']} | {r['win_rate']:.1f}% | {r['wins']} | {r['losses']} | {r['stalls']} | {r['avg_win_turn']:.1f} | {reason_str} |\n")
        f.write(f"\n**Overall WR: {avg_wr:.1f}%** ({total_wins}W/{total_losses}L/{total_stalls}S)\n")
    print(f"\nLog: {LOG_PATH}")

if __name__ == "__main__":
    main()
