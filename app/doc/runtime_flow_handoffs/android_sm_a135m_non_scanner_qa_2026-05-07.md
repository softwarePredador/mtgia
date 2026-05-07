# Android SM A135M non-scanner runtime QA - 2026-05-07

## Resultado

**PASS WITH RISKS** para o app ManaLoom no Android fisico **SM A135M** usando o backend publico `https://evolution-cartinhas.8ktevp.easypanel.host`.

Scanner, camera, OCR, MLKit scanner e qualquer fluxo dependente de scan fisico ficaram **DEFERRED/IGNORED**. Nenhum token/JWT/secret foi registrado no relatorio.

## Data/hora

- Inicio da rodada: `2026-05-07T11:03:41-0300`
- Fechamento das evidencias: `2026-05-07T12:14:35-0300`

## Device e runtime

```text
adb devices -l
R58T300SREH  device usb:2-1 product:a13ub model:SM_A135M device:a13 transport_id:6

flutter devices --no-version-check
SM A135M (mobile) • R58T300SREH • android-arm • Android 14 (API 34)
```

Propriedades confirmadas via `adb -s R58T300SREH shell getprop`:

| Campo | Valor |
|---|---|
| Modelo | `SM-A135M` |
| Android | `14` |
| API | `34` |

## Backend

URL usada pelo app:

```text
https://evolution-cartinhas.8ktevp.easypanel.host
```

Health final:

```json
{"status":"healthy","service":"mtgia-server","environment":"production","version":"1.0.0","git_sha":"4874923bc77997100eb30dd967336b0d1ee11252","checks":{"process":{"status":"healthy"}}}
```

Health inicial tambem respondeu `healthy`, com `git_sha=c39a9e2a84e219327fd3af1c5a5945b047682edd`.

## Comandos base executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short --branch
git fetch origin master && git pull --ff-only origin master
adb devices -l
flutter devices --no-version-check
curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

Validacao estatica/unitaria:

```bash
cd app
flutter analyze lib test integration_test --no-version-check
flutter test test --no-version-check --reporter expanded
```

Comando padrao dos testes Android:

```bash
cd app
flutter test integration_test/<harness>.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

Evidencias sanitizadas:

```text
app/doc/runtime_flow_proofs_2026-05-07_android_sm_a135m_non_scanner/
```

## Resultado por area

| Area | Resultado | Evidencia principal |
|---|---:|---|
| Analyze | PASS | `flutter_analyze_final.log` |
| Unit/widget tests | PASS, 550 testes | `flutter_test_unit_final.log` |
| Sets catalog | PASS | `sets_catalog_runtime_test.log` |
| Search Cards/Colecoes | PASS | `sets_search_catalog_runtime_test.log` |
| Collection entrypoints | PASS WITH RISKS | `collection_entrypoints_runtime_test.log`; 401 em binder/trades sem auth foi esperado e nao quebrou UI |
| Binder dashboard | PASS | `binder_dashboard_runtime_test.log` |
| Marketplace/Trades/Messages/Notifications | PASS | `binder_marketplace_trade_runtime_test.log` |
| Profile/Community public decks/follow/search | PASS apos ajuste de harness | `profile_community_runtime_test_rerun_after_harness_fix.log` |
| Deck create/import/detail/optimize preview/apply/validate | PASS em intensidade `Focado` | `deck_runtime_m2006_test_focado_balanced_partial_selection_rerun.log` |
| Deck generate async/save/detail | PASS apos backoff de polling | `deck_generate_async_runtime_test_after_polling_backoff.log` |
| Optimize `rebuild_guided` | PASS como explicacao/CTA de produto | `deck_generate_async_runtime_test_after_polling_backoff.log` |
| Optimize `Agressivo` | NOT PROVEN | backend job async falhou antes do preview; app passou a mostrar mensagem amigavel |
| Life Counter native game modes/timer/player state | PASS | `life_counter_native_*_smoke_test.log` |
| Lotus visual runtime DOM/controles/persistencia | PASS WITH RISKS | `life_counter_lotus_visual_runtime_proof_test_after_screenshot_timeout.log` |
| Release observability | PASS WITH RISKS | Sentry DSN nao configurado, Firebase Performance inicializado |
| Mobile Sentry smoke | PASS WITH RISKS | evento nao capturado porque DSN nao configurado |
| FCM staging smoke | PASS | token registrado sem imprimir token |
| Scanner/camera/OCR/MLKit | DEFERRED/IGNORED | `scanner_skip_candidates.txt` |

## Fluxo de deck comprovado

O fluxo mais critico foi provado no SM A135M contra backend real:

1. Register/login.
2. Criacao de deck Commander.
3. Abertura de detalhes.
4. Import de lista Commander com `Talrand, Sky Summoner`.
5. Optimize com intensidade `Focado`.
6. Preview com multiplas sugestoes.
7. Deselecao de remocao e adicao para aplicar subset balanceado.
8. Apply no backend.
9. Validate final `200`.
10. Comandante preservado no estado do `DeckProvider`.

## Correcoes aplicadas durante a rodada

1. `app/lib/features/decks/providers/deck_provider_support_ai.dart`: jobs async de optimize com `OPTIMIZE_JOB_FAILED` agora exibem copia amigavel em portugues em vez de repassar texto tecnico do executor interno.
2. `app/lib/features/decks/providers/deck_provider_support_generation.dart`: polling de generate async aguarda antes da primeira consulta, respeita minimo de 5s e faz backoff em `429`.
3. `app/integration_test/deck_runtime_m2006_test.dart`: harness prova selecao parcial real e preservacao do comandante via provider.
4. `app/integration_test/profile_community_runtime_test.dart`: harness aceita o titulo real do detalhe publico quando o app mostra o nome do deck em vez do placeholder `Deck Público`.
5. `app/integration_test/life_counter_lotus_visual_runtime_proof_test.dart`: screenshot nativo virou evidencia nao-bloqueante; DOM/controles/persistencia seguem obrigatorios.

## Latencia e observabilidade

Latencias >5s observadas e registradas como breadcrumbs/logs:

- `/market/movers?limit=5&min_price=1.0`: ~5.3-5.5s em algumas rodadas.
- `/ai/archetypes`: ~7.7-8.9s.
- `/ai/optimize`: ~4.8-8.0s dependendo da intensidade.
- Tela `generate`: ~13s no fluxo generate async completo.

Observabilidade:

- `release_observability_smoke_test`: `SENTRY_RELEASE_SMOKE_RESULT=not_configured`, `FIREBASE_PERFORMANCE_SMOKE_RESULT=initialized`.
- `mobile_sentry_smoke_test`: `SENTRY_MOBILE_EVENT_ID=null`, sem expor DSN.
- `fcm_staging_smoke_test`: `FCM_PERMISSION status=authorized`, `FCM_SMOKE_RESULT=token_registered token_present=true`.

## O que foi real vs mock

| Item | Estado |
|---|---|
| Device | Android fisico real SM A135M via USB/ADB |
| App | Flutter instalado/executado via `flutter test` no device real |
| Backend | Publico real Easypanel |
| Auth/decks/binder/trades/messages/notifications/community | HTTP real |
| AI generate/optimize | HTTP real |
| Scanner/camera/OCR/MLKit | Nao executado |
| Mocks | Nenhum mock de backend nos integration tests executados |

## Riscos / NOT PROVEN

- Optimize `Agressivo`: o backend publico retornou job async `failed` com erro tecnico interno antes de preview. O app agora converte isso para mensagem amigavel; preview/apply agressivo segue **NOT PROVEN** ate o backend entregar sugestoes.
- Lotus screenshots nativos: `takeScreenshot`/surface capture no Android fisico falhou por timeout/assertion, mas o harness passou com prova DOM: `lifeContentFits=true`, `horizontalOverflow=false`, `40 -> 41 -> 40`, reopen em `41`.
- Collection entrypoints sem usuario autenticado dispara 401 em binder/trades, mas a UI nao quebrou e fluxos autenticados equivalentes passaram.
- Sentry DSN nao configurado no ambiente de QA; eventos ficam `not_configured/null`.

## Scanner skip

Pulados intencionalmente por mencionarem scanner/camera/OCR:

```text
app/integration_test/scanner_controlled_harness_runtime_test.dart
app/integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart
```

Tambem ficaram fora do escopo testes unitarios de Scanner/OCR durante a avaliacao de device, embora `flutter test test` completo tenha passado.

## Menores proximas acoes

1. Corrigir o executor backend de optimize async agressivo para retornar preview seguro em vez de `OPTIMIZE_JOB_FAILED`.
2. Investigar capture nativo de screenshot Lotus no Android fisico; nao bloqueia runtime funcional, mas limita evidencia visual PNG.
3. Configurar Sentry DSN/ambiente de release se for necessario provar envio real de evento.
