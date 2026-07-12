# PG844 Beginning Upkeep Draw/Life-Loss Evidence - 2026-07-12

Status: `applied_validated_runtime_synced`.

Scope:

- Family: `xmage_beginning_upkeep_draw_lose_life`.
- Runtime scope: `xmage_beginning_upkeep_draw_lose_life_v1`.
- Cards promoted: `Baleful Force`, `Phyrexian Arena`.
- Source: local XMage classes in `/Users/desenvolvimentomobile/Downloads/mage-master`.

PostgreSQL package:

- Precheck: 2 target card rows found.
- Apply: 2 rules upserted, 2 stale Phyrexian Arena shadow rows deprecated.
- Postcheck: 1 promoted verified/auto rule per promoted card, both with `oracle_hash`.
- SQL package files:
  - `docs/hermes-analysis/master_optimizer_reports/pg844_beginning_upkeep_draw_lose_life_new_server_precheck.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg844_beginning_upkeep_draw_lose_life_new_server_apply.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg844_beginning_upkeep_draw_lose_life_new_server_postcheck.sql`
  - `docs/hermes-analysis/master_optimizer_reports/pg844_beginning_upkeep_draw_lose_life_new_server_rollback.sql`

Sync and validation:

- `sync_pg_card_metadata_to_hermes.py`: new server target `127.0.0.1:15432/halder`, `matched=2699/2699` deck-card backfill.
- `sync_battle_card_rules_pg.py`: `pg_rows_loaded=10522`, `sqlite_inserted_or_updated=10300`, canonical snapshot rows exported `7786`.
- `battle_package_end_to_end_validation.py`: status `pass`.
  - PostgreSQL source of truth: 2 rows validated.
  - SQLite Hermes cache: 2 rows validated.
  - Canonical fallback snapshot: 2 cards validated.
  - Runtime `get_card_effect`: 2 cards validated.
  - Battle execution: 2 scenarios, 2 events.

Battle execution proof:

- `Baleful Force`: active player `Opponent`, trigger `each_upkeep`, drew 1, lost 1 life.
- `Phyrexian Arena`: active player `Source Controller`, trigger `controller_upkeep`, drew 1, lost 1 life.

Post-PG844 global counters:

- `battle_and_oracle_ready`: 6735.
- `snapshot_has_verified_rule`: 6842.
- `battle_family_mapper_required`: 27059.
- `battle_rule_verification_required`: 70.
- Commander-legal XMage adapter queue: `23835`.
- XMage parser gaps: `0`.
- Missing XMage source exceptions: `313`.

Audits:

- `xmage_strategy_consistency_audit_20260712_post_pg844_beginning_upkeep_draw_lose_life_new_server`: `pass`, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260712_post_pg844_beginning_upkeep_draw_lose_life_new_server`: `pass`, 51 checks.
- Post-PG844 exact split recheck: `safe_for_batch_pg_package_count=0`; only the already-known `The Golden Throne` runtime-partial review proposal remains.
