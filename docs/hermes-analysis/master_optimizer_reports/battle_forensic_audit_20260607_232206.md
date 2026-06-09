# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:22:06 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1920
- card_events: 826
- unique_cards_seen: 235
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

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
| `curated` | 592 |
| `manual` | 190 |
| `type_line_creature` | 44 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 782 |
| `fact` | 44 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 214 |
| `draw_cards` | 133 |
| `ramp_permanent` | 59 |
| `tutor` | 57 |
| `creature` | 48 |
| `ramp_ritual` | 43 |
| `counter` | 30 |
| `silence_opponents` | 28 |
| `token_maker` | 24 |
| `ramp_engine` | 23 |
| `draw_engine` | 22 |
| `copy_spell` | 20 |
| `remove_permanent` | 20 |
| `remove_creature` | 14 |
| `finisher` | 10 |
| `indestructible` | 10 |
| `recursion` | 10 |
| `topdeck_manipulation` | 10 |
| `approach` | 8 |
| `board_wipe` | 8 |
| `modal_boros_charm` | 8 |
| `overload_recursion` | 8 |
| `equipment_haste_shroud` | 6 |
| `commander` | 5 |
| `redirect_removal` | 4 |
| `extra_turn` | 2 |
| `phase_out` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
