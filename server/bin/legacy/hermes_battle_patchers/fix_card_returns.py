#!/usr/bin/env python3
"""Add card data returns to simulate_game_v8"""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py"
with open(TARGET) as f:
    content = f.read()

# Find and modify the first return block (simpler simulate_game_v8 without approach)
old1 = '    if lorehold.is_alive():\n        alive_opps = sum(1 for o in opponents if o.is_alive())\n        if alive_opps == 0:\n            return "win", turn, "elimination"\n        return "stall", turn, f"opponents_alive={alive_opps}"\n    return "loss", turn, "life_zero"'

new1 = '    # Capture final card state for impact scoring\n    for c in lorehold.graveyard + lorehold.battlefield:\n        name = c.get("name", c.get("card_name", ""))\n        if name and not is_land(c):\n            cards_cast.add(name)\n\n    if lorehold.is_alive():\n        alive_opps = sum(1 for o in opponents if o.is_alive())\n        if alive_opps == 0:\n            return "win", turn, "elimination", cards_in_hand, cards_cast\n        return "stall", turn, f"opponents_alive={alive_opps}", cards_in_hand, cards_cast\n    return "loss", turn, "life_zero", cards_in_hand, cards_cast'

if old1 in content:
    content = content.replace(old1, new1)
    print("REPLACED first return block")
else:
    print("Pattern 1 NOT FOUND")

# Find and modify the approach-aware return block
search = 'if lorehold.is_alive():\n        alive_opps = sum(1 for o in opponents if o.is_alive())\n        if alive_opps == 0:\n            return "win", turn, "elimination"\n        return "stall", turn, f"opponents_alive={alive_opps}|found={approach_found}|countered={approach_countered}"\n    loss_tags = classify_loss'

if search in content:
    idx = content.find(search)
    chunk = content[idx:idx+500]
    print(f"Found approach block at {idx}")
    # Replace this block
    repl = '    for c in lorehold.graveyard + lorehold.battlefield:\n        name = c.get("name", c.get("card_name", ""))\n        if name and not is_land(c):\n            cards_cast.add(name)\n\n    if lorehold.is_alive():\n        alive_opps = sum(1 for o in opponents if o.is_alive())\n        if alive_opps == 0:\n            return "win", turn, "elimination", cards_in_hand, cards_cast\n        return "stall", turn, f"opponents_alive={alive_opps}|found={approach_found}|countered={approach_countered}", cards_in_hand, cards_cast\n    loss_tags = classify_loss'
    content = content.replace(search, repl)
    print("REPLACED approach block")
else:
    print("Pattern 2 NOT FOUND")
    # Show what's there
    idx = content.find('if lorehold.is_alive():')
    if idx >= 0:
        # Find second occurrence
        idx2 = content.find('if lorehold.is_alive():', idx + 10)
        if idx2 >= 0:
            print("Second block at", idx2, "=>", repr(content[idx2:idx2+250]))

with open(TARGET, "w") as f:
    f.write(content)
print("DONE")
