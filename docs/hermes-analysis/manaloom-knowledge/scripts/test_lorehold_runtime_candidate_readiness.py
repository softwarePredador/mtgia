import lorehold_runtime_candidate_readiness as readiness


def test_default_access_model_uses_post_pg272_brainstone_report():
    assert readiness.DEFAULT_ACCESS_MODEL.name == "lorehold_access_cut_model_20260630_post_pg272_brainstone.json"


def test_default_runtime_queue_uses_post_pg273_codex_report():
    assert (
        readiness.DEFAULT_RUNTIME_QUEUE.name
        == "lorehold_runtime_gap_family_queue_20260630_post_pg273_codex_shredder.json"
    )


def test_default_manifests_include_current_pg271_pg272_pg273_packages():
    assert [path.name for path in readiness.DEFAULT_MANIFESTS] == [
        "pg271_hidden_retreat_damage_prevention_20260630_manifest.json",
        "pg272_brainstone_executable_topdeck_20260630_manifest.json",
        "pg273_codex_shredder_mill_recursion_20260630_manifest.json",
    ]
    assert readiness.DEFAULT_PRECHECK_BLOCKERS == []


def runtime_queue():
    return {
        "family_queue": [
            {
                "family_id": "static_damage_modifier",
                "support_status": "runtime_supported_family",
                "batch_strategy": "metadata_batch_after_pg_precheck",
                "cards": [
                    {
                        "card_name": "Twinflame Tyrant",
                        "promotion_lane": "batch_metadata_candidate_requires_pg_precheck",
                        "effect": "damage_modifier",
                        "battle_model_scope": "damage_doubled_v1",
                        "ready_for_structured_pull": True,
                        "candidate_lane": "finisher_or_big_spell",
                        "candidate_score": 10,
                        "variant_decks": [608],
                        "variant_deck_count": 1,
                        "xmage_class": "TwinflameTyrant",
                    }
                ],
            },
            {
                "family_id": "targeted_interaction",
                "support_status": "runtime_family_partially_supported_review_required",
                "batch_strategy": "split_by_scope_before_metadata_batch",
                "cards": [
                    {
                        "card_name": "Boros Reckoner",
                        "promotion_lane": "split_family_scope_review_required",
                        "effect": "direct_damage",
                        "battle_model_scope": "targeted_damage_variant_v1",
                        "ready_for_structured_pull": True,
                        "candidate_lane": "contextual",
                        "candidate_score": 3,
                    }
                ],
            },
        ]
    }


def access_model():
    return {
        "candidates": [
            {
                "card_name": "Hidden Retreat",
                "lane": "topdeck_protection",
                "score": 0,
                "access_targets": ["Sensei's Divining Top"],
                "blockers": ["candidate_runtime_review_only"],
                "rule_summary": {
                    "active_rule_count": 0,
                    "review_only_rule_count": 2,
                },
                "variant_usage": {"deck_count": 0, "deck_ids": []},
            }
        ]
    }


def hypothesis_queue():
    return {
        "queue": [
            {
                "package_key": "pg245_twinflame_damage_payoff_cut_thor",
                "status": "tested_negative_do_not_promote",
                "adds": ["Twinflame Tyrant"],
                "cuts": ["Thor, God of Thunder"],
                "lane": "spell_chain_conversion",
                "prior_gate": {"decision": "tested_negative_do_not_promote", "delta_pp": -33.34},
                "runtime_package_readiness": {
                    "Twinflame Tyrant": {"readiness": "runtime_ready_pg_precheck_blocked"}
                },
            }
        ]
    }


def test_pg_precheck_blocked_is_not_global_card_reject(tmp_path):
    manifest_path = tmp_path / "pg245_manifest.json"
    blocker_path = tmp_path / "pg245_blocked.json"
    manifests = [
        (
            manifest_path,
            {
                "deploy_id": "PG245",
                "status": "prepared_read_only_pending_apply_approval",
                "selected_card_names": ["Twinflame Tyrant"],
                "files": {"apply": "apply.sql"},
            },
        )
    ]
    blockers = [
        (
            blocker_path,
            {
                "deploy_id": "PG245",
                "status": "postgres_precheck_blocked_connection_closed",
                "blocked_step": "precheck",
                "selected_cards": ["Twinflame Tyrant"],
                "sanitized_error": "server closed the connection unexpectedly",
            },
        )
    ]

    report = readiness.build_report(
        runtime_queue=runtime_queue(),
        access_model=access_model(),
        hypothesis_queue=hypothesis_queue(),
        manifests=manifests,
        precheck_blockers=blockers,
    )

    rows = {row["card_name"]: row for row in report["cards"]}
    twinflame = rows["Twinflame Tyrant"]
    assert twinflame["status"] == "pg_precheck_blocked"
    assert twinflame["card_global_reject"] is False
    assert twinflame["cut_specific_negative_count"] == 1
    assert twinflame["cut_specific_negatives"][0]["cuts"] == ["Thor, God of Thunder"]
    assert report["summary"]["pg_precheck_blocked_count"] == 1


def test_missing_pg_package_files_blocks_apply_before_precheck(tmp_path):
    manifest_path = tmp_path / "pg244_manifest.json"
    manifests = [
        (
            manifest_path,
            {
                "deploy_id": "PG244",
                "status": "prepared_read_only_pending_apply_approval",
                "selected_card_names": ["Hidden Retreat"],
                "files": {
                    "precheck": "missing_precheck.sql",
                    "apply": "missing_apply.sql",
                    "postcheck": "missing_postcheck.sql",
                    "rollback": "missing_rollback.sql",
                },
            },
        )
    ]

    report = readiness.build_report(
        runtime_queue={"family_queue": []},
        access_model=access_model(),
        hypothesis_queue={"queue": []},
        manifests=manifests,
        precheck_blockers=[],
    )

    hidden = {row["card_name"]: row for row in report["cards"]}["Hidden Retreat"]
    assert hidden["status"] == "pg_package_files_missing"
    assert hidden["pg_packages"][0]["missing_files"] == ["apply", "postcheck", "precheck", "rollback"]
    assert report["summary"]["pg_package_files_missing_count"] == 1
    assert report["summary"]["recommended_next_action"].startswith("regenerate_missing_pg_package_files")


def test_applied_synced_pg_package_is_not_reported_pending():
    manifests = [
        (
            readiness.REPORT_DIR / "pg271_manifest.json",
            {
                "deploy_id": "PG271",
                "status": "prepared_read_only_pending_apply_approval",
                "selected_card_names": ["Hidden Retreat"],
                "files": {
                    "precheck": "docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_runtime_candidate_readiness.py",
                    "apply": "docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_runtime_candidate_readiness.py",
                    "postcheck": "docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_runtime_candidate_readiness.py",
                    "rollback": "docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_runtime_candidate_readiness.py",
                },
                "expected_rules": [
                    {
                        "card_name": "Hidden Retreat",
                        "logical_rule_key": "battle_rule_v1:7148a419f22524cca81db7d14deeb043",
                        "review_status": "verified",
                        "execution_status": "auto",
                        "required_effect_fields": {
                            "effect": "damage_prevention_shield",
                            "battle_model_scope": (
                                "activated_put_card_from_hand_on_top_library_"
                                "prevent_damage_from_target_instant_or_sorcery_spell_v1"
                            ),
                        },
                    }
                ],
            },
        )
    ]
    active_rule_index = {
        "hidden retreat": [
            {
                "card_name": "Hidden Retreat",
                "logical_rule_key": "battle_rule_v1:7148a419f22524cca81db7d14deeb043",
                "review_status": "verified",
                "execution_status": "auto",
                "source": "curated",
                "effect_json": {
                    "effect": "damage_prevention_shield",
                    "battle_model_scope": (
                        "activated_put_card_from_hand_on_top_library_"
                        "prevent_damage_from_target_instant_or_sorcery_spell_v1"
                    ),
                },
            }
        ]
    }

    report = readiness.build_report(
        runtime_queue={"family_queue": []},
        access_model=access_model(),
        hypothesis_queue={"queue": []},
        manifests=manifests,
        precheck_blockers=[],
        active_rule_index=active_rule_index,
    )

    hidden = {row["card_name"]: row for row in report["cards"]}["Hidden Retreat"]
    assert hidden["status"] == "pg_package_applied_synced"
    assert hidden["active_rules"][0]["source"] == "curated"
    assert report["summary"]["pg_package_applied_synced_count"] == 1
    assert report["summary"]["pg_package_prepared_pending_apply_approval_count"] == 0
    assert not report["summary"]["recommended_next_action"].startswith("run_approved_precheck_apply")


def test_applied_synced_pg_package_accepts_selected_cards_manifest():
    manifests = [
        (
            readiness.REPORT_DIR / "pg272_manifest.json",
            {
                "deploy_id": "PG272",
                "status": "applied_synced",
                "selected_cards": ["Brainstone"],
                "files": {},
                "expected_rules": [
                    {
                        "card_name": "Brainstone",
                        "logical_rule_key": "battle_rule_v1:6aab083c9a25b2af50c2069683da5131",
                        "review_status": "verified",
                        "execution_status": "auto",
                    }
                ],
            },
        )
    ]
    access = {
        "candidates": [
            {
                "card_name": "Brainstone",
                "lane": "topdeck_setup",
                "score": 35,
                "access_targets": ["Sensei's Divining Top"],
                "blockers": [],
                "rule_summary": {
                    "active_rule_count": 1,
                    "review_only_rule_count": 0,
                },
                "variant_usage": {"deck_count": 0, "deck_ids": []},
            }
        ]
    }
    active_rule_index = {
        "brainstone": [
            {
                "card_name": "Brainstone",
                "logical_rule_key": "battle_rule_v1:6aab083c9a25b2af50c2069683da5131",
                "review_status": "verified",
                "execution_status": "auto",
                "source": "curated",
                "effect_json": {"battle_model_scope": "brainstone_draw_three_put_two_back_for_first_draw_miracle_v1"},
            }
        ]
    }

    report = readiness.build_report(
        runtime_queue={"family_queue": []},
        access_model=access,
        hypothesis_queue={"queue": []},
        manifests=manifests,
        precheck_blockers=[],
        active_rule_index=active_rule_index,
    )

    brainstone = {row["card_name"]: row for row in report["cards"]}["Brainstone"]
    assert brainstone["status"] == "pg_package_applied_synced"
    assert report["summary"]["pg_package_applied_synced_count"] == 1


def test_split_scope_and_access_runtime_blockers_get_separate_statuses():
    report = readiness.build_report(
        runtime_queue=runtime_queue(),
        access_model=access_model(),
        hypothesis_queue={"queue": []},
        manifests=[],
        precheck_blockers=[],
    )

    rows = {row["card_name"]: row for row in report["cards"]}
    assert rows["Boros Reckoner"]["status"] == "split_scope_review_required"
    assert rows["Hidden Retreat"]["status"] == "runtime_model_blocked"
    assert rows["Hidden Retreat"]["runtime_blockers"] == ["candidate_runtime_review_only"]
