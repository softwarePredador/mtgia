#!/usr/bin/env python3
"""Run resumable XMage/Forge battle queues with positive-evidence gates.

The runner is intended for controlled offline learning batches. It never falls
back after an operational engine failure, never treats a timeout as a draw,
and never promotes a deck. Completed comparisons become inputs for a separate
statistical/strategy decision only after both variants have natural exposure.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
import time
import unicodedata
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence


REGISTRY_SCHEMA = "external_battle_async_registry_v1"
CHECKPOINT_SCHEMA = "external_battle_async_checkpoint_v1"
LEARNING_SCHEMA = "external_battle_learning_v1"
COMPARISON_GATE_SCHEMA = "external_battle_comparison_gate_v1"
TERMINAL_JOB_STATUSES = {"completed", "failed", "timeout", "coverage_incomplete"}
POSITIVE_ACTION_TOKENS = (
    "ability",
    "activate",
    "attack",
    "battlefield",
    "block",
    "cast",
    "counter",
    "damage",
    "permanent",
    "spell",
    "stack",
    "tap",
    "zone",
)
NAME_FIELDS = (
    "source_card_name",
    "card_name",
    "object_name",
    "permanent_name",
    "attacker_name",
    "blocker_name",
    "card",
    "source",
    "target_card",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_name(value: Any) -> str:
    text = unicodedata.normalize("NFKC", str(value or "")).strip().casefold()
    return re.sub(r"\s+", " ", text)


def stable_registry_hash(payload: Mapping[str, Any]) -> str:
    stable = json.dumps(payload, sort_keys=True, ensure_ascii=True, separators=(",", ":"))
    return hashlib.sha256(stable.encode("utf-8")).hexdigest()


def atomic_write_json(path: Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def atomic_write_gzip_json(path: Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    raw = (json.dumps(payload, ensure_ascii=True, separators=(",", ":")) + "\n").encode("utf-8")
    temporary.write_bytes(gzip.compress(raw, compresslevel=6, mtime=0))
    temporary.replace(path)


@dataclass(frozen=True)
class HttpResult:
    status: int
    body: dict[str, Any]


class JsonHttpClient:
    def post(self, url: str, payload: Mapping[str, Any], timeout: float) -> HttpResult:
        return self._request("POST", url, payload=payload, timeout=timeout)

    def get(self, url: str, timeout: float) -> HttpResult:
        return self._request("GET", url, payload=None, timeout=timeout)

    def _request(
        self,
        method: str,
        url: str,
        *,
        payload: Mapping[str, Any] | None,
        timeout: float,
    ) -> HttpResult:
        data = None
        headers: dict[str, str] = {}
        if payload is not None:
            data = json.dumps(payload, ensure_ascii=True, separators=(",", ":")).encode("utf-8")
            headers["content-type"] = "application/json"
        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return HttpResult(response.status, _decode_json(response.read()))
        except urllib.error.HTTPError as error:
            return HttpResult(error.code, _decode_json(error.read()))


def _decode_json(raw: bytes) -> dict[str, Any]:
    try:
        value = json.loads(raw.decode("utf-8", errors="replace"))
    except json.JSONDecodeError as error:
        raise RuntimeError("engine returned non-JSON content") from error
    if not isinstance(value, dict):
        raise RuntimeError("engine returned a non-object JSON payload")
    return value


def _event_type(event: Mapping[str, Any]) -> str:
    for field in ("event_type", "type", "event", "kind", "action"):
        value = normalize_name(event.get(field)).replace(" ", "_")
        if value:
            return value
    return "unknown"


def _events(result: Mapping[str, Any]) -> list[dict[str, Any]]:
    candidates: list[Any] = [result.get("events")]
    for container_name in ("replay", "game", "telemetry"):
        container = result.get(container_name)
        if isinstance(container, Mapping):
            candidates.append(container.get("events"))
    for candidate in candidates:
        if isinstance(candidate, list):
            return [dict(item) for item in candidate if isinstance(item, Mapping)]
    return []


def _learning_contract(result: Mapping[str, Any]) -> dict[str, Any]:
    contract = result.get("learning_contract")
    if isinstance(contract, Mapping):
        return dict(contract)
    replay = result.get("replay")
    if isinstance(replay, Mapping) and isinstance(replay.get("learning_contract"), Mapping):
        return dict(replay["learning_contract"])
    return {}


def completed_result_error(
    result: Mapping[str, Any],
    *,
    expected_engine: str | None = None,
) -> str | None:
    status = normalize_name(result.get("status"))
    if status != "completed":
        return "engine_result_not_completed"
    if result.get("error") is not None:
        return "engine_result_contains_error"
    if (
        expected_engine is not None
        and normalize_name(result.get("engine")) != normalize_name(expected_engine)
    ):
        return "engine_result_mismatch"
    turns = result.get("turns")
    if not isinstance(turns, int) or isinstance(turns, bool) or turns <= 0:
        return "engine_result_missing_positive_turn_count"
    return None


def _completed(result: Mapping[str, Any], *, expected_engine: str | None = None) -> bool:
    return completed_result_error(result, expected_engine=expected_engine) is None


def extract_positive_evidence(
    result: Mapping[str, Any],
    *,
    focus_cards: Sequence[str] = (),
    expected_engine: str | None = None,
    same_lane: bool = False,
    natural_sample: bool = True,
) -> dict[str, Any]:
    contract = _learning_contract(result)
    contract_valid = (
        contract.get("schema_version") == LEARNING_SCHEMA
        and contract.get("absence_proves_nonuse") is False
    )
    exposed: defaultdict[str, set[str]] = defaultdict(set)
    display_names: dict[str, str] = {}
    event_counts: defaultdict[str, int] = defaultdict(int)
    for event in _events(result):
        event_type = _event_type(event)
        if not any(token in event_type for token in POSITIVE_ACTION_TOKENS):
            continue
        event_counts[event_type] += 1
        for field in NAME_FIELDS:
            raw_name = str(event.get(field) or "").strip()
            if raw_name:
                normalized = normalize_name(raw_name)
                exposed[normalized].add(event_type)
                display_names.setdefault(normalized, raw_name)
    focus = [name for name in focus_cards if str(name).strip()]
    focus_rows = []
    for card in focus:
        normalized = normalize_name(card)
        types = sorted(exposed.get(normalized, set()))
        focus_rows.append(
            {
                "card_name": card,
                "normalized_name": normalized,
                "positive_exposure": bool(types),
                "event_types": types,
            }
        )
    completed = _completed(result, expected_engine=expected_engine)
    all_focus_exposed = bool(focus_rows) and all(row["positive_exposure"] for row in focus_rows)
    requested_exposure_ready = all_focus_exposed if focus_rows else bool(exposed)
    positive_exposure_ready = completed and contract_valid and requested_exposure_ready
    natural_same_lane_exposure = positive_exposure_ready and same_lane and natural_sample
    return {
        "schema_version": "battle_positive_evidence_v1",
        "completed": completed,
        "learning_contract_valid": contract_valid,
        "learning_contract_schema": contract.get("schema_version"),
        "absence_proves_nonuse": False,
        "event_stream_is_lower_bound": True,
        "event_counts": dict(sorted(event_counts.items())),
        "exposed_card_names": sorted(display_names.values(), key=normalize_name),
        "exposed_card_names_normalized": sorted(exposed),
        "focus_cards": focus_rows,
        "all_focus_cards_exposed": all_focus_exposed,
        "positive_exposure_ready": positive_exposure_ready,
        "same_lane": same_lane,
        "natural_sample": natural_sample,
        "natural_same_lane_exposure": natural_same_lane_exposure,
        "comparison_input_ready": False,
        "strategy_proof": False,
        "swap_superiority_proven": False,
        "promotion_allowed": False,
    }


def _safe_job_id(value: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("._")
    if not safe:
        raise ValueError("job_id must contain at least one safe character")
    return safe[:160]


def new_checkpoint(registry: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": CHECKPOINT_SCHEMA,
        "registry_hash": stable_registry_hash(registry),
        "created_at": utc_now(),
        "updated_at": utc_now(),
        "status": "pending",
        "jobs": {},
        "comparison_gates": {},
    }


def load_checkpoint(path: Path, registry: Mapping[str, Any]) -> dict[str, Any]:
    expected_hash = stable_registry_hash(registry)
    if not path.exists():
        return new_checkpoint(registry)
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or payload.get("schema_version") != CHECKPOINT_SCHEMA:
        raise ValueError("checkpoint schema is not supported")
    if payload.get("registry_hash") != expected_hash:
        raise ValueError("checkpoint belongs to a different battle registry")
    jobs = payload.get("jobs")
    if not isinstance(jobs, dict):
        payload["jobs"] = {}
    for state in payload["jobs"].values():
        if isinstance(state, dict) and state.get("status") == "running":
            state["status"] = "pending"
            state["recovered_from_interruption"] = True
    return payload


def validate_registry(registry: Mapping[str, Any]) -> None:
    if registry.get("schema_version") != REGISTRY_SCHEMA:
        raise ValueError(f"registry schema must be {REGISTRY_SCHEMA}")
    jobs = registry.get("jobs")
    if not isinstance(jobs, list) or not jobs:
        raise ValueError("registry jobs must be a non-empty list")
    job_ids: set[str] = set()
    safe_job_ids: set[str] = set()
    comparison_samples: set[tuple[str, str, int]] = set()
    for job in jobs:
        if not isinstance(job, Mapping):
            raise ValueError("registry jobs must be objects")
        job_id = str(job.get("job_id") or "").strip()
        if not job_id or job_id in job_ids:
            raise ValueError(f"job_id must be present and unique: {job_id!r}")
        safe_job_id = _safe_job_id(job_id)
        if safe_job_id in safe_job_ids:
            raise ValueError(f"job_id file-name collision: {safe_job_id!r}")
        job_ids.add(job_id)
        safe_job_ids.add(safe_job_id)
        request = job.get("request")
        if not isinstance(request, Mapping):
            raise ValueError(f"job {job_id!r} requires a request object")
        seed = request.get("seed")
        if not isinstance(seed, int) or isinstance(seed, bool):
            raise ValueError(f"job {job_id!r} requires an integer seed")
        comparison_id = str(job.get("comparison_id") or "").strip()
        if not comparison_id:
            continue
        variant = str(job.get("variant") or "").strip()
        if variant not in {"base", "candidate"}:
            raise ValueError(
                f"comparison job {job_id!r} requires variant base or candidate"
            )
        sample_key = (comparison_id, variant, seed)
        if sample_key in comparison_samples:
            raise ValueError(f"duplicate comparison sample: {sample_key!r}")
        comparison_samples.add(sample_key)


def evaluate_comparisons(
    registry: Mapping[str, Any],
    checkpoint: Mapping[str, Any],
) -> dict[str, Any]:
    groups: defaultdict[str, list[tuple[Mapping[str, Any], Mapping[str, Any]]]] = defaultdict(list)
    states = checkpoint.get("jobs") or {}
    for job in registry.get("jobs") or []:
        if not isinstance(job, Mapping):
            continue
        comparison_id = str(job.get("comparison_id") or "").strip()
        state = states.get(str(job.get("job_id") or ""), {})
        if comparison_id and isinstance(state, Mapping):
            groups[comparison_id].append((job, state))

    minimum = max(1, int(registry.get("minimum_completed_per_variant") or 3))
    result: dict[str, Any] = {}
    for comparison_id, entries in sorted(groups.items()):
        variants: defaultdict[str, list[tuple[Mapping[str, Any], Mapping[str, Any]]]] = defaultdict(list)
        for job, state in entries:
            variants[str(job.get("variant") or "unknown")].append((job, state))
        base = variants.get("base", [])
        candidate = variants.get("candidate", [])

        def completed(values: Sequence[tuple[Mapping[str, Any], Mapping[str, Any]]]) -> list[tuple[Mapping[str, Any], Mapping[str, Any]]]:
            return [entry for entry in values if entry[1].get("status") == "completed"]

        def exposure_ready(
            entry: tuple[Mapping[str, Any], Mapping[str, Any]],
        ) -> bool:
            evidence = entry[1].get("evidence")
            return (
                isinstance(evidence, Mapping)
                and evidence.get("positive_exposure_ready") is True
            )

        base_completed = completed(base)
        candidate_completed = completed(candidate)
        base_exposure_eligible = [
            entry
            for entry in base_completed
            if exposure_ready(entry)
        ]
        candidate_exposure_eligible = [
            entry
            for entry in candidate_completed
            if exposure_ready(entry)
        ]
        base_seeds = {entry[0].get("request", {}).get("seed") for entry in base_completed}
        candidate_seeds = {entry[0].get("request", {}).get("seed") for entry in candidate_completed}
        base_exposure_seeds = {
            entry[0].get("request", {}).get("seed") for entry in base_exposure_eligible
        }
        candidate_exposure_seeds = {
            entry[0].get("request", {}).get("seed")
            for entry in candidate_exposure_eligible
        }
        base_exposed = {
            normalize_name(row.get("card_name"))
            for _job, state in base_completed
            for row in (state.get("evidence", {}).get("focus_cards") or [])
            if row.get("positive_exposure") is True
        }
        candidate_exposed = {
            normalize_name(row.get("card_name"))
            for _job, state in candidate_completed
            for row in (state.get("evidence", {}).get("focus_cards") or [])
            if row.get("positive_exposure") is True
        }
        removed = {
            normalize_name(name)
            for job, _state in base
            for name in (job.get("focus_cards") or [])
        }
        added = {
            normalize_name(name)
            for job, _state in candidate
            for name in (job.get("focus_cards") or [])
        }
        same_lane = bool(entries) and all(job.get("same_lane") is True for job, _state in entries)
        natural = bool(entries) and all(job.get("forced_access") is not True for job, _state in entries)
        completed_enough = (
            len(base_completed) >= minimum
            and len(candidate_completed) >= minimum
            and len(base_seeds) >= minimum
            and len(candidate_seeds) >= minimum
        )
        equal_seed_set = bool(base_seeds) and base_seeds == candidate_seeds
        exposure_qualified_enough = (
            len(base_exposure_seeds) >= minimum
            and len(candidate_exposure_seeds) >= minimum
        )
        equal_exposure_seed_set = (
            bool(base_exposure_seeds)
            and base_exposure_seeds == candidate_exposure_seeds
        )
        focus_exposed = bool(removed) and bool(added) and removed <= base_exposed and added <= candidate_exposed
        timeout_censored = any(
            state.get("status") == "timeout"
            for _job, state in entries
        )
        ready = (
            completed_enough
            and equal_seed_set
            and exposure_qualified_enough
            and equal_exposure_seed_set
            and focus_exposed
            and same_lane
            and natural
        )
        result[comparison_id] = {
            "schema_version": COMPARISON_GATE_SCHEMA,
            "status": "comparison_input_ready" if ready else "insufficient_evidence",
            "minimum_completed_per_variant": minimum,
            "base_completed": len(base_completed),
            "candidate_completed": len(candidate_completed),
            "base_exposure_eligible": len(base_exposure_seeds),
            "candidate_exposure_eligible": len(candidate_exposure_seeds),
            "equal_seed_set": equal_seed_set,
            "equal_exposure_seed_set": equal_exposure_seed_set,
            "exposure_qualified_enough": exposure_qualified_enough,
            "same_lane": same_lane,
            "natural_samples": natural,
            "focus_cards_exposed": focus_exposed,
            "timeout_censored": timeout_censored,
            "comparison_input_ready": ready,
            "swap_superiority_proven": False,
            "promotion_allowed": False,
            "next_gate": "statistical_and_strategy_evaluation" if ready else "collect_more_natural_evidence",
        }
    return result


class BattleQueueRunner:
    def __init__(
        self,
        *,
        registry: Mapping[str, Any],
        checkpoint_path: Path,
        result_dir: Path,
        xmage_url: str,
        forge_url: str,
        request_timeout: float,
        recovery_timeout: float,
        max_attempts: int,
        client: JsonHttpClient | None = None,
        sleeper: Callable[[float], None] = time.sleep,
    ) -> None:
        validate_registry(registry)
        self.registry = registry
        self.checkpoint_path = checkpoint_path
        self.result_dir = result_dir
        self.xmage_url = xmage_url.rstrip("/")
        self.forge_url = forge_url.rstrip("/")
        self.request_timeout = max(1.0, request_timeout)
        self.recovery_timeout = max(1.0, recovery_timeout)
        self.max_attempts = max(1, max_attempts)
        self.client = client or JsonHttpClient()
        self.sleeper = sleeper
        self.checkpoint = load_checkpoint(checkpoint_path, registry)

    def _save(self) -> None:
        self.checkpoint["comparison_gates"] = evaluate_comparisons(self.registry, self.checkpoint)
        self.checkpoint["updated_at"] = utc_now()
        states = list((self.checkpoint.get("jobs") or {}).values())
        self.checkpoint["status"] = "completed" if states and all(
            isinstance(state, Mapping)
            and state.get("status") in TERMINAL_JOB_STATUSES
            for state in states
        ) else "running"
        atomic_write_json(self.checkpoint_path, self.checkpoint)

    def _wait_for_xmage_recovery(self, previous_process_id: str) -> bool:
        deadline = time.monotonic() + self.recovery_timeout
        while time.monotonic() < deadline:
            try:
                response = self.client.get(f"{self.xmage_url}/health", min(5.0, self.request_timeout))
            except Exception:
                self.sleeper(1.0)
                continue
            current = str(response.body.get("sidecar_process_id") or "")
            if (
                response.status == 200
                and response.body.get("status") == "ok"
                and response.body.get("catalog_ready") is True
                and current
                and current != previous_process_id
            ):
                return True
            self.sleeper(1.0)
        return False

    def _attempt(self, engine: str, request: Mapping[str, Any]) -> HttpResult:
        base_url = self.xmage_url if engine == "xmage" else self.forge_url
        return self.client.post(f"{base_url}/simulate", request, self.request_timeout)

    def _run_job(self, job: Mapping[str, Any]) -> dict[str, Any]:
        job_id = str(job.get("job_id") or "").strip()
        request = job.get("request")
        if not job_id or not isinstance(request, Mapping):
            raise ValueError("every job requires job_id and request")
        state = self.checkpoint["jobs"].setdefault(
            job_id,
            {"status": "pending", "attempts": [], "created_at": utc_now()},
        )
        if state.get("status") in TERMINAL_JOB_STATUSES:
            return state
        attempts = state.setdefault("attempts", [])
        if not isinstance(attempts, list):
            raise ValueError(f"checkpoint attempts must be a list for job {job_id!r}")
        state["status"] = "running"
        self._save()

        engine = "xmage"
        first_attempt = len(attempts) + 1
        for attempt_number in range(first_attempt, self.max_attempts + 1):
            started = time.monotonic()
            try:
                response = self._attempt(engine, request)
            except Exception as error:
                state["attempts"].append(
                    {
                        "attempt": attempt_number,
                        "engine": engine,
                        "status": "transport_failure",
                        "error": str(error),
                    }
                )
                state["status"] = "failed"
                state["error"] = str(error)
                self._save()
                return state
            elapsed_ms = round((time.monotonic() - started) * 1000)
            attempt = {
                "attempt": attempt_number,
                "engine": engine,
                "http_status": response.status,
                "elapsed_ms": elapsed_ms,
                "error": response.body.get("error"),
            }
            state["attempts"].append(attempt)
            if response.status == 200:
                result_path = self.result_dir / f"{_safe_job_id(job_id)}.json.gz"
                atomic_write_gzip_json(result_path, response.body)
                evidence = extract_positive_evidence(
                    response.body,
                    focus_cards=[str(card) for card in job.get("focus_cards") or []],
                    expected_engine=engine,
                    same_lane=job.get("same_lane") is True,
                    natural_sample=job.get("forced_access") is not True,
                )
                completion_error = completed_result_error(
                    response.body,
                    expected_engine=engine,
                )
                if completion_error is not None:
                    attempt["status"] = "invalid_completed_result"
                    attempt["error"] = completion_error
                    state.update(
                        {
                            "status": "failed",
                            "engine": engine,
                            "result_path": str(result_path),
                            "evidence": evidence,
                            "error": completion_error,
                            "completed_at": utc_now(),
                        }
                    )
                    self._save()
                    return state
                state.update(
                    {
                        "status": "completed",
                        "engine": engine,
                        "result_path": str(result_path),
                        "evidence": evidence,
                        "completed_at": utc_now(),
                    }
                )
                self._save()
                return state
            if (
                engine == "xmage"
                and response.status == 422
                and response.body.get("error") == "xmage_coverage_incomplete"
            ):
                engine = "forge"
                attempt["next_engine"] = "forge"
                self._save()
                continue
            if response.status == 504:
                attempt["status"] = "timeout"
                if engine == "xmage":
                    if response.body.get("restart_required") is not True:
                        state["status"] = "timeout"
                        state["error"] = "xmage_timeout_restart_not_declared"
                        self._save()
                        return state
                    previous = str(response.body.get("sidecar_process_id") or "")
                    recovered = bool(previous) and self._wait_for_xmage_recovery(previous)
                    attempt["recovery_observed"] = recovered
                    if not recovered:
                        state["status"] = "timeout"
                        state["error"] = "xmage_recovery_not_observed"
                        self._save()
                        return state
                self._save()
                continue
            if response.status == 422:
                state["status"] = "coverage_incomplete"
                state["unsupported_cards"] = response.body.get("unsupported_cards") or []
            else:
                state["status"] = "failed"
            state["error"] = response.body.get("message") or response.body.get("error")
            self._save()
            return state

        state["status"] = "timeout" if any(
            attempt.get("http_status") == 504 for attempt in state["attempts"]
        ) else "failed"
        state["error"] = "maximum_attempts_exhausted"
        self._save()
        return state

    def run(self, *, max_jobs: int = 0) -> dict[str, Any]:
        processed = 0
        for job in self.registry.get("jobs") or []:
            if not isinstance(job, Mapping):
                continue
            job_id = str(job.get("job_id") or "")
            current = self.checkpoint["jobs"].get(job_id, {})
            if current.get("status") in TERMINAL_JOB_STATUSES:
                continue
            if max_jobs and processed >= max_jobs:
                break
            self._run_job(job)
            processed += 1
        self._save()
        return self.checkpoint


def load_registry(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("registry must be a JSON object")
    return payload


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--result-dir", type=Path, required=True)
    parser.add_argument("--xmage-url", required=True)
    parser.add_argument("--forge-url", required=True)
    parser.add_argument("--request-timeout-seconds", type=float, default=130.0)
    parser.add_argument("--recovery-timeout-seconds", type=float, default=180.0)
    parser.add_argument("--max-attempts", type=int, default=3)
    parser.add_argument("--max-jobs", type=int, default=0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    runner = BattleQueueRunner(
        registry=load_registry(args.registry),
        checkpoint_path=args.checkpoint,
        result_dir=args.result_dir,
        xmage_url=args.xmage_url,
        forge_url=args.forge_url,
        request_timeout=args.request_timeout_seconds,
        recovery_timeout=args.recovery_timeout_seconds,
        max_attempts=args.max_attempts,
    )
    checkpoint = runner.run(max_jobs=max(0, args.max_jobs))
    print(
        json.dumps(
            {
                "status": checkpoint["status"],
                "checkpoint": str(args.checkpoint),
                "job_status_counts": dict(
                    sorted(
                        Counter(
                            state.get("status")
                            for state in checkpoint.get("jobs", {}).values()
                        ).items()
                    )
                ),
                "comparison_gates": checkpoint.get("comparison_gates") or {},
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
