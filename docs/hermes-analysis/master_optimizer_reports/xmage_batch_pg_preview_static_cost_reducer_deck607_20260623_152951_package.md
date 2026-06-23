# PREVIEW_STATIC_COST XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

Preview note:

- This is a batch-builder proof artifact, not a replacement deploy request.
- It intentionally selects `Pearl Medallion` and `The Scarlet Witch` together
  to prove family batching, but those cards already have individual pending
  packages PG108 and PG110. Do not apply this preview package unless the
  operator explicitly abandons/replaces the individual packages and approves
  the exact command.

- Generated at: `2026-06-23T18:29:57+00:00`
- Selected cards: `["Pearl Medallion", "The Scarlet Witch"]`
- Families: `{"static_cost_reducer": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_batch_pg_preview_static_cost_reducer_deck607_20260623_152951_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_batch_pg_preview_static_cost_reducer_deck607_20260623_152951_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_batch_pg_preview_static_cost_reducer_deck607_20260623_152951_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_batch_pg_preview_static_cost_reducer_deck607_20260623_152951_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_batch_pg_preview_static_cost_reducer_deck607_20260623_152951_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_batch_pg_preview_static_cost_reducer_deck607_20260623_152951_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
