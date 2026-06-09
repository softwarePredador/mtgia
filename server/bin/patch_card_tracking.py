#!/usr/bin/env python3
"""Clean patch: modify simulate_game_v8 to also return card data.
Only 1 change per function version: add cards_hand/cards_cast to return value.
"""

import re

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py"
with open(TARGET) as f:
    content = f.read()

patches = 0

# Find all return statements in simulate_game_v8
# Pattern: return "win", turn, "..." 
# Replace with: return "win", turn, "...", cards_hand, cards_cast

# But first, we need to add the card capture block before the returns.
# Find: "if lorehold.is_alive():\n        alive_opps = ..."
# Add: for c in lorehold.graveyard + lorehold.battlefield... cards_cast.add(name)
# Then replace all returns in the function.

# Find the function body
func_start = content.find("def simulate_game_v8(")
if func_start < 0:
    print("Function not found")
    exit(1)

# Find the end of function (next top-level def or EOF)
func_end = content.find("\ndef ", func_start + 10)
if func_end < 0:
    func_end = len(content)

func_body = content[func_start:func_end]
func_indent = 4  # function body is indented 4 spaces

# 1. Add cards_in_hand tracking init after mulligan section
# Find: '    for p in all_players:\n        play_mulligan(p, rng)\n\n    while'
old_init = '    for p in all_players:\n        play_mulligan(p, rng)\n\n    while lorehold.is_alive()'
if old_init in func_body:
    new_init = '    for p in all_players:\n        play_mulligan(p, rng)\n\n    cards_in_hand = set()\n    cards_cast = set()\n\n    while lorehold.is_alive()'
    func_body = func_body.replace(old_init, new_init)
    patches += 1
    print("Added card tracking init")

# 2. Track hand at each turn start (before play_turn_sequence)
# Find: '            if not player.is_alive():\n                continue\n            others'
# Capture hand for lorehold player before turn
old_turn = '            if not player.is_alive():\n                continue\n            others = [p for p in all_players if p != player]\n            play_turn_sequence_v8'
if old_turn in func_body:
    new_turn = '            if not player.is_alive():\n                continue\n            if player is lorehold:\n                for c in player.hand:\n                    card_name = c.get("name", c.get("card_name", ""))\n                    if card_name:\n                        cards_in_hand.add(card_name)\n            others = [p for p in all_players if p != player]\n            play_turn_sequence_v8'
    func_body = func_body.replace(old_turn, new_turn)
    patches += 1
    print("Added hand tracking")

# 3. Track casts at game end (graveyard + battlefield)
# Find: '\n    if lorehold.is_alive():'
# Add before it: card capture from graveyard + battlefield
old_end = '\n    if lorehold.is_alive():'
if old_end in func_body:
    # Only patch first occurrence (last block of the function)
    # Find the LAST 'if lorehold.is_alive():' in the function
    idx = func_body.rfind(old_end)
    if idx > 0:
        prefix = func_body[:idx]
        suffix = func_body[idx:]
        capture_block = '\n    for c in lorehold.graveyard + lorehold.battlefield:\n        card_name = c.get("name", c.get("card_name", ""))\n        if card_name and not is_land(c):\n            cards_cast.add(card_name)\n'
        func_body = prefix + capture_block + suffix
        patches += 1
        print("Added cast tracking at game end")

# 4. Modify all return statements to include card data
# Pattern: return "win", turn, "elimination"  -> return "win", turn, "elimination", cards_in_hand, cards_cast
# But we need to handle multi-line returns too
returns = re.findall(r'return\s+"([^"]+)",\s*turn,\s*(.+)', func_body)
for ret_result, ret_reason in returns:
    old_ret = f'return "{ret_result}", turn, {ret_reason}'
    new_ret = f'return "{ret_result}", turn, {ret_reason}, cards_in_hand, cards_cast'
    if old_ret in func_body:
        func_body = func_body.replace(old_ret, new_ret)
        patches += 1
        print(f"Modified return: {ret_result}")

# Also handle f-string returns
fstring_returns = re.findall(r'return\s+"([^"]+)",\s*turn,\s*(f".*?")', func_body)
for ret_result, ret_reason in fstring_returns:
    old_ret = f'return "{ret_result}", turn, {ret_reason}'
    new_ret = f'return "{ret_result}", turn, {ret_reason}, cards_in_hand, cards_cast'
    if old_ret in func_body:
        func_body = func_body.replace(old_ret, new_ret)
        patches += 1
        print(f"Modified f-string return: {ret_result}")

# Rebuild full content
new_content = content[:func_start] + func_body + content[func_end:]

with open(TARGET, "w") as f:
    f.write(new_content)

print(f"\nTotal patches: {patches}")
