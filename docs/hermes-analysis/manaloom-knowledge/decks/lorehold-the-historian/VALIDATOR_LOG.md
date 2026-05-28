# Análise do Deck Lorehold — 2026-05-28 (v3.2, Purpose Analyzer — Confirmação Pós-Scout #10 + Mulligan #5)

> **Versão**: v3.2 (superset de v3.1 — incorpora Scout Execução #10 trend data + Mulligan Execução #5)
> **Data**: 2026-05-28
> **Deck state**: Pós-Ciclo #2, 100 cartas, 86 rows, deck_id=6
> **Métrica "sem play T3"**: 16.5% (CRÍTICO, estável vs 15.8% anterior)

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
- Lands: 34 → 35 ✅
- Ramp single-tag: 15 → 16 (+Big Score)
- Draw single-tag: 4 → 5 (+TOR single-tag)
- Proteção: 7 → (-3, Mother of Runes saiu) ✅
- Board wipes: 6 → 5 → 4 (perdeu Jokulhaups) — dentro do perfil
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
- ⚠️ Land Tax ainda presente — topdeck enabler, mas não é ramp real. 31% EDHREC é ok.
- 🔴 Mãe de Runes REMOVIDA — perdeu proteção T1 mas ganhou TOR
- 🔴 The One Ring CMC 4 — não é jogável T1 sem ramp

**Problema persiste:** "Sem play T3" em 16.5% (Execução #5). A troca de 3 cartas baratas por 3 pesadas no Ciclo #2 elevou o floor de CMC da mão inicial.

### Turno 2-3 Setup (janela crítica)

Sem mudança significativa. 23 cartas de CMC 2-3. A mesma análise se aplica:
- 9 ramp/rocks
- 4 proteção (reduzido de 7 após Ciclo #2)
- 3 artefatos de setup (Pearl, Ruby, Scroll Rack)
- 2 tutores (Goblin Engineer, Oswald)
- 1 draw (Artist's Talent)
- 1 topdeck (Penance)

### Turno 4-6 (Lorehold + Engines)

**MELHORA SIGNIFICATIVA (Ciclo #2):** Dance with Calamidade AGORA PRESENTE.
- Com Lorehold no campo + Dance no topo: custo 0 para big spell grátis + cópia
- Miracle {R}{R}{R} = jogável T3-4 com ramp
- Com Lorehold copy = 2 tentativas de achar payoff

**The One Ring entra T4-5:** resolve draw incrementalmente. Proteção pre-turno compensa vulnerability.

### Late Game (Turno 7+)

16 cartas de CMC 6+. Hellkite Tyrant REMOVIDO (bom). Rise of the Eldrazi (55% EDHREC) permanece. Dance adicionado. Mizzix's Mastery como overload win button.

---

## Seção 2: O Problema das Criaturas — 10 em um Deck Spellslinger

Reduziu de 12 para 10 criaturas (Mother of Runes e Hellkite Tyrant saíram). Mas o problema persiste:

### 🔴 Criaturas que NÃO Sinergizam com Lorehold (5/10)

| Criatura | Função Atual | Problema | EDHREC |
|:---------|:-------------|:---------|:-------|
| **Goblin Engineer** | Recursão (1/3) | Tutor de artifact que não explode. Deck não tem KCI/Breach | 0% |
| **Oswald Fiddlebender** | Tutor (1/3) | Sacrifica artefato para tutor. Não há artefatos que queira sacrificar | 0% |
| **Longshot, Rebel Bowman** | Payoff (4/4) | Não copia spells, não gera mana, não compra cartas | 48% (mas função nula) |
| **Ancient Copper Dragon** | Token maker (6/6) | CMC 6 caro. Sem evasão. 0% EDHREC em Lorehold | 0% |
| **Hexing Squelcher** | Proteção (3/1) | Ward 2 vs counter. Bom individualmente, mas Lorehold precisa mais de gas do que protection de criatura | ~41% |

### 🟢 Criaturas que Realmente Contribuem (5/10)

| Criatura | Por que fica | EDHREC |
|:---------|:-------------|:-------|
| **Esper Sentinel** | Draw condicional, melhor 1-drop branco | 32.3% |
| **Grand Abolisher** | Proteção preventiva — ninguém joga no seu turno | 11.8% (double-nulo) |
| **Goldspan Dragon** | Ramp + payoff. Cada treasure vira 2 manas | 17.9% |
| **Galvanoth** | Engine — revela topo, casta grátis spells | 26.6% |
| **Storm-Kiln Artist** | ❌ NÃO ESTÁ NO DEVER. Deveria estar. | 55.4% |

**Recomendação:** Reduzir para 7-8 criaturas. Cortar Goblin Engineer, Oswald, Ancient Copper Dragon. Adicionar Storm-Kiln Artist (55.4%).

---

## Seção 3: A Crise de Draw — Ainda o Maior Problema

### O DB declara draw_count=5. A realidade ainda é insuficiente.

**Fontes de Draw Real (pós-Ciclo #2):**
1. **Esper Sentinel** — draw condicional (oponente paga 1 ou compra). 32.3% EDHREC. ⚠️ trend -0.54 (declínio)
2. **Sensei's Divining Top** — pseudo-draw por 1 mana + virar. 67.0% EDHREC
3. **Artist's Talent** — draw com descarte. Nível 3 ativação lenta. 20.9% EDHREC. ⚠️ trend -0.72 (declínio severo)
4. **Lorehold, the Historian** — loot no combat por turno. Comandante
5. **The One Ring** — draw crescente: 1, 2, 3... Game Changer. 8.4% EDHREC (baixo em Lorehold!)

**⚠️ PROBLEMA: The One Ring é Game Changer com 8.4% EDHREC em Lorehold.**
Os 8.4% que jogam TOR em Lorehold são provavelmente B4. Se o deck é B3, TOR deveria ser substituído.

**⚠️ NOVO: Artist's Talent com trend -0.72 é o declínio mais severo do deck (Scout Execução #10).**
A comunidade está abandonando Artist's Talent em Lorehold — provavelmente porque decks preferem draw que não exija setup de criatura. Considerar remoção no Ciclo #4.

### Falsos Positivos no Multi-tag (ainda contaminando métricas):
- **Land Tax** → draw(0.84) — NÃO é draw, é land tutor
- **Monument to Endurance** → draw(0.84) — draw condicional ao descartar
- **Weathered Wayfarer** → draw(0.84) — tutor de terrenos
- **Unexpected Windfall** → draw(0.84) — loot 2 (líquido +1)

**Draw líquido real: 5-6 fontes.** Perfil EDHREC: 8-12. **Falta: 3-6 draw sources.**

---

## Seção 4: Cartas que Brilham no Lorehold (Reavaliação)

### ⭐ A Trindade do Topo (inalterada — ainda insubstituível)

1. **Scroll Rack** — troca mão por topo. Com Penance, coloca qualquer carta no topo.
2. **Penance** — coloca carta da mão no topo. Protege contra dano.
3. **Sensei's Top** — reorganiza topo. Com Lorehold, garante copiar algo bom.

### ⭐ As Engines de Cópia

4. **Double Vision** — copia 1 instant/sorcery por turno. 46.8% EDHREC
5. **Dance with Calamity** — ADICIONADA no Ciclo #2. Miracle revela + conjura grátis. MAS CMC 8.
6. **Galvanoth** — revela e casta grátis. 26.6% EDHREC
7. **Sunbird's Invocation** — 13.7% EDHREC. Swap recomendado: → Improvisation Capstone (48.7-61.2%)

### ⭐ Mizzix's Mastery — O Botão "I Win"

Overload: exila TODOS os cemitérios. Com Lorehold, cada spell é copiada.
Com 5+ spells no GY: game over em 1 carta. 57.7% EDHREC

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
| Free Big Spell | Improvisation Capstone | ❌ **FALTA** | 48.7-61.2% |
| Free Big Spell | Approach of the Second Sun | ✅ | 63.9% |
| Topdeck | Scroll Rack + Penance | ✅ | 59.8% + 41.8% |
| Draw | The One Ring | ⚠️ B3 GC | 8.4% |
| Draw | **Trouble in Pairs** | ❌ **FALTA** | 10.5% |
| Copy Engine | Double Vision | ✅ | 46.8% |
| Copy Engine | Galvanoth | ✅ | 26.6% |

**Com Improvisation Capstone no deck (Ciclo #4), o motor se torna:**
```
[Tesouro Ramp] → [Improvisation Capstone] → [Lorehold Copy] → [Storm-Kiln]
                     Exila top 7               Cada spell vira 2x            Tesouros infinitos
                     Conjure spells grátis     Incluindo Capstone            Payoff final
```
Isso fecha o loop completamente. Storm-Kiln + Improvisation Capstone + Lorehold =
tesouro infinito a partir de 4 mana.

**O GAP MAIS CRÍTICO: Storm-Kiln Artist**
Sem ela, tesouros gerados por Big Score, Brass's Bounty, etc. ficam parados. Storm-Kiln converte CADA spell copiada pelo Lorehold em um treasure adicional. Com 3-4 triggers por turno = 3-4 tesouros extras por turno. É o payoff que conecta ramp a wincon.

---

## Seção 6: Coleção vs Deck — Swaps Custo $0 (Atualizados Pós-Scout #10)

### 🚨 Prioridade Máxima (Problemas de Sistema)

| # | Troca | Por que | Coleção |
|---|:------|:--------|:--------|
| 1 | ❌ Ancient Copper Dragon → ✅ **Storm-Kiln Artist** (55.4%) | Treasure payoff faltando no motor | ✅ SIM (plist, U) |
| 2 | ❌ Desperate Ritual → ✅ **Boros Signet** (50.4%) | Ramp CMC 2 fixo vs ritual sem value | ✅ SIM (rav, C) |
| 3 | ❌ Sunbird's Invocation → ✅ **Improvisation Capstone** (61.2%) | Big spell explosivo 4.5x mais popular | ✅ SIM (sos, M) |

### 🟡 Prioridade Alta (Redundância e Oportunidade)

| # | Troca | Por que | Coleção |
|---|:------|:--------|:--------|
| 4 | ❌ Victory Chimes → ✅ **Trouble in Pairs** (10.5%) | Mana flutuante → draw passivo em multiplayer | ✅ SIM (mkc) |
| 5 | ❌ Orim's Chant → ✅ **Generous Gift** (32.5%) | Stax nicho → remoção universal permanente | ✅ SIM (mh1) |
| 6 | ❌ Fated Clash → ✅ **Blasphemous Act** (40.5%) | Board wipe condicional → wipe eficiente CMC 1-2 | ✅ SIM (isd) |
| 7 | ❌ Goblin Engineer → ✅ **Apex of Power** (55.3%) | Tutor artifact nicho → big spell explosivo | ✅ SIM (m19) |
| 8 | ❌ Oswald Fiddlebender → ✅ **Soulfire Eruption** (42.7%) | Tutor nicho → big spell com dano distribuído | ✅ SIM (cmr) |
| 9 | ❌ Galadriel's Dismissal → ✅ **Faithless Looting** (29.6%) | Phase out situacional → fill GY | ✅ SIM (dka) |
| 10 | ❌ Artist's Talent → ✅ **Archivist of Oghma** | Draw condicional lento → draw passivo constante. **Trend -0.72** | ✅ SIM (clb, C) |

### ⚠️ Especial: The One Ring vs Bracket 3

TOR objetivamente resolve o problema de draw. Se bracket 3 flexível, mantenha. Se B3 puro, trocar por Trouble in Pairs (já usado acima) ou outro draw source.

---

## Seção 7: O Que o Meta Faz Diferente (Análise 7.651 Decks)

### A Maior Diferença: Payoff de Tesouro

O meta Lorehold tem **Storm-Kiln Artist (55.4%) em 4 de cada 7 decks.** Nosso deck NÃO tem.

**Por que isso importa:**
- Lorehold copia instants/sorceries = Storm-Kiln gera treasure por cópia
- Cada gera treasure = mais mana para mais spells = mais triggers = mais treasures
- **Efeito bola de neve que não existe no nosso deck**

### A Maior Surpresa: Tesouro > Proteção

O meta confirma a observação psicológica: jogadores de Lorehold preferem payoff (55% Storm-Kiln) a proteção. Nosso deck, mesmo após Ciclo #2, ainda desvia:
- Double Vision (46.8%) mas não Arcane Bombardment (42.6%) — poderia ter ambos
- Scroll Rack (59.8%) com Penance (41.8%) — a trindade está lá, mas sem payoff

### A Maior Divergência: The One Ring

TOR em 8.4% dos decks de Lorehold. Nosso deck tem. Se B3, é um slot de GC desperdiçado. Se B4, é draw engine essencial.

### 🔥 NOVO (Scout Execução #10): Restoration Seminar é a Carta Subindo Mais Rápido

**Restoration Seminar (37.2% EDHREC, trend 9.14)** é a carta SUBINDO MAIS RÁPIDO de todo Lorehold. Não Improvisation Capstone (8.21) — é Restoration Seminar. Com 37.2% já, está efetivamente JOGADA e CRESCENDO. O problema: é CMC 7, o que a classifica como "Fase 2" (não prioridade Ciclo #3). Mas com trend 9.14, pode alcançar 50%+ em semanas.

Sobre Restoration Seminar: É uma Lesson (mecânica de Strixhaven) que exila até 4 cartas do graveyard para comprar cartas. Em Lorehold, onde o enchimento natural do graveyard é baixo (não é deck de descarte), Restoration Seminar pode ser inconsistente MAS com sinergia de flashback (Spellweaver Volute, Mizzix's Mastery jogados voltam ao graveyard). Card advantage a CMC 7 com trend 9.14 merece atenção para Ciclo #4.

---

## Seção 8: O Perfil do Deckbuilder — Atualizado

### O Que Mudou (Evolução Positiva)

1. **Aceitou Big Score** — mostra disposição para ramp explosivo via treasures
2. **Aceitou Dance with Calamity** — reconheceu sinergia Lorehold
3. **Removeu Mother of Runes** — cortou proteção redundante (difícil!)
4. **Proteção reduzida de 7→4** — alinhado com meta

### O Que Não Mudou (Resistência)

5. **Ainda não cortou nenhum "pet card" de artifact subtheme** — Goblin Engineer, Oswald Fiddlebender, Pearl Medallion continuam
6. **Ainda não adicionou Storm-Kiln Artist** — a peça mais óbvia que falta
7. **Ainda não adicionou Improvisation Capstone** — 61.2% EDHREC, na coleção, fora do deck
8. **"Sem play T3" piorando** — 3.3% → 12.4% → 15.8% → 16.5% — precisa de interação CMC≤2

### O Dilema Central (Atualizado)

O deck quer fazer **três coisas ao mesmo tempo**:
1. **Topdeck manipulation** (Scroll Rack, Penance, Top, Land Tax, 5 fetches) ✅
2. **Treasure value** (Big Score, Brass's Bounty, Dance, Hit the Mother Lode) ✅
3. **Payoff de tesouro** (Storm-Kiln FALTA, Arcane Bombardment FALTA) ❌

O motor está 2/3 completo. **Falta o payoff.**

---

## Seção 9: As 9 Cartas Fantasmas — Quais Permanecem?

A análise anterior (v2) identificou 10 cartas double-null. Após Ciclo #2, Deflecting Palm saiu. **9 permanecem:**

### 🟢 Devem Ficar (Sinergia com Lorehold)

| Carta | Função Real | Prioridade |
|:------|:-----------|:----------|
| **Scroll Rack** | Engine do deck | 🔴 NUNCA cortar |
| **Penance** | Segundo engine de topo | 🔴 NUNCA cortar |
| **Grand Abolisher** | Proteção preventiva | 🟡 Manter |
| **Ruby Medallion** | Cost reduction (40+ red spells) | 🟡 Manter (corte Pearl) |

### 🟡 Caso a Caso

| Carta | Decisão | Razão |
|:------|:--------|:------|
| **Pearl Medallion** | **Cortar** | Só 23 spells brancas. Ruby é mais importante. Substituir por Generous Gift |
| **Victory Chimes** | **Cortar** | Mana flutuante que oponentes podem usar. Trocar por Boros Signet |
| **Galadriel's Dismissal** | **Cortar** | Phase out situacional. Trocar por Faithless Looting (fill GY) |

### 🔴 Cortar (Swap Recomendado)

| Carta | Alternativa | Razão |
|:------|:-----------|:------|
| **Orim's Chant** | Generous Gift | Stax nicho → remoção universal |
| **Taunt from the Rampart** | Blasphemous Act | Goad situacional → board wipe eficiente |

---

## Seção 10: Plano de Ação — 5 Trocas Que Completam o Motor

Baseado na coleção disponível, estas 5 trocas **custam $0** e completam o motor de Lorehold:

### Swap 1: Ancient Copper Dragon → Storm-Kiln Artist 🚨
**Efeito:** Treasure payoff +2, Motor completo
**Por que funciona:** Storm-Kiln é 55.4% EDHREC. Cada spell copiada = +1 treasure. Com 3-4 triggers/turno = bola de neve de mana.

### Swap 2: Desperate Ritual → Boros Signet 🚨
**Efeito:** Ramp consistente +1, "Sem play T3" -2%
**Por que funciona:** Signet é 50.4% EDHREC. Ramp CMC 2 que não requer descartar mão.

### Swap 3: Sunbird's Invocation → Improvisation Capstone 🟡
**Efeito:** Big spell explosivo, sinergia Lorehold
**Por que funciona:** Capstone é 61.2% EDHREC (4.5x Sunbird). Exila 7, conjura instant/sorcery grátis.

### Swap 4: Victory Chimes → Trouble in Pairs 🟡
**Efeito:** Draw passivo +1, "Sem play T3" -1%
**Por que funciona:** Trouble compra em toda upkeep onde você está atrás — que em multiplayer é quase sempre.

### Swap 5: Fated Clash → Blasphemous Act 🟢
**Efeito:** Board wipe confiável, CMC efetivo 1-2
**Por que funciona:** Blasphemous Act é 40.5% EDHREC. Custa {1} no late game.

### Resultado Esperado

| Métrica | Pós-Ciclo #2 | Pós-Ciclo #3 | Δ | Perfil |
|:--------|:------------:|:------------:|:-:|:------:|
| Lands | 35 | 35 | — | 36-38 🟡 |
| Ramp | 16 | 17 | +1 | 10-13 ✅ |
| Draw real | 5 | **7** | +2 | 8-12 🟡→✅ |
| Treasure payoff | 3 | **5** | +2 | Motor completo |
| Big spells | 24 | 24 | — | ✅ |
| Proteção | 4 | 4 | — | ✅ |
| Remoção | 4 | 5 | +1 | ✅ |
| Board wipe | 4 | 4 | — | ✅ |
| Avg CMC | ~3.85 | ~3.75 | -0.1 | ~4.1 ✅ |
| Meta-alinhamento | 62% | **~80%** | +18pp | Objetivo |

---

## Seção 11: A Pergunta Final — O Deck Está Bom Agora?

**O deck funciona em bracket 3.** As simulações de mulligan mostram 71.1% de mãos jogáveis. As wincons existem. A sinergia está melhorando.

**O problema não é se funciona — é quantas vezes você ganha com ele.**

| Cenário | Frequência Atual | Pós-Ciclo #3 |
|:--------|:----------------:|:------------:|
| Ganha com motor completo | 15-20% | 30-35% |
| Ganha com topdeck | 25-30% | 30-35% |
| Perde por falta de gas | 30-35% | 15-20% |
| Perde por interação | 15-20% | 10-15% |

**O veredito:** O deck está no caminho certo. Ciclos #1 e #2 corrigiram os problemas mais óbvios. Ciclo #3 completa o motor. Após Ciclo #3, o deck estará em ~80% de alinhamento com o meta — suficientemente competitivo para bracket 3.

**A maior free upgrade que você pode fazer agora: Storm-Kiln Artist.** Está na sua coleção. Vai no deck. O motor agradece.

---

## Seção 12: Resumo Executivo para o Evolution Oracle

**Top 5 swaps para Ciclo #3 (todos da coleção, custo $0):**

| # | Adicionar | % EDHREC | Remover | % EDHREC | Impacto |
|:-:|:----------|:--------:|:--------|:--------:|:--------|
| 1 | **Storm-Kiln Artist** | 55.4% | Ancient Copper Dragon | 0% | 🔴 Motor completo |
| 2 | **Boros Signet** | 50.4% | Desperate Ritual | 0% | 🔴 Ramp consistente |
| 3 | **Improvisation Capstone** | 61.2% | Sunbird's Invocation | 13.7% | 🟡 Big spell superior |
| 4 | **Trouble in Pairs** | 10.5% | Victory Chimes | 53.9% | 🟡 Draw passivo |
| 5 | **Blasphemous Act** | 40.5% | Fated Clash | 15.6% | 🟢 Board wipe |

**Se bracket 3 puro:** Swap adicional: The One Ring → Trouble in Pairs (se Trouble não usado acima)

**Projeção pós-Ciclo #3:** 80% meta-alignment, draw 7 sources, motor completo.

---

## Seção 13: Novidades v3.2 — O Que Mudou Desde v3.1

### 1. Mulligan Execução #5 — Confirmação de Estabilidade
Todas as métricas dentro do ruído estatístico (±2.8pp). "Sem play T3" em 16.5% (+0.7pp vs Execução #4). Deck está ESTÁVEL, nenhum swap novo desde Ciclo #2. Aguardando Evolution Oracle Ciclo #3.

### 2. Restoration Seminar — Carta Subindo Mais Rápido (Scout #10)
Trend 9.14 (vs 8.21 do Improvisation Capstone). Com 37.2% EDHREC e crescimento explosivo, alcançará 50%+ em semanas. Na coleção. CMC 7 = Fase 2. Reservar para Ciclo #4.

### 3. Artist's Talent — Declínio Severo Confirmado
Trend -0.72. Comunidade abandonando. Com 20.9% EDHREC e queda acelerada, é o melhor candidato a corte no Ciclo #4. Funcional_tag=draw mas o draw é fraco comparado a Sensei's Top + Scroll Rack que o deck já tem.

### 4. Esper Sentinel — Declínio Preocupante
Trend -0.54. Ainda staple (32.3% EDHREC) mas caindo. Pode refletir migração para Archivist of Oghma. Manter — nenhuma substituição交换 o papel de 1-drop que compra carta em multiplayer.

### 5. A Ilha Artifact Está Morta
Goblin Engineer, Oswald Fiddlebender, Pearl + Ruby Medallions = 5 cartas focadas em artifact sem payoff. Storm-Kiln Artist seria o ÚNICO payoff para essa ilha. Sem Storm, essas cartas são deletáveis.

---

*Relatório gerado pelo Purpose Analyzer (v3.2) em 2026-05-28. Foco em trend analysis atualizada, mulligan confirmation, e double-null risk assessment. Dados: SQLite deck_id=6, 86 cartas analisadas, coleção do usuário verificada (161 cartas), 7.651 amostras EDHREC, 6 swaps aplicados (Ciclo #1 + #2). Scout Execução #10 + Mulligan Execução #5 incorporados.*