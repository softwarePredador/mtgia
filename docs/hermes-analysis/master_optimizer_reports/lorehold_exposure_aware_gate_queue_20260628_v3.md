# Lorehold Exposure-Aware Gate Queue - 2026-06-28

- Generated at: `2026-06-28T10:21:44Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Readiness report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260628_v1.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json`
- Planner: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260628_v16_current_default_chain.json`
- Cut safety report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v3_runtime_readiness.json`

## Summary

- Packages reviewed: `14`
- Status counts: `{"blocked_added_card_readiness": 2, "blocked_cut_safety": 6, "blocked_hypothesis_queue_prior_negative": 2, "blocked_prior_evidence": 4}`
- Ready packages: `0`
- Natural gate ready: `0`
- Forced-exposure diagnostic ready: `0`
- Recommended next action: `no_package_ready; build_new_failure_targeted_package_or_cut_model`

## Ready Queue

- No package is ready for execution.

## Blocked Queue

| Package | Status | Adds | Cuts | Blockers |
| --- | --- | --- | --- | --- |
| `pg245_twinflame_damage_payoff_cut_thor` | `blocked_added_card_readiness` | `Twinflame Tyrant` | `Thor, God of Thunder` | `added_card_readiness_blocked`, `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `pg245_verge_rangers_topdeck_land_cut_waterskin` | `blocked_added_card_readiness` | `Verge Rangers` | `Bender's Waterskin` | `added_card_readiness_blocked`, `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `dragon_rage_channeler_cut_scarlet_witch` | `blocked_cut_safety` | `Dragon's Rage Channeler` | `The Scarlet Witch` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `guttersnipe_spell_payoff_cut_prismari` | `blocked_cut_safety` | `Guttersnipe` | `Prismari Pianist` | `cut_safety_blocked`, `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `lapse_approach_topdeck_cut_tibalts_trickery` | `blocked_cut_safety` | `Lapse of Certainty` | `Tibalt's Trickery` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `monastery_mentor_spell_tokens_cut_prismari` | `blocked_cut_safety` | `Monastery Mentor` | `Prismari Pianist` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `radiant_scrollwielder_cut_scarlet_witch` | `blocked_cut_safety` | `Radiant Scrollwielder` | `The Scarlet Witch` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `young_pyromancer_spell_tokens_cut_prismari` | `blocked_cut_safety` | `Young Pyromancer` | `Prismari Pianist` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `akromas_will_cut_avatar_wrath` | `blocked_prior_evidence` | `Akroma's Will` | `Avatar's Wrath` | `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `grand_abolisher_cut_mother_of_runes` | `blocked_prior_evidence` | `Grand Abolisher` | `Mother of Runes` | `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `mana_vault_fast_mana_cut_arcane_signet` | `blocked_prior_evidence` | `Mana Vault` | `Arcane Signet` | `prior_natural_confirmation_reject` |
| `reprieve_cut_avatar_wrath` | `blocked_prior_evidence` | `Reprieve` | `Avatar's Wrath` | `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `perch_protection_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Perch Protection` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
| `silence_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Silence` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
