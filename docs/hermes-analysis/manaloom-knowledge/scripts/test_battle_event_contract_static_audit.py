#!/usr/bin/env python3
"""Tests for static battle event contract audit."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

import battle_event_contract_static_audit as audit_module


def write_engine(path: Path, event_names: list[str]) -> None:
    calls = "\n".join(
        f'emit_replay_event("{event_name}", turn=1)'
        for event_name in event_names
    )
    path.write_text(
        "def emit_replay_event(*args, **kwargs):\n    return args, kwargs\n" + calls + "\n",
        encoding="utf-8",
    )


def write_events(path: Path, events: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(json.dumps(event) for event in events) + "\n",
        encoding="utf-8",
    )


def test_known_static_and_observed_events_are_classified():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(
            engine,
            [
                "activated_ability",
                "adventure_cast",
                "draw_equal_to_discarded_hand_resolved",
                "etb_tutor_resolved",
                "copy_spell_no_stack_target",
                "damage_wipe_treasure_resolved",
                "life_totals_redistributed",
                "worldfire_resolved",
                "land_tax_trigger_resolved",
                "graveyard_flashback_granted",
                "mizzix_mastery_resolved",
                "spell_copy_ceased_to_exist",
                "end_step_token_death_draw_resolved",
            ],
        )
        write_events(
            tmp / "seed_1/replay.events.jsonl",
            [
                {"event": "activated_ability", "turn": 1, "player": "A"},
                {"event": "adventure_cast", "turn": 2, "player": "A"},
                {"event": "draw_equal_to_discarded_hand_resolved", "turn": 3, "player": "A"},
                {"event": "etb_tutor_resolved", "turn": 3, "player": "A"},
                {"event": "copy_spell_no_stack_target", "turn": 3, "player": "A"},
                {"event": "damage_wipe_treasure_resolved", "turn": 3, "player": "A"},
                {"event": "life_totals_redistributed", "turn": 3, "player": "A"},
                {"event": "worldfire_resolved", "turn": 3, "player": "A"},
                {"event": "land_tax_trigger_resolved", "turn": 4, "player": "A"},
                {"event": "graveyard_flashback_granted", "turn": 4, "player": "A"},
                {"event": "mizzix_mastery_resolved", "turn": 4, "player": "A"},
                {"event": "spell_copy_ceased_to_exist", "turn": 4, "player": "A"},
                {"event": "end_step_token_death_draw_resolved", "player": "A"},
            ],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["status"] == "event_contract_static_ready"
    assert summary["static_unclassified_total"] == 0
    assert summary["observed_unclassified_total"] == 0
    assert summary["observed_missing_required_fields"] == 0


def test_support_module_engine_sources_are_inventoried():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        support = tmp / "support.py"
        write_engine(engine, ["activated_ability"])
        support.write_text(
            "def emit_via_callback(emitter):\n"
            "    emitter(\"replacement_applied\", turn=1)\n",
            encoding="utf-8",
        )
        write_events(
            tmp / "seed_1/replay.events.jsonl",
            [
                {"event": "activated_ability", "turn": 1, "player": "A"},
                {
                    "event": "replacement_applied",
                    "turn": 1,
                    "player": "A",
                    "replacement": "life_total_cant_change",
                },
            ],
        )

        audit = audit_module.build_audit(
            input_dir=tmp,
            engine_source=[engine, support],
        )
        summary = audit["summary"]
        replacement_row = next(
            item for item in audit["items"] if item["event"] == "replacement_applied"
        )

    assert summary["status"] == "event_contract_static_ready"
    assert summary["observed_not_static_literal"] == []
    assert str(support) in summary["static_engine_sources"]
    assert replacement_row["static"] is True
    assert replacement_row["emitters"][0]["path"] == str(support)


def test_known_static_unobserved_events_get_accepted_fixture_waiver():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(engine, ["adventure_cast", "worldfire_resolved"])
        write_events(tmp / "seed_1/replay.events.jsonl", [])

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["status"] == "event_contract_static_ready"
    assert summary["static_contract_waiver_until_forced_fixture"] == 0
    assert summary["static_fixture_accepted_waiver_total"] == 2
    assert summary["fixture_or_waiver_counts"] == {
        "static_contract_accepted_waiver": 2
    }
    assert summary["static_fixture_unaccepted_types"] == []
    assert summary["static_fixture_accepted_waiver_reasons"] == {
        "accepted_strategy_context_signal_static_contract": 2
    }


def test_new_static_event_without_contract_is_reported():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(engine, ["future_static_event"])
        write_events(
            tmp / "seed_1/replay.events.jsonl",
            [{"event": "future_static_event", "turn": 1}],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["status"] == "review_required"
    assert summary["static_unclassified_total"] == 1
    assert summary["observed_unclassified_total"] == 1
    assert summary["static_unclassified_types"] == ["future_static_event"]
    assert summary["static_contract_waiver_until_forced_fixture"] == 1
    assert summary["static_fixture_accepted_waiver_total"] == 0
    assert summary["static_fixture_unaccepted_types"] == ["future_static_event"]


def test_observed_strategy_signal_missing_turn_is_reported():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(engine, ["utility_artifact_activated"])
        write_events(
            tmp / "seed_1/replay.events.jsonl",
            [{"event": "utility_artifact_activated", "player": "A"}],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["status"] == "review_required"
    assert summary["static_unclassified_total"] == 0
    assert summary["observed_missing_required_fields"] == 1
    assert audit["field_findings"][0]["missing"] == ["turn"]


def test_spell_resolved_has_event_specific_resolution_contract():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(engine, ["spell_resolved"])
        write_events(
            tmp / "seed_1/replay.events.jsonl",
            [
                {
                    "event": "spell_resolved",
                    "turn": 3,
                    "phase": "precombat_main",
                    "priority_window": "stack_resolution",
                    "player": "Caster",
                    "card": "Divination",
                    "stack_object": "Divination",
                    "stack_depth": 1,
                    "source_zone": "hand",
                    "from_zone": "hand",
                    "to_zone": "graveyard",
                    "destination": "graveyard",
                    "zone_after": "graveyard",
                    "resolved_from_stack": True,
                    "result": "resolved",
                    "cast_pipeline": "601.2_minimal",
                },
            ],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]
        spell_resolved = next(
            item for item in audit["items"] if item["event"] == "spell_resolved"
        )

    assert summary["status"] == "review_required"
    assert summary["observed_missing_required_fields"] == 1
    assert audit["field_findings"][0]["event"] == "spell_resolved"
    assert audit["field_findings"][0]["missing"] == ["locked_cost"]
    assert set(spell_resolved["minimum_fields"]) == {
        "event",
        "turn",
        "phase",
        "priority_window",
        "stack_object",
        "stack_depth",
        "source_zone",
        "from_zone",
        "to_zone",
        "destination",
        "zone_after",
        "resolved_from_stack",
        "result",
        "cast_pipeline",
        "locked_cost",
    }


def test_complete_spell_resolved_resolution_contract_is_ready():
    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        engine = tmp / "engine.py"
        write_engine(engine, ["spell_resolved"])
        write_events(
            tmp / "seed_1/replay.events.jsonl",
            [
                {
                    "event": "spell_resolved",
                    "turn": 3,
                    "phase": "precombat_main",
                    "priority_window": "stack_resolution",
                    "player": "Caster",
                    "card": "Divination",
                    "stack_object": "Divination",
                    "stack_depth": 1,
                    "source_zone": "hand",
                    "from_zone": "hand",
                    "to_zone": "graveyard",
                    "destination": "graveyard",
                    "zone_after": "graveyard",
                    "resolved_from_stack": True,
                    "result": "resolved",
                    "cast_pipeline": "601.2_minimal",
                    "locked_cost": "2U",
                },
            ],
        )

        audit = audit_module.build_audit(input_dir=tmp, engine_source=engine)
        summary = audit["summary"]

    assert summary["status"] == "event_contract_static_ready"
    assert summary["observed_missing_required_fields"] == 0


if __name__ == "__main__":
    tests = [
        test_known_static_and_observed_events_are_classified,
        test_support_module_engine_sources_are_inventoried,
        test_known_static_unobserved_events_get_accepted_fixture_waiver,
        test_new_static_event_without_contract_is_reported,
        test_observed_strategy_signal_missing_turn_is_reported,
        test_spell_resolved_has_event_specific_resolution_contract,
        test_complete_spell_resolved_resolution_contract_is_ready,
    ]
    for test in tests:
        test()
    print(f"{len(tests)} tests passed")
