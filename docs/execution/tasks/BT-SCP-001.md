# Ficha de execução — `BT-SCP-001`

> Ledger de execução não autoritativo. ID, prioridade, estado, dependências,
> entrega e aceite continuam resolvidos no backlog mestre/registry.

## Autoridade

- Task ID: `BT-SCP-001`
- Backlog: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`
- Registry schema: `2`
- Registry `generated_from.sha256` de abertura:
  `0ce0be74f84bd5e8eb25568601a4ce47f46a24dd6766dba67393caadd8f62abd`
- Project logic source digest de abertura:
  `bf7704ee33c99009bc878962409654df0af63d244c1b52c10eccc7aa674c80e0`
- Registry `generated_from.sha256` corrente: `dd1fe8ff0a41a10b680350ff197a4dfa32e3c25fe2acda6a5410be4ed109216f` (o aceite desta task
  foi ampliado em `f6f791098`)
- Linha canônica: `222`
- Decisão corrente: `docs/status/CURRENT_PRODUCT_DECISION.md`
- Dependência canônica: `BT-GOV-001=PASS`

## Identidade da execução

- Owner: `/root`
- Início UTC: `2026-08-24T21:14:27Z`
- Fim UTC: `pending`
- Branch: `codex/free-beta-release-candidate-2026-07-17`
- Git SHA baseline antes da abertura:
  `d9f7a59cd87d032df3d076c35ffbdb17e41525a6`
- Git SHA inicial da implementação: `pending`
- Git SHA final: `pending`
- Worktree digest do baseline limpo:
  `ee254fdbc66babfe86ddd041b8a28e3c458e5c13a536e0599d88d55b2b4f08a7`
  (`manaloom-worktree-v2` no SHA baseline; a abertura da ficha e o fechamento
  documental do predecessor ainda não estavam commitados)
- Fonte estável: `true` no baseline; revalidar antes de implementar
- Classe(s) de fechamento: `LOCAL_CODE`, `DISPOSABLE_PG` e
  `RELEASE_READ_ONLY` somente quando os respectivos gates forem executados
- Autorização máxima: código e documentação local, PostgreSQL loopback descartável, commits e push desta branch; nenhum PR/merge, deploy, migration ou DML live, capability ON, pin, regra ou deck
- Estado desta ficha: `IN_PROGRESS_CONTAINED`; implementação e prova focal de
  runtime existem, mas gate amplo, clean-SHA, auditoria e fechamento canônico
  continuam pendentes

## Resultado desta execução

### Consolidação herdada autorizada em 2026-09-09

- Owner único: `/root`; WIP `1`, sem subagentes de Desenvolvimento. Auditorias
  coordenadas pela gerência são somente leitura. Nenhum novo ID funcional foi
  aberto, e o aceite canônico de `BT-SCP-001` continua pendente.
- Base atual: `d15beb05b` (2026-09-21). Consolidação herdada landou em
  `f6f791098` (313 arquivos). Home/UX e recovery isolados não
  foram importados. O pacote é de consolidação do trabalho já existente,
  não um fechamento de Battle, MVP ou release.
- Destino enumerado: `271` paths herdados (`94` fontes/testes/contratos,
  `5` gerados modificados e `172` evidências históricas). A única fonte extra
  da revisão inicial foi `server/test/authenticated_visual_fixture_contract_test.dart`,
  teste existente necessário à segurança dos dois harnesses. O ajuste P0
  descrito abaixo acrescentou somente seu runner; total `273`, índice vazio.
- Preservação durável fora de `/tmp`: checkpoint privado
  `main-consolidation/20260909.SkxWdq9c`; backup verificado
  `backup-receipt.json` SHA-256
  `1960af763fbcf2f886a3b1476ca23d79cd69c7598b16ffe63cb23c8896f40083`.
  O índice `historical-evidence-172.json`, SHA-256
  `4b9b11d78ac8d6d93c2ebb81ecc131165a8cc1e4b80e7af1234a62669f65f537`,
  mantém origem/hashes de todos os artefatos antigos. Nada recebe reetiquetagem
  como prova nova; `current` só será substituído por captura runtime fresca.
- Revisão mínima dos scripts `manaloom_authenticated_visual_qa_isolated.sh`
  e `manaloom_server_contract_e2e_isolated.sh`: coordenadas PG literais
  loopback, neutralização de serviços/endereço herdados do libpq, segredo
  somente no ambiente dos consumers, bootstrap do CLI pinado antes de iniciar
  runtime, ownership/cancelamento do grupo de build e restauração dos outputs
  PRE ignorados. Cleanup falho ou receipt ausente/divergente não vira PASS.
- Prova focal `fixture-safety-r3`: `27/27`, zero SKIP; analyze, bash-n,
  diff-check e scan focal de segredos verdes. Receipt externo SHA-256
  `41c6b0994d128a4b32bc80461499eb52ac992f46d81b92f1066fb0898fd45015`;
  log dos testes SHA-256
  `6eafb453e77ac50afd29a150a67be86c10862dad22b354a6d267c6ef60dfec16`.
  R1 (escaping no teste) e R2 (`ps` bloqueado pela sandbox macOS) permanecem
  NON_PASS históricos. O focal usa stubs/processos locais, não prova PG/UI.
- Reauditoria do focal identificou que uma asserção Bash podia ser mascarada
  pelo `printf` seguinte. Corrigido somente `]]; printf` para `]] && printf`,
  sem alterar novamente os harnesses. R4 repetiu `27/27`, análise e cleanup
  com exit `0`; teste SHA-256
  `e972f207dda62ee9af8663d9d7887ccde03cba462495ed9d9277ca9c1dbbedfd`,
  log SHA-256
  `48cabafbdc7bda7deefadc6b4e42faf152b06516d62a0a6fe3bcdd872009e91d`.
  R3 permanece histórico com essa limitação; R4 aguarda o parecer dirigido.
- Gerência ratificou `GO_HARNESS_SAFETY_DELTA_AUDITED` para R4. Os receipts
  originais permanecem imutáveis; o parecer cobre só o delta de segurança,
  não PG/UI/release. Os dois harnesses e o focal R4 não mudaram depois do GO.
- `GO_FIX_P0_CAPTURE_TOOLCHAIN_BINDING_MINIMAL`: o runner
  `scripts/manaloom_p0_runtime_capture.sh` passou a consumir o resolver/par
  versionado de Flutter/Dart, eliminando a fixação ao SDK compartilhado e ao
  wrapper `bin/dart`. O processo de captura usará explicitamente o SDK lateral
  aprovado. Contrato em `server/test/flutter_release_sdk_contract_test.dart`
  (já herdado): overrides, Dart real do mesmo SDK e negação de root inválido;
  `8/8`, análise, bash-n e diff-check com exit `0`. Sem mudança de pin, helper,
  policy, roteiros ou outputs visuais.
- A geração R4 terminou `NON_PASS`, exit `2`, antes de produzir gerados:
  fonte global do cache divergiu em `24` arquivos intermediários JNI `.cxx`.
  Os cinco locks e o seed do cache privado previamente aprovado permaneceram
  idênticos. Preparação proporcional: usar esse seed privado como fonte
  somente leitura e criar outro cache independente pelo launcher canônico;
  não reetiquetar marcador nem alterar cache global/SDK compartilhados.
- Próximo marco: `play-vs-ai-web-real` recapturado e `latest.json` reescrito
  (hoje 22/23 manifests em `8bba809c`; 0 casam digest+hash).
- Veredito corrente (2026-09-21): `GATE_AMPLO_NAO_ALCANCADO` — `full` `EXIT=1`
  em `npm audit`; `ui-audit` (`BT-UIEV-001`), `custom-lint`, `patrol-smoke` e
  `dependency_audit` não exercitados. Provado: bootstrap frio + suíte
  project-logic + guard por mutação (`d83e9b1e1`, `07014b431`, `d26f23a16`).
- Capabilities de produto continuam `29/29 OFF`; nenhum deploy, DML/migration
  live, sincronização, pin ou runtime publicado foi alterado nesta retomada.

### Dentro do escopo pretendido

- Provar uma policy server-authoritative exata, versionada e fail-closed para
  todas as 29 capabilities.
- Provar que chave ausente, extra ou inválida produz negação antes de
  PostgreSQL, fila, worker ou provider externo.
- Provar que o app apresenta e roteia somente superfícies permitidas pelo
  snapshot válido recebido do backend.
- Aplicar a decisão do ADR 0013 sem abrir Battle: remover a rota pública de
  espectador, tornar Jogar contra IA a única direção interativa guardada e
  impedir fallback para Forge/simulação/replay quando o XMage estiver bloqueado.
- Manter `account_registration` separada e `OFF`, sem transformar login,
  recuperação ou privacidade de contas existentes em capability de produto.
- Ligar a matriz à release identity da mesma revisão e manter
  `implementation_status`, `release_capability` e `live_verified_as_of` como
  eixos independentes.

### Fora do escopo

- Ligar qualquer capability ou alterar a oferta gratuita sem comércio.
- Fechar canonicamente partida real completa, capacidade Battle ou prontidão
  de coorte; a execução focal autorizada pelo usuário serve como evidência
  suplementar da superfície app-facing, sem mover `BT-PLAY-002`, `BT-BAT-010`
  ou sucessores.
- Declarar produção same-SHA sem observação read-only da revisão publicada.
- Fazer deploy, migration/DML live, criar conta, promover deck/regra, atualizar
  XMage/Forge ou seus pins, ou iniciar outra task funcional.
- Fechar tasks consumidoras apenas porque sua capability permanece `OFF`.

### Capabilities

- Antes: policy `release_capabilities_v1`, versão
  `brewtact_free_beta_2026-08-13`, oferta `free_beta_no_commerce`, `29/29 OFF`.
- Depois pretendido: `29/29 OFF`; a task prova autoridade e contenção, sem
  promoção funcional.
- Evidência baseline: `server/config/release_capabilities.json`, SHA-256
  `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d`.

### Delta implementado nesta execução

- A policy e os consumers preservam 29/29 capabilities `OFF`, com cadastro
  novo separado de login/recuperação de conta existente.
- A superfície Battle pública foi reduzida a **Jogar contra IA** atrás da
  capability técnica legada `battle_coach`; Battle Live ficou sem rota/CTA de
  produto.
- A rota canônica é `/decks/:id/play-vs-ai[/sessionId]`; rotas Coach antigas
  são redirects de compatibilidade.
- A mesa apresenta mão própria, campo, pilha e ações tipadas card-first; opção
  ambígua não dispara ação e indisponibilidade XMage falha fechada sem Forge,
  simulação ou replay substituto.
- O runner isolado (`scripts/manaloom_play_vs_ai_e2e.sh`) provou o fluxo em
  2026-08-25 (receipt); a versão de 2026-09-18 tinha asserção impossível
  (corrigida em `d08c18717`) e ainda não voltou a passar no HEAD.
- Nenhum pin, migration, DML live, capability, deck/regra de produto, deploy ou
  runtime publicado foi alterado.

## Critérios de entrada

- Dependência e receipt: `BT-GOV-001=PASS` em
  `docs/qa/execution/2026-08-14/BT-GOV-001.md`.
- Predecessor operacional: `BT-DOC-004=PASS`, receipt em
  `docs/qa/execution/2026-08-24/BT-DOC-004.md`; publicação do fechamento deve
  ocorrer antes da primeira mudança funcional desta task.
- Baseline reproduzível: matriz commitada com 29 entradas, zero `allowed=true`
  e digest `ace782b3969a…`; o gate `full` passou no SHA baseline.
- Contratos aplicáveis: `AGENTS.md`, decisão corrente, backlog mestre,
  `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`, contrato de release capabilities e
  contrato operacional de release.
- Dados: PostgreSQL/backend permanece verdade; qualquer banco usado nos testes
  será novo, loopback, descartável e removido pelo gate.
- Riscos: divergência app/backend/ops, bypass de rota direta, leitura da policy
  depois de tocar PG/provider, snapshot inválido aceito parcialmente e
  confusão entre código implementado, capability liberada e live verificado.
- Rollback planejado: reverter somente os commits focais, regenerar project
  logic e repetir contratos/full; nenhuma restauração live deve ser necessária.

## Plano de implementação

1. Inventariar policy, parsers, middleware, rotas, jobs, release identity e
   consumers app na mesma revisão.
2. Reproduzir primeiro os gaps com testes negativos determinísticos.
3. Corrigir apenas os pontos onde a autoridade/falha fechada ainda não estiver
   comprovada, mantendo toda capability `OFF`.
4. Provar negação anterior a storage/provider e coerência app/backend/ops.
5. Rodar gates focais, project logic, schema descartável e `full`; emitir
   receipts ligados ao SHA/digest e solicitar auditoria independente.

### Fontes candidatas, ainda sem alteração nesta abertura

- `server/config/release_capabilities.json`
- `server/lib/release_capability_policy.dart`
- middleware e rotas backend protegidas pela policy
- `server/bin/manaloom_ops_daemon.py`
- `app/lib/core/config/release_capabilities.dart`
- guards/consumers app das superfícies protegidas
- `scripts/lib/manaloom_release_capabilities_contract.sh`
- `scripts/manaloom_release_capabilities_contract_test.sh`
- `scripts/manaloom_release_ops_contract_test.sh`
- scripts de release identity e seus testes

### Gerados derivados esperados

- Os nove artefatos oficiais de project logic, somente via
  `./scripts/manaloom_project_logic.sh --write`.
- Receipts duráveis específicos do gate/release quando houver execução.

### Migration/DDL

- Nenhuma migration ou alteração de DDL está prevista. O gate de schema pode
  criar PostgreSQL exclusivamente loopback em `/tmp` e deve removê-lo ao fim.

## Plano de prova

### Funcional

- Positivo: policy exata 29/29 `OFF` é aceita de forma idêntica por backend,
  app e ops, com identidade versionada.
- Negativo: chave ausente/extra, tipo/enum inválido, `allowed` divergente de
  `release_capability`, digest misto e snapshot incompleto falham fechados.
- Concorrência: processos/isolates carregando a mesma revisão observam a mesma
  matriz; nenhum reload parcial abre uma capability.
- Retry/idempotência: repetir carga, health/readiness e negação de rota não
  muda estado nem toca storage/provider.
- Failure injection: policy ausente/corrompida, endpoint indisponível e chamada
  direta/deep link continuam negados.

### Integração ponta a ponta

- Producer → storage → API → consumer: policy commitada → parser backend →
  middleware antes de PG/provider → `/capabilities`/release identity → provider
  app → navegação/CTA.
- Isolamento A/B: uma identidade/snapshot inválido não herda permissão de outro
  processo, usuário ou cache anterior.
- Cleanup/rollback: PostgreSQL e artefatos temporários descartáveis removidos;
  worktree e processos verificados no fim.

### UI/runtime

- `PASS_AUTOMATED`: testes de provider, guards, rotas e contratos aplicáveis.
- `PASS_RUNTIME`: obrigatório somente se a implementação alterar superfície
  app-facing; usar Android físico ou build Web real.
- `PASS_VISUAL_REVIEWED`: obrigatório somente para delta app-facing, após abrir
  todas as capturas do mesmo digest.
- TalkBack/teclado/permissões: permanecem gates humanos separados de release e
  não recebem crédito antecipado nesta ficha.

### Observabilidade

- Eventos/métricas/logs: registrar somente versão/digest/status da policy e
  motivo estruturado de negação; nunca token, DSN ou conteúdo de deck.
- SLO/alerta/runbook: validar health/readiness e falha da policy nos contratos
  operacionais; mudanças de alerta live ficam fora da autorização.
- Redação/PII: nenhuma capability ou release identity carrega PII.

## Gates executados

Tabela histórica de agosto; não atribuir crédito ao pacote de setembro sem
reexecução aplicável e prova vinculada ao digest congelado.

| Gate | Comando | Esperado | Real | Exit | SHA | Artefato/hash |
| --- | --- | --- | --- | ---: | --- | --- |
| Baseline herdado | `./scripts/manaloom_local_ci.sh full` | baseline saudável antes da task | `PASS`; nenhuma implementação de `BT-SCP-001` atribuída | `0` | `d9f7a59cd87d032df3d076c35ffbdb17e41525a6` | receipt de `BT-DOC-004` |
| Contrato Play/XMage | `cd server && dart test test/xmage_interactive_release_contract_test.dart` | `PASS` | rodada anterior `14/14`; refresh após regressão SQL pendente | — | worktree | teste focal |
| UI policy | `cd app && flutter test test/ui/ui_live_evidence_policy_test.dart` | `PASS` | `4/4` | `0` | worktree | policy executável |
| Mesa Jogar contra IA | `cd app && flutter test test/features/battle/screens/battle_coach_screen_test.dart` | `PASS` | `27/27` | `0` | worktree | widget/semântica/ações |
| Analyzer focal | Flutter analyzer nos sources Battle alterados | `PASS` | sem issues | `0` | worktree | saída local |
| E2E XMage + browser | `MANALOOM_PLAY_VS_AI_BROWSER_QA=1 ./scripts/manaloom_play_vs_ai_e2e.sh` com confirmações descartáveis | `PASS` | `PASS`; 3 níveis UI, replay/PG e cleanup | `0` | UI digest `a81e8c2a…` | relatório `20260825T193821Z_67071_13837` |
| Project logic / full / schema | comandos de fechamento | `PASS` | pendente desta consolidação | — | — | — |
| Full 2026-09-21 | `./scripts/manaloom_local_ci.sh full` | `PARCIAL` | `EXIT=1` em `npm audit` (`next` critical, `sharp` high); zero falha de teste nos estágios que rodaram | `1` | `b4473a98a`→`07014b431` | `docs/qa/execution/2026-09-21/btscp001-gate-amplo.md` |

## Receipts

| Contrato | Producer | Status | Path/hash | Durável | Bindings revisados |
| --- | --- | --- | --- | --- | --- |
| Baseline policy | repository | observado | `server/config/release_capabilities.json` · `ace782b3969a…` | yes | revisão baseline |
| Play vs AI focal | `/root` | `PASS_FOCAL_NOT_TASK_CLOSURE` | `docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md` | yes | worktree/UI digest/bundle/pins/target |
| Gate amplo 2026-09-21 | sessão de 2026-09-21 | `PARCIAL` | `docs/qa/execution/2026-09-21/btscp001-gate-amplo.md` | yes | SHA `b4473a98a`→`07014b431`; corrigido após revisão adversarial |
| `BT-UIEV-001` ChromeDriver e recaptura | sessão de 2026-09-21 | `PARCIAL` | `docs/qa/execution/2026-09-21/btuiev001-chromedriver-e-recaptura.md` | yes | SHA `d26f23a16`; UI digest `8bba809c…` (22/23 manifests) |
| Ponto de retomada 2026-09-21 | sessão de 2026-09-21 | `PARCIAL` | `docs/qa/execution/2026-09-21/PONTO_DE_RETOMADA.md` | yes | estado, não autoridade |
| `BT-SCP-001` | `/root` | fechamento pendente | será emitido depois de full, clean-SHA e auditoria | yes | SHA/digest/target obrigatórios |

## Aceite canônico

| Cláusula resolvida do registry | Evidência nesta abertura |
| --- | --- |
| Flag ausente/inválida fica OFF | implementado em parsers/providers e negativos; gate amplo ainda pendente |
| API nega antes de PG | testes de policy/rotas e fixture isolada exercitam default-deny; full ainda pendente |
| App só apresenta o permitido | guards/rotas atualizados e Web real comprovou a superfície permitida no snapshot isolado |
| Cadastro novo separado e OFF | policy/app mantêm chave própria; conta descartável só foi criada com policy isolada explícita |
| Same-SHA registra a matriz | pendente de receipt de release identity |
| Três eixos permanecem distintos | report mantém implementação funcional, capability `OFF`, live desconhecido e `release_ready=false` |

## Fechamento

- Resultado E2E estrito: `PASS` focal em ambiente loopback descartável; não é
  fechamento da task nem release
- Gate-eligible: `false`
- Release identity: produção não reobservada; último estado conhecido
  `SERVER_BEHIND`
- Bloqueios (2026-09-21): (1) `npm audit` do web público — bump `next` 15.5.25
  / `sharp` 0.35.4 autorizado pelo dono em 2026-09-21, execução pendente;
  (2) `BT-UIEV-001` — `latest.json` com 23 manifests; (3) `custom-lint`,
  `patrol-smoke`, `dependency_audit` nunca exercitados; (4) clean-SHA com hooks
  (16 commits `--no-verify`); (5) auditoria independente e receipt final
- Riscos residuais: aggregate UI global stale, Android físico,
  teclado/TalkBack e todos os P0/rollout Battle continuam abertos
- Rollback verificado: cleanup do runtime descartável passou sem kill forçado;
  rollback Git será registrado após o commit focal
- Auditor independente: `pending`
- Veredito da execução: `IN_PROGRESS_CONTAINED`; o estado canônico continua no
  backlog até todos os gates de `BT-SCP-001` fecharem
- Commit que atualiza o estado canônico: `pending`
- Próximo ID elegível depois do fechamento: `BT-UX-KIT-001` (kit visual em
  `app/lib`; decisão do dono em 2026-09-21; `BT-SCP-001` continua `NOW` até
  fechar)

## Nota de 2026-09-22 — dependências explicitadas

`BT-UIEV-001` e `BT-WEB-003` passaram a constar como dependências deste ID no backlog. Não é
mudança de aceite: é tornar visível o que já bloqueava o `PASS` — o gate amplo morre no
`npm audit` (`BT-WEB-003`) e em `ui_live_evidence` (`BT-UIEV-001`). Antes, `BT-UIEV-001`
declarava depender deste ID, o que criava impasse. Com dependências abertas, o slot segue
como contenção fail-closed (`IN_PROGRESS_CONTAINED`), com o marcador declarado em
`docs/execution/CURRENT_QUEUE.md`.
