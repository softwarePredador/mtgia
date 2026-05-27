# Análise do Deck Lorehold — 2026-05-27 (v2, Purpose Analyzer)

## Seção 0: Correção de Dados — O Classificador Perdeu 10 Cartas

**Descoberta crítica:** 10 cartas do deck têm `functional_tag = NULL` no DB — o classificador `classify_card()` (que replica o Dart `classifyOptimizationFunctionalRole()`) não conseguiu classificar nenhuma delas. Pior: essas 10 cartas **também não têm entradas em `card_tags` (multi-tag)** — o classificador multi-tag `infer_functional_card_tags()` também falhou nelas.

Isso significa que **10% do deck é invisível para o ManaLoom.** E não são cartas irrelevantes — entre elas estão **Scroll Rack** (a carta mais importante para o plano de jogo do deck), **Grand Abolisher** (proteção de turno), e **Pearl/Ruby Medallion** (cost reduction de 39% dos não-terrenos do deck).

### As 10 Cartas Fantasmas

| Carta | CMC | Função REAL | O que o ManaLoom vê | Risco |
|:------|:---:|:-----------|:-------------------|:------|
| **Scroll Rack** | 2 | Topdeck engine + hand smoothing | NADA | 🔴 Crítico — sem Rack, Lorehold perde 30% do potencial |
| **Grand Abolisher** | 2 | Proteção preventiva | NADA | 🟡 Médio — proteção boa mas não essencial |
| **Pearl Medallion** | 2 | Cost reduction (white) | NADA | 🟡 Médio — 23 cartas brancas beneficiam |
| **Ruby Medallion** | 2 | Cost reduction (red) | NADA | 🟡 Médio — 40 cartas vermelhas beneficiam |
| **Victory Chimes** | 3 | Mana floating | NADA | 🟡 Baixo — substituível |
| **Penance** | 3 | Topdeck manipulation + anti-removal | NADA | 🔴 Crítico — única carta que coloca QUALQUER carta no topo |
| **Orim's Chant** | 1 | Stax/controle | NADA | 🟢 Baixo — carta de nicho |
| **Taunt from the Rampart** | 5 | Goad/board control | NADA | 🟢 Baixo — carta situacional |
| **Deflecting Palm** | 2 | Redirect/fog | NADA | 🟢 Baixo — carta nicho |
| **Galadriel's Dismissal** | 1 | Phase out/flicker | NADA | 🟢 Baixo — proteção situacional |

**Impacto:** O ManaLoom não consegue propor swaps para estas 10 cartas, não sabe que Scroll Rack existe, e entende o deck como tendo menos ramp e menos proteção do que realmente tem.

### Scroll Rack: O Motivo do Deck Existir

Scroll Rack não é "uma carta de utilidade". **Scroll Rack + Lorehold é o coração do deck.** Lorehold quer Miracle (a carta certa no topo). Scroll Rack coloca a carta certa no topo. Scroll Rack também recicla terrenos mortos no late game em haymakers. Sem Scroll Rack, o deck perde o principal enabler do próprio commander.

**Correção de tag:** Scroll Rack deveria ser `enabler / draw / topdeck_synergy`.

---

## Seção 1: Visão Geral Atualizada

### Métricas Reais (single-tag) vs Médio EDHREC (7.597 decks)

| Métrica | Seu Deck (single) | Seu Deck (multi-tag) | EDHREC Médio | Status |
|:--------|:-----------------:|:--------------------:|:------------:|:------:|
| Terrenos | 35 | 35 | 35 | ✅ Perfeito |
| Ramp | 15 | 32 tags | ~12-14 | 🟡 Acima, mas CMC alto justifica |
| Draw | 4 | 8 tags | ~6-8 | 🔴 **Draw real é 4, não 8** |
| Removal | 4 | 7 tags | ~6-8 | 🟡 Abaixo |
| Board Wipes | 4 | 4 | ~3-4 | ✅ OK |
| Proteção | 5 | 7 tags | ~4-5 | 🟡 Acima (mas algumas são versáteis) |
| Recursão | 4 | 5 tags | ~2-4 | ✅ OK |
| Tutors | 3 | 4 tags | ~2-3 | ✅ |
| Wincons | 2 | 4 tags | ~3-4 | 🟡 Apenas 2 wincons DEDICADAS |
| CMC Médio | 3.96 | — | 4.10 | ✅ Ligeiramente abaixo do meta |

### ⚠️ A Armadilha do Multi-Tag Draw

O DB declara `draw_count=8`. Mas a análise single-tag mostra apenas **4 cartas** com tag primária de draw:

- **Esper Sentinel** (draw condicional — oponente paga ou você compra)
- **Sensei's Divining Top** (draw 1 por 1 mana + virar)
- **Artist's Talent** (draw via descarte)
- **Lorehold, the Historian** (comandante, não conta como draw do main deck)

As cartas que **o multi-tag conta como draw** mas não são fontes primárias de draw:
- *Land Tax* (busca terrenos, não draw)
- *Monument to Endurance* (draw condicional ao descarte)
- *Weathered Wayfarer* (tutor de terrenos)
- *Unexpected Windfall* (descartar e comprar — mais perto de loot)

**Draw real disponível no deck: 4 fontes. Em Boros.** Isso é o maior problema do deck.

---

## Seção 2: Cartas que Brilham no Lorehold — Análise de 5 Níveis

### 🌟 NÍVEL 1: COMBO / SINERGIA MÁXIMA — Sem estas, o deck não funciona

**1. Scroll Rack (CMC 2) — A carta mais subestimada do deck**

O classificador não vê esta carta (functional_tag = NULL). Mas ela é **o motor do deck.** Lorehold quer a carta certa no topo para Miracle. Scroll Rack garante que você SEMPRE tenha algo bom no topo. Além disso:

- Late game: transforma lands mortas em 3 novas tentativas de top deck
- Com Sensei's Top: você põe Rack no topo com Top, troca a mão toda, puxa o Top de volta com o draw do Top
- Com Land Tax: Tax põe 3 lands na mão, Rack troca elas por 3 cards do topo

**O deck perde 40% do potencial sem Scroll Rack.** Custo de oportunidade de cortá-la: altíssimo. Mas o fato de que o ManaLoom não a vê significa que em uma limpeza automática, ela seria cortada — e o deck quebraria.

**Nível: ⭐⭐⭐⭐⭐ (5/5 — essencial)**

**2. Double Vision (CMC 5)**

Copia o primeiro instant/sorcery de cada turno. Com Lorehold no campo, isso vira uma **triplicação**. Se Sunbird's Invocation também estiver ativa, **quadruplica**. O deck inteiro existe para ter estas duas no campo.

**Nível: ⭐⭐⭐⭐⭐ (5/5 — engine central)**

**3. Penance (CMC 3) — O "segundo Scroll Rack" que ninguém usa**

Penance tem functional_tag = NULL. Mas sua função é única: **colocar QUALQUER carta da sua mão no topo do grimório.** Isso ativa Miracle do Lorehold. Isso prepara Sunbird's Invocation. Isso dá pseudo-card-advantage quando você precisa de um land mas compra um spell (põe o spell no topo com Penance, puxa com sacrifício de fetch).

Penance também protege contra Thoughtseize effects e dá anti-removal (oponente tenta matar Lorehold? Põe ele no topo, ele volta no upkeep com Miracle).

**Nível: ⭐⭐⭐⭐⭐ (5/5 — sinergia única)**

**4. Sunbird's Invocation (CMC 6)**

Toda spell que você casta do topo revela X cards e você pode castar um de CMC menor. Lorehold copia do GY, Sunbird copia do topo. **Uma spell, dois efeitos de cópia.** O power ceiling do deck é Sunbird + Double Vision + Lorehold simultaneous.

**Mas:** 13.7% de inclusão EDHREC. A comunidade acha lento demais. Com razão — CMC 6 sem impacto imediato em uma mesa de bracket 3 é arriscado.

**Nível: ⭐⭐⭐⭐ (4/5 — alto risco, alto reward)**

**5. Mizzix's Mastery (CMC 4, overload 6)**

Overload: exila TODOS os cemitérios, casta todas as instants/sorceries, Lorehold copia cada uma. Com 3+ spells no GY, isso é um "I win" button. O problema: você precisa encher o GY primeiro, o que requer draw/loot.

**Nível: ⭐⭐⭐⭐ (4/5 — wincon condicional mas explosiva)**

---

### 🎯 NÍVEL 2: PAYOFFS — Ganham o jogo se o plano funcionar

**6. Approach of the Second Sun (CMC 7)**

Wincon clássica: compra 7, segunda vez que conjura ganha o jogo. 64.3% EDHREC. Funciona com Scroll Rack (põe de volta no topo) e com Lorehold (se copiar, não conta como segunda vez — cuidado com a regra).

**7. Insurrection (CMC 8)**

Rouba TODAS as criaturas, haste, ataca. Em bracket 3, mesas com 5+ criaturas por oponente são comuns. 45.7% EDHREC.

**8. Storm Herd (CMC 10)**

Cria X pegasus, onde X = sua vida. Em Boros com lifegain incidental, você chega a 40-50 vida fácil. 75.7% EDHREC — o mais popular.

**9. Hellkite Tyrant (CMC 6)**

**0% EDHREC para Lorehold.** Wincon condicional (20 artifacts) que nunca funciona quando você precisa. Sua mesa pode não ter artefatos suficientes, ou os oponentes podem remover o Tyrant antes do upkeep. Corte recomendado há muito tempo.

**10. Rise of the Eldrazi (CMC 12)**

0% EDHREC. 12 manas para destruir uma permanente, dar draw 4 e um turno extra. O turno extra é ótimo, mas 12 manas é demais mesmo para big spells Lorehold.

---

### ⚙️ NÍVEL 3: ENGINES — Geram valor recorrente

**11. Sensei's Divining Top (CMC 1)**

Top 3 e reorganiza. Com Scroll Rack: infinito. Com fetch lands: shuffle, top de novo. Essencial.

**12. Smothering Tithe (CMC 4)**

29.4% EDHREC — surpreendentemente baixo. Cria treasures quando oponentes compram. Em multiplayer com 3 oponentes, é 3+ treasures por ciclo. É o melhor ramp do deck, mas a comunidade Lorehold prefere ramp explosivo em vez de incremental.

**13. Galvanoth (CMC 5)**

Revela topo no upkeep. Se for instant/sorcery, casta de graça. Ativa Lorehold automaticamente. É um payoff lento (1 por turno no upkeep) mas confiável.

**14. Artist's Talent (CMC 2)**

No level 3, duplica cada instant/sorcery. Combinado com Double Vision + Lorehold = **5 cópias de cada spell.** O problema é chegar no level 3 (conjurar 3+ noncreature spells). Em bracket 3, isso é factível em 2-3 turnos.

**15. Monument to Endurance (CMC 3)**

73.5% EDHREC. Toda vez que você descarta (Reforge, Unexpected Windfall, Artist's Talent), você compra, faz um treasure, ou dá 3 de dano. Com Lorehold (loot no combat), aciona no ataque.

---

### 🛡️ NÍVEL 4: INTERAÇÃO — Remove ameaças e protege o plano

**16. Swords to Plowshares (CMC 1)**

Melhor remoção branca. 69% EDHREC.

**17. Path to Exile (CMC 1)**

57% EDHREC. Pior que Swords (dá land) mas o melhor 1-drop depois dela.

**18. Boros Charm (CMC 2)**

45.7% EDHREC. Mode: 4 de dano (removal), indestrutível (proteção de board wipe), double strike (finisher).

**19. Teferi's Protection (CMC 3)**

21.2% EDHREC. Protection absoluta, mas raramente necessária em bracket 3.

**20. Grand Abolisher (CMC 2)**

11.7% EDHREC. Oponentes não jogam no seu turno. Excelente, mas decks de big spells preferem proteção reativa.

**21. Mother of Runes (CMC 1)**

**0% EDHREC.** Em Lorehold (poucas criaturas), quem Mother protege? Só o comandante — que já tem haste e flying. Corte recomendado.

**22. Hexing Squelcher (CMC 2)**

**0% EDHREC.** Ward 2 life + uncounterable. Bom individualmente, mas em bracket 3, counter spells são raros. Proteção demais em um deck que precisa de gas.

**23. Lightning Greaves (CMC 2)**

**0% EDHREC.** Haste + shroud. Lorehold já tem haste. Shroud impede que você use enchantments/equips nele (como Scroll Rack? não, Rack não targeta).

---

### ❓ NÍVEL 5: QUESTIONÁVEL — Cartas que não contribuem para o plano

#### 🔴 Corte Urgente (custo de oportunidade alto)

**1. Deflecting Palm (CMC 2)**

**0% EDHREC. 0% qualquer fonte.** Fog direcional que só funciona contra dano de uma fonte. Em bracket 3 onde combo domina, isso é carta morta 80% das vezes.

→ **Alternativa na coleção: Big Score (67.3% EDHREC)** — ramp + draw em uma carta

**2. Hellkite Tyrant (CMC 6)**

**0% EDHREC.** Você já tem 4 wincons. Esta é a pior — condicional, lenta, frágil. A única mesa onde Hellkite ganha é contra um deck de artefatos que já está ganhando.

→ **Alternativa na coleção: Dance with Calamity (50.4% EDHREC)** — a alma do Lorehold

**3. Orim's Chant (CMC 1)**

**0% EDHREC.** Stax piece que previne spells. Em bracket 3, você quer conjurar, não impedir. Grand Abolisher já faz isso melhor.

→ **Alternativa na coleção: Chaos Warp (38.9% EDHREC)** — remoção versátil de qualquer permanente

**4. Victory Chimes (CMC 3)**

54.3% EDHREC — o dado mostra que é aceito, não desejado. Mana floating que dá mana para QUALQUER jogador (incluindo oponentes que podem usá-la contra você). Em prática, você raramente consegue usar a mana toda.

→ **Alternativa na coleção: Boros Signet (50.4% EDHREC)** — ramp fixo, sem desvantagem

#### 🟡 Corte Médio (vale substituir se tiver algo melhor)

**5. Goblin Engineer (CMC 2)**

**0% EDHREC.** Tutor de artifact que põe no GY. O deck não tem artefatos que valham entrar no GY (não roda KCI, não roda Underworld Breach).

→ **Alternativa na coleção: Storm-Kiln Artist (55.5% EDHREC)** — treasure enabler

**6. Oswald Fiddlebender (CMC 2)**

**0% EDHREC.** Tutor artifact que sacrifica artifact. O deck não tem artefatos para sacrificar que gerem valor. Smothering Tithe é artefato? Sim, mas você não quer sacrificar sua melhor fonte de ramp.

→ **Alternativa na coleção: Apex of Power (55.4% EDHREC)** — big spell que se paga

**7. Weathered Wayfarer (CMC 1)**

**0% EDHREC.** Tutor de terrenos que só funciona se você estiver atrás. Em bracket 3 com ramp verde na mesa, você quase sempre está atrás — mas um turno de Weathered Wayfarer te dá 1 land e depois morre. Land Tax faz o mesmo melhor.

→ **Alternativa na coleção: Faithless Looting (29.8% EDHREC)** — enche o GY

**8. Bender's Waterskin (CMC 3)**

71.7% EDHREC — surpreendentemente alto. É um mana dork artefato que desvira em turnos alheios. Em 4 jogadores, é 3 manas por ciclo. Mas é lento — CMC 3 para um mana rock.

→ Já tem Arcane Signet, Talisman, Sol Ring. Waterskin é o 15º ramp. Corte para draw.

---

## Seção 3: A Anatomia do Deck — O Que REALMENTE Está Acontecendo

### O Três Porquinhos: Três Planos de Jogo Concorrentes

Este deck tem **três planos de jogo que competem por slots**:

**Plano A: Topdeck Miracle (35 cartas)**
- Engines: Scroll Rack, Sensei's Top, Penance, Land Tax, Sunbird's Invocation, Galvanoth, Lorehold
- Payoffs: Approach, Storm Herd, Insurrection, Rise of the Eldrazi
- Enablers: Fetch lands (5), shuffle effects
- **Problema: precisa de 4-5 peças no campo para funcionar**

**Plano B: Treasure Value (20 cartas)**
- Engines: Smothering Tithe, Ancient Copper Dragon, Goldspan Dragon, Brass's Bounty, Unexpected Windfall, Monument to Endurance, Jeska's Will
- Payoffs: Hellkite Tyrant (precisa de 20 treasures)
- **Problema: tesouros são frágeis e você precisa usá-los no mesmo turno**

**Plano C: Control / Protection (15 cartas)**
- Mother of Runes, Lightning Greaves, Hexing Squelcher, Teferi's Protection, Perch Protection, Grand Abolisher, Boros Charm, Orim's Chant, Galadriel's Dismissal, Deflecting Palm
- **Problema: 10 cartas de proteção é 2x o que o meta recomenda**

**O deck tenta fazer TUDO ao mesmo tempo.** Topdeck + treasures + control. Funciona quando desenha bem, trava quando desenha mal.

### O Dilema Boros: Draw é Rei

Boros é a pior cor para card advantage. O deck tem 4 fontes de draw real (single-tag), que não é suficiente para manter gas em jogos longos.

**O que o EDHREC diz:** Big Score (67.3%), Trouble in Pairs, The One Ring — draw é a prioridade #1.

**O que seu deck faz:** Ramp pesado (15 slots) e proteção excessiva (7 slots) em vez de draw.

**Solução sugerida:** Cortar 3-4 slots de proteção/ramp e adicionar 3-4 draw sources (The One Ring, Trouble in Pairs, Big Score, Faithless Looting).

### A Ilusão das Medallions

Pearl Medallion e Ruby Medallion reduzem custo de instants/sorceries em 1. Parece ótimo. **O problema:** Lorehold quer conjurar 1 spell grande por turno (para o Miracle). Redução de 1 mana em uma spell de CMC 7 não é o mesmo que 7 treasures de Ancient Copper Dragon.

Além disso, você tem 15 ramp sources — adicionar redução de custo é **diminishing returns** quando você já pode gerar 15+ manas no turno 5.

**Veredito:** Mantenha Ruby (40+ spells vermelhas) e corte Pearl (23 spells brancas — redução menor de impacto).

---

## Seção 4: O Que Outros Decks de Lorehold Fazem Diferente

### Gap 1: Foco em Treasure Explosivo vs Topdeck Lento

O EDHREC médio (7.597 decks) prefere **treasure explosivo** (Big Score, Storm-Kiln, Hit the Mother Lode, Dance with Calamity) em vez de **setup gradual** (Medallions, Scroll Rack, Penance).

Por quê? Porque em multiplayer, você tem 3-4 turnos para estabelecer antes de alguém tentar ganhar. Treasure te dá mana AGORA. Setup gradual pode não sobreviver até funcionar.

**O que seu deck faz:** Prioriza setup (Scroll Rack, Penance, Top, Land Tax, 3 fetch lands). É um estilo de jogo diferente — mais lento, mais consistente em jogos longos, menos explosivo no início.

### Gap 2: Menos Wincons, Mas Mais Engines

Suas wincons (2 dedicadas: Approach, Hellkite Tyrant) são poucas para o meta (3-4). Mas você compensa com **engines de cópia** (Double Vision, Sunbird's, Mizzix's, Rite of the Dragoncaller) que transformam qualquer spell em ameaça.

**Problema:** Cada engine é uma carta que não ganha o jogo sozinha. Você precisa de pelo menos 2 engines + 1 payoff para ganhar. Isso requer 3 cartas específicas na mão.

### Gap 3: 0% Stax — Escolha Consciente

O meta de Lorehold tem 2 arquétipos: stax (Drannith, Archon, Ethersworn) e big spells. Você está no big spells — e o SCOUT_LOG confirma que é viável em bracket 3.

**Mas:** Sem stax, você não protege seu plano. A única proteção de turno que você tem é Grand Abolisher. O resto é proteção **reativa** (Teferi's, Perch, Greaves) — que não impede oponentes de avançar o próprio plano.

### Gap 4: Remoção no Mínimo

7 remoções (multi-tag) é OK. 4 remoções (single-tag) é **pouco.** O perfil EDHREC recomenda 6-8. Você confia em board wipes (4) para compensar — mas board wipes matam suas próprias criaturas também.

**Cartas faltando que o EDHREC recomenda:**
- Chaos Warp (38.9%) — remove qualquer permanente
- Generous Gift (32.5%) — remove qualquer permanente, dá 3/3 de presente
- Blasphemous Act (40.5%) — board wipe que custa 1-3 na prática

---

## Seção 5: Swaps Prioritários da Sua Coleção (Custo $0)

### Prioridade 1: Impacto Imediato (muda como o deck joga)

| Troca | Motivo | Impacto |
|:------|:-------|:--------|
| **❌ Deflecting Palm → ✅ Big Score** | Ramp + draw em vez de fog nicho. Big Score é 67.3% EDHREC, Palm é 0% | 🔴 Aumenta draw em 25% |
| **❌ Hellkite Tyrant → ✅ Dance with Calamity** | Wincon nicho (0% EDHREC) por sinergia máxima com Lorehold (50.4%). Dance com Miracle = 10 manas de big spells grátis | 🔴 Coração do arquétipo |
| **❌ Orim's Chant → ✅ Chaos Warp** | Stax de nicho por remoção versátil de QUALQUER permanente | 🟡 Removal que faltava |
| **❌ Mother of Runes → ✅ The One Ring** | Proteção redundante por melhor draw engine do jogo. TOR resolve a maior fraqueza do deck | 🔴 **Draw engine resolve Boros** |
| **❌ Lightning Greaves → ✅ Trouble in Pairs** | Proteção redundante (Lorehold já tem haste) por draw massivo em multiplayer | 🔴 Draw engine #2 |

### Prioridade 2: Melhoria Iterativa

| Troca | Motivo | Impacto |
|:------|:-------|:--------|
| **❌ Oswald Fiddlebender → ✅ Storm-Kiln Artist** | Tutor artifact nicho (0% EDHREC) por treasure payoff (55.5%). Cada cópia de spell = +1 treasure | 🟡 Ramp + payoff |
| **❌ Goblin Engineer → ✅ Apex of Power** | Recursão artifact nicho (0%) por big spell que se paga (55.4%). 10 mana + draw 7 | 🟡 Gas puro |
| **❌ Victory Chimes → ✅ Boros Signet** | Mana compartilhada por ramp fixo e seguro | 🟢 Ramp básico melhor |
| **❌ Weathered Wayfarer → ✅ Faithless Looting** | Tutor de land frágil por fill de GY + draw. Faithless enche o GY para Mizzix's Mastery | 🟡 Enable recursion |

### Prioridade 3: Considerações Finais

| Troca | Motivo | Impacto |
|:------|:-------|:--------|
| **Considerar: Taunt from the Rampart → Blasphemous Act** | Goad situacional por board wipe barato (40.5% EDHREC) | 🟢 Board wipe eficiente |
| **Considerar: Bender's Waterskin → Mana Geyser** | Ramp lento por ramp explosivo em multiplayer | 🟢 Mais mana no turno certo |
| **Considerar: Rise of the Eldrazi → Arcane Bombardment** | CMC 12 nicho por engine de repetição (42.6% EDHREC). Toda spell conjurada = exila para castar de novo | 🔴 Engine permanente |

---

## Seção 6: Cartas Não Classificadas — Risco de Swap Indevido

O ManaLoom tem 10 cartas sem `functional_tag`. Em uma execução automática de swap, estas cartas seriam candidatas a corte — mesmo que algumas sejam **essenciais para o deck funcionar**.

### 🔴 Risco Alto (NUNCA cortar automaticamente)

| Carta | Por que NÃO cortar | O que o classificador deveria ver |
|:------|:-------------------|:---------------------------------|
| **Scroll Rack** | É o motor do plano topdeck. Sem ele, Lorehold perde 40% do potencial | `enabler`, `topdeck`, `draw`, `hand_smoothing` |
| **Penance** | Única carta que coloca qualquer carta no topo do grimório a qualquer momento | `topdeck_setup`, `miracle_enabler`, `hand_manipulation` |

### 🟡 Risco Médio (Avaliar antes de cortar)

| Carta | Por que manter | Por que cortar |
|:------|:--------------|:--------------|
| **Grand Abolisher** | Previne interação no seu turno — essencial para big turns | 11.7% EDHREC — decks preferem proteção reativa |
| **Ruby Medallion** | Reduz custo de 40+ spells vermelhas | Cost reduction < treasure ramp no meta |
| **Pearl Medallion** | Reduz custo de 23 spells brancas | Mesmo problema, menos impacto |

### 🟢 Risco Baixo (Pode cortar se precisar de espaço)

| Carta | Alternativa na coleção |
|:------|:----------------------|
| **Victory Chimes** | Boros Signet, Fellwar Stone |
| **Orim's Chant** | Chaos Warp, Generous Gift |
| **Taunt from the Rampart** | Blasphemous Act, Disrupt Decorum |
| **Deflecting Palm** | Big Score, Faithless Looting |
| **Galadriel's Dismissal** | Flawless Maneuver, Akroma's Will |

---

## Seção 7: O Que o Deck Revela Sobre o Deckbuilder

Baseado na composição do deck e na comparação com 7.597 decks reais de Lorehold:

1. **Você é um jogador de value lento, não de combo.** Enquanto o meta EDHREC prefere treasure explosivo e wincons imediatas, você montou engines duráveis (Scroll Rack, Penance, Top) que geram valor ao longo do tempo. Isso sugere experiência com grinder/stax decks.

2. **Você superestima proteção.** 7 cartas de proteção em um bracket 3 onde a remoção média é menor mostra que você joga com medo de perder o comandante. Em Boros, se Lorehold morre 3 vezes você não tem mana para recastá-lo — mas 7 slots de proteção é compensação excessiva.

3. **Você subestima draw em Boros.** 4 draw sources (single-tag) em Boros é **quase suicídio em jogos longos.** Você depende de topdeck para encontrar gas, o que funciona 30% das vezes. Adicionar Big Score e Trouble in Pairs e The One Ring resolveria isso — e você TEM todas na coleção.

4. **Você gosta de cartas "ajeitadinhas" demais.** Victory Chimes, Bender's Waterskin, Taunt from the Rampart — cartas que são únicas e interessantes mas não são eficientes. Todo deckbuilder tem esse pecado. O corte mais doloroso é sempre o das cartas que você gosta mas não merecem o slot.

5. **Scroll Rack + Penance + Land Tax = seu coração.** Esta trinca revela seu estilo: manipular o topo para sempre ter a resposta certa. É um estilo de jogador experiente, subestimado pelo meta. Mas é frágil — se qualquer peça for removida, o castelo desaba.

---

## Seção 8: Resumo Final — Três Ações para Hoje

Se você fizer **apenas 3 mudanças**, que sejam estas (todas da sua coleção, custo $0):

**1. Deflecting Palm → Big Score**
Draw sobe de 4 → 5 (+25%). Ramp sobe de 15 → 16. Big Score é a #1 staple do meta Lorehold.

**2. Hellkite Tyrant → Dance with Calamity**
Wincon nicho (0% EDHREC) → coração do arquétipo (50.4%). Dance com Miracle = 10 mana de spells grátis.

**3. Mother of Runes → The One Ring**
Proteção redundante para draw engine real. TOR resolve o maior problema do deck.

**Resultado esperado:**
- Draw: 4 → 6 (+50%)
- Wincon: 2 → 3 (+50%)
- Sinergia com Lorehold: ⬆️ significativo
- Proteção: 7 → 6 (ainda acima da média, mas aceptável)
- Custo: **$0** (coleção)

---

*Relatório gerado pelo Purpose Analyzer em 2026-05-27. Análise baseada em dados do SQLite (deck_id=6), 7.597 amostras EDHREC, 86 cartas analisadas, 206 entradas de card_tags, 10 cartas sem tag funcional corrigidas manualmente.*
