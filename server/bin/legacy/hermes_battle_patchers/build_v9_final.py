#!/usr/bin/env python3
"""Build battle_analyst_v9.py: all fixes consolidated.

Fixes:
1. check_sbas_until_stable wrapper (SBA loop)
2. Creature toughness/damage SBA
3. Legend rule SBA
4. Commander replacement effect (optional CZ)
5. Poison counter + SBA
6. Remove incorrect deck_out SBA
7. classify_loss taxonomy expansion
"""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"

with open(TARGET) as f:
    content = f.read()

changes = 0

# ── 1. Add poison counter to Player ──────────────────────────────
old = '        self.life_cant_change = False\n        self.eliminated = False'
new = '        self.life_cant_change = False\n        self.eliminated = False\n        self.poison = 0  # v9'
if old in content:
    content = content.replace(old, new)
    changes += 1
    print("1. Added poison counter to Player")

# ── 2. Remove incorrect deck_out SBA ─────────────────────────────
old_dko = '        if not p.library and not p.hand and not p.eliminated:\n            p.life = 0\n            p.eliminated = True\n            emit_replay_event("player_eliminated", player=p.name, reason="deck_out")\n            return True'
if old_dko in content:
    content = content.replace(old_dko, '')
    changes += 1
    print("2. Removed incorrect deck_out SBA")

# ── 3. Add creature SBA + poison SBA + check_sbas_until_stable ──
old_end = '    return False\n\n\ndef game_winner(all_players):'
new_end = '''    # v9: Poison SBA
    for p in all_players:
        if getattr(p, "poison", 0) >= 10 and not p.eliminated:
            p.life = 0
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="poison")
            return True

    # v9: Creature SBAs
    for p in all_players:
        for c in list(p.battlefield):
            toughness = c.get("toughness", 1)
            damage = c.get("damage_marked", 0)
            if (toughness <= 0 or damage >= toughness) and not c.get("indestructible"):
                move_creature_from_battlefield(p, c, "sba_lethal", None, all_players)
                return True

    # v9: Legend rule
    legends = {}
    for p in all_players:
        for c in list(p.battlefield):
            if c.get("is_legendary") or "Legendary" in str(c.get("type_line", "")):
                key = c.get("name", c.get("card_name", ""))
                if not key: continue
                if key in legends:
                    existing = legends[key]
                    if c.get("_bt", 0) > existing.get("_bt", 0):
                        move_creature_from_battlefield(existing.get("_ctrl", p), existing, "sba_legend", None, all_players)
                        legends[key] = c
                    else:
                        move_creature_from_battlefield(p, c, "sba_legend", None, all_players)
                        return True
                else:
                    legends[key] = c

    return False


def check_sbas_until_stable(all_players):
    """v9: Loop SBAs until no more actions (CR 704.3)."""
    while check_sbas(all_players):
        pass


def game_winner(all_players):'''
if old_end in content:
    content = content.replace(old_end, new_end)
    changes += 1
    print("3. Added poison SBA + creature SBA + legend rule + until_stable")

# ── 4. Commander replacement opcional ────────────────────────────
old_cmd = '''    if creature.get("is_commander"):
        owner.command_zone.append(creature)
        return "command_zone"'''
new_cmd = '''    if creature.get("is_commander"):
        # v9: Commander replacement (CR 903.9a) - owner MAY move to CZ
        if owner.is_human:
            owner.command_zone.append(creature)
            return "command_zone"
        else:
            import random as _cr
            if _cr.random() < 0.7:
                owner.command_zone.append(creature)
                return "command_zone"'''
if old_cmd in content:
    content = content.replace(old_cmd, new_cmd)
    changes += 1
    print("4. Commander replacement opcional")

# ── 5. classify_loss taxonomy expansion ──────────────────────────
old_cl = '    if not tags:\n        tags.append("combat-damage")\n\n    return tags'
new_cl = '''    # v9: Additional loss modes
    if getattr(player, "poison", 0) >= 10:
        tags.append("poison")
    if "effect_says_lose" in str(reason).lower():
        tags.append("effect_says_lose")

    if not tags:
        tags.append("combat-damage")

    return tags'''
if old_cl in content:
    content = content.replace(old_cl, new_cl)
    changes += 1
    print("5. classify_loss expanded")

# ── 6. Replace key SBA call sites ────────────────────────────────
# In simulate_game_v8: change 'if check_sbas(all_players): break' to use until_stable
old_s1 = '            if check_sbas(all_players):\n                break'
new_s1 = '            check_sbas_until_stable(all_players)\n            if any(getattr(p, "eliminated", False) for p in all_players):\n                break'
if old_s1 in content:
    content = content.replace(old_s1, new_s1, 2)  # Only first 2 occurrences
    changes += 1
    print("6. Updated SBA call sites in simulate_game_v8")

with open(TARGET, "w") as f:
    f.write(content)

print(f"\nTotal changes: {changes}")
print(f"Lines: {len(content.split(chr(10)))}")
