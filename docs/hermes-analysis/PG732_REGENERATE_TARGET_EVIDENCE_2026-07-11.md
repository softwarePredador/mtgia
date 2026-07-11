# PG732 regenerate target evidence - 2026-07-11

Status: applied on new server PostgreSQL through `server/bin/with_new_server_pg.sh`.

## Scope

Implemented and promoted the exact XMage -> ManaLoom family:

- `xmage_permanent_simple_activated_regenerate_target_v1`
- XMage signal: `RegenerateTargetEffect + SimpleActivatedAbility + TargetCreaturePermanent`
- Supported Oracle form: `Regenerate target creature.`
- Supported costs: mana, tap, discard card, random discard, life payment
- Explicitly blocked for this wave: filtered targets such as artifact creature or Treefolk, sacrifice costs, return-to-hand costs, remove-counter costs, alternate/composite costs

Promoted cards:

- Draconian Cylix
- Medicine Bag
- Niall Silvain
- Ragnar
- Rushwood Herbalist
- Suture Spirit

## Runtime and tests

Runtime changed:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - added `SIMPLE_ACTIVATED_REGENERATE_TARGET_SCOPE`
  - added regenerate-target activation detection
  - added legal target selection for target creature
  - added activation executor that pays costs, creates a regeneration shield on the target, and emits replay/decision trace

Package/test tooling changed:

- `xmage_authoritative_exact_scope_split.py`
- `xmage_batch_pg_package_builder.py`
- `battle_package_end_to_end_validation.py`
- focused tests for splitter, package builder, and battle E2E

Focused test result:

```text
15 passed, 1223 deselected
```

Command:

```bash
python3 -m pytest \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py -k "regenerate_target or regenerate_source" \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py -k "regenerate_target or regenerate_source" \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k "regenerate_target or regenerate_source"
```

## PostgreSQL package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_package_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_package_package.md`

Precheck:

- target card rows: 6
- existing rule rows: 0
- shadow rows deprecated: 0

Apply/postcheck:

- upserted rows: 6
- promoted verified auto rows: 6
- promoted oracle hash rows: 6

## Sync and E2E

Sync artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_metadata_sync.json`

E2E artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/pg732_regenerate_target_new_server_e2e_validation.md`

E2E status: `pass`

Validated stages:

- PostgreSQL source of truth: 6 rows
- SQLite/Hermes cache: 6 rows
- canonical snapshot fallback: 6 cards
- runtime `get_card_effect`: 6 cards
- battle execution: 6 scenarios, 12 events

Each promoted card activated regenerate-target, created a regeneration shield on the target creature, and the target survived a destroy move with shield consumed.

## PG732B hash backfill

The final PG/Hermes/SQLite contract audit found trusted executable rules missing `oracle_hash`. This was not caused by PG732, but it blocks the current gate.

PG732B files:

- `docs/hermes-analysis/master_optimizer_reports/pg732b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg732b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg732b_trusted_rule_oracle_hash_backfill_new_server_metadata_sync.json`

PG732B result:

- precheck missing hashes: 55
- backfilled rows: 55
- postcheck missing hashes: 0
- backfilled rows matching `md5(cards.oracle_text)`: 55

## Final audits

Passed:

- `xmage_strategy_consistency_audit_20260711_post_pg732_regenerate_target_new_server_final`
- `operational_surface_alignment_audit_20260711_post_pg732_regenerate_target_new_server_final`
- `legacy_contamination_audit_20260711_post_pg732_regenerate_target_new_server_final`
- `pg_hermes_sqlite_contract_audit_20260711_post_pg732b_regenerate_target_hash_backfill_new_server_final`
- `./scripts/quality_gate.sh server-target`

Final readiness after PG732B:

- total cards: 34,331
- verified battle rule: 6,383
- strict Oracle + function + verified rule: 4,864
- Commander-legal strict: 4,777
- readiness lane `trusted_rule_oracle_hash_backfill`: absent

Commander-legal XMage queue after PG732:

- target identities: 24,595
- XMage authoritative adapter required: 24,282
- parser gaps: 0
- missing-source exceptions: 313

The global goal remains active; PG732 closed this exact regenerate-target subfamily and removed the hash-integrity blocker, but the all-card XMage adapter queue is not complete.
