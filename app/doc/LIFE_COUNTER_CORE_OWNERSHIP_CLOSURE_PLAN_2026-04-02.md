# Life Counter - Core Ownership Closure Plan - 2026-04-02

## Objective

Definir o caminho tecnico para fechar o contador no modelo desejado:

- `WebView` do Lotus preservado visualmente
- animacoes, interacoes e design do Lotus preservados
- estado, regras, persistencia e bootstrap controlados pelo ManaLoom
- customizacao visual deixada para uma fase posterior, ja com o core fechado

Este documento nao redefine a diretriz visual atual.

Ele responde apenas:

1. o que ja esta realmente ManaLoom-owned
2. o que ainda depende do runtime Lotus
3. o que falta para considerar o core `100% nosso`
4. em que ordem isso deve ser fechado

Documento de apoio desta fase:

- `app/doc/LIFE_COUNTER_SNAPSHOT_CANONICAL_MATRIX_2026-04-02.md`

## Target architecture

Estado final desejado:

- Lotus fica como `renderer`
- ManaLoom fica como `source of truth`
- o host Flutter deixa de depender do Lotus como primeiro escritor do estado
- o Lotus passa a consumir estado nosso de forma previsivel
- qualquer customizacao futura mexe primeiro no proprio bundle Lotus, nao na regra do jogo

Leitura pratica:

- o usuario continua vendo Lotus
- o runtime deixa de mandar na verdade do jogo
- o app consegue reabrir, restaurar e corrigir a mesa mesmo com snapshot Lotus stale ou incompleto

## Current status

Checkpoint objetivo desta trilha em `2026-04-02`:

- `Wave 1` concluida: a matriz do snapshot foi formalizada
- `Wave 2` concluida: `history` agora tem contrato canonico e store propria
- `currentGameMeta` e `gameCounter` agora tambem vivem dentro do contrato canonico de `history`
- `Wave 4` iniciada: existe ponte de patch incremental para o runtime Lotus
- `settings` permanecem em `reload` por seguranca, porque o bundle Lotus mantem esse dominio em memoria propria
- `game timer` ja aceita sync incremental no caso seguro `active -> active`, mas so evita `reload` quando o alvo `.game-timer` esta presente e responde no DOM real do Lotus
- `turn tracker` agora tambem aceita sync incremental no recorte seguro `active -> active` com avanco para frente, rewind curto limitado e mudanca curta de starting player em `Turn 1`, sem mudanca estrutural fora desse gesto, e so evita `reload` quando o alvo `.turn-time-tracker` esta presente e responde no DOM real do Lotus
- `table state` agora tambem aceita sync incremental no recorte seguro de `monarch/initiative`, mas so evita `reload` quando a mutacao nao mexe em `storm` e os `.player-card` do DOM real do Lotus estao presentes

## Ja ManaLoom-owned

### 1. Contratos canonicos locais

Ja existem contratos tipados nossos para:

- sessao: `life_counter_session.dart`
- settings: `life_counter_settings.dart`
- game timer: `life_counter_game_timer_state.dart`
- day/night: `life_counter_day_night_state.dart`
- perfis de aparencia: `life_counter_player_appearance_profile_store.dart`

Leitura:

- o app ja tem modelos proprios para guardar a verdade da mesa
- isso nao depende de API remota
- isso nao depende de formato interno do Lotus para existir

### 2. Regras e normalizacao

Ja existem engines proprias para:

- normalizacao do board
- `autoKill`
- `storm`, `monarch`, `initiative`
- commander damage
- counters
- high roll / roll 1st
- turn tracker e saneamento de ponteiros

Arquivos centrais:

- `life_counter_tabletop_engine.dart`
- `life_counter_turn_tracker_engine.dart`
- `life_counter_dice_engine.dart`

Leitura:

- a regra critica da mesa ja esta majoritariamente nossa
- o Lotus nao deveria mais ser tratado como juiz da logica

### 3. Bridge de snapshot e bootstrap

Ja existe pipeline nosso para:

- capturar `localStorage` do Lotus
- persistir snapshot bruto
- derivar contratos canonicos a partir do snapshot
- reconstruir snapshot de bootstrap a partir do estado canonicamente salvo

Arquivos centrais:

- `app/assets/lotus/flutter_bootstrap.js`
- `lotus_host_controller.dart`
- `lotus_life_counter_session_adapter.dart`
- `lotus_life_counter_settings_adapter.dart`
- `lotus_life_counter_game_timer_adapter.dart`

Leitura:

- o bootstrap da mesa ja passa pelo host
- o host ja consegue restaurar o Lotus usando estado salvo fora do bundle

### 4. Cobertura de reopen e round-trip

A rodada de `2026-04-02` fechou cobertura forte para:

- bootstrap
- reopen
- player runtime
- counters
- commander damage
- turn tracker
- timer
- table state
- day/night
- player counts

Leitura:

- a frente ja esta bem validada como `Lotus-first`
- isso reduz risco para a etapa final de ownership do core

## Ainda nao fechado

Os pontos abaixo impedem afirmar que o core ja esta `100% nosso`.

### 1. Lotus ainda e primeiro escritor em varios fluxos visuais

Hoje a policy do shell evita hijackar a maior parte das interacoes do Lotus.

Isso foi intencional para preservar o fluxo visual oficial.

Consequencia:

- o Lotus ainda muda `localStorage`
- o host espelha depois
- o caminho real em varios casos continua sendo `Lotus -> snapshot -> derivacao canonica`

Isso e diferente de:

- `ManaLoom -> estado canonico -> runtime Lotus`

Gap real:

- ainda nao fechamos a autoridade unica de mutacao do jogo

### 2. Varias aplicacoes ainda usam `snapshot + reload`

Hoje os fluxos nativos aplicam estado assim:

1. salvam store canonica
2. regeneram parte do snapshot
3. recarregam o bundle Lotus

Isso acontece em settings, timer, turn tracker, dice, commander damage, player state, set life, table state e afins.

Leitura:

- isso funciona
- mas ainda e um modelo de reidratacao pesada
- nao e o estado final ideal para `renderer puro`

Estado final desejado:

- atualizar o runtime Lotus sem reload completo sempre que o fluxo permitir
- deixar reload apenas como fallback

### 3. `History` ja entrou em contrato canonico, mas a compatibilidade Lotus ainda existe

Hoje:

- existe `LifeCounterHistoryState` como contrato tipado
- existe `LifeCounterHistoryStore` como persistencia propria
- o host espelha `history` canonico quando recebe `persist_snapshot`
- o bootstrap canonicamente gerado ja reidrata `gameHistory`, `allGamesHistory`, `currentGameMeta` e `gameCounter`
- o import/export nativo grava primeiro no store canonico

Mas ainda falta:

- reduzir ainda mais a leitura de compatibilidade do snapshot legado
- provar round-trip completo com snapshot Lotus parcial, stale ou ausente

Leitura:

- `history` deixou de ser apenas compatibilidade forte
- o runtime Lotus ainda recebe payload legado por compatibilidade visual
- `currentGameMeta/gameCounter` deixaram de ser detalhe implícito do bootstrap e passam a ter owner canonico junto de `history`

### 4. `Game Modes` ainda nao estao em contrato canonico proprio

Hoje:

- `Planechase`, `Archenemy` e `Bounty` seguem Lotus-first visualmente
- a shell nativa de `game modes` existe como apoio tecnico
- o proprio texto da sheet ainda assume que o runtime real fica embutido no Lotus

Isso cria uma fronteira em aberto:

- ou `Game Modes` ficam explicitamente fora do core que queremos fechar agora
- ou eles entram no escopo e precisam de contrato canonico proprio

Enquanto isso nao for decidido, o contador nao fecha `100%` sem ambiguidade.

### 5. O inventario do snapshot ja foi formalizado, mas ainda precisa ser usado como regra viva

Hoje o projeto ja usa chaves como:

- `players`
- `turnTracker`
- `gameSettings`
- `gameTimerState`
- `gameHistory`
- `allGamesHistory`
- `currentGameMeta`
- `__manaloom_table_state`
- `__manaloom_player_special_states`
- `__manaloom_player_appearances`
- `__manaloom_day_night_mode`

Agora ja existe um documento unico dizendo:

- qual chave e fonte primaria
- qual chave e compatibilidade
- qual chave ja pode ser reconstruida inteiramente do canonicamente salvo
- qual chave ainda depende de semantica interna do Lotus

Mas ainda falta:

- manter essa matriz atualizada conforme os dominios migram
- converter a matriz em criterio de implementacao para cada mutacao nova

Sem isso, ainda existe dependencia implicita do bundle.

### 6. Fallbacks internos ainda existem como runtime exercitavel

Isso nao e um problema por si so.

Mas, para fechamento de ownership, ainda falta classificar com precisao:

- o que e fallback de debug
- o que e suporte interno necessario
- o que ainda mascara dependencia real do Lotus

Enquanto o host continuar aceitando varios `open-native-*`, precisamos diferenciar:

- fallback interno legitimo
- ownership incompleto disfarcado de fallback

## Done definition for `core 100% nosso`

O life counter pode ser considerado fechado nesse objetivo quando:

1. toda mutacao critica de jogo tem writer canonico ManaLoom
2. o Lotus deixa de ser o primeiro escritor de estado em fluxos principais
3. o host consegue restaurar a mesa a partir do estado canonico mesmo sem snapshot Lotus valido
4. `history` tem contrato canonico proprio ou e explicitamente tirado do escopo do core
5. `Game Modes` tem fronteira final clara:
   - fora do core desta fase
   - ou com contrato canonico proprio
6. o reload do bundle deixa de ser o caminho padrao para mutacoes pequenas
7. o reload completo fica restrito a:
   - cold start
   - erro
   - fallback
8. o inventario `snapshot -> contrato canonico -> reidratacao Lotus` fica documentado e testado

## Recommended execution order

### Wave 1 - Formalizar o contrato

Status:

- concluida

Entregaveis:

- matriz completa das chaves do snapshot
- classificacao por dominio:
  - `canonical source`
  - `derived for Lotus`
  - `legacy compatibility`
  - `still Lotus-dependent`

Objetivo:

- remover dependencia implicita de formato legado

Done when:

- existe tabela unica com todas as chaves relevantes
- cada dominio tem dono claro

### Wave 2 - Fechar `history`

Status:

- concluida

Entregaveis:

- store propria de historico
- contrato tipado de historico vivo
- derivacao de `history` a partir do estado nosso, nao apenas do snapshot bruto
- serializer de volta para o Lotus enquanto o renderer depender disso

Objetivo:

- parar de tratar historico como leitura oportunista do storage legado

Done when:

- import/export e reopen funcionam com historico canonicamente salvo
- o app consegue restaurar historico sem depender apenas de `gameHistory/allGamesHistory`

Implementado nesta rodada:

- `LifeCounterHistoryState` e `LifeCounterHistoryStore`
- leitura preferencial do historico canonico no host e na tela viva
- persistencia canonica do historico ao receber snapshot do Lotus
- serializacao de volta para o formato legado apenas como compatibilidade do renderer
- `currentGameMeta` e `gameCounter` agora tambem sao persistidos no store canonico de `history`

### Wave 3 - Fechar a fronteira de `Game Modes`

Status:

- pendente

Entregaveis:

- decisao formal:
  - fora do core desta fase
  - ou contrato canonicamente nosso

Se ficar fora:

- documentar explicitamente isso como excecao
- excluir `Game Modes` da definicao de `core 100% nosso`

Se entrar:

- criar contrato proprio de disponibilidade, estado ativo e card pool handoff

Objetivo:

- eliminar a ultima ambiguidade grande de escopo

### Wave 4 - Trocar `reload` por sincronizacao incremental

Status:

- em andamento

Entregaveis:

- canal JS controlado para aplicar patches de estado no runtime Lotus
- `reload bundle` mantido apenas como fallback
- aplicacoes incrementais para:
  - settings
  - timer
  - turn tracker
  - player runtime
  - table state
  - day/night

Objetivo:

- transformar o Lotus em renderer sincronizado, nao em mini runtime rebootado

Done when:

- mutacoes pequenas nao exigem recarregar o bundle
- a UX continua visualmente identica

Implementado nesta rodada:

- `flutter_bootstrap.js` agora expoe `receivePatch` para aplicar mutacoes pontuais no `localStorage`
- o host consegue tentar patch incremental antes do reload completo
- `game timer` usa sync incremental no caso seguro `active -> active`, mas agora so considera sucesso quando o DOM `.game-timer` existe e confirma a aplicacao
- `turn tracker` usa sync incremental quando o tracker ja esta ativo, mantem a mesma configuracao estrutural e a mutacao e apenas avancar turnos para frente, voltar poucos passos ou mudar o starting player por rewind curto em `Turn 1`, mas agora so considera sucesso quando o DOM `.turn-time-tracker` existe e confirma a aplicacao
- `table state` usa sync incremental quando a mutacao e apenas ownership visual de `monarch/initiative`, reaplicando classes e moedas no DOM do Lotus sem rebootar o bundle
- `settings` continuam em reload por decisao explicita de seguranca, porque o Lotus mantem esse dominio em memoria e nao reage apenas ao patch de storage

### Wave 5 - Tornar o host o escritor primario

Entregaveis:

- identificar interacoes visuais do Lotus que ainda mutam estado sem passar pelo nosso caminho canonico
- interpor essas mutacoes por canal controlado, quando viavel sem alterar o visual
- manter o gesto e a animacao do Lotus, mas com confirmacao de estado via ManaLoom

Objetivo:

- sair de `Lotus muta e nos espelhamos`
- ir para `ManaLoom decide e Lotus renderiza`

Done when:

- os fluxos principais deixam de depender do Lotus como origem da verdade

## Priority checklist

Checklist curto de execucao:

- [ ] documentar a matriz completa do snapshot
- [ ] criar contrato canonico proprio para `history`
- [ ] decidir escopo final de `Game Modes`
- [ ] reduzir `reload bundle` como caminho padrao
- [ ] criar mecanismo de patch incremental do runtime Lotus
- [ ] provar reopen com estado canonico mesmo sem snapshot Lotus confiavel
- [ ] revisar quais `open-native-*` ainda sao fallback real e quais escondem ownership incompleto

## Performance note

Migrar `100%` do core vale a pena principalmente por:

- confiabilidade
- previsibilidade
- testabilidade
- facilidade de customizar o `WebView` depois

Ganho de desempenho tambem pode acontecer, mas o ganho real depende de:

- parar de recarregar o bundle para mutacoes pequenas
- parar de serializar e reidratar mais estado do que o necessario
- reduzir dependencia de `localStorage` como barramento principal

Se o projeto migrar o core mas continuar em `snapshot + reload`, o ganho de performance sera limitado.

## Final recommendation

Nao abrir customizacao visual nova antes de fechar pelo menos estas tres frentes:

1. contrato do snapshot formalizado
2. `history` canonicamente nosso
3. sincronizacao incremental no lugar de `reload` como caminho principal

Depois disso, o time pode mexer no design do Lotus com muito menos risco de acoplar visual novo a um runtime ainda ambiguo.

## Current implementation checkpoint

Depois desta rodada, a leitura mais correta e:

- `history` ja tem owner canonico ManaLoom
- o renderer Lotus ainda recebe `history/meta/counter` em formato legado por compatibilidade
- `receivePatch` existe e ja reduz reload em parte do `game timer`
- o `turn tracker` ja tem casos seguros de sync pelo proprio runtime do Lotus, disparando `click` para avancar e `long press` simulado para rewind curto limitado, inclusive para mudanca curta de starting player em `Turn 1`, sem rebootar o bundle
- `settings` nao devem migrar para patch cego enquanto o runtime do Lotus continuar mantendo esse estado em memoria interna
- o proximo alvo tecnico com melhor relacao ganho/risco continua sendo mapear de forma conservadora quais dominios aceitam patch incremental real
