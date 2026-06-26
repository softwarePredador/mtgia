# Lorehold 607 Bridge Candidate v2

- generated_at: `2026-06-26T16:53:01.550551+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_pg243_strategy_first_v7/knowledge_candidate.db`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_candidate_20260626_v2/knowledge_candidate.db`
- candidate_hash: `5e43d57596007d0645f88ef72cca71b9288bf1538053bc9ea544832c17d79bda`
- strategy_version: `lorehold_strategy_profile_v1_2026_06_26`
- postgres_writes: `false`
- source_db_mutated: `false`

## Intent

Start from `deck_607` and test only two v7 payoff imports. This is a minimal bridge to check whether the v1 failure came from importing too large an engine/tutor package.

## Swaps

| In from v7 | Out from 607 | Rationale |
| --- | --- | --- |
| Aetherflux Reservoir | Molecule Man | adds a compact spell-chain finisher |
| Storm-Kiln Artist | The Scarlet Witch | adds mana conversion and wincon pressure from spell volume |

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
- `draw`: 12
- `engine`: 4
- `equipment_haste_shroud`: 1
- `equipment_static_attachment`: 1
- `exile_value`: 1
- `land`: 34
- `land_tax`: 1
- `mana_development`: 1
- `overload_recursion`: 1
- `passive`: 4
- `protection`: 10
- `pump_all`: 1
- `ramp`: 19
- `redirect_removal`: 1
- `removal`: 11
- `steal_all_creatures`: 1
- `token_maker`: 4
- `treasure_maker`: 3
- `tutor`: 1
- `unknown`: 7
- `wincon`: 11
- `wipe`: 6

### Strategy Package Counts

- `deterministic_finisher`: 11
- `early_plan`: 36
- `graveyard_recursion`: 8
- `hand_filter`: 14
- `pressure_absorber`: 19
- `protection_window`: 16
- `spell_chain_conversion`: 43
- `topdeck_miracle_setup`: 11
