# ManaLoom Central Auditor Orders

Last updated: 2026-06-20 18:21 -0300
Owner: Auditor Central / single operator
Status: active, single-operator mode

## Purpose

This is now the central operating file for this thread only.

Rafael paused the executor chats and explicitly changed the operating model:
the Auditor Central owns audit, worktree triage, PostgreSQL deploy governance,
validation, register reconciliation, and next-step execution until Rafael
changes this again.

Historical executor-chat command blocks are deprecated. Do not generate new
orders for other chats unless Rafael explicitly asks to resume that model.
Current operating model: do not prepare continuation commands for other chats;
this thread owns the work until Rafael changes the model again.

## Mandatory Rules

1. Start each cycle with current repo state, not stale notes:
   - `git status --short --branch`
   - current required docs and artifacts
2. Do not commit or push without explicit Rafael approval.
3. Do not apply deck swaps without explicit Rafael approval.
4. PostgreSQL writes are owned by this Auditor Central thread now, but still
   require explicit Rafael approval for the exact apply command.
5. Every database write still needs:
   - source artifact or code evidence
   - exact table and column scope
   - exact affected rows
   - SELECT pre-apply
   - SQL/apply command
   - rollback SQL
   - non-destructive tests or dry-runs
   - post-apply SELECT
   - register update with evidence
6. Do not delete, revert, stash, or overwrite worktree files without an exact
   cleanup list and explicit approval.
7. Every conclusion needs evidence from code, tests, artifacts, `summary.json`,
   registers, SQL output, or updated docs.
8. If something is inferred, mark it as inference.

## Always Read

- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `docs/hermes-analysis/PROJECT_MEMORY.md`
- `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
- `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/POSTGRES_DEPLOY_REGISTER_2026-06-20.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

## Current Operator Queue

1. Maintain single-operator control. This thread performs audit, worktree
   triage, PostgreSQL deploy governance, validation, register reconciliation,
   and next-step execution while Rafael keeps the other chats paused.
2. Keep PG-001 closed unless a future SELECT proves rollback or data drift.
3. PG-002 global learned-deck metadata canonicalization was applied and
   validated. Do not reapply unless a future SELECT proves rollback or drift.
4. Keep PG-003 oracle/card text/type backlog blocked until the policy for
   official blank oracle text, Arena/Alchemy identities, aliases, and reprints
   is explicit.
5. PG-006 `card_battle_rules.execution_status` migration drift was applied and
   validated. Migration `029` is now recorded, the constraint is present, and
   generated/needs_review PostgreSQL rows are `review_only`.
6. Latest full battle now resolves to `20260620_212035` and is
   `trusted_for_strategy_learning`. Target-pressure passes `16/16`; forensic,
   action, replay-decision, table-intent, event-contract, effect-coverage,
   focused-template, unknown-template, and decision-trace gates pass. No
   current PostgreSQL apply is ready.
7. PG-007 was applied, postchecked, synced into the Hermes runtime cache, and
   validated by a fresh full recurring battle rerun. Do not reapply unless a
   future SELECT/artifact proves rollback or drift.
8. PG-008 was applied, postchecked, synced into the Hermes runtime cache, and
   validated by a full recurring battle rerun. Do not reapply unless a future
   SELECT/artifact proves rollback or drift.
9. PG-009 Korvold learned-deck replacement is closed. The current learned-deck
   audit keeps high severity at `0`; do not reapply unless a future SELECT or
   learned-deck artifact proves rollback or drift.
10. Lorehold canonical `Wheel of Misfortune` over `Reforge the Soul` is closed
    by the applied PG/Hermes sync evidence and the `20260620_181004` full battle
    artifact. Do not apply any further deck swap without explicit approval.
11. Convert dirty worktree into an auditable inventory before any cleanup.
    Current cleanup proposal is audited but not approved or executed.
12. Use
   `docs/hermes-analysis/MANALOOM_CENTRAL_AUDITOR_COMPLETION_AUDIT_2026-06-20.md`
   as the active completion/gap register for this single-operator cycle.
13. Future Lorehold deck optimization must use target-pressure battle evidence.
    Do not treat older free-for-all WR snapshots as proof that Lorehold is the
    best list, because those runs could let the other three decks fight each
    other while Lorehold developed without enough pressure.

## Battle Runtime Drift - 2026-06-20 16:30 -0300

Observed current latest:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_191248/summary.json`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["action_critic=review_required","forensic_audit=blocked","replay_decision_audit=review_required"]`
- `forensic_rule_findings=2`, `action_findings=2`,
  `decision_audit_decision_findings=1`
- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=84`,
  `target_pressure_opponent_combat_to_other=0`
- tests remain `17/17` pass.

Root cause identified from seed `63211917`:

- `Goblin Bombardment` from `Dargo, the Shipwrecker #74 (real)` was cast and
  resolved as `remove_creature` from `known_cards_canonical_snapshot`.
- The local runtime row is `review_status=needs_review` and
  `execution_status=review_only`; that row must not execute as removal through
  the canonical snapshot fallback.

Treatment performed without PostgreSQL writes, deck swaps, cleanup, stage,
commit, or push:

- `battle_analyst_v9.py` now suppresses non-runtime-safe canonical snapshot
  rules into a passive `canonical_snapshot_rule_not_runtime_safe` effect while
  preserving provenance.
- `battle_card_specific_tests.py` adds
  `test_goblin_bombardment_review_only_snapshot_does_not_remove_on_cast`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed and includes the new Goblin Bombardment regression.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`
  passed.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  passed.
- Focused seed replay/auditors written under
  `/tmp/lorehold_seed63211917_post_review_only_fix.*` returned
  `action_findings=0`, `forensic rule_findings=0`,
  `forensic turn_findings=0`, `decision_findings=0`, and
  `decision turn_findings=0`.

Operational state:

- This closes the identified runtime code defect locally.
- The official `latest` artifact remains `blocked` until a full recurring
  battle rerun supersedes `20260620_191248`.
- Do not open a PostgreSQL package for this blocker unless a future SELECT or
  sync report proves real database drift.

## Battle Runtime Follow-Up - 2026-06-20 16:50 -0300

Superseding full recurring rerun:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_195007/summary.json`
- `run_scope=recurring_full`, `seeds_requested=16`, `seeds_completed=16`,
  `start_seed=63211944`
- `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked","replay_decision_audit=review_required"]`
- `test_results_total=17`, `test_results_status_counts={"pass":17}`
- target-pressure closed: `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=193`,
  `target_pressure_opponent_combat_to_other=0`
- action critic closed: `action_findings=0`

Treatment completed in this follow-up:

- `battle_target_pressure_audit.py` now ignores opponent combat after the
  evaluation target has been eliminated.
- `test_battle_target_pressure_audit.py` adds
  `test_ignores_opponent_combat_after_lorehold_is_eliminated`.
- Focused validation on seed `63211952` returned `status=pass`,
  `post_target_elimination_opponent_combat_ignored=1`,
  `opponent_combat_to_target=10`, and `opponent_combat_to_other=0`.
- The full rerun `20260620_195007` confirms target-pressure passes `16/16`.

Current unresolved blockers:

- `forensic_rule_findings=26` and `forensic_turn_findings=1`.
- Blocking forensic seeds are `63211954` and `63211958`.
- High forensic findings come from opponent cards still using
  `functional_tags_json` instead of verified/active `card_battle_rules`:
  `Abandon Attachments`, `Channeled Force`, and `Hypothesizzle`.
- Medium recurring lineage findings also include
  `The Emperor of Palamecia`, `Firemind Vessel`,
  `Sisay, Weatherlight Captain`, and `Kraum, Ludevic's Opus`.
- Low review-only/passive mismatches include `Laughing Mad`, `Shark Typhoon`,
  `One with the Multiverse`, and `Stonespeaker Crystal`.
- The replay-decision review item is low severity:
  seed `63211944`, turn `7`, `board_wipe_resolved`, "Board wipe left more
  protected creatures (5) than destroyed (4)."

Operational state:

- The remaining battle blocker is a card-rule curation/data-governance backlog.
- No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
  commit, or push was performed.

## Battle Runtime Follow-Up - 2026-06-20 17:06 -0300

New heartbeat artifacts:

- Focused run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200322/summary.json`
  with `run_scope=focused_seed`, seed `63213000`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `target_pressure_statuses={"pass":1}`,
  `forensic_rule_findings=0`, `decision_audit_turn_findings=0`,
  `action_findings=0`, and tests `18/18` pass.
- Superseding full rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_200409/summary.json`
  with `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212004`,
  `battle_replay_final_status=blocked`, and
  `mandatory_gate_divergences=["forensic_audit=blocked","table_intent=blocked"]`.

Treatment completed:

- `battle_target_pressure_audit.py` now accepts `table_intent_*` target reasons
  as valid pressure metadata when `evaluation_target_active=true` and the
  defender is Lorehold.
- `test_battle_target_pressure_audit.py` adds
  `test_accepts_table_intent_target_reason_when_evaluation_target_is_active`.
- Direct re-audit of seed `63213000` returned `status=pass`,
  `opponent_combat_to_target=14`, `opponent_combat_to_other=0`, and
  `opponent_combat_missing_pressure_reason=0`.

Current unresolved blockers:

- Full target-pressure still has one real violation on seed `63212012`:
  opponent `Kinnan, Bonder Prodigy #104 (real)` split combat between
  Lorehold and `Tayam, Luminous Enigma #25 (real)` on turn `9`; aggregate
  `target_pressure_statuses={"blocked":1,"pass":15}`,
  `target_pressure_findings=2`,
  `target_pressure_opponent_combat_to_target=171`,
  `target_pressure_opponent_combat_to_other=1`, and
  `target_pressure_opponent_multi_defender_attack=1`.
- Full forensic blockers are `Woodland Bellower` on seed `63212015` and
  `Shantotto, Tactician Magician` on seed `63212017`, both from
  `functional_tags_json` lineage.
- Full table-intent blockers are seeds `63212004`, `63212009`, and
  `63212019`, each with `opponent_interaction_absent`.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed.

## Battle Runtime Follow-Up - 2026-06-20 17:39 -0300

New heartbeat evidence:

- Before wrapper correction, latest full
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_202211/summary.json`
  was `blocked` with
  `mandatory_gate_divergences=["event_contract_static=review_required","forensic_audit=blocked","replay_decision_audit=blocked"]`.
- Re-running `battle_event_contract_static_audit.py` over `20260620_202211`
  with current code wrote `/tmp/event_contract_static_202211_current_code.*`
  and returned `status=event_contract_static_ready`,
  `observed_unclassified_total=0`, and `static_unclassified_total=0`.
- The local wrapper
  `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  was corrected so `target_pressure` is a mandatory final-status gate.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  and `manaloom-battle-strategy-audit.sh --dry-run --seeds 16` exited `0`.
- Superseding full rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_203616/summary.json`
  with `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `start_seed=63212036`,
  `battle_replay_final_status=blocked`, and
  `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`.

Current unresolved blockers:

- `target_pressure` is now explicitly mandatory and blocked:
  `target_pressure_statuses={"blocked":3,"pass":13}`,
  `target_pressure_findings=9`,
  `target_pressure_opponent_combat_to_target=190`,
  `target_pressure_opponent_combat_to_other=8`,
  and `target_pressure_opponent_multi_defender_attack=1`.
- Target-pressure blocking seeds: `63212036`, `63212042`, and `63212046`.
- Forensic blocking seeds: `63212038`, `63212042`, `63212047`,
  `63212048`, and `63212050`, with `forensic_rule_findings=25`.
- Action critic, replay decision, table intent, decision trace taxonomy,
  event contract static, effect coverage, focused template dispatch, and
  unknown-template backlog all pass in `203616`; tests are `18/18` pass.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed.

## Battle Runtime Follow-Up - 2026-06-20 17:40 -0300

Wrapper recheck generated a newer latest artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_204002/summary.json`
- `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212040`, `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked","target_pressure=blocked"]`
- `mandatory_gates_required_for_final_status` includes `target_pressure`
- `target_pressure_statuses={"blocked":2,"pass":14}`,
  `target_pressure_findings=4`,
  `target_pressure_opponent_combat_to_target=188`,
  `target_pressure_opponent_combat_to_other=3`,
  `target_pressure_opponent_multi_defender_attack=1`
- Target-pressure blocking seeds: `63212042` and `63212046`
- `forensic_rule_findings=21`, `forensic_turn_findings=0`;
  forensic blocking seeds: `63212042`, `63212047`, `63212048`,
  and `63212050`
- `table_intent`, `event_contract_static`, `replay_decision_audit`,
  `action_critic`, `effect_coverage`, `focused_template_dispatch`,
  `unknown_template_backlog`, and `decision_trace_taxonomy` pass; tests are
  `18/18` pass.

This supersedes `203616` as the active latest but does not change the
classification: the remaining blockers are forensic
`functional_tags_json` lineage and target-pressure attacks away from Lorehold.
No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed.

## Battle Runtime Follow-Up - 2026-06-20 18:01 -0300

New latest artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_205821/summary.json`
- `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212058`, `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=196`,
  `target_pressure_opponent_combat_to_other=3`, and
  `target_pressure_opponent_multi_defender_attack=0`
- `forensic_rule_findings=2`, `forensic_turn_findings=0`
- Residual forensic findings are both low severity on seed `63212068`:
  `Goblin Bombardment` runtime effect `passive` differs from registry effect
  `remove_creature` on `spell_cast` and `spell_resolved`.
- `action_critic`, `replay_decision_audit`, `table_intent`,
  `target_pressure`, `event_contract_static`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`, and
  `decision_trace_taxonomy` pass; tests are `18/18` pass.

Detected external/unowned artifact evidence:

- `card_battle_rules_pg_table_intent_promotions_round5_20260620.json` has
  `apply_pg=true`, `pg_inserted_or_updated=3`, selected cards
  `Big Score` and `Spelltwine`, generated at `2026-06-20T20:57:21Z`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round5_20260620.json`
  has `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5224`, `sqlite_inserted_or_updated=5142`, and
  `canonical_snapshot_rows_exported=3181`.
- This heartbeat did not execute any PostgreSQL write. Treat the round5 files
  as detected evidence to reconcile, not as authorization to reapply.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed by this heartbeat.

## Battle Runtime Follow-Up - 2026-06-20 18:05 -0300

New latest artifact superseding `205821`:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_210513/summary.json`
- `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212105`, `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=179`,
  `target_pressure_opponent_combat_to_other=5`, and
  `target_pressure_opponent_multi_defender_attack=1`
- `forensic_rule_findings=11`, `forensic_turn_findings=0`
- Blocking high/medium cards through `functional_tags_json`: `Arcane Endeavor`,
  `Curator's Ward`, `Magma Opus`, and `The Unagi of Kyoshi Island`.
- Low registry/runtime drift also appears for `Apex of Power`.
- `action_critic`, `replay_decision_audit`, `table_intent`,
  `target_pressure`, `event_contract_static`, `effect_coverage`,
  `focused_template_dispatch`, `unknown_template_backlog`, and
  `decision_trace_taxonomy` pass; tests are `18/18` pass.

Detected external/unowned artifact evidence:

- `card_battle_rules_pg_table_intent_promotions_round6_20260620.json`
  has `apply_pg=true`, `pg_inserted_or_updated=2`, selected card
  `Goblin Bombardment`, generated at `2026-06-20T21:03:38Z`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round6_20260620.json`
  has `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5225`, `sqlite_inserted_or_updated=5143`, and
  `canonical_snapshot_rows_exported=3181`.
- This heartbeat did not execute any PostgreSQL write. Treat the round6 files
  as detected evidence to reconcile, not as authorization to reapply.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
commit, or push was performed by this heartbeat.

## Post-Latest Round7 Evidence - 2026-06-20 18:12 -0300

After `20260620_210513`, new round7 artifacts appeared, but the battle latest
did not rerun yet:

- Latest remains
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_210513/summary.json`
  after a 20s recheck.
- `card_battle_rules_pg_table_intent_promotions_round7_20260620.json`
  declares `apply_pg=true`, `pg_inserted_or_updated=6`, selected cards
  `Apex of Power`, `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, and
  `The Unagi of Kyoshi Island`, generated at `2026-06-20T21:11:34Z`.
- `battle_card_rules_sqlite_from_pg_full_after_table_intent_round7_20260620.json`
  declares `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`, and
  `canonical_snapshot_rows_exported=3185`.
- This heartbeat did not execute the round7 apply/sync and did not rerun
  battle after round7. Next evidence needed is a fresh battle rerun or the next
  heartbeat reading a superseding latest artifact.

## Battle Runtime Follow-Up - 2026-06-20 18:13 -0300

New latest artifact superseding `210513`:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211217/summary.json`
- `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212112`, `battle_replay_final_status=blocked`
- `mandatory_gate_divergences=["forensic_audit=blocked"]`
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=186`,
  `target_pressure_opponent_combat_to_other=3`,
  `target_pressure_opponent_multi_defender_attack=0`
- `table_intent_statuses={"pass":16}`
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`

Current unresolved blockers:

- `forensic_rule_findings=4`, `forensic_turn_findings=0`.
- Seed `63212112`: `Tellah, Great Sage` from
  `The Emperor of Palamecia #42 (real)` used `functional_tags_json` lineage
  for `draw_cards` on `spell_cast` and `spell_resolved`.
- Seed `63212123`: `Practical Research` from
  `The Emperor of Palamecia #42 (real)` used `functional_tags_json` lineage
  for `draw_cards` on `spell_cast` and `spell_resolved`.

Operational state:

- Round7 has post-rerun evidence now; the prior `Arcane Endeavor`,
  `Curator's Ward`, `Magma Opus`, `The Unagi of Kyoshi Island`, and
  `Apex of Power` blocker set is superseded by `211217`.
- The remaining blocker is still card-rule curation/governance for opponent
  cards, not Lorehold deck composition or target-pressure.
- This heartbeat did not execute PostgreSQL apply, SQLite sync, deck swap,
  cleanup, deletion, stash, revert, stage, commit, push, or battle rerun.

## Battle Runtime Follow-Up - 2026-06-20 18:17 -0300

New latest artifact superseding `211217`:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_211648/summary.json`
- `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212116`, `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=200`,
  `target_pressure_opponent_combat_to_other=0`,
  `target_pressure_opponent_multi_defender_attack=0`
- `table_intent_statuses={"pass":16}`
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`

Current unresolved review item:

- `forensic_rule_findings=2`, `forensic_turn_findings=0`,
  `forensic_severity_counts={"low":2}`.
- Seed `63212130`: `Breena, the Demagogue` from
  `Tayam, Luminous Enigma #25 (real)` has runtime effect `passive` differing
  from registry effect `draw_engine` on `spell_cast` and `spell_resolved`.

Operational state:

- The prior `Tellah, Great Sage` / `Practical Research` blocker set from
  `211217` is superseded by `211648`.
- The current state is a low review residual, not a strategy-learning blocker
  from target-pressure, action integrity, decision audit, table intent, or
  high/medium card-rule lineage.
- This heartbeat did not execute PostgreSQL apply, SQLite sync, deck swap,
  cleanup, deletion, stash, revert, stage, commit, push, or battle rerun.

## Battle Runtime Follow-Up - 2026-06-20 18:21 -0300

New latest artifact superseding `211648`:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`
- `run_scope=recurring_full`, `seeds_completed=16`,
  `start_seed=63212120`,
  `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=214`,
  `target_pressure_opponent_combat_to_other=3`,
  `target_pressure_opponent_multi_defender_attack=2`
- `forensic_rule_findings=0`, `forensic_turn_findings=0`
- `action_findings=0`, `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`, `table_intent_statuses={"pass":16}`
- `test_results_status_counts={"pass":18}`
- `strategy_findings=2`, both low-confidence only;
  `strategy_review_required_findings=0`

External artifacts detected before this green latest:

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

Operational state:

- The prior `211217` and `211648` forensic blocker/review sets are superseded
  by a green full recurring battle run.
- This heartbeat detected those artifacts and the new latest; it did not
  execute PostgreSQL apply, SQLite sync, deck swap, cleanup, deletion, stash,
  revert, stage, commit, push, or battle rerun.

## Current Operating Decision - 2026-06-20 11:39 -0300

Rafael clarified that this thread should stop generating commands for other
chats and should do the work directly: deploy, database governance, validation,
and worktree organization. That clarification is now adopted as the current
operating model.

Operational consequences:

- no new executor-chat command blocks by default;
- no waiting for another chat to run PostgreSQL, tests, or worktree triage;
- this does not authorize unsafe writes without evidence: PostgreSQL still
  requires precheck/apply/postcheck/rollback, deck swaps still require explicit
  approval, and destructive file operations still require an exact safe list.
- current evidence still shows no PostgreSQL apply ready at this heartbeat.

## Single-Operator Verification - 2026-06-20 11:42 -0300

After adopting Rafael's clarification, this thread ran a non-destructive
checkpoint:

- `git diff --check` clean;
- repo still on `master...origin/master`;
- tracked shortstat remains `72 files changed, 24631 insertions(+), 2029 deletions(-)`;
- individual untracked files are now `80` because the completion audit register
  was added;
- PostgreSQL migrations remain `29/29` executed and `0` pending;
- latest battle remains `trusted_for_strategy_learning` at
  `20260620_140016`, with mandatory divergences empty, forensic lineage
  complete, and tests `16/16` pass;
- runtime surface manifest test passed;
- PG-001 planner still plans `0` rows, PG-003 still has `backfill_ready=0`,
  and PG-005 still has `applied_counts=0`.

No PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage, commit,
or push was performed in this verification.

## Historical Evidence Snapshot - 2026-06-20 11:19 -0300

Repo state observed at 2026-06-20 11:19 -0300 before this register update:

- branch: `master...origin/master`
- tracked modified files: `72`
- untracked status entries: `78 ??`
- individual untracked files: `79`
- tracked diff size: `72 files changed, 24491 insertions(+), 2029 deletions(-)`
- tracked split by prefix:
  - `app`: `17` files
  - `server`: `47` files
  - `docs`: `8` files

Validation run by Auditor Central in this cycle:

- battle/PG/worktree heartbeat at `2026-06-20 11:19 -0300`:
  - confirmed repo evidence at that time showed `72 M`, `78 ??`, `79`
    individual untracked files, and `git diff --check` clean;
  - latest battle resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_140016/summary.json`,
    with `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
    forensic lineage complete, `forensic_rule_findings=0`,
    `forensic_turn_findings=0`, and tests `16/16` pass;
  - runtime surface manifest check passed with `110` related Python files and
    `unclassified_files=[]`;
  - PostgreSQL migration status remains `29/29` executed and `0` pending;
  - PG-001 planner returned `planned_row_count=0`, PG-002 postcheck returned
    `all_post_apply_checks_ok=true`, PG-003 oracle planner returned
    `backfill_ready=0`, PG-005 dry-run returned `applied_counts=0`, PG-006
    postcheck returned `remaining_needs_review_not_review_only=0`, and PG-007
    postcheck returned `pg007_target_rule_count=1`;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed in this heartbeat;
- cleanup proposal revalidation at `2026-06-20 11:26 -0300`:
  - all exact `8` cleanup candidates still exist;
  - hashes still match the proposal;
  - `battle_effect_coverage_audit_20260620_120952.json/.md` remain
    byte-identical to retained `120904_post_sqlite_sync` counterparts;
  - learned-deck candidates `031157`, `033941`, and `034324` remain
    superseded snapshots, while `095253` is retained as pre-PG-002 comparison
    evidence and `115918` is retained as post-PG-002 current evidence;
  - no cleanup, deletion, stash, revert, stage, commit, or push was performed;
- backend anti-fanout / PostgreSQL heartbeat at `2026-06-20 11:35 -0300`:
  - dirty backend scan covered `40` files under `server/lib`, `server/routes`,
    and `server/bin`;
  - direct join pattern scan found exactly one multi-row table join,
    `server/lib/ai/commander_learned_deck_support.dart:377`
    `LEFT JOIN card_function_tags cft`, and it is aggregated with
    `ARRAY_AGG(DISTINCT ...)` plus `GROUP BY` without `deck_cards` in context;
  - dirty deck-facing loaders use `card_intelligence_snapshot` when present or
    per-card `jsonb_agg(...)` / `EXISTS` fallbacks;
  - PostgreSQL read-only queue still has migrations `29/29`, PG-001
    `planned_row_count=0`, PG-002 `all_post_apply_checks_ok=true`, PG-003
    `backfill_ready=0`, PG-005 `applied_counts=0`, PG-006
    `remaining_needs_review_not_review_only=0`, and PG-007
    `pg007_target_rule_count=1`;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed;
- current docs-consistency heartbeat at `2026-06-20 10:57 -0300`:
  - re-read the required operating docs, the deploy register, and latest
    battle summary;
  - confirmed current repo evidence still shows `72 M`, `78 ??`, `79`
    individual untracked files, `git diff --check` clean, and latest battle
    `20260620_132812` trusted with `16/16` tests pass;
  - relabeled the older deploy-register PG-004 / `20260620_121005` section as
    historical and superseded by PG-007, so it cannot be mistaken for current
    Leyline deploy state;
  - appended current heartbeat notes to the Battle and Lorehold registers;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed in this heartbeat;
- current single-operator heartbeat at `2026-06-20 10:50 -0300`:
  - `git diff --check` returned no output;
  - latest battle resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`,
    with `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
    forensic lineage complete, and tests `16/16` pass;
  - `cd server && dart run bin/migrate.dart --status` reports `29/29`
    migrations executed and `0` pending;
  - PG-007 postcheck read-only returned `pg007_target_rule_count=1`, Leyline
    present in `card_intelligence_snapshot.battle_rules`, and backup rows `0`;
  - PostgreSQL queue planners/postchecks returned PG-001
    `planned_row_count=0`, PG-002 `all_post_apply_checks_ok=true`, PG-003
    `backfill_ready=0`, and PG-005 `applied_counts=0`;
  - app aggregate validation returned `flutter analyze` no issues and
    `flutter test` `105/105`;
  - backend Dart aggregate validation returned `dart analyze` no issues and
    `dart test` `146/146`;
  - backend Python aggregate validation returned `py_compile` plus focused
    unittests `39/39`;
  - no PostgreSQL write, deck swap, cleanup, deletion, stash, revert, stage,
    commit, or push was performed in this heartbeat;
- source-patch validation at `2026-06-20 10:09 -0300`:
  - `server/lib/deck_recommendations_advisory_support.dart` now restores
    backend-owned fallback context after merging parsed OpenAI text, so model
    output cannot override `power_level`, `statistics`, `colors`,
    `candidate_color_identity`, `color_identity_source`, `trending`, or
    `message` when those fields came from backend fallback context;
  - `server/test/deck_recommendations_advisory_support_test.dart` adds a
    regression proving conflicting model text cannot replace authoritative
    fallback context;
  - `server/bin/manaloom_battle_rule_focused_evidence.py` now passes the
    original spell effect data when validating extra-combat flashback evidence,
    preventing the focused harness from reclassifying `Seize the Day` away
    from the expected `extra_combat` contract;
  - `server/test/manaloom_ops_daemon_test.py` now isolates `DB_HOST` and
    `DB_NAME` leakage while checking `.env` loading;
  - focused recommendations validation passed:
    `dart analyze` with no issues and `dart test` `16/16`;
  - focused app deck validation passed:
    `flutter analyze` with no issues and `flutter test` `105/105`;
  - focused backend deck/API validation passed:
    `dart test` `143/143`;
  - focused Python validation passed:
    targeted focused evidence test with `evaluated_count=14` and
    `evidence_count=14`, targeted ops-daemon env test, `py_compile`, and full
    `python3 -m unittest discover -s server/test -p '*_test.py' -v` with
    `96/96` passing;
  - `git diff --check` returned no output after the source/test patches;
  - after the register/API-contract updates, `git diff --check` still returned
    no output and
    `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
    passed `6/6`;
- post-register tracked diff size is
    `72 files changed, 24134 insertions(+), 2026 deletions(-)`.
- PG-007 deploy and battle closure at `2026-06-20 10:31 -0300`:
  - PG-007 PostgreSQL apply inserted one row into `card_battle_rules` for
    `Leyline of Abundance` with `source=curated`, `review_status=active`,
    `execution_status=auto`, and
    `logical_rule_key=battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941`;
  - PG-007 postcheck returned `pg007_target_rule_count=1`, and
    `card_intelligence_snapshot` now exposes the rule in `battle_rules`;
  - runtime cache sync report
    `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`
    returned `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107`, and
    `canonical_snapshot_rows_exported=3160`;
  - post-sync coverage shows `runtime_safe_rule_names=1703`,
    `active_or_review_rule_names=3160`, and
    `execution_status_counts={"auto":1703,"review_only":1457}`;
  - latest battle now resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`;
  - latest is `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
    `forensic_lineage_status=complete`, `forensic_rule_findings=0`,
    `forensic_turn_findings=0`, and tests `16/16` pass.
- latest/battle heartbeat at `2026-06-20 10:18 -0300` (historical, pre-PG-007):
  - `latest/summary.json` resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/summary.json`;
  - latest is `review_required`, reason
    `one_or_more_mandatory_gates_require_review`, divergence
    `forensic_audit=review_required`, `forensic_lineage_status=incomplete`,
    `forensic_rule_findings=1`, `forensic_turn_findings=0`, and tests
    `16/16` pass;
  - blocker is `Leyline of Abundance` from seed `63211258`, event
    `spell_cast`, source `functional_tags_json`, effect `ramp_permanent`;
  - PostgreSQL read-only precheck for PG-007 confirms target card exists,
    existing Leyline battle-rule rows are `0`, and snapshot has
    `battle_rules=[]`;
  - at this historical point, PG-007 was still in prepared/pre-apply state.
- single-operator heartbeat at `2026-06-20 09:51 -0300`:
  - `git diff --check` returned no output;
  - added-line risk scan found no new `TODO`, `FIXME`, `debugPrint`, `print`,
    `console.log`, or skipped-test marker in the current app/server diff;
  - `cd app && xargs flutter analyze ...` returned no issues over the current
    changed app Dart slice;
  - `cd server && xargs dart analyze ...` returned no issues over the current
    changed/untracked backend Dart slice;
  - `cd app && flutter test ...` returned `105/105` tests passed;
  - `cd server && dart test ... -r expanded` returned historical `145/145`
    tests passed; superseded by the 10:50 `146/146` aggregate;
  - `python3 -m unittest ...` over changed/untracked backend Python tests
    returned historical `31` tests passed; superseded by the 10:50 `39/39`
    aggregate;
  - a first Python invocation from `server/` failed because it used module names
    under a non-package `test` path; it was rerun by file path from the repo
    root and passed. This is a command-shape issue, not a code/test failure.
- PostgreSQL queue heartbeat at `2026-06-20 09:51 -0300`
  (historical; superseded by the `2026-06-20 10:31 -0300` PG-007 closure):
  - migrations remain `29/29` executed and `0` pending;
  - PG-001 planner remains `planned_row_count=0`;
  - PG-002 postcheck remains `all_post_apply_checks_ok=true`;
  - PG-003 oracle planner remains `backfill_ready=0`;
  - PG-005 Lorehold critical-role dry-run remains `applied_counts=0`;
  - PG-006 postcheck remains migration `029` present, constraint present,
    `auto=1751`, `review_only=3437`, and
    `remaining_needs_review_not_review_only=0`;
  - latest battle at that time was `20260620_121005`,
    `battle_replay_final_status=trusted_for_strategy_learning`, with `16/16`
    tests passing. That was later superseded by `20260620_140016`, then by
    the current `20260620_181004` Lorehold Wheel closure run; `20260620_132812`
    remains the PG-007 closure run.

- `python3 -m unittest server/test/learned_deck_coherence_audit_test.py server/test/plan_learned_deck_partner_identity_backfill_test.py`
  - result: `21` tests passed
- `set -a && source server/.env && set +a && python3 server/bin/plan_learned_deck_partner_identity_backfill.py --dry-run --summary-only`
  - result: `status=PASS`, `planned_row_count=0`, `db_mutations=false`
- pre-PG-002 compact learned-deck audit:
  `set -a && source server/.env && set +a && python3 server/bin/learned_deck_coherence_audit.py --stdout`
  - historical result before PG-002 apply: `active_learned_decks=60`,
    `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
    `all_core_metadata_zero=54`, `some_core_metadata_zero=4`,
    severity `high=167`, `medium=12`
- post-PG-002 full learned-deck artifact
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`
  - result: `active_learned_decks=60`, `metadata_total_lands_mismatch=0`,
    `metadata_zero_lands=0`, `all_core_metadata_zero=0`,
    `partner_identity_not_modeled=0`, residual `some_core_metadata_zero=5`,
    severity `high=2`, `medium=13`
- backend Deck route/support slice:
  - `dart analyze` over focused bridge-resolution, bulk-cards,
    import-to-deck, validation, and recommendations files returned no issues;
  - focused `dart test` returned `52/52` tests passed.
- Flutter Deck provider/UI slice:
  - focused `flutter analyze` returned no issues;
  - focused `flutter test` returned `105/105` tests passed.
- PG-006 runtime cache sync:
  - backup:
    `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg006-runtime-sync.20260620_120904.bak`;
  - sync report:
    `battle_runtime_execution_status_sqlite_refresh_20260620_120904.json`
    with `apply_pg=false`, `apply_sqlite_from_pg=true`,
    `pg_rows_loaded=5188`, `sqlite_inserted_or_updated=5106`, and
    `canonical_snapshot_rows_exported=3159`;
  - post-sync effect audit:
    `execution_status_counts={"auto":1702,"review_only":1457}`,
    `needs_review_rule_names=1457`, `review_only_rule_names=1457`;
  - full recurring battle latest at that time:
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`,
    `battle_replay_final_status=trusted_for_strategy_learning`,
    `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
    `test_results_total=16`, and `test_results_status_counts={"pass":16}`.
- PostgreSQL queue heartbeat at `2026-06-20 09:24 -0300`:
  - PG-001 planner: `planned_row_count=0`, `db_mutations=false`;
  - PG-002 postcheck SQL: `all_post_apply_checks_ok=true`;
  - PG-003 oracle planner: `backfill_ready=0`, `db_mutations=false`;
  - PG-005 Lorehold critical-role dry-run: `applied_counts=0`,
    `db_mutations=false`;
  - PG-006 SELECTs: `auto=1751`, `review_only=3437`,
    `generated_needs_review_not_review_only=0`, migration `029=1`.
- Read-only recheck at `2026-06-20 09:36 -0300`
  (historical; superseded by the current `20260620_132812` latest battle):
  - `cd server && dart run bin/migrate.dart --status` reports `29/29`
    migrations executed and `0` pending;
  - latest battle symlink resolves to
    `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_121005`;
  - latest `summary.json` reports
    `battle_replay_final_status=trusted_for_strategy_learning`,
    `mandatory_gate_divergences=[]`, `test_results_total=16`,
    `test_results_status_counts={"pass":16}`,
    `execution_status_counts={"auto":1702,"review_only":1457}`, and
    `runtime_surface_manifest_total_files=110`.

## PostgreSQL State

### PG-001 - Partner/background identity metadata backfill

Status: `applied_validated_closed`

Evidence:

- apply approved by Rafael on 2026-06-20 06:39 -0300
- apply committed `10` rows in `commander_learned_decks.metadata`
- independent postcheck:
  `expected_rows=10`, `matched_rows=10`, `model_ok_rows=10`,
  `combined_identity_ok_rows=10`, `backfill_source_ok_rows=10`,
  `all_post_apply_checks_ok=true`
- post-apply planner:
  `status=PASS`, `planned_row_count=0`, `planned_rows=[]`,
  `db_mutations=false`
- current audit code/test closure:
  `partner_identity_not_modeled` respects persisted
  `metadata.commander_identity_model`
- focused tests: `21` Python tests passed

Action:

- Do not re-run PG-001 apply.
- Keep rollback SQL only as emergency rollback evidence.

### PG-002 - Global learned-deck metadata canonicalization

Status: `applied_validated`

Evidence:

- pre-apply read-only audit reported:
  `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
  `all_core_metadata_zero=54`, `some_core_metadata_zero=4`
- package artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_package_20260620_0718.md`
- dry-run artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_metadata_canonicalization_pg002_dryrun_20260620_0718.json`
- dry-run result:
  `checked=60`, `reported=60`, `changed=59`, `applied=0`,
  `db_mutations=false`
- precheck result:
  `expected_rows=59`, `matched_rows=59`, `before_matches=59`,
  `already_after_rows=0`, `would_change_rows=59`, `active_matches=59`
- `learned_deck:82` is unchanged by this package.

Post-apply evidence:

- Apply executed in this Auditor Central thread at `2026-06-20 08:32 -0300`.
- Apply result: `UPDATE 59`, `COMMIT`.
- SQL postcheck:
  `expected_rows=59`, `matched_rows=59`, `after_matches=59`,
  `still_before_rows=0`, `active_matches=59`,
  `all_post_apply_checks_ok=true`.
- Learned-deck coherence audit after apply:
  `active_learned_decks=60`, `high=2`, `medium=13`,
  `some_core_metadata_zero=5`.
- Full post-apply artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`
  confirms `metadata_total_lands_mismatch=0`, `metadata_zero_lands=0`,
  `all_core_metadata_zero=0`, and `partner_identity_not_modeled=0`.
- Canonicalizer post-apply dry-run:
  `status=PASS`, `db_mutations=false`, `checked=60`, `changed=0`,
  `applied=0`.

### PG-003 - Oracle/card text/type backlog

Status: `not_ready`

Evidence:

- current oracle inventory still shows global oracle/type gaps:
  `missing_any=363`, `missing_oracle_id=4`, `missing_oracle_text=360`
- `plan_oracle_text_backfill.py --no-scryfall --limit 10` is read-only and
  returned `backfill_ready=0`, `planned_items=6`, and `db_mutations=false`

Missing before any apply:

- policy for official blank oracle text
- policy for Arena/Alchemy `A-` identities
- alias/reprint handling
- row-by-row dry-run and rollback

### PG-004 / PG-007 - Battle rule promotion / Leyline of Abundance

Status: `pg007_applied_validated_runtime_synced_battle_trusted`

Evidence:

- PG-007 closure battle artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `forensic_lineage_status=complete`
- `forensic_rule_findings=0`, `forensic_turn_findings=0`
- PostgreSQL postcheck confirms the Leyline target rule exists and the
  `card_intelligence_snapshot` row now has a `battle_rules` entry.
- PG-007 SQL package, rollback, and postcheck remain preserved under
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_*_20260620_1018.sql`

Current action:

- Keep PG-007 closed unless a future SELECT, sync report, or battle artifact
  proves rollback or drift.
- Do not reapply PG-007 blindly; use the retained rollback/apply package only
  with fresh precheck evidence.

### PG-005 - Lorehold critical role/function/semantic rows

Status: `already_present_no_apply_needed`

Evidence:

- `plan_lorehold_critical_role_backfill.py --dry-run` returned `status=PASS`,
  `db_mutations=false`, `applied_counts=0`
- `counts_before` equals `counts_after`:
  `existing_commander_synergy_rows=5`, `existing_function_tag_rows=11`,
  `existing_semantic_v2_rows=4`

Action:

- Do not run `--apply` now.
- Treat this as evidence that the critical Lorehold rows are already present,
  not as a new deploy request.

### PG-006 - card_battle_rules execution_status migration drift

Status: `applied_validated`

Pre-apply evidence:

- `dart run bin/migrate.dart --status` reports:
  `029 add_card_battle_rules_execution_status` pending.
- Live read-only PostgreSQL inspection at `2026-06-20 08:08 -0300` shows:
  - `card_battle_rules.execution_status` already exists, is `NOT NULL`, and
    defaults to `'auto'::text`;
  - `chk_card_battle_rules_execution_status` is missing;
  - `schema_migrations.version='029'` is not recorded.
- PG-006 precheck returned:
  `generated / needs_review / auto = 1970`,
  `generated / needs_review / review_only = 1467`, and
  `pg006_rows_to_normalize=1970`.
- PG-006 precheck also shows the live `card_intelligence_snapshot` and
  `optimize_candidate_quality_summary` view definitions do not mention
  `execution_status`; the apply package refreshes them using current backend
  definitions before recording migration `029`.
- SQL package:
  `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_execution_status_pg006_package_20260620_0808.md`.

Post-apply evidence:

- Apply executed in this Auditor Central thread at `2026-06-20 08:30 -0300`.
- Apply result: `COMMIT`, `normalized_rows=1970`, rollback backup rows `1970`.
- Postcheck:
  `execution_status_counts={"auto":1751,"review_only":3437}`,
  `generated / needs_review / review_only = 3437`,
  `remaining_needs_review_not_review_only=0`,
  `chk_card_battle_rules_execution_status` present, migration `029` present,
  `card_intelligence_snapshot_view.mentions_execution_status=true`.
- `dart run bin/migrate.dart --status`: all `29/29` migrations executed.
- Current read-only recheck at `2026-06-20 09:36 -0300` again reports all
  `29/29` migrations executed and `0` pending.

Important:

- Do not run native `dart run bin/migrate.dart` as the fix for this drift. The
  migration source only normalizes rows where `execution_status` is null or
  blank, while the current bad rows already store `auto`.
- PG-006 normalizes PostgreSQL execution governance and migration state. The
  local Hermes runtime cache was refreshed from PostgreSQL after apply, and the
  latest battle artifact exposes `review_only` rule names.

## Worktree Control

Detailed worktree triage lives in:

- `docs/hermes-analysis/WORKTREE_TRIAGE_REGISTER_2026-06-20.md`
- operational map:
  `docs/hermes-analysis/WORKTREE_OPERATIONAL_MAP_2026-06-20.md`
- file ownership index:
  `docs/hermes-analysis/WORKTREE_FILE_OWNERSHIP_INDEX_2026-06-20.md`
- cleanup proposal:
  `docs/hermes-analysis/WORKTREE_CLEANUP_PROPOSAL_2026-06-20.md`

Current cleanup rule:

- no cleanup is authorized yet.
- older duplicate audit artifacts may become cleanup candidates only after the
  latest artifact and register evidence are retained.
- source files and tests under `app/` and `server/` are not cleanup candidates
  until their owning change is validated or explicitly rejected.

Latest validation state:

- changed/untracked backend Dart aggregate: `dart analyze` no issues and
  `dart test` `146/146` passed.
- changed/untracked backend Python tests aggregate: `39` tests passed.
- changed/untracked app Dart aggregate: `flutter analyze` no issues and
  `flutter test` `105/105` passed.
- backend data-contract anti-fanout slice: source inspection confirms
  deck-reading routes prefer `card_intelligence_snapshot` and fallback through
  per-card `jsonb_agg(...)` / `EXISTS`; focused guard tests returned `19/19`
  and `24/24` Dart tests passed plus `7/7` Python planner tests passed.
- PostgreSQL writes performed by this single-operator cycle are PG-006, PG-002,
  and PG-007, all postchecked. Local Hermes SQLite cache syncs were performed
  for PG-006 and PG-007 after backups; those syncs did not write PostgreSQL.
  No live route, live OpenAI, real-device, cleanup, commit, push, revert, or
  stash has been performed in these aggregate validations.

## Single Operator Mode - 2026-06-20 11:05 -0300

Rafael paused the other chats and explicitly assigned this Auditor Central
thread to operate the project for now.

Current rule:

- do not generate new commands for other chats as the default path.
- this thread audits, patches, validates, prepares PostgreSQL packages, applies
  PostgreSQL only after explicit approval, and controls worktree cleanup.
- preserve the same safety gates: no commit/push, no deck swap, no destructive
  cleanup, and no PostgreSQL write without exact approval and evidence.

Latest executed step:

- App Deck provider/UI ownership audit completed.
- Auditor patch normalized `createDeck` `archetype` for both API request and
  optimistic local cache.
- Validation: focused provider/support tests `65/65` passed and focused
  widget/screen tests `40/40` passed.
- Backend Deck routes/helpers ownership audit completed.
- Auditor patch made the OpenAI recommendations prompt include
  backend-computed `candidate_color_identity`.
- Validation: focused recommendations tests `16/16`, focused
  bulk/import/validation/name-resolution tests `33/33`, and focused backend
  Dart analyze passed.
- Backend AI/import/simulate ownership audit completed without extra patch.
- Validation: focused AI/import/simulate Dart tests `83/83`, focused Python
  planner/auditor tests `39/39`, and focused backend Dart analyze passed.

## Next Operator Step

1. Keep this Auditor Central thread as the single operator until Rafael
   explicitly reopens additional chats.
2. Keep PG-001 closed.
3. Keep PG-002, PG-006, and PG-007 closed unless future SELECT/artifact
   evidence proves rollback or drift.
4. Cleanup proposal is prepared and audited as an exact `8`-file list; do not
   delete anything until the exact list is approved.
5. No additional PostgreSQL apply is ready at the current heartbeat.
6. Before any commit discussion, review the broad dirty source diff by
   ownership area; aggregate tests passed, but that does not prove live backend
   deploy, live OpenAI behavior, or real-device Flutter behavior.

## Publication Branch Observation - 2026-06-20 13:28 -0300

Scope:

- Heartbeat re-read the current Git state, central registers, Lorehold register,
  latest learned-deck coherence artifact, and latest battle summary.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, push,
  live app route call, or OpenAI call was performed by this heartbeat.

Current evidence:

- `git status --short --branch`:
  `## codex/manaloom-batches-20260620...origin/codex/manaloom-batches-20260620`.
- `git status --porcelain=v1 | wc -l`: `0`.
- `git rev-list --left-right --count HEAD...@{upstream}`: `0 0`.
- Current commits on the publication branch are:
  `9ffe002b docs: publish ManaLoom audit evidence batch`,
  `7310111f chore: add ManaLoom audit tooling batch`,
  `764a3255 feat: harden ManaLoom deck backend flows`, and
  `ca939026 feat: refine deck app flows`.
- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`.
- Lorehold `learned_deck:82` still has `issues=[]`, `metadata.total_lands=33`,
  and excluded fast mana remains `Chrome Mox`, `Mox Diamond`, `Mox Opal`.
- Latest battle summary resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`
  and reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, complete forensic lineage, and tests `16/16`.

Current conclusion:

- The earlier Batch 0/1 readiness entries are historical checkpoint evidence.
  At this 13:28 checkpoint, the working tree was clean and aligned with the
  publication branch upstream.
- This checkpoint was superseded by the `Master Migration Closure -
  2026-06-20 13:31 -0300` section below, which records the later
  fast-forward/push of `master`.
- No new PostgreSQL apply is ready from the current Lorehold/deck register
  state.
- PG-001, PG-002, PG-006, PG-007, and PG-008 remain closed unless future
  SELECT, sync report, or battle artifact evidence proves rollback or drift.

## Master Migration Closure - 2026-06-20 13:31 -0300

Scope:

- Migrated the publication branch into `master` by fast-forward after Rafael
  requested migration so the work would not remain detached from the main line.
- Pushed `master` to GitHub.
- Verified public backend health after deploy.
- No PostgreSQL write, deck swap, cleanup, stash, revert, or new app/backend
  code edit was performed in this closure.

Evidence:

- Merge path: `master` fast-forwarded from `3908e88c` to `ca939026`.
- Pushed range: `3908e88c..ca939026 master -> master`.
- Final Git state:
  `git status --short --branch` reports `## master...origin/master`.
- Final divergence: `git rev-list --left-right --count HEAD...origin/master`
  reports `0 0`.
- Untracked non-ignored files: `0`.
- Public `/health` reports `status=healthy`, `environment=production`, and
  `git_sha=ca93902621728baefd0715f11fecccd0bfd62f03`.

Current conclusion:

- The batch branch has been migrated to `master` and production is running the
  migrated SHA.
- The local worktree is clean except for intentionally ignored SQLite backup
  files under `docs/hermes-analysis/manaloom-knowledge/backups/`.
- No current PostgreSQL apply is ready after this migration.

## Heartbeat Documentation Reconciliation - 2026-06-20 13:33 -0300

Scope:

- Rechecked the post-migration state during the Lorehold monitor heartbeat and
  documented the 13:28 publication-branch checkpoint as historical/superseded
  by the 13:31 `master` migration closure.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, push,
  app/backend code edit, live app route call, or OpenAI call was performed by
  this heartbeat.

Evidence:

- Pre-closure `git status --short --branch` reported
  `## master...origin/master` plus three modified documentation files from this
  reconciliation:
  `LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`,
  `MANALOOM_CENTRAL_AUDITOR_ORDERS.md`,
  `POSTGRES_DEPLOY_REGISTER_2026-06-20.md`.
- `git rev-list --left-right --count HEAD...origin/master`: `0 0`.
- Volatile-SHA closure rule: this register must not keep re-stamping exact
  "current HEAD" after each documentation-only closure commit. Exact deploy SHA
  proof remains mandatory for deploy validation, but it belongs in the command
  evidence or bounded smoke artifact for that cycle, not in a tracked heartbeat
  note that would recursively dirty itself.
- Public `/health` recheck reported `status=healthy` and
  `environment=production` during the reconciliation.
- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_115918.json`;
  Lorehold `learned_deck:82` still has `issues=[]`.
- Latest battle summary remains
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_160459/summary.json`
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, complete forensic lineage, and tests `16/16`.

Current conclusion:

- The active documentation loop is closed by policy: no further tracked
  heartbeat should be opened just to restamp the SHA created by the previous
  heartbeat documentation commit.
- PG-001, PG-002, PG-006, PG-007, and PG-008 remain closed.
- PG-003 remains policy-blocked and PG-005 remains no-apply-needed.
- No current PostgreSQL apply is ready.

## Active Single-Operator Goal - 2026-06-20 18:27 -0300

Rafael's current order supersedes older no-PostgreSQL/no-commit chat wording for
this thread:

- The central auditor owns the full real-battle validation loop for now.
- Allowed actions in this loop: code correction, tests, PostgreSQL battle-rule
  deploy, Hermes SQLite/cache sync, documentation/register reconciliation,
  worktree organization, commit, and push.
- Still protected: do not apply a new Lorehold deck swap unless the swap itself
  is explicitly documented and justified from battle evidence.

Current verified state:

- Latest battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`.
- Status: `trusted_for_strategy_learning`, reason
  `all_mandatory_gates_pass`.
- Real-battle table intent is active and passing:
  `table_intent_statuses={"pass":16}`, `table_intent_findings=0`,
  `opponent_spell_cast=270`, `opponent_interaction_events=72`,
  `opponent_trigger_interaction_events=32`, `opponent_wins=15`,
  `target_wins=1`.
- Target pressure is active and passing:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`.
- PostgreSQL/cache promotions through round9 are closed, ending with
  `pg_rows_loaded=5233`, `sqlite_inserted_or_updated=5151`,
  `canonical_snapshot_rows_exported=3187`, and `curated_rows=104`.

Next exact order:

1. Finish worktree organization by staging only intentional code, tests,
   registers, and evidence artifacts from the real-battle cycle.
2. Run final repository checks after documentation reconciliation.
3. Commit and push the validated cycle.
4. Start the next Lorehold deck-optimization cycle from the `20260620_212035`
   real-battle baseline, not from older target-pressure-only readings.

## Target-Pressure Battle Gate Closure - 2026-06-20 16:00 -0300

Scope:

- Rechecked the new battle target-pressure gate after `latest` temporarily
  moved to blocked run `20260620_185202`.
- Applied a battle-runtime metadata fix so evaluation-target attacks that are
  also lethal are tagged as `target_reason=lethal` before the `combat` event is
  emitted.
- Added focused regression coverage for the lethal Lorehold evaluation-target
  case.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, push,
  live app route call, or OpenAI call was performed.

Evidence:

- The blocked run was
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185202/summary.json`
  with `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked","replay_decision_audit=blocked"]`,
  `forensic_turn_findings=4`, and `decision_audit_turn_findings=4`.
- The concrete blocked invariant was repeated in seeds `63212004`, `63212007`,
  `63212009`, and `63212014`: potential lethal combat against Lorehold was not
  tagged as lethal.
- Focused tests passed:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`,
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py`,
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py`,
  and `python3 -m py_compile` for the touched battle scripts.
- Latest battle now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_185748/summary.json`.
- That summary reports `run_scope=recurring_full`,
  `run_profile=recurring_16_seed`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":17}`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `decision_audit_decision_findings=0`, `decision_audit_turn_findings=0`, and
  `action_findings=0`.
- Target pressure passed in the same run:
  `target_pressure_statuses={"pass":16}`, `target_pressure_findings=0`,
  `target_pressure_opponent_combat_total=117`,
  `target_pressure_opponent_combat_to_target=117`,
  `target_pressure_opponent_combat_to_other=0`, and
  `target_pressure_opponent_multi_defender_attack=0`.
- Battle validation register
  `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md` records the
  target-pressure checkpoint and notes the operational battle smoke now reads
  `83.3% (10W/2L/0S)` under direct pressure.

Current conclusion:

- The `20260620_185202` blocked latest is historical and superseded by the clean
  `20260620_185748` full recurring run.
- The target-pressure gate is now part of required battle readiness evidence.
- PG-001, PG-002, PG-006, PG-007, PG-008, PG-009, and the Lorehold canonical
  Wheel apply remain closed unless future SELECT, sync report, learned-deck
  artifact, or battle artifact evidence proves rollback or drift.
- PG-003 remains policy-blocked and PG-005 remains no-apply-needed.
- No current PostgreSQL apply is ready.

## PG-009 Korvold Learned-Deck Closure - 2026-06-20 14:24 -0300

Scope:

- Closed the global learned-deck high-severity Korvold backlog that had been
  identified after the post-loop smoke.
- This is not a Lorehold deck `6` mutation and not a deck swap.

Evidence:

- Deploy register entry `PG-009` records the authorized PostgreSQL replacement
  of the old active partial Korvold row.
- Old partial source `edhrec/learned_deck:7` is no longer the active learned
  Korvold row.
- Active replacement source is
  `commander_reference_decks` /
  `edhrec_korvold_fae_cursed_king_default_average_sprint3_lot_b_2026_05_14`.
- Fresh read-only learned-deck artifact:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_172437.json`.
- That artifact reports Korvold `parsed_quantity=100`,
  `resolved_quantity=100`, commander quantity `1`, and `issues=[]`.
- Global learned-deck severity is now `{"medium":13}` with no high findings.
- Lorehold `learned_deck:82` remains clean in the same artifact with
  `issues=[]`.

Current conclusion:

- PG-009 is closed unless future PostgreSQL SELECT, sync report, or learned-deck
  artifact evidence proves rollback or drift.
- Active learned-deck QA now consists of medium land-count review rows and
  `some_core_metadata_zero=5`.
- No current PostgreSQL apply is ready.

## Latest Battle Review Regression - 2026-06-20 14:28 -0300

Scope:

- Rechecked `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
  after PG-009 and the learned-deck artifact update.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, push,
  app/backend code edit, live app route call, or OpenAI call was performed.

Evidence:

- Latest battle now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_170724/summary.json`.
- `battle_replay_final_status=review_required`.
- Mandatory divergences:
  `forensic_audit=review_required` and
  `replay_decision_audit=review_required`.
- Tests still pass: `16/16`.
- Forensic lineage is complete.
- `forensic_rule_findings=0`, `forensic_turn_findings=1`,
  `decision_audit_decision_findings=0`.
- Concrete finding appears in both `forensic_audit.json` and
  `replay_decision_audit.json` for seed `63211720`: event
  `board_wipe_resolved`, player `Lorehold`, turn `12`, severity `low`, finding
  `Board wipe left more protected creatures (5) than destroyed (3).`

Current conclusion:

- This is a battle/auditor follow-up, not a PostgreSQL deployment item.
- PG-001, PG-002, PG-006, PG-007, PG-008, and PG-009 remain closed unless
  future SELECT, sync report, learned-deck artifact, or battle artifact evidence
  proves rollback or drift.
- No current PostgreSQL apply is ready.

## Lorehold Canonical Wheel Closure - 2026-06-20 15:28 -0300

Scope:

- Reconciled the stale `20260620_170724` review-required section against the
  current Lorehold register, learned-deck coherence artifact, quality gate, and
  battle latest symlink.
- No PostgreSQL write, deck swap, cleanup, stash, revert, stage, commit, push,
  app/backend code edit, live app route call, or OpenAI call was performed by
  this heartbeat.

Evidence:

- `git status --short --branch` returned only `## master...origin/master`.
- Latest battle now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_181004/summary.json`.
- That summary reports `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_status_counts={"pass":16}`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `decision_audit_decision_findings=0`, `decision_audit_turn_findings=0`, and
  `action_findings=0`.
- The applied Lorehold swap result artifact
  `docs/hermes-analysis/master_optimizer_reports/pg_apply_lorehold_wheel_swap_result_20260620_180448.json`
  shows materialized deck
  `528c877f-f829-4207-95e6-73981776c323` with `wheel=1`, `reforge=0`,
  `rows=100`, `total_cards=100`.
- The same apply result shows active learned deck
  `f46c0421-71b4-4de3-bb79-05a916b4988b` with `has_wheel=true`,
  `has_reforge=false`, and metadata
  `canonical_lorehold_swap_20260620`.
- Fresh read-only learned-deck coherence artifact
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_181429.json`
  reports Lorehold `learned_deck:82` with `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `total_lands=33`, and strategy package pass.
- Quality gate
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_quality_gate_20260620_181826.md`
  points to audit run `20260620_181004` and records all mandatory gates pass.

Current conclusion:

- The `20260620_170724` board-wipe/protection finding is historical and
  superseded by the approved canonical Wheel apply plus the clean full battle
  rerun.
- PG-001, PG-002, PG-006, PG-007, PG-008, PG-009, and the Lorehold canonical
  Wheel apply remain closed unless future SELECT, sync report, learned-deck
  artifact, or battle artifact evidence proves rollback or drift.
- PG-003 remains policy-blocked and PG-005 remains no-apply-needed.
- No current PostgreSQL apply is ready.
