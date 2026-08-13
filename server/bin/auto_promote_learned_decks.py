#!/usr/bin/env python3
"""Audita candidatos a learned deck sem promover nenhum deles.

Criterios minimos:
  - card_count == 100 por padrao
  - card_list parseado soma 100, com 1 comandante e 99 main
  - Commander nao-Lorehold (Lorehold e revisao manual)
  - Ainda nao promovido (nao existe em deck_promotions)
  - Tem deck alvo correspondente na tabela decks (mesmo commander)

O caminho automatico de promocao fica fail-closed ate existir o receipt
versionado DCK-P0-05. O modo padrao e dry-run e nao altera nem mesmo o SQLite
Hermes. ``--apply`` e qualquer opt-in legado de apply terminam com erro.
"""

import argparse, os, re, sqlite3, sys, json
from pathlib import Path


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
    already_promoted_filter = ""
    if _table_exists(db, "deck_promotions"):
        already_promoted_filter = """
          AND ld.id NOT IN (
            SELECT learned_deck_id
            FROM deck_promotions
            WHERE learned_deck_id IS NOT NULL
          )
        """
    return db.execute(
        f"""
        SELECT ld.id as learned_id, ld.commander, ld.deck_name, ld.card_count,
               ld.card_list, ld.wincon_primary
        FROM learned_decks ld
        WHERE ld.card_count >= ?
          AND LOWER(ld.commander) NOT LIKE '%lorehold%'
          AND ld.commander != ''
          {already_promoted_filter}
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
    parser = argparse.ArgumentParser(
        description="Audit Hermes learned deck promotion candidates",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Audita candidatos sem gravar (padrao)",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="Bloqueado ate o receipt DCK-P0-05",
    )
    args = parser.parse_args(argv)

    apply_requested = args.apply or os.environ.get("HERMES_AUTO_PROMOTE_APPLY") == "1"
    if apply_requested:
        print(
            "BLOCKED_DCK_P0_05: automatic learned-deck promotion is disabled; "
            "a reviewed, versioned promotion receipt is required.",
            file=sys.stderr,
        )
        return 2

    if not Path(SQLITE_DB).is_file():
        print(
            f"Nenhum SQLite Hermes encontrado em {SQLITE_DB}; "
            "dry-run sem efeito."
        )
        return 0

    db = sqlite3.connect(SQLITE_DB)
    print("=== Learned deck promotion candidate audit ===")
    print(f"mode=dry_run db={SQLITE_DB} promotion_allowed=false")

    candidates = _learned_candidates(db)

    if not candidates:
        print("Nenhum candidato elegivel.")
        db.close()
        return 0

    seen_cmd = set()
    eligible = 0
    skipped = 0
    unverified = 0
    for learned_id, commander, _deck_name, card_count, card_list, wincon in candidates:
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
        deck_id, _target_name, _target_cards = target

        # Verifica se ja foi promovido
        already = None
        if _table_exists(db, "deck_promotions"):
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

        print(
            f"CANDIDATE_ONLY {commander}: learned={learned_id} deck={deck_id} "
            f"cards={card_count} wincon={wincon[:80] if wincon else 'None'} "
            "promotion_allowed=false receipt_required=DCK-P0-05"
        )
        eligible += 1

    print(
        f"\nTOTALS eligible_candidates={eligible} promoted=0 "
        f"skipped={skipped} unverified={unverified}"
    )
    db.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
