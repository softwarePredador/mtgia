# ManaLoom Central Auditor Orders

Last updated: 2026-06-20 21:08 -0300
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
6. Latest full battle now resolves to `20260621_000827` and is
   `trusted_for_strategy_learning`; `mandatory_gate_divergences=[]`, forensic
   findings are `0`, target-pressure and table-intent pass `16/16`, and action
   and replay-decision findings are `0`.
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
14. PG-011 Lorehold defense variant was detected as externally applied in
    PostgreSQL and then synced into the local Hermes runtime cache. This
    heartbeat did not execute the apply; do not reapply it. Current follow-up
    is evidence reconciliation only.
15. PG-012, PG-013, and PG-014 were detected as externally applied in
    PostgreSQL and synced into the local Hermes runtime cache. This heartbeat
    did not execute their apply commands. Keep them closed unless SELECT,
    runtime-cache, learned-deck, or battle evidence proves rollback or drift.
16. The latest learned-deck coherence artifact is
    `learned_deck_coherence_audit_20260620_233027.*`: Lorehold
    `learned_deck:82` remains `issues=[]`, 100/100 parsed/resolved, no premium
    Mox, and no name-match drift. The only Lorehold strategy issue is the
    medium `big_spell_finishers` package counter created by the approved
    defense variant, not a deck resolution failure.
17. PG-015 is now the externally applied `Wrath of God` battle-rule package:
    read-only postcheck returned `curated_executable_rows=1`,
    `stale_enabled_wipe_rows=0`, and the local cache selects the
    `curated/verified/auto` `board_wipe` row. Later latest battle `000827`
    passed all mandatory gates. This heartbeat did not execute the apply
    command. Keep it closed unless SELECT, sync, or battle evidence proves
    rollback/drift.
18. `Arcane Epiphany` is candidate-only from superseded latest `235914`. It
    exists in `cards`, has `0` PG/local battle-rule rows, but is not active in
    current latest `000827`. No package was prepared or applied here; any future
    write needs exact approval and a reproduced active blocker.

## PG-012/PG-013/PG-014 External Apply Reconciliation - 2026-06-20 20:30 -0300

Observed external state:

- New PG-012, PG-013, and PG-014 package/sync artifacts appeared under
  `docs/hermes-analysis/master_optimizer_reports/`.
- PG-012 postcheck SQL, executed with `PGOPTIONS='-c default_transaction_read_only=on'`,
  returned `card_rows=1`, `curated_executable_rows=1`, and
  `stale_enabled_remove_rows=0` for `Flame Wave`; the curated rule is
  `damage_player_and_creatures`, source `curated`, confidence `1.000`,
  `review_status=verified`, `execution_status=auto`, reviewed by
  `codex_central_auditor_pg012`.
- PG-013 postcheck SQL, executed with read-only transaction settings, returned
  `card_rows=1`, `curated_executable_rows=1`, and
  `stale_enabled_draw_rows=0` for `Brainstone`; the curated rule is
  `topdeck_manipulation`, source `curated`, confidence `0.880`,
  `review_status=active`, `execution_status=auto`, reviewed by
  `codex_central_auditor_pg013`.
- PG-014 postcheck SQL, executed with read-only transaction settings, returned
  `card_rows=1`, `curated_executable_rows=1`,
  `stale_enabled_draw_rows=0`, and `protection_function_tag_rows=1` for
  `Sphere of Safety`; the curated rule is
  `attack_tax_per_enchantment`, source `curated`, confidence `1.000`,
  `review_status=verified`, `execution_status=auto`, reviewed by
  `codex_central_auditor_pg014`.
- Runtime sync artifacts show `apply_pg=false` and `apply_sqlite_from_pg=true`
  for PG-012/013/014. The latest PG-014 sync reports
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`, and
  `canonical_snapshot_rows_exported=3195`.

Validation performed by this heartbeat after detecting the external state:

- `sync_battle_card_rules_pg.py` was corrected so PG mirror refreshes preserve
  reviewed local runtime rows when `apply_pg=false`, preventing the local
  reviewed Brainstone rule from being erased by PG review-only generated rows.
- Focused sync regression
  `test_pg_mirror_keeps_reviewed_runtime_row_over_pg_review_only_snapshot`
  was added in `test_sync_battle_card_rules_pg_selection.py`.
- `python3 -m py_compile` over the sync script and selection test passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py`
  passed (`7` tests).
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed, including `Flame Wave`, `Brainstone`, and
  `Sphere of Safety` regressions.
- Fresh read-only learned-deck audit
  `learned_deck_coherence_audit_20260620_233027.json` keeps Lorehold
  `learned_deck:82` with `issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `unresolved=[]`, no premium Mox, and no PG/SQLite
  name drift.
- Fresh full recurring battle
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_232534/summary.json`
  completed `16/16` seeds and is `trusted_for_strategy_learning`.
  `mandatory_gate_divergences=[]`, forensic/action/replay-decision findings
  are `0`, target-pressure passes `16/16`, table-intent passes `16/16`, and
  tests are `18/18`.

Operational state:

- This heartbeat did not execute PostgreSQL apply commands for PG-012,
  PG-013, or PG-014; it observed external applied state and reconciled evidence.
- No deck swap, cleanup, stage, commit, or push was performed.
- PG-012, PG-013, and PG-014 are closed as externally applied,
  postchecked, runtime-synced, and battle-validated. Do not reapply without new
  rollback/drift evidence plus exact command approval.

## Current Battle Drift After External Runner - 2026-06-20 20:37 -0300

- A later external runner replaced `latest` with
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_233350/summary.json`.
- Invocation kind: `codex_variant_sphere_for_guttersnipe`; start seed
  `63212310`; seeds `16/16`.
- Final status: `blocked`; reason:
  `one_or_more_mandatory_gates_blocked`;
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- Forensic findings: `2` total, `{"high":1,"medium":1}`, both
  `Arcane Epiphany` from `The Emperor of Palamecia #42 (real)` on turn `10`:
  `spell_cast` medium and `spell_resolved` high, effect `draw_cards`, source
  `functional_tags_json`.
- Other gates remain clean: target-pressure `pass=16`,
  `target_pressure_findings=0`, table-intent `pass=16`,
  `action_findings=0`, replay-decision findings `0`, tests `18/18`.
- SELECT-only PostgreSQL evidence: `Arcane Epiphany` exists as one card row
  (`id=f5395e90-d0ef-4bf0-b042-f0cff60d31ae`, mana cost `{3}{U}{U}`,
  type `Instant`, oracle `This spell costs {1} less to cast if you control a
  Wizard. Draw three cards.`, color identity `{U}`) and has
  `battle_rule_rows=0`.
- Local cache evidence: `battle_card_rules` has `0` rows for
  `Arcane Epiphany`; it is absent from `known_cards_canonical_snapshot.json`,
  `known_cards_generated.json`, and `reviewed_battle_card_rules.json`.

Operational state:

- PG-012/013/014 remain closed.
- This was a real but superseded drift candidate, not an active pending after
  `234004`.
- No PG-015 package was applied; no PostgreSQL write, deck swap, cleanup,
  stage, commit, or push was performed.

## Current Battle Closure After External Variant Reruns - 2026-06-20 20:40 -0300

- Later external runners superseded `233350`; `latest` now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234004/summary.json`.
- Invocation kind: `codex_variant_sphere_for_victory_chimes`; start seed
  `63212310`; seeds `16/16`.
- Final status: `trusted_for_strategy_learning`; reason:
  `all_mandatory_gates_pass`; `mandatory_gate_divergences=[]`.
- Forensic findings: `0`; action findings: `0`; replay-decision findings:
  `0`; target-pressure `pass=16`; table-intent `pass=16`; tests `18/18`.
- PG-012/013/014 remain closed. PG-015 remains candidate-only from a
  superseded run and is not in the active pending list unless it reappears in a
  current latest artifact.

## Current Battle Drift After Variant Sweep Continued - 2026-06-20 20:49 -0300

- Later external variant runs continued after `234004`; at this checkpoint,
  `latest` resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_234900/summary.json`.
- Invocation kind: `codex_variant_spire_for_guttersnipe`; start seed
  `63212310`; seeds `16/16`.
- Final status: `blocked`; reason:
  `one_or_more_mandatory_gates_blocked`;
  `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- Forensic findings: `2`, severity `{"high":1,"medium":1}`, both
  `Arcane Epiphany`, effect `draw_cards`, source `functional_tags_json`, turn
  `10`, player `The Emperor of Palamecia #42 (real)`.
- Clean gates: target-pressure `pass=16`, target-pressure findings `0`,
  table-intent `pass=16`, action findings `0`, replay-decision findings `0`,
  tests `18/18`.
- A new external runner was already active after this latest was read. Treat
  `234900` as the current checkpoint, not a guarantee that the symlink will not
  advance again.

## Current Battle Closure After Variant Sweep Continued - 2026-06-20 20:52 -0300

- Re-read `latest` after the runner that was active at the 20:49 checkpoint
  completed. The symlink now resolves to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235219/summary.json`.
- Invocation kind: `codex_real_deck_after_variants`; start seed `63212310`;
  seeds `16/16`.
- Final status: `trusted_for_strategy_learning`; reason:
  `all_mandatory_gates_pass`; `mandatory_gate_divergences=[]`.
- Clean gates: forensic findings `0`, target-pressure `pass=16` with
  `target_pressure_findings=0`, table-intent `pass=16`, action findings `0`,
  replay-decision findings `0`, and event-contract unclassified observed/static
  totals `0/0`.
- `test_results_status_counts={"pass":18}` in the summary; the compatibility
  fields `tests_passed` and `tests_total` are `null`.
- PG-012/013/014 remain closed. `Arcane Epiphany` returns to
  candidate-only/historical status because the active latest no longer blocks
  on it. No PostgreSQL apply, cache hotfix, deck swap, cleanup, stage, commit,
  or push was performed.

## PG-015 Wrath External Apply And Current Arcane Drift - 2026-06-20 20:59 -0300

- New PG-015/Wrath package and sync artifacts appeared:
  `wrath_of_god_battle_rule_pg015_*_20260620_205619.*` and
  `battle_card_rules_sqlite_from_pg_pg015_wrath_20260620_205900.json`.
- PG-015/Wrath precheck/postcheck SQL, executed read-only with
  `PGOPTIONS='-c default_transaction_read_only=on'`, shows PostgreSQL already has
  one curated executable `Wrath of God` `board_wipe` row:
  `curated_executable_rows=1`, `stale_enabled_wipe_rows=0`,
  reviewed by `codex_central_auditor_pg015` at
  `2026-06-20 23:58:17.150487+00`.
- Local SQLite cache also has `Wrath of God` as `curated/verified/auto`
  `board_wipe`; the generated duplicate is `deprecated/disabled`.
- Sync report says `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5236`, `sqlite_inserted_or_updated=5172`,
  `canonical_snapshot_rows_exported=3195`, and `pg_inserted_or_updated=0`.
- The active latest battle advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_235914/summary.json`
  with `invocation_kind=codex_variant_wrath_for_guttersnipe`, seeds `16/16`, and
  status `blocked` by `mandatory_gate_divergences=["forensic_audit=blocked"]`.
- Current blocker: `Arcane Epiphany`, seed `63212310`, turn `10`,
  `The Emperor of Palamecia #42 (real)`, effect `draw_cards`, source
  `functional_tags_json`; findings are one medium `spell_cast` and one high
  `spell_resolved`.
- Clean gates in `235914`: target-pressure `pass=16`, table-intent `pass=16`,
  action findings `0`, replay-decision findings `0`, event-contract pass, and
  `test_results_status_counts={"pass":18}`.
- No PostgreSQL apply, deck swap, cleanup, stage, commit, or push was performed
  by this heartbeat.

## Current Battle Closure After Wrath Variant Sweep - 2026-06-20 21:08 -0300

- Further external runners superseded `235914` and `000525`. The latest symlink now resolves
  to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_000827/summary.json`.
- Invocation kind: `codex_real_deck_after_wrath_variants`; start seed
  `63212310`; seeds `16/16`.
- Final status: `trusted_for_strategy_learning`; reason:
  `all_mandatory_gates_pass`; `mandatory_gate_divergences=[]`.
- Clean gates: forensic findings `0`, target-pressure `pass=16` with
  `target_pressure_findings=0`, table-intent `pass=16`, action findings `0`,
  replay-decision findings `0`, and `test_results_status_counts={"pass":18}`.
- PG-015/Wrath is now externally applied, postchecked, runtime-synced, and
  battle-validated by latest `000827`. Arcane Epiphany returns to
  candidate-only/historical status from superseded `235914`.
- `ps` recheck found no active battle-strategy runner after this latest read.
- No PostgreSQL apply, deck swap, cleanup, stage, commit, or push was performed
  by this heartbeat.

## PG-011 External Apply Reconciliation - 2026-06-20 19:48 -0300

Observed external state:

- New untracked PG-011 package/sync artifacts appeared under
  `docs/hermes-analysis/master_optimizer_reports/`.
- SELECT-only PostgreSQL checks show the target materialized Lorehold deck now
  has `Ghostly Prison`, `Crawlspace`, `Chaos Warp`, `Austere Command`,
  `Get Lost`, and `Professional Face-Breaker` at quantity `1`, while
  `Storm Herd`, `Worldfire`, `Rite of the Dragoncaller`,
  `Fiery Emancipation`, `Mana Geyser`, and `Rise of the Eldrazi` are absent.
- SELECT-only PostgreSQL checks show curated/verified/auto rules for:
  `Crawlspace=attack_limit`, `Ghostly Prison=attack_tax`, and
  `Get Lost=remove_creature`, with stale generated duplicates deprecated and
  disabled.
- SELECT-only PostgreSQL checks show `stax` function tags for `Crawlspace` and
  `Ghostly Prison` from `curated_pg011_lorehold_defense`.
- PG-011 postcheck SQL passed under read-only transaction settings:
  `out_qty_in_target_deck=0`, `in_qty_in_target_deck=6`,
  `target_deck_qty=100`, `target_deck_rows=100`,
  `active_learned_deck_ok=1`.
- Runtime sync artifact
  `sync_pg_target_deck_to_hermes_pg011_lorehold_defense_20260620_193849.json`
  reports `apply=true`, deck id `6`, `cards_written=100`,
  `quantity_written=100`, deck hash
  `d6317fc612db65a3c5fa03bfa82287871d93b88cc907e3ea78b8e46ccf1287b0`.
- Runtime cache sync artifact
  `battle_card_rules_sqlite_from_pg_pg011_lorehold_defense_20260620_193849.json`
  reports `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`, and
  `canonical_snapshot_rows_exported=3187`.

Validation performed by this heartbeat after detecting the external state:

- Fresh learned-deck audit
  `learned_deck_coherence_audit_20260620_224441.json` keeps Lorehold
  `learned_deck:82` with `issues=[]`, `parsed_quantity=100`, and
  `resolved_quantity=100`; metadata now records
  `lorehold_defense_variant_b_20260620`.
- Fresh full recurring battle
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_224455/summary.json`
  completed `16/16` seeds and is `review_required` by
  `forensic_audit=review_required`.
- The only current forensic findings are `6` low `Flame Wave` passive vs
  registry `remove_creature` findings on seeds `63212248`, `63212253`, and
  `63212256`; `turn_findings=0`.
- Target-pressure passes `16/16` with `target_pressure_findings=0`,
  `opponent_combat_to_target=284`, `opponent_combat_to_other=4`, and
  `opponent_multi_defender_attack=2`.
- Table-intent passes `16/16`; action, replay-decision, event-contract,
  effect-coverage, focused-template, unknown-template, and decision-trace gates
  pass; tests are `18/18`.
- Focused local validation passed after reading the extra runtime/source
  diffs: `py_compile` for modified battle scripts,
  `test_battle_forensic_audit_supported_effects.py`,
  `test_battle_target_pressure_audit.py`, and
  `test_battle_analyst_v10_3.py`.
- Additional `py_compile` passed for the source mapping files
  `battle_rule_registry.py`,
  `derive_functional_tags_from_battle_rules.py`, and
  `sync_pg_target_deck_to_hermes.py`.

Operational state:

- This heartbeat did not execute the PG-011 apply, did not apply a deck swap by
  command, and did not commit or push.
- PG-011 is now observed as externally applied and locally synced, not a
  pending package to apply.
- The live battle baseline is now `224455`; it is usable only with the
  low-forensic-review caveat until a future run returns trusted again.

## Battle Runtime Follow-Up - 2026-06-20 19:31 -0300

Observed current latest:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221652/summary.json`
- `run_scope=recurring_full`, `seeds_completed=16`, `start_seed=63212216`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`,
  `target_pressure_opponent_combat_to_target=190`,
  `target_pressure_opponent_combat_to_other=2`, and
  `target_pressure_opponent_multi_defender_attack=0`
- `table_intent_statuses={"pass":16}`
- `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `action_findings=0`, `decision_audit_decision_findings=0`, and
  `decision_audit_turn_findings=0`
- `test_results_status_counts={"pass":18}`
- Strategy has only low-confidence findings:
  `strategy_findings=7`, `strategy_low_confidence_findings=7`,
  `strategy_review_required_findings=0`

Source/test evidence observed in the current dirty worktree:

- `battle_analyst_v9.py` contains local battle-runtime handling for
  `attack_limit` / `attack_tax`, plus Lorehold self-preservation attacker
  reservation before declaring attacks.
- `battle_combat_tests.py` contains regression coverage for self-preservation
  under pressure, vigilance attackers that can still remain blockers,
  `Crawlspace` attacker limits, and `Ghostly Prison` attack taxes.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passed and included the new combat/runtime regressions.

Operational state:

- At that checkpoint, `221652` superseded `212035` as the live `latest`
  strategy-learning artifact. It is now superseded by `224455`.
- New untracked PG-011 package files were detected under
  `docs/hermes-analysis/master_optimizer_reports/lorehold_defense_variant_pg011_*_20260620_193420.*`.
  They propose swapping six Lorehold cards and writing
  `deck_cards`, `commander_learned_decks`, `card_battle_rules`, and
  `card_function_tags`; this is a policy-blocked candidate, not an applied
  change at this 19:31 checkpoint. The later 19:48 reconciliation observed
  PG-011 as externally applied and synced.
- Read-only package evidence checked this heartbeat:
  baseline artifact `20260620_221318` is trusted; temp variant run
  `/tmp/manaloom_lorehold_variant_b_mE2pHv/run_20260620_192657` has
  `3` Lorehold wins by `Winner:` lines, `80` combat events with attack
  restrictions, `52` attackers restricted, and `192` total tax paid.
- This heartbeat performed no PostgreSQL write, deck swap, cleanup, deletion,
  stash, revert, stage, commit, or push.
- No current PostgreSQL apply is ready.

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
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221652/summary.json`.
- Status: `trusted_for_strategy_learning`, reason
  `all_mandatory_gates_pass`.
- Real-battle table intent is active and passing:
  `table_intent_statuses={"pass":16}`, `table_intent_findings=0`,
  `opponent_spell_cast=183`, `opponent_interaction_events=71`,
  `opponent_trigger_interaction_events=41`, `opponent_wins=15`,
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
4. Start the next Lorehold deck-optimization cycle from the `20260620_221652`
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

## Latest Battle/PG Drift Reading - 2026-06-20 22:14 -0300

Scope:

- Re-read the central registers, Lorehold Deck 6 register, latest
  learned-deck coherence artifact, and battle latest symlink for heartbeat
  `monitor-lorehold-deck-6`.
- No PostgreSQL apply, deck swap, cleanup, stash, revert, stage, commit, push,
  app/backend code edit, live app route call, or OpenAI call was performed by
  this heartbeat.

Evidence:

- `git status --short --branch` returned branch `master...origin/master` with
  tracked deck/auditor worktree changes plus untracked PG011-PG018 package and
  sync artifacts.
- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_233027.json`.
  It is read-only, reports Lorehold `learned_deck:82` with `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `unresolved=[]`, no
  off-color candidates, and no partner/background identity issue.
- Latest battle summary at the start of this heartbeat resolved to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_010452/summary.json`.
  It reports `invocation_kind=codex_pg017_full64_real_deck_baseline`,
  `seeds_requested=64`, `seeds_completed=64`,
  `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`,
  `forensic_rule_findings=2`, `forensic_severity_counts={"high":1,"medium":1}`,
  target-pressure `pass=64`, table-intent `pass=64`, action findings `0`,
  replay-decision findings `0`, and `test_results_status_counts={"pass":18}`.
- PG-016 anti-combat package artifacts appeared externally:
  `anti_combat_candidate_rules_pg016_*_20260621_011500.*`,
  `battle_card_rules_sqlite_from_pg_pg016_anti_combat_20260621_012400.json`,
  and `card_metadata_sqlite_from_pg_pg016_anti_combat_20260621_012400.json`.
  Read-only postcheck verified five curated executable rows for `Norn's Annex`,
  `Windborn Muse`, `Silent Arbiter`, `Ensnaring Bridge`, and
  `Magus of the Moat`; the sync report shows `apply_pg=false`,
  `apply_sqlite_from_pg=true`, `pg_rows_loaded=1808`, and
  `sqlite_inserted_or_updated=2400`.
- PG-017 Arcane Epiphany package artifacts appeared externally:
  `arcane_epiphany_battle_rule_pg017_*_20260621_004200.*` and
  `battle_card_rules_sqlite_from_pg_pg017_arcane_epiphany_20260621_004400.json`.
  Read-only postcheck verified one curated executable `draw_cards` row for
  `Arcane Epiphany`; the sync report shows `apply_pg=false`,
  `apply_sqlite_from_pg=true`, `pg_rows_loaded=1809`, and
  `sqlite_inserted_or_updated=1776`.
- The `010452` blocker was opponent forensic lineage for `Jin-Gitaxias, Core
  Augur` from `functional_tags_json`, seed `63212362`, turn `8`, effect
  `draw_cards`.
- During this heartbeat, PG-018 opponent forensic artifacts appeared
  externally:
  `opponent_forensic_rules_pg018_*_20260621_011600.*` and
  `battle_card_rules_sqlite_from_pg_pg018_opponent_forensic_20260621_011800.json`.
  The package scope is `Jin-Gitaxias, Core Augur` and
  `Chandra, Flameshaper`.
- Read-only PG-018 postcheck returned `card_rows=2`,
  `curated_executable_rows=2`, and `function_tag_rows=2`. PostgreSQL rules are
  curated/verified/auto with reviewed_by `codex_central_auditor_pg018` at
  `2026-06-21 01:17:38.985265+00`; local Hermes SQLite
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` also selects
  both PG-018 rows.
- A new battle runner was active after PG-018 sync:
  `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310`.

Current conclusion:

- PG-016, PG-017, and PG-018 are externally applied/synced and postchecked by
  read-only evidence; this heartbeat did not execute any apply command and must
  not reapply them.
- The active `010452` battle blocker is now expected to be superseded by the
  in-progress post-PG018 battle rerun, but no newer completed summary had been
  observed at this checkpoint.
- Lorehold Deck 6 learned-deck coherence remains clean; current open risk is
  battle/auditor validation drift, not a Lorehold decklist coherence issue.

## Latest Battle/PG Drift Reading - 2026-06-20 22:44 -0300

Scope:

- Re-read `git status --short --branch`, the central/Lorehold registers, the
  newest learned-deck coherence artifact, the latest battle summary, and new
  PG-019 artifacts.
- No PostgreSQL apply, deck swap, cleanup, stash, revert, stage, commit, push,
  app/backend code edit, live app route call, or OpenAI call was performed by
  this heartbeat.

Evidence:

- `git status --short --branch` returned branch `master...origin/master`.
  Compared with the previous checkpoint, a tracked test file
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`
  is now modified, and PG-019 package/sync artifacts are untracked.
- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_233027.json`.
  Lorehold `learned_deck:82` still reports `issues=[]`,
  `parsed_quantity=100`, `resolved_quantity=100`, `unresolved=[]`, no
  off-color candidates, and no partner/background identity issue.
- Latest completed battle summary advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_012833/summary.json`.
  It reports `invocation_kind=codex_pg018_full64_real_deck_baseline`,
  `seeds_requested=64`, `seeds_completed=64`,
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["strategy_audit=review_required"]`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`,
  `forensic_severity_counts={}`, target-pressure `pass=64`, table-intent
  `pass=64`, action findings `0`, replay-decision findings `0`, and
  `test_results_status_counts={"pass":18}`.
- The strategy audit has `strategy_findings=17`,
  `strategy_low_confidence_findings=16`, and
  `strategy_review_required_findings=1`.
- The single review-required finding is seed `63212362`,
  `wheel_opponent_refill_risk`, decision `decision-000141`, detail
  `Wheel may refill opponents without a recorded payoff.`
- PG-019 artifacts appeared externally:
  `jin_gitaxias_non_wheel_pg019_*_20260621_013900.sql`,
  `jin_gitaxias_non_wheel_pg019_package_20260621_013900.md`, and
  `battle_card_rules_sqlite_from_pg_pg019_jin_non_wheel_20260621_014100.json`.
- PG-019 package scope: correct `Jin-Gitaxias, Core Augur` so its draw seven
  proxy is not treated as a multiplayer wheel.
- Read-only PG-019 postcheck returned `Jin-Gitaxias, Core Augur` with
  logical key `battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e`,
  `effect=draw_cards`, `draw_count=7`, `wheel_like=false`,
  `review_status=verified`, `execution_status=auto`, reviewed by
  `codex_central_auditor_pg019` at `2026-06-21 01:40:25.910763+00`.
- PG-019 sync report shows `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`, and
  `selected_cards=["Jin-Gitaxias, Core Augur"]`. Local Hermes SQLite selects
  the same `wheel_like=false` row.
- A post-PG019 runner was active:
  `manaloom-battle-strategy-audit.sh --seeds 64 --start-seed 63212310`.

Current conclusion:

- PG-018 battle-forensic closure is validated by `012833`: forensic findings
  are now zero and the only mandatory divergence moved to strategy audit.
- PG-019 is externally applied/synced and postchecked for PostgreSQL/cache
  state; this heartbeat did not execute the apply/sync command and must not
  reapply it.
- PG-019 battle closure is pending the active post-PG019 64-seed rerun.
- Lorehold Deck 6 learned-deck coherence remains clean. The current latest
  drift is battle strategy-audit semantics around opponent `Jin-Gitaxias`, not
  a Lorehold decklist coherence failure.

## Latest Battle/Local Hermes Apply Reading - 2026-06-20 23:14 -0300

Scope:

- Re-read `git status --short --branch`, central/Lorehold registers, latest
  learned-deck coherence artifact, latest battle summary, and new
  `master_optimizer_apply` artifacts.
- No PostgreSQL apply, deck swap command, cleanup, stash, revert, stage,
  commit, push, app/backend code edit, live app route call, or OpenAI call was
  performed by this heartbeat.

Evidence:

- Latest learned-deck coherence artifact remains
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_233027.json`.
  No newer learned-deck artifact was present.
- New untracked local optimizer artifacts appeared:
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_apply_20260621_020406.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260621T020406839706+0000.json`.
- The apply artifact records a local Hermes SQLite deck change for `deck_id=6`:
  `Windborn Muse` over `Guttersnipe`, `confirmation_wr=6.2%`,
  `confirmation_delta=+3.1pp`, `deck_cards_after=100`, `lands_after=33`,
  and `avg_cmc_after=2.567`.
- The same artifact explicitly states: `No production database was mutated.
  This applies only to the Hermes local SQLite knowledge deck.`
- Local Hermes SQLite verification:
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` has
  `deck_cards` `deck_id=6` with `Windborn Muse=1`, no `Guttersnipe`, and
  `100/100` cards.
- PostgreSQL read-only verification for materialized deck
  `528c877f-f829-4207-95e6-73981776c323` still has `Guttersnipe=1`, no
  `Windborn Muse`, and `100/100` cards.
- Latest completed battle summary advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020427/summary.json`.
  It reports `run_scope=recurring_full`,
  `invocation_kind=codex_pg019_post_apply_windborn_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`, forensic findings `0`,
  target-pressure `pass=16`, table-intent `pass=16`, action findings `0`,
  replay-decision findings `0`, tests `18/18`,
  `strategy_findings=5`, `strategy_low_confidence_findings=5`, and
  `strategy_review_required_findings=0`.
- A newer battle directory `20260621_020729` existed but had no `summary.json`
  at this checkpoint; a 64-seed runner was still active.

Current conclusion:

- PG-019 battle closure is validated for the completed 16-seed latest
  `020427`, but a 64-seed post-local-apply runner is still in progress.
- The local Hermes Windborn-over-Guttersnipe apply is real evidence, but it is
  not a PostgreSQL/learned-deck apply. It must not be promoted to PostgreSQL or
  treated as a user-approved deck swap without explicit approval.
- Current product/canonical PostgreSQL Lorehold deck still contains
  `Guttersnipe`; current Hermes runtime deck contains `Windborn Muse`.

### 64-Seed Reconciliation - 2026-06-20 23:14 -0300

- During final recheck, `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/summary.json`.
- `invocation_kind=codex_pg019_post_apply_windborn_64`,
  `seeds_requested=64`, `seeds_completed=64`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`, and
  `mandatory_gate_divergences=[]`.
- Mandatory gates remain clean: forensic findings `0`, target-pressure
  `pass=64`, table-intent `pass=64`, action findings `0`, replay-decision
  findings `0`, tests `18/18`, and `strategy_review_required_findings=0`.
- No active `manaloom-battle-strategy-audit.sh` runner remained in the final
  `ps` check.

## Canonical PG-020 Windborn Apply - 2026-06-20 23:40 -0300

Scope:

- Promoted `Windborn Muse` over `Guttersnipe` from validated Hermes runtime
  evidence to the PostgreSQL materialized Lorehold deck, then synced PostgreSQL
  back to Hermes and re-ran battle validation.

Evidence:

- PG package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_windborn_deck_swap_pg020_package_20260621_022046.md`.
- PG precheck: `ready_to_apply=true` for deck
  `528c877f-f829-4207-95e6-73981776c323`.
- PG apply: `Guttersnipe=0`, `Windborn Muse=1`, `total_quantity=100`.
- PG postcheck: `postcheck_passed=true`, `backup_rows=1`,
  `deck_rows=100`, `deck_quantity=100`.
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg020_windborn_20260621_022046.json`.
- Post-sync 64-seed battle:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022700/summary.json`,
  `4/64 = 6.25%`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`.

Current order:

- Treat PG-020 as applied and validated.
- Do not reapply PG-020.
- Continue deck correction from the post-PG baseline, focusing on
  survivability and `forced_keep_after_bad_mulligan`, not on Guttersnipe or
  payoff restoration.

## Post-PG020 Learned-Deck Recheck - 2026-06-20 23:45 -0300

Scope:

- Observed and verified PG-020 as already applied, then reran the learned-deck
  coherence audit in read-only mode.
- No PostgreSQL apply, deck swap command, cleanup, stash, revert, stage,
  commit, push, app/backend code edit, live app route call, or OpenAI call was
  performed by this heartbeat.

Evidence:

- Read-only PG-020 postcheck returned `postcheck_passed=true`,
  `deck_rows=100`, `deck_quantity=100`, `Guttersnipe=0`,
  `Windborn Muse=1`, and `backup_rows=1`.
- Local Hermes SQLite `deck_id=6` also has `Windborn Muse=1`,
  no `Guttersnipe`, and `100/100` cards.
- Fresh read-only learned-deck coherence artifacts:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260621_024551.json`
  and `.md`.
- Global learned-deck result remains high-clean:
  `active_learned_decks=60`, `severity_counts={"medium":13}`.
- Lorehold `learned_deck:82` remains shape-clean:
  `issues=[]`, `parsed_quantity=100`, `resolved_quantity=100`,
  `unresolved=[]`, no off-color candidates, no partner/background identity
  finding, and no premium Mox violations.
- New post-PG020 name drift is real:
  active learned deck vs SQLite is missing `Guttersnipe` and
  `Monument to Endurance`, while SQLite has extra `Silent Arbiter` and
  `Windborn Muse`; active learned deck vs PostgreSQL is missing `Guttersnipe`,
  while PostgreSQL has extra `Windborn Muse`.
- Lorehold strategy package still has the medium
  `lorehold_strategy_big_spell_finishers_gap` (`2/4` big finishers).
- Latest battle at this checkpoint is
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024220/summary.json`,
  `invocation_kind=codex_pg020_candidate_ensnaring_bridge_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package was found for the Ensnaring Bridge candidate in
  `master_optimizer_reports`; it is battle-candidate evidence only.
- A newer run directory `20260621_024527` existed without `summary.json`, and a
  16-seed runner was still active.

Current order:

- Treat PG-020 as applied/postchecked/synced and battle-trusted.
- Keep the active learned-deck name drift as an open governance item; do not
  mutate the active learned deck or apply any further deck swap without explicit
  approval.
- Treat Ensnaring Bridge over Monument to Endurance as candidate-only until a
  package/precheck/postcheck or explicit command appears.

### Candidate Silent Arbiter Reconciliation - 2026-06-20 23:45 -0300

- Final recheck advanced `latest` to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024527/summary.json`.
- `invocation_kind=codex_pg020_candidate_silent_arbiter_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package was found for `Silent Arbiter` over `Monument to Endurance`.
- Local Hermes SQLite `deck_id=6` still only shows `Windborn Muse` among the
  checked candidate cards; no `Silent Arbiter`, `Ensnaring Bridge`, or
  `Monument to Endurance` row was present in that focused check.
- A newer run directory `20260621_024906` existed without a reconciled summary
  in this checkpoint, and a 16-seed runner was active.

### Candidate Norn's Annex Reconciliation - 2026-06-20 23:49 -0300

- Final heartbeat recheck advanced `latest` to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_024906/summary.json`.
- `invocation_kind=codex_pg020_candidate_norns_annex_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, target-pressure
  `pass=16`, table-intent `pass=16`, tests `18/18`, and
  `strategy_review_required_findings=0`.
- No PG package or artifact was found for `Norn's Annex`/`PG021`/`024906` in
  `docs/hermes-analysis/master_optimizer_reports`.
- A new 16-seed battle runner remained active after this summary:
  PID `3395`, `--start-seed 63212310`.

Current order:

- Keep PG-020 closed and canonical unless a later SELECT, sync report, or battle
  artifact proves rollback/drift.
- Treat Norn's Annex over Monument to Endurance as battle-candidate evidence
  only; no PostgreSQL apply or deck swap is authorized from this checkpoint.

### Candidate Magus of the Moat Review Blocker - 2026-06-20 23:52 -0300

- A later completed run advanced `latest` to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_025233/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_16`,
  `seeds_requested=16`, `seeds_completed=16`, but
  `battle_replay_final_status=review_required`.
- Mandatory divergences are
  `["forensic_audit=review_required", "replay_decision_audit=review_required"]`.
- The only concrete finding is low-severity and localized:
  seed `63212318`, turn `12`, event `board_wipe_resolved`,
  `Board wipe left more protected creatures (9) than destroyed (7).`
- Counters remain clean elsewhere: forensic rule findings `0`,
  replay decision findings `0`, target-pressure `pass=16`, table-intent
  `pass=16`, tests `18/18`, strategy review-required findings `0`.
- No PG package was found for `Magus of the Moat`/`PG021`/`025233`.

Current order:

- Treat Magus of the Moat over Monument to Endurance as blocked candidate
  evidence, not promotion evidence.
- Do not mutate PostgreSQL, apply a deck swap, or promote strategy learning from
  this run until the board-wipe/protection replay finding is reviewed or a clean
  rerun supersedes it.

### Magus 64-Seed Superseding Recheck - 2026-06-21 00:17 -0300

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_030022/summary.json`.
- `invocation_kind=codex_pg020_candidate_magus_moat_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=review_required`.
- Mandatory divergences remain
  `["forensic_audit=review_required", "replay_decision_audit=review_required"]`.
- The concrete blocker is unchanged from the 16-seed run: seed `63212318`,
  turn `12`, event `board_wipe_resolved`, low severity,
  `Board wipe left more protected creatures (9) than destroyed (7).`
- Clean surrounding counters: forensic rule findings `0`, replay decision
  findings `0`, target-pressure `pass=64`, table-intent `pass=64`, tests
  `18/18`, and strategy review-required findings `0`.
- Battle strategy signal remains poor: target wins `9`, opponent wins `54`,
  opponent combat to target `883`, opponent combat to other `21`, and
  `forced_keep_after_bad_mulligan=14`.
- No PG package was found for `Magus of the Moat`/`PG021`/`030022`.
- Fresh read-only learned-deck coherence artifacts were generated:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260621_031653.json`
  and `.md`.
- The new audit remains globally unchanged at `active_learned_decks=60` and
  `severity_counts={"medium":13}`; Lorehold `learned_deck:82` remains
  structurally clean (`issues=[]`, `parsed_quantity=100`,
  `resolved_quantity=100`, `unresolved=[]`) but still has active-vs-runtime
  drift and the medium `lorehold_strategy_big_spell_finishers_gap`.

Current order:

- Keep PG-020 closed and canonical; this checkpoint found no PG rollback/drift
  evidence.
- Treat Magus of the Moat over Monument to Endurance as blocked candidate-only
  evidence until the board-wipe/protection replay finding is reviewed or
  superseded by a clean rerun.
- Do not apply PostgreSQL, apply deck swaps, or mutate active learned decks
  without explicit command approval.

### Corrected Magus Candidate Clean Recheck - 2026-06-21 00:18 -0300

- `latest` then advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_031617/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_magus_moat_for_monument_16`,
  `run_scope=recurring_full`, `seeds_requested=16`, `seeds_completed=16`,
  and `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`,
  forensic rule findings `0`, forensic turn findings `0`, replay decision
  findings `0`, target-pressure `pass=16`, table-intent `pass=16`, and tests
  `18/18`.
- Strategy signal remains low-confidence rather than promotion-ready:
  target wins `2`, opponent wins `12`, opponent combat to target `215`,
  opponent combat to other `2`, `forced_keep_after_bad_mulligan=5`,
  high-confidence learning seeds `12`, low-confidence seeds `4`.
- No PG package was found for `Magus of the Moat`/`PG021`/`031617`.
- A new 16-seed runner remained active after this summary.

Current order:

- Treat the corrected Magus run as clean candidate evidence only.
- Do not apply PG021 or mutate the deck without an explicit approved
  precheck/apply/postcheck/rollback package and command.

### Corrected Silent Arbiter 64-Seed Recheck - 2026-06-21 00:52 -0300

- `latest` advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json`.
- `invocation_kind=codex_pg021_corrected_candidate_silent_arbiter_for_monument_64`,
  `run_scope=custom_multi_seed`, `seeds_requested=64`,
  `seeds_completed=64`, and
  `battle_replay_final_status=trusted_for_strategy_learning`.
- Mandatory gates are clean: `mandatory_gate_divergences=[]`, forensic rule
  findings `0`, forensic turn findings `0`, replay decision findings `0`,
  target-pressure `pass=64`, table-intent `pass=64`, and tests `18/18`.
- Strategy signal remains weak despite clean gates: target wins `8`, opponent
  wins `54`, opponent combat to target `1103`, opponent combat to other `14`,
  `forced_keep_after_bad_mulligan=15`, high-confidence learning seeds `51`,
  low-confidence seeds `13`.
- No PG package was found for `Silent Arbiter`/`PG021`/`032623`.
- A new battle runner remained active after this summary.

Current order:

- Treat the corrected Silent Arbiter 64-seed result as clean candidate evidence
  only.
- Do not apply PG021 or mutate the deck without an explicit approved
  precheck/apply/postcheck/rollback package and command.

### PG021/PG022 External Apply Observed - 2026-06-21 01:55 -0300

Scope:

- New PG021 and PG022 artifacts appeared under
  `docs/hermes-analysis/master_optimizer_reports/`.
- This heartbeat did not execute PG apply, deck swap, rollback, commit, push,
  cleanup, stash, or revert.
- The package markdown files still say `Status: planned`, but live read-only
  postchecks, PG -> Hermes sync, local SQLite, and post-sync battle artifacts
  prove that PG021/PG022 were applied externally before this checkpoint.

Evidence:

- PG021 read-only postcheck:
  `pg021_global_attack_rule_scope_postcheck`, `rule_rows=3`,
  `silent_global_ok=true`, `magus_global_ok=true`,
  `bridge_controller_hand_ok=true`, `postcheck_passed=true`.
- PG021 sync report:
  `battle_card_rules_sqlite_from_pg_pg021_global_attack_scope_20260621_043814.json`,
  `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `selected_cards=["Ensnaring Bridge","Magus of the Moat","Silent Arbiter"]`,
  `sqlite_inserted_or_updated=4`.
- PG022 read-only postcheck:
  `pg022_lorehold_silent_arbiter_postcheck`, `deck_rows=100`,
  `deck_quantity=100`, `Monument to Endurance=0`,
  `Silent Arbiter=1`, `silent_is_commander=false`, `backup_rows=1`,
  `postcheck_passed=true`.
- PG022 sync report:
  `sync_pg_target_deck_to_hermes_pg022_silent_arbiter_20260621_044155.json`,
  `apply=true`, `cards_written=100`, `quantity_written=100`,
  `duplicate_rows_collapsed=0`, `deck_hash=97d87629548e778b2e0d6c5f8925982e3742cc99a1c3dc85dd66c3a60faadc80`.
- Local Hermes SQLite `deck_id=6` now has `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Guttersnipe`, no `Monument to Endurance`, and
  `100/100` cards.
- Latest post-sync battle smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`,
  `invocation_kind=codex_pg022_post_pg_sync_silent_arbiter_16`,
  `seeds_completed=16`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, replay decision
  findings `0`, target-pressure `pass=16`, table-intent `pass=16`, tests
  `18/18`, target wins `3`, opponent wins `13`,
  `forced_keep_after_bad_mulligan=4`.
- Fresh read-only learned-deck coherence artifacts:
  `learned_deck_coherence_audit_20260621_045522.json` and `.md`.
- Learned-deck coherence remains globally unchanged:
  `active_learned_decks=60`, `severity_counts={"medium":13}`.
- Lorehold `learned_deck:82` remains structurally clean:
  `issues=[]`, `parsed_quantity=100`, `resolved_quantity=100`,
  `unresolved=[]`, no premium Mox, no off-color plan entries.
- Current active-vs-runtime drift after PG022:
  active learned deck is missing `Guttersnipe` and `Monument to Endurance`
  from both PG and SQLite, while PG/SQLite contain extra `Silent Arbiter` and
  `Windborn Muse`.
- Strategy package still has medium
  `lorehold_strategy_big_spell_finishers_gap` (`2/4` big finishers).

Current order:

- Treat PG021 and PG022 as applied, postchecked, synced, smoke-validated, and
  full 64-seed battle-validated.
- Do not reapply PG021/PG022.
- Keep the active learned-deck drift open as a governance item; do not mutate
  active learned decks without explicit approval.
- Use full post-PG022 summary
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`
  as the current canonical battle artifact: `8/64`, trusted, clean gates,
  `forced_keep_after_bad_mulligan=15`.
- Next work order: investigate and fix mulligan/curve/consistency before
  testing more blind anti-combat swaps.

### Post-PG022 Candidate Scan Sequence - 2026-06-21 02:27 -0300

Scope:

- New battle-strategy audit summaries appeared after the PG022 full validation.
- This heartbeat did not execute PostgreSQL apply, deck swap, rollback, commit,
  push, cleanup, stash, or revert.
- Local Hermes SQLite was checked after the latest temporary candidate runner:
  `deck_id=6` still has `Generous Gift=1` and no `Brainstone`,
  `Artist's Talent`, or `Reprieve` candidate persisted.

Evidence:

- PG022 validation artifact:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_deck6_pg022_silent_arbiter_validation_20260621_044758.md`.
  It preserves the canonical proof that PG022 moved Lorehold from `4/64` to
  `8/64`, with clean gates and `Silent Arbiter=1`,
  `Monument to Endurance=0`, `Windborn Muse=1`, `Guttersnipe=0`, `100/100`.
- Candidate sequence after PG022:
  - `20260621_050651`: `manual_cli`, `recurring_16_seed`, `3/16`,
    `blocked`, `strategy_audit=blocked`.
  - `20260621_051246`: `candidate_brainstone_for_generous_gift_16`, `4/16`,
    `blocked`, `forensic_audit=blocked`.
  - `20260621_051800`:
    `candidate_brainstone_for_generous_gift_16_after_forensic_fix`, `4/16`,
    `trusted_for_strategy_learning`, clean mandatory gates.
  - `20260621_052117`: `candidate_artists_talent_for_generous_gift_16`,
    `3/16`, `trusted_for_strategy_learning`, clean mandatory gates.
  - Latest `20260621_052416`: `candidate_reprieve_for_generous_gift_16`,
    `5/16`, `review_required`, `strategy_audit=review_required`,
    `forced_keep_after_bad_mulligan=5`, `wheel_opponent_refill_risk=1`.
- Latest learned-deck coherence remains
  `learned_deck_coherence_audit_20260621_045522.json`: read-only,
  `active_learned_decks=60`, `severity_counts={"medium":13}`; Lorehold
  active row is shape-clean but still drifts from PG/SQLite by
  `Guttersnipe`/`Monument to Endurance` versus `Silent Arbiter`/`Windborn Muse`.

Current order:

- Do not promote Brainstone, Artist's Talent, or Reprieve without an explicit
  PostgreSQL package and approval.
- Treat Reprieve as blocked candidate evidence until the strategy-audit review
  gate is resolved or the candidate is superseded.
- Keep active learned-deck mutation blocked until explicit approval.

### Post-Engine-Fix Candidate Sequence - 2026-06-21 03:06 -0300

Scope:

- The battle-strategy `latest` advanced after the prior Reprieve
  review-required checkpoint.
- This heartbeat did not execute PostgreSQL apply, deck swap, rollback, commit,
  push, cleanup, stash, or revert.
- No active `manaloom-battle-strategy-audit.sh` runner remained after the read.

Evidence:

- Latest learned-deck coherence artifact is unchanged:
  `learned_deck_coherence_audit_20260621_045522.json`; no new learned audit
  appeared.
- New battle sequence:
  - `20260621_053446`: `codex_candidate_scan`, `4/16`,
    `trusted_for_strategy_learning`, clean mandatory gates.
  - `20260621_053937`: `codex_baseline_after_engine_fix`, `3/16`,
    `trusted_for_strategy_learning`, clean mandatory gates.
  - `20260621_054357`: `codex_candidate_scan_after_engine_fix`, `4/16`,
    `trusted_for_strategy_learning`, clean mandatory gates,
    `forced_keep_after_bad_mulligan=2`.
  - Latest `20260621_054803`: `codex_candidate_combo_scan`, `1/16`,
    `trusted_for_strategy_learning`, clean mandatory gates,
    `forced_keep_after_bad_mulligan=7`.
- Latest artifact details:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_054803/summary.json`,
  `seeds_completed=16/16`, `mandatory_gate_divergences=[]`,
  forensic findings `0`, replay decision findings `0`,
  target-pressure `pass=16`, table-intent `pass=16`, tests `18/18`,
  learning-eligible seeds `10`, low-confidence seeds `6`.
- Local Hermes SQLite focused check stayed coherent at `100/100`; known
  current rows include `Generous Gift=1`, `Boros Charm=1`,
  `Teferi's Protection=1`, `Silence=1`, and `Orim's Chant=1`.
- New tracked test change observed outside this heartbeat:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
  now includes coverage that the player does not cast `Teferi's Protection`
  against its own wheel payoff.

Current order:

- Treat `054803` as gate-clean but strategically worse candidate evidence, not
  a promotion signal.
- Do not create or apply PostgreSQL packages from this sequence without an
  explicit command approval.
- Continue prioritizing consistency/mulligan investigation and active
  learned-deck governance drift.

### Aborted Runner Artifact - 2026-06-21 04:48 -0300

Scope:

- A newer run directory appeared after `054803`:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_060733/`.
- `latest` still points to `20260621_054803`; `060733` has no `summary.json`.
- This heartbeat did not execute PostgreSQL apply, deck swap, rollback, commit,
  push, cleanup, stash, or revert.

Evidence:

- `060733/test_results.jsonl` records `py_compile=pass`, then
  `test_battle_analyst_v10_3` failed after `963s`.
- Failure:
  `psycopg2.OperationalError: server closed the connection unexpectedly`
  while `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` opened
  `sync_pg.connect()` in `setUp`.
- Live follow-up check used `PGOPTIONS='-c default_transaction_read_only=on'`
  and returned `pg_select_1=1`.
- Latest learned-deck coherence remains unchanged at
  `learned_deck_coherence_audit_20260621_045522.json`.

Current order:

- Treat `060733` as an aborted runner/infrastructure artifact, not as a battle
  strategy result and not as PG rollback/drift evidence.
- Keep `054803` as the latest completed battle artifact until a newer
  `latest/summary.json` is published.

### Latest Manual 64-Seed Rerun - 2026-06-21 05:17 -0300

Scope:

- A newer completed `latest/summary.json` was published after the aborted
  `060733` artifact.
- This heartbeat did not execute PostgreSQL apply, deck swap, rollback, commit,
  push, cleanup, stash, or revert.
- No active battle runner remained after the read.

Evidence:

- Latest battle summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json`.
- `run_profile=custom_64_seed`, `invocation_kind=manual_cli`,
  `run_scope=custom_multi_seed`, `seeds_completed=64/64`.
- Status: `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, forensic findings `0`, replay decision
  findings `0`, target-pressure `pass=64`, table-intent `pass=64`, tests
  `18/18`.
- Strategy signal: Lorehold wins `14/64`, opponents win `49/64`,
  opponent combat to Lorehold `1050`, opponent combat to others `46`,
  `forced_keep_after_bad_mulligan=13`, high-confidence learning seeds `54`,
  low-confidence seeds `10`.
- Local Hermes SQLite focused check still shows canonical PG022 deck shape:
  `Silent Arbiter=1`, `Windborn Muse=1`, `Generous Gift=1`, `100/100`, with
  no `Guttersnipe` or `Monument to Endurance` row returned by the focused
  check.
- Latest learned-deck coherence artifact remains
  `learned_deck_coherence_audit_20260621_045522.json`; no new learned audit
  appeared.

Current order:

- Treat `080706` as the latest completed battle evidence and as a better
  current 64-seed signal than the prior PG022 `8/64` validation.
- Do not treat it as a PostgreSQL deploy authorization; no package or approved
  apply command exists from this heartbeat.
- Keep active learned-deck drift open until explicit mutation approval.

### PG023 Prepared, Not Applied - 2026-06-21 05:17 -0300

Scope:

- New PG023 package artifacts appeared under
  `docs/hermes-analysis/master_optimizer_reports/`.
- This heartbeat did not execute PG023 precheck, apply, postcheck, rollback,
  deck sync, battle-rule sync, commit, push, cleanup, stash, or revert.

Evidence:

- Package:
  `lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md`.
- Status in package: `prepared`.
- Proposed swap: add `Brainstone`; cut `Generous Gift`; target PostgreSQL deck
  `528c877f-f829-4207-95e6-73981776c323`.
- Evidence claimed by package: baseline PG022 `8/64` versus Brainstone over
  Generous Gift `14/64`, net `+6` Lorehold wins over 64 seeds.
- Required package files present: precheck, apply, postcheck, rollback.
- Local Hermes SQLite focused check still shows `Generous Gift=1` and no
  `Brainstone` row for `deck_id=6`, so PG023 is not reflected in local runtime.

Current order:

- Treat PG023 as prepared but not approved/applied.
- Do not run PG023 apply without explicit approval of the exact command.
- If approved later, require precheck, apply, postcheck, PG -> Hermes deck sync,
  battle-rule sync for Brainstone, and fresh 16/64 battle reruns.

### PG023 External Closure Evidence - 2026-06-21 10:07 -0300

Scope:

- The earlier prepared-only PG023 reading is now superseded by newer artifact
  and live-state evidence.
- This heartbeat did not execute PG023 precheck, apply, rollback, deck swap,
  commit, push, cleanup, stash, or revert.
- The only PostgreSQL command executed by this heartbeat was the PG023
  postcheck SQL under `PGOPTIONS='-c default_transaction_read_only=on'`.

Evidence:

- Package
  `lorehold_brainstone_deck_swap_pg023_package_20260621_114447.md` now reports
  `Status: applied_and_postchecked_and_battle_validated`.
- Read-only PostgreSQL postcheck returned:
  `deck_rows=100`, `deck_quantity=100`, `gift_rows=0`,
  `brainstone_rows=1`, `brainstone_is_commander=false`,
  `deck_backup_rows=1`, `rule_backup_rows=1`,
  `brainstone_rule_verified=true`, `postcheck_passed=true`.
- PG -> Hermes deck sync artifact
  `sync_pg_target_deck_to_hermes_pg023_brainstone_20260621_114447.json`
  reports `apply=true`, `cards_written=100`, `quantity_written=100`,
  `deck_hash=c160e490b9e887d7b1f15ca6557be97d59b5aaff60bdee926805fd36359a6cbf`,
  and `target_deck_id=6`.
- PG -> Hermes battle-rule sync artifact
  `battle_card_rules_sqlite_from_pg_pg023_brainstone_20260621_114447.json`
  reports `apply_pg=false`, `apply_sqlite_from_pg=true`,
  `pg_rows_loaded=5244`, `sqlite_inserted_or_updated=5211`.
- Current local SQLite focused check returns `Brainstone=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, and no `Generous Gift` row for
  `deck_id=6`.
- Post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_121648/summary.json`,
  `4/16`, trusted, clean gates.
- Post-sync full validation:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`,
  `custom_64_seed`, `manual_cli`, `64/64`,
  `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  target-pressure `pass=64`, table-intent `pass=64`, tests `18/18`,
  Lorehold wins `14/64`, opponents win `49/64`,
  `forced_keep_after_bad_mulligan=13`.
- Fresh learned-deck coherence audit
  `learned_deck_coherence_audit_20260621_130957.json` keeps aggregate
  `medium=13` and Lorehold `issues=[]`, but now reports active learned-vs-
  runtime name drift of active-only `Generous Gift`, `Guttersnipe`,
  `Monument to Endurance` versus runtime-only `Brainstone`, `Silent Arbiter`,
  `Windborn Muse`.

Current order:

- Treat PG023 as externally applied, postchecked, synced, and battle-validated;
  do not reapply it.
- Keep PG023 closed unless a future read-only postcheck, sync report, or battle
  artifact proves rollback/drift.
- Active learned-deck mutation remains blocked without explicit approval; the
  live governance drift is now three cards, not two.
- Continue prioritizing Lorehold consistency/mulligan work because
  `forced_keep_after_bad_mulligan=13` remains in the full post-sync battle.

### Temporary Expedition Map Candidate Runner - 2026-06-21 10:15 -0300

Scope:

- A new external runner started while this heartbeat was closing PG023
  documentation.
- Process command observed a temporary SQLite candidate: delete
  `Electroduplicate`, insert `Expedition Map`, run 16 seeds, then restore
  `knowledge.db` from a `mktemp` backup via shell trap.
- This heartbeat did not start, stop, alter, apply, rollback, commit, push,
  cleanup, stash, or revert that runner.

Evidence:

- New latest:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131126/summary.json`.
- Summary fields: `run_profile=recurring_16_seed`,
  `invocation_kind=manual_cli`, `seeds_completed=16/16`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal is poor: Lorehold wins `1/16`, opponents win `14/16`,
  `forced_keep_after_bad_mulligan=3`, high-confidence seeds `14`,
  low-confidence seeds `2`.
- After runner exit, local SQLite persistent state is restored:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Expedition Map`, no `Generous Gift`, and `100/100`
  deck quantity.

Current order:

- Treat `131126` as gate-clean but strategically poor temporary candidate
  evidence, not a promotion signal.
- Keep PG023 closed; this candidate did not create a PostgreSQL package or an
  authorized deck mutation.

### Latest PG023 Recurring Smoke - 2026-06-21 10:20 -0300

Scope:

- Another external 16-seed run completed after the temporary Expedition Map
  candidate.
- This heartbeat did not start, stop, apply, rollback, swap, commit, push,
  cleanup, stash, or revert this run.

Evidence:

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131606/summary.json`.
- `run_profile=recurring_16_seed`, `run_scope=recurring_full`,
  `invocation_kind=manual_cli`, `seeds_completed=16/16`.
- Status: `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `3/16`, opponents win `13/16`,
  opponent combat to Lorehold `268`, opponent combat to others `3`,
  `forced_keep_after_bad_mulligan=5`, high-confidence seeds `12`,
  low-confidence seeds `4`.
- Persistent SQLite remains PG023-shaped after the run:
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`,
  `Windborn Muse=1`, no `Generous Gift`, no `Expedition Map`, `100/100`.

Current order:

- Treat `131606` as the latest gate-clean recurring smoke on PG023 runtime.
- PG023 remains closed; Lorehold still needs consistency/mulligan work and
  active learned-deck governance drift remains blocked without approval.

### Temporary Thrill Candidate Latest - 2026-06-21 10:25 -0300

Scope:

- A final external 16-seed runner completed after `131606`.
- Process command observed a temporary SQLite candidate: delete `Boros Charm`,
  insert `Thrill of Possibility`, run 16 seeds, then restore `knowledge.db`
  from a `mktemp` backup via shell trap.
- This heartbeat did not start, stop, apply, rollback, swap, commit, push,
  cleanup, stash, or revert this run.

Evidence:

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132027/summary.json`.
- `run_profile=recurring_16_seed`, `run_scope=recurring_full`,
  `invocation_kind=manual_cli`, `seeds_completed=16/16`.
- Status: `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `2/16`, opponents win `13/16`,
  `forced_keep_after_bad_mulligan=4`.
- After runner exit, local SQLite persistent state is restored:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, no `Thrill of Possibility`, and
  `100/100` deck quantity.

Current order:

- Treat `132027` as gate-clean but poor temporary candidate evidence, not a
  promotion signal.
- PG023 remains closed; active learned-deck drift and consistency/mulligan work
  remain the active Lorehold items.

### Active Temporary Reprieve Runner - 2026-06-21 10:26 -0300

Scope:

- A new external candidate runner started after `132027` and is still in
  progress at this checkpoint.
- Process command observed temporary SQLite mutation: delete `Boros Charm`,
  insert `Reprieve`, run 16 seeds, then restore `knowledge.db` from a `mktemp`
  backup via shell trap.
- This heartbeat did not start, stop, apply, rollback, swap, commit, push,
  cleanup, stash, or revert this runner.

Evidence:

- Active process: `manaloom-battle-strategy-audit.sh --seeds 16 --start-seed 63212310`
  under the `candidate_reprieve_for_boros_charm_16` shell command.
- Active run directory:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/`.
- At the final checkpoint it had at least `9` seed directories and no completed
  summary was read yet.
- Current SQLite is temporary while the process runs: `Reprieve=1`, no
  `Boros Charm`, with `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, `Windborn Muse=1`, `100/100`.

Current order:

- Do not classify persistent runtime from SQLite until this runner exits and
  its trap restores the DB.
- Keep latest completed summary as `20260621_132027` until `132537` publishes
  `summary.json`.

### Temporary Reprieve Candidate Completed - 2026-06-21 10:30 -0300

Scope:

- Rechecked the previously active `candidate_reprieve_for_boros_charm_16`
  runner.
- This heartbeat did not start, stop, apply, rollback, swap, commit, push,
  cleanup, stash, or revert this run.

Evidence:

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json`.
- `run_profile=recurring_16_seed`, `run_scope=recurring_full`,
  `invocation_kind=manual_cli`, `seeds_completed=16/16`.
- Status: `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure `pass=16`,
  table-intent `pass=16`, tests `18/18`.
- Strategy signal: Lorehold wins `4/16`, opponents win `12/16`,
  opponent combat to Lorehold `267`, opponent combat to others `4`,
  `forced_keep_after_bad_mulligan=5`, high-confidence seeds `12`,
  low-confidence seeds `4`.
- SQLite restored after the runner: `Boros Charm=1`, `Brainstone=1`,
  `Electroduplicate=1`, `Silent Arbiter=1`, `Windborn Muse=1`,
  no `Reprieve`, no `Generous Gift`, `100/100`.
- Latest learned-deck coherence remains
  `learned_deck_coherence_audit_20260621_130957.json`: aggregate
  `medium=13`, Lorehold active learned-vs-runtime drift remains
  active-only `Generous Gift`/`Guttersnipe`/`Monument to Endurance` versus
  runtime-only `Brainstone`/`Silent Arbiter`/`Windborn Muse`.

Current order:

- Treat `132537` as latest gate-clean but temporary candidate evidence, not a
  promotion signal.
- PG023 remains closed; do not reapply it.
- Active learned-deck drift and consistency/mulligan remain the open Lorehold
  work items.

### PG023 Candidate Scan Artifact - 2026-06-21 10:30 -0300

Scope:

- New repo artifact appeared:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_pg023_candidate_scan_20260621_132537.md`.
- This heartbeat did not execute PostgreSQL apply, rollback, deck swap, commit,
  push, cleanup, stash, or revert.

Evidence:

- Artifact status: `no_promotion`.
- It classifies all four latest 16-seed runs as temporary SQLite candidates,
  each restored after the run:
  `Expedition Map` over `Electroduplicate` (`131126`, `1/16`),
  `Reforge the Soul` over `Boros Charm` (`131606`, `3/16`),
  `Thrill of Possibility` over `Boros Charm` (`132027`, `2/16`), and
  `Reprieve` over `Boros Charm` (`132537`, `4/16`).
- This supersedes the earlier local label that treated `131606` as a generic
  PG023 recurring smoke. It was candidate evidence, not canonical smoke.
- Artifact states no PostgreSQL apply was performed, no package was generated,
  and local SQLite restored to PG023 state.

Current order:

- Treat `132537` as current latest but rejected candidate evidence.
- Keep canonical PG023 validation anchored on full run `20260621_122732`
  (`14/64`, trusted, clean gates).
- Do not pursue simple land-tutor/generic cantrip substitutions from this
  sample without a seed-specific hypothesis.

### Learned Coherence Auditor Correction - 2026-06-21 11:03 -0300

Scope:

- `server/bin/learned_deck_coherence_audit.py` now evaluates the focused
  Lorehold strategy check from runtime truth when available:
  `pg_saved_deck` first, then `sqlite_deck`, then active learned deck.
- The stale `big_spell_finishers` requirement was replaced with
  `closing_conversion`; this keeps a finishing-line check without forcing old
  PG011-removed high-CMC finishers.
- No PostgreSQL apply, rollback, manual SQL write, deck swap, sync command,
  commit, push, cleanup, stash, revert, or file deletion was performed.

Evidence:

- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260621_133919.json`
  reports `strategy_source=pg_saved_deck`, `strategy_passed=true`, and
  `strategy_issues=[]`.
- Lorehold PG saved deck remains `100` rows / `100` quantity / `33` lands.
- `closing_conversion` has `7` present cards against minimum `4`.
- Focused code validation passed:
  `python3 -m py_compile server/bin/learned_deck_coherence_audit.py server/test/learned_deck_coherence_audit_test.py`
  and `python3 -m unittest server/test/learned_deck_coherence_audit_test.py`
  with `21` tests `OK`.

Current order:

- Treat the old Lorehold big-spell coherence finding as closed by auditor-rule
  correction, not by a deck swap.
- Keep active learned-source name lag open as source lag:
  active learned still differs from PG/SQLite by
  `Generous Gift`/`Guttersnipe`/`Monument to Endurance` versus
  `Brainstone`/`Silent Arbiter`/`Windborn Muse`.

### Focused Zone Transition Latest - 2026-06-21 11:03 -0300

Scope:

- Latest symlink now points to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_140346/summary.json`.
- This is a focused zone-transition run, not a post-apply full Lorehold deck
  validation.
- No PostgreSQL apply, rollback, manual SQL write, deck swap, sync command,
  commit, push, cleanup, stash, revert, or file deletion was performed.

Evidence:

- `run_profile=focused_zone_transition_fix_v3`,
  `run_scope=focused_seed`,
  `invocation_kind=codex_focused_zone_transition_fix_63212310_v3`,
  `seeds_completed=1/1`.
- Status: `trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`.
- Gate/test summary: `target_pressure_statuses={"pass":1}`,
  `table_intent_statuses={"pass":1}`,
  `test_results_status_counts={"pass":18}`.
- Strategy findings remain empty:
  `strategy_review_required_findings=0`, `strategy_code_counts={}`,
  `strategy_severity_counts={}`.
- Local SQLite deck `6`: `100` rows / `100` quantity; focused card check has
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Current order:

- Treat `140346` as focused runtime-support validation only.
- Keep canonical PG023 deck validation anchored on full run `20260621_122732`
  until a fresh post-sync/post-apply full run supersedes it.

### PG023 Combat-Survival Rebaseline - 2026-06-21 11:30 -0300

Scope:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_142400/summary.json`.
- This heartbeat did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap, sync command, commit, push, cleanup, stash, revert, or file
  deletion.
- This is PG023 16-seed rebaseline evidence after combat-survival runtime
  response, not a PostgreSQL deploy step.

Evidence:

- `run_profile=pg023_rebaseline_after_combat_survival_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_pg023_rebaseline_after_combat_survival_response`,
  `seeds_completed=16/16`.
- Status: `trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  test results `pass=18`.
- Strategy summary: `strategy_review_required_findings=0`,
  `strategy_code_counts={"forced_keep_after_bad_mulligan":2}`,
  `strategy_severity_counts={"medium":2}`.
- Outcome: Lorehold target wins `1/16`, opponents `15/16`; opponent combat to
  Lorehold `246`, to other players `2`.
- Local SQLite deck `6` remains `100` rows / `100` quantity and focused card
  check has `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Current order:

- Treat `142400` as gate-clean strategy evidence that the current PG023 deck
  still fails under combat pressure.
- Do not open a PostgreSQL apply/rollback item from this sample alone.
- Keep PG023 closed as deployed runtime shape; next viable work remains
  consistency/combat-survival/conversion analysis, not simple candidate
  promotion.

### PG023 Priority-Fix And Angel's Grace Candidate Sweep - 2026-06-21 12:04 -0300

Scope:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_145948/summary.json`.
- An external runner was active during the heartbeat; final runtime state was
  read only after it exited.
- No PostgreSQL apply, rollback, manual SQL write, deck swap, sync command,
  commit, push, cleanup, stash, revert, or file deletion was performed.

Evidence:

- `140846`: PG023 rebaseline after declared-target-controller/zone fix,
  trusted, clean gates, tests `pass=18`, Lorehold `2/16`,
  `forced_keep_after_bad_mulligan=2`.
- `141620`: PG023 rebaseline after reactive-hold fix, trusted, clean gates,
  tests `pass=18`, Lorehold `1/16`,
  `forced_keep_after_bad_mulligan=2`.
- `144336`: Angel's Grace over Boros Charm candidate before priority fix,
  `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`; do not use as
  strategy evidence.
- `145423`: PG023 rebaseline after cannot-lose priority fix, trusted, clean
  gates, tests `pass=18`, Lorehold `1/16`,
  `forced_keep_after_bad_mulligan=2`.
- `145948`: Angel's Grace over Boros Charm candidate after priority fix,
  trusted, clean gates, tests `pass=18`, Lorehold `2/16`, opponents `13/16`,
  `forced_keep_after_bad_mulligan=3`.
- SQLite restoration after runner: deck `6` is `100` rows / `100` quantity
  with `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Current order:

- Treat `145948` as latest gate-clean but rejected candidate evidence.
- Do not promote Angel's Grace over Boros Charm: it does not beat PG023 smoke
  baseline and worsens forced-keep signal versus `145423`.
- Do not open PostgreSQL apply/rollback from these runs. Continue with
  survival/conversion analysis under pressure.

### Latest Manual 16-Seed Review Checkpoint - 2026-06-21 12:35 -0300

Scope:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_151645/summary.json`.
- An external `manaloom-battle-strategy-audit.sh --seeds 16 --start-seed
  63212310` process was still active at read time.
- No PostgreSQL apply, rollback, manual SQL write, deck swap, sync command,
  commit, push, cleanup, stash, revert, file deletion, or runner termination
  was performed.

Evidence:

- `run_profile=recurring_16_seed`, `run_scope=recurring_full`,
  `invocation_kind=manual_cli`, `seeds_completed=16/16`.
- Status: `battle_replay_final_status=review_required`,
  `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`.
- Mandatory divergences:
  `["forensic_audit=review_required","replay_decision_audit=review_required","strategy_audit=review_required"]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy summary: `strategy_review_required_findings=4`,
  `forced_keep_after_bad_mulligan=4`,
  `resource_cost_without_selection_context=1`,
  `spending_unique_color_land=1`, `tutor_no_target=2`,
  severity `low=1`, `medium=7`.
- Outcome: Lorehold target wins `1/16`, opponents `12/16`; opponent combat to
  Lorehold `310`, to other players `8`.
- SQLite check at read time: deck `6` is `100` rows / `100` quantity with
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`,
  `Silent Arbiter=1`, and `Windborn Muse=1`.

Current order:

- Treat `151645` as latest review-required checkpoint, not trusted strategy
  evidence.
- Wait for the active runner to finish before making any final runtime-cache
  restoration claim.
- Keep PG023 closed unless future SELECT/sync/battle evidence proves rollback
  or drift. No apply/rollback is opened by this heartbeat.

### PG023 Oracle-Specific Finisher Contract Rebaseline - 2026-06-21 12:37 -0300

Scope:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_152154/summary.json`.
- No external runner was active at final read time.
- No PostgreSQL apply, rollback, manual SQL write, deck swap, sync command,
  commit, push, cleanup, stash, revert, file deletion, or runner termination
  was performed.

Evidence:

- `run_profile=pg023_rebaseline_after_oracle_specific_finisher_contract_fix_16_seed`,
  `run_scope=recurring_full`,
  `invocation_kind=codex_pg023_rebaseline_after_oracle_specific_finisher_contract_fix`,
  `seeds_completed=16/16`.
- Status: `trusted_for_strategy_learning`,
  `battle_replay_final_status_reason=all_mandatory_gates_pass`,
  `mandatory_gate_divergences=[]`.
- Gate/test summary: target-pressure `pass=16`, table-intent `pass=16`,
  tests `pass=18`.
- Strategy summary: `strategy_review_required_findings=0`,
  `forced_keep_after_bad_mulligan=2`, severity `medium=2`.
- Outcome: Lorehold target wins `1/16`, opponents `14/16`; opponent combat to
  Lorehold `252`, to other players `2`.
- SQLite check: deck `6` is `100` rows / `100` quantity with `Boros Charm=1`,
  `Brainstone=1`, `Electroduplicate=1`, `Silent Arbiter=1`, and
  `Windborn Muse=1`.

Current order:

- Treat `152154` as current latest trusted gate-clean PG023 rebaseline.
- It clears the `151645` review checkpoint but does not improve deck outcome.
- Keep PG023 closed as deployed runtime shape; continue survival/conversion
  analysis and do not open DB mutation work from this run.

### Magus Candidate Over Electroduplicate Blocked - 2026-06-21 13:03 -0300

Scope:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_153944/summary.json`.
- No PostgreSQL apply, rollback, manual SQL write, deck swap, sync command,
  commit, push, cleanup, stash, revert, or file deletion was performed.

Evidence:

- `151200` was blocked before the contract fix:
  `event_contract_static=review_required`, `forensic_audit=blocked`.
- `152154` cleared that gate path and remains the latest trusted PG023
  rebaseline.
- `153944` is `candidate_magus_of_the_moat_for_electroduplicate_16_seed`,
  `seeds_completed=16/16`, `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["strategy_audit=blocked"]`.
- Target-pressure/table-intent/tests passed at `16`, `16`, and `18`.
- Strategy findings: `spending_last_land=1`,
  `spending_unique_color_land=1`, `forced_keep_after_bad_mulligan=2`,
  severity `high=1`, `medium=3`.
- Outcome: Lorehold target wins `3/16`, opponents `12/16`.
- SQLite deck `6` restored to `100` rows / `100` quantity with
  `Electroduplicate=1` and no focused `Magus of the Moat` row.
- New backup artifact:
  `docs/hermes-analysis/master_optimizer_reports/knowledge_db_backup_candidate_magus_over_electroduplicate_20260621_123935.sqlite`.

Current order:

- Reject Magus of the Moat over Electroduplicate as blocked candidate evidence.
- Do not open PostgreSQL apply/rollback from `153944`.
- Preserve backup artifact unless an explicit cleanup command is approved.

### Magus Candidate After Mox Trace Fix - 2026-06-21 13:19 -0300

Scope:

- Latest symlink advanced to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_160405/summary.json`.
- No PostgreSQL apply, rollback, manual SQL write, deck swap, sync command,
  commit, push, cleanup, stash, revert, or file deletion was performed.

Evidence:

- `160405` is
  `candidate_magus_of_the_moat_for_electroduplicate_after_mox_trace_fix_16_seed`,
  `seeds_completed=16/16`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Target-pressure/table-intent/tests passed at `16`, `16`, and `18`.
- Strategy blockers cleared: `strategy_review_required_findings=0`, residual
  `forced_keep_after_bad_mulligan=2`.
- Outcome: Lorehold target wins `3/16`, opponents `12/16`.
- SQLite deck `6` restored to `100` rows / `100` quantity with
  `Electroduplicate=1` and no focused `Magus of the Moat` row.
- New backup artifact:
  `docs/hermes-analysis/master_optimizer_reports/knowledge_db_backup_candidate_magus_over_electroduplicate_20260621_160258.sqlite`.

Current order:

- Treat `160405` as valid but rejected candidate evidence.
- Do not promote Magus over Electroduplicate: it remains below PG023 smoke
  baseline and does not justify a PostgreSQL package.
- Preserve backup artifacts unless explicit cleanup is approved.

### Victory Chimes Rule Fix And Latest Rebaseline - 2026-06-21 13:52 -0300

Scope:

- New local rule/source evidence appeared for `Victory Chimes` plus two new
  battle artifacts: `20260621_164101` and `20260621_164710`.
- This checkpoint did not execute PostgreSQL apply, rollback, manual SQL write,
  deck swap command, commit, push, cleanup, stash, revert, or deletion.

Evidence:

- `reviewed_battle_card_rules.json` now models `Victory Chimes` as curated
  verified `ramp_permanent` with `mana_produced=1`, `produces=C`, and
  `untaps_each_opponent_untap=true`, not as `draw_engine`.
- `victory_chimes_reviewed_rule_sqlite_sync_20260621_161900.json` records a
  local SQLite sync with `apply=true`, `inserted_or_updated=122`,
  `deleted_stale_reviewed_rows=1`, and `canonical_snapshot_rows_exported=3201`.
- Backup
  `knowledge_db_backup_victory_chimes_rule_fix_20260621_161900.sqlite`
  preserves the stale curated `draw_engine` row, proving the local correction
  target.
- Focused regression tests for Victory Chimes passed: `Ran 3 tests ... OK`.
  The full reviewed-rule test file still has 2 non-Victory Top/Scroll Rack
  failures and remains a separate test risk.
- `20260621_164101` was trusted and gate-clean after the Victory fix but weak:
  Lorehold `1/16`, opponents `14/16`.
- `20260621_164710` is the current latest:
  `run_profile=recurring_16_seed`, `invocation_kind=manual_cli`,
  `seeds_completed=16/16`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, target-pressure/table-intent/tests all pass
  at `16/16/18`, strategy review findings `0`, Lorehold `2/16`, opponents
  `13/16`.
- Final SQLite deck check is restored to PG023 shape: deck `6` is `100/100`
  with `Electroduplicate=1`, `Brainstone=1`, `Victory Chimes=1`, no focused
  `Magus of the Moat` row.

Current order:

- Close the active Victory Chimes draw/ramp modeling pending item.
- Do not open PostgreSQL deploy or rollback from these artifacts.
- Keep PG023 closed and continue Lorehold strategy outcome work; current
  trusted latest remains poor at `2/16`.

### Magus Same-Seed Candidate After Victory Fix - 2026-06-21 14:38 -0300

Evidence:

- Battle latest advanced after the 13:52 checkpoint to
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_173334/summary.json`.
- `173334` is
  `candidate_magus_after_victory_chimes_fix_same_seed_16_seed`,
  `seeds_completed=16/16`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Target-pressure/table-intent/tests pass at `16`, `16`, and `18`.
- Strategy review findings are `0`; residual signal is
  `forced_keep_after_bad_mulligan=2`.
- Outcome: Lorehold `3/16`, opponents `12/16`.
- Final SQLite deck `6` is restored to `100/100` with `Electroduplicate=1`,
  `Brainstone=1`, `Victory Chimes=1`, no focused `Magus of the Moat`.
- New backup artifact:
  `knowledge_db_backup_candidate_magus_after_victory_fix_same_seed_20260621_165700.sqlite`.

Current order:

- Treat `173334` as current latest trusted candidate evidence.
- Do not promote Magus: result remains below PG023 smoke baseline and does not
  justify PostgreSQL mutation or deck swap.
- Victory Chimes stays closed; active work remains Lorehold consistency and
  active learned-source lag governance.

### Runtime Cache Drift After Latest Battle - 2026-06-21 14:42 -0300

Evidence:

- Battle `latest` remains `20260621_173334`; no active battle runner remained
  at read time.
- New backup artifact:
  `knowledge_db_backup_candidate_magus_sphere_after_victory_fix_20260621_174200.sqlite`.
- Backup focused deck `6`: `Electroduplicate` and `Victory Chimes`.
- Current SQLite focused deck `6`: `Magus of the Moat` and
  `Sphere of Safety`.

Current order:

- Treat this as active local runtime-cache drift after latest battle, not as a
  completed battle or PostgreSQL signal.
- Do not restore, sync, apply, or swap without explicit command approval.
- Keep Victory Chimes rule modeling closed, but keep the Magus+Sphere runtime
  candidate state pending validation or explicit restoration instruction.

### Magus+Sphere Candidate Review Required - 2026-06-21 14:46 -0300

Evidence:

- The runner opened after the runtime-cache drift completed and advanced
  latest to `20260621_174142`.
- `174142` is
  `candidate_magus_sphere_after_victory_fix_same_seed_16_seed`,
  `seeds_completed=16/16`, `battle_replay_final_status=review_required`.
- Mandatory gates requiring review:
  `forensic_audit=review_required`, `replay_decision_audit=review_required`,
  `strategy_audit=review_required`.
- Target-pressure/table-intent/tests pass at `16`, `16`, and `18`.
- Strategy review findings are `1`; residual codes are
  `forced_keep_after_bad_mulligan=3` and `tutor_no_target=1`.
- Outcome: Lorehold `5/16`, opponents `11/16`.
- Final SQLite focused deck `6` is restored to `Electroduplicate` and
  `Victory Chimes`; no focused `Magus of the Moat` or `Sphere of Safety`.

Current order:

- Treat `174142` as the current latest artifact and reject Magus+Sphere as
  review-required candidate evidence.
- The temporary runtime-cache drift is closed by the completed run plus final
  runtime restore evidence.
- Do not open PostgreSQL deploy/rollback or deck swap from this result.

### PG077 Final Addendum Order - 2026-06-23 06:28 UTC

Evidence:

- `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_seething_song_metadata_restore_postcheck_20260623_062422.out`
  closed the final metadata regression found after the earlier PG077 sync.
- `docs/hermes-analysis/master_optimizer_reports/pg077_l4_battle_support_final_sync_report_20260623_062422.json`
  is the accepted final PG077 sync.
- `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg077_final_20260623_062422.json`
  is the accepted final deck `6` card-gate artifact.

Current order:

- Treat the `06:24:22` PG077 recheck as the active high-water mark.
- Use PG078 for the next PostgreSQL package.
- Deck `6` card gate is closed. Continue either with deck `606` high cards or
  with a fresh battle rebaseline from current deck `6`; do not mix those two
  steps in one unreviewed package.

### PG078 Applied Order - 2026-06-23 06:42 UTC

Evidence:

- `docs/hermes-analysis/master_optimizer_reports/deck606_l2_hash_scope_restore_pg078_postcheck_20260623_063535.out`
  validated 23 restored oracle hashes, zero missing target hashes, zero active
  shadow rows, 44 disabled shadow rows, and 67 backup rows.
- `docs/hermes-analysis/master_optimizer_reports/pg078_l2_hash_scope_restore_sync_report_20260623_063535.json`
  synced PostgreSQL into Hermes SQLite/canonical snapshot with
  `sqlite_inserted_or_updated=1802` and `canonical_snapshot_rows_exported=3201`.
- `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck6_pg078_l2_hash_scope_restore_20260623_063535.json`
  keeps deck `6` at `high=0`, `medium=0`, `pass=100`.
- `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck606_pg078_l2_hash_scope_restore_20260623_063535.json`
  leaves deck `606` at `high=7`, `medium=7`, `pass=67`.

Current order:

- Commit and push the PG078 evidence batch before starting the next long run.
- Run the fresh 16-seed battle rebaseline for deck `6` after the worktree is
  clean.
- Keep the next card-rule package separate from battle rebaseline evidence;
  the likely next card queue remains deck `606` high battle-critical cards.
