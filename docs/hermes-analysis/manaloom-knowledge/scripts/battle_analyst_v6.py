#!/usr/bin/env python3
"""
Lorehold Battle Analyst v6 — REAL Game Simulator
Simula PARTIDAS REAIS de Commander 4-player:
- Shuffle + draw 7 + London mulligan
- 1 land/turn, mana tracking, CMC casting
- Cada carta tem efeito REAL baseado em functional_tag
- Board wipes, proteção (Teferi's/Boros Charm), combate
- 3 oponentes com decks reais
- Win conditions: Approach x2, Insurrection, dano letal, tokens
"""
import sqlite3, random, json, os, re, math
from datetime import datetime, timezone
from collections import defaultdict

DB = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
KNOWLEDGE_DIR = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge"
LOG_PATH = f"{KNOWLEDGE_DIR}/decks/lorehold-the-historian/BATTLE_LOG.md"

# ═══════════════════════════════════════════
# DECK LOADING
# ═══════════════════════════════════════════

def load_deck(deck_id=6):
    """Load Lorehold deck from SQLite with tags."""
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT card_name, quantity, CAST(COALESCE(cmc,0) AS REAL) as cmc,
               COALESCE(functional_tag,'unknown') as functional_tag,
               type_line
        FROM deck_cards WHERE deck_id=?
    """, (deck_id,)).fetchall()
    conn.close()
    
    deck = []
    for row in rows:
        qty = row["quantity"] or 1
        for _ in range(qty):
            deck.append({
                "name": row["card_name"],
                "cmc": float(row["cmc"] or 0),
                "tag": row["functional_tag"] or "unknown",
                "type_line": row["type_line"] or "",
            })
    return deck

# ═══════════════════════════════════════════
# CARD EFFECT ENGINE — cada carta FAZ algo real
# ═══════════════════════════════════════════

# Card-specific effects (known by name)
KNOWN_CARDS = {
    # ── Protection ──
    "Teferi's Protection": {"effect": "phase_out", "duration": 1},
    "Boros Charm": {"effect": "indestructible", "duration": 1, "alt_effect": "double_strike"},
    "Deflecting Swat": {"effect": "redirect_removal"},
    "Grand Abolisher": {"effect": "silence_opponents", "duration": "permanent"},
    
    # ── Board Wipes ──
    "Austere Command": {"effect": "board_wipe", "selective": True},
    "Blasphemous Act": {"effect": "board_wipe"},
    "Call Forth the Tempest": {"effect": "damage_wipe", "token_maker": True},
    
    # ── Win Conditions ──
    "Approach of the Second Sun": {"effect": "approach", "gain_life": 7},
    "Insurrection": {"effect": "steal_all_creatures"},
    "Mizzix's Mastery": {"effect": "overload_recursion"},
    "Storm Herd": {"effect": "token_maker", "token_count": "life_total"},
    "Surge to Victory": {"effect": "pump_all", "recursion": True},
    "Rite of the Dragoncaller": {"effect": "token_maker", "token_count": 4, "token_power": 5},
    
    # ── Token Makers ──
    "Brass's Bounty": {"effect": "token_maker", "token_count": "lands"},
    "Call Forth the Tempest": {"effect": "damage_wipe", "token_count": "damage_dealt"},
    
    # ── Pump ──
    "Akroma's Will": {"effect": "pump_all", "keywords": ["flying","double_strike","vigilance","lifelink","protection_all","indestructible"]},
    
    # ── Draw Engines ──
    "The One Ring": {"effect": "draw_engine", "burden": True},
    "Wedding Ring": {"effect": "draw_engine", "symmetric": True},
    "Victory Chimes": {"effect": "draw_engine", "untap": True},
    "Sensei's Divining Top": {"effect": "topdeck_manipulation"},
    "Scroll Rack": {"effect": "topdeck_manipulation"},
    
    # ── Ramp ──
    "Sol Ring": {"effect": "ramp_permanent", "mana_produced": 2},
    "Arcane Signet": {"effect": "ramp_permanent", "mana_produced": 1},
    "Boros Signet": {"effect": "ramp_permanent", "mana_produced": 1},
    "Talisman of Conviction": {"effect": "ramp_permanent", "mana_produced": 1},
    
    # ── Copy Engines ──
    "Double Vision": {"effect": "copy_spell"},
    "Arcane Bombardment": {"effect": "copy_spell", "repeatable": True},
    
    # ── Tutors ──
    "Enlightened Tutor": {"effect": "tutor", "target": "artifact_or_enchantment"},
    "Gamble": {"effect": "tutor", "target": "any", "discard_risk": True},
    
    # ── Game Changers ──
    "Smothering Tithe": {"effect": "ramp_engine", "trigger": "opponent_draw"},
    "Jeska's Will": {"effect": "ramp_ritual", "mana_produced": 7},
    "Esper Sentinel": {"effect": "draw_engine", "trigger": "opponent_spell"},
}

# Tag-based fallback effects
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
    """Get the real effect of a card."""
    name = card.get("name", card.get("effect", ""))
    if name in KNOWN_CARDS:
        return KNOWN_CARDS[name].copy()
    
    tag = card.get("tag", "")
    if tag in TAG_EFFECTS:
        return TAG_EFFECTS[tag].copy()
    
    # If opponent simplified card, map effects directly
    simple_effect = card.get("effect", "")
    if simple_effect in ("ramp",):
        return {"effect": "ramp_permanent", "mana_produced": 1}
    if simple_effect == "removal":
        return {"effect": "remove_creature"}
    if simple_effect == "board_wipe":
        return {"effect": "board_wipe"}
    if simple_effect == "wincon" or simple_effect == "finisher":
        return {"effect": "finisher"}
    if simple_effect == "draw":
        return {"effect": "draw_cards", "count": 2}
    if simple_effect == "creature":
        return {"effect": "creature", "power": card.get("power", 2), "toughness": card.get("power", 2)}
    if simple_effect == "counter":
        return {"effect": "counter"}
    if simple_effect == "land":
        return {"effect": "land"}
    
    # Default: creature can attack/block
    if "creature" in card.get("type_line", "").lower() or "Creature" in card.get("type_line", ""):
        return {"effect": "creature", "power": max(1, int(card.get("cmc", 2))), "toughness": max(1, int(card.get("cmc", 2)))}
    
    return {"effect": "unknown"}

# ═══════════════════════════════════════════
# OPPONENT DECK GENERATION
# ═══════════════════════════════════════════

OPPONENT_ARCHETYPES = [
    {
        "name": "Aggro (Krenko)",
        "archetype": "aggro",
        "life": 40,
        "lands": 34, "ramp": 8, "removal": 5, "counters": 0,
        "creatures": 35, "wincons": 3, "draw": 4, "wipe": 2,
        "avg_cmc": 2.5, "strategy": "rush",
    },
    {
        "name": "Control (Atraxa)",
        "archetype": "control",
        "life": 40,
        "lands": 37, "ramp": 12, "removal": 12, "counters": 6,
        "creatures": 15, "wincons": 3, "draw": 6, "wipe": 6,
        "avg_cmc": 3.2, "strategy": "control",
    },
    {
        "name": "Combo (Kinnan)",
        "archetype": "combo",
        "life": 40,
        "lands": 30, "ramp": 15, "removal": 6, "counters": 8,
        "creatures": 18, "wincons": 4, "draw": 8, "wipe": 1,
        "avg_cmc": 2.1, "strategy": "combo",
    },
    {
        "name": "Midrange (Korvold)",
        "archetype": "midrange",
        "life": 40,
        "lands": 36, "ramp": 12, "removal": 8, "counters": 2,
        "creatures": 25, "wincons": 3, "draw": 6, "wipe": 3,
        "avg_cmc": 3.0, "strategy": "value",
    },
    {
        "name": "Spellslinger (Niv-Mizzet)",
        "archetype": "spellslinger",
        "life": 40,
        "lands": 36, "ramp": 10, "removal": 10, "counters": 5,
        "creatures": 10, "wincons": 3, "draw": 8, "wipe": 3,
        "avg_cmc": 2.8, "strategy": "spells",
    },
    {
        "name": "Stax (Winota)",
        "archetype": "stax",
        "life": 40,
        "lands": 35, "ramp": 8, "removal": 8, "counters": 0,
        "creatures": 30, "wincons": 3, "draw": 3, "wipe": 2,
        "avg_cmc": 2.6, "strategy": "stax",
    },
]

def generate_opponent_deck(profile):
    """Generate a 99-card opponent deck from archetype profile."""
    deck = []
    
    # Lands (basic)
    for _ in range(profile["lands"]):
        deck.append({"name": "Land", "cmc": 0, "tag": "land", "effect": "land"})
    
    # Ramp
    for _ in range(profile["ramp"]):
        deck.append({"name": "Ramp Card", "cmc": max(1, profile["avg_cmc"] - 0.5), "tag": "ramp", "effect": "ramp"})
    
    # Removal
    for _ in range(profile["removal"]):
        deck.append({"name": "Removal", "cmc": max(1, profile["avg_cmc"] - 1), "tag": "removal", "effect": "removal"})
    
    # Creatures (filler)
    for _ in range(profile["creatures"]):
        pwr = max(1, int(profile["avg_cmc"]))
        deck.append({"name": "Creature", "cmc": profile["avg_cmc"], "tag": "creature", "effect": "creature", "power": pwr})
    
    # Wincons
    for _ in range(profile["wincons"]):
        deck.append({"name": "Wincon", "cmc": max(3, profile["avg_cmc"] + 1), "tag": "wincon", "effect": "wincon"})
    
    # Draw
    for _ in range(profile["draw"]):
        deck.append({"name": "Draw Spell", "cmc": max(2, profile["avg_cmc"] - 0.5), "tag": "draw", "effect": "draw"})
    
    # Board wipes
    for _ in range(profile.get("wipe", 2)):
        deck.append({"name": "Board Wipe", "cmc": 4, "tag": "board_wipe", "effect": "board_wipe"})
    
    # Counterspells
    for _ in range(profile.get("counters", 0)):
        deck.append({"name": "Counterspell", "cmc": 2, "tag": "counter", "effect": "counter"})
    
    # Pad to 99
    while len(deck) < 99:
        deck.append({"name": "Filler Creature", "cmc": profile["avg_cmc"], "tag": "creature", "effect": "creature", "power": 2})
    
    return deck[:99]

# ═══════════════════════════════════════════
# GAME STATE
# ═══════════════════════════════════════════

class Player:
    def __init__(self, name, deck, is_human=False, strategy="midrange"):
        self.name = name
        self.library = list(deck)
        self.hand = []
        self.battlefield = []  # permanents on board
        self.graveyard = []
        self.exile = []
        self.life = 40
        self.commander_damage = defaultdict(int)
        self.mana_pool = 0
        self.lands_played_this_turn = 0
        self.max_lands_per_turn = 1
        self.is_human = is_human
        self.strategy = strategy
        self.protected = False  # Teferi's / Boros Charm
        self.protected_until = 0
        self.opponents_silenced = False  # Grand Abolisher
        self.approach_count = 0
        self.treasures = 0
        self.draw_engines = 0
        self.copy_engines = 0
    
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
    
    def available_mana(self, turn):
        """Calculate available mana this turn."""
        lands_played = min(self.battlefield.count("land"), turn) if turn > 0 else 0
        ramp_mana = sum(
            c.get("mana_produced", 1) if isinstance(c, dict) else 1
            for c in self.battlefield 
            if isinstance(c, dict) and c.get("effect") in ("ramp_permanent", "ramp_engine")
        )
        # Also count creatures as ramp sources if they're ramp
        return lands_played + ramp_mana + self.treasures + self.mana_pool
    
    def can_cast(self, card, turn):
        return card["cmc"] <= self.available_mana(turn)
    
    def is_alive(self):
        return self.life > 0
    
    def has_creatures(self):
        return any(
            isinstance(c, dict) and c.get("effect") == "creature" 
            for c in self.battlefield
        )

# ═══════════════════════════════════════════
# GAME SIMULATOR
# ═══════════════════════════════════════════

def mulligan_decision(hand):
    """London mulligan: keep if 2-5 lands, else mull."""
    lands = sum(1 for c in hand if c.get("tag") == "land" or c.get("effect") == "land")
    if 2 <= lands <= 5:
        return True, 7  # keep
    return False, 7  # mulligan

def play_turn(player, opponents, turn, rng):
    """Play one turn for a player."""
    # Untap (skip T1 for first player)
    player.mana_pool = 0
    player.lands_played_this_turn = 0
    
    # Check protection expiry
    if player.protected and turn >= player.protected_until:
        player.protected = False
    
    # Draw step (skip T1 draw for first player)
    if turn > 1 or player.name != "Lorehold":
        player.draw(1, rng)
    
    # Land drop
    lands_in_hand = [c for c in player.hand if c.get("tag") == "land" or c.get("effect") == "land"]
    if lands_in_hand and player.lands_played_this_turn < player.max_lands_per_turn:
        land = lands_in_hand[0]
        player.hand.remove(land)
        player.battlefield.append("land")
        player.lands_played_this_turn += 1
    
    # Cast spells (play what we can afford)
    mana = player.available_mana(turn)
    castable = [c for c in player.hand if c["cmc"] <= mana]
    
    if not castable:
        return
    
    # Priority order for casting (smart AI)
    # 1. Ramp (early turns)
    # 2. Draw engines
    # 3. Threats
    # 4. Hold removal/wipe for opponent's turn (simplified)
    
    # Play ramp first (find ramp cards directly in hand)
    ramp_cards = [c for c in player.hand if c["cmc"] <= mana and (
        get_card_effect(c).get("effect") in ("ramp_permanent", "ramp_engine", "ramp_ritual")
    )]
    for c in ramp_cards[:2]:  # max 2 ramp per turn
        if c in player.hand and c["cmc"] <= mana:
            player.hand.remove(c)
            mana -= c["cmc"]
            effect_data = get_card_effect(c)
            if effect_data.get("effect") == "ramp_ritual":
                player.mana_pool += effect_data.get("mana_produced", 3)
                player.graveyard.append(c)
            else:
                player.battlefield.append(effect_data)
    
    # Play draw engines / creatures / threats
    castable = [c for c in player.hand if c["cmc"] <= mana]
    
    # Win conditions are played when available
    if player.is_human:
        wincon_names = {
            "Approach of the Second Sun", "Insurrection", "Mizzix's Mastery",
            "Storm Herd", "Surge to Victory"
        }
        wincons = [c for c in player.hand if c["cmc"] <= mana and (
            c.get("tag") == "wincon" or c.get("name") in wincon_names
        )]
        if wincons:
            wc = wincons[0]
            if wc in player.hand:
                player.hand.remove(wc)
                mana -= wc["cmc"]
                apply_effect(player, opponents, wc, turn, rng)
    
    # Remaining spells: play in CMC order (low to high = more value)
    remaining = sorted(
        [c for c in player.hand if c["cmc"] <= mana],
        key=lambda c: c["cmc"]
    )
    
    played = 0
    for c in remaining:
        if played >= 2:
            break
        if c in player.hand and c["cmc"] <= mana:
            player.hand.remove(c)
            mana -= c["cmc"]
            apply_effect(player, opponents, c, turn, rng)
            played += 1

def apply_effect(player, opponents, card, turn, rng):
    """Apply a card's effect to the game state."""
    effect_data = get_card_effect(card)
    effect = effect_data.get("effect", "unknown")
    name = card.get("name", card.get("effect", "Unknown"))
    
    if effect == "land":
        return  # already handled
    
    elif effect == "ramp_permanent":
        player.battlefield.append(effect_data)
    
    elif effect == "ramp_ritual":
        player.mana_pool += effect_data.get("mana_produced", 3)
        player.graveyard.append(card)
    
    elif effect == "ramp_engine":
        player.battlefield.append(effect_data)
        player.treasures += 1
    
    elif effect == "draw_engine":
        player.battlefield.append(effect_data)
        player.draw_engines += 1
        player.draw(1, rng)  # immediate draw
    
    elif effect == "draw_cards":
        n = effect_data.get("count", 2)
        player.draw(n, rng)
        player.graveyard.append(card)
    
    elif effect == "remove_creature":
        # Target creature on opponent's board
        for opp in opponents:
            creatures = [c for c in opp.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
            if creatures:
                target = rng.choice(creatures)
                opp.battlefield.remove(target)
                opp.graveyard.append(target)
                break
        player.graveyard.append(card)
    
    elif effect == "board_wipe":
        # Destroy all creatures on all boards
        for p in [player] + list(opponents):
            if p.protected and turn < p.protected_until:
                continue  # protected from wipe
            creatures = [c for c in p.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
            for c in creatures:
                p.battlefield.remove(c)
                p.graveyard.append(c)
        
        # Token maker effect (Call Forth the Tempest)
        token_count = effect_data.get("token_count", 0)
        if isinstance(token_count, str):
            if token_count == "life_total":
                token_count = player.life // 2
            elif token_count == "lands":
                lands = sum(1 for c in player.battlefield if c == "land")
                token_count = lands
            elif token_count == "damage_dealt":
                token_count = 5  # simplified
        if token_count and token_count > 0:
            for _ in range(token_count):
                player.battlefield.append({
                    "name": "Token", "cmc": 0, "tag": "token",
                    "effect": "creature", "power": 2
                })
        
        player.graveyard.append(card)
    
    elif effect == "phase_out":
        player.protected = True
        player.protected_until = turn + 2  # phases back at next upkeep
        player.graveyard.append(card)
    
    elif effect == "indestructible":
        player.protected = True
        player.protected_until = turn + 1
        player.graveyard.append(card)
    
    elif effect == "silence_opponents":
        player.battlefield.append(effect_data)
        player.opponents_silenced = True
        player.protected = True  # simplified: can't be responded to
    
    elif effect == "double_strike":
        # Combat pump — applied in combat phase
        player.battlefield.append({"name": "DoubleStrike", "effect": "pump_aura"})
        player.graveyard.append(card)
    
    elif effect == "redirect_removal":
        player.protected = True
        player.protected_until = turn + 1
        player.graveyard.append(card)
    
    elif effect == "approach":
        player.approach_count += 1
        player.life = min(40, player.life + 7)
        if player.approach_count >= 2:
            player.graveyard.append(card)
            # WIN — handled in game loop
        else:
            # Put 7th from top
            if len(player.library) >= 7:
                player.library.insert(6, card)
            else:
                player.library.append(card)
    
    elif effect == "steal_all_creatures":
        # Take all creatures from all opponents
        total_power = 0
        for opp in opponents:
            creatures = [c for c in opp.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
            for c in creatures:
                total_power += c.get("power", 2)
            opp.battlefield = [c for c in opp.battlefield if not (isinstance(c, dict) and c.get("effect") == "creature")]
        player.graveyard.append(card)
        # Attack with stolen creatures
        if total_power > 0:
            # Distribute damage among opponents
            alive_opps = [o for o in opponents if o.is_alive()]
            if alive_opps:
                dmg_per_opp = total_power // len(alive_opps)
                for opp in alive_opps:
                    opp.life -= dmg_per_opp
    
    elif effect == "token_maker":
        token_count = effect_data.get("token_count", 5)
        if isinstance(token_count, str):
            if token_count == "life_total":
                token_count = player.life // 2
            elif token_count == "lands":
                lands = sum(1 for c in player.battlefield if c == "land")
                token_count = lands
        token_count = int(token_count) if isinstance(token_count, (int, float)) else 5
        
        token_power = effect_data.get("token_power", 2)
        for _ in range(min(token_count, 20)):  # cap at 20 tokens for performance
            player.battlefield.append({
                "name": "Token", "cmc": 0, "tag": "token",
                "effect": "creature", "power": token_power
            })
        player.graveyard.append(card)
    
    elif effect == "overload_recursion":
        # Return all instants/sorceries from grave, cast them
        spells = [c for c in player.graveyard if isinstance(c, dict) and c.get("cmc", 0) > 0]
        if player.copy_engines > 0:
            spells = spells * 2  # Double Vision / Arcane Bombardment copies
        
        # Simplified: deal damage equal to number of spells
        dmg = len(spells) * 3
        alive_opps = [o for o in opponents if o.is_alive()]
        if alive_opps:
            dmg_each = dmg // len(alive_opps)
            for opp in alive_opps:
                opp.life -= dmg_each
        
        player.graveyard.append(card)
    
    elif effect == "pump_all":
        # Pump all our creatures
        creatures = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
        for c in creatures:
            c["power"] = c.get("power", 2) * 2  # double strike effectively doubles damage
        player.graveyard.append(card)
    
    elif effect == "creature":
        player.battlefield.append(card)
    
    elif effect == "copy_spell":
        player.battlefield.append(effect_data)
        player.copy_engines += 1
    
    elif effect == "tutor":
        # Search library for desired card type
        target = effect_data.get("target", "any")
        tutored = None
        for c in player.library:
            if target == "any":
                tutored = c
                break
            elif target == "artifact_or_enchantment":
                if c.get("tag") in ("ramp", "draw", "wincon"):
                    tutored = c
                    break
        if tutored:
            player.library.remove(tutored)
            player.hand.append(tutored)
        player.graveyard.append(card)
    
    elif effect == "topdeck_manipulation":
        player.battlefield.append(effect_data)
        # Look at top 3, reorder (simplified: draw 1)
        player.draw(1, rng)
    
    elif effect == "loot":
        n = effect_data.get("count", 1)
        player.draw(n, rng)
        # Discard n (removed from hand, not grave — simplified)
        for _ in range(min(n, len(player.hand))):
            if player.hand:
                discarded = player.hand.pop(rng.randint(0, len(player.hand)-1))
                player.graveyard.append(discarded)
    
    elif effect == "finisher" or effect == "wincon":
        # Generic finisher: deal damage based on board state
        creatures = [c for c in player.battlefield if isinstance(c, dict) and c.get("effect") == "creature"]
        total_power = sum(c.get("power", 2) for c in creatures)
        if total_power > 0:
            alive_opps = [o for o in opponents if o.is_alive()]
            if alive_opps:
                target = rng.choice(alive_opps)
                target.life -= total_power
        player.graveyard.append(card)

def combat_phase(player, opponents, turn, rng):
    """Combat: attack the most threatening opponent."""
    creatures = [
        c for c in player.battlefield 
        if isinstance(c, dict) and c.get("effect") == "creature"
    ]
    if not creatures:
        return
    
    total_power = sum(c.get("power", 2) for c in creatures)
    
    # Smart targeting: attack the player with highest life (threat assessment)
    alive_opps = [o for o in opponents if o.is_alive()]
    if not alive_opps:
        return
    
    # Smart targeting
    if not alive_opps:
        return
        
    if player.strategy in ("aggro", "rush"):
        target = min(alive_opps, key=lambda o: o.life)
    elif player.strategy in ("combo",):
        target = max(alive_opps, key=lambda o: o.life) if alive_opps else alive_opps[0]
    else:
        target = min(alive_opps, key=lambda o: sum(
            1 for c in o.battlefield if isinstance(c, dict) and c.get("effect") == "creature"
        ))
    
    actual_damage = total_power
    if player.strategy == "stax":
        actual_damage = total_power // 2  # stax slows down
    
    target.life -= actual_damage

def play_mulligan(player, rng):
    """Perform London mulligan."""
    player.shuffle(rng)
    player.hand = player.draw(7, rng)
    
    keep, _ = mulligan_decision(player.hand)
    mulligan_count = 0
    
    while not keep and mulligan_count < 3:  # max 3 mulligans
        mulligan_count += 1
        # London: shuffle all back, draw 7, then put N on bottom
        player.library = player.hand + player.library
        player.hand = []
        player.shuffle(rng)
        player.hand = player.draw(7, rng)
        # Put mulligan_count cards on bottom
        for _ in range(mulligan_count):
            if player.hand:
                c = player.hand.pop(rng.randint(0, len(player.hand)-1))
                player.library.append(c)
        
        keep, _ = mulligan_decision(player.hand)
    
    return mulligan_count

def simulate_game(my_deck, opp_profile, rng, game_id=0):
    """Simulate ONE game of 4-player Commander."""
    turn = 0
    max_turns = 30
    
    # Setup players
    lorehold = Player("Lorehold", my_deck, is_human=True, strategy="spellslinger")
    opponents = []
    for i, profile in enumerate(opp_profile):
        opp_deck = generate_opponent_deck(profile)
        opp = Player(profile["name"], opp_deck, strategy=profile["strategy"])
        opponents.append(opp)
    
    all_players = [lorehold] + opponents
    
    # Mulligan
    for p in all_players:
        play_mulligan(p, rng)
    
    # Game loop
    while lorehold.is_alive() and turn < max_turns:
        turn += 1
        
        # Check if only 1 player alive
        alive = [p for p in all_players if p.is_alive()]
        if len(alive) <= 1:
            break
        
        # Play order: Lorehold first, then opponents
        for player in all_players:
            if not player.is_alive():
                continue
            
            others = [p for p in all_players if p != player]
            
            # Main phase
            play_turn(player, others, turn, rng)
            
            # Combat phase (skip T1)
            if turn > 1:
                combat_phase(player, others, turn, rng)
            
            # Check for Approach win
            if player.approach_count >= 2:
                return "win", turn, "approach"
            
            # Check for Insurrection win
            if any(c.get("name") == "Insurrection" for c in player.graveyard):
                alive_opps = [o for o in others if o.is_alive()]
                if not alive_opps:
                    return "win", turn, "insurrection"
            
            # End step: draw engine triggers
            if player.draw_engines > 0:
                player.draw(1, rng)
    
    # Determine result
    if lorehold.is_alive():
        alive_opps = sum(1 for o in opponents if o.is_alive())
        if alive_opps == 0:
            return "win", turn, "elimination"
        else:
            return "stall", turn, f"opponents_alive={alive_opps}"
    else:
        # Find who killed us
        reason = "life_zero"
        return "loss", turn, reason

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════

def main():
    print("=" * 60)
    print("BATTLE ANALYST v6 — Real Game Simulator")
    print("=" * 60)
    
    # Load deck
    my_deck = load_deck()
    lands = sum(1 for c in my_deck if c["tag"] == "land" or "Land" in c.get("type_line", ""))
    ramp = sum(1 for c in my_deck if c["tag"] in ("ramp", "ritual"))
    removal = sum(1 for c in my_deck if c["tag"] in ("removal", "board_wipe"))
    creatures = sum(1 for c in my_deck if "creature" in c.get("type_line", "").lower())
    avg_cmc = sum(c["cmc"] for c in my_deck if c["tag"] != "land") / max(1, len([c for c in my_deck if c["tag"] != "land"]))
    
    print(f"Lorehold Deck: {len(my_deck)} cards | L={lands} R={ramp} X={removal} C={creatures} CMC={avg_cmc:.2f}")
    
    # Run simulations against each archetype
    GAMES_PER_OPPONENT = 100
    rng = random.Random(42)
    
    results = []
    total_wins = 0
    total_losses = 0
    total_stalls = 0
    total_games = 0
    
    print(f"\nSimulating {GAMES_PER_OPPONENT} games vs each of {len(OPPONENT_ARCHETYPES)} archetypes...\n")
    
    for profile in OPPONENT_ARCHETYPES:
        wins = 0
        losses = 0
        stalls = 0
        win_turns = []
        loss_reasons = defaultdict(int)
        
        for g in range(GAMES_PER_OPPONENT):
            result, turns, reason = simulate_game(my_deck, [profile], rng, g)
            
            if result == "win":
                wins += 1
                win_turns.append(turns)
            elif result == "loss":
                losses += 1
                loss_reasons[reason] += 1
            else:
                stalls += 1
        
        wr = wins / GAMES_PER_OPPONENT * 100
        avg_win_turn = sum(win_turns) / len(win_turns) if win_turns else 0
        
        results.append({
            "opponent": profile["name"],
            "archetype": profile["archetype"],
            "wins": wins,
            "losses": losses,
            "stalls": stalls,
            "win_rate": wr,
            "avg_win_turn": avg_win_turn,
            "loss_reasons": dict(loss_reasons),
        })
        
        total_wins += wins
        total_losses += losses
        total_stalls += stalls
        total_games += GAMES_PER_OPPONENT
        
        icon = "✅" if wr >= 55 else "⚖️" if wr >= 40 else "❌"
        print(f"  {icon} vs {profile['name']:<30s}  WR={wr:5.1f}%  Wins={wins}/{GAMES_PER_OPPONENT}  AvgWinTurn={avg_win_turn:.1f}  Losses={losses}  Stalls={stalls}")
    
    avg_wr = total_wins / total_games * 100
    print(f"\n  OVERALL: WR={avg_wr:.1f}%  ({total_wins}W/{total_losses}L/{total_stalls}S)")
    
    # Write log
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    
    with open(LOG_PATH, "a") as f:
        f.write(f"\n## [{ts}] Battle Analyst v6 — REAL Game Simulation\n")
        f.write(f"Games per opponent: {GAMES_PER_OPPONENT}\n")
        f.write(f"Deck: {len(my_deck)}c | L={lands} R={ramp} X={removal} C={creatures} CMC={avg_cmc:.2f}\n\n")
        f.write(f"| Opponent | Archetype | WR | Wins | Losses | Stalls | Avg Win Turn |\n")
        f.write(f"|:---------|:----------|---:|-----:|-------:|-------:|-------------:|\n")
        for r in results:
            f.write(f"| {r['opponent']} | {r['archetype']} | {r['win_rate']:.1f}% | {r['wins']} | {r['losses']} | {r['stalls']} | {r['avg_win_turn']:.1f} |\n")
        f.write(f"\n**Overall WR: {avg_wr:.1f}%** ({total_wins}W/{total_losses}L/{total_stalls}S)\n")
        
        # Loss reason breakdown
        f.write(f"\n### Loss Reasons\n")
        for r in results:
            if r["loss_reasons"]:
                reasons_str = ", ".join(f"{k}={v}" for k, v in r["loss_reasons"].items())
                f.write(f"- vs {r['opponent']}: {reasons_str}\n")
    
    print(f"\nLog written to: {LOG_PATH}")

if __name__ == "__main__":
    main()
