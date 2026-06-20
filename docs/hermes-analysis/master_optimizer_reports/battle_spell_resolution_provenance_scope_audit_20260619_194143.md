# Battle Spell Resolution Provenance Scope Audit - 2026-06-19 19:41 UTC

## Scope

Readonly audit of spell/trigger resolution provenance in the current battle
strategy audit artifact. No PostgreSQL changes, no swaps, no code edits and no
commit.

## Primary artifact

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_193733`
- `timestamp_utc=2026-06-19T19:37:33Z`
- `battle_replay_final_status=review_required`
- `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`
- `mandatory_gate_divergences=["forensic_audit=review_required"]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`

Alert note: the user-defined alert conditions for high/critical action findings
and strategy blockers are not present in this latest artifact. The final battle
status is still `review_required` because the forensic gate has two medium
lineage findings.

## Forensic gate context

The current forensic review is incomplete:

- `forensic_lineage_status=incomplete`
- `forensic_rule_findings=2`
- `forensic_rule_logical_key_missing_unaccepted=2`
- `forensic_card_id_missing_unaccepted=2`
- `forensic_semantic_hash_missing_unaccepted=2`

The unaccepted samples are `Mardu Devotee` on seed `63201940` and
`Orcish Lumberjack` on seed `63201943`, both as `spell_cast` events from
`functional_tags_json`.

This report is not a duplicate of that gate finding. It documents a broader
resolution-ledger gap: the `spell_resolved` event itself does not carry enough
phase, stack and zone provenance to prove resolution without reading nearby
events or runtime code.

## Resolution event coverage

The scan covered all `seed_*/replay.events.jsonl` files under the latest
artifact.

| Event | Count | `phase` present | `stack_depth` present | `source_zone` present | `destination` present | `resolved_from_stack` present | `result` present |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `spell_resolved` | 293 | 0 | 0 | 0 | 0 | 0 | 0 |
| `trigger_resolved` | 89 | 89 | 0 | 0 | 0 | 0 | 31 |
| `composite_rule_component_resolved` | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| `composite_rule_resolved` | 1 | 0 | 0 | 0 | 0 | 0 | 0 |

For `spell_resolved`, all `293/293` rows are missing:

- `phase`
- `priority_window`
- `stack_depth`
- `source_zone`
- `destination`
- `zone_after`
- `from_zone`
- `to_zone`
- `cast_pipeline`
- `locked_cost`
- `resolved_from_stack`
- `target`
- `targets`
- `stack_object`
- `stack_object_id`
- `result`

Identity fields are also not complete on resolution rows:

- `card_id`: present `232`, missing `61`
- `semantic_hash`: present `232`, missing `61`
- `rule_logical_key`: present `293`, missing `0`

Top observed `spell_resolved` effects:

| Effect | Count |
| --- | ---: |
| `tutor` | 29 |
| `passive` | 29 |
| `topdeck_manipulation` | 24 |
| `token_maker` | 22 |
| `draw_cards` | 22 |
| `copy_spell` | 20 |
| `draw_engine` | 13 |
| `remove_creature` | 13 |
| `silence_spell` | 12 |
| `remove_permanent` | 11 |

Representative rows:

- Seed `63201937`, line `13`: `Esper Sentinel`, `draw_engine`, has
  `card_id`, `semantic_hash` and `rule_logical_key`, but no phase/stack/zone
  provenance on `spell_resolved`.
- Seed `63201937`, line `63`: `Demonic Consultation`, `tutor`, has
  `rule_logical_key`, but no `card_id`, `semantic_hash`, phase/stack/zone
  provenance.
- Seed `63201937`, line `215`: `Path to Exile`, `remove_creature`, has identity
  fields and rule key, but no target, phase, stack object, zone or result on
  `spell_resolved`.

## Code and contract observations

- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md` describes `spell_resolved` as
  carrying `card, effect, result`, but the current observed `293/293`
  `spell_resolved` rows have no `result`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  defines `CastingContext.to_replay_fields()` with `cast_pipeline`,
  `locked_cost`, `targets`, `source_zone` and related fields, but
  `apply_effect_immediate(...)` emits `spell_resolved` with only card/CMC/type,
  effect, turn, declared target fields derived from the effect data and rule
  fields.
- `finish_resolved_spell(...)` is called after effect application in many paths,
  so zone movement appears separate from the `spell_resolved` ledger row.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
  renders `RESOLVE SPELL` with player, card, CMC, effect and rule source/status;
  it cannot render phase, stack depth or destination because the event does not
  carry them.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
  currently uses `spell_resolved` mainly to pop a tracked cast or emit
  `resolve_without_cast`; it does not enforce resolution provenance fields.

## Risk

The replay can say a spell resolved, but it cannot prove from the
`spell_resolved` row itself:

- in which phase or priority window it resolved;
- from which stack object or stack depth it resolved;
- from which zone/source context it was cast;
- where the resolved card moved afterward;
- whether the row is the exact stack resolution or a synthetic effect marker;
- what target/result was locked for targeted spell effects.

That forces future analysis to infer resolution state from neighboring events,
renderer output, or runtime implementation details. This is fragile for legal
stack validation, WR analysis, strategy learning and human handoff review.

## Recommended adjustments

1. Carry `CastingContext` or equivalent `StackItem` metadata through resolution.
2. Emit on `spell_resolved`: `phase`, `priority_window` when available,
   `stack_depth`, `stack_object_id` or `stack_object`, `source_zone`,
   `cast_pipeline`, `locked_cost`, `targets`, `resolved_from_stack`, and
   `result`.
3. Emit an explicit zone transition on the same event or link it by id to the
   following zone movement event: `from_zone`, `to_zone`, `destination` or
   `zone_after`.
4. Add critic checks for `spell_resolved` without required provenance, or add a
   formal waiver for resolution rows intentionally represented by adjacent
   events.
5. Update the human renderer to print phase/stack/destination when present.
6. Surface missing-resolution-provenance counts in the main `summary.json`.

## Closing criteria

This finding can be closed when every observed `spell_resolved` has either:

- phase/priority, stack object/depth, source zone, cast context, target/result
  where applicable, and a zone transition or explicit linked zone event; or
- a documented waiver explaining which adjacent event owns each omitted field.

The action critic or a dedicated event-contract test should fail when new
`spell_resolved` rows lack required provenance without waiver.

## Validation commands run

- Structured scan over
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/replay.events.jsonl`
- Static search over:
  - `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
  - `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
  - `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`

