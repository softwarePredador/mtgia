# Deck Card Battle Rule Coherence Audit

Generated at: `2026-06-25T01:58:22+00:00`

Scope: distinct cards referenced by Hermes `deck_cards` for `deck_id=617`.

This is an audit queue. It does not promote rules and does not mutate PostgreSQL/SQLite.

## Summary

- Total deck cards: `97`
- critical: `0`
- high: `49`
- medium: `2`
- low: `0`
- pass: `46`

## Finding Counts

- `review_only_or_needs_review_rule`: `29`
- `no_trusted_executable_rule`: `24`
- `no_active_battle_rule`: `22`
- `generic_effect_without_model_scope`: `3`
- `trusted_rule_without_oracle_hash`: `3`

## Top 51 Actionable Cards

| Severity | Impact | Priority | Card | Decks | Qty | Findings | Effects |
| --- | --- | ---: | --- | ---: | ---: | --- | --- |
| `high` | `battle_critical` | 7051 | `Arcane Denial` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7051 | `Archfiend of Ifnir` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Bloodchief Ascension` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Bone Miser` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Dark Deal` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Exquisite Blood` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Kaya's Ghostform` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Magmakin Artillerist` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Mana Drain` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `counter` |
| `high` | `battle_critical` | 7051 | `Painful Quandary` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Phyrexian Arena` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Psychic Frog` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Psychosis Crawler` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Sheoldred, the Apocalypse` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_critical` | 7051 | `Solphim, Mayhem Dominus` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `finisher` |
| `high` | `battle_critical` | 7051 | `The Locust God` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Toxic Deluge` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_cards` |
| `high` | `battle_critical` | 7051 | `Vandalblast` | 1 | 1 | `review_only_or_needs_review_rule`, `generic_effect_without_model_scope`, `trusted_rule_without_oracle_hash` | `remove_permanent` |
| `high` | `battle_critical` | 7051 | `Waste Not` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `token_maker` |
| `high` | `battle_critical` | 7051 | `Whip of Erebos` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `recursion` |
| `high` | `battle_critical` | 7051 | `Withering Torment` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `remove_creature` |
| `high` | `battle_critical` | 7051 | `Wound Reflection` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `draw_engine` |
| `high` | `battle_support` | 7051 | `Black Market Connections` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_engine` |
| `high` | `battle_support` | 7051 | `Vivi Ornitier` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `ramp_ritual` |
| `high` | `support_or_passive` | 7051 | `Aclazotz, Deepest Betrayal // Temple of the Dead` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bloodletter of Aclazotz` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Bloodthirsty Conqueror` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Brallin, Skyshark Rider` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Containment Construct` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Court of Ambition` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Davros, Dalek Creator` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Entropic Battlecruiser` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Fell Specter` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Green Goblin, Nemesis` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Harmonic Prodigy` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Kefka, Court Mage // Kefka, Ruler of Ruin` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Liliana's Caress` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Necrogoyf` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Niv-Mizzet, Parun` | 1 | 1 | `no_trusted_executable_rule`, `review_only_or_needs_review_rule` | `creature` |
| `high` | `support_or_passive` | 7051 | `Oppression` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Raiders' Wake` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sangromancer` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Sheoldred // The True Scriptures` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Syr Konrad, the Grim` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Teferi's Time Twist` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `The Haunt of Hightower` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tinybones, Bauble Burglar` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Tinybones, Trinket Thief` | 1 | 1 | `no_active_battle_rule` | - |
| `high` | `support_or_passive` | 7051 | `Words of Waste` | 1 | 1 | `no_active_battle_rule` | - |
| `medium` | `land_or_mana_base` | 4051 | `Scavenger Grounds` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |
| `medium` | `land_or_mana_base` | 4051 | `Urborg, Tomb of Yawgmoth` | 1 | 1 | `review_only_or_needs_review_rule` | `land` |

## Required Card-By-Card Gate

A card can move out of the queue only when all applicable evidence exists:

- oracle/type identity is present or an explicit no-text exception is documented;
- broad generated/heuristic behavior is replaced by a reviewed battle model;
- `card_battle_rules` has a stable `logical_rule_key`, `oracle_hash`, review status, and execution status;
- complex effects include `battle_model_scope` or equivalent oracle-specific marker;
- focused unit tests prove the modeled behavior and relevant negative cases;
- replay/events prove the selected `logical_rule_key` in a real or focused battle;
- PostgreSQL precheck/apply/postcheck/rollback and SQLite sync evidence exist before promotion.
