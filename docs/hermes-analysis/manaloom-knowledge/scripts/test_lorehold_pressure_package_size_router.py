from pathlib import Path

import lorehold_pressure_package_size_router as router


def _pressure_card(
    name,
    *,
    queue_status="missing",
    readiness_status="",
    natural_gate_ready=False,
    preflight_status="pass",
):
    return {
        "card_name": name,
        "cmc": 3,
        "role": "pressure_safe_spell_payoff",
        "preflight_status": preflight_status,
        "hypothesis_queue_overlay": {
            "hypothesis_queue_status": queue_status,
            "readiness_status": readiness_status,
            "natural_gate_ready": natural_gate_ready,
        },
    }


def _contract(cards):
    return {
        "summary": {
            "decision_status": "preflight_pass_cut_pool_required",
            "natural_gate_ready_from_hypothesis_queue": 0,
        },
        "primary_package_preflight": cards,
    }


def _cut_pool(*, gate_ready_cut_count=0, natural_ready_count=0, diagnostic_cut_count=0):
    return {
        "summary": {
            "gate_ready_cut_count": gate_ready_cut_count,
            "contract_natural_gate_ready_from_hypothesis_queue": natural_ready_count,
        },
        "diagnostic_tradeoff_cut_plan": {
            "eligible_diagnostic_cut_count": diagnostic_cut_count,
        },
    }


def _build(contract, cut_pool):
    return router.build_report(
        contract_report=contract,
        cut_pool_report=cut_pool,
        contract_path=Path("/tmp/contract.json"),
        cut_pool_path=Path("/tmp/cut_pool.json"),
    )


def _current_contract():
    return _contract(
        [
            _pressure_card("Monastery Mentor"),
            _pressure_card("Young Pyromancer"),
            _pressure_card("Guttersnipe"),
            _pressure_card(
                "Storm-Kiln Artist",
                queue_status="present",
                readiness_status="blocked_prior_reject",
            ),
        ]
    )


def test_current_zero_cut_capacity_blocks_singletons_and_pairs():
    payload = _build(_current_contract(), _cut_pool())

    assert payload["summary"]["decision_status"] == (
        "smaller_pressure_packages_blocked_current_607"
    )
    assert payload["summary"]["package_count"] == 10
    assert payload["summary"]["singleton_package_count"] == 4
    assert payload["summary"]["pair_package_count"] == 6
    assert payload["summary"]["gate_ready_package_count"] == 0
    assert payload["summary"]["diagnostic_only_package_count"] == 0
    assert payload["summary"]["best_singleton_learning_package"] == (
        "pressure_1_card_young_pyromancer"
    )
    assert all(row["status"] == "blocked_no_cut_or_hypothesis_capacity" for row in payload["packages"])


def test_synthetic_singleton_gate_ready_requires_structure_matrix():
    payload = _build(
        _contract(
            [
                _pressure_card(
                    "Young Pyromancer",
                    queue_status="present",
                    readiness_status="ready",
                    natural_gate_ready=True,
                )
            ]
        ),
        _cut_pool(gate_ready_cut_count=1, natural_ready_count=1),
    )

    assert payload["summary"]["decision_status"] == "smaller_pressure_package_gate_ready"
    assert payload["summary"]["gate_ready_package_count"] == 1
    assert payload["packages"][0]["package_key"] == "pressure_1_card_young_pyromancer"
    assert payload["packages"][0]["status"] == "gate_ready_requires_structure_matrix"
    assert payload["packages"][0]["blockers"] == []


def test_pair_stays_blocked_when_only_one_safe_cut_exists():
    payload = _build(
        _contract(
            [
                _pressure_card(
                    "Young Pyromancer",
                    queue_status="present",
                    readiness_status="ready",
                    natural_gate_ready=True,
                ),
                _pressure_card(
                    "Guttersnipe",
                    queue_status="present",
                    readiness_status="ready",
                    natural_gate_ready=True,
                ),
            ]
        ),
        _cut_pool(gate_ready_cut_count=1, natural_ready_count=2),
    )

    pair = next(row for row in payload["packages"] if row["required_cut_count"] == 2)

    assert pair["package_key"] == "pressure_2_card_young_pyromancer_guttersnipe"
    assert pair["status"] == "blocked_no_cut_or_hypothesis_capacity"
    assert "insufficient_seed_safe_cut_capacity" in pair["blockers"]


def test_prior_reject_storm_kiln_stays_lower_priority_and_blocked():
    payload = _build(_current_contract(), _cut_pool())
    storm = next(
        row
        for row in payload["packages"]
        if row["package_key"] == "pressure_1_card_storm_kiln_artist"
    )

    assert "blocked_prior_reject" in storm["blockers"]
    assert payload["summary"]["best_singleton_learning_package"] != storm["package_key"]


def test_markdown_surfaces_external_support_and_no_mutation():
    payload = _build(_current_contract(), _cut_pool())
    markdown = router.render_markdown(payload)

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger" in markdown
