# Binder / Marketplace / Trades Runtime - iPhone 15 Simulator - 2026-04-29

## Atualizacao - P1 performance PUT /trades/:id/respond - 2026-04-30 10:45 -0300

Resultado: `Approved for PUT /trades/:id/respond P1 latency closure on iPhone 15 Simulator`.

| Item | Evidencia |
| --- | --- |
| Device primario | `iPhone 15` |
| Simulator id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Estado | `Booted` |
| Backend URL usado pelo app | `http://127.0.0.1:8082` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}` |
| Evidencias locais | `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_trade_respond_p1/` |
| Runtime iPhone 15 | PASS: `01:39 +2: All tests passed!` |

Baseline novo em backend real, 5 amostras por action antes da alteracao:

| Endpoint/action | p50 | p95 | p99 | Min | Max |
| --- | ---: | ---: | ---: | ---: | ---: |
| `PUT /trades/:id/respond` `accept` | `3099ms` | `3902ms` | `3902ms` | `2992ms` | `3902ms` |
| `PUT /trades/:id/respond` `decline` | `3018ms` | `3028ms` | `3028ms` | `2980ms` | `3028ms` |

Depois da otimizacao, mesma amostra:

| Endpoint/action | p50 | p95 | p99 | Min | Max | Melhora p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `PUT /trades/:id/respond` `accept` | `565ms` | `1394ms` | `1394ms` | `563ms` | `1394ms` | `64.3%` |
| `PUT /trades/:id/respond` `decline` | `564ms` | `591ms` | `591ms` | `563ms` | `591ms` | `80.5%` |

Hipotese tecnica confirmada: a latencia era dominada por round-trips contra PostgreSQL remoto e notificacao sincrona no caminho critico. A rota fazia `UPDATE` transacional, `INSERT trade_status_history`, busca de nome do responder e `INSERT notifications` antes de responder ao app. Agora `FOR UPDATE`, validacao receiver-only/status pending, update e history rodam em um unico statement CTE atomico; `trade_accepted`/`trade_declined` continuam essenciais, mas via `NotificationService.createFromActorDeferred` com timeout/log/Sentry sanitizados fora do caminho critico.

Contratos preservados: JSON de sucesso (`id`, `status`, `message`), JWT, permissao receiver-only, `400` para action invalida e double respond/not pending, `401` sem token, `404` trade inexistente, `403` sem permissao, status final do trade e `trade_status_history`. O teste live passou a cobrir accept, decline, action invalida, receiver-only, double respond e notificacoes `trade_accepted`/`trade_declined`.

Comandos principais executados:

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8082/health
dart analyze routes/trades routes/notifications lib test && dart test -r expanded
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded
```

```bash
cd app
flutter analyze lib/features/trades lib/features/notifications lib/features/binder lib/features/market integration_test --no-version-check
flutter test test/features/trades test/features/notifications test/features/binder --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=SENTRY_DSN=${SENTRY_DSN:-} \
  --reporter expanded \
  --no-version-check
```

Validacoes:

- Server offline: `No issues found!`, `00:08 +555: All tests passed!`.
- Server live: `02:48 +166 ~3: All tests passed!`.
- App focado: `No issues found!`, `00:03 +12: All tests passed!`.
- Runtime iPhone 15: `PUT /trades/:id/respond -> 200 (590ms)`, `PUT /trades/:id/status -> 200 (602ms, 608ms, 593ms)`, `POST /trades -> 201 (1742ms)`.

Mocked/controlado: nenhum backend mockado; setup de usuarios/binder/trades foi por API real. `SENTRY_DSN` foi passado por dart-define com fallback vazio e nenhum segredo foi registrado.

Pendencias reais: FCM/APNS real permanece fora da prova do simulador; leituras de detalhe/mensagens ainda aparecem em ~1.1s-1.7s por DB remoto e podem virar P2/P1 se impactarem UX.

## Atualizacao - fechamento performance Social Trading P1 - 2026-04-30 10:10 -0300

Resultado: `Approved for POST /trades and PUT /trades/:id/status P1 latency closure on iPhone 15 Simulator`.

| Item | Evidencia |
| --- | --- |
| Device primario | `iPhone 15` |
| Simulator id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Estado | `Booted` |
| Backend URL usado pelo app | `http://127.0.0.1:8082` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}` |
| Evidencias locais | `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_social_trading_p1/` |
| Runtime iPhone 15 | PASS: `01:43 +2: All tests passed!` |

Baseline novo em backend real, 5 amostras por endpoint, antes da alteracao:

| Endpoint | p50 | p95 | p99 | Min | Max |
| --- | ---: | ---: | ---: | ---: | ---: |
| `POST /trades` | `3976ms` | `3991ms` | `3991ms` | `3970ms` | `3991ms` |
| `PUT /trades/:id/status` | `2782ms` | `2787ms` | `2787ms` | `2777ms` | `2787ms` |

Depois da otimizacao, mesma amostra:

| Endpoint | p50 | p95 | p99 | Min | Max | Melhora p95/p99 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `POST /trades` | `1788ms` | `1818ms` | `1818ms` | `1784ms` | `1818ms` | `54.4%` |
| `PUT /trades/:id/status` | `600ms` | `621ms` | `621ms` | `599ms` | `621ms` | `77.7%` |

Hipotese tecnica confirmada: a latencia residual era dominada por round-trips ao PostgreSQL remoto. `POST /trades` fazia validacao de receiver/ownership mais inserts transacionais em passos seriais; agora valida receiver, ownership e disponibilidade em uma query batch e cria offer/items/history com CTE em um unico round-trip transacional. `PUT /trades/:id/status` fazia `SELECT FOR UPDATE`, `UPDATE` e `INSERT history` separados; agora lock, validacao de permissao/transicao, update e status history rodam em um unico statement atomico.

Side effects essenciais preservados: contrato JSON/status codes, JWT/permissoes, `trade_items`, `trade_status_history`, estado final e notificacoes. Notificacoes continuam via `NotificationService.createFromActorDeferred`, fora do caminho critico, com timeout/log/Sentry; o log sanitizado registrou `slow_deferred` sem token/email/mensagem completa.

Comandos principais executados:

```bash
cd server
OBS_SAMPLE_COUNT=5 TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/qa/social_trading_observability_probe.dart
dart analyze routes/trades routes/notifications lib test && dart test -r expanded
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded
```

```bash
cd app
flutter analyze lib/features/trades lib/features/notifications lib/features/binder lib/features/market integration_test --no-version-check
flutter test test/features/trades test/features/notifications test/features/binder --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=SENTRY_DSN=${SENTRY_DSN:-} \
  --reporter expanded \
  --no-version-check
```

Validacoes:

- Server offline: `No issues found!`, `00:05 +555: All tests passed!`.
- Server live: primeira rodada classificou falha nao-social em `ai_generate_create_optimize_flow_test.dart` (`422 Generated deck failed validation` nos prompts); rerun imediato passou: `02:52 +165 ~3: All tests passed!`.
- App focado: `No issues found!`, `00:00 +12: All tests passed!`.
- Runtime iPhone 15: `POST /trades -> 201 (1826ms)` e `PUT /trades/:id/status -> 200 (636ms, 647ms, 635ms)`.

Mocked/controlado: nenhum backend mockado; setup de usuarios/binder/trades foi por API real. `SENTRY_DSN` foi passado por dart-define com fallback vazio e nenhum segredo foi registrado.

Pendencias reais: `PUT /trades/:id/respond` ainda aparece lento no runtime (`~3203ms`) e deve virar proximo P1 se o fluxo de aceite/recusa entrar no mesmo criterio de p95/p99. FCM/APNS real permanece fora da prova do simulador.

## Atualizacao - staging observability Social Trading - 2026-04-30 08:52 -0300

Resultado: `Approved for Sentry/log structured staging observability on simulator; FCM real remains not_proven on iPhone 15 Simulator`.

| Item | Evidencia |
| --- | --- |
| Device primario | `iPhone 15` |
| Simulator id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Backend URL usado pelo app | `http://127.0.0.1:8082` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}` |
| Sentry backend | PASS: `SENTRY_SMOKE_EVENT_ID=fa3497bfe71248f99d0217b3ba964816`, env `staging`, release `4edfbdf` |
| Sentry mobile | PASS: `SENTRY_MOBILE_EVENT_ID=08cc80c92ae446b89e8179e842a368e3`, tag `mtgia-mobile-smoke-19dde342848` |
| Runtime Social Trading | PASS: `02:12 +2: All tests passed!` com `--dart-define=SENTRY_DSN=<staging>` |
| FCM simulador | `not_proven`: `FCM_PERMISSION status=denied`, `FCM_APNS_TOKEN_PRESENT=false`, erro `firebase_messaging/apns-token-not-set` |
| Evidencias locais | `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_social_observability/` |

Comandos principais executados:

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8082/health
dart run bin/sentry_smoke.dart
OBS_SAMPLE_COUNT=5 TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/qa/social_trading_observability_probe.dart
```

```bash
cd app
flutter test integration_test/mobile_sentry_smoke_test.dart -d "iPhone 15" --dart-define=SENTRY_DSN=<staging> --dart-define=SENTRY_ENVIRONMENT=staging --reporter expanded --no-version-check
flutter test integration_test/fcm_staging_smoke_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --dart-define=SENTRY_DSN=<staging> --dart-define=SENTRY_ENVIRONMENT=staging --reporter expanded --no-version-check
```

Metricas do probe backend real, 5 amostras por endpoint:

| Endpoint | p50 | p95 | p99 | Min | Max |
| --- | ---: | ---: | ---: | ---: | ---: |
| `GET /community/marketplace` | `611ms` | `1485ms` | `1485ms` | `610ms` | `1485ms` |
| `POST /trades` | `3979ms` | `4258ms` | `4258ms` | `3976ms` | `4258ms` |
| `PUT /trades/:id/status` | `2783ms` | `3299ms` | `3299ms` | `2777ms` | `3299ms` |
| `GET /trades` | `630ms` | `1484ms` | `1484ms` | `610ms` | `1484ms` |
| `GET /trades/:id` | `1300ms` | `1346ms` | `1346ms` | `1210ms` | `1346ms` |
| `POST /trades/:id/messages` | `1227ms` | `1400ms` | `1400ms` | `1194ms` | `1400ms` |
| `POST /conversations/:id/messages` | `1195ms` | `1341ms` | `1341ms` | `1189ms` | `1341ms` |

Observabilidade provada:

- Backend Sentry real/staging inicializou e enviou smoke controlado.
- App Sentry real/staging enviou smoke controlado no iPhone 15 Simulator.
- Slow requests sociais geraram `api_slow_request` no app e `[http_observability] classification=slow_request` no backend.
- `400` esperado de payload invalido e `404` esperado de detalhe inexistente foram classificados como `client_error`.
- Timeout foi provado como `client_timeout` no probe cliente sem derrubar backend.
- Contrato JSON foi validado no probe; `contract_error status=not_triggered`.
- Logs finais foram varridos contra padroes obvios de JWT/email/body de auth; sem achados no runtime sanitizado.

Correcoes pequenas aplicadas nesta sprint:

- `AppObservability` mobile deixou de anexar email ao `SentryUser`.
- `PushNotificationService` mobile deixou de imprimir prefixo do FCM token.
- `AuthProvider` deixou de imprimir email completo, token e body de resposta de login.
- `server/lib/log_sanitizer.dart` passou a redigir email e `fcm_token`.
- Novo probe backend: `server/bin/qa/social_trading_observability_probe.dart`.
- Novo smoke iPhone: `app/integration_test/fcm_staging_smoke_test.dart`.

Pendencias:

| Prioridade | Item | Evidencia/Hipotese |
| --- | --- | --- |
| P1 | `POST /trades` p95/p99 `4258ms` | Ainda dominado por DB remoto/round-trips de trade + side effects diferidos |
| P1 | `PUT /trades/:id/status` p95/p99 `3299ms` | Validacoes transacionais/status e notificacoes diferidas ainda aparecem no caminho observado |
| P2 | FCM real entrega/recebimento | iPhone 15 Simulator nao obteve APNS token; requer device fisico/permissao APNS ou simulador com suporte/config validos |

## Resultado

Verdict: `Approved for BinderItemEditor CRUD + marketplace sale + full trade lifecycle + trade chat + notifications + direct messages runtime`

Execucao fresca final em `2026-04-29 17:10 -0300` no iPhone 15 Simulator contra backend local real em `http://127.0.0.1:8082`.

## Ambiente

| Item | Evidencia |
| --- | --- |
| Device primario | `iPhone 15` |
| Simulator id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Estado | `Booted` |
| Backend URL usado pelo app | `http://127.0.0.1:8082` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}` |
| Log PASS final | `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_binder_marketplace_trade/binder_marketplace_trade_runtime_after_sprint_pass.log` |
| Logs de tentativas | `binder_marketplace_trade_runtime_after_sprint_failed_attempt*.log` |

Resumo do `flutter devices`:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
macOS (desktop) • macos • darwin-arm64
Chrome (web) • chrome • web-javascript
Rafa (mobile) • 00008130-001C152922BA001C • ios • iOS 26.5 23F5043k
```

Resumo do `xcrun simctl list devices available | grep -E "iPhone 15|Booted"`:

```text
iPhone 15 Pro (...) (Shutdown)
iPhone 15 Pro Max (...) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (...) (Shutdown)
```

## Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8082/health
```

```bash
cd app
flutter test integration_test/binder_marketplace_trade_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Validacoes finais:

```bash
cd server
dart analyze routes/trades routes/market routes/binder routes/conversations routes/notifications lib test
dart test -r expanded
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded
```

```bash
cd app
flutter analyze lib/features/binder lib/features/market lib/features/trades lib/features/messages lib/features/notifications integration_test --no-version-check
flutter test test/features/binder test/features/trades test/features/messages test/features/notifications --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

## Dados de teste

Prefixos claros de QA: `qa_bmt_19ddadb15b4` para Binder/Marketplace/Trades e `qa_dm_19ddadc9d8f` para Direct Messages.

| Papel | Usuario |
| --- | --- |
| seller | `qa_bmt_19ddadb15b4_seller_6509ee7ccd9b6` |
| buyer | `qa_bmt_19ddadb15b4_buyer_6509ee7f63ea0` |
| trade criado | `80366433-a69c-4f1e-90d0-03c923c76f5b` |
| carta marketplace | `Sol Ring` |
| carta BinderItemEditor visual | `Command Tower` |
| conversa direta | `qa_dm_19ddace2aff` |

Os registros permanecem no backend real como dados marcados de QA (`qa_bmt_*`) para rastreabilidade.

## Matriz curta

| Tela/Provider | Endpoint | Teste existente | Runtime provado | Lacuna |
| --- | --- | --- | --- | --- |
| `BinderTabContent` / `BinderProvider` | `GET/POST/PUT/DELETE /binder`, `GET /binder/stats` | `binder_provider_test.dart`, `marketplace_screen_overflow_test.dart` | UI visual do `BinderItemEditor` criou `Command Tower`, editou quantidade/preco/condicao/idioma e removeu; backend confirmou `201/200/204` | Sem lacuna P1 neste fluxo |
| `MarketplaceTabContent` / `BinderProvider` | `GET /community/marketplace` | `marketplace_screen_overflow_test.dart` | UI buscou item seller real, validou listagem sem filtro e iniciou proposta | Latencia monitorada, mas dentro do runtime final: `664ms` sem filtro |
| `CreateTradeScreen` / `TradeProvider` | `POST /trades` | `create_trade_screen_overflow_test.dart` | UI criou venda a partir do Marketplace; API retornou `201` | Fluxo de troca pura com itens de ambos os lados nao foi provado |
| `TradeInboxTabContent` / `TradeProvider` | `GET /trades?role=sender/receiver` | testes de overflow + server live | UI exibiu `Enviadas` com trade pendente do buyer | Tap no card para detalhe via `GoRouter` nao foi exercitado no harness MaterialApp |
| `TradeDetailScreen` / `TradeProvider` | `GET /trades/:id`, `PUT /respond`, `PUT /status` | server live/error contract | UI seller aceitou e marcou enviado; UI buyer tocou `Confirmar Entrega` e `Finalizar`; backend final `completed` | Sem lacuna P1 neste fluxo |
| Trade messages | `GET/POST /trades/:id/messages` | server live/error contract | Chat visual enviou mensagem via input real; backend retornou `201`; UI buyer reabriu detalhe e exibiu a mensagem | Sem lacuna P1 neste fluxo |
| `NotificationScreen` / `NotificationProvider` | `GET /notifications`, `GET /notifications/count`, `PUT /notifications/:id/read`, `PUT /notifications/read-all` | `notification_models_test.dart` | UI exibiu notificacao de trade, tap navegou ao trade e marcou read; UI `Ler todas` chamou `read-all` e backend ficou com unread `0` | Sem lacuna P1 neste fluxo |
| `MessageProvider` direct messages | `/conversations*` | `message_models_test.dart`, server live/error contract | Runtime separado criou conversa, abriu chat visual, enviou mensagem, confirmou polling/read receipt e backend real | Sem lacuna P1 neste fluxo |

## O que foi provado por UI real no iPhone 15

- Login programatico via `AuthProvider` contra backend real para buyer e seller.
- `BinderItemEditor` visual criando, editando e removendo `Command Tower`.
- `CollectionScreen` -> `Fichario` exibindo item real e refresh de stats.
- `CollectionScreen` -> `Marketplace` buscando `Sol Ring` real.
- Marketplace -> `CreateTradeScreen` com item seller pre-selecionado.
- Criacao visual de proposta de venda (`Enviar Proposta`) com `POST /trades 201`.
- `Trades` -> `Enviadas` exibindo a proposta pendente.
- `TradeDetailScreen` como seller: `Pendente -> Aceito -> Enviado`.
- Chat visual de trade com mensagem enviada pelo input real.
- `TradeDetailScreen` como buyer: botao `Confirmar Entrega`, botao `Finalizar` e leitura de `Concluido`.
- `NotificationScreen` como buyer exibindo notificacao, tap com read individual e botao `Ler todas`.
- `ChatScreen` de mensagens diretas em runtime separado, com envio visual e read receipt.

## O que foi provado por API real

- Registro de dois usuarios de teste.
- Resolucao de carta por `GET /cards`.
- Binder CRUD autenticado: add, update e delete real via UI; delete retornando `204`.
- Marketplace global com item seller publicado.
- Criacao de trade por UI e leitura por API.
- Mensagem de trade por `POST /trades/:id/messages` via UI.
- Notificacoes geradas: `trade_offer_received`, `trade_accepted`, `trade_message`, `trade_shipped`, `trade_completed`.
- Notificacoes read/read-all: `PUT /notifications/:id/read` e `PUT /notifications/read-all`.
- Status final de trade: `completed`.
- Direct messages: `GET/POST /conversations`, `GET/POST /conversations/:id/messages`, `PUT /conversations/:id/read`.

## Mocked / controlado

- Nenhum backend mockado.
- O setup de dois usuarios e fixtures foi controlado por API HTTP real.
- Direct Messages (`/conversations`) nao sao disparadas pelo trade e foram provadas em runtime separado no mesmo arquivo.

## Bugs corrigidos

- `BinderProvider.removeItem` agora trata `204 No Content` como sucesso, alinhado ao contrato real de `DELETE /binder/:id`.
- Teste focado adicionado: `app/test/features/binder/providers/binder_provider_test.dart`.
- `TradeProvider.sendMessage` agora atualiza `chatMessages` de forma imutavel para reconstruir `_TradeChat` apos POST 201.
- `TradeDetailScreen` aceita envio de chat por `TextInputAction.send`, removendo dependencia de hit-test fragil do teclado/safe-area.
- `NotificationScreen` exibe `Ler todas` quando a lista carregada contem notificacoes nao lidas, mesmo antes do polling do badge.
- `MessageProvider.fetchMessages` ignora chamadas sobrepostas por conversa, evitando timeouts de polling quando o backend esta lento.
- `ChatScreen` ajustou padding inferior para safe-area em vez de `viewInsets.bottom`, eliminando overflow subpixel com teclado.

## Observacoes e riscos

- O runtime PASS final registrou chamadas lentas mas instrumentadas:
  - `GET /community/marketplace?page=1&limit=20`: `664ms`;
  - `GET /trades?page=1&limit=20`: `608ms-633ms`;
  - `GET /trades/:id`: ~`1202ms-1253ms`;
  - `POST /trades`: `5165ms`;
  - `PUT /trades/:id/respond`: `3205ms`;
  - `PUT /trades/:id/status`: `3941ms-3995ms`;
  - `POST /trades/:id/messages`: `2403ms`;
  - `POST /conversations/:id/messages`: `3047ms`.
- App Sentry/observabilidade: requests lentos geraram breadcrumb `api_slow_request` com metodo, endpoint, status, duracao e request ids, sem payload sensivel. HTTP 4xx/5xx agora tambem e reportavel pelo `ApiClient`.
- Backend Sentry/log estruturado: rotas tocadas (`binder`, `community/marketplace`, `trades`, `conversations`, `notifications`) capturam excecoes via `captureRouteException` com operacao/ids tecnicos e sem dados sensiveis.
- Warning conhecido de MLKit sem arm64 para simuladores Apple Silicon iOS 26+ apareceu no build, mas nao impediu o iPhone 15 iOS 17.4.

## Sprint final de performance/observabilidade social trading - 2026-04-29 17:37 -0300

Resultado: `Approved after performance sprint`. O mesmo runtime iPhone 15 passou novamente contra backend real `http://127.0.0.1:8082`, com melhorias mensuraveis nas escritas sociais sem alterar contrato JSON/status codes.

| Item | Evidencia |
| --- | --- |
| Device primario | `iPhone 15` |
| Simulator id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Estado | `Booted` |
| Backend URL usado pelo app | `http://127.0.0.1:8082` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}` |
| Log PASS social perf | `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_binder_marketplace_trade/binder_marketplace_trade_runtime_social_perf_pass.log` |

Comando iPhone 15 executado:

```bash
cd app
flutter test integration_test/binder_marketplace_trade_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Resultado: `01:53 +2: All tests passed!`

### Baseline antes da mudanca

Medição real em `8082` antes de alterar codigo, com payloads sanitizados e usuarios `qa_perf_bb17c499a1_*`:

| Endpoint | Frio | Quente | Status |
| --- | ---: | ---: | --- |
| `POST /trades` | `5324.62ms` | `6167.93ms` | `201` |
| `PUT /trades/:id/status` | `4061.75ms` | `4060.68ms` | `200` |
| `POST /trades/:id/messages` | `2440.10ms` | `2443.68ms` | `201` |
| `POST /conversations/:id/messages` | `3058.88ms` | `3043.00ms` | `201` |

Classificacao de erro descoberta durante baseline: `delivery_method=mail` gerava `500` por violar o `CHECK` do banco. O contrato valido aceita `correios`, `motoboy`, `pessoalmente` ou `outro`; a rota agora valida antes do DB e retorna `400` com log `invalid_payload`.

### Depois da otimizacao

Medição final com backend reiniciado e codigo novo, usuarios `qa_perf_final_f3357696e1_*`:

| Endpoint | Frio | Quente | Melhora |
| --- | ---: | ---: | ---: |
| `POST /trades` | `4123.00ms` | `4941.76ms` | `22.6%` frio / `19.9%` quente |
| `PUT /trades/:id/status` | `2844.34ms` | `2845.01ms` | `30.0%` frio / `29.9%` quente |
| `POST /trades/:id/messages` | `1222.30ms` | `1228.63ms` | `49.9%` frio / `49.7%` quente |
| `POST /conversations/:id/messages` | `1238.07ms` | `1233.96ms` | `59.5%` frio / `59.4%` quente |

Runtime UI final no iPhone 15 confirmou os ganhos em fluxo real:

- `POST /trades`: `3978ms` (`201`);
- `PUT /trades/:id/status`: `2811ms`, `2786ms`, `2876ms` (`200`);
- `POST /trades/:id/messages`: `1233ms` (`201`);
- `POST /conversations/:id/messages`: `1219ms` (`201`).

### Mudancas tecnicas

- `NotificationService.createFromActorDeferred` moveu a resolucao de nome do ator, insert em `notifications` e FCM para fire-and-forget controlado com timeout de 10s, logs de `slow_deferred` e captura Sentry em falha.
- `POST /conversations/:id/messages` passou a inserir mensagem e atualizar `last_message_at` em um unico CTE SQL.
- `POST /trades` e `PUT /trades/:id/status` validam `payment_method`/`delivery_method` antes de tocar o banco, convertendo violacoes previsiveis em `400`.
- Middleware raiz registra slow requests e 4xx/5xx com `endpoint`, duracao, status, request id e user id tecnico quando autenticado; captura Sentry e deferida para nao voltar ao caminho critico.
- `server/test/social_trading_live_test.dart` entrou no preset live e cobre sucesso dos endpoints tocados, contratos JSON, `400` esperados e side effects essenciais de notificacao.

### Observabilidade provada

- Logs estruturados vistos em `server`:
  - `[http_observability] classification=slow_request endpoint=POST /trades ... user_id=<uuid>`;
  - `[http_observability] classification=client_error endpoint=PUT /trades/:id/status status=400 ... user_id=<uuid>`;
  - `[social_write] invalid_payload ... trade_id=<uuid>`;
  - `[social_notification] slow_deferred ... type=trade_message/direct_message`.
- App continuou gerando breadcrumbs `api_slow_request` com metodo, endpoint, status, duracao e request ids, sem payload sensivel.
- FCM real externo continua `not proven` no simulador; o backend carregou service account local e o app manteve fallback esperado de Firebase Performance sem Firebase App inicializado no runtime.

## Pendencias

| Prioridade | Item | Owner |
| --- | --- | --- |
| P1/P2 | Monitorar leituras de detalhe/mensagens em ~`1.1s-1.7s` e promover a P1 se houver impacto perceptivel na UX | Backend social/trades |
| P2 | Criar metricas p95/p99 persistentes para social trading e alertas por endpoint | Backend observability |
| P2 | Provar FCM real em device/config staging; nao foi escopo do simulador sem Firebase inicializado | App notifications |
