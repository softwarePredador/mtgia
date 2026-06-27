# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T17:25:40.358414+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| core_challenge_dance_over_storm | payoff_challenge | Dance with Calamity | Storm Herd | 8/1/0 `88.89%` | 0/9/0 `0.00%` | -88.89 | cost -82, spell -63, spell mana +0, birgi mana +0, miracle -22, topdeck -21, hand to top +0, spell rummage -14, squee gy -7, squee return -5, squee explained -5 | reject_or_rework |
| core_challenge_aetherflux_over_storm | payoff_challenge | Aetherflux Reservoir | Storm Herd | 8/1/0 `88.89%` | 2/7/0 `22.22%` | -66.67 | cost -53, spell -40, spell mana +0, birgi mana +0, miracle -22, topdeck -20, hand to top +0, spell rummage -19, squee gy -4, squee return -3, squee explained -3 | reject_or_rework |

## Package Notes

### core_challenge_dance_over_storm

- family: payoff_challenge
- hypothesis: Dance with Calamity is an expensive sorcery payoff that may produce more immediate wins than Storm Herd when miracle makes it cheap.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Storm Herd`
- added_rule_counts: `{"Dance with Calamity": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm.json`
- gate_returncode: `0`

### core_challenge_aetherflux_over_storm

- family: payoff_challenge
- hypothesis: Aetherflux Reservoir may convert Lorehold's spell-chain turns into a deterministic life-gain and 50-damage finish while preserving the expensive instant/sorcery package outside the Storm Herd slot.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Storm Herd`
- added_rule_counts: `{"Aetherflux Reservoir": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge_core_challenge_aetherflux_over_storm/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge_core_challenge_aetherflux_over_storm.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge_core_challenge_aetherflux_over_storm.json`
- gate_returncode: `0`
