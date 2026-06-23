# PostgreSQL Deploy Register - 2026-06-20

Owner: Auditor Central / single operator
Controller: Auditor Central
Status: active register, PG-001, PG-002, PG-006, PG-007, PG-008, PG-009, and
Lorehold canonical Wheel apply applied and validated; PG-006, PG-007, PG-008,
and Lorehold canonical Wheel runtime cache sync completed; PG-003 remains not
ready; PG-005 remains no-apply-needed; PG-011, PG-012, PG-013, and PG-014 are
externally applied, postchecked, runtime-synced, and validated by
`20260620_232534`; PG-015/Wrath is externally applied, postchecked, and
runtime-synced, and later latest official full battle `20260621_000827` is
trusted for strategy learning; Arcane Epiphany remains candidate-only from
superseded blockers; no PostgreSQL apply was executed by this heartbeat

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
- Current official full battle state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221652/summary.json`
  supersedes `212035`; the full run remains
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
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221652/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `forensic_rule_findings=0`, `forensic_turn_findings=0`.
- Table-intent passes in the latest full run:
  `table_intent.statuses={"pass":16}`, `findings=0`.
- Target-pressure passes in the latest full run:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=190`, and
  `target_pressure_opponent_combat_to_other=2`.

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

### PG-011 - Lorehold defense variant

Status: `externally_applied_postchecked_runtime_synced_battle_review_required`
Source front: Lorehold battle optimization variant
Target tables: `deck_cards`, `commander_learned_decks`,
`card_battle_rules`, `card_function_tags`
DB mutations executed by this checkpoint: `false`
Observed PostgreSQL mutations from external state: `true`

Prepared package files detected:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_defense_variant_pg011_package_20260620_193420.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_defense_variant_pg011_precheck_20260620_193420.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_defense_variant_pg011_apply_20260620_193420.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_defense_variant_pg011_rollback_20260620_193420.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_defense_variant_pg011_postcheck_20260620_193420.sql`

Applied deck delta observed by SELECT-only checks:

- Out: `Storm Herd`, `Worldfire`, `Rite of the Dragoncaller`,
  `Fiery Emancipation`, `Mana Geyser`, and `Rise of the Eldrazi`.
- In: `Ghostly Prison`, `Crawlspace`, `Chaos Warp`, `Austere Command`,
  `Get Lost`, and `Professional Face-Breaker`.

Applied battle-rule/function-tag delta observed by SELECT-only checks:

- Promote existing `Crawlspace` rule
  `battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591` to curated verified
  `attack_limit` with `max_attackers_against_you=2`.
- Promote existing `Ghostly Prison` rule
  `battle_rule_v1:99151859bece89ba3ead032e05b1f65a` to curated verified
  `attack_tax` with `attack_tax_per_creature=2`.
- Promote existing `Get Lost` rule
  `battle_rule_v1:8e7da3df51386d58c857a596433f73ea` to curated verified
  `remove_creature`.
- Disable stale generated duplicate rows for those card names.
- Add curated `stax` function tags for `Ghostly Prison` and `Crawlspace`.

Read-only evidence checked in this heartbeat before/around the detected apply:

- Baseline artifact referenced by the package exists:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221318/summary.json`,
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `target_pressure_statuses={"pass":16}`,
  and tests `18/18`.
- Temp variant run exists at
  `/tmp/manaloom_lorehold_variant_b_mE2pHv/run_20260620_192657`.
- Direct `Winner:` line count over the variant replay files produced
  `3` Lorehold wins across the 16 seeds.
- Direct JSONL count over the variant replay events produced
  `combat_with_restrictions=80`, `attackers_restricted=52`, and
  `tax_paid=192`.
- Direct JSONL count over the same run found `Crawlspace` and
  `Ghostly Prison` each cast and resolved `5` times.

Policy classification:

- This heartbeat did not execute the PostgreSQL apply or a manual deck swap
  command, but PostgreSQL SELECTs show the PG-011 target state is already live.
- Do not reapply PG-011.
- Keep the package/sync files as evidence unless Rafael explicitly approves a
  cleanup/stage plan.

Postcheck and sync evidence after detected external apply:

- PG-011 postcheck SQL passed under read-only transaction settings:
  `out_qty_in_target_deck=0`, `in_qty_in_target_deck=6`,
  `target_deck_qty=100`, `target_deck_rows=100`,
  `active_learned_deck_ok=1`.
- PostgreSQL rule postcheck shows:
  `Crawlspace=attack_limit curated verified auto`,
  `Ghostly Prison=attack_tax curated verified auto`, and
  `Get Lost=remove_creature curated verified auto`.
- PostgreSQL function-tag postcheck shows `stax` tags for `Crawlspace` and
  `Ghostly Prison` from `curated_pg011_lorehold_defense`.
- Runtime sync artifact:
  `sync_pg_target_deck_to_hermes_pg011_lorehold_defense_20260620_193849.json`
  reports `apply=true`, deck id `6`, `cards_written=100`,
  `quantity_written=100`, and deck hash
  `d6317fc612db65a3c5fa03bfa82287871d93b88cc907e3ea78b8e46ccf1287b0`.
- Runtime cache artifact:
  `battle_card_rules_sqlite_from_pg_pg011_lorehold_defense_20260620_193849.json`
  reports `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`, and
  `canonical_snapshot_rows_exported=3187`.
- Fresh learned-deck audit:
  `learned_deck_coherence_audit_20260620_224441.json`; Lorehold remains
  `issues=[]`, `parsed_quantity=100`, `resolved_quantity=100`, and metadata
  records `lorehold_defense_variant_b_20260620`.
- Fresh full battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`,
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_rule_findings=6`, `forensic_severity_counts={"low":6}`,
  target-pressure pass `16/16`, table-intent pass `16/16`, and tests `18/18`.

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
| `2026-06-20 19:31 -0300` | Latest battle trusted reconciliation | Re-read latest battle after `212035` advanced to `221652`; re-ran local syntax/test checks for the modified battle runtime source. | n/a | `false` | Latest full `20260620_221652` supersedes `212035` and remains `trusted_for_strategy_learning` with `mandatory_gate_divergences=[]`; target-pressure passes `16/16` with `190` opponent combats into Lorehold, `2` into other defenders, `0` multi-defender attacks, and `0` findings; forensic, decision, action, and table-intent findings are `0`; tests pass `18/18`. Local evidence: `py_compile` passed for `battle_analyst_v9.py` and `battle_combat_tests.py`, and `test_battle_analyst_v10_3.py` passed with the attack-limit, attack-tax, and self-preservation combat regressions. This heartbeat did not execute PostgreSQL apply, SQLite sync, deck swap, stage, commit, or push. |
| `2026-06-20 19:34 -0300` | PG-011 Lorehold defense variant package detected | Read the newly created PG-011 package/precheck/apply/rollback/postcheck files and validated their referenced artifacts before the later sync artifacts appeared. | pending at that moment | `false` | Package proposes six Lorehold card swaps and writes to `deck_cards`, `commander_learned_decks`, `card_battle_rules`, and `card_function_tags`; baseline `20260620_221318` is trusted; temp variant run `/tmp/manaloom_lorehold_variant_b_mE2pHv/run_20260620_192657` shows `3` Lorehold wins, `80` combat events with restrictions, `52` attackers restricted, and `192` tax paid. At this instant PG-011 was treated as candidate/evidence only. |
| `2026-06-20 19:48 -0300` | PG-011 external apply/sync reconciliation | After new sync artifacts and `known_cards_canonical_snapshot.json` drift appeared, ran SELECT-only PostgreSQL checks, PG-011 postcheck SQL under read-only settings, learned-deck coherence audit, and a fresh full battle rerun. | external state observed; no apply command executed by this heartbeat | `false` by this heartbeat; external PostgreSQL state shows PG-011 applied | SELECT/postcheck shows out cards `0`, in cards `6`, deck qty `100`, active learned deck ok `1`; rules for `Crawlspace`, `Ghostly Prison`, and `Get Lost` are curated/verified/auto with generated duplicates deprecated/disabled; sync artifacts show Hermes deck id `6` and canonical snapshot refreshed; learned-deck audit `20260620_224441` keeps Lorehold `issues=[]`; fresh battle `20260620_224455` is `review_required` only by six low `Flame Wave` forensic findings, while target-pressure/table-intent/action/replay-decision pass and tests are `18/18`. |

## Current PostgreSQL Reading - 2026-06-20 19:48 -0300

- PostgreSQL-backed battle-rule promotions through round9 are reflected in the
  local Hermes battle runtime cache.
- Current final cache-sync artifact:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_full_after_table_intent_round9_20260620.json`.
- Current battle gate:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`,
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `test_results_status_counts={"pass":18}`.
- PG-011 is observed as externally applied in PostgreSQL and synced into the
  local Hermes runtime cache. This heartbeat did not execute the apply command.
- No additional PostgreSQL write is authorized at this exact checkpoint. Do
  not reapply PG-011; any future database apply must start from exact Rafael
  approval of the command, precheck review, rollback/postcheck evidence,
  runtime sync when applicable, and a fresh affected auditor rerun.
| `2026-06-20 18:21 -0300` | Latest battle trusted reconciliation | Re-read latest battle after round8/round9 artifacts appeared. | not by this heartbeat | `false` by this heartbeat; round8/round9 artifacts declare prior `apply_pg=true` and `apply_sqlite_from_pg=true` | Latest full `20260620_212035` supersedes `211648` and is `trusted_for_strategy_learning` with `mandatory_gate_divergences=[]`; target-pressure passes `16/16` with `214` opponent combats into Lorehold, `3` into other defenders, and `0` findings; forensic, decision, action, and table-intent findings are `0`; tests pass `18/18`. Round8 declares `pg_inserted_or_updated=2` for `Practical Research` and `Tellah, Great Sage`; round9 declares `pg_inserted_or_updated=2` for `Breena, the Demagogue`. This heartbeat did not execute apply/sync/rerun and no current PostgreSQL apply is ready. |

## Current PostgreSQL Reading - 2026-06-20 20:30 -0300

PG-012, PG-013, and PG-014 were observed as externally applied and already
synced into the local Hermes battle runtime cache. This heartbeat did not run
their apply commands and did not mutate PostgreSQL.

External apply/postcheck evidence:

- PG-012 `Flame Wave`: read-only postcheck returned `card_rows=1`,
  `curated_executable_rows=1`, `stale_enabled_remove_rows=0`; the curated rule
  is `damage_player_and_creatures`, source `curated`, confidence `1.000`,
  `review_status=verified`, `execution_status=auto`.
- PG-013 `Brainstone`: read-only postcheck returned `card_rows=1`,
  `curated_executable_rows=1`, `stale_enabled_draw_rows=0`; the curated rule is
  `topdeck_manipulation`, source `curated`, confidence `0.880`,
  `review_status=active`, `execution_status=auto`.
- PG-014 `Sphere of Safety`: read-only postcheck returned `card_rows=1`,
  `curated_executable_rows=1`, `stale_enabled_draw_rows=0`, and
  `protection_function_tag_rows=1`; the curated rule is
  `attack_tax_per_enchantment`, source `curated`, confidence `1.000`,
  `review_status=verified`, `execution_status=auto`.

Runtime/cache evidence:

- PG-012 sync artifacts:
  `battle_card_rules_sqlite_from_pg_pg012_flame_wave_20260620_200035.json` and
  `battle_card_rules_sqlite_from_pg_pg012_flame_wave_postfix_20260620_231019.json`.
  The postfix sync reports `apply_pg=false`,
  `apply_sqlite_from_pg=true`, `pg_rows_loaded=5234`,
  `sqlite_inserted_or_updated=5171`, and
  `canonical_snapshot_rows_exported=3195`.
- PG-013 sync artifact:
  `battle_card_rules_sqlite_from_pg_pg013_brainstone_20260620_201110.json`
  reports `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5235`, `sqlite_inserted_or_updated=5171`, and
  `canonical_snapshot_rows_exported=3195`.
- PG-014 sync artifact:
  `battle_card_rules_sqlite_from_pg_pg014_sphere_20260620_202250.json`
  reports `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`, and
  `canonical_snapshot_rows_exported=3195`.
- Local SQLite `battle_card_rules` has `Sphere of Safety` curated/verified/auto
  as `attack_tax` and the two generated `draw_engine` rows disabled.
- `known_cards_canonical_snapshot.json` exposes `Sphere of Safety` as
  `attack_tax` with `attack_tax_per_enchantment=1`,
  `minimum_attack_tax_per_creature=1`, and logical key
  `battle_rule_v1:a619518cf24caa68fdd86b555687f20f`.

Validation evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
  passed (`7` tests).
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including regressions for `Flame Wave`, `Brainstone`, and
  `Sphere of Safety`.
- Fresh read-only learned-deck audit
  `learned_deck_coherence_audit_20260620_233027.json` keeps Lorehold
  `learned_deck:82` with `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `unresolved=[]`, no premium Mox, and no PG/SQLite
  name drift.
- Fresh full recurring battle
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_232534/summary.json`
  is `trusted_for_strategy_learning`: `mandatory_gate_divergences=[]`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `action_findings=0`, replay-decision findings `0`,
  target-pressure passes `16/16`, table-intent passes `16/16`, and tests are
  `18/18`.

Operational conclusion:

- PG-012, PG-013, and PG-014 are closed as externally applied,
  postchecked, runtime-synced, and battle-validated.
- No new PostgreSQL package is authorized for apply at this checkpoint.
- Do not reapply PG-012/013/014 unless a future SELECT, sync report, or battle
  artifact proves rollback/drift and Rafael approves the exact command.

## Current PostgreSQL Reading - 2026-06-20 20:37 -0300

The `20260620_232534` full battle validated PG-012/013/014, but a later
external runner superseded `latest` with `20260620_233350` and exposed a new
opponent-card battle-rule backlog.

Current latest evidence:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_233350/summary.json`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `forensic_rule_findings=2`, severity `{"high":1,"medium":1}`.
- Both findings are `Arcane Epiphany` from `The Emperor of Palamecia #42 (real)`
  on seed `63212310`, turn `10`: `spell_cast` medium and `spell_resolved`
  high, effect `draw_cards`, source `functional_tags_json`.
- Target-pressure still passes `16/16`; table-intent passes `16/16`; action
  and replay-decision findings are `0`; tests are `18/18`.

Read-only PostgreSQL evidence for Arcane Epiphany candidate:

- `cards` has exactly one `Arcane Epiphany` row:
  `id=f5395e90-d0ef-4bf0-b042-f0cff60d31ae`, `mana_cost={3}{U}{U}`,
  `type_line=Instant`, `cmc=5.0`, `colors={U}`, `color_identity={U}`,
  oracle `This spell costs {1} less to cast if you control a Wizard. Draw
  three cards.`
- `card_battle_rules` has `0` rows for `Arcane Epiphany`.
- Local SQLite `battle_card_rules` also has `0` rows for `Arcane Epiphany`, and
  it is absent from `known_cards_canonical_snapshot.json`,
  `known_cards_generated.json`, and `reviewed_battle_card_rules.json`.

Operational conclusion:

- `Arcane Epiphany` is now the active candidate backlog item.
- No Arcane apply was executed or authorized in this heartbeat.
- Future Arcane work needs a row-level package with precheck, apply, rollback,
  postcheck, runtime cache sync, and a fresh battle rerun before closure.

## Current PostgreSQL Reading - 2026-06-20 20:40 -0300

Later external variant runners superseded the `233350` Arcane Epiphany blocker.
The current `latest` is now:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234004/summary.json`.
- `invocation_kind=codex_variant_sphere_for_victory_chimes`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `action_findings=0`, replay-decision findings `0`,
  target-pressure passes `16/16`, table-intent passes `16/16`, and tests are
  `18/18`.

Operational conclusion:

- PG-012, PG-013, and PG-014 remain closed by postcheck, runtime sync, and
  battle validation.
- `Arcane Epiphany` is a candidate from superseded `233350`, not an
  active latest blocker at `234004`.
- No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit, or push
  was performed for Arcane.

## Current PostgreSQL Reading - 2026-06-20 20:49 -0300

The variant sweep continued after `234004`; current latest at this checkpoint
is:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234900/summary.json`.
- `invocation_kind=codex_variant_spire_for_guttersnipe`.
- `battle_replay_final_status=blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `forensic_rule_findings=2`, severity `{"high":1,"medium":1}`.
- Both findings are `Arcane Epiphany`, effect `draw_cards`, source
  `functional_tags_json`, seed `63212310`, turn `10`.
- Clean gates: target-pressure `pass=16`, table-intent `pass=16`,
  action findings `0`, replay-decision findings `0`, tests `18/18`.

Arcane Epiphany candidate evidence remains:

- PostgreSQL has one `cards` row for `Arcane Epiphany` and `0`
  `card_battle_rules` rows.
- Local SQLite `battle_card_rules` has `0` rows for `Arcane Epiphany`.
- No Arcane apply, cache hotfix, deck swap, cleanup, stage, commit, or push was
  performed.

## Current PostgreSQL Reading - 2026-06-20 20:52 -0300

The runner that was active after the `234900` read completed and superseded the
temporary Arcane Epiphany blocker.

Current latest evidence:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235219/summary.json`.
- `invocation_kind=codex_real_deck_after_variants`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `forensic_rule_findings=0`, `forensic_turn_findings=0`.
- Target-pressure passes `16/16` with `target_pressure_findings=0`.
- Table-intent passes `16/16`; action findings `0`; replay-decision findings
  `0`; event-contract observed/static unclassified totals `0/0`.
- `test_results_status_counts={"pass":18}`; compatibility fields
  `tests_passed` and `tests_total` are `null`.

Operational conclusion:

- PG-012, PG-013, and PG-014 remain closed by SELECT postcheck, runtime sync,
  and battle validation.
- `Arcane Epiphany` remains candidate-only from superseded `233350` and
  `234900` artifacts. Because current latest `235219` passes all mandatory
  gates, it is not in the active apply queue.
- No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit, or push
  was performed.

## Current PostgreSQL Reading - 2026-06-20 20:59 -0300

New PG-015/Wrath artifacts appeared externally after the `235219` trusted run,
and the latest battle advanced again.

PG-015/Wrath evidence:

- Package files:
  `wrath_of_god_battle_rule_pg015_*_20260620_205619.*`.
- Sync report:
  `battle_card_rules_sqlite_from_pg_pg015_wrath_20260620_205900.json`.
- Sync report values: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`,
  `canonical_snapshot_rows_exported=3195`, `pg_inserted_or_updated=0`, and
  `selected_card_count=0`.
- Read-only precheck now returns `card_rows=1`,
  `generated_wipe_review_only_rows=0`, and `executable_board_wipe_rows=1`.
- Read-only postcheck returns `curated_executable_rows=1` and
  `stale_enabled_wipe_rows=0`.
- PostgreSQL rule state:
  `Wrath of God`, logical key
  `battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e`,
  `effect={"cmc":4.0,"effect":"board_wipe"}`, source `curated`,
  confidence `1.000`, `review_status=verified`, `execution_status=auto`,
  reviewed by `codex_central_auditor_pg015` at
  `2026-06-20 23:58:17.150487+00`.
- Local SQLite also selects the curated verified auto `Wrath of God` board-wipe
  row and has the old generated duplicate as `deprecated/disabled`.

Current latest evidence:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235914/summary.json`.
- `invocation_kind=codex_variant_wrath_for_guttersnipe`.
- `battle_replay_final_status=blocked`.
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `forensic_rule_findings=2`, severity `{"high":1,"medium":1}`.
- Both findings are `Arcane Epiphany`, effect `draw_cards`, source
  `functional_tags_json`, seed `63212310`, turn `10`.
- Clean gates: target-pressure `pass=16`, table-intent `pass=16`, action
  findings `0`, replay-decision findings `0`, and
  `test_results_status_counts={"pass":18}`.

Operational conclusion:

- PG-015/Wrath is externally applied, postchecked, and runtime-synced. This
  heartbeat did not execute the apply command and must not reapply it.
- Current active pending item is `Arcane Epiphany`, not Wrath. It has one
  PostgreSQL `cards` row and `0` PG/local battle-rule rows from prior read-only
  checks.
- No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit, or push
  was performed.

## Current PostgreSQL Reading - 2026-06-20 21:08 -0300

Further external runners superseded the `235914` Arcane blocker and `000525`.

Current latest evidence:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_000827/summary.json`.
- `invocation_kind=codex_real_deck_after_wrath_variants`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_severity_counts={}`.
- Target-pressure passes `16/16` with `target_pressure_findings=0`.
- Table-intent passes `16/16`; action findings `0`; replay-decision findings
  `0`; `test_results_status_counts={"pass":18}`.

Operational conclusion:

- PG-015/Wrath is externally applied, postchecked, runtime-synced, and
  battle-validated by the latest trusted run.
- `Arcane Epiphany` is candidate-only from superseded `235914`, not active in
  current latest `000827`.
- No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit, or push
  was performed by this heartbeat.

## Current PostgreSQL Reading - 2026-06-20 22:14 -0300

External PG-016, PG-017, and PG-018 artifacts appeared after the `000827`
trusted run. This heartbeat treated them as evidence to verify, not as approval
to execute any write.

PG-016 anti-combat evidence:

- Package files:
  `anti_combat_candidate_rules_pg016_*_20260621_011500.*`.
- Sync reports:
  `battle_card_rules_sqlite_from_pg_pg016_anti_combat_20260621_012400.json`
  and `card_metadata_sqlite_from_pg_pg016_anti_combat_20260621_012400.json`.
- Package scope: `Norn's Annex`, `Windborn Muse`, `Silent Arbiter`,
  `Ensnaring Bridge`, and `Magus of the Moat`.
- Read-only postcheck: `card_rows=5`, `commander_legal_rows=5`,
  `curated_executable_rows=5`, `stale_enabled_generated_rows=0`, and
  `protection_function_tag_rows=5`.
- Runtime sync report: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=1808`, `sqlite_inserted_or_updated=2400`, and
  `canonical_snapshot_rows_exported=3198`.

PG-017 Arcane Epiphany evidence:

- Package files:
  `arcane_epiphany_battle_rule_pg017_*_20260621_004200.*`.
- Sync report:
  `battle_card_rules_sqlite_from_pg_pg017_arcane_epiphany_20260621_004400.json`.
- Read-only postcheck: `card_rows=1`, `curated_executable_rows=1`, and
  `draw_function_tag_rows=1`.
- PostgreSQL rule:
  `battle_rule_v1:3e12c38dd6d41a47079fbdefee08b3bd`,
  `effect={"cmc":5.0,"effect":"draw_cards","draw_count":3,...}`,
  source `curated`, confidence `0.940`, `review_status=verified`,
  `execution_status=auto`, reviewed by `codex_central_auditor_pg017`.
- Runtime sync report: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=1809`, `sqlite_inserted_or_updated=1776`, and
  `canonical_snapshot_rows_exported=3199`.

PG-018 opponent forensic evidence:

- Package files:
  `opponent_forensic_rules_pg018_*_20260621_011600.*`.
- Sync report:
  `battle_card_rules_sqlite_from_pg_pg018_opponent_forensic_20260621_011800.json`.
- Package scope: `Jin-Gitaxias, Core Augur` and `Chandra, Flameshaper`.
- Read-only postcheck:
  `pg018_opponent_forensic_postcheck_counts` returned `card_rows=2`,
  `curated_executable_rows=2`, and `function_tag_rows=2`.
- PostgreSQL rules:
  `Jin-Gitaxias, Core Augur` has
  `battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e`,
  `effect=draw_cards`, `draw_count=7`, source `curated`, confidence `0.860`,
  `review_status=verified`, `execution_status=auto`;
  `Chandra, Flameshaper` has
  `battle_rule_v1:ee7ee13e3d57abd378763be663390375`,
  `effect=ramp_permanent`, `mana_produced=3`, source `curated`, confidence
  `0.840`, `review_status=verified`, `execution_status=auto`.
- Runtime sync report: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=2`, `sqlite_inserted_or_updated=2`,
  `selected_card_count=2`, and `canonical_snapshot_rows_exported=3184`.
- Local runtime cache
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` selects both
  PG-018 rows as curated/verified/auto.

Current latest battle evidence:

- Latest summary before PG-018 rerun completion:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_010452/summary.json`.
- `invocation_kind=codex_pg017_full64_real_deck_baseline`,
  `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`,
  `forensic_rule_findings=2`, `forensic_severity_counts={"high":1,"medium":1}`,
  target-pressure `pass=64`, table-intent `pass=64`, action findings `0`,
  replay-decision findings `0`, and `test_results_status_counts={"pass":18}`.
- That blocker was `Jin-Gitaxias, Core Augur` forensic lineage from
  `functional_tags_json`, seed `63212362`, turn `8`, effect `draw_cards`.
- After the PG-018 sync, a new
  `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310` runner
  was active. No newer completed summary had been observed at this checkpoint.

Operational conclusion:

- PG-016, PG-017, and PG-018 are closed for PostgreSQL/cache state by read-only
  SELECT plus sync artifacts, but PG-018 still needs the in-progress battle
  rerun result before battle closure.
- Do not reapply PG-016, PG-017, or PG-018.
- No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit, or push
  was performed by this heartbeat.

## Current PostgreSQL Reading - 2026-06-20 22:44 -0300

The post-PG018 battle rerun completed and introduced a PG-019 follow-up package
for the remaining strategy-audit semantic issue. This heartbeat verified the
result and PG-019 state in read-only mode only.

Current latest battle evidence:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_012833/summary.json`.
- `invocation_kind=codex_pg018_full64_real_deck_baseline`,
  `seeds_requested=64`, `seeds_completed=64`, `start_seed=63212310`.
- `battle_replay_final_status=review_required`.
- `mandatory_gate_divergences=["strategy_audit=review_required"]`.
- Forensic is clean: `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, and `forensic_severity_counts={}`.
- Other clean gates: target-pressure `pass=64`, target-pressure findings `0`,
  table-intent `pass=64`, action findings `0`, replay-decision findings `0`,
  and `test_results_status_counts={"pass":18}`.
- Strategy findings: `strategy_findings=17`,
  `strategy_low_confidence_findings=16`, and
  `strategy_review_required_findings=1`.
- The single review-required finding is seed `63212362`,
  `wheel_opponent_refill_risk`, decision `decision-000141`, detail
  `Wheel may refill opponents without a recorded payoff.`

PG-019 Jin-Gitaxias non-wheel evidence:

- Package files:
  `jin_gitaxias_non_wheel_pg019_*_20260621_013900.sql` and
  `jin_gitaxias_non_wheel_pg019_package_20260621_013900.md`.
- Sync report:
  `battle_card_rules_sqlite_from_pg_pg019_jin_non_wheel_20260621_014100.json`.
- Package scope: correct `Jin-Gitaxias, Core Augur` so the draw-seven proxy is
  not treated as a multiplayer wheel.
- Read-only postcheck:
  `Jin-Gitaxias, Core Augur`,
  `battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e`,
  `effect={"effect":"draw_cards","draw_count":7,"wheel_like":false,...}`,
  source `curated`, confidence `0.860`, `review_status=verified`,
  `execution_status=auto`, reviewed by `codex_central_auditor_pg019` at
  `2026-06-21 01:40:25.910763+00`.
- Snapshot postcheck shows the same `wheel_like=false` battle rule under
  `card_intelligence_snapshot`.
- Runtime sync report: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`,
  `selected_card_count=1`, `selected_cards=["Jin-Gitaxias, Core Augur"]`, and
  `canonical_snapshot_rows_exported=3184`.
- Local Hermes SQLite
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` selects the
  PG-019 `wheel_like=false` row.
- A post-PG019
  `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310` runner
  was active at this checkpoint.

Operational conclusion:

- PG-018 is battle-forensic closed by `012833`.
- PG-019 is closed for PostgreSQL/cache state by read-only SELECT plus sync
  artifact, but battle closure requires the active post-PG019 rerun result.
- Do not reapply PG-019.
- No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit, or push
  was performed by this heartbeat.

## Current PostgreSQL Reading - 2026-06-20 23:14 -0300

The post-PG019 battle state advanced, and a local Hermes optimizer apply
appeared. This checkpoint distinguishes PostgreSQL/canonical deck state from
Hermes SQLite runtime state.

PostgreSQL/canonical evidence:

- Read-only PostgreSQL check on materialized Lorehold deck
  `528c877f-f829-4207-95e6-73981776c323` returns `Guttersnipe=1`, no
  `Windborn Muse`, and `100/100` cards.
- Therefore no PostgreSQL deck swap was observed for the Windborn change.
- No new learned-deck coherence artifact exists after
  `learned_deck_coherence_audit_20260620_233027.json`.

Hermes local SQLite evidence:

- New local optimizer artifacts:
  `master_optimizer_apply_20260621_020406.md` and
  `master_optimizer_rollback_20260621T020406839706+0000.json`.
- The apply artifact records local Hermes `deck_id=6` swap:
  `Windborn Muse` over `Guttersnipe`.
- The apply artifact states: `No production database was mutated. This applies
  only to the Hermes local SQLite knowledge deck.`
- Local SQLite verification on
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` returns
  `Windborn Muse=1`, no `Guttersnipe`, and `100/100` cards for `deck_id=6`.

Latest completed battle evidence:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020427/summary.json`.
- `run_scope=recurring_full`,
  `invocation_kind=codex_pg019_post_apply_windborn_16`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- Forensic findings `0`; target-pressure `pass=16`; table-intent `pass=16`;
  action findings `0`; replay-decision findings `0`; tests `18/18`.
- Strategy audit has `strategy_findings=5`,
  `strategy_low_confidence_findings=5`, and
  `strategy_review_required_findings=0`.
- A newer run directory `20260621_020729` existed but had no `summary.json`;
  a 64-seed runner was still active at this checkpoint.

Operational conclusion:

- PG-019 is battle-closed for the completed 16-seed `020427` run.
- The Windborn-over-Guttersnipe change is only local Hermes runtime state, not
  a PostgreSQL or learned-deck apply. Do not promote/apply it to PostgreSQL
  without explicit approval.
- No PostgreSQL apply, cache hotfix, deck swap command, cleanup, stage, commit,
  or push was performed by this heartbeat.

Final 64-seed reconciliation:

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/summary.json`.
- `invocation_kind=codex_pg019_post_apply_windborn_64`,
  `seeds_requested=64`, `seeds_completed=64`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=64`, table-intent `pass=64`, action findings `0`, replay-decision
  findings `0`, tests `18/18`, and `strategy_review_required_findings=0`.
- No active `manaloom-battle-strategy-audit.sh` runner remained in the final
  process check.

## Current PostgreSQL Reading - 2026-06-20 23:45 -0300

PG-020 is now confirmed by live read-only postcheck and a fresh learned-deck
coherence audit.

PostgreSQL/Hermes evidence:

- Read-only postcheck
  `lorehold_windborn_deck_swap_pg020_postcheck_20260621_022046.sql` returned
  `postcheck_passed=true`, `deck_rows=100`, `deck_quantity=100`,
  `Guttersnipe=0`, `Windborn Muse=1`, `windborn_is_commander=false`, and
  `backup_rows=1`.
- Local Hermes SQLite `deck_id=6` has `Windborn Muse=1`, no `Guttersnipe`, and
  `100/100` cards.
- PG -> Hermes sync report
  `sync_pg_target_deck_to_hermes_pg020_windborn_20260621_022046.json`
  records `cards_written=100`, `quantity_written=100`, and
  `duplicate_rows_collapsed=0`.

Learned-deck coherence evidence:

- Fresh read-only artifacts:
  `learned_deck_coherence_audit_20260621_024551.json` and `.md`.
- Global learned-deck state is unchanged at high-clean:
  `active_learned_decks=60`, `severity_counts={"medium":13}`.
- Lorehold `learned_deck:82` still has `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `unresolved=[]`, no off-color finding, and no
  partner/background identity finding.
- Post-PG020 name drift remains because active learned deck contents are not
  the same as the materialized PG/Hermes runtime deck:
  active-vs-PG missing `Guttersnipe` and PG extra `Windborn Muse`;
  active-vs-SQLite missing `Guttersnipe` and `Monument to Endurance`, SQLite
  extra `Silent Arbiter` and `Windborn Muse`.

Current battle evidence:

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024220/summary.json`.
- `invocation_kind=codex_pg020_candidate_ensnaring_bridge_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package was found for the Ensnaring Bridge candidate at this checkpoint.
- A newer run directory `20260621_024527` existed without `summary.json`, and a
  16-seed runner was active.

Operational conclusion:

- PG-020 is applied/postchecked/synced and battle-trusted.
- The active learned-deck name drift is open and should not be fixed by a
  PostgreSQL mutation without explicit approval.
- Ensnaring Bridge over Monument to Endurance remains candidate-only.
- No PostgreSQL apply, cache hotfix, deck swap command, cleanup, stage, commit,
  or push was performed by this heartbeat.

## PG-020 Lorehold Windborn Deck Swap - 2026-06-20 23:40 -0300

Scope:

- Promoted the already battle-validated Hermes local swap `Windborn Muse` over
  `Guttersnipe` to the PostgreSQL materialized Lorehold deck after explicit
  owner authorization to continue deck correction and PostgreSQL deploy.

Files:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_windborn_deck_swap_pg020_precheck_20260621_022046.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_windborn_deck_swap_pg020_apply_20260621_022046.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_windborn_deck_swap_pg020_postcheck_20260621_022046.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_windborn_deck_swap_pg020_rollback_20260621_022046.sql`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_windborn_deck_swap_pg020_package_20260621_022046.md`
- `docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg020_windborn_20260621_022046.json`

Evidence:

- Precheck on `143.198.230.247:5433/halder` returned
  `ready_to_apply=true`: deck `Runtime Lorehold Learned 19e93de3cca`,
  format `commander`, `deck_rows=100`, `deck_quantity=100`,
  `Guttersnipe=1`, `Windborn Muse=0`, `Windborn Muse` Commander legal, and
  color identity `{W}`.
- Apply returned `Guttersnipe=0`, `Windborn Muse=1`, and
  `total_quantity=100`.
- Postcheck returned `postcheck_passed=true`, `backup_rows=1`,
  `deck_rows=100`, `deck_quantity=100`, `windborn_is_commander=false`.
- Rollback is available in
  `lorehold_windborn_deck_swap_pg020_rollback_20260621_022046.sql` and uses
  `manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046`.
- PG -> Hermes sync wrote `100/100` cards into local `deck_id=6`.

Battle proof after PG/sync:

- Smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022403/summary.json`,
  `2/16`, `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`.
- Full confirmation:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022700/summary.json`,
  `4/64 = 6.25%`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`,
  `target_pressure_opponent_combat_to_target=912`,
  `target_pressure_opponent_combat_to_other=12`, and
  `strategy_code_counts={"forced_keep_after_bad_mulligan":15}`.

Conclusion:

- PG-020 is applied, postchecked, synced back to Hermes, and battle-validated.
- It is a real improvement from the previous trusted baseline
  `2/64 = 3.125%` to `4/64 = 6.25%`, but the deck remains strategically weak.

## Candidate-Only Reading After PG-020 - 2026-06-20 23:49 -0300

- Latest battle summary at this deploy-register checkpoint:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024906/summary.json`.
- `invocation_kind=codex_pg020_candidate_norns_annex_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package was found for `Norn's Annex`/`PG021`/`024906`; this checkpoint
  made no PostgreSQL change and does not open an apply path.

## Review-Required Candidate After PG-020 - 2026-06-20 23:52 -0300

- Latest battle summary after the candidate-only Norn's Annex read:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_025233/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`, and
  `battle_replay_final_status=review_required`.
- Mandatory gate divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`.
- Specific replay blocker: seed `63212318`, turn `12`, low-severity
  `board_wipe_resolved` finding where the board wipe left `9` protected
  creatures and destroyed `7`.
- No PG package was found for `Magus of the Moat`/`PG021`/`025233`; this
  register made no PostgreSQL change.

## Review-Required 64-Seed Candidate After PG-020 - 2026-06-21 00:17 -0300

- Latest battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_030022/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=review_required`.
- Mandatory gate divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`.
- Specific replay blocker remains seed `63212318`, turn `12`, low-severity
  `board_wipe_resolved` finding where the board wipe left `9` protected
  creatures and destroyed `7`.
- No PG package was found for `Magus of the Moat`/`PG021`/`030022`; this
  checkpoint made no PostgreSQL change and does not authorize apply.
- Fresh learned-deck coherence audit
  `learned_deck_coherence_audit_20260621_031653.json` was read-only and keeps
  PG-020 as the only canonical PostgreSQL deck change in this checkpoint.

## Corrected Candidate After PG-020 - 2026-06-21 00:18 -0300

- Latest battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_031617/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_magus_moat_for_monument_16`,
  `run_scope=recurring_full`, `seeds_requested=16`, `seeds_completed=16`,
  and `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`, forensic turn
  findings `0`, replay decision turn findings `0`, target-pressure `pass=16`,
  table-intent `pass=16`, and tests `18/18`.
- No PG package was found for `Magus of the Moat`/`PG021`/`031617`; this
  checkpoint made no PostgreSQL change and does not authorize apply.

## Corrected Silent Arbiter Candidate After PG-020 - 2026-06-21 00:52 -0300

- Latest battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_silent_arbiter_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`, forensic turn
  findings `0`, replay decision turn findings `0`, target-pressure `pass=64`,
  table-intent `pass=64`, and tests `18/18`.
- No PG package was found for `Silent Arbiter`/`PG021`/`032623`; this
  checkpoint made no PostgreSQL change and does not authorize apply.

## PG021/PG022 Observed Applied And Postchecked - 2026-06-21 01:55 -0300

Scope:

- New PG021 and PG022 deploy packages appeared in
  `docs/hermes-analysis/master_optimizer_reports`.
- This heartbeat did not execute apply, rollback, deck swap, commit, push,
  cleanup, stash, or revert.

Evidence:

- PG021 read-only postcheck passed:
  `rule_rows=3`, `silent_global_ok=true`, `magus_global_ok=true`,
  `bridge_controller_hand_ok=true`, `postcheck_passed=true`.
- PG021 SQLite sync:
  `battle_card_rules_sqlite_from_pg_pg021_global_attack_scope_20260621_043814.json`,
  `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `sqlite_inserted_or_updated=4`.
- PG022 read-only postcheck passed:
  `deck_rows=100`, `deck_quantity=100`, `Monument to Endurance=0`,
  `Silent Arbiter=1`, `silent_is_commander=false`, `backup_rows=1`,
  `postcheck_passed=true`.
- PG022 PG -> Hermes sync:
  `sync_pg_target_deck_to_hermes_pg022_silent_arbiter_20260621_044155.json`,
  `apply=true`, `cards_written=100`, `quantity_written=100`,
  `duplicate_rows_collapsed=0`.
- Post-sync battle smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`,
  `codex_pg022_post_pg_sync_silent_arbiter_16`, trusted, clean gates,
  tests `18/18`.

Conclusion:

- PG021 and PG022 are observed as externally applied/postchecked/synced and
  smoke battle-validated.
- Do not reapply PG021/PG022.

## PG021/PG022 Executed And Full Battle Validated - 2026-06-21 01:58 -0300

Scope:

- This cycle executed and verified PG021 and PG022 from this thread.
- PG021 corrected battle-rule scope for `Silent Arbiter`, `Magus of the Moat`,
  and `Ensnaring Bridge`.
- PG022 promoted `Silent Arbiter` over `Monument to Endurance` in the
  PostgreSQL Lorehold runtime deck.

PostgreSQL evidence:

- PG021 precheck: `ready_to_apply=true`.
- PG021 apply: backup `INSERT 0 3`, rule update `UPDATE 3`.
- PG021 corrected postcheck:
  `rule_rows=3`, `silent_global_ok=true`, `magus_global_ok=true`,
  `bridge_controller_hand_ok=true`, `postcheck_passed=true`.
- PG022 precheck: `ready_to_apply=true`.
- PG022 apply result: `Monument to Endurance=0`, `Silent Arbiter=1`,
  `total_quantity=100`.
- PG022 postcheck:
  `deck_rows=100`, `deck_quantity=100`, `monument_rows=0`,
  `silent_rows=1`, `silent_is_commander=false`, `backup_rows=1`,
  `postcheck_passed=true`.

Sync evidence:

- PG021 PG -> SQLite battle-rule sync:
  `battle_card_rules_sqlite_from_pg_pg021_global_attack_scope_20260621_043814.json`,
  `sqlite_inserted_or_updated=4`.
- PG022 PG -> Hermes deck sync:
  `sync_pg_target_deck_to_hermes_pg022_silent_arbiter_20260621_044155.json`,
  `apply=true`, `cards_written=100`, `quantity_written=100`,
  `duplicate_rows_collapsed=0`.

Battle evidence:

- Baseline corrected 64:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_041725/summary.json`,
  `4/64`, trusted, clean gates.
- PG022 post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`,
  `3/16`, trusted, clean gates.
- PG022 post-sync full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`,
  `8/64 = 12.5%`, trusted, clean gates,
  `forced_keep_after_bad_mulligan=15`.

Conclusion:

- PG021 and PG022 are canonical and should not be reapplied.
- The current Lorehold deck is improved but still not solved; next work should
  target mulligan/curve/consistency rather than another blind pillowfort swap.

## Post-PG022 Candidate Scans - 2026-06-21 02:27 -0300

Scope:

- Observed new post-PG022 battle candidate scans only.
- This heartbeat did not execute PostgreSQL apply, rollback, deck swap,
  commit, push, cleanup, stash, or revert.
- No PostgreSQL package was found for Brainstone over Generous Gift,
  Artist's Talent over Generous Gift, or Reprieve over Generous Gift.

Evidence:

- PG022 validation remains the latest canonical deploy proof:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_deck6_pg022_silent_arbiter_validation_20260621_044758.md`.
- Candidate summaries:
  - `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_051800/summary.json`:
    Brainstone over Generous Gift after forensic fix, `4/16`, trusted, clean
    gates.
  - `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_052117/summary.json`:
    Artist's Talent over Generous Gift, `3/16`, trusted, clean gates.
  - `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_052416/summary.json`:
    Reprieve over Generous Gift, `5/16`, `review_required`,
    `strategy_audit=review_required`.
- Local SQLite restoration check after the latest temporary candidate runner:
  `Generous Gift=1`; no persisted `Reprieve`, `Artist's Talent`, or
  `Brainstone` candidate row in `deck_id=6`.

Conclusion:

- No new PostgreSQL deploy item is approved from these scans.
- Reprieve is explicitly blocked by strategy review.
- Brainstone and Artist's Talent are clean candidate evidence only, pending a
  package, approval, precheck, apply, postcheck, sync, and rerun if ever
  selected.

## Post-Engine-Fix Candidate Scans - 2026-06-21 03:06 -0300

Scope:

- Observed new post-PG022 battle candidate/baseline scans only.
- This heartbeat did not execute PostgreSQL apply, rollback, deck swap,
  commit, push, cleanup, stash, or revert.
- No PostgreSQL package was found for the sequence.

Evidence:

- Latest learned-deck coherence remains
  `learned_deck_coherence_audit_20260621_045522.json`; no new learned audit
  appeared.
- Battle summaries:
  - `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_053446/summary.json`:
    candidate scan, `4/16`, trusted, clean gates.
  - `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_053937/summary.json`:
    baseline after engine fix, `3/16`, trusted, clean gates.
  - `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_054357/summary.json`:
    candidate scan after engine fix, `4/16`, trusted, clean gates.
  - `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_054803/summary.json`:
    candidate combo scan, `1/16`, trusted, clean gates.

Conclusion:

- No new PostgreSQL deploy item is approved from these scans.
- The latest combo scan is worse than the existing PG022 validated deck result
  and should not be promoted.

## Aborted Runner / PG Connectivity Check - 2026-06-21 04:48 -0300

Scope:

- Observed new run directory `20260621_060733` without `summary.json`.
- This heartbeat did not execute PostgreSQL apply, rollback, deck swap,
  commit, push, cleanup, stash, or revert.

Evidence:

- `060733/test_results.jsonl`: `py_compile=pass`; `test_battle_analyst_v10_3`
  failed after `963s`.
- Error:
  `psycopg2.OperationalError: server closed the connection unexpectedly` while
  opening `sync_pg.connect()`.
- Follow-up with `PGOPTIONS='-c default_transaction_read_only=on'` succeeded:
  `select 1` returned `pg_select_1=1`.

Conclusion:

- This is not a PostgreSQL deploy package, not PG rollback/drift evidence, and
  not a deck result.
- Keep PG021/PG022 closed and do not reapply anything from this artifact.

## Latest Manual 64-Seed Battle Result - 2026-06-21 05:17 -0300

Scope:

- Observed new completed `latest` battle artifact `20260621_080706`.
- This heartbeat did not execute PostgreSQL apply, rollback, deck swap,
  commit, push, cleanup, stash, or revert.
- No PostgreSQL package was found for this result.

Evidence:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json`:
  `custom_64_seed`, `manual_cli`, `64/64`, trusted, clean gates.
- Lorehold wins `14/64`, opponents win `49/64`,
  `forced_keep_after_bad_mulligan=13`.
- Local SQLite remains aligned with PG022 runtime shape:
  `Silent Arbiter=1`, `Windborn Muse=1`, `100/100`.
- Latest learned-deck coherence remains `045522`; active learned-deck drift
  remains open.

Conclusion:

- No new PostgreSQL deploy item is approved from `080706`.
- PG021/PG022 remain closed; the next write action still requires explicit
  package approval.

## PG023 Brainstone Package Prepared - 2026-06-21 05:17 -0300

Scope:

- New PostgreSQL package artifacts appeared for a Lorehold Brainstone deck swap.
- This heartbeat did not execute precheck, apply, postcheck, rollback, sync,
  commit, push, cleanup, stash, or revert.

Files:

- `lorehold_brainstone_deck_swap_pg023_precheck_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_apply_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_postcheck_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_rollback_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`

Package summary:

- Status: `prepared`.
- Proposed swap: add `Brainstone`; cut `Generous Gift`.
- Target deck: `528c877f-f829-4207-95e6-73981776c323`.
- Evidence: PG022 baseline `8/64`; Brainstone candidate `14/64`; net `+6`
  Lorehold wins.
- Local SQLite still has `Generous Gift=1` and no `Brainstone` row, so this
  package is not applied to runtime.

Conclusion:

- PG023 is prepared only and must not be applied without explicit approval of
  the exact command.
- If approved later, run the package precheck/apply/postcheck, sync PG deck to
  Hermes, sync Brainstone battle rules, and rerun battle validation.

## PG023 Brainstone External Apply Closure - 2026-06-21 10:07 -0300

Scope:

- Newer PG023 evidence supersedes the earlier prepared-only entry.
- This heartbeat did not execute PG023 precheck, apply, rollback, deck swap,
  commit, push, cleanup, stash, or revert.
- This heartbeat did execute the PG023 postcheck SQL in read-only PostgreSQL
  mode using `PGOPTIONS='-c default_transaction_read_only=on'`.

Evidence:

- Package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`.
- Package status: `applied_and_postchecked_and_battle_validated`.
- Read-only PG postcheck returned:
  `deck_rows=100`, `deck_quantity=100`, `gift_rows=0`,
  `gift_quantity=0`, `brainstone_rows=1`, `brainstone_quantity=1`,
  `brainstone_is_commander=false`, `deck_backup_rows=1`,
  `rule_backup_rows=1`, `brainstone_rule_rows=1`,
  `brainstone_rule_verified=true`, `postcheck_passed=true`.
- Deck sync:
  `sync_pg_target_deck_to_hermes_pg023_brainstone_20260621_114447.json`
  reports `apply=true`, `cards_written=100`, `quantity_written=100`,
  `duplicate_rows_collapsed=0`.
- Rule sync:
  `battle_card_rules_sqlite_from_pg_pg023_brainstone_20260621_114447.json`
  reports `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5244`, `sqlite_inserted_or_updated=5211`.
- Local SQLite focused check confirms PG023 runtime shape:
  `Brainstone=1`, `Silent Arbiter=1`, `Windborn Muse=1`; no `Generous Gift`
  row in `deck_id=6`.
- Battle validation:
  `20260621_121648` smoke `4/16`, trusted, clean gates; latest full
  `20260621_122732` `14/64`, trusted, clean gates, tests `18/18`.
- Learned-deck follow-up:
  `learned_deck_coherence_audit_20260621_130957.json` keeps aggregate
  `medium=13` and confirms active learned-deck drift now includes
  `Generous Gift` versus `Brainstone`.

Conclusion:

- Treat PG023 as externally applied, postchecked, synced, and battle-validated.
- Do not reapply PG023. Future PG023 action should be rollback/drift handling
  only if read-only evidence proves a problem.
- Active learned-deck source mutation is still not authorized by this entry.

## Post-PG023 Temporary Candidate Latest - 2026-06-21 10:15 -0300

Scope:

- A new temporary 16-seed candidate runner became the `latest` battle artifact
  after PG023 closure was recorded.
- This heartbeat did not execute PostgreSQL apply, rollback, deck swap, commit,
  push, cleanup, stash, or revert for this candidate.

Evidence:

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131126/summary.json`.
- Observed process command temporarily inserted `Expedition Map` over
  `Electroduplicate` in SQLite with a backup/restore trap.
- Summary: `16/16`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold `1/16`, opponents `14/16`,
  `forced_keep_after_bad_mulligan=3`.
- Post-run SQLite check confirms persistent deck restored to PG023 state:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Expedition Map`, no `Generous Gift`.

Conclusion:

- `131126` is not a PostgreSQL deploy item and does not reopen PG023.
- PG023 remains closed on the read-only postcheck and post-sync validation
  evidence above; `122732` remains the PG023 full validation artifact even
  though it is no longer the symlink target.

## Latest PG023 Recurring Smoke - 2026-06-21 10:20 -0300

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131606/summary.json`.
- `131606`: `recurring_16_seed`, `recurring_full`, `manual_cli`, `16/16`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`,
  Lorehold `3/16`, `forced_keep_after_bad_mulligan=5`.
- Persistent runtime remains PG023-shaped after the run:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Generous Gift`, no `Expedition Map`, `100/100`.
- Deploy conclusion unchanged: PG023 is closed; no PostgreSQL action is ready.

## Temporary Thrill Candidate Latest - 2026-06-21 10:25 -0300

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132027/summary.json`.
- Observed temporary runner used `Thrill of Possibility` over `Boros Charm`
  with SQLite backup/restore.
- `132027`: `16/16`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`, Lorehold `2/16`,
  `forced_keep_after_bad_mulligan=4`.
- Persistent runtime after run:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Thrill of Possibility`,
  `100/100`.
- Deploy conclusion unchanged: no PostgreSQL action is ready.

## Temporary Reprieve Candidate Latest - 2026-06-21 10:30 -0300

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`.
- Temporary runner used `Reprieve` over `Boros Charm` with SQLite
  backup/restore.
- `132537`: `16/16`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`, Lorehold `4/16`,
  `forced_keep_after_bad_mulligan=5`.
- Persistent runtime after run:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Reprieve`, no `Generous Gift`,
  `100/100`.
- Deploy conclusion unchanged: no PostgreSQL action is ready.

## PG023 Candidate Scan No-Promotion Artifact - 2026-06-21 10:30 -0300

- New repo artifact:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_pg023_candidate_scan_20260621_132537.md`.
- Status: `no_promotion`.
- It records four temporary SQLite candidates and states no PostgreSQL apply
  was performed and no package was generated.
- Candidate results: `1/16`, `3/16`, `2/16`, and `4/16`; all gate-clean but
  rejected.
- Deploy conclusion unchanged: PG023 remains closed and no PostgreSQL action is
  ready.

## PG023 Brainstone Apply - 2026-06-21 10:06 -0300

Scope:

- Applied Lorehold deck swap in PostgreSQL:
  `Brainstone` replaced `Generous Gift` in deck
  `528c877f-f829-4207-95e6-73981776c323`.
- Promoted Brainstone curated battle rule
  `battle_rule_v1:03bed5506a427743723cd7676c6a67d9` from `active/auto` to
  `verified/auto`.

Files:

- `lorehold_brainstone_deck_swap_pg023_precheck_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_apply_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_postcheck_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_rollback_20260621_114447.sql`
- `lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`

Execution evidence:

- Precheck returned `ready_to_apply=t`.
- Apply returned `gift_rows=0`, `brainstone_rows=1`, `total_quantity=100`.
- Postcheck returned `postcheck_passed=t`, `deck_backup_rows=1`,
  `rule_backup_rows=1`, `brainstone_rule_verified=t`.
- Rollback script remains available and has not been executed.

Sync evidence:

- Rule sync report:
  `battle_card_rules_sqlite_from_pg_pg023_brainstone_20260621_114447.json`.
- Deck sync report:
  `sync_pg_target_deck_to_hermes_pg023_brainstone_20260621_114447.json`,
  `cards_written=100`, `quantity_written=100`,
  `deck_hash=c160e490b9e887d7b1f15ca6557be97d59b5aaff60bdee926805fd36359a6cbf`.

Battle validation:

- Smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_121648/summary.json`,
  `4/16`, trusted, clean gates.
- Full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`,
  `14/64`, trusted, clean gates.

Conclusion:

- PG023 is canonical current runtime state.
- Remaining action is not rollback; it is the next deck-consistency iteration
  against battle conversion under pressure. The earlier
  `forced_keep_after_bad_mulligan=13` signal is global table noise and should
  not be treated as Lorehold-only without decision-trace mapping.

## Learned Coherence Auditor Correction - 2026-06-21 10:39 -0300

Scope:

- No PostgreSQL apply, rollback, manual SQL write, deck swap, or sync command
  was performed.
- The only runtime-truth change was code-side audit interpretation:
  `server/bin/learned_deck_coherence_audit.py` now evaluates focused Lorehold
  strategy from `pg_saved_deck` when available.

Evidence:

- `learned_deck_coherence_audit_20260621_133919.json` reports
  `strategy_source=pg_saved_deck`, `strategy_passed=true`, and
  `strategy_issues=[]`.
- PG saved deck remains `100` rows / `100` quantity / `33` lands.

Deploy conclusion:

- No new PostgreSQL deploy is pending from the old big-spell coherence gap.
- PG023 remains the canonical deployed deck state until a fresh candidate beats
  it in trusted battle validation.

## Focused Zone Transition No-Deploy Checkpoint - 2026-06-21 11:03 -0300

Scope:

- Latest battle symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_140346/summary.json`.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, or file
  deletion.

Evidence:

- `140346` is `run_profile=focused_zone_transition_fix_v3`,
  `run_scope=focused_seed`, `seeds_completed=1/1`.
- Final status is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`.
- Gate/test counts: target-pressure `pass=1`, table-intent `pass=1`,
  test results `pass=18`.
- Local SQLite deck `6` remains `100` rows / `100` quantity and focused card
  check confirms `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `140346`.
- PG023 remains the current deployed deck state; the focused run only validates
  runtime support for zone transition behavior.

## PG023 Combat-Survival Rebaseline No-Deploy Checkpoint - 2026-06-21 11:30 -0300

Scope:

- Latest battle symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_142400/summary.json`.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, or file
  deletion.

Evidence:

- `142400` is `run_profile=pg023_rebaseline_after_combat_survival_16_seed`,
  `run_scope=recurring_full`, `seeds_completed=16/16`.
- Final status is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`.
- Gate/test counts: target-pressure `pass=16`, table-intent `pass=16`,
  test results `pass=18`.
- Strategy counts: `forced_keep_after_bad_mulligan=2`, medium severity `2`.
- Outcome: Lorehold target wins `1/16`, opponents `15/16`.
- Local SQLite deck `6` remains `100` rows / `100` quantity and focused card
  check confirms `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `142400`.
- No rollback is proven by this sample: the run is gate-clean and SQLite still
  matches the PG023 Brainstone shape.
- The result should feed the next deck-strategy iteration, not a DB mutation.

## PG023 Priority-Fix And Angel's Grace No-Deploy Checkpoint - 2026-06-21 12:04 -0300

Scope:

- Latest battle symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_145948/summary.json`.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, or file
  deletion.

Evidence:

- Recent PG023 rebaselines remain gate-clean but weak:
  `140846` Lorehold `2/16`, `141620` Lorehold `1/16`, and `145423` Lorehold
  `1/16`.
- Angel's Grace candidate before priority fix, `144336`, was blocked by
  `forensic_audit=blocked`.
- Angel's Grace candidate after priority fix, `145948`, is trusted with clean
  gates and tests `pass=18`, but only reaches Lorehold `2/16` with
  `forced_keep_after_bad_mulligan=3`.
- SQLite restored after the runner: deck `6` has `100` rows / `100` quantity
  and includes `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `145948`.
- Angel's Grace over Boros Charm is rejected as a deploy candidate.
- PG023 remains the deployed deck shape; this is strategy evidence only.

## Latest Manual 16-Seed Review No-Deploy Checkpoint - 2026-06-21 12:35 -0300

Scope:

- Latest battle symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_151645/summary.json`.
- An external runner was still active at read time.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, file deletion,
  or runner termination.

Evidence:

- `151645` reports `battle_replay_final_status=review_required`.
- Mandatory divergences:
  `forensic_audit=review_required`, `replay_decision_audit=review_required`,
  and `strategy_audit=review_required`.
- Target-pressure/table-intent/tests pass: `16`, `16`, and `18`.
- Strategy findings: `strategy_review_required_findings=4`, medium severity
  `7`, low severity `1`.
- Outcome remains poor: Lorehold `1/16`, opponents `12/16`.
- SQLite check at read time: deck `6` is `100` rows / `100` quantity and
  includes `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `151645`.
- No rollback is proven. This is battle/auditor review evidence, not DB drift.

## PG023 Oracle-Specific Finisher Contract No-Deploy Checkpoint - 2026-06-21 12:37 -0300

Scope:

- Latest battle symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_152154/summary.json`.
- No external battle runner was active at final read time.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, file deletion,
  or runner termination.

Evidence:

- `152154` reports `battle_replay_final_status=trusted_for_strategy_learning`
  and `mandatory_gate_divergences=[]`.
- Target-pressure/table-intent/tests pass: `16`, `16`, and `18`.
- Strategy review findings are `0`; residual strategy signal is
  `forced_keep_after_bad_mulligan=2`.
- Outcome remains poor: Lorehold `1/16`, opponents `14/16`.
- SQLite check: deck `6` is `100` rows / `100` quantity and includes
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `152154`.
- No rollback is proven. The result is trusted battle evidence for continued
  deck-strategy work only.

## Magus Candidate No-Deploy Checkpoint - 2026-06-21 13:03 -0300

Scope:

- Latest battle symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_153944/summary.json`.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, or file
  deletion.

Evidence:

- `153944` is blocked by `mandatory_gate_divergences=["strategy_audit=blocked"]`.
- Target-pressure/table-intent/tests pass, but strategy has `high=1` and
  `medium=3` findings.
- Candidate result: Lorehold `3/16`, opponents `12/16`.
- SQLite restored to PG023 focused shape: deck `6` `100/100`,
  `Electroduplicate=1`, no focused `Magus of the Moat` row.
- Backup artifact observed:
  `knowledge_db_backup_candidate_magus_over_electroduplicate_20260621_123935.sqlite`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `153944`.
- Magus over Electroduplicate is a blocked candidate, not a deploy candidate.

## Magus Candidate After Mox Trace Fix No-Deploy Checkpoint - 2026-06-21 13:19 -0300

Scope:

- Latest battle symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_160405/summary.json`.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, or file
  deletion.

Evidence:

- `160405` is trusted with `mandatory_gate_divergences=[]`.
- Target-pressure/table-intent/tests pass at `16`, `16`, and `18`.
- Candidate result: Lorehold `3/16`, opponents `12/16`.
- SQLite restored to PG023 focused shape: deck `6` `100/100`,
  `Electroduplicate=1`, no focused `Magus of the Moat` row.
- Backup artifact observed:
  `knowledge_db_backup_candidate_magus_over_electroduplicate_20260621_160258.sqlite`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `160405`.
- Magus over Electroduplicate is rejected as a deploy candidate because it does
  not beat the PG023 smoke baseline.

## Victory Chimes No-Deploy Checkpoint - 2026-06-21 13:52 -0300

Scope:

- Observed local Victory Chimes reviewed-rule and SQLite sync artifacts plus
  latest battle artifacts `20260621_164101` and `20260621_164710`.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap command, commit, push, cleanup, stash, revert, or deletion.

Evidence:

- `Victory Chimes` is corrected locally from stale curated `draw_engine` to
  verified curated `ramp_permanent`.
- Sync artifact
  `victory_chimes_reviewed_rule_sqlite_sync_20260621_161900.json` is local
  SQLite evidence: `apply=true`, `inserted_or_updated=122`,
  `deleted_stale_reviewed_rows=1`, `canonical_snapshot_rows_exported=3201`.
- Latest battle `20260621_164710` is trusted with clean mandatory gates,
  target-pressure `pass=16`, table-intent `pass=16`, tests `pass=18`,
  Lorehold `2/16`, opponents `13/16`.
- Final SQLite deck check is `100/100` and restored to PG023 focused shape:
  `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, no focused
  `Magus of the Moat`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by the Victory Chimes correction or the
  `164710` battle artifact.
- PG023 remains closed; current work remains deck strategy quality, not a DB
  deploy or rollback.

## Magus Same-Seed Candidate No-Deploy Checkpoint - 2026-06-21 14:38 -0300

Evidence:

- Battle latest advanced to `20260621_173334`.
- `173334` is trusted and gate-clean:
  `run_profile=candidate_magus_after_victory_chimes_fix_same_seed_16_seed`,
  `seeds_completed=16/16`, `mandatory_gate_divergences=[]`,
  target-pressure/table-intent/tests `16/16/18`.
- Candidate result: Lorehold `3/16`, opponents `12/16`.
- Final SQLite deck check is restored to PG023 focused shape:
  `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, no focused
  `Magus of the Moat`.
- Backup artifact observed:
  `knowledge_db_backup_candidate_magus_after_victory_fix_same_seed_20260621_165700.sqlite`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `173334`.
- Magus remains rejected as a deploy candidate because it does not beat the
  PG023 smoke baseline.

## Runtime Cache Drift No-Deploy Checkpoint - 2026-06-21 14:42 -0300

Evidence:

- Battle latest remains `20260621_173334`; no new completed battle artifact
  validates the current runtime cache.
- Current local SQLite deck `6` now has `Magus of the Moat` and
  `Sphere of Safety`, while the new backup
  `knowledge_db_backup_candidate_magus_sphere_after_victory_fix_20260621_174200.sqlite`
  preserves `Electroduplicate` and `Victory Chimes`.

Deploy conclusion:

- This is a local runtime-cache drift/candidate state, not a PostgreSQL deploy
  or rollback signal.
- No PostgreSQL deploy item is opened. Do not apply or restore without explicit
  approval of the exact command.

## Magus+Sphere Candidate No-Deploy Checkpoint - 2026-06-21 14:46 -0300

Evidence:

- Battle latest advanced to `20260621_174142`.
- `174142` is review-required, not deployable:
  `mandatory_gate_divergences=["forensic_audit=review_required","replay_decision_audit=review_required","strategy_audit=review_required"]`.
- Target-pressure/table-intent/tests pass at `16/16/18`, but strategy has
  `strategy_review_required_findings=1`.
- Candidate result: Lorehold `5/16`, opponents `11/16`.
- Final SQLite deck check is restored to PG023/Victory focused shape:
  `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, no focused
  `Magus of the Moat` or `Sphere of Safety`.

Deploy conclusion:

- No PostgreSQL deploy item is opened by `174142`.
- Magus+Sphere is rejected until the review-required gates have concrete
  closure evidence and explicit deploy authorization exists.

## Mental Misstep Runtime Waiver No-Deploy Checkpoint - 2026-06-22 12:48 UTC

Evidence:

- A focused replay before correction showed `Mental Misstep` illegally
  countering `Windborn Muse`, even though `Mental Misstep` should only counter
  mana value `1`.
- Runtime correction in `battle_analyst_v9.py` now scopes `Mental Misstep` with
  `counter_target_cmc=1` and filters counterspell targets by mana value.
- Regression coverage in `battle_stack_casting_tests.py` verifies that `Mental
  Misstep` cannot counter `Windborn Muse` but can counter `Esper Sentinel`.
- Full post-correction artifact
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_124815/summary.json`
  is trusted, gate-clean, and has tests `pass=18`.

Deploy conclusion:

- No PostgreSQL apply, rollback, or sync was executed in this checkpoint.
- This is a durable-source pending item: if the runtime waiver is accepted, the
  next PostgreSQL package should promote `Mental Misstep` target legality into
  `card_battle_rules` and then sync SQLite/Hermes from PostgreSQL.

## PG024 Mental Misstep Target Rule - applied_validated - 2026-06-22 13:07 UTC

Scope:

- Promote `Mental Misstep` target legality into PostgreSQL `card_battle_rules`.
- Remove dependency on the temporary runtime waiver for this card.
- Sync SQLite/Hermes from PostgreSQL after apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_precheck_20260622_130251.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_apply_20260622_130251.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_postcheck_20260622_130251.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/mental_misstep_target_rule_pg024_rollback_20260622_130251.sql`
- Validation report:
  `docs/hermes-analysis/master_optimizer_reports/mental_misstep_pg024_deploy_validation_20260622_130732.md`

Precheck:

- `card_rows=1`
- `expected_oracle_hash_rows=1`
- `exact_target_rule_rows=0`
- `broad_enabled_counter_rows=2`

Apply result:

- Inserted/updated curated verified/auto rule
  `battle_rule_v1:da6a568dbdfeda5d4009574d953db55e`.
- `effect_json` includes `counter_target_cmc=1` and
  `battle_model_scope=mental_misstep_mana_value_one_counter_v1`.
- Disabled broad counter rows
  `battle_rule_v1:62ec2df5de2fe17782f94df13896b536` and
  `battle_rule_v1:d47cbde8d1dc5678060e25ea1b620a82`.

Postcheck:

- `exact_executable_rule_rows=1`
- `broad_enabled_counter_rows=0`
- `card_intelligence_snapshot` reflects the restricted rule and disabled broad
  rows.

SQLite/Hermes sync:

- Command:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Mental Misstep" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg024_mental_misstep_20260622_130535.json`
- Result:
  `pg_rows_loaded=3`, `sqlite_inserted_or_updated=3`,
  `canonical_snapshot_rows_exported=3193`.

Validation:

- Runtime check resolved `Mental Misstep` from SQLite/PG with
  `_rule_logical_key=battle_rule_v1:da6a568dbdfeda5d4009574d953db55e`.
- Focused battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130646/summary.json`,
  trusted, gate-clean, tests `pass=18`.
- Full battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130732/summary.json`,
  trusted, gate-clean, `16/16`, tests `pass=18`.

Rollback:

- Rollback SQL exists and restores the captured pre-apply `Mental Misstep`
  `card_battle_rules` rows from
  `manaloom_deploy_audit.pg024_mental_misstep_target_rule_20260622_130251`.
- Rollback was not executed because postcheck, SQLite sync, runtime check,
  focused battle, and full battle passed.

## PG025 The One Ring and Orim's Chant Battle Rules - applied_validated - 2026-06-22 15:29 UTC

Scope:

- Promote `The One Ring` ETB/cast protection, no-ETB-draw, burden upkeep life
  loss, and activated burden draw into PostgreSQL `card_battle_rules`.
- Promote `Orim's Chant` kicked attack prevention into PostgreSQL
  `card_battle_rules`.
- Sync SQLite/Hermes from PostgreSQL after apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_precheck_20260622_152115.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_apply_20260622_152115.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_postcheck_20260622_152115.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_battle_rules_pg025_rollback_20260622_152115.sql`
- Validation report:
  `docs/hermes-analysis/master_optimizer_reports/one_ring_orims_pg025_deploy_validation_20260622_152901.md`

Precheck:

- `one_ring_card_rows=1`
- `one_ring_expected_oracle_hash_rows=1`
- `one_ring_exact_rule_rows=0`
- `one_ring_legacy_draw_engine_rows=1`
- `orims_chant_card_rows=1`
- `orims_chant_expected_oracle_hash_rows=1`
- `orims_chant_exact_rule_rows=0`
- `orims_chant_legacy_silence_rows=2`

Apply result:

- Inserted/updated `The One Ring` curated verified/auto rule
  `battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1`.
- Inserted/updated `Orim's Chant` curated verified/auto rule
  `battle_rule_v1:2332a82b6395a065b6516702d3e326c7`.
- Disabled one legacy `The One Ring` broad `draw_engine` row and two legacy
  `Orim's Chant` broad silence rows.

Postcheck:

- `one_ring_exact_executable_rule_rows=1`
- `one_ring_legacy_enabled_draw_engine_rows=0`
- `orims_chant_exact_executable_rule_rows=1`
- `orims_chant_legacy_enabled_silence_rows=0`
- `card_intelligence_snapshot` reflects the exact rules and disabled legacy
  rows.

SQLite/Hermes sync:

- Command:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "The One Ring" --only-card "Orim's Chant" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg025_one_ring_orims_20260622_152500.json`
- Result:
  `pg_rows_loaded=6`, `sqlite_inserted_or_updated=6`,
  `canonical_snapshot_rows_exported=3193`.

Validation:

- Runtime resolves `The One Ring` from SQLite/PG with
  `_rule_logical_key=battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1`.
- Runtime resolves `Orim's Chant` from SQLite/PG with
  `_rule_logical_key=battle_rule_v1:2332a82b6395a065b6516702d3e326c7`.
- Controlled battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_152901/summary.json`,
  trusted, gate-clean, `seeds_completed=16`, tests `pass=18`.
- Deck result remains unresolved in the comparable window: Lorehold `0/16`,
  opponents `16/16`, pressure to Lorehold `296`, pressure to others `4`.

Rollback:

- Rollback SQL exists and restores the captured pre-apply rows from
  `manaloom_deploy_audit.pg025_one_ring_orims_battle_rules_20260622_152115`.
- Rollback was not executed because postcheck, SQLite sync, runtime check,
  tests, and battle validation passed.

## PG026 Lorehold Magus+Sphere Deck Swap - applied_validated - 2026-06-22 17:09 UTC

Scope:

- Promote the tested Lorehold deck candidate into PostgreSQL deck
  `528c877f-f829-4207-95e6-73981776c323`.
- Remove `Electroduplicate` and `Victory Chimes`.
- Add `Magus of the Moat` and `Sphere of Safety`.
- Sync Hermes SQLite deck `6` from PostgreSQL and run the official 16-seed
  battle gate without a temporary deck swap.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_precheck_20260622_165810.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_apply_20260622_165810.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_postcheck_20260622_165810.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_rollback_20260622_165810.sql`
- Validation report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_pg026_deploy_validation_20260622_170304.md`

Data evidence:

- PostgreSQL precheck confirmed deck rows/quantity `100/100`,
  `Electroduplicate=1`, `Victory Chimes=1`, `Magus of the Moat=0`, and
  `Sphere of Safety=0`.
- PostgreSQL apply inserted `2` backup rows into
  `manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810`
  and changed the deck to `Magus of the Moat=1`, `Sphere of Safety=1`,
  `Electroduplicate=0`, `Victory Chimes=0`, total quantity `100`.
- PostgreSQL postcheck confirmed deck rows/quantity `100/100` and backup rows
  `2`.
- SQLite sync report:
  `docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg026_magus_sphere_20260622_165810.json`,
  with `cards_written=100`, `quantity_written=100`,
  `sync_run_id=20260622T170115Z`,
  `deck_hash=d43fde9ac9ff60ba4a3578579c50c85c2d761b9057daa5979182ae31a65fa268`,
  and
  `ruleset_hash=89ad57eea9c9feabb93e9dd8b51bbb1a2d0d04dfa0d51429f18a070151a7180d`.

Battle evidence:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_170304/summary.json`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- `table_intent_statuses={"pass":16}` and
  `target_pressure_statuses={"pass":16}`.
- Lorehold improved to `6/16`; opponents won `10/16`.

Rollback:

- Rollback SQL exists and restores the two captured pre-apply deck rows from
  `manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810`.
- Rollback was not executed because postcheck, SQLite sync, and post-deploy
  battle validation passed.

## PG027 Lorehold Variant 01 Battle Rule Coverage - applied_validated - 2026-06-22 17:45 UTC

Scope:

- Promote reviewed/runtime-safe battle rules needed by `Lorehold Variant 01 -
  Rafael Paste 2026-06-22`.
- No deck swap was applied.
- No production deck contents were changed.
- PostgreSQL remained the source of truth; Hermes SQLite was refreshed from PG
  after apply.

Cards covered:

- `Archaeomancer's Map`, `Borrowed Knowledge`, `Chandra, Hope's Beacon`,
  `Combustible Gearhulk`, `Commander's Plate`, `Farewell`,
  `Hit the Mother Lode`, `Improvisation Capstone`, `Increasing Vengeance`,
  `Mithril Coat`, `Olórin's Searing Light`,
  `Ondu Inversion // Ondu Skyruins`, `Reckless Endeavor`,
  `Restoration Seminar`, `Reverse the Sands`, `Soulfire Eruption`,
  `Sunforger`, `Swiftfoot Boots`, `Thought Vessel`, `Tibalt's Trickery`,
  and `Wear // Tear`.

Package/evidence:

- Reviewed rules file updated:
  `docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.json`.
- PG apply report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant01_rule_sync_pg027_apply_pg_20260622_144406.json`.
- SQLite-from-PG report:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant01_rule_sync_pg027_sqlite_from_pg_20260622_144406.json`.
- Variant post-sync validation:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_staging_20260622_174505.json`.

Apply result:

- `selected_card_count=21`.
- `input_rows=22` because `Hit the Mother Lode` has two composable runtime
  rules.
- `pg_inserted_or_updated=22`.
- `pg_skipped_lower_priority=0`.
- Direct PG postcheck on `143.198.230.247:5433/halder`:
  `curated|active|auto|17`, `curated|verified|auto|5`,
  `generated|needs_review|review_only|42`.

SQLite/Hermes sync:

- `pg_rows_loaded=64`.
- `sqlite_inserted_or_updated=64`.
- `canonical_snapshot_rows_exported=3193`.
- Direct SQLite postcheck for the same selected cards:
  `active|auto|curated|17`, `verified|auto|curated|5`,
  `needs_review|review_only|generated|42`.

Runtime/test evidence:

- `python3 -m py_compile` passed for
  `battle_analyst_v9.py`, `battle_card_specific_tests.py`,
  `battle_rule_registry.py`, `reviewed_battle_card_rules.py`,
  `sync_battle_card_rules.py`, and `sync_battle_card_rules_pg.py`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  passed: `Ran 25 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Variant 01 post-sync staging is clean:
  `variants=1 valid=1 invalid=0`, `issue_count=0`, `warning_count=0`.
- Direct Variant 01 SQLite proof:
  unique staged rows `81`, executable-rule rows `81`, oracle-matched rows `81`.

Rollback:

- No rollback executed because PG apply, SQLite sync, direct postchecks, unit
  tests, and Variant 01 validation passed.
- If rollback is needed, revert this PG027 batch by removing/disabling the 22
  curated rows whose source is `curated`, review/execution status is
  `active|verified`/`auto`, and whose card names are listed above; then rerun
  SQLite-from-PG sync for those same cards.

## PG028 Austere Command Battle Rule - applied_validated - 2026-06-22 19:10 UTC

Scope:

- Card: `Austere Command`.
- Reason: the existing trusted rule was a broad selective `board_wipe` without
  oracle hash or model scope, and the generated shadow row remained
  `needs_review`/`review_only`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_precheck_20260622_190701.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_apply_20260622_190701.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_postcheck_20260622_190701.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_battle_rule_pg028_rollback_20260622_190701.sql`.

Precheck:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_board_wipe_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg028_austere_command_battle_rule_20260622_190701`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64`.
- Stored oracle hash `bce631c9a75d6856dd8c0d7de442b47f`.
- Stored `battle_model_scope=austere_command_choose_two_destroy_modes_v1`.
- Disabled the old curated broad row and the generated shadow row as
  `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_board_wipe_rows=0`.
- Active executable rule is the new modal destroy rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg028_austere_command_20260622_190701.json`.
- `pg_rows_loaded=3`.
- `sqlite_inserted_or_updated=3`.
- `canonical_snapshot_rows_exported=3193`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_replay_summary_20260622_190701.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.

## PG029 Blasphemous Act Battle Rule - applied_validated - 2026-06-22 19:29 UTC

Scope:

- Card: `Blasphemous Act`.
- Reason: the existing trusted row was a broad `board_wipe` without oracle
  hash or model scope, and the generated shadow row remained
  `needs_review`/`review_only`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_precheck_20260622_192517.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_apply_20260622_192517.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_postcheck_20260622_192517.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_battle_rule_pg029_rollback_20260622_192517.sql`.

Precheck:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_wipe_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:56271789d639ef390213dbc90059e4d2`.
- Stored oracle hash `826022a579db4551b45ad35e4cfab973`.
- Stored `battle_model_scope=blasphemous_act_damage_13_each_creature_v1`.
- Disabled the old curated broad row and the generated shadow row as
  `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_wipe_rows=0`.
- Active executable rule is the new `damage_wipe` rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg029_blasphemous_act_20260622_192517.json`.
- `pg_rows_loaded=3`.
- `sqlite_inserted_or_updated=3`.
- `canonical_snapshot_rows_exported=3193`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/blasphemous_act_pg029_focused_replay_summary_20260622_192517.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.
- The rollback restores the two pre-PG029 rows from
  `manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517`
  and removes the new active rule.

## PG030 Boros Charm Battle Rule - applied_validated - 2026-06-22 19:42 UTC

Scope:

- Card: `Boros Charm`.
- Reason: the existing trusted row was a broad `modal_boros_charm` without
  oracle hash or model scope, and the generated `indestructible` shadow row
  remained `needs_review`/`review_only`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_precheck_20260622_193818.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_apply_20260622_193818.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_postcheck_20260622_193818.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_battle_rule_pg030_rollback_20260622_193818.sql`.

Precheck:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_modal_or_shadow_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg030_boros_charm_battle_rule_20260622_193818`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf`.
- Stored oracle hash `98a7be829075118b499a7c283a23501f`.
- Stored
  `battle_model_scope=boros_charm_choose_one_damage_indestructible_double_strike_v1`.
- Disabled the old curated broad row and the generated shadow row as
  `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_modal_or_shadow_rows=0`.
- Active executable rule is the new oracle-specific `modal_boros_charm` rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg030_boros_charm_20260622_193818.json`.
- `pg_rows_loaded=3`.
- `sqlite_inserted_or_updated=3`.
- `canonical_snapshot_rows_exported=3193`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/boros_charm_pg030_focused_replay_summary_20260622_193818.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.
- The rollback restores the two pre-PG030 rows from
  `manaloom_deploy_audit.pg030_boros_charm_battle_rule_20260622_193818`
  and removes the new active rule.

## PG031 Deflecting Swat Battle Rule - applied_validated - 2026-06-22 19:56 UTC

Scope:

- Card: `Deflecting Swat`.
- Reason: the existing trusted row was a broad `redirect_removal` without
  oracle hash or model scope, and the generated `draw_cards` shadow row
  remained `needs_review`/`review_only`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_precheck_20260622_195126.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_apply_20260622_195126.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_postcheck_20260622_195126.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_battle_rule_pg031_rollback_20260622_195126.sql`.

Precheck:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_redirect_or_shadow_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg031_deflecting_swat_battle_rule_20260622_195126`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:bac48343654a53205d790a8268bd2631`.
- Stored oracle hash `a34c89817f87f32bedfb3d66a5bdc672`.
- Stored
  `battle_model_scope=deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1`.
- Disabled the old curated broad row and the generated shadow row as
  `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_redirect_or_shadow_rows=0`.
- Active executable rule is the new oracle-specific `redirect_removal` rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg031_deflecting_swat_20260622_195126.json`.
- `pg_rows_loaded=3`.
- `sqlite_inserted_or_updated=3`.
- `canonical_snapshot_rows_exported=3193`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/deflecting_swat_pg031_focused_replay_summary_20260622_195126.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.
- The rollback restores the two pre-PG031 rows from
  `manaloom_deploy_audit.pg031_deflecting_swat_battle_rule_20260622_195126`
  and removes the new active rule.

## PG032 Flawless Maneuver Battle Rule - applied_validated - 2026-06-22 20:10 UTC

Scope:

- Card: `Flawless Maneuver`.
- Reason: the existing trusted row was a broad `indestructible` rule without
  oracle hash or model scope, and the generated shadow row remained
  `needs_review`/`review_only`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_precheck_20260622_200215.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_apply_20260622_200215.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_postcheck_20260622_200215.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_battle_rule_pg032_rollback_20260622_200215.sql`.

Precheck:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_indestructible_or_shadow_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg032_flawless_maneuver_battle_rule_20260622_200215`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:73622071c1ad89267708f914a0729bf2`.
- Stored oracle hash `fa955216fa827bf75c5b79dcbdb4b97e`.
- Stored
  `battle_model_scope=flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1`.
- Disabled the old curated broad row and the generated shadow row as
  `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_indestructible_or_shadow_rows=0`.
- Active executable rule is the new oracle-specific `indestructible` rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg032_flawless_maneuver_20260622_200215.json`.
- `pg_rows_loaded=3`.
- `sqlite_inserted_or_updated=3`.
- `canonical_snapshot_rows_exported=3193`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/flawless_maneuver_pg032_focused_replay_summary_20260622_200215.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.
- The rollback restores the two pre-PG032 rows from
  `manaloom_deploy_audit.pg032_flawless_maneuver_battle_rule_20260622_200215`
  and removes the new active rule.

## PG033 Land Tax Battle Rule - applied_validated - 2026-06-22 20:25 UTC

Scope:

- Card: `Land Tax`.
- Reason: the existing trusted row was a broad `passive` rule without oracle
  hash or model scope, and the generated shadow row remained
  `needs_review`/`review_only` as generic `tutor any`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_precheck_20260622_201417.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_apply_20260622_201417.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_postcheck_20260622_201417.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_battle_rule_pg033_rollback_20260622_201417.sql`.

Precheck:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_passive_or_shadow_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg033_land_tax_battle_rule_20260622_201417`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef`.
- Stored oracle hash `83b074e38da3e6c4eb6ec3e7568c914b`.
- Stored
  `battle_model_scope=land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1`.
- Disabled the old curated broad row and the generated shadow row as
  `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_passive_or_shadow_rows=0`.
- Active executable rule is the new oracle-specific `land_tax` rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg033_land_tax_20260622_201417.json`.
- `pg_rows_loaded=3`.
- `sqlite_inserted_or_updated=3`.
- `canonical_snapshot_rows_exported=3193`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/land_tax_pg033_focused_replay_summary_20260622_201417.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.
- The rollback restores the two pre-PG033 rows from
  `manaloom_deploy_audit.pg033_land_tax_battle_rule_20260622_201417`
  and removes the new active rule.

## PG034 Lightning Greaves Battle Rule - applied_validated - 2026-06-22 20:36 UTC

Scope:

- Card: `Lightning Greaves`.
- Reason: PostgreSQL had two trusted curated `equipment_haste_shroud` rows
  without oracle hash, and a generated `indestructible` shadow row remained
  `needs_review`/`review_only`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply, then re-synced after aligning the local reviewed-runtime cache to
  the new PG034 rule key.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_precheck_20260622_202908.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_apply_20260622_202908.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_postcheck_20260622_202908.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_battle_rule_pg034_rollback_20260622_202908.sql`.

Precheck:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_equipment_or_shadow_rows=3`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg034_lightning_greaves_battle_rule_20260622_202908`
  with the three pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac`.
- Stored oracle hash `4a4c71d3cc58637cf00a3d7fe2331353`.
- Stored
  `battle_model_scope=lightning_greaves_auto_attach_haste_shroud_equip_0_v1`.
- Disabled two old curated rows and the generated `indestructible` shadow row
  as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_equipment_or_shadow_rows=0`.
- Active executable rule is the new oracle-specific
  `equipment_haste_shroud` rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Initial post-apply report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg034_lightning_greaves_20260622_202908.json`.
- The initial selective sync exposed stale local reviewed-runtime filtering:
  SQLite still selected the old disabled curated key because
  `reviewed_battle_card_rules.json` had not been aligned to PG034.
- Corrected sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg034_lightning_greaves_retry_20260622_202908.json`.
- Corrected sync direct check: active SQLite rule
  `battle_rule_v1:5ea7f2a8349a93ea46e05b60ee8cdaac`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=4a4c71d3cc58637cf00a3d7fe2331353`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/lightning_greaves_pg034_focused_replay_summary_20260622_202908.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, corrected SQLite sync, focused tests, focused events, and auditor
  rerun passed.
- The rollback restores the three pre-PG034 rows from
  `manaloom_deploy_audit.pg034_lightning_greaves_battle_rule_20260622_202908`
  and removes the new active rule.

## PG035 Lorehold, the Historian Battle Rule - applied_validated - 2026-06-22 20:52 UTC

Scope:

- Card: `Lorehold, the Historian`.
- Reason: PostgreSQL had one trusted active passive row without oracle hash,
  `cmc=4.0`, and no `flying`; one old trusted generic `commander` row; and one
  generated `draw_engine` shadow row remained `needs_review`/`review_only`.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply, after aligning the local reviewed-runtime cache to the new PG035
  rule key.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_precheck_20260622_204549.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_apply_20260622_204549.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_postcheck_20260622_204549.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_battle_rule_pg035_rollback_20260622_204549.sql`.

Precheck:

- `card_rows=4`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=4`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_lorehold_rows=3`.
- `trusted_executable_without_oracle_hash_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg035_lorehold_historian_battle_rule_20260622_204549`
  with the three pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4`.
- Stored oracle hash `f1b6d4f38a533e56f0efb5a3f1547214`.
- Stored
  `battle_model_scope=lorehold_opponent_upkeep_miracle_v1`.
- Disabled the old `commander` row, the old `cmc=4.0` passive row, and the
  generated `draw_engine` shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_lorehold_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.
- Active executable rule is the new oracle-specific Lorehold miracle/rummage
  rule with `cmc=5.0`, `flying=true`, `haste=true`,
  `grants_miracle_cost=2`, and `opponent_upkeep_rummage=true`.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg035_lorehold_historian_20260622_204549.json`.
- `pg_rows_loaded=4`.
- `sqlite_inserted_or_updated=2`.
- Direct SQLite check selected the active PG035 rule
  `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=f1b6d4f38a533e56f0efb5a3f1547214`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_historian_pg035_focused_replay_summary_20260622_204549.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.
- The rollback restores the three pre-PG035 rows from
  `manaloom_deploy_audit.pg035_lorehold_historian_battle_rule_20260622_204549`
  and removes the new active rule.

## PG036 Past in Flames Battle Rule - applied_validated - 2026-06-22 21:11 UTC

Scope:

- Card: `Past in Flames`.
- Reason: PostgreSQL had one trusted broad `recursion` row without oracle hash
  or model scope, and one generated `needs_review`/`review_only` `recursion`
  shadow row. The broad executor would move instant/sorcery cards to hand,
  while the oracle grants temporary flashback in graveyard.
- PostgreSQL was the durable source. Hermes SQLite was synced from PG after
  the apply.

Package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_precheck_20260622_210425.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_apply_20260622_210425.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_postcheck_20260622_210425.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_battle_rule_pg036_rollback_20260622_210425.sql`.

Precheck:

- `card_rows=1`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_recursion_rows=2`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg036_past_in_flames_battle_rule_20260622_210425`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be`.
- Stored oracle hash `12f293d8d746fbc4e5ba80828919dec5`.
- Stored
  `battle_model_scope=past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1`.
- Disabled the old curated generic `recursion` row and the generated
  `recursion` shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_recursion_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.
- Active executable rule is the new oracle-specific
  `graveyard_flashback_grant` rule.
- Shadow rows remain present only as disabled/deprecated history.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg036_past_in_flames_20260622_210425.json`.
- `pg_rows_loaded=5278`.
- `sqlite_inserted_or_updated=5243`.
- Direct SQLite/runtime check selected the active PG036 rule
  `battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=12f293d8d746fbc4e5ba80828919dec5`.

Runtime/test evidence:

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_replay_summary_20260622_210425.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, focused tests, focused events, and auditor rerun
  passed.
- The rollback restores the two pre-PG036 rows from
  `manaloom_deploy_audit.pg036_past_in_flames_battle_rule_20260622_210425`
  and removes the new active rule.

## PG037 Path to Exile Battle Rule Deploy - 2026-06-22 21:22 UTC

PostgreSQL package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_precheck_20260622_212057.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_apply_20260622_212057.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_postcheck_20260622_212057.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/path_to_exile_battle_rule_pg037_rollback_20260622_212057.sql`.

Precheck:

- `card_rows=1`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_removal_rows=3`.
- `trusted_executable_without_oracle_hash_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg037_path_to_exile_battle_rule_20260622_212057`
  with the three pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd`.
- Stored oracle hash `861c960a37be744e45f13200349e2532`.
- Stored
  `battle_model_scope=path_to_exile_creature_exile_basic_land_compensation_annotation_v1`.
- Disabled the old curated active row, the old generic curated verified row,
  and the generated review-only shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_removal_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg037_path_to_exile_20260622_212057.json`.
- `pg_rows_loaded=5279`.
- `sqlite_inserted_or_updated=5243`.
- `canonical_snapshot_rows_exported=3201`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, tests, focused replay, and auditor rerun passed.
- The rollback restores the three pre-PG037 rows from
  `manaloom_deploy_audit.pg037_path_to_exile_battle_rule_20260622_212057`
  and removes the new active rule.

## PG038 Reverberate Battle Rule Deploy - 2026-06-22 21:43 UTC

PostgreSQL package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_precheck_20260622_213615.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_apply_20260622_213615.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_postcheck_20260622_213615.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_battle_rule_pg038_rollback_20260622_213615.sql`.

Precheck:

- `card_rows=1`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_copy_rows=2`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg038_reverberate_battle_rule_20260622_213615`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:0269136edf067f696c8576740b720e14`.
- Stored oracle hash `cbae05dee4261e3ed5412fd5f3591c17`.
- Stored
  `battle_model_scope=reverberate_copy_stack_instant_or_sorcery_new_targets_annotation_v1`.
- Disabled the stale curated copy row without `oracle_hash` and the generated
  review-only shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_copy_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg038_reverberate_20260622_213615.json`.
- `pg_rows_loaded=5280`.
- `sqlite_inserted_or_updated=5244`.
- `canonical_snapshot_rows_exported=3201`.

Runtime/test evidence:

- Runtime selected
  `battle_rule_v1:0269136edf067f696c8576740b720e14`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=cbae05dee4261e3ed5412fd5f3591c17`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_replay_summary_20260622_213615.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, tests, focused replay, and auditor rerun passed.
- The rollback restores the two pre-PG038 rows from
  `manaloom_deploy_audit.pg038_reverberate_battle_rule_20260622_213615`
  and removes the new active rule.

Caveat:

- `Reverberate` target reassignment remains `annotation_only`; PG038 proves
  stack copy creation/resolution, not dynamic retarget selection.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG039 Sensei's Divining Top Battle Rule Deploy - 2026-06-22 22:01 UTC

PostgreSQL package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_precheck_20260622_215306.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_apply_20260622_215306.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_postcheck_20260622_215306.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/senseis_divining_top_battle_rule_pg039_rollback_20260622_215306.sql`.

Precheck:

- `card_rows=1`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_topdeck_rows=3`.
- `trusted_executable_without_oracle_hash_rows=2`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg039_senseis_top_battle_rule_20260622_215306`
  with the three pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:70c8478871f352b46cee1af296117951`.
- Stored oracle hash `f2c5ac0f52963cd710470adc25cc6d7c`.
- Stored
  `battle_model_scope=senseis_top_reorder_draw_lorehold_first_draw_miracle_v1`.
- Disabled the old active curated row, old generic verified row, and generated
  review-only `draw_cards` shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_topdeck_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

SQLite/Hermes sync:

- Initial PG039 sync exposed the reviewed-runtime cache still allowing the old
  local Top key, so the local reviewed JSON was aligned with PG039 and the sync
  was repeated.
- Final report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg039_senseis_divining_top_retry_20260622_215306.json`.
- `pg_rows_loaded=5281`.
- `sqlite_inserted_or_updated=5244`.
- `canonical_snapshot_rows_exported=3201`.

Runtime/test evidence:

- Runtime selected
  `battle_rule_v1:70c8478871f352b46cee1af296117951`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=f2c5ac0f52963cd710470adc25cc6d7c`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/senseis_top_pg039_focused_replay_summary_20260622_215306.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, tests, focused replay, and auditor rerun passed.
- The rollback restores the three pre-PG039 rows from
  `manaloom_deploy_audit.pg039_senseis_top_battle_rule_20260622_215306`
  and removes the new active rule.

Caveat:

- Generic activated draw policy remains `annotation_only`; PG039 proves
  top-three reorder plus the restricted Lorehold first-draw miracle
  draw-put-self line.

## PG040 Swords to Plowshares Battle Rule Deploy - 2026-06-22 22:22 UTC

PostgreSQL package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_precheck_20260622_221254.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_apply_20260622_221254.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_postcheck_20260622_221254.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_battle_rule_pg040_rollback_20260622_221254.sql`.

Precheck:

- `card_rows=1`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_removal_rows=2`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg040_swords_to_plowshares_battle_rule_20260622_221254`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:379008f3f03f94258292123453e3041c`.
- Stored oracle hash `702f566e95dd477f5cf5a551e41e9df8`.
- Stored
  `battle_model_scope=swords_to_plowshares_creature_exile_life_equal_power_v1`.
- Disabled the stale curated generic executable row and the generated
  review-only shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_removal_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg040_swords_to_plowshares_20260622_221254.json`.
- `pg_rows_loaded=5282`.
- `sqlite_inserted_or_updated=5244`.
- `canonical_snapshot_rows_exported=3201`.

Runtime/test evidence:

- Runtime selected
  `battle_rule_v1:379008f3f03f94258292123453e3041c`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=702f566e95dd477f5cf5a551e41e9df8`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  passed (`Ran 25 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/swords_to_plowshares_pg040_focused_replay_summary_20260622_221254.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, tests, focused replay, and auditor rerun passed.
- The rollback restores the two pre-PG040 rows from
  `manaloom_deploy_audit.pg040_swords_to_plowshares_battle_rule_20260622_221254`
  and removes the new active rule.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG041 Teferi's Protection Battle Rule Deploy - 2026-06-22 22:41 UTC

PostgreSQL package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_precheck_20260622_223850.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_apply_20260622_223850.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_postcheck_20260622_223850.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_battle_rule_pg041_rollback_20260622_223850.sql`.

Precheck:

- `card_rows=1`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=1`.
- `exact_executable_rule_rows=0`.
- `legacy_enabled_phase_out_rows=2`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg041_teferis_protection_battle_rule_20260622_223850`
  with the two pre-existing rows.
- Inserted active executable rule
  `battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a`.
- Stored oracle hash `bdc0faecf4420dc6162c7e72e98cc0eb`.
- Stored
  `battle_model_scope=teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1`.
- Disabled the stale curated generic executable row and the generated
  review-only shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_executable_rule_rows=1`.
- `legacy_enabled_phase_out_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg041_teferis_protection_20260622_223850.json`.
- `pg_rows_loaded=5283`.
- `sqlite_inserted_or_updated=5244`.
- `canonical_snapshot_rows_exported=3201`.

Runtime/test evidence:

- Runtime selected
  `battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=bdc0faecf4420dc6162c7e72e98cc0eb`.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  passed (`Ran 25 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_replay_summary_20260622_223850.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, tests, focused replay, and auditor rerun passed.
- The rollback restores the two pre-PG041 rows from
  `manaloom_deploy_audit.pg041_teferis_protection_battle_rule_20260622_223850`
  and removes the new active rule.

Caveat:

- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG042 Valakut Awakening Battle Rule Deploy - 2026-06-22 23:01 UTC

PostgreSQL package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_precheck_20260622_225355.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_apply_20260622_225355.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_postcheck_20260622_225355.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg042_rollback_20260622_225355.sql`.

Precheck:

- `card_rows=1`.
- `distinct_oracle_ids=1`.
- `expected_oracle_hash_rows=1`.
- `exact_full_executable_with_hash_rows=0`.
- `exact_alias_executable_with_hash_rows=0`.
- `trusted_executable_without_oracle_hash_rows=4`.
- `legacy_enabled_rows=2`.
- `generated_review_only_shadow_rows=1`.

Apply result:

- Created backup table
  `manaloom_deploy_audit.pg042_valakut_awakening_battle_rule_20260622_225355`
  with the five pre-existing rows.
- Activated the split-name executable rule
  `battle_rule_v1:6e1f3b876822abafe1de47610f46858d` with oracle hash
  `22b42fcc181b7aed71f78b2e1e51e887`.
- Activated the front-face alias rule
  `battle_rule_v1:245b8d2627720fadfd7a30464d07605a` with the same oracle hash.
- Disabled the two legacy curated rows without `oracle_hash`/scope and the
  generated `draw_cards` shadow row as `deprecated`/`disabled`.

Postcheck:

- `exact_full_executable_with_hash_rows=1`.
- `exact_alias_executable_with_hash_rows=1`.
- `legacy_enabled_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.
- `generated_review_only_shadow_rows=0`.

SQLite/Hermes sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg042_valakut_awakening_20260622_225355.json`.
- `pg_rows_loaded=5283`.
- `sqlite_inserted_or_updated=5244`.
- `canonical_snapshot_rows_exported=3201`.

Runtime/test evidence:

- Runtime selected
  `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`,
  `source=curated`, `review_status=active`, `execution_status=auto`,
  `oracle_hash=22b42fcc181b7aed71f78b2e1e51e887`.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  passed (`Ran 25 tests`).
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py`
  passed (`Ran 5 tests`).
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_replay_summary_20260622_225355.md`.

Rollback:

- Rollback SQL was generated but not executed because precheck, apply,
  postcheck, SQLite sync, tests, focused replay, and auditor rerun passed.
- The rollback restores the five pre-PG042 rows from
  `manaloom_deploy_audit.pg042_valakut_awakening_battle_rule_20260622_225355`.

Caveats:

- PG042 proves Valakut Awakening's instant hand-filter behavior. It does not
  claim a land-play/tapped-red-mana executor for `Valakut Stoneforge`; that
  remains split-name MDFC metadata for runtime lookup.
- `Blasphemous Act` cost reduction `{1}` per creature remains
  `annotation_only`; PG029 proved the 13-damage creature wipe executor, not a
  dynamic cost-reduction executor.

## PG043 Wheel of Fortune Battle Rule Deploy - 2026-06-22 23:26 UTC

Status:

- `applied_validated`.
- PostgreSQL source of truth updated; Hermes SQLite/cache resynced from
  PostgreSQL after apply.

Applied package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_precheck_20260622_231859.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_apply_20260622_231859.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_postcheck_20260622_231859.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_battle_rule_pg043_rollback_20260622_231859.sql`.

Precheck evidence:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `legacy_curated_executable_without_hash_rows=1`.
- `generated_review_only_shadow_rows=1`.
- `trusted_draw_without_model_scope_rows=1`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply evidence:

- Backup table:
  `manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859`.
- Backup row count: `2`.
- Inserted active oracle-hashed rule:
  `battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3`.
- Disabled old rows:
  `battle_rule_v1:402155f35799993b812ca441586017cd` and
  `battle_rule_v1:3bd7f7866ce30619d4d92b4e9e7b520e`.

Postcheck evidence:

- `oracle_hashed_multiplayer_wheel_rows=1`.
- `legacy_or_shadow_enabled_rows=0`.
- `generated_review_only_shadow_rows=0`.
- `trusted_draw_without_model_scope_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

Post-apply sync/audit:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg043_wheel_of_fortune_20260622_231859.json`.
- Final SQLite-from-PG sync after PG044 correction:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg044_valakut_hash_refresh_20260622_232411.json`.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_232608.json`.
- Final counts: `high=81`, `medium=39`, `pass=25`.
- `Wheel of Fortune` reports `pass`.

Rollback:

- `wheel_of_fortune_battle_rule_pg043_rollback_20260622_231859.sql`
  deletes the current Wheel rows and restores the two pre-PG043 rows from
  `manaloom_deploy_audit.pg043_wheel_of_fortune_battle_rule_20260622_231859`.

## PG044 Valakut Awakening Hash Refresh Deploy - 2026-06-22 23:26 UTC

Status:

- `applied_validated`.
- Corrective metadata refresh after the post-PG043 auditor showed Valakut
  reopened as `medium` because PostgreSQL still had trusted executable rows
  without `oracle_hash`.

Applied package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_precheck_20260622_232411.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_apply_20260622_232411.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_postcheck_20260622_232411.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_battle_rule_pg044_hash_refresh_rollback_20260622_232411.sql`.

Precheck evidence:

- `card_rows=1`.
- `expected_oracle_hash_rows=1`.
- `full_rule_missing_hash_rows=1`.
- `alias_rule_missing_hash_rows=1`.
- `generated_shadow_review_rows=1`.

Apply evidence:

- Backup table:
  `manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411`.
- Backup row count: `5`.
- Updated rows: full-name rule, front-face alias rule, and generated shadow.

Postcheck evidence:

- `exact_full_executable_with_hash_rows=1`.
- `exact_alias_executable_with_hash_rows=1`.
- `generated_review_only_shadow_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.
- Final auditor reports `Valakut Awakening // Valakut Stoneforge` as `pass`.

Rollback:

- `valakut_awakening_battle_rule_pg044_hash_refresh_rollback_20260622_232411.sql`
  restores the five pre-PG044 Valakut rows from
  `manaloom_deploy_audit.pg044_valakut_awakening_hash_refresh_20260622_232411`.

## PG045 Aetherflux Reservoir Battle Rule Deploy - 2026-06-22 23:40 UTC

Status:

- `applied_validated`.
- Durable correction for `Aetherflux Reservoir`, which had a trusted generic
  `finisher` row without `oracle_hash`/`battle_model_scope` plus a generated
  `needs_review`/`review_only` shadow row.

Applied package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_precheck_20260622_233656.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_apply_20260622_233656.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_postcheck_20260622_233656.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/aetherflux_reservoir_battle_rule_pg045_rollback_20260622_233656.sql`.

Precheck evidence:

- `card_rows=1`.
- `oracle_hash_rows=1`.
- `target_rule_rows_before=0`.
- `legacy_generic_enabled_rows=1`.
- `generated_review_only_shadow_rows=1`.
- `trusted_finisher_without_model_scope_rows=1`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply evidence:

- Backup table:
  `manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656`.
- Backup row count: `2`.
- Inserted active oracle-hashed rule:
  `battle_rule_v1:3147dc90542c79e439ca1f77df02e4e5`.
- Disabled old rows:
  `battle_rule_v1:3895145eecb0a2ac9b7805febd67ea54` and
  `battle_rule_v1:53d7252f111b777ddf7ff42a275c4a38`.

Postcheck evidence:

- `oracle_hashed_aetherflux_lifegain_rows=1`.
- `legacy_or_shadow_enabled_rows=0`.
- `generated_review_only_shadow_rows=0`.
- `trusted_finisher_without_model_scope_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

Post-apply sync/audit:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg045_aetherflux_reservoir_20260622_233656.json`.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260622_234015.json`.
- Final counts: `high=80`, `medium=39`, `pass=26`.
- `Aetherflux Reservoir` reports `pass`.

Rollback:

- `aetherflux_reservoir_battle_rule_pg045_rollback_20260622_233656.sql`
  deletes the current Aetherflux rows and restores the two pre-PG045 rows from
  `manaloom_deploy_audit.pg045_aetherflux_reservoir_battle_rule_20260622_233656`.

## PG046 Approach of the Second Sun Battle Rule Deploy - 2026-06-23 00:02 UTC

Status:

- `applied_validated`.
- Durable correction for `Approach of the Second Sun`, which had trusted
  executable no-hash rows and a generated `needs_review`/`review_only` shadow
  row. PostgreSQL is the source of truth; Hermes SQLite was resynced only
  after the PG postcheck passed.

Applied package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_precheck_20260622_235039.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_apply_20260622_235039.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_postcheck_20260622_235039.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/approach_second_sun_battle_rule_pg046_rollback_20260622_235039.sql`.

Precheck evidence:

- `card_rows=1`.
- `oracle_hash_rows=1`.
- `target_rule_rows_before=0`.
- `legacy_trusted_enabled_rows=2`.
- `generated_review_only_shadow_rows=1`.
- `trusted_executable_without_oracle_hash_rows=2`.

Apply evidence:

- Backup table:
  `manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039`.
- Backup row count: `3`.
- Inserted active oracle-hashed rule:
  `battle_rule_v1:ed74fb069b6c1d635392d907804a1d98`.
- Disabled old rows:
  `battle_rule_v1:c9594094630e58aa220dd4e82309f597`,
  `battle_rule_v1:d89b90f224cfa72e048c8adef2f80185`, and
  `battle_rule_v1:6e281d363c92040c064cda01b445b596`.

Postcheck evidence:

- `oracle_hashed_approach_second_cast_rows=1`.
- `legacy_or_shadow_enabled_rows=0`.
- `generated_review_only_shadow_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

Post-apply sync/audit:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg046_approach_second_sun_20260622_235039.json`.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_000228.json`.
- Final counts: `high=79`, `medium=39`, `pass=27`.
- `Approach of the Second Sun` reports `pass`.

Rollback:

- `approach_second_sun_battle_rule_pg046_rollback_20260622_235039.sql`
  deletes the current Approach rows and restores the three pre-PG046 rows from
  `manaloom_deploy_audit.pg046_approach_second_sun_battle_rule_20260622_235039`.

## PG047 Archaeomancer's Map Battle Rule Deploy - 2026-06-23 00:17 UTC

Status:

- `applied_validated`.
- Durable correction for `Archaeomancer's Map`, which had one trusted
  executable no-hash/no-scope row and two generated `needs_review`/
  `review_only` shadow rows. PostgreSQL is the source of truth; Hermes SQLite
  was resynced only after the PG postcheck passed.

Applied package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_precheck_20260623_001244.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_apply_20260623_001244.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_postcheck_20260623_001244.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/archaeomancers_map_battle_rule_pg047_rollback_20260623_001244.sql`.

Precheck evidence:

- `card_rows=1`.
- `oracle_hash_rows=1`.
- `target_rule_rows_before=0`.
- `legacy_trusted_enabled_rows=1`.
- `generated_review_only_shadow_rows=2`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply evidence:

- Backup table:
  `manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244`.
- Backup row count: `3`.
- Inserted active oracle-hashed rule:
  `battle_rule_v1:69acc8f6ed179a5a32bef08190cd747e`.
- Disabled old rows:
  `battle_rule_v1:a2cbd7e64ee611d7284e4aa326e06d36`,
  `battle_rule_v1:d8dfc058ea5870cde290c3d57dc34849`, and
  `battle_rule_v1:f1fec28b4adc813d6a8a0a5722c288cd`.

Postcheck evidence:

- `oracle_hashed_archaeomancers_map_rows=1`.
- `legacy_or_shadow_enabled_rows=0`.
- `generated_review_only_shadow_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

Post-apply sync/audit:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg047_archaeomancers_map_20260623_001244.json`.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_001717.json`.
- Final counts: `high=78`, `medium=39`, `pass=28`.
- `Archaeomancer's Map` reports `pass`.

Rollback:

- `archaeomancers_map_battle_rule_pg047_rollback_20260623_001244.sql`
  deletes the current Archaeomancer's Map rows and restores the three
  pre-PG047 rows from
  `manaloom_deploy_audit.pg047_archaeomancers_map_battle_rule_20260623_001244`.

## PG048 Blind Obedience Battle Rule Deploy - 2026-06-23 00:35 UTC

Status:

- `applied_validated`.
- Durable correction for `Blind Obedience`, which had one trusted executable
  no-hash row and one generated `needs_review`/`review_only` shadow row.
  PostgreSQL is the source of truth; Hermes SQLite was resynced only after the
  PG postcheck passed.

Applied package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_precheck_20260623_003029.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_apply_20260623_003029.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_postcheck_20260623_003029.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/blind_obedience_battle_rule_pg048_rollback_20260623_003029.sql`.

Precheck evidence:

- `card_rows=1`.
- `oracle_hash_rows=1`.
- `target_rule_rows_before=0`.
- `legacy_trusted_enabled_rows=1`.
- `generated_review_only_shadow_rows=1`.
- `trusted_executable_without_oracle_hash_rows=1`.

Apply evidence:

- Backup table:
  `manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029`.
- Backup row count: `2`.
- Inserted active oracle-hashed rule:
  `battle_rule_v1:40f23fcea3b7955bacd550a9090c6872`.
- Disabled old rows:
  `battle_rule_v1:44f3e6ff98ac438be56aa74272b47f93` and
  `battle_rule_v1:81701a2e0221de09cf7cf5ba202a3ef0`.

Postcheck evidence:

- `oracle_hashed_blind_obedience_rows=1`.
- `legacy_or_shadow_enabled_rows=0`.
- `generated_review_only_shadow_rows=0`.
- `trusted_executable_without_oracle_hash_rows=0`.

Post-apply sync/audit:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg048_blind_obedience_20260623_003029.json`.
- Final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_20260623_003552.json`.
- Final counts: `high=77`, `medium=40`, `pass=28`.
- `Blind Obedience` reports `pass`.

Rollback:

- `blind_obedience_battle_rule_pg048_rollback_20260623_003029.sql`
  deletes the current Blind Obedience rows and restores the two pre-PG048 rows
  from
  `manaloom_deploy_audit.pg048_blind_obedience_battle_rule_20260623_003029`.

## PG049 Deck 6 L2 Hash-Only Batch Deploy - 2026-06-23 00:49 UTC

Status:

- `applied_validated`.
- Durable metadata cleanup for official Lorehold deck `6` L2 hash-only lane.
  PostgreSQL is the source of truth; Hermes SQLite was resynced only after the
  PG postcheck passed.
- No deck swap, commit, push, or runtime behavior change was executed.

Applied package:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_precheck_20260623_004614.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_apply_20260623_004614.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_postcheck_20260623_004614.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/deck6_l2_hash_only_batch_pg049_rollback_20260623_004614.sql`.

Target rows:

- `Crawlspace` active rule
  `battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591`.
- `Ghostly Prison` active rule
  `battle_rule_v1:99151859bece89ba3ead032e05b1f65a`.
- `Valakut Awakening` active alias rule
  `battle_rule_v1:245b8d2627720fadfd7a30464d07605a`.
- `Valakut Awakening // Valakut Stoneforge` active split-name rule
  `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`.
- Valakut generated disabled shadow
  `battle_rule_v1:1bd5dce7cffed8d0af007d20b15e8549`.

Precheck evidence:

- `card_rows=3`.
- `oracle_hash_rows=3`.
- `target_trusted_missing_hash_rows=4`.
- `valakut_generated_disabled_shadow_rows=1`.

Apply evidence:

- Backup table:
  `manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614`.
- Backup row count: `9`.
- Updated active oracle hashes: `4`.
- Deprecated generated Valakut shadow rows: `1`.

Postcheck evidence:

- `crawlspace_hashed_rows=1`.
- `ghostly_prison_hashed_rows=1`.
- `valakut_hashed_rows=2`.
- `target_trusted_missing_hash_rows=0`.
- `valakut_generated_review_only_shadow_rows=0`.

Post-apply sync/audit:

- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg049_deck6_l2_hash_only_20260623_004614.json`.
- Deck 6 final auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_20260623_004857.json`.
- Deck 6 final counts: `high=41`, `medium=30`, `pass=29`.
- Deck 606 separate auditor:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_20260623_004857.json`.

Rollback:

- `deck6_l2_hash_only_batch_pg049_rollback_20260623_004614.sql`
  deletes the current target rows and restores the nine pre-PG049 rows from
  `manaloom_deploy_audit.pg049_deck6_l2_hash_only_batch_20260623_004614`.
