#!/usr/bin/env python3
"""Benchmark ManaLoom card-adjustment throughput.

The benchmark separates the work that should be bulk/automatic from the work
that still requires runtime-family implementation:

- local lookup planning for pasted decklist names;
- Scryfall Collection bulk lookup for Oracle identity/faces;
- Scryfall named fallback for hard names such as MDFC display names;
- local source/gate checks that should stay sub-second.

The default mode is deterministic and network-free for CI. Use `--live` for an
explicit operational measurement.
"""

from __future__ import annotations

import argparse
import gzip
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs/hermes-analysis/master_optimizer_reports"
PLANNER_PATH = REPO_ROOT / "server/bin/plan_oracle_text_backfill.py"
ACCELERATION_AUDIT_PATH = SCRIPT_DIR / "battle_card_acceleration_source_audit.py"
SCRYFALL_COLLECTION_URL = "https://api.scryfall.com/cards/collection"
SCRYFALL_BULK_ORACLE_URL = "https://api.scryfall.com/bulk-data/oracle-cards"
DEFAULT_BULK_CACHE_PATH = Path.home() / ".cache/manaloom/scryfall/oracle-cards.json"


DEFAULT_CARD_NAMES = (
    "Sol Ring",
    "Swords to Plowshares",
    "Path to Exile",
    "Blasphemous Act",
    "Spectator Seating",
    "Sunbillow Verge",
    "Ruby Medallion",
    "The Mind Stone",
    "Emeria's Call // Emeria, Shattered Skyclave",
    "Pinnacle Monk // Mystic Peak",
    "Witch Enchanter // Witch-Blessed Meadow",
    "Approach of the Second Sun",
    "Mizzix's Mastery",
    "Teferi's Protection",
    "High Noon",
)


@dataclass(frozen=True)
class TimedResult:
    id: str
    card_count: int
    elapsed_seconds: float
    success_count: int
    failure_count: int
    mode: str
    notes: str = ""
    details: Any = None

    @property
    def seconds_per_card(self) -> float:
        if self.card_count <= 0:
            return 0.0
        return self.elapsed_seconds / self.card_count

    @property
    def cards_per_second(self) -> float:
        if self.elapsed_seconds <= 0:
            return 0.0
        return self.card_count / self.elapsed_seconds

    def to_json(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "mode": self.mode,
            "card_count": self.card_count,
            "elapsed_seconds": round(self.elapsed_seconds, 6),
            "seconds_per_card": round(self.seconds_per_card, 6),
            "cards_per_second": round(self.cards_per_second, 3),
            "success_count": self.success_count,
            "failure_count": self.failure_count,
            "notes": self.notes,
            "details": self.details,
        }


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load_module(path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def load_planner():
    return load_module(PLANNER_PATH, "plan_oracle_text_backfill_for_throughput")


def load_acceleration_audit():
    return load_module(ACCELERATION_AUDIT_PATH, "battle_card_acceleration_source_audit_for_throughput")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--live", action="store_true", help="Run live Scryfall network probes.")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=20)
    parser.add_argument(
        "--bulk-cache-path",
        type=Path,
        default=DEFAULT_BULK_CACHE_PATH,
        help="Local Scryfall Oracle Cards cache path for the bulk-cache benchmark.",
    )
    parser.add_argument(
        "--refresh-bulk-cache",
        action="store_true",
        help="Refresh the local Oracle Cards cache before timing local lookup.",
    )
    return parser.parse_args()


def load_card_names(limit: int = 0) -> list[str]:
    names = list(DEFAULT_CARD_NAMES)
    if limit and limit > 0:
        return names[:limit]
    return names


def exact_collection_identifier_for_name(planner, name: str) -> dict[str, str]:
    attempts = planner.scryfall_lookup_attempts(name)
    preferred_strategies = (
        "exact_without_set_suffix",
        "exact_without_quantity",
        "exact_front_face",
        "exact_original",
    )
    for strategy in preferred_strategies:
        for attempt in attempts:
            if attempt["mode"] == "exact" and attempt["strategy"] == strategy:
                return {"name": attempt["query"]}
    for attempt in attempts:
        if attempt["mode"] == "exact":
            return {"name": attempt["query"]}
    return {"name": name}


def run_curl_collection(identifiers: list[dict[str, str]], timeout_seconds: int) -> dict[str, Any]:
    payload = {"identifiers": identifiers}
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".json", delete=False) as handle:
        json.dump(payload, handle, sort_keys=True)
        payload_path = Path(handle.name)
    try:
        result = subprocess.run(
            [
                "curl",
                "-sL",
                "--max-time",
                str(timeout_seconds),
                "-H",
                "Content-Type: application/json",
                "-H",
                "Accept: application/json",
                "-H",
                "User-Agent: ManaLoomCardThroughputBenchmark/1.0",
                "--data-binary",
                f"@{payload_path}",
                SCRYFALL_COLLECTION_URL,
            ],
            capture_output=True,
            text=True,
            timeout=timeout_seconds + 5,
            check=False,
        )
    finally:
        payload_path.unlink(missing_ok=True)
    if result.returncode != 0:
        return {"object": "error", "details": result.stderr.strip() or f"curl returned {result.returncode}"}
    try:
        decoded = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        return {"object": "error", "details": f"invalid JSON: {exc}"}
    return decoded if isinstance(decoded, dict) else {"object": "error", "details": "non-object response"}


def fetch_bulk_oracle_metadata(timeout_seconds: int) -> dict[str, Any]:
    result = subprocess.run(
        [
            "curl",
            "-fsSL",
            "--max-time",
            str(timeout_seconds),
            "-H",
            "Accept: application/json",
            "-H",
            "User-Agent: ManaLoomCardThroughputBenchmark/1.0",
            SCRYFALL_BULK_ORACLE_URL,
        ],
        capture_output=True,
        text=True,
        timeout=timeout_seconds + 5,
        check=False,
    )
    if result.returncode != 0:
        return {
            "object": "error",
            "details": result.stderr.strip() or f"curl returned {result.returncode}",
        }
    try:
        decoded = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        return {"object": "error", "details": f"invalid JSON: {exc}"}
    return decoded if isinstance(decoded, dict) else {"object": "error", "details": "non-object response"}


def refresh_bulk_oracle_cache(cache_path: Path, timeout_seconds: int) -> dict[str, Any]:
    metadata = fetch_bulk_oracle_metadata(timeout_seconds)
    download_uri = metadata.get("download_uri")
    if metadata.get("object") == "error" or not isinstance(download_uri, str):
        return {
            "ok": False,
            "metadata": metadata,
            "error": metadata.get("details") or "missing download_uri",
        }

    cache_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = cache_path.with_suffix(cache_path.suffix + ".tmp")
    result = subprocess.run(
        [
            "curl",
            "-fsSL",
            "--compressed",
            "--max-time",
            str(timeout_seconds),
            "-H",
            "Accept: application/json",
            "-H",
            "User-Agent: ManaLoomCardThroughputBenchmark/1.0",
            "-o",
            str(temp_path),
            download_uri,
        ],
        capture_output=True,
        text=True,
        timeout=timeout_seconds + 5,
        check=False,
    )
    if result.returncode != 0:
        temp_path.unlink(missing_ok=True)
        return {
            "ok": False,
            "metadata": metadata,
            "error": result.stderr.strip() or f"curl returned {result.returncode}",
        }
    os.replace(temp_path, cache_path)
    return {
        "ok": True,
        "metadata": metadata,
        "cache_path": str(cache_path),
        "cache_size_bytes": cache_path.stat().st_size,
    }


def load_bulk_cards(cache_path: Path) -> list[dict[str, Any]]:
    with cache_path.open("rb") as raw:
        prefix = raw.read(2)
    opener = gzip.open if prefix == b"\x1f\x8b" else open
    with opener(cache_path, "rt", encoding="utf-8") as handle:
        decoded = json.load(handle)
    if not isinstance(decoded, list):
        raise ValueError("Scryfall Oracle Cards cache must be a JSON list")
    return [item for item in decoded if isinstance(item, dict)]


def normalize_scryfall_name(value: str | None) -> str:
    return " ".join(str(value or "").strip().lower().split())


def index_bulk_cards(cards: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for card in cards:
        name_key = normalize_scryfall_name(card.get("name"))
        if name_key:
            index.setdefault(name_key, card)
        faces = card.get("card_faces")
        if isinstance(faces, list):
            for face in faces:
                if not isinstance(face, dict):
                    continue
                face_key = normalize_scryfall_name(face.get("name"))
                if face_key:
                    index.setdefault(face_key, card)
    return index


def benchmark_local_lookup_planning(planner, names: list[str]) -> TimedResult:
    start = time.perf_counter()
    attempts = {name: planner.scryfall_lookup_attempts(name) for name in names}
    elapsed = time.perf_counter() - start
    return TimedResult(
        id="local_lookup_attempt_planning",
        mode="local",
        card_count=len(names),
        elapsed_seconds=elapsed,
        success_count=len(names),
        failure_count=0,
        notes="Builds exact/fallback lookup attempts without network.",
        details={
            "max_attempts_for_one_card": max((len(value) for value in attempts.values()), default=0),
            "multiface_cards": [
                name for name, value in attempts.items()
                if any(item["strategy"] == "exact_front_face" for item in value)
            ],
        },
    )


def benchmark_source_gate(repo_root: Path) -> TimedResult:
    audit = load_acceleration_audit()
    start = time.perf_counter()
    report = audit.build_audit(repo_root)
    elapsed = time.perf_counter() - start
    covered = int(report["summary"]["status_counts"].get("covered", 0))
    gaps = int(report["summary"].get("gap_count", 0))
    return TimedResult(
        id="local_source_gate_audit",
        mode="local",
        card_count=int(report["summary"]["need_count"]),
        elapsed_seconds=elapsed,
        success_count=covered,
        failure_count=gaps,
        notes="Validates source strategy surfaces; measured by project need, not per-card.",
        details=report["summary"],
    )


def benchmark_collection(planner, names: list[str], *, live: bool, timeout_seconds: int) -> TimedResult:
    identifiers = [exact_collection_identifier_for_name(planner, name) for name in names]
    if not live:
        start = time.perf_counter()
        encoded = json.dumps({"identifiers": identifiers}, sort_keys=True)
        decoded = json.loads(encoded)
        elapsed = time.perf_counter() - start
        return TimedResult(
            id="scryfall_collection_bulk_oracle",
            mode="dry_run",
            card_count=len(names),
            elapsed_seconds=elapsed,
            success_count=len(decoded["identifiers"]),
            failure_count=0,
            notes="Dry-run encodes one Scryfall Collection batch; use --live for network measurement.",
            details={"batch_size": len(identifiers), "endpoint": SCRYFALL_COLLECTION_URL},
        )

    start = time.perf_counter()
    decoded = run_curl_collection(identifiers, timeout_seconds)
    elapsed = time.perf_counter() - start
    data = decoded.get("data") if isinstance(decoded.get("data"), list) else []
    not_found = decoded.get("not_found") if isinstance(decoded.get("not_found"), list) else []
    error = decoded.get("details") if decoded.get("object") == "error" else ""
    return TimedResult(
        id="scryfall_collection_bulk_oracle",
        mode="live",
        card_count=len(names),
        elapsed_seconds=elapsed,
        success_count=len(data),
        failure_count=len(not_found) + (1 if error else 0),
        notes="Live Scryfall Collection POST using exact normalized names; hard not_found names should use named fallback.",
        details={
            "endpoint": SCRYFALL_COLLECTION_URL,
            "resolved_names": [card.get("name") for card in data[:20] if isinstance(card, dict)],
            "not_found": not_found,
            "error": error,
        },
    )


def benchmark_bulk_cache_lookup(
    planner,
    names: list[str],
    *,
    live: bool,
    cache_path: Path,
    refresh_cache: bool,
    timeout_seconds: int,
) -> TimedResult:
    if not live:
        start = time.perf_counter()
        synthetic_cards = [
            {
                "name": name,
                "oracle_id": f"dry-run-{index}",
                "layout": "normal",
                "oracle_text": "",
            }
            for index, name in enumerate(names)
        ]
        index = index_bulk_cards(synthetic_cards)
        resolved = [
            name
            for name in names
            if any(
                normalize_scryfall_name(attempt["query"]) in index
                for attempt in planner.scryfall_lookup_attempts(name)
                if attempt["mode"] == "exact"
            )
        ]
        elapsed = time.perf_counter() - start
        return TimedResult(
            id="scryfall_bulk_cache_lookup",
            mode="dry_run",
            card_count=len(names),
            elapsed_seconds=elapsed,
            success_count=len(resolved),
            failure_count=len(names) - len(resolved),
            notes="Dry-run indexes synthetic Oracle Cards cache; use --live for real cache throughput.",
            details={
                "cache_path": str(cache_path),
                "index_size": len(index),
                "refresh_cache": refresh_cache,
            },
        )

    refresh_details: dict[str, Any] | None = None
    download_elapsed = 0.0
    if refresh_cache or not cache_path.exists():
        download_start = time.perf_counter()
        refresh_details = refresh_bulk_oracle_cache(cache_path, timeout_seconds)
        download_elapsed = time.perf_counter() - download_start
        if not refresh_details.get("ok"):
            return TimedResult(
                id="scryfall_bulk_cache_lookup",
                mode="live",
                card_count=len(names),
                elapsed_seconds=download_elapsed,
                success_count=0,
                failure_count=len(names),
                notes="Unable to refresh local Scryfall Oracle Cards cache.",
                details=refresh_details,
            )

    load_start = time.perf_counter()
    cards = load_bulk_cards(cache_path)
    index = index_bulk_cards(cards)
    load_elapsed = time.perf_counter() - load_start

    lookup_start = time.perf_counter()
    resolved: list[dict[str, Any]] = []
    missing: list[str] = []
    for name in names:
        match = None
        for attempt in planner.scryfall_lookup_attempts(name):
            if attempt["mode"] != "exact":
                continue
            match = index.get(normalize_scryfall_name(attempt["query"]))
            if match:
                break
        if match:
            resolved.append(
                {
                    "input_name": name,
                    "resolved_name": match.get("name"),
                    "oracle_id": match.get("oracle_id"),
                    "layout": match.get("layout"),
                    "card_faces_present": isinstance(match.get("card_faces"), list),
                }
            )
        else:
            missing.append(name)
    lookup_elapsed = time.perf_counter() - lookup_start

    return TimedResult(
        id="scryfall_bulk_cache_lookup",
        mode="live",
        card_count=len(names),
        elapsed_seconds=lookup_elapsed,
        success_count=len(resolved),
        failure_count=len(missing),
        notes="Local Scryfall Oracle Cards cache lookup after one-time cache load/index.",
        details={
            "cache_path": str(cache_path),
            "cache_exists": cache_path.exists(),
            "cache_size_bytes": cache_path.stat().st_size if cache_path.exists() else 0,
            "download_elapsed_seconds": round(download_elapsed, 6),
            "load_and_index_elapsed_seconds": round(load_elapsed, 6),
            "bulk_card_count": len(cards),
            "index_size": len(index),
            "refreshed": bool(refresh_details),
            "bulk_updated_at": (refresh_details or {}).get("metadata", {}).get("updated_at"),
            "bulk_source_size_bytes": (refresh_details or {}).get("metadata", {}).get("size"),
            "resolved": resolved[:20],
            "missing": missing,
        },
    )


def benchmark_named_fallback(planner, names: list[str], *, live: bool, timeout_seconds: int) -> TimedResult:
    hard_names = [
        name for name in names
        if "//" in name or "(" in name or name.startswith("1 ")
    ]
    if not hard_names:
        hard_names = names[: min(3, len(names))]
    if not live:
        start = time.perf_counter()
        attempts = [planner.scryfall_lookup_attempts(name) for name in hard_names]
        elapsed = time.perf_counter() - start
        return TimedResult(
            id="scryfall_named_hard_fallback",
            mode="dry_run",
            card_count=len(hard_names),
            elapsed_seconds=elapsed,
            success_count=len(hard_names),
            failure_count=0,
            notes="Dry-run builds named fallback attempts for hard names.",
            details={"hard_names": hard_names, "attempt_counts": [len(item) for item in attempts]},
        )

    results: list[dict[str, Any]] = []
    start = time.perf_counter()
    for name in hard_names:
        result = planner.fetch_scryfall_best_match(name, timeout_seconds)
        results.append(
            {
                "input_name": name,
                "found": bool(result.get("found")),
                "resolved_name": result.get("name"),
                "layout": result.get("layout"),
                "card_faces_present": result.get("card_faces_present"),
                "lookup_strategy": result.get("lookup_strategy"),
                "lookup_mode": result.get("lookup_mode"),
                "lookup_query": result.get("lookup_query"),
            }
        )
    elapsed = time.perf_counter() - start
    success = sum(1 for item in results if item["found"])
    return TimedResult(
        id="scryfall_named_hard_fallback",
        mode="live",
        card_count=len(hard_names),
        elapsed_seconds=elapsed,
        success_count=success,
        failure_count=len(hard_names) - success,
        notes="Live named fallback for MDFC/hard pasted names.",
        details={"results": results},
    )


def classify_throughput(results: list[TimedResult]) -> dict[str, Any]:
    by_id = {item.id: item for item in results}
    collection = by_id.get("scryfall_collection_bulk_oracle")
    bulk_cache = by_id.get("scryfall_bulk_cache_lookup")
    named = by_id.get("scryfall_named_hard_fallback")
    local = by_id.get("local_lookup_attempt_planning")

    estimates: dict[str, Any] = {}
    if collection:
        estimates["oracle_bulk_seconds_per_card"] = round(collection.seconds_per_card, 4)
        estimates["oracle_bulk_cards_per_minute"] = round(collection.cards_per_second * 60, 1)
    if bulk_cache:
        estimates["bulk_cache_lookup_seconds_per_card"] = round(bulk_cache.seconds_per_card, 6)
        estimates["bulk_cache_lookup_cards_per_minute"] = round(bulk_cache.cards_per_second * 60, 1)
        load_elapsed = ((bulk_cache.details or {}) if isinstance(bulk_cache.details, dict) else {}).get(
            "load_and_index_elapsed_seconds"
        )
        if load_elapsed is not None:
            estimates["bulk_cache_load_and_index_seconds"] = load_elapsed
    if named:
        estimates["hard_named_fallback_seconds_per_card"] = round(named.seconds_per_card, 4)
        estimates["hard_named_fallback_cards_per_minute"] = round(named.cards_per_second * 60, 1)
    if local:
        estimates["local_planning_seconds_per_card"] = round(local.seconds_per_card, 6)

    verdict = "pass"
    recommendations: list[str] = []
    if collection and collection.mode == "live" and collection.seconds_per_card > 0.25:
        verdict = "review"
        recommendations.append("Prefer cached Scryfall bulk files or larger collection batches; live collection is above 0.25s/card.")
    if (
        bulk_cache
        and bulk_cache.mode == "live"
        and bulk_cache.failure_count == 0
        and collection
        and collection.mode == "live"
        and bulk_cache.seconds_per_card < collection.seconds_per_card
    ):
        recommendations.append("Use local Scryfall Oracle Cards cache for mass Oracle backfills; reserve live Collection/named calls for cache refresh and unresolved misses.")
    if bulk_cache and bulk_cache.failure_count:
        recommendations.append("Normalize unresolved cache misses through exact front-face lookup before using fuzzy or manual review.")
    if named and named.mode == "live" and named.seconds_per_card > 2.0:
        verdict = "review"
        recommendations.append("Reduce named fallback use by pre-normalizing MDFC/front-face names and backfilling oracle_id/layout first.")
    if collection and collection.failure_count:
        recommendations.append("Route collection not_found rows through exact/front-face named fallback, then queue true misses for manual review.")
    if not recommendations:
        recommendations.append("Keep Oracle work batched; spend human time only on runtime-family gaps and conflict review.")

    return {
        "verdict": verdict,
        "estimates": estimates,
        "recommendations": recommendations,
    }


def build_report(
    *,
    live: bool,
    limit: int,
    timeout_seconds: int,
    bulk_cache_path: Path = DEFAULT_BULK_CACHE_PATH,
    refresh_bulk_cache: bool = False,
) -> dict[str, Any]:
    planner = load_planner()
    names = load_card_names(limit)
    results = [
        benchmark_local_lookup_planning(planner, names),
        benchmark_collection(planner, names, live=live, timeout_seconds=timeout_seconds),
        benchmark_bulk_cache_lookup(
            planner,
            names,
            live=live,
            cache_path=bulk_cache_path,
            refresh_cache=refresh_bulk_cache,
            timeout_seconds=timeout_seconds,
        ),
        benchmark_named_fallback(planner, names, live=live, timeout_seconds=timeout_seconds),
        benchmark_source_gate(REPO_ROOT),
    ]
    return {
        "generated_at_utc": utc_now(),
        "mode": "live" if live else "dry_run",
        "postgres_writes": False,
        "sample_card_count": len(names),
        "sample_cards": names,
        "benchmarks": [item.to_json() for item in results],
        "throughput": classify_throughput(results),
        "source_method": {
            "oracle_bulk": "Scryfall Collection/bulk for identity, layout, faces, legalities; MTGJSON for bulk rulings/legalities.",
            "oracle_bulk_cache": "Local Scryfall Oracle Cards cache for mass identity/text/layout lookup after one-time refresh.",
            "hard_fallback": "Scryfall named exact/front-face/fuzzy-last for pasted MDFC or unresolved display names.",
            "battle_runtime": "XMage/Forge/Wizards rules by semantic family, then ManaLoom focused tests.",
            "deckbuilding": "Commander Spellbook/EDHREC/reference corpus as aggregate signals, not raw rule truth.",
        },
    }


def render_markdown(report: dict[str, Any]) -> str:
    throughput = report["throughput"]
    lines = [
        "# Card Adjustment Throughput Benchmark",
        "",
        f"- Generated UTC: `{report['generated_at_utc']}`",
        f"- Mode: `{report['mode']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        f"- Sample cards: `{report['sample_card_count']}`",
        f"- Verdict: `{throughput['verdict']}`",
        "",
        "## Benchmarks",
        "",
        "| Benchmark | Mode | Cards | Seconds | Sec/card | Cards/min | Success | Fail |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for item in report["benchmarks"]:
        lines.append(
            "| `{id}` | `{mode}` | `{card_count}` | `{elapsed_seconds}` | `{seconds_per_card}` | `{cards_per_min}` | `{success_count}` | `{failure_count}` |".format(
                cards_per_min=round(float(item["cards_per_second"]) * 60, 1),
                **item,
            )
        )
    lines.extend(["", "## Estimates", ""])
    for key, value in throughput["estimates"].items():
        lines.append(f"- `{key}`: `{value}`")
    lines.extend(["", "## Recommendations", ""])
    for recommendation in throughput["recommendations"]:
        lines.append(f"- {recommendation}")
    lines.extend(["", "## Sample Cards", ""])
    for name in report["sample_cards"]:
        lines.append(f"- {name}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    report = build_report(
        live=args.live,
        limit=args.limit,
        timeout_seconds=args.timeout_seconds,
        bulk_cache_path=args.bulk_cache_path,
        refresh_bulk_cache=args.refresh_bulk_cache,
    )
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    markdown = render_markdown(report)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
