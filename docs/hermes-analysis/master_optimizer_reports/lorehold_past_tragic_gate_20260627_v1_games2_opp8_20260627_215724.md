# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T21:57:50.191573+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `2`
- opponent_limit: `8`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `False`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json`
- prior_package_reports: `-`
- package_status_counts: `{"gated": 1}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| core_challenge_past_over_tragic | payoff_challenge | Past in Flames | Tragic Arrogance | `clear` | 3/13/0 `18.75%` | 5/11/0 `31.25%` | +12.50 | cost +37, spell +40, spell mana +0, birgi mana +0, ritual -3, miracle +4, tutor +8, random discard -1, topdeck +0, discard-to-top +2, rummage-to-top -5, spell-rummage-to-top +7, hand to top +0, spell rummage +10, squee gy +1, squee return +1, squee explained +1 | promote_to_deeper_gate |

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
- candidate_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_past_tragic_gate_20260627_v1_games2_opp8_20260627_215724_core_challenge_past_over_tragic/knowledge_candidate.db`
- gate_markdown: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_past_tragic_gate_20260627_v1_games2_opp8_20260627_215724_core_challenge_past_over_tragic.md`
- gate_json: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_past_tragic_gate_20260627_v1_games2_opp8_20260627_215724_core_challenge_past_over_tragic.json`
- gate_returncode: `0`
