# Lorehold Deck 6 Replay Hand + Survival Reserve - 2026-06-22 12:10

## Scope

- Added hand visibility to generated battle `replay.txt`.
- Fixed the battle pilot so low-life main-phase decisions preserve mana for
  survival response cards such as `Teferi's Protection`.
- Added a cast-ledger recovery guard for stack items that reach resolution with
  cast context.
- No PostgreSQL deploy, rollback, official deck swap, commit, push, stash,
  revert, cleanup, or file deletion was performed.

## Code Evidence

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  emits `hand_snapshot` on turn-start and turn-end replay events.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
  renders `HandCards=[...]` in mulligan, turn-start, and turn-end output.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  reserves survival response mana at life `<= 10` when a survival response card
  is in hand and still payable.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
  covers both survival-response reservation and cast-ledger recovery.

## Test Evidence

Commands passed:

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

## Battle Evidence

Baseline:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_114203/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- Lorehold `1/16`; opponents `14/16`
- Opponent combat to Lorehold `298`; to other players `11`

Final same-seed validation:

- Artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_121049/summary.json`
- `run_profile=survival_reserve_full_gate_clean_16_seed`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`
- Target-pressure/table-intent gates `pass=16/16`
- Lorehold `2/16`; opponents `13/16`; one no-winner/stall seed
- Opponent combat to Lorehold `303`; to other players `11`

Seed proof:

- Replay:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_121049/seed_63231123/replay.txt`
- The replay shows hand cards from mulligan onward with `HandCards=[...]`.
- On turn 8, Lorehold is at critical life and has `Teferi's Protection`,
  `Silence`, `Aetherflux Reservoir`, `Seething Song`, and `Windborn Muse` in
  hand.
- On turn 9, `Windborn Muse` is cast with mana moving `8->4`, preserving a
  survival-response line. Lorehold finishes alive while all three opponents are
  dead.

## Decision

- Replay hand visibility is complete.
- The observed survival-response pilot bug is closed for this failure pattern.
- This is not deck-swap promotion evidence. The deck remains weak under table
  focus: current official same-seed result is only `2/16`.
- Next work should investigate opening hand quality and mulligan policy:
  `forced_keep_after_bad_mulligan=7` across seeds `63231111`, `63231114`,
  `63231116`, `63231121`, and `63231124`.
