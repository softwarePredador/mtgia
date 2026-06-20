# Hermes Battle Forensic Audit

- generated_at: 2026-06-19 21:37:48 UTC
- status: blocked
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 1
- card_events: 1
- unique_cards_seen: 1
- rule_logical_key_present: 0
- rule_logical_key_missing: 1
- rule_logical_key_missing_accepted: 0
- rule_logical_key_missing_unaccepted: 1
- card_id_present: 0
- card_id_missing: 1
- card_id_missing_accepted: 0
- card_id_missing_unaccepted: 1
- semantic_hash_present: 0
- semantic_hash_missing: 1
- semantic_hash_missing_accepted: 0
- semantic_hash_missing_unaccepted: 1
- findings_total: 1
- critical: 0
- high: 1
- medium: 0
- low: 0

## Replay Evidence

- external JSONL replay was audited.

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `functional_tags_json` | 1 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `heuristic` | 1 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `draw_cards` | 1 |

## Accepted Lineage Missing Waiver Reasons

| Value | Count |
| --- | ---: |
| none | 0 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| none | 0 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| high | replay.events | 1 | - | Tester | spell_resolved | Synthetic Functional Fallback | draw_cards | Game event depended on heuristic source `functional_tags_json`. | Move this card into card_battle_rules with verified/active status. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
