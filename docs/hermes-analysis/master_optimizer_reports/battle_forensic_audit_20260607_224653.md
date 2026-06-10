# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 22:46:53 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 149
- card_events: 50
- unique_cards_seen: 39
- findings_total: 26
- critical: 0
- high: 6
- medium: 6
- low: 14

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `generated` | 28 |
| `manual` | 12 |
| `type_line_creature` | 10 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `needs_review` | 28 |
| `verified` | 12 |
| `fact` | 10 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 16 |
| `creature` | 11 |
| `ramp_permanent` | 4 |
| `remove_creature` | 4 |
| `finisher` | 2 |
| `indestructible` | 2 |
| `modal_boros_charm` | 2 |
| `overload_recursion` | 2 |
| `redirect_removal` | 2 |
| `token_maker` | 2 |
| `commander` | 1 |
| `ramp_engine` | 1 |
| `ramp_ritual` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_42 | 1 | precombat_main | Lorehold | spell_cast | Lightning Greaves | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 1 | - | Lorehold | spell_resolved | Lightning Greaves | indestructible | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 6 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Lightning Bolt | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 6 | - | Magda, Brazen Outlaw #71 (real) | spell_resolved | Lightning Bolt | remove_creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 8 | precombat_main | Lorehold | spell_cast | Guttersnipe | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 8 | - | Lorehold | spell_resolved | Guttersnipe | finisher | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 2 | precombat_main | Lorehold | spell_cast | Rite of Flame | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 2 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Mox Diamond | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 4 | precombat_main | Magda, Brazen Outlaw #71 (real) | creature_cast | Hexing Squelcher | creature | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 6 | precombat_main | Lorehold | spell_cast | Mana Vault | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 7 | precombat_main | Magda, Brazen Outlaw #71 (real) | spell_cast | Mana Vault | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 8 | precombat_main | Magda, Brazen Outlaw #71 (real) | commander_cast | Magda, Brazen Outlaw | ramp_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_42 | 1 | - | Lorehold | land_played | Sunbaked Canyon | land | Runtime effect `land` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Najeela, the Blade-Blossom #111 (real) | land_played | Ancient Tomb | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Exotic Orchard | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 1 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 2 | - | Najeela, the Blade-Blossom #111 (real) | land_played | Polluted Delta | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 2 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Gemstone Caverns | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 2 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 3 | - | Lorehold | land_played | Ancient Den | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 3 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 4 | precombat_main | Magda, Brazen Outlaw #71 (real) | creature_cast | Hexing Squelcher | creature | Runtime effect `creature` differs from registry effect `silence_opponents`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 4 | - | Lorehold | land_played | Scalding Tarn | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 5 | - | Lorehold | land_played | Plateau | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 7 | - | Kraum, Ludevic's Opus #81 (real) | land_played | Flooded Strand | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 9 | - | Lorehold | land_played | Inspiring Vantage | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
