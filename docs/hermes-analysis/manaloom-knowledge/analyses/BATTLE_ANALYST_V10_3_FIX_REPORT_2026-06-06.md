# Battle Analyst v10.3 Fix Report

Date: 2026-06-06

## Scope

This patch fixes three replay defects observed after v10.2:

- cleanup did not discard to seven cards after any player had died;
- games continued after a second resolved `Approach of the Second Sun`;
- combat logging depended on fragile source-string injection.

It also fixes a directly related draw-step indentation defect that caused zero
or multiple normal draws depending on battlefield size.

## Root causes

1. `check_sbas()` returned `True` forever for players already at zero life.
   Every later turn returned before cleanup.
2. Approach victory was represented only by `approach_count`. Some callers
   checked it after a complete turn, allowing later spells and combat to occur.
3. Replay generation modified source text at runtime and silently stopped
   logging when the expected source string changed.
4. The normal draw step was nested inside the upkeep battlefield loop.

## Implementation

- Track newly eliminated players separately from players already eliminated.
- Store explicit alternate-win state on `Player.win_reason`.
- Stop stack resolution, phases, turns, and game loops immediately after a win.
- Emit optional structured replay events from the battle engine.
- Generate replays by consuming those events instead of editing source text.
- Keep cleanup and draw-step behavior covered by focused regression tests.

## Validation

Focused tests:

```text
PASS test_sba_only_reports_new_elimination
PASS test_cleanup_runs_with_previously_eliminated_player
PASS test_draw_step_runs_once_with_multiple_permanents
PASS test_approach_sets_explicit_win_state
PASS test_combat_emits_structured_event
PASS test_turn_stops_immediately_after_approach_win
```

Five deterministic replay seeds were generated:

```text
seed=42 combats=28 hand_violations=0 GAME OVER - Turn 25 Winner: none (stall)
seed=43 combats=0  hand_violations=0 GAME OVER - Turn 13 Winner: Lorehold (approach)
seed=44 combats=24 hand_violations=0 GAME OVER - Turn 25 Winner: none (stall)
seed=45 combats=15 hand_violations=0 GAME OVER - Turn 15 Winner: Tivit, Seller of Secrets (real) (elimination)
seed=46 combats=21 hand_violations=0 GAME OVER - Turn 22 Winner: Tivit, Seller of Secrets (real) (elimination)
```

The seed 43 replay recorded the second Approach on turn 13 and immediately
recorded `GAME OVER - Turn 13`, with no spell or combat action after the win.

Compatibility smoke:

```text
Battle Analyst: 600 games completed
Overall: 336 wins / 259 losses / 5 stalls
Python compilation: battle_analyst_v8.py, slot_optimizer.py, kc_validator.py
```

`slot_optimizer.py` and `kc_validator.py` were compiled but not executed in
mutating mode, so the existing `knowledge.db` was not changed by this patch.

## Follow-up risks

- Mana is not modeled as tapped sources. `available_mana()` can refill after
  the pool reaches zero, allowing unrealistic reuse within a turn.
- Target selection and blockers remain simplified and are not evaluated per
  attacking creature or defending player with full Commander rules.
- Opponent threat assessment does not yet reason about visible lethal,
  commander-specific engines, or resource preservation deeply enough.
- Replay events cover the corrected critical path but do not yet include every
  cast, counter, target, trigger, zone move, or mana payment.
