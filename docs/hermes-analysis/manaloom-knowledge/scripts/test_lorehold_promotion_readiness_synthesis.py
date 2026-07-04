import json
import sqlite3
from pathlib import Path

import lorehold_promotion_readiness_synthesis as synth


def make_conn(*, total_cards: int = 100) -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            is_commander INTEGER
        );
        """
    )
    conn.execute(
        "INSERT INTO deck_cards VALUES (607, 'Lorehold, the Historian', 1, 1)"
    )
    conn.execute(
        "INSERT INTO deck_cards VALUES (607, 'Library of Leng', ?, 0)",
        (total_cards - 1,),
    )
    return conn


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def report_paths(tmp_path: Path, *, ready_candidate: bool = False, role_watch: bool = True) -> dict[str, Path]:
    card_value_payload = {
        "status": "card_value_priority_keep_607_with_role_watch_items",
        "summary": {
            "total_cards": 100,
            "ready_replacement_candidate_count": 0,
            "role_mapping_watch_count": 1 if role_watch else 0,
        },
        "candidate_replacement_pressure": {
            "ready_candidates": [
                {"card_name": "Replacement", "decision": "direct_swap_ready"}
            ]
            if ready_candidate
            else []
        },
        "role_mapping_watch_items": [
            {
                "card_name": "Redirect Lightning",
                "functional_tag": "draw",
                "primary_value_lane": "interaction_removal",
                "role_mapping_watch": ["draw_tag_masks_interaction_or_protection_function"],
                "cut_policy": "same_lane_only_with_card_use_and_equal_gate",
            }
        ]
        if role_watch
        else [],
    }
    paths = {
        "card_value": write_json(tmp_path / "card_value.json", card_value_payload),
        "mana": write_json(
            tmp_path / "mana.json",
            {
                "status": "mana_sequence_no_direct_auto_upgrade_current_607",
                "summary": {"total_cards": 100},
                "candidate_mana_backlog": [
                    {"card_name": "Mana Vault", "decision": "blocked_prior_gate_rejected", "lane": "ramp"}
                ],
            },
        ),
        "staple": write_json(
            tmp_path / "staple.json",
            {
                "status": "staple_policy_no_direct_auto_include_current_607",
                "summary": {"total_cards": 100},
                "candidate_staple_backlog": [
                    {
                        "card_name": "The One Ring",
                        "decision": "candidate_requires_same_lane_cut_and_gate",
                        "lane": "card_draw_selection",
                    }
                ],
            },
        ),
        "selection": write_json(
            tmp_path / "selection.json",
            {
                "status": "selection_access_no_swap_ready_current_607",
                "summary": {"total_cards": 100},
                "candidate_access_cards": [
                    {
                        "card_name": "Brainstone",
                        "decision": "runtime_ready_but_no_seed_safe_cut",
                        "access_model": {"lane": "topdeck_setup"},
                    }
                ],
            },
        ),
        "interaction": write_json(
            tmp_path / "interaction.json",
            {
                "status": "interaction_resilience_no_direct_swap_ready_current_607",
                "summary": {"total_cards": 100},
                "candidate_profiles": [
                    {
                        "card_name": "Boros Charm",
                        "decision": "prior_tibalt_replacement_rejected",
                        "lane": "stack_or_spell_protection",
                    }
                ],
            },
        ),
        "payoff": write_json(
            tmp_path / "payoff.json",
            {
                "status": "payoff_finisher_recursion_no_direct_swap_ready_current_607",
                "summary": {"total_cards": 100},
                "candidate_cards": [
                    {
                        "card_name": "Soulfire Eruption",
                        "decision": "blocked_existing_soulfire_shell_underperformed",
                        "lane": "payoffs_finishers",
                    }
                ],
            },
        ),
        "pressure": write_json(
            tmp_path / "pressure.json",
            {
                "status": "pressure_tradeoff_diagnostic_only_keep_607",
                "summary": {
                    "promotion_allowed": False,
                    "gate_ready_plan_complete": False,
                    "natural_cards_with_trigger_signal": 2,
                },
                "candidate_cards": [
                    {
                        "card_name": "Guttersnipe",
                        "decision": "hypothesis_natural_trigger_signal_but_full_package_regressed_miracle",
                        "lane": "pressure_payoff",
                    },
                    {
                        "card_name": "Monastery Mentor",
                        "decision": "blocked_no_natural_card_use_in_pressure_smoke",
                        "lane": "pressure_payoff",
                    },
                ],
            },
        ),
    }
    return paths


def build_payload(tmp_path: Path, *, ready_candidate: bool = False, role_watch: bool = True, total_cards: int = 100) -> dict:
    paths = report_paths(tmp_path, ready_candidate=ready_candidate, role_watch=role_watch)
    with make_conn(total_cards=total_cards) as conn:
        return synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            card_value_report_path=paths["card_value"],
            mana_report_path=paths["mana"],
            staple_report_path=paths["staple"],
            selection_report_path=paths["selection"],
            interaction_report_path=paths["interaction"],
            payoff_report_path=paths["payoff"],
            pressure_report_path=paths["pressure"],
        )


def test_baseline_keeps_607_when_no_candidate_is_ready(tmp_path):
    payload = build_payload(tmp_path)

    assert payload["status"] == "promotion_readiness_keep_607_no_candidate_ready"
    assert payload["decision"]["keep_607_as_protected_baseline"] is True
    assert payload["decision"]["promotion_allowed"] is False
    assert payload["summary"]["gate_ready_candidate_count"] == 0
    assert payload["summary"]["unique_candidate_count"] == 7
    assert payload["deck_shape"]["deck_shape_ok"] is True


def test_candidate_ready_requires_gate_review_not_promotion(tmp_path):
    payload = build_payload(tmp_path, ready_candidate=True)

    assert payload["status"] == "promotion_readiness_candidate_requires_gate_review"
    assert payload["summary"]["gate_ready_candidate_count"] == 1
    assert payload["decision"]["keep_607_as_protected_baseline"] is True
    assert payload["decision"]["promotion_allowed"] is False
    assert payload["candidate_pressure"]["gate_ready_candidates"][0]["card_name"] == "Replacement"


def test_candidate_classification_splits_blocked_and_hypotheses(tmp_path):
    payload = build_payload(tmp_path)
    counts = payload["candidate_pressure"]["classification_counts"]

    assert counts["blocked_or_rejected"] == 4
    assert counts["hypothesis_or_gate_needed"] == 3
    assert payload["summary"]["role_mapping_watch_count"] == 1


def test_bad_deck_shape_marks_source_evidence_incomplete(tmp_path):
    payload = build_payload(tmp_path, role_watch=False, total_cards=99)

    assert payload["status"] == "promotion_readiness_incomplete_source_evidence"
    assert payload["deck_shape"]["deck_shape_ok"] is False
    checklist = {row["gate"]: row for row in payload["promotion_gate_checklist"]}
    assert checklist["baseline_deck_shape"]["passed"] is False


def test_markdown_surfaces_learning_model_and_sources(tmp_path):
    payload = build_payload(tmp_path)
    markdown = synth.render_markdown(payload)

    assert "Lorehold Promotion Readiness Synthesis" in markdown
    assert "keep_607_as_protected_baseline: `true`" in markdown
    assert "Mana Vault is not blocked by Commander legality" in markdown
    assert "Pressure payoffs are valid hypotheses" in markdown
    assert "Scryfall The One Ring API" in markdown
