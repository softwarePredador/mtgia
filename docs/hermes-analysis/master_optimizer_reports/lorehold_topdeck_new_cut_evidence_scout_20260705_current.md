# Lorehold Topdeck New Cut Evidence Scout

- Generated at: `2026-07-05T10:40:27Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_new_cut_evidence_scout_learning_targets_only_keep_607`
- Router route: `topdeck_new_cut_evidence_scout`
- Primary target: `Dragon's Rage Channeler`
- Hard-blocked same-lane slots: `6`
- Internal review-only targets: `0`
- Safe cut ready: `0`
- Matrix candidate rows: `0`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Recommended next action: `collect_external_or_new_trace_evidence_for_drc_nonanchor_cut`

## Source Reports

- `exposure_profile`: `docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260704_role_tag_repair_deck607.json`
- `nonanchor_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json`
- `post_named_router`: `docs/hermes-analysis/master_optimizer_reports/lorehold_post_named_frontier_next_evidence_router_20260705_current.json`
- `trace_cut_expander`: `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## Deckbuilding Priority Rules

- land_quantity_floor: `34`
- ramp_quantity_floor: `15`
- mana_sources_land_plus_ramp_floor: `49`
- lands, ramp, protection, miracle finishers, and commander center are not generic cuts
- external staple strength can create a hypothesis but cannot create a cut
- same-lane proof, cut-safety proof, runtime support, and battle evidence are separate gates
- deck 607 remains the protected baseline while safe_cut_ready_count is zero

## Hard-Blocked Same-Lane Slots

- `Call Forth the Tempest` (spell_velocity): exposure=`8` blockers=cut_is_miracle_core_big_spell, miracle_or_finisher_core, structural_dependency
- `Everything Comes to Dust` (spell_velocity): exposure=`34` blockers=cut_is_miracle_core_big_spell, miracle_or_finisher_core, structural_dependency
- `Hexing Squelcher` (contextual): exposure=`93` blockers=prior_rejected_cut, protected_cut
- `Blasphemous Act` (spell_velocity): exposure=`368` blockers=cut_is_early_mana_floor_support, cut_is_miracle_core_big_spell, measured_high_cut_exposure, miracle_or_finisher_core, structural_dependency
- `Farewell` (spell_velocity): exposure=`231` blockers=cut_is_miracle_core_big_spell, measured_high_cut_exposure, miracle_or_finisher_core, structural_dependency
- `Starfall Invocation` (spell_velocity): exposure=`396` blockers=cut_is_miracle_core_big_spell, measured_high_cut_exposure, miracle_or_finisher_core, structural_dependency

## Internal Evidence Targets

- none

## Blocked Near Misses

- `Pinnacle Monk // Mystic Peak`: value=`10.0` exposure=`8` blockers=`cut_is_miracle_core_big_spell,prior_rejected_cut,prior_rejected_cut_slot,prior_rejected_signature`
- `Tempt with Bunnies`: value=`10.0` exposure=`31` blockers=`cut_is_miracle_core_big_spell,floor_lane,miracle_or_finisher_core,structural_dependency`
- `Promise of Loyalty`: value=`10.0` exposure=`53` blockers=`cut_is_miracle_core_big_spell,cut_is_protection_shell,floor_lane,miracle_or_finisher_core,prior_rejected_cut,prior_rejected_cut_slot`
- `Improvisation Capstone`: value=`10.0` exposure=`59` blockers=`structural_dependency`
- `Prismari Pianist`: value=`10.0` exposure=`65` blockers=`cut_is_miracle_core_big_spell,floor_lane,miracle_or_finisher_core,no_target_or_adjacent_lane_overlap,prior_rejected_cut,prior_rejected_cut_slot`
- `High Noon`: value=`10.0` exposure=`66` blockers=`no_target_or_adjacent_lane_overlap,prior_rejected_cut,prior_rejected_cut_slot,protected_cut`
- `Tragic Arrogance`: value=`10.0` exposure=`80` blockers=`cut_is_miracle_core_big_spell,floor_lane,miracle_or_finisher_core,prior_rejected_cut,prior_rejected_cut_slot,prior_rejected_signature`
- `Emeria's Call // Emeria, Shattered Skyclave`: value=`10.0` exposure=`86` blockers=`cut_is_miracle_core_big_spell,cut_is_protection_shell,floor_lane,miracle_or_finisher_core,prior_rejected_cut,prior_rejected_cut_slot`

## Evidence Requests

- `dragon_rage_channeler_new_nonanchor_same_lane_cut_evidence`: `external_or_new_trace_required`
- `external_topdeck_corpus_refresh`: `discovery_only`
- `mana_and_staple_routes_deferred`: `deferred_until_distinct_trace`

## External Research Context

- `Wizards Commander banned and restricted list`: https://magic.wizards.com/en/banned-restricted-list
- `Wizards Commander Brackets Beta`: https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta
- `EDHREC Lorehold, the Historian upgraded spellslinger`: https://edhrec.com/commanders/lorehold-the-historian/upgraded/spellslinger
- `Scryfall Dragon's Rage Channeler`: https://scryfall.com/search?q=%21%22Dragon%27s+Rage+Channeler%22
- `Scryfall Mana Vault`: https://scryfall.com/search?q=%21%22Mana+Vault%22
- `Scryfall The One Ring`: https://scryfall.com/search?q=%21%22The+One+Ring%22

## Decision

- keep_607_as_protected_baseline: `true`
- allow_deck_mutation_now: `false`
- allow_candidate_materialization_now: `false`
- allow_structure_matrix_now: `false`
- allow_forced_access_now: `false`
- allow_natural_battle_gate_now: `false`
- promotion_allowed: `false`
- reason: The router selected a topdeck cut-evidence scout, but the current non-anchor model has no safe cut. Internal targets, if any, are review-only evidence work and do not authorize a deck change.
- next_actions:
  - `collect_external_or_new_trace_evidence_for_drc_nonanchor_cut`
  - `do_not_mutate_deck_607`
  - `do_not_promote_mana_vault_or_the_one_ring_without_new_same_lane_cut_evidence`
  - `do_not_open_natural_battle_gate_until_safe_cut_and_matrix_rows_exist`
