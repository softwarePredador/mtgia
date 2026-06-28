# Lorehold Learning Evidence Ledger

- generated_at: `2026-06-28T07:22:22.436238+00:00`
- postgres_writes: `False`
- source_db_mutated: `False`
- current_leader: `candidate_607_squee_v1`
- protected_baseline: `deck_607`
- untested_queue_count: `0`
- observation_count: `311`
- package_group_count: `74`
- classification_counts: `{"blocked_prior_evidence": 5, "conflicting_signal_needs_champion_gate": 1, "current_champion": 1, "latest_rejected": 13, "preflight_blocked_protected_cut": 37, "preflight_ready_negative_history": 16, "registry_rejected": 1}`
- hidden_retreat_classification: `latest_rejected`

## Decision Guardrails

- candidate must tie or beat deck_607 on same real-opponent gate
- candidate must not regress the Winota matchup
- candidate must preserve or improve miracle/topdeck game frequency
- candidate must not cut pressure absorption unless replacing same function

## Current Read

- The registry remains the authority for promotion status; raw positive gates below are treated as hypotheses until they clear the current-leader/equal-gate rule.
- Hidden Retreat is classified from the latest local overlay gate and is not promoted unless a later same-function gate reverses the result.

## Actionable Confirmation Queue

| Package | Class | Best Delta | Latest Delta | Latest Source |
| --- | --- | ---: | ---: | --- |
| ghostly_prison_pressure_cut_promise | `conflicting_signal_needs_champion_gate` | +37.50 | +12.50 | `lorehold_ghostly_promise_champion_gate_20260628_v1_20260628_072510.json` |

## Key Package Groups

| Package | Class | Obs | +/-/0 | Best | Latest | Latest Source |
| --- | --- | ---: | --- | ---: | ---: | --- |
| candidate_607_squee_v1 | `current_champion` | 10 | 4/2/4 | +88.89 | -33.33 | `lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json` |
| brainstone_topdeck_miracle_cut_squelcher | `preflight_blocked_protected_cut` | 9 | 2/1/0 | +55.56 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| past_in_flames_recast | `preflight_blocked_protected_cut` | 6 | 1/0/0 | +50.00 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| core_challenge_dance_over_storm | `preflight_blocked_protected_cut` | 8 | 2/1/1 | +44.44 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| galvanoth_topdeck_freecast | `preflight_blocked_protected_cut` | 8 | 2/1/1 | +44.44 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| angel_grace_life_floor_cut_dawn | `preflight_blocked_protected_cut` | 7 | 1/1/1 | +33.33 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| birgi_seething_chain_cut_medallions | `preflight_blocked_protected_cut` | 7 | 2/1/0 | +33.33 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| galvanoth_topdeck_freecast_cut_chimes | `preflight_blocked_protected_cut` | 7 | 2/1/0 | +33.33 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| gamble_approach_access_cut_creative | `preflight_blocked_protected_cut` | 7 | 2/1/0 | +33.33 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| one_ring_protection_draw_cut_squelcher | `preflight_blocked_protected_cut` | 7 | 1/1/1 | +33.33 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| birgi_spellchain_cut_squelcher | `preflight_blocked_protected_cut` | 8 | 2/1/1 | +22.22 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| core_challenge_aetherflux_over_storm | `preflight_blocked_protected_cut` | 7 | 2/1/0 | +22.22 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| galvanoth_topdeck_freecast_cut_squelcher | `preflight_blocked_protected_cut` | 7 | 2/1/0 | +22.22 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| ghostly_prison_pressure_cut_squelcher | `preflight_blocked_protected_cut` | 7 | 2/1/0 | +22.22 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| penance_topdeck_protection_cut_squelcher | `preflight_blocked_protected_cut` | 9 | 1/1/1 | +22.22 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| primal_amulet_spell_engine | `preflight_blocked_protected_cut` | 8 | 2/1/1 | +22.22 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| brainstone_topdeck_miracle | `preflight_blocked_protected_cut` | 8 | 1/2/1 | +11.11 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| faithless_looting_squee_enabler | `preflight_blocked_protected_cut` | 8 | 2/1/0 | +11.11 | +0.00 | `lorehold_actionable_confirmation_preflight_20260628_v2_20260628_074000.json` |
| arcane_bombardment_engine | `preflight_blocked_protected_cut` | 3 | 0/0/1 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| birgi_spellchain_cut_waterskin | `preflight_blocked_protected_cut` | 3 | 0/0/1 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| copy_stack_package | `preflight_blocked_protected_cut` | 3 | 0/0/1 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| overmaster_protect_draw | `preflight_blocked_protected_cut` | 3 | 0/0/1 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| sun_titan_blink_value | `preflight_blocked_protected_cut` | 5 | 0/2/1 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| enlightened_engine_access_cut_thor | `preflight_blocked_protected_cut` | 4 | 0/1/0 | -44.45 | +0.00 | `lorehold_focus_access_preflight_20260628_v1_20260628_focus_access_preflight_v1.json` |
| chandra_copy_engine | `preflight_blocked_protected_cut` | 3 | 0/1/0 | -50.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| boseiju_spell_protection_land | `preflight_blocked_protected_cut` | 3 | 0/1/0 | -55.56 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| galvanoth_topdeck_freecast_cut_thor | `preflight_blocked_protected_cut` | 3 | 0/1/0 | -55.56 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| gamble_access_cut_thor | `preflight_blocked_protected_cut` | 4 | 0/1/0 | -55.56 | +0.00 | `lorehold_focus_access_preflight_20260628_v1_20260628_focus_access_preflight_v1.json` |
| sun_titan_cut_chimes | `preflight_blocked_protected_cut` | 3 | 0/1/0 | -66.67 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| boros_charm_pressure_cut_fated | `preflight_blocked_protected_cut` | 4 | 0/1/0 | -88.89 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| artifact_etb_value | `preflight_blocked_protected_cut` | 3 | 0/1/0 | -100.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| etb_tutor_blink | `preflight_blocked_protected_cut` | 3 | 0/1/0 | -100.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| one_ring_burden_reset | `preflight_blocked_protected_cut` | 4 | 0/1/0 | -100.00 | +0.00 | `lorehold_one_ring_bender_preflight_20260627_v2_20260627_230137.json` |
| sun_titan_cut_squelcher | `preflight_blocked_protected_cut` | 3 | 0/1/0 | -100.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| biblioplex_topdeck_land | `preflight_blocked_protected_cut` | 2 | 0/0/0 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| mirrorpool_spellcopy_land | `preflight_blocked_protected_cut` | 2 | 0/0/0 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| past_in_flames_cut_squelcher | `preflight_blocked_protected_cut` | 2 | 0/0/0 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| past_overmaster_spellchain | `preflight_blocked_protected_cut` | 2 | 0/0/0 | +0.00 | +0.00 | `lorehold_package_preflight_after_brass_20260627_v1_20260627_214043.json` |
| overmaster_protect_draw_cut_tibalts_trickery | `latest_rejected` | 6 | 2/2/0 | +25.00 | -6.25 | `lorehold_overmaster_tibalt_gate_20260627_v4_games2_opp8_20260627_215440.json` |
| core_challenge_past_over_tragic | `latest_rejected` | 7 | 2/3/0 | +12.50 | -12.50 | `lorehold_past_tragic_gate_20260627_v4_seed123_smoke_opp8_20260627_220625.json` |

## Protected Cards

`Molecule Man`, `The Scarlet Witch`, `Promise of Loyalty`, `Tragic Arrogance`, `Hexing Squelcher`, `Sensei's Divining Top`, `Scroll Rack`, `Bender's Waterskin`, `Tibalt's Trickery`, `Creative Technique`, `High Noon`, `Prismari Pianist`, `Reforge the Soul`, `Storm Herd`
