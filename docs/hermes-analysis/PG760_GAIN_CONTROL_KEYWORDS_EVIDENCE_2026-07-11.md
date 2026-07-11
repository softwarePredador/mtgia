# PG760 Gain Control Keywords Evidence - 2026-07-11

Status: `applied_synced_validated_committed`.

Database target: `127.0.0.1:15432/halder` through `server/bin/with_new_server_pg.sh`.

## Scope

Implemented the XMage exact-scope subpattern:

- `xmage_gain_control_untap_haste_until_eot_spell_v1`
- Effect: gain control of a target until end of turn, untap it, grant haste and any additional explicit end-of-turn target keywords.
- Neutral auxiliary abilities allowed for this resolution: examples in this batch are `CyclingAbility`, `DevoidAbility`, and `SplitSecondAbility`.
- Multi-resolution or variable-target abilities remain blocked; `Harness by Force` (`StriveAbility`) and `Spreading Insurrection` (`StormAbility`) were not promoted.

Promoted cards:

| Card | Target | Granted keywords | Auxiliary ability |
| --- | --- | --- | --- |
| Limits of Solidarity | creature | haste | CyclingAbility |
| Lose Calm | creature | menace, haste | none |
| Traitorous Blood | creature | trample, haste | none |
| Turn Against | creature | haste | DevoidAbility |
| Word of Seizing | permanent | haste | SplitSecondAbility |

## Code And Test Evidence

Runtime/parser changes:

- `battle_analyst_v9.py` now applies all `granted_keywords_until_eot` for the temporary-control spell and clears them at end of turn through existing until-EOT memory.
- `xmage_authoritative_exact_scope_split.py` now parses explicit target keywords from XMage `GainAbilityTargetEffect`, supports target `permanent`, accepts neutral resolution auxiliary abilities, and continues to block unsupported/multi-resolution abilities.
- `battle_package_end_to_end_validation.py` now verifies all expected granted keywords and cleanup, not only haste.
- `xmage_batch_pg_package_builder.py` already manifested `expected_granted_keywords`; PG760 adds coverage for extra-keyword and permanent-target scenarios.

Focused tests:

```text
python3 -m py_compile battle_analyst_v9.py xmage_authoritative_exact_scope_split.py xmage_batch_pg_package_builder.py battle_package_end_to_end_validation.py

python3 -m pytest -q [PG760 focused tests]
16 passed, 5 subtests passed
```

## Split And Package

Split report:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260711_pg760_gain_control_keywords_new_server.json`
- Safe package candidates: `5`
- Blocked as intended:
  - `Harness by Force`: `gain_control_untap_haste_ability_class_not_supported`
  - `Spreading Insurrection`: `gain_control_untap_haste_ability_class_not_supported`

Package:

- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg760_gain_control_keywords_new_server_manifest.json`
- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg760_gain_control_keywords_new_server_precheck.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg760_gain_control_keywords_new_server_apply.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg760_gain_control_keywords_new_server_postcheck.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pg760_gain_control_keywords_new_server_rollback.sql`

Precheck:

- `target_card_rows=1` for all 5 cards.
- `existing_rule_rows=0` for all 5 cards.
- `would_deprecate_shadow_rows=0`.

Apply/postcheck:

- `upserted_rows=5`
- `deprecated_shadow_rows=0`
- Postcheck showed `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1` for each promoted card.

Direct PostgreSQL verification:

```text
Limits of Solidarity  verified auto 2 creature  ["haste"]            ["CyclingAbility"]
Lose Calm             verified auto 2 creature  ["menace","haste"]   []
Traitorous Blood      verified auto 2 creature  ["trample","haste"]  []
Turn Against          verified auto 2 creature  ["haste"]            ["DevoidAbility"]
Word of Seizing       verified auto 2 permanent ["haste"]            ["SplitSecondAbility"]
```

## PG760B Hash Backfill

During post-PG760 readiness, old trusted executable curated/manual rows without `oracle_hash` reappeared as a readiness lane. PG760B restored hashes from current `cards.oracle_text`; it did not change card behavior.

Files:

- `docs/hermes-analysis/master_optimizer_reports/pg760b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg760b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg760b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg760b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`

Evidence:

- Precheck: `trusted_executable_rules_missing_oracle_hash=55`, `safe_backfill_rows=55`, no missing card id, no unmatched card id, no empty Oracle text.
- Apply: `backfilled_rows=55`.
- Postcheck: `trusted_executable_rules_missing_oracle_hash=0`, `backup_rows=55`, `updated_rows_with_current_oracle_hash=55`.

## Sync And E2E

Sync after PG760B:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg760b_trusted_rule_oracle_hash_backfill_new_server_sqlite_sync.json`
- `pg_rows_loaded=10080`
- `sqlite_inserted_or_updated=9858`
- `canonical_snapshot_rows_exported=7472`

Package E2E after PG760B:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg760_gain_control_keywords_new_server_e2e_after_pg760b_hash_backfill.json`
- Status: `pass`
- PostgreSQL rows validated: `5`
- SQLite rows validated: `5`
- Snapshot cards validated: `5`
- Runtime lookup cards validated: `5`
- Battle execution scenarios: `5`
- Battle execution events: `15`

## Global Delta

Readiness reports compared:

- Before: `global_card_oracle_battle_readiness_20260711_post_pg759_damage_optional_discard_draw_new_server.json`
- After: `global_card_oracle_battle_readiness_20260711_post_pg760b_hash_backfill_new_server.json`

Delta:

- `battle_and_oracle_ready`: `6480 -> 6485`
- `battle_family_mapper_required`: `27396 -> 27391`
- `snapshot_has_verified_rule`: `6505 -> 6510`
- `snapshot_has_any_rule`: `7673 -> 7678`
- `trusted_rule_oracle_hash_backfill`: `0 -> 0`

XMage queue reports compared:

- Before: `xmage_authoritative_adaptation_queue_20260711_post_pg759_damage_optional_discard_draw_new_server.json`
- After: `xmage_authoritative_adaptation_queue_20260711_post_pg760b_hash_backfill_new_server.json`

Delta:

- `target_identity_count`: `24473 -> 24468`
- `xmage_authoritative_adapter_required_count`: `24160 -> 24155`
- `xmage_authoritative_parser_gap_count`: `0 -> 0`
- `xmage_missing_source_exception_count`: `313 -> 313`
- `untap_target::xmage_targeted_untap_variant_review_v1`: `207 -> 202`

## Audits

Final audits:

- `pg_hermes_sqlite_contract_audit_20260711_post_pg760b_gain_control_hash_backfill_new_server`: `pass`, `51/51`.
- `xmage_strategy_consistency_audit_20260711_post_pg760b_gain_control_hash_backfill_new_server`: `pass`, `26/26`.
- `operational_surface_alignment_audit_20260711_post_pg760b_gain_control_hash_backfill_new_server`: `pass`.
- `legacy_contamination_audit_20260711_post_pg760b_gain_control_hash_backfill_new_server`: `pass`.

## Next Work

The next split still shows no immediate safe mana-source package because the remaining proposals are `runtime_partial_requires_family_runtime`:

- `xmage_simple_mana_source_with_unmodeled_auxiliary`: `7`
- `xmage_restricted_spell_category_mana_source`: `1`

The next productive continuation should choose a high-volume family from the updated queue rather than promoting mana-only partial rules.
