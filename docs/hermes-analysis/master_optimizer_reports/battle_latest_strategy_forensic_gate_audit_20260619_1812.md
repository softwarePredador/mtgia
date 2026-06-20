# Battle Latest Strategy and Forensic Gate Audit - 2026-06-19T18:12Z

## Escopo

Auditoria read-only dos gates que ainda mantem o latest em
`review_required`, alem de `focused_template_dispatch`.

Fontes verificadas:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911/seed_*/replay.events.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`

Nenhuma consulta ou alteracao PostgreSQL foi feita. Nenhum swap foi aplicado.
Nenhum codigo de produto foi alterado.

## Estado do latest

- Latest: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_175911`
- `battle_replay_final_status=review_required`
- `mandatory_gate_divergences=["focused_template_dispatch=review_required", "forensic_audit=review_required", "strategy_audit=review_required"]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

Nao ha alerta atual pelo criterio pedido pelo usuario
(`high/critical` em action findings ou strategy blockers). Ainda assim, o
replay nao e evidencia final confiavel porque tres gates obrigatorios continuam
em revisao.

## Strategy gate

Resumo:

- `strategy_findings=3`
- `strategy_severity_counts={"medium":3}`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":3}`
- `strategy_learning_confidence_counts={"high_confidence_replay":13,"low_confidence_replay":3}`
- `strategy_low_confidence_seeds=["63201739","63201740","63201741"]`
- `seeds_with_strategy_blockers=[]`

Findings:

| Seed | Player | Decision | Keep score | Rejected mulligan score | Score gap | Risk flags | Reading |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| `63201739` | `Kinnan, Bonder Prodigy #84 (real)` | `decision-000005` | `-5.0` | `5.0` | `-10.0` | `no_early_game_plan`, `off_color_early_hand`, `forced_keep_after_mulligan_cap` | Forced keep after cap; replay must not count as high-confidence learning. |
| `63201740` | `The Emperor of Palamecia #42 (real)` | `decision-000009` | `-1.0` | `1.0` | `-2.0` | `no_early_game_plan`, `forced_keep_after_mulligan_cap` | Forced keep after cap; replay must not count as high-confidence learning. |
| `63201741` | `Thrasios, Triton Hero #54 (real)` | `decision-000015` | `-5.0` | `5.0` | `-10.0` | `no_early_game_plan`, `off_color_early_hand`, `forced_keep_after_mulligan_cap` | Forced keep after cap; replay must not count as high-confidence learning. |

Interpretacao:

- Isto nao e blocker de legalidade e nao indica high/critical.
- O auditor ja separa esses seeds com `high_confidence_learning_weight=0.0`.
- O risco restante e downstream: qualquer relatorio de WR/aprendizado que trate
  `16/16` seeds como equivalentes ignora que apenas `13` sao high-confidence.

## Forensic gate

Resumo:

- `forensic_rule_findings=8`
- `forensic_severity_counts={"medium":2,"low":6}`
- `forensic_card_event_count=1487`
- `forensic_card_id_present/missing=953/534`
- `forensic_semantic_hash_present/missing=953/534`
- `forensic_rule_logical_key_present/missing=1469/18`
- `forensic_lineage_status=incomplete`

Findings de severidade media:

| Seed | Event index | Card | Player | Event | Source | Review status | Effect | Finding |
| --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| `63201738` | `712` | `Moonsnare Prototype` | `Kinnan, Bonder Prodigy #84 (real)` | `spell_cast` | `functional_tags_json` | `heuristic` | `ramp_permanent` | Evento dependeu de fonte heuristica. |
| `63201739` | `277` | `Sacrifice` | `Dargo, the Shipwrecker #74 (real)` | `spell_cast` | `functional_tags_json` | `heuristic` | `ramp_permanent` | Evento dependeu de fonte heuristica. |

Findings de severidade baixa:

| Seed | Events | Card | Runtime effect | Registry effect | Reading |
| --- | --- | --- | --- | --- | --- |
| `63201740` | `miracle_cast`, `spell_resolved` | `Rise of the Eldrazi` | `remove_permanent` | `extra_turn` | O evento tem `card_id`, `semantic_hash` e `rule_logical_key`; precisa alinhar contrato composite/oracle para nao repetir divergencia baixa. |
| `63201741` | `miracle_cast`, `spell_resolved` | `Rise of the Eldrazi` | `remove_permanent` | `extra_turn` | O evento tem `card_id`, `semantic_hash` e `rule_logical_key`; precisa alinhar contrato composite/oracle para nao repetir divergencia baixa. |
| `63201745` | `spell_cast`, `spell_resolved` | `Rise of the Eldrazi` | `remove_permanent` | `extra_turn` | O evento tem `card_id`, `semantic_hash` e `rule_logical_key`; precisa alinhar contrato composite/oracle para nao repetir divergencia baixa. |

Linhagem agregada:

| Metric | Count | Share |
| --- | ---: | ---: |
| `card_event_count` | `1487` | `100.00%` |
| `card_id_missing` | `534` | `35.91%` |
| `semantic_hash_missing` | `534` | `35.91%` |
| `rule_logical_key_missing` | `18` | `1.21%` |

Interpretacao:

- A ausencia de high/critical forensic e boa, mas nao fecha a linhagem.
- `functional_tags_json` ainda aparece como fonte de comportamento de partida
  em `Moonsnare Prototype` e `Sacrifice`.
- `Rise of the Eldrazi` melhorou para eventos com identificadores completos,
  mas ainda repete divergencia `remove_permanent` vs `extra_turn`, indicando
  que o contrato composite precisa ser refletido de ponta a ponta.
- O denominador de linhagem ainda e incompleto: mais de um terco dos card
  events nao carrega `card_id`/`semantic_hash`.

## Ajustes necessarios

1. Strategy: manter os tres seeds low-confidence fora de qualquer aprendizado,
   WR de alta confianca ou scorecard que nao tenha ponderacao explicita.
2. Strategy: o summary/consumidor deve exibir sempre denominador separado:
   `13 high_confidence` e `3 low_confidence`, nunca apenas `16 seeds`.
3. Forensic: promover ou waiver explicitamente `Moonsnare Prototype` e
   `Sacrifice` para uma fonte nao-heuristica antes de usar esses eventos como
   aprendizado de efeito.
4. Forensic: alinhar `Rise of the Eldrazi` para contrato composite, de modo que
   a auditoria veja `composite_resolution` ou subcomponentes aceitos em vez de
   repetir drift baixo entre runtime e registry.
5. Forensic: reduzir `card_id_missing` e `semantic_hash_missing` para zero nos
   eventos de carta com regra conhecida, ou declarar waiver por classe de evento
   que nao pode carregar esses campos.

## Criterio de fechamento

- `strategy_audit.status=pass` ou o status final aceita explicitamente seeds
  low-confidence sem bloquear a confianca agregada, mantendo peso `0.0`.
- Nenhum consumidor de aprendizado/WR usa os `3` seeds low-confidence como
  amostras high-confidence.
- `forensic_audit.status=pass`, `forensic_rule_findings=0` ou cada finding
  restante tem waiver aceito.
- `forensic_lineage_status=complete`, ou todo missing `card_id`/`semantic_hash`
  tem waiver por classe de evento no report.

## Validacoes executadas

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS, `15` testes.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` - PASS, `6` testes.
- `git diff --check -- docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md docs/hermes-analysis/master_optimizer_reports/battle_latest_strategy_forensic_gate_audit_20260619_1812.md` - PASS.
