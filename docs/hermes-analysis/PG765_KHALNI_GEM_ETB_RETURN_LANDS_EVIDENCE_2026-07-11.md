# PG765 Khalni Gem ETB Return Lands Evidence - 2026-07-11

Status: applied on new server PostgreSQL and synced to Hermes/SQLite.

## Scope

- Card: `Khalni Gem`
- XMage source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/k/KhalniGem.java`
- ManaLoom scope: `xmage_simple_mana_source_with_etb_return_lands_to_hand_v1`
- Logical rule key: `battle_rule_v1:06060ff363b50cf932d825d4a4937fac`
- Oracle hash: `d39f34a51eb4e49360a228042c1eb2d9`

## Runtime Behavior

- `{T}: Add two mana of any one color.`
- On enter, return up to two controlled lands to their owner's hand, matching XMage's `Math.min(landCount, 2)` and `Zone.HAND` behavior.
- E2E scenario validated `available_mana=2`, `conditional_mana=2`, `etb_returned_lands_to_hand_count=2`, and `hand_size=2`.

## PostgreSQL Evidence

- Precheck: `target_card_rows=1`, `existing_rule_rows=0`, `would_deprecate_shadow_rows=0`.
- Apply: `upserted_rows=1`, `deprecated_shadow_rows=0`.
- Postcheck: `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.
- Direct PG validation: `review_status=verified`, `execution_status=auto`, `rule_version=2`, `battle_model_scope=xmage_simple_mana_source_with_etb_return_lands_to_hand_v1`, `etb_return_controlled_lands_to_hand_count=2`.

## Sync And Audits

- PG -> SQLite/Hermes sync: `pg_rows_loaded=10088`, `sqlite_inserted_or_updated=9866`, `canonical_snapshot_rows_exported=7480`.
- Package E2E: `status=pass`, `scenario_count=1`, `event_count=4`.
- XMage strategy audit: `pass 26/26`.
- PG/Hermes/SQLite contract audit: `pass 51/51`.
- Operational surface audit: `pass`.
- Legacy contamination audit: `pass`.
- Global readiness after PG765: `battle_and_oracle_ready=6493`, `battle_family_mapper_required=27383`, `snapshot_has_verified_rule=6518`.
- XMage authoritative queue after PG765: `target_identity_count=24460`, `xmage_authoritative_adapter_required_count=24147`, `xmage_authoritative_parser_gap_count=0`, `xmage_missing_source_exception_count=313`.

## Generated Evidence Artifacts

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg765_khalni_gem_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/pg765_khalni_gem_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg765_khalni_gem_new_server_e2e.json`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg765_khalni_gem_new_server_final.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg765_khalni_gem_new_server_final.json`
