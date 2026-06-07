#!/usr/bin/env python3
"""Shared helpers for the safe Hermes master optimizer pipeline.

The helpers in this module are intentionally conservative: they run battles
through a temporary copy, restore deck rows after each test, and never apply
permanent swaps.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sqlite3
import subprocess
import sys
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"
KNOWLEDGE_DIR = DOCS_DIR / "manaloom-knowledge"

DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_BATTLE = SCRIPT_DIR / "battle_analyst_v8.py"

PROTECTED_CARDS = {
    "Lorehold, the Historian",
    "Approach of the Second Sun",
    "Teferi's Protection",
    "Grand Abolisher",
    "Silence",
    "Boros Charm",
    "Spiteful Banditry",
    "Increasing Vengeance",
}


@dataclass
class BattleResult:
    win_rate: float
    wins: int
    losses: int
    stalls: int
    games_per_opponent: int
    opponents: int
    stdout: str
    matchups: list[dict[str, object]]

    @property
    def total_games(self) -> int:
        return self.wins + self.losses + self.stalls


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(name: str | None) -> str:
    return re.sub(r"\s+", " ", str(name or "").strip().lower())


def connect(db_path: Path = DEFAULT_DB) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def run_command(command: list[str], cwd: Path | None = None, timeout: int = 900) -> tuple[int, str]:
    completed = subprocess.run(
        command,
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    output = (completed.stdout or "") + ("\n" + completed.stderr if completed.stderr else "")
    return completed.returncode, output.strip()


def ensure_optimizer_tables(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS optimizer_baseline_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER NOT NULL,
            deck_hash TEXT NOT NULL,
            battle_version TEXT NOT NULL DEFAULT 'battle_analyst_v8',
            games_per_opponent INTEGER NOT NULL,
            opponents INTEGER NOT NULL,
            total_games INTEGER NOT NULL,
            wr REAL NOT NULL,
            wins INTEGER NOT NULL,
            losses INTEGER NOT NULL,
            stalls INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'approved',
            result_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS optimizer_quality_reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER NOT NULL,
            card_added TEXT NOT NULL,
            card_removed TEXT NOT NULL,
            source_phase TEXT NOT NULL,
            status TEXT NOT NULL,
            reasons_json TEXT NOT NULL,
            warnings_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS optimizer_handoffs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER NOT NULL,
            baseline_id INTEGER,
            status TEXT NOT NULL,
            report_path TEXT NOT NULL,
            summary_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS optimizer_applied_swaps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER NOT NULL,
            swap_benchmark_id INTEGER NOT NULL,
            card_added TEXT NOT NULL,
            card_removed TEXT NOT NULL,
            before_hash TEXT NOT NULL,
            after_hash TEXT NOT NULL,
            rollback_path TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    conn.commit()


def deck_rows(conn: sqlite3.Connection, deck_id: int) -> list[sqlite3.Row]:
    return conn.execute(
        "SELECT * FROM deck_cards WHERE deck_id=? ORDER BY is_commander DESC, card_name",
        (deck_id,),
    ).fetchall()


def deck_hash(conn: sqlite3.Connection, deck_id: int) -> str:
    payload = []
    for row in deck_rows(conn, deck_id):
        payload.append(
            {
                "card_name": row["card_name"],
                "quantity": row["quantity"],
                "functional_tag": row["functional_tag"],
                "is_commander": row["is_commander"],
                "cmc": row["cmc"],
                "type_line": row["type_line"],
            }
        )
    encoded = json.dumps(payload, ensure_ascii=True, sort_keys=True)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def get_deck_summary(conn: sqlite3.Connection, deck_id: int) -> dict[str, object]:
    rows = deck_rows(conn, deck_id)
    lands = sum(
        1
        for row in rows
        if row["functional_tag"] == "land" or "Land" in str(row["type_line"] or "")
    )
    nonlands = [row for row in rows if row["functional_tag"] != "land"]
    avg_cmc = sum(float(row["cmc"] or 0) for row in nonlands) / max(1, len(nonlands))
    return {
        "deck_id": deck_id,
        "cards": len(rows),
        "lands": lands,
        "nonlands": len(nonlands),
        "avg_cmc": round(avg_cmc, 3),
        "hash": deck_hash(conn, deck_id),
    }


def latest_baseline(conn: sqlite3.Connection, deck_id: int) -> sqlite3.Row | None:
    return conn.execute(
        """
        SELECT * FROM optimizer_baseline_runs
        WHERE deck_id=? AND status='approved'
        ORDER BY id DESC
        LIMIT 1
        """,
        (deck_id,),
    ).fetchone()


def parse_battle_output(output: str, games_per_opponent: int) -> BattleResult:
    overall = re.search(
        r"OVERALL\s+v\d+:\s+WR=([\d.]+)%\s+\((\d+)W/(\d+)L/(\d+)S\)",
        output,
    )
    if not overall:
        raise RuntimeError("Could not parse OVERALL battle result")

    matchups: list[dict[str, object]] = []
    matchup_re = re.compile(
        r"vs\s+(.*?)\s+WR=\s*([\d.]+)%\s+W=(\d+)\s+L=(\d+)\s+S=(\d+)\s+T=([\d.]+)\s+\[(.*?)\]"
    )
    for line in output.splitlines():
        found = matchup_re.search(line)
        if found:
            matchups.append(
                {
                    "opponent": found.group(1).strip(),
                    "wr": float(found.group(2)),
                    "wins": int(found.group(3)),
                    "losses": int(found.group(4)),
                    "stalls": int(found.group(5)),
                    "avg_turn": float(found.group(6)),
                    "reasons": found.group(7).strip(),
                }
            )

    return BattleResult(
        win_rate=float(overall.group(1)),
        wins=int(overall.group(2)),
        losses=int(overall.group(3)),
        stalls=int(overall.group(4)),
        games_per_opponent=games_per_opponent,
        opponents=len(matchups),
        stdout=output,
        matchups=matchups,
    )


def run_battle(games_per_opponent: int, battle_path: Path = DEFAULT_BATTLE) -> BattleResult:
    source = battle_path.read_text(encoding="utf-8")
    patched = re.sub(
        r"(?m)^    GAMES = \d+\s*$",
        f"    GAMES = {games_per_opponent}",
        source,
        count=1,
    )
    if patched == source and games_per_opponent != 50:
        raise RuntimeError("Could not patch GAMES in battle script")

    tmp_path = battle_path.with_name("_battle_optimizer_tmp.py")
    tmp_path.write_text(patched, encoding="utf-8")
    try:
        code, output = run_command([sys.executable, str(tmp_path)], cwd=SCRIPT_DIR, timeout=1200)
        if code != 0:
            raise RuntimeError(output[-2000:])
        return parse_battle_output(output, games_per_opponent)
    finally:
        try:
            tmp_path.unlink()
        except FileNotFoundError:
            pass


def write_report(name: str, markdown: str) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    path = REPORT_DIR / f"{name}_{stamp}.md"
    path.write_text(markdown, encoding="utf-8")
    return path


def card_metadata(conn: sqlite3.Connection, card_name: str) -> sqlite3.Row | None:
    return conn.execute(
        "SELECT * FROM card_oracle_cache WHERE normalized_name=?",
        (normalize_name(card_name),),
    ).fetchone()


def json_list(value: object) -> list[str]:
    if not value:
        return []
    if isinstance(value, list):
        return [str(item) for item in value]
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    if isinstance(decoded, list):
        return [str(item) for item in decoded]
    return []


def deck_commander_identity(conn: sqlite3.Connection, deck_id: int) -> set[str]:
    row = conn.execute(
        """
        SELECT c.color_identity
        FROM decks d
        JOIN commanders c ON c.id=d.commander_id
        WHERE d.id=?
        """,
        (deck_id,),
    ).fetchone()
    raw = str(row["color_identity"] if row else "RW")
    return {char for char in raw.upper() if char in {"W", "U", "B", "R", "G"}}


def game_changer_names(conn: sqlite3.Connection) -> set[str]:
    table = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='game_changers'"
    ).fetchone()
    if not table:
        return set()
    columns = [row[1] for row in conn.execute("PRAGMA table_info(game_changers)")]
    name_col = "card_name" if "card_name" in columns else "name" if "name" in columns else None
    if not name_col:
        return set()
    return {
        normalize_name(row[0])
        for row in conn.execute(f"SELECT {name_col} FROM game_changers")
        if row[0]
    }


def commander_legality(conn: sqlite3.Connection, card_name: str) -> str | None:
    row = conn.execute(
        """
        SELECT status FROM card_legalities
        WHERE lower(card_name)=lower(?) AND format='commander'
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return str(row["status"]).lower() if row else None


def quality_gate_candidate(
    conn: sqlite3.Connection,
    deck_id: int,
    card_added: str,
    card_removed: str,
    source_phase: str = "candidate",
) -> dict[str, object]:
    reasons: list[str] = []
    warnings: list[str] = []
    rows = deck_rows(conn, deck_id)
    current_names = {normalize_name(row["card_name"]) for row in rows}
    removed = [
        row for row in rows if normalize_name(row["card_name"]) == normalize_name(card_removed)
    ]

    if normalize_name(card_added) in current_names:
        reasons.append("added_card_already_in_deck")
    if not removed:
        reasons.append("removed_card_not_in_deck")
    elif removed[0]["is_commander"]:
        reasons.append("cannot_cut_commander")
    if card_removed in PROTECTED_CARDS:
        reasons.append("cannot_cut_protected_card")

    meta = card_metadata(conn, card_added)
    if not meta:
        reasons.append("missing_card_oracle_cache")
        added_identity: set[str] = set()
        type_line = ""
        add_cmc = None
    else:
        added_identity = set(json_list(meta["color_identity_json"]))
        type_line = str(meta["type_line"] or "")
        add_cmc = meta["cmc"]

    allowed_identity = deck_commander_identity(conn, deck_id)
    if not added_identity.issubset(allowed_identity):
        reasons.append(
            "color_identity_outside_commander:"
            + "".join(sorted(added_identity))
            + " not subset "
            + "".join(sorted(allowed_identity))
        )

    legality = commander_legality(conn, card_added)
    if legality and legality != "legal":
        reasons.append(f"commander_legality_{legality}")
    elif not legality:
        warnings.append("commander_legality_missing")

    if type_line and "Basic" in type_line and "Land" not in type_line:
        warnings.append("unusual_basic_type_line")

    before = get_deck_summary(conn, deck_id)
    lands_after = int(before["lands"])
    if removed and "Land" in str(removed[0]["type_line"] or ""):
        lands_after -= 1
    if "Land" in type_line:
        lands_after += 1
    if lands_after < 30:
        reasons.append(f"land_count_too_low:{lands_after}")
    if lands_after > 40:
        reasons.append(f"land_count_too_high:{lands_after}")

    gc_names = game_changer_names(conn)
    if normalize_name(card_added) in gc_names:
        warnings.append("adds_game_changer_requires_bracket_review")

    status = "blocked" if reasons else "passed"
    conn.execute(
        """
        INSERT INTO optimizer_quality_reviews
            (deck_id, card_added, card_removed, source_phase, status,
             reasons_json, warnings_json, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            deck_id,
            card_added,
            card_removed,
            source_phase,
            status,
            json.dumps(reasons, ensure_ascii=True),
            json.dumps(warnings, ensure_ascii=True),
            utc_now(),
        ),
    )
    conn.commit()
    return {
        "status": status,
        "reasons": reasons,
        "warnings": warnings,
        "add_cmc": add_cmc,
        "type_line": type_line,
    }


@contextmanager
def temporary_swap(
    conn: sqlite3.Connection,
    deck_id: int,
    card_added: str,
    card_removed: str,
    add_tag: str | None = None,
):
    rows = conn.execute("SELECT * FROM deck_cards WHERE deck_id=?", (deck_id,)).fetchall()
    columns = [row[1] for row in conn.execute("PRAGMA table_info(deck_cards)")]
    meta = card_metadata(conn, card_added)
    try:
        conn.execute(
            "DELETE FROM deck_cards WHERE deck_id=? AND lower(card_name)=lower(?)",
            (deck_id, card_removed),
        )
        conn.execute(
            """
            INSERT INTO deck_cards
                (deck_id, card_name, quantity, functional_tag, tag_confidence,
                 is_commander, is_partner, cmc, type_line, oracle_text)
            VALUES (?, ?, 1, ?, NULL, 0, 0, ?, ?, ?)
            """,
            (
                deck_id,
                card_added,
                add_tag or "candidate",
                meta["cmc"] if meta else None,
                meta["type_line"] if meta else None,
                meta["oracle_text"] if meta else None,
            ),
        )
        conn.commit()
        yield
    finally:
        conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (deck_id,))
        placeholders = ",".join("?" for _ in columns)
        col_list = ",".join(columns)
        for row in rows:
            conn.execute(
                f"INSERT INTO deck_cards ({col_list}) VALUES ({placeholders})",
                [row[col] for col in columns],
            )
        conn.commit()


def candidate_rows(
    conn: sqlite3.Connection,
    limit: int,
    baseline_wr: float,
    *,
    include_existing: bool = False,
    only_added: str = "",
) -> list[sqlite3.Row]:
    where = [
        "phase='best-in-slot'",
    ]
    params: list[object] = []
    if not include_existing:
        where.append(
            """
            card_added NOT IN (
                SELECT card_added FROM swap_benchmarks
                WHERE phase IN ('confirmation', 'full_confirmation')
            )
            """
        )
    if only_added:
        where.append("lower(card_added)=lower(?)")
        params.append(only_added)
    params.append(limit)
    return conn.execute(
        f"""
        SELECT category, card_added, card_removed, add_cmc, add_effect,
               wr, wins, losses, draws, games, delta_pp, phase, tested_at
        FROM slot_benchmarks
        WHERE {' AND '.join(where)}
        ORDER BY wr DESC, delta_pp DESC
        LIMIT ?
        """,
        params,
    ).fetchall()
