# Lorehold Exposure-Aware Gate Queue - 2026-06-28

- Generated at: `2026-06-28T10:03:42Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Packages reviewed: `14`
- Status counts: `{"blocked_added_card_readiness": 2, "blocked_cut_safety": 6, "blocked_hypothesis_queue_prior_negative": 2, "blocked_prior_evidence": 3, "forced_exposure_probe_ready": 1}`
- Ready packages: `1`
- Natural gate ready: `0`
- Forced-exposure diagnostic ready: `1`
- Recommended next action: `run_forced_exposure_probe_before_natural_gate`

## Ready Queue

| Rank | Package | Status | Adds | Cuts | Promotion allowed | Command |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `mana_vault_fast_mana_cut_arcane_signet` | `forced_exposure_probe_ready` | `Mana Vault` | `Arcane Signet` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages mana_vault_fast_mana_cut_arcane_signet --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260628_v2_execute_run --forced-access-mode opening_hand` |

## Executed

| Package | Return code | Child JSON | Child Markdown |
| --- | ---: | --- | --- |
| `mana_vault_fast_mana_cut_arcane_signet` | 0 | `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_aware_gate_queue_20260628_v2_execute_run_20260628_100342.json` | `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_aware_gate_queue_20260628_v2_execute_run_20260628_100342.md` |

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
| `reprieve_cut_avatar_wrath` | `blocked_prior_evidence` | `Reprieve` | `Avatar's Wrath` | `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `perch_protection_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Perch Protection` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
| `silence_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Silence` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
