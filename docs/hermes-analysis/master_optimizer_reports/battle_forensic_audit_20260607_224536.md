# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 22:45:36 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 365
- card_events: 99
- unique_cards_seen: 66
- findings_total: 83
- critical: 1
- high: 19
- medium: 46
- low: 17

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `generated` | 65 |
| `type_line_creature` | 21 |
| `manual` | 13 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `needs_review` | 65 |
| `fact` | 21 |
| `verified` | 13 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `creature` | 22 |
| `land` | 20 |
| `ramp_permanent` | 20 |
| `remove_permanent` | 6 |
| `ramp_ritual` | 5 |
| `indestructible` | 4 |
| `remove_creature` | 4 |
| `token_maker` | 3 |
| `counter` | 2 |
| `finisher` | 2 |
| `modal_boros_charm` | 2 |
| `redirect_removal` | 2 |
| `silence_opponents` | 2 |
| `tutor` | 2 |
| `commander` | 1 |
| `draw_cards` | 1 |
| `ramp_engine` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| critical | seed_42 | 6 | postcombat_main | Lorehold | commander_cast | Lorehold, the Historian | commander | Effect `commander` is not implemented by battle_analyst_v8.py. | Implement the effect branch or map the card to a supported approximation. |
| high | seed_42 | 1 | postcombat_main | Lorehold | spell_cast | Lightning Greaves | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 1 | - | Lorehold | spell_resolved | Lightning Greaves | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 10 | precombat_main | Lorehold | spell_cast | Mother of Runes | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 10 | - | Lorehold | spell_resolved | Mother of Runes | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 12 | - | Lorehold | miracle_cast | Rise of the Eldrazi | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 12 | - | Lorehold | spell_resolved | Rise of the Eldrazi | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 13 | - | Najeela, the Blade-Blossom #111 (real) | end_step_instant | Pact of Negation | counter | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 13 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Pact of Negation | counter | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 18 | - | Magda, Brazen Outlaw #71 (real) | land_played | Cavern of Souls | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 18 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Tezzeret, Cruel Captain | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 18 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Tezzeret, Cruel Captain | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 21 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Cavern of Souls | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 22 | - | Magda, Brazen Outlaw #71 (real) | land_played | Urza's Saga | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 6 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Lightning Bolt | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 6 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Lightning Bolt | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 7 | precombat_main | Lorehold | spell_cast | Guttersnipe | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 7 | - | Lorehold | spell_resolved | Guttersnipe | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 9 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Maskwood Nexus | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 9 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Maskwood Nexus | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Lorehold | land_played | Sunbaked Canyon | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Najeela, the Blade-Blossom #111 (real) | land_played | Ancient Tomb | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Exotic Orchard | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | precombat_main | Lorehold | spell_cast | Bloodstained Mire | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | precombat_main | Lorehold | spell_cast | Ancient Den | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | postcombat_main | Lorehold | spell_cast | Scalding Tarn | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Polluted Delta | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Marsh Flats | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | precombat_main | Kraum, Ludevic's Opus #81 (real) | spell_cast | Gemstone Caverns | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Mountain | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Mountain | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Lorehold | spell_resolved | Ancient Den | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Lorehold | spell_resolved | Bloodstained Mire | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Lorehold | spell_resolved | Scalding Tarn | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Marsh Flats | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Polluted Delta | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Kraum, Ludevic's Opus #81 (real) | spell_resolved | Gemstone Caverns | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Mountain | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 1 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Mountain | land | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 10 | precombat_main | Magda, Brazen Outlaw #71 (real) | creature_cast | Hexing Squelcher | creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 11 | - | Lorehold | land_played | Great Furnace | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 11 | - | Najeela, the Blade-Blossom #111 (real) | land_played | Exotic Orchard | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 11 | precombat_main | Kraum, Ludevic's Opus #81 (real) | spell_cast | Lion's Eye Diamond | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 12 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Windswept Heath | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 12 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Lotus Petal | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 13 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Mana Confluence | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 14 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 17 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Marsh Flats | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 17 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Lotus Petal | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 19 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 2 | precombat_main | Lorehold | spell_cast | Rite of Flame | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 2 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Mox Diamond | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 20 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Bloodstained Mire | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 21 | - | Magda, Brazen Outlaw #71 (real) | land_played | Gemstone Caverns | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 23 | - | Kraum, Ludevic's Opus #81 (real) | land_played | City of Brass | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 25 | - | Kraum, Ludevic's Opus #81 (real) | land_played | City of Traitors | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 25 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 4 | - | Lorehold | land_played | Plateau | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 5 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Verdant Catacombs | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 6 | precombat_main | Lorehold | spell_cast | Mana Vault | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 7 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Flooded Strand | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 7 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Mana Vault | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 8 | precombat_main | Magda, Brazen Outlaw #71 (real) | commander_cast | Magda, Brazen Outlaw | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 9 | - | Lorehold | land_played | Inspiring Vantage | - | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 9 | precombat_main | Kraum, Ludevic's Opus #81 (real) | spell_cast | Fellwar Stone | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_42 | 1 | precombat_main | Lorehold | spell_cast | Ancient Den | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | postcombat_main | Lorehold | spell_cast | Scalding Tarn | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Polluted Delta | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | precombat_main | Kraum, Ludevic's Opus #81 (real) | spell_cast | Gemstone Caverns | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Lorehold | spell_resolved | Ancient Den | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Lorehold | spell_resolved | Scalding Tarn | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Polluted Delta | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Kraum, Ludevic's Opus #81 (real) | spell_resolved | Gemstone Caverns | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 10 | precombat_main | Magda, Brazen Outlaw #71 (real) | creature_cast | Hexing Squelcher | creature | Runtime effect `creature` differs from registry effect `silence_opponents`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 12 | - | Lorehold | miracle_cast | Rise of the Eldrazi | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `silence_opponents`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 12 | - | Lorehold | spell_resolved | Rise of the Eldrazi | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `silence_opponents`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 4 | precombat_main | Lorehold | spell_cast | Mizzix's Mastery | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `overload_recursion`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 4 | - | Lorehold | spell_resolved | Mizzix's Mastery | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `overload_recursion`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
