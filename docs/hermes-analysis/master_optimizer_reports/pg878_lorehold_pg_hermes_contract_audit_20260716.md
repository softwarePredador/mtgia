# PG Hermes SQLite Contract Audit

- Generated at: `2026-07-16T09:05:13.589913+00:00`
- Status: `pass`
- PostgreSQL target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Summary: `{"check_count": 55, "status_counts": {"pass": 55}}`

| Check | Status | Detail |
| --- | --- | --- |
| `sqlite_db.active` | `pass` | /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db |
| `sqlite_schema.battle_card_rules` | `pass` | ok |
| `sqlite_rows.battle_card_rules` | `pass` | rows=10583 |
| `sqlite_schema.card_legalities` | `pass` | ok |
| `sqlite_rows.card_legalities` | `pass` | rows=35010 |
| `sqlite_schema.card_oracle_cache` | `pass` | ok |
| `sqlite_rows.card_oracle_cache` | `pass` | rows=9004 |
| `sqlite_schema.deck_cards` | `pass` | ok |
| `sqlite_rows.deck_cards` | `pass` | rows=2693 |
| `sqlite_schema.format_staples` | `pass` | ok |
| `sqlite_rows.format_staples` | `pass` | rows=748 |
| `sqlite_schema.learned_decks` | `pass` | ok |
| `sqlite_rows.learned_decks` | `pass` | rows=120 |
| `sqlite_json.battle_card_rules.deck_role_json` | `pass` | scanned=10583 |
| `sqlite_json.battle_card_rules.effect_json` | `pass` | scanned=10583 |
| `sqlite_json.card_oracle_cache.color_identity_json` | `pass` | scanned=9004 |
| `sqlite_json.card_oracle_cache.colors_json` | `pass` | scanned=9004 |
| `sqlite_json.card_oracle_cache.keywords_json` | `pass` | scanned=9004 |
| `sqlite_json.deck_cards.battle_rules_json` | `pass` | scanned=2693 |
| `sqlite_json.deck_cards.functional_tags_json` | `pass` | scanned=2693 |
| `sqlite_json.deck_cards.semantic_tags_v2_json` | `pass` | scanned=2693 |
| `sqlite_json.learned_decks.card_list` | `pass` | scanned=120 |
| `sqlite_integrity.card_oracle_cache_card_id` | `pass` | postgres_cache_rows_missing_card_id=0 |
| `sqlite_integrity.deck_cards_target_card_id` | `pass` | deck_id_607_missing_card_id=0 |
| `sqlite_integrity.deck_cards_global_card_id` | `pass` | all_deck_cards_missing_card_id=0 |
| `sqlite_integrity.deck_cards_card_id_cache_drift` | `pass` | deck_cards_rows_with_card_id_drift=0 |
| `sqlite_integrity.deck_cards_name_aliases_canonicalized_by_card_id` | `pass` | name_alias_rows_with_matching_card_id=37 |
| `sqlite_integrity.battle_rules_trusted_oracle_hash_coverage` | `pass` | verified_executable_rules_missing_oracle_hash=0 |
| `sqlite_integrity.battle_rules_competing_exact_scope` | `pass` | competing_verified_executable_scope_groups=0 |
| `sqlite_integrity.commander_legality.worldfire` | `pass` | actual=legal expected=legal |
| `sqlite_integrity.commander_legality.mana_crypt` | `pass` | actual=banned expected=banned |
| `pg_sqlite_parity.battle_card_rules_runtime_keys` | `pass` | sqlite_runtime_keys=10109 pg_runtime_keys=10109 unresolved=0 |
| `pg_sqlite_parity.battle_rule_oracle_hashes` | `pass` | comparable_rules=7156 hash_drift=0 |
| `pg_sqlite_parity.protected_deck_607_pg_snapshot` | `pass` | deck_id=607 pg_deck_id=8938b746-1a9e-46ce-b0d9-c2ec932ddddd sqlite_rows=94 pg_rows=94 sqlite_qty=100 pg_qty=100 |
| `pg_sqlite_parity.legacy_deck_6_pg_snapshot` | `pass` | deck_id=6 pg_deck_id=8938b746-1a9e-46ce-b0d9-c2ec932ddddd sqlite_rows=94 pg_rows=94 sqlite_qty=100 pg_qty=100 |
| `pg_connection` | `pass` | 127.0.0.1:15432/halder |
| `pg_schema.card_battle_rules` | `pass` | ok |
| `pg_rows.card_battle_rules` | `pass` | rows=10830 |
| `pg_schema.card_intelligence_snapshot` | `pass` | ok |
| `pg_rows.card_intelligence_snapshot` | `pass` | rows=34331 |
| `pg_schema.card_legalities` | `pass` | ok |
| `pg_rows.card_legalities` | `pass` | rows=393767 |
| `pg_schema.cards` | `pass` | ok |
| `pg_rows.cards` | `pass` | rows=34331 |
| `pg_schema.commander_learning_snapshot` | `pass` | ok |
| `pg_rows.commander_learning_snapshot` | `pass` | rows=113 |
| `pg_schema.deck_cards` | `pass` | ok |
| `pg_rows.deck_cards` | `pass` | rows=8481 |
| `pg_schema.format_staples` | `pass` | ok |
| `pg_rows.format_staples` | `pass` | rows=748 |
| `pg_schema.meta_decks` | `pass` | ok |
| `pg_rows.meta_decks` | `pass` | rows=653 |
| `pg_integrity.battle_rules_trusted_oracle_hash_coverage` | `pass` | verified_executable_rules_missing_oracle_hash=0 |
| `pg_integrity.battle_rules_oracle_hash_current` | `pass` | verified_executable_rules_stale_oracle_hash=0 |
| `pg_integrity.battle_rules_competing_exact_scope` | `pass` | competing_verified_executable_scope_groups=0 |
