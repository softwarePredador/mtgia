# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:50:10.444991+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| gamble_access_cut_thor | tutor_access | Gamble | Thor, God of Thunder | 8/1/0 `88.89%` | 3/6/0 `33.33%` | -55.56 | cost -43, spell -34, spell mana +0, birgi mana +0, ritual -3, miracle -16, tutor -2, random discard +3, topdeck -21, discard-to-top -9, rummage-to-top -6, spell-rummage-to-top -3, hand to top +0, spell rummage -19, squee gy -1, squee return -1, squee explained -1 | reject_or_rework |

## Package Notes

### gamble_access_cut_thor

- family: tutor_access
- hypothesis: Gamble improved weak seeds when it cut Creative Technique but broke seed 42. This retest keeps the modeled free-cast slot and instead cuts Thor, whose local runtime rule has natural exposure but no deck win-rate lift yet, while preserving Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, medallions, Bender's Waterskin, and the three-mana ramp shell.
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Gamble": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2_gamble_access_cut_thor/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2_gamble_access_cut_thor.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2_gamble_access_cut_thor.json`
- gate_returncode: `0`
