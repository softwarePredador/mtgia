# ManaLoom Lorehold Commander flow - 2026-05-11

## Resultado

**PASS** para prova publica de `Lorehold Reference Card Stats v1` e para runtime
visual no device fisico `SM A135M` / `R58T300SREH`.

Scanner/camera/OCR/MLKit nao foram testados nem acionados.

## Escopo

- Confirmar que o backend publico
  `https://evolution-cartinhas.8ktevp.easypanel.host` esta no commit
  `59c75ff`.
- Provar `/ai/generate` publico com `commander_name=Lorehold, the Historian` e
  diagnostics `reference_profile_used=true` e `reference_card_stats_used=true`.
- Provar no app o fluxo register -> Decks -> Gerar com IA -> campo comandante
  Lorehold -> preview -> salvar -> abrir detalhe -> validar deck salvo por API.
- Registrar latencias, bloqueios ambientais, screenshots/logs e classificacao
  tematica sem expor JWT, tokens, emails reais, secrets ou payload sensivel.

## Evidencia de ambiente

| Item | Resultado |
| --- | --- |
| Branch | `master`, sincronizada com `origin/master` |
| Commit local | `59c75ff Add Lorehold reference card stats` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| `/health` publico | `200`, `status=healthy`, `git_sha=59c75ff735357832c854aebf051acfb0da8c9834` |
| Device alvo | `SM A135M` / `R58T300SREH` |
| Device discovery | `flutter devices`: `SM A135M (mobile) • R58T300SREH • android-arm • Android 14 (API 34)` |
| Fallback disponivel | `iPhone 15` Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, mas nao foi necessario |

## Prova publica sanitizada de Reference Card Stats v1

Fluxo executado por API publica com usuario QA descartavel, sem registrar JWT,
email real, token, payload sensivel ou secrets.

Primeiras tentativas async:

- `POST /ai/generate async=true` foi aceito, mas o poll recebeu `429`.
- Nova tentativa imediata recebeu `429` no generate.
- Classificacao: tentativa valida como evidencia de rate limit publico; nao foi
  mascarada.

Prova final apos janela de rate limit: `POST /ai/generate` sincrono com
`format=commander` e `commander_name=Lorehold, the Historian`.

| Criterio | Valor |
| --- | --- |
| HTTP | `200` |
| Latencia `/health` | `618ms` |
| Latencia register | `742ms` |
| Latencia generate sync | `627ms` |
| `diagnostics.reference_profile_used` | `true` |
| `diagnostics.reference_card_stats_used` | `true` |
| `on_theme_candidate_count` | `34` |
| `package_keys` | `interaction_and_resets`, `miracle_payoffs_expensive_spells`, `spell_payoff_copy_package`, `topdeck_and_miracle_setup` |
| `unresolved_reference_cards` | `[]` |
| `reference_deck_evaluation.classification` | `on_theme` |
| `reference_deck_evaluation.counts` | `on_theme=31`, `generic=57`, `questionable=11`, `off_theme=0` |
| Main deck | `99` |
| Total com comandante | `100` |
| Lorehold comandante | `1` |
| Lorehold nas 99 | `0` |
| Off-identity | `0` |
| Validacao | `true` |

## Prova runtime app no SM A135M

Handoff detalhado:
`app/doc/runtime_flow_handoffs/lorehold_reference_stats_sm_a135m_2026-05-11.md`.

Comando executado:

```bash
cd app
set -o pipefail
flutter test integration_test/lorehold_generate_reference_stats_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Resultado runtime: **PASS** (`00:57 +1: All tests passed!`).

| Checkpoint | Evidencia |
| --- | --- |
| Backend usado pelo app | `LOREHOLD_RUNTIME_BASE_URL https://evolution-cartinhas.8ktevp.easypanel.host` |
| Health no app | `status=200`, `git_sha=59c75ff735357832c854aebf051acfb0da8c9834`, `latency_ms=1447` |
| Feedback inicial generate | `858ms` ate "Pedido aceito" |
| Deck salvo | `18da672e-f48b-4e6c-8a65-bb828e6a28b8` |
| Validacao API | `validation_ok=true` |
| Classificacao QA | `on_theme` |
| Matches de reference package | `33` |
| Main deck | `99` |
| Total com comandante | `100` |
| Lorehold comandante | `1` |
| Lorehold nas 99 | `0` |
| Off-identity | `0` |
| Erro bruto/overflow/modal preso | Nao observado na prova PASS |

Screenshots extraidas:

- `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_01_login.png`
- `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_02_registered.png`
- `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_03_prompt_with_commander.png`
- `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_04_preview.png`
- `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_05_saved.png`
- `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_06_details.png`

Logs:

- Tentativa 1 bloqueada pelo harness/teclado:
  `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_reference_stats_runtime_attempt1_failed.filtered.log`
- Prova PASS:
  `app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/lorehold_generate_reference_stats_runtime_pass.filtered.log`

## Mudanca app-side desta rodada

- `DeckListScreen` ganhou a key `deck-list-empty-generate-button` para acionar o
  fluxo Generate em lista vazia sem depender apenas de texto.
- `lorehold_generate_reference_stats_runtime_test.dart` cobre o fluxo visual no
  app e valida o deck salvo por API.
- `UI_TEST_SURFACE_MAP.md` foi atualizado com a nova key/harness.

## Comandos de validacao

```bash
git status --short
git fetch origin master --quiet
git pull --ff-only origin master
flutter devices --no-version-check
adb devices -l
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
cd app && flutter analyze lib/features/decks/screens/deck_list_screen.dart integration_test/lorehold_generate_reference_stats_runtime_test.dart --no-version-check
cd app && flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart --no-version-check
cd app && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check
cd app && flutter test integration_test/lorehold_generate_reference_stats_runtime_test.dart -d R58T300SREH --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=DISABLE_FIREBASE_STARTUP=true --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true --reporter expanded --no-version-check
```

Resultados:

- Analyze focado: PASS.
- Testes focados de deck: PASS.
- Runtime SM A135M: PASS.

## Observacoes e riscos

- O backend publico esta no commit correto e Reference Card Stats v1 foi provado
  publicamente.
- Rate limit publico de IA foi observado em tentativas async/polling (`429`); a
  prova final usou geracao sync apos aguardar a janela. O app runtime PASS usou o
  fluxo async normal e completou sem `429`.
- Reference Card Stats v1 segue propositalmente Lorehold-only.
