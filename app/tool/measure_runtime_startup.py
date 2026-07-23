#!/usr/bin/env python3
"""Measure ManaLoom cold/warm startup on Android or Flutter Web."""

from __future__ import annotations

import argparse
import json
import math
import re
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Sequence


SCHEMA_VERSION = "manaloom_runtime_startup_v1"
WAIT_TIME_PATTERN = re.compile(r"^WaitTime:\s*(\d+)$", re.MULTILINE)


def nearest_rank_percentile(values: Sequence[int], percentile: float) -> int:
    if not values:
        raise ValueError("At least one sample is required.")
    ordered = sorted(values)
    rank = math.ceil(percentile * len(ordered))
    return ordered[max(0, min(rank - 1, len(ordered) - 1))]


def parse_android_wait_time(output: str) -> int:
    match = WAIT_TIME_PATTERN.search(output)
    if match is None:
        raise RuntimeError(f"adb am start did not emit WaitTime: {output!r}")
    return int(match.group(1))


def metric(values: Sequence[int], budget_ms: int) -> dict[str, Any]:
    p95 = nearest_rank_percentile(values, 0.95)
    return {
        "samples": len(values),
        "values_ms": list(values),
        "p50_ms": nearest_rank_percentile(values, 0.50),
        "p95_ms": p95,
        "max_ms": max(values),
        "budget_ms": budget_ms,
        "status": "pass" if p95 <= budget_ms else "fail",
    }


def run_android(args: argparse.Namespace) -> dict[str, Any]:
    adb = [args.adb, "-s", args.device]

    def command(*parts: str) -> str:
        completed = subprocess.run(
            [*adb, *parts],
            check=True,
            capture_output=True,
            text=True,
        )
        return completed.stdout

    def start() -> int:
        output = command(
            "shell",
            "am",
            "start",
            "-W",
            "-n",
            f"{args.package}/{args.activity}",
        )
        return parse_android_wait_time(output)

    cold: list[int] = []
    warm: list[int] = []
    for _ in range(args.samples):
        command("shell", "am", "force-stop", args.package)
        time.sleep(args.settle_seconds)
        cold.append(start())
        time.sleep(args.foreground_seconds)
        command("shell", "input", "keyevent", "KEYCODE_HOME")
        time.sleep(args.settle_seconds)
        warm.append(start())
        time.sleep(args.foreground_seconds)

    return build_result(
        platform="android",
        cold=cold,
        warm=warm,
        cold_budget_ms=args.cold_budget_ms,
        warm_budget_ms=args.warm_budget_ms,
        target={
            "device": args.device,
            "package": args.package,
            "activity": args.activity,
            "signal": "adb_am_start_wait_time",
        },
    )


class WebDriverClient:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")

    def request(
        self,
        path: str,
        payload: dict[str, Any] | None = None,
        method: str | None = None,
    ) -> dict[str, Any]:
        data = None if payload is None else json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            f"{self.base_url}{path}",
            data=data,
            headers={"Content-Type": "application/json"},
            method=method or ("POST" if data is not None else "GET"),
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            body = error.read().decode("utf-8", errors="replace")
            raise RuntimeError(
                f"WebDriver HTTP {error.code} for {path}: {body}"
            ) from error


WEB_READY_SCRIPT = r"""
const done = arguments[arguments.length - 1];
const pollStartedAt = performance.now();
function poll() {
  const canvas = document
    .querySelector("flt-glass-pane")
    ?.shadowRoot
    ?.querySelector("canvas");
  if (canvas && canvas.width > 0 && canvas.height > 0) {
    done({
      ready_ms: Math.round(performance.now()),
      poll_ms: Math.round(performance.now() - pollStartedAt),
      width: canvas.width,
      height: canvas.height,
    });
    return;
  }
  if (performance.now() - pollStartedAt > 15000) {
    done({error: "Flutter first-frame canvas timeout"});
    return;
  }
  setTimeout(poll, 5);
}
poll();
"""


def run_web(args: argparse.Namespace) -> dict[str, Any]:
    client = WebDriverClient(args.webdriver_url)
    cold: list[int] = []
    warm: list[int] = []
    dimensions: set[tuple[int, int]] = set()

    chrome_options: dict[str, Any] = {
        "args": [
            "--headless=new",
            "--no-sandbox",
            f"--window-size={args.window_size}",
        ]
    }
    if args.chrome_binary:
        chrome_options["binary"] = args.chrome_binary

    for _ in range(args.samples):
        response = client.request(
            "/session",
            {
                "capabilities": {
                    "alwaysMatch": {
                        "browserName": "chrome",
                        "goog:chromeOptions": chrome_options,
                    }
                }
            },
        )
        session_id = response["value"]["sessionId"]
        try:
            cold_sample = navigate_until_flutter_ready(
                client, session_id, args.app_url
            )
            warm_sample = navigate_until_flutter_ready(
                client, session_id, args.app_url
            )
            cold.append(cold_sample["ready_ms"])
            warm.append(warm_sample["ready_ms"])
            dimensions.add(
                (cold_sample["width"], cold_sample["height"])
            )
            dimensions.add(
                (warm_sample["width"], warm_sample["height"])
            )
        finally:
            client.request(f"/session/{session_id}", {}, method="DELETE")

    return build_result(
        platform="web",
        cold=cold,
        warm=warm,
        cold_budget_ms=args.cold_budget_ms,
        warm_budget_ms=args.warm_budget_ms,
        target={
            "app_url": args.app_url,
            "webdriver_url": args.webdriver_url,
            "signal": "flutter_first_frame_canvas",
            "canvas_dimensions": [
                {"width": width, "height": height}
                for width, height in sorted(dimensions)
            ],
        },
    )


def navigate_until_flutter_ready(
    client: WebDriverClient,
    session_id: str,
    app_url: str,
) -> dict[str, int]:
    client.request(f"/session/{session_id}/url", {"url": app_url})
    response = client.request(
        f"/session/{session_id}/execute/async",
        {"script": WEB_READY_SCRIPT, "args": []},
    )
    value = response["value"]
    if value.get("error"):
        raise RuntimeError(value["error"])
    return {
        "ready_ms": int(value["ready_ms"]),
        "width": int(value["width"]),
        "height": int(value["height"]),
    }


def build_result(
    *,
    platform: str,
    cold: Sequence[int],
    warm: Sequence[int],
    cold_budget_ms: int,
    warm_budget_ms: int,
    target: dict[str, Any],
) -> dict[str, Any]:
    metrics = {
        "cold_start": metric(cold, cold_budget_ms),
        "warm_start": metric(warm, warm_budget_ms),
    }
    return {
        "schema_version": SCHEMA_VERSION,
        "platform": platform,
        "target": target,
        "metrics": metrics,
        "result": (
            "pass"
            if all(item["status"] == "pass" for item in metrics.values())
            else "fail"
        ),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samples", type=int, default=7)
    parser.add_argument("--output", type=Path)
    subparsers = parser.add_subparsers(dest="platform", required=True)

    android = subparsers.add_parser("android")
    android.add_argument("--adb", default="adb")
    android.add_argument("--device", required=True)
    android.add_argument("--package", default="com.mtgia.mtg_app")
    android.add_argument("--activity", default=".MainActivity")
    android.add_argument("--cold-budget-ms", type=int, default=5000)
    android.add_argument("--warm-budget-ms", type=int, default=1000)
    android.add_argument("--settle-seconds", type=float, default=0.35)
    android.add_argument("--foreground-seconds", type=float, default=0.60)

    web = subparsers.add_parser("web")
    web.add_argument("--webdriver-url", default="http://127.0.0.1:4444")
    web.add_argument("--app-url", required=True)
    web.add_argument("--chrome-binary")
    web.add_argument("--window-size", default="1440,900")
    web.add_argument("--cold-budget-ms", type=int, default=3000)
    web.add_argument("--warm-budget-ms", type=int, default=1500)

    args = parser.parse_args()
    if args.samples < 3:
        parser.error("--samples must be at least 3")
    return args


def main() -> int:
    args = parse_args()
    result = run_android(args) if args.platform == "android" else run_web(args)
    rendered = json.dumps(result, indent=2, sort_keys=True)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(f"{rendered}\n", encoding="utf-8")
    print(rendered)
    return 0 if result["result"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
