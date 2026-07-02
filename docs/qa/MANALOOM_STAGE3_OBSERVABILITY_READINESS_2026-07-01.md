# ManaLoom Stage 3 - Observability And Release Readiness

Data: 2026-07-01
Escopo: Etapa 3 do goal de produto - confiabilidade tecnica, rastreabilidade e smoke de release.
Status da etapa: concluida como readiness operacional interno, com bloqueios objetivos para release publico.

## 1. Veredito atual

O app ja tem base tecnica para teste interno: `x-request-id` no cliente esta
coberto por teste unitario, scanner esta desligado por flag no release default,
backend preserva request-id em probes publicos, Android compila APK/AAB release
contra a API publica, APK release instala/abre em Android fisico e Firebase
Performance inicializa no smoke mobile.

Ainda nao e possivel declarar release publico confiavel porque faltam:

- confirmacao de evento Sentry mobile real no build alvo;
- keystore Android real para assinar AAB de distribuicao;
- build iOS/TestFlight assinado;
- decisao final de push, monetizacao e Fan Content Policy.

Classificacao:

- Observabilidade de contrato local: `PASS`.
- Backend publico read-only observability probes: `PASS`.
- Build Android tecnico: `PASS_INTERNAL_UNSIGNED`.
- Smoke Android instalado/executado: `PASS_PARTIAL_DEVICE`.
- Firebase Performance mobile: `PASS_DEVICE`.
- Sentry mobile: `PASS_DEVICE_STAGING`.
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

- O smoke mobile mostrou request-id/breadcrumb do app em runtime. Ainda falta
  reconciliar esse request-id com log backend/Sentry em uma ferramenta de
  observabilidade com acesso ao projeto.

### Suite Flutter completa

Comando:

```bash
cd app
flutter test test --no-version-check --reporter compact --concurrency=1
```

Resultado:

- `626` testes passaram.

### Analise estatica Flutter

Comando:

```bash
cd app
flutter analyze lib test integration_test --no-version-check
```

Resultado:

- `No issues found`.

### Build Android com API publica

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

Resultado:

- `build/app/outputs/flutter-apk/app-release.apk`, gerado em
  `2026-07-01 10:50:55`, `114044826` bytes.
- `build/app/outputs/bundle/release/app-release.aab`, gerado em
  `2026-07-01 10:51:16`, `75806976` bytes.
- `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`
  retornou `C=US, O=Android, CN=Android Debug`.

Instalacao/abertura do APK release:

```bash
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
adb -s R58T300SREH shell monkey -p com.mtgia.mtg_app -c android.intent.category.LAUNCHER 1
adb -s R58T300SREH shell pidof com.mtgia.mtg_app
```

Resultado:

- Instalacao: `Success`.
- App abriu no dispositivo Android fisico `R58T300SREH`.
- `pidof com.mtgia.mtg_app` retornou `21012` apos a reinstalacao final do APK release.

Assinatura:

```bash
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --print-certs \
  app/build/app/outputs/flutter-apk/app-release.apk
```

Resultado:

- Certificado: `C=US, O=Android, CN=Android Debug`.
- `app/android/key.properties` ausente (`test -f` retornou exit `1`).

Limite:

- Build instala e abre para teste interno, mas nao esta assinado para loja.

### Smoke Android de observabilidade

Dispositivo:

- `SM A135M`, id `R58T300SREH`, Android 14/API 34.

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
- Historico anterior: `SENTRY_RELEASE_SMOKE_RESULT=not_configured` e
  `SENTRY_RELEASE_DSN_CONFIGURED=false` antes da criacao do projeto.
- Atualizacao posterior em 2026-07-01: projeto Sentry `manaloom` criado na org
  `rafa-pz`; ingestao mobile real confirmada no device `R58T300SREH`.
- Evidencia: `docs/qa/MANALOOM_SENTRY_PROJECT_SETUP_2026-07-01.md`.
- `FIREBASE_PERFORMANCE_SMOKE_RESULT=initialized`.
- `FIREBASE_PERFORMANCE_COLLECTION_ENABLED=true`.

Interpretacao:

- Firebase Performance esta operacional no runtime mobile.
- Sentry mobile nao pode ser confirmado sem `SENTRY_DSN`/`SENTRY_MOBILE_DSN`.
  O bloqueio agora esta isolado como credencial/configuracao, nao como falha de app.

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
| Backend health/ready publico estavel | PASS | Stage 1/2 validaram `/health`, `/ready`, `/cards` | Monitorar continuamente |
| Request-id manual preservado no backend | PASS | `/ready` preservou header manual | Usar em incidentes/smokes futuros |
| Request-id do app rastreavel | PASS_LOCAL | `api_client_request_id_test.dart` e logs do smoke mobile mostram `request_id`/breadcrumb em chamada lenta | Falta reconciliar com log backend em ambiente de observabilidade completo |
| Sentry backend | PARTIAL_HISTORICAL | Caminhos historicos documentados; codigo existe | Confirmar ingestao atual se for release publico |
| Sentry mobile | PASS_DEVICE_STAGING | Evento mobile confirmado por API Sentry | Propagar DSN validado para build assinado |
| Firebase Performance mobile | PASS_DEVICE | Smoke Android retornou `initialized` e `collection_enabled=true` | Monitorar ingestao no console Firebase quando houver acesso |
| Build Android | PASS_INTERNAL_UNSIGNED | APK release/AAB release compilam; APK release instala e abre | Falta keystore real |
| Build iOS/TestFlight | PENDING | Nao executado nesta etapa | Exige signing/provisioning iOS |
| Scanner | DEFERRED_BY_FLAG | Flag default desligada e testes de gate | Sprint fisica para reativar |
| Push notification | PENDING | Nao validado nesta etapa | Marcar fora do release ou validar build atual |
| Rate limit/paywall IA | PENDING | Contratos existem, release comercial nao fechado | Definir plano/paywall/UX 402 |
| Logs/segredos | PASS_CODE_SCOPE | Scan de codigo/config nao encontrou segredo hardcoded; Firebase configs esperadas | Repetir antes de publicar e revisar artefatos finais |

## 4. Proximas acoes para fechar Stage 3

1. Criar ou apontar `app/android/key.properties` para keystore real fora do git e rebuildar AAB release.
2. Propagar `SENTRY_DSN`/`SENTRY_MOBILE_DSN` validado para o build assinado.
3. Confirmar ingestao do evento Sentry mobile no projeto correto.
4. Executar aceite final em build assinado: abrir app, registrar/logar, buscar carta, criar/importar deck, abrir detalhes.
5. Capturar um request-id real do app e reconciliar com backend/log.
6. Decidir push notification: validado no release ou explicitamente fora.
7. Repetir secret/log scan antes de publicar o build final.

## 5. Regra de fechamento

Stage 3 esta concluida para teste interno. Para release publico, so pode virar
`RELEASE_READY` quando houver Sentry mobile confirmado ou bloqueio formal aceito,
assinatura real para distribuicao Android/iOS e aceite final do build assinado.
