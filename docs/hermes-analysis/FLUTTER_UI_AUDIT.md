# Flutter UI/UX Audit

## Metadata

- Gerado em UTC: `2026-06-04T17:02:13.749273+00:00`
- Branch: `master`
- SHA: `f732438`
- Scan repo: `/opt/data/workspace/mtgia-sync`
- Memory/report repo: `/opt/data/workspace/mtgia`
- Escopo: `app/lib/features/**/*.dart`, `app/lib/core/**/*.dart`
- Arquivos Dart analisados: `152`
- Metodo: varredura estatica deterministica por padroes de UI/UX
- Limite por regra: `80`

## Sumario

`findings=193 P0=0 P1=0 P2=193`

### Contagem por regra

- `hardcoded_color`: 80
- `interactive_without_semantics_hint`: 58
- `possible_small_touch_target`: 51
- `material_color_direct`: 3
- `network_image_no_cache_abstraction`: 1

## Findings

### P2

#### P2-001 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:82`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-002 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_commander_damage_sheet.dart:101`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-003 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_day_night_sheet.dart:52`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-004 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_dice_sheet.dart:83`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-005 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_modes_sheet.dart:113`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-006 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_game_timer_sheet.dart:73`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-007 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_history_sheet.dart:51`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-008 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:445`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-009 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:933`
- Trecho: `color: Color(0x33000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-010 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_counter_sheet.dart:174`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-011 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_state_sheet.dart:229`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-012 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:129`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-013 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:399`
- Trecho: `? const Color(0xFFFF7A9C)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-014 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:404`
- Trecho: `? const Color(0x66FF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-015 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:448`
- Trecho: `? const Color(0x33FF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-016 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:451`
- Trecho: `destructive ? const Color(0xFFFF5E9A) : AppTheme.textPrimary,`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-017 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_set_life_sheet.dart:457`
- Trecho: `? const Color(0x66FF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-018 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_settings_sheet.dart:78`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-019 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_table_state_sheet.dart:85`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-020 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_turn_tracker_sheet.dart:80`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-021 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:108`
- Trecho: `Color(0xFFFFB51E),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-022 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:109`
- Trecho: `Color(0xFFFF0A5B),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-023 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:110`
- Trecho: `Color(0xFFCF7AEF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-024 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:111`
- Trecho: `Color(0xFF4B57FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-025 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:112`
- Trecho: `Color(0xFF44E063),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-026 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:113`
- Trecho: `Color(0xFF40B9FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-027 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:906`
- Trecho: `decoration: BoxDecoration(color: Color(0xA6000000)),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-028 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1332`
- Trecho: `color: Color(0xFF44E063),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-029 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1339`
- Trecho: `color: Color(0xFFFFE277),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-030 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1346`
- Trecho: `color: Color(0xFF40B9FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-031 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1353`
- Trecho: `color: Color(0xFFB9B4FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-032 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1621`
- Trecho: `color: const Color(0xFF0D1117),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-033 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1658`
- Trecho: `colors: [Color(0xFF04070E), Color(0xFF121A2B)],`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-034 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1667`
- Trecho: `colors: [Color(0xFFEAFDFF), Color(0xFFB9D7FF)],`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-035 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1679`
- Trecho: `colors: [Color(0xFFFDF4FF), Color(0xFFD7EDFF)],`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-036 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1962`
- Trecho: `color: Color(0xFFFF2C77),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-037 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2036`
- Trecho: `color: selected ? const Color(0xFFFF2C77) : Colors.transparent,`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-038 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2041`
- Trecho: `? const Color(0xFFFF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-039 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2332`
- Trecho: `color: Color(0xFF40B9FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-040 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2581`
- Trecho: `color: const Color(0xFFF7F4EC),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-041 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3060`
- Trecho: `? const Color(0xFF4A3A12)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-042 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3062`
- Trecho: `? const Color(0xFF1D1D1D)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-043 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3064`
- Trecho: `? const Color(0xFF5B3A6C)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-044 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3066`
- Trecho: `? const Color(0xFF341217)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-045 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3068`
- Trecho: `? const Color(0xFF122A18)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-046 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3438`
- Trecho: `? const Color(0xFF2F2407)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-047 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3440`
- Trecho: `? const Color(0xFF121212)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-048 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3442`
- Trecho: `? const Color(0xFF1D1025)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-049 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3444`
- Trecho: `? const Color(0xFF2B090F)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-050 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3445`
- Trecho: `: const Color(0xFF0C2414),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-051 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3448`
- Trecho: `? const Color(0xFFFFD36A)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-052 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3450`
- Trecho: `? const Color(0xFFEDEDED)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-053 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3452`
- Trecho: `? const Color(0xFFFF5AA9)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-054 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3454`
- Trecho: `? const Color(0xFFFF5B61)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-055 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3455`
- Trecho: `: const Color(0xFF6BFF8D),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-056 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3834`
- Trecho: `accent: const Color(0xFF6BFF8D),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-057 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3853`
- Trecho: `: const Color(0xFFFFB3A8),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-058 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4178`
- Trecho: `Color(0xFFFF9CD1),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-059 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4179`
- Trecho: `Color(0xFFFFF5A3),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-060 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4180`
- Trecho: `Color(0xFFB7FFBE),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-061 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4181`
- Trecho: `Color(0xFFB5C8FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-062 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4188`
- Trecho: `colors: [Color(0xFFFFC55A), Color(0xFFFFE596), Color(0xFFFFB764)],`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-063 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4485`
- Trecho: `Color(0xFFFF4C7D),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-064 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4486`
- Trecho: `Color(0xFF4A5BFF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-065 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4487`
- Trecho: `Color(0xFFFFC552),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-066 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4488`
- Trecho: `Color(0xFF5BDF79),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-067 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4489`
- Trecho: `Color(0xFFFFFFFF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-068 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4809`
- Trecho: `accent: const Color(0xFF40B9FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-069 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:4937`
- Trecho: `accent: const Color(0xFF40B9FF),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-070 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5340`
- Trecho: `color: Color(0xFFFF2C77),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-071 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5413`
- Trecho: `color: const Color(0xFF454257),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-072 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5429`
- Trecho: `? const Color(0xFFFF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-073 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5677`
- Trecho: `color: Color(0xFFFF2C77),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-074 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5753`
- Trecho: `color: const Color(0xFF171717),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-075 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5775`
- Trecho: `? const Color(0xFFFF2C77)`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-076 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6623`
- Trecho: `color: selected ? const Color(0xFFFFC81E) : Colors.transparent,`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-077 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6626`
- Trecho: `color: selected ? const Color(0xFFFFC81E) : Colors.white,`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-078 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6675`
- Trecho: `color: selected ? const Color(0xFF1C78FF) : Colors.white,`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-079 hardcoded_color

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6678`
- Trecho: `color: selected ? const Color(0xFF1C78FF) : Colors.transparent,`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-080 hardcoded_color

- Evidencia: `app/lib/features/home/lotus/lotus_host_overlays.dart:87`
- Trecho: `color: Color(0x66000000),`
- Impacto: Cores diretas dificultam consistencia visual, tema e contraste.
- Sugestao: Trocar por token/AppTheme ou justificar excecao local.

#### P2-081 interactive_without_semantics_hint

- Evidencia: `app/lib/features/auth/screens/login_screen.dart:212`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-082 interactive_without_semantics_hint

- Evidencia: `app/lib/features/auth/screens/register_screen.dart:300`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-083 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1493`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-084 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/screens/marketplace_screen.dart:498`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-085 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:467`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-086 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:618`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-087 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:665`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-088 interactive_without_semantics_hint

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:1005`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-089 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_detail_screen.dart:77`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-090 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_detail_screen.dart:137`
- Trecho: `(_) => GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-091 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:328`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-092 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:658`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-093 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1232`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-094 interactive_without_semantics_hint

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1339`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-095 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:205`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-096 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:788`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-097 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:853`
- Trecho: `child: GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-098 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:969`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-099 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:1110`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-100 interactive_without_semantics_hint

- Evidencia: `app/lib/features/community/screens/community_screen.dart:1465`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-101 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_details_screen.dart:716`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-102 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:487`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-103 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:957`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-104 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1009`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-105 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1346`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-106 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:1446`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-107 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_card.dart:85`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-108 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:448`
- Trecho: `(card) => InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-109 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1188`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-110 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1211`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-111 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1369`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-112 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:103`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-113 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:1140`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-114 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_progress_indicator.dart:129`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-115 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_progress_indicator.dart:277`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-116 interactive_without_semantics_hint

- Evidencia: `app/lib/features/decks/widgets/deck_ui_components.dart:164`
- Trecho: `return InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-117 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/home_screen.dart:422`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-118 interactive_without_semantics_hint

- Evidencia: `app/lib/features/home/home_screen.dart:532`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-119 interactive_without_semantics_hint

- Evidencia: `app/lib/features/messages/screens/message_inbox_screen.dart:124`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-120 interactive_without_semantics_hint

- Evidencia: `app/lib/features/notifications/screens/notification_screen.dart:172`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-121 interactive_without_semantics_hint

- Evidencia: `app/lib/features/profile/profile_screen.dart:295`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-122 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/screens/card_scanner_screen.dart:663`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-123 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:92`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-124 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:243`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-125 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:302`
- Trecho: `GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-126 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:401`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-127 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:416`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-128 interactive_without_semantics_hint

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:550`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-129 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:393`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-130 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:466`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-131 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:1207`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-132 interactive_without_semantics_hint

- Evidencia: `app/lib/features/social/screens/user_search_screen.dart:193`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-133 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:772`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-134 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:959`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-135 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:989`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-136 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:1012`
- Trecho: `InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-137 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:1086`
- Trecho: `return GestureDetector(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-138 interactive_without_semantics_hint

- Evidencia: `app/lib/features/trades/screens/trade_inbox_screen.dart:291`
- Trecho: `child: InkWell(`
- Impacto: Elemento interativo custom pode ficar pouco claro para leitor de tela.
- Sugestao: Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.

#### P2-139 material_color_direct

- Evidencia: `app/lib/features/scanner/screens/card_scanner_screen.dart:548`
- Trecho: `color: Colors.white70,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-140 material_color_direct

- Evidencia: `app/lib/features/scanner/screens/card_scanner_screen.dart:691`
- Trecho: `color: Colors.black87,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-141 material_color_direct

- Evidencia: `app/lib/features/scanner/screens/card_scanner_screen.dart:722`
- Trecho: `color: Colors.white54,`
- Impacto: Uso direto de Colors pode furar o design system.
- Sugestao: Preferir AppTheme/tokens semanticos para cor de UI.

#### P2-142 network_image_no_cache_abstraction

- Evidencia: `app/lib/features/home/home_screen.dart:677`
- Trecho: `return Image.network(`
- Impacto: Imagens remotas repetidas podem prejudicar scroll/performance.
- Sugestao: Avaliar componente centralizado com cache, placeholder e error state.

#### P2-143 possible_small_touch_target

- Evidencia: `app/lib/features/auth/screens/login_screen.dart:212`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-144 possible_small_touch_target

- Evidencia: `app/lib/features/auth/screens/register_screen.dart:300`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-145 possible_small_touch_target

- Evidencia: `app/lib/features/binder/screens/binder_screen.dart:1493`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-146 possible_small_touch_target

- Evidencia: `app/lib/features/binder/screens/marketplace_screen.dart:498`
- Trecho: `GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-147 possible_small_touch_target

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:618`
- Trecho: `child: GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-148 possible_small_touch_target

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:665`
- Trecho: `child: GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-149 possible_small_touch_target

- Evidencia: `app/lib/features/binder/widgets/binder_item_editor.dart:1005`
- Trecho: `return InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-150 possible_small_touch_target

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:328`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-151 possible_small_touch_target

- Evidencia: `app/lib/features/cards/screens/card_search_screen.dart:1232`
- Trecho: `return InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-152 possible_small_touch_target

- Evidencia: `app/lib/features/community/screens/community_deck_detail_screen.dart:205`
- Trecho: `child: GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-153 possible_small_touch_target

- Evidencia: `app/lib/features/community/screens/community_screen.dart:969`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-154 possible_small_touch_target

- Evidencia: `app/lib/features/community/screens/community_screen.dart:1110`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-155 possible_small_touch_target

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:487`
- Trecho: `InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-156 possible_small_touch_target

- Evidencia: `app/lib/features/decks/screens/deck_list_screen.dart:957`
- Trecho: `return InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-157 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:448`
- Trecho: `(card) => InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-158 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1188`
- Trecho: `InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-159 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1369`
- Trecho: `InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-160 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:103`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-161 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:1140`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-162 possible_small_touch_target

- Evidencia: `app/lib/features/decks/widgets/deck_progress_indicator.dart:129`
- Trecho: `return InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-163 possible_small_touch_target

- Evidencia: `app/lib/features/home/home_screen.dart:422`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-164 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_card_search_sheet.dart:354`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-165 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter/life_counter_native_player_appearance_sheet.dart:915`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-166 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:1786`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-167 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2029`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-168 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2435`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-169 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2482`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-170 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:2647`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-171 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3518`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-172 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:3743`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-173 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5026`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-174 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5238`
- Trecho: `child: GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-175 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:5746`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-176 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6435`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-177 possible_small_touch_target

- Evidencia: `app/lib/features/home/life_counter_screen.dart:6616`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-178 possible_small_touch_target

- Evidencia: `app/lib/features/messages/screens/message_inbox_screen.dart:124`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-179 possible_small_touch_target

- Evidencia: `app/lib/features/notifications/screens/notification_screen.dart:172`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-180 possible_small_touch_target

- Evidencia: `app/lib/features/profile/profile_screen.dart:295`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-181 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/screens/card_scanner_screen.dart:663`
- Trecho: `GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-182 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:243`
- Trecho: `GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-183 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:401`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-184 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:416`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-185 possible_small_touch_target

- Evidencia: `app/lib/features/scanner/widgets/scanned_card_preview.dart:550`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-186 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:393`
- Trecho: `return GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-187 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:466`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-188 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_profile_screen.dart:1207`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-189 possible_small_touch_target

- Evidencia: `app/lib/features/social/screens/user_search_screen.dart:193`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-190 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:772`
- Trecho: `return GestureDetector(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-191 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:989`
- Trecho: `InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-192 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/create_trade_screen.dart:1012`
- Trecho: `InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

#### P2-193 possible_small_touch_target

- Evidencia: `app/lib/features/trades/screens/trade_inbox_screen.dart:291`
- Trecho: `child: InkWell(`
- Impacto: Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.
- Sugestao: Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.

## Incertezas / medir depois

- Contraste real depende de renderizacao e tema ativo; validar com screenshot ou teste visual.
- Overflow/truncamento depende de device, escala de fonte e dados reais.
- Estados empty/error/loading contextuais exigem revisar providers/API por fluxo.

## Git status no momento da auditoria

```text
## master...origin/master
```

## Git status da memoria Hermes

```text
## codex/hermes-analysis-docs...origin/codex/hermes-analysis-docs
 M docs/hermes-analysis/manaloom-knowledge/scripts/__pycache__/db_helper.cpython-313.pyc
 M docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db
```

UI_AUDIT_RESULT: findings=193 P0=0 P1=0 P2=193
