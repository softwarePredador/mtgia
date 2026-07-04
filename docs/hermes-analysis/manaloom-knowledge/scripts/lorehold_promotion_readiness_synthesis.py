#!/usr/bin/env python3
"""Synthesize Lorehold 607 promotion readiness across deckbuilding axes.

This read-only layer combines the current Commander deckbuilding evidence into
one gate decision. It does not mutate PostgreSQL or Hermes SQLite. Its job is
to prevent a candidate from looking attractive in one axis while breaking the
protected 607 baseline in another axis.
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
    resolve_default_knowledge_db,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_DECK_ID = 607

DIRECT_READY_DECISIONS = {"direct_swap_ready", "promotion_ready", "natural_gate_won"}

BLOCKED_TOKENS = {
    "blocked",
    "banned",
    "not_accessible",
    "not_legal",
    "policy_blocked",
    "prior_exact_reject",
    "prior_gate_rejected",
    "rejected",
    "reject",
}

HYPOTHESIS_TOKENS = {
    "candidate",
    "gate",
    "hypothesis",
    "needs",
    "preflight",
    "requires",
    "runtime_ready",
    "triage",
    "watch",
}

CANDIDATE_KEYS = {
    "mana": "candidate_mana_backlog",
    "staple": "candidate_staple_backlog",
    "selection": "candidate_access_cards",
    "interaction": "candidate_profiles",
    "payoff": "candidate_cards",
}

EXTERNAL_LEARNING = [
    {
        "source": "Wizards Commander format page",
        "url": "https://magic.wizards.com/en/formats/commander",
        "learning": (
            "Commander is a 100-card constructed format and Wizards now frames "
            "deck expectations through optional brackets. ManaLoom should keep "
            "format legality separate from power-bracket and deck-plan fit."
        ),
    },
    {
        "source": "Wizards banned and restricted list",
        "url": "https://magic.wizards.com/en/banned-restricted-list",
        "learning": (
            "Commander ban checks are format-specific. Mana Crypt, Jeweled Lotus, "
            "and the original Moxen are Commander-banned, but that does not make "
            "every legal fast-mana card correct for 607."
        ),
    },
    {
        "source": "Scryfall Mana Vault API",
        "url": "https://api.scryfall.com/cards/named?exact=Mana%20Vault",
        "learning": (
            "Mana Vault is Commander-legal in Scryfall data checked on 2026-07-04, "
            "so its current exclusion is evidence/policy based, not legality based."
        ),
    },
    {
        "source": "Scryfall The One Ring API",
        "url": "https://api.scryfall.com/cards/named?exact=The%20One%20Ring",
        "learning": (
            "The One Ring is Commander-legal in Scryfall data checked on 2026-07-04, "
            "so it needs same-lane draw/protection proof before challenging 607."
        ),
    },
    {
        "source": "EDHREC Lorehold articles",
        "url": "https://edhrec.com/articles/tag/lorehold",
        "learning": (
            "Recent Lorehold deckbuilding coverage emphasizes miracle/topdeck and "
            "Boros spellslinger execution. That supports prioritizing commander "
            "cadence over generic staple rank."
        ),
    },
]

LEARNING_MODEL = {
    "deckbuilding_principles": [
        "Legality is only the first filter; promotion needs commander-plan fit and battle proof.",
        "Every replacement must name the same-lane card it challenges.",
        "A famous staple is pressure to investigate, not automatic inclusion.",
        "Protected anchors cannot be cut unless the candidate preserves the same function and wins an equal gate.",
        "A candidate must be drawn/cast/used in evidence traces before a battle result can promote it.",
    ],
    "lorehold_priority_order": [
        "commander miracle/topdeck cadence",
        "Top/Rack/Library/Land Tax access package",
        "turn-cycle miracle mana such as Bender's Waterskin and Victory Chimes",
        "interaction/protection that keeps the commander turn alive",
        "payoff conversion and recursion that actually closes games",
        "generic staples only after lane and sequence proof",
    ],
    "mana_policy": [
        "Keep land/ramp counts and Boros source counts inside the proven 607 profile unless a candidate proves the tradeoff.",
        "Fast colorless mana has to improve the critical turn without breaking colored fixing or miracle cadence.",
        "Mana Vault is not blocked by Commander legality; it is blocked by current 607 gate evidence.",
    ],
    "staple_policy": [
        "The One Ring is legal but not automatically better than the current draw/protection/topdeck structure.",
        "Original Moxen, Mana Crypt, and Jeweled Lotus remain Commander-banned under current official banlist evidence.",
        "Premium or cEDH-style packages require budget/policy approval plus same-lane promotion proof.",
    ],
}


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


def default_card_value_report() -> Path:
    return newest_report(
        "lorehold_card_value_priority_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_card_value_priority_synthesis_20260704_learning.json",
    )


def default_mana_report() -> Path:
    return newest_report(
        "lorehold_mana_sequence_policy_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_mana_sequence_policy_synthesis_20260704_learning.json",
    )


def default_staple_report() -> Path:
    return newest_report(
        "lorehold_staple_policy_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_staple_policy_synthesis_20260704_learning.json",
    )


def default_selection_report() -> Path:
    return newest_report(
        "lorehold_selection_access_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_selection_access_synthesis_20260704_learning.json",
    )


def default_interaction_report() -> Path:
    return newest_report(
        "lorehold_interaction_resilience_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_interaction_resilience_synthesis_20260704_learning.json",
    )


def default_payoff_report() -> Path:
    return newest_report(
        "lorehold_payoff_finisher_recursion_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_payoff_finisher_recursion_synthesis_20260704_learning.json",
    )


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def read_json_if_exists(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def deck_shape(conn: sqlite3.Connection, deck_id: int) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "deck_cards"):
        return {
            "deck_id": deck_id,
            "deck_rows": 0,
            "total_cards": 0,
            "commander_names": [],
            "deck_shape_ok": False,
        }
    rows = conn.execute(
        """
        SELECT card_name, quantity, is_commander
        FROM deck_cards
        WHERE deck_id = ?
        ORDER BY is_commander DESC, card_name
        """,
        (deck_id,),
    ).fetchall()
    commanders = [str(row["card_name"]) for row in rows if as_int(row["is_commander"]) == 1]
    total_cards = sum(as_int(row["quantity"], 1) for row in rows)
    return {
        "deck_id": deck_id,
        "deck_rows": len(rows),
        "total_cards": total_cards,
        "commander_names": commanders,
        "deck_shape_ok": total_cards == 100 and len(commanders) == 1,
    }


def source_status_class(status: str | None) -> str:
    text = str(status or "")
    if not text:
        return "missing_report"
    if any(token in text for token in ("no_direct", "no_swap_ready", "no_direct_auto", "keep_607")):
        return "keep_607"
    if "candidate_requires_gate_review" in text or text.endswith("direct_swap_ready"):
        return "candidate_pressure"
    if "watch" in text:
        return "keep_607_with_watch"
    return "review_needed"


def classify_decision(row: Mapping[str, Any]) -> str:
    decision = str(row.get("decision") or "").strip()
    decision_text = decision.lower()
    if row.get("in_protected_607") is True or row.get("in_607") is True:
        return "already_in_607"
    if decision in DIRECT_READY_DECISIONS:
        return "gate_ready_candidate"
    if decision_text.startswith("already_in_607"):
        return "already_in_607"
    if any(token in decision_text for token in BLOCKED_TOKENS):
        return "blocked_or_rejected"
    if any(token in decision_text for token in HYPOTHESIS_TOKENS):
        return "hypothesis_or_gate_needed"
    if not decision:
        return "unclassified"
    return "unclassified"


def candidate_name(row: Mapping[str, Any]) -> str:
    for key in ("card_name", "candidate", "name"):
        value = row.get(key)
        if value:
            return str(value)
    return "unknown"


def row_lane(row: Mapping[str, Any]) -> str:
    lane = row.get("lane")
    if lane:
        return str(lane)
    access_model = row.get("access_model")
    if isinstance(access_model, Mapping) and access_model.get("lane"):
        return str(access_model["lane"])
    return "unknown"


def collect_candidate_rows(reports: Mapping[str, Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for source, key in CANDIDATE_KEYS.items():
        payload = reports.get(source) or {}
        values = payload.get(key) or []
        if not isinstance(values, list):
            continue
        for raw in values:
            if not isinstance(raw, Mapping):
                continue
            row = dict(raw)
            row["_source_axis"] = source
            row["_classification"] = classify_decision(row)
            row["_candidate_name"] = candidate_name(row)
            row["_lane"] = row_lane(row)
            rows.append(row)
    card_value = reports.get("card_value") or {}
    pressure = card_value.get("candidate_replacement_pressure")
    if isinstance(pressure, Mapping):
        for raw in pressure.get("ready_candidates") or []:
            if not isinstance(raw, Mapping):
                continue
            row = dict(raw)
            row["_source_axis"] = "card_value"
            row["_classification"] = classify_decision(row)
            row["_candidate_name"] = candidate_name(row)
            row["_lane"] = row_lane(row)
            rows.append(row)
    return rows


def unique_names(rows: Iterable[Mapping[str, Any]]) -> list[str]:
    names = {
        str(row.get("_candidate_name") or candidate_name(row))
        for row in rows
        if str(row.get("_candidate_name") or candidate_name(row)) != "unknown"
    }
    return sorted(names)


def classify_candidates(rows: list[Mapping[str, Any]]) -> dict[str, Any]:
    class_counts = Counter(str(row.get("_classification")) for row in rows)
    lane_counts = Counter(str(row.get("_lane")) for row in rows)
    source_counts = Counter(str(row.get("_source_axis")) for row in rows)
    ready = [row for row in rows if row.get("_classification") == "gate_ready_candidate"]
    blocked = [row for row in rows if row.get("_classification") == "blocked_or_rejected"]
    hypotheses = [row for row in rows if row.get("_classification") == "hypothesis_or_gate_needed"]
    already = [row for row in rows if row.get("_classification") == "already_in_607"]
    return {
        "candidate_rows_considered": len(rows),
        "unique_candidate_count": len(unique_names(rows)),
        "classification_counts": dict(sorted(class_counts.items())),
        "lane_counts": dict(sorted(lane_counts.items())),
        "source_counts": dict(sorted(source_counts.items())),
        "gate_ready_candidate_count": len(ready),
        "blocked_or_rejected_count": len(blocked),
        "hypothesis_or_gate_needed_count": len(hypotheses),
        "already_in_607_count": len(already),
        "gate_ready_candidates": [candidate_public_row(row) for row in ready],
        "highest_pressure_hypotheses": [candidate_public_row(row) for row in hypotheses[:20]],
        "blocked_examples": [candidate_public_row(row) for row in blocked[:20]],
    }


def candidate_public_row(row: Mapping[str, Any]) -> dict[str, Any]:
    public = {
        "card_name": str(row.get("_candidate_name") or candidate_name(row)),
        "source_axis": str(row.get("_source_axis") or "unknown"),
        "lane": str(row.get("_lane") or row_lane(row)),
        "decision": str(row.get("decision") or ""),
        "classification": str(row.get("_classification") or classify_decision(row)),
    }
    for key in ("decision_reasons", "commander_legality", "edhrec_rank", "policy_class"):
        if key in row:
            public[key] = row[key]
    return public


def role_watch_items(report: Mapping[str, Any]) -> list[dict[str, Any]]:
    values = report.get("role_mapping_watch_items") or []
    out = []
    if not isinstance(values, list):
        return out
    for row in values:
        if not isinstance(row, Mapping):
            continue
        out.append(
            {
                "card_name": str(row.get("card_name") or ""),
                "functional_tag": row.get("functional_tag"),
                "primary_value_lane": row.get("primary_value_lane"),
                "watch": row.get("role_mapping_watch") or [],
                "cut_policy": row.get("cut_policy"),
            }
        )
    return sorted(out, key=lambda item: item["card_name"])


def axis_assessments(reports: Mapping[str, Mapping[str, Any]], paths: Mapping[str, Path]) -> dict[str, Any]:
    assessments = {}
    for name, report in reports.items():
        summary = report.get("summary") if isinstance(report.get("summary"), Mapping) else {}
        status = str(report.get("status") or "")
        assessments[name] = {
            "status": status,
            "status_class": source_status_class(status),
            "loaded": bool(report),
            "source_report": rel(paths[name]),
            "total_cards": summary.get("total_cards"),
            "ready_replacement_candidate_count": summary.get("ready_replacement_candidate_count"),
            "direct_swap_ready_count": summary.get("direct_swap_ready_count"),
            "role_mapping_watch_count": summary.get("role_mapping_watch_count"),
        }
    return assessments


def promotion_checklist(
    *,
    shape: Mapping[str, Any],
    axis: Mapping[str, Mapping[str, Any]],
    candidates: Mapping[str, Any],
    watch_items: list[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    all_reports_loaded = all(item.get("loaded") for item in axis.values())
    axis_keep_or_watch = all(
        str(item.get("status_class")) in {"keep_607", "keep_607_with_watch"}
        for item in axis.values()
    )
    gate_ready_count = as_int(candidates.get("gate_ready_candidate_count"))
    return [
        {
            "gate": "baseline_deck_shape",
            "passed": bool(shape.get("deck_shape_ok")),
            "evidence": f"{shape.get('total_cards')} cards, commanders={shape.get('commander_names')}",
        },
        {
            "gate": "all_axis_reports_loaded",
            "passed": all_reports_loaded,
            "evidence": ", ".join(sorted(axis.keys())),
        },
        {
            "gate": "axis_decisions_do_not_promote_candidate",
            "passed": axis_keep_or_watch and gate_ready_count == 0,
            "evidence": f"gate_ready_candidate_count={gate_ready_count}",
        },
        {
            "gate": "role_tag_watch_before_new_cuts",
            "passed": len(watch_items) == 0,
            "evidence": f"role_mapping_watch_items={len(watch_items)}",
            "required_before_promotion": True,
        },
        {
            "gate": "same_lane_cut_named",
            "passed": False,
            "evidence": "No current candidate has a complete named cut plus equal gate proof.",
            "required_before_promotion": True,
        },
        {
            "gate": "equal_battle_gate_with_card_use",
            "passed": False,
            "evidence": "No current challenger has equal-opponent, equal-seed, card-used promotion proof over 607.",
            "required_before_promotion": True,
        },
    ]


def synthesize_status(candidates: Mapping[str, Any], checklist: list[Mapping[str, Any]]) -> str:
    if as_int(candidates.get("gate_ready_candidate_count")) > 0:
        return "promotion_readiness_candidate_requires_gate_review"
    if all(item.get("passed") for item in checklist if not item.get("required_before_promotion")):
        return "promotion_readiness_keep_607_no_candidate_ready"
    return "promotion_readiness_incomplete_source_evidence"


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    card_value_report_path: Path,
    mana_report_path: Path,
    staple_report_path: Path,
    selection_report_path: Path,
    interaction_report_path: Path,
    payoff_report_path: Path,
) -> dict[str, Any]:
    paths = {
        "card_value": card_value_report_path,
        "mana": mana_report_path,
        "staple": staple_report_path,
        "selection": selection_report_path,
        "interaction": interaction_report_path,
        "payoff": payoff_report_path,
    }
    reports = {name: read_json_if_exists(path) for name, path in paths.items()}
    shape = deck_shape(conn, deck_id)
    axis = axis_assessments(reports, paths)
    candidate_rows = collect_candidate_rows(reports)
    candidates = classify_candidates(candidate_rows)
    watch_items = role_watch_items(reports.get("card_value") or {})
    checklist = promotion_checklist(shape=shape, axis=axis, candidates=candidates, watch_items=watch_items)
    status = synthesize_status(candidates, checklist)
    promotion_allowed = False
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_promotion_readiness_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": status,
        "source_reports": {name: rel(path) for name, path in paths.items()},
        "deck_shape": shape,
        "axis_assessments": axis,
        "candidate_pressure": candidates,
        "role_mapping_watch_items": watch_items,
        "promotion_gate_checklist": checklist,
        "learning_model": LEARNING_MODEL,
        "external_learning": EXTERNAL_LEARNING,
        "summary": {
            "total_cards": shape.get("total_cards"),
            "deck_rows": shape.get("deck_rows"),
            "axis_count": len(axis),
            "reports_loaded": sum(1 for item in axis.values() if item.get("loaded")),
            "gate_ready_candidate_count": candidates["gate_ready_candidate_count"],
            "blocked_or_rejected_count": candidates["blocked_or_rejected_count"],
            "hypothesis_or_gate_needed_count": candidates["hypothesis_or_gate_needed_count"],
            "unique_candidate_count": candidates["unique_candidate_count"],
            "role_mapping_watch_count": len(watch_items),
            "promotion_allowed": promotion_allowed,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": promotion_allowed,
            "reason": (
                "The current learning axes agree that 607 remains protected: no candidate has "
                "a complete same-lane cut, equal-seed battle gate, and card-use proof. Legal "
                "cards such as Mana Vault and The One Ring stay hypotheses or blocked prior "
                "evidence until they beat the current role they challenge."
            ),
            "next_actions": [
                "repair role/tag watch items before trusting automated cuts",
                "generate only named same-lane packages from a specific 607 failure target",
                "run equal opponent and seed gates with trace proof that the candidate was drawn, cast, and used",
                "promote only if the challenger preserves land/ramp/draw/removal/protection/wincon density and beats 607",
            ],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    decision = payload["decision"]
    lines = [
        "# Lorehold Promotion Readiness Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- total cards: `{summary['total_cards']}`",
        f"- reports loaded: `{summary['reports_loaded']}/{summary['axis_count']}`",
        f"- unique candidates considered: `{summary['unique_candidate_count']}`",
        f"- gate-ready candidates: `{summary['gate_ready_candidate_count']}`",
        f"- hypotheses needing named cut/gate: `{summary['hypothesis_or_gate_needed_count']}`",
        f"- blocked/rejected rows: `{summary['blocked_or_rejected_count']}`",
        f"- role mapping watch items: `{summary['role_mapping_watch_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        "",
        "## Axis Assessments",
        "",
        "| Axis | Status | Class | Report |",
        "| --- | --- | --- | --- |",
    ]
    for axis_name, row in sorted(payload["axis_assessments"].items()):
        lines.append(
            f"| `{axis_name}` | `{row['status']}` | `{row['status_class']}` | `{row['source_report']}` |"
        )
    lines.extend(["", "## Candidate Pressure", ""])
    pressure = payload["candidate_pressure"]
    lines.append(f"- classification counts: `{json.dumps(pressure['classification_counts'], sort_keys=True)}`")
    lines.append(f"- lane counts: `{json.dumps(pressure['lane_counts'], sort_keys=True)}`")
    if pressure["gate_ready_candidates"]:
        lines.extend(["", "### Gate-Ready Candidates", ""])
        for row in pressure["gate_ready_candidates"]:
            lines.append(f"- `{row['card_name']}` from `{row['source_axis']}` lane `{row['lane']}`: `{row['decision']}`")
    if pressure["highest_pressure_hypotheses"]:
        lines.extend(["", "### Highest Pressure Hypotheses", ""])
        for row in pressure["highest_pressure_hypotheses"][:12]:
            lines.append(f"- `{row['card_name']}` from `{row['source_axis']}` lane `{row['lane']}`: `{row['decision']}`")
    if payload.get("role_mapping_watch_items"):
        lines.extend(["", "## Role/Tag Watch Before New Cuts", ""])
        for row in payload["role_mapping_watch_items"]:
            watch = ", ".join(str(value) for value in row.get("watch") or [])
            lines.append(
                f"- `{row['card_name']}`: tag `{row.get('functional_tag')}`, "
                f"lane `{row.get('primary_value_lane')}`, watch `{watch}`."
            )
    lines.extend(["", "## Promotion Gate Checklist", ""])
    for item in payload["promotion_gate_checklist"]:
        required = " required-before-promotion" if item.get("required_before_promotion") else ""
        lines.append(
            f"- `{item['gate']}`: passed `{str(item['passed']).lower()}`{required}; {item['evidence']}"
        )
    lines.extend(["", "## Learned Deckbuilding Model", ""])
    model = payload["learning_model"]
    for key, values in model.items():
        lines.append(f"### {key.replace('_', ' ').title()}")
        for value in values:
            lines.append(f"- {value}")
        lines.append("")
    lines.extend(["## External Sources", ""])
    for source in payload["external_learning"]:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- keep_607_as_protected_baseline: `{str(decision['keep_607_as_protected_baseline']).lower()}`")
    lines.append(f"- promotion_allowed: `{str(decision['promotion_allowed']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append("- next_actions:")
    for action in decision["next_actions"]:
        lines.append(f"  - {action}")
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
    parser.add_argument("--card-value-report", type=Path, default=None)
    parser.add_argument("--mana-report", type=Path, default=None)
    parser.add_argument("--staple-report", type=Path, default=None)
    parser.add_argument("--selection-report", type=Path, default=None)
    parser.add_argument("--interaction-report", type=Path, default=None)
    parser.add_argument("--payoff-report", type=Path, default=None)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_promotion_readiness_synthesis",
    )
    args = parser.parse_args()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            card_value_report_path=args.card_value_report or default_card_value_report(),
            mana_report_path=args.mana_report or default_mana_report(),
            staple_report_path=args.staple_report or default_staple_report(),
            selection_report_path=args.selection_report or default_selection_report(),
            interaction_report_path=args.interaction_report or default_interaction_report(),
            payoff_report_path=args.payoff_report or default_payoff_report(),
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
