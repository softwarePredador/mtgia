#!/usr/bin/env python3
"""Safe preflight and reporting entrypoint for the Hermes optimizer loop.

This script intentionally does not apply deck swaps. It verifies that battle,
metadata, and optimizer prerequisites are healthy before a long optimization run.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"

DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_BATTLE = SCRIPT_DIR / "battle_analyst_v9.py"
DEFAULT_BATTLE_TEST = SCRIPT_DIR / "test_battle_analyst_v10_3.py"
DEFAULT_SLOT_OPTIMIZER = SCRIPT_DIR / "slot_optimizer.py"
DEFAULT_UNIVERSAL_OPTIMIZER = SCRIPT_DIR / "universal_optimizer.py"
DEFAULT_SYNC_METADATA = SCRIPT_DIR / "sync_pg_card_metadata_to_hermes.py"
DEFAULT_SYNC_META_DECKS = SCRIPT_DIR / "sync_pg_meta_decks_to_hermes.py"
DEFAULT_SYNC_BATTLE_RULES = SCRIPT_DIR / "sync_battle_card_rules_pg.py"
DEFAULT_EFFECT_COVERAGE_AUDIT = SCRIPT_DIR / "battle_effect_coverage_audit.py"

ESSENTIAL_TABLES = {
    "deck_cards",
    "learned_decks",
    "card_oracle_cache",
}


@dataclass
class CheckResult:
    name: str
    status: str
    detail: str

    @property
    def ok(self) -> bool:
        return self.status == "ok"


def run_command(command: list[str], cwd: Path | None = None) -> tuple[int, str]:
    try:
        completed = subprocess.run(
            command,
            cwd=str(cwd) if cwd else None,
            capture_output=True,
            text=True,
            timeout=180,
        )
    except FileNotFoundError as exc:
        return 127, str(exc)
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "") + "\n" + (exc.stderr or "")
        return 124, output.strip()

    output = (completed.stdout or "") + "\n" + (completed.stderr or "")
    return completed.returncode, output.strip()


def table_names(conn: sqlite3.Connection) -> set[str]:
    rows = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    ).fetchall()
    return {row[0] for row in rows}


def scalar(conn: sqlite3.Connection, query: str) -> int:
    row = conn.execute(query).fetchone()
    return int(row[0] or 0) if row else 0


def db_coverage(db_path: Path) -> dict[str, int]:
    with sqlite3.connect(db_path) as conn:
        tables = table_names(conn)
        if "card_oracle_cache" not in tables:
            return {}
        return {
            "oracle_cache_rows": scalar(conn, "SELECT COUNT(*) FROM card_oracle_cache"),
            "mana_cost_filled": scalar(
                conn,
                "SELECT COUNT(*) FROM card_oracle_cache "
                "WHERE mana_cost IS NOT NULL AND TRIM(mana_cost) <> ''",
            ),
            "oracle_text_filled": scalar(
                conn,
                "SELECT COUNT(*) FROM card_oracle_cache "
                "WHERE oracle_text IS NOT NULL AND TRIM(oracle_text) <> ''",
            ),
            "power_filled": scalar(
                conn,
                "SELECT COUNT(*) FROM card_oracle_cache "
                "WHERE power IS NOT NULL AND TRIM(power) <> ''",
            ),
            "toughness_filled": scalar(
                conn,
                "SELECT COUNT(*) FROM card_oracle_cache "
                "WHERE toughness IS NOT NULL AND TRIM(toughness) <> ''",
            ),
            "keywords_filled": scalar(
                conn,
                "SELECT COUNT(*) FROM card_oracle_cache "
                "WHERE keywords_json IS NOT NULL AND keywords_json NOT IN ('', '[]')",
            ),
        }


def run_preflight(args: argparse.Namespace) -> list[CheckResult]:
    checks: list[CheckResult] = []

    required_files = {
        "knowledge_db": args.db,
        "battle": args.battle,
        "battle_regression": args.battle_test,
        "slot_optimizer": args.slot_optimizer,
        "universal_optimizer": args.universal_optimizer,
        "meta_decks_sync": args.sync_meta_decks,
        "metadata_sync": args.sync_metadata,
        "battle_rules_sync": args.sync_battle_rules,
        "effect_coverage_audit": args.effect_coverage_audit,
    }
    for name, path in required_files.items():
        checks.append(
            CheckResult(
                name,
                "ok" if path.exists() else "error",
                str(path),
            )
        )

    if args.db.exists():
        try:
            with sqlite3.connect(args.db) as conn:
                tables = table_names(conn)
                missing = sorted(ESSENTIAL_TABLES - tables)
                checks.append(
                    CheckResult(
                        "sqlite_tables",
                        "ok" if not missing else "error",
                        "all essential tables present"
                        if not missing
                        else f"missing: {', '.join(missing)}",
                    )
                )

                deck_cards = scalar(conn, "SELECT COUNT(*) FROM deck_cards")
                learned_decks = scalar(conn, "SELECT COUNT(*) FROM learned_decks")
                checks.append(
                    CheckResult(
                        "sqlite_content",
                        "ok" if deck_cards > 0 and learned_decks > 0 else "error",
                        f"deck_cards={deck_cards}, learned_decks={learned_decks}",
                    )
                )
        except Exception as exc:
            checks.append(CheckResult("sqlite_open", "error", str(exc)))

    if not args.skip_tests:
        code, output = run_command(
            [
                sys.executable,
                "-m",
                "py_compile",
                str(args.battle),
                str(args.sync_metadata),
                str(args.sync_battle_rules),
            ]
        )
        checks.append(
            CheckResult(
                "python_compile",
                "ok" if code == 0 else "error",
                "battle, metadata sync and battle rules sync compile"
                if code == 0
                else output[-500:],
            )
        )

        code, output = run_command([sys.executable, str(args.battle_test)], cwd=SCRIPT_DIR)
        checks.append(
            CheckResult(
                "battle_regression",
                "ok" if code == 0 else "error",
                "test_battle_analyst_v10_3 passed"
                if code == 0
                else output[-1000:],
            )
        )

    coverage = db_coverage(args.db) if args.db.exists() else {}
    if coverage:
        cache_rows = coverage["oracle_cache_rows"]
        combat_rows = min(coverage["power_filled"], coverage["toughness_filled"])
        checks.append(
            CheckResult(
                "oracle_cache_coverage",
                "ok" if cache_rows > 0 and combat_rows > 0 else "warning",
                json.dumps(coverage, sort_keys=True),
            )
        )

    return checks


def render_report(checks: list[CheckResult]) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    status = "approved" if all(check.ok for check in checks) else "blocked"
    lines = [
        "# Hermes Master Optimizer Preflight",
        "",
        f"- generated_at: {now}",
        f"- status: {status}",
        "",
        "## Checks",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in checks:
        detail = check.detail.replace("\n", " ").replace("|", "\\|")
        lines.append(f"| {check.name} | {check.status} | {detail} |")

    lines.extend(
        [
            "",
            "## Next action",
            "",
            "- If status is `approved`, run baseline battle and isolated slot scan.",
            "- If status is `blocked`, fix battle/metadata before running optimizer.",
            "- Do not apply swaps from quick phase automatically.",
        ]
    )
    return "\n".join(lines) + "\n"


def write_report(markdown: str) -> Path:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    path = REPORT_DIR / f"master_optimizer_preflight_{stamp}.md"
    path.write_text(markdown, encoding="utf-8")
    return path


def print_plan() -> None:
    print(
        """Hermes Master Optimizer Loop
1. Preflight: compile battle, run regression, inspect SQLite/cache.
2. Baseline: run battle without swaps and persist current winrate.
3. Slot scan: test one swap at a time and always restore baseline.
4. Full confirm: retest promising swaps with more games.
5. Quality gate: validate mana, curve, roles, bracket, lands, commander plan.
6. Forensic audit: inspect one fixed-seed battle event by event and flag rule gaps.
7. Replay audit: inspect wrong decisions before trusting optimizer output.
8. Handoff: write approved swaps, risks, evidence, and battle fixes.
"""
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", action="store_true")
    parser.add_argument("--preflight", action="store_true")
    parser.add_argument("--report", action="store_true")
    parser.add_argument("--skip-tests", action="store_true")
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--battle", type=Path, default=DEFAULT_BATTLE)
    parser.add_argument("--battle-test", type=Path, default=DEFAULT_BATTLE_TEST)
    parser.add_argument("--slot-optimizer", type=Path, default=DEFAULT_SLOT_OPTIMIZER)
    parser.add_argument(
        "--universal-optimizer",
        type=Path,
        default=DEFAULT_UNIVERSAL_OPTIMIZER,
    )
    parser.add_argument("--sync-metadata", type=Path, default=DEFAULT_SYNC_METADATA)
    parser.add_argument("--sync-meta-decks", type=Path, default=DEFAULT_SYNC_META_DECKS)
    parser.add_argument("--sync-battle-rules", type=Path, default=DEFAULT_SYNC_BATTLE_RULES)
    parser.add_argument("--effect-coverage-audit", type=Path, default=DEFAULT_EFFECT_COVERAGE_AUDIT)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.plan or not args.preflight:
        print_plan()
    if not args.preflight:
        return 0

    checks = run_preflight(args)
    markdown = render_report(checks)
    print(markdown)
    if args.report:
        path = write_report(markdown)
        print(f"Report written: {path}")

    return 0 if all(check.ok for check in checks) else 1


if __name__ == "__main__":
    raise SystemExit(main())
