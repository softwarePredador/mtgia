from pathlib import Path

import lorehold_external_shell_gate_synthesis as synthesis


def _gate_rows(baseline_wins=8, candidate_wins=3, baseline_winota=1, candidate_winota=0):
    return {
        "candidate_key": "challenger_shell",
        "candidate_minus_607_wins": candidate_wins - baseline_wins,
        "candidate_minus_607_winota_wins": candidate_winota - baseline_winota,
        "rows": {
            "deck_607": {
                "counts": {"win": baseline_wins, "loss": 16, "stall": 0, "total": 24},
                "winota_counts": {
                    "win": baseline_winota,
                    "loss": 2,
                    "stall": 0,
                    "total": 3,
                },
            },
            "challenger_shell": {
                "counts": {"win": candidate_wins, "loss": 21, "stall": 0, "total": 24},
                "winota_counts": {
                    "win": candidate_winota,
                    "loss": 3,
                    "stall": 0,
                    "total": 3,
                },
            },
        },
    }


def test_shell_decision_rejects_confirmed_loss_before_smoke_or_structure():
    assert (
        synthesis.shell_decision(
            baseline_rank=1,
            candidate_rank=4,
            smoke_gate={"candidate_minus_607_wins": 2},
            confirm_gate=_gate_rows(),
        )
        == "reject_confirmed_lost_to_607"
    )


def test_signal_exactly_covered_by_nonpromotable_shell_stays_learning_only():
    shells = [
        {
            "shell_slug": "conversion",
            "candidate_key": "challenger_conversion",
            "cards": ["Aetherflux Reservoir", "Underworld Breach", "Wheel of Fortune"],
            "decision": "not_promotable_structure_below_607",
            "candidate_rank": 4,
            "baseline_rank": 1,
        }
    ]
    signal = {
        "signal_key": "external_conversion",
        "package_key": "external_conversion",
        "status": "requires_separate_full_shell_contract",
        "contract_path": "full_shell",
        "missing_add_cards": [
            "Aetherflux Reservoir",
            "Underworld Breach",
            "Wheel of Fortune",
        ],
    }

    row = synthesis.classify_signal_against_shells(signal, shells)

    assert row["synthesis_status"] == "covered_by_existing_nonpromotable_shell"
    assert row["recommended_action"] == "do_not_repeat_full_shell_without_new_contract_change"
    assert row["exact_coverage_count"] == 1


def test_build_report_keeps_uncovered_full_shell_as_future_contract(tmp_path: Path):
    matrix = {
        "ranked_deck_keys": ["deck_607", "challenger_shell"],
        "best_structural_deck": "deck_607",
        "decks": [
            {"deck_key": "deck_607", "role_counts": {"land": 34, "ramp": 18, "draw": 13}},
            {
                "deck_key": "challenger_shell",
                "role_counts": {"land": 33, "ramp": 18, "draw": 12},
                "strategy_score": 90.0,
                "commander_intent_score": 100.0,
            },
        ],
    }
    (tmp_path / "lorehold_from_scratch_challengers_20260703_current_test_matrix.json").write_text(
        synthesis.json.dumps(matrix),
        encoding="utf-8",
    )
    (tmp_path / "lorehold_from_scratch_challengers_20260703_current_test.decklist.txt").write_text(
        "1 Aetherflux Reservoir\n1 Wheel of Fortune\n",
        encoding="utf-8",
    )
    external = {
        "signals": [
            {
                "signal_key": "pressure",
                "status": "requires_separate_full_shell_contract",
                "contract_path": "full_shell",
                "missing_add_cards": ["Young Pyromancer", "Guttersnipe"],
            }
        ]
    }

    payload = synthesis.build_report(
        external_reconciliation=external,
        external_reconciliation_path=Path("/tmp/external.json"),
        report_dir=tmp_path,
    )

    assert payload["summary"]["promotable_shell_count"] == 0
    assert payload["summary"]["recommended_next_action"] == (
        "promote_no_shell_keep_607_and_define_smaller_diagnostics"
    )
    assert payload["signals"][0]["synthesis_status"] == "partial_or_uncovered_full_shell"
