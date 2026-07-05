from pathlib import Path

import lorehold_same_lane_microbenchmark_decision_synthesis as synthesis


def benchmark_report():
    return {
        "summary": {
            "profiled_cut_count": 2,
            "supported_cut_count": 2,
            "pair_evaluation_count": 540,
            "preflight_ready_pair_count": 1,
            "selected_package_count": 1,
        },
        "selected_pairs": [
            {
                "package_key": "possibility_storm_same_lane_benchmark_cut_creative_technique",
                "candidate": "Possibility Storm",
                "cut": "Creative Technique",
                "candidate_role": "big_spell_value",
                "cut_role": "big_spell_value",
                "status": "preflight_ready",
                "score": 96,
            }
        ],
        "top_pair_evaluations": [
            {
                "package_key": "mana_vault_same_lane_benchmark_cut_bender_s_waterskin",
                "candidate": "Mana Vault",
                "cut": "Bender's Waterskin",
                "candidate_role": "ramp",
                "cut_role": "ramp",
                "status": "blocked",
                "score": 112,
                "blockers": ["prior_exact_reject"],
            }
        ],
    }


def gate_report(*, forced_access_mode="none", baseline_results=None, candidate_results=None):
    baseline_results = baseline_results or ["win", "win", "loss", "loss"]
    candidate_results = candidate_results or ["win", "loss", "loss", "loss"]
    return {
        "status": "ready",
        "results": [
            {
                "deck_key": "deck_607",
                "forced_access_mode": forced_access_mode,
                "game_results": [
                    {
                        "result": result,
                        "focus_card_trace_card_counts": {"Creative Technique": 1},
                        "card_event_counts": {},
                    }
                    for result in baseline_results
                ],
            },
            {
                "deck_key": "synergy_possibility_storm_same_lane_benchmark_cut_creative_technique",
                "forced_access_mode": forced_access_mode,
                "game_results": [
                    {
                        "result": result,
                        "focus_card_trace_card_counts": {"Possibility Storm": 1},
                        "card_event_counts": {"spell_cast:Possibility Storm": 1},
                    }
                    for result in candidate_results
                ],
            },
        ],
    }


def test_static_ready_prior_natural_reject_keeps_607():
    payload = synthesis.build_payload(
        benchmark=benchmark_report(),
        benchmark_path=Path("/tmp/benchmark.json"),
        prior_gate_payloads=[
            (Path("/tmp/natural.json"), gate_report()),
            (
                Path("/tmp/forced.json"),
                gate_report(
                    forced_access_mode="opening_hand",
                    baseline_results=["loss", "loss"],
                    candidate_results=["win", "loss"],
                ),
            ),
        ],
    )

    assert payload["status"] == "same_lane_static_ready_prior_natural_rejected_keep_607"
    assert payload["summary"]["prior_natural_reject_count"] == 1
    assert payload["summary"]["forced_access_signal_count"] == 1
    assert payload["summary"]["natural_battle_allowed_now"] is False
    assert payload["decision"]["promotion_allowed"] is False
    assert payload["candidate_decisions"][0]["decision"] == "static_ready_but_prior_natural_rejected"


def test_bender_queue_is_reported_as_blocked_by_prior_reject():
    payload = synthesis.build_payload(
        benchmark=benchmark_report(),
        benchmark_path=Path("/tmp/benchmark.json"),
        prior_gate_payloads=[(Path("/tmp/natural.json"), gate_report())],
    )

    assert payload["summary"]["bender_waterskin_ready_pair_count"] == 0
    assert payload["bender_waterskin_blocked_queue"][0]["candidate"] == "Mana Vault"
    assert payload["bender_waterskin_blocked_queue"][0]["blockers"] == ["prior_exact_reject"]


def test_markdown_surfaces_decision_and_prior_gate_evidence():
    payload = synthesis.build_payload(
        benchmark=benchmark_report(),
        benchmark_path=Path("/tmp/benchmark.json"),
        prior_gate_payloads=[(Path("/tmp/natural.json"), gate_report())],
    )
    markdown = synthesis.render_markdown(payload)

    assert "Lorehold Same-Lane Microbenchmark Decision Synthesis" in markdown
    assert "static_ready_but_prior_natural_rejected" in markdown
    assert "Mana Vault" in markdown
