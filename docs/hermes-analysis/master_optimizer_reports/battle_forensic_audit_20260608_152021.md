# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 15:20:21 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1459
- card_events: 373
- unique_cards_seen: 163
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_970.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_970.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_971.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_971.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_972.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_972.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_973.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_973.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_974.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_974.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 248 |
| `known_cards_manual` | 107 |
| `type_line_creature` | 18 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 355 |
| `fact` | 18 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 110 |
| `ramp_permanent` | 39 |
| `creature` | 29 |
| `silence_opponents` | 24 |
| `tutor` | 18 |
| `ramp_ritual` | 15 |
| `draw_cards` | 14 |
| `ramp_engine` | 13 |
| `copy_spell` | 12 |
| `token_maker` | 12 |
| `draw_engine` | 10 |
| `redirect_removal` | 10 |
| `remove_creature` | 9 |
| `commander` | 8 |
| `remove_permanent` | 8 |
| `counter` | 6 |
| `deal_damage` | 4 |
| `equipment_haste_shroud` | 4 |
| `finisher` | 4 |
| `hate_artifact` | 4 |
| `approach` | 2 |
| `board_wipe` | 2 |
| `indestructible` | 2 |
| `modal_boros_charm` | 2 |
| `overload_recursion` | 2 |
| `phase_creatures` | 2 |
| `phase_out` | 2 |
| `recursion` | 2 |
| `topdeck_manipulation` | 2 |
| `land_ramp` | 1 |
| `land_recursion` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
