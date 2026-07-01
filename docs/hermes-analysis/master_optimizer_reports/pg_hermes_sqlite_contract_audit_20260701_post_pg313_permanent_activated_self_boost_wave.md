# PG Hermes SQLite Contract Audit

- Generated at: `2026-07-01T15:27:23.427993+00:00`
- Status: `pass`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Summary: `{"check_count": 49, "status_counts": {"pass": 48, "warn": 1}}`

| Check | Status | Detail |
| --- | --- | --- |
| `sqlite_db.active` | `pass` | /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db |
| `sqlite_schema.battle_card_rules` | `pass` | ok |
| `sqlite_rows.battle_card_rules` | `pass` | rows=6803 |
| `sqlite_schema.card_legalities` | `pass` | ok |
| `sqlite_rows.card_legalities` | `pass` | rows=32092 |
| `sqlite_schema.card_oracle_cache` | `pass` | ok |
| `sqlite_rows.card_oracle_cache` | `pass` | rows=5579 |
| `sqlite_schema.deck_cards` | `pass` | ok |
| `sqlite_rows.deck_cards` | `pass` | rows=2699 |
| `sqlite_schema.format_staples` | `pass` | ok |
| `sqlite_rows.format_staples` | `pass` | rows=748 |
| `sqlite_schema.learned_decks` | `pass` | ok |
| `sqlite_rows.learned_decks` | `pass` | rows=120 |
| `sqlite_json.battle_card_rules.deck_role_json` | `pass` | scanned=6803 |
| `sqlite_json.battle_card_rules.effect_json` | `pass` | scanned=6803 |
| `sqlite_json.card_oracle_cache.color_identity_json` | `pass` | scanned=5579 |
| `sqlite_json.card_oracle_cache.colors_json` | `pass` | scanned=5579 |
| `sqlite_json.card_oracle_cache.keywords_json` | `pass` | scanned=5579 |
| `sqlite_json.deck_cards.battle_rules_json` | `pass` | scanned=2699 |
| `sqlite_json.deck_cards.functional_tags_json` | `pass` | scanned=2699 |
| `sqlite_json.deck_cards.semantic_tags_v2_json` | `pass` | scanned=2699 |
| `sqlite_json.learned_decks.card_list` | `pass` | scanned=120 |
| `sqlite_integrity.card_oracle_cache_card_id` | `pass` | postgres_cache_rows_missing_card_id=0 |
| `sqlite_integrity.deck_cards_target_card_id` | `pass` | deck_id_6_missing_card_id=0 |
| `sqlite_integrity.deck_cards_global_card_id` | `pass` | all_deck_cards_missing_card_id=0 |
| `sqlite_integrity.deck_cards_card_id_cache_drift` | `pass` | deck_cards_rows_with_card_id_drift=0 |
| `sqlite_integrity.deck_cards_name_aliases_canonicalized_by_card_id` | `pass` | name_alias_rows_with_matching_card_id=37 |
| `sqlite_integrity.battle_rules_trusted_oracle_hash_coverage` | `warn` | trusted_executable_rules_missing_oracle_hash=1418 |
| `sqlite_integrity.commander_legality.worldfire` | `pass` | actual=legal expected=legal |
| `sqlite_integrity.commander_legality.mana_crypt` | `pass` | actual=banned expected=banned |
| `pg_sqlite_parity.battle_card_rules_runtime_keys` | `pass` | sqlite_runtime_keys=6162 pg_runtime_keys=6159 unresolved=0 |
| `pg_sqlite_parity.deck_id_6_pg_snapshot` | `pass` | pg_deck_id=528c877f-f829-4207-95e6-73981776c323 sqlite_rows=100 pg_rows=100 sqlite_qty=100 pg_qty=100 |
| `pg_connection` | `pass` | 143.198.230.247:5433/halder |
| `pg_schema.card_battle_rules` | `pass` | ok |
| `pg_rows.card_battle_rules` | `pass` | rows=7101 |
| `pg_schema.card_intelligence_snapshot` | `pass` | ok |
| `pg_rows.card_intelligence_snapshot` | `pass` | rows=34331 |
| `pg_schema.card_legalities` | `pass` | ok |
| `pg_rows.card_legalities` | `pass` | rows=393764 |
| `pg_schema.cards` | `pass` | ok |
| `pg_rows.cards` | `pass` | rows=34331 |
| `pg_schema.commander_learning_snapshot` | `pass` | ok |
| `pg_rows.commander_learning_snapshot` | `pass` | rows=107 |
| `pg_schema.deck_cards` | `pass` | ok |
| `pg_rows.deck_cards` | `pass` | rows=52182 |
| `pg_schema.format_staples` | `pass` | ok |
| `pg_rows.format_staples` | `pass` | rows=748 |
| `pg_schema.meta_decks` | `pass` | ok |
| `pg_rows.meta_decks` | `pass` | rows=653 |
