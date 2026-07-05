# Lorehold Equal Battle Gate

- generated_at: `2026-07-05T15:23:04Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `8`
- opponent_kind: `real`
- opponent_seed: `2026070502`
- fixed_opponent_deck_ids: `none`
- simulation_seed: `2026070502`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8_seed2026070502_game_checkpoint.json`
- opponents: `Lumra, Bellow of the Woods #49 (real), Grist, the Hunger Tide #66 (real), Sisay, Weatherlight Captain #61 (real), Najeela, the Blade-Blossom #111 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 32 | 12 | 20 | 0 | 37.50% | 15.75 | 20 | 10 | 4 | 0 | 0 | 0 | 0 | 22 | 0 | 0 | none | draw_role, recursion_role, tutor_role |
| 2 | 2 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 32 | 8 | 24 | 0 | 25.00% | 11.00 | 18 | 8 | 8 | 0 | 0 | 0 | 0 | 26 | 0 | 0 | none | removal_role, recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `12W/20L/0S`, WR `37.50%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Lumra, Bellow of the Woods #49 (real) | 0 | 8 | 0 | 0.00% | 0.00 |  |
| Grist, the Hunger Tide #66 (real) | 5 | 3 | 0 | 62.50% | 15.60 | approach=2, elimination=3 |
| Sisay, Weatherlight Captain #61 (real) | 3 | 5 | 0 | 37.50% | 16.67 | elimination=3 |
| Najeela, the Blade-Blossom #111 (real) | 4 | 4 | 0 | 50.00% | 15.25 | approach=2, elimination=2 |

**Strategic event counts:** discard_to_top_replacement=28, lorehold_cost_paid=348, lorehold_rummage_discard_to_top=7, lorehold_spell_cast=301, lorehold_spell_rummage=36, lorehold_spell_rummage_discard_to_top=21, lorehold_upkeep_rummage=112, miracle_cast=69, scarlet_static_cost_reduction_casts=7, scarlet_static_cost_reduction_total=13, static_cost_reduction_casts=47, static_cost_reduction_total=90, thor_cost_paid=3, thor_noncreature_damage=4, thor_noncreature_damage_amount=20, thor_spell_cast=1, topdeck_manipulation_activated=38

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
### 2. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `8W/24L/0S`, WR `25.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Lumra, Bellow of the Woods #49 (real) | 2 | 6 | 0 | 25.00% | 9.00 | approach=2 |
| Grist, the Hunger Tide #66 (real) | 1 | 7 | 0 | 12.50% | 13.00 | approach=1 |
| Sisay, Weatherlight Captain #61 (real) | 2 | 6 | 0 | 25.00% | 8.00 | approach=2 |
| Najeela, the Blade-Blossom #111 (real) | 3 | 5 | 0 | 37.50% | 13.67 | approach=1, elimination=2 |

**Strategic event counts:** birgi_spell_cast_mana=37, discard_to_top_replacement=54, lorehold_cost_paid=289, lorehold_rummage_discard_to_top=54, lorehold_spell_cast=239, lorehold_upkeep_rummage=156, miracle_cast=49, spell_cast_mana_trigger=37, static_cost_reduction_casts=2, static_cost_reduction_total=2, topdeck_manipulation_activated=22

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
