# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:56:49 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1352
- card_events: 415
- unique_cards_seen: 170
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_900.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_900.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_901.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_901.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_902.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_902.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_903.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_903.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_904.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_904.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 268 |
| `known_cards_manual` | 128 |
| `type_line_creature` | 19 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 396 |
| `fact` | 19 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 132 |
| `ramp_permanent` | 38 |
| `creature` | 25 |
| `token_maker` | 24 |
| `draw_cards` | 22 |
| `ramp_ritual` | 18 |
| `tutor` | 18 |
| `remove_creature` | 14 |
| `draw_engine` | 12 |
| `ramp_engine` | 10 |
| `recursion` | 10 |
| `remove_permanent` | 10 |
| `silence_opponents` | 10 |
| `approach` | 8 |
| `counter` | 8 |
| `commander` | 6 |
| `copy_spell` | 6 |
| `board_wipe` | 4 |
| `damage_each_opponent` | 4 |
| `equipment_haste_shroud` | 4 |
| `indestructible` | 4 |
| `land_recursion_creature` | 4 |
| `modal_boros_charm` | 4 |
| `phase_out` | 4 |
| `redirect_removal` | 4 |
| `topdeck_manipulation` | 4 |
| `finisher` | 2 |
| `life_artifact` | 2 |
| `overload_recursion` | 2 |
| `treasure_maker` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
