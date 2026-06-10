# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:17:19 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1899
- card_events: 808
- unique_cards_seen: 232
- findings_total: 96
- critical: 2
- high: 41
- medium: 51
- low: 2

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_200.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_200.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_201.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_201.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_202.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_202.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_203.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_203.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_204.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_204.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 492 |
| `manual` | 181 |
| `generated` | 92 |
| `type_line_creature` | 43 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 673 |
| `needs_review` | 92 |
| `fact` | 43 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 210 |
| `draw_cards` | 125 |
| `tutor` | 61 |
| `ramp_permanent` | 58 |
| `creature` | 47 |
| `ramp_ritual` | 41 |
| `counter` | 32 |
| `silence_opponents` | 24 |
| `token_maker` | 24 |
| `ramp_engine` | 23 |
| `draw_engine` | 22 |
| `copy_spell` | 18 |
| `remove_permanent` | 16 |
| `finisher` | 14 |
| `remove_creature` | 14 |
| `board_wipe` | 10 |
| `indestructible` | 10 |
| `topdeck_manipulation` | 10 |
| `approach` | 8 |
| `modal_boros_charm` | 8 |
| `overload_recursion` | 8 |
| `recursion` | 8 |
| `equipment_haste_shroud` | 6 |
| `commander` | 5 |
| `extra_turn` | 2 |
| `phase_out` | 2 |
| `redirect_removal` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| critical | seed_201 | 18 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Final Fortune | extra_turn | Effect `extra_turn` is not implemented by battle_analyst_v8.py. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_201 | 18 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Final Fortune | extra_turn | Effect `extra_turn` is not implemented by battle_analyst_v8.py. | Implement the effect branch or map the card to a supported approximation. |
| high | seed_201 | 10 | precombat_main | Ishai, Ojutai Dragonspeaker #52 (real) | spell_cast | Gifts Ungiven | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 10 | - | Ishai, Ojutai Dragonspeaker #52 (real) | spell_resolved | Gifts Ungiven | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 13 | precombat_main | Ishai, Ojutai Dragonspeaker #52 (real) | spell_cast | Intuition | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 13 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Demonic Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 13 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Demonic Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_204 | 14 | precombat_main | Ishai, Ojutai Dragonspeaker #52 (real) | spell_cast | Brain Freeze | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_204 | 14 | - | Ishai, Ojutai Dragonspeaker #52 (real) | spell_resolved | Brain Freeze | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 17 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Thassa's Oracle | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 17 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Eladamri's Call | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_203 | 17 | precombat_main | Lorehold | spell_cast | Imperial Recruiter | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_204 | 17 | precombat_main | Ishai, Ojutai Dragonspeaker #52 (real) | spell_cast | Mystical Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 17 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Thassa's Oracle | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 17 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Eladamri's Call | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_203 | 17 | - | Lorehold | spell_resolved | Imperial Recruiter | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_204 | 17 | - | Ishai, Ojutai Dragonspeaker #52 (real) | spell_resolved | Mystical Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 18 | - | Najeela, the Blade-Blossom #111 (real) | end_step_instant | Brain Freeze | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 18 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Brain Freeze | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 19 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Mystical Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 19 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Intuition | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 19 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Mystical Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 19 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Intuition | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 20 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Knuckles the Echidna | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 20 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Underworld Breach | recursion | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 20 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Knuckles the Echidna | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 20 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Underworld Breach | recursion | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 21 | precombat_main | Lorehold | spell_cast | Molten Duplication | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 21 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Snap | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 21 | - | Lorehold | spell_resolved | Molten Duplication | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 21 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Snap | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_203 | 22 | precombat_main | Rograkh, Son of Rohgahh #94 (real) | spell_cast | Mystical Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_203 | 22 | - | Rograkh, Son of Rohgahh #94 (real) | spell_resolved | Mystical Tutor | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 25 | precombat_main | Lorehold | spell_cast | Fiery Emancipation | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 25 | - | Lorehold | spell_resolved | Fiery Emancipation | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_204 | 3 | postcombat_main | Lorehold | spell_cast | Imperial Recruiter | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_204 | 3 | - | Lorehold | spell_resolved | Imperial Recruiter | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_203 | 7 | precombat_main | Lorehold | spell_cast | Fiery Emancipation | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_203 | 7 | - | Lorehold | spell_resolved | Fiery Emancipation | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_200 | 8 | precombat_main | Lorehold | spell_cast | Molten Duplication | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_200 | 8 | precombat_main | Arcum Dagsson #53 (real) | spell_cast | Tezzeret the Seeker | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_200 | 8 | - | Lorehold | spell_resolved | Molten Duplication | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_200 | 8 | - | Arcum Dagsson #53 (real) | spell_resolved | Tezzeret the Seeker | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_202 | 10 | precombat_main | Magda, Brazen Outlaw #90 (real) | spell_cast | Magda, the Hoardmaster | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 11 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Lotho, Corrupt Shirriff | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 11 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Vampiric Tutor | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 11 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Vampiric Tutor | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 12 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Culling Ritual | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 12 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Culling Ritual | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_203 | 13 | precombat_main | Rograkh, Son of Rohgahh #94 (real) | spell_cast | Defense Grid | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 14 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Noble Hierarch | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 14 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Necropotence | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 14 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Necropotence | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_204 | 15 | - | Lorehold | miracle_cast | Faithless Looting | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 15 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Tainted Pact | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 15 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Tainted Pact | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_204 | 15 | - | Lorehold | spell_resolved | Faithless Looting | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_203 | 16 | precombat_main | Lorehold | spell_cast | Unexpected Windfall | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 17 | - | Najeela, the Blade-Blossom #111 (real) | end_step_instant | Borne Upon a Wind | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 17 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Borne Upon a Wind | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_204 | 18 | - | Lorehold | miracle_cast | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 18 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Final Fortune | extra_turn | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 18 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_203 | 18 | precombat_main | Lorehold | spell_cast | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 18 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Final Fortune | extra_turn | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 18 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_203 | 18 | - | Lorehold | spell_resolved | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_204 | 18 | - | Lorehold | spell_resolved | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 19 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Ignoble Hierarch | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 19 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Imperial Seal | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 19 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Ignoble Hierarch | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 19 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Imperial Seal | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 21 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Mnemonic Betrayal | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_203 | 21 | precombat_main | Rograkh, Son of Rohgahh #94 (real) | spell_cast | Talisman of Dominance | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 21 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Mnemonic Betrayal | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 23 | - | Lorehold | miracle_cast | Unexpected Windfall | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 23 | - | Lorehold | spell_resolved | Unexpected Windfall | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 24 | precombat_main | Rograkh, Son of Rohgahh #33 (real) | spell_cast | Talisman of Dominance | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_200 | 5 | precombat_main | Rograkh, Son of Rohgahh #94 (real) | spell_cast | Defense Grid | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 6 | - | Lorehold | miracle_cast | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 6 | precombat_main | Rograkh, Son of Rohgahh #33 (real) | spell_cast | Grinding Station | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 6 | - | Lorehold | spell_resolved | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_200 | 7 | precombat_main | Lorehold | spell_cast | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_200 | 7 | - | Lorehold | spell_resolved | Wheel of Fortune | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_200 | 8 | - | Lorehold | end_step_instant | Reiterate | copy_spell | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_204 | 8 | - | Lorehold | miracle_cast | Unexpected Windfall | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 8 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Ad Nauseam | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_203 | 8 | precombat_main | Lorehold | spell_cast | Reiterate | copy_spell | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_200 | 8 | - | Lorehold | spell_resolved | Reiterate | copy_spell | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 8 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Ad Nauseam | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_203 | 8 | - | Lorehold | spell_resolved | Reiterate | copy_spell | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_204 | 8 | - | Lorehold | spell_resolved | Unexpected Windfall | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 9 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Dark Ritual | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 9 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Dark Ritual | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_201 | 21 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Snap | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_201 | 21 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Snap | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
