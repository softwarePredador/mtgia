# Android internal build validation - 2026-05-07

## Atualizacao - 2026-05-08 14:04-14:23 -0300

### Resultado

**PASS WITH RISKS para o APK interno Android non-scanner instalado no SM A135M.**

O APK release foi gerado contra o backend publico, instalado no device alvo
`SM A135M` (`adb R58T300SREH`) e aberto fora de `flutter test`/`flutter run`
via `am start`. A rodada provou UI/backend reais para os fluxos non-scanner
criticos: register/login, Home, Search/Cards, Search/Colecoes, detalhe de
colecao, Decks, Generate async/save, Deck Detail, Optimize com
`rebuild_guided`, Validate, Binder, Marketplace, Trades list, Messages,
Notifications, Community e Life Counter/Lotus.

Scanner, camera, OCR e MLKit scanner ficaram **DEFERRED/IGNORED** e nao foram
tocados.

### Sync e branch

```text
git status --short
<sem saida antes da rodada; worktree limpo>

git branch --show-current
master

git log -1 --oneline
01c55fa (HEAD -> master, origin/master, origin/HEAD) Document Android internal install lockscreen validation

git fetch origin master --quiet && git pull --ff-only origin master
Already up to date.
```

### Backend publico

URL usada no build e runtime:

```text
https://evolution-cartinhas.8ktevp.easypanel.host
```

`/health` respondeu `healthy` e incluiu `git_sha`:

```json
{"status":"healthy","service":"mtgia-server","environment":"production","version":"1.0.0","git_sha":"01c55faf3dc32cba80756c7198911385d9490723","checks":{"process":{"status":"healthy"}}}
```

`/git_sha` separado retornou `404`; a validacao de SHA ficou no campo
`git_sha` de `/health`.

### Device Android fisico

```text
flutter devices --no-version-check
SM A135M (mobile)  • R58T300SREH • android-arm • Android 14 (API 34)
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • iOS 17.4 simulator
macOS (desktop)
Chrome (web)

adb devices -l
R58T300SREH device usb:2-1 product:a13ub model:SM_A135M device:a13 transport_id:1

ro.product.model: SM-A135M
ro.product.manufacturer: samsung
ro.build.version.release: 14
ro.build.version.sdk: 34
ro.product.device: a13
```

### Validacao local pre-build

```bash
cd app
flutter analyze lib test integration_test --no-version-check
```

Resultado: `No issues found`.

```bash
cd app
flutter test test --no-version-check
```

Resultado: PASS, processo terminou com exit code `0`.

### APK interno

Comando executado:

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
activity: com.mtgia.mtg_app/.MainActivity
```

### Instalacao e abertura fora de Flutter

```text
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
Performing Streamed Install
Success

adb -s R58T300SREH shell am start -W -n com.mtgia.mtg_app/.MainActivity
Status: ok
Activity: com.mtgia.mtg_app/.MainActivity
Complete
```

O app foi aberto e operado por ADB/shell no APK instalado. Nao foi usado
`flutter run`, `flutter test` ou runner de integration test para a prova
funcional instalada.

### Smoke non-scanner solicitado

| Area | Resultado | Evidencia |
|---|---:|---|
| Login/register | PASS | Registro pelo app abriu Home autenticada; login UI explicito em conta QA separada carregou Home. |
| Home | PASS | `14_home_notifications_allowed.png`, `41_login_success_home.png`. |
| Search/Cards | PASS | Busca `sol` retornou cartas e CTAs `Adicionar`; `17_card_search_sol_results.png`. |
| Search/Colecoes | PASS | Aba `Colecoes` carregou catalogo com sets futuros, seguida de abertura do set `MSH`; evidencia principal em `19_set_detail_msh.png`. |
| Set detail | PASS | `MSH` abriu com cartas e metadata local; `19_set_detail_msh.png`. |
| Decks | PASS | Lista vazia inicial, geracao IA e deck salvo em `Decks`; `25_after_save_generated_deck.png`. |
| Generate async | PASS WITH RISKS | Geracao demorou ~55s e caiu em fallback deterministico/mock amigavel; deck 100/100 salvo. |
| Deck Detail | PASS | `26_deck_detail.png`. |
| Optimize safe no-op/rebuild_guided | PASS WITH RISKS | Backend retornou `POST /ai/optimize -> 422`; UI exibiu modal de reconstrucao guiada com CTA e sem aplicar mudancas. |
| Validate | PASS | Deck seguiu `Deck legal para o formato`, `100/100`, comandante definido; `30_deck_detail_validate_after_optimize.png`. |
| Binder | PASS | Aba `Fichario` abriu sem crash; `31_binder_tab.png`. |
| Marketplace | PASS | Lista global carregou itens e vendedores; `32_marketplace_tab.png`. |
| Trades list | PASS | Lista abriu estado vazio amigavel; `33_trades_tab.png`. |
| Messages/Notifications | PASS | Estados vazios amigaveis; `34_messages_inbox.png`, `35_notifications.png`. |
| Profile/Community | PASS | Community carregou decks publicos; perfil foi observado autenticado sem crash. |
| Life Counter/Lotus | PASS WITH RISKS | WebView `ManaLoom Life Counter` abriu e processo permaneceu vivo; um comando ADB de captura encerrou com `137`, recuperado sem crash do app. |
| Scanner/camera/OCR/MLKit | DEFERRED/IGNORED | Fora de escopo e nenhum CTA de scanner foi acionado. |

### Classificacao de riscos

| Categoria | Classificacao | Evidencia |
|---|---:|---|
| Crash/ANR app | PASS | Logcat por PID do app sem `FATAL EXCEPTION`, ANR, SIGABRT ou SIGSEGV. |
| Tela branca | PASS | Telas funcionais renderizadas; Life Counter mostrou WebView. |
| 4xx/5xx | PASS WITH RISKS | Uma chamada app-facing `POST /ai/optimize -> 422` foi observada e mapeada para UX de rebuild guiado; nao houve 5xx. |
| Timeout/latencia >5s | PASS WITH RISKS | Generate async levou ~55s e retornou fallback deterministico com copia amigavel. |
| Erro bruto user-facing | PASS WITH RISKS | Nao houve 4xx/5xx cru; o modal ainda mostra o termo tecnico `rebuild_guided` no corpo, classificado como risco P2 de microcopy. |
| Overflow | PASS | Logcat app sem `RenderFlex`/overflow; telas capturadas nao mostraram overflow bloqueante. |
| Logs graficos Android | RISCO ACEITO | `gralloc4`/`OpenGLRenderer` do device apareceram sem crash e sem impacto visual observado. |

### Evidencias salvas

Diretorio:

```text
app/doc/runtime_flow_proofs_2026-05-07_sm_a135m/
```

Arquivos principais:

```text
14_home_notifications_allowed.png
17_card_search_sol_results.png
19_set_detail_msh.png
24_generate_result_55s.png
25_after_save_generated_deck.png
26_deck_detail.png
28_optimize_after_submit_15s.png
30_deck_detail_validate_after_optimize.png
31_binder_tab.png
32_marketplace_tab.png
33_trades_tab.png
34_messages_inbox.png
35_notifications.png
36_community_tab.png
38_life_counter_lotus.png
40_login_screen_before_login.png
41_login_success_home.png
logcat_filtered_redacted.txt
logcat_app_pid_17415_redacted.txt
logcat_app_pid_20234_redacted.txt
```

Os logs foram redigidos para remover tokens, headers, emails e chaves. Arquivos
brutos de logcat e dumps XML com campos de formulario foram removidos antes do
commit.

### Decisao

**GO WITH RISKS / PASS WITH RISKS** para release interno Android non-scanner.

Nao foi encontrado P0/P1 fora de Scanner que exigisse patch antes da decisao.
Os riscos remanescentes sao aceitaveis para build interno: fallback lento de
Generate async, `rebuild_guided` acionado por deck estruturalmente ruim com
termo tecnico ainda visivel, e ruido grafico Android sem impacto funcional.

## Atualizacao - 2026-05-08 13:43-13:49 -0300

### Resultado

**BLOCKED para smoke funcional completo do release interno instalado no SM A135M.**

Nesta rodada o device alvo `SM A135M` (`adb R58T300SREH`) estava visivel no ADB, o APK release foi gerado, instalado com sucesso e aberto fora de `flutter run`. A validacao funcional de telas ficou **NOT PROVEN** porque o telefone permaneceu no lockscreen/keyguard (`NotificationShade`/`top-sleeping`) durante a tentativa, impedindo interacao visual segura com Login/Home/fluxos internos sem credencial de desbloqueio.

Scanner, camera, OCR e MLKit scanner ficaram **DEFERRED/IGNORED** e nao foram exercitados.

### Sync e branch

```text
git status --short
<sem saida; worktree limpo antes da rodada>

git branch --show-current
master

git log -1 --oneline
74e3176 (HEAD -> master, origin/master, origin/HEAD) Document Android internal build validation

git pull --ff-only
Already up to date.
```

Nao havia alteracoes locais nao relacionadas a preservar antes da validacao.

### Backend publico

URL usada no build e runtime:

```text
https://evolution-cartinhas.8ktevp.easypanel.host
```

`/health` respondeu `healthy` e incluiu `git_sha`:

```json
{"status":"healthy","service":"mtgia-server","environment":"production","version":"1.0.0","git_sha":"74e3176543b7fe9a727567d6ed7cf4503157b70e","checks":{"process":{"status":"healthy"}}}
```

`/git_sha` separado retornou `Route not found`; o SHA foi validado pelo campo `git_sha` do `/health`.

### Validacao local

```text
cd app
flutter analyze lib test integration_test --no-version-check
No issues found! (ran in 4.4s)
```

```text
cd app
flutter test test --no-version-check
Resultado: PASS, processo terminou com exit code 0.
```

### APK interno

Comando executado:

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

### Device Android fisico

```text
adb devices -l
R58T300SREH device usb:2-1 product:a13ub model:SM_A135M device:a13 transport_id:1

ro.product.model: SM-A135M
ro.product.manufacturer: samsung
ro.build.version.release: 14
ro.build.version.sdk: 34
```

### Instalacao e abertura fora de Flutter

```text
adb -s R58T300SREH install -r build/app/outputs/flutter-apk/app-release.apk
Performing Streamed Install
Success
```

```text
adb -s R58T300SREH shell am start -W -n com.mtgia.mtg_app/.MainActivity
Status: ok
Activity: com.mtgia.mtg_app/.MainActivity
WaitTime: 3042
Complete
```

Evidencia de processo/atividade:

```text
pidof com.mtgia.mtg_app
14864

dumpsys activity processes
ProcessRecord ... 14864:com.mtgia.mtg_app/u0a723
ActivityRecord ... com.mtgia.mtg_app/.MainActivity
state: top-sleeping
```

Bloqueio observado:

```text
dumpsys window
mCurrentFocus=Window{... u0 NotificationShade}
mFocusedApp=ActivityRecord{... u0 com.mtgia.mtg_app/.MainActivity ...}
mShowingDream=false mDreamingLockscreen=true
```

`uiautomator dump /dev/tty` retornou apenas hierarquia do `com.android.systemui`/lockscreen, nao a arvore do app. Por isso screenshots de telas funcionais e navegacao por Login/Home/Search/etc. nao foram capturados nesta rodada.

### Logcat filtrado

Apos a abertura do app instalado, o logcat filtrado nao mostrou crash/ANR do pacote `com.mtgia.mtg_app`.

Trechos relevantes:

```text
PkgPredictorService ... pkgName:com.mtgia.mtg_app
MdnieScenarioControlService: packageName : com.mtgia.mtg_app className : com.mtgia.mtg_app.MainActivity
```

Mensagens de `LoadedApk`/Google Play Services sem relacao direta com `com.mtgia.mtg_app` apareceram no buffer do sistema, mas nao houve `FATAL EXCEPTION`, `ANR` ou encerramento do processo do app.

### Smoke non-scanner solicitado

| Area | Resultado nesta rodada | Observacao |
|---|---:|---|
| Login/register | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Home | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Search/Sets | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Decks | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Generate async | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Deck Detail | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Optimize safe no-op/rebuild_guided | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Validate | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Binder | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Marketplace | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Trades list | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Messages/Notifications | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Profile/Community | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Life Counter/Lotus | NOT PROVEN | Device permaneceu no lockscreen/keyguard |
| Scanner/camera/OCR/MLKit | DEFERRED/IGNORED | Fora de escopo por instrucao |

### Classificacao de riscos

| Categoria | Classificacao | Evidencia |
|---|---:|---|
| Build release | PASS | APK gerado contra backend publico |
| Instalacao no SM A135M | PASS | `adb install -r` retornou `Success` |
| Abertura fora de Flutter | PASS parcial | `am start -W` retornou `Status: ok`; processo ficou vivo |
| Crash/ANR no launch | PASS parcial | Nenhum `FATAL EXCEPTION`/ANR do pacote no logcat filtrado |
| Tela branca | NOT PROVEN | Lockscreen impediu observar UI do app |
| 4xx/5xx user-facing | NOT PROVEN | Lockscreen impediu fluxos de rede da UI |
| Timeout | NOT PROVEN | Lockscreen impediu fluxos internos |
| Erro bruto user-facing | NOT PROVEN | Lockscreen impediu observar UI |
| Overflow | NOT PROVEN | Lockscreen impediu observar UI |
| Latencias >5s | NOT PROVEN | Lockscreen impediu medicao funcional |

### Decisao

**BLOCKED** para aprovacao funcional final do release interno non-scanner nesta rodada.

Menor proximo passo: desbloquear fisicamente o `SM A135M`/autorizar uma sessao interativa e repetir somente a etapa instalada:

```bash
adb -s R58T300SREH install -r app/build/app/outputs/flutter-apk/app-release.apk
adb -s R58T300SREH shell am start -W -n com.mtgia.mtg_app/.MainActivity
adb -s R58T300SREH logcat -c
```

Depois, navegar manualmente/por automacao nas telas non-scanner solicitadas, capturando screenshots e logcat filtrado. Sem desbloqueio do device, nao ha base para promover o resultado acima de `BLOCKED`.

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
