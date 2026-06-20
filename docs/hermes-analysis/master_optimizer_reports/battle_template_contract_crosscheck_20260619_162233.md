# Battle Template Contract Crosscheck - 2026-06-19T16:22:33Z

## Scope

Artifact-only validation slice for card action templates and focused evidence.
This audit does not change PostgreSQL, swaps, product code, or automation code.

Inputs:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161528`
- Latest effect coverage:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161528/effect_coverage.json`
- Generated crosscheck artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_template_contract_162233/template_contract_crosscheck.json`

## Current Latest Snapshot

Latest `summary.json` at `2026-06-19T16:15:28Z`:

- `events`: `1073`
- `action_findings`: `0`
- `strategy_findings`: `0`
- `decision_audit_turn_findings`: `0`
- `decision_audit_decision_findings`: `0`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- `effect_coverage_unknowns`: `33`
- `heuristic_effects`: `120`
- `runtime_safe_rule_names`: `1702`
- `active_or_review_rule_names`: `3159`
- `review_only_rule_names`: `1457`
- `review_only_rule_instances`: `34`

Effect coverage flags:

| Flag | Count |
| --- | ---: |
| `trigger_not_explicit` | 147 |
| `heuristic_effect` | 120 |
| `cast_permission_not_explicit` | 89 |
| `temporary_effect_not_explicit` | 65 |
| `land_utility_ability_not_modeled` | 48 |
| `review_only_rule` | 34 |
| `unknown_effect` | 33 |
| `oracle_target_removal_mismatch` | 20 |
| `oracle_silence_mismatch` | 15 |
| `copy_effect_mismatch` | 1 |

Source totals:

| Source | Count |
| --- | ---: |
| `battle_rule_curated` | 724 |
| `battle_rule_review_only_generated` | 34 |
| `effect_map` | 100 |
| `tag` | 20 |
| `type_land` | 377 |
| `unknown` | 33 |

## Tests Run

Validation commands run in this slice:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` - PASS, `3` tests.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py` - PASS.
- `python3 server/test/manaloom_review_queue_consumers_test.py` - PASS, `11` tests.

The tests prove that the existing review queue, focused evidence, promotion
gate, and runtime-safe separation work for their fixture cases. They do not
prove that the current unknown backlog has focused templates.

## Focused Evidence Template Surface

`server/bin/manaloom_battle_rule_focused_evidence.py` exposes `21`
`supports_*_template` functions. The supported surface is intentionally narrow:

- exact `Counter target spell.`;
- sacrifice-creature damage outlets;
- extra combat plus flashback;
- attack trigger creating Treasure plus artifact tutor;
- exact destroy/exile templates for creature, nonland permanent, artifact,
  enchantment, artifact-or-enchantment, and all creatures;
- creatures you control gain indestructible until end of turn;
- exact `Create a Treasure token.`;
- exact draw one/two/three cards;
- exact return target creature/artifact/enchantment/artifact-or-enchantment
  card from graveyard to hand.

This is useful and safer than broad promotion, but it is not a complete card
action template library.

## Current Unknown Backlog Crosscheck

The latest coverage contains `29` distinct `unknown_cards`.

Crosscheck against `infer_effect_families_from_text(...)` using full corpus
oracle text where available:

- `6/29` unknown cards inferred at least one effect family.
- `23/29` unknown cards inferred no family.
- Inferred families observed:
  - `copy_spell_or_permanent`: `3`
  - `counter_manipulation`: `2`
  - `graveyard_recast_replacement`: `2`
  - `targeted_interaction`: `1`

Crosscheck against the `21` focused evidence support functions:

- `0/29` unknown cards matched a focused evidence template.
- `29/29` unknown cards are still outside focused-template coverage.

Cards without focused template match:

- `Banishing Knack`
- `Flash Photography`
- `Heroes' Hangout`
- `Hidden Strings`
- `Kindle the Inner Flame`
- `Liquimetal Coating`
- `Opera Love Song`
- `Submerge`
- `Ashnod's Transmogrant`
- `Candelabra of Tawnos`
- `Clown Car`
- `Codex Shredder`
- `Copy Artifact`
- `Cryptic Coat`
- `Cursed Windbreaker`
- `Dissection Tools`
- `Firestorm`
- `God-Pharaoh's Statue`
- `Mine Collapse`
- `Nevermore`
- `Out of Time`
- `Power Artifact`
- `Reality Acid`
- `Scroll of Fate`
- `Stoke the Flames`
- `Sudden Shock`
- `Thorn of Amethyst`
- `Tragic Arrogance`
- `Tyvar, Jubilant Brawler`

## Operational Reading

The answer to "are all card action templates created?" is still no for the
current battle corpus.

The current implementation has real focused templates and fixture coverage, but
the latest unknown backlog is dominated by families outside that template
surface: alternative/additional cost, impulse/topdeck permission, tap/untap,
manifest/cloak/face-down, static tax/restriction, modal sacrifice, split second,
counter/type manipulation, and complex copy/continuous effects.

`server/test/manaloom_review_queue_consumers_test.py` passing is valuable, but
it currently proves that supported fixture families work. It does not prove the
actual `29` unknown cards have a family, template, focused replay, or waiver.

## Required Follow-Up

- Add a generated or maintained `BATTLE_EFFECT_TEMPLATE_CONTRACT` that maps each
  `effect_json.effect` and backlog family to:
  runtime handler, replay events, action critic behavior, forensic support,
  focused template status, fixture, current coverage count, and
  runtime-safe/review-only/needs-review mode.
- Add an audit/report that directly joins current `unknown_cards` to
  `supports_*_template` coverage and fails or flags when a card has neither a
  focused template nor an explicit waiver.
- Expand `infer_effect_families_from_text(...)` for the missing families or
  add explicit family mapping/waiver records.

