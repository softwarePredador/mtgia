import json
import sqlite3
from pathlib import Path

import lorehold_accessibility_layer_matrix as matrix


def make_conn() -> sqlite3.Connection:
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
            type_line TEXT
        );
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT,
            mana_cost TEXT,
            colors_json TEXT,
            color_identity_json TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            scryfall_id TEXT,
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
            normalized_name TEXT,
            card_name TEXT,
            execution_status TEXT,
            review_status TEXT
        );
        """
    )
    deck_rows = [
        (607, "Lorehold, the Historian", 1, "commander", "[]", 1, 5, "Legendary Creature"),
        (607, "Sol Ring", 1, "ramp", "[]", 0, 1, "Artifact"),
        (607, "Jeska's Will", 1, "ramp", "[]", 0, 3, "Sorcery"),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?)", deck_rows)
    oracle_rows = [
        (
            "mana vault",
            "Mana Vault",
            "{1}",
            "[]",
            "[]",
            "Artifact",
            "{T}: Add {C}{C}{C}.",
            1,
            None,
            None,
        ),
        (
            "the one ring",
            "The One Ring",
            "{4}",
            "[]",
            "[]",
            "Legendary Artifact",
            "Indestructible. {T}: Draw cards.",
            4,
            None,
            None,
        ),
    ]
    conn.executemany("INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", oracle_rows)
    conn.executemany(
        "INSERT INTO card_legalities VALUES (?, 'commander', 'legal', NULL)",
        [("Mana Vault",), ("The One Ring",)],
    )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Mana Vault', 'commander', 'ramp', '', '', 144, NULL, 0)"
    )
    conn.executemany(
        "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified')",
        [("mana vault", "Mana Vault"), ("the one ring", "The One Ring")],
    )
    return conn


def write_inputs(tmp_path: Path) -> dict[str, Path]:
    collection = tmp_path / "collection.csv"
    collection.write_text(
        "Edicao (Sigla),Card (PT),Card (EN),Quantidade,Card #\n"
        "ltr,O Um Anel,The One Ring,1,246\n",
        encoding="utf-8",
    )
    policy = tmp_path / "edh_bracket_policy.dart"
    policy.write_text(
        "const officialGameChangerNamesForBracketPolicy = <String>{\n"
        "  'jeska\\'s will',\n"
        "  'mana vault',\n"
        "  'the one ring',\n"
        "};\n",
        encoding="utf-8",
    )
    staple_report = tmp_path / "staple.json"
    staple_report.write_text(
        json.dumps(
            {
                "candidate_staple_backlog": [
                    {
                        "card_name": "Mana Vault",
                        "decision": "blocked_prior_gate_rejected",
                        "decision_reasons": ["mana_vault_current_pair_lost_with_card_exposure"],
                        "policy_class": "tested_or_policy_blocked_staple",
                        "lane": "ramp",
                    },
                    {
                        "card_name": "The One Ring",
                        "decision": "blocked_existing_package_rejected",
                        "decision_reasons": ["payoff_synthesis_decision"],
                        "policy_class": "tested_or_policy_blocked_staple",
                        "lane": "card_draw_selection",
                    },
                ]
            }
        ),
        encoding="utf-8",
    )
    mana_foundation = tmp_path / "mana.json"
    mana_foundation.write_text(json.dumps({"candidate_staples": []}), encoding="utf-8")
    return {
        "collection": collection,
        "policy": policy,
        "staple_report": staple_report,
        "mana_foundation": mana_foundation,
    }


def test_accessibility_layers_do_not_collapse_legal_owned_and_promotable(tmp_path):
    paths = write_inputs(tmp_path)
    with make_conn() as conn:
        payload = matrix.build_matrix(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            card_names=["Mana Vault", "The One Ring"],
            collection_path=paths["collection"],
            bracket_policy_path=paths["policy"],
            staple_policy_report_path=paths["staple_report"],
            mana_foundation_report_path=paths["mana_foundation"],
            target_bracket=4,
        )

    cards = {row["card_name"]: row for row in payload["cards"]}
    mana_vault = cards["Mana Vault"]
    one_ring = cards["The One Ring"]

    assert mana_vault["rules_layer"]["commander_legal"] is True
    assert mana_vault["collection_layer"]["owned"] is False
    assert mana_vault["discovery_layer"]["format_staple_present"] is True
    assert mana_vault["deck_layer"]["present_in_607"] is False
    assert mana_vault["current_607_accessibility"] == "legal_not_owned_and_promotion_blocked_current_607"

    assert one_ring["rules_layer"]["commander_legal"] is True
    assert one_ring["collection_layer"]["owned"] is True
    assert one_ring["discovery_layer"]["format_staple_present"] is False
    assert one_ring["discovery_layer"]["format_staples_gap"] is True
    assert one_ring["current_607_accessibility"] == "legal_owned_but_promotion_blocked_current_607"

    assert payload["decision"]["keep_607"] is True


def test_markdown_surfaces_accessibility_layers(tmp_path):
    paths = write_inputs(tmp_path)
    with make_conn() as conn:
        payload = matrix.build_matrix(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            card_names=["Mana Vault", "The One Ring"],
            collection_path=paths["collection"],
            bracket_policy_path=paths["policy"],
            staple_policy_report_path=paths["staple_report"],
            mana_foundation_report_path=paths["mana_foundation"],
            target_bracket=4,
        )

    markdown = matrix.render_markdown(payload)

    assert "Lorehold Accessibility Layer Matrix" in markdown
    assert "legal_not_owned_and_promotion_blocked_current_607" in markdown
    assert "legal_owned_but_promotion_blocked_current_607" in markdown
    assert "Do not label a card as simply accessible" in markdown
