# Task de Perfeicao: Life Counter

> Documento operacional criado em `2026-03-26`.
> Status: `ACTIVE`.
> Esta task complementa `docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md` e define o recorte final de refinamento para o `life counter`.

## Objetivo

Levar `app/lib/features/home/life_counter_screen.dart` do estado atual de `clone forte, mas ainda adaptado` para o estado de `clone praticamente 1:1`, com acabamento visual, geometria, motion e encaixe dos contadores MTG no mesmo idioma do benchmark.

Nao e uma task de features novas.
Nao e uma task de compatibilizacao com o resto do app.
Nao e uma task de design system global.

E uma task de:

- side-by-side fino
- geometria
- hierarquia
- motion
- takeover
- brutalidade de mesa

## Working Model

### Visual thesis

Mesa full-canvas, crua, fisica e dominante, onde cada quadrante parece uma superficie de jogo e nao um componente de app.

### Content plan

1. mesa e numero dominante
2. evento dominante (`High Roll`, `D20`, `KO'D!`, lethal)
3. hub/radial e rail como utilidade de mesa
4. overlays como camada secundaria, nunca como tela separada

### Interaction thesis

1. o jogador toca no centro da vida para entrar no estado certo sem pensar
2. eventos importantes tomam o quadrante inteiro por alguns instantes
3. overlays surgem da mesa e somem de volta para a mesa

## Veredito atual

Hoje o `life counter`:

- esta coerente
- ja e valido como direcao
- ja abandonou o layout de app/dashboard
- ja usa takeover para eventos e estados especiais

Mas ainda nao esta perfeito porque:

1. a geometria fina ainda nao esta travada
2. a rotacao nova ainda precisa de revisao optica
3. o hub central ainda esta um pouco mais polido do que cru
4. alguns overlays ainda tem cheiro de produto Flutter
5. os contadores MTG ainda soam adaptados, nao totalmente nativos da mesa clone
6. o motion ja existe, mas ainda nao tem o mesmo impacto do benchmark

## Avanco documentado em 2026-03-26

Entrou como contrato explicito desta task:

- suporte de mesa para `2p` ate `6p`
- layouts `5p/6p` desenhados para preservar um vazio central real de mesa
- hub central com comportamento adaptativo de escala/alinhamento em layouts mais densos
- overlay `PLAYERS` promovido para incluir `5` e `6` jogadores como opcao oficial, nao mais backlog

Leitura desta rodada:

- `5p/6p` nao entram como "feature lateral"
- eles passam a fazer parte da geometria final obrigatoria do clone
- o aceite da task agora depende de a mesa continuar forte mesmo na densidade `6p`
- o painel do jogador tambem passou a ter um `dense mode` proprio para `5p/6p`, reduzindo palco do numero, takeover e atalhos para que a mesa continue parecendo desenhada para densidade, nao apenas comprimida
- a adaptacao MTG em `5p/6p` tambem entrou no desenho: quando o life core abre atalhos, `poison`, `tax` e `commander damage` agora aparecem primeiro como console resumido de mesa, em vez de virar apenas uma fita longa de botoes espremidos
- os overlays residuais tambem comecaram a sair da linguagem de sheet generica: `TABLE TOOLS` foi puxado para uma lista mais seca de acoes e o `COMMANDER DAMAGE` rapido passou a usar linhas por fonte mais cruas, menos `counter row` ornamental

## Gaps restantes

### 1. Geometria da mesa

Objetivo:

- travar as proporcoes finais de `2p`, `3p` e `4p`
- revisar gutters, bordas, raios e massa dos quadrantes
- garantir que a mesa ainda pareca benchmark mesmo sem overlays abertos

Pendencias:

- revisar relacao entre largura e altura dos quadrantes em `3p`
- revisar se `compact` ainda esta comprimindo mais do que o benchmark
- revisar massa visual dos cantos arredondados
- revisar se o centro da mesa esta respirando do mesmo jeito do benchmark

Aceite:

- screenshot lado a lado passa como mesma familia visual
- nenhum quadrante parece "card"
- a mesa pode ser lida como poster antes de qualquer detalhe

### 2. Rotacao e centragem optica

Objetivo:

- sair do "matematicamente centralizado" para "opticamente correto"

Pendencias:

- validar `quarterTurns` atuais por assento
- revisar massa visual de numeros como `7`, `10`, `23`, `41`
- revisar centragem durante:
  - estado normal
  - `D20`
  - `High Roll`
  - estados especiais

Aceite:

- os numeros parecem centrados, nao apenas calculados
- nenhuma orientacao parece torta ou deslocada
- a leitura continua obvia em todos os assentos

### 3. Hub central

Objetivo:

- deixar o hub ainda mais cru e fisico

Pendencias:

- reduzir o que ainda parece "premium product UI"
- revisar escala do hexagono central versus petalas
- revisar espessura do contorno e glow
- revisar peso do bloco de ultimo evento

Aceite:

- o hub parece ferramenta de mesa, nao menu bonito
- a leitura de `PLAYERS`, `SETTINGS`, `HIGH ROLL`, `RESTART` e `HELP` e imediata
- o centro nao compete mais do que os quadrantes quando nao deveria

### 4. Overlays

Objetivo:

- fazer todos os overlays parecerem da mesma familia do benchmark

Pendencias:

- endurecer mais `DICE`
- endurecer mais `HISTORY`
- endurecer mais `CARD SEARCH`
- revisar se `PLAYERS` ainda precisa perder acabamento
- revisar `SETTINGS` para ficar ainda mais seco

Aceite:

- nenhum overlay parece modal genérico
- todos surgem como camada da mesa
- o usuario nunca sente que "saiu da partida"

### 5. Event takeovers

Objetivo:

- tornar o takeover de evento claramente dominante

Pendencias:

- aumentar ainda mais o impacto do valor em `High Roll`
- revisar tempo de permanencia visual do resultado
- revisar se `WINNER` / `TIE` ainda estao pequenos demais
- revisar se o fundo comemorativo esta forte no ponto certo

Aceite:

- o numero do roll vira protagonista temporario
- o vencedor e identificado em 1 segundo
- o empate e entendido sem texto auxiliar

### 6. Estados especiais

Objetivo:

- fechar o sistema de painel cheio para derrotas e estados terminais

Pendencias:

- revisar `KO'D!`
- revisar `COMMANDER DOWN.`
- revisar `TOXIC OUT.`
- validar se falta algum estado especial relevante dentro da linguagem do clone

Aceite:

- os estados especiais parecem takeover real
- o texto domina o quadrante
- nao parece badge, aviso ou snack visual

### 7. Encaixe final dos contadores MTG

Objetivo:

- fazer `poison`, `tax` e `commander damage` parecerem nativos desta shell

Pendencias:

- reduzir linguagem residual de `feature adaptada`
- revisar nome dos atalhos locais
- revisar o overlay rapido de `commander damage`
- revisar como `poison` e `tax` aparecem no painel sem sujar o clone

Aceite:

- os contadores extras convivem com a mesa clone sem quebrar o benchmark
- continuam rapidos
- nao reintroduzem UI de card/painel auxiliar

### 8. Motion final

Objetivo:

- deixar a tela viva no nivel certo, sem cair em enfeite

Pendencias:

- revisar duracao/easing do takeover de `High Roll`
- revisar entrada e saida dos overlays
- revisar transicao de `SET LIFE`
- revisar presenca de `KO'D!` e lethal states

Aceite:

- motion melhora leitura
- motion fica visivel em gravacao curta
- motion nao parece ornamental

## Ordem de execucao

### Fase A

1. geometria da mesa
2. centragem optica e rotacao
3. hub central

### Fase B

1. overlays
2. `DICE`
3. `HISTORY`
4. `CARD SEARCH`

### Fase C

1. `High Roll`
2. `D20`
3. `WINNER` / `TIE`
4. takeovers especiais

### Fase D

1. poison
2. tax
3. commander damage
4. polimento final da shell

### Fase E

1. motion final
2. side-by-side final com benchmark
3. freeze de aceite

## Definition of done

O `life counter` so pode ser marcado como `DONE` quando:

1. a mesa principal parecer benchmark mesmo sem legenda
2. o `High Roll` dominar os quadrantes como no benchmark
3. `SET LIFE` e `SETTINGS` parecerem overlays de mesa e nao modais
4. os estados especiais parecerem takeover real
5. a rotacao/centragem parecer correta a olho, nao so no codigo
6. os contadores MTG nao denunciarem "adaptacao em cima"
7. o resultado visual final puder ser chamado honestamente de clone e nao de interpretacao

## Proxima task operacional

Inicio recomendado desta task:

1. revisar geometria `3p/4p` e compactacao
2. revisar centragem optica dos numerais por assento
3. so depois mexer no restante

Motivo:

- esse e o ponto que mais afeta a primeira impressao da mesa
- se a base geometrica estiver errada, todo o resto fica "bonito em cima de proporcao errada"
