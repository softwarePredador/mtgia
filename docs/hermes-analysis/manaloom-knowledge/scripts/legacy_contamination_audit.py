#!/usr/bin/env python3
"""Audit broad ManaLoom surfaces for reintroduced legacy contamination.

This audit is read-only. It scans active code, tests, operational scripts, and
current handoff docs for old bug classes that have already caused drift:

- stale Hermes SQLite path defaults;
- hardcoded PostgreSQL fallback credentials/ports;
- historical `deck_6` defaults leaking into current Lorehold work;
- direct consumption of legacy `ranked_decks` artifacts; and
- raw EDHREC `inclusion` count scoring.

Existing historical occurrences are allowed only through the checked-in
baseline. New occurrences fail until they are removed or intentionally added to
the baseline with a review note.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"
BASELINE_PATH = DOCS_DIR / "LEGACY_CONTAMINATION_BASELINE_2026-06-30.json"

SCAN_ROOTS = [
    REPO_ROOT / "server" / "lib",
    REPO_ROOT / "server" / "routes",
    REPO_ROOT / "server" / "bin",
    REPO_ROOT / "server" / "test",
    SCRIPT_DIR,
]

CURRENT_DOCS = [
    DOCS_DIR / "README.md",
    DOCS_DIR / "MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md",
    DOCS_DIR / "MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md",
    DOCS_DIR / "DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md",
    DOCS_DIR / "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
    DOCS_DIR / "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
    DOCS_DIR / "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
]

SCAN_SUFFIXES = {".dart", ".md", ".py", ".sh"}
EXCLUDED_DIR_NAMES = {
    ".dart_tool",
    ".git",
    "__pycache__",
    "build",
    "master_optimizer_reports",
    "node_modules",
}
EXCLUDED_FILE_NAMES = {
    Path(__file__).name,
    "test_legacy_contamination_audit.py",
}


@dataclass(frozen=True)
class PatternSpec:
    category: str
    description: str
    regex: re.Pattern[str]


PATTERN_SPECS = [
    PatternSpec(
        "stale_sqlite_path",
        "Stale or sibling Hermes knowledge.db path/default.",
        re.compile(
            r"("
            r"SCRIPT_DIR\s*/\s*['\"]knowledge\.db['\"]"
            r"|scripts/knowledge\.db"
            r"|/opt/data/workspace/mtgia/[^\s'\"`]*knowledge\.db"
            r"|DEFAULT(?:_SQLITE)?_DB\s*=\s*[^#\n]*knowledge\.db"
            r"|DB\s*=\s*[^#\n]*knowledge\.db"
            r"|os\.path\.join\([^#\n]*['\"]scripts['\"][^#\n]*['\"]knowledge\.db['\"]"
            r")"
        ),
    ),
    PatternSpec(
        "hardcoded_pg_fallback",
        "Hardcoded old PostgreSQL host, port, database, or fallback env default.",
        re.compile(
            r"("
            r"143\.198\.230\.247"
            r"|(?:PGPORT|DB_PORT)[^#\n]*5433"
            r"|(?:PGDATABASE|DB_NAME)[^#\n]*halder"
            r"|(?:PGHOST|DB_HOST)[^#\n]*143\.198\.230\.247"
            r")"
        ),
    ),
    PatternSpec(
        "legacy_deck6_current_default",
        "Historical deck 6 default/baseline reference.",
        re.compile(
            r"("
            r"DEFAULT_BASELINE_DECK_ID\s*=\s*6\b"
            r"|\bdeck_id\s*=\s*6\b"
            r"|\bdeck_id=6\b"
            r"|\bdeck_6\b"
            r"|\bbaseline_squee_champion\b"
            r")"
        ),
    ),
    PatternSpec(
        "legacy_ranked_decks_schema",
        "Direct legacy ranked_decks schema reference.",
        re.compile(r"\branked_decks\b"),
    ),
    PatternSpec(
        "raw_edhrec_inclusion_score",
        "Raw EDHREC inclusion count used as a score instead of inclusionRate.",
        re.compile(r"(card\.inclusion\s*[+*/-]|\binclusion\s*\*\s*20\b)"),
    ),
]


@dataclass(frozen=True)
class LegacyHit:
    category: str
    file: str
    line: int
    snippet: str
    fingerprint: str

    def as_dict(self) -> dict[str, Any]:
        return {
            "category": self.category,
            "file": self.file,
            "line": self.line,
            "snippet": self.snippet,
            "fingerprint": self.fingerprint,
        }


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def iter_files(roots: Iterable[Path] | None = None) -> list[Path]:
    roots = list(roots or [*SCAN_ROOTS, *CURRENT_DOCS])
    files: set[Path] = set()
    for root in roots:
        if not root.exists():
            continue
        if root.is_file():
            if root.suffix in SCAN_SUFFIXES and root.name not in EXCLUDED_FILE_NAMES:
                files.add(root)
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in SCAN_SUFFIXES:
                continue
            if path.name in EXCLUDED_FILE_NAMES:
                continue
            if any(part in EXCLUDED_DIR_NAMES for part in path.parts):
                continue
            files.add(path)
    return sorted(files)


def fingerprint(category: str, file: str, line_text: str) -> str:
    digest = hashlib.sha256(f"{category}|{file}|{line_text.strip()}".encode("utf-8")).hexdigest()
    return digest[:16]


def scan_file(path: Path) -> list[LegacyHit]:
    relative = rel(path)
    text = path.read_text(encoding="utf-8", errors="replace")
    hits: list[LegacyHit] = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        for spec in PATTERN_SPECS:
            if not spec.regex.search(line):
                continue
            snippet = line.strip()
            if len(snippet) > 220:
                snippet = snippet[:217] + "..."
            hits.append(
                LegacyHit(
                    category=spec.category,
                    file=relative,
                    line=line_no,
                    snippet=snippet,
                    fingerprint=fingerprint(spec.category, relative, line),
                )
            )
    return hits


def scan(roots: Iterable[Path] | None = None) -> tuple[list[Path], list[LegacyHit]]:
    files = iter_files(roots)
    hits: list[LegacyHit] = []
    for path in files:
        hits.extend(scan_file(path))
    return files, hits


def counts_by_category_file(hits: Iterable[LegacyHit]) -> dict[str, dict[str, int]]:
    counts: dict[str, dict[str, int]] = {}
    for hit in hits:
        category_counts = counts.setdefault(hit.category, {})
        category_counts[hit.file] = category_counts.get(hit.file, 0) + 1
    return {
        category: dict(sorted(file_counts.items()))
        for category, file_counts in sorted(counts.items())
    }


def load_baseline(path: Path = BASELINE_PATH) -> dict[str, Any] | None:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def baseline_counts(baseline: Mapping[str, Any] | None) -> dict[str, dict[str, int]]:
    if not baseline:
        return {}
    raw = baseline.get("allowed_max_by_category_file", {})
    counts: dict[str, dict[str, int]] = {}
    for category, files in raw.items():
        if not isinstance(files, Mapping):
            continue
        counts[str(category)] = {str(file): int(count) for file, count in files.items()}
    return counts


def current_baseline_payload(hits: Iterable[LegacyHit]) -> dict[str, Any]:
    return {
        "status": "legacy_contamination_baseline",
        "generated_at": utc_now(),
        "policy": (
            "Counts are maximum tolerated occurrences for already-reviewed "
            "legacy references. New or increased occurrences fail "
            "legacy_contamination_audit.py."
        ),
        "allowed_max_by_category_file": counts_by_category_file(hits),
    }


def compare_counts(
    current: Mapping[str, Mapping[str, int]],
    allowed: Mapping[str, Mapping[str, int]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    excess: list[dict[str, Any]] = []
    resolved: list[dict[str, Any]] = []

    categories = sorted(set(current) | set(allowed))
    for category in categories:
        current_files = current.get(category, {})
        allowed_files = allowed.get(category, {})
        files = sorted(set(current_files) | set(allowed_files))
        for file in files:
            current_count = int(current_files.get(file, 0))
            allowed_count = int(allowed_files.get(file, 0))
            if current_count > allowed_count:
                excess.append(
                    {
                        "category": category,
                        "file": file,
                        "current_count": current_count,
                        "allowed_count": allowed_count,
                        "excess_count": current_count - allowed_count,
                    }
                )
            elif current_count < allowed_count:
                resolved.append(
                    {
                        "category": category,
                        "file": file,
                        "current_count": current_count,
                        "allowed_count": allowed_count,
                        "resolved_count": allowed_count - current_count,
                    }
                )
    return excess, resolved


def sample_hits_for_excess(
    hits: Iterable[LegacyHit],
    excess: Iterable[Mapping[str, Any]],
    limit_per_file: int = 5,
) -> list[dict[str, Any]]:
    excess_keys = {(str(item["category"]), str(item["file"])) for item in excess}
    samples: list[dict[str, Any]] = []
    counts: dict[tuple[str, str], int] = {}
    for hit in hits:
        key = (hit.category, hit.file)
        if key not in excess_keys:
            continue
        count = counts.get(key, 0)
        if count >= limit_per_file:
            continue
        samples.append(hit.as_dict())
        counts[key] = count + 1
    return samples


def build_report(
    *,
    roots: Iterable[Path] | None = None,
    baseline_path: Path = BASELINE_PATH,
) -> dict[str, Any]:
    files, hits = scan(roots)
    baseline = load_baseline(baseline_path)
    current_counts = counts_by_category_file(hits)
    allowed_counts = baseline_counts(baseline)
    excess, resolved = compare_counts(current_counts, allowed_counts)
    missing_baseline = baseline is None
    status = "fail" if missing_baseline or excess else "pass"
    category_totals = {
        category: sum(file_counts.values())
        for category, file_counts in current_counts.items()
    }
    return {
        "generated_at": utc_now(),
        "status": status,
        "summary": {
            "scanned_file_count": len(files),
            "hit_count": len(hits),
            "category_totals": dict(sorted(category_totals.items())),
            "excess_group_count": len(excess),
            "resolved_group_count": len(resolved),
            "baseline_path": str(baseline_path),
            "baseline_loaded": baseline is not None,
        },
        "pattern_descriptions": {
            spec.category: spec.description for spec in PATTERN_SPECS
        },
        "excess": excess,
        "excess_hit_samples": sample_hits_for_excess(hits, excess),
        "resolved_baseline_groups": resolved,
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Legacy Contamination Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "## Pattern Totals",
        "",
        "| Category | Hits | Meaning |",
        "| --- | ---: | --- |",
    ]
    totals = report["summary"].get("category_totals", {})
    descriptions = report.get("pattern_descriptions", {})
    for category in sorted(descriptions):
        lines.append(
            f"| `{category}` | {int(totals.get(category, 0))} | {descriptions[category]} |"
        )

    lines.extend(["", "## New Or Increased Legacy Groups", ""])
    if report["excess"]:
        lines.extend(["| Category | File | Current | Allowed | Excess |", "| --- | --- | ---: | ---: | ---: |"])
        for item in report["excess"]:
            lines.append(
                f"| `{item['category']}` | `{item['file']}` | {item['current_count']} | "
                f"{item['allowed_count']} | {item['excess_count']} |"
            )
    else:
        lines.append("None.")

    lines.extend(["", "## Excess Hit Samples", ""])
    if report["excess_hit_samples"]:
        lines.extend(["| Category | File | Line | Snippet |", "| --- | --- | ---: | --- |"])
        for hit in report["excess_hit_samples"]:
            snippet = str(hit["snippet"]).replace("|", "\\|")
            lines.append(f"| `{hit['category']}` | `{hit['file']}` | {hit['line']} | `{snippet}` |")
    else:
        lines.append("None.")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "legacy_contamination_audit_20260630",
    )
    parser.add_argument("--baseline", type=Path, default=BASELINE_PATH)
    parser.add_argument(
        "--print-current-baseline",
        action="store_true",
        help="Print a baseline payload from the current scan and exit.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.print_current_baseline:
        _, hits = scan()
        print(json.dumps(current_baseline_payload(hits), indent=2, sort_keys=True))
        return 0

    report = build_report(baseline_path=args.baseline)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
