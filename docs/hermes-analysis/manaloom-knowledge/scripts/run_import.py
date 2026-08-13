#!/usr/bin/env python3
"""Read-only auditor for the Markdown/Hermes knowledge import surface.

This entrypoint intentionally does not import a PostgreSQL driver, load secret
files, open a database connection, or write artifacts.  Its only supported
operation is to parse the versioned local corpus and print a deterministic
candidate summary.  PostgreSQL apply stays fail-closed under BT-AI-014 until
schema, provenance, idempotency and promotion receipts are versioned.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


REPORT_SCHEMA_VERSION = "manaloom_knowledge_import_audit_v1"
BLOCKED_TASK = "BT-AI-014"


def _resolve_repo_root() -> Path:
    for key in ("MANALOOM_REPO", "MANALOOM_WORKSPACE", "HERMES_REPO_DIR"):
        value = os.environ.get(key)
        if value:
            candidate = Path(value).resolve()
            if candidate.exists():
                return candidate
    return Path(__file__).resolve().parents[4]


REPO_ROOT = _resolve_repo_root()
KNOWLEDGE_ROOT = Path(
    os.environ.get(
        "MANALOOM_KNOWLEDGE_ROOT",
        str(REPO_ROOT / "docs" / "hermes-analysis" / "manaloom-knowledge"),
    )
).resolve()
THEMES_PATH = Path(
    os.environ.get("MANALOOM_THEMES_MD", str(KNOWLEDGE_ROOT / "THEMES.md"))
).resolve()
DECKS_DIR = Path(
    os.environ.get("MANALOOM_KNOWLEDGE_DECKS_DIR", str(KNOWLEDGE_ROOT / "decks"))
).resolve()


def parse_markdown_table(table_text: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    lines = [line.strip() for line in table_text.split("\n") if line.strip()]
    if len(lines) < 3:
        return rows
    header = [cell.strip() for cell in lines[0].split("|")[1:-1]]
    for line in lines[2:]:
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.split("|")[1:-1]]
        cells = [re.sub(r"\*+", "", cell).strip() for cell in cells]
        if len(cells) == len(header):
            rows.append(dict(zip(header, cells)))
    return rows


def parse_themes_md(filepath: Path | str) -> list[dict[str, Any]]:
    content = Path(filepath).read_text(encoding="utf-8")
    rules: list[dict[str, Any]] = []
    sections = (
        ("### Ramp por Tema", "ramp"),
        ("### Draw por Tema", "draw"),
        ("### Removal por Tema", "removal"),
    )
    for section_header, function_name in sections:
        index = content.find(section_header)
        if index == -1:
            continue
        end_index = content.find("\n### ", index + len(section_header))
        if end_index == -1:
            end_index = len(content)
        section_text = content[index:end_index]
        table_match = re.search(
            r"(\|.+\|\n\|[-|: :]+\|\n(?:\|.+\|\n?)+)", section_text
        )
        if not table_match:
            continue
        for row in parse_markdown_table(table_match.group(1)):
            values = list(row.values())
            theme = values[0].strip() if values else ""
            if not theme or theme == "Tema":
                continue
            value_column = values[1].strip() if len(values) > 1 else ""
            numbers = re.findall(r"(\d+)", value_column)
            if not numbers:
                continue
            minimum = int(numbers[0])
            maximum = int(numbers[1]) if len(numbers) > 1 else minimum
            notes = values[-1].strip() if values else ""
            theme_slug = (
                theme.lower().replace(" ", "_").replace("-", "_").replace("'", "")
            )
            rules.append(
                {
                    "theme": theme_slug,
                    "function": function_name,
                    "min": minimum,
                    "max": maximum,
                    "ideal": maximum,
                    "priority": (
                        "essential"
                        if function_name in {"ramp", "draw"} and minimum >= 10
                        else "high"
                    ),
                    "conditions": {"theme_label": theme, "notes": notes},
                    "description": (
                        f"{function_name.upper()} para {theme}: "
                        f"{minimum}-{maximum}. {notes}"
                    ),
                }
            )
    return rules


def extract_metrics_from_content(content: str) -> dict[str, int | float]:
    metrics: dict[str, int | float] = {}
    patterns = {
        "lands": [r"[Ll]ands?\s*[:=]\s*(\d+)", r"Total\s+lands\s*[=:]\s*(\d+)"],
        "ramp": [
            r"[Rr]amp\s*(?:total)?\s*[:=]\s*(\d+)",
            r"[Rr]amp\s*/s*non-terreo\s*[:=]\s*(\d+)",
        ],
        "draw": [
            r"[Dd]raw\s*(?:total|Rummage)?\s*[:=]\s*(\d+)",
            r"[Dd]raw\s*/s*loot\s*[:=]\s*(\d+)",
        ],
        "removal": [
            r"[Rr]emoval\s*(?:total|spot)?\s*[:=]\s*(\d+)",
            r"[Ss]pot\s+interaction?\s*[:=]\s*(\d+)",
        ],
        "board_wipes": [
            r"[Bb]oard\s*[Ww]ipe\s*[=:]\s*(\d+)",
            r"[Ww]ipe[s]?\s*[=:]\s*(\d+)",
        ],
        "protection": [r"[Pp]rotection\s*[=:]\s*(\d+)"],
        "avg_cmc": [
            r"CMC\s*(?:medio|average|mdio)\s*[:=]\s*([\d.]+)",
            r"[Aa]vg\.?\s*CMC\s*[:=]\s*([\d.]+)",
        ],
    }
    for key, pattern_list in patterns.items():
        for pattern in pattern_list:
            match = re.search(pattern, content, re.MULTILINE)
            if match:
                value = float(match.group(1))
                metrics[key] = int(value) if value == int(value) else value
                break
    return metrics


def _commander_profiles(decks_dir: Path) -> tuple[list[dict[str, Any]], list[Path]]:
    profiles: list[dict[str, Any]] = []
    sources: list[Path] = []
    if not decks_dir.is_dir():
        return profiles, sources
    accepted_names = ("edhrec-avg", "edhrec-default", "user-decklist", "optimized")
    for commander_dir in sorted(path for path in decks_dir.iterdir() if path.is_dir()):
        for filepath in sorted(path for path in commander_dir.iterdir() if path.is_file()):
            if not any(marker in filepath.name for marker in accepted_names):
                continue
            try:
                content = filepath.read_text(encoding="utf-8")
            except (OSError, UnicodeError):
                continue
            sources.append(filepath)
            commander_match = re.search(r"Comandante:\s*(.+)", content)
            commander_name = (
                commander_match.group(1).strip()
                if commander_match
                else commander_dir.name.replace("-", " ").replace("_", " ").title()
            )
            metrics = extract_metrics_from_content(content)
            if metrics:
                profiles.append(
                    {
                        "commander_name": commander_name,
                        "metrics": metrics,
                        "source_file": str(filepath),
                        "content_sha256": hashlib.sha256(content.encode()).hexdigest(),
                    }
                )
    return profiles, sources


def _card_profile_candidates(filepath: Path, commander_name: str) -> list[tuple[str, ...]]:
    try:
        content = filepath.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        return []

    candidates: list[tuple[str, ...]] = []
    for table_match in re.finditer(
        r"(\|.+\|\n\|[-|: :]+\|\n(?:\|.+\|\n?)+)", content
    ):
        lines = [line.strip() for line in table_match.group(1).split("\n") if line.strip()]
        if len(lines) < 3:
            continue
        headers = [cell.strip().lower() for cell in lines[0].split("|")[1:-1]]
        for line in lines[2:]:
            cells = [cell.strip() for cell in line.split("|")[1:-1]]
            if len(cells) != len(headers):
                continue
            row = dict(zip(headers, cells))
            card = row.get("card", row.get("carta", "")).strip()
            if not card or len(card) > 50:
                continue
            tag = row.get("tag", row.get("type", row.get("tipo", ""))).strip()
            function = row.get("function", row.get("funo", tag)).strip()
            candidates.append(
                (
                    commander_name.casefold(),
                    card.casefold(),
                    tag.casefold(),
                    function.casefold(),
                    "analysis_table",
                )
            )

    for match in re.finditer(r"\*\*([^*]+)\*\*\s*\((\d+)%\)", content):
        card = match.group(1).strip()
        if len(card) <= 50:
            candidates.append(
                (
                    commander_name.casefold(),
                    card.casefold(),
                    "",
                    f"edhrec {match.group(2)}%",
                    "edhrec_inclusion",
                )
            )
    return candidates


def _scan_card_profiles(decks_dir: Path) -> tuple[list[tuple[str, ...]], list[Path]]:
    candidates: list[tuple[str, ...]] = []
    sources: list[Path] = []
    if not decks_dir.is_dir():
        return candidates, sources
    for commander_dir in sorted(path for path in decks_dir.iterdir() if path.is_dir()):
        commander = commander_dir.name.replace("-", " ").replace("_", " ").title()
        for filepath in sorted(commander_dir.glob("*.md")):
            sources.append(filepath)
            candidates.extend(_card_profile_candidates(filepath, commander))
    return candidates, sources


def _duplicate_excess(values: Iterable[Any]) -> int:
    return sum(count - 1 for count in Counter(values).values() if count > 1)


def _source_manifest_digest(paths: Iterable[Path]) -> str:
    records: list[str] = []
    for path in sorted(set(path.resolve() for path in paths)):
        try:
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
        except OSError:
            continue
        try:
            label = path.relative_to(REPO_ROOT).as_posix()
        except ValueError:
            label = path.as_posix()
        records.append(f"{label}\t{digest}")
    return hashlib.sha256("\n".join(records).encode()).hexdigest()


def build_report() -> dict[str, Any]:
    warnings: list[str] = []
    theme_rules: list[dict[str, Any]] = []
    sources: list[Path] = []
    if THEMES_PATH.is_file():
        theme_rules = parse_themes_md(THEMES_PATH)
        sources.append(THEMES_PATH)
    else:
        warnings.append(f"missing_themes_file:{THEMES_PATH}")

    if not DECKS_DIR.is_dir():
        warnings.append(f"missing_decks_directory:{DECKS_DIR}")
    profiles, profile_sources = _commander_profiles(DECKS_DIR)
    card_candidates, card_sources = _scan_card_profiles(DECKS_DIR)
    sources.extend(profile_sources)
    sources.extend(card_sources)

    theme_keys = [(rule["theme"], rule["function"]) for rule in theme_rules]
    commander_keys = [profile["commander_name"].casefold() for profile in profiles]
    unique_sources = set(path.resolve() for path in sources)
    return {
        "schema_version": REPORT_SCHEMA_VERSION,
        "status": "report_only",
        "apply": {
            "allowed": False,
            "blocked_by": BLOCKED_TASK,
            "reason": (
                "versioned schema, source provenance, idempotency and promotion "
                "receipt are not yet closed"
            ),
        },
        "postgresql": {
            "credentials_loaded": False,
            "connected": False,
            "queried": False,
            "mutated": False,
        },
        "sources": {
            "knowledge_root": str(KNOWLEDGE_ROOT),
            "files_scanned": len(unique_sources),
            "manifest_sha256": _source_manifest_digest(unique_sources),
        },
        "candidate_counts": {
            "theme_contextual_rules": len(theme_rules),
            "commander_reference_profiles": len(profiles),
            "card_deck_profiles": len(card_candidates),
            "total": len(theme_rules) + len(profiles) + len(card_candidates),
        },
        "duplicate_natural_key_excess": {
            "theme_contextual_rules": _duplicate_excess(theme_keys),
            "commander_reference_profiles": _duplicate_excess(commander_keys),
            "card_deck_profiles": _duplicate_excess(card_candidates),
        },
        "warnings": warnings,
    }


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--report-only", action="store_true")
    mode.add_argument("--apply", action="store_true")
    return parser.parse_args(argv)


def _env_requests_apply() -> bool:
    return os.environ.get("MANALOOM_IMPORT_APPLY", "0").strip().lower() in {
        "1",
        "true",
        "yes",
    }


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    if args.apply or _env_requests_apply():
        print(
            json.dumps(
                {
                    "schema_version": REPORT_SCHEMA_VERSION,
                    "status": "blocked",
                    "blocked_by": BLOCKED_TASK,
                    "reason": "Markdown/Hermes -> PostgreSQL apply is disabled",
                    "postgresql": {"connected": False, "mutated": False},
                },
                sort_keys=True,
            ),
            file=sys.stderr,
        )
        return 2

    print(json.dumps(build_report(), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
