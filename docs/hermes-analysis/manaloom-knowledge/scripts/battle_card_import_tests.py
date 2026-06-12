"""Card import, oracle cache, and curated rule regressions."""

import importlib.util
import json
import random
import sqlite3
import tempfile
from pathlib import Path


def register_tests(battle, player, card, module_path):
    def test_card_oracle_cache_enriches_battle_cards():
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        conn.execute(
            """
            CREATE TABLE card_oracle_cache (
                normalized_name TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                mana_cost TEXT,
                colors_json TEXT,
                color_identity_json TEXT,
                type_line TEXT,
                oracle_text TEXT,
                cmc REAL,
                power TEXT,
                toughness TEXT,
                keywords_json TEXT,
                scryfall_id TEXT
            )
            """
        )
        conn.execute(
            """
            INSERT INTO card_oracle_cache (
                normalized_name, name, mana_cost, colors_json, color_identity_json,
                type_line, oracle_text, cmc, power, toughness, keywords_json, scryfall_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "test trampler",
                "Test Trampler",
                "{3}{G}",
                json.dumps(["G"]),
                json.dumps(["G"]),
                "Creature - Beast",
                "Trample",
                4,
                "4",
                "4",
                json.dumps(["trample"]),
                "00000000-0000-0000-0000-000000000000",
            ),
        )

        cache = battle.load_card_oracle_cache(conn, ["Test Trampler"])
        enriched = battle.enrich_card(
            battle.merge_oracle_metadata(
                {"name": "Test Trampler", "cmc": 0, "tag": "creature"},
                cache,
            )
        )

        assert enriched["mana_cost"] == "{3}{G}"
        assert enriched["cmc"] == 4
        assert enriched["power"] == 4
        assert enriched["toughness"] == 4
        assert enriched["trample"] is True
        conn.close()

    def test_battle_card_rules_table_overrides_fallbacks():
        if battle.battle_rule_registry is None:
            raise AssertionError("battle_rule_registry failed to import")
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "rules.db"
            conn = sqlite3.connect(db_path)
            battle.battle_rule_registry.upsert_battle_card_rule(
                conn,
                "Registry Counter",
                {"effect": "counter", "instant": True},
                source="manual",
                confidence=1.0,
                review_status="verified",
                oracle_hash="unit-oracle-hash",
                notes="Unit test rule.",
            )
            conn.commit()
            conn.close()

            try:
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                effect = battle.get_card_effect(
                    {
                        "name": "Registry Counter",
                        "type_line": "Instant",
                        "oracle_text": "A deliberately weird test card.",
                    }
                )

                assert effect["effect"] == "counter"
                assert effect["_rule_source"] == "manual"
                assert effect["_rule_logical_key"].startswith("battle_rule_v1:")
                assert effect["_rule_oracle_hash"] == "unit-oracle-hash"
                replay_fields = battle.replay_rule_fields(effect)
                assert replay_fields["rule_logical_key"] == effect["_rule_logical_key"]
                assert replay_fields["rule_oracle_hash"] == "unit-oracle-hash"
                assert battle.is_instant({"name": "Registry Counter", "type_line": "Instant"})
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

    def test_lands_are_not_instant_or_sorcery_even_with_generated_metadata():
        land = {
            "name": "Mana Confluence",
            "cmc": 0,
            "type_line": "Land",
            "oracle_text": "{T}: Add one mana of any color.",
            "effect": "land",
            "tag": "land",
        }

        assert battle.is_effective_land(land)
        assert battle.is_instant(land) is False
        assert battle.is_sorcery(land) is False
        assert battle.get_card_effect(land).get("instant") is None

    def test_end_step_window_does_not_cast_lands():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        active = player("Active", [card("Draw")])
        opponent = player("Opponent", [card("Opp Draw")])
        opponent.hand = [
            {
                "name": "Mana Confluence",
                "cmc": 0,
                "type_line": "Land",
                "oracle_text": "{T}: Add one mana of any color.",
                "effect": "land",
                "tag": "land",
            }
        ]
        opponent.battlefield = [
            {"name": "Island", "effect": "land", "type_line": "Land"},
            {"name": "Island", "effect": "land", "type_line": "Land"},
        ]

        battle.play_turn_v8(
            active,
            [opponent],
            [active, opponent],
            turn=3,
            rng=random.Random(32),
            stack=battle.Stack(),
        )
        battle.REPLAY_EVENT_HANDLER = None

        assert not [
            data
            for event, data in events
            if event == "end_step_instant" and data.get("effect") == "land"
        ]

    def test_zuran_orb_is_life_artifact_not_mana_rock():
        active = player("Active")
        zuran = {
            "name": "Zuran Orb",
            "cmc": 0,
            "type_line": "Artifact",
            "oracle_text": "Sacrifice a land: You gain 2 life.",
        }

        effect = battle.get_card_effect(zuran)
        assert effect["effect"] == "life_artifact"
        assert effect["_rule_review_status"] == "verified"
        battle.apply_effect_immediate(active, [], zuran, 5, random.Random(41))

        permanent = active.battlefield[0]
        assert permanent["effect"] == "life_artifact"
        assert "mana_produced" not in permanent
        assert active.available_mana() == 0

    def test_vexing_bauble_is_hate_artifact_not_immediate_draw():
        active = player("Active", [card("Top card")])
        bauble = {
            "name": "Vexing Bauble",
            "cmc": 1,
            "type_line": "Artifact",
            "oracle_text": "Whenever a player casts a spell, if no mana was spent to cast it, counter that spell.\n{1}, {T}, Sacrifice Vexing Bauble: Draw a card.",
        }

        effect = battle.get_card_effect(bauble)
        assert effect["effect"] == "hate_artifact"
        assert effect["_rule_review_status"] == "verified"
        before_hand = len(active.hand)
        battle.apply_effect_immediate(active, [], bauble, 6, random.Random(42))

        permanent = active.battlefield[0]
        assert permanent["effect"] == "hate_artifact"
        assert permanent["counters_free_spells"] is True
        assert len(active.hand) == before_hand

    def test_known_land_name_without_oracle_imports_as_land_not_creature():
        imported = battle.build_learned_battle_card({"name": "High Market"}, oracle_cache={})

        assert imported["effect"] == "land"
        assert imported["type_line"] == "Land"
        assert battle.is_battlefield_creature(imported) is False

    def test_unknown_card_without_oracle_does_not_default_to_creature():
        imported = battle.build_learned_battle_card({"name": "Mystery Card"}, oracle_cache={})

        assert imported["effect"] == "unknown"
        assert imported["type_line"] == ""
        assert battle.is_battlefield_creature(imported) is False

    def test_rule_sync_oracle_normalizes_generated_land_rules():
        sync_path = module_path.with_name("sync_battle_card_rules.py")
        sync_spec = importlib.util.spec_from_file_location("sync_rules_under_test", sync_path)
        sync_rules = importlib.util.module_from_spec(sync_spec)
        sync_spec.loader.exec_module(sync_rules)

        with tempfile.TemporaryDirectory() as tmp_dir:
            db_path = str(Path(tmp_dir) / "rules.db")
            conn = sqlite3.connect(db_path)
            conn.execute(
                """
                CREATE TABLE card_oracle_cache (
                  normalized_name TEXT PRIMARY KEY,
                  name TEXT,
                  mana_cost TEXT,
                  colors_json TEXT,
                  color_identity_json TEXT,
                  type_line TEXT,
                  oracle_text TEXT,
                  cmc REAL,
                  power TEXT,
                  toughness TEXT,
                  keywords_json TEXT,
                  scryfall_id TEXT
                )
                """
            )
            conn.execute(
                """
                INSERT INTO card_oracle_cache (
                  normalized_name, name, type_line, oracle_text, cmc,
                  colors_json, color_identity_json, keywords_json
                )
                VALUES ('mystery land', 'Mystery Land', 'Land', '', 0, '[]', '[]', '[]')
                """
            )
            conn.commit()
            conn.close()

            rows = sync_rules._oracle_normalized_rows(
                db_path,
                [
                    {
                        "card_name": "Mystery Land",
                        "effect_json": {"effect": "ramp_permanent"},
                        "source": "generated",
                        "confidence": 0.55,
                        "review_status": "needs_review",
                        "notes": "",
                    }
                ],
            )

        assert rows[0]["effect_json"]["effect"] == "land"
        assert rows[0]["_oracle_normalized"] is True

    return [
        test_card_oracle_cache_enriches_battle_cards,
        test_battle_card_rules_table_overrides_fallbacks,
        test_lands_are_not_instant_or_sorcery_even_with_generated_metadata,
        test_end_step_window_does_not_cast_lands,
        test_zuran_orb_is_life_artifact_not_mana_rock,
        test_vexing_bauble_is_hate_artifact_not_immediate_draw,
        test_known_land_name_without_oracle_imports_as_land_not_creature,
        test_unknown_card_without_oracle_does_not_default_to_creature,
        test_rule_sync_oracle_normalizes_generated_land_rules,
    ]
