#!/usr/bin/env python3
"""Build one deterministic XMage -> Forge -> native card coverage ledger.

The ledger is deliberately report-only. It does not promote rules, mutate
PostgreSQL, or teach the deckbuilder from catalog presence. Its purpose is to
turn global coverage into a reproducible queue with an explicit residual.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
import urllib.error
import urllib.request
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


SCHEMA_VERSION = "external_card_coverage_closure_v1"
ENGINE_ORDER = ("xmage", "forge", "native")


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_name(value: Any) -> str:
    text = unicodedata.normalize("NFKC", str(value or "")).strip().casefold()
    text = text.replace("\u2018", "'").replace("\u2019", "'")
    text = text.replace("\u2013", "-").replace("\u2014", "-")
    return re.sub(r"\s+", " ", text)


def card_key(row: Mapping[str, Any], index: int) -> str:
    for field in ("card_id", "id", "oracle_id"):
        value = str(row.get(field) or "").strip()
        if value:
            return f"{field}:{value}"
    return f"name:{normalize_name(row.get('name'))}:{index}"


def reconciliation_candidates(row: Mapping[str, Any]) -> list[str]:
    name = unicodedata.normalize("NFKC", str(row.get("name") or "")).strip()
    candidates: list[str] = []
    faces = row.get("card_faces") or row.get("card_faces_json") or []
    if isinstance(faces, str):
        try:
            faces = json.loads(faces)
        except json.JSONDecodeError:
            faces = []
    if isinstance(faces, list):
        candidates.extend(
            str(face.get("name") or "").strip()
            for face in faces
            if isinstance(face, Mapping)
        )
    for separator in (" // ", " / "):
        if separator in name:
            candidates.append(name.split(separator, 1)[0].strip())
    punctuation = (
        name.replace("\u2018", "'")
        .replace("\u2019", "'")
        .replace("\u2013", "-")
        .replace("\u2014", "-")
    )
    candidates.append(punctuation)
    result: list[str] = []
    seen = {normalize_name(name)}
    for candidate in candidates:
        if not candidate:
            continue
        normalized = normalize_name(candidate)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        result.append(candidate)
    return result


def residual_family(row: Mapping[str, Any]) -> str:
    name = str(row.get("name") or "")
    layout = normalize_name(row.get("layout")) or "unknown"
    oracle_text = str(row.get("oracle_text") or "").strip()
    if " // " in name or layout in {
        "adventure",
        "battle",
        "double_faced_token",
        "modal_dfc",
        "reversible_card",
        "split",
        "transform",
    }:
        return f"multiface_or_special_layout::{layout}"
    if not oracle_text:
        return f"missing_oracle_or_nonstandard_object::{layout}"
    return f"engine_catalog_gap::{layout}"


def residual_family_next_gate(family: str) -> str:
    if family == "product_identity_or_nonstandard_object":
        return "product_identity_and_oracle_review"
    if family.startswith("multiface_or_special_layout::"):
        return "identity_bridge_runtime_test_then_catalog_recheck"
    if family.startswith("missing_oracle_or_nonstandard_object::"):
        return "product_identity_and_oracle_review"
    return "engine_update_or_native_family_adapter_gate"


def residual_semantic_family(row: Mapping[str, Any]) -> str:
    oracle = normalize_name(row.get("oracle_text"))
    type_line = normalize_name(row.get("type_line"))
    if not oracle:
        return "product_identity_or_nonstandard_object"
    checks = (
        ("token_creation", ("create", "token")),
        ("tutor_search_library", ("search your library",)),
        ("counterspell_or_stack", ("counter target",)),
        ("mana_generation_or_cost", ("add {", "costs ", "cost less")),
        ("targeted_or_mass_removal", ("destroy", "exile target", "sacrifice")),
        ("damage_or_life", ("deals ", "damage", "life total", "gain life")),
        ("draw_selection_topdeck", ("draw ", "scry", "surveil", "top card")),
        ("graveyard_recursion", ("from your graveyard", "return target card")),
        ("copy_or_alternate_cast", ("copy target", "cast without paying", "play the top")),
    )
    for family, markers in checks:
        if any(marker in oracle for marker in markers):
            return family
    if "creature" in type_line:
        return "creature_combat_or_ability"
    if any(marker in oracle for marker in ("whenever", "at the beginning", "instead", "can't", "as long as")):
        return "triggered_static_or_replacement"
    return "other_long_tail"


def residual_execution_scope(row: Mapping[str, Any]) -> str:
    oracle = normalize_name(row.get("oracle_text"))
    type_line = normalize_name(row.get("type_line"))
    layout = normalize_name(row.get("layout"))
    set_type = normalize_name(row.get("set_type"))
    set_code = normalize_name(row.get("set_code"))
    commander_legality = normalize_name(row.get("commander_legality"))
    online_only = row.get("is_online_only") is True or normalize_name(
        row.get("is_online_only")
    ) in {"1", "true", "yes"}
    if online_only or set_type == "alchemy":
        return "digital_only_ruleset"
    if layout in {"double_faced_token", "emblem", "token"} or any(
        marker in type_line
        for marker in (
            "attraction",
            "contraption",
            "conspiracy",
            "dungeon",
            "phenomenon",
            "plane",
            "scheme",
            "stickers",
            "token",
        )
    ):
        return "auxiliary_game_object"
    if set_type == "memorabilia" or set_code in {
        "pssc",
        "tbth",
        "tdag",
        "tfth",
        "thp1",
        "thp2",
        "thp3",
    }:
        return "scenario_or_challenge_deck_ruleset"
    if any(
        marker in oracle
        for marker in (
            "a person outside the game",
            "ask a person",
            "artist credit",
            "booster pack",
            "from outside the game",
            "in its art",
            "looking directly",
            "physical",
            "target drink",
            "your age",
            "you speak",
            "a toy you own",
            "you own from outside",
        )
    ):
        return "physical_or_external_interaction"
    # Unfinity mixes acorn and Eternal-legal cards in the same funny set. Only
    # its normal Commander-legal cards may cross this product-level boundary;
    # other funny/playtest products stay excluded even if imported legalities
    # contain a name-collision false positive.
    if set_code == "unf" and commander_legality == "legal" and oracle:
        return "conventional_magic_rules"
    if set_type == "funny" or set_code in {
        "cmb1",
        "hho",
        "j17",
        "mb2",
        "olep",
        "p30m",
        "pal04",
        "pcel",
        "pf24",
        "pf25",
        "pf26",
        "punk",
        "ugl",
        "und",
        "unf",
        "unh",
        "unk",
        "ust",
    }:
        return "nonstandard_or_playtest_ruleset"
    if not oracle:
        return "missing_oracle_or_product_identity"
    return "conventional_magic_rules"


@dataclass(frozen=True)
class HttpResult:
    status: int
    body: dict[str, Any]


class JsonHttpClient:
    def post(self, url: str, payload: Mapping[str, Any], timeout: float) -> HttpResult:
        request = urllib.request.Request(
            url,
            data=json.dumps(payload, ensure_ascii=True, separators=(",", ":")).encode("utf-8"),
            headers={"content-type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return HttpResult(response.status, _decode_json(response.read()))
        except urllib.error.HTTPError as error:
            return HttpResult(error.code, _decode_json(error.read()))


def _decode_json(raw: bytes) -> dict[str, Any]:
    try:
        value = json.loads(raw.decode("utf-8", errors="replace"))
    except json.JSONDecodeError as error:
        raise RuntimeError("sidecar returned non-JSON content") from error
    if not isinstance(value, dict):
        raise RuntimeError("sidecar returned a non-object JSON payload")
    return value


def _chunks(values: Sequence[dict[str, Any]], size: int) -> Iterable[tuple[int, Sequence[dict[str, Any]]]]:
    for offset in range(0, len(values), size):
        yield offset, values[offset : offset + size]


def _coverage(
    rows: Sequence[dict[str, Any]],
    *,
    base_url: str,
    batch_size: int,
    timeout: float,
    client: JsonHttpClient,
) -> tuple[set[int], dict[str, Any]]:
    unsupported: set[int] = set()
    engine_metadata: dict[str, Any] = {}
    for offset, batch in _chunks(list(rows), batch_size):
        payload_rows = []
        for local_index, row in enumerate(batch):
            payload_rows.append(
                {
                    "name": row["name"],
                    "card_id": row["_key"],
                    "set_code": row.get("set_code"),
                    "collector_number": row.get("collector_number"),
                    "quantity": 1,
                }
            )
        response = client.post(
            f"{base_url.rstrip('/')}/cards/coverage",
            {"cards": payload_rows},
            timeout,
        )
        if response.status != 200:
            raise RuntimeError(
                f"coverage request failed status={response.status} body={response.body}"
            )
        engine_metadata = {
            key: response.body.get(key)
            for key in ("engine", "engine_version", "engine_commit")
            if response.body.get(key) is not None
        }
        unsupported_rows = response.body.get("unsupported_cards") or []
        if not isinstance(unsupported_rows, list):
            raise RuntimeError("coverage response unsupported_cards must be a list")
        reported_total = response.body.get("total")
        reported_supported = response.body.get("supported")
        reported_unsupported = response.body.get("unsupported")
        if (
            reported_total != len(batch)
            or not isinstance(reported_supported, int)
            or reported_unsupported != len(unsupported_rows)
            or reported_supported + reported_unsupported != reported_total
        ):
            raise RuntimeError(
                "coverage response counts do not reconcile "
                f"batch={len(batch)} body={response.body}"
            )
        seen_local_indexes: set[int] = set()
        for item in unsupported_rows:
            if not isinstance(item, Mapping):
                raise RuntimeError("coverage response contains a non-object unsupported row")
            local_index = item.get("input_index")
            if (
                not isinstance(local_index, int)
                or local_index < 0
                or local_index >= len(batch)
                or local_index in seen_local_indexes
            ):
                raise RuntimeError(
                    f"coverage response has invalid input_index={local_index!r}"
                )
            seen_local_indexes.add(local_index)
            unsupported.add(offset + local_index)
    return unsupported, engine_metadata


def _supported_aliases(
    rows: Sequence[dict[str, Any]],
    *,
    base_url: str,
    batch_size: int,
    timeout: float,
    client: JsonHttpClient,
) -> dict[str, str]:
    aliases: list[dict[str, Any]] = []
    alias_owner: dict[str, tuple[str, str]] = {}
    for row in rows:
        for rank, candidate in enumerate(reconciliation_candidates(row)):
            alias_key = f"{row['_key']}::alias:{rank}"
            aliases.append({"_key": alias_key, "name": candidate})
            alias_owner[alias_key] = (row["_key"], candidate)
    if not aliases:
        return {}
    unsupported, _metadata = _coverage(
        aliases,
        base_url=base_url,
        batch_size=batch_size,
        timeout=timeout,
        client=client,
    )
    result: dict[str, str] = {}
    for index, alias in enumerate(aliases):
        if index in unsupported:
            continue
        owner, candidate = alias_owner[alias["_key"]]
        result.setdefault(owner, candidate)
    return result


def _native_names(payload: Any) -> set[str]:
    if isinstance(payload, Mapping):
        payload = payload.get("cards") or payload.get("names") or payload.get("rows") or []
    result: set[str] = set()
    if not isinstance(payload, list):
        return result
    for item in payload:
        name = item.get("name") if isinstance(item, Mapping) else item
        normalized = normalize_name(name)
        if normalized:
            result.add(normalized)
    return result


def build_closure(
    cards: Sequence[Mapping[str, Any]],
    *,
    xmage_url: str,
    forge_url: str,
    native_names: set[str] | None = None,
    batch_size: int = 20_000,
    timeout: float = 30.0,
    client: JsonHttpClient | None = None,
) -> dict[str, Any]:
    http = client or JsonHttpClient()
    native = native_names or set()
    rows: list[dict[str, Any]] = []
    keys: set[str] = set()
    for index, raw in enumerate(cards):
        name = str(raw.get("name") or "").strip()
        if not name:
            raise ValueError(f"card at input index {index} has no name")
        row = dict(raw)
        row["name"] = name
        row["_key"] = card_key(row, index)
        if row["_key"] in keys:
            raise ValueError(f"duplicate card key: {row['_key']}")
        keys.add(row["_key"])
        rows.append(row)

    xmage_unsupported, xmage_metadata = _coverage(
        rows,
        base_url=xmage_url,
        batch_size=batch_size,
        timeout=timeout,
        client=http,
    )
    xmage_residual = [rows[index] for index in sorted(xmage_unsupported)]
    forge_unsupported_local, forge_metadata = _coverage(
        xmage_residual,
        base_url=forge_url,
        batch_size=batch_size,
        timeout=timeout,
        client=http,
    ) if xmage_residual else (set(), {})
    forge_unsupported_keys = {
        xmage_residual[index]["_key"] for index in forge_unsupported_local
    }
    unresolved_exact = [
        row for row in xmage_residual if row["_key"] in forge_unsupported_keys
    ]
    xmage_aliases = _supported_aliases(
        unresolved_exact,
        base_url=xmage_url,
        batch_size=batch_size,
        timeout=timeout,
        client=http,
    )
    forge_aliases = _supported_aliases(
        [row for row in unresolved_exact if row["_key"] not in xmage_aliases],
        base_url=forge_url,
        batch_size=batch_size,
        timeout=timeout,
        client=http,
    )

    ledger: list[dict[str, Any]] = []
    xmage_unsupported_keys = {rows[index]["_key"] for index in xmage_unsupported}
    for row in rows:
        key = row["_key"]
        normalized = normalize_name(row["name"])
        engine_name: str | None = None
        if key not in xmage_unsupported_keys:
            lane = "xmage_exact"
        elif key not in forge_unsupported_keys:
            lane = "forge_exact"
        elif normalized in native:
            lane = "native_verified"
        elif key in xmage_aliases:
            lane = "identity_reconciliation_required"
            engine_name = xmage_aliases[key]
        elif key in forge_aliases:
            lane = "identity_reconciliation_required"
            engine_name = forge_aliases[key]
        else:
            lane = "unresolved"
        covered = lane in {"xmage_exact", "forge_exact", "native_verified"}
        ledger_row = {
            "key": key,
            "card_id": row.get("card_id") or row.get("id"),
            "oracle_id": row.get("oracle_id"),
            "name": row["name"],
            "layout": row.get("layout"),
            "lane": lane,
            "covered": covered,
            "engine_name_candidate": engine_name,
            "residual_family": None if covered else residual_family(row),
            "residual_semantic_family": None
            if covered
            else residual_semantic_family(row),
            "residual_execution_scope": None
            if covered
            else residual_execution_scope(row),
        }
        if not covered:
            ledger_row.update(
                {
                    "set_code": row.get("set_code"),
                    "collector_number": row.get("collector_number"),
                    "set_type": row.get("set_type"),
                    "is_online_only": row.get("is_online_only"),
                    "commander_legality": row.get("commander_legality"),
                    "type_line": row.get("type_line"),
                    "oracle_text": row.get("oracle_text"),
                }
            )
        ledger.append(ledger_row)

    lane_counts = Counter(row["lane"] for row in ledger)
    family_counts = Counter(
        row["residual_family"] for row in ledger if row.get("residual_family")
    )
    semantic_family_counts = Counter(
        row["residual_semantic_family"]
        for row in ledger
        if row.get("residual_semantic_family")
    )
    execution_scope_counts = Counter(
        row["residual_execution_scope"]
        for row in ledger
        if row.get("residual_execution_scope")
    )
    covered_count = sum(1 for row in ledger if row["covered"])
    total = len(ledger)
    residual_count = total - covered_count
    identities: dict[str, list[bool]] = {}
    for row in ledger:
        identity = str(row.get("oracle_id") or "").strip()
        if not identity:
            identity = f"name:{normalize_name(row.get('name'))}"
        identities.setdefault(identity, []).append(bool(row["covered"]))
    fully_covered_identities = sum(all(states) for states in identities.values())
    partially_covered_identities = sum(
        any(states) and not all(states) for states in identities.values()
    )
    residual_identities = len(identities) - fully_covered_identities
    family_gates = [
        {
            "family": family,
            "card_count": count,
            "status": "action_required",
            "next_gate": residual_family_next_gate(family),
            "promotion_allowed": False,
        }
        for family, count in sorted(semantic_family_counts.items())
    ]
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": utc_now(),
        "status": "complete" if residual_count == 0 else "complete_with_residual",
        "method": {
            "engine_order": list(ENGINE_ORDER),
            "read_only": True,
            "identity_reconciliation_is_not_coverage_until_runtime_uses_it": True,
            "catalog_presence_is_not_card_use_evidence": True,
        },
        "engines": {"xmage": xmage_metadata, "forge": forge_metadata},
        "summary": {
            "total": total,
            "covered": covered_count,
            "residual": residual_count,
            "coverage_ratio": round(covered_count / max(total, 1), 6),
            "total_identities": len(identities),
            "fully_covered_identities": fully_covered_identities,
            "partially_covered_identities": partially_covered_identities,
            "residual_identities": residual_identities,
            "identity_coverage_ratio": round(
                fully_covered_identities / max(len(identities), 1), 6
            ),
            "lane_counts": dict(sorted(lane_counts.items())),
            "residual_family_counts": dict(sorted(family_counts.items())),
            "residual_semantic_family_counts": dict(
                sorted(semantic_family_counts.items())
            ),
            "residual_execution_scope_counts": dict(
                sorted(execution_scope_counts.items())
            ),
        },
        "family_gates": family_gates,
        "ledger": ledger,
    }


def write_markdown(payload: Mapping[str, Any], path: Path) -> None:
    summary = payload["summary"]
    lines = [
        "# External Card Coverage Closure",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Schema: `{payload['schema_version']}`",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
        f"| Total | {summary['total']} |",
        f"| Covered | {summary['covered']} |",
        f"| Residual | {summary['residual']} |",
        f"| Coverage ratio | {summary['coverage_ratio']:.4%} |",
        f"| Total identities | {summary['total_identities']} |",
        f"| Fully covered identities | {summary['fully_covered_identities']} |",
        f"| Partially covered identities | {summary['partially_covered_identities']} |",
        f"| Residual identities | {summary['residual_identities']} |",
        f"| Identity coverage ratio | {summary['identity_coverage_ratio']:.4%} |",
        "",
        "## Lanes",
        "",
        "| Lane | Cards |",
        "| --- | ---: |",
    ]
    for lane, count in summary["lane_counts"].items():
        lines.append(f"| `{lane}` | {count} |")
    lines.extend(["", "## Residual Families", "", "| Family | Cards |", "| --- | ---: |"])
    for family, count in summary["residual_family_counts"].items():
        lines.append(f"| `{family}` | {count} |")
    lines.extend(["", "## Semantic Residual Families", "", "| Family | Cards |", "| --- | ---: |"])
    for family, count in summary["residual_semantic_family_counts"].items():
        lines.append(f"| `{family}` | {count} |")
    lines.extend(
        [
            "",
            "## Residual Execution Scopes",
            "",
            "| Scope | Cards |",
            "| --- | ---: |",
        ]
    )
    for scope, count in summary["residual_execution_scope_counts"].items():
        lines.append(f"| `{scope}` | {count} |")
    lines.extend(["", "## Family Gates", "", "| Family | Next gate |", "| --- | --- |"])
    for gate in payload.get("family_gates") or []:
        lines.append(f"| `{gate['family']}` | `{gate['next_gate']}` |")
    lines.extend(
        [
            "",
            "## Contract",
            "",
            "- Exact catalog resolution is execution coverage, not evidence that a card was used.",
            "- Identity candidates remain residual until the runtime identity bridge consumes them.",
            "- The ledger is read-only and never promotes PostgreSQL rules.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def load_cards(path: Path) -> list[dict[str, Any]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, Mapping):
        payload = payload.get("cards") or payload.get("rows") or payload.get("ledger") or []
    if not isinstance(payload, list):
        raise ValueError("cards input must be a list or an object containing cards/rows")
    return [dict(row) for row in payload if isinstance(row, Mapping)]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cards", type=Path, required=True)
    parser.add_argument("--native-cards", type=Path)
    parser.add_argument("--xmage-url", required=True)
    parser.add_argument("--forge-url", required=True)
    parser.add_argument("--batch-size", type=int, default=20_000)
    parser.add_argument("--timeout-seconds", type=float, default=30.0)
    parser.add_argument("--out-prefix", type=Path, required=True)
    parser.add_argument("--fail-on-residual", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    native = set()
    if args.native_cards:
        native = _native_names(json.loads(args.native_cards.read_text(encoding="utf-8")))
    payload = build_closure(
        load_cards(args.cards),
        xmage_url=args.xmage_url,
        forge_url=args.forge_url,
        native_names=native,
        batch_size=max(1, args.batch_size),
        timeout=max(1.0, args.timeout_seconds),
    )
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "summary": payload["summary"], "json": str(json_path), "markdown": str(md_path)}))
    if args.fail_on_residual and payload["summary"]["residual"]:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
