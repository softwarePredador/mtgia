#!/usr/bin/env python3
"""Build focused evidence for simple battle-rule drafts.

This job is intentionally narrow and report-only. It consumes drafts from
`manaloom_battle_rule_review_queue.py`, runs focused runtime checks only for
supported low-risk templates, and emits an evidence file consumed by
`manaloom_battle_rule_promotion_gate.py`.

It never writes to PostgreSQL and never promotes a rule by itself.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import random
import sqlite3
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
HERMES_SCRIPTS_DIR = REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts"
DEFAULT_OUTPUT_DIR = REPO_ROOT / "server/test/artifacts/battle_rule_focused_evidence_local"
DEFAULT_KNOWLEDGE_DB = REPO_ROOT / "server/test/artifacts/new_card_candidate_review_local/knowledge.db"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


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


def table_exists(conn: sqlite3.Connection, name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name = ?",
        (name,),
    ).fetchone()
    return row is not None


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


@dataclass
class DraftRecord:
    run_id: str
    card_name: str
    oracle_id: str | None
    set_code: str
    draft_rule_key: str
    proposed_status: str
    confidence: str
    roles: list[str]
    effect_families: list[str]
    risk_flags: list[str]
    draft: dict[str, Any]


@dataclass
class EvidenceResult:
    draft: DraftRecord
    status: str
    reason: str
    evidence: dict[str, Any] = field(default_factory=dict)
    artifacts: list[str] = field(default_factory=list)

    def to_json(self) -> dict[str, Any]:
        return {
            "card_name": self.draft.card_name,
            "oracle_id": self.draft.oracle_id,
            "set_code": self.draft.set_code,
            "draft_rule_key": self.draft.draft_rule_key,
            "source_review_run_id": self.draft.run_id,
            "status": self.status,
            "reason": self.reason,
            "roles": self.draft.roles,
            "effect_families": self.draft.effect_families,
            "risk_flags": self.draft.risk_flags,
            "evidence": self.evidence,
            "artifacts": self.artifacts,
        }


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_battle_rule_focused_evidence_runs (
            run_id TEXT PRIMARY KEY,
            generated_at TEXT NOT NULL,
            evaluated_count INTEGER NOT NULL,
            evidence_count INTEGER NOT NULL,
            summary_json TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS new_card_battle_rule_focused_evidence_items (
            run_id TEXT NOT NULL,
            card_name TEXT NOT NULL,
            oracle_id TEXT,
            set_code TEXT,
            draft_rule_key TEXT NOT NULL,
            status TEXT NOT NULL,
            reason TEXT NOT NULL,
            evidence_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            PRIMARY KEY (run_id, card_name, set_code, draft_rule_key)
        )
        """
    )
    conn.commit()


def load_latest_drafts(conn: sqlite3.Connection, limit: int) -> list[DraftRecord]:
    if not table_exists(conn, "new_card_battle_rule_review_drafts"):
        return []
    rows = conn.execute(
        """
        SELECT
            run_id,
            card_name,
            oracle_id,
            set_code,
            draft_rule_key,
            proposed_status,
            confidence,
            roles_json,
            effect_families_json,
            risk_flags_json,
            draft_json
        FROM new_card_battle_rule_review_drafts
        WHERE run_id = (
            SELECT run_id
            FROM new_card_battle_rule_review_runs
            ORDER BY generated_at DESC
            LIMIT 1
        )
        ORDER BY card_name, set_code, draft_rule_key
        LIMIT ?
        """,
        (limit,),
    ).fetchall()
    return [
        DraftRecord(
            run_id=str(row[0]),
            card_name=str(row[1]),
            oracle_id=str(row[2]) if row[2] else None,
            set_code=str(row[3] or ""),
            draft_rule_key=str(row[4]),
            proposed_status=str(row[5] or ""),
            confidence=str(row[6] or ""),
            roles=[str(item) for item in parse_json(row[7], [])],
            effect_families=[str(item) for item in parse_json(row[8], [])],
            risk_flags=[str(item) for item in parse_json(row[9], [])],
            draft=parse_json(row[10], {}),
        )
        for row in rows
    ]


def _event_records(events: list[tuple[str, dict[str, Any]]], replay_id: str) -> list[dict[str, Any]]:
    return [
        {
            "event": event,
            "replay_id": replay_id,
            **data,
        }
        for event, data in events
    ]


def _decision_records(decisions: list[dict[str, Any]], replay_id: str) -> list[dict[str, Any]]:
    return [
        {
            **decision,
            "replay_id": decision.get("replay_id") or replay_id,
        }
        for decision in decisions
    ]


def _write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.write_text(
        "".join(json.dumps(row, sort_keys=True, default=str) + "\n" for row in rows),
        encoding="utf-8",
    )


def _severity_counts(findings: list[dict[str, Any]]) -> dict[str, int]:
    counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
    for finding in findings:
        severity = str(finding.get("severity") or "low")
        counts[severity] = counts.get(severity, 0) + 1
    return counts


def supports_counterspell_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        text == "counter target spell."
        and "counterspell_stack_interaction" in draft.effect_families
        and draft.proposed_status == "needs_review"
    )


def build_counterspell_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_focused_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_focused_evidence",
        HERMES_SCRIPTS_DIR / "replay_decision_auditor.py",
    )

    replay_id = f"focused_{draft.draft_rule_key}"
    events: list[tuple[str, dict[str, Any]]] = []
    decisions: list[dict[str, Any]] = []
    previous_event_handler = battle.REPLAY_EVENT_HANDLER
    previous_decision_handler = battle.DECISION_TRACE_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    battle.DECISION_TRACE_HANDLER = decisions.append
    try:
        if hasattr(battle, "reset_decision_trace_counter"):
            battle.reset_decision_trace_counter()
        active = battle.Player("Active", None, [])
        responder = battle.Player("Responder", None, [])
        responder.hand = [
            {
                "name": draft.card_name,
                "cmc": 2,
                "mana_cost": "{U}{U}",
                "tag": "counter",
                "effect": "counter",
                "type_line": "Instant",
            }
        ]
        responder.battlefield = [
            {"name": "Island", "type_line": "Basic Land - Island", "effect": "land"},
            {"name": "Island", "type_line": "Basic Land - Island", "effect": "land"},
        ]
        responder.refresh_mana_sources(turn=2)
        target_spell = {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
            "effect": "approach",
        }
        stack = battle.Stack()
        stack.push(target_spell, active, battle.get_card_effect(target_spell))

        first_priority = battle.priority_round(
            active,
            [active, responder],
            stack,
            2,
            random.Random(6),
            phase="precombat_main",
        )
        second_priority = battle.priority_round(
            active,
            [active, responder],
            stack,
            2,
            random.Random(6),
            phase="precombat_main",
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler

    event_rows = _event_records(events, replay_id)
    decision_rows = _decision_records(decisions, replay_id)
    event_findings = replay_auditor.audit_turn_events(event_rows)
    decision_findings = replay_auditor.audit_decision_traces(decision_rows)
    findings = [*event_findings, *decision_findings]
    counts = _severity_counts(findings)

    spell_countered = any(
        row.get("event") == "spell_countered"
        and row.get("counter") == draft.card_name
        and row.get("target") == "Approach of the Second Sun"
        for row in event_rows
    )
    target_finished = bool(active.graveyard) and active.graveyard[0].get("name") == "Approach of the Second Sun"
    counter_spent = bool(responder.graveyard) and responder.graveyard[0].get("name") == draft.card_name
    focused_passed = bool(
        first_priority
        and not second_priority
        and spell_countered
        and target_finished
        and counter_spent
        and counts.get("critical", 0) == 0
        and counts.get("high", 0) == 0
    )

    rule_dir = output_dir / "focused_artifacts" / draft.draft_rule_key
    rule_dir.mkdir(parents=True, exist_ok=True)
    events_path = rule_dir / "replay_events.jsonl"
    decisions_path = rule_dir / "decision_trace.jsonl"
    audit_path = rule_dir / "replay_audit.json"
    focused_path = rule_dir / "focused_test.json"
    _write_jsonl(events_path, event_rows)
    _write_jsonl(decisions_path, decision_rows)
    audit_payload = {
        "replay_id": replay_id,
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "medium_findings": counts.get("medium", 0),
        "low_findings": counts.get("low", 0),
        "findings": findings,
    }
    audit_path.write_text(json.dumps(audit_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    focused_payload = {
        "card_name": draft.card_name,
        "draft_rule_key": draft.draft_rule_key,
        "passed": focused_passed,
        "checks": {
            "first_priority_countered": bool(first_priority),
            "second_priority_resolved_stack": not bool(second_priority),
            "spell_countered_event": spell_countered,
            "target_spell_finished_in_graveyard": target_finished,
            "counter_card_spent": counter_spent,
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "counterspell_stack_interaction",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: Counter target spell.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_counterspell_stack_interaction_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="counterspell_stack_interaction_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def evaluate_draft(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    if supports_counterspell_template(draft):
        return build_counterspell_evidence(draft, output_dir)
    return EvidenceResult(
        draft=draft,
        status="unsupported",
        reason="no_focused_evidence_template_for_effect_family",
    )


def summarize(run_id: str, generated_at: str, results: list[EvidenceResult]) -> dict[str, Any]:
    statuses: dict[str, int] = {}
    reasons: dict[str, int] = {}
    for result in results:
        statuses[result.status] = statuses.get(result.status, 0) + 1
        reasons[result.reason] = reasons.get(result.reason, 0) + 1
    return {
        "run_id": run_id,
        "generated_at": generated_at,
        "mode": "sqlite_operational_cache",
        "dry_run": True,
        "evaluated_count": len(results),
        "evidence_count": statuses.get("evidence_ready", 0),
        "statuses": statuses,
        "reasons": reasons,
        "notes": [
            "report_only_no_pg_writes",
            "no_auto_promotion",
            "only_supported_low_risk_templates_generate_evidence",
            "promotion_gate_still_required",
        ],
    }


def persist(conn: sqlite3.Connection, summary: dict[str, Any], results: list[EvidenceResult]) -> None:
    ensure_schema(conn)
    run_id = summary["run_id"]
    generated_at = summary["generated_at"]
    conn.execute(
        """
        INSERT OR REPLACE INTO new_card_battle_rule_focused_evidence_runs (
            run_id, generated_at, evaluated_count, evidence_count, summary_json
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            run_id,
            generated_at,
            summary["evaluated_count"],
            summary["evidence_count"],
            json.dumps(summary, sort_keys=True),
        ),
    )
    for result in results:
        conn.execute(
            """
            INSERT OR REPLACE INTO new_card_battle_rule_focused_evidence_items (
                run_id, card_name, oracle_id, set_code, draft_rule_key,
                status, reason, evidence_json, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                run_id,
                result.draft.card_name,
                result.draft.oracle_id,
                result.draft.set_code,
                result.draft.draft_rule_key,
                result.status,
                result.reason,
                json.dumps(result.to_json(), sort_keys=True),
                generated_at,
            ),
        )
    conn.commit()


def render_markdown(summary: dict[str, Any], results: list[EvidenceResult]) -> str:
    lines = [
        "# Battle Rule Focused Evidence",
        "",
        f"- Run: `{summary['run_id']}`",
        f"- Generated at: `{summary['generated_at']}`",
        f"- Evaluated: `{summary['evaluated_count']}`",
        f"- Evidence ready: `{summary['evidence_count']}`",
        "",
        "| Card | Set | Draft rule | Status | Reason |",
        "| --- | --- | --- | --- | --- |",
    ]
    for result in results[:120]:
        lines.append(
            "| {card} | {set_code} | `{rule}` | `{status}` | `{reason}` |".format(
                card=result.draft.card_name.replace("|", "\\|"),
                set_code=result.draft.set_code,
                rule=result.draft.draft_rule_key,
                status=result.status,
                reason=result.reason,
            )
        )
    lines.extend(
        [
            "",
            "## Safety Contract",
            "",
            "- This job never writes to PostgreSQL.",
            "- Evidence only feeds the report-only promotion gate.",
            "- Unsupported or complex effect families stay blocked.",
            "- `evidence_ready` is not automatic promotion.",
            "",
        ]
    )
    return "\n".join(lines)


def write_artifacts(output_dir: Path, run_id: str, summary: dict[str, Any], results: list[EvidenceResult]) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    run_dir = output_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    items = [result.to_json() for result in results]
    evidence = {
        "by_draft_rule_key": {
            result.draft.draft_rule_key: result.evidence
            for result in results
            if result.status == "evidence_ready"
        }
    }
    for path in (run_dir / "summary.json", output_dir / "latest_summary.json"):
        path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for path in (run_dir / "items.json", output_dir / "latest_items.json"):
        path.write_text(json.dumps(items, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for path in (run_dir / "evidence.json", output_dir / "latest_evidence.json"):
        path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    report = render_markdown(summary, results)
    for path in (run_dir / "report.md", output_dir / "latest_report.md"):
        path.write_text(report, encoding="utf-8")
    return output_dir / "latest_evidence.json"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build focused evidence for battle-rule drafts")
    parser.add_argument("--knowledge-db", default=os.environ.get("MANALOOM_KNOWLEDGE_DB") or os.environ.get("HERMES_KNOWLEDGE_DB"))
    parser.add_argument("--output-dir", default=os.environ.get("MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE_DIR"))
    parser.add_argument("--limit", type=int, default=int(os.environ.get("MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE_LIMIT", "80")))
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> dict[str, Any]:
    db_path = Path(args.knowledge_db or DEFAULT_KNOWLEDGE_DB)
    output_dir = Path(
        args.output_dir
        or os.environ.get("MANALOOM_OPS_ARTIFACT_DIR", "")
        or DEFAULT_OUTPUT_DIR
    )
    if output_dir.name != "battle_rule_focused_evidence":
        output_dir = output_dir / "battle_rule_focused_evidence"
    generated_at = utc_now().isoformat(timespec="seconds")
    run_id = "battle_rule_focused_evidence_" + utc_now().strftime("%Y%m%d_%H%M%S_%f")

    if not db_path.exists():
        summary = summarize(run_id, generated_at, [])
        summary["blocked_reason"] = "knowledge_db_missing"
        evidence_file = write_artifacts(output_dir, run_id, summary, [])
        print(
            "MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE "
            + json.dumps({**summary, "evidence_file": str(evidence_file)}, sort_keys=True)
        )
        return summary

    conn = sqlite3.connect(db_path)
    try:
        ensure_schema(conn)
        drafts = load_latest_drafts(conn, args.limit)
        results = [evaluate_draft(draft, output_dir) for draft in drafts]
        summary = summarize(run_id, generated_at, results)
        persist(conn, summary, results)
    finally:
        conn.close()
    evidence_file = write_artifacts(output_dir, run_id, summary, results)
    print(
        "MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE "
        + json.dumps(
            {
                "run_id": run_id,
                "evaluated_count": summary["evaluated_count"],
                "evidence_count": summary["evidence_count"],
                "output_dir": str(output_dir),
                "evidence_file": str(evidence_file),
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
        print(f"MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE_FAILED {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
