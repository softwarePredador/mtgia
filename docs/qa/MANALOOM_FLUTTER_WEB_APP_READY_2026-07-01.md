# ManaLoom Flutter Web App Ready

Data: 2026-07-01
Status: `APP_WEB_BASE_READY`

## Escopo

Inicio da frente Flutter Web para funcionar como app logado em `/app`, em
paralelo ao React/Next publico.

## Entregas

- Build Flutter Web validado com `--base-href /app/`.
- Fallback web para o contador Lotus/WebView, evitando quebra de runtime no
  navegador.
- Helper local `app/tool/serve_flutter_web_app.py` para servir o bundle em
  `/app/` com fallback SPA.
- Runbook em `app/doc/FLUTTER_WEB_APP_RUNBOOK_2026-07-01.md`.

## Comandos executados

```sh
flutter build web --base-href /app/
python3 -m py_compile tool/serve_flutter_web_app.py
flutter test test/core/widgets/platform_unavailable_screen_test.dart
flutter analyze
python3 tool/serve_flutter_web_app.py --port 8088
curl -I http://127.0.0.1:8088/app/
curl -I http://127.0.0.1:8088/app/main.dart.js
curl -I http://127.0.0.1:8088/app/decks
curl -s http://127.0.0.1:8088/app/ | rg '<base href="/app/">|flutter_bootstrap.js|ManaLoom'
git diff --check -- app/lib/core/widgets/platform_unavailable_screen.dart app/lib/main.dart app/tool/serve_flutter_web_app.py app/doc/FLUTTER_WEB_APP_RUNBOOK_2026-07-01.md app/test/core/widgets/platform_unavailable_screen_test.dart docs/qa/MANALOOM_FLUTTER_WEB_APP_READY_2026-07-01.md
```

Resultados:

- `flutter build web --base-href /app/`: PASS.
- `python3 -m py_compile tool/serve_flutter_web_app.py`: PASS.
- `flutter test test/core/widgets/platform_unavailable_screen_test.dart`: PASS.
- `flutter analyze`: PASS, sem issues.
- `curl` local: `/app/`, `/app/main.dart.js` e `/app/decks` retornaram `200`.
- HTML local contem `<base href="/app/">` e `flutter_bootstrap.js`.

## Observacoes

- O build web compila a base atual do app.
- O deploy deve servir `app/build/web` sob `/app/`.
- O React publico deve apontar CTAs iniciais para `/app`.
- Links profundos devem aguardar QA do proxy final.
- Nenhuma mudanca em PostgreSQL foi feita.

## Atualizacao - Login Web E RangeError

Data: 2026-07-01

Problema reproduzido no browser local:

- URL: `http://127.0.0.1:8088/app/#/login`
- Ao enviar login, o app falhava antes de sair o HTTP.
- Log: `RangeError: max must be in range 0 < max ≤ 2^32, was 0`
- Causa: `ApiClient.generateRequestId()` usava `Random.nextInt(1 << 32)`;
  no build Flutter Web esse limite chegou como `0`.

Correcao aplicada:

- `ApiClient.generateRequestId()` agora gera entropia em dois blocos de 16 bits
  (`0x10000` + `0x10000`), evitando `nextInt(0)` no web.
- `AuthProvider.initialize()` ficou idempotente e passou a ser chamado no boot
  do app, cobrindo deep link direto em `#/login`.
- `AuthProvider.register()` recebeu logs sanitizados equivalentes ao login.
- `AppObservability.bootstrap()` registra explicitamente quando Sentry esta
  desabilitado por falta de `SENTRY_DSN`.

Comandos reexecutados:

```sh
flutter test test/core/api/api_client_request_id_test.dart test/features/auth/providers/auth_provider_log_sanitization_test.dart test/core/observability/app_observability_test.dart test/core/widgets/platform_unavailable_screen_test.dart
flutter analyze
flutter build web --base-href /app/
curl -I http://127.0.0.1:8088/app/
curl -I http://127.0.0.1:8088/app/main.dart.js
```

Resultados:

- Testes focados: PASS (`16` testes).
- `flutter analyze`: PASS, sem issues.
- `flutter build web --base-href /app/`: PASS.
- `/app/` e `/app/main.dart.js`: `200`.

Smoke no browser embutido:

- Boot direto em `#/login`: `AuthProvider.initialize()` executou, status final
  `AuthStatus.unauthenticated`, sem `RangeError` e sem console error.
- Login com conta QA gerada: `POST /auth/login → 200`, status
  `authenticated`, redirect para `#/home`.
- Home pos-login: `/notifications/count`, `/conversations/unread-count` e
  `/decks` retornaram `200`.
- Reload em `#/login` com token salvo: `GET /auth/me → 200`, token valido,
  redirect para `#/home`.

Estado Sentry neste build local:

- Codigo esta preparado para Sentry via `SENTRY_DSN`, `SENTRY_ENVIRONMENT` e
  `SENTRY_RELEASE`.
- Neste shell local, `SENTRY_DSN`, `SENTRY_MOBILE_DSN` e `SENTRY_AUTH_TOKEN`
  estavam ausentes.
- Portanto, ingestao Sentry web real nao foi validada neste build local; o
  runtime confirmou o estado esperado: `Sentry desabilitado: SENTRY_DSN vazio`.
