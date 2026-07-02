# PG352 XMage Graveyard Shuffle-To-Library Spell Wave - Apply Evidence

- Generated UTC: `2026-07-02`
- Deploy ID: `PG352`
- Scope: exact `TargetPlayerShufflesTargetCardsEffect` instant/sorcery rules
  that shuffle up to N target cards from the target player's graveyard into
  that player's library.
- Cards promoted: `Dwell on the Past`, `Krosan Reclamation`,
  `Memory's Journey`, `Stream of Consciousness`
- Battle model scope:
  `xmage_put_target_graveyard_card_on_library_spell_v1`

## Source Package

- Split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg352_graveyard_shuffle_to_library_spell_wave.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_package.md`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_apply.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_rollback.sql`

## PostgreSQL Apply

Precheck found `4/4` target card rows, `0` existing expected rows, and `0`
shadow rows to deprecate.

Apply reported `4` upserted rows and `0` deprecated shadow rows.

Postcheck proves all four rows are promoted as verified executable rules with
matching Oracle hashes:

| Card | Promoted rows | Verified/auto rows | Oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Dwell on the Past` | 1 | 1 | 1 | 0 |
| `Krosan Reclamation` | 1 | 1 | 1 | 0 |
| `Memory's Journey` | 1 | 1 | 1 | 0 |
| `Stream of Consciousness` | 1 | 1 | 1 | 0 |

## Hermes/SQLite Sync

- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7325`
- SQLite rows inserted/updated: `7119`
- Canonical snapshot rows exported: `4902`

## E2E And Focused Tests

- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_e2e_validation.md`
- E2E status: `pass`
- Validated stages: PostgreSQL source of truth, SQLite Hermes cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution
  no-override.
- Focused splitter suite reports `229` tests passing.
- Focused runtime suite reports `138` tests passing.

## Post-PG352 Queue Movement

- Readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_recheck.md`
- Authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_commander_legal.md`
- `battle_and_oracle_ready`: `2458`
- `battle_family_mapper_required`: `30089`
- `snapshot_has_verified_rule`: `3606`
- `target_identity_count`: `27166`
- `xmage_authoritative_source_count`: `26852`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26852`
- Top reusable work unit:
  `recursion::xmage_graveyard_return_variant_review_v1` at `1862`

## Supported Recheck And Audits

- Post-PG352 supported exact-scope recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg352_supported_recheck.md`
- Supported recheck result: `proposal_count=0` over `7923` considered
  supported rows.
- XMage strategy consistency audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
  reports `pass`.
- Operational surface alignment audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
  reports `pass`.
- Legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
  reports `pass`.
- PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
  reports `pass` with the inherited warning
  `trusted_executable_rules_missing_oracle_hash=16`; PG352 rows carry matching
  Oracle hashes.

## Continuation

Continue from the post-PG352 queue. The next exact runtime-backed batch should
be selected from the remaining largest reusable work units, starting with
`recursion::xmage_graveyard_return_variant_review_v1` unless a fresher queue
changes the ranking.
