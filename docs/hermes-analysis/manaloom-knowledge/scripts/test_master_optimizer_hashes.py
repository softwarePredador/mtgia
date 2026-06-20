#!/usr/bin/env python3
import sqlite3
import tempfile
import unittest
from pathlib import Path

import master_optimizer_common as optimizer


class MasterOptimizerHashTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmpdir.name) / "knowledge.db"
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_id TEXT,
                card_name TEXT,
                quantity INTEGER,
                functional_tag TEXT,
                functional_tags_json TEXT,
                battle_rules_json TEXT,
                tag_confidence REAL,
                is_commander INTEGER,
                is_partner INTEGER,
                cmc REAL,
                type_line TEXT,
                oracle_text TEXT
            )
            """
        )
        self.conn.executemany(
            """
            INSERT INTO deck_cards (
                deck_id, card_id, card_name, quantity, functional_tag,
                functional_tags_json, battle_rules_json, tag_confidence,
                is_commander, is_partner, cmc, type_line, oracle_text
            )
            VALUES (6, ?, ?, 1, ?, ?, ?, 0.9, ?, 0, ?, ?, ?)
            """,
            [
                (
                    "cmd-1",
                    "Lorehold, the Historian",
                    "commander",
                    '["commander"]',
                    "[]",
                    1,
                    4,
                    "Legendary Creature",
                    "Commander text",
                ),
                (
                    "draw-1",
                    "Archive Trap",
                    "draw",
                    '["draw"]',
                    "[]",
                    0,
                    2,
                    "Instant",
                    "Draw a card.",
                ),
            ],
        )
        self.conn.commit()
        optimizer.ensure_optimizer_tables(self.conn)

    def tearDown(self) -> None:
        self.conn.close()
        self.tmpdir.cleanup()

    def _insert_baseline(self) -> sqlite3.Row:
        summary = optimizer.get_deck_summary(self.conn, 6)
        self.conn.execute(
            """
            INSERT INTO optimizer_baseline_runs (
                deck_id, deck_hash, semantics_hash, ruleset_hash,
                games_per_opponent, opponents, total_games, wr, wins, losses,
                stalls, status, result_json, created_at
            )
            VALUES (6, ?, ?, ?, 1, 1, 1, 100.0, 1, 0, 0, 'approved', '{}', ?)
            """,
            (
                summary["hash"],
                summary["semantics_hash"],
                summary["ruleset_hash"],
                optimizer.utc_now(),
            ),
        )
        self.conn.commit()
        baseline = optimizer.latest_baseline(self.conn, 6)
        assert baseline is not None
        return baseline

    def test_optimizer_tables_expose_semantic_hash_columns(self) -> None:
        baseline_columns = {
            row[1]
            for row in self.conn.execute("PRAGMA table_info(optimizer_baseline_runs)")
        }
        slot_columns = {
            row[1] for row in self.conn.execute("PRAGMA table_info(slot_benchmarks)")
        }
        self.assertIn("semantics_hash", baseline_columns)
        self.assertIn("ruleset_hash", baseline_columns)
        self.assertIn("baseline_semantics_hash", slot_columns)
        self.assertIn("baseline_ruleset_hash", slot_columns)

    def test_semantic_only_change_invalidates_semantic_baseline_not_deck_hash(self) -> None:
        baseline = self._insert_baseline()
        before_deck_hash = optimizer.deck_hash(self.conn, 6)
        self.conn.execute(
            """
            UPDATE deck_cards
            SET functional_tags_json='["draw","removal"]'
            WHERE card_id='draw-1'
            """
        )
        self.conn.commit()
        self.assertEqual(optimizer.deck_hash(self.conn, 6), before_deck_hash)
        with self.assertRaisesRegex(RuntimeError, "semantics hash"):
            optimizer.assert_current_deck_matches_baseline(self.conn, 6, baseline)

    def test_rules_only_change_invalidates_ruleset_baseline_not_deck_hash(self) -> None:
        baseline = self._insert_baseline()
        before_deck_hash = optimizer.deck_hash(self.conn, 6)
        self.conn.execute(
            """
            UPDATE deck_cards
            SET battle_rules_json='[{"effect":{"effect":"draw_cards"},"source":"test"}]'
            WHERE card_id='draw-1'
            """
        )
        self.conn.commit()
        self.assertEqual(optimizer.deck_hash(self.conn, 6), before_deck_hash)
        with self.assertRaisesRegex(RuntimeError, "ruleset hash"):
            optimizer.assert_current_deck_matches_baseline(self.conn, 6, baseline)

    def test_battle_rule_deck_categories_preserve_multiple_roles_same_name(self) -> None:
        optimizer.battle_rule_registry.ensure_battle_card_rules(self.conn)
        optimizer.battle_rule_registry.upsert_battle_card_rule(
            self.conn,
            "Modal Test Card",
            {"effect": "draw_cards", "amount": 2},
            source="curated",
            confidence=0.95,
            review_status="verified",
        )
        optimizer.battle_rule_registry.upsert_battle_card_rule(
            self.conn,
            "Modal Test Card",
            {"effect": "remove_creature", "target": "creature"},
            source="curated",
            confidence=0.95,
            review_status="verified",
        )
        self.conn.commit()

        categories = optimizer.battle_rule_deck_categories(self.conn, "Modal Test Card")

        self.assertEqual(categories, {"draw", "removal"})
        self.assertEqual(
            optimizer.battle_rule_deck_category(self.conn, "Modal Test Card"),
            "removal",
        )

    def test_battle_gate_report_lines_expose_optimizer_guardrail(self) -> None:
        summary = {
            "run_dir": "/tmp/battle-audit-run",
            "battle_replay_final_status": "review_required",
            "battle_replay_final_status_reason": "focused_template_dispatch",
            "mandatory_gate_divergences": ["focused_template_dispatch=review_required"],
            "mandatory_gate_statuses": {
                "focused_template_dispatch": {"status": "review_required"},
                "strategy_audit": {"status": "pass"},
            },
            "strategy_learning_confidence_counts": {
                "high_confidence_replay": 13,
                "low_confidence_replay": 3,
            },
            "strategy_low_confidence_seeds": ["63201739", "63201740"],
            "strategy_high_confidence_learning_seeds": ["63201734"],
            "global_learning_eligibility_policy": "requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass",
            "global_learning_eligible_seeds": ["63201734"],
            "global_not_learning_eligible_seeds": ["63201739", "63201740"],
            "focused_template_dispatch_status": "review_required",
            "focused_template_evidence_ready": 5,
            "focused_template_evidence_not_ready_unwaived": 24,
            "effect_coverage_residual_status": "effect_coverage_residual_accepted",
            "effect_coverage_residual_raw_flag_total": 539,
            "effect_coverage_residual_accepted_card_flag_rows": 293,
            "effect_coverage_residual_unaccepted_card_flag_rows": 0,
            "review_only_rule_names": 0,
            "needs_review_rule_names": 1457,
            "non_runtime_safe_rule_names": 1457,
            "runtime_safe_rule_names": 1702,
            "review_status_counts": {"needs_review": 1457, "verified": 1675},
            "decision_trace_taxonomy_rows": 2221,
            "decision_trace_kinds_total": 15,
            "decision_trace_kinds_observed": 12,
            "decision_trace_kinds_uncovered": 3,
            "decision_trace_static_uncovered_types": ["worldfire_reset"],
            "forensic_lineage_status": "complete",
            "forensic_card_id_present": 862,
            "forensic_card_id_missing": 527,
            "forensic_card_id_missing_accepted": 527,
            "forensic_card_id_missing_unaccepted": 0,
            "forensic_semantic_hash_present": 862,
            "forensic_semantic_hash_missing": 527,
            "forensic_semantic_hash_missing_accepted": 527,
            "forensic_semantic_hash_missing_unaccepted": 0,
            "forensic_rule_logical_key_present": 1371,
            "forensic_rule_logical_key_missing": 18,
            "forensic_rule_logical_key_missing_accepted": 18,
            "forensic_rule_logical_key_missing_unaccepted": 0,
            "forensic_lineage_missing_waiver_reasons": {"accepted": 1},
        }

        markdown = "\n".join(optimizer.battle_gate_report_lines(summary))
        cli = "\n".join(optimizer.battle_gate_cli_lines(summary))

        self.assertIn("battle_replay_final_status: `review_required`", markdown)
        self.assertIn("battle_gate_weight: `required_for_optimizer_wr_evidence`", markdown)
        self.assertIn("focused_template_dispatch=review_required", markdown)
        self.assertIn("strategy_low_confidence_seed_sample", markdown)
        self.assertIn("strategy_high_confidence_learning_seed_sample", markdown)
        self.assertIn("global_learning_eligibility_policy", markdown)
        self.assertIn("global_learning_eligible_seed_sample", markdown)
        self.assertIn("global_not_learning_eligible_seed_sample", markdown)
        self.assertIn("effect_coverage_residual_raw_flag_total: `539`", markdown)
        self.assertIn(
            "effect_coverage_residual_scope_note: `accepted_residual_is_not_full_runtime_coverage`",
            markdown,
        )
        self.assertIn("review_rule_denominators", markdown)
        self.assertIn(
            "review_rule_denominator_scope_note: `review_only_zero_is_not_review_backlog_zero`",
            markdown,
        )
        self.assertIn("needs_review=1457", markdown)
        self.assertIn("decision_trace_taxonomy_scope: `rows=2221 observed=12/15 uncovered=3`", markdown)
        self.assertIn("forensic_card_id_present_missing: `862/527`", markdown)
        self.assertIn(
            "forensic_lineage_scope_note: `complete_means_zero_unaccepted_missing_not_full_identity_coverage`",
            markdown,
        )
        self.assertIn("forensic_lineage_missing_waiver_reasons", markdown)
        self.assertIn("battle_replay_final_status=review_required", cli)
        self.assertIn("battle_gate_weight=required_for_optimizer_wr_evidence", cli)
        self.assertIn(
            "global_learning_eligibility_policy=requires_high_confidence_strategy_seed_and_all_mandatory_gates_pass",
            cli,
        )
        self.assertIn("global_learning_eligible_seed_sample", cli)
        self.assertIn("global_not_learning_eligible_seed_sample", cli)
        self.assertIn("effect_coverage_residual_raw_flag_total=539", cli)
        self.assertIn(
            "effect_coverage_residual_scope_note=accepted_residual_is_not_full_runtime_coverage",
            cli,
        )
        self.assertIn("review_rule_denominators=review_only:0 needs_review:1457", cli)
        self.assertIn(
            "review_rule_denominator_scope_note=review_only_zero_is_not_review_backlog_zero",
            cli,
        )
        self.assertIn("decision_trace_taxonomy_scope=rows:2221 observed:12/15 uncovered:3", cli)
        self.assertIn("forensic_card_id_present_missing=862/527", cli)
        self.assertIn(
            "forensic_lineage_scope_note=complete_means_zero_unaccepted_missing_not_full_identity_coverage",
            cli,
        )

    def test_optimizer_operational_surfaces_publish_battle_gate(self) -> None:
        report_scripts = [
            "master_optimizer_apply.py",
            "master_optimizer_baseline.py",
            "master_optimizer_confirmation.py",
            "master_optimizer_handoff.py",
            "master_optimizer_loop.py",
            "master_optimizer_post_apply_gate.py",
            "master_optimizer_product_handoff.py",
            "master_optimizer_quality_gate.py",
            "master_optimizer_rollback.py",
        ]
        for filename in report_scripts:
            with self.subTest(filename=filename):
                source = (optimizer.SCRIPT_DIR / filename).read_text(encoding="utf-8")
                self.assertIn("battle_gate_report_lines", source)

        cli_scripts = [
            "master_optimizer_loop.py",
            "slot_optimizer.py",
        ]
        for filename in cli_scripts:
            with self.subTest(filename=filename):
                source = (optimizer.SCRIPT_DIR / filename).read_text(encoding="utf-8")
                self.assertIn("battle_gate_cli_lines", source)

        universal_source = (optimizer.SCRIPT_DIR / "universal_optimizer.py").read_text(encoding="utf-8")
        self.assertIn("legacy_deprecated_not_authorized_for_handoff", universal_source)
        self.assertIn("battle_gate_cli_lines", universal_source)


if __name__ == "__main__":
    unittest.main()
