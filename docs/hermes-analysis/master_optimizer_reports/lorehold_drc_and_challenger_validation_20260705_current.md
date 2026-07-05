# Lorehold DRC and Challenger Validation 2026-07-05

- status: `keep_607_protected_baseline_no_promotion`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`

## Decision

- Current best baseline: `deck_607`
- DRC promotion: `blocked`
- Reason: No candidate beats 607 across aggregate, fixed-607 head-to-head, and card-causality/forced-access evidence at the same time.

## Gate Summary

| Test | Cut | Candidate | Base | Delta W | Fixed 607 Candidate | Fixed 607 Base | DRC event games | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| natural8 | Hexing Squelcher | 14/24 (58.33%) | 11/24 (45.83%) | 3 | 2/8 | 4/8 | 9 | expand_or_watch |
| natural8 | Call Forth the Tempest | 10/24 (41.67%) | 11/24 (45.83%) | -1 | 5/8 | 4/8 | 9 | reject_window |
| natural8 | Everything Comes to Dust | 8/24 (33.33%) | 11/24 (45.83%) | -3 | 3/8 | 4/8 | 6 | reject_window |
| natural8 | Blasphemous Act | 11/24 (45.83%) | 11/24 (45.83%) | 0 | 3/8 | 4/8 | 5 | expand_or_watch |
| natural8 | Farewell | 9/24 (37.5%) | 11/24 (45.83%) | -2 | 3/8 | 4/8 | 7 | reject_window |
| natural8 | Starfall Invocation | 10/24 (41.67%) | 11/24 (45.83%) | -1 | 3/8 | 4/8 | 5 | reject_window |
| expanded24 | Hexing Squelcher | 34/72 (47.22%) | 30/72 (41.67%) | 4 | 9/24 | 11/24 | 26 | watch_not_promote |
| expanded24 | Call Forth the Tempest | 32/72 (44.44%) | 30/72 (41.67%) | 2 | 11/24 | 11/24 | 16 | watch_not_promote |
| forced_opening8 | Hexing Squelcher | 10/24 (41.67%) | 11/24 (45.83%) | -1 | 3/8 | 4/8 | 24 | forced_access_regression |
| forced_opening8 | Call Forth the Tempest | 6/24 (25.0%) | 11/24 (45.83%) | -5 | 3/8 | 4/8 | 23 | forced_access_regression |

## Full-Shell Challenger

- access_density_control: candidate `8/24` WR `33.33%`; base `11/24` WR `45.83%`; decision `reject_current_window`.

## External And Runtime Evidence

- 39% inclusion, 3.52K decks, 37% synergy observed on current EDHREC Lorehold page
- 39% inclusion, 18/46 decks, 37% synergy observed on EDHREC core Spellslinger page
- Commander legal, red color identity, surveil/delirium Oracle text verified through current Scryfall API
- verified/auto battle rule noncreature_spell_cast_surveil_one_delirium_plus2_plus2_flying_must_attack_v1

## Next Actions

- Keep deck 607 as protected baseline.
- Do not promote Dragon's Rage Channeler from this cycle.
- If DRC remains under review, build a card-causality trace that proves surveil changes a later topdeck/miracle outcome; current cost-paid exposure is not enough.
- Treat DRC over Call Forth the Tempest as watchlist only because natural aggregate improved slightly but forced access was strongly negative.
- Reject current access_density_control full-shell challenger and continue learning from 607 plus narrow probes.
