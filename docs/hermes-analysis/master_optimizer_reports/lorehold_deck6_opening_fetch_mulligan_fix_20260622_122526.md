# Lorehold Deck 6 Opening Fetch Mulligan Fix - 2026-06-22 12:25

## Scope

- Audit the remaining `forced_keep_after_bad_mulligan` seeds after the
  survival-reserve fix.
- Fix the opening-hand evaluator so fetchlands count as color fixing for
  mulligan decisions.
- Validate with focused and full battle runs.
- No PostgreSQL deploy, rollback, official deck swap, commit, push, stash,
  revert, cleanup, or file deletion was performed.

## Finding

The previous full run
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_121049/summary.json`
had `forced_keep_after_bad_mulligan=7` across seeds `63231111`, `63231114`,
`63231116`, `63231121`, and `63231124`.

Seed ownership audit:

- `63231111`: Kinnan forced keep, not Lorehold.
- `63231114`: Lorehold forced keep; real bad opener.
- `63231116`: Etali and Rograkh forced keeps, not Lorehold.
- `63231121`: Lorehold false off-color forced keep.
- `63231124`: Sisay forced keep, not Lorehold.

The actionable bug was seed `63231121`: `Bloodstained Mire` was treated as
`generic` in opening-hand color checks, so early white cards such as
`Esper Sentinel` and `Land Tax` were marked uncastable.

## Code Evidence

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  adds `_opening_hand_land_source_colors()`.
- The helper treats fetchlands as `wildcard` fixing only for opening-hand
  evaluation.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py`
  adds `test_mulligan_treats_fetch_land_as_opening_color_fixing`.

## Test Evidence

Commands passed:

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

Direct evaluation:

- Seed `63231121` Lorehold-style hand after fix:
  `keep=True`, `reason=early_card_flow:Esper Sentinel:1`, no
  `off_color_early_hand`.
- Seed `63231114` Lorehold-style hand remains `keep=False`, so the fix does not
  hide true weak-openers.

## Battle Evidence

Focused proof:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_122423/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`
- Strategy findings `0`
- Lorehold `1/1`

Full official window:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_122526/summary.json`
- `run_profile=opening_fetch_fix_full_16_seed`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`
- Target-pressure/table-intent gates `pass=16/16`
- Lorehold `2/16`; opponents `13/16`
- Opponent combat to Lorehold `296`; to other players `10`
- `forced_keep_after_bad_mulligan=1`, only seed `63231124`

## Decision

- The mulligan evaluator bug is closed.
- Lorehold-specific learning is now cleaner because no current Lorehold-owned
  low-confidence mulligan finding remains in the official 16-seed window.
- The deck is still not fixed: the win rate remains `2/16`.
- Next work should use the current high-confidence losses and target the actual
  strategic failure under table focus, not the superseded mulligan artifact.
