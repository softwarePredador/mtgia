#!/usr/bin/env python3
"""Audit pinned XMage/Forge runtimes against their official upstream HEADs.

The audit is intentionally read-only. It never advances a pin, changes a
runtime, promotes a card rule, deploys a service, or writes PostgreSQL/SQLite.
Local pin consistency can be checked without network access; upstream compare
is an explicit research lane backed by GitHub's official Compare API.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import ssl
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


SCHEMA_VERSION = "external_engine_upstream_delta_audit_v1"
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
CATEGORIES = ("card_additions", "rules_fixes", "engine_changes")
DEFAULT_REPO_ROOT = Path(__file__).resolve().parents[4]
DEFAULT_JSON_OUTPUT = Path("/tmp/manaloom_external_engine_upstream_delta_audit.json")


@dataclass(frozen=True)
class PinMirror:
    path: str
    pattern: str
    role: str


@dataclass(frozen=True)
class EngineSpec:
    engine: str
    repository: str
    default_branch: str
    canonical_pin_path: str
    mirrors: tuple[PinMirror, ...]

    @property
    def compare_api_template(self) -> str:
        return (
            f"https://api.github.com/repos/{self.repository}/compare/"
            "{pin}..." + self.default_branch
        )

    @property
    def compare_web_template(self) -> str:
        return (
            f"https://github.com/{self.repository}/compare/"
            "{pin}..." + self.default_branch
        )


ENGINE_SPECS = (
    EngineSpec(
        engine="xmage",
        repository="magefree/mage",
        default_branch="master",
        canonical_pin_path="services/xmage-sidecar/XMAGE_COMMIT",
        mirrors=(
            PinMirror(
                "services/xmage-sidecar/Dockerfile",
                r"(?m)^ARG XMAGE_COMMIT=([0-9a-f]{40})\s*$",
                "container_build_checkout",
            ),
            PinMirror(
                "services/xmage-sidecar/src/main/java/com/manaloom/xmage/SidecarMain.java",
                r'(?m)^\s*static final String XMAGE_COMMIT = "([0-9a-f]{40})";\s*$',
                "runtime_health_and_replay_identity",
            ),
            PinMirror(
                "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_execution_contract_audit.py",
                r'(?m)^XMAGE_PIN = "([0-9a-f]{40})"\s*$',
                "execution_contract_expectation",
            ),
        ),
    ),
    EngineSpec(
        engine="forge",
        repository="Card-Forge/forge",
        default_branch="master",
        canonical_pin_path="services/forge-sidecar/FORGE_COMMIT",
        mirrors=(
            PinMirror(
                "services/forge-sidecar/Dockerfile",
                r"(?m)^ARG FORGE_COMMIT=([0-9a-f]{40})\s*$",
                "container_build_checkout",
            ),
            PinMirror(
                "docs/hermes-analysis/manaloom-knowledge/scripts/xmage_execution_contract_audit.py",
                r'(?m)^FORGE_PIN = "([0-9a-f]{40})"\s*$',
                "execution_contract_expectation",
            ),
        ),
    ),
)


class CompareFetchError(RuntimeError):
    """Raised when an official upstream comparison cannot be completed."""


CompareFetcher = Callable[[EngineSpec, str], dict[str, Any]]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _read_text(repo_root: Path, relative_path: str) -> tuple[str | None, str | None]:
    path = repo_root / relative_path
    try:
        return path.read_text(encoding="utf-8"), None
    except OSError as exc:
        return None, f"{relative_path}: {exc.__class__.__name__}"


def validate_engine_pin(repo_root: Path, spec: EngineSpec) -> dict[str, Any]:
    canonical_text, canonical_error = _read_text(repo_root, spec.canonical_pin_path)
    canonical_pin = (canonical_text or "").strip()
    errors: list[str] = []
    if canonical_error:
        errors.append(canonical_error)
    elif not SHA_PATTERN.fullmatch(canonical_pin):
        errors.append(f"{spec.canonical_pin_path}: expected one lowercase 40-character SHA")

    mirrors: list[dict[str, Any]] = []
    for mirror in spec.mirrors:
        text, read_error = _read_text(repo_root, mirror.path)
        values = re.findall(mirror.pattern, text or "") if text is not None else []
        status = "pass"
        detail = "matches_canonical_pin"
        if read_error:
            status = "fail"
            detail = read_error
        elif len(values) != 1:
            status = "fail"
            detail = f"expected_one_pin_match_found_{len(values)}"
        elif not canonical_pin or values[0] != canonical_pin:
            status = "fail"
            detail = "mirror_diverges_from_canonical_pin"
        if status == "fail":
            errors.append(f"{mirror.path}: {detail}")
        mirrors.append(
            {
                "path": mirror.path,
                "role": mirror.role,
                "status": status,
                "observed_values": values,
                "detail": detail,
            }
        )

    return {
        "status": "pass" if not errors else "fail",
        "canonical_pin_path": spec.canonical_pin_path,
        "canonical_pin": canonical_pin or None,
        "mirrors": mirrors,
        "errors": errors,
    }


def validate_runtime_reference_policy(repo_root: Path) -> dict[str, Any]:
    relative_path = (
        "docs/hermes-analysis/manaloom-knowledge/scripts/"
        "external_card_rule_reference_harvester.py"
    )
    text, read_error = _read_text(repo_root, relative_path)
    errors: list[str] = []
    if read_error:
        errors.append(read_error)
    else:
        required = (
            'XMAGE_PIN = canonical_engine_pin("services/xmage-sidecar/XMAGE_COMMIT")',
            'FORGE_PIN = canonical_engine_pin("services/forge-sidecar/FORGE_COMMIT")',
            "validate_xmage_local_root_pin(xmage_root)",
            '"xmage_local_root_pin_contract": local_root_pin_contract',
            '"upstream_head_allowed": False',
        )
        missing = [marker for marker in required if marker not in (text or "")]
        if missing:
            errors.append(f"missing_runtime_pin_markers={missing}")
        forbidden = (
            "magefree/mage/master/",
            "Card-Forge/forge/master/",
        )
        present = [marker for marker in forbidden if marker in (text or "")]
        if present:
            errors.append(f"forbidden_upstream_head_references={present}")
    return {
        "status": "pass" if not errors else "fail",
        "path": relative_path,
        "policy": "runtime_and_promotion_references_must_use_canonical_pins",
        "upstream_head_allowed_only_in_explicit_delta_research": True,
        "errors": errors,
    }


def _github_json(url: str, *, token: str | None, timeout: int) -> dict[str, Any]:
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "ManaLoomExternalEngineDeltaAudit/1.0",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    ssl_context = ssl.create_default_context()
    try:
        import certifi  # type: ignore[import-not-found]

        ssl_context = ssl.create_default_context(cafile=certifi.where())
    except (ImportError, OSError):
        # System Python installations with a configured trust store need no
        # extra package; certifi is only a portable CA fallback.
        pass
    try:
        with urllib.request.urlopen(
            request,
            timeout=timeout,
            context=ssl_context,
        ) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        try:
            body = json.loads(exc.read().decode("utf-8"))
            message = str(body.get("message") or "")
        except Exception:
            message = ""
        suffix = f": {message}" if message else ""
        raise CompareFetchError(f"GitHub Compare HTTP {exc.code}{suffix}") from exc
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise CompareFetchError(f"GitHub Compare unavailable: {exc.__class__.__name__}") from exc
    if not isinstance(payload, dict):
        raise CompareFetchError("GitHub Compare returned a non-object payload")
    return payload


def fetch_official_compare(
    spec: EngineSpec,
    pin: str,
    *,
    token: str | None = None,
    timeout: int = 30,
) -> dict[str, Any]:
    """Fetch all compare commits and the API's capped first-page file list."""

    encoded_compare = urllib.parse.quote(f"{pin}...{spec.default_branch}", safe=".")
    endpoint = f"https://api.github.com/repos/{spec.repository}/compare/{encoded_compare}"
    page = 1
    commits: list[dict[str, Any]] = []
    first_payload: dict[str, Any] | None = None
    total_commits: int | None = None
    while True:
        separator = "&" if "?" in endpoint else "?"
        url = f"{endpoint}{separator}per_page=100&page={page}"
        payload = _github_json(url, token=token, timeout=timeout)
        if first_payload is None:
            first_payload = payload
            try:
                total_commits = int(payload.get("total_commits", 0))
            except (TypeError, ValueError):
                total_commits = None
        page_commits = payload.get("commits")
        if not isinstance(page_commits, list):
            raise CompareFetchError("GitHub Compare payload is missing commits")
        commits.extend(item for item in page_commits if isinstance(item, dict))
        if total_commits is None or len(commits) >= total_commits or len(page_commits) < 100:
            break
        page += 1
        if page > 100:
            raise CompareFetchError("GitHub Compare pagination exceeded safety limit")

    assert first_payload is not None
    first_payload = dict(first_payload)
    first_payload["commits"] = commits
    first_payload["_audit_pagination"] = {
        "pages_fetched": page,
        "commits_returned": len(commits),
        "commits_truncated": total_commits is not None and len(commits) < total_commits,
    }
    return first_payload


def classify_commit(message: str) -> str:
    normalized = re.sub(r"\s+", " ", str(message or "").lower()).strip()
    if re.search(r"\b(fix|fixed|rule|trigger|ability|replacement|combat|stack|oracle|interaction)\b", normalized):
        return "rules_fixes"
    if (
        re.search(r"\b(card|cards|spoiler|spoilers|set release)\b", normalized)
        or re.search(r"^\[[a-z0-9]{2,8}\]\s+implement\b", normalized)
    ):
        return "card_additions"
    return "engine_changes"


def _is_test_or_fixture_path(path: str) -> bool:
    lower = path.lower()
    parts = [part for part in lower.split("/") if part]
    name = parts[-1] if parts else lower
    return (
        any(part in {"test", "tests", "fixture", "fixtures"} for part in parts)
        or name.startswith("test_")
        or name.endswith("_test.py")
        or name.endswith("test.java")
        or "test" in name and name.endswith((".java", ".kt", ".groovy"))
    )


def classify_file(engine: str, path: str, status: str) -> str:
    lower = str(path or "").lower()
    normalized_status = str(status or "").lower()
    if engine == "xmage" and lower.startswith("mage.sets/src/mage/cards/"):
        return "card_additions" if normalized_status == "added" else "rules_fixes"
    if engine == "forge" and lower.startswith("forge-gui/res/cardsfolder/"):
        return "card_additions" if normalized_status == "added" else "rules_fixes"
    if _is_test_or_fixture_path(lower):
        return "rules_fixes"
    if engine == "xmage" and lower.startswith(
        (
            "mage/src/main/java/mage/abilities/",
            "mage/src/main/java/mage/cards/",
            "mage/src/main/java/mage/game/",
            "mage/src/main/java/mage/players/",
            "mage/src/main/java/mage/replacement/",
            "mage/src/main/java/mage/target/",
        )
    ):
        return "rules_fixes"
    if engine == "forge" and lower.startswith("forge-game/src/main/java/forge/game/"):
        return "rules_fixes"
    return "engine_changes"


def _derived_card_name(identifier: str) -> str:
    if "_" in identifier or "-" in identifier:
        words = re.split(r"[_-]+", identifier)
    else:
        words = re.split(
            r"(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])",
            identifier,
        )
    return " ".join(word for word in words if word).strip()


def candidate_card_from_file(engine: str, changed_file: dict[str, Any]) -> dict[str, Any] | None:
    path = str(changed_file.get("filename") or "")
    lower = path.lower()
    if engine == "xmage":
        if not lower.startswith("mage.sets/src/mage/cards/") or not lower.endswith(".java"):
            return None
    elif engine == "forge":
        if not lower.startswith("forge-gui/res/cardsfolder/") or not lower.endswith(".txt"):
            return None
    else:
        return None

    identifier = Path(path).stem
    patch = str(changed_file.get("patch") or "")
    exact_name: str | None = None
    name_source = "path_derived"
    confidence = "derived"
    if engine == "forge":
        match = re.search(r"(?m)^\+?Name:\s*(.+?)\s*$", patch)
        if match:
            exact_name = match.group(1).strip()
            name_source = "compare_patch_name_field"
            confidence = "exact"
    else:
        match = re.search(
            r'(?m)^\+.*super\([^\n]*,\s*"([^"\n]+)"\s*,',
            patch,
        )
        if match:
            exact_name = match.group(1).strip()
            name_source = "compare_patch_constructor"
            confidence = "exact"

    status = str(changed_file.get("status") or "unknown")
    return {
        "engine": engine,
        "card_name": exact_name or _derived_card_name(identifier),
        "source_identifier": identifier,
        "name_source": name_source,
        "name_confidence": confidence,
        "source_path": path,
        "file_status": status,
        "candidate_reason": (
            "new_upstream_card"
            if status == "added"
            else "upstream_card_implementation_changed"
        ),
        "recommended_action": "review_against_current_runtime_pin_and_add_focused_fixture_before_pin_change",
    }


def _commit_record(commit: dict[str, Any]) -> dict[str, Any]:
    commit_payload = commit.get("commit") if isinstance(commit.get("commit"), dict) else {}
    message = str(commit_payload.get("message") or "")
    author = commit_payload.get("author") if isinstance(commit_payload.get("author"), dict) else {}
    return {
        "sha": commit.get("sha"),
        "message": message.splitlines()[0] if message else "",
        "date": author.get("date"),
        "url": commit.get("html_url"),
        "category": classify_commit(message),
    }


def _file_record(engine: str, changed_file: dict[str, Any]) -> dict[str, Any]:
    path = str(changed_file.get("filename") or "")
    status = str(changed_file.get("status") or "unknown")
    return {
        "path": path,
        "status": status,
        "additions": changed_file.get("additions"),
        "deletions": changed_file.get("deletions"),
        "changes": changed_file.get("changes"),
        "url": changed_file.get("blob_url"),
        "category": classify_file(engine, path, status),
        "patch_available": bool(changed_file.get("patch")),
    }


def _category_counts(records: list[dict[str, Any]]) -> dict[str, int]:
    counts = Counter(str(item.get("category") or "") for item in records)
    return {category: counts.get(category, 0) for category in CATEGORIES}


def analyze_compare(spec: EngineSpec, pin: str, payload: dict[str, Any]) -> dict[str, Any]:
    compare_status = str(payload.get("status") or "unknown")
    try:
        ahead_by = int(payload.get("ahead_by", 0))
        behind_by = int(payload.get("behind_by", 0))
        total_commits = int(payload.get("total_commits", 0))
    except (TypeError, ValueError) as exc:
        raise CompareFetchError("GitHub Compare returned invalid counters") from exc

    base_commit = payload.get("base_commit") if isinstance(payload.get("base_commit"), dict) else {}
    base_sha = str(base_commit.get("sha") or "")
    if base_sha and base_sha != pin:
        raise CompareFetchError("GitHub Compare base SHA does not match canonical pin")

    raw_commits = payload.get("commits")
    raw_files = payload.get("files")
    if not isinstance(raw_commits, list) or not isinstance(raw_files, list):
        raise CompareFetchError("GitHub Compare payload is missing commits/files")
    commits = [_commit_record(item) for item in raw_commits if isinstance(item, dict)]
    files = [_file_record(spec.engine, item) for item in raw_files if isinstance(item, dict)]
    candidates = [
        candidate
        for item in raw_files
        if isinstance(item, dict)
        for candidate in [candidate_card_from_file(spec.engine, item)]
        if candidate is not None
    ]
    changed_fixtures = [
        {
            "engine": spec.engine,
            "kind": "changed_upstream_test_or_fixture",
            "path": str(item.get("filename") or ""),
            "file_status": str(item.get("status") or "unknown"),
            "recommended_action": "review_and_port_only_if_relevant_to_the_pinned_runtime_delta",
        }
        for item in raw_files
        if isinstance(item, dict)
        and _is_test_or_fixture_path(str(item.get("filename") or ""))
    ]
    recommended_fixtures = [
        {
            "engine": spec.engine,
            "kind": "recommended_focused_card_fixture",
            "fixture_id": f"{spec.engine}:{card['source_identifier']}",
            "source_path": card["source_path"],
            "recommended_action": "create_before_any_reviewed_pin_advance",
        }
        for card in candidates
    ]

    pagination = payload.get("_audit_pagination")
    pagination = pagination if isinstance(pagination, dict) else {}
    files_truncated = len(raw_files) >= 300
    commits_truncated = bool(pagination.get("commits_truncated", len(commits) < total_commits))
    review_reasons: list[str] = []
    if ahead_by > 0:
        review_reasons.append("official_upstream_is_ahead_of_runtime_pin")
    if compare_status == "diverged" or behind_by > 0:
        review_reasons.append("runtime_pin_and_default_branch_require_ancestry_review")
    if files_truncated or commits_truncated:
        review_reasons.append("compare_result_is_truncated")

    head_commit = payload.get("head_commit") if isinstance(payload.get("head_commit"), dict) else {}
    head_sha = head_commit.get("sha")
    if not head_sha and commits:
        head_sha = commits[-1].get("sha")
    if not head_sha and compare_status == "identical":
        head_sha = pin

    return {
        "status": "review_required" if review_reasons else "pass",
        "review_required": bool(review_reasons),
        "review_reasons": review_reasons,
        "compare": {
            "status": compare_status,
            "ahead_by": ahead_by,
            "behind_by": behind_by,
            "total_commits": total_commits,
            "upstream_head_sha": head_sha,
            "commits_returned": len(commits),
            "files_returned": len(files),
            "commits_truncated": commits_truncated,
            "files_truncated": files_truncated,
            "github_files_limit": 300,
        },
        "classification_summary": {
            "commits": _category_counts(commits),
            "files": _category_counts(files),
        },
        "commits": commits,
        "files": files,
        "candidate_cards": candidates,
        "candidate_fixtures": changed_fixtures + recommended_fixtures,
    }


def build_report(
    repo_root: Path = DEFAULT_REPO_ROOT,
    *,
    compare_fetcher: CompareFetcher | None = None,
    local_only: bool = False,
) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    pin_results = {
        spec.engine: validate_engine_pin(repo_root, spec) for spec in ENGINE_SPECS
    }
    runtime_policy = validate_runtime_reference_policy(repo_root)
    local_errors = [
        error
        for result in pin_results.values()
        for error in result.get("errors", [])
    ] + list(runtime_policy.get("errors", []))

    report: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "generated_at_utc": utc_now(),
        "status": "pass",
        "review_required": False,
        "mode": "local_pin_contract" if local_only else "official_upstream_compare",
        "safety": {
            "read_only": True,
            "postgres_writes": False,
            "sqlite_writes": False,
            "pin_updates_performed": False,
            "deployment_actions_performed": False,
            "promotion_actions_performed": False,
            "mutations_performed": [],
        },
        "classification_categories": list(CATEGORIES),
        "runtime_reference_policy": runtime_policy,
        "engines": [],
        "errors": local_errors,
    }

    if local_errors:
        report["status"] = "fail"
        for spec in ENGINE_SPECS:
            report["engines"].append(
                {
                    "engine": spec.engine,
                    "official_repository": f"https://github.com/{spec.repository}",
                    "default_branch": spec.default_branch,
                    "pin_consistency": pin_results[spec.engine],
                    "upstream": {"status": "not_checked_due_to_local_contract_failure"},
                }
            )
        report["summary"] = {
            "engines": len(ENGINE_SPECS),
            "pin_contract_failures": sum(
                result["status"] == "fail" for result in pin_results.values()
            ),
            "engines_requiring_review": 0,
            "candidate_cards": 0,
            "candidate_fixtures": 0,
        }
        return report

    for spec in ENGINE_SPECS:
        pin_result = pin_results[spec.engine]
        pin = str(pin_result["canonical_pin"])
        engine_report: dict[str, Any] = {
            "engine": spec.engine,
            "official_repository": f"https://github.com/{spec.repository}",
            "default_branch": spec.default_branch,
            "pin_consistency": pin_result,
            "compare_api": spec.compare_api_template.format(pin=pin),
            "compare_web": spec.compare_web_template.format(pin=pin),
        }
        if local_only:
            engine_report["status"] = "pass"
            engine_report["review_required"] = False
            engine_report["upstream"] = {"status": "skipped_local_only"}
            report["engines"].append(engine_report)
            continue

        if compare_fetcher is None:
            raise ValueError("compare_fetcher is required when local_only is false")
        try:
            payload = compare_fetcher(spec, pin)
            analysis = analyze_compare(spec, pin, payload)
            engine_report.update(analysis)
        except (CompareFetchError, OSError, ValueError, TypeError) as exc:
            engine_report.update(
                {
                    "status": "fail",
                    "review_required": False,
                    "upstream": {
                        "status": "unknown",
                        "error": str(exc),
                    },
                    "candidate_cards": [],
                    "candidate_fixtures": [],
                }
            )
            report["errors"].append(f"{spec.engine}: {exc}")
        report["engines"].append(engine_report)

    failures = [engine for engine in report["engines"] if engine.get("status") == "fail"]
    reviews = [engine for engine in report["engines"] if engine.get("review_required")]
    if failures:
        report["status"] = "fail"
    elif reviews:
        report["status"] = "review_required"
        report["review_required"] = True
    report["summary"] = {
        "engines": len(ENGINE_SPECS),
        "pin_contract_failures": 0,
        "engines_requiring_review": len(reviews),
        "candidate_cards": sum(len(engine.get("candidate_cards", [])) for engine in report["engines"]),
        "candidate_fixtures": sum(
            len(engine.get("candidate_fixtures", [])) for engine in report["engines"]
        ),
    }
    return report


def fixture_compare_fetcher(fixture_dir: Path) -> CompareFetcher:
    def fetch(spec: EngineSpec, pin: str) -> dict[str, Any]:
        path = fixture_dir / f"{spec.engine}_compare.json"
        try:
            raw = path.read_text(encoding="utf-8")
        except OSError as exc:
            raise CompareFetchError(f"missing compare fixture: {path}") from exc
        raw = raw.replace("__CANONICAL_PIN__", pin)
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise CompareFetchError(f"invalid compare fixture: {path}") from exc
        if not isinstance(payload, dict):
            raise CompareFetchError(f"compare fixture must be an object: {path}")
        return payload

    return fetch


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT)
    parser.add_argument("--json-output", type=Path, default=DEFAULT_JSON_OUTPUT)
    parser.add_argument(
        "--local-only",
        action="store_true",
        help="Validate canonical pins/mirrors and runtime reference policy without network.",
    )
    parser.add_argument(
        "--fixture-dir",
        type=Path,
        help="Read <engine>_compare.json fixtures instead of accessing GitHub.",
    )
    parser.add_argument("--timeout", type=int, default=30)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.local_only and args.fixture_dir:
        raise SystemExit("--local-only and --fixture-dir are mutually exclusive")
    if args.timeout <= 0:
        raise SystemExit("--timeout must be positive")

    if args.local_only:
        fetcher = None
    elif args.fixture_dir:
        fetcher = fixture_compare_fetcher(args.fixture_dir)
    else:
        token = os.environ.get("GITHUB_TOKEN") or None
        fetcher = lambda spec, pin: fetch_official_compare(
            spec,
            pin,
            token=token,
            timeout=args.timeout,
        )
    report = build_report(
        args.repo_root,
        compare_fetcher=fetcher,
        local_only=args.local_only,
    )
    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    args.json_output.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "status": report["status"],
                "review_required": report["review_required"],
                "json_output": str(args.json_output),
                "summary": report["summary"],
                "mutations_performed": [],
            },
            sort_keys=True,
        )
    )
    return 1 if report["status"] == "fail" else 0


if __name__ == "__main__":
    raise SystemExit(main())
