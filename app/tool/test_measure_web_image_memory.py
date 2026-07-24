import io
import json
import unittest
from unittest.mock import patch

from measure_web_image_memory import (
    build_result,
    parse_process_rows,
    process_tree_rss,
    read_fixture_stats,
    resource_summary,
    tracked_heap_bytes,
)


def checkpoint(
    *,
    rss: int,
    heap: int,
    unique_images: int,
    transfer: int,
) -> dict:
    return {
        "rss": {"bytes": rss, "process_count": 4},
        "heap": {"tracked_bytes": heap},
        "dom": {"nodes": 10},
        "performance": {},
        "resources": {
            "request_count": unique_images,
            "unique_sample_count": unique_images,
            "minimum_sample_index": 0 if unique_images else None,
            "maximum_sample_index": unique_images - 1 if unique_images else None,
            "transfer_bytes": transfer,
            "encoded_body_bytes": transfer,
            "decoded_body_bytes": transfer,
            "zero_transfer_count": 0,
            "initiators": {"img": unique_images},
            "fixture_server": {
                "request_count": unique_images,
                "bytes_sent": transfer,
                "unique_sample_count": unique_images,
                "duplicate_request_count": 0,
            },
        },
    }


class WebImageMemoryMeasurementTest(unittest.TestCase):
    @patch("measure_web_image_memory.urllib.request.urlopen")
    def test_fixture_stats_preserve_attempt_and_completion_counts(
        self,
        urlopen,
    ) -> None:
        urlopen.return_value = io.BytesIO(
            json.dumps(
                {
                    "attempted_request_count": 9,
                    "attempted_unique_sample_count": 8,
                    "request_count": 7,
                    "bytes_sent": 700,
                    "unique_sample_count": 6,
                    "duplicate_request_count": 1,
                }
            ).encode()
        )

        stats = read_fixture_stats("http://127.0.0.1:8091/stats")

        self.assertEqual(stats["attempted_request_count"], 9)
        self.assertEqual(stats["attempted_unique_sample_count"], 8)
        self.assertEqual(stats["request_count"], 7)

    def test_process_tree_rss_ignores_unrelated_processes(self) -> None:
        rows = parse_process_rows(
            """100 1 1000
101 100 2000
102 101 3000
900 1 9999
"""
        )

        rss, count = process_tree_rss(rows, 100)

        self.assertEqual(rss, (1000 + 2000 + 3000) * 1024)
        self.assertEqual(count, 3)

    def test_resource_summary_tracks_fixture_indices_and_cache_hits(self) -> None:
        summary = resource_summary(
            [
                {
                    "name": "http://127.0.0.1/card.png?memory_sample=0",
                    "initiatorType": "img",
                    "transferSize": 400,
                    "encodedBodySize": 300,
                    "decodedBodySize": 300,
                },
                {
                    "name": "http://127.0.0.1/card.png?memory_sample=1",
                    "initiatorType": "img",
                    "transferSize": 0,
                    "encodedBodySize": 300,
                    "decodedBodySize": 300,
                },
                {
                    "name": "http://127.0.0.1/main.dart.js",
                    "initiatorType": "script",
                    "transferSize": 999,
                },
            ]
        )

        self.assertEqual(summary["request_count"], 2)
        self.assertEqual(summary["unique_sample_count"], 2)
        self.assertEqual(summary["transfer_bytes"], 400)
        self.assertEqual(summary["zero_transfer_count"], 1)

    def test_tracked_heap_uses_runtime_disjoint_buckets(self) -> None:
        self.assertEqual(
            tracked_heap_bytes(
                {
                    "usedSize": 10,
                    "embedderHeapUsedSize": 20,
                    "backingStorageSize": 30,
                }
            ),
            60,
        )

    def test_result_passes_only_with_images_samples_and_budgets(self) -> None:
        result = build_result(
            target={"signal": "test"},
            checkpoints={
                "baseline": checkpoint(
                    rss=100,
                    heap=50,
                    unique_images=0,
                    transfer=0,
                ),
                "first_pass": checkpoint(
                    rss=160,
                    heap=80,
                    unique_images=3,
                    transfer=900,
                ),
                "repeat_pass": checkpoint(
                    rss=170,
                    heap=85,
                    unique_images=3,
                    transfer=900,
                ),
                "cleaned": checkpoint(
                    rss=120,
                    heap=60,
                    unique_images=3,
                    transfer=900,
                ),
            },
            first_pass_samples=[
                {
                    "rss_bytes": 150,
                    "tracked_heap_bytes": 75,
                    "process_count": 4,
                }
            ],
            repeat_pass_samples=[
                {
                    "rss_bytes": 170,
                    "tracked_heap_bytes": 85,
                    "process_count": 4,
                }
            ],
            expected_image_count=3,
            minimum_runtime_samples=2,
            rss_growth_budget_bytes=100,
            repeat_rss_growth_budget_bytes=20,
            settled_rss_growth_budget_bytes=25,
            heap_growth_budget_bytes=40,
            repeat_heap_growth_budget_bytes=10,
            transfer_budget_bytes=1000,
            repeat_transfer_budget_bytes=1,
        )

        self.assertEqual(result["result"], "pass")
        self.assertTrue(
            all(metric["status"] == "pass" for metric in result["metrics"].values())
        )

    def test_result_fails_when_repeat_transfer_exceeds_budget(self) -> None:
        result = build_result(
            target={"signal": "test"},
            checkpoints={
                "baseline": checkpoint(
                    rss=100,
                    heap=50,
                    unique_images=0,
                    transfer=0,
                ),
                "first_pass": checkpoint(
                    rss=150,
                    heap=75,
                    unique_images=3,
                    transfer=900,
                ),
                "repeat_pass": checkpoint(
                    rss=155,
                    heap=76,
                    unique_images=3,
                    transfer=1300,
                ),
                "cleaned": checkpoint(
                    rss=110,
                    heap=55,
                    unique_images=3,
                    transfer=1300,
                ),
            },
            first_pass_samples=[
                {
                    "rss_bytes": 150,
                    "tracked_heap_bytes": 75,
                    "process_count": 4,
                }
            ],
            repeat_pass_samples=[
                {
                    "rss_bytes": 155,
                    "tracked_heap_bytes": 76,
                    "process_count": 4,
                }
            ],
            expected_image_count=3,
            minimum_runtime_samples=2,
            rss_growth_budget_bytes=100,
            repeat_rss_growth_budget_bytes=20,
            settled_rss_growth_budget_bytes=25,
            heap_growth_budget_bytes=40,
            repeat_heap_growth_budget_bytes=10,
            transfer_budget_bytes=1000,
            repeat_transfer_budget_bytes=100,
        )

        self.assertEqual(result["metrics"]["repeat_image_transfer"]["status"], "fail")
        self.assertEqual(result["result"], "fail")


if __name__ == "__main__":
    unittest.main()
