# XMage Effective Queue Report

- Generated at: `2026-06-24T14:37:04+00:00`
- Status: `ready`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_expanded_608_619_real_v5_proposals.json`
- Package manifests scanned: `60`
- Cards covered by package manifests: `178`

## Effective Lanes

- `package_already_prepared`: `54`
- `package_ready_unprepared`: `0`
- `split_scope_backlog`: `68`
- `runtime_family_backlog`: `24`
- `manual_mapper_backlog`: `356`
- `blocked_missing_xmage_source`: `2`

## Recommendations

- `P0` Stop rebuilding cards that already have PG package artifacts. Reason: 54 current candidates are already covered by prepared package manifests in the report directory.
- `P1` After the PG-ready lane shrinks, batch the biggest split-scope cluster. Reason: The partially supported backlog is 68 cards. Top exact cluster: targeted_damage_variant_v1 (21)
- `P1` Open new runtime only on the most reusable family remaining. Reason: Runtime-only backlog is 24 cards. Top reusable exact scope cluster: damage_all_variant_v1 (2). Largest raw family is token_maker (20 cards across 20 scopes), so it should wait for taxonomy/test-miner support instead of leading the queue.
- `P2` Keep the manual mapper lane last. Reason: 356 cards still need mapper/manual review; this lane should not drive executor architecture.
- `P2` Isolate missing-XMage cards as a separate exception lane. Reason: 2 cards are blocked by missing local XMage source.

## Prepared Packages Already Covering Current Queue

- `PG166` `copy_permanent_etb`: `5` cards
- `PG167` `copy_creature_applier`: `4` cards
- `PG168` `land_and_hand_exile`: `3` cards
- `PG169` `exotic_orchard`: `1` cards
- `PG171` `draw_engines_and_land_tutors`: `4` cards
- `PG172` `monolith_mana_rocks`: `2` cards
- `PG173` `x_tutor_battlefield_spells`: `4` cards
- `PG174` `copy_spell_engines`: `2` cards
- `PG175` `untap_land_engines`: `4` cards
- `PG176` `damage_controller_pain_sources`: `3` cards
- `PG177` `creatures_tap_any_color`: `2` cards
- `PG178` `opponent_draw_punishers`: `2` cards
- `PG179` `discard_trigger_engines`: `3` cards
- `PG180` `residual_mana_accelerants`: `8` cards
- `PG181` `residual_batch_ready_seven`: `7` cards

## Lane Details

### package_already_prepared

- Count: `54`
- Top scope clusters:
  - `copy_permanent_etb` / `copy_permanent_etb` / `etb_copy_target_permanent_with_optional_extra_type_v1`: `5` cards (Clever Impersonator, Copy Artifact, Copy Enchantment, Mirrormade, Phyrexian Metamorph)
  - `copy_permanent_etb` / `copy_permanent_etb` / `etb_copy_target_creature_with_copy_applier_modifiers_v1`: `4` cards (Flesh Duplicate, Imposter Mech, Mockingbird, Phantasmal Image)
  - `creature` / `creature` / `one_mana_zero_one_exalted_tricolor_mana_dork_v1`: `2` cards (Ignoble Hierarch, Noble Hierarch)
  - `land` / `land` / `basic_one_color_land_v1`: `2` cards (Mountain, Plains)
  - `ramp_permanent` / `ramp_permanent` / `pain_talisman_color_pair_partial_v1`: `2` cards (Talisman of Curiosity, Talisman of Indulgence)
  - `ramp_permanent` / `ramp_permanent` / `three_colorless_monolith_mana_rock_v1`: `2` cards (Basalt Monolith, Grim Monolith)
  - `copy_spell_engine` / `copy_spell` / `first_instant_sorcery_cast_each_turn_copy_own_spell_v1`: `1` cards (Double Vision)
  - `copy_spell_engine` / `copy_spell` / `instant_sorcery_cast_copy_own_spell_v1`: `1` cards (Swarm Intelligence)

### package_ready_unprepared

- Count: `0`
- Top scope clusters: `none`

### split_scope_backlog

- Count: `68`
- Top scope clusters:
  - `targeted_interaction` / `direct_damage` / `targeted_damage_variant_v1`: `21` cards (Balefire Liege, Boros Reckoner, Brash Taunter, Caldera Pyremaw, Cemetery Gatekeeper, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Gleeful Arsonist)
  - `targeted_interaction` / `draw_cards` / `source_controller_draw_variant_v1`: `17` cards (Arcane Denial, Archivist of Oghma, Bedlam Reveler, Blood Sun, Cool but Rude, Glint-Horn Buccaneer, Kefka, Court Mage // Kefka, Ruler of Ruin, Morbid Opportunist)
  - `targeted_interaction` / `add_counters` / `source_add_counters_variant_v1`: `11` cards (Bloodchief Ascension, Brallin, Skyshark Rider, Nightshade Harvester, Palantír of Orthanc, Primal Amulet // Primal Wellspring, Pyromancer Ascension, Solphim, Mayhem Dominus, Séance Board)
  - `targeted_interaction` / `removal_destroy` / `targeted_destroy_variant_v1`: `10` cards (Abrade, Erode, Infernal Grasp, Rakdos Charm, Sheoldred // The True Scriptures, Star of Extinction, Sundering Eruption // Volcanic Fissure, Suspended Sentence)
  - `targeted_interaction` / `recursion` / `graveyard_to_battlefield_variant_v1`: `4` cards (Forge Anew, Profound Journey, Sun Titan, The Soul Stone)
  - `static_cost_reducer` / `static_cost_reduction` / `static_self_spell_cost_reduction_variant_v1`: `2` cards (Explosive Singularity, Vanquish the Horde)
  - `targeted_interaction` / `add_counters` / `targeted_add_counters_variant_v1`: `1` cards (Persistent Constrictor)
  - `targeted_interaction` / `removal_exile` / `targeted_exile_variant_v1`: `1` cards (Whip of Erebos)

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

- Count: `356`
- Top scope clusters:
  - `manual_model` / `external_reference_required_manual_model` / `xmage_reference_requires_manual_model_review_v1`: `355` cards ("Name Sticker" Goblin, Ad Nauseam, Agate Instigator, Akroma's Will, Alhammarret's Archive, All Is Dust, Altar of Dementia, Aminatou's Augury)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_spikedcorridortorturepit_v1`: `1` cards (Spiked Corridor // Torture Pit)

### blocked_missing_xmage_source

- Count: `2`
- Top scope clusters:
  - `manual_model` / `` / ``: `2` cards (Alicia Masters, Skilled Sculptor, Mjölnir, Hammer of Thor)
