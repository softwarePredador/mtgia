from pathlib import Path

import lorehold_miracle_trace_failure_miner as miner


def gate_sample():
    return {
        "status": "completed",
        "results": [
            {
                "deck_key": miner.BASELINE_KEY,
                "wins": 1,
                "losses": 1,
                "stalls": 0,
                "games": 2,
                "opponents": [{"opponent": miner.FIXED_607_OPPONENT, "wins": 0, "losses": 0, "stalls": 0}],
                "telemetry": {
                    "strategic_event_counts": {
                        "miracle_cast": 4,
                        "topdeck_manipulation_activated": 3,
                        "lorehold_spell_cast": 9,
                    },
                    "strategic_games": {
                        "miracle_cast": {"games": 2},
                        "topdeck_manipulation_activated": {"games": 1},
                    },
                    "focus_card_access_summary": {
                        "Land Tax": {"accessed_games": 1, "near_access_games": 1},
                        "Scroll Rack": {"accessed_games": 1, "drawn_games": 1},
                        "Sensei's Divining Top": {"accessed_games": 1},
                    },
                },
                "game_results": [],
            },
            {
                "deck_key": "challenger_lorehold_spell_volume_access_depressure_v1",
                "wins": 0,
                "losses": 2,
                "stalls": 0,
                "games": 2,
                "opponents": [
                    {"opponent": miner.FIXED_607_OPPONENT, "wins": 0, "losses": 1, "stalls": 0},
                    {"opponent": "Winota, Joiner of Forces #39 (real)", "wins": 0, "losses": 1, "stalls": 0},
                ],
                "telemetry": {
                    "strategic_event_counts": {
                        "lorehold_spell_cast": 3,
                        "spell_cast_mana_trigger": 2,
                        "birgi_spell_cast_mana": 2,
                    },
                    "strategic_games": {
                        "miracle_cast": {"games": 0},
                        "topdeck_manipulation_activated": {"games": 0},
                    },
                    "focus_card_access_summary": {
                        "Land Tax": {"accessed_games": 0},
                        "Scroll Rack": {"accessed_games": 0},
                        "Sensei's Divining Top": {"accessed_games": 0},
                    },
                },
                "game_results": [],
            },
            {
                "deck_key": "challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1",
                "wins": 1,
                "losses": 1,
                "stalls": 0,
                "games": 2,
                "opponents": [{"opponent": miner.FIXED_607_OPPONENT, "wins": 0, "losses": 1, "stalls": 0}],
                "telemetry": {
                    "strategic_event_counts": {
                        "miracle_cast": 8,
                        "topdeck_manipulation_activated": 4,
                        "lorehold_spell_cast": 12,
                    },
                    "strategic_games": {
                        "miracle_cast": {"games": 2},
                        "topdeck_manipulation_activated": {"games": 2},
                    },
                    "focus_card_access_summary": {
                        "Land Tax": {"accessed_games": 1},
                        "Scroll Rack": {"accessed_games": 1},
                        "Sensei's Divining Top": {"accessed_games": 1},
                    },
                },
                "game_results": [],
            },
        ],
    }


def summarize_sample():
    gate = gate_sample()
    baseline = miner.gate_row(gate, miner.BASELINE_KEY)
    return [
        miner.candidate_summary(
            gate=gate,
            gate_path=Path("/tmp/gate.json"),
            baseline=baseline,
            candidate=candidate,
        )
        for candidate in miner.candidate_rows(gate)
    ]


def test_depressure_flags_missing_miracle_topdeck_and_access_regression():
    summaries = summarize_sample()
    depressure = next(item for item in summaries if "depressure" in item["candidate_key"])

    assert depressure["decision"] == "reject_current_depressure_shell"
    assert "head_to_head_not_won" in depressure["failure_flags"]
    assert "miracle_trace_missing" in depressure["failure_flags"]
    assert "topdeck_activation_missing" in depressure["failure_flags"]
    assert "topdeck_anchor_access_regressed" in depressure["failure_flags"]
    assert "mana_event_without_conversion_to_wins" in depressure["failure_flags"]
    assert depressure["promotion_allowed"] is False


def test_deoverfill_keeps_miracle_trace_but_still_blocks_promotion():
    summaries = summarize_sample()
    deoverfill = next(item for item in summaries if "deoverfill" in item["candidate_key"])

    assert deoverfill["decision"] == "do_not_promote_pressure_unproven"
    assert deoverfill["strategic_count_delta"]["miracle_cast"] == 4
    assert "miracle_trace_missing" not in deoverfill["failure_flags"]
    assert "topdeck_activation_missing" not in deoverfill["failure_flags"]
    assert "head_to_head_not_won" in deoverfill["failure_flags"]
    assert "pressure_causality_unproven" in deoverfill["failure_flags"]


def test_payload_keeps_607_protected_and_records_external_staple_boundary(tmp_path):
    gate_path = tmp_path / "gate.json"
    import json

    gate_path.write_text(json.dumps(gate_sample()), encoding="utf-8")
    payload = miner.build_payload([gate_path])

    assert payload["status"] == "lorehold_miracle_trace_failure_learning_ready"
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["summary"]["keep_607_as_protected_baseline"] is True
    assert payload["summary"]["next_shell_contract"] == "miracle_access_first_shell"
    assert payload["external_card_legality_snapshot"]["Mana Vault"]["commander"] == "legal"
    assert payload["external_card_legality_snapshot"]["The One Ring"]["color_identity"] == []
    internal = payload["internal_accessibility_snapshot"]["cards"]
    assert internal["Mana Vault"]["summary"]["in_card_oracle_cache"] is True
    assert internal["Mana Vault"]["summary"]["has_executable_runtime_rule"] is True
    assert internal["Mana Vault"]["summary"]["present_in_protected_607"] is False
    assert internal["The One Ring"]["summary"]["in_card_oracle_cache"] is True
    assert internal["The One Ring"]["summary"]["has_executable_runtime_rule"] is True


def test_markdown_surfaces_decisions_and_source_links(tmp_path):
    gate_path = tmp_path / "gate.json"
    import json

    gate_path.write_text(json.dumps(gate_sample()), encoding="utf-8")
    markdown = miner.render_markdown(miner.build_payload([gate_path]))

    assert "Lorehold Miracle Trace Failure Miner" in markdown
    assert "reject_current_depressure_shell" in markdown
    assert "Mana Vault" in markdown
    assert "https://edhrec.com/commanders/lorehold-the-historian" in markdown
    assert "Internal Accessibility Snapshot" in markdown
    assert "not_in_protected_607_and_prior_cut_battle_evidence_rejected" in markdown
