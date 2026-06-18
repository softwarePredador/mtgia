#!/usr/bin/env python3
"""Bootstrap the Hermes lab cron fleet from a versioned manifest.

This keeps the EasyPanel Hermes runtime reproducible:
  - deterministic scripts stay in manaloom-ops
  - provider-backed jobs stay small, delta-gated and low cadence
  - legacy noisy jobs are paused or removed on startup
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


def _resolve_repo_root() -> Path:
    for key in ("MANALOOM_REPO", "MANALOOM_WORKSPACE", "HERMES_REPO_DIR"):
        value = os.environ.get(key)
        if value:
            candidate = Path(value).resolve()
            if candidate.exists():
                return candidate
    return Path(__file__).resolve().parents[2]


REPO_ROOT = _resolve_repo_root()
HERMES_HOME = Path(os.environ.get("HERMES_HOME", "/opt/data")).resolve()
HERMES_STATE_ROOT = Path(os.environ.get("HERMES_STATE_ROOT", str(HERMES_HOME))).resolve()
HERMES_SCRIPTS_DIR = Path(
    os.environ.get("HERMES_CRON_SCRIPTS_DIR", str(HERMES_STATE_ROOT / "scripts"))
).resolve()
JOBS_JSON = Path(
    os.environ.get("HERMES_CRON_JOBS_JSON", str(HERMES_STATE_ROOT / "cron" / "jobs.json"))
).resolve()
ARTIFACT_DIR = Path(
    os.environ.get(
        "HERMES_CRON_BOOTSTRAP_ARTIFACT_DIR",
        str(HERMES_HOME / "artifacts" / "hermes_cron_bootstrap"),
    )
).resolve()
HERMES_CLI = os.environ.get("HERMES_CLI", "/opt/hermes/bin/hermes")
WORKDIR = Path(os.environ.get("MANALOOM_WORKSPACE", str(REPO_ROOT))).resolve()
DELIVER = os.environ.get("HERMES_CRON_DELIVER", "local")
DRY_RUN = os.environ.get("HERMES_CRON_BOOTSTRAP_DRY_RUN", "0") == "1"


@dataclass(frozen=True)
class ManagedJob:
    name: str
    schedule: str
    prompt: str | None = None
    script: str | None = None
    no_agent: bool = False
    deliver: str = DELIVER
    workdir: str | None = str(WORKDIR)


def _delta_gate_profile(name: str, watch_roots: list[str], notes: str) -> dict[str, object]:
    return {
        "job_name": name,
        "watch_roots": watch_roots,
        "notes": notes,
    }


PROVIDER_GATE_PROFILES = {
    "manaloom-commander-knowledge-deep-gate.py": _delta_gate_profile(
        "manaloom-commander-knowledge-deep",
        [
            "docs/hermes-analysis/IMPLEMENTATION_GAPS.md",
            "docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md",
            "docs/hermes-analysis/manaloom-knowledge/decks",
            "docs/hermes-analysis/manaloom-knowledge/GAME_CHANGERS.md",
            "server/test/artifacts",
        ],
        "wake only when commander-learning inputs or recent artifacts changed",
    ),
    "manaloom-gamechanger-research-gate.py": _delta_gate_profile(
        "manaloom-gamechanger-research",
        [
            "docs/hermes-analysis/manaloom-knowledge/GAME_CHANGERS.md",
            "docs/hermes-analysis/IMPLEMENTATION_GAPS.md",
            "server/test/edh_bracket_policy_test.dart",
            "server/test/artifacts",
        ],
        "wake only when gamechanger or bracket evidence changed",
    ),
    "manaloom-knowledge-synthesis-gate.py": _delta_gate_profile(
        "manaloom-knowledge-synthesis",
        [
            "docs/hermes-analysis/IMPLEMENTATION_GAPS.md",
            "docs/hermes-analysis/PENDING_TASKS.md",
            "docs/hermes-analysis/master_optimizer_reports",
            "server/test/artifacts",
        ],
        "wake only when implementation docs or fresh reports changed",
    ),
    "mtg-rules-auditor-gate.py": _delta_gate_profile(
        "mtg-rules-auditor",
        [
            "docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md",
            "docs/hermes-analysis/IMPLEMENTATION_GAPS.md",
            "docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.json",
            "docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules.py",
            "docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py",
            "server/test/artifacts",
        ],
        "wake only when battle/rules sources or replay artifacts changed",
    ),
}


PROVIDER_PROMPTS = {
    "manaloom-commander-knowledge-deep": """Audit only commander-learning deltas in the ManaLoom repo.

Rules:
- Work only from current repo files and recent local artifacts.
- Treat `latest_files` from cron context as the first evidence set.
- Never call `read_file` on a directory path; enumerate with `rg --files`, `find`, `ls` or `git diff --name-only`, then open only concrete files.
- Ignore `optional-mcps/`, personal tooling, local agent scaffolding and unrelated manifests unless `latest_files` proves a live ManaLoom runtime dependency.
- Focus on learned decks, commander usage, generate/optimize support, and commander-specific evidence.
- Do not create generic tasks. Every finding must cite a concrete file path.
- If nothing actionable changed, reply exactly [SILENT] and do not emit sections 1-3, bullets, headings, explanations, or any extra text.

Output:
Only when actionable delta exists:
1. concise delta summary
2. concrete findings with evidence
3. classification per finding: implement-now, docs-only, or ignore
""",
    "manaloom-gamechanger-research": """Audit only gamechanger/bracket/restriction deltas in the ManaLoom repo.

Rules:
- Use current repo files and recent local artifacts only.
- Treat `latest_files` from cron context as the first evidence set.
- Never call `read_file` on a directory path; enumerate with `rg --files`, `find`, `ls` or `git diff --name-only`, then open only concrete files.
- Ignore `optional-mcps/`, personal tooling, local agent scaffolding and unrelated manifests unless `latest_files` proves a live ManaLoom runtime dependency.
- Distinguish official-rule evidence from heuristic/product policy.
- Cite concrete file paths for every claim.
- If no material delta exists, reply exactly [SILENT] and do not emit sections 1-3, bullets, headings, explanations, or any extra text.

Output:
Only when material delta exists:
1. concise delta summary
2. confirmed gaps or regressions
3. recommended next action per gap
""",
    "manaloom-knowledge-synthesis": """Synthesize only delta-backed implementation tasks from the ManaLoom repo.

Rules:
- Use only repo-local evidence and recent artifacts.
- Treat `latest_files` from cron context as the first evidence set.
- Never call `read_file` on a directory path; enumerate with `rg --files`, `find`, `ls` or `git diff --name-only`, then open only concrete files.
- Ignore `optional-mcps/`, external plugin manifests, local agent scaffolding and unrelated infra unless `latest_files` shows they affect live ManaLoom runtime paths under `server/`, `app/`, `docs/hermes-analysis/` or `server/test/artifacts/`.
- No broad brainstorming, no duplicated tasks, no generic cleanup items.
- Prefer P1/P2 actions with exact file evidence.
- If there is no new actionable delta, reply exactly [SILENT] and do not emit sections 1-3, bullets, headings, explanations, or any extra text.

Output:
Only when actionable delta exists:
1. short synthesis
2. actionable tasks with priority and evidence
3. rejected/ignored findings with reason if needed
""",
    "mtg-rules-auditor": """Audit only MTG rules and battle-logic deltas in the ManaLoom repo.

Rules:
- Separate official rules gaps from strategic-heuristic gaps.
- Treat `latest_files` from cron context as the first evidence set.
- Never call `read_file` on a directory path; enumerate with `rg --files`, `find`, `ls` or `git diff --name-only`, then open only concrete files.
- Ignore `optional-mcps/`, personal tooling, local agent scaffolding and unrelated manifests unless `latest_files` proves a live ManaLoom runtime dependency.
- Cite current code/docs/artifacts for every finding.
- Do not propose app/UI work here.
- If no material rules delta exists, reply exactly [SILENT] and do not emit sections 1-3, bullets, headings, explanations, or any extra text.

Output:
Only when material rules delta exists:
1. rules delta summary
2. concrete battle/rules findings with evidence
3. whether each item is release-blocking, safe backlog, or docs-only
""",
}


DESIRED_JOBS = [
    ManagedJob(
        name="manaloom-docs-branch-sync",
        schedule="*/20 * * * *",
        script="manaloom-docs-branch-sync.sh",
        no_agent=True,
        deliver=DELIVER,
        workdir=None,
    ),
    ManagedJob(
        name="manaloom-commander-knowledge-deep",
        schedule="0 */8 * * *",
        prompt=PROVIDER_PROMPTS["manaloom-commander-knowledge-deep"],
        script="manaloom-commander-knowledge-deep-gate.py",
    ),
    ManagedJob(
        name="manaloom-gamechanger-research",
        schedule="0 */12 * * *",
        prompt=PROVIDER_PROMPTS["manaloom-gamechanger-research"],
        script="manaloom-gamechanger-research-gate.py",
    ),
    ManagedJob(
        name="manaloom-knowledge-synthesis",
        schedule="30 */12 * * *",
        prompt=PROVIDER_PROMPTS["manaloom-knowledge-synthesis"],
        script="manaloom-knowledge-synthesis-gate.py",
    ),
    ManagedJob(
        name="mtg-rules-auditor",
        schedule="45 */12 * * *",
        prompt=PROVIDER_PROMPTS["mtg-rules-auditor"],
        script="mtg-rules-auditor-gate.py",
    ),
]

PAUSE_JOBS = {
    "manaloom-hermes-normal-audit",
    "manaloom-hermes-weekly-parallel-audit",
    "manaloom-tag-accuracy-reporter",
    "manaloom-code-structure-auditor",
    "manaloom-logic-coherence-auditor",
    "manaloom-master-optimizer-slot-scan",
    "manaloom-master-optimizer-end-to-end",
}

REMOVE_JOBS = {
    "manaloom-master-watchdog",
    "manaloom-pull-learning-events",
    "lorehold-knowncards-validator",
    "manaloom-master-optimizer-preflight",
    "manaloom-knowledge-import",
    "manaloom-auto-sync-learned-decks",
    "manaloom-auto-promote-learned",
    "manaloom-mana-base-validator",
    "manaloom-cron-governor-report",
    "manaloom-manager-watchdog",
    "manaloom-flutter-ui-auditor",
    "manaloom-master-optimizer-loop",
    "lorehold-knowncards-generator",
    "lorehold-universal-optimizer",
    "lorehold-deck-scout",
    "lorehold-deck-validator",
    "lorehold-evolution-oracle",
    "lorehold-mulligan-analyst",
    "lorehold-wincon-hunter",
    "lorehold-wincon-tester",
    "lorehold-deckbuilding-methodology",
    "lorehold-wincon-builder",
}


DELTA_GATE_SCRIPT = """#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve()
SCRIPT_NAME = SCRIPT_PATH.name
PROFILE_MAP = {profile_json}

profile = PROFILE_MAP.get(SCRIPT_NAME)
if profile is None:
    print(json.dumps({{"wakeAgent": False, "error": f"unknown gate profile: {{SCRIPT_NAME}}"}}))
    sys.exit(0)

repo = Path(os.environ.get("MANALOOM_WORKSPACE") or os.environ.get("HERMES_REPO_DIR") or "/opt/data/workspace/mtgia").resolve()
state_root = Path(os.environ.get("HERMES_STATE_ROOT", "/opt/data")).resolve() / "data" / "manaloom" / "cron-gates"
jobs_json = Path(os.environ.get("HERMES_CRON_JOBS_JSON", str(Path(os.environ.get("HERMES_STATE_ROOT", "/opt/data")).resolve() / "cron" / "jobs.json"))).resolve()
state_root.mkdir(parents=True, exist_ok=True)
state_file = state_root / f"{{SCRIPT_PATH.stem}}.json"

def _job_last_status() -> str | None:
    if not jobs_json.exists():
        return None
    try:
        payload = json.loads(jobs_json.read_text())
    except Exception:
        return None
    jobs = payload.get("jobs", payload) if isinstance(payload, dict) else payload
    if not isinstance(jobs, list):
        return None
    for job in jobs:
        if str(job.get("name", "")).lower() == str(profile["job_name"]).lower():
            return job.get("last_status")
    return None

def _collect_entries() -> list[tuple[str, int, int]]:
    entries: list[tuple[str, int, int]] = []
    for rel in profile["watch_roots"]:
        target = (repo / rel).resolve()
        if not target.exists():
            continue
        if target.is_file():
            stat = target.stat()
            entries.append((str(target.relative_to(repo)), stat.st_mtime_ns, stat.st_size))
            continue
        for child in sorted(target.rglob("*")):
            if not child.is_file():
                continue
            stat = child.stat()
            entries.append((str(child.relative_to(repo)), stat.st_mtime_ns, stat.st_size))
    return entries

def _head() -> str:
    try:
        return subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "no-git-head"

entries = _collect_entries()
head = _head()
signature_input = "\\n".join([head] + [f"{{path}}|{{mtime}}|{{size}}" for path, mtime, size in entries])
signature = hashlib.sha256(signature_input.encode("utf-8")).hexdigest()
last_status = _job_last_status()

prior = {{}}
if state_file.exists():
    try:
        prior = json.loads(state_file.read_text())
    except Exception:
        prior = {{}}

changed = signature != prior.get("signature")
retry_after_error = last_status not in (None, "ok")
wake = changed or retry_after_error or not prior

payload = {{
    "signature": signature,
    "head": head,
    "file_count": len(entries),
    "latest_files": [path for path, _, _ in entries[-8:]],
}}
state_file.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\\n")

if not wake:
    print(json.dumps({{"wakeAgent": False}}))
    sys.exit(0)

context = {{
    "repo_head": head,
    "scope_summary": profile["notes"],
    "watch_root_count": len(profile["watch_roots"]),
    "watch_root_instruction": "Latest_files are the first evidence set. If more evidence is needed, enumerate concrete files first and never pass a directory path to read_file.",
    "file_count": len(entries),
    "latest_files": [path for path, _, _ in entries[-8:]],
    "reason": "retry_after_error" if retry_after_error and not changed else ("changed_inputs" if changed else "first_run"),
    "notes": profile["notes"],
}}
print(json.dumps({{"wakeAgent": True, "context": context}}))
"""


def _load_jobs() -> list[dict[str, object]]:
    if not JOBS_JSON.exists():
        return []
    try:
        payload = json.loads(JOBS_JSON.read_text())
    except json.JSONDecodeError:
        return []
    jobs = payload.get("jobs", payload) if isinstance(payload, dict) else payload
    if isinstance(jobs, list):
        return [job for job in jobs if isinstance(job, dict)]
    return []


def _job_state(job: dict[str, object]) -> str:
    state = str(job.get("state") or "")
    if state:
        return state.lower()
    return "active" if bool(job.get("enabled", True)) else "paused"


def _schedule_matches(job: dict[str, object], schedule: str) -> bool:
    candidates = []
    schedule_block = job.get("schedule")
    if isinstance(schedule_block, dict):
        for key in ("expr", "display"):
            value = schedule_block.get(key)
            if value:
                candidates.append(str(value))
    else:
        if schedule_block:
            candidates.append(str(schedule_block))
    for key in ("schedule_display", "schedule_expr"):
        value = job.get(key)
        if value:
            candidates.append(str(value))
    return schedule in candidates


def _job_matches(job: dict[str, object], spec: ManagedJob) -> bool:
    if _job_state(job) != "active":
        return False
    if not _schedule_matches(job, spec.schedule):
        return False
    if str(job.get("deliver") or DELIVER) != spec.deliver:
        return False
    if bool(job.get("no_agent", False)) != spec.no_agent:
        return False
    if spec.workdir is None:
        if job.get("workdir"):
            return False
    else:
        actual_workdir = str(job.get("workdir") or "")
        try:
            if Path(actual_workdir).resolve() != Path(spec.workdir).resolve():
                return False
        except Exception:
            if actual_workdir != spec.workdir:
                return False
    if spec.script:
        if Path(str(job.get("script") or "")).name != spec.script:
            return False
    if spec.prompt is not None and str(job.get("prompt") or "") != spec.prompt:
        return False
    return True


def _run(cmd: list[str], actions: list[dict[str, object]]) -> None:
    actions.append({"command": cmd})
    if DRY_RUN:
        return
    subprocess.run(cmd, check=True)


def _script_path(name: str) -> Path:
    return HERMES_SCRIPTS_DIR / name


def _resolve_docs_branch_sync_source() -> Path:
    candidates = [
        REPO_ROOT / "server" / "bin" / "hermes_docs_branch_sync.sh",
        Path("/opt/bootstrap/hermes_docs_branch_sync.sh"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    searched = ", ".join(str(candidate) for candidate in candidates)
    raise FileNotFoundError(f"hermes_docs_branch_sync.sh not found in: {searched}")


def _install_scripts() -> None:
    HERMES_SCRIPTS_DIR.mkdir(parents=True, exist_ok=True)
    source_docs_sync = _resolve_docs_branch_sync_source()
    target_docs_sync = _script_path("manaloom-docs-branch-sync.sh")
    shutil.copy2(source_docs_sync, target_docs_sync)
    target_docs_sync.chmod(0o755)

    rendered_gate = DELTA_GATE_SCRIPT.format(
        profile_json=json.dumps(PROVIDER_GATE_PROFILES, indent=2, sort_keys=True)
    )
    for script_name in PROVIDER_GATE_PROFILES:
        path = _script_path(script_name)
        path.write_text(rendered_gate)
        path.chmod(0o755)


def _remove_job(job_id: str, actions: list[dict[str, object]]) -> None:
    _run([HERMES_CLI, "cron", "remove", job_id], actions)


def _pause_job(job_id: str, actions: list[dict[str, object]]) -> None:
    _run([HERMES_CLI, "cron", "pause", job_id], actions)


def _create_job(spec: ManagedJob, actions: list[dict[str, object]]) -> None:
    cmd = [HERMES_CLI, "cron", "create", spec.schedule]
    if spec.prompt is not None:
        cmd.append(spec.prompt)
    cmd.extend(["--name", spec.name, "--deliver", spec.deliver])
    if spec.script:
        cmd.extend(["--script", spec.script])
    if spec.no_agent:
        cmd.append("--no-agent")
    if spec.workdir:
        cmd.extend(["--workdir", spec.workdir])
    _run(cmd, actions)


def _write_report(actions: list[dict[str, object]], jobs: list[dict[str, object]]) -> Path:
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    report = ARTIFACT_DIR / "latest_bootstrap_report.json"
    payload = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "dry_run": DRY_RUN,
        "repo_root": str(REPO_ROOT),
        "workdir": str(WORKDIR),
        "scripts_dir": str(HERMES_SCRIPTS_DIR),
        "jobs_json": str(JOBS_JSON),
        "desired_jobs": [spec.name for spec in DESIRED_JOBS],
        "paused_jobs": sorted(PAUSE_JOBS),
        "removed_jobs": sorted(REMOVE_JOBS),
        "actions": actions,
        "existing_jobs_count": len(jobs),
    }
    report.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    return report


def main() -> int:
    _install_scripts()
    jobs = _load_jobs()
    jobs_by_name: dict[str, list[dict[str, object]]] = {}
    for job in jobs:
        jobs_by_name.setdefault(str(job.get("name", "")).strip().lower(), []).append(job)

    actions: list[dict[str, object]] = []

    for legacy_name in sorted(REMOVE_JOBS):
        for job in jobs_by_name.get(legacy_name.lower(), []):
            job_id = str(job.get("id") or legacy_name)
            _remove_job(job_id, actions)

    for paused_name in sorted(PAUSE_JOBS):
        for job in jobs_by_name.get(paused_name.lower(), []):
            if _job_state(job) == "paused":
                continue
            job_id = str(job.get("id") or paused_name)
            _pause_job(job_id, actions)

    for spec in DESIRED_JOBS:
        existing = jobs_by_name.get(spec.name.lower(), [])
        if len(existing) == 1 and _job_matches(existing[0], spec):
            continue
        for job in existing:
            job_id = str(job.get("id") or spec.name)
            _remove_job(job_id, actions)
        _create_job(spec, actions)

    report = _write_report(actions, jobs)
    print(f"HERMES_CRON_BOOTSTRAP_REPORT: {report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
