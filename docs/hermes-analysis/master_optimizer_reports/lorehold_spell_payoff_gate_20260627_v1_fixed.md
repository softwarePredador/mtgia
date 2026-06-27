# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T20:53:29.444819+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"gated": 3}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| guttersnipe_spell_payoff_cut_prismari | spellcast_payoff | Guttersnipe | Prismari Pianist | `clear` | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | cost -39, spell -35, spell mana +0, birgi mana +0, ritual +2, miracle -10, tutor -4, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -10, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| monastery_mentor_spell_tokens_cut_prismari | spellcast_payoff | Monastery Mentor | Prismari Pianist | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -42, spell -34, spell mana +0, birgi mana +0, ritual +0, miracle -8, tutor -4, random discard -1, topdeck -12, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |
| young_pyromancer_spell_tokens_cut_prismari | spellcast_payoff | Young Pyromancer | Prismari Pianist | `clear` | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | cost -35, spell -33, spell mana +0, birgi mana +0, ritual +1, miracle -7, tutor -6, random discard -1, topdeck -8, discard-to-top +3, rummage-to-top +3, spell-rummage-to-top +0, hand to top +0, spell rummage -12, squee gy -1, squee return +0, squee explained +0 | reject_or_rework |

## Package Notes

### guttersnipe_spell_payoff_cut_prismari

- family: spellcast_payoff
- hypothesis: Guttersnipe is present in Lorehold variants 615/616 and gives direct multiplayer damage on every instant or sorcery. This tests whether a lower-curve spell payoff converts miracle/topdeck turns better than Prismari Pianist without cutting the protected ramp, pressure, or finisher shell.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Prismari Pianist`
- added_rule_counts: `{"Guttersnipe": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_guttersnipe_spell_payoff_cut_prismari/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_guttersnipe_spell_payoff_cut_prismari.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_guttersnipe_spell_payoff_cut_prismari.json`
- gate_returncode: `0`

### monastery_mentor_spell_tokens_cut_prismari

- family: spellcast_payoff
- hypothesis: Monastery Mentor is present in Lorehold variant 616 and turns each noncreature spell into a growing board. This checks whether a token payoff survives combat pressure while converting Lorehold's miracle spell volume better than Prismari Pianist.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Prismari Pianist`
- added_rule_counts: `{"Monastery Mentor": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_monastery_mentor_spell_tokens_cut_prismari/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_monastery_mentor_spell_tokens_cut_prismari.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_monastery_mentor_spell_tokens_cut_prismari.json`
- gate_returncode: `0`

### young_pyromancer_spell_tokens_cut_prismari

- family: spellcast_payoff
- hypothesis: Young Pyromancer is present in Lorehold variant 616 and creates board presence from instant/sorcery casts at two mana. This tests the same payoff lane at the lowest curve point while leaving the known topdeck and protection shell untouched.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Prismari Pianist`
- added_rule_counts: `{"Young Pyromancer": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_young_pyromancer_spell_tokens_cut_prismari/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_young_pyromancer_spell_tokens_cut_prismari.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spell_payoff_gate_20260627_v1_fixed_young_pyromancer_spell_tokens_cut_prismari.json`
- gate_returncode: `0`
