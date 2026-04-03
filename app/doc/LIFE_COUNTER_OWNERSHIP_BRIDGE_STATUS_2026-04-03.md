# Life Counter - Ownership Bridge Status - 2026-04-03

## Objetivo

Registrar o estado atual dos dominios classificados como `ownership_bridge` no host do contador e responder:

- quais dominios ja evitam `reload` em casos seguros
- quais dominios ainda ficam em `canonical_store_sync`
- quais dominios ainda sao `reload-only`
- onde esta a maior oportunidade real para reduzir `reload bundle` como caminho padrao

Documento relacionado:

- `app/doc/LIFE_COUNTER_NATIVE_FALLBACK_AUDIT_2026-04-03.md`
- `app/doc/LIFE_COUNTER_CORE_OWNERSHIP_CLOSURE_PLAN_2026-04-02.md`

## Leitura curta

Hoje o item aberto mais importante do plano de ownership e:

- reduzir `reload bundle` como caminho padrao

O inventario abaixo traduz isso para o estado real de cada dominio `ownership_bridge`.

## Status por dominio

| Domain | Current best strategy | Estado atual |
| --- | --- | --- |
| `settings` | `reload_fallback` | continua `reload-only` por decisao arquitetural; o Lotus mantem esse dominio em memoria propria |
| `turn_tracker` | `live_runtime` | ja evita `reload` em avancos, rewinds curtos e mudanca curta de starting player com tracker ativo |
| `game_timer` | `live_runtime` | ja evita `reload` em `active -> active` e `inactive -> active` quando a superficie `.game-timer` responde |
| `dice` | `canonical_store_sync` | ja evita `reload` quando a mutacao fica limitada ao resultado canonico e nao muda estruturalmente o tracker |
| `commander_damage` | `canonical_store_sync` | ja evita `reload` apenas quando o settings garante ausencia de reflexo visual na mesa |
| `player_appearance` | `reload_fallback` | continua dominado pela superficie visual do board e pelos assets do jogador |
| `player_counter` | `canonical_store_sync` | ja evita `reload` quando counters ficam ocultos e `poison` nao pode disparar `autoKill` |
| `player_state` | `mixed` | combina `canonical_store_sync`, `live_runtime` e `reload_fallback` conforme o subfluxo final do hub |
| `set_life` | `live_runtime` | ja evita `reload` em delta medio de vida no jogador alvo quando o runtime Lotus confirma os controles |
| `table_state` | `live_runtime` | ja evita `reload` para `storm`, `monarch` e `initiative` quando o DOM alvo responde |
| `day_night` | `live_runtime` | ja evita `reload` quando `.day-night-switcher` confirma a troca |

## Grupos praticos

### 1. Reload-only

Entram aqui:

- `settings`
- `player_appearance`

Leitura:

- esses dois ainda nao tem um recorte live confiavel o bastante para virar default
- `settings` e um caso explicitamente arquitetural
- `player_appearance` continua acoplado a reflexo visual direto do board Lotus

### 2. Sync canonico sem reboot

Entram aqui:

- `dice`
- `commander_damage`
- `player_counter`
- parte de `player_state`

Leitura:

- o estado ja fica correto sem recarregar o bundle
- mas o host ainda depende de gates conservadores para nao vender sync silencioso em caso com reflexo visual real

### 3. Live runtime real

Entram aqui:

- `turn_tracker`
- `game_timer`
- parte de `player_state`
- `set_life`
- `table_state`
- `day_night`

Leitura:

- aqui ja existe controle direto sobre o runtime Lotus sem `reload` completo
- esses dominios representam o avancado real da trilha de ownership sem mexer no visual

## Maior oportunidade real

Se o objetivo for continuar reduzindo `reload bundle` como caminho padrao, a ordem mais promissora hoje e:

1. `player_appearance`
   - maior bloco ainda `reload-only` fora `settings`
   - mas tambem o mais sensivel visualmente
2. `player_state`
   - ainda mistura varios subfluxos
   - existe espaco para abrir mais recortes seguros
3. `commander_damage` e `player_counter`
   - continuar ampliando os casos ocultos/sem reflexo visual
4. `turn_tracker`
   - explorar se existe mais algum gesto seguro alem dos recortes ja suportados

## Menor oportunidade real

Menos provavel de ganhar muito agora:

- `settings`
  - continua conscientemente fora do live sync
- `day_night`
  - ja esta bem resolvido
- `table_state`
  - ja cobre o principal da mesa auxiliar

## Conclusao operacional

O plano de ownership agora pode ser lido assim:

- o mecanismo de patch incremental ja existe
- a prova de reopen canonico sem snapshot confiavel ja existe
- a auditoria de `open-native-*` ja existe
- o grande item ainda aberto de verdade e reduzir `reload` nos dominios `ownership_bridge` que continuam `reload-only` ou `mixed`

## Regra para proximas tasks

Cada task nova nessa frente deve declarar qual destes alvos ela persegue:

1. abrir um novo recorte `live_runtime`
2. abrir um novo recorte `canonical_store_sync`
3. manter `reload_fallback` mas explicar por que ainda e necessario
4. mover um dominio de `mixed` para um estado mais previsivel
