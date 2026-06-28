# Lorehold Learning Evidence Ledger

- generated_at: `2026-06-28T07:41:19.427241+00:00`
- postgres_writes: `False`
- source_db_mutated: `False`
- current_leader: `candidate_607_squee_v1`
- protected_baseline: `deck_607`
- untested_queue_count: `0`
- observation_count: `683`
- critical_matchup_observation_count: `363`
- package_group_count: `77`
- classification_counts: `{"blocked_prior_evidence": 22, "current_champion": 1, "latest_rejected": 2, "preflight_blocked_protected_cut": 51, "registry_rejected": 1}`
- hidden_retreat_classification: `preflight_blocked_protected_cut`

## Decision Guardrails

- candidate must tie or beat deck_607 on same real-opponent gate
- candidate must not regress the Winota matchup
- candidate must preserve or improve miracle/topdeck game frequency
- candidate must not cut pressure absorption unless replacing same function

## Current Read

- The registry remains the authority for promotion status; raw positive gates below are treated as hypotheses until they clear the current-leader/equal-gate rule.
- Critical matchup rows track Winota, Vivi, and Sisay from detailed synergy gates; a positive aggregate gate with critical regression is held for rework.
- Hidden Retreat is classified from the latest local overlay gate and is not promoted unless a later same-function gate reverses the result.

## Actionable Confirmation Queue

- None.

## Key Package Groups

| Package | Class | Obs | +/-/0 | Critical +/-/0 | Best | Latest | Latest Source |
| --- | --- | ---: | --- | --- | ---: | ---: | --- |
| candidate_607_squee_v1 | `current_champion` | 10 | 4/2/4 | 0/0/0 | +88.89 | -33.33 | `lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json` |
| brainstone_topdeck_miracle_cut_squelcher | `preflight_blocked_protected_cut` | 13 | 2/1/0 | 5/3/1 | +55.56 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| past_in_flames_recast | `preflight_blocked_protected_cut` | 11 | 1/0/0 | 1/0/1 | +50.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| core_challenge_dance_over_storm | `preflight_blocked_protected_cut` | 13 | 2/1/1 | 6/4/1 | +44.44 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| galvanoth_topdeck_freecast | `preflight_blocked_protected_cut` | 13 | 2/1/1 | 4/3/4 | +44.44 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| ghostly_prison_pressure_cut_promise | `preflight_blocked_protected_cut` | 14 | 6/1/0 | 6/5/7 | +37.50 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| angel_grace_life_floor_cut_dawn | `preflight_blocked_protected_cut` | 12 | 1/1/1 | 2/3/4 | +33.33 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| birgi_seething_chain_cut_medallions | `preflight_blocked_protected_cut` | 12 | 2/1/0 | 5/3/1 | +33.33 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| galvanoth_topdeck_freecast_cut_chimes | `preflight_blocked_protected_cut` | 12 | 2/1/0 | 3/2/4 | +33.33 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| gamble_approach_access_cut_creative | `preflight_blocked_protected_cut` | 12 | 2/1/0 | 4/2/3 | +33.33 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| gods_willing_commander_shield_cut_promise | `preflight_blocked_protected_cut` | 10 | 1/1/1 | 0/0/0 | +33.33 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| one_ring_protection_draw_cut_squelcher | `preflight_blocked_protected_cut` | 12 | 1/1/1 | 3/3/3 | +33.33 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| overmaster_protect_draw_cut_tibalts_trickery | `preflight_blocked_protected_cut` | 11 | 2/2/0 | 4/3/5 | +25.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| birgi_spellchain_cut_squelcher | `preflight_blocked_protected_cut` | 13 | 2/1/1 | 4/3/4 | +22.22 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| core_challenge_aetherflux_over_storm | `preflight_blocked_protected_cut` | 12 | 2/1/0 | 3/2/4 | +22.22 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| galvanoth_topdeck_freecast_cut_squelcher | `preflight_blocked_protected_cut` | 12 | 2/1/0 | 3/3/3 | +22.22 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| ghostly_prison_pressure_cut_squelcher | `preflight_blocked_protected_cut` | 12 | 2/1/0 | 3/3/3 | +22.22 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| penance_topdeck_protection_cut_squelcher | `preflight_blocked_protected_cut` | 14 | 1/1/1 | 2/3/4 | +22.22 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| primal_amulet_spell_engine | `preflight_blocked_protected_cut` | 13 | 2/1/1 | 2/2/7 | +22.22 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| core_challenge_past_over_tragic | `preflight_blocked_protected_cut` | 12 | 2/3/0 | 3/4/7 | +12.50 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| brainstone_topdeck_miracle | `preflight_blocked_protected_cut` | 13 | 1/2/1 | 1/3/7 | +11.11 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| faithless_looting_squee_enabler | `preflight_blocked_protected_cut` | 13 | 2/1/0 | 2/3/4 | +11.11 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| arcane_bombardment_engine | `preflight_blocked_protected_cut` | 8 | 0/0/1 | 1/1/0 | +0.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| birgi_spellchain_cut_waterskin | `preflight_blocked_protected_cut` | 8 | 0/0/1 | 0/0/2 | +0.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| copy_stack_package | `preflight_blocked_protected_cut` | 8 | 0/0/1 | 0/0/2 | +0.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| overmaster_protect_draw | `preflight_blocked_protected_cut` | 8 | 0/0/1 | 0/0/2 | +0.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| penance_runtime_topdeck_cut_promise | `preflight_blocked_protected_cut` | 9 | 0/1/2 | 0/0/0 | +0.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| sejiri_shelter_commander_shield_cut_promise | `preflight_blocked_protected_cut` | 8 | 0/2/1 | 0/0/0 | +0.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| sun_titan_blink_value | `preflight_blocked_protected_cut` | 10 | 0/2/1 | 0/3/6 | +0.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| enlightened_engine_access_cut_thor | `preflight_blocked_protected_cut` | 9 | 0/1/0 | 0/3/0 | -44.45 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| chandra_copy_engine | `preflight_blocked_protected_cut` | 8 | 0/1/0 | 0/1/1 | -50.00 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| boseiju_spell_protection_land | `preflight_blocked_protected_cut` | 8 | 0/1/0 | 1/2/0 | -55.56 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| galvanoth_topdeck_freecast_cut_thor | `preflight_blocked_protected_cut` | 8 | 0/1/0 | 0/3/0 | -55.56 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| gamble_access_cut_thor | `preflight_blocked_protected_cut` | 9 | 0/1/0 | 0/3/0 | -55.56 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| hidden_retreat_stack_damage_topdeck_cut_promise | `preflight_blocked_protected_cut` | 6 | 0/1/0 | 0/2/1 | -66.67 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| lapse_approach_topdeck_cut_tibalts_trickery | `preflight_blocked_protected_cut` | 7 | 0/1/0 | 0/2/1 | -66.67 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| monastery_mentor_spell_tokens_cut_prismari | `preflight_blocked_protected_cut` | 7 | 0/1/0 | 0/2/1 | -66.67 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| radiant_scrollwielder_cut_scarlet_witch | `preflight_blocked_protected_cut` | 7 | 0/1/0 | 0/2/1 | -66.67 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| sun_titan_cut_chimes | `preflight_blocked_protected_cut` | 8 | 0/1/0 | 0/2/1 | -66.67 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |
| young_pyromancer_spell_tokens_cut_prismari | `preflight_blocked_protected_cut` | 7 | 0/1/0 | 0/2/1 | -66.67 | +0.00 | `lorehold_all_package_preflight_20260628_v5_20260628_100000.json` |

## Protected Cards

`Molecule Man`, `The Scarlet Witch`, `Promise of Loyalty`, `Tragic Arrogance`, `Hexing Squelcher`, `Sensei's Divining Top`, `Scroll Rack`, `Bender's Waterskin`, `Tibalt's Trickery`, `Creative Technique`, `High Noon`, `Prismari Pianist`, `Reforge the Soul`, `Storm Herd`
