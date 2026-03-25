# Sprint de Mesa: Life Counter Tabletop

> Documento superado em `2026-03-25` para a direcao visual/interacional do `life counter`.
> A direcao ativa desta frente passou a ser `docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md`.
> Este arquivo permanece como historico da fase "inspirar sem copiar".

> Documento operacional criado em `2026-03-25`.
> Objetivo: transformar o `life_counter_screen.dart` em uma ferramenta de mesa realmente superior para partidas de Commander, usando benchmark visual e de usabilidade de um app concorrente analisado por captura.

## Resumo executivo

O benchmark visual analisado em `ddddd/` mostrou um ponto importante:

- o nosso `life counter` já está melhor em organização, semântica e consistência de produto
- o app de referência ainda está melhor em **velocidade de leitura de mesa**, **feedback imediato** e **obviedade da interação**

O concorrente não vence por ser mais bonito.
Ele vence porque, durante a partida, exige menos interpretação.

Esta sprint existe para puxar tudo o que ele faz melhor, sem copiar o visual bruto dele e sem abandonar a direção minimalista do produto.

## Benchmark analisado

Referência local usada nesta sprint:

- `ddddd/WhatsApp Image 2026-03-25 at 12.13.00.jpeg`
- `ddddd/WhatsApp Image 2026-03-25 at 12.13.09.jpeg`
- `ddddd/WhatsApp Image 2026-03-25 at 12.13.21.jpeg`
- `ddddd/WhatsApp Image 2026-03-25 at 12.13.41.jpeg`
- `ddddd/WhatsApp Image 2026-03-25 at 12.13.54.jpeg`
- `ddddd/WhatsApp Image 2026-03-25 at 12.14.07.jpeg`

## O que o app de referência faz melhor

### 1. Leitura instantânea

- o número principal ocupa quase todo o painel
- os painéis são legíveis à distância
- o usuário entende o estado da mesa sem ler texto de apoio

### 2. Feedback por jogador

- resultados especiais aparecem no próprio espaço do jogador
- `KO'D`, `DECKED OUT`, `COMMANDER DOWN` e equivalentes não ficam escondidos em modal ou log
- ações locais deixam rastro local

### 3. Resultado de dado mais claro

- cada jogador mostra seu próprio valor
- o vencedor da rolagem é percebido rapidamente
- a ferramenta de `high roll` tem cara de utilidade de mesa, não de ação administrativa

### 4. Ferramentas com affordance explícita

- `HIGH ROLL`
- `PLAYERS`
- `SETTINGS`
- `RESTART`

As ações têm nome claro, posição clara e consequência visual forte.

### 5. Interface mais “física”

- o layout parece pensado para celular no centro da mesa
- a interação é menos “app com menu” e mais “painel de partida”

## O que não devemos copiar

- excesso de saturação
- visual bruto ou agressivo demais
- perda de consistência com o restante do produto
- interface caótica em telas auxiliares
- falta de semântica e organização em nome de impacto

Direção correta:

- copiar a **imediaticidade**
- não copiar a **crueza visual**

## Diagnóstico atual do nosso life counter

### Pontos já resolvidos

- hub central menos ruidoso
- `roll-off` por jogador implementado
- `D20`, `Moeda` e `1º jogador` puxados para o `Mesa Commander`
- mini hub por jogador no núcleo da vida
- `D20` individual já deixa badge local no próprio player card

### Pontos ainda abaixo do benchmark

1. `High Roll` ainda não é uma experiência de mesa forte
- existe `roll-off`
- mas ainda falta transformá-lo em ritual visual óbvio

2. estados especiais por jogador ainda são fracos
- `Morto/Reviver` existe
- mas ainda não há estados visuais fortes para:
  - morto
  - deck out
  - commander lethal
  - poison lethal

3. contadores críticos ainda estão fundos demais
- `poison`
- `commander tax`
- `commander damage`

4. o card do jogador ainda pode carregar mais sinal útil
- hoje ele mostra vida e alguns badges
- ainda falta ele virar um “painel vivo” de partida

5. o resultado global da mesa ainda depende demais de texto
- falta evidência visual distribuída pelos cards

## Lista consolidada do que vamos puxar do benchmark

### Essencial

1. `High Roll` com resultado distribuído por jogador
2. destaque visual do vencedor no próprio card
3. empate explícito e rerrolagem de empatados
4. `poison` inline
5. `commander tax` inline
6. acesso rápido a `commander damage`
7. estados explícitos de jogador derrotado

### Importante

1. `D20` individual mais visual
2. feedback local de ações especiais no próprio player card
3. affordance mais clara para ações locais
4. modo “contadores críticos” sem precisar abrir sheet
5. status de lethal por fonte mais legível

### Refino

1. presets rápidos de partida
2. histórico curto da mesa
3. visual de tool/result mais teatral
4. validação em mesa real com 4 jogadores

## Sprint proposta

### Fase 1: Ações críticas no card do jogador

Objetivo:

- fazer o jogador resolver o essencial sem modal

Escopo:

1. `poison inline` no mini hub do núcleo da vida
2. `commander tax inline` no mini hub do núcleo da vida
3. `Morto/Reviver` com estado visual mais forte no card

Status atual:

- `poison inline`: `DONE`
- `commander tax inline`: `DONE`
- `Morto/Reviver` com estado visual forte: `DONE`

Aceite:

- `poison` ajustável sem abrir sheet
- `tax` ajustável sem abrir sheet
- jogador derrotado perceptível em menos de 1 segundo
- sem poluir o card

### Fase 2: High Roll de verdade

Objetivo:

- superar o benchmark no fluxo de rolagem inicial

Escopo:

1. CTA explícito `High Roll`
2. rolar valor para todos os jogadores
3. gravar cada valor no próprio card
4. destacar o vencedor
5. destacar empatados
6. rerrolar só empatados
7. `1º jogador` derivado claramente do resultado

Status atual:

- CTA explícito `High Roll` no `Mesa Commander`: `DONE`
- rolagem distribuída pelos cards dos jogadores (`HIGH N`): `DONE`
- destaque visual de vencedor / empate no próprio card: `DONE`
- `1º jogador` derivado automaticamente quando há vencedor único: `DONE`
- rerrolagem só dos empatados: `DONE`

Aceite:

- em 1 segundo o usuário entende quem ganhou
- empate não exige interpretação manual
- resultado fica visível sem abrir tool panel

### Fase 3: Commander damage rápido

Objetivo:

- reduzir o maior gargalo restante do fluxo de Commander

Escopo:

1. entrada rápida de `commander damage`
2. leitura imediata de total por fonte
3. sinal forte de `21+ lethal`
4. fluxo menos dependente do sheet atual

Status atual:

- acesso rápido a `commander damage` pelo mini hub do núcleo da vida: `DONE`
- sheet rápida dedicada por jogador, focada só em dano por fonte: `DONE`
- badge total de `commander damage` no card continua reagindo ao fluxo rápido: `DONE`
- sinal forte de `21+ lethal`: `PARTIAL`

Aceite:

- dano de comandante entra rápido
- origem do dano continua clara
- lethal é visível

### Fase 4: Estados especiais de mesa

Objetivo:

- aproximar o card do jogador de um painel de partida

Escopo:

1. morto
2. deck out
3. poison lethal
4. commander lethal
5. talvez `commander down` quando fizer sentido no modelo

Aceite:

- os estados especiais são percebidos no card, não só deduzidos
- continuam consistentes com o tom minimalista do app

## Critérios de aceite desta sprint

### Aceite visual

- cada card do jogador continua legível à distância
- feedback novo não transforma a tela em dashboard poluído
- o minimalismo é preservado

### Aceite de produto

- ações recorrentes de mesa ficam mais curtas
- o usuário entende o que aconteceu sem ler log
- o contador se comporta mais como ferramenta de partida do que como tela administrativa

### Aceite técnico

- `flutter analyze` verde
- `life_counter_screen_test.dart` ampliado para cada novo fluxo crítico
- sem overflow em layouts de 2 e 4 jogadores

## Ordem oficial de implementação

1. `poison inline`
2. `commander tax inline`
3. `high roll` visual por jogador
4. empate/rerrolagem
5. estado visual de morto
6. commander damage rápido

## O que define encerramento

Esta sprint só termina quando:

1. o `life counter` ficar superior ao benchmark em clareza de rolagem
2. os contadores críticos saírem do modal
3. o card do jogador virar uma superfície realmente útil de mesa
4. os estados especiais estiverem perceptíveis sem leitura de log

## Veredito atual

- status: `IN_PROGRESS`
- direção: correta
- benchmark: ainda está na frente em imediaticidade de mesa
- meta da sprint: virar esse placar sem sacrificar a identidade visual do app
