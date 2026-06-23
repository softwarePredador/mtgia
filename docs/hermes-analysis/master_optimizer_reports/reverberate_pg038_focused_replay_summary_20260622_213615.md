# Reverberate PG038 focused replay

Generated: 2026-06-22T21:36:15-03:00

## Scenario

- Active player controls an unresolved sorcery on stack: `Targeted Insight` with effect `draw_cards`, count `1`.
- Responder has `Reverberate` in hand and exactly two red mana.
- PostgreSQL/Hermes rule resolved through `get_card_effect(Reverberate)`.

## Rule proof

- `rule_logical_key`: `battle_rule_v1:0269136edf067f696c8576740b720e14`
- `rule_oracle_hash`: `cbae05dee4261e3ed5412fd5f3591c17`
- `battle_model_scope`: `reverberate_copy_stack_instant_or_sorcery_new_targets_annotation_v1`
- Executor: `copy_spell` targeting `instant_or_sorcery_on_stack`.
- Caveat: `may_choose_new_targets` is retained as `annotation_only`; this replay proves stack copy creation/resolution only, not dynamic retarget selection.

## Event proof

- `spell_cast` seq 1: `Reverberate` responded to `Targeted Insight` with PG038 key/hash.
- `spell_copied` seq 2: copied `Targeted Insight`; copy was not cast.
- `spell_resolved` seq 6: copied `Targeted Insight` resolved for `Responder` and had destination `ceased_to_exist`.
- `spell_copy_ceased_to_exist` seq 8: copy left the stack without going to a graveyard.
- `spell_resolved` seq 11: original `Targeted Insight` resolved for `Active` and moved to graveyard.

## State proof

- Top of stack after `Reverberate`: `Targeted Insight` copy controlled by `Responder`.
- Responder drew `Responder Draw` from the copied spell.
- Active drew `Active Draw` from the original spell.
- Original spell ended in Active graveyard.

## Artifact

- Events JSONL: `docs/hermes-analysis/master_optimizer_reports/reverberate_pg038_focused_events_20260622_213615.jsonl`
