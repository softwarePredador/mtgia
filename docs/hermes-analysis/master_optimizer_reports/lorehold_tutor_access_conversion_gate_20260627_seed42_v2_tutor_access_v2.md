# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:49:36.747073+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| enlightened_engine_access_cut_thor | tutor_access | Enlightened Tutor | Thor, God of Thunder | 8/1/0 `88.89%` | 4/5/0 `44.44%` | -44.45 | cost -55, spell -43, spell mana +0, birgi mana +0, ritual -5, miracle -15, tutor -3, random discard +0, topdeck -21, discard-to-top -9, rummage-to-top -6, spell-rummage-to-top -3, hand to top +0, spell rummage -19, squee gy -7, squee return -5, squee explained -5 | reject_or_rework |

## Package Notes

### enlightened_engine_access_cut_thor

- family: tutor_access
- hypothesis: Enlightened Tutor tests a lower-risk access line than Gamble: it cannot find Approach, but it can put artifact/enchantment engines on top for Lorehold and miracle setup without random discard. Thor is the cut for the same modeled-not-proven reason as the Gamble retest.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Enlightened Tutor": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_tutor_access_v2_enlightened_engine_access_cut_thor/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_tutor_access_v2_enlightened_engine_access_cut_thor.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_tutor_access_v2_enlightened_engine_access_cut_thor.json`
- gate_returncode: `0`
