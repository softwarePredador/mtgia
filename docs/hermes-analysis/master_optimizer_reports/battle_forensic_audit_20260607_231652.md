# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:16:52 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 2266
- card_events: 881
- unique_cards_seen: 337
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_100.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_100.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_101.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_101.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_102.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_102.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_103.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_103.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_104.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_104.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 618 |
| `type_line_creature` | 145 |
| `manual` | 118 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 736 |
| `fact` | 145 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 243 |
| `creature` | 149 |
| `ramp_permanent` | 87 |
| `draw_cards` | 56 |
| `silence_opponents` | 39 |
| `remove_permanent` | 38 |
| `tutor` | 32 |
| `draw_engine` | 30 |
| `ramp_ritual` | 30 |
| `counter` | 28 |
| `remove_creature` | 20 |
| `token_maker` | 20 |
| `indestructible` | 16 |
| `ramp_engine` | 16 |
| `copy_spell` | 14 |
| `topdeck_manipulation` | 10 |
| `approach` | 8 |
| `deal_damage` | 8 |
| `board_wipe` | 6 |
| `equipment_haste_shroud` | 6 |
| `commander` | 4 |
| `recursion` | 4 |
| `redirect_removal` | 4 |
| `remove_artifact_or_3dmg` | 4 |
| `finisher` | 2 |
| `overload_recursion` | 2 |
| `phase_out` | 2 |
| `pump_all` | 2 |
| `modal_boros_charm` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
