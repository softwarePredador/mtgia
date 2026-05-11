# Relatorio Realtime Notifications & Badges - 2026-05-11

## Status

Resultado: **PASS** para Android FCM real no `SM A135M` e **PASS WITH RISKS**
para iPhone 15 Simulator, onde APNs/FCM real segue dependente de provisioning.

### Atualizacao Android FCM real - 2026-05-11

- Device: `SM A135M`, adb `R58T300SREH`, Android 14/API 34.
- Backend publico:
  `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Backend `/health`: `healthy`,
  `git_sha=70303922a57bd1d2f91115f5cb5977ee8c3c123d`.
- Foreground real: `direct_message` entregue via FCM, callback recebido e
  badge/lista/inbox atualizados.
- Background/tap real: app enviado para home, novo evento criado via segundo
  usuario QA/API publica, notificacao Android chegou no canal
  `manaloom_notifications`, tap navegou para `/messages/:conversationId`.
- Ajustes app-side: `POST_NOTIFICATIONS`, canal nativo
  `manaloom_notifications` e harness host-assisted para background real.
- Handoff:
  `app/doc/runtime_flow_handoffs/push_delivery_android_sm_a135m_2026-05-11.md`.

## Escopo

- Notificacoes, badges, mensagens, trades, FCM foreground/tap e polling
  complementar.
- Scanner/camera/OCR, IA, meta pipeline e regras de negocio fora dos eventos de
  notificacao ficaram fora do escopo.
- Nenhum secret, token, JWT, `DATABASE_URL`, Sentry DSN, OpenAI key ou service
  account foi documentado ou exposto.

## Contrato app/backend

- `notifications` permanece a fonte de verdade para badge/lista.
- FCM usa payload de dados minimo e nao sensivel:
  - `type`
  - `reference_id`
- Tipos app-facing atuais:
  - `new_follower`
  - `trade_offer_received`
  - `trade_accepted`
  - `trade_declined`
  - `trade_shipped`
  - `trade_delivered`
  - `trade_completed`
  - `trade_message`
  - `direct_message`
- Rotas por tap:
  - `new_follower` -> `/community/user/:userId`
  - `trade_*` e `trade_message` -> `/trades/:tradeId`
  - `direct_message` -> `/messages/:conversationId`

## Implementacao

- App:
  - `RealtimeNotificationCoordinator` trata foreground/tap por payload puro,
    atualizando providers e navegando sem depender de selectors frageis.
  - `NotificationProvider` ganhou refresh realtime de badge e lista ja carregada.
  - `MessageProvider` rastreia conversa ativa e atualiza inbox, unread e chat
    ativo em `direct_message`.
  - `TradeProvider` rastreia trade ativo e atualiza detalhe completo em eventos
    `trade_*`, incluindo status/timeline/mensagens.
  - `NotificationScreen`, `MessageInboxScreen` e `TradeDetailScreen` mantem
    polling leve complementar quando o push nao chega.
  - `PushNotificationService` preserva tap inicial pendente ate o callback estar
    conectado, suprime foreground banner duplicado e registra token sem bloquear
    o boot visual.
- Backend:
  - `NotificationService.create` grava DB antes e dispara FCM com `unawaited`.
  - Follow usa criacao deferida padronizada.
  - Teste live social/trading passou a exigir `reference_id` para eventos de
    trade/message e cobertura de `trade_delivered`/`trade_completed`.

## Validacao local

- `cd server && dart analyze routes/notifications routes/conversations routes/trades routes/users lib test`: PASS.
- `cd app && flutter analyze lib test integration_test --no-version-check`: PASS.
- Provider/unit focados app:
  - `test/core/services/realtime_notification_coordinator_test.dart`
  - `test/features/notifications/models/notification_models_test.dart`
  - `test/features/messages/providers/message_provider_test.dart`
  - `test/features/trades/providers/trade_provider_test.dart`
  - Resultado: PASS.
- `cd app && flutter test test --no-version-check`: PASS (`559` tests).
- `TEST_API_BASE_URL=http://127.0.0.1:8081 dart test -P live test/social_trading_live_test.dart --reporter expanded`: PASS (`169` tests, `3` skipped).

## Prova runtime iPhone 15 Simulator

- Simulator: `iPhone 15`, id `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`,
  runtime `iOS 17.4`.
- Backend local: `http://127.0.0.1:8081`.
- Comando:

```bash
cd app
flutter test integration_test/realtime_notifications_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=DISABLE_PUSH_INIT=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

- Resultado: PASS (`00:37 +1: All tests passed!`).
- Real: UI Flutter no iPhone 15 Simulator + backend local + dois usuarios QA.
- Simulado: entrega APNs/FCM real. O teste injeta no coordenador o mesmo payload
  FCM app-facing (`type`, `reference_id`) para provar foreground/tap sem depender
  de provisioning.
- Handoff:
  `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-05-11.md`.

## Riscos / pendencias

- FCM real depende de configuracao APNs/Firebase do ambiente; quando ausente, o
  app continua coberto por polling e DB notifications.
- Badge de icone do sistema iOS segue best-effort do FCM; a garantia funcional
  deste sprint e badge in-app/listas contextuais.
