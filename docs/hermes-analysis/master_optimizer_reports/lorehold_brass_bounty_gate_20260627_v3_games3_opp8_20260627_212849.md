# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T21:29:30.528755+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `3`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| brass_bounty_cut_boros_signet | spellchain_mana | Brass's Bounty | Boros Signet | `clear` | 9/15/0 `37.50%` | 11/13/0 `45.83%` | +8.33 | cost +15, spell +8, spell mana +0, birgi mana +0, ritual +3, miracle +26, tutor -8, random discard +1, topdeck +14, discard-to-top +43, rummage-to-top +32, spell-rummage-to-top +11, hand to top +0, spell rummage +18, squee gy +6, squee return +6, squee explained +6 | promote_to_deeper_gate |

## Package Notes

### brass_bounty_cut_boros_signet

- family: spellchain_mana
- hypothesis: Brass's Bounty is shared by six Lorehold variants and now has a reviewed runtime model that creates Treasure equal to lands controlled. This tests whether a late ritual/treasure burst is better than the least-blocked two-mana Boros rock without cutting Sol Ring, Bender's Waterskin, medallions, Victory Chimes, or the protection/finisher shell.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `False`
- miracle_core_cuts: `-`
- added_rule_counts: `{"Brass's Bounty": 2}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849_brass_bounty_cut_boros_signet/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849_brass_bounty_cut_boros_signet.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849_brass_bounty_cut_boros_signet.json`
- gate_returncode: `0`
