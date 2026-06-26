#!/usr/bin/env python3
"""Promote a confirmed Lorehold optimizer swap into an equal battle gate."""

from __future__ import annotations

import argparse
import json
import shutil
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import DEFAULT_DB, connect, normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def load_swap_row(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    baseline_id: int | None,
    phase: str,
    only_added: str,
) -> sqlite3.Row:
    clauses = ["deck_id=?", "phase=?"]
    params: list[Any] = [deck_id, phase]
    if baseline_id is not None:
        clauses.append("baseline_id=?")
        params.append(baseline_id)
    if only_added:
        clauses.append("lower(card_added)=lower(?)")
        params.append(only_added)
    row = conn.execute(
        f"""
        SELECT *
        FROM swap_benchmarks
        WHERE {' AND '.join(clauses)}
        ORDER BY id DESC
        LIMIT 1
        """,
        params,
    ).fetchone()
    if row is None:
        raise RuntimeError(
            f"no swap_benchmark row for deck_id={deck_id} phase={phase} only_added={only_added!r}"
        )
    return row


def deck_rows(conn: sqlite3.Connection, deck_id: int) -> list[sqlite3.Row]:
    return conn.execute(
        "SELECT * FROM deck_cards WHERE deck_id=? ORDER BY is_commander DESC, card_name",
        (deck_id,),
    ).fetchall()


def replace_candidate_deck(
    conn: sqlite3.Connection,
    *,
    source_deck_id: int,
    candidate_deck_id: int,
    card_added: str,
    card_removed: str,
    add_tag: str | None,
) -> dict[str, Any]:
    source_rows = deck_rows(conn, source_deck_id)
    columns = [row[1] for row in conn.execute("PRAGMA table_info(deck_cards)") if row[1] != "id"]
    by_name = {normalize_name(str(row["card_name"])): row for row in source_rows}
    removed_key = normalize_name(card_removed)
    added_key = normalize_name(card_added)
    if removed_key not in by_name:
        raise RuntimeError(f"removed card not present in source deck {source_deck_id}: {card_removed}")
    if added_key in by_name:
        raise RuntimeError(f"added card already present in source deck {source_deck_id}: {card_added}")

    meta = conn.execute(
        "SELECT * FROM card_oracle_cache WHERE normalized_name=?",
        (added_key,),
    ).fetchone()
    if meta is None:
        raise RuntimeError(f"missing oracle cache for candidate card: {card_added}")

    candidate_rows: list[dict[str, Any]] = []
    for row in source_rows:
        if normalize_name(str(row["card_name"])) == removed_key:
            continue
        payload = {column: row[column] for column in columns}
        payload["deck_id"] = candidate_deck_id
        candidate_rows.append(payload)

    added_row = {
        "deck_id": candidate_deck_id,
        "card_id": None,
        "card_name": card_added,
        "quantity": 1,
        "functional_tag": add_tag or "candidate",
        "tag_confidence": None,
        "is_commander": 0,
        "is_partner": 0,
        "cmc": meta["cmc"],
        "type_line": meta["type_line"],
        "oracle_text": meta["oracle_text"],
    }
    if "functional_tags_json" in columns:
        added_row["functional_tags_json"] = json.dumps([add_tag or "candidate"], ensure_ascii=True)
    if "battle_rules_json" in columns:
        added_row["battle_rules_json"] = "[]"
    if "semantic_tags_json" in columns:
        added_row["semantic_tags_json"] = "[]"
    candidate_rows.append({column: added_row.get(column) for column in columns})

    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (candidate_deck_id,))
    placeholders = ",".join("?" for _ in columns)
    for row in candidate_rows:
        conn.execute(
            f"INSERT INTO deck_cards ({','.join(columns)}) VALUES ({placeholders})",
            [row.get(column) for column in columns],
        )
    conn.commit()

    total_cards = sum(int(row.get("quantity") or 1) for row in candidate_rows)
    return {
        "row_count": len(candidate_rows),
        "total_cards": total_cards,
        "candidate_deck_id": candidate_deck_id,
        "source_deck_id": source_deck_id,
        "card_added": card_added,
        "card_removed": card_removed,
    }


def write_manifest(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=607)
    parser.add_argument("--baseline-id", type=int, default=None)
    parser.add_argument("--candidate-deck-id", type=int, default=6)
    parser.add_argument("--phase", default="confirmation")
    parser.add_argument("--only-added", default="")
    parser.add_argument("--games", type=int, default=3)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--game-timeout-seconds", type=float, default=30.0)
    parser.add_argument("--stem", default="lorehold_optimizer_equal_gate")
    args = parser.parse_args()

    source_db = args.source_db.resolve()

    with connect(source_db) as conn:
        swap = load_swap_row(
            conn,
            deck_id=args.deck_id,
            baseline_id=args.baseline_id,
            phase=args.phase,
            only_added=args.only_added,
        )

    stamp = utc_stamp()
    card_slug = normalize_name(str(swap["card_added"])).replace(" ", "_").replace(",", "")
    out_dir = REPORT_DIR / f"{args.stem}_{stamp}_{card_slug}"
    out_dir.mkdir(parents=True, exist_ok=True)
    candidate_db = out_dir / "knowledge_candidate.db"
    shutil.copy2(source_db, candidate_db)

    with connect(candidate_db) as conn:
        candidate_meta = replace_candidate_deck(
            conn,
            source_deck_id=args.deck_id,
            candidate_deck_id=args.candidate_deck_id,
            card_added=str(swap["card_added"]),
            card_removed=str(swap["card_removed"]),
            add_tag=str(swap["add_tag"] or "candidate"),
        )

    candidate_key = f"candidate_{args.deck_id}_{card_slug}_equal_gate"
    candidate_name = f"Lorehold {args.deck_id} {swap['card_added']} equal gate"
    stem = f"{args.stem}_{stamp}_{card_slug}"
    gate_cmd = [
        sys.executable,
        str(SCRIPT_DIR / "lorehold_variant_battle_gate.py"),
        "--db",
        str(source_db),
        "--deck-ids",
        str(args.deck_id),
        "--candidate-db",
        str(candidate_db),
        "--candidate-key",
        candidate_key,
        "--candidate-name",
        candidate_name,
        "--candidate-archetype",
        "optimizer-equal-gate",
        "--games",
        str(max(1, args.games)),
        "--opponent-limit",
        str(max(1, args.opponent_limit)),
        "--opponent-seed",
        str(args.opponent_seed),
        "--simulation-seed",
        str(args.simulation_seed),
        "--game-timeout-seconds",
        str(max(0.0, args.game_timeout_seconds)),
        "--stem",
        stem,
    ]

    completed = subprocess.run(
        gate_cmd,
        cwd=str(SCRIPT_DIR),
        check=False,
        capture_output=True,
        text=True,
    )
    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_db": str(source_db),
        "candidate_db": str(candidate_db),
        "out_dir": str(out_dir),
        "swap": dict(swap),
        "candidate_meta": candidate_meta,
        "candidate_key": candidate_key,
        "candidate_name": candidate_name,
        "gate_command": gate_cmd,
        "gate_returncode": completed.returncode,
        "gate_stdout_tail": completed.stdout[-12000:],
        "gate_stderr_tail": completed.stderr[-12000:],
    }
    write_manifest(out_dir / "manifest.json", payload)
    if completed.returncode != 0:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return completed.returncode
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
