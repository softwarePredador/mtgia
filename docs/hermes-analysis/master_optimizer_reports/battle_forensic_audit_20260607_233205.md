# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:32:05 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 232
- card_events: 121
- unique_cards_seen: 64
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 76 |
| `manual` | 37 |
| `type_line_creature` | 8 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 113 |
| `fact` | 8 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `draw_cards` | 25 |
| `land` | 21 |
| `ramp_permanent` | 12 |
| `creature` | 10 |
| `tutor` | 10 |
| `draw_engine` | 8 |
| `remove_creature` | 6 |
| `approach` | 4 |
| `counter` | 4 |
| `deal_damage` | 4 |
| `silence_opponents` | 4 |
| `copy_spell` | 2 |
| `damage_each_opponent` | 2 |
| `equipment_haste_shroud` | 2 |
| `ramp_ritual` | 2 |
| `recursion` | 2 |
| `commander` | 1 |
| `ramp_engine` | 1 |
| `topdeck_manipulation` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
