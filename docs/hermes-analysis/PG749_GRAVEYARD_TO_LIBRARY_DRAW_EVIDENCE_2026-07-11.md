# PG749 Graveyard To Library Then Draw Evidence - 2026-07-11

Status: `applied_synced_validated`

Database target: `127.0.0.1:15432/halder` via
`server/bin/with_new_server_pg.sh`.

## Scope

PG749 promotes the exact XMage/ManaLoom scope
`xmage_put_graveyard_cards_on_library_then_draw_spell_v1`.

Cards promoted:

- `Footbottom Feast`
- `Forever Young`
- `Frantic Salvage`
- `Gravepurge`

XMage source pattern:

- `PutOnLibraryTargetEffect(true)`
- `TargetCardInYourGraveyard(0, Integer.MAX_VALUE, ...)`
- `DrawCardSourceControllerEffect(1)`

ManaLoom runtime behavior:

- move any number of matching cards from controller graveyard to top of library;
- order selected cards so the highest-value recovered card is drawn by the
  follow-up draw;
- draw 1 card after the graveyard-to-library movement;
- emit `recursion_resolved` and `recursion_followup_draw_resolved`.

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - added exact split scope for graveyard-to-library then draw;
  - supports any-number creature and artifact targets;
  - blocks non-exact source/oracle mismatches.
- `battle_analyst_v9.py`
  - executes prioritized top-library ordering for this scope;
  - executes the follow-up draw and draw triggers.
- `xmage_batch_pg_package_builder.py`
  - carries required runtime fields into package manifests;
  - emits focused E2E scenarios for this scope.
- `battle_package_end_to_end_validation.py`
  - validates real runtime lookup and battle execution for the new scenario.

## PostgreSQL Evidence

Postcheck:

| Card | Promoted rows | Verified auto rows | Oracle hash rows | Backup rows |
| --- | ---: | ---: | ---: | ---: |
| `Footbottom Feast` | 1 | 1 | 1 | 0 |
| `Forever Young` | 1 | 1 | 1 | 0 |
| `Frantic Salvage` | 1 | 1 | 1 | 0 |
| `Gravepurge` | 1 | 1 | 1 | 0 |

Package artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg749_graveyard_to_library_draw_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg749_graveyard_to_library_draw_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg749_graveyard_to_library_draw_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg749_graveyard_to_library_draw_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg749_graveyard_to_library_draw_package_rollback.sql`

## Sync Evidence

PostgreSQL -> Hermes/SQLite:

- `pg_rows_loaded`: `6376`
- `sqlite_inserted_or_updated`: `6371`
- `canonical_snapshot_rows_exported`: `6325`

Metadata sync:

- `requested_unique_names`: `7280`
- `postgres_cards_matched`: `7463`
- `sqlite_cache_alias_rows`: `7385`
- `deck_cards_backfill.card_id_rows_updated`: `99`
- `unresolved_count`: `1`

## Runtime And E2E Evidence

Focused tests:

- `1483` unittest cases passed for exact split/runtime coverage.
- `295` pytest cases passed for package builder and E2E validator coverage.
- `py_compile` passed for all touched Python modules/tests.

E2E report:

- `status`: `pass`
- `scenario_count`: `4`
- `event_count`: `12`
- every promoted card recovered two matching graveyard cards, drew the intended
  high-value card, and left the lower-value recovered card on top of library.

E2E artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg749_graveyard_to_library_draw_new_server_e2e_validation.json`
- `docs/hermes-analysis/master_optimizer_reports/pg749_graveyard_to_library_draw_new_server_e2e_validation.md`

## Readiness Delta

Current all-card readiness after PG749:

- `all_known_cards`: `34331`
- `snapshot_has_verified_rule`: `6450`
- `battle_and_oracle_ready`: `6425`
- `battle_family_mapper_required`: `27451`

Compared with the previous PG747/hash readiness:

- `snapshot_has_verified_rule`: `6446 -> 6450`
- `battle_and_oracle_ready`: `6421 -> 6425`
- `battle_family_mapper_required`: `27455 -> 27451`

## Queue After PG749

Commander-legal adaptation queue after PG749:

- `target_identity_count`: `24528`
- `xmage_authoritative_source_count`: `24215`
- `xmage_authoritative_adapter_required_count`: `24215`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`
- `adapter_work_unit_count`: `11292`

Largest remaining work units:

- `recursion::xmage_graveyard_return_variant_review_v1`: `1792`
- `draw_engine::xmage_draw_card_variant_review_v1`: `1553`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`: `1064`
- `add_counters::source_add_counters_variant_v1`: `768`
- `direct_damage::targeted_damage_variant_v1`: `750`

## Alignment Gates

- `xmage_strategy_consistency_audit`: `pass` (`26/26`)
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `pg_hermes_sqlite_contract_audit`: `pass` (`51/51`)
- `quality_gate.sh server-target`: `pass`

## Next Work

Continue the global goal by selecting the next exact safe subpattern from the
post-PG749 queue. The highest-volume lanes are broad review scopes, so the next
package must be chosen by exact XMage class/effect signature rather than by
promoting the generic `xmage_*_review_v1` scope.
