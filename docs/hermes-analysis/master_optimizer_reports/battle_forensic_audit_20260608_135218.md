# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:52:18 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1590
- card_events: 532
- unique_cards_seen: 220
- findings_total: 105
- critical: 48
- high: 52
- medium: 4
- low: 1

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
| `curated` | 284 |
| `known_cards_manual` | 124 |
| `unknown` | 96 |
| `type_line_creature` | 20 |
| `generated` | 6 |
| `manual` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 410 |
| `missing` | 96 |
| `fact` | 20 |
| `needs_review` | 6 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 141 |
| `unknown` | 96 |
| `ramp_permanent` | 40 |
| `creature` | 29 |
| `draw_cards` | 28 |
| `ramp_ritual` | 24 |
| `token_maker` | 22 |
| `tutor` | 18 |
| `remove_creature` | 14 |
| `draw_engine` | 12 |
| `remove_permanent` | 12 |
| `silence_opponents` | 12 |
| `ramp_engine` | 9 |
| `approach` | 8 |
| `counter` | 8 |
| `commander` | 6 |
| `copy_spell` | 6 |
| `recursion` | 6 |
| `board_wipe` | 4 |
| `equipment_haste_shroud` | 4 |
| `land_recursion_creature` | 4 |
| `modal_boros_charm` | 4 |
| `overload_recursion` | 4 |
| `phase_out` | 4 |
| `topdeck_manipulation` | 4 |
| `damage_each_opponent` | 3 |
| `finisher` | 2 |
| `indestructible` | 2 |
| `life_artifact` | 2 |
| `redirect_removal` | 2 |
| `treasure_maker` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| critical | seed_902 | 10 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Ashaya, Soul of the Wild | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 11 | - | Thrasios, Triton Hero #115 (real) | spell_resolved | Biomancer's Familiar | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 11 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Invasion of Ikoria | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_903 | 11 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Collector Ouphe | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 14 | - | Thrasios, Triton Hero #115 (real) | spell_resolved | Swift Reconfiguration | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 15 | - | Thrasios, Triton Hero #77 (real) | spell_resolved | Snapback | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 15 | - | Thrasios, Triton Hero #115 (real) | spell_resolved | Mockingbird | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 3 | - | Thrasios, Triton Hero #77 (real) | spell_resolved | The Cabbage Merchant | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 3 | - | Arcum Dagsson #97 (real) | spell_resolved | Twiddle | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 3 | - | Arcum Dagsson #97 (real) | spell_resolved | Shield Sphere | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 3 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Elvish Spirit Guide | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 3 | - | Thrasios, Triton Hero #59 (real) | spell_resolved | Biomancer's Familiar | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 3 | - | Thrasios, Triton Hero #59 (real) | spell_resolved | Oboro Breezecaller | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 3 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Collector Ouphe | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_903 | 3 | - | Marneus Calgar #64 (real) | spell_resolved | Phyrexian Metamorph | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 4 | - | Arcum Dagsson #97 (real) | spell_resolved | Marvin, Murderous Mimic | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 4 | - | Arcum Dagsson #97 (real) | spell_resolved | Crashing Drawbridge | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 5 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Storm of Memories | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 5 | - | Arcum Dagsson #97 (real) | spell_resolved | Corridor Monitor | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 5 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Summoner's Pact | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 5 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Famished Worldsire | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 5 | - | Thrasios, Triton Hero #59 (real) | spell_resolved | Emiel the Blessed | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 5 | - | Thrasios, Triton Hero #59 (real) | spell_resolved | Candelabra of Tawnos | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 5 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Famished Worldsire | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 5 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Arboreal Grazer | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 5 | - | Arcum Dagsson #97 (real) | spell_resolved | Marvin, Murderous Mimic | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_903 | 5 | - | Thrasios, Triton Hero #101 (real) | spell_resolved | Flash Photography | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_904 | 5 | - | Dargo, the Shipwrecker #74 (real) | spell_resolved | Sacrifice | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_904 | 5 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Gut Shot | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 6 | - | Arcum Dagsson #97 (real) | spell_resolved | Metalworker | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 6 | - | Arcum Dagsson #97 (real) | spell_resolved | Sewer-veillance Cam | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 6 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Endurance | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 6 | - | Arcum Dagsson #97 (real) | spell_resolved | Tomb Trawler | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_903 | 6 | - | Thrasios, Triton Hero #101 (real) | spell_resolved | Survival of the Fittest | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_904 | 6 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Quiet Speculation | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 7 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Abandon Attachments | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 7 | - | Thrasios, Triton Hero #77 (real) | spell_resolved | Valley Floodcaller | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_903 | 7 | - | Thrasios, Triton Hero #101 (real) | spell_resolved | Swift Reconfiguration | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_904 | 7 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Hidden Strings | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 8 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Twinferno | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 8 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Bonus Round | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 8 | - | Thrasios, Triton Hero #115 (real) | spell_resolved | Flash Photography | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_901 | 8 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Magus of the Candelabra | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_904 | 8 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Overmaster | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_904 | 8 | - | Thrasios, Triton Hero #59 (real) | spell_resolved | Hazel's Brewmaster | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_900 | 9 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Mind's Desire | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_902 | 9 | - | Arcum Dagsson #97 (real) | spell_resolved | God-Pharaoh's Statue | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| critical | seed_903 | 9 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Magus of the Candelabra | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 10 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Ashaya, Soul of the Wild | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 11 | precombat_main | Thrasios, Triton Hero #115 (real) | spell_cast | Biomancer's Familiar | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 11 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Invasion of Ikoria | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_903 | 11 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Collector Ouphe | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 14 | precombat_main | Thrasios, Triton Hero #115 (real) | spell_cast | Swift Reconfiguration | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 15 | postcombat_main | Thrasios, Triton Hero #77 (real) | spell_cast | Snapback | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 15 | precombat_main | Thrasios, Triton Hero #115 (real) | spell_cast | Mockingbird | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 16 | - | Thrasios, Triton Hero #77 (real) | combat | - | - | Combat declared attackers with non-positive total power. | - |
| high | seed_900 | 16 | - | Thrasios, Triton Hero #77 (real) | combat_result | - | - | Unblocked combat dealt 0 player damage. | - |
| high | seed_900 | 17 | precombat_main | Thrasios, Triton Hero #77 (real) | spell_cast | Diabolic Intent | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_900 | 17 | - | Thrasios, Triton Hero #77 (real) | spell_resolved | Diabolic Intent | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_900 | 3 | precombat_main | Thrasios, Triton Hero #77 (real) | spell_cast | The Cabbage Merchant | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 3 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Shield Sphere | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 3 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Twiddle | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 3 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Elvish Spirit Guide | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 3 | precombat_main | Thrasios, Triton Hero #59 (real) | spell_cast | Biomancer's Familiar | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 3 | precombat_main | Thrasios, Triton Hero #59 (real) | spell_cast | Oboro Breezecaller | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 3 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Collector Ouphe | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_903 | 3 | precombat_main | Marneus Calgar #64 (real) | spell_cast | Phyrexian Metamorph | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 4 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Marvin, Murderous Mimic | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 4 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Crashing Drawbridge | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 5 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Storm of Memories | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 5 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Corridor Monitor | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 5 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Famished Worldsire | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 5 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Summoner's Pact | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 5 | precombat_main | Thrasios, Triton Hero #59 (real) | spell_cast | Emiel the Blessed | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 5 | precombat_main | Thrasios, Triton Hero #59 (real) | spell_cast | Candelabra of Tawnos | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 5 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Arboreal Grazer | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 5 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Famished Worldsire | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 5 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Marvin, Murderous Mimic | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_903 | 5 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_cast | Flash Photography | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_904 | 5 | precombat_main | Dargo, the Shipwrecker #74 (real) | spell_cast | Sacrifice | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_904 | 5 | postcombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Gut Shot | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 6 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Sewer-veillance Cam | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 6 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Metalworker | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 6 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Endurance | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 6 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | Tomb Trawler | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_903 | 6 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_cast | Survival of the Fittest | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_904 | 6 | postcombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Quiet Speculation | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 7 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Abandon Attachments | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 7 | precombat_main | Thrasios, Triton Hero #77 (real) | spell_cast | Valley Floodcaller | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_903 | 7 | precombat_main | Thrasios, Triton Hero #101 (real) | spell_cast | Swift Reconfiguration | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_904 | 7 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Hidden Strings | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 8 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Bonus Round | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 8 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Twinferno | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 8 | precombat_main | Thrasios, Triton Hero #115 (real) | spell_cast | Flash Photography | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_901 | 8 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Magus of the Candelabra | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_904 | 8 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Overmaster | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_904 | 8 | precombat_main | Thrasios, Triton Hero #59 (real) | spell_cast | Hazel's Brewmaster | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_900 | 9 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Mind's Desire | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_902 | 9 | precombat_main | Arcum Dagsson #97 (real) | spell_cast | God-Pharaoh's Statue | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| high | seed_903 | 9 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Magus of the Candelabra | unknown | Card event used unknown battle semantics. | Create or correct card_battle_rules.effect_json, then replay this seed. |
| medium | seed_900 | 16 | precombat_main | Thrasios, Triton Hero #77 (real) | spell_cast | Noxious Revival | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_900 | 16 | - | Thrasios, Triton Hero #77 (real) | spell_resolved | Noxious Revival | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_902 | 6 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Burgeoning | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_902 | 6 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Burgeoning | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_903 | 13 | - | Lorehold | board_wipe_resolved | - | - | Board wipe left more protected creatures (7) than destroyed (2). | - |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
