# Hermes Analysis Docs — leitura canonica

> Status atual: canonico.
> Esta e a porta de entrada para decidir quais docs ler e quais ignorar em
> tarefas Hermes.

Updated: 2026-06-11

Esta pasta mistura contrato operacional, historico de auditoria, relatorios de
rodadas e memorias antigas. Para evitar confusao, use esta ordem de leitura.

## Triagens recentes

- `BRANCH_RETENTION_AUDIT_2026-06-11.md`
  - Politica de retencao de branches: manter somente `master` e
    `codex/hermes-analysis-docs`.
  - Define `master` como fonte canonica e `codex/hermes-analysis-docs` como
    fila/staging Hermes, sem merge bruto para `master`.

- `CODEX_HERMES_COLLABORATION_PROTOCOL_2026-06-11.md`
  - Contrato operacional entre Codex local e Hermes/AWS.
  - Use para decidir quando Hermes pode escrever docs, quando Codex deve chamar
    report-only e como transformar achados Hermes em tarefas reais.

- `HERMES_RUNTIME_CRON_ALIGNMENT_2026-06-11.md`
  - Snapshot do runtime AWS depois do prune de branches e ajuste das crons.
  - Registra jobs habilitados/pausados, scripts alterados e validações feitas.

- `HERMES_CRON_VALUE_AND_MIGRATION_AUDIT_2026-06-11.md`
  - Auditoria uma a uma das crons Hermes, com decisão de manter/pausar e plano
    para migrar o loop para o servidor ManaLoom.

- `HERMES_DOCS_TRIAGE_2026-06-11.md`
  - Triagem curada dos commits `13a10128`, `372cdfca` e `76ec897f` da branch
    `codex/hermes-analysis-docs`.
  - Use antes de abrir tarefas a partir de `PLANO_CORRECAO.md`,
    `STRUCTURE_AUDIT.md` ou `TECHNICAL_MAP.md`.
  - Nao fazer merge bruto desses relatórios na `master` sem revalidar contra o
    código vivo.

## Fonte de verdade atual

1. `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md`
   - Contrato operacional ponta a ponta.
   - Use para saber quais bancos, tabelas, scripts, parametros, guardrails e
     comandos devem ser usados.
   - Este e o documento principal para agentes.

2. `HERMES_MASTER_OPTIMIZER_LOOP_2026-06-06.md`
   - Diario tecnico/evidencial do battle + optimizer.
   - Use para entender decisoes recentes, aplicacoes bloqueadas, revalidacoes e
     estado atual do Lorehold.
   - Nao use sozinho como autorizacao de apply.

3. `HERMES_CRON_PIPELINE_ORDER_2026-06-07.md`
   - Snapshot da ordem e estado das crons.
   - Use para entender a frota atual, mas valide contra `/opt/data/cron/jobs.json`
     e artefatos frescos no container.

4. `master_optimizer_reports/`
   - Evidencias de execucoes.
   - Use sempre o report mais fresco que bate com `baseline_id`, `baseline_hash`
     e o SQLite vivo.

5. `HERMES_DOCS_VALIDATION_MATRIX_2026-06-07.md`
   - Classificacao de todos os docs raiz desta pasta.
   - Use para saber se um arquivo e canonico, operacional, historico ou backlog.

## Historico util, mas nao operacional

Estes arquivos podem explicar por que algo foi criado, mas nao devem guiar
execucao atual sem cruzar com o contrato E2E:

- `HERMES_CRON_GOVERNANCE_REPORT.md`
- `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md`
- `AUDIT_REPORT_2026-05-27.md`
- `AUDIT_REPORT_2026-05-30.md`
- `AUDIT_REPORT_2026-05-31.md`
- `COMMIT_DIGEST.md`
- `PROJECT_MEMORY.md`

## Docs gerais fora do Hermes runtime

Estes documentos falam do app/backend/produto em geral. Nao use para decidir
swaps, crons ou battle Hermes:

- `TECHNICAL_MAP.md`
- `STRUCTURE_AUDIT.md`
- `IMPLEMENTATION_TASKS.md`
- `PLANO_CORRECAO.md`
- `BACKEND_ACTIONABLE_TASKS.md`
- `FLUTTER_UI_AUDIT.md`
- `UI_ACTIONABLE_TASKS.md`
- `LOGIC_COHERENCE_REPORT_2026-05-29.md`
- `LOGIC_COHERENCE_REPORT_2026-05-29_E2E.md`
- `OPEN_RISKS.md`
- `PRODUCT_DIRECTION.md`
- `modules_coherence.md`

## Politica de exclusao

Nao deletar relatorios historicos que tenham evidencias de baseline, hash, apply,
rollback, provider, cron ou replay. Eles sao memoria auditavel.

Se uma doc antiga estiver confundindo agentes:

- prefira adicionar aviso de snapshot/historico no topo;
- ou mover para uma pasta de arquivo morto em uma PR separada;
- so delete se nao houver referencia, evidencia unica ou valor de auditoria.

## Furos adicionais identificados nesta organizacao

- `HERMES_CRON_GOVERNANCE_REPORT.md` e snapshot de 2026-06-05 e nao reflete a
  frota atual de 23 jobs.
- `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md` ainda descreve crons Lorehold antigas
  e uma politica de frequencia que nao e mais o contrato atual.
- `HERMES_CRON_PIPELINE_ORDER_2026-06-07.md` e util, mas parte dele foi
  superada pelo contrato E2E depois que `master_optimizer_end_to_end.sh` passou a
  executar slot scan.
- `STRUCTURE_AUDIT.md` e muito grande e pode contaminar contexto de agentes; use
  apenas quando a tarefa for auditoria estrutural ampla.
