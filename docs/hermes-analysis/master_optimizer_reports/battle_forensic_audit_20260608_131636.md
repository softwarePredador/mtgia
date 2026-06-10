# Hermes Battle Forensic Audit

- generated_at: 2026-06-08 13:16:36 UTC
- status: blocked
- sqlite_db: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\manaloom-knowledge\scripts\knowledge.db`
- structured_events: 232
- card_events: 95
- unique_cards_seen: 58
- findings_total: 18
- critical: 4
- high: 0
- medium: 10
- low: 4

## Replay Evidence

- text: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.txt`
- events: `C:\Users\rafae\OneDrive\Documents\mtgia\docs\hermes-analysis\master_optimizer_reports\forensic_replays\battle_forensic_seed_777.jsonl`

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 58 |
| `known_cards_manual` | 30 |
| `type_line_creature` | 7 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 88 |
| `fact` | 7 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 25 |
| `draw_cards` | 12 |
| `ramp_permanent` | 11 |
| `creature` | 9 |
| `ramp_ritual` | 5 |
| `approach` | 4 |
| `damage_each_opponent` | 4 |
| `tutor` | 4 |
| `board_wipe` | 2 |
| `counter` | 2 |
| `draw_engine` | 2 |
| `equipment_haste_shroud` | 2 |
| `land_recursion_creature` | 2 |
| `life_artifact` | 2 |
| `ramp_engine` | 2 |
| `remove_creature` | 2 |
| `silence_opponents` | 2 |
| `token_maker` | 2 |
| `commander` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| critical | seed_777 | 4 | precombat_main | Lumra, Bellow of the Woods #49 (real) | commander_cast | Lumra, Bellow of the Woods | land_recursion_creature | Effect `land_recursion_creature` is not implemented by battle_analyst_v8.py. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_777 | 6 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Zuran Orb | life_artifact | Effect `life_artifact` is not implemented by battle_analyst_v8.py. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_777 | 6 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Zuran Orb | life_artifact | Effect `life_artifact` is not implemented by battle_analyst_v8.py. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_777 | 9 | precombat_main | Lumra, Bellow of the Woods #49 (real) | commander_cast | Lumra, Bellow of the Woods | land_recursion_creature | Effect `land_recursion_creature` is not implemented by battle_analyst_v8.py. | Implement the effect branch or map the card to a supported approximation. |
| medium | seed_777 | 1 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 1 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 1 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 1 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 2 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 3 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 3 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 3 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 6 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| medium | seed_777 | 9 | precombat_main | Lorehold | trigger_resolved | ? | draw_cards | Card used legacy known-cards fallback but is absent from battle_card_rules cache. | Sync card_battle_rules from PG and confirm the card exists in card_battle_rules. |
| low | seed_777 | 4 | precombat_main | Lumra, Bellow of the Woods #49 (real) | commander_cast | Lumra, Bellow of the Woods | land_recursion_creature | Runtime effect `land_recursion_creature` differs from registry effect `recursion`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_777 | 6 | precombat_main | Lumra, Bellow of the Woods #49 (real) | spell_cast | Zuran Orb | life_artifact | Runtime effect `life_artifact` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_777 | 6 | - | Lumra, Bellow of the Woods #49 (real) | spell_resolved | Zuran Orb | life_artifact | Runtime effect `life_artifact` differs from registry effect `ramp_permanent`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_777 | 9 | precombat_main | Lumra, Bellow of the Woods #49 (real) | commander_cast | Lumra, Bellow of the Woods | land_recursion_creature | Runtime effect `land_recursion_creature` differs from registry effect `recursion`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
