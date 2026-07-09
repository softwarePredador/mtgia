# PG683 Destroy Target Controller Damage Evidence - 2026-07-09

Status: `applied_and_validated`.

Scope:

- `Cryoclasm`
- `Melt Terrain`
- `Peak Eruption`
- `Poison the Well`

Implemented runtime scope:

- `xmage_destroy_target_and_target_controller_damage_spell_v1`
- `effect=remove_permanent`
- `resolution_order=destroy_then_target_controller_damage`
- `target_controller_damage_on_resolve` applies fixed damage to the removed target's controller.

Database target:

- `server/bin/with_new_server_pg.sh`
- `127.0.0.1:15432/halder`

PostgreSQL evidence:

- Precheck: 4/4 Oracle-hash matched target rows; each rule already present after idempotent rerun.
- Apply: 4 upserted rows; 0 deprecated shadow rows.
- Postcheck: 4/4 promoted rows, 4/4 `verified/auto`, 4/4 Oracle-hash matched.

Sync evidence:

- `pg_rows_loaded=6080`
- `sqlite_inserted_or_updated=6065`
- `canonical_snapshot_rows_exported=6042`

E2E evidence:

- `status=pass`
- 4 battle execution scenarios.
- 16 replay events.
- Each legal land target moved to graveyard.
- Each illegal fixture stayed on battlefield.
- Target controller damage applied: Cryoclasm 3, Melt Terrain 2, Peak Eruption 3, Poison the Well 2.

Focused tests:

- `1506 passed, 230 subtests passed`

Audits:

- `quality_gate.sh server-target`: pass
- `xmage_strategy_consistency_audit`: 26/26 pass
- `operational_surface_alignment_audit`: pass
- `legacy_contamination_audit`: pass
- `pg_hermes_sqlite_contract_audit`: 51/51 pass

Queue delta:

- `battle_and_oracle_ready`: 6136 -> 6140
- `battle_family_mapper_required`: 27740 -> 27736
- `xmage_authoritative_adapter_required`: 24504 -> 24500
- `removal_destroy::targeted_destroy_variant_v1`: 490 -> 486
- Post-PG683 exact-scope recheck: `proposal_count=0`

Ignored local raw artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg683_destroy_target_controller_damage_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/pg683_destroy_target_controller_damage_new_server_pg_to_sqlite_sync_runtime_only.json`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260709_post_pg683_destroy_target_controller_damage_new_server.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260709_post_pg683_destroy_target_controller_damage_new_server_commander_legal.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_post_pg683_destroy_target_controller_damage_new_server_recheck.json`
