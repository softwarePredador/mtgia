import unittest

from measure_runtime_startup import (
    build_result,
    metric,
    nearest_rank_percentile,
    parse_android_wait_time,
)


class RuntimeStartupMeasurementTest(unittest.TestCase):
    def test_nearest_rank_percentiles_do_not_interpolate(self) -> None:
        values = [9, 1, 7, 3, 5, 11, 13]

        self.assertEqual(nearest_rank_percentile(values, 0.50), 7)
        self.assertEqual(nearest_rank_percentile(values, 0.95), 13)

    def test_android_wait_time_parser_uses_stable_wait_signal(self) -> None:
        output = """Status: ok
LaunchState: COLD
Activity: com.mtgia.mtg_app/.MainActivity
TotalTime: 2183
WaitTime: 2190
Complete
"""

        self.assertEqual(parse_android_wait_time(output), 2190)

    def test_metric_fails_when_p95_exceeds_budget(self) -> None:
        measured = metric([100, 120, 140, 180], budget_ms=150)

        self.assertEqual(measured["p50_ms"], 120)
        self.assertEqual(measured["p95_ms"], 180)
        self.assertEqual(measured["status"], "fail")

    def test_result_requires_both_cold_and_warm_budgets(self) -> None:
        result = build_result(
            platform="web",
            cold=[500, 550, 600],
            warm=[150, 170, 200],
            cold_budget_ms=700,
            warm_budget_ms=180,
            target={"signal": "test"},
        )

        self.assertEqual(result["metrics"]["cold_start"]["status"], "pass")
        self.assertEqual(result["metrics"]["warm_start"]["status"], "fail")
        self.assertEqual(result["result"], "fail")


if __name__ == "__main__":
    unittest.main()
