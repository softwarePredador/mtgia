# ManaLoom Sentry Project Setup

Data: 2026-07-01
Status: `SENTRY_MOBILE_INGESTION_CONFIRMED`

## Projeto criado

| Campo | Valor |
|---|---|
| Organizacao | `rafa-pz` |
| Time | `rafa` |
| Projeto | `manaloom` |
| Project ID | `4511661329350656` |
| Plataforma | `flutter` |

O token recebido foi usado apenas em ambiente local e nao foi versionado.

## Aplicacao local

O arquivo `server/.env` local foi atualizado com:

- `SENTRY_AUTH_TOKEN`
- `SENTRY_ORG_SLUG=rafa-pz`
- `SENTRY_TEAM_SLUG=rafa`
- `SENTRY_BACKEND_PROJECT_SLUG=manaloom`
- `SENTRY_MOBILE_PROJECT_SLUG=manaloom`
- `SENTRY_DSN`
- `SENTRY_MOBILE_DSN`
- `SENTRY_ENVIRONMENT=staging`
- `SENTRY_RELEASE=manaloom-sentry-setup-2026-07-01`
- `SENTRY_TRACES_SAMPLE_RATE=1.0`

`server/.env` esta ignorado pelo git via `server/.gitignore`.

## Evidencia de ingestao mobile

Comando:

```sh
MOBILE_SENTRY_BUILD_TIMEOUT_SECONDS=600 ./scripts/validate_sentry_mobile_ingestion.sh \
  -d R58T300SREH \
  --no-version-check \
  --reporter expanded
```

Resultado:

- Build Android debug gerado e instalado no `SM A135M` (`R58T300SREH`).
- `mobile_sentry_smoke_test.dart`: PASS.
- Sentry inicializou apos o primeiro frame.
- `SENTRY_MOBILE_EVENT_ID=6f2080bf844d471588c1cc3dc852fc83`
- `SENTRY_MOBILE_SMOKE_TAG=smoke_id:mtgia-mobile-smoke-19f1ed84135`
- Consulta API Sentry confirmou:
  - `SENTRY_MOBILE_GROUP_ID=7587662734`
  - mesmo `event_id`
  - mesma tag `smoke_id`

## Evidencia de release observability smoke

Comando:

```sh
flutter test integration_test/release_observability_smoke_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_DSN=<local-sentry-mobile-dsn> \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=manaloom-sentry-setup-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check \
  --reporter expanded
```

Resultado:

- `SENTRY_RELEASE_SMOKE_RESULT=captured`
- `SENTRY_RELEASE_DSN_CONFIGURED=true`
- `SENTRY_RELEASE_READY=true`
- `FIREBASE_PERFORMANCE_SMOKE_RESULT=initialized`
- `FIREBASE_PERFORMANCE_COLLECTION_ENABLED=true`
- `All tests passed`

## Correção aplicada nos smokes

Os testes de Sentry agora aguardam `AppObservability.isReadyForTesting` antes
de capturar o evento. Sem isso, o DSN podia estar configurado, mas o smoke
tentava capturar cedo demais e emitia `event_id=null`.

Arquivos:

- `app/integration_test/mobile_sentry_smoke_test.dart`
- `app/integration_test/release_observability_smoke_test.dart`

## Pendencia restante

Para o release publico, o mesmo DSN precisa ser injetado no build assinado de
distribuicao. O blocker de DSN/ingestao mobile esta fechado para staging/device;
o blocker de signing e aceite final assinado continua aberto.
