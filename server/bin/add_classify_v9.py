"""Add classify_loss to battle_analyst_v9.py"""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"

with open(TARGET) as f:
    lines = f.readlines()

# Find simulate_game_v8
func_start = None
for i, line in enumerate(lines):
    if line.strip().startswith('def simulate_game_v8('):
        func_start = i
        break

if func_start is None:
    print("simulate_game_v8 NOT FOUND")
    exit(1)

classify_func = [
    '\n',
    'def classify_loss(player, opponents, turn, result, reason):\n',
    '    """v9: Root-cause canonical loss tagging (CR 104.2-104.5, 903.14)."""\n',
    '    tags = []\n',
    '    if result != "loss":\n',
    '        return tags\n',
    '    \n',
    '    current_mana = player.available_mana() if hasattr(player, "available_mana") else 0\n',
    '    lands_played = getattr(player, "lands_played_this_turn", 0)\n',
    '    nonland_count = sum(1 for c in (player.graveyard + player.hand) if not is_land(c))\n',
    '    mulligans = getattr(player, "_mulligan_count", 0)\n',
    '    \n',
    '    if turn >= 4 and current_mana < 3 and lands_played < 3:\n',
    '        tags.append("screw")\n',
    '    elif lands_played >= 7 and nonland_count <= 2:\n',
    '        tags.append("flood")\n',
    '    if mulligans >= 2 and turn < 6:\n',
    '        tags.append("bad-mulligan")\n',
    '    if getattr(player, "_commander_removals", 0) >= 3:\n',
    '        tags.append("commander-removed")\n',
    '    if turn >= 10 and "screw" not in tags and "flood" not in tags:\n',
    '        tags.append("out-valued")\n',
    '    \n',
    '    # v9: Canonical loss taxonomy\n',
    '    if getattr(player, "poison", 0) >= 10:\n',
    '        tags.insert(0, "poison")\n',
    '    if getattr(player, "lost_by_effect", False):\n',
    '        tags.insert(0, "effect_says_lose")\n',
    '    if getattr(player, "conceded", False):\n',
    '        tags.insert(0, "concede")\n',
    '    \n',
    '    if not tags:\n',
    '        tags.append("combat-damage")\n',
    '    return tags\n',
    '\n',
]

for j, cl in enumerate(classify_func):
    lines.insert(func_start + j, cl)

with open(TARGET, "w") as f:
    f.writelines(lines)

print(f"Added classify_loss + canonical taxonomy before line {func_start + 1}")
print(f"Lines: {len(lines)}")
