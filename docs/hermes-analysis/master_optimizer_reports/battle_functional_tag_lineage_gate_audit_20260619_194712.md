# Battle Functional Tag Lineage Gate Audit - 2026-06-19 19:47 UTC

## Scope

Readonly audit of the current forensic gate failure in the local ManaLoom battle
strategy artifact. No PostgreSQL changes, no swaps, no code edits and no commit.

## Primary artifact

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_193733`
- `timestamp_utc=2026-06-19T19:37:33Z`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `forensic_lineage_status=incomplete`
- `forensic_rule_findings=2`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`
- `seeds_with_strategy_blockers=[]`

Alert note: the user-defined high/critical action finding and strategy blocker
alert conditions are not present. The current review requirement is a medium
forensic lineage gate failure.

## Current unaccepted lineage samples

The latest summary reports six unaccepted missing lineage samples, all from two
cards:

| Seed | Card | Event | Effect | Missing fields | Source |
| --- | --- | --- | --- | --- | --- |
| `63201940` | `Mardu Devotee` | `spell_cast` | `ramp_permanent` | `rule_logical_key`, `card_id`, `semantic_hash` | `functional_tags_json` |
| `63201943` | `Orcish Lumberjack` | `spell_cast` | `ramp_permanent` | `rule_logical_key`, `card_id`, `semantic_hash` | `functional_tags_json` |

The per-seed forensic files confirm one medium finding per seed:

- `seed_63201940/forensic_audit.md`: `Mardu Devotee`, turn `1`,
  `precombat_main`, recommendation: move the card into `card_battle_rules` with
  verified/active status.
- `seed_63201943/forensic_audit.md`: `Orcish Lumberjack`, turn `9`,
  `precombat_main`, recommendation: move the card into `card_battle_rules` with
  verified/active status.

## Event evidence

The global latest scan found exactly `6` events with
`rule_source=functional_tags_json`:

| Event | Count |
| --- | ---: |
| `cast_announced` | 2 |
| `cost_paid` | 2 |
| `spell_cast` | 2 |

All six are `ramp_permanent`, and all six are missing:

- `rule_logical_key`
- `card_id`
- `semantic_hash`

There are no other `functional_tags_json` cards in the latest artifact.

### Mardu Devotee

Source:
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201940/replay.events.jsonl`

- Line `39`: `cast_announced`, `Mardu Devotee`, `ramp_permanent`,
  `rule_source=functional_tags_json`, `rule_review_status=heuristic`,
  `rule_confidence=0.35`, no `rule_logical_key`, no `card_id`, no
  `semantic_hash`.
- Line `40`: `cost_paid`, same lineage gap.
- Line `41`: `spell_cast`, same lineage gap, `cmc=1.0`,
  `type_line=Creature -- Human Scout`.

Seed forensic summary:

- `by_source={"curated":109,"functional_tags_json":1,"type_line_creature":2}`
- `by_status={"active":7,"fact":2,"heuristic":1,"verified":102}`
- `rule_logical_key_missing_unaccepted=1`
- `card_id_missing_unaccepted=1`
- `semantic_hash_missing_unaccepted=1`

### Orcish Lumberjack

Source:
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_63201943/replay.events.jsonl`

- Line `819`: `cast_announced`, `Orcish Lumberjack`, `ramp_permanent`,
  `rule_source=functional_tags_json`, `rule_review_status=heuristic`,
  `rule_confidence=0.35`, no `rule_logical_key`, no `card_id`, no
  `semantic_hash`.
- Line `820`: `cost_paid`, same lineage gap.
- Line `821`: `spell_cast`, same lineage gap, `cmc=1.0`,
  `type_line=Creature -- Orc`.

Seed forensic summary:

- `by_source={"curated":100,"functional_tags_json":1,"manual_runtime_waiver":2,"type_line_creature":4}`
- `by_status={"active":3,"fact":4,"heuristic":1,"verified":99}`
- `rule_logical_key_missing_unaccepted=1`
- `card_id_missing_unaccepted=1`
- `semantic_hash_missing_unaccepted=1`

## Runtime path

Relevant implementation observations from
`docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`:

- `load_deck_cards(...)` can load `card_id` and `semantics_hash` columns when
  they exist in the local SQLite `deck_cards` table.
- `get_card_effect(...)` first tries battle-rule registry and canonical/manual
  fallbacks.
- If no battle rule or canonical/manual fallback is selected,
  `get_card_effect(...)` iterates `card_functional_tags(card)` and returns
  `TAG_EFFECTS[tag]` wrapped with
  `with_rule_metadata(..., source="functional_tags_json",
  review_status="heuristic", confidence=0.35)`.
- That `TAG_EFFECTS` fallback does not pass a `logical_rule_key`.
- The observed events prove that these two cards reached replay events through
  the heuristic fallback without stable card identity fields.

Relevant implementation observations from
`docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`:

- `functional_tags_json` is listed as a heuristic source.
- Missing lineage for `functional_tags_json` is not accepted by
  `accepted_lineage_missing_reason(...)`.
- The forensic finding recommendation is to move the affected card into
  `card_battle_rules` with verified/active status.

## Risk

The battle can execute a card action from broad deckbuilding tags when no
reviewed battle rule is available. In the current latest this affects only two
cards, but it is enough to make the mandatory forensic gate fail.

The practical risk is not only missing IDs in logs. A `functional_tags_json`
fallback reduces the card to a generic `ramp_permanent` approximation, so
strategy learning can treat a card-specific behavior as a generic ramp spell.
That weakens card-specific WR, action explanation, replay trust and future
template completeness claims.

## Recommended adjustments

1. Add verified/active `card_battle_rules` entries for `Mardu Devotee` and
   `Orcish Lumberjack`, with stable `logical_rule_key` and review evidence, or
   explicitly waive them with owner, reason and expiry.
2. Prevent `functional_tags_json` from silently producing action-audited card
   events without `card_id`, `semantic_hash` and a stable rule key.
3. If functional-tag fallback remains allowed for exploration, label it as a
   non-learning, low-trust path and surface affected cards/counts in
   `summary.json`.
4. Add a regression fixture where a card with only `functional_tags_json`
   fallback fails forensic unless it has a waiver.
5. Keep `functional_tags_json` separate from focused-template readiness when
   answering whether all action templates are complete.

## Closing criteria

This finding can be closed when the latest artifact has:

- `battle_replay_final_status` no longer blocked by
  `forensic_audit=review_required`;
- zero unaccepted missing lineage samples from `functional_tags_json`;
- no `functional_tags_json` action-audited events, or a documented waiver for
  each observed card;
- a test/critic/gate that prevents future heuristic functional-tag events from
  being treated as learning-grade card actions.

## Validation commands run

- Parsed latest `summary.json`.
- Scanned all
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
  rows for `rule_source=functional_tags_json`.
- Read per-seed forensic summaries:
  - `seed_63201940/forensic_audit.json`
  - `seed_63201940/forensic_audit.md`
  - `seed_63201943/forensic_audit.json`
  - `seed_63201943/forensic_audit.md`
- Static inspection of:
  - `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`

