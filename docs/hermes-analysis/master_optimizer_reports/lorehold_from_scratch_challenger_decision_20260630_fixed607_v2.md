# Lorehold From-Scratch Challenger Decision - Fixed 607 Opponent

- generated_at: `2026-06-30T19:10:00Z`
- source_builder: `docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_from_scratch_challenger_builder.py`
- protected_baseline_deck_id: `607`
- fixed_opponent_deck_ids: `607`
- postgres_writes: `false`
- source_db_mutated: `false`

## Decision

Do not promote any from-scratch challenger over protected deck `607` from the
current evidence.

The new from-scratch pipeline is valid for exploration and package learning:
it builds complete isolated 100-card shells from the Lorehold corpus `607-616`,
uses `607` only as protected baseline/fixed opponent, and emits battle-gate
commands with `--fixed-opponent-deck-ids 607`.

## Structural Read

After score repair for package overfill, the challengers became materially more
coherent but still trailed the protected baseline:

| Candidate | Structural Rank | Score | Intent | Rule Ready |
| --- | ---: | ---: | ---: | ---: |
| `challenger_lorehold_miracle_topdeck_control_v1` | 3 | 131.623 | 94.212 | 96.88% |
| `challenger_lorehold_spellchain_big_sorcery_v1` | 4 | 131.223 | 94.394 | 96.91% |
| `challenger_lorehold_recursion_discard_engine_v1` | 4 | 129.137 | 91.990 | 96.88% |
| `deck_607` | 1 | 141.036 | 100.000 | 97.87% |

## Battle Evidence

All smoke gates used the same table composition:

- fixed opponent: `Fixed Lorehold deck 607`
- learned opponents: `Vivi Ornitier #99`, `Sisay, Weatherlight Captain #61`,
  `Winota, Joiner of Forces #39`

Initial one-game-per-opponent smoke:

| Candidate | Candidate Result | 607 Result | Read |
| --- | ---: | ---: | --- |
| `miracle_topdeck_control` | 0/4 | 1/4 | reject for now |
| `spellchain_big_sorcery` | 0/4 | 1/4 | reject for now |
| `recursion_discard_engine` | 1/4 | 1/4 | run confirmation |

Confirmation for `recursion_discard_engine`, three games per opponent:

| Deck | Result | WR | Win Reasons |
| --- | ---: | ---: | --- |
| `deck_607` | 5W/7L/0S | 41.67% | `approach=2`, `elimination=3` |
| `challenger_lorehold_recursion_discard_engine_v1` | 3W/9L/0S | 25.00% | `approach=1`, `elimination=2` |

## Useful Learning

`recursion_discard_engine` is not a full-deck replacement, but it produced real
engine telemetry:

- `Squee, Goblin Nabob`: graveyard entries `7`, upkeep returns `6`, explained
  returns `6`.
- `Birgi`: spell-cast mana `13`.
- `Sensei's Divining Top`: accessed in `7/12` games.
- `Library of Leng`: accessed in `5/12` games.
- `discard_to_top_replacement`: `10`.

The protected 607 still converted better overall:

- `607` had more miracle casts: `23` versus `7`.
- `607` had more wins: `5/12` versus `3/12`.
- The challenger failed the Sisay lane: `0/3`.

## Next Step

Keep the from-scratch challenger pipeline. Use the recursion/discard shell as a
package-learning source, not as a replacement. The next concrete experiment
should isolate the package that actually fired:

`Squee + Library of Leng + Sensei's Divining Top + Birgi/recursion support`

That package must be recut into a same-lane, protected-607 candidate and then
retested with the same fixed-607 opponent gate.
