# PG784/PG785 Minus-One Counter Cost Evidence - 2026-07-11

Status: `applied_validated_new_server`.

Scope:

- PG784 promoted `Lethal Sting` from XMage `LethalStingCost` into ManaLoom
  runtime scope `xmage_destroy_target_spell_v1`.
- PG785 generalized the same XMage custom `CostImpl` pattern when it has
  `CounterType.M1M1`, `TargetControlledCreaturePermanent`, and matching Oracle
  text, then promoted `Scarscale Ritual` into
  `xmage_fixed_source_controller_draw_spell_v1`.
- Runtime behavior: pay `put_minus_one_counter_on_controlled_creature` before
  spell resolution; if the cost creature survives, it remains on battlefield
  with the expected `minus_one_counters` count.

PostgreSQL apply evidence:

- PG784 precheck found `Lethal Sting` canonical row and no existing target rule.
  Apply upserted `1` row; postcheck verified `1` promoted
  `verified/auto/oracle_hash` row.
- PG785 precheck found `Scarscale Ritual` canonical row and no existing target
  rule. Apply upserted `1` row; postcheck verified `1` promoted
  `verified/auto/oracle_hash` row.
- Current DB target evidence during PG785 apply:
  `halder` at internal server `10.0.1.14:5432`, through
  `server/bin/with_new_server_pg.sh` resolving to `127.0.0.1:15432/halder`.

Sync and E2E evidence:

- PG784 sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg784_sync_battle_card_rules_pg_report.json`
  exported `7525` canonical snapshot rows and updated `9913` SQLite rows.
- PG785 sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg785_sync_battle_card_rules_pg_report.json`
  exported `7526` canonical snapshot rows and updated `9914` SQLite rows.
- PG784 E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg784_minus_one_counter_cost_new_server_e2e_validation.json`
  passed PostgreSQL, SQLite, canonical snapshot, runtime lookup, and battle
  execution. Battle moved the legal target to graveyard and paid the -1/-1
  counter cost.
- PG785 E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg785_draw_minus_one_counter_cost_new_server_e2e_validation.json`
  passed PostgreSQL, SQLite, canonical snapshot, runtime lookup, and battle
  execution. Battle drew `2` cards and paid the -1/-1 counter cost.

Global counters:

- Post-PG784 readiness:
  `battle_and_oracle_ready=6540`,
  `snapshot_has_verified_rule=6565`,
  `battle_family_mapper_required=27336`.
- Post-PG785 readiness:
  `battle_and_oracle_ready=6541`,
  `snapshot_has_verified_rule=6566`,
  `battle_family_mapper_required=27335`.
- Post-PG785 XMage queue:
  `target_identity_count=24412`,
  `xmage_authoritative_source_count=24099`,
  `xmage_authoritative_adapter_required_count=24099`,
  `xmage_missing_source_exception_count=313`,
  `xmage_authoritative_parser_gap_count=0`.
- Post-PG785 exact split has `safe_for_batch_pg_package_count=0`; the only
  remaining proposals are the 3 simple mana-source partial rows that still need
  family runtime support before promotion.

Tests and audits:

- `python3 -m py_compile` passed for:
  `xmage_authoritative_exact_scope_split.py`,
  `xmage_batch_pg_package_builder.py`,
  `battle_package_end_to_end_validation.py`,
  `battle_analyst_v9.py`.
- Focused runtime/split tests passed for `Lethal Sting` and `Scarscale Ritual`.
- Focused package-builder/E2E function tests passed for both minus-one counter
  additional-cost scenarios.
- `xmage_strategy_consistency_audit_20260711_post_pg785_draw_minus_one_counter_cost_new_server_final`:
  `pass`, 26/26 checks.
- `operational_surface_alignment_audit_20260711_post_pg785_draw_minus_one_counter_cost_new_server_final`:
  `pass`.
- `legacy_contamination_audit_20260711_post_pg785_draw_minus_one_counter_cost_new_server_final`:
  `pass`.
- `pg_hermes_sqlite_contract_audit_20260711_post_pg785_draw_minus_one_counter_cost_new_server_final`:
  `pass`, 51/51 checks.
- `./scripts/quality_gate.sh server-target`: `pass`.

Next actionable lane:

- The broad queue is still active: `24099` XMage-authoritative adapter work
  units remain, with no parser gap.
- The next implementation should target a repeated blocked subpattern, not a
  raw card list. Current high-volume candidates include recursion/draw variants,
  targeted protection, add-counters, direct damage, and simple mana-source
  partials.
