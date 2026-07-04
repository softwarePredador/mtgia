#!/usr/bin/env python3
"""Audit whether protected Lorehold 607 currently needs Soulfire Eruption.

This helper is read-only. It does not create a candidate deck, mutate SQLite,
or write PostgreSQL. It turns external/public signal plus current local runtime
and cut evidence into a conservative next action for the 607 learning goal.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from master_optimizer_common import (
    load_dynamic_protected_cards,
    resolve_default_knowledge_db,
    safe_cmc_from_card,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_DECK_ID = 607
SOULFIRE_ERUPTION = "Soulfire Eruption"

DEFAULT_EXPOSURE_PROFILES = [
    REPORT_DIR / "lorehold_recursion_cut_candidate_exposure_profile_20260627_v1.json",
    REPORT_DIR / "lorehold_card_exposure_profile_20260627_v1.json",
]
DEFAULT_TRACE_REPORT_GLOBS = [
    "*lorehold*gate*.json",
    "*lorehold*probe*.json",
    "*lorehold*trace*.json",
    "*lorehold*checkpoint*.json",
    "lorehold_from_scratch_challengers_*.json",
]
DEFAULT_RECENT_GATE_REPORTS = [
    REPORT_DIR / "lorehold_from_scratch_challengers_20260703_current_miracle_pressure_conversion_fixed607_gate.json",
    REPORT_DIR / "lorehold_from_scratch_challengers_20260703_current_recursion_discard_pressure_repair_fixed607_gate.json",
]
DEFAULT_REMOVAL_LANE_REPORT = (
    REPORT_DIR / "lorehold_profiled_cut_benchmark_generator_20260630_removal_lane_audit.json"
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
    "Creative Technique",
    "Insurrection",
    "Molecule Man",
    "Rise of the Eldrazi",
    "Storm Herd",
    "The Mind Stone",
}

SOULFIRE_LANE_TAGS = {
    "board_wipe",
    "deal_damage",
    "draw",
    "exile_value",
    "removal",
    "token_maker",
    "wincon",
    "wipe",
}
SOULFIRE_LANE_EFFECTS = {
    "board_wipe",
    "composite_resolution",
    "damage_wipe",
    "deal_damage",
    "exile_artifact_enchantment_creature_convoke_wipe",
    "exile_top_nonland_free_cast",
    "exile_value",
    "fated_clash_protect_then_destroy",
    "steal_all_creatures",
    "token_maker",
    "vow_counter_each_player_sacrifice_rest",
}
NONREPLACEMENT_CORE_TAGS = {"engine", "land", "protection", "ramp", "tutor"}
TRACE_USE_EVENTS = {
    "board_wipe_resolved",
    "cast_announced",
    "cost_paid",
    "damage_resolved",
    "deal_damage",
    "miracle_cast",
    "spell_cast",
    "spell_resolved",
    "trigger_resolved",
}


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


def discover_report_paths(globs: Iterable[str]) -> list[Path]:
    paths: list[Path] = []
    for pattern in globs:
        paths.extend(REPORT_DIR.glob(pattern))
    return sorted(set(path for path in paths if path.is_file()))


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def json_list(value: object) -> list[str]:
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
                "functional_tags": json_list(row["functional_tags_json"]),
                "type_line": row["type_line"] or "",
                "cmc": safe_cmc_from_card(row),
                "raw_cmc": row["cmc"],
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
        "raw_cmc": row["cmc"],
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


def load_rule_summaries(
    conn: sqlite3.Connection,
    names: Iterable[str],
) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in names if str(name).strip()}
    out: dict[str, dict[str, Any]] = {
        key: {
            "card_name": name,
            "rule_count": 0,
            "active_rule_count": 0,
            "effects": Counter(),
            "battle_model_scopes": Counter(),
            "active_effects": Counter(),
            "active_battle_model_scopes": Counter(),
            "active_effect_jsons": [],
            "execution_statuses": Counter(),
            "review_statuses": Counter(),
        }
        for key, name in wanted.items()
    }
    if not out or not sqlite_connection_has_table(conn, "battle_card_rules"):
        return out
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, execution_status, review_status, effect_json
        FROM battle_card_rules
        ORDER BY card_name
        """
    ).fetchall()
    for row in rows:
        forms = {normalize_key(row["card_name"]), normalize_key(row["normalized_name"])}
        key = next((item for item in forms if item in wanted), "")
        if not key:
            continue
        summary = out[key]
        execution_status = str(row["execution_status"] or "")
        review_status = str(row["review_status"] or "")
        summary["rule_count"] += 1
        summary["execution_statuses"][execution_status] += 1
        summary["review_statuses"][review_status] += 1
        is_active = execution_status in {"active", "auto", "reviewed", "verified"} and review_status in {
            "active",
            "needs_review",
            "reviewed",
            "verified",
        }
        if is_active:
            summary["active_rule_count"] += 1
        try:
            effect_json = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect_json = {}
        if not isinstance(effect_json, dict):
            continue
        effect = str(effect_json.get("effect") or "")
        scope = str(effect_json.get("battle_model_scope") or "")
        if effect:
            summary["effects"][effect] += 1
            if is_active:
                summary["active_effects"][effect] += 1
        if scope:
            summary["battle_model_scopes"][scope] += 1
            if is_active:
                summary["active_battle_model_scopes"][scope] += 1
        if is_active:
            summary["active_effect_jsons"].append(effect_json)
    return {
        key: {
            **value,
            "effects": dict(sorted(value["effects"].items())),
            "battle_model_scopes": dict(sorted(value["battle_model_scopes"].items())),
            "active_effects": dict(sorted(value["active_effects"].items())),
            "active_battle_model_scopes": dict(sorted(value["active_battle_model_scopes"].items())),
            "active_effect_jsons": value["active_effect_jsons"],
            "execution_statuses": dict(sorted(value["execution_statuses"].items())),
            "review_statuses": dict(sorted(value["review_statuses"].items())),
        }
        for key, value in out.items()
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


def profile_summary(card_name: str, exposures: Mapping[str, dict[str, Any]]) -> dict[str, Any]:
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


def card_lane_match(card: Mapping[str, Any], rule: Mapping[str, Any]) -> bool:
    name = str(card.get("name") or card.get("card_name") or "")
    if normalize_key(name) == normalize_key(SOULFIRE_ERUPTION):
        return True
    type_line = str(card.get("type_line") or "")
    if "land" in type_line.lower():
        return False
    tags = {str(tag) for tag in (card.get("functional_tags") or [])}
    role = str(card.get("functional_tag") or "")
    effects = set((rule.get("active_effects") or {}).keys())
    cmc = float(card.get("cmc") or 0)
    if cmc < 5:
        return False
    if tags & SOULFIRE_LANE_TAGS or role in SOULFIRE_LANE_TAGS:
        return True
    return bool(effects & SOULFIRE_LANE_EFFECTS)


def lane_score(card: Mapping[str, Any], rule: Mapping[str, Any]) -> dict[str, Any]:
    tags = {str(tag) for tag in (card.get("functional_tags") or [])}
    role = str(card.get("functional_tag") or "")
    effects = set((rule.get("active_effects") or {}).keys())
    score = 0
    reasons: list[str] = []
    if tags & {"removal", "deal_damage", "board_wipe", "wipe"} or role in {
        "removal",
        "board_wipe",
    }:
        score += 20
        reasons.append("pressure_answer")
    if tags & {"draw", "exile_value"} or role == "draw" or effects & {
        "exile_value",
        "exile_top_nonland_free_cast",
    }:
        score += 18
        reasons.append("impulse_or_freecast_value")
    if tags & {"wincon", "token_maker"} or role == "wincon" or effects & {
        "token_maker",
        "steal_all_creatures",
    }:
        score += 16
        reasons.append("closing_payoff")
    if float(card.get("cmc") or 0) >= 7:
        score += 8
        reasons.append("high_mana_value_miracle_payoff")
    if "Sorcery" in str(card.get("type_line") or ""):
        score += 4
        reasons.append("lorehold_discountable_sorcery")
    return {
        "score": score,
        "reasons": reasons,
    }


def cut_review(
    card: Mapping[str, Any],
    rule: Mapping[str, Any],
    exposures: Mapping[str, dict[str, Any]],
    protected_cards: set[str],
) -> dict[str, Any]:
    name = str(card.get("name") or "")
    tags = {str(tag) for tag in (card.get("functional_tags") or [])}
    role = str(card.get("functional_tag") or "")
    blockers: list[str] = []
    cautions: list[str] = []
    profile = profile_summary(name, exposures)
    match = card_lane_match(card, rule)

    if card.get("is_commander"):
        blockers.append("cut_is_commander")
    if "land" in str(card.get("type_line") or "").lower():
        blockers.append("cut_is_land")
    if not match:
        blockers.append("cut_not_soulfire_lane")
    if name in protected_cards:
        blockers.append("cut_is_protected_anchor_or_prior_guardrail")
    for tag in sorted((tags | {role}) & NONREPLACEMENT_CORE_TAGS):
        blockers.append(f"cut_has_nonreplacement_core_tag:{tag}")
    if float(card.get("cmc") or 0) <= 3 and (role == "removal" or "removal" in tags):
        blockers.append("cut_removes_cheap_interaction_for_nine_mana_spell")
    if int(profile["unique_exposure_count"]) >= 40:
        blockers.append(f"cut_has_high_exposure:{profile['unique_exposure_count']}")
    elif int(profile["unique_exposure_count"]) > 0:
        cautions.append(f"cut_has_some_exposure:{profile['unique_exposure_count']}")
    if (tags | {role}) & {"board_wipe", "draw", "removal", "wincon"}:
        cautions.append("cut_removes_current_core_payoff_or_answer")
    if float(card.get("cmc") or 0) < 5:
        cautions.append("cut_lowers_curve_pressure_badly")

    lane = lane_score(card, rule)
    status = "blocked" if blockers else "manual_review_only"
    return {
        "card": name,
        "role": role,
        "functional_tags": sorted(tags),
        "type_line": card.get("type_line") or "",
        "cmc": card.get("cmc"),
        "status": status,
        "lane_match": match,
        "lane_score": lane["score"],
        "lane_reasons": lane["reasons"],
        "blockers": blockers,
        "cautions": cautions,
        "rule": {
            "active_rule_count": int(rule.get("active_rule_count") or 0),
            "active_effects": rule.get("active_effects") or {},
            "active_battle_model_scopes": rule.get("active_battle_model_scopes") or {},
        },
        "exposure": profile,
    }


def _read_path_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return None


def split_card_metric_key(value: object) -> tuple[str, str]:
    raw = str(value or "")
    if ":" not in raw:
        return raw, ""
    event_name, card_name = raw.split(":", 1)
    return event_name, card_name


def int_count(value: object, default: int = 1) -> int:
    try:
        parsed = int(value)
    except Exception:
        return default
    return max(parsed, 0)


def collect_card_events_from_paths(
    paths: list[Path],
    card_name: str,
    *,
    max_report_mb: float | None = None,
) -> dict[str, Any]:
    card_key = normalize_key(card_name)
    max_bytes = None if max_report_mb is None else int(max_report_mb * 1024 * 1024)
    event_counts: Counter[str] = Counter()
    use_event_counts: Counter[str] = Counter()
    samples: list[dict[str, Any]] = []
    parsed_report_count = 0
    skipped_no_target_marker_count = 0
    skipped_too_large_count = 0
    parse_errors: list[dict[str, Any]] = []

    def record_event(
        event_name: str,
        source_path: Path,
        json_path: str,
        *,
        count: int = 1,
        turn: Any = None,
        phase: Any = None,
        game_id: Any = None,
    ) -> None:
        event_counts[event_name] += count
        if event_name in TRACE_USE_EVENTS:
            use_event_counts[event_name] += count
        if len(samples) < 25:
            samples.append(
                {
                    "event": event_name,
                    "count": count,
                    "source_report": str(source_path),
                    "json_path": json_path,
                    "turn": turn,
                    "phase": phase,
                    "game_id": game_id,
                }
            )

    def visit(value: Any, source_path: Path, json_path: str = "") -> None:
        if isinstance(value, dict):
            for metric_key, metric_value in value.items():
                event_name, metric_card = split_card_metric_key(metric_key)
                if normalize_key(metric_card) == card_key:
                    record_event(
                        event_name,
                        source_path,
                        f"{json_path}.{metric_key}" if json_path else str(metric_key),
                        count=int_count(metric_value),
                    )
            event_name_from_key, card_from_key = split_card_metric_key(value.get("key"))
            if normalize_key(card_from_key) == card_key:
                record_event(
                    event_name_from_key,
                    source_path,
                    f"{json_path}.key" if json_path else "key",
                    count=int_count(value.get("count")),
                )
            data = value.get("data") if isinstance(value.get("data"), dict) else value
            found_card = (
                data.get("card")
                or data.get("card_name")
                or data.get("name")
                or value.get("card")
                or value.get("card_name")
            )
            if normalize_key(found_card) == card_key:
                event_name = str(value.get("event") or data.get("event") or "card_reference")
                record_event(
                    event_name,
                    source_path,
                    json_path,
                    turn=data.get("turn"),
                    phase=data.get("phase"),
                    game_id=value.get("game_id") or data.get("game_id"),
                )
            for key, child in value.items():
                if key == "data" and isinstance(child, dict):
                    continue
                child_path = f"{json_path}.{key}" if json_path else str(key)
                visit(child, source_path, child_path)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                visit(child, source_path, f"{json_path}[{index}]")

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
        if card_name not in text:
            skipped_no_target_marker_count += 1
            continue
        try:
            payload = read_json(path)
        except Exception as exc:
            parse_errors.append({"path": str(path), "error": str(exc)[:240]})
            continue
        parsed_report_count += 1
        visit(payload, path)

    return {
        "event_counts": dict(sorted(event_counts.items())),
        "use_event_counts": dict(sorted(use_event_counts.items())),
        "samples": samples,
        "scan_summary": {
            "mode": "discovered_report_paths",
            "candidate_report_count": len(paths),
            "parsed_report_count": parsed_report_count,
            "skipped_no_target_marker_count": skipped_no_target_marker_count,
            "skipped_too_large_count": skipped_too_large_count,
            "parse_error_count": len(parse_errors),
            "parse_errors": parse_errors[:20],
            "max_report_mb": max_report_mb,
        },
    }


def collect_metric_counts(value: Any, card_name: str) -> Counter[str]:
    card_key = normalize_key(card_name)
    counts: Counter[str] = Counter()

    def visit(item: Any) -> None:
        if isinstance(item, dict):
            for metric_key, metric_value in item.items():
                event_name, metric_card = split_card_metric_key(metric_key)
                if normalize_key(metric_card) == card_key:
                    counts[event_name] += int_count(metric_value)
            event_name_from_key, card_from_key = split_card_metric_key(item.get("key"))
            if normalize_key(card_from_key) == card_key:
                counts[event_name_from_key] += int_count(item.get("count"))
            for child_key, child in item.items():
                if child_key == "data" and isinstance(child, dict):
                    continue
                visit(child)
        elif isinstance(item, list):
            for child in item:
                visit(child)

    visit(value)
    return counts


def summarize_existing_soulfire_results(
    paths: list[Path],
    *,
    max_report_mb: float | None = None,
) -> dict[str, Any]:
    max_bytes = None if max_report_mb is None else int(max_report_mb * 1024 * 1024)
    result_rows: list[dict[str, Any]] = []
    skipped_too_large_count = 0
    parsed_report_count = 0
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
        if text is None or SOULFIRE_ERUPTION not in text:
            continue
        try:
            payload = read_json(path)
        except Exception as exc:
            parse_errors.append({"path": str(path), "error": str(exc)[:240]})
            continue
        parsed_report_count += 1
        baseline_rows = [
            result for result in (payload.get("results") or []) if result.get("deck_key") == "deck_607"
        ]
        best_baseline = baseline_rows[0] if baseline_rows else {}
        for result in payload.get("results") or []:
            metrics = collect_metric_counts(result, SOULFIRE_ERUPTION)
            has_static_reference = SOULFIRE_ERUPTION in json.dumps(
                result.get("construction_report") or result.get("final_deck") or {},
                sort_keys=True,
            )
            if not metrics and not has_static_reference:
                continue
            wins = int(result.get("wins") or 0)
            losses = int(result.get("losses") or 0)
            result_rows.append(
                {
                    "source": str(path),
                    "deck_key": result.get("deck_key"),
                    "forced_access_mode": result.get("forced_access_mode") or payload.get("forced_access_mode") or "none",
                    "wins": wins,
                    "losses": losses,
                    "stalls": int(result.get("stalls") or 0),
                    "win_rate": result.get("win_rate"),
                    "soulfire_metric_counts": dict(sorted(metrics.items())),
                    "soulfire_use_event_count": sum(
                        count for event, count in metrics.items() if event in TRACE_USE_EVENTS
                    ),
                    "baseline_607_wins": int(best_baseline.get("wins") or 0),
                    "baseline_607_losses": int(best_baseline.get("losses") or 0),
                    "baseline_607_win_rate": best_baseline.get("win_rate"),
                    "delta_wins_vs_607": wins - int(best_baseline.get("wins") or 0)
                    if best_baseline
                    else None,
                }
            )
    negative_rows = [
        row
        for row in result_rows
        if row.get("delta_wins_vs_607") is not None and int(row["delta_wins_vs_607"]) < 0
    ]
    return {
        "parsed_report_count": parsed_report_count,
        "skipped_too_large_count": skipped_too_large_count,
        "parse_error_count": len(parse_errors),
        "parse_errors": parse_errors[:20],
        "result_count": len(result_rows),
        "negative_vs_607_count": len(negative_rows),
        "rows": result_rows[:25],
    }


def summarize_recent_607_gates(paths: Iterable[Path]) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    totals: Counter[str] = Counter()
    strategic_totals: Counter[str] = Counter()
    for path in paths:
        if not path.exists():
            continue
        payload = read_json(path)
        for result in payload.get("results") or []:
            if result.get("deck_key") != "deck_607":
                continue
            rows.append(
                {
                    "source": str(path),
                    "deck_key": result.get("deck_key"),
                    "wins": int(result.get("wins") or result.get("win_count") or 0),
                    "losses": int(result.get("losses") or result.get("loss_count") or 0),
                    "stalls": int(result.get("stalls") or result.get("stall_count") or 0),
                    "win_rate": result.get("win_rate"),
                    "strategic_event_counts": result.get("strategic_event_counts") or {},
                }
            )
            for game in result.get("game_results") or []:
                if game.get("result") == "loss":
                    totals["losses"] += 1
                elif game.get("result") == "win":
                    totals["wins"] += 1
                else:
                    totals["stalls"] += 1
                for key, value in (game.get("strategic_event_counts") or {}).items():
                    try:
                        strategic_totals[str(key)] += int(value or 0)
                    except Exception:
                        continue
    return {
        "report_count": len(rows),
        "rows": rows,
        "game_result_totals": dict(sorted(totals.items())),
        "strategic_event_totals": dict(sorted(strategic_totals.items())),
    }


def summarize_removal_lane_report(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"available": False, "path": str(path)}
    payload = read_json(path)
    top_rows = payload.get("top_pair_evaluations") or []
    soulfire_rows = [
        row for row in top_rows if SOULFIRE_ERUPTION in json.dumps(row, sort_keys=True)
    ]
    return {
        "available": True,
        "path": str(path),
        "summary": payload.get("summary") or {},
        "soulfire_pair_count": len(soulfire_rows),
        "soulfire_rows": soulfire_rows[:10],
    }


def build_audit(
    *,
    conn: sqlite3.Connection,
    deck_id: int,
    db_path: Path,
    exposure_profiles: list[tuple[Path, dict[str, Any]]],
    trace_report_paths: list[Path],
    max_trace_report_mb: float | None,
    recent_gate_reports: list[Path],
    removal_lane_report: Path,
    dynamic_protected_cards: set[str] | None = None,
) -> dict[str, Any]:
    deck_cards = load_deck_cards(conn, deck_id)
    exposures = exposure_lookup(exposure_profiles)
    soulfire_card = load_card_from_cache(conn, SOULFIRE_ERUPTION)
    all_names = [str(card["name"]) for card in deck_cards] + [SOULFIRE_ERUPTION]
    rule_summaries = load_rule_summaries(conn, all_names)
    protected_cards = set(PROTECTED_ANCHORS) | set(ADDITIONAL_PROTECTED_607_CARDS)
    if dynamic_protected_cards is None:
        protected_cards |= load_dynamic_protected_cards()
    else:
        protected_cards |= dynamic_protected_cards

    competitor_rows = [
        cut_review(
            card,
            rule_summaries.get(normalize_key(card["name"]), {}),
            exposures,
            protected_cards,
        )
        for card in deck_cards
        if card_lane_match(card, rule_summaries.get(normalize_key(card["name"]), {}))
    ]
    competitor_rows.sort(
        key=lambda row: (
            0 if row["status"] == "manual_review_only" else 1,
            -int(row["lane_score"]),
            row["card"],
        )
    )
    manual_rows = [row for row in competitor_rows if row["status"] == "manual_review_only"]
    blocked_rows = [row for row in competitor_rows if row["status"] == "blocked"]
    trace_events = collect_card_events_from_paths(
        trace_report_paths,
        SOULFIRE_ERUPTION,
        max_report_mb=max_trace_report_mb,
    )
    existing_soulfire_results = summarize_existing_soulfire_results(
        trace_report_paths,
        max_report_mb=max_trace_report_mb,
    )
    recent_gate_summary = summarize_recent_607_gates(recent_gate_reports)
    removal_lane_summary = summarize_removal_lane_report(removal_lane_report)
    soulfire_rule = rule_summaries.get(normalize_key(SOULFIRE_ERUPTION), {})
    active_rule_count = int(soulfire_rule.get("active_rule_count") or 0)
    use_event_count = sum(int(value) for value in trace_events["use_event_counts"].values())

    if active_rule_count <= 0:
        status = "blocked_runtime_missing"
        next_action = "create_or_verify_soulfire_runtime_before_deck_test"
    elif not manual_rows:
        status = "blocked_no_nonprotected_same_lane_cut"
        next_action = "do_not_gate_soulfire_until_same_lane_cut_exists"
    elif int(existing_soulfire_results.get("negative_vs_607_count") or 0) > 0:
        status = "blocked_existing_soulfire_shell_underperformed"
        next_action = "do_not_repeat_broad_soulfire_shell_without_new_named_cut_hypothesis"
    elif use_event_count <= 0:
        status = "blocked_no_soulfire_use_trace"
        next_action = "run_forced_access_learning_probe_before_natural_gate"
    else:
        status = "learning_probe_ready_not_promotion"
        next_action = "build_named_add_cut_probe_then_require_natural_equal_gate"

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_soulfire_eruption_need_audit",
        "status": status,
        "recommended_next_action": next_action,
        "deck_id": deck_id,
        "source_db": str(db_path),
        "postgres_writes": False,
        "source_db_mutated": False,
        "soulfire_eruption": soulfire_card,
        "soulfire_rule": soulfire_rule,
        "soulfire_variant_deck_ids": find_variant_rows(conn, SOULFIRE_ERUPTION),
        "external_signal_summary": {
            "edhrec_lorehold_inclusion": "strong_lorehold_specific_signal_checked_2026_07_04",
            "draftsim_lorehold_guide": "high_ceiling_nine_mana_or_miracle_payoff_checked_2026_07_04",
            "interpretation": "hypothesis_source_not_auto_include",
        },
        "trace_report_paths": [str(path) for path in trace_report_paths],
        "trace_events": trace_events,
        "exposure_profiles": [str(path) for path, _payload in exposure_profiles],
        "recent_607_gate_summary": recent_gate_summary,
        "removal_lane_summary": removal_lane_summary,
        "existing_soulfire_results": existing_soulfire_results,
        "summary": {
            "active_rule_count": active_rule_count,
            "variant_deck_count": len(find_variant_rows(conn, SOULFIRE_ERUPTION)),
            "current_607_contains_soulfire": any(
                normalize_key(card["name"]) == normalize_key(SOULFIRE_ERUPTION)
                for card in deck_cards
            ),
            "same_lane_current_card_count": len(competitor_rows),
            "manual_review_cut_count": len(manual_rows),
            "blocked_cut_count": len(blocked_rows),
            "trace_reference_event_count": sum(int(value) for value in trace_events["event_counts"].values()),
            "trace_use_event_count": use_event_count,
            "removal_lane_prior_soulfire_pair_count": int(
                removal_lane_summary.get("soulfire_pair_count") or 0
            ),
            "existing_soulfire_result_count": int(existing_soulfire_results.get("result_count") or 0),
            "existing_soulfire_negative_vs_607_count": int(
                existing_soulfire_results.get("negative_vs_607_count") or 0
            ),
        },
        "same_lane_current_cards": competitor_rows[:30],
        "manual_review_cuts": manual_rows[:20],
        "blocked_cut_samples": blocked_rows[:25],
        "guardrails": [
            "Soulfire Eruption cannot enter 607 from public popularity alone.",
            "It is a nine-mana payoff/removal/value hybrid, not a replacement for cheap interaction.",
            "Any package must name the cut and protect prior 607 anchors.",
            "Forced-access probes are learning-only until a natural equal gate ties or beats 607.",
            "Card-level promotion requires trace evidence that Soulfire was drawn, cast, resolved, or converted.",
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    summary = payload["summary"]
    scan = payload["trace_events"]["scan_summary"]
    lines = [
        "# Lorehold Soulfire Eruption Need Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Recommended next action: `{payload['recommended_next_action']}`",
        f"- Deck id: `{payload['deck_id']}`",
        f"- Source DB: `{payload['source_db']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Active Soulfire rule count: `{summary['active_rule_count']}`",
        f"- Soulfire variant deck count: `{summary['variant_deck_count']}`",
        f"- Current 607 contains Soulfire: `{str(summary['current_607_contains_soulfire']).lower()}`",
        f"- Same-lane current card count: `{summary['same_lane_current_card_count']}`",
        f"- Manual-review cut count: `{summary['manual_review_cut_count']}`",
        f"- Blocked cut count: `{summary['blocked_cut_count']}`",
        f"- Trace reference events: `{summary['trace_reference_event_count']}`",
        f"- Trace use events: `{summary['trace_use_event_count']}`",
        f"- Prior removal-lane Soulfire pair count: `{summary['removal_lane_prior_soulfire_pair_count']}`",
        f"- Existing Soulfire result rows: `{summary['existing_soulfire_result_count']}`",
        f"- Existing Soulfire negative rows vs 607: `{summary['existing_soulfire_negative_vs_607_count']}`",
        "",
        "## Soulfire Eruption",
        "",
        f"- Mana cost: `{payload['soulfire_eruption'].get('mana_cost', '')}`",
        f"- Safe CMC: `{payload['soulfire_eruption'].get('cmc', '')}`",
        f"- Type: `{payload['soulfire_eruption'].get('type_line', '')}`",
        f"- Variant deck ids: `{payload['soulfire_variant_deck_ids']}`",
        f"- Active effects: `{payload['soulfire_rule'].get('active_effects', {})}`",
        f"- Active battle scopes: `{payload['soulfire_rule'].get('active_battle_model_scopes', {})}`",
        "",
        "## Same-Lane 607 Cards",
        "",
        "| Rank | Card | Role | CMC | Status | Score | Blockers | Cautions |",
        "| ---: | --- | --- | ---: | --- | ---: | --- | --- |",
    ]
    for index, row in enumerate(payload["same_lane_current_cards"][:20], start=1):
        lines.append(
            "| {rank} | {card} | `{role}` | {cmc} | `{status}` | {score} | {blockers} | {cautions} |".format(
                rank=index,
                card=row["card"],
                role=row["role"],
                cmc=row["cmc"],
                status=row["status"],
                score=row["lane_score"],
                blockers=", ".join(row["blockers"]) or "-",
                cautions=", ".join(row["cautions"]) or "-",
            )
        )
    lines.extend(
        [
            "",
            "## Trace Evidence",
            "",
            f"- Candidate reports: `{scan.get('candidate_report_count', 0)}`",
            f"- Parsed reports with Soulfire marker: `{scan.get('parsed_report_count', 0)}`",
            f"- Skipped without Soulfire marker: `{scan.get('skipped_no_target_marker_count', 0)}`",
            f"- Skipped too large: `{scan.get('skipped_too_large_count', 0)}`",
            f"- Parse errors: `{scan.get('parse_error_count', 0)}`",
            f"- Event counts: `{payload['trace_events']['event_counts']}`",
            f"- Use event counts: `{payload['trace_events']['use_event_counts']}`",
            "",
            "## Recent 607 Gate Context",
            "",
            f"- Gate rows found: `{payload['recent_607_gate_summary']['report_count']}`",
            f"- Game result totals: `{payload['recent_607_gate_summary']['game_result_totals']}`",
            "",
            "## Existing Soulfire Results",
            "",
            f"- Result rows found: `{payload['existing_soulfire_results']['result_count']}`",
            f"- Negative rows versus 607: `{payload['existing_soulfire_results']['negative_vs_607_count']}`",
            "",
            "| Deck | W | L | WR | 607 W | 607 L | Delta W | Soulfire Metrics | Source |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |",
        ]
    )
    for row in payload["existing_soulfire_results"]["rows"][:10]:
        lines.append(
            "| {deck} | {wins} | {losses} | {wr} | {bw} | {bl} | {delta} | `{metrics}` | `{source}` |".format(
                deck=row.get("deck_key") or "",
                wins=row.get("wins"),
                losses=row.get("losses"),
                wr=row.get("win_rate"),
                bw=row.get("baseline_607_wins"),
                bl=row.get("baseline_607_losses"),
                delta=row.get("delta_wins_vs_607"),
                metrics=row.get("soulfire_metric_counts") or {},
                source=row.get("source") or "",
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
    parser.add_argument("--trace-report-glob", action="append", default=[])
    parser.add_argument("--max-trace-report-mb", type=float)
    parser.add_argument("--recent-gate-report", type=Path, action="append")
    parser.add_argument("--removal-lane-report", type=Path, default=DEFAULT_REMOVAL_LANE_REPORT)
    parser.add_argument("--stem", default="lorehold_soulfire_eruption_need_audit_20260704")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    exposure_profiles = read_existing_json(args.exposure_profile or DEFAULT_EXPOSURE_PROFILES)
    trace_report_paths = discover_report_paths(args.trace_report_glob or DEFAULT_TRACE_REPORT_GLOBS)
    recent_gate_reports = args.recent_gate_report or DEFAULT_RECENT_GATE_REPORTS
    with connect(args.db) as conn:
        payload = build_audit(
            conn=conn,
            deck_id=args.deck_id,
            db_path=args.db,
            exposure_profiles=exposure_profiles,
            trace_report_paths=trace_report_paths,
            max_trace_report_mb=args.max_trace_report_mb,
            recent_gate_reports=recent_gate_reports,
            removal_lane_report=args.removal_lane_report,
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
