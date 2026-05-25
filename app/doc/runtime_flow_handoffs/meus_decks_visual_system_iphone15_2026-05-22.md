# Meus Decks Visual System iPhone Runtime - 2026-05-22

## Status

`PASS_WITH_RISKS`

## Objetivo

Provar em runtime vivo no iPhone Simulator que as telas non-scanner ajustadas
para o padrao visual de `Meus Decks` continuam renderizando e navegando sem
crash, overflow deterministico, modal preso ou quebra de fluxo.

Esta rodada valida consistencia visual por captura real. Ela nao substitui a
revisao pixel a pixel com o designer para cada mockup.

## Ambiente

- App runtime: iPhone 15 Pro Max Simulator
  `DABB9D79-2FDB-4585-94DB-E31F1288EE74`.
- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Health final: `status=healthy`, `environment=production`,
  `git_sha=9719572355ce48fb5665f4e02d5d7c8476e9de95`.
- Firebase startup/performance init ficaram desligados por dart define nos
  harnesses de runtime.
- Scanner, camera, OCR e MLKit ficaram fora do escopo.

## Cobertura provada

| Grupo | Harness/capturas |
| --- | --- |
| Splash, Auth, Home, onboarding, Decks, create deck, Deck Details, Deck Import, Generate, Community, Collection e Profile entrypoints | `app_full_non_life_counter_visual_capture_smoke_test.dart` com capturas `app_full_00`, `app_full_01` ate `app_full_09` e `app_full_04c`. |
| Card Search, Card Detail, Sets/Colecoes e Set Detail | `sets_search_catalog_runtime_test.dart` com capturas `sets_search_01` ate `sets_search_04`. |
| Modal de adicionar carta com escolha de comandante | `card_add_commander_choice_runtime_test.dart` com captura `card_add_commander_choice_modal`. |
| Collection tabs, Binder, Marketplace, Trades entrypoint, Sets catalog e Market | `collection_entrypoints_runtime_test.dart` com capturas `collection_01` ate `collection_05`. |
| Binder editor, Binder populado, Marketplace, proposta, ciclo de trade, trade chat, Notifications, Messages inbox e conversa | `binder_marketplace_trade_runtime_test.dart` com capturas `market_trade_00` ate `market_trade_11` e `messages_01` ate `messages_02`. |
| Profile, User Profile, User Search, Community Explore, Community Deck Detail, Following e Users | `profile_community_runtime_test.dart` com capturas `profile_community_01` ate `profile_community_07`. |

As capturas resultantes cobrem background, tipografia, bordas, botoes, bottom
navigation, empty/error states e modais das familias de tela alteradas nesta
rodada visual.

## Comandos runtime

Todos foram executados em `app/` contra o backend publico acima:

```bash
flutter test integration_test/collection_entrypoints_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check

flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check

flutter test integration_test/card_add_commander_choice_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check

flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check

flutter test integration_test/binder_marketplace_trade_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check

flutter test integration_test/profile_community_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check
```

## Resultado dos harnesses

| Harness | Resultado |
| --- | --- |
| `collection_entrypoints_runtime_test.dart` | `00:18 +2: All tests passed!` |
| `sets_search_catalog_runtime_test.dart` | `00:29 +1: All tests passed!` |
| `card_add_commander_choice_runtime_test.dart` | `00:13 +1: All tests passed!` |
| `app_full_non_life_counter_visual_capture_smoke_test.dart` | `00:50 +1: All tests passed!` no rerun final que adicionou `Splash` e `Deck Import`. |
| `binder_marketplace_trade_runtime_test.dart` | `02:09 +2: All tests passed!` |
| `profile_community_runtime_test.dart` | `00:33 +1: All tests passed!` |
| `app_full_non_life_counter_visual_capture_smoke_test.dart` token audit rerun | `00:51 +1: All tests passed!` em `/tmp/manaloom_layout_uniformity_token_audit_20260522.log`. |
| `flutter test test --no-version-check --reporter compact` | `01:52 +590: All tests passed!`. |

## Evidencias

- Proof folder local sanitizado:
  `app/doc/runtime_flow_proofs_2026-05-22_meus_decks_visual_system_iphone15/`.
- Inventario: `capture_inventory.txt`.
- Contact sheet global: `contact_sheet_all_visual_captures.jpg`.
- Capturas decodificadas base, recapturas de auth e capturas adicionais
  `app_full_00_splash.png` e `app_full_04c_deck_import.png`.
- Logs locais de runtime: `/tmp/manaloom_visual_*_20260522.log`.
- Recaptura da auth apos aplicar logo nova e shell visual conectado a splash:
  `auth_refresh_01_login.png`, `auth_refresh_02_register_filled.png`,
  `auth_refresh_03_home.png` e `/tmp/manaloom_auth_visual_20260522.log`.
- Matriz de uniformidade por rota/surface:
  `docs/qa/manaloom_layout_uniformity_audit_iphone15_2026-05-22.md`.
- Contact sheet do rerun final:
  `contact_sheet_app_full_token_audit.jpg`.
- Auditoria de tokens visuais:
  a varredura non-scanner de `Color(0x...)`/`Colors.*` foi reduzida para zero
  ocorrencias reais em telas auditadas; o match remanescente e apenas a variavel
  `identityColors` em `card_detail_screen.dart`.
- Golden estabilizado:
  `app/test/features/home/goldens/home_hero_sma135m.png` foi atualizado apos
  substituir overlays hardcoded por tokens do `AppTheme`, e o teste agora faz
  pre-cache do banner antes da comparacao.

## Riscos remanescentes

- A captura `app_full_06_generate_preview_not_proven` registra o branch em que
  o preview de generate nao ficou provado no smoke amplo; as telas anteriores e
  posteriores do harness passaram.
- O entrypoint isolado de Trade Inbox dentro de Collection capturou um estado de
  auth/token vazio. O inbox populado foi provado no ciclo real de trade por
  `market_trade_05_trade_list`.
- O backend publico retornou um `429` no setup do runtime de
  `binder_marketplace_trade_runtime_test.dart`; o retry do harness aguardou e o
  fluxo completo passou.
- Esta prova e no simulador iOS. Build assinado em device fisico e scanner
  continuam como gates separados quando reabertos.
