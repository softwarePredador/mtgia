#!/usr/bin/env python3
"""Unit tests for report-only consumers of new-card review queues."""

from __future__ import annotations

import importlib.util
import json
import os
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


def _load_module(name: str, relative_path: str):
    root = Path(__file__).resolve().parents[1]
    path = root / relative_path
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _write_fixture(tmp: Path) -> Path:
    fixture = {
        "commanders": [
            {
                "name": "Lorehold, the Historian",
                "source": "fixture_control",
                "color_identity": ["R", "W"],
                "existing_cards": [],
                "role_counts": {
                    "ramp": 5,
                    "draw": 4,
                    "removal": 4,
                    "protection": 1,
                    "board_wipe": 0,
                },
            }
        ],
        "cards": [
            {
                "card_id": "card-missing-data",
                "name": "Marvel Unknown Preview",
                "mana_cost": "{1}{W}",
                "type_line": "Creature",
                "oracle_text": "",
                "color_identity": ["W"],
                "cmc": 2,
                "set_code": "msh",
                "function_tags": ["protection"],
            },
            {
                "card_id": "card-rule-review",
                "oracle_id": "oracle-rule-review",
                "name": "Marvel Tactical Reset",
                "mana_cost": "{2}{R}{W}",
                "type_line": "Sorcery",
                "oracle_text": "Destroy all creatures. Draw a card for each creature destroyed this way.",
                "color_identity": ["R", "W"],
                "cmc": 4,
                "set_code": "msh",
                "legalities": {"commander": "legal"},
                "function_tags": ["board_wipe", "removal", "draw"],
                "battle_rule_count": 0,
                "verified_battle_rule_count": 0,
            },
        ],
    }
    path = tmp / "fixture.json"
    path.write_text(json.dumps(fixture), encoding="utf-8")
    return path


def _write_counterspell_gate_fixture(tmp: Path) -> Path:
    fixture = {
        "commanders": [
            {
                "name": "Urza, Lord High Artificer",
                "source": "fixture_control",
                "color_identity": ["U"],
                "existing_cards": [],
                "role_counts": {
                    "protection": 0,
                    "removal": 0,
                },
            },
            {
                "name": "Lorehold, the Historian",
                "source": "fixture_control",
                "color_identity": ["R", "W"],
                "existing_cards": [],
                "role_counts": {
                    "protection": 0,
                    "removal": 0,
                },
            },
            {
                "name": "Kykar, Wind's Fury",
                "source": "fixture_control",
                "color_identity": ["U", "R", "W"],
                "existing_cards": [],
                "role_counts": {
                    "engine": 0,
                    "tutor": 0,
                    "ramp": 0,
                },
            },
        ],
        "cards": [
            {
                "card_id": "card-counterspell",
                "oracle_id": "oracle-counterspell",
                "name": "Counterspell",
                "mana_cost": "{U}{U}",
                "type_line": "Instant",
                "oracle_text": "Counter target spell.",
                "color_identity": ["U"],
                "cmc": 2,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["protection", "removal"],
            },
            {
                "card_id": "card-goblin-bombardment",
                "oracle_id": "oracle-goblin-bombardment",
                "name": "Goblin Bombardment",
                "mana_cost": "{1}{R}",
                "type_line": "Enchantment",
                "oracle_text": "Sacrifice a creature: This enchantment deals 1 damage to any target.",
                "color_identity": ["R"],
                "cmc": 2,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["removal", "sacrifice_outlet"],
                "semantic_tags_v2": [
                    {"protection_type": "sacrifice_outlet"},
                    {"recursion_type": "graveyard_synergy"},
                ],
            },
            {
                "card_id": "card-seize-the-day",
                "oracle_id": "oracle-seize-the-day",
                "name": "Seize the Day",
                "mana_cost": "{3}{R}",
                "type_line": "Sorcery",
                "oracle_text": "Untap target creature. After this main phase, there is an additional combat phase followed by an additional main phase. Flashback {2}{R}",
                "color_identity": ["R"],
                "cmc": 4,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["recursion", "payoff"],
            },
            {
                "card_id": "card-iron-man",
                "oracle_id": "oracle-iron-man",
                "name": "Iron Man, Titan of Innovation",
                "mana_cost": "{2}{U}{R}",
                "type_line": "Legendary Artifact Creature — Human Hero",
                "oracle_text": "Flying, haste\nGenius Industrialist — Whenever Iron Man attacks, create a Treasure token, then you may sacrifice a noncreature artifact. If you do, search your library for an artifact card with mana value equal to 1 plus the sacrificed artifact's mana value, put it onto the battlefield tapped, then shuffle.",
                "color_identity": ["U", "R"],
                "cmc": 4,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["engine", "ramp", "tutor", "payoff"],
                "semantic_tags_v2": [
                    {"engine_type": "attack_trigger"},
                    {"tutor_type": "artifact_tutor"},
                ],
            },
            {
                "card_id": "card-clean-execution",
                "oracle_id": "oracle-clean-execution",
                "name": "Clean Execution",
                "mana_cost": "{1}{W}",
                "type_line": "Instant",
                "oracle_text": "Destroy target creature.",
                "color_identity": ["W"],
                "cmc": 2,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["removal"],
            },
            {
                "card_id": "card-clean-sweeper",
                "oracle_id": "oracle-clean-sweeper",
                "name": "Clean Sweeper",
                "mana_cost": "{2}{W}{W}",
                "type_line": "Sorcery",
                "oracle_text": "Destroy all creatures.",
                "color_identity": ["W"],
                "cmc": 4,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["board_wipe", "removal"],
            },
            {
                "card_id": "card-clean-unmaking",
                "oracle_id": "oracle-clean-unmaking",
                "name": "Clean Unmaking",
                "mana_cost": "{2}{W}",
                "type_line": "Sorcery",
                "oracle_text": "Destroy target nonland permanent.",
                "color_identity": ["W"],
                "cmc": 3,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["removal"],
            },
            {
                "card_id": "card-clean-shatter",
                "oracle_id": "oracle-clean-shatter",
                "name": "Clean Shatter",
                "mana_cost": "{1}{R}",
                "type_line": "Instant",
                "oracle_text": "Destroy target artifact.",
                "color_identity": ["R"],
                "cmc": 2,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["removal"],
            },
            {
                "card_id": "card-clean-demystify",
                "oracle_id": "oracle-clean-demystify",
                "name": "Clean Demystify",
                "mana_cost": "{W}",
                "type_line": "Instant",
                "oracle_text": "Destroy target enchantment.",
                "color_identity": ["W"],
                "cmc": 1,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["removal"],
            },
            {
                "card_id": "card-clean-formation",
                "oracle_id": "oracle-clean-formation",
                "name": "Clean Formation",
                "mana_cost": "{W}",
                "type_line": "Instant",
                "oracle_text": "Creatures you control gain indestructible until end of turn.",
                "color_identity": ["W"],
                "cmc": 1,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["protection"],
            },
            {
                "card_id": "card-clean-treasure",
                "oracle_id": "oracle-clean-treasure",
                "name": "Clean Treasure",
                "mana_cost": "{R}",
                "type_line": "Sorcery",
                "oracle_text": "Create a Treasure token.",
                "color_identity": ["R"],
                "cmc": 1,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["ramp"],
            },
            {
                "card_id": "card-clean-recursion",
                "oracle_id": "oracle-clean-recursion",
                "name": "Clean Recursion",
                "mana_cost": "{1}{W}",
                "type_line": "Sorcery",
                "oracle_text": "Return target creature card from your graveyard to your hand.",
                "color_identity": ["W"],
                "cmc": 2,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["recursion"],
            },
        ],
    }
    path = tmp / "counterspell_gate_fixture.json"
    path.write_text(json.dumps(fixture), encoding="utf-8")
    return path


def _write_counter_manipulation_fixture(tmp: Path) -> Path:
    fixture = {
        "commanders": [
            {
                "name": "Atraxa, Praetors' Voice",
                "source": "fixture_control",
                "color_identity": ["G", "W", "U", "B"],
                "existing_cards": [],
                "role_counts": {
                    "engine": 0,
                },
            }
        ],
        "cards": [
            {
                "card_id": "card-clean-counter-engine",
                "oracle_id": "oracle-clean-counter-engine",
                "name": "Clean Counter Engine",
                "mana_cost": "{1}{G}",
                "type_line": "Creature",
                "oracle_text": "Put a +1/+1 counter on target creature.",
                "color_identity": ["G"],
                "cmc": 2,
                "set_code": "mar",
                "legalities": {"commander": "legal"},
                "function_tags": ["engine"],
            },
        ],
    }
    path = tmp / "counter_manipulation_fixture.json"
    path.write_text(json.dumps(fixture), encoding="utf-8")
    return path


class ManaloomReviewQueueConsumersTest(unittest.TestCase):
    def test_consumers_do_not_fail_before_candidate_review_runs(self) -> None:
        data_gap = _load_module(
            "manaloom_card_data_gap_review_empty",
            "bin/manaloom_card_data_gap_review.py",
        )
        battle_queue = _load_module(
            "manaloom_battle_rule_review_queue_empty",
            "bin/manaloom_battle_rule_review_queue.py",
        )
        promotion_gate = _load_module(
            "manaloom_battle_rule_promotion_gate_empty",
            "bin/manaloom_battle_rule_promotion_gate.py",
        )

        with tempfile.TemporaryDirectory() as raw_tmp:
            tmp = Path(raw_tmp)
            knowledge_db = tmp / "empty_knowledge.db"
            data_summary = data_gap.run(
                data_gap.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "data_gap"),
                    ]
                )
            )
            battle_summary = battle_queue.run(
                battle_queue.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "battle"),
                        "--limit",
                        "0",
                    ]
                )
            )
            self.assertEqual(data_summary["unique_cards"], 0)
            self.assertEqual(battle_summary["draft_count"], 0)
            gate_summary = promotion_gate.run(
                promotion_gate.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "gate"),
                    ]
                )
            )
            self.assertEqual(gate_summary["evaluated_count"], 0)
            self.assertEqual(data_summary.get("blocked_reason"), "knowledge_db_missing")
            self.assertEqual(battle_summary.get("blocked_reason"), "knowledge_db_missing")
            self.assertEqual(gate_summary.get("blocked_reason"), "knowledge_db_missing")

    def test_consumers_classify_data_gaps_and_generate_rule_drafts(self) -> None:
        candidate = _load_module(
            "manaloom_new_card_candidate_review_for_consumers",
            "bin/manaloom_new_card_candidate_review.py",
        )
        data_gap = _load_module(
            "manaloom_card_data_gap_review",
            "bin/manaloom_card_data_gap_review.py",
        )
        battle_queue = _load_module(
            "manaloom_battle_rule_review_queue",
            "bin/manaloom_battle_rule_review_queue.py",
        )
        promotion_gate = _load_module(
            "manaloom_battle_rule_promotion_gate",
            "bin/manaloom_battle_rule_promotion_gate.py",
        )

        with tempfile.TemporaryDirectory() as raw_tmp:
            tmp = Path(raw_tmp)
            fixture = _write_fixture(tmp)
            knowledge_db = tmp / "knowledge.db"
            candidate_dir = tmp / "candidate"
            data_gap_dir = tmp / "data_gap"
            battle_dir = tmp / "battle"
            gate_dir = tmp / "gate"

            candidate_summary = candidate.run(
                candidate.parse_args(
                    [
                        "--fixture",
                        str(fixture),
                        "--output-dir",
                        str(candidate_dir),
                        "--knowledge-db",
                        str(knowledge_db),
                        "--no-lorehold-control",
                    ]
                )
            )
            self.assertGreaterEqual(candidate_summary["decisions"].get("needs_data", 0), 1)
            self.assertGreaterEqual(candidate_summary["decisions"].get("needs_rule_review", 0), 1)

            data_summary = data_gap.run(
                data_gap.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(data_gap_dir),
                    ]
                )
            )
            self.assertEqual(data_summary["gap_rows"], 1)
            self.assertEqual(data_summary["unique_cards"], 1)
            self.assertIn("needs_oracle_sync", data_summary["decisions"])
            data_items = json.loads(
                (data_gap_dir / "card_data_gap_review/latest_items.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertIn("refresh_oracle_text", data_items[0]["actions"])
            self.assertIn("refresh_commander_legality", data_items[0]["actions"])

            battle_summary = battle_queue.run(
                battle_queue.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(battle_dir),
                    ]
                )
            )
            self.assertEqual(battle_summary["queue_rows"], 1)
            self.assertEqual(battle_summary["draft_count"], 1)
            drafts = json.loads(
                (battle_dir / "battle_rule_review_queue/latest_drafts.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(drafts[0]["proposed_status"], "needs_review")
            self.assertIn("no_verified_promotion", drafts[0]["safety"])
            self.assertIn("mass_removal_or_modal_wipe", drafts[0]["effect_families"])
            self.assertIn("targeted_interaction", drafts[0]["effect_families"])

            blocked_gate_summary = promotion_gate.run(
                promotion_gate.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(gate_dir),
                    ]
                )
            )
            self.assertEqual(blocked_gate_summary["evaluated_count"], 1)
            self.assertEqual(blocked_gate_summary["blocked_count"], 1)
            self.assertIn(
                "missing_official_source_review",
                blocked_gate_summary["blockers"],
            )

            evidence_path = tmp / "promotion_evidence.json"
            evidence_path.write_text(
                json.dumps(
                    {
                        "by_draft_rule_key": {
                            drafts[0]["draft_rule_key"]: {
                                "official_source_reviewed": True,
                                "official_sources": ["Scryfall oracle text"],
                                "focused_test_passed": True,
                                "focused_test_refs": ["test/marvel_tactical_reset_test.py"],
                                "replay_audit_passed": True,
                                "replay_audit_refs": ["artifacts/replay_audit.json"],
                                "critical_findings": 0,
                                "high_findings": 0,
                            }
                        }
                    }
                ),
                encoding="utf-8",
            )
            eligible_dir = tmp / "gate_eligible"
            eligible_gate_summary = promotion_gate.run(
                promotion_gate.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(eligible_dir),
                        "--evidence-file",
                        str(evidence_path),
                    ]
                )
            )
            self.assertEqual(eligible_gate_summary["eligible_count"], 1)
            gate_items = json.loads(
                (eligible_dir / "battle_rule_promotion_gate/latest_items.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(
                gate_items[0]["decision"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertFalse(gate_items[0]["promotion_contract"]["postgres_write_allowed"])

            original_call = battle_queue.call_openai_review
            original_key = os.environ.get("OPENAI_API_KEY")

            def fake_openai_review(*_args, **kwargs):
                return {
                    "status": "completed",
                    "model": kwargs["model"],
                    "summary": "Mocked report-only review.",
                    "recommended_status": "needs_review",
                    "risk_assessment": ["requires official source review"],
                    "official_sources_needed": ["Scryfall oracle", "Wizards rules"],
                    "suggested_test_cases": ["focused replay keeps draft in needs_review"],
                    "implementation_notes": ["do not execute hard behavior"],
                    "safety": [
                        "llm_review_only",
                        "no_postgres_write",
                        "no_verified_promotion",
                        "manual_gate_required",
                    ],
                }

            battle_queue.call_openai_review = fake_openai_review
            os.environ["OPENAI_API_KEY"] = "test-openai-key"
            try:
                llm_dir = tmp / "battle_llm"
                llm_summary = battle_queue.run(
                    battle_queue.parse_args(
                        [
                            "--knowledge-db",
                            str(knowledge_db),
                            "--output-dir",
                            str(llm_dir),
                            "--llm-review",
                            "--llm-limit",
                            "1",
                        ]
                    )
                )
            finally:
                battle_queue.call_openai_review = original_call
                if original_key is None:
                    os.environ.pop("OPENAI_API_KEY", None)
                else:
                    os.environ["OPENAI_API_KEY"] = original_key

            self.assertEqual(llm_summary["llm_review"]["completed"], 1)
            llm_drafts = json.loads(
                (llm_dir / "battle_rule_review_queue/latest_drafts.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(llm_drafts[0]["proposed_status"], "needs_review")
            self.assertEqual(llm_drafts[0]["llm_review"]["status"], "completed")
            self.assertEqual(llm_drafts[0]["llm_review"]["recommended_status"], "needs_review")
            self.assertIn("no_verified_promotion", llm_drafts[0]["llm_review"]["safety"])

            conn = sqlite3.connect(knowledge_db)
            try:
                data_runs = conn.execute(
                    "SELECT COUNT(*) FROM new_card_data_gap_review_runs"
                ).fetchone()[0]
                battle_runs = conn.execute(
                    "SELECT COUNT(*) FROM new_card_battle_rule_review_runs"
                ).fetchone()[0]
                gate_runs = conn.execute(
                    "SELECT COUNT(*) FROM new_card_battle_rule_promotion_gate_runs"
                ).fetchone()[0]
                self.assertEqual(data_runs, 1)
                self.assertGreaterEqual(battle_runs, 1)
                self.assertEqual(gate_runs, 2)
            finally:
                conn.close()

    def test_focused_evidence_unblocks_supported_low_risk_templates(self) -> None:
        candidate = _load_module(
            "manaloom_new_card_candidate_review_for_focused_evidence",
            "bin/manaloom_new_card_candidate_review.py",
        )
        battle_queue = _load_module(
            "manaloom_battle_rule_review_queue_for_focused_evidence",
            "bin/manaloom_battle_rule_review_queue.py",
        )
        focused_evidence = _load_module(
            "manaloom_battle_rule_focused_evidence",
            "bin/manaloom_battle_rule_focused_evidence.py",
        )
        promotion_gate = _load_module(
            "manaloom_battle_rule_promotion_gate_for_focused_evidence",
            "bin/manaloom_battle_rule_promotion_gate.py",
        )

        with tempfile.TemporaryDirectory() as raw_tmp:
            tmp = Path(raw_tmp)
            fixture = _write_counterspell_gate_fixture(tmp)
            knowledge_db = tmp / "knowledge.db"

            candidate.run(
                candidate.parse_args(
                    [
                        "--fixture",
                        str(fixture),
                        "--output-dir",
                        str(tmp / "candidate"),
                        "--knowledge-db",
                        str(knowledge_db),
                        "--no-lorehold-control",
                    ]
                )
            )
            battle_summary = battle_queue.run(
                battle_queue.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "battle"),
                    ]
                )
            )
            self.assertEqual(battle_summary["draft_count"], 12)
            drafts = json.loads(
                (
                    tmp
                    / "battle"
                    / "battle_rule_review_queue"
                    / "latest_drafts.json"
                ).read_text(encoding="utf-8")
            )
            draft_keys = {draft["card_name"]: draft["draft_rule_key"] for draft in drafts}
            self.assertEqual(
                draft_keys["Goblin Bombardment"],
                "goblin_bombardment__activated_sacrifice_creature_damage__draft_v1",
            )
            self.assertEqual(
                draft_keys["Clean Formation"],
                "clean_formation__protection_or_prevention__draft_v1",
            )
            self.assertEqual(
                draft_keys["Clean Shatter"],
                "clean_shatter__targeted_interaction__draft_v1",
            )
            self.assertEqual(
                draft_keys["Clean Demystify"],
                "clean_demystify__targeted_interaction__draft_v1",
            )
            self.assertEqual(
                draft_keys["Clean Treasure"],
                "clean_treasure__treasure_resource_generation__draft_v1",
            )
            self.assertEqual(
                draft_keys["Clean Recursion"],
                "clean_recursion__graveyard_or_zone_recursion__draft_v1",
            )

            evidence_summary = focused_evidence.run(
                focused_evidence.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "focused"),
                        "--limit",
                        "0",
                    ]
                )
            )
            self.assertEqual(evidence_summary["evaluated_count"], 12)
            self.assertEqual(evidence_summary["evidence_count"], 12)

            evidence_file = (
                tmp
                / "focused"
                / "battle_rule_focused_evidence"
                / "latest_evidence.json"
            )
            self.assertTrue(evidence_file.exists())
            gate_summary = promotion_gate.run(
                promotion_gate.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "gate"),
                        "--limit",
                        "0",
                    ]
                )
            )
            self.assertEqual(gate_summary["evaluated_count"], 12)
            self.assertEqual(gate_summary["eligible_count"], 12)
            self.assertEqual(gate_summary["blocked_count"], 0)
            self.assertEqual(gate_summary["evidence_file"], str(evidence_file))

            items = json.loads(
                (
                    tmp
                    / "gate"
                    / "battle_rule_promotion_gate"
                    / "latest_items.json"
                ).read_text(encoding="utf-8")
            )
            decisions = {item["card_name"]: item["decision"] for item in items}
            self.assertEqual(
                decisions["Counterspell"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Goblin Bombardment"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Seize the Day"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Iron Man, Titan of Innovation"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Execution"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Sweeper"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Unmaking"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Shatter"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Demystify"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Formation"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Treasure"],
                "eligible_for_manual_verified_promotion",
            )
            self.assertEqual(
                decisions["Clean Recursion"],
                "eligible_for_manual_verified_promotion",
            )

    def test_counter_manipulation_requires_dedicated_template_before_promotion(self) -> None:
        candidate = _load_module(
            "manaloom_new_card_candidate_review_counter_manipulation",
            "bin/manaloom_new_card_candidate_review.py",
        )
        battle_queue = _load_module(
            "manaloom_battle_rule_review_queue_counter_manipulation",
            "bin/manaloom_battle_rule_review_queue.py",
        )
        focused_evidence = _load_module(
            "manaloom_battle_rule_focused_evidence_counter_manipulation",
            "bin/manaloom_battle_rule_focused_evidence.py",
        )
        promotion_gate = _load_module(
            "manaloom_battle_rule_promotion_gate_counter_manipulation",
            "bin/manaloom_battle_rule_promotion_gate.py",
        )

        with tempfile.TemporaryDirectory() as raw_tmp:
            tmp = Path(raw_tmp)
            fixture = _write_counter_manipulation_fixture(tmp)
            knowledge_db = tmp / "knowledge.db"

            candidate_summary = candidate.run(
                candidate.parse_args(
                    [
                        "--fixture",
                        str(fixture),
                        "--output-dir",
                        str(tmp / "candidate"),
                        "--knowledge-db",
                        str(knowledge_db),
                        "--no-lorehold-control",
                    ]
                )
            )
            self.assertEqual(candidate_summary["decisions"].get("needs_rule_review"), 1)

            battle_summary = battle_queue.run(
                battle_queue.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "battle"),
                    ]
                )
            )
            self.assertEqual(battle_summary["draft_count"], 1)
            drafts = json.loads(
                (
                    tmp
                    / "battle"
                    / "battle_rule_review_queue"
                    / "latest_drafts.json"
                ).read_text(encoding="utf-8")
            )
            self.assertIn("counter_manipulation", drafts[0]["effect_families"])

            evidence_summary = focused_evidence.run(
                focused_evidence.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "focused"),
                        "--limit",
                        "0",
                    ]
                )
            )
            self.assertEqual(evidence_summary["evaluated_count"], 1)
            self.assertEqual(evidence_summary["evidence_count"], 0)
            self.assertEqual(
                evidence_summary["reasons"].get("no_focused_evidence_template_for_effect_family"),
                1,
            )

            gate_summary = promotion_gate.run(
                promotion_gate.parse_args(
                    [
                        "--knowledge-db",
                        str(knowledge_db),
                        "--output-dir",
                        str(tmp / "gate"),
                        "--limit",
                        "0",
                    ]
                )
            )
            self.assertEqual(gate_summary["evaluated_count"], 1)
            self.assertEqual(gate_summary["eligible_count"], 0)
            self.assertEqual(gate_summary["blocked_count"], 1)


if __name__ == "__main__":
    unittest.main()
