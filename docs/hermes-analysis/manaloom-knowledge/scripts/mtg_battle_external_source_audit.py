#!/usr/bin/env python3
"""Audit ManaLoom battle coverage against external MTG battle sources.

The audit is intentionally deterministic. Internet research establishes the
source matrix, but routine CI/gate execution must not depend on live network
availability.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_REPO_ROOT = SCRIPT_DIR.parents[3]


@dataclass(frozen=True)
class SourceReference:
    id: str
    name: str
    url: str
    source_type: str
    reliability: str
    use_for: str
    do_not_use_for: str


@dataclass(frozen=True)
class BattleRequirement:
    id: str
    area: str
    source_ids: tuple[str, ...]
    required_for_gate: bool
    expected_globs: tuple[str, ...]
    keyword_groups: tuple[tuple[str, ...], ...]
    rationale: str
    missing_recommendation: str


SOURCE_INVENTORY: tuple[SourceReference, ...] = (
    SourceReference(
        id="wotc_comprehensive_rules_20260619",
        name="Magic: The Gathering Comprehensive Rules",
        url="https://media.wizards.com/2026/downloads/MagicCompRules%2020260619.txt",
        source_type="official_rules",
        reliability="authoritative",
        use_for="Primary semantics for phases, priority, stack, combat, zones, state-based actions, replacement effects, and layers.",
        do_not_use_for="Card telemetry, deck performance, or player behavior frequency.",
    ),
    SourceReference(
        id="wotc_rules_page",
        name="Wizards Rules and Documents",
        url="https://magic.wizards.com/en/rules",
        source_type="official_index",
        reliability="authoritative_index",
        use_for="Current official rules landing page and document freshness checks.",
        do_not_use_for="Executable card implementation details.",
    ),
    SourceReference(
        id="wotc_mtga_detailed_logs",
        name="MTG Arena detailed log support article",
        url="https://mtgarena-support.wizards.com/hc/en-us/articles/360000726823-Creating-Log-Files-on-PC-Mac-Steam",
        source_type="official_telemetry_availability",
        reliability="official_availability_not_schema_contract",
        use_for="Evidence that Arena detailed logs exist and must be enabled for local telemetry collection.",
        do_not_use_for="Stable public schema, bulk corpus availability, or Commander strategy truth.",
    ),
    SourceReference(
        id="scryfall_api",
        name="Scryfall API",
        url="https://scryfall.com/docs/api",
        source_type="card_oracle_api",
        reliability="high_quality_card_metadata",
        use_for="Oracle text, rulings endpoints, identifiers, and card search metadata.",
        do_not_use_for="Turn order, priority, stack execution, or battle outcome priors.",
    ),
    SourceReference(
        id="mtgjson_v5",
        name="MTGJSON v5",
        url="https://mtgjson.com/",
        source_type="bulk_card_data",
        reliability="high_quality_aggregated_metadata",
        use_for="Bulk card, set, legality, keyword, and ruling-shaped data models.",
        do_not_use_for="Battle sequence telemetry or rules authority over Wizards documents.",
    ),
    SourceReference(
        id="seventeenlands_public_datasets",
        name="17Lands public datasets",
        url="https://www.17lands.com/public_datasets",
        source_type="public_game_history_corpus",
        reliability="high_for_arena_limited_telemetry",
        use_for="Observed turn cadence, card access/use lifecycle, and game history priors.",
        do_not_use_for="Commander staples, exact Oracle semantics, or paper multiplayer metagame truth.",
    ),
    SourceReference(
        id="forge_rules_engine",
        name="Forge rules engine",
        url="https://github.com/Card-Forge/forge",
        source_type="independent_open_engine",
        reliability="useful_comparison_not_authority",
        use_for="Independent implementation comparison for families not covered by XMage.",
        do_not_use_for="Replacing official rules or bypassing ManaLoom runtime tests.",
    ),
    SourceReference(
        id="cockatrice_client_replays",
        name="Cockatrice",
        url="https://github.com/Cockatrice/Cockatrice",
        source_type="open_client_and_replay_surface",
        reliability="manual_game_replay_reference",
        use_for="Replay/client concepts and manual game-state references.",
        do_not_use_for="Automatic rules enforcement truth.",
    ),
    SourceReference(
        id="magarena_engine",
        name="Magarena",
        url="https://github.com/magarena/magarena",
        source_type="independent_open_engine",
        reliability="comparison_reference",
        use_for="Additional card scripting and AI implementation comparison when XMage/Forge disagree or lack coverage.",
        do_not_use_for="Authoritative rule interpretation.",
    ),
)


REQUIREMENTS: tuple[BattleRequirement, ...] = (
    BattleRequirement(
        id="official_rules_authority_anchored",
        area="source hierarchy",
        source_ids=("wotc_comprehensive_rules_20260619", "wotc_rules_page"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_rules_2026_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/mtg_battle_external_source_audit.py",
        ),
        keyword_groups=(("Comprehensive Rules", "official_rules"),),
        rationale="ManaLoom should anchor battle semantics to official rules before simulator or telemetry sources.",
        missing_recommendation="Keep the official rules source in the external audit and add/update rule-version tests when the official document changes.",
    ),
    BattleRequirement(
        id="turn_structure_and_phase_order",
        area="turn structure",
        source_ids=("wotc_comprehensive_rules_20260619",),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
        ),
        keyword_groups=(
            ("beginning", "precombat", "combat", "postcombat", "ending"),
            ("phase", "turn"),
        ),
        rationale="Battle simulation must model the turn skeleton before card-specific logic can be trusted.",
        missing_recommendation="Add focused turn-flow tests covering beginning, main, combat, postcombat, and ending phase transitions.",
    ),
    BattleRequirement(
        id="priority_stack_and_resolution",
        area="priority and stack",
        source_ids=("wotc_comprehensive_rules_20260619",),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
        ),
        keyword_groups=(
            ("priority_window", "priority"),
            ("stack_depth", "stack_object", "spell_resolved"),
            ("cast_pipeline", "locked_cost"),
        ),
        rationale="Stack and priority are the main boundary between card text mapping and legal executable gameplay.",
        missing_recommendation="Extend stack casting tests and event contracts with priority window, stack depth, locked cost, and resolution metadata.",
    ),
    BattleRequirement(
        id="casting_cost_target_legality",
        area="casting, costs, and targets",
        source_ids=("wotc_comprehensive_rules_20260619", "scryfall_api", "mtgjson_v5"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_cost_support.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py",
        ),
        keyword_groups=(
            ("target", "targets"),
            ("mana_cost", "locked_cost", "cost"),
            ("illegal", "legality"),
        ),
        rationale="ManaLoom cannot compare card strength if the cast legality and target model is fuzzy.",
        missing_recommendation="Add cast-legality fixtures for cost locking, target selection, and illegal cast rejection.",
    ),
    BattleRequirement(
        id="combat_step_model",
        area="combat",
        source_ids=("wotc_comprehensive_rules_20260619", "seventeenlands_public_datasets"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
        ),
        keyword_groups=(
            ("attack", "attacker", "attackers"),
            ("block", "blocker", "blockers"),
            ("combat_damage", "combat damage"),
        ),
        rationale="Combat needs both official step ordering and telemetry-aware outcome logging.",
        missing_recommendation="Add combat regression tests for attacker declaration, blocker declaration, combat damage, and related replay events.",
    ),
    BattleRequirement(
        id="state_based_actions",
        area="state-based actions",
        source_ids=("wotc_comprehensive_rules_20260619",),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py",
        ),
        keyword_groups=(
            ("state_based", "sba", "state-based"),
            ("permanent_moved_by_sba", "player_eliminated", "graveyard"),
        ),
        rationale="SBA support prevents impossible board states from contaminating replay learning.",
        missing_recommendation="Add state-based action support/tests for lethal damage, zero toughness, legendary/commander edge cases, and player loss.",
    ),
    BattleRequirement(
        id="replacement_and_prevention_effects",
        area="replacement and prevention",
        source_ids=("wotc_comprehensive_rules_20260619",),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_tests.py",
        ),
        keyword_groups=(
            ("ReplacementRegistry", "replacement"),
            ("replacement_applied", "prevention", "prevent"),
        ),
        rationale="Replacement/prevention changes event causality and must be learned as an event transform, not as after-the-fact text.",
        missing_recommendation="Add tests for replacement ordering, prevention shields, and emitted causal event metadata.",
    ),
    BattleRequirement(
        id="continuous_effect_layers",
        area="continuous effects and layers",
        source_ids=("wotc_comprehensive_rules_20260619",),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_continuous_effects_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_characteristics_support.py",
        ),
        keyword_groups=(
            ("continuous", "apply_continuous_effects"),
            ("layer", "sublayer"),
        ),
        rationale="Layer handling protects card characteristics and power/toughness calculations from order bugs.",
        missing_recommendation="Add layer-order fixtures for characteristics, control, type/color, ability, and power/toughness sublayers.",
    ),
    BattleRequirement(
        id="triggered_ability_resolution",
        area="triggered abilities",
        source_ids=("wotc_comprehensive_rules_20260619", "scryfall_api"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_trigger_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
        ),
        keyword_groups=(
            ("trigger", "triggered"),
            ("trigger_resolved", "event_payload"),
        ),
        rationale="Triggered abilities are a frequent bridge from Oracle text to runtime event queues.",
        missing_recommendation="Add trigger queue/resolution tests with emitted event payloads and source object identity.",
    ),
    BattleRequirement(
        id="zone_transition_ledger",
        area="zones",
        source_ids=("wotc_comprehensive_rules_20260619",),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py",
        ),
        keyword_groups=(
            ("from_zone", "source_zone"),
            ("to_zone", "destination", "zone_after"),
        ),
        rationale="Zone transitions are required for graveyard, exile, stack, library, command zone, and blink learning.",
        missing_recommendation="Add zone transition tests that prove source/destination metadata survives replacement and SBA paths.",
    ),
    BattleRequirement(
        id="commander_and_deck_legality",
        area="Commander constraints",
        source_ids=("wotc_comprehensive_rules_20260619", "mtgjson_v5", "scryfall_api"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_commander_tests.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/validate_deck_legalities.py",
        ),
        keyword_groups=(
            ("commander", "command_zone"),
            ("color_identity", "legalities", "legality"),
        ),
        rationale="Commander deckbuilding cannot be judged apart from commander identity, command zone, and legal card universe.",
        missing_recommendation="Add commander legality fixtures tied to card metadata identifiers and command-zone transitions.",
    ),
    BattleRequirement(
        id="oracle_rulings_metadata_pipeline",
        area="Oracle/rulings metadata",
        source_ids=("scryfall_api", "mtgjson_v5"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/external_card_rule_reference_harvester.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py",
        ),
        keyword_groups=(
            ("oracle", "rulings", "scryfall"),
            ("oracle_hash", "rule_version"),
        ),
        rationale="Card text and rulings must be canonicalized before pattern families are promoted.",
        missing_recommendation="Keep Oracle/rulings harvest and PG sync metadata tied to oracle_hash/rule_version.",
    ),
    BattleRequirement(
        id="xmage_semantic_family_absorption",
        area="XMage source absorption",
        source_ids=("wotc_comprehensive_rules_20260619", "scryfall_api"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_local_rule_indexer.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py",
        ),
        keyword_groups=(
            ("XMage", "xmage"),
            ("semantic", "family", "effect"),
            ("candidate_only", "manual review", "review_policy"),
        ),
        rationale="XMage should accelerate card families, but promotion still needs Oracle alignment and ManaLoom tests.",
        missing_recommendation="Keep XMage adapters producing family candidates with explicit non-authoritative review policy.",
    ),
    BattleRequirement(
        id="seventeenlands_history_learning",
        area="public battle history learning",
        source_ids=("seventeenlands_public_datasets",),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_replay_profile.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_battle_prior_compare.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_general_absorption_audit.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_history_learning.py",
        ),
        keyword_groups=(
            ("replay_data", "DEFAULT_REPLAY_URL", "17Lands"),
            ("turn_behavior_by_history", "sequence_learning"),
            ("card_lifecycle", "use_after_access_rate"),
        ),
        rationale="17Lands should feed general cadence and lifecycle priors, not card-rule authority.",
        missing_recommendation="Keep 17Lands learners focused on sequence/card lifecycle priors and compare them against ManaLoom replay behavior.",
    ),
    BattleRequirement(
        id="structured_replay_and_event_contracts",
        area="structured replay logs",
        source_ids=("seventeenlands_public_datasets", "wotc_mtga_detailed_logs"),
        required_for_gate=True,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py",
        ),
        keyword_groups=(
            ("replay.events.jsonl", "decision_trace"),
            ("MINIMUM_FIELDS_BY_EVENT", "minimum_fields_for_event"),
            ("observed_event_missing_minimum_fields", "event_contract"),
        ),
        rationale="Learning from battles requires stable structured event fields, not only rendered play-by-play text.",
        missing_recommendation="Expand event contract tests whenever a new runtime event type or log-learning consumer is added.",
    ),
    BattleRequirement(
        id="mtga_player_log_ingestion",
        area="local Arena Player.log ingestion",
        source_ids=("wotc_mtga_detailed_logs",),
        required_for_gate=False,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/mtga_player_log*.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/*player_log*.py",
        ),
        keyword_groups=(
            ("Player.log", "Detailed Logs", "GRE"),
            ("GameStateMessage", "turnInfo", "annotations"),
        ),
        rationale="Arena Player.log can be useful for user-local telemetry, but there is no approved public bulk source in this repo yet.",
        missing_recommendation="Add a read-only Player.log parser only if the project receives real local logs and privacy handling requirements.",
    ),
    BattleRequirement(
        id="independent_engine_crosscheck_beyond_xmage",
        area="independent engine comparison",
        source_ids=("forge_rules_engine", "magarena_engine", "cockatrice_client_replays"),
        required_for_gate=False,
        expected_globs=(
            "docs/hermes-analysis/manaloom-knowledge/scripts/forge_*",
            "docs/hermes-analysis/manaloom-knowledge/scripts/magarena_*",
            "docs/hermes-analysis/manaloom-knowledge/scripts/cockatrice_*",
        ),
        keyword_groups=(
            ("Forge", "Magarena", "Cockatrice"),
            ("comparison", "crosscheck", "adapter"),
        ),
        rationale="External engines can find disagreements, but none should bypass official rules plus ManaLoom runtime tests.",
        missing_recommendation="Add comparison adapters only for semantic families where XMage is missing, ambiguous, or contradicted by tests.",
    ),
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(DEFAULT_REPO_ROOT),
    )
    parser.add_argument("--output", type=Path)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--fail-on-required-gaps", action="store_true")
    return parser.parse_args()


def matched_paths(repo_root: Path, globs: tuple[str, ...]) -> list[Path]:
    paths: set[Path] = set()
    for pattern in globs:
        if any(char in pattern for char in "*?["):
            paths.update(path for path in repo_root.glob(pattern) if path.is_file())
        else:
            path = repo_root / pattern
            if path.is_file():
                paths.add(path)
    return sorted(paths, key=lambda path: path.relative_to(repo_root).as_posix())


def read_combined_text(paths: list[Path]) -> str:
    chunks: list[str] = []
    for path in paths:
        try:
            chunks.append(path.read_text(encoding="utf-8"))
        except UnicodeDecodeError:
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(chunks).lower()


def keyword_group_hits(combined_text: str, keyword_groups: tuple[tuple[str, ...], ...]) -> tuple[list[dict[str, Any]], list[list[str]]]:
    hits: list[dict[str, Any]] = []
    missing: list[list[str]] = []
    for group in keyword_groups:
        found = [keyword for keyword in group if keyword.lower() in combined_text]
        if found:
            hits.append({"accepted_any_of": list(group), "found": found})
        else:
            missing.append(list(group))
    return hits, missing


def audit_requirement(repo_root: Path, requirement: BattleRequirement) -> dict[str, Any]:
    paths = matched_paths(repo_root, requirement.expected_globs)
    combined_text = read_combined_text(paths)
    keyword_hits, missing_keyword_groups = keyword_group_hits(
        combined_text,
        requirement.keyword_groups,
    )
    missing_globs = [
        pattern
        for pattern in requirement.expected_globs
        if not matched_paths(repo_root, (pattern,))
    ]

    if not paths and missing_keyword_groups:
        status = "gap"
    elif not missing_keyword_groups and not missing_globs:
        status = "covered"
    else:
        status = "partial"

    return {
        **asdict(requirement),
        "status": status,
        "evidence_paths": [
            path.relative_to(repo_root).as_posix()
            for path in paths
        ],
        "missing_globs": missing_globs,
        "keyword_hits": keyword_hits,
        "missing_keyword_groups": missing_keyword_groups,
    }


def build_audit(repo_root: Path = DEFAULT_REPO_ROOT) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    requirements = [audit_requirement(repo_root, item) for item in REQUIREMENTS]
    required_gaps = [
        item for item in requirements if item["required_for_gate"] and item["status"] == "gap"
    ]
    required_partials = [
        item for item in requirements if item["required_for_gate"] and item["status"] == "partial"
    ]
    optional_gaps = [
        item for item in requirements if not item["required_for_gate"] and item["status"] == "gap"
    ]
    status_counts: dict[str, int] = {}
    for item in requirements:
        status_counts[item["status"]] = status_counts.get(item["status"], 0) + 1

    source_types: dict[str, int] = {}
    for source in SOURCE_INVENTORY:
        source_types[source.source_type] = source_types.get(source.source_type, 0) + 1

    return {
        "generated_at_utc": utc_now(),
        "repo_root": str(repo_root),
        "postgres_writes": False,
        "summary": {
            "source_count": len(SOURCE_INVENTORY),
            "source_type_counts": dict(sorted(source_types.items())),
            "requirement_count": len(requirements),
            "required_requirement_count": sum(1 for item in requirements if item["required_for_gate"]),
            "optional_requirement_count": sum(1 for item in requirements if not item["required_for_gate"]),
            "status_counts": dict(sorted(status_counts.items())),
            "required_gap_count": len(required_gaps),
            "required_partial_count": len(required_partials),
            "optional_gap_count": len(optional_gaps),
            "gate_status": "pass" if not required_gaps else "fail",
        },
        "source_inventory": [asdict(source) for source in SOURCE_INVENTORY],
        "requirements": requirements,
        "required_gaps": required_gaps,
        "required_partials": required_partials,
        "optional_gaps": optional_gaps,
        "recommendations": [
            {
                "requirement_id": item["id"],
                "area": item["area"],
                "status": item["status"],
                "required_for_gate": item["required_for_gate"],
                "recommendation": item["missing_recommendation"],
            }
            for item in requirements
            if item["status"] != "covered"
        ],
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report["summary"]
    lines = [
        "# MTG Battle External Source Audit",
        "",
        f"- Generated UTC: `{report['generated_at_utc']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        f"- Sources inventoried: `{summary['source_count']}`",
        f"- Requirements audited: `{summary['requirement_count']}`",
        f"- Gate status: `{summary['gate_status']}`",
        f"- Required gaps: `{summary['required_gap_count']}`",
        f"- Required partials: `{summary['required_partial_count']}`",
        f"- Optional gaps: `{summary['optional_gap_count']}`",
        "",
        "## Source Inventory",
        "",
        "| Source | Type | Reliability | Use | Do not use for |",
        "| --- | --- | --- | --- | --- |",
    ]
    for source in report["source_inventory"]:
        lines.append(
            "| [{name}]({url}) | `{source_type}` | `{reliability}` | {use_for} | {do_not_use_for} |".format(
                **source
            )
        )

    lines.extend(
        [
            "",
            "## Requirement Coverage",
            "",
            "| Requirement | Area | Required | Status | Evidence paths | Missing globs |",
            "| --- | --- | ---: | --- | ---: | ---: |",
        ]
    )
    for item in report["requirements"]:
        lines.append(
            "| `{id}` | {area} | `{required_for_gate}` | `{status}` | `{evidence}` | `{missing}` |".format(
                id=item["id"],
                area=item["area"],
                required_for_gate=item["required_for_gate"],
                status=item["status"],
                evidence=len(item["evidence_paths"]),
                missing=len(item["missing_globs"]),
            )
        )

    if report["recommendations"]:
        lines.extend(["", "## Recommendations", ""])
        for item in report["recommendations"]:
            lines.append(
                "- `{requirement_id}` ({status}, required={required_for_gate}): {recommendation}".format(
                    **item
                )
            )

    lines.extend(
        [
            "",
            "## Method Notes",
            "",
            "- Official Wizards rules remain the authority for runtime semantics.",
            "- Scryfall and MTGJSON are metadata/rulings inputs, not battle-order authorities.",
            "- 17Lands and Player.log-style sources are telemetry inputs; they can expose cadence and coverage gaps but do not define card rules.",
            "- Open engines such as Forge, Magarena, and Cockatrice are comparison references only.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    report = build_audit(args.repo_root)
    markdown = render_markdown(report)

    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(stable_json(report) + "\n", encoding="utf-8")
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    if not args.output and not args.json_output:
        print(markdown)

    if args.fail_on_required_gaps and report["summary"]["required_gap_count"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
