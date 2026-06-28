import json
import sqlite3

import lorehold_variant_gap_miner as miner


def memory_db():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            cmc REAL,
            type_line TEXT,
            functional_tags_json TEXT,
            is_commander INTEGER
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            execution_status TEXT,
            review_status TEXT,
            effect_json TEXT
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE decks (
            id INTEGER,
            deck_name TEXT,
            archetype TEXT,
            total_cards INTEGER
        )
        """
    )
    conn.executemany(
        "INSERT INTO decks VALUES (?, ?, ?, ?)",
        [
            (6, "Champion", "lorehold", 100),
            (608, "Variant 608", "lorehold", 100),
            (609, "Variant 609", "lorehold", 100),
        ],
    )
    conn.executemany(
        "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [
            (6, "Safe Rock", 1, "ramp", 2, "Artifact", '["ramp"]', 0),
            (6, "Locked Core", 1, "protection", 2, "Instant", '["protection"]', 0),
            (6, "Prismari Pianist", 1, "wincon", 5, "Creature", '["wincon"]', 0),
            (608, "Candidate Ramp", 1, "ramp", 7, "Sorcery", '["ramp"]', 0),
            (608, "Candidate Bad", 1, "draw", 3, "Sorcery", '["draw"]', 0),
            (608, "Candidate Partial", 1, "ramp", 7, "Sorcery", '["ramp"]', 0),
            (608, "Candidate Protection", 1, "protection", 2, "Instant", '["protection"]', 0),
            (608, "Needs Rule", 1, "draw", 3, "Creature", '["draw"]', 0),
            (609, "Candidate Ramp", 1, "ramp", 7, "Sorcery", '["ramp"]', 0),
            (609, "Candidate Partial", 1, "ramp", 7, "Sorcery", '["ramp"]', 0),
        ],
    )
    conn.executemany(
        "INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?)",
        [
            (
                "Candidate Ramp",
                "candidate ramp",
                "auto",
                "verified",
                json.dumps({"effect": "treasure_maker"}),
            ),
            (
                "Candidate Bad",
                "candidate bad",
                "auto",
                "verified",
                json.dumps({"effect": "draw_cards"}),
            ),
            (
                "Needs Rule",
                "needs rule",
                "review_only",
                "needs_review",
                json.dumps({"effect": "draw_cards"}),
            ),
            (
                "Candidate Partial",
                "candidate partial",
                "auto",
                "verified",
                json.dumps(
                    {
                        "effect": "treasure_maker",
                        "battle_model_scope": "single_treasure_creation_v1",
                        "treasure_count": 1,
                    }
                ),
            ),
            (
                "Candidate Protection",
                "candidate protection",
                "auto",
                "verified",
                json.dumps({"effect": "counter"}),
            ),
        ],
    )
    return conn


def strategy_audit():
    return {
        "card_decision_manifest": {
            "cards": [
                {
                    "card_name": "Safe Rock",
                    "decision": "support_flex",
                    "status": "core_support",
                    "package_lane": "early_mana",
                    "effective_role": "ramp",
                },
                {
                    "card_name": "Locked Core",
                    "decision": "core_support",
                    "status": "core_support",
                    "package_lane": "protection_window",
                    "effective_role": "protection",
                },
                {
                    "card_name": "Prismari Pianist",
                    "decision": "finisher_benchmark_lane",
                    "status": "core_or_flex_engine",
                    "package_lane": "spell_chain_conversion",
                    "effective_role": "wincon",
                },
            ]
        },
        "cut_safety_manifest": {
            "cuts": [
                {
                    "card_name": "Locked Core",
                    "status": "locked_do_not_cut",
                }
            ],
            "untested_flex_pool": [
                {
                    "card_name": "Safe Rock",
                    "decision": "support_flex",
                    "status": "core_support",
                    "package_lane": "early_mana",
                    "effective_role": "ramp",
                }
            ],
        },
    }


def test_variant_gap_miner_blocks_review_only_and_marks_prior_negative(tmp_path):
    queue_path = tmp_path / "queue.json"
    queue_path.write_text(
        json.dumps(
            {
                "queue": [
                    {
                        "package_key": "bad_package",
                        "status": "tested_negative_do_not_promote",
                        "adds": ["Candidate Bad"],
                        "cuts": ["Prismari Pianist"],
                        "prior_gate": {"delta_pp": -66.67},
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    with memory_db() as conn:
        payload = miner.build_report(
            conn=conn,
            strategy_audit=strategy_audit(),
            prior_gate_paths=[queue_path],
            base_deck_id=6,
            variant_deck_ids=(608, 609),
        )

    by_card = {row["card_name"]: row for row in payload["top_variant_candidates"]}
    assert by_card["Candidate Ramp"]["status"] == "runtime_ready_unexplored"
    assert by_card["Candidate Ramp"]["active_rule_count"] == 1
    assert by_card["Candidate Bad"]["status"] == "tested_negative_add_requires_new_cut"
    assert by_card["Candidate Partial"]["status"] == "runtime_partial_needs_model_review"
    assert "single_treasure_model_review_required" in by_card["Candidate Partial"][
        "rule_quality_flags"
    ]
    assert by_card["Needs Rule"]["status"] == "blocked_runtime_rule_gap"

    cuts = {row["card_name"]: row for row in payload["cut_inventory"]}
    assert cuts["Safe Rock"]["status"] == "untested_flex_candidate"
    assert cuts["Locked Core"]["status"] == "blocked_locked_cut"
    assert cuts["Prismari Pianist"]["status"] == "tested_negative_cut"

    assert payload["pairing_hypotheses"][0]["candidate"] == "Candidate Ramp"
    assert payload["pairing_hypotheses"][0]["status"] == "gate_ready_safe_same_lane"
    assert payload["pairing_hypotheses"][0]["cut_options"][0]["card_name"] == "Safe Rock"
    assert (
        payload["pairing_hypotheses"][0]["cut_options"][0]["gate_readiness"]
        == "safe_same_lane_flex"
    )
    pairings = {row["candidate"]: row for row in payload["pairing_hypotheses"]}
    assert pairings["Candidate Protection"]["status"] == "blocked_no_safe_cut_in_lane"
    assert pairings["Candidate Protection"]["cut_options"][0]["card_name"] == "Locked Core"
    assert pairings["Candidate Protection"]["cut_options"][0]["gate_readiness"] == "blocked_cut_contract"
    assert "Candidate Partial" not in {
        row["candidate"] for row in payload["pairing_hypotheses"]
    }
    assert len(payload["all_variant_candidates"]) == 5
    all_by_card = {row["card_name"]: row for row in payload["all_variant_candidates"]}
    assert all_by_card["Needs Rule"]["status"] == "blocked_runtime_rule_gap"


def test_variant_gap_miner_imports_negative_package_gate_history(tmp_path):
    report_path = tmp_path / "package_gate.json"
    report_path.write_text(
        json.dumps(
            {
                "packages": [
                    {
                        "package_key": "negative_package",
                        "status": "gated",
                        "adds": ["Candidate Ramp"],
                        "cuts": ["Safe Rock"],
                        "gate_summary": {"delta_pp": -12.5},
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    history = miner.load_prior_gate_reports([report_path])

    assert history["negative_adds"]["candidate ramp"][0]["package_key"] == "negative_package"
    assert history["negative_cuts"]["safe rock"][0]["package_key"] == "negative_package"
