# PG343 XMage Recursion Mill-Return Wave Apply Evidence

Status: `applied_synced_e2e_validated`.

## Scope

Promoted exact `MillCardsControllerEffect + ReturnCardChosenFromGraveyardEffect`
XMage signatures into ManaLoom runtime-backed rules:

- `Acolyte of Affliction`
- `Corpse Churn`
- `Eccentric Farmer`
- `Grapple with the Past`
- `Pothole Mole`

## Splitter

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg343_recursion_mill_return_wave.md`
- Proposal count: `5`
- Scope counts:
  - `xmage_mill_then_return_graveyard_card_to_hand_spell_v1`: `2`
  - `xmage_creature_etb_mill_then_return_graveyard_card_to_hand_v1`: `3`

## PostgreSQL

Target: `143.198.230.247:5433/halder`.

Precheck:

- `5/5` target card rows found.
- `0/5` expected rules already present.
- `2` nonmatching shadow rows scheduled for deprecation, both on
  `Grapple with the Past`.

Apply:

- Inserted/updated rows: `5`
- Deprecated shadow rows: `2`

Postcheck:

- `5/5` promoted rows present.
- `5/5` promoted rows are `verified/auto`.
- `5/5` promoted rows carry matching Oracle hashes.

## Sync And E2E

PG -> Hermes/SQLite sync:

- PostgreSQL rows loaded: `7288`
- SQLite inserted/updated: `7082`
- Canonical snapshot rows exported: `4865`
- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_pg_to_sqlite_sync.json`

E2E package validation:

- PostgreSQL source of truth: `5/5` pass.
- SQLite Hermes cache: `5/5` pass.
- Canonical snapshot fallback: `5/5` pass.
- Runtime `get_card_effect`: `5/5` pass.
- Battle execution no-override: pass.
- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_e2e_validation.md`

## Tests And Audits

Focused tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py`
  passed `325` tests.
- `python3 -m pytest -q test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py`
  passed `6` tests.

Alignment audits:

- XMage strategy consistency: `26/26` pass.
- PG/Hermes/SQLite contract: `48` pass, `1` warn for pre-existing
  `trusted_executable_rules_missing_oracle_hash=1418`.
- Operational surface alignment: pass.
- Legacy contamination: pass.

## Queue Reduction

Post-PG343 readiness:

- `battle_and_oracle_ready`: `2421`
- `battle_family_mapper_required`: `30126`
- `snapshot_has_verified_rule`: `3569`

Post-PG343 authoritative queue:

- `target_identity_count`: `27203`
- `xmage_authoritative_source_count`: `26889`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_authoritative_adapter_required_count`: `26889`
- Top work unit remains
  `recursion::xmage_graveyard_return_variant_review_v1` at `1899`.

Supported splitter recheck:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg343_supported_recheck.md`
- `proposal_count=0`
- `considered_supported_work_unit_rows=7928`
