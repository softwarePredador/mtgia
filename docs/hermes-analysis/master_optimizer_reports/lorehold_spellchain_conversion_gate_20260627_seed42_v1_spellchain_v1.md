# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:18:51.138944+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| birgi_seething_chain_cut_medallions | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Seething Song | Pearl Medallion, Ruby Medallion | 8/1/0 `88.89%` | 3/6/0 `33.33%` | -55.56 | cost -22, spell -27, spell mana +15, birgi mana +15, miracle -15, topdeck -8, discard-to-top -7, rummage-to-top -8, spell-rummage-to-top +1, hand to top +0, spell rummage -6, squee gy -5, squee return -4, squee explained -4 | reject_or_rework |

## Package Notes

### birgi_seething_chain_cut_medallions

- family: spellchain_mana
- hypothesis: The loss classifier shows mana/spell-volume failures under pressure. This imports the narrow 615 ritual lane while preserving Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, and the three-mana ramp shell; it tests whether cast-trigger mana plus a one-shot ritual beats static red/white medallion discounts.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Birgi, God of Storytelling // Harnfel, Horn of Bounty": 1, "Seething Song": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed42_v1_spellchain_v1_birgi_seething_chain_cut_medallions/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed42_v1_spellchain_v1_birgi_seething_chain_cut_medallions.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed42_v1_spellchain_v1_birgi_seething_chain_cut_medallions.json`
- gate_returncode: `0`
