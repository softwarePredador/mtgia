# Lorehold Pressure Absorber Ablation Telemetry

- generated_at: `2026-06-27T22:22:20Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v3_seed99_games3_opp8_20260627_221640_ghostly_prison_pressure_cut_promise/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_seed: `20260626`
- simulation_seed: `99`
- opponents: `8`
- available_target_cards: `Ghostly Prison`
- absent_target_cards: `Crawlspace, Magus of the Moat, Silent Arbiter, Sphere of Safety, Windborn Muse`
- postgres_writes: `false`
- source_db_mutated: `false`

## Probability Baseline

| Cards seen | One specific card | Any of 6-card package |
| ---: | ---: | ---: |
| 7 | 7.07% | 36.36% |
| 10 | 10.10% | 48.14% |
| 12 | 12.12% | 54.93% |
| 15 | 15.15% | 63.72% |
| 20 | 20.20% | 75.19% |
| 25 | 25.25% | 83.47% |

## Scenario Results

| Scenario | Games | W | L | S | WR | Avg win turn | Package restricted attackers | Restriction events | Restriction sources |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| baseline_v7 | 8 | 2 | 6 | 0 | 25.00% | 16.00 | 5 | 2 | Ghostly Prison=2 |
| without_ghostly_prison | 8 | 3 | 5 | 0 | 37.50% | 14.33 | 0 | 0 |  |

## Baseline Card Telemetry

| Card | Seen games | Seen rate | Opening seen | In-game drawn | Cast paid games | Casts paid | Cast when seen |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Crawlspace | 0 | 0.00% | 0 | 0 | 0 | 0 | 0.00% |
| Ghostly Prison | 2 | 25.00% | 2 | 0 | 2 | 2 | 100.00% |
| Magus of the Moat | 0 | 0.00% | 0 | 0 | 0 | 0 | 0.00% |
| Silent Arbiter | 0 | 0.00% | 0 | 0 | 0 | 0 | 0.00% |
| Sphere of Safety | 0 | 0.00% | 0 | 0 | 0 | 0 | 0.00% |
| Windborn Muse | 0 | 0.00% | 0 | 0 | 0 | 0 | 0.00% |

## Opponent Detail

### baseline_v7

| Opponent | W | L | S | WR | Avg win turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 15.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 1 | 0 | 0 | 100.00% | 17.00 | elimination=1 |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

### without_ghostly_prison

| Opponent | W | L | S | WR | Avg win turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 1 | 0 | 0 | 100.00% | 17.00 | elimination=1 |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 0 | 0 | 100.00% | 12.00 | approach=1 |

## Method Notes

- `baseline_v7` uses the generated isolated candidate DB.
- Ablations keep deck size constant by replacing the target card with a blank in-memory slot.
- This measures slot utility versus a dead card, not the best possible replacement card.
- Draw telemetry counts final opening hand plus in-game draws by the Lorehold player.
- Cast telemetry uses `cost_paid`, so illegal/uncastable announcements are not counted as real casts.
- Package attack utility uses combat restriction events against Lorehold and requires a package card source when the runtime exposes `attack_restriction_sources`.
