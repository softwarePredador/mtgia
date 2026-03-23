# Documentação Ativa

Este diretório concentra a documentação que ainda orienta decisão e execução.

## Ordem de leitura

1. [CONTEXTO_PRODUTO_ATUAL.md](CONTEXTO_PRODUTO_ATUAL.md)
2. [MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md](MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md)
3. [CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md](CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md)
4. [AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md](AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md)

## O que cada documento faz

### Fonte de verdade operacional

- [CONTEXTO_PRODUTO_ATUAL.md](CONTEXTO_PRODUTO_ATUAL.md)
  - prioridade atual
  - regras de decisão
  - escopo permitido e bloqueado
  - próximos passos oficiais do core

### Validação e qualidade

- [MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md](MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md)
  - mapa da cobertura da otimização
  - quais suites sustentam confiança real
  - o que ainda falta endurecer

- [CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md](CONTRATO_OPTIMIZE_REBUILD_2026-03-23.md)
  - contrato funcional do fluxo optimize -> rebuild -> validate
  - payloads esperados de sucesso, warning e erro
  - regras mínimas de compatibilidade entre backend e app

- [AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md](AUDITORIA_UX_LOGICA_PERFORMANCE_2026-03-23.md)
  - leitura consolidada de produto
  - riscos de UX, lógica e performance
  - recomendações de priorização

- [../server/doc/RESOLUTION_CORPUS_WORKFLOW.md](../server/doc/RESOLUTION_CORPUS_WORKFLOW.md)
  - operacao do corpus estavel Commander
  - gate recorrente de release do fluxo optimize -> rebuild -> validate

## Documentos complementares

Esses documentos continuam úteis, mas não definem a prioridade principal sozinhos:

- [../ROADMAP.md](../ROADMAP.md)
- [../CHECKLIST_GO_LIVE_FINAL.md](../CHECKLIST_GO_LIVE_FINAL.md)
- [../CHECKLIST_EXECUCAO.md](../CHECKLIST_EXECUCAO.md)
- [PLANO_SPRINTS_EXECUCAO_MTGIA_2026-03-23.md](PLANO_SPRINTS_EXECUCAO_MTGIA_2026-03-23.md)
- [PLANO_ABSORCAO_OPERACIONAL_REDIS_SENTRY_EASYPANEL_2026-03-23.md](PLANO_ABSORCAO_OPERACIONAL_REDIS_SENTRY_EASYPANEL_2026-03-23.md)
- [../server/manual-de-instrucao.md](../server/manual-de-instrucao.md)
- [../server/doc/RESOLUTION_CORPUS_WORKFLOW.md](../server/doc/RESOLUTION_CORPUS_WORKFLOW.md)
- [../server/doc/OPTIMIZATION_RESOLUTION_HANDOFF_2026-03-18.md](../server/doc/OPTIMIZATION_RESOLUTION_HANDOFF_2026-03-18.md)
- [../app/doc/COMMANDER_PRODUCT_ROADMAP_2026-03-18.md](../app/doc/COMMANDER_PRODUCT_ROADMAP_2026-03-18.md)
- [../app/doc/COMMANDER_EXECUTION_TRACKER_2026-03-18.md](../app/doc/COMMANDER_EXECUTION_TRACKER_2026-03-18.md)
- [../app/doc/DESIGN_COLOR_LAYOUT_AUDIT_2026-03-18.md](../app/doc/DESIGN_COLOR_LAYOUT_AUDIT_2026-03-18.md)
- [../app/doc/THEME_SYSTEM_ABSORPTION_PLAN_2026-03-23.md](../app/doc/THEME_SYSTEM_ABSORPTION_PLAN_2026-03-23.md)

## Documentos históricos

Documentos arquivados ou superados ficam em:

- `archive_docs/`

Relatórios pontuais de rodada continuam no root para consulta, mas devem ser lidos como histórico de execução, não como prioridade atual.
