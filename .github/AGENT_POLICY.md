# ManaLoom/BrewTact — política canônica para agentes

Status: `CURRENT_CONTRACT · MANALOOM_AGENT_POLICY_V1 · WIP_LIMIT_1`

Esta política governa todo perfil ou instrução sob `.github/`. Perfis de domínio
ajudam a executar um escopo; eles não alteram prioridade, autorização ou fonte
de verdade.

## Autoridade obrigatória

Antes de analisar, editar ou executar comandos:

1. ler `AGENTS.md`;
2. ler `docs/status/CURRENT_PRODUCT_DECISION.md`;
3. resolver o único Task ID ativo em
   `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`,
   `docs/generated/TASK_REGISTRY.json` e `docs/execution/CURRENT_QUEUE.md`;
4. ler `docs/generated/CURRENT_SYSTEM.md`, o contrato da área e
   `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`;
5. consultar `semantic_analysis` e `lineage` antes de alterar uma fonte.

Em divergência, decisão corrente e backlog mestre prevalecem. Fila, task
packet, receipt, perfil de agente, relatório, plano antigo e documentação
histórica não podem redefinir prioridade ou aceite.

## Execução e concorrência

- Existe um único Task ID `NOW` por checkout.
- Um agente escritor possui o conjunto exato de arquivos da task. Revisores
  atuam em leitura ou em worktree isolado.
- Não iniciar outra implementação enquanto o pacote atual estiver sujo ou sem
  handoff atômico.
- Respeitar qualquer limite de subagentes imposto pelo usuário; um subagente
  não cria descendentes quando isso estiver proibido.
- Preservar mudanças preexistentes e nunca limpar, reverter ou incorporar
  trabalho alheio por conveniência.

## Fronteiras de autoridade

- Nenhum perfil autoriza commit, push, merge, deploy, migration live, DML live,
  mudança de capability, pin, regra ou deck. Essas ações exigem autorização
  explícita e separada quando aplicáveis.
- PostgreSQL/backend é a verdade de produto. Hermes/SQLite é cache,
  laboratório ou evidência.
- XMage é a fonte executável primária pinada; Forge cobre gaps estruturados.
  Execução externa nunca promove automaticamente regra nativa, deck ou
  aprendizado.
- Capabilities permanecem default-deny. Teste, relatório, screenshot ou
  receipt local não abre superfície pública.
- Segredos, credenciais, PII e payloads live não entram em logs, fixtures,
  documentação ou commits.

## Fontes, gerados e documentação

- Editar somente fontes. `project_logic_manifest.json` e `docs/generated/*`
  são regenerados pela ferramenta oficial.
- Contratos registram política; ADRs registram motivos; receipts registram
  evidência; relatórios datados permanecem históricos.
- Um comando encontrado em material histórico é exemplo não autoritativo.
- Depois de alterar fonte, contrato, script ou gate, executar
  `./scripts/manaloom_project_logic.sh --write` e `--check`.

## Prova e handoff

- Executar testes positivos e negativos proporcionais ao risco; registrar
  `SKIP`, `PARTIAL`, `BLOCKED` e `FAIL` sem convertê-los em sucesso.
- UI app-facing exige os três níveis do contrato de prova viva no mesmo digest.
- O handoff lista Task ID, arquivos, gates, receipts, SHA/digest, skips,
  rollback, riscos residuais e ações deliberadamente não executadas.
