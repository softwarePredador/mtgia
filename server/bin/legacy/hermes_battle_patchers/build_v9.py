#!/usr/bin/env python3
"""Build battle_analyst_v9.py from clean v8 with native card tracking + loss tags.

Modifications (clean, no fragile string matching):
1. Player.__init__: add tracking vars  
2. classify_loss(): root-cause loss tagging
3. simulate_game_v8: capture hand cards each turn, graveyard/battlefield at end
4. Return card data + loss tags
5. Output includes loss reasons
"""

import re, sys

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"

with open(TARGET) as f:
    lines = f.readlines()

changes = 0

# ── 1. Player.__init__: add tracking vars after self.eliminated ──
for i, line in enumerate(lines):
    if 'self.eliminated = False' in line and '#' not in line:
        indent = line[:len(line) - len(line.lstrip())]
        lines.insert(i + 1, f'{indent}# v9: card impact tracking\n')
        lines.insert(i + 2, f'{indent}self.total_mana_produced = 0\n')
        lines.insert(i + 3, f'{indent}self.nonland_spells_cast = 0\n')
        lines.insert(i + 4, f'{indent}self.mulligan_count = 0\n')
        lines.insert(i + 5, f'{indent}self.commander_times_removed = 0\n')
        lines.insert(i + 6, f'{indent}self.opponent_combo_detected = False\n')
        changes += 1
        print(f'  Line {i+1}: Added Player tracking vars')
        break

# ── 2. classify_loss function ──
classify_func = '''def classify_loss(player, opponents, turn, result, reason):
    """v9: Root-cause loss tagging."""
    tags = []
    if result != "loss":
        return tags
    lands_played = getattr(player, 'lands_played_this_turn', 0)
    current_mana = player.available_mana() if hasattr(player, 'available_mana') else 0
    nonland_count = sum(1 for c in (player.graveyard + player.hand) if not is_land(c))
    if turn >= 4 and current_mana < 3 and lands_played < 3:
        tags.append("screw")
    elif lands_played >= 7 and nonland_count <= 2:
        tags.append("flood")
    if player.mulligan_count >= 2 and turn < 6:
        tags.append("bad-mulligan")
    if player.commander_times_removed >= 3:
        tags.append("commander-removed")
    if player.opponent_combo_detected:
        tags.append("out-comboed")
    if turn >= 10 and "out-comboed" not in tags and "screw" not in tags and "flood" not in tags:
        tags.append("out-valued")
    if not tags:
        tags.append("combat-damage")
    return tags

'''

# Insert before first simulate_game_v8
for i, line in enumerate(lines):
    if line.strip().startswith('def simulate_game_v8('):
        lines.insert(i, classify_func)
        changes += 1
        print(f'  Line {i+1}: Added classify_loss')
        break

# ── 3. Mulligan tracking ──
for i, line in enumerate(lines):
    if line.strip().startswith('def play_mulligan('):
        # Add player.mulligan_count tracking
        # Find the 'keep = mulligan_decision(player.hand)' before 'return mulligan_count'
        for j in range(i+5, min(i+40, len(lines))):
            if 'return mulligan_count' in lines[j]:
                indent = lines[j][:len(lines[j]) - len(lines[j].lstrip())]
                lines.insert(j, f'{indent}player.mulligan_count = mulligan_count\n')
                changes += 1
                print(f'  Line {j+1}: Added mulligan_count tracking')
                break
        break

# ── 4. simulate_game_v8: card tracking ──
for i, line in enumerate(lines):
    if 'def simulate_game_v8(' in line:
        func_start = i
        break

# Find the 'for p in all_players:\n        play_mulligan(p, rng)' block
for i in range(func_start, len(lines)):
    if 'play_mulligan(p, rng)' in lines[i] and 'for p in all_players' in lines[i-1]:
        # Add card tracking init after this line
        indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
        lines.insert(i + 1, f'\n')
        lines.insert(i + 2, f'{indent}# v9: card impact tracking\n')
        lines.insert(i + 3, f'{indent}cards_in_hand = set()\n')
        lines.insert(i + 4, f'{indent}cards_cast = set()\n')
        lines.insert(i + 5, f'\n')
        changes += 1
        print(f'  Line {i+2}: Added card tracking init in simulate_game_v8')
        break

# ── 5. Capture hand cards at each lorehold turn ──
for i, line in enumerate(lines):
    if 'play_turn_sequence_v8(' in line and 'player, opponents, all_players' in line:
        indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
        # Insert before this line
        lines.insert(i, f'{indent}# v9: track lorehold hand for card impact\n')
        lines.insert(i+1, f'{indent}if player is lorehold:\n')
        lines.insert(i+2, f'{indent}    for c in player.hand:\n')
        lines.insert(i+3, f'{indent}        cn = c.get("name", c.get("card_name", ""))\n')
        lines.insert(i+4, f'{indent}        if cn:\n')
        lines.insert(i+5, f'{indent}            cards_in_hand.add(cn)\n')
        changes += 1
        print(f'  Line {i}: Added hand tracking at turn')
        break

# ── 6. Capture cast cards before return statements ──
# Find the LAST occurrence of 'if lorehold.is_alive():' before returns
last_alive = -1
for i, line in enumerate(lines):
    if line.strip() == 'if lorehold.is_alive():':
        last_alive = i

if last_alive > 0:
    indent = lines[last_alive][:len(lines[last_alive]) - len(lines[last_alive].lstrip())]
    capture = [
        f'\n',
        f'{indent}# v9: capture cast cards from graveyard+battlefield\n',
        f'{indent}for c in lorehold.graveyard + lorehold.battlefield:\n',
        f'{indent}    cn = c.get("name", c.get("card_name", ""))\n',
        f'{indent}    if cn and not is_land(c):\n',
        f'{indent}        cards_cast.add(cn)\n',
        f'\n',
    ]
    for j, cap_line in enumerate(capture):
        lines.insert(last_alive + j, cap_line)
    changes += 1
    print(f'  Line {last_alive}: Added cast tracking before returns')

# ── 7. Modify all return statements to include card data + loss tags ──
# Find returns in simulate_game_v8 function body
# Pattern: return "win", turn, "elimination" -> add cards and tags
return_pattern = re.compile(r'return\s+"(win|loss|stall)",\s*turn,\s*(.+)')

for i in range(func_start, len(lines)):
    line = lines[i]
    match = return_pattern.search(line)
    if match:
        result_type = match.group(1)
        reason_part = match.group(2).rstrip()
        # Add loss tags for loss returns
        if result_type == 'loss':
            # Replace reason with loss-tagged version
            old = f'return "{result_type}", turn, {reason_part}'
            new = 'loss_tags = classify_loss(lorehold, opponents, turn, "' + result_type + '", ' + reason_part.strip() + '); return "' + result_type + '", turn, f"{"+".join(loss_tags)}", cards_in_hand, cards_cast'
            lines[i] = new + '\n'
        else:
            old = f'return "{result_type}", turn, {reason_part}'
            # Keep original reason for win/stall, add card data
            if reason_part.strip().startswith('f"'):
                new = f'return "{result_type}", turn, {reason_part}, cards_in_hand, cards_cast'
            else:
                new = f'return "{result_type}", turn, {reason_part}, cards_in_hand, cards_cast'
            lines[i] = new + '\n'
        changes += 1
        print(f'  Line {i+1}: Modified return for {result_type}')

# ── 8. Update the battle output to show loss tags ──
for i, line in enumerate(lines):
    if 'win_reasons = defaultdict(int)' in line:
        indent = line[:len(line)-len(line.lstrip())]
        lines.insert(i+1, f'{indent}loss_reasons = defaultdict(int)\n')
        changes += 1
        print(f'  Line {i+1}: Added loss_reasons tracking')
    if line.strip() == 'elif result == "loss":' or line.strip() == 'elif result == "loss":':
        # Find the 'losses += 1' line after this
        for j in range(i+1, min(i+3, len(lines))):
            if 'losses += 1' in lines[j]:
                indent = lines[j][:len(lines[j])-len(lines[j].lstrip())]
                lines.insert(j+1, f'{indent}loss_reasons[reason] += 1\n')
                changes += 1
                print(f'  Line {j+1}: Added loss reason tracking')
                break
        break

# ── 9. Fix details output to show loss reasons ──
for i, line in enumerate(lines):
    if 'win_reasons.items()' in line and 'details' in line:
        indent = line[:len(line)-len(line.lstrip())]
        lines[i] = f'{indent}details_parts = [f"W:{{k}}={{v}}" for k, v in win_reasons.items()]\n'
        lines.insert(i+1, f'{indent}details_parts += [f"L:{{k}}={{v}}" for k, v in loss_reasons.items()]\n')
        lines.insert(i+2, f'{indent}details = ", ".join(details_parts) if details_parts else "-"\n')
        changes += 1
        print(f'  Line {i+1}: Fixed details output with loss reasons')

with open(TARGET, "w") as f:
    f.writelines(lines)

print(f'\nTotal changes: {changes}')
print(f'File: {len(lines)} lines')
