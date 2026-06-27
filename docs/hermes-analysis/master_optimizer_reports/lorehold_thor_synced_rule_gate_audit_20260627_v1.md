# Lorehold Thor Synced Rule Gate Audit - 2026-06-27

- Generated at: `2026-06-27T17:07:57Z`
- Decision: `rule_sync_verified_battle_exposure_observed_no_winrate_delta`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Seeds: `42, 7, 13, 21, 99, 123, 321`
- Candidate exposure: `1/21` games with Thor damage trigger (`4.76%`).
- Win-rate delta: `+0.00` pp.

## Sync And Materialization

- Reviewed rows synced into temp SQLite: `134` (`manual=0`, `generated=0`).
- Deck materialized Thor rule count: `1`.
- Thor rule keys: `battle_rule_v1:280e17ec34ac105baeb6989491c6ff25`.

## Aggregate

| Deck | Games | W | L | S | WR | Thor Cost | Thor Cast | Thor Damage Triggers | Thor Damage | Miracle | Topdeck | Spell Cast |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `deck_6` | 21 | 6 | 15 | 0 | 28.57% | 1 | 1 | 0 | 0 | 39 | 32 | 170 |
| `deck_6_thor_synced` | 21 | 6 | 15 | 0 | 28.57% | 1 | 0 | 1 | 7 | 40 | 32 | 170 |

## Per-Seed Result

| Seed | Deck | W | L | S | WR | Thor Cost | Thor Cast | Thor Damage | Damage Amount |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | `deck_6` | 0 | 3 | 0 | 0.00% | 0 | 0 | 0 | 0 |
| 7 | `deck_6_thor_synced` | 0 | 3 | 0 | 0.00% | 0 | 0 | 0 | 0 |
| 13 | `deck_6` | 0 | 3 | 0 | 0.00% | 0 | 0 | 0 | 0 |
| 13 | `deck_6_thor_synced` | 0 | 3 | 0 | 0.00% | 0 | 0 | 0 | 0 |
| 21 | `deck_6` | 0 | 3 | 0 | 0.00% | 0 | 0 | 0 | 0 |
| 21 | `deck_6_thor_synced` | 0 | 3 | 0 | 0.00% | 0 | 0 | 0 | 0 |
| 42 | `deck_6` | 3 | 0 | 0 | 100.00% | 0 | 0 | 0 | 0 |
| 42 | `deck_6_thor_synced` | 3 | 0 | 0 | 100.00% | 0 | 0 | 0 | 0 |
| 99 | `deck_6` | 1 | 2 | 0 | 33.33% | 0 | 0 | 0 | 0 |
| 99 | `deck_6_thor_synced` | 1 | 2 | 0 | 33.33% | 0 | 0 | 0 | 0 |
| 123 | `deck_6` | 1 | 2 | 0 | 33.33% | 1 | 1 | 0 | 0 |
| 123 | `deck_6_thor_synced` | 1 | 2 | 0 | 33.33% | 1 | 0 | 1 | 7 |
| 321 | `deck_6` | 1 | 2 | 0 | 33.33% | 0 | 0 | 0 | 0 |
| 321 | `deck_6_thor_synced` | 1 | 2 | 0 | 33.33% | 0 | 0 | 0 | 0 |

## Exposure Games

| Seed | Deck | Opponent | Result | Turns | Reason | Thor Cost | Thor Cast | Thor Damage | Damage Amount |
| ---: | --- | --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
| 123 | `deck_6` | Vivi Ornitier #99 (real) | win | 10 | `approach` | 1 | 1 | 0 | 0 |
| 123 | `deck_6_thor_synced` | Vivi Ornitier #99 (real) | win | 10 | `approach` | 1 | 0 | 1 | 7 |

## Read

The synced Thor rule executed once in natural battle exposure and dealt 7 damage, but the 21-game candidate sample had the same 6-15 record as the baseline. This proves runtime behavior can matter, but not that Thor improves the deck at current sample size/exposure rate.

Use a stratified Thor-exposure gate or larger sample before treating Thor as a keep/cut decision; ETB temporary graveyard play remains a separate runtime gap.
