import argparse
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

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


def test_parse_package_keys_accepts_external_package_definition():
    definitions = {
        "external_profiled_cut": {
            "hypothesis": "benchmark",
            "adds": ["Lightning Bolt"],
            "cuts": ["Winds of Abandon"],
        }
    }

    assert matrix.parse_package_keys("external_profiled_cut", package_definitions=definitions) == [
        "external_profiled_cut"
    ]


def test_run_package_seed_forwards_external_package_file():
    with patch("lorehold_synergy_seed_matrix.subprocess.run") as run:
        run.return_value = SimpleNamespace(returncode=0, stdout="", stderr="")
        matrix.run_package_seed(
            package_key="external_profiled_cut",
            seed=7,
            source_db=Path("/tmp/source.db"),
            games=1,
            opponent_limit=1,
            opponent_seed=20260626,
            game_timeout_seconds=1.0,
            deck_process_timeout_seconds=1.0,
            gate_timeout_seconds=1.0,
            stem="test_matrix",
            stamp="stamp",
            cut_safety_report=None,
            prior_package_reports=[],
            package_files=[Path("/tmp/packages.json")],
            ignore_prior_results=True,
            no_game_checkpoint=True,
        )

    cmd = run.call_args.args[0]
    assert "--package-file" in cmd
    assert "/tmp/packages.json" in cmd


def test_run_package_seed_uses_short_package_token_for_long_names():
    package_key = "witch_enchanter_witch_blessed_meadow_same_lane_benchmark_cut_winds_of_abandon"
    with patch("lorehold_synergy_seed_matrix.subprocess.run") as run:
        run.return_value = SimpleNamespace(returncode=0, stdout="", stderr="")
        matrix.run_package_seed(
            package_key=package_key,
            seed=42,
            source_db=Path("/tmp/source.db"),
            games=1,
            opponent_limit=1,
            opponent_seed=20260626,
            game_timeout_seconds=1.0,
            deck_process_timeout_seconds=1.0,
            gate_timeout_seconds=1.0,
            stem="test_matrix",
            stamp="20260628_091040",
            cut_safety_report=None,
            prior_package_reports=[],
            package_files=[],
            ignore_prior_results=True,
            no_game_checkpoint=True,
        )

    cmd = run.call_args.args[0]
    stem_value = cmd[cmd.index("--stem") + 1]
    stamp_value = cmd[cmd.index("--stamp") + 1]
    assert package_key not in stem_value
    assert len(stem_value) < 90
    assert stamp_value == "20260628_091040"


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
