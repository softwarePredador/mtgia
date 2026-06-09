#!/usr/bin/env python3
import sys

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py"

with open(TARGET) as f:
    lines = f.readlines()

# Find classify_loss function boundaries
start = -1
end = -1
for i, line in enumerate(lines):
    if line.strip().startswith("def classify_loss("):
        start = i
    if start >= 0 and line.strip() == "return tags" and i > start + 5:
        end = i
        break

if start < 0 or end < 0:
    print("Could not find classify_loss boundaries")
    sys.exit(1)

print(f"Found classify_loss: lines {start}-{end}")

# New function body
new_body = [
    '    tags = []\n',
    '\n',
    '    if result != "loss":\n',
    '        return tags\n',
    '\n',
    '    lands_played = getattr(player, "lands_played_this_turn", 0)\n',
    '    current_mana = player.available_mana()\n',
    '    nonland_count = sum(1 for c in (player.graveyard + player.hand) if not is_land(c))\n',
    '\n',
    '    # Screw: morreu tarde e ainda tinha pouca mana\n',
    '    if turn >= 4 and current_mana < 3 and lands_played < 3:\n',
    '        tags.append("screw")\n',
    '\n',
    '    # Flood: muitas lands vs poucas spells\n',
    '    elif lands_played >= 7 and nonland_count <= 2:\n',
    '        tags.append("flood")\n',
    '\n',
    '    # Bad mulligan\n',
    '    if player.mulligan_count >= 2 and turn < 6:\n',
    '        tags.append("bad-mulligan")\n',
    '\n',
    '    # Commander removed 3+ times\n',
    '    if player.commander_times_removed >= 3:\n',
    '        tags.append("commander-removed")\n',
    '\n',
    '    # Out-comboed\n',
    '    if player.opponent_combo_detected:\n',
    '        tags.append("out-comboed")\n',
    '\n',
    '    # Out-valued: jogo longo sem causa especifica\n',
    '    if turn >= 10 and "out-comboed" not in tags and "screw" not in tags and "flood" not in tags:\n',
    '        tags.append("out-valued")\n',
    '\n',
    '    if not tags:\n',
    '        tags.append("combat-damage")\n',
    '\n',
    '    return tags\n',
]

# Replace body (lines between start+1 and end-1)
new_lines = lines[:start+1] + new_body + lines[end+1:]

with open(TARGET, "w") as f:
    f.writelines(new_lines)

print("REPLACED classify_loss body")
