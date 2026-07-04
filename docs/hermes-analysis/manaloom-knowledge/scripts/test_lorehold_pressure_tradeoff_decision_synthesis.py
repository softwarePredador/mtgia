from pathlib import Path

import lorehold_pressure_tradeoff_decision_synthesis as synth


def _resolver():
    return {
        "summary": {
            "gate_ready_cut_count": 0,
            "gate_ready_plan_complete": False,
            "natural_battle_gate_allowed_now": False,
        },
        "primary_adds": [
            "Monastery Mentor",
            "Young Pyromancer",
            "Guttersnipe",
            "Storm-Kiln Artist",
        ],
    }


def _candidate():
    return {
        "candidate_key": "candidate_607_pressure_payoff_diagnostic_tradeoff_v1",
        "diagnostic_only": True,
        "promotion_eligible": False,
        "added": [
            "Monastery Mentor",
            "Young Pyromancer",
            "Guttersnipe",
            "Storm-Kiln Artist",
        ],
        "removed": [
            "Call Forth the Tempest",
            "Tempt with Bunnies",
            "Everything Comes to Dust",
            "Rise of the Eldrazi",
        ],
        "commander_intent_alignment": {"score": 100.0},
    }


def _matrix():
    return {
        "ranked_deck_keys": [
            "candidate_607_pressure_payoff_diagnostic_tradeoff_v1",
            "deck_607",
        ],
        "decks": [
            {"deck_key": "deck_607", "strategy_score": 139.038},
            {
                "deck_key": "candidate_607_pressure_payoff_diagnostic_tradeoff_v1",
                "strategy_score": 140.901,
            },
        ],
    }


def _smoke_gate():
    return {
        "results": [
            {
                "deck_key": "deck_607",
                "wins": 3,
                "losses": 1,
                "stalls": 0,
                "win_rate": 75.0,
                "avg_win_turn": 18.67,
                "telemetry": {
                    "strategic_event_counts": {
                        "miracle_cast": 20,
                        "topdeck_manipulation_activated": 19,
                        "discard_to_top_replacement": 11,
                        "lorehold_spell_cast": 58,
                        "lorehold_upkeep_rummage": 19,
                        "static_cost_reduction_total": 22,
                    },
                    "card_event_counts": {},
                    "focus_card_access_summary": {},
                },
            },
            {
                "deck_key": "candidate_607_pressure_payoff_diagnostic_tradeoff_v1",
                "wins": 3,
                "losses": 1,
                "stalls": 0,
                "win_rate": 75.0,
                "avg_win_turn": 15.67,
                "telemetry": {
                    "strategic_event_counts": {
                        "miracle_cast": 5,
                        "topdeck_manipulation_activated": 4,
                        "discard_to_top_replacement": 3,
                        "lorehold_spell_cast": 50,
                        "lorehold_upkeep_rummage": 16,
                        "static_cost_reduction_total": 28,
                    },
                    "card_event_counts": {
                        "trigger_resolved:Guttersnipe": 7,
                        "trigger_resolved:Young Pyromancer": 6,
                        "cost_paid:Storm-Kiln Artist": 2,
                    },
                    "focus_card_access_summary": {
                        "Guttersnipe": {"accessed_games": 2, "near_access_games": 1},
                        "Young Pyromancer": {"accessed_games": 1, "near_access_games": 1},
                        "Storm-Kiln Artist": {"accessed_games": 2, "near_access_games": 2},
                        "Monastery Mentor": {"accessed_games": 0, "near_access_games": 1},
                    },
                },
            },
        ]
    }


def _forced_monastery():
    return {
        "forced_access_mode": "opening_hand",
        "results": [
            {
                "deck_key": "deck_607",
                "wins": 2,
                "losses": 1,
                "telemetry": {
                    "card_event_counts": {
                        "cost_paid:Monastery Mentor": 3,
                        "spell_cast:Monastery Mentor": 3,
                        "spell_resolved:Monastery Mentor": 3,
                    },
                    "focus_card_access_summary": {
                        "Monastery Mentor": {"accessed_games": 3, "opening_hand_games": 3}
                    },
                    "trace": [
                        {"card": "Monastery Mentor", "effect": "token_maker"},
                        {"card": "Monastery Mentor", "effect": "token_maker"},
                        {"card": "Monastery Mentor", "effect": "token_maker"},
                    ],
                },
            }
        ],
    }


def _forced_storm():
    return {
        "forced_access_mode": "opening_hand",
        "results": [
            {
                "deck_key": "deck_607",
                "wins": 1,
                "losses": 2,
                "telemetry": {
                    "card_event_counts": {"cost_paid:Storm-Kiln Artist": 3},
                    "focus_card_access_summary": {
                        "Storm-Kiln Artist": {"accessed_games": 3, "opening_hand_games": 3}
                    },
                    "trace": [{"card": "Storm-Kiln Artist", "effect": "creature"}],
                },
            }
        ],
    }


def _payload():
    return synth.build_synthesis(
        resolver=_resolver(),
        candidate=_candidate(),
        matrix=_matrix(),
        smoke_gate=_smoke_gate(),
        forced_monastery=_forced_monastery(),
        forced_storm_kiln=_forced_storm(),
        source_paths={
            "resolver": Path("/tmp/resolver.json"),
            "candidate": Path("/tmp/candidate.json"),
            "matrix": Path("/tmp/matrix.json"),
            "smoke_gate": Path("/tmp/smoke.json"),
            "forced_monastery": Path("/tmp/monastery.json"),
            "forced_storm_kiln": Path("/tmp/storm.json"),
        },
    )


def test_pressure_tradeoff_keeps_607_when_diagnostic_and_miracle_regresses():
    payload = _payload()

    assert payload["status"] == "pressure_tradeoff_diagnostic_only_keep_607"
    assert payload["decision"]["keep_607_as_protected_baseline"] is True
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["natural_smoke_gate"]["strategic_deltas"]["miracle_cast"]["delta"] == -15
    assert payload["natural_smoke_gate"]["strategic_deltas"]["topdeck_manipulation_activated"]["delta"] == -15


def test_pressure_card_rows_separate_trigger_signal_from_forced_only_signal():
    payload = _payload()
    rows = {row["card_name"]: row for row in payload["candidate_cards"]}

    assert rows["Guttersnipe"]["natural_trigger_count"] == 7
    assert rows["Young Pyromancer"]["decision"].startswith("hypothesis_natural_trigger_signal")
    assert rows["Monastery Mentor"]["decision"] == "hypothesis_natural_access_only_needs_smaller_package_or_safe_cut"
    assert payload["summary"]["forced_monastery_token_maker_count"] == 3
    assert payload["summary"]["forced_storm_kiln_treasure_like_count"] == 0


def test_markdown_surfaces_decision_reasons():
    markdown = synth.render_markdown(_payload())

    assert "Lorehold Pressure Tradeoff Decision Synthesis" in markdown
    assert "miracle regressed: `true`" in markdown
    assert "No seed-safe cut plan exists" in markdown
