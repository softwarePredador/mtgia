# PG767 Shaman Formidable Life Reset Evidence - 2026-07-11

Status: `applied_synced_validated`.

Database target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`.

## Runtime Scope

- Card: `Shaman of Forgotten Ways`
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/ShamanOfForgottenWays.java`
- ManaLoom scope: `xmage_simple_tap_restricted_mana_source_with_formidable_life_total_reset_v1`
- Logical rule key: `battle_rule_v1:cf0bd9ea965d4aac08811c1d74300374`
- Oracle hash: `182c9953ec3d764f9ab6a77500987289`

Implemented behavior:

- `{T}: Add two mana in any combination of colors. Spend this mana only to cast creature spells.`
- `Formidable - {9}{G}{G}, {T}: Each player's life total becomes the number of creatures they control. Activate only if creatures you control have total power 8 or greater.`
- Battle refresh preserves Shaman for the Formidable activation when the life reset is materially better than using it as a mana source.

## Package Evidence

- Split: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg767_shaman_formidable_new_server.json`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg767_shaman_formidable_new_server_manifest.json`
- Precheck/apply/postcheck: `docs/hermes-analysis/master_optimizer_reports/pg767_shaman_formidable_new_server_{precheck,apply,postcheck}.sql`
- SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg767_shaman_formidable_new_server_sqlite_sync.json`
- Final E2E: `docs/hermes-analysis/master_optimizer_reports/pg767_shaman_formidable_new_server_post_pg767b_e2e.json`

PG767 apply result:

- `target_card_rows=1`
- `existing_rule_rows=0`
- `upserted_rows=1`
- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`

E2E result:

- PostgreSQL source of truth: `pass`
- SQLite/Hermes cache: `pass`
- Canonical snapshot fallback: `pass`
- Runtime lookup: `pass`
- Battle execution: `pass`
- Restricted mana subcheck: `conditional_mana=2`, `sources=1`
- Formidable subcheck: controller life `2`, opponent life `2`, source tapped after activation `true`

## PG767B Hash Backfill

The post-PG767 PG/Hermes audit found old trusted executable rules without `oracle_hash`. PG767B performed a metadata-only backfill from `cards.oracle_text`.

- Precheck target rows: `55`
- Backfilled rows: `55`
- Postcheck remaining trusted executable rules missing `oracle_hash`: `0`
- Backup table: `manaloom_deploy_audit.pg767b_trusted_rule_oracle_hash_backfill_20260711`
- SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg767b_trusted_rule_oracle_hash_backfill_new_server_sqlite_sync.json`

## Final Audits

- XMage strategy consistency: `pass`, `26/26`
- Operational surface alignment: `pass`
- Legacy contamination: `pass`
- PG/Hermes/SQLite contract after PG767B: `pass`, `51/51`
- Global readiness after PG767B:
  - `battle_and_oracle_ready=6495`
  - `battle_family_mapper_required=27381`
  - `snapshot_has_verified_rule=6520`
  - `snapshot_has_any_rule=7688`
- XMage authoritative queue after PG767B:
  - `target_identity_count=24458`
  - `xmage_authoritative_source_count=24145`
  - `xmage_authoritative_adapter_required_count=24145`
  - `xmage_missing_source_exception_count=313`
  - `xmage_authoritative_parser_gap_count=0`
- Next exact split:
  - `safe_for_batch_pg_package_count=0`
  - Remaining partial candidates in this mana-source auxiliary track: `Codie, Vociferous Codex`, `Coveted Jewel`, `Sage of the Maze`, `Strixhaven Stadium`
