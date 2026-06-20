# Battle Decision Trace Taxonomy

Status: current as of `2026-06-20T04:01Z`.

Fonte atual:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/decision_trace_taxonomy.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/decision_trace_taxonomy.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/summary.json`

Leitura operacional: `decision_trace_taxonomy_ready` significa que os tipos
observados/estaticos possuem contrato, dono, waiver ou fixture esperado. Nao
significa que todos os `15/15` tipos foram observados no latest.
Tambem nao significa que todas as decisoes observadas tenham o mesmo grau de
aprendizado: tipos `accepted_field_contract_waiver` sao field-contract-only ate
o summary/taxonomy publicar `decision_learning_grade` ou auditoria estrategica
dedicada. Ver `BV-085` no register.

## Current Summary

- `decision_trace_taxonomy_status=decision_trace_taxonomy_ready`
- `decision_trace_taxonomy_rows=2326`
- `decision_trace_kinds_total=15`
- `decision_trace_kinds_observed=11`
- `decision_trace_kinds_uncovered=4`
- `decision_trace_static_uncovered_types=["activated_sacrifice_damage","attack_trigger_artifact_tutor","board_wipe","worldfire_reset"]`
- `decision_trace_contract_findings=0`
- `decision_trace_missing_required_fields=0`
- `decision_trace_static_without_contract=0`
- `decision_trace_observed_without_contract=0`
- `decision_trace_observed_without_specific_contract=0`
- `decision_trace_kinds_without_specific_contract=0`
- `decision_trace_accepted_waivers=["activated_sacrifice_damage","attack_trigger_artifact_tutor","lorehold_upkeep_rummage","saga_chapter_resolution","utility_artifact_activation","utility_land_activation"]`

## Ownership Matrix

| Decision type | Latest count | Observed | Owner | Strategy auditor | Research category | Specific status | Fixture/gate |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| `activated_sacrifice_damage` | 0 | no | `activated-sacrifice-damage-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `attack_trigger_artifact_tutor` | 0 | no | `attack-trigger-artifact-tutor-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `board_wipe` | 0 | no | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `board_wipe_wheel` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `cast_spell` | 493 | yes | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `cast_spell` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `combat_attack` | 265 | yes | `battle_decision_research_review.py` | `generic_strategy_fields_only` | `combat_attack` | `specific_via_research` | `test_battle_decision_research_review.py` |
| `lorehold_upkeep_rummage` | 109 | yes | `lorehold-upkeep-rummage-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `mulligan_decision` | 118 | yes | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `mulligan` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `pass_no_action` | 1206 | yes | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `pass_no_action` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `response` | 19 | yes | `battle_decision_research_review.py` | `generic_strategy_fields_only` | `response` | `specific_via_research` | `test_battle_decision_research_review.py` |
| `saga_chapter_resolution` | 2 | yes | `saga-chapter-resolution-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `tutor` | 39 | yes | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `tutor` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `utility_artifact_activation` | 50 | yes | `utility-artifact-activation-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `utility_land_activation` | 18 | yes | `utility-land-activation-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` |
| `wheel` | 7 | yes | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `board_wipe_wheel` | `specific` | `test_battle_decision_strategy_auditor.py` |
| `worldfire_reset` | 0 | no | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `-` | `specific` | `test_battle_decision_strategy_auditor.py` |

## Accepted Waivers

- `activated_sacrifice_damage`: deterministic activated damage outlet; strategy trust is bounded by target, damage and creature-options trace fields until a dedicated research category is justified.
- `attack_trigger_artifact_tutor`: triggered artifact tutor is narrow and non-optional quality is captured by treasures/candidate-count plus chosen tutor option.
- `lorehold_upkeep_rummage`: commander-engine bookkeeping; trace must expose discard destination and drawn card, while broader strategic quality remains covered by parent engine choices.
- `saga_chapter_resolution`: deterministic trigger resolution; contract is chapter, candidate count and selected reason.
- `utility_artifact_activation`: narrow deterministic resource conversion; each observed row must expose activation-cost or activation-family score keys before it can be used as trace evidence.
- `utility_land_activation`: deterministic resource conversion; each row must expose an activation-family score key.

## Findings

- No taxonomy contract findings in `20260620_040120`.
- Observability follow-up: the latest has `179` observed
  `accepted_field_contract_waiver` rows and `0` parent-link rows among them.
  This is tracked as `BV-085` because the current `summary.json` does not yet
  publish waiver-observed counts or `decision_learning_grade` by type.
