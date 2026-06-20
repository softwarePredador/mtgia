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

Current battle work should not target the old seed `63211720` finding unless a
future battle artifact reintroduces it. The current battle latest is green, so
there is no active battle-gate fix to apply. Continue monitoring only; do not
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

Current smoke:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`.
- Status: `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- Mandatory gates: forensic, target-pressure, table-intent, action critic,
  replay-decision, decision-trace contract, unknown-template backlog, and
  tests all pass under the current contract.
- Final cache-sync artifact:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_full_after_table_intent_round9_20260620.json`.
- One battle log for review:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/seed_63212120/replay.txt`.

Next cycle:

1. Use `20260620_212035` as the real-battle baseline for Lorehold.
2. Do not treat the latest result as proof that Lorehold is optimal: opponents
   won `15/16` and Lorehold won `1/16`.
3. Optimize deck decisions against table-intent pressure with explicit
   before/after battle evidence and no silent swaps.
