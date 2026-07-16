#!/usr/bin/env python3
"""Audit retained ManaLoom report data artifacts.

The product truth is PostgreSQL/backend plus executable runtime code. The
`master_optimizer_reports` tree is not a durable data lake. This audit keeps
that boundary explicit by flagging raw report artifacts that are tracked but not
referenced by current scripts/contracts, and by surfacing ignored local
artifacts left on disk.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"

RAW_REPORT_SUFFIXES = {".json", ".jsonl", ".sql", ".out", ".txt", ".db", ".log", ".tsv", ".err"}

SQL_PACKAGE_ROLES = frozenset({"precheck", "apply", "postcheck", "rollback"})
SQL_PACKAGE_ROLE_RE = re.compile(
    r"^(?P<prefix>.+)_(?P<role>precheck|apply|postcheck|rollback)\.sql$"
)

ACTIVE_REFERENCE_ROOTS = (
    DOCS_DIR / "manaloom-knowledge" / "scripts",
    REPO_ROOT / "scripts",
    REPO_ROOT / "server" / "bin",
    REPO_ROOT / "server" / "lib",
    REPO_ROOT / "server" / "routes",
    REPO_ROOT / "server" / "test",
    REPO_ROOT / "app" / "lib",
    REPO_ROOT / "app" / "test",
    REPO_ROOT / "app" / "integration_test",
    REPO_ROOT / ".github",
)

RETENTION_MANIFEST_FILE = REPORT_DIR / "README.md"
RETENTION_JUSTIFICATION_PREFIX = "Retention justification:"
PENDING_LOCAL_HASH_LABEL = "pending-local-sha256:"

CURRENT_CONTRACT_FILES = (
    DOCS_DIR / "README.md",
    DOCS_DIR / "MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md",
    DOCS_DIR / "MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md",
    DOCS_DIR / "APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md",
    DOCS_DIR / "NEW_SERVER_POSTGRES_WORKFLOW_2026-07-06.md",
    DOCS_DIR / "DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md",
    DOCS_DIR / "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
    DOCS_DIR / "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
    DOCS_DIR / "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
    DOCS_DIR / "MANALOOM_DEEP_AI_DATA_COHERENCE_VALIDATION_2026-07-06.md",
    DOCS_DIR / "RULE_COMPETING_SCOPE_CLEANUP_EVIDENCE_2026-07-14.md",
    DOCS_DIR / "PROJECT_REVALIDATION_AND_GLOBAL_QUEUE_2026-07-14.md",
)


@dataclass(frozen=True)
class Check:
    name: str
    status: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"name": self.name, "status": self.status, "detail": self.detail}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def git_ls_files(path: Path) -> list[Path]:
    output = subprocess.check_output(
        ["git", "-C", str(REPO_ROOT), "ls-files", str(path.relative_to(REPO_ROOT))],
        text=True,
    )
    return [REPO_ROOT / line for line in output.splitlines() if line.strip()]


def tracked_report_raw_files() -> list[Path]:
    return [
        path
        for path in git_ls_files(REPORT_DIR)
        if path.is_file() and path.suffix in RAW_REPORT_SUFFIXES
    ]


def active_reference_files() -> list[Path]:
    files: set[Path] = set()
    for root in ACTIVE_REFERENCE_ROOTS:
        if not root.exists():
            continue
        for path in git_ls_files(root):
            if path.exists() and path.is_file() and not str(path).startswith(str(REPORT_DIR) + "/"):
                files.add(path)
    for path in CURRENT_CONTRACT_FILES:
        if path.exists() and path.is_file():
            files.add(path)
    return sorted(files)


def read_active_reference_text() -> str:
    chunks: list[str] = []
    for path in active_reference_files():
        try:
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            continue
    return "\n".join(chunks)


def extract_raw_reference_tokens(text: str) -> set[str]:
    referenced_tokens = set(
        re.findall(
            r"[\w./-]+\.(?:json|jsonl|sql|out|txt|db|log|tsv|err)",
            text,
        )
    )
    referenced_tokens.update(Path(token).name for token in list(referenced_tokens))
    return referenced_tokens


def retention_manifest_justification() -> str | None:
    if not RETENTION_MANIFEST_FILE.exists():
        return None
    for line in RETENTION_MANIFEST_FILE.read_text(
        encoding="utf-8", errors="ignore"
    ).splitlines():
        if line.startswith(RETENTION_JUSTIFICATION_PREFIX):
            justification = line.removeprefix(RETENTION_JUSTIFICATION_PREFIX).strip()
            return justification or None
    return None


def retention_manifest_paths() -> set[str]:
    if not RETENTION_MANIFEST_FILE.exists():
        return set()
    text = RETENTION_MANIFEST_FILE.read_text(encoding="utf-8", errors="ignore")
    suffixes = "|".join(
        sorted(
            suffix.removeprefix(".")
            for suffix in RAW_REPORT_SUFFIXES.union({".md"})
        )
    )
    pattern = rf"`(docs/hermes-analysis/master_optimizer_reports/[^`]+\.(?:{suffixes}))`"
    return set(re.findall(pattern, text))


def retention_manifest_pending_hashes() -> dict[str, str]:
    """Return content seals for reviewed evidence that is not tracked yet.

    Ordinary manifest membership is intentionally insufficient for local
    JSON/Markdown output. A pending evidence file is governed only when the
    README records its exact repository path and SHA-256. This lets a reviewed
    apply/sync/audit bundle survive until it is added to Git without turning
    the manifest into a blanket escape hatch for generated output.
    """

    if not RETENTION_MANIFEST_FILE.exists():
        return {}
    text = RETENTION_MANIFEST_FILE.read_text(encoding="utf-8", errors="ignore")
    suffixes = "|".join(
        sorted(
            suffix.removeprefix(".")
            for suffix in RAW_REPORT_SUFFIXES.union({".md"})
        )
    )
    pattern = re.compile(
        rf"`(?P<path>docs/hermes-analysis/master_optimizer_reports/[^`]+\.(?:{suffixes}))`"
        rf"\s+[—-]\s+{re.escape(PENDING_LOCAL_HASH_LABEL)}\s+"
        r"`(?P<sha256>[0-9a-f]{64})`"
    )
    result: dict[str, str] = {}
    for match in pattern.finditer(text):
        path = match.group("path")
        digest = match.group("sha256")
        prior = result.get(path)
        if prior is not None and prior != digest:
            raise ValueError(f"conflicting pending-local SHA-256 seals for {path}")
        result[path] = digest
    return result


def classify_paths(
    paths: list[Path],
    *,
    active_tokens: set[str],
    manifest_paths: set[str],
    manifest_has_justification: bool,
) -> dict[str, list[Path]]:
    classified: dict[str, list[Path]] = {
        "active_consumer": [],
        "manifest_only": [],
        "ungoverned": [],
    }
    for path in paths:
        relative_path = rel(path)
        if path.name in active_tokens or relative_path in active_tokens:
            classified["active_consumer"].append(path)
        elif manifest_has_justification and relative_path in manifest_paths:
            classified["manifest_only"].append(path)
        else:
            classified["ungoverned"].append(path)
    return classified


def classify_raw_files() -> dict[str, list[Path]]:
    return classify_paths(
        tracked_report_raw_files(),
        active_tokens=extract_raw_reference_tokens(read_active_reference_text()),
        manifest_paths=retention_manifest_paths(),
        manifest_has_justification=retention_manifest_justification() is not None,
    )


def local_untracked_report_files() -> list[Path]:
    if not REPORT_DIR.exists():
        return []
    tracked = {path.resolve() for path in git_ls_files(REPORT_DIR)}
    return sorted(
        path
        for path in REPORT_DIR.rglob("*")
        if path.is_file()
        and path.resolve() not in tracked
        and path.suffix in RAW_REPORT_SUFFIXES.union({".md"})
    )


def classify_local_report_files(
    paths: list[Path], *, manifest_paths: set[str], pending_hashes: dict[str, str] | None = None
) -> dict[str, list[Path]]:
    """Split local raw files into reviewed SQL quartets and actual residue.

    A newly prepared PostgreSQL operator package necessarily exists before it
    can be tracked. Treating every such file as disposable residue made the
    local closure gate impossible to run without mutating the Git index.

    The exceptions are deliberately narrow: SQL must be explicitly listed and
    form a complete precheck/apply/postcheck/rollback quartet; reviewed JSON or
    Markdown evidence must be explicitly listed and match an exact SHA-256 seal
    in the manifest. Missing/tampered files, arbitrary generated output, and
    incomplete SQL packages still fail. In CI, omitted files remain stale
    manifest entries.
    """

    pending_hashes = pending_hashes or {}

    package_members: dict[str, dict[str, Path]] = {}
    for path in paths:
        if path.suffix != ".sql" or rel(path) not in manifest_paths:
            continue
        match = SQL_PACKAGE_ROLE_RE.fullmatch(path.name)
        if match is None:
            continue
        package_members.setdefault(match.group("prefix"), {})[
            match.group("role")
        ] = path

    pending_manifest: set[Path] = set()
    for members in package_members.values():
        if set(members) == SQL_PACKAGE_ROLES:
            pending_manifest.update(members.values())

    for path in paths:
        relative_path = rel(path)
        expected_hash = pending_hashes.get(relative_path)
        if (
            relative_path not in manifest_paths
            or expected_hash is None
            or path.suffix not in {".json", ".md"}
        ):
            continue
        try:
            actual_hash = hashlib.sha256(path.read_bytes()).hexdigest()
        except OSError:
            continue
        if actual_hash == expected_hash:
            pending_manifest.add(path)

    return {
        "pending_manifest": sorted(pending_manifest),
        "ignored": sorted(path for path in paths if path not in pending_manifest),
    }


def ignored_local_report_files() -> list[Path]:
    """Compatibility helper returning only ungoverned local residue."""

    return classify_local_report_files(
        local_untracked_report_files(),
        manifest_paths=retention_manifest_paths(),
        pending_hashes=retention_manifest_pending_hashes(),
    )["ignored"]


def byte_size(paths: list[Path]) -> int:
    total = 0
    for path in paths:
        try:
            total += path.stat().st_size
        except OSError:
            continue
    return total


def artifact_metadata(
    path: Path,
    *,
    classification: str,
    justification: str | None = None,
    now: datetime | None = None,
) -> dict[str, Any]:
    now = now or datetime.now(timezone.utc)
    try:
        stat = path.stat()
        modified_at = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc)
        size_bytes = stat.st_size
        age_days = max(0.0, (now - modified_at).total_seconds() / 86400)
    except OSError:
        modified_at = None
        size_bytes = 0
        age_days = None
    return {
        "path": rel(path),
        "classification": classification,
        "justification": justification,
        "size_bytes": size_bytes,
        "modified_at": modified_at.isoformat() if modified_at else None,
        "age_days": round(age_days, 2) if age_days is not None else None,
    }


def build_report(*, fail_on_ignored_local: bool) -> dict[str, Any]:
    classified = classify_raw_files()
    active_consumer = classified["active_consumer"]
    manifest_only = classified["manifest_only"]
    ungoverned = classified["ungoverned"]
    manifest_paths = retention_manifest_paths()
    manifest_justification = retention_manifest_justification()
    pending_hashes = retention_manifest_pending_hashes()
    local_classified = classify_local_report_files(
        local_untracked_report_files(),
        manifest_paths=manifest_paths,
        pending_hashes=pending_hashes,
    )
    pending_manifest_local = local_classified["pending_manifest"]
    ignored = local_classified["ignored"]
    # Markdown summaries are not part of the tracked-raw classification, but a
    # content-sealed pending summary must stop being "stale" once it is tracked.
    tracked_relative_paths = {
        rel(path)
        for path in git_ls_files(REPORT_DIR)
        if path.exists() and path.is_file()
    }
    pending_manifest_relative_paths = {
        rel(path) for path in pending_manifest_local
    }
    stale_manifest_entries = sorted(
        manifest_paths
        - tracked_relative_paths
        - pending_manifest_relative_paths
    )
    checks = [
        Check(
            "retention_manifest_has_explicit_justification",
            "pass" if manifest_justification else "fail",
            f"manifest={rel(RETENTION_MANIFEST_FILE)} justification_present={manifest_justification is not None}",
        ),
        Check(
            "tracked_raw_report_files_have_consumer_or_retention_justification",
            "pass" if not ungoverned else "fail",
            " ".join(
                [
                    f"active_consumer={len(active_consumer)}",
                    f"manifest_only={len(manifest_only)}",
                    f"ungoverned={len(ungoverned)}",
                ]
            ),
        ),
        Check(
            "retention_manifest_has_no_stale_raw_entries",
            "pass" if not stale_manifest_entries else "fail",
            f"manifest_entries={len(manifest_paths)} stale_entries={len(stale_manifest_entries)}",
        ),
        Check(
            "ignored_local_report_artifacts_absent",
            "pass" if (not fail_on_ignored_local or not ignored) else "fail",
            f"ignored_local_count={len(ignored)} ignored_local_bytes={byte_size(ignored)}",
        ),
    ]
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    now = datetime.now(timezone.utc)
    tracked_artifacts = [
        artifact_metadata(path, classification="active_consumer", now=now)
        for path in active_consumer
    ] + [
        artifact_metadata(
            path,
            classification="manifest_only",
            justification=manifest_justification,
            now=now,
        )
        for path in manifest_only
    ] + [
        artifact_metadata(path, classification="ungoverned", now=now)
        for path in ungoverned
    ]
    ignored_artifacts = [
        artifact_metadata(path, classification="ignored_local", now=now)
        for path in ignored
    ]
    known_ages = [
        float(item["age_days"])
        for item in tracked_artifacts
        if item["age_days"] is not None
    ]
    return {
        "generated_at": utc_now(),
        "status": "pass" if status_counts.get("fail", 0) == 0 else "fail",
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
            "tracked_raw_count": len(active_consumer) + len(manifest_only) + len(ungoverned),
            "active_consumer_tracked_raw_count": len(active_consumer),
            "active_consumer_tracked_raw_bytes": byte_size(active_consumer),
            "manifest_only_tracked_raw_count": len(manifest_only),
            "manifest_only_tracked_raw_bytes": byte_size(manifest_only),
            "ungoverned_tracked_raw_count": len(ungoverned),
            "ungoverned_tracked_raw_bytes": byte_size(ungoverned),
            "tracked_raw_oldest_age_days": max(known_ages) if known_ages else None,
            "retention_manifest_entry_count": len(manifest_paths),
            "retention_manifest_stale_entry_count": len(stale_manifest_entries),
            "pending_manifest_local_count": len(pending_manifest_local),
            "pending_manifest_local_bytes": byte_size(pending_manifest_local),
            "ignored_local_count": len(ignored),
            "ignored_local_bytes": byte_size(ignored),
        },
        "checks": [check.as_dict() for check in checks],
        "retention_manifest": {
            "path": rel(RETENTION_MANIFEST_FILE),
            "justification": manifest_justification,
            "entries": sorted(manifest_paths),
            "pending_local_sha256": dict(sorted(pending_hashes.items())),
            "pending_local_entries": sorted(pending_manifest_relative_paths),
            "stale_entries": stale_manifest_entries,
        },
        "active_consumer_tracked_raw": [rel(path) for path in active_consumer],
        "manifest_only_tracked_raw": [rel(path) for path in manifest_only],
        "ungoverned_tracked_raw": [rel(path) for path in ungoverned],
        "tracked_raw_artifacts": sorted(tracked_artifacts, key=lambda item: item["path"]),
        "ignored_local_artifact_metadata": ignored_artifacts,
        # Compatibility aliases. "referenced" now means a real active surface;
        # manifest-only retention is reported separately instead of inflating it.
        "referenced_tracked_raw": [rel(path) for path in active_consumer],
        "unreferenced_tracked_raw": [rel(path) for path in ungoverned],
        "pending_manifest_local_raw": [rel(path) for path in pending_manifest_local],
        "ignored_local_report_artifacts": [rel(path) for path in ignored],
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Report Retention Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    if report["ungoverned_tracked_raw"]:
        lines.extend(["", "## Ungoverned Tracked Raw Files", ""])
        for item in report["ungoverned_tracked_raw"][:200]:
            lines.append(f"- `{item}`")
        if len(report["ungoverned_tracked_raw"]) > 200:
            lines.append(f"- ... {len(report['ungoverned_tracked_raw']) - 200} more")
    if report["manifest_only_tracked_raw"]:
        lines.extend(
            [
                "",
                "## Manifest-only Retained Raw Files",
                "",
                (
                    f"Count: `{len(report['manifest_only_tracked_raw'])}`. "
                    "These files have retention justification but no active consumer reference."
                ),
            ]
        )
        metadata_by_path = {
            item["path"]: item for item in report["tracked_raw_artifacts"]
        }
        for item in report["manifest_only_tracked_raw"][:200]:
            metadata = metadata_by_path.get(item, {})
            lines.append(
                f"- `{item}` - bytes={metadata.get('size_bytes', 0)} "
                f"age_days={metadata.get('age_days')}"
            )
        if len(report["manifest_only_tracked_raw"]) > 200:
            lines.append(f"- ... {len(report['manifest_only_tracked_raw']) - 200} more")
    if report["ignored_local_report_artifacts"]:
        lines.extend(["", "## Ignored Local Report Artifacts", ""])
        for item in report["ignored_local_report_artifacts"][:200]:
            lines.append(f"- `{item}`")
        if len(report["ignored_local_report_artifacts"]) > 200:
            lines.append(f"- ... {len(report['ignored_local_report_artifacts']) - 200} more")
    if report["pending_manifest_local_raw"]:
        lines.extend(["", "## Pending Manifest SQL Package Files", ""])
        lines.append(
            "Complete reviewed SQL quartets present locally and listed in the "
            "retention manifest; they must be tracked with the related evidence "
            "before merge."
        )
        for item in report["pending_manifest_local_raw"][:200]:
            lines.append(f"- `{item}`")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=Path("/tmp/manaloom_report_retention_audit"),
    )
    parser.add_argument(
        "--fail-on-ignored-local",
        action="store_true",
        help="Fail when ignored local report artifacts are present on disk.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(fail_on_ignored_local=args.fail_on_ignored_local)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
