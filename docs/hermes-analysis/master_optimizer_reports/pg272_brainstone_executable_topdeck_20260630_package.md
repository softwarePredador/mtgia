# PG272 Brainstone Executable Topdeck Package

Status: `applied_synced`.

This package promotes Brainstone from the stale `unexecuted` scope label to the
exact executable ManaLoom scope already covered by the Lorehold focused runtime
test.

- Generated at: `2026-06-30T09:30:35Z`
- Selected cards: `["Brainstone"]`
- Family: `topdeck_manipulation`
- Local XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/b/Brainstone.java`
- Focused runtime proof:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py::test_brainstone_first_draw_approach_wins_before_rummage_resolution`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_manifest.json`

Expected promoted rule:

- card: `Brainstone`
- oracle_hash: `3c13a2b77d527812c94eae8a9c6f9615`
- logical_rule_key: `battle_rule_v1:6aab083c9a25b2af50c2069683da5131`
- battle_model_scope:
  `brainstone_draw_three_put_two_back_for_first_draw_miracle_v1`
- effect: `topdeck_manipulation`
- review/execution: `verified/auto`

Apply result:

- precheck: `target_card_rows=1`, `active_unexecuted_rows_before=1`,
  `expected_rule_rows_before=0`
- apply: `backup_rows=3`, `deprecated_shadow_rows=3`, `upserted_rows=1`
- postcheck: `promoted_verified_auto_rows=1`,
  `promoted_expected_scope_rows=1`, `active_unexecuted_rows_after=0`
- sync: `pg_rows_loaded=4`, `sqlite_inserted_or_updated=3`,
  `canonical_snapshot_rows_exported=3284`

Post-apply validation route:

- run focused Brainstone runtime test;
- rebuild access-cut model and focus-access package generator;
- rerun XMage, deckbuilding, and operational surface audits.
