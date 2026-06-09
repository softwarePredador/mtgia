# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:05:14 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 178
- card_events: 59
- unique_cards_seen: 41
- findings_total: 14
- critical: 1
- high: 8
- medium: 1
- low: 4

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 27 |
| `manual` | 17 |
| `generated` | 6 |
| `type_line_creature` | 5 |
| `functional_tag` | 2 |
| `unknown` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 44 |
| `needs_review` | 6 |
| `fact` | 5 |
| `heuristic` | 2 |
| `missing` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 16 |
| `creature` | 7 |
| `ramp_permanent` | 5 |
| `redirect_removal` | 4 |
| `remove_creature` | 3 |
| `counter` | 2 |
| `draw_cards` | 2 |
| `equipment_haste_shroud` | 2 |
| `indestructible` | 2 |
| `modal_boros_charm` | 2 |
| `overload_recursion` | 2 |
| `ramp_ritual` | 2 |
| `remove_permanent` | 2 |
| `token_maker` | 2 |
| `tutor` | 2 |
| `unknown` | 2 |
| `commander` | 1 |
| `ramp_engine` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| critical | seed_42 | 2 | - | Magda, Brazen Outlaw #90 (real) | spell_resolved | Shatterskull Smashing | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_42 | 10 | precombat_main | Lorehold | spell_cast | Mother of Runes | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 10 | - | Lorehold | spell_resolved | Mother of Runes | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 2 | precombat_main | Magda, Brazen Outlaw #90 (real) | spell_cast | Shatterskull Smashing | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_42 | 2 | precombat_main | Rograkh, Son of Rohgahh #94 (real) | spell_cast | Chain of Vapor | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 2 | - | Rograkh, Son of Rohgahh #94 (real) | spell_resolved | Chain of Vapor | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 3 | precombat_main | Magda, Brazen Outlaw #90 (real) | spell_cast | Untimely Malfunction | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 3 | - | Magda, Brazen Outlaw #90 (real) | spell_resolved | Untimely Malfunction | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 4 | - | Magda, Brazen Outlaw #90 (real) | spell_resolved | Smuggler's Copter | draw_cards | Game event depended on heuristic source `functional_tag`. | Move this card into card_battle_rules with verified/active status. |
| medium | seed_42 | 4 | precombat_main | Magda, Brazen Outlaw #90 (real) | spell_cast | Smuggler's Copter | draw_cards | Game event depended on heuristic source `functional_tag`. | Move this card into card_battle_rules with verified/active status. |
| low | seed_42 | 2 | precombat_main | Rograkh, Son of Rohgahh #94 (real) | spell_cast | Chain of Vapor | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 2 | - | Rograkh, Son of Rohgahh #94 (real) | spell_resolved | Chain of Vapor | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 3 | precombat_main | Magda, Brazen Outlaw #90 (real) | spell_cast | Untimely Malfunction | remove_creature | Runtime effect `remove_creature` differs from registry effect `remove_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 3 | - | Magda, Brazen Outlaw #90 (real) | spell_resolved | Untimely Malfunction | remove_creature | Runtime effect `remove_creature` differs from registry effect `remove_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
