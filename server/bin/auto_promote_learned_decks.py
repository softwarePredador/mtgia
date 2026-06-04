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

import os, re, sqlite3, sys
from datetime import datetime, timezone

SQLITE_DB = os.environ.get(
    "HERMES_KNOWLEDGE_DB",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
)

REQUIRE_EXACT_100 = os.environ.get("HERMES_AUTO_PROMOTE_ALLOW_INCOMPLETE") != "1"
MIN_CARD_COUNT = 100 if REQUIRE_EXACT_100 else 90


def _normalize_name(name):
    return (name or "").strip().lower().replace("’", "'").replace("‘", "'")


def _parse_card_list(card_list_text):
    cards = []
    for raw_line in (card_list_text or "").splitlines():
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


def main():
    db = sqlite3.connect(SQLITE_DB)
    print("=== Auto-promote learned decks ===")

    candidates = db.execute("""
        SELECT ld.id as learned_id, ld.commander, ld.deck_name, ld.card_count,
               ld.card_list,
               ld.wincon_primary, d.id as deck_id, d.deck_name as target_name,
               d.total_cards as target_cards
        FROM learned_decks ld
        JOIN decks d ON d.commander_id = (
            SELECT c.id FROM commanders c
            WHERE LOWER(c.name) = LOWER(ld.commander)
            LIMIT 1
        )
        WHERE ld.card_count >= ?
          AND LOWER(ld.commander) NOT LIKE '%lorehold%'
          AND ld.id NOT IN (SELECT learned_deck_id FROM deck_promotions)
          AND ld.commander != ''
        ORDER BY ld.commander, ld.card_count DESC
    """, (MIN_CARD_COUNT,)).fetchall()

    if not candidates:
        print("Nenhum candidato elegivel.")
        db.close()
        return 0

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    promoted = 0

    seen_cmd = set()
    for learned_id, commander, deck_name, card_count, card_list, wincon, deck_id, target_name, target_cards in candidates:
        if commander in seen_cmd:
            continue
        seen_cmd.add(commander)

        blockers = _commander_gate(commander, card_count, card_list)
        if blockers:
            print(f"SKIP {commander}: commander_gate_failed {'; '.join(blockers)}")
            continue

        # Verifica se ja foi promovido
        already = db.execute(
            "SELECT id FROM deck_promotions WHERE learned_deck_id=? OR target_deck_id=?",
            (learned_id, deck_id),
        ).fetchone()
        if already:
            print(f"SKIP {commander}: already promoted")
            continue

        notes = f"Auto-promoted: {card_count} cards"
        if wincon:
            notes += f", wincon: {wincon[:120]}"

        db.execute(
            """INSERT INTO deck_promotions
               (promoted_at, target_deck_id, learned_deck_id,
                previous_deck_name, new_deck_name,
                previous_card_count, new_card_count, notes)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                now, deck_id, learned_id,
                target_name, deck_name,
                target_cards or 0, card_count, notes,
            ),
        )
        print(f"PROMOTED {commander}: learned={learned_id} deck={deck_id} cards={card_count} wincon={wincon[:80] if wincon else 'None'}")
        promoted += 1

    db.commit()
    print(f"\nTOTALS promoted={promoted}")
    db.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
