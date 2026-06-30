# Solo Mapper Reconciled Cut/Lane Benchmark Decision - 2026-06-30

## Decision

- Status: `benchmark_blocked_no_gate_ready_pair`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Reason: the mapper is reconciled and the rule-first queue is classified, but the current cut/lane models found no add/cut pair that is safe enough for a deck battle benchmark with card drawn/cast/used evidence.

## Mapper reconciliation

- Manual reconciliation was applied only to the safe mapper deltas, not the raw Agent 2 branch.
- Generic `xmage_*_review_v1` scopes are now always kept in `split_family_scope_review_required`; stale batch lanes are downgraded by the batch proposal generator.
- `Deathbellow War Cry` now has an exact XMage-derived mapper scope: `up_to_four_different_name_minotaur_creatures_to_battlefield_v1`.
- `Deathbellow War Cry` still requires Oracle hash/precheck before any PostgreSQL package.

## Five rule-first cards

| Card | Decision | Current lane |
| --- | --- | --- |
| `Deathbellow War Cry` | closed at mapper level; waiting Oracle hash/precheck | `batch_metadata_candidate_requires_pg_precheck` |
| `Charmbreaker Devils` | deferred; needs focused random upkeep recursion plus pump runtime model | `split_family_scope_review_required` |
| `Naktamun Lorespinner // Wheel of Fortune` | deferred; needs prepare/MDFC/wheel runtime split | `split_family_scope_review_required` |
| `Karn's Sylex` | deferred; needs ETB tapped, pay-life/sacrifice restriction, and X wipe model | `split_family_scope_review_required` |
| `Karn, the Great Creator` | deferred; needs artifact lock, animation, and wish/exile access model | `split_family_scope_review_required` |

## Cut/lane model results

| Model | Evaluated pairs | Gate-ready pairs | Recommended action |
| --- | ---: | ---: | --- |
| `solo_mapper_reconciled_20260630_access_cut_model` | 470 | 0 | `no_access_swap_ready; build_new_seed_safe_cut` |
| `solo_mapper_reconciled_20260630_hand_filter_cut_model` | 445 expanded | 0 | `do_not_gate_hand_filter_without_new_cut_or_runtime_evidence` |
| `solo_mapper_reconciled_20260630_tutor_cut_model` | 188 | 0 | `do_not_gate_direct_tutor_swap; benchmark same-access cuts or build additive package` |
| `solo_mapper_reconciled_20260630_recursion_cut_model` | 10 | 0 | `do_not_gate_recursion_without_non_squee_cut_or_multi_card_package` |
| `solo_mapper_reconciled_20260630_safe_cut_replanner` | 188 followups | 0 manifest-ready | no safe manifest package |

## Runner check

- `solo_mapper_reconciled_20260630_registry_runner_dryrun` returned `result_count=0`.
- No battle benchmark was executed because there was no current package with a gate-ready add/cut pairing.
- The next battle benchmark must start only after a generated package can force or observe the candidate card being drawn, cast, activated, triggered, or otherwise used.

## Validation

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py test_xmage_semantic_family_batch_pipeline.py test_xmage_batch_validity_audit.py test_xmage_batch_pg_package_builder.py`: `531 tests OK`
- `python3 -m unittest test_lorehold_ideal_deck_candidate_matrix.py test_lorehold_607_research_candidate.py test_lorehold_variant_battle_gate.py test_lorehold_focus_access_package_generator.py test_lorehold_registry_candidate_runner.py test_operational_surface_alignment_audit.py`: `52 tests OK`
- `python3 test_artifact_topdeck_runtime.py`: `PASS`
- `python3 test_session_agent3_finisher_draw_recursion_runtime.py`: `PASS`
- `python3 xmage_strategy_consistency_audit.py --output-prefix /tmp/solo_mapper_reconciled_xmage_strategy`: `pass`, 26 checks
- `python3 operational_surface_alignment_audit.py --out-prefix /tmp/solo_mapper_reconciled_operational_surface`: `pass`
- `python3 deckbuilding_contract_surface_audit.py --out-prefix /tmp/solo_mapper_reconciled_deckbuilding_contract`: `pass`
- `python3 pg_hermes_sqlite_contract_audit.py --skip-pg --sqlite-db .../knowledge.db --out-prefix /tmp/solo_mapper_reconciled_pg_hermes_sqlite_skip_pg`: `pass`, 29 pass and 3 expected warnings (`skipped_pg`, `skipped_pg`, `trusted_executable_rules_missing_oracle_hash=1418`)

## Next executable work

1. Build a seed-safe same-lane/additive package for topdeck access, tutor, hand-filter, or recursion.
2. Run the battle benchmark only when that package exposes the candidate card and records drawn/cast/used evidence.
3. Package Deathbellow only after Oracle hash/precheck; leave the other four rule-first cards deferred until their runtime families are explicitly modeled.
