# Lorehold Deck 6 Survival Defense Counter Legality Audit - 2026-06-22 12:48 UTC

## Scope

- Validate the requested replay observability improvement: `replay.txt` must show the player's current hand cards.
- Audit current high-confidence Lorehold losses after the opening-fetch mulligan cleanup.
- Fix only battle-runtime defects with direct replay/test evidence.
- No PostgreSQL apply, rollback, deck swap, commit, push, stash, cleanup, or file deletion was executed in this checkpoint.

## Runtime Changes

- `battle_replay_v10_3.py` renders `HandCards=[...]` in the mulligan block, turn-start lines, and turn-end lines. `battle_analyst_v9.py` emits `hand_snapshot` at turn start and turn end.
- `battle_analyst_v9.py` raises the survival-response reserve threshold to `15`, so Lorehold does not spend the last flexible white mana on non-survival plays while holding effects such as `Teferi's Protection`.
- `battle_analyst_v9.py` prioritizes proactive combat defenses (`attack_tax`, `attack_limit`) over commander/non-defense lines when the player is already below the survival reserve threshold.
- `battle_analyst_v9.py` adds runtime target legality for counterspells with mana-value restrictions. `Mental Misstep` is now a manual runtime waiver with `counter_target_cmc=1`, preventing it from countering `Windborn Muse`.
- `battle_stack_casting_tests.py` adds regression coverage for `Mental Misstep`: it cannot counter `Windborn Muse` but can counter `Esper Sentinel`.

## Test Evidence

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` passed.
- Latest full artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_124815/summary.json`.
  It is `trusted_for_strategy_learning`, `mandatory_gate_divergences=[]`,
  `seeds_completed=16/16`, and `test_results_status_counts={"pass":18}`.

## Replay Evidence

Focused seed proof:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_124815/seed_63231114/replay.txt`

Relevant replay lines:

- Turn 6 Lorehold starts the critical window with hand visible:
  `HandCards=[Lotus Petal, Windborn Muse, Land Tax, Teferi's Protection]`.
- Rograkh attacks for lethal pressure and Lorehold now preserves/casts the response:
  `CAST Lorehold: Teferi's Protection (CMC=3.0) [phase_out] phase=combat_damage`.
- The prevented damage is explicit:
  `DAMAGE Rograkh ... -> Lorehold: 0 player damage, target life 1, target_dead=False`.
- Turn 7 Lorehold starts at life 1 with hand visible:
  `HandCards=[Lotus Petal, Windborn Muse, Land Tax]`.
- Lorehold now casts the proactive defense before commander:
  `CAST Lorehold: Windborn Muse (CMC=4.0) [attack_tax]`.
- `Windborn Muse` resolves. Thrasios still holds `Mental Misstep`, proving the invalid counter no longer fires against a mana-value-four spell.
- Thrasios and Sisay attacks are reduced to zero damage. Lorehold still dies to Rograkh for 2 damage later in turn 7, which is now a real deck/board-state loss rather than the prior counter-legality defect.

## Outcome Delta

Compared with the previous full gate-clean run `20260622_122526`:

- Lorehold win count stayed at `2/16`.
- Opponent win count stayed at `13/16`.
- Opponent combat pressure to Lorehold rose from `296` to `316`.
- Opponent combat pressure to other players rose from `10` to `13`.
- Strategy residue stayed at `forced_keep_after_bad_mulligan=1`, still only seed `63231124`.

## Current Reading

- The replay hand-card requirement is closed by generated `replay.txt` output and renderer/runtime support.
- The survival-response, proactive-defense priority, and `Mental Misstep` target-legality bugs are closed for the observed failure pattern.
- The deck is still not fixed. The latest full run remains `2/16`, and the table still behaves like Lorehold is the focused threat.
- The next real improvement should target deck construction and strategic sequencing under table focus: earlier proactive combat taxation, more reliable life buffer, and faster conversion after surviving the first focused pressure wave.

## PostgreSQL Status

- No PostgreSQL write was applied in this checkpoint.
- `Mental Misstep` is currently corrected through a manual runtime waiver in code. It should be promoted into the durable `card_battle_rules`/PostgreSQL source-of-truth path in the next PostgreSQL deploy package if the current runtime behavior is accepted.
