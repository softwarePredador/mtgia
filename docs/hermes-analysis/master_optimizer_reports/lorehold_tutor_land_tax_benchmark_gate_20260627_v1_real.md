# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T00:02:06.992787+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"gated": 2}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gamble_access_benchmark_cut_land_tax | tutor_access_benchmark | Gamble | Land Tax | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -25, spell -21, spell mana +0, birgi mana +0, ritual +0, miracle -10, tutor -1, random discard +1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -4, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| enlightened_access_benchmark_cut_land_tax | tutor_access_benchmark | Enlightened Tutor | Land Tax | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -29, spell -24, spell mana +0, birgi mana +0, ritual +1, miracle +0, tutor -4, random discard -1, topdeck -3, discard-to-top +9, rummage-to-top +9, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### gamble_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. This is not a promotion candidate by itself: it tests whether Gamble's any-card access can outperform Land Tax's upkeep basic-land access without repeating the failed Thor or Creative Technique cuts.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Gamble": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_gamble_access_benchmark_cut_land_tax/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_gamble_access_benchmark_cut_land_tax.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_gamble_access_benchmark_cut_land_tax.json`
- gate_returncode: `0`

### enlightened_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. Enlightened Tutor is the lower-randomness comparison: it cannot find Approach directly, but it can put artifact/enchantment engines on top for Lorehold's miracle draw window while preserving the failed Thor and Creative Technique slots.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Enlightened Tutor": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_enlightened_access_benchmark_cut_land_tax/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_enlightened_access_benchmark_cut_land_tax.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_enlightened_access_benchmark_cut_land_tax.json`
- gate_returncode: `0`
