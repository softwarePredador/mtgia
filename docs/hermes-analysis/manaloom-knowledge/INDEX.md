# ManaLoom Commander Knowledge — Indice Cumulativo

> Base de conhecimento em construcao sobre Commander deckbuilding, gerada por
> analise diaria de decks reais de torneios cEDH. Serve como oraculo para
> validar se a IA do ManaLoom esta raciocinando corretamente.

## Status

| Metrica | Valor | Data |
|:--------|:-----:|:-----|
| Comandantes analisados | 2 | 2026-05-26 |
| Decks analisados | 2 | 2026-05-26 |
| Cartas revisadas | ~70 (selecao) | 2026-05-26 |
| Insights documentados | 8 | 2026-05-26 |
| Discrepancias com ManaLoom | 13 (8 novas) | 2026-05-26 |

## Comandantes Analisados

| Comandante | Decks | Ultima Analise | Insights | Tags Review |
|:-----------|:-----:|:--------------:|:--------:|:-----------:|
| Kinnan, Bonder Prodigy | 1 | 2026-05-26 | 4 | Pendente |
| Atraxa, Praetors' Voice | 1 | 2026-05-26 | 4 | Pendente |

## Padroes de Deckbuilding (Cumulativo)

### Regras Gerais
1. **cEDH quebra as regras casuais** — 29 terrenos, 24 ramp, 0 board wipes
   sao aceitaveis em bracket 4, mas seriam problemas em bracket 2-3.
   O ManaLoom precisa de heuristicas por bracket.
2. **EDHREC Average Deck e um oraculo confiavel** — 41.130 decks de amostra
   para Atraxa mostram um consenso robusto. Se a IA marcar um EDHREC avg deck
   como problematico, provavelmente e erro da IA, nao do deck.
3. **Decks de bracket 3 subestimam interacao** — O EDHREC avg de Atraxa tem
   apenas 1 counter (Counterspell). Jogadores de bracket 3 preferem ser
   proativos (fazer seu plano) a reativos (parar o oponente).
4. **O "engine deck" disfarcado de "tempo deck"** — Atraxa infect parece aggro
   (veneno rapido), mas e um engine que acelera gradualmente. Cada proliferacao
   e um "tick" de motor, nao uma explosao. A IA precisa distinguir entre
   wincons de acumulo e wincons de combo.

### Por Arquetipo
- **Combo (cEDH):** 24+ ramp, 15+ interaction, 0-2 board wipes,
  28-32 terrenos, 2-3 wincons, CMC medio < 2.0
- **Combo (casual):** 10-15 ramp, 8-12 removal, 3-5 board wipes,
  35-40 terrenos, CMC medio 2.5-3.5
- **Proliferate/Midrange (bracket 3):** 12 ramp, 6-8 removal, 1 board wipe,
  35-37 terrenos, CMC medio ~3.0, ~14 infect/poison sources, ~12 proliferate engines

### Psicologia do Jogador (acumulativo)
- **Jogador de infect/proliferate:** Conservador-incremental. Quer vencer por
  exaustao, nao explosao. Prefere consistencia a potencia maxima. Aceita ter
  cartas "mortas" no early game (Deepglow Skate, Vorinclex) pelo payoff massivo
  no late game. Valoriza a experiencia do jogo sobre a eficiencia de vitoria.
- **Jogador de cEDH Kinnan:** Agressivo-eficiente. Quer vencer o mais rapido
  possivel. Prefere combos compactos (2 slots) sobre redundancia (4-6 slots).
  Tolerante a risco (Mox Diamond + 29 lands). Nao se importa em perder se o
  combo falha — prefere "win fast or lose fast."

### Descobertas
- **Walking Ballista como wincon:** Habilidade de mana, nao spell.
  Nao pode ser counterada. Deve ser prioridade em decks de mana infinita.
- **Basalt Monolith + Kinnan:** Combo mais compacto que Isochron+Dramatic
  (2 slots vs 4). Menos slots de combo = mais slots de interaction.
- **Mox Diamond + 29 terrenos:** Arriscado mas funcional em cEDH.
  O risco de descartar a unica terra e aceitavel pela velocidade extra.
- **Valley Floodcaller:** Carta nova (Edge of Eternities) que entrou
  no meta cEDH. Precisa de dados atualizados no banco.
- **Infect/Poison como wincon de split-second:** Uma vez que o veneno comeca
  a proliferar, a janela de resposta do oponente e muito curta. 1-2 turnos
  com Deepglow Skate ou Contagion Engine levam o veneno de 2-3 para 10.
  A IA precisa entender que wincons de "inevitabilidade" sao diferentes de
  wincons de combo.
- **Prologue to Phyresis como starter:** A carta mais eficiente para iniciar
  o contador de veneno dos 3 oponentes por {B}. Sem o primeiro counter,
  proliferacao nao faz nada — entao esta carta e essencial no arquétipo, mas
  parece fraca para uma IA que so ve "sorcery: each opponent gets 1 poison."

## Sinergias Documentadas

| Carta A | Carta B | Tipo de Sinergia | Forca |
|:--------|:--------|:-----------------|:-----:|
| Kinnan | Basalt Monolith | Mana infinita | Essencial |
| Kinnan | Bloom Tender | Mana infinita (via Freed from the Real) | Secundaria |
| Basalt Monolith | Walking Ballista | Outlet de mana infinita | Essencial |
| Kinnan | Gaea's Cradle | Super-ramp com dorks | Alta |
| Atraxa | Deepglow Skate | Dobra todos os counters | Essencial |
| Atraxa | Contagion Engine | Proliferacao multipla sob demanda | Alta |
| Atraxa | Evolution Sage | Proliferacao por entrada de terreno | Alta |
| Atraxa | Brokers Ascendancy | +1/+1 counters em cada combate | Media |
| Atraxa | Prologue to Phyresis | Inicia contador de veneno | Essencial (infect) |
| Atraxa | Doubling Season | Dobra todos os counters de entrada | Alta |
| Doubling Season | Deepglow Skate | Exponencial de counters | Massiva |
| Vorinclex | Doubling Season | Quadruplica counters (teorico) | Massiva |
| Venerated Rotpriest | Remocao oponente | Punishe oponente por remover | Media |

## Discrepancias Acumuladas com ManaLoom

| Carta | Tag Esperada | Tag Provavel ManaLoom | Diferenca | Impacto |
|:------|:------------:|:---------------------:|:---------:|:-------:|
| Basalt Monolith | ramp + combo_piece | ramp | Tag composta ausente | AI subestima a carta |
| Fierce Guardianship | protection | removal | Classificacao de counter | Pode remover protecao |
| Gaea's Cradle | ramp (superior) | land | Perde contexto de qualidade | Subestima valor |
| Thrasios (no 99) | wincon + engine | engine | Perde contexto de outlet | Pode trocar errado |
| Blighted Agent | wincon + enabler | creature | Tag composta ausente | IA subestima importancia |
| Prologue to Phyresis | enabler | sorcery | Tag faltando | IA pode sugerir remover como "carta fraca" |
| Deepglow Skate | engine | creature | Carta cara como wincon-multiplier | IA pode marcar como "carta lenta candidata a swap" |
| Contagion Engine | engine + wincon | artifact | Perde contexto de wincon | Subestima valor estrategico |
| Tezzeret's Gambit | draw + engine | draw | Tag composta ausente | Perde que faz 2 coisas |
| Venerated Rotpriest | enabler + removal (indireto) | creature | Tag faltando de punicao | IA nao entende funcao dissuasoria |
| Ixhel, Scion of Atraxa | engine | creature | Tag engine faltando | IA subestima redundancia |
| Brokers Ascendancy | engine | enchantment | Tag engine faltando | Nao detecta como motor de counters |
| Smothering Tithe | ramp | enchantment | Tag ramp correta, mas perde contexto | Pode ser tratada como ramp comum |

## Funcional Tags: Precisao Acumulada

| Tag | Precisao | Amostras | Falsos + | Falsos - |
|:----|:--------:|:--------:|:--------:|:--------:|
| ramp | 95% (est.) | 24 | 0 | 1 (Basalt Monolith sem combo_piece) |
| draw | 100% (est.) | 5 | 0 | 0 |
| tutor | 100% (est.) | 7 | 0 | 0 |
| removal | 90% (est.) | 15 | 0 | Fierce Guardianship (e protection) |
| wincon | 90% (est.) | 2 | 0 | Ballista como wincon depende de deteccao |
| *Precisoes sao estimativas. Validacao real depende de rodar o sistema contra estes decks.* |
| engine | 60% (est.) | 6 | 0 | 4 falsos - (Ixhel, Brokers Ascendancy, Deepglow Skate, Contagion Engine nao detectados como engine) |

## Vocabulario do Dominio

| Termo | Significado |
|:------|:-----------|
| Proliferate engine | Carta que prolifera sem custo adicional (Atraxa, Evolution Sage, Flux Channeler) |
| Poison starter | Carta que da o primeiro counter de veneno (Prologue to Phyresis, Infectious Inquiry) |
| Stackable wincon | Wincon que funciona por acumulo, nao por combo unico (veneno, +1/+1 counters massivos) |
| Dissuasive enabler | Carta que pune o oponente por agir (Venerated Rotpriest) |
| EDHREC Average Deck | Lista dos cards mais estatisticamente comuns para um comandante (nao e deck completo de 100) |
| Value per turn | Mentalidade de avaliacao de cartas por quanto valor geram a cada turno em jogo |
| Engine deck | Deck que vence por acumulo de valor incremental, nao por combo ou explosao |

## Principios de Deckbuilding (extraidos das analises)

1. "Consistencia > Potencia. Um combo que funciona 90% das vezes e melhor que um que ganha na hora mas funciona 50%." (Kinnan — cEDH)
2. "Redundancia e a melhor protecao. Se voce tem 12 fontes de proliferacao, perder o comandante nao acaba com o jogo." (Atraxa)
3. "Curva de mana e rainha. Nada custa mais que 7, ramp garante bombas no turno 5-6." (Atraxa, valido para bracket 3)
4. "cEDH quebra todas as regras. 29 lands, 0 wipes, CMC < 2.0 — e correto para bracket 4." (Kinnan)
5. "Staples sao staples por um motivo. Uma carta generica forte vence uma carta tematica fraca." (Rhystic, Smothering em Atraxa)
6. "O melhor combo e o que voce consegue proteger, nao o mais forte." (Kinnan — optou por nao incluir Isochron+Dramatic)
7. "Valor por turno: avalie cartas por quanto elas produzem a cada turno em jogo, nao apenas pelo impacto inicial." (Atraxa)

## Ultimas Execucoes

| Data | Torneio | Decks | Status |
|:----|:--------|:-----:|:------:|
| 2026-05-26 | Jokers Are Wild Monthly 1k | Kinnan (2nd) | Analise concluida |
| 2026-05-26 | EDHREC Average Deck (41.130 decks) | Atraxa, Praetors' Voice (Default/Goodstuff) | Analise concluida |