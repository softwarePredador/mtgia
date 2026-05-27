<<<<<<< HEAD
# Validator Log — Lorehold

## [2026-05-27 03:01:16 UTC] Execucao #1

### Contagem de Cartas
- Total cartas (qty): 100
- Status: ✅ 100 cartas

### Checagem de Regras
- Singleton (duplicates): ✅ OK
- Commander presente: ✅ Lorehold, the Historian

### Metricas do Deck vs EDHREC Profile

| Metrica         | Deck | EDHREC (min-max) | Status |
|-----------------|------|------------------|--------|
| Draw            |    8 | 8-12 | ✅ OK |
| Recursion       |    5 | 2-5 | ✅ OK |
| Lands           |   34 | 36-38 | 🟡 ALERTA (+2) |
| Ramp            |   17 | 10-13 | 🟡 ALERTA (-4) |
| Spot Removal    |    7 | 4-6 | 🟡 ALERTA (-1) |
| Board Wipes     |    6 | 3-5 | 🟡 ALERTA (-1) |
| Protection      |    7 | 3-5 | 🟡 ALERTA (-2) |
| Wincons         |    3 | 4-7 | 🟡 ALERTA (+1) |

### CMC Medio
- avg_cmc: 3.98
- Status: ✅ (dentro do esperado para Lorehold big spells)

### Resumo de Alertas
- 🟡 ALERTA: Lands = 34 (EDHREC: 36-38)
- 🟡 ALERTA: Ramp = 17 (EDHREC: 10-13)
- 🟡 ALERTA: Spot Removal = 7 (EDHREC: 4-6)
- 🟡 ALERTA: Board Wipes = 6 (EDHREC: 3-5)
- 🟡 ALERTA: Protection = 7 (EDHREC: 3-5)
- 🟡 ALERTA: Wincons = 3 (EDHREC: 4-7)

Total: 6 metricas fora do range.
=======
# Análise do Deck Lorehold — 2026-05-28

## Seção 1: Visão Geral

| Métrica | Seu Deck | Lorehold Ideal (EDHREC, 4 fontes) | Status |
|:--------|:--------:|:----------------------------------:|:------:|
| Terrenos | 35 | 36-38 | 🟡 1 abaixo do mínimo |
| Ramp (rocks/treasures) | 15 | 10-13 | 🟡 2 acima do máximo |
| Draw/Rummage/Draw em turno oponente | 8 | 8-12 | ✅ OK (no mínimo) |
| Spot Interaction | 7 | 4-6 | 🟡 1 acima (aceitável) |
| Board Wipes/Resets | 4 | 3-5 | ✅ OK |
| Proteção | 7 | 3-5 | 🟡 acima (ver seção 3) |
| Topdeck/Miracle Setup | 12 | 6-9 | 🟡 bem acima |
| Spell Payoffs/Copy Engines | 8 | 5-8 | ✅ OK (no máximo) |
| Gy Recursion | 0 | 2-5 | 🔴 GAP CRÍTICO |
| Win Conditions Dedicadas | 4 | 4-7 | ✅ OK |
| CMC Médio | 3.96 | ~3.5 (estimado) | 🟡 alto |

**Resumo:** Seu deck é construído em torno de **value engine massivo** (topdeck manipulation + copy effects), com ramp acima da média Boros e draw no mínimo aceitável. O gap mais crítico é **recursão de cemitério zero** — você não tem como reciclar as spells do GY depois que Lorehold copiou, o que diminui o valor de longo prazo.

O CMC médio de 3.96 é alto mesmo para Lorehold, o que explica porque você tem mais ramp que a média — precisa dela para casts os haymakers de 7-12 manas.

---

## Seção 2: Cartas que Brilham no Lorehold

### 🌟 Nível 1: Sinergia Máxima (peças centrais do plano)

**1. Sunbird's Invocation (CMC 6)**
A carta mais subestimada do deck. Lorehold copia do GY; Sunbird's Invocation copia do topo. Juntas criam uma cascata: casta uma spell → Sunbird's Invocation te dá uma spell grátis do topo → essa spell vai pro GY → Lorehold copia ela. **Uma spell = três casts.** Isso é o power ceiling do deck.

**2. Double Vision (CMC 5) + Artist's Talent (CMC 2)**
Double Vision duplica o primeiro instant/sorcery de cada turno. Artist's Talent no nível 3 duplica cada instant/sorcery. Com Lorehold no campo, isso vira **triple-cast** — e se Sunbird's Invocation também estiver ativa, **quadruple-cast**. O deck inteiro gira em torno de ter essas duas no campo simultaneamente.

**3. Scroll Rack (CMC 2) + Sensei's Divining Top (CMC 1)**
O melhor pacote de topdeck manipulation do jogo. Lorehold quer ver a carta certa no topo; essas duas cartas garantem que você sempre tenha algo bom. Scroll Rack também reembaralha lands mortas no late game para transformá-las em haymakers.

**4. Mizzix's Mastery (CMC 4 overload 6)**
Overloaded Mizzix's Mastery com Lorehold no campo = você exila TODOS os GYs, casta todas as instants/sorceries, e Lorehold duplica cada uma. É o "i win" button do deck. A única limitação é que requer um GY cheio — daí a importância de ter mais loot/rummage.

**5. Rite of the Dragoncaller (CMC 6)**
Toda instant/sorcery que você casta (incluindo as copiadas por Lorehold) gera um token de Dragon 5/5 com flying. Com Lorehold copiando, você essencialmente dobra a produção de tokens. Arcane Bombardment na coleção tornaria isso ainda mais absurdo.

### ⭐ Nível 2: Alto Valor

**6. Smothering Tithe (CMC 4)** — Cada oponente que compra te dá um Treasure. Você está em Boros (pior cor para card advantage), e isso transforma draws deles em mana sua. É ramp, é card advantage, é o melhor staple de ramp do deck.

**7. Ancient Copper Dragon (CMC 6)** — Ataca, gera 1d20 treasures. O alto CMC do deck significa que treasures maleáveis são melhores que rocks fixos — você pode explodir 20 manas em Storm Herd ou Approach no mesmo turno.

**8. Volcanic Vision (CMC 7)** — Board wipe + recursão. Mata quase tudo e devolve uma instant/sorcery do GY pra mão. É sua melhor forma de recursão atual (a única).

### 🎖️ Nível 3: Boa Suporte

**9. Jeska's Will (CMC 3)** — Ramp explosivo + card advantage. Exila 3 do topo, pode castá-las até o fim do turno. Com Lorehold, se alguma for instant/sorcery, você copia duas vezes.

**10. Monument to Endurance (CMC 3)** — Quando você descarta (Reforge, Unexpected Windfall, Olórin's), pode comprar, criar um treasure, ou dar 3 de dano. Excelente em deck que descarta bastante.

**11. Archaeomancer's Map (CMC 3)** — Se um oponente joga mais terrenos que você, você pega 1 (ou 2) básicas. Em bracket 3 com ramp verde, isso é consistente. Também compra quando ataca.

---

## Seção 3: Cartas Questionáveis

### 🔴 Nível 1: Corte Recomendado (custo de oportunidade alto)

**1. Bender's Waterskin (CMC 3)** — Tapar 3 criaturas para fazer 1 Treasure é uma troca terrível. Você pode não ter 3 criaturas relevantes no campo, e mesmo se tiver, 1 treasure por turno é irrelevante. **Nenhuma das 3 referências EDHREC usa.** Substitua por qualquer outro ramp (Boros Signet, Fellwar Stone, Ornithopter of Paradise — todos na coleção).

**2. Deflecting Palm (CMC 2)** — Redireciona dano de uma fonte para o oponente. É situacionalíssimo — só funciona se alguém te atacar com uma criatura grande ou usar um burn spell direcionado. Contra combo (que é o comum em bracket 3), não faz nada. **Nenhuma referência EDHREC usa.** Substitua por Faithless Looting ou Thrill of Possibility (draw + fill GY).

**3. Galadriel's Dismissal (CMC 1)** — Proteção temporária de criaturas que pode ser situacional. Tem usos (flicker suas criaturas para salvar de board wipe, ou remover blockers), mas em Boros com Lorehold, há opções melhores de proteção. Substitua por Flawless Maneuver (na coleção) ou Giver of Runes.

**4. Longshot, Rebel Bowman (CMC 4)** — 3/3 que dá 1 de dano no ataque. Em um deck de big spells e copy engines, esta carta é filler puro. Não escala, não sinergiza com Lorehold (não é instant/sorcery). É uma das wincons declaradas (4 total) mas não ganha o jogo. **Apenas 1/3 referências EDHREC tem.** Substituir por Arcane Bombardment (na coleção) — que é uma wincon de verdade.

### 🟡 Nível 2: Baixa Prioridade (mantenha se gostar, mas há opções melhores)

**5. Season of the Bold (CMC 5)** — Modal: 5 de dano, 5 de vida, ou 5 treasures. Ter flexibilidade é bom, mas o custo é alto para efeitos moderados. 5 treasures é o melhor modo, mas Brass's Bounty (7 manas) dá muito mais. **Nenhuma referência EDHREC tem.** Mantenha se curte a flexibilidade, mas considere cortar se precisar de espaço.

**6. Taunt from the Rampart (CMC 5)** — Força criaturas a atacar. Em bracket 3, isso pode quebrar board stalls, mas é situacional demais. **Apenas 1 de 3 referências EDHREC tem.** Mantenha se sua mesa costuma travar com boards cheios.

### 🔵 Nível 3: Fino, Mas Com Ressonância

**7. Goldspan Dragon (CMC 5)** — Excelente carta individualmente, mas 5 mana para um 4/4 que gera treasures não é o que Lorehold quer fazer. O deck quer castar big spells copiados, não criaturas. Dito isso, treasures com haste são MUITO bons, e Goldspan pode ser um enabler para um big turn com Hellkite Tyrant. **Nenhuma referência EDHREC usa (surpreendente, mas confirmado).** Manteria pelo valor de mana, mas como 15ª fonte de ramp, é um luxo.

**8. Hellkite Tyrant (CMC 6)** — Wincon condicional (20 artifacts). Você tem Smothering Tithe + Ancient Copper Dragon + Goldspan Dragon = potencial de 20 artifacts rápido. Mas é frágil — se removerem antes do trigger de início de combate, você perde um turno. Mantenha, mas saiba que é frágil.

**9. Kor Haven (land)** — Land utility boa, mas em 2 cores com 35 lands, você não pode dar-se ao luxo de ter muitas lands que entram tapped ou não produzem mana colorida consistentemente. Considere substituir por Temple of Triumph (scry) ou Sun-Blessed Peak.

**10. Orim's Chant (CMC 1)** — Impede oponentes de castar no seu turno. Bom em cEDH, questionável em bracket 3. É um effecto mais fraco que Silence ou Grand Abolisher (que você já tem). Mantenha se a mesa tem muito instant-speed interaction.

---

## Seção 4: O Que Outros Decks de Lorehold Fazem Diferente

### Gap 1: Sua maior força é sua maior fraqueza

Seu deck tem **12 cartas de topdeck/miracle setup** vs 6-9 do EDHREC. Isso é **o dobro da média**. É intencional — você quer controle absoluto do topo para Lorehold + Sunbird's Invocation. Mas cada carta de setup é um slot que não é draw, ramp, ou interação.

**Consequência:** Você tem 0 cartas de recursão. Enquanto 2 dos 3 decks EDHREC de referência têm Sevinne's Reclamation, Underworld Breach, ou Goblin Welder, você não tem nenhuma. Assim que suas spells vão pro GY (se Lorehold copiou ou não), elas não voltam.

**Sugestão:** Troque 1-2 cartas de setup (Penance, Taunt, Victory Chimes) por recursão (Arcane Bombardment, Radiant Scrollwielder, Faithless Looting).

### Gap 2: Stax Package

O deck EDHREC de referência (Deck 1) tem stax: Archon of Emeria, Drannith Magistrate, Ethersworn Canonist, Cursed Totem — essas cartas *fecham* o jogo em Boros. Seu deck tem Grand Abolisher (proteção) mas não tem stax pieces que atrapalhem oponentes.

Isso é uma escolha de estilo. O deck EDHREC é mais **control/stax**; o seu é mais **big spells value**. Ambos são válidos, mas o stax protege seu plano de jogo naturalmente.

### Gap 3: Você tem mais ramp que a média

15 ramp (acima do intervalo de 10-13). Isso é compreensível porque seu CMC médio é 3.96. Mas você poderia cortar 2 ramp pieces para colocar lands (subir de 35 para 37) e recorrer a cartas de draw que também rampeiam (Big Score, Unexpected Windfall já tem).

### Gap 4: Menos wincons que a média (4 vs 4-7)

Você está no mínimo do intervalo. Suas wincons são:
- Approach of the Second Sun (wincon de turno)
- Hellkite Tyrant (condicional, 20 artifacts)
- Insurrection (wincon de mesa)
- Storm Herd (wincon de mesa)

O deck EDHREC tem wincons como Aetherflux Reservoir, Twinflame (com Dualcaster), e combos infinitos. Você optou por wincons de battle cruiser — o que é ok para bracket 3, mas saber que você está no limite mínimo é importante.

### Gap 5: O que a coleção oferece que você não usa

| Carta | Tag | Por que incluir |
|:------|:---:|:----------------|
| **Arcane Bombardment** | recursion | A melhor engine de copy do jogo — toda instant/sorcery que você casta, exila para castar de novo em upkeep. Com Lorehold, é absurdamente forte |
| **Farewell** | board_wipe | O melhor board wipe do jogo. Exila tudo que você escolher — com Lorehold, você pode recarregar do GY |
| **Mana Geyser** | ramp | Se 3 oponentes tiverem 4 lands cada = 12 manas vermelhas. Para umbrella de big spells, é melhor que vários rocks |
| **Dualcaster Mage** | spellslinger | Copia qualquer instant/sorcery. Com Twinflame (na coleção) forma combo infinito. Sozinho é bom com Lorehold |
| **Trouble in Pairs** | draw | Cada oponente que faz algo de vantagem te dá draw. Em multi-player bracket 3, isso é consistentemente 2-3 cartas por ciclo |
| **The One Ring** | draw | 4 mana, protection, e draw consistente. Feito sob medida para decks que precisam de card advantage em Boros |
| **Faithless Looting** | recursion/loot | Custa 1 mana, compra 2, descarta 2 — enche o GY para Lorehold copiar. Com flashback, faz de novo |
| **Invoke Calamity** | recursion | Casta instants/sorceries do GY por 5 mana. Lorehold duplica. Duas spells copiadas do GY por 5 manas |

---

## Seção 5: Swap Recommendations (Prioritárias)

### Prioridade Alta (melhoria imediata):

1. **❌ Bender's Waterskin → ✅ Boros Signet ou Fellwar Stone**
   - Mesma função (ramp), execução muito melhor. Boros Signet rampa fixo em 2, Fellwar Stone é praticamente Sol Ring em multi-player.

2. **❌ Deflecting Palm → ✅ Faithless Looting**
   - Troca uma carta situacional por card advantage + fill de GY. Faithless Looting prepara o GY para Lorehold + Mizzix's Mastery.

3. **❌ Season of the Bold → ✅ Arcane Bombardment**
   - Troca flexibilidade moderada por engine de repetição. Arcane Bombardment é o que o deck quer fazer.

### Prioridade Média:

4. **❌ Longshot, Rebel Bowman → ✅ Trouble in Pairs ou The One Ring**
   - Troca filler por card advantage real. O deck precisa de draw consistente, não de uma criatura 3/3 que pinga.

5. **❌ Galadriel's Dismissal → ✅ Flawless Maneuver**
   - Flawless Maneuver é proteção free (se você tiver seu commander). Galadriel's Dismissal é situacional.

### Prioridade Baixa:

6. **❌ Kor Haven → ✅ Sun-Blessed Peak**
   - Sun-Blessed Peak é uma mountain/plains que também pode dar scry. 35 lands é apertado — não pode ter lands que não produzem mana colorida sem bounce.

7. **Considerar +2 lands (subir para 37):** Cortar Victory Chimes ou Taunt from the Rampart por Path of Ancestry e Temple of Triumph.

---

## Seção 6: Resumo de Qualidade dos Dados

### Recontagem de Cartas
- **SQLite:** 86 registros em deck_cards, mas destes 34 são lands (1x cada, sem contar básicas múltiplas)
- **Total real:** 100 cartas (1 commander + 99 main deck)
- **Commander:** Lorehold, the Historian contado 1x
- **Básicas:** 8x Mountain + 8x Plains = 16 cartas (representadas como 2 registros)

### Classificação (Multi-Tag)
- **206 entradas em card_tags** para 86 cartas (~2.4 tags por carta em média)
- **Cartas sem tag primária:** Longshot (payoff), Deflecting Palm (big_spell?), Orim's Chant (protection)

### Distribuição Real vs DB
| Métrica | Declarado (DB) | Recontado | Match? |
|:--------|:--------------:|:---------:|:------:|
| Total Lands | 35 | 34 + 1 MDFC (Valakut/Emeria's) = 35 | ✅ |
| Ramp Count | 15 | 15 contando fetch lands como ramp multi-tag | ✅ |
| Draw Count | 8 | 8 | ✅ |
| Board Wipe | 4 | 4 (Austere Command, Fated Clash, Call Forth, Volcanic Vision) | ✅ |
| Protection | 7 | 7 | ✅ |
| Wincon | 4 | 4 (Approach, Hellkite, Insurrection, Storm Herd) | ✅ |

---

## Seção 7: Aprendizados e Descobertas

### Novo: Lorehold tem 3 arquétipos distintos

1. **Stax/Combo** (EDHREC Deck 1) — Archon of Emeria, Drannith Magistrate, Underworld Breach + Grinding Station, Karn + Lattice. Foco em travar a mesa enquanto monta combo.
2. **Big Spells Value** (EDHREC Deck 2) — Double Vision, Galvanoth, Arcane Bombardment, Worldfire. Foco em copiar spells enormes. **Este é o arquétipo mais próximo do seu deck.**
3. **Chaos/Haymakers** (EDHREC Deck 3) — Goblin Game, Prisoner's Dilemma, Master Warcraft. Foco em efeitos caóticos e imprevisíveis.

Seu deck está entre o arquétipo 2 e 3 — tem os big spells (Storm Herd, Insurrection, Approach) e alguns efeitos "haha" (Taunt, Penance). Para subir de nível, puxe mais para o Arquétipo 2.

### Confirmado: Stax não é obrigatório para Lorehold

No início eu achei que Lorehold sem stax estaria incompleto. As refs EDHREC mostram que o arquétipo Big Spells (Deck 2) tem zero stax pieces e ainda assim funciona. **Validado — Big Spells Lorehold é um deck viável em bracket 3.**

### Discrepância: Call Forth the Tempest não é board wipe puro

O multi-tag classifica Call Forth como `board_wipe(0.90)` — mas na verdade é um wheel (todo mundo descarta, compra 7) que também dá dano por carta no GY. É mais perto de `wheel + drain` do que `board_wipe`. Isso afeta as contagens de board wipe vs wheel.

### Insights para ManaLoom

| Carta | Tag ManaLoom | Tag Esperada | Diferença |
|:------|:-----------:|:------------:|:---------:|
| Call Forth the Tempest | board_wipe | wheel + drain | Multi-tag captura board_wipe mas não wheel |
| Longshot, Rebel Bowman | payoff | filler/marginal | Payoff é generoso — a carta não escala |
| Deflecting Palm | big_spell | reactive/situational | Big_spell é estranho para um redirect de CMC 2 |
| Smothering Tithe | ramp | ramp + engine | Multi-tag captura corretamente (ramp + token_maker + sacrifice_outlet) |
>>>>>>> 83684733 (feat: Lorehold Purpose Analyzer - deep dissection 2026-05-28)
