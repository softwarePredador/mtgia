# Lorehold Exposure Outcome Audit - 2026-06-28

- generated_at: `2026-06-28T11:17:01Z`
- postgres_writes: `false`
- source_db_mutated: `false`
- loaded_package_observation_count: `5`
- missing_report_count: `0`
- decision_counts: `{"card_outcome_rejects_current_pair": 3, "forced_access_card_outcome_signal_requires_natural_confirmation": 2}`
- recommended_next_action: `avoid_repeating_rejected_pairs_and_generate_new_trace_targeted_package`

## Decision Rules

- aggregate deck record is not card-level proof by itself
- candidate card must have a used-game sample before a package can be promoted
- used-game comparison is candidate-added card record versus baseline-cut card record
- forced-access probes can diagnose access but require natural confirmation before promotion
- multi-card packages require split or manual review before per-card outcome promotion
- Hermes gate evidence is lab evidence; PostgreSQL state is not mutated by this report

## Package Outcomes

| Package | Source | Adds | Cuts | Aggregate | Added Used | Cut Used | Used Delta | Decision | Next Action |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| `mana_vault_fast_mana_cut_arcane_signet` | `lorehold_exposure_aware_gate_queue_20260628_v1_execute_run_20260628_100146_mana_vault_fast_mana_cut_arcane_signet.json` | `Mana Vault` | `Arcane Signet` | 0-3-0 (0.00%) -> 1-2-0 (33.33%) (+33.33) | 1-2-0 (33.33%) | 0-2-0 (0.00%) | +33.33 | `forced_access_card_outcome_signal_requires_natural_confirmation` | `run_natural_gate_without_forced_access_before_promoting` |
| `mana_vault_fast_mana_cut_arcane_signet` | `lorehold_exposure_by_game_gate_20260628_v1_20260628_101737_mana_vault_fast_mana_cut_arcane_signet.json` | `Mana Vault` | `Arcane Signet` | 3-0-0 (100.00%) -> 1-2-0 (33.33%) (-66.67) | 1-1-0 (50.00%) | 2-0-0 (100.00%) | -50.00 | `card_outcome_rejects_current_pair` | `do_not_repeat_exact_pair_without_new_failure_target_or_cut` |
| `mana_vault_fast_mana_cut_arcane_signet` | `lorehold_forced_access_gate_20260628_v6_20260628_161500_mana_vault_fast_mana_cut_arcane_signet.json` | `Mana Vault` | `Arcane Signet` | 0-3-0 (0.00%) -> 1-2-0 (33.33%) (+33.33) | 1-2-0 (33.33%) | 0-2-0 (0.00%) | +33.33 | `forced_access_card_outcome_signal_requires_natural_confirmation` | `run_natural_gate_without_forced_access_before_promoting` |
| `mana_vault_fast_mana_cut_arcane_signet` | `lorehold_mana_vault_gate_20260628_v1_20260628_092000_mana_vault_fast_mana_cut_arcane_signet.json` | `Mana Vault` | `Arcane Signet` | 3-0-0 (100.00%) -> 1-2-0 (33.33%) (-66.67) | 0-1-0 (0.00%) | 2-0-0 (100.00%) | -100.00 | `card_outcome_rejects_current_pair` | `do_not_repeat_exact_pair_without_new_failure_target_or_cut` |
| `mana_vault_fast_mana_cut_arcane_signet` | `lorehold_mana_vault_natural_confirmation_20260628_v2_20260628_162000_mana_vault_fast_mana_cut_arcane_signet.json` | `Mana Vault` | `Arcane Signet` | 3-0-0 (100.00%) -> 1-2-0 (33.33%) (-66.67) | 1-1-0 (50.00%) | 2-0-0 (100.00%) | -50.00 | `card_outcome_rejects_current_pair` | `do_not_repeat_exact_pair_without_new_failure_target_or_cut` |
