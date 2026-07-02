# PG353 XMage Permanent Activated Graveyard-To-Hand Discard-Cost Wave - Apply Evidence

- Generated UTC: `2026-07-02`
- Deploy ID: `PG353`
- Scope: exact `ReturnFromGraveyardToHandTargetEffect` permanent activated
  abilities with `{B}` mana, optional tap, and one exact discard-card cost.
- Cards promoted: `Tortured Existence`, `Undertaker`
- Battle model scope:
  `xmage_permanent_simple_activated_graveyard_to_hand_v1`

## Source Package

- Split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_package.md`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_apply.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_rollback.sql`

## PostgreSQL Apply

Precheck found `2/2` target card rows, `0` existing expected rows, and `2`
shadow rows to deprecate.

Apply reported `2` upserted rows and `2` deprecated shadow rows.

Postcheck proves both rows are promoted as verified executable rules with
matching Oracle hashes:

| Card | Promoted rows | Verified/auto rows | Oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Tortured Existence` | 1 | 1 | 1 | 2 |
| `Undertaker` | 1 | 1 | 1 | 2 |

## Hermes/SQLite Sync

- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7327`
- SQLite rows inserted/updated: `7121`
- Canonical snapshot rows exported: `4903`

## E2E And Focused Tests

- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_e2e_validation.md`
- E2E status: `pass`
- Validated stages: PostgreSQL source of truth, SQLite Hermes cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution
  no-override.
- Focused splitter suite reports `230` tests passing.
- Focused runtime suite reports `140` tests passing.
- Package/E2E pytest checks report `6` tests passing.

## Runtime Behavior Added

- The splitter accepts exact activated graveyard-to-hand permanents with
  `DiscardCardCost()` or
  `DiscardCardCost(StaticFilters.FILTER_CARD_CREATURE_A)` only when source and
  Oracle agree.
- Runtime pays the discard cost before moving the target graveyard card to
  hand, records discard metadata, and skips the activation if no valid discard
  card is available.
- Generic review scopes remain blocked from executable PostgreSQL promotion.

## Post-PG353 Queue Movement

- Readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_recheck.md`
- Authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_commander_legal.md`
- `battle_and_oracle_ready`: `2460`
- `battle_family_mapper_required`: `30087`
- `snapshot_has_verified_rule`: `3608`
- `target_identity_count`: `27164`
- `xmage_authoritative_source_count`: `26850`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26850`
- Top reusable work unit:
  `recursion::xmage_graveyard_return_variant_review_v1` at `1860`

## Supported Recheck And Audits

- Post-PG353 supported exact-scope recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg353_supported_recheck.md`
- Supported recheck result: `proposal_count=0` over `7921` considered
  supported rows.
- XMage strategy consistency audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
  reports `pass`.
- Operational surface alignment audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
  reports `pass`.
- Legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
  reports `pass`.
- PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
  reports `pass` with the inherited warning
  `trusted_executable_rules_missing_oracle_hash=16`; PG353 rows carry matching
  Oracle hashes.

## Continuation

Continue from the post-PG353 queue. The next exact runtime-backed batch should
be selected from the remaining largest reusable work units, starting with
`recursion::xmage_graveyard_return_variant_review_v1` unless a fresher queue
changes the ranking.
