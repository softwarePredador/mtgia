# PG763 Draw Lose Half Life Evidence - 2026-07-11

Status: applied to new-server PostgreSQL and validated.

## Scope

- Family: `xmage_draw_lose_half_life_spell`
- Battle model scope: `xmage_controller_draw_lose_half_life_rounded_up_spell_v1`
- Cards promoted:
  - `Cruel Bargain`
  - `Infernal Contract`

## XMage Source

Both local XMage classes use the same narrow source signature:

- `DrawCardSourceControllerEffect(4)`
- `LoseHalfLifeEffect()`

Oracle text:

- `Draw four cards. You lose half your life, rounded up.`

## Implementation

- `xmage_authoritative_exact_scope_split.py`
  - Added exact Oracle/source split for `DrawCardSourceControllerEffect + LoseHalfLifeEffect`.
  - Produces `life_loss_mode=half_rounded_up` and `life_loss_rounding=up`.
- `battle_analyst_v9.py`
  - Extends `resolve_draw_lose_life_spell` to compute half-life loss rounded up from the target player's life at resolution.
- `xmage_batch_pg_package_builder.py`
  - Preserves draw/life-loss E2E fields and builds focused draw-then-lose-life scenarios.
- `battle_package_end_to_end_validation.py`
  - Adds `draw_lose_life_spell` runner validating draw count, life before, life lost, life after, and replay event fields.

## Focused Tests

Command:

```bash
python3 -m pytest -q \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_draw_lose_half_life_spell_maps \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py::XMageAuthoritativeExactScopeSplitTest::test_draw_lose_half_life_spell_blocks_source_order_mismatch \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py::XMageExactScopeRuntimeTest::test_draw_lose_half_life_spell_rounds_up \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_manifest_expected_rule_preserves_draw_lose_half_life_fields \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py::test_manifest_builds_draw_lose_half_life_scenario \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py::test_draw_lose_half_life_runner_draws_and_rounds_up_life_loss
```

Result: `6 passed`.

Py compile:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py
```

Result: pass.

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_rollback.sql`

Precheck:

- `Cruel Bargain`: `target_card_rows=1`, `existing_rule_rows=0`, `would_deprecate_shadow_rows=0`
- `Infernal Contract`: `target_card_rows=1`, `existing_rule_rows=0`, `would_deprecate_shadow_rows=0`

Apply:

- `upserted_rows=2`
- `deprecated_shadow_rows=0`

Postcheck:

- `promoted_rule_rows=1` for each card
- `promoted_verified_auto_rows=1` for each card
- `promoted_oracle_hash_rows=1` for each card
- `backup_rows=0`

Direct PostgreSQL validation:

- `Cruel Bargain`: `verified`, `auto`, `rule_version=2`, scope `xmage_controller_draw_lose_half_life_rounded_up_spell_v1`, `life_loss_mode=half_rounded_up`, `draw_count=4`
- `Infernal Contract`: `verified`, `auto`, `rule_version=2`, scope `xmage_controller_draw_lose_half_life_rounded_up_spell_v1`, `life_loss_mode=half_rounded_up`, `draw_count=4`

## Hermes/SQLite Sync

Command:

```bash
./server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --report docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_sqlite_sync.json
```

Result:

- `database_target=127.0.0.1:15432/halder`
- `pg_rows_loaded=10086`
- `sqlite_inserted_or_updated=9864`
- `canonical_snapshot_rows_exported=7478`

## E2E

Command:

```bash
./server/bin/with_new_server_pg.sh python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py \
  --manifest docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_manifest.json \
  --output-json docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_e2e.json \
  --output-md docs/hermes-analysis/master_optimizer_reports/pg763_draw_lose_half_life_new_server_e2e.md
```

Result: `status=pass`.

Battle execution:

- `Cruel Bargain`: drew `4`, life `21 -> 10`, life lost `11`, mode `half_rounded_up`
- `Infernal Contract`: drew `4`, life `21 -> 10`, life lost `11`, mode `half_rounded_up`

## Readiness Delta

Global readiness after PG762 -> after PG763:

- `battle_and_oracle_ready`: `6489 -> 6491`
- `battle_family_mapper_required`: `27387 -> 27385`
- `snapshot_has_verified_rule`: `6514 -> 6516`
- `snapshot_has_any_rule`: `7682 -> 7684`

XMage authoritative queue after PG762 -> after PG763:

- `target_identity_count`: `24464 -> 24462`
- `xmage_authoritative_adapter_required_count`: `24151 -> 24149`
- `xmage_authoritative_parser_gap_count`: `0 -> 0`
- `xmage_missing_source_exception_count`: `313 -> 313`
- `draw_cards::xmage_draw_card_variant_review_v1`: `534 -> 532`

## Audits

- PostgreSQL/Hermes/SQLite contract audit: `pass`, `51/51`
- XMage strategy consistency audit: `pass`, `26/26`
- Operational surface alignment audit: `pass`
- Legacy contamination audit: `pass`
