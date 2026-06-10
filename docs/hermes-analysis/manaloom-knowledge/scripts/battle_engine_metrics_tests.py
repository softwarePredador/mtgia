"""Battle engine metrics and sanitized report regressions."""

import json
import random
import tempfile
from pathlib import Path


def register_tests(battle, player, engine_metrics_report):
    def test_engine_metrics_collects_core_health_signals():
        metrics = battle.set_engine_metrics(battle.EngineMetrics())
        try:
            stack = battle.Stack()
            stack.push({"name": "Metric Spell", "type_line": "Instant"})
            stack.resolve_top()

            active = player("Active")
            active.life = 5
            active.life_cant_change = True
            assert battle.deal_damage(active, 3) is False

            walker = {
                "name": "Metric Walker",
                "type_line": "Planeswalker",
                "loyalty": 0,
            }
            active.battlefield = [walker]
            battle.check_sbas_until_stable([active])
            battle.priority_round(
                active,
                [active],
                battle.Stack(),
                1,
                random.Random(110),
                phase="upkeep",
            )

            snapshot = metrics.snapshot()
            assert snapshot["counters"]["stack_pushes"] == 1
            assert snapshot["counters"]["stack_resolutions"] == 1
            assert snapshot["counters"]["replacement_events"] == 1
            assert snapshot["counters"]["sba_iterations"] == 1
            assert snapshot["counters"]["sba_permanent_moves"] == 1
            assert snapshot["counters"]["priority_rounds"] == 1
            assert snapshot["max_stack_depth"] == 1
            assert snapshot["event_counts"]["replacement_applied"] == 1
        finally:
            battle.clear_engine_metrics()

    def test_engine_metrics_snapshot_writes_sanitized_json():
        metrics = battle.set_engine_metrics(battle.EngineMetrics())
        try:
            metrics.increment("priority_rounds", 2)
            metrics.record_stack_depth(3)
            with tempfile.TemporaryDirectory() as tmp:
                path = Path(tmp) / "metrics.json"
                payload = battle.write_engine_metrics_snapshot(
                    str(path),
                    {"deck_id": "redacted", "games": 4},
                )
                saved = json.loads(path.read_text(encoding="utf-8"))

            assert payload["schema_version"] == "battle_engine_metrics_v1"
            assert saved["metadata"] == {"deck_id": "redacted", "games": 4}
            assert saved["counters"]["priority_rounds"] == 2
            assert saved["max_stack_depth"] == 3
            assert "created_at" in saved
        finally:
            battle.clear_engine_metrics()

    def test_engine_metrics_report_aggregates_sanitized_snapshots():
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "one.json").write_text(
                json.dumps(
                    {
                        "schema_version": "battle_engine_metrics_v1",
                        "counters": {
                            "stack_pushes": 2,
                            "priority_rounds": 3,
                            "sba_permanent_moves": 1,
                        },
                        "event_counts": {"spell_cast": 2},
                        "max_stack_depth": 4,
                        "warnings": ["short warning"],
                    }
                ),
                encoding="utf-8",
            )
            (root / "two.json").write_text(
                json.dumps(
                    {
                        "schema_version": "battle_engine_metrics_v1",
                        "counters": {
                            "stack_pushes": 5,
                            "replacement_events": 2,
                        },
                        "event_counts": {
                            "spell_cast": 1,
                            "replacement_applied": 2,
                        },
                        "max_stack_depth": 2,
                        "warnings": ["x" * 220],
                    }
                ),
                encoding="utf-8",
            )
            (root / "ignore.json").write_text(
                '{"schema_version":"other"}',
                encoding="utf-8",
            )

            report = engine_metrics_report.aggregate_snapshots(root)

        assert report["schema_version"] == "battle_engine_metrics_report_v1"
        assert report["files_processed"] == 2
        assert report["files_skipped"] == 1
        assert report["totals"]["stack_pushes"] == 7
        assert report["totals"]["priority_rounds"] == 3
        assert report["totals"]["replacement_events"] == 2
        assert report["totals"]["sba_permanent_moves"] == 1
        assert report["event_counts"] == {
            "replacement_applied": 2,
            "spell_cast": 3,
        }
        assert report["max_stack_depth"] == 4
        assert len(report["warning_samples"][1]) == 160

    return [
        test_engine_metrics_collects_core_health_signals,
        test_engine_metrics_snapshot_writes_sanitized_json,
        test_engine_metrics_report_aggregates_sanitized_snapshots,
    ]
