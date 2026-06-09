# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:47:30 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1040
- card_events: 295
- unique_cards_seen: 161
- findings_total: 1
- critical: 0
- high: 0
- medium: 0
- low: 1

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
| `curated` | 186 |
| `known_cards_manual` | 65 |
| `type_line_creature` | 44 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 251 |
| `fact` | 44 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 111 |
| `creature` | 48 |
| `ramp_permanent` | 26 |
| `ramp_ritual` | 17 |
| `draw_cards` | 14 |
| `token_maker` | 8 |
| `tutor` | 8 |
| `draw_engine` | 6 |
| `remove_creature` | 6 |
| `commander` | 5 |
| `copy_spell` | 4 |
| `counter` | 4 |
| `equipment_haste_shroud` | 4 |
| `modal_boros_charm` | 4 |
| `ramp_engine` | 4 |
| `redirect_removal` | 4 |
| `silence_opponents` | 4 |
| `board_wipe` | 2 |
| `finisher` | 2 |
| `indestructible` | 2 |
| `land_recursion_creature` | 2 |
| `life_artifact` | 2 |
| `recursion` | 2 |
| `remove_permanent` | 2 |
| `topdeck_manipulation` | 2 |
| `treasure_maker` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| low | seed_901 | 5 | - | Lorehold | removal_resolved | - | - | Removal hit a low-power target while multiple targets were available. | - |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
