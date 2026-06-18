#!/usr/bin/env python3
"""Report-only consumer for new-card battle rule review queue.

The job generates draft review artifacts from `new_card_battle_rule_review_queue`.
It never promotes rules to `verified` and never writes to PostgreSQL.
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
DEFAULT_OUTPUT_DIR = REPO_ROOT / "server/test/artifacts/battle_rule_review_queue_local"
DEFAULT_KNOWLEDGE_DB = REPO_ROOT / "server/test/artifacts/new_card_candidate_review_local/knowledge.db"


ROLE_TO_EFFECT_FAMILY = {
    "board_wipe": "mass_removal_or_modal_wipe",
    "draw": "card_advantage_or_selection",
    "engine": "triggered_or_static_engine",
    "enabler": "synergy_enabler",
    "payoff": "synergy_payoff",
    "protection": "protection_or_prevention",
    "ramp": "mana_or_resource_acceleration",
    "recursion": "graveyard_or_zone_recursion",
    "removal": "targeted_interaction",
    "token": "token_or_board_presence",
    "tutor": "library_search_or_selection",
    "wincon": "win_condition",
}


def infer_effect_families_from_text(oracle_text: str) -> list[str]:
    text = oracle_text.lower()
    families: set[str] = set()
    if "additional combat phase" in text:
        families.add("extra_combat_phase")
    if "flashback" in text:
        families.add("graveyard_recast_replacement")
    if "counter target spell" in text:
        families.add("counterspell_stack_interaction")
    if "search your library" in text:
        families.add("library_search_or_selection")
    if "treasure token" in text:
        families.add("treasure_resource_generation")
    if "draw a card" in text or "draw cards" in text:
        families.add("card_advantage_or_selection")
    if "destroy all" in text or "exile all" in text:
        families.add("mass_removal_or_modal_wipe")
    if "destroy target" in text or "exile target" in text or "damage to target" in text:
        families.add("targeted_interaction")
    if "+1/+1 counter" in text:
        families.add("counter_manipulation")
    if "copy" in text and ("spell" in text or "target" in text):
        families.add("copy_spell_or_permanent")
    return sorted(families)


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def normalize_name(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"[^a-z0-9]+", "_", value.strip().lower()).strip("_")


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
class QueueRow:
    commander_name: str
    card_name: str
    oracle_id: str | None
    set_code: str
    roles: list[str]
    reason: str
    latest_run_id: str
    payload: dict[str, Any] = field(default_factory=dict)
    candidate_score: int = 0
    candidate_reasons: list[str] = field(default_factory=list)


@dataclass
class RuleDraft:
    card_name: str
    oracle_id: str | None
    set_code: str
    roles: set[str] = field(default_factory=set)
    commanders: set[str] = field(default_factory=set)
    reasons: set[str] = field(default_factory=set)
    source_run_ids: set[str] = field(default_factory=set)
    max_score: int = 0
    payload: dict[str, Any] = field(default_factory=dict)

    @property
    def draft_rule_key(self) -> str:
        role_hint = unique_sorted(self.roles)[0] if self.roles else "review"
        return f"{normalize_name(self.card_name)}__{role_hint}__draft_v1"

    @property
    def effect_families(self) -> list[str]:
        from_roles = [ROLE_TO_EFFECT_FAMILY.get(role, role) for role in self.roles]
        from_text = infer_effect_families_from_text(str(self.payload.get("oracle_text") or ""))
        return unique_sorted([*from_roles, *from_text])

    @property
    def confidence(self) -> str:
        oracle_text = str(self.payload.get("oracle_text") or "").strip()
        if not oracle_text:
            return "low"
        if self.max_score >= 70 and len(self.roles) <= 4:
            return "medium"
        return "low"

    @property
    def risk_flags(self) -> list[str]:
        flags = {
            "do_not_execute_until_verified",
            "requires_official_oracle_and_rulings_review",
            "requires_focused_replay_test",
        }
        if not str(self.payload.get("oracle_text") or "").strip():
            flags.add("missing_oracle_text")
        if len(self.roles) >= 5:
            flags.add("multi_role_complexity")
        if "tutor" in self.roles:
            flags.add("search_effect_needs_target_policy")
        if "board_wipe" in self.roles:
            flags.add("wipe_needs_asymmetry_and_timing_policy")
        if "extra_combat_phase" in self.effect_families:
            flags.add("extra_combat_needs_phase_model_test")
        if "graveyard_recast_replacement" in self.effect_families:
            flags.add("flashback_or_recast_needs_zone_replacement_test")
        return sorted(flags)

    def test_scenario(self) -> str:
        families = ", ".join(self.effect_families) or "unknown effect"
        return (
            f"Create a focused replay with {self.card_name} in hand, legal mana, "
            f"one meaningful board state for {families}, and assert that the simulator "
            "emits a traceable needs_review decision without executing verified-only behavior."
        )

    def to_json(self) -> dict[str, Any]:
        return {
            "card_name": self.card_name,
            "oracle_id": self.oracle_id,
            "set_code": self.set_code,
            "draft_rule_key": self.draft_rule_key,
            "proposed_status": "needs_review",
            "confidence": self.confidence,
            "roles": unique_sorted(self.roles),
            "effect_families": self.effect_families,
            "commanders": unique_sorted(self.commanders),
            "source_run_ids": unique_sorted(self.source_run_ids),
            "max_score": self.max_score,
            "reasons": unique_sorted(self.reasons)[:12],
            "risk_flags": self.risk_flags,
            "oracle_text_excerpt": str(self.payload.get("oracle_text") or "")[:500],
            "test_scenario": self.test_scenario(),
            "safety": [
                "draft_only",
                "no_postgres_write",
                "no_verified_promotion",
                "no_hard_battle_behavior",
            ],
        }


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_battle_rule_review_runs (
            run_id TEXT PRIMARY KEY,
            generated_at TEXT NOT NULL,
            queue_rows INTEGER NOT NULL,
            draft_count INTEGER NOT NULL,
            summary_json TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_battle_rule_review_drafts (
            run_id TEXT NOT NULL,
            card_name TEXT NOT NULL,
            oracle_id TEXT,
            set_code TEXT,
            draft_rule_key TEXT NOT NULL,
            proposed_status TEXT NOT NULL,
            confidence TEXT NOT NULL,
            roles_json TEXT NOT NULL,
            effect_families_json TEXT NOT NULL,
            commanders_json TEXT NOT NULL,
            risk_flags_json TEXT NOT NULL,
            draft_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (run_id, card_name, set_code, draft_rule_key)
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


def load_queue_rows(conn: sqlite3.Connection, limit: int) -> list[QueueRow]:
    if not table_exists(conn, "new_card_battle_rule_review_queue"):
        return []
    rows = conn.execute(
        """
        SELECT
            q.commander_name,
            q.card_name,
            q.oracle_id,
            COALESCE(q.set_code, '') AS set_code,
            q.roles_json,
            q.reason,
            q.latest_run_id,
            r.score,
            r.reasons_json,
            r.payload_json
        FROM new_card_battle_rule_review_queue q
        LEFT JOIN new_card_candidate_reviews r
            ON r.run_id = q.latest_run_id
           AND r.commander_name = q.commander_name
           AND r.card_name = q.card_name
           AND COALESCE(r.set_code, '') = COALESCE(q.set_code, '')
        ORDER BY COALESCE(r.score, 0) DESC, q.card_name, q.commander_name
        LIMIT ?
        """,
        (limit,),
    ).fetchall()
    return [
        QueueRow(
            commander_name=str(row[0]),
            card_name=str(row[1]),
            oracle_id=str(row[2]) if row[2] else None,
            set_code=str(row[3] or ""),
            roles=[str(item) for item in parse_json(row[4], [])],
            reason=str(row[5] or ""),
            latest_run_id=str(row[6] or ""),
            candidate_score=int(row[7] or 0),
            candidate_reasons=[str(item) for item in parse_json(row[8], [])],
            payload=parse_json(row[9], {}),
        )
        for row in rows
    ]


def aggregate(rows: list[QueueRow]) -> list[RuleDraft]:
    drafts: dict[str, RuleDraft] = {}
    for row in rows:
        key = row.oracle_id or f"{normalize_name(row.card_name)}::{row.set_code}"
        draft = drafts.setdefault(
            key,
            RuleDraft(
                card_name=row.card_name,
                oracle_id=row.oracle_id,
                set_code=row.set_code,
                payload=row.payload,
            ),
        )
        draft.roles.update(row.roles)
        draft.commanders.add(row.commander_name)
        draft.reasons.add(row.reason)
        draft.reasons.update(row.candidate_reasons)
        draft.source_run_ids.add(row.latest_run_id)
        draft.max_score = max(draft.max_score, row.candidate_score)
        if not draft.payload and row.payload:
            draft.payload = row.payload
    return sorted(drafts.values(), key=lambda item: (-item.max_score, item.card_name))


def summarize(run_id: str, generated_at: str, queue_rows: list[QueueRow], drafts: list[RuleDraft]) -> dict[str, Any]:
    confidence_counts: dict[str, int] = {}
    effect_counts: dict[str, int] = {}
    for draft in drafts:
        confidence_counts[draft.confidence] = confidence_counts.get(draft.confidence, 0) + 1
        for family in draft.effect_families:
            effect_counts[family] = effect_counts.get(family, 0) + 1
    return {
        "run_id": run_id,
        "generated_at": generated_at,
        "mode": "sqlite_operational_cache",
        "dry_run": True,
        "queue_rows": len(queue_rows),
        "draft_count": len(drafts),
        "confidence_counts": confidence_counts,
        "effect_family_counts": effect_counts,
        "notes": [
            "report_only_no_pg_writes",
            "drafts_remain_needs_review",
            "no_verified_promotion",
            "no_hard_battle_behavior",
            "no_llm_used",
        ],
    }


def render_markdown(summary: dict[str, Any], drafts: list[RuleDraft]) -> str:
    lines = [
        "# Battle Rule Review Queue",
        "",
        f"- Run: `{summary['run_id']}`",
        f"- Generated at: `{summary['generated_at']}`",
        f"- Queue rows: `{summary['queue_rows']}`",
        f"- Drafts: `{summary['draft_count']}`",
        "",
        "## Confidence",
        "",
    ]
    for confidence, count in sorted(summary["confidence_counts"].items()):
        lines.append(f"- `{confidence}`: {count}")
    lines.extend(["", "## Effect Families", ""])
    for family, count in sorted(summary["effect_family_counts"].items()):
        lines.append(f"- `{family}`: {count}")
    lines.extend(["", "## Drafts", ""])
    if not drafts:
        lines.append("No battle rule review queue rows found.")
    else:
        lines.append("| Card | Set | Status | Confidence | Roles | Effect Families | Risk Flags | Test Scenario |")
        lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
        for draft in drafts[:80]:
            payload = draft.to_json()
            lines.append(
                "| {card} | {set_code} | `{status}` | `{confidence}` | {roles} | {families} | {flags} | {scenario} |".format(
                    card=payload["card_name"].replace("|", "\\|"),
                    set_code=payload["set_code"],
                    status=payload["proposed_status"],
                    confidence=payload["confidence"],
                    roles=", ".join(payload["roles"]).replace("|", "\\|"),
                    families=", ".join(payload["effect_families"]).replace("|", "\\|"),
                    flags=", ".join(payload["risk_flags"]).replace("|", "\\|"),
                    scenario=payload["test_scenario"].replace("|", "\\|"),
                )
            )
    lines.extend(
        [
            "",
            "## Safety Contract",
            "",
            "- Drafts are not written to PostgreSQL `card_battle_rules`.",
            "- Drafts do not become `verified` automatically.",
            "- Battle must not execute hard behavior from these drafts.",
            "- Promotion requires official source review, focused test, replay audit, and no critical finding.",
            "",
        ]
    )
    return "\n".join(lines)


def persist(conn: sqlite3.Connection, summary: dict[str, Any], drafts: list[RuleDraft]) -> None:
    ensure_schema(conn)
    run_id = summary["run_id"]
    generated_at = summary["generated_at"]
    conn.execute(
        """
        INSERT OR REPLACE INTO new_card_battle_rule_review_runs (
            run_id, generated_at, queue_rows, draft_count, summary_json
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            run_id,
            generated_at,
            summary["queue_rows"],
            summary["draft_count"],
            json.dumps(summary, sort_keys=True),
        ),
    )
    for draft in drafts:
        payload = draft.to_json()
        conn.execute(
            """
            INSERT OR REPLACE INTO new_card_battle_rule_review_drafts (
                run_id, card_name, oracle_id, set_code, draft_rule_key,
                proposed_status, confidence, roles_json, effect_families_json,
                commanders_json, risk_flags_json, draft_json, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                run_id,
                payload["card_name"],
                payload["oracle_id"],
                payload["set_code"],
                payload["draft_rule_key"],
                payload["proposed_status"],
                payload["confidence"],
                json.dumps(payload["roles"], sort_keys=True),
                json.dumps(payload["effect_families"], sort_keys=True),
                json.dumps(payload["commanders"], sort_keys=True),
                json.dumps(payload["risk_flags"], sort_keys=True),
                json.dumps(payload, sort_keys=True),
                generated_at,
            ),
        )
    conn.commit()


def write_artifacts(output_dir: Path, run_id: str, summary: dict[str, Any], drafts: list[RuleDraft]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    run_dir = output_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    draft_payloads = [draft.to_json() for draft in drafts]
    for path in (run_dir / "summary.json", output_dir / "latest_summary.json"):
        path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for path in (run_dir / "drafts.json", output_dir / "latest_drafts.json"):
        path.write_text(json.dumps(draft_payloads, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    report = render_markdown(summary, drafts)
    for path in (run_dir / "report.md", output_dir / "latest_report.md"):
        path.write_text(report, encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Report-only battle rule review queue")
    parser.add_argument("--knowledge-db", default=os.environ.get("MANALOOM_KNOWLEDGE_DB") or os.environ.get("HERMES_KNOWLEDGE_DB"))
    parser.add_argument("--output-dir", default=os.environ.get("MANALOOM_BATTLE_RULE_REVIEW_QUEUE_DIR"))
    parser.add_argument("--limit", type=int, default=int(os.environ.get("MANALOOM_BATTLE_RULE_REVIEW_QUEUE_LIMIT", "250")))
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> dict[str, Any]:
    db_path = Path(args.knowledge_db or DEFAULT_KNOWLEDGE_DB)
    output_dir = Path(
        args.output_dir
        or os.environ.get("MANALOOM_OPS_ARTIFACT_DIR", "")
        or DEFAULT_OUTPUT_DIR
    )
    if output_dir.name != "battle_rule_review_queue":
        output_dir = output_dir / "battle_rule_review_queue"
    generated_at = utc_now().isoformat(timespec="seconds")
    run_id = "battle_rule_review_queue_" + utc_now().strftime("%Y%m%d_%H%M%S")
    if not db_path.exists():
        summary = summarize(run_id, generated_at, [], [])
        summary["blocked_reason"] = "knowledge_db_missing"
        write_artifacts(output_dir, run_id, summary, [])
        print("MANALOOM_BATTLE_RULE_REVIEW_QUEUE " + json.dumps(summary, sort_keys=True))
        return summary

    conn = sqlite3.connect(db_path)
    try:
        ensure_schema(conn)
        rows = load_queue_rows(conn, args.limit)
        drafts = aggregate(rows)
        summary = summarize(run_id, generated_at, rows, drafts)
        persist(conn, summary, drafts)
    finally:
        conn.close()
    write_artifacts(output_dir, run_id, summary, drafts)
    print(
        "MANALOOM_BATTLE_RULE_REVIEW_QUEUE "
        + json.dumps(
            {
                "run_id": run_id,
                "queue_rows": summary["queue_rows"],
                "draft_count": summary["draft_count"],
                "confidence_counts": summary["confidence_counts"],
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
        print(f"MANALOOM_BATTLE_RULE_REVIEW_QUEUE_FAILED {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
