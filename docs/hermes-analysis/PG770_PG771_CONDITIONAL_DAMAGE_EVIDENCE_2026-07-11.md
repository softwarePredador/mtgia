# PG770/PG771 Conditional Damage Evidence - 2026-07-11

Status: applied on new PostgreSQL target `127.0.0.1:15432/halder`.

## PG770 - Kicker Conditional Damage

Scope: `xmage_conditional_fixed_damage_target_spell_v1`.

Promoted cards:

- Burst Lightning: base 2, kicked 4, kicker `{4}`
- Firebending Lesson: base 2, kicked 5, kicker `{4}`
- Roil Eruption: base 3, kicked 5, kicker `{5}`
- Shivan Fire: base 2, kicked 4, kicker `{4}`

Evidence:

- Split report: `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg770_kicker_conditional_damage_new_server.json`
- Package manifest: `master_optimizer_reports/pg770_kicker_conditional_damage_new_server_manifest.json`
- PostgreSQL apply/postcheck: 4 upserts, 4 verified auto rows, 4 oracle-hash rows, 0 shadow rows deprecated
- SQLite sync: `pg_rows_loaded=10098`, `sqlite_inserted_or_updated=9876`, `canonical_snapshot_rows_exported=7489`
- E2E: `pg770_kicker_conditional_damage_new_server_e2e.json`, status `pass`, damages `4/5/5/4`

## PG771 - Contextual Conditional Damage

Scope: `xmage_conditional_fixed_damage_target_spell_v1`.

Promoted cards:

- Firecannon Blast: raid, base 3, condition 6
- Frost Bite: three or more snow permanents, base 2, condition 3
- Galvanize: two or more cards drawn this turn, base 3, condition 5
- Invasive Maneuvers: controls Spacecraft, base 3, condition 5

Explicitly not promoted:

- Bring Low: condition depends on the selected target having a +1/+1 counter; current direct-damage amount resolution occurs before target selection, so this needs a target-aware runtime change.
- Plasma Bolt: void condition still needs battlefield-left/warped-spell tracking.
- Slaying Fire: adamant condition still needs cast-mana color tracking.
- Arrow Storm: conditional damage also has `damage can't be prevented`, which is a separate prevention/runtime scope.

Evidence:

- Split report: `master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg771_contextual_conditional_damage_new_server.json`
- Package manifest: `master_optimizer_reports/pg771_contextual_conditional_damage_new_server_manifest.json`
- PostgreSQL apply/postcheck: 4 upserts, 4 verified auto rows, 4 oracle-hash rows, 0 shadow rows deprecated
- SQLite sync: `pg_rows_loaded=10102`, `sqlite_inserted_or_updated=9880`, `canonical_snapshot_rows_exported=7493`
- E2E: `pg771_contextual_conditional_damage_new_server_e2e.json`, status `pass`, damages `6/3/5/5`

## Global Counters

Baseline before this evidence set:

- `battle_and_oracle_ready=6499`
- `battle_family_mapper_required=27377`
- `xmage_authoritative_adapter_required_count=24141`

After PG770:

- `battle_and_oracle_ready=6503`
- `battle_family_mapper_required=27373`
- `xmage_authoritative_adapter_required_count=24137`

After PG771:

- `battle_and_oracle_ready=6507`
- `battle_family_mapper_required=27369`
- `xmage_authoritative_adapter_required_count=24133`

Post-PG771 alignment gates:

- `xmage_strategy_consistency_audit_20260711_post_pg771_contextual_conditional_damage_new_server_final`: pass, 26/26
- `pg_hermes_sqlite_contract_audit_20260711_post_pg771_contextual_conditional_damage_new_server_final`: pass, 51/51
- `operational_surface_alignment_audit_20260711_post_pg771_contextual_conditional_damage_new_server_final`: pass
- `legacy_contamination_audit_20260711_post_pg771_contextual_conditional_damage_new_server_final`: pass

Next split:

- `xmage_authoritative_exact_scope_split_20260711_post_pg771_next_new_server`
- Safe package candidates: 0
- Remaining proposals: 3 `xmage_simple_tap_mana_source_permanent_v1` runtime partial review-only rows, intentionally not promoted.
