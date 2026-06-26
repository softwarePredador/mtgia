# XMage Effective Queue Report

- Generated at: `2026-06-26T11:27:13+00:00`
- Status: `ready`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg242_magmakin_postsync_v1_proposals.json`
- Package manifests scanned: `116`
- Cards covered by package manifests: `257`

## Effective Lanes

- `package_already_prepared`: `1`
- `package_ready_unprepared`: `0`
- `split_scope_backlog`: `59`
- `runtime_family_backlog`: `4`
- `manual_mapper_backlog`: `315`
- `blocked_missing_xmage_source`: `4`

## Recommendations

- `P0` Stop rebuilding cards that already have PG package artifacts. Reason: 1 current candidates are already covered by prepared package manifests in the report directory.
- `P1` After the PG-ready lane shrinks, batch the biggest split-scope cluster. Reason: The partially supported backlog is 59 cards. Top exact cluster: targeted_damage_variant_v1 (19)
- `P1` Open new runtime only on the most reusable family remaining. Reason: Runtime-only backlog is 4 cards. Top reusable exact scope cluster: damage_all_variant_v1 (1). Largest raw family is token_maker (3 cards across 3 scopes), so it should wait for taxonomy/test-miner support instead of leading the queue.
- `P2` Keep the manual mapper lane last. Reason: 315 cards still need mapper/manual review; this lane should not drive executor architecture.
- `P2` Isolate missing-XMage cards as a separate exception lane. Reason: 4 cards are blocked by missing local XMage source.

## Prepared Packages Already Covering Current Queue

- `PG219` `purphoros_partial_trigger_preserve_shadow`: `1` cards

## Lane Details

### package_already_prepared

- Count: `1`
- Top scope clusters:
  - `controlled_creature_etb_damage_engine` / `creature` / `controlled_creature_enters_damage_each_opponent_v1`: `1` cards (Purphoros, God of the Forge)

### package_ready_unprepared

- Count: `0`
- Top scope clusters: `none`

### split_scope_backlog

- Count: `59`
- Top scope clusters:
  - `targeted_interaction` / `direct_damage` / `targeted_damage_variant_v1`: `19` cards (Balefire Liege, Boros Reckoner, Brash Taunter, Cemetery Gatekeeper, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Gleeful Arsonist, Harsh Mentor)
  - `targeted_interaction` / `draw_cards` / `source_controller_draw_variant_v1`: `11` cards (Arcane Denial, Archivist of Oghma, Kefka, Court Mage // Kefka, Ruler of Ruin, Morbid Opportunist, Phyrexian Arena, Psychic Frog, Puresteel Paladin, Solemn Simulacrum)
  - `targeted_interaction` / `add_counters` / `source_add_counters_variant_v1`: `7` cards (Bloodchief Ascension, Brallin, Skyshark Rider, Nightshade Harvester, Solphim, Mayhem Dominus, Séance Board, Tezzeret, Cruel Captain, The Haunt of Hightower)
  - `targeted_interaction` / `removal_destroy` / `targeted_destroy_variant_v1`: `6` cards (Abrade, Infernal Grasp, Rakdos Charm, Sheoldred // The True Scriptures, Suspended Sentence, Withering Torment)
  - `recursion` / `recursion` / `graveyard_to_battlefield_variant_v1`: `2` cards (Forge Anew, The Soul Stone)
  - `creature` / `creature` / `activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1`: `1` cards (Razaketh, the Foulblooded)
  - `creature` / `creature` / `another_creature_dies_target_player_loses_life_you_gain_life_v1`: `1` cards (Blood Artist)
  - `creature` / `creature` / `etb_tutor_to_hand_creature_variant_v1`: `1` cards (Rune-Scarred Demon)

### runtime_family_backlog

- Count: `4`
- Top scope clusters:
  - `board_wipe_choice` / `sweeper_damage` / `damage_all_variant_v1`: `1` cards (Ashling, Flame Dancer)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_adagiawindsweptbastion_v1`: `1` cards (Adagia, Windswept Bastion)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_hazelsbrewmaster_v1`: `1` cards (Hazel's Brewmaster)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_maskwoodnexus_v1`: `1` cards (Maskwood Nexus)

### manual_mapper_backlog

- Count: `315`
- Top scope clusters:
  - `manual_model` / `external_reference_required_manual_model` / `xmage_reference_requires_manual_model_review_v1`: `314` cards ("Name Sticker" Goblin, Ad Nauseam, Akroma's Will, Alhammarret's Archive, All Is Dust, Altar of Dementia, Aminatou's Augury, Amphibian Downpour)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_spikedcorridortorturepit_v1`: `1` cards (Spiked Corridor // Torture Pit)

### blocked_missing_xmage_source

- Count: `4`
- Top scope clusters:
  - `manual_model` / `` / ``: `4` cards (Alicia Masters, Skilled Sculptor, Mjölnir, Hammer of Thor, Molecule Man, Thor, God of Thunder)
