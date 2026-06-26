# XMage Effective Queue Report

- Generated at: `2026-06-26T03:05:03+00:00`
- Status: `ready`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg220_destroy_exact_lorehold_v1_proposals.json`
- Package manifests scanned: `98`
- Cards covered by package manifests: `228`

## Effective Lanes

- `package_already_prepared`: `3`
- `package_ready_unprepared`: `1`
- `split_scope_backlog`: `27`
- `runtime_family_backlog`: `3`
- `manual_mapper_backlog`: `269`
- `blocked_missing_xmage_source`: `0`

## Recommendations

- `P0` Stop rebuilding cards that already have PG package artifacts. Reason: 3 current candidates are already covered by prepared package manifests in the report directory.
- `P0` Exhaust the unpackaged PG-ready residual before opening new runtime work. Reason: 1 cards are immediately packageable. Top exact cluster: destroy_target_opponent_artifact_or_overload_all_opponent_artifacts_annotation_v1 (1)
- `P1` After the PG-ready lane shrinks, batch the biggest split-scope cluster. Reason: The partially supported backlog is 27 cards. Top exact cluster: targeted_damage_variant_v1 (8)
- `P1` Open new runtime only on the most reusable family remaining. Reason: Runtime-only backlog is 3 cards. Top reusable exact scope cluster: damage_all_variant_v1 (1). Largest raw family is token_maker (2 cards across 2 scopes), so it should wait for taxonomy/test-miner support instead of leading the queue.
- `P2` Keep the manual mapper lane last. Reason: 269 cards still need mapper/manual review; this lane should not drive executor architecture.

## Prepared Packages Already Covering Current Queue

- `PG219` `purphoros_partial_trigger_preserve_shadow`: `1` cards
- `PG220` `erode_sundering_destroy_exact`: `2` cards

## Lane Details

### package_already_prepared

- Count: `3`
- Top scope clusters:
  - `controlled_creature_etb_damage_engine` / `creature` / `controlled_creature_enters_damage_each_opponent_v1`: `1` cards (Purphoros, God of the Forge)
  - `targeted_interaction` / `remove_permanent` / `destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1`: `1` cards (Erode)
  - `targeted_interaction` / `remove_permanent` / `destroy_target_land_target_controller_basic_land_tapped_nonfliers_cant_block_or_tapped_red_land_v1`: `1` cards (Sundering Eruption // Volcanic Fissure)

### package_ready_unprepared

- Count: `1`
- Top scope clusters:
  - `targeted_interaction` / `remove_permanent` / `destroy_target_opponent_artifact_or_overload_all_opponent_artifacts_annotation_v1`: `1` cards (Vandalblast)

### split_scope_backlog

- Count: `27`
- Top scope clusters:
  - `targeted_interaction` / `direct_damage` / `targeted_damage_variant_v1`: `8` cards (Balefire Liege, Boros Reckoner, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Razorgrass Ambush // Razorgrass Field, Repercussion, Terror of the Peaks, Toralf, God of Fury // Toralf's Hammer)
  - `targeted_interaction` / `add_counters` / `source_add_counters_variant_v1`: `3` cards (Palantír of Orthanc, Primal Amulet // Primal Wellspring, Tezzeret, Cruel Captain)
  - `targeted_interaction` / `draw_cards` / `source_controller_draw_variant_v1`: `3` cards (Archivist of Oghma, Bedlam Reveler, Blood Sun)
  - `static_cost_reducer` / `static_cost_reduction` / `static_self_spell_cost_reduction_variant_v1`: `2` cards (Explosive Singularity, Vanquish the Horde)
  - `targeted_interaction` / `removal_destroy` / `targeted_destroy_variant_v1`: `2` cards (Abrade, Star of Extinction)
  - `creature` / `creature` / `etb_tutor_to_hand_creature_variant_v1`: `1` cards (Starfield Shepherd)
  - `mill_spell` / `mill_engine` / `artifact_tap_sacrifice_permanent_target_player_mill_v1`: `1` cards (Grinding Station)
  - `modal_spell` / `modal_spell` / `modal_artifact_tutor_or_artifact_graveyard_to_hand_v1`: `1` cards (Scour for Scrap)

### runtime_family_backlog

- Count: `3`
- Top scope clusters:
  - `board_wipe_choice` / `sweeper_damage` / `damage_all_variant_v1`: `1` cards (Ashling, Flame Dancer)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_adagiawindsweptbastion_v1`: `1` cards (Adagia, Windswept Bastion)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_hazelsbrewmaster_v1`: `1` cards (Hazel's Brewmaster)

### manual_mapper_backlog

- Count: `269`
- Top scope clusters:
  - `manual_model` / `external_reference_required_manual_model` / `xmage_reference_requires_manual_model_review_v1`: `269` cards ("Name Sticker" Goblin, Ad Nauseam, Akroma's Will, Alhammarret's Archive, All Is Dust, Altar of Dementia, Aminatou's Augury, Amphibian Downpour)

### blocked_missing_xmage_source

- Count: `0`
- Top scope clusters: `none`
