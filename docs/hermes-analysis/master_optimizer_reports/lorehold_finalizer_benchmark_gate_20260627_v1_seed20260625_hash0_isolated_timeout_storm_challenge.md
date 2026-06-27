# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T17:26:34.156772+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `20260625`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| core_challenge_dance_over_storm | payoff_challenge | Dance with Calamity | Storm Herd | 0/9/0 `0.00%` | 4/5/0 `44.44%` | +44.44 | cost +60, spell +54, spell mana +0, birgi mana +0, miracle +20, topdeck +24, hand to top +0, spell rummage +0, squee gy +2, squee return +2, squee explained +2 | promote_to_deeper_gate |
| core_challenge_aetherflux_over_storm | payoff_challenge | Aetherflux Reservoir | Storm Herd | 0/9/0 `0.00%` | 2/7/0 `22.22%` | +22.22 | cost +23, spell +29, spell mana +0, birgi mana +0, miracle +11, topdeck +3, hand to top +0, spell rummage +5, squee gy +0, squee return +0, squee explained +0 | promote_to_deeper_gate |

## Package Notes

### core_challenge_dance_over_storm

- family: payoff_challenge
- hypothesis: Dance with Calamity is an expensive sorcery payoff that may produce more immediate wins than Storm Herd when miracle makes it cheap.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Storm Herd`
- added_rule_counts: `{"Dance with Calamity": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm.json`
- gate_returncode: `0`

### core_challenge_aetherflux_over_storm

- family: payoff_challenge
- hypothesis: Aetherflux Reservoir may convert Lorehold's spell-chain turns into a deterministic life-gain and 50-damage finish while preserving the expensive instant/sorcery package outside the Storm Herd slot.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Storm Herd`
- added_rule_counts: `{"Aetherflux Reservoir": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_aetherflux_over_storm/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_aetherflux_over_storm.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_aetherflux_over_storm.json`
- gate_returncode: `0`
