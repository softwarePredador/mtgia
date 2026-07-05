from pathlib import Path

import lorehold_current_best_baseline_synthesis as synthesis


def _artifact_audit(*, unknown=0):
    return {
        "summary": {"artifact_count": 10, "unknown_or_invalid_count": unknown},
        "continuation_gate": {
            "artifact_contract_status": "pass" if unknown == 0 else "fail",
            "can_run_equal_battle_gate": unknown == 0,
            "ready_for_real_deck_change": False,
        },
    }


def _matrix():
    return {
        "ranked_deck_keys": ["deck_607", "deck_615", "deck_614"],
        "decks": [
            {"deck_key": "deck_607", "strategy_score": 141.2},
            {"deck_key": "deck_615", "strategy_score": 134.8},
            {"deck_key": "deck_614", "strategy_score": 131.7},
        ],
    }


def _cut_methodology(*, overrides=True):
    return {
        "decision": {
            "current_candidate_status": (
                "battle_cleared_with_cut_methodology_caveat"
                if overrides
                else "promote_challenger"
            ),
            "ready_for_real_deck_change": False if overrides else True,
            "summary": "methodology caveat",
        }
    }


def _planner():
    return {
        "summary": {
            "matrix_candidate_row_eligible_count": 0,
            "safe_cut_ready_count": 0,
            "candidate_deck_materialization_allowed_now": False,
            "promotion_allowed_now": False,
            "floor_trace_cut_blocker_count": 6,
        }
    }


def _floor_miner():
    return {"summary": {"target_with_floor_trace_count": 6}}


def _paths():
    return {
        "artifact_audit": Path("/tmp/artifact.json"),
        "strategy_matrix": Path("/tmp/matrix.json"),
        "cut_methodology_reaudit": Path("/tmp/cut.json"),
        "sidecar_cut_planner": Path("/tmp/planner.json"),
        "gap_floor_trace_miner": Path("/tmp/floor.json"),
    }


def test_current_best_keeps_607_when_only_positive_signal_is_overridden(tmp_path):
    positive = tmp_path / "lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.json"
    positive.write_text(
        '{"decision":{"ready_for_real_deck_change":true},"status":"pass"}',
        encoding="utf-8",
    )
    payload = synthesis.build_report(
        artifact_audit=_artifact_audit(),
        strategy_matrix=_matrix(),
        cut_methodology=_cut_methodology(overrides=True),
        sidecar_cut_planner=_planner(),
        gap_floor_trace_miner=_floor_miner(),
        paths=_paths(),
        report_dir=tmp_path,
    )

    assert payload["status"] == "current_best_baseline_synthesis_keep_607"
    assert payload["summary"]["current_positive_signal_count"] == 0
    assert payload["summary"]["overridden_historical_positive_signal_count"] == 1
    assert payload["decision"]["keep_607_as_current_best_baseline"] is True
    assert payload["decision"]["deck_action_allowed"] is False


def test_current_best_blocks_when_positive_signal_is_not_overridden(tmp_path):
    positive = tmp_path / "lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.json"
    positive.write_text(
        '{"decision":{"ready_for_real_deck_change":true},"status":"pass"}',
        encoding="utf-8",
    )
    payload = synthesis.build_report(
        artifact_audit=_artifact_audit(),
        strategy_matrix=_matrix(),
        cut_methodology=_cut_methodology(overrides=False),
        sidecar_cut_planner=_planner(),
        gap_floor_trace_miner=_floor_miner(),
        paths=_paths(),
        report_dir=tmp_path,
    )

    assert payload["status"] == "current_best_baseline_synthesis_blocked_review_required"
    assert payload["summary"]["current_positive_signal_count"] == 1
    assert "current positive promotion/materialization signals remain" in payload["validation"]["errors"]


def test_current_best_blocks_when_artifact_contract_has_unknowns(tmp_path):
    payload = synthesis.build_report(
        artifact_audit=_artifact_audit(unknown=2),
        strategy_matrix=_matrix(),
        cut_methodology=_cut_methodology(),
        sidecar_cut_planner=_planner(),
        gap_floor_trace_miner=_floor_miner(),
        paths=_paths(),
        report_dir=tmp_path,
    )

    assert payload["validation"]["status"] == "fail"
    assert "artifact contract is not pass" in payload["validation"]["errors"]
    assert "artifact audit still has unknown or invalid artifacts" in payload["validation"]["errors"]


def test_markdown_surfaces_overridden_signal(tmp_path):
    positive = tmp_path / "lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.json"
    positive.write_text(
        '{"decision":{"ready_for_real_deck_change":true},"status":"pass"}',
        encoding="utf-8",
    )
    markdown = synthesis.render_markdown(
        synthesis.build_report(
            artifact_audit=_artifact_audit(),
            strategy_matrix=_matrix(),
            cut_methodology=_cut_methodology(),
            sidecar_cut_planner=_planner(),
            gap_floor_trace_miner=_floor_miner(),
            paths=_paths(),
            report_dir=tmp_path,
        )
    )

    assert "Current positive signal count: `0`" in markdown
    assert "lorehold_ideal_candidate_decision_audit_20260629_v615_mana_engine_v1.json" in markdown
    assert "keep_607_as_current_best_baseline: `true`" in markdown
