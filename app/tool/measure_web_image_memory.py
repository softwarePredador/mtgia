#!/usr/bin/env python3
"""Measure Flutter Web image memory and cache behavior through ChromeDriver.

The browser session is created by ``flutter drive``. This monitor attaches to
that existing session, synchronizes with the integration test through explicit
DOM checkpoints, and records:

* aggregate RSS for the isolated Chrome process tree;
* Runtime/CDP JavaScript and embedder heap usage;
* DOM counters;
* Resource Timing transfer and cache-reuse evidence for the image fixture.

Missing checkpoints, browser process identity, resource entries, or samples
are hard failures. This script never turns an unavailable runtime into PASS.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import time
import urllib.request
from pathlib import Path
from typing import Any, Sequence
from urllib.parse import parse_qs, urlparse

from measure_runtime_startup import WebDriverClient


SCHEMA_VERSION = "manaloom_web_image_memory_v1"
PHASE_ATTRIBUTE = "data-manaloom-image-memory-phase"
ACK_ATTRIBUTE = "data-manaloom-image-memory-ack"
READY_ATTRIBUTE = "data-manaloom-image-memory-cdp-ready"
ERROR_ATTRIBUTE = "data-manaloom-image-memory-probe-error"
EXPECTED_PHASES = ("baseline", "first_pass", "repeat_pass", "cleaned")


def parse_process_rows(output: str) -> dict[int, tuple[int, int]]:
    """Parse ``ps`` PID/PPID/RSS rows into bytes."""

    rows: dict[int, tuple[int, int]] = {}
    for raw_line in output.splitlines():
        parts = raw_line.split()
        if len(parts) != 3:
            continue
        try:
            pid, parent_pid, rss_kib = (int(part) for part in parts)
        except ValueError:
            continue
        rows[pid] = (parent_pid, rss_kib * 1024)
    return rows


def process_tree_rss(
    rows: dict[int, tuple[int, int]],
    root_pid: int,
) -> tuple[int, int]:
    """Return aggregate RSS and process count for a root and its descendants."""

    if root_pid not in rows:
        raise RuntimeError(f"Chrome root PID {root_pid} is not present in ps.")

    selected = {root_pid}
    changed = True
    while changed:
        changed = False
        for pid, (parent_pid, _) in rows.items():
            if pid not in selected and parent_pid in selected:
                selected.add(pid)
                changed = True

    return sum(rows[pid][1] for pid in selected), len(selected)


def read_process_tree_rss(root_pid: int) -> tuple[int, int]:
    completed = subprocess.run(
        ["ps", "-axo", "pid=,ppid=,rss="],
        check=True,
        capture_output=True,
        text=True,
    )
    return process_tree_rss(parse_process_rows(completed.stdout), root_pid)


def tracked_heap_bytes(heap: dict[str, Any]) -> int:
    """Combine disjoint Runtime heap buckets exposed by Chrome."""

    return sum(
        int(heap.get(field, 0) or 0)
        for field in ("usedSize", "embedderHeapUsedSize", "backingStorageSize")
    )


def resource_summary(
    entries: Sequence[dict[str, Any]],
    *,
    marker: str = "memory_sample",
) -> dict[str, Any]:
    fixture_entries: list[dict[str, Any]] = []
    sample_indices: set[int] = set()
    initiators: dict[str, int] = {}

    for entry in entries:
        name = str(entry.get("name", ""))
        query = parse_qs(urlparse(name).query)
        raw_indices = query.get(marker)
        if not raw_indices:
            continue
        try:
            sample_indices.add(int(raw_indices[-1]))
        except (TypeError, ValueError):
            continue
        fixture_entries.append(entry)
        initiator = str(entry.get("initiatorType", "unknown"))
        initiators[initiator] = initiators.get(initiator, 0) + 1

    def total(field: str) -> int:
        return sum(int(entry.get(field, 0) or 0) for entry in fixture_entries)

    return {
        "request_count": len(fixture_entries),
        "unique_sample_count": len(sample_indices),
        "minimum_sample_index": min(sample_indices) if sample_indices else None,
        "maximum_sample_index": max(sample_indices) if sample_indices else None,
        "transfer_bytes": total("transferSize"),
        "encoded_body_bytes": total("encodedBodySize"),
        "decoded_body_bytes": total("decodedBodySize"),
        "zero_transfer_count": sum(
            1
            for entry in fixture_entries
            if int(entry.get("transferSize", 0) or 0) == 0
        ),
        "initiators": dict(sorted(initiators.items())),
    }


def read_fixture_stats(url: str) -> dict[str, int]:
    with urllib.request.urlopen(url, timeout=5) as response:
        value = json.load(response)
    if not isinstance(value, dict):
        raise RuntimeError("The image fixture stats endpoint returned invalid JSON.")
    required = {
        "request_count",
        "bytes_sent",
        "unique_sample_count",
        "duplicate_request_count",
    }
    if not required.issubset(value):
        raise RuntimeError("The image fixture stats endpoint omitted required fields.")
    return {key: int(value[key]) for key in required}


def maximum_sample_value(
    samples: Sequence[dict[str, int]],
    field: str,
    fallback: int,
) -> int:
    return max([fallback, *(int(sample[field]) for sample in samples)])


def budget_metric(value: int, budget: int) -> dict[str, Any]:
    return {
        "value_bytes": value,
        "budget_bytes": budget,
        "status": "pass" if value <= budget else "fail",
    }


def minimum_metric(value: int, minimum: int) -> dict[str, Any]:
    return {
        "value": value,
        "minimum": minimum,
        "status": "pass" if value >= minimum else "fail",
    }


def build_result(
    *,
    target: dict[str, Any],
    checkpoints: dict[str, dict[str, Any]],
    first_pass_samples: Sequence[dict[str, int]],
    repeat_pass_samples: Sequence[dict[str, int]],
    expected_image_count: int,
    minimum_runtime_samples: int,
    rss_growth_budget_bytes: int,
    repeat_rss_growth_budget_bytes: int,
    settled_rss_growth_budget_bytes: int,
    heap_growth_budget_bytes: int,
    repeat_heap_growth_budget_bytes: int,
    transfer_budget_bytes: int,
    repeat_transfer_budget_bytes: int,
) -> dict[str, Any]:
    baseline = checkpoints["baseline"]
    first = checkpoints["first_pass"]
    repeat = checkpoints["repeat_pass"]
    cleaned = checkpoints["cleaned"]

    baseline_rss = int(baseline["rss"]["bytes"])
    first_rss_peak = maximum_sample_value(
        first_pass_samples,
        "rss_bytes",
        int(first["rss"]["bytes"]),
    )
    repeat_rss_peak = maximum_sample_value(
        repeat_pass_samples,
        "rss_bytes",
        int(repeat["rss"]["bytes"]),
    )
    baseline_heap = int(baseline["heap"]["tracked_bytes"])
    first_heap_peak = maximum_sample_value(
        first_pass_samples,
        "tracked_heap_bytes",
        int(first["heap"]["tracked_bytes"]),
    )
    repeat_heap_peak = maximum_sample_value(
        repeat_pass_samples,
        "tracked_heap_bytes",
        int(repeat["heap"]["tracked_bytes"]),
    )

    first_resources = first["resources"]
    repeat_resources = repeat["resources"]
    first_fixture = first_resources["fixture_server"]
    repeat_fixture = repeat_resources["fixture_server"]
    runtime_sample_count = len(first_pass_samples) + len(repeat_pass_samples)

    metrics = {
        "runtime_samples": minimum_metric(
            runtime_sample_count,
            minimum_runtime_samples,
        ),
        "image_samples": minimum_metric(
            int(first_resources["unique_sample_count"]),
            expected_image_count,
        ),
        "fixture_server_image_samples": minimum_metric(
            int(first_fixture["unique_sample_count"]),
            expected_image_count,
        ),
        "rss_growth": budget_metric(
            max(0, max(first_rss_peak, repeat_rss_peak) - baseline_rss),
            rss_growth_budget_bytes,
        ),
        "repeat_rss_growth": budget_metric(
            max(0, repeat_rss_peak - first_rss_peak),
            repeat_rss_growth_budget_bytes,
        ),
        "settled_rss_growth": budget_metric(
            max(0, int(cleaned["rss"]["bytes"]) - baseline_rss),
            settled_rss_growth_budget_bytes,
        ),
        "heap_growth": budget_metric(
            max(0, max(first_heap_peak, repeat_heap_peak) - baseline_heap),
            heap_growth_budget_bytes,
        ),
        "repeat_heap_growth": budget_metric(
            max(0, repeat_heap_peak - first_heap_peak),
            repeat_heap_growth_budget_bytes,
        ),
        "image_transfer": budget_metric(
            int(first_fixture["bytes_sent"]),
            transfer_budget_bytes,
        ),
        "repeat_image_transfer": budget_metric(
            max(
                0,
                int(repeat_fixture["bytes_sent"])
                - int(first_fixture["bytes_sent"]),
            ),
            repeat_transfer_budget_bytes,
        ),
    }
    return {
        "schema_version": SCHEMA_VERSION,
        "platform": "web",
        "target": target,
        "checkpoints": checkpoints,
        "peaks": {
            "first_pass_rss_bytes": first_rss_peak,
            "repeat_pass_rss_bytes": repeat_rss_peak,
            "first_pass_tracked_heap_bytes": first_heap_peak,
            "repeat_pass_tracked_heap_bytes": repeat_heap_peak,
            "runtime_sample_count": runtime_sample_count,
        },
        "metrics": metrics,
        "result": (
            "pass"
            if all(metric["status"] == "pass" for metric in metrics.values())
            else "fail"
        ),
    }


class ExistingChromeSession:
    def __init__(
        self,
        *,
        webdriver_url: str,
        session_id: str,
    ) -> None:
        self.client = WebDriverClient(webdriver_url)
        self.session_id = session_id

    @property
    def prefix(self) -> str:
        return f"/session/{self.session_id}"

    def capabilities(self) -> dict[str, Any]:
        value = self.client.request(self.prefix).get("value", {})
        capabilities = value.get("capabilities", value)
        if not isinstance(capabilities, dict):
            raise RuntimeError("ChromeDriver did not return session capabilities.")
        return capabilities

    def execute(self, script: str, args: Sequence[Any] = ()) -> Any:
        response = self.client.request(
            f"{self.prefix}/execute/sync",
            {"script": script, "args": list(args)},
        )
        return response.get("value")

    def cdp(self, command: str, params: dict[str, Any] | None = None) -> Any:
        response = self.client.request(
            f"{self.prefix}/goog/cdp/execute",
            {"cmd": command, "params": params or {}},
        )
        return response.get("value")

    def attribute(self, name: str) -> str | None:
        value = self.execute(
            """
return document.documentElement
  ? document.documentElement.getAttribute(arguments[0])
  : null;
""",
            [name],
        )
        return None if value is None else str(value)

    def set_attribute(self, name: str, value: str) -> None:
        self.execute(
            """
if (!document.documentElement) return false;
document.documentElement.setAttribute(arguments[0], arguments[1]);
return true;
""",
            [name, value],
        )

    def resource_entries(self) -> list[dict[str, Any]]:
        value = self.execute(
            """
return performance.getEntriesByType('resource').map((entry) => ({
  name: entry.name,
  initiatorType: entry.initiatorType || 'unknown',
  transferSize: Number(entry.transferSize || 0),
  encodedBodySize: Number(entry.encodedBodySize || 0),
  decodedBodySize: Number(entry.decodedBodySize || 0),
  duration: Number(entry.duration || 0),
}));
"""
        )
        if not isinstance(value, list):
            raise RuntimeError("Resource Timing did not return a list.")
        return [entry for entry in value if isinstance(entry, dict)]

    def console_messages(self) -> list[str]:
        value = self.execute(
            """
return Array.isArray(window.__manaloomImageMemoryConsole)
  ? window.__manaloomImageMemoryConsole.slice(-100)
  : [];
"""
        )
        if not isinstance(value, list):
            return []
        return [str(item) for item in value]


class RuntimeSampler:
    def __init__(
        self,
        session: ExistingChromeSession,
        root_pid: int,
        fixture_stats_url: str,
    ) -> None:
        self.session = session
        self.root_pid = root_pid
        self.fixture_stats_url = fixture_stats_url

    def sample(self) -> dict[str, int]:
        rss_bytes, process_count = read_process_tree_rss(self.root_pid)
        heap = self.session.cdp("Runtime.getHeapUsage")
        if not isinstance(heap, dict):
            raise RuntimeError("Runtime.getHeapUsage returned an invalid body.")
        return {
            "rss_bytes": rss_bytes,
            "process_count": process_count,
            "tracked_heap_bytes": tracked_heap_bytes(heap),
        }

    def checkpoint(self) -> dict[str, Any]:
        rss_bytes, process_count = read_process_tree_rss(self.root_pid)
        heap = self.session.cdp("Runtime.getHeapUsage")
        dom = self.session.cdp("Memory.getDOMCounters")
        performance = self.session.cdp("Performance.getMetrics")
        if not isinstance(heap, dict) or not isinstance(dom, dict):
            raise RuntimeError("Chrome returned invalid heap or DOM metrics.")

        performance_metrics: dict[str, float] = {}
        if isinstance(performance, dict):
            for item in performance.get("metrics", []):
                if isinstance(item, dict) and "name" in item and "value" in item:
                    performance_metrics[str(item["name"])] = float(item["value"])

        resources = resource_summary(self.session.resource_entries())
        resources["fixture_server"] = read_fixture_stats(self.fixture_stats_url)
        return {
            "rss": {
                "bytes": rss_bytes,
                "process_count": process_count,
            },
            "heap": {
                **{key: int(value) for key, value in heap.items()},
                "tracked_bytes": tracked_heap_bytes(heap),
            },
            "dom": {key: int(value) for key, value in dom.items()},
            "performance": {
                key: performance_metrics[key]
                for key in (
                    "Documents",
                    "Frames",
                    "JSHeapTotalSize",
                    "JSHeapUsedSize",
                    "LayoutObjects",
                    "Nodes",
                )
                if key in performance_metrics
            },
            "resources": resources,
            "browser_console": self.session.console_messages(),
        }


def wait_for_attribute(
    session: ExistingChromeSession,
    *,
    name: str,
    expected: str,
    timeout_seconds: float,
    poll_seconds: float,
    sampler: RuntimeSampler | None = None,
) -> list[dict[str, int]]:
    deadline = time.monotonic() + timeout_seconds
    samples: list[dict[str, int]] = []
    while time.monotonic() < deadline:
        if session.attribute(name) == expected:
            return samples
        if sampler is not None:
            samples.append(sampler.sample())
        time.sleep(poll_seconds)
    current = session.attribute(name)
    raise TimeoutError(
        f"Timed out waiting for {name}={expected!r}; current={current!r}."
    )


def run_probe(args: argparse.Namespace) -> dict[str, Any]:
    session = ExistingChromeSession(
        webdriver_url=args.webdriver_url,
        session_id=args.session_id,
    )
    wait_for_attribute(
        session,
        name=PHASE_ATTRIBUTE,
        expected="awaiting_cdp",
        timeout_seconds=args.timeout_seconds,
        poll_seconds=args.poll_seconds,
    )

    capabilities = (
        json.loads(args.capabilities_json)
        if args.capabilities_json
        else session.capabilities()
    )
    if not isinstance(capabilities, dict):
        raise RuntimeError("ChromeDriver capabilities are not a JSON object.")
    root_pid = int(capabilities.get("goog:processID", 0) or 0)
    if root_pid <= 0:
        raise RuntimeError("ChromeDriver did not expose goog:processID.")

    session.cdp("Performance.enable")
    session.cdp("HeapProfiler.enable")
    session.cdp("Network.enable")
    session.cdp("Network.setCacheDisabled", {"cacheDisabled": False})
    session.cdp("Memory.setPressureNotificationsSuppressed", {"suppressed": True})
    session.execute(
        """
performance.setResourceTimingBufferSize(1000);
performance.clearResourceTimings();
window.__manaloomImageMemoryConsole = [];
for (const level of ['log', 'warn', 'error']) {
  const original = console[level].bind(console);
  console[level] = (...args) => {
    const line = args.map((value) => {
      try {
        return typeof value === 'string' ? value : JSON.stringify(value);
      } catch (_) {
        return String(value);
      }
    }).join(' ');
    if (line.includes('CachedCardImage')) {
      window.__manaloomImageMemoryConsole.push(`${level}: ${line}`);
    }
    original(...args);
  };
}
return true;
"""
    )
    sampler = RuntimeSampler(session, root_pid, args.fixture_stats_url)
    session.set_attribute(READY_ATTRIBUTE, "1")

    checkpoints: dict[str, dict[str, Any]] = {}
    phase_samples: dict[str, list[dict[str, int]]] = {}
    for phase in EXPECTED_PHASES:
        phase_samples[phase] = wait_for_attribute(
            session,
            name=PHASE_ATTRIBUTE,
            expected=phase,
            timeout_seconds=args.timeout_seconds,
            poll_seconds=args.poll_seconds,
            sampler=None if phase == "baseline" else sampler,
        )
        if phase in {"baseline", "cleaned"}:
            session.cdp("HeapProfiler.collectGarbage")
        checkpoints[phase] = sampler.checkpoint()
        session.set_attribute(ACK_ATTRIBUTE, phase)

    chrome = capabilities.get("chrome", {})
    target = {
        "browser_name": capabilities.get("browserName"),
        "browser_version": capabilities.get("browserVersion"),
        "chromedriver_version": (
            chrome.get("chromedriverVersion")
            if isinstance(chrome, dict)
            else None
        ),
        "chrome_root_pid": root_pid,
        "signal": (
            "chrome_process_tree_rss+runtime_heap+dom_counters+resource_timing"
        ),
        "fixture_marker": "memory_sample",
        "fixture_stats_url": args.fixture_stats_url,
        "expected_image_count": args.expected_image_count,
    }
    return build_result(
        target=target,
        checkpoints=checkpoints,
        first_pass_samples=phase_samples["first_pass"],
        repeat_pass_samples=phase_samples["repeat_pass"],
        expected_image_count=args.expected_image_count,
        minimum_runtime_samples=args.minimum_runtime_samples,
        rss_growth_budget_bytes=args.rss_growth_budget_bytes,
        repeat_rss_growth_budget_bytes=args.repeat_rss_growth_budget_bytes,
        settled_rss_growth_budget_bytes=args.settled_rss_growth_budget_bytes,
        heap_growth_budget_bytes=args.heap_growth_budget_bytes,
        repeat_heap_growth_budget_bytes=args.repeat_heap_growth_budget_bytes,
        transfer_budget_bytes=args.transfer_budget_bytes,
        repeat_transfer_budget_bytes=args.repeat_transfer_budget_bytes,
    )


def positive_int(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be positive")
    return parsed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--webdriver-url", required=True)
    parser.add_argument("--session-id", required=True)
    parser.add_argument("--fixture-stats-url", required=True)
    parser.add_argument(
        "--capabilities-json",
        help=(
            "W3C session capabilities supplied by flutter drive. "
            "When omitted, the monitor attempts the legacy session info endpoint."
        ),
    )
    parser.add_argument("--output", type=Path)
    parser.add_argument("--expected-image-count", type=positive_int, default=180)
    parser.add_argument("--minimum-runtime-samples", type=positive_int, default=6)
    parser.add_argument("--timeout-seconds", type=float, default=60.0)
    parser.add_argument("--poll-seconds", type=float, default=0.20)
    parser.add_argument(
        "--rss-growth-budget-bytes",
        type=positive_int,
        default=256 * 1024 * 1024,
    )
    parser.add_argument(
        "--repeat-rss-growth-budget-bytes",
        type=positive_int,
        default=64 * 1024 * 1024,
    )
    parser.add_argument(
        "--settled-rss-growth-budget-bytes",
        type=positive_int,
        default=192 * 1024 * 1024,
    )
    parser.add_argument(
        "--heap-growth-budget-bytes",
        type=positive_int,
        default=128 * 1024 * 1024,
    )
    parser.add_argument(
        "--repeat-heap-growth-budget-bytes",
        type=positive_int,
        default=32 * 1024 * 1024,
    )
    parser.add_argument(
        "--transfer-budget-bytes",
        type=positive_int,
        default=64 * 1024 * 1024,
    )
    parser.add_argument(
        "--repeat-transfer-budget-bytes",
        type=positive_int,
        default=1024 * 1024,
    )
    args = parser.parse_args()
    if args.timeout_seconds <= 0 or args.poll_seconds <= 0:
        parser.error("timeouts and polling intervals must be positive")
    return args


def render_result(result: dict[str, Any], output: Path | None) -> None:
    rendered = json.dumps(result, indent=2, sort_keys=True)
    if output is not None:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(f"{rendered}\n", encoding="utf-8")
    print(rendered)


def main() -> int:
    args = parse_args()
    try:
        result = run_probe(args)
    except Exception as error:  # noqa: BLE001 - CLI must persist blocked evidence.
        try:
            ExistingChromeSession(
                webdriver_url=args.webdriver_url,
                session_id=args.session_id,
            ).set_attribute(ERROR_ATTRIBUTE, f"{type(error).__name__}: {error}")
        except Exception:
            pass
        result = {
            "schema_version": SCHEMA_VERSION,
            "platform": "web",
            "result": "blocked",
            "error": {
                "type": type(error).__name__,
                "message": str(error),
            },
        }
        render_result(result, args.output)
        return 2

    render_result(result, args.output)
    return 0 if result["result"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
