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

DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_BATTLE = Path(os.environ.get("MANALOOM_BATTLE_SCRIPT", SCRIPT_DIR / "battle_analyst_v9.py"))

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

ROLE_FAMILIES = {
    "removal": {
        "tags": {"removal", "remove_creature", "remove_permanent"},
        "patterns": (
            r"\bdestroy target\b",
            r"\bexile target\b",
            r"\bdamage to (?:any|target)",
            r"\bdeals? \d+ damage to target\b",
        ),
        "minimum": 4,
    },
    "wipe": {
        "tags": {"wipe", "board_wipe", "damage_wipe"},
        "patterns": (
            r"\bdestroy all\b",
            r"\bexile all\b",
            r"\beach creature\b",
            r"\ball creatures\b",
        ),
        "minimum": 3,
    },
    "draw": {
        "tags": {"draw", "draw_cards", "draw_engine"},
        "patterns": (
            r"\bdraw (?:a|\d+|two|three|seven) cards?\b",
            r"\bdiscard.*hand.*draw\b",
            r"\bwhenever.*draw\b",
        ),
        "minimum": 7,
    },
    "ramp": {
        "tags": {"ramp", "ramp_permanent", "ramp_ritual", "ramp_engine"},
        "patterns": (
            r"\badd .*mana\b",
            r"\btreasure token\b",
            r"\bcosts? .* less\b",
        ),
        "minimum": 10,
    },
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


def run_command(
    command: list[str],
    cwd: Path | None = None,
    timeout: int = 900,
    env_extra: dict[str, str] | None = None,
) -> tuple[int, str]:
    env = os.environ.copy()
    env.setdefault("PYTHONIOENCODING", "utf-8")
    env.setdefault("PYTHONUTF8", "1")
    if env_extra:
        env.update(env_extra)
    completed = subprocess.run(
        command,
        cwd=str(cwd) if cwd else None,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )
    output = (completed.stdout or "") + ("\n" + completed.stderr if completed.stderr else "")
    return completed.returncode, output.strip()


def ensure_optimizer_tables(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS slot_benchmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            baseline_id INTEGER,
            baseline_hash TEXT,
            category TEXT NOT NULL,
            card_added TEXT NOT NULL,
            card_removed TEXT NOT NULL,
            add_cmc REAL,
            add_effect TEXT,
            add_tag TEXT,
            wr REAL,
            wins INTEGER,
            losses INTEGER,
            draws INTEGER,
            games INTEGER,
            delta_pp REAL,
            phase TEXT,
            tested_at TEXT DEFAULT (datetime('now'))
        )
        """
    )
    _ensure_columns(
        conn,
        "slot_benchmarks",
        {
            "deck_id": "INTEGER",
            "baseline_id": "INTEGER",
            "baseline_hash": "TEXT",
            "add_tag": "TEXT",
        },
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS optimizer_baseline_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER NOT NULL,
            deck_hash TEXT NOT NULL,
            battle_version TEXT NOT NULL DEFAULT 'battle_analyst_v9',
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
        CREATE TABLE IF NOT EXISTS swap_benchmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            baseline_id INTEGER,
            baseline_hash TEXT,
            card_added TEXT NOT NULL,
            card_removed TEXT NOT NULL,
            add_cmc REAL,
            add_effect TEXT,
            add_tag TEXT,
            wr REAL NOT NULL,
            wins INTEGER,
            losses INTEGER,
            draws INTEGER,
            games INTEGER,
            phase TEXT NOT NULL,
            delta_pp REAL NOT NULL,
            applied INTEGER NOT NULL DEFAULT 0,
            tested_at TEXT NOT NULL
        )
        """
    )
    _ensure_columns(
        conn,
        "swap_benchmarks",
        {
            "deck_id": "INTEGER",
            "baseline_id": "INTEGER",
            "baseline_hash": "TEXT",
        },
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
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS optimizer_product_handoffs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER NOT NULL,
            applied_swap_id INTEGER,
            status TEXT NOT NULL,
            report_path TEXT NOT NULL,
            approval_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    conn.commit()


def _ensure_columns(conn: sqlite3.Connection, table: str, columns: dict[str, str]) -> None:
    existing = {row[1] for row in conn.execute(f"PRAGMA table_info({table})")}
    for name, definition in columns.items():
        if name not in existing:
            conn.execute(f"ALTER TABLE {table} ADD COLUMN {name} {definition}")


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
    nonlands = [
        row
        for row in rows
        if row["functional_tag"] != "land" and "Land" not in str(row["type_line"] or "")
    ]
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


def deck_contains(conn: sqlite3.Connection, deck_id: int, card_name: str) -> bool:
    return (
        conn.execute(
            """
            SELECT 1 FROM deck_cards
            WHERE deck_id=? AND lower(card_name)=lower(?)
            LIMIT 1
            """,
            (deck_id, card_name),
        ).fetchone()
        is not None
    )


def assert_current_deck_matches_baseline(
    conn: sqlite3.Connection,
    deck_id: int,
    baseline: sqlite3.Row,
) -> None:
    current_hash = deck_hash(conn, deck_id)
    baseline_hash = str(baseline["deck_hash"])
    if current_hash != baseline_hash:
        raise RuntimeError(
            "Current deck hash does not match latest approved baseline. "
            f"current={current_hash} baseline={baseline_hash}. "
            "Re-freeze the baseline before quality gate, confirmation, handoff, or apply."
        )


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
        env_extra = {}
        metrics_dir = os.environ.get("MANALOOM_ENGINE_METRICS_DIR")
        if metrics_dir:
            Path(metrics_dir).mkdir(parents=True, exist_ok=True)
            stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
            env_extra["MANALOOM_ENGINE_METRICS_OUT"] = str(
                Path(metrics_dir)
                / f"battle_engine_metrics_{battle_path.stem}_{games_per_opponent}_{stamp}.json"
            )
        code, output = run_command(
            [sys.executable, str(tmp_path)],
            cwd=SCRIPT_DIR,
            timeout=1200,
            env_extra=env_extra,
        )
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


def battle_rule_deck_category(conn: sqlite3.Connection, card_name: str) -> str | None:
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='battle_card_rules'"
    ).fetchone()
    if not table:
        return None
    row = conn.execute(
        "SELECT deck_role_json FROM battle_card_rules WHERE normalized_name=?",
        (normalize_name(card_name),),
    ).fetchone()
    if not row:
        return None
    try:
        role = json.loads(str(row["deck_role_json"] or "{}"))
    except Exception:
        return None
    category = role.get("category") if isinstance(role, dict) else None
    return str(category) if category else None


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
    raw = "RW"
    commanders_table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='commanders'"
    ).fetchone()
    deck_columns = {row[1] for row in conn.execute("PRAGMA table_info(decks)")}
    if commanders_table and "commander_id" in deck_columns:
        row = conn.execute(
            """
            SELECT c.color_identity
            FROM decks d
            JOIN commanders c ON c.id=d.commander_id
            WHERE d.id=?
            """,
            (deck_id,),
        ).fetchone()
        raw = str(row["color_identity"] if row else raw)
    else:
        row = conn.execute(
            """
            SELECT coc.color_identity_json
            FROM deck_cards dc
            LEFT JOIN card_oracle_cache coc ON coc.normalized_name=lower(dc.card_name)
            WHERE dc.deck_id=? AND dc.is_commander=1
            LIMIT 1
            """,
            (deck_id,),
        ).fetchone()
        values = json_list(row["color_identity_json"] if row else None)
        if values:
            raw = "".join(values)
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
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='card_legalities'"
    ).fetchone()
    if not table:
        return "legal"
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

    removed_role = infer_role(
        str(removed[0]["functional_tag"] if removed else ""),
        str(removed[0]["type_line"] if removed else ""),
        str(removed[0]["oracle_text"] if removed else ""),
    )
    added_role = infer_role(
        battle_rule_deck_category(conn, card_added) or "",
        type_line,
        str(meta["oracle_text"] if meta else ""),
    )
    if removed_role and removed_role != added_role:
        role_count = count_role(rows, removed_role)
        minimum = ROLE_FAMILIES[removed_role]["minimum"]
        if role_count <= minimum:
            reasons.append(
                f"cannot_cut_low_count_{removed_role}:"
                f"{card_removed} role={removed_role} count={role_count} add_role={added_role or 'unknown'}"
            )
        else:
            warnings.append(
                f"role_mismatch:{card_removed} role={removed_role} add_role={added_role or 'unknown'}"
            )

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


def infer_role(functional_tag: str, type_line: str, oracle_text: str) -> str | None:
    tag = normalize_name(functional_tag).replace(" ", "_")
    text = f"{type_line}\n{oracle_text}".lower()
    for role, spec in ROLE_FAMILIES.items():
        if tag in spec["tags"]:
            return role
        if any(re.search(pattern, text) for pattern in spec["patterns"]):
            return role
    return None


def count_role(rows: Iterable[sqlite3.Row], role: str) -> int:
    return sum(
        1
        for row in rows
        if infer_role(
            str(row["functional_tag"] or ""),
            str(row["type_line"] or ""),
            str(row["oracle_text"] or ""),
        )
        == role
    )


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
    current_names = {normalize_name(row["card_name"]) for row in rows}
    if normalize_name(card_removed) not in current_names:
        raise RuntimeError(f"Cannot test stale swap target; card is not in deck: {card_removed}")
    if normalize_name(card_added) in current_names:
        raise RuntimeError(f"Cannot test duplicate candidate; card is already in deck: {card_added}")
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
    deck_id: int | None = None,
    baseline_id: int | None = None,
    baseline_hash: str = "",
    include_existing: bool = False,
    only_added: str = "",
) -> list[sqlite3.Row]:
    ensure_optimizer_tables(conn)
    where = [
        "phase IN ('best-in-slot', 'phase1')",
    ]
    params: list[object] = []
    if deck_id is not None:
        where.append("deck_id=?")
        params.append(deck_id)
    if baseline_id is not None:
        where.append("baseline_id=?")
        params.append(baseline_id)
    if baseline_hash:
        where.append("baseline_hash=?")
        params.append(baseline_hash)
    if not include_existing:
        swap_where = ["phase IN ('confirmation', 'full_confirmation')"]
        swap_params: list[object] = []
        if deck_id is not None:
            swap_where.append("deck_id=?")
            swap_params.append(deck_id)
        if baseline_id is not None:
            swap_where.append("baseline_id=?")
            swap_params.append(baseline_id)
        if baseline_hash:
            swap_where.append("baseline_hash=?")
            swap_params.append(baseline_hash)
        where.append(
            f"""
            card_added NOT IN (
                SELECT card_added FROM swap_benchmarks
                WHERE {' AND '.join(swap_where)}
            )
            """
        )
        params.extend(swap_params)
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
