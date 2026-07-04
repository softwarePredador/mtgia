import json
import sqlite3
from pathlib import Path

import lorehold_selection_access_synthesis as synth


def make_conn():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            functional_tags_json TEXT,
            is_commander INTEGER,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            card_id TEXT
        );
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT,
            mana_cost TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            card_id TEXT
        );
        CREATE TABLE card_legalities (
            card_name TEXT,
            format TEXT,
            status TEXT,
            scryfall_id TEXT
        );
        CREATE TABLE format_staples (
            card_name TEXT,
            format TEXT,
            archetype TEXT,
            category TEXT,
            color_identity TEXT,
            edhrec_rank INTEGER,
            scryfall_id TEXT,
            is_banned INTEGER
        );
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            execution_status TEXT,
            review_status TEXT,
            effect_json TEXT
        );
        """
    )
    rows = [
        (607, "Lorehold, the Historian", 1, "engine", "[]", 1, 5, "Legendary Creature", "", None),
        (607, "Sensei's Divining Top", 1, "draw", "[]", 0, 1, "Artifact", "", None),
        (607, "Scroll Rack", 1, "draw", "[]", 0, 2, "Artifact", "", None),
        (607, "Library of Leng", 1, "engine", "[]", 0, 1, "Artifact", "", None),
        (607, "Land Tax", 1, "tutor", "[]", 0, 1, "Enchantment", "", None),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
    for name in [
        "Sensei's Divining Top",
        "Scroll Rack",
        "Library of Leng",
        "Land Tax",
        "Brainstone",
        "Penance",
        "Hidden Retreat",
        "Enlightened Tutor",
        "Gamble",
    ]:
        conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal', NULL)", (name,))
        conn.execute(
            "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified', ?)",
            (name, synth.normalize_name(name), json.dumps({"battle_model_scope": "test_scope"})),
        )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Enlightened Tutor', 'commander', 'white', '', 'W', 115, NULL, 0)"
    )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Gamble', 'commander', 'red', '', 'R', 231, NULL, 0)"
    )
    return conn


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def write_edhrec(tmp_path: Path) -> Path:
    rows = [
        {"name": "Library of Leng", "inclusion": 5944, "potential_decks": 7651, "pct": 77.7, "synergy": 0.75},
        {"name": "Sensei's Divining Top", "inclusion": 5123, "potential_decks": 7651, "pct": 67.0, "synergy": 0.63},
        {"name": "Scroll Rack", "inclusion": 4572, "potential_decks": 7651, "pct": 59.8, "synergy": 0.57},
        {"name": "Penance", "inclusion": 3195, "potential_decks": 7651, "pct": 41.8, "synergy": 0.41},
        {"name": "Land Tax", "inclusion": 2391, "potential_decks": 7651, "pct": 31.3, "synergy": 0.2},
        {"name": "Enlightened Tutor", "inclusion": 1400, "potential_decks": 7651, "pct": 18.3, "synergy": 0.03},
        {"name": "Brainstone", "inclusion": 1403, "potential_decks": 7651, "pct": 18.3, "synergy": 0.18},
        {"name": "Hidden Retreat", "inclusion": 1346, "potential_decks": 7651, "pct": 17.6, "synergy": 0.17},
        {"name": "Gamble", "inclusion": 924, "potential_decks": 7651, "pct": 12.1, "synergy": 0.05},
    ]
    return write_json(tmp_path / "edhrec.json", rows)


def access_report(tmp_path: Path) -> Path:
    return write_json(
        tmp_path / "access.json",
        {
            "summary": {
                "preflight_access_candidate_ready_count": 0,
                "current_target_access_cards": [
                    "Sensei's Divining Top",
                    "Scroll Rack",
                    "Library of Leng",
                ],
                "nonbaseline_target_access_cards": ["Squee, Goblin Nabob"],
                "recommended_next_action": "no_access_swap_ready; build_new_seed_safe_cut",
            },
            "candidates": [
                {
                    "card_name": "Brainstone",
                    "status": "ready",
                    "lane": "topdeck_setup",
                    "score": 35,
                    "access_targets": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng"],
                    "nonbaseline_access_targets": [],
                    "variant_usage": {"deck_ids": [611, 613]},
                    "blockers": [],
                },
                {
                    "card_name": "Gamble",
                    "status": "ready",
                    "lane": "access_tutor",
                    "score": 63,
                    "access_targets": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng"],
                    "nonbaseline_access_targets": ["Squee, Goblin Nabob"],
                    "variant_usage": {"deck_ids": [609, 612, 613]},
                    "blockers": [],
                },
                {
                    "card_name": "Enlightened Tutor",
                    "status": "ready",
                    "lane": "access_tutor",
                    "score": 67,
                    "access_targets": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng"],
                    "nonbaseline_access_targets": [],
                    "variant_usage": {"deck_ids": [608, 611, 612]},
                    "blockers": [],
                },
            ],
        },
    )


def tutor_report(tmp_path: Path) -> Path:
    return write_json(
        tmp_path / "tutor.json",
        {
            "summary": {
                "direct_gate_ready_count": 0,
                "recommended_next_action": "do_not_gate_direct_tutor_swap",
            },
            "candidates": [
                {
                    "card_name": "Enlightened Tutor",
                    "active_rule_count": 1,
                    "exposure": 202,
                },
                {
                    "card_name": "Gamble",
                    "active_rule_count": 1,
                    "exposure": 228,
                },
            ],
            "prior_tutor_evidence": [
                {
                    "package_key": "gamble_access_benchmark_cut_land_tax",
                    "adds": ["Gamble"],
                    "cuts": ["Land Tax"],
                    "decision": "reject_or_rework",
                    "delta_pp": -66.67,
                    "strong_seed_delta_pp": -66.67,
                }
            ],
        },
    )


def hand_report(tmp_path: Path) -> Path:
    return write_json(
        tmp_path / "hand.json",
        {
            "summary": {
                "preflight_benchmark_ready_count": 0,
                "expanded_preflight_benchmark_ready_count": 0,
                "recommended_next_action": "do_not_gate_hand_filter_without_new_cut_or_runtime_evidence",
            }
        },
    )


def test_synthesis_keeps_current_607_access_package_when_no_cut_is_ready(tmp_path):
    with make_conn() as conn:
        payload = synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            access_report_path=access_report(tmp_path),
            tutor_report_path=tutor_report(tmp_path),
            hand_filter_report_path=hand_report(tmp_path),
            edhrec_card_data=write_edhrec(tmp_path),
        )

    assert payload["status"] == "selection_access_no_swap_ready_current_607"
    assert payload["decision"]["keep_607_access_package"] is True
    assert payload["summary"]["current_access_anchor_count"] == 4
    assert payload["summary"]["current_target_access_cards"] == [
        "Sensei's Divining Top",
        "Scroll Rack",
        "Library of Leng",
    ]
    assert payload["summary"]["nonbaseline_target_access_cards"] == ["Squee, Goblin Nabob"]
    assert payload["divergences"][0]["key"] == "access_model_contains_nonbaseline_target"


def test_tutor_candidates_are_blocked_despite_legality_and_runtime(tmp_path):
    with make_conn() as conn:
        payload = synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            access_report_path=access_report(tmp_path),
            tutor_report_path=tutor_report(tmp_path),
            hand_filter_report_path=hand_report(tmp_path),
            edhrec_card_data=write_edhrec(tmp_path),
        )

    candidates = {row["card_name"]: row for row in payload["candidate_access_cards"]}
    assert candidates["Gamble"]["commander_legality"] == "legal"
    assert candidates["Gamble"]["decision"] == "direct_tutor_swap_blocked"
    assert "prior_tutor_evidence_contains_strong_seed_regression_or_watch" in candidates["Gamble"]["decision_reasons"]
    assert candidates["Brainstone"]["decision"] == "runtime_ready_but_no_seed_safe_cut"
