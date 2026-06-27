# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T21:52:48.960966+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| overmaster_protect_draw_cut_tibalts_trickery | spell_protection | Overmaster | Tibalt's Trickery | `clear` | 2/6/0 `25.00%` | 4/4/0 `50.00%` | +25.00 | cost +76, spell +60, spell mana +0, birgi mana +0, ritual -1, miracle +18, tutor +5, random discard +1, topdeck +26, discard-to-top +20, rummage-to-top +7, spell-rummage-to-top +13, hand to top +0, spell rummage +20, squee gy +7, squee return +7, squee explained +6 | promote_to_deeper_gate |

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
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_overmaster_tibalt_gate_20260627_v2_smoke_opp8_20260627_215233_overmaster_protect_draw_cut_tibalts_trickery/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_overmaster_tibalt_gate_20260627_v2_smoke_opp8_20260627_215233_overmaster_protect_draw_cut_tibalts_trickery.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_overmaster_tibalt_gate_20260627_v2_smoke_opp8_20260627_215233_overmaster_protect_draw_cut_tibalts_trickery.json`
- gate_returncode: `0`
