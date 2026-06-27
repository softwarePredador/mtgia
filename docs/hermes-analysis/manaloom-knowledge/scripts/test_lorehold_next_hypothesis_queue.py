import sqlite3
import json

import lorehold_synergy_package_gate as gate
import lorehold_next_hypothesis_queue as queue


def memory_db():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute("CREATE TABLE card_oracle_cache (name TEXT, normalized_name TEXT)")
    conn.execute(
        "CREATE TABLE battle_card_rules (card_name TEXT, normalized_name TEXT, execution_status TEXT)"
    )
    for name in [
        "Akroma's Will",
        "Dragon's Rage Channeler",
        "Radiant Scrollwielder",
        "Perch Protection",
        "Avatar's Wrath",
        "The Scarlet Witch",
    ]:
        conn.execute(
            "INSERT INTO card_oracle_cache (name, normalized_name) VALUES (?, ?)",
            (name, name.lower()),
        )
    conn.executemany(
        "INSERT INTO battle_card_rules (card_name, normalized_name, execution_status) VALUES (?, ?, ?)",
        [
            ("Akroma's Will", "akroma's will", "auto"),
            ("Dragon's Rage Channeler", "dragon's rage channeler", "auto"),
            ("Radiant Scrollwielder", "radiant scrollwielder", "review_only"),
            ("Perch Protection", "perch protection", "auto"),
        ],
    )
    return conn


def report_payload():
    def cards(names):
        return [{"card_name": name} for name in names]

    return {
        "deck_summaries": {
            "607": {"cards": cards(["Avatar's Wrath", "The Scarlet Witch"])},
            "614": {
                "cards": cards(
                    [
                        "Akroma's Will",
                        "Dragon's Rage Channeler",
                        "Radiant Scrollwielder",
                    ]
                )
            },
            "615": {"cards": cards(["Perch Protection"])},
        },
        "card_decision_manifest": {
            "cards": [
                {
                    "card_name": "Avatar's Wrath",
                    "decision": "core_support",
                    "status": "ready",
                    "package_lane": "protection_window",
                    "effective_role": "protection",
                },
                {
                    "card_name": "The Scarlet Witch",
                    "decision": "unresolved_before_cut",
                    "status": "unresolved_rule_or_aggregate_gap",
                    "package_lane": "contextual",
                    "effective_role": "unknown",
                },
            ]
        },
        "strategy_dependency_map": {
            "cut_guardrails": {
                "locked_or_protected": [],
                "risky_same_lane_only": [],
            },
            "next_hypothesis_contract": {
                "hard_reject_if": ["candidate depends on a card with unresolved battle runtime/model evidence"],
            },
        },
    }


def test_lookup_forms_match_apostrophe_names_and_review_only_is_not_active():
    with memory_db() as conn:
        oracle = queue.oracle_presence(conn, ["Akroma's Will", "Dragon's Rage Channeler"])
        rules = queue.active_rule_counts(
            conn,
            ["Akroma's Will", "Dragon's Rage Channeler", "Radiant Scrollwielder"],
        )

    assert oracle["Akroma's Will"] is True
    assert oracle["Dragon's Rage Channeler"] is True
    assert rules["Akroma's Will"] == 1
    assert rules["Dragon's Rage Channeler"] == 1
    assert rules["Radiant Scrollwielder"] == 0


def test_build_queue_marks_runtime_ready_and_review_only_packages():
    with memory_db() as conn:
        result = queue.build_queue(report_payload(), conn)

    by_key = {row["package_key"]: row for row in result["queue"]}
    assert by_key["akromas_will_cut_avatar_wrath"]["status"] == "gate_ready"
    assert by_key["dragon_rage_channeler_cut_scarlet_witch"]["status"] == "needs_manual_review"
    assert by_key["radiant_scrollwielder_cut_scarlet_witch"]["status"] == "blocked_runtime_rule_gap"
    assert "missing_active_rule:Radiant Scrollwielder" in by_key[
        "radiant_scrollwielder_cut_scarlet_witch"
    ]["blockers"]
    assert "cut_has_unresolved_rule:The Scarlet Witch" in by_key[
        "radiant_scrollwielder_cut_scarlet_witch"
    ]["blockers"]


def test_gate_runner_contains_queue_ready_package_definitions():
    for package_key in [
        "perch_protection_cut_avatar_wrath",
        "akromas_will_cut_avatar_wrath",
        "silence_cut_avatar_wrath",
        "dragon_rage_channeler_cut_scarlet_witch",
        "grand_abolisher_cut_mother_of_runes",
        "reprieve_cut_avatar_wrath",
    ]:
        assert package_key in gate.PACKAGE_DEFINITIONS
        assert gate.PACKAGE_DEFINITIONS[package_key]["adds"]
        assert gate.PACKAGE_DEFINITIONS[package_key]["cuts"]


def test_prior_negative_gate_demotes_package_from_ready_queue(tmp_path):
    gate_path = tmp_path / "gate.json"
    gate_path.write_text(
        json.dumps(
            {
                "packages": [
                    {
                        "package_key": "perch_protection_cut_avatar_wrath",
                        "status": "gated",
                        "candidate_meta": {"added_rule_counts": {"Perch Protection": 1}},
                        "gate_summary": {
                            "baseline": {"wins": 3, "losses": 0},
                            "candidate": {"wins": 1, "losses": 2},
                            "delta_pp": -66.67,
                        },
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    with memory_db() as conn:
        result = queue.build_queue(report_payload(), conn, [gate_path])

    by_key = {row["package_key"]: row for row in result["queue"]}
    assert by_key["perch_protection_cut_avatar_wrath"]["status"] == "tested_negative_do_not_promote"
    assert by_key["perch_protection_cut_avatar_wrath"]["prior_gate"]["candidate_wins"] == 1
    assert result["summary"]["tested_negative_count"] == 1
