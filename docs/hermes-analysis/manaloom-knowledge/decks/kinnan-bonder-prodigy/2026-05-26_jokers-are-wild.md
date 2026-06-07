# Analise: Kinnan, Bonder Prodigy

## Meta do Deck

- **Comandante:** Kinnan, Bonder Prodigy
- **Arquetipo:** Combo (infinite mana)
- **Bracket:** 4 (cEDH)
- **Fonte:** https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton
- **Data:** 2026-04-27
- **Posicao no torneio:** 2nd place
- **Jogador:** Eric Ward
- **Deck original:** https://moxfield.com/decks/sgic222q2U63nncGrJNxyg

## Resumo Estrategico

Kinnan e um dos comandantes de combo mais eficientes do cEDH. Por {2}, ele
desvira criaturas e artefatos que voce controla. O plano A e simples:

**Plano A — Mana infinita no turno 3-4:**
1. Acelerar mana com dorks e artefatos (turnos 1-2)
2. Kinnan no turno 2-3
3. Basalt Monolith (que tapa por {3}, mas nao desvira): Kinnan desvira = {3} por ativacao = mana infinita
4. Walking Ballista ou Thrasios como outlet de mana infinita

**Plano B — Protecao maxima:**
O deck joga 15+ counterspells e efeitos de protecao. Isso permite proteger
o combo mesmo com mesa aberta.

**Plano C — Value grinder:**
Se o combo falha, Kinnan gera value ao longo do tempo desvirando dorks
toda vez que ele ataca, gerando mana incremental.

Particularidade do deck: nao joga Isochron Scepter + Dramatic Reversal
(o combo classico de Kinnan). Em vez disso, usa Basalt Monolith como
peca principal de mana infinita — e mais compacto (2 slots vs 4).

## Distribuicao Funcional

| Funcao | Qtd | % | Ideal Commander | Notas |
|:-------|:---:|:-:|:---------------:|:------|
| Terrenos | 29 | - | 35-40 | **Baixo para Commander comum, mas normal para cEDH** |
| Ramp | 24 | 34% | 10-15 | **Muito acima do normal** — cEDH acelera agressivamente |
| Draw | 5 | 7% | 8-12 | Abaixo do normal — compensado por tutores que buscam o que precisa |
| Tutores | 7 | 10% | 0-5 | Alto — cEDH precisa de consistencia |
| Removal | 15 | 21% | 8-12 | Inclui 15 counterspells (protecao do combo) |
| Board Wipes | 0 | 0% | 3-5 | **Zero** — cEDH nao usa board wipes (mata o proprio combo) |
| Protecao | 4 | 6% | 3-5 | Os counters mais eficientes dobram como protecao |
| Recursao | 0 | 0% | 2-5 | Nao precisa — se o combo falha, o deck perde |
| Wincons | 2 | 3% | 1-3 | Walking Ballista + Thrasios |
| Engine | 2 | 3% | 1-2 | Kinnan (comandante) + The One Ring |

### Diferencas criticas vs Commander casual

Este deck cEDH quebra varias "regras" de deckbuilding casual:
- **29 terrenos** vs 35-40 recomendados — mas tem 24 ramp, entao funciona
- **0 board wipes** — em cEDH voce nao limpa mesa, voce protege seu combo
- **Zero recursion** — deck all-in no combo, sem plano B gradual
- **CMC medio extremamente baixo** — quase tudo custa 0-2

**Insight:** As heuristicas de deckbuilding do ManaLoom (que usam referencias
casual/competitive mid) vao marcar este deck como "deficit de terrenos" e
"falta board wipes". Mas para cEDH, isso e **correto** — o deck e otimizado
para um meta diferente. O sistema precisa entender o contexto de bracket/poder.

## Analise Carta a Carta (Selecao)

### Pecas de Mana Infinita (Core do Combo)

#### Basalt Monolith — Ramp / Combo Piece
- **Tag ManaLoom esperada:** ramp
- **Por que esta aqui:** A peca central de mana infinita com Kinnan.
  Tapa por {3}. O mana nao desvira sozinho (diferente de Grim Monolith).
  Kinnan desvira = {3} por ativacao. Com Kinnan em jogo, voce gasta {3}
  para ativar, ele desvira, voce tem {3} de volta = infinito.
- **Sinergia com comandante:** A razao do deck existir. Kinnan foi feito
  para esta carta.
- **Alternativas comuns:** Grim Monolith (segunda copia, mas com summoning
  sickness). Muitos decks Kinnan tambeem jogam Isochron+Dramatic como
  segundo combo, mas este deck optou por nao incluir.
- **Tag ManaLoom correta?** Ramp sim, mas devia ter tag extra `combo_piece`.
  O sistema atual nao marca Basalt Monolith como combo piece porque
  a deteccao e baseada em `oracle_text` — e o texto do Monolith nao
  menciona combo.

#### Walking Ballista — Wincon
- **Tag ManaLoom esperada:** wincon
- **Por que esta aqui:** O outlet de mana infinita mais eficiente.
  Com mana infinita, Walking Ballista mata todos os oponentes instantaneamente.
  Nao pode ser interrompido com a prioridade correta.
- **Alternativas:** Heliod, Sun-Crowned (precisa de vida), Hangarback Walker
  (mais lento). Ballista e o melhor porque a habilidade de remover +1/+1
  counters e uma habilidade de mana, nao uma spell — nao pode ser countered.
- **Tag ManaLoom:** Esperado `wincon`. O sistema provavelmente marca
  corretamente (texto de dano a qualquer alvo com +1/+1 counters).

#### Thrasios, Triton Hero — Wincon Alternativo / Engine
- **Tag ManaLoom esperada:** wincon + engine
- **Por que esta aqui:** Com mana infinita, Thrasios compra o deck inteiro.
  Voce coloca todos os terrenos em jogo, encontra Walking Ballista,
  e mata. Funciona tambem como value engine sem combo (gasta mana
  excedente pra comprar).
- **Nota:** Thrasios esta no 99, nao e parceiro. Interessante que o deck
  tem um comandante parceiro viavel no 99.
- **Tag ManaLoom:** `engine` parece correto como tag primaria, `wincon`
  como secundaria. O sistema detecta `wincon`?

#### Freed from the Real — Combo Piece Alternativo
- **Tag ManaLoom esperada:** combo_piece
- **Por que esta aqui:** Segundo combo. Coloca em Bloom Tender
  (que tapa por UG), Freed gera mana infinita.
- **Nota:** So funciona com Bloom Tender (que tapa por UG), nao com
  dorks de 1 so mana. E menos eficiente que Basalt Monolith.
- **Tag ManaLoom:** O sistema tem `combo_piece` como tag valida. Essa
  carta provavelmente seria detectada como `enchantment_synergy` ou
  `combo_piece`. Precisamos verificar.

#### Valley Floodcaller — Flash Enabler / Combo Facilitator
- **Tag ManaLoom esperada:** enabler
- **Por que esta aqui:** Da flash para criaturas e desvira criaturas
  quando voce conjura uma spell nao-creature. Isso permite:
  1. Kinnan desvirar no turno do oponente
  2. Combos instantaneos em resposta a remocao
  E uma carta do Edge of Eternities (colecao nova) que entrou
  no meta cEDH recentemente.
- **Insight:** Carta muito nova. Se o ManaLoom nao tiver dados
  atualizados, pode classificar errado.

### Ramp (Aceleracao)

#### Chrome Mox — Ramp
- **Tag:** ramp
- **Por que:** Mana gratis no turno 1 em troca de imprimir uma carta.
  Essencial em cEDH. O deck pode "imprimir" cartas que nao serve
  naquela partida (lands extras, etc.).
- **Tag ManaLoom:** `ramp` — correto. Mas o sistema diferencia
  Chrome Mox de mana dorks? Ambos sao ramp, mas Chrome Mox e
  descartavel (uma vez) enquanto dorks sao recorrentes.

#### Mox Diamond — Ramp
- **Tag:** ramp
- **Por que:** Similar ao Chrome Mox, mas descarta TERRA. Em um deck
  com so 29 terrenos, isso e arriscado — mas em partidas curtas de
  cEDH, voce nao precisa de muitos terrenos.
- **Nota:** Curioso que o deck joga Mox Diamond com 29 lands. Isso
  significa que em algumas maos, Mox Diamond e um "mulligan ou jogo
  arriscado". Em cEDH, isso e aceitavel.
- **Insight:** Se o ManaLoom analisar a consistencia da mana base,
  ele pode marcar isso como "instavel". E de fato e — mas e intencional.

#### Gaea's Cradle — Ramp (Lendario)
- **Tag:** ramp / land
- **Por que:** Com Kinnan + dorks, voce tem 2-3 criaturas cedo.
  Gaea's Cradle tapa por GG ou mais. E a melhor fonte de mana do deck.
- **Nota:** Custa $1000+. O deck tem versao "orcamento zero".
- **Tag ManaLoom:** `land` — correto, mas o sistema perde o contexto
  de que esta terra e muito melhor que uma terra comum.

### Draw / Card Advantage

#### The One Ring — Draw / Engine
- **Tag:** draw / engine
- **Por que:** A melhor fonte de card advantage do Commander.
  Protecao + compra 1 por turno. Em cEDH, o "burden" de 1 de dano
  por contador e irrelevante — o jogo acaba em 3-4 turnos.
- **Tag ManaLoom:** `draw` + `engine` — correto. O sistema
  provavelmente marca corretamente.

#### Rhystic Study — Draw
- **Tag:** draw
- **Por que:** Classico do Commander. Cada spell do oponente =
  potencial compra. Em cEDH, as vezes os oponentes pagam {1},
  mas mesmo assim gera valor.
- **Tag ManaLoom:** `draw` — correto.

### Interaction / Protecao

#### Force of Will — Counterspell / Protection
- **Tag:** removal / protection
- **Por que:** Counter gratis (imprintando uma blue card).
  Essencial em cEDH para proteger combo ou parar combo adversario.
- **Tag ManaLoom:** `removal` — correto. Mas devia ser `protection`
  tambem? O sistema classifica counters como `removal` atualmente.

#### Fierce Guardianship — Protection
- **Tag:** protection
- **Por que:** Counter gratis se voce controla seu comandante.
  No Kinnan, isso e quase sempre verdade. E o melhor counter
  de protecao do formato.
- **Tag ManaLoom:** Esperado `protection` — mas o sistema atual
  provavelmente classifica como `removal` (counter target spell).
  **Possivel discrepancia.**

### Tutores

#### Chord of Calling — Tutor
- **Tag:** tutor
- **Por que:** Tutor instantaneo por criatura. Com Kinnan gerando
  mana, pode buscar Walking Ballista, Thrasios, Bloom Tender,
  ou Valley Floodcaller. O Convoke permite pagar com criaturas.
- **Tag ManaLoom:** `tutor` — correto.

#### Finale of Devastation — Tutor / Wincon
- **Tag:** tutor / wincon
- **Por que:** Tutor de criatura que, com X >= 10, da +X/+X e
  haste para todas as criaturas. Com mana infinita, X = infinito.
- **Insight:** Carta de dupla funcao — tutor cedo, wincon tarde.
  O sistema precisa de tags compostas ou prioridade.

### Pecas de Protecao contra Graveyard / Combo

#### Endurance — Protecao / Recursao Reativa
- **Tag:** protection / graveyard_synergy
- **Por que:** Flash, 3/4, e quando entra, embaralha qualquer
  numero de cards de GYs nos libraries. Usado para:
  1. Parar combos de GY do oponente (Breach, etc.)
  2. Proteger seu proprio GY de exilio
  3. Reciclar cartas (embaralha e compra de novo)
- **Tag ManaLoom:** O sistema tem `graveyard_synergy`. Endurance
  seria melhor classificado como `protection` (hate piece).

## Padroes Identificados

### Novos (descobertos nesta analise)

- [X] **Kinnan combo sem Isochron-Dramatic** — versao compacta com
  Basalt Monolith como peca unica. Menos slots, mais vulneravel
  a remocao de artefatos.
- [X] **29 terrenos e funcional em cEDH** — a regra de 35-40 terrenos
  e para Commander casual. cEDH funciona com 28-32 devido a
  ramp massivo e curvas de mana baixissimas.
- [X] **0 board wipes e correto em cEDH** — board wipes matam seu
  proprio board e atrasam seu combo. Em cEDH, voce protege,
  nao limpa.
- [X] **Valley Floodcaller (Edge of Eternities)** — carta nova
  que entrou no meta. O ManaLoom precisa ter dados atualizados
  para classificar corretamente.
- [X] **Walking Ballista como wincon preferido** — por ser habilidade
  de mana (nao spell), nao pode ser counterada.

### Confirmados (ja conhecidos, validados)

- [X] cEDH roda muito mais ramp que casual (24 vs 10-15)
- [X] cEDH roda muito mais interaction (15 counters vs 8-12 removal)
- [X] cEDH nao roda recursion (deck all-in no combo)

## Discrepancias com ManaLoom (Hipoteticas — precisam ser verificadas)

| Carta | Tag Esperada | Tag Provavel ManaLoom | Diferenca | Impacto |
|:------|:------------:|:---------------------:|:---------:|:-------:|
| Basalt Monolith | ramp + combo_piece | ramp | `combo_piece` ausente | AI pode nao entender que esta carta e o coracao do combo |
| Fierce Guardianship | protection | removal | Classificacao como removal em vez de protecao especifica | Swap AI pode REMOVER protecao achando que e removal extra |
| Walking Ballista | wincon | ? | Precisa verificar se o sistema detecta como wincon | Se nao detectar, AI pode sugerir remover |
| Gaea's Cradle | ramp (superior) | land | Perde o contexto de ser a melhor terra do deck | AI pode subestimar o valor |
| Thrasios (no 99) | wincon | engine | Pode ser classificado so como engine, perdendo o contexto de outlet de mana infinita | AI pode trocar por outro engine "melhor" |

## Descobertas / Insights

1. **cEDH e um formato diferente, nao um Commander "melhorado".** As regras
   de deckbuilding sao diferentes, nao apenas mais otimizadas. Um deck
   cEDH quebra metricas que o ManaLoom considera "ideais".

2. **A classificacao functional tag do ManaLoom e linear** — cada carta
   recebe UMA tag primaria. Mas cartas de combo sao inerentemente
   duais. Basalt Monolith e ramp + combo_piece. Walking Ballista e
   wincon + creature. O sistema precisa suportar tags multiplas
   com peso.

3. **Cartas novas (Edge of Eternities) sao um ponto cego.** Valley
   Floodcaller so existe ha algumas semanas. Se o sistema usa dados
   estaticos de `oracle_text` para classificar, cartas novas podem
   cair na classificacao generica.

4. **A mana base de 29 terrenos parece inconsistente, mas e intencional.**
   Isso significa que o ManaLoom precisa de uma metrica de "consistencia
   esperada baseada em bracket" — nao a mesma para bracket 2 e bracket 4.

## Perguntas em Aberto

1. O sistema atual de functional tags do ManaLoom consegue detectar
   que Basalt Monolith + Kinnan formam um combo? Ou ele ve as duas
   cartas isoladamente?
2. Se um deck cEDH for analisado pelo ManaLoom, ele vai marcar
   "falta board wipes" e "terrenos insuficientes"? Esses alertas
   seriam falsos para cEDH.
3. O ManaLoom diferencia decks por bracket ao aplicar as heuristicas
   de qualidade? Ou as mesmas regras valem para bracket 2 e bracket 4?
4. Como o sistema trata parceiros (ex: Rograkh + Silas Renn)?
   O deck #3 do mesmo torneio tem 2 comandantes — o pipeline consegue
   validar a identidade de cor combinada?

## Verificacao de Qualidade

- [X] Cada carta principal tem papel funcional identificado
- [X] Insight novo documentado: cEDH quebra regras de deckbuilding casual
- [X] Discrepancias com ManaLoom registradas (hipoteticamente)
- [X] INDEX.md precisa ser atualizado
- [X] Heuristicas de analise seguidas