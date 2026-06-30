#!/usr/bin/env python3
"""Audit ManaLoom Commander deck planning flow against researched sources."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
CONTRACT_DOC = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
SUPPORT_FILE = REPO_ROOT / "server/lib/ai/commander_deckbuilding_contract_support.dart"
SUPPORT_TEST = REPO_ROOT / "server/test/commander_deckbuilding_contract_support_test.dart"

RESEARCH_SOURCES = [
    {
        "source": "Wizards Commander format page",
        "url": "https://magic.wizards.com/en/formats/commander",
        "imported_learning": "official 99+1, singleton, color identity, multiplayer, and bracket framing",
        "required_markers": ["legal_identity", "power_bracket"],
    },
    {
        "source": "EDHREC How to Build a Commander Deck",
        "url": "https://edhrec.com/articles/how-to-build-a-commander-deck",
        "imported_learning": "start from card categories and test whether the list plays as intended",
        "required_markers": ["role_counts_vs_targets", "battle_and_replay_validation"],
    },
    {
        "source": "The Command Zone template via EDHREC",
        "url": "https://edhrec.com/articles/the-command-zone-commander-deckbuilding-template-for-the-new-era-the-command-zone-658-mtg-edh-magic-gathering",
        "imported_learning": "balance ramp, card draw, disruption, and other core ratios",
        "required_markers": ["ramp", "card_draw_selection", "interaction_removal"],
    },
    {
        "source": "EDHREC Ramp in Commander",
        "url": "https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander",
        "imported_learning": "ramp quality depends on curve, commander mana value, and timing",
        "required_markers": ["mana_foundation_and_curve", "curve"],
    },
    {
        "source": "EDHREC Top/Staples",
        "url": "https://edhrec.com/top",
        "imported_learning": "global staple popularity is a floor and consistency signal, not commander-specific truth",
        "required_markers": ["staple_impact_and_role_policy", "staple_floor_and_context"],
    },
    {
        "source": "BinderBrew Commander template",
        "url": "https://binderbrew.com/commander-deck-building-template",
        "imported_learning": "core slots come before commander-specific payoffs and then tune by table/budget",
        "required_markers": ["budget_collection_constraints", "commander_specific_packages"],
    },
    {
        "source": "Card Kingdom ramp/draw article",
        "url": "https://blog.cardkingdom.com/whats-better-in-commander-card-draw-or-ramp/",
        "imported_learning": "ramp, draw, removal, and recursion are structural pillars",
        "required_markers": ["recursion_recovery", "card_flow_and_resource_engine"],
    },
    {
        "source": "Commander Spellbook",
        "url": "https://commanderspellbook.com/",
        "imported_learning": "use combo search for deterministic lines and variants, not overall deck balance",
        "required_markers": ["combo_synergy_and_finishers", "combo_lines"],
    },
]

REQUIRED_FLOW = [
    "format_legality_and_power_bracket",
    "commander_intent_and_archetype",
    "primary_and_backup_win_plan",
    "mana_foundation_and_curve",
    "card_flow_and_resource_engine",
    "interaction_protection_and_resilience",
    "commander_specific_packages",
    "combo_synergy_and_finishers",
    "reference_corpus_and_learned_usage",
    "staple_impact_and_role_policy",
    "lane_balanced_cuts_and_anchor_protection",
    "goldfish_battle_replay_iteration",
]

REQUIRED_OVERVIEW_FIELDS = [
    "commander_plan_sentence",
    "power_bracket_target",
    "primary_win_lines",
    "backup_win_lines",
    "role_counts_vs_targets",
    "mana_curve_and_sources",
    "package_lanes_with_key_cards",
    "source_provenance_by_anchor",
    "staple_impact_by_role",
    "protected_anchors_and_cut_rules",
    "known_risks_and_validation_status",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def marker_status(text: str, markers: list[str]) -> dict[str, Any]:
    missing = [marker for marker in markers if marker not in text]
    return {"status": "pass" if not missing else "fail", "missing": missing}


def build_report() -> dict[str, Any]:
    contract_text = read(CONTRACT_DOC)
    support_text = read(SUPPORT_FILE)
    test_text = read(SUPPORT_TEST)
    checks = []
    checks.append(
        {
            "name": "contract_has_researched_flow",
            "path": rel(CONTRACT_DOC),
            **marker_status(
                contract_text,
                [
                    "Research-Backed Deck Planning Flow",
                    "Lane Order And Deck Overview Contract",
                    *REQUIRED_FLOW,
                    *REQUIRED_OVERVIEW_FIELDS,
                ],
            ),
        }
    )
    checks.append(
        {
            "name": "backend_exposes_planning_flow",
            "path": rel(SUPPORT_FILE),
            **marker_status(
                support_text,
                [
                    "commanderDeckPlanningFlowVersion",
                    "commanderDeckPlanningFlow",
                    "commanderDeckPlanningLaneOrder",
                    "commanderDeckOverviewRequiredFields",
                    *REQUIRED_FLOW,
                ],
            ),
        }
    )
    checks.append(
        {
            "name": "tests_lock_planning_flow",
            "path": rel(SUPPORT_TEST),
            **marker_status(
                test_text,
                [
                    "planning_flow_version",
                    "planning_flow",
                    "lane_order",
                    "deck_overview_required_fields",
                    "lane_balanced_cuts_and_anchor_protection",
                ],
            ),
        }
    )
    for source in RESEARCH_SOURCES:
        checks.append(
            {
                "name": "source_learning_" + source["source"].lower().replace(" ", "_"),
                "path": rel(CONTRACT_DOC),
                "source": source,
                **marker_status(contract_text, [source["url"], *source["required_markers"]]),
            }
        )

    failures = [check for check in checks if check["status"] != "pass"]
    return {
        "generated_at": utc_now(),
        "status": "pass" if not failures else "fail",
        "research_sources": RESEARCH_SOURCES,
        "required_flow": REQUIRED_FLOW,
        "required_overview_fields": REQUIRED_OVERVIEW_FIELDS,
        "checks": checks,
        "failures": failures,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Commander Deckbuilding Flow Research Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        "",
        "## External Learning Imported",
        "",
        "| Source | Imported Learning | URL |",
        "| --- | --- | --- |",
    ]
    for source in payload["research_sources"]:
        lines.append(
            f"| {source['source']} | {source['imported_learning']} | {source['url']} |"
        )
    lines.extend(["", "## Flow", ""])
    for index, step in enumerate(payload["required_flow"], start=1):
        lines.append(f"{index}. `{step}`")
    lines.extend(["", "## Checks", "", "| Status | Check | Missing |", "| --- | --- | --- |"])
    for check in payload["checks"]:
        lines.append(
            f"| {check['status']} | `{check['name']}` | {', '.join(check.get('missing') or [])} |"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "commander_deckbuilding_flow_research_audit_20260629",
    )
    args = parser.parse_args()
    payload = build_report()
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    args.out_prefix.with_suffix(".json").write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_markdown(payload, args.out_prefix.with_suffix(".md"))
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(args.out_prefix.with_suffix(".json")),
                "markdown": str(args.out_prefix.with_suffix(".md")),
            },
            sort_keys=True,
        )
    )
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
