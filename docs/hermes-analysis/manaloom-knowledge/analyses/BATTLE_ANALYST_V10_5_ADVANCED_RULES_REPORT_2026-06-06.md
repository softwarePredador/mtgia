# Battle Analyst v10.5 Advanced Rules Report

Date: 2026-06-06

## Implemented

### Colored mana

- Parses generic, colored, colorless, hybrid, and variable mana symbols.
- Requires the correct colored sources when `mana_cost` metadata exists.
- Supports flexible multi-color sources and Treasure tokens.
- Basic lands and known artifact lands produce their real colors.
- Unknown legacy sources remain generic rather than inventing a color.
- Commander tax is added as generic mana to the commander's real cost.
- All normal casts, counters, removal, ramp, and end-step interaction use the colored payment API.

### Card metadata ingestion

- Learned deck cards preserve imported metadata instead of discarding it.
- `mana_cost`, `colors`, `produces`, `keywords`, `oracle_text`, `power`, and `toughness` are accepted when present.
- Combat keywords are normalized into simulator flags.
- Current legacy datasets without these fields continue to use their previous generic fallback.

### Advanced combat

- Multiple blockers can gang-block a single attacker.
- Each blocker is assigned to at most one attacker.
- First strike and double strike work for attackers and blockers.
- Damage is simultaneous within each combat damage step.
- Deathtouch makes any positive combat damage lethal.
- Trample assigns excess damage after lethal damage is assigned to every blocker.
- A blocked creature without trample remains blocked after its blockers die.
- Indestructible creatures survive lethal combat damage.
- Replay combat events expose gang-block counts.

## Validation

- Focused regression suite: 23/23 passing locally and inside Hermes.
- Existing v10.4 regressions remain passing.
- Added isolated proofs for:
  - incorrect colored mana rejection;
  - Treasure/flexible source colored payment;
  - basic-land colored refresh;
  - multiple blockers;
  - trample excess damage;
  - deathtouch lethal assignment;
  - first-strike blocker timing.
  - indestructible surviving lethal combat damage;
  - double strike plus trample across both damage steps.

Full simulator validation:

- 600 four-player games completed without crashes.
- Calibrated result: 416 wins, 179 losses, 5 stalls.
- Overall win rate: 69.3%.
- The v10.4 baseline was 324 wins, 270 losses, 6 stalls.
- The higher win rate is an observed rules consequence: legal gang blocks and simultaneous trades slow combat elimination and give the Approach alternate-win plan more time. The simulator does not artificially rebalance this result.

## Data limitation

The current `deck_cards` schema has no `mana_cost`, `power`, `toughness`, `keywords`, or color columns. Learned deck JSON currently usually contains only name, CMC, type, and role. The engine now supports the richer fields, but legacy cards remain generic until import/enrichment starts supplying them.
