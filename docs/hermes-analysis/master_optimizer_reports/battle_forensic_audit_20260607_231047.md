# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:10:47 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 207
- card_events: 72
- unique_cards_seen: 48
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_42.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 47 |
| `manual` | 18 |
| `type_line_creature` | 7 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 65 |
| `fact` | 7 |

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
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
