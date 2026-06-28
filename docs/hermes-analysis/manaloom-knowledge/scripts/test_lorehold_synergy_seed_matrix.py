import argparse

import lorehold_synergy_seed_matrix as matrix


def gate_summary(baseline_wins, baseline_losses, candidate_wins, candidate_losses, delta_pp):
    return {
        "baseline": {
            "games": baseline_wins + baseline_losses,
            "wins": baseline_wins,
            "losses": baseline_losses,
            "stalls": 0,
            "win_rate": 100 * baseline_wins / max(1, baseline_wins + baseline_losses),
        },
        "candidate": {
            "games": candidate_wins + candidate_losses,
            "wins": candidate_wins,
            "losses": candidate_losses,
            "stalls": 0,
            "win_rate": 100 * candidate_wins / max(1, candidate_wins + candidate_losses),
        },
        "delta_pp": delta_pp,
    }


def test_parse_int_csv_requires_at_least_one_value():
    try:
        matrix.parse_int_csv("")
    except argparse.ArgumentTypeError:
        pass
    else:
        raise AssertionError("empty seed CSV should fail")


def test_aggregate_rejects_if_strong_seed_regresses():
    rows = [
        {
            "seed": 7,
            "gate_returncode": 0,
            "gate_summary": gate_summary(0, 3, 1, 2, 33.33),
        },
        {
            "seed": 42,
            "gate_returncode": 0,
            "gate_summary": gate_summary(3, 0, 1, 2, -66.67),
        },
    ]

    aggregate = matrix.aggregate_seed_rows("example_package", rows, strong_seeds={42})

    assert aggregate["decision"] == "reject_regresses_strong_seed"
    assert aggregate["strong_seed_regressions"] == [42]


def test_aggregate_promotes_when_total_wins_improve_without_strong_regression():
    rows = [
        {
            "seed": 7,
            "gate_returncode": 0,
            "gate_summary": gate_summary(0, 3, 1, 2, 33.33),
        },
        {
            "seed": 42,
            "gate_returncode": 0,
            "gate_summary": gate_summary(3, 0, 3, 0, 0.0),
        },
    ]

    aggregate = matrix.aggregate_seed_rows("example_package", rows, strong_seeds={42})

    assert aggregate["decision"] == "promote_to_confirm_gate"
    assert aggregate["candidate_record"] == "4-2"
