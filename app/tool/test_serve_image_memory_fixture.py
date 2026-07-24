import struct
import threading
import unittest
import urllib.request

from serve_image_memory_fixture import (
    ConcurrentFixtureServer,
    FIXTURE_HEIGHT,
    FIXTURE_WIDTH,
    FixtureStats,
    ImageMemoryFixtureHandler,
    fixture_headers,
    generate_fixture_png,
    is_loopback_host,
)


class ImageMemoryFixtureTest(unittest.TestCase):
    def test_live_fixture_response_sends_declared_headers_and_complete_body(
        self,
    ) -> None:
        data = generate_fixture_png(width=8, height=8)
        ImageMemoryFixtureHandler.fixture_data = data
        ImageMemoryFixtureHandler.response_headers = fixture_headers(data)
        ImageMemoryFixtureHandler.stats = FixtureStats(len(data))
        server = ConcurrentFixtureServer(
            ("127.0.0.1", 0),
            ImageMemoryFixtureHandler,
        )
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(thread.join, 2)
        self.addCleanup(server.shutdown)

        host, port = server.server_address
        with urllib.request.urlopen(
            f"http://{host}:{port}/assets/symbols/logo.png?memory_sample=7",
            timeout=2,
        ) as response:
            body = response.read()

        self.assertEqual(body, data)
        self.assertEqual(response.headers["Access-Control-Allow-Origin"], "*")
        self.assertEqual(response.headers["Timing-Allow-Origin"], "*")
        self.assertEqual(response.headers["Content-Length"], str(len(data)))
        self.assertIn("immutable", response.headers["Cache-Control"])

    def test_listener_is_restricted_to_loopback(self) -> None:
        self.assertTrue(is_loopback_host("127.0.0.1"))
        self.assertTrue(is_loopback_host("::1"))
        self.assertTrue(is_loopback_host("localhost"))
        self.assertFalse(is_loopback_host("0.0.0.0"))
        self.assertFalse(is_loopback_host("example.com"))

    def test_fixture_server_has_a_bounded_high_concurrency_backlog(self) -> None:
        self.assertTrue(ConcurrentFixtureServer.daemon_threads)
        self.assertGreaterEqual(ConcurrentFixtureServer.request_queue_size, 180)

    def test_fixture_headers_enable_timing_and_immutable_cache(self) -> None:
        headers = fixture_headers(b"fixture")

        self.assertEqual(headers["Access-Control-Allow-Origin"], "*")
        self.assertEqual(headers["Timing-Allow-Origin"], "*")
        self.assertIn("immutable", headers["Cache-Control"])
        self.assertEqual(headers["Content-Length"], "7")
        self.assertTrue(headers["ETag"].startswith('"'))

    def test_generated_fixture_is_deterministic_representative_png(self) -> None:
        first = generate_fixture_png()
        second = generate_fixture_png()

        self.assertEqual(first, second)
        self.assertTrue(first.startswith(b"\x89PNG\r\n\x1a\n"))
        self.assertEqual(first[12:16], b"IHDR")
        self.assertEqual(
            struct.unpack(">II", first[16:24]),
            (FIXTURE_WIDTH, FIXTURE_HEIGHT),
        )
        self.assertGreater(len(first), 50_000)
        self.assertLess(len(first), 150_000)

    def test_generated_fixture_rejects_invalid_dimensions(self) -> None:
        with self.assertRaises(ValueError):
            generate_fixture_png(width=0, height=1)

    def test_stats_distinguish_unique_samples_from_duplicate_requests(self) -> None:
        stats = FixtureStats(payload_bytes=7)
        stats.record_attempt(0)
        stats.record_attempt(1)
        stats.record_attempt(1)
        stats.record_attempt(2)
        stats.record(0)
        stats.record(1)
        stats.record(1)

        self.assertEqual(
            stats.snapshot(),
            {
                "attempted_request_count": 4,
                "attempted_unique_sample_count": 3,
                "request_count": 3,
                "bytes_sent": 21,
                "unique_sample_count": 2,
                "duplicate_request_count": 1,
                "minimum_sample_index": 0,
                "maximum_sample_index": 1,
            },
        )


if __name__ == "__main__":
    unittest.main()
