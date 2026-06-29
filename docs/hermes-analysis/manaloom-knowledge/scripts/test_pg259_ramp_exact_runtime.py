#!/usr/bin/env python3
"""Focused runtime tests for PG259 exact ramp-family promotions."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import xmage_semantic_family_classifier as classifier
import xmage_to_manaloom_effect_hints as hints


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_pg259_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def card(name, type_line, **extra):
    return {"name": name, "type_line": type_line, **extra}


def primary_from_index(index_entry, oracle_text=""):
    return hints.build_effect_hints(index_entry, oracle_text)["primary_candidate"]["effect_json"]


def family_lane(card_name, effect_json, types, effects, abilities, costs=None):
    report = classifier.build_family_report(
        {
            "cards": [
                {
                    "card_name": card_name,
                    "severity": "medium",
                    "oracle_hash": "hash",
                    "status": "ready_for_structured_xmage_pull_review_required",
                    "ready_for_structured_pull": True,
                    "valid_xmage_source": True,
                    "coherence_findings": ["trusted_rule_without_oracle_hash"],
                    "checks": {"focused_test_scenario_count": 1},
                    "xmage": {
                        "class_name": card_name.replace(" ", ""),
                        "path": f"/xmage/{card_name}.java",
                        "types": sorted(types),
                        "effect_classes": sorted(effects),
                        "ability_classes": sorted(abilities),
                        "cost_classes": sorted(costs or []),
                        "primary_effect": effect_json,
                    },
                }
            ]
        }
    )
    return report["cards"][0]["promotion_lane"]


def test_mapper_and_classifier_mark_exact_ramp_scopes_batch_safe():
    cases = [
        (
            "Devoted Druid",
            {
                "xmage_class_name": "DevotedDruid",
                "effect_classes": ["UntapSourceEffect"],
                "ability_classes": ["GreenManaAbility", "SimpleActivatedAbility"],
                "cost_classes": ["PutCountersSourceCost"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            {"CREATURE"},
            {"UntapSourceEffect"},
            {"GreenManaAbility", "SimpleActivatedAbility"},
            {"PutCountersSourceCost"},
            "green_mana_dork_minus_counter_self_untap_v1",
        ),
        (
            "Delighted Halfling",
            {
                "xmage_class_name": "DelightedHalfling",
                "effect_classes": ["DelightedHalflingCantCounterEffect"],
                "ability_classes": [
                    "ColorlessManaAbility",
                    "ConditionalAnyColorManaAbility",
                    "SimpleStaticAbility",
                    "SpellAbility",
                ],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            {"CREATURE"},
            {"DelightedHalflingCantCounterEffect"},
            {"ColorlessManaAbility", "ConditionalAnyColorManaAbility", "SimpleStaticAbility", "SpellAbility"},
            set(),
            "colorless_or_legendary_any_color_uncounterable_mana_dork_v1",
        ),
        (
            "Incubation Druid",
            {
                "xmage_class_name": "IncubationDruid",
                "effect_classes": ["AnyColorLandsProduceManaEffect", "ManaEffect"],
                "ability_classes": ["AdaptAbility", "SimpleManaAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            {"CREATURE"},
            {"AnyColorLandsProduceManaEffect", "ManaEffect"},
            {"AdaptAbility", "SimpleManaAbility"},
            set(),
            "land_type_mana_dork_plus_counter_triples_adapt_v1",
        ),
        (
            "Selvala, Heart of the Wilds",
            {
                "xmage_class_name": "SelvalaHeartOfTheWilds",
                "effect_classes": ["AddManaInAnyCombinationEffect", "ManaEffect", "OneShotEffect", "SelvalaHeartOfTheWildsEffect"],
                "ability_classes": ["EntersBattlefieldAllTriggeredAbility", "SimpleManaAbility"],
                "constructor_metadata": {"card_types": ["CREATURE"]},
            },
            {"CREATURE"},
            {"AddManaInAnyCombinationEffect", "ManaEffect", "OneShotEffect", "SelvalaHeartOfTheWildsEffect"},
            {"EntersBattlefieldAllTriggeredAbility", "SimpleManaAbility"},
            set(),
            "greatest_power_any_color_mana_dork_etb_draw_annotation_v1",
        ),
        (
            "Birgi, God of Storytelling",
            {
                "xmage_class_name": "BirgiGodOfStorytelling",
                "effect_classes": ["ExileTopXMayPlayUntilEffect", "UntilEndOfTurnManaEffect"],
                "ability_classes": ["BoastAbility", "SimpleActivatedAbility", "SpellCastControllerTriggeredAbility"],
                "constructor_metadata": {"card_types": ["ARTIFACT", "CREATURE"]},
            },
            {"ARTIFACT", "CREATURE"},
            {"ExileTopXMayPlayUntilEffect", "UntilEndOfTurnManaEffect"},
            {"BoastAbility", "SimpleActivatedAbility", "SpellCastControllerTriggeredAbility"},
            set(),
            "spell_cast_red_mana_trigger_boast_harnfel_annotation_v1",
        ),
        (
            "Fractured Powerstone",
            {
                "xmage_class_name": "FracturedPowerstone",
                "effect_classes": ["FracturedPowerstoneEffect", "OneShotEffect"],
                "ability_classes": ["ActivateAsSorceryActivatedAbility", "ActivateIfConditionActivatedAbility", "ColorlessManaAbility", "StackAbility"],
                "cost_classes": ["TapSourceCost"],
                "constructor_metadata": {"card_types": ["ARTIFACT"]},
            },
            {"ARTIFACT"},
            {"FracturedPowerstoneEffect", "OneShotEffect"},
            {"ActivateAsSorceryActivatedAbility", "ActivateIfConditionActivatedAbility", "ColorlessManaAbility", "StackAbility"},
            {"TapSourceCost"},
            "colorless_mana_rock_planar_die_annotation_v1",
        ),
    ]

    for name, index_entry, types, effects, abilities, costs, scope in cases:
        effect = primary_from_index(index_entry)
        assert effect["battle_model_scope"] == scope
        assert family_lane(name, effect, types, effects, abilities, costs) == "batch_metadata_candidate_requires_pg_precheck"


def test_variable_mana_source_runtime_for_incubation_and_selvala():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    forest = card("Forest", "Basic Land - Forest", effect="land", mana_produced=1, produces="G")
    incubation = card(
        "Incubation Druid",
        "Creature - Elf Druid",
        effect="ramp_permanent",
        is_mana_source=True,
        mana_produced=1,
        mana_produced_if_plus_one_counter=3,
        produces="WUBRGC",
        power=0,
        toughness=2,
        plus_one_counters=1,
    )
    giant = card("Large Creature", "Creature - Beast", effect="creature", power=5, toughness=5)
    selvala = card(
        "Selvala, Heart of the Wilds",
        "Legendary Creature - Elf Scout",
        effect="ramp_permanent",
        is_mana_source=True,
        mana_produced_from_greatest_power_controlled_creatures=True,
        produces="WUBRG",
        activation_mana_cost="{G}",
        power=2,
        toughness=3,
    )
    active.battlefield = [selvala, incubation, giant, forest]

    events = []
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        active.refresh_mana_sources(turn=3)
    finally:
        battle.REPLAY_EVENT_HANDLER = None

    assert battle.mana_source_production_for_state(active, incubation) == 3
    assert battle.mana_source_production_for_state(active, selvala) == 5
    assert active.available_mana() == 8
    assert any(event == "mana_source_activation_cost_paid" and data.get("card") == "Selvala, Heart of the Wilds" for event, data in events)


def test_delighted_halfling_creates_conditional_legendary_mana_source():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    halfling = primary_from_index(
        {
            "xmage_class_name": "DelightedHalfling",
            "effect_classes": ["DelightedHalflingCantCounterEffect"],
            "ability_classes": [
                "ColorlessManaAbility",
                "ConditionalAnyColorManaAbility",
                "SimpleStaticAbility",
                "SpellAbility",
            ],
            "constructor_metadata": {"card_types": ["CREATURE"]},
        }
    )
    active.battlefield = [card("Delighted Halfling", "Creature - Halfling Citizen", **halfling)]

    active.refresh_mana_sources(turn=1)

    assert active.available_mana() == 1
    assert len(active.conditional_mana_sources) == 1
    modes = active.conditional_mana_sources[0]["modes"]
    assert {mode["restriction"] for mode in modes} == {"any_spell", "legendary_spell"}


def test_birgi_spell_cast_trigger_adds_red_mana():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    opponent = battle.Player("Opponent", None, [])
    birgi = primary_from_index(
        {
            "xmage_class_name": "BirgiGodOfStorytelling",
            "effect_classes": ["ExileTopXMayPlayUntilEffect", "UntilEndOfTurnManaEffect"],
            "ability_classes": ["BoastAbility", "SimpleActivatedAbility", "SpellCastControllerTriggeredAbility"],
            "constructor_metadata": {"card_types": ["ARTIFACT", "CREATURE"]},
        }
    )
    active.battlefield = [card("Birgi, God of Storytelling", "Legendary Creature - God", **birgi)]

    battle.trigger_spell_cast_engines(
        active,
        [active, opponent],
        card("Lightning Bolt", "Instant"),
        turn=2,
        phase="precombat_main",
    )

    assert active.mana_pool.red == 1


def test_mdfc_pay_life_land_faces_enter_and_make_mana():
    battle = load_battle()
    cases = [
        (
            "Bridgeworks Battle",
            {
                "xmage_class_name": "BridgeworksBattle",
                "effect_classes": ["BoostTargetEffect", "FightTargetsEffect", "TapSourceUnlessPaysEffect"],
                "ability_classes": ["AsEntersBattlefieldAbility", "GreenManaAbility"],
                "cost_classes": ["PayLifeCost"],
                "constructor_metadata": {"card_types": ["LAND", "SORCERY"]},
            },
            "Tanglespan Bridgeworks",
            "green",
        ),
        (
            "Hydroelectric Specimen",
            {
                "xmage_class_name": "HydroelectricSpecimen",
                "effect_classes": ["ChangeATargetOfTargetSpellAbilityToSourceEffect", "TapSourceUnlessPaysEffect"],
                "ability_classes": ["AsEntersBattlefieldAbility", "BlueManaAbility", "EntersBattlefieldTriggeredAbility", "FlashAbility"],
                "cost_classes": ["PayLifeCost"],
                "constructor_metadata": {"card_types": ["CREATURE", "LAND"]},
            },
            "Hydroelectric Laboratory",
            "blue",
        ),
    ]

    for front_name, index_entry, face_name, mana_color in cases:
        effect = primary_from_index(index_entry)
        active = battle.Player("Pilot", None, [])
        active.hand = [card(front_name, "Modal DFC")]
        original_get_card_effect = battle.get_card_effect
        battle.get_card_effect = lambda _card, effect=effect: effect
        try:
            played = battle.play_land_candidate(
                active,
                [],
                [active],
                turn=1,
                stack=battle.Stack(),
                candidate={"card": active.hand[0], "source_zone": "hand"},
            )
        finally:
            battle.get_card_effect = original_get_card_effect

        assert played is True
        assert active.life == 37
        permanent = active.battlefield[0]
        assert permanent["name"] == face_name
        assert permanent["life_paid_to_enter_untapped"] == 3
        assert permanent.get("tapped") is not True
        assert getattr(active.mana_pool, mana_color) == 1


if __name__ == "__main__":
    for test in [
        test_mapper_and_classifier_mark_exact_ramp_scopes_batch_safe,
        test_variable_mana_source_runtime_for_incubation_and_selvala,
        test_delighted_halfling_creates_conditional_legendary_mana_source,
        test_birgi_spell_cast_trigger_adds_red_mana,
        test_mdfc_pay_life_land_faces_enter_and_make_mana,
    ]:
        test()
