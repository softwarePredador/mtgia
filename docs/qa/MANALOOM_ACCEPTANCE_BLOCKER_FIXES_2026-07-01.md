# ManaLoom Acceptance Blocker Fixes

Data: 2026-07-01
Status: `FIXED_LOCALLY_PENDING_ANDROID_RERUN`

## Escopo

Correcoes dos dois blockers de aceite descobertos no Android fisico:

- `ACCEPTANCE_BLOCKER_IMPORT_MODAL_CLOSE`
- `ACCEPTANCE_BLOCKER_OPTIMIZE_NEEDS_REPAIR_UX`

## Correcoes aplicadas

### Import modal apos replace_all

Problema:

- O backend retornava `POST /import/to-deck -> 200`.
- Quando a resposta vinha com `commander_preserved=true`, o app mantinha o
  modal `Importar Lista` aberto para revisao.
- No aceite, isso parecia travamento porque nao havia erro real para revisar.

Correcao:

- `commander_preserved` sozinho deixou de segurar o modal.
- O dialog continua aberto apenas para revisao real: cartas nao encontradas,
  warnings ou comandante ausente.
- Quando o comandante e preservado sem erro, o modal fecha e o snackbar informa
  `comandante preservado`.

Arquivos:

- `app/lib/features/decks/widgets/deck_import_list_dialog.dart`
- `app/test/features/decks/widgets/deck_import_list_dialog_test.dart`

### Optimize com OPTIMIZE_NEEDS_REPAIR

Problema:

- O backend retornava `422 OPTIMIZE_NEEDS_REPAIR`.
- A UX ja exibia o dialog de reconstrucao guiada, mas o harness classificava
  esse estado como blocker e encerrava sem outcome seguro.

Correcao:

- `deck_generate_async_runtime_test.dart` agora trata o dialog
  `optimize-rebuild-guided-dialog` como outcome seguro quando o objetivo e
  comprovar UX de quality gate.
- `deck_runtime_m2006_test.dart` tambem registra rebuild guiado e no-op seguro
  como outcomes aceitos quando `RUNTIME_OPTIMIZE_REQUIRE_APPLY` nao exige prova
  de aplicacao.
- Os harnesses capturam a tela, imprimem um sinal explicito de safe outcome e
  fecham o dialog em vez de deixar o teste preso.

Arquivos:

- `app/integration_test/deck_generate_async_runtime_test.dart`
- `app/integration_test/deck_runtime_m2006_test.dart`

## Evidencia local

Comandos:

```sh
dart format app/integration_test/deck_runtime_m2006_test.dart app/integration_test/deck_generate_async_runtime_test.dart app/lib/features/decks/widgets/deck_import_list_dialog.dart app/test/features/decks/widgets/deck_import_list_dialog_test.dart
flutter analyze lib/features/decks/widgets/deck_import_list_dialog.dart test/features/decks/widgets/deck_import_list_dialog_test.dart integration_test/deck_generate_async_runtime_test.dart integration_test/deck_runtime_m2006_test.dart --no-version-check
flutter test test/features/decks/widgets/deck_import_list_dialog_test.dart --no-version-check --reporter compact
```

Resultados:

- `dart format`: 4 arquivos, 0 alterados apos formatacao.
- `flutter analyze`: PASS, sem issues.
- `deck_import_list_dialog_test`: PASS, 3 testes.

## Pendencia

Ainda falta repetir o aceite Android fisico contra o backend publico. Esta
passada nao executou os testes live completos porque eles registram usuarios,
criam decks e podem consumir IA real.

Comandos de retomada:

```sh
cd app
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=RUNTIME_OPTIMIZE_INTENSITY_LABEL=Focado \
  --no-version-check \
  --reporter expanded

flutter test integration_test/deck_generate_async_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --no-version-check \
  --reporter expanded
```
