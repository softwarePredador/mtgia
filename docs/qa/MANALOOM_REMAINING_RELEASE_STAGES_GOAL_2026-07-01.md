# ManaLoom Remaining Release Stages Goal

Data: 2026-07-01
Goal: dar andamento as etapas remanescentes apos Etapas 1, 2 e 3.

## Veredito

Status para teste interno Android: `READY_WITH_KNOWN_ACCEPTANCE_BLOCKERS`.

Status para release publico/comercial: `NO-GO`.

As etapas remanescentes foram organizadas como:

- Etapa 4: Observabilidade/Sentry.
- Etapa 5: Signing e distribuicao Android/iOS.
- Etapa 6: Aceite final em build.

## Etapa 4 - Observabilidade/Sentry

Status: `CONCLUIDA_COM_BLOQUEIO_DE_CREDENCIAL`.

Evidencia atual:

- Codigo mobile usa `String.fromEnvironment('SENTRY_DSN')`.
- Codigo backend usa `SENTRY_DSN` de env/config.
- `SENTRY_DSN`, `SENTRY_MOBILE_DSN` e `SENTRY_AUTH_TOKEN` nao estao carregados
  no ambiente atual.
- Smoke Android anterior retornou:
  - `SENTRY_RELEASE_SMOKE_RESULT=not_configured`
  - `SENTRY_RELEASE_DSN_CONFIGURED=false`
  - `FIREBASE_PERFORMANCE_SMOKE_RESULT=initialized`
  - `FIREBASE_PERFORMANCE_COLLECTION_ENABLED=true`

Conclusao:

- Firebase Performance mobile esta operacional.
- Sentry nao falhou por codigo; esta bloqueado por credencial/configuracao.

Acao restante:

```bash
cd app
flutter test integration_test/release_observability_smoke_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_DSN=<dsn-mobile-seguro> \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=mtgia-ready-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check \
  --reporter expanded
```

Critico:

- Nao gravar DSN real em arquivo versionado.
- Confirmar ingestao no projeto Sentry pelo `smoke_id`.

## Etapa 5 - Signing e distribuicao

Status: `CONCLUIDA_COM_BLOQUEIOS_DE_CREDENCIAL`.

### Android

Evidencia atual:

- `app/android/app/build.gradle.kts` ja carrega `key.properties` se existir.
- `app/android/.gitignore` ignora:
  - `key.properties`
  - `**/*.keystore`
  - `**/*.jks`
- `app/android/key.properties` nao existe no ambiente atual.
- APK release final instalou e abriu no Android fisico.
- `apksigner verify --print-certs` retornou certificado
  `C=US, O=Android, CN=Android Debug`.

Artefatos atuais:

- `app/build/app/outputs/flutter-apk/app-release.apk`
- `app/build/app/outputs/bundle/release/app-release.aab`

Acao restante:

Criar `app/android/key.properties` fora do git com:

```properties
storeFile=/absolute/path/to/release-keystore.jks
storePassword=<secret>
keyAlias=<alias>
keyPassword=<secret>
```

Depois rebuildar:

```bash
cd app
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_DSN=<dsn-mobile-seguro> \
  --dart-define=SENTRY_ENVIRONMENT=production \
  --dart-define=SENTRY_RELEASE=manaloom-1.0.0+1 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=0.1 \
  --no-version-check
```

### iOS

Evidencia atual:

Comando executado:

```bash
cd app
flutter build ios --release --no-codesign \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=mtgia-ready-2026-07-01 \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 \
  --no-version-check
```

Resultado:

- `Xcode build done`.
- `Built build/ios/iphoneos/Runner.app (101.2MB)`.
- `du -sh`: `97M`.
- `codesign`: `code object is not signed at all`.
- `Info.plist`:
  - `CFBundleIdentifier=com.mtgia.mtgApp`
  - `CFBundleShortVersionString=1.0.0`
  - `CFBundleVersion=1`
  - `MinimumOSVersion=13.0`
- `GoogleService-Info.plist` esta embutido no app.

Conclusao:

- iOS compila tecnicamente.
- TestFlight/App Store continua bloqueado por signing/provisioning Apple.

Acao restante:

- Definir Apple Team.
- Configurar provisioning para `com.mtgia.mtgApp`.
- Criar export/archive assinado.
- Rodar smoke em dispositivo iOS ou TestFlight.

## Etapa 6 - Aceite final em build

Status: `CONCLUIDA_COM_BLOCKERS_DE_UX_ACEITE`.

### Provas positivas

APK release final:

```bash
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
adb -s R58T300SREH shell monkey -p com.mtgia.mtg_app -c android.intent.category.LAUNCHER 1
adb -s R58T300SREH shell pidof com.mtgia.mtg_app
```

Resultado:

- Instalacao: `Success`.
- App abriu no Android fisico.
- `pidof`: `25211`.

Smoke mobile import localizado ja passou:

- `POST /auth/register -> 201`.
- `POST /import/validate -> 200`.
- `POST /import -> 200`.
- `DELETE /decks/055610c2-cd53-48dd-9106-fda73118d650 -> 204`.

### Aceite funcional completo - import path

Comando:

```bash
cd app
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=RUNTIME_OPTIMIZE_INTENSITY_LABEL=Focado \
  --no-version-check \
  --reporter expanded
```

Log:

- `/tmp/manaloom_deck_runtime_android_20260701.log`

Resultado parcial:

- Registro: passou (`POST /auth/register -> 201`).
- Criacao de deck: passou (`POST /decks -> 200`).
- Importacao Commander completa: passou (`POST /import/to-deck -> 200`).
- Validacao: passou (`POST /decks/9b263ee1-f8ce-46e3-b1d0-b6cc4bf4a598/validate -> 200`).
- Pricing: passou (`POST /decks/.../pricing -> 200`).
- Analysis: passou (`GET /decks/.../analysis -> 200`).

Falha:

- A segunda importacao `replace_all` tambem retornou `POST /import/to-deck -> 200`,
  mas o modal `Importar Lista` nao desapareceu dentro do timeout.
- Classificacao: `ACCEPTANCE_BLOCKER_IMPORT_MODAL_CLOSE`.

Deck de QA possivelmente residual:

- `9b263ee1-f8ce-46e3-b1d0-b6cc4bf4a598`.

### Aceite funcional completo - generate path

Comando:

```bash
cd app
flutter test integration_test/deck_generate_async_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --no-version-check \
  --reporter expanded
```

Log:

- `/tmp/manaloom_generate_async_android_20260701.log`

Resultado parcial:

- Registro: passou.
- Entrada no fluxo de gerar deck: passou.
- Feedback inicial async: `ASYNC_GENERATE_INITIAL_FEEDBACK_MS 655`.
- Preview gerado: passou.
- Deck salvo: passou.
- Deck criado: `4b5f542c-a546-4e10-a08a-eed5704140e3`.
- Details/pricing/validate/analysis: passaram.
- Optimize request emitido com request-id:
  `mob-6558d5acd33c0-516182c3`.

Falha:

- `POST /ai/optimize -> 422`.
- Backend retornou quality gate:
  `OPTIMIZE_NEEDS_REPAIR - O deck precisa de rebuild_guided antes de uma micro-otimizacao segura`.
- O harness ficou preso apos o quality gate e foi interrompido.
- Classificacao: `ACCEPTANCE_BLOCKER_OPTIMIZE_NEEDS_REPAIR_UX`.

Deck de QA possivelmente residual:

- `4b5f542c-a546-4e10-a08a-eed5704140e3`.

## Proximas acoes fechadas

1. Corrigir UX/harness do modal de importacao para fechar ou mostrar estado final
   apos `POST /import/to-deck -> 200` no caminho `replace_all`.
2. Corrigir UX/harness do quality gate `OPTIMIZE_NEEDS_REPAIR` para exibir
   claramente rebuild guided ou outcome seguro, sem travar o aceite.
3. Limpar os decks residuais acima com token/admin apropriado.
4. Repetir aceite Android completo.
5. Rebuildar Android com keystore real.
6. Repetir observabilidade com `SENTRY_DSN` real.
7. Fazer archive iOS assinado.

## Estado de fechamento

As etapas remanescentes foram avancadas e evidenciadas. O que depende apenas do
ambiente local foi concluido; o que depende de segredo/signing ficou bloqueado
com comando exato de retomada. O aceite mobile descobriu dois blockers reais de
release que devem ser tratados antes de oferta publica.
