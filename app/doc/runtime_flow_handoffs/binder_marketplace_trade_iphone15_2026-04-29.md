# Binder / Marketplace / Trades Runtime - iPhone 15 Simulator - 2026-04-29

## Resultado

Verdict: `Approved for binder -> marketplace -> trade sale runtime path / buyer delivered-completed buttons not visually proven`

Execucao fresca em `2026-04-29 15:30 -0300` no iPhone 15 Simulator contra backend local real em `http://127.0.0.1:8082`.

## Ambiente

| Item | Evidencia |
| --- | --- |
| Device primario | `iPhone 15` |
| Simulator id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Estado | `Booted` |
| Backend URL usado pelo app | `http://127.0.0.1:8082` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}` |
| Log PASS | `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator_binder_marketplace_trade/binder_marketplace_trade_runtime_pass.log` |
| Outros logs historicos da tentativa | `binder_marketplace_trade_runtime.log`, `binder_marketplace_trade_runtime_rerun.log`, `binder_marketplace_trade_runtime_final.log` |

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

Validacoes focadas:

```bash
cd server
dart analyze routes/binder routes/community routes/trades routes/conversations routes/notifications lib test
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/error_contract_test.dart -P live
dart test
```

```bash
cd app
flutter analyze lib/features/binder lib/features/market lib/features/trades lib/features/messages lib/features/notifications lib/features/collection test/features/binder test/features/trades test/features/messages test/features/notifications integration_test --no-version-check
flutter test test/features/binder test/features/trades test/features/messages test/features/notifications --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

## Dados de teste

Prefixo claro de QA: `qa_bmt_19dda7ad00b`.

| Papel | Usuario |
| --- | --- |
| seller | `qa_bmt_19dda7ad00b_seller_6509d6fbcc58c` |
| buyer | `qa_bmt_19dda7ad00b_buyer_6509d6fe91eb7` |
| trade criado | `744f4e67-4f48-44e4-b5a3-989fdfc98b60` |
| carta marketplace | `Sol Ring` |
| carta binder buyer | `Arcane Signet` |

Os registros permanecem no backend real como dados marcados de QA (`qa_bmt_*`) para rastreabilidade.

## Matriz curta

| Tela/Provider | Endpoint | Teste existente | Runtime provado | Lacuna |
| --- | --- | --- | --- | --- |
| `BinderTabContent` / `BinderProvider` | `GET/POST/PUT/DELETE /binder`, `GET /binder/stats` | `binder_provider_test.dart`, `marketplace_screen_overflow_test.dart` | API CRUD autenticado real; UI abriu Fichario e exibiu `Arcane Signet` do buyer | Add/edit/delete visual via modal nao foi exercitado neste runtime |
| `MarketplaceTabContent` / `BinderProvider` | `GET /community/marketplace` | `marketplace_screen_overflow_test.dart` | API marketplace encontrou item seller; UI buscou `Sol Ring`, exibiu seller e abriu criacao de proposta | Unfiltered marketplace ainda registrou chamada lenta de `2049ms` |
| `CreateTradeScreen` / `TradeProvider` | `POST /trades` | `create_trade_screen_overflow_test.dart` | UI criou venda a partir do Marketplace; API retornou `201` | Fluxo de troca pura com itens de ambos os lados nao foi provado |
| `TradeInboxTabContent` / `TradeProvider` | `GET /trades?role=sender/receiver` | testes de overflow + server live | UI exibiu `Enviadas` com trade pendente do buyer | Tap no card para detalhe via `GoRouter` nao foi exercitado no harness MaterialApp |
| `TradeDetailScreen` / `TradeProvider` | `GET /trades/:id`, `PUT /respond`, `PUT /status` | server live/error contract | UI seller abriu detalhe, aceitou e marcou enviado; UI buyer reabriu detalhe e leu `Concluido` | Botao buyer `Confirmar Entrega` nao foi visualmente provado; `delivered -> completed` foi API real |
| Trade messages | `GET/POST /trades/:id/messages` | server live/error contract | API real criou mensagem de trade e disparou notificacao | Campo visual de chat no detalhe nao foi exercitado no PASS final |
| `NotificationScreen` / `NotificationProvider` | `GET /notifications`, `GET /notifications/count` | `notification_models_test.dart` | UI buyer abriu notificacoes e leu notificacao de aceite; API confirmou tipos de trade | `read/read-all` visual nao foi exercitado |
| `MessageProvider` direct messages | `/conversations*` | `message_models_test.dart`, server live/error contract | Not triggered by trade; nao aplicavel a este fluxo | Inbox/chat direto continua fora deste runtime |

## O que foi provado por UI real no iPhone 15

- Login programatico via `AuthProvider` contra backend real para buyer e seller.
- `CollectionScreen` -> `Fichario` exibindo item real do buyer.
- `CollectionScreen` -> `Marketplace` buscando `Sol Ring` real.
- Marketplace -> `CreateTradeScreen` com item seller pre-selecionado.
- Criacao visual de proposta de venda (`Enviar Proposta`) com `POST /trades 201`.
- `Trades` -> `Enviadas` exibindo a proposta pendente.
- `TradeDetailScreen` como seller: `Pendente -> Aceito -> Enviado`.
- `TradeDetailScreen` como buyer apos fechamento por API: leitura de `Concluido`.
- `NotificationScreen` como buyer exibindo notificacao de aceite.

## O que foi provado por API real

- Registro de dois usuarios de teste.
- Resolucao de carta por `GET /cards`.
- Binder CRUD autenticado: add, update e delete real; delete retornando `204`.
- Marketplace global com item seller publicado.
- Criacao de trade por UI e leitura por API.
- Mensagem de trade por `POST /trades/:id/messages`.
- Notificacoes geradas: `trade_offer_received`, `trade_accepted`, `trade_message`, `trade_shipped`, `trade_completed`.
- Status final de trade: `completed`.

## Mocked / controlado

- Nenhum backend mockado.
- O setup de dois usuarios e fixtures foi controlado por API HTTP real.
- Direct Messages (`/conversations`) nao foram disparadas por trade e ficaram fora da prova.

## Bugs corrigidos

- `BinderProvider.removeItem` agora trata `204 No Content` como sucesso, alinhado ao contrato real de `DELETE /binder/:id`.
- Teste focado adicionado: `app/test/features/binder/providers/binder_provider_test.dart`.

## Observacoes e riscos

- O runtime PASS registrou chamadas lentas:
  - `GET /community/marketplace?page=1&limit=20`: `2049ms`;
  - `POST /trades`: `5293ms`;
  - `PUT /trades/:id/status`: `4097ms`;
  - `GET /trades/:id`: ~`2440ms-2468ms`.
- Warning conhecido de MLKit sem arm64 para simuladores Apple Silicon iOS 26+ apareceu no build, mas nao impediu o iPhone 15 iOS 17.4.

## Pendencias

| Prioridade | Item | Owner |
| --- | --- | --- |
| P1 | Provar visualmente add/edit/delete do `BinderItemEditor` no iPhone 15 | App binder |
| P1 | Provar botao buyer `Confirmar Entrega` / `Finalizar` por UI ou corrigir harness/visibilidade se reproduzir manualmente | App trades |
| P1 | Medir e otimizar latencia de `/trades`, `/trades/:id`, `/trades/:id/status` e marketplace sem filtro | Backend social/trades |
| P2 | Provar chat visual de trade e `read/read-all` de notificacoes | App trades/notifications |
| P2 | Criar runtime separado para direct messages (`/conversations`) entre dois usuarios | App messages/backend conversations |

