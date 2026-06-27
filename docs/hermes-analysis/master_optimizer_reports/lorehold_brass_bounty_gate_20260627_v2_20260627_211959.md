# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T21:20:05.611345+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| brass_bounty_cut_boros_signet | spellchain_mana | Brass's Bounty | Boros Signet | `clear` | 3/0/0 `100.00%` | 3/0/0 `100.00%` | +0.00 | cost +0, spell +0, spell mana +0, birgi mana +0, ritual +0, miracle +0, tutor +0, random discard +0, topdeck +0, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage +0, squee gy +0, squee return +0, squee explained +0 | tie_promote_to_deeper_gate |

## Package Notes

### brass_bounty_cut_boros_signet

- family: spellchain_mana
- hypothesis: Brass's Bounty is shared by six Lorehold variants and now has a reviewed runtime model that creates Treasure equal to lands controlled. This tests whether a late ritual/treasure burst is better than the least-blocked two-mana Boros rock without cutting Sol Ring, Bender's Waterskin, medallions, Victory Chimes, or the protection/finisher shell.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous exact package result", "status": "clear"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Brass's Bounty": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v2_20260627_211959_brass_bounty_cut_boros_signet/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v2_20260627_211959_brass_bounty_cut_boros_signet.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v2_20260627_211959_brass_bounty_cut_boros_signet.json`
- gate_returncode: `0`
