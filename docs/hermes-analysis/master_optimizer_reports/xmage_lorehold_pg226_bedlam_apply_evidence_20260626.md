# Lorehold PG226 Bedlam Reveler Apply Evidence

- Date: `2026-06-26`
- Scope: promote the exact XMage -> ManaLoom Bedlam Reveler rule, sync Hermes SQLite, rerun Lorehold routing, and confirm whether the generated deck changes.
- PostgreSQL writes: `yes`
- Deck mutations: `no`

## Implemented local changes

- Added exact XMage structural mapping for `Bedlam Reveler` in `xmage_to_manaloom_effect_hints.py`.
- Added graveyard-count self cost-reduction support and ETB discard-then-draw persistence in `battle_analyst_v9.py`.
- Added/connected focused regression coverage for:
  - `test_runtime_cast_plan_supports_self_graveyard_count_cost_reduction_creature`
  - `test_pg226_bedlam_reveler_etb_discards_hand_and_draws_three`

## Local validation

Commands run:

```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts
python3 -m unittest test_xmage_to_manaloom_effect_hints.py test_xmage_semantic_family_batch_pipeline.py
python3 - <<'PY'
import test_battle_analyst_v10_3 as t
selected = [fn for fn in t.battle_card_specific_tests.register_tests(t.battle, t.player) if fn.__name__ in {
    'test_runtime_cast_plan_supports_self_graveyard_count_cost_reduction_creature',
    'test_pg226_bedlam_reveler_etb_discards_hand_and_draws_three',
}]
for fn in selected:
    if hasattr(t.battle, 'clear_pending_triggers'):
        t.battle.clear_pending_triggers()
    fn()
    print(f'PASS {fn.__name__}')
PY
```

Results:

- `424 tests` passed for hint/classifier coverage.
- both Bedlam-focused runtime tests passed.

## Presync Lorehold routing

Presync proposal report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg226_bedlam_loreholdscope_presync_v2_proposals.json`

Presync matrix:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg226_bedlam_loreholdscope_presync_v3.json`

Presync Bedlam status:

- `proposal_status=batch_pg_candidate_after_precheck`
- `promotion_lane=batch_metadata_candidate_requires_pg_precheck`
- `family_id=creature`
- `battle_model_scope=front_creature_prowess_etb_discard_hand_draw_three_self_instant_sorcery_graveyard_cost_reduction_v1`
- matrix status before PG sync: `rule_status=package_ready`, `recommendation_lane=low_priority`

## PostgreSQL package

Generated package files:

- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_package.md`

## Precheck

Output file:

- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_precheck.out`

Observed result:

- `target_card_rows=1`
- `existing_rule_rows=0`
- `expected_rule_rows_before=0`
- `would_deprecate_shadow_rows=0`

Direct PG card/hash verification:

```text
Bedlam Reveler|25edf0dbac766bdc2506f4b317a1897a
```

## Apply

Output file:

- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_apply.out`

Observed result:

- `deprecated_shadow_rows=0`
- `upserted_rows=1`

## Postcheck

Output file:

- `docs/hermes-analysis/master_optimizer_reports/pg226_bedlam_reveler_exact_scope_postcheck.out`

Observed result:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- `backup_rows=0`

Direct PG rule verification:

```text
Bedlam Reveler|curated|verified|auto|2|front_creature_prowess_etb_discard_hand_draw_three_self_instant_sorcery_graveyard_cost_reduction_v1
```

## Hermes / SQLite sync

Command used:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --only-card "Bedlam Reveler" \
  --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg226_bedlam_reveler_exact_scope_20260626.json
```

Sync report:

- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg226_bedlam_reveler_exact_scope_20260626.json`

Observed result:

- `pg_rows_loaded=1`
- `sqlite_inserted_or_updated=1`
- `selected_card_count=1`

## Postsync Lorehold routing

Postsync proposal report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg226_bedlam_loreholdscope_postsync_v1_proposals.json`

Postsync matrix:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg226_bedlam_loreholdscope_postsync_v1.json`

Postsync summary deltas:

- rule statuses moved from `battle_ready=312, package_ready=1, split_scope=10` to `battle_ready=313, split_scope=10`
- Bedlam moved to:
  - `rule_status=battle_ready`
  - `recommendation_lane=watchlist_candidate`
  - `next_action=run_safe_slot_benchmark_after_baseline_hash_guard`

This confirms the Bedlam rule left `needs_rule_before_strategy`.

## Generated deck impact

Postsync candidate:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg226_bedlam_postsync_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg226_bedlam_postsync_v1.md`

Hash comparison:

- previous stable hash: `a2a5793c8c7586bcf2b99860f54afeb0200a93ad127b0b71239fc3ff048d6579`
- postsync hash: `a2a5793c8c7586bcf2b99860f54afeb0200a93ad127b0b71239fc3ff048d6579`
- result: `unchanged`

Conclusion:

- PG226 successfully promoted `Bedlam Reveler` into PostgreSQL and Hermes SQLite.
- Lorehold routing now treats Bedlam as `battle_ready`.
- This promotion did **not** materially change the generated Lorehold candidate deck hash.
- The next high-return Lorehold split-scope targets remain:
  - `Primal Amulet // Primal Wellspring`
  - `Blood Sun`
  - `Palantír of Orthanc`
  - `Razorgrass Ambush // Razorgrass Field`
