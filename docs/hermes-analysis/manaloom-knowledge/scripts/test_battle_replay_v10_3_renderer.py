#!/usr/bin/env python3
"""Focused tests for battle_replay_v10_3 human replay rendering."""

from __future__ import annotations

from io import StringIO

import battle_replay_v10_3 as replay_renderer


def render(event: str, data: dict) -> str:
    handle = StringIO()
    replay_renderer.write_replay_event(handle, event, data)
    return handle.getvalue()


class FakeBattleModule:
    @staticmethod
    def replay_card_snapshot(card):
        return {"name": card.get("name", "?")}

    @staticmethod
    def target_player_name_for_commander(commander):
        name = str(commander.get("name") or "")
        return "Lorehold" if name.startswith("Lorehold, the Historian") else name


class FakePlayer:
    def __init__(self, name, life, hand, alive=True):
        self.name = name
        self.life = life
        self.hand = hand
        self._alive = alive

    def is_alive(self):
        return self._alive


def test_renderer_writes_land_cost_cast_illegal_and_board_details():
    start_line = render(
        "turn_start",
        {
            "player": "Lorehold",
            "turn": 1,
            "life": 40,
            "hand": 2,
            "board": 0,
            "hand_snapshot": [
                {"name": "Ghostly Prison"},
                {"name": "Crawlspace"},
            ],
        },
    )
    land_line = render(
        "land_played",
        {
            "player": "Lorehold",
            "card": "Sunbillow Verge",
            "mana_produced": 1,
            "mana_pool_after": {"red": 1},
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    )
    cost_line = render(
        "cost_paid",
        {
            "player": "Lorehold",
            "card": "Sensei's Divining Top",
            "locked_cost": {"generic": 1, "colored": {}},
            "mana_before": 1,
            "mana_after": 0,
            "life_before": 40,
            "life_after": 40,
            "life_paid": 0,
            "mana_pool_after": {},
        },
    )
    illegal_line = render(
        "cast_illegal",
        {
            "player": "Opponent",
            "card": "Mental Misstep",
            "reason": "cannot_pay_locked_cost",
            "locked_cost": {"generic": 0, "colored": {"blue": 1}},
            "phase": "end_step",
        },
    )
    end_line = render(
        "turn_end",
        {
            "player": "Lorehold",
            "life": 40,
            "hand": 5,
            "board": 2,
            "graveyard": 0,
            "discarded": 1,
            "discarded_cards": ["Spectator Seating"],
            "hand_snapshot": [{"name": "Approach of the Second Sun"}],
            "board_snapshot": [
                {"name": "Sunbillow Verge", "effect": "land"},
                {"name": "Sensei's Divining Top", "effect": "topdeck_manipulation"},
            ],
        },
    )

    assert "HandCards=[Ghostly Prison, Crawlspace]" in start_line
    assert "PLAY LAND Lorehold: Sunbillow Verge" in land_line
    assert "PAY COST Lorehold: Sensei's Divining Top" in cost_line
    assert "mana 1->0" in cost_line
    assert "ILLEGAL CAST Opponent: Mental Misstep" in illegal_line
    assert "DiscardedCards=[Spectator Seating]" in end_line
    assert "HandCards=[Approach of the Second Sun]" in end_line
    assert "Permanents=[Sunbillow Verge, Sensei's Divining Top" in end_line


def test_renderer_differentiates_spell_ability_trigger_and_counter():
    cast_line = render(
        "spell_cast",
        {
            "player": "Lorehold",
            "card": "Scroll Rack",
            "cmc": 2,
            "effect": "topdeck_manipulation",
            "phase": "precombat_main",
            "locked_cost": {"generic": 2, "colored": {}},
            "rule_source": "curated",
            "rule_review_status": "active",
        },
    )
    activation_line = render(
        "topdeck_manipulation_activated",
        {
            "player": "Lorehold",
            "card": "Scroll Rack",
            "activation_kind": "scroll_rack_single_exchange_for_lorehold",
            "mana_paid": 1,
            "life_before": 40,
            "life_paid": 2,
            "life_after": 38,
        },
    )
    trigger_line = render(
        "trigger_resolved",
        {
            "player": "Lorehold",
            "card": "Urza's Saga",
            "activation_kind": "saga_chapter",
        },
    )
    counter_line = render(
        "spell_countered",
        {
            "player": "Responder",
            "counter": "Counterspell",
            "target": "Approach of the Second Sun",
            "stack_object": "Approach of the Second Sun",
            "result": "countered",
            "phase": "precombat_main",
            "priority_window": "stack_response",
            "cost": 2,
        },
    )

    assert cast_line.startswith("  CAST Lorehold: Scroll Rack")
    assert activation_line.startswith("  ACTIVATE Lorehold: Scroll Rack")
    assert "life=40->38 life_paid=2" in activation_line
    assert "life=?->" not in activation_line
    assert trigger_line.startswith("  RESOLVE ABILITY Lorehold: Urza's Saga")
    assert "stack_object=Approach of the Second Sun result=countered" in counter_line
    assert "phase=precombat_main priority_window=stack_response" in counter_line


def test_renderer_uses_cmc_for_special_cast_events():
    commander_line = render(
        "commander_cast",
        {
            "player": "Lorehold",
            "card": "Lorehold, the Historian",
            "cmc": 5,
            "effect": "passive",
            "phase": "precombat_main",
            "locked_cost": {"generic": 3, "colored": {"red": 1, "white": 1}},
            "rule_source": "curated",
            "rule_review_status": "active",
        },
    )
    miracle_line = render(
        "miracle_cast",
        {
            "player": "Lorehold",
            "card": "Silence",
            "cmc": 1,
            "effect": "silence_spell",
            "phase": "draw_step",
            "locked_cost": {"generic": 0, "colored": {}},
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    )
    instant_line = render(
        "end_step_instant",
        {
            "player": "Lorehold",
            "card": "Flawless Maneuver",
            "cmc": 3,
            "effect": "indestructible",
            "phase": "end_step",
            "locked_cost": {"generic": 2, "colored": {"white": 1}},
            "rule_source": "curated",
            "rule_review_status": "verified",
        },
    )

    assert "CAST COMMANDER Lorehold: Lorehold, the Historian (CMC=5)" in commander_line
    assert "CAST Lorehold: Silence (CMC=1)" in miracle_line
    assert "CAST INSTANT Lorehold: Flawless Maneuver (CMC=3)" in instant_line
    assert "CMC=?" not in commander_line + miracle_line + instant_line


def test_renderer_uses_real_trigger_put_on_stack_fields():
    trigger_line = render(
        "trigger_put_on_stack",
        {
            "player": "Lorehold",
            "card": "Lotus Cobra",
            "trigger": "landfall",
            "timestamp": 12,
        },
    )

    assert trigger_line == "  TRIGGER Lorehold: Lotus Cobra event=landfall stack=12\n"
    assert "event=?" not in trigger_line
    assert "stack=?" not in trigger_line


def test_renderer_uses_trigger_fields_for_resolved_ability_kind():
    trigger_line = render(
        "trigger_resolved",
        {
            "player": "Lorehold",
            "card": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
            "trigger": "spell_cast",
            "trigger_spell": "Jeska's Will",
            "effect": "add_mana",
        },
    )

    assert trigger_line == (
        "  RESOLVE ABILITY Lorehold: "
        "Birgi, God of Storytelling // Harnfel, Horn of Bounty "
        "kind=spell_cast trigger_spell=Jeska's Will\n"
    )
    assert "kind=?" not in trigger_line


def test_renderer_explains_noncombat_damage_life_change():
    damage_line = render(
        "damage_resolved",
        {
            "player": "Sisay, Weatherlight Captain #31 (real)",
            "card": "Thassa's Oracle",
            "target_player": "Thrasios, Triton Hero #54 (real)",
            "amount": 1,
            "result": "player_damage",
            "cause": "finisher_total_power",
            "life_before": 40,
            "life_after": 39,
        },
    )

    assert damage_line.startswith(
        "  DAMAGE Sisay, Weatherlight Captain #31 (real): Thassa's Oracle"
    )
    assert "-> Thrasios, Triton Hero #54 (real)" in damage_line
    assert "cause=finisher_total_power" in damage_line
    assert "life=40->39" in damage_line


def test_renderer_uses_card_as_damage_cause_fallback():
    damage_line = render(
        "damage_resolved",
        {
            "player": "Etali, Primal Conqueror #105 (real)",
            "card": "Lightning Bolt",
            "target_player": "Kraum, Ludevic's Opus #83 (real)",
            "target": "Memnite",
            "amount": 3,
            "result": "creature_destroyed",
        },
    )

    assert "DAMAGE Etali, Primal Conqueror #105 (real): Lightning Bolt" in damage_line
    assert "-> Kraum, Ludevic's Opus #83 (real)" in damage_line
    assert "cause=Lightning Bolt" in damage_line
    assert "cause=?" not in damage_line


def test_renderer_explains_kicked_orims_chant_attack_prevention():
    prevention_line = render(
        "attack_prevented_by_orims_chant",
        {
            "player": "Lorehold",
            "card": "Orim's Chant",
            "prevented_attacker": "Dargo",
            "prevented_attackers": 3,
            "projected_combat_damage": 12,
        },
    )

    assert prevention_line == (
        "  PREVENT ATTACK Lorehold: Orim's Chant kicked against Dargo; "
        "3 attackers stopped before declare attackers (projected_damage=12)\n"
    )


def test_deck_metrics_are_derived_from_resolved_cards():
    metrics = replay_renderer.deck_metrics(
        [
            {"name": "Mountain", "type_line": "Basic Land - Mountain", "cmc": 0},
            {"name": "Ancient Tomb", "functional_tags": ["land"], "cmc": 0},
            {"name": "Sol Ring", "type_line": "Artifact", "cmc": 1},
            {"name": "Wrath of God", "type_line": "Sorcery", "cmc": 4},
            {"name": "Ugin", "type_line": "Planeswalker", "cmc": 8},
        ]
    )

    assert metrics["card_count"] == 5
    assert metrics["lands"] == 2
    assert metrics["nonlands"] == 3
    assert metrics["avg_cmc_nonlands"] == 4.333
    assert metrics["curve"]["1"] == 1
    assert metrics["curve"]["4"] == 1
    assert metrics["curve"]["7+"] == 1
    assert metrics["curve"]["0"] == 0


def test_target_deck_id_env_defaults_validates_and_overrides():
    assert replay_renderer.target_deck_id_from_env({}) == 6
    assert replay_renderer.target_deck_id_from_env(
        {replay_renderer.TARGET_DECK_ID_ENV: "606"}
    ) == 606

    for raw in ("abc", "0", "-1"):
        try:
            replay_renderer.target_deck_id_from_env(
                {replay_renderer.TARGET_DECK_ID_ENV: raw}
            )
        except ValueError as exc:
            assert replay_renderer.TARGET_DECK_ID_ENV in str(exc)
        else:
            raise AssertionError(f"expected invalid deck id to fail: {raw}")


def test_target_player_name_uses_commander_for_non_lorehold_decks():
    assert (
        replay_renderer.target_player_name_from_battle_module(
            FakeBattleModule,
            {"name": "Kaalia of the Vast"},
        )
        == "Kaalia of the Vast"
    )
    assert (
        replay_renderer.target_player_name_from_battle_module(
            FakeBattleModule,
            {"name": "Lorehold, the Historian"},
        )
        == "Lorehold"
    )


def test_provenance_line_names_source_metrics_and_blocker_domain():
    handle = StringIO()

    replay_renderer.write_provenance_line(
        handle,
        {
            "name": "Lorehold",
            "source_kind": "sqlite_deck_cards",
            "metrics_basis": "runtime_derived_from_resolved_card_list",
            "metrics": {
                "card_count": 100,
                "lands": 33,
                "avg_cmc_nonlands": 3.0,
                "curve": {"0": 0, "1": 9, "2": 16, "3": 14, "4": 10, "5": 7, "6": 5, "7+": 6},
            },
            "blocker_domain": "deck_source",
        },
    )

    line = handle.getvalue()
    assert "Lorehold: source=sqlite_deck_cards" in line
    assert "metrics=runtime_derived_from_resolved_card_list" in line
    assert "cards=100 lands=33 avg_nonland_cmc=3.00" in line
    assert "blockers=deck_source" in line


def test_final_player_summary_includes_hand_card_names():
    handle = StringIO()
    player = FakePlayer(
        "Lorehold",
        3,
        [{"name": "Teferi's Protection"}, {"name": "Boros Charm"}],
        alive=False,
    )

    replay_renderer.write_final_player_summary(handle, player, FakeBattleModule)

    assert handle.getvalue() == (
        "Lorehold: DEAD Life=3 Hand=2 "
        "HandCards=[Teferi's Protection, Boros Charm]\n"
    )


if __name__ == "__main__":
    tests = [
        test_renderer_writes_land_cost_cast_illegal_and_board_details,
        test_renderer_differentiates_spell_ability_trigger_and_counter,
        test_renderer_uses_cmc_for_special_cast_events,
        test_renderer_uses_real_trigger_put_on_stack_fields,
        test_renderer_uses_trigger_fields_for_resolved_ability_kind,
        test_renderer_explains_noncombat_damage_life_change,
        test_renderer_uses_card_as_damage_cause_fallback,
        test_renderer_explains_kicked_orims_chant_attack_prevention,
        test_deck_metrics_are_derived_from_resolved_cards,
        test_target_deck_id_env_defaults_validates_and_overrides,
        test_target_player_name_uses_commander_for_non_lorehold_decks,
        test_provenance_line_names_source_metrics_and_blocker_domain,
        test_final_player_summary_includes_hand_card_names,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
