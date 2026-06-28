# Lorehold Equal Battle Gate

- generated_at: `2026-06-28T09:15:29Z`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- games_per_opponent: `1`
- opponent_kind: `real`
- opponent_seed: `20260626`
- simulation_seed: `42`
- python_hash_seed: `0`
- deck_process_isolation: `True`
- game_timeout_seconds: `30.0`
- forced_access_mode: `none`
- game_checkpoint_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_decision_contract_20260628_v1_20260628_190000_mana_vault_fast_mana_cut_arcane_signet_game_checkpoint.json`
- opponents: `Vivi Ornitier #99 (real)`
- postgres_writes: `false`
- source_db_mutated: `false`

## Battle Ranking

| Battle Rank | Structural Rank | Deck | Archetype | Games | W | L | S | WR | Avg Win Turn | Miracle Games | Topdeck Games | Discard-To-Top Games | Squee GY Games | Squee Return Games | Explained Return Games | Unexplained Return Games | Rummage Games | Lorehold Attackers Restricted | Attack Tax Paid | Restriction Sources | Main Risks |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 1 | 1 | 0 | 0 | 100.00% | 11.00 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | wincon_role |
| 2 |  | Lorehold synergy package: mana_vault_fast_mana_cut_arcane_signet (`synergy_mana_vault_fast_mana_cut_arcane_signet`) | synergy-package | 1 | 1 | 0 | 0 | 100.00% | 12.00 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | none | none |

## Deck Detail

### 1. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

- objective: Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.
- result: `1W/0L/0S`, WR `100.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 11.00 | elimination=1 |

**Strategic event counts:** lorehold_cost_paid=15, lorehold_spell_cast=9, lorehold_upkeep_rummage=4, miracle_cast=1, topdeck_manipulation_activated=4

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

### 2. Lorehold synergy package: mana_vault_fast_mana_cut_arcane_signet (`synergy_mana_vault_fast_mana_cut_arcane_signet`)

- objective: not available in structural matrix
- result: `1W/0L/0S`, WR `100.00%`
- construction_valid: `True`
- deck shape: size `100`, lands `34`, ramp `18`, removal `16`

| Opponent | W | L | S | WR | Avg Win Turn | Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vivi Ornitier #99 (real) | 1 | 0 | 0 | 100.00% | 12.00 | elimination=1 |

**Strategic event counts:** discard_to_top_replacement=4, lorehold_cost_paid=9, lorehold_rummage_discard_to_top=4, lorehold_spell_cast=7, lorehold_upkeep_rummage=5, miracle_cast=4

**Lorehold attack restriction telemetry:** events=0, attackers_before=0, attackers_after=0, attackers_restricted=0, tax_paid=0, sources=none

