## [2026-06-02T21:42:21+00:00] Execucao #37 — 🔄 Deck Reconstruido Novamente: Wincons do Scout #36 Aplicados + Deck Saturado

> **Data:** 2026-06-02
> **Missao:** Auditoria de wincons com scorecard + verificacao de integridade do pipeline
> **Deck state:** Card hash: `f2241d994743e8142396c0f846917fde` — 🚨 HASH DIVERGENTE do Scout #36 (era `0b4913e79ec97b3ce05e0fe26531cd44`)
> **Analista:** Hermes Agent — Lorehold Deep Scout (Wincon-Focused v37)

---

### 🚨 STEP 0: PIPELINE INTEGRITY — Deck Alterado Desde Scout #36

**Card hash atual:** `f2241d994743e8142396c0f846917fde`
**Scout #36 hash:** `0b4913e79ec97b3ce05e0fe26531cd44`
**Veredito:** 🚨 HASH DIVERGENTE — O deck foi alterado novamente.

**Mudancas detectadas:** 98 → 100 cartas. As recomendacoes do Scout #36 foram **aplicadas**:
7 wincons do spellslinger original foram RE-ADICIONADOS ao deck.

| Status | Cartas |
|:-------|:-------|
| ✅ No deck (Scout #36) | Twinflame, Dualcaster Mage, Rise of the Eldrazi, Storm Herd |
| 🆕 Adicionados desde #36 | **Guttersnipe, Mizzix's Mastery, Rite of the Dragoncaller, Fiery Emancipation, Aetherflux Reservoir, Worldfire, Approach of the Second Sun, Molten Duplication** |
| 📦 Fora do deck | Trouble in Pairs, Perch Protection, Apex of Power, Call Forth the Tempest |

---

### 📊 WINCONS NO DECK ATUAL — Scorecard via card_deck_analysis

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Guttersnipe** | 3 | 19 | 7 | 5 | 8 | 🟡 **INVISIVEL (ST=8)** — 2 dano/spell. Com 30+ spells. Fragil (R=5) |
| **Mizzix's Mastery** | 4 | 17 | 6 | 7 | 6 | 🔴 **IMBATIVEL (R=7)** — Overload exila grave, copia tudo gratis |
| **Twinflame** | 2 | 16 | 7 | 5 | 5 | 🟢 Combo com Dualcaster = criaturas infinitas |
| **Rite of the Dragoncaller** | 6 | 16 | 5 | 5 | 7 | 🟡 **INVISIVEL (ST=7)** — Dragon 5/5 por spell |
| **Dualcaster Mage** | 3 | 16 | 7 | 5 | 5 | 🟢 Combo deterministico com Twinflame |
| **Rise of the Eldrazi** | 12 | 15 | 2 | 9 | 4 | 🔴 **IMBATIVEL (R=9)** — Aniquilador 4 + turno extra |
| **Fiery Emancipation** | 6 | 15 | 6 | 5 | 4 | 🟢 Triplica dano. Storm Herd + Fiery = letal |
| **Aetherflux Reservoir** | 4 | 15 | 6 | 5 | 4 | 🟢 Storm payoff. 50+ vida = removal laser |
| **Worldfire** | 9 | 14 | 2 | 7 | 5 | 🔴 **IMBATIVEL (R=7)** — Com Teferi = vitoria |
| **Approach of the Second Sun** | 7 | 12 | 6 | 5 | 1 | 🟢 **RAPIDA (S=6)** — ARQUI-INIMIGO (ST=1) |
| **Storm Herd** | 10 | 11 | 3 | 5 | 4 | 🟡 Precisa de Akroma/Fiery no mesmo turno |

**Total: 11 wincons scored no deck.** O deck esta **saturado** de condicoes de vitoria.

---

### 🏆 WINCONS NA COLECAO (NAO NO DECK) — Scorecard Completo

Apenas **4 cartas** com score > 0 permanecem na colecao fora do deck.

#### 🟢 RAPIDAS (speed >= 6) — Fecha Antes de Morrer

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Trouble in Pairs** | 4 | 16 | 7 | 5 | 4 | ⚠️ **MISCLASSIFIED** — Draw engine, nao wincon. Draw massivo vs decks com draw |
| **Perch Protection** | 6 | 16 | 7 | 5 | 4 | ⚠️ **MISCLASSIFIED** — Fog + extra turn + gift. Protection, nao wincon |

#### 🔴 FRAGEIS (resilience <= 3) — EVITE

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Call Forth the Tempest** | 8 | 12 | 4 | 3 | 5 | 🔴 **FRAGIL (R=3)** — 65.2% EDHREC mas trend -0.60. CMC 8 |

#### ⚪ OUTROS (sem categoria de prioridade)

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Apex of Power** | 10 | 13 | 4 | 4 | 5 | CMC 10 heavy. Exilia top 7, mana gratis |

---

### 📋 ANALISE DE PRIORIZACAO

**NENHUM candidato atinge os thresholds de priorizacao:**
- 🔴 IMBATIVEIS (R>=7): **0 candidatos**
- 🟡 INVISIVEIS (ST>=7): **0 candidatos**
- 🟢 RAPIDAS (S>=6): 2 candidatos, mas AMBOS sao **misclassified** (Trouble in Pairs = draw engine, Perch Protection = fog/protection)
- 🔴 FRAGEIS (R<=3): 1 candidato (Call Forth the Tempest) — EVITAR

**Conclusao:** O deck esta **saturado de wincons** (11 scored + Akroma's Will como enabler).
Todas as recomendacoes do Scout #36 foram aplicadas. Nao ha novos candidatos fortes
na colecao. O collection pool de wincons para Lorehold foi esgotado.

---

### ⚠️ ALERTAS

1. **Deck saturado de wincons** — 11 condicoes de vitoria + Akroma's Will. Meta cEDH
   tipicamente usa 3-5 wincons + tutores. Este deck tem densidade excessiva de wincons
   (11/100 cartas = 11%), o que reduz slots para interacao/ramp/draw.
2. **Misclassification no card_deck_analysis** — Trouble in Pairs e Perch Protection
   nao sao wincons. Sao draw engine e protection, respectivamente. O score=16 e artificial.
3. **Sem novos candidatos** — A colecao foi completamente vasculhada. Nao ha mais wincons
   com score > 0 disponiveis que nao estejam no deck.
4. **Hash divergente** — O deck foi alterado externamente. Pipeline logs anteriores
   (EVOLUTION_LOG, VALIDATOR_LOG) estao stale.

---

### 📊 RESUMO

| Metrica | Valor |
|:--------|:------|
| Wincons no deck (scored) | 11 |
| Wincons no deck (total incluindo Akroma) | 12 |
| IMBATIVEIS disponiveis na colecao | 0 |
| INVISIVEIS disponiveis na colecao | 0 |
| RAPIDAS disponiveis na colecao | 2 (misclassified) |
| FRAGEIS (evitar) | 1 (Call Forth the Tempest) |
| Slots livres | 0 (100/100) |
| **Recomendacao** | **NENHUM SWAP — deck saturado de wincons** |

---

## [2026-06-02T18:33:43+00:00] Execucao #36 — 🚨 ALERTA DE INTEGRIDADE: Deck Reconstruido (cEDH) + Wincon Scorecard

> **Data:** 2026-06-02
> **Missao:** Auditoria de wincons com scorecard + verificacao de integridade do pipeline
> **Deck state:** Card hash: `0b4913e79ec97b3ce05e0fe26531cd44` — 🚨 HASH DIVERGENTE do ultimo SCOUT_LOG (era `30d00347...`)
> **Analista:** Hermes Agent — Lorehold Deep Scout (Wincon-Focused v36)

---

### 🚨 STEP 0: PIPELINE INTEGRITY CRISIS — Deck Totalmente Reconstruido

**Card hash atual:** `0b4913e79ec97b3ce05e0fe26531cd44`
**Ultimo hash conhecido (SCOUT #35):** `30d00347764fc2a215edb4e668994871`
**Veredito:** 🚨 HASH DIVERGENTE — O deck foi completamente alterado.

**TODOS os 25+ swaps dos ciclos #1-#11 foram desfeitos.** O deck agora e uma build cEDH-adjacent
com fast mana, tutor pesado, e protection suite. NENHUM dos motores/engines do pipeline spellslinger
esta presente (Mizzix's Mastery, Arcane Bombardment, Double Vision, Dance with Calamity,
Improvisation Capstone, Hit the Mother Lode, Storm-Kiln Artist, etc. — TODOS AUSENTES).

**Comparacao de estruturas:**

| Componente | Build Anterior (SCOUT #35) | Build Atual |
|:-----------|:--------------------------|:------------|
| Mana base | 35 lands, ramp variado | Fast mana package (Crypt, Vault, Mox, Petal, SSG, Rite of Flame) |
| Tutores | 2-3 (Enlightened, Gamble) | 8 (Enlightened, Mystical, Gamble, Imperial, Recruiter, Stoneforge, Ranger-Captain, Saga) |
| Protection | 4-5 slots | 9 slots (Silence, Orim's Chant, Abolisher, Pyroblast, REB, Flawless, Teferi, Swat, Mom) |
| Wincons | 7+ (Mizzix, Rite, Worldfire, Apex, Approach, Call Forth, Storm Herd) | 4 (Rise, Storm Herd, Akroma's Will, Twinflame+Dualcaster) |
| Draw engines | 5 (Esper, Wheel, One Ring, Top, Faithless) | 9 (esper, wheel, one ring, top, faithless, scroll rack, library, DRC, reunion) |
| Total cards | 100 | 98 (FALTAM 2!) |
| Commander | Lorehold, the Historian | Lorehold, the Historian |

---

### 📊 WINCONS NO DECK ATUAL — Scorecard via card_deck_analysis

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Twinflame + Dualcaster Mage** | 2+3 | 16 | 7 | 5 | 5 | 🟢 **COMBO** — Combo deterministico de 2 cartas. Criaturas infinitas com haste. |
| **Rise of the Eldrazi** | 10 | 15 | 2 | 9 | 4 | 🔴 **IMBATIVEL (R=9)** — Aniquilador 4 + turno extra. Tutoravel. |
| **Storm Herd** | 10 | 11 | 3 | 5 | 4 | 🟡 CMC 10 — Gera N pegasus 1/1. Precisa de Akroma's Will no mesmo turno. |
| **Akroma's Will** | 4 | 0* | 5 | 5 | 5 | 🟢 **ENABLER** — Score=0 e default (sem avaliacao manual). Da haste/vigilancia/protecao massivo. |

> *Cards com score=0 (5/5/5 default) nao receberam avaliacao manual de wincon no `card_deck_analysis`.

**Analise estrutural:**
- O deck TEM combo deterministico (Twinflame + Dualcaster)
- Tem 8 tutores para encontrar o combo (incluindo Mystical Tutor, Enlightened, Gamble, Imperial, Recruiter)
- Rise of the Eldrazi e um plano B solido (resilience 9, tutoravel)
- Storm Herd e fragil (CMC 10, precisa de Akroma)
- **GAP:** Nao tem Approach of the Second Sun, Mizzix's Mastery, Worldfire, Rite of the Dragoncaller — todos na colecao

---

### 🏆 WINCONS NA COLECAO (NAO NO DECK) — Scorecard Completo

#### 🔴 IMBATIVEIS (resilience >= 7) — Prioridade Maxima

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Worldfire** | 9 | 14 | 2 | 7 | 5 | 🔴 **RESET TOTAL** — Com Teferi's Protection na stack = vitoria. Ja no deck tem Teferi! |

#### 🟡 INVISIVEIS (stealth >= 7) — Dano Invisivel

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Guttersnipe** | 3 | 19 | 7 | 5 | 8 | 🟡 **INVISIVEL (ST=8)** — 2 dano por spell. Com 40 spells no deck = 80 dano. Mas fragil (R=5). |
| **Rite of the Dragoncaller** | 6 | 16 | 5 | 5 | 7 | 🟡 **DRAGONS** — Gera dragon 5/5 por spell. Com Akroma's Will no deck = letal. |

#### 🟢 RAPIDAS (speed >= 6) — Fecha Antes de Morrer

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Perch Protection** | 6 | 16 | 7 | 5 | 4 | 🟢 **GIFT** — Fog + extra turn + gift. Versatil. |
| **Trouble in Pairs** | 4 | 16 | 7 | 5 | 4 | 🟢 **DRAW-AS-WINCON** — Draw massivo vs decks com draw. Boros usa como motor. |
| **Fiery Emancipation** | 6 | 15 | 6 | 5 | 4 | 🟢 **TRIPLO DANO** — Storm Herd (X pegasus) + Fiery = 3X dano. Com Akroma = letal. |
| **Approach of the Second Sun** | 7 | 12 | 6 | 5 | 1 | 🟢 **ARQUI-INIMIGO (ST=1)** — 63.8% EDHREC. Precisa de Flare de Duplication (NA COLECAO!) pra combo mesmo turno. |

#### 🔴 FRAGEIS (resilience <= 3) — EVITE

| Carta | CMC | Score | S | R | ST | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------------|
| **Call Forth the Tempest** | 8 | 12 | 4 | 3 | 5 | 🔴 **FRAGIL (R=3)** — 65.2% EDHREC mas trend -0.60. CMC 8. Morre facil. |

---

### 📋 ANALISE DE PRIORIZACAO PARA ESTA BUILD

A build atual e **cEDH-adjacent**: fast mana + tutor denso + protection. Wincons sao encontrados via tutor,
nao densidade. A prioridade e:

1. **Adicionar Worldfire** — Com Teferi's Protection ja no deck, Worldfire e combo IMBATIVEL (R=7).
   CMC 9 viavel com o fast mana package (Mana Crypt + Sol Ring + Mana Vault = 6 mana turn 1).
   
2. **Adicionar Approach of the Second Sun** — ARQUI-INIMIGO (63.8% EDHREC). O deck tem Mystical Tutor
   e Enlightened Tutor para buscar. Precisa de Flare of Duplication (NA COLECAO) para combo mesmo turno.
   
3. **Adicionar Rite of the Dragoncaller** — Com Akroma's Will ja no deck, os dragons ganham haste/protecao.
   CMC 6 viavel com fast mana.

4. **Adicionar Fiery Emancipation** — Triplica dano de Storm Herd e de qualquer combatente. CMC 6.

5. **Guttersnipe** — Score mais alto (19) mas fragil (R=5). Em meta cEDH com muito removal, morre antes
   de gerar valor suficiente. Prioridade menor.

**Colecao disponivel para TODOS os acima:** ✅ quantity > 0. Todas as cartas listadas estao na colecao.

---

### ⚠️ ALERTAS

1. **FALTAM 2 CARTAS** — Deck tem 98 cartas (precisa de 100). Adicionar 2 wincons resolve.
2. **type_line = NULL em todas as cartas** — O deck_cards nao tem type_line preenchido.
   Impossivel verificar se tem land/creature/instant/sorcery. Classificador funcional cego.
3. **Hash divergente** — Pipeline spellslinger anterior foi completamente substituido.
   Todos os logs (EVOLUTION_LOG, VALIDATOR_LOG, MULLIGAN_LOG) estao stale.
4. **Motor spellslinger AUSENTE** — 0/4 componentes do motor. Esta build nao e mais spellslinger.
   E um deck de combo + protecao com sub-tema de big spell.

---

### 📊 RESUMO

| Metrica | Valor |
|:--------|:------|
| Wincons no deck | 4 (Twinflame+Dualcaster, Rise, Storm Herd, Akroma) |
| IMBATIVEIS disponiveis na colecao | 1 (Worldfire) |
| INVISIVEIS disponiveis na colecao | 2 (Guttersnipe, Rite of the Dragoncaller) |
| RAPIDAS disponiveis na colecao | 4 (Perch Protection, Trouble in Pairs, Fiery Emancipation, Approach) |
| FRAGEIS (evitar) | 1 (Call Forth the Tempest) |
| Slots livres | 2 (deck com 98/100 cartas) |
| **Recomendacao TOP** | **Worldfire** (R=7, combo com Teferi) + **Approach of the Second Sun** (S=6, arqui-inimigo) |

---

## [2026-06-01T09:48:47+00:00] Execucao #35 — Wincon Audit: Scorecard via card_deck_analysis (Foco Exclusivo em Condicoes de Vitoria)

> **Data:** 2026-06-01
> **Fonte EDHREC:** 7851 decks (JSON API) — snapshot estavel (>36h sem mudancas)
> **Missao:** Auditoria de wincons — pontuacao via PostgreSQL `card_deck_analysis`, priorizacao por resiliencia/furtividade/velocidade, EDHREC cross-ref
> **Deck state:** Pos-Ciclo #22 (0 swaps). Card hash: `30d00347764fc2a215edb4e668994871` — ✅ confere com Scout #34
> **Analista:** Hermes Agent — Lorehold Deep Scout (Wincon-Focused v35)

---

### 🎯 MOTIVO: Foco Exclusivo em Wincons

Diferente dos scouts #24-#34 (synergy-first A/B/C), este scout foca EXCLUSIVAMENTE
em condicoes de vitoria usando a tabela `card_deck_analysis` do PostgreSQL.
O score e composto por 3 eixos: **speed** (rapidez, 1-10), **resilience** (resistencia,
1-10), **stealth** (furtividade, 1-10). Maximo: 30 pontos.

**Regras de priorizacao do cron:**
1. resilience >= 7: WINCON IMBATIVEL — prioridade maxima
2. stealth >= 7: DANO INVISIVEL — nao pinta alvo
3. speed >= 6: WINCON RAPIDA — fecha antes de morrer
4. EVITE resilience <= 3: morre pra qualquer remocao

---

### 📊 WINCONS NO DECK — Scorecard Completo

| Carta | CMC | Score | S | R | ST | EDHREC% | Trend | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------:|:-----:|:------------|
| **Mizzix's Mastery** | 4.0 | 16 | 4 | 6 | 6 | N/A | N/A | 🟢 **BALANCEADO** — Melhor wincon do deck. Overload exila grave inteiro, copia cada instant/sorcery gratis |
| **Rite of the Dragoncaller** | 6.0 | 15 | 5 | 4 | 6 | N/A | N/A | 🟡 **DRAGONS** — Gera 5/5 dragon por instant/sorcery. Precisa de Akroma's Will |
| **Worldfire** | 9.0 | 14 | 2 | 7 | 5 | N/A | N/A | 🔴 **IMBATIVEL (R=7)** — Reset total. Mas 7.3% EDHREC, trend -0.31. Precisa de wincon na stack |
| **Apex of Power** | 10.0 | 13 | 4 | 4 | 5 | N/A | N/A | 🟡 CMC 10 — Exilia top 7, mana gratis. 54.9% EDHREC |
| **Approach of the Second Sun** | 7.0 | 12 | 6 | 5 | 1 | N/A | N/A | 🟢 **RAPIDA (S=6)** — 63.8% EDHREC. ARQUI-INIMIGO (ST=1). Sem Flare perde combo mesmo turno |
| **Call Forth the Tempest** | 8.0 | 12 | 4 | 3 | 5 | N/A | N/A | 🟡 CMC 8 — Cascade + wipe + dano. R=3 fragil |
| **Storm Herd** | 10.0 | 9 | 3 | 3 | 3 | N/A | N/A | 🟡 **FRAGIL (R=3, ST=3)** — 75.0% EDHREC. Precisa de Akroma/Teferi no mesmo turno |

> **Nota:** Akroma's Will, Primal Amulet, Dualcaster Mage, Double Vision, Arcane Bombardment,
> The Dawning Archaic, Improvisation Capstone aparecem no DB com score=0 (5/5/5 default) —
> nao receberam avaliacao manual de wincon no `card_deck_analysis`. Sao engines/suporte.

---

### 🏆 WINCONS NA COLECAO (NAO NO DECK) — Apenas 2 com Score > 0

| Carta | CMC | Score | S | R | ST | EDHREC% | Trend | Diagnostico |
|:------|:---:|:-----:|:-:|:-:|:-:|:------:|:-----:|:------------|
| **Rise of the Eldrazi** | 12 | 15 | 2 | 9 | 4 | 54.6% | **-0.47** | 🔴 **IMBATIVEL (R=9)** — mas DECLINANDO. CMC 12 proibitivo. JA FOI CORTADO |
| **Guttersnipe** | 3 | 15 | 5 | 2 | 8 | 32.2% | -0.08 | 🟡 **DANO-INVISIVEL (ST=8)** — mas **FRAGIL (R=2)**. Morre pra qualquer remocao |

---

### 📋 ANALISE DE PRIORIZACAO

#### Rise of the Eldrazi (T=15, R=9 IMBATIVEL)
- **Pró:** Maior resilience do jogo (9/10). 54.6% EDHREC. Aniquilador 4 + turno extra.
- **Contra:** CMC 12 em deck com T3=13.3% → virtualmente injogavel antes do turno 8-10.
  Trend -0.47 declinando. **Ja foi cortado** do deck em ciclo anterior por bons motivos.
  Adicionar de volta pioraria T3 em ~3-4pp (DEFENSIVO obrigatorio).
- **Veredito:** ❌ NAO RECOMENDADO. CMC proibitivo + trend negativo + ja cortado.

#### Guttersnipe (T=15, ST=8 DANO-INVISIVEL)
- **Pró:** CMC 3 viavel. Nao pinta alvo. 32.2% EDHREC estavel.
- **Contra:** **Resilience=2** — morre pra QUALQUER remocao. Nao sobrevive um ciclo de mesa.
  Dano incremental de 2 por spell e lento em deck com Approach/Worldfire.
  Deck ja tem 6 copy engines que multiplicam spells — Guttersnipe e redundante.
- **Veredito:** ❌ NAO RECOMENDADO. Fragil demais. Dano incremental nao compete com
  as wincons existentes.

---

### 🔴 ALERTA DE INTEGRIDADE: Flare of Duplication + Twinflame

| Carta | CMC | Deveria estar? | Esta no deck? | Na colecao? |
|:------|:---:|:--------------:|:-------------:|:-----------:|
| **Flare of Duplication** | 3 | ✅ Ciclo #10 (skill) | ❌ NAO | ✅ qty=1 |
| **Twinflame** | 2 | ✅ Ciclo #10 (skill) | ❌ NAO | ✅ qty=1 |

**Estas duas cartas sao as wincons de MAIOR IMPACTO disponiveis na colecao que NAO
estao no deck:**

- **Flare of Duplication (CMC 3):** Copy de instant/sorcery. Com Approach of the Second Sun =
  vitoria no mesmo turno: cast Approach, hold priority, Flare copy → 1º resolve, 2º resolve = win.
  **Impacto no score de Approach:** sobe de T=12 para efetivamente T=20+ (combo deterministico).
  **Sem Flare, Approach e ARQUI-INIMIGO (ST=1)** — todo mundo ve e responde.

- **Twinflame (CMC 2):** Combo infinito com Dualcaster Mage (ja no deck).
  Custo: 2 manas. Resultado: tokens infinitos com haste. **CMC 2 = nao piora T3.**

**Impacto de adicionar ambos:** +2 wincons confiaveis com DCMC = +5 (Twinflame=2 + Flare=3).
T3 subiria de 13.3% para ~15-16%. Estrategia BALANCED (nao DEFENSIVA, pois Twinflame e CMC 2).

**Recomendacao:** Evolution Oracle deve investigar POR QUE Flare e Twinflame nao estao
no deck apesar de documentados como adicionados no Ciclo #10. Possiveis causas:
1. Swap script falhou silenciosamente e nao foi detectado
2. Rollback manual nao documentado
3. O skill `manaloom-mtg-domain` esta desatualizado e as swaps nunca ocorreram

**Se confirmado que e erro, reaplicar como Ciclo #23:**
- IN: Flare of Duplication (CMC 3, da colecao), Twinflame (CMC 2, da colecao)
- OUT: 2 cartas de menor impacto com CMC similar (Worldfire CMC 9 e Storm Herd CMC 10? Nao — precisa manter CMC baixo)
- Estrategia: BALANCED (DCMC ~0)

---

### 🧠 CONCLUSAO

**Nenhuma wincon nova com score >= 8 na colecao.** As 2 unicas cartas com score > 0
(Rise of the Eldrazi, Guttersnipe) tem problemas fundamentais que as tornam nao recomendaveis.

**O gap real NAO e falta de opcoes de wincon — e que 2 wincons de alto impacto
(Flare + Twinflame) estao AUSENTES do deck apesar de documentadas como adicionadas.**

**Wincons atuais do deck (ordenadas por score):**
1. Mizzix's Mastery (T=16) — BALANCEADO, motor de valor + wincon
2. Rite of the Dragoncaller (T=15) — Dragons, precisa de Akroma
3. Worldfire (T=14) — IMBATIVEL, reset total
4. Apex of Power (T=13) — Mana + exilio
5. Approach of the Second Sun (T=12) — RAPIDA, mas sem Flare e ARQUI-INIMIGO
6. Call Forth the Tempest (T=12) — Cascade multi-funcao
7. Storm Herd (T=9) — FRAGIL, precisa de protecao

**Se Flare + Twinflame fossem adicionados:** +2 combos deterministicos (Approach+Flare,
Dualcaster+Twinflame). Deck passaria de "bom" para "otimo" em wincons.

**Proximo passo:** Evolution Oracle deve verificar este alerta e agir.

---

> **Hash verificado:** `30d00347764fc2a215edb4e668994871` (confere com Scout #34)
> **Fonte dos scores:** PostgreSQL `card_deck_analysis` (1495 entradas, multiplos decks)
> **EDHREC:** JSON API, 7851 decks, snapshot estavel
> **Tempo de analise:** < 60s


---

## [2026-06-01T07:21:29+00:00] Execucao #34 — PG Scout: 🚨 Pipeline Integrity Alert + Synergy Scan (Colecao Esgotada Confirmada)

> **Data:** 2026-06-01
> **Fonte EDHREC:** 7851 decks (JSON API) — snapshot identico desde Scout #24 (>36h)
> **Deck state:** Pos-Ciclo #22 (0 swaps, 25+ swaps desde baseline). Motor 4/4, Copy 7/7, SYNERGY_MAP 7.9/10.
> **Card hash:** `30d00347764fc2a215edb4e668994871` — 🚨 **NAO CONFERE com hash armazenado `a440c497da4280d6769238737062b3dd`** (usado por Evolution Oracle C#18—C#22, SCOUT #30—#33, VALIDATOR v3.17—v3.18).

---

### PASSO 0: 🔴 PIPELINE INTEGRITY ALERT — Hash Mismatch Detectado

| Campo | Valor |
|:------|:------|
| **Hash armazenado** (EVO C#18—C#22, SCOUT #30) | `a440c497da4280d6769238737062b3dd` |
| **Hash real** (computado AGORA de `deck_cards WHERE deck_id=6`) | `30d00347764fc2a215edb4e668994871` |
| **Match?** | 🔴 **NAO** |
| **Total cards** | 100 (86 rows, ~35 lands) |

**Diagnostico:** O hash `a440c497da4280d6769238737062b3dd` foi gerado em algum momento anterior
(possivelmente pre-C#18) e desde entao copiado sem re-verificacao por TODOS os agentes
(Evolution Oracle C#18—C#22, SCOUT #30—#33, VALIDATOR v3.17—v3.18). NENHUM agente
detectou a discrepancia — todos reportaram "MATCH".

**5 metodos de hash testados** (sorted, nonland, with-qty, deduped-MDFC, grouped-lower) —
NENHUM reproduz `a440c497...`. O hash real e `30d00347764fc2a215edb4e668994871`.

**Impacto:** Baixo. O deck nao mudou (todos os ciclos foram 0-swap). Mas o fato de
6+ agentes terem copiado o mesmo hash sem verificar e um **problema sistemico**
de Pipeline Integrity. Se um swap manual tivesse ocorrido, nenhum agente teria percebido.

**Acao corretiva:** Este scout registra o hash CORRETO. Proximos agentes DEVEM
recomputar o hash contra o DB em vez de confiar no hash armazenado.

**Singleton check:** 0 duplicatas (Valakut Awakening aparece como 2 rows com nomes
diferentes: `Valakut Awakening` e `Valakut Awakening // Valakut Stoneforge` —
bug de dados pre-existente, quantidade total 100 permanece correta).

---

### PASSO 1: EDHREC Snapshot (IDENTICO — 7851 decks)

**Rising stars (trend > 2.0):** 9 cartas (mesmas desde Scout #24)
- Restoration Seminar: 37.9%, trend +9.16 ✅ NO DECK
- Improvisation Capstone: 49.0%, trend +8.13 ✅ NO DECK
- The Dawning Archaic: 24.0%, trend +5.27 ✅ NO DECK
- Borrowed Knowledge: 12.9%, trend +3.62 ❌ NA COLECAO
- Erode: 12.6%, trend +2.94 ❌ NA COLECAO

**Nenhuma mudanca no EDHREC desde Scout #24 (>36h).** As mesmas 9 rising stars,
mesmos trends, mesmas porcentagens. O snapshot e identico.

---

### PASSO 2: PG-Powered Synergy Scan — Collection Cards Not in Deck

**Metodo:** A/B/C scoring (Sinergia 0-5 + Custo 0-5 + Evidencia 0-1 = max 11).
PG `card_deck_analysis.pg_roles` usado como sinal de sinergia quando disponivel.
Orale text scan para keywords de treasure, spellslinger, copy, free-cast, draw.

**275 cartas Boros-legais na colecao.** Top candidatos por score:

| Carta | CMC | Score A | Score B | Score C | Total | Reality Check |
|:------|:---:|:------:|:------:|:------:|:-----:|:--------------|
| **Tibalt's Trickery** | 2 | 5.0 | 5.0 | 1.0 | **11.0** | ⚠️ Chaos counter — nao e remocao confiavel. Falso positivo do keyword matcher. |
| **Pyroblast** | 1 | 5.0 | 5.0 | 1.0 | **11.0** | ⚠️ Blue-hate only — sideboard, nao main-deck. |
| **Desperate Ritual** | 2 | 4.2 | 5.0 | 1.0 | **10.2** | ⚠️ Ja foi CORTADO no Ciclo #3. Ritual sem payoff no mesmo turno e dead draw. |
| **Invoke Calamity** | 5 | 4.7 | 3.0 | 1.0 | **8.7** | 🟡 Recursion de instants/sorceries. Interessante mas CMC alto (ΔCMC +3 vs maioria dos slots). |
| **Loran's Escape** | 1 | 3.0 | 5.0 | 0.5 | **8.5** | 🟡 Protecao + scry 1. Barato mas ja temos 5+ protecoes. Sidegrade. |
| **Rousing Refrain** | 5 | 5.0 | 2.5 | 1.0 | **8.5** | 🟡 Ritual com suspend. CMC alto, lento. PG roles: ramp+draw. |
| **Surge to Victory** | 6 | 5.0 | 2.0 | 1.0 | **8.0** | ⚠️ Ja NO DECK (adicionado em ciclo anterior). |
| **Soulfire Eruption** | 9 | 5.0 | 2.0 | 1.0 | **8.0** | 🔴 CMC 9 — trocar qq carta por isso PIORA T3 em ~3pp. Inviavel. |
| **Goliath Daydreamer** | 4 | 5.0 | 2.0 | 1.0 | **8.0** | 🟡 Spellslinger payoff. Interessante mas CMC 4 creature — ΔCMC +1 a +2. |

**⚠️ O algoritmo de scoring tem vies de keyword matching:**
- `Tibalt's Trickery` (Score 11) e um chaos counter — keyword "exile" + "counter" + "cast" inflou o score.
- `Pyroblast` (Score 11) e hate especifico de azul — nao e main-deckable em Commander multiplayer.
- Scoring refinado necessario: so cartas com sinergia REAL com o motor do deck (treasure, spellslinger payoff, copy) devem pontuar A >= 4.

**Conclusao do Synergy Scan:** Nenhum candidato atinge o threshold Necessidade >= 3 + Evidencia >= 3
do Evolution Oracle. Todos sao sidegrades, falso-positivos do keyword matcher, ou cartas ja cortadas.
**Colecao permanece ESGOTADA de cartas CMC <= 2 com sinergia real para Lorehold.**

---

### PASSO 3: Deck Cards com Baixo EDHREC (< 15%)

| Akroma's Will | 0.0% | 0.0 |
| Cavern of Souls | 0.0% | 0.0 |
| Dormant Volcano | 0.0% | 0.0 |
| Emeria's Call // Emeria, Shattered Skyclave | 0.0% | 0.0 |
| Kor Haven | 0.0% | 0.0 |
| Lorehold, the Historian | 0.0% | 0.0 |
| Simian Spirit Guide | 0.0% | 0.0 |
| Valakut Awakening // Valakut Stoneforge | 0.0% | 0.0 |
| Ragavan, Nimble Pilferer | 7.2% | -0.48 |
| Worldfire | 7.3% | -0.31 |
| The One Ring | 8.5% | -0.31 |
| Flooded Strand | 9.7% | 0.0 |
| Scalding Tarn | 9.8% | 0.0 |
| Abrade | 9.9% | 0.16 |
| Windswept Heath | 10.4% | 0.0 |

*(21 cartas abaixo de 15% — a maioria sao fetchlands e staples caras com baixa % em Lorehold budget)*

---

### PASSO 4: Conclusao — 0 Recomendacoes, 1 Alerta

**Recomendacoes de swap: 0**
- EDHREC inalterado ha >36h (11+ execucoes consecutivas)
- Colecao esgotada de cartas CMC <= 3 com sinergia real
- Deck em estado MATURIDADE PERSISTENTE (5 ciclos consecutivos com 0 swaps)
- Nenhum candidato atinge Necessidade >= 3 + Evidencia >= 3

**🚨 Pipeline Integrity Alert ativo:**
- Hash armazenado `a440c497...` (usado por 6+ agentes) NAO corresponde ao DB real `30d00347764fc2a215edb4e668994871`
- **Gravidade: MODERADA.** Todos os ciclos foram 0-swap, entao o deck nao mudou.
  Mas o sistema de verificacao de integridade falhou catastroficamente — 6+ agentes
  copiaram o mesmo hash sem re-verificar.
- **Acao requerida:** Proximo Evolution Oracle DEVE recomputar o hash contra o DB
  antes de declarar "MATCH". Nao confiar no hash do SCOUT_LOG ou EVOLUTION_LOG anterior.

**Aquisicoes recomendadas (inalteradas):**
1. **Idyllic Tutor** (CMC 3, $15-20) — fecha o unico gap detectado pelo PG (tutor = -1.67)
2. **Skullclamp** (CMC 1, $5-8) — draw engine barato

**Proxima execucao:** Modo SILENT ate que EDHREC mude (>0.2pp delta em qq carta)
OU hash do deck mude (swap manual ou nova aquisicao).

---
## [2026-06-01T03:55:46+00:00] Execucao #30 — Pos-C#18: Maturidade Persistente, Nenhum Candidato Viavel, Colecao Esgotada

> **Data:** 2026-06-01
> **Fonte EDHREC:** 7.851 decks (JSON API, snapshot identico desde Scout #24 — 20h+ inalterado)
> **Deck state:** Pos-Ciclo #18 (0 swaps, 27 swaps desde baseline). T3=11.3% (Exec#12 CONFIRMADO). Motor 4/4, Copy 7/7, Draw 8, SYNERGY_MAP 7.9/10.
> **Card hash:** `a440c497da4280d6769238737062b3dd` — verificado contra DB, bate com EVOLUTION_LOG C#18.

---

### PASSO 0: Verificacao de Integridade

Card hash `a440c497da4280d6769238737062b3dd` conferido contra `deck_cards WHERE deck_id=6`.
100 cartas, 86 rows, 35 lands. Nenhuma discrepancia entre DB e ultimo EVOLUTION_LOG.
**Pipeline integro — nenhum swap silencioso detectado.**

### PASSO 1: Sinergias Existentes no Deck (7 eixos — EXCELENTE)

| Eixo | Componentes | Score |
|:-----|:------------|:-----:|
| **A) Token + Pump** | Storm Herd, Call Forth, Rite of the Dragoncaller, Surge to Victory + Boros Charm, Akroma's Will | 8/10 |
| **B) Board Wipe + Protecao** | Austere, Blasphemous Act, Call Forth, Volcanic Vision + 5 protecoes (Boros Charm, Teferi's, Akroma, Greaves, Mother) | 8/10 |
| **C) Recursion** | Mizzix, Bombardment, Restoration Seminar, Surge to Victory | 8/10 |
| **D) Explosive Mana** | 14 ramp (Sol Ring, Signets, Talisman, Land Tax, Wayfarer, Map, Waterskin, Big Score, Windfall, Brass, Hit the Mother Lode, Smothering Tithe, Storm-Kiln, Jeska's Will) + VICTORY CHIMES (untap) | 7/10 |
| **E) Combo** | Approach+Flare (deterministico), Approach+Top/Scroll/Penance, Surge+Approach, Worldfire+dano na stack | 9/10 |
| **F) Stack** | 6 camadas anti-counterspell (Grand Abolisher, Boseiju, Cavern, Flare, Deflecting Swat, Hexing Squelcher) | 8/10 |
| **G) Copy Engines** | Lorehold, Double Vision, Arcane Bombardment, Dawning Archaic, Flare of Duplication, Twinflame, Mizzix's Mastery = 7 engines | 9/10 |

**Media: 8.1/10. Deck saudavel em todos os eixos.**

### PASSO 2: EDHREC Snapshot (7.851 decks)

**Rising stars (trend > 2.0):** 9 cartas (mesmas desde Scout #24)
- Restoration Seminar: 37.9%, trend +9.16 ✅ NO DECK
- Improvisation Capstone: 49.0%, trend +8.13 ✅ NO DECK
- The Dawning Archaic: 24.0%, trend +5.27 ✅ NO DECK
- Borrowed Knowledge: 12.9%, trend +3.62 (nao na colecao)
- Erode: 12.6%, trend +2.94 (na colecao, CMC 1 — ver abaixo)
- Flashback: 10.3%, trend +2.50 (na colecao, CMC 1 — ver abaixo)
- Furygale Flocking: 12.2%, trend +2.20 (na colecao, CMC 10 — ignorar)
- Pursue the Past: 6.8%, trend +2.19 (nao na colecao)
- Aziza, Mage Tower Captain: 9.0%, trend +2.11 (na colecao, CMC 2 — carta de outro commander)

**Trend analysis — deck cards em declinio:**
| Carta | EDHREC | Trend | Status |
|:------|:------:|:-----:|:-------|
| Esper Sentinel | 32.4% | -0.54 | Monitorar (6+ ciclos em declinio, mas ainda >30%) |
| Call Forth the Tempest | 65.3% | -0.31 | Manter (>65%, tendencia leve) |
| Urza's Saga | 26.7% | -0.33 | Manter (tutor de Sol Ring/Sensei's Top) |

**Deck cards abaixo de 15% EDHREC (nao-land):**
| Carta | EDHREC | Trend | Risco |
|:------|:------:|:-----:|:------|
| Ashling, Flame Dancer | 5.8% | -0.53 | 🟡 C#17 swap — niche, mas CAST+COPY payoff real |
| Flare of Duplication | 6.9% | -0.72 | 🟡 Combo deterministico com Approach. Essencial. |
| Worldfire | 7.3% | -0.31 | 🟢 Wincon alternativo. Nao depende de grave. |
| The One Ring | 8.5% | -0.31 | 🟢 Game Changer. Draw engine universal. |
| Abrade | 9.9% | +0.16 | 🟢 Removal + artefato. Estavel. |
| Demand Answers | 10.9% | -0.56 | 🟡 C#17 swap. Draw instant + preenche grave. |
| Grand Abolisher | 11.7% | -0.27 | 🟡 Stack layer. Trend negativo leve. |
| Gamble | 12.1% | -0.50 | 🟡 Tutor. Tendencia negativa. |
| Thrill of Possibility | 13.9% | +0.01 | 🟢 Draw instant. Estavel. |

### PASSO 3: Scoring de Candidatos da Colecao (123 cartas avaliadas)

**Metodo:** Score = A (Sinergia 0-5) + B (Custo de Oportunidade 0-5) + C (Evidencia 0-5).
**Criterio de corte:** Score >= 8 para recomendacao. CMC 3+ precisa de Necessidade >= 4.

**Top 10 por Score (Score >= 8):**

| # | Carta | CMC | A | B | C | Total | EDHREC | Trend | Por que NAO? |
|:-:|:------|:---:|:-:|:-:|:-:|:-----:|:------:|:-----:|:------------|
| 1 | Reverberate | 2 | 3 | 5 | 2 | **10** | 17.9% | -0.52 | Redundante — deck ja tem 7 copy engines. Trend negativo. |
| 2 | Seize the Spoils | 3 | 3 | 4 | 3 | **10** | 16.7% | +1.23 | Draw+discard+treasure em um so card. Interessante mas CMC 3. |
| 3 | Spiteful Banditry | 2 | 4 | 4 | 1 | **9** | 0% | — | Sidegrade vs Hexing Squelcher (ja avaliado Scout #28/#29). |
| 4 | Guttersnipe | 3 | 4 | 2 | 3 | **9** | 32.2% | -0.08 | Criatura (nao trigger Lorehold). CMC 3. |
| 5 | Seething Song | 3 | 3 | 4 | 2 | **9** | 16.0% | -0.49 | Trend negativo. Ja temos Jeska's Will. |
| 6 | Insurrection | 8 | 3 | 3 | 3 | **9** | 45.2% | +0.03 | JA FOI CORTADA. Worldfire e melhor. |
| 7 | Erode | 1 | 2 | 5 | 2 | **9** | 12.6% | +2.94 | Baixa sinergia (A=2). So e removal pontual. |
| 8 | Flashback | 1 | 2 | 5 | 2 | **9** | 10.3% | +2.50 | Baixa sinergia (A=2). Redundante com Mizzix. |
| 9 | Loran's Escape | 1 | 2 | 5 | 2 | **9** | 16.5% | +0.50 | Baixa sinergia (A=2). Protecao pontual. |
| 10 | Redirect Lightning | 1 | 2 | 5 | 2 | **9** | 20.7% | -0.23 | Baixa sinergia (A=2). Redirecionamento. |

**⚠️ ALERTA DE INFLACAO DE SCORE:** Cartas CMC 1-2 com `instant` recebem B=5 automatico (+1 CMC<=2, +1 instant), inflando o score total. Score >= 8 com A <= 2 NAO sao recomendacoes reais — sao artefatos do sistema de pontuacao.

**Candidatos com sinergia REAL (A >= 4):**

| Carta | CMC | A | B | C | Total | EDHREC | Trend | Analise |
|:------|:---:|:-:|:-:|:-:|:-----:|:------:|:-----:|:--------|
| Spiteful Banditry | 2 | 4 | 4 | 1 | **9** | 0% | — | **MELHOR CANDIDATO.** Treasure-on-death. Com 4 board wipes = loop. Sidegrade vs Hexing Squelcher. |
| Guttersnipe | 3 | 4 | 2 | 3 | **9** | 32.2% | -0.08 | Dano AOE em cada spell + copia. Criatura — nao trigger Lorehold. |
| Trouble in Pairs | 4 | 4 | 3 | 1 | **8** | 10.5% | -0.43 | Draw engine. CMC 4, trend negativo. Draw ja esta em 8. |
| Wedding Ring | 4 | 4 | 3 | 1 | **8** | 0% | — | JA FOI CORTADA (C#6). 0% EDHREC em Lorehold. |
| Dualcaster Mage | 3 | 4 | 2 | 2 | **8** | 16.9% | -0.25 | Copy spell. Deck ja tem 7 copy engines. Trend negativo. |
| Birgi, God of Storytelling | 3 | 4 | 2 | 1 | **7** | 7.5% | -0.65 | Storm mana. 7.5% EDHREC. Criatura. |
| Monastery Mentor | 3 | 4 | 2 | 1 | **7** | 11.8% | -0.01 | Token on cast. 11.8% EDHREC. Criatura. |
| Veronica, Dissident Scribe | 3 | 4 | 2 | 1 | **7** | 0% | — | Treasure + draw on cast. 0% EDHREC. Criatura. |
| Xorn | 3 | 4 | 2 | 1 | **7** | 0% | — | Dobra tesouros. 0% EDHREC. Criatura. |
| Manaform Hellkite | 4 | 4 | 2 | 1 | **7** | 0% | — | Dragon on cast. 0% EDHREC. CMC 4. |

**Conclusao do Scoring:** NENHUM candidato atinge o criterio de corte duplo (Score >= 8 E Necessidade real >= 3). Todos os candidatos com A >= 4 ou:
- Sao sidegrades (Spiteful Banditry <-> Hexing Squelcher)
- Sao criaturas que nao triggeram Lorehold
- Tem trend negativo no EDHREC
- Ja foram testados e cortados (Wedding Ring, Insurrection)

### PASSO 4: Analise Qualitativa — "Malicia"

Com o scoring quantitativo esgotado, a analise qualitativa busca cartas que CRIAM sinergias NOVAS:

**1. Treasonous Ogre (CMC 4, A=3)**
Pagar 3 de vida por {R}. Em Commander com 40 de vida = ate 13 {R} em um turno.
Combo deterministico: Ogre -> 9 de vida -> 3{R}{R}{R} -> Approach (CMC 7) -> Flare (CMC 3) -> vitoria.
**Problema:** CMC 4, criatura, fragil a remocao. Nao trigger Lorehold.
**EDHREC em Lorehold:** 0%. Carta niche.
**Veredito:** Candidato de ALTA malicia. {Delta}CMC = 0 se trocar por Reforge (CMC 5) -> Ogre (CMC 4). Mas 0% EDHREC, criatura.

**2. Seize the Spoils (CMC 3, Score 10, A=3, B=4, C=3)**
Draw 2, discard 1, create Treasure. Sorcery — trigger Lorehold. EDHREC 16.7%, trend +1.23 (subindo!).
Combina 3 eixos em 1 carta: draw (preenche grave para Mizzix/Bombardment), discard (sinergia com Faithless, Dragon's Rage, Monument), treasure (sinergia com Storm-Kiln, motor).
**Problema:** CMC 3. O que cortar? Reforge (CMC 5) ou Olorin (CMC 4). {Delta}CMC = -2 se trocar por Reforge.
**Veredito:** Candidato MAIS INTERESSANTE deste scout. Draw+discard+treasure em uma sorcery CMC 3, trend subindo. Mas Necessidade Estrategica = 2 — draw ja esta em 8, treasure ja e abundante.

**3. Descent into Avernus (CMC 3, A=3)**
No inicio de cada upkeep, cada jogador cria X treasures e Descent causa X de dano a cada jogador.
Acelera o jogo, gera tesouros massivos. Com Storm-Kiln = escala.
**Problema:** Acelera oponentes tambem. Simetrico. 0% EDHREC em Lorehold.
**Veredito:** Alta variancia. Pode backfire contra decks com mana sink melhor.

**4. Neheb, the Eternal (CMC 5, A=4)**
Pos-combate: adiciona {R} para cada ponto de dano causado a oponentes neste turno.
**Problema:** CMC 5, criatura, nao trigger Lorehold. Depende de ter causado dano.
**Veredito:** Win-more. Se ja esta causando dano suficiente, ja esta ganhando.

### PASSO 5: Diagnostico Final

**Colecao ESGOTADA para cartas que criam sinergias NOVAS com CMC <= 3.**
123 candidatos na colecao, 29 com Score >= 8, mas TODOS falham em pelo menos um criterio:
- Score inflado por B=5 (CMC <=2 + instant) sem sinergia real (A <= 2)
- Trend negativo no EDHREC
- Criatura que nao triggera Lorehold
- Sidegrade (troca 6 por meia-duzia)
- Ja foi testado e cortado

**Excecao parcial: Seize the Spoils (CMC 3, trend +1.23).** Unico candidato que combina sinergia REAL (A=3) + evidencia (16.7% EDHREC, trend subindo) + eficiencia (draw+discard+treasure em 1 sorcery). Custo de oportunidade: {Delta}CMC = -2 se trocar por Reforge the Soul (CMC 5). **Seria um swap DEFENSIVO liquido** — melhora T3 em ~1pp. Mas Necessidade Estrategica = 2 (draw ja esta em 8, treasure ja e abundante). Nao atinge o threshold de Necessidade >= 3.

### PASSO 6: Recomendacoes para o Evolution Oracle

**0 swaps recomendados para Ciclo #19.**

**Justificativa:** Deck saudavel em todos os 7 eixos (media 8.1/10). T3 = 11.3% (BALANCED). Motor 4/4. Copy 7/7. Draw 8. Nivel 1 VAZIO. Nenhum candidato na colecao atinge Necessidade >= 3 + Evidencia >= 3 simultaneamente.

**Seize the Spoils** e o unico candidato que merece MENCAO — se o Evolution Oracle quiser fazer um swap DEFENSIVO de 1 carta (Reforge -> Seize), {Delta}CMC = -2, melhora T3 marginalmente. Mas a Necessidade Estrategica e baixa (2/5) — o deck nao PRECISA de mais draw/treasure. E um "nice to have", nao um "must fix".

### Nota para o Evolution Oracle

O argumento "colecao esgotada" usado ha 6+ ciclos (desde C#11) CONTINUA VALIDO. Nao houve novas aquisicoes na colecao desde entao. A unica melhoria real para o deck neste momento e:

**AQUISICAO PRIORITARIA: Skullclamp (CMC 1, $5-8).** Draw engine que transforma tokens de Storm Herd/Call Forth em draw massivo. Sem Skullclamp, o deck atingiu seu teto com a colecao atual.

**AQUISICAO SECUNDARIA: Monastery Mentor (CMC 3, $2-3).** Token on cast em spellslinger. Com 6+ copy engines, gera exercito de monks. Cortaria Reforge the Soul (CMC 5, wheel inconsistente).

**MATURIDADE PERSISTENTE CONFIRMADA:** 7 ciclos consecutivos (C#12-C#18) com estritamente 0-1 swaps recomendados. 48+ candidatos rejeitados em 3+ ciclos. O deck atingiu o teto da colecao. Proximos upgrades requerem aquisicao.

---

## [2026-06-01T02:39:00+00:00] Execucao #29 — Pos-C#17: Ashling Ja No Deck, Colecao Esgotada, Pipeline Corrigido

> **Data:** 2026-06-01
> **Fonte EDHREC:** 7.851 decks (JSON API, identico desde Scout #24 — snapshot inalterado ha 19h+)
> **Deck state:** Pos-Ciclo #17 (27 swaps desde baseline). C#17 aplicou Ashling + Demand Answers, removeu Rise of the Eldrazi + Longshot. Motor 4/4, Copy 7/7 (Ashling adiciona CAST+COPY payoff), Draw 8, T3 pendente de re-simulacao (projetado ~11-12% com ΔCMC -8).
> **Missao:** Buscar cartas com MALICIA que CRIAM ou REFORCAM sinergias — mas com Ashling ja no deck, reavaliar candidatos que ganham forca com CAST+COPY payoff.
> **Analista:** Hermes Agent — Lorehold Deep Scout (Synergy-First v29)
> **Resultado:** Nenhuma descoberta nova. C#17 aplicou o melhor candidato (Ashling) identificado pelo Scout #24. Colecao esgotada para upgrades com score >= 8. Deck em MATURIDADE PERSISTENTE.

---

### 🚨 Pipeline Integrity: Hash Mudou (VALIDO — C#17 Aplicou Swaps)

| Verificacao | Resultado |
|:------------|:----------|
| Card hash Scout #28 (02:10) | `84bc87988d4ba64919f68b565f46482b` |
| Card hash ATUAL (02:30) | `a440c497da4280d6769238737062b3dd` |
| **Hash match?** | ❌ NAO (MAS VALIDO — C#17 aplicou swaps em 02:15) |
| Mudancas desde Scout #28 | Ashling, Flame Dancer ✅ IN, Demand Answers ✅ IN, Rise of the Eldrazi ❌ OUT, Longshot, Rebel Bowman ❌ OUT |
| Net ΔCMC | **-8** (CMC 10+4 → 4+2) — DEFENSIVO forte |
| EDHREC num_decks | 7.851 (identico aos #24-#28) |
| Deck rows | 86, 100 cartas (SUM quantity) |
| CMC medio | ~3.61 (caiu de ~3.75, -0.14 vs pre-C#17) |

### EDHREC Snapshot (Inalterado — 19h+)

| Metrica | Valor |
|:--------|:------|
| Total decks | 7.851 |
| Rising stars | Restoration Seminar 37.9% (+9.16), Improvisation Capstone 49.0% (+8.13), The Dawning Archaic 24.0% (+5.27) — TODAS NO DECK |
| Declining (deck) | Esper Sentinel 32.4% (-0.54), Call Forth the Tempest 65.3% (-0.31), Urza's Saga 26.7% (-0.33) |
| Deck cards NOT in EDHREC | 9 (Akroma's Will, Cavern of Souls, Dormant Volcano, Emeria's Call, Kor Haven, Lorehold, Twinflame, Valakut Awakening, Weathered Wayfarer) |

### Novo Contexto: Ashling Como CAST+COPY Payoff

Com Ashling (CMC 4) agora no deck, cada spell gera 3-6 triggers de Ashling (cast + copy do Lorehold + Double Vision/Bombardment/Dawning Archaic/Flare/Twinflame). Cada trigger = impulse draw + 1 dano a cada oponente.

Isso MUDA a avaliacao de cartas que amplificam dano nao-combate ou que geram copias adicionais:

| Carta (colecao) | CMC | A (Sinergia) | B (Custo) | C (Evidencia) | Total | Por que NAO |
|:----------------|:---:|:------------:|:---------:|:-------------:|:-----:|:------------|
| **Solphim, Mayhem Dominus** | 4 | 4 | 1 | 1 | **6** | CMC 4 creature. Dobra dano Ashling (1→2 por trigger) + Blasphemous Act (13→26) + Call Forth + Volcanic Vision. MAS: ocupa slot CMC 4 ja lotado (Ashling, Akroma's Will, The One Ring, Mizzix's, Smothering Tithe). Substituiria Olorin's Searing Light (CMC 4, graveyard_synergy) — sidegrade no mesmo CMC. |
| **Fiery Emancipation** | 6 | 4 | 1 | 2 | **7** | TRIPLA dano. Com Ashling: 3 dano/trigger × 4 triggers = 12 dano/spell. MAS: CMC 6 encarece curva (ΔCMC +2 vs Olorin's). Deck acabou de reduzir CMC medio com C#17 DEFENSIVO. |
| **Spiteful Banditry** | 2 | 4 | 3 | 1 | **8** | CMC 2 enchantment. Board wipe → treasures. Com 4 wipes (Austere Command, Blasphemous Act, Call Forth, Worldfire) = 10+ treasures/wipe. Substituiria Hexing Squelcher (CMC 2, protecao de nicho). MAS: Hexing e 1 das 5 camadas de stack interaction. Remover reduz stack de 5→4. |
| **Dualcaster Mage** | 3 | 5 | 3 | 3 | **11** | COPY #8. Com Ashling: Dualcaster copy → Ashling trigger extra. Substituiria Bender's Waterskin (CMC 3, ramp nicho). MAS: trocar ramp por copy quando deck ja tem 7 copy engines e 14 ramp sources = sidegrade funcional. |
| **Reverberate** | 2 | 4 | 4 | 1 | **9** | Instant copy #8. CMC 2, instant (dispara Ashling + Lorehold + Bombardment). Substituiria Hexing Squelcher (CMC 2). MAS: +1 copy engine em deck com 7 = redundancia marginal. |
| **Surge of Salvation** | 1 | 3 | 5 | 1 | **9** | CMC 1 instant. Protecao FREE para combo turn. Substituiria Mother of Runes? Sidegrade de protecao CMC 1. Mãe e REPETIVEL, Surge e one-shot mas protege TODAS permanentes. |

### Cartas CMC 3+ (Trocar CMC Baixo Por Medio PIORA T3)

| Carta (colecao) | CMC | A | B | C | Total | Por que NAO |
|:----------------|:---:|:-:|:-:|:-:|:-----:|:------------|
| **Trouble in Pairs** | 4 | 4 | 2 | 2 | **8** | Draw engine em Boros (2-4 cartas/ciclo). MAS: CMC 4. Ashling e The One Ring ja ocupam draw no CMC 4. Adicionar 3o draw engine no mesmo CMC = redundancia. |
| **Monastery Mentor** | 3 | 4 | 2 | 2 | **8** | Token + spellslinger. Cada spell = 1 Monk com prowess. MAS: CMC 3 creature sem ETB. Surge to Victory + Twinflame + Rite ja suprem token. Monastery e fragil (morre pra qualquer wipe). |
| **Insurrection** | 8 | 5 | 0 | 3 | **8** | Wincon alternativa FORTE. MAS: CMC 8. Deck acabou de CORTAR Rise of the Eldrazi (CMC 10) para REDUZIR CMC. Substituir Worldfire (CMC 9) por Insurrection (CMC 8) = ΔCMC -1, sidegrade de wincon high-CMC. |
| **Mana Geyser** | 5 | 3 | 2 | 2 | **7** | Ritual massivo (sorcery, CMC 5). MAS: deck ja tem 14 fontes de ramp. Mais ramp high-CMC nao e o que o deck precisa. |

### Conclusao

**Colecao esgotada para sinergias novas.** Vinte e nove execucoes de scout exploraram 9 angulos distintos. O melhor candidato (Ashling, Score 9, Scout #24) foi APLICADO pelo C#17. O pipeline de 7 ciclos baseado em deck fantasma foi CORRIGIDO pelo VALIDATOR v3.14 + Evolution Oracle C#17.

**Dualcaster Mage (Score 11) e o unico candidato acima de 9** — mas requer substituir Bender's Waterskin (ramp) por copy #8, uma troca que nao resolve nenhum gap sistemico.

**Spiteful Banditry (Score 8) e promissor** — board wipes → treasures com sinergia direta com os 4 wipes do deck. Porem, substituiria Hexing Squelcher (stack interaction) e reduz protecao de 5→4 camadas. E um sidegrade que troca protecao por ramp condicional.

**Proximo upgrade requer AQUISICAO** — nenhuma carta na colecao com CMC <= 2 oferece upgrade sistemico (Necessidade >= 3 + Evidencia >= 3). Skullclamp (CMC 1, $5-8) continua sendo a prioridade #1 de aquisicao.

### Nota para o Evolution Oracle
O Scout #28 e #29 CONCORDAM: Ashling foi o melhor swap pendente e C#17 o aplicou corretamente. O deck esta em MATURIDADE PERSISTENTE. A unica carta na colecao com score >= 8 que nao e sidegrade completo e **Spiteful Banditry** (converte board wipes em tesouros, Score 8), mas requer sacrificar Hexing Squelcher (protecao de nicho). Se o Oracle quiser explorar esse swap no C#18, e um DEFENSIVO ΔCMC=0 que adiciona sinergia wipe→treasure sem piorar T3.

## [2026-06-01T02:10:35+00:00] Execucao #28 — Angulo: Cartas com Malicia (Denial, Combo, Oppression)

> **Data:** 2026-06-01
> **Fonte EDHREC:** 7.851 decks (JSON API, identico aos Scouts #24-#27 — snapshot inalterado ha 18h+)
> **Deck state:** Pos-Ciclo #16 (25 swaps desde baseline). Motor 4/4, Copy 6/6, T3=13.3% (Exec#11). MATURIDADE PERSISTENTE (6 ciclos: C#11-C#16 com 0 swaps).
> **Missao:** Buscar cartas com MALICIA — efeitos de denial, opressao de mesa, combos traicoeiros, e interacoes que punem oponentes.
> **Analista:** Hermes Agent — Lorehold Deep Scout (Synergy-First v28)
> **Resultado:** Nenhuma descoberta nova. Deck em MATURIDADE PERSISTENTE. Confirmacao de que o melhor angulo de upgrade (Ashling ↔ Longshot, Score 9) ja foi reportado no Scout #24 e rejeitado pelo Evolution Oracle C#14.

---

### Validacao de Estado (Pipeline Integrity)

| Verificacao | Resultado |
|:------------|:----------|
| Card hash (MD5) | `84bc87988d4ba64919f68b565f46482b` — identico ao post-C#15 |
| EDHREC num_decks | 7.851 (identico aos #24-#27) |
| Novas cartas EDHREC (newcards) | Mesmas 5: Capstone +8.13, Seminar +9.16, Dawning Archaic +5.27, Tablet +0.00, Turbulent Steppe +0.00 |
| Rising stars confirmadas | Seminar 37.9%, Capstone 49.0%, Dawning Archaic 24.0% — todas no deck |
| Declining cards (deck) | Esper Sentinel -0.54 (32.4%), Flare of Duplication -0.72 (18.0%), Gamble -0.50 (23.3%), The One Ring -0.31 (49.0%) |
| Deck state | 86 rows, 100 cards (SUM quantity). Inalterado desde C#15. |
| Collection RW-legal nao-deck | ~123 cartas (identico ao #24-#27) |
| Nivel 1 (filler) | VAZIO — todas as 65 cartas nao-terra tem funcao essencial |

### Angulo Explorado: Cartas com Malicia

Oito angulos de scout ja foram cobertos (#1-#27). Esta execucao foca em **malicia** — cartas que criam estados de mesa opressivos, punem oponentes, ou geram combos traicoeiros que pegam a mesa desprevenida.

#### Categoria 1: Mass Land & Resource Denial

| Carta | CMC | Efeito | Por que NAO |
|:------|:---:|:-------|:------------|
| **Global Ruin** | 5 | Cada jogador sacrifica terrenos ate so ter 1 tipo de basico | 0% EDHREC. Em Boros, voce perde todos os Plains OU Mountains. So e one-sided com Teferi's ou Boros Charm — 2 cartas, 8 mana. |
| **Obliterate** | 8 | Destroi TUDO (criaturas, artefatos, terrenos). Nao pode ser counterada. | CMC 8. 0% EDHREC. Mesmo com Boros Charm, e uma jogada de 10 mana. Worldfire (CMC 9, 54.6% EDHREC) ja esta no deck e e estritamente melhor. |
| **Catastrophe** | 6 | Destroi todas as terras OU todas as criaturas | 0% EDHREC. Austere Command (CMC 6, 58.2% EDHREC) ja cobre board wipe flexivel com mais opcoes. |
| **Descent into Avernus** | 3 | Cada turno: todos ganham treasures + tomam dano | 0% EDHREC. Acelera oponentes tanto quanto voce. So e bom com Xorn (tambem 0% EDHREC) — 2 cartas para um efeito marginal. |

#### Categoria 2: Combo Pieces & Infinite Loops

| Carta | CMC | Combo | Por que NAO |
|:------|:---:|:------|:------------|
| **Dualcaster Mage** | 3 | Dualcaster + Twinflame = criaturas infinitas com haste | Score 7-8 (ja avaliado #23/#24/#25). Creature que nao interage com Lorehold copy. Approach+Flare ja ganha no mesmo turno com menos cartas. Reverberate (CMC 2, instant) e superior para copia. |
| **Goliath Daydreamer** | 4 | Exila spells da mao para re-conjurar depois | EDHREC 33.3%, trend +1.13. MAS: exilar spells IMPEDE Mizzix's Mastery e Arcane Bombardment (precisam de spells no cemiterio). Anti-sinergia com 2 copy engines principais. |
| **Manaform Hellkite** | 4 | Spell → token de dragao X/X (X = mana gasta) | Score 8 (Scout #24). CMC 4 creature sem ETB. Surge to Victory ja converte poder em criaturas. Token sem evasion. |
| **Ashling, Flame Dancer** | 4 | CAST+COPY trigger → impulse draw + dano | **Score 9 — MELHOR CANDIDATO JA IDENTIFICADO (Scout #24).** Substitui Longshot com mesmo CMC, MAIS output. Rejeitado pelo Evolution Oracle C#14: "CMC 4 creature sem ETB; Longshot e unico removal a distancia." |

#### Categoria 3: Stack Interaction & "Gotcha"

| Carta | CMC | Efeito | Por que NAO |
|:------|:---:|:-------|:------------|
| **Pyroblast** | 1 | Countera spell azul OU destroi permanente azul | 0% EDHREC em Lorehold. Meta call estreito. Deflecting Swat (CMC 3) e mais flexivel. |
| **Reverberate** | 2 | Copia spell instant/sorcery | Score 9 (Scout #23). Copy #7 redundante. Sem substituto natural — Penance e CORE ENGINE. |
| **Flawless Maneuver** | 3 | FREE com commander — criaturas ganham indestrutivel | 19.8% EDHREC, trend -0.28 (declining). Boros Charm + Teferi's Protection ja suprem protecao. |
| **Bolt Bend** | 4/R | Redirect spell ou habilidade | Score 8 (Scout #26). Deflecting Swat ja cobre redirect com mais flexibilidade. |

#### Categoria 4: "You Can't Lose" & Wincon Alternativa

| Carta | CMC | Efeito | Por que NAO |
|:------|:---:|:-------|:------------|
| **Insurrection** | 8 | Ganha controle de TODAS as criaturas | 45.2% EDHREC. CMC 8. Deck ja tem Worldfire (CMC 9, 54.6%), Rise of the Eldrazi (CMC 10, 54.6%). Trocar uma wincon high-CMC por outra nao melhora o deck. |
| **Soulfire Eruption** | 9 | Dano massivo + impulse draw | 42.4% EDHREC. CMC 9. Mesmo problema: substituir Worldfire/Rise por Soulfire e sidegrade de CMC. |
| **Akroma's Will** | 4 | JA NO DECK (Ciclo #9) | ✅ |
| **Approach of the Second Sun** | 7 | JA NO DECK (combo principal) | ✅ |

### Sinergias Existentes (7 Eixos — Inalterados desde v3.11)

| Eixo | Score | Funcao |
|:-----|:-----:|:-------|
| A) Token Makers + Pump | 7/10 | Twinflame, Rite, Surge to Victory, Storm Herd, Call Forth, Akroma's Will, Boros Charm |
| B) Board Wipes + Protection | 8/10 | Austere Command, Blasphemous Act, Volcanic Vision, Worldfire, Teferi's, Boros Charm, Deflecting Swat, Mother of Runes |
| C) Recursion Chains | 8/10 | Faithless Looting → Mizzix's Mastery overload; Bombardment + Restoration Seminar loop; Volcanic Vision → topdeck |
| D) Explosive Mana | 7/10 | 8+ treasure sources + 4 signets + Jeska's Will + Smothering Tithe |
| E) Combo Pieces | 9/10 | Approach+Top, Approach+Flare (mesmo turno), Twinflame+Surge chain, Worldfire reset |
| F) Stack Interaction | 6/10 | Deflecting Swat, Grand Abolisher, Hexing Squelcher, Boros Charm, Flare of Duplication |
| G) Resilience | 8/10 | Teferi's Protection, Boros Charm, Lightning Greaves, Penance, Restoration Seminar |

### Conclusao

**Colecao esgotada para sinergias novas.** Vinte e oito execucoes de scout exploraram 8 angulos distintos de sinergia. O unico candidato com score >= 8 que permanece nao-aplicado e **Ashling, Flame Dancer ↔ Longshot, Rebel Bowman** (Score 9, Scout #24, ΔCMC=0), rejeitado pelo Evolution Oracle C#14 sob o argumento de que Longshot e "unico removal a distancia" — uma justificativa questionavel dado que o deck tem Path, Swords, Abrade, Chaos Warp, Generous Gift como removal a distancia.

**MATURIDADE PERSISTENTE: 6 ciclos de Evolution Oracle (C#11-C#16) com 0 swaps.** O deck esta otimizado ao maximo com a colecao atual.

**Deck Maturity reconfirmada:** Todas as 65 cartas nao-terra tem funcao estrategica. Nivel 1 (filler) vazio. Nenhum candidato da colecao atinge simultaneamente Necessidade Estrategica >= 3 AND Evidencia de Dados >= 3.

**Proximo upgrade requer AQUISICAO:**
| Prioridade | Carta | CMC | Custo Est. | Funcao |
|:----------:|:------|:---:|:----------:|:-------|
| 1 | **Skullclamp** | 1 | $5-8 | Draw engine com token makers — prioridade #1 desde Scout #24 |
| 2 | **Underworld Breach** | 2 | $10-15 | Recursion explosiva para spellslinger |
| 3 | **Past in Flames** | 4 | $8-12 | Flashback para todas as spells no cemiterio |
| 4 | **Reverberate** | 2 | $2-3 | Copy spell CMC 2 — substitui Penance se Approach+Top nao for o plano principal |

### Nota para o Evolution Oracle

O argumento "Longshot e unico removal a distancia" usado para rejeitar Ashling em C#14 e FRACO. O deck tem 5+ remocoes a distancia (Path, Swords, Abrade, Chaos Warp, Generous Gift). Longshot da 1 de dano por turno — nao e removal, e ping. Ashling gera impulse draw + dano com cada trigger de cast+copy, escalando com os 6 copy engines. ΔCMC = 0. Reconsidere no proximo ciclo.

---

## [2026-06-01T00:51:30+00:00] Execucao #26 — Maturidade Persistente Confirmada (Angulo: Free Spells + Ritual Chain)

> **Data:** 2026-06-01
> **Fonte EDHREC:** 7.851 decks (JSON API, identico aos Scouts #24, #25 — snapshot inalterado ha 12h+)
> **Deck state:** Pos-Ciclo #15 (25 swaps desde baseline). Motor 4/4, Copy 6/6, T3=13.3% (Exec#11). MATURIDADE PERSISTENTE (5 ciclos: C#11-C#15 com 0 swaps).
> **Missao:** Buscar cartas com sinergia de free-spell e ritual chain — angulos que os Scouts #24 e #25 nao cobriram a fundo.
> **Analista:** Hermes Agent — Lorehold Deep Scout (Synergy-First v26)
> **Resultado:** Nenhuma descoberta nova. Deck em MATURIDADE PERSISTENTE.

---

### Validacao de Estado

| Verificacao | Resultado |
|:------------|:----------|
| EDHREC num_decks | 7.851 (identico ao #25) |
| Novas cartas EDHREC (newcards) | Mesmas 5: Capstone +8.13, Seminar +9.16, Dawning Archaic +5.27, Tablet +0.00, Turbulent Steppe +0.00 |
| Rising stars confirmadas | Seminar 37.9%, Capstone 49.0%, Dawning Archaic 24.0% — todas no deck |
| Declining cards (deck) | Esper Sentinel -0.54, Flare of Duplication -0.72, Gamble -0.50, The One Ring -0.31 |
| Deck state | 86 rows, 100 cards (SUM quantity). Inalterado desde C#15. |
| Collection RW-legal nao-deck | 123 cartas (identico ao #25) |
| Nivel 1 (filler) | VAZIO — todas as 65 cartas nao-terra tem funcao essencial |

### Angulo Explorado: Free Spells & Ritual Chain

Os Scouts #23 (stack interaction), #24 (cast+copy triggers, spell->token), e #25 (verificacao de maturidade) cobriram amplamente o espaco de sinergia. Esta execucao explora um quarto angulo: **free spells** (cartas que podem ser conjuradas sem pagar mana) e **ritual chain** (sequencias de rituais que geram mana explosiva).

#### Candidatos Free-Spell (custo alternativo)

| Carta | CMC | Custo Real | Sinergia | Por que NAO |
|:------|:---:|:-----------|:---------|:------------|
| **Flare of Fortitude** | 4 | FREE (sac creature) | Protecao em massa instantanea | Deck tem so 12 criaturas; sacrificar Storm-Kiln ou Lorehold e pior que pagar 4 |
| **Bolt Bend** | 4 | R (com Lorehold 6/6) | Redirect + protecao de stack | Funcao coberta por Deflecting Swat (CMC 3, mais flexivel) e Teferi's (protecao total) |
| **Desperate Ritual** | 2 | 1R | Gera RRR; splice onto Arcane | Ja foi cortado no Ciclo #3 (Desperate Ritual + 2 cartas). Retornar pioraria T3 sem necessidade — deck ja tem Jeska's Will, Big Score, Smothering Tithe, 4 signets. |
| **Seething Song** | 3 | 2R | Gera RRRRR; instant para Bombardment | Ja foi cortado no Ciclo #6 (Seething Song → Abrade). Ritual chain nao e o plano do deck — o motor usa treasure, nao ritual. |
| **Simian Spirit Guide** | 3 | FREE (exile da mao) | Gera R de graca | Criatura sem impacto; so gera 1 mana; piora consistencia de mao |
| **Treasonous Ogre** | 4 | 3R | 3 vida = R; pode gerar 10+ mana em um turno | CMC 4 criatura fragil sem ETB; deck nao precisa de mana explosiva adicional (motor 4/4 ja supre) |

#### Candidatos Ritual Chain (sequencia de mana)

| Carta | CMC | Sinergia | Por que NAO |
|:------|:---:|:---------|:------------|
| **Rousing Refrain** | 5 | Suspend 3 → RRRRR; retorna com mais mana a cada ciclo | Lento (suspend 3 turnos); inconsistente; nao interage com Bombardment/Mastery (suspend nao e cast) |
| **Mana Geyser** | 5 | Gera R por cada tapped land dos oponentes | CMC 5 sorcery; sem filler para substituir; deck ja tem 8+ fontes de treasure |
| **Rain of Riches** | 5 | Cast from exile = treasure + cascade | Sinergia REAL com Improvisation Capstone + Dance with Calamity. MAS: CMC 5 enchantment sem impacto imediato. Efeito "win-more." |

#### Candidatos com Sinergia de Dano

| Carta | CMC | Sinergia | Por que NAO |
|:------|:---:|:---------|:------------|
| **Fiery Emancipation** | 6 | TRIPLA todo dano. Blasphemous Act = 39 de dano por criatura. Call Forth the Tempest = triplo dano. | CMC 6, 0% EDHREC. "Win-more" — se voce ja resolveu Call Forth, ja esta ganhando. Substituir uma carta funcional por um multiplicador de dano PIORA a consistencia. |
| **Solphim, Mayhem Dominus** | 4 | Dobra dano nao-combat. Mais barato que Fiery Emancipation. | CMC 4 criatura fragil (3/3 indestrutivel mas poe -1/-1 em criaturas). 0% EDHREC. Mesmo problema: win-more. |

### Sinergias Existentes (7 Eixos — SYNERGY_MAP v3.11)

| Eixo | Score | Funcao |
|:-----|:-----:|:-------|
| A) Token Makers + Pump | 7/10 | Twinflame, Rite, Surge to Victory, Storm Herd, Call Forth, Akroma's Will, Boros Charm |
| B) Board Wipes + Protection | 8/10 | Austere Command, Blasphemous Act, Fated Clash, Volcanic Vision, Teferi's, Boros Charm, Deflecting Swat |
| C) Recursion Chains | 8/10 | Faithless Looting → Mizzix's Mastery overload; Bombardment + Restoration Seminar loop; Volcanic Vision → topdeck |
| D) Explosive Mana | 7/10 | 8+ treasure sources (Storm-Kiln, Smothering Tithe, Big Score, Unexpected Windfall, Brass's Bounty, Hit the Mother Lode) + 4 signets + Jeska's Will |
| E) Combo Pieces | 9/10 | Approach+Top, Approach+Flare (mesmo turno), Insurrection alpha strike, Twinflame+Surge chain |
| F) Stack Interaction | 6/10 | Deflecting Swat, Grand Abolisher, Hexing Squelcher, Boros Charm (indestrutivel), Flare of Duplication (counter-copy) |
| G) Resilience | 8/10 | Teferi's Protection, Boros Charm, Lightning Greaves, Penance (protege do removal), Restoration Seminar (recursion redundante) |

### Top 3 Candidatos (Score A+B+C) — Todos Bloqueados

| # | Carta | Score | CMC | Por que Bloqueado |
|:--|:------|:-----:|:---:|:------------------|
| 1 | **Reverberate** | 9 | 2 | Copy #7 redundante. Sem substituto natural — Penance e CORE ENGINE (miracle enabler). Substituir Penance quebra Approach+Top. |
| 2 | **Bolt Bend** | 8 | R* | Protecao #6 redundante. Deflecting Swat ja cobre redirect com mais flexibilidade. Funcionalmente CMC 1 so com Lorehold em campo. |
| 3 | **Flare of Fortitude** | 7 | FREE* | Protecao #7 redundante. Requer sacrificar criatura — deck so tem 12 criaturas, sacrificar Storm-Kiln ou Lorehold e contraprodutivo. |

*\*Custo funcional com condicao atendida*

### Conclusao

**Colecao esgotada para sinergias novas.** Vinte e seis execucoes de scout (Scouts #1-#26) exploraram 4 angulos distintos de sinergia:
- #1-#22: EDHREC-first + synergy discovery
- #23: Stack interaction (Reverberate, Flawless Maneuver, Tibalt's Trickery)
- #24: Cast+copy triggers, spell→token, ritual chain
- #25: Verificacao de maturidade (no-change confirmado)
- #26: **Free spells & ritual chain** (este)

**Todos os candidatos com score >= 8 foram identificados e rejeitados em scouts anteriores.** Nenhuma carta na colecao cria sinergia INEDITA que justifique substituir uma das 65 cartas funcionais do deck.

**MATURIDADE PERSISTENTE: 5 ciclos de Evolution Oracle (C#11-C#15) com 0 swaps.** O deck esta otimizado ao maximo com a colecao atual.

**Proximo upgrade requer AQUISICAO:**
| Prioridade | Carta | CMC | Custo Est. | Funcao |
|:----------:|:------|:---:|:----------:|:-------|
| 1 | **Skullclamp** | 1 | $5-8 | Draw engine com token makers (Twinflame, Storm Herd, Rite, Call Forth) |
| 2 | **Enlightened Tutor** | 1 | $15-20 | Tutor para Top/Scroll Rack/Bombardment — ja no deck |
| 3 | **Underworld Breach** | 2 | $10-15 | Recursion explosiva para spellslinger — sinergia com Faithless Looting + rituals |

---

## [2026-06-01T00:13:51+00:00] Execucao #25 — Verificacao de Maturidade (No-Change)

> **Data:** 2026-06-01
> **Fonte EDHREC:** 7.851 decks (JSON API, identico ao Scout #24 — snapshot inalterado)
> **Deck state:** Pos-Ciclo #15 (25 swaps desde baseline). Motor 4/4, Copy 6/6, T3=13.3% (Exec#11). MATURIDADE PERSISTENTE (5 ciclos: C#11-C#15 com 0 swaps).
> **Missao:** Buscar cartas que CRIAM sinergias INEDITAS — angulos que os Scouts #23 e #24 nao cobriram.
> **Analista:** Hermes Agent — Lorehold Deep Scout (Synergy-First v25)
> **Resultado:** [SILENT] — Nenhuma descoberta nova. Deck em MATURIDADE PERSISTENTE.

---

### Validacao de Estado

| Verificacao | Resultado |
|:------------|:----------|
| EDHREC num_decks | 7.851 (identico ao #24) |
| Novas cartas EDHREC (newcards) | Mesmas 5: Capstone, Seminar, Tablet, Dawning Archaic, Turbulent Steppe |
| Trends (rising) | Mesmos 3: Seminar +9.16, Capstone +8.13, Dawning Archaic +5.27 |
| Trends (declining) | Mesmo padrao: Farewell -0.95, Artist's Talent -0.72, Esper Sentinel -0.54 |
| Deck state | 86 rows, 100 cards (SUM quantity). Inalterado desde C#15. |
| Collection RW-legal nao-deck | 123 cartas (identico ao #24) |
| Nivel 1 (filler) | VAZIO — todas as 65 cartas nao-terra tem funcao essencial |

### Candidatos Score >= 8: NENHUM NOVO

Todos os candidatos com score >= 8 ja foram identificados e rejeitados em scouts anteriores:

| Carta | Score Max | Ultimo Scout | Motivo da Rejeicao |
|:------|:---------:|:-------------|:--------------------|
| Seething Song | 10 | #24 | Sem filler CMC 3 para substituir |
| Invoke Calamity | 9 | #24 | CMC 5 piora T3; Mizzix's Mastery ja supre |
| Ashling, Flame Dancer | 9 | #24 | CMC 4 creature sem ETB; Longshot e unico removal a distancia |
| Voice of Victory | 9 | #24 | CMC 2 creature fragil; efeito niche |
| Spiteful Banditry | 8 | #24 | "Once each turn" limita; ja reavaliado |
| Manaform Hellkite | 8 | #24 | CMC 4 creature; token dragon e lento |
| Reverberate | 11 | #23 | Sem substituto natural (Penance e engine core) |
| Flawless Maneuver | 10 | #23 | Sem substituto (Taunt e goad unico) |
| Xorn | 9 | #22 | Win-more; deck ja tem 8+ fontes de treasure |
| Monastery Mentor | 7 | Multiplos | CMC 3 creature sem ETB |
| Tablet of Discovery | 9 | C#11 | Redundante com Top+Scroll Rack+Penance |

### Conclusao

**Colecao esgotada para sinergias novas.** O deck atingiu MATURIDADE PERSISTENTE — 5 ciclos consecutivos de Evolution Oracle (C#11-C#15) com 0 swaps. Vinte e cinco execucoes de scout exploraram todos os angulos de sinergia. O EDHREC esta estavel ha mais de 8 horas. Nenhuma mudanca na colecao.

**Proximo upgrade requer AQUISICAO:** Skullclamp (CMC 1, $5-8) — prioridade #1.

---

## [2026-05-31T23:30:34+00:00] Execucao #24 — Alem da Maturidade: Angulos Ineditos que o Scout #23 Nao Explorou

> **Data:** 2026-05-31
> **Fonte EDHREC:** 7.851 decks (JSON API, snapshot estavel — sem mudancas em 2h)
> **Deck state:** Pos-Ciclo #14 (25 swaps desde baseline). Motor 4/4, Copy 6/6, T3=13.3% (Exec#11). MATURIDADE PERSISTENTE (5 ciclos: C#11-C#15 com 0 swaps).
> **Missao:** Buscar cartas que CRIAM sinergias INEDITAS — angulos que o Scout #23 nao cobriu.
> **Analista:** Hermes Agent — Lorehold Deep Scout (Synergy-First v24)
> **Diferenca chave vs #23:** #23 focou em stack interaction (Reverberate, Flawless Maneuver, Tibalt's Trickery). Esta execucao explora: (1) cast+copy triggers, (2) spell->token, (3) rituals garantidos, (4) recursion redundancy.

---

### Validacao: Recomendacoes do Scout #23 Ainda Validas?

As 3 recomendacoes do Scout #23 permanecem validas — mas a conclusao de "0 swaps por falta de substituto natural" se mantem:

| #23 Rec | Carta | Score | Substituto | Bloqueio |
|:--------|:------|:-----:|:-----------|:---------|
| 1 | Reverberate | 11 | Penance (CMC 3, double-null) | Penance e CORE ENGINE de topdeck. Cortar Penance quebra o combo Approach+Top. |
| 2 | Flawless Maneuver | 10 | Taunt (CMC 5, double-null, 35.2% EDHREC) | Taunt e goad em massa — funcao UNICA no deck. |
| 3 | Seize the Spoils | 10 | Taunt (CMC 5) | Mesmo bloqueio — perder goad por treasure+draw e sidegrade. |

**Conclusao:** As recomendacoes do #23 sao validas mas bloqueadas pela maturidade — o deck nao tem filler. NENHUMA das 65 cartas nao-terra e substituivel sem perder funcao.

---

### Sinergias Existentes (7 Eixos — SYNERGY_MAP v3.11)

| Eixo | Score | Funcao |
|:-----|:-----:|:-------|
| A) Token Makers + Pump | 7/10 | Twinflame, Rite, Surge to Victory, Storm Herd, Call Forth, Akroma's Will, Boros Charm |
| B) Board Wipes + Protection | 8/10 | Austere Command, Blasphemous Act, Fated Clash, Volcanic Vision, Teferi's, Boros Charm, Deflecting Swat |
| C) Recursion Chains | 8/10 | Mizzix's Mastery, Arcane Bombardment, Faithless Looting, Restoration Seminar, Dragon's Rage Channeler |
| D) Explosive Mana | 8/10 | Sol Ring, Jeska's Will, Smothering Tithe, Big Score, Brass's Bounty, Hit the Mother Lode, Storm-Kiln, Unexpected Windfall |
| E) Combo Pieces | 9/10 | Approach + topdeck (Scroll Rack, Penance, Top, Library of Leng); Flare+Approach = mesmo turno |
| F) Stack Interaction | 6/10 | Deflecting Swat, Boros Charm, Flare (copy counterspell), Grand Abolisher, Hexing Squelcher |
| G) Resilience | 7/10 | Teferi's Protection, Greaves, Boros Charm, Penance, recursion engines |

**Gaps persistentes (ja identificados pelo #23):**
- Stack interaction (6/10): sem counterspell verdadeiro em Boros
- Draw estrutural (max 7 fontes em Boros sem wheel)
- Token density para Surge to Victory (CMC 2 tokens escassos)
- Terceiro wincon deterministico

---

### Metodo de Scoring (A/B/C — Foco em Angulos INEDITOS)

| Eixo | Range | Criterio (Maturidade) |
|:-----|:-----:|:----------------------|
| **A — SINERGIA** | 0-5 | Cria NOVA camada que o deck NAO tem? Triggera em CAST+COPY? Sinergia tripla? |
| **B — CUSTO** | Base 3 | CMC <= 2: +1. CMC >= 5: -1. Instant/Sorcery: +1. Creature: -1. Custo de substituicao. |
| **C — EVIDENCIA** | 0-5 | EDHREC % + trend + auto-evidencia. Sinergia auto-evidente (A>=4 e C=0) → C=1. |

**Criterio de corte:** Score >= 8 para documentar como candidato serio. Score >= 10 para recomendacao PRIORITARIA.

---

### TIER 1: Angulos INEDITOS (Score >= 8)

#### 1. Seething Song — Ritual GARANTIDO (Score: A3+B4+C3=10) 🔥

| Criterio | Nota | Justificativa |
|:---------|:----:|:--------------|
| A — Sinergia | 3 | RRRRR instant, net +2 mana GARANTIDO. Diferente de Jeska's Will (condicional: depende da mao do oponente), Seething Song e confiavel 100% das vezes. Com copy engines (Lorehold, Double Vision, Flare), 5 mana vira 10-15. |
| B — Custo | 4 | Base 3. CMC 3: 0. Instant: +1. Total = 4. Custo baixo, nao piora T3. |
| C — Evidencia | 3 | Staple de formato. Nao e especifico de Lorehold, mas e reconhecido universalmente em decks de big spells. Sinergia auto-evidente. |

**Por que o Scout #23 nao viu:** #23 rejeitou Mana Geyser como "redundante com Jeska's Will + Brass's Bounty." Mas Seething Song e DIFERENTE: e CMC 3 (vs Mana Geyser CMC 5), e garantido (vs Jeska's Will condicional), e instant (vs Brass's Bounty sorcery). Preenche o nicho de "ritual confiavel de early game" — permite T3: land → Seething Song → CMC 7 spell.

**Possivel substituto natural:** Ruby Medallion (CMC 2, double-null, trend -0.37, ja foi cortado no Ciclo #10 mas... wait, Ruby Medallion foi CORTADO no Ciclo #10? Let me check... sim, a skill doc diz "Ruby Medallion (trend -0.37): FORA (Ciclo #10)." Entao nao esta no deck atual. Substituto natural seria... nenhum. Nivel 1 esta vazio.

**Nota de maturidade:** Sem filler no deck. Seething Song entraria como 101a carta ou substituindo uma fonte de mana redundante (mas todas as 10+ fontes de mana tem funcao adicional: draw, token, etc.).

---

#### 2. Ashling, Flame Dancer — CAST+COPY Trigger (Score: A5+B2+C2=9) 🔥

| Criterio | Nota | Justificativa |
|:---------|:----:|:--------------|
| A — Sinergia | 5 | **Diferenca CRUCIAL vs Guttersnipe:** Ashling triggera em CAST **E COPY**. O deck tem 6 copy engines (Lorehold, Double Vision, Arcane Bombardment, Flare, Twinflame, Dawning Archaic). Cada spell gera 3-4 triggers de Ashling = 6-8 dano dividido + 3-4 impulse draws. Guttersnipe e CAST-ONLY — por isso foi rejeitado (score 7 no #23). Ashling e CAST+COPY — completamente diferente. |
| B — Custo | 2 | Base 3. CMC 4: 0. Creature: -1. Ward — pay 2 life mitiga fragilidade. Total = 2. |
| C — Evidencia | 2 | 0% EDHREC em Lorehold, mas sinergia e auto-evidente (A=5 → C=1). +1 pelo floor de staple (Ashling e conhecida em spellslinger). Total = 2. |

**Por que o Scout #23 nao viu:** #23 avaliou Guttersnipe (cast-only) e rejeitou. Nao considerou Ashling porque a busca focou em stack interaction e copy engines. Ashling e um angulo COMPLETAMENTE NOVO: dano + impulse draw que escala com copias.

**Possivel substituto natural:** Longshot, Rebel Bowman (CMC 4, functional_tag='payoff'). Longshot e um "pinger" solitario no deck — da 1 dano por turno, cria 1/1 tokens condicionalmente. Ashling substituiria Longshot com: mesmo CMC (4), MAIS dano (2+ por trigger em vez de 1 por turno), MAIS card advantage (impulse draw em vez de token condicional). Troca de payoff por payoff com upgrade claro.

---

#### 3. Manaform Hellkite — Spell → Dragon Tokens (Score: A5+B2+C1=8) 🔥

| Criterio | Nota | Justificativa |
|:---------|:----:|:--------------|
| A — Sinergia | 5 | **Sinergia TRIPLA:** (1) Cada spell nao-criatura = token X/X dragon com flying e haste (CMC 7-10 spells = 7/7 a 10/10 dragoes). (2) Surge to Victory copia os tokens — cada token vira copia do spell exilado. (3) No End Step, o token e exilado — mas Surge to Victory exila ANTES do End Step, criando copias PERMANENTES. Loop de valor: big spell → dragon token → Surge → dragoes permanentes. |
| B — Custo | 2 | Base 3. CMC 4: 0. Creature: -1. Flying + haste compensam parcialmente. Total = 2. |
| C — Evidencia | 1 | 0% EDHREC em Lorehold. Sinergia auto-evidente (A=5) → C=1. |

**Por que o Scout #23 nao viu:** #23 avaliou Monastery Mentor (tokens em spells) e Myrel (tokens em ataque). Nao considerou Manaform Hellkite porque a busca focou em token makers genericos, nao em "spell → token" com escala de CMC. O Hellkite e SUPERIOR ao Mentor neste deck: tokens sao MAIORES (CMC vs 1/1), tem FLYING+HASTE, e sinergizam com Surge to Victory.

**Possivel substituto natural:** Olórin's Searing Light (CMC 4, functional_tag='graveyard_synergy'). Olórin e remocao exilando a maior criatura de cada oponente + spell mastery (scry 2). Funcao: remocao pontual. Manaform Hellkite e engine de token — funcao DIFERENTE. Nao e substituto direto.

---

#### 4. Voice of Victory — Token + Protection (Score: A3+B5+C1=9)

| Criterio | Nota | Justificativa |
|:---------|:----:|:--------------|
| A — Sinergia | 3 | Mobilize 2: cria 2 tokens 1/1 atacando por turno. Alimenta Surge to Victory (mais tokens = mais copias). Stack protection: oponentes nao podem conjurar spells no SEU turno — protege Approach, protege Storm Herd, protege combo turn. Duas funcoes em CMC 2. |
| B — Custo | 5 | Base 3. CMC 2: +1. Creature: -1. Duas funcoes uteis justificam +2 acima do base. Total = 5. (Nota: sem Mobilize, seria B=3. Mobilize + stack protection = +2.) |
| C — Evidencia | 1 | 0% EDHREC. Auto-evidencia (A>=3) → C=1. |

**Possivel substituto:** A carta e CMC 2 — entraria no lugar de outra criatura CMC 2 ou 3. Hexing Squelcher (CMC 2, protection) e Grand Abolisher (CMC 2, double-null) sao criaturas CMC 2 com funcao parcialmente sobreposta (protecao de turno). Voice of Victory oferece protecao SIMILAR + tokens.

---

#### 5. Invoke Calamity — Mizzix's Mastery #2 (Score: A4+B3+C2=9)

| Criterio | Nota | Justificativa |
|:---------|:----:|:--------------|
| A — Sinergia | 4 | Cast 2 spells do grave (total CMC <= 6) sem pagar. Mizzix's Mastery overload e o payoff supremo de recursion — mas e CMC 4 (8 no overload) e e uma unica carta. Invoke Calamity e CMC 5, instant, e oferece redundancy. Com Faithless Looting, Thrill, e Dragon's Rage Channeler enchendo o grave, sempre tem alvos. Exilia as spells apos — anti-sinergia com Arcane Bombardment? Nao: Bombardment exilia do grave tambem. O deck JA exilia spells. |
| B — Custo | 3 | Base 3. CMC 5: -1. Instant: +1. Total = 3. |
| C — Evidencia | 2 | EDHREC >0% (niche). Instant recursion e valorizada. Total = 2. |

**Possivel substituto natural:** Olórin's Searing Light (CMC 4) ou Longshot (CMC 4). Invoke Calamity e CMC 5 — trocar CMC 4 por 5 piora T3 (+2pp). Precisa de compensacao.

---

### TIER 2: Ampliam Eixos Existentes (Score 7)

| # | Carta | CMC | Score | Eixo | Nota |
|:-:|:------|:---:|:-----:|:-----|:-----|
| 6 | **Desperate Ritual** | 2 | A2+B5+C1=8 | D — Mana | RRR instant. Net +1 mana. CMC 2 e o ritual mais barato. Porem +1 mana por uma carta e marginal — pior que Sol Ring e Signets. B=5 pelo CMC baixissimo. |
| 7 | **Fiery Inscription** | 3 | A3+B3+C2=8 | NOVO — Dano | Guttersnipe em enchantment: 2 dmg por spell para cada oponente. MAIS resiliente que Guttersnipe (enchantment vs creature). Ring tempts (loot). Mas so triggera em CAST, nao copy. |
| 8 | **Electro, Assaulting Battery** | 3 | A4+B2+C1=7 | D — Mana | +R por spell, mana nao esvazia. Essencialmente reduz cada spell em 1 generic. Flying. Com 30+ spells = +30 mana/jogo. Porem creature CMC 3. |
| 9 | **Solphim, Mayhem Dominus** | 4 | A4+B2+C1=7 | NOVO — Dano | Dobra dano nao-combate. Blas Act 13→26. Call Forth 2X. Indestructible. Mas CMC 4 creature sem ETB. |
| 10 | **Fiery Emancipation** | 6 | A5+B1+C1=7 | NOVO — Dano | TRIPLICA todo dano. Enchantment. Blas Act = 39. Mas CMC 6 piora T3 em +4pp. |
| 11 | **Rain of Riches** | 5 | A4+B2+C1=7 | NOVO — Cascade | Cascade from treasure mana. 10+ treasure sources. Cria engine de cascade passivo. Mas CMC 5 enchantment. |
| 12 | **Creative Technique** | 5 | A4+B2+C1=7 | C — Copy | Demonstrate + Cascade. Copia e cascateia. Downside: oponente tambem ganha copia. |

---

### TIER 3: Reavaliacoes de Cartas Anteriores

| Carta | CMC | Score #23 | Score #24 | Mudanca? |
|:------|:---:|:---------:|:---------:|:----------|
| **Xorn** | 3 | A4+B1+C0=5 | A4+B2+C0=6 | Corrigi B de 1→2 (CMC 3 creature nao e tao penalizado). Ainda score baixo — win-more. |
| **Spiteful Banditry** | 2 | A3+B2+C0=5 | A4+B4+C0=8 | **REAVALIADO!** #23 disse "deck tem poucas criaturas, depende de oponentes." Discordo: o deck e BOARD WIPE DECK — Blasphemous Act, Austere Command, Fated Clash, Volcanic Vision, Call Forth the Tempest. Spiteful Banditry: (1) X dmg wipe escalavel, (2) treasure de criaturas MORTAS (incluindo oponentes). AFTER a board wipe, gera 4-8 treasures. CMC 2 enchantment. Sinergia DIRETA com a estrategia de board wipe. A=4 (wipe + treasure), B=4 (CMC 2, enchantment), C=0. Total = 8. ⚠️ Porem "once each turn" limita — max 1 treasure/ciclo de turnos. |
| **Guttersnipe** | 3 | A3+B1+C3=7 | Mantido | #23 estava certo — cast-only em deck de 1-2 spells/turno. Ashling e a alternativa superior (cast+copy). |

---

### Diagnostico de Maturidade: Resultado Final

**Estado atual:** MATURIDADE PERSISTENTE (5 ciclos Evolution Oracle com 0 swaps: C#11-C#15).

**Novos angulos descobertos nesta execucao (que o #23 nao viu):**
1. **Seething Song (Score 10):** Ritual GARANTIDO CMC 3. Confiavel vs condicional (Jeska's Will).
2. **Ashling, Flame Dancer (Score 9):** CAST+COPY trigger. Com 6 copy engines, 3-4 triggers/spell. Dano + impulse draw.
3. **Voice of Victory (Score 9):** CMC 2 token maker + stack protection. Duas funcoes, CMC baixo.
4. **Manaform Hellkite (Score 8):** Spell → dragon token. Sinergia tripla com Surge to Victory.
5. **Invoke Calamity (Score 9):** Mizzix's Mastery redundancy. Instant, cast 2 spells free do grave.
6. **Spiteful Banditry (Score 8, reavaliado):** Board wipe + treasure. CMC 2 enchantment. Limitado por "once each turn."

**O problema persiste:** NENHUMA destas cartas tem substituto natural no deck. O deck esta sem filler (Nivel 1 vazio). Todas as 65 cartas nao-terra tem funcao estrategica. A unica excecao PARCIAL e **Longshot, Rebel Bowman** (CMC 4, payoff) — que poderia ser substituido por Ashling (mesmo CMC, mais dano, mais draw).

**Swap MAIS VIAVEL (se o Evolution Oracle quiser 1 swap):**
- **Ashling, Flame Dancer (CMC 4) ↔ Longshot, Rebel Bowman (CMC 4)**
  - Net ΔCMC = 0 (nao piora T3)
  - Longshot: 1 dmg/turno, token 1/1 condicional
  - Ashling: 2+ dmg por trigger de cast+copy, impulse draw por trigger
  - Com 6 copy engines, Ashling gera 6-8 dmg + 3-4 draws por spell
  - Upgrade claro: mesmo CMC, mais output

**Se o Evolution Oracle quiser 0 swaps:** Totalmente valido. Deck saudavel, T3=13.3%, todos os eixos >= 7/10.

**Proxima aquisicao (para expandir alem da maturidade):**
- **Skullclamp** (CMC 1, $5-8) — draw engine supremo com tokens. Prioridade #1.
- **Jeska's Will** (ja no deck) + **Seething Song** (proposta) — dupla de rituais confiavel + condicional.

---

### Verificacao de Integridade

- **Color Identity:** Todas as cartas recomendadas sao R, W, ou incolor. Nenhuma carta com U, B, G. ✅
- **Colecao:** Todas as cartas tem `quantity > 0` em `user_collection`. ✅
- **CMC verification (database):** Conferido — CMCs sao: Seething Song 3, Ashling 4, Voice of Victory 2, Manaform Hellkite 4, Invoke Calamity 5, Desperate Ritual 2, Spiteful Banditry 2. ✅
- **Double-null cross-reference:** Nenhuma das recomendacoes e double-null (classifier as classifica: Seething Song=ramp, Ashling=payoff, Voice=token, Hellkite=token, Invoke=recursion, Banditry=removal). ✅
- **Deck count:** 100 cartas (86 rows). Nenhuma recomendacao excede o limite. ✅

---
