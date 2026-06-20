# Battle Table-Intent Real Battle Closure - 2026-06-20 18:27 -0300

## Scope

Rafael authorized the central auditor to own the full cycle for the Lorehold
real-battle validation: code, tests, PostgreSQL battle-rule promotion, Hermes
SQLite cache refresh, worktree organization, docs/registers, commit, and push
when the cycle is validated.

Operational goal used for this closure:

- Evaluate Lorehold deck `6` through real Commander battle pressure, not
  goldfish or forced one-sided target pressure only.
- Model table intent: threat assessment, low-life opportunism,
  self-preservation, lethal attacks, opponent wins, blocking, and opponent spell
  agency.
- Treat relevant opponent cards with the same battle-rule governance standard
  used for Lorehold, promoting blockers from fallback/runtime findings into
  PostgreSQL-backed curated rules when evidence is sufficient.
- Trust the result only when `summary.json`, replay auditors, tests, PostgreSQL
  reports, cache-sync reports, and registers agree.

## Current Source Of Truth

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/summary.json`
- Stable symlink:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`

The older battle states `20260620_210513`, `20260620_211217`, and
`20260620_211648` are superseded by this closure.

## Mandatory Gate Evidence

- Forensic lineage: `forensic_lineage_status=complete`
- Forensic findings: `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, `forensic_severity_counts={}`
- Action critic: `action_findings=0`
- Replay decision audit: `decision_audit_decision_findings=0`,
  `decision_audit_turn_findings=0`
- Decision trace contract: `decision_trace_contract_findings=0`
- Target pressure: `target_pressure_statuses={"pass":16}`,
  `target_pressure_findings=0`, `opponent_combat_to_target=214`,
  `opponent_combat_to_other=3`, `opponent_multi_defender_attack=2`
- Table intent: `table_intent_statuses={"pass":16}`,
  `table_intent_findings=0`, `combat_total=294`,
  `scored_combat_total=294`, `missing_scores=0`
- Opponent agency in table-intent run:
  `opponent_spell_cast=270`, `opponent_spell_resolved=153`,
  `opponent_creature_cast=101`, `opponent_commander_cast=59`,
  `opponent_cast_illegal=0`, `opponent_interaction_events=72`,
  `opponent_trigger_interaction_events=32`, `opponent_wins=15`,
  `target_wins=1`, `target_blockers_total=25`,
  `opponent_blockers_total=2`
- Unknown-template backlog: `unknown_template_backlog_cards=0`,
  `unknown_template_backlog_status=focused_template_backlog_ready`
- Effect-coverage residuals: `effect_coverage_residual_status=effect_coverage_residual_accepted`,
  `effect_coverage_residual_raw_unaccepted_flags=[]`,
  `effect_coverage_residual_unaccepted_cards=[]`

Reading: this is enough to trust the battle for strategy learning under the
current engine contract. It does not claim every possible Magic card ability in
the database is perfectly modeled; it claims the current recurring real-battle
surface has no unaccepted blocker.

## PostgreSQL And Cache Deployment Evidence

All PostgreSQL applies below targeted battle-rule promotions for real opponent
or Lorehold-facing replay blockers, then mirrored PostgreSQL into the local
Hermes SQLite runtime cache and canonical snapshot.

| round | selected cards | PG result | cache result |
| --- | --- | --- | --- |
| round5 | `Big Score`, `Spelltwine` | `pg_inserted_or_updated=3` | `pg_rows_loaded=5224`, `sqlite_inserted_or_updated=5142`, `canonical_snapshot_rows_exported=3181` |
| round6 | `Goblin Bombardment` | `pg_inserted_or_updated=2` | `pg_rows_loaded=5225`, `sqlite_inserted_or_updated=5143`, `canonical_snapshot_rows_exported=3181` |
| round7 | `Apex of Power`, `Arcane Endeavor`, `Curator's Ward`, `Magma Opus`, `The Unagi of Kyoshi Island` | `pg_inserted_or_updated=6` | `pg_rows_loaded=5230`, `sqlite_inserted_or_updated=5148`, `canonical_snapshot_rows_exported=3185` |
| round8 | `Practical Research`, `Tellah, Great Sage` | `pg_inserted_or_updated=2` | `pg_rows_loaded=5232`, `sqlite_inserted_or_updated=5150`, `canonical_snapshot_rows_exported=3187` |
| round9 | `Breena, the Demagogue` | `pg_inserted_or_updated=2` | `pg_rows_loaded=5233`, `sqlite_inserted_or_updated=5151`, `canonical_snapshot_rows_exported=3187`, `curated_rows=104` |

Relevant artifact files:

- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_pg_table_intent_promotions_round5_20260620.json`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_pg_table_intent_promotions_round6_20260620.json`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_pg_table_intent_promotions_round7_20260620.json`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_pg_table_intent_promotions_round8_20260620.json`
- `docs/hermes-analysis/master_optimizer_reports/card_battle_rules_pg_table_intent_promotions_round9_20260620.json`
- `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_full_after_table_intent_round9_20260620.json`

## One Real Battle Log

Seed used for human inspection:

- Replay:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/seed_63212120/replay.txt`
- Table-intent audit:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/seed_63212120/table_intent.md`
- Target-pressure audit:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/seed_63212120/target_pressure.md`
- Action critic:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_212035/seed_63212120/action_critic.md`

Replay facts:

- Evaluation mode: `table-intent-realistic`
- Evaluation target: `Lorehold`
- Opponents:
  `The Emperor of Palamecia #42 (real)`,
  `Thrasios, Triton Hero #54 (real)`,
  `Thrasios, Triton Hero #58 (real)`
- Deck provenance blockers: `none` for Lorehold and all three opponents.
- Table intent for the seed: `status=pass`, `combat_total=23`,
  `table_intent_missing_scores=0`, `opponent_spell_cast=26`,
  `opponent_spell_resolved=15`, `opponent_creature_cast=3`,
  `opponent_commander_cast=7`, `opponent_interaction_events=7`,
  `opponent_trigger_interaction_events=4`, `opponent_wins=1`,
  `target_wins=0`
- Target pressure for the seed: `status=pass`,
  `opponent_combat_total=16`, `opponent_combat_to_target=16`,
  `opponent_combat_to_other=0`, `findings=0`
- Action critic for the seed: `total_actions=446`, `findings=0`,
  `verdict_counts={"ok":446}`
- Outcome: Lorehold died on turn `11`; `The Emperor of Palamecia #42 (real)`
  won by elimination after Thrasios #54 delivered lethal damage to Lorehold.

## Lorehold Deck Reading

Lorehold deck `6` remains coherent and valid after the prior canonical Wheel
apply:

- Source: `sqlite_deck_cards`, `deck_id:6`
- Commander: `Lorehold, the Historian`
- Quantity: `100` total, `99` main, `1` commander
- Lands in current replay provenance: `33`
- Off-color cards: `[]`
- Singleton violations: `[]`

Battle reading is not "Lorehold is best". The realistic table-intent run shows
Lorehold as a valid tested target but under severe table pressure:
`opponent_wins=15` and `target_wins=1` across the latest 16-seed recurring run.
The next deck-improvement cycle should optimize Lorehold against this
table-intent pressure instead of using the older focused target-pressure
reading as a standalone win-rate claim.

## Residual Risk

- `strategy_findings=2` and `strategy_review_required_findings=0`.
  These are low-confidence/medium mulligan confidence notes, not mandatory
  blockers.
- There are accepted effect-coverage residuals and focused-template-ready
  unknown-effect families. They are tracked, accepted by current contracts, and
  not active blockers because `unaccepted_cards=[]`.
- Opponent learned-deck construction/coherence detailed reports are still
  waived at replay-provenance level because the replay emits resolved runtime
  shape, source identity, and metrics, not full per-deck construction reports.

## Conclusion

The battle loop is now functional for real strategy learning under table-intent
pressure. The current source of truth is `20260620_212035`, all mandatory gates
pass, PostgreSQL/cache promotions through round9 are represented in runtime,
and the next work should be a Lorehold optimization cycle using this real-battle
baseline.
