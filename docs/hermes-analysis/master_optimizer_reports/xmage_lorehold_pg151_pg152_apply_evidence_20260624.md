# XMage Lorehold PG151 and PG152 Evidence

Generated on 2026-06-24.

## Scope

- Branch: `codex/xmage-absorption-20260623`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite/Hermes DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

## PG151: Magda, Brazen Outlaw

- Exact scope implemented:
  - `magda_dwarf_tap_treasure_and_five_treasure_tutor_v1`
- Runtime/test coverage added:
  - tapped Dwarf trigger creates Treasure
  - sacrifice five Treasures tutors artifact or Dragon to battlefield
- Package artifacts:
  - `pg151_magda_brazen_outlaw_package_20260624_*`
- Precheck result:
  - card row found
  - canonical card id `7d68da40-369b-4cc0-a144-b6b93c64d51e`
  - existing rule rows `3`
  - expected exact rule rows before apply `1`
- Apply:
  - status `ok`
- Postcheck result:
  - promoted rule rows `1`
  - promoted verified auto rows `1`
  - promoted oracle-hash rows `1`
  - backup rows `2`
- Hermes sync report:
  - `battle_card_rules_sqlite_from_pg_pg151_magda_brazen_outlaw_20260624.json`
  - `selected_card_count=1`
  - `pg_rows_loaded=3`
  - `sqlite_inserted_or_updated=3`
- Pipeline evidence:
  - presync prefix `xmage_current_replay_batch_pipeline_20260624_pg151_presync_real_v1`
  - postsync prefix `xmage_current_replay_batch_pipeline_20260624_pg151_postsync_real_v1`
  - Magda moved out of the pending proposal lane and remained only as residual coherence noise from historical active rows.

## PG152: Bartolomé del Presidio

- Structural unblock delivered before promotion:
  - XMage resolver now strips accents for Java class lookup
  - XMage resolver now searches `Mage/src/main/java/mage/cards/basiclands`
- Exact scope implemented:
  - `sacrifice_another_creature_or_artifact_put_plus_one_counter_on_self_v1`
- Runtime/test coverage added:
  - precombat sacrifice outlet growth using expendable creature/artifact fodder
  - exact oracle normalization test
- Package artifacts:
  - `pg152_bartolome_del_presidio_package_20260624_*`
- Precheck result:
  - card row found
  - canonical card id `76a966c3-7b74-40d9-b7ec-260d052f224e`
  - existing rule rows `0`
  - expected exact rule rows before apply `0`
- Apply:
  - status `ok`
- Postcheck result:
  - promoted rule rows `1`
  - promoted verified auto rows `1`
  - promoted oracle-hash rows `1`
  - backup rows `0`
- Hermes sync report:
  - `battle_card_rules_sqlite_from_pg_pg152_bartolome_del_presidio_20260624.json`
  - `selected_card_count=1`
  - `pg_rows_loaded=1`
  - `sqlite_inserted_or_updated=1`
- Pipeline evidence:
  - candidate prefix before apply `xmage_current_replay_batch_pipeline_20260624_bartolome_exact_real_v1`
  - postsync prefix `xmage_current_replay_batch_pipeline_20260624_pg152_postsync_real_v1`
  - candidate row before apply:
    - `Bartolomé del Presidio | creature | batch_pg_candidate_after_precheck`
  - postsync summary:
    - `severity_counts={"high": 212, "medium": 38, "pass": 284}`
    - `validity_status_counts={"xmage_source_valid_mapper_required": 234}`
    - `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 234}`

## Queue impact

- `blocked_missing_xmage_class` dropped from `3` to `0` after the XMage resolver fixes.
- `Bartolomé del Presidio` was promoted and removed from the proposal queue after PG152 postsync.
- Current residual queue is now pure `xmage_source_valid_mapper_required`, without missing-local-XMage blockers.
