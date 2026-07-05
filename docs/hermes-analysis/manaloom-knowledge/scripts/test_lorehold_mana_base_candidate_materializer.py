import json
import sqlite3
from pathlib import Path

import pytest

import lorehold_mana_base_candidate_materializer as materializer


def create_fixture_db(path: Path, *, include_cut: bool = True) -> None:
    conn = sqlite3.connect(path)
    conn.executescript(
        """
        CREATE TABLE deck_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            card_name TEXT NOT NULL,
            quantity INTEGER DEFAULT 1,
            functional_tag TEXT,
            tag_confidence REAL,
            is_commander INTEGER DEFAULT 0,
            is_partner INTEGER DEFAULT 0,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            card_id TEXT,
            functional_tags_json TEXT DEFAULT '[]',
            semantic_tags_v2_json TEXT DEFAULT '[]',
            battle_rules_json TEXT DEFAULT '[]',
            deck_hash TEXT,
            semantics_hash TEXT,
            sync_run_id TEXT,
            ruleset_hash TEXT
        );
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT,
            card_id TEXT,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            color_identity_json TEXT
        );
        CREATE TABLE battle_card_rules (
            normalized_name TEXT,
            logical_rule_key TEXT,
            effect_json TEXT,
            deck_role_json TEXT,
            source TEXT,
            confidence REAL,
            review_status TEXT,
            execution_status TEXT,
            rule_version INTEGER,
            oracle_hash TEXT
        );
        """
    )
    conn.executemany(
        """
        INSERT INTO card_oracle_cache (
            normalized_name, name, card_id, cmc, type_line, oracle_text,
            color_identity_json
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        [
            (
                "plateau",
                "Plateau",
                "plateau-card-id",
                0,
                "Land - Mountain Plains",
                "({T}: Add {R} or {W}.)",
                "[]",
            ),
            (
                "radiant summit",
                "Radiant Summit",
                "radiant-card-id",
                0,
                "Land - Mountain Plains",
                "({T}: Add {R} or {W}.)\nThis land enters tapped unless you control two or more basic lands.",
                "[]",
            ),
        ],
    )
    conn.execute(
        """
        INSERT INTO battle_card_rules (
            normalized_name, logical_rule_key, effect_json, deck_role_json,
            source, confidence, review_status, execution_status, rule_version,
            oracle_hash
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            "plateau",
            "battle_rule_v1:land",
            json.dumps({"effect": "land"}),
            json.dumps({"category": "land", "effect": "land"}),
            "curated",
            1.0,
            "verified",
            "auto",
            1,
            "plateau-oracle-hash",
        ),
    )

    def insert_card(
        deck_id: int,
        name: str,
        tag: str,
        type_line: str,
        oracle_text: str = "",
        *,
        is_commander: int = 0,
        card_id: str | None = None,
        semantic: str = "[]",
        rules: str = "[]",
    ) -> None:
        conn.execute(
            """
            INSERT INTO deck_cards (
                deck_id, card_name, quantity, functional_tag,
                is_commander, is_partner, cmc, type_line, oracle_text, card_id,
                functional_tags_json, semantic_tags_v2_json, battle_rules_json,
                deck_hash, semantics_hash, sync_run_id, ruleset_hash
            )
            VALUES (?, ?, 1, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                deck_id,
                name,
                tag,
                is_commander,
                5 if is_commander else 0,
                type_line,
                oracle_text,
                card_id or name.lower().replace(" ", "-"),
                json.dumps([tag]),
                semantic,
                rules,
                "source-hash",
                "source-semantics",
                "source-sync",
                "source-ruleset",
            ),
        )

    insert_card(
        607,
        "Lorehold, the Historian",
        "engine",
        "Legendary Creature - Elder Dragon",
        "Flying",
        is_commander=1,
        card_id="commander-id",
    )
    protected_anchor_rows = [
        ("Bender's Waterskin", "ramp", "Artifact"),
        ("Creative Technique", "draw", "Sorcery"),
        ("Land Tax", "tutor", "Enchantment"),
        ("Library of Leng", "engine", "Artifact"),
        ("Mizzix's Mastery", "wincon", "Sorcery"),
        ("Molecule Man", "draw", "Legendary Creature - Mutant Hero"),
        ("Scroll Rack", "draw", "Artifact"),
        ("Sensei's Divining Top", "draw", "Artifact"),
        ("Storm Herd", "wincon", "Sorcery"),
        ("The Mind Stone", "ramp", "Artifact"),
        ("The Scarlet Witch", "creature", "Legendary Creature - Human Warlock Hero"),
        ("Victory Chimes", "ramp", "Artifact"),
    ]
    for name, tag, type_line in protected_anchor_rows:
        insert_card(
            607,
            name,
            tag,
            type_line,
            "Fixture protected anchor.",
        )
    if include_cut:
        insert_card(
            607,
            "Radiant Summit",
            "land",
            "Land - Mountain Plains",
            "({T}: Add {R} or {W}.)\nThis land enters tapped unless you control two or more basic lands.",
            card_id="radiant-card-id",
            rules=json.dumps([{"logical_rule_key": "radiant-rule"}]),
        )
    for index in range(33 if include_cut else 34):
        insert_card(
            607,
            f"Basic Plains {index}",
            "land",
            "Basic Land - Plains",
            "({T}: Add {W}.)",
        )
    for index in range(53):
        insert_card(
            607,
            f"Spell {index}",
            "draw",
            "Sorcery",
            "Draw a card.",
            card_id=f"spell-{index}",
        )

    insert_card(
        606,
        "Plateau",
        "land",
        "Land - Mountain Plains",
        "({T}: Add {R} or {W}.)",
        card_id="plateau-card-id",
        semantic=json.dumps([{"source": "fixture", "tags": [{"tag": "land"}]}]),
        rules=json.dumps([{"logical_rule_key": "stale-existing-rule"}]),
    )
    conn.commit()
    conn.close()


def create_model_report(path: Path) -> None:
    path.write_text(
        json.dumps(
            {
                "top_model_ready_pairs": [
                    {
                        "add": "Plateau",
                        "cut": "Radiant Summit",
                        "status": "model_ready_for_candidate_materialization",
                        "pair_score": 52,
                        "reasons": ["tempo_upgrade_preserves_color_and_fetch_target_type"],
                    }
                ]
            }
        ),
        encoding="utf-8",
    )


def test_materializes_candidate_without_mutating_source(tmp_path: Path) -> None:
    source_db = tmp_path / "knowledge.db"
    model_report = tmp_path / "safe_model.json"
    out_prefix = tmp_path / "materializer_report"
    create_fixture_db(source_db)
    create_model_report(model_report)

    payload = materializer.build_payload(
        source_db=source_db,
        safe_cut_model_path=model_report,
        out_prefix=out_prefix,
    )

    assert payload["status"] == "candidate_materialized_structure_ready_battle_gate_closed"
    assert payload["summary"]["source_unchanged"] is True
    assert payload["summary"]["source_candidate_hash_differs"] is True
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["summary"]["allow_battle_gate_now"] is False
    assert payload["structure_validation"]["checks"]["total_cards_100"] is True
    assert payload["structure_validation"]["checks"]["land_quantity_34"] is True

    candidate_db = out_prefix.parent / f"{out_prefix.name}_candidate" / "knowledge_candidate.db"
    with sqlite3.connect(source_db) as conn:
        source_names = {
            row[0]
            for row in conn.execute("SELECT card_name FROM deck_cards WHERE deck_id=607")
        }
    with sqlite3.connect(candidate_db) as conn:
        candidate_names = {
            row[0]
            for row in conn.execute("SELECT card_name FROM deck_cards WHERE deck_id=607")
        }
        plateau = conn.execute(
            """
            SELECT functional_tag, functional_tags_json, battle_rules_json
            FROM deck_cards
            WHERE deck_id=607 AND card_name='Plateau'
            """
        ).fetchone()

    assert "Radiant Summit" in source_names
    assert "Plateau" not in source_names
    assert "Radiant Summit" not in candidate_names
    assert "Plateau" in candidate_names
    assert plateau[0] == "land"
    assert json.loads(plateau[1]) == ["land"]
    assert json.loads(plateau[2])[0]["logical_rule_key"] == "battle_rule_v1:land"


def test_missing_cut_blocks_materialization(tmp_path: Path) -> None:
    source_db = tmp_path / "knowledge.db"
    model_report = tmp_path / "safe_model.json"
    create_fixture_db(source_db, include_cut=False)
    create_model_report(model_report)

    with pytest.raises(RuntimeError, match="cut card not found"):
        materializer.build_payload(
            source_db=source_db,
            safe_cut_model_path=model_report,
            out_prefix=tmp_path / "materializer_report",
        )


def test_write_outputs_creates_json_and_markdown(tmp_path: Path) -> None:
    source_db = tmp_path / "knowledge.db"
    model_report = tmp_path / "safe_model.json"
    out_prefix = tmp_path / "materializer_report"
    create_fixture_db(source_db)
    create_model_report(model_report)

    payload = materializer.build_payload(
        source_db=source_db,
        safe_cut_model_path=model_report,
        out_prefix=out_prefix,
    )
    json_path, md_path = materializer.write_outputs(payload, out_prefix)

    assert json_path.exists()
    assert md_path.exists()
    assert "Lorehold Mana Base Candidate Materializer" in md_path.read_text(encoding="utf-8")
