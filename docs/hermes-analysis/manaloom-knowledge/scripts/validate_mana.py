#!/usr/bin/env python3
"""Mana base validation pipeline for ManaLoom project."""
import sqlite3, json, sys
from master_optimizer_common import resolve_default_knowledge_db

DB_PATH = str(resolve_default_knowledge_db())

PROFILE_FILES = {
    "kinnan_bonder_prodigy": "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/kinnan_bonder_prodigy.json",
    "atraxa_praetors_voice": "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/atraxa_praetors_voice.json",
    "korvold_fae_cursed_king": "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/korvold_fae_cursed_king.json",
    "teysa_karlov": "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/teysa_karlov.json",
    "aesi_tyrant_of_gyre_strait": "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/aesi_tyrant_of_gyre_strait.json",
    "winota_joiner_of_forces": "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/winota_joiner_of_forces.json",
    "yuriko_the_tigers_shadow": "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/yuriko_the_tigers_shadow.json",
}

CMD_ID_TO_PROFILE = {
    1: "kinnan_bonder_prodigy",
    2: "yuriko_the_tigers_shadow",
    3: "korvold_fae_cursed_king",
    4: "teysa_karlov",
    5: "aesi_tyrant_of_gyre_strait",
    6: None,
    7: "winota_joiner_of_forces",
    8: "atraxa_praetors_voice",
}

DB_COL_TO_ROLE = {
    "ramp_count": "ramp",
    "draw_count": "draw",
    "removal_count": "removal",
    "tutor_count": "tutor",
    "board_wipe_count": "board_wipes",
    "protection_count": "protection",
    "recursion_count": "recursion",
    "wincon_count": "wincon",
    "engine_count": "engine",
}

def check_range(value, min_val, max_val):
    if min_val is None and max_val is None:
        return ("N/A", 0, "")
    if value < min_val:
        diff = min_val - value
        if diff >= 4:
            return ("CRIT", diff, "below")
        elif diff >= 2:
            return ("WARN", diff, "below")
        elif diff == 1:
            return ("BLUE", diff, "below")
        else:
            return ("OK", 0, "")
    elif value > max_val:
        diff = value - max_val
        if diff >= 4:
            return ("CRIT", diff, "above")
        elif diff >= 2:
            return ("WARN", diff, "above")
        elif diff == 1:
            return ("BLUE", diff, "above")
        else:
            return ("OK", 0, "")
    else:
        return ("OK", 0, "in range")

def status_icon(s):
    return {"OK": "OK", "BLUE": "BLUE", "WARN": "WARN", "CRIT": "CRIT", "N/A": "N/A"}.get(s, s)

# Load profiles
profiles = {}
for key, path in PROFILE_FILES.items():
    with open(path) as f:
        profiles[key] = json.load(f)

# Connect DB
db = sqlite3.connect(DB_PATH)
db.row_factory = sqlite3.Row

decks = db.execute(
    "SELECT id, deck_name, commander_id, total_lands, avg_cmc, ramp_count, "
    "draw_count, removal_count, tutor_count, board_wipe_count, protection_count, "
    "recursion_count, wincon_count, engine_count, total_cards FROM decks"
).fetchall()

results = []
for deck in decks:
    dd = dict(deck)
    deck_id = dd["id"]
    cmd_id = dd["commander_id"]

    actual_lands = db.execute(
        "SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=? AND type_line LIKE '%land%'",
        (deck_id,)).fetchone()[0]
    actual_total = db.execute(
        "SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=?",
        (deck_id,)).fetchone()[0]

    profile_key = CMD_ID_TO_PROFILE.get(cmd_id)
    profile = profiles.get(profile_key) if profile_key else None

    res = {
        "deck_id": deck_id,
        "deck_name": dd["deck_name"],
        "cmd_id": cmd_id,
        "profile_key": profile_key,
        "db_total_cards": dd["total_cards"],
        "db_total_lands": dd["total_lands"],
        "sqlite_total": actual_total,
        "sqlite_lands": actual_lands,
        "db_metrics": {
            "ramp_count": dd["ramp_count"],
            "draw_count": dd["draw_count"],
            "removal_count": dd["removal_count"],
            "tutor_count": dd["tutor_count"],
            "board_wipe_count": dd["board_wipe_count"],
            "protection_count": dd["protection_count"],
            "recursion_count": dd["recursion_count"],
            "wincon_count": dd["wincon_count"],
            "engine_count": dd["engine_count"],
        },
        "profile_lands": None,
        "lands_check": None,
        "total_cards_check": None,
        "discrepancies": [],
        "crit_issues": [],
        "warn_issues": [],
        "blue_issues": [],
        "ok_issues": [],
        "profile_checks": [],
    }

    # Total cards integrity
    if actual_total == 100:
        res["total_cards_check"] = "OK"
    elif actual_total < 100:
        res["total_cards_check"] = f"CRIT (only {actual_total}/100)"
        res["crit_issues"].append(f"Incomplete deck: only {actual_total}/100 cards in deck_cards")
    else:
        res["total_cards_check"] = f"WARN ({actual_total}/100)"
        res["warn_issues"].append(f"Overfull deck: {actual_total}/100 cards in deck_cards")

    # DB vs SQLite discrepancies
    if dd["total_cards"] != actual_total:
        res["discrepancies"].append(f"DB total_cards={dd['total_cards']} vs SQLite SUM={actual_total}")
    if dd["total_lands"] != actual_lands:
        res["discrepancies"].append(f"DB total_lands={dd['total_lands']} vs SQLite land SUM={actual_lands}")

    if profile:
        role_targets = profile.get("role_targets", {})

        # Lands check
        pl = role_targets.get("lands", {})
        if pl:
            res["profile_lands"] = f"{pl.get('min')}-{pl.get('max')}"
            st, diff, direction = check_range(actual_lands, pl.get("min"), pl.get("max"))
            res["lands_check"] = f"{status_icon(st)} (SQLite={actual_lands}, prof={res['profile_lands']})"
            if st == "CRIT":
                res["crit_issues"].append(f"Lands {actual_lands} is {diff} {direction} profile [{pl.get('min')}-{pl.get('max')}]")
            elif st == "WARN":
                res["warn_issues"].append(f"Lands {actual_lands} is {diff} {direction} profile [{pl.get('min')}-{pl.get('max')}]")
            elif st == "BLUE":
                res["blue_issues"].append(f"Lands {actual_lands} is {diff} {direction} profile [{pl.get('min')}-{pl.get('max')}]")
            else:
                res["ok_issues"].append(f"Lands {actual_lands} in [{pl.get('min')}-{pl.get('max')}]")

        # Profile role checks
        matched_roles = set(DB_COL_TO_ROLE.values())
        for db_col, role_key in DB_COL_TO_ROLE.items():
            db_val = dd[db_col]
            rt = role_targets.get(role_key)
            if rt is None:
                continue
            mn, mx = rt.get("min"), rt.get("max")
            st, diff, direction = check_range(db_val, mn, mx)
            res["profile_checks"].append({
                "role": role_key, "db_val": db_val,
                "prof_min": mn, "prof_max": mx,
                "status": st, "diff": diff, "direction": direction
            })
            if st == "CRIT":
                res["crit_issues"].append(f"{role_key}: DB={db_val} is {diff} {direction} [{mn}-{mx}]")
            elif st == "WARN":
                res["warn_issues"].append(f"{role_key}: DB={db_val} is {diff} {direction} [{mn}-{mx}]")
            elif st == "BLUE":
                res["blue_issues"].append(f"{role_key}: DB={db_val} is {diff} {direction} [{mn}-{mx}]")
            else:
                res["ok_issues"].append(f"{role_key}: {db_val} in [{mn}-{mx}]")

        # Unmatched profile roles
        for rk, rv in role_targets.items():
            if rk == "lands" or rk in matched_roles:
                continue
            res["profile_checks"].append({
                "role": rk, "db_val": None,
                "prof_min": rv.get("min"), "prof_max": rv.get("max"),
                "status": "INFO", "diff": 0, "direction": "no DB col"
            })
    else:
        res["lands_check"] = "NO PROFILE"
        res["crit_issues"].append("No commander reference profile loaded")

    if res["crit_issues"]:
        res["overall_status"] = "CRIT"
    elif res["warn_issues"]:
        res["overall_status"] = "WARN"
    elif res["blue_issues"]:
        res["overall_status"] = "BLUE"
    else:
        res["overall_status"] = "OK"

    results.append(res)

db.close()
print(json.dumps(results, indent=2))
