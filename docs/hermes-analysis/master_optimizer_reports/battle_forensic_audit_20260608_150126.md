# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 15:01:26 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1442
- card_events: 395
- unique_cards_seen: 170
- findings_total: 31
- critical: 0
- high: 16
- medium: 13
- low: 2

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_970.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_970.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_971.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_971.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_972.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_972.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_973.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_973.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_974.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_974.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 256 |
| `known_cards_manual` | 93 |
| `generated` | 29 |
| `type_line_creature` | 17 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 349 |
| `needs_review` | 29 |
| `fact` | 17 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 110 |
| `ramp_permanent` | 46 |
| `tutor` | 28 |
| `silence_opponents` | 24 |
| `creature` | 22 |
| `ramp_ritual` | 20 |
| `draw_cards` | 18 |
| `ramp_engine` | 16 |
| `draw_engine` | 15 |
| `token_maker` | 12 |
| `remove_creature` | 11 |
| `copy_spell` | 10 |
| `redirect_removal` | 10 |
| `remove_permanent` | 8 |
| `commander` | 7 |
| `counter` | 4 |
| `equipment_haste_shroud` | 4 |
| `finisher` | 4 |
| `hate_artifact` | 4 |
| `phase_out` | 4 |
| `recursion` | 4 |
| `approach` | 2 |
| `board_wipe` | 2 |
| `deal_damage` | 2 |
| `indestructible` | 2 |
| `modal_boros_charm` | 2 |
| `overload_recursion` | 2 |
| `topdeck_manipulation` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_970 | 1 | precombat_main | Zirda, the Dawnwaker #69 (real) | spell_cast | Stoneforge Mystic | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_970 | 1 | - | Zirda, the Dawnwaker #69 (real) | spell_resolved | Stoneforge Mystic | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 10 | precombat_main | Zirda, the Dawnwaker #69 (real) | spell_cast | Reprieve | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 10 | - | Zirda, the Dawnwaker #69 (real) | spell_resolved | Reprieve | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_970 | 6 | precombat_main | Tannuk, Memorial Ensign #40 (real) | spell_cast | Splendid Reclamation | recursion | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 6 | precombat_main | Zirda, the Dawnwaker #69 (real) | spell_cast | Vandalblast | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 6 | precombat_main | Zirda, the Dawnwaker #69 (real) | spell_cast | Stoneforge Mystic | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_970 | 6 | - | Tannuk, Memorial Ensign #40 (real) | spell_resolved | Splendid Reclamation | recursion | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 6 | - | Zirda, the Dawnwaker #69 (real) | spell_resolved | Stoneforge Mystic | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 6 | - | Zirda, the Dawnwaker #69 (real) | spell_resolved | Vandalblast | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 7 | postcombat_main | Zirda, the Dawnwaker #69 (real) | spell_cast | Delivery Moogle | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 7 | - | Zirda, the Dawnwaker #69 (real) | spell_resolved | Delivery Moogle | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 8 | precombat_main | Zirda, the Dawnwaker #69 (real) | spell_cast | Galadriel's Dismissal | phase_out | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 8 | - | Zirda, the Dawnwaker #69 (real) | spell_resolved | Galadriel's Dismissal | phase_out | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 9 | precombat_main | Magda, Brazen Outlaw #90 (real) | spell_cast | Bottle-Cap Blast | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_972 | 9 | - | Magda, Brazen Outlaw #90 (real) | spell_resolved | Bottle-Cap Blast | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 11 | precombat_main | Tannuk, Memorial Ensign #40 (real) | spell_cast | Mechanized Warfare | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_971 | 11 | precombat_main | Thrasios, Triton Hero #59 (real) | spell_cast | Cloud of Faeries | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 11 | - | Tannuk, Memorial Ensign #40 (real) | spell_resolved | Mechanized Warfare | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_971 | 11 | - | Thrasios, Triton Hero #59 (real) | spell_resolved | Cloud of Faeries | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 12 | precombat_main | Tannuk, Memorial Ensign #40 (real) | spell_cast | Rampant Growth | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 3 | precombat_main | Tannuk, Memorial Ensign #40 (real) | spell_cast | Springbloom Druid | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 4 | precombat_main | Tannuk, Memorial Ensign #40 (real) | commander_cast | Tannuk, Memorial Ensign | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_973 | 5 | postcombat_main | Marneus Calgar #64 (real) | spell_cast | Commandeer | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_973 | 5 | - | Marneus Calgar #64 (real) | spell_resolved | Commandeer | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 7 | precombat_main | Tannuk, Memorial Ensign #40 (real) | spell_cast | Springbloom Druid | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 7 | precombat_main | Tannuk, Memorial Ensign #40 (real) | spell_cast | Roiling Regrowth | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_971 | 9 | precombat_main | Zhulodok, Void Gorger #46 (real) | spell_cast | Echoes of Eternity | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_971 | 9 | - | Zhulodok, Void Gorger #46 (real) | spell_resolved | Echoes of Eternity | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_972 | 10 | precombat_main | Zirda, the Dawnwaker #69 (real) | spell_cast | Reprieve | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_972 | 10 | - | Zirda, the Dawnwaker #69 (real) | spell_resolved | Reprieve | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
