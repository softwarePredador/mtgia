# PG539 Activated Damage Discard Apply Evidence

- deploy_id: `pg539_activated_damage_discard_new_server`
- package: `docs/hermes-analysis/master_optimizer_reports/pg539_activated_damage_discard_new_server_package_manifest.json`
- database_target: `143.198.230.247:5433/halder`
- status: `applied_and_validated`
- postgres_writes: `true`
- sqlite_hermes_sync: `true`
- battle_e2e: `pass`

## Scope

PG539 closes the XMage-derived `xmage_permanent_simple_activated_damage_v1`
subfamily where an activated damage ability has a discard cost. The runtime now
distinguishes ordinary discard, random discard, and land-card discard costs.

## Cards Promoted

| Card | Damage | Discard target | Random |
| --- | ---: | --- | --- |
| `Mage il-Vec` | 1 | `any_card` | `true` |
| `Molten Vortex` | 2 | `land_card` | `false` |
| `Ogre Shaman` | 2 | `any_card` | `true` |
| `Seismic Assault` | 2 | `land_card` | `false` |
| `Stormbind` | 2 | `any_card` | `true` |

## PostgreSQL Evidence

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg539_activated_damage_discard_new_server_precheck_output.txt`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg539_activated_damage_discard_new_server_apply_output.txt`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg539_activated_damage_discard_new_server_postcheck_output.txt`
- apply result: `upserted_rows=5`, `deprecated_shadow_rows=0`, `COMMIT`
- postcheck result: each promoted card has `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`

## Hermes And Runtime Evidence

- sync: `docs/hermes-analysis/master_optimizer_reports/pg539_activated_damage_discard_new_server_pg_to_sqlite_sync.json`
- sync result: `pg_rows_loaded=5`, `sqlite_inserted_or_updated=5`,
  `canonical_snapshot_rows_exported=6203`
- e2e: `docs/hermes-analysis/master_optimizer_reports/pg539_activated_damage_discard_new_server_e2e_validation.md`
- e2e result: PostgreSQL, SQLite, canonical snapshot, runtime lookup, and battle
  execution all passed
- battle execution: 5 scenarios, 10 battle events, all expected damage and
  discard costs observed

## Queue Delta

- before PG539: `target_identity_count=25812`,
  `xmage_authoritative_adapter_required_count=25498`,
  `manual_semantic_decision_units_remaining=314`
- after PG539: `target_identity_count=25807`,
  `xmage_authoritative_adapter_required_count=25493`,
  `manual_semantic_decision_units_remaining=314`
- direct damage work unit reduced from 780 to 775

## Final Audits

- `xmage_strategy_consistency_audit_20260706_post_pg539_activated_damage_discard_new_server_final.md`: pass, 26/26
- `pg_hermes_sqlite_contract_audit_20260706_post_pg539_activated_damage_discard_new_server_with_pg.md`: pass, 51/51
- `operational_surface_alignment_audit_20260706_post_pg539_activated_damage_discard_new_server.md`: pass
- `legacy_contamination_audit_20260706_post_pg539_activated_damage_discard_new_server.md`: pass

## Residual

This package intentionally does not model the remaining activated-damage
source-cost variants such as exile costs, group tap costs, sacrifice/exile
counters, or repeated payment loops. Those remain in later XMage family batches.
