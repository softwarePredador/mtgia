# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T16:10:11.637701+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| birgi_spellchain_cut_squelcher | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Hexing Squelcher | 8/1/0 `88.89%` | 3/6/0 `33.33%` | -55.56 | cost -44, spell -43, spell mana +7, birgi mana +7, miracle -16, topdeck -19, hand to top +0, spell rummage -9, squee gy -3, squee return -2, squee explained -2 | reject_or_rework |
| galvanoth_topdeck_freecast_cut_squelcher | topdeck_freecast | Galvanoth | Hexing Squelcher | 8/1/0 `88.89%` | 2/7/0 `22.22%` | -66.67 | cost -48, spell -36, spell mana +0, birgi mana +0, miracle -16, topdeck -9, hand to top +0, spell rummage -12, squee gy -4, squee return -4, squee explained -4 | reject_or_rework |
| penance_topdeck_protection_cut_squelcher | topdeck_protection | Penance | Hexing Squelcher | 8/1/0 `88.89%` | 4/5/0 `44.44%` | -44.45 | cost -18, spell -1, spell mana +0, birgi mana +0, miracle -6, topdeck -16, hand to top +0, spell rummage +0, squee gy -6, squee return -5, squee explained -5 | reject_or_rework |

## Package Notes

### birgi_spellchain_cut_squelcher

- family: spellchain_mana
- hypothesis: Birgi adds red mana on every spell cast, which should help Lorehold chain miracle spells without cutting the expensive spell package.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Birgi, God of Storytelling // Harnfel, Horn of Bounty": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_birgi_spellchain_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_birgi_spellchain_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_birgi_spellchain_cut_squelcher.json`
- gate_returncode: `0`

### galvanoth_topdeck_freecast_cut_squelcher

- family: topdeck_freecast
- hypothesis: Galvanoth was aggregate-positive but failed the seed-42 success case when it cut Bender's Waterskin. This retest preserves the ramp shell and cuts the narrower anti-counter creature instead.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Galvanoth": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_galvanoth_topdeck_freecast_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_galvanoth_topdeck_freecast_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_galvanoth_topdeck_freecast_cut_squelcher.json`
- gate_returncode: `0`

### penance_topdeck_protection_cut_squelcher

- family: topdeck_protection
- hypothesis: Penance gives an executable hand-to-library topdeck line plus combat damage prevention. It tests topdeck consistency without relying on land-only placeholder rules such as The Biblioplex or Mirrorpool.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Penance": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_penance_topdeck_protection_cut_squelcher/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_penance_topdeck_protection_cut_squelcher.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout_penance_topdeck_protection_cut_squelcher.json`
- gate_returncode: `0`
