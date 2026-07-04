#!/usr/bin/env python3
"""Audit whether protected Lorehold 607 currently needs Restoration Seminar.

This helper is read-only. It does not create a candidate deck and does not run
a battle gate. Its job is narrower: verify whether Restoration Seminar has
real target demand in the current 607 shell and whether any cut lane is safe
enough to justify a later package test.
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

from master_optimizer_common import (
    resolve_default_knowledge_db,
    safe_cmc_from_card,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_DECK_ID = 607
RESTORATION_SEMINAR = "Restoration Seminar"

DEFAULT_EXPOSURE_PROFILES = [
    REPORT_DIR / "lorehold_recursion_cut_candidate_exposure_profile_20260627_v1.json",
    REPORT_DIR / "lorehold_card_exposure_profile_20260627_v1.json",
]
DEFAULT_TRACE_REPORTS = [
    REPORT_DIR / "lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json",
    REPORT_DIR / "lorehold_forced_exposure_probe_20260630_after_607_fix_20260630_043721_volcanic_recursion_cut_pinnacle.json",
]
DEFAULT_TRACE_REPORT_GLOBS = [
    "*lorehold*gate*.json",
    "*lorehold*probe*.json",
    "*lorehold*trace*.json",
    "*lorehold*checkpoint*.json",
    "*lorehold*confirm*.json",
]
DEFAULT_RECURSION_MODEL_REPORT = (
    REPORT_DIR / "lorehold_recursion_cut_model_20260704_cmc_safe_learning_after_baseline_cut_fix.json"
)

PROTECTED_ANCHORS = {
    "Lorehold, the Historian",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Approach of the Second Sun",
    "Victory Chimes",
    "Mizzix's Mastery",
    "Bender's Waterskin",
    "Jeska's Will",
    "Library of Leng",
}

ADDITIONAL_PROTECTED_607_CARDS = {
    "Molecule Man",
    "The Scarlet Witch",
    "The Mind Stone",
    "Insurrection",
    "Storm Herd",
    "Creative Technique",
}

TOPDECK_ENGINE_TARGETS = {
    "Sensei's Divining Top",
    "Scroll Rack",
    "Library of Leng",
    "Bender's Waterskin",
}

CORE_CUT_TAGS = {"board_wipe", "draw", "removal", "wincon", "protection", "ramp", "tutor"}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_existing_json(paths: Iterable[Path]) -> list[tuple[Path, dict[str, Any]]]:
    out: list[tuple[Path, dict[str, Any]]] = []
    for path in paths:
        if path.exists():
            out.append((path, read_json(path)))
    return out


def discover_trace_report_paths(globs: Iterable[str]) -> list[Path]:
    paths: list[Path] = []
    for pattern in globs:
        paths.extend(REPORT_DIR.glob(pattern))
    return sorted(set(path for path in paths if path.is_file()))


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def _json_list(value: object) -> list[str]:
    try:
        parsed = json.loads(str(value or "[]"))
    except Exception:
        return []
    if not isinstance(parsed, list):
        return []
    return [str(item) for item in parsed]


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    if sqlite_connection_has_table(conn, "card_oracle_cache"):
        from_sql = """
        FROM deck_cards dc
        LEFT JOIN card_oracle_cache coc
          ON coc.normalized_name = lower(dc.card_name)
        """
        mana_cost_sql = "coc.mana_cost AS mana_cost"
    else:
        from_sql = "FROM deck_cards dc"
        mana_cost_sql = "'' AS mana_cost"
    rows = conn.execute(
        f"""
        SELECT dc.card_name, dc.quantity, dc.functional_tag,
               dc.functional_tags_json, dc.type_line, dc.cmc, dc.is_commander,
               dc.oracle_text, {mana_cost_sql}
        {from_sql}
        WHERE dc.deck_id=?
        ORDER BY dc.is_commander DESC, dc.card_name
        """,
        (deck_id,),
    ).fetchall()
    cards: list[dict[str, Any]] = []
    for row in rows:
        cards.append(
            {
                "name": row["card_name"],
                "quantity": int(row["quantity"] or 1),
                "functional_tag": row["functional_tag"] or "",
                "functional_tags": _json_list(row["functional_tags_json"]),
                "type_line": row["type_line"] or "",
                "cmc": safe_cmc_from_card(row),
                "is_commander": bool(row["is_commander"]),
                "oracle_text": row["oracle_text"] or "",
                "mana_cost": row["mana_cost"] or "",
            }
        )
    return cards


def load_card_from_cache(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {"name": card_name}
    row = conn.execute(
        """
        SELECT name, mana_cost, type_line, oracle_text, cmc
        FROM card_oracle_cache
        WHERE normalized_name=lower(?)
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    if row is None:
        return {"name": card_name}
    return {
        "name": row["name"],
        "mana_cost": row["mana_cost"] or "",
        "type_line": row["type_line"] or "",
        "oracle_text": row["oracle_text"] or "",
        "cmc": safe_cmc_from_card(row),
    }


def find_variant_rows(conn: sqlite3.Connection, card_name: str) -> list[int]:
    rows = conn.execute(
        """
        SELECT DISTINCT deck_id
        FROM deck_cards
        WHERE lower(card_name)=lower(?)
        ORDER BY deck_id
        """,
        (card_name,),
    ).fetchall()
    return [int(row["deck_id"]) for row in rows]


def is_nonland_permanent(card: dict[str, Any]) -> bool:
    type_line = str(card.get("type_line") or "").lower()
    if card.get("is_commander"):
        return False
    if "land" in type_line:
        return False
    if "instant" in type_line or "sorcery" in type_line:
        return False
    permanent_types = ("artifact", "creature", "enchantment", "planeswalker", "battle")
    return any(kind in type_line for kind in permanent_types)


def is_restoration_bad_target(card: dict[str, Any]) -> bool:
    name = str(card.get("name") or "")
    tags = set(card.get("functional_tags") or [])
    if name in {"Sol Ring", "Arcane Signet", "Boros Signet", "Fellwar Stone", "Talisman of Conviction"}:
        return True
    if card.get("functional_tag") == "ramp" and float(card.get("cmc") or 0) <= 2:
        return True
    return bool(tags == {"ramp"} and float(card.get("cmc") or 0) <= 2)


def target_priority(card: dict[str, Any], graveyard_events: int = 0) -> dict[str, Any]:
    name = str(card.get("name") or "")
    tags = set(str(tag) for tag in (card.get("functional_tags") or []))
    role = str(card.get("functional_tag") or "")
    score = 0
    reasons: list[str] = []

    if name in PROTECTED_ANCHORS:
        score += 30
        reasons.append("protected_anchor")
    if name in TOPDECK_ENGINE_TARGETS:
        score += 30
        reasons.append("topdeck_miracle_engine")
    if role == "engine" or "engine" in tags:
        score += 12
        reasons.append("engine")
    if role == "tutor" or "tutor" in tags:
        score += 10
        reasons.append("access_piece")
    if "protection" in tags or role == "protection":
        score += 8
        reasons.append("protection_piece")
    if "ramp" in tags or role == "ramp":
        score += 6
        reasons.append("mana_piece")
    if "draw" in tags or role == "draw":
        score += 6
        reasons.append("card_flow_piece")
    if is_restoration_bad_target(card):
        score -= 10
        reasons.append("low_ceiling_ramp_target")
    if graveyard_events:
        score += min(25, 10 + graveyard_events * 3)
        reasons.append("observed_graveyard_target")

    return {
        "card": name,
        "role": role,
        "functional_tags": sorted(tags),
        "type_line": card.get("type_line") or "",
        "cmc": card.get("cmc"),
        "target_priority_score": score,
        "graveyard_event_count": int(graveyard_events),
        "reasons": reasons,
    }


def exposure_lookup(profiles: list[tuple[Path, dict[str, Any]]]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for path, payload in profiles:
        for row in payload.get("card_profiles") or []:
            name = row.get("card_name")
            if not name:
                continue
            candidate = dict(row)
            candidate["exposure_profile"] = str(path)
            key = normalize_key(name)
            current = out.get(key)
            if current is None or int(candidate.get("unique_exposure_count") or 0) >= int(
                current.get("unique_exposure_count") or 0
            ):
                out[key] = candidate
    return out


def profile_summary(card_name: str, exposures: dict[str, dict[str, Any]]) -> dict[str, Any]:
    row = exposures.get(normalize_key(card_name)) or {}
    rule = row.get("rule_summary") or {}
    decision = row.get("decision") or {}
    return {
        "profiled": bool(row),
        "unique_exposure_count": int(row.get("unique_exposure_count") or 0),
        "direct_event_count": int(row.get("direct_event_count") or 0),
        "inferred_role": row.get("inferred_role") or "unmeasured",
        "decision_status": decision.get("status") or "unmeasured",
        "role_signals": list(row.get("role_signals") or []),
        "active_rule_count": int(rule.get("active_rule_count") or 0),
        "battle_model_scopes": sorted((rule.get("battle_model_scopes") or {}).keys()),
        "rule_effects": sorted((rule.get("effects") or {}).keys()),
        "exposure_profile": row.get("exposure_profile") or "",
    }


def collect_graveyard_events(
    reports: list[tuple[Path, dict[str, Any]]],
    target_names: Iterable[str],
) -> dict[str, Any]:
    target_keys = {normalize_key(name): name for name in target_names}
    counts: Counter[str] = Counter()
    samples: list[dict[str, Any]] = []

    def visit(value: Any, source_path: Path, json_path: str = "") -> None:
        if isinstance(value, dict):
            event_name = value.get("event")
            data = value.get("data") if isinstance(value.get("data"), dict) else value
            card_name = data.get("card") or data.get("card_name") or value.get("card")
            from_zone = data.get("from_zone")
            to_zone = data.get("to_zone") or data.get("destination")
            if (
                event_name == "permanent_moved_from_battlefield"
                and normalize_key(card_name) in target_keys
                and (not from_zone or str(from_zone).lower() == "battlefield")
                and (not to_zone or str(to_zone).lower() == "graveyard")
            ):
                display_name = target_keys[normalize_key(card_name)]
                counts[display_name] += 1
                if len(samples) < 20:
                    samples.append(
                        {
                            "card": display_name,
                            "event": event_name,
                            "source_report": str(source_path),
                            "json_path": json_path,
                            "turn": data.get("turn"),
                            "reason": data.get("reason"),
                            "source": data.get("source"),
                            "game_id": value.get("game_id") or data.get("game_id"),
                        }
                    )
            for key, child in value.items():
                child_path = f"{json_path}.{key}" if json_path else str(key)
                visit(child, source_path, child_path)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                visit(child, source_path, f"{json_path}[{index}]")

    for path, payload in reports:
        visit(payload, path)
    return {
        "counts": dict(sorted(counts.items())),
        "samples": samples,
        "scan_summary": {
            "mode": "loaded_reports",
            "candidate_report_count": len(reports),
            "parsed_report_count": len(reports),
            "skipped_no_event_marker_count": 0,
            "skipped_no_target_marker_count": 0,
            "skipped_too_large_count": 0,
            "parse_error_count": 0,
            "parse_errors": [],
        },
    }


def _read_path_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return None


def collect_graveyard_events_from_paths(
    paths: list[Path],
    target_names: Iterable[str],
    *,
    max_report_mb: float | None = None,
) -> dict[str, Any]:
    target_names = sorted(set(str(name) for name in target_names if str(name)))
    target_needles = target_names + [json.dumps(name) for name in target_names]
    max_bytes = None if max_report_mb is None else int(max_report_mb * 1024 * 1024)
    counts: Counter[str] = Counter()
    samples: list[dict[str, Any]] = []
    parsed_report_count = 0
    skipped_no_event_marker_count = 0
    skipped_no_target_marker_count = 0
    skipped_too_large_count = 0
    parse_errors: list[dict[str, Any]] = []

    for path in paths:
        try:
            size = path.stat().st_size
        except OSError:
            parse_errors.append({"path": str(path), "error": "stat_failed"})
            continue
        if max_bytes is not None and size > max_bytes:
            skipped_too_large_count += 1
            continue
        text = _read_path_text(path)
        if text is None:
            parse_errors.append({"path": str(path), "error": "read_failed"})
            continue
        if "permanent_moved_from_battlefield" not in text:
            skipped_no_event_marker_count += 1
            continue
        if not any(needle in text for needle in target_needles):
            skipped_no_target_marker_count += 1
            continue
        try:
            payload = read_json(path)
        except Exception as exc:
            parse_errors.append({"path": str(path), "error": str(exc)[:240]})
            continue
        parsed_report_count += 1
        result = collect_graveyard_events([(path, payload)], target_names)
        counts.update(result["counts"])
        samples.extend(result["samples"])

    return {
        "counts": dict(sorted(counts.items())),
        "samples": samples[:20],
        "scan_summary": {
            "mode": "discovered_report_paths",
            "candidate_report_count": len(paths),
            "parsed_report_count": parsed_report_count,
            "skipped_no_event_marker_count": skipped_no_event_marker_count,
            "skipped_no_target_marker_count": skipped_no_target_marker_count,
            "skipped_too_large_count": skipped_too_large_count,
            "parse_error_count": len(parse_errors),
            "parse_errors": parse_errors[:20],
            "max_report_mb": max_report_mb,
        },
    }


def cut_review(card: dict[str, Any], exposures: dict[str, dict[str, Any]]) -> dict[str, Any]:
    name = str(card.get("name") or "")
    tags = set(str(tag) for tag in (card.get("functional_tags") or []))
    role = str(card.get("functional_tag") or "")
    blockers: list[str] = []
    cautions: list[str] = []
    profile = profile_summary(name, exposures)

    if card.get("is_commander"):
        blockers.append("cut_is_commander")
    if "land" in str(card.get("type_line") or "").lower():
        blockers.append("cut_is_land")
    if name in PROTECTED_ANCHORS or name in ADDITIONAL_PROTECTED_607_CARDS:
        blockers.append("cut_is_protected_anchor_or_prior_guardrail")
    for tag in sorted((tags | {role}) & CORE_CUT_TAGS):
        blockers.append(f"cut_has_core_tag:{tag}")
    if is_nonland_permanent(card) and target_priority(card)["target_priority_score"] >= 30:
        cautions.append("cut_removes_meaningful_restoration_target")
    if int(profile["unique_exposure_count"]) >= 40:
        blockers.append(f"cut_has_high_exposure:{profile['unique_exposure_count']}")
    elif int(profile["unique_exposure_count"]) > 0:
        cautions.append(f"cut_has_some_exposure:{profile['unique_exposure_count']}")

    status = "blocked" if blockers else "manual_review_only"
    return {
        "card": name,
        "role": role,
        "functional_tags": sorted(tags),
        "type_line": card.get("type_line") or "",
        "cmc": card.get("cmc"),
        "status": status,
        "blockers": blockers,
        "cautions": cautions,
        "exposure": profile,
    }


def summarize_recursion_model(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"available": False, "path": str(path)}
    payload = read_json(path)
    return {
        "available": True,
        "path": str(path),
        "summary": payload.get("summary") or {},
    }


def build_audit(
    *,
    conn: sqlite3.Connection,
    deck_id: int,
    db_path: Path,
    exposure_profiles: list[tuple[Path, dict[str, Any]]],
    trace_reports: list[tuple[Path, dict[str, Any]]],
    trace_report_paths: list[Path] | None,
    max_trace_report_mb: float | None,
    recursion_model_report: Path,
) -> dict[str, Any]:
    deck_cards = load_deck_cards(conn, deck_id)
    exposures = exposure_lookup(exposure_profiles)
    target_cards = [card for card in deck_cards if is_nonland_permanent(card)]
    target_names = [str(card["name"]) for card in target_cards]
    if trace_report_paths is not None:
        graveyard_events = collect_graveyard_events_from_paths(
            trace_report_paths,
            target_names,
            max_report_mb=max_trace_report_mb,
        )
    else:
        graveyard_events = collect_graveyard_events(trace_reports, target_names)
    target_rows = [
        target_priority(card, int(graveyard_events["counts"].get(str(card["name"]), 0)))
        for card in target_cards
    ]
    target_rows.sort(key=lambda row: (-int(row["target_priority_score"]), row["card"]))
    cut_rows = [cut_review(card, exposures) for card in deck_cards]
    cut_rows.sort(
        key=lambda row: (
            0 if row["status"] == "manual_review_only" else 1,
            len(row["blockers"]),
            row["card"],
        )
    )
    manual_cut_rows = [row for row in cut_rows if row["status"] == "manual_review_only"]
    restoration_profile = profile_summary(RESTORATION_SEMINAR, exposures)
    trace_event_count = sum(int(value) for value in graveyard_events["counts"].values())
    recursion_model = summarize_recursion_model(recursion_model_report)
    preflight_ready_count = int(
        ((recursion_model.get("summary") or {}).get("preflight_benchmark_ready_count") or 0)
    )

    if trace_event_count <= 0:
        status = "blocked_no_current_target_graveyard_trace"
        next_action = "mine_or_generate_restoration_target_trace_before_cut"
    elif preflight_ready_count <= 0:
        status = "blocked_no_seed_safe_cut"
        next_action = "manual_cut_review_before_any_restoration_gate"
    else:
        status = "learning_probe_ready_not_promotion"
        next_action = "build_forced_access_learning_probe_then_natural_gate_if_positive"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_restoration_seminar_need_audit",
        "status": status,
        "recommended_next_action": next_action,
        "deck_id": deck_id,
        "source_db": str(db_path),
        "postgres_writes": False,
        "source_db_mutated": False,
        "restoration_seminar": load_card_from_cache(conn, RESTORATION_SEMINAR),
        "restoration_profile": restoration_profile,
        "restoration_variant_deck_ids": find_variant_rows(conn, RESTORATION_SEMINAR),
        "trace_reports": [str(path) for path, _payload in trace_reports],
        "trace_report_paths": [str(path) for path in trace_report_paths or []],
        "trace_scan_summary": graveyard_events.get("scan_summary") or {},
        "exposure_profiles": [str(path) for path, _payload in exposure_profiles],
        "recursion_model": recursion_model,
        "summary": {
            "deck_card_rows": len(deck_cards),
            "nonland_permanent_target_count": len(target_cards),
            "high_priority_target_count": sum(
                1 for row in target_rows if int(row["target_priority_score"]) >= 30
            ),
            "target_graveyard_event_count": trace_event_count,
            "manual_review_cut_count": len(manual_cut_rows),
            "blocked_cut_count": len(cut_rows) - len(manual_cut_rows),
            "preflight_ready_count_from_recursion_model": preflight_ready_count,
        },
        "target_graveyard_events": graveyard_events,
        "top_targets": target_rows[:25],
        "manual_review_cuts": manual_cut_rows[:25],
        "blocked_cut_samples": [row for row in cut_rows if row["status"] == "blocked"][:25],
        "guardrails": [
            "Restoration Seminar cannot be promoted from external popularity alone.",
            "A positive claim requires observed/reproduced nonland permanent target demand.",
            "Any add still needs a named cut that does not remove protected 607 anchors.",
            "Forced-access probes are learning-only until a natural equal gate ties or beats 607.",
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Restoration Seminar Need Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Recommended next action: `{payload['recommended_next_action']}`",
        f"- Deck id: `{payload['deck_id']}`",
        f"- Source DB: `{payload['source_db']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        f"- Trace scan mode: `{payload.get('trace_scan_summary', {}).get('mode', 'unknown')}`",
        "",
        "## Summary",
        "",
        f"- Nonland permanent target count: `{summary['nonland_permanent_target_count']}`",
        f"- High-priority target count: `{summary['high_priority_target_count']}`",
        f"- Observed target graveyard events: `{summary['target_graveyard_event_count']}`",
        f"- Manual-review cut count: `{summary['manual_review_cut_count']}`",
        f"- Blocked cut count: `{summary['blocked_cut_count']}`",
        f"- Recursion-model preflight-ready count: `{summary['preflight_ready_count_from_recursion_model']}`",
        f"- Trace candidate reports: `{payload.get('trace_scan_summary', {}).get('candidate_report_count', 0)}`",
        f"- Trace parsed reports: `{payload.get('trace_scan_summary', {}).get('parsed_report_count', 0)}`",
        "",
        "## Restoration Seminar",
        "",
        f"- Mana cost: `{payload['restoration_seminar'].get('mana_cost', '')}`",
        f"- Safe CMC: `{payload['restoration_seminar'].get('cmc', '')}`",
        f"- Type: `{payload['restoration_seminar'].get('type_line', '')}`",
        f"- Variant deck ids: `{payload['restoration_variant_deck_ids']}`",
        f"- Active rule count: `{payload['restoration_profile']['active_rule_count']}`",
        f"- Natural exposure count: `{payload['restoration_profile']['unique_exposure_count']}`",
        "",
        "## Top Restoration Targets In 607",
        "",
        "| Rank | Card | Role | Score | Graveyard Events | Reasons |",
        "| ---: | --- | --- | ---: | ---: | --- |",
    ]
    for index, row in enumerate(payload["top_targets"][:15], start=1):
        lines.append(
            "| {rank} | {card} | `{role}` | {score} | {events} | {reasons} |".format(
                rank=index,
                card=row["card"],
                role=row["role"],
                score=row["target_priority_score"],
                events=row["graveyard_event_count"],
                reasons=", ".join(row["reasons"]) or "-",
            )
        )
    lines.extend(
        [
            "",
            "## Trace Evidence",
            "",
        ]
    )
    if not payload["target_graveyard_events"]["samples"]:
        lines.append("- No consumed trace showed a current 607 Restoration target moving from battlefield to graveyard.")
    else:
        lines.extend(["| Card | Turn | Reason | Source Report |", "| --- | ---: | --- | --- |"])
        for sample in payload["target_graveyard_events"]["samples"][:10]:
            lines.append(
                "| {card} | {turn} | {reason} | `{source}` |".format(
                    card=sample["card"],
                    turn=sample.get("turn") if sample.get("turn") is not None else "",
                    reason=sample.get("reason") or "",
                    source=sample["source_report"],
                )
            )
    scan = payload.get("trace_scan_summary") or {}
    lines.extend(
        [
            "",
            "### Trace Scan Summary",
            "",
            f"- Candidate reports: `{scan.get('candidate_report_count', 0)}`",
            f"- Parsed reports: `{scan.get('parsed_report_count', 0)}`",
            f"- Skipped without event marker: `{scan.get('skipped_no_event_marker_count', 0)}`",
            f"- Skipped without target marker: `{scan.get('skipped_no_target_marker_count', 0)}`",
            f"- Skipped too large: `{scan.get('skipped_too_large_count', 0)}`",
            f"- Parse errors: `{scan.get('parse_error_count', 0)}`",
        ]
    )
    lines.extend(
        [
            "",
            "## Manual-Review Cut Candidates",
            "",
            "| Rank | Card | Role | CMC | Cautions |",
            "| ---: | --- | --- | ---: | --- |",
        ]
    )
    for index, row in enumerate(payload["manual_review_cuts"][:15], start=1):
        lines.append(
            "| {rank} | {card} | `{role}` | {cmc} | {cautions} |".format(
                rank=index,
                card=row["card"],
                role=row["role"],
                cmc=row["cmc"],
                cautions=", ".join(row["cautions"]) or "-",
            )
        )
    lines.extend(
        [
            "",
            "## Guardrails",
            "",
        ]
    )
    for guardrail in payload["guardrails"]:
        lines.append(f"- {guardrail}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--exposure-profile", type=Path, action="append")
    parser.add_argument("--trace-report", type=Path, action="append")
    parser.add_argument("--discover-trace-reports", action="store_true")
    parser.add_argument("--trace-report-glob", action="append", default=[])
    parser.add_argument("--max-trace-report-mb", type=float)
    parser.add_argument("--recursion-model-report", type=Path, default=DEFAULT_RECURSION_MODEL_REPORT)
    parser.add_argument("--stem", default="lorehold_restoration_seminar_need_audit_20260704")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    exposure_profiles = read_existing_json(args.exposure_profile or DEFAULT_EXPOSURE_PROFILES)
    trace_report_paths: list[Path] | None = None
    if args.discover_trace_reports:
        trace_report_paths = discover_trace_report_paths(args.trace_report_glob or DEFAULT_TRACE_REPORT_GLOBS)
        trace_reports: list[tuple[Path, dict[str, Any]]] = []
    else:
        trace_reports = read_existing_json(args.trace_report or DEFAULT_TRACE_REPORTS)
    with connect(args.db) as conn:
        payload = build_audit(
            conn=conn,
            deck_id=args.deck_id,
            db_path=args.db,
            exposure_profiles=exposure_profiles,
            trace_reports=trace_reports,
            trace_report_paths=trace_report_paths,
            max_trace_report_mb=args.max_trace_report_mb,
            recursion_model_report=args.recursion_model_report,
        )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
