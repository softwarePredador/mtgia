# ManaLoom Stage 3 - Observability And Release Readiness

Data: 2026-07-01
Escopo: Etapa 3 do goal de produto - confiabilidade tecnica, rastreabilidade e smoke de release.
Status da etapa: em andamento.

## 1. Veredito atual

O app ja tem base tecnica melhor para teste interno: `x-request-id` no cliente
esta coberto por teste unitario, scanner esta desligado por flag no release
default, e Android compila debug/release/AAB contra a API publica.

Ainda nao e possivel declarar release publico confiavel porque faltam:

- smoke instalado/executado em device ou simulator com API publica/staging;
- confirmacao de evento Sentry mobile real no build alvo;
- keystore Android real para assinar AAB de distribuicao;
- revisao final de logs/segredos no escopo de release;
- decisao comercial/legal para monetizacao e Fan Content Policy.

Classificacao:

- Observabilidade de contrato local: `PARTIAL_PASS`.
- Build Android tecnico: `PASS_COMPILE_UNSIGNED`.
- Release publico: `NO-GO`.

## 2. Evidencias ja executadas

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

### Scanner

Status:

- Scanner esta fora do release default por flag:
  `LaunchFeatures.scannerEnabled = bool.fromEnvironment('ENABLE_SCANNER_RELEASE', defaultValue: false)`.
- Entradas de scanner foram escondidas em deck add-card menu e binder.
- Rota `/scan` redireciona para `/search` quando a flag esta desligada.

Limite:

- Reativar scanner exige sprint fisica de camera/OCR/permissao.

## 3. Matriz da Etapa 3

| Criterio | Status | Evidencia | Bloqueio restante |
|---|---|---|---|
| Backend health/ready publico estavel | PARTIAL_PASS | Stage 1 validou `/health`, `/ready`, `/cards` | Repetir no fechamento final |
| Request-id manual preservado no backend | PARTIAL_PASS | `/ready` preservou header manual | Repetir junto do smoke instalado |
| Request-id do app rastreavel | PARTIAL_LOCAL | `api_client_request_id_test.dart` | Falta app real -> backend -> log/breadcrumb |
| Sentry backend | PARTIAL_HISTORICAL | Ha caminhos historicos documentados | Confirmar ingestao atual se for release publico |
| Sentry mobile | PENDING | Nao confirmado neste fechamento | Exige DSN/config segura e evento real do build |
| Build Android | PASS_COMPILE_UNSIGNED | APK debug, APK release e AAB release compilam | Falta keystore real e smoke instalado |
| Build iOS/TestFlight | PENDING | Nao executado nesta etapa | Exige signing/provisioning iOS |
| Scanner | DEFERRED_BY_FLAG | Flag default desligada e testes de gate | Sprint fisica para reativar |
| Push notification | PENDING | Nao validado nesta etapa | Marcar fora do release ou validar build atual |
| Rate limit/paywall IA | PENDING | Contratos existem, release comercial nao fechado | Definir plano/paywall/UX 402 |
| Logs/segredos | PENDING | Nao rodado scan final nesta etapa | Rodar scan antes de publicar |

## 4. Proximas acoes para fechar Stage 3

1. Rodar secret/log scan no escopo `app`, `server`, `docs/qa` e arquivos de build.
2. Criar ou apontar `app/android/key.properties` para keystore real fora do git e
   rebuildar AAB release.
3. Instalar o APK debug/release interno em device ou emulator.
4. Executar fluxo minimo: abrir app, login/register teste, buscar carta, criar/importar deck, abrir detalhes.
5. Capturar um request-id real do app e reconciliar com backend/log.
6. Emitir evento Sentry mobile controlado e confirmar ingestao.
7. Decidir push notification: validado no release ou explicitamente fora.

## 5. Regra de fechamento

Stage 3 so pode virar `CONCLUIDA` quando houver evidencia de build instalado,
request-id real rastreavel, Sentry mobile confirmado ou bloqueio formal
aceito, e assinatura real para distribuicao Android/iOS.
