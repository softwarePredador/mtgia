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
    limit_clause = "" if limit <= 0 else "LIMIT ?"
    params: tuple[int, ...] = () if limit <= 0 else (limit,)
    rows = conn.execute(
        f"""
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
        {limit_clause}
        """,
        params,
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


def supports_sacrifice_damage_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        "sacrifice a creature:" in text
        and (
            "damage to any target" in text
            or "damage to target" in text
            or "deals 1 damage to any target" in text
        )
        and draft.proposed_status == "needs_review"
    )


def supports_extra_combat_flashback_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        (
            "extra_combat_phase" in draft.effect_families
            or "additional combat phase" in text
        )
        and (
            "graveyard_recast_replacement" in draft.effect_families
            or "flashback" in text
        )
        and draft.proposed_status == "needs_review"
    )


def supports_attack_artifact_tutor_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        (
            "attack_trigger_artifact_tutor" in draft.effect_families
            or (
                "whenever" in text
                and "attacks" in text
                and "treasure token" in text
                and "sacrifice" in text
                and "artifact" in text
                and "search your library" in text
                and "artifact card" in text
                and "onto the battlefield" in text
            )
        )
        and draft.proposed_status == "needs_review"
    )


def supports_destroy_target_creature_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        "targeted_interaction" in draft.effect_families
        and "destroy target creature." in text
        and "or " not in text
        and "can't be regenerated" not in text
        and draft.proposed_status == "needs_review"
    )


def supports_destroy_target_nonland_permanent_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        "targeted_interaction" in draft.effect_families
        and text == "destroy target nonland permanent."
        and draft.proposed_status == "needs_review"
    )


def supports_destroy_target_artifact_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        "targeted_interaction" in draft.effect_families
        and text == "destroy target artifact."
        and draft.proposed_status == "needs_review"
    )


def supports_destroy_target_enchantment_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        "targeted_interaction" in draft.effect_families
        and text == "destroy target enchantment."
        and draft.proposed_status == "needs_review"
    )


def supports_destroy_all_creatures_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        "mass_removal_or_modal_wipe" in draft.effect_families
        and "destroy all creatures." in text
        and "can't be regenerated" not in text
        and "choose" not in text
        and draft.proposed_status == "needs_review"
    )


def supports_creatures_indestructible_template(draft: DraftRecord) -> bool:
    text = str(draft.draft.get("oracle_text_excerpt") or "").strip().lower()
    return (
        "protection_or_prevention" in draft.effect_families
        and "creatures you control" in text
        and "gain indestructible until end of turn" in text
        and "target" not in text
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


def build_destroy_target_creature_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_destroy_target_creature_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_destroy_target_creature_evidence",
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
        opponent = battle.Player("Opponent", None, [])
        target = {
            "name": "Threat Creature",
            "cmc": 5,
            "type_line": "Creature",
            "effect": "creature",
            "power": 5,
            "toughness": 5,
            "controller": opponent.name,
        }
        decoy = {
            "name": "Small Creature",
            "cmc": 1,
            "type_line": "Creature",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "controller": opponent.name,
        }
        opponent.battlefield = [decoy, target]
        spell = {
            "name": draft.card_name,
            "cmc": 2,
            "type_line": "Instant",
            "oracle_text": "Destroy target creature.",
            "tag": "removal",
            "effect": "remove_creature",
            "target": "creature",
            "_rule_source": "focused_battle_rule_evidence",
            "_rule_review_status": "needs_review",
        }
        battle.apply_effect_immediate(active, [opponent], spell, turn=4, rng=random.Random(11))
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler

    event_rows = _event_records(events, replay_id)
    decision_rows = _decision_records(decisions, replay_id)
    event_findings = replay_auditor.audit_turn_events(event_rows)
    decision_findings = replay_auditor.audit_decision_traces(decision_rows)
    findings = [*event_findings, *decision_findings]
    counts = _severity_counts(findings)

    removal_event = any(
        row.get("event") == "removal_resolved"
        and row.get("card") == draft.card_name
        and row.get("target") == "Threat Creature"
        and row.get("target_legal") is True
        for row in event_rows
    )
    focused_passed = bool(
        removal_event
        and not any(card.get("name") == "Threat Creature" for card in opponent.battlefield)
        and any(card.get("name") == "Small Creature" for card in opponent.battlefield)
        and any(card.get("name") == "Threat Creature" for card in opponent.graveyard)
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
            "removal_event": removal_event,
            "threat_removed": not any(card.get("name") == "Threat Creature" for card in opponent.battlefield),
            "decoy_preserved": any(card.get("name") == "Small Creature" for card in opponent.battlefield),
            "target_in_graveyard": any(card.get("name") == "Threat Creature" for card in opponent.graveyard),
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "destroy_target_creature",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: Destroy target creature.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_destroy_target_creature_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="destroy_target_creature_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def build_destroy_target_nonland_permanent_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_destroy_target_nonland_permanent_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_destroy_target_nonland_permanent_evidence",
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
        opponent = battle.Player("Opponent", None, [])
        target = {
            "name": "Problem Artifact",
            "cmc": 3,
            "type_line": "Artifact",
            "effect": "hate_artifact",
            "controller": opponent.name,
        }
        creature = {
            "name": "Small Creature",
            "cmc": 1,
            "type_line": "Creature",
            "effect": "creature",
            "power": 1,
            "toughness": 1,
            "controller": opponent.name,
        }
        land = {
            "name": "Basic Land",
            "type_line": "Basic Land",
            "effect": "land",
            "controller": opponent.name,
        }
        opponent.battlefield = [land, creature, target]
        spell = {
            "name": draft.card_name,
            "cmc": 3,
            "type_line": "Sorcery",
            "oracle_text": "Destroy target nonland permanent.",
            "tag": "removal",
            "effect": "remove_permanent",
            "target": "nonland_permanent",
            "_rule_source": "focused_battle_rule_evidence",
            "_rule_review_status": "needs_review",
        }
        battle.apply_effect_immediate(active, [opponent], spell, turn=4, rng=random.Random(13))
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler

    event_rows = _event_records(events, replay_id)
    decision_rows = _decision_records(decisions, replay_id)
    event_findings = replay_auditor.audit_turn_events(event_rows)
    decision_findings = replay_auditor.audit_decision_traces(decision_rows)
    findings = [*event_findings, *decision_findings]
    counts = _severity_counts(findings)

    removal_event = any(
        row.get("event") == "removal_resolved"
        and row.get("card") == draft.card_name
        and row.get("target") == "Problem Artifact"
        and row.get("target_legal") is True
        and row.get("target_is_creature") is False
        for row in event_rows
    )
    focused_passed = bool(
        removal_event
        and not any(card.get("name") == "Problem Artifact" for card in opponent.battlefield)
        and any(card.get("name") == "Problem Artifact" for card in opponent.graveyard)
        and any(card.get("name") == "Small Creature" for card in opponent.battlefield)
        and any(card.get("name") == "Basic Land" for card in opponent.battlefield)
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
            "removal_event": removal_event,
            "artifact_removed": not any(card.get("name") == "Problem Artifact" for card in opponent.battlefield),
            "artifact_in_graveyard": any(card.get("name") == "Problem Artifact" for card in opponent.graveyard),
            "creature_preserved": any(card.get("name") == "Small Creature" for card in opponent.battlefield),
            "land_preserved": any(card.get("name") == "Basic Land" for card in opponent.battlefield),
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "destroy_target_nonland_permanent",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: Destroy target nonland permanent.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_destroy_target_nonland_permanent_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="destroy_target_nonland_permanent_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def build_destroy_target_permanent_type_evidence(
    draft: DraftRecord,
    output_dir: Path,
    *,
    target_type: str,
    target_name: str,
    target_type_line: str,
    decoy_name: str,
    decoy_type_line: str,
    template_text: str,
) -> EvidenceResult:
    battle = load_module(
        f"battle_analyst_destroy_target_{target_type}_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        f"replay_decision_auditor_destroy_target_{target_type}_evidence",
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
        opponent = battle.Player("Opponent", None, [])
        target = {
            "name": target_name,
            "cmc": 3,
            "type_line": target_type_line,
            "effect": "engine",
            "controller": opponent.name,
        }
        decoy = {
            "name": decoy_name,
            "cmc": 2,
            "type_line": decoy_type_line,
            "effect": "decoy",
            "controller": opponent.name,
        }
        land = {
            "name": "Basic Land",
            "type_line": "Basic Land",
            "effect": "land",
            "controller": opponent.name,
        }
        opponent.battlefield = [land, decoy, target]
        spell = {
            "name": draft.card_name,
            "cmc": 2,
            "type_line": "Instant",
            "oracle_text": template_text,
            "tag": "removal",
            "effect": "remove_permanent",
            "target": target_type,
            "_rule_source": "focused_battle_rule_evidence",
            "_rule_review_status": "needs_review",
        }
        battle.apply_effect_immediate(active, [opponent], spell, turn=4, rng=random.Random(17))
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler

    event_rows = _event_records(events, replay_id)
    decision_rows = _decision_records(decisions, replay_id)
    event_findings = replay_auditor.audit_turn_events(event_rows)
    decision_findings = replay_auditor.audit_decision_traces(decision_rows)
    findings = [*event_findings, *decision_findings]
    counts = _severity_counts(findings)

    removal_event = any(
        row.get("event") == "removal_resolved"
        and row.get("card") == draft.card_name
        and row.get("target") == target_name
        and row.get("target_legal") is True
        and row.get("target_type") == target_type
        and row.get("target_is_creature") is False
        for row in event_rows
    )
    focused_passed = bool(
        removal_event
        and not any(card.get("name") == target_name for card in opponent.battlefield)
        and any(card.get("name") == target_name for card in opponent.graveyard)
        and any(card.get("name") == decoy_name for card in opponent.battlefield)
        and any(card.get("name") == "Basic Land" for card in opponent.battlefield)
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
            "removal_event": removal_event,
            "target_removed": not any(card.get("name") == target_name for card in opponent.battlefield),
            "target_in_graveyard": any(card.get("name") == target_name for card in opponent.graveyard),
            "decoy_preserved": any(card.get("name") == decoy_name for card in opponent.battlefield),
            "land_preserved": any(card.get("name") == "Basic Land" for card in opponent.battlefield),
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": f"destroy_target_{target_type}",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            f"Oracle text template: {template_text}",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": f"hard_behavior_destroy_target_{target_type}_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason=f"destroy_target_{target_type}_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def build_destroy_target_artifact_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    return build_destroy_target_permanent_type_evidence(
        draft,
        output_dir,
        target_type="artifact",
        target_name="Problem Artifact",
        target_type_line="Artifact",
        decoy_name="Problem Enchantment",
        decoy_type_line="Enchantment",
        template_text="Destroy target artifact.",
    )


def build_destroy_target_enchantment_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    return build_destroy_target_permanent_type_evidence(
        draft,
        output_dir,
        target_type="enchantment",
        target_name="Problem Enchantment",
        target_type_line="Enchantment",
        decoy_name="Problem Artifact",
        decoy_type_line="Artifact",
        template_text="Destroy target enchantment.",
    )


def build_destroy_all_creatures_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_destroy_all_creatures_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_destroy_all_creatures_evidence",
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
        opponent = battle.Player("Opponent", None, [])
        protected = {
            "name": "Protected Creature",
            "cmc": 2,
            "type_line": "Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "indestructible": True,
            "controller": active.name,
        }
        unprotected = {
            "name": "Friendly Creature",
            "cmc": 2,
            "type_line": "Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "controller": active.name,
        }
        threat_a = {
            "name": "Opponent Threat A",
            "cmc": 4,
            "type_line": "Creature",
            "effect": "creature",
            "power": 4,
            "toughness": 4,
            "controller": opponent.name,
        }
        threat_b = {
            "name": "Opponent Threat B",
            "cmc": 3,
            "type_line": "Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "controller": opponent.name,
        }
        rock = {
            "name": "Mana Rock",
            "cmc": 2,
            "type_line": "Artifact",
            "effect": "ramp_permanent",
        }
        active.battlefield = [protected, unprotected, rock]
        opponent.battlefield = [threat_a, threat_b]
        spell = {
            "name": draft.card_name,
            "cmc": 4,
            "type_line": "Sorcery",
            "effect": "board_wipe",
            "_rule_source": "focused_battle_rule_evidence",
            "_rule_review_status": "needs_review",
        }
        battle.apply_effect_immediate(active, [opponent], spell, turn=5, rng=random.Random(12))
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler

    event_rows = _event_records(events, replay_id)
    decision_rows = _decision_records(decisions, replay_id)
    event_findings = replay_auditor.audit_turn_events(event_rows)
    decision_findings = replay_auditor.audit_decision_traces(decision_rows)
    findings = [*event_findings, *decision_findings]
    counts = _severity_counts(findings)

    wipe_event = next(
        (
            row
            for row in event_rows
            if row.get("event") == "board_wipe_resolved"
            and row.get("card") == draft.card_name
        ),
        None,
    )
    decision_event = any(
        row.get("decision_type") == "board_wipe"
        and row.get("chosen_option", {}).get("card") == draft.card_name
        for row in decision_rows
    )
    focused_passed = bool(
        wipe_event
        and decision_event
        and wipe_event.get("destroyed") == 3
        and wipe_event.get("protected") == 1
        and any(card.get("name") == "Protected Creature" for card in active.battlefield)
        and any(card.get("name") == "Mana Rock" for card in active.battlefield)
        and not any(card.get("name") == "Friendly Creature" for card in active.battlefield)
        and not opponent.battlefield
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
            "wipe_event": bool(wipe_event),
            "decision_trace": decision_event,
            "destroyed": wipe_event.get("destroyed") if wipe_event else None,
            "protected": wipe_event.get("protected") if wipe_event else None,
            "protected_creature_survived": any(card.get("name") == "Protected Creature" for card in active.battlefield),
            "noncreature_preserved": any(card.get("name") == "Mana Rock" for card in active.battlefield),
            "opponent_board_empty": not opponent.battlefield,
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "destroy_all_creatures",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: Destroy all creatures.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_destroy_all_creatures_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="destroy_all_creatures_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def build_creatures_indestructible_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_creatures_indestructible_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_creatures_indestructible_evidence",
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
        defender = battle.Player("Defender", None, [], is_human=True)
        defender.hand = [
            {
                "name": draft.card_name,
                "cmc": 1,
                "mana_cost": "{W}",
                "tag": "protection",
                "effect": "indestructible",
                "type_line": "Instant",
                "color_identity": ["W"],
                "_rule_source": "focused_battle_rule_evidence",
                "_rule_review_status": "needs_review",
            }
        ]
        defender.mana_pool.add("white", 1)
        defender.battlefield = [
            {
                "name": "Defender Creature A",
                "cmc": 2,
                "type_line": "Creature",
                "effect": "creature",
                "power": 2,
                "toughness": 2,
                "controller": defender.name,
            },
            {
                "name": "Defender Creature B",
                "cmc": 3,
                "type_line": "Creature",
                "effect": "creature",
                "power": 3,
                "toughness": 3,
                "controller": defender.name,
            },
        ]
        active.battlefield = [
            {
                "name": "Active Threat",
                "cmc": 4,
                "type_line": "Creature",
                "effect": "creature",
                "power": 4,
                "toughness": 4,
                "controller": active.name,
            }
        ]
        board_wipe = {
            "name": "Test Board Wipe",
            "cmc": 4,
            "type_line": "Sorcery",
            "effect": "board_wipe",
        }
        stack = battle.Stack()
        stack.push(board_wipe, active, battle.get_card_effect(board_wipe))

        first_priority = battle.priority_round(
            active,
            [active, defender],
            stack,
            4,
            random.Random(18),
            phase="precombat_main",
        )
        second_priority = battle.priority_round(
            active,
            [active, defender],
            stack,
            4,
            random.Random(18),
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

    protection_response = any(
        row.get("decision_type") == "response"
        and row.get("chosen_option", {}).get("card") == draft.card_name
        and row.get("actual_outcome") == "protective_response_cast"
        for row in decision_rows
    )
    protection_cast = any(
        row.get("event") == "spell_cast"
        and row.get("card") == draft.card_name
        and row.get("role") == "response"
        and row.get("response_to") == "Test Board Wipe"
        for row in event_rows
    )
    wipe_event = next(
        (
            row
            for row in event_rows
            if row.get("event") == "board_wipe_resolved"
            and row.get("card") == "Test Board Wipe"
        ),
        None,
    )
    defender_creatures = [
        card.get("name")
        for card in defender.battlefield
        if isinstance(card, dict) and battle.is_battlefield_creature(card)
    ]
    protection_spent = bool(defender.graveyard) and defender.graveyard[0].get("name") == draft.card_name
    focused_passed = bool(
        first_priority
        and not second_priority
        and protection_response
        and protection_cast
        and protection_spent
        and wipe_event
        and wipe_event.get("destroyed") == 1
        and wipe_event.get("protected") == 2
        and sorted(defender_creatures) == ["Defender Creature A", "Defender Creature B"]
        and not active.battlefield
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
            "first_priority_protected": bool(first_priority),
            "second_priority_resolved_stack": not bool(second_priority),
            "protection_response_decision": protection_response,
            "protection_cast_event": protection_cast,
            "protection_card_spent": protection_spent,
            "destroyed": wipe_event.get("destroyed") if wipe_event else None,
            "protected": wipe_event.get("protected") if wipe_event else None,
            "defender_creatures_survived": sorted(defender_creatures),
            "active_board_empty": not active.battlefield,
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "creatures_gain_indestructible_against_board_wipe",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: Creatures you control gain indestructible until end of turn.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_creatures_indestructible_until_eot_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="creatures_indestructible_until_eot_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def build_sacrifice_damage_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_sacrifice_damage_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_sacrifice_damage_evidence",
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
        opponent = battle.Player("Opponent", None, [])
        opponent.life = 3
        token = battle.create_creature_token(
            active,
            name="Goblin Token",
            power=1,
            toughness=1,
        )
        outlet = {
            "name": draft.card_name,
            "cmc": 2,
            "type_line": "Enchantment",
            "effect": "sacrifice_damage_outlet",
            "activated_sacrifice_creature_damage": True,
            "damage": 1,
            "_rule_source": "focused_battle_rule_evidence",
            "_rule_review_status": "needs_review",
        }
        active.battlefield.append(outlet)
        activations = battle.activate_sacrifice_damage_outlets(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(7),
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

    activation_event = any(
        row.get("event") == "activated_ability"
        and row.get("card") == draft.card_name
        and row.get("activation_kind") == "sacrifice_creature_damage"
        and row.get("sacrificed") == "Goblin Token"
        and row.get("target") == "Opponent"
        and row.get("damage_dealt") == 1
        for row in event_rows
    )
    decision_event = any(
        row.get("decision_type") == "activated_sacrifice_damage"
        and row.get("chosen_option", {}).get("card") == "Goblin Token"
        for row in decision_rows
    )
    focused_passed = bool(
        activations == 1
        and opponent.life == 2
        and token not in active.battlefield
        and token not in active.graveyard
        and activation_event
        and decision_event
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
            "activation_count": activations,
            "activation_event": activation_event,
            "decision_trace": decision_event,
            "token_left_battlefield": token not in active.battlefield,
            "token_not_in_graveyard": token not in active.graveyard,
            "opponent_life_after": opponent.life,
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "activated_sacrifice_creature_damage",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: Sacrifice a creature: deals damage to any target.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_activated_sacrifice_creature_damage_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="activated_sacrifice_creature_damage_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def build_extra_combat_flashback_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_extra_combat_flashback_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_extra_combat_flashback_evidence",
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
        opponent = battle.Player("Opponent", None, [])
        attacker = {
            "name": "Combat Creature",
            "cmc": 2,
            "type_line": "Creature",
            "effect": "creature",
            "power": 3,
            "toughness": 3,
            "tapped": True,
            "summoning_sick": False,
        }
        spell = {
            "name": draft.card_name,
            "cmc": 4,
            "type_line": "Sorcery",
            "effect": "extra_combat",
            "combats": 1,
            "extra_combats": 1,
            "untap_creatures": True,
            "flashback_cost": "{2}{R}",
            "_rule_source": "focused_battle_rule_evidence",
            "_rule_review_status": "needs_review",
        }
        active.battlefield = [
            attacker,
            {"name": "Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
            {"name": "Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
            {"name": "Mountain", "type_line": "Basic Land - Mountain", "effect": "land"},
        ]
        active.refresh_mana_sources(turn=4)
        battle.apply_effect_immediate(active, [opponent], spell, turn=4, rng=random.Random(8))
        hand_resolution_ok = active.extra_combats == 1 and attacker.get("tapped") is False

        flashback_card = next((card for card in active.graveyard if card.get("name") == draft.card_name), None)
        stack = battle.Stack()
        flashback_cast = bool(
            flashback_card
            and battle.cast_flashback_spell_from_graveyard(
                active,
                flashback_card,
                [opponent],
                [active, opponent],
                turn=5,
                phase="precombat_main",
                stack=stack,
                rng=random.Random(9),
            )
        )
        item = stack.resolve_top()
        if item:
            battle.apply_effect_immediate(active, [opponent], item.card, turn=5, rng=random.Random(9))
        flashback_exiled = any(card.get("name") == draft.card_name and card.get("_flashback_cast") for card in active.exile)
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_event_handler
        battle.DECISION_TRACE_HANDLER = previous_decision_handler

    event_rows = _event_records(events, replay_id)
    decision_rows = _decision_records(decisions, replay_id)
    event_findings = replay_auditor.audit_turn_events(event_rows)
    decision_findings = replay_auditor.audit_decision_traces(decision_rows)
    findings = [*event_findings, *decision_findings]
    counts = _severity_counts(findings)

    extra_combat_events = [
        row
        for row in event_rows
        if row.get("event") == "extra_combat_scheduled"
        and row.get("card") == draft.card_name
    ]
    flashback_event = any(
        row.get("event") == "flashback_cast" and row.get("card") == draft.card_name
        for row in event_rows
    )
    focused_passed = bool(
        hand_resolution_ok
        and flashback_cast
        and flashback_exiled
        and len(extra_combat_events) >= 2
        and active.extra_combats >= 2
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
            "hand_resolution_extra_combat": hand_resolution_ok,
            "flashback_cast": flashback_cast,
            "flashback_exiled": flashback_exiled,
            "extra_combat_event_count": len(extra_combat_events),
            "extra_combats_pending": active.extra_combats,
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "extra_combat_flashback",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: additional combat phase plus flashback.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_extra_combat_flashback_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="extra_combat_flashback_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def build_attack_artifact_tutor_evidence(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    battle = load_module(
        "battle_analyst_attack_artifact_tutor_evidence",
        HERMES_SCRIPTS_DIR / "battle_analyst_v9.py",
    )
    replay_auditor = load_module(
        "replay_decision_auditor_attack_artifact_tutor_evidence",
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
        active = battle.Player("Active", None, [], strategy="midrange")
        opponent = battle.Player("Opponent", None, [], strategy="midrange")
        source = {
            "name": draft.card_name,
            "cmc": 4,
            "type_line": "Legendary Artifact Creature — Human Hero",
            "oracle_text": draft.draft.get("oracle_text_excerpt"),
            "effect": "attack_artifact_tutor",
            "artifact_attack_tutor": True,
            "artifact_tutor_cmc_mode": "sacrificed_mana_value_plus",
            "artifact_tutor_sacrifice_noncreature": True,
            "artifact_tutor_enters_tapped": True,
            "attack_trigger": True,
            "power": 4,
            "toughness": 4,
            "summoning_sick": False,
            "tapped": False,
            "_rule_source": "focused_battle_rule_evidence",
            "_rule_review_status": "needs_review",
        }
        active.battlefield = [
            source,
        ]
        active.library = [
            {
                "name": "Sol Ring",
                "cmc": 1,
                "type_line": "Artifact",
                "effect": "ramp_permanent",
                "mana_produced": 2,
            },
            {
                "name": "High Cost Artifact",
                "cmc": 5,
                "type_line": "Artifact",
                "effect": "finisher",
            },
        ]
        opponent.life = 40
        battle.combat_phase_v8(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            rng=random.Random(10),
            stack=battle.Stack(),
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

    trigger_event = any(
        row.get("event") == "trigger_resolved"
        and row.get("card") == draft.card_name
        and row.get("activation_kind") == "artifact_attack_tutor"
        and row.get("artifact_sacrificed") == "Treasure token"
        and row.get("found") == "Sol Ring"
        and row.get("destination") == "battlefield"
        and row.get("target_cmc") == 1
        and row.get("cmc_match") == "exact"
        and row.get("enters_tapped") is True
        for row in event_rows
    )
    decision_event = any(
        row.get("decision_type") == "attack_trigger_artifact_tutor"
        and row.get("chosen_option", {}).get("target") == "Sol Ring"
        for row in decision_rows
    )
    focused_passed = bool(
        trigger_event
        and decision_event
        and any(card.get("name") == "Sol Ring" and card.get("tapped") is True for card in active.battlefield)
        and not any(card.get("name") == "Sol Ring" for card in active.library)
        and active.treasures == 0
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
            "trigger_event": trigger_event,
            "decision_trace": decision_event,
            "artifact_tutored_to_battlefield": any(card.get("name") == "Sol Ring" for card in active.battlefield),
            "artifact_entered_tapped": any(card.get("name") == "Sol Ring" and card.get("tapped") is True for card in active.battlefield),
            "treasure_sacrificed": active.treasures == 0,
            "critical_findings": counts.get("critical", 0),
            "high_findings": counts.get("high", 0),
        },
        "scope": "attack_trigger_artifact_tutor",
    }
    focused_path.write_text(json.dumps(focused_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    evidence = {
        "source_review_run_id": draft.run_id,
        "official_source_reviewed": True,
        "official_sources": [
            f"Scryfall oracle text for oracle_id:{draft.oracle_id}",
            "Oracle text template: attack trigger creates Treasure, may sacrifice noncreature artifact, artifact tutor with mana value one greater to battlefield tapped.",
        ],
        "focused_test_passed": focused_passed,
        "focused_test_refs": [str(focused_path)],
        "replay_audit_passed": counts.get("critical", 0) == 0 and counts.get("high", 0) == 0,
        "replay_audit_refs": [str(audit_path), str(events_path), str(decisions_path)],
        "critical_findings": counts.get("critical", 0),
        "high_findings": counts.get("high", 0),
        "evidence_scope": "hard_behavior_attack_trigger_artifact_tutor_v1",
        "generated_by": "manaloom_battle_rule_focused_evidence",
    }
    return EvidenceResult(
        draft=draft,
        status="evidence_ready" if focused_passed else "evidence_failed",
        reason="attack_trigger_artifact_tutor_supported",
        evidence=evidence,
        artifacts=[str(focused_path), str(audit_path), str(events_path), str(decisions_path)],
    )


def evaluate_draft(draft: DraftRecord, output_dir: Path) -> EvidenceResult:
    if supports_counterspell_template(draft):
        return build_counterspell_evidence(draft, output_dir)
    if supports_destroy_target_creature_template(draft):
        return build_destroy_target_creature_evidence(draft, output_dir)
    if supports_destroy_target_nonland_permanent_template(draft):
        return build_destroy_target_nonland_permanent_evidence(draft, output_dir)
    if supports_destroy_target_artifact_template(draft):
        return build_destroy_target_artifact_evidence(draft, output_dir)
    if supports_destroy_target_enchantment_template(draft):
        return build_destroy_target_enchantment_evidence(draft, output_dir)
    if supports_destroy_all_creatures_template(draft):
        return build_destroy_all_creatures_evidence(draft, output_dir)
    if supports_creatures_indestructible_template(draft):
        return build_creatures_indestructible_evidence(draft, output_dir)
    if supports_sacrifice_damage_template(draft):
        return build_sacrifice_damage_evidence(draft, output_dir)
    if supports_extra_combat_flashback_template(draft):
        return build_extra_combat_flashback_evidence(draft, output_dir)
    if supports_attack_artifact_tutor_template(draft):
        return build_attack_artifact_tutor_evidence(draft, output_dir)
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
