from pathlib import Path

import lorehold_external_evidence_reconciler as reconciler


def _base_inputs():
    champion = {
        "cards": [
            {"name": "Library of Leng"},
            {"name": "Sensei's Divining Top"},
            {"name": "Creative Technique"},
            {"name": "Bender's Waterskin"},
            {"name": "Flex Cut"},
        ],
        "summary": {"deck_id": 607},
    }
    trace_cut = {
        "summary": {"recommended_next_action": "no_cut_slot_to_expand_under_current_607_contract"},
        "all_cut_slots": [
            {
                "card_name": "Creative Technique",
                "actionability": "same_lane_hard_blocked",
                "lane": "big_spell_value",
                "status": "same_lane_only_not_seed_safe",
                "all_blockers": ["protected_cut", "prior_rejected_cut"],
                "recommended_action": "do_not_use_until_concrete_same_lane_add_and_new_evidence",
            },
            {
                "card_name": "Flex Cut",
                "actionability": "seed_safe_ready",
                "lane": "misc",
                "status": "seed_safe_cut_ready",
                "all_blockers": [],
                "recommended_action": "build_package_from_seed_safe_cut",
            },
        ],
    }
    planner = {
        "summary": {
            "recommended_next_action": "no_cut_slot_to_expand_under_current_607_contract",
            "prior_rejected_package_keys": [
                "planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique"
            ],
            "prior_inconclusive_low_exposure_keys": ["low_exposure_probe"],
        }
    }
    return champion, trace_cut, planner


def test_external_reconciler_classifies_current_anchor_and_blocked_signal():
    champion, trace_cut, planner = _base_inputs()
    corpus = {
        "sources": [{"source_key": "source", "url": "https://example.test", "source_type": "test"}],
        "signals": [
            {
                "signal_key": "anchor",
                "package_key": "anchor",
                "add_cards": ["Library of Leng", "Sensei's Divining Top"],
                "proposed_cut_cards": [],
                "lane": "topdeck_miracle_setup",
            },
            {
                "signal_key": "planetarium",
                "package_key": "planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique",
                "add_cards": ["Planetarium of Wan Shi Tong"],
                "proposed_cut_cards": ["Creative Technique"],
                "lane": "topdeck_miracle_setup",
            },
        ],
    }

    payload = reconciler.build_report(
        external_corpus=corpus,
        champion_snapshot=champion,
        trace_cut_evidence=trace_cut,
        planner=planner,
        external_corpus_path=Path("/tmp/corpus.json"),
        champion_snapshot_path=Path("/tmp/champion.json"),
        trace_cut_evidence_path=Path("/tmp/cut.json"),
        planner_path=Path("/tmp/planner.json"),
    )

    statuses = {row["signal_key"]: row["status"] for row in payload["signals"]}
    assert statuses["anchor"] == "already_represented_by_current_607"
    assert statuses["planetarium"] == "blocked_by_cut_safety"
    planetarium = next(row for row in payload["signals"] if row["signal_key"] == "planetarium")
    assert "prior_internal_reject" in planetarium["blockers"]
    assert payload["summary"]["direct_deck_change_ready_count"] == 0


def test_external_reconciler_allows_only_seed_safe_named_cut_as_preflight():
    champion, trace_cut, planner = _base_inputs()
    corpus = {
        "signals": [
            {
                "signal_key": "lapse_no_cut",
                "package_key": "lapse_no_cut",
                "add_cards": ["Lapse of Certainty"],
                "proposed_cut_cards": [],
                "lane": "deterministic_finisher",
            },
            {
                "signal_key": "full_shell",
                "package_key": "full_shell",
                "contract_path": "full_shell",
                "add_cards": ["Chrome Mox"],
                "proposed_cut_cards": ["Bender's Waterskin"],
                "lane": "early_plan",
            },
            {
                "signal_key": "ready",
                "package_key": "ready",
                "add_cards": ["Useful Card"],
                "proposed_cut_cards": ["Flex Cut"],
                "lane": "misc",
            },
        ],
    }

    payload = reconciler.build_report(
        external_corpus=corpus,
        champion_snapshot=champion,
        trace_cut_evidence=trace_cut,
        planner=planner,
        external_corpus_path=Path("/tmp/corpus.json"),
        champion_snapshot_path=Path("/tmp/champion.json"),
        trace_cut_evidence_path=Path("/tmp/cut.json"),
        planner_path=Path("/tmp/planner.json"),
    )

    statuses = {row["signal_key"]: row["status"] for row in payload["signals"]}
    assert statuses["lapse_no_cut"] == "blocked_no_named_cut"
    assert statuses["full_shell"] == "requires_separate_full_shell_contract"
    assert statuses["ready"] == "preflight_ready_external_candidate"
    assert payload["summary"]["direct_deck_change_ready_count"] == 1
    assert payload["summary"]["recommended_next_action"] == (
        "build_named_package_manifest_then_battle_gate"
    )
