# Binder / Marketplace / Trades Runtime - iPhone 15 Simulator - 2026-04-29

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

## Pendencias

| Prioridade | Item | Owner |
| --- | --- | --- |
| P1 | Reduzir latencia residual de escrita em `POST /trades`, `PUT /trades/:id/status`, `POST /trades/:id/messages` e `POST /conversations/:id/messages` | Backend social/trades |
| P2 | Criar metricas p95/p99 persistentes para social trading e alertas por endpoint | Backend observability |
| P2 | Provar FCM real em device/config staging; nao foi escopo do simulador sem Firebase inicializado | App notifications |
