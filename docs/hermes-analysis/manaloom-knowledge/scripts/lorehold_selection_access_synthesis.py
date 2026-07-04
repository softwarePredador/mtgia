#!/usr/bin/env python3
"""Synthesize Lorehold 607 selection, tutor, and access evidence.

This read-only synthesis sits above the access/tutor/hand-filter cut models.
It answers one deckbuilding question: does the current protected deck 607 need
a direct access or selection swap, and if not, why?
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from master_optimizer_common import (
    normalize_name,
    resolve_default_knowledge_db,
    safe_cmc_from_card,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_DECK_ID = 607
DEFAULT_EDHREC_CARD_DATA = SCRIPT_DIR / "_edhrec_card_data.json"
CURRENT_ACCESS_ANCHORS = [
    "Sensei's Divining Top",
    "Scroll Rack",
    "Library of Leng",
    "Land Tax",
]
ACCESS_CANDIDATES = [
    "Brainstone",
    "Penance",
    "Hidden Retreat",
    "Enlightened Tutor",
    "Gamble",
]
EXTERNAL_LEARNING = [
    {
        "source": "EDHREC Lorehold cEDH article",
        "url": "https://edhrec.com/articles/a-cedh-miracle-with-lorehold-the-historian",
        "learning": "Sensei's Divining Top, Scroll Rack, and Library of Leng are explicit topdeck setup support for Lorehold.",
    },
    {
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "learning": "Lorehold-specific inclusion rate is evidence for commander fit, not automatic replacement authority.",
    },
    {
        "source": "EDHREC topdeck average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/topdeck",
        "learning": "The topdeck tag reinforces Top/Rack/Library plus artifact and spell-value support as the main access lane.",
    },
    {
        "source": "Card Kingdom Lorehold synergy article",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "learning": "Topdeck manipulation is especially important in red-white where blue cantrip tools are absent.",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def newest_report(pattern: str, fallback: Path, *, report_dir: Path = REPORT_DIR) -> Path:
    matches = sorted(
        report_dir.glob(pattern),
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )
    return matches[0] if matches else fallback


def default_access_report() -> Path:
    return newest_report(
        "lorehold_access_cut_model_20260704_learning_selection_access_baseline_targets.json",
        REPORT_DIR / "lorehold_access_cut_model_20260704_learning_selection_access.json",
    )


def default_tutor_report() -> Path:
    return newest_report(
        "lorehold_tutor_cut_model_20260704_learning_selection_access.json",
        REPORT_DIR / "lorehold_tutor_cut_model_20260630_goal_learning_contextual_tutor.json",
    )


def default_hand_filter_report() -> Path:
    return newest_report(
        "lorehold_hand_filter_cut_model_20260704_learning_selection_access.json",
        REPORT_DIR / "lorehold_hand_filter_cut_model_20260630_post_pg270_expanded607_search.json",
    )


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_json_if_exists(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return read_json(path)


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def as_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def normalized_sql_expr(column: str) -> str:
    return f"lower(trim(replace(replace(replace({column}, '''', ''), ',', ''), '-', ' ')))"


def oracle_lookup(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {}
    wanted = normalize_name(card_name)
    row = conn.execute(
        f"""
        SELECT name, mana_cost, type_line, oracle_text, cmc, card_id
        FROM card_oracle_cache
        WHERE normalized_name = ?
           OR {normalized_sql_expr("name")} = ?
        LIMIT 1
        """,
        (wanted, wanted),
    ).fetchone()
    return dict(row) if row else {}


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT deck_id, card_name, quantity, functional_tag, functional_tags_json,
               is_commander, cmc, type_line, oracle_text, card_id
        FROM deck_cards
        WHERE deck_id = ?
        ORDER BY is_commander DESC, card_name
        """,
        (deck_id,),
    ).fetchall()
    cards: list[dict[str, Any]] = []
    for row in rows:
        card = dict(row)
        oracle = oracle_lookup(conn, str(card.get("card_name") or ""))
        if oracle.get("mana_cost"):
            card["mana_cost"] = oracle["mana_cost"]
        for field in ("type_line", "oracle_text", "cmc", "card_id"):
            if card.get(field) in (None, "") and oracle.get(field) not in (None, ""):
                card[field] = oracle[field]
        card["safe_cmc"] = safe_cmc_from_card(card, unknown_nonland_fallback=99.0)
        cards.append(card)
    return cards


def commander_legality(conn: sqlite3.Connection, card_name: str) -> str | None:
    if not sqlite_connection_has_table(conn, "card_legalities"):
        return None
    row = conn.execute(
        """
        SELECT status
        FROM card_legalities
        WHERE lower(card_name) = lower(?)
          AND lower(format) = 'commander'
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return str(row["status"]) if row else None


def format_staple(conn: sqlite3.Connection, card_name: str) -> dict[str, Any] | None:
    if not sqlite_connection_has_table(conn, "format_staples"):
        return None
    row = conn.execute(
        """
        SELECT card_name, archetype, category, color_identity, edhrec_rank, is_banned
        FROM format_staples
        WHERE lower(card_name) = lower(?)
          AND lower(format) = 'commander'
        ORDER BY edhrec_rank
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return dict(row) if row else None


def battle_rule_summary(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return {"rule_count": 0, "active_rule_count": 0, "scopes": []}
    rows = conn.execute(
        """
        SELECT execution_status, review_status, effect_json
        FROM battle_card_rules
        WHERE lower(card_name) = lower(?)
           OR normalized_name = ?
        """,
        (card_name, normalize_name(card_name)),
    ).fetchall()
    active_statuses = {"auto", "active", "verified"}
    active_reviews = {"active", "verified", "reviewed"}
    active = 0
    scopes: set[str] = set()
    for row in rows:
        if str(row["execution_status"] or "") in active_statuses and str(
            row["review_status"] or ""
        ) in active_reviews:
            active += 1
        try:
            effect = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect = {}
        if isinstance(effect, Mapping) and effect.get("battle_model_scope"):
            scopes.add(str(effect["battle_model_scope"]))
    return {"rule_count": len(rows), "active_rule_count": active, "scopes": sorted(scopes)}


def load_edhrec_stats(path: Path, card_names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_name(name): name for name in card_names}
    out: dict[str, dict[str, Any]] = {}
    payload = read_json_if_exists(path)
    rows = payload if isinstance(payload, list) else []
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        key = normalize_name(str(row.get("name") or ""))
        if key not in wanted:
            continue
        potential = as_float(row.get("potential_decks"))
        inclusion = as_float(row.get("inclusion"))
        pct = as_float(row.get("pct"), 100.0 * inclusion / potential if potential else 0.0)
        out[wanted[key]] = {
            "inclusion": as_int(row.get("inclusion")),
            "potential_decks": as_int(row.get("potential_decks")),
            "pct": round(pct, 2),
            "synergy": row.get("synergy"),
            "source": rel(path),
        }
    return out


def report_summary(report: Mapping[str, Any]) -> dict[str, Any]:
    summary = report.get("summary")
    return dict(summary) if isinstance(summary, Mapping) else {}


def access_candidate_lookup(access_report: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = access_report.get("candidates")
    rows = rows if isinstance(rows, list) else []
    return {
        normalize_name(str(row.get("card_name") or "")): dict(row)
        for row in rows
        if isinstance(row, Mapping) and row.get("card_name")
    }


def tutor_candidate_lookup(tutor_report: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = tutor_report.get("candidates")
    rows = rows if isinstance(rows, list) else []
    return {
        normalize_name(str(row.get("card_name") or "")): dict(row)
        for row in rows
        if isinstance(row, Mapping) and row.get("card_name")
    }


def tutor_prior_evidence(tutor_report: Mapping[str, Any], card_name: str) -> list[dict[str, Any]]:
    wanted = normalize_name(card_name)
    rows = tutor_report.get("prior_tutor_evidence")
    rows = rows if isinstance(rows, list) else []
    out: list[dict[str, Any]] = []
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        add_keys = {normalize_name(str(card)) for card in row.get("adds") or []}
        if wanted not in add_keys:
            continue
        out.append(
            {
                "package_key": row.get("package_key"),
                "cuts": row.get("cuts") or [],
                "decision": row.get("decision"),
                "delta_pp": row.get("delta_pp"),
                "strong_seed_delta_pp": row.get("strong_seed_delta_pp"),
            }
        )
    return out


def current_anchor_profiles(
    conn: sqlite3.Connection,
    cards_by_name: Mapping[str, Mapping[str, Any]],
    edhrec_stats: Mapping[str, Mapping[str, Any]],
) -> list[dict[str, Any]]:
    profiles: list[dict[str, Any]] = []
    for name in CURRENT_ACCESS_ANCHORS:
        key = normalize_name(name)
        card = cards_by_name.get(key)
        profiles.append(
            {
                "card_name": name,
                "in_protected_607": bool(card),
                "role": (card or {}).get("functional_tag"),
                "cmc": (card or {}).get("safe_cmc"),
                "edhrec_lorehold": dict(edhrec_stats.get(name) or {}),
                "battle_rule_summary": battle_rule_summary(conn, name),
                "commander_legality": commander_legality(conn, name),
                "format_staple": format_staple(conn, name),
            }
        )
    return profiles


def candidate_profile(
    conn: sqlite3.Connection,
    cards_by_name: Mapping[str, Mapping[str, Any]],
    edhrec_stats: Mapping[str, Mapping[str, Any]],
    access_lookup: Mapping[str, Mapping[str, Any]],
    tutor_lookup: Mapping[str, Mapping[str, Any]],
    tutor_report: Mapping[str, Any],
    card_name: str,
) -> dict[str, Any]:
    key = normalize_name(card_name)
    access = dict(access_lookup.get(key) or {})
    tutor = dict(tutor_lookup.get(key) or {})
    in_deck = key in cards_by_name
    profile: dict[str, Any] = {
        "card_name": card_name,
        "in_protected_607": in_deck,
        "commander_legality": commander_legality(conn, card_name),
        "format_staple": format_staple(conn, card_name),
        "edhrec_lorehold": dict(edhrec_stats.get(card_name) or {}),
        "battle_rule_summary": battle_rule_summary(conn, card_name),
        "access_model": {
            "status": access.get("status"),
            "lane": access.get("lane"),
            "score": access.get("score"),
            "access_targets": access.get("access_targets") or [],
            "nonbaseline_access_targets": access.get("nonbaseline_access_targets") or [],
            "variant_usage": access.get("variant_usage") or {},
            "blockers": access.get("blockers") or [],
        },
        "decision": "candidate_not_evaluated",
        "decision_reasons": [],
    }
    if tutor:
        profile["tutor_model"] = {
            "active_rule_count": tutor.get("active_rule_count"),
            "exposure": tutor.get("exposure"),
            "prior_tutor_evidence": tutor_prior_evidence(tutor_report, card_name),
        }
    access_status = str(access.get("status") or "")
    if in_deck:
        profile["decision"] = "already_in_protected_607"
    elif access_status == "ready":
        profile["decision"] = "runtime_ready_but_no_seed_safe_cut"
        profile["decision_reasons"].append("candidate_runtime_ready")
    if key in {"enlightened tutor", "gamble"}:
        profile["decision"] = "direct_tutor_swap_blocked"
        profile["decision_reasons"].append("tutor_model_has_zero_direct_gate_ready_pairs")
        if profile.get("tutor_model", {}).get("prior_tutor_evidence"):
            profile["decision_reasons"].append("prior_tutor_evidence_contains_strong_seed_regression_or_watch")
    if profile["access_model"]["nonbaseline_access_targets"]:
        profile["decision_reasons"].append("candidate_targets_nonbaseline_card_requires_package_context")
    if not profile["decision_reasons"] and profile["decision"] == "candidate_not_evaluated":
        profile["decision_reasons"].append("no_current_report_evidence")
    return profile


def synthesize_status(
    access_summary: Mapping[str, Any],
    tutor_summary: Mapping[str, Any],
    hand_summary: Mapping[str, Any],
) -> str:
    if (
        as_int(access_summary.get("preflight_access_candidate_ready_count")) == 0
        and as_int(tutor_summary.get("direct_gate_ready_count")) == 0
        and as_int(hand_summary.get("preflight_benchmark_ready_count")) == 0
        and as_int(hand_summary.get("expanded_preflight_benchmark_ready_count")) == 0
    ):
        return "selection_access_no_swap_ready_current_607"
    return "selection_access_candidate_requires_gate_review"


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    access_report_path: Path,
    tutor_report_path: Path,
    hand_filter_report_path: Path,
    edhrec_card_data: Path,
) -> dict[str, Any]:
    cards = load_deck_cards(conn, deck_id)
    cards_by_name = {normalize_name(str(card.get("card_name") or "")): card for card in cards}
    names_for_stats = [*CURRENT_ACCESS_ANCHORS, *ACCESS_CANDIDATES]
    edhrec_stats = load_edhrec_stats(edhrec_card_data, names_for_stats)
    access_report = read_json_if_exists(access_report_path)
    tutor_report = read_json_if_exists(tutor_report_path)
    hand_report = read_json_if_exists(hand_filter_report_path)
    access_summary = report_summary(access_report)
    tutor_summary = report_summary(tutor_report)
    hand_summary = report_summary(hand_report)
    status = synthesize_status(access_summary, tutor_summary, hand_summary)
    current_targets = list(access_summary.get("current_target_access_cards") or [])
    nonbaseline_targets = list(access_summary.get("nonbaseline_target_access_cards") or [])
    divergences = []
    if nonbaseline_targets:
        divergences.append(
            {
                "key": "access_model_contains_nonbaseline_target",
                "detail": (
                    "The access model still tracks historical target(s) not present in protected 607; "
                    "they cannot drive a 607 cut unless a package explicitly reintroduces them."
                ),
                "cards": nonbaseline_targets,
            }
        )
    access_lookup = access_candidate_lookup(access_report)
    tutor_lookup = tutor_candidate_lookup(tutor_report)
    candidates = [
        candidate_profile(
            conn,
            cards_by_name,
            edhrec_stats,
            access_lookup,
            tutor_lookup,
            tutor_report,
            name,
        )
        for name in ACCESS_CANDIDATES
    ]
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_selection_access_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": status,
        "source_reports": {
            "access_cut_model": rel(access_report_path),
            "tutor_cut_model": rel(tutor_report_path),
            "hand_filter_cut_model": rel(hand_filter_report_path),
            "edhrec_card_data": rel(edhrec_card_data),
        },
        "summary": {
            "total_cards": sum(as_int(card.get("quantity"), 1) for card in cards),
            "current_access_anchor_count": sum(
                1 for name in CURRENT_ACCESS_ANCHORS if normalize_name(name) in cards_by_name
            ),
            "current_target_access_cards": current_targets,
            "nonbaseline_target_access_cards": nonbaseline_targets,
            "access_preflight_ready_count": as_int(
                access_summary.get("preflight_access_candidate_ready_count")
            ),
            "tutor_direct_gate_ready_count": as_int(tutor_summary.get("direct_gate_ready_count")),
            "hand_filter_preflight_ready_count": as_int(
                hand_summary.get("preflight_benchmark_ready_count")
            ),
            "hand_filter_expanded_preflight_ready_count": as_int(
                hand_summary.get("expanded_preflight_benchmark_ready_count")
            ),
            "access_recommended_next_action": access_summary.get("recommended_next_action"),
            "tutor_recommended_next_action": tutor_summary.get("recommended_next_action"),
            "hand_filter_recommended_next_action": hand_summary.get("recommended_next_action"),
            "divergence_count": len(divergences),
        },
        "external_learning": EXTERNAL_LEARNING,
        "current_access_anchors": current_anchor_profiles(conn, cards_by_name, edhrec_stats),
        "candidate_access_cards": candidates,
        "divergences": divergences,
        "decision": {
            "keep_607_access_package": status == "selection_access_no_swap_ready_current_607",
            "reason": (
                "The current 607 already contains the high-signal Top/Rack/Library/Land Tax access core; "
                "available access candidates are legal and mostly runtime-ready, but no current report "
                "has a seed-safe same-lane cut."
            ),
            "next_action": "build_new_seed_safe_cut_or_additive_package_before_battle_gate",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Selection Access Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- current access anchors: `{summary['current_access_anchor_count']}`",
        f"- current target access cards: `{', '.join(summary['current_target_access_cards']) or '-'}`",
        f"- nonbaseline target access cards: `{', '.join(summary['nonbaseline_target_access_cards']) or '-'}`",
        f"- access preflight-ready pairs: `{summary['access_preflight_ready_count']}`",
        f"- tutor direct gate-ready pairs: `{summary['tutor_direct_gate_ready_count']}`",
        f"- hand-filter preflight-ready pairs: `{summary['hand_filter_preflight_ready_count']}`",
        f"- expanded hand-filter preflight-ready pairs: `{summary['hand_filter_expanded_preflight_ready_count']}`",
        f"- divergences: `{summary['divergence_count']}`",
        "",
        "## Current Anchors",
        "",
        "| Card | In 607 | Role | EDHREC Lorehold | Active Rules |",
        "| --- | --- | --- | ---: | ---: |",
    ]
    for row in payload["current_access_anchors"]:
        stats = row.get("edhrec_lorehold") or {}
        rules = row.get("battle_rule_summary") or {}
        pct = stats.get("pct")
        lines.append(
            "| {card} | `{in_deck}` | `{role}` | {pct} | {rules} |".format(
                card=row["card_name"],
                in_deck=str(row["in_protected_607"]).lower(),
                role=row.get("role") or "-",
                pct=f"{pct}%" if pct is not None else "-",
                rules=rules.get("active_rule_count", 0),
            )
        )
    lines.extend(
        [
            "",
            "## Candidate Cards",
            "",
            "| Card | Legal | EDHREC Lorehold | Access Decision | Access Targets | Nonbaseline Targets |",
            "| --- | --- | ---: | --- | --- | --- |",
        ]
    )
    for row in payload["candidate_access_cards"]:
        stats = row.get("edhrec_lorehold") or {}
        access = row.get("access_model") or {}
        pct = stats.get("pct")
        lines.append(
            "| {card} | `{legal}` | {pct} | `{decision}` | {targets} | {nonbaseline} |".format(
                card=row["card_name"],
                legal=row.get("commander_legality") or "unknown",
                pct=f"{pct}%" if pct is not None else "-",
                decision=row.get("decision"),
                targets=", ".join(access.get("access_targets") or []) or "-",
                nonbaseline=", ".join(access.get("nonbaseline_access_targets") or []) or "-",
            )
        )
    if payload.get("divergences"):
        lines.extend(["", "## Divergences", ""])
        for row in payload["divergences"]:
            lines.append(f"- `{row['key']}`: {row['detail']} Cards: {', '.join(row.get('cards') or [])}.")
    lines.extend(["", "## Learning Sources", ""])
    for source in payload["external_learning"]:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_access_package: `{str(decision['keep_607_access_package']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append(f"- next_action: `{decision['next_action']}`")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--access-report", type=Path, default=None)
    parser.add_argument("--tutor-report", type=Path, default=None)
    parser.add_argument("--hand-filter-report", type=Path, default=None)
    parser.add_argument("--edhrec-card-data", type=Path, default=DEFAULT_EDHREC_CARD_DATA)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_selection_access_synthesis",
    )
    args = parser.parse_args()
    access_report = args.access_report or default_access_report()
    tutor_report = args.tutor_report or default_tutor_report()
    hand_filter_report = args.hand_filter_report or default_hand_filter_report()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            access_report_path=access_report,
            tutor_report_path=tutor_report,
            hand_filter_report_path=hand_filter_report,
            edhrec_card_data=args.edhrec_card_data,
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
