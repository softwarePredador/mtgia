# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:24:46 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 240
- card_events: 56
- unique_cards_seen: 48
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_888.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_888.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 33 |
| `type_line_creature` | 13 |
| `known_cards_manual` | 10 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 43 |
| `fact` | 13 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 20 |
| `creature` | 13 |
| `ramp_permanent` | 6 |
| `copy_spell` | 4 |
| `approach` | 2 |
| `counter` | 2 |
| `hate_artifact` | 2 |
| `modal_boros_charm` | 2 |
| `ramp_ritual` | 2 |
| `remove_creature` | 2 |
| `commander` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
