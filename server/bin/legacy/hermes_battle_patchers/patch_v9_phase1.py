#!/usr/bin/env python3
"""Patch battle_analyst_v8.py: Phase 1 kernel enhancements from PDF spec.

Implementacoes de baixo esforco e alto impacto:
1. SBA loop com re-check ate estabilizar
2. Creature toughness <= 0 / lethal damage SBA  
3. Commander replacement effect (opcao de ir ao CZ)
4. Legend rule SBA
"""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py"
BACKUP = TARGET + ".bak_v9_enhancements"

import os, shutil

if not os.path.exists(BACKUP):
    shutil.copy(TARGET, BACKUP)
    print(f"Backup: {BACKUP}")
else:
    shutil.copy(BACKUP, TARGET)
    print("Restored from backup")

with open(TARGET) as f:
    content = f.read()

changes = 0

# ═══════════════════════════════════════════════════════════════════════
# FIX 1: SBA loop with re-check until stable
# ═══════════════════════════════════════════════════════════════════════

old_sba = '''def check_sbas(all_players):
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
        if not p.library and not p.hand and not p.eliminated:
            p.life = 0
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="deck_out")
            return True
    return False'''

new_sba = '''def check_sbas(all_players):
    """v9: Full SBA loop — check all, re-check until stable (CR 704.3)."""
    any_sba = False
    for p in all_players:
        if getattr(p, "failed_draw_from_empty_library", False) and not p.eliminated:
            p.life = 0
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="draw_from_empty_library")
            any_sba = True
        if p.life <= 0 and not p.eliminated:
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="life_zero")
            any_sba = True
        if p.eliminated:
            continue
        for name, dmg in p.commander_damage.items():
            if dmg >= 21:
                for op in all_players:
                    if op.name == name and not op.eliminated:
                        op.life = 0
                        op.eliminated = True
                        emit_replay_event("player_eliminated", player=op.name, reason="commander_damage")
                        any_sba = True
        if not p.library and not p.hand and not p.eliminated:
            p.life = 0
            p.eliminated = True
            emit_replay_event("player_eliminated", player=p.name, reason="deck_out")
            any_sba = True

    # v9: Creature SBAs — toughness <= 0 or lethal damage
    for p in all_players:
        for c in list(p.battlefield):
            toughness = c.get("toughness", 1)
            damage = c.get("damage_marked", 0)
            if toughness <= 0 or damage >= toughness:
                if not c.get("indestructible"):
                    move_creature_from_battlefield(p, c, "sba_lethal", None, all_players)
                    any_sba = True

    # v9: Legend rule (CR 704.5j)
    legends = {}
    for p in all_players:
        for c in list(p.battlefield):
            if c.get("is_legendary") or "Legendary" in c.get("type_line", ""):
                key = c.get("name", c.get("card_name", ""))
                if not key: continue
                if key in legends:
                    # Keep the one with higher timestamp, destroy the other
                    existing = legends[key]
                    if c.get("_battle_timestamp", 0) > existing.get("_battle_timestamp", 0):
                        move_creature_from_battlefield(existing.get("controller", p), existing, "sba_legend", None, all_players)
                        legends[key] = c
                    else:
                        move_creature_from_battlefield(p, c, "sba_legend", None, all_players)
                        any_sba = True
                else:
                    legends[key] = c

    return any_sba


def check_sbas_until_stable(all_players):
    """v9: Loop SBAs until no more actions (CR 704.3)."""
    while check_sbas(all_players):
        pass
    return False'''

if old_sba in content:
    content = content.replace(old_sba, new_sba)
    changes += 1
    print("FIX 1: SBA loop + creature toughness + legend rule")
else:
    print("FIX 1: PATTERN NOT FOUND")

# ═══════════════════════════════════════════════════════════════════════
# FIX 2: Replace all single check_sbas calls with check_sbas_until_stable
# ═══════════════════════════════════════════════════════════════════════

# Replace all `check_sbas(all_players)` calls that aren't in definitions
# We need to be careful - only replace at call sites, not in the function def
import re
# Replace pattern: `check_sbas(all_players)` at start of line with indentation
old_call = 'check_sbas(all_players)'
new_call = 'check_sbas_until_stable(all_players)'

# Count occurrences
count = content.count(old_call)
# Only replace call sites (not the function definitions)
# The function definition uses check_sbas as the name, but calls should use check_sbas_until_stable
# We'll replace all EXCEPT in the def line
lines = content.split('\n')
new_lines = []
for line in lines:
    if 'def check_sbas' in line or 'def check_sbas_until_stable' in line:
        new_lines.append(line)
    elif old_call in line:
        new_line = line.replace(old_call, new_call)
        new_lines.append(new_line)
    else:
        new_lines.append(line)
content = '\n'.join(new_lines)
# Also replace in standalone calls like `if check_sbas`
content = content.replace('if check_sbas_until_stable(all_players):', 'check_sbas_until_stable(all_players)')
changes += 1
print(f"FIX 2: Replaced {count} SBA call sites with until_stable")

# ═══════════════════════════════════════════════════════════════════════
# FIX 3: Commander replacement effect — optional move to CZ
# ═══════════════════════════════════════════════════════════════════════

old_cmd = '''        if creature.get("is_commander"):
            player.command_zone.append(creature)
            creature["controller"] = player.name'''
new_cmd = '''        if creature.get("is_commander"):
            # v9: Commander replacement effect (CR 903.9a)
            # Owner MAY put commander in command zone instead of graveyard/exile
            # Sim: 70% chance to move to CZ (simulates strategic choice)
            if player.is_human:
                # Human (Lorehold): always move to CZ for recast potential
                player.command_zone.append(creature)
                creature["controller"] = player.name
            else:
                # AI opponent: 70% move to CZ, 30% let it go to graveyard
                import random as _random
                if _random.random() < 0.7:
                    player.command_zone.append(creature)
                    creature["controller"] = player.name'''

if old_cmd in content:
    content = content.replace(old_cmd, new_cmd)
    changes += 1
    print("FIX 3: Commander replacement effect (optional CZ)")
else:
    print("FIX 3: PATTERN NOT FOUND — searching")
    idx = content.find('if creature.get("is_commander"):')
    if idx > 0:
        print(f"  Found at {idx}: {content[idx:idx+200]}")

# ═══════════════════════════════════════════════════════════════════════
# Write back
# ═══════════════════════════════════════════════════════════════════════

with open(TARGET, "w") as f:
    f.write(content)

print(f"\nTotal changes: {changes}")
print(f"Lines: {len(content.split(chr(10)))}")
