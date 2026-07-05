from pathlib import Path

import lorehold_young_pyromancer_singleton_cut_safety_model as model


def _package_router(status="blocked_no_cut_or_hypothesis_capacity", gate_ready=False):
    return {
        "summary": {
            "best_singleton_learning_package": "pressure_1_card_young_pyromancer",
        },
        "packages": [
            {
                "package_key": "pressure_1_card_young_pyromancer",
                "adds": ["Young Pyromancer"],
                "status": status,
                "gate_ready": gate_ready,
                "score": 75,
                "blockers": ["insufficient_seed_safe_cut_capacity"],
            }
        ],
    }


def _contract():
    return {
        "primary_package_preflight": [
            {
                "card_name": "Young Pyromancer",
                "role": "low_curve_token_pressure_payoff",
                "cmc": 2,
                "type_line": "Creature - Human Shaman",
                "preflight_status": "pass",
                "commander_legal_status": "legal",
                "already_in_607": False,
                "verified_auto_battle_rule_count": 1,
                "hypothesis_queue_overlay": {
                    "hypothesis_queue_status": "missing_from_current_hypothesis_queue",
                    "natural_gate_ready": False,
                },
            }
        ]
    }


def _seed_safe(candidates=None):
    candidates = candidates or []
    return {
        "summary": {
            "seed_safe_cut_ready_count": len(candidates),
        },
        "seed_safe_cut_candidates": candidates,
    }


def _trace(rows, *, reviewable=0):
    return {
        "summary": {
            "seed_safe_ready_count": 0,
            "reviewable_evidence_gap_count": reviewable,
            "hard_blocked_count": len(rows),
        },
        "all_cut_slots": rows,
    }


def _row(card_name, lane, blockers=None, manual_status="", exposure=0, events=0, status="blocked"):
    return {
        "card_name": card_name,
        "lane": lane,
        "manual_status": manual_status,
        "status": status,
        "unique_exposure_count": exposure,
        "direct_event_count": events,
        "all_blockers": blockers or [],
    }


def _build(seed_safe=None, trace=None, router=None):
    return model.build_model(
        package_router=router or _package_router(),
        pressure_contract=_contract(),
        seed_safe_report=seed_safe or _seed_safe(),
        trace_expander=trace or _trace([]),
        paths={"package_router": Path("/tmp/router.json")},
    )


def test_current_like_model_keeps_607_when_no_pressure_cut_exists():
    payload = _build(
        trace=_trace(
            [
                _row("Hexing Squelcher", "contextual", ["protected_cut", "prior_rejected_cut"], exposure=93),
                _row("Generous Gift", "removal", ["measured_high_cut_exposure"], exposure=52),
            ]
        )
    )

    assert payload["status"] == "young_pyromancer_singleton_no_cut_keep_607"
    assert payload["summary"]["eligible_cut_count"] == 0
    assert payload["summary"]["pressure_lane_hard_blocked_count"] == 1
    assert payload["summary"]["promotion_allowed_now"] is False


def test_seed_safe_pressure_lane_cut_becomes_structure_matrix_candidate():
    cut = _row("Low-Impact Token Slot", "creature", [], manual_status="seed_safe", status="seed_safe_cut_ready")
    payload = _build(seed_safe=_seed_safe([cut]), trace=_trace([cut]))

    assert payload["status"] == "young_pyromancer_singleton_gate_candidate_requires_structure_matrix"
    assert payload["summary"]["eligible_cut_count"] == 1
    assert payload["eligible_cut_candidates"][0]["card_name"] == "Low-Impact Token Slot"
    assert payload["eligible_cut_candidates"][0]["recommended_action"] == (
        "run_structure_matrix_before_any_battle"
    )


def test_wrong_lane_seed_safe_cut_does_not_promote_young_pyromancer():
    cut = _row("Loose Removal Slot", "removal", [], manual_status="seed_safe", status="seed_safe_cut_ready")
    payload = _build(seed_safe=_seed_safe([cut]), trace=_trace([cut]))
    row = payload["top_cut_safety_rows"][0]

    assert payload["status"] == "young_pyromancer_singleton_no_cut_keep_607"
    assert payload["summary"]["eligible_cut_count"] == 0
    assert row["young_pyromancer_cut_status"] == "blocked_lane_mismatch_for_young_pyromancer"


def test_pressure_lane_evidence_gap_is_not_gate_ready():
    cut = _row("Untested Pressure Slot", "contextual", ["missing_cut_safety_row"], exposure=2)
    payload = _build(trace=_trace([cut], reviewable=1))

    assert payload["status"] == "young_pyromancer_singleton_cut_evidence_gap_not_gate_ready"
    assert payload["summary"]["pressure_lane_evidence_gap_count"] == 1
    assert payload["pressure_lane_evidence_gaps"][0]["recommended_action"] == (
        "mine_trace_or_manual_review_before_deck_variant"
    )


def test_markdown_surfaces_no_mutation_and_external_support():
    payload = _build(trace=_trace([_row("Generous Gift", "removal", ["measured_high_cut_exposure"])]))
    markdown = model.render_markdown(payload)

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger" in markdown
