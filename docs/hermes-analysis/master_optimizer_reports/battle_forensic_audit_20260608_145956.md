# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 14:59:56 UTC
- status: ready_for_review
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1459
- card_events: 381
- unique_cards_seen: 165
- findings_total: 4
- critical: 0
- high: 0
- medium: 4
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
| `curated` | 262 |
| `known_cards_manual` | 95 |
| `type_line_creature` | 20 |
| `generated` | 4 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 357 |
| `fact` | 20 |
| `needs_review` | 4 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 120 |
| `ramp_permanent` | 39 |
| `creature` | 29 |
| `tutor` | 28 |
| `draw_cards` | 19 |
| `draw_engine` | 16 |
| `remove_creature` | 14 |
| `silence_opponents` | 14 |
| `copy_spell` | 12 |
| `counter` | 12 |
| `remove_permanent` | 12 |
| `token_maker` | 12 |
| `ramp_ritual` | 8 |
| `commander` | 7 |
| `topdeck_manipulation` | 7 |
| `ramp_engine` | 6 |
| `redirect_removal` | 6 |
| `approach` | 4 |
| `board_wipe` | 4 |
| `finisher` | 2 |
| `indestructible` | 2 |
| `modal_boros_charm` | 2 |
| `overload_recursion` | 2 |
| `phase_out` | 2 |
| `recursion` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| medium | seed_970 | 4 | precombat_main | Rograkh, Son of Rohgahh #118 (real) | spell_cast | Sneak Attack | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_970 | 4 | - | Rograkh, Son of Rohgahh #118 (real) | spell_resolved | Sneak Attack | draw_engine | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_972 | 7 | precombat_main | Rograkh, Son of Rohgahh #118 (real) | spell_cast | Eldritch Evolution | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_972 | 7 | - | Rograkh, Son of Rohgahh #118 (real) | spell_resolved | Eldritch Evolution | draw_cards | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
