#!/usr/bin/env python3
"""Audit whether the repo is aligned with the definitive battle-rules flow.

This is a governance audit, not a card-rule promoter. It checks that docs,
scripts, and current evidence still agree on the 2026-06-29 operating model:

- official rules / Oracle metadata / pinned XMage and Forge are source inputs;
- XMage is the primary external executor and Forge handles structured gaps;
- external execution is separate from native PostgreSQL rule promotion;
- broad XMage extraction creates review candidates only;
- pattern registry rows stay shadow-only and non-executable;
- generic ``xmage_*_review_v1`` scopes do not become PostgreSQL truth;
- PostgreSQL remains the durable source of truth and Hermes remains cache/lab;
- the frozen battle-rules family contract points execution to families after a
  short checkpoint;
- current Lorehold 6 + 607-616 scope is visible in evidence.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = REPO_ROOT / "docs/hermes-analysis/master_optimizer_reports"

DEFAULT_DEFINITIVE_FLOW = REPO_ROOT / "docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md"
DEFAULT_FROZEN_CONTRACT = REPO_ROOT / "docs/hermes-analysis/BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md"
DEFAULT_EXECUTION_CONTRACT = REPO_ROOT / "docs/hermes-analysis/EXTERNAL_BATTLE_EXECUTION_CONTRACT.md"
DEFAULT_DOC_INDEX = REPO_ROOT / "docs/hermes-analysis/BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md"
DEFAULT_ROOT_README = REPO_ROOT / "docs/hermes-analysis/README.md"
DEFAULT_REPORT_README = REPORT_DIR / "README.md"
DEFAULT_PIPELINE_MANIFEST_MD = (
    REPORT_DIR
    / "xmage_current_replay_batch_pipeline_20260630_post_pg276_assemble_the_players_manifest.md"
)
DEFAULT_RUNTIME_SURFACE_MD = REPORT_DIR / "battle_runtime_surface_manifest_20260629_post_adagia_mapper.md"
DEFAULT_EXTERNAL_SOURCE_MD = REPORT_DIR / "mtg_battle_external_source_audit_20260629_post_adagia_mapper.md"

DEFAULT_EXPECTED_FORCED_DECK_IDS = [6, *range(607, 617)]
DEFAULT_EXPECTED_EFFECTIVE_DECK_IDS = [
    6,
    25,
    31,
    42,
    54,
    58,
    62,
    74,
    83,
    84,
    104,
    105,
    116,
    *range(607, 617),
]


@dataclass
class Check:
    name: str
    status: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"name": self.name, "status": self.status, "detail": self.detail}


def ok(name: str, detail: str) -> Check:
    return Check(name=name, status="pass", detail=detail)


def fail(name: str, detail: str) -> Check:
    return Check(name=name, status="fail", detail=detail)


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def contains_all(path: Path, needles: list[str], *, check_name: str | None = None) -> Check:
    if not path.exists():
        return fail(check_name or display_path(path), "missing_file")
    text = read_text(path)
    missing = [needle for needle in needles if needle not in text]
    if missing:
        return fail(check_name or display_path(path), f"missing={missing}")
    return ok(check_name or display_path(path), f"contains={needles}")


def contains_none(path: Path, needles: list[str], *, check_name: str | None = None) -> Check:
    if not path.exists():
        return fail(check_name or display_path(path), "missing_file")
    text = read_text(path)
    present = [needle for needle in needles if needle in text]
    if present:
        return fail(check_name or display_path(path), f"present={present}")
    return ok(check_name or display_path(path), f"absent={needles}")


def extract_backtick_json_object(text: str, label: str) -> dict[str, Any]:
    pattern = re.compile(rf"- {re.escape(label)}: `(?P<json>{{.*?}})`")
    match = pattern.search(text)
    if not match:
        raise ValueError(f"could not find JSON object for {label}")
    return json.loads(match.group("json"))


def extract_backtick_list(text: str, label: str) -> list[int]:
    pattern = re.compile(rf"- {re.escape(label)}: `(?P<list>\[.*?\])`")
    match = pattern.search(text)
    if not match:
        raise ValueError(f"could not find list for {label}")
    return [int(value) for value in json.loads(match.group("list"))]


def audit_docs(args: argparse.Namespace) -> list[Check]:
    definitive_flow = Path(args.definitive_flow)
    frozen_contract = Path(args.frozen_contract)
    checks = [
        contains_all(
            frozen_contract,
            [
                "Status: `frozen_operating_contract`",
                "Do not revalidate the whole battle/rules philosophy before each card wave.",
                "PostgreSQL `card_battle_rules` is the durable source of truth",
                "Hermes SQLite is cache/lab/runtime evidence and must not overwrite PostgreSQL",
                "local XMage is authoritative behavior source for any card with a resolvable XMage class",
                "Broad XMage extraction creates source-authoritative ManaLoom adapter candidates",
                "Generic `xmage_*_review_v1` scopes are adapter/runtime work units",
                "Pattern registry rows are `shadow_only`, non-executable, and non-autopromotable",
                "A battle aggregate is not card-level proof unless the candidate card was drawn/used or a focused test exercised it",
                "Rebuild the current replay/deck scope queue",
                "xmage_authoritative_adaptation_queue.py",
                "ramp_permanent",
                "targeted_interaction",
                "Hazel's Brewmaster",
                "xmage_source_catalog_reconciliation.py",
            ],
            check_name="docs.frozen_family_pipeline_contract",
        ),
        contains_all(
            definitive_flow,
            [
                "Status: `current_operating_standard`",
                "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
                "If the contract checkpoint passes",
                "Local XMage as the authoritative open rules-engine behavior source",
                "Pinned Forge as a secondary executable rules engine",
                "A pinned XMage or Forge battle",
                "source-authoritative adapter candidates",
                "only when its matching runtime adapter exists",
                "PostgreSQL remains the durable source of truth",
                "Hermes is cache/runtime evidence, not truth",
                "xmage_authoritative_adaptation_queue.py",
                "If a candidate card is not drawn/used in battle",
                "Hazel's Brewmaster",
            ],
            check_name="docs.definitive_flow_contract",
        ),
        contains_all(
            Path(args.execution_contract),
            [
                "Status: `current_operating_standard`",
                "pinned XMage is the primary rules executor",
                "pinned Forge is tried only when XMage returns a structured coverage gap",
                "does not create `card_battle_rules` rows",
                "A completed battle proves the engine ran the two decks",
                "33,080",
                "1,212",
                "GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md",
                "battle_positive_evidence_v1",
            ],
            check_name="docs.external_execution_contract",
        ),
        contains_all(
            Path(args.root_readme),
            [
                "EXTERNAL_BATTLE_EXECUTION_CONTRACT.md",
                "XMage pinado como executor primario",
                "xmage_execution_contract_audit.py",
                "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
                "frozen_operating_contract",
                "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
                "current_operating_standard",
                "Nao devem ser usados como contrato operacional",
                "xmage_strategy_consistency_audit.py",
            ],
            check_name="docs.root_readme_points_to_definitive_flow",
        ),
        contains_none(
            Path(args.root_readme),
            [
                "Decisao atual para acelerar XMage -> ManaLoom: usar\n    `hybrid_effective_queue_pattern_registry`",
                "Workflow operacional atual para a fila real Lorehold 608-616",
            ],
            check_name="docs.root_readme_no_old_strategy_as_current",
        ),
        contains_all(
            Path(args.doc_index),
            [
                "EXTERNAL_BATTLE_EXECUTION_CONTRACT.md",
                "XMage primario, Forge secundario apenas para gap estruturado",
                "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
                "checkpoint curto de invariantes",
                "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
                "current",
                "supersede o uso operacional dos planos XMage de 2026-06-23/24",
            ],
            check_name="docs.status_index_marks_definitive_flow_current",
        ),
        contains_all(
            Path(args.report_readme),
            [
                "evidence archive",
                "not executable source of",
                "Commit only reviewed summaries, package evidence, or final manifests",
                "../XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
            ],
            check_name="docs.report_archive_boundary",
        ),
        contains_all(
            REPO_ROOT
            / "docs/hermes-analysis/GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md",
            [
                "current_operating_runbook",
                "external_card_coverage_closure_v1",
                "xmage_source_catalog_reconciliation_v1",
                "external_battle_async_registry_v1",
                "battle_positive_evidence_v1",
                "promotion_allowed=false",
            ],
            check_name="docs.global_battle_learning_closure",
        ),
    ]
    return checks


def audit_script_surface() -> list[Check]:
    scripts = REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts"
    return [
        contains_all(
            REPO_ROOT / "scripts/manaloom_global_battle_closure.sh",
            [
                "external_card_coverage_closure.py",
                "xmage_source_catalog_reconciliation.py",
                "external_battle_async_runner.py",
                "global_residual.json",
            ],
            check_name="scripts.global_battle_closure_entrypoint",
        ),
        contains_all(
            scripts / "xmage_current_replay_batch_pipeline.py",
            [
                "import xmage_pattern_registry_builder as pattern_registry_builder",
                "pattern_registry_builder.build_report",
                "_pattern_registry.json",
                "pattern_status_counts",
                "forced_include_deck_ids",
            ],
            check_name="scripts.pipeline_emits_required_reports",
        ),
        contains_all(
            scripts / "xmage_pattern_registry_builder.py",
            [
                'PROMOTION_STATUS = "shadow_only"',
                '"can_execute_in_battle": False',
                '"can_auto_promote_to_card_battle_rules": False',
                "promotion_status <> 'shadow_only'",
                "can_execute_in_battle = FALSE",
            ],
            check_name="scripts.pattern_registry_shadow_only",
        ),
        contains_all(
            scripts / "xmage_to_manaloom_effect_hints.py",
            [
                "xmage_spell_mana_ritual_variant_review_v1",
                "xmage_exile_then_return_target_variant_review_v1",
                "static_one_spell_per_turn_restriction_variant_review_v1",
                "static_cast_as_flash_permission_variant_review_v1",
                "xmage_choose_new_targets_variant_review_v1",
                "xmage_multi_target_damage_variant_review_v1",
                "xmage_life_gain_variant_review_v1",
                "station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1",
                '"activation_cost_mana": "{3}{W}"',
                '"station_level_required": 12',
                '"token_legendary": True',
                "_nonmana_ability_pending",
                "nonmana_abilities_require_separate_scope",
            ],
            check_name="scripts.effect_mapper_family_lanes_present",
        ),
        contains_all(
            scripts / "test_adagia_runtime.py",
            [
                "test_adagia_station_gate_blocks_copy_before_level_12",
                "test_adagia_precombat_engine_activates_station_copy_after_level_12",
                "test_adagia_station_12_creates_legendary_artifact_or_enchantment_copy",
                "station_level_required",
                "token_legendary",
            ],
            check_name="scripts.adagia_station_runtime_tests_present",
        ),
        contains_all(
            scripts / "xmage_semantic_family_classifier.py",
            [
                '"life_total_change"',
                '"blink"',
                '"multi_target_damage"',
                '"redirect_target"',
                '"untap_target"',
                "station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1",
            ],
            check_name="scripts.family_classifier_matches_mapper",
        ),
        contains_all(
            scripts / "battle_analyst_v9.py",
            [
                'effect_data.get("token_legendary")',
                "token_legendary=bool(effect_data.get(\"token_legendary\"))",
            ],
            check_name="scripts.runtime_copy_token_legendary_support",
        ),
        contains_all(
            scripts / "test_xmage_to_manaloom_effect_hints.py",
            [
                "test_adagia_maps_to_station_legendary_artifact_enchantment_copy_token",
                "test_neheb_routes_to_exact_postcombat_life_lost_mana_engine",
                "test_cloud_key_maps_to_chosen_card_type_cost_reduction",
                "test_alhammarrets_archive_maps_to_exact_draw_life_replacement_scope",
                "test_dynamic_mana_spell_routes_to_ritual_family",
                "test_generic_blink_effect_routes_to_targeted_zone_transition_family",
                "test_red_utility_land_splits_exact_mana_mode_from_nonmana_scope",
            ],
            check_name="tests.mapper_family_coverage_present",
        ),
        contains_all(
            scripts / "battle_card_specific_tests.py",
            [
                "test_adagia_station_copy_creates_legendary_artifact_or_enchantment_token",
                "station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1",
                'assert created["token_legendary"] is True',
            ],
            check_name="tests.runtime_adagia_coverage_present",
        ),
        contains_all(
            scripts / "test_neheb_postcombat_mana_runtime.py",
            [
                "test_neheb_adds_red_equal_to_opponents_life_lost_this_turn",
                "postcombat_main_add_red_for_opponents_life_lost_this_turn_v1",
                "phase_trigger_resolved",
            ],
            check_name="tests.runtime_neheb_coverage_present",
        ),
        contains_all(
            scripts / "test_cloud_key_runtime.py",
            [
                "test_cloud_key_chooses_best_hand_type_and_reduces_only_that_type",
                "chosen_card_type_cost_reduction_v1",
                "chosen_card_type_resolved",
                "spells_you_cast_of_chosen_card_type",
            ],
            check_name="tests.runtime_cloud_key_coverage_present",
        ),
        contains_all(
            scripts / "test_alhammarrets_archive_runtime.py",
            [
                "test_alhammarrets_archive_enters_without_drawing_and_doubles_life_gain",
                "test_alhammarrets_archive_draw_replacement_respects_draw_step_exception",
                "static_double_life_gain_and_draw_except_first_draw_step_v1",
                "draw_replacement_applied",
                "life_gain_replacement_applied",
            ],
            check_name="tests.runtime_alhammarret_archive_coverage_present",
        ),
    ]


def audit_manifest(args: argparse.Namespace) -> list[Check]:
    path = Path(args.pipeline_manifest_md)
    if not path.exists():
        return [fail("evidence.pipeline_manifest", "missing_file")]
    text = read_text(path)
    checks: list[Check] = []

    try:
        forced_deck_ids = set(extract_backtick_list(text, "Forced include deck ids"))
        expected_forced = set(int(deck_id) for deck_id in args.expected_forced_deck_id)
        missing_forced = sorted(expected_forced - forced_deck_ids)
        if missing_forced:
            checks.append(fail("evidence.forced_deck_ids", f"missing={missing_forced}"))
        else:
            checks.append(ok("evidence.forced_deck_ids", json.dumps(sorted(forced_deck_ids))))
    except Exception as exc:
        checks.append(fail("evidence.forced_deck_ids", str(exc)))

    try:
        effective_deck_ids = set(extract_backtick_list(text, "Effective deck ids"))
        expected_effective = set(int(deck_id) for deck_id in args.expected_effective_deck_id)
        missing_effective = sorted(expected_effective - effective_deck_ids)
        if missing_effective:
            checks.append(fail("evidence.effective_deck_ids", f"missing={missing_effective}"))
        else:
            checks.append(ok("evidence.effective_deck_ids", json.dumps(sorted(effective_deck_ids))))
    except Exception as exc:
        checks.append(fail("evidence.effective_deck_ids", str(exc)))

    expected_counts = {
        "Validity status counts": {
            "ready_for_structured_xmage_pull_review_required": 64,
            "xmage_source_valid_mapper_required": 61,
        },
        "Proposal status counts": {
            "split_family_scope_review_required": 64,
            "mapper_metadata_or_test_scenario_required": 61,
        },
        "Family counts": {
            "manual_model": 61,
            "ramp_permanent": 5,
            "targeted_interaction": 12,
            "recursion": 9,
            "free_cast": 7,
            "targeted_protection": 7,
            "passive": 5,
            "draw_engine": 2,
            "topdeck_play": 2,
            "board_wipe_choice": 3,
            "copy_spell_engine": 1,
            "life_total_change": 1,
            "tutor": 10,
        },
        "Pattern status counts": {
            "candidate_template_requires_review_tests": 9,
            "manual_model_observation_only": 1,
            "requires_subpattern_split_before_promotion": 10,
        },
    }
    for label, expected in expected_counts.items():
        try:
            actual = extract_backtick_json_object(text, label)
            mismatches = {
                key: {"expected": value, "actual": actual.get(key)}
                for key, value in expected.items()
                if actual.get(key) != value
            }
            if mismatches:
                checks.append(fail(f"evidence.{label.lower().replace(' ', '_')}", json.dumps(mismatches, sort_keys=True)))
            else:
                checks.append(ok(f"evidence.{label.lower().replace(' ', '_')}", json.dumps(expected, sort_keys=True)))
        except Exception as exc:
            checks.append(fail(f"evidence.{label.lower().replace(' ', '_')}", str(exc)))

    checks.append(
        contains_all(
            path,
            ["Pattern promotion status: `shadow_only`"],
            check_name="evidence.pattern_promotion_shadow_only",
        )
    )
    return checks


def audit_gates(args: argparse.Namespace) -> list[Check]:
    return [
        contains_all(
            Path(args.runtime_surface_md),
            [
                "Unclassified files: `0`",
                "card_specific_runtime_rules",
                "family_mapper_required",
                "XMage/Oracle extraction creates review candidate; PG promotion requires focused test and safe lane",
            ],
            check_name="gate.runtime_surface_current",
        ),
        contains_all(
            Path(args.external_source_md),
            [
                "Gate status: `pass`",
                "Required gaps: `0`",
                "Required partials: `0`",
                "Optional gaps: `0`",
                "Official Wizards rules remain the authority",
                "Scryfall and MTGJSON are metadata/rulings inputs",
                "Open engines such as Forge, Magarena, and Cockatrice are comparison references only",
            ],
            check_name="gate.external_source_current",
        ),
    ]


def build_report(args: argparse.Namespace) -> dict[str, Any]:
    checks: list[Check] = []
    checks.extend(audit_docs(args))
    checks.extend(audit_script_surface())
    checks.extend(audit_manifest(args))
    checks.extend(audit_gates(args))
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    return {
        "status": "pass" if status_counts.get("fail", 0) == 0 else "fail",
        "mutations_performed": [],
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
        },
        "checks": [check.as_dict() for check in checks],
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Strategy Consistency Audit",
        "",
        f"- Status: `{report.get('status')}`",
        f"- Mutations performed: `{report.get('mutations_performed')}`",
        f"- Summary: `{json.dumps(report.get('summary'), sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report.get("checks", []):
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check.get('name')}` | `{check.get('status')}` | {detail} |")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--definitive-flow", default=str(DEFAULT_DEFINITIVE_FLOW))
    parser.add_argument("--frozen-contract", default=str(DEFAULT_FROZEN_CONTRACT))
    parser.add_argument("--execution-contract", default=str(DEFAULT_EXECUTION_CONTRACT))
    parser.add_argument("--doc-index", default=str(DEFAULT_DOC_INDEX))
    parser.add_argument("--root-readme", default=str(DEFAULT_ROOT_README))
    parser.add_argument("--report-readme", default=str(DEFAULT_REPORT_README))
    parser.add_argument("--pipeline-manifest-md", default=str(DEFAULT_PIPELINE_MANIFEST_MD))
    parser.add_argument("--runtime-surface-md", default=str(DEFAULT_RUNTIME_SURFACE_MD))
    parser.add_argument("--external-source-md", default=str(DEFAULT_EXTERNAL_SOURCE_MD))
    parser.add_argument(
        "--expected-forced-deck-id",
        type=int,
        action="append",
        default=DEFAULT_EXPECTED_FORCED_DECK_IDS,
    )
    parser.add_argument(
        "--expected-effective-deck-id",
        type=int,
        action="append",
        default=DEFAULT_EXPECTED_EFFECTIVE_DECK_IDS,
    )
    parser.add_argument("--output-prefix", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(args)
    output_prefix = Path(args.output_prefix)
    output_json = output_prefix.with_name(output_prefix.name + ".json")
    output_md = output_prefix.with_name(output_prefix.name + ".md")
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(render_markdown(report) + "\n", encoding="utf-8")
    print(f"report_json={output_json}")
    print(f"report_md={output_md}")
    print(f"status={report['status']}")
    print(f"summary={json.dumps(report['summary'], sort_keys=True)}")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
