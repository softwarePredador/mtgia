from pathlib import Path

import lorehold_engine_preserving_pressure_conversion_router as router


def _pressure_card(
    name,
    *,
    queue_status="missing_from_current_hypothesis_queue",
    readiness_status="identity_runtime_cut_model_required_before_gate",
    natural_gate_ready=False,
    preflight_status="pass",
):
    return {
        "card_name": name,
        "preflight_status": preflight_status,
        "role": "pressure_safe_spell_payoff",
        "value_test": f"value test for {name}",
        "hypothesis_queue_overlay": {
            "hypothesis_queue_status": queue_status,
            "readiness_status": readiness_status,
            "natural_gate_ready": natural_gate_ready,
        },
    }


def _pressure_contract(*, gut_ready=False, storm_ready=False, storm_prior=True):
    storm_readiness = "ready" if storm_ready else "blocked_prior_reject"
    if storm_prior:
        storm_readiness = "blocked_prior_reject"
    return {
        "summary": {"decision_status": "preflight_pass_cut_pool_required"},
        "primary_package_preflight": [
            _pressure_card(
                "Guttersnipe",
                queue_status="present" if gut_ready else "missing_from_current_hypothesis_queue",
                readiness_status="ready" if gut_ready else "identity_runtime_cut_model_required_before_gate",
                natural_gate_ready=gut_ready,
            ),
            _pressure_card(
                "Storm-Kiln Artist",
                queue_status="present",
                readiness_status=storm_readiness,
                natural_gate_ready=storm_ready and not storm_prior,
            ),
        ],
    }


def _package(adds, *, gate=False, diagnostic=False, blockers=None, gate_cuts=0, diagnostic_cuts=0):
    pkey = router.package_key(adds)
    return {
        "package_key": pkey,
        "adds": adds,
        "required_cut_count": len(adds),
        "available_gate_ready_cut_count": gate_cuts,
        "available_diagnostic_cut_count": diagnostic_cuts,
        "contract_natural_gate_ready_count": gate_cuts if gate else 0,
        "status": "gate_ready_requires_structure_matrix"
        if gate
        else "diagnostic_only_available_no_promotion"
        if diagnostic
        else "blocked_no_cut_or_hypothesis_capacity",
        "gate_ready": gate,
        "diagnostic_only_available": diagnostic,
        "blockers": blockers
        if blockers is not None
        else [
            "insufficient_seed_safe_cut_capacity",
            "insufficient_hypothesis_natural_gate_capacity",
        ],
    }


def _package_router(*, gate_pair=False):
    rows = [
        _package(["Guttersnipe"]),
        _package(["Storm-Kiln Artist"], blockers=["blocked_prior_reject"]),
    ]
    if gate_pair:
        rows.append(
            _package(
                ["Guttersnipe", "Storm-Kiln Artist"],
                gate=True,
                blockers=[],
                gate_cuts=2,
            )
        )
    else:
        rows.append(
            _package(
                ["Guttersnipe", "Storm-Kiln Artist"],
                blockers=[
                    "blocked_prior_reject",
                    "insufficient_seed_safe_cut_capacity",
                    "insufficient_hypothesis_natural_gate_capacity",
                ],
            )
        )
    return {"summary": {"decision_status": "smaller_pressure_packages_blocked_current_607"}, "packages": rows}


def _cut_pool(gate_cuts=0, diagnostic_cuts=0):
    return {
        "summary": {
            "gate_ready_cut_count": gate_cuts,
            "contract_natural_gate_ready_from_hypothesis_queue": gate_cuts,
        },
        "diagnostic_tradeoff_cut_plan": {"eligible_diagnostic_cut_count": diagnostic_cuts},
    }


def _spell_trace(*, gut_win=False):
    return {
        "summary": {
            "tested_pressure_cards": ["Guttersnipe", "Young Pyromancer", "Monastery Mentor"],
            "pressure_cards_by_result": {"win": ["Guttersnipe"]} if gut_win else {"loss": ["Young Pyromancer"]},
            "wins_with_pressure_card_events": 1 if gut_win else 0,
            "losses_with_pressure_card_events": 0 if gut_win else 1,
        }
    }


def _miracle_trace(flags=None):
    return {
        "summary": {
            "blocking_failure_flags": flags
            if flags is not None
            else [
                "pressure_causality_unproven",
                "pressure_conversion_unproven",
                "fast_pressure_slice_not_protected",
            ]
        }
    }


def _young_trace():
    return {
        "status": "young_pyromancer_pressure_window_refuted_no_deck_action",
        "summary": {"young_pyromancer_seen_only_in_losses": True},
    }


def _closing_trace():
    return {"summary": {"comparison_count": 13, "avg_607_turn_advantage": 10.15}}


def _storm_md(*, rejected=True):
    if not rejected:
        return "- status: `candidate_reopened_for_clean_package`\n"
    return "\n".join(
        [
            "- status: `rejected_for_deck_promotion_pressure_regression`",
            "The candidate has a real positive signal after the runtime fix.",
            "Do not promote this swap to the deck.",
            "| Winota, Joiner of Forces | `4W/5L` | `3W/6L` |",
            "| `treasure_created:Storm-Kiln Artist` | `17` |",
        ]
    )


def _build(
    *,
    contract=None,
    package_report=None,
    cut_pool=None,
    spell=None,
    miracle=None,
    storm_md=None,
):
    return router.build_report(
        young_trace=_young_trace(),
        package_router=package_report or _package_router(),
        pressure_contract=contract or _pressure_contract(),
        cut_pool=cut_pool or _cut_pool(),
        spell_pressure_trace=spell or _spell_trace(),
        miracle_trace=miracle or _miracle_trace(),
        closing_trace=_closing_trace(),
        storm_decision_markdown=storm_md if storm_md is not None else _storm_md(),
        paths={"package_router": Path("/tmp/package.json")},
    )


def test_current_like_engine_preserving_routes_are_not_gate_ready():
    payload = _build()

    assert payload["summary"]["decision_status"] == (
        "engine_preserving_pressure_conversion_not_gate_ready_keep_607"
    )
    assert payload["summary"]["gate_ready_route_count"] == 0
    assert payload["summary"]["diagnostic_ready_route_count"] == 0
    assert payload["summary"]["promotion_allowed_now"] is False
    assert payload["summary"]["best_next_learning_route"] == (
        "guttersnipe_storm_kiln_engine_preserving_pair"
    )

    pair = payload["best_next_learning_route"]
    assert pair["status"] == "best_next_learning_route_contract_required_no_deck_action"
    assert "insufficient_seed_safe_cut_capacity" in pair["blockers"]
    assert "storm_kiln_arcane_signet_swap_rejected" in pair["blockers"]


def test_synthetic_pair_with_safe_cuts_and_clean_trace_routes_to_structure_matrix():
    payload = _build(
        contract=_pressure_contract(gut_ready=True, storm_ready=True, storm_prior=False),
        package_report=_package_router(gate_pair=True),
        cut_pool=_cut_pool(gate_cuts=2),
        spell=_spell_trace(gut_win=True),
        miracle=_miracle_trace(flags=[]),
        storm_md=_storm_md(rejected=False),
    )

    assert payload["summary"]["decision_status"] == (
        "engine_preserving_pressure_conversion_gate_candidate"
    )
    assert payload["summary"]["gate_ready_route_count"] == 1
    assert payload["best_next_learning_route"]["route_key"] == (
        "guttersnipe_storm_kiln_engine_preserving_pair"
    )
    assert payload["best_next_learning_route"]["status"] == (
        "engine_preserving_pressure_conversion_gate_candidate_requires_structure_matrix"
    )


def test_storm_kiln_prior_reject_blocks_singleton_even_with_external_value():
    payload = _build()
    storm = next(
        row for row in payload["routes"] if row["route_key"] == "storm_kiln_artist_mana_conversion"
    )

    assert storm["status"] == "blocked_prior_reject_engine_signal_requires_new_package"
    assert "blocked_prior_reject" in storm["blockers"]
    assert "storm_kiln_arcane_signet_swap_rejected" in storm["blockers"]
    assert storm["promotion_allowed"] is False


def test_guttersnipe_is_research_candidate_until_hypothesis_and_trace_exist():
    payload = _build()
    guttersnipe = next(
        row for row in payload["routes"] if row["route_key"] == "guttersnipe_noncombat_spell_pressure"
    )

    assert guttersnipe["status"] == "research_candidate_missing_hypothesis_and_cut"
    assert "missing_current_hypothesis_queue" in guttersnipe["blockers"]
    assert "no_current_positive_guttersnipe_trace" in guttersnipe["blockers"]


def test_markdown_surfaces_no_mutation_and_external_research_links():
    markdown = router.render_markdown(_build())

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger" in markdown
    assert "https://commanderspellbook.com/combo/3940-5195/" in markdown
    assert "pair_is_learning_route_not_deck_action" in markdown
