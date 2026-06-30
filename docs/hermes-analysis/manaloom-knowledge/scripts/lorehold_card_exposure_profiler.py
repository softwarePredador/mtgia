#!/usr/bin/env python3
"""Profile Lorehold card exposure from local battle/replay evidence.

This is a read-only helper. It scans local JSON/JSONL gate and replay artifacts
for actual event exposure by target card, then combines that with local battle
rule availability. The output is meant to separate "card has a good rule" from
"card has actually appeared doing its job in the current evidence archive."
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_TARGET_CARDS = [
    "Emeria's Call // Emeria, Shattered Skyclave",
    "Austere Command",
    "Squee, Goblin Nabob",
    "Volcanic Vision",
    "Restoration Seminar",
    "Gamble",
    "Enlightened Tutor",
]
ACTIVE_EXECUTION_STATUSES = {"active", "verified", "auto", "reviewed"}
ACTIVE_REVIEW_STATUSES = {"verified", "active", "needs_review", "reviewed"}
SAMPLE_LIMIT_PER_CARD = 30
SOURCE_LIMIT_PER_CARD = 20


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def default_evidence_paths() -> list[Path]:
    paths: set[Path] = set()
    for pattern in ("lorehold_*gate*.json", "lorehold_*replay*.json", "lorehold_*forensic*.json"):
        paths.update(path for path in REPORT_DIR.glob(pattern) if path.is_file())
    paths.update(path for path in REPORT_DIR.rglob("*.jsonl") if path.is_file())
    return sorted(
        path
        for path in paths
        if "exposure_profile" not in path.name
    )


def target_lookup(card_names: Iterable[str]) -> dict[str, str]:
    return {normalize_key(name): str(name) for name in card_names if str(name).strip()}


def dedupe_preserve_order(values: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for value in values:
        text = str(value or "").strip()
        key = normalize_key(text)
        if not key or key in seen:
            continue
        seen.add(key)
        out.append(text)
    return out


def deck_card_names(conn: sqlite3.Connection, deck_id: int) -> list[str]:
    table = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='deck_cards'"
    ).fetchone()
    if table is None:
        return []
    rows = conn.execute(
        """
        SELECT card_name
        FROM deck_cards
        WHERE deck_id=?
          AND coalesce(card_name, '') <> ''
        ORDER BY card_name
        """,
        (deck_id,),
    ).fetchall()
    return [str(row["card_name"]) for row in rows]


def split_metric_key(value: object) -> tuple[str, str]:
    raw = str(value or "")
    if ":" not in raw:
        return raw, ""
    left, right = raw.split(":", 1)
    return left, right


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def iter_target_matches(row: dict[str, Any], targets: dict[str, str]) -> Iterable[tuple[str, str]]:
    for key in (
        "card",
        "card_name",
        "found",
        "source",
        "source_card",
        "stack_top",
        "target",
        "object",
    ):
        if not row.get(key):
            continue
        normalized = normalize_key(row[key])
        if normalized in targets:
            yield targets[normalized], key
    metric_prefix, metric_card = split_metric_key(row.get("key"))
    if metric_card and normalize_key(metric_card) in targets:
        yield targets[normalize_key(metric_card)], "metric_card"
    if isinstance(row.get("discarded_cards"), list):
        for value in row["discarded_cards"]:
            normalized = normalize_key(value)
            if normalized in targets:
                yield targets[normalized], "discarded_cards"


def event_payload(row: dict[str, Any]) -> dict[str, Any]:
    payload = dict(row)
    data = row.get("data")
    if isinstance(data, dict):
        payload.update(data)
    return payload


def evidence_record(
    *,
    source_path: Path,
    path: str,
    row: dict[str, Any],
    target: str,
    matched_field: str,
) -> dict[str, Any]:
    payload = event_payload(row)
    metric_type, metric_card = split_metric_key(payload.get("key"))
    event = str(payload.get("event") or metric_type or "summary_metric")
    evidence_type = "summary_metric" if payload.get("key") and not payload.get("event") else "event"
    return {
        "card_name": target,
        "event": event,
        "evidence_type": evidence_type,
        "metric_key": payload.get("key"),
        "metric_count": int(payload.get("count") or 0) if payload.get("count") is not None else None,
        "effect": payload.get("effect"),
        "player": payload.get("player"),
        "turn": payload.get("turn"),
        "source": payload.get("source"),
        "reason": payload.get("reason"),
        "found": payload.get("found"),
        "matched_field": matched_field,
        "path": path,
        "source_file": display_path(source_path),
        "signature": event_signature(
            source_path,
            path,
            payload,
            target,
            event,
            metric_card,
            matched_field,
        ),
    }


def event_signature(
    source_path: Path,
    path: str,
    payload: dict[str, Any],
    target: str,
    event: str,
    metric_card: str,
    matched_field: str,
) -> tuple[Any, ...]:
    game_context = ""
    for part in path.split("."):
        if ":" in part and ("deck_" in part or "synergy_" in part):
            game_context = part
            break
    return (
        display_path(source_path),
        game_context,
        target,
        event,
        payload.get("turn"),
        payload.get("player"),
        payload.get("effect"),
        payload.get("reason"),
        payload.get("source"),
        payload.get("key") or metric_card,
        matched_field,
    )


def walk_json(
    obj: Any,
    *,
    source_path: Path,
    path: str,
    targets: dict[str, str],
) -> Iterable[dict[str, Any]]:
    if isinstance(obj, dict):
        payload = event_payload(obj)
        if obj.get("event") or obj.get("key"):
            seen_matches: set[tuple[str, str]] = set()
            for target, matched_field in iter_target_matches(payload, targets):
                match = (target, matched_field)
                if match in seen_matches:
                    continue
                seen_matches.add(match)
                yield evidence_record(
                    source_path=source_path,
                    path=path,
                    row=obj,
                    target=target,
                    matched_field=matched_field,
                )
        for key, value in obj.items():
            child_path = f"{path}.{key}" if path else str(key)
            yield from walk_json(value, source_path=source_path, path=child_path, targets=targets)
    elif isinstance(obj, list):
        for index, value in enumerate(obj):
            yield from walk_json(
                value,
                source_path=source_path,
                path=f"{path}[{index}]",
                targets=targets,
            )


def load_json_records(path: Path, targets: dict[str, str]) -> tuple[list[dict[str, Any]], str | None]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return [], f"{type(exc).__name__}: {exc}"
    return list(walk_json(data, source_path=path, path="", targets=targets)), None


def load_jsonl_records(path: Path, targets: dict[str, str]) -> tuple[list[dict[str, Any]], str | None]:
    records: list[dict[str, Any]] = []
    try:
        with path.open("r", encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, start=1):
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except Exception:
                    continue
                if isinstance(row, dict):
                    records.extend(
                        walk_json(
                            row,
                            source_path=path,
                            path=f"line:{line_number}",
                            targets=targets,
                        )
                    )
    except Exception as exc:
        return [], f"{type(exc).__name__}: {exc}"
    return records, None


def load_rule_summaries(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in names if name}
    summaries: dict[str, dict[str, Any]] = {
        key: {
            "card_name": name,
            "active_rule_count": 0,
            "rule_count": 0,
            "effects": Counter(),
            "battle_model_scopes": Counter(),
            "active_effects": Counter(),
            "active_battle_model_scopes": Counter(),
            "execution_statuses": Counter(),
            "review_statuses": Counter(),
        }
        for key, name in wanted.items()
    }
    if not wanted:
        return {}
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, execution_status, review_status, effect_json
        FROM battle_card_rules
        ORDER BY card_name
        """
    ).fetchall()
    for row in rows:
        forms = {normalize_key(row["card_name"]), normalize_key(row["normalized_name"])}
        key = next((form for form in forms if form in wanted), "")
        if not key:
            continue
        summary = summaries[key]
        execution_status = str(row["execution_status"] or "")
        review_status = str(row["review_status"] or "")
        summary["rule_count"] += 1
        summary["execution_statuses"][execution_status] += 1
        summary["review_statuses"][review_status] += 1
        is_active_rule = execution_status in ACTIVE_EXECUTION_STATUSES and review_status in ACTIVE_REVIEW_STATUSES
        if is_active_rule:
            summary["active_rule_count"] += 1
        try:
            effect_json = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect_json = {}
        if isinstance(effect_json, dict):
            if effect_json.get("effect"):
                summary["effects"][str(effect_json["effect"])] += 1
                if is_active_rule:
                    summary["active_effects"][str(effect_json["effect"])] += 1
            if effect_json.get("battle_model_scope"):
                summary["battle_model_scopes"][str(effect_json["battle_model_scope"])] += 1
                if is_active_rule:
                    summary["active_battle_model_scopes"][str(effect_json["battle_model_scope"])] += 1
    return {key: finalize_rule_summary(value) for key, value in summaries.items()}


def finalize_rule_summary(summary: dict[str, Any]) -> dict[str, Any]:
    finalized = dict(summary)
    for key in (
        "effects",
        "battle_model_scopes",
        "active_effects",
        "active_battle_model_scopes",
        "execution_statuses",
        "review_statuses",
    ):
        finalized[key] = dict(sorted((summary.get(key) or {}).items()))
    return finalized


def summarize_card(card_name: str, records: list[dict[str, Any]], rule: dict[str, Any]) -> dict[str, Any]:
    unique: dict[tuple[Any, ...], dict[str, Any]] = {}
    for record in records:
        unique.setdefault(tuple(record["signature"]), record)
    unique_records = list(unique.values())
    event_counts = Counter(str(row["event"]) for row in unique_records if row["evidence_type"] == "event")
    direct_event_count = sum(1 for row in unique_records if row["evidence_type"] == "event")
    summary_metric_count = sum(1 for row in unique_records if row["evidence_type"] == "summary_metric")
    metric_counts = Counter()
    for row in unique_records:
        if row["evidence_type"] == "summary_metric" and row.get("metric_key"):
            metric_counts[str(row["metric_key"])] += int(row.get("metric_count") or 0)
    effect_counts = Counter(str(row.get("effect")) for row in unique_records if row.get("effect"))
    matched_field_counts = Counter(
        str(row.get("matched_field")) for row in unique_records if row.get("matched_field")
    )
    source_counts = Counter(str(row["source_file"]) for row in unique_records)
    role_signals = infer_role_signals(
        event_counts,
        effect_counts,
        metric_counts,
        matched_field_counts,
        rule,
    )
    inferred_role, role_confidence = infer_role(
        card_name,
        role_signals,
        rule,
        unique_exposure_count=len(unique_records),
        direct_event_count=direct_event_count,
    )
    decision = cut_or_gate_decision(card_name, role_signals, rule, len(unique_records))
    samples = sorted(
        (
            {
                key: row.get(key)
                for key in (
                    "event",
                    "evidence_type",
                    "metric_key",
                    "metric_count",
                    "effect",
                    "turn",
                    "player",
                    "reason",
                    "source",
                    "found",
                    "matched_field",
                    "source_file",
                    "path",
                )
                if row.get(key) not in (None, "")
            }
            for row in unique_records
        ),
        key=lambda row: (str(row.get("source_file")), str(row.get("path"))),
    )[:SAMPLE_LIMIT_PER_CARD]
    return {
        "card_name": card_name,
        "raw_record_count": len(records),
        "unique_exposure_count": len(unique_records),
        "direct_event_count": direct_event_count,
        "summary_metric_count": summary_metric_count,
        "event_counts": dict(sorted(event_counts.items())),
        "metric_counts": dict(sorted(metric_counts.items())),
        "effect_counts": dict(sorted(effect_counts.items())),
        "matched_field_counts": dict(sorted(matched_field_counts.items())),
        "source_file_count": len(source_counts),
        "source_files": [
            {"source_file": source, "unique_exposure_count": count}
            for source, count in source_counts.most_common(SOURCE_LIMIT_PER_CARD)
        ],
        "rule_summary": rule,
        "role_signals": role_signals,
        "inferred_role": inferred_role,
        "role_confidence": role_confidence,
        "decision": decision,
        "samples": samples,
    }


def infer_role_signals(
    event_counts: Counter[str],
    effect_counts: Counter[str],
    metric_counts: Counter[str],
    matched_field_counts: Counter[str],
    rule: dict[str, Any],
) -> list[str]:
    signals: set[str] = set()
    has_active_rules = int(rule.get("active_rule_count") or 0) > 0
    rule_effects = set((rule.get("effects") or {}).keys())
    active_rule_effects = set((rule.get("active_effects") or {}).keys())
    scopes = set((rule.get("battle_model_scopes") or {}).keys())
    active_scopes = set((rule.get("active_battle_model_scopes") or {}).keys())
    role_rule_effects = active_rule_effects if has_active_rules else rule_effects
    role_scopes = active_scopes if has_active_rules else scopes
    all_effects = set(effect_counts) | role_rule_effects
    if {"tokens_created", "token_maker"} & set(event_counts) or "token_maker" in all_effects:
        signals.add("board_development_tokens")
    if all_effects & {"draw_cards", "draw_engine", "hand_filter", "exile_value"} or "wheel_resolved" in event_counts:
        signals.add("draw_filter_value")
    if (
        "ramp_engine" in all_effects
        or any("treasure" in effect for effect in all_effects)
        or any("treasure" in scope or "mana" in scope for scope in role_scopes)
    ):
        signals.add("ramp_engine")
    if any("discard" in effect for effect in all_effects) or any("discard" in scope for scope in role_scopes):
        signals.add("discard_payoff")
    if "protection_resolved" in event_counts or any("indestructible" in scope for scope in role_scopes):
        signals.add("protection_window")
    if "board_wipe_resolved" in event_counts or "board_wipe" in all_effects:
        signals.add("pressure_reset_board_wipe")
    rule_removal_effect = any(
        effect.startswith("remove") or "removal" in effect
        for effect in role_rule_effects
    )
    rule_removal_scope = any(
        "destroy_target" in scope
        or "exile_target" in scope
        or scope.startswith("path_to_exile")
        or scope.startswith("swords_to_plowshares")
        or scope.startswith("winds_of_abandon")
        or "edict" in scope
        or "greatest_power" in scope
        for scope in role_scopes
    )
    if rule_removal_effect or rule_removal_scope:
        signals.add("spot_removal")
    if any("tutor" in effect for effect in all_effects):
        signals.add("tutor_access")
    if "tutor_resolved" in event_counts and matched_field_counts.get("found"):
        signals.add("tutor_target")
    graveyard_effect = any(
        "graveyard" in effect and ("return" in effect or "recursion" in effect)
        for effect in all_effects
    )
    graveyard_scope = any(
        "graveyard" in scope and ("return" in scope or "recursion" in scope)
        for scope in role_scopes
    )
    if graveyard_effect or graveyard_scope:
        signals.add("graveyard_recursion")
    if "recursion" in all_effects:
        signals.add("spell_or_permanent_recursion")
    if any(key.startswith("miracle:") for key in metric_counts):
        signals.add("miracle_hit")
    if any(key.startswith("cost_paid:") for key in metric_counts):
        signals.add("paid_cast_exposure")
    if "turn_end" in event_counts:
        signals.add("discard_or_rummage_context")
    return sorted(signals)


def infer_role(
    card_name: str,
    signals: list[str],
    rule: dict[str, Any],
    unique_exposure_count: int,
    direct_event_count: int,
) -> tuple[str, str]:
    signal_set = set(signals)
    if {"board_development_tokens", "protection_window"} <= signal_set:
        return "token_protection_rebuild", "direct_event_and_rule" if direct_event_count else "rule_only"
    if "pressure_reset_board_wipe" in signal_set:
        return "board_wipe_pressure_reset", "direct_event_or_rule" if direct_event_count else "rule_only"
    if "graveyard_recursion" in signal_set:
        return "recursion_engine", "direct_event_or_rule" if direct_event_count else "rule_only"
    if "spell_or_permanent_recursion" in signal_set:
        if direct_event_count:
            return "recursion_candidate", "direct_event_or_rule"
        if unique_exposure_count:
            return "recursion_candidate", "summary_metric_and_rule"
        return "recursion_candidate", "rule_ready_unexposed"
    if "spot_removal" in signal_set:
        return "spot_removal", "direct_event_or_rule" if direct_event_count else "rule_only"
    if "tutor_access" in signal_set:
        return "tutor_access", "direct_event_or_rule" if direct_event_count else "rule_only"
    if "draw_filter_value" in signal_set:
        return "draw_filter_value", "direct_event_or_rule" if direct_event_count else "rule_only"
    if {"discard_payoff", "ramp_engine"} <= signal_set:
        return "discard_ramp_value", "direct_event_or_rule" if direct_event_count else "rule_only"
    if "ramp_engine" in signal_set:
        return "ramp_engine", "direct_event_or_rule" if direct_event_count else "rule_only"
    if "tutor_target" in signal_set:
        return "tutor_target", "direct_event"
    if int(rule.get("active_rule_count") or 0) > 0:
        return "runtime_ready_unexposed", "rule_only"
    return "unproven_or_unmodeled", "missing_runtime_and_event_evidence"


def cut_or_gate_decision(
    card_name: str,
    signals: list[str],
    rule: dict[str, Any],
    unique_exposure_count: int,
) -> dict[str, str]:
    key = normalize_key(card_name)
    signal_set = set(signals)
    if key == normalize_key("Squee, Goblin Nabob"):
        if "graveyard_recursion" in signal_set and unique_exposure_count > 0:
            return {
                "status": "protect_current_engine",
                "next_action": "do_not_cut_for_volcanic_or_restoration_without_non_squee_package",
                "reason": "Squee has direct graveyard-return exposure and active rule support.",
            }
    if key == normalize_key("Emeria's Call // Emeria, Shattered Skyclave"):
        if {"board_development_tokens", "protection_window"} <= signal_set:
            return {
                "status": "not_safe_as_blind_cut",
                "next_action": "test_austere_only_as_explicit_wipe_over_rebuild_tradeoff",
                "reason": "Emeria has direct token/protection exposure; cutting it deletes a measured rebuild/protection role.",
            }
        return {
            "status": "needs_exposure_gate",
            "next_action": "measure_token_and_protection_exposure_before_cut",
            "reason": "Emeria has runtime support but insufficient direct role exposure in scanned evidence.",
        }
    if key == normalize_key("Austere Command"):
        return {
            "status": "candidate_role_known",
            "next_action": "only_gate_against_emeria_if_targeting_more_board_reset_than_rebuild",
            "reason": "Austere is a board-wipe role; it is not a same-role replacement for token/protection rebuild.",
        }
    if key in {normalize_key("Volcanic Vision"), normalize_key("Restoration Seminar")}:
        return {
            "status": "needs_non_squee_cut",
            "next_action": "find recursion cut that is not the protected Squee engine",
            "reason": "Runtime-ready recursion candidate, but current safe-cut model points at Squee.",
        }
    if key in {normalize_key("Gamble"), normalize_key("Enlightened Tutor")}:
        return {
            "status": "runtime_ready_cut_sensitive",
            "next_action": "retest only with seed-safe cut model",
            "reason": "Tutor role is modelable; prior cut choices regressed the protected seed.",
        }
    if int(rule.get("active_rule_count") or 0) <= 0:
        return {
            "status": "blocked_runtime_gap",
            "next_action": "implement or sync active rule before gate",
            "reason": "No active local rule was found.",
        }
    return {
        "status": "review_required",
        "next_action": "connect role to an explicit package hypothesis",
        "reason": "Role evidence exists but no cut decision is encoded for this card.",
    }


def build_profile(
    *,
    evidence_paths: list[Path],
    card_names: list[str],
    conn: sqlite3.Connection,
) -> dict[str, Any]:
    targets = target_lookup(card_names)
    parse_errors: list[dict[str, str]] = []
    records_by_card: dict[str, list[dict[str, Any]]] = defaultdict(list)
    scanned_json = 0
    scanned_jsonl = 0
    scanned_bytes = 0
    for path in evidence_paths:
        if not path.exists() or not path.is_file():
            continue
        scanned_bytes += path.stat().st_size
        if path.suffix == ".jsonl":
            scanned_jsonl += 1
            records, error = load_jsonl_records(path, targets)
        elif path.suffix == ".json":
            scanned_json += 1
            records, error = load_json_records(path, targets)
        else:
            continue
        if error:
            parse_errors.append({"source_file": display_path(path), "error": error})
            continue
        for record in records:
            records_by_card[record["card_name"]].append(record)
    rules = load_rule_summaries(conn, card_names)
    profiles = [
        summarize_card(
            card_name,
            records_by_card.get(card_name, []),
            rules.get(normalize_key(card_name), {}),
        )
        for card_name in card_names
    ]
    return {
        "generated_at": utc_now(),
        "source_db": str(DEFAULT_DB),
        "postgres_writes": False,
        "source_db_mutated": False,
        "scan_summary": {
            "evidence_path_count": len(evidence_paths),
            "json_files_scanned": scanned_json,
            "jsonl_files_scanned": scanned_jsonl,
            "scanned_bytes": scanned_bytes,
            "parse_error_count": len(parse_errors),
        },
        "parse_errors": parse_errors[:20],
        "target_cards": card_names,
        "card_profiles": profiles,
        "package_implications": package_implications(profiles),
    }


def package_implications(profiles: list[dict[str, Any]]) -> list[dict[str, str]]:
    by_name = {normalize_key(row["card_name"]): row for row in profiles}
    emeria = by_name.get(normalize_key("Emeria's Call // Emeria, Shattered Skyclave"), {})
    squee = by_name.get(normalize_key("Squee, Goblin Nabob"), {})
    gamble = by_name.get(normalize_key("Gamble"), {})
    enlightened = by_name.get(normalize_key("Enlightened Tutor"), {})
    implications = []
    if (emeria.get("decision") or {}).get("status") == "not_safe_as_blind_cut":
        implications.append(
            {
                "package": "austere_command_over_emeria",
                "decision": "manual_tradeoff_only",
                "reason": "Emeria has measured token/protection exposure, so Austere must prove board-reset value beats rebuild/protection loss.",
            }
        )
    if (squee.get("decision") or {}).get("status") == "protect_current_engine":
        implications.append(
            {
                "package": "volcanic_or_restoration_over_squee",
                "decision": "blocked_until_non_squee_cut",
                "reason": "Squee has measured graveyard-return exposure and should remain protected.",
            }
        )
    if gamble or enlightened:
        implications.append(
            {
                "package": "tutor_access",
                "decision": "seed_safe_cut_required",
                "reason": "Tutor effects are modelable, but promotion depends on a cut model that preserves the known strong seed.",
            }
        )
    return implications


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Card Exposure Profile - 2026-06-28",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Source DB: `{payload['source_db']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Evidence paths scanned: `{payload['scan_summary']['evidence_path_count']}`",
        f"- JSON files scanned: `{payload['scan_summary']['json_files_scanned']}`",
        f"- JSONL files scanned: `{payload['scan_summary']['jsonl_files_scanned']}`",
        f"- Parse errors: `{payload['scan_summary']['parse_error_count']}`",
        "",
        "## Card Profiles",
        "",
        "| Card | Unique Exposure | Role | Decision | Signals | Top Events/Metrics |",
        "| --- | ---: | --- | --- | --- | --- |",
    ]
    for row in payload["card_profiles"]:
        top_bits = []
        for key, count in list(row["event_counts"].items())[:5]:
            top_bits.append(f"{key}={count}")
        for key, count in list(row["metric_counts"].items())[:5]:
            top_bits.append(f"{key}={count}")
        decision = row["decision"]
        lines.append(
            "| {card} | {exposure} | `{role}` | `{status}` | {signals} | {events} |".format(
                card=row["card_name"],
                exposure=row["unique_exposure_count"],
                role=row["inferred_role"],
                status=decision["status"],
                signals=", ".join(row["role_signals"]) or "none",
                events=", ".join(top_bits) or "none",
            )
        )
    lines.extend(["", "## Package Implications", ""])
    for row in payload["package_implications"]:
        lines.append(f"- `{row['package']}`: `{row['decision']}` - {row['reason']}")
    lines.extend(["", "## Samples", ""])
    for row in payload["card_profiles"]:
        lines.append(f"### {row['card_name']}")
        lines.append("")
        lines.append(f"- Decision: `{row['decision']['status']}`; next: {row['decision']['next_action']}")
        for sample in row["samples"][:8]:
            lines.append(
                "- `{event}` from `{source}` path `{path}` turn `{turn}` effect `{effect}` metric `{metric}`".format(
                    event=sample.get("event"),
                    source=sample.get("source_file"),
                    path=sample.get("path"),
                    turn=sample.get("turn", ""),
                    effect=sample.get("effect", ""),
                    metric=sample.get("metric_key", ""),
                )
            )
        lines.append("")
    return "\n".join(lines).rstrip()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--evidence", type=Path, action="append")
    parser.add_argument("--card", action="append")
    parser.add_argument(
        "--deck-id",
        type=int,
        action="append",
        default=[],
        help="Include all card names from one or more local deck_cards deck ids.",
    )
    parser.add_argument("--stem", default="lorehold_card_exposure_profile_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    with connect(args.db) as conn:
        deck_cards = [
            card_name
            for deck_id in (args.deck_id or [])
            for card_name in deck_card_names(conn, deck_id)
        ]
        card_names = dedupe_preserve_order(
            [*(args.card or ([] if deck_cards else DEFAULT_TARGET_CARDS)), *deck_cards]
        )
        evidence_paths = args.evidence or default_evidence_paths()
        payload = build_profile(evidence_paths=evidence_paths, card_names=card_names, conn=conn)
    payload["source_db"] = str(args.db)
    payload["target_deck_ids"] = list(args.deck_id or [])
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload) + "\n", encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
