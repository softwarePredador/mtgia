# Battle Focused Template Missing Builder Priority Audit - 2026-06-19 17:55Z

## Scope

This report turns the current `focused_template_dispatch` gap into an actionable
matrix by card, predicate, deck pressure and required fixture. It is
documentation-only: no PostgreSQL changes, no swaps, no code changes and no
commit.

Primary sources:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175500/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175500/focused_template_dispatch.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

## Current Gate State

Latest checked run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175500/`

Focused dispatch summary:

| Metric | Value |
| --- | ---: |
| `focused_template_cards` | 29 |
| `template_predicate_match` | 29 |
| `without_template_predicate_match` | 0 |
| `supports_template_count` | 47 |
| `evaluate_dispatch_template_count` | 21 |
| `build_evidence_function_count` | 21 |
| `evidence_dispatch_ready` | 0 |
| `focused_evidence_ready` | 0 |
| `focused_evidence_not_ready_unwaived` | 29 |
| `accepted_waivers` | 0 |
| `evidence_runner_status_counts.unsupported` | 29 |

Interpretation:

- The review queue can classify these 29 cards into focused template families.
- `evaluate_draft(...)` cannot route any of those families to a builder.
- Therefore none of these 29 cards has executable focused evidence yet.

## Existing Dispatch Surface

`server/bin/manaloom_battle_rule_focused_evidence.py` currently has:

- 47 `supports_*_template` predicates.
- 21 `build_*_evidence` functions.
- 21 predicates wired through `evaluate_draft(...)`.

The current wired dispatch supports mostly narrow counterspell, simple
destroy/exile, simple draw, treasure, graveyard return, sacrifice damage, extra
combat flashback and artifact tutor evidence paths.

The current 29-card backlog only hits predicates that are not wired to builders.

## Missing Builder Families

| Predicate | Cards | Current cards |
| --- | ---: | --- |
| `supports_manifest_cloak_equipment_template` | 3 | `Cryptic Coat`, `Cursed Windbreaker`, `Dissection Tools` |
| `supports_impulse_topdeck_or_library_zone_template` | 2 | `Heroes' Hangout`, `Opera Love Song` |
| `supports_additional_cost_discard_multi_target_damage_template` | 1 | `Firestorm` |
| `supports_alternative_cost_library_bounce_template` | 1 | `Submerge` |
| `supports_alternative_cost_sacrifice_mountain_damage_template` | 1 | `Mine Collapse` |
| `supports_convoke_damage_template` | 1 | `Stoke the Flames` |
| `supports_copy_artifact_as_enters_template` | 1 | `Copy Artifact` |
| `supports_copy_permanent_flash_or_flashback_template` | 1 | `Flash Photography` |
| `supports_copy_token_delayed_sacrifice_template` | 1 | `Kindle the Inner Flame` |
| `supports_cost_reduction_static_aura_template` | 1 | `Power Artifact` |
| `supports_counter_type_change_template` | 1 | `Ashnod's Transmogrant` |
| `supports_granted_bounce_ability_template` | 1 | `Banishing Knack` |
| `supports_manifest_from_hand_activated_ability_template` | 1 | `Scroll of Fate` |
| `supports_mill_graveyard_return_template` | 1 | `Codex Shredder` |
| `supports_modal_mass_sacrifice_selection_template` | 1 | `Tragic Arrogance` |
| `supports_named_card_cast_restriction_template` | 1 | `Nevermore` |
| `supports_phase_out_mass_removal_counters_template` | 1 | `Out of Time` |
| `supports_planeswalker_static_activated_graveyard_template` | 1 | `Tyvar, Jubilant Brawler` |
| `supports_split_second_damage_template` | 1 | `Sudden Shock` |
| `supports_static_noncreature_tax_template` | 1 | `Thorn of Amethyst` |
| `supports_static_tax_opponent_life_loss_template` | 1 | `God-Pharaoh's Statue` |
| `supports_tap_untap_cipher_trigger_template` | 1 | `Hidden Strings` |
| `supports_type_change_continuous_effect_template` | 1 | `Liquimetal Coating` |
| `supports_utility_artifact_untap_x_lands_template` | 1 | `Candelabra of Tawnos` |
| `supports_vanishing_sacrifice_trigger_removal_template` | 1 | `Reality Acid` |
| `supports_x_vehicle_counters_token_template` | 1 | `Clown Car` |

## Deck Pressure

| Deck | Focused cards affected |
| --- | ---: |
| `Yorion, Sky Nomad #38 (real)` | 8 |
| `Magda, Brazen Outlaw #71 (real)` | 8 |
| `Urza, Lord High Artificer #87 (real)` | 5 |
| `Kraum, Ludevic's Opus #50 (real)` | 2 |
| `Kenrith, the Returned King #113 (real)` | 2 |
| `Ishai, Ojutai Dragonspeaker #28 (real)` | 2 |
| `Gwen Stacy #65 (real)` | 2 |
| `Akiri, Line-Slinger #30 (real)` | 2 |
| `Sisay, Weatherlight Captain #31 (real)` | 1 |
| `Etali, Primal Conqueror #105 (real)` | 1 |

Priority reading:

1. `Yorion` and `Magda` get the largest immediate coverage gain from builders.
2. `manifest/cloak equipment` closes 3 cards with one family.
3. `impulse topdeck/library zone` closes 2 cards with one family.
4. Static/tax, alternative/additional cost and copy/token families are single
   cards each, but they affect rules that are easy to overstate if only the
   predicate is counted.

## Per-Card Matrix

| Card | Predicate | Decks | Required fixture |
| --- | --- | --- | --- |
| `Ashnod's Transmogrant` | `supports_counter_type_change_template` | `Magda, Brazen Outlaw #71 (real)` | `counter_and_artifact_type_change_replay` |
| `Banishing Knack` | `supports_granted_bounce_ability_template` | `Urza, Lord High Artificer #87 (real)` | `grant_activated_bounce_ability_replay` |
| `Candelabra of Tawnos` | `supports_utility_artifact_untap_x_lands_template` | `Akiri, Line-Slinger #30 (real)` | `x_land_untap_activated_ability_replay` |
| `Clown Car` | `supports_x_vehicle_counters_token_template` | `Magda, Brazen Outlaw #71 (real)` | `x_cost_vehicle_counters_and_token_replay` |
| `Codex Shredder` | `supports_mill_graveyard_return_template` | `Urza, Lord High Artificer #87 (real)` | `mill_then_graveyard_return_activated_ability_replay` |
| `Copy Artifact` | `supports_copy_artifact_as_enters_template` | `Kraum, Ludevic's Opus #50 (real)`; `Urza, Lord High Artificer #87 (real)` | `copy_artifact_as_enters_replay` |
| `Cryptic Coat` | `supports_manifest_cloak_equipment_template` | `Yorion, Sky Nomad #38 (real)` | `cloak_equipment_etb_attach_replay` |
| `Cursed Windbreaker` | `supports_manifest_cloak_equipment_template` | `Yorion, Sky Nomad #38 (real)` | `manifest_cloak_equipment_static_grant_replay` |
| `Dissection Tools` | `supports_manifest_cloak_equipment_template` | `Yorion, Sky Nomad #38 (real)` | `manifest_cloak_equipment_lifelink_replay` |
| `Firestorm` | `supports_additional_cost_discard_multi_target_damage_template` | `Ishai, Ojutai Dragonspeaker #28 (real)`; `Kenrith, the Returned King #113 (real)`; `Kraum, Ludevic's Opus #50 (real)` | `discard_x_multi_target_damage_replay` |
| `Flash Photography` | `supports_copy_permanent_flash_or_flashback_template` | `Ishai, Ojutai Dragonspeaker #28 (real)`; `Kenrith, the Returned King #113 (real)` | `copy_permanent_flash_timing_and_flashback_replay` |
| `God-Pharaoh's Statue` | `supports_static_tax_opponent_life_loss_template` | `Magda, Brazen Outlaw #71 (real)` | `static_opponent_tax_and_end_step_life_loss_replay` |
| `Heroes' Hangout` | `supports_impulse_topdeck_or_library_zone_template` | `Gwen Stacy #65 (real)` | `modal_impulse_play_until_next_turn_replay` |
| `Hidden Strings` | `supports_tap_untap_cipher_trigger_template` | `Akiri, Line-Slinger #30 (real)` | `tap_untap_cipher_trigger_replay` |
| `Kindle the Inner Flame` | `supports_copy_token_delayed_sacrifice_template` | `Etali, Primal Conqueror #105 (real)` | `copy_token_delayed_sacrifice_flashback_replay` |
| `Liquimetal Coating` | `supports_type_change_continuous_effect_template` | `Magda, Brazen Outlaw #71 (real)` | `temporary_artifact_type_change_replay` |
| `Mine Collapse` | `supports_alternative_cost_sacrifice_mountain_damage_template` | `Magda, Brazen Outlaw #71 (real)` | `sacrifice_mountain_alternative_cost_damage_replay` |
| `Nevermore` | `supports_named_card_cast_restriction_template` | `Yorion, Sky Nomad #38 (real)` | `named_card_cast_restriction_replay` |
| `Opera Love Song` | `supports_impulse_topdeck_or_library_zone_template` | `Gwen Stacy #65 (real)` | `instant_impulse_play_until_next_turn_replay` |
| `Out of Time` | `supports_phase_out_mass_removal_counters_template` | `Yorion, Sky Nomad #38 (real)` | `mass_phase_out_duration_counters_replay` |
| `Power Artifact` | `supports_cost_reduction_static_aura_template` | `Urza, Lord High Artificer #87 (real)` | `enchanted_artifact_activation_cost_reduction_replay` |
| `Reality Acid` | `supports_vanishing_sacrifice_trigger_removal_template` | `Yorion, Sky Nomad #38 (real)` | `vanishing_sacrifice_enchanted_permanent_replay` |
| `Scroll of Fate` | `supports_manifest_from_hand_activated_ability_template` | `Yorion, Sky Nomad #38 (real)` | `manifest_card_from_hand_replay` |
| `Stoke the Flames` | `supports_convoke_damage_template` | `Magda, Brazen Outlaw #71 (real)` | `convoke_damage_payment_replay` |
| `Submerge` | `supports_alternative_cost_library_bounce_template` | `Urza, Lord High Artificer #87 (real)` | `alternative_cost_top_of_library_bounce_replay` |
| `Sudden Shock` | `supports_split_second_damage_template` | `Magda, Brazen Outlaw #71 (real)` | `split_second_damage_priority_lock_replay` |
| `Thorn of Amethyst` | `supports_static_noncreature_tax_template` | `Magda, Brazen Outlaw #71 (real)` | `static_noncreature_spell_tax_replay` |
| `Tragic Arrogance` | `supports_modal_mass_sacrifice_selection_template` | `Yorion, Sky Nomad #38 (real)` | `per_player_permanent_type_choice_sacrifice_replay` |
| `Tyvar, Jubilant Brawler` | `supports_planeswalker_static_activated_graveyard_template` | `Sisay, Weatherlight Captain #31 (real)` | `planeswalker_static_haste_and_graveyard_activation_replay` |

## Required Adjustment

The gate should remain `review_required` until each current focused card has
one of:

1. a `build_*_evidence` function wired through `evaluate_draft(...)`;
2. passing focused artifacts proving replay events, decision trace and audit
   behavior;
3. an accepted waiver explaining why focused evidence is not required.

## Register Update

Open finding added in
`docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`:

- `BV-054`: focused template backlog needs a builder/waiver priority matrix,
  not only a global count of unsupported cards.
