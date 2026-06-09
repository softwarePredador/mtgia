"""Add targeting partial resolution + tokens lifecycle to v9"""

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py"

with open(TARGET) as f:
    lines = f.readlines()

changes = 0

# 1. Add is_legal_target function (needed for partial resolution)
for i, line in enumerate(lines):
    if 'def game_winner(all_players):' in line:
        target_func = [
            '\n',
            'def is_legal_target(spell, target, controller, all_players):\n',
            '    """v9: Check if a target is still legal for a spell/ability (CR 608.2b)."""\n',
            '    if not isinstance(target, dict):\n',
            '        return False\n',
            '    # Hexproof: can\'t be targeted by opponents\n',
            '    if target.get("hexproof") and controller.name != target.get("controller"):\n',
            '        return False\n',
            '    # Shroud: can\'t be targeted at all\n',
            '    if target.get("shroud"):\n',
            '        return False\n',
            '    # Protection from source\'s color\n',
            '    protections = target.get("protection_from", [])\n',
            '    source_colors = spell.get("colors", [])\n',
            '    if any(c in protections for c in source_colors):\n',
            '        return False\n',
            '    # Ward: doesn\'t affect legality, only triggers on cast\n',
            '    # Target not eliminated\n',
            '    if target.get("eliminated"):\n',
            '        return False\n',
            '    return True\n',
            '\n',
        ]
        for j, tl in enumerate(target_func):
            lines.insert(i + j, tl)
        changes += 1
        print(f"Added is_legal_target at line {i}")
        break

# 2. Add token lifecycle handling
for i, line in enumerate(lines):
    if 'def check_sbas_until_stable(all_players):' in line:
        token_sba = [
            '\n',
            'def check_token_lifecycle(all_players):\n',
            '    """v9: Token SBAs — tokens cease to exist outside battlefield (CR 110.5f)."""\n',
            '    for p in all_players:\n',
            '        for zone_attr in ["graveyard", "exile", "hand"]:\n',
            '            zone = getattr(p, zone_attr, [])\n',
            '            for obj in list(zone):\n',
            '                if isinstance(obj, dict) and (obj.get("is_token") or obj.get("tag") == "token"):\n',
            '                    zone.remove(obj)  # Ceases to exist\n',
            '\n',
        ]
        for j, tl in enumerate(token_sba):
            lines.insert(i + j, tl)
        changes += 1
        print(f"Added token lifecycle at line {i}")
        break

# 3. Add copy spell function  
for i, line in enumerate(lines):
    if 'class StackItem:' in line:
        copy_func = [
            '\n',
            'def copy_spell_on_stack(original, controller, stack):\n',
            '    """v9: Copy a spell on the stack (CR 706.10).\n',
            '    The copy is NOT cast — triggers that care about casting do not fire.\n',
            '    """\n',
            '    if not isinstance(original, dict):\n',
            '        return None\n',
            '    copy = {\n',
            '        "name": original.get("name", ""),\n',
            '        "cmc": original.get("cmc", 0),\n',
            '        "type_line": original.get("type_line", ""),\n',
            '        "effect": original.get("effect", ""),\n',
            '        "is_copy": True,\n',
            '        "was_cast": False,\n',
            '        "controller": controller.name,\n',
            '        "colors": original.get("colors", []),\n',
            '        "modes": original.get("modes", []),\n',
            '        "targets": original.get("targets", []),\n',
            '    }\n',
            '    item = StackItem(copy, controller, {})\n',
            '    item.was_cast = False\n',
            '    stack.push(item)\n',
            '    return item\n',
            '\n',
        ]
        for j, cl in enumerate(copy_func):
            lines.insert(i + j, cl)
        changes += 1
        print(f"Added copy_spell_on_stack at line {i}")
        break

with open(TARGET, "w") as f:
    f.writelines(lines)

print(f"Total changes: {changes}")
print(f"Lines: {len(lines)}")
