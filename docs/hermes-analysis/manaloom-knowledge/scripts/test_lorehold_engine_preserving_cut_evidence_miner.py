from pathlib import Path

import lorehold_engine_preserving_cut_evidence_miner as miner


def _contract(required=2):
    return {
        "status": "hypothesis_contract_written_blocked_no_named_safe_cuts",
        "summary": {
            "required_cut_count": required,
            "router_route_status": "best_next_learning_route_contract_required_no_deck_action",
        },
    }


def _cut(
    name,
    *,
    lane="spell_velocity",
    status="blocked",
    manual_status="missing_manual_cut_evidence",
    blockers=None,
    exposure=5,
    score=90,
):
    return {
        "card_name": name,
        "lane": lane,
        "status": status,
        "manual_status": manual_status,
        "score": score,
        "unique_exposure_count": exposure,
        "direct_event_count": 0,
        "blockers": blockers
        if blockers is not None
        else ["manual_status_not_seed_safe", "missing_cut_safety_row"],
    }


def _seed_safe(cuts=None):
    return {"summary": {"blocker_counts": {}}, "cut_slots": cuts or []}


def _trace(names=None):
    return {
        "summary": {
            "top_near_miss_cut_cards": names or [],
            "hard_blocked_count": 0,
            "blocker_counts": {},
        },
        "all_cut_slots": [],
    }


def _build(cuts, *, required=2, top_names=None):
    return miner.build_report(
        contract=_contract(required=required),
        seed_safe_report=_seed_safe(cuts),
        trace_expander=_trace(top_names),
        cut_expansion={"status": "pressure_cut_expansion_no_seed_safe_cut_keep_607"},
        paths={"seed_safe_cut_report": Path("/tmp/seed.json")},
    )


def test_current_like_no_cut_evidence_keeps_607_protected():
    payload = _build(
        [
            _cut(
                "Creative Technique",
                lane="big_spell_value",
                manual_status="same_lane_only",
                blockers=[
                    "cut_is_miracle_core_big_spell",
                    "miracle_or_finisher_core",
                    "protected_cut",
                    "same_lane_only_requires_concrete_same_lane_add",
                ],
                exposure=58,
            ),
            _cut(
                "Bender's Waterskin",
                lane="early_mana",
                manual_status="same_lane_only",
                blockers=[
                    "cut_is_early_mana_floor_support",
                    "early_mana_floor_support",
                    "measured_high_cut_exposure",
                    "protected_cut",
                ],
                exposure=268,
            ),
        ],
        top_names=["Creative Technique", "Bender's Waterskin"],
    )

    assert payload["summary"]["decision_status"] == (
        "no_current_cut_evidence_for_guttersnipe_storm_kiln_keep_607"
    )
    assert payload["summary"]["named_seed_safe_cut_count"] == 0
    assert payload["summary"]["cut_shortage"] == 2
    assert payload["summary"]["hard_stop_cut_count"] == 2
    assert payload["decision"]["natural_battle_allowed_now"] is False


def test_two_seed_safe_target_lane_cuts_are_ready_for_structure_matrix():
    payload = _build(
        [
            _cut("Low Exposure Spell A", status="seed_safe_cut_ready", blockers=[]),
            _cut("Low Exposure Spell B", status="seed_safe_cut_ready", blockers=[]),
        ],
        top_names=["Low Exposure Spell A", "Low Exposure Spell B"],
    )

    assert payload["summary"]["decision_status"] == "cut_evidence_ready_for_structure_matrix"
    assert payload["summary"]["named_seed_safe_cut_count"] == 2
    assert payload["summary"]["cut_shortage"] == 0
    assert [row["card_name"] for row in payload["ready_seed_safe_cuts"]] == [
        "Low Exposure Spell A",
        "Low Exposure Spell B",
    ]


def test_target_lane_soft_gap_is_not_promoted_to_cut():
    payload = _build([_cut("Soft Gap Spell", lane="spell_velocity")])

    assert payload["summary"]["decision_status"] == "target_lane_cut_evidence_gap_keep_607"
    assert payload["summary"]["target_lane_evidence_gap_count"] == 1
    assert payload["target_lane_evidence_gaps"][0]["card_name"] == "Soft Gap Spell"
    assert payload["ready_seed_safe_cuts"] == []


def test_cross_lane_soft_gap_requires_separate_shell_contract():
    payload = _build([_cut("Draw Gap", lane="draw")])

    assert payload["summary"]["cross_lane_excluded_count"] == 1
    assert payload["cross_lane_exclusions"][0]["classification"] == (
        "cross_lane_not_current_package_cut"
    )
    assert payload["ready_seed_safe_cuts"] == []


def test_hard_stop_blocks_even_when_status_claims_ready():
    payload = _build(
        [
            _cut(
                "Protected Topdeck",
                lane="draw",
                status="seed_safe_cut_ready",
                blockers=["protected_cut", "measured_high_cut_exposure"],
            )
        ]
    )

    assert payload["summary"]["named_seed_safe_cut_count"] == 0
    assert payload["hard_stop_near_misses"][0]["card_name"] == "Protected Topdeck"
    assert "protected_cut" in payload["hard_stop_near_misses"][0]["hard_stop_blockers"]


def test_markdown_surfaces_no_mutation_and_cut_shortage():
    markdown = miner.render_markdown(
        _build([_cut("Creative Technique", lane="big_spell_value", blockers=["protected_cut"])])
    )

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "Cut shortage: `2`" in markdown
