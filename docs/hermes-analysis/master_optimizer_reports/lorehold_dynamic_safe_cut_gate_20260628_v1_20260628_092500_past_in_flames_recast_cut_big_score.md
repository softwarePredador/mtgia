# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T07:40:43Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `2`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `20260628`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_dynamic_safe_cut_gate_20260628_v1_20260628_092500_past_in_flames_recast_cut_big_score_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real), Kenrith, the Returned King #113 (real), Aang, at the Crossroads #106 (real), Umbris, Fear Manifest #114 (real), Rograkh, Son of Rohgahh #62 (real), Tannuk, Memorial Ensign #40 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 16 | 4 | 12 | 0 | 25.00% | 11.50 | 10 | 6 | 2 | 4 | 4 | 4 | 0 | 14 | 7 | 0 | unattributed: events=7, restricted=7, tax=0 | wincon_role |
| 2 |  | Lorehold synergy package: past_in_flames_recast_cut_big_score (`synergy_past_in_flames_recast_cut_big_score`) | synergy-package | 16 | 1 | 15 | 0 | 6.25% | 17.00 | 5 | 3 | 3 | 1 | 0 | 0 | 0 | 12 | 0 | 0 | none | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `4W/12L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 2 | 0 | 0 | 100.00% | 11.50 | elimination=2 |
| Rograkh, Son of Rohgahh #62 (real) | 1 | 1 | 0 | 50.00% | 11.00 | elimination=1 |
| Tannuk, Memorial Ensign #40 (real) | 1 | 1 | 0 | 50.00% | 12.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=12, graveyard_upkeep_return_self_to_hand=15, lorehold_cost_paid=148, lorehold_rummage_discard_to_top=9, lorehold_rummage_discards_squee=8, lorehold_spell_cast=123, lorehold_spell_rummage=15, lorehold_spell_rummage_discard_to_top=3, lorehold_spell_rummage_discards_squee=7, lorehold_upkeep_rummage=63, miracle_cast=22, squee_return_after_known_graveyard_entry=15, squee_to_graveyard=17, squee_upkeep_return=15, topdeck_manipulation_activated=15

**Lorehold attack restriction telemetry:** events=7, attackers_before=24, attackers_after=17, attackers_restricted=7, tax_paid=0, sources=unattributed: events=7, restricted=7, tax=0

### 2. Lorehold synergy package: past_in_flames_recast_cut_big_score (`synergy_past_in_flames_recast_cut_big_score`)

- objective: not available in structural matrix
- result: `1W/15L/0S`, WR `6.25%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `17`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Sisay, Weatherlight Captain #61 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Kenrith, the Returned King #113 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Aang, at the Crossroads #106 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Umbris, Fear Manifest #114 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Rograkh, Son of Rohgahh #62 (real) | 0 | 2 | 0 | 0.00% | 0.00 |  |
| Tannuk, Memorial Ensign #40 (real) | 1 | 1 | 0 | 50.00% | 17.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=28, lorehold_cost_paid=142, lorehold_rummage_discard_to_top=24, lorehold_rummage_discards_squee=1, lorehold_spell_cast=114, lorehold_spell_rummage=7, lorehold_spell_rummage_discard_to_top=4, lorehold_upkeep_rummage=56, miracle_cast=10, squee_to_graveyard=1, thor_cost_paid=1, thor_spell_cast=1, topdeck_manipulation_activated=13

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
