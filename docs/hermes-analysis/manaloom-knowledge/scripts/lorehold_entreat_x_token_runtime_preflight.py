#!/usr/bin/env python3
"""Preflight the Entreat X-token runtime primitive before any deck gate."""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_RUNTIME = SCRIPT_DIR / "battle_analyst_v9.py"
DEFAULT_TEST = SCRIPT_DIR / "test_xmage_exact_scope_runtime.py"
DEFAULT_CONTRACT_REPORT = (
    REPORT_DIR / "lorehold_brain_entreat_haze_runtime_contract_20260705_post_authorized_full_validation.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_entreat_x_token_runtime_preflight_20260705_current"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_name(name: str) -> str:
    return " ".join(str(name or "").strip().lower().replace("’", "'").split())


def active_rule_rows(db_path: Path, card_name: str) -> list[dict[str, Any]]:
    if not db_path.exists():
        return []
    normalized = normalize_name(card_name)
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            (
                "SELECT normalized_name, card_name, logical_rule_key, effect_json, "
                "review_status, execution_status, source "
                "FROM battle_card_rules "
                "WHERE normalized_name = ? OR lower(card_name) = ?"
            ),
            [normalized, card_name.lower()],
        ).fetchall()
    out = []
    for row in rows:
        data = dict(row)
        try:
            effect_json = json.loads(data.get("effect_json") or "{}")
        except json.JSONDecodeError:
            effect_json = {}
        data["effect"] = effect_json.get("effect")
        data["battle_model_scope"] = effect_json.get("battle_model_scope")
        out.append(data)
    return out


def runtime_checks(runtime_text: str) -> dict[str, bool]:
    return {
        "x_value_helper": "def x_value_from_effect_context" in runtime_text,
        "token_count_uses_x_value": "token_count_source" in runtime_text and "x_value_from_effect_context(effect_data)" in runtime_text,
        "token_count_per_x_guard": "token_count_per_x" in runtime_text,
        "cast_planner_uses_x_token_count": (
            "def effect_uses_x_cast_value" in runtime_text
            and "uses_x_cast_value = effect_uses_x_cast_value(effect_data)" in runtime_text
            and "str(effect_data.get(\"token_count_source\") or \"\").strip().lower() == \"x_value\"" in runtime_text
        ),
        "native_x_miracle_cast_plan": (
            "def miracle_cast_plan_for_card" in runtime_text
            and "def native_miracle_cost_for_effect" in runtime_text
            and "\"alternative_cost_kind\": \"native_miracle\"" in runtime_text
        ),
        "tokens_created_replay_source": "token_count_source=effect_data.get(\"token_count_source\")" in runtime_text,
        "tokens_created_replay_x_value": "x_value_from_effect_context(effect_data)" in runtime_text and "tokens_created" in runtime_text,
    }


def test_checks(test_text: str) -> dict[str, bool]:
    return {
        "focused_test_exists": "test_x_create_creature_tokens_spell_uses_cast_context_x_value" in test_text,
        "entreat_fixture": "Entreat the Angels" in test_text,
        "x_value_fixture": "\"_cast_context\": {\"x_value\": 3}" in test_text,
        "angel_token_model": "Angel Token" in test_text and "token_flying" in test_text,
        "xx_cost_plan_test": "test_x_create_creature_tokens_spell_cast_plan_uses_xx_cost" in test_text,
        "native_x_miracle_test": "test_native_x_miracle_create_creature_tokens_uses_xww_cost" in test_text,
        "replay_assertion": "tokens_requested" in test_text and "token_count_source" in test_text,
    }


def build_payload(
    *,
    db_path: Path,
    runtime_path: Path,
    test_path: Path,
    contract_report_path: Path,
) -> dict[str, Any]:
    runtime_text = read_text(runtime_path)
    test_text = read_text(test_path)
    runtime = runtime_checks(runtime_text)
    tests = test_checks(test_text)
    rules = active_rule_rows(db_path, "Entreat the Angels")
    contract_report = read_json(contract_report_path)
    runtime_primitive_ready = all(runtime.values()) and all(tests.values())
    active_rule_ready = any(
        row.get("review_status") in {"verified", "active"}
        and row.get("execution_status") in {"auto", "executable"}
        for row in rules
    )
    if runtime_primitive_ready and active_rule_ready:
        status = "entreat_x_token_runtime_and_rule_ready_cut_still_blocked_keep_607"
        recommended_next_action = "mine_entreat_named_same_lane_safe_cut_before_matrix_or_battle"
        reason = (
            "The generic X token runtime primitive is present, focused Entreat tests cover "
            "normal and native miracle X-token casting, and Entreat has a reviewed active "
            "ManaLoom rule. Deck action is still blocked until a named same-lane safe cut "
            "and later natural battle gate exist."
        )
    elif runtime_primitive_ready:
        status = "entreat_x_token_runtime_primitive_ready_rule_still_blocked_keep_607"
        recommended_next_action = "apply_entreat_rule_only_after_pg_precheck_then_run_607_battle_gate"
        reason = (
            "The generic X token runtime primitive is present and covered by a focused "
            "Entreat-style fixture, but Entreat still has no reviewed active card rule and "
            "has not passed a natural battle gate against protected deck 607."
        )
    else:
        status = "entreat_x_token_runtime_primitive_incomplete_keep_607"
        recommended_next_action = "complete_entreat_x_token_runtime_before_rule_or_deck_gate"
        reason = (
            "The Entreat X-token runtime primitive is incomplete, so no rule, matrix, battle, "
            "or deck action is allowed."
        )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_entreat_x_token_runtime_preflight",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": {
            "brain_entreat_haze_contract": rel(contract_report_path),
        },
        "source_files": {
            "runtime": rel(runtime_path),
            "focused_test": rel(test_path),
        },
        "status": status,
        "summary": {
            "current_baseline": "deck_607",
            "runtime_primitive_ready": runtime_primitive_ready,
            "entreat_active_rule_count": len(rules),
            "entreat_active_rule_ready": active_rule_ready,
            "battle_ready_now_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "recommended_next_action": recommended_next_action,
        },
        "prior_contract_status": contract_report.get("status"),
        "prior_contract_best_first": (contract_report.get("summary") or {}).get("best_first_runtime_contract"),
        "runtime_checks": runtime,
        "test_checks": tests,
        "entreat_active_rules": rules,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "reason": reason,
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Entreat X-Token Runtime Preflight",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- Deck 607 mutated: `{payload['deck_607_mutated']}`",
        f"- Prior best first runtime contract: `{payload.get('prior_contract_best_first')}`",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in [
        "runtime_primitive_ready",
        "entreat_active_rule_count",
        "entreat_active_rule_ready",
        "battle_ready_now_count",
        "natural_battle_allowed_now",
        "promotion_allowed",
    ]:
        lines.append(f"| `{key}` | `{summary[key]}` |")
    lines.extend(["", "## Runtime Checks", "", "| Check | Pass |", "| --- | ---: |"])
    for key, value in payload["runtime_checks"].items():
        lines.append(f"| `{key}` | `{value}` |")
    lines.extend(["", "## Test Checks", "", "| Check | Pass |", "| --- | ---: |"])
    for key, value in payload["test_checks"].items():
        lines.append(f"| `{key}` | `{value}` |")
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{payload['decision']['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{payload['decision']['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{payload['decision']['promotion_allowed']}`",
            f"- Recommended next action: `{summary['recommended_next_action']}`",
            f"- Reason: {payload['decision']['reason']}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--runtime", type=Path, default=DEFAULT_RUNTIME)
    parser.add_argument("--test", type=Path, default=DEFAULT_TEST)
    parser.add_argument("--contract-report", type=Path, default=DEFAULT_CONTRACT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        db_path=args.db,
        runtime_path=args.runtime,
        test_path=args.test,
        contract_report_path=args.contract_report,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "runtime_primitive_ready": payload["summary"]["runtime_primitive_ready"],
                "battle_ready_now_count": payload["summary"]["battle_ready_now_count"],
            },
            ensure_ascii=True,
        )
    )
    return 0 if payload["summary"]["runtime_primitive_ready"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
