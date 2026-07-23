# Evidências da Sprint 8 — Resiliência, desempenho e operação

Data: 2026-07-23
Branch: `codex/free-beta-release-candidate-2026-07-17`
Base das medições runtime: `4700fc38317aae0d3c1955176b32c18ac3b34339`
Commit de implementação validado/publicado:
`2139ec9f6f902a8b266fbb852db6e834b25bceff`
Base limpa da revalidação residual:
`9deb607e4c09f8d8e6cd94241a61f2960262c6fe`
Commit de retenção/retry publicado:
`bf035b7f15216bb74c34b172c84e20ad498a5174`
Commit técnico do cancelamento físico:
`b84302e1e7b1d19da23bb2d1cc6e4605f9703d6b`
SDK: Flutter `3.44.6`, Dart `3.12.2`

Este relatório registra somente provas executadas na revisão corrente. Provas
de artefato assinado, serviço externo ou escrita off-site permanecem pendentes
até que a mesma SHA esteja congelada e os pré-requisitos estejam disponíveis.
As medições físicas/Web focadas foram iniciadas sobre a base acima com o
worktree dirty. Depois da consolidação, o gate determinístico completo foi
repetido sobre o commit de implementação limpo, publicado e sem diferenças
entre o ref local e o remoto.

## S8-01 e S8-09 — Offline e reconexão

Resultado: `PASS`

- `OfflineFlowContract` classifica 19 fluxos como `offline_supported`,
  `cached_read_only` ou `online_required` e declara cache, fila, retry,
  conflito, reconciliação e preservação de entrada.
- somente `PostGameNoteStore` declara mutação remota offline: upserts e
  tombstones persistentes, retry serializado e merge por ID/cursor;
- Life Counter e onboarding são locais, sem fingir fila remota;
- geração/importação e mensagens mantêm rascunho e chave idempotente, mas
  continuam explicitamente online;
- descrição de deck que falha ao salvar fica persistida por usuário/deck e é
  removida somente após sucesso ou descarte;
- Home usa `cached-read-only` para snapshot em memória; scanner e erros de
  transporte consomem o contrato canônico;
- um guard estático falha se uma nova promessa de offline surgir fora das
  superfícies governadas ou se `MessageProvider` voltar a expor exceção crua.

Provas executadas:

```text
flutter analyze (6 alvos)                         PASS, 0 issues
offline/resilience + UI/provider focused tests   PASS, 56/56
deck/detail + stores focused tests               PASS, 34/34
```

Arquivos centrais:

- `app/lib/core/resilience/offline_capability.dart`
- `app/test/core/resilience/offline_capability_test.dart`
- `app/test/core/resilience/offline_ui_contract_guard_test.dart`
- `app/lib/features/decks/services/deck_entry_draft_store.dart`
- `app/lib/features/retention/services/post_game_note_store.dart`
- `app/lib/core/services/message_draft_store.dart`

## S8-02 — Orçamento de desempenho do core

Resultado: `IN_PROGRESS`

`PerformanceService` e o harness de Web/device estão implementados, mas a
matriz completa de cold/warm start, Home, listas, busca, detalhe, deck,
optimize e Battle ainda não tem p50/p95 da mesma revisão nos dois alvos.
Fechamento exige a fixture real autorizada e uma execução sem checkout
concorrente.

Uma reexecução limpa fechou novamente a parcela de startup Web sem mutação de
produto:

```text
Chrome 150 / 1440×757 / 7 amostras
  cold start  valores 631, 622, 618, 619, 614, 660, 623 ms
              p50/p95/max 622/660/660 <= orçamento 3000 ms
  warm start  valores 219, 238, 220, 222, 228, 227, 219 ms
              p50/p95/max 222/238/238 <= orçamento 1500 ms
```

O relatório canônico `manaloom_runtime_startup_v1` terminou `result=pass`.
Também passaram 4/4 testes Python do harness, 13/13 testes Flutter de
performance/cache/imagens e 19/19 de layout/fallback, com análise estática sem
erros. O startup Android não foi executado porque o aparelho não estava
conectado. As oito superfícies autenticadas ainda exigem PostgreSQL/API
loopback descartáveis levantados na mesma revisão.

O contrato determinístico do harness agora é um modo próprio,
`./scripts/quality_gate.sh performance`, e também participa de
`quality_gate.sh full`. Ele compila os dois módulos Python e executa os 4/4
testes de percentil, parser Android, orçamento e resultado agregado sem abrir
browser/device nem acessar fixture. Isso fecha a integração no gate sem
transformar ausência de runtime em `PASS`.

## S8-03 — Memória e imagens

Resultado: `IN_PROGRESS`

O teste `app/integration_test/image_memory_runtime_test.dart` preserva uma
prova física anterior válida com 180 imagens no Android:

```text
Android Samsung SM-A135M / R58T300SREH
  cache peak/final       7.864.320 bytes, 20 entradas
  orçamento de cache    33.554.432 bytes, 96 entradas
  RSS inicial/peak      363.450.368 / 466.591.744 bytes
  crescimento RSS       103.141.376 <= 201.326.592 bytes
  crescimento repetido  16.039.936 <= 33.554.432 bytes
  passos                19 + 19
```

A revalidação Web corrigiu uma falsa equivalência de métrica: profile e
release executaram 78 + 78 passos de scroll, porém
`PaintingBinding.imageCache` permaneceu com 0 entradas/0 bytes e o guard
falhou fechado como amostra inválida. Nesse alvo, `cached_network_image_web`
usa `HtmlImage`; portanto o cache Flutter não mede a memória efetiva das
imagens do navegador e o antigo número de Chrome não serve como aceite atual.

O app de teste e o `adb reverse` da prova física foram removidos do aparelho;
o ChromeDriver da revalidação foi encerrado. Permanecem necessários um probe
Web específico de heap/rede (por exemplo CDP) ou uma decisão explícita de
loader/CORS, a repetição Android da SHA final e a incorporação ao perfil
completo S8-02.

## S8-04 — IA longa, indisponibilidade e cancelamento

Resultado: `IN_PROGRESS`

- timeout do provider em `/ai/generate` agora retorna HTTP 504 e
  `Cache-Control: no-store`;
- o corpo declara `provider_timeout`, `provider_unavailable`,
  `ai_generation_timed_out=true`, `retryable=true`, `can_save=false` e
  `learning_eligible=false`;
- `generated_deck=null`; não há mock, cache ou HTTP 200 no caminho de timeout;
- o worker assíncrono trata 504 como job falho, não como conclusão;
- `server/test/ai_generate_provider_timeout_test.dart` cobre o contrato e a
  suíte focada passou `26/26`; análise dos alvos alterados passou sem issues.
- falha terminal persistida agora lança
  `GenerateDeckTerminalFailureException`, limpa `job_id` e `request_key` no
  rascunho e permite uma nova submissão; timeout/transiente preserva a chave
  resumível;
- a mensagem terminal é sanitizada e não expõe o erro bruto do provedor;
  provider + fluxo widget real de retomada passaram `57/57`.
- a chamada OpenAI usa `http.AbortableRequest`; timeout ou cancelamento
  completa o `abortTrigger`, e o `IOClient` encerra fisicamente o
  `HttpClientRequest` subjacente;
- o worker envia o ID canônico do job somente junto do token interno. O
  executor valida ambos, consulta no PostgreSQL se o job continua
  `pending/processing` e propaga a transição feita pelo `DELETE` ao request em
  andamento com cadência nominal de um segundo;
- cada execução possui cliente HTTP próprio, fechado no `finally`; o caminho
  cancelado retorna HTTP 409, `Cache-Control: no-store`,
  `ai_generation_cancelled`, `can_save=false`, `learning_eligible=false` e
  nenhum deck;
- os testes específicos de timeout/abort passaram `9/9`; a malha ampliada de
  lifecycle/provider passou `45/45`, o analyzer passou sem issues,
  `ai-bridge` passou `114/114` e o gate local `full` passou no commit técnico
  `b84302e1e7b1d19da23bb2d1cc6e4605f9703d6b`.

A task permanece `IN_PROGRESS`: o residual local de abort físico e propagação
foi fechado, mas ainda falta executar, na SHA final e contra um endpoint
controlado, a matriz E2E integral de indisponibilidade/cancelamento
(`429`, `5xx`, queda de conexão, timeout e cancelamento durante o request).

## S8-05 — Observabilidade acionável

Resultado: `BLOCKED`

As superfícies locais de request ID, redaction, health/readiness e
observabilidade foram reforçadas e testadas, mas o aceite exige evento Sentry
da mesma SHA e correlação app → API → erro em runtime publicado. Próxima
condição: SHA limpa implantada e credenciais/ambiente Sentry disponíveis para
prova read-only.

## S8-06 — FCM no artefato alvo

Resultado: `BLOCKED`

O contrato e o harness local de notificações existem, porém foreground,
background e tap/deep link precisam ser repetidos no APK assinado exato da SHA
congelada. Próxima condição: artefato final instalável e credenciais FCM do
ambiente candidato.

## S8-07 — Backup e recuperação

Resultado: `BLOCKED`

Scripts e contratos locais de backup/cron foram reforçados, mas não houve
escrita off-site nem restore de um backup fresco desta revisão. Próxima
condição: destino off-site, chave e autorização específica, seguidos por
checksum, restore isolado e registro de RPO/RTO.

## S8-08 — Segurança técnica

Resultado: `BLOCKED`

```text
./scripts/quality_gate.sh deps          PASS, 4 pacotes
./scripts/manaloom_secret_scan.sh --worktree
                                         PASS, 0 credenciais live literais
gitleaks                                 PASS, 8.30.1
```

O preflight source-lock da base limpa foi determinístico em duas execuções
(SHA-256
`452ab8f4314d35e0da5a8bd024327bb0feab35062968a0b3b921930f6668cc3b`):

```text
Android source-lock       539 componentes, 533 consultados no OSV,
                          226 excluídos, 0 vulnerabilidades de release
Web público combinado     954 componentes, 948 consultados no OSV,
                          0 vulnerabilidades de release
achados fora do release   78, mantidos como não-release/excluded
```

Isso é prova de fonte, não de artefato. Não existe APK/AAB release corrente;
o checkout só contém APKs debug/profile. O guard de identidade rejeita a
base medida porque ela estava dez commits à frente de `origin/master`
(`72bd76da8372c1b2188ee86d0d8bb55c98d590fc`), e `version: 1.0.0+2` ainda
precisa de disposição/bump antes de upload. O SBOM também não cobre pacotes
APT da futura imagem OCI. O fechamento continua dependente de S8-05, do
SBOM/OSV do APK/AAB exato e da rejeição de token antigo após publicação do
backend correspondente. Nenhum deploy ou mutação live foi executado.

## Validação determinística relacionada

O commit técnico limpo
`b84302e1e7b1d19da23bb2d1cc6e4605f9703d6b` passou:

```text
./scripts/manaloom_local_ci.sh full
  backend                              1742/1742 PASS
  Flutter                              1159 PASS + 1 skip Web-only conhecido
  Web pública                          13 páginas, 0 vulnerabilidades, smoke PASS
  Patrol local                         9/9 PASS
  schema loopback                      73 tabelas, 6 views, 76 FKs, 51 migrations

ai-eval / ai-bridge                    PASS
battle                                 PASS em 2 execuções
web                                    PASS
E2E deterministic-read-only           PARTIAL, 10 PASS, 9 skips guardados,
                                       0 FAIL, 0 BLOCKED
```

O `engine-delta` passou sem alterar pins e retornou `review_required` para 316
cartas e 328 fixtures: XMage 120/131 e Forge 196/197, ambos 113 commits à
frente dos pins. A revisão explícita em
`docs/qa/MANALOOM_ENGINE_DELTA_REVIEW_2026-07-23.md` decidiu
`retain_current_pins`: o incremental XMage é restrito ao editor desktop; o
Forge mantém regressão no orçamento público e possui mudanças gerais ainda
não qualificadas, além do compare truncado em 300 arquivos. A disposição fecha
a revisão local do delta, mas não substitui as provas externas/live das tasks
bloqueadas.

## Disposição de acessibilidade relacionada

S3-04 continua `BLOCKED` somente pela interação humana TalkBack no Android
alvo. O beta S10 foi fixado em Web + Android; iOS e VoiceOver estão
`DEFERRED_BY_SCOPE`, com rotas vazias na matriz, e não bloqueiam esta candidata.
