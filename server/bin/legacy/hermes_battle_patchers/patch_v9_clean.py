#!/usr/bin/env python3
"""Clean v9 patch — add creature SBA + SBA loop wrapper."""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py"

with open(TARGET) as f:
    lines = f.readlines()

# 1. Find check_sbas function end and add creature SBA before return False
for i, line in enumerate(lines):
    if line.strip() == 'return False' and i > 2520:
        # Check if this is the last return in check_sbas (before next def)
        if i + 2 < len(lines) and 'def game_winner' in lines[i+2]:
            indent = line[:len(line) - len(line.lstrip())]
            # Insert creature SBA before this return
            creature_sba = [
                '\n',
                f'{indent}# v9: Creature SBAs — toughness <= 0 or lethal damage\n',
                f'{indent}for p in all_players:\n',
                f'{indent}    for c in list(p.battlefield):\n',
                f'{indent}        toughness = c.get("toughness", 1)\n',
                f'{indent}        damage = c.get("damage_marked", 0)\n',
                f'{indent}        if (toughness <= 0 or damage >= toughness) and not c.get("indestructible"):\n',
                f'{indent}            move_creature_from_battlefield(p, c, "sba_lethal", None, all_players)\n',
                f'{indent}            return True\n',
            ]
            for j, cl in enumerate(creature_sba):
                lines.insert(i + j, cl)
            i += len(creature_sba)
            
            # Now add check_sbas_until_stable after the return False
            # Find the blank line before game_winner
            until_stable = [
                '\n',
                '\n',
                'def check_sbas_until_stable(all_players):\n',
                '    """v9: Loop SBAs until no more actions (CR 704.3)."""\n',
                '    while check_sbas(all_players):\n',
                '        pass\n',
            ]
            # Insert after the return False line (which moved by creature_sba lines)
            ret_idx = i  # after insertions
            for j, ul in enumerate(until_stable):
                lines.insert(ret_idx + j, ul)
            print(f"FIX 1: Added creature SBA + until_stable wrapper at line {i}")
            break

# 2. Replace key SBA call sites with until_stable
replacements = 0
for i, line in enumerate(lines):
    stripped = line.strip()
    # In simulate_game_v8: if check_sbas(all_players): break
    if stripped == 'if check_sbas(all_players):' and 'break' in lines[i+1]:
        indent = line[:len(line) - len(line.lstrip())]
        lines[i] = f'{indent}check_sbas_until_stable(all_players)\n'
        lines[i+1] = f'{indent}if any(hasattr(p, "eliminated") and p.eliminated for p in all_players):\n'
        lines.insert(i+2, f'{indent}    break\n')
        replacements += 1
    
    # In combat: check_sbas(all_players) 
    if stripped == 'check_sbas(all_players)' and 'combat' in ''.join(lines[max(0,i-30):i]).lower():
        lines[i] = line.replace('check_sbas(all_players)', 'check_sbas_until_stable(all_players)')
        replacements += 1

print(f"FIX 2: Replaced {replacements} SBA call sites")

with open(TARGET, "w") as f:
    f.writelines(lines)

print(f"Lines: {len(lines)}")
print("DONE")
