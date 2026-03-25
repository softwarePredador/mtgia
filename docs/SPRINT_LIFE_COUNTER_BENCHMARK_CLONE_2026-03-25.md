# Sprint de Clone: Life Counter Benchmark

> Documento operacional criado em `2026-03-25`.
> Status: `ACTIVE`.
> Esta sprint substitui a direcao visual e interacional definida em `docs/SPRINT_LIFE_COUNTER_TABLETOP_2026-03-25.md` para a frente `life counter`.

## Objetivo

Transformar `app/lib/features/home/life_counter_screen.dart` em um clone funcional e visual do benchmark local armazenado em `dddddd/`.

Decisao explicitamente assumida nesta sprint:

- ignorar, nesta frente, a sinergia com a linguagem visual atual do restante do app
- abandonar a direcao anterior de "inspirar sem copiar"
- usar o benchmark como fonte de verdade para:
  - layout
  - hierarquia
  - interacao
  - estados especiais
  - overlays
  - fluxo de rolagem

O que deve ser preservado do nosso app:

- logica de jogo ja implementada
- persistencia local
- undo/historico interno
- suporte a contadores especificos de Commander
- testes e estabilidade tecnica

Eixo adicional incorporado nesta mesma sprint em `2026-03-25`:

- motion
- feedback de evento
- transicoes de estado

Decisao explicitamente assumida:

- nao abrir uma sprint separada so para animacao
- acrescentar motion e feedback dentro desta mesma sprint de clone
- so considerar o `life counter` realmente pronto quando layout, interacao e motion convergirem juntos

Resumo da mudanca de criterio:

- antes: `superar benchmark sem copiar`
- agora: `copiar o benchmark o mais fielmente possivel e depois customizar`

## Fonte de verdade visual

As capturas abaixo formam o benchmark oficial desta sprint:

1. `dddddd/WhatsApp Image 2026-03-25 at 12.13.00.jpeg`
   - mesa em 4 quadrantes
   - numero central dominante
   - estado especial `DECKED OUT.`
2. `dddddd/WhatsApp Image 2026-03-25 at 12.13.09.jpeg`
   - hub central expandido
   - barra utilitaria inferior
   - estado especial `ANSWER LEFT.`
3. `dddddd/WhatsApp Image 2026-03-25 at 12.13.21.jpeg`
   - `High Roll` dominante por jogador
   - vencedor com fundo comemorativo
   - estado `KO'D!`
4. `dddddd/WhatsApp Image 2026-03-25 at 12.13.41.jpeg`
   - seletor de quantidade/layout de jogadores
5. `dddddd/WhatsApp Image 2026-03-25 at 12.13.54.jpeg`
   - overlay de configuracoes por cima da mesa
6. `dddddd/WhatsApp Image 2026-03-25 at 12.14.07.jpeg`
   - estado especial `COMMANDER DOWN.`
7. `dddddd/WhatsApp Image 2026-03-25 at 13.50.23.jpeg`
   - estado normal com valores baixos
   - reforco da geometria base da mesa
8. `dddddd/WhatsApp Image 2026-03-25 at 13.50.32.jpeg`
   - keypad numerico flutuante para `set life`
9. `dddddd/WhatsApp Image 2026-03-25 at 13.50.47.jpeg`
   - `High Roll` com numero gigante e vencedor obvio
10. `dddddd/WhatsApp Image 2026-03-25 at 13.51.38.jpeg`
   - repeticao consistente do hub expandido + rail inferior

Essas 10 imagens deixam claro que o benchmark nao e uma tela isolada: ele e uma linguagem completa de mesa.

## Mandato de clone

Nesta frente, "clone" significa:

1. copiar a geometria principal da mesa
2. copiar a hierarquia dominante de leitura
3. copiar a logica do hub central e da barra inferior
4. copiar o tratamento de `High Roll`
5. copiar os estados de derrota/estado especial em painel cheio
6. copiar a abordagem de overlay por cima da mesa em vez de `sheet` tradicional

Nao entra no escopo de copia literal:

- branding do concorrente
- prompts de review/patron/ads
- copy exata dos textos de monetizacao

Esses itens sao ruido de produto do concorrente, nao nucleo do `life counter`.

## O que o benchmark faz melhor

### 1. O painel do jogador deixa de ser "card de app"

- cada jogador ocupa um quadrante de mesa inteiro
- o painel parece superficie fisica, nao card sobre fundo
- quase nao existe camada secundaria visivel

### 2. O valor principal domina o espaco

- vida normal ocupa o painel
- durante `High Roll`, o numero do dado toma o protagonismo total
- o valor nao aparece como badge; ele vira o estado do painel

### 3. Estados especiais sao absolutos

- `KO'D!`
- `DECKED OUT.`
- `COMMANDER DOWN.`
- `ANSWER LEFT.`

O benchmark nao trata estados especiais como detalhe lateral. Ele transforma o painel inteiro.

### 4. O hub central resolve a mesa

- botao central hexagonal sempre visivel
- menu expandido em "petalas" ao redor
- acoes nomeadas de forma brutalmente obvia:
  - `PLAYERS`
  - `HIGH ROLL`
  - `SETTINGS`
  - `RESTART`
  - `HELP`

### 5. Overlays acontecem na propria mesa

- configuracoes aparecem sobre a mesa escurecida
- seletor de jogadores aparece sobre a mesa
- keypad numerico aparece sobre a mesa

O benchmark evita a sensacao de "sair da partida".

### 6. A ferramenta de rolagem e mesa-first

- `High Roll` tem nome proprio
- os valores aparecem em todos os jogadores
- vencedor fica obvio
- empate nao precisa de interpretacao

### 7. O benchmark tem mais vida de evento

- o painel muda de estado com mais presenca
- `High Roll` parece acontecimento, nao badge
- overlay parece surgir da mesa, nao abrir tela secundaria
- estados especiais parecem takeover, nao anotacao

## Gap atual entre o nosso app e o benchmark

### O que ja aproveita a logica certa

- persistencia de sessao
- undo
- `High Roll` com desempate
- `D20` individual
- `poison inline`
- `commander tax inline`
- acesso rapido a `commander damage`
- derivacao do `1o jogador`

### O que ainda esta longe do benchmark

1. o painel do jogador ainda carrega semantica demais
- badges
- texto auxiliar
- affordances de app
- componentes secundaros visiveis demais

2. o `High Roll` ainda nao toma o painel inteiro
- ele existe
- mas ainda esta com cara de estado adicional
- o benchmark trata roll como modo principal temporario

3. o hub central ainda esta "bom de produto", mas nao clonado
- ainda ha cheiro de design autoral nosso
- o benchmark usa uma composicao mais crua, mais fisica e mais direta

4. ainda dependemos demais de `sheet`
- o benchmark usa overlays/superficies de mesa
- o nosso fluxo ainda recorre a bottom sheet e modais mais padrao Flutter

5. a barra inferior utilitaria nao existe no mesmo formato
- `DICE`
- `HISTORY`
- `CARD SEARCH`

Hoje isso nao esta resolvido como rail persistente na mesa.

6. os estados especiais ainda nao sao um sistema
- `KO'D!` avancou
- mas ainda nao existe familia completa no mesmo padrao brutal do benchmark

7. motion e feedback ainda estao abaixo do benchmark
- o nosso app ja esta mais forte em shell e hierarquia
- mas ainda tem menos vida visual
- ainda falta uma linguagem de transicao/evento coerente para:
  - `High Roll`
  - overlays
  - `Set Life`
  - estados especiais

## Caracteristicas obrigatorias do clone

Estas caracteristicas passam a ser obrigatorias para considerar a sprint encerrada.

### Layout da mesa

- 2, 3 e 4 jogadores precisam parecer a mesma familia visual do benchmark
- quadrantes full-bleed
- separacao preta/escura espessa entre jogadores
- cantos bem arredondados
- area util maxima para numero central

### Painel do jogador

- numero principal ocupando o miolo do painel
- `+` e `-` pequenos nas extremidades do painel
- toque no numero central como gesto primario
- estados especiais tomando o painel inteiro

### Roll / High Roll

- `High Roll` vira estado principal temporario do painel
- valor do dado toma o lugar do numero de vida
- vencedor recebe tratamento visual especial
- empate recebe tratamento explicito

### Hub central

- botao hexagonal central sempre presente
- menu expandido radial/petal
- acoes com naming curto e pesado
- zero dependencia de `AppBar`

### Overlays

- `Players`
- `Settings`
- `Set Life`
- `Dice`
- `History`

Todos devem parecer extensoes da mesa, nao telas soltas.

### Barra utilitaria inferior

- rail fixa ou quase fixa no rodape da mesa
- acoes principais do benchmark replicadas
- linguagem visual do benchmark, nao do restante do app

## Itens do benchmark a copiar 1:1

### 1. Geometria

- quadrantes
- proporcao do numero
- zona central hexagonal
- rail inferior em pills pretas

### 2. Hierarquia

- numero principal domina
- texto quase nao existe
- estado especial domina o painel inteiro
- utilidades globais ficam no centro/rodape

### 3. Interacao

- toque central relevante
- menu central expandivel
- `High Roll` como acao primaria de mesa
- `set life` via keypad

### 4. Linguagem visual de mesa

- superficies planas
- contraste alto
- pouca ornamentacao
- nenhum card "bonitinho" tradicional

## Itens que precisam ser adaptados ao MTG sem fugir do benchmark

### 1. Poison

- nao deve reaparecer como badge de app
- deve entrar na mesma gramatica do benchmark
- se entrar em painel/overlay, precisa parecer parte da mesa

### 2. Commander damage

- o benchmark nao cobre esse caso com a complexidade do nosso app
- adaptacao correta:
  - manter a logica atual
  - redesenhar a apresentacao para parecer ferramenta de mesa, nao sheet tecnica

### 3. Commander lethal

- deve ganhar estado visual da familia `COMMANDER DOWN`
- sem depender de selo pequeno

### 4. Deck out / answer left / kill / poison

- precisamos decidir um vocabulário padrao de estados especiais do nosso app
- todos devem seguir a mesma familia visual de painel cheio

## Sprint executavel

### Wave 0: Rebaseline tecnica

Objetivo:

- manter a logica forte atual e desmontar a casca visual autoral

Escopo:

1. congelar a malha de testes atual do `life counter`
2. separar estado de jogo de apresentacao de painel
3. mapear widgets que precisam ser descartados ou reescritos
4. tratar o benchmark como referencia primaria na implementacao

Aceite:

- nenhuma feature essencial atual pode ser perdida
- toda divergencia visual futura deve ser justificada pelo benchmark, nao pelo tema do app

### Wave 1: Mesa base 1:1

Objetivo:

- clonar a composicao geral da mesa

Escopo:

1. reescrever layout 2p/3p/4p para bater com o benchmark
2. remover cheiro de `card`/`surface` tradicional
3. clonar o botao central fechado
4. clonar o espaçamento/separacao entre quadrantes

Aceite:

- side-by-side com o benchmark deve mostrar a mesma leitura de mesa
- o usuario deve perceber imediatamente que se trata da mesma logica visual

Status atual:

- `IN_PROGRESS`
- primeiro corte implementado em `2026-03-25`:
  - fundo da mesa agora e `black-first`, sem gradiente/glow autoral
  - quadrantes dos jogadores ficaram mais `full-bleed`, com gutter preto fino e borda pesada
  - paleta base dos jogadores foi trocada para a familia cromatica do benchmark
  - shell do painel deixou de usar gradientes e sombras de `card`
  - botao central foi reduzido a um nucleo geometrico mais proximo do benchmark
  - labels persistentes de jogador foram removidas da mesa principal
- segundo corte implementado em `2026-03-25`:
  - hub expandido deixou de ser um card central e virou um menu radial/petal
  - a acao `PLAYERS` ganhou entrada dedicada no centro da mesa
  - `SETTINGS`, `RESTART`, `HELP` e `HIGH ROLL` passaram para a composicao radial
  - utilidades pequenas (`D20`, `COIN`, `1ST`, `UNDO`) foram rebaixadas para micro-pills sob o nucleo central
  - a barra inferior branca com pills pretas (`DICE`, `HISTORY`, `CARD SEARCH`) entrou na shell da mesa, aproximando o rodape do benchmark
- terceiro corte implementado em `2026-03-25`:
  - `SETTINGS` deixou a semantica de bottom sheet e passou a usar overlay centrado na propria mesa
  - `TABLE TOOLS` tambem saiu da sheet generica e entrou na mesma familia de overlay preto/branco do clone
  - `HISTORY` e `CARD SEARCH` passaram a compartilhar a mesma shell de overlay
  - `PLAYERS` foi alinhado a essa mesma shell de overlay, deixando de usar um dialogo visualmente paralelo
  - a malha foi alinhada ao novo contrato visual (`SETTINGS`, `PLAYERS`, `STARTING LIFE`, `TABLE TOOLS`)
- quarto corte implementado em `2026-03-25`:
  - o toque no numero central do jogador passou a abrir `SET LIFE`, aproximando o life core da logica do benchmark
  - os atalhos locais rapidos foram preservados como gesto secundario (`long press`) no life core, em vez de ocupar o gesto principal
  - o rail inferior ganhou `DICE` como overlay proprio, deixando de reaproveitar `TABLE TOOLS`
  - o keypad de `SET LIFE` entrou como overlay dedicado na propria mesa, em vez de ajuste indireto por taps incrementais

Gap restante desta wave:

- geometria 2p/3p/4p ainda precisa convergir mais para o benchmark em side-by-side
- o hub radial ainda precisa de refinamento fino de angulos, tamanhos e espacamento para bater mais 1:1
- `DICE` e `SET LIFE` ainda nao entraram na familia final de overlay clone
- a hierarquia visual do `SET LIFE` ainda precisa convergir mais para o keypad do benchmark em side-by-side
- `DICE` ainda cobre as utilidades certas, mas a composicao do overlay pode se aproximar mais da referencia

### Wave 2: Painel do jogador 1:1

Objetivo:

- transformar o player panel em clone do painel do benchmark

Escopo:

1. numero central gigante
2. `+` e `-` nas extremidades corretas
3. toque no numero abrindo `Set Life`
4. esconder ou remover elementos secundarios nao presentes no benchmark
5. revisar rotacao/orientacao em multiplayer

Aceite:

- numero principal ocupar a maior parte da altura util
- vida nao parecer badge, chip ou card interno
- painel poder ser lido a distancia

### Wave 3: Hub central 1:1

Objetivo:

- clonar o comportamento do centro da mesa

Escopo:

1. botao central fechado com icone compacto
2. expansao radial/petal
3. acoes:
   - `PLAYERS`
   - `HIGH ROLL`
   - `SETTINGS`
   - `RESTART`
   - `HELP`
4. central de close no mesmo comportamento do benchmark

Aceite:

- o hub central precisa ser reconhecivel em side-by-side
- as acoes devem parecer utilidades de mesa, nao app menu

### Wave 4: High Roll 1:1

Objetivo:

- clonar o momento de abertura de partida

Escopo:

1. `High Roll` com takeover do painel
2. numero do dado gigante por jogador
3. vencedor com tratamento visual especial
4. empate com tratamento explicito
5. rerrolagem so dos empatados
6. `1o jogador` herdado do vencedor unico

Aceite:

- quem ganha deve ser entendivel em menos de 1 segundo
- o roll deve parecer evento de mesa, nao metadado

### Wave 5: Estados especiais 1:1

Objetivo:

- transformar derrota e estado especial em sistema forte

Escopo:

1. `KO'D!`
2. `DECKED OUT.`
3. `COMMANDER DOWN.`
4. estados equivalentes para poison/lethal/leave
5. recuperar/reativar jogador mantendo coerencia com o benchmark

Aceite:

- qualquer estado especial deve dominar o painel inteiro
- nao pode parecer selo ou overlay pequeno

Status atual:

- `IN_PROGRESS`
- primeiro corte implementado em `2026-03-25`:
  - `KO'D!` deixou de ser apenas detalhe do life core e passou a takeover real do painel
  - `COMMANDER DOWN.` entrou como estado de takeover para `21+` de commander damage
  - poison lethal (`10+`) ganhou takeover proprio (`TOXIC OUT.`)
  - a mesma familia visual passou a ser compartilhada pelos estados especiais, com painel escurecido, borda/acento forte e tipografia central dominante

### Wave 6: Overlays 1:1

Objetivo:

- tirar a sensacao de sheet generica e clonar overlays da mesa

Escopo:

1. `Settings` overlay
2. `Players` overlay
3. `Set Life` keypad overlay
4. `Dice` overlay
5. `History` overlay

Aceite:

- abrir configuracao nao pode parecer troca de tela
- overlays devem preservar a leitura de que a partida continua embaixo

### Wave 7: Rail inferior 1:1

Objetivo:

- introduzir a barra utilitaria do benchmark

Escopo:

1. `DICE`
2. `HISTORY`
3. entrada equivalente ao `CARD SEARCH`
4. comportamento visual em pills escuras pesadas

Aceite:

- o rodape deve parecer ferramenta de mesa permanente
- nao pode parecer bottom navigation do restante do app

### Wave 8: Adaptacao MTG dentro da shell clonada

Objetivo:

- encaixar nossos contadores especificos na linguagem do clone

Escopo:

1. poison sem badge de app
2. commander tax na mesma gramatica
3. commander damage com leitura de mesa
4. storm/monarch/initiative sem poluir a board shell

Aceite:

- o usuario deve sentir que esses recursos sempre pertenceram ao clone
- nenhum contador pode "vazar" a linguagem antiga do projeto

### Wave 9: Motion e feedback 1:1

Objetivo:

- incorporar a sensacao de evento do benchmark sem abrir uma sprint paralela

Escopo:

1. `High Roll` com takeover animado do painel
2. reveal do numero do dado em escala protagonista
3. transicao de vencedor/empate com hierarquia forte
4. entrada/saida dos overlays da mesa com sensacao de continuidade
5. `Set Life` com feedback de keypad e confirmacao mais viva
6. estados especiais (`KO'D!`, `COMMANDER DOWN`, futuros equivalentes) com transicao de takeover
7. revisar duracao/easing para que a mesa pareca ferramenta fisica, nao interface lenta

Aceite:

- o jogador precisa sentir quando um evento importante aconteceu
- o numero do `High Roll` nao pode parecer aparecer como badge comum
- os overlays precisam parecer nascer da mesa e nao substituir a tela
- motion nao pode virar enfeite; precisa reforcar leitura e estado

Status atual:

- `IN_PROGRESS`
- primeiro corte implementado em `2026-03-25`:
  - `PlayerPanel` ganhou transicao animada de estado no life core via `AnimatedSwitcher`
  - `High Roll` passou a acender o painel com glow radial e `AnimatedContainer`, aproximando o takeover do benchmark
  - o numero protagonista e o status de vencedor/empate passaram a entrar com mais presenca no proprio miolo do painel, nao so em badges
  - a malha focada foi revalidada verde depois desse recorte
- segundo corte implementado em `2026-03-25`:
  - a abertura dos overlays da mesa foi centralizada em um helper proprio com `fade + scale + slide`
  - `SETTINGS`, `PLAYERS`, `DICE`, `TABLE TOOLS`, `HISTORY`, `CARD SEARCH` e `SET LIFE` agora entram e saem com a mesma sensacao de nascer da mesa
  - a familia de overlay deixou de depender de aparicao seca por `showGeneralDialog`
  - a malha focada continuou verde apos a introducao desse motion compartilhado

## Backlog consolidado por prioridade

### P0

1. reescrever a shell da mesa
2. reescrever o painel do jogador
3. reescrever o hub central
4. reescrever o `High Roll`
5. implementar overlays `Players`, `Settings` e `Set Life`

### P1

1. estados especiais completos
2. rail inferior
3. `Dice` e `History`
4. commander damage em fluxo clone-compatible
5. motion de evento para `High Roll`, overlays e estados especiais

### P2

1. ajuste fino de poison/tax/storm/initiative/monarch
2. polimento de animacao
3. persistencia visual de resultados
4. refinamento de copy

## Termos de aceite

### Aceite visual

- a mesa precisa ser identificada como clone do benchmark em comparacao lado a lado
- o jogador precisa enxergar numero, vencedor e estado especial sem procurar
- nao pode haver cheiro de `card`, `sheet`, `dashboard` ou `settings page` padrao
- eventos importantes precisam ter presenca visual suficiente para nao parecerem troca seca de estado

### Aceite de produto

- as acoes centrais da partida precisam caber na propria mesa
- o jogador nao deve sentir que "saiu da partida" para configurar ou rolar
- `High Roll` precisa ser melhor entendido do que no nosso estado atual
- o `life counter` nao pode ficar "funcional, porem sem vida"; mesa e evento precisam ser igualmente claros

### Aceite tecnico

- `flutter analyze` verde em `life_counter_screen.dart` e teste focado
- `flutter test test/features/home/life_counter_screen_test.dart` verde
- sem regressao de persistencia, undo, `High Roll`, `poison`, `tax` e `commander damage`

## Regra de decisao durante a sprint

Se houver duvida entre:

- manter a linguagem do resto do app
- ficar mais proximo do benchmark

Nesta frente, vence:

- ficar mais proximo do benchmark

Se houver duvida entre:

- preservar um widget bonito atual
- ficar mais parecido com a captura

Nesta frente, vence:

- ficar mais parecido com a captura

## Definicao de encerramento

Esta sprint so pode ser marcada como `DONE` quando:

1. a mesa principal estiver reconhecivelmente clonada
2. o `High Roll` estiver no mesmo nivel de protagonismo do benchmark
3. os estados especiais estiverem em painel cheio
4. `Settings`, `Players` e `Set Life` estiverem na mesma familia de overlay
5. a barra inferior utilitaria existir
6. nossos contadores MTG residuais estiverem encaixados nessa shell sem reintroduzir a linguagem antiga
7. motion e feedback de evento estiverem no mesmo nivel de protagonismo e clareza do benchmark

## Status Operacional Atual

- a shell da mesa ja convergiu em boa parte:
  - base `black-first`
  - quadrantes `full-bleed`
  - hub central radial
  - rail inferior
  - overlays centrados sobre a mesa
- `SET LIFE` e `DICE` ja pertencem a essa mesma familia visual
- o `SET LIFE` desta rodada saiu do frame/card e virou keypad flutuante:
  - numero branco grande
  - botoes circulares
  - `CANCEL / SET LIFE` no rodape
  - composicao alinhada a captura `13.50.32`
- o `SETTINGS` tambem convergiu melhor para o benchmark:
  - `PLAYERS` saiu dele e ficou como overlay proprio
  - presets de vida separados para `MULTI-PLAYER` e `TWO-PLAYER`
  - secoes cruas `GAME MODES` e `GAMEPLAY`
  - leitura mais de lista de mesa do que de card configuravel
- o frame compartilhado dos overlays tambem foi simplificado:
  - menos caixa central com borda
  - mais conteudo flutuando sobre a mesa
  - `DICE`, `HISTORY`, `CARD SEARCH`, `PLAYERS` e `SETTINGS` agora respiram mais como overlay de jogo do que como modal premium de app
- `KO'D!`, `COMMANDER DOWN.` e `TOXIC OUT.` ja usam takeover real de painel
- o `High Roll` e o `D20` deixaram de ser badge nesta rodada e passaram a takeover de painel:
  - numero gigante como protagonista
  - vencedor com fundo comemorativo
  - badges e controles secundarios escondidos durante o evento
- regra vigente de composicao:
  - estado normal = vida domina
  - `High Roll` / `D20` = valor do dado domina
  - estado especial = mensagem de derrota/lethal domina

## Nota final

Este documento existe porque a direcao anterior ficou aquem da meta.

Ela tentou:

- melhorar nosso `life counter`
- manter linguagem propria
- superar benchmark por refinamento

O benchmark, pelas imagens em `dddddd/`, mostrou que o ganho real dele nao esta no refinamento; esta na brutalidade de mesa, na obviedade e na falta de vergonha de transformar cada painel em um placar temporario de jogo.

A decisao desta sprint e simples:

- primeiro clonar
- depois customizar
