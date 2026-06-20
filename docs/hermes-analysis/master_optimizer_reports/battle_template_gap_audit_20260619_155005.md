# Battle Template Gap Audit - 2026-06-19T15:50Z

## Scope

Read-only validation of the current action-template pipeline for ManaLoom
battle rules. No PostgreSQL changes, no swaps, no code changes, and no commit.

## Sources Checked

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `server/bin/manaloom_battle_rule_review_queue.py`
- `server/bin/manaloom_battle_rule_focused_evidence.py`
- `server/bin/manaloom_battle_rule_promotion_gate.py`
- `server/test/manaloom_review_queue_consumers_test.py`
- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`

## Commands Run

```text
python3 -m py_compile server/bin/manaloom_battle_rule_review_queue.py server/bin/manaloom_battle_rule_focused_evidence.py server/bin/manaloom_battle_rule_promotion_gate.py
python3 server/test/manaloom_review_queue_consumers_test.py
```

Results:

- `py_compile`: PASS
- `manaloom_review_queue_consumers_test.py`: `Ran 11 tests`, `OK`

## Current Focused Evidence Templates

The current `manaloom_battle_rule_focused_evidence.py` exposes `21`
`supports_*_template` helpers:

| Template helper | Scope |
| --- | --- |
| `supports_counterspell_template` | Exact counterspell stack interaction. |
| `supports_destroy_target_creature_template` | Exact simple destroy target creature. |
| `supports_destroy_target_nonland_permanent_template` | Exact simple destroy target nonland permanent. |
| `supports_destroy_target_artifact_template` | Exact simple destroy target artifact. |
| `supports_destroy_target_enchantment_template` | Exact simple destroy target enchantment. |
| `supports_destroy_all_creatures_template` | Exact simple destroy all creatures. |
| `supports_exile_target_creature_template` | Exact simple exile target creature. |
| `supports_exile_target_nonland_permanent_template` | Exact simple exile target nonland permanent. |
| `supports_exile_target_artifact_template` | Exact simple exile target artifact. |
| `supports_exile_target_enchantment_template` | Exact simple exile target enchantment. |
| `supports_exile_target_artifact_or_enchantment_template` | Exact simple exile target artifact or enchantment. |
| `supports_creatures_indestructible_template` | Narrow protection against board wipe. |
| `supports_simple_treasure_template` | Exact create a Treasure token. |
| `supports_simple_draw_card_template` | Exact draw one/two/three cards. |
| `supports_return_target_creature_from_graveyard_template` | Exact return target creature card from graveyard to hand. |
| `supports_return_target_artifact_from_graveyard_template` | Exact return target artifact card from graveyard to hand. |
| `supports_return_target_enchantment_from_graveyard_template` | Exact return target enchantment card from graveyard to hand. |
| `supports_return_target_artifact_or_enchantment_from_graveyard_template` | Exact return target artifact or enchantment card from graveyard to hand. |
| `supports_sacrifice_damage_template` | Sacrifice a creature for damage to a target. |
| `supports_extra_combat_flashback_template` | Additional combat plus flashback. |
| `supports_attack_artifact_tutor_template` | Attack trigger, Treasure, artifact sacrifice, artifact tutor. |

These templates are intentionally narrow. `evidence_ready` remains report-only
and is not automatic promotion.

## Latest Unknown Coverage

Latest coverage file:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- generated at: `2026-06-19T15:38:23.595284+00:00`
- `unknown_cards`: `29`
- supported by current focused-evidence templates: `0/29`
- inferred by `infer_effect_families_from_text(...)`: `5/29`
- no inferred family: `24/29`

Family counts inferred from the current review queue:

| Inferred family | Cards |
| --- | ---: |
| `copy_spell_or_permanent` | 2 |
| `graveyard_recast_replacement` | 2 |
| `counter_manipulation` | 2 |
| `targeted_interaction` | 1 |

Unknown cards by deck:

| Deck | Unknown count |
| --- | ---: |
| `Magda, Brazen Outlaw #71 (real)` | 8 |
| `Yorion, Sky Nomad #38 (real)` | 8 |
| `Urza, Lord High Artificer #87 (real)` | 5 |
| `Ishai, Ojutai Dragonspeaker #28 (real)` | 2 |
| `Kenrith, the Returned King #113 (real)` | 2 |
| `Gwen Stacy #65 (real)` | 2 |
| `Akiri, Line-Slinger #30 (real)` | 2 |
| `Kraum, Ludevic's Opus #50 (real)` | 2 |
| `Etali, Primal Conqueror #105 (real)` | 1 |
| `Sisay, Weatherlight Captain #31 (real)` | 1 |

## Current Unknown Cards

| Card | Current inferred family | Focused template support | Primary missing shape |
| --- | --- | --- | --- |
| `Banishing Knack` | none | none | temporary granted activated bounce ability |
| `Flash Photography` | `copy_spell_or_permanent`, `graveyard_recast_replacement` | none | conditional flash, copy permanent token, flashback |
| `Heroes' Hangout` | none | none | modal impulse/topdeck play permission and pump |
| `Hidden Strings` | none | none | tap/untap targets plus cipher trigger |
| `Kindle the Inner Flame` | `copy_spell_or_permanent`, `graveyard_recast_replacement` | none | copy creature token, haste, delayed sacrifice, flashback alternative cost |
| `Liquimetal Coating` | none | none | temporary type-changing activated ability |
| `Opera Love Song` | none | none | modal impulse play permission or pump |
| `Submerge` | none | none | alternative free cast condition plus put creature on library |
| `Ashnod's Transmogrant` | `counter_manipulation` | none | counter plus permanent type change |
| `Candelabra of Tawnos` | none | none | variable untap target lands |
| `Clown Car` | `counter_manipulation` | none | dice, tokens, counters, vehicle |
| `Codex Shredder` | none | none | mill plus generic graveyard card recursion |
| `Copy Artifact` | none | none | ETB copy artifact as enchantment |
| `Cryptic Coat` | none | none | cloak top card and attach equipment |
| `Cursed Windbreaker` | none | none | manifest dread and attach equipment |
| `Dissection Tools` | none | none | manifest dread, static buffs, equip sacrifice cost |
| `Firestorm` | none | none | additional discard X cost and X targets damage |
| `God-Pharaoh's Statue` | none | none | static tax plus recurring life loss |
| `Mine Collapse` | `targeted_interaction` | none | alternative sacrifice cost plus damage to creature/planeswalker |
| `Nevermore` | none | none | named-card cast restriction |
| `Out of Time` | none | none | mass phase-out, counters, delayed sacrifice |
| `Power Artifact` | none | none | activated ability cost reduction aura |
| `Reality Acid` | none | none | vanishing, delayed sacrifice, enchanted permanent sacrifice |
| `Scroll of Fate` | none | none | manifest card from hand |
| `Stoke the Flames` | none | none | convoke cost and damage to any target |
| `Sudden Shock` | none | none | split second and damage to any target |
| `Thorn of Amethyst` | none | none | static noncreature spell tax |
| `Tragic Arrogance` | none | none | modal multi-player permanent sacrifice selection |
| `Tyvar, Jubilant Brawler` | none | none | static ability haste, loyalty untap, mill/recursion |

## Findings

1. The pipeline for simple templates is healthy: syntax passes and the consumer
   test suite passes.
2. The current unknown backlog is outside the supported focused-evidence
   surface. None of the `29` unknown cards match any current `supports_*`
   template.
3. The review queue still under-classifies real unknowns: `24/29` current
   unknown cards receive no inferred effect family.
4. Some cards receive a broad family but still cannot be evaluated safely:
   `Flash Photography`, `Kindle the Inner Flame`, `Ashnod's Transmogrant`,
   `Clown Car`, and `Mine Collapse`.
5. Therefore, it is not correct to say that all action templates exist for the
   current Lorehold plus 12-opponent corpus.

## Recommended Register Updates

- Keep `BV-011`, `BV-014`, and `BV-015` open.
- Add a specific finding that `0/29` current unknowns are covered by current
  focused-evidence templates.
- Add a test-gap note: consumer tests prove supported simple templates, not the
  current unknown backlog.
