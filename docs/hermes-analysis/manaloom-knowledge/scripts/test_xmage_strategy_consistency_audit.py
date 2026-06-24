#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

import xmage_strategy_consistency_audit as audit


class XMageStrategyConsistencyAuditTests(unittest.TestCase):
    def test_pattern_registry_audit_rejects_executable_shadow_pattern(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "registry.json"
            path.write_text(
                json.dumps(
                    {
                        "summary": {
                            "promotion_status": "shadow_only",
                            "executable_pattern_count": 1,
                            "auto_promotable_pattern_count": 0,
                        },
                        "patterns": [
                            {
                                "pattern_id": "unsafe",
                                "can_execute_in_battle": True,
                                "can_auto_promote_to_card_battle_rules": False,
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            checks = audit.audit_pattern_registry(path)

        statuses = {check.name: check.status for check in checks}
        self.assertEqual(statuses["pattern_registry.executable_pattern_count"], "fail")
        self.assertEqual(statuses["pattern_registry.unsafe_pattern_flags"], "fail")

    def test_full_audit_passes_with_current_fixture_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            benchmark = root / "benchmark.json"
            registry = root / "registry.json"
            schema = root / "schema.sql"
            queue = root / "queue.json"
            manifest = root / "manifest.json"
            benchmark.write_text(
                json.dumps(
                    {
                        "summary": {
                            "recommended_strategy_id": "hybrid_effective_queue_pattern_registry",
                            "ranking": [
                                {"strategy_id": "hybrid_effective_queue_pattern_registry", "decision_score": 80.1}
                            ],
                        }
                    }
                ),
                encoding="utf-8",
            )
            registry.write_text(
                json.dumps(
                    {
                        "summary": {
                            "promotion_status": "shadow_only",
                            "executable_pattern_count": 0,
                            "auto_promotable_pattern_count": 0,
                        },
                        "patterns": [
                            {
                                "pattern_id": "safe",
                                "can_execute_in_battle": False,
                                "can_auto_promote_to_card_battle_rules": False,
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            schema.write_text(
                "\n".join(
                    [
                        "CREATE TABLE IF NOT EXISTS public.xmage_pattern_registry ();",
                        "promotion_status <> 'shadow_only'",
                        "can_execute_in_battle = FALSE",
                        "can_auto_promote_to_card_battle_rules = FALSE",
                    ]
                ),
                encoding="utf-8",
            )
            queue.write_text(
                json.dumps(
                    {
                        "effective_queue": {
                            "lane_counts": {
                                "package_ready_unprepared": 0,
                                "package_already_prepared": 1,
                            }
                        }
                    }
                ),
                encoding="utf-8",
            )
            manifest.write_text(
                json.dumps(
                    {
                        "aggregate_scope": {
                            "artifact_deck_ids": [6],
                            "learned_deck_ids": [25, 31],
                            "forced_include_deck_ids": [6, 608, 609],
                            "effective_deck_ids": [6, 25, 31, 608, 609],
                        },
                        "materialization": [
                            {"learned_deck_id": 25, "apply": False},
                            {"learned_deck_id": 31, "apply": False},
                        ],
                    }
                ),
                encoding="utf-8",
            )
            args = SimpleNamespace(
                benchmark_report=str(benchmark),
                pattern_registry_report=str(registry),
                pattern_schema_sql=str(schema),
                effective_queue_report=str(queue),
                pipeline_manifest=str(manifest),
                expected_effective_deck_id=[608, 609],
            )
            report = audit.build_report(args)

        self.assertEqual(report["status"], "pass", report["checks"])
        self.assertEqual(report["summary"]["status_counts"].get("fail", 0), 0)


if __name__ == "__main__":
    unittest.main()
