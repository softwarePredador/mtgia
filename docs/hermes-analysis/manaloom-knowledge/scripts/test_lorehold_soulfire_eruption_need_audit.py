import sqlite3
from pathlib import Path

import lorehold_soulfire_eruption_need_audit as audit


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
            functional_tags_json TEXT,
            type_line TEXT,
            cmc REAL,
            is_commander INTEGER,
            oracle_text TEXT
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT,
            name TEXT,
            mana_cost TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE battle_card_rules (
            normalized_name TEXT,
            logical_rule_key TEXT,
            card_name TEXT,
            effect_json TEXT,
            deck_role_json TEXT,
            source TEXT,
            confidence REAL,
            review_status TEXT,
            execution_status TEXT,
            rule_version INTEGER,
            oracle_hash TEXT,
            notes TEXT,
            created_at TEXT,
            updated_at TEXT,
            last_seen_at TEXT
        )
        """
    )
    deck_rows = [
        (607, "Lorehold, the Historian", 1, "engine", '["engine"]', "Legendary Creature", 5, 1, ""),
        (607, "Creative Technique", 1, "draw", '["draw"]', "Sorcery", 5, 0, ""),
        (607, "Starfall Invocation", 1, "board_wipe", '["board_wipe","wipe"]', "Sorcery", 5, 0, ""),
        (607, "Approach of the Second Sun", 1, "wincon", '["wincon"]', "Sorcery", 7, 0, ""),
        (607, "Swords to Plowshares", 1, "removal", '["removal"]', "Instant", 1, 0, ""),
        (607, "Sol Ring", 1, "ramp", '["ramp"]', "Artifact", 1, 0, ""),
        (613, "Soulfire Eruption", 1, "draw", '["draw","removal","deal_damage"]', "Sorcery", 9, 0, ""),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", deck_rows)
    oracle_rows = [
        (
            "soulfire eruption",
            "Soulfire Eruption",
            "{6}{R}{R}{R}",
            "Sorcery",
            "Choose any number of targets. Exile cards and deal damage.",
            9,
        ),
        ("creative technique", "Creative Technique", "{4}{R}", "Sorcery", "", 5),
        ("starfall invocation", "Starfall Invocation", "{3}{W}{W}", "Sorcery", "", 5),
    ]
    conn.executemany("INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?)", oracle_rows)
    rule_rows = [
        (
            "soulfire eruption",
            "rule:soulfire",
            "Soulfire Eruption",
            '{"effect":"deal_damage","battle_model_scope":"multi_target_exile_damage_average_single_target_v1"}',
            "{}",
            "curated",
            1,
            "active",
            "auto",
            1,
            "",
            "",
            "",
            "",
            "",
        ),
        (
            "starfall invocation",
            "rule:starfall",
            "Starfall Invocation",
            '{"effect":"board_wipe","battle_model_scope":"destroy_all_creatures_v1"}',
            "{}",
            "curated",
            1,
            "verified",
            "auto",
            1,
            "",
            "",
            "",
            "",
            "",
        ),
        (
            "creative technique",
            "rule:creative",
            "Creative Technique",
            '{"effect":"exile_top_nonland_free_cast","battle_model_scope":"shuffle_reveal_top_nonland_exile_free_cast_with_demonstrate_v1"}',
            "{}",
            "curated",
            1,
            "verified",
            "auto",
            1,
            "",
            "",
            "",
            "",
            "",
        ),
    ]
    conn.executemany("INSERT INTO battle_card_rules VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", rule_rows)
    return conn


def test_build_audit_blocks_until_soulfire_has_use_trace():
    with memory_db() as conn:
        payload = audit.build_audit(
            conn=conn,
            deck_id=607,
            db_path=Path("memory.db"),
            exposure_profiles=[],
            trace_report_paths=[],
            max_trace_report_mb=None,
            recent_gate_reports=[],
            removal_lane_report=Path("missing.json"),
            dynamic_protected_cards=set(),
        )

    assert payload["status"] == "blocked_no_soulfire_use_trace"
    assert payload["summary"]["active_rule_count"] == 1
    assert payload["summary"]["variant_deck_count"] == 1
    assert payload["summary"]["current_607_contains_soulfire"] is False
    assert [row["card"] for row in payload["manual_review_cuts"]] == ["Starfall Invocation"]
    blocked = {row["card"]: row["blockers"] for row in payload["blocked_cut_samples"]}
    assert "cut_is_protected_anchor_or_prior_guardrail" in blocked["Creative Technique"]


def test_collect_card_events_from_paths_prefilters_and_counts_use_events(tmp_path):
    matching = tmp_path / "matching.json"
    matching.write_text(
        """
        {
          "events": [
            {
              "event": "cost_paid",
              "data": {
                "card": "Soulfire Eruption",
                "turn": 6,
                "phase": "main"
              }
            },
            {
              "event": "card_reference",
              "name": "Soulfire Eruption"
            },
            {
              "spell_resolved:Soulfire Eruption": 2
            },
            {
              "key": "miracle_cast:Soulfire Eruption",
              "count": 1
            }
          ]
        }
        """,
        encoding="utf-8",
    )
    no_target = tmp_path / "no_target.json"
    no_target.write_text('{"event":"cost_paid","data":{"card":"Other"}}', encoding="utf-8")

    result = audit.collect_card_events_from_paths(
        [matching, no_target],
        "Soulfire Eruption",
    )

    assert result["event_counts"] == {
        "card_reference": 1,
        "cost_paid": 1,
        "miracle_cast": 1,
        "spell_resolved": 2,
    }
    assert result["use_event_counts"] == {
        "cost_paid": 1,
        "miracle_cast": 1,
        "spell_resolved": 2,
    }
    assert result["scan_summary"]["candidate_report_count"] == 2
    assert result["scan_summary"]["parsed_report_count"] == 1
    assert result["scan_summary"]["skipped_no_target_marker_count"] == 1


def test_cut_review_does_not_replace_cheap_interaction_with_soulfire():
    card = {
        "name": "Swords to Plowshares",
        "functional_tag": "removal",
        "functional_tags": ["removal"],
        "type_line": "Instant",
        "cmc": 1,
        "is_commander": False,
    }
    row = audit.cut_review(card, {}, {}, set())

    assert row["status"] == "blocked"
    assert "cut_not_soulfire_lane" in row["blockers"]
    assert "cut_removes_cheap_interaction_for_nine_mana_spell" in row["blockers"]
