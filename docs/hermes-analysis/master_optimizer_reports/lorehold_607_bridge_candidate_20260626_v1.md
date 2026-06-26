# Lorehold 607 Bridge Candidate v1

- generated_at: `2026-06-26T16:43:06.782677+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg243_strategy_first_v7/knowledge_candidate.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_candidate_20260626_v1/knowledge_candidate.db`
- candidate_hash: `cfa1c7421f318c379fda6f33068a03b6265d2937dfdc34fa075d906f4bea9697`
- strategy_version: `lorehold_strategy_profile_v1_2026_06_26`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Start from the battle-winning `deck_607` shell, keep its pressure/removal density, and import only a compact v7 package that targets the known `deck_607` risks: tutor density, graveyard recursion, and spell-chain conversion.

## Swaps

| In from v7 | Out from 607 | Rationale |
| --- | --- | --- |
| Aetherflux Reservoir | Bender's Waterskin | adds a compact spell-chain finisher |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | Emeria's Call // Emeria, Shattered Skyclave | adds mana/hand engine without cutting removal |
| Enlightened Tutor | Library of Leng | addresses tutor shortfall and finds key artifacts/enchantments |
| Gamble | Molecule Man | adds cheap tutor density |
| Past in Flames | The Scarlet Witch | addresses recursion shortfall for spell-chain recovery |
| Storm-Kiln Artist | Tragic Arrogance | adds mana conversion and wincon pressure from spell volume |

## Counts

- rows: `94`
- quantity_total: `100`
- lands: `34`
- nonlands: `66`

### Role Counts

- `approach`: 1
- `board_wipe`: 6
- `creature`: 3
- `damage_wipe`: 2
- `draw`: 13
- `engine`: 5
- `equipment_haste_shroud`: 1
- `equipment_static_attachment`: 1
- `exile_value`: 1
- `land`: 34
- `land_tax`: 1
- `mana_development`: 1
- `overload_recursion`: 1
- `passive`: 3
- `protection`: 10
- `pump_all`: 1
- `ramp`: 18
- `recursion`: 1
- `redirect_removal`: 1
- `removal`: 11
- `steal_all_creatures`: 1
- `token_maker`: 4
- `treasure_maker`: 3
- `tutor`: 3
- `unknown`: 5
- `wincon`: 11
- `wipe`: 6

### Strategy Package Counts

- `deterministic_finisher`: 11
- `early_plan`: 37
- `graveyard_recursion`: 8
- `hand_filter`: 16
- `pressure_absorber`: 19
- `protection_window`: 15
- `spell_chain_conversion`: 44
- `topdeck_miracle_setup`: 10
