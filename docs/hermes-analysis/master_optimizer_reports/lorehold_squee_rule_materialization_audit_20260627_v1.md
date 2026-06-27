# Lorehold Squee Rule Materialization Audit

- Decision: `loader_gap_fixed_but_not_deck_promotion`
- Finding: Squee now materializes one verified/auto graveyard-recursion rule in the equal-gate candidate; across seeds 42, 7, and 20260625 candidate is 8/19 versus deck_607 10/17, so the fix improves rule evidence but does not prove a stronger deck by itself.

| Seed | Deck | W | L | S | WR | Miracle | Topdeck | Squee GY | Squee Return | Spell Rummage | Rule Keys | Tags |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 42 | `deck_607` | 5 | 4 | 0 | 55.56% | 25 | 9 | 0 | 0 | 4 |  |  |
| 42 | `candidate_607_squee_goblin_nabob_equal_gate` | 8 | 1 | 0 | 88.89% | 33 | 30 | 7 | 5 | 19 | battle_rule_v1:4565272d5decc69322e01a4f919df77e | graveyard_recursion, engine, board_presence, wincon |
| 7 | `deck_607` | 1 | 8 | 0 | 11.11% | 12 | 0 | 0 | 0 | 0 |  |  |
| 7 | `candidate_607_squee_goblin_nabob_equal_gate` | 0 | 9 | 0 | 0.00% | 4 | 2 | 0 | 0 | 2 | battle_rule_v1:4565272d5decc69322e01a4f919df77e | graveyard_recursion, engine, board_presence, wincon |
| 20260625 | `deck_607` | 4 | 5 | 0 | 44.44% | 25 | 17 | 0 | 0 | 0 |  |  |
| 20260625 | `candidate_607_squee_goblin_nabob_equal_gate` | 0 | 9 | 0 | 0.00% | 4 | 3 | 0 | 0 | 2 | battle_rule_v1:4565272d5decc69322e01a4f919df77e | graveyard_recursion, engine, board_presence, wincon |

## Aggregate

| Deck | W | L | S | WR | Miracle | Topdeck | Squee GY | Squee Return | Spell Rummage |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | 10 | 17 | 0 | 37.04% | 62 | 26 | 0 | 0 | 4 |
| `candidate_607_squee_goblin_nabob_equal_gate` | 8 | 19 | 0 | 29.63% | 41 | 35 | 7 | 5 | 23 |
