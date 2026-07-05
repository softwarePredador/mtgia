#!/usr/bin/env python3
"""Scout external Lorehold material evidence against protected deck 607.

This is a learning and routing artifact, not a deck generator. It turns current
external Commander evidence into local ManaLoom classifications: already in
607, present in Lorehold variants, lab-only, rule-known but not in the local
candidate pool, or missing from local deck material. No classification here is
promotion evidence by itself.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import defaultdict
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import (
    normalize_name,
    resolve_default_knowledge_db,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_PRESSURE_REPORT = REPORT_DIR / "lorehold_pressure_safe_cut_expansion_model_20260705_current.json"
DEFAULT_SAME_LANE_REPORT = REPORT_DIR / "lorehold_same_lane_microbenchmark_decision_synthesis_20260705_current.json"
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_external_material_evidence_scout_20260705_current"
DEFAULT_BASELINE_DECK_ID = 607
DEFAULT_LOREHOLD_VARIANT_DECK_IDS = tuple(range(608, 617))
DEFAULT_LAB_DECK_IDS = tuple(range(617, 622))

EXTERNAL_SOURCE_LANES = [
    {
        "source_key": "edhrec_upgraded_spellslinger_current",
        "source": "EDHREC Lorehold upgraded spellslinger page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/upgraded/spellslinger",
        "route_type": "reference_corpus",
        "learning": (
            "The current public Lorehold surface is tagged Topdeck, Spellslinger, "
            "Discard, and Burn; high-synergy cards still point toward topdeck, "
            "miracle, big-spell conversion, and pressure payoffs."
        ),
        "candidate_cards": [
            "Storm-Kiln Artist",
            "Guttersnipe",
            "Young Pyromancer",
            "Monastery Mentor",
            "Surly Badgersaur",
            "Goldspan Dragon",
            "Glint-Horn Buccaneer",
            "Inti, Seneschal of the Sun",
        ],
    },
    {
        "source_key": "gametyrant_miracle_topdeck_pressure",
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "route_type": "topdeck_pressure_reference",
        "learning": (
            "The article reinforces Library of Leng, miracle setup, topdeck "
            "control, alternate casting, and pressure conversion rather than "
            "generic Boros goodstuff."
        ),
        "candidate_cards": [
            "Brain in a Jar",
            "Galvanoth",
            "Burning Prophet",
            "Dragon's Rage Channeler",
            "Planetarium of Wan Shi Tong",
            "Entreat the Angels",
        ],
    },
    {
        "source_key": "card_kingdom_reanimator_direction",
        "source": "Card Kingdom Lorehold synergy cards",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "route_type": "archetype_fork",
        "learning": (
            "A reanimator build is a separate direction: expensive white "
            "reanimation spells and Karmic Guide can exploit discard and cost "
            "reduction, but that is not a one-card update to the current 607 shell."
        ),
        "candidate_cards": [
            "Storm of Souls",
            "Late to Dinner",
            "Miraculous Recovery",
            "Karmic Guide",
        ],
    },
    {
        "source_key": "coolstuffinc_token_combo_voltron_directions",
        "source": "CoolStuffInc Lorehold commander article",
        "url": "https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander",
        "route_type": "archetype_fork",
        "learning": (
            "The article frames token swarm, combo, burn/damage, and Voltron as "
            "directions beyond the instant/sorcery shell. These need full-shell "
            "contracts, not isolated cuts from 607."
        ),
        "candidate_cards": [
            "Anointed Procession",
            "Cathars' Crusade",
            "Blackblade Reforged",
            "Strata Scythe",
            "Excalibur, Sword of Eden",
        ],
    },
    {
        "source_key": "commander_spellbook_storm_kiln_haze",
        "source": "Commander Spellbook Storm-Kiln Artist + Haze of Rage",
        "url": "https://commanderspellbook.com/combo/3940-5195/",
        "route_type": "combo_package",
        "learning": (
            "Storm-Kiln Artist plus Haze of Rage is a red combo lane with mana, "
            "storm, magecraft, Treasure, and creature-power outputs. It remains a "
            "package hypothesis until local identity, runtime, cuts, and natural "
            "battle proof all exist."
        ),
        "candidate_cards": ["Storm-Kiln Artist", "Haze of Rage"],
    },
    {
        "source_key": "archidekt_recent_public_corpus",
        "source": "Archidekt Lorehold commander search",
        "url": "https://archidekt.com/commanders/Lorehold%2C_the_Historian",
        "route_type": "reference_corpus",
        "learning": (
            "The public corpus is broad and fresh enough to mine, but raw public "
            "deck presence is only reference evidence until normalized into local "
            "identity, legality, lane, and battle-gate artifacts."
        ),
        "candidate_cards": [],
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
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def as_summary(payload: Mapping[str, Any]) -> dict[str, Any]:
    summary = payload.get("summary")
    return dict(summary) if isinstance(summary, Mapping) else {}


def unique_candidate_names(source_lanes: list[dict[str, Any]]) -> list[str]:
    seen: dict[str, str] = {}
    for source in source_lanes:
        for card_name in as_list(source.get("candidate_cards")):
            name = str(card_name).strip()
            if name:
                seen.setdefault(normalize_name(name), name)
    return sorted(seen.values(), key=lambda item: normalize_name(item))


def source_index(source_lanes: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for source in source_lanes:
        for card_name in as_list(source.get("candidate_cards")):
            name = str(card_name).strip()
            if name:
                index[normalize_name(name)].append(
                    {
                        "source_key": source["source_key"],
                        "source": source["source"],
                        "url": source["url"],
                        "route_type": source["route_type"],
                    }
                )
    return dict(index)


def deck_presence(
    conn: sqlite3.Connection,
    candidate_names: list[str],
    *,
    baseline_deck_id: int,
    variant_deck_ids: tuple[int, ...],
    lab_deck_ids: tuple[int, ...],
) -> dict[str, dict[str, Any]]:
    presence = {
        normalize_name(name): {
            "in_607": False,
            "baseline_quantity": 0,
            "lorehold_variant_deck_ids": [],
            "lab_deck_ids": [],
            "all_deck_ids": [],
            "deck_rows": [],
        }
        for name in candidate_names
    }
    if not candidate_names or not sqlite_connection_has_table(conn, "deck_cards"):
        return presence
    names = [normalize_name(name) for name in candidate_names]
    placeholders = ",".join("?" for _ in names)
    rows = conn.execute(
        f"""
        SELECT deck_id, card_name, COALESCE(quantity, 1) AS quantity
        FROM deck_cards
        WHERE lower(card_name) IN ({placeholders})
        ORDER BY lower(card_name), deck_id
        """,
        names,
    ).fetchall()
    for row in rows:
        norm = normalize_name(row["card_name"])
        data = presence.setdefault(
            norm,
            {
                "in_607": False,
                "baseline_quantity": 0,
                "lorehold_variant_deck_ids": [],
                "lab_deck_ids": [],
                "all_deck_ids": [],
                "deck_rows": [],
            },
        )
        deck_id = int(row["deck_id"])
        quantity = int(row["quantity"] or 1)
        data["all_deck_ids"].append(deck_id)
        data["deck_rows"].append({"deck_id": deck_id, "card_name": row["card_name"], "quantity": quantity})
        if deck_id == baseline_deck_id:
            data["in_607"] = True
            data["baseline_quantity"] += quantity
        if deck_id in variant_deck_ids and deck_id not in data["lorehold_variant_deck_ids"]:
            data["lorehold_variant_deck_ids"].append(deck_id)
        if deck_id in lab_deck_ids and deck_id not in data["lab_deck_ids"]:
            data["lab_deck_ids"].append(deck_id)
    for data in presence.values():
        data["all_deck_ids"] = sorted(set(data["all_deck_ids"]))
        data["lorehold_variant_deck_ids"] = sorted(data["lorehold_variant_deck_ids"])
        data["lab_deck_ids"] = sorted(data["lab_deck_ids"])
    return presence


def battle_rule_presence(conn: sqlite3.Connection, candidate_names: list[str]) -> dict[str, dict[str, Any]]:
    rules = {
        normalize_name(name): {
            "rule_count": 0,
            "verified_auto_rule_count": 0,
            "rules": [],
        }
        for name in candidate_names
    }
    if not candidate_names or not sqlite_connection_has_table(conn, "battle_card_rules"):
        return rules
    names = [normalize_name(name) for name in candidate_names]
    placeholders = ",".join("?" for _ in names)
    rows = conn.execute(
        f"""
        SELECT card_name, logical_rule_key, review_status, execution_status
        FROM battle_card_rules
        WHERE lower(card_name) IN ({placeholders})
        ORDER BY lower(card_name), logical_rule_key
        """,
        names,
    ).fetchall()
    for row in rows:
        norm = normalize_name(row["card_name"])
        data = rules.setdefault(norm, {"rule_count": 0, "verified_auto_rule_count": 0, "rules": []})
        data["rule_count"] += 1
        if row["review_status"] == "verified" and row["execution_status"] == "auto":
            data["verified_auto_rule_count"] += 1
        data["rules"].append(
            {
                "logical_rule_key": row["logical_rule_key"],
                "review_status": row["review_status"],
                "execution_status": row["execution_status"],
            }
        )
    return rules


def classify_candidate(
    *,
    name: str,
    source_rows: list[dict[str, Any]],
    presence: Mapping[str, Any],
    rule_presence: Mapping[str, Any],
) -> tuple[str, str, list[str]]:
    route_types = {str(row["route_type"]) for row in source_rows}
    blockers: list[str] = []
    if presence.get("in_607"):
        classification = "already_in_protected_607"
        actionability = "baseline_card_no_change"
        blockers.append("already_in_607")
    elif presence.get("lorehold_variant_deck_ids"):
        classification = "local_lorehold_variant_candidate_not_in_607"
        actionability = "local_candidate_but_blocked_by_current_cut_safety_or_prior_route"
        blockers.append("no_seed_safe_cut_or_prior_reject")
    elif presence.get("lab_deck_ids"):
        classification = "non_lorehold_lab_only"
        actionability = "not_in_current_lorehold_variant_pool"
        blockers.append("lab_only_not_lorehold_candidate")
    elif int(rule_presence.get("rule_count") or 0) > 0:
        classification = "rule_known_external_not_in_lorehold_candidate_pool"
        actionability = "requires_identity_and_deck_materialization_before_cut_work"
        blockers.append("not_in_current_lorehold_deck_pool")
    else:
        classification = "external_missing_from_local_deck_pool"
        actionability = "requires_import_or_identity_resolution_before_deckbuilding_test"
        blockers.append("missing_from_local_deck_pool")

    if "archetype_fork" in route_types and not presence.get("in_607"):
        actionability = "archetype_fork_only_requires_full_shell_contract"
        blockers.append("not_a_one_for_one_607_cut")
    if "combo_package" in route_types and not presence.get("in_607"):
        actionability = "combo_package_research_only_requires_runtime_cut_and_battle_proof"
        blockers.append("combo_package_not_single_card_proof")
    if name == "Storm-Kiln Artist":
        blockers.append("prior_arcane_signet_replacement_rejected_by_winota_guard")
    if name == "Possibility Storm":
        blockers.append("prior_creative_technique_replacement_naturally_rejected")
    return classification, actionability, sorted(set(blockers))


def build_candidate_rows(
    conn: sqlite3.Connection,
    *,
    baseline_deck_id: int,
    variant_deck_ids: tuple[int, ...],
    lab_deck_ids: tuple[int, ...],
) -> list[dict[str, Any]]:
    candidates = unique_candidate_names(EXTERNAL_SOURCE_LANES)
    sources_by_card = source_index(EXTERNAL_SOURCE_LANES)
    presence_by_card = deck_presence(
        conn,
        candidates,
        baseline_deck_id=baseline_deck_id,
        variant_deck_ids=variant_deck_ids,
        lab_deck_ids=lab_deck_ids,
    )
    rules_by_card = battle_rule_presence(conn, candidates)
    rows: list[dict[str, Any]] = []
    for name in candidates:
        norm = normalize_name(name)
        presence = presence_by_card.get(norm, {})
        rules = rules_by_card.get(norm, {})
        source_rows = sources_by_card.get(norm, [])
        classification, actionability, blockers = classify_candidate(
            name=name,
            source_rows=source_rows,
            presence=presence,
            rule_presence=rules,
        )
        rows.append(
            {
                "card_name": name,
                "classification": classification,
                "actionability": actionability,
                "source_keys": [row["source_key"] for row in source_rows],
                "route_types": sorted({row["route_type"] for row in source_rows}),
                "in_607": bool(presence.get("in_607")),
                "baseline_quantity": int(presence.get("baseline_quantity") or 0),
                "lorehold_variant_deck_ids": as_list(presence.get("lorehold_variant_deck_ids")),
                "lab_deck_ids": as_list(presence.get("lab_deck_ids")),
                "all_deck_ids": as_list(presence.get("all_deck_ids")),
                "battle_rule_count": int(rules.get("rule_count") or 0),
                "verified_auto_rule_count": int(rules.get("verified_auto_rule_count") or 0),
                "blockers": blockers,
            }
        )
    return sorted(rows, key=lambda row: (row["classification"], row["card_name"]))


def package_assessments(candidate_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_name = {normalize_name(row["card_name"]): row for row in candidate_rows}

    def card_status(card_name: str) -> dict[str, Any]:
        row = by_name.get(normalize_name(card_name), {})
        return {
            "card_name": card_name,
            "classification": row.get("classification", "not_in_external_candidate_index"),
            "in_607": bool(row.get("in_607")),
            "lorehold_variant_deck_ids": as_list(row.get("lorehold_variant_deck_ids")),
            "battle_rule_count": int(row.get("battle_rule_count") or 0),
        }

    storm_haze_cards = [card_status("Storm-Kiln Artist"), card_status("Haze of Rage")]
    storm_haze_has_missing = any(card["classification"] == "external_missing_from_local_deck_pool" for card in storm_haze_cards)
    storm_haze_has_local = any(card["lorehold_variant_deck_ids"] for card in storm_haze_cards)
    if storm_haze_has_missing and storm_haze_has_local:
        storm_haze_status = "research_only_mixed_local_and_missing_material"
    else:
        storm_haze_status = "research_only_requires_cut_runtime_and_battle_proof"

    return [
        {
            "package_key": "storm_kiln_artist_haze_of_rage_combo",
            "route_type": "combo_package",
            "cards": storm_haze_cards,
            "status": storm_haze_status,
            "gate_ready": False,
            "natural_battle_allowed_now": False,
            "reason": (
                "Storm-Kiln Artist is visible locally, but Haze of Rage is not a "
                "current local Lorehold deck candidate. Even if imported, the "
                "package still needs cut-safety, runtime scope, and natural battle proof."
            ),
        },
        {
            "package_key": "white_reanimator_lorehold_shell",
            "route_type": "archetype_fork",
            "cards": [
                card_status("Storm of Souls"),
                card_status("Late to Dinner"),
                card_status("Miraculous Recovery"),
                card_status("Karmic Guide"),
            ],
            "status": "archetype_fork_only_requires_full_shell_contract",
            "gate_ready": False,
            "natural_battle_allowed_now": False,
            "reason": "This changes the deck thesis toward reanimator and cannot justify one-for-one cuts from 607.",
        },
        {
            "package_key": "voltron_or_token_closure_shell",
            "route_type": "archetype_fork",
            "cards": [
                card_status("Blackblade Reforged"),
                card_status("Strata Scythe"),
                card_status("Excalibur, Sword of Eden"),
                card_status("Anointed Procession"),
                card_status("Cathars' Crusade"),
            ],
            "status": "archetype_fork_only_requires_full_shell_contract",
            "gate_ready": False,
            "natural_battle_allowed_now": False,
            "reason": "This is a new closure plan, not direct evidence that a protected 607 anchor should be cut.",
        },
    ]


def count_rows(rows: list[dict[str, Any]], field: str, value: Any = True) -> int:
    return sum(1 for row in rows if row.get(field) == value)


def build_payload(
    conn: sqlite3.Connection,
    *,
    db_path: Path,
    pressure_report: Mapping[str, Any],
    same_lane_report: Mapping[str, Any],
    value_model: Mapping[str, Any],
    source_paths: Mapping[str, Path],
    baseline_deck_id: int = DEFAULT_BASELINE_DECK_ID,
    variant_deck_ids: tuple[int, ...] = DEFAULT_LOREHOLD_VARIANT_DECK_IDS,
    lab_deck_ids: tuple[int, ...] = DEFAULT_LAB_DECK_IDS,
) -> dict[str, Any]:
    candidate_rows = build_candidate_rows(
        conn,
        baseline_deck_id=baseline_deck_id,
        variant_deck_ids=variant_deck_ids,
        lab_deck_ids=lab_deck_ids,
    )
    packages = package_assessments(candidate_rows)
    pressure_summary = as_summary(pressure_report)
    same_lane_summary = as_summary(same_lane_report)
    value_summary = as_summary(value_model)
    missing_count = count_rows(candidate_rows, "classification", "external_missing_from_local_deck_pool")
    local_variant_count = count_rows(candidate_rows, "classification", "local_lorehold_variant_candidate_not_in_607")
    rule_known_external_count = count_rows(candidate_rows, "classification", "rule_known_external_not_in_lorehold_candidate_pool")
    archetype_card_count = sum(
        1
        for row in candidate_rows
        if "archetype_fork" in row.get("route_types", []) and row.get("classification") != "already_in_protected_607"
    )
    status = "external_material_evidence_found_but_no_gate_ready_keep_607"
    recommended_next_action = "build_external_candidate_identity_import_preflight_before_any_new_gate"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_external_material_evidence_scout",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_db": str(db_path),
        "source_reports": {name: rel(path) for name, path in source_paths.items()},
        "external_source_lanes": EXTERNAL_SOURCE_LANES,
        "status": status,
        "summary": {
            "current_baseline": f"deck_{baseline_deck_id}",
            "external_source_count": len(EXTERNAL_SOURCE_LANES),
            "external_candidate_count": len(candidate_rows),
            "in_607_count": count_rows(candidate_rows, "in_607", True),
            "local_lorehold_variant_candidate_count": local_variant_count,
            "non_lorehold_lab_only_count": count_rows(candidate_rows, "classification", "non_lorehold_lab_only"),
            "rule_known_external_not_in_lorehold_candidate_pool_count": rule_known_external_count,
            "missing_from_local_deck_pool_count": missing_count,
            "archetype_fork_candidate_count": archetype_card_count,
            "package_assessment_count": len(packages),
            "gate_ready_now_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "pressure_report_status": pressure_report.get("status"),
            "pressure_seed_safe_cut_ready_count": int(pressure_summary.get("seed_safe_cut_ready_count") or 0),
            "pressure_gate_ready_package_count": int(pressure_summary.get("gate_ready_package_count") or 0),
            "same_lane_report_status": same_lane_report.get("status"),
            "same_lane_prior_natural_reject_count": int(same_lane_summary.get("prior_natural_reject_count") or 0),
            "value_model_status": value_model.get("status"),
            "value_model_quantity_total": int(value_summary.get("quantity_total") or 0),
            "recommended_next_action": recommended_next_action,
        },
        "candidate_classifications": candidate_rows,
        "package_assessments": packages,
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "run identity/import preflight for missing material cards before any deck test",
                "separate archetype forks from one-for-one 607 cut work",
                "keep Storm-Kiln/Haze as combo research until Haze exists locally and a safe package is declared",
                "rerun safe-cut logic only after material evidence changes a candidate or cut row",
            ],
            "reason": (
                "External sources add real learning lanes, but the current internal "
                "state still has zero seed-safe cuts, prior natural rejects on the "
                "only same-lane static package, and no package that is ready for a "
                "natural battle gate."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold External Material Evidence Scout",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- Deck 607 mutated: `{payload['deck_607_mutated']}`",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in [
        "external_source_count",
        "external_candidate_count",
        "in_607_count",
        "local_lorehold_variant_candidate_count",
        "rule_known_external_not_in_lorehold_candidate_pool_count",
        "missing_from_local_deck_pool_count",
        "archetype_fork_candidate_count",
        "gate_ready_now_count",
    ]:
        lines.append(f"| `{key}` | `{summary[key]}` |")
    lines.extend(
        [
            "",
            "## External Source Lanes",
            "",
            "| Source | Route | Candidate Cards | Learning |",
            "| --- | --- | --- | --- |",
        ]
    )
    for source in payload["external_source_lanes"]:
        candidates = ", ".join(source.get("candidate_cards") or ["source_lane_only"])
        lines.append(
            f"| [{source['source']}]({source['url']}) | `{source['route_type']}` | "
            f"{candidates} | {source['learning']} |"
        )
    lines.extend(
        [
            "",
            "## Candidate Classification",
            "",
            "| Card | Classification | Actionability | 607 | Lorehold Variants | Rules |",
            "| --- | --- | --- | ---: | --- | ---: |",
        ]
    )
    for row in payload["candidate_classifications"]:
        variants = ",".join(str(deck_id) for deck_id in row["lorehold_variant_deck_ids"]) or "-"
        lines.append(
            f"| {row['card_name']} | `{row['classification']}` | `{row['actionability']}` | "
            f"`{row['in_607']}` | {variants} | `{row['verified_auto_rule_count']}` |"
        )
    lines.extend(
        [
            "",
            "## Package Assessments",
            "",
            "| Package | Route | Status | Natural Battle Allowed | Reason |",
            "| --- | --- | --- | ---: | --- |",
        ]
    )
    for package in payload["package_assessments"]:
        lines.append(
            f"| `{package['package_key']}` | `{package['route_type']}` | `{package['status']}` | "
            f"`{package['natural_battle_allowed_now']}` | {package['reason']} |"
        )
    decision = payload["decision"]
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{decision['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{decision['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{decision['promotion_allowed']}`",
            f"- Reason: {decision['reason']}",
            "",
            "## Next Actions",
            "",
        ]
    )
    for action in decision["next_actions"]:
        lines.append(f"- {action}")
    return "\n".join(lines) + "\n"


def open_readonly_db(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--pressure-report", type=Path, default=DEFAULT_PRESSURE_REPORT)
    parser.add_argument("--same-lane-report", type=Path, default=DEFAULT_SAME_LANE_REPORT)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()

    pressure_report = read_json(args.pressure_report)
    same_lane_report = read_json(args.same_lane_report)
    value_model = read_json(args.value_model)
    with open_readonly_db(args.db) as conn:
        payload = build_payload(
            conn,
            db_path=args.db,
            pressure_report=pressure_report,
            same_lane_report=same_lane_report,
            value_model=value_model,
            source_paths={
                "pressure_report": args.pressure_report,
                "same_lane_report": args.same_lane_report,
                "value_model": args.value_model,
            },
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
                "promotion_allowed": payload["summary"]["promotion_allowed"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
