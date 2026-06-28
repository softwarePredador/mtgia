import sqlite3
from pathlib import Path

import lorehold_mana_base_validator as validator


def make_conn():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
            card_name TEXT,
            quantity INTEGER,
            type_line TEXT,
            oracle_text TEXT,
            functional_tag TEXT,
            battle_rules_json TEXT,
            deck_id INTEGER
        );
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type_line TEXT,
            oracle_text TEXT
        );
        CREATE TABLE battle_card_rules (
            normalized_name TEXT,
            logical_rule_key TEXT,
            card_name TEXT,
            effect_json TEXT,
            deck_role_json TEXT,
            execution_status TEXT,
            review_status TEXT
        );
        """
    )
    return conn


def insert_land(conn, name, type_line, oracle):
    conn.execute(
        """
        INSERT INTO deck_cards (
            card_name, quantity, type_line, oracle_text, functional_tag, battle_rules_json, deck_id
        )
        VALUES (?, 1, ?, ?, 'land', '[]', 6)
        """,
        (name, type_line, oracle),
    )


def insert_oracle(conn, name, type_line, oracle):
    conn.execute(
        """
        INSERT INTO card_oracle_cache (normalized_name, name, type_line, oracle_text)
        VALUES (?, ?, ?, ?)
        """,
        (validator.normalize_key(name), name, type_line, oracle),
    )


def miner_report(*candidates):
    return {
        "pairing_hypotheses": [
            {
                "candidate": candidate,
                "lane": "mana_base",
                "status": "blocked_no_safe_cut_in_lane",
                "candidate_score": 90,
                "cut_options": [
                    {
                        "card_name": "Ancient Tomb",
                        "status": "blocked_core_cut",
                        "gate_readiness": "blocked_cut_contract",
                    }
                ],
            }
            for candidate in candidates
        ]
    }


def report_for(conn, *candidates):
    return validator.build_report(
        conn=conn,
        miner_report=miner_report(*candidates),
        prior_land_gate_reports=[],
        db_path=Path(":memory:"),
        miner_path=Path("miner.json"),
        deck_id=6,
    )


def test_plateau_over_turbulent_steppe_is_deterministic_upgrade():
    conn = make_conn()
    insert_land(
        conn,
        "Turbulent Steppe",
        "Land - Mountain Plains",
        "Tap: Add R or W. This land enters tapped unless your opponents control eight or more lands.",
    )
    insert_oracle(conn, "Plateau", "Land - Mountain Plains", "Tap: Add R or W.")

    payload = report_for(conn, "Plateau")

    ready = {(row["candidate"], row["cut"]): row for row in payload["ready_swaps"]}
    swap = ready[("Plateau", "Turbulent Steppe")]
    assert swap["status"] == "preflight_land_swap_ready"
    assert swap["deltas"]["red_source_delta"] == 0
    assert swap["deltas"]["white_source_delta"] == 0
    assert swap["deltas"]["etb_score_delta"] > 0
    assert payload["summary"]["recommended_swap"]["candidate"] == "Plateau"
    assert payload["summary"]["recommended_next_action"] == "run_mana_base_validated_preflight"


def test_boseiju_cannot_cut_boros_color_source():
    conn = make_conn()
    insert_land(
        conn,
        "Battlefield Forge",
        "Land",
        "Tap: Add C. Tap: Add R or W. This land deals 1 damage to you.",
    )
    insert_oracle(
        conn,
        "Boseiju, Who Shelters All",
        "Legendary Land",
        "Boseiju enters tapped. Tap, Pay 2 life: Add C. If that mana is spent on an instant or sorcery spell, that spell cannot be countered.",
    )

    payload = report_for(conn, "Boseiju, Who Shelters All")

    blocked = {(row["candidate"], row["cut"]): row for row in payload["blocked_swaps_sample"]}
    swap = blocked[("Boseiju, Who Shelters All", "Battlefield Forge")]
    assert "would_reduce_boros_color_sources" in swap["blockers"]


def test_plateau_does_not_auto_cut_commander_legendary_land():
    conn = make_conn()
    insert_land(
        conn,
        "Plaza of Heroes",
        "Land",
        "Tap: Add C. Tap: Add one mana of any color. Spend this mana only to cast a legendary spell. Tap: Add one mana of any color among legendary permanents you control. Tap: Target legendary creature gains hexproof and indestructible until end of turn.",
    )
    insert_oracle(conn, "Plateau", "Land - Mountain Plains", "Tap: Add R or W.")

    payload = report_for(conn, "Plateau")

    row = {
        (item["candidate"], item["cut"]): item
        for item in payload["all_evaluations"]
    }[("Plateau", "Plaza of Heroes")]
    assert row["status"] == "blocked"
    assert "would_cut_commander_legendary_mana" in row["blockers"]
    assert "would_cut_legendary_protection" in row["blockers"]


def test_unique_mana_base_roles_are_protected():
    conn = make_conn()
    insert_land(conn, "Ancient Tomb", "Land", "Tap: Add CC. This land deals 2 damage to you.")
    insert_land(
        conn,
        "Arid Mesa",
        "Land",
        "Tap, Pay 1 life, Sacrifice this land: Search your library for a Mountain or Plains card.",
    )
    insert_land(
        conn,
        "Command Beacon",
        "Land",
        "Tap: Add C. Tap, Sacrifice this land: Put your commander into your hand from the command zone.",
    )
    insert_oracle(conn, "Plateau", "Land - Mountain Plains", "Tap: Add R or W.")

    payload = report_for(conn, "Plateau")

    blocked = {(row["candidate"], row["cut"]): row for row in payload["all_evaluations"]}
    assert "would_cut_fast_colorless_acceleration" in blocked[("Plateau", "Ancient Tomb")][
        "blockers"
    ]
    assert "would_cut_fetch_dual_access" in blocked[("Plateau", "Arid Mesa")]["blockers"]
    assert "would_cut_commander_recast_utility" in blocked[("Plateau", "Command Beacon")][
        "blockers"
    ]


def test_prior_boseiju_reliquary_gate_blocks_repeat():
    conn = make_conn()
    insert_land(conn, "Reliquary Tower", "Land", "You have no maximum hand size. Tap: Add C.")
    insert_oracle(
        conn,
        "Boseiju, Who Shelters All",
        "Legendary Land",
        "Boseiju enters tapped. Tap, Pay 2 life: Add C. If that mana is spent on an instant or sorcery spell, that spell cannot be countered.",
    )
    prior = {
        "results": [
            {
                "package_key": "boseiju_spell_protection_land",
                "candidate_wins": 3,
                "candidate_losses": 6,
                "baseline_wins": 8,
                "baseline_losses": 1,
                "delta_pp": -55.56,
                "strong_seed_delta_pp": -55.56,
            }
        ]
    }

    payload = validator.build_report(
        conn=conn,
        miner_report=miner_report("Boseiju, Who Shelters All"),
        prior_land_gate_reports=[(Path("prior.json"), prior)],
        db_path=Path(":memory:"),
        miner_path=Path("miner.json"),
        deck_id=6,
    )

    row = {
        (item["candidate"], item["cut"]): item
        for item in payload["all_evaluations"]
    }[("Boseiju, Who Shelters All", "Reliquary Tower")]
    assert "prior_negative_land_gate" in row["blockers"]
    assert row["prior_land_gate"]["candidate_wins"] == 3
