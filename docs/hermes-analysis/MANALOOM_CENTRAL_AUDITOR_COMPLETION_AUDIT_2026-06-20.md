# ManaLoom Central Auditor Completion Audit - 2026-06-20

Owner: Auditor Central / single operator
Status: active completion and gap register
Last refreshed: 2026-06-20 21:08 -0300

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
| Current repo state checked before acting | achieved in this cycle | current 21:08 snapshot remains `master...origin/master`, with `21` tracked modified files, `39` untracked files, tracked shortstat `21 files changed, 5431 insertions(+), 1799 deletions(-)`, and `git diff --check` clean | repo remains dirty by design |
| Worktree organized without destroying work | partially achieved | all dirty files are classified by ownership in `WORKTREE_OPERATIONAL_MAP_2026-06-20.md`; no orphan owner fronts remain; exact initial `8`-file cleanup plus duplicate `132730.*` pair were executed after approval | worktree remains dirty and publication still needs a separate decision |
| PostgreSQL deploy ownership | achieved | `POSTGRES_DEPLOY_REGISTER_2026-06-20.md` records PG-002, PG-006, PG-007, and PG-008 applied by this thread after Rafael's single-operator directive | no current apply is ready; future writes still need precheck/apply/postcheck/rollback evidence |
| PostgreSQL current queue audited | achieved at latest heartbeat | PG-011/PG-012/PG-013/PG-014 SELECT-only postchecks show external applied state and local sync reports show `apply_pg=false`, `apply_sqlite_from_pg=true`; PG-015/Wrath read-only postcheck shows `curated_executable_rows=1`, `stale_enabled_wipe_rows=0`, and local cache selects `curated/verified/auto`; PG-001/PG-002/PG-006/PG-007/PG-008/PG-009 remain closed; PG-003 remains `backfill_ready=0`; PG-005 remains no-op | PG-003 policy-blocked; Arcane Epiphany is candidate-only from superseded latest `235914`; PG-011/012/013/014/015 must not be reapplied without drift evidence and exact approval |
| Battle artifact reconciled | achieved for current latest | latest official full battle now points to `20260621_000827/summary.json`, status `trusted_for_strategy_learning`, with `mandatory_gate_divergences=[]`; forensic/action/replay-decision findings `0`; target-pressure/table-intent pass `16/16`; tests `18/18` | none in current latest |
| Deck/app source validation | achieved locally | current aggregate `flutter analyze` clean and `flutter test` passed `619/619` | not proven on real device or production app build |
| Backend source validation | achieved locally | current aggregate `dart analyze` clean, `dart test` passed `634/634`, and Python discover passed `96/96` | dirty backend source is not published; live OpenAI request path not proven |
| Public backend deploy state | achieved for current production SHA | `/health` returned `status=healthy`, `environment=production`, and `git_sha=3908e88caa9c1bb43207e8a2334b0214e150fa10`; local `HEAD` and `origin/master` are the same SHA with `HEAD...origin/master=0 0` | this proves production is current with committed `master`, not with the dirty local worktree |
| Anti-fanout data access audit | achieved locally | dirty backend scan found one direct `card_function_tags` join, but it is aggregated with `ARRAY_AGG(DISTINCT ...)`, `GROUP BY`, and no nearby `deck_cards` join | must be rechecked after future backend SQL edits |
| Documentation/register reconciliation | partially achieved and active | PostgreSQL, battle, Lorehold, worktree, ownership, and central-order registers were updated with evidence | docs will keep drifting until the dirty worktree is either committed or deliberately split |
| Git publication | not authorized | no stage, commit, push, or PR has been performed | requires Rafael's explicit approval |
| Destructive cleanup | achieved for approved list | exact initial `8`-file cleanup list plus duplicate `132730.*` pair were deleted after hash/presence/duplicate revalidation; retained evidence still exists; duplicate hash scan now returns `NO_DUPLICATE_UNTRACKED_HASHES` | no further cleanup candidate is currently validated |

## Current PostgreSQL Position

There is no current PostgreSQL apply authorized or ready.

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
- PG-009: Korvold active learned-deck replacement remains closed.
- PG-011: Lorehold defense variant is observed as externally applied,
  postchecked, and synced into the local Hermes runtime cache. This heartbeat
  did not execute the apply command. Do not reapply it.
- PG-012: `Flame Wave` curated battle rule is observed as externally applied,
  postchecked, and synced into the local Hermes runtime cache. This heartbeat
  did not execute the apply command. Do not reapply it.
- PG-013: `Brainstone` curated battle rule is observed as externally applied,
  postchecked, and synced into the local Hermes runtime cache. This heartbeat
  did not execute the apply command. Do not reapply it.
- PG-014: `Sphere of Safety` curated battle rule and `protection` function tag
  are observed as externally applied, postchecked, and synced into the local
  Hermes runtime cache. This heartbeat did not execute the apply command. Do
  not reapply it.
- PG-015: `Wrath of God` curated board-wipe rule is observed as externally
  applied, postchecked, and synced into the local Hermes runtime cache. This
  heartbeat did not execute the apply command. Do not reapply it.

Still blocked:

- PG-003: oracle/card text/type backlog has `backfill_ready=0`. This is a policy
  problem, not an execution problem. It needs explicit rules for blank official
  oracle text, Arena/Alchemy identities, aliases, and reprints before any write.
- Arcane Epiphany: candidate-only from superseded latest `235914`; it has no
  PG/local battle-rule rows from the read-only checks, but current latest
  `000827` does not block on it. No package/apply is authorized.

No-op:

- PG-005: Lorehold critical role/function/semantic rows already exist; dry-run
  reports `applied_counts=0`.

## Current Worktree Position

The worktree is intentionally dirty:

- `18` tracked modified files;
- `9` individual untracked files;
- tracked diff is `18 files changed, 1503 insertions(+), 102 deletions(-)` at
  the 19:48 evidence checkpoint;
- `git diff --check` is clean.

Operational interpretation:

- modified battle source/test files are source/test necessary for
  attack-limit, attack-tax, self-preservation, forensic support, and
  target-pressure table-intent handling;
- modified rule/tag/sync mapping files are source necessary to classify
  `damage_player_and_creatures` as `removal`, which is relevant to the current
  low `Flame Wave` forensic residual;
- `known_cards_canonical_snapshot.json` is runtime-cache evidence from the
  PG-011 sync, not a standalone PostgreSQL apply artifact;
- untracked PG-011 SQL/package/sync files and
  PG-012/PG-013/PG-014 SQL/package/sync files are evidence artifacts;
- `learned_deck_coherence_audit_20260620_224441.*`,
  `learned_deck_coherence_audit_20260620_231452.*`, and
  `learned_deck_coherence_audit_20260620_233027.*` are evidence artifacts;
- global cleanup, stash, revert, or delete would be unsafe;
- no additional cleanup candidate is currently validated.

## Battle Runtime Completion Checkpoint - 2026-06-20 19:48 -0300

Commands and evidence:

- SELECT-only PostgreSQL checks showed PG-011 external applied state for
  Lorehold deck id `528c877f-f829-4207-95e6-73981776c323`: six defense cards
  present, six prior cards absent, target deck qty `100`.
- PG-011 postcheck SQL passed under read-only transaction settings:
  `out_qty_in_target_deck=0`, `in_qty_in_target_deck=6`,
  `target_deck_qty=100`, `target_deck_rows=100`,
  `active_learned_deck_ok=1`.
- Runtime sync artifacts detected:
  `sync_pg_target_deck_to_hermes_pg011_lorehold_defense_20260620_193849.json`
  and
  `battle_card_rules_sqlite_from_pg_pg011_lorehold_defense_20260620_193849.json`.
- Fresh learned-deck audit:
  `learned_deck_coherence_audit_20260620_224441.json`; Lorehold
  `learned_deck:82` remains `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, and metadata records
  `lorehold_defense_variant_b_20260620`.
- Fresh battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`.
- Battle result:
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_rule_findings=6`, all low `Flame Wave` passive vs
  `remove_creature`; `forensic_turn_findings=0`.
- Target-pressure passes `16/16` with `target_pressure_findings=0`;
  table-intent passes `16/16`; action/replay-decision/event-contract/effect
  coverage/focused-template/unknown-template/decision-trace gates pass; tests
  `18/18`.
- Focused local tests passed:
  `py_compile` over modified battle scripts,
  `test_battle_forensic_audit_supported_effects.py`,
  `test_battle_target_pressure_audit.py`, and
  `test_battle_analyst_v10_3.py`.
- Additional `py_compile` passed for
  `battle_rule_registry.py`,
  `derive_functional_tags_from_battle_rules.py`, and
  `sync_pg_target_deck_to_hermes.py`.

No PostgreSQL apply command, manual deck swap command, cleanup, deletion,
stash, revert, stage, commit, or push was performed by this heartbeat.

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

## Battle Runtime Completion Checkpoint - 2026-06-20 20:30 -0300

Commands and evidence:

- `git status --short --branch` was read before acting. The worktree was
  already dirty with prior battle/docs/cache changes plus new PG-012,
  PG-013, PG-014, and learned-deck audit artifacts.
- PG-012 `Flame Wave` postcheck SQL was executed with
  `PGOPTIONS='-c default_transaction_read_only=on'` and returned
  `card_rows=1`, `curated_executable_rows=1`,
  `stale_enabled_remove_rows=0`.
- PG-013 `Brainstone` postcheck SQL was executed with read-only transaction
  settings and returned `card_rows=1`, `curated_executable_rows=1`,
  `stale_enabled_draw_rows=0`.
- PG-014 `Sphere of Safety` postcheck SQL was executed with read-only
  transaction settings and returned `card_rows=1`,
  `curated_executable_rows=1`, `stale_enabled_draw_rows=0`, and
  `protection_function_tag_rows=1`.
- Sync artifacts detected:
  `battle_card_rules_sqlite_from_pg_pg012_flame_wave_20260620_200035.json`,
  `battle_card_rules_sqlite_from_pg_pg012_flame_wave_postfix_20260620_231019.json`,
  `battle_card_rules_sqlite_from_pg_pg013_brainstone_20260620_201110.json`,
  and `battle_card_rules_sqlite_from_pg_pg014_sphere_20260620_202250.json`.
- The PG-014 sync report shows `apply_pg=false`,
  `apply_sqlite_from_pg=true`, `pg_rows_loaded=5236`,
  `sqlite_inserted_or_updated=5172`, and
  `canonical_snapshot_rows_exported=3195`.
- Local SQLite and `known_cards_canonical_snapshot.json` confirm
  `Sphere of Safety` as curated/verified/auto `attack_tax` with
  `attack_tax_per_enchantment=1`; stale generated `draw_engine` rows are
  disabled/deprecated.
- `sync_battle_card_rules_pg.py` was corrected to preserve current reviewed
  runtime rows during PG mirror refresh when `apply_pg=false`, avoiding the
  Brainstone regression where a reviewed runtime rule could be removed by a
  PG review-only generated snapshot.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
  passed (`7` tests).
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including `Flame Wave`, `Brainstone`, and
  `Sphere of Safety` regressions.
- Fresh read-only learned-deck audit:
  `learned_deck_coherence_audit_20260620_233027.json`; Lorehold
  `learned_deck:82` remains `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `unresolved=[]`, no premium Mox, no PG/SQLite name
  drift, and commander identity remains `single_commander_identity`.
- Fresh full battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_232534/summary.json`.
- Battle result: `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, `action_findings=0`,
  `decision_audit_decision_findings=0`, `decision_audit_turn_findings=0`,
  target-pressure passes `16/16`, table-intent passes `16/16`, and tests are
  `18/18`.

Deck/battle file classification:

- Source necessary:
  `sync_battle_card_rules_pg.py`,
  `test_sync_battle_card_rules_pg_selection.py`, `battle_analyst_v9.py`,
  `battle_card_specific_tests.py`, `battle_combat_tests.py`,
  `battle_forensic_audit.py`, `battle_rule_registry.py`,
  `battle_target_pressure_audit.py`,
  `derive_functional_tags_from_battle_rules.py`,
  `sync_pg_target_deck_to_hermes.py`, and their focused tests.
- Runtime cache/evidence:
  `known_cards_canonical_snapshot.json` and the local Hermes SQLite state.
- Evidence artifacts:
  PG-011/PG-012/PG-013/PG-014 SQL package files, PG/Hermes sync reports, and
  learned-deck coherence audit JSON/Markdown files.
- Candidate future cleanup:
  superseded local battle artifacts and older learned-deck audit files only
  after a separate exact cleanup list and explicit approval. No cleanup,
  delete, revert, stash, stage, commit, or push was performed here.

Operational conclusion:

- PG-012, PG-013, and PG-014 are closed as externally applied,
  postchecked, runtime-synced, and battle-validated.
- Lorehold Deck 6 has no active list-resolution, quantity, off-color, premium
  Mox, or PG/SQLite name-match pending in the latest learned-deck audit.
- Superseded on 2026-06-21 10:39 -0300:
  `lorehold_strategy_big_spell_finishers_gap` was closed as an auditor-rule
  mismatch. The corrected audit
  `learned_deck_coherence_audit_20260621_133919` evaluates strategy from
  `pg_saved_deck`, reports strategy pass `yes`, and leaves no Lorehold strategy
  issues.
- No PostgreSQL apply command, deck swap, cleanup, deletion, stash, revert,
  stage, commit, or push was performed by this checkpoint.

## Latest Drift Checkpoint - 2026-06-20 20:37 -0300

- After the `232534` trusted battle, an external runner completed and replaced
  `latest` with
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_233350/summary.json`.
- `233350` is `blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- Forensic blocker: `Arcane Epiphany`, effect `draw_cards`, source
  `functional_tags_json`, seed `63212310`, turn `10`; `spell_cast` is medium
  and `spell_resolved` is high.
- Clean gates in `233350`: target-pressure `pass=16`,
  `target_pressure_findings=0`, table-intent `pass=16`,
  `action_findings=0`, replay-decision findings `0`, tests `18/18`.
- SELECT-only PostgreSQL evidence: one `cards` row for `Arcane Epiphany`
  (`{3}{U}{U}`, `Instant`, `Draw three cards.`) and `0` battle-rule rows.
- Local cache evidence: `0` SQLite `battle_card_rules` rows for
  `Arcane Epiphany`; absent from canonical/generated/reviewed battle-rule JSON.

Conclusion:

- PG-012/013/014 remain closed by `232534`.
- At `233350`, the active blocker was Arcane Epiphany battle-rule candidate.
- No PostgreSQL apply, local cache hotfix, deck swap, cleanup, stage, commit,
  or push was performed for Arcane.

## Latest Closure Checkpoint - 2026-06-20 20:40 -0300

- Later external variant runners superseded `233350`; `latest` now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234004/summary.json`.
- `234004` is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`.
- Clean latest evidence: forensic findings `0`, action findings `0`,
  replay-decision findings `0`, target-pressure `pass=16`, table-intent
  `pass=16`, tests `18/18`.
- `Arcane Epiphany` remains candidate-only from superseded `233350`, not
  an active latest blocker.
- No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit, or push
  was performed.

## Latest Drift Checkpoint - 2026-06-20 20:49 -0300

- The external variant sweep continued after `234004`; `latest` now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234900/summary.json`.
- `234900` is `blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- Forensic blocker: Arcane Epiphany candidate, effect `draw_cards`,
  source `functional_tags_json`, seed `63212310`, turn `10`; `spell_cast` is
  medium and `spell_resolved` is high.
- Clean gates in `234900`: target-pressure `pass=16`, table-intent `pass=16`,
  action findings `0`, replay-decision findings `0`, tests `18/18`.
- A new external runner was already active after this snapshot was read, so
  future heartbeats must re-read `latest` before acting.

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

## Latest Closure Checkpoint - 2026-06-20 20:52 -0300

Commands and evidence:

- `git status --short --branch`: branch remains `master...origin/master`; dirty
  worktree is intentionally preserved.
- `git diff --shortstat`:
  `21 files changed, 5431 insertions(+), 1799 deletions(-)`.
- Dirty inventory at this checkpoint: `21` tracked modified files and `39`
  untracked files.
- `git diff --check`: no output, whitespace/conflict-marker check clean.
- Latest battle summary realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235219/summary.json`.
- Latest battle summary values:
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, `action_findings=0`,
  `decision_audit_decision_findings=0`, `decision_audit_turn_findings=0`,
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `table_intent_statuses={"pass":16}`,
  `event_contract_static_observed_unclassified_total=0`,
  `event_contract_static_static_unclassified_total=0`, and
  `test_results_status_counts={"pass":18}`.
- `ps` scan found no active `manaloom-battle-strategy-audit` runner at the final
  read.

Conclusion:

- Current latest battle is trusted for strategy learning again after the variant
  sweep.
- `Arcane Epiphany` is not an active latest blocker; retain it only as a
  candidate from superseded artifacts unless a future latest reintroduces it.
- PG-012/013/014 stay closed; no PostgreSQL apply, deck swap, cleanup, stage,
  commit, or push was performed.

## Latest Drift Checkpoint - 2026-06-20 20:59 -0300

Commands and evidence:

- New PG-015/Wrath artifacts appeared:
  `wrath_of_god_battle_rule_pg015_*_20260620_205619.*` and
  `battle_card_rules_sqlite_from_pg_pg015_wrath_20260620_205900.json`.
- PG-015/Wrath read-only precheck/postcheck: `card_rows=1`,
  `executable_board_wipe_rows=1`, `curated_executable_rows=1`, and
  `stale_enabled_wipe_rows=0`; generated duplicate is `deprecated/disabled`.
- PG-015/Wrath sync report: `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`,
  `canonical_snapshot_rows_exported=3195`.
- Local SQLite `battle_card_rules` selects `Wrath of God` as
  `curated/verified/auto` `board_wipe`.
- Latest battle summary realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235914/summary.json`.
- Latest battle summary values:
  `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`,
  `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"high":1,"medium":1}`,
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `table_intent_statuses={"pass":16}`, action findings `0`,
  replay-decision findings `0`, and `test_results_status_counts={"pass":18}`.
- Forensic blocker: `Arcane Epiphany`, seed `63212310`, turn `10`,
  `The Emperor of Palamecia #42 (real)`, effect `draw_cards`, source
  `functional_tags_json`; one medium `spell_cast` and one high
  `spell_resolved` finding.

Conclusion:

- PG-015/Wrath is closed for PostgreSQL/cache state but not sufficient to make
  the current battle latest trusted.
- Active pending item is Arcane Epiphany battle-rule lineage. No PostgreSQL
  apply, deck swap, cleanup, stage, commit, or push was performed.

## Latest Closure Checkpoint - 2026-06-20 21:08 -0300

Commands and evidence:

- Latest battle summary realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_000827/summary.json`.
- Latest battle summary values:
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, `forensic_severity_counts={}`,
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `table_intent_statuses={"pass":16}`, action findings `0`,
  replay-decision findings `0`, and `test_results_status_counts={"pass":18}`.
- `ps` scan found no active `manaloom-battle-strategy-audit` runner after this
  latest read.

Conclusion:

- Current latest battle is trusted again after the Wrath variant sweep.
- PG-015/Wrath is externally applied, postchecked, runtime-synced, and
  battle-validated by `000827`.
- Arcane Epiphany is not an active latest blocker; retain it only as a candidate
  from superseded `235914` unless a future latest reintroduces it.
- No PostgreSQL apply, deck swap, cleanup, stage, commit, or push was performed.

## Latest Drift Checkpoint - 2026-06-20 22:14 -0300

Commands and evidence:

- `git status --short --branch` shows branch `master...origin/master`, tracked
  deck/auditor changes, and untracked PG011-PG018 package/sync artifacts.
- `git diff --check` was clean before this documentation update.
- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_233027.json`;
  Lorehold `learned_deck:82` has `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `unresolved=[]`, no partner/background identity
  finding, and no off-color finding.
- PG-016 artifacts appeared externally and were verified by read-only postcheck:
  five anti-combat cards, `curated_executable_rows=5`,
  `stale_enabled_generated_rows=0`; sync report has `apply_pg=false`,
  `apply_sqlite_from_pg=true`, and `sqlite_inserted_or_updated=2400`.
- PG-017 artifacts appeared externally and were verified by read-only postcheck:
  `Arcane Epiphany` has `curated_executable_rows=1` and
  `draw_function_tag_rows=1`; sync report has `apply_pg=false`,
  `apply_sqlite_from_pg=true`, and `sqlite_inserted_or_updated=1776`.
- Latest completed battle at the start of the checkpoint:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_010452/summary.json`.
  It reports a 64-seed blocked run with
  `mandatory_gate_divergences=["forensic_audit=blocked"]`,
  `forensic_rule_findings=2`, target-pressure `pass=64`, table-intent
  `pass=64`, action findings `0`, replay-decision findings `0`, and tests
  `18/18`.
- The `010452` active blocker was `Jin-Gitaxias, Core Augur` forensic lineage
  from `functional_tags_json`, seed `63212362`, turn `8`, effect `draw_cards`.
- PG-018 artifacts appeared externally during the heartbeat. Read-only
  postcheck returned `card_rows=2`, `curated_executable_rows=2`, and
  `function_tag_rows=2` for `Jin-Gitaxias, Core Augur` and
  `Chandra, Flameshaper`; local Hermes SQLite selects both rows as
  curated/verified/auto.
- A post-PG018 battle runner was active:
  `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310`.

Conclusion:

- PG-016, PG-017, and PG-018 are externally applied/synced and postchecked for
  PostgreSQL/cache state. This heartbeat did not execute any apply/sync command.
- PG-018 battle closure is pending the in-progress rerun summary.
- Current Lorehold learned-deck coherence remains clean; the remaining
  Lorehold-specific strategy item is the medium big-spell finisher gap reported
  by the learned-deck coherence artifact.
- No PostgreSQL apply, deck swap, cleanup, stage, commit, or push was performed
  by this heartbeat.

## Latest Drift Checkpoint - 2026-06-20 22:44 -0300

Commands and evidence:

- `git status --short --branch` shows branch `master...origin/master`.
  New compared with the prior checkpoint: modified
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`
  and untracked PG-019 package/sync artifacts.
- Newest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_233027.json`;
  Lorehold `learned_deck:82` has `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `unresolved=[]`, no partner/background identity
  finding, and no off-color finding.
- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_012833/summary.json`.
  It reports `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["strategy_audit=review_required"]`,
  forensic findings `0`, target-pressure `pass=64`, table-intent `pass=64`,
  action findings `0`, replay-decision findings `0`, and tests `18/18`.
- The single review-required strategy finding is seed `63212362`,
  `wheel_opponent_refill_risk`, decision `decision-000141`.
- PG-019 artifacts:
  `jin_gitaxias_non_wheel_pg019_*_20260621_013900.*` and
  `battle_card_rules_sqlite_from_pg_pg019_jin_non_wheel_20260621_014100.json`.
- Read-only PG-019 postcheck shows `Jin-Gitaxias, Core Augur` with
  `wheel_like=false`, source `curated`, `review_status=verified`,
  `execution_status=auto`, reviewed by `codex_central_auditor_pg019`.
- PG-019 runtime sync report shows `apply_pg=false`,
  `apply_sqlite_from_pg=true`, `pg_rows_loaded=1`, and
  `sqlite_inserted_or_updated=1`; local Hermes SQLite selects the same row.
- A post-PG019 64-seed runner was active.

Conclusion:

- PG-018 battle-forensic closure is validated by `012833`.
- PG-019 is externally applied/synced and postchecked for PostgreSQL/cache
  state. This heartbeat did not execute apply/sync.
- PG-019 battle closure is pending the active post-PG019 rerun.
- No PostgreSQL apply, deck swap, cleanup, stage, commit, or push was performed
  by this heartbeat.

## Latest Closure/Local Apply Checkpoint - 2026-06-20 23:14 -0300

Commands and evidence:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020427/summary.json`.
  It reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`,
  target-pressure `pass=16`, table-intent `pass=16`, action findings `0`,
  replay-decision findings `0`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- New local optimizer evidence:
  `master_optimizer_apply_20260621_020406.md` and
  `master_optimizer_rollback_20260621T020406839706+0000.json`.
- The apply artifact records Hermes local SQLite `deck_id=6` swap:
  `Windborn Muse` over `Guttersnipe`; it explicitly says no production database
  was mutated.
- Local SQLite verification: `deck_id=6` has `Windborn Muse=1`, no
  `Guttersnipe`, and `100/100` cards.
- PostgreSQL read-only verification for materialized Lorehold deck
  `528c877f-f829-4207-95e6-73981776c323`: `Guttersnipe=1`, no
  `Windborn Muse`, and `100/100` cards.
- Newer run directory `20260621_020729` had no `summary.json`; a 64-seed runner
  was active.
- `git diff --check` returned clean.

Conclusion:

- PG-019 is battle-closed for completed 16-seed latest `020427`.
- The Windborn change is real local Hermes runtime state, but not canonical
  PostgreSQL/learned-deck state.
- Completion remains conditional on either treating the local Windborn result as
  candidate evidence only or getting explicit approval before any promotion.
- No PostgreSQL apply, deck swap command, cleanup, stage, commit, or push was
  performed by this heartbeat.

Final 64-seed reconciliation:

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/summary.json`.
- The 64-seed post-local-apply run is trusted:
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=64`, table-intent `pass=64`, action findings `0`, replay-decision
  findings `0`, tests `18/18`, and `strategy_review_required_findings=0`.
- No active battle runner remained in the final process check.

## Latest PG020/Learned-Deck Checkpoint - 2026-06-20 23:45 -0300

Commands and evidence:

- PG-020 read-only postcheck returned `postcheck_passed=true`, `deck_rows=100`,
  `deck_quantity=100`, `Guttersnipe=0`, `Windborn Muse=1`, and
  `backup_rows=1`.
- Fresh read-only learned-deck coherence artifacts:
  `learned_deck_coherence_audit_20260621_024551.json` and `.md`.
- Global learned-deck state remains `severity_counts={"medium":13}` with no
  high issues.
- Lorehold active learned deck remains structurally clean, but has name drift
  against materialized PG/Hermes runtime state:
  active-vs-PG `Guttersnipe` missing from PG and `Windborn Muse` extra in PG;
  active-vs-SQLite `Guttersnipe`/`Monument to Endurance` missing from SQLite and
  `Silent Arbiter`/`Windborn Muse` extra in SQLite.
- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024220/summary.json`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- The `024220` invocation is
  `codex_pg020_candidate_ensnaring_bridge_for_monument_16`; no PG package was
  found for that candidate.
- A newer run directory `20260621_024527` had no `summary.json`, and a 16-seed
  runner was active.

Conclusion:

- PG-020 remains applied/postchecked/synced and battle-trusted.
- Active learned-deck name drift is now the main open governance item.
- Ensnaring Bridge over Monument to Endurance is candidate-only.
- No PostgreSQL apply, deck swap command, cleanup, stage, commit, or push was
  performed by this heartbeat.

Final candidate reconciliation:

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024527/summary.json`.
- `invocation_kind=codex_pg020_candidate_silent_arbiter_for_monument_16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package was found for Silent Arbiter over Monument to Endurance; a
  newer run directory `20260621_024906` was active.

Final candidate reconciliation:

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024906/summary.json`.
- `invocation_kind=codex_pg020_candidate_norns_annex_for_monument_16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package was found for Norn's Annex over Monument to Endurance.
- Classification remains candidate-only; no PostgreSQL apply, deck swap
  command, cleanup, stage, commit, or push was performed by this heartbeat.

Latest candidate blocker:

- `latest` then advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_025233/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_16`,
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required",
  "replay_decision_audit=review_required"]`.
- Concrete evidence is seed `63212318`, turn `12`,
  `board_wipe_resolved`: low-severity board-wipe/protection finding,
  `9` protected creatures versus `7` destroyed.
- Tests stayed `18/18`, target-pressure `pass=16`, table-intent `pass=16`,
  forensic rule findings `0`, and replay decision findings `0`.
- No PG package was found for Magus of the Moat over Monument to Endurance; the
  candidate is blocked from promotion until reviewed or superseded by a clean
  rerun.

Latest 64-seed checkpoint:

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_030022/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, `battle_replay_final_status=review_required`.
- Mandatory divergences remain
  `["forensic_audit=review_required", "replay_decision_audit=review_required"]`.
- Concrete blocker remains seed `63212318`, turn `12`,
  `board_wipe_resolved`, low-severity board-wipe/protection finding:
  `9` protected creatures versus `7` destroyed.
- Tests stayed `18/18`, target-pressure `pass=64`, table-intent `pass=64`,
  forensic rule findings `0`, and replay decision findings `0`.
- No PG package was found for Magus of the Moat over Monument to Endurance.
- New read-only learned-deck coherence evidence:
  `learned_deck_coherence_audit_20260621_031653.json` and `.md`; Lorehold
  remains structurally clean but still has active-vs-runtime drift and the
  medium big-spell finisher gap.

Corrected candidate checkpoint:

- `latest` advanced again to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_031617/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_magus_moat_for_monument_16`,
  `run_scope=recurring_full`, `seeds_requested=16`, `seeds_completed=16`,
  and `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`, forensic turn
  findings `0`, replay decision turn findings `0`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`, strategy review-required findings
  `0`.
- No PG package was found for Magus of the Moat over Monument to Endurance; the
  run is candidate-only evidence.

Corrected Silent Arbiter checkpoint:

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_silent_arbiter_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`, forensic turn
  findings `0`, replay decision turn findings `0`, target-pressure `pass=64`,
  table-intent `pass=64`, tests `18/18`, strategy review-required findings
  `0`.
- Strategy signal remains weak: target wins `8`, opponent wins `54`, and
  `forced_keep_after_bad_mulligan=15`.
- No PG package was found for Silent Arbiter over Monument to Endurance; the
  run is candidate-only evidence.

PG021/PG022 external apply checkpoint:

- New PG021/PG022 artifacts appeared, and read-only postchecks prove they were
  applied externally before this heartbeat.
- PG021 postcheck:
  `pg021_global_attack_rule_scope_postcheck`, `rule_rows=3`,
  `silent_global_ok=true`, `magus_global_ok=true`,
  `bridge_controller_hand_ok=true`, `postcheck_passed=true`.
- PG022 postcheck:
  `pg022_lorehold_silent_arbiter_postcheck`, `deck_rows=100`,
  `deck_quantity=100`, `Monument to Endurance=0`, `Silent Arbiter=1`,
  `backup_rows=1`, `postcheck_passed=true`.
- PG022 sync wrote `100/100` cards into local Hermes `deck_id=6`, where focused
  SQLite check now shows `Silent Arbiter=1` and `Windborn Muse=1`.
- Latest smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`,
  `codex_pg022_post_pg_sync_silent_arbiter_16`, `3/16`, trusted, clean gates,
  tests `18/18`.
- New learned audit:
  `learned_deck_coherence_audit_20260621_045522.json` and `.md`; Lorehold
  remains structurally clean but active learned deck still drifts from PG/SQLite
  by `Guttersnipe`/`Monument to Endurance` versus
  `Silent Arbiter`/`Windborn Muse`.
- This heartbeat did not execute apply/swap/commit/push/cleanup.

Post-PG022 candidate scan checkpoint:

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_052416/summary.json`.
- `run_profile=candidate_reprieve_for_generous_gift_16`,
  `invocation_kind=codex_candidate_scan`, `seeds_completed=16/16`.
- Status is `review_required`, with
  `mandatory_gate_divergences=["strategy_audit=review_required"]`.
- Clean surfaces: forensic findings `0`, replay decision findings `0`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `5/16`, opponents win `9/16`,
  `forced_keep_after_bad_mulligan=5`, `wheel_opponent_refill_risk=1`.
- Temporary candidate state was restored: local SQLite `deck_id=6` still has
  `Generous Gift=1` and no persisted `Reprieve`, `Artist's Talent`, or
  `Brainstone` candidate row.
- No PostgreSQL package was found or applied for this candidate sequence.

Post-engine-fix candidate scan checkpoint:

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_054803/summary.json`.
- `run_profile=recurring_16_seed`,
  `invocation_kind=codex_candidate_combo_scan`, `seeds_completed=16/16`.
- Status is `trusted_for_strategy_learning`, with
  `mandatory_gate_divergences=[]`.
- Clean surfaces: forensic findings `0`, replay decision findings `0`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `1/16`, opponents win `15/16`,
  `forced_keep_after_bad_mulligan=7`.
- Post-fix sequence before latest:
  `053446` candidate `4/16`, `053937` baseline `3/16`, `054357` candidate
  after engine fix `4/16`; all gate-clean.
- No new learned-deck coherence artifact appeared; `045522` remains latest.
- No PostgreSQL package was found or applied for this sequence.

Aborted runner checkpoint:

- Newer run directory:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_060733/`.
- No `summary.json`; `latest` remains `20260621_054803`.
- `py_compile=pass`; `test_battle_analyst_v10_3` failed after `963s`.
- Error: `psycopg2.OperationalError: server closed the connection unexpectedly`
  while opening `sync_pg.connect()` in
  `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`.
- Read-only follow-up `select 1` succeeded with `pg_select_1=1`.
- No PostgreSQL apply, deck swap, commit, push, cleanup, stash, or revert was
  performed.

Latest manual 64-seed checkpoint:

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json`.
- `run_profile=custom_64_seed`, `invocation_kind=manual_cli`,
  `run_scope=custom_multi_seed`, `seeds_completed=64/64`.
- Status is `trusted_for_strategy_learning`, with
  `mandatory_gate_divergences=[]`.
- Clean surfaces: forensic findings `0`, replay decision findings `0`,
  target-pressure `pass=64`, table-intent `pass=64`, tests `18/18`.
- Strategy signal: Lorehold wins `14/64`, opponents win `49/64`,
  `forced_keep_after_bad_mulligan=13`.
- Local SQLite focused check remains `Silent Arbiter=1`, `Windborn Muse=1`,
  `Generous Gift=1`, `100/100`.
- No new learned-deck coherence artifact appeared; `045522` remains latest.
- No PostgreSQL package was found or applied for this sequence.

PG023 prepared package checkpoint:

- New package artifacts:
  `lorehold_brainstone_deck_swap_pg023_{precheck,apply,postcheck,rollback}_20260621_114447.sql`
  and `lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`.
- Package status is `prepared`, not applied.
- Proposed swap is `Brainstone` over `Generous Gift`.
- Package cites `080706` as candidate evidence: `14/64`, trusted, clean gates.
- Local SQLite remains pre-PG023 with `Generous Gift=1` and no `Brainstone`
  row.
- No PostgreSQL command or sync command was executed by this heartbeat.

PG023 external closure checkpoint:

- The package now reports `Status: applied_and_postchecked_and_battle_validated`,
  superseding the earlier prepared-only checkpoint.
- This heartbeat did not execute PG023 apply, rollback, deck swap, commit,
  push, cleanup, stash, or revert.
- Read-only PG postcheck returned `postcheck_passed=true`, with
  `gift_rows=0`, `brainstone_rows=1`, `deck_backup_rows=1`,
  `rule_backup_rows=1`, and `brainstone_rule_verified=true`.
- Deck sync report
  `sync_pg_target_deck_to_hermes_pg023_brainstone_20260621_114447.json`
  has `apply=true`, `cards_written=100`, `quantity_written=100`, and
  `target_deck_id=6`.
- Rule sync report
  `battle_card_rules_sqlite_from_pg_pg023_brainstone_20260621_114447.json`
  has `apply_sqlite_from_pg=true`, `pg_rows_loaded=5244`,
  `sqlite_inserted_or_updated=5211`.
- Current local SQLite focused check returns `Brainstone=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, and no `Generous Gift` row.
- Latest full battle validation is
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`:
  `64/64`, trusted, clean gates, tests `18/18`, Lorehold `14/64`,
  `forced_keep_after_bad_mulligan=13`.
- Fresh learned-deck audit
  `learned_deck_coherence_audit_20260621_130957.json` keeps aggregate
  `medium=13`; Lorehold active learned row remains `issues=[]` but now drifts
  by active-only `Generous Gift`, `Guttersnipe`, `Monument to Endurance` versus
  runtime-only `Brainstone`, `Silent Arbiter`, `Windborn Muse`.
- Completion status: PG023 is closed externally; active learned-deck mutation
  and mulligan/consistency remain open.

Temporary candidate latest checkpoint:

- After PG023 closure, a new external temporary runner became latest:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131126/summary.json`.
- Observed runner command used a temporary SQLite mutation:
  `Expedition Map` over `Electroduplicate`, then restored `knowledge.db` from
  backup on exit.
- Summary: `16/16`, trusted, clean gates, tests `18/18`, Lorehold `1/16`,
  `forced_keep_after_bad_mulligan=3`.
- Post-run SQLite check confirms persistent state restored to PG023:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Expedition Map`, no `Generous Gift`.
- Completion status remains unchanged: candidate is not a promotion signal,
  not a PostgreSQL deploy item, and not a cleanup item.

Latest PG023 recurring smoke checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131606/summary.json`.
- Summary: `16/16`, trusted, clean gates, tests `18/18`, Lorehold `3/16`,
  `forced_keep_after_bad_mulligan=5`.
- Runtime check after run: `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Generous Gift`,
  no `Expedition Map`, `100/100`.
- Completion status remains unchanged: PG023 closed, active learned-deck drift
  and mulligan/consistency remain open.

Temporary Thrill candidate checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132027/summary.json`.
- Observed temporary runner used `Thrill of Possibility` over `Boros Charm`
  with SQLite backup/restore.
- Summary: `16/16`, trusted, clean gates, tests `18/18`, Lorehold `2/16`,
  `forced_keep_after_bad_mulligan=4`.
- Runtime check after run: `Boros Charm=1`, `Brainstone=1`,
  `Electroduplicate=1`, `Silent Arbiter=1`, `Windborn Muse=1`,
  no `Thrill of Possibility`, `100/100`.
- Completion status remains unchanged: no deploy, no promotion, no cleanup.

Temporary Reprieve candidate checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`.
- Temporary runner used `Reprieve` over `Boros Charm` with SQLite
  backup/restore.
- Summary: `16/16`, trusted, clean gates, tests `18/18`, Lorehold `4/16`,
  `forced_keep_after_bad_mulligan=5`.
- Runtime check after run: `Boros Charm=1`, `Brainstone=1`,
  `Electroduplicate=1`, `Silent Arbiter=1`, `Windborn Muse=1`,
  no `Reprieve`, no `Generous Gift`, `100/100`.
- Completion status remains unchanged: no deploy, no promotion, no cleanup.

PG023 candidate scan checkpoint:

- New artifact:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_pg023_candidate_scan_20260621_132537.md`.
- Status: `no_promotion`.
- It classifies `131126`, `131606`, `132027`, and `132537` as temporary
  SQLite candidates and confirms no PostgreSQL apply/package.
- Completion status unchanged: candidates rejected; PG023 remains canonical
  current runtime, with full validation `122732` at `14/64`.

Focused zone-transition checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_140346/summary.json`.
- Scope is focused one-seed runtime validation:
  `run_profile=focused_zone_transition_fix_v3`,
  `run_scope=focused_seed`, `seeds_completed=1/1`.
- Final status is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`, target-pressure `pass=1`,
  table-intent `pass=1`, and test results `pass=18`.
- Completion status unchanged: this validates zone-transition runtime support
  but does not supersede PG023 full deck validation `122732`, does not open a
  PostgreSQL deploy item, and does not authorize cleanup.

PG023 combat-survival rebaseline checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_142400/summary.json`.
- Scope is PG023 16-seed recurring full rebaseline after combat-survival runtime
  response:
  `run_profile=pg023_rebaseline_after_combat_survival_16_seed`,
  `run_scope=recurring_full`, `seeds_completed=16/16`.
- Final status is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, and test results `pass=18`.
- Strategy signal is poor but gate-clean: Lorehold `1/16`, opponents `15/16`,
  `forced_keep_after_bad_mulligan=2`.
- Completion status unchanged: PG023 remains closed as deployed shape; the
  result reinforces the open consistency/combat-survival/conversion backlog.

PG023 priority-fix and Angel's Grace candidate checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_145948/summary.json`.
- Rebaselines: `140846` Lorehold `2/16`, `141620` Lorehold `1/16`, and
  `145423` Lorehold `1/16`; all trusted with clean gates and tests `pass=18`.
- Candidate `144336` was blocked by `forensic_audit=blocked`; do not use it as
  strategy truth.
- Candidate `145948` is trusted and clean but reaches only Lorehold `2/16` with
  `forced_keep_after_bad_mulligan=3`.
- Completion status unchanged: Angel's Grace over Boros Charm is rejected, no
  deploy/rollback opens, and PG023 remains closed as current deployed shape.

Latest manual 16-seed review checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_151645/summary.json`.
- A battle runner was still active at read time, so this is a checkpoint.
- `151645` reports `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required",
  "replay_decision_audit=review_required","strategy_audit=review_required"]`,
  target-pressure `pass=16`, table-intent `pass=16`, and tests `pass=18`.
- Strategy findings are active: `strategy_review_required_findings=4`,
  including `forced_keep_after_bad_mulligan=4`, `tutor_no_target=2`,
  `resource_cost_without_selection_context=1`, and
  `spending_unique_color_land=1`.
- Completion status unchanged: no deploy/rollback opens. Wait for runner exit
  and next artifact before making a final runtime-cache conclusion.

PG023 oracle-specific finisher contract checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_152154/summary.json`.
- No external runner remained active at final read time.
- `152154` reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, and tests `pass=18`.
- Strategy review findings returned to `0`; residual signal is
  `forced_keep_after_bad_mulligan=2`.
- Completion status unchanged: PG023 remains closed as deployed shape and no
  deploy/rollback opens. The result is trusted but still poor at `1/16`.

Magus candidate checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_153944/summary.json`.
- `153944` is blocked by `strategy_audit=blocked`; target-pressure,
  table-intent, and tests still pass.
- Candidate outcome is Lorehold `3/16`, opponents `12/16`, but it has one high
  strategy finding (`spending_last_land`) plus `spending_unique_color_land`.
- Runtime SQLite restored to PG023 focused shape with `Electroduplicate=1`.
- Completion status unchanged: Magus over Electroduplicate is rejected as a
  blocked candidate and no deploy/rollback opens.

Magus after mox trace fix checkpoint:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_160405/summary.json`.
- `160405` is trusted and gate-clean, superseding blocked `153944`.
- Candidate outcome is Lorehold `3/16`, opponents `12/16`, with residual
  `forced_keep_after_bad_mulligan=2`.
- Runtime SQLite restored to PG023 focused shape with `Electroduplicate=1`.
- Completion status unchanged: Magus over Electroduplicate is valid evidence
  but rejected for promotion; no deploy/rollback opens.

Victory Chimes rule fix and latest rebaseline:

- Victory Chimes local rule modeling is corrected and no longer an active
  pending item: reviewed-rule source now says verified curated
  `ramp_permanent`, not `draw_engine`.
- Local SQLite sync evidence:
  `victory_chimes_reviewed_rule_sqlite_sync_20260621_161900.json` records
  `inserted_or_updated=122`, `deleted_stale_reviewed_rows=1`, and
  `canonical_snapshot_rows_exported=3201`.
- Focused Victory Chimes regression tests passed (`Ran 3 tests ... OK`).
- Current latest battle advanced to `20260621_164710`: trusted, clean
  mandatory gates, tests `pass=18`, target-pressure/table-intent `pass=16`,
  strategy review findings `0`, Lorehold `2/16`, opponents `13/16`.
- Final runtime SQLite check: deck `6` is `100/100` and back to PG023 focused
  shape with `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, no
  focused `Magus of the Moat`.
- Completion status unchanged: no PostgreSQL deploy/rollback opens. The active
  work remains Lorehold consistency/mulligan quality and active learned-source
  lag governance.

Magus same-seed candidate after Victory fix:

- Latest battle advanced to `20260621_173334`, superseding `164710`.
- `173334` is trusted and gate-clean with tests `pass=18`,
  target-pressure/table-intent `pass=16`, and strategy review findings `0`.
- Outcome is Lorehold `3/16`, opponents `12/16`, with residual
  `forced_keep_after_bad_mulligan=2`.
- Final runtime SQLite check is restored to PG023 focused shape:
  `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, no focused Magus.
- Completion status unchanged: Magus remains rejected for promotion and no
  deploy/rollback opens.

Runtime cache drift after latest:

- A later local SQLite read found current deck `6` at `100/100` with
  `Magus of the Moat` and `Sphere of Safety`, while battle `latest` still
  points to `20260621_173334`.
- Backup
  `knowledge_db_backup_candidate_magus_sphere_after_victory_fix_20260621_174200.sqlite`
  preserves the prior focused state with `Electroduplicate` and
  `Victory Chimes`.
- Completion status: this is active runtime-cache drift after latest battle.
  No deploy/rollback opens and no restore/sync is authorized without explicit
  command approval.

Magus+Sphere candidate review-required closure:

- The active runner completed as latest `20260621_174142`.
- `174142` is `review_required` with mandatory divergences in forensic,
  replay-decision, and strategy gates.
- Side channels are green (`16/16/18`), but strategy has
  `strategy_review_required_findings=1`.
- Outcome is Lorehold `5/16`, opponents `11/16`, which cannot be used for
  promotion while gates require review.
- Final runtime SQLite check is back to `Electroduplicate` and
  `Victory Chimes`; no focused Magus or Sphere.
- Completion status: runtime drift is superseded, Magus+Sphere is rejected as
  review-required, and no deploy/rollback opens.
