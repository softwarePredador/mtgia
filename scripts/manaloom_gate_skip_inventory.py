#!/usr/bin/env python3
"""Inventário estrito de SKIP e BLOCKED dos gates locais (BT-GATE-001, D-17).

Regra: todo teste pulado e todo marcador SKIP/PARTIAL na saída de um gate vira
PARTIAL inventariado, com código de saída 3, salvo se estiver na allowlist
versionada (`server/config/gate_skip_allowlist.json`) com motivo, dono e prazo.
BLOCKED nunca vira sucesso: código de saída 2.

Subcomandos:
  test-report  lê o JSON do reporter de `dart test`/`flutter test`
               (`--file-reporter json:<arquivo>`) e lista cada teste pulado;
  scan-log     lê o log de uma etapa e procura marcadores textuais de skip e de
               bloqueio;
  validate-allowlist  confere o esquema da allowlist.

Códigos de saída: 0 sem skip (ou todo skip na allowlist), 3 PARTIAL, 2 BLOCKED
(entrada ilegível, truncada ou allowlist inválida). Nunca devolve 0 por falta de
dados: relatório vazio ou sem evento `done` é BLOCKED.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any

SCHEMA = "manaloom.gate_skip_allowlist.v1"
INVENTORY_SCHEMA = "manaloom.gate_skip_inventory.v1"
ROOT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_ALLOWLIST = ROOT_DIR / "server" / "config" / "gate_skip_allowlist.json"

EXIT_PASS = 0
EXIT_BLOCKED = 2
EXIT_PARTIAL = 3

ENTRY_ID_RE = re.compile(r"^[a-z0-9][a-z0-9_.-]*$")
REQUIRED_ENTRY_FIELDS = ("id", "kind", "reason", "owner", "added", "review_by")
KINDS = ("test", "log_line")

# Marcadores textuais de skip. Ancorados no começo da linha (depois de espaços e
# de um "- " de lista) para não pegar nome de teste ou prosa.
SKIP_LINE_RE = re.compile(r"^\s*(?:-\s+)?(SKIP|SKIPPED|PARTIAL)(?:_[A-Z]+)?\b")
BLOCKED_LINE_RE = re.compile(r"^\s*(?:-\s+)?BLOCKED\b")
# Contadores de teste pulado: Flutter/Dart "+34 ~2:", unittest "skipped=2",
# pytest "2 skipped" e o resumo "All other tests passed!".
COUNTER_RES = (
    re.compile(r"\+\d+\s+~([1-9]\d*)"),
    re.compile(r"(?<![A-Za-z0-9_])skipped=([1-9]\d*)"),
    re.compile(r"\b([1-9]\d*) skipped\b"),
    re.compile(r"All other tests passed!"),
)
# Linha emitida por `test-report`: contabiliza os skips de contador no log.
INVENTORY_LINE_RE = re.compile(
    r"^GATE_SKIP_INVENTORY label=(?P<label>\S*) skipped=(?P<skipped>\d+) "
    r"allowlisted=(?P<allowlisted>\d+) unlisted=(?P<unlisted>\d+)$"
)


class InventoryError(Exception):
    """Entrada inválida: o gate vira BLOCKED, nunca sucesso."""


def _parse_date(value: Any, field: str) -> date:
    if not isinstance(value, str):
        raise InventoryError(f"{field} must be an ISO date")
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise InventoryError(f"{field} must be an ISO date") from exc


def load_allowlist(path: Path, today: date | None = None) -> list[dict[str, Any]]:
    """Carrega e valida a allowlist. Entrada vencida deixa de valer (é PARTIAL)."""
    today = today or date.today()
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise InventoryError(f"allowlist unreadable: {path}") from exc
    if not isinstance(raw, dict) or raw.get("schema") != SCHEMA:
        raise InventoryError(f"allowlist schema must be {SCHEMA!r}")
    entries = raw.get("entries")
    if not isinstance(entries, list):
        raise InventoryError("allowlist entries must be a list")
    seen: set[str] = set()
    active: list[dict[str, Any]] = []
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise InventoryError(f"entries[{index}] must be an object")
        for field in REQUIRED_ENTRY_FIELDS:
            value = entry.get(field)
            if not isinstance(value, str) or not value.strip():
                raise InventoryError(f"entries[{index}].{field} is required")
        if not ENTRY_ID_RE.fullmatch(entry["id"]) or entry["id"] in seen:
            raise InventoryError(f"entries[{index}].id is invalid or duplicated")
        seen.add(entry["id"])
        if entry["kind"] not in KINDS:
            raise InventoryError(f"entries[{index}].kind must be one of {KINDS}")
        added = _parse_date(entry["added"], f"entries[{index}].added")
        review_by = _parse_date(entry["review_by"], f"entries[{index}].review_by")
        if review_by < added:
            raise InventoryError(f"entries[{index}].review_by precedes added")
        if entry["kind"] == "test":
            for field in ("suite", "test_name"):
                value = entry.get(field)
                if not isinstance(value, str) or not value.strip():
                    raise InventoryError(f"entries[{index}].{field} is required")
        else:
            pattern = entry.get("pattern")
            if not isinstance(pattern, str) or not pattern.strip():
                raise InventoryError(f"entries[{index}].pattern is required")
            try:
                re.compile(pattern)
            except re.error as exc:
                raise InventoryError(f"entries[{index}].pattern is invalid") from exc
        if review_by < today:
            continue  # vencida: o skip volta a ser PARTIAL
        active.append(entry)
    return active


def _read_events(path: Path) -> list[dict[str, Any]]:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        raise InventoryError(f"test report unreadable: {path}") from exc
    events: list[dict[str, Any]] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        if not line.strip():
            continue
        try:
            value = json.loads(line)
        except ValueError as exc:
            raise InventoryError(f"test report line {line_number} is not JSON") from exc
        if isinstance(value, dict):
            events.append(value)
    if not events:
        raise InventoryError("test report is empty")
    if not any(event.get("type") == "done" for event in events):
        raise InventoryError("test report has no done event (truncated run)")
    return events


def skipped_tests(path: Path) -> list[dict[str, Any]]:
    """Cada teste pulado do reporter JSON: suite, nome e motivo declarado."""
    events = _read_events(path)
    suites: dict[int, str] = {}
    tests: dict[int, dict[str, Any]] = {}
    skipped: list[dict[str, Any]] = []
    for event in events:
        kind = event.get("type")
        if kind == "suite":
            suite = event.get("suite") or {}
            if isinstance(suite.get("id"), int):
                suites[suite["id"]] = str(suite.get("path") or "")
        elif kind == "testStart":
            test = event.get("test") or {}
            if isinstance(test.get("id"), int):
                tests[test["id"]] = test
        elif kind == "testDone" and event.get("skipped") is True:
            if event.get("hidden") is True:
                continue
            test = tests.get(event.get("testID"), {})
            metadata = test.get("metadata") or {}
            skipped.append(
                {
                    "suite": suites.get(test.get("suiteID"), ""),
                    "test_name": str(test.get("name") or ""),
                    "reason": str(metadata.get("skipReason") or ""),
                }
            )
    return skipped


def _entry_matches_test(entry: dict[str, Any], item: dict[str, Any]) -> bool:
    return (
        entry["kind"] == "test"
        and entry["test_name"] == item["test_name"]
        and item["suite"].replace("\\", "/").endswith(entry["suite"])
    )


def classify_tests(
    skips: list[dict[str, Any]], allowlist: list[dict[str, Any]]
) -> dict[str, Any]:
    items = []
    for skip in skips:
        match = next((e for e in allowlist if _entry_matches_test(e, skip)), None)
        items.append(
            {
                **skip,
                "allowlisted": match is not None,
                "allowlist_id": match["id"] if match else None,
                "owner": match["owner"] if match else None,
                "allowlist_reason": match["reason"] if match else None,
            }
        )
    unlisted = [item for item in items if not item["allowlisted"]]
    return {
        "schema": INVENTORY_SCHEMA,
        "status": "PARTIAL" if unlisted else "PASS",
        "skipped": len(items),
        "allowlisted": len(items) - len(unlisted),
        "unlisted": len(unlisted),
        "items": items,
    }


def scan_log_text(text: str, allowlist: list[dict[str, Any]]) -> dict[str, Any]:
    """Marcadores textuais de skip/bloqueio e contadores de teste pulado."""
    findings: list[dict[str, Any]] = []
    inventoried_skips = 0
    inventoried_unlisted = 0
    counter_hits: list[str] = []
    patterns = [
        (entry, re.compile(entry["pattern"]))
        for entry in allowlist
        if entry["kind"] == "log_line"
    ]
    for raw_line in re.split(r"[\r\n]+", text):
        line = raw_line.rstrip()
        if not line:
            continue
        inventory = INVENTORY_LINE_RE.match(line)
        if inventory:
            inventoried_skips += int(inventory["skipped"])
            inventoried_unlisted += int(inventory["unlisted"])
            continue
        if BLOCKED_LINE_RE.match(line):
            findings.append({"kind": "blocked", "line": line[:240]})
            continue
        if SKIP_LINE_RE.match(line):
            match = next((e for e, rx in patterns if rx.search(line)), None)
            findings.append(
                {
                    "kind": "skip_marker",
                    "line": line[:240],
                    "allowlisted": match is not None,
                    "allowlist_id": match["id"] if match else None,
                }
            )
            continue
        if any(rx.search(line) for rx in COUNTER_RES):
            counter_hits.append(line[:240])
    if counter_hits and inventoried_skips == 0:
        findings.append(
            {
                "kind": "uninventoried_test_skip",
                "line": counter_hits[-1],
                "detail": "contador de teste pulado sem GATE_SKIP_INVENTORY no log",
            }
        )
    if inventoried_unlisted:
        findings.append(
            {
                "kind": "unlisted_test_skip",
                "detail": f"{inventoried_unlisted} teste(s) pulado(s) fora da allowlist",
            }
        )
    blocked = any(item["kind"] == "blocked" for item in findings)
    partial = any(
        item["kind"] in ("uninventoried_test_skip", "unlisted_test_skip")
        or (item["kind"] == "skip_marker" and not item["allowlisted"])
        for item in findings
    )
    status = "BLOCKED" if blocked else "PARTIAL" if partial else "PASS"
    return {
        "schema": INVENTORY_SCHEMA,
        "status": status,
        "findings": findings,
        "inventoried_skips": inventoried_skips,
    }


def exit_code_for(status: str) -> int:
    return {"PASS": EXIT_PASS, "PARTIAL": EXIT_PARTIAL, "BLOCKED": EXIT_BLOCKED}[status]


def _write_json(path: Path | None, payload: dict[str, Any]) -> None:
    if path is not None:
        path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("test-report", "scan-log", "validate-allowlist"):
        item = sub.add_parser(name)
        item.add_argument("--allowlist", type=Path, default=DEFAULT_ALLOWLIST)
        item.add_argument("--today", help="ISO date (somente para testes)")
        if name != "validate-allowlist":
            item.add_argument("--out", type=Path)
    sub.choices["test-report"].add_argument("--json", type=Path, required=True)
    sub.choices["test-report"].add_argument("--label", default="tests")
    sub.choices["scan-log"].add_argument("--log", type=Path, required=True)
    args = parser.parse_args(argv)

    try:
        today = date.fromisoformat(args.today) if args.today else None
        allowlist = load_allowlist(args.allowlist, today)
        if args.command == "validate-allowlist":
            print(f"PASS: allowlist válida ({len(allowlist)} entradas ativas)")
            return EXIT_PASS
        if args.command == "test-report":
            result = classify_tests(skipped_tests(args.json), allowlist)
            result["label"] = args.label
            _write_json(args.out, result)
            label = re.sub(r"\s+", "_", args.label) or "tests"
            print(
                f"GATE_SKIP_INVENTORY label={label} skipped={result['skipped']} "
                f"allowlisted={result['allowlisted']} unlisted={result['unlisted']}"
            )
            for item in result["items"]:
                state = f"allowlisted:{item['allowlist_id']}" if item["allowlisted"] else "UNLISTED"
                print(
                    f"PARTIAL-INVENTORY {state} test={item['test_name']!r} "
                    f"suite={item['suite']} reason={item['reason']!r}",
                    file=sys.stderr if not item["allowlisted"] else sys.stdout,
                )
            return exit_code_for(result["status"])
        text = args.log.read_text(encoding="utf-8", errors="replace")
        result = scan_log_text(text, allowlist)
        _write_json(args.out, result)
        for finding in result["findings"]:
            print(f"{result['status']}-INVENTORY {json.dumps(finding, sort_keys=True)}", file=sys.stderr)
        return exit_code_for(result["status"])
    except InventoryError as exc:
        print(f"BLOCKED: {exc}", file=sys.stderr)
        return EXIT_BLOCKED
    except OSError as exc:
        print(f"BLOCKED: {exc}", file=sys.stderr)
        return EXIT_BLOCKED


if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
