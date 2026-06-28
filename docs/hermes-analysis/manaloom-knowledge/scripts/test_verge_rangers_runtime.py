#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_verge_rangers_under_test", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def land(name: str) -> dict:
    return {"name": name, "effect": "land", "type_line": "Basic Land"}


def test_verge_rangers_runtime_rule_grants_top_library_land_play() -> None:
    battle = load_battle()
    effect = battle.get_card_effect(
        {
            "name": "Verge Rangers",
            "cmc": 3,
            "type_line": "Creature - Human Scout Ranger",
        }
    )

    assert effect["effect"] == "topdeck_play"
    assert effect["battle_model_scope"] == battle.TOPDECK_LAND_PLAY_SCOPE
    assert effect["play_lands_from_top_library"] is True
    assert effect["play_from_top_condition"] == "opponent_controls_more_lands"
    assert effect["_rule_logical_key"] == "battle_rule_v1:c795721c1dc42d0f9ee3fa23349500e1"
    assert effect["_rule_oracle_hash"] == "44aa2eeb2eeb517fb30478aec7cec42f"
    assert effect["_rule_review_status"] == "verified"
    assert effect["_rule_execution_status"] == "auto"
    waiver = next(
        row
        for row in battle.manual_runtime_waiver_inventory()
        if row["card"] == "Verge Rangers"
    )
    assert waiver["effect"] == "topdeck_play"
    assert waiver["rule_logical_key"] == "battle_rule_v1:c795721c1dc42d0f9ee3fa23349500e1"
    assert waiver["source_runs"] == [
        "manaloom_log_learning_audit_20260628_v5",
        "VergeRangers.java",
    ]
    assert waiver["opened_at_utc"] == "2026-06-28T18:40:00Z"
    assert waiver["expires_at_utc"] == "2026-07-05T23:59:59Z"


def test_verge_rangers_plays_top_land_only_when_opponent_has_more_lands() -> None:
    battle = load_battle()
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Lorehold", None, [])
        opponent = battle.Player("Opponent", None, [])
        active.battlefield = [
            {
                "name": "Verge Rangers",
                "cmc": 3,
                "type_line": "Creature - Human Scout Ranger",
                **battle.get_card_effect({"name": "Verge Rangers", "cmc": 3}),
            },
            land("Plains"),
            land("Mountain"),
        ]
        opponent.battlefield = [land("Island"), land("Swamp"), land("Forest")]
        active.library = [land("Sacred Foundry")]
        active.hand = []

        candidate = battle.choose_land_play_candidate(active, [opponent])
        assert candidate is not None
        assert candidate["source_zone"] == "library"
        assert candidate["card"]["name"] == "Sacred Foundry"

        played = battle.play_land_candidate(
            active,
            [opponent],
            [active, opponent],
            turn=4,
            stack=battle.Stack(),
            candidate=candidate,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert played is True
    assert active.library == []
    assert any(card.get("name") == "Sacred Foundry" for card in active.battlefield)
    assert any(
        event == "land_played"
        and data.get("card") == "Sacred Foundry"
        and data.get("source_zone") == "library"
        and data.get("played_from_top_library") is True
        and data.get("topdeck_play_source") == "Verge Rangers"
        and data.get("topdeck_play_scope") == battle.TOPDECK_LAND_PLAY_SCOPE
        for event, data in events
    )


def test_verge_rangers_does_not_play_top_land_when_not_behind_on_lands() -> None:
    battle = load_battle()
    active = battle.Player("Lorehold", None, [])
    opponent = battle.Player("Opponent", None, [])
    active.battlefield = [
        {
            "name": "Verge Rangers",
            "cmc": 3,
            "type_line": "Creature - Human Scout Ranger",
            **battle.get_card_effect({"name": "Verge Rangers", "cmc": 3}),
        },
        land("Plains"),
        land("Mountain"),
    ]
    opponent.battlefield = [land("Island"), land("Swamp")]
    active.library = [land("Sacred Foundry")]
    active.hand = []

    assert battle.choose_land_play_candidate(active, [opponent]) is None
