#!/usr/bin/env python3

from __future__ import annotations

import tempfile
import unittest
import sys
import gzip
import importlib.util
import json
import copy
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import external_battle_async_runner as runner


def completed_result(
    card_name: str,
    *,
    engine: str = "xmage",
    seed: int = 1,
    deck_hashes: dict | None = None,
) -> dict:
    identity = runner.ENGINE_IDENTITIES[engine]
    return {
        "status": "completed",
        "engine": engine,
        "engine_commit": identity["engine_commit"],
        "engine_version": identity["engine_version"],
        "seed": seed,
        "winner_deck_key": "deck_a",
        "turns": 7,
        "deck_hashes": copy.deepcopy(
            deck_hashes or default_request(seed)["deck_hashes"]
        ),
        "learning_contract": {
            "schema_version": runner.LEARNING_SCHEMA,
            "absence_proves_nonuse": False,
        },
        "events": [
            {"event_type": "waiting", "card_name": "False Positive"},
            {"event_type": "ability_activated", "source_card_name": card_name},
        ],
    }


class FakeClient:
    def __init__(self, posts, health=None):
        self.posts = list(posts)
        self.health = list(health or [])
        self.post_calls = []
        self.post_payloads = []
        self.get_calls = []

    def post(self, url, payload, timeout):
        self.post_calls.append(url)
        self.post_payloads.append(copy.deepcopy(payload))
        response = self.posts.pop(0)
        engine = "forge" if "forge" in url else "xmage"
        return runner.HttpResult(
            response.status,
            strict_response(response.body, payload=payload, engine=engine),
        )

    def get(self, url, timeout):
        self.get_calls.append(url)
        response = self.health.pop(0)
        body = dict(response.body)
        identity = runner.ENGINE_IDENTITIES["xmage"]
        body.update(
            {
                "schema_version": runner.EXECUTION_SCHEMA,
                "engine": "xmage",
                "engine_version": identity["engine_version"],
                "engine_commit": identity["engine_commit"],
                "sidecar_protocol_version": runner.SIDECAR_PROTOCOL,
                "sidecar_build_identity": identity["sidecar_build_identity"],
                "ai_profile": identity["ai_profile"],
                identity["telemetry_field"]: identity["telemetry_version"],
                "seed_semantics": identity["seed_semantics"],
                "deterministic": identity["deterministic"],
                "sidecar_started_at": "2026-07-22T12:00:00Z",
            }
        )
        return runner.HttpResult(response.status, body)


def strict_response(body: dict, *, payload: dict, engine: str) -> dict:
    result = copy.deepcopy(body)
    identity = runner.ENGINE_IDENTITIES[engine]
    status = result.get("status") or (
        "coverage_incomplete"
        if result.get("error") == f"{engine}_coverage_incomplete"
        else "timeout"
        if result.get("error") == "simulation_timeout"
        else "failed"
    )
    result.setdefault("status", status)
    result.setdefault("schema_version", runner.EXECUTION_SCHEMA)
    result.setdefault("engine", engine)
    result.setdefault("engine_version", identity["engine_version"])
    result.setdefault("engine_commit", identity["engine_commit"])
    result.setdefault("sidecar_protocol_version", runner.SIDECAR_PROTOCOL)
    result.setdefault("sidecar_build_identity", identity["sidecar_build_identity"])
    result.setdefault("ai_profile", identity["ai_profile"])
    result.setdefault(identity["telemetry_field"], identity["telemetry_version"])
    result.setdefault("seed_semantics", identity["seed_semantics"])
    result.setdefault("deterministic", identity["deterministic"])
    winner_key = result.get("winner_deck_key")
    if winner_key in {"deck_a", "deck_b"}:
        winner_deck = payload.get(winner_key) or {}
        result.setdefault("winner_deck_id", winner_deck.get("id"))
        result.setdefault("winner", winner_deck.get("name"))
    else:
        result.setdefault("winner_deck_id", None)
        result.setdefault("winner", None)
    result.setdefault("sidecar_process_id", f"{engine}-process-1")
    result.setdefault("sidecar_started_at", "2026-07-22T12:00:00Z")
    for field in ("request_id", "seed", "timeout_ms", "request_hash", "deck_hashes"):
        result.setdefault(field, copy.deepcopy(payload.get(field)))
    result.setdefault("fallback_reason", "none")
    coverage = status == "coverage_incomplete"
    result.setdefault("fallback_allowed", coverage)
    result.setdefault(
        "fallback_eligibility_reason",
        "coverage_incomplete_eligible" if coverage else "none",
    )
    result.setdefault(
        "request_contract",
        {
            "schema_version": runner.REQUEST_SCHEMA,
            "controls": {
                field: {"value": copy.deepcopy(payload.get(field))}
                for field in (
                    "max_turns",
                    "focus_cards",
                    "force_focus_access_mode",
                    "same_lane",
                    "natural_sample",
                )
            },
        },
    )
    return result


def registry_for(job: dict, *, minimum=1) -> dict:
    prepared = copy.deepcopy(job)
    request = dict(prepared.get("request") or {})
    seed = request.get("seed", 1)
    request.setdefault("request_id", prepared.get("job_id") or "fixture-job")
    request.setdefault("timeout_ms", 40_000)
    request.setdefault("max_turns", 30)
    deck_a = request.get("deck_a")
    deck_b = request.get("deck_b")
    if not isinstance(deck_a, dict) or not isinstance(deck_a.get("cards"), list):
        request["deck_a"] = default_request(seed)["deck_a"]
    if not isinstance(deck_b, dict) or not isinstance(deck_b.get("cards"), list):
        request["deck_b"] = default_request(seed)["deck_b"]
    request["deck_hashes"] = runner.canonical_request_deck_hashes(request)
    prepared["request"] = request
    return {
        "schema_version": runner.REGISTRY_SCHEMA,
        "minimum_completed_per_variant": minimum,
        "jobs": [prepared],
    }


def deck(deck_id: str, commander: str, focus: str, basic: str) -> dict:
    return {
        "id": deck_id,
        "name": deck_id,
        "cards": [
            {"name": commander, "quantity": 1, "is_commander": True},
            {"name": focus, "quantity": 1, "is_commander": False},
            {"name": basic, "quantity": 98, "is_commander": False},
        ],
    }


def default_request(seed: int = 1) -> dict:
    request = {
        "request_id": f"fixture-{seed}",
        "seed": seed,
        "timeout_ms": 40_000,
        "max_turns": 30,
        "deck_a": deck("fixture-a", "Fixture Commander", "Candidate", "Mountain"),
        "deck_b": deck("fixture-b", "Opponent Commander", "Opp Card", "Forest"),
    }
    request["deck_hashes"] = runner.canonical_request_deck_hashes(request)
    return request


def golden_deck() -> dict:
    return {
        "id": "golden",
        "cards": [
            {
                "name": "Lorehold, the Historian",
                "quantity": 1,
                "is_commander": True,
                "set_code": "STX",
                "collector_number": "268",
            },
            {
                "name": "The Mind Stone",
                "quantity": 1,
                "is_commander": False,
                "set_code": "PIP",
                "collector_number": "145",
            },
            {
                "name": "Mountain",
                "quantity": 98,
                "is_commander": False,
                "set_code": "",
                "collector_number": "",
            },
        ],
    }


GOLDEN_DECK_HASH_V1 = "926d4864af12aa6d6bd9b57758df6249a3fbc49fdb2818ed5941a58f0c35e25b"


def comparison_registry(*, seeds=(1, 2, 3), minimum=3) -> dict:
    base_deck = deck("base-deck", "Subject Commander", "Removed", "Mountain")
    candidate_deck = deck(
        "candidate-deck",
        "Subject Commander",
        "Added",
        "Mountain",
    )
    opponent = deck("opponent-deck", "Opponent Commander", "Opp Card", "Forest")
    base_hash = runner.canonical_deck_hash(base_deck)
    candidate_hash = runner.canonical_deck_hash(candidate_deck)
    opponent_hash = runner.canonical_deck_hash(opponent)
    jobs = []
    for variant, subject, focus in (
        ("base", base_deck, "Removed"),
        ("candidate", candidate_deck, "Added"),
    ):
        for seed in seeds:
            request = {
                "request_id": f"{variant}-{seed}",
                "seed": seed,
                "timeout_ms": 40000,
                "max_turns": 30,
                "deck_a": copy.deepcopy(subject),
                "deck_b": copy.deepcopy(opponent),
            }
            request["deck_hashes"] = runner.canonical_request_deck_hashes(request)
            jobs.append(
                {
                    "job_id": f"{variant}-{seed}",
                    "comparison_id": "swap-1",
                    "variant": variant,
                    # These legacy flags are deliberately not proof.
                    "same_lane": True,
                    "forced_access": False,
                    "focus_cards": [focus],
                    "request": request,
                }
            )
    return {
        "schema_version": runner.REGISTRY_SCHEMA,
        "minimum_completed_per_variant": minimum,
        "comparisons": [
            {
                "schema_version": runner.COMPARISON_CONTRACT_SCHEMA,
                "comparison_id": "swap-1",
                "subject_deck_key": "deck_a",
                "commander_identity": "Subject Commander",
                "opponent_deck_id": "opponent-deck",
                "opponent_commander_identity": "Opponent Commander",
                "base_deck_hash": base_hash,
                "candidate_deck_hash": candidate_hash,
                "opponent_deck_hash": opponent_hash,
                "seed_set": list(seeds),
                "timeout_policy": {
                    "timeout_ms": 40000,
                    "censoring": "exclude_any_timeout_attempt",
                },
                "same_lane_hypothesis": {
                    "schema_version": runner.SAME_LANE_HYPOTHESIS_SCHEMA,
                    "status": "reviewed",
                    "owner": "deckbuilder_quality",
                    "removed_lane_key": "ramp",
                    "added_lane_key": "ramp",
                    "removed_cards": ["Removed"],
                    "added_cards": ["Added"],
                    "evidence_refs": ["postgresql:functional_card_tags"],
                },
                "legality_attestation": {
                    "schema_version": runner.LEGALITY_ATTESTATION_SCHEMA,
                    "source": "postgresql_deck_rules_service",
                    "validation_id": "fixture-validation-1",
                    "decks": [
                        {
                            "deck_hash": deck_hash,
                            "status": "legal",
                            "card_count": 100,
                            "commander_count": 1,
                        }
                        for deck_hash in (base_hash, candidate_hash, opponent_hash)
                    ],
                },
            }
        ],
        "jobs": jobs,
    }


def comparison_states(registry: dict) -> dict:
    states = {}
    for job in registry["jobs"]:
        seed = job["request"]["seed"]
        focus = job["focus_cards"][0]
        engine_request = runner.strict_engine_request(
            job["request"],
            job=job,
            engine="xmage",
            same_lane=True,
        )
        response = strict_response(
            completed_result(
                focus,
                seed=seed,
                deck_hashes=job["request"]["deck_hashes"],
            ),
            payload=engine_request,
            engine="xmage",
        )
        states[job["job_id"]] = {
            "status": "completed",
            "engine": "xmage",
            "attempts": [{"http_status": 200, "status": "completed"}],
            "sample_classification": "natural",
            "result_identity": runner._result_identity(response),
            "request_identity": {
                key: copy.deepcopy(engine_request.get(key))
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
            "result_deck_hashes": copy.deepcopy(job["request"]["deck_hashes"]),
            "comparison_outcome": runner.comparison_outcome(
                response,
                engine_request,
                subject_deck_key="deck_a",
            ),
            "evidence": {
                "positive_exposure_ready": True,
                "typed_positive_event_count": 1,
                "natural_sample": True,
                "focus_cards": [
                    {
                        "card_name": focus,
                        "positive_exposure": True,
                        "exposure_state": "positive",
                        "evidence_kind": "typed_event",
                        "event_types": ["spell_cast"],
                    }
                ],
            },
        }
    return states


class ExternalBattleAsyncRunnerTest(unittest.TestCase):
    def test_comparison_outcome_is_request_correlated_and_never_seed_paired(self):
        request = default_request(7)
        result = strict_response(
            completed_result("Candidate", seed=7),
            payload=request,
            engine="xmage",
        )

        subject = runner.comparison_outcome(
            result,
            request,
            subject_deck_key="deck_a",
        )
        opponent = runner.comparison_outcome(
            result,
            request,
            subject_deck_key="deck_b",
        )

        self.assertTrue(subject["valid"])
        self.assertEqual(subject["classification"], "win")
        self.assertEqual(opponent["classification"], "loss")
        self.assertFalse(subject["seed_pairing_claim"])

    def test_comparison_outcome_accepts_draw_and_blocks_censored_winner_leak(self):
        request = default_request(11)
        draw = strict_response(
            {
                **completed_result("Candidate", seed=11),
                "winner_deck_key": None,
            },
            payload=request,
            engine="xmage",
        )
        draw["winner"] = None
        draw["winner_deck_id"] = None
        draw_outcome = runner.comparison_outcome(
            draw,
            request,
            subject_deck_key="deck_a",
        )
        self.assertTrue(draw_outcome["valid"])
        self.assertEqual(draw_outcome["classification"], "draw")

        censored = dict(draw)
        censored.update(
            {
                "status": "censored",
                "winner_deck_key": "deck_a",
                "winner_deck_id": request["deck_a"]["id"],
                "winner": request["deck_a"]["name"],
            }
        )
        censored_outcome = runner.comparison_outcome(
            censored,
            request,
            subject_deck_key="deck_a",
        )
        self.assertFalse(censored_outcome["valid"])
        self.assertIn("censored_result_exposes_winner", censored_outcome["errors"])

    def test_deck_hash_v1_matches_shared_golden_and_forge(self):
        golden = golden_deck()

        self.assertEqual(runner.canonical_deck_hash(golden), GOLDEN_DECK_HASH_V1)
        reordered = copy.deepcopy(golden)
        reordered["cards"].reverse()
        self.assertEqual(runner.canonical_deck_hash(reordered), GOLDEN_DECK_HASH_V1)
        spaced = copy.deepcopy(golden)
        spaced["cards"][0]["name"] = "  Lorehold, the Historian  "
        spaced["cards"][0]["set_code"] = " STX "
        self.assertEqual(runner.canonical_deck_hash(spaced), GOLDEN_DECK_HASH_V1)
        changed_case = copy.deepcopy(golden)
        changed_case["cards"][0]["set_code"] = "stx"
        self.assertNotEqual(runner.canonical_deck_hash(changed_case), GOLDEN_DECK_HASH_V1)

        forge_path = (
            Path(__file__).resolve().parents[4]
            / "services"
            / "forge-sidecar"
            / "sidecar.py"
        )
        spec = importlib.util.spec_from_file_location("forge_sidecar_golden", forge_path)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        forge = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = forge
        try:
            spec.loader.exec_module(forge)
            forge_hash = forge.canonical_deck_hash(
                forge.DeckInput.parse(spaced, "deck")
            )
        finally:
            sys.modules.pop(spec.name, None)
        self.assertEqual(forge_hash, GOLDEN_DECK_HASH_V1)

    def test_registry_and_checkpoint_v1_are_rejected_after_identity_upgrade(self):
        registry = registry_for(
            {"job_id": "identity-upgrade", "request": {"seed": 1}}
        )
        legacy_registry = copy.deepcopy(registry)
        legacy_registry["schema_version"] = "external_battle_async_registry_v1"
        with self.assertRaisesRegex(ValueError, runner.REGISTRY_SCHEMA):
            runner.validate_registry(legacy_registry)

        with tempfile.TemporaryDirectory() as temporary:
            checkpoint = Path(temporary) / "checkpoint.json"
            checkpoint.write_text(
                json.dumps(
                    {
                        "schema_version": "external_battle_async_checkpoint_v1",
                        "registry_hash": runner.stable_registry_hash(registry),
                        "jobs": {},
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "checkpoint schema"):
                runner.load_checkpoint(checkpoint, registry)

    def test_request_hash_v2_matches_dart_forge_and_xmage_golden_vectors(self):
        cards = [
            {"name": "Commander", "quantity": 1, "is_commander": True},
            {"name": "Plains", "quantity": 99, "is_commander": False},
        ]
        request = {
            "request_id": "request-42",
            "seed": 42,
            "timeout_ms": 40_000,
            "max_turns": 30,
            "focus_cards": ["Sol Ring"],
            "force_focus_access_mode": "none",
            "same_lane": True,
            "natural_sample": True,
            "deck_a": {"id": "deck-a", "cards": cards},
            "deck_b": {"id": "deck-b", "cards": list(reversed(cards))},
        }
        request["deck_hashes"] = runner.canonical_request_deck_hashes(request)
        job = {"focus_cards": ["Sol Ring"]}

        xmage = runner.strict_engine_request(
            request,
            job=job,
            engine="xmage",
            same_lane=True,
        )
        forge = runner.strict_engine_request(
            request,
            job=job,
            engine="forge",
            same_lane=True,
        )

        self.assertEqual(
            xmage["request_hash"],
            "ad93b5dd41231adc7c9c1a25772aca16a4cc0e418081d6897962edf1153539b6",
        )
        self.assertEqual(
            forge["request_hash"],
            "4f9ee996b548e718547b58d0dfcf8765e7751c143fd273cc50821a4cb4d17469",
        )

    def test_runner_builds_strict_engine_specific_request_v2(self):
        client = FakeClient([runner.HttpResult(200, completed_result("Candidate"))])
        job = {
            "job_id": "strict-request",
            "request": {"seed": 1},
            "focus_cards": ["Candidate"],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=1,
                client=client,
            ).run()["jobs"]["strict-request"]

        sent = client.post_payloads[0]
        identity = runner.ENGINE_IDENTITIES["xmage"]
        self.assertEqual(sent["request_schema_version"], runner.REQUEST_SCHEMA)
        self.assertEqual(sent["expected_engine_commit"], identity["engine_commit"])
        self.assertEqual(sent["ai_profile"], identity["ai_profile"])
        self.assertEqual(
            sent["request_hash"],
            runner.canonical_external_request_hash(sent),
        )
        self.assertEqual(state["request_identity"]["request_hash"], sent["request_hash"])
        self.assertEqual(state["fallback_reason"], "none")
        self.assertEqual(state["engine_selection_reason"], "auto_primary_xmage")

    def test_zero_turn_completed_payload_fails_closed(self):
        invalid_result = completed_result("Candidate")
        invalid_result.update(
            {
                "winner": None,
                "turns": 0,
                "events": [],
                "visual_snapshots": [],
                "game_log": [],
            }
        )
        client = FakeClient([runner.HttpResult(200, invalid_result)])
        job = {
            "job_id": "zero-turn-completion",
            "request": {"seed": 1, "deck_a": {}, "deck_b": {}},
            "focus_cards": ["Candidate"],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
            ).run()["jobs"]["zero-turn-completion"]

        self.assertEqual(state["status"], "failed")
        self.assertEqual(state["error"], "engine_result_missing_positive_turn_count")
        self.assertEqual(state["attempts"][0]["status"], "invalid_completed_result")
        self.assertFalse(state["evidence"]["completed"])
        self.assertFalse(state["evidence"]["positive_exposure_ready"])
        self.assertEqual(client.post_calls, ["http://xmage/simulate"])

    def test_mismatched_engine_and_embedded_error_fail_closed(self):
        cases = (
            (
                completed_result("Candidate", engine="forge"),
                "engine_identity_mismatch:engine",
            ),
            (
                {**completed_result("Candidate"), "error": "engine_failed"},
                "engine_result_contains_error",
            ),
            (
                {**completed_result("Candidate"), "error": ""},
                "engine_result_contains_error",
            ),
        )
        for index, (invalid_result, expected_error) in enumerate(cases):
            with (
                self.subTest(expected_error=expected_error),
                tempfile.TemporaryDirectory() as temporary,
            ):
                client = FakeClient([runner.HttpResult(200, invalid_result)])
                job = {
                    "job_id": f"invalid-completion-{index}",
                    "request": {"seed": 1, "deck_a": {}, "deck_b": {}},
                    "focus_cards": ["Candidate"],
                }
                root = Path(temporary)
                state = runner.BattleQueueRunner(
                    registry=registry_for(job),
                    checkpoint_path=root / "checkpoint.json",
                    result_dir=root / "results",
                    xmage_url="http://xmage",
                    forge_url="http://forge",
                    request_timeout=5,
                    recovery_timeout=5,
                    max_attempts=3,
                    client=client,
                ).run()["jobs"][job["job_id"]]

            self.assertEqual(state["status"], "failed")
            self.assertEqual(state["error"], expected_error)
            if expected_error.startswith("engine_identity_mismatch"):
                self.assertNotIn("evidence", state)
            else:
                self.assertFalse(state["evidence"]["completed"])
                self.assertFalse(state["evidence"]["positive_exposure_ready"])

    def test_positive_evidence_rejects_generic_named_events(self):
        evidence = runner.extract_positive_evidence(
            completed_result("Krenko, Mob Boss"),
            focus_cards=["Krenko, Mob Boss", "False Positive"],
        )
        by_name = {row["card_name"]: row for row in evidence["focus_cards"]}
        self.assertTrue(by_name["Krenko, Mob Boss"]["positive_exposure"])
        self.assertFalse(by_name["False Positive"]["positive_exposure"])
        self.assertFalse(evidence["all_focus_cards_exposed"])
        self.assertFalse(evidence["swap_superiority_proven"])
        self.assertFalse(evidence["promotion_allowed"])

    def test_natural_same_lane_evidence_matches_backend_contract_without_focus(self):
        result = completed_result("Aerialephant")
        result["events"] = [
            {"event_type": "spell_cast", "card": "Aerialephant"},
            {"event_type": "ability_resolved", "source": "Aerialephant"},
            {"event_type": "damage", "target_card": "Target Creature"},
        ]

        evidence = runner.extract_positive_evidence(
            result,
            expected_engine="xmage",
            same_lane=True,
            natural_sample=True,
        )

        self.assertTrue(evidence["positive_exposure_ready"])
        self.assertTrue(evidence["natural_same_lane_exposure"])
        self.assertEqual(evidence["learning_contract_schema"], runner.LEARNING_SCHEMA)
        self.assertEqual(
            evidence["exposed_card_names_normalized"],
            ["aerialephant"],
        )
        self.assertFalse(evidence["comparison_input_ready"])
        self.assertFalse(evidence["promotion_allowed"])

    def test_text_log_visibility_and_target_only_events_remain_unknown(self):
        result = completed_result("Candidate")
        result["events"] = [
            {
                "type": "add_to_stack",
                "message": "Ai(1) cast Candidate",
                "card_name": "Candidate",
            },
            {
                "action": "visible_zone_entry",
                "card_name": "Candidate",
            },
            {
                "event_type": "damage",
                "target_card": "Candidate",
            },
        ]

        evidence = runner.extract_positive_evidence(
            result,
            focus_cards=["Candidate"],
        )

        self.assertFalse(evidence["positive_exposure_ready"])
        self.assertEqual(evidence["unknown_focus_card_count"], 1)
        self.assertEqual(evidence["focus_cards"][0]["exposure_state"], "unknown")
        self.assertEqual(evidence["typed_positive_event_count"], 0)

    def test_forge_type_only_event_remains_unknown(self):
        result = completed_result("Candidate", engine="forge")
        result["events"] = [
            {
                "type": "spell_cast",
                "card_name": "Candidate",
                "message": "Ai(1) cast Candidate",
            }
        ]

        evidence = runner.extract_positive_evidence(
            result,
            focus_cards=["Candidate"],
            expected_engine="forge",
        )

        self.assertFalse(evidence["positive_exposure_ready"])
        self.assertEqual(evidence["focus_cards"][0]["exposure_state"], "unknown")
        self.assertEqual(evidence["typed_positive_event_count"], 0)

    def test_focused_positive_and_negative_tests_are_rule_input_not_swap_exposure(self):
        result = completed_result("Candidate")
        result["events"] = []

        evidence = runner.extract_positive_evidence(
            result,
            focus_cards=["Candidate"],
            focused_test_evidence={
                "schema_version": runner.FOCUSED_TEST_EVIDENCE_SCHEMA,
                "card_names": ["Candidate"],
                "positive_test_passed": True,
                "negative_test_passed": True,
                "test_id": "test_candidate_rule",
                "source_revision": "sha-123",
            },
        )

        self.assertFalse(evidence["positive_exposure_ready"])
        self.assertTrue(evidence["rule_execution_input_ready"])
        self.assertFalse(evidence["comparison_input_ready"])
        self.assertFalse(evidence["promotion_allowed"])

    def test_forced_access_remains_diagnostic_only_in_positive_evidence(self):
        evidence = runner.extract_positive_evidence(
            completed_result("Candidate"),
            focus_cards=["Candidate"],
            same_lane=True,
            natural_sample=False,
        )

        self.assertTrue(evidence["positive_exposure_ready"])
        self.assertFalse(evidence["natural_same_lane_exposure"])
        self.assertFalse(evidence["comparison_input_ready"])

    def test_forge_is_used_only_for_structured_xmage_coverage_gap(self):
        client = FakeClient(
            [
                runner.HttpResult(422, {"error": "xmage_coverage_incomplete"}),
                runner.HttpResult(200, completed_result("Candidate", engine="forge")),
            ]
        )
        job = {
            "job_id": "forge-fallback",
            "request": {"seed": 1, "deck_a": {}, "deck_b": {}},
            "focus_cards": ["Candidate"],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            queue = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
                sleeper=lambda _seconds: None,
            )
            state = queue.run()["jobs"]["forge-fallback"]
            with gzip.open(state["result_path"], "rt", encoding="utf-8") as handle:
                self.assertEqual(json.load(handle)["status"], "completed")
        self.assertEqual(state["status"], "completed")
        self.assertEqual(state["engine"], "forge")
        self.assertEqual(client.post_calls, ["http://xmage/simulate", "http://forge/simulate"])

    def test_operational_xmage_failure_never_falls_back(self):
        client = FakeClient([runner.HttpResult(500, {"error": "engine_failed"})])
        job = {"job_id": "failure", "request": {"seed": 1}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            queue = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
            )
            state = queue.run()["jobs"]["failure"]
        self.assertEqual(state["status"], "failed")
        self.assertEqual(client.post_calls, ["http://xmage/simulate"])

    def test_xmage_timeout_requires_a_new_process_before_retry(self):
        client = FakeClient(
            [
                runner.HttpResult(
                    504,
                    {
                        "error": "simulation_timeout",
                        "restart_required": True,
                        "sidecar_process_id": "old",
                    },
                ),
                runner.HttpResult(200, completed_result("Candidate")),
            ],
            health=[
                runner.HttpResult(200, {"status": "ok", "catalog_ready": True, "sidecar_process_id": "old"}),
                runner.HttpResult(200, {"status": "ok", "catalog_ready": True, "sidecar_process_id": "new"}),
            ],
        )
        job = {"job_id": "timeout", "request": {"seed": 1}, "focus_cards": ["Candidate"]}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            queue = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
                sleeper=lambda _seconds: None,
            )
            state = queue.run()["jobs"]["timeout"]
        self.assertEqual(state["status"], "completed")
        self.assertTrue(state["attempts"][0]["recovery_observed"])
        self.assertEqual(len(client.get_calls), 2)

    def test_xmage_timeout_without_restart_contract_is_not_retried(self):
        client = FakeClient(
            [runner.HttpResult(504, {"error": "simulation_timeout"})]
        )
        job = {"job_id": "unsafe-timeout", "request": {"seed": 1}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=3,
                client=client,
            ).run()["jobs"]["unsafe-timeout"]

        self.assertEqual(state["status"], "timeout")
        self.assertEqual(state["error"], "xmage_timeout_restart_not_declared")
        self.assertEqual(client.post_calls, ["http://xmage/simulate"])
        self.assertEqual(client.get_calls, [])

    def test_completed_job_is_not_reexecuted_on_resume(self):
        client = FakeClient([runner.HttpResult(200, completed_result("Candidate"))])
        job = {"job_id": "resume", "request": {"seed": 1}, "focus_cards": ["Candidate"]}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            kwargs = dict(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=2,
                client=client,
            )
            runner.BattleQueueRunner(**kwargs).run()
            runner.BattleQueueRunner(**kwargs).run()
        self.assertEqual(len(client.post_calls), 1)

    def test_terminal_failure_is_not_reexecuted_on_resume(self):
        client = FakeClient([runner.HttpResult(500, {"error": "engine_failed"})])
        job = {"job_id": "terminal-failure", "request": {"seed": 1}}
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            kwargs = dict(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=2,
                client=client,
            )
            runner.BattleQueueRunner(**kwargs).run()
            runner.BattleQueueRunner(**kwargs).run()
        self.assertEqual(len(client.post_calls), 1)

    def test_registry_rejects_duplicate_comparison_seed(self):
        registry = comparison_registry()
        duplicate = copy.deepcopy(registry["jobs"][0])
        duplicate["job_id"] = "duplicate-base-seed"
        registry["jobs"].append(duplicate)
        with self.assertRaisesRegex(ValueError, "duplicate comparison sample"):
            runner.validate_registry(registry)

    def test_registry_rejects_deck_hashes_from_different_material(self):
        registry = comparison_registry()
        registry["jobs"][0]["request"]["deck_hashes"]["deck_a"] = "stale"

        with self.assertRaisesRegex(ValueError, "deck_hashes do not match"):
            runner.validate_registry(registry)

    def test_comparison_gate_requires_equal_natural_exposed_samples(self):
        registry = comparison_registry()
        runner.validate_registry(registry)
        checkpoint = {"jobs": comparison_states(registry)}
        gate = runner.evaluate_comparisons(registry, checkpoint)["swap-1"]
        self.assertTrue(gate["comparison_input_ready"])
        self.assertTrue(gate["same_lane"])
        self.assertTrue(gate["postgresql_legality_attestation_valid"])
        self.assertTrue(gate["same_engine_commit_and_version"])
        self.assertTrue(gate["completed_seed_set_matches_contract"])
        self.assertTrue(gate["engine_result_deck_hashes_match"])
        self.assertFalse(gate["seed_pairing_claim"])
        self.assertEqual(
            gate["statistical_design_required"],
            "engine_semantics_aware_independent_samples",
        )
        self.assertEqual(gate["blockers"], [])
        self.assertFalse(gate["promotion_allowed"])
        self.assertFalse(gate["swap_superiority_proven"])

    def test_comparison_gate_rejects_completed_but_unexposed_seed(self):
        registry = comparison_registry()
        states = comparison_states(registry)
        for job_id in ("base-3", "candidate-3"):
            evidence = states[job_id]["evidence"]
            evidence["positive_exposure_ready"] = False
            evidence["typed_positive_event_count"] = 0
            evidence["focus_cards"][0].update(
                {
                    "positive_exposure": False,
                    "exposure_state": "unknown",
                    "evidence_kind": None,
                    "event_types": [],
                }
            )
        gate = runner.evaluate_comparisons(registry, {"jobs": states})["swap-1"]
        self.assertFalse(gate["comparison_input_ready"])
        self.assertEqual(gate["base_exposure_eligible"], 2)
        self.assertFalse(gate["exposure_qualified_enough"])
        self.assertIn("typed_focus_exposure_missing_or_unknown", gate["blockers"])
        self.assertEqual(
            gate["next_gate"],
            "collect_typed_natural_focus_card_exposure",
        )

    def test_comparison_gate_blocks_timeout_censored_completed_retry(self):
        registry = comparison_registry()
        states = comparison_states(registry)
        states["candidate-2"]["attempts"] = [
            {"http_status": 504, "status": "timeout"},
            {"http_status": 200, "status": "completed"},
        ]

        gate = runner.evaluate_comparisons(registry, {"jobs": states})["swap-1"]

        self.assertFalse(gate["comparison_input_ready"])
        self.assertTrue(gate["timeout_censored"])
        self.assertIn("timeout_censored_sample", gate["blockers"])
        self.assertEqual(gate["next_gate"], "rerun_uncensored_same_policy_seed_set")

    def test_comparison_gate_blocks_completed_sample_without_outcome(self):
        registry = comparison_registry()
        states = comparison_states(registry)
        states["candidate-2"].pop("comparison_outcome")

        gate = runner.evaluate_comparisons(registry, {"jobs": states})["swap-1"]

        self.assertFalse(gate["comparison_input_ready"])
        self.assertFalse(gate["comparison_outcomes_valid"])
        self.assertIn("comparison_outcome_missing_or_invalid", gate["blockers"])

    def test_comparison_gate_blocks_forced_access_even_with_positive_events(self):
        registry = comparison_registry()
        states = comparison_states(registry)
        states["candidate-2"]["sample_classification"] = "forced_access_diagnostic"
        states["candidate-2"]["evidence"]["natural_sample"] = False

        gate = runner.evaluate_comparisons(registry, {"jobs": states})["swap-1"]

        self.assertFalse(gate["comparison_input_ready"])
        self.assertTrue(gate["forced_access_diagnostic"])
        self.assertIn("forced_access_or_non_natural_sample", gate["blockers"])
        self.assertEqual(
            gate["next_gate"],
            "collect_natural_samples_without_forced_access",
        )

    def test_comparison_gate_blocks_engine_commit_mismatch(self):
        registry = comparison_registry()
        states = comparison_states(registry)
        states["candidate-3"]["result_identity"]["engine_commit"] = "other-commit"

        gate = runner.evaluate_comparisons(registry, {"jobs": states})["swap-1"]

        self.assertFalse(gate["comparison_input_ready"])
        self.assertFalse(gate["same_engine_commit_and_version"])
        self.assertIn("engine_identity_mismatch_or_incomplete", gate["blockers"])

    def test_comparison_gate_blocks_engine_result_deck_hash_mismatch(self):
        registry = comparison_registry()
        states = comparison_states(registry)
        states["candidate-3"]["result_deck_hashes"]["deck_a"] = "wrong-deck"

        gate = runner.evaluate_comparisons(registry, {"jobs": states})["swap-1"]

        self.assertFalse(gate["comparison_input_ready"])
        self.assertFalse(gate["engine_result_deck_hashes_match"])
        self.assertIn("engine_result_deck_hashes_mismatch", gate["blockers"])
        self.assertEqual(
            gate["next_gate"],
            "repair_engine_result_deck_correlation",
        )

    def test_comparison_preflight_blocks_unproven_lane_and_hash_mismatch(self):
        registry = comparison_registry()
        contract = registry["comparisons"][0]
        contract["same_lane_hypothesis"]["added_lane_key"] = "card_draw"
        contract["candidate_deck_hash"] = "incorrect"

        preflight = runner.comparison_preflight(registry, "swap-1")

        self.assertFalse(preflight["valid"])
        self.assertFalse(preflight["same_lane_hypothesis_verified"])
        self.assertIn("same_lane_keys_mismatch", preflight["blockers"])
        self.assertIn("candidate_deck_hash_mismatch", preflight["blockers"])
        gate = runner.evaluate_comparisons(
            registry,
            {"jobs": comparison_states(registry)},
        )["swap-1"]
        self.assertFalse(gate["comparison_input_ready"])
        self.assertEqual(gate["next_gate"], "repair_canonical_comparison_contract")

    def test_registry_rejects_bad_cardinality_and_non_postgres_legality(self):
        registry = comparison_registry()
        registry["jobs"][0]["request"]["deck_a"]["cards"][2]["quantity"] = 97
        registry["jobs"][0]["request"]["deck_hashes"] = (
            runner.canonical_request_deck_hashes(registry["jobs"][0]["request"])
        )
        registry["comparisons"][0]["legality_attestation"]["source"] = "self_reported"

        with self.assertRaisesRegex(
            ValueError,
            "subject_deck_shape_invalid|canonical_legality_source_mismatch",
        ):
            runner.validate_registry(registry)

    def test_engine_result_seed_mismatch_fails_job(self):
        client = FakeClient(
            [runner.HttpResult(200, completed_result("Candidate", seed=999))]
        )
        job = {
            "job_id": "seed-mismatch",
            "request": {"seed": 1, "deck_a": {}, "deck_b": {}},
            "focus_cards": ["Candidate"],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=1,
                client=client,
            ).run()["jobs"]["seed-mismatch"]

        self.assertEqual(state["status"], "failed")
        self.assertEqual(state["error"], "engine_correlation_mismatch:seed")

    def test_engine_result_deck_hash_mismatch_fails_job(self):
        invalid_result = completed_result("Candidate")
        invalid_result["deck_hashes"]["deck_b"] = "wrong-deck"
        client = FakeClient([runner.HttpResult(200, invalid_result)])
        job = {
            "job_id": "deck-hash-mismatch",
            "request": {"seed": 1},
            "focus_cards": ["Candidate"],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            state = runner.BattleQueueRunner(
                registry=registry_for(job),
                checkpoint_path=root / "checkpoint.json",
                result_dir=root / "results",
                xmage_url="http://xmage",
                forge_url="http://forge",
                request_timeout=5,
                recovery_timeout=5,
                max_attempts=1,
                client=client,
            ).run()["jobs"]["deck-hash-mismatch"]

        self.assertEqual(state["status"], "failed")
        self.assertEqual(
            state["error"],
            "engine_correlation_mismatch:deck_hashes",
        )


if __name__ == "__main__":
    unittest.main()
