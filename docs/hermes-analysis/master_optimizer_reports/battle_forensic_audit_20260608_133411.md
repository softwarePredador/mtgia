# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:34:11 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1277
- card_events: 400
- unique_cards_seen: 208
- findings_total: 28
- critical: 0
- high: 11
- medium: 17
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_900.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_900.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_901.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_901.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_902.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_902.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_903.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_903.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_904.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_904.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 230 |
| `known_cards_manual` | 86 |
| `type_line_creature` | 61 |
| `generated` | 23 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 316 |
| `fact` | 61 |
| `needs_review` | 23 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 133 |
| `creature` | 66 |
| `ramp_permanent` | 34 |
| `draw_cards` | 22 |
| `token_maker` | 22 |
| `ramp_ritual` | 20 |
| `draw_engine` | 12 |
| `remove_creature` | 10 |
| `tutor` | 10 |
| `ramp_engine` | 8 |
| `remove_permanent` | 8 |
| `commander` | 5 |
| `copy_spell` | 4 |
| `counter` | 4 |
| `equipment_haste_shroud` | 4 |
| `land_recursion_creature` | 4 |
| `modal_boros_charm` | 4 |
| `phase_out` | 4 |
| `recursion` | 4 |
| `redirect_removal` | 4 |
| `silence_opponents` | 4 |
| `approach` | 2 |
| `board_wipe` | 2 |
| `finisher` | 2 |
| `life_artifact` | 2 |
| `overload_recursion` | 2 |
| `topdeck_manipulation` | 2 |
| `damage_each_opponent` | 1 |
| `indestructible` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_904 | 10 | - | Thrasios, Triton Hero #59 (real) | combat_result | - | - | Unblocked combat dealt 0 player damage. | - |
| high | seed_904 | 10 | - | Thrasios, Triton Hero #59 (real) | combat_result | - | - | Unblocked lethal-looking combat did not kill the target. | - |
| high | seed_903 | 13 | precombat_main | Marneus Calgar #64 (real) | spell_cast | Stridehangar Automaton | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_903 | 13 | - | Marneus Calgar #64 (real) | spell_resolved | Stridehangar Automaton | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_903 | 7 | - | Marneus Calgar #64 (real) | combat_result | - | - | Unblocked combat dealt 0 player damage. | - |
| high | seed_903 | 7 | - | Lumra, Bellow of the Woods #49 (real) | combat_result | - | - | Unblocked combat dealt 0 player damage. | - |
| high | seed_903 | 7 | - | Thrasios, Triton Hero #101 (real) | combat_result | - | - | Unblocked combat dealt 0 player damage. | - |
| high | seed_901 | 7 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Walking Ballista | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_901 | 7 | - | Arcum Dagsson #97 (real) | spell_resolved | Walking Ballista | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_902 | 8 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Springheart Nantuko | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_902 | 8 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Springheart Nantuko | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_901 | 1 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Plague Myr | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_902 | 1 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Elvish Reclaimer | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_901 | 1 | - | Arcum Dagsson #97 (real) | spell_resolved | Plague Myr | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_900 | 13 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Demand Answers | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_900 | 13 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Demand Answers | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_900 | 4 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Reckless Impulse | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_902 | 4 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Food Chain | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_904 | 4 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Demand Answers | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_900 | 4 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Reckless Impulse | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_902 | 4 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Food Chain | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_904 | 4 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Demand Answers | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_904 | 6 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Wheel of Misfortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_904 | 6 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Wheel of Misfortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_902 | 8 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Chromatic Orrery | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_902 | 8 | - | Arcum Dagsson #97 (real) | spell_resolved | Chromatic Orrery | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_904 | 9 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Strike It Rich | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_904 | 9 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Desperate Ritual | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
