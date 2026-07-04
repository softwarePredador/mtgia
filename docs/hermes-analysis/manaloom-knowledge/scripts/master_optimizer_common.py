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
from typing import Any, Iterable

import battle_rule_registry


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"
KNOWLEDGE_DIR = DOCS_DIR / "manaloom-knowledge"


def sqlite_has_table(path: Path, table_name: str) -> bool:
    if not path.exists() or path.stat().st_size <= 0:
        return False
    conn: sqlite3.Connection | None = None
    try:
        conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
        row = conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            (table_name,),
        ).fetchone()
    except sqlite3.Error:
        return False
    finally:
        if conn is not None:
            conn.close()
    return bool(row)


def sqlite_connection_has_table(conn: sqlite3.Connection, table_name: str) -> bool:
    try:
        row = conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            (table_name,),
        ).fetchone()
    except sqlite3.Error:
        return False
    return bool(row)


def resolve_default_knowledge_db() -> Path:
    env_path = os.environ.get("MANALOOM_KNOWLEDGE_DB")
    if env_path:
        return Path(env_path)
    local_path = SCRIPT_DIR / "knowledge.db"
    if sqlite_has_table(local_path, "battle_card_rules"):
        return local_path
    canonical_path = (
        Path.home()
        / "Documents"
        / "rafa"
        / "mtg"
        / "mtgia"
        / "docs"
        / "hermes-analysis"
        / "manaloom-knowledge"
        / "scripts"
        / "knowledge.db"
    )
    if canonical_path != local_path and sqlite_has_table(canonical_path, "battle_card_rules"):
        return canonical_path
    return local_path


DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_BATTLE = Path(os.environ.get("MANALOOM_BATTLE_SCRIPT", SCRIPT_DIR / "battle_analyst_v9.py"))
DEFAULT_BATTLE_GATE_SUMMARY = Path(
    os.environ.get(
        "MANALOOM_BATTLE_GATE_SUMMARY",
        str(Path.home() / ".manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json"),
    )
)
DEFAULT_LOREHOLD_PROTECTED_REGISTRY = (
    REPORT_DIR / "lorehold_candidate_hypothesis_registry_20260626.json"
)

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


class BattleRunTimeout(RuntimeError):
    def __init__(self, timeout_seconds: int, output_tail: str = "") -> None:
        self.timeout_seconds = int(timeout_seconds)
        self.output_tail = output_tail
        detail = f"battle run timed out after {self.timeout_seconds}s"
        if output_tail:
            detail = f"{detail}: {output_tail[-400:]}"
        super().__init__(detail)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(name: str | None) -> str:
    return re.sub(r"\s+", " ", str(name or "").strip().lower())


def parse_mana_cost_cmc(mana_cost: object) -> float | None:
    value = str(mana_cost or "").strip()
    if not value:
        return None
    total = 0.0
    saw_symbol = False
    for raw_symbol in re.findall(r"\{([^}]+)\}", value.upper()):
        symbol = raw_symbol.strip()
        if not symbol:
            continue
        saw_symbol = True
        if symbol.isdigit():
            total += int(symbol)
            continue
        if symbol in {"X", "Y", "Z"}:
            continue
        if symbol.startswith("2/"):
            total += 2
            continue
        if "/" in symbol:
            total += 1
            continue
        total += 1
    return total if saw_symbol else None


def _mapping_value(card: Any, key: str) -> Any:
    if isinstance(card, dict):
        return card.get(key)
    try:
        if hasattr(card, "keys") and key in card.keys():
            return card[key]
    except Exception:
        return None
    return None


def raw_cmc_value(raw_cmc: object) -> float | None:
    if raw_cmc is None:
        return None
    try:
        parsed = float(raw_cmc)
    except Exception:
        return None
    if parsed < 0:
        return 0.0
    return min(parsed, 999.0)


def safe_cmc_from_card(card: Any, *, unknown_nonland_fallback: float = 99.0) -> float:
    type_line = str(_mapping_value(card, "type_line") or "")
    if "land" in type_line.lower():
        return 0.0
    parsed_cmc = raw_cmc_value(_mapping_value(card, "cmc"))
    mana_cost_cmc = parse_mana_cost_cmc(_mapping_value(card, "mana_cost"))
    if parsed_cmc is None:
        return mana_cost_cmc if mana_cost_cmc is not None else unknown_nonland_fallback
    if parsed_cmc == 0 and mana_cost_cmc is not None and mana_cost_cmc > 0:
        return mana_cost_cmc
    return parsed_cmc


def load_dynamic_protected_cards(
    registry_path: Path = DEFAULT_LOREHOLD_PROTECTED_REGISTRY,
) -> set[str]:
    try:
        payload = json.loads(registry_path.read_text(encoding="utf-8"))
    except Exception:
        return set()
    values = payload.get("protected_cards_until_same_function_replacement_wins") or []
    if not isinstance(values, list):
        return set()
    return {
        str(value).strip()
        for value in values
        if str(value).strip()
    }


def effective_protected_cards() -> set[str]:
    return set(PROTECTED_CARDS) | load_dynamic_protected_cards()


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
            "baseline_semantics_hash": "TEXT",
            "baseline_ruleset_hash": "TEXT",
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
    _ensure_columns(
        conn,
        "optimizer_baseline_runs",
        {
            "semantics_hash": "TEXT",
            "ruleset_hash": "TEXT",
        },
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
            "baseline_semantics_hash": "TEXT",
            "baseline_ruleset_hash": "TEXT",
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
    _ensure_columns(
        conn,
        "optimizer_applied_swaps",
        {
            "before_semantics_hash": "TEXT",
            "after_semantics_hash": "TEXT",
            "before_ruleset_hash": "TEXT",
            "after_ruleset_hash": "TEXT",
        },
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
                "card_id": row["card_id"] if row_has_column(row, "card_id") else "",
                "card_name": row["card_name"],
                "quantity": row["quantity"],
                "is_commander": row["is_commander"],
            }
        )
    encoded = json.dumps(payload, ensure_ascii=True, sort_keys=True)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def semantics_hash(conn: sqlite3.Connection, deck_id: int) -> str:
    payload = []
    for row in deck_rows(conn, deck_id):
        if row_has_column(row, "semantic_tags_v2_json"):
            try:
                semantic_tags_v2 = json.loads(str(row["semantic_tags_v2_json"] or "[]"))
            except Exception:
                semantic_tags_v2 = []
        else:
            semantic_tags_v2 = []
        payload.append(
            {
                "card_id": row["card_id"] if row_has_column(row, "card_id") else "",
                "card_name": row["card_name"],
                "functional_tags": sorted(functional_tags_for_row(row)),
                "semantic_tags_v2": semantic_tags_v2,
            }
        )
    encoded = json.dumps(payload, ensure_ascii=True, sort_keys=True)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def ruleset_hash(conn: sqlite3.Connection, deck_id: int) -> str:
    payload = []
    for row in deck_rows(conn, deck_id):
        if row_has_column(row, "battle_rules_json"):
            try:
                battle_rules = json.loads(str(row["battle_rules_json"] or "[]"))
            except Exception:
                battle_rules = []
        else:
            battle_rules = []
        payload.append(
            {
                "card_id": row["card_id"] if row_has_column(row, "card_id") else "",
                "card_name": row["card_name"],
                "battle_rules": battle_rules,
            }
        )
    encoded = json.dumps(payload, ensure_ascii=True, sort_keys=True)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def get_deck_summary(conn: sqlite3.Connection, deck_id: int) -> dict[str, object]:
    rows = deck_rows(conn, deck_id)
    lands = sum(
        int(row["quantity"] or 1)
        for row in rows
        if "land" in functional_tags_for_row(row) or "Land" in str(row["type_line"] or "")
    )
    nonlands = [
        row
        for row in rows
        if "land" not in functional_tags_for_row(row) and "Land" not in str(row["type_line"] or "")
    ]
    nonland_cards = sum(int(row["quantity"] or 1) for row in nonlands)
    avg_cmc = sum(float(row["cmc"] or 0) * int(row["quantity"] or 1) for row in nonlands) / max(1, nonland_cards)
    return {
        "deck_id": deck_id,
        "cards": sum(int(row["quantity"] or 1) for row in rows),
        "lands": lands,
        "nonlands": nonland_cards,
        "avg_cmc": round(avg_cmc, 3),
        "hash": deck_hash(conn, deck_id),
        "semantics_hash": semantics_hash(conn, deck_id),
        "ruleset_hash": ruleset_hash(conn, deck_id),
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
    if row_has_column(baseline, "semantics_hash") and baseline["semantics_hash"]:
        current_semantics_hash = semantics_hash(conn, deck_id)
        baseline_semantics_hash = str(baseline["semantics_hash"])
        if current_semantics_hash != baseline_semantics_hash:
            raise RuntimeError(
                "Current deck semantics hash does not match latest approved baseline. "
                f"current={current_semantics_hash} baseline={baseline_semantics_hash}. "
                "Re-freeze the baseline because tags/rules changed without a deck structure change."
            )
    if row_has_column(baseline, "ruleset_hash") and baseline["ruleset_hash"]:
        current_ruleset_hash = ruleset_hash(conn, deck_id)
        baseline_ruleset_hash = str(baseline["ruleset_hash"])
        if current_ruleset_hash != baseline_ruleset_hash:
            raise RuntimeError(
                "Current battle ruleset hash does not match latest approved baseline. "
                f"current={current_ruleset_hash} baseline={baseline_ruleset_hash}. "
                "Re-freeze the baseline before comparing battle results."
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


def run_battle(
    games_per_opponent: int,
    battle_path: Path = DEFAULT_BATTLE,
    *,
    deck_id: int = 6,
    timeout_seconds: int = 1200,
    opponent_limit: int | None = None,
    opponent_seed: int | None = None,
    simulation_seed: int | None = None,
) -> BattleResult:
    env_extra = {
        "MANALOOM_BATTLE_EVALUATION_TARGET_PLAYER": "Lorehold",
        "MANALOOM_BATTLE_DECK_ID": str(deck_id),
    }
    if opponent_limit is not None and int(opponent_limit) > 0:
        env_extra["MANALOOM_BATTLE_REAL_OPPONENT_LIMIT"] = str(int(opponent_limit))
    if opponent_seed is not None:
        env_extra["MANALOOM_BATTLE_REAL_OPPONENT_SEED"] = str(int(opponent_seed))
    metrics_dir = os.environ.get("MANALOOM_ENGINE_METRICS_DIR")
    if metrics_dir:
        Path(metrics_dir).mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        env_extra["MANALOOM_ENGINE_METRICS_OUT"] = str(
            Path(metrics_dir)
            / f"battle_engine_metrics_{battle_path.stem}_{games_per_opponent}_{stamp}.json"
        )
    command = [
        sys.executable,
        str(battle_path),
        "--games",
        str(games_per_opponent),
        "--deck-id",
        str(deck_id),
    ]
    if simulation_seed is not None:
        command.extend(["--seed", str(int(simulation_seed))])
    try:
        code, output = run_command(
            command,
            cwd=SCRIPT_DIR,
            timeout=timeout_seconds,
            env_extra=env_extra,
        )
    except subprocess.TimeoutExpired as exc:
        output = ""
        if isinstance(exc.stdout, bytes):
            output += exc.stdout.decode("utf-8", errors="replace")
        elif exc.stdout:
            output += str(exc.stdout)
        if isinstance(exc.stderr, bytes):
            output += "\n" + exc.stderr.decode("utf-8", errors="replace")
        elif exc.stderr:
            output += "\n" + str(exc.stderr)
        raise BattleRunTimeout(timeout_seconds, output.strip()) from exc
    if code != 0:
        raise RuntimeError(output[-2000:])
    return parse_battle_output(output, games_per_opponent)


def write_report(name: str, markdown: str) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    path = REPORT_DIR / f"{name}_{stamp}.md"
    path.write_text(markdown, encoding="utf-8")
    return path


def load_battle_gate_summary(summary_path: Path | None = None) -> dict[str, Any]:
    path = summary_path or DEFAULT_BATTLE_GATE_SUMMARY
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {
            "battle_replay_final_status": "missing_summary",
            "battle_replay_final_status_reason": f"summary_not_found:{path}",
            "mandatory_gate_divergences": ["battle_gate_summary_missing"],
            "_summary_path": str(path),
        }


def _sample(values: object, limit: int = 8) -> list[object]:
    if isinstance(values, list):
        return values[:limit]
    return []


def battle_gate_report_lines(summary: dict[str, Any] | None = None) -> list[str]:
    data = summary or load_battle_gate_summary()
    summary_path = str(data.get("_summary_path") or DEFAULT_BATTLE_GATE_SUMMARY)
    gate_statuses = data.get("mandatory_gate_statuses") or {}
    gate_rollup = {
        name: (gate or {}).get("status")
        for name, gate in sorted(gate_statuses.items())
    }
    return [
        "## Battle Replay Gate",
        "",
        f"- audit_summary: `{summary_path}`",
        f"- audit_run_dir: `{data.get('run_dir') or '-'}`",
        f"- battle_replay_final_status: `{data.get('battle_replay_final_status') or 'unknown'}`",
        f"- battle_replay_final_status_reason: `{data.get('battle_replay_final_status_reason') or 'unknown'}`",
        f"- battle_gate_weight: `required_for_optimizer_wr_evidence`",
        f"- mandatory_gate_divergences: `{json.dumps(data.get('mandatory_gate_divergences') or [], sort_keys=True)}`",
        f"- mandatory_gate_statuses: `{json.dumps(gate_rollup, sort_keys=True)}`",
        f"- strategy_learning_confidence_counts: `{json.dumps(data.get('strategy_learning_confidence_counts') or {}, sort_keys=True)}`",
        f"- strategy_low_confidence_seed_sample: `{json.dumps(_sample(data.get('strategy_low_confidence_seeds')), sort_keys=True)}`",
        f"- strategy_high_confidence_learning_seed_sample: `{json.dumps(_sample(data.get('strategy_high_confidence_learning_seeds')), sort_keys=True)}`",
        f"- global_learning_eligibility_policy: `{data.get('global_learning_eligibility_policy') or '-'}`",
        f"- global_learning_eligible_seed_sample: `{json.dumps(_sample(data.get('global_learning_eligible_seeds')), sort_keys=True)}`",
        f"- global_not_learning_eligible_seed_sample: `{json.dumps(_sample(data.get('global_not_learning_eligible_seeds')), sort_keys=True)}`",
        f"- focused_template_dispatch_status: `{data.get('focused_template_dispatch_status') or '-'}`",
        f"- focused_template_evidence_ready: `{data.get('focused_template_evidence_ready', '-')}`",
        f"- focused_template_evidence_not_ready_unwaived: `{data.get('focused_template_evidence_not_ready_unwaived', '-')}`",
        f"- effect_coverage_residual_status: `{data.get('effect_coverage_residual_status') or '-'}`",
        f"- effect_coverage_residual_raw_flag_total: `{data.get('effect_coverage_residual_raw_flag_total', '-')}`",
        f"- effect_coverage_residual_accepted_unaccepted_rows: `{data.get('effect_coverage_residual_accepted_card_flag_rows', '-')}/{data.get('effect_coverage_residual_unaccepted_card_flag_rows', '-')}`",
        "- effect_coverage_residual_scope_note: `accepted_residual_is_not_full_runtime_coverage`",
        f"- review_rule_denominators: `review_only={data.get('review_only_rule_names', '-')} needs_review={data.get('needs_review_rule_names', '-')} non_runtime_safe={data.get('non_runtime_safe_rule_names', '-')} runtime_safe={data.get('runtime_safe_rule_names', '-')}`",
        "- review_rule_denominator_scope_note: `review_only_zero_is_not_review_backlog_zero`",
        f"- review_status_counts: `{json.dumps(data.get('review_status_counts') or {}, sort_keys=True)}`",
        f"- decision_trace_taxonomy_scope: `rows={data.get('decision_trace_taxonomy_rows', '-')} observed={data.get('decision_trace_kinds_observed', '-')}/{data.get('decision_trace_kinds_total', '-')} uncovered={data.get('decision_trace_kinds_uncovered', '-')}`",
        f"- decision_trace_static_uncovered_types: `{json.dumps(data.get('decision_trace_static_uncovered_types') or [], sort_keys=True)}`",
        f"- forensic_lineage_status: `{data.get('forensic_lineage_status') or '-'}`",
        f"- forensic_card_id_present_missing: `{data.get('forensic_card_id_present', '-')}/{data.get('forensic_card_id_missing', '-')}`",
        f"- forensic_card_id_missing_accepted_unaccepted: `{data.get('forensic_card_id_missing_accepted', '-')}/{data.get('forensic_card_id_missing_unaccepted', '-')}`",
        f"- forensic_semantic_hash_present_missing: `{data.get('forensic_semantic_hash_present', '-')}/{data.get('forensic_semantic_hash_missing', '-')}`",
        f"- forensic_semantic_hash_missing_accepted_unaccepted: `{data.get('forensic_semantic_hash_missing_accepted', '-')}/{data.get('forensic_semantic_hash_missing_unaccepted', '-')}`",
        f"- forensic_rule_logical_key_present_missing: `{data.get('forensic_rule_logical_key_present', '-')}/{data.get('forensic_rule_logical_key_missing', '-')}`",
        f"- forensic_rule_logical_key_missing_accepted_unaccepted: `{data.get('forensic_rule_logical_key_missing_accepted', '-')}/{data.get('forensic_rule_logical_key_missing_unaccepted', '-')}`",
        "- forensic_lineage_scope_note: `complete_means_zero_unaccepted_missing_not_full_identity_coverage`",
        f"- forensic_lineage_missing_waiver_reasons: `{json.dumps(data.get('forensic_lineage_missing_waiver_reasons') or {}, sort_keys=True)}`",
        "",
    ]


def battle_gate_cli_lines(summary: dict[str, Any] | None = None) -> list[str]:
    data = summary or load_battle_gate_summary()
    return [
        f"battle_replay_final_status={data.get('battle_replay_final_status') or 'unknown'}",
        f"battle_replay_final_status_reason={data.get('battle_replay_final_status_reason') or 'unknown'}",
        f"battle_gate_weight=required_for_optimizer_wr_evidence",
        f"mandatory_gate_divergences={json.dumps(data.get('mandatory_gate_divergences') or [], sort_keys=True)}",
        f"strategy_learning_confidence_counts={json.dumps(data.get('strategy_learning_confidence_counts') or {}, sort_keys=True)}",
        f"strategy_low_confidence_seed_sample={json.dumps(_sample(data.get('strategy_low_confidence_seeds')), sort_keys=True)}",
        f"strategy_high_confidence_learning_seed_sample={json.dumps(_sample(data.get('strategy_high_confidence_learning_seeds')), sort_keys=True)}",
        f"global_learning_eligibility_policy={data.get('global_learning_eligibility_policy') or '-'}",
        f"global_learning_eligible_seed_sample={json.dumps(_sample(data.get('global_learning_eligible_seeds')), sort_keys=True)}",
        f"global_not_learning_eligible_seed_sample={json.dumps(_sample(data.get('global_not_learning_eligible_seeds')), sort_keys=True)}",
        f"focused_template_dispatch_status={data.get('focused_template_dispatch_status') or '-'}",
        f"focused_template_evidence_ready={data.get('focused_template_evidence_ready', '-')}",
        f"focused_template_evidence_not_ready_unwaived={data.get('focused_template_evidence_not_ready_unwaived', '-')}",
        f"effect_coverage_residual_status={data.get('effect_coverage_residual_status') or '-'}",
        f"effect_coverage_residual_raw_flag_total={data.get('effect_coverage_residual_raw_flag_total', '-')}",
        f"effect_coverage_residual_accepted_unaccepted_rows={data.get('effect_coverage_residual_accepted_card_flag_rows', '-')}/{data.get('effect_coverage_residual_unaccepted_card_flag_rows', '-')}",
        "effect_coverage_residual_scope_note=accepted_residual_is_not_full_runtime_coverage",
        f"review_rule_denominators=review_only:{data.get('review_only_rule_names', '-')} needs_review:{data.get('needs_review_rule_names', '-')} non_runtime_safe:{data.get('non_runtime_safe_rule_names', '-')} runtime_safe:{data.get('runtime_safe_rule_names', '-')}",
        "review_rule_denominator_scope_note=review_only_zero_is_not_review_backlog_zero",
        f"decision_trace_taxonomy_scope=rows:{data.get('decision_trace_taxonomy_rows', '-')} observed:{data.get('decision_trace_kinds_observed', '-')}/{data.get('decision_trace_kinds_total', '-')} uncovered:{data.get('decision_trace_kinds_uncovered', '-')}",
        f"forensic_lineage_status={data.get('forensic_lineage_status') or '-'}",
        f"forensic_card_id_present_missing={data.get('forensic_card_id_present', '-')}/{data.get('forensic_card_id_missing', '-')}",
        f"forensic_card_id_missing_accepted_unaccepted={data.get('forensic_card_id_missing_accepted', '-')}/{data.get('forensic_card_id_missing_unaccepted', '-')}",
        f"forensic_semantic_hash_present_missing={data.get('forensic_semantic_hash_present', '-')}/{data.get('forensic_semantic_hash_missing', '-')}",
        f"forensic_semantic_hash_missing_accepted_unaccepted={data.get('forensic_semantic_hash_missing_accepted', '-')}/{data.get('forensic_semantic_hash_missing_unaccepted', '-')}",
        f"forensic_rule_logical_key_present_missing={data.get('forensic_rule_logical_key_present', '-')}/{data.get('forensic_rule_logical_key_missing', '-')}",
        f"forensic_rule_logical_key_missing_accepted_unaccepted={data.get('forensic_rule_logical_key_missing_accepted', '-')}/{data.get('forensic_rule_logical_key_missing_unaccepted', '-')}",
        "forensic_lineage_scope_note=complete_means_zero_unaccepted_missing_not_full_identity_coverage",
    ]


def card_metadata(conn: sqlite3.Connection, card_name: str) -> sqlite3.Row | None:
    return conn.execute(
        "SELECT * FROM card_oracle_cache WHERE normalized_name=?",
        (normalize_name(card_name),),
    ).fetchone()


def _role_sort_key(role: str) -> int:
    try:
        return list(ROLE_FAMILIES).index(role)
    except ValueError:
        return len(ROLE_FAMILIES)


def battle_rule_deck_categories(conn: sqlite3.Connection, card_name: str) -> set[str]:
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='battle_card_rules'"
    ).fetchone()
    if not table:
        return set()
    rows = conn.execute(
        """
        SELECT deck_role_json, effect_json
        FROM battle_card_rules
        WHERE normalized_name=?
          AND review_status IN ('verified', 'needs_review', 'active')
          AND execution_status != 'disabled'
        """,
        (normalize_name(card_name),),
    ).fetchall()
    categories: set[str] = set()
    for row in rows:
        try:
            role = json.loads(str(row["deck_role_json"] or "{}"))
        except Exception:
            role = {}
        category = role.get("category") if isinstance(role, dict) else None
        if not category:
            try:
                effect = json.loads(str(row["effect_json"] or "{}"))
            except Exception:
                effect = {}
            if isinstance(effect, dict):
                category = battle_rule_registry.EFFECT_TO_DECK_CATEGORY.get(
                    str(effect.get("effect") or "")
                )
        if category:
            normalized = normalize_name(str(category)).replace(" ", "_")
            if normalized and normalized != "unknown":
                categories.add(normalized)
    return categories


def battle_rule_deck_category(conn: sqlite3.Connection, card_name: str) -> str | None:
    categories = battle_rule_deck_categories(conn, card_name)
    if not categories:
        return None
    return sorted(categories, key=_role_sort_key)[0]


def json_list(value: object) -> list[str]:
    if not value:
        return []
    if isinstance(value, list):
        result = []
        for item in value:
            if isinstance(item, dict):
                tag = item.get("tag") or item.get("role") or item.get("category")
                if tag:
                    result.append(str(tag))
            else:
                result.append(str(item))
        return result
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    if isinstance(decoded, list):
        return json_list(decoded)
    return []


def row_has_column(row: sqlite3.Row, column: str) -> bool:
    return column in row.keys()


def functional_tags_for_row(row: sqlite3.Row) -> set[str]:
    values: list[str] = []
    if row_has_column(row, "functional_tags_json"):
        values.extend(json_list(row["functional_tags_json"]))
    if row_has_column(row, "functional_tag") and row["functional_tag"]:
        values.append(str(row["functional_tag"]))
    return {
        normalize_name(value).replace(" ", "_")
        for value in values
        if normalize_name(value) not in {"", "unknown"}
    }


def infer_roles(
    functional_tags: Iterable[str],
    type_line: str,
    oracle_text: str,
) -> set[str]:
    tags = {normalize_name(tag).replace(" ", "_") for tag in functional_tags}
    text = f"{type_line}\n{oracle_text}".lower()
    roles: set[str] = set()
    for role, spec in ROLE_FAMILIES.items():
        if tags.intersection(spec["tags"]) or any(
            re.search(pattern, text) for pattern in spec["patterns"]
        ):
            roles.add(role)
    return roles


def roles_for_row(row: sqlite3.Row) -> set[str]:
    return infer_roles(
        functional_tags_for_row(row),
        str(row["type_line"] or ""),
        str(row["oracle_text"] or ""),
    )


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
    protected_cards = effective_protected_cards()
    protected_normalized = {normalize_name(name) for name in protected_cards}
    if normalize_name(card_removed) in protected_normalized:
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

    removed_roles = roles_for_row(removed[0]) if removed else set()
    added_roles = infer_roles(
        battle_rule_deck_categories(conn, card_added),
        type_line,
        str(meta["oracle_text"] if meta else ""),
    )
    for removed_role in sorted(removed_roles, key=lambda role: list(ROLE_FAMILIES).index(role)):
        if removed_role in added_roles:
            continue
        role_count = count_role(rows, removed_role)
        minimum = ROLE_FAMILIES[removed_role]["minimum"]
        if role_count <= minimum:
            reasons.append(
                f"cannot_cut_low_count_{removed_role}:"
                f"{card_removed} role={removed_role} count={role_count} "
                f"add_roles={','.join(sorted(added_roles)) or 'unknown'}"
            )
        else:
            warnings.append(
                f"role_mismatch:{card_removed} role={removed_role} "
                f"add_roles={','.join(sorted(added_roles)) or 'unknown'}"
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
    roles = infer_roles([functional_tag], type_line, oracle_text)
    for role in ROLE_FAMILIES:
        if role in roles:
            return role
    return None


def count_role(rows: Iterable[sqlite3.Row], role: str) -> int:
    return sum(1 for row in rows if role in roles_for_row(row))


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
        insert_columns = [
            "deck_id",
            "card_name",
            "quantity",
            "functional_tag",
            "tag_confidence",
            "is_commander",
            "is_partner",
            "cmc",
            "type_line",
            "oracle_text",
        ]
        values: list[object] = [
            deck_id,
            card_added,
            1,
            add_tag or "candidate",
            None,
            0,
            0,
            meta["cmc"] if meta else None,
            meta["type_line"] if meta else None,
            meta["oracle_text"] if meta else None,
        ]
        if "functional_tags_json" in columns:
            insert_columns.append("functional_tags_json")
            values.append(json.dumps([add_tag or "candidate"], ensure_ascii=True))
        placeholders = ", ".join("?" for _ in insert_columns)
        conn.execute(
            f"""
            INSERT INTO deck_cards ({", ".join(insert_columns)})
            VALUES ({placeholders})
            """,
            values,
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
    phases: tuple[str, ...] = ("best-in-slot", "phase1"),
    include_existing: bool = False,
    only_added: str = "",
) -> list[sqlite3.Row]:
    ensure_optimizer_tables(conn)
    where = [
        f"phase IN ({','.join('?' for _ in phases)})",
    ]
    params: list[object] = list(phases)
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
