# ManaLoom Post-Loop Smoke And Next Cycle - 2026-06-20

## Scope

This register closes the post-publication organization cycle after the
documentation heartbeat loop fix. It records stable evidence only:

- no deck swap was applied;
- no PostgreSQL write was performed;
- production smoke used only `GET` calls and local artifact reads;
- exact "current HEAD" must not be recursively re-stamped in tracked heartbeat
  docs after documentation-only commits.

## Worktree And Deploy Evidence

- Heartbeat-loop closure commit tested before this register:
  `3800c940501ba687369c5d8208d9eccfad0c1dcc`
  (`docs: close ManaLoom heartbeat loop`).
- Production `/health` matched that closure commit before this register was
  created: `status=healthy`, `environment=production`.
- After a 75-second post-commit wait, the worktree stayed clean:
  `git status --short --branch` showed only `## master...origin/master`;
  untracked non-ignored count was `0`;
  `git rev-list --left-right --count HEAD...origin/master` returned `0 0`.
- This register intentionally does not claim to be the final deployed SHA after
  its own commit. The final handoff for this cycle must use live `/health` and
  Git status, not another tracked heartbeat restamp.

## Production Read-Only Smoke

Smoke artifact:
`/tmp/manaloom_production_readonly_smoke_20260620_1358.json`

Result: `verdict=pass`.

Read-only public checks:

- `GET /health`: HTTP `200`, `status=healthy`,
  `git_sha=3800c940501ba687369c5d8208d9eccfad0c1dcc`.
- `GET /ready`: HTTP `200`, `status=ready`, database `healthy`,
  `cards_data.card_count=34329`.
- `GET /health/ready`: HTTP `200`, `status=ready`, database `healthy`,
  `cards_data.card_count=34329`.
- `GET /cards?name=Velomachus+Lorehold&limit=5`: HTTP `200`,
  `total_returned=1`, first result `Velomachus Lorehold`.
- `GET /community/decks?format=Commander&limit=1`: HTTP `200`, `rows=1`,
  public Commander total `45`.
- `GET /community/decks/1c3a57ee-98de-42a4-bf35-982558e3b930`: HTTP `200`,
  detail shape included `main_board`, `all_cards_flat`, `stats`, and owner
  fields. This public QA fixture had only one main-board row, so it proves
  route shape and DB reachability, not full 100-card Commander quality.
- `GET /rules?q=Commander&limit=3&meta=true`: HTTP `200`, `rows=3`,
  metadata included.

Expected auth-boundary checks:

- `GET /ai/ml-status` without token: HTTP `401`, JSON auth error.
- `GET /ai/commander-learning` without token: HTTP `401`, JSON auth error.

Battle smoke boundary:

- Live `POST /ai/simulate`, `POST /ai/simulate-matchup`, and deck write routes
  were not called because they are write-capable.
- At creation time, the latest local battle artifact was the read-only battle
  evidence:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`.
- That artifact reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, and `test_results_status_counts.pass=16`.
- Current later state is recorded below; do not treat `160459` as the live
  latest after the later target-pressure and review-only runtime checkpoints.

## Active Next Cycle

### 1. Deck Learned-Deck QA

Source:
`docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_181429.json`.

Aggregate state:

- active learned decks: `60`;
- medium severity: `13`;
- high severity: `0`;
- `commander_deck_quantity_mismatch=0`;
- `commander_quantity_mismatch=0`;
- `land_count_low_review=7`;
- `land_count_high_review=1`;
- `some_core_metadata_zero=5`.

Closed since the original post-loop register:

- PG-009 replaced the partial active `learned_deck:7` /
  `Korvold, Fae-Cursed King` row with accepted
  `commander_reference_decks` corpus data.
- Fresh coherence artifact `learned_deck_coherence_audit_20260620_172437`
  reports Korvold `parsed_quantity=100`, `resolved_quantity=100`,
  commander quantity `1`, and `issues=[]`.
- Later coherence artifact `learned_deck_coherence_audit_20260620_181429`
  keeps high severity at `0`, medium severity at `13`, and Lorehold
  `learned_deck:82` with `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `total_lands=33`,
  `has_wheel_of_misfortune=true`, and `has_reforge_the_soul=false`.
- The global high-severity count dropped from `2` to `0`.

Current highest-priority learned-deck work:

Medium land-count reviews:

- `learned_deck:105` / `Aang, at the Crossroads`: `23` lands.
- `learned_deck:150` / `Brigid, Clachan's Heart`: `23` lands.
- `learned_deck:173` / `Krark, the Thumbless`: `23` lands.
- `learned_deck:131` / `Lumra, Bellow of the Woods`: `48` lands.
- `learned_deck:104` / `Ral, Monsoon Mage`: `14` lands.
- `learned_deck:114` / `Rowan, Scion of War`: `23` lands.
- `learned_deck:137` / `Selvala, Explorer Returned`: `20` lands.
- `learned_deck:95` / `Yuriko, the Tiger's Shadow`: `22` lands.

Medium metadata-counter reviews:

- `learned_deck:5` / `Atraxa, Praetors' Voice`: `tutor_count=0`.
- `learned_deck:1` / `Krenko, Mob Boss`: `tutor_count=0`.
- `learned_deck:127` / `Sauron, Lord of the Rings`: `tutor_count=0`.
- `learned_deck:124` / `The Emperor of Palamecia`: `tutor_count=0`.
- `learned_deck:120` / `Yorion, Sky Nomad`: `tutor_count=0`.

Lorehold status:

- Lorehold `learned_deck:82` remains clean in the same artifact with
  `issues=[]`; it is not the first next-cycle target unless new evidence appears.

### 2. Battle Follow-Up - Historical 14:28 State

Original post-loop latest battle was trusted. The later heartbeat at
`2026-06-20 14:28 -0300` found a newer latest artifact:
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_170724/summary.json`.

Historical latest battle status at 14:28 -0300:

- `battle_replay_final_status=review_required`;
- mandatory divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`;
- tests still pass: `16/16`;
- forensic lineage is complete;
- `forensic_rule_findings=0`;
- `forensic_turn_findings=1`;
- `decision_audit_decision_findings=0`.

Concrete finding:

- seed `63211720`, turn `12`, player `Lorehold`;
- event `board_wipe_resolved`;
- severity `low`;
- finding: board wipe left more protected creatures (`5`) than destroyed (`3`).

This did not indicate a PostgreSQL deploy or deck swap by itself. It was a
battle/auditor follow-up around board-wipe protection accounting or gate policy.

Superseding closure at 2026-06-20 15:28 -0300:

- At that time, the latest symlink resolved to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_181004/summary.json`.
- That summary reported `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":16}`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `decision_audit_decision_findings=0`, `decision_audit_turn_findings=0`, and
  `action_findings=0`.
- The closure is tied to the documented Lorehold canonical
  `Wheel of Misfortune` over `Reforge the Soul` apply, whose result artifact
  `docs/hermes-analysis/master_optimizer_reports/pg_apply_lorehold_wheel_swap_result_20260620_180448.json`
  shows materialized deck `Wheel=1`, `Reforge=0`, `rows=100`,
  `total_cards=100`, and active learned deck `has_wheel=true`,
  `has_reforge=false`.
- The current learned-deck coherence artifact
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_181429.json`
  keeps Lorehold `learned_deck:82` clean with `issues=[]`.

Superseding target-pressure closure at 2026-06-20 16:00 -0300:

- The latest symlink now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/summary.json`.
- The current summary reports
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, and
  `test_results_status_counts={"pass":17}`.
- The mandatory gate list now includes `target_pressure`.
- Target-pressure evidence is clean:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_total=117`,
  `target_pressure_opponent_combat_to_target=117`,
  `target_pressure_opponent_combat_to_other=0`, and
  `target_pressure_opponent_multi_defender_attack=0`.

Later review-only runtime drift at 2026-06-20 16:30 -0300:

- The latest symlink now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_191248/summary.json`.
- The current summary reports `battle_replay_final_status=blocked` with
  `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=blocked","replay_decision_audit=review_required"]`.
- The blocking seed is `63211917`: `Goblin Bombardment` from
  `Dargo, the Shipwrecker #74 (real)` executed a `needs_review` /
  `review_only` canonical snapshot rule as `remove_creature`.
- Target-pressure remains clean in that latest run:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=84`, and
  `target_pressure_opponent_combat_to_other=0`.
- Runtime treatment has been implemented in `battle_analyst_v9.py`, with a new
  regression in `battle_card_specific_tests.py`; focused tests and seed
  auditors are clean.

Later latest state at 2026-06-20 16:50 -0300:

- The latest symlink now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_195007/summary.json`.
- The current summary reports `battle_replay_final_status=blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked","replay_decision_audit=review_required"]`.
- The target-pressure false positive from `20260620_194456` is closed:
  `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=193`, and
  `target_pressure_opponent_combat_to_other=0`.
- Remaining blockers are `functional_tags_json` forensic lineage for
  learned-opponent cards and one low board-wipe review finding:
  `forensic_rule_findings=26`, `forensic_turn_findings=1`,
  `decision_audit_turn_findings=1`.

Later latest state at 2026-06-20 17:06 -0300:

- The focused `20260620_200322` rerun closes the seed `63213000`
  `table_intent_*` target-pressure metadata false positive:
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `target_pressure_statuses={"pass":1}`,
  `forensic_rule_findings=0`, `decision_audit_turn_findings=0`, and
  tests `18/18` pass.
- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200409/summary.json`.
- The current full summary remains `blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked","table_intent=blocked"]`.
- Remaining full blockers are `functional_tags_json` forensic lineage for
  `Woodland Bellower` and `Shantotto, Tactician Magician`, table-intent
  `opponent_interaction_absent` on seeds `63212004`, `63212009`, and
  `63212019`, plus one real target-pressure split attack on seed `63212012`.

Later latest state at 2026-06-20 17:39 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_203616/summary.json`.
- The current full summary remains `blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`.
- The recurring wrapper now includes `target_pressure` in
  `mandatory_gates_required_for_final_status` and in `mandatory_gate_statuses`;
  this makes target-pressure a visible final-status blocker instead of only a
  side counter.
- Event-contract drift from `20260620_202211` is closed under current code:
  `/tmp/event_contract_static_202211_current_code.*` reports
  `observed_unclassified_total=0` and `static_unclassified_total=0`.
- Table-intent now passes `16/16`; replay-decision/action-critic/event-contract
  gates also pass.
- Remaining full blockers are `functional_tags_json` forensic lineage on seeds
  `63212038`, `63212042`, `63212047`, `63212048`, and `63212050`, plus
  target-pressure attacks away from Lorehold on seeds `63212036`, `63212042`,
  and `63212046`.

Later latest state at 2026-06-20 17:40 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_204002/summary.json`.
- The current full summary remains `blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`.
- Table-intent, event-contract, replay-decision, action-critic, effect
  coverage, focused-template dispatch, unknown-template backlog, and decision
  trace taxonomy all pass; tests are `18/18`.
- Remaining full blockers are `functional_tags_json` forensic lineage on seeds
  `63212042`, `63212047`, `63212048`, and `63212050`, plus target-pressure
  attacks away from Lorehold on seeds `63212042` and `63212046`.

Later latest state at 2026-06-20 18:01 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_205821/summary.json`.
- That full summary was `review_required`, not `blocked`, with
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Target-pressure, table-intent, event-contract, replay-decision,
  action-critic, effect coverage, focused-template dispatch,
  unknown-template backlog, and decision trace taxonomy all pass; tests are
  `18/18`.
- The only current review residual is seed `63212068`, where two low
  `Goblin Bombardment` findings report runtime effect `passive` differing from
  registry effect `remove_creature`.
- Round5 artifacts were detected:
  `card_battle_rules_pg_table_intent_promotions_round5_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=3`, selected cards
  `Big Score` and `Spelltwine`; the paired SQLite sync artifact declares
  `pg_rows_loaded=5224`, `sqlite_inserted_or_updated=5142`, and
  `canonical_snapshot_rows_exported=3181`. This heartbeat did not execute
  those writes/syncs.

Later latest state at 2026-06-20 18:05 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_210513/summary.json`.
- That full summary was `blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- Target-pressure, table-intent, event-contract, replay-decision,
  action-critic, effect coverage, focused-template dispatch,
  unknown-template backlog, and decision trace taxonomy all pass; tests are
  `18/18`.
- Active forensic blockers are high/medium `functional_tags_json` lineage for
  `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, and
  `The Unagi of Kyoshi Island`; low registry/runtime drift is also visible for
  `Apex of Power`.
- Round6 artifacts were detected:
  `card_battle_rules_pg_table_intent_promotions_round6_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=2`, selected card
  `Goblin Bombardment`; the paired SQLite sync artifact declares
  `pg_rows_loaded=5225`, `sqlite_inserted_or_updated=5143`, and
  `canonical_snapshot_rows_exported=3181`. This heartbeat did not execute
  those writes/syncs.
- Round7 artifacts appeared after `210513` and target the current blocker
  cards: `Apex of Power`, `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`,
  and `The Unagi of Kyoshi Island`. The paired sync reports
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`, and
  `canonical_snapshot_rows_exported=3185`.
- A 20s recheck still found latest at `20260620_210513`; that reading is now
  superseded by the later `211217` post-round7 battle state below.

Later latest state at 2026-06-20 18:13 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211217/summary.json`.
- That full summary was still `blocked` with
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- Target-pressure, table-intent, event-contract, replay-decision,
  action-critic, effect coverage, focused-template dispatch,
  unknown-template backlog, and decision trace taxonomy all pass; tests are
  `18/18`.
- Target-pressure is clean:
  `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=186`,
  `target_pressure_opponent_combat_to_other=3`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- Active forensic blockers are high/medium `functional_tags_json` lineage for
  `Tellah, Great Sage` on seed `63212112` and `Practical Research` on seed
  `63212123`, both from `The Emperor of Palamecia #42 (real)`.
- This heartbeat did not execute the round7 apply/sync or run the battle; it
  only detected the artifacts and reconciled the superseding latest result.

Later latest state at 2026-06-20 18:17 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211648/summary.json`.
- That full summary was `review_required` with
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Target-pressure, table-intent, event-contract, replay-decision,
  action-critic, effect coverage, focused-template dispatch,
  unknown-template backlog, and decision trace taxonomy all pass; tests are
  `18/18`.
- Target-pressure is clean:
  `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=200`,
  `target_pressure_opponent_combat_to_other=0`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- Active forensic residual is low registry/runtime drift for
  `Breena, the Demagogue` on seed `63212130`: runtime effect `passive`
  differs from registry effect `draw_engine` on `spell_cast` and
  `spell_resolved`.
- This heartbeat did not execute any apply/sync or run the battle; it only
  reconciled the superseding latest result.

Later latest state at 2026-06-20 18:21 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`.
- The current full summary is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]` and
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Target-pressure, forensic, table-intent, event-contract, replay-decision,
  action-critic, effect coverage, focused-template dispatch,
  unknown-template backlog, and decision trace taxonomy all pass; tests are
  `18/18`.
- Target-pressure remains clean:
  `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=214`,
  `target_pressure_opponent_combat_to_other=3`, and
  `target_pressure_opponent_multi_defender_attack=2`.
- Forensic findings are now `0`; action and decision findings are also `0`.
- Round8 and round9 artifacts appeared externally before this green latest:
  round8 declares `pg_inserted_or_updated=2` for `Practical Research` and
  `Tellah, Great Sage`; round9 declares `pg_inserted_or_updated=2` for
  `Breena, the Demagogue`; paired sync artifacts report
  `pg_rows_loaded=5232/5233` and `sqlite_inserted_or_updated=5150/5151`.
- This heartbeat did not execute any apply/sync or run the battle; it only
  reconciled the superseding latest result.

Later latest state at 2026-06-20 19:31 -0300:

- The latest full recurring run now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221652/summary.json`.
- The current full summary remains `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]` and
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Target-pressure, forensic, table-intent, event-contract, replay-decision,
  action-critic, effect coverage, focused-template dispatch,
  unknown-template backlog, and decision trace taxonomy all pass; tests are
  `18/18`.
- Target-pressure remains clean:
  `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=190`,
  `target_pressure_opponent_combat_to_other=2`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- Forensic findings are `0`; action, decision, and table-intent findings are
  also `0`.
- Local runtime/test source currently includes attack-limit, attack-tax,
  defender attack restriction, and Lorehold self-preservation combat handling;
  `py_compile` and `test_battle_analyst_v10_3.py` passed for that source.
- This heartbeat did not execute PostgreSQL apply, SQLite sync, deck swap,
  cleanup, stage, commit, push, or battle rerun.

Later latest state at 2026-06-20 19:48 -0300:

- New PG-011 sync/cache artifacts appeared after the `221652` read, and
  SELECT-only checks showed the Lorehold defense variant already applied in
  PostgreSQL.
- PG-011 postcheck passed read-only:
  `out_qty_in_target_deck=0`, `in_qty_in_target_deck=6`,
  `target_deck_qty=100`, `target_deck_rows=100`,
  `active_learned_deck_ok=1`.
- Fresh learned-deck coherence artifact
  `learned_deck_coherence_audit_20260620_224441.json` keeps Lorehold
  `learned_deck:82` with `issues=[]`, `parsed_quantity=100`, and
  `resolved_quantity=100`.
- At that checkpoint, the fresh full recurring battle resolved to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`.
- That now-superseded full summary is `review_required` with
  `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Target-pressure and table-intent pass `16/16`; action, replay-decision,
  event-contract, effect coverage, focused-template dispatch,
  unknown-template backlog, and decision trace taxonomy pass; tests are
  `18/18`.
- The now-superseded residual is six low `Flame Wave` forensic findings on seeds
  `63212248`, `63212253`, and `63212256`; no battle blocker is active.
- This heartbeat did not execute the PG-011 PostgreSQL apply command, did not
  manually apply a deck swap by command, and did not stage, commit, or push.

Current battle work should not target the old seed `63211720` finding unless a
future battle artifact reintroduces it. This `224455` low-forensic state is now
superseded by `232534`, which is trusted. Continue monitoring only; do not
apply PostgreSQL without exact approval if future drift appears.

Previous trusted-run strategy observations were not blockers:

- `strategy_findings=5`;
- all five are `forced_keep_after_bad_mulligan`;
- severity is `medium`;
- `strategy_review_required_findings=0`;
- `action_findings=0`;
- `decision_audit_decision_findings=0`;
- `forensic_rule_findings=0`;
- `forensic_turn_findings=0`.

Next battle work should treat target-pressure evidence as mandatory before
using Lorehold WR or replay outcomes for deck optimization. Follow-up work can
still improve confidence labeling around forced mulligan-cap keeps or add
specific decision-trace contracts for currently uncovered accepted types. It
should not trigger a PostgreSQL deploy by itself.

### 3. Production Smoke Gap

Authenticated production deck/AI reads were not fully smoked because no reusable
read-only QA token was available in this cycle, and creating a production test
user would be a DB write.

Next safe options:

1. use an existing QA token if Rafael provides one;
2. create a documented non-production or explicitly authorized production QA
   read fixture;
3. add a backend-owned read-only smoke route only if product/security policy
   accepts it.

### 4. PostgreSQL Gate

No current PostgreSQL apply is ready.

PG-003 remains blocked by policy:

- oracle/card text/type backlog still exists;
- previous planner state had `missing_any=363`;
- `backfill_ready=0`;
- `db_mutations=false`.

The next PostgreSQL write may happen only when all items below exist together:

1. exact row-level diff;
2. source-of-truth policy for the rows;
3. read-only precheck;
4. apply SQL;
5. rollback SQL;
6. postcheck SQL;
7. runtime or artifact evidence after apply.

Until then, deck and battle investigation should stay in code/tests/artifacts,
not database mutation.

## Superseding Post-Loop Smoke - 2026-06-20 18:27 -0300

This section supersedes the earlier "no current PostgreSQL apply is ready"
state for the table-intent battle blocker sequence. Rafael later authorized the
central auditor to own the full deploy/cache/docs/worktree loop, and round5
through round9 battle-rule promotions were applied and runtime-synced before
the final green battle.

Historical smoke superseded by the 20:30 update:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`.
- Status: `battle_replay_final_status=review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- Mandatory gates: forensic, target-pressure, table-intent, action critic,
  replay-decision, decision-trace contract, unknown-template backlog, and tests
  all run under the current contract; only forensic is review-required, with
  low `Flame Wave` findings.
- Final cache-sync artifact:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg011_lorehold_defense_20260620_193849.json`.
- One battle log for review:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/seed_63212248/replay.txt`.

Historical next cycle, superseded by the 20:30 update:

1. At this checkpoint, `20260620_224455` was the real-battle baseline for
   Lorehold with the low-forensic-review caveat. It is now superseded by
   `20260620_232534`.
2. Do not treat the latest result as proof that Lorehold is optimal: opponents
   won `15/16` and Lorehold won `1/16`.
3. Optimize deck decisions against table-intent pressure with explicit
   before/after battle evidence and no silent swaps.
4. PG-011 is observed as externally applied and synced. Do not reapply it; any
   further database or deck change still requires exact apply-command approval.

## Current Battle/Deck Monitor Update - 2026-06-20 20:30 -0300

This update supersedes the `20260620_224455` low `Flame Wave` review state.

Historical smoke superseded by the 20:49 update:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_232534/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Mandatory divergences: `[]`.
- Findings: forensic `0`, action `0`, replay-decision `0`.
- Target-pressure: `pass=16`, `target_pressure_findings=0`,
  `opponent_combat_to_target=231`, `opponent_combat_to_other=7`,
  `opponent_multi_defender_attack=1`.
- Table-intent: `pass=16`.
- Tests: `18/18`.

PostgreSQL/cache evidence:

- PG-012 `Flame Wave`, PG-013 `Brainstone`, and PG-014 `Sphere of Safety` were
  observed as externally applied through read-only postchecks. This heartbeat
  did not run their apply commands.
- PG-014 sync artifact:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg014_sphere_20260620_202250.json`
  with `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`, and
  `canonical_snapshot_rows_exported=3195`.
- Local cache evidence shows `Sphere of Safety` as curated/verified/auto
  `attack_tax` and stale generated draw rows disabled.

Learned-deck evidence:

- Latest read-only coherence artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_233027.json`.
- Lorehold `learned_deck:82` remains `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, no premium Mox, no PG/SQLite name drift, and
  commander identity `single_commander_identity`.
- The remaining Lorehold strategy counter is medium
  `lorehold_strategy_big_spell_finishers_gap` from the defense variant. It is
  not a deck-resolution failure and does not authorize a silent swap.

Historical next cycle superseded by the 20:49 update:

1. Use `20260620_232534` as the current real-battle baseline.
2. Keep PG-012/PG-013/PG-014 closed unless a future SELECT, sync report, or
   battle artifact proves rollback/drift.
3. Continue treating any further Lorehold deck change as a separate
   before/after battle experiment requiring explicit approval before applying
   swaps or PostgreSQL writes.

## Current Battle/Deck Monitor Update - 2026-06-20 20:37 -0300

This update superseded the `232534` trusted state temporarily, but is itself
superseded by the later `234004` trusted latest. It does not reopen
PG-012/PG-013/PG-014.

Historical smoke superseded by the 20:40 update:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_233350/summary.json`.
- Status: `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- Mandatory divergences: `["forensic_audit=blocked"]`.
- Forensic: `forensic_rule_findings=2`,
  `forensic_severity_counts={"high":1,"medium":1}`.
- Clean gates: target-pressure `pass=16`, table-intent `pass=16`,
  action findings `0`, replay-decision findings `0`, tests `18/18`.

Active blocker:

- `Arcane Epiphany`, seed `63212310`, turn `10`,
  `The Emperor of Palamecia #42 (real)`, effect `draw_cards`, source
  `functional_tags_json`.
- PostgreSQL SELECT-only evidence shows one `cards` row and `0`
  `card_battle_rules` rows for `Arcane Epiphany`.
- Local cache also has `0` `battle_card_rules` rows for `Arcane Epiphany`.

Historical next cycle superseded by the 20:40 update and later by PG-015/Wrath:

1. Treat `Arcane Epiphany` as the active battle-rule backlog item only if the
   latest still reproduces it.
2. Do not apply any Arcane package without exact approval of an apply command.
3. Prepare/review row-level precheck/apply/rollback/postcheck, then sync Hermes
   runtime cache and rerun battle only if the apply is approved.

## Current Battle/Deck Monitor Update - 2026-06-20 20:40 -0300

Current smoke:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234004/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Mandatory divergences: `[]`.
- Findings: forensic `0`, action `0`, replay-decision `0`.
- Target-pressure: `pass=16`, `target_pressure_findings=0`.
- Table-intent: `pass=16`.
- Tests: `18/18`.

Next cycle:

1. Use `20260620_234004` as the current real-battle baseline.
2. Keep PG-012/PG-013/PG-014 closed.
3. Treat `Arcane Epiphany` only as a candidate from superseded `233350`;
   it is not active in the current latest unless a future artifact reintroduces
   it.

## Current Battle/Deck Monitor Update - 2026-06-20 20:49 -0300

Current smoke at this checkpoint:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234900/summary.json`.
- Status: `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- Mandatory divergences: `["forensic_audit=blocked"]`.
- Findings: forensic `2` with severity `{"high":1,"medium":1}`,
  action `0`, replay-decision `0`.
- Target-pressure: `pass=16`, `target_pressure_findings=0`.
- Table-intent: `pass=16`.
- Tests: `18/18`.

Active blocker:

- `Arcane Epiphany` candidate, effect `draw_cards`, source
  `functional_tags_json`, seed `63212310`, turn `10`.
- PostgreSQL/local cache have `0` battle-rule rows for the card.

Next cycle:

1. Re-read `latest` first; another external runner was active after this
   checkpoint.
2. If `Arcane Epiphany` remains the active blocker, prepare a row-level package
   and do not apply it without exact approval.
3. Keep PG-012/PG-013/PG-014 closed unless drift evidence appears.

## Current Battle/Deck Monitor Update - 2026-06-20 20:52 -0300

Current smoke after the runner active at 20:49 completed:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235219/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Mandatory divergences: `[]`.
- Findings: forensic `0`, action `0`, replay-decision `0`.
- Target-pressure: `pass=16`, `target_pressure_findings=0`.
- Table-intent: `pass=16`.
- Event-contract observed/static unclassified totals: `0/0`.
- Tests: `test_results_status_counts={"pass":18}`; compatibility fields
  `tests_passed` and `tests_total` are `null`.

Next cycle:

1. Use `20260620_235219` as the current real-battle baseline until `latest`
   advances again.
2. Keep PG-012/PG-013/PG-014 closed.
3. Treat `Arcane Epiphany` only as a candidate from superseded `233350`
   and `234900`; do not prepare/apply it unless a future latest reintroduces the
   blocker or Rafael explicitly prioritizes the package.

## Current Battle/Deck Monitor Update - 2026-06-20 20:59 -0300

Current smoke after externally detected PG-015/Wrath artifacts:

- PG-015/Wrath artifacts:
  `wrath_of_god_battle_rule_pg015_*_20260620_205619.*` and
  `battle_card_rules_sqlite_from_pg_pg015_wrath_20260620_205900.json`.
- PG-015/Wrath read-only postcheck: `curated_executable_rows=1`,
  `stale_enabled_wipe_rows=0`; local cache has `Wrath of God` as
  `curated/verified/auto` `board_wipe`.
- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235914/summary.json`.
- Status: `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- Mandatory divergences: `["forensic_audit=blocked"]`.
- Findings: forensic `2` with severity `{"high":1,"medium":1}`, action `0`,
  replay-decision `0`.
- Target-pressure: `pass=16`, `target_pressure_findings=0`.
- Table-intent: `pass=16`.
- Tests: `test_results_status_counts={"pass":18}`.

Active blocker:

- `Arcane Epiphany`, effect `draw_cards`, source `functional_tags_json`, seed
  `63212310`, turn `10`; medium `spell_cast` and high `spell_resolved`.
- PostgreSQL/local cache have `0` battle-rule rows for the card from prior
  read-only checks.

Next cycle:

1. Use `20260620_235914` as the current real-battle latest until the symlink
   advances again.
2. Keep PG-012/PG-013/PG-014 closed and keep PG-015/Wrath closed for PG/cache
   state unless rollback/drift appears.
3. Treat `Arcane Epiphany` as the active pending battle-rule lineage item. Do
   not apply a package without exact approval of the command.

## Current Battle/Deck Monitor Update - 2026-06-20 21:08 -0300

Current smoke after further external Wrath variant runners:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_000827/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Mandatory divergences: `[]`.
- Findings: forensic `0`, action `0`, replay-decision `0`.
- Target-pressure: `pass=16`, `target_pressure_findings=0`.
- Table-intent: `pass=16`.
- Tests: `test_results_status_counts={"pass":18}`.

Next cycle:

1. Use `20260621_000827` as the current real-battle latest until the symlink
   advances again.
2. Keep PG-012/PG-013/PG-014 closed and keep PG-015/Wrath closed for PG/cache
   plus battle state unless rollback/drift appears.
3. Treat `Arcane Epiphany` only as a candidate from superseded `235914`; do not
   prepare/apply a package unless a future latest reintroduces the blocker or
   Rafael explicitly prioritizes it.

## Current Battle/Deck Monitor Update - 2026-06-20 22:14 -0300

Current smoke after external PG-016, PG-017, and PG-018 artifacts:

- Latest completed battle summary at the checkpoint:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_010452/summary.json`.
- Status: `battle_replay_final_status=blocked`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_blocked`.
- Mandatory divergences: `["forensic_audit=blocked"]`.
- Scope: `invocation_kind=codex_pg017_full64_real_deck_baseline`,
  `seeds_requested=64`, `seeds_completed=64`, `start_seed=63212310`.
- Findings: forensic `2` with severity `{"high":1,"medium":1}`, action `0`,
  replay-decision `0`.
- Target-pressure: `pass=64`, `target_pressure_findings=0`.
- Table-intent: `pass=64`.
- Tests: `test_results_status_counts={"pass":18}`.

PG/cache evidence:

- PG-016 anti-combat is externally applied/synced and read-only postchecked for
  five curated executable rows across `Norn's Annex`, `Windborn Muse`,
  `Silent Arbiter`, `Ensnaring Bridge`, and `Magus of the Moat`.
- PG-017 Arcane Epiphany is externally applied/synced and read-only postchecked
  with one curated executable `draw_cards` row.
- PG-018 opponent forensic is externally applied/synced and read-only
  postchecked for `Jin-Gitaxias, Core Augur` and `Chandra, Flameshaper`.
  Local Hermes SQLite selects both rows as curated/verified/auto.

Next cycle:

1. Re-read `latest` first. A post-PG018
   `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310`
   runner was active at this checkpoint.
2. Keep PG-016, PG-017, and PG-018 closed for PostgreSQL/cache state unless
   SELECT, sync report, or snapshot evidence proves rollback/drift.
3. Do not reapply any PG package and do not apply deck swaps. Battle closure for
   PG-018 depends on the next completed summary.

## Current Battle/Deck Monitor Update - 2026-06-20 22:44 -0300

Current smoke after the post-PG018 battle completed:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_012833/summary.json`.
- Status: `battle_replay_final_status=review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- Mandatory divergences: `["strategy_audit=review_required"]`.
- Scope: `invocation_kind=codex_pg018_full64_real_deck_baseline`,
  `seeds_requested=64`, `seeds_completed=64`, `start_seed=63212310`.
- Findings: forensic `0`, action `0`, replay-decision `0`.
- Target-pressure: `pass=64`, `target_pressure_findings=0`.
- Table-intent: `pass=64`.
- Tests: `test_results_status_counts={"pass":18}`.
- Strategy: `strategy_findings=17`, `strategy_low_confidence_findings=16`,
  `strategy_review_required_findings=1`.

PG/cache evidence:

- PG-018 is battle-forensic closed by `012833`.
- PG-019 artifacts appeared externally for `Jin-Gitaxias, Core Augur`:
  `jin_gitaxias_non_wheel_pg019_*_20260621_013900.*` and
  `battle_card_rules_sqlite_from_pg_pg019_jin_non_wheel_20260621_014100.json`.
- Read-only PG-019 postcheck and local Hermes SQLite both show
  `wheel_like=false` on the curated/verified/auto Jin-Gitaxias draw-seven rule.

Next cycle:

1. Re-read `latest` first. A post-PG019
   `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310`
   runner was active at this checkpoint.
2. Keep PG-019 closed for PostgreSQL/cache state unless SELECT, sync report, or
   snapshot evidence proves rollback/drift.
3. Battle closure for PG-019 depends on the next completed summary. Do not
   reapply PG-019 and do not apply deck swaps.

## Current Battle/Deck Monitor Update - 2026-06-20 23:14 -0300

Current smoke after local Hermes optimizer apply:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020427/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Mandatory divergences: `[]`.
- Scope: `run_scope=recurring_full`,
  `invocation_kind=codex_pg019_post_apply_windborn_16`,
  `seeds_requested=16`, `seeds_completed=16`, `start_seed=63212310`.
- Findings: forensic `0`, action `0`, replay-decision `0`.
- Target-pressure: `pass=16`, `target_pressure_findings=0`.
- Table-intent: `pass=16`.
- Tests: `test_results_status_counts={"pass":18}`.
- Strategy: `strategy_findings=5`, `strategy_low_confidence_findings=5`,
  `strategy_review_required_findings=0`.

Deck-state evidence:

- Local Hermes apply artifact:
  `master_optimizer_apply_20260621_020406.md`.
- Local Hermes `deck_id=6` now has `Windborn Muse=1`, no `Guttersnipe`, and
  `100/100` cards.
- PostgreSQL materialized Lorehold deck
  `528c877f-f829-4207-95e6-73981776c323` still has `Guttersnipe=1`, no
  `Windborn Muse`, and `100/100` cards.
- The apply artifact states that no production database was mutated.

Next cycle:

1. Re-read `latest` first. A newer 64-seed run directory `20260621_020729`
   existed without `summary.json`, and the runner was active.
2. Treat Windborn-over-Guttersnipe as local Hermes runtime evidence only until
   Rafael explicitly approves any PostgreSQL/learned-deck promotion.
3. Do not apply deck swaps, do not reapply PG packages, and do not clean the
   rollback/apply artifacts without exact approval.

Final 64-seed reconciliation:

- Latest advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `seeds_requested=64`,
  `seeds_completed=64`, forensic findings `0`, target-pressure `pass=64`,
  table-intent `pass=64`, action findings `0`, replay-decision findings `0`,
  tests `18/18`, and `strategy_review_required_findings=0`.
- No active battle runner remained in the final process check.

## Current Battle/Deck Monitor Update - 2026-06-20 23:45 -0300

Current smoke:

- Latest completed battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024220/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Scope: `invocation_kind=codex_pg020_candidate_ensnaring_bridge_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`.
- Findings: forensic `0`, action `0`, replay-decision `0`.
- Target-pressure: `pass=16`; table-intent: `pass=16`; tests: `18/18`.
- Strategy: `strategy_findings=7`, `strategy_low_confidence_findings=7`,
  `strategy_review_required_findings=0`.

Learned-deck recheck:

- New read-only learned-deck audit:
  `learned_deck_coherence_audit_20260621_024551.json`.
- Lorehold `learned_deck:82` remains shape-clean, but name drift is now active:
  active learned deck still differs from PG/Hermes runtime after PG-020.

Next cycle:

1. Re-read `latest` first. A newer run directory `20260621_024527` had no
   `summary.json`, and a 16-seed runner was active.
2. Keep Ensnaring Bridge over Monument to Endurance candidate-only unless an
   approved package/precheck/postcheck appears.
3. Do not mutate active learned deck to resolve name drift without explicit
   approval.

Final candidate reconciliation:

- Latest advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024527/summary.json`.
- Status: `trusted_for_strategy_learning`, candidate
  `Silent Arbiter` over `Monument to Endurance`, `16/16` seeds completed,
  mandatory divergences `[]`, forensic findings `0`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package exists for this candidate; a newer run directory
  `20260621_024906` was active.

## Next Cycle After PG-020 - 2026-06-20 23:40 -0300

Closed:

- `Windborn Muse` over `Guttersnipe` is now applied to PostgreSQL deck
  `528c877f-f829-4207-95e6-73981776c323`, synced back to Hermes `deck_id=6`,
  and validated in 64-seed battle.
- Latest proof:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022700/summary.json`.
- Result: `4/64 = 6.25%`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, tests `18/18`.

Still failing:

- Lorehold remains the table focus: `912` opponent combat-pressure events to
  Lorehold versus `12` to other players.
- `forced_keep_after_bad_mulligan` remains present in `15/64` seeds.
- The deck needs stronger survival/keep stability before more payoff work.

Recommended next cycle:

1. Do not revert PG-020 unless a later postcheck or battle artifact shows a
   regression.
2. Scan and test stronger survival candidates against the post-PG baseline:
   more attack restriction/tax, life buffer, early blockers, or draw/selection
   that improves keep quality.
3. Benchmark one candidate at a time with temporary swaps and same seed window.
4. Promote to PostgreSQL only after a clean full-confirmation run and exact
   precheck/apply/postcheck/rollback package.

## Latest Candidate Reading - 2026-06-20 23:49 -0300

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024906/summary.json`.
- `invocation_kind=codex_pg020_candidate_norns_annex_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No `Norn's Annex`/`PG021`/`024906` package was found under
  `docs/hermes-analysis/master_optimizer_reports`.
- Status: candidate-only evidence after PG-020. Do not promote without an
  explicit precheck/apply/postcheck/rollback package and approval of the exact
  command.

## Latest Review-Required Candidate - 2026-06-20 23:52 -0300

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_025233/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=review_required`.
- Mandatory divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`.
- The concrete blocker is seed `63212318`, turn `12`,
  `board_wipe_resolved`: low-severity finding that a board wipe left `9`
  protected creatures and destroyed `7`.
- Target pressure, table intent, and test suite stayed clean (`pass=16`,
  `pass=16`, `18/18`), so this is a replay/forensic trust blocker, not a
  PostgreSQL deploy signal.

## Magus 64-Seed Review-Required Recheck - 2026-06-21 00:17 -0300

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_030022/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=review_required`.
- Mandatory divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`.
- Same concrete blocker as the 16-seed run: seed `63212318`, turn `12`,
  `board_wipe_resolved`, low severity, board wipe left `9` protected creatures
  versus `7` destroyed.
- Target pressure and table intent stayed clean (`pass=64`, `pass=64`) and
  tests stayed `18/18`.
- No PG package exists for this Magus candidate, so it remains non-promotable
  candidate evidence.
- Fresh learned-deck coherence audit
  `learned_deck_coherence_audit_20260621_031653.json` is read-only and keeps
  the same global `medium=13` count; Lorehold remains shape-clean but has
  active-vs-runtime drift plus the big-spell finisher gap.

## Corrected Magus Candidate Reading - 2026-06-21 00:18 -0300

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_031617/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_magus_moat_for_monument_16`,
  `run_scope=recurring_full`, `seeds_requested=16`, `seeds_completed=16`,
  and `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`, forensic turn
  findings `0`, replay decision turn findings `0`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- No PG package exists for the corrected candidate. It is suitable as candidate
  evidence for review, not as an apply path.

## Corrected Silent Arbiter 64-Seed Reading - 2026-06-21 00:52 -0300

- Latest completed summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_silent_arbiter_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`, forensic turn
  findings `0`, replay decision turn findings `0`, target-pressure `pass=64`,
  table-intent `pass=64`, tests `18/18`.
- Strategy signal remains weak (`8` target wins, `54` opponent wins,
  `forced_keep_after_bad_mulligan=15`).
- No PG package exists for the corrected Silent Arbiter candidate. It is
  suitable as candidate evidence for review, not as an apply path.

## PG021/PG022 Observed Applied And Smoke-Trusted - 2026-06-21 01:55 -0300

- PG021 read-only postcheck passed for global attack-rule scope:
  `rule_rows=3`, all checks `true`, `postcheck_passed=true`.
- PG021 sync report:
  `battle_card_rules_sqlite_from_pg_pg021_global_attack_scope_20260621_043814.json`,
  `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `sqlite_inserted_or_updated=4`.
- PG022 read-only postcheck passed:
  `deck_rows=100`, `deck_quantity=100`, `Monument to Endurance=0`,
  `Silent Arbiter=1`, `backup_rows=1`, `postcheck_passed=true`.
- PG022 sync report:
  `sync_pg_target_deck_to_hermes_pg022_silent_arbiter_20260621_044155.json`,
  `cards_written=100`, `quantity_written=100`.
- Post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`,
  `codex_pg022_post_pg_sync_silent_arbiter_16`, `3/16`, trusted, clean gates,
  tests `18/18`.
- Fresh learned-deck coherence
  `learned_deck_coherence_audit_20260621_045522.json` remains `medium=13`;
  Lorehold remains shape-clean but active learned deck still differs from
  PG/SQLite by `Guttersnipe`/`Monument to Endurance` versus
  `Silent Arbiter`/`Windborn Muse`.

Next cycle:

- Do not reapply PG021/PG022.
- Full post-PG022 battle rerun is now recorded:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`,
  `codex_pg022_post_pg_sync_silent_arbiter_64`, `8/64`, trusted, clean gates.
- Keep active learned-deck mutation blocked until explicit approval.
- Next technical cycle should target mulligan/curve/consistency because
  `forced_keep_after_bad_mulligan=15` remains in the full post-sync battle.

## Candidate Scan Follow-Up - 2026-06-21 02:27 -0300

- Latest completed battle summary now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_052416/summary.json`.
- `run_profile=candidate_reprieve_for_generous_gift_16`,
  `invocation_kind=codex_candidate_scan`, `seeds_requested=16`,
  `seeds_completed=16`.
- Final status is `review_required` because
  `mandatory_gate_divergences=["strategy_audit=review_required"]`.
- Other mandatory surfaces stayed clean: forensic findings `0`, replay
  decision findings `0`, target-pressure `pass=16`, table-intent `pass=16`,
  tests `18/18`.
- Strategy signal is not promotable as-is: `5/16` Lorehold wins,
  `forced_keep_after_bad_mulligan=5`, `wheel_opponent_refill_risk=1`.
- Local SQLite restored after the temporary runner: `Generous Gift=1` remains
  in `deck_id=6`; `Reprieve`, `Artist's Talent`, and `Brainstone` are not
  persisted.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.
- Preserve PG022 full validation as the current canonical deck proof:
  `lorehold_deck6_pg022_silent_arbiter_validation_20260621_044758.md` and
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`.

## Engine-Fix Candidate Scan Follow-Up - 2026-06-21 03:06 -0300

- Latest completed battle summary now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_054803/summary.json`.
- `run_profile=recurring_16_seed`,
  `invocation_kind=codex_candidate_combo_scan`, `seeds_requested=16`,
  `seeds_completed=16`.
- Final status is `trusted_for_strategy_learning` with clean gates:
  `mandatory_gate_divergences=[]`, forensic findings `0`, replay decision
  findings `0`, target-pressure `pass=16`, table-intent `pass=16`, tests
  `18/18`.
- Strategy signal is poor: `1/16` Lorehold wins and
  `forced_keep_after_bad_mulligan=7`.
- Earlier post-fix scans were also gate-clean:
  `053446` candidate `4/16`, `053937` baseline `3/16`, and `054357`
  candidate-after-fix `4/16`.
- No new learned-deck coherence artifact appeared after
  `learned_deck_coherence_audit_20260621_045522.json`.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## PG023 External Closure + Latest Full Validation - 2026-06-21 10:07 -0300

- PG023 package
  `lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md` now reports
  `Status: applied_and_postchecked_and_battle_validated`.
- This heartbeat did not execute PG023 apply, rollback, deck swap, commit,
  push, cleanup, stash, or revert.
- Read-only PG postcheck with
  `PGOPTIONS='-c default_transaction_read_only=on'` returned
  `postcheck_passed=true`, `gift_rows=0`, `brainstone_rows=1`,
  `brainstone_rule_verified=true`.
- PG -> Hermes deck sync artifact reports `apply=true`, `cards_written=100`,
  `quantity_written=100`, and `target_deck_id=6`.
- Local SQLite `deck_id=6` now returns `Brainstone=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, and no `Generous Gift` row.
- Latest full battle summary now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`.
- `122732`: `custom_64_seed`, `manual_cli`, `64/64`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=64`, table-intent `pass=64`, tests `18/18`,
  Lorehold `14/64`, `forced_keep_after_bad_mulligan=13`.
- Fresh learned-deck audit
  `learned_deck_coherence_audit_20260621_130957.json` keeps aggregate
  `medium=13`; Lorehold remains `issues=[]` but active learned-vs-runtime drift
  is now `Generous Gift`/`Guttersnipe`/`Monument to Endurance` versus
  `Brainstone`/`Silent Arbiter`/`Windborn Muse`.
- Next cycle should not reapply PG023. Keep active learned-deck mutation
  blocked until explicit approval, and continue consistency/mulligan work.

## Temporary Expedition Map Candidate Follow-Up - 2026-06-21 10:15 -0300

- A new external runner `20260621_131126` became the latest battle artifact.
- Process command showed a temporary SQLite candidate:
  `Expedition Map` over `Electroduplicate`, with backup/restore trap.
- Summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131126/summary.json`,
  `16/16`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal is poor: Lorehold `1/16`, opponents `14/16`,
  `forced_keep_after_bad_mulligan=3`.
- After runner exit, local SQLite restored to PG023 persistent shape:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Expedition Map`, no `Generous Gift`, `100/100`.
- Classification: gate-clean temporary candidate evidence only; no promotion,
  no PostgreSQL deploy, no active pending-list change.

## Latest PG023 Recurring Smoke - 2026-06-21 10:20 -0300

- Latest summary advanced again to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131606/summary.json`.
- `131606`: `recurring_16_seed`, `recurring_full`, `manual_cli`, `16/16`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold `3/16`, opponents `13/16`,
  `forced_keep_after_bad_mulligan=5`.
- Persistent SQLite remains PG023-shaped:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Generous Gift`, no `Expedition Map`, `100/100`.
- Next cycle: no PG reapply; continue active learned-deck drift governance and
  mulligan/consistency work.

## Temporary Thrill Candidate Follow-Up - 2026-06-21 10:25 -0300

- Latest summary advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132027/summary.json`.
- Observed temporary candidate: `Thrill of Possibility` over `Boros Charm`,
  with backup/restore trap around local SQLite.
- `132027`: `16/16`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold `2/16`, opponents `13/16`,
  `forced_keep_after_bad_mulligan=4`.
- Persistent SQLite restored after run:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Thrill of Possibility`,
  `100/100`.
- Classification: gate-clean temporary candidate evidence only; no promotion
  and no PostgreSQL deploy action.

## PG023 Candidate Scan Artifact - 2026-06-21 10:30 -0300

- New artifact:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_pg023_candidate_scan_20260621_132537.md`.
- Status: `no_promotion`.
- Candidate classification: `131126` Expedition Map over Electroduplicate
  `1/16`; `131606` Reforge the Soul over Boros Charm `3/16`; `132027` Thrill
  of Possibility over Boros Charm `2/16`; `132537` Reprieve over Boros Charm
  `4/16`.
- The artifact supersedes the earlier generic smoke label for `131606`; it was
  a temporary candidate run.
- No PostgreSQL apply, no package generation, and SQLite restored after each
  candidate. Canonical PG023 full validation remains `122732` at `14/64`.

## Active Temporary Reprieve Runner - 2026-06-21 10:26 -0300

- External candidate runner `20260621_132537` is active and not yet summarized.
- Observed temporary candidate: `Reprieve` over `Boros Charm`, with
  backup/restore trap around local SQLite.
- Final checkpoint: at least `9` seed directories and no `summary.json` read
  yet.
- Current SQLite should be treated as temporary while the process runs:
  `Reprieve=1`, no `Boros Charm`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, `100/100`.
- Latest completed summary remains `20260621_132027` until `132537` finishes.

## Temporary Reprieve Candidate Completed - 2026-06-21 10:30 -0300

- Latest summary advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`.
- `132537`: `recurring_16_seed`, `recurring_full`, `manual_cli`, `16/16`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold `4/16`, opponents `12/16`,
  `forced_keep_after_bad_mulligan=5`.
- Persistent SQLite restored after the run:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Reprieve`, no `Generous Gift`,
  `100/100`.
- Classification: gate-clean temporary candidate evidence only; no promotion
  and no PostgreSQL deploy action.

## PG023 Prepared Package Found - 2026-06-21 05:17 -0300

- New package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`.
- Package status: `prepared`.
- Proposed swap: `Brainstone` over `Generous Gift`.
- Package evidence: PG022 baseline `8/64`; Brainstone candidate `14/64`;
  net `+6` Lorehold wins.
- Required files present: precheck, apply, postcheck, rollback.
- Not executed by this heartbeat: PG023 precheck, apply, postcheck, rollback,
  PG -> Hermes sync, battle-rule sync, commit, push, cleanup, stash, revert.
- Local SQLite still has `Generous Gift=1` and no `Brainstone` row, so runtime
  remains pre-PG023.
- Next cycle should keep prioritizing consistency/mulligan and should not
  promote the `054803` combo scan.

## Aborted Runner Check - 2026-06-21 04:48 -0300

- A newer run directory exists:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_060733/`.
- It has no `summary.json`; `latest` still points to `20260621_054803`.
- `py_compile` passed, but `test_battle_analyst_v10_3` failed after `963s`.
- Failure root:
  `psycopg2.OperationalError: server closed the connection unexpectedly` during
  `sync_pg.connect()` in the promoted-hotfix PG fallback test setup.
- Follow-up read-only PG check succeeded with `pg_select_1=1`.
- Classification: aborted runner/infrastructure artifact, not a battle result,
  not a PostgreSQL drift signal, and not a deck promotion signal.

## Latest 64-Seed Manual Rerun - 2026-06-21 05:17 -0300

- Latest completed battle summary now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json`.
- `run_profile=custom_64_seed`, `invocation_kind=manual_cli`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`.
- Final status is `trusted_for_strategy_learning` with clean gates:
  `mandatory_gate_divergences=[]`, forensic findings `0`, replay decision
  findings `0`, target-pressure `pass=64`, table-intent `pass=64`, tests
  `18/18`.
- Strategy signal: `14/64` Lorehold wins,
  `forced_keep_after_bad_mulligan=13`, high-confidence learning seeds `54`,
  low-confidence seeds `10`.
- Local SQLite remains on PG022 deck shape: `Silent Arbiter=1`,
  `Windborn Muse=1`, `100/100`.
- No new learned-deck coherence artifact appeared after
  `learned_deck_coherence_audit_20260621_045522.json`.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## Focused Zone Transition Latest - 2026-06-21 11:03 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_140346/summary.json`.
- `run_profile=focused_zone_transition_fix_v3`,
  `run_scope=focused_seed`,
  `invocation_kind=codex_focused_zone_transition_fix_63212310_v3`,
  `seeds_completed=1/1`.
- Final status is `trusted_for_strategy_learning` with
  `battle_replay_final_status_reason=all_mandatory_gates_pass` and
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=1`, table-intent `pass=1`,
  test results `pass=18`, strategy review findings `0`.
- Current cycle reading: `latest` is now focused runtime-support evidence, not
  a new full deck validation. PG023 full validation remains `20260621_122732`
  until another post-sync/post-apply full run supersedes it.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## PG023 Combat-Survival Rebaseline - 2026-06-21 11:30 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_142400/summary.json`.
- `run_profile=pg023_rebaseline_after_combat_survival_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_pg023_rebaseline_after_combat_survival_response`,
  `seeds_completed=16/16`.
- Final status is `trusted_for_strategy_learning` with
  `battle_replay_final_status_reason=all_mandatory_gates_pass` and
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  test results `pass=18`, strategy review findings `0`.
- Strategy sample: Lorehold `1/16`, opponents `15/16`,
  `forced_keep_after_bad_mulligan=2`, opponent combat to Lorehold `246`, to
  other players `2`.
- Current cycle reading: `142400` is clean gate evidence but a poor deck result.
  Keep PG023 closed as current deployed shape; next cycle should continue
  strategy work on survival/conversion instead of applying or rolling back
  PostgreSQL.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## PG023 Priority-Fix And Angel's Grace Candidate Sweep - 2026-06-21 12:04 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_145948/summary.json`.
- Recent PG023 rebaselines:
  `140846` Lorehold `2/16`, `141620` Lorehold `1/16`, and `145423` Lorehold
  `1/16`; all trusted, clean gates, tests `pass=18`.
- `144336` Angel's Grace over Boros Charm was blocked by
  `forensic_audit=blocked`.
- `145948` Angel's Grace over Boros Charm after priority fix is trusted and
  gate-clean, but only reaches Lorehold `2/16`, opponents `13/16`, with
  `forced_keep_after_bad_mulligan=3`.
- Runtime cache restored after the active runner: deck `6` is `100` rows /
  `100` quantity with `Boros Charm=1`, `Brainstone=1`,
  `Electroduplicate=1`, `Silent Arbiter=1`, and `Windborn Muse=1`.
- Current cycle reading: reject Angel's Grace as a deploy candidate; continue
  survival/conversion work under pressure.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## Latest Manual 16-Seed Review Checkpoint - 2026-06-21 12:35 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_151645/summary.json`.
- A `manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63212310`
  runner was still active at read time.
- Summary: `run_profile=recurring_16_seed`, `run_scope=recurring_full`,
  `invocation_kind=manual_cli`, `seeds_completed=16/16`.
- Final status is `review_required` with mandatory divergences:
  `forensic_audit=review_required`, `replay_decision_audit=review_required`,
  and `strategy_audit=review_required`.
- Green gates/tests: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy sample: Lorehold `1/16`, opponents `12/16`,
  `strategy_review_required_findings=4`,
  `forced_keep_after_bad_mulligan=4`, `tutor_no_target=2`,
  `resource_cost_without_selection_context=1`, and
  `spending_unique_color_land=1`.
- Current cycle reading: do not use `151645` as trusted learning or deploy
  evidence until review gates are handled and the active runner state settles.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, revert,
  or runner termination was performed by this heartbeat.

## PG023 Oracle-Specific Finisher Contract Rebaseline - 2026-06-21 12:37 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_152154/summary.json`.
- No external battle runner was active at final read time.
- Summary:
  `run_profile=pg023_rebaseline_after_oracle_specific_finisher_contract_fix_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_pg023_rebaseline_after_oracle_specific_finisher_contract_fix`,
  `seeds_completed=16/16`.
- Final status is `trusted_for_strategy_learning` with
  `battle_replay_final_status_reason=all_mandatory_gates_pass` and
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`, strategy review findings `0`.
- Strategy sample: Lorehold `1/16`, opponents `14/16`,
  `forced_keep_after_bad_mulligan=2`, opponent combat to Lorehold `252`, to
  other players `2`.
- Current cycle reading: `152154` clears the `151645` review gates, but it does
  not improve Lorehold outcome. Continue survival/conversion work; do not open
  PostgreSQL apply/rollback.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, revert,
  or runner termination was performed by this heartbeat.

## Magus Candidate Over Electroduplicate Blocked - 2026-06-21 13:03 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_153944/summary.json`.
- `run_profile=candidate_magus_of_the_moat_for_electroduplicate_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_of_the_moat_for_electroduplicate_16_seed`,
  `seeds_completed=16/16`.
- Final status is `blocked` with
  `mandatory_gate_divergences=["strategy_audit=blocked"]`.
- Green side channels: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy sample: Lorehold `3/16`, opponents `12/16`,
  `spending_last_land=1`, `spending_unique_color_land=1`,
  `forced_keep_after_bad_mulligan=2`.
- Runtime cache restored after the candidate: deck `6` is `100/100` with
  `Electroduplicate=1` and no focused `Magus of the Moat` row.
- Current cycle reading: reject Magus over Electroduplicate as blocked
  candidate; continue survival/conversion work without PostgreSQL mutation.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## Magus Candidate After Mox Trace Fix - 2026-06-21 13:19 -0300

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_160405/summary.json`.
- `run_profile=candidate_magus_of_the_moat_for_electroduplicate_after_mox_trace_fix_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_of_the_moat_for_electroduplicate_after_mox_trace_fix_16_seed`,
  `seeds_completed=16/16`.
- Final status is `trusted_for_strategy_learning` with
  `mandatory_gate_divergences=[]`.
- Green side channels: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy sample: Lorehold `3/16`, opponents `12/16`,
  `forced_keep_after_bad_mulligan=2`.
- Runtime cache restored after the candidate: deck `6` is `100/100` with
  `Electroduplicate=1` and no focused `Magus of the Moat` row.
- Current cycle reading: valid evidence but rejected for promotion; continue
  survival/conversion work without PostgreSQL mutation.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## Victory Chimes Rebaseline - 2026-06-21 13:52 -0300

- Victory Chimes was corrected locally from stale curated `draw_engine` to
  verified curated `ramp_permanent`; sync evidence is
  `victory_chimes_reviewed_rule_sqlite_sync_20260621_161900.json`.
- Focused Victory Chimes tests passed (`Ran 3 tests ... OK`); the full
  reviewed-rule test file still has 2 Top/Scroll Rack failures outside this
  fix.
- Intermediate run `20260621_164101`:
  `run_profile=rebaseline_after_victory_chimes_rule_fix_16_seed`, trusted,
  clean gates, tests `pass=18`, Lorehold `1/16`, opponents `14/16`.
- Current latest run `20260621_164710`:
  `run_profile=recurring_16_seed`, `invocation_kind=manual_cli`,
  trusted, clean gates, tests `pass=18`, target-pressure/table-intent
  `pass=16`, strategy review findings `0`, Lorehold `2/16`, opponents
  `13/16`.
- Runtime cache final check: deck `6` is `100/100` with `Electroduplicate=1`,
  `Brainstone=1`, `Victory Chimes=1`, and no focused `Magus of the Moat`.
- Current cycle reading: Victory Chimes is closed as a runtime modeling
  pending item, but deck outcome remains weak. Continue consistency/mulligan
  and learned-source governance work without PostgreSQL mutation.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## Magus Same-Seed Candidate After Victory Fix - 2026-06-21 14:38 -0300

- Latest symlink advanced again to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_173334/summary.json`.
- `run_profile=candidate_magus_after_victory_chimes_fix_same_seed_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_after_victory_chimes_fix_same_seed_16_seed`,
  `seeds_completed=16/16`.
- Final status is trusted and gate-clean:
  `mandatory_gate_divergences=[]`, target-pressure/table-intent/tests
  `16/16/18`, strategy review findings `0`.
- Strategy sample: Lorehold `3/16`, opponents `12/16`,
  `forced_keep_after_bad_mulligan=2`.
- Runtime cache final check: deck `6` is `100/100` with `Electroduplicate=1`,
  `Brainstone=1`, `Victory Chimes=1`, and no focused `Magus of the Moat`.
- Current cycle reading: Magus remains valid but rejected candidate evidence;
  continue consistency/mulligan work without PostgreSQL mutation.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash, or
  revert was performed by this heartbeat.

## Runtime Cache Drift After Latest Battle - 2026-06-21 14:42 -0300

- Battle `latest` still points to `20260621_173334`; no active runner remained
  at read time.
- New backup:
  `knowledge_db_backup_candidate_magus_sphere_after_victory_fix_20260621_174200.sqlite`.
- Backup focused deck `6`: `Electroduplicate`, `Victory Chimes`.
- Current local SQLite focused deck `6`: `Magus of the Moat`,
  `Sphere of Safety`.
- Current cycle reading: local runtime cache is in an unvalidated Magus+Sphere
  candidate state after latest battle. This is an active pending item and does
  not authorize PostgreSQL mutation or deck swap.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash,
  revert, or sync was performed by this heartbeat.

## Magus+Sphere Candidate Review Required - 2026-06-21 14:46 -0300

- The active runner completed and latest now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_174142/summary.json`.
- `run_profile=candidate_magus_sphere_after_victory_fix_same_seed_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_candidate_magus_sphere_after_victory_fix_same_seed_16_seed`,
  `seeds_completed=16/16`.
- Final status is `review_required` with mandatory divergences in forensic,
  replay-decision, and strategy gates.
- Side channels pass: target-pressure/table-intent/tests `16/16/18`.
- Strategy sample: Lorehold `5/16`, opponents `11/16`,
  `forced_keep_after_bad_mulligan=3`, `tutor_no_target=1`.
- Runtime cache final check: deck `6` is `100/100` with `Electroduplicate=1`,
  `Brainstone=1`, `Victory Chimes=1`, and no focused `Magus of the Moat` or
  `Sphere of Safety`.
- Current cycle reading: Magus+Sphere is review-required and rejected for
  promotion. Continue consistency/gate-closure work without PostgreSQL
  mutation.
- No PostgreSQL package, apply, deck swap, commit, push, cleanup, stash,
  revert, or sync was performed by this heartbeat.
