# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:27:42 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 239
- card_events: 128
- unique_cards_seen: 69
- findings_total: 6
- critical: 0
- high: 0
- medium: 6
- low: 0

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 75 |
| `manual` | 39 |
| `type_line_creature` | 8 |
| `generated` | 6 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 114 |
| `fact` | 8 |
| `needs_review` | 6 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `draw_cards` | 31 |
| `land` | 21 |
| `ramp_permanent` | 14 |
| `creature` | 10 |
| `draw_engine` | 8 |
| `remove_creature` | 6 |
| `tutor` | 6 |
| `approach` | 4 |
| `copy_spell` | 4 |
| `deal_damage` | 4 |
| `silence_opponents` | 4 |
| `counter` | 2 |
| `equipment_haste_shroud` | 2 |
| `indestructible` | 2 |
| `ramp_engine` | 2 |
| `ramp_ritual` | 2 |
| `recursion` | 2 |
| `token_maker` | 2 |
| `commander` | 1 |
| `topdeck_manipulation` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| medium | seed_777 | 6 | precombat_main | Kinnan, Bonder Prodigy #84 (real) | spell_cast | Green Sun's Zenith | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_777 | 6 | - | Kinnan, Bonder Prodigy #84 (real) | spell_resolved | Green Sun's Zenith | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_777 | 8 | precombat_main | Kinnan, Bonder Prodigy #84 (real) | spell_cast | Green Sun's Zenith | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_777 | 8 | postcombat_main | Kinnan, Bonder Prodigy #84 (real) | spell_cast | Consecrated Sphinx | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_777 | 8 | - | Kinnan, Bonder Prodigy #84 (real) | spell_resolved | Green Sun's Zenith | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_777 | 8 | - | Kinnan, Bonder Prodigy #84 (real) | spell_resolved | Consecrated Sphinx | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
