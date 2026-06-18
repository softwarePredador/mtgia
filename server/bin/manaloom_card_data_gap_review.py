#!/usr/bin/env python3
"""Report-only review of new-card data gaps.

This job consumes `new_card_candidate_reviews` rows with `decision=needs_data`
from the ManaLoom operational SQLite cache. It does not mutate PostgreSQL.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_OUTPUT_DIR = REPO_ROOT / "server/test/artifacts/card_data_gap_review_local"
DEFAULT_KNOWLEDGE_DB = REPO_ROOT / "server/test/artifacts/new_card_candidate_review_local/knowledge.db"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def normalize_name(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"\s+", " ", value.strip().lower())


def parse_json(value: Any, default: Any) -> Any:
    if value is None:
        return default
    if isinstance(value, (dict, list)):
        return value
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return default
        try:
            return json.loads(text)
        except Exception:
            return default
    return default


def unique_sorted(values: Iterable[str]) -> list[str]:
    return sorted({value for value in values if value})


@dataclass
class DataGapRow:
    run_id: str
    commander_name: str
    card_name: str
    oracle_id: str | None
    set_code: str
    score: int
    roles: list[str]
    reasons: list[str]
    risk_flags: list[str]
    battle_rule_status: str
    payload: dict[str, Any]


@dataclass
class DataGapItem:
    card_name: str
    oracle_id: str | None
    set_code: str
    commanders: set[str] = field(default_factory=set)
    roles: set[str] = field(default_factory=set)
    reasons: set[str] = field(default_factory=set)
    risk_flags: set[str] = field(default_factory=set)
    actions: set[str] = field(default_factory=set)
    max_score: int = 0
    payload: dict[str, Any] = field(default_factory=dict)

    @property
    def key(self) -> str:
        return self.oracle_id or f"{normalize_name(self.card_name)}::{self.set_code}"

    @property
    def priority(self) -> str:
        if self.max_score >= 70 or len(self.commanders) >= 5:
            return "high"
        if self.max_score >= 45 or len(self.commanders) >= 2:
            return "medium"
        return "low"

    @property
    def decision(self) -> str:
        if "missing_oracle_text" in self.risk_flags or "refresh_oracle_text" in self.actions:
            return "needs_oracle_sync"
        if "missing_commander_legality" in self.risk_flags or "refresh_commander_legality" in self.actions:
            return "needs_legality_sync"
        if "resolve_oracle_id" in self.actions:
            return "needs_identity_resolution"
        return "needs_catalog_review"

    def to_json(self) -> dict[str, Any]:
        return {
            "card_name": self.card_name,
            "oracle_id": self.oracle_id,
            "set_code": self.set_code,
            "decision": self.decision,
            "priority": self.priority,
            "max_score": self.max_score,
            "commanders": unique_sorted(self.commanders),
            "roles": unique_sorted(self.roles),
            "risk_flags": unique_sorted(self.risk_flags),
            "actions": unique_sorted(self.actions),
            "reasons": unique_sorted(self.reasons)[:12],
            "payload": self.payload,
        }


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_data_gap_review_runs (
            run_id TEXT PRIMARY KEY,
            generated_at TEXT NOT NULL,
            source_candidate_run_id TEXT,
            gap_rows INTEGER NOT NULL,
            unique_cards INTEGER NOT NULL,
            summary_json TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_data_gap_review_items (
            run_id TEXT NOT NULL,
            card_name TEXT NOT NULL,
            oracle_id TEXT,
            set_code TEXT,
            decision TEXT NOT NULL,
            priority TEXT NOT NULL,
            max_score INTEGER NOT NULL,
            commanders_json TEXT NOT NULL,
            roles_json TEXT NOT NULL,
            risk_flags_json TEXT NOT NULL,
            actions_json TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (run_id, card_name, set_code)
        )
        """
    )
    conn.commit()


def table_exists(conn: sqlite3.Connection, name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name = ?",
        (name,),
    ).fetchone()
    return row is not None


def latest_candidate_run_id(conn: sqlite3.Connection) -> str | None:
    if not table_exists(conn, "new_card_candidate_review_runs"):
        return None
    row = conn.execute(
        """
        SELECT run_id
        FROM new_card_candidate_review_runs
        ORDER BY generated_at DESC
        LIMIT 1
        """
    ).fetchone()
    return str(row[0]) if row else None


def load_gap_rows(conn: sqlite3.Connection, source_run_id: str) -> list[DataGapRow]:
    if not table_exists(conn, "new_card_candidate_reviews"):
        return []
    rows = conn.execute(
        """
        SELECT
            run_id,
            commander_name,
            card_name,
            oracle_id,
            COALESCE(set_code, '') AS set_code,
            score,
            roles_json,
            reasons_json,
            risk_flags_json,
            battle_rule_status,
            payload_json
        FROM new_card_candidate_reviews
        WHERE run_id = ? AND decision = 'needs_data'
        ORDER BY score DESC, commander_name, card_name
        """,
        (source_run_id,),
    ).fetchall()
    return [
        DataGapRow(
            run_id=str(row[0]),
            commander_name=str(row[1]),
            card_name=str(row[2]),
            oracle_id=str(row[3]) if row[3] else None,
            set_code=str(row[4] or ""),
            score=int(row[5] or 0),
            roles=[str(item) for item in parse_json(row[6], [])],
            reasons=[str(item) for item in parse_json(row[7], [])],
            risk_flags=[str(item) for item in parse_json(row[8], [])],
            battle_rule_status=str(row[9] or "unknown"),
            payload=parse_json(row[10], {}),
        )
        for row in rows
    ]


def classify_actions(row: DataGapRow) -> list[str]:
    actions: set[str] = set()
    legalities = row.payload.get("legalities")
    oracle_text = str(row.payload.get("oracle_text") or "").strip()
    if not row.oracle_id:
        actions.add("resolve_oracle_id")
    if "missing_oracle_text" in row.risk_flags or not oracle_text:
        actions.add("refresh_oracle_text")
    if "missing_commander_legality" in row.risk_flags:
        actions.add("refresh_commander_legality")
    if not isinstance(legalities, dict) or not legalities.get("commander"):
        actions.add("refresh_card_legalities")
    if row.set_code:
        actions.add(f"review_set:{row.set_code}")
    if row.battle_rule_status == "missing":
        actions.add("defer_battle_rule_until_data_complete")
    return sorted(actions)


def aggregate_rows(rows: list[DataGapRow]) -> list[DataGapItem]:
    items: dict[str, DataGapItem] = {}
    for row in rows:
        key = row.oracle_id or f"{normalize_name(row.card_name)}::{row.set_code}"
        item = items.setdefault(
            key,
            DataGapItem(
                card_name=row.card_name,
                oracle_id=row.oracle_id,
                set_code=row.set_code,
                payload=row.payload,
            ),
        )
        item.commanders.add(row.commander_name)
        item.roles.update(row.roles)
        item.reasons.update(row.reasons)
        item.risk_flags.update(row.risk_flags)
        item.actions.update(classify_actions(row))
        item.max_score = max(item.max_score, row.score)
        if not item.payload and row.payload:
            item.payload = row.payload
    return sorted(items.values(), key=lambda item: (-item.max_score, item.card_name))


def summarize(run_id: str, generated_at: str, source_run_id: str | None, rows: list[DataGapRow], items: list[DataGapItem]) -> dict[str, Any]:
    decisions: dict[str, int] = {}
    actions: dict[str, int] = {}
    priorities: dict[str, int] = {}
    for item in items:
        decisions[item.decision] = decisions.get(item.decision, 0) + 1
        priorities[item.priority] = priorities.get(item.priority, 0) + 1
        for action in item.actions:
            actions[action] = actions.get(action, 0) + 1
    return {
        "run_id": run_id,
        "generated_at": generated_at,
        "source_candidate_run_id": source_run_id,
        "mode": "sqlite_operational_cache",
        "dry_run": True,
        "gap_rows": len(rows),
        "unique_cards": len(items),
        "decisions": decisions,
        "actions": actions,
        "priorities": priorities,
        "notes": [
            "report_only_no_pg_writes",
            "postgres_backend_remains_source_of_truth",
            "refresh_actions_are_recommendations_only",
            "no_llm_used",
        ],
    }


def render_markdown(summary: dict[str, Any], items: list[DataGapItem]) -> str:
    lines = [
        "# New Card Data Gap Review",
        "",
        f"- Run: `{summary['run_id']}`",
        f"- Generated at: `{summary['generated_at']}`",
        f"- Source candidate run: `{summary.get('source_candidate_run_id')}`",
        f"- Gap rows: `{summary['gap_rows']}`",
        f"- Unique cards: `{summary['unique_cards']}`",
        "",
        "## Decisions",
        "",
    ]
    for decision, count in sorted(summary["decisions"].items()):
        lines.append(f"- `{decision}`: {count}")
    lines.extend(["", "## Recommended Sync Actions", ""])
    for action, count in sorted(summary["actions"].items()):
        lines.append(f"- `{action}`: {count}")
    lines.extend(["", "## Top Cards", ""])
    if not items:
        lines.append("No data gaps found.")
    else:
        lines.append("| Priority | Card | Set | Decision | Score | Commanders | Actions | Risk Flags |")
        lines.append("| --- | --- | --- | --- | ---: | --- | --- | --- |")
        for item in items[:80]:
            payload = item.to_json()
            lines.append(
                "| {priority} | {card} | {set_code} | `{decision}` | {score} | {commanders} | {actions} | {risk_flags} |".format(
                    priority=payload["priority"],
                    card=payload["card_name"].replace("|", "\\|"),
                    set_code=payload["set_code"],
                    decision=payload["decision"],
                    score=payload["max_score"],
                    commanders=", ".join(payload["commanders"][:4]).replace("|", "\\|"),
                    actions=", ".join(payload["actions"]).replace("|", "\\|"),
                    risk_flags=", ".join(payload["risk_flags"]).replace("|", "\\|"),
                )
            )
    lines.extend(
        [
            "",
            "## Safety Contract",
            "",
            "- This job does not write to PostgreSQL.",
            "- It does not change decks, tags, or battle rules.",
            "- It only classifies catalog gaps so a sync job or human review can handle them.",
            "",
        ]
    )
    return "\n".join(lines)


def persist(conn: sqlite3.Connection, summary: dict[str, Any], items: list[DataGapItem]) -> None:
    ensure_schema(conn)
    run_id = summary["run_id"]
    generated_at = summary["generated_at"]
    conn.execute(
        """
        INSERT OR REPLACE INTO new_card_data_gap_review_runs (
            run_id, generated_at, source_candidate_run_id,
            gap_rows, unique_cards, summary_json
        ) VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            run_id,
            generated_at,
            summary.get("source_candidate_run_id"),
            summary["gap_rows"],
            summary["unique_cards"],
            json.dumps(summary, sort_keys=True),
        ),
    )
    for item in items:
        payload = item.to_json()
        conn.execute(
            """
            INSERT OR REPLACE INTO new_card_data_gap_review_items (
                run_id, card_name, oracle_id, set_code, decision, priority,
                max_score, commanders_json, roles_json, risk_flags_json,
                actions_json, payload_json, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                run_id,
                payload["card_name"],
                payload["oracle_id"],
                payload["set_code"],
                payload["decision"],
                payload["priority"],
                payload["max_score"],
                json.dumps(payload["commanders"], sort_keys=True),
                json.dumps(payload["roles"], sort_keys=True),
                json.dumps(payload["risk_flags"], sort_keys=True),
                json.dumps(payload["actions"], sort_keys=True),
                json.dumps(payload, sort_keys=True),
                generated_at,
            ),
        )
    conn.commit()


def write_artifacts(output_dir: Path, run_id: str, summary: dict[str, Any], items: list[DataGapItem]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    run_dir = output_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    item_payloads = [item.to_json() for item in items]
    for path in (run_dir / "summary.json", output_dir / "latest_summary.json"):
        path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for path in (run_dir / "items.json", output_dir / "latest_items.json"):
        path.write_text(json.dumps(item_payloads, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    report = render_markdown(summary, items)
    for path in (run_dir / "report.md", output_dir / "latest_report.md"):
        path.write_text(report, encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Report-only new-card data gap review")
    parser.add_argument("--knowledge-db", default=os.environ.get("MANALOOM_KNOWLEDGE_DB") or os.environ.get("HERMES_KNOWLEDGE_DB"))
    parser.add_argument("--output-dir", default=os.environ.get("MANALOOM_CARD_DATA_GAP_REVIEW_DIR"))
    parser.add_argument("--source-run-id")
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> dict[str, Any]:
    db_path = Path(args.knowledge_db or DEFAULT_KNOWLEDGE_DB)
    output_dir = Path(
        args.output_dir
        or os.environ.get("MANALOOM_OPS_ARTIFACT_DIR", "")
        or DEFAULT_OUTPUT_DIR
    )
    if output_dir.name != "card_data_gap_review":
        output_dir = output_dir / "card_data_gap_review"
    generated_at = utc_now().isoformat(timespec="seconds")
    run_id = "card_data_gap_review_" + utc_now().strftime("%Y%m%d_%H%M%S")
    if not db_path.exists():
        summary = summarize(run_id, generated_at, None, [], [])
        summary["blocked_reason"] = "knowledge_db_missing"
        write_artifacts(output_dir, run_id, summary, [])
        print("MANALOOM_CARD_DATA_GAP_REVIEW " + json.dumps(summary, sort_keys=True))
        return summary

    conn = sqlite3.connect(db_path)
    try:
        ensure_schema(conn)
        source_run_id = args.source_run_id or latest_candidate_run_id(conn)
        rows = load_gap_rows(conn, source_run_id) if source_run_id else []
        items = aggregate_rows(rows)
        summary = summarize(run_id, generated_at, source_run_id, rows, items)
        persist(conn, summary, items)
    finally:
        conn.close()
    write_artifacts(output_dir, run_id, summary, items)
    print(
        "MANALOOM_CARD_DATA_GAP_REVIEW "
        + json.dumps(
            {
                "run_id": run_id,
                "source_candidate_run_id": summary.get("source_candidate_run_id"),
                "gap_rows": summary["gap_rows"],
                "unique_cards": summary["unique_cards"],
                "decisions": summary["decisions"],
                "output_dir": str(output_dir),
                "knowledge_db": str(db_path),
            },
            sort_keys=True,
        )
    )
    return summary


def main(argv: list[str] | None = None) -> int:
    try:
        run(parse_args(argv))
    except Exception as exc:
        print(f"MANALOOM_CARD_DATA_GAP_REVIEW_FAILED {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
