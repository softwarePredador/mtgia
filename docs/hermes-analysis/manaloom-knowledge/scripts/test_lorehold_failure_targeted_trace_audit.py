import json

import lorehold_failure_targeted_trace_audit as audit


def test_default_synthesis_uses_current_after_profiled_gate_handoff():
    assert (
        audit.DEFAULT_SYNTHESIS.name
        == "lorehold_failure_targeted_synergy_hypotheses_20260630_after_profiled_gate.json"
    )


def write_json(path, payload):
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def synthesis_payload():
    return {
        "hypotheses": [
            {
                "hypothesis_key": "trace_seed7_engine_access_sequence",
                "status": "trace_audit_required",
                "target_failure": "seed 7 missing or low engine access",
                "target_seeds": [7],
                "focus_cards": [
                    "Urza's Saga",
                    "Library of Leng",
                    "Sensei's Divining Top",
                    "Scroll Rack",
                    "Squee, Goblin Nabob",
                ],
            },
            {
                "hypothesis_key": "audit_urzas_saga_artifact_tutor_scope",
                "status": "runtime_utilization_audit_required",
                "target_failure": "existing engine may be under-modeled",
                "target_seeds": [7, 42],
                "focus_cards": ["Urza's Saga", "Sensei's Divining Top", "Library of Leng"],
            },
            {
                "hypothesis_key": "audit_squee_graveyard_entry_route",
                "status": "trace_audit_required",
                "target_failure": "Squee value exists but not through Lorehold discard",
                "target_seeds": [7, 42],
                "focus_cards": ["Squee, Goblin Nabob", "Library of Leng", "Lorehold, the Historian"],
            },
        ]
    }


def result(seed, wins, losses, *, game_results=False, squee_trace=False, focus_trace=False, focus_access=False):
    telemetry = {
        "event_counts": {
            "saga_chapter_progressed": 2,
            "saga_chapter_resolved": 1,
            "saga_sacrificed_by_sba": 1,
            "topdeck_manipulation_activated": 3 if seed == 42 else 1,
            "replacement_applied": 2,
            "tutor_resolved": 2,
        },
        "strategic_event_counts": {
            "lorehold_cost_paid": 12,
            "lorehold_spell_cast": 9,
            "lorehold_upkeep_rummage": 4,
            "miracle_cast": 5 if seed == 42 else 1,
            "topdeck_manipulation_activated": 3 if seed == 42 else 1,
            "squee_to_graveyard": 1 if seed == 42 else 0,
            "squee_upkeep_return": 1 if seed == 42 else 0,
            "squee_return_after_known_graveyard_entry": 1 if seed == 42 else 0,
        },
        "strategic_games": {
            "miracle_cast": {"games": 2 if seed == 42 else 1, "rate": 0.5},
            "topdeck_manipulation_activated": {"games": 2 if seed == 42 else 1, "rate": 0.5},
            "squee_to_graveyard": {"games": 1 if seed == 42 else 0, "rate": 0.25},
        },
        "top_cards": [
            {"key": "topdeck:Sensei's Divining Top", "count": 2},
            {"key": "topdeck:Scroll Rack", "count": 1},
            {"key": "cost_paid:Library of Leng", "count": 1},
        ],
        "squee_game_traces": {},
        "squee_known_graveyard_balance_by_game": {},
        "squee_anomalies": [],
        "focus_card_game_traces": {},
    }
    if squee_trace:
        telemetry["squee_game_traces"] = {
            "candidate:opponent:0": [
                {
                    "event": "cast_announced",
                    "data": {"card": "Squee, Goblin Nabob", "turn": 4, "player": "Lorehold"},
                    "seq": 10,
                },
                {
                    "event": "permanent_moved_from_battlefield",
                    "data": {
                        "card": "Squee, Goblin Nabob",
                        "to_zone": "graveyard",
                        "reason": "combat_damage",
                        "turn": 5,
                        "player": "Lorehold",
                    },
                    "seq": 20,
                },
            ]
        }
        telemetry["top_cards"].append({"key": "cost_paid:Squee, Goblin Nabob", "count": 1})
    if focus_trace:
        telemetry["focus_card_game_traces"] = {
            "candidate:opponent:0": [
                {
                    "seq": 1,
                    "game_id": "candidate:opponent:0",
                    "event": "saga_chapter_resolved",
                    "cards": ["Urza's Saga"],
                    "data": {
                        "player": "Lorehold",
                        "card": "Urza's Saga",
                        "chapter": 3,
                        "target_type": "artifact_cmc_1_or_less",
                        "found": "Sol Ring",
                        "candidate_names": ["Sol Ring", "Sensei's Divining Top"],
                        "legal_target_names": ["Sol Ring", "Sensei's Divining Top"],
                        "selected_reason": "mana_priority",
                    },
                }
            ]
        }
    if focus_access:
        rows = telemetry["focus_card_game_traces"].setdefault("candidate:opponent:0", [])
        rows.append(
            {
                "seq": 2,
                "game_id": "candidate:opponent:0",
                "event": "focus_card_access_snapshot",
                "cards": [
                    "Urza's Saga",
                    "Sensei's Divining Top",
                    "Scroll Rack",
                    "Squee, Goblin Nabob",
                ],
                "data": {
                    "player": "Lorehold",
                    "phase": "opening_keep",
                    "turn": 0,
                    "hand_size": 7,
                    "library_size": 92,
                    "focus_card_zones": {
                        "Urza's Saga": {"zone": "hand"},
                        "Library of Leng": {"zone": "library", "library_position": 12},
                        "Sensei's Divining Top": {"zone": "hand"},
                        "Scroll Rack": {"zone": "library", "library_position": 4},
                        "Squee, Goblin Nabob": {"zone": "library", "library_position": 18},
                    },
                    "hand_focus": ["Urza's Saga", "Sensei's Divining Top"],
                    "library_focus": ["Library of Leng", "Scroll Rack", "Squee, Goblin Nabob"],
                    "library_top_focus": ["Scroll Rack"],
                    "top_library": [{"name": "Scroll Rack"}],
                    "opening_reason": "early_engine:Sensei's Divining Top:1",
                },
            }
        )

    payload = {
        "deck_key": audit.CANDIDATE_KEY,
        "deck_name": "candidate",
        "games": wins + losses,
        "wins": wins,
        "losses": losses,
        "stalls": 0,
        "win_rate": round(100 * wins / max(1, wins + losses), 2),
        "telemetry": telemetry,
    }
    if game_results:
        payload["game_results"] = [
            {
                "game_id": f"seed{seed}:game0",
                "game_index": 0,
                "opponent": "Opponent",
                "result": "win" if wins else "loss",
                "reason": "test",
                "turns": 7,
                "squee_trace_count": 2 if squee_trace else 0,
                "squee_known_graveyard_balance": 1 if squee_trace else 0,
                "event_counts": {
                    "saga_chapter_progressed": 1,
                    "tutor_resolved": 1,
                    "topdeck_manipulation_activated": 1,
                },
                "strategic_event_counts": {
                    "miracle_cast": 1,
                    "topdeck_manipulation_activated": 1,
                    "squee_to_graveyard": 1 if squee_trace else 0,
                },
            }
        ]
    return payload


def gate(seed, wins, losses, *, game_results=False, squee_trace=False, focus_trace=False, focus_access=False):
    return {
        "simulation_seed": seed,
        "status": "ready",
        "results": [
            result(
                seed,
                wins,
                losses,
                game_results=game_results,
                squee_trace=squee_trace,
                focus_trace=focus_trace,
                focus_access=focus_access,
            )
        ],
    }


def test_primary_seed_records_prefer_diagnostic_game_results(tmp_path):
    aggregate = write_json(tmp_path / "seed7_gate.json", gate(7, 0, 3, game_results=False))
    diagnostic = write_json(tmp_path / "seed7_diag.json", gate(7, 0, 3, game_results=True))

    report = audit.build_report(
        synthesis=synthesis_payload(),
        gate_paths=[aggregate],
        diagnostic_gate_paths=[diagnostic],
    )

    seed7 = report["primary_seed_records"]["7"]
    assert seed7["trace_data_level"] == "per_game_event_counts"
    assert seed7["source"].endswith("seed7_diag.json")
    assert report["summary"]["primary_trace_level_counts"] == {"per_game_event_counts": 1}


def test_squee_trace_summary_counts_graveyard_route_without_lorehold_discard(tmp_path):
    diagnostic7 = write_json(tmp_path / "seed7_diag.json", gate(7, 0, 3, game_results=True))
    diagnostic42 = write_json(
        tmp_path / "seed42_diag.json",
        gate(42, 2, 1, game_results=True, squee_trace=True),
    )

    report = audit.build_report(
        synthesis=synthesis_payload(),
        gate_paths=[],
        diagnostic_gate_paths=[diagnostic7, diagnostic42],
    )

    seed42 = report["primary_seed_records"]["42"]
    trace = seed42["squee_trace_summary"]
    assert trace["trace_game_count"] == 1
    assert trace["matched_cards"]["Squee, Goblin Nabob"]["permanent_moved_from_battlefield"] == 1
    assert trace["lorehold_squee_discard_count"] == 0

    by_key = {row["hypothesis_key"]: row for row in report["hypothesis_assessments"]}
    assert by_key["audit_squee_graveyard_entry_route"]["trace_status"] == (
        "trace_evidence_supports_sequencing_gap"
    )


def test_urza_scope_remains_partial_without_tutor_payload(tmp_path):
    diagnostic7 = write_json(tmp_path / "seed7_diag.json", gate(7, 0, 3, game_results=True))
    diagnostic42 = write_json(tmp_path / "seed42_diag.json", gate(42, 2, 1, game_results=True))

    report = audit.build_report(
        synthesis=synthesis_payload(),
        gate_paths=[],
        diagnostic_gate_paths=[diagnostic7, diagnostic42],
    )

    by_key = {row["hypothesis_key"]: row for row in report["hypothesis_assessments"]}
    urza = by_key["audit_urzas_saga_artifact_tutor_scope"]
    assert urza["trace_status"] == "runtime_trace_partial_missing_tutor_payload"
    assert "artifact tutor target identity" in " ".join(urza["current_limitations"])


def test_urza_scope_uses_focus_trace_payload_when_available(tmp_path):
    diagnostic7 = write_json(
        tmp_path / "seed7_diag.json",
        gate(7, 0, 3, game_results=True, focus_trace=True),
    )
    diagnostic42 = write_json(
        tmp_path / "seed42_diag.json",
        gate(42, 2, 1, game_results=True, focus_trace=True),
    )

    report = audit.build_report(
        synthesis=synthesis_payload(),
        gate_paths=[],
        diagnostic_gate_paths=[diagnostic7, diagnostic42],
    )

    by_key = {row["hypothesis_key"]: row for row in report["hypothesis_assessments"]}
    urza = by_key["audit_urzas_saga_artifact_tutor_scope"]
    assert urza["trace_status"] == "runtime_trace_payload_available_review_model_scope"

    seed7 = report["primary_seed_records"]["7"]
    urza_obs = next(row for row in seed7["card_observations"] if row["card_name"] == "Urza's Saga")
    assert urza_obs["evidence_level"] == "focus_card_trace_available"
    assert "candidate_names" in urza_obs["focus_trace_payload_fields"]


def test_seed7_access_snapshot_changes_missing_payload_status(tmp_path):
    diagnostic7 = write_json(
        tmp_path / "seed7_diag.json",
        gate(7, 0, 3, game_results=True, focus_access=True),
    )
    diagnostic42 = write_json(
        tmp_path / "seed42_diag.json",
        gate(42, 2, 1, game_results=True, squee_trace=True, focus_trace=True),
    )

    report = audit.build_report(
        synthesis=synthesis_payload(),
        gate_paths=[],
        diagnostic_gate_paths=[diagnostic7, diagnostic42],
    )

    by_key = {row["hypothesis_key"]: row for row in report["hypothesis_assessments"]}
    seed7 = by_key["trace_seed7_engine_access_sequence"]
    assert seed7["trace_status"] == "focus_access_trace_available_review_sequence"
    assert "focus access seed 7" in " ".join(seed7["current_limitations"])

    seed7_record = report["primary_seed_records"]["7"]
    squee_obs = next(
        row for row in seed7_record["card_observations"]
        if row["card_name"] == "Squee, Goblin Nabob"
    )
    assert squee_obs["evidence_level"] == "focus_access_trace_available"
    assert squee_obs["focus_access"]["min_library_position"] == 18
