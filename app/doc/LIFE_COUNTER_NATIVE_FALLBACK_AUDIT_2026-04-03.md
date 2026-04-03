# Life Counter - Native Fallback Audit - 2026-04-03

## Objetivo

Fechar a auditoria dos `open-native-*` ainda aceitos pelo host do contador e deixar explicito:

- quais superficies continuam exercitaveis por fallback interno
- quais delas ainda representam ponte de ownership do core
- quais sao apenas suporte utilitario Lotus-first
- quais ficam explicitamente fora do core canonico desta fase

Esta auditoria usa como fonte viva o inventario em:

- `app/lib/features/home/lotus_life_counter_screen.dart`

Mais precisamente:

- `_nativeFallbackDescriptors`
- `_nativeFallbackPlayerTargetTypes`

## Decisao operacional

Os `open-native-*` restantes **nao** significam takeover visual principal.

Eles passam a ser tratados assim:

- `ownership_bridge`: fallback interno ainda util para exercitar e estabilizar ownership canonico do dominio
- `support_utility`: suporte interno legitimo para fluxos Lotus-first que nao dependem de takeover visual
- `excluded_core_support`: suporte interno de dominio explicitamente fora do core canonico desta fase

Regra pratica:

- enquanto o host continuar aceitando esses eventos, as sheets associadas permanecem validas como suporte interno
- a simples existencia de um `open-native-*` **nao** implica gap de produto aberto
- remocao adicional so deve acontecer quando houver ganho claro e cobertura equivalente

## Inventario vivo

| Message type | Domain key | Classification | Review status | Default source | Papel atual |
| --- | --- | --- | --- | --- | --- |
| `open-native-settings` | `settings` | `ownership_bridge` | `ownership_in_progress` | `shell_shortcut` | fallback interno de configuracao; visual principal segue Lotus |
| `open-native-history` | `history` | `support_utility` | `support_utility` | `shell_shortcut` | suporte interno para dominio ja canonico; visual principal segue Lotus |
| `open-native-card-search` | `card_search` | `support_utility` | `support_utility` | `shell_shortcut` | suporte interno para busca; visual principal segue Lotus |
| `open-native-turn-tracker` | `turn_tracker` | `ownership_bridge` | `ownership_in_progress` | `turn_tracker_surface_pressed` | fallback tecnico para tracker canonico e sync incremental |
| `open-native-game-timer` | `game_timer` | `ownership_bridge` | `ownership_in_progress` | `game_timer_surface_pressed` | fallback tecnico para timer canonico e sync incremental |
| `open-native-game-modes` | `game_modes` | `excluded_core_support` | `excluded_from_core` | `game_modes_shortcut` | suporte interno de backend/observabilidade para `Planechase`, `Archenemy` e `Bounty` |
| `open-native-dice` | `dice` | `ownership_bridge` | `ownership_in_progress` | `dice_shortcut_pressed` | fallback tecnico para dominio de dice e handoff com tracker |
| `open-native-commander-damage` | `commander_damage` | `ownership_bridge` | `ownership_in_progress` | `commander_damage_surface_pressed` | fallback tecnico do runtime de jogador |
| `open-native-player-appearance` | `player_appearance` | `ownership_bridge` | `ownership_in_progress` | `player_background_surface_pressed` | fallback tecnico de aparencia, clipboard e perfis |
| `open-native-player-counter` | `player_counter` | `ownership_bridge` | `ownership_in_progress` | `player_counter_surface_pressed` | fallback tecnico de counters e autoKill |
| `open-native-player-state` | `player_state` | `ownership_bridge` | `ownership_in_progress` | `player_state_surface_pressed` | fallback tecnico do hub de runtime do jogador |
| `open-native-set-life` | `set_life` | `ownership_bridge` | `ownership_in_progress` | `player_life_total_surface_pressed` | fallback tecnico para vida e apply live curto |
| `open-native-table-state` | `table_state` | `ownership_bridge` | `ownership_in_progress` | `table_state_surface` | fallback tecnico para `storm`, `monarch` e `initiative` |
| `open-native-day-night` | `day_night` | `ownership_bridge` | `ownership_in_progress` | `day_night_surface` | fallback tecnico para preferencia canonica e sync live |

## Leitura por grupo

### Ownership bridge

Entram aqui:

- `settings`
- `turn_tracker`
- `game_timer`
- `dice`
- `commander_damage`
- `player_appearance`
- `player_counter`
- `player_state`
- `set_life`
- `table_state`
- `day_night`

Interpretacao correta:

- esses dominios ja tem forte ownership canonico ManaLoom
- mas o fallback interno ainda e util para testes, diagnostico, cobertura de borda e exercicio do pipeline de normalizacao
- enquanto existir `ownership_in_progress`, a sheet nao deve ser podada automaticamente

### Support utility

Entram aqui:

- `history`
- `card_search`

Interpretacao correta:

- sao utilitarios Lotus-first
- o fallback existe como apoio tecnico legitimo
- eles ja nao representam gap estrutural do core

### Excluded core support

Entra aqui:

- `game_modes`

Interpretacao correta:

- `Planechase`, `Archenemy` e `Bounty` seguem Lotus-first por decisao de produto
- a shell nativa de `game modes` nao representa ownership canonico pendente do core
- ela permanece como `backend support`

## Conclusao da auditoria

Depois da revisao do inventario vivo, a leitura final fica assim:

1. os `open-native-*` restantes estao classificados e auditados
2. nao existe fallback remanescente "sem dono"
3. `history` e `card search` deixam de contar como gap de ownership
4. `game modes` deixa de contar como ambiguidade do core e permanece como suporte explicitamente fora desse fechamento
5. os fallbacks restantes de runtime/mesa continuam intencionais enquanto a trilha de ownership canonico do core seguir ativa

## Impacto no plano

Com esta auditoria fechada:

- o checklist "revisar quais `open-native-*` ainda sao fallback real e quais escondem ownership incompleto" pode ser marcado como concluido
- as proximas tasks deixam de ser de classificacao e passam a ser:
  - fortalecer ownership canonico dos dominios `ownership_bridge`
  - podar apenas quando houver ganho claro e cobertura equivalente

## Regra daqui para frente

Qualquer novo `open-native-*` so pode entrar se vier com:

1. `classification`
2. `domain_key`
3. `review_status`
4. `defaultSource`
5. documentacao atualizada nesta auditoria ou no documento sucessor
