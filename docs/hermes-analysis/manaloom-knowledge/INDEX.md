# ManaLoom Commander Knowledge — Indice Cumulativo

> Base de conhecimento em construcao sobre Commander deckbuilding, gerada por
> analise diaria de decks reais de torneios cEDH. Serve como oraculo para
> validar se a IA do ManaLoom esta raciocinando corretamente.

## Status

| Metrica | Valor | Data |
|:--------|:-----:|:-----|
| Comandantes analisados | 5 | 2026-05-26 |
| Decks analisados | 5 | 2026-05-26 |
| Cartas revisadas | ~280 (selecao) | 2026-05-26 |
| Insights documentados | 26 | 2026-05-26 |
| Discrepancias com ManaLoom | 30 (7 novas) | 2026-05-26 |

## Comandantes Analisados

| Comandante | Decks | Ultima Analise | Insights | Tags Review |
|:-----------|:-----:|:--------------:|:--------:|:-----------:|
| Kinnan, Bonder Prodigy | 1 | 2026-05-26 | 4 | Pendente |
| Atraxa, Praetors' Voice | 1 | 2026-05-26 | 4 | Pendente |
| Yuriko, the Tiger's Shadow | 1 | 2026-05-26 | 6 | Pendente |
| Korvold, Fae-Cursed King | 1 | 2026-05-26 | 5 | Pendente |
| Teysa Karlov | 1 | 2026-05-26 | 6 | Pendente |

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
5. **Yuriko inverte a regra de CMC** — cartas de CMC alto nao sao "custosas",
   sao o motor de dano do deck. Temporal Trespass (CMC 11) e a melhor carta do
   deck, mas nunca e conjurada. A IA precisa entender que CMC alto pode ser
   vantagem, nao desvantagem.
6. **Enabler density > Card quality** — No Yuriko, ter 12 enablers de evasao
   de 1 mana e mais importante que ter cartas individuais mais fortes. A
   metrica mais importante do deck nao e CMC medio ou ramp — e quantas
   criaturas evasivas de baixo custo o deck tem.
7. **Nem toda carta precisa ser jogavel** — Yuriko e o unico deck popular onde
   a funcao primaria de algumas cartas (Temporal Trespass, Shadow of Mortality)
   e ser revelada, nao conjurada. O sistema de tags precisa capturar esta
   dualidade de proposito.
8. **Korvold e o "engine deck" de Jund** — O deck parece combo (Pitiless
   Plunderer + sac outlet), mas a metrica mais importante e a quantidade de
   "fodder" (coisas para sacrificar). Cada sacrifice fodder = 1 carta (Korvold)
   + 1 dano (Mayhem Devil) + 1 treasure (Pitiless). A qualidade de cada peca
   individual e menos importante que a densidade do triangulo aristocratas.
9. **Bracket 3 midrange super-estima ramp e subestima interacao** — O EDHREC
   avg de Korvold tem 24 cartas que aceleram mana (14 ramp puro + 8 combo) mas
   apenas 1 board wipe e 0 counterspells. Jogadores de bracket 3 confiam que
   seu motor gerara mais valor do que os oponentes podem remover.
10. **Sacrifice permanentes, nao so criaturas** — Diferente de aristocrats
    tradicionais que so sacrificam criaturas, Korvold sacrifica treasures,
    clues, foods, encantamentos (Awakening Zone), e ate terrenos. Isso torna
    o deck mais robusto contra remocao focada em criaturas.
11. **Aristocrats bracket 3 prioriza redundancia sobre protecao** — Teysa Karlov
    tem 0 counterspells, 0 cartas de protecao. Em vez de proteger pecas, o deck
    tem 3+ fontes de death trigger doubling (Teysa, Teysa Scion, Drivnod).
    Se uma peca for removida, o jogador tem outra.
12. **Ramp e subestimado em aristocrats bracket 3** — Teysa tem apenas 8 ramp
    (contra 10-15 recomendados). Confianca excessiva em Smothering Tithe como
    fonte de ramp e arriscada. Padrao confirmado: bracket 3 prefere payoff a ramp.
13. **O triangulo aristocrats e universal** — Fodder + Outlet + Payoff aparece
    em todos os 4 decks do corpus Teysa (default, aristocrats, tokens, sacrifice).
    A densidade varia, mas o triangulo sempre esta presente.

### Por Arquetipo
- **Combo (cEDH):** 24+ ramp, 15+ interaction, 0-2 board wipes,
  28-32 terrenos, 2-3 wincons, CMC medio < 2.0
- **Combo (casual):** 10-15 ramp, 8-12 removal, 3-5 board wipes,
  35-40 terrenos, CMC medio 2.5-3.5
- **Proliferate/Midrange (bracket 3):** 12 ramp, 6-8 removal, 1 board wipe,
  35-37 terrenos, CMC medio ~3.0, ~14 infect/poison sources, ~12 proliferate engines
- **Tempo/Ninja (Yuriko, bracket 3):** 6 ramp (baixo, mas aceitavel), 8-10 draw,
  10-12 enablers de evasao 1-mana, 12-17 ninjas, 35-37 terrenos (full build),
  CMC medio ~2.8 (mas ~1.8 se excluir flips), ~4 wincons de alto CMC (7-11),
  3-4 topdeck manipulation, 4 tutores
- **Sacrifice/Midrange (Korvold, bracket 3):** 14 ramp puro (+8 condicional),
  7 draw, 12 removal (incluindo payoffs como Blood Artist), 1 board wipe,
  5 tutores, 5 sac outlets, 37 terrenos (full build), CMC medio ~3.2,
  12 wincons (incrementais + combo), 6 Game Changers
- **Aristocrats/Death Triggers (Teysa, bracket 3):** 8 ramp (abaixo do ideal),
  10 draw (ok), 10 removal (7 spot + 3 board wipes), 1 tutor, 3 board wipes,
  0 protecao (redundancia > protecao), 9 sacrifice outlets (7 + 2 terrenos),
  11 fodder/tokens, 8 death payoffs, 4 recursion, 35 terrenos, ~2.9 CMC medio,
  2 Game Changers (Smothering Tithe, Bolas's Citadel)

### Psicologia do Jogador (acumulativo)
- **Jogador de infect/proliferate:** Conservador-incremental. Quer vencer por
  exaustao, nao explosao. Prefere consistencia a potencia maxima. Aceita ter
  cartas "mortas" no early game (Deepglow Skate, Vorinclex) pelo payoff massivo
  no late game. Valoriza a experiencia do jogo sobre a eficiencia de vitoria.
- **Jogador de cEDH Kinnan:** Agressivo-eficiente. Quer vencer o mais rapido
  possivel. Prefere combos compactos (2 slots) sobre redundancia (4-6 slots).
  Tolerante a risco (Mox Diamond + 29 lands). Nao se importa em perder se o
  combo falha — prefere "win fast or lose fast."
- **Jogador de Yuriko tempo:** Calculista-oportunista. Pensa em termos de
  "conexoes", nao de "cartas" — cada ataque que conecta vale 3+ recursos (dano,
  Yuriko flip, ETB do ninja). Aceita dead draws (cartas de CMC 11 que nao
  conjura) em troca de explosao de dano. Valoriza consistencia de enablers
  acima de qualidade individual das cartas. E um dos poucos jogadores que
  otimiza o topo do library mais que a mao.
- **Jogador de Korvold sacrifice/midrange:** Conservador-incremental com
  explosao de combo. Prefere "win-more" a "comeback" — cartas como Old Gnawbone
  e Bootleggers' Stash multiplicam uma posicao ja boa. Subestima interacao
  (zero counterspells, 1 board wipe). Confia que o motor de valor (Korvold +
  Pitiless + 5 sac outlets) gera mais vantagem que os oponentes podem remover.
  Pensamento chave: "Toda peca do deck serve a pelo menos 2 funcoes" — Pitiless
  e ramp + combo piece, Blood Artist e payoff + removal, Mayhem Devil e payoff
  + removal. O deck e construido para ter 0 cartas mortas, mas aceita que
  nenhuma funcao individual e maximizada.
- **Jogador de Teysa aristocrats:** Estrategista incremental — prefere vencer
  por mil cortes do que por uma explosao. Tolerancia a risco moderada: nao
  inclui combos deterministicos, mas aceita riscos calculados (sacrifice outlets
  dependentes de ter criaturas). Foco em loops de valor recursivo — o deck ganha
  consistencia quanto mais tempo o jogo dura. Pensamento chave: "O triangulo
  aristocrats e a lei" — toda carta e escolhida para preencher um dos tres papeis
  (fodder, outlet, payoff). Medo de board wipe vs confianca na recursao: tem
  3 wipes proprios mas so 4 recursao. Protecao zero e escolha consciente —
  prefere ter mais pecas do que o oponente pode remover. A inclusao de Bolas's
  Citadel revela ambicao de late game para quando o plano A (drenagem incremental)
  e lento demais.

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
- **Yuriko inverte o valor de CMC:** Temporal Trespass (CMC 11) e a melhor carta
  do deck, mas a IA classificaria como "big_spell" (negativo). No Yuriko, CMC
  alto e positivo. O sistema precisa de logica condicional por comandante.
- **Dead draw premium e exclusivo do Yuriko:** Cartas de CMC 7-11 que sao
  valiosas no topo mas inuteis na mao. Nenhum outro comandante cria este
  fenomeno. O sistema de tags nao captura "carta valiosa por nao ser jogavel."
- **Enabler density e metrica critica:** Yuriko precisa de 10+ enablers de
  evasao de 1-2 manas. Sem eles, Yuriko nao ativa e o deck nao funciona. A IA
  precisa medir "conexao funcional" (ratio enabler:deck_size) em vez de so
  contagens tradicionais.
- **Korvold + fetch lands = valor psuedo-gratis:** Cada fetch land ativa
  Korvold (compra 1 carta) e Tireless Provisioner (1 treasure). O jogador
  escolheu 13+ fetch lands nao so por correcao de mana, mas por gerar valor
  adicional de sacrificio "gratuito" — a fetch morre de qualquer jeito.
- **O triangulo aristocratas de Korvold:** Sac outlet + Fodder + Payoff = win.
  A densidade e tao alta (5 outlets, 13 payoffs, 10+ fodder) que o deck quase
  sempre tem o triangulo completo em campo. A IA precisa entender que
  redundancia de pecas e mais importante que qualidade individual.
- **Ramp inflado por combo pieces no sistema de tags:** Pitiless Plunderer e
  Phyrexian Altar sao classificados como "ramp" pelo ManaLoom, mas no contexto
  de Korvold sao primariamente combo pieces. A discrepancia entre tag e funcao
  real (como confirmado na auditoria de 2026-05-26) faz com que a IA
  superestime ramp e subestime wincons no deck.
- **Teysa Karlov: o deck aristocrats mais representativo do formato.** Com
  20,216 decks na amostra default, e o arquetipo de sacrificio mais popular.
- **Protecao zero e caracteristica do arquetipo aristocrats.** Diferente de
  outros brackets, aristocrats bracket 3 prefere redundancia a protecao. Se voce
  remover uma peca, o jogador tem outra.
- **Triangulo aristocrats universal validado em 4 decks do corpus.** Fodder +
  Outlet + Payoff aparece em todos os decks Teysa do corpus (default, aristocrats,
  tokens, sacrifice). A densidade varia, mas o triangulo sempre esta presente.
- **Teysa + Teysa Scion + Drivnod = 3 fontes de death trigger doubling.**
  O deck sobrevive a remocao do comandante. A redundancia de engine e a marca
  registrada de bracket 3 bem construido.
- **Draw condicional e aceito em aristocrats.** Teysa depende de draw que requer
  criaturas morrendo (Grim Haruspex, Midnight Reaper, Skullclamp). A confianca
  de que "sempre vai ter algo para sacrificar" e alta — mas pode ser punida por
  oponentes que fogem do jogo de criaturas.

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
| Yuriko | Sensei's Divining Top | Controle de topo para flip otimizado | Essencial (Yuriko) |
| Yuriko | Scroll Rack | Troca mao pelo topo para maximo CMC | Essencial (Yuriko) |
| Yuriko | Silver-Fur Master | Reduz ninjutsu {1} para todos os ninjas | Essencial (Yuriko) |
| Yuriko | Temporal Trespass | Flip de 11 de dano + extra turn potencial | Essencial (Yuriko) |
| Yuriko | Changeling Outcast | Melhor enabler (unblockable + changeling = ninja) | Essencial (Yuriko) |
| Yuriko | Tetsuko Umezawa | Torna todos os enablers 1/1 unblockable | Alta (Yuriko) |
| Yuriko | Ingenious Infiltrator | Compra 2 ao ninjutsu + flip de 4 | Alta (Yuriko) |
| Changeling Outcast | Cover of Darkness | Changeling = ninja -> ganha fear | Alta (Yuriko) |
| Korvold | Pitiless Plunderer | Cada sacrificio = 1 treasure + 1 draw + 1 +1/+1 | Essencial (Korvold) |
| Korvold | Viscera Seer | Sac outlet de 1 mana que scry. Ativa motor inteiro | Essencial (Korvold) |
| Korvold | Tireless Provisioner | Fetch lands viram treasures que viram cartas | Alta (Korvold) |
| Pitiless Plunderer | Chatterfang, Squirrel General | Squirrels + treasures infinitos | Essencial (Korvold) |
| Pitiless Plunderer | Blood Artist | Combo infinita = drena 3 oponentes | Essencial (Korvold) |
| Pitiless Plunderer | Reassembling Skeleton | Loop infinito (sac, volta, sac) | Alta (Korvold) |
| Underworld Breach | Lotus Petal | Loop de mana recursivo | Alta (Korvold) |
| Ashnod's Altar | Pitiless Plunderer | 2 treasures + 2 mana por criatura sacrificada | Alta (Korvold) |
| Old Gnawbone | Korvold | Ataque gera treasures que viram cartas | Media (Korvold) |
| Academy Manufactor | Pitiless Plunderer | Cada morte de criatura = 1 treasure + 1 clue + 1 food | Alta (Korvold) |
| Teysa Karlov | Teysa, Orzhov Scion | Loop completo: sacrificio -> exila -> ficha -> death triggers | Essencial (Teysa) |
| Teysa Karlov | Drivnod, Carnage Dominus | Triplica death triggers (2x + 2x nao stacka, mas da redundancia) | Alta (Teysa) |
| Teysa Karlov | Skullclamp | Equipa token 1/1, sacrifica, compra 2 | Essencial (Teysa) |
| Teysa Karlov | Dictate of Erebos | Cada sacrificio = cada oponente sacrifica 2 criaturas | Essencial (Teysa) |
| Teysa Karlov | Blood Artist | Cada morte = 2 de dano em cada oponente | Essencial (Teysa) |
| Skullclamp | Reassembling Skeleton | 2 cartas por turno para sempre | Alta (Teysa) |
| Bolas's Citadel | Blood Artist | Life gain de Blood Artist alimenta Citadel | Alta (Teysa) |
| Smothering Tithe | Mirkwood Bats | Treasures como fodder que drenam | Media (Teysa) |
| Smothering Tithe | Marionette Apprentice | Cada treasure que morre = 3 de dano (com Teysa) | Media (Teysa) |

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
| Temporal Trespass (Yuriko) | wincon | big_spell | Tag big_spell sugere fardo, mas no Yuriko e o motor de dano principal | Alto |
| Shadow of Mortality (Yuriko) | wincon | creature | Nunca e jogada como criatura — existe para ser revelada por Yuriko | Alto |
| Dark Ritual (Yuriko) | ramp | ritual | No Yuriko funciona como ramp porque o deck inteiro custa 1-2 CMC | Medio |
| Mystic Remora (Yuriko) | stax_light | draw | Tambem impede oponentes de jogar spells de baixo CMC cedo | Medio |
| Commandeer (Yuriko) | protection | removal | Funciona como protecao contra board wipes | Baixo |
| Pitiless Plunderer (Korvold) | ramp + combo_piece | ramp | Tag unica perde funcao primaria de wincon | Medio |
| Blood Artist (Korvold) | payoff | removal | Tag removal ignora que e o payoff principal do deck | Alto |
| Mayhem Devil (Korvold) | payoff + removal | removal | Dual function nao capturada | Medio |
| Underworld Breach (Korvold) | recursion + wincon | recursion | Missing wincon tag | Alto |
| Korvold, Fae-Cursed King (Korvold) | engine | draw | Sistema nao tem tag engine | Alto |
| Blood Artist (Teysa) | death_payoff_drain | removal | Tag removal perde funcao de drenagem incremento | Alto |
| Dictate of Erebos (Teysa) | stax_aristocrat | removal | Perde funcao de controle de board continuo | Alto |
| Bolas's Citadel (Teysa) | engine_wincon | other | Sistema nao detecta como wincon engine | Alto |
| Teysa Karlov (comandante) | engine (enabler) | token_maker | Sistema ve como "faz tokens" em vez de "dobra triggers" | Alto |
| Ashnod's Altar (Teysa) | sacrifice_outlet | ramp | Primariamente outlet que gera mana, nao ramp puro | Alto |
| Teysa, Orzhov Scion | sac_outlet_token_maker | removal | Dual function: outlet + token gen | Medio |
| Syr Konrad, the Grim | death_payoff_drain | removal | Drenagem passiva vs spot removal | Alto |

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
| big_spell | 50% (est.) | 2 | 2 (Temporal Trespass, Shadow of Mortality como wincon) | 0 |
| **death_payoff** | **0% (est.)** | **5** | **0** | **5 falsos - (Blood Artist, Zulaport Cutthroat, etc. viram "removal")** |
| **sac_outlet** | **50% (est.)** | **6** | **0** | **3 falsos - (Ashnod's Altar, Phyrexian Altar viram "ramp")** |

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
| Enabler density | Proporcao de cartas que permitem ativar a mecanica principal do deck (ex: 12 enablers de evasao no Yuriko) |
| Flip economy (Yuriko) | Ciclo de revelar cartas com Yuriko, causar dano = CMC, e gerar card advantage com triggers |
| Dead draw premium (Yuriko) | Cartas valiosas no topo do library para Yuriko flipar mas inuteis na mao por serem caras demais para conjurar |
| Conexao funcional | Ratio entre numero de enablers e tamanho do deck - metrica essencial para Yuriko |
| Dual purpose card (Yuriko) | Carta que serve tanto para efeito quanto como flip de dano para Yuriko |
| Aristocrat Triangle (Korvold) | Sac outlet + Fodder + Payoff = o triangulo basico de qualquer deck aristocrats |
| Treasure Storm (Korvold) | Geracao massiva de treasures em um turno (Pitiless + sac outlet + Reassembling Skeleton) |
| Combo Density (Korvold) | Numero de pecas de combo no deck. Korvold tem alta densidade porque muitas pecas servem a 2 funcoes |
| Incremental Engine (Korvold) | Motor que gera valor a cada acao (Korvold compra a cada sacrificio, nao de uma vez) |
| Dual Function Card (geral) | Carta que serve a 2 funcoes primarias (ex: Pitiless = ramp + combo_piece). O sistema de tags do ManaLoom nao captura dual function |
| Triangulo aristocrats (Teysa) | Fodder + Outlet + Payoff. As tres pernas necessarias para um deck de sacrificio funcionar. Universal. |
| Death trigger doubler (Teysa) | Carta que faz death triggers triggerarem duas vezes (Teysa Karlov, Drivnod, Roaming Throne) |
| Fodder (Teysa) | Criaturas ou fichas descartaveis que podem ser sacrificadas. Quanto mais baratas e recorrentes, melhor. |
| Drain (Teysa) | Perda de vida de oponentes combinada com ganho de vida proprio. Efeito Blood Artist. |
| Sac outlet (Teysa) | Sacrifice outlet - permanente que pode sacrificar criaturas a custo zero ou baixo. |

## Principios de Deckbuilding (extraidos das analises)

1. "Consistencia > Potencia. Um combo que funciona 90% das vezes e melhor que um que ganha na hora mas funciona 50%." (Kinnan — cEDH)
2. "Redundancia e a melhor protecao. Se voce tem 12 fontes de proliferacao, perder o comandante nao acaba com o jogo." (Atraxa)
3. "Curva de mana e rainha. Nada custa mais que 7, ramp garante bombas no turno 5-6." (Atraxa, valido para bracket 3)
4. "cEDH quebra todas as regras. 29 lands, 0 wipes, CMC < 2.0 — e correto para bracket 4." (Kinnan)
5. "Staples sao staples por um motivo. Uma carta generica forte vence uma carta tematica fraca." (Rhystic, Smothering em Atraxa)
6. "O melhor combo e o que voce consegue proteger, nao o mais forte." (Kinnan — optou por nao incluir Isochron+Dramatic)
7. "Valor por turno: avalie cartas por quanto elas produzem a cada turno em jogo, nao apenas pelo impacto inicial." (Atraxa)
8. **"A carta que voce NAO joga pode ser mais valiosa do que a que voce joga."** (Yuriko — Temporal Trespass nunca e conjurada, mas e o motor de dano principal)
9. **"Enabler density > Card quality. Ter 12 enablers de evasao de 1 mana e mais importante que ter cartas individuais mais fortes."** (Yuriko)
10. **"Consistencia de conexao > Potencia individual. Cada ataque que conecta vale 3+ recursos."** (Yuriko)
11. **"Todo slot tem custo de oportunidade — cada carta que nao acelera ou nao interage e um risco calculado."** (Korvold)
12. **"O triangulo aristocratas: Sac outlet + Fodder + Payoff = win. A densidade de cada peca e mais importante que a qualidade individual."** (Korvold)
13. **"Bracket 3 confia em motor > interacao. Prefere ter 14 ramp e 0 counters a 10 ramp e 4 counters."** (Korvold)
14. **"Dual function > Single function. Uma carta que serve a 2 propositos (Pitiless = ramp + combo) vale mais que duas cartas que fazem cada um separadamente."** (Korvold)
15. **"Nao proteja o comandante — tenha backups."** (Teysa — em vez de protecao, o deck tem 3 fontes de death trigger doubling)
16. **"Draw condicional e aceitavel se voce controla a condicao."** (Teysa — sempre pode criar uma ficha e sacrifica-la)
17. **"Board wipe proprio e autodano aceitavel."** (Teysa — criaturas geram valor na morte, entao Toxic Deluge e um buff disfarcado)
18. **"Tutor com custo de sacrificio e vantagem, nao custo."** (Teysa — Diabolic Intent e melhor que Demonic Tutor quando sacrificio e valor, nao perda)

## Ultimas Execucoes

| Data | Torneio | Decks | Status |
|:----|:--------|:-----:|:------:|
| 2026-05-26 | Jokers Are Wild Monthly 1k | Kinnan (2nd) | Analise concluida |
| 2026-05-26 | EDHREC Average Deck (41.130 decks) | Atraxa, Praetors' Voice (Default/Goodstuff) | Analise concluida |
| 2026-05-26 | EDHREC Average Deck (30.921 decks) | Yuriko, the Tiger's Shadow (Dimir Ninja Topdeck Tempo) | Analise concluida |
| 2026-05-26 | EDHREC Average Deck (19.646 decks) | Korvold, Fae-Cursed King (Jund Sacrifice Midrange) | Analise concluida |
| 2026-05-26 | EDHREC Average Deck (20.216 decks) | Teysa Karlov (Orzhov Aristocrats Death Triggers) | Analise concluida |
