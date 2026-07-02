# PG374 Bounce Draw Spell Wave Apply Evidence

Generated: `2026-07-02`

## Scope

PG374 promoted the exact XMage-derived
`ReturnToHandTargetEffect + DrawCardSourceControllerEffect` subpattern into
the executable ManaLoom scope
`xmage_return_target_to_hand_and_draw_card_spell_v1`.

Promoted cards:

- `Drag Under`
- `Galestrike`
- `Leave in the Dust`
- `Repulse`
- `Symbol of Unsummoning`

Blocked neighbors:

- `Read the Tides`: modal/up-to behavior.
- `Repeal`: X/target-adjusted behavior.

## Runtime And Splitter

- Updated `xmage_authoritative_exact_scope_split.py` with
  `BOUNCE_DRAW_SCOPE`, exact Oracle/source parsing, tapped-creature support,
  and blocker reasons for dynamic/modal/X cases.
- Updated `battle_analyst_v9.py` so composite removal components route through
  `move_removed_permanent_to_destination`; `destination=hand` now uses the
  same tested bounce path as non-composite removal.
- Focused tests:

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py
```

Result: `Ran 458 tests in 7.093s - OK`.

## Splitter Evidence

Command:

```bash
PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  --queue docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg373_destroy_draw_spell_wave_commander_legal.json \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg374_bounce_draw_spell_wave
```

Result:

- `proposal_count=5`
- `safe_for_batch_pg_package_count=5`
- `family_counts={"xmage_bounce_draw_card_spell": 5}`
- `scope_counts={"xmage_return_target_to_hand_and_draw_card_spell_v1": 5}`

## PostgreSQL Package

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_package.md`

Apply result:

- precheck: `5` Oracle-hash-matched target rows, `0` existing expected rows,
  `0` stale shadow rows to deprecate.
- apply: `deprecated_shadow_rows=0`, `upserted_rows=5`, `COMMIT`.
- postcheck: all `5/5` promoted rows are present, `verified`, `auto`, and
  Oracle-hash matched.

Output evidence:

- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_precheck.out`
- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_apply.out`
- `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_postcheck.out`

## Sync And E2E

PG -> Hermes/SQLite sync:

- `canonical_snapshot_rows_exported=5017`
- `pg_rows_loaded=7446`
- `sqlite_inserted_or_updated=7241`
- report:
  `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_pg_to_sqlite_sync.json`

PG metadata sync:

- `postgres cards matched=6025`
- `sqlite cache alias rows=5952`
- `deck_cards backfill matched=2699/2699`
- report:
  `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_pg_metadata_sync.json`

E2E validation:

- status: `pass`
- PostgreSQL source of truth: `5/5`
- SQLite/Hermes cache: `5/5`
- canonical snapshot fallback: `5/5`
- runtime `get_card_effect`: `5/5`
- report:
  `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_e2e_validation.md`

## Post-PG374 Queue

Fresh queue:

- `target_identity_count=27045`
- `xmage_authoritative_source_count=26731`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26731`
- `draw_cards::xmage_draw_card_variant_review_v1=654`

Delta from post-PG373:

- `target_identity_count`: `27050 -> 27045`
- `xmage_authoritative_adapter_required_count`: `26736 -> 26731`
- `draw_cards::xmage_draw_card_variant_review_v1`: `659 -> 654`

Post-PG374 supported splitter recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`
- `considered_supported_work_unit_rows=7802`
- report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg374_supported_recheck.md`

## Final Audits

- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg374_bounce_draw_spell_wave_final.md`
  passed with `49/49`.
- XMage strategy:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg374_bounce_draw_spell_wave_docs_after_update.md`
  passed with `26/26`.
- Operational surface:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg374_bounce_draw_spell_wave_docs_after_update.md`
  passed.
- Legacy contamination:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg374_bounce_draw_spell_wave_docs_after_update.md`
  passed.

## Next Cycle

Start PG375 from:

`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg374_bounce_draw_spell_wave_commander_legal.json`

The current exact splitter has no remaining package-safe proposal, so PG375
must add another exact mapper/runtime subpattern before package generation.
