# Lorehold Squee Seed Diagnostic

- generated_at: `2026-06-27T15:47:22Z`
- candidate_key: `candidate_607_squee_hashseed0_isolated_cached_timeout_v3`
- postgres_writes: `false`
- source_db_mutated: `false`

## Findings

- The 10-seed suite keeps Squee only narrowly ahead: 24W/66L vs deck_607 21W/69L. That is evidence to keep testing, not evidence to lock the final list.
- Seed 42 is the success case: candidate 8W/1L with topdeck=30, miracle=33, squee_gy=7, squee_return=5.
- Seeds 7 and 20260625 are the anti-cases: candidate 0W/9L and 0W/9L, with squee_gy=0/0 and squee_return=0/0.
- The practical read is that Squee is not yet a self-sufficient plan. It helps when the topdeck/miracle/spell-volume engine is alive, but in failure seeds it does not appear or convert.

## 10-Seed Suite Summary

| Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `candidate_607_squee_hashseed0_isolated_cached_timeout_v3` | 90 | 24 | 66 | 0 | 26.67% | 135 | 97 | 771 | 902 | 16 | 12 |
| `deck_6` | 90 | 16 | 74 | 0 | 17.78% | 89 | 88 | 690 | 854 | 0 | 0 |
| `deck_607` | 90 | 21 | 69 | 0 | 23.33% | 145 | 81 | 694 | 859 | 0 | 0 |

## Diagnostic Gates

| Seed | Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 42 | `deck_6` | 9 | 0 | 9 | 0 | 0.00% | 9 | 18 | 66 | 89 | 0 | 0 |
| 42 | `deck_607` | 9 | 5 | 4 | 0 | 55.56% | 25 | 9 | 98 | 122 | 0 | 0 |
| 42 | `candidate_607_squee_hashseed0_isolated_cached_timeout_v3` | 9 | 8 | 1 | 0 | 88.89% | 33 | 30 | 118 | 148 | 7 | 5 |
| 20260625 | `deck_6` | 9 | 3 | 6 | 0 | 33.33% | 10 | 4 | 79 | 100 | 0 | 0 |
| 20260625 | `deck_607` | 9 | 4 | 5 | 0 | 44.44% | 25 | 17 | 84 | 97 | 0 | 0 |
| 20260625 | `candidate_607_squee_hashseed0_isolated_cached_timeout_v3` | 9 | 0 | 9 | 0 | 0.00% | 4 | 3 | 48 | 64 | 0 | 0 |
| 7 | `deck_6` | 9 | 2 | 7 | 0 | 22.22% | 9 | 11 | 80 | 95 | 0 | 0 |
| 7 | `deck_607` | 9 | 1 | 8 | 0 | 11.11% | 12 | 0 | 65 | 83 | 0 | 0 |
| 7 | `candidate_607_squee_hashseed0_isolated_cached_timeout_v3` | 9 | 0 | 9 | 0 | 0.00% | 4 | 2 | 42 | 53 | 0 | 0 |

## Candidate Outcome Lens

| Seed | Result | Games | Avg Turns | Miracle | Topdeck | Spell Cast | Squee GY | Squee Return | Games With Topdeck | Games With Squee GY |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 42 | loss | 1 | 6.00 | 0 | 0 | 5 | 1 | 0 | 0 | 1 |
| 42 | win | 8 | 15.12 | 33 | 30 | 113 | 6 | 5 | 5 | 3 |
| 20260625 | loss | 9 | 7.00 | 4 | 3 | 48 | 0 | 0 | 1 | 0 |
| 7 | loss | 9 | 6.33 | 4 | 2 | 42 | 0 | 0 | 1 | 0 |

## Next Tests

- Do not promote Squee as final on the current evidence; treat it as a provisional micro-upgrade.
- Test one topdeck consistency package against 607+Squee, because the winning seed is topdeck/miracle rich and the failure seeds are not.
- Test one explicit Squee-enabler package with discard/rummage access, because current traces prove graveyard recurrence but not the intended discard-fuel loop.
- Keep per-game telemetry on all decisive gates so future swaps can be explained by actual game outcomes, not aggregate counters alone.
