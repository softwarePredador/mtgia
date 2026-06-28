# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T07:48:44Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `90.0`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000_mana_vault_fast_mana_cut_arcane_signet_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real), Sisay, Weatherlight Captain #61 (real), Winota, Joiner of Forces #39 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 3 | 3 | 0 | 0 | 100.00% | 15.00 | 3 | 2 | 0 | 1 | 1 | 1 | 0 | 2 | 0 | 0 | none | wincon_role |
| 2 |  | Lorehold synergy package: mana_vault_fast_mana_cut_arcane_signet (`synergy_mana_vault_fast_mana_cut_arcane_signet`) | synergy-package | 3 | 1 | 2 | 0 | 33.33% | 15.00 | 2 | 2 | 1 | 1 | 1 | 1 | 0 | 3 | 0 | 0 | none | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `3W/0L/0S`, WR `100.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 17.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 1 | 0 | 0 | 100.00% | 14.00 | elimination=1 |
| Winota, Joiner of Forces #39 (real) | 1 | 0 | 0 | 100.00% | 14.00 | approach=1 |

**Strategic event counts:** graveyard_upkeep_return_self_to_hand=3, lorehold_cost_paid=61, lorehold_spell_cast=53, lorehold_spell_rummage=16, lorehold_spell_rummage_discards_squee=4, lorehold_upkeep_rummage=8, miracle_cast=13, squee_return_after_known_graveyard_entry=3, squee_to_graveyard=4, squee_upkeep_return=3, topdeck_manipulation_activated=12

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
### 2. Lorehold synergy package: mana_vault_fast_mana_cut_arcane_signet (`synergy_mana_vault_fast_mana_cut_arcane_signet`)

- objective: not available in structural matrix
- result: `1W/2L/0S`, WR `33.33%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 15.00 | elimination=1 |
| Sisay, Weatherlight Captain #61 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |
| Winota, Joiner of Forces #39 (real) | 0 | 1 | 0 | 0.00% | 0.00 |  |

**Strategic event counts:** discard_to_top_replacement=11, graveyard_upkeep_return_self_to_hand=3, lorehold_cost_paid=41, lorehold_rummage_discard_to_top=11, lorehold_rummage_discards_squee=2, lorehold_spell_cast=35, lorehold_upkeep_rummage=29, miracle_cast=9, squee_return_after_known_graveyard_entry=3, squee_to_graveyard=3, squee_upkeep_return=3, topdeck_manipulation_activated=12

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none
