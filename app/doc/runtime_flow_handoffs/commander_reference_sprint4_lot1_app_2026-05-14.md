# Commander Reference Sprint 4 Lote 1 App Runtime Handoff - 2026-05-14

## Resultado

**BLOCKED** em 2026-05-14T15:08-03:00.

O harness especifico do Lote 1 foi criado para `Miirym, Sentinel Wyrm`, mas a
prova no Android fisico solicitado nao executou porque o device alvo
`SM A135M` (`R58T300SREH`) nao estava conectado ao ADB/Flutter. O unico Android
detectado foi outro aparelho (`M2006C3MG`, Android 10/API 29), que nao substitui
o alvo da prova.

Scanner, camera e OCR permaneceram fora do escopo.

## Fontes lidas antes da validacao

- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT4_LOT1_PUBLIC_PROOF_2026-05-14.md`
- `app/doc/runtime_flow_handoffs/commander_reference_sprint4_lot1_app_2026-05-14.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `app/integration_test/commander_reference_sprint3_lot_c_app_runtime_test.dart`
- `app/integration_test/runtime_test_helpers.dart`

## Repositorio/branch

- Branch alvo: `master`.
- HEAD local: `5c316ab6ac0b4513a91653faceacec11039ecae8`.
- `origin/master`: `5c316ab6ac0b4513a91653faceacec11039ecae8`.
- `git status` antes da mudanca: limpo e alinhado a `origin/master`.
- Backend publico `/health`: HTTP 200, `status=healthy`,
  `git_sha=5c316ab6ac0b4513a91653faceacec11039ecae8`.

## Harness criado

- Arquivo:
  `app/integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart`.
- Fluxo coberto: register/login QA descartavel pela UI, Generate Commander com
  `commander_name=Miirym, Sentinel Wyrm`, prompt Temur dragons ETB/copy com
  ramp/draw/removal/protection, feedback async, preview, save, Deck Details e
  `/decks/:id/validate`.
- Gates de API no harness: `validation_ok=true`, `main_quantity=99`,
  `total=100`, `commander_count=1`, `commander_in_99_count=0` e
  `off_identity=0`.
- Gates de UI no harness: tela de preview, tela de detalhes, ausencia de erro cru,
  `AlertDialog`/`SimpleDialog`/`Dialog` preso e excecao Flutter/overflow.

## Validacao local focada

```bash
cd app
dart format integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart
flutter analyze integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart --no-version-check
flutter test test/features/decks/providers/deck_provider_test.dart --no-version-check
```

Resultado: **PASS**. O analyze nao encontrou issues e
`deck_provider_test.dart` terminou com todos os testes passando.

## Runtime Android solicitado

Comando executado:

```bash
cd app
flutter test integration_test/commander_reference_sprint4_lot1_app_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

Resultado: **BLOCKED antes do build/install**. `adb -s R58T300SREH get-state`,
`adb -s R58T300SREH shell svc wifi disable`, o comando Flutter e o restore de
Wi-Fi retornaram que o device `R58T300SREH` nao foi encontrado.

## Evidencia sanitizada

Diretorio:

- `app/doc/runtime_flow_proofs_2026-05-14_commander_reference_sprint4_lot1_app/`

Arquivos:

- `environment_blocker_sanitized.log`
- `runtime_command_sanitized.log`

Os logs foram redigidos para nao conter secrets, tokens, JWT, `SENTRY_DSN`,
`DATABASE_URL`, `OPENAI_API_KEY`, e-mail QA completo, prompt bruto ou decklist
completa.

## O que foi real, mockado e nao provado

- Real: branch `master` sincronizada, `/health` publico HTTP 200, harness Sprint 4
  Lote 1 criado, analyze/test focados passando e tentativa do comando Android
  solicitado.
- Mockado: nada.
- Nao provado: app real no `SM A135M`/`R58T300SREH`, register/login runtime,
  Generate Commander, preview, save, Deck Details e `/decks/:id/validate`, porque
  o device alvo nao estava conectado.

Resultado final desta rodada: **BLOCKED**.
