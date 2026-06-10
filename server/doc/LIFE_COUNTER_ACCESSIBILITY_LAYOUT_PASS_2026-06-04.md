# Life Counter Accessibility/Layout Pass — 2026-06-04

## Status

**PASS_WITH_RISKS**

Escopo: Life Counter Flutter/Lotus fallback, overlays nativos de card search,
set life e player appearance. O objetivo foi reduzir bugs objetivos de UX
estática sem redesenhar a mesa ou trocar a paleta funcional por jogador.

## Mudanças Aplicadas

- Adicionados `Semantics` e `Tooltip` nos controles centrais da mesa, hub,
  ações de jogador, bottom rail, busca de cartas, botões de dados, teclado de
  vida, presets de vida inicial e chips de cor.
- Backspace do teclado de vida foi padronizado como `DEL`, removendo texto
  corrompido.
- Corrigidos textos user-facing corrompidos em labels/diagnósticos do Life
  Counter: configurações, seleção de jogadores, histórico, separador de carta e
  estados letais.
- Harness runtime de player appearance passou a usar `scrollUntilVisible`
  antes de tocar no preset, igual ao teste interno, evitando falso negativo no
  iPhone Simulator.

## Auditor Estático

Antes do passe local:

- `UI_AUDIT_RESULT: findings=215 P0=0 P1=0 P2=215`
- Life Counter P2: 115
- Life Counter `interactive_without_semantics_hint`: 22

Depois do passe:

- `UI_AUDIT_RESULT: findings=193 P0=0 P1=0 P2=193`
- Life Counter P2: 93
- Life Counter `interactive_without_semantics_hint`: 0

Risco aceito: 79 achados restantes de `hardcoded_color` no Life Counter são, em
grande parte, cores funcionais de estado/mesa/jogador. Trocar isso por tokens
sem uma matriz visual específica pode piorar legibilidade durante a partida.

## Validações

Comandos locais:

```bash
cd app
flutter analyze lib/features/home/life_counter_screen.dart \
  lib/features/home/life_counter/life_counter_native_card_search_sheet.dart \
  lib/features/home/life_counter/life_counter_native_set_life_sheet.dart \
  lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart \
  integration_test/life_counter_native_player_appearance_color_card_live_smoke_test.dart \
  --no-version-check

flutter test $(find test/features/home -maxdepth 1 -type f -name '*life_counter*test.dart' -print | sort) \
  --no-version-check --reporter compact
```

Resultado:

- `flutter analyze`: PASS
- Life Counter unit/widget suite: 264 tests PASS

Prova viva no iPhone 15 Pro Max Simulator
`DABB9D79-2FDB-4585-94DB-E31F1288EE74`:

```bash
cd app
flutter test integration_test/life_counter_lotus_visual_capture_smoke_test.dart \
  integration_test/life_counter_native_card_search_smoke_test.dart \
  integration_test/life_counter_set_life_live_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check

flutter test integration_test/life_counter_native_player_appearance_color_card_live_smoke_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded --no-version-check
```

Resultado:

- Base visual/Lotus screenshot proof: PASS
- Native card search: PASS
- Set life live: PASS, `apply_strategy=live_runtime`
- Player appearance color-card live: PASS, `apply_strategy=live_runtime`

Observação: o warning conhecido de plugins sem suporte arm64 no simulator foi
emitido, mas não bloqueou os runtimes.
