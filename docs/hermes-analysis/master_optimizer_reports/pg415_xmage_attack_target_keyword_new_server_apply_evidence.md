# PG415 Attack Target Keyword Evidence

Status: `applied_postchecked_synced`.

PG415 promoted the XMage-backed attack-trigger target-keyword-until-end-of-turn
family plus one newly unlocked already-supported activated target-keyword row.

Runtime scopes:

- `xmage_creature_attack_grant_keyword_target_creature_until_eot_v1`: 10 cards.
- `xmage_permanent_simple_activated_target_keyword_until_eot_v1`: 1 card.

Validation:

- Split: 11 exact proposals selected.
- Precheck: 11 target card rows, 0 existing rule rows, 0 shadow rows to deprecate.
- Apply: 11 upserted rows, 0 deprecated shadow rows.
- Postcheck: 11 promoted rows, all `verified` / `auto`, all Oracle hash matched.
- PG -> SQLite sync: 11 PG rows loaded, 11 SQLite rows inserted/updated, canonical snapshot rows `5443`.
- Metadata sync: 6432 PostgreSQL card rows matched, 6359 SQLite alias rows present, 108 `deck_cards.card_id` backfill updates, 1 unresolved alias.
- E2E package validation: PostgreSQL `11/11`, SQLite `11/11`, canonical snapshot `11/11`, runtime `get_card_effect` `11/11`.
- Focused tests: `test_xmage_authoritative_exact_scope_split.py` 423 tests passed; `test_xmage_exact_scope_runtime.py` 242 tests passed; package/sync helpers 27 tests passed.
- Final audits: XMage strategy `26/26`, operational surface pass, PG/Hermes/SQLite contract `51/51`, legacy contamination pass.
- Queue delta: target identity count `26593 -> 26582`; adapter-required `26279 -> 26268`; target-keyword/protection work unit `1114 -> 1103`.
- Post-PG415 exact-scope recheck: `proposal_count=0`.

Selected cards:

- `Aerial Guide`
- `Chasm Drake`
- `Garrison Griffin`
- `Heavenly Qilin`
- `Kinsbaile Balloonist`
- `Majestic Heliopterus`
- `Pegasus Courser`
- `Roc Charger`
- `Trailblazing Historian`
- `Trained Condor`
- `Trusted Pegasus`

Evidence files:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg415_attack_target_keyword_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg415_xmage_attack_target_keyword_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg415_attack_target_keyword_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg415_attack_target_keyword_new_server_recheck.json`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg415_attack_target_keyword_new_server.json`
