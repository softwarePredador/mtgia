# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T22:06:16.416904+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `99`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| core_challenge_past_over_tragic | payoff_challenge | Past in Flames | Tragic Arrogance | `clear` | 5/3/0 `62.50%` | 2/6/0 `25.00%` | -37.50 | cost -4, spell -7, spell mana +0, birgi mana +0, ritual -1, miracle -2, tutor +9, random discard +2, topdeck -9, discard-to-top +0, rummage-to-top +0, spell-rummage-to-top +0, hand to top +0, spell rummage +7, squee gy -2, squee return -2, squee explained -2 | reject_or_rework |

## Package Notes

### core_challenge_past_over_tragic

- family: payoff_challenge
- hypothesis: Past in Flames may be a stronger spell-chain payoff than a generic five-mana cleanup sorcery in the current shell.
- status: `gated`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "prior package evidence disabled", "status": "not_checked"}`
- allow_miracle_core_cuts: `True`
- miracle_core_cuts: `Tragic Arrogance`
- added_rule_counts: `{"Past in Flames": 1}`
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_past_tragic_gate_20260627_v3_seed99_smoke_opp8_20260627_220604_core_challenge_past_over_tragic/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_past_tragic_gate_20260627_v3_seed99_smoke_opp8_20260627_220604_core_challenge_past_over_tragic.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_past_tragic_gate_20260627_v3_seed99_smoke_opp8_20260627_220604_core_challenge_past_over_tragic.json`
- gate_returncode: `0`
