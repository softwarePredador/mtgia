# PG108 Pearl Medallion Static Cost Reducer Package

Status: `prepared_read_only_precheck_pending_apply_approval`.

Scope:

- Card: `Pearl Medallion`.
- Oracle hash: `77f7f449ee56143d6b63814fecd37176`.
- Proposed logical rule key:
  `battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2`.
- Proposed effect: `static_cost_reduction`, not `ramp_permanent`.
- Proposed deck role: `support/cost_reducer`.
- No PostgreSQL apply was executed while preparing this package.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg108_pearl_medallion_static_cost_reducer_precheck_20260623_170353.sql`.
- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg108_pearl_medallion_static_cost_reducer_precheck_20260623_170353.json`
  and
  `docs/hermes-analysis/master_optimizer_reports/pg108_pearl_medallion_static_cost_reducer_precheck_20260623_170353.out`.
- Apply candidate:
  `docs/hermes-analysis/master_optimizer_reports/pg108_pearl_medallion_static_cost_reducer_apply_20260623_170353.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg108_pearl_medallion_static_cost_reducer_rollback_20260623_170353.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg108_pearl_medallion_static_cost_reducer_postcheck_20260623_170353.sql`.
- Focused runtime artifact:
  `docs/hermes-analysis/master_optimizer_reports/pg108_pearl_medallion_static_cost_reducer_focused_runtime_20260623_170353.json`.
- Pre-apply deck-card coherence audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg108_pearl_preapply_20260623_170353.json`
  and
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg108_pearl_preapply_20260623_170353.md`.
- Fresh external reference packet:
  `docs/hermes-analysis/master_optimizer_reports/external_card_rule_reference_harvest_deck607_pg108_pearl_20260623_170353.json`
  and
  `docs/hermes-analysis/master_optimizer_reports/external_card_rule_reference_harvest_deck607_pg108_pearl_20260623_170353.md`.

Runtime evidence:

- `battle_analyst_v9.py` now has a state-aware static cost-reduction path used
  by cast announcement, card affordability checks, and card mana spending.
- `battle_mana_cost_support.py` now carries static cost-reduction provenance in
  replay locked-cost snapshots.
- `battle_stack_casting_tests.py` includes focused tests proving:
  `Pearl Medallion` is not a mana source, a white spell gets one generic cost
  reduced, and a non-white spell does not get the reduction.
- Focused runtime artifact confirms:
  `White Audit Spell` locks `generic=1`, `colored.white=1`,
  `static_cost_reduction_total=1`, pays successfully, and leaves
  `available_mana_after=0`; `Blue Audit Spell` locks `generic=1`,
  `colored.blue=1`, receives no static reduction, and cannot be paid with only
  one blue mana.

Executed validation:

- `python3 -m py_compile` for the changed battle/harvester/hint modules:
  exit `0`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`:
  `Ran 3 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_external_card_rule_reference_harvester.py`:
  `Ran 7 tests OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`:
  passed, including the two new Pearl Medallion casting tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --deck-id 607 --output-json docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg108_pearl_preapply_20260623_170353.json --output-md docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg108_pearl_preapply_20260623_170353.md`:
  `severity_counts={"high":9,"medium":4,"pass":81}`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/external_card_rule_reference_harvester.py --from-report docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck607_pg108_pearl_preapply_20260623_170353.json --limit 3 --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master --output-json docs/hermes-analysis/master_optimizer_reports/external_card_rule_reference_harvest_deck607_pg108_pearl_20260623_170353.json --output-md docs/hermes-analysis/master_optimizer_reports/external_card_rule_reference_harvest_deck607_pg108_pearl_20260623_170353.md`:
  `cards=3`, `mutations_performed=[]`.

PostgreSQL read-only precheck result:

- Target DB: `143.198.230.247:5433/halder`.
- `target_card_rows=1`.
- `card_oracle_hash_match_rows=1`.
- `existing_rule_rows=2`.
- `expected_rule_rows_before=0`.
- `trusted_rule_rows_before=0`.
- `active_ramp_shadow_rows_before=2`.
- `would_deprecate_shadow_rows=2`.
- `rows_missing_oracle_hash_before=2`.
- Pre-apply deck-card audit still reports `Pearl Medallion` as `high` with
  `trusted_executable_rule_count=0`, `review_only_rule_count=2`, and effects
  `["ramp_permanent"]`; this is expected until PG108 is applied and synced.
- Fresh external reference packet reports `PearlMedallion` found in local
  XMage and candidate effect
  `static_cost_reduction` with `applies_to_spell_colors=["W"]`.

Apply gate:

- Do not run the apply SQL without explicit approval for the exact command.
- If approved later, run precheck, apply, postcheck, PG-to-SQLite sync for
  `Pearl Medallion`, focused tests, and a deck-card coherence re-audit.
