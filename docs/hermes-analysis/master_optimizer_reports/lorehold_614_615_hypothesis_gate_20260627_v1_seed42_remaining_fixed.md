# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T20:09:40.020014+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"gated": 3}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| dragon_rage_channeler_cut_scarlet_witch | topdeck_filter | Dragon's Rage Channeler | The Scarlet Witch | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -40, spell -37, spell mana +0, birgi mana +0, ritual -1, miracle -13, tutor -6, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy +1, squee return +1, squee explained +1 | reject_or_rework |
| grand_abolisher_cut_mother_of_runes | spell_protection | Grand Abolisher | Mother of Runes | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -46, spell -39, spell mana +0, birgi mana +0, ritual -1, miracle -13, tutor -7, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| reprieve_cut_avatar_wrath | spell_protection | Reprieve | Avatar's Wrath | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -25, spell -26, spell mana +0, birgi mana +0, ritual -1, miracle -8, tutor -4, random discard -1, topdeck -6, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -11, squee gy +1, squee return +1, squee explained +1 | reject_or_rework |

## Package Notes

### dragon_rage_channeler_cut_scarlet_witch

- family: topdeck_filter
- hypothesis: Dragon's Rage Channeler is a low-cost 614 topdeck/filter engine with active local battle rules. It targets seed 7's missing early engine by challenging The Scarlet Witch, a materialization-sensitive slot.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `The Scarlet Witch`
- added_rule_counts: `{"Dragon's Rage Channeler": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_dragon_rage_channeler_cut_scarlet_witch/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_dragon_rage_channeler_cut_scarlet_witch.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_dragon_rage_channeler_cut_scarlet_witch.json`
- gate_returncode: `0`

### grand_abolisher_cut_mother_of_runes

- family: spell_protection
- hypothesis: Grand Abolisher protects the whole decisive turn and appears in 615. Mother of Runes is the same-creature-protection comparison slot, so this is a risky same-lane test rather than a generic support cut.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Grand Abolisher": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_grand_abolisher_cut_mother_of_runes/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_grand_abolisher_cut_mother_of_runes.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_grand_abolisher_cut_mother_of_runes.json`
- gate_returncode: `0`

### reprieve_cut_avatar_wrath

- family: spell_protection
- hypothesis: Reprieve is a 615 tempo/protection card with active local battle rules. It can buy a turn and draw without cutting cards already locked by the seed-42 protection pattern.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Avatar's Wrath`
- added_rule_counts: `{"Reprieve": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_reprieve_cut_avatar_wrath/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_reprieve_cut_avatar_wrath.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed_reprieve_cut_avatar_wrath.json`
- gate_returncode: `0`
