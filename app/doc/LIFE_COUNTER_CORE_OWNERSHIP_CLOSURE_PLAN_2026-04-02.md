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
- `table state` agora tambem aceita sync incremental para `storm`, `monarch` e `initiative`; o `storm` passa a fechar por storage patch sem rebootar o bundle, e `monarch/initiative` continuam reaplicando ou limpando ownership visual quando os `.player-card` do DOM real do Lotus estao presentes
- `day/night` continua live sem takeover visual, mas agora so considera sucesso quando o `.day-night-switcher` responde; se falhar, cai em `reload` de fallback
- handoffs embutidos de `Game Modes` agora confirmam que o seletor primario, o seletor de `edit cards` e os seletores de fechamento existem no DOM do Lotus antes de registrar sucesso; seletor ausente passa a gerar falha observavel em vez de sucesso silencioso, e o dismiss da shell agora diferencia acao escolhida de acao realmente entregue
- `turn tracker`, `game timer` e `table state` agora tambem registram na observabilidade se a aplicacao fechou por `live_runtime` ou `reload_fallback`, junto do sinal de elegibilidade do patch live
- `day/night` agora tambem registra `live_patch_eligible` e `apply_strategy`, fechando o mesmo contrato observavel dos dominios com live apply/fallback
- `dice` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a mutacao fica restrita ao resultado canonico de rolagem; com `turn tracker` ativo, isso continua permitido apenas se `first player` e o estado estrutural do tracker nao mudarem
- `player state` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando a sheet so altera dados canonicos de rolagem (`lastPlayerRolls`, `lastHighRolls`, `firstPlayerIndex` quando permitido e `lastTableEvent`), reutilizando o mesmo criterio conservador ja aceito em `dice`
- `commander damage` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando o proprio settings garante que o dominio esta invisivel na mesa (`autoKill` desligado, `life loss on commander damage` desligado e counters fora do player card), evitando reboot do bundle quando a mutacao e apenas canonica
- `player counter` agora tambem tem um recorte sem `reload` por `canonical_store_sync` quando o settings ja esconde counters no player card e `poison` nao pode disparar `autoKill`, evitando reboot do bundle quando a mutacao fica invisivel para a mesa
- `player state` agora tambem herda `canonical_store_sync` sem rebootar o bundle no subcaso em que o efeito final do hub fica limitado a `partner commander` oculto pelo settings atual, mantendo fallback quando counters continuam visiveis ou quando a mutacao mistura outros efeitos fora desse contrato
- os recortes ocultos de `commander damage`, `player counter` e `partner commander` agora respeitam a visibilidade real configurada no Lotus: `commander damage` pode fechar sem `reload` quando `showCommanderDamageCounters` continua desligado mesmo com card ativo, e `player counter/partner commander` tambem podem fechar sem `reload` quando `showRegularCounters` continua desligado
- a suite do hub de `player state` agora tambem prova explicitamente esses dois subcasos intermediarios, garantindo que o fluxo herdado continua sem `reload` quando o card permanece ativo mas o tipo especifico de counter segue escondido pelo settings
- o recorte oculto de `partner commander` agora tambem volta para `reload_fallback` quando existe `backgroundImagePartner` no payload do jogador, evitando vender sync canonico como seguro em um caso que ainda pode alterar a superficie visual do Lotus
- quando `player state` nasce de takeover do option-card do Lotus, o host agora tambem reseta a superficie do board apos apply sem `reload`, evitando deixar o overlay visual stale mesmo quando a mutacao em si fechou por `canonical_store_sync` ou `live_runtime`
- `turn tracker` e `game timer` agora tambem expõem `sync_blockers`, deixando explicito na observabilidade quando o fallback veio de `tracker/timer` ainda inativo, mudanca estrutural do tracker ou mudanca de posicao fora dos recortes live suportados
- `day/night` e `table state` agora tambem expõem `sync_blockers` com o `reason` real devolvido pelo runtime do Lotus, deixando explicito quando o fallback veio de `switcher` ausente, `player cards` ausentes ou rejeicao equivalente do DOM real
- `settings`, `player appearance` e `set life` agora tambem expõem `sync_blockers`, deixando explicito quando o fallback e puramente arquitetural: settings ainda mantidos em memoria propria do Lotus, aparencia ainda acoplada a superficie visual do board e vida ainda renderizada diretamente na mesa
- `settings` agora tambem registra explicitamente `live_patch_eligible: false` e `apply_strategy: reload_fallback`, alinhando a telemetria com a decisao arquitetural de manter esse dominio fora do live sync
- `history` e `card search` agora registram `surface_strategy: native_fallback` nos eventos da shell interna, deixando explicito que esses fluxos sao apoio tecnico e nao apply de runtime do Lotus
- `history import` agora tambem registra `transfer_strategy: clipboard_import`, `apply_strategy: canonical_store_sync` e `reload_required: false`, deixando explicito que o dominio muda primeiro no contrato canonico sem rebootar o bundle
- `settings`, `day/night`, `turn tracker`, `game timer`, `dice` e `table state` agora tambem registram `surface_strategy: native_fallback` na abertura e no dismiss das sheets internas, alinhando a telemetria dessas superfices utilitarias ao papel Lotus-first atual
- `commander damage`, `player appearance`, `player counter`, `player state` e `set life` agora tambem registram `surface_strategy: native_fallback` na abertura e no dismiss das sheets internas, fechando o mesmo contrato observavel para o runtime de jogador
- `player appearance export/import` agora tambem registram `surface_strategy: native_fallback` e `transfer_strategy` (`clipboard_export` / `clipboard_import`), deixando explicito quando o fluxo auxiliar usa transporte por clipboard
- `player appearance profile save/delete` agora tambem registram `surface_strategy: native_fallback` e `persistence_strategy: owned_profile_store`, separando persistencia de perfis ManaLoom-owned dos eventos de apply e clipboard
- `player appearance profile select` agora tambem registra `surface_strategy: native_fallback` e `persistence_strategy: owned_profile_store`, deixando explicito quando a sheet apenas carrega um preset salvo para o draft local
- o host agora tambem tem cobertura unitaria para o fallback `canonical -> bootstrap Lotus` sem snapshot persistido, incluindo `day/night`, os caminhos `session/settings/timer/history`, `history-only` e `day/night-only`
- o host agora tambem espelha `day/night` do `persist_snapshot` Lotus para a store canonica, e limpa estado stale quando a chave `__manaloom_day_night_mode` deixa de existir no snapshot
- o mirror canonico do host agora tambem limpa `session` e `settings` stale quando o snapshot Lotus deixa de trazer `players` ou `gameSettings`, alinhando esse comportamento ao cleanup ja existente de `day/night`, `game timer` e `history`
- o mirror canonico do host agora tambem preserva `history` meta-only (`currentGameMeta` / `gameCounter`) quando o snapshot Lotus traz esse dominio sem eventos, evitando perder ownership canonico logo no primeiro `persist_snapshot`
- o round-trip de `history` meta-only agora tambem tem prova automatizada na store canonica e no fallback `history-only -> bootstrap Lotus`, evitando regressao silenciosa nesse subdominio sem eventos
- o fallback canônico do host agora tambem tem prova dedicada para `session + history` meta-only, evitando que `currentGameMeta/gameCounter` sejam substituídos pelos defaults internos quando a mesa canônica já existe mas o histórico ainda está vazio
- a deduplicacao de observabilidade do `persist_snapshot` no host agora tambem respeita o primeiro mirror de `session` e `history`, evitando que uma carga parcial anterior esconda o primeiro espelhamento canonico desses dominios na mesma carga do Lotus
- `history` e `card search` agora identificam explicitamente na observabilidade que a sheet nativa acionada por atalho interno eh `native_fallback`; `history export` tambem marca o transporte como `clipboard_export`

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

Leitura operacional atual:

- `dice` agora tambem pode fechar por `canonical_store_sync` sem rebootar o bundle quando a shell so altera resultado canonico de rolagem; com `turn tracker` ativo, esse recorte continua permitido apenas se `first player` e o estado estrutural do tracker ficarem intactos
- `player state` agora tambem pode fechar por `canonical_store_sync` sem rebootar o bundle no subcaso em que a sheet so altera dados canonicos de rolagem, reaproveitando o mesmo criterio conservador de `dice`
- `player state` agora tambem herda `canonical_store_sync` sem rebootar o bundle nos subcasos em que o efeito final do hub fica limitado a `player counter` oculto ou `commander damage` oculto, reaproveitando exatamente os mesmos gates de settings que ja valiam fora do hub
- `player state` agora tambem herda `canonical_store_sync` sem rebootar o bundle no subcaso em que o efeito final do hub fica limitado a `partner commander` oculto, desde que `showCountersOnPlayerCard` continue desligado e a mudanca nao venha misturada com outros efeitos fora desse contrato
- os recortes ocultos desses dominios agora tambem consideram os flags especificos de visibilidade do Lotus, e nao so o toggle global `showCountersOnPlayerCard`: `commander damage` respeita `showCommanderDamageCounters`, e `player counter/partner commander` respeitam `showRegularCounters`
- essa mesma leitura agora fica coberta no proprio hub de `player state`, evitando regressao entre o comportamento das sheets diretas e o fluxo consolidado do runtime de jogador
- em `partner commander`, o host agora tambem bloqueia `canonical_store_sync` quando o jogador carrega `backgroundImagePartner`, porque esse asset ainda pode mudar a superficie visivel do Lotus mesmo com counters regulares escondidos
- quando a origem do fluxo e `player_option_card_presented`, o evento de apply agora tambem expõe `surface_reset_required` e `surface_reset_strategy`, e o host sempre reabre o bundle apos o apply para fechar corretamente a superficie takeover do Lotus
- quando `player state` vindo de `player_option_card_presented` e fechado sem apply, o evento de dismiss agora tambem expõe `surface_reset_required` e `surface_reset_strategy`, deixando explicito o reset do bundle usado so para limpar a superficie takeover
- `player state` agora tambem pode fechar por `live_runtime` sem rebootar o bundle no subcaso em que o efeito final do hub e apenas um `set life` curto em um unico jogador, reaproveitando os mesmos controles reais do Lotus que ja sustentam o atalho direto de `set life`
- `commander damage` agora tambem pode fechar por `canonical_store_sync` sem rebootar o bundle no subcaso em que o settings ja garante ausencia de reflexo visual na mesa, mantendo `reload` para os cenarios em que esse dominio ainda afeta vida, estado letal ou counters visiveis
- `player counter` agora tambem pode fechar por `canonical_store_sync` sem rebootar o bundle no subcaso em que o settings ja garante ausencia de reflexo visual na mesa, mantendo `reload` quando os counters ainda aparecem no player card ou quando `poison` pode abrir `autoKill`
- o atalho direto de `set life` agora tambem pode fechar por `live_runtime` sem rebootar o bundle quando a mudanca fica limitada a um delta medio de vida no jogador alvo e o runtime real do Lotus confirma os controles da mesa; o fallback agora fica reservado para deltas acima desse limite, jogador previamente inativo ou mudanca estrutural fora desse contrato
- as suites de `player values` agora tambem provam explicitamente essas fronteiras, garantindo que `commander damage` e `player counter` continuam em `reload_fallback` assim que o settings volta a permitir reflexo visual ou efeito colateral real na mesa
- `commander damage` e `player counter` agora tambem expõem `sync_blockers` na observabilidade de apply, deixando explicito por que um recorte oculto caiu em `reload_fallback`
- `dice` e `player state` agora tambem expõem `sync_blockers` nos applies baseados em rolagem, deixando explicito quando o fallback veio de mudanca estrutural do tracker, troca indevida de `first player` ou mutacao fora do contrato canonico de roll
- no recorte oculto de `partner commander`, `player state` agora tambem deixa explicito quando o fallback veio de counters ainda visiveis na mesa ou de mutacao misturada fora do contrato escondido do parceiro
- `turn tracker` e `game timer` agora tambem expõem `sync_blockers` nos applies com live path, deixando explicito quando o fallback veio de `tracker/timer` ainda inativo, mudanca estrutural do tracker ou mudanca de posicao fora dos recortes live suportados
- `day/night` e `table state` agora tambem expõem `sync_blockers` com o `reason` real vindo do runtime do Lotus, deixando explicito quando o fallback veio de falha de confirmacao do DOM em vez de ficar escondido sob um `reload_fallback` generico
- `settings` e `player appearance` continuam exponto `sync_blockers` puramente arquiteturais; em `set life`, os blockers agora tambem distinguem quando o fallback veio de delta acima do limite live, jogador previamente inativo, vida letal sem `autoKill` ou mudanca fora do contrato de vida alvo
- os applies de `settings`, `day/night`, `turn tracker`, `game timer`, `player appearance` e `table state` agora tambem expõem `reload_required`, alinhando toda a trilha observavel de apply ao mesmo contrato ja usado pelos demais dominios
- `settings` continua em `reload` por seguranca do bundle Lotus, e agora isso tambem aparece de forma explicita na telemetria de apply
- `history` e `card search` seguem Lotus-first visualmente; quando a shell interna entra em cena, a observabilidade agora marca isso explicitamente como `native_fallback`
- `history import` continua vindo pela sheet interna quando necessario, mas a observabilidade agora deixa explicito que a mudanca real acontece por sync canonico no ManaLoom, sem `reload`
- nas utility sheets (`settings`, `day/night`, `turn tracker`, `game timer`, `dice`, `table state`), a observabilidade agora tambem deixa explicito quando a interacao passou por suporte interno nativo, sem confundir a abertura da sheet com takeover visual principal
- nas sheets de runtime de jogador (`commander damage`, `player appearance`, `player counter`, `player state`, `set life`), a observabilidade agora tambem deixa explicito quando a interacao passou por suporte interno nativo, sem confundir a abertura da sheet com takeover visual principal
- em `game modes`, os eventos de open, dismiss e falha de entrega agora tambem expõem `surface_strategy: native_fallback`, alinhando essa shell Lotus-first ao mesmo contrato observavel das outras superfices internas
- em `player appearance`, os eventos auxiliares de export/import agora tambem deixam explicito quando o fluxo passou por clipboard, em vez de parecer mutacao direta do runtime
- em `player appearance`, os eventos auxiliares de save/delete de perfil agora tambem deixam explicito quando o fluxo passou por persistencia propria do ManaLoom, em vez de parecer mutacao direta do runtime Lotus
- em `player appearance`, a selecao de perfil salvo agora tambem fica observavel como uso de preset ManaLoom-owned no draft da sheet, sem parecer apply real da mesa
- quando `player appearance` nasce de takeover da superficie de background do Lotus, o evento de dismiss agora tambem expõe `surface_reset_required` e `surface_reset_strategy`, deixando explicito quando o host reabre o bundle apenas para limpar a superficie takeover
- `history` e `card search` continuam Lotus-first visuais no produto, e a observabilidade das sheets internas agora deixa explicito quando o fluxo registrado e apenas fallback nativo de suporte
- o caminho `storage_bootstrap_restored_from_canonical` agora tem prova unitaria do payload de fallback gerado a partir das stores canonicas, incluindo `day/night`, sem depender de `localStorage` Lotus previamente salvo
- o merge de `storage_bootstrap` agora tambem poda chaves stale de `session`, `settings`, `game timer`, `day/night` e `history` quando o fallback canonico daquele dominio nao existe mais, evitando que um snapshot Lotus antigo ressuscite estado limpo no reopen

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
- os handoffs embutidos agora validam a presenca do seletor alvo antes de considerar que a acao foi entregue ao runtime do Lotus, inclusive no segundo passo de `edit cards`

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
- `table state` usa sync incremental para `storm`, `monarch` e `initiative`; o `storm` fecha por storage patch sem rebootar o bundle, enquanto `monarch/initiative` reaplicam ou limpam classes, moedas e estado da `menu-button` no DOM do Lotus
- `day/night` atualiza `__manaloom_day_night_mode` e o `.day-night-switcher` com confirmacao explicita de sucesso; se o switcher nao responder, o host faz fallback via `reload`
- `game modes` embutidos agora so registram sucesso quando o seletor primario, o follow-up de `edit cards` e os seletores de fechamento existem no DOM real do Lotus; o segundo passo de card pool saiu do modelo `setTimeout` fire-and-forget e passa a ser confirmado em chamada separada
- a observabilidade da shell agora registra `native_game_modes_action_failed` e marca `action_delivered` no evento de dismiss, evitando telemetria ambigua quando a acao foi escolhida mas nao chegou ao Lotus
- `turn tracker`, `game timer` e `table state` agora marcam `live_patch_eligible` e `apply_strategy` nos eventos de apply, o que separa claramente sucesso via runtime do Lotus e fallback por `reload`
- `day/night` agora tambem marca `live_patch_eligible` e `apply_strategy` no evento de apply, deixando o fallback para `reload` visivel na mesma trilha operacional
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
