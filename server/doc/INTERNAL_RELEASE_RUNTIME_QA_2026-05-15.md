# Internal Release Runtime QA - 2026-05-15

## Resultado

Status final: **PASS_WITH_RISKS** para release interno non-scanner.

Escopo scanner/camera/OCR/MLKit: **DEFERRED / NOT PROVEN**.

## Ambiente

| Item | Valor |
|---|---|
| Branch | `master` sincronizada com `origin/master` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| `/health` | HTTP 200, `status=healthy`, `environment=production` |
| Backend `git_sha` | `dc53d092ee9f1955a52d2e0fd45d22298ca91540` |
| Device escolhido | iPhone 15 Simulator |
| Device id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Android preferencial | `SM A135M/R58T300SREH` nao conectado |
| Evidencias | `app/doc/runtime_flow_proofs_2026-05-15_release_non_scanner_runtime/` |

## Comandos executados

```bash
git status --short --branch
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
curl -sS https://evolution-cartinhas.8ktevp.easypanel.host/health

cd app
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check

flutter test integration_test/sets_search_catalog_runtime_test.dart -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
flutter test integration_test/deck_runtime_m2006_test.dart -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=RUNTIME_OPTIMIZE_INTENSITY_LABEL=Focado --reporter expanded --no-version-check
flutter test integration_test/deck_runtime_m2006_test.dart -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=RUNTIME_OPTIMIZE_INTENSITY_LABEL=Agressivo --reporter expanded --no-version-check
flutter test integration_test/commander_reference_feather_app_runtime_test.dart -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
```

## Fluxos provados

| Fluxo | Resultado | Evidencia |
|---|---:|---|
| Backend health publico + `git_sha` | PASS | `00_environment.sanitized.log` |
| Search Cards, Card Detail, Search/Colecoes, Set Detail | PASS | `01_sets_search_catalog_runtime.sanitized.log`, 4 PNGs |
| Register, criar deck Commander, abrir Deck Details | PASS | `02_deck_runtime_focused_rerun.sanitized.log` |
| Import-to-deck com comandante na lista | PASS | `06_import_commander`, `07_commander_imported` |
| Import-to-deck sem comandante preservando comandante existente | PASS | `07b_import_without_commander`, `07c_commander_preserved` |
| Optimize focado, preview selecionavel, partial apply, validate final | PASS | `09_preview`, `09b_preview_partial_selection`, `10_complete_validated` |
| Optimize agressivo com UX amigavel quando nao aplicavel | PASS_WITH_RISKS | `03_deck_runtime_aggressive__09_friendly_optimize_failure.png` |
| AI Generate async com `commander_name`, salvar deck, details, validate | PASS | `04_commander_reference_feather_generate.sanitized.log` |
| Home, Decks, Community, Collection, Profile | PASS | `06_app_full_non_scanner_smoke.sanitized.log` |
| Binder add/list/update/delete | PASS | `05_binder_marketplace_trade_messages_notifications_rerun3.sanitized.log` |
| Marketplace list + create trade review | PASS | `market_trade_02` a `market_trade_04` |
| Trades status lifecycle + trade chat | PASS | `market_trade_05` a `market_trade_10` |
| Notifications list, tap/read, read-all | PASS | `market_trade_11_notifications` |
| Direct Messages inbox, chat, read receipt, reply | PASS | `messages_01_inbox`, `messages_02_conversation` |
| Logout/troca de conta sem stale state no harness de trades | PASS_WITH_RISKS | `AuthProvider.logout()` + sessao QA tokenizada por API, sem reusar estado de provider |

## Correcoes de harness aplicadas

- `app/integration_test/deck_runtime_m2006_test.dart`
  - adicionou prova de importacao sem comandante usando `replace_all=true` e lista de 99 cartas sem tag `[Commander]`;
  - confirma via API que `Talrand, Sky Summoner` permanece como unico comandante antes do optimize.
- `app/integration_test/binder_marketplace_trade_runtime_test.dart`
  - envia mensagem de trade via `TextInputAction.send`, evitando tap fragil em botao coberto/desabilitado pelo viewport;
  - adiciona router real para `MessageInboxScreen -> ChatScreen`, eliminando fallback sem `GoRouter`;
  - troca login repetido entre contas QA por seed autenticado via token descartavel ja emitido pelo backend, preservando `AuthProvider.logout()` e evitando stale state;
  - faz retry unico e explicitamente logado quando o backend publico retorna 429 de auth setup.

## Riscos restantes aceitos

- Optimize agressivo retornou falha amigavel/no apply nesta rodada; o apply seletivo ficou provado no modo focado.
- O backend publico aplicou rate limit distribuido durante setup de usuarios QA; o harness aguardou `retry_after=60` e repetiu uma vez.
- Warnings de plugins nativos de scanner/Firebase no build do simulador continuam ambientais; scanner/camera/OCR/MLKit nao foram acionados.
- O smoke amplo capturou Generate em estado `preview_not_proven`, mas Generate Commander com `commander_name` foi provado separadamente no harness Feather.

## Mocking

Nao houve mock de backend nos runtimes listados. As telas/harnesses usaram app Flutter real no iPhone 15 Simulator e backend publico real. O harness de Binder/Trades usa widgets/providers reais com setup por API para criar dados descartaveis de usuarios, binder, trade e mensagens.
