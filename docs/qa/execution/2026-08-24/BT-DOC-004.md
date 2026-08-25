# Receipt de execução — `BT-DOC-004`

Status: `PASS_LOCAL · IMPLEMENTATION_COMMITTED · PUSH_PENDING`

Este receipt prova o fechamento local de `BT-DOC-004` no SHA de implementação
abaixo. O snapshot de Git desta evidência é anterior ao push de fechamento. Ele
não autoriza PR, merge, deploy, migration ou DML live, capability `ON`,
atualização de pin, promoção de deck/regra ou alteração de runtime.

## Identidade

- Branch: `codex/free-beta-release-candidate-2026-07-17`
- SHA inicial:
  `c1bd186633a479f62eae0ba4db6eb29463e94419`
- SHA final da implementação:
  `d9f7a59cd87d032df3d076c35ffbdb17e41525a6`
- Commit de fechamento: posterior ao SHA de implementação; comunicado no
  handoff para evitar autorreferência
- Upstream observado na implementação:
  `c1bd186633a479f62eae0ba4db6eb29463e94419`
- Relação observada: `ahead_by=1`, `behind_by=0`, `NOT_PUSHED`
- Project logic digest da implementação:
  `bf7704ee33c99009bc878962409654df0af63d244c1b52c10eccc7aa674c80e0`
- Project logic digest de fechamento:
  `abf4957c7646a4189edc833a02eb343fe32b283e8a7cfe409ff993d706557fe9`
- Manifest SHA-256 da implementação:
  `624610e83e30d2011e20311fccc32dfee95be981a376874d8f14899a12668f9b`
- Manifest SHA-256 de fechamento:
  `d1ca14ed775e4626cd791108e1a8320e1f85920a971e00a463d90127cab4e38d`
- Registry source SHA-256 de fechamento:
  `0ce0be74f84bd5e8eb25568601a4ce47f46a24dd6766dba67393caadd8f62abd`
- Registry gerado SHA-256 de fechamento:
  `5c70be25a8577481cf56abc22a4a47e8b63fd233ca4e72660541c61afa727793`
- Registry JSON canônico standalone/embedded:
  `ae21e9f61be06d36f1a3f3b9c2a14c621aa3bf905823f04057fd58530ed3002b`
- Fila operacional SHA-256 de fechamento:
  `01a7b56ab0cbbf82cfd1b2538b14da3fc5aa1dc5c948bd2d1e3b08e3c7b05d7d`
- Registry schema: `2`
- Generator: `manaloom_project_logic 1.5.0`
- Início UTC: `2026-08-24T19:43:25Z`
- Gate `full` encerrado em: `2026-08-24T21:12:20Z`
- Fechamento documental retomado em: `2026-08-25T11:40:24Z`
- Autorização usada: código/tooling/documentação local, commits e push da
  branch; nenhum PR/merge, deploy, mutation live ou capability

## Resultado

- O parser backlog → registry passou a rejeitar IDs inválidos/duplicados,
  dependências ausentes/duplicadas/próprias, ciclos, placeholders inequívocos e
  definições fora da tabela canônica.
- A fila exige WIP máximo 1, exatamente um `NOW`, ficha correspondente com ID,
  banner não autoritativo e autorização explícita, além de dependências `PASS`
  ou exceção estruturada `IN_PROGRESS_CONTAINED`.
- O schema do registry foi elevado para `2`; os campos honestos
  `flow_producers` e `flow_consumers` deixam explícita a granularidade por fluxo
  e incluem scripts entre os produtores.
- O lifecycle de fila/fichas permanece ledger auxiliar e não altera prioridade,
  estado, dependências, entrega ou aceite canônicos.
- `project_logic_manifest_v1` agora exige binding explícito
  `source_digest_sha256`, tornando o receipt do manifesto verificável contra o
  digest da revisão.
- O generator ficou em `1.5.0`, com 27 testes determinísticos e nove artefatos
  oficiais sincronizados.
- Nenhum arquivo funcional de produto, policy de capability, banco, deck,
  regra, pin externo, runtime ou deploy foi alterado.

## Evidência

| Camada | Resultado no SHA `d9f7a59cd87d032df3d076c35ffbdb17e41525a6` |
| --- | --- |
| Project logic | `PASS`; 27/27 testes, 9 artefatos sincronizados e `dart doc` limpo em 4 módulos |
| Registry | schema `2`; 217 tasks, 393 arestas; JSON standalone e embedded canonicamente iguais |
| Determinismo | `PASS`; ordenação, digest e projeção repetida cobertos |
| Negativos | `PASS`; IDs, dependências, ciclo, placeholders, WIP/NOW/ficha, lifecycle, rotas e receipt fail-closed |
| Gate `full` | `PASS`; 124 auditorias determinísticas e 32 contratos de release |
| Backend | `PASS`; todos os batches completos |
| App | `PASS`; analyzer sem issues, 1.564 testes Flutter e 1 skip explícito de ambiente |
| Web pública | `PASS`; lint, build, smoke e zero vulnerabilidade reportada |
| Performance/UI/lint | `PASS`; harness 17, UI audit 59, custom lint app/backend/package |
| UI preexistente | `PASS_AUTOMATED`, `PASS_RUNTIME`, `PASS_VISUAL_REVIEWED`; 456 capturas no digest `d517adb65b…`; nenhuma aprovação nova reivindicada |
| Patrol | `PASS`; 9/9 no harness local; CLI de device não executada porque o ambiente não foi configurado |
| PostgreSQL descartável | `PASS`; 79 tabelas, 6 views, 98 FKs e 58 migrations; cluster loopback removido |
| Retenção | `PASS`; 17/17 testes |
| Segredos | `PASS`; zero credencial live literal e gitleaks `8.30.1` |
| Estrutura | `PASS`; `git diff --check` e JSON parse |
| Auditoria independente | `GO` após resolver os quatro gaps iniciais e os achados adicionais de schema, scripts e normalização |
| Regeneração de fechamento | `PASS`; 9 artefatos oficiais sincronizados, digest `abf4957c7646…`, único `NOW=BT-SCP-001`, ficha validada e dependência `BT-GOV-001=PASS` |
| Gate focal de fechamento | `PASS`; 27/27 e `dart doc` limpo nos 4 módulos após generalizar o teste do slot corrente |

Durante o desenvolvimento, o negativo com `???`/`...` detectou uma regressão
na normalização (26/27). Ela foi corrigida antes do commit; o SHA de
implementação contém somente o resultado final 27/27 e passou no gate amplo.

Na transição da fila, o primeiro gate focal de fechamento também falhou de
forma útil: um teste de integração ainda fixava literalmente
`NOW=BT-DOC-004`. O fechamento substituiu esse snapshot frágil por invariantes
que resolvem o ID corrente no registry, conferem sua ficha, estado canônico e
dependency gate. A segunda rodada fechou em 27/27. O `full` desse commit de
fechamento é responsabilidade do pre-push normal e ainda estava pendente neste
snapshot do receipt.

## Aceite canônico

| Cláusula | Evidência |
| --- | --- |
| IDs únicos e dependências resolvidas | parser, DAG, negativos focais e dependency gate do `NOW` |
| Nenhum placeholder | detector em entrega/aceite e corpus negativo determinístico |
| Ciclo detectado | ordenação topológica e fixture cíclica fail-closed |
| Histórico fora da fonte ativa | lifecycle, banners e negativo de autoridade histórica |
| Receipt vinculado ao digest | `project_logic_manifest_v1.source_digest_sha256` e este receipt durável |

## Limites, riscos e rollback

- A granularidade completa entrypoint → rota → teste → gate permanece em
  `BT-GATE-005`/`BT-AI-029`; `flow_consumers` não finge ser call graph.
- Receipts fortes para todos os fluxos permanecem em `BT-GATE-002`.
- Hardening para menções incomuns de placeholder embutido permanece em
  `BT-DOC-005`; os tokens inequívocos e variações de caixa estão cobertos.
- Não houve PostgreSQL/Hermes/SQLite de produto, runtime, capability, deck,
  regra, pin, PR, merge ou deploy.
- Rollback: `git revert d9f7a59cd87d032df3d076c35ffbdb17e41525a6`,
  regenerar os nove artefatos pela ferramenta e repetir project logic/full.
  Não existe estado live para restaurar.

## Veredito

`PASS` local para `BT-DOC-004`, com auditoria independente `GO` e gate `full`
verde na implementação exata. A fila pode avançar, em WIP 1, para
`BT-SCP-001`; isso não liga capabilities nem declara produção atualizada.
