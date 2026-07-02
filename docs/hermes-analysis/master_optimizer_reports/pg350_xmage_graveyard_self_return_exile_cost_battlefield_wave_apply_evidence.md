# PG350 XMage Graveyard Self-Return Exile-Cost Battlefield Wave Apply Evidence

Generated at: `2026-07-02T04:10:00Z`

## Scope

- Deploy id: `PG350`
- Slug: `xmage_graveyard_self_return_exile_cost_battlefield_wave`
- Cards: `Bone Dragon`, `Despoiler of Souls`, `Scrapheap Scrounger`
- Battle model scope: `xmage_graveyard_simple_activated_self_return_to_battlefield_v1`

## PostgreSQL Precheck

- Target card rows found: `3/3`
- Expected rule rows already present before apply: `0`
- Shadow rows scheduled for deprecation: `0`
- Logical rule keys:
  - `Bone Dragon`: `battle_rule_v1:ed192d13af826e2cba9fc1a0193966b9`
  - `Despoiler of Souls`: `battle_rule_v1:cb987efceb3f6cb411733e0382b5415d`
  - `Scrapheap Scrounger`: `battle_rule_v1:b2bcbf2dbafe43780992bc75976967fe`

## PostgreSQL Apply

- Transaction: `COMMIT`
- Deprecated shadow rows: `0`
- Upserted rows: `3`

## PostgreSQL Postcheck

- Promoted rule rows: `3/3`
- Promoted `verified/auto` rows: `3/3`
- Promoted Oracle-hash rows: `3/3`
- Backup rows: `0`

## PG To Hermes/SQLite Sync

- PostgreSQL rows loaded: `7319`
- SQLite inserted or updated: `7113`
- Canonical snapshot rows exported: `4896`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_pg_to_sqlite_sync.json`

## Validation

- Splitter focused suite: `223` tests passing.
- Runtime focused suite: `135` tests passing.
- Package builder focused command: exit `0`.
- E2E package validation: `pass`.
- XMage strategy consistency audit: `26/26` pass.
- Operational surface alignment audit: `pass`.
- PG/Hermes/SQLite contract audit: `pass` with `48` pass and `1` inherited warning for `trusted_executable_rules_missing_oracle_hash=16`.
- Legacy contamination audit: `pass`.

## Queue Movement

- Readiness `battle_and_oracle_ready`: `2449 -> 2452`
- Readiness `battle_family_mapper_required`: `30098 -> 30095`
- Readiness `snapshot_has_verified_rule`: `3597 -> 3600`
- Authoritative queue `target_identity_count`: `27175 -> 27172`
- Authoritative queue `xmage_authoritative_source_count`: `26861 -> 26858`
- Authoritative queue `xmage_authoritative_adapter_required_count`: `26861 -> 26858`
- `recursion::xmage_graveyard_return_variant_review_v1`: `1871 -> 1868`

The post-PG350 supported splitter recheck returned `proposal_count=0` over
`7929` considered supported rows, so this exact subpattern is exhausted.
