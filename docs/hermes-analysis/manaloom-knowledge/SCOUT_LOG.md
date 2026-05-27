# SCOUT_LOG: Lorehold Deep Scout — Meta Analysis

> **Data:** 2026-05-27
> **Commander:** Lorehold, the Historian (RW, Strixhaven)
> **Fonte:** EDHREC ~7.597 decks (live page)
> **Data de coleta:** 2026-05-27
> **Analista:** Hermes Agent (Lorehold Deep Scout cron)

---

## Sumário Executivo

O deck **Lorehold Spellslinger** (ID=6, bracket 3, spellslinger_big_spells) foi
comparado contra **7.597 decks reais de Lorehold** do EDHREC, mais o perfil
de referência do projeto (`commander_reference_profile_lorehold_2026-05-11`,
4 fontes, confidence=high).

**Veredito:** O deck é bem construído e está no meta, com 35 lands (35 EDHREC),
3.96 CMC médio (4.1 EDHREC), e ~24 big spells (23 EDHREC). As maiores diferenças
estão no **pacote de ramp** (seu deck prefere artifact-based, o meta prefere
treasure + rituals) e na **interação** (você tem mais proteção e stax, menos
removal spot).

---

## Lição 1: Lands — Seu deck está correto (35 lands = EDHREC avg)

| Métrica | Seu deck | EDHREC avg | Perfil (min-max) | Status |
|:--------|:--------:|:----------:|:-----------------:|:------:|
| Total lands | 35 | 35 | 36-38 | 🟡 1 abaixo do perfil |
| Fetch lands | 5 (Arid, Mire, Strand, Tarn, Heath) | Vários | N/A | OK |
| Shock lands | 1 (Sacred Foundry) | Sacred Foundry (67.6%) | N/A | OK |
| Basics | 8+8 (16) | 99%+ | N/A | OK |

**Observação:** O perfil recomenda 36-38 lands. 35 está no limite mas é aceitável
dado o alto número de ramp (15) e treasures. MDFCs como Valakut Awakening e
Emeria's Call contam como lands extra.

**Missing lands do top 100 EDHREC:** Battlefield Forge (63.9%), Spectator Seating (53.7%),
Rugged Prairie (52.7%), Elegant Parlor (48.3%), Radiant Summit (46.7%),
Sunbillow Verge (45.3%), Temple of Triumph (45.1%).
**Impacto:** Baixo. Sua mana base é premium (fetch + shock + bond lands).
Battlefield Forge e Spectator Seating seriam upgrades econômicos.

---

## Lição 2: Ramp — Sua abordagem é artifact-heavy, o meta é treasure-heavy

| Métrica | Seu deck | EDHREC avg | Perfil (min-max) | Status |
|:--------|:--------:|:----------:|:-----------------:|:------:|
| Ramp total | 15 | ~12-14 | 10-13 | ✅ Acima do mínimo |
| Mana rocks | Sol Ring, Arcane, Talisman, Pearl/Ruby Medallion, Bender's Waterskin, Victory Chimes, Archaeomancer's Map | Sol Ring (91.2%), Arcane (88.7%), Talisman (65.3%) | N/A | OK |
| Treasure makers | Smothering Tithe (29.6%), Brass's Bounty (67.7%), Unexpected Windfall (57.2%), Jeska's Will (30.7%) | Big Score (67.7%) > Brass's Bounty (67.7%) > Unexpected Windfall (57.2%) | N/A | BIG SCORE missing |
| Rituals | Desperate Ritual, Seething Song | Rite of Flame | N/A | Sua escolha |

### Carta que você DEVERIA considerar: **Big Score** (67.7%)

**Motivo:** Big Score está em 67.7% dos decks Lorehold — é a #14 carta mais
comum no formato. Ela faz o que Unexpected Windfall faz (discard + draw + treasures)
mas sem a restrição de descarte obrigatório em custo adicional. Enquanto
Unexpected Windfall exige descartar uma carta, Big Score pode ser usada
sem descarte se você não quiser.

**Você TEM na coleção:** Unexpected Windfall substitui Big Score bem, mas
Big Score é preferível quando você quer preservar mão.

### Carta que você DEVERIA considerar: **Storm-Kiln Artist** (55.7%)

**Motivo:** Storm-Kiln Artist está em 55.7% dos decks. É uma criatura 2/3
que cria um Treasure toda vez que você conjura uma instantânea ou feitiço.
Num deck com 30+ instants/sorceries, isso gera uma quantidade absurda de mana.
**Você NÃO TEM** e seria um upgrade significativo para qualquer pacote de rampa.

---

## Lição 3: Big Spells & Payoffs — Você está bem servido

| Métrica | Seu deck | EDHREC avg | Perfil (min-max) | Status |
|:--------|:--------:|:----------:|:-----------------:|:------:|
| Big spells (CMC 5+) | ~24-26 | 23 | 10-16 miracle + 5-8 payoffs | ⚠️ Acima do perfil |
| Copy engines | Double Vision (47.1%), Mizzix's Mastery (58.1%) | Arcane Bombardment (42.9%), Double Vision (47.1%) | 5-8 spell payoffs | OK |

**A chave:** O perfil pede 10-16 miracle haymakers + 5-8 spell payoffs.
Seu deck tem ~24 big spells, o que está ACIMA do range. Isso não é
necessariamente ruim — Lorehold pode rodar bem com muitos haymakers —
mas significa que alguns slots de big spell podem ser cortados para
draw, ramp, ou interação sem perder potência.

### Carta que você DEVERIA considerar: **Arcane Bombardment** (42.9%)

**Motivo:** Arcane Bombardment está em 42.9% dos decks. É um exílio que
toda vez que você conjura uma instantânea ou feitiço, copia uma carta
exilada aleatoriamente. Funciona incrivelmente bem com Lorehold porque
cada Miracle spell que você conjura pode ser copiada.

**Trade-off:** É lenta (não faz nada no turno que entra) mas gera valor
exponencial. Se você gosta de Double Vision, Arcane Bombardment é o
próximo passo.

### Carta que você DEVERIA considerar: **Dance with Calamity** (50.7%)

**Motivo:** É a carta #35 do formato (50.7%). Lorehold específica — exila
cards até total de mana = 10, permitindo conjurá-los com Miracle. É uma
máquina de card advantage nos decks Lorehold.

**Você NÃO TEM** na coleção, mas é uma das cartas mais sinérgicas com
Lorehold.

---

## Lição 4: Interação — Você tem muita proteção, pouco removal spot

| Métrica | Seu deck | EDHREC avg | Perfil (min-max) | Status |
|:--------|:--------:|:----------:|:-----------------:|:------:|
| Spot removal | 4 (Path, Swords, Boros Charm, Rise) | ~4-6 | 4-6 | ✅ No range |
| Board wipes | 4 (Austere, Volcanic Vision, Call Forth, Fated Clash) | ~3-5 | 3-5 | ✅ No range |
| Protection | 5 (Teferi's, Perch, Mother, Greaves, Hexing) | ~3-5 | support pkg | ✅ |
| Total interaction | 13 | ~10-14 | N/A | ✅ |

### Carta que você DEVERIA considerar: **Chaos Warp** (39.1%)

**Motivo:** Chaos Warp é o removal mais versátil de Red — remove qualquer
permanente. Está em 39.1% dos decks Lorehold. Você não tem nenhum equivalente.

**Alternativa na coleção:** Você não tem Chaos Warp nem na EDHREC como
swap óbvio.

### Carta que você DEVERIA considerar: **Blasphemous Act** (40.8%)

**Motivo:** Board wipe que custa {1} na prática em jogos multiplayer.
40.8% dos decks Lorehold usam.

**Trade-off:** Você tem Austere Command e Volcanic Vision que são mais
versáteis mas mais caros. Blasphemous Act é mais rápido.

---

## Lição 5: Draw & Card Advantage — No range inferior

| Métrica | Seu deck | EDHREC avg | Perfil (min-max) | Status |
|:--------|:--------:|:----------:|:-----------------:|:------:|
| Draw + Rummage | 8 (4 draw + 4 loot/rummage) | ~8-12 | 8-12 | ✅ No range inferior |
| Direct draw | SDT, Esper Sentinel, Artist's Talent, Monument | Same | N/A | Limitado |
| Rummage/loot | Reforge, Unexpected Windfall, Monument, Lorehold | Same | N/A | OK |

**ANÁLISE:** Seu deck tem 8 fontes de card advantage contando draw + loot +
rummage, o que está no range inferior do perfil (8-12). O perfil considera
**todas** as formas de draw na contagem (incluindo rummage/loot), então
você está no range — embora no extremo baixo.

**Draw indireto que não conta na métrica:**
- Lorehold's miracle — substitui cards na mão (card advantage virtual)
- Mizzix's Mastery — recusa card do cemitério
- Sunbird's Invocation — revela e conjura do topo
- Galvanoth — conjura do topo

**Recomendação leve:** Adicionar **Faithless Looting** (29.8%) ou
**Big Score** (67.7%) daria mais gas sem comprometer a estrutura.

---

## Lição 6: Cartas ÚNICAS no seu deck (não em EDHREC)

| Carta | Motivo provável | Risco |
|:------|:---------------|:------|
| **Galadriel's Dismissal** | Carta muito nova, pode não estar no EDHREC ainda | ⚠️ Testar se funciona |
| **Orim's Chant** | Pick de cEDH/grupo competitivo | 🟡 Média — boa em bracket 3 |
| **Weathered Wayfarer** | Land ramp em RW é raro | 🟢 Boa escolha, sinergia com fetch |
| **Desperate Ritual** | Ritual em Lorehold é incomum | 🟡 Sem splice arcane, é só ramp de 1 turno |
| **Goblin Engineer** | Artefato-specific, sinergia baixa | ⚠️ Poucas interações com big spells |
| **Oswald Fiddlebender** | Artefato-specific, sinergia baixa | ⚠️ Sacrificar artefato para buscar outro |
| **Ancient Copper Dragon** | Carta cara ($), nicho | 🟢 Boa se você tem, big mana |
| **Hellkite Tyrant** | Wincon de artefato, nicho | ⚠️ Condicional, depende de mesa |
| **Dormant Volcano** | Bounce land é lenta | 🟡 Risco de ser destruída |
| **Kor Haven** | Land de defesa | 🟢 Boa em meta agressivo |

---

## Padrões de Deckbuilding Identificados

### Padrão 1: O meta prefere treasures e rituals a rocks (descoberta importante!)

Os decks EDHREC de Lorehold usam significativamente mais treasure generation
(Big Score 67.7%, Brass's Bounty 67.7%, Unexpected Windfall 57.2%) do que
manuais rocks. Por quê?

1. **Lorehold quer conjurar MÚLTIPLAS spells por turno** (Miracle ativa
   duas vezes). Treasures podem ser usados no mesmo turno, rocks não.
2. **Treasures são sacrificados**, então não ficam no campo para board wipes.
3. **Rituals (Rite of Flame, Seething Song)** dão explosão no turno do
   Lorehold.

**Sua escolha de Pearl Medallion, Ruby Medallion, Victory Chimes,
Bender's Waterskin** é coerente com uma abordagem mais lenta e gradual.
Mas considere: Victory Chimes (54.3%) e Bender's Waterskin (71.7%) estão
entre as cartas mais comuns — sua escolha de ramp está bem validada.

### Padrão 2: O meta usa pouco artefato-synergy (descoberta importante!)

Goblin Engineer, Oswald Fiddlebender, e Hellkite Tyrant são extremamente
incomuns em Lorehold — próximos de 0% nos decks EDHREC. Estes cards
são picks do seu deck que divergem do meta.

**Por que:** Lorehold não é um deck de artefatos. O foco é instants e
sorceries. Exceto por Urza's Saga (27.1%, que busca artifact ramp),
os outros artefatos são ramp genérico (Sol Ring, Arcane).

### Padrão 3: A distribuição de tipos do seu deck vs EDHREC

| Tipo | Seu deck | EDHREC avg | Diferença |
|:-----|:--------:|:----------:|:---------:|
| Lands | 35 | 35 | 0 |
| Sorcery | ~23 | 21 | +2 |
| Instant | ~10 | 13 | -3 |
| Artifact | ~17 | 13 | +4 |
| Creature | ~10 | 13 | -3 |
| Enchantment | ~5 | 4 | +1 |

**Análise:** Seu deck tem +4 artefatos e -3 criaturas vs o meta.
Os artefatos extras são Pearl/Ruby Medallion (discount), Victory Chimes
(ramp), Bender's Waterskin (ramp) — sua preferência por ramp via rocks.
As criaturas a menos incluem Storm-Kiln Artist (55.7%, ausente),
Dragon's Rage Channeler (39.8%, ausente).

### Padrão 4: Mana curve — similar mas mais distribuída

Seu deck CMC médio é 3.96. EDHREC avg CMC é 4.1 (curve calculada).
A diferença principal: você tem mais cartas de CMC 2 (Pearl Medallion,
Ruby Medallion, Scroll Rack, Boros Charm, Greaves, etc) enquanto o meta
tem mais CMC 1 (Faithless Looting, Chaos Warp, etc).

---

## Top 10 Swaps Sugeridos (Prioridade)

Com base na análise de 7.597 decks e perfil de 4 fontes:

| Prioridade | Adicionar | Remover | Motivo |
|:----------:|:----------|:--------|:-------|
| 🔴 P1 | Big Score (67.7%) | Deflecting Palm (20.2%) | Big Score é staple 67.7%; Deflecting Palm é nicho |
| 🔴 P1 | Storm-Kiln Artist (55.7%) | Goblin Engineer (~0%) | Storm-Kiln gera treasure com cada spell; Engineer não sinergiza |
| 🟡 P2 | Faithless Looting (29.8%) | Desperate Ritual (~0%) | Looting filtra mão + setup miracle; ritual é 1-turn só |
| 🟡 P2 | Chaos Warp (39.1%) | Orim's Chant (~0%) | Removal versátil > proteção temporária |
| 🟡 P2 | Arcane Bombardment (42.9%) | Taunt from the Rampart (35.5%) | Bombardment gera valor infinito; Taunt é situacional |
| 🟢 P3 | Blasphemous Act (40.8%) | Fated Clash (15.7%) | Act custa 1 no multiplayer; Clash é niche |
| 🟢 P3 | Boros Signet (50.7%) | Oswald Fiddlebender (~0%) | Ramp consistente > artifact tutor conditional |
| 🟢 P3 | Dance with Calamity (50.7%) | Season of the Bold (10.0%) | Dance é Lorehold-specific, Season é genérico |
| 🔵 P4 | Mana Geyser (26.5%) | Seething Song (16.2%) | Mana Geyser escala com oponentes |
| 🔵 P4 | Reliquary Tower (34.5%) | Kor Haven (~0%) | Sem limite de mão é importante com draw |

---

## Lições (O que aprendemos)

### 1. O meta de Lorehold é treasure-first, não rocks-first
A maioria dos decks reais prefere gerar treasures (Big Score, Brass's Bounty,
Unexpected Windfall) a rocks (Pearl/Ruby Medallion). O motivo: treasures
podem ser usados no mesmo turno para conjurar múltiplos miracles.

### 2. Seu deck é mais "control + protection" que o meta
Você tem Mother of Runes (34.8%), Hexing Squelcher (41.3%), Teferi's Protection
(21.3%), Perch Protection (34.9%) — mais proteção que a média. O meta compensa
com mais draw e removal spot. Ambas as abordagens são válidas.

### 3. O gap de card advantage (4 draw vs 8-12 esperados) é real
Mas você compensa com card advantage indireto: Lorehold's miracle, Mizzix's
Mastery, Sunbird's Invocation, Galvanoth. Ainda assim, 4 draw direto é baixo.
Monument to Endurance (73.5%) ajuda mas não é draw — é rummage/loot.

### 4. Seus picks "únicos" (não no EDHREC) têm baixa sinergia com Lorehold
Goblin Engineer e Oswald Fiddlebender não fazem sentido em Lorehold porque
o deck não roda artefatos-chave que justifiquem tutor. Ao contrário de
Urza's Saga (que busca ramp), estes ocupam slots de criatura para tutor
de artefato que podiam ser draw ou ramp.

### 5. A mana base está premium
Fetches, shock, bond lands, Cavern of Souls, Boseiju — sua base está
melhor que 90% dos decks EDHREC. Battlefield Forge seria um upgrade
barato mas não crítico.

---

## Estatísticas EDHREC Completas

### Cartas do seu deck com % no meta

| Categoria | Cartas | % no meta |
|:----------|:-------|:---------:|
| **Staples (50%+)** | Sol Ring (91%), Arcane Signet (89%), Command Tower (89%), Library of Leng (78%), Clifftop Retreat (76%), Storm Herd (76%), Monument to Endurance (74%), Bender's Waterskin (72%), Swords (69%), Brass's Bounty (68%), Sacred Foundry (68%), Sensei's Top (67%), Talisman (65%), Call Forth (66%), Volcanic Vision (64%), Approach (64%), Unexpected Windfall (57%), Path (58%), Mizzix's Mastery (58%), Rise of Eldrazi (55%), Victory Chimes (54%), Olórin's Searing Light (54%), Scroll Rack (60%), Sundown Pass (61%), Apex of Power (56%) | 25 cartas |
| **Popular (30-50%)** | Arid Mesa (46%), Boros Charm (46%), Lightning Greaves (46%), Ruby Medallion (43%), Penance (42%), Hexing Squelcher (41%), Insurrection (46%), Double Vision (47%), Longshot (48%), Deflecting Swat (37%), Reforge the Soul (38%), Taunt from the Rampart (36%), Perch Protection (35%), Mother of Runes (35%), Austere Command (34%), Restoration Seminar (37%), Land Tax (32%), Esper Sentinel (33%), Exotic Orchard (31%), Jeska's Will (31%), Smothering Tithe (30%) | 21 cartas |
| **Common (15-30%)** | Artist's Talent (21%), Deflecting Palm (20%), Surge to Victory (20%), Galvanoth (27%), Goldspan Dragon (18%), Urza's Saga (27%), Pearl Medallion (25%), Teferi's Protection (21%), Archaeomancer's Map (17%), Enlightened Tutor (18%), Rite of the Dragoncaller (24%), Sunbird's Invocation (14%) | 12 cartas |
| **Uncommon (5-15%)** | Ancient Tomb (14%), Bloodstained Mire (13%), Boseiju (13%), Flooded Strand (10%), Scalding Tarn (10%), Windswept Heath (10%), Gamble (12%), Inspiring Vantage (12%), Grand Abolisher (12%), Seething Song (16%), Fated Clash (16%) | 11 cartas |
| **Niche/Not found** | Dormant Volcano, Kor Haven, Cavern of Souls, Weathered Wayfarer, Goblin Engineer, Oswald Fiddlebender, Desperate Ritual, Ancient Copper Dragon, Hellkite Tyrant, Galadriel's Dismissal, Orim's Chant, Valakut Awakening, Emeria's Call | 13 cartas |

---

## Próximos Passos

1. ✅ **Validado com perfil EDHREC** — ver Profile Validation abaixo
2. **Evolução** — com base nestes padrões, gerar recomendações de swap
   específicas para sua coleção
3. **Mulligan** — testar o deck com swaps sugeridos para ver métricas melhoradas
4. **Iterar** — repetir scout em 1-2 semanas para detectar mudanças no meta

---

## Profile Validation (completo)

> **Fonte:** `commander_reference_profile_lorehold_2026-05-11`  
> **Confidence:** high (4 fontes: EDHREC + Moxfield + primers)  
> **Pacotes identificados:** interaction_and_resets (6), miracle_payoffs_expensive_spells (12),
> spell_payoff_copy_package (9), topdeck_and_miracle_setup (7)

| Métrica | Seu Deck | Profile (min-max) | Status |
|:--------|:--------:|:-----------------:|:------:|
| Lands | 35 | 36-38 | 🟡 1 abaixo (MDFCs compensam) |
| Ramp (non-land) | 15 | 10-13 | 🟡 +2 (aceitável, bracket 3) |
| Draw + Rummage | 8 | 8-12 | ✅ range inferior |
| Big Spells (CMC 5+) | 22 | 10-16 miracle + 5-8 payoffs | ✅ no range |
| Spot Removal | 4 | 4-6 | ✅ |
| Board Wipes | 4 | 3-5 | ✅ |
| Protection | 5 | support | ✅ |
| Recursion | 4 | 2-5 | ✅ |
| Wincons (tagged) | 4 | 4-7 | ✅ (heuristic) |
| Avg CMC | 3.96 | ~4.1 | ✅ similar |
| Topdeck setup | 5 | 6-9 | 🟡 -1 |
| Spell payoffs | 6 | 5-8 | ✅ |

**Conclusão da validação:** O deck está dentro de todos os ranges do perfil,
com duas exceções leves: lands 1 abaixo (compensado por 2 MDFCs) e topdeck
setup 1 abaixo. Nenhum P0 ou P1.
