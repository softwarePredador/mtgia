# Lorehold Mana Vault Evidence Synthesis - 2026-06-28

- generated_at: `2026-06-28T10:13:55.349788+00:00`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_key: `mana_vault_fast_mana_cut_arcane_signet`
- adds: `Mana Vault`
- cuts: `Arcane Signet`
- decision: `reject_current_pair`
- promotion_allowed: `false`
- next_action: `do_not_repeat_mana_vault_cut_arcane_signet_without_new_cut_or_failure_target`
- sample_caveat: Repeated gates share small opponent/seed scopes; use them as consistency evidence, not as independent large-sample proof.

## Summary

- source_report_count: `7`
- observation_count: `7`
- performance_gate_count: `5`
- natural_gate_count: `2`
- positive_gate_count: `0`
- negative_gate_count: `5`
- latest_natural_source: `lorehold_mana_vault_natural_confirmation_after_forced_20260628_v1_20260628_100237.json`
- latest_natural_delta_pp: `-66.67`
- exposure_confirmed: `true`
- strategic_delta_total: `{"artifact_mana_added": 0, "lorehold_spell_cast": -100, "mana_rock_activated": 0, "mana_vault_activated": 0, "miracle_cast": -22, "topdeck_manipulation_activated": -1}`

## Decision Rules

- preflight_or_skip reports are readiness signals, not performance evidence
- forced/exposure diagnostics can prove card access, but do not promote by themselves
- natural promotion requires a positive natural confirmation without unresolved critical regression
- negative natural confirmations reject the exact add/cut pair until the cut or failure target changes

## Evidence

| Source | Kind | Status | Natural | Baseline | Candidate | Delta | Strategic Delta |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| `lorehold_mana_vault_preflight_20260628_v1_20260628_091000.json` | `preflight_or_skip` | `preflight_ready` | `false` | - | - | - | `{}` |
| `lorehold_mana_vault_gate_20260628_v1_20260628_092000.json` | `performance_gate` | `gated` | `false` | 3-0-0 (100.00%) | 1-2-0 (33.33%) | -66.67 | `{"artifact_mana_added": 0, "lorehold_spell_cast": -28, "mana_rock_activated": 0, "mana_vault_activated": 0, "miracle_cast": -6, "topdeck_manipulation_activated": -1}` |
| `lorehold_mana_vault_preflight_20260628_v2_20260628_093000.json` | `preflight_or_skip` | `skipped_prior_evidence` | `false` | - | - | - | `{}` |
| `lorehold_mana_vault_gate_after_ramp_runtime_fix_20260628_v1_20260628_102000.json` | `performance_gate` | `gated` | `false` | 3-0-0 (100.00%) | 1-2-0 (33.33%) | -66.67 | `{"artifact_mana_added": 0, "lorehold_spell_cast": -18, "mana_rock_activated": 0, "mana_vault_activated": 0, "miracle_cast": -4, "topdeck_manipulation_activated": 0}` |
| `lorehold_mana_vault_exposure_gate_20260628_v1_20260628_111500.json` | `performance_gate` | `gated` | `false` | 3-0-0 (100.00%) | 1-2-0 (33.33%) | -66.67 | `{"artifact_mana_added": 0, "lorehold_spell_cast": -18, "mana_rock_activated": 0, "mana_vault_activated": 0, "miracle_cast": -4, "topdeck_manipulation_activated": 0}` |
| `lorehold_mana_vault_natural_confirmation_20260628_v2_20260628_162000.json` | `performance_gate` | `gated` | `true` | 3-0-0 (100.00%) | 1-2-0 (33.33%) | -66.67 | `{"artifact_mana_added": 0, "lorehold_spell_cast": -18, "mana_rock_activated": 0, "mana_vault_activated": 0, "miracle_cast": -4, "topdeck_manipulation_activated": 0}` |
| `lorehold_mana_vault_natural_confirmation_after_forced_20260628_v1_20260628_100237.json` | `performance_gate` | `gated` | `true` | 3-0-0 (100.00%) | 1-2-0 (33.33%) | -66.67 | `{"artifact_mana_added": 0, "lorehold_spell_cast": -18, "mana_rock_activated": 0, "mana_vault_activated": 0, "miracle_cast": -4, "topdeck_manipulation_activated": 0}` |
