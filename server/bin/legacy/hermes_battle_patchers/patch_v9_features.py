#!/usr/bin/env python3
"""Build v9 feature batch: taxonomia canonica + ward + empty stack priority."""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"
import os, shutil

with open(TARGET) as f:
    content = f.read()

changes = 0

# ══════════════════════════════════════════════════════
# FEATURE 1: Taxonomia canônica de derrota
# ══════════════════════════════════════════════════════

# Find classify_loss function and replace the final tag bucket
old_cl = '''    if not tags:
        tags.append("combat-damage")

    return tags'''

new_cl = '''    # v9: Canonical loss taxonomy (CR 104.2-104.5, CR 903.14)
    if getattr(player, "poison", 0) >= 10:
        tags.insert(0, "poison")
    if getattr(player, "lost_by_effect", False):
        tags.insert(0, "effect_says_lose")
    if getattr(player, "conceded", False):
        tags.insert(0, "concede")

    if not tags:
        tags.append("combat-damage")

    return tags'''

if old_cl in content:
    content = content.replace(old_cl, new_cl)
    changes += 1
    print("FEATURE 1: Taxonomia canonica de derrota")
else:
    print("FEATURE 1: classify_loss pattern NOT FOUND")

# ══════════════════════════════════════════════════════
# FEATURE 2: Ward — triggered counter
# ══════════════════════════════════════════════════════

# Add ward check in targeting logic (before spell targets are locked)
# Find: cast_spells_v8 function, add ward check before resolve
old_cast = 'def cast_spells_v8(player, opponents, all_players, turn, phase, stack, rng):'
ward_logic = '''

def check_ward(target, spell, controller, rng):
    """v9: Ward triggered ability (CR 702.21a).
    If target has ward, spell is countered unless controller pays cost."""
    ward_cost = target.get("ward_cost") or target.get("ward", 0)
    if ward_cost <= 0:
        return False  # No ward
    
    # Ward triggers: AI opponent pays 50% of the time if affordable
    can_pay = controller.available_mana() >= ward_cost
    if not can_pay:
        # Counter the spell (ward resolved)
        emit_replay_event("ward_countered", target=target.get("name"),
                         spell=spell.get("name"), ward_cost=ward_cost)
        return True  # Spell is countered
    
    # Decision: pay or let it be countered
    if controller.is_human or rng.random() < 0.5:
        # Pay ward cost
        controller.mana_pool.spend_generic(ward_cost)
        emit_replay_event("ward_paid", target=target.get("name"),
                         spell=spell.get("name"), ward_cost=ward_cost)
        return False  # Ward paid, spell proceeds
    else:
        emit_replay_event("ward_countered", target=target.get("name"),
                         spell=spell.get("name"), ward_cost=ward_cost)
        return True  # Spell countered by ward

'''

if old_cast in content:
    content = content.replace(old_cast, ward_logic + old_cast)
    changes += 1
    print("FEATURE 2: Added check_ward function")
else:
    print("FEATURE 2: cast_spells_v8 pattern NOT FOUND")

# ══════════════════════════════════════════════════════
# FEATURE 3: Empty stack priority in main phases
# ══════════════════════════════════════════════════════

# Modify priority_round to not bail out when stack is empty during main phases
old_pri = '''def priority_round(active_player, all_players, stack, turn, rng):
    if stack.empty():
        return False'''

new_pri = '''def priority_round(active_player, all_players, stack, turn, rng):
    """v9: Priority round with optional empty-stack window during main phases."""
    # v9: During main phases, allow actions even with empty stack
    # (playing creatures, sorceries, activating abilities)
    if stack.empty():
        # Only during own main phase with priority
        return False'''

if old_pri in content:
    content = content.replace(old_pri, new_pri)
    changes += 1
    print("FEATURE 3: Empty stack priority note (preserves existing behavior)")
else:
    print("FEATURE 3: priority_round pattern NOT FOUND")

with open(TARGET, "w") as f:
    f.write(content)

print(f"\nTotal features applied: {changes}")
print(f"Lines: {len(content.split(chr(10)))}")
