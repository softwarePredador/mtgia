#!/usr/bin/env python3
"""Lorehold Deck Evolution Oracle — cycle #2.

Applies at most three approved swaps based on Scout/Validator/Mulligan logs.
Evidence gates:
- Validator critical: lands below profile, wincons below profile.
- Scout 60%+: Hit the Mother Lode 8/8 (100%), Approach 6/8 (75%), Exotic Orchard is collection fallback for missing profile land.
- User collection checked before adding each card.
"""
from __future__ import annotations

import os
import sqlite3
from datetime import datetime, timezone

ROOT = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge"
DB = os.path.join(ROOT, "scripts", "knowledge.db")
LOG = os.path.join(ROOT, "decks", "lorehold-the-historian", "EVOLUTION_LOG.md")

SWAPS = [
    {
        "out": "Obliterate",
        "in": "Approach of the Second Sun",
        "in_tag": "wincon",
        "reason": "Validator marcou Wincons=3 como CRITICO; Approach aparece em 6/8 externos (75%) e EDHREC live 64%.",
    },
    {
        "out": "Apex of Power",
        "in": "Hit the Mother Lode",
        "in_tag": "token_maker",
        "reason": "Hit the Mother Lode aparece em 8/8 externos (100%) e EDHREC live 79%; troca ramp CMC10 por big spell sinergico CMC7.",
    },
    {
        "out": "Claim Jumper",
        "in": "Exotic Orchard",
        "in_tag": "land",
        "reason": "Validator marcou Lands=34 como CRITICO; Exotic Orchard existe na colecao e aumenta lands sem remover abaixo de 35.",
    },
]

TARGETS = {
    "lands": (36, 38),
    "ramp": (10, 13),
    "draw": (8, 12),
    "removal": (4, 6),
    "board_wipe": (3, 5),
    "protection": (3, 5),
    "recursion": (2, 5),
    "wincon": (4, 7),
    "engine": (5, 8),
}

PROFILE_FIELD = {
    "lands": "total_lands",
    "ramp": "ramp_count",
    "draw": "draw_count",
    "removal": "removal_count",
    "board_wipe": "board_wipe_count",
    "protection": "protection_count",
    "recursion": "recursion_count",
    "wincon": "wincon_count",
    "engine": "engine_count",
}


def get_conn(path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def fetch_collection_card(conn: sqlite3.Connection, name: str) -> sqlite3.Row:
    row = conn.execute(
        """
        SELECT card_en, quantity, type_line, oracle_text, cmc, functional_tag
        FROM user_collection
        WHERE LOWER(card_en) = LOWER(?) AND COALESCE(quantity, 0) > 0
        LIMIT 1
        """,
        (name,),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"Carta de entrada nao existe na user_collection: {name}")
    return row


def latest_lorehold_deck_id(conn: sqlite3.Connection) -> int:
    row = conn.execute(
        """
        SELECT d.id
        FROM decks d JOIN commanders c ON c.id = d.commander_id
        WHERE c.name LIKE '%Lorehold%'
        ORDER BY d.id DESC
        LIMIT 1
        """
    ).fetchone()
    if row is None:
        raise RuntimeError("Deck Lorehold nao encontrado")
    return int(row["id"])


def get_deck_card(conn: sqlite3.Connection, did: int, name: str) -> sqlite3.Row:
    row = conn.execute(
        "SELECT * FROM deck_cards WHERE deck_id = ? AND LOWER(card_name) = LOWER(?)",
        (did, name),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"Carta de saida nao existe no deck {did}: {name}")
    if row["is_commander"]:
        raise RuntimeError(f"Tentativa de remover commander bloqueada: {name}")
    return row


def card_tags_for_insert(name: str, tag: str, type_line: str | None, oracle_text: str | None) -> list[tuple[str, float, str]]:
    # Use deterministic tags from stored oracle when available; fall back to known collection tag.
    tl = type_line or ""
    ot = oracle_text or ""
    lower_tl = tl.lower()
    lower_ot = ot.lower()
    tags: list[tuple[str, float, str]] = []
    if "land" in lower_tl:
        tags.append(("land", 1.0, "type_line_land"))
        if "add " in lower_ot or "add one mana" in lower_ot:
            tags.append(("ramp", 0.88, "mana_or_land_ramp_text"))
    if "treasure" in lower_ot or "add " in lower_ot:
        if not any(t[0] == "ramp" for t in tags):
            tags.append(("ramp", 0.88, "mana_or_land_ramp_text"))
    if "draw" in lower_ot:
        tags.append(("draw", 0.84, "card_draw_text"))
    if "create" in lower_ot and "token" in lower_ot:
        tags.append(("token_maker", 0.82, "token_creation_text"))
    if "you win the game" in lower_ot:
        tags.append(("wincon", 0.78, "explicit_win_or_finisher_text"))
    if "exile" in lower_ot and ("cast" in lower_ot or "play" in lower_ot):
        tags.append(("exile_value", 0.84, "exile_play_or_cast_value_text"))
    if "destroy all" in lower_ot or "exile all" in lower_ot or "deals" in lower_ot and "each" in lower_ot:
        # Not used by this cycle inserts, intentionally conservative.
        pass
    if tag and not any(t[0] == tag for t in tags):
        tags.append((tag, 0.70, "user_collection_functional_tag"))
    # Deduplicate preserving max confidence.
    by = {}
    for t, conf, ev in tags:
        if t not in by or conf > by[t][0]:
            by[t] = (conf, ev)
    return [(t, conf, ev) for t, (conf, ev) in by.items()]


def insert_card(conn: sqlite3.Connection, did: int, name: str, tag: str) -> int:
    src = fetch_collection_card(conn, name)
    cmc = src["cmc"] if src["cmc"] is not None else 0
    conn.execute(
        """
        INSERT INTO deck_cards (deck_id, card_name, quantity, functional_tag, tag_confidence,
                                is_commander, is_partner, cmc, type_line, oracle_text)
        VALUES (?, ?, 1, ?, ?, 0, 0, ?, ?, ?)
        """,
        (did, src["card_en"], tag, 0.90, cmc, src["type_line"], src["oracle_text"]),
    )
    deck_card_id = int(conn.execute("SELECT last_insert_rowid()").fetchone()[0])
    for t, conf, ev in card_tags_for_insert(src["card_en"], tag, src["type_line"], src["oracle_text"]):
        conn.execute(
            "INSERT INTO card_tags (deck_card_id, card_name, tag, confidence, evidence) VALUES (?, ?, ?, ?, ?)",
            (deck_card_id, src["card_en"], t, conf, ev),
        )
    return deck_card_id


def delete_card(conn: sqlite3.Connection, did: int, name: str) -> None:
    row = get_deck_card(conn, did, name)
    conn.execute("DELETE FROM card_tags WHERE deck_card_id = ?", (row["id"],))
    conn.execute("DELETE FROM card_analyses WHERE deck_card_id = ?", (row["id"],))
    conn.execute("DELETE FROM deck_cards WHERE id = ?", (row["id"],))


def metric_count(conn: sqlite3.Connection, did: int, tag: str) -> int:
    if tag == "land":
        return int(conn.execute("SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=? AND functional_tag='land'", (did,)).fetchone()[0])
    # Multi-tag counts excluding lands, matching validator convention.
    return int(conn.execute(
        """
        SELECT COALESCE(SUM(dc.quantity),0)
        FROM deck_cards dc JOIN card_tags ct ON ct.deck_card_id = dc.id
        WHERE dc.deck_id = ? AND ct.tag = ?
          AND NOT EXISTS (SELECT 1 FROM card_tags l WHERE l.deck_card_id = dc.id AND l.tag = 'land')
        """,
        (did, tag),
    ).fetchone()[0])


def recalc(conn: sqlite3.Connection, did: int) -> dict[str, float | int]:
    qty = int(conn.execute("SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=?", (did,)).fetchone()[0])
    cmd_qty = int(conn.execute("SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=? AND is_commander=1", (did,)).fetchone()[0])
    lands = metric_count(conn, did, "land")
    nonlands = int(conn.execute("SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=? AND functional_tag!='land'", (did,)).fetchone()[0])
    nonland_cmc_sum = float(conn.execute("SELECT COALESCE(SUM(quantity * COALESCE(cmc,0)),0) FROM deck_cards WHERE deck_id=? AND functional_tag!='land'", (did,)).fetchone()[0])
    avg_cmc = round(nonland_cmc_sum / nonlands, 2) if nonlands else 0.0
    metrics = {
        "total_cards": qty,
        "commander_qty": cmd_qty,
        "total_lands": lands,
        "avg_cmc": avg_cmc,
        "ramp_count": metric_count(conn, did, "ramp"),
        "draw_count": metric_count(conn, did, "draw"),
        "removal_count": metric_count(conn, did, "removal"),
        "tutor_count": metric_count(conn, did, "tutor"),
        "board_wipe_count": metric_count(conn, did, "board_wipe"),
        "protection_count": metric_count(conn, did, "protection"),
        "recursion_count": metric_count(conn, did, "recursion"),
        "wincon_count": metric_count(conn, did, "wincon"),
        "engine_count": metric_count(conn, did, "engine"),
    }
    conn.execute(
        """
        UPDATE decks
        SET total_cards=?, total_lands=?, avg_cmc=?, ramp_count=?, draw_count=?, removal_count=?,
            tutor_count=?, board_wipe_count=?, protection_count=?, recursion_count=?, wincon_count=?, engine_count=?
        WHERE id=?
        """,
        (
            metrics["total_cards"], metrics["total_lands"], metrics["avg_cmc"],
            metrics["ramp_count"], metrics["draw_count"], metrics["removal_count"],
            metrics["tutor_count"], metrics["board_wipe_count"], metrics["protection_count"],
            metrics["recursion_count"], metrics["wincon_count"], metrics["engine_count"], did,
        ),
    )
    return metrics


def status(value: int, lo: int, hi: int) -> str:
    if lo <= value <= hi:
        return "✅ OK"
    if value < lo:
        return f"🔴 CRITICO ({value} < {lo})" if (lo - value) >= 2 else f"🟡 ALERTA ({value} < {lo})"
    return f"🟡 ALERTA ({value} > {hi})"


def append_log(before: sqlite3.Row, after: dict[str, float | int], did: int) -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    table_lines = ["| Métrica | Antes | Depois | EDHREC/Profile | Status depois |", "|:--|--:|--:|:--:|:--|"]
    for key, label in [
        ("total_lands", "Lands"), ("ramp_count", "Ramp"), ("draw_count", "Draw"),
        ("removal_count", "Spot interaction"), ("board_wipe_count", "Board wipes"),
        ("protection_count", "Protection"), ("recursion_count", "Recursion"),
        ("wincon_count", "Wincons"), ("engine_count", "Engines"),
    ]:
        target_key = key.replace("total_lands", "lands").replace("_count", "")
        lo, hi = TARGETS.get(target_key, (0, 99))
        table_lines.append(f"| {label} | {before[key]} | {after[key]} | {lo}-{hi} | {status(int(after[key]), lo, hi)} |")
    block = []
    block.append(f"\n## [{ts}] Execucao #2\n")
    block.append("### Aprendizados desta rodada\n")
    block.append("- Scout: o scout ampliado consolidou 8 decks externos + EDHREC live (7597 decks). Ausentes com gate 60%+: Hit the Mother Lode 8/8 (100%), Approach of the Second Sun 6/8 (75%), Big Score 5/8 (62%), Improvisation Capstone 6/8 (75%) e lands como Battlefield Forge/Elegant Parlor/Spectator Seating.\n")
    block.append("- Validator: dois criticos guiam a evolucao: Lands=34 abaixo de 36-38 e Wincons=3 abaixo de 4-7; alertas adicionais: Ramp=17 acima de 10-13, Protection=7 acima de 3-5, Board wipes=6 acima de 3-5.\n")
    block.append("- Mulligan: 23.0% de mulligan, abaixo do threshold critico de 30%; nao exige emergencia, mas reforca que +1 land melhora consistencia sem revolucao.\n")
    block.append("\n### Mudancas aplicadas (max 3)\n")
    block.append("1. **SAI:** Obliterate → **ENTRA:** Approach of the Second Sun — corrige o critico de wincons (3→4) com carta presente em 6/8 externos e 64% EDHREC live; tambem reduz wipes superavitarios.\n")
    block.append("2. **SAI:** Apex of Power → **ENTRA:** Hit the Mother Lode — troca ramp/big spell CMC 10 por staple universal externo (8/8; 79% EDHREC live) que descobre 10 e gera Treasure no plano de cast gratuito/topdeck.\n")
    block.append("3. **SAI:** Claim Jumper → **ENTRA:** Exotic Orchard — aplica o critico de lands adicionando land RW-legal existente na user_collection; Claim Jumper era ramp fragil e o deck estava acima do range de ramp.\n")
    block.append("\n### Estado do deck apos mudancas\n")
    block.append(f"- Deck DB id: {did}\n")
    block.append(f"- Total cards: {after['total_cards']} (confirmado); commander_qty: {after['commander_qty']}\n")
    block.append(f"- Avg CMC recalculado: {after['avg_cmc']}\n")
    block.append("\n" + "\n".join(table_lines) + "\n")
    block.append("\n### Licoes aprendidas\n")
    block.append("- Para Lorehold, wincon dedicada importa: Approach combina com topdeck manipulation e resolve o gap do validator sem depender de combate.\n")
    block.append("- Hit the Mother Lode e melhor que apenas 'mais ramp': e uma carta de identidade Lorehold, porque transforma topo do deck em spell gratis e Treasure.\n")
    block.append("- Quando o scout pede lands especificas ausentes da colecao, a evolucao deve respeitar user_collection e usar o melhor fallback real disponivel, documentando que nao e staple externo.\n")
    with open(LOG, "a", encoding="utf-8") as f:
        f.write("".join(block))


def main() -> None:
    conn = get_conn(DB)
    try:
        did = latest_lorehold_deck_id(conn)
        before = conn.execute("SELECT * FROM decks WHERE id=?", (did,)).fetchone()
        # pre-check all additions exist in user_collection before any mutation
        for sw in SWAPS:
            fetch_collection_card(conn, sw["in"])
            get_deck_card(conn, did, sw["out"])
        # never remove lands below 35: only land-ish removal? none. Confirm commander count/total before.
        pre_qty = conn.execute("SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=?", (did,)).fetchone()[0]
        pre_cmd = conn.execute("SELECT COALESCE(SUM(quantity),0) FROM deck_cards WHERE deck_id=? AND is_commander=1", (did,)).fetchone()[0]
        if pre_qty != 100 or pre_cmd != 1:
            raise RuntimeError(f"Precondition failed: total={pre_qty}, commander_qty={pre_cmd}")
        for sw in SWAPS:
            delete_card(conn, did, sw["out"])
            insert_card(conn, did, sw["in"], sw["in_tag"])
        after = recalc(conn, did)
        if after["total_cards"] != 100 or after["commander_qty"] != 1:
            raise RuntimeError(f"Postcondition failed: total={after['total_cards']}, commander_qty={after['commander_qty']}")
        if after["total_lands"] < 35:
            raise RuntimeError(f"Postcondition failed: lands below 35 ({after['total_lands']})")
        append_log(before, after, did)
        conn.commit()
        print("APPLIED", len(SWAPS), "swaps to deck", did)
        print("BEFORE", {k: before[k] for k in ['total_cards','total_lands','avg_cmc','ramp_count','draw_count','removal_count','board_wipe_count','protection_count','recursion_count','wincon_count','engine_count']})
        print("AFTER", after)
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    main()
