# XMage Effective Queue Report

- Generated at: `2026-06-24T19:22:56+00:00`
- Status: `ready`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_proposals.json`
- Package manifests scanned: `62`
- Cards covered by package manifests: `180`

## Effective Lanes

- `package_already_prepared`: `0`
- `package_ready_unprepared`: `2`
- `split_scope_backlog`: `81`
- `runtime_family_backlog`: `24`
- `manual_mapper_backlog`: `337`
- `blocked_missing_xmage_source`: `2`

## Recommendations

- `P0` Exhaust the unpackaged PG-ready residual before opening new runtime work. Reason: 2 cards are immediately packageable. Top exact cluster: storm_target_player_mill_fixed_count_v1 (1)
- `P1` After the PG-ready lane shrinks, batch the biggest split-scope cluster. Reason: The partially supported backlog is 81 cards. Top exact cluster: targeted_damage_variant_v1 (21)
- `P1` Open new runtime only on the most reusable family remaining. Reason: Runtime-only backlog is 24 cards. Top reusable exact scope cluster: damage_all_variant_v1 (2). Largest raw family is token_maker (20 cards across 20 scopes), so it should wait for taxonomy/test-miner support instead of leading the queue.
- `P2` Keep the manual mapper lane last. Reason: 337 cards still need mapper/manual review; this lane should not drive executor architecture.
- `P2` Isolate missing-XMage cards as a separate exception lane. Reason: 2 cards are blocked by missing local XMage source.

## Lane Details

### package_already_prepared

- Count: `0`
- Top scope clusters: `none`

### package_ready_unprepared

- Count: `2`
- Top scope clusters:
  - `mill_spell` / `brain_freeze` / `storm_target_player_mill_fixed_count_v1`: `1` cards (Brain Freeze)
  - `ramp_ritual` / `ramp_ritual` / `threshold_three_or_five_black_mana_ritual_v1`: `1` cards (Cabal Ritual)

### split_scope_backlog

- Count: `81`
- Top scope clusters:
  - `targeted_interaction` / `direct_damage` / `targeted_damage_variant_v1`: `21` cards (Balefire Liege, Boros Reckoner, Brash Taunter, Caldera Pyremaw, Cemetery Gatekeeper, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Gleeful Arsonist)
  - `targeted_interaction` / `draw_cards` / `source_controller_draw_variant_v1`: `17` cards (Arcane Denial, Archivist of Oghma, Bedlam Reveler, Blood Sun, Cool but Rude, Glint-Horn Buccaneer, Kefka, Court Mage // Kefka, Ruler of Ruin, Morbid Opportunist)
  - `targeted_interaction` / `add_counters` / `source_add_counters_variant_v1`: `11` cards (Bloodchief Ascension, Brallin, Skyshark Rider, Nightshade Harvester, Palantír of Orthanc, Primal Amulet // Primal Wellspring, Pyromancer Ascension, Solphim, Mayhem Dominus, Séance Board)
  - `targeted_interaction` / `removal_destroy` / `targeted_destroy_variant_v1`: `10` cards (Abrade, Erode, Infernal Grasp, Rakdos Charm, Sheoldred // The True Scriptures, Star of Extinction, Sundering Eruption // Volcanic Fissure, Suspended Sentence)
  - `targeted_interaction` / `recursion` / `graveyard_to_battlefield_variant_v1`: `4` cards (Forge Anew, Profound Journey, Sun Titan, The Soul Stone)
  - `creature` / `creature` / `etb_tutor_to_hand_creature_variant_v1`: `2` cards (Rune-Scarred Demon, Starfield Shepherd)
  - `static_cost_reducer` / `static_cost_reduction` / `static_self_spell_cost_reduction_variant_v1`: `2` cards (Explosive Singularity, Vanquish the Horde)
  - `copy_spell_engine` / `copy_spell` / `copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1`: `1` cards (Fury Storm)

### runtime_family_backlog

- Count: `24`
- Top scope clusters:
  - `board_wipe_choice` / `sweeper_damage` / `damage_all_variant_v1`: `2` cards (Ashling, Flame Dancer, Soul Immolation)
  - `board_wipe_choice` / `board_wipe` / `destroy_all_permanents_or_creatures_variant_v1`: `2` cards (Armageddon, Ultima)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_aclazotzdeepestbetrayal_v1`: `1` cards (Aclazotz, Deepest Betrayal // Temple of the Dead)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_adagiawindsweptbastion_v1`: `1` cards (Adagia, Windswept Bastion)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_biotransference_v1`: `1` cards (Biotransference)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_blackmarketconnections_v1`: `1` cards (Black Market Connections)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_blazecommando_v1`: `1` cards (Blaze Commando)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_bonemiser_v1`: `1` cards (Bone Miser)

### manual_mapper_backlog

- Count: `337`
- Top scope clusters:
  - `manual_model` / `external_reference_required_manual_model` / `xmage_reference_requires_manual_model_review_v1`: `336` cards ("Name Sticker" Goblin, Ad Nauseam, Agate Instigator, Akroma's Will, Alhammarret's Archive, All Is Dust, Altar of Dementia, Aminatou's Augury)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_spikedcorridortorturepit_v1`: `1` cards (Spiked Corridor // Torture Pit)

### blocked_missing_xmage_source

- Count: `2`
- Top scope clusters:
  - `manual_model` / `` / ``: `2` cards (Alicia Masters, Skilled Sculptor, Mjölnir, Hammer of Thor)
