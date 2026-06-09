# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:15:50 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 260
- card_events: 101
- unique_cards_seen: 63
- findings_total: 2
- critical: 0
- high: 1
- medium: 1
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 68 |
| `manual` | 25 |
| `type_line_creature` | 6 |
| `generated` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 93 |
| `fact` | 6 |
| `needs_review` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 29 |
| `ramp_permanent` | 14 |
| `draw_cards` | 12 |
| `creature` | 8 |
| `ramp_ritual` | 6 |
| `damage_each_opponent` | 5 |
| `approach` | 4 |
| `tutor` | 4 |
| `board_wipe` | 2 |
| `copy_spell` | 2 |
| `counter` | 2 |
| `draw_engine` | 2 |
| `equipment_haste_shroud` | 2 |
| `remove_creature` | 2 |
| `silence_opponents` | 2 |
| `token_maker` | 2 |
| `commander` | 1 |
| `ramp_engine` | 1 |
| `recursion` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_777 | 4 | precombat_main | Lumra, Bellow of the Woods #49 (real) | commander_cast | Lumra, Bellow of the Woods | recursion | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_777 | 10 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Zuran Orb | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
