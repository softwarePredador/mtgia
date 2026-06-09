#!/usr/bin/env python3
"""Patch slot_optimizer.py para respeitar roles reais do card_deck_analysis.
Evita swaps invalidos como Rise of the Eldrazi (wincon) → Erode (removal).
"""

import os, re

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py"
BACKUP = TARGET + ".bak_role_fix"

# Backup
if not os.path.exists(BACKUP):
    with open(TARGET) as f:
        original = f.read()
    with open(BACKUP, "w") as f:
        f.write(original)
    print("Backup: " + BACKUP)
else:
    # Restore from backup first (idempotent)
    with open(BACKUP) as f:
        original = f.read()
    with open(TARGET, "w") as f:
        f.write(original)
    print("Restored from backup")

with open(TARGET) as f:
    content = f.read()

# ── 1. Add imports ────────────────────────────────────────────────
if "from master_optimizer_common import" in content:
    # Add load_real_roles function after imports
    pass

# ── 2. Add ROLE_TO_CATEGORY mapping ───────────────────────────────
role_map = """
# Roles reais do card_deck_analysis → categorias do optimizer
# Prioridade maxima: evita swaps entre categorias diferentes
REAL_ROLE_TO_CATEGORY = {
    "wincon": "wincon",
    "finisher": "wincon",
    "combo": "wincon",
    "removal": "removal",
    "spot_removal": "removal",
    "ramp": "ramp",
    "ritual": "ramp",
    "mana_rock": "ramp",
    "draw": "draw",
    "card_advantage": "draw",
    "tutor": "tutor",
    "board_wipe": "wipe",
    "wipe": "wipe",
    "protection": "protection",
    "stax": "protection",
    "counter": "protection",
    "recursion": "engine",
    "graveyard": "engine",
    "engine": "engine",
    "value_engine": "engine",
    "copy": "engine",
    "land": "land",
}
"""

# Insert after EFFECT_TO_CATEGORY block
marker = "EFFECT_TO_CATEGORY = {"
idx = content.find(marker)
if idx > 0:
    # Find end of EFFECT_TO_CATEGORY dict
    end = content.find("\n\n", content.find("}", idx))
    if end > 0:
        content = content[:end] + role_map + content[end:]
        print("Added REAL_ROLE_TO_CATEGORY")

# ── 3. Add load_real_roles function ───────────────────────────────
load_func = """
def load_real_roles(conn, deck_id: int) -> dict[str, str]:
    roles = {}
    rows = []
    try:
        rows = conn.execute(
            \"SELECT LOWER(card_name) as name, LOWER(role_in_deck) as role FROM card_deck_analysis WHERE deck_id = ? AND role_in_deck IS NOT NULL AND role_in_deck != ''\",
            (deck_id,),
        ).fetchall()
    except Exception:
        return roles
    for row in rows:
        name = str(row[\"name\"] or \"\").strip()
        role = str(row[\"role\"] or \"\").strip().lower()
        if name and role:
            mapped = REAL_ROLE_TO_CATEGORY.get(role)
            if mapped:
                roles[name] = mapped
    return roles

"""

# Insert before category_for_card
marker = "def category_for_card(name: str, row, known_cards: dict[str, dict[str, object]]) -> str:"
idx = content.find(marker)
if idx > 0:
    content = content[:idx] + load_func + "\n" + content[idx:]
    print("Added load_real_roles")

# ── 4. Modify category_for_card to use real roles ─────────────────
old_func = """def category_for_card(name: str, row, known_cards: dict[str, dict[str, object]]) -> str:
    type_line = str(row["type_line"] or "")
    if "Land" in type_line:
        return "land"
    entry = known_cards.get(name, {})
    if entry.get("deck_category"):
        return str(entry["deck_category"])
    effect = str(entry.get("effect") or "")
    if effect in EFFECT_TO_CATEGORY:
        return EFFECT_TO_CATEGORY[effect]
    tag = str(row["functional_tag"] or "")"""

new_func = """def category_for_card(name: str, row, known_cards: dict[str, dict[str, object]]) -> str:
    type_line = str(row["type_line"] or "")
    if "Land" in type_line:
        return "land"
    entry = known_cards.get(name, {})
    if entry.get("deck_category"):
        return str(entry["deck_category"])
    # Prioridade: role real do card_deck_analysis > battle effect > functional tag
    real_role = _REAL_ROLES_CACHE.get(normalize_name(name), "")
    if real_role and real_role in REAL_ROLE_TO_CATEGORY:
        return REAL_ROLE_TO_CATEGORY[real_role]
    effect = str(entry.get("effect") or "")
    if effect in EFFECT_TO_CATEGORY:
        return EFFECT_TO_CATEGORY[effect]
    tag = str(row["functional_tag"] or "")"""

content = content.replace(old_func, new_func)
print("Modified category_for_card")

# ── 5. Add cache initialization in main scan function ─────────────
# Find the main scan function and add _REAL_ROLES_CACHE init
old_line = "    allowed = deck_commander_identity(conn, deck_id)"
new_line = """    # Cache real roles from card_deck_analysis (block cross-category swaps)
    global _REAL_ROLES_CACHE
    _REAL_ROLES_CACHE = load_real_roles(conn, deck_id)
    allowed = deck_commander_identity(conn, deck_id)"""
content = content.replace(old_line, new_line)
print("Added role cache init")

# ── 6. Add global declaration ─────────────────────────────────────
old_line = "def load_known_cards(db_path: str = str(DEFAULT_DB)) -> dict[str, dict[str, object]]:"
new_line = """_REAL_ROLES_CACHE: dict[str, str] = {}

def load_known_cards(db_path: str = str(DEFAULT_DB)) -> dict[str, dict[str, object]]:"""
content = content.replace(old_line, new_line)
print("Added global cache")

with open(TARGET, "w") as f:
    f.write(content)

print("DONE - slot_optimizer.py patched")
