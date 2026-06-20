# Battle Unknown Template Backlog Manifest - 2026-06-19T16:46Z

## Scope

Artifact-only manifest for current `unknown_cards` in the battle effect
coverage. This report checks the latest coverage backlog against:

- current `infer_effect_families_from_text(...)`;
- current focused evidence `supports_*_template(...)` functions;
- latest runtime coverage artifact.

No PostgreSQL changes, swaps, commits, product-code edits, or automation edits
were made.

## Inputs

- Coverage JSON:
  `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260619_1638_runtime_status.json`
- Generated JSON artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/unknown_template_backlog_1642/unknown_template_backlog.json`
- Review queue inference:
  `server/bin/manaloom_battle_rule_review_queue.py`
- Focused evidence templates:
  `server/bin/manaloom_battle_rule_focused_evidence.py`

## Validation Commands

- Generated the per-card manifest from the current coverage JSON, importing the
  current review/focused-evidence functions.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `5` tests.
- `python3 server/test/manaloom_review_queue_consumers_test.py` - PASS, `11` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py` - PASS.

## Summary

- `unknown_cards`: `29`
- `with_current_inferred_family`: `5`
- `without_current_inferred_family`: `24`
- `with_focused_template_match`: `0`
- `without_focused_template_match`: `29`

Operational reading: all `29` current unknown cards remain outside the focused
evidence template surface. The review/focused pipeline is working for fixture
families, but it does not yet cover the current backlog.

## Per-Card Backlog

`Observed gap family` is an audit bucket derived from the latest oracle sample;
it is not an implementation decision. `Current inferred families` are only what
the current `infer_effect_families_from_text(...)` returned.

| Card | Type | Observed gap family | Current inferred families | Focused template match | Flags | Decks |
| --- | --- | --- | --- | --- | --- | --- |
| `Banishing Knack` | `Instant` | `tap_untap_bounce_granted_ability` | `-` | `-` | `temporary_effect_not_explicit, unknown_effect` | Urza, Lord High Artificer #87 (real) |
| `Flash Photography` | `Sorcery` | `copy_permanent_with_flash_condition_and_flashback` | `copy_spell_or_permanent, graveyard_recast_replacement` | `-` | `cast_permission_not_explicit, unknown_effect` | Ishai, Ojutai Dragonspeaker #28 (real); Kenrith, the Returned King #113 (real) |
| `Heroes' Hangout` | `Sorcery` | `modal_impulse_play_or_unfinished_target_text` | `-` | `-` | `temporary_effect_not_explicit, unknown_effect` | Gwen Stacy #65 (real) |
| `Hidden Strings` | `Sorcery` | `tap_untap_cipher_trigger` | `-` | `-` | `trigger_not_explicit, unknown_effect` | Akiri, Line-Slinger #30 (real) |
| `Kindle the Inner Flame` | `Kindred Sorcery - Elemental` | `copy_token_and_graveyard_recast` | `copy_spell_or_permanent, graveyard_recast_replacement` | `-` | `cast_permission_not_explicit, unknown_effect` | Etali, Primal Conqueror #105 (real) |
| `Liquimetal Coating` | `Artifact` | `type_change_continuous_effect` | `-` | `-` | `temporary_effect_not_explicit, unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Opera Love Song` | `Instant` | `impulse_play_until_next_turn` | `-` | `-` | `temporary_effect_not_explicit, unknown_effect` | Gwen Stacy #65 (real) |
| `Submerge` | `Instant` | `alternative_cost_library_bounce` | `-` | `-` | `cast_permission_not_explicit, unknown_effect` | Urza, Lord High Artificer #87 (real) |
| `Ashnod's Transmogrant` | `Artifact` | `counter_manipulation_and_type_change` | `counter_manipulation` | `-` | `unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Candelabra of Tawnos` | `Artifact` | `utility_artifact_untap_x_lands` | `-` | `-` | `unknown_effect` | Akiri, Line-Slinger #30 (real) |
| `Clown Car` | `Artifact - Vehicle` | `x_cost_counters_vehicle_token` | `counter_manipulation` | `-` | `unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Codex Shredder` | `Artifact` | `mill_and_graveyard_return` | `-` | `-` | `unknown_effect` | Urza, Lord High Artificer #87 (real) |
| `Copy Artifact` | `Enchantment` | `copy_artifact_static_as_enters` | `-` | `-` | `unknown_effect` | Kraum, Ludevic's Opus #50 (real); Urza, Lord High Artificer #87 (real) |
| `Cryptic Coat` | `Artifact - Equipment` | `manifest_cloak_equipment` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Cursed Windbreaker` | `Artifact - Equipment` | `manifest_cloak_equipment` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Dissection Tools` | `Artifact - Equipment` | `manifest_cloak_equipment` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Firestorm` | `Instant` | `additional_cost_discard_multi_target_damage` | `-` | `-` | `unknown_effect` | Ishai, Ojutai Dragonspeaker #28 (real); Kenrith, the Returned King #113 (real); Kraum, Ludevic's Opus #50 (real) |
| `God-Pharaoh's Statue` | `Legendary Artifact` | `static_tax_and_opponent_life_loss` | `-` | `-` | `unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Mine Collapse` | `Instant` | `alternative_cost_sacrifice_mountain_damage` | `targeted_interaction` | `-` | `unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Nevermore` | `Enchantment` | `static_named_card_cast_restriction` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Out of Time` | `Enchantment` | `phase_out_mass_removal_counters` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Power Artifact` | `Enchantment - Aura` | `cost_reduction_static_aura` | `-` | `-` | `unknown_effect` | Urza, Lord High Artificer #87 (real) |
| `Reality Acid` | `Enchantment - Aura` | `vanishing_sacrifice_trigger_removal` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Scroll of Fate` | `Artifact` | `manifest_from_hand_activated_ability` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Stoke the Flames` | `Instant` | `convoke_damage` | `-` | `-` | `unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Sudden Shock` | `Instant` | `split_second_damage` | `-` | `-` | `unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Thorn of Amethyst` | `Artifact` | `static_noncreature_tax` | `-` | `-` | `unknown_effect` | Magda, Brazen Outlaw #71 (real) |
| `Tragic Arrogance` | `Sorcery` | `modal_mass_sacrifice_selection` | `-` | `-` | `unknown_effect` | Yorion, Sky Nomad #38 (real) |
| `Tyvar, Jubilant Brawler` | `Legendary Planeswalker - Tyvar` | `planeswalker_static_and_activated_graveyard_ability` | `-` | `-` | `unknown_effect` | Sisay, Weatherlight Captain #31 (real) |

## Priority Reading

The backlog is not one missing generic template. It is a set of distinct rule
families. The largest repeated family is `manifest_cloak_equipment` with three
cards. Everything else is effectively one-off or narrow-family work.

High-priority families for triage:

- alternative/additional cost plus damage or bounce:
  `Submerge`, `Mine Collapse`, `Firestorm`, `Stoke the Flames`;
- static tax/cast restriction:
  `God-Pharaoh's Statue`, `Thorn of Amethyst`, `Nevermore`;
- manifest/cloak:
  `Cryptic Coat`, `Cursed Windbreaker`, `Dissection Tools`, `Scroll of Fate`;
- tap/untap and activated utility:
  `Banishing Knack`, `Hidden Strings`, `Candelabra of Tawnos`;
- complex copy/type/counter manipulation:
  `Flash Photography`, `Kindle the Inner Flame`, `Copy Artifact`,
  `Liquimetal Coating`, `Ashnod's Transmogrant`, `Clown Car`.

## Required Follow-Up

- Add a recurring backlog manifest that persists per-card family, current
  inference result, focused template match, waiver status, and owner.
- Expand `infer_effect_families_from_text(...)` for the `24` cards without a
  current family, or add explicit family mappings.
- Do not create a broad "unknown handler"; add narrow templates, fixtures, or
  `not_required` waivers per family/card.
- Treat green review/focused-evidence tests as fixture coverage only until at
  least one current unknown card in the backlog has a passing focused evidence
  path or an explicit waiver.
