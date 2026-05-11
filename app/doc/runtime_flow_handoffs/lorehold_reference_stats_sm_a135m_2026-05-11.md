# Lorehold Reference Stats runtime - SM A135M - 2026-05-11

## Resultado

**PASS** no device fisico `SM A135M` / `R58T300SREH` contra o backend publico
`https://evolution-cartinhas.8ktevp.easypanel.host`.

## Ambiente

| Item | Evidencia |
| --- | --- |
| Data/hora | 2026-05-11, rodada QA BRT |
| Repo/branch | `master`, `59c75ff Add Lorehold reference card stats` |
| Backend | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Backend health | `200`, `git_sha=59c75ff735357832c854aebf051acfb0da8c9834` |
| Device primario | `SM A135M (mobile) • R58T300SREH • android-arm • Android 14 (API 34)` |
| Fallback descoberto | `iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • iOS 17.4`, nao usado |
| Scanner/OCR | Fora de escopo; nao testado |

## Comando runtime

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

Resultado: `00:57 +1: All tests passed!`.

## O que foi real

- App Flutter instalado/executado via `flutter test` no Android fisico.
- Registro de usuario QA descartavel pela UI.
- Navegacao Decks -> Generate usando key em lista vazia.
- Campo comandante preenchido com `Lorehold, the Historian`.
- `/ai/generate` consumido pelo app contra backend publico.
- Preview visual antes de salvar.
- Deck salvo no backend publico e aberto em Deck Details.
- `GET /decks`, `GET /decks/:id` e `POST /decks/:id/validate` reais para
  confirmar persistencia e validade.

## O que foi mockado

Nada no fluxo app/backend. Firebase startup/performance foi desabilitado por
`dart-define` para evitar ruido externo de QA; isso nao substitui API, auth,
generate, deck save ou validacao.

## Evidencia principal

| Item | Valor |
| --- | --- |
| Base URL no app | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Health pelo app | `status=200`, `latency_ms=1447`, `git_sha=59c75ff735357832c854aebf051acfb0da8c9834` |
| Feedback inicial | `LOREHOLD_RUNTIME_INITIAL_FEEDBACK_MS 858` |
| Deck salvo | `18da672e-f48b-4e6c-8a65-bb828e6a28b8` |
| Summary | `classification=on_theme`, `on_theme_reference_matches=33`, `validation_ok=true` |
| Construção | `main_qty=99`, `total_with_commander=100`, `lorehold_commander_count=1`, `lorehold_in_99_count=0`, `off_identity_count=0` |

## Prova publica de diagnostics backend

Probe publico sanitizado de `/ai/generate` sync apos janela de rate limit:

- `reference_profile_used=true`
- `reference_card_stats_used=true`
- `on_theme_candidate_count=34`
- `package_keys=[interaction_and_resets, miracle_payoffs_expensive_spells, spell_payoff_copy_package, topdeck_and_miracle_setup]`
- `unresolved_reference_cards=[]`
- `reference_deck_evaluation.classification=on_theme`
- `counts: on_theme=31, generic=57, questionable=11, off_theme=0`
- `validation=true`, 100 cartas, Lorehold unico no slot de comandante, 0 off-identity.

## Screenshots e logs

Pasta:
`app/doc/runtime_flow_proofs_2026-05-11_sm_a135m_lorehold_reference_stats/`

Screenshots:

- `lorehold_generate_01_login.png`
- `lorehold_generate_02_registered.png`
- `lorehold_generate_03_prompt_with_commander.png`
- `lorehold_generate_04_preview.png`
- `lorehold_generate_05_saved.png`
- `lorehold_generate_06_details.png`

Logs:

- `lorehold_generate_reference_stats_runtime_attempt1_failed.filtered.log`
- `lorehold_generate_reference_stats_runtime_pass.filtered.log`

## Tentativas e bloqueios

- Tentativa 1 no device falhou antes de chamar `/ai/generate`: o teclado/overlay
  interceptou o tap em `deck-generate-submit-button`. Corrigido no harness com
  unfocus/fechamento de teclado e `ensureVisible`.
- Rate limit publico `429` foi observado no probe API async/polling antes da
  prova final sync; nao ocorreu no runtime PASS.
- Nenhum crash, overflow, erro bruto 4xx/5xx, modal preso ou timeout foi
  observado na prova PASS.

## Menor proxima acao

Sem bloqueio para Lorehold Reference Card Stats v1. Manter monitoramento de
rate limit para probes async publicos longos, porque polling tambem consome o
bucket de IA.
