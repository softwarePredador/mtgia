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
import ssl
import sys
import urllib.error
import urllib.request
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
    "sacrifice_outlet": "activated_sacrifice_creature_damage",
    "token": "token_or_board_presence",
    "tutor": "library_search_or_selection",
    "wincon": "win_condition",
}

EFFECT_FAMILY_KEY_PRIORITY = [
    "attack_trigger_artifact_tutor",
    "activated_sacrifice_creature_damage",
    "extra_combat_phase",
    "graveyard_recast_replacement",
    "graveyard_or_zone_recursion",
    "counterspell_stack_interaction",
    "mass_removal_or_modal_wipe",
    "targeted_interaction",
    "protection_or_prevention",
    "mana_or_resource_acceleration",
    "treasure_resource_generation",
    "library_search_or_selection",
    "triggered_or_static_engine",
    "copy_spell_or_permanent",
    "card_advantage_or_selection",
    "counter_manipulation",
    "token_or_board_presence",
    "synergy_enabler",
    "synergy_payoff",
    "win_condition",
]


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
    if (
        "whenever" in text
        and "attacks" in text
        and "sacrifice" in text
        and "artifact" in text
        and "search your library" in text
    ):
        families.add("attack_trigger_artifact_tutor")
    if (
        "sacrifice a creature:" in text
        and (
            "damage to any target" in text
            or "damage to target" in text
            or "deals 1 damage" in text
        )
    ):
        families.add("activated_sacrifice_creature_damage")
    if "draw a card" in text or "draw cards" in text:
        families.add("card_advantage_or_selection")
    if "destroy all" in text or "exile all" in text:
        families.add("mass_removal_or_modal_wipe")
    if "destroy target" in text or "exile target" in text or "damage to target" in text:
        families.add("targeted_interaction")
    if (
        "gain indestructible until end of turn" in text
        or "prevent all damage" in text
        or "protection from" in text
    ):
        families.add("protection_or_prevention")
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
    card_id: str
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
    llm_review: dict[str, Any] | None = None

    @property
    def draft_rule_key(self) -> str:
        key_hint = self.primary_effect_family
        if not key_hint:
            key_hint = unique_sorted(self.roles)[0] if self.roles else "review"
        return f"{normalize_name(self.card_name)}__{normalize_name(key_hint)}__draft_v1"

    @property
    def effect_families(self) -> list[str]:
        from_roles = [ROLE_TO_EFFECT_FAMILY.get(role, role) for role in self.roles]
        from_text = infer_effect_families_from_text(str(self.payload.get("oracle_text") or ""))
        return unique_sorted([*from_roles, *from_text])

    @property
    def primary_effect_family(self) -> str | None:
        families = set(self.effect_families)
        for family in EFFECT_FAMILY_KEY_PRIORITY:
            if family in families:
                return family
        return unique_sorted(families)[0] if families else None

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

    def to_json(self, *, include_llm: bool = True) -> dict[str, Any]:
        payload = {
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
        if include_llm and self.llm_review is not None:
            payload["llm_review"] = self.llm_review
        return payload


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


def table_columns(conn: sqlite3.Connection, name: str) -> set[str]:
    if not table_exists(conn, name):
        return set()
    return {str(row[1]) for row in conn.execute(f"PRAGMA table_info({name})").fetchall()}


def load_queue_rows(conn: sqlite3.Connection, limit: int) -> list[QueueRow]:
    if not table_exists(conn, "new_card_battle_rule_review_queue"):
        return []
    queue_columns = table_columns(conn, "new_card_battle_rule_review_queue")
    review_columns = table_columns(conn, "new_card_candidate_reviews")
    queue_card_id_expr = (
        "q.card_id"
        if "card_id" in queue_columns
        else "COALESCE(q.oracle_id, q.card_name)"
    )
    card_id_join = "AND r.card_id = q.card_id" if "card_id" in queue_columns and "card_id" in review_columns else ""
    limit_clause = "" if limit <= 0 else "LIMIT ?"
    params: tuple[int, ...] = () if limit <= 0 else (limit,)
    rows = conn.execute(
        f"""
        SELECT
            q.commander_name,
            {queue_card_id_expr} AS card_id,
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
           {card_id_join}
           AND r.card_name = q.card_name
           AND COALESCE(r.set_code, '') = COALESCE(q.set_code, '')
        ORDER BY COALESCE(r.score, 0) DESC, q.card_name, q.commander_name
        {limit_clause}
        """,
        params,
    ).fetchall()
    return [
        QueueRow(
            commander_name=str(row[0]),
            card_id=str(row[1] or ""),
            card_name=str(row[2]),
            oracle_id=str(row[3]) if row[3] else None,
            set_code=str(row[4] or ""),
            roles=[str(item) for item in parse_json(row[5], [])],
            reason=str(row[6] or ""),
            latest_run_id=str(row[7] or ""),
            candidate_score=int(row[8] or 0),
            candidate_reasons=[str(item) for item in parse_json(row[9], [])],
            payload=parse_json(row[10], {}),
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


def env_truthy(name: str, default: str = "0") -> bool:
    return os.environ.get(name, default).strip().lower() in {"1", "true", "yes", "y", "on"}


def extract_response_text(response: dict[str, Any]) -> str:
    output_text = response.get("output_text")
    if isinstance(output_text, str) and output_text.strip():
        return output_text.strip()

    parts: list[str] = []
    for item in response.get("output", []) if isinstance(response.get("output"), list) else []:
        if not isinstance(item, dict):
            continue
        content = item.get("content")
        if not isinstance(content, list):
            continue
        for content_item in content:
            if not isinstance(content_item, dict):
                continue
            text = content_item.get("text")
            if isinstance(text, str) and text.strip():
                parts.append(text.strip())
    return "\n".join(parts).strip()


def bounded_text(value: Any, *, limit: int = 2000) -> str:
    text = str(value or "").strip()
    if len(text) <= limit:
        return text
    return text[: limit - 3].rstrip() + "..."


def normalize_llm_review(raw_text: str, *, model: str) -> dict[str, Any]:
    try:
        parsed = json.loads(raw_text)
    except Exception:
        parsed = {
            "summary": "OpenAI response was not valid JSON.",
            "raw_text_excerpt": bounded_text(raw_text, limit=1200),
        }
    if not isinstance(parsed, dict):
        parsed = {
            "summary": "OpenAI response JSON was not an object.",
            "raw_text_excerpt": bounded_text(raw_text, limit=1200),
        }
    parsed.setdefault("summary", "")
    parsed.setdefault("recommended_status", "needs_review")
    parsed["recommended_status"] = "needs_review"
    parsed["status"] = "completed"
    parsed["model"] = model
    parsed["safety"] = [
        "llm_review_only",
        "no_postgres_write",
        "no_verified_promotion",
        "manual_gate_required",
    ]
    return parsed


def openai_ssl_context() -> ssl.SSLContext:
    try:
        import certifi  # type: ignore

        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


def call_openai_review(
    draft: RuleDraft,
    *,
    api_key: str,
    model: str,
    timeout: int,
) -> dict[str, Any]:
    draft_payload = draft.to_json(include_llm=False)
    instructions = (
        "You are reviewing ManaLoom battle-rule draft candidates for Magic: The Gathering. "
        "Return a single JSON object only. Do not promote anything to verified. "
        "Use the provided oracle text and metadata only; do not invent official rulings. "
        "If official source review is needed, say so. Keep recommendations report-only."
    )
    user_payload = {
        "task": "review_needs_rule_review_draft",
        "required_json_keys": [
            "summary",
            "risk_assessment",
            "official_sources_needed",
            "suggested_test_cases",
            "implementation_notes",
            "recommended_status",
        ],
        "draft": draft_payload,
        "hard_constraints": [
            "recommended_status must remain needs_review",
            "do not suggest automatic verification",
            "do not suggest PostgreSQL writes",
            "do not suggest hard battle execution before focused tests",
        ],
    }
    request_payload = {
        "model": model,
        "input": [
            {"role": "developer", "content": instructions},
            {"role": "user", "content": json.dumps(user_payload, sort_keys=True)},
        ],
        "temperature": 0,
        "max_output_tokens": 900,
        "text": {"format": {"type": "json_object"}},
    }
    request = urllib.request.Request(
        "https://api.openai.com/v1/responses",
        data=json.dumps(request_payload).encode("utf-8"),
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(
            request,
            timeout=timeout,
            context=openai_ssl_context(),
        ) as response:
            response_payload = json.loads(response.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        raise RuntimeError(f"OpenAI HTTP {exc.code}: {bounded_text(body, limit=800)}") from exc
    raw_text = extract_response_text(response_payload)
    return normalize_llm_review(raw_text, model=model)


def apply_llm_reviews(drafts: list[RuleDraft], args: argparse.Namespace) -> dict[str, Any]:
    limit = max(0, int(args.llm_limit or 0))
    target_drafts = drafts[:limit]
    summary = {
        "enabled": bool(args.llm_review),
        "model": args.llm_model if args.llm_review else None,
        "limit": limit,
        "attempted": 0,
        "completed": 0,
        "skipped": 0,
        "errors": 0,
        "status": "disabled",
    }
    if not args.llm_review:
        return summary
    summary["status"] = "enabled"
    if not target_drafts:
        summary["status"] = "skipped_no_drafts"
        return summary
    api_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not api_key:
        summary["status"] = "skipped_missing_openai_api_key"
        summary["skipped"] = len(target_drafts)
        for draft in target_drafts:
            draft.llm_review = {
                "status": "skipped_missing_openai_api_key",
                "model": args.llm_model,
                "safety": [
                    "llm_review_only",
                    "no_postgres_write",
                    "no_verified_promotion",
                    "manual_gate_required",
                ],
            }
        return summary

    for draft in target_drafts:
        summary["attempted"] += 1
        try:
            draft.llm_review = call_openai_review(
                draft,
                api_key=api_key,
                model=args.llm_model,
                timeout=args.llm_timeout,
            )
            summary["completed"] += 1
        except Exception as exc:
            draft.llm_review = {
                "status": "error",
                "model": args.llm_model,
                "error_type": type(exc).__name__,
                "error": bounded_text(str(exc), limit=800),
                "safety": [
                    "llm_review_only",
                    "no_postgres_write",
                    "no_verified_promotion",
                    "manual_gate_required",
                ],
            }
            summary["errors"] += 1
    if summary["errors"]:
        summary["status"] = "completed_with_errors"
    else:
        summary["status"] = "completed"
    return summary


def summarize(
    run_id: str,
    generated_at: str,
    queue_rows: list[QueueRow],
    drafts: list[RuleDraft],
    *,
    llm_review: dict[str, Any] | None = None,
) -> dict[str, Any]:
    confidence_counts: dict[str, int] = {}
    effect_counts: dict[str, int] = {}
    for draft in drafts:
        confidence_counts[draft.confidence] = confidence_counts.get(draft.confidence, 0) + 1
        for family in draft.effect_families:
            effect_counts[family] = effect_counts.get(family, 0) + 1
    notes = [
        "report_only_no_pg_writes",
        "drafts_remain_needs_review",
        "no_verified_promotion",
        "no_hard_battle_behavior",
    ]
    if llm_review and llm_review.get("enabled"):
        notes.append("llm_review_optional_report_only")
    else:
        notes.append("no_llm_used")
    return {
        "run_id": run_id,
        "generated_at": generated_at,
        "mode": "sqlite_operational_cache",
        "dry_run": True,
        "queue_rows": len(queue_rows),
        "draft_count": len(drafts),
        "confidence_counts": confidence_counts,
        "effect_family_counts": effect_counts,
        "llm_review": llm_review or {
            "enabled": False,
            "model": None,
            "limit": 0,
            "attempted": 0,
            "completed": 0,
            "skipped": 0,
            "errors": 0,
            "status": "disabled",
        },
        "notes": notes,
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
    llm_review = summary.get("llm_review") or {}
    lines.extend(
        [
            "",
            "## Optional LLM Review",
            "",
            f"- Enabled: `{str(bool(llm_review.get('enabled'))).lower()}`",
            f"- Status: `{llm_review.get('status', 'disabled')}`",
            f"- Model: `{llm_review.get('model') or 'n/a'}`",
            f"- Completed: `{llm_review.get('completed', 0)}`",
            f"- Errors: `{llm_review.get('errors', 0)}`",
            "",
        ]
    )
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
    parser.set_defaults(llm_review=env_truthy("MANALOOM_BATTLE_RULE_LLM_REVIEW", "0"))
    parser.add_argument("--llm-review", action="store_true", dest="llm_review")
    parser.add_argument("--no-llm-review", action="store_false", dest="llm_review")
    parser.add_argument(
        "--llm-model",
        default=os.environ.get("MANALOOM_BATTLE_RULE_LLM_MODEL", "gpt-4o-mini"),
    )
    parser.add_argument(
        "--llm-limit",
        type=int,
        default=int(os.environ.get("MANALOOM_BATTLE_RULE_LLM_LIMIT", "3")),
    )
    parser.add_argument(
        "--llm-timeout",
        type=int,
        default=int(os.environ.get("MANALOOM_BATTLE_RULE_LLM_TIMEOUT", "30")),
    )
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
        llm_summary = apply_llm_reviews([], args)
        summary = summarize(run_id, generated_at, [], [], llm_review=llm_summary)
        summary["blocked_reason"] = "knowledge_db_missing"
        write_artifacts(output_dir, run_id, summary, [])
        print("MANALOOM_BATTLE_RULE_REVIEW_QUEUE " + json.dumps(summary, sort_keys=True))
        return summary

    conn = sqlite3.connect(db_path)
    try:
        ensure_schema(conn)
        rows = load_queue_rows(conn, args.limit)
        drafts = aggregate(rows)
        llm_summary = apply_llm_reviews(drafts, args)
        summary = summarize(run_id, generated_at, rows, drafts, llm_review=llm_summary)
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
