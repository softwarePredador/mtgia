#!/usr/bin/env python3
"""Auto-promove learned decks de alta qualidade que ainda nao estao promovidos.

Criterios minimos:
  - card_count == 100 por padrao
  - card_list parseado soma 100, com 1 comandante e 99 main
  - Commander nao-Lorehold (Lorehold e revisao manual)
  - Ainda nao promovido (nao existe em deck_promotions)
  - Tem deck alvo correspondente na tabela decks (mesmo commander)

Seguro para rodar em cron: idempotente (checa deck_promotions antes de inserir).
"""

import argparse, os, re, sqlite3, sys, json
from pathlib import Path
from datetime import datetime, timezone


def _resolve_repo_root() -> Path:
    if os.environ.get("MANALOOM_REPO"):
        return Path(os.environ["MANALOOM_REPO"]).resolve()
    return Path(__file__).resolve().parents[2]


REPO_ROOT = _resolve_repo_root()
DEFAULT_SQLITE_DB = (
    REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)
SQLITE_DB = os.environ.get("HERMES_KNOWLEDGE_DB", str(DEFAULT_SQLITE_DB))

REQUIRE_EXACT_100 = os.environ.get("HERMES_AUTO_PROMOTE_ALLOW_INCOMPLETE") != "1"
MIN_CARD_COUNT = 100 if REQUIRE_EXACT_100 else 90


def _table_exists(db, table_name):
    return (
        db.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
            (table_name,),
        ).fetchone()
        is not None
    )


def _columns(db, table_name):
    if not _table_exists(db, table_name):
        return set()
    return {row[1] for row in db.execute(f"PRAGMA table_info({table_name})")}


def _ensure_deck_promotions_schema(db):
    db.execute(
        """
        CREATE TABLE IF NOT EXISTS deck_promotions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            promoted_at TEXT NOT NULL,
            target_deck_id INTEGER NOT NULL,
            learned_deck_id INTEGER NOT NULL,
            previous_deck_name TEXT,
            new_deck_name TEXT,
            previous_card_count INTEGER DEFAULT 0,
            new_card_count INTEGER DEFAULT 0,
            actual_card_count INTEGER DEFAULT 0,
            migration_verified INTEGER DEFAULT 0,
            migration_checked_at TEXT,
            notes TEXT
        )
        """
    )
    existing = _columns(db, "deck_promotions")
    for name, ddl in {
        "target_deck_id": "INTEGER",
        "learned_deck_id": "INTEGER",
        "previous_deck_name": "TEXT",
        "new_deck_name": "TEXT",
        "previous_card_count": "INTEGER DEFAULT 0",
        "new_card_count": "INTEGER DEFAULT 0",
        "actual_card_count": "INTEGER DEFAULT 0",
        "migration_verified": "INTEGER DEFAULT 0",
        "migration_checked_at": "TEXT",
        "notes": "TEXT",
    }.items():
        if name not in existing:
            db.execute(f"ALTER TABLE deck_promotions ADD COLUMN {name} {ddl}")
    db.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS idx_deck_promotions_learned
        ON deck_promotions (learned_deck_id)
        """
    )
    db.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_deck_promotions_target
        ON deck_promotions (target_deck_id)
        """
    )


def _normalize_name(name):
    return (name or "").strip().lower().replace("’", "'").replace("‘", "'")


def _parse_card_list(card_list_text):
    text = (card_list_text or "").strip()
    if text.startswith("["):
        try:
            cards_json = json.loads(text)
            cards = []
            for item in cards_json:
                name = item.get("name", "")
                qty = item.get("quantity", 1)
                if name:
                    cards.append((int(qty), name))
            return cards
        except Exception:
            pass
    cards = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        match = re.match(r"^(\d+)\s+(.+)$", line)
        if match:
            cards.append((int(match.group(1)), match.group(2).strip()))
        else:
            cards.append((1, line))
    return cards


def _commander_gate(commander, card_count, card_list):
    cards = _parse_card_list(card_list)
    parsed_total = sum(qty for qty, _ in cards)
    commander_normalized = _normalize_name(commander)
    commander_qty = sum(
        qty for qty, name in cards if _normalize_name(name) == commander_normalized
    )
    main_qty = parsed_total - commander_qty
    blockers = []
    if REQUIRE_EXACT_100 and card_count != 100:
        blockers.append(f"declared_card_count={card_count}")
    if REQUIRE_EXACT_100 and parsed_total != 100:
        blockers.append(f"parsed_card_count={parsed_total}")
    if REQUIRE_EXACT_100 and commander_qty != 1:
        blockers.append(f"commander_qty={commander_qty}")
    if REQUIRE_EXACT_100 and main_qty != 99:
        blockers.append(f"main_qty={main_qty}")
    return blockers


def _learned_candidates(db):
    if not _table_exists(db, "learned_decks") or not _table_exists(db, "decks"):
        return []
    return db.execute(
        """
        SELECT ld.id as learned_id, ld.commander, ld.deck_name, ld.card_count,
               ld.card_list, ld.wincon_primary
        FROM learned_decks ld
        WHERE ld.card_count >= ?
          AND LOWER(ld.commander) NOT LIKE '%lorehold%'
          AND ld.commander != ''
          AND ld.id NOT IN (
            SELECT learned_deck_id
            FROM deck_promotions
            WHERE learned_deck_id IS NOT NULL
          )
        ORDER BY ld.commander, ld.card_count DESC
        """,
        (MIN_CARD_COUNT,),
    ).fetchall()


def _target_deck_for_commander(db, commander):
    deck_columns = _columns(db, "decks")
    if "commander_id" in deck_columns and _table_exists(db, "commanders"):
        return db.execute(
            """
            SELECT d.id, d.deck_name, d.total_cards
            FROM decks d
            JOIN commanders c ON c.id = d.commander_id
            WHERE LOWER(c.name) = LOWER(?)
            ORDER BY d.id DESC
            LIMIT 1
            """,
            (commander,),
        ).fetchone()

    # Reduced Hermes cache schema: no commander_id. Match only existing decks
    # whose visible name clearly references the commander.
    return db.execute(
        """
        SELECT d.id, d.deck_name, d.total_cards
        FROM decks d
        WHERE LOWER(d.deck_name) = LOWER(?)
           OR LOWER(d.deck_name) LIKE '%' || LOWER(?) || '%'
           OR LOWER(?) LIKE '%' || LOWER(d.deck_name) || '%'
        ORDER BY LENGTH(d.deck_name), d.id DESC
        LIMIT 1
        """,
        (commander, commander, commander),
    ).fetchone()


def _target_deck_card_state(db, deck_id):
    if not _table_exists(db, "deck_cards"):
        return 0, 0
    row = db.execute(
        """
        SELECT COALESCE(SUM(quantity), 0) as qty,
               COALESCE(SUM(CASE WHEN is_commander = 1 THEN quantity ELSE 0 END), 0)
        FROM deck_cards
        WHERE deck_id = ?
        """,
        (deck_id,),
    ).fetchone()
    return int(row[0] or 0), int(row[1] or 0)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Auto-promote Hermes learned decks")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Valida candidatos sem gravar deck_promotions",
    )
    args = parser.parse_args(argv)
    dry_run = args.dry_run or os.environ.get("HERMES_AUTO_PROMOTE_DRY_RUN") == "1"

    db = sqlite3.connect(SQLITE_DB)
    print("=== Auto-promote learned decks ===")
    print(f"mode={'dry_run' if dry_run else 'apply'} db={SQLITE_DB}")

    _ensure_deck_promotions_schema(db)
    candidates = _learned_candidates(db)

    if not candidates:
        print("Nenhum candidato elegivel.")
        if not dry_run:
            db.commit()
        db.close()
        return 0

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    promoted = 0

    seen_cmd = set()
    skipped = 0
    unverified = 0
    for learned_id, commander, deck_name, card_count, card_list, wincon in candidates:
        if commander in seen_cmd:
            continue
        seen_cmd.add(commander)

        blockers = _commander_gate(commander, card_count, card_list)
        if blockers:
            print(f"SKIP {commander}: commander_gate_failed {'; '.join(blockers)}")
            skipped += 1
            continue

        target = _target_deck_for_commander(db, commander)
        if not target:
            print(f"SKIP {commander}: no_target_deck")
            skipped += 1
            continue
        deck_id, target_name, target_cards = target

        # Verifica se ja foi promovido
        already = db.execute(
            "SELECT id FROM deck_promotions WHERE learned_deck_id=? OR target_deck_id=?",
            (learned_id, deck_id),
        ).fetchone()
        if already:
            print(f"SKIP {commander}: already promoted")
            skipped += 1
            continue

        actual_cards, commander_cards = _target_deck_card_state(db, deck_id)
        migration_verified = int(
            actual_cards == card_count
            and (not REQUIRE_EXACT_100 or (actual_cards == 100 and commander_cards == 1))
        )
        if not migration_verified:
            print(
                f"SKIP {commander}: target_not_verified "
                f"target_deck_id={deck_id} claimed={card_count} actual={actual_cards} "
                f"commander_qty={commander_cards}"
            )
            unverified += 1
            continue

        notes = f"Auto-promoted: {card_count} cards"
        if wincon:
            notes += f", wincon: {wincon[:120]}"

        if not dry_run:
            db.execute(
                """INSERT INTO deck_promotions
                   (promoted_at, target_deck_id, learned_deck_id,
                    previous_deck_name, new_deck_name,
                    previous_card_count, new_card_count, actual_card_count,
                    migration_verified, migration_checked_at, notes)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    now, deck_id, learned_id,
                    target_name, deck_name,
                    target_cards or 0, card_count, actual_cards,
                    migration_verified, now, notes,
                ),
            )
        print(f"PROMOTED {commander}: learned={learned_id} deck={deck_id} cards={card_count} wincon={wincon[:80] if wincon else 'None'}")
        promoted += 1

    if not dry_run:
        db.commit()
    print(f"\nTOTALS promoted={promoted} skipped={skipped} unverified={unverified}")
    db.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
