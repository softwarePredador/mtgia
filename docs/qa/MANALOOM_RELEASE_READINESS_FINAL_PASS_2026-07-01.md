# ManaLoom Release Readiness - Final Pass

Data: 2026-07-01
Backend alvo: `https://evolution-cartinhas.8ktevp.easypanel.host`
Dispositivo Android: `SM A135M`, id `R58T300SREH`, Android 14/API 34

## Veredito

Status para teste interno: `READY_WITH_RELEASE_BLOCKERS`.

Status para release publico/comercial: `NO-GO`.

O produto esta pronto para teste interno com backend publico, APK release local
instalado em Android fisico e smokes controlados passando. O release publico
ainda depende de tres itens formais: Sentry mobile configurado/confirmado,
assinatura Android/iOS de distribuicao e aceite final em build assinado.

## Evidencias finais

### Backend publico

- `GET /health`, `GET /ready`, `GET /cards?limit=1`: HTTP 200.
- `/ready` preservou `x-request-id` manual.
- `cards_data.card_count=34331`.
- Busca publica retornou `Sol Ring` e `Command Tower`.

### Testes locais e contratos

- `flutter analyze`: sem issues.
- App focado Etapa 1: 76 testes passaram.
- Backend focado Etapa 1: 40 testes passaram.
- App core Etapa 2: 72 testes passaram.
- App details/import/optimize: 65 testes passaram.
- Backend completo: 625 testes passaram, 9 skips.
- Observabilidade local app/backend: 15 testes passaram no total documentado.
- Export/pricing/community contract: 3 testes passaram.

### Backend publico com escrita controlada

Comando:

```bash
cd server
TEST_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host dart test -t live --concurrency=1 \
  test/auth_flow_integration_test.dart \
  test/import_to_deck_flow_test.dart \
  test/core_flow_smoke_test.dart \
  -r expanded
```

Resultado:

- Auth live: 2 testes passaram.
- Import live: 6 testes passaram.
- Core flow live: 2 testes passaram.

Observacao:

- Os testes usam usuarios unicos.
- Decks criados pelos smokes foram removidos no `tearDown`.
- Usuarios de teste podem permanecer como residuo de QA.

### Smoke mobile Android

Comando:

```bash
cd app
flutter test integration_test/localized_import_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --no-version-check \
  --reporter expanded
```

Resultado:

- `All tests passed`.
- `POST /auth/register -> 201`.
- `POST /import/validate -> 200`.
- `POST /import -> 200`.
- `DELETE /decks/f4d529aa-abdc-41fd-90c3-4316d34e1deb -> 204`.
- `found_count=12`.
- `localized_matches_count=9`.
- `commander_detected=true`.
- `missing_commander=false`.

### Artefatos Android

Comandos:

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=mtgia-ready-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=mtgia-ready-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check
```

Artefatos:

- `app/build/app/outputs/flutter-apk/app-release.apk`
  - timestamp: `2026-07-01 10:50:55`
  - bytes: `114044826`
- `app/build/app/outputs/bundle/release/app-release.aab`
  - timestamp: `2026-07-01 10:51:16`
  - bytes: `75806976`

Instalacao/abertura:

```bash
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
adb -s R58T300SREH shell monkey -p com.mtgia.mtg_app -c android.intent.category.LAUNCHER 1
adb -s R58T300SREH shell pidof com.mtgia.mtg_app
```

Resultado:

- Instalacao: `Success`.
- App abriu no Android fisico.
- `pidof` final: `21012`.

Assinatura:

- `apksigner verify --print-certs` confirmou certificado
  `C=US, O=Android, CN=Android Debug`.
- `app/android/key.properties` nao existe neste ambiente.

### Observabilidade mobile

Comando:

```bash
cd app
flutter test integration_test/release_observability_smoke_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=mtgia-ready-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check \
  --reporter expanded
```

Resultado:

- `All tests passed`.
- `SENTRY_RELEASE_SMOKE_RESULT=not_configured`.
- `SENTRY_RELEASE_DSN_CONFIGURED=false`.
- `FIREBASE_PERFORMANCE_SMOKE_RESULT=initialized`.
- `FIREBASE_PERFORMANCE_COLLECTION_ENABLED=true`.

## Bloqueios restantes

1. `BLOCKED_BY_DSN`: configurar `SENTRY_DSN` ou `SENTRY_MOBILE_DSN` por canal
   seguro e confirmar ingestao real de evento mobile.
2. `BLOCKED_BY_SIGNING`: criar `app/android/key.properties` com keystore real
   fora do git e rebuildar AAB/APK de distribuicao.
3. `BLOCKED_BY_IOS_SIGNING`: executar build iOS/TestFlight assinado se iOS for
   alvo do release.
4. `BLOCKED_BY_FINAL_ACCEPTANCE`: rodar aceite final em build assinado:
   login/register, import/generate, details, optimize/apply, export/share.
5. `BLOCKED_BY_COMMERCIAL_POLICY`: finalizar monetizacao, paywall/limites de IA
   e revisao de Fan Content Policy antes de oferta paga.

## Estado dos documentos

- Etapa 1:
  `docs/qa/MANALOOM_PRODUCT_DIAGNOSTIC_STAGE1_2026-07-01.md`
- Tracker:
  `docs/qa/MANALOOM_GOAL_STAGE1_2_3_TRACKER_2026-07-01.md`
- Etapa 2:
  `docs/qa/MANALOOM_STAGE2_CORE_RELEASE_READINESS_2026-07-01.md`
- Etapa 3:
  `docs/qa/MANALOOM_STAGE3_OBSERVABILITY_READINESS_2026-07-01.md`
