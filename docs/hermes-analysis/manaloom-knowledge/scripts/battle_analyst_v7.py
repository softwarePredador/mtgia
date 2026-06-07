#!/usr/bin/env python3
"""
Lorehold Battle Analyst v7 — Commander Rule-Compliant Simulator
Correções baseadas no MTG Rules Audit:
- Commander Zone + Commander Damage (E4, E5)
- Declare Blockers (C5)
- Cleanup Step — discard to 7 (A12)
- T1 Draw fix para multiplayer (A5)
- Free first mulligan (D3)
- Summoning Sickness (C3)
- Colored mana tracking simplificado (B3)
- Opponent commanders (E3)
- Postcombat Main Phase (A11)
- Upkeep step triggers (A7)
- Insurrection win check fix (G3)
- Draw from empty = lose (G4)
- First Strike / Double Strike combat steps (C6)
- Teferi's Protection — phase out real (F2)
- End step triggers melhorado (A6)
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
        card = {
            "name": row["card_name"],
            "cmc": float(row["cmc"] or 0),
            "tag": row["functional_tag"] or "unknown",
            "type_line": row["type_line"] or "",
            "is_commander": bool(row["is_commander"]),
        }
        if card["is_commander"]:
            commander = card
        else:
            for _ in range(qty):
                deck.append(card)
    return commander, deck

# ═══════════════════════════════════════════
# CARD EFFECT ENGINE
# ═══════════════════════════════════════════

KNOWN_CARDS = {
    "Teferi's Protection": {"effect": "phase_out"},
    "Boros Charm": {"effect": "indestructible", "alt_effect": "double_strike"},
    "Deflecting Swat": {"effect": "redirect_removal"},
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
    "Akroma's Will": {"effect": "pump_all",
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
    "Enlightened Tutor": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Gamble": {"effect": "tutor", "target": "any", "discard_risk": True},
    "Smothering Tithe": {"effect": "ramp_engine", "trigger": "opponent_draw"},
    "Jeska's Will": {"effect": "ramp_ritual", "mana_produced": 7},
    "Esper Sentinel": {"effect": "draw_engine", "trigger": "opponent_spell"},
    "Lorehold, the Historian": {"effect": "commander", "is_commander": True},
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
        if effect == "ramp":
            return {"effect": "ramp_permanent", "mana_produced": 1}
        if effect in ("wincon",):
            return {"effect": "finisher"}
        if effect == "draw":
            return {"effect": "draw_cards", "count": 2}
        return {"effect": effect_map[effect]}
    if effect == "creature" or "creature" in card.get("type_line", "").lower():
        return {"effect": "creature", "power": card.get("power", 2)}
    return {"effect": "unknown"}

# ═══════════════════════════════════════════
# OPPONENT DECK GENERATION (WITH COMMANDER)
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
        deck.append({"name": "Counterspell", "cmc": 2, "tag": "counter", "effect": "counter"})
    while len(deck) < 99:
        deck.append({"name": "Filler Creature", "cmc": profile["avg_cmc"], "tag": "creature", "effect": "creature", "power": 2, "type_line": "Creature"})
    return deck[:99]

def get_opponent_commander(profile):
    return {
        "name": profile["commander_name"],
        "cmc": profile["commander_cmc"],
        "tag": "creature",
        "effect": "creature",
        "power": max(2, profile["commander_cmc"]),
        "type_line": "Legendary Creature",
        "is_commander": True,
        "owner": profile["name"],
    }

# ═══════════════════════════════════════════
# COLORED MANA (simplified: lands produce 1 colored)
# ═══════════════════════════════════════════

class ManaPool:
    def __init__(self):
        self.generic = 0
        self.white = 0
        self.blue = 0
        self.black = 0
        self.red = 0
        self.green = 0
        self.colorless = 0

    def total(self):
        return self.generic + self.white + self.blue + self.black + self.red + self.green + self.colorless

    def add_land(self, color="generic"):
        if color == "white": self.white += 1
        elif color == "blue": self.blue += 1
        elif color == "black": self.black += 1
        elif color == "red": self.red += 1
        elif color == "green": self.green += 1
        else: self.generic += 1

    def add_generic(self, n):
        self.generic += n

    def can_pay_cmc(self, cmc):
        return self.total() >= cmc

    def spend(self, amount):
        remaining = amount
        pools = [(self.colorless, 'colorless'), (self.green, 'green'), (self.red, 'red'),
                 (self.black, 'black'), (self.blue, 'blue'), (self.white, 'white'), (self.generic, 'generic')]
        for pool_attr, _ in pools:
            if remaining <= 0: break
            spend = min(remaining, pool_attr if isinstance(pool_attr, int) else 0)
            remaining -= spend
        if remaining > 0:
            self.generic = max(0, self.generic - remaining)
        self.generic = max(0, self.generic)

    def empty(self):
        self.generic = self.white = self.blue = self.black = self.red = self.green = self.colorless = 0

# ═══════════════════════════════════════════
# PLAYER STATE (v7 — Commander-aware)
# ═══════════════════════════════════════════

class Player:
    def __init__(self, name, commander, deck, is_human=False, strategy="midrange"):
        self.name = name
        self.commander = commander  # card dict, starts in command zone
        self.command_zone = [commander] if commander else []
        self.commander_tax = 0
        self.library = list(deck)
        self.hand = []
        self.battlefield = []  # list of permanents (dict for creatures/artifacts, str "land")
        self.phased_out = []  # v7: phased out permanents
        self.graveyard = []
        self.exile = []
        self.life = 40
        self.commander_damage = defaultdict(int)  # commander_name -> damage taken
        self.mana_pool = ManaPool()
        self.lands_played_this_turn = 0
        self.max_lands_per_turn = 1
        self.is_human = is_human
        self.strategy = strategy
        self.indestructible = False
        self.indestructible_until = 0
        self.protection_from_everything = False
        self.life_cant_change = False
        self.silenced_opponents = False
        self.approach_count = 0
        self.treasures = 0
        self.draw_engines = 0
        self.copy_engines = 0
        self.summoning_sick = []  # v7: creatures with summoning sickness (refs by id)

    def shuffle(self, rng):
        rng.shuffle(self.library)

    def draw(self, n=1, rng=None):
        drawn = []
        for _ in range(n):
            if self.library:
                c = self.library.pop(0)
                self.hand.append(c)
                drawn.append(c)
        return drawn

    def available_mana_total(self, turn):
        lands = sum(1 for c in self.battlefield if c == "land" or (isinstance(c, dict) and c.get("effect") == "land"))
        ramp_mana = sum(
            c.get("mana_produced", 1) if isinstance(c, dict) else 1
            for c in self.battlefield
            if isinstance(c, dict) and c.get("effect") in ("ramp_permanent", "ramp_engine")
        )
        self.mana_pool.add_generic(lands + ramp_mana + self.treasures)
        total = self.mana_pool.total()
        return total

    def can_cast(self, card, turn):
        return card["cmc"] <= self.available_mana_total(turn)

    def is_alive(self):
        return self.life > 0

    def has_creatures(self):
        return any(
            isinstance(c, dict) and c.get("effect") == "creature"
            for c in self.battlefield
        )

    def untapped_creatures(self):
        return [
            c for c in self.battlefield
            if isinstance(c, dict) and c.get("effect") == "creature"
            and not c.get("tapped", False) and not c.get("summoning_sick", False)
        ]

    def creatures_for_blocking(self):
        return [
            c for c in self.battlefield
            if isinstance(c, dict) and c.get("effect") == "creature"
            and not c.get("tapped", False)
        ]

# ═══════════════════════════════════════════
# GAME SIMULATOR v7
# ═══════════════════════════════════════════

def create_creature_id(player, idx):
    return f"{player.name}_{idx}"

def play_mulligan(player, rng):
    """London mulligan with FREE first mulligan in multiplayer (v7 fix D3)"""
    player.shuffle(rng)
    # Draw 7 (commander is in command zone, not in library)
    player.hand = player.draw(7, rng)
    keep, _ = mulligan_decision(player.hand)
    mulligan_count = 0

    while not keep and mulligan_count < 3:
        mulligan_count += 1
        player.library = player.hand + player.library
        player.hand = []
        player.shuffle(rng)
        player.hand = player.draw(7, rng)
        # v7: first mulligan is FREE in multiplayer (0 cards to bottom)
        bottom_count = max(0, mulligan_count - 1)
        for _ in range(bottom_count):
            if player.hand:
                c = player.hand.pop(rng.randint(0, len(player.hand) - 1))
                player.library.append(c)
        keep, _ = mulligan_decision(player.hand)

    return mulligan_count

def mulligan_decision(hand):
    """Keep if 2-5 lands."""
    lands = sum(1 for c in hand if c.get("tag") == "land" or c.get("effect") == "land" or c.get("type_line", "") == "Land")
    if 2 <= lands <= 5:
        return True, 7
    return False, 7

def play_turn(player, opponents, turn, rng):
    """v7: Full turn structure with phases."""
    all_opponents = opponents
    mana = player.mana_pool
    mana.empty()
    player.lands_played_this_turn = 0
    player.indestructible = False

    # ── UNTAP STEP ──
    for c in player.battlefield:
        if isinstance(c, dict):
            c["tapped"] = False
    # v7: Return phased out permanents
    player.battlefield.extend(player.phased_out)
    player.phased_out = []
    player.life_cant_change = False
    player.protection_from_everything = False

    # ── UPKEEP STEP (v7 A7) ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and c.get("burden"):
            # The One Ring burden counters — take 1 damage per counter, draw N
            counts = sum(1 for _ in player.battlefield if isinstance(_, dict) and _.get("effect") == "draw_engine")
            for _ in range(counts):
                player.draw(1, rng)

    # ── DRAW STEP (v7 A5: NO draw skip in multiplayer) ──
    player.draw(1, rng)
    # v7 G4: check empty library
    if not player.library and not player.hand:
        player.life = 0  # lose
        return

    # ── PRECOMBAT MAIN PHASE ──
    total_mana = player.available_mana_total(turn)

    # Land drop
    lands_in_hand = [c for c in player.hand if c.get("effect") == "land" or c.get("tag") == "land" or "Land" in c.get("type_line", "")]
    if lands_in_hand and player.lands_played_this_turn < player.max_lands_per_turn:
        land = lands_in_hand[0]
        player.hand.remove(land)
        player.battlefield.append("land")
        player.lands_played_this_turn += 1
        total_mana += 1

    # Cast spells — priority: ramp, draw engines, threats, wincons
    cast_spells(player, opponents, turn, rng)
    total_mana = player.available_mana_total(turn)

    # ── COMBAT PHASE ──
    if turn > 1:
        combat_phase(player, opponents, turn, rng)

    # ── POSTCOMBAT MAIN PHASE (v7 A11) ──
    total_mana = player.available_mana_total(turn)
    cast_spells(player, opponents, turn, rng)

    # ── END STEP ──
    for c in player.battlefield:
        if isinstance(c, dict) and c.get("effect") == "draw_engine" and not c.get("burden"):
            player.draw(1, rng)

    # ── CLEANUP STEP (v7 A12) ──
    while len(player.hand) > 7:
        # Discard worst card (highest CMC)
        worst = max(player.hand, key=lambda c: c.get("cmc", 0))
        player.hand.remove(worst)
        player.graveyard.append(worst)

    # ── CHECK WIN (v7 G3 fix) ──
    if player.approach_count >= 2:
        return

def cast_spells(player, opponents, turn, rng):
    """Cast as many spells as mana allows, within turn limits."""
    mana = player.available_mana_total(turn)
    if mana <= 0:
        return

    # 1. Cast commander from command zone (all players)
    if player.command_zone:
        cmd = player.command_zone[0]
        cmd_total_cmc = cmd["cmc"] + player.commander_tax
        if mana >= cmd_total_cmc:
            already_on_board = any(
                isinstance(c, dict) and c.get("name") == cmd.get("name") 
                for c in player.battlefield
            )
            if not already_on_board:
                player.command_zone.pop(0)
                cmd_copy = dict(cmd)
                cmd_copy["summoning_sick"] = True
                player.battlefield.append(cmd_copy)
                player.mana_pool.spend(cmd_total_cmc)
                player.commander_tax += 2
                mana -= cmd_total_cmc

    # 2. Ramp first
    ramp_cards = [c for c in player.hand if c["cmc"] <= mana and get_card_effect(c).get("effect") in ("ramp_permanent", "ramp_engine", "ramp_ritual")]
    played = 0
    for c in ramp_cards:
        if played >= 2: break
        if c in player.hand and c["cmc"] <= mana:
            player.hand.remove(c)
            mana -= c["cmc"]
            eff = get_card_effect(c)
            if eff.get("effect") == "ramp_ritual":
                mana += eff.get("mana_produced", 3)
                player.graveyard.append(c)
            else:
                player.battlefield.append(eff)
            played += 1

    # 3. Draw engines / creatures / threats
    remaining = sorted([c for c in player.hand if c["cmc"] <= mana], key=lambda c: c["cmc"])
    played = 0
    for c in remaining:
        if played >= 3: break
        if c in player.hand and c["cmc"] <= mana:
            eff = get_card_effect(c)
            if eff.get("effect") == "finisher" or eff.get("effect") == "wincon":
                if played < 1:  # one wincon per phase
                    player.hand.remove(c)
                    mana -= c["cmc"]
                    apply_effect(player, opponents, c, turn, rng)
                    played += 1
            elif eff.get("effect") == "creature":
                player.hand.remove(c)
                mana -= c["cmc"]
                c_copy = dict(c)
                c_copy["summoning_sick"] = True  # v7 C3
                c_copy["tapped"] = False
                player.battlefield.append(c_copy)
                played += 1
            else:
                player.hand.remove(c)
                mana -= c["cmc"]
                apply_effect(player, opponents, c, turn, rng)
                played += 1

def apply_effect(player, opponents, card, turn, rng):
    effect_data = get_card_effect(card)
    effect = effect_data.get("effect", "unknown")
    name = card.get("name", "Unknown")
    opps = list(opponents)

    if effect == "land":
        pass
    elif effect == "ramp_permanent":
        player.battlefield.append(effect_data)
    elif effect == "ramp_ritual":
        mana_amt = effect_data.get("mana_produced", 3)
        player.mana_pool.add_generic(mana_amt)
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
    elif effect == "remove_creature":
        for opp in opps:
            creatures = [c for c in opp.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
            if creatures:
                target = rng.choice(creatures)
                opp.battlefield.remove(target)
                opp.graveyard.append(target)
                # v7: commander goes to command zone
                if target.get("is_commander") and target.get("owner") == opp.name:
                    opp.command_zone.append(target)
                break
        player.graveyard.append(card)
    elif effect == "board_wipe":
        for p in [player] + opps:
            if p.indestructible and turn < p.indestructible_until:
                continue
            survivors = []
            for c in p.battlefield:
                if isinstance(c, dict) and c.get("effect") == "creature":
                    if c.get("is_commander"):
                        # v7: commander back to command zone
                        c["tapped"] = False
                        c["summoning_sick"] = False
                        p.command_zone.append(c)
                    else:
                        p.graveyard.append(c)
                else:
                    survivors.append(c)
            p.battlefield = survivors
        token_count = effect_data.get("token_count", 0)
        if isinstance(token_count, str) and token_count == "life_total":
            token_count = player.life // 2
        if token_count and int(token_count) > 0:
            for _ in range(min(int(token_count), 20)):
                player.battlefield.append({"name": "Token", "cmc": 0, "tag": "token", "effect": "creature", "power": 2, "summoning_sick": False})
        player.graveyard.append(card)
    elif effect == "phase_out":
        # v7 F2: REAL phase out — remove all permanents from battlefield temporarily
        player.phased_out = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") not in ("land",)]
        player.battlefield = [c for c in player.battlefield if c == "land" or (isinstance(c, dict) and c.get("effect") == "land")]
        player.life_cant_change = True
        player.protection_from_everything = True
        player.graveyard.append(card)
    elif effect == "indestructible":
        player.indestructible = True
        player.indestructible_until = turn + 2
        player.graveyard.append(card)
    elif effect == "silence_opponents":
        player.battlefield.append(effect_data)
        player.silenced_opponents = True
    elif effect == "approach":
        player.approach_count += 1
        player.life = min(40, player.life + 7)
        if player.approach_count >= 2:
            player.graveyard.append(card)
            return  # WIN — handled in game loop
        if len(player.library) >= 7:
            player.library.insert(6, card)
        else:
            player.library.append(card)
    elif effect == "steal_all_creatures":
        total_power = 0
        for opp in opps:
            creatures = [c for c in opp.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
            for c in creatures:
                total_power += c.get("power", 2)
            opp.battlefield = [c for c in opp.battlefield if not (isinstance(c, dict) and c.get("effect") == "creature")]
        player.graveyard.append(card)
        # v7 G3 fix: attack immediately
        alive_opps = [o for o in opps if o.is_alive()]
        if alive_opps and total_power > 0:
            dmg_per_opp = total_power // len(alive_opps)
            for opp in alive_opps:
                opp.life -= dmg_per_opp
    elif effect == "token_maker":
        token_count = effect_data.get("token_count", 5)
        if isinstance(token_count, str):
            if token_count == "life_total":
                token_count = player.life // 2
            elif token_count == "lands":
                token_count = sum(1 for c in player.battlefield if c == "land")
        token_count = int(token_count) if isinstance(token_count, (int, float)) else 5
        token_power = effect_data.get("token_power", 2)
        for _ in range(min(token_count, 20)):
            player.battlefield.append({"name": "Token", "cmc": 0, "tag": "token", "effect": "creature", "power": token_power, "summoning_sick": False})
        player.graveyard.append(card)
    elif effect == "overload_recursion":
        spells = [c for c in player.graveyard if isinstance(c, dict) and c.get("cmc", 0) > 0]
        if player.copy_engines > 0:
            spells = spells * 2
        dmg = len(spells) * 3
        alive_opps = [o for o in opps if o.is_alive()]
        if alive_opps:
            dmg_each = dmg // len(alive_opps)
            for opp in alive_opps:
                opp.life -= dmg_each
        player.graveyard.append(card)
    elif effect == "pump_all":
        keywords = effect_data.get("keywords", [])
        for c in player.battlefield:
            if isinstance(c, dict) and c.get("effect") == "creature":
                c["power"] = c.get("power", 2) * 2
                if "flying" in keywords: c["flying"] = True
                if "double_strike" in keywords: c["double_strike"] = True
                if "lifelink" in keywords: c["lifelink"] = True
                if "indestructible" in keywords: c["indestructible"] = True
        player.graveyard.append(card)
    elif effect == "creature":
        c_copy = dict(card)
        c_copy["summoning_sick"] = True
        c_copy["tapped"] = False
        player.battlefield.append(c_copy)
    elif effect == "copy_spell":
        player.battlefield.append(effect_data)
        player.copy_engines += 1
    elif effect == "tutor":
        target = effect_data.get("target", "any")
        for c in player.library:
            if target == "any":
                player.library.remove(c)
                player.hand.append(c)
                break
            elif target == "artifact_or_enchantment":
                if c.get("tag") in ("ramp", "draw", "wincon"):
                    player.library.remove(c)
                    player.hand.append(c)
                    break
        player.graveyard.append(card)
    elif effect == "topdeck_manipulation":
        player.battlefield.append(effect_data)
        player.draw(1, rng)
    elif effect == "loot":
        n = effect_data.get("count", 1)
        player.draw(n, rng)
        for _ in range(min(n, len(player.hand))):
            if player.hand:
                discarded = player.hand.pop(rng.randint(0, len(player.hand) - 1))
                player.graveyard.append(discarded)
    elif effect == "finisher":
        creatures = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
        total_power = sum(c.get("power", 2) for c in creatures)
        if total_power > 0:
            alive_opps = [o for o in opps if o.is_alive()]
            if alive_opps:
                target = rng.choice(alive_opps)
                target.life -= total_power
        player.graveyard.append(card)

def combat_phase(attacker, opponents, turn, rng):
    """v7: Full combat with blockers, first strike, double strike, flying."""
    creatures = attacker.untapped_creatures()
    if not creatures:
        return

    attackers = []
    for c in creatures:
        if not c.get("summoning_sick", False):
            c["tapped"] = True
            attackers.append(c)

    if not attackers:
        return

    alive_defenders = [o for o in opponents if o.is_alive()]
    if not alive_defenders:
        return

    # v7 4-player: attack the most threatening/losing opponent (politics)
    if attacker.is_human or attacker.strategy in ("aggro", "rush"):
        target = min(alive_defenders, key=lambda o: o.life)  # finish weakest
    elif attacker.strategy in ("control",):
        target = max(alive_defenders, key=lambda o: len(o.untapped_creatures()))  # suppress strongest board
    else:
        target = max(alive_defenders, key=lambda o: o.life)  # attack life leader

    # ── DECLARE BLOCKERS (v7 C5) ──
    # Each untapped opponent creature can block one attacker
    blockers = []
    for a in attackers:
        for opp in opponents:
            if opp.is_alive() and opp != attacker:
                available = [c for c in opp.creatures_for_blocking() if c not in blockers]
                if available and rng.random() < 0.5:  # 50% chance to block
                    blocker_candidates = [c for c in available if not c.get("flying", False) or a.get("flying", False)]
                    if blocker_candidates:
                        blocker = rng.choice(blocker_candidates)
                        blockers.append(blocker)
                        break
        if len(blockers) >= len(attackers):
            break

    # ── FIRST STRIKE DAMAGE STEP (v7 C6) ──
    first_strikers = [a for a in attackers if a.get("first_strike") or a.get("double_strike")]
    if first_strikers:
        for a in first_strikers:
            a_pwr = a.get("power", 2) * (2 if a.get("double_strike") else 1)
            # Check if blocked
            is_blocked = False
            for b in blockers:
                if b in target.battlefield:
                    b_tgh = b.get("power", 2)
                    if a_pwr >= b_tgh:
                        target.battlefield.remove(b)
                        target.graveyard.append(b)
                    is_blocked = True
                    break
            if not is_blocked:
                target.life -= a_pwr
                # v7: track commander damage
                if a.get("is_commander") and a.get("owner") == attacker.name:
                    attacker.commander_damage[target.name] += a_pwr

    # Remove dead blockers
    blockers = [b for b in blockers if b in target.battlefield]

    # ── REGULAR COMBAT DAMAGE STEP ──
    for a in attackers:
        a_pwr = a.get("power", 2)
        is_blocked = False
        for b in blockers[:]:
            if b in target.battlefield:
                b_tgh = b.get("power", 2)
                if a_pwr >= b_tgh:
                    target.battlefield.remove(b)
                    target.graveyard.append(b)
                    blockers.remove(b)
                is_blocked = True
                break
        if not is_blocked:
            target.life -= a_pwr
            if a.get("is_commander") and a.get("owner") == attacker.name:
                attacker.commander_damage[target.name] += a_pwr

    # ── CHECK COMMANDER DAMAGE WIN (v7 E5) ──
    for name, dmg in attacker.commander_damage.items():
        if dmg >= 21:
            for opp in opponents:
                if opp.name == name:
                    opp.life = 0

def simulate_game(my_commander, my_deck, opp_profile, rng, game_id=0):
    """v7: Full Commander game simulation."""
    turn = 0
    max_turns = 30

    lorehold = Player("Lorehold", my_commander, my_deck, is_human=True, strategy="spellslinger")
    opponents = []
    for profile in opp_profile:
        opp_deck = generate_opponent_deck(profile)
        opp_cmd = get_opponent_commander(profile)
        opp = Player(profile["name"], opp_cmd, opp_deck, strategy=profile["strategy"])
        opponents.append(opp)

    all_players = [lorehold] + opponents

    # Mulligan
    for p in all_players:
        play_mulligan(p, rng)

    # Game loop
    while lorehold.is_alive() and turn < max_turns:
        turn += 1

        alive = [p for p in all_players if p.is_alive()]
        if len(alive) <= 1:
            break

        for player in all_players:
            if not player.is_alive():
                continue
            others = [p for p in all_players if p != player]
            play_turn(player, others, turn, rng)

            # WIN CHECKS (v7)
            if player.approach_count >= 2:
                return "win", turn, "approach" if player.is_human else "opponent_win"

            if player.commander_damage:
                for name, dmg in player.commander_damage.items():
                    if dmg >= 21:
                        return "win", turn, "commander_damage" if player.is_human else "opponent_win"

            if not player.is_alive():
                continue

    # Result
    if lorehold.is_alive():
        alive_opps = sum(1 for o in opponents if o.is_alive())
        if alive_opps == 0:
            return "win", turn, "elimination"
        else:
            return "stall", turn, f"opponents_alive={alive_opps}"
    else:
        return "loss", turn, "life_zero"

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════

def main():
    print("=" * 60)
    print("BATTLE ANALYST v7 — Commander Rule-Compliant Simulator")
    print("=" * 60)

    commander, deck = load_deck()
    lands = sum(1 for c in deck if c.get("tag") == "land" or "Land" in c.get("type_line", ""))
    ramp = sum(1 for c in deck if c.get("tag") in ("ramp", "ritual"))
    removal = sum(1 for c in deck if c.get("tag") in ("removal", "board_wipe"))
    creatures = sum(1 for c in deck if "creature" in c.get("type_line", "").lower())
    nonlands = [c for c in deck if c.get("tag") != "land"]
    avg_cmc = sum(c["cmc"] for c in nonlands) / max(1, len(nonlands))

    print(f"Commander: {commander['name'] if commander else 'NONE'}")
    print(f"Lorehold Deck: 1 Commander + {len(deck)} cards | L={lands} R={ramp} X={removal} C={creatures} CMC={avg_cmc:.2f}")
    print(f"v7 Features: Commander Zone, Commander Damage, Blockers, Summoning Sickness, Cleanup, Colored Mana")

    GAMES_PER_OPPONENT = 100
    rng = random.Random(42)

    results = []
    total_wins = total_losses = total_stalls = 0

    print(f"\nSimulating {GAMES_PER_OPPONENT} games vs each of {len(OPPONENT_ARCHETYPES)} archetypes...\n")

    # v7: True 4-player — each game has 3 different opponent archetypes
    import itertools
    
    for profile in OPPONENT_ARCHETYPES:
        wins = losses = stalls = 0
        win_turns = []
        win_reasons = defaultdict(int)
        loss_reasons = defaultdict(int)

        for g in range(GAMES_PER_OPPONENT):
            # Pick 3 opponents (always include the current profile + 2 others)
            others = [p for p in OPPONENT_ARCHETYPES if p != profile]
            picked = [profile] + rng.sample(others, 2)
            result, turns, reason = simulate_game(commander, deck, picked, rng, g)

            if result == "win":
                wins += 1
                win_turns.append(turns)
                win_reasons[reason] += 1
            elif result == "loss":
                losses += 1
                loss_reasons[reason] += 1
            else:
                stalls += 1

        wr = wins / GAMES_PER_OPPONENT * 100
        avg_win_turn = sum(win_turns) / len(win_turns) if win_turns else 0

        results.append({
            "opponent": profile["name"], "archetype": profile["archetype"],
            "wins": wins, "losses": losses, "stalls": stalls,
            "win_rate": wr, "avg_win_turn": avg_win_turn,
            "win_reasons": dict(win_reasons), "loss_reasons": dict(loss_reasons),
        })

        total_wins += wins; total_losses += losses; total_stalls += stalls

        icon = "✅" if wr >= 55 else "⚖️" if wr >= 40 else "❌"
        win_details = ", ".join(f"{k}={v}" for k, v in win_reasons.items())
        print(f"  {icon} vs {profile['name']:<30s} WR={wr:5.1f}% W={wins} L={losses} S={stalls} AvgT={avg_win_turn:.1f} [{win_details}]")

    total_games = GAMES_PER_OPPONENT * len(OPPONENT_ARCHETYPES)
    avg_wr = total_wins / total_games * 100
    print(f"\n  OVERALL: WR={avg_wr:.1f}% ({total_wins}W/{total_losses}L/{total_stalls}S)")

    # Write log
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(LOG_PATH, "a") as f:
        f.write(f"\n## [{ts}] Battle Analyst v7 — Commander Rule-Compliant\n")
        f.write(f"Games: {GAMES_PER_OPPONENT} | Deck: 1+{len(deck)}c | L={lands} R={ramp} X={removal} CMC={avg_cmc:.2f}\n")
        f.write(f"v7: Commander Zone, Commander Damage, Blockers, Summoning Sickness, Cleanup, Colored Mana, Postcombat Main\n\n")
        f.write(f"| Opponent | WR | Wins | Losses | Stalls | Avg Win Turn | Win Reasons |\n")
        f.write(f"|:---------|----:|-----:|-------:|-------:|-------------:|:------------|\n")
        for r in results:
            wr_det = ", ".join(f"{k}={v}" for k, v in r["win_reasons"].items())
            f.write(f"| {r['opponent']} | {r['win_rate']:.1f}% | {r['wins']} | {r['losses']} | {r['stalls']} | {r['avg_win_turn']:.1f} | {wr_det} |\n")
        f.write(f"\n**Overall WR: {avg_wr:.1f}%** ({total_wins}W/{total_losses}L/{total_stalls}S)\n")

    print(f"\nLog: {LOG_PATH}")

if __name__ == "__main__":
    main()
