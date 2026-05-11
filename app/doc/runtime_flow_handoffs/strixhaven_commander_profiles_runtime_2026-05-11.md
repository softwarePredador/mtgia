# Strixhaven Commander Profiles Runtime - 2026-05-11

## Resultado

**PASS.** O app real no Android fisico `SM A135M` validou os Commander
Reference Profiles de Secrets of Strixhaven aplicados no backend publico.

## Ambiente

- Data/hora: `2026-05-11T15:44-03:00`
- Branch/head: `master` em `2e0702f Apply Strixhaven commander reference profiles`
- Backend usado pelo app: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Health: `200`, `status=healthy`, `git_sha=2e0702fb6face5721e53621a792d5ba15cd6705f`
- Device primario: `SM A135M` / `R58T300SREH` / Android 14 API 34
- Fallback disponivel, nao usado: `iPhone 15` Simulator
  `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, booted

## Comando executado

```bash
cd app
flutter test integration_test/strixhaven_commander_profiles_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

## Fluxo real validado

- UI real: register, login, aba Decks, Generate Commander, preview, save,
  Deck Details.
- Backend real: `/health`, `/auth/register`, `/auth/login`, `/ai/generate`
  async/poll, `/decks`, `/decks/:id`, `/decks/:id/validate`.
- Mockado: nada.
- Fora de escopo e nao usado: Scanner, camera, OCR, MLKit.

## Evidencia por comandante

| Commander | Diagnostics | Deck salvo | Validacao |
|---|---|---|---|
| Lorehold, the Historian | `reference_profile_used=true`, `reference_card_stats_used=true`, `on_theme_candidate_count=34`, `unresolved_reference_cards=0` | `4636850d-887e-430e-8d83-94b6d4314acd` | 99 main + 1 commander, comandante unico fora das 99, 0 off-identity, `validation_ok=true` |
| Dina, Essence Brewer | `reference_profile_used=true`, `reference_card_stats_used=true`, `on_theme_candidate_count=39`, `unresolved_reference_cards=0` | `a9de0dbb-219f-40df-a884-3ae52c946c77` | 99 main + 1 commander, comandante unico fora das 99, 0 off-identity, `validation_ok=true` |
| Zimone, Infinite Analyst | `reference_profile_used=true`, `reference_card_stats_used=true`, `on_theme_candidate_count=42`, `unresolved_reference_cards=0` | `9421b0d2-c2ab-4e2d-a632-fba443bec181` | 99 main + 1 commander, comandante unico fora das 99, 0 off-identity, `validation_ok=true` |

## Artefatos

- Device discovery: `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_strixhaven/device_discovery.log`
- Backend health: `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_strixhaven/backend_health.log`
- Tentativa 1 sanitizada: `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_strixhaven/strixhaven_commander_profiles_runtime_attempt1_sanitized.log`
- Tentativa 2 PASS sanitizada: `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_strixhaven/strixhaven_commander_profiles_runtime_attempt2_sanitized.log`

Screenshots foram capturados como markers sanitizados no log PASS:
`strixhaven_01_login`, `strixhaven_02_registered`, `strixhaven_03_logged_in`,
`strixhaven_lorehold_01_prompt`, `strixhaven_lorehold_02_preview`,
`strixhaven_lorehold_03_details`, `strixhaven_dina_01_prompt`,
`strixhaven_dina_02_preview`, `strixhaven_dina_03_details`,
`strixhaven_zimone_01_prompt`, `strixhaven_zimone_02_preview` e
`strixhaven_zimone_03_details`.

## Tentativa 1

**Falhou por harness**, nao por backend/produto: apos register, o teste limpou
SharedPreferences e reinjetou `ManaLoomApp` sem trocar a key da arvore, mantendo
estado antigo de provider. A correcao trocou a arvore por `SizedBox.shrink()` e
reiniciou `ManaLoomApp(key: UniqueKey())`; a tentativa 2 passou.

## Validacoes locais

- `flutter analyze lib/features/decks test/features/decks integration_test --no-version-check`: PASS.
- `flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart --no-version-check`: PASS.
- `flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check`: PASS.

## Blockers e proximas acoes

- Blockers: nenhum.
- Menor proxima acao: manter `strixhaven_commander_profiles_runtime_test.dart`
  como regressao device para novos lotes de Commander Reference Profiles.
