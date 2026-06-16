# Hermes Analysis Docs — leitura canonica

> Status atual: canonico.
> Esta e a porta de entrada para decidir quais docs ler e quais ignorar em
> tarefas Hermes.

Updated: 2026-06-15

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

- `HERMES_DOCS_BRANCH_SYNC_CRON_2026-06-13.md`
  - Guardrail novo para auditorias Hermes na branch
    `codex/hermes-analysis-docs`.
  - Define a cron `manaloom-docs-branch-sync`, que deve mergear
    `origin/master` na branch docs antes de qualquer auditoria publicar achados
    sobre código vivo.
  - Use quando uma auditoria de docs/estrutura parecer stale ou antes de
    reativar crons como code-structure, normal-audit, weekly-audit ou
    logic-coherence.

- `HERMES_CRON_VALUE_AND_MIGRATION_AUDIT_2026-06-11.md`
  - Auditoria uma a uma das crons Hermes, com decisão de manter/pausar e plano
  para migrar o loop para o servidor ManaLoom.
  - Atualizado com a primeira rodada real pós-ajuste: watchdog OK, falha de
    ownership SQLite corrigida e sync de target deck com duplicatas tratado.

- `BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
  - Mapa detalhado da lógica atual de battle simulator, geração IA,
    otimização, Hermes e Lorehold.
  - Use para comparar novos planos de implementação antes de alterar
    `IMPLEMENTATION_GAPS.md` ou código.

- `BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
  - Plano de implementação faseado para agregação multi-função, snapshot
    Hermes, tags funcionais, `card_battle_rules`, learned decks e validação.
  - Use como checklist técnico antes de alterar schema, sync ou consumidores
    Hermes.

- `BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
  - Evidência da implementação local do primeiro slice: agregação por
    `card_id`, arrays JSON, hashes, testes anti-fanout e validação Lorehold em
    SQLite temporário.
  - Também registra o bridge de `master_optimizer_common.py` e
    `slot_optimizer.py` para ler `functional_tags_json`.
  - Use antes de avançar para validadores/report-only crons restantes ou apply
    no Hermes real.

- `BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md`
  - Lista de dúvidas, decisões de produto, logística e políticas que precisam
  de validação do owner antes das próximas fases.
  - Use quando uma alteração depender de regra de negócio e não só de código.

- `BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`
  - Handoff direto para o owner responder dúvidas, furos, logística e ideias
    antes das próximas fases de battle/IA/Hermes.
  - Use para separar o que já pode ser implementado dos pontos que ainda
    precisam de validação explícita.

- `HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`
  - Classifica scripts que ainda mencionam `functional_tag` como ativos,
    indiretos, manuais/importers ou históricos/pausados.
  - Use antes de aplicar o snapshot agregado no Hermes runtime real.

- `HERMES_DOCS_TRIAGE_2026-06-11.md`
  - Triagem curada dos commits `13a10128`, `372cdfca` e `76ec897f` da branch
    `codex/hermes-analysis-docs`.
  - Use antes de abrir tarefas a partir de `PLANO_CORRECAO.md`,
    `STRUCTURE_AUDIT.md` ou `TECHNICAL_MAP.md`.
  - Nao fazer merge bruto desses relatórios na `master` sem revalidar contra o
    código vivo.

- `DECISION_TRACE_V1_SLICE_2026-06-15.md`
  - Slice Hermes-only que adiciona `decision_trace_v1` aos replays de battle.
  - Use para auditar por que o simulador escolheu cast/resposta/ataque/pass
    antes de confiar em WR bruto ou sugerir swaps Lorehold.
  - Nao altera app/API/PostgreSQL; persistencia atual e JSON/MD.

- `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`
  - Complementa o trace com auditoria estrategica: mulligan, Lotus Petal,
    Mox Diamond, sacrificio de land, tutor, board wipe/wheel,
    removal/counter/protection, combate e pass/no-action.
  - Use para diferenciar jogada legal de jogada estrategicamente defensavel.
  - Estado atual: todas as categorias ficaram `coherent_in_sample` na rodada
    `20260615_172608`; ainda falta corpus maior para tratar isso como
    heuristica final.
  - Fontes de comunidade/artigos calibram heuristica; comportamento duro ainda
    exige regra oficial, replay e teste focado.

- `INFORMATION_BANK_DIAGNOSTIC_2026-06-15.md`
  - Diagnóstico do banco de informações do produto: PostgreSQL, SQLite Hermes,
    tags funcionais, semantic v2, battle rules, learned decks, Commander
    Reference, telemetria de IA/optimize e price history.
  - Use antes de criar novos pipelines de IA/battle para evitar fanout, fonte
    duplicada ou aprendizado a partir de tabela incompleta.
  - Recomendação central: criar snapshot agregado por `card_id` e bridge de
    identidade antes de promover novos sinais para lógica app-facing.

- `DATA_AND_CRON_HEALTH_AUDIT_2026-06-16.md`
  - Validação source-backed do preenchimento de dados e da efetividade das
    crons locais/Hermes AWS.
  - Confirma que PostgreSQL/views criticas estao coerentes, candidate quality e
    meta signals geram dados uteis, e o principal risco segue sendo join direto
    de deck com fontes multi-linha.
  - Use para decidir proximos applies controlados: candidate quality, auto
    promote learned decks e metricas de decision impact.

- `BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md`
  - Status pos-correcao da auditoria de battle: 16 seeds, 17069 eventos,
    2301 decision traces, 0 high/critical, 0 strategy blockers e apenas
    3 findings low `review_rule_used`.
  - Use para responder se cada etapa/jogada esta sendo auditada e quais gaps
    reais ainda impedem usar WR bruto como aprendizado forte.

- `BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md`
  - Consolidacao canônica do estado real do battle simulator, do generator e do
    caso Lorehold.
  - Use quando a pergunta for "o que ja esta suficientemente certo?" versus
    "o que ainda precisa virar dado util para criacao/optimize?".
  - Mantem a separacao entre laboratorio auditavel, fallback curado e verdade
    de produto/backend.

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

3. `BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
   - Explica a divisao entre simulador leve do backend, battle analyzer Hermes,
     generate/optimize app-facing e pipeline Lorehold learned deck.
   - Use como mapa atual antes de propor migracao Hermes -> backend.

4. `BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
   - Transforma o deep dive e as validações externas em plano executável.
   - Use como ordem padrão para implementar agregação por `card_id`, snapshot
     Hermes e consumidores set-based.

5. `BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
   - Evidência fresca de Slice 1 implementado localmente e validado, incluindo
     bridge do optimizer para arrays semânticos.
   - Use como baseline antes de aplicar no Hermes real ou migrar
     validadores/report-only crons restantes.

6. `BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md`
   - Perguntas e políticas pendentes para o owner validar.
   - Use antes de transformar heurística/cron/Hermes em comportamento de
     produção.

7. `BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`
   - Lista objetiva de perguntas, furos e decisões logísticas a retornar para
     Codex antes de promover comportamento novo.

8. `HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`
   - Inventário dos consumidores Hermes de `functional_tag` e quais já foram
     migrados para `functional_tags_json`.

9. `DECISION_TRACE_V1_SLICE_2026-06-15.md`
   - Contrato inicial de rastreabilidade de decisoes do battle.
   - Use antes de tratar WR alto como evidencia confiavel.

10. `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`
   - Matriz oficial de estrategia versus legalidade para decisoes do simulador.
   - Use antes de implementar mulligan, fast mana, tutor, removal, wipe,
     combate ou pass/no-action como heuristica dura.

11. `HERMES_CRON_PIPELINE_ORDER_2026-06-07.md`
   - Snapshot da ordem e estado das crons.
   - Use para entender a frota atual, mas valide contra `/opt/data/cron/jobs.json`
     e artefatos frescos no container.

12. `master_optimizer_reports/`
   - Evidencias de execucoes.
   - Use sempre o report mais fresco que bate com `baseline_id`, `baseline_hash`
     e o SQLite vivo.

13. `HERMES_DOCS_VALIDATION_MATRIX_2026-06-07.md`
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
