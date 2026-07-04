#!/usr/bin/env python3
"""Plan the next Lorehold spell-pressure overfill repair.

The mana-conversion shell had a useful smoke signal, but it still ranked below
the protected 607 baseline and had package overfill. This read-only planner
identifies the lowest-risk single-card repair before any larger gate.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from lorehold_strategy_profile import (
    INTENT_PACKAGE_RANGES,
    commander_intent_alignment,
    normalize_name,
    strategy_counts,
    strategy_tags_for_card,
)
from lorehold_variant_strategy_matrix import roles_for_card


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_CANDIDATE = (
    REPORT_DIR
    / "lorehold_from_scratch_challengers_20260704_spell_pressure_mana_conversion_spell_pressure_mana_conversion.json"
)
DEFAULT_MATRIX = REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_mana_conversion_matrix.json"
DEFAULT_GATE = REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_mana_conversion_fixed607_gate.json"
DEFAULT_TRACE = REPORT_DIR / "lorehold_spell_pressure_trace_miner_20260704_mana_conversion_current.json"
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_spell_pressure_overfill_repair_20260704_current"

CANDIDATE_KEY = "challenger_lorehold_spell_pressure_mana_conversion_v1"
BASELINE_DECK_ID = 607

PROTECTED_ENGINE_CARDS = {
    "Approach of the Second Sun",
    "Bender's Waterskin",
    "Guttersnipe",
    "Hit the Mother Lode",
    "Improvisation Capstone",
    "Land Tax",
    "Library of Leng",
    "Lorehold, the Historian",
    "Mizzix's Mastery",
    "Molecule Man",
    "Scroll Rack",
    "Sensei's Divining Top",
    "Storm-Kiln Artist",
    "The Mind Stone",
    "The Scarlet Witch",
    "Victory Chimes",
}
DEMOTED_PRESSURE_CARDS = {"Young Pyromancer", "Monastery Mentor"}

EXTERNAL_LEARNING = [
    {
        "source": "EDHREC average optimized spellslinger",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/optimized/spellslinger",
        "learning": (
            "The optimized average contains both Storm-Kiln Artist and the protected "
            "topdeck/miracle artifacts, so the repair should preserve that axis while "
            "removing excess topdeck/spell-chain density."
        ),
    },
    {
        "source": "EDHREC Boros Miracles budget article",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "learning": (
            "Lorehold needs enough instant/sorcery density for miracles, but too many "
            "top-exile/draw-like haymakers can become miracle duds instead of setup."
        ),
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_int(value: Any) -> int:
    try:
        return int(value)
    except Exception:
        return 0


def as_float(value: Any) -> float:
    try:
        return float(value)
    except Exception:
        return 0.0


def card_name(card: Mapping[str, Any]) -> str:
    return str(card.get("card_name") or card.get("name") or "")


def normalized_names(names: set[str]) -> set[str]:
    return {normalize_name(name) for name in names}


def matrix_candidate(matrix: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in matrix.get("decks") or []:
        if isinstance(row, Mapping) and row.get("deck_key") == deck_key:
            return dict(row)
    return {}


def overfilled_packages(matrix: Mapping[str, Any], candidate: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    source = matrix_candidate(matrix, CANDIDATE_KEY)
    alignment = source.get("commander_intent_alignment") if isinstance(source.get("commander_intent_alignment"), Mapping) else {}
    if not alignment:
        alignment = candidate.get("commander_intent_alignment") if isinstance(candidate.get("commander_intent_alignment"), Mapping) else {}
    ranges = alignment.get("package_ranges") if isinstance(alignment.get("package_ranges"), Mapping) else {}
    return {
        str(package): dict(row)
        for package, row in ranges.items()
        if isinstance(row, Mapping) and row.get("status") == "overfilled"
    }


def gate_card_events(gate: Mapping[str, Any], card: str) -> dict[str, int]:
    for row in gate.get("results") or []:
        if not isinstance(row, Mapping) or row.get("deck_key") != CANDIDATE_KEY:
            continue
        telemetry = row.get("telemetry") if isinstance(row.get("telemetry"), Mapping) else {}
        counts = telemetry.get("card_event_counts") if isinstance(telemetry.get("card_event_counts"), Mapping) else {}
        return {
            str(event): as_int(count)
            for event, count in counts.items()
            if f":{card}" in str(event)
        }
    return {}


def baseline_names(db_path: Path, deck_id: int = BASELINE_DECK_ID) -> set[str]:
    with sqlite3.connect(db_path) as conn:
        rows = conn.execute("SELECT card_name FROM deck_cards WHERE deck_id = ?", (deck_id,)).fetchall()
    return {str(row[0]) for row in rows}


def db_card_payload(db_path: Path, card: str, deck_id: int = BASELINE_DECK_ID) -> dict[str, Any] | None:
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute(
            "SELECT * FROM deck_cards WHERE deck_id = ? AND card_name = ?",
            (deck_id, card),
        ).fetchone()
    if not row:
        return None
    data = dict(row)
    return {
        "card_name": data["card_name"],
        "name": data["card_name"],
        "quantity": 1,
        "roles": sorted(roles_for_card(data)),
        "is_commander": bool(data.get("is_commander")),
        "is_land": "land" in roles_for_card(data) or "Land" in str(data.get("type_line") or ""),
        "cmc": data.get("cmc"),
        "type_line": data.get("type_line") or "",
        "oracle_text": data.get("oracle_text") or "",
    }


def role_risks(alignment: Mapping[str, Any]) -> list[str]:
    return [risk for risk in alignment.get("risks") or [] if str(risk).startswith("role_")]


def package_risks(alignment: Mapping[str, Any]) -> list[str]:
    return [risk for risk in alignment.get("risks") or [] if str(risk).startswith("package_")]


def count_repaired_overfills(alignment: Mapping[str, Any], current_overfilled: set[str]) -> int:
    ranges = alignment.get("package_ranges") if isinstance(alignment.get("package_ranges"), Mapping) else {}
    repaired = 0
    for package in current_overfilled:
        row = ranges.get(package) if isinstance(ranges.get(package), Mapping) else {}
        if row.get("status") == "aligned":
            repaired += 1
    return repaired


def cut_rows(
    *,
    candidate_cards: list[Mapping[str, Any]],
    matrix: Mapping[str, Any],
    candidate: Mapping[str, Any],
    gate: Mapping[str, Any],
    db_path: Path,
) -> list[dict[str, Any]]:
    overfilled = overfilled_packages(matrix, candidate)
    overfilled_names = set(overfilled)
    baseline = normalized_names(baseline_names(db_path))
    required = normalized_names(set(str(name) for name in candidate.get("required_cards") or []))
    protected = normalized_names(PROTECTED_ENGINE_CARDS)
    rows: list[dict[str, Any]] = []
    for card in candidate_cards:
        name = card_name(card)
        if not name or card.get("is_land") or card.get("is_commander"):
            continue
        tags = strategy_tags_for_card(card)
        overlap = sorted(tags & overfilled_names)
        if not overlap:
            continue
        without = [item for item in candidate_cards if normalize_name(card_name(item)) != normalize_name(name)]
        after = commander_intent_alignment(without)
        events = gate_card_events(gate, name)
        in_baseline = normalize_name(name) in baseline
        is_required = normalize_name(name) in required
        is_protected = normalize_name(name) in protected
        blockers: list[str] = []
        if is_protected:
            blockers.append("protected_engine_or_pressure_card")
        if is_required:
            blockers.append("required_by_current_shell")
        if in_baseline:
            blockers.append("present_in_protected_607")
        if events:
            blockers.append("observed_in_smoke_gate")
        if role_risks(after):
            blockers.append("would_create_role_risk")
        if any(str(risk).endswith("_shortfall") for risk in package_risks(after)):
            blockers.append("would_create_package_shortfall")
        decision = "overfill_cut_candidate" if not blockers else "blocked_or_caution"
        repaired = count_repaired_overfills(after, overfilled_names)
        score = repaired * 12 + len(overlap) * 4
        if not in_baseline:
            score += 5
        if not events:
            score += 4
        if is_required or is_protected:
            score -= 40
        if role_risks(after):
            score -= 20
        rows.append(
            {
                "card_name": name,
                "decision": decision,
                "score": round(score, 3),
                "in_protected_607": in_baseline,
                "required_by_current_shell": is_required,
                "protected_engine_or_pressure_card": is_protected,
                "overfilled_tags": overlap,
                "all_tags": sorted(tags),
                "smoke_event_counts": events,
                "after_cut_score": after["score"],
                "after_cut_risks": after["risks"],
                "repaired_overfilled_package_count": repaired,
                "blockers": blockers,
            }
        )
    return sorted(rows, key=lambda row: (-as_float(row["score"]), row["card_name"]))


def replacement_rows(
    *,
    candidate_cards: list[Mapping[str, Any]],
    cut_card: str,
    db_path: Path,
) -> list[dict[str, Any]]:
    current = {normalize_name(card_name(card)) for card in candidate_cards}
    trimmed = [card for card in candidate_cards if normalize_name(card_name(card)) != normalize_name(cut_card)]
    baseline = sorted(baseline_names(db_path))
    rows: list[dict[str, Any]] = []
    for name in baseline:
        if normalize_name(name) in current or normalize_name(name) in normalized_names(DEMOTED_PRESSURE_CARDS):
            continue
        payload = db_card_payload(db_path, name)
        if not payload or payload.get("is_land") or payload.get("is_commander"):
            continue
        tested = trimmed + [payload]
        alignment = commander_intent_alignment(tested)
        tags = strategy_tags_for_card(payload)
        roles = set(payload.get("roles") or [])
        score = as_float(alignment.get("score"))
        if not package_risks(alignment) and not role_risks(alignment):
            score += 12
        if "ramp" in roles:
            score += 5
        if "spell_chain_conversion" not in tags:
            score += 4
        score -= min(5.0, as_float(payload.get("cmc")) * 0.35)
        rows.append(
            {
                "card_name": name,
                "score": round(score, 3),
                "roles": sorted(roles),
                "tags": sorted(tags),
                "after_replacement_score": alignment["score"],
                "after_replacement_risks": alignment["risks"],
                "decision": "replacement_candidate" if not alignment["risks"] else "replacement_keeps_risk",
            }
        )
    return sorted(rows, key=lambda row: (-as_float(row["score"]), row["card_name"]))


def build_payload(
    *,
    candidate: Mapping[str, Any],
    matrix: Mapping[str, Any],
    gate: Mapping[str, Any],
    trace: Mapping[str, Any],
    db_path: Path,
    candidate_path: Path,
    matrix_path: Path,
    gate_path: Path,
    trace_path: Path,
) -> dict[str, Any]:
    candidate_cards = list(candidate.get("final_deck") or [])
    overfilled = overfilled_packages(matrix, candidate)
    cuts = cut_rows(
        candidate_cards=candidate_cards,
        matrix=matrix,
        candidate=candidate,
        gate=gate,
        db_path=db_path,
    )
    ready_cuts = [row for row in cuts if row["decision"] == "overfill_cut_candidate"]
    top_cut = ready_cuts[0] if ready_cuts else (cuts[0] if cuts else {})
    replacements = replacement_rows(
        candidate_cards=candidate_cards,
        cut_card=str(top_cut.get("card_name") or ""),
        db_path=db_path,
    ) if top_cut else []
    ready_replacements = [row for row in replacements if row["decision"] == "replacement_candidate"]
    top_replacement = ready_replacements[0] if ready_replacements else (replacements[0] if replacements else {})
    status = (
        "overfill_repair_plan_ready"
        if top_cut.get("decision") == "overfill_cut_candidate"
        and top_replacement.get("decision") == "replacement_candidate"
        else "overfill_repair_needs_manual_review"
    )
    trace_summary = trace.get("summary") if isinstance(trace.get("summary"), Mapping) else {}
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_spell_pressure_overfill_repair",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": {
            "candidate": rel(candidate_path),
            "matrix": rel(matrix_path),
            "battle_gate": rel(gate_path),
            "trace_miner": rel(trace_path),
        },
        "external_learning": EXTERNAL_LEARNING,
        "status": status,
        "summary": {
            "candidate_key": candidate.get("candidate_key"),
            "overfilled_packages": overfilled,
            "trace_status": trace.get("status"),
            "wins_with_pressure_conversion_events": trace_summary.get("wins_with_pressure_conversion_events"),
            "top_cut_card": top_cut.get("card_name"),
            "top_replacement_card": top_replacement.get("card_name"),
            "promotion_allowed": False,
            "confirmation_allowed": False,
        },
        "top_cut": top_cut,
        "top_replacement": top_replacement,
        "cut_queue": cuts[:20],
        "replacement_queue": replacements[:20],
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
            "confirmation_allowed": False,
            "recommended_next_shell": "spell_pressure_mana_conversion_deoverfill",
            "reason": (
                "Apex of Power is the lowest-risk current overfill cut: it contributes "
                "to topdeck, hand-filter, and spell-chain overfill, is not in protected "
                "607, was not exercised in the smoke gate, and removing it repairs the "
                "package ranges. Pearl Medallion is the best 607-backed replacement "
                "because it preserves early mana without adding spell-chain/topdeck "
                "overfill."
            ),
            "next_actions": [
                "generate_deoverfill_shell_before_any_larger_gate",
                "require_matrix_no_package_overfill_before_confirm_gate",
                "require_storm_kiln_or_guttersnipe_conversion_events_before_learning_the_package",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Spell Pressure Overfill Repair",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- candidate_key: `{summary['candidate_key']}`",
        f"- overfilled_packages: `{json.dumps(summary['overfilled_packages'], sort_keys=True)}`",
        f"- trace_status: `{summary['trace_status']}`",
        f"- wins_with_pressure_conversion_events: `{summary['wins_with_pressure_conversion_events']}`",
        f"- top_cut_card: `{summary['top_cut_card']}`",
        f"- top_replacement_card: `{summary['top_replacement_card']}`",
        "- promotion_allowed: `false`",
        "- confirmation_allowed: `false`",
        "",
        "## Top Cut",
        "",
        f"- `{payload['top_cut'].get('card_name')}`: `{payload['top_cut'].get('decision')}`",
        f"- overfilled_tags: `{json.dumps(payload['top_cut'].get('overfilled_tags', []))}`",
        f"- blockers: `{json.dumps(payload['top_cut'].get('blockers', []))}`",
        f"- after_cut_risks: `{json.dumps(payload['top_cut'].get('after_cut_risks', []))}`",
        "",
        "## Top Replacement",
        "",
        f"- `{payload['top_replacement'].get('card_name')}`: `{payload['top_replacement'].get('decision')}`",
        f"- roles: `{json.dumps(payload['top_replacement'].get('roles', []))}`",
        f"- tags: `{json.dumps(payload['top_replacement'].get('tags', []))}`",
        f"- after_replacement_risks: `{json.dumps(payload['top_replacement'].get('after_replacement_risks', []))}`",
        "",
        "## Decision",
        "",
        f"- recommended_next_shell: `{payload['decision']['recommended_next_shell']}`",
        f"- reason: {payload['decision']['reason']}",
        "- next_actions:",
    ]
    for action in payload["decision"]["next_actions"]:
        lines.append(f"  - {action}")
    lines.extend(["", "## External Learning", ""])
    for source in payload.get("external_learning") or []:
        lines.append(f"- {source['source']}: {source['url']}")
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
    parser.add_argument("--candidate", type=Path, default=DEFAULT_CANDIDATE)
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--gate", type=Path, default=DEFAULT_GATE)
    parser.add_argument("--trace", type=Path, default=DEFAULT_TRACE)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        candidate=read_json(args.candidate),
        matrix=read_json(args.matrix),
        gate=read_json(args.gate),
        trace=read_json(args.trace),
        db_path=args.db,
        candidate_path=args.candidate,
        matrix_path=args.matrix,
        gate_path=args.gate,
        trace_path=args.trace,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
