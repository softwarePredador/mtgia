#!/usr/bin/env python3
"""Synthesize failure-targeted Lorehold synergy hypotheses.

This read-only helper starts where the package queue stops. When the latest
queue has no gate-ready swaps, it mines the current strategy audit, weak-seed
telemetry, and active runtime rules for the existing engine pieces. The output
is a trace/runtime hypothesis queue, not a deck promotion.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_STRATEGY_AUDIT = (
    REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
)
DEFAULT_HYPOTHESIS_QUEUE = (
    REPORT_DIR / "lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json"
)
DEFAULT_NEXT_ACTION_PLANNER = (
    REPORT_DIR / "lorehold_next_action_planner_20260628_v11_strategy_synthesis.json"
)
DEFAULT_DB = (
    REPORT_DIR
    / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
    / "knowledge_candidate.db"
)

DEFAULT_FOCUS_CARDS = [
    "Urza's Saga",
    "Library of Leng",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Squee, Goblin Nabob",
    "The Mind Stone",
    "Land Tax",
]
EVENT_KEYS = [
    "lorehold_upkeep_rummage",
    "lorehold_spell_rummage",
    "miracle_cast",
    "topdeck_manipulation_activated",
    "squee_to_graveyard",
    "squee_upkeep_return",
    "squee_return_after_known_graveyard_entry",
    "lorehold_rummage_discards_squee",
]
ACTIVE_EXECUTION_STATUSES = {"active", "auto", "reviewed", "verified"}
INACTIVE_REVIEW_STATUSES = {"deprecated", "disabled"}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def lookup_forms(name: str) -> set[str]:
    normalized = normalize_key(name)
    return {
        normalized,
        normalized.replace(" ", ""),
        re.sub(r"\s+", " ", str(name or "").strip().lower()),
    }


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {str(row["name"]) for row in conn.execute(f"PRAGMA table_info({table})").fetchall()}


def focus_cards_from_planner(planner_payload: dict[str, Any]) -> list[str]:
    for row in planner_payload.get("action_queue") or []:
        if row.get("action_key") == "build_failure_targeted_synergy_hypotheses":
            cards = [str(card) for card in row.get("candidate_cards") or [] if str(card).strip()]
            if cards:
                return cards
    return list(DEFAULT_FOCUS_CARDS)


def deck_presence(strategy_audit: dict[str, Any], focus_cards: Iterable[str]) -> dict[str, dict[str, Any]]:
    presence = {
        card: {
            "deck_ids": [],
            "in_current_champion_by_inference": False,
        }
        for card in focus_cards
    }
    lookup = {normalize_key(card): card for card in focus_cards}
    for deck_id, summary in (strategy_audit.get("deck_summaries") or {}).items():
        for row in summary.get("cards") or []:
            card_name = row.get("card_name")
            key = normalize_key(card_name)
            if key in lookup:
                presence[lookup[key]]["deck_ids"].append(str(deck_id))

    champion_key = str(strategy_audit.get("current_champion_key") or "")
    if "squee" in champion_key.lower() and "Squee, Goblin Nabob" in presence:
        presence["Squee, Goblin Nabob"]["in_current_champion_by_inference"] = True
    for row in presence.values():
        row["deck_ids"] = sorted(
            set(row["deck_ids"]),
            key=lambda value: (0, int(value)) if value.isdigit() else (1, value),
        )
    return presence


def rule_lookup(conn: sqlite3.Connection, focus_cards: Iterable[str]) -> dict[str, dict[str, Any]]:
    focus = list(focus_cards)
    forms = sorted({form for card in focus for form in lookup_forms(card)})
    out = {
        card: {
            "active_rule_count": 0,
            "rule_count": 0,
            "battle_model_scopes": [],
            "effects": [],
            "runtime_notes": [],
        }
        for card in focus
    }
    if not forms:
        return out
    columns = table_columns(conn, "battle_card_rules")
    normalized_expr = "normalized_name" if "normalized_name" in columns else "lower(card_name)"
    select_parts = ["card_name"]
    for column in ("normalized_name", "logical_rule_key", "review_status", "execution_status", "effect_json"):
        select_parts.append(column if column in columns else f"NULL AS {column}")
    placeholders = ",".join("?" for _ in forms)
    rows = conn.execute(
        f"""
        SELECT {", ".join(select_parts)}
        FROM battle_card_rules
        WHERE {normalized_expr} IN ({placeholders})
        ORDER BY card_name, logical_rule_key
        """,
        forms,
    ).fetchall()
    form_to_focus = {form: card for card in focus for form in lookup_forms(card)}
    for row in rows:
        forms_for_row = lookup_forms(str(row["card_name"] or ""))
        focus_card = next((form_to_focus[form] for form in forms_for_row if form in form_to_focus), "")
        if not focus_card:
            continue
        summary = out[focus_card]
        summary["rule_count"] += 1
        execution = str(row["execution_status"] or "")
        review = str(row["review_status"] or "")
        is_active_rule = execution in ACTIVE_EXECUTION_STATUSES and review not in INACTIVE_REVIEW_STATUSES
        if is_active_rule:
            summary["active_rule_count"] += 1
        try:
            effect = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect = {}
        if is_active_rule and isinstance(effect, dict):
            scope = effect.get("battle_model_scope")
            if scope:
                summary["battle_model_scopes"].append(str(scope))
            effect_name = effect.get("effect")
            if effect_name:
                summary["effects"].append(str(effect_name))
            if focus_card == "Urza's Saga":
                if "partial" in str(scope or ""):
                    summary["runtime_notes"].append("saga_rule_scope_partial")
                tutor_cmc_max = effect.get("saga_artifact_tutor_cmc_max")
                if tutor_cmc_max is not None and int(tutor_cmc_max) < 1:
                    summary["runtime_notes"].append("saga_tutor_cmc_max_below_top_or_library")
            if focus_card == "The Mind Stone" and effect.get("harnessed_end_step_blink"):
                summary["runtime_notes"].append("blink_value_requires_target_trace")
    for summary in out.values():
        summary["battle_model_scopes"] = sorted(set(summary["battle_model_scopes"]))
        summary["effects"] = sorted(set(summary["effects"]))
        summary["runtime_notes"] = sorted(set(summary["runtime_notes"]))
    return out


def seed_row(strategy_audit: dict[str, Any], seed_key: str) -> dict[str, Any]:
    benchmark = (strategy_audit.get("strategy_dependency_map") or {}).get("current_benchmark") or {}
    return dict(benchmark.get(seed_key) or {})


def event_rate(row: dict[str, Any], event: str) -> float:
    games = (row.get("strategic_games") or {}).get(event) or {}
    if isinstance(games, dict) and "rate" in games:
        return float(games.get("rate") or 0.0)
    total_games = int(row.get("games") or 0)
    if total_games <= 0:
        return 0.0
    event_counts = row.get("strategic_events") or {}
    return float(event_counts.get(f"games_with:{event}") or 0) / total_games


def seed_profile(strategy_audit: dict[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for label, key in (
        ("strong_reference", "seed_42_champion"),
        ("weak_missing_engine", "seed_7_champion"),
        ("weak_conversion_gap", "seed_20260625_champion"),
    ):
        row = seed_row(strategy_audit, key)
        if not row:
            continue
        rates = {event: round(event_rate(row, event), 4) for event in EVENT_KEYS}
        rows.append(
            {
                "label": label,
                "seed": row.get("seed"),
                "record": f"{int(row.get('wins') or 0)}-{int(row.get('losses') or 0)}-{int(row.get('stalls') or 0)}",
                "win_rate": float(row.get("win_rate") or 0.0),
                "games": int(row.get("games") or 0),
                "source": row.get("source"),
                "event_rates": rates,
                "event_counts": {
                    event: int((row.get("strategic_events") or {}).get(event) or 0)
                    for event in EVENT_KEYS
                },
            }
        )
    return rows


def weak_seed_findings(seeds: list[dict[str, Any]]) -> list[dict[str, Any]]:
    strong = next((row for row in seeds if row["label"] == "strong_reference"), {})
    strong_rates = strong.get("event_rates") or {}
    findings = []
    for row in seeds:
        if row["label"] == "strong_reference":
            continue
        rates = row.get("event_rates") or {}
        topdeck_ratio = (
            rates.get("topdeck_manipulation_activated", 0.0)
            / strong_rates.get("topdeck_manipulation_activated", 1.0)
            if strong_rates.get("topdeck_manipulation_activated", 0.0) > 0
            else 0.0
        )
        miracle_ratio = (
            rates.get("miracle_cast", 0.0) / strong_rates.get("miracle_cast", 1.0)
            if strong_rates.get("miracle_cast", 0.0) > 0
            else 0.0
        )
        squee_missing = (
            rates.get("squee_to_graveyard", 0.0) == 0.0
            and rates.get("squee_upkeep_return", 0.0) == 0.0
        )
        if row["seed"] == 20260625 and rates.get("lorehold_upkeep_rummage", 0.0) >= 0.75:
            finding_type = "engine_seen_but_conversion_failed"
        elif topdeck_ratio <= 0.25 or squee_missing:
            finding_type = "missing_or_low_engine_access"
        else:
            finding_type = "weak_seed_unclassified"
        findings.append(
            {
                "seed": row["seed"],
                "finding_type": finding_type,
                "record": row["record"],
                "win_rate": row["win_rate"],
                "topdeck_rate": rates.get("topdeck_manipulation_activated", 0.0),
                "topdeck_ratio_vs_seed42": round(topdeck_ratio, 4),
                "miracle_rate": rates.get("miracle_cast", 0.0),
                "miracle_ratio_vs_seed42": round(miracle_ratio, 4),
                "squee_missing": squee_missing,
                "source": row.get("source"),
            }
        )
    return findings


def queue_exhausted(hypothesis_queue: dict[str, Any]) -> bool:
    summary = hypothesis_queue.get("summary") or {}
    return int(summary.get("gate_ready_count") or 0) == 0 and int(summary.get("tested_negative_count") or 0) > 0


def build_hypotheses(
    *,
    strategy_audit: dict[str, Any],
    hypothesis_queue: dict[str, Any],
    engine_profiles: list[dict[str, Any]],
    findings: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    if not queue_exhausted(hypothesis_queue):
        return []
    profile_by_name = {row["card_name"]: row for row in engine_profiles}
    findings_by_seed = {int(row["seed"]): row for row in findings if row.get("seed") is not None}
    hypotheses: list[dict[str, Any]] = []
    if 7 in findings_by_seed:
        hypotheses.append(
            {
                "hypothesis_key": "trace_seed7_engine_access_sequence",
                "status": "trace_audit_required",
                "target_failure": "seed 7 missing or low engine access",
                "target_seeds": [7],
                "focus_cards": [
                    "Urza's Saga",
                    "Library of Leng",
                    "Sensei's Divining Top",
                    "Scroll Rack",
                    "Squee, Goblin Nabob",
                ],
                "why": (
                    "Seed 7 is 0-9 with topdeck manipulation far below seed 42 and no Squee "
                    "graveyard/return route, so another card swap is premature."
                ),
                "required_evidence": [
                    "per-game opening/early-turn presence for Library, Top, Rack, Urza's Saga, and Squee",
                    "whether Urza's Saga resolves artifact tutor value before the game is lost",
                    "whether the commander rummage ever has Squee in hand and chooses a graveyard route",
                ],
                "gate_after_trace": "only build a package if the trace identifies a missing access route or unused in-deck engine",
                "evidence": findings_by_seed[7],
            }
        )
    if 20260625 in findings_by_seed:
        hypotheses.append(
            {
                "hypothesis_key": "trace_seed20260625_conversion_window",
                "status": "trace_audit_required",
                "target_failure": "engine appears but fails to convert",
                "target_seeds": [20260625],
                "focus_cards": [
                    "Library of Leng",
                    "Sensei's Divining Top",
                    "Scroll Rack",
                    "The Mind Stone",
                    "Land Tax",
                ],
                "why": (
                    "Seed 20260625 still sees Lorehold upkeep rummage often but remains 0-9, "
                    "with low miracle/topdeck conversion and no Squee recursion route."
                ),
                "required_evidence": [
                    "whether discard-to-top produces Approach, protection, or a finisher window",
                    "whether The Mind Stone blink has a high-value target or is only incidental ramp",
                    "whether Land Tax thins/fixes mana early enough to increase spell-chain density",
                ],
                "gate_after_trace": "prefer conversion/support package only if it preserves seed-42 miracle/topdeck telemetry",
                "evidence": findings_by_seed[20260625],
            }
        )
    urza = profile_by_name.get("Urza's Saga") or {}
    urza_rules = urza.get("rules") or {}
    if urza_rules.get("runtime_notes"):
        hypotheses.append(
            {
                "hypothesis_key": "audit_urzas_saga_artifact_tutor_scope",
                "status": "runtime_utilization_audit_required",
                "target_failure": "existing engine may be under-modeled",
                "target_seeds": [7, 20260625, 42],
                "focus_cards": ["Urza's Saga", "Sensei's Divining Top", "Library of Leng"],
                "why": (
                    "Urza's Saga is already in the champion shell, but active rule metadata includes "
                    "partial Saga scope or artifact tutor CMC limits that may miss key one-mana artifacts."
                ),
                "required_evidence": [
                    "confirm chapter progression, construct creation, tutor target choice, and sacrificed state in natural games",
                    "verify whether Top/Library-class targets are intentionally reachable or excluded by the battle model",
                ],
                "gate_after_trace": "fix runtime/model first if Saga cannot find relevant artifacts before testing new cards",
                "evidence": {
                    "rule_profile": urza_rules,
                },
            }
        )
    champion_events = (
        (strategy_audit.get("strategy_dependency_map") or {})
        .get("current_benchmark", {})
        .get("champion", {})
        .get("strategic_events", {})
    )
    if int(champion_events.get("lorehold_rummage_discards_squee") or 0) == 0:
        hypotheses.append(
            {
                "hypothesis_key": "audit_squee_graveyard_entry_route",
                "status": "trace_audit_required",
                "target_failure": "Squee value exists but not through Lorehold discard",
                "target_seeds": [7, 20260625, 42],
                "focus_cards": ["Squee, Goblin Nabob", "Library of Leng", "Lorehold, the Historian"],
                "why": (
                    "The champion has Squee returns after known graveyard entry, but Lorehold rummage "
                    "has not been observed discarding Squee. The deck may need sequencing logic before a card swap."
                ),
                "required_evidence": [
                    "trace every Squee hand/graveyard move and the source reason",
                    "verify whether Library replacement conflicts with putting Squee into the graveyard",
                ],
                "gate_after_trace": "only test discard enablers if Squee is present but cannot enter graveyard naturally",
                "evidence": {
                    "champion_lorehold_rummage_discards_squee": int(
                        champion_events.get("lorehold_rummage_discards_squee") or 0
                    ),
                    "champion_squee_to_graveyard": int(champion_events.get("squee_to_graveyard") or 0),
                    "champion_squee_upkeep_return": int(champion_events.get("squee_upkeep_return") or 0),
                },
            }
        )
    return hypotheses


def build_report(
    *,
    strategy_audit: dict[str, Any],
    hypothesis_queue: dict[str, Any],
    planner_payload: dict[str, Any],
    conn: sqlite3.Connection,
    strategy_path: Path = DEFAULT_STRATEGY_AUDIT,
    queue_path: Path = DEFAULT_HYPOTHESIS_QUEUE,
    planner_path: Path = DEFAULT_NEXT_ACTION_PLANNER,
    db_path: Path = DEFAULT_DB,
) -> dict[str, Any]:
    focus_cards = focus_cards_from_planner(planner_payload)
    presence = deck_presence(strategy_audit, focus_cards)
    rules = rule_lookup(conn, focus_cards)
    engine_profiles = []
    for card in focus_cards:
        engine_profiles.append(
            {
                "card_name": card,
                "presence": presence.get(card, {}),
                "rules": rules.get(card, {}),
            }
        )
    seeds = seed_profile(strategy_audit)
    findings = weak_seed_findings(seeds)
    hypotheses = build_hypotheses(
        strategy_audit=strategy_audit,
        hypothesis_queue=hypothesis_queue,
        engine_profiles=engine_profiles,
        findings=findings,
    )
    status_counts = Counter(row["status"] for row in hypotheses)
    queue_summary = hypothesis_queue.get("summary") or {}
    return {
        "generated_at": utc_now(),
        "strategy_audit": str(strategy_path),
        "hypothesis_queue": str(queue_path),
        "next_action_planner": str(planner_path),
        "source_db": str(db_path),
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "focus_card_count": len(focus_cards),
            "weak_seed_finding_count": len(findings),
            "hypothesis_count": len(hypotheses),
            "hypothesis_status_counts": dict(sorted(status_counts.items())),
            "queue_gate_ready_count": int(queue_summary.get("gate_ready_count") or 0),
            "queue_tested_negative_count": int(queue_summary.get("tested_negative_count") or 0),
            "recommended_next_action": (
                "run_failure_targeted_trace_audit"
                if hypotheses
                else "use_existing_gate_ready_queue"
            ),
        },
        "commander_intent": strategy_audit.get("commander_intent"),
        "seed_profiles": seeds,
        "weak_seed_findings": findings,
        "engine_profiles": engine_profiles,
        "hypotheses": hypotheses,
        "guardrails": [
            "Do not register a new add/cut package while the current queue is fully prior-negative.",
            "Do not cut protected or locked cards without same-lane proof.",
            "Preserve seed-42 miracle/topdeck telemetry as the first regression check.",
            "Treat runtime/model underutilization as a blocker before judging a card as strategically bad.",
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Failure-Targeted Synergy Hypotheses - 2026-06-28",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Strategy audit: `{payload['strategy_audit']}`",
        f"- Hypothesis queue: `{payload['hypothesis_queue']}`",
        f"- Next action planner: `{payload['next_action_planner']}`",
        f"- Source DB: `{payload['source_db']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Recommended next action: `{payload['summary']['recommended_next_action']}`",
        f"- Focus cards: `{payload['summary']['focus_card_count']}`",
        f"- Weak seed findings: `{payload['summary']['weak_seed_finding_count']}`",
        f"- Hypotheses: `{payload['summary']['hypothesis_count']}`",
        f"- Hypothesis statuses: `{json.dumps(payload['summary']['hypothesis_status_counts'], sort_keys=True)}`",
        f"- Queue gate-ready/tested-negative: `{payload['summary']['queue_gate_ready_count']}` / `{payload['summary']['queue_tested_negative_count']}`",
        "",
        "## Weak Seed Findings",
        "",
        "| Seed | Finding | Record | Topdeck Rate | Miracle Rate | Squee Missing |",
        "| ---: | --- | --- | ---: | ---: | --- |",
    ]
    for row in payload["weak_seed_findings"]:
        lines.append(
            "| {seed} | `{finding}` | `{record}` | {topdeck:.4f} | {miracle:.4f} | `{squee}` |".format(
                seed=row["seed"],
                finding=row["finding_type"],
                record=row["record"],
                topdeck=row["topdeck_rate"],
                miracle=row["miracle_rate"],
                squee=str(row["squee_missing"]).lower(),
            )
        )
    lines.extend(["", "## Engine Profiles", ""])
    for row in payload["engine_profiles"]:
        rules = row["rules"]
        presence = row["presence"]
        lines.append(
            "- `{card}`: decks `{decks}`, champion_inferred=`{champion}`, active_rules=`{active}`, scopes=`{scopes}`, notes=`{notes}`".format(
                card=row["card_name"],
                decks=",".join(presence.get("deck_ids") or []) or "-",
                champion=str(presence.get("in_current_champion_by_inference", False)).lower(),
                active=rules.get("active_rule_count", 0),
                scopes=", ".join(rules.get("battle_model_scopes") or []) or "-",
                notes=", ".join(rules.get("runtime_notes") or []) or "-",
            )
        )
    lines.extend(["", "## Hypotheses", ""])
    for row in payload["hypotheses"]:
        lines.append(f"### {row['hypothesis_key']}")
        lines.append("")
        lines.append(f"- Status: `{row['status']}`")
        lines.append(f"- Target failure: {row['target_failure']}")
        lines.append(f"- Target seeds: `{', '.join(str(seed) for seed in row['target_seeds'])}`")
        lines.append(f"- Focus cards: {', '.join(row['focus_cards'])}")
        lines.append(f"- Why: {row['why']}")
        for item in row.get("required_evidence") or []:
            lines.append(f"- Required evidence: {item}")
        lines.append(f"- Gate after trace: {row['gate_after_trace']}")
        lines.append("")
    lines.extend(["## Guardrails", ""])
    for guardrail in payload["guardrails"]:
        lines.append(f"- {guardrail}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--next-action-planner", type=Path, default=DEFAULT_NEXT_ACTION_PLANNER)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--stem", default="lorehold_failure_targeted_synergy_hypotheses_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    strategy_audit = read_json(args.strategy_audit)
    hypothesis_queue = read_json(args.hypothesis_queue)
    planner_payload = read_json(args.next_action_planner)
    with connect(args.db) as conn:
        payload = build_report(
            strategy_audit=strategy_audit,
            hypothesis_queue=hypothesis_queue,
            planner_payload=planner_payload,
            conn=conn,
            strategy_path=args.strategy_audit,
            queue_path=args.hypothesis_queue,
            planner_path=args.next_action_planner,
            db_path=args.db,
        )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
