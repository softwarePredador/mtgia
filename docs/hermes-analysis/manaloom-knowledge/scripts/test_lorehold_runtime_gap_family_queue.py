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
