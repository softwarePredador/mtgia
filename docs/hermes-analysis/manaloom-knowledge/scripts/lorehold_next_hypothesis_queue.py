#!/usr/bin/env python3
"""Build the next Lorehold package queue from the strategy dependency map.

This script is read-only. It mines high-ranked Lorehold variants, checks local
runtime/rule availability in the current candidate SQLite DB, applies the v3
cut-safety contract, and emits a small queue for the next battle gates.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_STRATEGY_AUDIT = REPORT_DIR / "lorehold_strategy_learning_audit_20260627_v3.json"
DEFAULT_DB = (
    REPORT_DIR
    / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
    / "knowledge_candidate.db"
)
DEFAULT_PACKAGE_GATE_REPORTS = [
    REPORT_DIR / "lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json",
    REPORT_DIR / "lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json",
    REPORT_DIR / "lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json",
    REPORT_DIR / "lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json",
    REPORT_DIR / "lorehold_radiant_scrollwielder_gate_20260627_v1_fixed.json",
]


PACKAGE_IDEAS = [
    {
        "package_key": "perch_protection_cut_avatar_wrath",
        "source_decks": ["deck_615", "deck_614"],
        "family": "pressure_absorber",
        "adds": ["Perch Protection"],
        "cuts": ["Avatar's Wrath"],
        "lane": "protection_window",
        "targets": ["seed_20260625_pressure_conversion", "combat_pressure_life_zero"],
        "hypothesis": (
            "Perch Protection is present in the two strongest non-607 variants and has an active rule. "
            "It tests a same-lane protection upgrade over Avatar's Wrath while preserving Dawn's Truce, "
            "Fated Clash, Hexing Squelcher, High Noon, medallions, Storm Herd, and Thor."
        ),
        "required_telemetry": [
            "combat-pressure losses should fall or loss turn should move later",
            "miracle_cast and topdeck_manipulation_activated must not fall in seed 42",
            "discard_to_top_replacement should convert into a survival or second-window line",
        ],
    },
    {
        "package_key": "akromas_will_cut_avatar_wrath",
        "source_decks": ["deck_614"],
        "family": "pressure_absorber",
        "adds": ["Akroma's Will"],
        "cuts": ["Avatar's Wrath"],
        "lane": "protection_window",
        "targets": ["seed_20260625_pressure_conversion", "finisher_window"],
        "hypothesis": (
            "Akroma's Will is a 614 protection/finisher bridge with active rules. "
            "It challenges the same Avatar's Wrath slot without touching the locked protection shell."
        ),
        "required_telemetry": [
            "protection/combat-swing exposure must appear before life-zero losses",
            "seed 42 cannot regress on miracle/topdeck conversion",
        ],
    },
    {
        "package_key": "silence_cut_avatar_wrath",
        "source_decks": ["deck_615", "deck_614"],
        "family": "spell_protection",
        "adds": ["Silence"],
        "cuts": ["Avatar's Wrath"],
        "lane": "protection_window",
        "targets": ["second_approach_window", "decisive_spell_turn_protection"],
        "hypothesis": (
            "Silence is shared by 614/615 and protects the decisive Lorehold or Approach turn at one mana. "
            "This tests whether cheap proactive stack protection beats a slower protection spell."
        ),
        "required_telemetry": [
            "candidate must show protected decisive spell turns or delayed losses",
            "spell volume cannot fall in the strong seed",
        ],
    },
    {
        "package_key": "reprieve_cut_avatar_wrath",
        "source_decks": ["deck_615"],
        "family": "spell_protection",
        "adds": ["Reprieve"],
        "cuts": ["Avatar's Wrath"],
        "lane": "protection_window",
        "targets": ["tempo_survival", "second_approach_window"],
        "hypothesis": (
            "Reprieve is a 615 tempo/protection card with active rules. It can buy a turn and draw without "
            "cutting the locked cards that already hold seed 42 together."
        ),
        "required_telemetry": [
            "loss turn should move later in pressure seeds",
            "draw/protection value must not lower seed-42 miracle conversion",
        ],
    },
    {
        "package_key": "grand_abolisher_cut_mother_of_runes",
        "source_decks": ["deck_615"],
        "family": "spell_protection",
        "adds": ["Grand Abolisher"],
        "cuts": ["Mother of Runes"],
        "lane": "protection_window",
        "targets": ["decisive_spell_turn_protection"],
        "hypothesis": (
            "Grand Abolisher protects the whole decisive turn and appears in 615. "
            "Mother of Runes is a same-creature-protection comparison slot, but this cut is risky "
            "because Mother is part of the current early protection package."
        ),
        "required_telemetry": [
            "commander/decisive turn survival must improve enough to justify losing Mother of Runes",
            "seed 42 must not lose the early protection pattern",
        ],
    },
    {
        "package_key": "dragon_rage_channeler_cut_scarlet_witch",
        "source_decks": ["deck_614"],
        "family": "topdeck_filter",
        "adds": ["Dragon's Rage Channeler"],
        "cuts": ["The Scarlet Witch"],
        "lane": "topdeck_miracle_setup",
        "targets": ["seed_7_missing_early_engine"],
        "hypothesis": (
            "Dragon's Rage Channeler is a low-cost 614 topdeck/filter engine with active rules. "
            "The Scarlet Witch is currently an unresolved/materialization-sensitive slot in the champion role audit, "
            "making this a possible early-engine test if the cut remains rule-safe."
        ),
        "required_telemetry": [
            "seed 7 must improve topdeck_manipulation_activated or early spell volume",
            "seed 42 miracle_cast cannot fall",
        ],
    },
    {
        "package_key": "radiant_scrollwielder_cut_scarlet_witch",
        "source_decks": ["deck_614"],
        "family": "graveyard_recursion",
        "adds": ["Radiant Scrollwielder"],
        "cuts": ["The Scarlet Witch"],
        "lane": "graveyard_recursion",
        "targets": ["spell_reuse", "pressure_lifegain"],
        "hypothesis": (
            "Radiant Scrollwielder is a 614 recursion/lifegain bridge, but it needs rule coverage before any "
            "battle result can be trusted."
        ),
        "required_telemetry": [
            "graveyard spell reuse or lifegain must appear in natural exposure",
            "no promotion if runtime/model evidence is missing",
        ],
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def lookup_forms(value: object) -> set[str]:
    raw = re.sub(r"\s+", " ", str(value or "").lower()).strip()
    return {form for form in {raw, normalize(raw)} if form}


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def deck_card_names(report: dict[str, Any], deck_key: str) -> set[str]:
    deck_id = deck_key.replace("deck_", "")
    return {
        str(row.get("card_name"))
        for row in ((report.get("deck_summaries") or {}).get(deck_id) or {}).get("cards", [])
        if row.get("card_name")
    }


def card_decision_lookup(report: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        row.get("card_name"): row
        for row in ((report.get("card_decision_manifest") or {}).get("cards") or [])
        if row.get("card_name")
    }


def cut_guardrail_lookup(report: dict[str, Any]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    guardrails = (report.get("strategy_dependency_map") or {}).get("cut_guardrails") or {}
    for section in ("locked_or_protected", "risky_same_lane_only"):
        for row in guardrails.get(section) or []:
            if row.get("card_name"):
                out[row["card_name"]] = {**row, "guardrail_section": section}
    return out


def active_rule_counts(conn: sqlite3.Connection, names: list[str]) -> dict[str, int]:
    if not names:
        return {}
    lookup_values = sorted({form for name in names for form in lookup_forms(name)})
    placeholders = ",".join("?" for _ in lookup_values)
    rows = conn.execute(
        f"""
        SELECT card_name, COUNT(*) AS active_rules
        FROM battle_card_rules
        WHERE normalized_name IN ({placeholders})
          AND COALESCE(execution_status, '') IN ('active', 'verified', 'auto', 'reviewed')
        GROUP BY card_name
        """,
        lookup_values,
    ).fetchall()
    counts = {str(row["card_name"]): int(row["active_rules"] or 0) for row in rows}
    lookup_to_name = {
        form: key
        for key in counts
        for form in lookup_forms(key)
    }
    out: dict[str, int] = {}
    for name in names:
        matched_name = next(
            (lookup_to_name[form] for form in lookup_forms(name) if form in lookup_to_name),
            "",
        )
        out[name] = int(counts.get(name) or counts.get(matched_name, 0))
    return out


def oracle_presence(conn: sqlite3.Connection, names: list[str]) -> dict[str, bool]:
    if not names:
        return {}
    lookup_values = sorted({form for name in names for form in lookup_forms(name)})
    placeholders = ",".join("?" for _ in lookup_values)
    rows = conn.execute(
        f"SELECT name, normalized_name FROM card_oracle_cache WHERE normalized_name IN ({placeholders})",
        lookup_values,
    ).fetchall()
    present = {
        form
        for row in rows
        for value in (row["name"], row["normalized_name"])
        for form in lookup_forms(value)
    }
    return {name: bool(lookup_forms(name) & present) for name in names}


def package_status(
    idea: dict[str, Any],
    *,
    report: dict[str, Any],
    oracle: dict[str, bool],
    rules: dict[str, int],
    cut_guardrails: dict[str, dict[str, Any]],
    card_decisions: dict[str, dict[str, Any]],
) -> tuple[str, list[str]]:
    reasons: list[str] = []
    for card in idea["adds"]:
        if not oracle.get(card):
            reasons.append(f"missing_oracle:{card}")
        if int(rules.get(card) or 0) <= 0:
            reasons.append(f"missing_active_rule:{card}")
    for cut in idea["cuts"]:
        guardrail = cut_guardrails.get(cut)
        if guardrail and guardrail.get("guardrail_section") == "locked_or_protected":
            reasons.append(f"locked_cut:{cut}")
        decision = card_decisions.get(cut) or {}
        if decision.get("decision") in {"locked_core", "mana_base_core"}:
            reasons.append(f"core_cut:{cut}")
        if decision.get("status") in {"missing_battle_rule_model", "unresolved_rule_or_aggregate_gap"}:
            reasons.append(f"cut_has_unresolved_rule:{cut}")
    if any(reason.startswith(("missing_oracle", "missing_active_rule")) for reason in reasons):
        return "blocked_runtime_rule_gap", reasons
    if any(reason.startswith(("locked_cut", "core_cut")) for reason in reasons):
        return "blocked_cut_contract", reasons
    if any(reason.startswith("cut_has_unresolved_rule") for reason in reasons):
        return "needs_manual_review", reasons
    if any(cut in cut_guardrails for cut in idea["cuts"]):
        return "risky_same_lane_only", reasons
    return "gate_ready", reasons


def score_package(idea: dict[str, Any], status: str, variant_presence: int) -> int:
    score = 0
    if status == "gate_ready":
        score += 50
    elif status == "risky_same_lane_only":
        score += 25
    elif status == "needs_manual_review":
        score += 10
    score += 8 * variant_presence
    if "seed_7_missing_early_engine" in idea.get("targets", []):
        score += 8
    if "seed_20260625_pressure_conversion" in idea.get("targets", []):
        score += 10
    if idea.get("lane") == "protection_window":
        score += 5
    return score


def load_prior_gate_results(paths: list[Path]) -> dict[str, dict[str, Any]]:
    results: dict[str, dict[str, Any]] = {}
    for path in paths:
        if not path.exists():
            continue
        payload = read_json(path)
        for package in payload.get("packages") or []:
            key = str(package.get("package_key") or "")
            if not key:
                continue
            gate = package.get("gate_summary") or {}
            baseline = gate.get("baseline") or {}
            candidate = gate.get("candidate") or {}
            result = {
                "source": str(path),
                "status": package.get("status"),
                "baseline_wins": int(baseline.get("wins") or 0),
                "baseline_losses": int(baseline.get("losses") or 0),
                "candidate_wins": int(candidate.get("wins") or 0),
                "candidate_losses": int(candidate.get("losses") or 0),
                "delta_pp": float(gate.get("delta_pp") or 0.0),
                "added_rule_counts": (package.get("candidate_meta") or {}).get("added_rule_counts") or {},
            }
            if result["delta_pp"] < 0:
                result["decision"] = "tested_negative_do_not_promote"
            elif result["candidate_wins"] >= result["baseline_wins"]:
                result["decision"] = "positive_gate_needs_deeper_validation"
            else:
                result["decision"] = "tested_inconclusive"
            results[key] = result
    return results


def apply_prior_gate_status(status: str, prior_gate: dict[str, Any] | None) -> str:
    if not prior_gate:
        return status
    if prior_gate.get("decision") == "tested_negative_do_not_promote":
        return "tested_negative_do_not_promote"
    if prior_gate.get("decision") == "positive_gate_needs_deeper_validation":
        return "positive_gate_needs_deeper_validation"
    return status


def build_queue(
    report: dict[str, Any],
    conn: sqlite3.Connection,
    prior_gate_reports: list[Path] | None = None,
) -> dict[str, Any]:
    deck_sets = {key: deck_card_names(report, key) for key in ("deck_607", "deck_615", "deck_614")}
    cut_guardrails = cut_guardrail_lookup(report)
    card_decisions = card_decision_lookup(report)
    prior_gate_results = load_prior_gate_results(prior_gate_reports or [])
    all_adds = sorted({card for idea in PACKAGE_IDEAS for card in idea["adds"]})
    oracle = oracle_presence(conn, all_adds)
    rules = active_rule_counts(conn, all_adds)
    rows = []
    status_counts: Counter[str] = Counter()
    for idea in PACKAGE_IDEAS:
        variant_presence = sum(
            1 for deck_key in idea.get("source_decks", [])
            if all(card in deck_sets.get(deck_key, set()) for card in idea["adds"])
        )
        status, blockers = package_status(
            idea,
            report=report,
            oracle=oracle,
            rules=rules,
            cut_guardrails=cut_guardrails,
            card_decisions=card_decisions,
        )
        prior_gate = prior_gate_results.get(idea["package_key"])
        status = apply_prior_gate_status(status, prior_gate)
        visible_blockers = list(blockers)
        if status in {
            "tested_negative_do_not_promote",
            "positive_gate_needs_deeper_validation",
        }:
            visible_blockers = []
        status_counts[status] += 1
        rows.append(
            {
                **idea,
                "status": status,
                "score": score_package(idea, status, variant_presence),
                "variant_presence": variant_presence,
                "blockers": visible_blockers,
                "prior_gate": prior_gate or {},
                "add_oracle_ready": {card: oracle.get(card, False) for card in idea["adds"]},
                "add_active_rule_counts": {card: int(rules.get(card) or 0) for card in idea["adds"]},
                "cut_guardrails": {
                    cut: cut_guardrails.get(cut)
                    for cut in idea["cuts"]
                    if cut in cut_guardrails
                },
                "cut_decisions": {
                    cut: {
                        key: value
                        for key, value in (card_decisions.get(cut) or {}).items()
                        if key in {"decision", "status", "package_lane", "effective_role"}
                    }
                    for cut in idea["cuts"]
                },
            }
        )
    rows.sort(key=lambda row: (-int(row["score"]), row["status"], row["package_key"]))
    return {
        "generated_at": utc_now(),
        "strategy_audit": str(DEFAULT_STRATEGY_AUDIT),
        "source_db": str(DEFAULT_DB),
        "source_decks": {
            key: {
                "card_count": len(cards),
                "new_vs_607": sorted(cards - deck_sets["deck_607"]),
                "missing_from_607": sorted(deck_sets["deck_607"] - cards),
            }
            for key, cards in deck_sets.items()
            if key != "deck_607"
        },
        "summary": {
            "status_counts": dict(sorted(status_counts.items())),
            "gate_ready_count": status_counts.get("gate_ready", 0),
            "risky_same_lane_only_count": status_counts.get("risky_same_lane_only", 0),
            "tested_negative_count": status_counts.get("tested_negative_do_not_promote", 0),
            "blocked_count": sum(
                count for status, count in status_counts.items()
                if status.startswith("blocked")
            ),
        },
        "promotion_contract": (report.get("strategy_dependency_map") or {})
        .get("next_hypothesis_contract", {}),
        "queue": rows,
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Next Hypothesis Queue - 2026-06-27",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Strategy audit: `{payload['strategy_audit']}`",
        f"- Source DB: `{payload['source_db']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Status counts: `{json.dumps(payload['summary']['status_counts'], sort_keys=True)}`",
        f"- Gate-ready packages: `{payload['summary']['gate_ready_count']}`",
        f"- Risky same-lane-only packages: `{payload['summary']['risky_same_lane_only_count']}`",
        f"- Tested negative packages: `{payload['summary']['tested_negative_count']}`",
        f"- Blocked packages: `{payload['summary']['blocked_count']}`",
        "",
        "## Queue",
        "",
        "| Rank | Package | Status | Score | Adds | Cuts | Lane | Targets | Prior Gate | Blockers |",
        "| ---: | --- | --- | ---: | --- | --- | --- | --- | --- | --- |",
    ]
    for index, row in enumerate(payload["queue"], start=1):
        prior = row.get("prior_gate") or {}
        prior_text = (
            f"{prior.get('candidate_wins')}-{prior.get('candidate_losses')} vs "
            f"{prior.get('baseline_wins')}-{prior.get('baseline_losses')} "
            f"({float(prior.get('delta_pp') or 0):+.2f} pp)"
            if prior
            else "none"
        )
        lines.append(
            "| {rank} | `{package}` | `{status}` | {score} | {adds} | {cuts} | {lane} | {targets} | {prior} | {blockers} |".format(
                rank=index,
                package=row["package_key"],
                status=row["status"],
                score=row["score"],
                adds=", ".join(row["adds"]),
                cuts=", ".join(row["cuts"]),
                lane=row["lane"],
                targets=", ".join(row["targets"]),
                prior=prior_text,
                blockers=", ".join(row["blockers"]) or "none",
            )
        )
    lines.extend(["", "## Gate-Ready Detail", ""])
    for row in payload["queue"]:
        if row["status"] != "gate_ready":
            continue
        lines.append(f"### {row['package_key']}")
        lines.append("")
        lines.append(f"- Hypothesis: {row['hypothesis']}")
        lines.append(f"- Source decks: `{', '.join(row['source_decks'])}`")
        lines.append(f"- Runtime/rule readiness: `{json.dumps(row['add_active_rule_counts'], sort_keys=True)}`")
        for telemetry in row["required_telemetry"]:
            lines.append(f"- Required telemetry: {telemetry}")
        lines.append("")
    lines.extend(["## Promotion Contract", ""])
    contract = payload.get("promotion_contract") or {}
    for group in ("promotion_bar", "must_target", "required_telemetry", "hard_reject_if"):
        for item in contract.get(group) or []:
            lines.append(f"- {group}: {item}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--package-gate-report", type=Path, action="append")
    parser.add_argument("--stem", default="lorehold_next_hypothesis_queue_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = read_json(args.strategy_audit)
    package_gate_reports = args.package_gate_report or [
        path for path in DEFAULT_PACKAGE_GATE_REPORTS if path.exists()
    ]
    with connect(args.db) as conn:
        payload = build_queue(report, conn, package_gate_reports)
    payload["strategy_audit"] = str(args.strategy_audit)
    payload["source_db"] = str(args.db)
    payload["package_gate_reports"] = [str(path) for path in package_gate_reports]
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload) + "\n", encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
