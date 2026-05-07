# Android internal build validation - 2026-05-07

## Resultado

**BLOCKED para decisao final de release interno instalado no SM A135M.**

O APK Android interno non-scanner foi gerado com sucesso contra o backend publico, mas o device alvo `SM A135M` (`adb R58T300SREH`) nao estava visivel no ADB durante a tentativa final. Por isso, instalacao via `adb install`, abertura fora de `flutter run`, screenshots, `logcat` filtrado e smoke manual/automatizado do APK instalado ficaram **NOT PROVEN** nesta rodada.

Scanner, camera, OCR e MLKit scanner ficaram **DEFERRED/IGNORED** e nao foram exercitados.

## Data/hora

- Tentativa: `2026-05-07 17:16-17:29 -0300`
- Repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch alvo: `master`
- HEAD local: `fd5fa91b2528204ae2818fdc7f263e6676334a79`

## Backend publico

URL usada no build:

```text
https://evolution-cartinhas.8ktevp.easypanel.host
```

`/health` respondeu `healthy` e expos o `git_sha`:

```json
{"status":"healthy","service":"mtgia-server","environment":"production","version":"1.0.0","git_sha":"fd5fa91b2528204ae2818fdc7f263e6676334a79","checks":{"process":{"status":"healthy"}}}
```

`/git_sha` separado retornou `Route not found`; o SHA foi validado pelo campo `git_sha` do `/health`.

## Device discovery

Comandos executados:

```bash
flutter devices --no-version-check
adb devices -l
adb -s R58T300SREH get-state
adb -s R58T300SREH shell getprop ro.product.model
```

Resultado:

```text
adb devices -l
List of devices attached

adb -s R58T300SREH get-state
error: device 'R58T300SREH' not found

adb -s R58T300SREH shell getprop ro.product.model
adb: device 'R58T300SREH' not found
```

`flutter devices` listou iPhone 15 Simulator, macOS, Chrome e um iOS fisico wireless, mas nenhum Android. ADB foi reiniciado (`adb kill-server`/`adb start-server`) e o resultado permaneceu sem o `R58T300SREH`.

## Validacao local pre-device

### Sync e status

```bash
git fetch origin master --quiet
git pull --ff-only origin master
git status --short
```

Resultado: `Already up to date` em `master`; status limpo antes das atualizacoes de documentacao.

### Analyze

```bash
cd app
flutter analyze lib test integration_test --no-version-check
```

Resultado: **PASS** (`No issues found!`).

### Tests

```bash
cd app
flutter test test --no-version-check
```

Resultado final: **PASS**, `551` testes (`All tests passed!`).

Observacao de ambiente: a primeira tentativa de `flutter test test` falhou antes de executar a suite por falta de espaco temporario do macOS (`No space left on device`, errno 28). Foram removidos somente artefatos regeneraveis locais (`app/build`, `app/.dart_tool`, `server/build` e `flutter_tools.*` em `/var/folders/.../T`), `flutter pub get` foi reexecutado, e a suite passou em seguida.

## APK interno gerado

Comando:

```bash
cd app
flutter build apk --release --no-version-check \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
```

Resultado:

```text
Built build/app/outputs/flutter-apk/app-release.apk (111.6MB)
```

Artefato:

```text
app/build/app/outputs/flutter-apk/app-release.apk
size: 111,594,763 bytes
sha256: c158e67e733446489df495e0e511df34939f7943154862dba604c7eb1a0fad2e
package: com.mtgia.mtg_app
launchable-activity: com.mtgia.mtg_app.MainActivity
```

Aviso de build observado, nao bloqueante para o escopo non-scanner:

```text
google_mlkit_commons ... uses unchecked or unsafe operations
```

Esse aviso vem de dependencia scanner/MLKit, mas Scanner ficou fora de escopo e nao foi executado.

## Instalacao e abertura fora de flutter run

**BLOCKED / NOT PROVEN.**

Nao foi possivel executar:

```bash
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
adb -s R58T300SREH shell monkey ...
adb -s R58T300SREH logcat ...
adb -s R58T300SREH exec-out screencap ...
```

Motivo: `adb: device 'R58T300SREH' not found`.

## Smoke non-scanner solicitado

| Area | Resultado nesta rodada | Observacao |
|---|---:|---|
| Login/register | NOT PROVEN | APK nao instalado no device alvo |
| Home | NOT PROVEN | APK nao instalado no device alvo |
| Search/Sets | NOT PROVEN | APK nao instalado no device alvo |
| Decks | NOT PROVEN | APK nao instalado no device alvo |
| Generate async | NOT PROVEN | APK nao instalado no device alvo |
| Deck Detail | NOT PROVEN | APK nao instalado no device alvo |
| Optimize safe no-op/rebuild_guided | NOT PROVEN | APK nao instalado no device alvo |
| Validate | NOT PROVEN | APK nao instalado no device alvo |
| Binder | NOT PROVEN | APK nao instalado no device alvo |
| Marketplace | NOT PROVEN | APK nao instalado no device alvo |
| Trades list | NOT PROVEN | APK nao instalado no device alvo |
| Messages/Notifications | NOT PROVEN | APK nao instalado no device alvo |
| Profile/Community | NOT PROVEN | APK nao instalado no device alvo |
| Life Counter/Lotus | NOT PROVEN | APK nao instalado no device alvo |
| Scanner/camera/OCR/MLKit | DEFERRED/IGNORED | Fora de escopo por instrucao |

Provas Android anteriores do mesmo dia existem em `app/doc/runtime_flow_handoffs/android_sm_a135m_non_scanner_qa_2026-05-07.md`, mas foram executadas via `flutter test` no device. Elas nao substituem o criterio desta rodada: APK release instalado e aberto fora de `flutter test/flutter run`.

## Classificacao de riscos

| Categoria | Classificacao | Evidencia |
|---|---:|---|
| Crash | NOT PROVEN | Runtime do APK instalado nao executou |
| Tela branca | NOT PROVEN | Runtime do APK instalado nao executou |
| 4xx/5xx user-facing | NOT PROVEN | Runtime do APK instalado nao executou |
| Timeout | NOT PROVEN | Runtime do APK instalado nao executou |
| Erro bruto user-facing | NOT PROVEN | Runtime do APK instalado nao executou |
| Overflow | NOT PROVEN | Runtime do APK instalado nao executou |
| Latencias >5s | NOT PROVEN | Runtime do APK instalado nao executou |
| Build release | PASS | APK gerado com backend publico |
| Analyze/test local | PASS | Analyze limpo; 551 testes passaram |

## Decisao

**BLOCKED** para release interno final no SM A135M nesta rodada.

O build esta pronto para instalacao assim que o device `R58T300SREH` voltar a aparecer em `adb devices -l`. O menor proximo passo e conectar/desbloquear o SM A135M com depuracao USB autorizada e repetir apenas:

```bash
adb devices -l
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
adb -s R58T300SREH shell monkey -p com.mtgia.mtg_app 1
adb -s R58T300SREH logcat ...
adb -s R58T300SREH exec-out screencap -p > <evidence>.png
```

Sem o device ADB, nao ha base para promover o resultado acima de `BLOCKED`.
