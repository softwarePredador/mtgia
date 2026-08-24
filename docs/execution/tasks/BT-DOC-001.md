# Ficha de execução — `BT-DOC-001`

> Ledger não autoritativo. A linha do backlog/registry define a task.

## Autoridade

- Task ID: `BT-DOC-001`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `1`
- Registry `generated_from.sha256`: `baed1f2b2ccd0cbc9620fa073d13311d5a8354513d2222a324881ca70d003016`
- Project logic baseline na abertura:
  `44ab0563e6703bad2d1a8a47128d318d88401c050fb98b07d38a3b2a299ab042`
- Dependência `BT-GOV-001`: `PASS`

## Identidade da execução

- Owner: `/root`
- Início UTC reconciliado com o fechamento do predecessor:
  `2026-08-24T16:38:30Z`
- Fim UTC: `pending`
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Git SHA inicial: `b09ac6dbb6b88f2ea235404431049609da3215ff`
- Git SHA final: `pending`
- Estado canônico: `IN_PROGRESS_CONTAINED`
- Autorização máxima nesta abertura: documentação/tooling local e commits
  atômicos locais; nenhuma mutação live, push, deploy, migration ou promoção

## Resultado esperado

Reconciliar documentos ativos e históricos para que decisão, contratos e
runbooks correntes tenham precedência inequívoca. Planos, relatórios antigos e
material Hermes/SQLite devem permanecer consultáveis sem aparentar autoridade
operacional ou autorização de comandos mutantes.

## Escopo inicial

- inventariar documentos canônicos, históricos, generated e overrides;
- validar lifecycle, links e comandos contra `project_logic_contracts.json`;
- colocar READMEs, instruções e perfis `.github` sob policy e lineage;
- impedir que agentes ativos herdem push/deploy/DML ou autoridade histórica;
- classificar vídeos derivados sem promovê-los a prova E2E;
- confirmar que mapas Deck/IA apontam PostgreSQL/backend como verdade e Hermes
  apenas como cache/laboratório;
- corrigir somente classificação, precedência e referências documentais;
- regenerar os nove artefatos de project logic e produzir receipt durável.

Fora do escopo: código funcional, migrations, banco live, Hermes/SQLite,
capabilities, decks, regras, pins externos, runtime, deploy, commit ou push de
outra task.

## Plano de prova

1. inventário determinístico sem fonte histórica ativa;
2. negativos para lifecycle ausente, override inválido e comando mutante em
   documento histórico;
3. `project_logic --write` e `--check` sem drift;
4. secret scan, link/route consumers e `diff --check`;
5. auditoria do índice e receipt antes de qualquer `PASS`.

## Checkpoint de execução

- As três auditorias independentes foram concluídas sem subagentes aninhados;
  o limite efetivo solicitado pelo usuário foi `3`.
- Um delta Battle concorrente foi preservado separadamente no commit local
  `243ca57fe`, branch `codex/battle-e2e-handoff-2026-08-24`, com
  `NO_TASK_CLOSURE`; ele não pertence a esta task nem altera seu aceite.
- A implementação de `BT-DOC-001` está em andamento somente na branch desta
  ficha.
- `BT-GOV-001` fechou localmente em `PASS`; produção permanece `SERVER_BEHIND`
  na última observação read-only e nenhum deploy foi autorizado.
- WIP permanece `1`; nenhuma outra task funcional está aberta.

## Fechamento

- Resultado: `IN_PROGRESS_CONTAINED`
- Gate-eligible: `false`
- Bloqueios: nenhum para iniciar a auditoria documental
- Commit final: `pending`
