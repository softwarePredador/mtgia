import json
import random
from pathlib import Path

import battle_analyst_v9 as battle


def test_brass_bounty_creates_treasures_equal_to_controlled_lands():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active = battle.Player("Active", commander=None, deck=[])
        active.battlefield = [
            {"name": "Plains", "effect": "land", "type_line": "Basic Land - Plains"},
            {"name": "Mountain", "effect": "land", "type_line": "Basic Land - Mountain"},
            {"name": "Ancient Tomb", "effect": "land", "type_line": "Land"},
            {"name": "Boros Signet", "effect": "ramp_permanent", "type_line": "Artifact"},
        ]
        card = {"name": "Brass's Bounty", "cmc": 7, "type_line": "Sorcery"}
        reviewed = json.loads(
            Path(__file__).with_name("reviewed_battle_card_rules.json").read_text(
                encoding="utf-8"
            )
        )["Brass's Bounty"]
        effect_data = dict(reviewed["effect_json"])
        effect_data.update(
            {
                "_rule_logical_key": reviewed["logical_rule_key"],
                "_rule_oracle_hash": reviewed["oracle_hash"],
                "_rule_review_status": reviewed["review_status"],
                "_rule_execution_status": reviewed["execution_status"],
            }
        )

        assert effect_data["effect"] == "treasure_maker"
        assert effect_data["treasure_count_from_lands_controlled"] is True
        assert effect_data["battle_model_scope"] == "lands_controlled_treasure_count_v1"

        battle.apply_effect_immediate(
            active,
            [],
            card,
            7,
            random.Random(1167),
            effect_data_override=effect_data,
        )
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler

    assert active.treasures == 3
    treasure_event = next(
        data
        for event, data in events
        if event == "treasure_created" and data.get("card") == "Brass's Bounty"
    )
    assert treasure_event["treasures_created"] == 3
    assert treasure_event["rule_logical_key"] == "battle_rule_v1:da9de027d7238a22376c00db758f8f85"
