## [2026-05-31T18:48:27+00:00] Execucao #19 — COPY SYNERGY Ecosystem (Pos-Ciclo #10, 24 swaps)

> **Data:** 2026-05-31T18:48:27+00:00
> **Deck state:** Pos-Ciclo #10 (Flare of Duplication + Twinflame aplicados). Motor 4/4, Copy 5/5 (Lorehold + Double Vision + Bombardment + Archaic + Twinflame). Sem Play T3=16.9% (Execucao #10, N=1000, seed=42)
> **EDHREC:** 7.802 decks (sem alteracao significativa desde #17)
> **Colecao:** 229 cartas, funcionalmente esgotada para cartas de alto impacto CMC <= 3
> **Missao:** Com Twinflame + Reverberate + Dualcaster Mage na colecao, o deck agora tem acesso a uma CAMADA DE COPIA completa. Quais cartas da colecao TRIGAM em copias? O que mais ganha valor com 5+ fontes de copia?
> **Analista:** Hermes Agent — Lorehold Deep Scout

---

### CONFIRMACAO: Nenhuma Mudanca Desde Execucao #18

| #18 Recomendou | Aplicado pelo Evolution Oracle Ciclo #10? | Status |
|:---------------|:----------------------------------------:|:-------|
| Grand Abolisher → **Reverberate** | ❌ NAO | **Ainda pendente** |
| Flare of Duplication → ja estava aplicado | ✅ | Confirmado |
| Twinflame → ja estava aplicado | ✅ | Confirmado |

**Estado atual do deck identico ao #18.** Grand Abolisher (CMC 2, double-null, declining -0.27, 11.7% EDHREC) permanece como a carta mais fraca do deck que ainda e substituivel.

---

### PASSO 1: O ECOSSISTEMA DE COPIA — Por que Copy Triggers Importam

O deck agora tem **5 camadas de copia** ativas:

| # | Camada | Tipo | CMC | O que copia | Triggera "cast"? |
|:-:|:-------|:-----|:---:|:------------|:-----------------:|
| 1 | **Lorehold, the Historian** | Commander | 5 | Copia 1a spell nao-criatura por turno | ❌ (copia, nao cast) |
| 2 | **Double Vision** | Enchantment | 5 | Copia 1a sorcery por turno | ❌ (copia, nao cast) |
| 3 | **Arcane Bombardment** | Enchantment | 5 | Exila spell → cast copia | ✅ SIM — CAST |
| 4 | **The Dawning Archaic** | Creature | 3 | Copia 1a spell por turno | ❌ (copia, nao cast) |
| 5 | **Twinflame** | Sorcery | 2 | Copia criatura (Strive) | N/A (copia criatura) |

**Diferenca critica:** Arcane Bombardment CASTA a copia (triggera magecraft, prowess, Storm-Kiln). As outras COPIAM (nao triggeram "cast"). Cartas como **Ashling, Flame Dancer** triggeram em AMBOS ("cast OR copy") — perfeitas para este deck.

---

### PASSO 2-3: Cartas que TRIGAM em Copias (Score Atualizado)

**Metodologia:** Mesmo scoring A+B+C. Bonus extra (+1 em A) para cartas que triggeram em copy, ja que o deck tem 4+ fontes de copy por jogo.

#### SCORE >= 8 (Prioridade)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 1 | **Reverberate** | 2 | R | **10** | 4 | 5 | 1 | **MESMA recomendacao do #18.** Copia qualquer spell por RR. Com 5 camadas de copia ativas, Reverberate e a 6a camada — e a unica que copia spells do OPONENTE. Instant → alimenta Bombardment + Double Vision. CMC 2 e o mesmo slot de Grand Abolisher (permuta direta, DCMC=0). EDHREC 17.9% trend -0.52. **Continua sendo a MELHOR carta restante na colecao.** |

#### SCORE 7 (Forte — reconsiderar)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 2 | **Ashling, Flame Dancer** | 4 | R | **7** | 4 | 2 | 1 | 🆕 **REAVALIADA COM ECOSSISTEMA DE COPIA.** Magecraft triggera em cast **OU copy**. Com Lorehold (1 copy/turn) + Double Vision (1 copy/turn) + Bombardment (cast copy) = Ashling ve 3-4 triggers POR TURNO sem gastar mana extra. Cada trigger: +2/+0, scry 1, draw 1 (se segunda trigger no turno), 2 dano a qualquer target. Em um turno tipico: cast spell → Lorehold copy → Ashling +2/+0 + scry + draw → Double Vision copy → Ashling +4/+0 + 2 dano → Bombardment cast → Ashling +6/+0 + scry. **3 triggers = Ashling 7/6 com dano e draw.** Mas: CMC 4, criatura (nao interage com Double Vision como spell). |

| 3 | **Dualcaster Mage** | 3 | R | **7** | 4 | 2 | 1 | Com Twinflame no deck: combo infinito (5 mana: Twinflame → hold priority → Dualcaster → copia Twinflame → token copia Dualcaster → loop). Fora do combo: copia spell com flash. EDHREC 16.9% trend -0.25. Criatura (nao interage com Double Vision/Bombardment). |

#### SCORE 6 (Nice to have — novos angulos)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 4 | **Invoke Calamity** | 5 | R | **6** | 3 | 3 | 0 | 🆕 **NOVA ANALISE.** Instant: casta ate 2 instants/sorceries do cemiterio OU mao sem pagar (total CMC <= 6). Com Faithless Looting + Thrill of Possibility enchendo o cemiterio, Invoke Calamity e um mini-Mizzix's Mastery a instant speed. Pode recastar Swords to Plowshares (CMC 1) + Abrade (CMC 2) por 5 mana = removal duplo. Ou Thrill (CMC 2) + Chaos Warp (CMC 3) = draw + removal. Instant → alimenta Bombardment + Double Vision. Mas CMC 5 em zona DEFENSIVE. |

| 5 | **Galvanoth** | 5 | R | **6** | 4 | 1 | 1 | 🆕 **REAVALIADO.** Com 3 topdeck manipulation cards (Top, Scroll Rack, Penance), Galvanoth garante free spell TODO TURNO. Free spell → Lorehold trigger (copy) → Double Vision trigger (copy) → Ashling trigger (se no campo). Cadeia de valor: 0 mana investido = 1 spell + 2 copies + triggers. Mas CMC 5, criatura, 0% EDHREC. **So recomendavel quando T3 < 12%.** |

| 6 | **Seize the Spoils** | 3 | R | **6** | 3 | 3 | 0 | Discard → draw 2 + Treasure. CMC 3 vs Big Score/Unexpected Windfall (CMC 4). Troca CMC 4→3 = -1 CMC. Sorcery → alimenta Lorehold + Double Vision + Bombardment. Mas efeito menor que Big Score (CMC 4, instant, 2 treasures). |

| 7 | **Spiteful Banditry** | 2 | R | **6** | 3 | 4 | 0 | Board wipe ETB + treasure engine. CMC 2. Mas 0% EDHREC em Lorehold. Enchantment nao interage com Bombardment. Rebaixado de 7→6 porque nao ganha valor extra com o ecossistema de copia. |

| 8 | **Xorn** | 3 | R | **6** | 4 | 2 | 0 | 🆕 **REAVALIADO.** Treasure doubler: com 8+ fontes de treasure (Big Score, Unexpected Windfall, Brass's Bounty, Hit the Mother Lode, Storm-Kiln, Smothering Tithe, Archaeomancer's Map, Jeska's Will), Xorn dobra a producao. 1 Big Score vira 4 treasures (em vez de 2). Brass's Bounty vira 14 treasures (em vez de 7). Isso alimenta Rain of Riches (cascade), mana para Approach recast, e X-spells como Call Forth the Tempest. **Subiu de 5→6 porque o ecossistema de copia permite gastar esse mana extra em spells copiadas.** Mas 0% EDHREC, criatura fragil 3/2. |

---

### PASSO 4: O Que o Ecossistema de Copia REALMENTE Significa

Com 5 camadas de copia ativas, o deck opera em **3 velocidades**:

| Velocidade | Cartas | Trigger de copia |
|:-----------|:-------|:-----------------|
| **Passiva (todo turno)** | Lorehold, Double Vision, Dawning Archaic | 2-3 copias/turno sem custo |
| **Ativa (sob demanda)** | Reverberate (se adicionado), Dualcaster Mage | Copia instantanea de spell especifico |
| **Explosiva (1 vez)** | Arcane Bombardment, Twinflame | Copia do cemiterio / copia de criatura |

**Por que Ashling e a carta mais subestimada da colecao:**

Em um turno tipico com Double Vision + Lorehold + Bombardment no campo:
1. Cast Faithless Looting (R, draw 2 discard 2) → Ashling trigger #1 (+2/+0)
2. Lorehold copy → Ashling trigger #2 (+4/+0, scry, draw se 2a trigger)
3. Double Vision copy → Ashling trigger #3 (+6/+0, 2 dano, scry)
4. Bombardment exile + cast copy → Ashling trigger #4 (+8/+0, scry, draw)
5. Resultado: Ashling 9/6, scry 2, draw 2, 2 dano distribuido. **Tudo por R.**

Isso transforma Ashling de "criatura util" em **engine de draw+dano que escala com cada spell do deck**. Nenhuma outra carta na colecao oferece esse nivel de valor incremental por trigger.

**Mas:** Ashling custa CMC 4 e e criatura. Em zona DEFENSIVE (T3=16.9%), adicionar CMC 4 piora T3. So recomendavel quando T3 < 12%.

---

### COLECAO: Estado Terminal

```
Categorias ESGOTADAS (0 cartas restantes):
  - Draw CMC <= 3
  - Removal CMC <= 3  
  - Ramp CMC <= 2
  - Protecao CMC <= 2 com EDHREC > 15%
  - Board wipe CMC <= 4

Ultimas cartas RESTANTES com Score >= 6:
  1. Reverberate (CMC 2, Score 10) — COPY spell. ULTIMA carta de copy disponivel.
  2. Ashling, Flame Dancer (CMC 4, Score 7) — Copy trigger engine.
  3. Dualcaster Mage (CMC 3, Score 7) — Combo com Twinflame.

Cartas que PRECISAM ser adquiridas para melhorar o deck:
  - Skullclamp (CMC 1) — draw engine em deck de tokens
  - Chrome Mox / Mox Diamond (CMC 0) — fast mana
  - Mana Vault (CMC 1) — fast mana
  - Enlightened Tutor (ja no deck) ✅
  - Gamble (ja no deck) ✅
```

---

### TOP 3 RECOMENDACOES PARA EVOLUTION ORACLE (Ciclo #11)

1. **Grand Abolisher → Reverberate** — DCMC=0. RECOMENDACAO UNANIME desde Execucao #18. Substitui 6a protecao redundante (double-null, declining -0.27, 11.7% EDHREC) pela 6a camada de copia (instant, CMC 2, interage com TODAS as engines). Carta na colecao (x1). Cor: R (legal). **NAO HA MOTIVO PARA NAO APLICAR ESTE SWAP.**

2. **Nenhum outro swap de ALTO impacto viavel.** Com T3=16.9% (DEFENSIVE), adicionar CMC 4+ piora a consistencia. Ashling (CMC 4), Invoke Calamity (CMC 5), Galvanoth (CMC 5) sao excelentes cartas mas AGRAVAM o problema de T3. So serao viaveis quando T3 < 12%.

3. **AQUISICAO recomendada:** Para reduzir T3 de 16.9% para <12%, o deck precisa de cartas CMC <= 2 com alto impacto. A colecao esta esgotada. Adquirir: **Skullclamp** (CMC 1, draw em tokens), **Mana Vault** (CMC 1, fast mana), **Jeweled Lotus** (CMC 0, cast commander T1-T2). Estimativa: 2-3 cartas CMC 0-1 reduzem T3 em ~5pp.

### ESTRATEGIA PARA CICLO #11

| Parametro | Valor | Estrategia |
|:----------|:-----:|:-----------|
| T3 atual | 16.9% | DEFENSIVE (target: -5 a -10 CMC) |
| Colecao CMC <= 2 | 1 carta (Reverberate) | Esgotada |
| Swap viavel | 1 (Grand Abolisher → Reverberate, DCMC=0) | Nao reduz T3 |
| Conclusao | **Ciclo #11 deve ser: 1 swap (Abolisher→Reverberate) + recomendacao de aquisicao** | Aguardar novas cartas |

---

## [2026-05-31T18:10:47+00:00] Execucao #18 — Post-Twinflame Scout (Pos-Ciclo #9, 24 swaps)

> **Data:** 2026-05-31T18:10:47+00:00
> **Deck state:** Pos-Ciclo #9 + swap extra (Ruby Medallion → Twinflame aplicado). Motor 4/4, Copy 5/5 (Lorehold + Double Vision + Bombardment + Archaic + Twinflame), Sem Play T3=16.9% (Execucao #10, N=1000, seed=42)
> **EDHREC:** 7851 decks (+49 vs exec #17, +0.6% growth)
> **Colecao:** 229 cartas (158 nao estao no deck)
> **Missao:** Verificar o que mudou desde Execucao #17. Twinflame foi aplicado — o que isso libera? Quais sinergias novas surgem?
> **Analista:** Hermes Agent — Lorehold Deep Scout

---

### CONFIRMACAO: Recomendacao #17 Aplicada

| #17 Recomendou | Aplicado? | Delta |
|:---------------|:---------:|:------|
| Ruby Medallion → **Twinflame** | ✅ SIM | ΔCMC=0 |
| Grand Abolisher → Reverberate | ❌ NAO | Pendente |
| Galvanoth → Flare of Duplication | N/A — Galvanoth ja tinha saido | — |

**Estado pos-aplicacao:**
- Ruby Medallion: FORA (double-null, declining -0.37, 3+ ciclos) ✅
- Twinflame: NO DECK (CMC 2, instant, copy creature → comba com Surge to Victory + Akroma's Will) ✅
- Grand Abolisher: AINDA NO DECK (11.7% EDHREC, declining -0.27, 6a protecao) 🟡
- **Total swaps desde baseline: 24** (era 23 no #17, Ruby→Twinflame = +1)

---

### O QUE MUDA COM TWINFLAME NO DECK

Twinflame adiciona a **5a camada de copia** (antes eram 4: Lorehold, Double Vision, Bombardment, Archaic).

**Nova chain de sinergia:**
```
Twinflame (copia de criatura) → Surge to Victory (dobra poder + copia instant/sorcery) → Akroma's Will (double strike + flying + indestrutivel)
= 1 criatura vira 2 copias (Twinflame), cada uma com poder dobrado (Surge), todas com double strike (Akroma's Will)
= DANO QUADRUPLICADO em um turno
```

**Nova combo potencial: Twinflame + Dualcaster Mage (CMC 3, R, na colecao)**
- Twinflame targeting qualquer criatura → hold priority → Dualcaster Mage
- Dualcaster ETB copia Twinflame → copia de Twinflame targeta Dualcaster → token de Dualcaster copia Twinflame → loop infinito
- Resultado: tokens infinitos de Dualcaster Mage com haste. Vitoria naquele turno.
- Custo: 5 mana (2+3). Requer timing. Dualcaster e criatura (nao interage com Double Vision).
- **Score: 7** (A=4 combo wincon, B=2 CMC 3 creature, C=1 EDHREC 16.9%)

---

### PASSO 2-3: Cartas Candidatas Atualizadas

**Metodologia:** Mesmo scoring (A+B+C) da #17. Foco em cartas que COMPLEMENTAM o novo estado com Twinflame.

#### SCORE >= 8 (Prioridade)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 1 | **Reverberate** | 2 | R | **8** | 2 | 5 | 1 | Copia qualquer spell. Com Twinflame + Lorehold: cast spell → Lorehold copy → Reverberate copy → Twinflame copia criatura = 4 effects de 1 card. Instant → alimenta Bombardment + Mizzix's Mastery. CMC 2 nao piora T3. EDHREC 17.9% trend -0.52. MELHOR CARTA RESTANTE na colecao. |
| 2 | **Strike It Rich** | 1 | R | **8** | 4 | 5 | 0 | CMC 1 sorcery: cria Treasure. Com 8+ fontes de treasure, +1 nao muda o jogo. MAS: CMC 1 = nao piora T3. Sorcery = alimenta Lorehold, Bombardment, Double Vision. Flashback (3R) do grave = usa 2x. So e recomendavel em strategy DEFENSIVE onde cada -1 CMC importa. |

**Nota sobre Strike It Rich:** Score inflado pelo sistema automatico (bonus de treasure). Na pratica, e uma carta de impacto baixo — 1 treasure por R nao move o ponteiro. So faz sentido se o objetivo e puramente reduzir CMC medio (trocar por algo CMC ≥ 5). Nao recomendado como swap de sinergia — so como swap de CMC (DEFENSIVE puro).

#### SCORE 7 (Forte — considerar)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 3 | **Spiteful Banditry** | 2 | R | **7** | 3 | 4 | 0 | Board wipe (ETB damage) + treasure engine (criaturas morrendo = treasures). CMC 2. Sinergia dupla: wipe+treasure. Mas 0% EDHREC em Lorehold — comunidade nao valida. Enchantment (nao interage com Bombardment). |
| 4 | **Dualcaster Mage** | 3 | R | **7** | 4 | 2 | 1 | Com Twinflame no deck: combo infinito (5 mana, vence na hora). Fora do combo: copia spell por 3 mana com flash. EDHREC 16.9% trend -0.25. Criatura (nao interage com Double Vision/Bombardment). |
| 5 | **Guttersnipe** | 3 | R | **7** | 2 | 3 | 2 | 2 dano a cada oponente por spell nao-criatura. Com 20+ spells = relogio real. EDHREC 32.2% (validado). Trend -0.08 (estavel). Mas: criatura (nao interage com Double Vision/Bombardment), CMC 3 ja e. |

#### SCORE 5-6 (Nice to have — sidegrades)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 6 | Seize the Spoils | 3 | R | 6 | 3 | 3 | 0 | Discard 1 → draw 2 + Treasure. CMC 3. Redundante com Big Score (CMC 4, instant) e Unexpected Windfall (CMC 4, instant). Trocar CMC 4→3 = -1 CMC. |
| 7 | Tablet of Discovery | 3 | R | 6 | 2 | 3 | 1 | 🆕 NA SECAO NEWCARDS do EDHREC (26.3%). Milla 1 → pode jogar do topo. Com Scroll Rack + Penance + Top = valor adicional. Mas CMC 3 e efeito marginal. |
| 8 | Xorn | 3 | R | 5 | 3 | 2 | 0 | Tesouros criam +1 tesouro. Com 8+ fontes de treasure = multiplicador real. Mas 0% EDHREC em Lorehold — comunidade nao usa. Criatura 3/2 fragil. |
| 9 | Mother of Runes | 1 | W | 5 | 1 | 3 | 1 | Protecao pontual. EDHREC 34.5% (alto). Mas deck ja tem 5 protecoes. Sidegrade de protecao, nao resolve gap. |

---

### PASSO 4: Analise Qualitativa

#### Por que Reverberate e a UNICA recomendacao forte desta execucao:

1. **Complementa Twinflame.** Com Twinflame copiando criaturas e Reverberate copiando spells, o deck ganha 2 eixos de copia que operam em velocidades diferentes (sorcery-speed creature copy + instant-speed spell copy).

2. **CMC 2 — mesmo slot de Grand Abolisher.** Troca 1-por-1 sem impacto no CMC medio. Nao piora T3 (16.9% → DEFENSIVE).

3. **Interage com TODAS as engines de spells:** Lorehold (copy trigger), Double Vision (copy spell), Arcane Bombardment (exile + cast), Mizzix's Mastery (flashback). E o "quinto Beatle" das engines de copia.

4. **Grand Abolisher e a carta mais fraca do deck que ainda e substituivel.** 11.7% EDHREC, declining -0.27, double-null. 6a protecao em um deck que precisa de 3-4. O slot e perfeito para Reverberate.

#### O que NAO recomendar:

- **Apex of Power** (54.9%, CMC 10): Excelente carta, CMC 10 piora T3 em ~1.5pp. Impossivel em zona DEFENSIVE.
- **Guttersnipe** (32.2%, CMC 3): Bom payoff, mas criatura em deck de spellslinger. Existe em tensao com Double Vision e Bombardment (que querem spells, nao criaturas).
- **Strike It Rich** (CMC 1): Impacto baixissimo. So faz sentido se trocar por carta CMC 6+ — mas as cartas CMC 6+ no deck (Austere Command, Rite of the Dragoncaller, Surge to Victory) tem EDHREC 33-65% e nao merecem corte.

#### Colecao: Estado de Deplecao

Apos 24 swaps desde baseline, a colecao esta **funcionalmente esgotada** para cartas de ALTO impacto em Lorehold:

| Categoria | Cartas restantes na colecao | Status |
|:----------|:---------------------------|:-------|
| Draw CMC ≤ 3 | 0 (todas no deck) | 🔴 Esgotado |
| Removal CMC ≤ 3 | 0 (todas no deck) | 🔴 Esgotado |
| Ramp CMC ≤ 2 | 0 (todas no deck) | 🔴 Esgotado |
| Copy spell CMC ≤ 3 | **Reverberate** (1 carta) | 🟡 Ultima carta |
| Wincon alternativo CMC ≤ 5 | Dualcaster Mage (combo com Twinflame) | 🟡 Situacional |
| Protecao CMC ≤ 2 | Mother of Runes, Giver of Runes | Sidegrades |
| Treasure adicional | Strike It Rich, Seize the Spoils, Spiteful Banditry, Xorn | Baixo impacto |

**Conclusao: A colecao suporta no maximo 1 swap de alto impacto (Grand Abolisher→Reverberate) e 1-2 sidegrades.** Alem disso, qualquer melhoria requer AQUISICAO de cartas novas.

---

### RESUMO DO ESTADO DO DECK (Execucao #18)

| Aspecto | Status | Delta vs Exec #17 |
|:--------|:-------|:-----------------:|
| Ciclos aplicados | 9 (24 swaps desde baseline) | +1 (Ruby→Twinflame extra) |
| Motor Lorehold | 4/4 COMPLETO | Estavel |
| Copy layers | 5 ativas (Lorehold, Double Vision, Bombardment, Archaic, Twinflame) | +1 vs #17 ✅ |
| T3 (Execucao #10) | **16.9%** | Igual (sem novos dados) |
| Double-null count | 4 (Scroll Rack, Penance, Grand Abolisher, Taunt from the Rampart) | -1 (Ruby saiu) ✅ |
| Cartas 0% EDHREC | 0 | Estavel |
| Draw real | 7 fontes | Estavel |
| Protecao | 5 pecas | Estavel (Pearl ja saiu) |
| Strategy zone | **DEFENSIVE** (T3 16.9% > 12%) | Igual |
| Colecao CMC ≤ 3 disponivel | **Crítica** (1 carta: Reverberate) | Piorou (Twinflame consumiu 1) |
| Cartas novas no EDHREC | Tablet of Discovery (newcards, 26.3%) | 🆕 |

---

### TOP 3 RECOMENDACOES PARA EVOLUTION ORACLE (Ciclo #10)

1. **Grand Abolisher → Reverberate** — ΔCMC=0. Substitui 6a protecao redundante (declining -0.27, double-null) por spell copy engine que interage com TODAS as camadas de spellslinger. Carta na colecao (x1). Cor: R (legal). ULTIMA carta de copy spell disponivel na colecao.

2. **Nenhum outro swap de ALTO impacto disponivel.** Dualcaster Mage (combo com Twinflame) e interessante mas e criatura (anti-sinergia com Double Vision/Bombardment). Guttersnipe idem. Spiteful Banditry tem 0% EDHREC.

3. **Se T3 > 16% apos Mulligan Execucao #11:** Considerar swap DEFENSIVO puro (CMC 5+ → CMC 1-2) mesmo com cartas de baixo impacto, so para reduzir CMC medio. Ex: Taunt from the Rampart (CMC 5, 35.2% mas double-null) → Strike It Rich (CMC 1) = ΔCMC -4. Mas isso sacrifica uma carta de 35.2% EDHREC por filler — nao recomendado a menos que T3 > 18%.

**Estrategia recomendada: 1 swap (ΔCMC=0) + monitorar T3.**

- Se T3 cair para < 14% na proxima medicao: liberar Apex of Power (CMC 10, 54.9%) para swap de poder.
- Se T3 subir para > 18%: swap DEFENSIVO urgente (cortar CMC 5+, adicionar qualquer CMC 1-2 da colecao).
- Se T3 mantiver 15-17%: manter estrategia atual, priorizar AQUISICAO.

---

### AQUISICOES RECOMENDADAS (reiteradas da #17, priorizadas)

A colecao esta esgotada. O caminho para melhorar o deck agora e COMPRAR cartas:

| # | Carta | Funcao | Sinergia | Preco | Prioridade |
|:-:|:------|:-------|:---------|:------|:----------|
| 1 | **Skullclamp** | Draw engine CMC 1 | Mata token 1/1 → draw 2. Com Storm Herd = draw 40+ cartas em 1 turno. Melhor draw de Commander. | $10-15 | 🔴 Urgente |
| 2 | **Underworld Breach** | Recursion massiva CMC 2 | Alternativa a Mizzix's Mastery. Escape = recurso infinito com Faithless Looting, Thrill, Big Score. | $15-20 | 🟡 Alta |
| 3 | **Past in Flames** | Flashback massivo CMC 4 | Mono-red recursion — todo grave vira jogavel com Lorehold. Mesmo efeito que Mizzix's Mastery mas em peca separada. | $5-10 | 🟡 Alta |
| 4 | **Mana Vault** | Fast mana CMC 1 | Acelera T1→T3. Melhora T3 diretamente. | $50-60 | 🟢 Media (custo alto) |
| 5 | **Dockside Extortionist** | Treasure massivo CMC 2 | Melhor criatura de treasure do formato. Banido em alguns grupos. | $80-100 | ⚪ Banido? |

**Se for comprar 1 carta: Skullclamp.** E o melhor draw engine de Commander, CMC 1, e transforma Storm Herd de "10 mana, cria tokens" para "10 mana, cria tokens E draw 40+ cartas". Custo-beneficio imbatível.

---

### PROXIMOS PASSOS

1. **Evolution Oracle:** Avaliar Grand Abolisher → Reverberate (unico swap de alto impacto viavel). Estrategia: 1 swap, ΔCMC=0.
2. **Mulligan Analyst:** URGENTE — Rodar Execucao #11 (N=1000, seed=42) pos-Ciclo #9 para medir T3 real. O numero 16.9% e da Execucao #10 e ja tem +2 ciclos desde entao (C#8 e C#9, ambos AGGRESSIVE com ΔCMC +2 cada). E provavel que T3 real seja > 16.9%.
3. **Validar se T3 > 18%:** Se sim, Cycle #10 precisa ser DEFENSIVE pesado, mesmo que isso signifique cortar cartas de medio EDHREC por fillers CMC 1-2.
4. **Aquisicao:** Priorizar Skullclamp. Mudaria fundamentalmente o perfil de draw do deck.

---

**Dados brutos:** knowledge.db deck_id=6 (100 cartas, 86 rows) + user_collection (229 cartas, 158 fora do deck) + EDHREC JSON API (7851 decks)

## [2026-05-31T17:33:01+00:00] Execucao #17 — Synergy-First Scout (Pos-Ciclo #9)

> **Data:** 2026-05-31T17:33:01+00:00
> **Deck state:** Pos-Ciclo #9 (23 swaps desde baseline). Motor 4/4, Copy 3/3, Sem Play T3=16.9% (Execucao #10, N=1000, seed=42)
> **Colecao:** 229 cartas (159 nao estao no deck)
> **Missao:** Buscar cartas com MALICIA — prioridade SINERGIA sobre EDHREC %. Identificar opcoes que CRIAM ou REFORCAM sinergias com o que ja existe.
> **Analista:** Hermes Agent — Lorehold Deep Scout

---

### PASSO 0: Deck Atual (deck_id=6, 100 cartas, 86 rows)

**Cartas nao-terra organizadas por CMC:**

| CMC | Cartas |
|:---:|:-------|
| 0 | Esper Sentinel (draw), Gamble (tutor) |
| 1 | Dragon's Rage Channeler, Enlightened Tutor, Faithless Looting, Land Tax, Library of Leng, Path to Exile, Sensei's Divining Top, Sol Ring, Swords to Plowshares, Weathered Wayfarer |
| 2 | Abrade, Arcane Signet, Boros Charm, Boros Signet, Grand Abolisher, Hexing Squelcher, Lightning Greaves, Ruby Medallion, Scroll Rack, Talisman of Conviction, Thrill of Possibility |
| 3 | Archaeomancer's Map, Bender's Waterskin, Chaos Warp, Deflecting Swat, Generous Gift, Jeska's Will, Monument to Endurance, Penance, Teferi's Protection, The Dawning Archaic, Valakut Awakening, Victory Chimes |
| 4 | Akroma's Will, Big Score, Longshot, Mizzix's Mastery, Olorin's Searing Light, Smothering Tithe, Storm-Kiln Artist, The One Ring, Unexpected Windfall, Wedding Ring |
| 5 | Arcane Bombardment, Double Vision, Fated Clash, Galvanoth, Lorehold (commander), Reforge the Soul, Taunt from the Rampart |
| 6 | Austere Command, Rite of the Dragoncaller, Surge to Victory |
| 7 | Approach of the Second Sun, Brass's Bounty, Emeria's Call, Hit the Mother Lode, Improvisation Capstone, Restoration Seminar, Volcanic Vision |
| 8 | Call Forth the Tempest, Dance with Calamity, Insurrection |
| 9 | Blasphemous Act |
| 10 | Storm Herd |

**Double-null cards (sem classificacao):**
- 🔴 Scroll Rack (CMC 2) — CORE ENGINE, nao cortar
- 🔴 Penance (CMC 3) — CORE ENGINE, nao cortar
- 🟡 Ruby Medallion (CMC 2) — declining -0.37, 3+ ciclos
- 🟢 Taunt from the Rampart (CMC 5) — 35.2% EDHREC, nao cortar
- 🟡 Grand Abolisher (CMC 2) — 11.7% EDHREC, declining -0.27
- ✅ Total: 5 double-nulls restantes (eram 10 no baseline)

---

### PASSO 1: Sinergias Existentes (Reconfirmadas)

| Camada | Cartas-chave | Status |
|:-------|:-------------|:-------|
| **Tesouro** | Big Score (67.3%), Brass's Bounty, Smothering Tithe (64.1%), Storm-Kiln (55.4%), Hit the Mother Lode (56.8%), Unexpected Windfall | 8 fontes |
| **Copia** | Lorehold (commander), Double Vision, Arcane Bombardment (42.5%), The Dawning Archaic (24.0%), Mizzix's Mastery | 4 camadas |
| **Topdeck** | Scroll Rack, Penance, Sensei's Top, Library of Leng | 4 pecas |
| **Spellslinger** | 20+ instants/sorceries | Denso |
| **Recursion** | Mizzix's Mastery, Arcane Bombardment, Volcanic Vision, Restoration Seminar (37.8%) | 4 pecas |
| **Token** | Storm Herd, Call Forth the Tempest (65.5%), Rite of the Dragoncaller, Surge to Victory, Akroma's Will, Hit the Mother Lode (treasure) | 6 criadores |
| **Protecao** | Teferi's Protection (49.7%), Boros Charm (indestrutivel), Deflecting Swat (55.4%), Lightning Greaves, Grand Abolisher (11.7%), Hexing Squelcher, Longshot (ward) | 6 pecas (talvez excesso) |
| **Board Wipe** | Austere Command (56.8%), Blasphemous Act (54.9%), Volcanic Vision, Call Forth the Tempest, Fated Clash | 5 pecas |
| **Wincon** | Approach of the Second Sun (55.2%), Insurrection (47.7%), Akroma's Will, Surge to Victory | 4 caminhos |
| **Draw** | The One Ring (8.5% in Lorehold, staple global), Wedding Ring, Victory Chimes (53.6%), Sensei's Top, Esper Sentinel (32.5% declining), Thrill of Possibility, Faithless Looting | 7 fontes |

**Gaps persistentes (pos-22-swaps):**
- **T3 elevado:** 16.9% ← DEFENSIVE zone (target < 12%)
- **Protecao excessiva:** 6 pecas (meta usa 3-4). Grand Abolisher (11.7% declining) e o mais fraco.
- **Cost reduction em declinio:** Ruby Medallion (-0.37, 3+ ciclos). Comunidade prefere Treasure.
- **Falta wincon de 1 turno:** Approach leva 2 turnos. Insurrection depende do board oponente. Surge to Victory precisa de setup.

---

### PASSO 2-3: Cartas Candidatas (Score A+B+C)

**Metodologia:**
- **A (SINERGIA 0-5):** Interage com camadas existentes? Cria nova opcao?
- **B (CUSTO 0-5):** Impacto no CMC medio, tipo de carta, slot que ocupa
- **C (EVIDENCIA 0-5):** EDHREC %, staple, dados externos

**Filtro:** Apenas cartas na user_collection (quantity > 0) E color identity dentro de RW (Lorehold = Boros)

#### SCORE >= 8 (Prioridade — recomendacao forte)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 1 | **Twinflame** | 2 | R | **8** | 3 | 5 | 0 | Cria copia de criatura → ataca com Surge to Victory (dobra poder) + Akroma's Will (double strike). Instant/Sorcery → alimenta Arcane Bombardment + Lorehold + Mizzix's Mastery. Sinergia DUAL: token+pump E recursion. |
| 2 | **Reverberate** | 2 | R | **8** | 3 | 5 | 0 | Copia qualquer instant/sorcery. Com Lorehold no campo: 1 spell → Lorehold copy → Reverberate copy do original → Lorehold copy do Reverberate = 4 copias totais. Alimenta Arcane Bombardment. Melhor que Dualcaster Mage (mesmo efeito, mas instant/sorcery em vez de creature — interage com todo o motor). |

#### SCORE 7 (Forte — considerar)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 3 | **Flare of Duplication** | 3 | R | **7** | 3 | 4 | 0 | Copia spell = FREE se controla commander (Lorehold). Efetivamente CMC 0 no late game. Instant → alimenta Bombardment. Levemente pior que Reverberate porque so copia seus proprios spells. |

#### SCORE 6 (Interessante — nice to have)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 4 | **Desperate Ritual** | 2 | R | **6** | 1 | 5 | 0 | Ritual classico — R in, RRR out. CMC 2, instant → bom para Bombardment/Lorehold. Mas ja temos Jeska's Will, Sol Ring, Land Tax. Redundante. |
| 5 | **Ephemerate** | 1 | W | **6** | 1 | 5 | 0 | Blink instantaneo. Re-usa ETB do Lorehold (draw), Dawning Archaic (copy), Storm-Kiln (treasure). CMC 1, instant. Mas e narrow — so funciona se tem criatura no campo. |

#### SCORE 5 (Monitorar — sidegrades defensaveis)

| # | Carta | CMC | Cor | Score | A | B | C | Por que |
|:-:|:------|:---:|:---:|:-----:|:-:|:-:|:-:|:--------|
| 6 | Spiteful Banditry | 2 | R | 5 | 2 | 3 | 0 | Treasure em board wipe — sinergia dupla. Mas e encantamento (nao interage com Bombardment). |
| 7 | Manaform Hellkite | 4 | R | 5 | 3 | 2 | 0 | Dragon token em cada noncreature spell. Com Bombardment = muitos tokens. Mas CMC 4, creature (nao interage com 60% do motor). |
| 8 | Jokulhaups | 6 | R | 5 | 2 | 3 | 0 | Com Teferi's Protection = wipe unilateral. CMC 6 pesado. |
| 9 | Terminus | 6 | W | 5 | 2 | 3 | 0 | Miracle W. Topdeck engine (Scroll Rack, Penance, Top) garante Miracle T3-T4. CMC efetivo = 1. Efeito = exile wipe (melhor que destroy). |
| 10 | Creative Technique | 5 | R | 5 | 2 | 3 | 0 | Demonstrate = copia spell gratis. CMC 5 caro mas efeito potente com Bombardment. |

#### SCORE < 5 (Ignorar — redundantes, anti-sinergicos, ou pioram T3)

Cartas como Solemn Simulacrum (CMC 4, sem sinergia), Archivist of Oghma (draw competindo com Wedding Ring), Descent into Avernus (acelera oponentes), Worldfire (CMC 9 sem protecao garantida), Fated Clash ja no deck, etc.

---

### PASSO 4: Analise Qualitativa

#### Por que Twinflame e Reverberate sao as MELHORES descobertas desta execucao:

1. **CMC 2 — nao pioram T3.** O deck esta em zona DEFENSIVE (T3=16.9%). Adicionar cartas CMC 2 mantem o early game estavel. Ambas podem ser jogadas no turno 2-3 sem comprometer o desenvolvimento.

2. **Sinergia MULTI-CAMADA.** Twinflame interage com 3 camadas simultaneamente:
   - Token (cria copia de criatura que ataca)
   - Pump (Surge to Victory dobra poder da copia; Akroma's Will buffa a copia)
   - Recursion (Lorehold, Arcane Bombardment, Mizzix's Mastery copiam o Twinflame)

3. **Reforcam o que o deck JA FAZ BEM.** O deck ja tem 4 camadas de copia. Twinflame/Reverberate adicionam a 5a e 6a camada, criando chains de copia exponenciais:
   - Lorehold copy → Twinflame copy → Surge to Victory copy → Akroma's Will dobra tudo = 4x copias de uma criatura com poder quadruplicado e double strike.

4. **NA mesa (na colecao) e COM color identity correta (R).** Ambas sao mono-red, legal em Lorehold.

#### Swap candidates (quem sai para dar lugar):

| Sai | CMC | Motivo | Entra | CMC | Delta CMC |
|:----|:---:|:-------|:------|:---:|:---------:|
| **Ruby Medallion** | 2 | Double-null, declining -0.37 (3+ ciclos). Cost reduction mediocre em deck de big spells (reduz 1 mana em spells de CMC 5-10 = impacto minimo). Treasure generation escala melhor. | **Twinflame** | 2 | **0** |
| **Grand Abolisher** | 2 | Double-null, 11.7% EDHREC, declining -0.27. Deck ja tem 5 outras protecoes (Teferi's, Boros Charm, Deflecting Swat, Greaves, Hexing Squelcher). Protecao excessiva. | **Reverberate** | 2 | **0** |
| Galvanoth | 5 | Spellslinger synergy mas CMC 5 criatura que raramente sobrevive. Efeito de "free spell do topo" ja coberto por Dance with Calamity + Improvisation Capstone. | **Flare of Duplication** | 3 | **-2** ⬇ DEFENSIVO |

**Net ΔCMC: 0 (Twinflame+Reverberate) ou -2 (com Flare of Duplication no lugar de Galvanoth)**

#### Cartas ILEGAIS encontradas na colecao (fora de color identity):

Nenhuma carta com U, B, ou G foi considerada. Todas as recomendacoes sao mono-R (dentro de Boros). Cartas como Deflecting Palm (M = multicolor RW), Boros Charm (M), Akroma's Will (W) ja estao no deck.

#### Colecao DEPLETADA para certos efeitos:

- **Draw engines CMC ≤ 3:** Esgotado. Wedding Ring (CMC 4) e The One Ring (CMC 4) sao as unicas opcoes na colecao e ja estao no deck.
- **Removal CMC ≤ 3:** Abrade, Chaos Warp, Path, Swords, Generous Gift ja no deck. Nao ha mais opcoes relevantes.
- **Ramp CMC ≤ 2:** Arcane Signet, Boros Signet, Talisman of Conviction, Sol Ring, Land Tax, Weathered Wayfarer — todos ja no deck.
- **Wincon de 1 turno CMC ≤ 5:** Nao existe na colecao. Godo+Helm, Dualcaster+Twinflame combos precisam de aquisicao.

#### Aquisicoes recomendadas (cartas NAO na colecao, mas que criariam sinergia nova):

| Carta | Funcao | Sinergia | Preco aprox |
|:------|:-------|:---------|:------------|
| **Skullclamp** | Draw engine CMC 1 | Mata token de Storm Herd/Rite of the Dragoncaller → draw 2 cartas | $10-15 |
| **Mana Vault** | Fast mana CMC 1 | Acelera T1-T2 para chegar em CMC 4-5 antes | $50-60 |
| **Underworld Breach** | Recursion massiva CMC 2 | Mizzix's Mastery alternativo, funciona com Faithless Looting, Thrill, Big Score | $15-20 |
| **Past in Flames** | Flashback massivo CMC 4 | Versao mono-red de recursion global — todo grave vira playable com Lorehold | $5-10 |

---

### RESUMO DO ESTADO DO DECK (Execucao #17)

| Aspecto | Status | Delta vs Exec #16 |
|:--------|:-------|:-----------------:|
| Ciclos aplicados | 9 (23 swaps desde baseline) | +1 (Ciclo #9: Pearl→Akroma's Will) |
| Motor Lorehold | 4/4 COMPLETO | Estavel |
| Copy layers | 4 ativas (Lorehold, Double Vision, Bombardment, Archaic) | Estavel |
| T3 (Execucao #10) | **16.9%** | +1.6pp vs Exec#9 ⚠ |
| Double-null count | 5 | Estavel |
| Cartas com EDHREC > 50% | ~28/63 (44%) | Estavel |
| Cartas 0% EDHREC | 0 | Estavel |
| Draw real | 7 fontes | Estavel |
| Protecao | 6 pecas | -1 (Pearl saiu, Akroma's Will entrou) |
| Strategy zone | **DEFENSIVE** (T3 > 12%) | Piorou vs BALANCED de C#8 |
| Colecao CMC ≤ 3 disponivel | **Esgotada** para draw/removal/ramp | Igual ao #16 |
| Sinergias NOVAS encontradas | 2 (Twinflame, Reverberate — copy layer expansion) | 🆕 |

---

### TOP 3 RECOMENDACOES PARA EVOLUTION ORACLE (Ciclo #10)

1. **Ruby Medallion → Twinflame** — Mesmo CMC (Δ=0). Substitui cost reduction (declining trend, double-null, impacto marginal em big spells) por copy engine que interage com 3 camadas (token, pump, recursion). Carta na colecao, quantity > 0. Cor: R (legal em Lorehold).

2. **Grand Abolisher → Reverberate** — Mesmo CMC (Δ=0). Substitui protecao redundante (6 pecas, declining trend 11.7% EDHREC) por spell copy que expande a camada de copia para 5 layers. Carta na colecao, quantity > 0. Cor: R (legal em Lorehold).

3. **Galvanoth → Flare of Duplication** — Net ΔCMC = -2 ⬇ DEFENSIVO. Galvanoth (CMC 5 creature) raramente sobrevive um turno; seu efeito de "free spell do topo" ja e coberto por Dance with Calamity + Improvisation Capstone. Flare of Duplication e CMC 3 (FREE com commander no campo) e dobra qualquer spell — incluindo Approach of the Second Sun para vitoria imediata (1o cast → Flare copy = 2 casts no mesmo turno, vence na hora).

**Estrategia recomendada: DEFENSIVE light (net ΔCMC = -2 a 0).**
- T3 = 16.9% esta na zona DEFENSIVE (target < 12%).
- Mas a colecao esta esgotada de cartas CMC ≤ 2 com alta sinergia.
- Recomendado: aplicar swap #3 (Galvanoth→Flare, ΔCMC=-2) para melhorar T3, e opcionalmente swaps #1 e #2 (ΔCMC=0) se quiser expandir a camada de copia.
- Melhor fazer -2 de CMC do que +2 como nos ultimos 2 ciclos.

---

### PROXIMOS PASSOS

1. **Evolution Oracle:** Avaliar swaps #1, #2, #3 para Ciclo #10 com estrategia DEFENSIVE.
2. **Mulligan Analyst:** Rodar Execucao #11 (N=1000, seed=42) para medir T3 pos-Ciclo #9 e validar a zona DEFENSIVE.
3. **Aquisicao:** Se nenhum swap for viavel (colecao esgotada), priorizar compra de Skullclamp ($10-15) — e a carta de maior impacto por menor custo para este deck.

---

**Dados brutos:** knowledge.db deck_id=6 (100 cartas, 86 rows) + user_collection (229 cartas, 159 fora do deck)

## [2026-05-31T14:13:39+00:00] Purpose Analyzer v3.8 — SYNERGY_MAP

**Tipo:** Analise profunda de sinergias (nao e scout EDHREC)
**Fonte:** knowledge.db deck_id=6 (pos-Ciclo #8, 22 swaps)
**Metodo:** Classificacao estrategica 1-5 + SYNERGY_MAP 5 eixos

### Resultados
- **86 cartas classificadas** por importancia real e funcao corrigida
- **5 combos mapeados** — 2 deterministicos (Approach+Topdeck, Surge+Approach)
- **SYNERGY_MAP completo:** Token+Pump (6/10), Wipes+Prot (8/10), Recursion (8/10), Mana (7/10), Combo (8/10)
- **Pearl Medallion: Nivel 1** — corte prioritario quando substituto disponivel
- **Draw real = 7** (perfil quer 8-12) — melhorou +2 desde v3.7
- **Motor 4/4, Copy 3/3, T3 = 3.7%** — deck saudavel
- **Recomendacao Ciclo #9:** Adquirir Skullclamp, Mana Vault. Sem aquisicoes: 0 swaps.

**Ver analise completa:** `VALIDATOR_LOG_v3.8.md` e `VALIDATOR_SUMMARY.md`

---

## [2026-05-31T14:05:47+00:00] Execucao #16 — Segundo Olhar: Cartas que o #15 Deixou Passar

> **Data:** 2026-05-31T14:05:47+00:00
> **Fonte EDHREC:** 7.802 decks (JSON API — identica a Execucao #15, sem mudancas)
> **Deck state:** Pos-Ciclo #7 (22 swaps). Motor 4/4, Copy 3/3, Sem Play T3=3.7%. Inalterado desde #15.
> **Missao:** Revisar a colecao com olhar FRESCO. A #15 foi excelente mas deixou 3+ cartas de alto impacto de fora.
> **Analista:** Hermes Agent — Lorehold Deep Scout

---

### Contexto

A Execucao #15 fez um trabalho excepcional identificando 15 cartas de sinergia na colecao.
O deck nao mudou e o EDHREC tambem nao. **Este scout e um "segundo olhar"** — re-examinar
a colecao inteira (159 cartas fora do deck) procurando o que a #15 pode ter subestimado
ou deixado passar.

**Metodologia:** Re-score manual de TODA a colecao com foco em:
1. Cartas que CRIAM um novo eixo de vitoria (nao so melhoram o existente)
2. Cartas que combinam 2+ funcoes em um slot
3. Cartas que a #15 nao listou no Top 15

---

### Sinergias Existentes (Reconfirmadas)

| Camada | Cartas-chave | Status |
|:-------|:-------------|:-------|
| **Tesouro** | Big Score, Brass's Bounty, Smothering Tithe, Storm-Kiln, Hit the Mother Lode, Unexpected Windfall | 8 fontes |
| **Copia** | Lorehold (commander), Double Vision, Arcane Bombardment | 3 camadas |
| **Topdeck** | Scroll Rack, Penance, Sensei's Top, Library of Leng | 4 pecas |
| **Spellslinger** | 20+ instants/sorceries | Denso |
| **Recursion** | Mizzix's Mastery, Arcane Bombardment, Volcanic Vision, Restoration Seminar | 4 pecas |
| **Token** | Storm Herd, Call Forth the Tempest, Rite of the Dragoncaller, Surge to Victory | 4 criadores |

**Gaps conhecidos (atualizados):**
- Draw real: 7 fontes (Boros estruturalmente limitado)
- Removal: 6 pecas (aceitavel)
- **Wincon explosivo:** Approach (CMC 7, 2 turnos) e Insurrection (CMC 8, requer board oponente). FALTA uma carta que transforma qualquer board em lethal imediato.
- **Tutor de interacao:** O deck tem respostas mas depende de compra-las. Falta um toolbox.

---

### Metodo de Scoring (mesmo da #15)

| Eixo | Range | Criterios |
|:-----|:-----:|:----------|
| **A — SINERGIA** | 0-5 | Cria nova camada? Multiplica engine? Combina 2+ funcoes? Interage com motor? |
| **B — CUSTO** | 0-5 | CMC baixo? Instant/sorcery? Nao compete com slots existentes? Nao piora T3? |
| **C — EVIDENCIA** | 0-5 | EDHREC %? Trend? Staple? Auto-evidente por sinergia? |

**Score >= 8:** Prioridade | **Score 5-7:** Nice to have | **Score < 5:** Ignorar

---

### CARTA #1: Akroma's Will — A Carta que a #15 NAO VIU (Score: 4+3+2 = 9)

| Atributo | Valor |
|:---------|:------|
| **CMC** | 4 |
| **Tipo** | Instant |
| **CI** | W |
| **EDHREC** | Nao aparece no top 277 de Lorehold (carta generica, nao especifica do commander) |
| **Na colecao?** | Sim (x1) |
| **No deck?** | NAO |

**Texto:** Creatures you control gain flying, vigilance, double strike, lifelink,
protection from all colors, and indestructible until end of turn.

**Por que a #15 nao viu:** Akroma's Will nao aparece no EDHREC de Lorehold (nao e carta
"do commander", e generica). A #15 usou EDHREC como um dos criterios de busca. Mas
Akroma's Will e uma staple de Commander — esta em TODO deck branco com criaturas.

**Por que e a MELHOR carta da colecao para este deck:**

O deck cria tokens massivos:
- Storm Herd (CMC 10): X Pegasus 1/1 onde X = seu life total (tipicamente 20-40)
- Call Forth the Tempest (CMC 8): dano em massa + dragoes
- Rite of the Dragoncaller (CMC 6): Dragon 5/5 por spell nao-criatura
- Surge to Victory (CMC 6): ja dobra o poder, mas so as atacantes

Com QUALQUER um destes resolvidos, Akroma's Will transforma um board de tokens em
**LETHAL IMEDIATO**. Double strike dobra o dano. Flying evita bloqueadores terrestres.
Protection from all colors torna o ataque inevitavel. Vigilance + lifelink = estabiliza
mesmo se nao matar.

**E instant speed.** Pode ser conjurada em resposta a um wipe, transformando o wipe
do oponente em uma janela para atacar sem blockers.

**Scoring:**
- **A=4:** +2 (nova opcao token+pump — a MELHOR combinacao de pump para token board)
  +1 (wincon ALTERNATIVA — diferente de Approach e Insurrection, e condicao de vitoria
  imediata com qualquer board de 3+ criaturas)
- **B=3:** CMC 4 substituindo CMC 2 (Pearl Medallion) = +2 CMC → -2. Instant (+0).
  Base 5, -2 = 3.
- **C=2:** Staple absoluto de Commander (+2). Nao tem dados especificos de Lorehold
  mas e auto-evidente para qualquer deck branco com criaturas.

**Score: 4+3+2 = 9** — 🔥 PRIORIDADE MAXIMA. A MELHOR carta da colecao que nao esta no deck.

---

### CARTA #2: Sunforger — Toolbox de Respostas (Score: 4+3+1 = 8)

| Atributo | Valor |
|:---------|:------|
| **CMC** | 3 (equip 3) |
| **Tipo** | Artifact — Equipment |
| **CI** | C |
| **EDHREC** | Staple Boros, nao especifico de Lorehold |
| **Na colecao?** | Sim (x1) |
| **No deck?** | NAO |

**Texto:** Equipped creature gets +4/+0. RW, Unattach Sunforger: Search your library for
a red or white instant card with mana value 4 or less and cast it without paying its mana cost.

**Por que a #15 nao viu:** E uma carta niche em spellslinger. O deck nao e de criaturas.
Mas Sunforger nao e sobre a criatura — e sobre o TOOLBOX.

**Alvos no deck atual (CMC <= 4, red/white instant):**
- Boros Charm (CMC 2) — indestrutivel ou double strike
- Deflecting Swat (CMC 3) — redireciona spell
- Chaos Warp (CMC 3) — removal universal
- Abrade (CMC 2) — removal de artefato ou 3 dano
- Generous Gift (CMC 3) — removal permanente
- Swords to Plowshares (CMC 1) — exile
- Path to Exile (CMC 1) — exile
- Teferi's Protection (CMC 3) — protecao suprema
- Thrill of Possibility (CMC 2) — draw
- Valakut Awakening (CMC 3) — draw massivo

**10 alvos validos no deck.** Sunforger transforma QUALQUER criatura em um tutor
instantaneo para a resposta certa. Comandante precisa de remocao? Swords/Path.
Alguem vai dar wipe? Boros Charm/Teferi's. Alguem vai counterar? Deflecting Swat.
Precisa de gas? Thrill/Valakut.

**Scoring:**
- **A=4:** +2 (cria toolbox de interacao — NOVA capacidade que o deck nao tem)
  +1 (draw engine condicional via Thrill/Valakut) +1 (wincon alternativa? Nao exatamente,
  mas permite buscar Boros Charm para double strike letal com tokens)
- **B=3:** CMC 3 (+1 sobre Pearl → -1). Equipment, nao instant/sorcery (-1).
  Base 5, -2 = 3.
- **C=1:** Staple classico em Boros Commander.

**Score: 4+3+1 = 8** — PRIORIDADE. Adiciona uma capacidade que o deck nao tem: buscar
a resposta certa no momento certo.

---

### CARTA #3: Invoke Calamity — Recursao Dupla Instantanea (Score: 4+3+0 = 7)

| Atributo | Valor |
|:---------|:------|
| **CMC** | 5 |
| **Tipo** | Instant |
| **CI** | R |
| **EDHREC** | Nao nos dados de Lorehold |
| **Na colecao?** | Sim (x1) |
| **No deck?** | NAO |

**Texto:** You may cast up to two instant and/or sorcery cards from your graveyard
this turn. If you do, exile them. They gain flashback until end of turn.

**Por que e relevante:** O deck tem 4 pecas de recursion (Mizzix's Mastery, Arcane
Bombardment, Volcanic Vision, Restoration Seminar). Mas TODAS sao sorcery speed.
Invoke Calamity e **instant speed** — pode ser usada no turno do oponente para
recastar Swords/Path + Chaos Warp, ou no seu turno para double Faithless Looting + Thrill.

**Sinergia com Arcane Bombardment:** Invoke Calamity e instant/sorcery, entao
Bombardment pode exila-la e recastar todo turno. Isso cria um loop de recursion
que se auto-alimenta.

**Scoring:**
- **A=4:** +2 (recursion chain — adiciona recursion a instant speed, stack com
  Arcane Bombardment para loop). +2 (combina 2+ funcoes: recursion + flashback enabler)
- **B=3:** CMC 5 (+3 sobre Pearl → -2). Instant (+0). Base 5, -2 = 3.
- **C=0:** Sem dados de EDHREC para Lorehold.

**Score: 4+3+0 = 7** — Nice to have. Poderosa mas CMC 5 compete com slots de big spell.

---

### CARTA #4: Bedlam Reveler — Draw 3 por RR (Score: 3+5+0 = 8)

| Atributo | Valor |
|:---------|:------|
| **CMC** | 8 (efetivo RR ~= 2) |
| **Tipo** | Creature — Devil Horror |
| **CI** | R |
| **EDHREC** | Nao nos dados |
| **Na colecao?** | Sim (x1) |
| **No deck?** | NAO |

**Texto:** Bedlam Reveler costs R less for each instant and sorcery in your graveyard.
Prowess. When ETB, discard your hand, then draw three cards.

**Por que a #15 nao viu:** CMC 8 impresso assusta. Mas o deck tem 30+ instants/sorceries.
Com 7+ no cemiterio (trivial apos Faithless Looting + Thrill + Big Score), custa so RR.
E o draw 3 e ANCESTRAL RECALL em Boros.

**Scoring:**
- **A=3:** +2 (draw engine — draw 3 por RR e excelente em Boros). O drawback "discard
  hand" nao e tao ruim — enche o cemiterio para Mizzix's Mastery e Arcane Bombardment.
  +1 (graveyard synergy — alimenta recursion)
- **B=5:** Custo efetivo RR = sem penalidade de CMC (0). Creature (-1). Mas o CUSTO
  REAL e RR = 2, nao piora T3. Replacing Pearl (CMC 2 → efetivo 2) = neutro. B=5.
  (O -1 por creature e compensado pelo custo efetivo baixo e a funcao "draw" que
  e rara em Boros)
- **C=0:** Sem dados.

**Score: 3+5+0 = 8** — PRIORIDADE. Draw 3 em Boros por 2 mana e um roubo.

---

### Re-Score das Escolhas da #15 (Segundo Olhar)

Confirmo as analises da #15, com ajustes pontuais de scoring:

| Carta | Score #15 | Score #16 | Nota |
|:------|:---------:|:---------:|:-----|
| Spiteful Banditry | 10 | **10** | ✅ Confirmado. Melhor wipe+ramp da colecao a CMC 2. |
| Reverberate | 11 | **10** | Ajuste: 4a camada de copy e redundante (ja temos 3). A=4 (nao 5). Score corrigido: 4+4+2=10. |
| Xorn | 8 | **9** | Ajuste: multiplica engine PRINCIPAL do deck. A=5 (maximo, cria camada NOVA de engine multiplication). Score corrigido: 5+2+2=9. |
| Guttersnipe | 8 | **8** | ✅ Confirmado. Spellslinger burn e wincon alternativa real. |
| Seize the Spoils | 9 | **8** | Ajuste: redundancia de Big Score, mas CMC 3 e pior. A=4 (nao 4 mas B=3, nao 3). Score: 4+3+1=8. |
| Flawless Maneuver | 9 | **9** | ✅ Confirmado. Protecao em massa gratis com commander. |
| Mother of Runes | 9 | **8** | Ajuste: nao cria sinergia, so protege. A=2, B=4, C=2 = 8. |
| Veronica | 8 | **7** | Ajuste: draw condicional em deck spellslinger nao e confiavel. A=4, B=2, C=1 = 7. |
| Palantir of Orthanc | 8 | **8** | ✅ Confirmado. Topdeck sinergia real. |
| Dualcaster Mage | 7 | **7** | ✅ Confirmado. Bom mas criatura a CMC 3 em deck spellslinger. |
| Mana Geyser | 8 | **8** | ✅ Confirmado. Explosivo em 4-player. |

---

### Top 8 Geral (Consolidado #15 + #16)

| # | Carta | CMC | Score | Por que |
|:-:|:------|:---:|:-----:|:--------|
| 1 | **Spiteful Banditry** | 2 | **10** | Wipe + ramp em 1 slot. CMC 2. Nao piora T3. |
| 2 | **Reverberate** | 2 | **10** | Copy spell CMC 2. Instant. Flexivel. |
| 3 | **Akroma's Will** | 4 | **9** | 🔥 NOVA — game-ender com token board. A MELHOR carta da colecao. |
| 4 | **Xorn** | 3 | **9** | Multiplica motor de treasure. 8 fontes viram 16+. |
| 5 | **Flawless Maneuver** | 3 (0) | **9** | Protecao em massa GRATIS com commander. |
| 6 | **Sunforger** | 3 | **8** | 🔥 NOVA — toolbox de 10 instants no deck. |
| 7 | **Bedlam Reveler** | 8 (RR) | **8** | 🔥 NOVA — Draw 3 por RR. Ancestral em Boros. |
| 8 | **Guttersnipe** | 8 | **8** | Spellslinger burn. Wincon alternativa. |

---

### Recomendacoes para o Evolution Oracle (Ciclo #8+)

**Contexto:** Apos 7 ciclos e 22 swaps, o deck esta saudavel (T3=3.7%, motor 4/4,
copy 3/3). O Ciclo #8 resultou em 0 swaps (nenhum candidato tinha Necessidade
Estrategica >= 3). A colecao esta esgotada de cartas CMC <= 3 com alto EDHREC.

**Novas opcoes de swap (cada swap requer justificativa estrategica):**

| Swap | Delta CMC | Justificativa |
|:-----|:---------:|:--------------|
| Pearl Medallion → Akroma's Will | +2 | Troca cost reduction (25.2%, declining) por game-ender. Pearl so afeta 23 white spells. Akroma's Will transforma qualquer token board em lethal. **Necessidade Estrategica: 4** (wincon alternativo). |
| Pearl Medallion → Spiteful Banditry | 0 | Troca cost reduction por wipe+ramp. CMC identico. Banditry preenche 2 gaps (removal + ramp). **Necessidade Estrategica: 4** (removal gap). |
| Ruby Medallion → Reverberate | 0 | Troca cost reduction (42.3% mas declining) por copy spell. Ruby afeta 35 red spells — util mas redundante com 12 outras fontes de ramp. **Necessidade Estrategica: 3** (copy redundancy). |
| Grand Abolisher → Sunforger | +1 | Troca protecao (11.7%, declining) por toolbox de interacao. **Necessidade Estrategica: 3** (tutor de respostas). |

**Cuidado com Delta CMC:** Akroma's Will (+2) piora T3, mas T3=3.7% tem MUITA folga
(limiar AGGRESSIVE e < 8%). Com T3 tao baixo, +2 e perfeitamente seguro.

**Por que nao recomendar todos de uma vez:** O deck ja recebeu 22 swaps. Cada swap
adicional tem custo de oportunidade maior. O Evolution Oracle deve escolher NO MAXIMO
2-3 destes, priorizando os que preenchem gaps (Banditry, Akroma's Will) sobre os que
adicionam redundancia (Reverberate, Sunforger).

---

### O Que a Colecao DEFINITIVAMENTE Nao Tem (Atualizado)

| Gap | Status | Alternativa |
|:----|:-------|:------------|
| Draw engines CMC <= 3 | ❌ Esgotado | Bedlam Reveler (efetivo RR) e a unica opcao nova. Veronica e Glint-Horn ja estao na lista da #15. |
| Copy spells CMC <= 2 | ❌ So Reverberate | Flare of Duplication (CMC 3) e Dualcaster Mage (CMC 3) sao as alternativas. |
| Board wipes CMC <= 4 | ❌ So Spiteful Banditry e Chain Reaction | Ambos niche. |
| Wincon explosivo (token payoff) | ❌ So Akroma's Will | Nao ha segunda opcao. |

---

### Dados Brutos

- EDHREC JSON API: 7.802 decks (identico a #15)
- knowledge.db: deck_id=6, 86 rows, SUM(qty)=100
- user_collection: 229 cartas com quantity > 0, 159 fora do deck
- Double-null cards no deck: 6 (Grand Abolisher, Pearl Medallion, Penance, Ruby Medallion, Scroll Rack, Taunt from the Rampart)
- Swaps aplicados desde baseline: 22 (C#1:3, C#2:3, C#3:5, C#4:3, C#5:3, C#6:2, C#7:1, C#8:0)

---

### Licoes Desta Execucao

1. **A #15 foi 85% correta mas perdeu a carta mais impactante.** Akroma's Will e um
   game-ender que transforma a estrategia de tokens do deck em lethal imediato. Nao
   aparecer no EDHREC de Lorehold nao significa que nao e relevante — significa que
   e uma staple generica, nao uma carta "do commander".

2. **Sunforger e um toolbox que o deck nao sabia que precisava.** Com 10 alvos validos
   no deck, Sunforger transforma qualquer criatura em um tutor instantaneo. Em um deck
   que depende de comprar as respostas certas, isso e uma capacidade NOVA.

3. **A colecao tem MAIS cartas boas do que parecia.** A #15 encontrou 15. Esta execucao
   adicionou 3 (Akroma's Will, Sunforger, Bedlam Reveler). Total: 18 cartas com score >= 7
   na colecao fora do deck. O gargalo nao e falta de opcoes — e que o deck ja esta
   muito bom e cada swap adicional tem custo de oportunidade crescente.

4. **O "esgotamento da colecao" e real para draw engines e copy spells baratos,**
   mas NAO para wincons alternativos e toolbox de interacao. Ha cartas nao-obvias
   que merecem atencao.

5. **Segundo olhar e essencial.** Um unico scout, por mais completo que seja, sempre
   tem vies. A #15 priorizou cartas que APARECEM no EDHREC ou tem sinergia OBVIA
   (Xorn, Spiteful Banditry). Esta execucao encontrou cartas que exigem um entendimento
   mais profundo do deck (Akroma's Will requer saber que o deck cria tokens; Sunforger
   requer conhecer a lista de instants no deck).


## [2026-05-31T13:26:39+00:00] Execucao #15 — Scout de Sinergias Ocultas (Colecao Esgotada de Alto EDHREC)

> **Data:** 2026-05-31T13:26:39+00:00
> **Fonte EDHREC:** 7.802 decks (JSON API, snapshot estavel — sem mudancas significativas)
> **Deck state:** Pos-Ciclo #7 (22 swaps aplicados desde baseline). Motor 4/4, Copy 3/3, Sem Play T3=3.7%.
> **Missao especial:** Buscar cartas de SINERGIA na colecao, nao so EDHREC%.
> **Analista:** Hermes Agent — Lorehold Deep Scout

---

### Contexto Estrategico

Apos 7 ciclos de otimizacao (22 swaps), o deck atingiu um estado saudavel:
- Motor 4/4 completo, Copy 3/3, Sem Play T3 = 3.7% (excelente)
- 0 cartas nao-terra a 0% EDHREC
- 62.9% das cartas nao-terra >= 30% EDHREC
- Colecao **esgotada de cartas CMC <= 3 com alto EDHREC** — as melhores ja estao no deck

**Pergunta desta execucao:** A colecao tem cartas que nao aparecem no EDHREC (niche, sinergicas)
mas que CRIAM ou REFORCAM sinergias com o deck existente? Scouts anteriores priorizaram
EDHREC%. Esta execucao inverte a prioridade: **sinergia primeiro, EDHREC depois.**

---

### Sinergias Existentes no Deck (Baseline para scoring)

O deck atual tem 5 camadas de sinergia ativas:

| Camada | Cartas-chave | Descricao |
|:-------|:-------------|:----------|
| **Tesouro** | Big Score, Brass's Bounty, Smothering Tithe, Storm-Kiln, Hit the Mother Lode, Unexpected Windfall | 8 fontes de treasure — maior densidade do deck |
| **Copia** | Lorehold (commander), Double Vision, Arcane Bombardment | 3 camadas de copy (commander + 2 enchantments) |
| **Topdeck** | Scroll Rack, Penance, Sensei's Top, Library of Leng | 4 pecas de manipulacao de topo |
| **Spellslinger** | 20+ instants/sorceries. Dance with Calamity, Improvisation Capstone, Mizzix's Mastery | O deck quer conjurar spells grandes de graca |
| **Recursion** | Mizzix's Mastery, Arcane Bombardment, Volcanic Vision, Restoration Seminar | 4 pecas de recursion do grave |

**Gaps conhecidos:**
- Draw real: 7 fontes (Boros estruturalmente limitado, compensado por topdeck)
- Removal: 6 pecas (aceitavel, Chaos Warp adicionou remocao universal)
- Wincon alternativo: so Approach + Insurrection (poderia ter spellslinger burn)

---

### Metodo de Scoring

Cada carta da colecao (quantity > 0, nao no deck) avaliada em 3 eixos:

| Eixo | Range | Criterios |
|:-----|:-----:|:----------|
| **A — SINERGIA** | 0-5 | Cria nova camada? Multiplica engine? Combina 2+ funcoes? Interage com motor? |
| **B — CUSTO** | 0-5 | CMC baixo? Instant/sorcery? Nao compete com slots existentes? Nao piora T3? |
| **C — EVIDENCIA** | 0-5 | EDHREC %? Trend? Staple? Auto-evidente por sinergia? |

**Score >= 8:** Prioridade (recomendar ao Evolution Oracle)
**Score 5-7:** "Nice to have" (documentar, nao priorizar)
**Score < 5:** Ignorar

---

### Top 15 Cartas por Sinergia

#### TIER 1 — Criam NOVA Camada de Sinergia (Score >= 9)

| # | Carta | CMC | Score (A+B+C) | EDHREC | Funcao | Sinergia |
|:-:|:------|:---:|:------------:|:------:|:-------|:---------|
| 1 | **Xorn** | 3 | **5+2+1=8** | 0% | Creature — Doubles treasures | 🔥 MULTIPLICA o motor de treasure. Com 8 fontes, cada Big Score vira 4 treasures, Brass's Bounty vira 14-20. Camada NOVA de engine multiplication. |
| 2 | **Spiteful Banditry** | 2 | **5+4+1=10** | 0% | Enchantment — Board wipe gera treasures | 🔥 COMBINA removal + ramp em 1 carta. Mata criaturas dos oponentes e transforma em mana SUA. CMC 2. Preenche gap de removal E adiciona ramp. |
| 3 | **Guttersnipe** | 3 | **3+2+3=8** | 32.3% | Creature — 2 dmg por spell | Cria wincon alternativa (spellslinger burn). Com Lorehold copy, cada spell = 4 dmg por oponente. 20+ spells = 80 dmg potencial. |
| 4 | **Reverberate** | 2 | **5+4+2=11** | 18.0% | Instant — Copy spell | Adiciona 4a camada de copy ao deck. CMC 2, instant speed, copia spell de QUALQUER jogador (removal, counter, draw). Flexibilidade maxima. |
| 5 | **Veronica, Dissident Scribe** | 3 | **5+2+1=8** | 0% | Creature — Draw + treasure on spell cast | DUAS funcoes em uma: draw E ramp no trigger de conjurar spell (acao primaria do deck). Draw condicional mas recorrente. |

#### TIER 2 — Reforcam Sinergias Existentes (Score 7-8)

| # | Carta | CMC | Score (A+B+C) | EDHREC | Funcao | Sinergia |
|:-:|:------|:---:|:------------:|:------:|:-------|:---------|
| 6 | **Seize the Spoils** | 3 | **4+3+2=9** | 16.6% | Sorcery — Rummage + treasure | Mini Big Score. CMC 3 (vs Big Score CMC 4). Rummage + treasure. Flashback com Big Score. Mais redundancia de treasure ramp barato. |
| 7 | **Glint-Horn Buccaneer** | 3 | **4+2+1=7** | 9.0% | Creature — Draw + ping on discard | Transforma Faithless Looting, Thrill, Big Score rummage em DRAW EXTRA. Cada discard = draw 1 + ping 1. Cria motor de draw via discard. |
| 8 | **Palantir of Orthanc** | 3 | **5+2+1=8** | 0% | Artifact — Scry 2 + opponent paga vida ou vc draw | Sinergia DIRETA com Scroll Rack + Penance. Coloque Big Spell no topo (CMC 7-8) = oponente toma 7-8 de dano OU voce draw. Topdeck vira arma. |
| 9 | **Dualcaster Mage** | 3 | **3+2+2=7** | 17.0% | Creature — Copy spell ETB | Redundancia de copy. Flash. Pode copiar spell propria ou do oponente. Corpo 2/2 irrelevante — o ETB e o que importa. |
| 10 | **Mana Geyser** | 5 | **4+2+2=8** | 26.2% | Sorcery — Add R per tapped land opponents control | Em 4-player, rotineiramente 15-25 red mana. Alimenta X spells (Call Forth the Tempest) ou Dance with Calamity. BIG mana explosivo. |

#### TIER 3 — Protecao Eficiente (Score 7-8)

| # | Carta | CMC | Score (A+B+C) | EDHREC | Funcao | Sinergia |
|:-:|:------|:---:|:------------:|:------:|:-------|:---------|
| 11 | **Flawless Maneuver** | 3 (0) | **2+5+2=9** | 19.8% | Instant — Indestrutivel (gratis com commander) | CMC efetivo 0 com Lorehold em jogo. Protecao em massa gratis. Stack com Boros Charm ou Teferi's. |
| 12 | **Mother of Runes** | 1 | **2+4+3=9** | 34.5% | Creature — Protection a uma criatura | CMC 1. Protege Lorehold ou Storm-Kiln. Staple classico. Nao cria sinergia nova mas e eficiente. |

#### TIER 4 — Spellslinger Adicional (Score 6-7)

| # | Carta | CMC | Score (A+B+C) | EDHREC | Funcao | Sinergia |
|:-:|:------|:---:|:------------:|:------:|:-------|:---------|
| 13 | **Fiery Inscription** | 3 | **3+2+1=6** | 5.7% | Enchantment — 2 dmg por spell | Versao enchantment do Guttersnipe. Mais dificil de remover. Stack com Guttersnipe = 4 dmg/spell. |
| 14 | **Caldera Pyremaw** | 5 | **3+1+3=7** | 30.2% | Creature — Pinger + treasure on death | Dois em um: spellslinger burn + treasure. CMC 5 e caro, mas deixa treasure ao morrer. |
| 15 | **Flare of Duplication** | 3 (0) | **4+2+1=7** | 6.9% | Instant — Copy spell (gratis sacrificando criatura vermelha) | Flexivel: CMC 3 normal ou gratuito com sac. Copia spell propria ou do oponente. |

---

### Notas sobre Cartas Fora do EDHREC

**12 das 15 cartas no Top 15 tem EDHREC < 20%.** Destas, 6 tem **0% EDHREC**:

| Carta | Score | Por que 0% EDHREC | Mesmo assim relevante? |
|:------|:-----:|:------------------|:----------------------|
| Xorn | 8 | Niche — so aparece em decks de treasure dedicado | **SIM** — deck tem 8 fontes de treasure. Multiplicacao e obvia. |
| Spiteful Banditry | 10 | Carta recente (OTJ), ainda nao amplamente adotada | **SIM** — wipe + treasure e combinacao rara. Alta sinergia. |
| Veronica | 8 | Carta niche de spellslinger | **SIM** — draw + treasure no trigger certo. |
| Palantir of Orthanc | 8 | Nao e staple em Boros | **SIM** — topdeck sinergia existe no deck. |
| Twinflame | 8 | Copy de criatura em deck spellslinger | **PARCIAL** — deck tem poucas criaturas para copiar. |
| Fiery Inscription | 6 | Enchantment niche | **TALVEZ** — efeito bom mas lento. |

**Regra:** Cartas com 0% EDHREC mas sinergia auto-evidente (score A >= 4) NAO devem ser descartadas
so por falta de dados. O scout existe exatamente para encontrar estas cartas.

---

### Colecao: O Que REALMENTE Vale a Pena

Apos 22 swaps, a colecao esta **esgotada de staples com alto EDHREC**. Mas esta **RICA em cartas
de sinergia niche que EDHREC nao captura**. As 5 cartas que MAIS adicionariam ao deck:

| # | Carta | CMC | Funcao | Por que |
|:-:|:------|:---:|:-------|:--------|
| 1 | **Spiteful Banditry** | 2 | Wipe + Ramp | Preenche 2 gaps simultaneamente. CMC 2 = nao piora T3. Unica. |
| 2 | **Reverberate** | 2 | Copy | 4a camada de copy. CMC 2, instant. Flexivel (sua OU do oponente). |
| 3 | **Xorn** | 3 | Treasure Doubler | Multiplica motor principal. 8 fontes viram 16+. Cria turns explosivos. |
| 4 | **Guttersnipe** | 3 | Spellslinger Burn | Wincon alternativa. 4 dmg/spell com Lorehold. Stack com Double Vision = 6/spell. |
| 5 | **Seize the Spoils** | 3 | Rummage + Treasure | Treasure ramp barato. Redundancia de Big Score a CMC menor. |

**Swap candidates (se o Evolution Oracle quiser aplicar):**
- Pearl Medallion (CMC 2, 25.2% trend -0.46) → Spiteful Banditry (CMC 2): troca cost reduction por wipe+ramp
- Ruby Medallion (CMC 2, 42.3% trend -0.37) → Reverberate (CMC 2): troca cost reduction por copy
- Grand Abolisher (CMC 2, 11.7% trend -0.27) → Guttersnipe (CMC 3): troca protecao por wincon alternativa

**Delta CMC: +1** (seguro, T3=3.7% permite)

---

### O Que A Colecao NAO Tem

**Gap confirmado: nao ha mais draw engines baratas (CMC <= 3) na colecao.**
Veronica (CMC 3, draw condicional) e a unica. Glint-Horn (CMC 3, draw via discard) e a segunda.
Nao ha Faithless Looting #2, nem mais rummage spells.

**Gap confirmado: nao ha mais copy spells alem de Reverberate, Dualcaster Mage, Flare of Duplication.**
Twinflame copia criaturas (deck tem poucas). As 3 acima sao as unicas opcoes de copy spell na colecao.

**Gap confirmado: nao ha mais board wipes baratos (CMC <= 4).**
Spiteful Banditry (CMC 2) e Chain Reaction (CMC 4) sao os unicos. Ambos sao niche.

---

### Dados Brutos

- EDHREC JSON API: 7.802 decks, 277 cards trackeados
- knowledge.db: deck_id=6, 86 rows, SUM(qty)=100
- user_collection: 229 cartas com quantity > 0, 159 fora do deck
- Double-null cards no deck: 6 (Grand Abolisher, Pearl Medallion, Penance, Ruby Medallion, Scroll Rack, Taunt from the Rampart)

---

### Licoes Desta Execucao

1. **EDHREC e um espelho retrovisor — mostra o que a comunidade JA joga, nao o que DEVERIA jogar.** Cartas como Xorn (0% EDHREC) e Spiteful Banditry (0% EDHREC) tem sinergia OBVIA com o deck mas nao aparecem no EDHREC porque sao niche ou recentes. O scout por sinergia encontra cartas que o scout por EDHREC perde.

2. **A colecao nao esta verdadeiramente esgotada — esta esgotada de HIGH-EDHREC, mas tem cartas de SINERGIA.** Das 159 cartas na colecao fora do deck, 12 tem score de sinergia >= 8. Nenhuma delas foi considerada em ciclos anteriores porque o criterio era EDHREC > 30%.

3. **Spiteful Banditry e a descoberta mais interessante.** CMC 2, combina wipe + ramp, na colecao, nao estava sendo considerada. E um "two-for-one" funcional que preenche 2 gaps simultaneamente.

4. **Reverberate a CMC 2 e melhor que Dualcaster Mage a CMC 3 para este deck.** Ambas copiam spells, mas Reverberate e instant/sorcery (sinergia com Lorehold copy, Arcane Bombardment, Mizzix's Mastery). Dualcaster e criatura — nao interage com o motor de spells.

5. **Guttersnipe (32.3% EDHREC) cria uma wincon que o deck nao tem: spellslinger burn.** Com 20+ spells, cada uma causando 4 dmg por oponente (com Lorehold copy), e uma alternativa real ao Approach of the Second Sun e Insurrection. Stack com Double Vision = 6/spell, Arcane Bombardment = 8/spell.

6. **Palantir of Orthanc e o "quinto elemento" do topdeck.** O deck ja tem Scroll Rack + Penance + Top + Library of Leng. Palantir transforma essa engine de setup em engine de dano OU draw. O oponente escolhe: tomar 7-8 de dano (CMC da big spell no topo) OU deixar voce comprar. Win-win.


---

## [2026-05-31] Execução #14 — Post-Ciclo #5 Deep Analysis + Ciclo #6 Prep

> **Data:** 2026-05-31
> **Fonte EDHREC:** 7.802 decks (JSON API, 2026-05-31)
> **Deck state:** Pós-Ciclo #5 (19 swaps applied since baseline)
> **Analista:** Hermes Agent — Lorehold Deep Scout

### Contexto

O EDHREC data é **numericamente idênticu à Execução #13** (mesmo snapshot de 7.802 decks,
todas as mudanças ≤0.2pp). Seguindo a regra do skill: quando dados são idênticos,
**mudar para análise qualitativa** — não re-reportar números.

Foco desta rodada: **Entender o estado pós-Ciclo #5 e preparar recomendações defensivas
para Ciclo #6**, com base nas tendências, gaps, e evolução do meta.

---

# SCOUT_LOG: Lorehold Deep Scout — Meta Analysis

> **Archived:** Entries 1-10 moved to SCOUT_LOG_ARCHIVE_2026-05-31.md
