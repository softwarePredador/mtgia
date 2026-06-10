# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:08:53 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 207
- card_events: 72
- unique_cards_seen: 48
- findings_total: 8
- critical: 0
- high: 4
- medium: 0
- low: 4

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 43 |
| `manual` | 18 |
| `type_line_creature` | 7 |
| `generated` | 4 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 61 |
| `fact` | 7 |
| `needs_review` | 4 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 21 |
| `creature` | 10 |
| `ramp_permanent` | 6 |
| `remove_permanent` | 6 |
| `counter` | 4 |
| `draw_engine` | 4 |
| `redirect_removal` | 4 |
| `deal_damage` | 2 |
| `equipment_haste_shroud` | 2 |
| `modal_boros_charm` | 2 |
| `overload_recursion` | 2 |
| `ramp_ritual` | 2 |
| `token_maker` | 2 |
| `tutor` | 2 |
| `commander` | 1 |
| `ramp_engine` | 1 |
| `remove_creature` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_42 | 12 | - | Lorehold | miracle_cast | Rise of the Eldrazi | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 12 | - | Lorehold | spell_resolved | Rise of the Eldrazi | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 9 | - | Rograkh, Son of Rohgahh #94 (real) | end_step_instant | An Offer You Can't Refuse | counter | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_42 | 9 | - | Rograkh, Son of Rohgahh #94 (real) | spell_resolved | An Offer You Can't Refuse | counter | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_42 | 12 | - | Lorehold | miracle_cast | Rise of the Eldrazi | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `silence_opponents`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 12 | - | Lorehold | spell_resolved | Rise of the Eldrazi | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `silence_opponents`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 9 | - | Rograkh, Son of Rohgahh #94 (real) | end_step_instant | An Offer You Can't Refuse | counter | Runtime effect `counter` differs from registry effect `ramp_engine`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_42 | 9 | - | Rograkh, Son of Rohgahh #94 (real) | spell_resolved | An Offer You Can't Refuse | counter | Runtime effect `counter` differs from registry effect `ramp_engine`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
