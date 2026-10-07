#!/usr/bin/env python3
"""Receipt forte de uma execução de gate local (BT-GATE-002).

O `local_ci` e a suíte E2E rodavam sem deixar prova: o `local_ci` apagava o
próprio diretório de execução, e o `summary.json` do E2E ficava em `/tmp` sem
SHA, sem digest e sem hash de log. Este utilitário fecha isso para os dois:

- `capture` grava o estado-fonte do checkout (SHA completo do `HEAD`, worktree
  sujo ou limpo, digest do worktree e digest do project logic);
- `finalize` captura o estado-fonte de novo, exige que seja igual ao do início,
  copia cada log para uma raiz durável fora de `/tmp` e fora do worktree, guarda
  o sha256 e o tamanho de cada log e grava o `receipt.json`;
- `validate` refaz cada conferência contra o checkout corrente e falha fechado.

Um receipt só tem `gate_eligible: true` quando o status é `PASS`, todos os
checks nomeados passaram, o estado-fonte não mudou e a raiz é durável. Um
receipt em `/tmp`, um log adulterado, um catálogo de checks trocado ou um
checkout diferente nunca validam.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA = "manaloom.gate_run_receipt.v1"
ROOT_DIR = Path(__file__).resolve().parent.parent
TEMPORARY_PATH_PREFIXES = (
    "/tmp",
    "/private/tmp",
    "/var/tmp",
    "/private/var/tmp",
    "/var/folders",
    "/private/var/folders",
    "/dev/shm",
)
GATES = {
    "local_ci": ("quick", "schema", "full", "e2e", "release"),
    "e2e_suite": ("strict-gate", "diagnostic-allow-partial"),
}
_FULL_CHECKS = (
    "shell-contracts",
    "commander-game-changer-source",
    "dart-mcp-preflight",
    "secret-scan",
    "guardrail-audits",
    "release-contracts",
    "full-quality",
    "schema-gate",
)
# Catálogo fechado de cada modo do local_ci, na ordem em que o script roda.
# Um receipt com um check só, ou com a ordem trocada, nunca valida.
LOCAL_CI_CHECKS = {
    "quick": (
        "shell-contracts",
        "commander-game-changer-source",
        "dart-mcp-preflight",
        "secret-scan",
        "project-logic",
        "ui-live-evidence",
    ),
    "schema": (
        "shell-contracts",
        "commander-game-changer-source",
        "project-logic",
        "schema-gate",
    ),
    "full": _FULL_CHECKS,
    "e2e": _FULL_CHECKS + ("strict-e2e",),
    "release": _FULL_CHECKS + ("battle-gate", "android-release-build"),
}
STATUSES = ("PASS", "FAIL", "BLOCKED", "PARTIAL")
STEP_STATUSES = ("PASS", "FAIL", "SKIP", "BLOCKED")
STEP_ID_RE = re.compile(r"^[a-z0-9][a-z0-9_.-]*$")
RUN_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")


def _load_validator() -> Any:
    path = ROOT_DIR / "scripts" / "manaloom_deck_ai_learning_receipt_validator.py"
    spec = importlib.util.spec_from_file_location("manaloom_receipt_core", path)
    if spec is None or spec.loader is None:  # pragma: no cover - checkout quebrado
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_core = _load_validator()
ReceiptValidationError = _core.ReceiptValidationError
canonical_sha256 = _core.canonical_sha256
file_sha256 = _core.file_sha256
load_json_strict = _core.load_json_strict
worktree_digest_sha256 = _core.worktree_digest_sha256
GIT_SHA_RE = _core.GIT_SHA_RE
SHA256_RE = _core.SHA256_RE


def _utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def _iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _parse_timestamp(value: Any, field: str) -> datetime:
    return _core._parse_timestamp(value, field)


def _is_relative_to(path: Path, parent: Path) -> bool:
    return _core._is_relative_to(path, parent)


def capture_source_state(repo: Path) -> dict[str, Any]:
    """Estado-fonte do checkout; mesma captura do receipt Deck/IA, sem a política."""
    repo = repo.resolve()
    manifest_path = repo / "project_logic_manifest.json"
    manifest = load_json_strict(manifest_path)
    git_sha = _core._git_bytes(repo, "rev-parse", "HEAD").decode().strip()
    if not GIT_SHA_RE.fullmatch(git_sha):
        raise ReceiptValidationError("source checkout has no full Git SHA")
    git_dirty = bool(
        _core._git_bytes(
            repo, "status", "--porcelain", "--untracked-files=normal"
        ).strip()
    )
    source_digest = manifest.get("source_digest_sha256")
    if not isinstance(source_digest, str) or not SHA256_RE.fullmatch(source_digest):
        raise ReceiptValidationError("project logic source digest is invalid")
    return {
        "git_sha": git_sha,
        "git_dirty": git_dirty,
        "worktree_digest_sha256": worktree_digest_sha256(repo),
        "project_logic_source_digest": source_digest,
        "project_logic_manifest_sha256": file_sha256(manifest_path),
    }


def is_durable_root(path: Path, repo: Path) -> bool:
    resolved = path.resolve()
    for prefix in TEMPORARY_PATH_PREFIXES:
        if _is_relative_to(resolved, Path(prefix).resolve()):
            return False
    return not _is_relative_to(resolved, repo.resolve())


def _slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_") or "step"


def parse_steps(path: Path, steps_format: str) -> list[dict[str, Any]]:
    """Lê o manifesto de etapas que o shell escreveu, uma etapa por linha.

    local-ci-v1: id, status, exit_code, log (TAB)
    e2e-v1: status, label, exit_code, log, reason (TAB; o formato do steps.tsv)
    """
    steps: list[dict[str, Any]] = []
    seen: set[str] = set()
    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if not raw_line.strip():
            continue
        if steps_format == "local-ci-v1":
            fields = raw_line.split("\t")
            if len(fields) != 4:
                raise ReceiptValidationError(f"step line {line_number} is malformed")
            step_id, status, exit_code, log = fields
            label = step_id
        elif steps_format == "e2e-v1":
            fields = raw_line.split("\t", 4)
            if len(fields) != 5:
                raise ReceiptValidationError(f"step line {line_number} is malformed")
            status, label, exit_code, log, _reason = fields
            step_id = _slug(label)
        else:
            raise ReceiptValidationError(f"unknown steps format: {steps_format}")
        if not STEP_ID_RE.fullmatch(step_id):
            raise ReceiptValidationError(f"step id is invalid: {step_id}")
        base_id = step_id
        suffix = 2
        while step_id in seen:
            step_id = f"{base_id}.{suffix}"
            suffix += 1
        seen.add(step_id)
        if status not in STEP_STATUSES:
            raise ReceiptValidationError(f"step {step_id} has invalid status")
        if log and not Path(log).is_absolute():
            log = str(path.parent / log)
        steps.append(
            {
                "id": step_id,
                "label": label,
                "status": status,
                "exit_code": int(exit_code) if exit_code else None,
                "log": log or None,
            }
        )
    return steps


def finalize(
    *,
    repo: Path,
    gate: str,
    mode: str,
    run_id: str,
    started_at: str,
    source_start_path: Path,
    steps_path: Path,
    steps_format: str,
    status: str,
    receipt_root: Path,
) -> tuple[Path, dict[str, Any]]:
    repo = repo.resolve()
    if gate not in GATES or mode not in GATES[gate]:
        raise ReceiptValidationError(f"unknown gate/mode: {gate}/{mode}")
    if status not in STATUSES:
        raise ReceiptValidationError(f"invalid status: {status}")
    if not RUN_ID_RE.fullmatch(run_id):
        raise ReceiptValidationError("run id is invalid")
    started = _parse_timestamp(started_at, "started_at")
    source_start = load_json_strict(source_start_path)
    source_end = capture_source_state(repo)
    stable = source_start == source_end
    steps = parse_steps(steps_path, steps_format)

    receipt_root = receipt_root.absolute()
    git_sha = source_start.get("git_sha")
    if not isinstance(git_sha, str) or not GIT_SHA_RE.fullmatch(git_sha):
        raise ReceiptValidationError("source.start has no full Git SHA")
    evidence_root = receipt_root / gate / git_sha / run_id
    if evidence_root.exists():
        raise ReceiptValidationError(f"evidence root already exists: {evidence_root}")
    (evidence_root / "logs").mkdir(parents=True)

    artifacts: list[dict[str, Any]] = []
    checks: list[dict[str, Any]] = []
    for index, step in enumerate(steps, start=1):
        artifact_ids: list[str] = []
        raw_log = step["log"]
        if raw_log:
            source_log = Path(raw_log)
            if not source_log.is_file() or source_log.is_symlink():
                raise ReceiptValidationError(f"step log is missing: {step['id']}")
            relative = f"logs/{index:02d}-{step['id']}.log"
            shutil.copyfile(source_log, evidence_root / relative)
            copied = evidence_root / relative
            artifact_id = f"log.{step['id']}"
            artifacts.append(
                {
                    "id": artifact_id,
                    "path": relative,
                    "sha256": file_sha256(copied),
                    "size_bytes": copied.stat().st_size,
                }
            )
            artifact_ids.append(artifact_id)
        checks.append(
            {
                "id": step["id"],
                "label": step["label"],
                "status": step["status"],
                "exit_code": step["exit_code"],
                "artifact_ids": artifact_ids,
            }
        )

    final_status = status
    reasons: list[str] = []
    if not stable:
        final_status = "FAIL"
        changed = sorted(
            key
            for key in set(source_start) | set(source_end)
            if source_start.get(key) != source_end.get(key)
        )
        reasons.append("source_changed:" + ",".join(changed))
    if final_status == "PASS" and any(check["status"] != "PASS" for check in checks):
        final_status = "FAIL"
        reasons.append("non_pass_check_with_pass_status")
    if final_status == "PASS" and not checks:
        final_status = "FAIL"
        reasons.append("no_checks")
    durable = is_durable_root(evidence_root, repo)
    if not durable:
        reasons.append("evidence_root_not_durable")
    completed = _utc_now()
    summary = {
        "check_count": len(checks),
        "passed": sum(1 for check in checks if check["status"] == "PASS"),
        "failed": sum(1 for check in checks if check["status"] == "FAIL"),
        "skipped": sum(1 for check in checks if check["status"] == "SKIP"),
        "blocked": sum(1 for check in checks if check["status"] == "BLOCKED"),
    }
    receipt = {
        "schema": SCHEMA,
        "gate": {"id": gate, "mode": mode},
        "run_id": run_id,
        "status": final_status,
        "reasons": reasons,
        "started_at": _iso(started),
        "completed_at": _iso(completed),
        "generated_at": _iso(completed),
        "git_sha": git_sha,
        "worktree_digest_sha256": source_start.get("worktree_digest_sha256"),
        "project_logic_source_digest": source_start.get("project_logic_source_digest"),
        "source": {"start": source_start, "end": source_end, "stable": stable},
        "checks": checks,
        "check_catalog_sha256": canonical_sha256([check["id"] for check in checks]),
        "summary": summary,
        "evidence_root": str(evidence_root),
        "durable": durable,
        "artifacts": artifacts,
        "artifact_manifest_sha256": canonical_sha256(
            sorted(artifacts, key=lambda item: item["id"])
        ),
        "gate_eligible": final_status == "PASS" and stable and durable,
    }
    receipt_path = evidence_root / "receipt.json"
    receipt_path.write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return receipt_path, receipt


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ReceiptValidationError(message)


def validate(
    receipt_path: Path,
    *,
    repo: Path,
    require_clean: bool = False,
    max_age_hours: int = 24,
    expected_gate: str | None = None,
    expected_mode: str | None = None,
    expected_checks: list[str] | None = None,
    now: datetime | None = None,
    current_source: dict[str, Any] | None = None,
) -> dict[str, Any]:
    repo = repo.resolve()
    _require(receipt_path.is_file() and not receipt_path.is_symlink(), "receipt is missing")
    receipt = load_json_strict(receipt_path)
    _require(receipt.get("schema") == SCHEMA, f"schema must be exactly {SCHEMA!r}")
    gate = receipt.get("gate")
    _require(isinstance(gate, dict), "gate must be an object")
    _require(
        gate.get("id") in GATES and gate.get("mode") in GATES[gate.get("id")],
        "gate id/mode is unknown",
    )
    if expected_gate is not None:
        _require(gate.get("id") == expected_gate, f"gate.id must be {expected_gate!r}")
    if expected_mode is not None:
        _require(gate.get("mode") == expected_mode, f"gate.mode must be {expected_mode!r}")
    _require(receipt.get("status") == "PASS", "status must be exactly 'PASS'")
    _require(receipt.get("gate_eligible") is True, "receipt is not gate eligible")
    _require(receipt.get("reasons") == [], "a PASS receipt carries no reasons")

    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    started = _parse_timestamp(receipt.get("started_at"), "started_at")
    completed = _parse_timestamp(receipt.get("completed_at"), "completed_at")
    generated = _parse_timestamp(receipt.get("generated_at"), "generated_at")
    _require(started <= completed <= generated, "receipt timestamps are out of order")
    age_seconds = (now - generated).total_seconds()
    _require(age_seconds >= -300, "receipt timestamp is in the future")
    _require(
        age_seconds <= max_age_hours * 3600,
        f"receipt is stale: age_seconds={int(age_seconds)}",
    )

    source = receipt.get("source")
    _require(isinstance(source, dict), "source must be an object")
    _require(source.get("stable") is True, "source.stable must be true")
    _require(source.get("start") == source.get("end"), "source state changed during gate")
    start = source.get("start")
    _require(isinstance(start, dict), "source.start must be an object")
    current = current_source or capture_source_state(repo)
    for key in sorted(current):
        _require(start.get(key) == current[key], f"source drift against checkout: {key}")
    _require(set(start) == set(current), "source.start keys differ from capture")
    _require(receipt.get("git_sha") == current["git_sha"], "git_sha drift")
    _require(
        receipt.get("worktree_digest_sha256") == current["worktree_digest_sha256"],
        "worktree_digest_sha256 drift",
    )
    _require(
        receipt.get("project_logic_source_digest")
        == current["project_logic_source_digest"],
        "project_logic_source_digest drift",
    )
    if require_clean:
        _require(start.get("git_dirty") is False, "release evidence requires a clean worktree")

    raw_root = receipt.get("evidence_root")
    _require(isinstance(raw_root, str) and raw_root.startswith("/"), "evidence_root must be absolute")
    evidence_root = Path(raw_root)
    _require(not evidence_root.is_symlink(), "evidence_root cannot be a symlink")
    evidence_root = evidence_root.resolve()
    _require(receipt.get("durable") is True, "receipt is not durable")
    _require(is_durable_root(evidence_root, repo), "evidence root is temporary or inside the worktree")
    _require(
        _is_relative_to(receipt_path.resolve(), evidence_root),
        "receipt must live under evidence_root",
    )

    artifacts = receipt.get("artifacts")
    _require(isinstance(artifacts, list), "artifacts must be a list")
    indexed: dict[str, dict[str, Any]] = {}
    for index, artifact in enumerate(artifacts):
        _require(isinstance(artifact, dict), f"artifacts[{index}] must be an object")
        artifact_id = artifact.get("id")
        _require(
            isinstance(artifact_id, str) and artifact_id not in indexed,
            f"artifacts[{index}].id is invalid or duplicated",
        )
        relative = artifact.get("path")
        _require(
            isinstance(relative, str) and relative and not Path(relative).is_absolute(),
            f"artifact {artifact_id} path must be relative",
        )
        candidate = evidence_root / relative
        _require(not candidate.is_symlink(), f"artifact cannot be a symlink: {artifact_id}")
        resolved = candidate.resolve()
        _require(_is_relative_to(resolved, evidence_root), f"artifact escapes evidence_root: {artifact_id}")
        _require(resolved.is_file(), f"artifact is missing: {artifact_id}")
        size = artifact.get("size_bytes")
        _require(
            isinstance(size, int) and not isinstance(size, bool) and size >= 0,
            f"artifact {artifact_id}.size_bytes is invalid",
        )
        _require(resolved.stat().st_size == size, f"artifact size drift: {artifact_id}")
        _require(file_sha256(resolved) == artifact.get("sha256"), f"artifact hash drift: {artifact_id}")
        indexed[artifact_id] = artifact
    _require(
        receipt.get("artifact_manifest_sha256")
        == canonical_sha256(sorted(artifacts, key=lambda item: item["id"])),
        "artifact_manifest_sha256 drift",
    )

    checks = receipt.get("checks")
    _require(isinstance(checks, list) and checks, "checks must be a non-empty list")
    check_ids: list[str] = []
    referenced: set[str] = set()
    for index, check in enumerate(checks):
        _require(isinstance(check, dict), f"checks[{index}] must be an object")
        check_id = check.get("id")
        _require(
            isinstance(check_id, str)
            and STEP_ID_RE.fullmatch(check_id) is not None
            and check_id not in check_ids,
            f"checks[{index}].id is invalid or duplicated",
        )
        check_ids.append(check_id)
        _require(check.get("status") == "PASS", f"check did not pass: {check_id}")
        _require(check.get("exit_code") == 0, f"check exit code is not 0: {check_id}")
        ids = check.get("artifact_ids")
        _require(isinstance(ids, list) and ids, f"check has no log artifact: {check_id}")
        for artifact_id in ids:
            _require(artifact_id in indexed, f"check references unknown artifact: {check_id}")
            _require(artifact_id not in referenced, f"artifact shared by two checks: {artifact_id}")
            referenced.add(artifact_id)
    _require(referenced == set(indexed), "artifact not referenced by any check")
    _require(
        receipt.get("check_catalog_sha256") == canonical_sha256(check_ids),
        "check catalog drift",
    )
    if expected_checks is None and gate.get("id") == "local_ci":
        expected_checks = list(LOCAL_CI_CHECKS[gate["mode"]])
    if expected_checks is not None:
        _require(check_ids == expected_checks, "check catalog mismatch")
    summary = receipt.get("summary")
    _require(
        summary
        == {
            "check_count": len(checks),
            "passed": len(checks),
            "failed": 0,
            "skipped": 0,
            "blocked": 0,
        },
        "summary does not match checks",
    )
    return receipt


def _main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    capture_parser = sub.add_parser("capture")
    capture_parser.add_argument("--repo", type=Path, default=ROOT_DIR)
    capture_parser.add_argument("--out", type=Path, required=True)

    finalize_parser = sub.add_parser("finalize")
    finalize_parser.add_argument("--repo", type=Path, default=ROOT_DIR)
    finalize_parser.add_argument("--gate", required=True, choices=sorted(GATES))
    finalize_parser.add_argument("--mode", required=True)
    finalize_parser.add_argument("--run-id", required=True)
    finalize_parser.add_argument("--started-at", required=True)
    finalize_parser.add_argument("--source-start", type=Path, required=True)
    finalize_parser.add_argument("--steps", type=Path, required=True)
    finalize_parser.add_argument(
        "--steps-format", required=True, choices=("local-ci-v1", "e2e-v1")
    )
    finalize_parser.add_argument("--status", required=True, choices=STATUSES)
    finalize_parser.add_argument("--receipt-root", type=Path, required=True)

    validate_parser = sub.add_parser("validate")
    validate_parser.add_argument("receipt", type=Path)
    validate_parser.add_argument("--repo", type=Path, default=ROOT_DIR)
    validate_parser.add_argument("--require-clean", action="store_true")
    validate_parser.add_argument("--max-age-hours", type=int, default=24)
    validate_parser.add_argument("--gate", choices=sorted(GATES))
    validate_parser.add_argument("--mode")

    args = parser.parse_args(argv)
    try:
        if args.command == "capture":
            state = capture_source_state(args.repo)
            args.out.write_text(
                json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8"
            )
            return 0
        if args.command == "finalize":
            path, receipt = finalize(
                repo=args.repo,
                gate=args.gate,
                mode=args.mode,
                run_id=args.run_id,
                started_at=args.started_at,
                source_start_path=args.source_start,
                steps_path=args.steps,
                steps_format=args.steps_format,
                status=args.status,
                receipt_root=args.receipt_root,
            )
            print(
                json.dumps(
                    {
                        "receipt": str(path),
                        "status": receipt["status"],
                        "gate_eligible": receipt["gate_eligible"],
                        "source_stable": receipt["source"]["stable"],
                        "durable": receipt["durable"],
                        "reasons": receipt["reasons"],
                    },
                    sort_keys=True,
                )
            )
            return 0 if receipt["source"]["stable"] else 1
        validate(
            args.receipt,
            repo=args.repo,
            require_clean=args.require_clean,
            max_age_hours=args.max_age_hours,
            expected_gate=args.gate,
            expected_mode=args.mode,
        )
        print(f"PASS: receipt válido: {args.receipt}")
        return 0
    except (ReceiptValidationError, OSError, ValueError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
