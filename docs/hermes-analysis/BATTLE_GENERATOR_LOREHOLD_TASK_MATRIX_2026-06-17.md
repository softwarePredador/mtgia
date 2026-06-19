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

Atualizacao 2026-06-19: a inspecao manual do artefato local
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-battle-simulation/20260619_135854/`
mostrou que `replay.txt` ainda e um resumo humano incompleto. Os JSONL
estruturados carregam land drops, tentativas ilegais, prioridade e trace, mas o
texto omite land play, pagamento de custo, alvo/resultado de counter, fases e
conteudo real do board. Isso deve virar task explicita porque o proximo Codex
que trabalhar em battle precisa validar o replay textual contra
`replay.events.jsonl`/`replay.decision_trace.jsonl`, nao assumir que o texto
sozinho prova legalidade.

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
| P1 | Battle | `decision_trace_v1` comparativo | O trace atual já cobre pass/cast/rummage e, em 2026-06-19, passou a pontuar `keep` vs `mulligan` para mãos pesadas. Ainda falta ampliar a mesma exigência para todas as decisões complexas de tutor/response/combat. | Continuar adicionando score comparativo onde o runtime já possui ranking local, sem inventar EV perfeito. | Replay com `available_options`, score da escolhida, score das rejeitadas e motivo explícito das rejeições nas decisões de maior impacto. |
| P1 | Battle | Replay textual auditável e coerente com JSONL | Replay manual `20260619_135854`, seed `786135854`, mostrou divergência de observabilidade no turno 1: `replay.txt` omite `Sunbillow Verge`, `Dryad Arbor`, `Scrubland`, `Breeding Pool`, pagamento de custos, fases detalhadas e board contents; também mostra `Mental Misstep` como `RESOLVE` sem alvo/resultado claro, enquanto `replay.events.jsonl` registra `end_step_instant` depois de `Sensei's Divining Top` já ter resolvido. | Fazer o render de `replay.txt` derivar os eventos estruturados essenciais: `PLAY LAND`, `TAP/PAY COST`, `CAST/RESOLVE` com phase, targets e counter result, tentativas ilegais relevantes, mudanças de vida por custo, e snapshot legível de permanentes no fim do turno. Adicionar auditor/teste que compare texto e JSONL para impedir que um evento critico exista só no side-channel estruturado. | O mesmo seed ou fixture equivalente deve gerar `replay.txt` contendo land drops/custos/alvos/fases suficientes para auditar o turno 1 sem abrir o JSONL; `Mental Misstep` precisa declarar alvo e resultado legal, ou ser marcado como finding bloqueante quando nao houver alvo valido. |
| P1 | Battle | Scorecard Commander-safe | Em 2026-06-19 o `server/bin/card_impact_analyzer.py` ganhou scorecard replay-derived com `seen_wr`, `not_seen_wr`, `cast_wr`, `not_cast_wr`, `delta_vs_baseline`, `baseline_hash`, `sample_quality` e resumo `trusted/needs_more_samples/blocked` via `--json-summary-output`. Isso reduz o risco de confiar em WR bruto, mas ainda nao prova qualidade final sem corpus maior. | Rodar o scorecard em lote Lorehold/control decks, congelar `baseline_hash` por rodada e adicionar segmentacao por arquétipo/turno antes de usar como gate de swap. | Relatório por carta/swap com amostra utilizável, baseline reproduzível e conclusão explícita; sem auto-apply. |
| P1 | Battle | Executor genérico de activated abilities recorrentes | Em 2026-06-19 `Ashnod's Altar` foi coberta por teste focado: o executor `activated_mana_ability + activation_cost=sacrifice_creature` sacrifica token apenas quando os 2 manas destravam payoff real no mesmo precombat main, emite replay event e decision trace. | Ampliar a mesma família para outros permanentes recorrentes somente quando houver metadata confiável e cenário focado. | Slice mínimo fechado para `sacrifice_creature -> add mana`; próximos fechamentos exigem novo teste por família de habilidade, sem combo engine genérica. |
| P1 | Battle | Multi-row real em `card_battle_rules` | Infra pronta; PostgreSQL ainda com `multi_rule_card_count = 0`. | Persistir 3-5 cartas reais com escopos distintos: `spell_resolution`, `activated_ability`, `trigger_resolution`, `cost_annotation` ou `static_layer`. | Auditor multi-rule reencontra casos reais no PG e o runtime seleciona por escopo, não por nome cru. |
| P1 | Generator | Política explícita de precedência do builder | Em 2026-06-19 a política foi explicitada em código/diagnostics como `active_learned_deck -> reference_card_stats -> reference_corpus_packages -> profile_expected_packages -> usage_hot_cards -> deterministic_fallback`. | Manter a constante `deterministicReferenceDeckSourcePrecedence` como fonte de verdade e exigir que auditores/provenance usem o diagnostics em vez de texto histórico. | Geração, provenance audit e docs convergem para a mesma política declarada; qualquer mudança futura precisa atualizar teste e docs. |
| P1 | Optimize | Quality gate profile-aware | Em 2026-06-19 o gate de optimize deixou de depender apenas de buckets por arquétipo: `role_targets` do commander reference profile agora alimenta papéis críticos e range de lands. Para Lorehold, isso preserva engines/topdeck/copy/payoffs e evita trim de lands dentro do range 36-38. | Rodar corpus maior de optimize para medir falsos positivos/negativos por comandante e enriquecer diagnostics seguros de bloqueio. | Swaps aprovados não podem perder papéis declarados no profile nem cortar lands abaixo do range do comandante quando o profile existir; quando não existir, o comportamento archetype-only continua compatível. |
| P1 | Generator | Curar `fallback_without_profile_or_stats` do Lorehold | Bucket factual live5: 9 cartas; live pós-backfill v2: 0. | Fechado em 2026-06-19 com profile/stats aplicados no PostgreSQL e rerun source-mix. | Manter teste de regressão para as 12 staples/interações incorporadas. |
| P1 | Generator | Curar `learned_plus_fallback_only` do Lorehold | Bucket factual live5: 2 cartas (`Fellwar Stone`, `Lightning Greaves`); live pós-backfill v2: 0. | Fechado em 2026-06-19 via `mana_ramp_foundation` e `protection_and_equipment`. | Próximos reruns não podem voltar a listar learned+fallback-only. |
| P1 | Generator | Revisar `fallback_profile_stats_no_empirical_support` | Bucket factual live5: 18 cartas; live pós-backfill v2: 0; live v4 com provenance runtime: `fallback_touched_count=0`. | Fechado em 2026-06-19 porque fallback só é rotulado quando realmente introduz carta. | Manter auditor usando provenance runtime real, não reclassificação por lista fallback estática. |
| P1 | Lorehold | Revalidar o pacote de miracle/topdeck do comandante | A auditoria `LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md` confirmou que o generator já puxa `Top`, `Rack`, `Brainstone`, `Mikokoro` e `Library of Leng`. O runtime e o snapshot canônico já modelam rummage/topdeck parcialmente; em 2026-06-19 o fallback legado `known_cards_generated.json` também foi alinhado para não recriar `Library of Leng`/`Scroll Rack`/`Top` como ramp ou draw genérico. O sub-slice de trace fechou `Approach + Brainstone/Top/Rack` como decisão auditável, e os sub-slices seguintes fecharam replay real de `Sensei's Divining Top`, `Scroll Rack` e `Brainstone` preparando/comprando `Approach`, miracle e segunda resolução vencendo a partida. | Próximo foco: transformar as capabilities de topo em policy mais genérica fora do caminho seguro acoplado ao Lorehold, sem inventar hard executor inseguro para outros comandantes. | O deck final continua alinhado a `miracle/topdeck/spellslinger`, e o battle rastreia miracle/topdeck lines sem ambiguidade crítica nem carta-chave mal classificada. |
| P1 | Lorehold | Validar aprendizado só com corpus confiável | O Lorehold já é deck de controle válido, mas ainda tem 42 cartas tocadas por fallback e coverage parcial dos oponentes. | Tratar o deck como caso de controle, não como “melhor deck final” até fechar os buckets P1 e melhorar o scorecard. | Novo relatório Lorehold classificado como `trusted`, `needs_more_samples` ou `blocked`, com justificativa reproduzível. |
| P2 | Battle | Melhorar mulligan bottoming por plano do deck | Mulligan já é melhor que land-count-only, mas o bottom ainda é simples. | Bottom por função: preservar lands necessárias, early plays, ramp e plano do comandante; mandar high-cost dead cards primeiro. | Testes de mãos pesadas/curvas ruins passam com justificativa mais rica no trace. |
| P2 | Battle | Refinar utility lands remanescentes só se impactarem aprendizado | Lorehold hoje tem 9 cartas de risco médio, quase todas utility lands já parcialmente tratadas. | Não abrir frente ampla de lands; atacar apenas se os auditores mostrarem impacto real em replay/learning. | Redução de medium-risk por evidência, não por perfeccionismo especulativo. |
| P2 | Process | Reexecutar relatórios Hermes stale antes de abrir task | A branch `origin/codex/hermes-analysis-docs` está atrás do `master` local nas frentes battle/generator/Lorehold. | Reaproveitar relatório Hermes antigo só depois de rerun em cima do hash atual. | Nenhuma task nova fica ancorada apenas em doc Hermes histórico. |

## Ordem recomendada

### Fase 1 — Battle confiável para aprendizagem

1. `decision_trace_v1` comparativo
2. replay textual auditável e coerente com JSONL
3. executor genérico de activated abilities recorrentes
4. scorecard Commander-safe
5. primeiro lote multi-row real em `card_battle_rules`

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
