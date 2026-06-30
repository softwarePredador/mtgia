#!/usr/bin/env python3
"""Focused tests for Lorehold agent2 static/tutor runtime scopes."""

from __future__ import annotations

import importlib.util
import random
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import xmage_semantic_family_classifier as classifier
import xmage_to_manaloom_effect_hints as hints


def load_battle():
    spec = importlib.util.spec_from_file_location("battle_agent2_under_test", BATTLE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def card(name, type_line, **extra):
    return {"name": name, "type_line": type_line, **extra}


def primary_from_index(index_entry, oracle_text=""):
    return hints.build_effect_hints(index_entry, oracle_text)["primary_candidate"]["effect_json"]


def family_lane(card_name, effect_json, types, effects, abilities, targets=None, filters=None, costs=None):
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
                        "class_name": card_name.replace(" ", "").replace(",", "").replace("'", ""),
                        "path": f"/xmage/{card_name}.java",
                        "types": sorted(types),
                        "effect_classes": sorted(effects),
                        "ability_classes": sorted(abilities),
                        "target_classes": sorted(targets or []),
                        "filter_classes": sorted(filters or []),
                        "cost_classes": sorted(costs or []),
                        "primary_effect": effect_json,
                    },
                }
            ]
        }
    )
    return report["cards"][0]["promotion_lane"]


def blood_moon_index_entry():
    return {
        "xmage_class_name": "BloodMoon",
        "effect_classes": ["NonbasicLandsAreMountainsEffect"],
        "ability_classes": ["SimpleStaticAbility"],
        "target_classes": [],
        "filter_classes": [],
        "cost_classes": [],
        "constructor_metadata": {"card_types": ["ENCHANTMENT"]},
        "raw_excerpt": "new SimpleStaticAbility(new NonbasicLandsAreMountainsEffect())",
    }


def deathbellow_index_entry():
    return {
        "xmage_class_name": "DeathbellowWarCry",
        "effect_classes": ["SearchLibraryPutInPlayEffect"],
        "ability_classes": [],
        "target_classes": ["TargetCardWithDifferentNameInLibrary"],
        "filter_classes": ["FilterCard"],
        "cost_classes": [],
        "constructor_metadata": {"card_types": ["SORCERY"]},
        "raw_excerpt": (
            "new SearchLibraryPutInPlayEffect(new TargetCardWithDifferentNameInLibrary(0, 4, "
            "new FilterCreatureCard(\"Minotaur creature cards\", SubType.MINOTAUR)))"
        ),
    }


def test_blood_moon_mapper_and_classifier_are_exact_batch_safe():
    effect = primary_from_index(
        blood_moon_index_entry(),
        "Nonbasic lands are Mountains.",
    )

    assert effect["effect"] == "passive"
    assert effect["battle_model_scope"] == "nonbasic_lands_are_mountains_static_v1"
    assert effect["nonbasic_lands_are_mountains"] is True
    assert effect["nonbasic_lands_produce"] == "R"
    assert effect["suppresses_land_nonmana_abilities"] is True
    assert (
        family_lane(
            "Blood Moon",
            effect,
            {"ENCHANTMENT"},
            {"NonbasicLandsAreMountainsEffect"},
            {"SimpleStaticAbility"},
        )
        == "batch_metadata_candidate_requires_pg_precheck"
    )


def test_blood_moon_runtime_converts_existing_and_entering_nonbasic_lands():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    opponent = battle.Player("Opponent", None, [])
    sacred_foundry = card(
        "Sacred Foundry",
        "Land - Mountain Plains",
        effect="land",
        mana_produced=1,
        produces="WR",
    )
    mountain = card("Mountain", "Basic Land - Mountain", effect="land", mana_produced=1, produces="R")
    command_tower = card("Command Tower", "Land", effect="land", mana_produced=1, produces="WUBRG")
    active.battlefield = [sacred_foundry, mountain]
    opponent.battlefield = [command_tower]
    effect = primary_from_index(
        blood_moon_index_entry(),
        "Nonbasic lands are Mountains.",
    )

    battle.apply_effect_immediate(
        active,
        [opponent],
        card("Blood Moon", "Enchantment", cmc=3),
        3,
        random.Random(1),
        effect_data_override=effect,
    )

    assert sacred_foundry["blood_moon_modified"] is True
    assert sacred_foundry["type_line"] == "Land - Mountain"
    assert sacred_foundry["produces"] == "R"
    assert command_tower["blood_moon_modified"] is True
    assert command_tower["produces"] == "R"
    assert "blood_moon_modified" not in mountain

    late_land = card("Reliquary Tower", "Land", effect="land", mana_produced=1, produces="C")
    battle.prepare_entering_permanent(late_land, controller=active, all_players=[active, opponent], turn=3)
    active.battlefield.append(late_land)
    assert late_land["blood_moon_modified"] is True
    assert late_land["produces"] == "R"

    active.refresh_mana_sources(turn=3)
    assert active.mana_pool.red == 3


def test_deathbellow_mapper_and_classifier_are_exact_batch_safe():
    effect = primary_from_index(
        deathbellow_index_entry(),
        "Search your library for up to four Minotaur creature cards with different names, put them onto the battlefield, then shuffle.",
    )

    assert effect["effect"] == "tutor"
    assert effect["battle_model_scope"] == "search_up_to_four_minotaur_creatures_different_names_to_battlefield_v1"
    assert effect["target"] == "minotaur_creature_to_battlefield"
    assert effect["tutor_destination"] == "battlefield"
    assert effect["max_count"] == 4
    assert effect["different_names"] is True
    assert (
        family_lane(
            "Deathbellow War Cry",
            effect,
            {"SORCERY"},
            {"SearchLibraryPutInPlayEffect"},
            set(),
            {"TargetCardWithDifferentNameInLibrary"},
            {"FilterCard"},
        )
        == "batch_metadata_candidate_requires_pg_precheck"
    )


def test_deathbellow_runtime_puts_unique_named_minotaurs_onto_battlefield():
    battle = load_battle()
    active = battle.Player("Pilot", None, [])
    active.library = [
        card("Neheb, the Eternal", "Legendary Creature - Zombie Minotaur Warrior", cmc=5, power=4, toughness=6),
        card("Boros Reckoner", "Creature - Minotaur Wizard", cmc=3, power=3, toughness=3),
        card("Boros Reckoner", "Creature - Minotaur Wizard", cmc=3, power=3, toughness=3),
        card("Fanatic of Mogis", "Creature - Minotaur Shaman", cmc=4, power=4, toughness=2),
        card("Solemn Simulacrum", "Artifact Creature - Golem", cmc=4, power=2, toughness=2),
    ]
    effect = primary_from_index(
        deathbellow_index_entry(),
        "Search your library for up to four Minotaur creature cards with different names, put them onto the battlefield, then shuffle.",
    )

    battle.apply_effect_immediate(
        active,
        [],
        card("Deathbellow War Cry", "Sorcery", cmc=8),
        5,
        random.Random(2),
        effect_data_override=effect,
    )

    battlefield_names = [item["name"] for item in active.battlefield]
    assert sorted(battlefield_names) == ["Boros Reckoner", "Fanatic of Mogis", "Neheb, the Eternal"]
    assert all(item.get("effect") == "creature" for item in active.battlefield)
    library_names = [item["name"] for item in active.library]
    assert library_names.count("Boros Reckoner") == 1
    assert "Solemn Simulacrum" in library_names


def test_karn_the_great_creator_remains_split_scope_review_required():
    effect = primary_from_index(
        {
            "xmage_class_name": "KarnTheGreatCreator",
            "effect_classes": [
                "KarnTheGreatCreatorAnimateEffect",
                "KarnTheGreatCreatorCantActivateEffect",
                "RestrictionEffect",
                "WishEffect",
            ],
            "ability_classes": ["LoyaltyAbility", "SimpleStaticAbility"],
            "target_classes": ["TargetPermanent"],
            "constructor_metadata": {"card_types": ["PLANESWALKER"]},
        },
        "+1: Until your next turn, up to one target noncreature artifact becomes an artifact creature. -2: You may reveal an artifact card you own from outside the game or choose a face-up artifact card you own in exile, put that card into your hand.",
    )

    assert effect["battle_model_scope"] == "xmage_artifact_activation_lock_planeswalker_wish_review_v1"
    assert (
        family_lane(
            "Karn, the Great Creator",
            effect,
            {"PLANESWALKER"},
            {
                "KarnTheGreatCreatorAnimateEffect",
                "KarnTheGreatCreatorCantActivateEffect",
                "RestrictionEffect",
                "WishEffect",
            },
            {"LoyaltyAbility", "SimpleStaticAbility"},
            {"TargetPermanent"},
        )
        == "split_family_scope_review_required"
    )


def test_karns_sylex_remains_split_scope_review_required():
    effect = primary_from_index(
        {
            "xmage_class_name": "KarnsSylex",
            "effect_classes": ["KarnsSylexDestroyEffect", "OneShotEffect"],
            "ability_classes": [
                "ActivateAsSorceryActivatedAbility",
                "CantPayLifeOrSacrificeAbility",
                "EntersBattlefieldTappedAbility",
            ],
            "cost_classes": ["ExileSourceCost", "TapSourceCost"],
            "constructor_metadata": {"card_types": ["ARTIFACT"]},
            "raw_excerpt": (
                "Karn's Sylex enters the battlefield tapped. Players can't pay life to cast spells "
                "or to activate abilities that aren't mana abilities. X, tap, exile Karn's Sylex: "
                "Destroy each nonland permanent with mana value X or less. Activate only as a sorcery."
            ),
        }
    )

    assert effect["battle_model_scope"] == "xmage_mass_removal_or_sacrifice_variant_review_v1"
    assert (
        family_lane(
            "Karn's Sylex",
            effect,
            {"ARTIFACT"},
            {"KarnsSylexDestroyEffect", "OneShotEffect"},
            {
                "ActivateAsSorceryActivatedAbility",
                "CantPayLifeOrSacrificeAbility",
                "EntersBattlefieldTappedAbility",
            },
            costs={"ExileSourceCost", "TapSourceCost"},
        )
        == "split_family_scope_review_required"
    )
