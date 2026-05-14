# Commander Reference Sprint 4 Lote 1 App Runtime Handoff - 2026-05-14

## Resultado

**PASS_WITH_MINOR_HARNESS_FIX** em 2026-05-14T16:40-03:00.

O runtime real do Lote 1 passou no **iPhone 15 Simulator**
(`F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4) contra o backend publico
`https://evolution-cartinhas.8ktevp.easypanel.host`, cobrindo
`Miirym, Sentinel Wyrm` de ponta a ponta: register/login pela UI, Generate
Commander com `commander_name`, feedback async, preview, save, Deck Details e
`/decks/:id/validate`.

Scanner, camera e OCR permaneceram fora do escopo. Logs e documentacao abaixo
mantem e-mail QA completo, decklist completa, secrets, tokens, JWT,
`SENTRY_DSN`, `DATABASE_URL` e `OPENAI_API_KEY` fora do repositorio.

## Repositorio/branch

- Branch alvo: `master`.
- Base sincronizada antes da mudanca:
  `34576f51e710e10c950f787ae2f91aa6f77e3cba`.
- Commit com a correcao do harness em `master`:
  `dd918fc5b9e95f0c1f551f48bd73752b817ab8b4`.
- `git status` antes da mudanca e apos o push: limpo e alinhado a
  `origin/master`.
- Backend publico `/health`: HTTP 200, `status=healthy`,
  `git_sha=34576f51e710e10c950f787ae2f91aa6f77e3cba`,
  `latency_ms=1148`.

## Correcao menor do harness

O campo `deck_commander_name_matches` do summary do harness foi corrigido para
representar validacao real: agora ele compara o comandante esperado contra
`raw_commander_names`, normalizado a partir das entradas reais de `commander` do
`GET /decks/:id`. O campo agregado `deck['commander_name']` continua sendo usado
somente como fallback para contar comandante quando a API nao enviar a lista
`commander`, mas nao determina mais `deck_commander_name_matches`.

Essa correcao remove a inconsistencia observada na prova recebida, onde os gates
reais estavam corretos (`raw_commander_names=['Miirym, Sentinel Wyrm']`,
`commander_count=1`, `commander_in_99_count=0`) apesar do campo antigo poder
ficar falso por depender do agregado.

## Validacao local focada

```bash
cd app
dart format integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart
flutter analyze integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart --no-version-check
flutter test test/features/decks/providers/deck_provider_test.dart --no-version-check
```

Resultado: **PASS**. O analyze nao encontrou issues e
`deck_provider_test.dart` terminou com todos os testes passando.

## Runtime iPhone 15 Simulator

Comando executado:

```bash
cd app
flutter test integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart \
  -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Resultado: **PASS** (`00:41 +1: All tests passed!`).

Latencias relevantes observadas:

- `/health`: `latency_ms=1148`.
- Feedback inicial de Generate Commander: `elapsed_ms=587`.
- Public proof backend de Miirym ja documentado: p50 `849ms`, p95 `942ms`.

Resumo final sanitizado:

```json
{
  "deck_id": "<redacted-deck-id>",
  "commander": "Miirym, Sentinel Wyrm",
  "archetype": "temur_dragons_etb_copy",
  "app_runtime_valid": true,
  "deck_commander_name_matches": true,
  "raw_commander_entries": 1,
  "raw_commander_names": ["Miirym, Sentinel Wyrm"],
  "validation_ok": true,
  "main_quantity": 99,
  "total": 100,
  "commander_count": 1,
  "commander_in_99_count": 0,
  "off_identity": 0
}
```

## O que foi real, mockado e nao provado

- Real: branch `master` sincronizada, backend publico `/health` HTTP 200,
  harness corrigido, analyze/test focados passando e runtime completo no
  iPhone 15 Simulator.
- Mockado: nada.
- Nao provado nesta rodada: scanner, camera e OCR, por estarem fora do escopo.

Resultado final desta rodada: **PASS_WITH_MINOR_HARNESS_FIX**.
