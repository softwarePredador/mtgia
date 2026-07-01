# ManaLoom Stage 3 - Observability And Release Readiness

Data: 2026-07-01
Escopo: Etapa 3 do goal de produto - confiabilidade tecnica, rastreabilidade e smoke de release.
Status da etapa: avaliada, com bloqueios objetivos para release publico.

## 1. Veredito atual

O app ja tem base tecnica para teste interno: `x-request-id` no cliente esta
coberto por teste unitario, scanner esta desligado por flag no release default,
backend preserva request-id em probes publicos, e Android compila debug,
release APK e release AAB contra a API publica.

Ainda nao e possivel declarar release publico confiavel porque faltam:

- smoke instalado/executado em device ou simulator com API publica/staging;
- confirmacao de evento Sentry mobile real no build alvo;
- keystore Android real para assinar AAB de distribuicao;
- build iOS/TestFlight assinado;
- decisao final de push, monetizacao e Fan Content Policy.

Classificacao:

- Observabilidade de contrato local: `PASS`.
- Backend publico read-only observability probes: `PASS`.
- Build Android tecnico: `PASS_COMPILE_UNSIGNED`.
- Release publico: `NO-GO`.

## 2. Evidencias executadas

### Request-id no app

Comando:

```bash
cd app
flutter test test/core/api/api_client_request_id_test.dart --no-version-check
```

Resultado:

- `6` testes passaram.
- GET envia `x-request-id` e guarda eco do backend.
- HTTP 503 preserva `requestId` mobile e `responseRequestId` do backend.

Limite:

- Ainda falta smoke app real mostrando o request-id no caminho app -> backend ->
  log/breadcrumb.

### Suite Flutter completa

Comando:

```bash
cd app
flutter test test --no-version-check --reporter compact
```

Resultado:

- `626` testes passaram.

### Analise estatica Flutter

Comando:

```bash
cd app
flutter analyze lib test --no-version-check
```

Resultado:

- `No issues found`.

### Build Android com API publica

Comandos:

```bash
cd app
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --no-version-check

flutter build apk --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --no-version-check

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --no-version-check
```

Resultado:

- `build/app/outputs/flutter-apk/app-debug.apk`, `237M`, gerado em `2026-07-01 10:07:28`.
- `build/app/outputs/flutter-apk/app-release.apk`, `110M`, gerado em `2026-07-01 10:07:55`.
- `build/app/outputs/bundle/release/app-release.aab`, `74M`, gerado em `2026-07-01 10:08:28`.
- `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`
  retornou `C=US, O=Android, CN=Android Debug`.

Limite:

- Build compila, mas nao esta assinado para loja.
- Build nao foi instalado/executado neste fechamento.

### Backend publico read-only

Evidencia consolidada das Etapas 1 e 2:

- `GET /health`, `GET /ready` e `GET /cards?limit=1` responderam HTTP 200.
- `/ready` preservou `x-request-id` manual.
- Banco publico reportou `cards_data.card_count=34331`.
- `GET /cards?name=Sol%20Ring&limit=1` e
  `GET /cards?name=Command%20Tower&limit=1` retornaram cartas esperadas.

### Scanner

Status:

- Scanner esta fora do release default por flag:
  `LaunchFeatures.scannerEnabled = bool.fromEnvironment('ENABLE_SCANNER_RELEASE', defaultValue: false)`.
- Entradas de scanner foram escondidas em deck add-card menu e binder.
- Rota `/scan` redireciona para `/search` quando a flag esta desligada.

Limite:

- Reativar scanner exige sprint fisica de camera/OCR/permissao.

### Secret/log scan

Comando de escopo de codigo/config:

```bash
rg -l -I \
  -e 'sk-[A-Za-z0-9_-]{20,}' \
  -e 'postgres(ql)?://' \
  -e 'Bearer [A-Za-z0-9._-]{20,}' \
  -e 'storePassword\s*=' \
  -e 'keyPassword\s*=' \
  -e 'SENTRY_AUTH_TOKEN\s*=' \
  -e 'DATABASE_URL\s*=' \
  app/lib app/android/app/build.gradle.kts server/lib server/routes server/bin \
  --glob '!**/*.md'
```

Resultado:

- Match unico: `app/android/app/build.gradle.kts`.
- Interpretacao: referencia apenas nomes de propriedades `storePassword` e
  `keyPassword`; os valores ficam em `key.properties`, que esta ignorado pelo
  git.

Firebase:

- `app/lib/firebase_options.dart`, `app/android/app/google-services.json` e
  `app/ios/Runner/GoogleService-Info.plist` contem chaves Firebase `AIza...`.
- Essas chaves sao configuracao publica de cliente Firebase, nao segredo de
  servidor; ainda devem permanecer restritas aos apps/projetos corretos no
  console Firebase.

## 3. Matriz da Etapa 3

| Criterio | Status | Evidencia | Bloqueio restante |
|---|---|---|---|
| Backend health/ready publico estavel | PARTIAL_PASS | Stage 1/2 validaram `/health`, `/ready`, `/cards` | Repetir no fechamento final |
| Request-id manual preservado no backend | PARTIAL_PASS | `/ready` preservou header manual | Repetir junto do smoke instalado |
| Request-id do app rastreavel | PARTIAL_LOCAL | `api_client_request_id_test.dart` | Falta app real -> backend -> log/breadcrumb |
| Sentry backend | PARTIAL_HISTORICAL | Caminhos historicos documentados; codigo existe | Confirmar ingestao atual se for release publico |
| Sentry mobile | PENDING | Nao confirmado neste fechamento | Exige DSN/config segura e evento real do build |
| Build Android | PASS_COMPILE_UNSIGNED | APK debug, APK release e AAB release compilam | Falta keystore real e smoke instalado |
| Build iOS/TestFlight | PENDING | Nao executado nesta etapa | Exige signing/provisioning iOS |
| Scanner | DEFERRED_BY_FLAG | Flag default desligada e testes de gate | Sprint fisica para reativar |
| Push notification | PENDING | Nao validado nesta etapa | Marcar fora do release ou validar build atual |
| Rate limit/paywall IA | PENDING | Contratos existem, release comercial nao fechado | Definir plano/paywall/UX 402 |
| Logs/segredos | PASS_CODE_SCOPE | Scan de codigo/config nao encontrou segredo hardcoded; Firebase configs esperadas | Repetir antes de publicar e revisar artefatos finais |

## 4. Proximas acoes para fechar Stage 3

1. Criar ou apontar `app/android/key.properties` para keystore real fora do git e rebuildar AAB release.
2. Instalar o APK debug/release interno em device ou emulator.
3. Executar fluxo minimo: abrir app, login/register teste, buscar carta, criar/importar deck, abrir detalhes.
4. Capturar um request-id real do app e reconciliar com backend/log.
5. Emitir evento Sentry mobile controlado e confirmar ingestao.
6. Decidir push notification: validado no release ou explicitamente fora.
7. Repetir secret/log scan antes de publicar o build final.

## 5. Regra de fechamento

Stage 3 so pode virar `CONCLUIDA` quando houver evidencia de build instalado,
request-id real rastreavel, Sentry mobile confirmado ou bloqueio formal aceito,
e assinatura real para distribuicao Android/iOS.
