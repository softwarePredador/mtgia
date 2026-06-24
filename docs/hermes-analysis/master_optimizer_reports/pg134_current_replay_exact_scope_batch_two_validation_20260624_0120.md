# PG134 Current Replay Exact Scope Batch Two Validation - 2026-06-24 01:20 UTC

## Scope

- Promote the next exact XMage-backed batch still present in the real
  `Lorehold + oponentes usados` replay surface:
  - `Archdruid's Charm`
  - `Sink into Stupor`
  - `Ruthless Technomancer`
  - `Emperor of Bones`
  - `Disciple of Freyalise`
  - `Vibrance`
- Deprecate the broader shadow rows those cards still resolved through.
- Sync the promoted rules into Hermes SQLite/cache.
- Validate the MDFC-sensitive runtime surface before the next residual pass.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_rollback.sql`

Precheck result:

- `Archdruid's Charm`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Disciple of Freyalise`: `target_card_rows=1`, `existing_rule_rows=1`,
  `would_deprecate_shadow_rows=1`
- `Emperor of Bones`: `existing_rule_rows=0`,
  `would_deprecate_shadow_rows=0`
- `Ruthless Technomancer`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Sink into Stupor`: `target_card_rows=1`, `existing_rule_rows=1`,
  `would_deprecate_shadow_rows=1`
- `Vibrance`: `existing_rule_rows=1`, `would_deprecate_shadow_rows=1`

Apply result:

- `deprecated_shadow_rows=7`
- `upserted_rows=6`

Postcheck result:

- all six cards have `promoted_rule_rows=1`
- all six cards have `promoted_verified_auto_rows=1`
- all six cards have `promoted_oracle_hash_rows=1`
- backup table retained `7` captured rows

Promoted scopes:

- `Archdruid's Charm` ->
  `search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1`
- `Sink into Stupor` ->
  `return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1`
- `Ruthless Technomancer` ->
  `etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1`
- `Emperor of Bones` ->
  `combat_exile_adapt_finality_reanimate_v1`
- `Disciple of Freyalise` ->
  `etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1`
- `Vibrance` ->
  `evoke_etb_red_damage_or_green_land_tutor_lifegain_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Archdruid's Charm" --only-card "Sink into Stupor" --only-card "Ruthless Technomancer" --only-card "Emperor of Bones" --only-card "Disciple of Freyalise" --only-card "Vibrance" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg134_current_replay_exact_scope_batch_two_20260624_0120.json
```

Sync result:

- `selected_card_count=6`
- `pg_rows_loaded=15`
- `sqlite_inserted_or_updated=12`
- `generated_rows=3`
- `oracle_normalized_rows=2`
- `canonical_snapshot_rows_exported=3211`

## Test Evidence

- `python3 -m py_compile ...xmage_to_manaloom_effect_hints.py ...xmage_semantic_family_classifier.py ...xmage_batch_pg_package_builder.py ...sync_battle_card_rules_pg.py ...deck_card_battle_rule_coherence_audit.py ...test_xmage_to_manaloom_effect_hints.py ...test_xmage_semantic_family_batch_pipeline.py ...test_sync_battle_card_rules_pg_selection.py ...test_deck_card_battle_rule_coherence_audit.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `110 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Seed pipeline before PG134 apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg134_seed_manifest.json`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":6,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":2}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg134_postsync_real_v3_manifest.json`
- the only residual local-XMage split-family cards after PG134 were:
  - `Agatha's Soul Cauldron`
  - `Necropotence`

## Current Reading

- PG134 closed the six-card exact-scope batch and reduced the real local-XMage
  residual to the two structurally special cards that still needed exact
  non-generic mapping.
- The MDFC alias fixes introduced during this pass were required so
  `Sink into Stupor` and `Disciple of Freyalise` would survive both PG sync and
  replay-coherence lookup through their front faces.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg134_current_replay_exact_scope_batch_two_rollback.sql`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  focused tests, and post-sync replay-batch validation all passed.
