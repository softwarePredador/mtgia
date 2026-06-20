# Battle Effect Template Residual Contract Audit - 2026-06-19T18:56Z

## Scope

Read-only audit of current card-action template coverage. This report answers a
narrow question: when the latest recurring battle run is trusted, what exactly
is proven about action templates, and what is only covered by accepted residual
contracts?

No PostgreSQL changes, swaps, runtime-code edits, automation edits, or commits
were made.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

## Latest Gate Status

| Metric | Value |
| --- | ---: |
| `timestamp_utc` | `2026-06-19T18:47:21Z` |
| `battle_replay_final_status` | `trusted_for_strategy_learning` |
| `battle_replay_final_status_reason` | `all_mandatory_gates_pass` |
| `mandatory_gate_divergences` | `[]` |
| `seeds_completed` | `16` |
| `events` | `14679` |
| `decisions` | `2265` |
| `seeds_with_high_or_critical_action_findings` | `[]` |
| `seeds_with_strategy_blockers` | `[]` |

There is no current high/critical action or strategy-blocker notification
condition.

## What Is Proven For Focused Templates

The focused-template backlog for the current corpus is ready:

| Metric | Value |
| --- | ---: |
| `focused_template_dispatch.status` | `focused_template_dispatch_ready` |
| `focused_template_cards` | `29` |
| `template_predicate_match` | `29` |
| `evidence_dispatch_ready` | `29` |
| `focused_evidence_ready` | `29` |
| `focused_evidence_not_ready_unwaived` | `0` |
| `accepted_waivers` | `0` |
| `supports_template_count` | `47` |
| `evaluate_dispatch_template_count` | `47` |
| `build_evidence_function_count` | `47` |
| `supports_not_dispatched` | `[]` |

Static inspection of `server/bin/manaloom_battle_rule_focused_evidence.py`
also found:

- `47` `supports_*_template` predicates.
- `47` `build_*_evidence` builders.
- The dispatch audit reports `supports_not_dispatched=[]`, so the non-1:1
  helper naming for shared builders is not a live dispatch gap.

Interpretation: for the current focused backlog, all `29` focused-template
cards have a dispatchable predicate and generated evidence.

## What Is Not Proven Globally

The same latest run still has accepted residual coverage. These are not
blocking, but they are not the same as card-specific runtime/template proof.

| Residual metric | Value |
| --- | ---: |
| `effect_coverage_residual_status` | `effect_coverage_residual_accepted` |
| `raw_flag_total` | `539` |
| `unique_flagged_cards` | `240` |
| `card_flag_rows` | `293` |
| `accepted_card_flag_rows` | `293` |
| `unaccepted_card_flag_rows` | `0` |
| `raw_unaccepted_flags` | `[]` |
| `unknown_cards` | `[]` |

Accepted residuals by owner:

| Owner | Card-flag rows | Meaning |
| --- | ---: | --- |
| `battle-effect-contract` | `153` | Timing, trigger, target, silence, temporary, copy-effect contract residuals are accepted for now. |
| `battle-heuristic-fallback` | `90` | Effect-map/tag fallbacks are allowed as denominators, not card-specific learning evidence. |
| `battle-rule-review-queue` | `29` | Generated `needs_review` rules remain visible but are not runtime-safe learning proof. |
| `battle-land-utility-contract` | `21` | Utility land abilities remain accepted residuals rather than fully modeled behavior. |

Accepted residuals by flag:

| Flag | Accepted card rows |
| --- | ---: |
| `heuristic_effect` | `90` |
| `trigger_not_explicit` | `63` |
| `temporary_effect_not_explicit` | `38` |
| `cast_permission_not_explicit` | `35` |
| `needs_review_rule` | `29` |
| `land_utility_ability_not_modeled` | `21` |
| `oracle_target_removal_mismatch` | `12` |
| `oracle_silence_mismatch` | `4` |
| `copy_effect_mismatch` | `1` |

Source mix for accepted residual rows:

| Source | Card-flag rows |
| --- | ---: |
| `battle_rule_curated` | `104` |
| `effect_map` | `95` |
| `battle_rule_needs_review_generated` | `41` |
| `tag` | `23` |
| `type_land` | `22` |
| `focused_template_ready` | `8` |

Top residual decks:

| Deck | Residual rows |
| --- | ---: |
| `Lumra, Bellow of the Woods #49 (real)` | `52` |
| `Magda, Brazen Outlaw #71 (real)` | `51` |
| `Akiri, Line-Slinger #30 (real)` | `44` |
| `Gwen Stacy #65 (real)` | `44` |
| `Ishai, Ojutai Dragonspeaker #28 (real)` | `44` |
| `Kinnan, Bonder Prodigy #37 (real)` | `43` |
| `Sisay, Weatherlight Captain #31 (real)` | `41` |
| `Kraum, Ludevic's Opus #50 (real)` | `40` |
| `Kenrith, the Returned King #113 (real)` | `40` |
| `Urza, Lord High Artificer #87 (real)` | `39` |
| `Yorion, Sky Nomad #38 (real)` | `34` |
| `Etali, Primal Conqueror #105 (real)` | `34` |
| `Lorehold target deck` | `33` |

## Priority Examples

Needs-review generated rules still visible in the corpus include:

- `Aether Channeler`, `Amulet of Vigor`, `Blood Moon`, `Dispel`,
  `Ephemerate`, `Exploration`, `Ghostly Flicker`, `Grasp of Fate`,
  `Lotus Cobra`, `Reality Shift`, `Resculpt`, `Snuff Out`,
  `Tibalt's Trickery`, `Tormod's Crypt`, `Veil of Summer`.

Heuristic fallback rows include broad creature/effect-map/tag examples such as:

- `Aarakocra Sneak`, `Adaptive Automaton`, `Battered Golem`,
  `Displacer Kitten`, `Endurance`, `Etherium Sculptor`, `Gilded Drake`,
  `Permission Denied`, `Wandering Archaic`.

Utility-land residual examples include:

- `Boseiju, Who Endures`, `City of Brass`, `Field of the Dead`,
  `Ghost Quarter`, `Mirrorpool`, `Otawara, Soaring City`,
  `Shifting Woodland`, `Sunbaked Canyon`, `Urza's Saga`, `War Room`,
  `Wasteland`.

## Interpretation

It is correct to say:

- the latest recurring battle is trusted under current mandatory gates;
- the current unknown-card backlog is empty;
- the current focused-template backlog has `29/29` evidence-ready cards;
- the focused evidence code has `47/47` supports/build/dispatch coverage.

It is not correct to say:

- every card action in the broader corpus has a card-specific runtime template;
- every residual timing/trigger/cast-permission/land-utility behavior is fully
  implemented;
- `needs_review` generated rules are runtime-safe learning evidence.

Accepted residual contracts are valid gates, but they are still waivers or
denominator policy. They must remain visible in any "all templates are created"
claim.

## Suggested Follow-Up

- Keep focused-template readiness and residual coverage as separate denominators
  in the register and any optimizer handoff.
- When claiming template completeness, say "current focused backlog" rather than
  "all card actions" unless residual rows are also reduced or explicitly scoped.
- Prioritize residual reduction where the same card is both high-frequency and
  strategically meaningful: needs-review generated interaction, utility lands,
  trigger engines, and cast-permission effects.
