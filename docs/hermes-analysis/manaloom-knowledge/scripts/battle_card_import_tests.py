"""Card import, oracle cache, and curated rule regressions."""

import importlib.util
import json
import random
import sqlite3
import tempfile
from pathlib import Path


def register_tests(battle, player, card, module_path):
    def _create_deck_schema(conn):
        conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_id TEXT,
                card_name TEXT,
                quantity INTEGER,
                cmc REAL,
                functional_tag TEXT,
                functional_tags_json TEXT,
                type_line TEXT,
                oracle_text TEXT,
                is_commander INTEGER,
                semantics_hash TEXT
            )
            """
        )
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

    def _insert_deck_card(
        conn,
        name,
        quantity=1,
        card_id=None,
        functional_tag="unknown",
        type_line="",
        oracle_text="",
        is_commander=0,
        cmc=0,
    ):
        conn.execute(
            """
            INSERT INTO deck_cards (
                deck_id, card_id, card_name, quantity, cmc, functional_tag,
                functional_tags_json, type_line, oracle_text, is_commander,
                semantics_hash
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                6,
                card_id or f"card-{battle.normalize_card_name(name)}",
                name,
                quantity,
                cmc,
                functional_tag,
                json.dumps([functional_tag]) if functional_tag != "unknown" else "[]",
                type_line,
                oracle_text,
                is_commander,
                f"semantic-{battle.normalize_card_name(name)}",
            ),
        )

    def _insert_oracle_card(
        conn,
        name,
        color_identity=None,
        type_line="",
        oracle_text="",
        mana_cost="",
        cmc=0,
        power=None,
        toughness=None,
    ):
        colors = color_identity or []
        conn.execute(
            """
            INSERT INTO card_oracle_cache (
                normalized_name, name, mana_cost, colors_json, color_identity_json,
                type_line, oracle_text, cmc, power, toughness, keywords_json, scryfall_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                battle.normalize_card_name(name),
                name,
                mana_cost,
                json.dumps(colors),
                json.dumps(colors),
                type_line,
                oracle_text,
                cmc,
                "" if power is None else str(power),
                "" if toughness is None else str(toughness),
                "[]",
                f"scryfall-{battle.normalize_card_name(name)}",
            ),
        )

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

    def test_learned_opponent_commander_uses_oracle_metadata():
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
        _insert_oracle_card(
            conn,
            "Thrasios, Triton Hero",
            color_identity=["G", "U"],
            type_line="Legendary Creature - Merfolk Wizard",
            oracle_text="{4}: Scry 1, then reveal the top card of your library.",
            mana_cost="{G}{U}",
            cmc=2,
            power=1,
            toughness=3,
        )

        cache = battle.load_card_oracle_cache(conn, ["Thrasios, Triton Hero"])
        commander = battle.build_learned_commander_card(
            "Thrasios, Triton Hero",
            cache,
            owner="Thrasios #101 (real)",
        )

        assert commander["cmc"] == 2
        assert commander["mana_cost"] == "{G}{U}"
        assert commander["type_line"] == "Legendary Creature - Merfolk Wizard"
        assert commander["power"] == 1
        assert commander["toughness"] == 3
        assert commander["is_commander"] is True
        assert commander["owner"] == "Thrasios #101 (real)"
        assert commander["_commander_metadata_source"] == "oracle_cache"
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
                        "card_id": "unit-card-id",
                        "semantic_hash": "unit-semantic-hash",
                        "type_line": "Instant",
                        "oracle_text": "A deliberately weird test card.",
                    }
                )

                assert effect["effect"] == "counter"
                assert effect["_rule_source"] == "manual"
                assert effect["_rule_logical_key"].startswith("battle_rule_v1:")
                assert effect["_rule_oracle_hash"] == "unit-oracle-hash"
                replay_fields = battle.replay_rule_fields(effect)
                assert replay_fields["card_id"] == "unit-card-id"
                assert replay_fields["semantic_hash"] == "unit-semantic-hash"
                assert replay_fields["rule_logical_key"] == effect["_rule_logical_key"]
                assert replay_fields["rule_oracle_hash"] == "unit-oracle-hash"
                assert battle.is_instant({"name": "Registry Counter", "type_line": "Instant"})
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()

    def test_manual_runtime_waiver_can_override_registry_rule():
        if battle.battle_rule_registry is None:
            raise AssertionError("battle_rule_registry failed to import")
        old_db = battle.DB
        old_manual_rule = battle.HANDCRAFTED_KNOWN_CARD_RULES.get("Waived Manual Card")
        had_handcrafted = "Waived Manual Card" in battle.HANDCRAFTED_KNOWN_CARDS
        had_waiver = "Waived Manual Card" in battle.MANUAL_RULE_RUNTIME_WAIVERS
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "rules.db"
            conn = sqlite3.connect(db_path)
            battle.battle_rule_registry.upsert_battle_card_rule(
                conn,
                "Waived Manual Card",
                {"effect": "counter", "instant": True},
                source="manual",
                confidence=1.0,
                review_status="verified",
                notes="Registry rule for waiver precedence test.",
            )
            conn.commit()
            conn.close()

            try:
                battle.HANDCRAFTED_KNOWN_CARD_RULES["Waived Manual Card"] = {
                    "effect": "draw_cards",
                    "count": 2,
                }
                battle.HANDCRAFTED_KNOWN_CARDS.add("Waived Manual Card")
                battle.MANUAL_RULE_RUNTIME_WAIVERS.add("Waived Manual Card")
                battle.DB = str(db_path)
                battle.battle_rule_registry._RULE_CACHE.clear()
                effect = battle.get_card_effect(
                    {
                        "name": "Waived Manual Card",
                        "type_line": "Sorcery",
                        "oracle_text": "Draw two cards.",
                    }
                )

                assert effect["effect"] == "draw_cards"
                assert effect["_rule_source"] == "known_cards_manual"
            finally:
                battle.DB = old_db
                battle.battle_rule_registry._RULE_CACHE.clear()
                if old_manual_rule is None:
                    battle.HANDCRAFTED_KNOWN_CARD_RULES.pop("Waived Manual Card", None)
                else:
                    battle.HANDCRAFTED_KNOWN_CARD_RULES["Waived Manual Card"] = old_manual_rule
                if not had_handcrafted:
                    battle.HANDCRAFTED_KNOWN_CARDS.discard("Waived Manual Card")
                if not had_waiver:
                    battle.MANUAL_RULE_RUNTIME_WAIVERS.discard("Waived Manual Card")

    def test_load_deck_preserves_semantic_snapshot_identity_fields():
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "deck.db"
            conn = sqlite3.connect(db_path)
            conn.execute(
                """
                CREATE TABLE deck_cards (
                    deck_id INTEGER,
                    card_id TEXT,
                    card_name TEXT,
                    quantity INTEGER,
                    cmc REAL,
                    functional_tag TEXT,
                    functional_tags_json TEXT,
                    type_line TEXT,
                    oracle_text TEXT,
                    is_commander INTEGER,
                    semantics_hash TEXT
                )
                """
            )
            conn.execute(
                """
                INSERT INTO deck_cards (
                    deck_id, card_id, card_name, quantity, cmc, functional_tag,
                    functional_tags_json, type_line, oracle_text, is_commander,
                    semantics_hash
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    6,
                    "card-id-1",
                    "Semantic Draw",
                    1,
                    1,
                    "draw",
                    json.dumps(["draw"]),
                    "Instant",
                    "Draw two cards.",
                    0,
                    "semantic-hash-1",
                ),
            )
            conn.commit()
            conn.close()

            try:
                battle.DB = str(db_path)
                commander, deck = battle.load_deck()
                assert commander is None
                assert len(deck) == 1
                assert deck[0]["card_id"] == "card-id-1"
                assert deck[0]["semantic_hash"] == "semantic-hash-1"
                effect = battle.get_card_effect(deck[0])
                replay_fields = battle.replay_rule_fields(effect)
                assert replay_fields["card_id"] == "card-id-1"
                assert replay_fields["semantic_hash"] == "semantic-hash-1"
            finally:
                battle.DB = old_db

    def test_load_deck_construction_report_accepts_valid_commander_shape():
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "deck.db"
            conn = sqlite3.connect(db_path)
            _create_deck_schema(conn)
            _insert_oracle_card(
                conn,
                "Talrand, Sky Summoner",
                color_identity=["U"],
                type_line="Legendary Creature - Merfolk Wizard",
                oracle_text="Whenever you cast an instant or sorcery spell, create a Drake token.",
                power=2,
                toughness=2,
            )
            _insert_oracle_card(
                conn,
                "Island",
                color_identity=[],
                type_line="Basic Land - Island",
                oracle_text="",
            )
            _insert_deck_card(
                conn,
                "Talrand, Sky Summoner",
                is_commander=1,
                type_line="Legendary Creature - Merfolk Wizard",
            )
            _insert_deck_card(conn, "Island", quantity=99, functional_tag="land")
            conn.commit()
            conn.close()

            try:
                battle.DB = str(db_path)
                commander, deck, report = battle.load_deck_with_construction_report()
                assert commander["name"] == "Talrand, Sky Summoner"
                assert len(deck) == 99
                assert report["is_valid"] is True
                assert report["main_quantity"] == 99
                assert report["total_quantity"] == 100
                assert report["commander_color_identity"] == ["blue"]
                assert report["singleton_violations"] == []
                assert report["off_color_cards"] == []
            finally:
                battle.DB = old_db

    def test_load_deck_ignores_zero_quantity_rows():
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "deck.db"
            conn = sqlite3.connect(db_path)
            _create_deck_schema(conn)
            _insert_oracle_card(
                conn,
                "Talrand, Sky Summoner",
                color_identity=["U"],
                type_line="Legendary Creature - Merfolk Wizard",
                oracle_text="Whenever you cast an instant or sorcery spell, create a Drake token.",
                power=2,
                toughness=2,
            )
            _insert_oracle_card(
                conn,
                "Island",
                color_identity=[],
                type_line="Basic Land - Island",
                oracle_text="",
            )
            _insert_oracle_card(
                conn,
                "Zero Quantity Spell",
                color_identity=["U"],
                type_line="Sorcery",
                oracle_text="Draw a card.",
            )
            _insert_deck_card(conn, "Talrand, Sky Summoner", is_commander=1)
            _insert_deck_card(conn, "Island", quantity=99, functional_tag="land")
            _insert_deck_card(
                conn,
                "Zero Quantity Spell",
                quantity=0,
                functional_tag="draw",
                type_line="Sorcery",
                oracle_text="Draw a card.",
            )
            conn.commit()
            conn.close()

            try:
                battle.DB = str(db_path)
                commander, deck, report = battle.load_deck_with_construction_report()
                assert commander["name"] == "Talrand, Sky Summoner"
                assert len(deck) == 99
                assert all(item["name"] != "Zero Quantity Spell" for item in deck)
                assert report["is_valid"] is True
                assert report["main_quantity"] == 99
                assert report["total_quantity"] == 100
                assert report["issues"] == []
            finally:
                battle.DB = old_db

    def test_load_deck_construction_report_flags_singleton_violations():
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "deck.db"
            conn = sqlite3.connect(db_path)
            _create_deck_schema(conn)
            _insert_oracle_card(
                conn,
                "Talrand, Sky Summoner",
                color_identity=["U"],
                type_line="Legendary Creature - Merfolk Wizard",
            )
            _insert_oracle_card(conn, "Island", type_line="Basic Land - Island")
            _insert_oracle_card(conn, "Sol Ring", type_line="Artifact")
            _insert_deck_card(conn, "Talrand, Sky Summoner", is_commander=1)
            _insert_deck_card(conn, "Sol Ring", quantity=2, functional_tag="ramp")
            _insert_deck_card(conn, "Island", quantity=97, functional_tag="land")
            conn.commit()
            conn.close()

            try:
                battle.DB = str(db_path)
                _, _, report = battle.load_deck_with_construction_report()
                assert report["is_valid"] is False
                assert "singleton_violations" in report["issues"]
                assert report["singleton_violations"] == [
                    {"name": "Sol Ring", "count": 2, "card_id": "card-sol ring"}
                ]
                assert report["main_quantity"] == 99
                assert report["total_quantity"] == 100
            finally:
                battle.DB = old_db

    def test_load_deck_construction_report_flags_off_color_cards():
        old_db = battle.DB
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "deck.db"
            conn = sqlite3.connect(db_path)
            _create_deck_schema(conn)
            _insert_oracle_card(
                conn,
                "Talrand, Sky Summoner",
                color_identity=["U"],
                type_line="Legendary Creature - Merfolk Wizard",
            )
            _insert_oracle_card(conn, "Island", type_line="Basic Land - Island")
            _insert_oracle_card(
                conn,
                "Lightning Bolt",
                color_identity=["R"],
                type_line="Instant",
                oracle_text="Lightning Bolt deals 3 damage to any target.",
            )
            _insert_deck_card(conn, "Talrand, Sky Summoner", is_commander=1)
            _insert_deck_card(conn, "Lightning Bolt", quantity=1, functional_tag="removal")
            _insert_deck_card(conn, "Island", quantity=98, functional_tag="land")
            conn.commit()
            conn.close()

            try:
                battle.DB = str(db_path)
                _, _, report = battle.load_deck_with_construction_report()
                assert report["is_valid"] is False
                assert "off_color_cards" in report["issues"]
                assert report["off_color_cards"] == [
                    {
                        "name": "Lightning Bolt",
                        "card_id": "card-lightning bolt",
                        "color_identity": ["red"],
                        "off_identity_colors": ["red"],
                    }
                ]
            finally:
                battle.DB = old_db

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
        test_learned_opponent_commander_uses_oracle_metadata,
        test_battle_card_rules_table_overrides_fallbacks,
        test_load_deck_preserves_semantic_snapshot_identity_fields,
        test_load_deck_construction_report_accepts_valid_commander_shape,
        test_load_deck_ignores_zero_quantity_rows,
        test_load_deck_construction_report_flags_singleton_violations,
        test_load_deck_construction_report_flags_off_color_cards,
        test_lands_are_not_instant_or_sorcery_even_with_generated_metadata,
        test_end_step_window_does_not_cast_lands,
        test_zuran_orb_is_life_artifact_not_mana_rock,
        test_vexing_bauble_is_hate_artifact_not_immediate_draw,
        test_known_land_name_without_oracle_imports_as_land_not_creature,
        test_unknown_card_without_oracle_does_not_default_to_creature,
        test_rule_sync_oracle_normalizes_generated_land_rules,
    ]
