#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

import xmage_strategy_consistency_audit as audit


class XMageStrategyConsistencyAuditTests(unittest.TestCase):
    def test_default_effective_deck_ids_match_current_opponent_scope(self) -> None:
        self.assertIn(104, audit.DEFAULT_EXPECTED_EFFECTIVE_DECK_IDS)
        self.assertNotIn(103, audit.DEFAULT_EXPECTED_EFFECTIVE_DECK_IDS)

    def test_manifest_audit_rejects_missing_forced_lorehold_deck(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            manifest = Path(tmp_dir) / "manifest.md"
            manifest.write_text(
                "\n".join(
                    [
                        "- Forced include deck ids: `[6, 607]`",
                        "- Effective deck ids: `[6, 25, 607]`",
                        '- Validity status counts: `{"ready_for_structured_xmage_pull_review_required": 69, "xmage_source_valid_mapper_required": 61}`',
                        '- Family counts: `{"board_wipe_choice": 3, "copy_spell_engine": 1, "draw_engine": 3, "free_cast": 9, "life_total_change": 1, "manual_model": 61, "passive": 5, "ramp_permanent": 5, "recursion": 11, "targeted_interaction": 12, "targeted_protection": 7, "topdeck_play": 2, "tutor": 10}`',
                        '- Proposal status counts: `{"mapper_metadata_or_test_scenario_required": 61, "split_family_scope_review_required": 69}`',
                        '- Pattern status counts: `{"candidate_template_requires_review_tests": 9, "manual_model_observation_only": 1, "requires_subpattern_split_before_promotion": 10}`',
                        "- Pattern promotion status: `shadow_only`",
                    ]
                ),
                encoding="utf-8",
            )
            args = SimpleNamespace(
                pipeline_manifest_md=str(manifest),
                expected_forced_deck_id=[6, 607, 608],
                expected_effective_deck_id=[6, 25, 607, 608],
            )
            checks = audit.audit_manifest(args)

        statuses = {check.name: check.status for check in checks}
        self.assertEqual(statuses["evidence.forced_deck_ids"], "fail")
        self.assertEqual(statuses["evidence.effective_deck_ids"], "fail")

    def test_manifest_audit_accepts_current_counts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            manifest = Path(tmp_dir) / "manifest.md"
            manifest.write_text(
                "\n".join(
                    [
                        "- Forced include deck ids: `[6, 607, 608]`",
                        "- Effective deck ids: `[6, 25, 31, 607, 608]`",
                        '- Validity status counts: `{"ready_for_structured_xmage_pull_review_required": 69, "xmage_source_valid_mapper_required": 61}`',
                        '- Family counts: `{"board_wipe_choice": 3, "copy_spell_engine": 1, "draw_engine": 3, "free_cast": 9, "life_total_change": 1, "manual_model": 61, "passive": 5, "ramp_permanent": 5, "recursion": 11, "targeted_interaction": 12, "targeted_protection": 7, "topdeck_play": 2, "tutor": 10}`',
                        '- Proposal status counts: `{"mapper_metadata_or_test_scenario_required": 61, "split_family_scope_review_required": 69}`',
                        '- Pattern status counts: `{"candidate_template_requires_review_tests": 9, "manual_model_observation_only": 1, "requires_subpattern_split_before_promotion": 10}`',
                        "- Pattern promotion status: `shadow_only`",
                    ]
                ),
                encoding="utf-8",
            )
            args = SimpleNamespace(
                pipeline_manifest_md=str(manifest),
                expected_forced_deck_id=[6, 607, 608],
                expected_effective_deck_id=[6, 25, 31, 607, 608],
            )
            checks = audit.audit_manifest(args)

        self.assertTrue(all(check.status == "pass" for check in checks), checks)

    def test_full_audit_passes_with_current_fixture_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            definitive = root / "definitive.md"
            contract = root / "contract.md"
            root_readme = root / "README.md"
            doc_index = root / "index.md"
            report_readme = root / "reports.md"
            manifest = root / "manifest.md"
            runtime = root / "runtime.md"
            external = root / "external.md"

            definitive.write_text(
                "\n".join(
                    [
                        "Status: `current_operating_standard`",
                        "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
                        "If the contract checkpoint passes",
                        "broad XMage extraction may create review candidates and family lanes",
                        "must not create executable battle truth or PostgreSQL promotion by itself",
                        "PostgreSQL remains the durable source of truth",
                        "Hermes is cache/runtime evidence, not truth",
                        "Do not promote from `xmage_*_review_v1`",
                        "If a candidate card is not drawn/used in battle",
                        "Hazel's Brewmaster",
                    ]
                ),
                encoding="utf-8",
            )
            contract.write_text(
                "\n".join(
                    [
                        "Status: `frozen_operating_contract`",
                        "Do not revalidate the whole battle/rules philosophy before each card wave.",
                        "PostgreSQL `card_battle_rules` is the durable source of truth",
                        "Hermes SQLite is cache/lab/runtime evidence and must not overwrite PostgreSQL",
                        "Broad XMage extraction may create review candidates and family lanes only",
                        "Generic `xmage_*_review_v1` scopes are review/split-only and never batch PG candidates",
                        "Pattern registry rows are `shadow_only`, non-executable, and non-autopromotable",
                        "A battle aggregate is not card-level proof unless the candidate card was drawn/used or a focused test exercised it",
                        "Rebuild the current replay/deck scope queue",
                        "ramp_permanent",
                        "targeted_interaction",
                        "Hazel's Brewmaster",
                    ]
                ),
                encoding="utf-8",
            )
            root_readme.write_text(
                "\n".join(
                    [
                        "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
                        "frozen_operating_contract",
                        "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
                        "current_operating_standard",
                        "Nao devem ser usados como contrato operacional",
                        "xmage_strategy_consistency_audit.py",
                    ]
                ),
                encoding="utf-8",
            )
            doc_index.write_text(
                "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md checkpoint curto de invariantes XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md current supersede o uso operacional dos planos XMage de 2026-06-23/24",
                encoding="utf-8",
            )
            report_readme.write_text(
                "evidence archive not executable source of Commit only reviewed summaries, package evidence, or final manifests ../XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
                encoding="utf-8",
            )
            manifest.write_text(
                "\n".join(
                    [
                        "- Forced include deck ids: `[6, 607, 608]`",
                        "- Effective deck ids: `[6, 25, 31, 607, 608]`",
                        '- Validity status counts: `{"ready_for_structured_xmage_pull_review_required": 69, "xmage_source_valid_mapper_required": 61}`',
                        '- Family counts: `{"board_wipe_choice": 3, "copy_spell_engine": 1, "draw_engine": 3, "free_cast": 9, "life_total_change": 1, "manual_model": 61, "passive": 5, "ramp_permanent": 5, "recursion": 11, "targeted_interaction": 12, "targeted_protection": 7, "topdeck_play": 2, "tutor": 10}`',
                        '- Proposal status counts: `{"mapper_metadata_or_test_scenario_required": 61, "split_family_scope_review_required": 69}`',
                        '- Pattern status counts: `{"candidate_template_requires_review_tests": 9, "manual_model_observation_only": 1, "requires_subpattern_split_before_promotion": 10}`',
                        "- Pattern promotion status: `shadow_only`",
                    ]
                ),
                encoding="utf-8",
            )
            runtime.write_text(
                "Unclassified files: `0` card_specific_runtime_rules family_mapper_required XMage/Oracle extraction creates review candidate; PG promotion requires focused test and safe lane",
                encoding="utf-8",
            )
            external.write_text(
                "Gate status: `pass` Required gaps: `0` Required partials: `0` Optional gaps: `0` Official Wizards rules remain the authority Scryfall and MTGJSON are metadata/rulings inputs Open engines such as Forge, Magarena, and Cockatrice are comparison references only",
                encoding="utf-8",
            )

            args = SimpleNamespace(
                definitive_flow=str(definitive),
                frozen_contract=str(contract),
                root_readme=str(root_readme),
                doc_index=str(doc_index),
                report_readme=str(report_readme),
                pipeline_manifest_md=str(manifest),
                runtime_surface_md=str(runtime),
                external_source_md=str(external),
                expected_forced_deck_id=[6, 607, 608],
                expected_effective_deck_id=[6, 25, 31, 607, 608],
            )
            report = audit.build_report(args)

        self.assertEqual(report["status"], "pass", report["checks"])
        self.assertEqual(report["summary"]["status_counts"].get("fail", 0), 0)

    def test_frozen_contract_audit_rejects_missing_shadow_guardrail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "contract.md"
            path.write_text(
                "\n".join(
                    [
                        "Status: `frozen_operating_contract`",
                        "Do not revalidate the whole battle/rules philosophy before each card wave.",
                        "PostgreSQL `card_battle_rules` is the durable source of truth",
                        "Hermes SQLite is cache/lab/runtime evidence and must not overwrite PostgreSQL",
                        "Broad XMage extraction may create review candidates and family lanes only",
                    ]
                ),
                encoding="utf-8",
            )
            check = audit.contains_all(
                path,
                [
                    "Pattern registry rows are `shadow_only`, non-executable, and non-autopromotable",
                ],
                check_name="docs.frozen_family_pipeline_contract",
            )

        self.assertEqual(check.status, "fail")

    def test_root_readme_audit_rejects_old_strategy_as_current(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "README.md"
            path.write_text(
                "Decisao atual para acelerar XMage -> ManaLoom: usar\n    `hybrid_effective_queue_pattern_registry`",
                encoding="utf-8",
            )
            check = audit.contains_none(
                path,
                [
                    "Decisao atual para acelerar XMage -> ManaLoom: usar\n    `hybrid_effective_queue_pattern_registry`"
                ],
                check_name="docs.root_readme_no_old_strategy_as_current",
            )

        self.assertEqual(check.status, "fail")


if __name__ == "__main__":
    unittest.main()
