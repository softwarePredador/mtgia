"""Add LKI + Zone Change Counter to battle_analyst_v9.py"""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"

with open(TARGET) as f:
    lines = f.readlines()

changes = 0

# 1. Add zone_id counter and LKI snapshot to move_creature_from_battlefield
for i, line in enumerate(lines):
    if 'def move_creature_from_battlefield(owner, creature):' in line:
        # Find the line BEFORE the zone checks: 'if not isinstance(creature, dict):'
        for j in range(i+1, min(i+20, len(lines))):
            if 'if not isinstance(creature, dict):' in lines[j]:
                indent = lines[j][:len(lines[j]) - len(lines[j].lstrip())]
                lki_code = [
                    f'\n',
                    f'{indent}# v9: LKI snapshot before zone change (CR 608.2g, 400.7)\n',
                    f'{indent}creature["_lki_snapshot"] = {{\n',
                    f'{indent}    "name": creature.get("name", creature.get("card_name", "")),\n',
                    f'{indent}    "power": creature.get("power", 0),\n',
                    f'{indent}    "toughness": creature.get("toughness", 0),\n',
                    f'{indent}    "cmc": creature.get("cmc", 0),\n',
                    f'{indent}    "type_line": creature.get("type_line", ""),\n',
                    f'{indent}    "is_commander": creature.get("is_commander", False),\n',
                    f'{indent}    "owner": creature.get("owner", creature.get("controller", "")),\n',
                    f'{indent}}}\n',
                    f'{indent}# v9: Zone change counter — new identity (CR 400.7)\n',
                    f'{indent}creature["_zone_id"] = creature.get("_zone_id", 0) + 1\n',
                    f'{indent}creature["_last_zone"] = "battlefield"\n',
                ]
                for k, cl in enumerate(lki_code):
                    lines.insert(j + k, cl)
                changes += 1
                print(f"Added LKI + zone counter to move_creature_from_battlefield at line {j}")
                break
        break

# 2. Add zone change counter tracking to Player
for i, line in enumerate(lines):
    if 'self.eliminated = False' in line and 'poison' not in lines[i+1]:
        indent = line[:len(line) - len(line.lstrip())]
        lines.insert(i+1, f'{indent}self.poison = 0  # v9\n')
        lines.insert(i+2, f'{indent}self.zone_change_events = 0  # v9: LKI counter\n')
        lines.insert(i+3, f'{indent}self.conceded = False  # v9\n')
        lines.insert(i+4, f'{indent}self.lost_by_effect = False  # v9\n')
        changes += 1
        print(f"Added Player tracking vars at line {i+1}")
        break

# 3. Add LKI accessor function  
lki_func = [
    '\n',
    'def get_lki(creature):\n',
    '    """v9: Get Last Known Information for a creature (CR 608.2g)."""\n',
    '    if isinstance(creature, dict) and "_lki_snapshot" in creature:\n',
    '        return creature["_lki_snapshot"]\n',
    '    # Fallback: derive from current state\n',
    '    return {\n',
    '        "name": creature.get("name", creature.get("card_name", "")),\n',
    '        "power": creature.get("power", 0),\n',
    '        "toughness": creature.get("toughness", 0),\n',
    '        "cmc": creature.get("cmc", 0),\n',
    '    }\n',
    '\n',
]

# Insert before move_creature_from_battlefield or after game_winner
for i, line in enumerate(lines):
    if 'def move_creature_from_battlefield(owner, creature):' in line:
        for j, fl in enumerate(lki_func):
            lines.insert(i + j, fl)
        changes += 1
        print(f"Added get_lki() at line {i}")
        break

with open(TARGET, "w") as f:
    f.writelines(lines)

print(f"Total changes: {changes}")
print(f"Lines: {len(lines)}")
