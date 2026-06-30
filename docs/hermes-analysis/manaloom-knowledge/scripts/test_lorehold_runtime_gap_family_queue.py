import json
import sqlite3

import lorehold_runtime_gap_family_queue as queue


def test_default_miner_report_uses_current_runtime_queue() -> None:
    assert queue.DEFAULT_MINER_REPORT.name == "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"


def miner_report() -> dict:
    return {
        "base_deck_id": 6,
        "variant_deck_ids": [608, 609],
        "summary": {"blocked_runtime_rule_gap_count": 1},
        "top_variant_candidates": [],
        "all_variant_candidates": [
            {
                "card_name": "Blocked Engine",
                "status": "blocked_runtime_rule_gap",
                "score": 24,
                "lane": "hand_filter",
                "type_line": "Artifact",
                "variant_decks": [608, 609],
                "variant_deck_count": 2,
                "variant_total_quantity": 2,
                "active_rule_count": 0,
                "review_only_rule_count": 1,
                "functional_tags": {"draw": 2},
            },
            {
                "card_name": "Ready Engine",
                "status": "runtime_ready_unexplored",
                "score": 12,
                "lane": "early_mana",
                "variant_decks": [608],
                "variant_deck_count": 1,
            },
        ],
    }


def test_blocked_runtime_rows_uses_all_candidates_not_only_top() -> None:
    rows = queue.blocked_runtime_rows(miner_report())

    assert [row["card_name"] for row in rows] == ["Blocked Engine"]


def test_blocked_runtime_rows_filters_current_verified_auto_sqlite_rule(tmp_path) -> None:
    sqlite_db = tmp_path / "knowledge.db"
    conn = sqlite3.connect(sqlite_db)
    conn.execute(
        """
        CREATE TABLE battle_card_rules (
          normalized_name TEXT,
          logical_rule_key TEXT,
          card_name TEXT,
          effect_json TEXT,
          deck_role_json TEXT,
          source TEXT,
          confidence REAL,
          review_status TEXT,
          execution_status TEXT,
          rule_version INTEGER,
          oracle_hash TEXT,
          notes TEXT,
          created_at TEXT,
          updated_at TEXT,
          last_seen_at TEXT,
          PRIMARY KEY (normalized_name, logical_rule_key)
        )
        """
    )
    conn.execute(
        """
        INSERT INTO battle_card_rules (
          normalized_name, logical_rule_key, card_name, effect_json,
          deck_role_json, source, confidence, review_status, execution_status,
          rule_version, oracle_hash, notes, created_at, updated_at, last_seen_at
        ) VALUES (?, ?, ?, ?, '{}', 'curated', 1.0, 'verified', 'auto', 2, 'hash', '', '', '', '')
        """,
        (
            "blocked engine",
            "battle_rule_v1:abc",
            "Blocked Engine",
            json.dumps({"effect": "draw_engine", "battle_model_scope": "current_exact_scope_v1"}),
        ),
    )
    conn.commit()
    conn.close()
    active_rules = queue.active_runtime_rule_index(sqlite_db)

    rows = queue.blocked_runtime_rows(
        miner_report(),
        active_rule_index=active_rules,
    )

    assert rows == []


def test_blocked_coherence_report_preserves_lorehold_context() -> None:
    rows = queue.blocked_runtime_rows(miner_report())
    report = queue.build_blocked_coherence_report(
        miner_report=miner_report(),
        blocked_rows=rows,
    )

    assert report["total_cards"] == 1
    assert report["severity_counts"] == {"high": 1}
    assert report["source_deck_ids"] == [6, 608, 609]
    card = report["cards"][0]
    assert card["card_name"] == "Blocked Engine"
    assert card["lane"] == "hand_filter"
    assert card["findings"][0]["code"] == "no_active_battle_rule"


def test_family_queue_groups_cards_with_candidate_priority_context() -> None:
    rows = queue.blocked_runtime_rows(miner_report())
    family_report = {
        "families": [
            {
                "family_id": "manual_model",
                "support_status": "manual_model_required",
                "batch_strategy": "not_batch_safe",
                "implementation_unit": "manual mapper required",
                "family_tests": [],
                "cards": [
                    {
                        "card_name": "Blocked Engine",
                        "promotion_lane": "mapper_metadata_or_test_scenario_required",
                        "family_support_status": "manual_model_required",
                        "effect": "external_reference_required_manual_model",
                        "battle_model_scope": "xmage_reference_requires_manual_model_review_v1",
                        "ready_for_structured_pull": False,
                        "valid_xmage_source": True,
                        "xmage_class": "BlockedEngine",
                        "xmage_path": "/tmp/BlockedEngine.java",
                        "xmage_ability_classes": ["SimpleActivatedAbility"],
                        "xmage_effect_classes": ["DrawCardSourceControllerEffect"],
                        "xmage_target_classes": ["TargetPlayer"],
                        "xmage_condition_classes": [],
                        "focused_test_scenario_count": 1,
                    }
                ],
            }
        ]
    }

    family_queue = queue.build_family_queue(
        family_report=family_report,
        blocked_rows=rows,
    )

    assert family_queue[0]["family_id"] == "manual_model"
    assert family_queue[0]["candidate_lane_counts"] == {"hand_filter": 1}
    assert family_queue[0]["promotion_lane_counts"] == {
        "mapper_metadata_or_test_scenario_required": 1
    }
    assert family_queue[0]["xmage_signal_groups"][0]["signal_group"] == (
        "targeting;draw;activated_ability"
    )
    card = family_queue[0]["cards"][0]
    assert card["candidate_score"] == 24
    assert card["variant_decks"] == [608, 609]


def test_targeted_interaction_queue_splits_direct_damage_subfamilies() -> None:
    rows = [
        {
            "card_name": "Terror of the Peaks",
            "status": "blocked_runtime_rule_gap",
            "score": 0,
            "lane": "contextual",
            "variant_decks": [608, 612],
            "variant_deck_count": 2,
        },
        {
            "card_name": "Balefire Liege",
            "status": "blocked_runtime_rule_gap",
            "score": -10,
            "lane": "contextual",
            "variant_decks": [616],
            "variant_deck_count": 1,
        },
        {
            "card_name": "Firesong and Sunspeaker",
            "status": "blocked_runtime_rule_gap",
            "score": -10,
            "lane": "finisher_or_big_spell",
            "variant_decks": [616],
            "variant_deck_count": 1,
        },
        {
            "card_name": "Boros Reckoner",
            "status": "blocked_runtime_rule_gap",
            "score": 0,
            "lane": "contextual",
            "variant_decks": [612, 616],
            "variant_deck_count": 2,
        },
        {
            "card_name": "Repercussion",
            "status": "blocked_runtime_rule_gap",
            "score": -10,
            "lane": "contextual",
            "variant_decks": [612],
            "variant_deck_count": 1,
        },
        {
            "card_name": "Toralf, God of Fury // Toralf's Hammer",
            "status": "blocked_runtime_rule_gap",
            "score": -10,
            "lane": "contextual",
            "variant_decks": [612],
            "variant_deck_count": 1,
        },
    ]
    family_report = {
        "families": [
            {
                "family_id": "targeted_interaction",
                "support_status": "runtime_family_partially_supported_review_required",
                "batch_strategy": "split_by_scope_before_metadata_batch",
                "implementation_unit": "target legality, resolution, zone transition, and event provenance",
                "family_tests": [],
                "cards": [
                    targeted_damage_card(
                        "Terror of the Peaks",
                        abilities=["EntersBattlefieldControlledTriggeredAbility"],
                        effects=["DamageTargetEffect", "TerrorOfThePeaksCostIncreaseEffect"],
                        targets=["TargetAnyTarget"],
                    ),
                    targeted_damage_card(
                        "Balefire Liege",
                        abilities=["SpellCastControllerTriggeredAbility"],
                        effects=["BoostControlledEffect", "DamageTargetEffect", "GainLifeEffect"],
                        targets=["TargetPlayerOrPlaneswalker"],
                    ),
                    targeted_damage_card(
                        "Firesong and Sunspeaker",
                        abilities=["FiresongAndSunspeakerTriggeredAbility"],
                        effects=["DamageTargetEffect", "GainAbilityControlledSpellsEffect"],
                        targets=["TargetCreatureOrPlayer"],
                    ),
                    targeted_damage_card(
                        "Boros Reckoner",
                        abilities=["DealtDamageToSourceTriggeredAbility"],
                        effects=["DamageTargetEffect", "GainAbilitySourceEffect"],
                        targets=["TargetAnyTarget"],
                    ),
                    targeted_damage_card(
                        "Repercussion",
                        abilities=["DealtDamageAnyTriggeredAbility"],
                        effects=["DamageTargetEffect"],
                        targets=[],
                    ),
                    targeted_damage_card(
                        "Toralf, God of Fury // Toralf's Hammer",
                        abilities=["BatchTriggeredAbility", "ToralfGodOfFuryTriggeredAbility"],
                        effects=["DamageTargetEffect", "ToralfsHammerEffect"],
                        targets=["TargetAnyTarget"],
                        conditions=["AttachedToMatchesFilterCondition"],
                    ),
                ],
            }
        ]
    }

    family_queue = queue.build_family_queue(
        family_report=family_report,
        blocked_rows=rows,
    )

    family = family_queue[0]
    assert family["targeted_interaction_subfamily_status_counts"] == {
        "runtime_family_implementation_required": 1,
        "runtime_supported_family": 5,
    }
    assert family["targeted_interaction_subfamily_counts"] == {
        "creature_damage_controller_reflect_global": 1,
        "excess_damage_redirect_to_any_target": 1,
        "instant_sorcery_lifelink_lifegain_damage_engine": 1,
        "source_damaged_reflect_to_any_target": 1,
        "spell_color_trigger_damage_life_engine": 1,
        "targeted_damage_etb_power_to_any_target": 1,
    }
    by_card = {
        card["card_name"]: card["targeted_interaction_subfamily"]
        for card in family["cards"]
    }
    assert by_card["Repercussion"]["subfamily_id"] == "creature_damage_controller_reflect_global"
    assert by_card["Repercussion"]["status"] == "runtime_supported_family"
    assert by_card["Toralf, God of Fury // Toralf's Hammer"]["requires_condition_model"] is True
    assert by_card["Terror of the Peaks"]["subfamily_id"] == "targeted_damage_etb_power_to_any_target"
    assert by_card["Terror of the Peaks"]["status"] == "runtime_supported_family"
    assert by_card["Firesong and Sunspeaker"]["status"] == "runtime_supported_family"
    assert by_card["Balefire Liege"]["status"] == "runtime_supported_family"
    assert by_card["Boros Reckoner"]["status"] == "runtime_supported_family"
    assert by_card["Boros Reckoner"]["family_tests"] == [
        "test_boros_reckoner_reflects_damage_to_selected_any_target",
        "test_boros_reckoner_reflection_uses_saved_damage_amount",
    ]
    assert by_card["Balefire Liege"]["family_tests"] == [
        "test_balefire_liege_red_spell_deals_three_to_target_player_or_planeswalker",
        "test_balefire_liege_white_spell_gains_three_life",
        "test_balefire_liege_red_white_spell_fires_both_triggers",
    ]


def targeted_damage_card(
    name: str,
    *,
    abilities: list[str],
    effects: list[str],
    targets: list[str],
    conditions: list[str] | None = None,
) -> dict:
    return {
        "card_name": name,
        "promotion_lane": "split_family_scope_review_required",
        "family_support_status": "runtime_family_partially_supported_review_required",
        "effect": "direct_damage",
        "battle_model_scope": "targeted_damage_variant_v1",
        "ready_for_structured_pull": True,
        "valid_xmage_source": True,
        "xmage_class": name.replace(" ", ""),
        "xmage_path": f"/tmp/{name}.java",
        "xmage_ability_classes": abilities,
        "xmage_effect_classes": effects,
        "xmage_target_classes": targets,
        "xmage_condition_classes": conditions or [],
        "focused_test_scenario_count": 1,
    }
