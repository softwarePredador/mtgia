# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T21:53:54.307663+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `7`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| overmaster_protect_draw_cut_tibalts_trickery | spell_protection | Overmaster | Tibalt's Trickery | `clear` | 1/7/0 `12.50%` | 3/5/0 `37.50%` | +25.00 | cost +50, spell +47, spell mana +0, birgi mana +0, ritual -1, miracle +6, tutor -11, random discard +1, topdeck +9, discard-to-top -16, rummage-to-top -8, spell-rummage-to-top -8, hand to top +0, spell rummage +2, squee gy +0, squee return +0, squee explained +0 | promote_to_deeper_gate |

## Package Notes

### overmaster_protect_draw_cut_tibalts_trickery

- family: spell_protection
- hypothesis: Overmaster protects a decisive instant or sorcery and replaces itself. This tests the spell-protection lane while keeping Hexing Squelcher and the known protection shell intact, comparing against a swingy protection/counter slot instead.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Overmaster": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_overmaster_tibalt_gate_20260627_v3_seed7_smoke_opp8_20260627_215341_overmaster_protect_draw_cut_tibalts_trickery/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_overmaster_tibalt_gate_20260627_v3_seed7_smoke_opp8_20260627_215341_overmaster_protect_draw_cut_tibalts_trickery.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_overmaster_tibalt_gate_20260627_v3_seed7_smoke_opp8_20260627_215341_overmaster_protect_draw_cut_tibalts_trickery.json`
- gate_returncode: `0`
