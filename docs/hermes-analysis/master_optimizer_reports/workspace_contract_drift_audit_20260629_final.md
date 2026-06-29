# Workspace Contract Drift Audit

- Generated at: `2026-06-29T19:22:41.094065+00:00`
- Status: `pass`
- Summary: `{"active_file_count": 24, "check_count": 28, "status_counts": {"pass": 28}}`
- Active SQLite: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Stale sibling SQLite: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/knowledge.db`

| Check | Status | Detail |
| --- | --- | --- |
| `active_files.exist` | `pass` | count=24 |
| `active_files.no_stale_absolute_or_pg_fallbacks` | `pass` | no hits |
| `path_contract.battle_analyst_v9.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py |
| `path_contract.sync_pg_card_metadata_to_hermes.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py |
| `path_contract.sync_pg_legalities.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_legalities.py |
| `path_contract.sync_pg_target_deck_to_hermes.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py |
| `path_contract.sync_pg_meta_decks_to_hermes.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_meta_decks_to_hermes.py |
| `path_contract.sync_battle_card_rules_pg.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py |
| `path_contract.generate_known_cards.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/generate_known_cards.py |
| `path_contract.kc_validator.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/kc_validator.py |
| `path_contract._mana_validator.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/_mana_validator.py |
| `path_contract._update_cron_status.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/_update_cron_status.py |
| `path_contract.wincon_pipeline.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/wincon_pipeline.py |
| `path_contract.import_lorehold_decks.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/import_lorehold_decks.py |
| `path_contract.lorehold_canonical_deck_snapshot.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_canonical_deck_snapshot.py |
| `path_contract.validate_deck_legalities.py` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/validate_deck_legalities.py |
| `path_contract.sync_hermes_learned_deck.sh` | `pass` | server/bin/sync_hermes_learned_deck.sh |
| `path_contract.pull_learning_events.py` | `pass` | server/bin/pull_learning_events.py |
| `path_contract.register_commanders.py` | `pass` | server/bin/register_commanders.py |
| `cron_sequence.known_cards_generator_cron.sh` | `pass` | ordered |
| `cron_sequence.known_cards_validator_cron.sh` | `pass` | ordered |
| `cron_sequence.master_optimizer_preflight_cron.sh` | `pass` | ordered |
| `cron_sequence.master_optimizer_end_to_end.sh` | `pass` | ordered |
| `cron_sequence.master_optimizer_auto_cycle_cron.sh` | `pass` | ordered |
| `cron_sequence.master_optimizer_slot_scan_cron.sh` | `pass` | ordered |
| `sqlite.active_knowledge_db_exists` | `pass` | docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db size=15327232 |
| `sqlite.no_stale_sibling_knowledge_db` | `pass` | absent |
| `query_consumers.no_unsafe_direct_1n_card_joins` | `pass` | no unsafe joins |
