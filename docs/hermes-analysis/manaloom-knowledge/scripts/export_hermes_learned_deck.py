#!/usr/bin/env python3
"""Exporta um learned deck ativo do SQLite Hermes para JSON aceito por
   dart run bin/commander_learned_deck.dart --input-json=<path>.

Uso:
  python3 export_hermes_learned_deck.py [--db <sqlite_path>] [--out <json_path>]
     [--commander <name>] [--learned-id <id>] [--dry-run]
"""

import json, sqlite3, sys, os, re
from datetime import datetime, timezone

from learned_deck_completeness import learned_deck_completeness

def table_exists(db, table_name):
    return (
        db.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
            (table_name,),
        ).fetchone()
        is not None
    )

def column_exists(db, table_name, column_name):
    if not table_exists(db, table_name):
        return False
    return any(
        row[1] == column_name
        for row in db.execute(f"PRAGMA table_info({table_name})")
    )

def parse_card_list(card_list_text):
    text = str(card_list_text or "").strip()
    if text.startswith("["):
        try:
            cards_json = json.loads(text)
            cards = []
            for item in cards_json:
                name = item.get("name", "")
                qty = item.get("quantity", 1)
                if name:
                    cards.append({"name": name, "quantity": int(qty or 1)})
            return cards
        except Exception:
            pass
    cards = []
    for line in text.split("\n"):
        line = line.strip()
        if not line:
            continue
        m = re.match(r"^(\d+)\s+(.+)$", line)
        if m:
            cards.append({"name": m.group(2).strip(), "quantity": int(m.group(1))})
        else:
            cards.append({"name": line, "quantity": 1})
    return cards

def normalize_commander(name):
    return name.strip().lower().replace("\u2018", "'").replace("\u2019", "'").replace("  ", " ")

def compute_score(wincon_catalog_db, wincon_primary, wincon_backup):
    if not wincon_primary:
        return None
    names = [wincon_primary]
    if wincon_backup:
        names += [n.strip() for n in wincon_backup.split(";") if n.strip()]
    total = 0.0
    count = 0
    for name in names:
        row = wincon_catalog_db.execute(
            "SELECT total_score FROM wincon_catalog WHERE wincon_name LIKE ? LIMIT 1",
            (f"%{name}%",)
        ).fetchone()
        if row and row[0] is not None:
            total += float(row[0])
            count += 1
    return round(total / count, 1) if count > 0 else None


def parse_role_list(raw):
    roles = []
    if raw:
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                roles.extend(str(role).strip().lower() for role in parsed if str(role).strip())
        except Exception:
            roles.extend(str(role).strip().lower() for role in str(raw).split(",") if role.strip())
    return roles


def analysis_roles_for_card(db, target_deck_id, card_name):
    if not table_exists(db, "card_deck_analysis"):
        return []
    columns = {row[1] for row in db.execute("PRAGMA table_info(card_deck_analysis)").fetchall()}
    if "role_in_deck" not in columns:
        return []
    pg_roles_expr = "pg_roles" if "pg_roles" in columns else "NULL AS pg_roles"
    rows = db.execute(
        f"""
        SELECT role_in_deck, {pg_roles_expr}
        FROM card_deck_analysis
        WHERE deck_id = ? AND LOWER(card_name) = ?
        """,
        (target_deck_id, card_name.lower().strip()),
    ).fetchall()
    roles = []
    seen = set()
    for row in rows:
        for role in parse_role_list(row["pg_roles"] if "pg_roles" in row.keys() else None):
            if role not in seen:
                seen.add(role)
                roles.append(role)
        role = (row["role_in_deck"] or "").strip().lower()
        if role and role not in seen:
            seen.add(role)
            roles.append(role)
    return roles


def build_metadata(db, target_deck_id, card_list, commander):
    cards = parse_card_list(card_list)
    card_names = [c["name"].strip().lower() for c in cards]
    total_lands = 0
    ramp = draw = removal = tutor = wipe = protection = recursion = wincon = engine = 0

    land_keywords = ["plains", "island", "swamp", "mountain", "forest", "wastes",
                     "fetch", "shock", "surveil", "battlefield", "checkland",
                     "fastland", "slowland", "pathway", "canopy"]

    for card in cards:
        name = card["name"].lower().strip()
        qty = card["quantity"]
        type_line_row = None
        role_tags = []

        if target_deck_id and table_exists(db, "deck_cards"):
            type_line_row = db.execute(
                "SELECT type_line FROM deck_cards WHERE deck_id = ? AND LOWER(card_name) = ? LIMIT 1",
                (target_deck_id, name)
            ).fetchone()
            role_tags = analysis_roles_for_card(db, target_deck_id, name)

        is_land = False
        if type_line_row and type_line_row[0]:
            tl = type_line_row[0].lower()
            if "land" in tl:
                is_land = True
        else:
            is_land = any(kw in name for kw in land_keywords) or "land" in name

        if is_land:
            total_lands += qty
            continue

        role_tag = " ".join(role_tags)

        if "ramp" in role_tag:
            ramp += qty
        if "draw" in role_tag or "card" in role_tag:
            draw += qty
        if "removal" in role_tag:
            removal += qty
        if "tutor" in role_tag:
            tutor += qty
        if "wipe" in role_tag or "board" in role_tag:
            wipe += qty
        if "protect" in role_tag:
            protection += qty
        if "recur" in role_tag:
            recursion += qty
        if "win" in role_tag or "combo" in role_tag:
            wincon += qty
        if "engine" in role_tag or "value" in role_tag:
            engine += qty

    return {
        "total_lands": total_lands,
        "ramp_count": ramp,
        "draw_count": draw,
        "removal_count": removal,
        "tutor_count": tutor,
        "board_wipe_count": wipe,
        "protection_count": protection,
        "recursion_count": recursion,
        "wincon_count": wincon,
        "engine_count": engine,
    }

def export_learned_deck(db_path, out_path, commander_filter=None, learned_id=None, dry_run=False):
    db = sqlite3.connect(db_path)
    db.row_factory = sqlite3.Row

    # Find the active learned + promoted deck
    clauses = []
    params = []
    if column_exists(db, "deck_promotions", "migration_verified"):
        clauses.append("COALESCE(dp.migration_verified, 0) = 1")
    query = """
        SELECT ld.*, dp.promoted_at, dp.target_deck_id,
               d.deck_name as active_deck_name, d.total_cards as active_card_count
        FROM learned_decks ld
        JOIN deck_promotions dp ON dp.learned_deck_id = ld.id
        JOIN decks d ON d.id = dp.target_deck_id
    """
    if learned_id:
        clauses.append("ld.id = ?")
        params.append(learned_id)
    elif commander_filter:
        clauses.append("LOWER(ld.commander) LIKE ?")
        params.append(f"%{commander_filter.lower()}%")
    if clauses:
        query += " WHERE " + " AND ".join(clauses)
    query += " ORDER BY dp.promoted_at DESC LIMIT 1"

    row = db.execute(query, params).fetchone()
    if not row:
        print("Nenhum learned deck promovido encontrado.", file=sys.stderr)
        sys.exit(1)

    learned_id_val = row["id"]
    commander = row["commander"]
    deck_name = row["deck_name"]
    source = row["source"] or "hermes"
    card_list = row["card_list"]
    card_count = row["card_count"]
    wincon_primary = row["wincon_primary"]
    wincon_backup = row["wincon_backup"]
    promoted_at = row["promoted_at"]

    score = compute_score(db, wincon_primary, wincon_backup)
    target_deck_id = row["target_deck_id"]
    completeness = learned_deck_completeness(
        card_list,
        commander=commander,
        declared_quantity=card_count,
    )
    if not completeness.is_full_commander_deck():
        print(
            "Learned deck incompleto; export bloqueado: "
            f"learned_deck:{learned_id_val} total={completeness.total_with_commander} "
            f"main={completeness.main_quantity} "
            f"commander_in_list={completeness.commander_quantity_in_list}",
            file=sys.stderr,
        )
        sys.exit(2)

    output_card_list = card_list
    output_card_count = completeness.total_with_commander
    if completeness.commander_quantity_in_list == 0:
        output_card_list = f"1 {commander}\n{str(card_list or '').strip()}"

    # `card_list` is the promoted learned-deck truth. The exported metadata must
    # be rederived from that persisted list instead of trusting stale summary
    # counters in `decks`, which can diverge from the promoted composition.
    metadata = build_metadata(db, target_deck_id, output_card_list, commander)

    output = {
        "source_system": source,
        "source_ref": f"learned_deck:{learned_id_val}",
        "commander_name": commander,
        "deck_name": deck_name,
        "card_list": output_card_list,
        "card_count": output_card_count,
        "is_active": True,
        "score": score,
        "wincon_primary": wincon_primary,
        "wincon_backup": wincon_backup,
        "legal_status": "commander_legal",
        "source_url": row["source_url"],
        "archetype": row["archetype"],
        "metadata": metadata,
        "promoted_at": promoted_at,
        "notes": row["notes"] or f"Exported from Hermes SQLite learned_deck:{learned_id_val}",
    }

    if dry_run:
        print(json.dumps(output, indent=2, ensure_ascii=False, default=str))
        return

    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False, default=str)
    print(f"Exported to {out_path}")

def main(argv=None):
    import argparse

    parser = argparse.ArgumentParser(
        description="Export Hermes learned deck to PG import JSON",
    )
    parser.add_argument("--db", default="knowledge.db", help="SQLite database path")
    parser.add_argument("--out", default=None, help="Output JSON path")
    parser.add_argument(
        "--commander",
        default=None,
        help="Commander name filter",
    )
    parser.add_argument(
        "--learned-id",
        type=int,
        default=None,
        help="Specific learned deck ID",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print JSON to stdout only",
    )
    args = parser.parse_args(argv)

    if not args.out and not args.dry_run:
        args.out = "hermes_export.json"

    db_path = args.db
    if not os.path.isabs(db_path):
        db_path = os.path.join(os.path.dirname(__file__), db_path)

    export_learned_deck(
        db_path,
        args.out,
        args.commander,
        args.learned_id,
        args.dry_run,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
