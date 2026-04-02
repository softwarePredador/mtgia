# Life Counter - Native Sheets Review - 2026-04-02

## Objetivo

Classificar as `native sheets` ainda existentes no codigo do contador agora que a diretriz oficial e:

- Lotus continua como camada visual principal no `WebView`
- ManaLoom continua dona de backend, persistencia, normalizacao e fallback interno

Esta revisao nao remove nada por impulso.

Ela define o papel de cada sheet para orientar manutencao, testes e poda futura.

## Status legend

- `principal`: fluxo visual principal do produto
- `fallback interno`: suporte tecnico ainda exercitavel por host/tests/debug, mas nao e o fluxo visual principal
- `backend support`: existe para handoff tecnico, observabilidade ou apoio do backend, mesmo sem ser fluxo visual principal
- `candidata a poda`: pode entrar em fila de remocao quando o fallback equivalente deixar de ser necessario
- `podada`: removida do runtime e da cobertura interna por nao ter mais papel no fluxo atual

## Classificacao atual

### Shells de shell/menu e overlays leves

- `life_counter_native_settings_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: manter enquanto o host ainda suportar `open-native-settings`

- `life_counter_native_history_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: manter enquanto o host ainda suportar `open-native-history`

- `life_counter_native_card_search_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: manter enquanto o host ainda suportar `open-native-card-search`

- `life_counter_native_quick_actions_sheet.dart`
  - status: `podada`
  - visual principal atual: menu radial do Lotus
  - observacao: removida do runtime e da suite de fallback em 2026-04-02; o menu radial do Lotus segue como fluxo visual oficial

### Runtime auxiliar da mesa

- `life_counter_native_turn_tracker_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: ainda e util como fallback tecnico e para validar a `LifeCounterTurnTrackerEngine`

- `life_counter_native_game_timer_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: manter enquanto existir fallback de `open-native-game-timer`

- `life_counter_native_dice_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: ainda exercita a `LifeCounterDiceEngine` no fallback interno

- `life_counter_native_table_state_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: continua util para fallback e para validar ownership/`storm`/`monarch`/`initiative`

- `life_counter_native_day_night_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: continua util porque o host ainda reaplica `__manaloom_day_night_mode`

### Runtime de jogador

- `life_counter_native_commander_damage_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: ainda valida e exercita o pipeline canonico de commander damage

- `life_counter_native_player_appearance_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: ainda concentra import/export e perfis como apoio interno

- `life_counter_native_player_counter_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: ainda exercita counters e sinais criticos pela engine da mesa

- `life_counter_native_player_state_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: ainda funciona como hub interno tecnico para varios fluxos de runtime

- `life_counter_native_set_life_sheet.dart`
  - status: `fallback interno`
  - visual principal atual: Lotus
  - observacao: ainda e um fallback tecnico importante para `autoKill` e ajustes de vida

### Game modes

- `life_counter_native_game_modes_sheet.dart`
  - status: `backend support`
  - visual principal atual: Lotus
  - observacao: manter como apoio tecnico de backend, handoff e observabilidade por decisao final de produto; `Planechase`, `Archenemy` e `Bounty` seguem Lotus-first visualmente e `edit cards`/card pools permanecem embutidos no Lotus

## Decisao operacional atual

Nenhuma dessas sheets deve ser removida imediatamente.

Ordem recomendada:

1. manter todas as sheets classificadas como `fallback interno` enquanto o host ainda aceitar `open-native-*`
2. registrar `life_counter_native_quick_actions_sheet.dart` como primeira poda concluida
3. revisar `life_counter_native_game_modes_sheet.dart` apenas se a estrategia de `Game Modes` mudar no futuro; com a decisao atual, ela permanece como `backend support`

## Proximo passo recomendado

Antes de podar qualquer sheet:

1. confirmar que nao ha mais gatilho visual principal para ela na `lotus_shell_policy.dart`
2. confirmar que os testes relevantes migraram para suites de fallback ou host normalization
3. confirmar que o comportamento canonico equivalente continua coberto por engine/adapters/smokes

## Done criteria desta revisao

- cada `native sheet` tem papel claro
- a equipe sabe o que e principal, o que e fallback e o que pode entrar em fila de poda
- futuras remocoes deixam de ser intuitivas e passam a seguir criterio documentado
