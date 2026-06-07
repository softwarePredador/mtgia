#!/usr/bin/env python3
"""Focused regression checks for the v10.3 battle/replay fixes.

Run from this directory with:
    python3 test_battle_analyst_v10_3.py
"""

import importlib.util
import json
import os
import random
import sqlite3
from pathlib import Path


MODULE_PATH = Path(
    os.environ.get(
        "BATTLE_ANALYST_PATH",
        Path(__file__).with_name("battle_analyst_v8.py"),
    )
)
spec = importlib.util.spec_from_file_location("battle_under_test", MODULE_PATH)
battle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(battle)


def card(name, cmc=99, effect="unknown", power=0):
    return {
        "name": name,
        "cmc": cmc,
        "tag": effect,
        "effect": effect,
        "type_line": "Creature" if effect == "creature" else "Sorcery",
        "power": power,
    }


def player(name, deck=None):
    return battle.Player(name, None, deck or [], strategy="midrange")


def test_sba_only_reports_new_elimination():
    dead = player("Dead")
    alive = player("Alive", [card("Library card")])
    dead.life = 0

    assert battle.check_sbas([alive, dead]) is True
    assert dead.eliminated is True
    assert battle.check_sbas([alive, dead]) is False


def test_cleanup_runs_with_previously_eliminated_player():
    active = player("Active", [card("Draw") for _ in range(5)])
    active.hand = [card(f"Expensive {index}") for index in range(10)]
    dead = player("Dead")
    dead.life = 0
    dead.eliminated = True

    battle.play_turn_v8(
        active,
        [dead],
        [active, dead],
        turn=3,
        rng=random.Random(1),
        stack=battle.Stack(),
    )

    assert len(active.hand) == 7


def test_draw_step_runs_once_with_multiple_permanents():
    active = player("Active", [card("Draw") for _ in range(5)])
    active.battlefield = [
        {"name": "Permanent A", "effect": "unknown"},
        {"name": "Permanent B", "effect": "unknown"},
    ]
    opponent = player("Opponent", [card("Opp Draw") for _ in range(5)])

    battle.play_turn_v8(
        active,
        [opponent],
        [active, opponent],
        turn=1,
        rng=random.Random(2),
        stack=battle.Stack(),
    )

    assert len(active.hand) == 1


def test_approach_sets_explicit_win_state():
    active = player("Active")
    opponent = player("Opponent")
    approach = {
        "name": "Approach of the Second Sun",
        "cmc": 7,
        "type_line": "Sorcery",
    }

    battle.apply_effect_immediate(active, [opponent], approach, 5, random.Random(3))
    assert active.has_won() is False
    battle.apply_effect_immediate(active, [opponent], approach, 6, random.Random(3))

    assert active.has_won() is True
    assert active.win_reason == "approach"


def test_combat_emits_structured_event():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    defender = player("Defender")
    attacker.battlefield = [
        {
            "name": "Attacker Creature",
            "effect": "creature",
            "power": 3,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=2,
        rng=random.Random(4),
        stack=battle.Stack(),
    )

    combat_events = [data for event, data in events if event == "combat"]
    assert len(combat_events) == 1
    assert combat_events[0]["attacker"] == "Attacker"
    assert combat_events[0]["target"] == "Defender"
    assert combat_events[0]["attackers"] == 1


def test_turn_stops_immediately_after_approach_win():
    active = player("Active", [card("Library card") for _ in range(10)])
    opponent = player("Opponent", [card("Opp Library") for _ in range(10)])
    active.approach_count = 1
    active.hand = [
        {
            "name": "Approach of the Second Sun",
            "cmc": 7,
            "type_line": "Sorcery",
        },
        {
            "name": "Must Stay In Hand",
            "cmc": 1,
            "tag": "draw",
            "type_line": "Sorcery",
        },
    ]
    active.battlefield = ["land" for _ in range(10)]

    battle.play_turn_v8(
        active,
        [opponent],
        [active, opponent],
        turn=5,
        rng=random.Random(5),
        stack=battle.Stack(),
    )

    assert active.has_won() is True
    assert any(card["name"] == "Must Stay In Hand" for card in active.hand)


def test_mana_sources_do_not_refill_after_spending():
    active = player("Active")
    active.battlefield = ["land", "land", "land"]
    active.refresh_mana_sources(turn=1)

    assert active.available_mana() == 3
    assert active.spend_mana(3) is True
    assert active.available_mana() == 0
    assert active.available_mana() == 0


def test_treasures_are_spent_without_refilling_sources():
    active = player("Active")
    active.battlefield = ["land"]
    active.treasures = 2
    active.refresh_mana_sources(turn=1)

    assert active.available_mana() == 3
    assert active.spend_mana(2) is True
    assert active.available_mana() == 1
    assert active.treasures == 1


def test_counterspell_consumes_card_mana_and_counters_target():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    active = player("Active")
    responder = player("Responder")
    responder.hand = [
        {
            "name": "Real Counter",
            "cmc": 2,
            "tag": "counter",
            "effect": "counter",
            "type_line": "Instant",
        }
    ]
    responder.battlefield = ["land", "land"]
    responder.refresh_mana_sources(turn=2)
    spell = {
        "name": "Approach of the Second Sun",
        "cmc": 7,
        "type_line": "Sorcery",
    }
    stack = battle.Stack()
    stack.push(spell, active, battle.get_card_effect(spell))

    assert battle.priority_round(active, [active, responder], stack, 2, random.Random(6)) is True
    assert stack.items[-1].countered is True
    assert responder.available_mana() == 0
    assert responder.hand == []
    assert responder.graveyard[0]["name"] == "Real Counter"
    assert any(event == "spell_countered" for event, _ in events)

    battle.priority_round(active, [active, responder], stack, 2, random.Random(6))
    assert stack.empty()
    assert active.graveyard[0]["name"] == "Approach of the Second Sun"


def test_only_attacked_player_can_block():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    non_target = player("Non Target")
    target = player("Target")
    non_target.life = 40
    target.life = 39
    attacker.battlefield = [
        {
            "name": "Attacker Creature",
            "effect": "creature",
            "power": 2,
            "toughness": 2,
            "summoning_sick": False,
            "tapped": False,
        }
    ]
    non_target.battlefield = [
        {"name": "Wrong Blocker", "effect": "creature", "power": 3, "toughness": 3}
    ]
    target.battlefield = [
        {"name": "Right Blocker", "effect": "creature", "power": 3, "toughness": 3}
    ]

    battle.combat_phase_v8(
        attacker,
        [non_target, target],
        [attacker, non_target, target],
        turn=2,
        rng=random.Random(1),
        stack=battle.Stack(),
    )

    combat = next(data for event, data in events if event == "combat")
    assert combat["target"] == "Target"
    assert combat["blockers"] == 1
    assert non_target.battlefield[0]["name"] == "Wrong Blocker"
    assert attacker.battlefield == []


def test_combat_prioritizes_visible_lethal():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    lethal = player("Lethal")
    healthy = player("Healthy")
    lethal.life = 4
    healthy.life = 40
    attacker.battlefield = [
        {
            "name": "Five Power",
            "effect": "creature",
            "power": 5,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [healthy, lethal],
        [attacker, healthy, lethal],
        turn=2,
        rng=random.Random(7),
        stack=battle.Stack(),
    )

    combat = next(data for event, data in events if event == "combat")
    assert combat["target"] == "Lethal"
    assert lethal.life == -1
    assert healthy.life == 40


def test_combat_focuses_known_approach_caster():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    approach = player("Approach Caster")
    other = player("Other")
    attacker.approach_revealed.append(approach.name)
    attacker.battlefield = [
        {
            "name": "Attacker Creature",
            "effect": "creature",
            "power": 3,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [other, approach],
        [attacker, other, approach],
        turn=2,
        rng=random.Random(8),
        stack=battle.Stack(),
    )

    combat = next(data for event, data in events if event == "combat")
    assert combat["target"] == "Approach Caster"


def test_first_strike_does_not_deal_regular_damage_twice():
    attacker = player("Attacker")
    defender = player("Defender")
    attacker.battlefield = [
        {
            "name": "First Striker",
            "effect": "creature",
            "power": 3,
            "first_strike": True,
            "summoning_sick": False,
            "tapped": False,
        }
    ]

    battle.combat_phase_v8(
        attacker,
        [defender],
        [attacker, defender],
        turn=2,
        rng=random.Random(9),
        stack=battle.Stack(),
    )

    assert defender.life == 37


def test_player_does_not_counter_own_spell():
    active = player("Active")
    active.hand = [
        {
            "name": "Own Counter",
            "cmc": 2,
            "tag": "counter",
            "effect": "counter",
            "type_line": "Instant",
        }
    ]
    active.battlefield = ["land", "land"]
    active.refresh_mana_sources(turn=2)
    spell = {
        "name": "Approach of the Second Sun",
        "cmc": 7,
        "type_line": "Sorcery",
    }
    stack = battle.Stack()
    stack.push(spell, active, battle.get_card_effect(spell))

    battle.priority_round(active, [active], stack, 2, random.Random(10))

    assert stack.empty()
    assert active.approach_count == 1
    assert active.hand[0]["name"] == "Own Counter"
    assert active.available_mana() == 2


def test_colored_mana_requires_the_correct_color():
    active = player("Active")
    active.mana_pool.add("white", 1)
    active.mana_pool.add_generic(2)
    white_spell = {"name": "White Spell", "cmc": 2, "mana_cost": "{1}{W}"}
    blue_spell = {"name": "Blue Spell", "cmc": 2, "mana_cost": "{1}{U}"}

    assert active.can_pay_card(white_spell) is True
    assert active.can_pay_card(blue_spell) is False
    assert active.spend_card_mana(white_spell) is True
    assert active.available_mana() == 1


def test_treasure_and_flexible_sources_pay_colored_costs():
    active = player("Active")
    active.mana_pool.add("wildcard", 1)
    active.treasures = 1
    spell = {"name": "Dimir Spell", "cmc": 2, "mana_cost": "{U}{B}"}

    assert active.can_pay_card(spell) is True
    assert active.spend_card_mana(spell) is True
    assert active.available_mana() == 0
    assert active.treasures == 0


def test_basic_lands_refresh_as_colored_sources():
    active = player("Active")
    active.battlefield = [
        {"name": "Plains", "effect": "land"},
        {"name": "Island", "effect": "land"},
    ]
    active.refresh_mana_sources(turn=1)

    assert active.mana_pool.white == 1
    assert active.mana_pool.blue == 1
    assert active.can_pay_card({"name": "Azorius", "cmc": 2, "mana_cost": "{W}{U}"})


def test_multiple_blockers_can_gang_block():
    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    attacker = player("Attacker")
    defender = player("Defender")
    defender.life = 5
    attacker.battlefield = [{
        "name": "Large Attacker",
        "effect": "creature",
        "power": 6,
        "toughness": 6,
        "summoning_sick": False,
        "tapped": False,
    }]
    defender.battlefield = [
        {"name": "Blocker A", "effect": "creature", "power": 3, "toughness": 3},
        {"name": "Blocker B", "effect": "creature", "power": 3, "toughness": 3},
    ]

    battle.combat_phase_v8(
        attacker, [defender], [attacker, defender], 2, random.Random(11), battle.Stack()
    )

    combat = next(data for event, data in events if event == "combat")
    assert combat["blockers"] == 2
    assert combat["multi_blocks"] == 1
    assert attacker.battlefield == []
    assert defender.battlefield == []
    assert defender.life == 5


def test_trample_assigns_excess_damage_to_defender():
    attacker = player("Attacker")
    defender = player("Defender")
    defender.life = 5
    attacker.battlefield = [{
        "name": "Trampler",
        "effect": "creature",
        "power": 7,
        "toughness": 7,
        "trample": True,
        "summoning_sick": False,
        "tapped": False,
    }]
    defender.battlefield = [
        {"name": "Small Blocker", "effect": "creature", "power": 2, "toughness": 2}
    ]

    battle.combat_phase_v8(
        attacker, [defender], [attacker, defender], 2, random.Random(12), battle.Stack()
    )

    assert defender.life == 0
    assert defender.battlefield == []
    assert attacker.battlefield[0]["name"] == "Trampler"


def test_deathtouch_assigns_one_lethal_damage_per_blocker():
    attacker = player("Attacker")
    defender = player("Defender")
    defender.life = 2
    attacker.battlefield = [{
        "name": "Deathtouch Attacker",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "deathtouch": True,
        "summoning_sick": False,
        "tapped": False,
    }]
    defender.battlefield = [
        {"name": "Blocker A", "effect": "creature", "power": 1, "toughness": 8},
        {"name": "Blocker B", "effect": "creature", "power": 1, "toughness": 8},
    ]

    battle.combat_phase_v8(
        attacker, [defender], [attacker, defender], 2, random.Random(13), battle.Stack()
    )

    assert defender.battlefield == []
    assert attacker.battlefield == []
    assert defender.life == 2


def test_first_strike_blocker_kills_before_regular_damage():
    attacker = player("Attacker")
    defender = player("Defender")
    defender.life = 3
    attacker.battlefield = [{
        "name": "Regular Attacker",
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "summoning_sick": False,
        "tapped": False,
    }]
    defender.battlefield = [{
        "name": "First Strike Blocker",
        "effect": "creature",
        "power": 3,
        "toughness": 3,
        "first_strike": True,
    }]

    battle.combat_phase_v8(
        attacker, [defender], [attacker, defender], 2, random.Random(14), battle.Stack()
    )

    assert attacker.battlefield == []
    assert defender.battlefield[0]["name"] == "First Strike Blocker"
    assert defender.life == 3


def test_indestructible_blocker_survives_lethal_combat_damage():
    attacker = player("Attacker")
    defender = player("Defender")
    defender.life = 5
    attacker.battlefield = [{
        "name": "Large Attacker",
        "effect": "creature",
        "power": 5,
        "toughness": 5,
        "summoning_sick": False,
        "tapped": False,
    }]
    defender.battlefield = [{
        "name": "Indestructible Blocker",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "indestructible": True,
    }]

    battle.combat_phase_v8(
        attacker, [defender], [attacker, defender], 2, random.Random(15), battle.Stack()
    )

    assert defender.battlefield[0]["name"] == "Indestructible Blocker"
    assert defender.life == 5


def test_double_strike_trample_deals_excess_in_both_steps():
    attacker = player("Attacker")
    defender = player("Defender")
    defender.life = 4
    attacker.battlefield = [{
        "name": "Double Strike Trampler",
        "effect": "creature",
        "power": 4,
        "toughness": 4,
        "double_strike": True,
        "trample": True,
        "summoning_sick": False,
        "tapped": False,
    }]
    defender.battlefield = [{
        "name": "Small Blocker",
        "effect": "creature",
        "power": 1,
        "toughness": 2,
    }]

    battle.combat_phase_v8(
        attacker, [defender], [attacker, defender], 2, random.Random(16), battle.Stack()
    )

    assert defender.battlefield == []
    assert defender.life == -2


def test_card_oracle_cache_enriches_battle_cards():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            mana_cost TEXT,
            colors_json TEXT,
            color_identity_json TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            power TEXT,
            toughness TEXT,
            keywords_json TEXT,
            scryfall_id TEXT
        )
        """
    )
    conn.execute(
        """
        INSERT INTO card_oracle_cache (
            normalized_name, name, mana_cost, colors_json, color_identity_json,
            type_line, oracle_text, cmc, power, toughness, keywords_json, scryfall_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            "test trampler",
            "Test Trampler",
            "{3}{G}",
            json.dumps(["G"]),
            json.dumps(["G"]),
            "Creature - Beast",
            "Trample",
            4,
            "4",
            "4",
            json.dumps(["trample"]),
            "00000000-0000-0000-0000-000000000000",
        ),
    )

    cache = battle.load_card_oracle_cache(conn, ["Test Trampler"])
    enriched = battle.enrich_card(
        battle.merge_oracle_metadata(
            {"name": "Test Trampler", "cmc": 0, "tag": "creature"},
            cache,
        )
    )

    assert enriched["mana_cost"] == "{3}{G}"
    assert enriched["cmc"] == 4
    assert enriched["power"] == 4
    assert enriched["toughness"] == 4
    assert enriched["trample"] is True
    conn.close()


if __name__ == "__main__":
    tests = [
        test_sba_only_reports_new_elimination,
        test_cleanup_runs_with_previously_eliminated_player,
        test_draw_step_runs_once_with_multiple_permanents,
        test_approach_sets_explicit_win_state,
        test_combat_emits_structured_event,
        test_turn_stops_immediately_after_approach_win,
        test_mana_sources_do_not_refill_after_spending,
        test_treasures_are_spent_without_refilling_sources,
        test_counterspell_consumes_card_mana_and_counters_target,
        test_only_attacked_player_can_block,
        test_combat_prioritizes_visible_lethal,
        test_combat_focuses_known_approach_caster,
        test_first_strike_does_not_deal_regular_damage_twice,
        test_player_does_not_counter_own_spell,
        test_colored_mana_requires_the_correct_color,
        test_treasure_and_flexible_sources_pay_colored_costs,
        test_basic_lands_refresh_as_colored_sources,
        test_multiple_blockers_can_gang_block,
        test_trample_assigns_excess_damage_to_defender,
        test_deathtouch_assigns_one_lethal_damage_per_blocker,
        test_first_strike_blocker_kills_before_regular_damage,
        test_indestructible_blocker_survives_lethal_combat_damage,
        test_double_strike_trample_deals_excess_in_both_steps,
        test_card_oracle_cache_enriches_battle_cards,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
