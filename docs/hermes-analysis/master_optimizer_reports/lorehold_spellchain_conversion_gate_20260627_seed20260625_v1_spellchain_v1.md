# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T18:18:49.201214+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `20260625`

| Package | Family | Adds | Cuts | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| birgi_seething_chain_cut_medallions | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Seething Song | Pearl Medallion, Ruby Medallion | 0/9/0 `0.00%` | 3/6/0 `33.33%` | +33.33 | cost +8, spell +8, spell mana +0, birgi mana +0, miracle +5, topdeck +8, discard-to-top -5, rummage-to-top -5, spell-rummage-to-top +0, hand to top +0, spell rummage -2, squee gy +1, squee return +1, squee explained +1 | promote_to_deeper_gate |

## Package Notes

### birgi_seething_chain_cut_medallions

- family: spellchain_mana
- hypothesis: The loss classifier shows mana/spell-volume failures under pressure. This imports the narrow 615 ritual lane while preserving Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, and the three-mana ramp shell; it tests whether cast-trigger mana plus a one-shot ritual beats static red/white medallion discounts.
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Birgi, God of Storytelling // Harnfel, Horn of Bounty": 1, "Seething Song": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed20260625_v1_spellchain_v1_birgi_seething_chain_cut_medallions/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed20260625_v1_spellchain_v1_birgi_seething_chain_cut_medallions.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_conversion_gate_20260627_seed20260625_v1_spellchain_v1_birgi_seething_chain_cut_medallions.json`
- gate_returncode: `0`
