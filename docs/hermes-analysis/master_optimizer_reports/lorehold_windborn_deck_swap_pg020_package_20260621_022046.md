# PG-020 Lorehold Windborn Deck Swap Package

- status: applied_and_postchecked
- target PostgreSQL deck: `528c877f-f829-4207-95e6-73981776c323`
- deck name observed: `Runtime Lorehold Learned 19e93de3cca`
- intended swap: add `Windborn Muse`, remove `Guttersnipe`
- reason: Hermes PG019 trusted 64-seed battle showed `Windborn Muse` over
  `Guttersnipe` improved Lorehold from `2/64` to `4/64` on the same seed
  window and kept mandatory battle gates clean.

Evidence before PostgreSQL promotion:

- Hermes apply artifact:
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_apply_20260621_020406.md`
- Hermes rollback artifact:
  `docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260621T020406839706+0000.json`
- Trusted 64-seed post-apply summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_020729/summary.json`
- Battle result: `4/64 = 6.25%`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`.
- Baseline before swap: `2/64 = 3.125%` in
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_015127/summary.json`.

Safety model:

- `precheck` verifies exact target deck, 100/100 deck shape, one
  non-commander `Guttersnipe`, no `Windborn Muse`, unique resolved card IDs,
  Commander legality, and Boros-compatible color identity.
- `apply` stores the original `deck_cards` row in
  `manaloom_deploy_audit.pg020_lorehold_windborn_deck_swap_20260621_022046`
  before updating the row's `card_id`.
- `postcheck` verifies the deck remains 100/100 with one `Windborn Muse`, no
  `Guttersnipe`, and exactly one audit backup row.
- `rollback` restores the previous `card_id` from the audit table.

Files:

- `lorehold_windborn_deck_swap_pg020_precheck_20260621_022046.sql`
- `lorehold_windborn_deck_swap_pg020_apply_20260621_022046.sql`
- `lorehold_windborn_deck_swap_pg020_postcheck_20260621_022046.sql`
- `lorehold_windborn_deck_swap_pg020_rollback_20260621_022046.sql`

Execution result:

- Precheck result on `143.198.230.247:5433/halder`: `ready_to_apply=true`.
- Apply result: `guttersnipe_rows=0`, `windborn_rows=1`,
  `total_quantity=100`.
- Postcheck result: `postcheck_passed=true`, `backup_rows=1`,
  `deck_rows=100`, `deck_quantity=100`, `Guttersnipe=0`,
  `Windborn Muse=1`, `windborn_is_commander=false`.
- PG -> Hermes sync:
  `docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg020_windborn_20260621_022046.json`,
  `cards_written=100`, `quantity_written=100`, `duplicate_rows_collapsed=0`.
- Post-PG/sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022403/summary.json`,
  `2/16`, `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`.
- Post-PG/sync 64-seed confirmation:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_022700/summary.json`,
  `4/64 = 6.25%`, `trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`,
  `strategy_code_counts={"forced_keep_after_bad_mulligan":15}`.

Current strategy conclusion:

- PG-020 is a valid first deck correction, not a solved deck.
- Lorehold still loses `60/64` in this seed window, with target pressure
  `912` to Lorehold versus `12` to other players.
- Next deck work should prioritize early survivability and mulligan/keep
  stability over additional payoff.
