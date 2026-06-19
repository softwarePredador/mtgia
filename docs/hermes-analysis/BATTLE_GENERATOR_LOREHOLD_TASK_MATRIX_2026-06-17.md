# Battle + Generator + Lorehold Task Matrix - 2026-06-17

## Objetivo

Transformar o estado real já apurado sobre:

- battle simulator Hermes;
- `/ai/generate` e builder determinístico;
- caso de controle `Lorehold, the Historian`;

em uma matriz única de execução, com prioridade, dependência, evidência de
código/artefato e critério objetivo de fechamento.

Este documento não reabre hipótese antiga já encerrada. Ele parte de três
verdades consolidadas:

1. o battle runtime não está mais quebrado por precedence de fallback;
2. o generator não é prompt-only e já é backend-owned com validação real;
3. o Lorehold já tem profile persistido canônico e deck de controle usável.

Spec técnica derivada desta matriz:

- [BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md)

## Fontes base

- [BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md)
- [IMPLEMENTATION_GAPS.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/IMPLEMENTATION_GAPS.md)
- [LOREHOLD_GENERATOR_SOURCE_MIX_AUDIT_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_GENERATOR_SOURCE_MIX_AUDIT_2026-06-17.md)
- [LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md)
- [LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md)
- [LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md)
- [BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md)
- [BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md)
- [commander_generate_provenance_summary.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/test/artifacts/commander_generate_provenance_2026-06-17_live5/commander_generate_provenance_summary.json)
- [lorehold_generator_source_mix_2026-06-17.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_generator_source_mix_2026-06-17.json)

Referências externas rechecadas nesta rodada:

- [Magic Comprehensive Rules](https://magic.wizards.com/en/rules)
- [Commander oficial](https://magic.wizards.com/en/formats/commander)
- [London Mulligan](https://magic.wizards.com/en/news/announcements/london-mulligan-2019-06-03)
- [EDHREC Guide to Mulligans in Commander](https://edhrec.com/guides/the-edhrec-guide-to-mulligans-in-commander)
- [EDHREC Threat Assessment](https://edhrec.com/articles/how-to-be-new-at-threat-assessment-in-commander)
- [Miracles Every Turn With Lorehold, the Historian](https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander)
- [17Lands - Using Win Rate Data](https://blog.17lands.com/posts/using-win-rate-data/)
- [17Lands Metrics Definitions](https://www.17lands.com/metrics_definitions)

## Regras fixas

- PostgreSQL/backend continua fonte de verdade.
- Hermes continua laboratório, auditor e gerador de evidência.
- SQLite Hermes continua cache operacional/laboratório.
- O app Flutter continua consumidor, não decisor.
- Learned deck continua single-commander até existir corpus forte para
  Partner/Background.
- Sem ban global de Mox.
- `needs_review` não executa comportamento duro.
- `card_battle_rules` só pode derivar tags/efeito quando trusted e traceable.
- Relatório Hermes antigo sem rerun contra o `master` atual vale como pista,
  não como fato.

## Tarefas priorizadas

| Pri | Frente | Task | Evidência atual | O que fazer | Critério de fechamento |
| --- | --- | --- | --- | --- | --- |
| P1 | Battle | `decision_trace_v1` comparativo | O trace atual já registra coerência/legalidade, mas ainda não explica por que a ação escolhida venceu as rejeitadas. | Adicionar score comparativo por opção em cast/response/combat/pass/tutor/mulligan. | Replay com `available_options`, score da escolhida, score das rejeitadas e motivo explícito das rejeições nas decisões de maior impacto. |
| P1 | Battle | Scorecard Commander-safe | Hoje ainda não existe camada canônica de `seen vs unseen`, `cast vs not cast`, delta por `baseline_hash` e amostra mínima. | Evoluir métricas Hermes inspiradas em 17Lands, sem usar 17Lands como dado Commander. | Relatório por carta/swap com `sample_size`, `seen_wr`, `not_seen_wr`, `cast_wr`, `not_cast_wr`, `delta_vs_baseline` e `confidence`. |
| P1 | Battle | Executor genérico de activated abilities recorrentes | `Ashnod's Altar` já tem metadata confiável, mas ainda não executa a habilidade ativada. | Criar família mínima de executor para `sacrifice_creature -> add mana` e outras activated abilities simples recorrentes. | Replays deixam de cair em `review_rule_used` para essas cartas e testes focados passam. |
| P1 | Battle | Multi-row real em `card_battle_rules` | Infra pronta; PostgreSQL ainda com `multi_rule_card_count = 0`. | Persistir 3-5 cartas reais com escopos distintos: `spell_resolution`, `activated_ability`, `trigger_resolution`, `cost_annotation` ou `static_layer`. | Auditor multi-rule reencontra casos reais no PG e o runtime seleciona por escopo, não por nome cru. |
| P1 | Generator | Política explícita de precedência do builder | O builder determinístico hoje usa `stats -> corpus -> profile -> learned -> usage -> fallback`, mas isso ainda é verdade de código, não decisão de produto documentada. | Congelar e documentar a ordem de precedência; depois refletir no código e nos auditores. | Geração, provenance audit e docs passam a convergir para a mesma política declarada. |
| P1 | Generator | Curar `fallback_without_profile_or_stats` do Lorehold | Bucket factual live5: 9 cartas; live pós-backfill v2: 0. | Fechado em 2026-06-19 com profile/stats aplicados no PostgreSQL e rerun source-mix. | Manter teste de regressão para as 12 staples/interações incorporadas. |
| P1 | Generator | Curar `learned_plus_fallback_only` do Lorehold | Bucket factual live5: 2 cartas (`Fellwar Stone`, `Lightning Greaves`); live pós-backfill v2: 0. | Fechado em 2026-06-19 via `mana_ramp_foundation` e `protection_and_equipment`. | Próximos reruns não podem voltar a listar learned+fallback-only. |
| P1 | Generator | Revisar `fallback_profile_stats_no_empirical_support` | Bucket factual live5: 18 cartas; live pós-backfill v2: 0; live v4 com provenance runtime: `fallback_touched_count=0`. | Fechado em 2026-06-19 porque fallback só é rotulado quando realmente introduz carta. | Manter auditor usando provenance runtime real, não reclassificação por lista fallback estática. |
| P1 | Lorehold | Revalidar o pacote de miracle/topdeck do comandante | A auditoria `LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md` confirmou que o generator já puxa `Top`, `Rack`, `Brainstone`, `Mikokoro` e `Library of Leng`, mas o battle ainda não modela explicitamente o rummage no upkeep do oponente, ainda trata `topdeck_manipulation` de forma rasa e ainda carrega `Library of Leng` como `ramp_permanent`. | Fechar o gap entre lista temática e execução real: promover regra expressiva do comandante, modelar o trigger de upkeep, quebrar `topdeck_manipulation` em capabilities reais e corrigir `Library of Leng`. | O deck final continua alinhado a `miracle/topdeck/spellslinger`, e o battle rastreia miracle/topdeck lines sem ambiguidade crítica nem carta-chave mal classificada. |
| P1 | Lorehold | Validar aprendizado só com corpus confiável | O Lorehold já é deck de controle válido, mas ainda tem 42 cartas tocadas por fallback e coverage parcial dos oponentes. | Tratar o deck como caso de controle, não como “melhor deck final” até fechar os buckets P1 e melhorar o scorecard. | Novo relatório Lorehold classificado como `trusted`, `needs_more_samples` ou `blocked`, com justificativa reproduzível. |
| P2 | Battle | Melhorar mulligan bottoming por plano do deck | Mulligan já é melhor que land-count-only, mas o bottom ainda é simples. | Bottom por função: preservar lands necessárias, early plays, ramp e plano do comandante; mandar high-cost dead cards primeiro. | Testes de mãos pesadas/curvas ruins passam com justificativa mais rica no trace. |
| P2 | Battle | Refinar utility lands remanescentes só se impactarem aprendizado | Lorehold hoje tem 9 cartas de risco médio, quase todas utility lands já parcialmente tratadas. | Não abrir frente ampla de lands; atacar apenas se os auditores mostrarem impacto real em replay/learning. | Redução de medium-risk por evidência, não por perfeccionismo especulativo. |
| P2 | Process | Reexecutar relatórios Hermes stale antes de abrir task | A branch `origin/codex/hermes-analysis-docs` está atrás do `master` local nas frentes battle/generator/Lorehold. | Reaproveitar relatório Hermes antigo só depois de rerun em cima do hash atual. | Nenhuma task nova fica ancorada apenas em doc Hermes histórico. |

## Ordem recomendada

### Fase 1 — Battle confiável para aprendizagem

1. `decision_trace_v1` comparativo
2. executor genérico de activated abilities recorrentes
3. scorecard Commander-safe
4. primeiro lote multi-row real em `card_battle_rules`

Motivo:

- sem isso, o battle ainda é bom para bloquear erro, mas fraco para gerar
  aprendizado comparativo;
- sem isso, WR alto de Lorehold continua sinal fraco.

### Fase 2 — Generator com explicabilidade real

5. decisão explícita de precedência
6. backfill das 9 `fallback_without_profile_or_stats` no código/profile,
   ampliado para 12 após rerun live e confirmado no PostgreSQL em 2026-06-19
7. cura das 2 `learned_plus_fallback_only` confirmada no rerun live
8. revisão das 18 `fallback_profile_stats_no_empirical_support` confirmada no
   rerun live; fallback label residual zerado no rerun v4

Motivo:

- isso reduz exatamente o fallback residual que ainda impede chamar o Lorehold
  de `fully source-backed`.

### Fase 3 — Lorehold como caso de controle confiável

9. reexecutar provenance/source-mix
10. reexecutar coverage matrix
11. reexecutar battle + decision audit
12. classificar o deck como `trusted`, `needs_more_samples` ou `blocked`

Motivo:

- o objetivo aqui não é “provar que Lorehold é perfeito”, e sim saber o quanto
  dele já pode ensinar o sistema sem contaminar optimize/generate.

## Tarefas que não devem ser abertas agora

- Reescrever o battle como judge engine completo.
- Zerar `deterministic_fallback` do Lorehold à força.
- Dar prioridade total ao learned deck sem policy explícita.
- Generalizar multi-rule “por nome” sem escopo/executor.
- Atacar utility lands em massa sem evidência de impacto.
- Tratar relatórios Hermes antigos como backlog ativo sem rerun.

## Checklist de validação por fase

### Battle

- `python3 -m py_compile` nos scripts alterados
- suites Python focadas do battle/runtime
- replay forense com zero `critical/high`
- auditor estratégico sem blockers para o slice alterado
- relatório de research review atualizado

### Generator

- `dart analyze bin lib routes test`
- `dart test` focado em generate/provenance/source-mix
- rerun do provenance audit
- rerun do source-mix audit

### Lorehold

- snapshot/provenance atualizados
- coverage matrix atualizada
- rationale final coerente com o plano `miracle/topdeck/spellslinger`
- conclusão explícita do nível de confiança do deck

## Veredito operacional

O projeto já saiu do estágio “arrumar bug óbvio” e entrou no estágio de
qualidade de decisão e qualidade de evidência.

O battle precisa melhorar em comparabilidade e execução de abilities
recorrentes. O generator precisa reduzir fallback residual e congelar a política
de precedência. O Lorehold já é um caso de controle válido, mas ainda não é
prova final de que o sistema aprendeu o deck ideal.

Se a implementação seguir esta ordem, o próximo ciclo deixa de ser tentativa
cega e passa a ser evolução mensurável.
