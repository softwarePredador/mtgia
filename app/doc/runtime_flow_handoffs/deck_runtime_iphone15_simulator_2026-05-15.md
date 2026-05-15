# Deck Runtime iPhone 15 Simulator - 2026-05-15

## Verdict

**PASS_WITH_RISKS** para runtime QA non-scanner de release interno.

Scanner/camera/OCR/MLKit: **DEFERRED / NOT PROVEN**.

## Runtime environment

| Item | Valor |
|---|---|
| Data/hora | 2026-05-15, tarde BRT |
| Device | iPhone 15 Simulator |
| Device id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| `flutter devices` | iPhone fisico iOS 26.5, iPhone 15 Simulator bootado, macOS, Chrome |
| Backend URL | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Backend health | HTTP 200 `healthy` |
| Backend `git_sha` | `dc53d092ee9f1955a52d2e0fd45d22298ca91540` |
| Evidencias | `app/doc/runtime_flow_proofs_2026-05-15_release_non_scanner_runtime/` |

## Commands

As execucoes usaram sempre:

```bash
--dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
--dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
-d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF
--reporter expanded --no-version-check
```

Arquivos executados:

- `integration_test/sets_search_catalog_runtime_test.dart`: PASS.
- `integration_test/deck_runtime_m2006_test.dart` com `RUNTIME_OPTIMIZE_INTENSITY_LABEL=Focado`: PASS.
- `integration_test/deck_runtime_m2006_test.dart` com `RUNTIME_OPTIMIZE_INTENSITY_LABEL=Agressivo`: PASS_WITH_RISKS por falha amigavel/no apply.
- `integration_test/commander_reference_feather_app_runtime_test.dart`: PASS.
- `integration_test/binder_marketplace_trade_runtime_test.dart`: PASS apos retry de rate limit de setup.
- `integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart`: PASS.

## What was real

- App Flutter real no iPhone 15 Simulator.
- Backend publico real.
- Cadastro/login UI descartavel nos fluxos de app shell/deck/generate.
- Dados reais descartaveis no backend para decks, binder, trades, mensagens e notificacoes.
- Search/cards/sets, Deck Details, Import List, Optimize, Generate, Binder, Marketplace, Trades, Messages, Notifications e navegacao shell non-scanner.

## What was mocked

Nada no backend. O harness de Binder/Trades monta dados por API e usa widgets/providers reais em rotas controladas para reduzir dependencia de estado externo do shell.

## Result summary

- Search Cards/Colecoes e Set Detail: PASS.
- Home/Decks/Community/Collection/Profile: PASS.
- Register/Login: PASS em app shell/deck/generate.
- Create Commander deck e Deck Details: PASS.
- Import com comandante: PASS.
- Import sem comandante preservando comandante existente: PASS.
- Optimize focado: preview com multiplas sugestoes, desmarcacao parcial e apply seletivo: PASS.
- Optimize agressivo: copy amigavel para falha/no-op, sem erro cru: PASS_WITH_RISKS.
- Validate final deck: PASS no fluxo focado e no Generate Feather.
- AI Generate async com `commander_name`: PASS para `Feather, the Redeemed`.
- Binder add/list/update/delete: PASS.
- Marketplace list e proposta: PASS.
- Trades status lifecycle, chat, notifications: PASS.
- Direct Messages inbox/chat/read/reply: PASS.
- Logout/troca de conta: PASS_WITH_RISKS; provado com `AuthProvider.logout()` e seed de token QA descartavel para evitar rate limit publico.

## Blockers / risks

- `SM A135M/R58T300SREH` nao estava conectado; iPhone 15 Simulator foi usado como alvo primario disponivel.
- Backend publico retornou 429 em setup de usuarios no harness de mensagens; retry unico respeitou `retry_after=60`.
- Optimize agressivo nao provou apply nesta rodada; o apply seletivo ficou provado no modo focado.
- Scanner/camera/OCR/MLKit permanecem deferred.

## Smallest next actions

1. Repetir optimize agressivo quando o backend estiver fora de janela de no-op/falha amigavel, exigindo preview/apply.
2. Manter retry/backoff explicito em harnesses publicos que criam varias contas QA.
