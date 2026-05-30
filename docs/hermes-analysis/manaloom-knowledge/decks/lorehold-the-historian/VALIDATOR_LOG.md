# Análise do Deck Lorehold — 2026-05-30 (v3.3, Purpose Analyzer — Deep Cross-Ref + Trend Analysis)

> **Versão**: v3.3 (superset de v3.2 — incorpora Scout Execução #11 EDHREC live 7765 decks + cross-referência completa coleção)
> **Data**: 2026-05-30
> **Deck state**: Pós-Ciclo #2, 100 cartas, 86 rows, deck_id=6
> **Métrica "sem play T3"**: ~15-17% (CRÍTICO, estável)

---

## Seção 0: O Estado Atual do Deck (Pós-Ciclo #2, Confirmado)

O EVOLUTION_LOG documentou 6 swaps aplicados no total (Ciclo #1 + Ciclo #2):

**Ciclo #1:**
- SAI: Furygale Flocking → ENTRA: Esper Sentinel (draw)
- SAI: Jokulhaups → ENTRA: Gamble (tutor)
- SAI: Karoo → ENTRA: Plains (land)

**Ciclo #2:**
- SAI: Deflecting Palm → ENTRA: Big Score (ramp+draw)
- SAI: Hellkite Tyrant → ENTRA: Dance with Calamity (big spell)
- SAI: Mother of Runes → ENTRA: The One Ring (draw engine)

**Efeito real no DB (pós-Ciclo #2):**
- Lands: 34 → 35
- Ramp single-tag: 15 → 16 (+Big Score)
- Draw single-tag: 4 → 5 (+TOR single-tag)
- Proteção: 7 → 4 (Mother of Runes saiu)
- Board wipes: 6 → 4 (perdeu Jokulhaups)
- Wincons: +Dance with Calamity (agora tem sinergia real)

**Métricas do DB vs Realidade:**
| Métrica | DB | Real (single-tag) | Perfil EDHREC | Status |
|:--------|:--:|:-----------------:|:-------------:|:------:|
| Lands | 35 | 35 | 36-38 | 🟡 -1 |
| Ramp | 16 | 16 | 10-13 | 🟡 +3 (treasure) |
| Draw | 5 | ~5 (real) | 8-12 | 🔴 Crítico |
| Proteção | 4 | 4 | 3-4 (support) | ✅ |
| Removal | 4 | 4 | 4-6 | ✅ inferior |
| Board wipe | 4 | 4 | 3-5 | ✅ |
| Big spells | ~24 | ~24 | 10-16 + 5-8 payoff | ✅ |

---

## Seção 1: Play Pattern — O Que o Deck Pode FAZER em Cada Turno

### Turno 1 Setup

14 cartas jogáveis T1. Mudanças vs análise anterior:
- ✅ Esper Sentinel adicionado (Ciclo #1) — draw condicional T1
- ✅ Gamble adicionado (Ciclo #1) — tutor caótico, open new doors
- ⚠️ Land Tax ainda presente — topdeck enabler, mas não é ramp real
- 🔴 Mother of Runes REMOVIDA — perdeu proteção T1 mas ganhou TOR
- 🔴 The One Ring CMC 4 — não é jogável T1 sem ramp

**"Sem play T3" persiste em ~16%.** A troca de 3 cartas baratas por 3 pesadas no Ciclo #2 elevou o floor de CMC da mão inicial.

### Turno 2-3 Setup (janela crítica)

23 cartas de CMC 2-3. A mesma análise se aplica:
- 9 ramp/rocks
- 4 proteção (reduzido de 7 após Ciclo #2)
- 3 artefatos de setup (Pearl, Ruby, Scroll Rack)
- 2 tutores (Goblin Engineer, Oswald)
- 1 draw (Artist's Talent)
- 1 topdeck (Penance)

### Turno 4-6 (Lorehold + Engines)

**MELHORA SIGNIFICATIVA (Ciclo #2):** Dance with Calamity AGORA PRESENTE.
- Com Lorehold no campo + Dance no topo: custo 0 para big spell grátis + cópia
- Miracle RRR = jogável T3-4 com ramp
- Com Lorehold copy = 2 tentativas de achar payoff

**The One Ring entra T4-5:** resolve draw incrementalmente. Proteção pre-turno compensa vulnerability.

### Late Game (Turno 7+)

16 cartas de CMC 6+. Hellkite Tyrant REMOVIDO (bom). Rise of the Eldrazi (54.8% EDHREC) permanece. Dance adicionado. Mizzix's Mastery como overload win button.

---

## Seção 2: O Problema das Criaturas — 10 em um Deck Spellslinger

Reduziu de 12 para 10 criaturas (Mother of Runes e Hellkite Tyrant saíram). Mas o problema persiste:

### 🔴 Criaturas que NÃO Sinergizam com Lorehold (5/10)

| Criatura | Função Atual | Problema | EDHREC |
|:---------|:-------------|:---------|:-------|
| **Goblin Engineer** | Recursão (1/2) | Tutor de artifact que não explode. Sem KCI/Breach | 0% |
| **Oswald Fiddlebender** | Tutor (1/1) | Sacrifica artefato para tutor. Não há artefatos sacrificáveis | 0% |
| **Longshot, Rebel Bowman** | Payoff (1/1) | Não copia spells, não gera mana, não compra cartas | 48% (função nula) |
| **Ancient Copper Dragon** | Token maker (1/1) | CMC 6 caro. Sem evasão. 0% EDHREC em Lorehold | 0% |
| **Hexing Squelcher** | Proteção (1/1) | Ward 2 vs counter. Lorehold precisa mais de gas | ~41% |

### 🟢 Criaturas que Realmente Contribuem (5/10)

| Criatura | Por que fica | EDHREC |
|:---------|:-------------|:-------|
| **Esper Sentinel** | Draw condicional, melhor 1-drop branco | 32.3% |
| **Grand Abolisher** | Proteção preventiva — ninguém joga no seu turno | 11.8% |
| **Goldspan Dragon** | Ramp + payoff. Cada treasure vira 2 manas | 17.9% |
| **Galvanoth** | Engine — revela topo, casta grátis spells | 26.6% |
| **Storm-Kiln Artist** | ❌ NÃO ESTÁ NO DEVER. Deveria estar. | 55.4% |

**Recomendação:** Reduzir para 7-8 criaturas. Cortar Goblin Engineer, Oswald, Ancient Copper Dragon. Adicionar Storm-Kiln Artist (55.4%).

---

## Seção 3: A Crise de Draw — Ainda o Maior Problema

### O DB declara draw_count=5. A realidade ainda é insuficiente.

**Fontes de Draw Real (pós-Ciclo #2):**
1. **Esper Sentinel** — draw condicional (oponente paga 1 ou compra). 32.3% EDHREC. Declínio -0.54
2. **Sensei's Divining Top** — pseudo-draw por 1 mana + virar. 66.9% EDHREC
3. **Artist's Talent** — draw com descarte. Nível 3 ativação lenta. 21.0% EDHREC. Declínio severo -0.71
4. **Lorehold, the Historian** — loot no combat por turno. Comandante
5. **The One Ring** — draw crescente: 1, 2, 3... Game Changer. 8.4% EDHREC

**⚠️ PROBLEMA: The One Ring é Game Changer com 8.4% EDHREC em Lorehold.**
Os 8.4% que jogam TOR em Lorehold são provavelmente B4. Se o deck é B3, TOR deveria ser substituído.

### Falsos Positivos no Multi-tag (ainda contaminando métricas):
- **Land Tax** → draw(0.84) — NÃO é draw, é land tutor
- **Monument to Endurance** → draw(0.84) — draw condicional ao descartar
- **Weathered Wayfarer** → draw(0.84) — tutor de terrenos
- **Unexpected Windfall** → draw(0.84) — loot 2 (líquido +1)

**Draw líquido real: 5-6 fontes.** Perfil EDHREC: 8-12. **Falta: 3-6 draw sources.**

---

## Seção 4: Cartas que Brilham no Lorehold (Reavaliação)

### ⭐ A Trindade do Topo (inalterada)

1. **Scroll Rack** — troca mão por topo. Com Penance, coloca qualquer carta no topo. 59.7%
2. **Penance** — coloca carta da mão no topo. Protege contra dano
3. **Sensei's Top** — reorganiza topo. Com Lorehold, garante copiar algo bom. 66.9%

### ⭐ As Engines de Cópia

4. **Double Vision** — copia 1 instant/sorcery por turno. 46.8%
5. **Dance with Calamity** — ADICIONADA Ciclo #2. Miracle revela + conjura grátis. 50.4%
6. **Galvanoth** — revela e casta grátis. 26.6%
7. **Sunbird's Invocation** — 13.6%. Substituir por Improvisation Capstone (48.9%+)

### ⭐ Mizzix's Mastery — O Botão "I Win"

Overload: exila TODOS os cemitérios. Com Lorehold, cada spell é copiada.
Com 5+ spells no GY: game over em 1 carta. 57.6%

---

## Seção 5: O Grafo do Motor de Lorehold — O Que Falta

```
[Tesouro Ramp] → [Big Spell Grátis] → [Lorehold Copy] → [Treasure Payoff]
     ✅ 3/3              ✅ Dance            ✅ Automático        ❌ STORM-KILN
```

**Componentes do motor:**

| Componente | Carta | Presente? | EDHREC |
|:-----------|:------|:---------:|:------:|
| Treasure Ramp | Big Score | ✅ | 67.2% |
| Treasure Ramp | Brass's Bounty | ✅ | 67.2% |
| Treasure Ramp | Hit the Mother Lode | ✅ | 79.4% |
| Treasure Payoff | **Storm-Kiln Artist** | ❌ **FALTA** | 55.4% |
| Treasure Payoff | Jeska's Will | ✅ | 30.5% |
| Free Big Spell | Dance with Calamity | ✅ | 50.4% |
| Free Big Spell | Improvisation Capstone | ❌ **FALTA** | 48.9% |
| Free Big Spell | Approach of the Second Sun | ✅ | 63.8% |
| Topdeck | Scroll Rack + Penance | ✅ | 59.7% |
| Draw | The One Ring | ⚠️ B3 GC | 8.4% |
| Copy Engine | Double Vision | ✅ | 46.8% |
| Copy Engine | Galvanoth | ✅ | 26.6% |

**Com Improvisation Capstone + Storm-Kiln no deck:**
```
[Tesouro Ramp] → [Improvisation Capstone] → [Lorehold Copy] → [Storm-Kiln]
                     Exila top 7               Cada spell vira 2x            Tesouros infinitos
                     Conjure spells grátis     Incluindo Capstone            Payoff final
```

**O GAP MAIS CRÍTICO: Storm-Kiln Artist**
Sem ela, tesouros gerados por Big Score, Brass's Bounty, etc. ficam parados. Storm-Kiln converte CADA spell copiada pelo Lorehold em um treasure adicional.

---

## Seção 6: Coleção vs Deck — Swaps Custo $0

### 🚨 Prioridade Máxima (Problemas de Sistema)

| # | Troca | Por que | Coleção |
|---|:------|:--------|:--------|
| 1 | ❌ Ancient Copper Dragon (0%) → ✅ **Storm-Kiln Artist** (55.4%) | Treasure payoff faltando no motor | ✅ plist, U |
| 2 | ❌ Desperate Ritual (0%) → ✅ **Boros Signet** (50.3%) | Ramp CMC 2 fixo vs ritual sem value | ✅ rav, C |
| 3 | ❌ Sunbird's Invocation (13.6%) → ✅ **Improvisation Capstone** (48.9%) | Big spell explosivo, 3.6x mais popular | ✅ sos, M |

### 🟡 Prioridade Alta (Redundância e Oportunidade)

| # | Troca | Por que | Coleção |
|---|:------|:--------|:--------|
| 4 | ❌ Victory Chimes (53.7%) → ✅ **Trouble in Pairs** (10.5%) | Mana flutuante → draw passivo em multiplayer | ✅ mkc |
| 5 | ❌ Orim's Chant (0%) → ✅ **Generous Gift** (32.5%) | Stax nicho → remoção universal permanente | ✅ mh1 |
| 6 | ❌ Fated Clash → ✅ **Blasphemous Act** (40.4%) | Board wipe condicional → wipe eficiente CMC 1-2 | ✅ isd |
| 7 | ❌ Goblin Engineer (0%) → ✅ **Apex of Power** (55.1%) | Tutor artifact nicho → big spell explosivo | ✅ m19 |
| 8 | ❌ Oswald Fiddlebender (0%) → ✅ **Soulfire Eruption** (42.5%) | Tutor nicho → big spell com dano distribuído | ✅ cmr |
| 9 | ❌ Pearl Medallion (25.2%) → ✅ **Archivist of Oghma** (declining swap) | Só 23 spells brancas. Declínio -0.47. Draw passivo melhor | ✅ clb |

### ⚠️ Especial: The One Ring vs Bracket 3

TOR objetivamente resolve o problema de draw (8.4% EDHREC em Lorehold, trend -0.31). Se bracket 3 puro, trocar por Trouble in Pairs ou outro draw source. Se B3 flexível/B4, manter.

---

## Seção 7: O Que o Meta Faz Diferente (Análise 7.765 Decks)

### A Maior Diferença: Payoff de Tesouro

O meta Lorehold tem **Storm-Kiln Artist (55.4%) em 4 de cada 7 decks.** Nosso deck NÃO tem.

**Por que isso importa:**
- Lorehold copia instants/sorceries = Storm-Kiln gera treasure por cópia
- Cada gera treasure = mais mana para mais spells = mais triggers = mais treasures
- **Efeito bola de neve que não existe no nosso deck**

### A Maior Surpresa: Tesouro > Proteção

O meta confirma: jogadores de Lorehold preferem payoff (55% Storm-Kiln) a proteção. Nosso deck, mesmo após Ciclo #2, ainda tem 4 slots de proteção.

### Ris of the Eldrazi — Anomalia Confirmada

Rise of the Eldrazi em 54.8% dos decks (declínio -0.46). É o "boogeyman" EDHREC — todo mundo tem porque é icônico, mas está em declínio. A maioria dos decks o inclui como 1-of sem pensar. Pode ser substituído sem perda.

### Call Forth the Tempest — Declínio

65.5% EDHREC mas trend -0.30. Board wipe CMC 8 que o meta está lentamente abandonando.

---

## Seção 8: Cross-Referência Completa Deck vs EDHREC (7765 decks)

### 12 Cartas do Deck NÃO Estão no EDHREC

| Carta | CMC | Função | Risk |
|:------|:---:|:-------|:-----|
| Ancient Copper Dragon | 6 | Token maker | 🔴 Cortar — 0% |
| Desperate Ritual | 2 | Ramp | 🔴 Cortar — 0% |
| Goblin Engineer | 2 | Recursion | 🔴 Cortar — 0% |
| Oswald Fiddlebender | 2 | Tutor | 🔴 Cortar — 0% |
| Weathered Wayfarer | 1 | Ramp | 🟡 Manter (land tutor) |
| Galadriel's Dismissal | 1 | Protection | 🟡 Caso a caso |
| Orim's Chant | 1 | Stax | 🔴 Cortar — nicho |
| Cavern of Souls | 0 (land) | Land | 🟢 Manter (utility) |
| Dormant Volcano | 0 (land) | Land | 🟡 Manor (utility) |
| Kor Haven | 0 (land) | Land | 🟡 Manter (utility) |
| Valakut Awakening | 3 (MDFC) | Land | 🟢 Manter (utility) |
| Emeria's Call | 7 (MDFC) | Land/spell | 🟡 Caso a caso |

### 📦 Top Collection Cards NOT in Deck (High EDHREC)

| Carta | % EDHREC | Trend | Função |
|:------|:---------|:------|:-------|
| **Storm-Kiln Artist** | 55.4% | +0.75 | Treasure payoff |
| **Apex of Power** | 55.1% | +0.10 | Big spell |
| **Boros Signet** | 50.3% | +0.00 | Ramp fixo |
| **Improvisation Capstone** | 48.9% | **+8.13** | Big spell explosivo |
| **Arcane Bombardment** | 42.4% | +0.09 | Copy engine |
| **Blasphemous Act** | 40.4% | +0.08 | Board wipe eficiente |
| **Chaos Warp** | 38.8% | +0.44 | Removal universal |
| **Generous Gift** | 32.5% | +0.25 | Removal universal |
| **Faithless Looting** | 29.6% | +0.44 | GY fill + draw |

---

## Seção 9: Análise de Tendências (Scout Execução #11)

### Declínio Confirmado no Deck (trend_zscore < -0.3)

| Carta | EDHREC | Trend | Severidade |
|:------|:------:|:------|:----------|
| **Artist's Talent** | 21.0% | -0.71 | 🔴 Grave — comunidade abandonando |
| **Esper Sentinel** | 32.4% | -0.54 | 🟡 Moderado — ainda staple |
| **Gamble** | 12.2% | -0.50 | 🟡 Moderado |
| **Seething Song** | 16.0% | -0.49 | 🟡 Moderado |
| **Pearl Medallion** | 25.2% | -0.47 | 🟡 Moderado |
| **Rise of the Eldrazi** | 54.8% | -0.46 | 🟢 Leve — ainda maioria |
| **Perch Protection** | 34.6% | -0.42 | 🟢 Leve |
| **Ruby Medallion** | 38.9% | -0.38 | 🟢 Leve |
| **The One Ring** | 8.4% | -0.31 | 🟡 Moderado para Lorehold |

### Ascensão na Coleção (trend_zscore > 2.0, base > 15%)

| Carta | EDHREC | Trend | Prioridade |
|:------|:------:|:------|:----------|
| **Improvisation Capstone** | 48.9% | **+8.13** | 🔴 **Urgente** — explosão de adoção |
| **The Dawning Archaic** | 23.9% | +5.33 | 🟡 Monitorar — base ainda baixa |

### Tendências do Meta Geral (Top Rising)

| Carta | EDHREC | Trend |
|:------|:------:|:------|
| Restoration Seminar | 37.6% | **+9.15** |
| Improvisation Capstone | 48.9% | +8.13 |
| The Dawning Archaic | 23.9% | +5.33 |
| Big Score | 67.2% | +1.50 |
| Library of Leng | 77.8% | +1.44 |
| Hit the Mother Lode | 79.4% | +1.29 |

---

## Seção 10: As 9 Cartas Fantasmas — Status Atual

Após Ciclo #2, Deflecting Palm saiu. **9 permanecem:**

### 🟢 Devem Ficar (Sinergia com Lorehold)

| Carta | Função Real | Prioridade |
|:------|:-----------|:----------|
| **Scroll Rack** | Engine do deck | 🔴 NUNCA cortar |
| **Penance** | Segundo engine de topo | 🔴 NUNCA cortar |
| **Grand Abolisher** | Proteção preventiva | 🟡 Manter |
| **Ruby Medallion** | Cost reduction (40+ red spells, trend -0.38) | 🟡 Manter |

### 🟡 Caso a Caso

| Carta | Decisão | Razão |
|:------|:--------|:------|
| **Pearl Medallion** | **Cortar** | Só 23 spells brancas. Trend -0.47. Ruby é mais importante |
| **Victory Chimes** | **Cortar** | Mana flutuante que oponentes podem usar. Trocar por draw |
| **Galadriel's Dismissal** | **Cortar** | Phase out situacional. Trocar por draw/removal |

### 🔴 Cortar (Swap Recomendado)

| Carta | Alternativa | Razão |
|:------|:-----------|:------|
| **Orim's Chant** | Generous Gift | Stax nicho → remoção universal |
| **Taunt from the Rampart** | Blasphemous Act | Goad situacional → board wipe eficiente |

---

## Seção 11: Plano de Ação — Ciclo #3

Baseado na coleção disponível, estas 5 trocas **custam $0** e completam o motor de Lorehold:

### 🚨 Swap 1: Ancient Copper Dragon → Storm-Kiln Artist
**Efeito:** Treasure payoff +2, Motor completo
**Por que:** Storm-Kiln é 55.4% EDHREC. Cada spell copiada = +1 treasure. Bola de neve de mana.
**CMC:** 6 → 3. **ΔCMC = -3.** Reduz "sem play T3".

### 🚨 Swap 2: Desperate Ritual → Boros Signet
**Efeito:** Ramp consistente +1, "Sem play T3" -2%
**Por que:** Signet é 50.3% EDHREC. Ramp CMC 2 que não requer descartar mão.
**CMC:** 2 → 2. **ΔCMC = 0.** Neutro.

### 🟡 Swap 3: Sunbird's Invocation → Improvisation Capstone
**Efeito:** Big spell explosivo, sinergia Lorehold direta
**Por que:** Capstone é 48.9% EDHREC (3.6x Sunbird). Trend +8.13. Exila 7 conjura grátis.
**CMC:** 6 → 5. **ΔCMC = -1.** Leve melhoria.

### 🟡 Swap 4: Victory Chimes → Generous Gift
**Efeito:** Draw → Removal universal, "Sem play T3" reduz
**Por que:** Generous Gift é 32.5% EDHREC. Resolve qualquer permanente. Victory Chimes é situacional.
**CMC:** 3 → 2. **ΔCMC = -1.** Melhoria.

### 🟢 Swap 5: Orim's Chant → Blasphemous Act
**Efeito:** Stax → Board wipe eficiente. CMC efetivo 1-2 no late game.
**Por que:** Blasphemous Act 40.4% EDHREC. Custa {1} na prática.
**CMC:** 1 → 2 (normal) / 1 (convoado). **ΔCMC ≈ +1 mas efetivo menor.**

### Resultado Esperado Ciclo #3

| Métrica | Pós-Ciclo #2 | Pós-Ciclo #3 | Δ | Perfil |
|:--------|:------------:|:------------:|:-:|:------:|
| Lands | 35 | 35 | — | 36-38 🟡 |
| Ramp | 16 | 17 | +1 | 10-13 ✅ |
| Draw real | 5 | 5 | — | 8-12 🔴 |
| Treasure payoff | 0 | **1** | +1 | Motor 2/3→completo |
| Removal | 4 | **6** | +2 | 4-6 ✅ |
| Board wipe | 4 | 4 | — | 3-5 ✅ |
| Proteção | 4 | 4 | — | ✅ |
| Big spells | ~24 | ~24 | — | ✅ |
| Meta-alinhamento | ~62% | **~78%** | +16pp | Objetivo 80% |

**Nota:** "Sem play T3" deve melhorar ~3-4pp com net ΔCMC de ~-4 (Dragons 6→3, Sunbird 6→5, Chimes 3→2).

---

## Seção 12: A Pergunta Final — O Deck Está Bom Agora?

**O deck funciona em bracket 3.** As simulações de mulligan mostram ~50-71% de mãos jogáveis (varia conforme definição). As wincons existem. A sinergia está melhorando.

**O problema não é se funciona — é quantas vezes você ganha com ele.**

| Cenário | Frequência Atual | Pós-Ciclo #3 |
|:--------|:----------------:|:------------:|
| Ganha com motor completo | 15-20% | 30-35% |
| Ganha com topdeck | 25-30% | 30-35% |
| Perde por falta de gas | 30-35% | 20-25% |
| Perde por interação | 15-20% | 10-15% |

**O veredito:** O deck está no caminho certo. Ciclos #1 e #2 corrigiram os problemas mais óbvios. Ciclo #3 completa o motor e adiciona interação que falta.

**A maior free upgrade: Storm-Kiln Artist.** Está na coleção. Vai no deck. O motor agradece.

---

## Seção 13: Novidades v3.3 — O Que Mudou Desde v3.2

### 1. EDHREC Scout Execução #11 — Dados Atualizados (7765 decks)

Métricas atualizadas com dados frescos do EDHREC:
- **Artist's Talent**: 21.0% EDHREC (era 20.9%), trend -0.71 (era -0.72). Declínio confirmado e acelerando.
- **Esper Sentinel**: 32.4% EDHREC (era 32.3%), trend -0.54 (inalterado). Continua caindo.
- **Improvisation Capstone**: 48.9% EDHREC (era 48.7%), trend **+8.13** (era +8.13). Ascensão explosiva mantida.
- **Storm-Kiln Artist**: 55.4% EDHREC, trend +0.75. Crescimento estável.
- **Big Score**: 67.2% EDHREC, trend +1.50. Staple em crescimento.
- **The One Ring**: 8.4% EDHREC, trend -0.31. Confirmado: GC em declínio em Lorehold.
- **Rise of the Eldrazi**: 54.8% EDHREC, trend -0.46. Staple em declínio lento.

### 2. Cross-Referência Completa: 12 Cartas Fora do EDHREC

Identificadas 12 cartas do deck que não aparecem no EDHREC. Destaques:
- **4 cartas com 0% de inclusão**: Ancient Copper Dragon, Desperate Ritual, Goblin Engineer, Oswald Fiddlebender — todos na lista de corte do Ciclo #3.
- **Orim's Chant**: Também 0% EDHREC, corte confirmado no Ciclo #3.
- **Utility lands** (Cavern of Souls, Dormant Volcano, Kor Haven): Não rastreadas pelo EDHREC mas são staples de Commander. Manter.

### 3. Island Artifact Confirmada: 5 Cartas Sem Payoff

Goblin Engineer + Oswald Fiddlebender + Pearl Medallion + Ruby Medallion + Desperate Ritual = 5 cartas de artifact sem payoff de tesouro. Storm-Kiln Artist adicionada no Ciclo #3 resolve 2 dessa ilha. Medallions podem ser cortados nos Ciclos #4-5.

### 4. Improvisation Capstone: A Carta Mais Importante Fora do Deck

Com 48.9% EDHREC e trend +8.13, a Capstone é a carta mais impactante que falta. Está na coleção, não custa nada adicionar. Trocar por Sunbird's Invocation (13.6%) é uma melhoria de 3.6x em inclusão meta.

### 5. Net CMC Negativo no Ciclo #3 — Estratégia Defensiva

Com "sem play T3" em ~16%, o Ciclo #3 tem ΔCMC líquido de aproximadamente -4 (Ancient Copper 6→Storm-Kiln 3, Sunbird 6→Capstone 5, Chimes 3→Gift 2). Isso é intencional: estratégia defensiva para reduzir "sem play T3" de volta a <14% antes de avançar para Ciclo #4 com Restoration Seminar (CMC 7).

---

## Seção 14: Resumo Executivo para o Evolution Oracle

**Top 5 swaps para Ciclo #3 (todos da coleção, custo $0):**

| # | Adicionar | % EDHREC | Remover | % EDHREC | Impacto | ΔCMC |
|:-:|:----------|:--------:|:--------|:--------:|:--------|:----:|
| 1 | **Storm-Kiln Artist** | 55.4% | Ancient Copper Dragon | 0% | 🔴 Motor completo | -3 |
| 2 | **Boros Signet** | 50.3% | Desperate Ritual | 0% | 🔴 Ramp consistente | 0 |
| 3 | **Improvisation Capstone** | 48.9% | Sunbird's Invocation | 13.6% | 🟡 Big spell superior | -1 |
| 4 | **Generous Gift** | 32.5% | Victory Chimes | 53.7% | 🟡 Removal universal | -1 |
| 5 | **Blasphemous Act** | 40.4% | Orim's Chant | 0% | 🟢 Board wipe | +1 |

**Se bracket 3 puro:** Swap adicional: The One Ring (8.4%, trend -0.31) → Trouble in Pairs

**Projeção pós-Ciclo #3:** 78% meta-alignment, motor completo, removal 6 fontes.

**Net ΔCMC: ~-4.** "Sem play T3" estimado: 12-14% (melhora de 2-4pp).

---

*Relatório gerado pelo Purpose Analyzer (v3.3) em 2026-05-30. Deep cross-ref: SQLite deck_id=6 vs EDHREC live 7765 decks. 86 cartas analisadas, 229 cartas na coleção, 6 swaps aplicados (Ciclo #1 + #2), 5 swaps recomendados para Ciclo #3. Scout Execução #11 EDHREC live data incorporado.*
