# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 12:04:28 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 216
- card_events: 69
- unique_cards_seen: 44
- findings_total: 2
- critical: 0
- high: 0
- medium: 2
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_888.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_888.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 52 |
| `manual` | 12 |
| `type_line_creature` | 3 |
| `generated` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 64 |
| `fact` | 3 |
| `needs_review` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 32 |
| `ramp_ritual` | 8 |
| `ramp_permanent` | 7 |
| `approach` | 4 |
| `copy_spell` | 4 |
| `creature` | 3 |
| `counter` | 2 |
| `modal_boros_charm` | 2 |
| `remove_creature` | 2 |
| `silence_opponents` | 2 |
| `topdeck_manipulation` | 2 |
| `commander` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| medium | seed_888 | 12 | precombat_main | Vivi Ornitier #99 (real) | spell_cast | Desperate Ritual | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_888 | 2 | precombat_main | Vivi Ornitier #99 (real) | commander_cast | Vivi Ornitier | ramp_ritual | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
