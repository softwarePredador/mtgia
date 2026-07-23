#!/usr/bin/env python3
"""Run resumable XMage/Forge battle queues with positive-evidence gates.

The runner is intended for controlled offline learning batches. It never falls
back after an operational engine failure, never treats a timeout as a draw,
and never promotes a deck. Completed comparisons become inputs for a separate
statistical/strategy decision only after both variants have natural exposure.
"""

from __future__ import annotations

import argparse
import base64
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


REGISTRY_SCHEMA = "external_battle_async_registry_v2"
CHECKPOINT_SCHEMA = "external_battle_async_checkpoint_v2"
LEARNING_SCHEMA = "external_battle_learning_v1"
EXECUTION_SCHEMA = "external_battle_execution_v2"
REQUEST_SCHEMA = "external_battle_request_v2"
SIDECAR_PROTOCOL = "external_battle_sidecar_v2"
COMPARISON_GATE_SCHEMA = "external_battle_comparison_gate_v1"
COMPARISON_CONTRACT_SCHEMA = "external_battle_comparison_contract_v1"
COMPARISON_OUTCOME_SCHEMA = "external_battle_comparison_outcome_v1"
SAME_LANE_HYPOTHESIS_SCHEMA = "battle_same_lane_hypothesis_v1"
LEGALITY_ATTESTATION_SCHEMA = "postgresql_commander_legality_attestation_v1"
FOCUSED_TEST_EVIDENCE_SCHEMA = "focused_card_rule_test_evidence_v1"
DECK_HASH_SCHEMA = "external_battle_deck_hash_v1"
ENGINE_IDENTITIES = {
    "xmage": {
        "engine_version": "1.4.60",
        "engine_commit": "34d81ea4995ce15d7e1a788dc6d2a3595d35bcec",
        "ai_profile": "computer_mad",
        "sidecar_build_identity": "xmage-sidecar-v2@34d81ea4995ce15d7e1a788dc6d2a3595d35bcec",
        "telemetry_field": "normalizer_version",
        "telemetry_version": "xmage_replay_normalizer_v2",
        "seed_semantics": "request_correlation_only_server_rng_uncontrolled",
        "deterministic": False,
    },
    "forge": {
        "engine_version": "2.0.14-SNAPSHOT",
        "engine_commit": "a62915f500c2411484689294659c6bb84ea215f8",
        "ai_profile": "forge_default_ai",
        "sidecar_build_identity": "forge-sidecar-v2@a62915f500c2411484689294659c6bb84ea215f8",
        "telemetry_field": "parser_version",
        "telemetry_version": "forge_log_parser_v2",
        "seed_semantics": "engine_rng_seeded_not_replay_guarantee",
        "deterministic": False,
    },
}
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
    "discard",
    "draw",
    "enter",
    "exile",
    "leave",
    "permanent",
    "play",
    "resolve",
    "sacrifice",
    "spell",
    "stack",
    "tap",
    "token",
    "trigger",
    "zone",
)
NON_EXECUTION_EVENT_TOKENS = (
    "hand_count",
    "library_count",
    "life_change",
    "log",
    "message",
    "snapshot",
    "text",
    "visible",
    "waiting",
)
TYPED_EVENT_FIELDS = ("event_type", "action")
SOURCE_NAME_FIELDS = (
    "source_card_name",
    "card_name",
    "object_name",
    "permanent_name",
    "attacker_name",
    "blocker_name",
    "card",
    "source",
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


def _typed_event_type(event: Mapping[str, Any]) -> str | None:
    """Return an engine-authored event type, never a parsed log label."""

    for field in TYPED_EVENT_FIELDS:
        value = normalize_name(event.get(field)).replace(" ", "_")
        if value:
            return value
    return None


def _is_typed_positive_action(event_type: str | None) -> bool:
    if not event_type:
        return False
    if any(token in event_type for token in NON_EXECUTION_EVENT_TOKENS):
        return False
    return any(token in event_type for token in POSITIVE_ACTION_TOKENS)


def _card_name_value(value: Any) -> str:
    if isinstance(value, Mapping):
        value = value.get("name")
    return str(value or "").strip()


def _focused_test_evidence(
    payload: Mapping[str, Any] | None,
    *,
    focus_cards: Sequence[str],
) -> dict[str, Any]:
    row = payload if isinstance(payload, Mapping) else {}
    tested_cards = {
        normalize_name(name)
        for name in row.get("card_names") or []
        if str(name).strip()
    }
    focus = {normalize_name(name) for name in focus_cards if str(name).strip()}
    valid = (
        row.get("schema_version") == FOCUSED_TEST_EVIDENCE_SCHEMA
        and row.get("positive_test_passed") is True
        and row.get("negative_test_passed") is True
        and bool(str(row.get("test_id") or "").strip())
        and bool(str(row.get("source_revision") or "").strip())
        and bool(focus)
        and focus <= tested_cards
    )
    return {
        "schema_version": FOCUSED_TEST_EVIDENCE_SCHEMA,
        "valid": valid,
        "tested_cards_normalized": sorted(tested_cards),
        "positive_test_passed": row.get("positive_test_passed") is True,
        "negative_test_passed": row.get("negative_test_passed") is True,
        "test_id": row.get("test_id"),
        "source_revision": row.get("source_revision"),
    }


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
    expected_seed: int | None = None,
    expected_deck_hashes: Mapping[str, Any] | None = None,
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
    if expected_seed is not None and result.get("seed") != expected_seed:
        return "engine_result_seed_mismatch"
    if expected_deck_hashes is not None and not deck_hashes_match(
        result.get("deck_hashes"),
        expected_deck_hashes,
    ):
        return "engine_result_deck_hashes_mismatch"
    return None


def comparison_outcome(
    result: Mapping[str, Any],
    request: Mapping[str, Any],
    *,
    subject_deck_key: str,
) -> dict[str, Any]:
    """Return a fail-closed, request-correlated comparison outcome.

    XMage and Forge do not expose controllable RNG seeds.  This normalized
    outcome is therefore an independent sample; the seed remains request and
    schedule correlation only.
    """

    errors: list[str] = []
    if subject_deck_key not in {"deck_a", "deck_b"}:
        errors.append("subject_deck_key_invalid")
        subject_deck_key = "deck_a"
    opponent_deck_key = "deck_b" if subject_deck_key == "deck_a" else "deck_a"
    status = normalize_name(result.get("status"))
    winner_key = result.get("winner_deck_key")
    winner_id = result.get("winner_deck_id")
    winner_label = result.get("winner")

    if winner_key is not None and winner_key not in {"deck_a", "deck_b"}:
        errors.append("winner_deck_key_invalid")
    if status == "censored":
        if winner_key is not None or winner_id is not None or winner_label is not None:
            errors.append("censored_result_exposes_winner")
        classification = "censored"
    elif status != "completed":
        classification = "invalid"
        errors.append("comparison_result_not_completed_or_censored")
    elif winner_key is None:
        if winner_id is not None or winner_label is not None:
            errors.append("draw_result_exposes_partial_winner")
        classification = "draw"
    else:
        winner_deck = request.get(winner_key)
        if not isinstance(winner_deck, Mapping):
            errors.append("winner_deck_missing_from_request")
        else:
            expected_winner_id = str(winner_deck.get("id") or "").strip()
            if not expected_winner_id or str(winner_id or "").strip() != expected_winner_id:
                errors.append("winner_deck_id_mismatch")
        classification = "win" if winner_key == subject_deck_key else "loss"

    if errors:
        classification = "invalid"
    return {
        "schema_version": COMPARISON_OUTCOME_SCHEMA,
        "valid": not errors,
        "classification": classification,
        "subject_deck_key": subject_deck_key,
        "opponent_deck_key": opponent_deck_key,
        "winner_deck_key": winner_key,
        "seed": result.get("seed"),
        "seed_pairing_claim": False,
        "sample_design": "engine_semantics_aware_independent_sample",
        "errors": errors,
    }


def _completed(result: Mapping[str, Any], *, expected_engine: str | None = None) -> bool:
    return completed_result_error(result, expected_engine=expected_engine) is None


def _result_identity(result: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": str(result.get("schema_version") or "").strip(),
        "engine": str(result.get("engine") or "").strip(),
        "engine_commit": str(result.get("engine_commit") or "").strip(),
        "engine_version": str(result.get("engine_version") or "").strip(),
        "sidecar_protocol_version": str(
            result.get("sidecar_protocol_version") or ""
        ).strip(),
        "sidecar_build_identity": str(
            result.get("sidecar_build_identity") or ""
        ).strip(),
        "ai_profile": str(result.get("ai_profile") or "").strip(),
        "normalizer_version": str(
            result.get("normalizer_version") or ""
        ).strip(),
        "parser_version": str(result.get("parser_version") or "").strip(),
        "seed": result.get("seed"),
        "seed_semantics": str(result.get("seed_semantics") or "").strip(),
        "deterministic": result.get("deterministic"),
        "request_id": str(result.get("request_id") or "").strip(),
        "request_hash": str(result.get("request_hash") or "").strip(),
        "timeout_ms": result.get("timeout_ms"),
        "sidecar_process_id": str(result.get("sidecar_process_id") or "").strip(),
        "sidecar_started_at": str(result.get("sidecar_started_at") or "").strip(),
    }


def _natural_sample_from_runtime(
    job: Mapping[str, Any],
    result: Mapping[str, Any],
) -> bool:
    request = job.get("request") if isinstance(job.get("request"), Mapping) else {}
    contract = _learning_contract(result)
    forced_mode = normalize_name(
        result.get("forced_access_mode")
        or request.get("force_focus_access_mode")
        or request.get("forced_access_mode")
    )
    return not (
        job.get("forced_access") is True
        or job.get("natural_sample") is False
        or request.get("natural_sample") is False
        or contract.get("forced_access_diagnostic") is True
        or (forced_mode and forced_mode != "none")
    )


def extract_positive_evidence(
    result: Mapping[str, Any],
    *,
    focus_cards: Sequence[str] = (),
    expected_engine: str | None = None,
    same_lane: bool = False,
    natural_sample: bool = True,
    focused_test_evidence: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    contract = _learning_contract(result)
    contract_valid = (
        contract.get("schema_version") == LEARNING_SCHEMA
        and contract.get("absence_proves_nonuse") is False
    )
    exposed: defaultdict[str, set[str]] = defaultdict(set)
    display_names: dict[str, str] = {}
    event_counts: defaultdict[str, int] = defaultdict(int)
    ignored_event_counts: defaultdict[str, int] = defaultdict(int)
    typed_positive_event_count = 0
    for event in _events(result):
        event_type = _typed_event_type(event)
        if not _is_typed_positive_action(event_type):
            ignored_event_counts[_event_type(event)] += 1
            continue
        assert event_type is not None
        event_counts[event_type] += 1
        event_has_named_source = False
        for field in SOURCE_NAME_FIELDS:
            raw_name = _card_name_value(event.get(field))
            if raw_name:
                normalized = normalize_name(raw_name)
                exposed[normalized].add(event_type)
                display_names.setdefault(normalized, raw_name)
                event_has_named_source = True
        if event_has_named_source:
            typed_positive_event_count += 1
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
                "exposure_state": "positive" if types else "unknown",
                "evidence_kind": "typed_event" if types else None,
                "event_types": types,
            }
        )
    completed = _completed(result, expected_engine=expected_engine)
    all_focus_exposed = bool(focus_rows) and all(row["positive_exposure"] for row in focus_rows)
    requested_exposure_ready = all_focus_exposed if focus_rows else bool(exposed)
    positive_exposure_ready = completed and contract_valid and requested_exposure_ready
    natural_same_lane_exposure = positive_exposure_ready and same_lane and natural_sample
    focused_tests = _focused_test_evidence(
        focused_test_evidence,
        focus_cards=focus,
    )
    rule_execution_input_ready = positive_exposure_ready or focused_tests["valid"]
    return {
        "schema_version": "battle_positive_evidence_v1",
        "completed": completed,
        "learning_contract_valid": contract_valid,
        "learning_contract_schema": contract.get("schema_version"),
        "absence_proves_nonuse": False,
        "event_stream_is_lower_bound": True,
        "positive_evidence_basis": "typed_event",
        "typed_positive_event_count": typed_positive_event_count,
        "event_counts": dict(sorted(event_counts.items())),
        "ignored_untyped_or_nonexecution_event_counts": dict(
            sorted(ignored_event_counts.items())
        ),
        "exposed_card_names": sorted(display_names.values(), key=normalize_name),
        "exposed_card_names_normalized": sorted(exposed),
        "focus_cards": focus_rows,
        "unknown_focus_card_count": sum(
            1 for row in focus_rows if row["exposure_state"] == "unknown"
        ),
        "all_focus_cards_exposed": all_focus_exposed,
        "positive_exposure_ready": positive_exposure_ready,
        "focused_test_evidence": focused_tests,
        "rule_execution_input_ready": rule_execution_input_ready,
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


def _trimmed_hash_field(value: Any) -> str:
    return str(value or "").strip()


def _base64_hash_field(value: Any) -> str:
    return base64.urlsafe_b64encode(
        _trimmed_hash_field(value).encode("utf-8")
    ).decode("ascii").rstrip("=")


def canonical_deck_facts(deck: Any, *, deck_key: str) -> dict[str, Any]:
    errors: list[str] = []
    if not isinstance(deck, Mapping):
        return {
            "deck_key": deck_key,
            "deck_id": "",
            "deck_hash": "",
            "card_count": 0,
            "commander_count": 0,
            "commander_identity": "",
            "card_quantities": {},
            "valid_shape": False,
            "errors": ["deck_not_object"],
        }
    raw_cards = deck.get("cards")
    if not isinstance(raw_cards, list) or not raw_cards:
        raw_cards = []
        errors.append("cards_missing")
    hash_records: list[str] = []
    card_quantities: Counter[str] = Counter()
    commander_names: list[str] = []
    card_count = 0
    commander_count = 0
    for index, row in enumerate(raw_cards):
        if not isinstance(row, Mapping):
            errors.append(f"card_{index}_not_object")
            continue
        original_name = _trimmed_hash_field(row.get("name"))
        name = normalize_name(original_name)
        quantity = row.get("quantity", 1)
        if not name:
            errors.append(f"card_{index}_name_missing")
            continue
        if not isinstance(quantity, int) or isinstance(quantity, bool) or quantity < 1:
            errors.append(f"card_{index}_quantity_invalid")
            continue
        is_commander = row.get("is_commander") is True
        hash_records.append(
            "|".join(
                (
                    "1" if is_commander else "0",
                    str(quantity),
                    _base64_hash_field(original_name),
                    _base64_hash_field(row.get("set_code")),
                    _base64_hash_field(row.get("collector_number")),
                )
            )
        )
        card_quantities[name] += quantity
        card_count += quantity
        if is_commander:
            commander_count += quantity
            commander_names.extend([name] * quantity)
    if card_count != 100:
        errors.append("cardinality_not_100")
    if commander_count != 1:
        errors.append("commander_count_not_1")
    material = f"{DECK_HASH_SCHEMA}\n" + "\n".join(sorted(hash_records)) + "\n"
    deck_hash = hashlib.sha256(material.encode("utf-8")).hexdigest()
    return {
        "deck_key": deck_key,
        "deck_id": str(deck.get("id") or "").strip(),
        "deck_hash": deck_hash,
        "card_count": card_count,
        "commander_count": commander_count,
        "commander_identity": commander_names[0] if len(commander_names) == 1 else "",
        "card_quantities": dict(sorted(card_quantities.items())),
        "valid_shape": not errors,
        "errors": errors,
    }


def canonical_deck_hash(deck: Any, *, deck_key: str = "deck") -> str:
    return str(canonical_deck_facts(deck, deck_key=deck_key)["deck_hash"])


def canonical_request_deck_hashes(request: Mapping[str, Any]) -> dict[str, str]:
    return {
        "schema_version": DECK_HASH_SCHEMA,
        "algorithm": "sha256",
        "deck_a": canonical_deck_hash(request.get("deck_a"), deck_key="deck_a"),
        "deck_b": canonical_deck_hash(request.get("deck_b"), deck_key="deck_b"),
    }


def deck_hashes_match(actual: Any, expected: Mapping[str, Any]) -> bool:
    return isinstance(actual, Mapping) and all(
        actual.get(key) == expected.get(key)
        for key in ("schema_version", "algorithm", "deck_a", "deck_b")
    )


def canonical_external_request_hash(request: Mapping[str, Any]) -> str:
    identity = ENGINE_IDENTITIES[str(request.get("expected_engine") or "")]
    deck_hashes = request["deck_hashes"]
    deck_a = request["deck_a"]
    deck_b = request["deck_b"]
    focus_cards = request.get("focus_cards") or []
    material = "\n".join(
        (
            REQUEST_SCHEMA,
            f"request_id={_base64_hash_field(request.get('request_id'))}",
            f"seed={request['seed']}",
            f"timeout_ms={request['timeout_ms']}",
            f"max_turns={request['max_turns']}",
            "focus_cards=" + ",".join(_base64_hash_field(card) for card in focus_cards),
            f"force_focus_access_mode={request['force_focus_access_mode']}",
            f"same_lane={1 if request['same_lane'] else 0}",
            f"natural_sample={1 if request['natural_sample'] else 0}",
            f"deck_a_id={_base64_hash_field(deck_a.get('id') or 'deck_a')}",
            f"deck_b_id={_base64_hash_field(deck_b.get('id') or 'deck_b')}",
            f"deck_a_hash={deck_hashes['deck_a']}",
            f"deck_b_hash={deck_hashes['deck_b']}",
            f"engine={request['expected_engine']}",
            f"engine_version={_base64_hash_field(identity['engine_version'])}",
            f"engine_commit={identity['engine_commit']}",
            f"ai_profile={_base64_hash_field(identity['ai_profile'])}",
        )
    )
    return hashlib.sha256(f"{material}\n".encode("utf-8")).hexdigest()


def strict_engine_request(
    request: Mapping[str, Any],
    *,
    job: Mapping[str, Any],
    engine: str,
    same_lane: bool,
) -> dict[str, Any]:
    identity = ENGINE_IDENTITIES[engine]
    force_mode = normalize_name(request.get("force_focus_access_mode") or "none")
    if force_mode != "none":
        raise ValueError("external battle engines do not support forced card access")
    focus_cards = [
        str(card).strip()
        for card in (request.get("focus_cards") or job.get("focus_cards") or [])
        if str(card).strip()
    ]
    envelope = {
        **request,
        "request_schema_version": REQUEST_SCHEMA,
        "expected_engine": engine,
        "expected_engine_version": identity["engine_version"],
        "expected_engine_commit": identity["engine_commit"],
        "ai_profile": identity["ai_profile"],
        "focus_cards": focus_cards,
        "force_focus_access_mode": force_mode,
        "same_lane": same_lane,
        "natural_sample": (
            request.get("natural_sample") is not False
            and job.get("natural_sample") is not False
            and job.get("forced_access") is not True
        ),
        "deck_hashes": canonical_request_deck_hashes(request),
    }
    envelope["request_hash"] = canonical_external_request_hash(envelope)
    return envelope


def _valid_timestamp(value: Any) -> bool:
    if not isinstance(value, str) or not value.strip():
        return False
    try:
        datetime.fromisoformat(value.strip().replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


def external_execution_identity_error(
    body: Mapping[str, Any],
    *,
    engine: str,
) -> str | None:
    identity = ENGINE_IDENTITIES[engine]
    expected = {
        "schema_version": EXECUTION_SCHEMA,
        "engine": engine,
        "engine_version": identity["engine_version"],
        "engine_commit": identity["engine_commit"],
        "sidecar_protocol_version": SIDECAR_PROTOCOL,
        "sidecar_build_identity": identity["sidecar_build_identity"],
        "ai_profile": identity["ai_profile"],
        identity["telemetry_field"]: identity["telemetry_version"],
        "seed_semantics": identity["seed_semantics"],
        "deterministic": identity["deterministic"],
    }
    for field, value in expected.items():
        if body.get(field) != value:
            return f"engine_identity_mismatch:{field}"
    if not str(body.get("sidecar_process_id") or "").strip():
        return "engine_identity_missing:sidecar_process_id"
    if not _valid_timestamp(body.get("sidecar_started_at")):
        return "engine_identity_invalid:sidecar_started_at"
    return None


def external_execution_correlation_error(
    body: Mapping[str, Any],
    request: Mapping[str, Any],
) -> str | None:
    for field in ("request_id", "seed", "timeout_ms", "request_hash", "ai_profile"):
        if body.get(field) != request.get(field):
            return f"engine_correlation_mismatch:{field}"
    if not deck_hashes_match(body.get("deck_hashes"), request["deck_hashes"]):
        return "engine_correlation_mismatch:deck_hashes"
    contract = body.get("request_contract")
    if not isinstance(contract, Mapping) or contract.get("schema_version") != REQUEST_SCHEMA:
        return "engine_correlation_mismatch:request_contract"
    controls = contract.get("controls")
    if not isinstance(controls, Mapping):
        return "engine_correlation_mismatch:controls"
    for field in (
        "max_turns",
        "focus_cards",
        "force_focus_access_mode",
        "same_lane",
        "natural_sample",
    ):
        declaration = controls.get(field)
        if not isinstance(declaration, Mapping) or declaration.get("value") != request.get(field):
            return f"engine_correlation_mismatch:control:{field}"
    return None


def external_execution_contract_error(
    body: Mapping[str, Any],
    request: Mapping[str, Any],
    *,
    engine: str,
) -> str | None:
    return external_execution_identity_error(body, engine=engine) or external_execution_correlation_error(
        body,
        request,
    )


def _comparison_contract_index(registry: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    rows = registry.get("comparisons")
    if rows is None:
        return {}
    if not isinstance(rows, list):
        raise ValueError("registry comparisons must be a list")
    result: dict[str, Mapping[str, Any]] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            raise ValueError("registry comparisons must contain objects")
        comparison_id = str(row.get("comparison_id") or "").strip()
        if not comparison_id or comparison_id in result:
            raise ValueError(
                f"comparison_id must be present and unique: {comparison_id!r}"
            )
        result[comparison_id] = row
    return result


def _name_counter(values: Any) -> Counter[str]:
    if not isinstance(values, list):
        return Counter()
    return Counter(
        normalize_name(value)
        for value in values
        if isinstance(value, str) and value.strip()
    )


def _expanded_counter(counter: Counter[str]) -> list[str]:
    return sorted(name for name, quantity in counter.items() for _ in range(quantity))


def _legality_attestation_blockers(
    contract: Mapping[str, Any],
    *,
    required_facts: Sequence[Mapping[str, Any]],
) -> list[str]:
    attestation = contract.get("legality_attestation")
    if not isinstance(attestation, Mapping):
        return ["canonical_legality_attestation_missing"]
    blockers: list[str] = []
    if attestation.get("schema_version") != LEGALITY_ATTESTATION_SCHEMA:
        blockers.append("canonical_legality_schema_mismatch")
    if attestation.get("source") != "postgresql_deck_rules_service":
        blockers.append("canonical_legality_source_mismatch")
    if not str(attestation.get("validation_id") or "").strip():
        blockers.append("canonical_legality_validation_id_missing")
    rows = attestation.get("decks")
    if not isinstance(rows, list):
        rows = []
        blockers.append("canonical_legality_decks_missing")
    by_hash = {
        str(row.get("deck_hash") or ""): row
        for row in rows
        if isinstance(row, Mapping) and str(row.get("deck_hash") or "")
    }
    for facts in required_facts:
        deck_hash = str(facts.get("deck_hash") or "")
        row = by_hash.get(deck_hash)
        if row is None:
            blockers.append(f"canonical_legality_hash_missing:{deck_hash}")
            continue
        if row.get("status") != "legal":
            blockers.append(f"canonical_legality_not_legal:{deck_hash}")
        if row.get("card_count") != facts.get("card_count"):
            blockers.append(f"canonical_legality_cardinality_mismatch:{deck_hash}")
        if row.get("commander_count") != facts.get("commander_count"):
            blockers.append(f"canonical_legality_commander_count_mismatch:{deck_hash}")
    return blockers


def comparison_preflight(
    registry: Mapping[str, Any],
    comparison_id: str,
) -> dict[str, Any]:
    contracts = _comparison_contract_index(registry)
    contract = contracts.get(comparison_id)
    blockers: list[str] = []
    if contract is None:
        return {
            "comparison_id": comparison_id,
            "valid": False,
            "blockers": ["canonical_comparison_contract_missing"],
            "same_lane_hypothesis_verified": False,
            "postgresql_legality_attestation_valid": False,
            "seed_set": [],
        }
    if contract.get("schema_version") != COMPARISON_CONTRACT_SCHEMA:
        blockers.append("canonical_comparison_contract_schema_mismatch")

    jobs = [
        job
        for job in registry.get("jobs") or []
        if isinstance(job, Mapping)
        and str(job.get("comparison_id") or "").strip() == comparison_id
    ]
    variants: defaultdict[str, list[Mapping[str, Any]]] = defaultdict(list)
    for job in jobs:
        variants[str(job.get("variant") or "unknown")].append(job)
    base = variants.get("base", [])
    candidate = variants.get("candidate", [])
    if not base:
        blockers.append("base_variant_missing")
    if not candidate:
        blockers.append("candidate_variant_missing")

    raw_seed_set = contract.get("seed_set")
    seed_set = (
        list(raw_seed_set)
        if isinstance(raw_seed_set, list)
        and raw_seed_set
        and all(isinstance(seed, int) and not isinstance(seed, bool) for seed in raw_seed_set)
        and len(set(raw_seed_set)) == len(raw_seed_set)
        else []
    )
    if not seed_set:
        blockers.append("canonical_seed_set_invalid")
    expected_seeds = set(seed_set)
    for variant, rows in (("base", base), ("candidate", candidate)):
        actual_seeds = {
            job.get("request", {}).get("seed")
            for job in rows
            if isinstance(job.get("request"), Mapping)
        }
        if actual_seeds != expected_seeds:
            blockers.append(f"{variant}_seed_set_mismatch")

    subject_key = str(contract.get("subject_deck_key") or "deck_a")
    if subject_key not in {"deck_a", "deck_b"}:
        blockers.append("subject_deck_key_invalid")
        subject_key = "deck_a"
    opponent_key = "deck_b" if subject_key == "deck_a" else "deck_a"
    facts_by_variant: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
    opponent_facts: list[dict[str, Any]] = []
    for variant, rows in (("base", base), ("candidate", candidate)):
        for job in rows:
            request = job.get("request") if isinstance(job.get("request"), Mapping) else {}
            subject = canonical_deck_facts(request.get(subject_key), deck_key=subject_key)
            opponent = canonical_deck_facts(request.get(opponent_key), deck_key=opponent_key)
            if not deck_hashes_match(
                request.get("deck_hashes"),
                canonical_request_deck_hashes(request),
            ):
                blockers.append(f"{job.get('job_id')}:registry_deck_hashes_mismatch")
            facts_by_variant[variant].append(subject)
            opponent_facts.append(opponent)
            if not subject["valid_shape"]:
                blockers.append(f"{job.get('job_id')}:subject_deck_shape_invalid")
            if not opponent["valid_shape"]:
                blockers.append(f"{job.get('job_id')}:opponent_deck_shape_invalid")

    def unique_value(rows: Sequence[Mapping[str, Any]], field: str) -> str:
        values = {str(row.get(field) or "") for row in rows}
        return values.pop() if len(values) == 1 else ""

    base_hash = unique_value(facts_by_variant["base"], "deck_hash")
    candidate_hash = unique_value(facts_by_variant["candidate"], "deck_hash")
    opponent_hash = unique_value(opponent_facts, "deck_hash")
    if not base_hash:
        blockers.append("base_deck_hash_not_stable")
    if not candidate_hash:
        blockers.append("candidate_deck_hash_not_stable")
    if not opponent_hash:
        blockers.append("opponent_deck_hash_not_stable")
    if base_hash and base_hash == candidate_hash:
        blockers.append("base_candidate_deck_hashes_equal")
    for field, actual in (
        ("base_deck_hash", base_hash),
        ("candidate_deck_hash", candidate_hash),
        ("opponent_deck_hash", opponent_hash),
    ):
        if str(contract.get(field) or "") != actual:
            blockers.append(f"{field}_mismatch")

    base_commander = unique_value(facts_by_variant["base"], "commander_identity")
    candidate_commander = unique_value(
        facts_by_variant["candidate"], "commander_identity"
    )
    opponent_commander = unique_value(opponent_facts, "commander_identity")
    if not base_commander or base_commander != candidate_commander:
        blockers.append("subject_commander_identity_mismatch")
    if normalize_name(contract.get("commander_identity")) != base_commander:
        blockers.append("canonical_commander_identity_mismatch")
    if normalize_name(contract.get("opponent_commander_identity")) != opponent_commander:
        blockers.append("canonical_opponent_identity_mismatch")
    opponent_ids = {str(row.get("deck_id") or "") for row in opponent_facts}
    if len(opponent_ids) != 1 or "" in opponent_ids:
        blockers.append("opponent_deck_id_mismatch")
    elif str(contract.get("opponent_deck_id") or "") not in opponent_ids:
        blockers.append("canonical_opponent_deck_id_mismatch")

    timeout_policy = contract.get("timeout_policy")
    timeout_ms = (
        timeout_policy.get("timeout_ms")
        if isinstance(timeout_policy, Mapping)
        else None
    )
    if (
        not isinstance(timeout_ms, int)
        or isinstance(timeout_ms, bool)
        or timeout_ms <= 0
        or not isinstance(timeout_policy, Mapping)
        or timeout_policy.get("censoring") != "exclude_any_timeout_attempt"
    ):
        blockers.append("canonical_timeout_policy_invalid")
    elif any(
        not isinstance(job.get("request"), Mapping)
        or job["request"].get("timeout_ms") != timeout_ms
        for job in jobs
    ):
        blockers.append("timeout_policy_mismatch")

    hypothesis = contract.get("same_lane_hypothesis")
    hypothesis_blockers: list[str] = []
    if not isinstance(hypothesis, Mapping):
        hypothesis = {}
        hypothesis_blockers.append("same_lane_hypothesis_missing")
    if hypothesis.get("schema_version") != SAME_LANE_HYPOTHESIS_SCHEMA:
        hypothesis_blockers.append("same_lane_hypothesis_schema_mismatch")
    if hypothesis.get("status") != "reviewed":
        hypothesis_blockers.append("same_lane_hypothesis_not_reviewed")
    removed_lane = str(hypothesis.get("removed_lane_key") or "").strip()
    added_lane = str(hypothesis.get("added_lane_key") or "").strip()
    if not removed_lane or removed_lane != added_lane:
        hypothesis_blockers.append("same_lane_keys_mismatch")
    if not str(hypothesis.get("owner") or "").strip():
        hypothesis_blockers.append("same_lane_owner_missing")
    if not [ref for ref in hypothesis.get("evidence_refs") or [] if str(ref).strip()]:
        hypothesis_blockers.append("same_lane_evidence_refs_missing")

    actual_removed: Counter[str] = Counter()
    actual_added: Counter[str] = Counter()
    if facts_by_variant["base"] and facts_by_variant["candidate"]:
        base_cards = Counter(facts_by_variant["base"][0]["card_quantities"])
        candidate_cards = Counter(facts_by_variant["candidate"][0]["card_quantities"])
        actual_removed = base_cards - candidate_cards
        actual_added = candidate_cards - base_cards
    declared_removed = _name_counter(hypothesis.get("removed_cards"))
    declared_added = _name_counter(hypothesis.get("added_cards"))
    if not declared_removed or actual_removed != declared_removed:
        hypothesis_blockers.append("same_lane_removed_cards_mismatch")
    if not declared_added or actual_added != declared_added:
        hypothesis_blockers.append("same_lane_added_cards_mismatch")
    for variant, expected_focus in (
        ("base", declared_removed),
        ("candidate", declared_added),
    ):
        if any(_name_counter(job.get("focus_cards")) != expected_focus for job in variants[variant]):
            hypothesis_blockers.append(f"{variant}_focus_cards_mismatch")
    blockers.extend(hypothesis_blockers)

    required_facts: list[Mapping[str, Any]] = []
    for rows in (facts_by_variant["base"], facts_by_variant["candidate"], opponent_facts):
        for facts in rows:
            if facts.get("deck_hash") and not any(
                existing.get("deck_hash") == facts.get("deck_hash")
                for existing in required_facts
            ):
                required_facts.append(facts)
    legality_blockers = _legality_attestation_blockers(
        contract,
        required_facts=required_facts,
    )
    blockers.extend(legality_blockers)
    return {
        "comparison_id": comparison_id,
        "valid": not blockers,
        "blockers": sorted(set(blockers)),
        "seed_set": sorted(seed_set),
        "subject_deck_key": subject_key,
        "opponent_deck_key": opponent_key,
        "base_deck_hash": base_hash,
        "candidate_deck_hash": candidate_hash,
        "opponent_deck_hash": opponent_hash,
        "commander_identity": base_commander,
        "opponent_commander_identity": opponent_commander,
        "timeout_ms": timeout_ms,
        "actual_removed_cards": _expanded_counter(actual_removed),
        "actual_added_cards": _expanded_counter(actual_added),
        "same_lane_hypothesis_verified": not hypothesis_blockers,
        "postgresql_legality_attestation_valid": not legality_blockers,
    }


def validate_registry(registry: Mapping[str, Any]) -> None:
    if registry.get("schema_version") != REGISTRY_SCHEMA:
        raise ValueError(f"registry schema must be {REGISTRY_SCHEMA}")
    jobs = registry.get("jobs")
    if not isinstance(jobs, list) or not jobs:
        raise ValueError("registry jobs must be a non-empty list")
    minimum = registry.get("minimum_completed_per_variant", 3)
    if not isinstance(minimum, int) or isinstance(minimum, bool) or minimum < 1:
        raise ValueError("minimum_completed_per_variant must be a positive integer")
    comparison_contracts = _comparison_contract_index(registry)
    job_ids: set[str] = set()
    safe_job_ids: set[str] = set()
    comparison_samples: set[tuple[str, str, int]] = set()
    referenced_comparisons: set[str] = set()
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
        request_id = str(request.get("request_id") or "").strip()
        if re.fullmatch(r"[A-Za-z0-9_-]{1,80}", request_id) is None:
            raise ValueError(
                f"job {job_id!r} requires a safe 1-80 character request_id"
            )
        seed = request.get("seed")
        if not isinstance(seed, int) or isinstance(seed, bool):
            raise ValueError(f"job {job_id!r} requires an integer seed")
        timeout_ms = request.get("timeout_ms")
        if (
            not isinstance(timeout_ms, int)
            or isinstance(timeout_ms, bool)
            or not 1_000 <= timeout_ms <= 900_000
        ):
            raise ValueError(f"job {job_id!r} requires timeout_ms in 1000..900000")
        max_turns = request.get("max_turns")
        if (
            not isinstance(max_turns, int)
            or isinstance(max_turns, bool)
            or not 1 <= max_turns <= 100
        ):
            raise ValueError(f"job {job_id!r} requires max_turns in 1..100")
        if normalize_name(request.get("force_focus_access_mode") or "none") != "none":
            raise ValueError(
                f"job {job_id!r} cannot request forced access from external engines"
            )
        if not deck_hashes_match(
            request.get("deck_hashes"),
            canonical_request_deck_hashes(request),
        ):
            raise ValueError(
                f"job {job_id!r} deck_hashes do not match canonical request decks"
            )
        comparison_id = str(job.get("comparison_id") or "").strip()
        if not comparison_id:
            continue
        referenced_comparisons.add(comparison_id)
        if comparison_id not in comparison_contracts:
            raise ValueError(
                f"comparison job {job_id!r} has no canonical comparison contract"
            )
        variant = str(job.get("variant") or "").strip()
        if variant not in {"base", "candidate"}:
            raise ValueError(
                f"comparison job {job_id!r} requires variant base or candidate"
            )
        sample_key = (comparison_id, variant, seed)
        if sample_key in comparison_samples:
            raise ValueError(f"duplicate comparison sample: {sample_key!r}")
        comparison_samples.add(sample_key)
    unreferenced = sorted(set(comparison_contracts) - referenced_comparisons)
    if unreferenced:
        raise ValueError(f"unreferenced comparison contracts: {unreferenced!r}")
    for comparison_id in sorted(referenced_comparisons):
        preflight = comparison_preflight(registry, comparison_id)
        if len(preflight["seed_set"]) < minimum:
            raise ValueError(
                f"comparison {comparison_id!r} seed set is smaller than the minimum"
            )
        if not preflight["valid"]:
            raise ValueError(
                f"comparison {comparison_id!r} preflight failed: "
                + ", ".join(preflight["blockers"])
            )


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
        preflight = comparison_preflight(registry, comparison_id)
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
                and int(evidence.get("typed_positive_event_count") or 0) > 0
                and evidence.get("natural_sample") is True
                and entry[1].get("sample_classification") == "natural"
                and all(
                    isinstance(row, Mapping)
                    and row.get("positive_exposure") is True
                    and row.get("evidence_kind") == "typed_event"
                    for row in evidence.get("focus_cards") or []
                )
            )

        base_completed = completed(base)
        candidate_completed = completed(candidate)
        completed_entries = [*base_completed, *candidate_completed]
        outcomes_valid = bool(completed_entries) and all(
            isinstance(state.get("comparison_outcome"), Mapping)
            and state["comparison_outcome"].get("schema_version")
            == COMPARISON_OUTCOME_SCHEMA
            and state["comparison_outcome"].get("valid") is True
            and state["comparison_outcome"].get("classification")
            in {"win", "loss", "draw"}
            and state["comparison_outcome"].get("seed_pairing_claim") is False
            for _job, state in completed_entries
        )

        def outcome_counts(
            values: Sequence[tuple[Mapping[str, Any], Mapping[str, Any]]],
        ) -> dict[str, int]:
            counts = Counter(
                str(state.get("comparison_outcome", {}).get("classification") or "invalid")
                for _job, state in values
            )
            return {
                "win": counts["win"],
                "loss": counts["loss"],
                "draw": counts["draw"],
                "invalid": counts["invalid"],
            }

        base_outcomes = outcome_counts(base_completed)
        candidate_outcomes = outcome_counts(candidate_completed)
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
            and row.get("evidence_kind") == "typed_event"
        }
        candidate_exposed = {
            normalize_name(row.get("card_name"))
            for _job, state in candidate_completed
            for row in (state.get("evidence", {}).get("focus_cards") or [])
            if row.get("positive_exposure") is True
            and row.get("evidence_kind") == "typed_event"
        }
        removed = {normalize_name(name) for name in preflight["actual_removed_cards"]}
        added = {normalize_name(name) for name in preflight["actual_added_cards"]}
        same_lane = preflight["same_lane_hypothesis_verified"] is True
        natural = bool(entries) and all(
            state.get("sample_classification") == "natural"
            and isinstance(state.get("evidence"), Mapping)
            and state["evidence"].get("natural_sample") is True
            for _job, state in entries
            if state.get("status") == "completed"
        )
        forced_access_diagnostic = any(
            job.get("forced_access") is True
            or job.get("natural_sample") is False
            or state.get("sample_classification") == "forced_access_diagnostic"
            for job, state in entries
        )
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
            or any(
                attempt.get("http_status") == 504
                or attempt.get("status") == "timeout"
                for attempt in state.get("attempts") or []
                if isinstance(attempt, Mapping)
            )
            for _job, state in entries
        )
        expected_seed_set = set(preflight["seed_set"])
        completed_seed_set_matches_contract = (
            bool(expected_seed_set)
            and base_seeds == expected_seed_set
            and candidate_seeds == expected_seed_set
        )
        result_identity_rows = [
            state.get("result_identity")
            for _job, state in [*base_completed, *candidate_completed]
        ]
        result_identity_complete = bool(result_identity_rows) and all(
            isinstance(identity, Mapping)
            and str(identity.get("engine") or "") in ENGINE_IDENTITIES
            and external_execution_identity_error(
                identity,
                engine=str(identity.get("engine")),
            )
            is None
            and bool(str(identity.get("request_id") or "").strip())
            and bool(str(identity.get("request_hash") or "").strip())
            for identity in result_identity_rows
        )
        engine_identities = {
            (
                str(identity.get("engine") or ""),
                str(identity.get("engine_commit") or ""),
                str(identity.get("engine_version") or ""),
                str(identity.get("sidecar_protocol_version") or ""),
                str(identity.get("sidecar_build_identity") or ""),
                str(identity.get("seed_semantics") or ""),
                identity.get("deterministic"),
            )
            for identity in result_identity_rows
            if isinstance(identity, Mapping)
        }
        same_engine_identity = result_identity_complete and len(engine_identities) == 1
        result_seed_match = all(
            isinstance(state.get("result_identity"), Mapping)
            and state["result_identity"].get("seed")
            == job.get("request", {}).get("seed")
            for job, state in [*base_completed, *candidate_completed]
        )
        result_deck_hashes_match = all(
            deck_hashes_match(
                state.get("result_deck_hashes"),
                job.get("request", {}).get("deck_hashes", {}),
            )
            for job, state in [*base_completed, *candidate_completed]
        )
        result_request_correlation_match = all(
            isinstance(state.get("result_identity"), Mapping)
            and isinstance(state.get("request_identity"), Mapping)
            and state["result_identity"].get("request_id")
            == state["request_identity"].get("request_id")
            and state["result_identity"].get("request_hash")
            == state["request_identity"].get("request_hash")
            and state["result_identity"].get("timeout_ms")
            == state["request_identity"].get("timeout_ms")
            and state["result_identity"].get("engine")
            == state["request_identity"].get("expected_engine")
            and state["result_identity"].get("engine_version")
            == state["request_identity"].get("expected_engine_version")
            and state["result_identity"].get("engine_commit")
            == state["request_identity"].get("expected_engine_commit")
            for _job, state in [*base_completed, *candidate_completed]
        )
        runtime_blockers: list[str] = []
        if not completed_enough:
            runtime_blockers.append("minimum_completed_samples_missing")
        if not completed_seed_set_matches_contract:
            runtime_blockers.append("completed_seed_set_mismatch")
        if not equal_seed_set:
            runtime_blockers.append("base_candidate_seed_set_mismatch")
        if not exposure_qualified_enough or not equal_exposure_seed_set or not focus_exposed:
            runtime_blockers.append("typed_focus_exposure_missing_or_unknown")
        if not natural or forced_access_diagnostic:
            runtime_blockers.append("forced_access_or_non_natural_sample")
        if timeout_censored:
            runtime_blockers.append("timeout_censored_sample")
        if not same_engine_identity:
            runtime_blockers.append("engine_identity_mismatch_or_incomplete")
        if not result_request_correlation_match:
            runtime_blockers.append("engine_request_correlation_mismatch")
        if not result_seed_match:
            runtime_blockers.append("engine_result_seed_mismatch")
        if not result_deck_hashes_match:
            runtime_blockers.append("engine_result_deck_hashes_mismatch")
        if not outcomes_valid:
            runtime_blockers.append("comparison_outcome_missing_or_invalid")
        blockers = sorted(set([*preflight["blockers"], *runtime_blockers]))
        ready = (
            not blockers
            and completed_enough
            and equal_seed_set
            and completed_seed_set_matches_contract
            and exposure_qualified_enough
            and equal_exposure_seed_set
            and focus_exposed
            and same_lane
            and natural
            and not forced_access_diagnostic
            and not timeout_censored
            and same_engine_identity
            and result_request_correlation_match
            and result_seed_match
            and result_deck_hashes_match
            and outcomes_valid
        )
        if ready:
            next_gate = "statistical_and_strategy_evaluation"
        elif timeout_censored:
            next_gate = "rerun_uncensored_same_policy_seed_set"
        elif forced_access_diagnostic or not natural:
            next_gate = "collect_natural_samples_without_forced_access"
        elif preflight["blockers"]:
            next_gate = "repair_canonical_comparison_contract"
        elif not exposure_qualified_enough or not focus_exposed:
            next_gate = "collect_typed_natural_focus_card_exposure"
        elif not result_deck_hashes_match:
            next_gate = "repair_engine_result_deck_correlation"
        else:
            next_gate = "repair_engine_identity_or_seed_mismatch"
        result[comparison_id] = {
            "schema_version": COMPARISON_GATE_SCHEMA,
            "status": "comparison_input_ready" if ready else "insufficient_evidence",
            "blockers": blockers,
            "minimum_completed_per_variant": minimum,
            "base_completed": len(base_completed),
            "candidate_completed": len(candidate_completed),
            "base_exposure_eligible": len(base_exposure_seeds),
            "candidate_exposure_eligible": len(candidate_exposure_seeds),
            "equal_seed_set": equal_seed_set,
            "seed_set_role": "balanced_schedule_correlation_only",
            "seed_pairing_claim": False,
            "statistical_design_required": "engine_semantics_aware_independent_samples",
            "completed_seed_set_matches_contract": completed_seed_set_matches_contract,
            "equal_exposure_seed_set": equal_exposure_seed_set,
            "exposure_qualified_enough": exposure_qualified_enough,
            "same_lane": same_lane,
            "same_lane_source": "canonical_reviewed_hypothesis",
            "natural_samples": natural,
            "forced_access_diagnostic": forced_access_diagnostic,
            "focus_cards_exposed": focus_exposed,
            "timeout_censored": timeout_censored,
            "postgresql_legality_attestation_valid": preflight[
                "postgresql_legality_attestation_valid"
            ],
            "base_deck_hash": preflight["base_deck_hash"],
            "candidate_deck_hash": preflight["candidate_deck_hash"],
            "opponent_deck_hash": preflight["opponent_deck_hash"],
            "commander_identity": preflight["commander_identity"],
            "opponent_commander_identity": preflight["opponent_commander_identity"],
            "timeout_ms": preflight["timeout_ms"],
            "same_engine_commit_and_version": same_engine_identity,
            "engine_identity_and_contract_complete": result_identity_complete,
            "engine_request_correlation_match": result_request_correlation_match,
            "engine_identity": (
                {
                    "engine": next(iter(engine_identities))[0],
                    "engine_commit": next(iter(engine_identities))[1],
                    "engine_version": next(iter(engine_identities))[2],
                    "sidecar_protocol_version": next(iter(engine_identities))[3],
                    "sidecar_build_identity": next(iter(engine_identities))[4],
                    "seed_semantics": next(iter(engine_identities))[5],
                    "deterministic": next(iter(engine_identities))[6],
                }
                if same_engine_identity
                else None
            ),
            "engine_result_seed_match": result_seed_match,
            "engine_result_deck_hashes_match": result_deck_hashes_match,
            "comparison_outcomes_valid": outcomes_valid,
            "base_outcomes": base_outcomes,
            "candidate_outcomes": candidate_outcomes,
            "comparison_input_ready": ready,
            "swap_superiority_proven": False,
            "promotion_allowed": False,
            "next_gate": next_gate,
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
                and external_execution_identity_error(
                    response.body,
                    engine="xmage",
                )
                is None
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

        comparison_id = str(job.get("comparison_id") or "").strip()
        comparison_contract = (
            comparison_preflight(self.registry, comparison_id)
            if comparison_id
            else {}
        )
        same_lane = comparison_contract.get("same_lane_hypothesis_verified") is True
        subject_deck_key = str(
            comparison_contract.get("subject_deck_key") or "deck_a"
        )
        engine = "xmage"
        first_attempt = len(attempts) + 1
        for attempt_number in range(first_attempt, self.max_attempts + 1):
            engine_request = strict_engine_request(
                request,
                job=job,
                engine=engine,
                same_lane=same_lane,
            )
            started = time.monotonic()
            try:
                response = self._attempt(engine, engine_request)
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
                "request_schema_version": REQUEST_SCHEMA,
                "request_id": engine_request["request_id"],
                "request_hash": engine_request["request_hash"],
                "expected_engine_commit": engine_request[
                    "expected_engine_commit"
                ],
            }
            state["attempts"].append(attempt)
            execution_contract_error = external_execution_contract_error(
                response.body,
                engine_request,
                engine=engine,
            )
            if execution_contract_error is not None:
                attempt["status"] = "invalid_execution_contract"
                attempt["error"] = execution_contract_error
                state.update(
                    {
                        "status": "failed",
                        "engine": engine,
                        "result_identity": _result_identity(response.body),
                        "request_identity": {
                            key: engine_request.get(key)
                            for key in (
                                "request_schema_version",
                                "request_id",
                                "request_hash",
                                "seed",
                                "timeout_ms",
                                "max_turns",
                                "expected_engine",
                                "expected_engine_version",
                                "expected_engine_commit",
                                "ai_profile",
                                "deck_hashes",
                            )
                        },
                        "error": execution_contract_error,
                        "completed_at": utc_now(),
                    }
                )
                self._save()
                return state
            if response.status == 200:
                result_path = self.result_dir / f"{_safe_job_id(job_id)}.json.gz"
                atomic_write_gzip_json(result_path, response.body)
                natural_sample = _natural_sample_from_runtime(job, response.body)
                evidence = extract_positive_evidence(
                    response.body,
                    focus_cards=[str(card) for card in job.get("focus_cards") or []],
                    expected_engine=engine,
                    same_lane=same_lane,
                    natural_sample=natural_sample,
                    focused_test_evidence=(
                        job.get("focused_test_evidence")
                        if isinstance(job.get("focused_test_evidence"), Mapping)
                        else None
                    ),
                )
                completion_error = completed_result_error(
                    response.body,
                    expected_engine=engine,
                    expected_seed=engine_request.get("seed"),
                    expected_deck_hashes=engine_request.get("deck_hashes"),
                )
                outcome = comparison_outcome(
                    response.body,
                    engine_request,
                    subject_deck_key=subject_deck_key,
                )
                if comparison_id and outcome["valid"] is not True:
                    completion_error = (
                        "comparison_outcome_invalid:"
                        + ",".join(str(value) for value in outcome["errors"])
                    )
                result_identity = _result_identity(response.body)
                result_deck_hashes = response.body.get("deck_hashes")
                request_identity = {
                    key: engine_request.get(key)
                    for key in (
                        "request_schema_version",
                        "request_id",
                        "request_hash",
                        "seed",
                        "timeout_ms",
                        "max_turns",
                        "expected_engine",
                        "expected_engine_version",
                        "expected_engine_commit",
                        "ai_profile",
                        "deck_hashes",
                    )
                }
                fallback_reason = (
                    "xmage_coverage_incomplete" if engine == "forge" else "none"
                )
                engine_selection_reason = (
                    "auto_secondary_forge_after_coverage_gap"
                    if engine == "forge"
                    else "auto_primary_xmage"
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
                            "result_identity": result_identity,
                            "request_identity": request_identity,
                            "result_deck_hashes": result_deck_hashes,
                            "comparison_outcome": outcome,
                            "fallback_reason": fallback_reason,
                            "engine_selection_reason": engine_selection_reason,
                            "sample_classification": (
                                "natural"
                                if natural_sample
                                else "forced_access_diagnostic"
                            ),
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
                        "result_identity": result_identity,
                        "request_identity": request_identity,
                        "result_deck_hashes": result_deck_hashes,
                        "comparison_outcome": outcome,
                        "fallback_reason": fallback_reason,
                        "engine_selection_reason": engine_selection_reason,
                        "fallback_chain": (
                            ["xmage:coverage_incomplete", "forge"]
                            if engine == "forge"
                            else ["xmage"]
                        ),
                        "sample_classification": (
                            "natural"
                            if natural_sample
                            else "forced_access_diagnostic"
                        ),
                        "completed_at": utc_now(),
                    }
                )
                attempt["status"] = "completed"
                self._save()
                return state
            if (
                engine == "xmage"
                and response.status == 422
                and response.body.get("error") == "xmage_coverage_incomplete"
            ):
                if (
                    response.body.get("fallback_allowed") is not True
                    or response.body.get("fallback_reason") != "none"
                    or response.body.get("fallback_eligibility_reason")
                    != "coverage_incomplete_eligible"
                ):
                    attempt["status"] = "invalid_fallback_contract"
                    state["status"] = "failed"
                    state["error"] = "xmage_coverage_response_not_fallback_eligible"
                    self._save()
                    return state
                engine = "forge"
                attempt["next_engine"] = "forge"
                attempt["status"] = "coverage_incomplete"
                attempt["fallback_reason"] = "xmage_coverage_incomplete"
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
