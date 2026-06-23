# PG110 The Scarlet Witch Static Cost Reducer Package

Status: `prepared_read_only_precheck_pending_apply_approval`.

Scope:

- Card: `The Scarlet Witch`.
- Oracle hash: `6129fda2f5ae1f8edad5a2f2e77d05c2`.
- Proposed logical rule key:
  `battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc`.
- Proposed effect: `static_cost_reduction` with
  `cost_reduction_amount_source=source_power`, `applies_to_card_types=["instant","sorcery"]`,
  and `minimum_mana_value=4`.
- Proposed deck role: `support/cost_reducer`.
- No PostgreSQL apply was executed while preparing this package.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg110_the_scarlet_witch_static_cost_reducer_precheck_20260623_150416.sql`.
- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg110_the_scarlet_witch_static_cost_reducer_precheck_20260623_150416.json`
  and
  `docs/hermes-analysis/master_optimizer_reports/pg110_the_scarlet_witch_static_cost_reducer_precheck_20260623_150416.out`.
- Apply candidate:
  `docs/hermes-analysis/master_optimizer_reports/pg110_the_scarlet_witch_static_cost_reducer_apply_20260623_150416.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg110_the_scarlet_witch_static_cost_reducer_rollback_20260623_150416.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg110_the_scarlet_witch_static_cost_reducer_postcheck_20260623_150416.sql`.
- Runtime artifact:
  `docs/hermes-analysis/master_optimizer_reports/scarlet_witch_runtime_validation_20260623_150416.json`
  and `.md`.
- XMage index:
  `docs/hermes-analysis/master_optimizer_reports/xmage_local_rule_index_deck607_pg108_high_medium_scarlet_20260623_150235.json`
  and `.md`.
- XMage batch gate:
  `docs/hermes-analysis/master_optimizer_reports/xmage_batch_validity_audit_deck607_pg108_high_medium_scarlet_20260623_150242.json`
  and `.md`.
- Pre-apply deck-card coherence audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg110_scarlet_preapply_20260623_150416.json`
  and `.md`.

Runtime evidence:

- `battle_analyst_v9.py` now supports static cost reduction whose amount is
  derived from source permanent power and whose matching can be constrained by
  card type and minimum mana value.
- `battle_stack_casting_tests.py` includes focused tests proving:
  a mana-value-4 sorcery is reduced by `The Scarlet Witch` power, while a
  mana-value-3 instant and a mana-value-4 creature are not reduced.
- Runtime artifact confirms:
  `mv4_sorcery_static_cost_reduction_total=2`,
  `mv4_sorcery_applied_amount=2`,
  `mv3_has_reduction=false`, and
  `mv4_creature_has_reduction=false`.
- Pre-apply deck-card audit still reports `high=9`, `medium=4`, `pass=81`;
  this is expected because PG110 was not applied and no PG -> SQLite sync was
  run.

PostgreSQL read-only precheck result:

- Target DB: `143.198.230.247:5433/halder`.
- Precheck executed only `SELECT/WITH` statements in a readonly session and
  recorded `mutations_performed=[]`.
- `target_card_rows=1`.
- `card_oracle_hash_match_rows=1`.
- `existing_rule_rows=0`.
- `expected_rule_rows_before=0`.
- `trusted_rule_rows_before=0`.
- `active_static_cost_reduction_rows_before=0`.
- `would_deprecate_shadow_rows=0`.
- `rows_missing_oracle_hash_before=0`.

XMage evidence:

- Exact local XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/t/TheScarletWitch.java`.
- XMage effect uses `CostModificationEffectImpl`, `FilterInstantOrSorceryCard`,
  `ManaValuePredicate(ComparisonType.OR_GREATER, 4)`,
  `SourcePermanentPowerValue.NOT_NEGATIVE`, and `CardUtil.reduceCost`.
- Batch gate reports `ready_for_structured_pull=true`, `valid_xmage_source=true`,
  `specific_effect_candidate=true`, `type_match=true`, `mana_cost_match=true`,
  and `focused_test_scenario_count=2`.

Executed validation:

- Focused Scarlet harness:
  `ran=2` for
  `test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power` and
  `test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`:
  `Ran 8 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py --help`:
  due the harness behavior, this executed the full suite and all printed tests
  passed, including the two new Scarlet tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-id 607 --output-json docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg110_scarlet_preapply_20260623_150416.json --output-md docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg110_scarlet_preapply_20260623_150416.md`:
  `severity_counts={"high":9,"medium":4,"pass":81}`.

Apply gate:

- PG110 is prepared but not applied.
- Do not run
  `docs/hermes-analysis/master_optimizer_reports/pg110_the_scarlet_witch_static_cost_reducer_apply_20260623_150416.sql`
  without explicit approval for the exact command.
- If approved later, required sequence is precheck, apply, postcheck,
  PG -> SQLite sync for `The Scarlet Witch`, focused tests, and deck `607`
  coherence re-audit.
