# Hermes Battle Forensic Audit

- generated_at: 2026-06-07 23:20:11 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 1914
- card_events: 826
- unique_cards_seen: 235
- findings_total: 5
- critical: 0
- high: 2
- medium: 1
- low: 2

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_200.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_200.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_201.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_201.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_202.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_202.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_203.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_203.jsonl`
- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_204.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_204.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 589 |
| `manual` | 190 |
| `type_line_creature` | 44 |
| `generated` | 3 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 779 |
| `fact` | 44 |
| `needs_review` | 3 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 214 |
| `draw_cards` | 133 |
| `ramp_permanent` | 59 |
| `tutor` | 57 |
| `creature` | 48 |
| `ramp_ritual` | 43 |
| `counter` | 30 |
| `silence_opponents` | 28 |
| `token_maker` | 24 |
| `ramp_engine` | 23 |
| `draw_engine` | 22 |
| `remove_permanent` | 22 |
| `copy_spell` | 20 |
| `remove_creature` | 14 |
| `finisher` | 10 |
| `indestructible` | 10 |
| `topdeck_manipulation` | 10 |
| `approach` | 8 |
| `board_wipe` | 8 |
| `modal_boros_charm` | 8 |
| `overload_recursion` | 8 |
| `recursion` | 8 |
| `equipment_haste_shroud` | 6 |
| `commander` | 5 |
| `redirect_removal` | 4 |
| `extra_turn` | 2 |
| `phase_out` | 2 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | seed_201 | 21 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Sevinne's Reclamation | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| high | seed_201 | 21 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Sevinne's Reclamation | remove_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| medium | seed_201 | 19 | precombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Birds of Paradise | ramp_permanent | Game event depended on a needs_review rule. | Review oracle text/rulings, add a regression test if impactful, then promote to verified. |
| low | seed_201 | 21 | postcombat_main | Najeela, the Blade-Blossom #111 (real) | spell_cast | Sevinne's Reclamation | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `recursion`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_201 | 21 | - | Najeela, the Blade-Blossom #111 (real) | spell_resolved | Sevinne's Reclamation | remove_permanent | Runtime effect `remove_permanent` differs from registry effect `recursion`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
