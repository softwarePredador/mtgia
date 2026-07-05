# Lorehold Equal Battle Gate

- generated_at: `2026-07-05T15:08:30Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- games_per_opponent: `8`
- opponent_kind: `real`
- opponent_seed: `20260705`
- fixed_opponent_deck_ids: `none`
- simulation_seed: `20260705`
- python_hash_seed: `unset`
- deck_process_isolation: `True`
- game_timeout_seconds: `20.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8_game_checkpoint.json`
- opponents: `Thrasios, Triton Hero #54 (real), Rograkh, Son of Rohgahh #95 (real), Kinnan, Bonder Prodigy #92 (real), Korvold, Fae-Cursed King #41 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 32 | 14 | 18 | 0 | 43.75% | 15.29 | 25 | 16 | 7 | 0 | 0 | 0 | 0 | 26 | 0 | 0 | none | removal_role, recursion_role, tutor_role |
| 2 | 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 32 | 11 | 21 | 0 | 34.38% | 18.73 | 23 | 17 | 5 | 0 | 0 | 0 | 0 | 20 | 0 | 0 | none | draw_role, recursion_role, tutor_role |

## Deck Detail

### 1. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

- objective: Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.
- result: `14W/18L/0S`, WR `43.75%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `15`, removal `10`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #54 (real) | 5 | 3 | 0 | 62.50% | 15.60 | approach=2, elimination=3 |
| Rograkh, Son of Rohgahh #95 (real) | 3 | 5 | 0 | 37.50% | 15.00 | approach=1, elimination=2 |
| Kinnan, Bonder Prodigy #92 (real) | 1 | 7 | 0 | 12.50% | 21.00 | elimination=1 |
| Korvold, Fae-Cursed King #41 (real) | 5 | 3 | 0 | 62.50% | 14.00 | approach=1, elimination=4 |

**Strategic event counts:** birgi_spell_cast_mana=28, discard_to_top_replacement=39, lorehold_cost_paid=338, lorehold_rummage_discard_to_top=39, lorehold_spell_cast=292, lorehold_upkeep_rummage=138, miracle_cast=86, spell_cast_mana_trigger=28, static_cost_reduction_casts=1, static_cost_reduction_total=1, topdeck_manipulation_activated=70

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
### 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `11W/21L/0S`, WR `34.38%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `18`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Thrasios, Triton Hero #54 (real) | 4 | 4 | 0 | 50.00% | 22.25 | approach=1, elimination=3 |
| Rograkh, Son of Rohgahh #95 (real) | 2 | 6 | 0 | 25.00% | 14.50 | elimination=2 |
| Kinnan, Bonder Prodigy #92 (real) | 4 | 4 | 0 | 50.00% | 17.00 | elimination=4 |
| Korvold, Fae-Cursed King #41 (real) | 1 | 7 | 0 | 12.50% | 20.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=17, lorehold_cost_paid=377, lorehold_rummage_discard_to_top=17, lorehold_spell_cast=324, lorehold_spell_rummage=16, lorehold_upkeep_rummage=111, miracle_cast=62, scarlet_static_cost_reduction_casts=12, scarlet_static_cost_reduction_total=24, static_cost_reduction_casts=49, static_cost_reduction_total=99, thor_cost_paid=3, thor_noncreature_damage=3, thor_noncreature_damage_amount=14, topdeck_manipulation_activated=76

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
