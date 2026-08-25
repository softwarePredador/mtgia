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
- Estado desta ficha: `OPENED_NOT_IMPLEMENTED`; nenhuma cláusula de aceite foi
  reivindicada por esta abertura

## Resultado desta execução

### Dentro do escopo pretendido

- Provar uma policy server-authoritative exata, versionada e fail-closed para
  todas as 29 capabilities.
- Provar que chave ausente, extra ou inválida produz negação antes de
  PostgreSQL, fila, worker ou provider externo.
- Provar que o app apresenta e roteia somente superfícies permitidas pelo
  snapshot válido recebido do backend.
- Manter `account_registration` separada e `OFF`, sem transformar login,
  recuperação ou privacidade de contas existentes em capability de produto.
- Ligar a matriz à release identity da mesma revisão e manter
  `implementation_status`, `release_capability` e `live_verified_as_of` como
  eixos independentes.

### Fora do escopo

- Ligar qualquer capability ou alterar a oferta gratuita sem comércio.
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

| Gate | Comando | Esperado | Real | Exit | SHA | Artefato/hash |
| --- | --- | --- | --- | ---: | --- | --- |
| Baseline herdado | `./scripts/manaloom_local_ci.sh full` | baseline saudável antes da task | `PASS`; nenhuma implementação de `BT-SCP-001` atribuída | `0` | `d9f7a59cd87d032df3d076c35ffbdb17e41525a6` | receipt de `BT-DOC-004` |
| Focais `BT-SCP-001` | a definir após reproduzir o gap | `PASS` | não executado | — | — | — |

## Receipts

| Contrato | Producer | Status | Path/hash | Durável | Bindings revisados |
| --- | --- | --- | --- | --- | --- |
| Baseline policy | repository | observado | `server/config/release_capabilities.json` · `ace782b3969a…` | yes | revisão baseline |
| `BT-SCP-001` | `/root` | não emitido | será definido no fechamento | yes | SHA/digest/target obrigatórios |

## Aceite canônico

| Cláusula resolvida do registry | Evidência nesta abertura |
| --- | --- |
| Flag ausente/inválida fica OFF | pendente de testes focais e integrados |
| API nega antes de PG | pendente de prova de ordem e failure injection |
| App só apresenta o permitido | pendente de provider/guard/runtime aplicável |
| Cadastro novo separado e OFF | baseline observado; aceite integrado pendente |
| Same-SHA registra a matriz | pendente de receipt de release identity |
| Três eixos permanecem distintos | baseline observado; negativos pendentes |

## Fechamento

- Resultado E2E estrito: `n/a` nesta abertura sem implementação
- Gate-eligible: `false`
- Release identity: produção não reobservada; último estado conhecido
  `SERVER_BEHIND`
- Bloqueios: nenhum para iniciar após publicar o fechamento de `BT-DOC-004`
- Riscos residuais: todos os riscos desta task permanecem abertos
- Rollback verificado: `no`; implementação ainda não iniciada
- Auditor independente: `pending`
- Veredito da execução: `DEFERRED_BY_SCOPE` somente para esta etapa de abertura;
  o estado canônico continua no backlog
- Commit que atualiza o estado canônico: `pending`
- Próximo ID elegível depois do fechamento: `BT-OFFER-001`
