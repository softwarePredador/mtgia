# Lorehold Ghostly Prison over Promise Decision

- generated_at: `2026-06-27`
- decision: `promote_to_controlled_integration_gate`
- package: `ghostly_prison_pressure_cut_promise`
- add: `Ghostly Prison`
- cut: `Promise of Loyalty`
- scope: isolated candidate DB gates only
- postgres_writes: `false`
- source_db_mutated: `false`

## Why this lane was tested

The Lorehold shell is still a miracle/spellslinger deck, but the repeated
failure mode against real opponents is early/midgame combat pressure before the
expensive miracle payoffs stabilize the table. `Promise of Loyalty` is a
high-cost pressure reset that appeared very rarely in gates. `Ghostly Prison`
is a cheaper static pressure absorber that can protect the commander setup
turns without cutting `Hexing Squelcher` or `Fated Clash`.

The cached EDHREC Lorehold data also lists `Stax` and `Pillow Fort` tags for
the commander view and includes both `Promise of Loyalty` and `Ghostly Prison`
in the card data, so the hypothesis is archetype-coherent. The decision below,
however, is based on battle gates, not popularity.

## Gate Evidence

| Gate | Games | Baseline | Candidate | Delta | Ghostly resolved | Promise resolved |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `v1_games2_opp8_seed42` | 16 vs 16 | 3/13/0, 18.75% | 7/9/0, 43.75% | +25.00pp | 5 | 1 baseline |
| `v2_seed7_smoke_opp8` | 8 vs 8 | 1/7/0, 12.50% | 4/4/0, 50.00% | +37.50pp | 4 | 0 baseline |
| `v3_seed99_games3_opp8` | 24 vs 24 | 3/21/0, 12.50% | 8/16/0, 33.33% | +20.83pp | 8 | 1 baseline |

Aggregate:

- Baseline: `7/41/0`, WR `14.58%`.
- Candidate: `19/29/0`, WR `39.58%`.
- Aggregate delta: `+25.00pp`.
- Candidate `Ghostly Prison`: `18` cost-paid/cast events, `17` resolved events across the three gates.
- Baseline `Promise of Loyalty`: `2` resolved events across the three gates.
- Miracle games did not collapse after the cut: baseline `23/48`, candidate `31/48`.

## Runtime and Telemetry Work

Runtime already enforced attack tax through `battle_analyst_v9.py`, but the
combat detail did not identify which permanent supplied the restriction. That
made `Ghostly Prison` hard to prove beyond cast/resolution counts.

Changes made:

- Added `defender_attack_tax_details()` and preserved
  `defender_attack_tax_per_creature()` as a compatibility wrapper.
- Combat restriction details now include `attack_tax_sources` and
  `attack_restriction_sources`.
- The pressure absorber ablation auditor now credits restricted attackers only
  when a target package card is named as the restriction source.
- Combat tests now assert source attribution for `Ghostly Prison` and combined
  `Sphere of Safety` plus `Ghostly Prison` tax.

## Source Attribution Smoke

Report:
`lorehold_ghostly_pressure_ablation_20260627_v1_seed99_games1_opp8`

- Candidate DB: `lorehold_ghostly_promise_gate_20260627_v3_seed99_games3_opp8_20260627_221640_ghostly_prison_pressure_cut_promise/knowledge_candidate.db`
- Available pressure target in this candidate: `Ghostly Prison`.
- `Ghostly Prison` seen in `2/8` games and cost paid in `2/8`.
- Source-attributed restrictions: `2` events, `5` attackers restricted,
  `10` tax paid, `source_event_counts={"Ghostly Prison": 2}`.
- The `without_ghostly_prison` blank-slot smoke had `0` source-attributed
  restrictions. Its WR was higher in this very small 8-game ablation, so this
  smoke is used only to prove attribution, not to override the 48-game
  Ghostly-over-Promise gate result.

## Decision

Promote `Ghostly Prison` over `Promise of Loyalty` to the next controlled
integration gate. Do not write PostgreSQL from this evidence alone.

Required next validation before live deck mutation:

- Run a final larger integration gate with the post-source-attribution runtime.
- Include an explicit pressure metric in the acceptance criteria:
  `attack_restriction_sources` must attribute meaningful restricted attackers
  to `Ghostly Prison` in the games where it is seen.
- If the larger gate remains positive, update the deck source of truth and
  synchronize Hermes in a separate PostgreSQL-approved package.
