# Lorehold Brass's Bounty Exposure Decision - 2026-06-27

- package: `brass_bounty_cut_boros_signet`
- add: `Brass's Bounty`
- cut: `Boros Signet`
- source_db_mutated: `false`
- postgres_writes: `false`
- decision: `do_not_promote_yet`

## Evidence

| Gate | Seed | Games/Opp | Opponents | Baseline | Candidate | Delta | Brass Exposure | Gate Decision |
| --- | ---: | ---: | ---: | --- | --- | ---: | --- | --- |
| `lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849` | 42 | 3 | 8 | 9/15/0, 37.50%, avg win turn 17.89 | 11/13/0, 45.83%, avg win turn 17.73 | +8.33pp | old telemetry, no per-card exposure map | `promote_to_deeper_gate` |
| `lorehold_brass_bounty_gate_20260627_v5_exposure_smoke_20260627_213725` | 42 | 1 | 8 | 2/6/0, 25.00%, avg win turn 22.50 | 1/7/0, 12.50%, avg win turn 28.00 | -12.50pp | `miracle_cast=1`, `spell_resolved=1`, `treasure_created=1`, `discard_to_top=5` | `reject_or_rework` |
| `lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848` | 7 | 2 | 8 | 4/12/0, 25.00%, avg win turn 16.50 | 4/12/0, 25.00%, avg win turn 17.00 | +0.00pp | `miracle_cast=1`, `spell_resolved=1`, `treasure_created=1` | `tie_watch_strategy_regression` |

## Interpretation

`Brass's Bounty` is runtime-valid and can convert through the Lorehold miracle line:
the exposure gates observed `miracle_cast:Brass's Bounty`, `spell_resolved:Brass's Bounty`,
and `treasure_created:Brass's Bounty`.

The result is not stable enough to replace `Boros Signet` in the current best
deck. One larger seed-42 gate was positive, but the exposure-enabled smoke was
negative and the seed-7 confirmation was a tie with strategy-regression flags.

## Current Handling

- Keep the runtime rule and telemetry instrumentation.
- Do not promote `Brass's Bounty` into the canonical Lorehold list yet.
- Keep the card in the candidate queue as `needs_rework_or_deeper_multi_seed_gate`.
- Re-test only if paired with a clearer topdeck/conversion package or a safer
  cut model than `Boros Signet`.

## Next Candidate Direction

The miner currently ranks `Apex of Power`, `Volcanic Vision`, `Restoration Seminar`,
`Austere Command`, and mana-base candidates above most unexplored cards. Before
running those gates, the next requirement is to define safe cuts or package
models for their lanes:

- `Apex of Power`: needs a hand-filter/big-spell cut model before gate.
- `Volcanic Vision` and `Restoration Seminar`: only obvious cut is `Squee, Goblin Nabob`, which is now proven strategically active and should not be cut casually.
- `Austere Command`: requires deciding whether `Emeria's Call // Emeria, Shattered Skyclave` is a safe pressure/protection cut.
- Mana-base candidates need a land cut model instead of swapping against non-land cards.
