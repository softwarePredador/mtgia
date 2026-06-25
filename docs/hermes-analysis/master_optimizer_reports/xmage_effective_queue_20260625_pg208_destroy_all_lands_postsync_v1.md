# XMage Effective Queue Report

- Generated at: `2026-06-25T07:30:10+00:00`
- Status: `ready`
- Proposal report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg208_destroy_all_lands_postsync_v1_proposals.json`
- Package manifests scanned: `86`
- Cards covered by package manifests: `209`

## Effective Lanes

- `package_already_prepared`: `0`
- `package_ready_unprepared`: `0`
- `split_scope_backlog`: `74`
- `runtime_family_backlog`: `19`
- `manual_mapper_backlog`: `333`
- `blocked_missing_xmage_source`: `4`

## Recommendations

- `P1` After the PG-ready lane shrinks, batch the biggest split-scope cluster. Reason: The partially supported backlog is 74 cards. Top exact cluster: targeted_damage_variant_v1 (20)
- `P1` Open new runtime only on the most reusable family remaining. Reason: Runtime-only backlog is 19 cards. Top reusable exact scope cluster: damage_all_variant_v1 (2). Largest raw family is token_maker (16 cards across 16 scopes), so it should wait for taxonomy/test-miner support instead of leading the queue.
- `P2` Keep the manual mapper lane last. Reason: 333 cards still need mapper/manual review; this lane should not drive executor architecture.
- `P2` Isolate missing-XMage cards as a separate exception lane. Reason: 4 cards are blocked by missing local XMage source.

## Lane Details

### package_already_prepared

- Count: `0`
- Top scope clusters: `none`

### package_ready_unprepared

- Count: `0`
- Top scope clusters: `none`

### split_scope_backlog

- Count: `74`
- Top scope clusters:
  - `targeted_interaction` / `direct_damage` / `targeted_damage_variant_v1`: `20` cards (Balefire Liege, Boros Reckoner, Brash Taunter, Cemetery Gatekeeper, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Gleeful Arsonist, Harsh Mentor)
  - `targeted_interaction` / `draw_cards` / `source_controller_draw_variant_v1`: `13` cards (Arcane Denial, Archivist of Oghma, Bedlam Reveler, Blood Sun, Kefka, Court Mage // Kefka, Ruler of Ruin, Morbid Opportunist, Phyrexian Arena, Psychic Frog)
  - `targeted_interaction` / `add_counters` / `source_add_counters_variant_v1`: `10` cards (Bloodchief Ascension, Brallin, Skyshark Rider, Nightshade Harvester, Palantír of Orthanc, Primal Amulet // Primal Wellspring, Solphim, Mayhem Dominus, Séance Board, Tezzeret, Cruel Captain)
  - `targeted_interaction` / `removal_destroy` / `targeted_destroy_variant_v1`: `10` cards (Abrade, Erode, Infernal Grasp, Rakdos Charm, Sheoldred // The True Scriptures, Star of Extinction, Sundering Eruption // Volcanic Fissure, Suspended Sentence)
  - `creature` / `creature` / `etb_tutor_to_hand_creature_variant_v1`: `2` cards (Rune-Scarred Demon, Starfield Shepherd)
  - `recursion` / `recursion` / `graveyard_to_battlefield_variant_v1`: `2` cards (Forge Anew, The Soul Stone)
  - `static_cost_reducer` / `static_cost_reduction` / `static_self_spell_cost_reduction_variant_v1`: `2` cards (Explosive Singularity, Vanquish the Horde)
  - `controlled_creature_etb_damage_engine` / `creature` / `controlled_creature_enters_damage_each_opponent_v1`: `1` cards (Purphoros, God of the Forge)

### runtime_family_backlog

- Count: `19`
- Top scope clusters:
  - `board_wipe_choice` / `sweeper_damage` / `damage_all_variant_v1`: `2` cards (Ashling, Flame Dancer, Soul Immolation)
  - `board_wipe_choice` / `board_wipe` / `destroy_all_permanents_or_creatures_variant_v1`: `1` cards (Ultima)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_aclazotzdeepestbetrayal_v1`: `1` cards (Aclazotz, Deepest Betrayal // Temple of the Dead)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_adagiawindsweptbastion_v1`: `1` cards (Adagia, Windswept Bastion)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_biotransference_v1`: `1` cards (Biotransference)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_blackmarketconnections_v1`: `1` cards (Black Market Connections)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_blazecommando_v1`: `1` cards (Blaze Commando)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_bonemiser_v1`: `1` cards (Bone Miser)

### manual_mapper_backlog

- Count: `333`
- Top scope clusters:
  - `manual_model` / `external_reference_required_manual_model` / `xmage_reference_requires_manual_model_review_v1`: `332` cards ("Name Sticker" Goblin, Ad Nauseam, Akroma's Will, Alhammarret's Archive, All Is Dust, Altar of Dementia, Aminatou's Augury, Amphibian Downpour)
  - `token_maker` / `token_maker` / `xmage_create_token_variant_spikedcorridortorturepit_v1`: `1` cards (Spiked Corridor // Torture Pit)

### blocked_missing_xmage_source

- Count: `4`
- Top scope clusters:
  - `manual_model` / `` / ``: `4` cards (Alicia Masters, Skilled Sculptor, Mjölnir, Hammer of Thor, Molecule Man, Thor, God of Thunder)
