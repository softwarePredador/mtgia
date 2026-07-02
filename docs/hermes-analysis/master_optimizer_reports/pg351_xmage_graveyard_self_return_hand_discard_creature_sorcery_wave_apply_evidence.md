# PG351 XMage Graveyard Self-Return Hand Discard/Sorcery Wave - Apply Evidence

- Generated UTC: `2026-07-02`
- Deploy ID: `PG351`
- Scope: exact `ReturnSourceFromGraveyardToHandEffect` graveyard activated
  self-return-to-hand rules with either a single creature-card discard cost or
  sorcery-speed activation.
- Cards promoted: `Kraul Swarm`, `Summoned Dromedary`
- Battle model scope:
  `xmage_graveyard_simple_activated_self_return_to_hand_v1`

## Source Package

- Split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_package.md`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_apply.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_rollback.sql`

## PostgreSQL Apply

The package was applied to PostgreSQL and the postcheck now proves both rows are
promoted as verified executable rules with matching Oracle hashes:

| Card | Promoted rows | Verified/auto rows | Oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Kraul Swarm` | 1 | 1 | 1 | 0 |
| `Summoned Dromedary` | 1 | 1 | 1 | 0 |

Current PostgreSQL row inspection confirms:

- `Kraul Swarm` carries `activation_discard_count=1`,
  `activation_discard_target=creature_card`, and
  `graveyard_self_return_activation_discard_target=creature_card`.
- `Summoned Dromedary` carries `activation_timing=sorcery` and
  `xmage_ability_class=ActivateAsSorceryActivatedAbility`.

## Hermes/SQLite Sync

- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_pg_to_sqlite_sync.json`
- PostgreSQL rows loaded: `7321`
- SQLite rows inserted/updated: `7115`
- Canonical snapshot rows exported: `4898`

The refreshed
`docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
contains both promoted PG351 rules and the new effect fields.

## E2E And Focused Tests

- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_e2e_validation.md`
- E2E status: `pass`
- Validated stages: PostgreSQL source of truth, SQLite Hermes cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution
  no-override.
- Focused splitter suite:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  reports `226` tests passing.
- Focused runtime suite:
  `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  reports `137` tests passing.

## Post-PG351 Queue Movement

- Readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_recheck.md`
- Authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_commander_legal.md`
- `battle_and_oracle_ready`: `2454`
- `battle_family_mapper_required`: `30093`
- `snapshot_has_verified_rule`: `3602`
- `target_identity_count`: `27170`
- `xmage_authoritative_source_count`: `26856`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26856`
- Top reusable work unit:
  `recursion::xmage_graveyard_return_variant_review_v1` at `1866`

## Supported Recheck And Audits

- Post-PG351 supported exact-scope recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg351_supported_recheck.md`
- Supported recheck result: `proposal_count=0` over `7927` considered
  supported rows.
- XMage strategy consistency audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
  reports `pass`.
- Operational surface alignment audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
  reports `pass`.
- Legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
  reports `pass`.
- PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
  reports `pass` with the inherited warning
  `trusted_executable_rules_missing_oracle_hash=16`; PG351 rows carry matching
  Oracle hashes.

## Continuation

Continue from the post-PG351 queue. The next exact runtime-backed batch should
be selected from the remaining largest reusable work units, starting with
`recursion::xmage_graveyard_return_variant_review_v1` unless a fresher queue
changes the ranking.
