# PG057 Deck 6 L3A Artifact Mana-Rock Package

Generated: 2026-06-23 01:40 UTC.

Logical deploy id: `PG057`.

Numbering note: the physical SQL/sync/event artifacts and PG backup table keep
the `pg055_deck6_l3a_artifact_mana_rocks...` prefix because this package was
generated and applied before the parallel `PG055 Lorehold Variant 03` register
entry and separate `PG056` deck 608 package artifacts appeared in the worktree.

## Scope

Deck `6` official Lorehold artifact mana rocks using the shared
`ramp_permanent` mana-source executor:

- `Arcane Signet`
- `Boros Signet`
- `Fellwar Stone`
- `Mana Vault`
- `Mox Amber`
- `Sol Ring`
- `Talisman of Conviction`

Excluded from this package:

- `Lotus Petal`: sacrifice one-shot mana artifact, not the same reusable
  permanent mana-source model.
- `Ruby Medallion`: cost reduction, not a mana-source executor.
- Rituals, treasure engines, and cost engines.

## Intended Change

- Add PostgreSQL oracle hashes to the trusted runtime rule for each target.
- Add or preserve `battle_model_scope`, `produces`, and `mana_produced`.
- Mark non-executed oracle clauses as annotation/abstraction where applicable:
  Boros Signet activation cost, Mana Vault untap/damage clauses, Talisman life
  loss, Fellwar Stone opponent-color dependency, Mox Amber color choice.
- Disable generated `needs_review` / `review_only` shadows.
- Disable older curated generic shadows only where a more specific trusted
  runtime rule exists for that card.

## Files

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3a_artifact_mana_rocks_pg055_precheck_20260623_014032.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3a_artifact_mana_rocks_pg055_apply_20260623_014032.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3a_artifact_mana_rocks_pg055_postcheck_20260623_014032.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l3a_artifact_mana_rocks_pg055_rollback_20260623_014032.sql`

## Expected Precheck

- `deck_target_cards=7`
- `target_rule_rows=18`
- `target_runtime_rows=7`
- `generated_review_only_rows=7`
- `curated_shadow_rows_to_disable=4`
- `trusted_missing_hash_rows=11`
- `trusted_without_scope_rows=7`
- `target_runtime_rows_without_produces=3`
- `active_card_id_mismatch_same_oracle_rows=2`
- `active_card_id_mismatch_unknown_or_mismatch_oracle_rows=0`
- `target_names_missing_rules=0`

## Rollback

Rollback deletes current rows for the seven target names and restores the
pre-PG055 snapshot from
`manaloom_deploy_audit.pg055_deck6_l3a_artifact_mana_rocks_20260623_014032`.
