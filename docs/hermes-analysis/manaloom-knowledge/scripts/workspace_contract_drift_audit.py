#!/usr/bin/env python3
"""Audit residual workspace drift against the current ManaLoom data contract.

This audit is intentionally static and read-only. It checks the files that are
part of the active battle/deckbuilding/Hermes sync surface for:

- stale absolute knowledge.db paths;
- hardcoded PostgreSQL production fallbacks;
- crons that skip the required PG -> Hermes -> SQLite sync contract;
- accidental stale sibling SQLite databases; and
- unsafe direct reads from one-to-many card rule/tag tables.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
ACTIVE_SQLITE_DB = SCRIPT_DIR / "knowledge.db"
STALE_SIBLING_SQLITE_DB = SCRIPT_DIR.parent / "knowledge.db"

ACTIVE_FILES = [
    SCRIPT_DIR / "battle_analyst_v9.py",
    SCRIPT_DIR / "known_cards_generator_cron.sh",
    SCRIPT_DIR / "known_cards_validator_cron.sh",
    SCRIPT_DIR / "master_optimizer_preflight_cron.sh",
    SCRIPT_DIR / "master_optimizer_end_to_end.sh",
    SCRIPT_DIR / "master_optimizer_auto_cycle_cron.sh",
    SCRIPT_DIR / "master_optimizer_slot_scan_cron.sh",
    SCRIPT_DIR / "sync_pg_card_metadata_to_hermes.py",
    SCRIPT_DIR / "sync_pg_legalities.py",
    SCRIPT_DIR / "sync_pg_target_deck_to_hermes.py",
    SCRIPT_DIR / "sync_pg_meta_decks_to_hermes.py",
    SCRIPT_DIR / "sync_battle_card_rules_pg.py",
    SCRIPT_DIR / "generate_known_cards.py",
    SCRIPT_DIR / "kc_validator.py",
    SCRIPT_DIR / "_mana_validator.py",
    SCRIPT_DIR / "_update_cron_status.py",
    SCRIPT_DIR / "wincon_pipeline.py",
    SCRIPT_DIR / "import_lorehold_decks.py",
    SCRIPT_DIR / "lorehold_canonical_deck_snapshot.py",
    SCRIPT_DIR / "validate_deck_legalities.py",
    SCRIPT_DIR / "pg_hermes_sqlite_contract_audit.py",
    REPO_ROOT / "server" / "bin" / "sync_hermes_learned_deck.sh",
    REPO_ROOT / "server" / "bin" / "pull_learning_events.py",
    REPO_ROOT / "server" / "bin" / "register_commanders.py",
]

FORBIDDEN_SNIPPETS = [
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
    "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/knowledge.db",
    'os.environ.get("PGHOST", "143.198.230.247")',
    "os.environ.get('PGHOST', '143.198.230.247')",
    'os.environ.get("DB_HOST", "143.198.230.247")',
    "os.environ.get('DB_HOST', '143.198.230.247')",
    'os.environ.get("PGPORT", "5433")',
    "os.environ.get('PGPORT', '5433')",
    'os.environ.get("DB_PORT", "5433")',
    "os.environ.get('DB_PORT', '5433')",
    'os.environ.get("PGDATABASE", "halder")',
    "os.environ.get('PGDATABASE', 'halder')",
    'os.environ.get("DB_NAME", "halder")',
    "os.environ.get('DB_NAME', 'halder')",
]

PATH_CONTRACT_SNIPPETS = {
    "battle_analyst_v9.py": ["MANALOOM_KNOWLEDGE_DB", "_resolve_knowledge_db"],
    "sync_pg_card_metadata_to_hermes.py": ["MANALOOM_KNOWLEDGE_DB"],
    "sync_pg_legalities.py": ["MANALOOM_KNOWLEDGE_DB"],
    "sync_pg_target_deck_to_hermes.py": ["MANALOOM_KNOWLEDGE_DB"],
    "sync_pg_meta_decks_to_hermes.py": ["MANALOOM_KNOWLEDGE_DB"],
    "sync_battle_card_rules_pg.py": ["MANALOOM_KNOWLEDGE_DB"],
    "generate_known_cards.py": ["MANALOOM_HERMES_SCRIPT_DIR"],
    "kc_validator.py": ["MANALOOM_HERMES_SCRIPT_DIR"],
    "_mana_validator.py": ["MANALOOM_KNOWLEDGE_DB"],
    "_update_cron_status.py": ["MANALOOM_KNOWLEDGE_DB"],
    "wincon_pipeline.py": ["MANALOOM_KNOWLEDGE_DB", "DATABASE_URL"],
    "import_lorehold_decks.py": ["MANALOOM_KNOWLEDGE_DB", "--sqlite-db"],
    "lorehold_canonical_deck_snapshot.py": ["MANALOOM_KNOWLEDGE_DB", "HERMES_KNOWLEDGE_BACKUP_DIR"],
    "validate_deck_legalities.py": ["MANALOOM_KNOWLEDGE_DB"],
    "sync_hermes_learned_deck.sh": ["MANALOOM_REPO", "MANALOOM_KNOWLEDGE_DB", "MANALOOM_HERMES_SCRIPT_DIR"],
    "pull_learning_events.py": ["MANALOOM_KNOWLEDGE_DB", "PGHOST", "PGDATABASE"],
    "register_commanders.py": ["MANALOOM_KNOWLEDGE_DB", "DEFAULT_KNOWLEDGE_DB"],
}

CRON_SEQUENCE_SNIPPETS = {
    "known_cards_generator_cron.sh": [
        "MANALOOM_KNOWLEDGE_DB",
        "sync_pg_legalities.py",
        "sync_pg_card_metadata_to_hermes.py",
        "sync_battle_card_rules_pg.py",
        "pg_hermes_sqlite_contract_audit.py",
        "generate_known_cards.py",
    ],
    "known_cards_validator_cron.sh": [
        "MANALOOM_KNOWLEDGE_DB",
        "sync_pg_legalities.py",
        "sync_pg_card_metadata_to_hermes.py",
        "sync_battle_card_rules_pg.py",
        "pg_hermes_sqlite_contract_audit.py",
        "kc_validator.py",
    ],
    "master_optimizer_preflight_cron.sh": [
        "MANALOOM_KNOWLEDGE_DB",
        "sync_pg_meta_decks_to_hermes.py",
        "sync_pg_target_deck_to_hermes.py",
        "sync_pg_legalities.py",
        "sync_pg_card_metadata_to_hermes.py",
        "sync_battle_card_rules_pg.py",
        "pg_hermes_sqlite_contract_audit.py",
        "master_optimizer_loop.py",
    ],
    "master_optimizer_end_to_end.sh": [
        "MANALOOM_KNOWLEDGE_DB",
        "sync_pg_legalities.py",
        "sync_pg_card_metadata_to_hermes.py",
        "sync_battle_card_rules_pg.py",
        "pg_hermes_sqlite_contract_audit.py",
        "master_optimizer_loop.py",
    ],
    "master_optimizer_auto_cycle_cron.sh": [
        "MANALOOM_KNOWLEDGE_DB",
        "sync_pg_meta_decks_to_hermes.py",
        "sync_pg_legalities.py",
        "sync_pg_card_metadata_to_hermes.py",
        "sync_battle_card_rules_pg.py",
        "pg_hermes_sqlite_contract_audit.py",
        "slot_optimizer.py",
    ],
    "master_optimizer_slot_scan_cron.sh": [
        "MANALOOM_KNOWLEDGE_DB",
        "sync_pg_legalities.py",
        "sync_pg_card_metadata_to_hermes.py",
        "sync_battle_card_rules_pg.py",
        "pg_hermes_sqlite_contract_audit.py",
        "slot_optimizer.py",
    ],
}

ONE_TO_MANY_CARD_TABLES = (
    "card_function_tags",
    "card_semantic_tags_v2",
    "card_battle_rules",
)
CARD_INTELLIGENCE_JOIN_RE = re.compile(
    r"\b(?:LEFT\s+JOIN|JOIN)\s+card_intelligence_snapshot"
    r"(?:\s+(?:AS\s+)?([a-zA-Z_][a-zA-Z0-9_]*))?\s+ON\b",
    re.IGNORECASE,
)


@dataclass
class Check:
    name: str
    status: str
    detail: str
    data: dict[str, Any] | None = None

    def as_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "name": self.name,
            "status": self.status,
            "detail": self.detail,
        }
        if self.data is not None:
            payload["data"] = self.data
        return payload


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def check_active_files_exist(files: Iterable[Path] = ACTIVE_FILES) -> Check:
    file_list = list(files)
    missing = [rel(path) for path in file_list if not path.exists()]
    if missing:
        return Check("active_files.exist", "fail", f"missing={json.dumps(missing)}")
    return Check("active_files.exist", "pass", f"count={len(file_list)}")


def check_forbidden_snippets(
    files: Iterable[Path] = ACTIVE_FILES,
    snippets: Iterable[str] = FORBIDDEN_SNIPPETS,
) -> Check:
    hits: list[dict[str, str]] = []
    for path in files:
        text = read_text(path)
        for snippet in snippets:
            if snippet in text:
                hits.append({"file": rel(path), "snippet": snippet})
    if hits:
        return Check(
            "active_files.no_stale_absolute_or_pg_fallbacks",
            "fail",
            f"hits={len(hits)}",
            {"hits": hits},
        )
    return Check("active_files.no_stale_absolute_or_pg_fallbacks", "pass", "no hits")


def check_path_contracts() -> list[Check]:
    checks: list[Check] = []
    files_by_name = {path.name: path for path in ACTIVE_FILES}
    for file_name, snippets in PATH_CONTRACT_SNIPPETS.items():
        path = files_by_name.get(file_name)
        if path is None or not path.exists():
            checks.append(Check(f"path_contract.{file_name}", "fail", "missing_file"))
            continue
        text = read_text(path)
        missing = [snippet for snippet in snippets if snippet not in text]
        if missing:
            checks.append(
                Check(
                    f"path_contract.{file_name}",
                    "fail",
                    "missing=" + json.dumps(missing, ensure_ascii=True),
                )
            )
        else:
            checks.append(Check(f"path_contract.{file_name}", "pass", rel(path)))
    return checks


def check_cron_sequence(file_name: str, snippets: list[str]) -> Check:
    path = SCRIPT_DIR / file_name
    if not path.exists():
        return Check(f"cron_sequence.{file_name}", "fail", "missing_file")
    text = read_text(path)
    missing = [snippet for snippet in snippets if snippet not in text]
    if missing:
        return Check(
            f"cron_sequence.{file_name}",
            "fail",
            "missing=" + json.dumps(missing, ensure_ascii=True),
        )
    positions = [text.find(snippet) for snippet in snippets]
    out_of_order = [
        snippets[index]
        for index in range(1, len(snippets))
        if positions[index] < positions[index - 1]
    ]
    if out_of_order:
        return Check(
            f"cron_sequence.{file_name}",
            "fail",
            "out_of_order=" + json.dumps(out_of_order, ensure_ascii=True),
        )
    return Check(f"cron_sequence.{file_name}", "pass", "ordered")


def check_cron_sequences() -> list[Check]:
    return [
        check_cron_sequence(file_name, snippets)
        for file_name, snippets in CRON_SEQUENCE_SNIPPETS.items()
    ]


def check_sqlite_location() -> list[Check]:
    checks: list[Check] = []
    if not ACTIVE_SQLITE_DB.exists():
        checks.append(
            Check(
                "sqlite.active_knowledge_db_exists",
                "fail",
                f"missing:{rel(ACTIVE_SQLITE_DB)}",
            )
        )
    else:
        checks.append(
            Check(
                "sqlite.active_knowledge_db_exists",
                "pass",
                f"{rel(ACTIVE_SQLITE_DB)} size={ACTIVE_SQLITE_DB.stat().st_size}",
            )
        )

    if not STALE_SIBLING_SQLITE_DB.exists():
        checks.append(Check("sqlite.no_stale_sibling_knowledge_db", "pass", "absent"))
    elif STALE_SIBLING_SQLITE_DB.stat().st_size == 0:
        checks.append(
            Check(
                "sqlite.no_stale_sibling_knowledge_db",
                "fail",
                f"zero_byte:{rel(STALE_SIBLING_SQLITE_DB)}",
            )
        )
    else:
        checks.append(
            Check(
                "sqlite.no_stale_sibling_knowledge_db",
                "warn",
                f"present_nonzero:{rel(STALE_SIBLING_SQLITE_DB)}",
            )
        )
    return checks


def query_consumer_files() -> list[Path]:
    roots = [
        REPO_ROOT / "server" / "lib",
        REPO_ROOT / "server" / "routes",
        REPO_ROOT / "server" / "bin",
        SCRIPT_DIR,
    ]
    files: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        for suffix in ("*.dart", "*.py"):
            files.extend(root.rglob(suffix))
    excluded_names = {
        "audit_data_model_links.dart",
        Path(__file__).name,
    }
    return sorted(
        path
        for path in set(files)
        if not path.name.startswith("test_") and path.name not in excluded_names
    )


def statement_context(text: str, start: int, end: int) -> str:
    left = max(text.rfind("\n\n", 0, start), text.rfind("WITH ", 0, start), text.rfind("SELECT", 0, start))
    if left < 0:
        left = max(0, start - 600)
    right_candidates = [
        pos
        for pos in (
            text.find("\n\n", end),
            text.find("''')", end),
            text.find('""")', end),
            text.find(";", end),
        )
        if pos != -1
    ]
    right = min(right_candidates) if right_candidates else min(len(text), end + 900)
    return text[left:right]


def direct_join_issues(files: Iterable[Path] | None = None) -> list[dict[str, Any]]:
    files = list(files or query_consumer_files())
    pattern = re.compile(
        r"\b(?:LEFT\s+JOIN|JOIN)\s+("
        + "|".join(re.escape(table) for table in ONE_TO_MANY_CARD_TABLES)
        + r")\b",
        re.IGNORECASE,
    )
    issues: list[dict[str, Any]] = []
    for path in files:
        if path.name == Path(__file__).name:
            continue
        text = read_text(path)
        for match in pattern.finditer(text):
            context = statement_context(text, match.start(), match.end())
            upper = context.upper()
            aggregated = any(token in upper for token in ("ARRAY_AGG", "JSONB_AGG", "JSON_AGG"))
            grouped = "GROUP BY" in upper
            if aggregated and grouped:
                continue
            line = text.count("\n", 0, match.start()) + 1
            issues.append(
                {
                    "file": rel(path),
                    "line": line,
                    "table": match.group(1),
                    "reason": "direct one-to-many join without aggregate/group boundary",
                }
            )
    return issues


def check_direct_join_consumers() -> Check:
    issues = direct_join_issues()
    if issues:
        return Check(
            "query_consumers.no_unsafe_direct_1n_card_joins",
            "fail",
            f"issues={len(issues)}",
            {"issues": issues},
        )
    return Check("query_consumers.no_unsafe_direct_1n_card_joins", "pass", "no unsafe joins")


def card_intelligence_snapshot_join_findings(
    files: Iterable[Path] | None = None,
) -> dict[str, Any]:
    files = list(files or query_consumer_files())
    issues: list[dict[str, Any]] = []
    canonical_alias_count = 0
    compatibility_alias_count = 0
    compatibility_alias_samples: list[dict[str, Any]] = []
    for path in files:
        text = read_text(path)
        for match in CARD_INTELLIGENCE_JOIN_RE.finditer(text):
            alias = match.group(1) or "card_intelligence_snapshot"
            context = statement_context(text, match.start(), match.end())
            line = text.count("\n", 0, match.start()) + 1
            upper_context = context.upper()
            on_index = upper_context.find(" ON ")
            on_clause = context[on_index:] if on_index >= 0 else context
            alias_card_id = re.search(
                rf"\b{re.escape(alias)}\.card_id\b",
                on_clause,
                re.IGNORECASE,
            )
            alias_id = re.search(
                rf"\b{re.escape(alias)}\.id\b",
                on_clause,
                re.IGNORECASE,
            )
            on_without_snapshot_alias = re.sub(
                rf"\b{re.escape(alias)}\.(?:card_id|id)\b",
                "",
                on_clause,
                flags=re.IGNORECASE,
            )
            other_identity = re.search(
                r"\b[a-zA-Z_][a-zA-Z0-9_]*\.(?:card_id|id)\b",
                on_without_snapshot_alias,
                re.IGNORECASE,
            )
            if alias_card_id:
                canonical_alias_count += 1
            elif alias_id:
                compatibility_alias_count += 1
                if len(compatibility_alias_samples) < 10:
                    compatibility_alias_samples.append(
                        {
                            "file": rel(path),
                            "line": line,
                            "alias": alias,
                            "field": "id",
                        }
                    )
            if not (alias_card_id or alias_id) or not other_identity:
                issues.append(
                    {
                        "file": rel(path),
                        "line": line,
                        "alias": alias,
                        "reason": "card_intelligence_snapshot join is not anchored on card identity fields",
                    }
                )
    return {
        "issues": issues,
        "canonical_alias_count": canonical_alias_count,
        "compatibility_alias_count": compatibility_alias_count,
        "compatibility_alias_samples": compatibility_alias_samples,
    }


def check_card_intelligence_snapshot_joins() -> Check:
    findings = card_intelligence_snapshot_join_findings()
    issues = findings["issues"]
    if issues:
        return Check(
            "query_consumers.card_intelligence_snapshot_identity_joins",
            "fail",
            f"issues={len(issues)}",
            findings,
        )
    return Check(
        "query_consumers.card_intelligence_snapshot_identity_joins",
        "pass",
        (
            "canonical_card_id_joins="
            f"{findings['canonical_alias_count']} compatibility_id_alias_joins="
            f"{findings['compatibility_alias_count']}"
        ),
        findings,
    )


def build_report() -> dict[str, Any]:
    checks: list[Check] = [
        check_active_files_exist(),
        check_forbidden_snippets(),
        *check_path_contracts(),
        *check_cron_sequences(),
        *check_sqlite_location(),
        check_direct_join_consumers(),
        check_card_intelligence_snapshot_joins(),
    ]
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    status = "fail" if status_counts.get("fail", 0) else "pass"
    return {
        "generated_at": utc_now(),
        "status": status,
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
            "active_file_count": len(ACTIVE_FILES),
        },
        "sqlite_paths": {
            "active": str(ACTIVE_SQLITE_DB),
            "stale_sibling": str(STALE_SIBLING_SQLITE_DB),
        },
        "checks": [check.as_dict() for check in checks],
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Workspace Contract Drift Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        f"- Active SQLite: `{report['sqlite_paths']['active']}`",
        f"- Stale sibling SQLite: `{report['sqlite_paths']['stale_sibling']}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "workspace_contract_drift_audit_20260629",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report()
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
