# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 14:21:02 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 2626
- card_events: 810
- unique_cards_seen: 211
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_960.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_960.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_961.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_961.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_962.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_962.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_963.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_963.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_964.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_964.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_965.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_965.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_966.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_966.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_967.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_967.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_968.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_968.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_969.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_969.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 558 |
| `known_cards_manual` | 220 |
| `type_line_creature` | 32 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 778 |
| `fact` | 32 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 266 |
| `ramp_permanent` | 78 |
| `draw_cards` | 63 |
| `tutor` | 46 |
| `creature` | 43 |
| `draw_engine` | 32 |
| `token_maker` | 28 |
| `silence_opponents` | 26 |
| `copy_spell` | 24 |
| `ramp_ritual` | 21 |
| `remove_creature` | 20 |
| `counter` | 18 |
| `finisher` | 16 |
| `remove_permanent` | 16 |
| `topdeck_manipulation` | 16 |
| `commander` | 15 |
| `ramp_engine` | 14 |
| `indestructible` | 12 |
| `approach` | 8 |
| `equipment_haste_shroud` | 8 |
| `recursion` | 8 |
| `redirect_removal` | 8 |
| `board_wipe` | 6 |
| `overload_recursion` | 6 |
| `phase_out` | 6 |
| `damage_each_opponent` | 2 |
| `hate_artifact` | 2 |
| `modal_boros_charm` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
