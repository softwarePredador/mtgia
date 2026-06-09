# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 14:17:13 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 2635
- card_events: 826
- unique_cards_seen: 213
- findings_total: 9
- critical: 0
- high: 6
- medium: 3
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
| `curated` | 569 |
| `known_cards_manual` | 216 |
| `type_line_creature` | 32 |
| `generated` | 9 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 785 |
| `fact` | 32 |
| `needs_review` | 9 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 267 |
| `ramp_permanent` | 77 |
| `draw_cards` | 66 |
| `tutor` | 48 |
| `creature` | 41 |
| `draw_engine` | 32 |
| `token_maker` | 32 |
| `silence_opponents` | 26 |
| `copy_spell` | 24 |
| `ramp_ritual` | 22 |
| `counter` | 20 |
| `remove_creature` | 20 |
| `finisher` | 16 |
| `remove_permanent` | 16 |
| `topdeck_manipulation` | 16 |
| `commander` | 14 |
| `indestructible` | 14 |
| `ramp_engine` | 14 |
| `recursion` | 10 |
| `redirect_removal` | 10 |
| `approach` | 8 |
| `equipment_haste_shroud` | 8 |
| `board_wipe` | 6 |
| `overload_recursion` | 6 |
| `phase_out` | 6 |
| `damage_each_opponent` | 3 |
| `hate_artifact` | 2 |
| `modal_boros_charm` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_968 | 10 | precombat_main | Etali, Primal Conqueror #105 (real) | spell_cast | Squee, the Immortal | recursion | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_968 | 10 | - | Etali, Primal Conqueror #105 (real) | spell_resolved | Squee, the Immortal | recursion | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_968 | 3 | precombat_main | Rograkh, Son of Rohgahh #118 (real) | spell_cast | Fierce Empath | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_968 | 3 | - | Rograkh, Son of Rohgahh #118 (real) | spell_resolved | Fierce Empath | tutor | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_968 | 8 | precombat_main | Etali, Primal Conqueror #105 (real) | spell_cast | Rionya, Fire Dancer | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_968 | 8 | - | Etali, Primal Conqueror #105 (real) | spell_resolved | Rionya, Fire Dancer | token_maker | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_968 | 3 | precombat_main | Etali, Primal Conqueror #105 (real) | spell_cast | Cursed Mirror | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_966 | 6 | precombat_main | Zhulodok, Void Gorger #46 (real) | spell_cast | Mystic Forge | topdeck_manipulation | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_966 | 6 | - | Zhulodok, Void Gorger #46 (real) | spell_resolved | Mystic Forge | topdeck_manipulation | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
