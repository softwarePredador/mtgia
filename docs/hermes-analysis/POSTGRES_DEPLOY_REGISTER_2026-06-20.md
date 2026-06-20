# PostgreSQL Deploy Register - 2026-06-20

Owner: Auditor Central / single operator
Controller: Auditor Central
Status: active register, PG-001, PG-002, PG-006, PG-007, PG-008, PG-009, and
Lorehold canonical Wheel apply applied and validated; PG-006, PG-007, PG-008,
and Lorehold canonical Wheel runtime cache sync completed; PG-003 remains not
ready; PG-005 remains no-apply-needed; latest official full battle now resolves
to `20260620_212035` and is trusted for strategy learning; no new apply was
executed by this heartbeat

## Purpose

This register is the source of truth for ManaLoom PostgreSQL deploys coordinated
and executed by the Auditor Central in single-operator mode.

The older split between Deck/Battle executor chats and a separate DBA chat is
deprecated while Rafael keeps the other chats paused. PostgreSQL writes are now
handled in this Auditor Central thread. On 2026-06-20 08:51 -0300 Rafael
explicitly changed the operating model to "faca tudo, faca deploy, suba em
banco"; PG-006, PG-002, PG-007, and PG-008 were applied in this thread after
their prechecks matched the prepared packages.

## Mandatory Deploy Protocol

Every PostgreSQL write requires:

1. `git status --short --branch`
2. source artifact or code evidence
3. exact table/column scope
4. exact affected row count
5. SELECT pre-apply
6. SQL/apply command
7. rollback SQL
8. non-destructive tests or dry-runs
9. Auditor Central review
10. explicit Rafael approval for the exact apply command in this thread
11. SELECT post-apply
12. register update with result and evidence

No additional deck swaps, commits, pushes, or destructive cleanup are authorized
by this register. The Lorehold canonical Wheel apply below is historical
evidence of an already-executed approved deck/data correction, not standing
authorization for any future swap.

## Current Database Deploy Queue

### Lorehold canonical Wheel apply - 2026-06-20 15:15 -0300

Status: `applied_validated_runtime_synced_battle_trusted`
Source front: Lorehold Deck 6 canonical deck decision
Target tables: `deck_cards`, `commander_learned_decks`
Target deck: `528c877f-f829-4207-95e6-73981776c323`
Target learned deck: `f46c0421-71b4-4de3-bb79-05a916b4988b`
Apply authorized: documented approved canonical Lorehold decision
DB mutations executed by this historical event: `true`
DB mutations executed by the 15:28 heartbeat reconciliation: `false`

Pre-apply blocker evidence:

- Before the apply, Lorehold canonical strategy expected
  `Wheel of Misfortune` and rejected `Reforge the Soul`.
- Precheck artifact
  `docs/hermes-analysis/master_optimizer_reports/pg_precheck_aven_lorehold_20260620_180309.json`
  showed the materialized Lorehold deck still had `Reforge the Soul` and the
  active `learned_deck:82` card list still had `Reforge the Soul`.

Deploy result:

- Apply result artifact:
  `docs/hermes-analysis/master_optimizer_reports/pg_apply_lorehold_wheel_swap_result_20260620_180448.json`.
- Materialized deck check after apply:
  `wheel=1`, `reforge=0`, `rows=100`, `total_cards=100`.
- Active learned-deck check after apply:
  `has_wheel=true`, `has_reforge=false`, `card_count=100`, and metadata
  `canonical_lorehold_swap_20260620`.
- Backup artifact:
  `docs/hermes-analysis/master_optimizer_reports/pg_apply_lorehold_wheel_swap_backup_20260620_180448.json`.

Runtime sync and battle proof:

- PostgreSQL -> Hermes deck sync evidence:
  `sync_pg_target_deck_to_hermes_lorehold_post_wheel_20260620_1805.json`.
- Approved canonical deck snapshot after sync:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_post_pg_swap_check_20260620_1806.md`
  with 100 cards, 33 lands, `Wheel of Misfortune` present, and
  `Reforge the Soul` absent.
- Fresh read-only learned-deck audit:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_181429.json`
  with Lorehold `learned_deck:82` `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `total_lands=33`, and strategy package pass.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_181004/summary.json`.
- Battle result: `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":16}`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `decision_audit_decision_findings=0`, `decision_audit_turn_findings=0`, and
  `action_findings=0`.
- Later target-pressure battle validation:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/summary.json`
  supersedes the `181004` battle proof for current strategy-learning
  readiness. It performed no PostgreSQL write and reports
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":17}`,
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=117`, and
  `target_pressure_opponent_combat_to_other=0`.
- Later official battle drift:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_191248/summary.json`
  supersedes `185748` as the live `latest` pointer and is `blocked`, but the
  blocker is a battle runtime safety defect: seed `63211917` executed
  `Goblin Bombardment` from a `needs_review` / `review_only` canonical snapshot
  rule. Target-pressure still passes `16/16` with `84/84` opponent combats into
  Lorehold and `0` opponent combats into other defenders. No PostgreSQL write
  is justified by this blocker.
- Later official battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_195007/summary.json`
  supersedes `191248`; the Goblin blocker and target-pressure blocker are
  closed, but the run remains `blocked` by `forensic_audit=blocked` and
  `replay_decision_audit=review_required`. Current forensic blockers are
  learned-opponent card-rule lineage gaps from `functional_tags_json`, not a
  rollback of the Lorehold Wheel apply.
- Latest official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200409/summary.json`
  supersedes `195007`; the prior table-intent metadata false positive is
  closed by focused proof `20260620_200322`, but the full run remains
  `blocked` by `forensic_audit=blocked` and `table_intent=blocked`. This is
  not evidence of a rollback of the Lorehold Wheel apply.
- Later official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_203616/summary.json`
  supersedes `200409`; the recurring wrapper now includes `target_pressure` in
  the mandatory gate list and status map. The full run remains `blocked` by
  `forensic_audit=blocked` and `target_pressure=blocked`, with `table_intent`
  passing `16/16`. This is not evidence of a rollback of the Lorehold Wheel
  apply or any prior PostgreSQL package.
- Current official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_204002/summary.json`
  supersedes `203616`; the full run remains `blocked` by
  `forensic_audit=blocked` and `target_pressure=blocked`, with `table_intent`,
  `event_contract_static`, `replay_decision_audit`, and `action_critic`
  passing. This is not evidence of a rollback of the Lorehold Wheel apply or
  any prior PostgreSQL package.
- New current official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_205821/summary.json`
  supersedes `204002`; the full run is now `review_required` by
  `forensic_audit=review_required`. Target-pressure, table-intent,
  event-contract, replay-decision, and action gates pass. The remaining
  findings are two low `Goblin Bombardment` registry/runtime drift findings.
  This is not evidence of a rollback of the Lorehold Wheel apply or any prior
  PostgreSQL package.
- Current official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_210513/summary.json`
  supersedes `205821`; the full run is now `blocked` by
  `forensic_audit=blocked`. Target-pressure, table-intent, event-contract,
  replay-decision, and action gates pass. Current high/medium blockers are
  opponent cards `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, and
  `The Unagi of Kyoshi Island` using `functional_tags_json`. This is not
  evidence of a rollback of the Lorehold Wheel apply or any prior PostgreSQL
  package.
- Current official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211217/summary.json`
  supersedes `210513`; the full run remains `blocked` by
  `forensic_audit=blocked`. Target-pressure, table-intent, event-contract,
  replay-decision, and action gates pass. Current high/medium blockers are
  opponent cards `Tellah, Great Sage` and `Practical Research` using
  `functional_tags_json`. This is not evidence of a rollback of the Lorehold
  Wheel apply or any prior PostgreSQL package.
- Current official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211648/summary.json`
  supersedes `211217`; the full run is now `review_required` by
  `forensic_audit=review_required`. Target-pressure, table-intent,
  event-contract, replay-decision, and action gates pass. The remaining
  findings are two low `Breena, the Demagogue` registry/runtime drift
  findings. This is not evidence of a rollback of the Lorehold Wheel apply or
  any prior PostgreSQL package.
- Current official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`
  supersedes `211648`; the full run is now
  `trusted_for_strategy_learning` with `mandatory_gate_divergences=[]`.
  Target-pressure, forensic, table-intent, event-contract, replay-decision,
  and action gates pass. This is not evidence of a rollback of the Lorehold
  Wheel apply or any prior PostgreSQL package.

### PG-010 candidate - opponent card battle-rule lineage gaps

Status: `externally_advanced_latest_trusted_no_apply_by_this_heartbeat`
Source front: latest battle forensic audit
Target table if approved later: `card_battle_rules`
DB mutations executed by this checkpoint: `false`

Current evidence:

- Latest full run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `forensic_rule_findings=0`, `forensic_turn_findings=0`.
- Table-intent passes in the latest full run:
  `table_intent.statuses={"pass":16}`, `findings=0`.
- Target-pressure passes in the latest full run:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=214`, and
  `target_pressure_opponent_combat_to_other=3`.

Detected round5 artifact evidence:

- `card_battle_rules_pg_table_intent_promotions_round5_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=3`, selected cards
  `Big Score` and `Spelltwine`, `input_rows=3`, `curated_rows=2`, and
  `generated_rows=1`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round5_20260620.json`
  declares `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5224`, `sqlite_inserted_or_updated=5142`, and
  `canonical_snapshot_rows_exported=3181`.
- This heartbeat detected the files and latest battle effect but did not run
  PostgreSQL apply, SQLite sync, cleanup, stage, commit, or push.

Detected round6 artifact evidence:

- `card_battle_rules_pg_table_intent_promotions_round6_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=2`, selected card
  `Goblin Bombardment`, `input_rows=2`, `curated_rows=1`, and
  `generated_rows=1`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round6_20260620.json`
  declares `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5225`, `sqlite_inserted_or_updated=5143`, and
  `canonical_snapshot_rows_exported=3181`.
- This heartbeat detected the files and latest battle effect but did not run
  PostgreSQL apply, SQLite sync, cleanup, stage, commit, or push.

Detected round7 artifact evidence after latest `210513`:

- `card_battle_rules_pg_table_intent_promotions_round7_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=6`, selected cards
  `Apex of Power`, `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, and
  `The Unagi of Kyoshi Island`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round7_20260620.json`
  declares `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`, and
  `canonical_snapshot_rows_exported=3185`.
- The later latest battle `20260620_212035` supersedes `211648`: the prior
  `210513`, `211217`, and `211648` blocker/review sets are superseded, and no
  current forensic finding remains.
- This heartbeat did not run PostgreSQL apply, SQLite sync, cleanup, stage,
  commit, or push.

Detected round8 artifact evidence:

- `card_battle_rules_pg_table_intent_promotions_round8_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=2`, selected cards
  `Practical Research` and `Tellah, Great Sage`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round8_20260620.json`
  declares `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5232`, `sqlite_inserted_or_updated=5150`, and
  `canonical_snapshot_rows_exported=3187`.
- This heartbeat detected the files and latest battle effect but did not run
  PostgreSQL apply, SQLite sync, cleanup, stage, commit, or push.

Detected round9 artifact evidence:

- `card_battle_rules_pg_table_intent_promotions_round9_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=2`, selected card
  `Breena, the Demagogue`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round9_20260620.json`
  declares `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5233`, `sqlite_inserted_or_updated=5151`, and
  `canonical_snapshot_rows_exported=3187`.
- This heartbeat detected the files and latest battle effect but did not run
  PostgreSQL apply, SQLite sync, cleanup, stage, commit, or push.

Read-only local cache evidence:

- `card_oracle_cache` has oracle metadata for `Abandon Attachments`,
  `Channeled Force`, `Hypothesizzle`, `The Emperor of Palamecia`,
  `Firemind Vessel`, `Sisay, Weatherlight Captain`, and
  `Kraum, Ludevic's Opus`.
- Local `battle_card_rules` has generated `needs_review` / `review_only` rows
  for `Laughing Mad`, `One with the Multiverse`, `Shark Typhoon`, and
  `Stonespeaker Crystal`, which now surface only as low passive/review
  mismatches after the canonical snapshot safety fix.

Next safe step:

- No current PostgreSQL apply is ready. Keep PG-010 as a watch item only:
  if a future full battle reintroduces card-rule lineage drift, start from
  read-only evidence, dry-run/precheck/rollback, and exact Rafael approval
  before any apply.

### PG-008 - Machine God's Effigy battle-rule lineage blocker

Status: `applied_validated_runtime_synced_battle_trusted`
Source front: latest battle forensic audit
Target table: `card_battle_rules`
Target row: `normalized_name='machine god''s effigy'`,
`logical_rule_key='battle_rule_v1:c07949dca69471872a2d2b70c527b5f8'`
Apply authorized: `true` by Rafael's single-operator directive and later
authorization to organize/deploy/validate in this thread
DB mutations executed by this register: `true`

Pre-apply blocker evidence:

- Before PG-008, the latest battle symlink resolved to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_150241/summary.json`.
- That historical latest reported
  `battle_replay_final_status=review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_lineage_status=incomplete`, `forensic_rule_findings=1`,
  `forensic_turn_findings=0`, and `test_results_total=16` with all tests
  passing.
- Blocking seed artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_150241/seed_63211509/forensic_audit.json`.
- The finding is one medium forensic rule finding:
  `Machine God's Effigy`, event `spell_cast`, effect `ramp_permanent`, source
  `functional_tags_json`; the forensic recommendation says to move the card
  into `card_battle_rules` with verified/active status.

Pre-apply read-only PostgreSQL evidence:

- Target card exists:
  `cards.id=1f48fdfb-983c-429b-a777-df0ce2b1d8f0`,
  `cards.name='Machine God's Effigy'`,
  `type_line='Artifact'`,
  `oracle_id=64ebdd6f-acde-4aab-a86b-2798bad5f70c`.
- At that point, `card_battle_rules` had no Machine God's Effigy row:
  `pg008_existing_target_rule=0`,
  `pg008_existing_any_machine_gods_effigy_rule=0`.
- At that point, `card_intelligence_snapshot` for the card had
  `battle_rule_count=0`, `battle_rules=[]`, `function_tags={ramp}`, and
  `source_coverage.has_any_battle_rules=false`.

Prepared package:

- Package report:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_package_20260620_1210.md`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_precheck_20260620_1210.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_apply_20260620_1210.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_rollback_20260620_1210.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_postcheck_20260620_1210.sql`

Proposed row:

- `source=curated`
- `review_status=active`
- `execution_status=auto`
- `confidence=0.820`
- `effect_json.effect=ramp_permanent`
- `effect_json.produces=U`
- `effect_json.mana_produced=1`
- `effect_json.battle_model_scope=copy_artifact_mana_rock_partial_v1`
- `effect_json.copy_target_selection_not_modeled=true`
- `deck_role_json.category=ramp`
- `deck_role_json.subtype=copy_artifact_mana_rock`

Deploy result:

- Precheck result: target card `1`, existing target rule `0`, existing any
  Machine God's Effigy rule `0`, snapshot before `battle_rules=[]`,
  `battle_rule_count=0`, `function_tags={ramp}`.
- Apply result: `INSERT 0 1`, `COMMIT`, row now has `source=curated`,
  `review_status=active`, `execution_status=auto`, `confidence=0.820`.
- Postcheck result: `pg008_target_rule_count=1`; `card_intelligence_snapshot`
  now exposes the Machine God's Effigy rule in `battle_rules`; backup rows `0`
  because no prior target row existed.
- Rollback file retained:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_rollback_20260620_1210.sql`.

Runtime sync and battle proof:

- SQLite backup:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg008-runtime-sync.20260620_1210.bak`.
- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json`.
- Sync result: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108`,
  `canonical_snapshot_rows_exported=3161`.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_151437/summary.json`.
- Battle result: `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, and
  `test_results_total=16` with `test_results_status_counts={"pass":16}`.

### PG-007 - Leyline of Abundance battle-rule lineage blocker

Status: `applied_validated_runtime_synced_battle_trusted`
Source front: latest battle forensic audit
Target table: `card_battle_rules`
Target row: `normalized_name='leyline of abundance'`,
`logical_rule_key='battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941'`
Apply authorized: `true` by Rafael's single-operator directive in this thread:
`faca tudo, faca deploy, suba em banco`
DB mutations executed by this register: `true`

Pre-apply blocker evidence:

- Before PG-007, the latest battle symlink resolved to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/summary.json`.
- That historical latest was `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63211257`.
- It reported `battle_replay_final_status=review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_lineage_status=incomplete`, `forensic_rule_findings=1`,
  `forensic_turn_findings=0`, and `test_results_total=16` with all tests
  passing.
- Blocking seed artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/seed_63211258/forensic_audit.json`.
- The finding is one medium forensic rule finding:
  `Leyline of Abundance`, event `spell_cast`, effect `ramp_permanent`, source
  `functional_tags_json`; the forensic recommendation says to move the card
  into `card_battle_rules` with verified/active status.

Pre-apply read-only PostgreSQL evidence:

- Target card exists:
  `cards.id=d524183f-6430-411b-8a9b-48eda6cb0f7d`,
  `cards.name='Leyline of Abundance'`,
  `type_line='Enchantment'`,
  `oracle_id=1197a595-3afc-4f18-b868-bbb096771922`.
- At that point, `card_battle_rules` had no Leyline row:
  `pg007_existing_target_rule=0`,
  `pg007_existing_any_leyline_rule=0`.
- At that point, `card_intelligence_snapshot` for the card had
  `battle_rules=[]` and `function_tags={engine}`.
- Migration heartbeat remains clean:
  `cd server && dart run bin/migrate.dart --status` reports all `29/29`
  migrations executed and `0` pending.

Prepared package:

- Package report:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_package_20260620_1018.md`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`

Proposed row:

- `source=curated`
- `review_status=active`
- `execution_status=auto`
- `confidence=0.820`
- `effect_json.effect=ramp_permanent`
- `effect_json.battle_model_scope=leyline_of_abundance_static_mana_bonus_partial_v1`
- `effect_json.activated_counter_ability_not_modeled=true`
- `deck_role_json.category=ramp`
- `deck_role_json.subtype=static_mana_bonus_enchantment`

Deploy result:

- Precheck command:
  `psql ... -f docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql`
- Precheck result: target card `1`, existing target rule `0`, existing any
  Leyline rule `0`, snapshot before `battle_rules=[]`, `function_tags={engine}`.
- Apply command:
  `psql ... -f docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql`
- Apply result: `INSERT 0 1`, `COMMIT`, row now has `source=curated`,
  `review_status=active`, `execution_status=auto`, `confidence=0.820`.
- Postcheck command:
  `psql ... -f docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`
- Postcheck result: `pg007_target_rule_count=1`; `card_intelligence_snapshot`
  now exposes the Leyline rule in `battle_rules`; backup rows `0` because no
  prior target row existed.
- Rollback file retained:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql`.

Runtime sync and battle proof:

- SQLite backup:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg007-runtime-sync.20260620_102701.bak`.
- Sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`.
- Sync result: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107`,
  `canonical_snapshot_rows_exported=3160`.
- Coverage reports:
  `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260620_102701_post_pg007_sync.json`.
- Coverage result: `runtime_safe_rule_names=1703`,
  `active_or_review_rule_names=3160`,
  `execution_status_counts={"auto":1703,"review_only":1457}`.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`.
- Battle result: `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63211328`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, and
  `test_results_total=16` with `test_results_status_counts={"pass":16}`.
- Per-seed forensic proof: all `16` seed forensic files were checked and
  `bad_forensic_files=0`.

### Queue heartbeat - 2026-06-20 10:50 -0300

Scope: read-only PostgreSQL queue recheck after PG-007 apply, runtime cache
sync, latest battle rerun, and aggregate source validation.

Results:

- `cd server && dart run bin/migrate.dart --status` reports all `29/29`
  migrations executed and `0` pending.
- PG-001 remains closed:
  `plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`
  returned `status=PASS`, `planned_row_count=0`, `planned_rows=[]`, and
  `db_mutations=false`.
- PG-002 remains applied:
  `learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`
  returned `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`, and
  `all_post_apply_checks_ok=true`.
- PG-003 remains not ready:
  `plan_oracle_text_backfill.py --no-scryfall --limit 10` returned
  `status=PASS`, `mode=read_only`, `db_mutations=false`,
  `base_oracle_summary={"total_cards":34329,"missing_any":363,"missing_oracle_id":4,"missing_oracle_text":360}`,
  `planned_items=6`, `deck_card_gap_items=6`,
  `active_learned_gap_items=0`, and `backfill_ready=0`.
- PG-005 remains no-apply-needed:
  `plan_lorehold_critical_role_backfill.py --dry-run` returned
  `status=PASS`, `mode=dry_run`, `db_mutations=false`,
  `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`,
  and unchanged existing row counts `5/11/4`.
- PG-007 remains applied:
  `leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`
  returned `pg007_target_rule_count=1`, the Leyline row in
  `card_battle_rules`, the same rule exposed through
  `card_intelligence_snapshot.battle_rules`, and backup rows `0`.
- Latest battle artifact symlink resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`
  and remains `trusted_for_strategy_learning`, with
  `mandatory_gate_divergences=[]`, forensic lineage complete, and tests
  `16/16` pass.

Operational conclusion:

- There is no current PostgreSQL apply ready at this heartbeat.
- Do not reapply PG-001, PG-002, PG-006, or PG-007 unless future SELECT,
  sync, or battle-artifact evidence proves rollback or drift.
- No PostgreSQL write, deck swap, cleanup, commit, push, revert, stash, or
  deletion was performed in this heartbeat.

### Queue heartbeat - 2026-06-20 10:09 -0300

Scope: historical deploy-governance recheck before PG-007; Auditor Central had
patched and validated
the backend recommendations advisory guard, battle focused-evidence harness,
and ops-daemon env test isolation.

Results:

- No PostgreSQL write was performed in this source-patch slice.
- No new SQL package was generated by this source-patch slice.
- Post-register verification:
  `git diff --check` returned no output and
  `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
  passed `6/6`.
- The recommendations advisory change is code/contract behavior only: parsed
  OpenAI text cannot override backend-owned fallback context fields when those
  fields are present.
- The battle focused-evidence change is Python harness evidence behavior only:
  extra-combat flashback validation now uses the original spell effect data.
- The ops-daemon test change is test isolation only: it prevents shell
  `DB_HOST` and `DB_NAME` values from contaminating `.env` loading assertions.
- Latest known PostgreSQL queue state remains unchanged: PG-001, PG-002, and
  PG-006 are applied/validated; PG-003 is policy-blocked; PG-004 has no current
  trusted latest finding requiring a package; PG-005 is no-apply-needed.

Operational conclusion:

- There is no current PostgreSQL apply ready after this source-patch cycle.
- Do not reapply PG-001, PG-002, or PG-006 unless future SELECT evidence proves
  rollback or drift.
- Do not create a PG-004/Leyline package from superseded `090636` evidence.
- No deck swap, cleanup, commit, push, revert, stash, or deletion was
  performed.

### Queue heartbeat - 2026-06-20 09:51 -0300

Scope: read-only PostgreSQL queue recheck after Rafael confirmed
single-operator mode for audit, deploy governance, validation, and worktree
control.

Results:

- `cd server && dart run bin/migrate.dart --status` reports all `29/29`
  migrations executed and `0` pending.
- PG-001 remains closed:
  `plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`
  returned `status=PASS`, `planned_row_count=0`, `planned_rows=[]`, and
  `db_mutations=false`.
- PG-002 remains applied:
  `learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`
  returned `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`, and
  `all_post_apply_checks_ok=true`.
- PG-003 remains not ready:
  `plan_oracle_text_backfill.py --no-scryfall --limit 10` returned
  `status=PASS`, `mode=read_only`, `db_mutations=false`,
  `base_oracle_summary={"total_cards":34329,"missing_any":363,"missing_oracle_id":4,"missing_oracle_text":360}`,
  `planned_items=6`, `deck_card_gap_items=6`,
  `active_learned_gap_items=0`, and `backfill_ready=0`.
- PG-005 remains no-apply-needed:
  `plan_lorehold_critical_role_backfill.py --dry-run` returned
  `status=PASS`, `mode=dry_run`, `db_mutations=false`,
  `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`,
  and unchanged existing row counts `5/11/4`.
- PG-006 remains applied:
  `card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql`
  returned migration `029`, the `execution_status` NOT NULL column, the
  `chk_card_battle_rules_execution_status` constraint, PostgreSQL counts
  `auto=1751` and `review_only=3437`, and
  `remaining_needs_review_not_review_only=0`.
- Latest battle artifact symlink resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`.
- Latest `summary.json` reports
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `test_results_total=16`,
  `test_results_status_counts={"pass":16}`,
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, `review_only_rule_names=1457`, and
  `runtime_surface_manifest_total_files=110`.

Operational conclusion:

- No PostgreSQL apply is currently ready.
- PG-001, PG-002, and PG-006 remain closed unless a future SELECT proves
  rollback or drift.
- PG-003 is still policy-blocked and must not be applied without row-by-row
  policy for official blank oracle text, Arena/Alchemy `A-` identities,
  aliases, and reprints.
- PG-004/Leyline remains closed from the latest trusted battle run.
- No PostgreSQL write, deck swap, cleanup, commit, push, revert, stash, or file
  deletion was performed in this heartbeat.

### Queue heartbeat - 2026-06-20 09:36 -0300

Scope: read-only migration/latest-artifact recheck after documentation
contradiction audit.

Results:

- `cd server && dart run bin/migrate.dart --status` reports all `29/29`
  migrations executed and `0` pending.
- Latest battle artifact symlink resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`.
- Latest `summary.json` reports
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={"pass":16}`,
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, `review_only_rule_names=1457`, and
  `runtime_surface_manifest_total_files=110`.

Operational conclusion:

- No PostgreSQL apply is currently ready.
- PG-002 and PG-006 remain closed; do not reapply unless a future SELECT proves
  rollback or drift.
- PG-004/Leyline remains closed from the latest trusted battle run; do not
  create a PostgreSQL package from superseded `090636` evidence.
- No PostgreSQL write, deck swap, cleanup, commit, push, revert, or stash was
  performed.

### Queue heartbeat - 2026-06-20 09:24 -0300

Scope: SELECT/read-only planner recheck of the current PostgreSQL queue after
PG-001, PG-002, and PG-006 had already been applied.

Results:

- PG-001 remains closed:
  `plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`
  returned `status=PASS`, `planned_row_count=0`, `planned_rows=[]`, and
  `db_mutations=false`.
- PG-002 remains applied:
  `learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`
  returned `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`, and
  `all_post_apply_checks_ok=true`.
- PG-003 remains not ready:
  `plan_oracle_text_backfill.py --no-scryfall --limit 10` returned
  `status=PASS`, `mode=read_only`, `db_mutations=false`,
  `base_oracle_summary={"total_cards":34329,"missing_any":363,"missing_oracle_id":4,"missing_oracle_text":360}`,
  `planned_items=6`, `deck_card_gap_items=6`,
  `active_learned_gap_items=0`, and `backfill_ready=0`.
- PG-005 remains no-apply-needed:
  `plan_lorehold_critical_role_backfill.py --dry-run` returned `status=PASS`,
  `mode=dry_run`, `db_mutations=false`,
  `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`,
  and unchanged existing row counts `5/11/4`.
- PG-006 remains applied:
  direct PostgreSQL SELECTs returned `execution_status auto=1751`,
  `review_only=3437`, `generated_needs_review_not_review_only=0`, and
  `schema_migrations.version='029'` count `1`.

No PostgreSQL write, deck swap, cleanup, commit, push, revert, or stash was
performed. A full canonicalizer dry-run was started but interrupted after it
did not finish in a useful window; it is not counted as evidence for this
heartbeat.

### PG-001 - Partner/background identity metadata backfill

Status: `applied_validated`
Source front: Ajustar Deck / learned-deck audit
Target table: `commander_learned_decks`
Target column: `metadata`
Mutation type: JSON metadata update only
Apply authorized: `true`
DB mutations executed by this register: `true`

Source artifact:

- `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_plan_20260620_005219.json`

Current evidence:

- `status=PASS`
- `mode=dry_run`
- `db_mutations=false`
- `apply_supported=false`
- `apply_requires_explicit_approval=true`
- `planned_row_count=10`
- rollback scope in artifact: table `commander_learned_decks`, column
  `metadata`
- DBA package prepared at `2026-06-20 06:33 -0300`; no PostgreSQL write was
  executed.
- SELECT-only precheck result:
  `expected_rows=10`, `matched_rows=10`, `needs_update_rows=10`,
  `already_persisted_rows=0`.
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_apply_20260620_063349.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_rollback_20260620_063349.sql`
- SELECT pre-apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_precheck_20260620_063349.sql`
- SELECT post-apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_postcheck_20260620_063349.sql`
- Rafael approved apply in chat on `2026-06-20 06:39 -0300` with:
  `esta autorizado faca`.
- Apply executed at `2026-06-20 06:39 -0300` with:
  `cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_apply_20260620_063349.sql`
- Apply result: `COMMIT`, `INSERT 0 10`, `updated_count=10`, and `10`
  returned rows all with `identity_status=combined_identity_inferred` and
  `backfill_source=learned_deck_partner_identity_inference_2026_06_20`.
- SELECT post-apply result:
  `expected_rows=10`, `matched_rows=10`, `model_ok_rows=10`,
  `combined_identity_ok_rows=10`, `backfill_source_ok_rows=10`,
  `all_post_apply_checks_ok=true`.
- Partner identity planner post-apply result:
  `status=PASS`, `planned_row_count=0`, `db_mutations=false`.
- Auditor Central independent postcheck at `2026-06-20 06:43 -0300`:
  `expected_rows=10`, `matched_rows=10`, `model_ok_rows=10`,
  `combined_identity_ok_rows=10`, `backfill_source_ok_rows=10`, and
  `all_post_apply_checks_ok=true`.
- Auditor Central independent planner recheck at `2026-06-20 06:43 -0300`:
  `status=PASS`, `planned_row_count=0`, `planned_rows=[]`,
  `db_mutations=false`.
- Learned-deck coherence audit post-apply result:
  `partner_identity_not_modeled=10` remains. This is classified as inferred
  auditor residual, not apply failure: current audit code still emits
  `partner_identity_not_modeled` from derived partner/off-color inference and
  does not check whether `commander_learned_decks.metadata.commander_identity_model`
  now matches the persisted model. Direct PostgreSQL validation and the planner
  both confirm persistence is complete for the 10 planned rows.
- Ajustar Deck audit-code drift closure at `2026-06-20 06:55 -0300`:
  - changed `server/bin/learned_deck_coherence_audit.py` so
    `partner_identity_not_modeled` respects persisted
    `metadata.commander_identity_model`;
  - planner dry-run artifact
    `learned_deck_partner_identity_backfill_plan_20260620_095139_post_pg001_audit_fix.json`
    reports `planned_row_count=0`, `db_mutations=false`, and
    `planned_rows=[]`;
  - learned-deck coherence artifact
    `learned_deck_coherence_audit_20260620_095253.json` reports
    `partner_identity_not_modeled=0`;
  - direct artifact check shows `combined_identity_rows=10`,
    `persisted_matching_rows=10`, `partner_issue_rows=0`, and
    `partner_issue_refs=[]`;
  - no PostgreSQL mutation was executed for this closure.

Planned rows:

| source_ref | row_id | commander | planned combined identity |
| --- | --- | --- | --- |
| `learned_deck:112` | `0d9058af-51f1-4e2c-9dfa-d813880ae91c` | `Akiri, Line-Slinger` | `G,R,U,W` |
| `learned_deck:93` | `b8221a6b-af2b-4f7e-89c3-cea07e2d071f` | `Dargo, the Shipwrecker` | `B,R,W` |
| `learned_deck:110` | `7a7001a1-aebe-4963-830f-31031f92c105` | `Ishai, Ojutai Dragonspeaker` | `R,U,W` |
| `learned_deck:100` | `de69e590-452b-4e2d-bc64-df7145a930f3` | `Jeska, Thrice Reborn` | `B,R,W` |
| `learned_deck:116` | `421b13ef-c325-42e4-821c-8123dea59d15` | `K-9, Mark I` | `G,R,U,W` |
| `learned_deck:173` | `2d18afa2-561b-4c69-ad89-ce4bfb432770` | `Krark, the Thumbless` | `R,U` |
| `learned_deck:89` | `367003b1-36f2-42ec-a015-fa605d0a9b97` | `Kraum, Ludevic's Opus` | `B,R,U,W` |
| `learned_deck:90` | `5e6d0cbe-6b58-4bbd-8f2f-62aa03bf0cd9` | `Malcolm, Keen-Eyed Navigator` | `B,R,U` |
| `learned_deck:85` | `5242b94b-954e-4a32-abc6-8b5fa2a4cabb` | `Rograkh, Son of Rohgahh` | `B,R,U` |
| `learned_deck:87` | `0e37c8b3-f931-47b9-9eec-7d4b755ccd78` | `Thrasios, Triton Hero` | `G,U,W` |

Operator next steps:

1. PG-001 apply is complete; do not re-run apply unless a future SELECT proves a
   partial rollback or data drift.
2. If rollback is approved after apply, execute exactly:
   `cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/learned_deck_partner_identity_backfill_pg001_rollback_20260620_063349.sql`
3. Ajustar Deck audit-code closure is complete. No PG-001 database action remains
   unless a future SELECT proves rollback or data drift.

Post-apply validation target:

- SELECT post-apply: complete, all `10` rows OK.
- Partner identity planner: complete, `planned_row_count=0`.
- Learned-deck coherence audit: rerun complete after audit-code fix;
  `partner_identity_not_modeled=0`, and persisted metadata matches the derived
  model for all `10` combined identity rows.

### PG-002 - Global learned-deck metadata canonicalization

Status: `applied_validated`

Evidence:

- Current read-only audit stdout and
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_095253.json`
  report `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
  `all_core_metadata_zero=54`, and `some_core_metadata_zero=4`.
- Auditor Central improved the canonicalizer tooling without changing the
  default no-write behavior:
  - `--offset=<N>` for chunked dry-runs;
  - `--progress` for row-level progress in stderr;
  - `--include-full-metadata` for rollback package evidence;
  - database connection logs are routed away from stdout so JSON can be parsed.
- Tooling validation:
  - `cd server && dart analyze bin/canonicalize_learned_deck_metadata.dart test/canonicalize_learned_deck_metadata_cli_test.dart`
    returned no issues;
  - `cd server && dart test test/canonicalize_learned_deck_metadata_cli_test.dart -r expanded`
    returned `3/3` tests passed.
- Dry-run artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json`
  reports `status=PASS`, `mode=dry_run`, `db_mutations=false`,
  `chunk_count=6`, `checked=60`, `reported=60`, `changed=59`, and
  `applied=0`.
- `learned_deck:82` / `Lorehold, the Historian` remains unchanged in PG-002:
  `changed=false`, selected metadata before/after both
  `total_lands=33`, `ramp_count=20`, `draw_count=18`, `engine_count=37`,
  `protection_count=13`.
- SQL package:
  - `learned_deck_metadata_canonicalization_pg002_precheck_20260620_0718.sql`
  - `learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql`
  - `learned_deck_metadata_canonicalization_pg002_rollback_20260620_0718.sql`
  - `learned_deck_metadata_canonicalization_pg002_postcheck_20260620_0718.sql`
- Package report:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md`.
- SELECT-only precheck result:
  `expected_rows=59`, `matched_rows=59`, `before_matches=59`,
  `already_after_rows=0`, `would_change_rows=59`, `active_matches=59`.
- Auditor Central package reconciliation at `2026-06-20 08:26 -0300`:
  dry-run artifact has `60` total results and `59` `changed=true` rows;
  precheck/apply/rollback/postcheck SQL each contain the same `59` unique
  `(row_id, source_ref)` pairs; all `59` pairs match the dry-run `changed=true`
  set; live SELECT-only precheck still returns `before_matches=59`,
  `would_change_rows=59`, and `active_matches=59`.

Apply status:

- Applied at `2026-06-20 08:32 -0300` in this Auditor Central thread after the
  same-cycle precheck still returned `expected_rows=59`, `matched_rows=59`,
  `before_matches=59`, `already_after_rows=0`, `would_change_rows=59`, and
  `active_matches=59`.
- Apply command:
  `cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_apply_20260620_0718.sql`
- Apply result: `UPDATE 59`, `COMMIT`.
- Postcheck result:
  `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`,
  `all_post_apply_checks_ok=true`.
- Learned-deck coherence audit after apply:
  `active_learned_decks=60`, `commander_deck_quantity_mismatch=1`,
  `commander_quantity_mismatch=1`, `land_count_high_review=1`,
  `land_count_low_review=7`, `some_core_metadata_zero=5`; severity now
  `high=2`, `medium=13`.
- Heartbeat full-artifact recheck at `2026-06-20 08:59 -0300` generated
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`
  and `.md`; it confirms current aggregate
  `metadata_total_lands_mismatch=0`, `metadata_zero_lands=0`,
  `all_core_metadata_zero=0`, `partner_identity_not_modeled=0`, `high=2`,
  and `medium=13`.
- `learned_deck:82` / Lorehold remains clean in the new artifact:
  active issues `[]`, metadata `total_lands=33`, derived `total_lands=33`,
  PG saved deck lands `33`, strategy checks pass, and no Premium Mox present.
- Canonicalizer post-apply dry-run:
  `status=PASS`, `mode=dry_run`, `db_mutations=false`, `checked=60`,
  `reported=0`, `changed=0`, `applied=0`.

### PG-003 - Oracle/card text/type backfill

Status: `not_ready`

Evidence:

- Current oracle inventory reports `34,329` cards, `33,966` strict structured,
  and `363` relevant oracle/type gaps.
- Current planner is read-only and has `backfill_ready=0`.
- Recheck `2026-06-20 07:54 -0300`:
  `python3 server/bin/plan_oracle_text_backfill.py --no-scryfall --limit 10`
  returned `status=PASS`, `mode=read_only`, `db_mutations=false`,
  `base_oracle_summary={"total_cards":34329,"missing_any":363,"missing_oracle_id":4,"missing_oracle_text":360}`,
  `planned_items=6`, `deck_card_gap_items=6`, `active_learned_gap_items=0`,
  and `backfill_ready=0`.

Reason not ready:

- Needs policy for official blank oracle text, Arena/Alchemy `A-` identities,
  aliases, and reprints before any PostgreSQL write.

### PG-004 - Battle rule promotion for Leyline of Abundance

Status: `historical_superseded_by_pg007`

Evidence:

- Historical latest battle artifact at this checkpoint was
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005/summary.json`.
- Historical final status was `trusted_for_strategy_learning` because all
  mandatory gates pass.
- Historical forensic lineage was complete:
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_rule_logical_key_missing_unaccepted=0`,
  `forensic_card_id_missing_unaccepted=0`, and
  `forensic_semantic_hash_missing_unaccepted=0`.
- Runtime surface manifest was updated and validated with total files `110`;
  the previously unclassified learned-deck planner files are now classified as
  `learned-deck source`.
- This section was superseded by the later `2026-06-20 10:22 -0300`
  `20260620_125745` forensic finding and the `2026-06-20 10:31 -0300`
  PG-007 apply/postcheck/runtime-sync closure. The current active Leyline state
  is documented in the PG-007 queue section above.

Current action:

- Do not use this historical PG-004 section to decide current deploy state.
- Keep PG-007 closed unless future SELECT, sync, or battle-artifact evidence
  proves rollback or drift.

### PG-005 - Lorehold critical role/function/semantic rows

Status: `already_present_no_apply_needed`

Evidence:

- `python3 -m py_compile server/bin/plan_lorehold_critical_role_backfill.py server/bin/plan_oracle_text_backfill.py server/bin/plan_learned_deck_partner_identity_backfill.py`
  returned PASS.
- `python3 -m unittest server/test/plan_lorehold_critical_role_backfill_test.py server/test/plan_oracle_text_backfill_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py`
  returned `7` tests passed.
- `python3 server/bin/plan_lorehold_critical_role_backfill.py --dry-run`
  returned `status=PASS`, `mode=dry_run`, `db_mutations=false`, and
  `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`.
- The same dry-run reported `counts_before` equal to `counts_after`:
  `existing_commander_synergy_rows=5`, `existing_function_tag_rows=11`,
  and `existing_semantic_v2_rows=4`.

### PG-006 - card_battle_rules execution_status migration drift

Status: `applied_validated`

Source front: Auditor Central / Battle data governance
Target table: `card_battle_rules`
Target column: `execution_status`
Mutation type: status normalization plus missing migration/constraint record
Apply authorized: `true`
DB mutations executed by this register: `true`

Evidence:

- `cd server && set -a && source .env && set +a && dart run bin/migrate.dart --status`
  reports `029 add_card_battle_rules_execution_status` as pending.
- Live read-only PostgreSQL inspection at `2026-06-20 08:08 -0300`:
  - `card_battle_rules.execution_status` exists, is `NOT NULL`, and has
    default `'auto'::text`;
  - `card_battle_rules.logical_rule_key` exists and is `NOT NULL`;
  - `chk_card_battle_rules_execution_status` is missing;
  - `schema_migrations.version='029'` is not recorded.
- Live read-only row counts:
  - `cards=34329`;
  - `card_intelligence_snapshot=34329`;
  - `card_identity_bridge=305905`;
  - active `commander_learned_decks=60`.
- `card_battle_rules` source/review/execution distribution before apply:
  - `curated / active / auto = 26`;
  - `curated / verified / auto = 1725`;
  - `generated / needs_review / auto = 1970`;
  - `generated / needs_review / review_only = 1467`.
- PG-006 precheck:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`
  returned `migration_029_recorded=false`, no execution-status constraint row,
  `pg006_rows_to_normalize=1970`,
  `card_intelligence_snapshot_view.mentions_execution_status=false`, and
  `optimize_candidate_quality_summary_view.mentions_execution_status=false`.
- Migration 029 source in `server/bin/migrate.dart` only updates rows where
  `execution_status IS NULL OR execution_status = ''`. Because the current
  drift rows are already `auto`, running the native migration alone would not
  normalize the `1970` `generated/needs_review/auto` rows.
- Current backend source defines `card_intelligence_snapshot.battle_rules` JSON
  with `execution_status`, so PG-006 apply also refreshes
  `card_intelligence_snapshot` and `optimize_candidate_quality_summary` before
  recording migration `029`.
- Auditor Central source/package comparison at `2026-06-20 08:21 -0300`:
  - `optimizeCandidateQualitySummaryViewStatement`: `MATCH`;
  - `cardIntelligenceSnapshotViewStatement`: `MATCH`;
  - source and apply both contain `4` `execution_status` occurrences in
    `cardIntelligenceSnapshotViewStatement`.
- Heartbeat SELECT-only precheck re-run at `2026-06-20 08:28 -0300`:
  - `migration_029_recorded=false`;
  - `execution_status` column remains `NOT NULL` with default `'auto'::text`;
  - `chk_card_battle_rules_execution_status` still absent;
  - `execution_status_counts`: `auto=3721`, `review_only=1467`;
  - `generated / needs_review / auto=1970`;
  - `pg006_rows_to_normalize=1970`;
  - live `card_intelligence_snapshot` and
    `optimize_candidate_quality_summary` views still do not mention
    `execution_status`;
  - transaction ended with `ROLLBACK`; no PostgreSQL mutation was performed.
- Pre-sync battle summary `20260620_115516` still reported
  `execution_status_counts={"auto":3159}`, `needs_review_rule_names=1457`,
  `review_only_rule_names=0`, and `review_only_rule_instances=0`; this was
  treated as a separate artifact/runtime scope discrepancy, not proof that
  PostgreSQL was dirty.

SQL package:

- Package report:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md`
- Precheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_precheck_20260620_0808.sql`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_rollback_20260620_0808.sql`
- Postcheck SQL:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_postcheck_20260620_0808.sql`
- Rollback boundary: restores row values, drops the PG-006 check constraint,
  and removes the migration `029` record; it intentionally does not revert the
  refreshed view definitions because current backend source expects
  `execution_status` inside `card_intelligence_snapshot.battle_rules`.

Apply status:

- Applied at `2026-06-20 08:30 -0300` in this Auditor Central thread after the
  same-cycle precheck still returned `migration_029_recorded=false`,
  `pg006_rows_to_normalize=1970`, no
  `chk_card_battle_rules_execution_status`, and live views without
  `execution_status`.
- Apply command:
  `cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_apply_20260620_0808.sql`
- Apply result: `COMMIT`; rollback backup inserted `1970` rows into
  `manaloom_deploy_audit.pg006_card_battle_rules_execution_status_20260620_0808`;
  `normalized_rows=1970`; migration `029` inserted.
- Postcheck result:
  `migration_029_status` present, `execution_status` column `NOT NULL` with
  default `'auto'::text`, `chk_card_battle_rules_execution_status` present,
  `execution_status_counts={"auto":1751,"review_only":3437}`,
  `generated / needs_review / review_only = 3437`,
  `remaining_needs_review_not_review_only=0`,
  `rollback_backup_rows=1970`,
  `card_intelligence_snapshot_view.mentions_execution_status=true`.
- `dart run bin/migrate.dart --status` after apply reports all `29/29`
  migrations executed and `0` pending.
- Battle recurring audit after the runtime-surface manifest fix completed at
  run `20260620_115516`: `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, and `test_results_total=16` with all tests
  passing.
- Runtime cache reconciliation executed at `2026-06-20 09:09 -0300` using
  `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`.
  This did not write PostgreSQL (`apply_pg=false`), loaded `5188` PG rules,
  updated `5106` SQLite rows, and exported `3159` canonical fallback names.
- Post-sync effect audit reports
  `execution_status_counts={"auto":1702,"review_only":1457}`,
  `needs_review_rule_names=1457`, and `review_only_rule_names=1457`.
- Full recurring battle audit after the runtime cache sync updated latest to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `test_results_total=16`, and
  `execution_status_counts={"auto":1702,"review_only":1457}`.

Operator next steps:

1. Do not re-run PG-006 apply unless a future SELECT proves rollback or data
   drift.
2. Keep the PG-006 rollback package only as emergency rollback evidence.
3. Keep PG-006 separate from PG-004: this normalizes execution governance for
   existing PostgreSQL rules. The latest battle artifact now closes the
   forensic lineage blocker and the Hermes runtime cache now exposes
   `review_only` names after the PG -> SQLite sync.

Conclusion:

- PG-006 is applied and validated in PostgreSQL.
- No separate Leyline rule-promotion PostgreSQL package exists or is needed from
  the latest trusted battle run.

## PostgreSQL Queue Heartbeat - 2026-06-20 11:19 -0300

Scope:

- Rechecked deploy queue in read-only/dry-run mode after latest battle moved to
  `20260620_140016`.
- No PostgreSQL write was performed in this heartbeat.
- No deck swap, cleanup, stash, revert, stage, commit, or push was performed.

Evidence:

- `cd server && dart run bin/migrate.dart --status`:
  `29/29` migrations executed, `0` pending.
- PG-001 partner/background identity planner:
  `status=PASS`, `planned_row_count=0`, `db_mutations=false`,
  `apply_supported=false`.
- PG-002 metadata canonicalization postcheck:
  `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`,
  `all_post_apply_checks_ok=true`.
- PG-003 oracle/card text/type planner:
  `status=PASS`, `mode=read_only`, `missing_any=363`,
  `missing_oracle_id=4`, `missing_oracle_text=360`, `planned_items=6`,
  `backfill_ready=0`, `active_learned_gap_items=0`,
  `scryfall_found=0`, `db_mutations=false`. Scryfall lookup was intentionally
  skipped with `--no-scryfall`.
- PG-005 Lorehold critical role/function/semantic planner:
  `status=PASS`, `mode=dry_run`, `db_mutations=false`,
  `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`,
  existing rows remain `commander_synergy=5`, `function_tag=11`,
  `semantic_v2=4`.
- PG-006 execution-status postcheck:
  migration `029` present, `execution_status` column `NOT NULL` with default
  `'auto'::text`, `chk_card_battle_rules_execution_status` present,
  `execution_status_counts={"auto":1752,"review_only":3437}`,
  `remaining_needs_review_not_review_only=0`, rollback backup rows `1970`,
  `card_intelligence_snapshot_view.mentions_execution_status=true`.
- PG-007 Leyline postcheck:
  `pg007_target_rule_count=1`; target row remains
  `normalized_name='leyline of abundance'`,
  `source='curated'`, `review_status='active'`,
  `execution_status='auto'`, `confidence=0.820`; snapshot exposes the battle
  rule.
- Battle artifact at that 11:19 heartbeat:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_140016/summary.json`
  reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic lineage complete, and tests
  `16/16` pass.

Conclusion:

- No new PostgreSQL apply is ready at this heartbeat.
- PG-001, PG-002, PG-006, and PG-007 remain closed unless future
  SELECT/artifact evidence proves rollback or drift.
- PG-003 remains policy-blocked; PG-005 remains no-apply-needed.

## PostgreSQL Queue Heartbeat - 2026-06-20 11:35 -0300

Scope:

- Rechecked deploy queue in read-only/dry-run mode after the worktree ownership
  coverage audit.
- No PostgreSQL write was performed in this heartbeat.
- No deck swap, cleanup, stash, revert, stage, commit, or push was performed.

Evidence:

- `cd server && dart run bin/migrate.dart --status`:
  `29/29` migrations executed, `0` pending.
- PG-001 partner/background identity planner:
  `status=PASS`, `planned_row_count=0`, `db_mutations=false`,
  `apply_supported=false`.
- PG-002 metadata canonicalization postcheck:
  `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`,
  `all_post_apply_checks_ok=true`.
- PG-003 oracle/card text/type planner:
  `status=PASS`, `mode=read_only`, `missing_any=363`,
  `missing_oracle_id=4`, `missing_oracle_text=360`, `planned_items=6`,
  `backfill_ready=0`, `active_learned_gap_items=0`,
  `scryfall_found=0`, `db_mutations=false`. Scryfall lookup was intentionally
  skipped with `--no-scryfall`.
- PG-005 Lorehold critical role/function/semantic planner:
  `status=PASS`, `mode=dry_run`, `db_mutations=false`,
  `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`,
  existing rows remain `commander_synergy=5`, `function_tag=11`,
  `semantic_v2=4`.
- PG-006 execution-status postcheck:
  migration `029` present, `execution_status` column `NOT NULL` with default
  `'auto'::text`, `chk_card_battle_rules_execution_status` present,
  `execution_status_counts={"auto":1752,"review_only":3437}`,
  `remaining_needs_review_not_review_only=0`, rollback backup rows `1970`,
  `card_intelligence_snapshot_view.mentions_execution_status=true`.
- PG-007 Leyline postcheck:
  `pg007_target_rule_count=1`; target row remains
  `normalized_name='leyline of abundance'`,
  `source='curated'`, `review_status='active'`,
  `execution_status='auto'`, `confidence=0.820`; snapshot exposes the battle
  rule.
- Battle runtime manifest still passes separately:
  `total_files=110`, `unclassified_files=[]`.

Conclusion:

- No new PostgreSQL apply is ready at this heartbeat.
- PG-001, PG-002, PG-006, and PG-007 remain closed unless future
  SELECT/artifact evidence proves rollback or drift.
- PG-003 remains policy-blocked; PG-005 remains no-apply-needed.

## Deploy History

| time | item | action | approval | db_mutations | result |
| --- | --- | --- | --- | --- | --- |
| `2026-06-20 06:24 -0300` | register init | Created deploy register and queue from current artifacts. | none | `false` | No PostgreSQL write performed. |
| `2026-06-20 06:33 -0300` | `PG-001` | Prepared DBA package for partner/background identity metadata backfill. Ran SELECT-only precheck and generated apply, rollback, precheck, and postcheck SQL files. Proposed apply command is documented in PG-001 next steps. | none; apply still blocked pending explicit Rafael/Auditor Central approval | `false` | Ready for approval: 10/10 live rows matched by `id + source_ref`; 10/10 need metadata update; 0/10 already persisted. |
| `2026-06-20 06:39 -0300` | `PG-001` | Applied partner/background identity metadata backfill to `commander_learned_decks.metadata` using the approved SQL package. | Rafael chat approval: `esta autorizado faca` | `true` | Apply committed `10` rows. Postcheck passed `10/10`. Planner now returns `planned_row_count=0`. Coherence audit still reports `partner_identity_not_modeled=10`, documented as auditor residual because direct PG validation confirms all 10 persisted models match the plan. |
| `2026-06-20 06:43 -0300` | `PG-001` | Auditor Central independently reran SELECT-only postcheck and partner planner dry-run after the DBA apply. | n/a | `false` | Confirmed `all_post_apply_checks_ok=true` and planner `planned_row_count=0`; PG-001 remains applied/validated and must not be re-applied. |
| `2026-06-20 06:55 -0300` | `PG-001` | Ajustar Deck fixed the learned-deck coherence audit residual metric and reran planner/audit read-only. | n/a | `false` | Planner artifact reports `planned_row_count=0`; new coherence artifact reports `partner_identity_not_modeled=0`; no PG-001 database action remains. |
| `2026-06-20 07:06 -0300` | single-operator control | Auditor Central validated the audit-code closure directly and switched deploy ownership to this thread. | n/a | `false` | `21` Python tests passed; partner planner returned `planned_row_count=0`; compact coherence audit showed the real remaining backlog is PG-002 metadata canonicalization, not PG-001. |
| `2026-06-20 07:37 -0300` | `PG-002` | Prepared row-by-row dry-run artifact and SQL package for global learned-deck metadata canonicalization. Ran SELECT-only precheck. | pending exact Rafael approval | `false` | Package has `59` active rows; precheck passed `matched_rows=59`, `before_matches=59`, `would_change_rows=59`, `already_after_rows=0`; apply is ready for approval but not executed. |
| `2026-06-20 07:48 -0300` | `PG-004` | Reconciled battle latest `090636` against the validation register. | n/a | `false` | Battle remains `review_required` by `forensic_audit`; `Leyline of Abundance` via `functional_tags_json` may later require DB-backed rule promotion, but there is no approved design, precheck, apply, rollback, or postcheck package yet. |
| `2026-06-20 07:54 -0300` | `PG-003` / `PG-005` | Ran read-only oracle planner and dry-run Lorehold critical-role planner. | n/a | `false` | Oracle backlog remains `not_ready` with `backfill_ready=0`; Lorehold critical role/function/semantic rows are already present, with `counts_before` equal to `counts_after` and `applied_counts=0`. |
| `2026-06-20 08:21 -0300` | `PG-006` | Revalidated migration status and precheck read-only, and compared PG-006 view SQL against the current Dart source constants. | pending exact Rafael approval | `false` | Migration `029` remains pending; PG-006 precheck still reports `pg006_rows_to_normalize=1970`; live views still do not mention `execution_status`; package view SQL matches current backend source. |
| `2026-06-20 08:26 -0300` | `PG-002` | Reconciled dry-run artifact against precheck/apply/rollback/postcheck SQL and reran SELECT-only precheck. | pending exact Rafael approval | `false` | Dry-run has `59` changed rows; every SQL package file carries the same `59` `(row_id, source_ref)` pairs; live precheck remains `matched_rows=59`, `before_matches=59`, `would_change_rows=59`. |
| `2026-06-20 08:28 -0300` | `PG-006` | Heartbeat reran PG-006 SELECT-only precheck after detecting the package-ready queue state. | pending exact Rafael approval | `false` | Confirmed migration `029` is still unrecorded, constraint still absent, `pg006_rows_to_normalize=1970`, and live views still do not mention `execution_status`; transaction rolled back. |
| `2026-06-20 08:30 -0300` | `PG-006` | Applied `card_battle_rules.execution_status` governance package after Rafael switched this thread to single-operator deploy ownership. | Rafael chat approval: `faca tudo, faca deploy, suba em banco` | `true` | `COMMIT`; `normalized_rows=1970`; rollback backup rows `1970`; migration `029` recorded; postcheck passed with `remaining_needs_review_not_review_only=0`; migration status now `29/29` executed. |
| `2026-06-20 08:32 -0300` | `PG-002` | Applied global learned-deck metadata canonicalization package. | Rafael chat approval: `faca tudo, faca deploy, suba em banco` | `true` | `UPDATE 59`, `COMMIT`; postcheck passed with `after_matches=59`, `still_before_rows=0`, `all_post_apply_checks_ok=true`; canonicalizer dry-run after apply returned `changed=0`, `applied=0`, `db_mutations=false`. |
| `2026-06-20 08:48 -0300` | battle validation | Reran full recurring battle audit after PG-006; first run exposed stale runtime-surface manifest denominator, then the manifest classifier/test were updated for two learned-deck planner files and the full audit was rerun. | n/a | `false` | Latest artifact now points to `20260620_115516`; `battle_replay_final_status=trusted_for_strategy_learning`; `16/16` tests pass; `forensic_lineage_status=complete`; runtime-surface manifest total is `110`. |
| `2026-06-20 08:59 -0300` | learned-deck audit | Heartbeat generated a fresh full read-only coherence artifact after PG-002 apply. | n/a | `false` | `learned_deck_coherence_audit_20260620_115918` confirms PG-002 metadata backlog closure: `metadata_total_lands_mismatch=0`, `metadata_zero_lands=0`, `all_core_metadata_zero=0`, and `partner_identity_not_modeled=0`; residual learned-deck issues are limited to quantity/commander mismatch, land-count review, and `some_core_metadata_zero=5`. |
| `2026-06-20 09:10 -0300` | PG-006 runtime cache sync | Backed up local Hermes `knowledge.db`, mirrored PostgreSQL battle rules into SQLite with `--apply-sqlite-from-pg --include-needs-review`, exported canonical fallback snapshot, reran effect coverage, and reran the full recurring battle audit. | Rafael single-operator command: `faca tudo, faca deploy, suba em banco` | `false` for PostgreSQL; `true` for local SQLite cache | Sync report: `apply_pg=false`, `pg_rows_loaded=5188`, `sqlite_inserted_or_updated=5106`, `canonical_snapshot_rows_exported=3159`. Latest artifact now points to `20260620_121005`; `battle_replay_final_status=trusted_for_strategy_learning`; `16/16` tests pass; `execution_status_counts={"auto":1702,"review_only":1457}`. |
| `2026-06-20 09:24 -0300` | PostgreSQL queue heartbeat | Reran current read-only planners/postchecks for PG-001/PG-002/PG-003/PG-005 and direct SELECTs for PG-006. | n/a | `false` | PG-001 planner `planned_row_count=0`; PG-002 postcheck `all_post_apply_checks_ok=true`; PG-003 still `backfill_ready=0`; PG-005 dry-run `applied_counts=0`; PG-006 still `auto=1751`, `review_only=3437`, remaining generated needs-review not-review-only `0`, migration `029=1`. |
| `2026-06-20 09:36 -0300` | PostgreSQL/latest heartbeat | Reran migration status and current battle latest after documentation contradiction audit. | n/a | `false` | Migration status remains `29/29` executed and `0` pending. Latest battle remains `20260620_121005`, `trusted_for_strategy_learning`, `16/16` tests pass, and runtime execution-status counts are `auto=1702`, `review_only=1457`. |
| `2026-06-20 10:31 -0300` | `PG-007` + battle validation | Applied Leyline battle-rule lineage package, postchecked PostgreSQL, backed up and refreshed Hermes SQLite from PostgreSQL, generated post-sync coverage, and reran the full recurring battle audit. | Rafael single-operator command: `faca tudo, faca deploy, suba em banco` | `true` for PostgreSQL; `true` for local SQLite cache | Apply `INSERT 0 1`, `COMMIT`; postcheck `pg007_target_rule_count=1`; sync `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107`, `canonical_snapshot_rows_exported=3160`; latest artifact now points to `20260620_132812`, `battle_replay_final_status=trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`, forensic lineage complete, and tests `16/16` pass. |
| `2026-06-20 10:50 -0300` | PostgreSQL queue heartbeat | Reran migration status, PG-001 planner, PG-002 postcheck, PG-003 oracle planner, PG-005 Lorehold dry-run, PG-007 postcheck, and latest battle summary read-only after aggregate source validation. | n/a | `false` | Migrations remain `29/29` executed and `0` pending; PG-001 `planned_row_count=0`; PG-002 `all_post_apply_checks_ok=true`; PG-003 `backfill_ready=0`; PG-005 `applied_counts=0`; PG-007 `pg007_target_rule_count=1`; latest battle remains `20260620_132812`, trusted, with `16/16` tests pass. No current PostgreSQL apply is ready. |
| `2026-06-20 10:57 -0300` | Deploy-register docs reconciliation | Relabeled the older PG-004 / `20260620_121005` section as historical and superseded by PG-007 after rereading latest battle and control docs. | n/a | `false` | No deploy action. Current Leyline state remains PG-007 applied/validated/runtime-synced; no current PostgreSQL apply is ready. |
| `2026-06-20 11:19 -0300` | PostgreSQL queue heartbeat | Reran migration status, PG-001 planner, PG-002 postcheck, PG-003 oracle planner, PG-005 Lorehold dry-run, PG-006 postcheck, PG-007 postcheck, runtime surface manifest, and latest battle summary read-only after single-operator source-slice audits. | n/a | `false` | Migrations remain `29/29` executed and `0` pending; PG-001 `planned_row_count=0`; PG-002 `all_post_apply_checks_ok=true`; PG-003 `backfill_ready=0`; PG-005 `applied_counts=0`; PG-006 `remaining_needs_review_not_review_only=0`; PG-007 `pg007_target_rule_count=1`; latest battle is `20260620_140016`, trusted, with `16/16` tests pass. No current PostgreSQL apply is ready. |
| `2026-06-20 11:35 -0300` | PostgreSQL queue heartbeat | Reran migration status, PG-001 planner, PG-002 postcheck, PG-003 oracle planner, PG-005 Lorehold dry-run, PG-006 postcheck, PG-007 postcheck, and battle runtime manifest read-only after worktree ownership coverage audit. | n/a | `false` | Migrations remain `29/29` executed and `0` pending; PG-001 `planned_row_count=0`; PG-002 `all_post_apply_checks_ok=true`; PG-003 `backfill_ready=0`; PG-005 `applied_counts=0`; PG-006 `remaining_needs_review_not_review_only=0`; PG-007 `pg007_target_rule_count=1`; battle runtime manifest has `110` files and `0` unclassified. No current PostgreSQL apply is ready. |
| `2026-06-20 12:14 -0300` | `PG-008` + battle validation | Applied Machine God's Effigy battle-rule lineage package after latest battle `20260620_150241` exposed a `functional_tags_json` forensic blocker; postchecked PostgreSQL, backed up and refreshed Hermes SQLite from PostgreSQL, exported canonical fallback, and reran full recurring battle audit. | Rafael single-operator authorization for database deploy and validation in this thread | `true` for PostgreSQL; `true` for local SQLite cache | Apply `INSERT 0 1`, `COMMIT`; postcheck `pg008_target_rule_count=1`; sync `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108`, `canonical_snapshot_rows_exported=3161`; latest artifact now points to `20260620_151437`, `battle_replay_final_status=trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`, forensic lineage complete, and tests `16/16` pass. |
| `2026-06-20 12:26 -0300` | Final single-operator organization heartbeat | Reran worktree whitespace check, untracked duplicate hash scan, migration status, latest battle summary read, HEAD/origin check, and stale-current-doc scan after PG-008 docs reconciliation. | n/a | `false` | `git diff --check` clean; untracked duplicate scan `NO_DUPLICATE_UNTRACKED_HASHES`; migrations remain `29/29` executed and `0` pending; latest battle remains `20260620_151437`, trusted, with `mandatory_gate_divergences=[]`, forensic lineage complete, and tests `16/16` pass. No current PostgreSQL apply is ready. |
| `2026-06-20 12:58 -0300` | Publication-batch validation heartbeat | Reran aggregate app/backend tests, Python discover, migration status, PG-008 postcheck, runtime-surface manifest test, public health check, and fresh 16-seed battle audit. Added publication batch plan and ignored local SQLite `.bak` backups while preserving them on disk. | n/a | `false` | `flutter analyze` clean; `flutter test` `619/619`; `dart analyze` clean; `dart test` `634/634`; Python discover `96/96`; migrations `29/29`; PG-008 target rule count `1`; fresh battle latest `20260620_155445` is trusted with `mandatory_gate_divergences=[]`. No current PostgreSQL apply is ready. |
| `2026-06-20 13:12 -0300` | Batch 0/1 readiness heartbeat | Re-read live latest battle and worktree state before preparing audit/publication batches 0 and 1. | n/a | `false` | Latest battle now points to `20260620_160459`, still `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`, complete forensic lineage, and tests `16/16`; `git diff --check` clean; worktree checkpoint `73` tracked modified, `75` untracked, shortstat `73 files changed, 24752 insertions(+), 2022 deletions(-)`. No current PostgreSQL apply is ready. |
| `2026-06-20 13:28 -0300` | Publication branch reconciliation heartbeat | Re-read Git state, central registers, Lorehold register, latest learned-deck coherence artifact, and latest battle summary after the workspace moved to `codex/manaloom-batches-20260620`. | n/a | `false` | Working tree is clean (`git status --porcelain=v1` count `0`) and aligned with upstream (`HEAD...@{upstream}` = `0 0`); branch contains publication commits `9ffe002b`, `7310111f`, `764a3255`, and `ca939026`; learned-deck audit remains `20260620_115918` with Lorehold `learned_deck:82` issues `[]`; latest battle remains `20260620_160459`, trusted, with `mandatory_gate_divergences=[]` and tests `16/16`. This heartbeat performed no PostgreSQL write, deck swap, cleanup, stage, commit, or push. No current PostgreSQL apply is ready. |
| `2026-06-20 13:31 -0300` | Master migration and production deploy verification | Fast-forwarded `master` to the publication branch, pushed `master`, and verified public health after deploy. | Rafael requested migration to avoid losing the branch work | `false` for PostgreSQL | `master` moved `3908e88c..ca939026`; `origin/master` now equals local `HEAD`; production `/health` reports `git_sha=ca93902621728baefd0715f11fecccd0bfd62f03` and `status=healthy`; untracked non-ignored files remain `0`. No current PostgreSQL apply is ready. |
| `2026-06-20 13:33 -0300` | Lorehold monitor documentation reconciliation | Rechecked post-migration `master`, latest learned-deck audit, latest battle, and public health; marked the 13:28 publication-branch checkpoint as historical/superseded by the 13:31 master migration closure. | n/a | `false` | Pre-closure `HEAD...origin/master` was `0 0`; production `/health` was healthy; latest learned audit remained `20260620_115918` with Lorehold `learned_deck:82` issues `[]`; latest battle remained `20260620_160459`, trusted, with `mandatory_gate_divergences=[]` and tests `16/16`; only three documentation files were modified by this heartbeat. No PostgreSQL write, deck swap, cleanup, stage, commit, or push was performed. No current PostgreSQL apply is ready. |
| `2026-06-20 13:43 -0300` | Heartbeat loop closure policy | Closed the documentation loop created by tracking exact "current HEAD" in heartbeat docs after a documentation-only deploy verification. | Rafael requested worktree cleanup before the next product cycle | `false` | Stable rule: exact deploy SHA proof remains required for deploy/smoke validation, but tracked heartbeat docs must not recursively restamp the SHA created by the previous heartbeat commit. Future current-state proof should be command evidence or bounded smoke artifacts, not endless tracked doc churn. No PostgreSQL write, deck swap, cleanup of data, or app/backend code change was performed. No current PostgreSQL apply is ready. |
| `2026-06-20 14:24 -0300` | `PG-009` Korvold learned-deck replacement | Replaced the active partial Korvold learned deck row with accepted `commander_reference_decks` corpus data and added runtime guards so product loaders skip incomplete active learned decks. | Rafael active goal authorization for end-to-end Korvold cycle and PostgreSQL deploy with gates | `true` for PostgreSQL | Precheck passed: old partial active `1`, replacement source `1`, source quantity `100`, commander quantity `1`, unresolved `0`, off-color `0`, no existing replacement row. First apply deactivated old `edhrec/learned_deck:7` and inserted replacement. Reapply updated canonical metadata counters. Postcheck passed: exactly one active Korvold row, `source_system=commander_reference_decks`, source ref `edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14`, `card_count=100`, parsed quantity `100`, commander quantity `1`, old partial active `0`. Fresh coherence artifact `learned_deck_coherence_audit_20260620_172437` shows Korvold `issues=[]` and global `severity_counts={"medium":13}` with no high findings. |
| `2026-06-20 14:28 -0300` | Latest battle review regression | Rechecked latest battle after PG-009 closure and learned-deck artifact `20260620_172437`. | n/a | `false` | Latest battle moved to `20260620_170724` and is `review_required` with mandatory divergences `forensic_audit=review_required` and `replay_decision_audit=review_required`; tests still pass `16/16`, forensic lineage is complete, `forensic_rule_findings=0`, and `decision_audit_decision_findings=0`. The concrete finding is seed `63211720`, turn `12`, player `Lorehold`, event `board_wipe_resolved`, severity `low`: protected creatures `5` versus destroyed `3`. This is battle/auditor follow-up, not a PostgreSQL apply or deck swap. PG-001, PG-002, PG-006, PG-007, PG-008, and PG-009 remain closed unless future evidence proves rollback or drift. No current PostgreSQL apply is ready. |
| `2026-06-20 15:15 -0300` | Lorehold canonical Wheel apply | Applied the documented Lorehold canonical decision `Wheel of Misfortune` over `Reforge the Soul` to the materialized PG deck and active learned deck, then synced Hermes deck `6` and reran learned-deck/battle validation. | documented approved canonical Lorehold decision | `true` for PostgreSQL; `true` for local SQLite cache | Apply artifact `pg_apply_lorehold_wheel_swap_result_20260620_180448.json` shows materialized deck `wheel=1`, `reforge=0`, `rows=100`, `total_cards=100`, and active learned deck `has_wheel=true`, `has_reforge=false`, metadata `canonical_lorehold_swap_20260620`; learned-deck audit `20260620_181429` keeps Lorehold `issues=[]`; latest battle `20260620_181004` is `trusted_for_strategy_learning` with `mandatory_gate_divergences=[]`, forensic/decision/action findings `0`, and tests `16/16`. |
| `2026-06-20 15:28 -0300` | Lorehold canonical Wheel reconciliation heartbeat | Re-read Git state, central registers, Lorehold register, latest learned-deck coherence artifact, Wheel apply artifacts, quality gate, and current battle latest after the Wheel apply. | n/a | `false` | Worktree started clean on `master...origin/master`; current battle latest resolves to `20260620_181004` and is trusted with all mandatory gates pass; the old `20260620_170724` board-wipe finding is historical/superseded. No new PostgreSQL write, deck swap, cleanup, stage, commit, or push was performed. No current PostgreSQL apply is ready. |
| `2026-06-20 16:00 -0300` | Battle target-pressure validation | Corrected the battle methodology so Lorehold deck evaluation forces opponent combat/removal pressure onto Lorehold and added target-pressure as a mandatory recurring battle gate. | n/a | `false` for PostgreSQL | Latest battle now resolves to `20260620_185748`, is `trusted_for_strategy_learning`, has `mandatory_gate_divergences=[]`, tests `17/17`, and target-pressure evidence `117/117` opponent combats into Lorehold with `0` opponent combats into other defenders and `0` findings. No current PostgreSQL apply is ready. |
| `2026-06-20 16:30 -0300` | Battle runtime review-only suppression | Latest official battle drifted to `20260620_191248` blocked by seed `63211917`, where `Goblin Bombardment` executed a `needs_review` / `review_only` canonical snapshot rule as `remove_creature`. Runtime fallback now suppresses non-runtime-safe snapshot rules to passive provenance and a focused regression/auditors passed. | n/a | `false` for PostgreSQL | Evidence: latest summary has `forensic_audit=blocked`, `action_critic=review_required`, `replay_decision_audit=review_required`, while target-pressure remains pass `16/16`; `test_battle_analyst_v10_3.py`, `test_battle_target_pressure_audit.py`, `py_compile`, and `/tmp/lorehold_seed63211917_post_review_only_fix.*` focused auditors are clean. Official full rerun still pending before `latest` is green again. |
| `2026-06-20 16:50 -0300` | Battle target-pressure false-positive closure + PG-010 candidate classification | Reran full recurring battle after the Goblin review-only fix and target-pressure post-target-elimination audit fix. | n/a | `false` for PostgreSQL | Latest battle now resolves to `20260620_195007`, still `blocked` but with target-pressure pass `16/16`, `193/193` opponent combats into Lorehold, `0` into other defenders, and `action_findings=0`. Remaining blockers are `functional_tags_json` card-rule lineage for learned-opponent cards and one low board-wipe review finding. No PostgreSQL apply is approved or executed. |
| `2026-06-20 17:06 -0300` | Battle table-intent metadata false-positive closure + latest full blocker classification | Accepted `table_intent_*` target reasons as valid target-pressure metadata when Lorehold is the active evaluation target, reran focused seed `63213000`, and then reran the full recurring battle audit. | n/a | `false` for PostgreSQL | Focused latest `20260620_200322` is trusted with `mandatory_gate_divergences=[]`, target-pressure pass `1/1`, forensic `0`, decision `0`, action `0`, and tests `18/18`. Latest full `20260620_200409` remains `blocked` with `mandatory_gate_divergences=["forensic_audit=blocked","table_intent=blocked"]`; remaining blockers are `Woodland Bellower` and `Shantotto, Tactician Magician` via `functional_tags_json`, table-intent `opponent_interaction_absent` on seeds `63212004`, `63212009`, `63212019`, and one target-pressure split attack on seed `63212012`. No PostgreSQL apply is approved or executed. |
| `2026-06-20 17:39 -0300` | Battle target-pressure mandatory-wrapper reconciliation | Reaudited `20260620_202211` event-contract with current code, fixed the local recurring wrapper to include `target_pressure` in the final-status mandatory gate map, dry-ran the wrapper, and reran full recurring battle. | n/a | `false` for PostgreSQL | Event-contract current-code artifact `/tmp/event_contract_static_202211_current_code.*` is clean; `test_battle_event_contract_static_audit.py` passed `7/7`; wrapper `bash -n` and `--dry-run --seeds 16` passed. Latest full `20260620_203616` remains `blocked` with `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`; table-intent now passes `16/16`; current blockers are forensic `functional_tags_json` lineage and target-pressure attacks away from Lorehold. No PostgreSQL apply is approved or executed. |
| `2026-06-20 17:40 -0300` | Battle latest artifact reconciliation after wrapper dry-run | Re-read the latest artifact generated by the wrapper recheck. | n/a | `false` for PostgreSQL | Latest full `20260620_204002` supersedes `203616` and remains `blocked` with `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`; target-pressure is `{"blocked":2,"pass":14}` with blockers `63212042` and `63212046`; forensic has `21` rule findings on seeds `63212042`, `63212047`, `63212048`, and `63212050`; table-intent/event-contract/replay-decision/action all pass; tests `18/18`. No PostgreSQL apply is approved or executed. |
| `2026-06-20 18:01 -0300` | Round5 artifact detection + latest battle review residual | Re-read latest battle and detected new round5 PG/sync artifacts generated externally before this heartbeat. | not by this heartbeat | `false` by this heartbeat; round5 artifact declares prior `apply_pg=true` | Latest full `20260620_205821` supersedes `204002` and is `review_required` with `mandatory_gate_divergences=["forensic_audit=review_required"]`; target-pressure passes `16/16`; forensic has two low `Goblin Bombardment` passive-vs-remove registry drift findings on seed `63212068`; round5 artifact declares `pg_inserted_or_updated=3` for selected cards `Big Score` and `Spelltwine` plus SQLite sync `pg_rows_loaded=5224`, `sqlite_inserted_or_updated=5142`. This heartbeat did not execute apply/sync and did not reapply anything. |
| `2026-06-20 18:05 -0300` | Round6 artifact detection + latest battle blocker regression | Re-read latest battle and detected new round6 PG/sync artifacts generated externally before this heartbeat finished. | not by this heartbeat | `false` by this heartbeat; round6 artifact declares prior `apply_pg=true` | Latest full `20260620_210513` supersedes `205821` and is `blocked` with `mandatory_gate_divergences=["forensic_audit=blocked"]`; target-pressure passes `16/16`; forensic has `11` rule findings from `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, `The Unagi of Kyoshi Island`, and low `Apex of Power`; round6 artifact declares `pg_inserted_or_updated=2` for selected card `Goblin Bombardment` plus SQLite sync `pg_rows_loaded=5225`, `sqlite_inserted_or_updated=5143`. This heartbeat did not execute apply/sync and did not reapply anything. |
| `2026-06-20 18:12 -0300` | Round7 artifact detection awaiting battle rerun | Rechecked latest after new round7 PG/sync artifacts appeared. | not by this heartbeat | `false` by this heartbeat; round7 artifact declares prior `apply_pg=true` | Round7 artifact declares `pg_inserted_or_updated=6` for selected cards `Apex of Power`, `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, and `The Unagi of Kyoshi Island`; paired SQLite sync declares `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`, `canonical_snapshot_rows_exported=3185`. Latest remained `20260620_210513` after 20s, so a post-round7 battle rerun is still pending. |
| `2026-06-20 18:13 -0300` | Post-round7 latest battle reconciliation | Re-read latest battle after the round7 artifacts. | not by this heartbeat | `false` by this heartbeat; round7 artifacts declare prior `apply_pg=true` and `apply_sqlite_from_pg=true` | Latest full `20260620_211217` supersedes `210513` and is still `blocked` with `mandatory_gate_divergences=["forensic_audit=blocked"]`; target-pressure passes `16/16` with `186` opponent combats into Lorehold, `3` into other defenders, and `0` multi-defender attacks; forensic has `4` rule findings from `Tellah, Great Sage` and `Practical Research` via `functional_tags_json`. The prior round7 blocker set is superseded, but a new opponent-card lineage backlog remains. This heartbeat did not execute apply/sync/rerun and did not reapply anything. |
| `2026-06-20 18:17 -0300` | Latest battle review residual reconciliation | Re-read latest battle after `211217` advanced again. | not by this heartbeat | `false` | Latest full `20260620_211648` supersedes `211217` and is `review_required` with `mandatory_gate_divergences=["forensic_audit=review_required"]`; target-pressure passes `16/16` with `200` opponent combats into Lorehold and `0` into other defenders; forensic has `2` low findings from `Breena, the Demagogue` runtime `passive` vs registry `draw_engine` on seed `63212130`. There is no current high/medium blocker and no PostgreSQL apply is ready. This heartbeat did not execute apply/sync/rerun and did not reapply anything. |
| `2026-06-20 18:27 -0300` | Table-intent real-battle PG/cache closure | Consolidated round5 through round9 battle-rule promotions and the final post-sync recurring battle audit under Rafael's full single-operator authorization. | Rafael authorized this thread to handle PostgreSQL/cache/docs/worktree/commit/push for the functional real-battle cycle | `true` for prior PG rounds; `true` for local SQLite cache sync | Round5 selected `Big Score` and `Spelltwine` with `pg_inserted_or_updated=3`; round6 selected `Goblin Bombardment` with `pg_inserted_or_updated=2`; round7 selected `Apex of Power`, `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, and `The Unagi of Kyoshi Island` with `pg_inserted_or_updated=6`; round8 selected `Practical Research` and `Tellah, Great Sage` with `pg_inserted_or_updated=2`; round9 selected `Breena, the Demagogue` with `pg_inserted_or_updated=2`; final cache sync reports `pg_rows_loaded=5233`, `sqlite_inserted_or_updated=5151`, `canonical_snapshot_rows_exported=3187`, and `curated_rows=104`; latest battle `20260620_212035` is trusted with all mandatory gates pass. |

## Current PostgreSQL Reading - 2026-06-20 18:27 -0300

- PostgreSQL-backed battle-rule promotions through round9 are reflected in the
  local Hermes battle runtime cache.
- Current final cache-sync artifact:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_full_after_table_intent_round9_20260620.json`.
- Current battle gate:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":18}`.
- No additional PostgreSQL write is pending at this exact checkpoint. The next
  database apply should be generated only from a new concrete battle/deck
  blocker with row-level diff, source policy, precheck, apply, rollback,
  postcheck, and runtime evidence.
| `2026-06-20 18:21 -0300` | Latest battle trusted reconciliation | Re-read latest battle after round8/round9 artifacts appeared. | not by this heartbeat | `false` by this heartbeat; round8/round9 artifacts declare prior `apply_pg=true` and `apply_sqlite_from_pg=true` | Latest full `20260620_212035` supersedes `211648` and is `trusted_for_strategy_learning` with `mandatory_gate_divergences=[]`; target-pressure passes `16/16` with `214` opponent combats into Lorehold, `3` into other defenders, and `0` findings; forensic, decision, action, and table-intent findings are `0`; tests pass `18/18`. Round8 declares `pg_inserted_or_updated=2` for `Practical Research` and `Tellah, Great Sage`; round9 declares `pg_inserted_or_updated=2` for `Breena, the Demagogue`. This heartbeat did not execute apply/sync/rerun and no current PostgreSQL apply is ready. |
