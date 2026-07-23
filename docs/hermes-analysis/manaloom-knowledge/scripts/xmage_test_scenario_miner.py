#!/usr/bin/env python3
"""Mine local XMage tests into ManaLoom focused-test review candidates.

The miner is read-only. It scans XMage's Java test corpus for exact card-name or
class-name references and emits scenario-shape evidence. It does not execute
tests, mutate PostgreSQL, mutate SQLite, or promote battle rules.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import external_engine_source_contract as engine_source_contract

DEFAULT_XMAGE_ROOT: Path | None = None
DEFAULT_REPORT_DIR = Path(__file__).resolve().parent.parent.parent / "master_optimizer_reports"

TEST_COMMANDS = [
    "addCard",
    "removeAllCardsFromLibrary",
    "castSpell",
    "activateAbility",
    "attack",
    "block",
    "setChoice",
    "setTarget",
    "waitStackResolved",
    "checkLife",
    "checkPermanentCount",
    "checkGraveyardCount",
    "checkHandCardCount",
    "checkStackObject",
    "checkPlayableAbility",
    "checkPT",
    "execute",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def rel(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def first_face_name(card_name: str) -> str:
    return str(card_name or "").split("//", 1)[0].strip()


def java_class_name(value: str) -> str:
    normalized = str(value or "").replace("'", "").replace("\u2019", "")
    words = re.findall(r"[A-Za-z0-9]+", normalized)
    return "".join(word[:1].upper() + word[1:] for word in words)


def normalize_name(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip()).lower()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def iter_test_files(xmage_root: Path) -> list[Path]:
    root = xmage_root / "Mage.Tests" / "src" / "test" / "java"
    if not root.exists():
        return []
    return sorted(path for path in root.rglob("*.java") if path.is_file())


def card_search_terms(card_name: str) -> list[str]:
    first = first_face_name(card_name)
    terms = [card_name, first, java_class_name(first), java_class_name(card_name)]
    return sorted({term for term in terms if term}, key=lambda value: (len(value), value.lower()), reverse=True)


def command_counts(source: str) -> dict[str, int]:
    counts = Counter()
    for command in TEST_COMMANDS:
        count = source.count(command)
        if count:
            counts[command] = count
    return dict(counts)


def extract_methods(source: str) -> list[dict[str, Any]]:
    methods: list[dict[str, Any]] = []
    pattern = re.compile(
        r"(?:@Test[^\n]*\s*)?(?:public|private|protected)\s+void\s+([A-Za-z0-9_]+)\s*\([^)]*\)\s*\{",
        flags=re.MULTILINE,
    )
    for match in pattern.finditer(source):
        brace_start = match.end() - 1
        depth = 0
        end = brace_start
        for index in range(brace_start, len(source)):
            char = source[index]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    end = index + 1
                    break
        methods.append(
            {
                "method_name": match.group(1),
                "start_offset": match.start(),
                "end_offset": end,
                "source": source[match.start() : end],
            }
        )
    return methods


def excerpt(source: str, *, max_lines: int = 70) -> str:
    lines = [line.rstrip() for line in source.splitlines() if line.strip()]
    return "\n".join(lines[:max_lines])


def scenario_shape(source: str) -> dict[str, Any]:
    counts = command_counts(source)
    setup = [name for name in ["addCard", "removeAllCardsFromLibrary"] if counts.get(name)]
    actions = [name for name in ["castSpell", "activateAbility", "attack", "block", "waitStackResolved"] if counts.get(name)]
    choices = [name for name in ["setChoice", "setTarget"] if counts.get(name)]
    assertions = [
        name
        for name in [
            "checkLife",
            "checkPermanentCount",
            "checkGraveyardCount",
            "checkHandCardCount",
            "checkStackObject",
            "checkPlayableAbility",
            "checkPT",
        ]
        if counts.get(name)
    ]
    return {
        "setup_commands": setup,
        "action_commands": actions,
        "choice_commands": choices,
        "assertion_commands": assertions,
        "command_counts": counts,
        "usable_for_manaloom_candidate": bool(setup and actions and assertions),
    }


def method_matches_card(method_source: str, terms: list[str]) -> bool:
    lower_source = method_source.lower()
    return any(term.lower() in lower_source for term in terms)


def mine_card(card_name: str, *, xmage_root: Path, test_files: list[Path]) -> dict[str, Any]:
    terms = card_search_terms(card_name)
    file_hits: list[dict[str, Any]] = []
    for path in test_files:
        source = read_text(path)
        if not method_matches_card(source, terms):
            continue
        methods = [
            method
            for method in extract_methods(source)
            if method_matches_card(method["source"], terms)
        ]
        if not methods:
            methods = [{"method_name": None, "source": source}]
        method_hits = []
        for method in methods[:8]:
            shape = scenario_shape(method["source"])
            method_hits.append(
                {
                    "method_name": method.get("method_name"),
                    "scenario_shape": shape,
                    "excerpt": excerpt(method["source"]),
                }
            )
        file_hits.append(
            {
                "path": rel(path, xmage_root),
                "method_hit_count": len(methods),
                "method_hits": method_hits,
                "file_command_counts": command_counts(source),
            }
        )
    usable_count = sum(
        1
        for file_hit in file_hits
        for method_hit in file_hit["method_hits"]
        if method_hit["scenario_shape"]["usable_for_manaloom_candidate"]
    )
    return {
        "card_name": card_name,
        "search_terms": terms,
        "status": "test_reference_found" if file_hits else "no_exact_test_reference_found",
        "test_file_count": len(file_hits),
        "usable_scenario_candidate_count": usable_count,
        "file_hits": file_hits[:12],
    }


def load_cards_from_json(path: Path) -> list[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    cards = data.get("cards")
    if isinstance(cards, list):
        names = [str(card.get("card_name") or card.get("name") or "") for card in cards if isinstance(card, dict)]
        return [name for name in names if name]
    raise ValueError(f"Unsupported cards JSON shape: {path}")


def build_report(cards: list[str], *, xmage_root: Path) -> dict[str, Any]:
    test_files = iter_test_files(xmage_root)
    mined_cards = [mine_card(card, xmage_root=xmage_root, test_files=test_files) for card in cards]
    statuses = Counter(card["status"] for card in mined_cards)
    return {
        "generated_at": utc_now(),
        "status": "ready",
        "mutations_performed": [],
        "xmage_root": str(xmage_root),
        "summary": {
            "requested_card_count": len(cards),
            "test_files_scanned": len(test_files),
            "status_counts": dict(sorted(statuses.items())),
            "cards_with_test_reference": sum(1 for card in mined_cards if card["test_file_count"] > 0),
            "usable_scenario_candidate_count": sum(card["usable_scenario_candidate_count"] for card in mined_cards),
        },
        "cards": mined_cards,
        "notes": [
            "XMage tests are reference evidence only; ManaLoom still needs local focused tests before PG promotion.",
            "no_exact_test_reference_found does not mean XMage has no card implementation; it only means the test corpus did not reference the card by scanned terms.",
        ],
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# XMage Test Scenario Miner",
        "",
        f"- Generated at: `{report.get('generated_at')}`",
        f"- Status: `{report.get('status')}`",
        f"- XMage root: `{report.get('xmage_root')}`",
        f"- Mutations performed: `{report.get('mutations_performed')}`",
        "",
        "## Summary",
        "",
    ]
    for key, value in sorted((report.get("summary") or {}).items()):
        lines.append(f"- `{key}`: `{value}`")
    lines.extend(["", "## Cards", ""])
    for card in report.get("cards", []):
        lines.extend(
            [
                f"### {card.get('card_name')}",
                "",
                f"- Status: `{card.get('status')}`",
                f"- Test files: `{card.get('test_file_count')}`",
                f"- Usable scenario candidates: `{card.get('usable_scenario_candidate_count')}`",
            ]
        )
        for file_hit in card.get("file_hits", [])[:4]:
            lines.append(f"- `{file_hit.get('path')}` method hits `{file_hit.get('method_hit_count')}`")
            for method_hit in file_hit.get("method_hits", [])[:2]:
                shape = method_hit.get("scenario_shape") or {}
                lines.append(
                    "  - "
                    f"`{method_hit.get('method_name')}` "
                    f"usable=`{shape.get('usable_for_manaloom_candidate')}` "
                    f"setup=`{shape.get('setup_commands')}` "
                    f"actions=`{shape.get('action_commands')}` "
                    f"assertions=`{shape.get('assertion_commands')}`"
                )
        lines.append("")
    lines.extend(["## Boundary", ""])
    for note in report.get("notes", []):
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(report: dict[str, Any], *, output_json: Path, output_md: Path) -> None:
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    output_md.write_text(render_markdown(report), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xmage-root", type=Path, default=DEFAULT_XMAGE_ROOT)
    parser.add_argument("--cards", nargs="*", default=[])
    parser.add_argument("--cards-json", type=Path)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--output-md", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        xmage_root = engine_source_contract.resolve_xmage_source_root(args.xmage_root)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    cards = list(args.cards)
    if args.cards_json:
        cards.extend(load_cards_from_json(args.cards_json))
    cards = sorted({card for card in cards if card}, key=normalize_name)
    if not cards:
        raise SystemExit("No cards provided. Use --cards or --cards-json.")
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_json = args.output_json or DEFAULT_REPORT_DIR / f"xmage_test_scenario_miner_{timestamp}.json"
    output_md = args.output_md or output_json.with_suffix(".md")
    report = build_report(cards, xmage_root=xmage_root)
    write_outputs(report, output_json=output_json, output_md=output_md)
    print(f"wrote_json={output_json}")
    print(f"wrote_md={output_md}")
    print(f"requested_card_count={report['summary']['requested_card_count']}")
    print(f"cards_with_test_reference={report['summary']['cards_with_test_reference']}")
    print(f"usable_scenario_candidate_count={report['summary']['usable_scenario_candidate_count']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
