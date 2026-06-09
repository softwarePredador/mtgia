# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 22:59:46 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 159
- card_events: 58
- unique_cards_seen: 41
- findings_total: 16
- critical: 0
- high: 4
- medium: 7
- low: 5

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 26 |
| `generated` | 14 |
| `manual` | 12 |
| `type_line_creature` | 6 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 38 |
| `needs_review` | 14 |
| `fact` | 6 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 18 |
| `creature` | 8 |
| `draw_cards` | 4 |
| `ramp_permanent` | 4 |
| `counter` | 2 |
| `deal_damage` | 2 |
| `draw_engine` | 2 |
| `equipment_haste_shroud` | 2 |
| `modal_boros_charm` | 2 |
| `overload_recursion` | 2 |
| `ramp_ritual` | 2 |
| `redirect_removal` | 2 |
| `remove_creature` | 2 |
| `remove_permanent` | 2 |
| `token_maker` | 2 |
| `commander` | 1 |
| `ramp_engine` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_42 | 4 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Into the Flood Maw | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 4 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Into the Flood Maw | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 6 | - | Najeela, the Blade-Blossom #111 (real) | end_step_instant | Pact of Negation | counter | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 6 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Pact of Negation | counter | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 2 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Culling the Weak | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 2 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Culling the Weak | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 3 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Mystic Remora | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 3 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Mystic Remora | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 5 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Cabal Ritual | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 5 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Cabal Ritual | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_42 | 6 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Lotus Petal | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_42 | 1 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 2 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 3 | - | Magda, Brazen Outlaw #71 (real) | land_played | Mountain | land | Runtime effect `land` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 4 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Into the Flood Maw | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `token_maker`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 4 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Into the Flood Maw | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `token_maker`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
