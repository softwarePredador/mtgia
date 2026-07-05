#!/usr/bin/env python3
"""Resolve missing external Lorehold identities through Scryfall without apply.

This report-only artifact consumes the identity/import preflight queue, fetches
the missing Oracle identities from Scryfall, and classifies whether each card is
ready for a later cache import. It does not write SQLite and it does not make a
deck candidate battle-ready.
"""

from __future__ import annotations

import argparse
import json
import ssl
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import normalize_name

try:
    import certifi
except Exception:  # pragma: no cover - optional local TLS helper.
    certifi = None


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_PREFLIGHT_REPORT = REPORT_DIR / "lorehold_external_candidate_identity_import_preflight_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_external_identity_resolution_queue_20260705_current"
SCRYFALL_NAMED_URL = "https://api.scryfall.com/cards/named"
LOREHOLD_COLOR_IDENTITY = {"R", "W"}


def tls_context() -> ssl.SSLContext:
    if certifi is not None:
        return ssl.create_default_context(cafile=certifi.where())
    return ssl.create_default_context()


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def preflight_identity_rows(preflight_report: Mapping[str, Any]) -> list[dict[str, Any]]:
    wanted = set(as_list((preflight_report.get("queues") or {}).get("identity_import_required")))
    rows = []
    for row in as_list(preflight_report.get("preflight_rows")):
        if not isinstance(row, Mapping):
            continue
        if row.get("card_name") in wanted:
            rows.append(dict(row))
    return sorted(rows, key=lambda row: normalize_name(str(row.get("card_name") or "")))


def fetch_scryfall_exact(card_name: str, *, timeout: int = 20) -> dict[str, Any]:
    query = urllib.parse.urlencode({"exact": card_name})
    url = f"{SCRYFALL_NAMED_URL}?{query}"
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "ManaLoomDeckLearning/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout, context=tls_context()) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        try:
            error_payload = json.loads(exc.read().decode("utf-8"))
        except Exception:
            error_payload = {"details": str(exc)}
        return {
            "lookup_status": "not_found",
            "http_status": exc.code,
            "name": card_name,
            "details": error_payload.get("details"),
            "scryfall_api_url": url,
        }
    except Exception as exc:
        return {
            "lookup_status": "error",
            "name": card_name,
            "details": str(exc),
            "scryfall_api_url": url,
        }
    return {
        "lookup_status": "found",
        "name": payload.get("name"),
        "oracle_id": payload.get("oracle_id"),
        "scryfall_id": payload.get("id"),
        "mana_cost": payload.get("mana_cost"),
        "cmc": payload.get("cmc"),
        "type_line": payload.get("type_line"),
        "oracle_text": payload.get("oracle_text"),
        "colors": payload.get("colors") or [],
        "color_identity": payload.get("color_identity") or [],
        "keywords": payload.get("keywords") or [],
        "legalities": {"commander": (payload.get("legalities") or {}).get("commander")},
        "scryfall_uri": payload.get("scryfall_uri"),
        "scryfall_api_url": url,
    }


def compact_lookup(card_name: str, lookup: Mapping[str, Any]) -> dict[str, Any]:
    if lookup.get("lookup_status") != "found":
        return dict(lookup)
    return {
        "lookup_status": "found",
        "name": lookup.get("name") or card_name,
        "oracle_id": lookup.get("oracle_id"),
        "scryfall_id": lookup.get("scryfall_id"),
        "mana_cost": lookup.get("mana_cost"),
        "cmc": lookup.get("cmc"),
        "type_line": lookup.get("type_line"),
        "oracle_text": lookup.get("oracle_text"),
        "colors": as_list(lookup.get("colors")),
        "color_identity": as_list(lookup.get("color_identity")),
        "keywords": as_list(lookup.get("keywords")),
        "legalities": dict(lookup.get("legalities") or {}),
        "scryfall_uri": lookup.get("scryfall_uri"),
        "scryfall_api_url": lookup.get("scryfall_api_url"),
    }


def build_resolution_row(preflight_row: Mapping[str, Any], lookup: Mapping[str, Any]) -> dict[str, Any]:
    card_name = str(preflight_row.get("card_name") or lookup.get("name") or "")
    lookup_status = str(lookup.get("lookup_status") or "missing_lookup")
    commander_status = (lookup.get("legalities") or {}).get("commander")
    color_identity = set(as_list(lookup.get("color_identity")))
    color_compatible = lookup_status == "found" and color_identity.issubset(LOREHOLD_COLOR_IDENTITY)
    commander_legal = lookup_status == "found" and commander_status == "legal"
    route_types = as_list(preflight_row.get("route_types"))
    cache_insert_ready = lookup_status == "found" and commander_legal and color_compatible
    blockers: list[str] = []
    if lookup_status != "found":
        blockers.append("scryfall_identity_not_resolved")
    if lookup_status == "found" and not commander_legal:
        blockers.append("scryfall_commander_not_legal")
    if lookup_status == "found" and not color_compatible:
        blockers.append("not_lorehold_color_identity_compatible")
    if cache_insert_ready:
        if "combo_package" in route_types:
            post_import_status = "identity_ready_then_combo_runtime_and_cut_safety_required"
            blockers.append("combo_runtime_and_cut_safety_still_required")
        elif "archetype_fork" in route_types:
            post_import_status = "identity_ready_then_shell_contract_required"
            blockers.append("full_shell_contract_still_required")
        else:
            post_import_status = "identity_ready_then_runtime_or_cut_safety_required"
            blockers.append("runtime_or_cut_safety_still_required")
    else:
        post_import_status = "identity_resolution_blocked"
    return {
        "card_name": card_name,
        "source_preflight_status": preflight_row.get("preflight_status"),
        "route_types": route_types,
        "lookup": compact_lookup(card_name, lookup),
        "scryfall_lookup_status": lookup_status,
        "commander_legal": commander_legal,
        "lorehold_color_identity_compatible": color_compatible,
        "cache_insert_ready": cache_insert_ready,
        "post_import_status": post_import_status,
        "deck_test_allowed_after_identity": False,
        "blockers": blockers,
    }


def build_payload(
    *,
    preflight_report: Mapping[str, Any],
    preflight_path: Path,
    scryfall_lookups: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    rows = [
        build_resolution_row(row, scryfall_lookups.get(str(row["card_name"]), {"lookup_status": "missing_lookup"}))
        for row in preflight_identity_rows(preflight_report)
    ]
    status = "external_identity_resolution_ready_for_apply_plan_keep_607"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_external_identity_resolution_queue",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "apply_sqlite_allowed_now": False,
        "source_reports": {"identity_import_preflight": rel(preflight_path)},
        "status": status,
        "summary": {
            "current_baseline": "deck_607",
            "identity_queue_count": len(rows),
            "scryfall_found_count": sum(1 for row in rows if row["scryfall_lookup_status"] == "found"),
            "commander_legal_count": sum(1 for row in rows if row["commander_legal"]),
            "lorehold_color_identity_compatible_count": sum(
                1 for row in rows if row["lorehold_color_identity_compatible"]
            ),
            "cache_insert_ready_count": sum(1 for row in rows if row["cache_insert_ready"]),
            "deck_test_ready_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "recommended_next_action": "prepare_reviewed_sqlite_identity_cache_apply_package_without_deck_mutation",
        },
        "resolution_rows": rows,
        "queues": {
            "cache_insert_ready": [row["card_name"] for row in rows if row["cache_insert_ready"]],
            "combo_runtime_after_identity": [
                row["card_name"]
                for row in rows
                if row["post_import_status"] == "identity_ready_then_combo_runtime_and_cut_safety_required"
            ],
            "shell_contract_after_identity": [
                row["card_name"]
                for row in rows
                if row["post_import_status"] == "identity_ready_then_shell_contract_required"
            ],
            "runtime_or_cut_safety_after_identity": [
                row["card_name"]
                for row in rows
                if row["post_import_status"] == "identity_ready_then_runtime_or_cut_safety_required"
            ],
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "prepare reviewed SQLite identity cache apply package if local cache should be updated",
                "after identity cache update, rerun identity/import preflight",
                "route Haze of Rage to combo runtime only after identity exists locally",
                "keep archetype-fork cards out of one-for-one 607 cut gates",
            ],
            "reason": (
                "The missing identity queue can be resolved externally, but this "
                "report intentionally does not apply cache rows and no card becomes "
                "battle- or promotion-ready from identity alone."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold External Identity Resolution Queue",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- Deck 607 mutated: `{payload['deck_607_mutated']}`",
        f"- SQLite apply allowed now: `{payload['apply_sqlite_allowed_now']}`",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in [
        "identity_queue_count",
        "scryfall_found_count",
        "commander_legal_count",
        "lorehold_color_identity_compatible_count",
        "cache_insert_ready_count",
        "deck_test_ready_count",
    ]:
        lines.append(f"| `{key}` | `{summary[key]}` |")
    lines.extend(
        [
            "",
            "## Resolution Rows",
            "",
            "| Card | Lookup | Commander | Color Fit | Cache Ready | Post-Import Status |",
            "| --- | --- | ---: | ---: | ---: | --- |",
        ]
    )
    for row in payload["resolution_rows"]:
        lines.append(
            f"| {row['card_name']} | `{row['scryfall_lookup_status']}` | "
            f"`{row['commander_legal']}` | `{row['lorehold_color_identity_compatible']}` | "
            f"`{row['cache_insert_ready']}` | `{row['post_import_status']}` |"
        )
    lines.extend(["", "## Queues", ""])
    for queue_name, cards in payload["queues"].items():
        card_list = ", ".join(cards) if cards else "-"
        lines.append(f"- `{queue_name}`: {card_list}")
    decision = payload["decision"]
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{decision['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{decision['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{decision['promotion_allowed']}`",
            f"- Reason: {decision['reason']}",
            "",
            "## Next Actions",
            "",
        ]
    )
    for action in decision["next_actions"]:
        lines.append(f"- {action}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preflight-report", type=Path, default=DEFAULT_PREFLIGHT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--lookup-cache", type=Path)
    parser.add_argument("--request-delay-seconds", type=float, default=0.12)
    args = parser.parse_args()
    preflight_report = read_json(args.preflight_report)

    cached = read_json(args.lookup_cache) if args.lookup_cache else {}
    lookups: dict[str, dict[str, Any]] = {}
    for row in preflight_identity_rows(preflight_report):
        card_name = str(row["card_name"])
        if card_name in cached:
            lookups[card_name] = dict(cached[card_name])
            continue
        lookups[card_name] = fetch_scryfall_exact(card_name)
        if args.request_delay_seconds > 0:
            time.sleep(args.request_delay_seconds)

    payload = build_payload(
        preflight_report=preflight_report,
        preflight_path=args.preflight_report,
        scryfall_lookups=lookups,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "cache_insert_ready_count": payload["summary"]["cache_insert_ready_count"],
                "promotion_allowed": payload["summary"]["promotion_allowed"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
