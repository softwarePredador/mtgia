# Commander Reference Feather app runtime handoff - 2026-05-15

## Resultado

**PASS** em 2026-05-15T10:48-03:00.

O runtime real de `Feather, the Redeemed` passou no **iPhone 15 Simulator**
(`F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4) contra o backend publico
`https://evolution-cartinhas.8ktevp.easypanel.host`, cobrindo register/login pela
UI, Generate Commander com `commander_name`, feedback async, preview, save, Deck
Details e `/decks/:id/validate`.

Scanner, camera e OCR permaneceram fora do escopo. Artifacts e documentacao
mantem secrets, tokens, JWT, `SENTRY_DSN`, `DATABASE_URL`, `OPENAI_API_KEY`,
e-mail QA completo, prompt bruto e decklist completa fora do repositorio.

## Fontes lidas antes da validacao

- `server/doc/RELATORIO_COMMANDER_REFERENCE_FEATHER_TIMEOUT_FIX_2026-05-14.md`
- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT4_LOT1_PUBLIC_PROOF_2026-05-14.md`
- `app/integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint4_lot1_app_2026-05-14.md`

## Repositorio/branch/backend

- Branch alvo: `master`.
- HEAD local durante runtime: `6e155224ea2306d944dc8aa20d93576aa29ff8ee`.
- Backend publico `/health`: HTTP 200, `status=healthy`,
  `git_sha=6e155224ea2306d944dc8aa20d93576aa29ff8ee`.
- O harness de Miirym foi preservado; a cobertura Feather ficou isolada em
  `app/integration_test/commander_reference_feather_app_runtime_test.dart`.

## Validacao local focada

```bash
cd app
dart format \
  integration_test/commander_reference_feather_app_runtime_test.dart \
  integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart
flutter analyze \
  integration_test/commander_reference_feather_app_runtime_test.dart \
  integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart \
  --no-version-check
flutter test test/features/decks/providers/deck_provider_test.dart \
  --no-version-check
```

Resultado: **PASS**. O analyze nao encontrou issues e
`deck_provider_test.dart` terminou com todos os testes passando.

## Runtime iPhone 15 Simulator

Comando executado:

```bash
cd app
flutter test integration_test/commander_reference_feather_app_runtime_test.dart \
  -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Resultado: **PASS** (`00:39 +1: All tests passed!`).

Latencias relevantes observadas:

- `/health`: `latency_ms=1085`.
- Feedback inicial de Generate Commander: `elapsed_ms=764`.

Resumo final sanitizado:

```json
{
  "deck_id": "<redacted-deck-id>",
  "commander": "Feather, the Redeemed",
  "archetype": "boros_heroic_spellslinger",
  "app_runtime_valid": true,
  "deck_commander_name_matches": true,
  "raw_commander_entries": 1,
  "raw_commander_names": ["Feather, the Redeemed"],
  "validation_ok": true,
  "main_quantity": 99,
  "total": 100,
  "commander_count": 1,
  "commander_in_99_count": 0,
  "off_identity": 0
}
```

## Evidencia sanitizada

Diretorio:

- `app/doc/runtime_flow_proofs_2026-05-15_commander_reference_feather_app/`

Arquivos:

- `SUMMARY.md`
- `device_discovery_2026-05-15.txt`
- `commander_reference_feather_app_runtime_iphone15_2026-05-15_sanitized.log`

O log sanitizado remove e-mail QA completo, JWT/header, deck id e chunks base64
de screenshots. Nenhum PNG foi persistido nesta rodada para evitar capturar PII
visual; o log mantem os marcadores `CAPTURE_START`/`CAPTURE_TAKEN` e os asserts
do harness cobrem erro cru, overflow/excecao Flutter e modal preso.

## O que foi real, mockado e nao provado

- Real: branch `master` sincronizada, backend publico `/health` HTTP 200,
  register/login pela UI, Generate Commander com `commander_name`, feedback async,
  preview, save, Deck Details e validacao API no iPhone 15 Simulator.
- Mockado: nada.
- Nao provado nesta rodada: scanner, camera e OCR, por estarem fora do escopo.

Resultado final desta rodada: **PASS**.
