# Ficha de execução — `BT-DOC-001`

> Ledger não autoritativo. A linha do backlog/registry define a task.

## Autoridade

- Task ID: `BT-DOC-001`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `1`
- Registry `generated_from.sha256` de fechamento:
  `5109f0e0e5585c2c6ce3655514d2f8a5f38331105f6a6471ee9069e520d25864`
- Project logic baseline na abertura:
  `44ab0563e6703bad2d1a8a47128d318d88401c050fb98b07d38a3b2a299ab042`
- Dependência `BT-GOV-001`: `PASS`

## Identidade da execução

- Owner: `/root`
- Início UTC reconciliado com o fechamento do predecessor:
  `2026-08-24T16:38:30Z`
- Fim UTC: `2026-08-24T19:43:25Z`
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Git SHA inicial: `b09ac6dbb6b88f2ea235404431049609da3215ff`
- Git SHA final da implementação:
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`
- Project logic digest da implementação:
  `be3bf02dba40befead607ba4f34a55595e1322ef9dc1a7bccc6396b1ccac9cee`
- Project logic digest de fechamento:
  `c1ddf67874b4861c9736cd64c5519887a3e59106e9658f12276a6905d9387a96`
- Estado canônico: `PASS`
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
- A implementação de `BT-DOC-001` foi commitada atomicamente em `c6e2725af`.
- `BT-GOV-001` fechou localmente em `PASS`; produção permanece `SERVER_BEHIND`
  na última observação read-only e nenhum deploy foi autorizado.
- WIP permanece `1`; nenhuma outra task funcional está aberta.

## Gates e evidência

| Gate | Resultado |
| --- | --- |
| `project_logic --write/--check` | `PASS`; 9 artefatos sincronizados |
| `quality_gate project-logic` | `PASS`; 23/23 testes, incluindo histórico mutante sem banner fail-closed, e `dart doc` sem warnings/erros |
| `manaloom_local_ci quick` | `PASS` no hook normal do commit de implementação |
| `quality_gate report-retention` | `PASS`; 17/17 testes |
| secret scan | `PASS`; zero credencial live literal, gitleaks 8.30.1 |
| semantic analysis | `PASS`; 684/684 fontes, zero arquivo com diagnóstico de erro |
| `diff --check` e JSON parse | `PASS` |
| auditoria independente | `GO` após corrigir o `NO-GO` inicial dos planos Battle históricos |

Receipt durável:
`docs/qa/execution/2026-08-24/BT-DOC-001.md`.

## Fechamento

- Resultado: `PASS_LOCAL · COMMITTED · NOT_PUSHED`
- Gate-eligible: `true` para fechamento local; não autoriza release/deploy
- UI/runtime/PG/live: não aplicável ao delta documental/tooling; nenhuma nova
  prova funcional foi reivindicada
- Bloqueios locais: nenhum
- Riscos residuais: proteção remota de PR, receipt forte e rastreabilidade
  completa continuam em tasks próprias; não foram convertidos em aceite aqui
- Rollback: reverter `c6e2725af`, regenerar os nove artefatos e executar os
  mesmos gates; não há estado live para restaurar
- Auditor independente: `GO`
- Commit de implementação:
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`
- Commit de fechamento: commit posterior a `c6e2725af`; SHA comunicado no
  handoff para evitar autorreferência
- Próximo ID elegível: `BT-DOC-004`
