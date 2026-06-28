# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T00:01:45.328733+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"preflight_ready": 2}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gamble_access_benchmark_cut_land_tax | tutor_access_benchmark | Gamble | Land Tax | `clear` | - | - | +0.00 | - | preflight_ready |
| enlightened_access_benchmark_cut_land_tax | tutor_access_benchmark | Enlightened Tutor | Land Tax | `clear` | - | - | +0.00 | - | preflight_ready |

## Package Notes

### gamble_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. This is not a promotion candidate by itself: it tests whether Gamble's any-card access can outperform Land Tax's upkeep basic-land access without repeating the failed Thor or Creative Technique cuts.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### enlightened_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. Enlightened Tutor is the lower-randomness comparison: it cannot find Approach directly, but it can put artifact/enchantment engines on top for Lorehold's miracle draw window while preserving the failed Thor and Creative Technique slots.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
