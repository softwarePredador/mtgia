# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:07:18 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 227
- card_events: 55
- unique_cards_seen: 47
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
| `curated` | 32 |
| `type_line_creature` | 13 |
| `manual` | 8 |
| `generated` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 40 |
| `fact` | 13 |
| `needs_review` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 19 |
| `creature` | 13 |
| `ramp_permanent` | 6 |
| `copy_spell` | 4 |
| `approach` | 2 |
| `counter` | 2 |
| `draw_cards` | 2 |
| `modal_boros_charm` | 2 |
| `ramp_ritual` | 2 |
| `remove_creature` | 2 |
| `commander` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| medium | seed_888 | 1 | precombat_main | Ral, Monsoon Mage #48 (real) | spell_cast | Vexing Bauble | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_888 | 1 | - | Ral, Monsoon Mage #48 (real) | spell_resolved | Vexing Bauble | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
