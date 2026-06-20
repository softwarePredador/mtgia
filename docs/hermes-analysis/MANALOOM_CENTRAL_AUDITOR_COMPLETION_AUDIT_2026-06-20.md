# ManaLoom Central Auditor Completion Audit - 2026-06-20

Owner: Auditor Central / single operator
Status: active completion and gap register
Last refreshed: 2026-06-20 18:21 -0300

## Purpose

This register defines what "do everything in this thread" means for the current
ManaLoom cycle.

Rafael explicitly stopped the other executor chats and required this Auditor
Central thread to own repo audit, worktree organization, PostgreSQL deployment,
validation, documentation reconciliation, and next-step execution. Therefore:

- do not generate continuation commands for other chats by default;
- do not wait for another chat to perform PostgreSQL or worktree triage;
- continue operating from live repo, test, artifact, and PostgreSQL evidence;
- keep any inference labeled as inference.

## Completion Criteria

| Criterion | Current state | Evidence | Gap / blocker |
| --- | --- | --- | --- |
| Single-operator ownership | achieved for the current model | `MANALOOM_CENTRAL_AUDITOR_ORDERS.md` says historical executor-chat command blocks are deprecated and this thread owns the work | none unless Rafael re-enables other chats |
| Current repo state checked before acting | achieved in this cycle | current 18:21 snapshot remains `master...origin/master`, with `25` tracked modified files, `85` individual untracked files, tracked shortstat `25 files changed, 6597 insertions(+), 185 deletions(-)`, and `git diff --check` clean | repo remains dirty by design |
| Worktree organized without destroying work | partially achieved | all dirty files are classified by ownership in `WORKTREE_OPERATIONAL_MAP_2026-06-20.md`; no orphan owner fronts remain; exact initial `8`-file cleanup plus duplicate `132730.*` pair were executed after approval | worktree remains dirty and publication still needs a separate decision |
| PostgreSQL deploy ownership | achieved | `POSTGRES_DEPLOY_REGISTER_2026-06-20.md` records PG-002, PG-006, PG-007, and PG-008 applied by this thread after Rafael's single-operator directive | no current apply is ready; future writes still need precheck/apply/postcheck/rollback evidence |
| PostgreSQL current queue audited | achieved at latest heartbeat | PG-008 postcheck `pg008_target_rule_count=1`; PG-001 planner `planned_row_count=0`; PG-002 postcheck `all_post_apply_checks_ok=true`; PG-003 planner `backfill_ready=0`; PG-005 dry-run `applied_counts=0`; PG-006/PG-007 postchecks clean; migrations `29/29` | PG-003 remains policy-blocked |
| Battle artifact reconciled | achieved for current latest | latest official full battle now points to `20260620_212035/summary.json`, status `trusted_for_strategy_learning`, with `mandatory_gate_divergences=[]`; target-pressure/table-intent/event-contract/replay-decision/action/forensic all pass; tests `18/18` pass and `action_findings=0` | none in current latest |
| Deck/app source validation | achieved locally | current aggregate `flutter analyze` clean and `flutter test` passed `619/619` | not proven on real device or production app build |
| Backend source validation | achieved locally | current aggregate `dart analyze` clean, `dart test` passed `634/634`, and Python discover passed `96/96` | dirty backend source is not published; live OpenAI request path not proven |
| Public backend deploy state | achieved for current production SHA | `/health` returned `status=healthy`, `environment=production`, and `git_sha=3908e88caa9c1bb43207e8a2334b0214e150fa10`; local `HEAD` and `origin/master` are the same SHA with `HEAD...origin/master=0 0` | this proves production is current with committed `master`, not with the dirty local worktree |
| Anti-fanout data access audit | achieved locally | dirty backend scan found one direct `card_function_tags` join, but it is aggregated with `ARRAY_AGG(DISTINCT ...)`, `GROUP BY`, and no nearby `deck_cards` join | must be rechecked after future backend SQL edits |
| Documentation/register reconciliation | partially achieved and active | PostgreSQL, battle, Lorehold, worktree, ownership, and central-order registers were updated with evidence | docs will keep drifting until the dirty worktree is either committed or deliberately split |
| Git publication | not authorized | no stage, commit, push, or PR has been performed | requires Rafael's explicit approval |
| Destructive cleanup | achieved for approved list | exact initial `8`-file cleanup list plus duplicate `132730.*` pair were deleted after hash/presence/duplicate revalidation; retained evidence still exists; duplicate hash scan now returns `NO_DUPLICATE_UNTRACKED_HASHES` | no further cleanup candidate is currently validated |

## Current PostgreSQL Position

There is no current PostgreSQL apply ready.

Closed unless drift is proven:

- PG-001: partner/background identity backfill now plans `0` rows.
- PG-002: learned-deck metadata canonicalization postcheck is clean.
- PG-006: `card_battle_rules.execution_status` migration/postcheck/cache sync is
  clean.
- PG-007: `Leyline of Abundance` curated battle rule was inserted, postchecked,
  synced to runtime cache, and validated by a trusted battle run.
- PG-008: `Machine God's Effigy` curated active battle rule was inserted,
  postchecked, synced to runtime cache, and validated by trusted battles
  `20260620_155445`, `20260620_160459`, and the later target-pressure run
  `20260620_185748`.

Still blocked:

- PG-003: oracle/card text/type backlog has `backfill_ready=0`. This is a policy
  problem, not an execution problem. It needs explicit rules for blank official
  oracle text, Arena/Alchemy identities, aliases, and reprints before any write.

No-op:

- PG-005: Lorehold critical role/function/semantic rows already exist; dry-run
  reports `applied_counts=0`.

## Current Worktree Position

The worktree is intentionally dirty and broad:

- `25` tracked modified files;
- `85` individual untracked files, currently concentrated in battle
  target-pressure/table-intent runtime/audit source, retained replay evidence,
  PG table-intent sync evidence, event-contract/target-pressure evidence, and
  new round5/round6/round7/round8/round9 PG/sync artifacts;
- tracked diff is `25 files changed, 6597 insertions(+), 185 deletions(-)` at
  the 18:21 evidence checkpoint;
- wrapper syntax/dry-run validation is clean;
- `git diff --check` is clean.

Operational interpretation:

- broad dirty state is not automatically bad, because it includes validated app
  source, backend source, tests, SQL deployment packages, runtime artifacts, and
  registers;
- `known_cards_canonical_snapshot.json` is a source/runtime-cache candidate with
  local curated opponent-card entries, not PostgreSQL apply evidence;
- newly untracked PG/table-intent JSON files are evidence artifacts or future
  sync inputs until explicitly promoted or cleaned;
- global cleanup, stash, revert, or delete would be unsafe;
- no additional cleanup candidate is currently validated after the executed
  initial `8`-file cleanup and duplicate `132730.*` pair cleanup.

## Battle Runtime Completion Checkpoint - 2026-06-20 17:39 -0300

Commands and evidence:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
  passed with `7` tests.
- Reauditing `20260620_202211` with
  `battle_event_contract_static_audit.py` and current code wrote
  `/tmp/event_contract_static_202211_current_code.*` and returned
  `status=event_contract_static_ready`, `observed_unclassified_total=0`, and
  `static_unclassified_total=0`.
- The local recurring wrapper
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  now includes `target_pressure` in
  `mandatory_gates_required_for_final_status` and
  `mandatory_gate_statuses`.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  passed.
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh --dry-run --seeds 16`
  passed.
- Full rerun
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_203616/summary.json`
  returned `run_scope=recurring_full`, `seeds_completed=16`,
  `battle_replay_final_status=blocked`, and
  `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`.
- `mandatory_gates_required_for_final_status` in the summary now includes
  `target_pressure`.
- `event_contract_static`, `replay_decision_audit`, `action_critic`,
  `table_intent`, `effect_coverage`, `focused_template_dispatch`,
  `unknown_template_backlog`, and `decision_trace_taxonomy` all pass in
  `203616`; tests are `18/18` pass.

Current unresolved full-run blockers:

- Forensic: `forensic_rule_findings=25`, `forensic_turn_findings=0`, blocking
  seeds `63212038`, `63212042`, `63212047`, `63212048`, and `63212050`.
- Target-pressure: `target_pressure_statuses={"blocked":3,"pass":13}`,
  `target_pressure_findings=9`, blocking seeds `63212036`, `63212042`, and
  `63212046`, with `190` opponent combats into Lorehold and `8` into other
  defenders.
- Learned-deck coherence remains clean for Lorehold in
  `learned_deck_coherence_audit_20260620_181429.json` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed.

## Battle Runtime Completion Checkpoint - 2026-06-20 17:40 -0300

Commands and evidence:

- Wrapper recheck produced the newer latest full run
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_204002/summary.json`.
- The run returned `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212040`, `battle_replay_final_status=blocked`, and
  `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`.
- `mandatory_gates_required_for_final_status` includes `target_pressure`.
- `event_contract_static`, `replay_decision_audit`, `action_critic`,
  `table_intent`, `effect_coverage`, `focused_template_dispatch`,
  `unknown_template_backlog`, and `decision_trace_taxonomy` all pass in
  `204002`; tests are `18/18` pass.
- Learned-deck coherence remains clean for Lorehold in
  `learned_deck_coherence_audit_20260620_181429.json` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.

Current unresolved full-run blockers:

- Forensic: `forensic_rule_findings=21`, `forensic_turn_findings=0`, blocking
  seeds `63212042`, `63212047`, `63212048`, and `63212050`.
- Target-pressure: `target_pressure_statuses={"blocked":2,"pass":14}`,
  `target_pressure_findings=4`, blocking seeds `63212042` and `63212046`,
  with `188` opponent combats into Lorehold and `3` into other defenders.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed.

## Battle Runtime Completion Checkpoint - 2026-06-20 18:01 -0300

Commands and evidence:

- New latest full run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_205821/summary.json`.
- The run returned `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212058`, `battle_replay_final_status=review_required`, and
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=196`,
  `target_pressure_opponent_combat_to_other=3`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- `event_contract_static`, `replay_decision_audit`, `action_critic`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`, and
  `decision_trace_taxonomy` all pass in `205821`; tests are `18/18` pass.
- Learned-deck coherence remains clean for Lorehold in
  `learned_deck_coherence_audit_20260620_181429.json` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.

Current unresolved full-run review item:

- Forensic: `forensic_rule_findings=2`, `forensic_turn_findings=0`.
- Both findings are low severity on seed `63212068`: `Goblin Bombardment`
  runtime effect `passive` differs from registry effect `remove_creature` on
  `spell_cast` and `spell_resolved`.

Round5 artifact classification:

- `card_battle_rules_pg_table_intent_promotions_round5_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=3`, selected cards
  `Big Score` and `Spelltwine`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round5_20260620.json`
  declares `apply_sqlite_from_pg=true`, `pg_rows_loaded=5224`,
  `sqlite_inserted_or_updated=5142`, and
  `canonical_snapshot_rows_exported=3181`.
- This heartbeat detected those files and did not execute PostgreSQL apply,
  SQLite sync, cleanup, deletion, stash, revert, stage, commit, or push.

## Battle Runtime Completion Checkpoint - 2026-06-20 18:05 -0300

Commands and evidence:

- New latest full run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_210513/summary.json`.
- The run returned `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212105`, `battle_replay_final_status=blocked`, and
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=179`,
  `target_pressure_opponent_combat_to_other=5`, and
  `target_pressure_opponent_multi_defender_attack=1`.
- `event_contract_static`, `replay_decision_audit`, `action_critic`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`, and
  `decision_trace_taxonomy` all pass in `210513`; tests are `18/18` pass.
- Learned-deck coherence remains clean for Lorehold in
  `learned_deck_coherence_audit_20260620_181429.json` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.

Current unresolved full-run blockers:

- Forensic: `forensic_rule_findings=11`, `forensic_turn_findings=0`.
- High/medium `functional_tags_json` lineage cards: `Arcane Endeavor`,
  `Curator's Ward`, `Magma Opus`, and `The Unagi of Kyoshi Island`.
- Low registry/runtime drift is also visible for `Apex of Power`.

Round6 artifact classification:

- `card_battle_rules_pg_table_intent_promotions_round6_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=2`, selected card
  `Goblin Bombardment`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round6_20260620.json`
  declares `apply_sqlite_from_pg=true`, `pg_rows_loaded=5225`,
  `sqlite_inserted_or_updated=5143`, and
  `canonical_snapshot_rows_exported=3181`.
- This heartbeat detected those files and did not execute PostgreSQL apply,
  SQLite sync, cleanup, deletion, stash, revert, stage, commit, or push.

Post-latest round7 artifact classification:

- `card_battle_rules_pg_table_intent_promotions_round7_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=6`, selected cards
  `Apex of Power`, `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, and
  `The Unagi of Kyoshi Island`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round7_20260620.json`
  declares `apply_sqlite_from_pg=true`, `pg_rows_loaded=5230`,
  `sqlite_inserted_or_updated=5148`, and
  `canonical_snapshot_rows_exported=3185`.
- A 20s recheck still found latest at `20260620_210513`, so post-round7 battle
  proof is pending.
- This heartbeat detected those files and did not execute PostgreSQL apply,
  SQLite sync, cleanup, deletion, stash, revert, stage, commit, push, or battle
  rerun.

## Battle Runtime Completion Checkpoint - 2026-06-20 18:13 -0300

Commands and evidence:

- New latest full run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211217/summary.json`.
- The run returned `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212112`, `battle_replay_final_status=blocked`, and
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=186`,
  `target_pressure_opponent_combat_to_other=3`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- `event_contract_static`, `replay_decision_audit`, `action_critic`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`, and
  `decision_trace_taxonomy` all pass in `211217`; tests are `18/18` pass.
- Learned-deck coherence remains clean for Lorehold in
  `learned_deck_coherence_audit_20260620_181429.json` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.

Current unresolved full-run blockers:

- Forensic: `forensic_rule_findings=4`, `forensic_turn_findings=0`.
- High/medium `functional_tags_json` lineage cards: `Tellah, Great Sage` and
  `Practical Research`, both from `The Emperor of Palamecia #42 (real)`.
- The prior round7 blocker set from `210513` is superseded by this run, but the
  battle gate remains blocked on new opponent-card lineage.

No PostgreSQL write, SQLite sync, deck swap, cleanup, deletion, stash, revert,
stage, commit, push, or battle rerun was performed.

## Battle Runtime Completion Checkpoint - 2026-06-20 18:17 -0300

Commands and evidence:

- New latest full run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211648/summary.json`.
- The run returned `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212116`, `battle_replay_final_status=review_required`, and
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=200`,
  `target_pressure_opponent_combat_to_other=0`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- `event_contract_static`, `replay_decision_audit`, `action_critic`,
  `table_intent`, `target_pressure`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`, and
  `decision_trace_taxonomy` all pass in `211648`; tests are `18/18` pass.
- Learned-deck coherence remains clean for Lorehold in
  `learned_deck_coherence_audit_20260620_181429.json` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.

Current unresolved full-run review item:

- Forensic: `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"low":2}`.
- Low registry/runtime drift card: `Breena, the Demagogue` from
  `Tayam, Luminous Enigma #25 (real)` on seed `63212130`.
- Runtime effect `passive` differs from registry effect `draw_engine` on
  `spell_cast` and `spell_resolved`.

No PostgreSQL write, SQLite sync, deck swap, cleanup, deletion, stash, revert,
stage, commit, push, or battle rerun was performed.

## Battle Runtime Completion Checkpoint - 2026-06-20 18:21 -0300

Commands and evidence:

- New latest full run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`.
- The run returned `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212120`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`, and
  `mandatory_gate_divergences=[]`.
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=214`,
  `target_pressure_opponent_combat_to_other=3`, and
  `target_pressure_opponent_multi_defender_attack=2`.
- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`, and `table_intent_statuses={"pass":16}`.
- Tests are `18/18` pass.
- Learned-deck coherence remains clean for Lorehold in
  `learned_deck_coherence_audit_20260620_181429.json` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.

External artifact classification:

- Round8 declares `apply_pg=true`, `pg_inserted_or_updated=2`, selected cards
  `Practical Research` and `Tellah, Great Sage`; paired sync declares
  `apply_sqlite_from_pg=true`, `pg_rows_loaded=5232`,
  `sqlite_inserted_or_updated=5150`, and
  `canonical_snapshot_rows_exported=3187`.
- Round9 declares `apply_pg=true`, `pg_inserted_or_updated=2`, selected card
  `Breena, the Demagogue`; paired sync declares
  `apply_sqlite_from_pg=true`, `pg_rows_loaded=5233`,
  `sqlite_inserted_or_updated=5151`, and
  `canonical_snapshot_rows_exported=3187`.

No PostgreSQL write, SQLite sync, deck swap, cleanup, deletion, stash, revert,
stage, commit, push, or battle rerun was performed.

## Battle Runtime Completion Checkpoint - 2026-06-20 17:06 -0300

Commands and evidence:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`
  passed with the new table-intent target-pressure metadata regression.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_target_pressure_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`
  passed.
- Direct target-pressure re-audit of seed `63213000` returned `status=pass`,
  `opponent_combat_to_target=14`, `opponent_combat_to_other=0`,
  `opponent_combat_missing_pressure_reason=0`, and `findings=0`.
- Focused rerun
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200322/summary.json`
  returned `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `target_pressure_statuses={"pass":1}`,
  `forensic_rule_findings=0`, `decision_audit_turn_findings=0`,
  `action_findings=0`, and tests `18/18` pass.
- Full rerun
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200409/summary.json`
  returned `run_scope=recurring_full`, `seeds_completed=16`,
  `battle_replay_final_status=blocked`, and
  `mandatory_gate_divergences=["forensic_audit=blocked","table_intent=blocked"]`.

Current unresolved full-run blockers:

- Forensic: `forensic_rule_findings=15`, blocking seeds `63212015` and
  `63212017`; high findings are `Woodland Bellower` and
  `Shantotto, Tactician Magician` via `functional_tags_json`.
- Table-intent: seeds `63212004`, `63212009`, and `63212019` have
  `opponent_interaction_absent`.
- Target-pressure: seed `63212012` has one opponent split attack against
  Lorehold and another defender while target evaluation is active.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed.

## Target-Pressure Completion Checkpoint - 2026-06-20 16:00 -0300

Commands and evidence:

- `git status --short --branch`: branch remains `master...origin/master`,
  with `15` tracked modified files and `20` individual untracked files.
- `git diff --shortstat`: `15 files changed, 818 insertions(+), 59 deletions(-)`.
- `git ls-files --others --exclude-standard | wc -l`: `20`.
- `git diff --check`: no output.
- latest battle summary realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/summary.json`.
- latest battle summary values: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`, `action_findings=0`,
  `test_results_total=17`, and `test_results_status_counts={"pass":17}`.
- target-pressure values in the same latest run:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_total=117`,
  `target_pressure_opponent_combat_to_target=117`,
  `target_pressure_opponent_combat_to_other=0`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- learned-deck coherence latest remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_181429.json`;
  Lorehold `learned_deck:82` has `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `has_wheel=true`, and `has_reforge=false`.
- Focused runtime validation passed after this register update:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  including
  `PASS test_evaluation_mode_tags_lorehold_lethal_pressure_as_lethal`.
- Target-pressure audit test passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`.
- Runtime surface manifest test passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`.
- `python3 -m py_compile` passed for `battle_analyst_v9.py`,
  `battle_target_pressure_audit.py`, and `battle_replay_v10_3.py`.

Conclusion:

- The historical `20260620_185202` blocked target-pressure run is superseded by
  the clean full run `20260620_185748`.
- Current battle readiness for Lorehold strategy learning now depends on the
  target-pressure gate, not older free-pressure WR snapshots.
- No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
  commit, or push was performed in this checkpoint.

## Review-Only Runtime Safety Checkpoint - 2026-06-20 16:30 -0300

Commands and evidence:

- `git status --short --branch`: branch remains `master...origin/master`.
- Before this register update, the worktree had `18` tracked modified files,
  `43` individual untracked files, tracked shortstat
  `18 files changed, 1514 insertions(+), 77 deletions(-)`, and
  `git diff --check` clean.
- latest battle summary realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_191248/summary.json`.
- latest battle summary values:
  `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`,
  `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=blocked","replay_decision_audit=review_required"]`,
  `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `decision_audit_decision_findings=1`,
  `decision_audit_turn_findings=0`, `action_findings=2`,
  `test_results_total=17`, and `test_results_status_counts={"pass":17}`.
- target-pressure values in the same latest run:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_total=84`,
  `target_pressure_opponent_combat_to_target=84`,
  `target_pressure_opponent_combat_to_other=0`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- Blocking seed evidence:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_191248/seed_63211917/forensic_audit.json`
  reports two high `Goblin Bombardment` `remove_creature` findings from a
  `needs_review` rule; action critic reports two low `review_rule_used`
  findings; decision audit reports one low `decision:cast_spell` finding.
- Local SQLite/runtime row evidence:
  `Goblin Bombardment` is `source=generated`,
  `review_status=needs_review`, `execution_status=review_only`, and effect
  `remove_creature`.
- Runtime fix:
  `battle_analyst_v9.py` suppresses non-runtime-safe canonical snapshot rules
  into a passive `canonical_snapshot_rule_not_runtime_safe` provenance effect.
- Regression:
  `battle_card_specific_tests.py` adds
  `test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast`.
- Focused validation passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
- Target-pressure audit test passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`.
- Python compile passed:
  `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`.
- Focused seed replay/auditors under
  `/tmp/lorehold_seed63211917_post_review_only_fix.*` returned
  `action_findings=0`, `forensic rule_findings=0`,
  `forensic turn_findings=0`, `decision_findings=0`, and
  `decision turn_findings=0`.

Conclusion:

- The specific `Goblin Bombardment` review-only runtime defect is fixed locally.
- The official battle artifact is not yet green; it remains blocked until the
  next full recurring battle rerun supersedes `20260620_191248`.
- No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
  commit, or push was performed in this checkpoint.

## Latest Battle State - 2026-06-20 16:50 -0300

Commands and evidence:

- Focused target-pressure revalidation on seed `63211952` passed after
  `battle_target_pressure_audit.py` started ignoring opponent combat after the
  evaluation target has been eliminated:
  `status=pass`, `target_player_eliminated=true`,
  `post_target_elimination_opponent_combat_ignored=1`,
  `opponent_combat_to_target=10`, `opponent_combat_to_other=0`.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_195007/summary.json`.
- `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63211944`.
- `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked","replay_decision_audit=review_required"]`.
- `test_results_total=17`, `test_results_status_counts={"pass":17}`.
- `action_findings=0`.
- Target-pressure pass:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_total=193`,
  `target_pressure_opponent_combat_to_target=193`,
  `target_pressure_opponent_combat_to_other=0`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- Remaining forensic blockers:
  `forensic_rule_findings=26`, `forensic_turn_findings=1`,
  blocking seeds `63211954` and `63211958`.
- High forensic cards:
  `Abandon Attachments`, `Channeled Force`, and `Hypothesizzle`, all still
  using `functional_tags_json`.
- Replay-decision review:
  seed `63211944`, turn `7`, `board_wipe_resolved`, low severity.

Conclusion:

- The Goblin `review_only` blocker is closed.
- The target-pressure false positive is closed.
- The official latest remains blocked by card-rule lineage/data curation and a
  low board-wipe review finding.
- No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
  commit, or push was performed.

## What This Thread Will Do Next

1. Keep operating as the only active executor/auditor while Rafael keeps the
   other chats paused.
2. Run read-only PostgreSQL and artifact checks before every database decision.
3. Apply PostgreSQL only when a specific package has passed precheck and has a
   rollback/postcheck path.
4. Continue validating dirty source by ownership front before any publication.
5. Prepare only a dry-run/precheck/rollback package or waiver proposal for the
   current `functional_tags_json` forensic blockers; do not apply without
   exact approval.
6. Keep worktree cleanup conservative: preserve evidence, remove only proven
   duplicate/superseded files, and never delete without the exact safe list.
7. Keep registers updated after each material action.
8. Use `MANALOOM_PUBLICATION_BATCH_PLAN_2026-06-20.md` as the current batch
   order before any stage/commit/push decision.

## Non-Completion Boundaries

The current goal is not complete yet because:

- the worktree is still dirty and not published;
- approved cleanup has been executed, but the broader worktree is still dirty;
- live backend deploy is healthy for committed `master`, but dirty local
  app/server changes are not committed or pushed;
- live OpenAI behavior and real-device Flutter behavior are not proven by the
  current local test set;
- the latest full battle artifact is currently blocked at `20260620_200409`
  by learned-opponent card-rule lineage, table-intent opponent interaction
  absence, and one target-pressure split attack;
- PG-003 remains policy-blocked.

## Historical Verification Checkpoint - 2026-06-20 11:42 -0300

Commands run after this register was introduced:

- `git diff --check`: no output, whitespace/conflict-marker check clean.
- `git status --short --branch`: branch remains `master...origin/master`;
  tracked modified files remain broad, and this new completion audit is now
  one of the untracked control docs.
- `git diff --shortstat`: `72 files changed, 24631 insertions(+), 2029 deletions(-)`.
- `git ls-files --others --exclude-standard | wc -l`: `80`.
- `cd server && dart run bin/migrate.dart --status`: `29` migrations total,
  `29` executed, `0` pending.
- latest battle summary realpath at that time:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_140016/summary.json`.
- latest battle summary values: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={'pass': 16}`,
  `execution_status_counts={'auto': 1703, 'review_only': 1457}`,
  `runtime_surface_manifest_total_files=110`,
  `runtime_surface_manifest_unclassified_files=[]`,
  `seeds_requested=16`, and `seeds_completed=16`.
- `cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_battle_runtime_surface_manifest.py`:
  `PASS test_manifest_classifies_current_battle_surface`.
- `python3 server/bin/plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`:
  `status=PASS`, `planned_row_count=0`, `db_mutations=false`,
  `apply_supported=false`.
- `python3 server/bin/plan_oracle_text_backfill.py --no-scryfall --limit 25`:
  `status=PASS`, `mode=read_only`, `db_mutations=false`,
  `missing_any=363`, `missing_oracle_id=4`, `missing_oracle_text=360`,
  `planned_items=6`, `active_learned_gap_items=0`, `backfill_ready=0`.
- `python3 server/bin/plan_lorehold_critical_role_backfill.py --dry-run`:
  `status=PASS`, `mode=dry_run`, `db_mutations=false`,
  `applied_counts={"commander_synergy_rows":0,"function_tag_rows":0,"semantic_v2_rows":0}`,
  existing rows remain `5/11/4`.

Conclusion:

- no PostgreSQL apply is ready right now;
- no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
  commit, or push was performed in this checkpoint.

## Public Backend Deploy Checkpoint - 2026-06-20 11:44 -0300

Commands and evidence captured immediately before writing this checkpoint
section:

- `git fetch --all --prune`: updated only `origin/codex/hermes-analysis-docs`
  from `f80b2da2` to `956f630e`; no `origin/master` update was reported.
- `git rev-list --left-right --count HEAD...origin/master`: `0 0`.
- `git rev-parse HEAD`: `3908e88caa9c1bb43207e8a2334b0214e150fa10`.
- `git rev-parse origin/master`:
  `3908e88caa9c1bb43207e8a2334b0214e150fa10`.
- `curl -fsS --max-time 15 https://evolution-cartinhas.8ktevp.easypanel.host/health`:
  `{"status":"healthy","service":"mtgia-server","environment":"production","version":"1.0.0","git_sha":"3908e88caa9c1bb43207e8a2334b0214e150fa10",...}`.
- `git diff --name-only -- app server | wc -l`: `64`.
- `git diff --name-only -- app | wc -l`: `17`.
- `git diff --name-only -- server | wc -l`: `47`.

Conclusion:

- Production backend is healthy and deployed at the same committed SHA as local
  `HEAD` and `origin/master`.
- The current dirty app/server work is local-only and not published to
  production because it is not committed or pushed.
- This was a read-only deploy audit. No code deploy, PostgreSQL write, deck
  swap, cleanup, deletion, stash, revert, stage, commit, or push was performed.

## Worktree Ownership Checkpoint - 2026-06-20 11:48 -0300

Commands and evidence:

- `git status --short --branch`: `master...origin/master`, `72 M`, `78 ??`.
- `git diff --shortstat`: `72 files changed, 24631 insertions(+), 2029 deletions(-)`.
- `git ls-files --others --exclude-standard | wc -l`: `80`.
- `git diff --check`: clean.
- Tracked prefix split: `app=17`, `docs=8`, `server=47`.
- Untracked prefix split: `docs=52`, `server=28`.
- Ownership index updated to include
  `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
  as Auditor Central control state.
- Current ownership section totals cover all dirty files:
  `17` App Deck files, `8` tracked docs/runtime evidence files, `47` tracked
  backend source/test files, `7` untracked control registers, `22` untracked
  PostgreSQL deploy evidence files, `5` untracked PG-006 battle/runtime
  evidence files, `4` untracked learned-deck retained evidence files, `8`
  untracked cleanup proposal candidates, `28` untracked backend source/test
  files, and `6` untracked PG-007 runtime/battle evidence files.

Conclusion:

- Worktree ownership is current again after the added completion audit.
- The worktree is still dirty, but no dirty file is outside a known owner
  front.
- This was documentation reconciliation only. No code deploy, PostgreSQL write,
  deck swap, cleanup, deletion, stash, revert, stage, commit, or push was
  performed.

## Cleanup Checkpoint - 2026-06-20 11:57 -0300

Actions:

- Executed the exact `8`-file cleanup list from
  `WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md` after Rafael authorized cleanup and
  organization.

Evidence:

- Pre-delete: all `8` files existed and matched audited hashes.
- Duplicate proof remained true for
  `battle_effect_coverage_audit_20260620_120952.*` against retained
  `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.*`.
- Post-delete: all `8` paths are absent.
- Retained evidence still exists:
  `learned_deck_coherence_audit_20260620_095253.*`,
  `learned_deck_coherence_audit_20260620_115918.*`, and
  `battle_effect_coverage_audit_20260620_120904_post_sqlite_sync.*`.
- `git status --short --branch`: `master...origin/master`, `72 M`,
  `70 ??`.
- `git ls-files --others --exclude-standard | wc -l`: `72`.
- `git diff --check`: clean.

Conclusion:

- The validated cleanup list is closed.
- No PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit, or
  push was performed.

## Duplicate Evidence Cleanup Checkpoint - 2026-06-20 12:00 -0300

Actions:

- Executed additional cleanup for the duplicate pair
  `battle_effect_coverage_audit_20260620_132730.*`.

Evidence:

- Duplicate SHA scan found `132730.json` byte-identical to retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.json`.
- Duplicate SHA scan found `132730.md` byte-identical to retained
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.md`.
- `cmp -s` returned `0` for both pairs.
- `rg` found no artifact filename reference to `132730.*` outside cleanup and
  ownership documentation.
- Post-delete: both `132730.*` paths are absent.
- Retained PG-007 evidence still exists:
  `battle_effect_coverage_audit_20260620_102701_post_pg007_sync.*`.
- Duplicate hash scan over current untracked files returned
  `NO_DUPLICATE_UNTRACKED_HASHES`.
- `git ls-files --others --exclude-standard | wc -l`: `70`.
- Untracked prefix split: `docs=42`, `server=28`.

Conclusion:

- No duplicate untracked evidence hashes are known at this checkpoint.
- No PostgreSQL write, deck swap, code deploy, stash, revert, stage, commit, or
  push was performed.

## PG-008 Battle Closure Checkpoint - 2026-06-20 12:16 -0300

Actions:

- Treated new latest battle `20260620_150241` as an active blocker because it
  reported `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_lineage_status=incomplete`, and `forensic_rule_findings=1`.
- Identified the blocker as `Machine God's Effigy`, event `spell_cast`, effect
  `ramp_permanent`, source `functional_tags_json`, seed `63211509`.
- Prepared and applied PG-008:
  `machine_gods_effigy_battle_rule_pg008_*_20260620_1210`.

Evidence:

- PostgreSQL precheck: target card `1`, existing target rule `0`, existing any
  Machine God's Effigy rule `0`, snapshot before `battle_rules=[]`,
  `battle_rule_count=0`, `function_tags={ramp}`.
- Apply result: `INSERT 0 1`, `COMMIT`.
- Postcheck result: `pg008_target_rule_count=1`; snapshot exposes the new rule
  in `battle_rules`; backup rows `0`.
- Runtime sync:
  `battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json`
  with `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108`, and
  `canonical_snapshot_rows_exported=3161`.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_151437/summary.json`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, and tests `16/16`
  pass.
- Worktree after PG-008: `72` tracked modified files, `77` individual untracked
  files, untracked prefix split `docs=49`, `server=28`.

Conclusion:

- PG-008 is closed unless future SELECT/sync/battle evidence proves drift.
- There is no current PostgreSQL apply ready after PG-008.
- No deck swap, code deploy, stash, revert, stage, commit, or push was
  performed.

## Publication Batch Validation Checkpoint - 2026-06-20 12:58 -0300

Actions:

- Created
  `docs/hermes-analysis/MANALOOM_PUBLICATION_BATCH_PLAN_2026-06-20.md`.
- Added `.gitignore` rule for
  `docs/hermes-analysis/manaloom-knowledge/backups/*.bak`; the backup files
  remain on disk and were not deleted.
- Ran aggregate app/backend/Python/PG/battle validation.

Evidence:

- `git status --short --branch`: `master...origin/master`, `73` tracked
  modified files, `75` untracked files after the plan file was added.
- `git diff --shortstat`:
  `73 files changed, 24686 insertions(+), 2022 deletions(-)`.
- `git diff --check`: clean.
- `flutter analyze`: no issues.
- `flutter test`: `619/619` tests passed.
- `cd server && dart analyze`: no issues.
- `cd server && dart test`: `634/634` tests passed.
- `python3 -m unittest discover -s server/test -p '*_test.py' -v`: `96/96`
  tests passed; one sqlite ResourceWarning remains non-failing.
- `cd server && dart run bin/migrate.dart --status`: `29/29` executed, `0`
  pending.
- PG-008 postcheck: `pg008_target_rule_count=1`; transaction rolled back after
  SELECT checks.
- `test_battle_runtime_surface_manifest.py`: `PASS`.
- Fresh battle audit latest:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_155445/summary.json`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic lineage complete, and tests `16/16`
  pass.
- Public `/health`: healthy on committed SHA
  `3908e88caa9c1bb43207e8a2334b0214e150fa10`.

Conclusion:

- Current publication order is now documented.
- No current PostgreSQL apply is ready.
- No deck swap, code deploy, stash, revert, stage, commit, or push was
  performed.

## Final Organization Checkpoint - 2026-06-20 12:26 -0300

Commands and evidence:

- `git diff --check`: no output, whitespace/conflict-marker check clean.
- `git status --short --branch`: branch remains `master...origin/master`; dirty
  worktree is classified and intentionally preserved.
- `git diff --shortstat`:
  `72 files changed, 24685 insertions(+), 2022 deletions(-)`.
- `git ls-files --others --exclude-standard | wc -l`: `77`; prefix split is
  `docs=49`, `server=28`.
- Duplicate hash scan over untracked files:
  `NO_DUPLICATE_UNTRACKED_HASHES`.
- `cd server && dart run bin/migrate.dart --status`: `29` total, `29`
  executed, `0` pending.
- `git rev-parse --short HEAD`: `3908e88c`; `git rev-list --left-right --count
  HEAD...origin/master`: `0 0`.
- latest battle summary realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_151437/summary.json`.
- latest battle summary values: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `test_results_total=16`, `test_results_status_counts={'pass': 16}`,
  `execution_status_counts={'auto': 1704, 'review_only': 1457}`,
  `runtime_surface_manifest_total_files=110`,
  `runtime_surface_manifest_unclassified_files=[]`, `seeds_requested=16`, and
  `seeds_completed=16`.
- Stale-current-doc scan for `20260620_140016` as active latest: no matches.

Conclusion:

- Current battle is trusted again after PG-008.
- No PostgreSQL apply is currently ready after this checkpoint.
- Worktree is still dirty by design, but no unowned dirty front or duplicate
  untracked evidence hash remains known.
- No deck swap, code deploy, stash, revert, stage, commit, or push was
  performed.
