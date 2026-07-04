import json
import sqlite3
from pathlib import Path

import lorehold_mana_foundation_audit as audit


def make_conn(include_optional=True):
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
            is_commander INTEGER,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            card_id TEXT
        )
        """
    )
    if include_optional:
        conn.executescript(
            """
            CREATE TABLE card_oracle_cache (
                normalized_name TEXT PRIMARY KEY,
                name TEXT NOT NULL,
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
    return conn


def insert_card(conn, name, qty, tag, type_line, oracle, cmc=0, commander=0, deck_id=607):
    conn.execute(
        """
        INSERT INTO deck_cards
        VALUES (?, ?, ?, ?, '[]', ?, ?, ?, ?, NULL)
        """,
        (deck_id, name, qty, tag, commander, cmc, type_line, oracle),
    )


def insert_oracle(conn, name, mana_cost, type_line, oracle, cmc):
    conn.execute(
        """
        INSERT INTO card_oracle_cache
        VALUES (?, ?, ?, ?, ?, ?, NULL)
        """,
        (audit.normalize_name(name), name, mana_cost, type_line, oracle, cmc),
    )


def populate_structural_607(conn):
    insert_card(
        conn,
        "Lorehold, the Historian",
        1,
        "engine",
        "Legendary Creature - Elder Dragon",
        "Flying, haste.",
        5,
        1,
    )
    insert_card(conn, "Mountain", 10, "land", "Basic Land - Mountain", "Tap: Add R.")
    insert_card(conn, "Plains", 10, "land", "Basic Land - Plains", "Tap: Add W.")
    insert_card(conn, "Command Tower", 1, "land", "Land", "Tap: Add one mana of any color in your commander's color identity.")
    insert_card(conn, "Sacred Foundry", 4, "land", "Land - Mountain Plains", "Tap: Add R or W.")
    insert_card(
        conn,
        "Arid Mesa",
        8,
        "land",
        "Land",
        "Tap, Pay 1 life, Sacrifice this land: Search your library for a Mountain or Plains card.",
    )
    insert_card(conn, "Ancient Tomb", 1, "land", "Land", "{T}: Add {C}{C}. This land deals 2 damage to you.")
    ramp_rows = [
        ("Sol Ring", 1, "Artifact", "{T}: Add {C}{C}."),
        ("Arcane Signet", 2, "Artifact", "Tap: Add one mana of any color in your commander's color identity."),
        ("Boros Signet", 2, "Artifact", "1, Tap: Add RW."),
        ("Fellwar Stone", 2, "Artifact", "Tap: Add one mana of any color that a land an opponent controls could produce."),
        ("Talisman of Conviction", 2, "Artifact", "Tap: Add C. Tap: Add R or W. This artifact deals 1 damage to you."),
        ("Pearl Medallion", 2, "Artifact", "White spells you cast cost {1} less to cast."),
        ("Ruby Medallion", 2, "Artifact", "Red spells you cast cost {1} less to cast."),
        ("The Mind Stone", 2, "Artifact", "Tap: Add W."),
        ("Bender's Waterskin", 3, "Artifact", "Untap this artifact during each other player's untap step. Tap: Add one mana of any color."),
        ("Victory Chimes", 3, "Artifact", "Untap this artifact during each other player's untap step. Tap: A player of your choice adds C."),
        ("Jeska's Will", 3, "Sorcery", "Add R for each card in target opponent's hand."),
        ("Big Score", 4, "Instant", "Draw two cards and create two Treasure tokens."),
        ("Unexpected Windfall", 4, "Instant", "Draw two cards and create two Treasure tokens."),
        ("Smothering Tithe", 4, "Enchantment", "Whenever an opponent draws a card, create a Treasure token."),
        ("Monument to Endurance", 3, "Artifact", "Whenever you discard a card, create a Treasure token."),
    ]
    for name, cmc, type_line, oracle in ramp_rows:
        insert_card(conn, name, 1, "ramp", type_line, oracle, cmc)
    insert_card(
        conn,
        "Land Tax",
        1,
        "tutor",
        "Enchantment",
        "At the beginning of your upkeep, search your library for up to three basic land cards.",
        1,
    )
    insert_oracle(
        conn,
        "Mana Vault",
        "{1}",
        "Artifact",
        "This artifact doesn't untap during your untap step. Tap: Add CCC.",
        1,
    )
    insert_oracle(
        conn,
        "The One Ring",
        "{4}",
        "Legendary Artifact",
        "Indestructible. Tap: Put a burden counter on The One Ring, then draw a card.",
        4,
    )
    for name in ["Mana Vault", "The One Ring"]:
        conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal', NULL)", (name,))
        conn.execute(
            "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified', ?)",
            (name, audit.normalize_name(name), json.dumps({"battle_model_scope": "test_scope"})),
        )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Mana Vault', 'commander', 'ramp', '', '', 144, NULL, 0)"
    )


def write_edhrec(tmp_path: Path):
    path = tmp_path / "edhrec.json"
    path.write_text(
        json.dumps(
            [
                {"name": "Mana Vault", "inclusion": 447, "potential_decks": 7651, "synergy": 0.02, "pct": 5.8},
                {"name": "The One Ring", "inclusion": 645, "potential_decks": 7651, "synergy": 0.02, "pct": 8.4},
                {"name": "Arcane Signet", "inclusion": 6742, "potential_decks": 7651, "synergy": 0.08, "pct": 88.1},
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    return path


def test_structural_607_mana_foundation_passes_with_watch_items(tmp_path):
    conn = make_conn()
    populate_structural_607(conn)

    payload = audit.build_audit(conn=conn, db_path=Path("memory.db"), edhrec_card_data=write_edhrec(tmp_path))

    assert payload["status"] == "mana_foundation_pass_with_watch_items"
    assert payload["summary"]["land_count"] == 34
    assert payload["summary"]["ramp_count"] == 15
    assert payload["summary"]["total_mana_package_including_land_tax"] == 50
    assert payload["summary"]["early_foundation_count"] == 8
    assert payload["summary"]["red_source_count"] >= 20
    assert payload["summary"]["white_source_count"] >= 20
    assert payload["summary"]["mana_vault_decision"] == "blocked_for_current_known_cuts"
    assert payload["summary"]["one_ring_decision"] == "blocked_for_current_607_shell"


def test_candidate_history_parsers_are_attached(tmp_path):
    conn = make_conn()
    populate_structural_607(conn)
    synth = tmp_path / "mana_vault.json"
    synth.write_text(
        json.dumps(
            {
                "summary": {
                    "decision": "reject_current_pair",
                    "promotion_allowed": False,
                    "latest_natural_delta_pp": -66.67,
                    "next_action": "do_not_repeat",
                }
            }
        )
        + "\n",
        encoding="utf-8",
    )
    profiled = tmp_path / "profiled.md"
    profiled.write_text(
        "| Candidate | Cut | Status | Score | Blockers |\n"
        "| --- | --- | --- | ---: | --- |\n"
        "| Mana Vault | Bender's Waterskin | `blocked` | 112 | prior_exact_reject |\n",
        encoding="utf-8",
    )
    one_ring = tmp_path / "one_ring.md"
    one_ring.write_text(
        "- Status: `rejected_keep_607_baseline`\n"
        "| `deck_607` | `30` | `72` | `41.67%` | `41` | `1` |\n"
        "| `candidate_607_one_ring_creative_technique_v1` | `25` | `72` | `34.72%` | `47` | `0` |\n"
        "| `The One Ring` accessed games | `0` | `24` |\n"
        "| `The One Ring` cost paid | `0` | `42` |\n",
        encoding="utf-8",
    )

    payload = audit.build_audit(
        conn=conn,
        db_path=Path("memory.db"),
        edhrec_card_data=write_edhrec(tmp_path),
        one_ring_decision_path=one_ring,
        profiled_cut_report=profiled,
        mana_vault_arcane_synthesis_path=synth,
    )

    mana_vault = payload["candidate_staples"][0]
    one_ring_profile = payload["candidate_staples"][1]
    assert mana_vault["mana_vault_over_arcane_signet"]["decision"] == "reject_current_pair"
    assert mana_vault["mana_vault_over_benders_waterskin"]["blockers"] == ["prior_exact_reject"]
    assert one_ring_profile["one_ring_current_shell_decision"]["aggregate"]["baseline_wins"] == 30
    assert one_ring_profile["one_ring_current_shell_decision"]["card_use"]["accessed_games"] == 24


def test_optional_tables_are_not_required_for_blocked_minimal_audit(tmp_path):
    conn = make_conn(include_optional=False)
    insert_card(conn, "Lorehold, the Historian", 1, "engine", "Legendary Creature", "", 5, 1)
    insert_card(conn, "Mountain", 10, "land", "Basic Land - Mountain", "Tap: Add R.")
    insert_card(conn, "Sol Ring", 1, "ramp", "Artifact", "{T}: Add {C}{C}.", 1)

    payload = audit.build_audit(conn=conn, db_path=Path("memory.db"), edhrec_card_data=write_edhrec(tmp_path))

    assert payload["status"] == "blocked_mana_foundation"
    assert "land_count_below_lorehold_floor" in payload["structural_assessment"]["blockers"]
    assert payload["candidate_staples"][0]["commander_legality"] is None
