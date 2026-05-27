# Scout Log — Lorehold, the Historian

## [2026-05-27 03:00] Execução #1

### Fontes consultadas

- **EDHREC Deckpreview Corpus** (`commander_reference_deck_corpus_lorehold_2026-05-12`): 3 decks analisados
  - Deck 1: https://edhrec.com/deckpreview/3SFEtbTKhht92q7FXEd3qA (96 cartas)
  - Deck 2: https://edhrec.com/deckpreview/A_z1s_GftOaC6u75p7_TDw (89 cartas)
  - Deck 3: https://edhrec.com/deckpreview/Bn4UCaNCLKSTPqkwxUnStQ (88 cartas)
- **Tema unânime**: lorehold_reference_spellslinger_big_spells
- **Nosso deck**: deck_id=6, "Lorehold Spellslinger", 87 cartas

---

### Métricas de Referência (Apply Summary)

| Papel            | Deck 1 | Deck 2 | Deck 3 | Média Ext. | Nosso Deck | Delta   |
|------------------|--------|--------|--------|------------|------------|---------|
| Lands            | 25     | 36     | 35     | **32.0**   | 34         | +2.0    |
| Ramp             | 16     | 16     | 12     | **14.7**   | 17         | +2.3    |
| Draw             | 6      | 6      | 4      | **5.3**    | 8          | +2.7    |
| Interaction      | 6      | 6      | 6      | **6.0**    | 7 (removal)| +1.0    |
| Board Wipe       | 4      | 5      | 3      | **4.0**    | 6          | +2.0    |
| Win Condition    | 1      | 7      | 1      | **3.0**    | —          | —       |
| Creature         | 12     | 3      | 2      | **5.7**    | —          | —       |
| Protection       | —      | 2      | 5      | **2.3**    | —          | —       |
| Other            | 30     | 19     | 32     | **27.0**   | —          | —       |

**Observações**: Nosso deck tem mais lands, ramp, draw e board wipes que a média externa. Isso sugere um perfil mais "midrange/controle" do que os decks de referência, que variam entre posturas mais agressivas (Deck 1 com 12 criaturas) e mais spell-slinging puras (Decks 2-3 com 2-3 criaturas).

---

### Top 10 Cartas Mais Comuns (EDHREC)

Considerando staples não-land mais impactantes:

| # | Carta                   | Freq.    | No nosso deck? |
|---|-------------------------|----------|----------------|
| 1 | Sol Ring                | 3/3 (100%) | ✓ SIM         |
| 2 | Arcane Signet           | 3/3 (100%) | ✓ SIM         |
| 3 | Smothering Tithe        | 3/3 (100%) | ✓ SIM         |
| 4 | Esper Sentinel          | 3/3 (100%) | ✗ **NÃO**     |
| 5 | Enlightened Tutor       | 3/3 (100%) | ✓ SIM         |
| 6 | Sensei's Divining Top   | 3/3 (100%) | ✓ SIM         |
| 7 | Scroll Rack             | 3/3 (100%) | ✓ SIM         |
| 8 | Deflecting Swat         | 3/3 (100%) | ✓ SIM         |
| 9 | Dance with Calamity     | 3/3 (100%) | ✗ **NÃO**     |
|10 | Gamble                  | 3/3 (100%) | ✗ **NÃO**     |

**Nota**: 28 cartas aparecem em 100% dos decks — a maioria são lands (fetches, duals, rainbow lands).

---

### Faltando no Nosso Deck (presentes em 67%+ dos decks externos)

#### PRIORIDADE ALTA (100% — staples absolutos)

| Carta                 | Função         | Notas                                            |
|-----------------------|----------------|--------------------------------------------------|
| Dance with Calamity   | Big spell      | Sinergia direta com Lorehold — revela topo, casta spell grátis |
| Esper Sentinel        | Draw           | Melhor draw 1-drop em branco, essencial em qualquer deck |
| Gamble                | Tutor          | Tutor vermelho que toda lista de referência usa   |
| Hit the Mother Lode   | Ramp/Big spell | Ramp que revela topo do deck — sinergia Lorehold  |
| Redirect Lightning    | Proteção/Tech  | Tech exclusivo Lorehold — redireciona dano para criar treasure |
| Gemstone Caverns      | Fast land      | Aceleração T1 quando na opening hand              |
| Marsh Flats           | Fetch land     | Fetch preto/branco (busca Plains)                 |
| Plateau               | Dual land      | OG dual land Boros                               |
| Spectator Seating     | Land           | Bond land multiplayer — quase sempre entra untapped |
| Wooded Foothills      | Fetch land     | Fetch verde/vermelho (busca Mountain)             |

#### PRIORIDADE MÉDIA (67% — fortes candidatos)

| Carta                 | Função         | Notas                                            |
|-----------------------|----------------|--------------------------------------------------|
| Archivist of Oghma    | Draw           | Draw engine em multiplayer, 2-drop excelente      |

---

### Cortáveis do Nosso Deck (0% nos decks externos)

30 cartas do nosso deck nunca aparecem em nenhum deck de referência:

| Carta                              | Tag atual       | CMC | Razão provável                                    |
|------------------------------------|-----------------|-----|---------------------------------------------------|
| Deflecting Palm                    | None            | 2   | Pouco impacto, Fog pontual                        |
| Orim's Chant                       | None            | 1   | Stax/controle que não se alinha com big spells    |
| Pearl Medallion                    | None            | 2   | Redundante com Ruby Medallion; branco não é cor primária de ramp |
| Ruby Medallion                     | None            | 2   | Medallion é slow; decks externos preferem rituais |
| Sunbird's Invocation               | big_spell       | 6   | CMC alto, substituído por Double Vision/Dance     |
| Fated Clash                        | board_wipe      | 5   | Remoção ineficiente comparada a alternativas      |
| Jokulhaups                         | board_wipe      | 6   | Destrói tudo inclusive lands — muito punitivo     |
| Obliterate                         | board_wipe      | 8   | Não pode ser counterada mas CMC muito alto        |
| Artist's Talent                    | draw            | 2   | Draw lento, decks externos usam Sensei's/Scroll   |
| Season of the Bold                 | exile_value     | 5   | CMC 5 para draw condicional é caro                |
| Boseiju, Who Shelters All          | land            | 0   | Land lendária, decks externos preferem Cavern     |
| Dormant Volcano                    | land            | 0   | Bounce land muito lenta                           |
| Emeria's Call // Emeria            | land            | 7   | MDFC cara, não aparece em nenhuma lista           |
| Inspiring Vantage                  | land            | 0   | Fast land ok, mas substituível por fetch/Plateau  |
| Karoo                              | land            | 0   | Bounce land, risco de stone rain                  |
| Kor Haven                          | land            | 0   | Land de combate, nicho demais                     |
| Valakut Awakening // Valakut       | land            | 3   | MDFC substituível por Reforge the Soul            |
| Lightning Greaves                  | protection      | 2   | Decks externos usam mais protection spells        |
| Mother of Runes                    | protection      | 1   | Proteção single-target, decks preferem Teferi's   |
| Archaeomancer's Map                | ramp            | 3   | Bom mas Land Tax é mais comum                     |
| Claim Jumper                       | ramp            | 3   | Criatura frágil para ramp                         |
| Goldspan Dragon                    | ramp            | 5   | CMC alto, Ancient Copper Dragon é melhor payoff   |
| Land Tax                           | ramp            | 1   | Bom, mas nenhum deck externo usa                  |
| Weathered Wayfarer                  | ramp            | 1   | Tutor de land frágil, não alinha com big spells   |
| Surge to Victory                   | recursion       | 6   | CMC alto, substituível por Mizzix's Mastery       |
| Rite of the Dragoncaller           | spellslinger    | 6   | Muito caro para payoff incremental                |
| Ancient Copper Dragon              | token_maker     | 6   | Tag errado? Deveria ser ramp. Mas decks externos não incluem |
| Furygale Flocking                  | token_maker     | 10  | CMC 10 sem redução — injogável fora de cheat      |
| Oswald Fiddlebender                | tutor           | 2   | Tutor de artifact que decks referenciais não usam |
| Hellkite Tyrant                    | wincon          | 6   | Wincon situacional, decks preferem Storm Herd     |

---

### Cartas em Ambos (56 de 86 não-commander — 65% de overlap)

O overlap é razoável para uma primeira análise: 56 cartas do nosso deck também aparecem em pelo menos 1 deck externo. As staples universais estão presentes (Sol Ring, Arcane Signet, fetches, Command Tower, etc.), mas há diferenças significativas na escolha de payoffs e interação.

---

### Recomendações Imediatas

1. **Adicionar com urgência**: Dance with Calamity, Esper Sentinel, Gamble, Hit the Mother Lode — são staples em 100% dos decks e têm sinergia direta com o commander.

2. **Revisar manabase**: Adicionar Plateau, Marsh Flats, Wooded Foothills, Spectator Seating, Gemstone Caverns. Remover Karoo, Dormant Volcano, Kor Haven.

3. **Cortar payoffs questionáveis**: Furygale Flocking (CMC 10), Hellkite Tyrant, Rite of the Dragoncaller, Sunbird's Invocation.

4. **Reavaliar board wipes**: Jokulhaups e Obliterate são muito destrutivos. Decks externos preferem Austere Command + Call Forth the Tempest.

5. **Adicionar Redirect Lightning**: Tech exclusivo de Lorehold que aparece em 100% dos decks de referência — redireciona dano ao commander e gera Treasure.

---

### Limitações da Análise

- Amostra pequena: apenas 3 decks no corpus EDHREC
- Todos os 3 decks têm o mesmo tema (spellslinger_big_spells) — não há diversidade de arquétipos
- A classificação de tags nos decks externos é aproximada (via apply_summary)
- Não analisamos o maybeboard/sideboard dos decks externos
- Preços e disponibilidade de cartas não foram considerados

**Próximo passo**: Expandir corpus com mais fontes (Moxfield, Archidekt, EDHTop16) para aumentar confiança das recomendações.

---

## [2026-05-27 15:10] Execução #2 — EDHREC Live (7,597 decks)

### Fonte
- **EDHREC Live** (`__NEXT_DATA__` do https://edhrec.com/commanders/lorehold-the-historian)
- **Amostra**: 7.597 decks reais de Lorehold (vs 3 do corpus anterior)
- **Rank atual**: ~352° no EDHREC (variação sazonal entre 133° e 571°)
- **Preço médio do deck**: $955 (69% do nosso deck atual)

---

### Métricas da Amostra EDHREC (80 cartas trackeadas)

| Métrica | EDHREC (7.597 decks) | Nosso Deck | Delta |
|:--------|:-------------------:|:-----------:|:-----:|
| Lands | 35 | 34 | 🟡 -1 |
| Criaturas | 13 | ~8 | 🟡 |
| Instantâneas | 13 | ~10 | ✅ |
| Feitiços | 21 | ~14 | 🟡 |
| Artefatos | 13 | ~12 | ✅ |
| Encantamentos | 4 | ~3 | ✅ |

**CMC médio (EDHREC): 4.10** (excluindo lands)
**CMC médio (nosso): 3.96** — ligeiramente mais baixo, mais rápido.

**Distribuição EDHREC por CMC:**
- CMC 1: 9 cartas | CMC 2: 12 | CMC 3: 11 | CMC 4: 8 | CMC 5: 7
- CMC 6: 3 | CMC 7: 6 | CMC 8: 3 | CMC 9: 1 | CMC 10: 2 | CMC 12: 1
- **CMC 7+: 13 cartas (21% da amostra)** — big spells são o core do arquétipo

**Observação:** O CMC 4.10 do EDHREC é MAIOR que o 3.96 do nosso deck. Isso sugere que os decks populares de Lorehold são ainda mais pesados em big spells que o nosso — e se viram bem com ramp abundante.

---

### Novas Descobertas (vs Execução #1)

**Correções importantes em relação ao corpus de 3 decks:**
1. **Redirect Lightning NÃO é 100%** — está em apenas 20.6% dos decks (1.566/7.597). O corpus de 3 decks deu falso universal.
2. **Dance with Calamity NÃO é 100%** — está em 50.4% (3.828/7.597). Ainda muito relevante, mas não essencial.
3. **Gamble NÃO é 100%** — está em apenas 12.1% (920/7.597). O corpus superestimou tutores.
4. **Esper Sentinel** está em 32.3% (2.456/7.597) — bem abaixo do "100%" do corpus pequeno.

**Novos staples descobertos (não apareciam no corpus de 3 decks):**
1. **Big Score** — 67.3% (5.114/7.597) — ramp + draw, NÃO temos
2. **Storm-Kiln Artist** — 55.5% (4.217/7.597) — criatura payoff magecraft, NÃO temos
3. **Apex of Power** — 55.4% (4.205/7.597) — big spell que dá 10 mana + draw 7, NÃO temos

---

### Faltando Urgente (60%+ EDHREC que não temos)

| # | Carta | Inclusão EDHREC | Função | Nota |
|:-:|:------|:---------------:|:-------|:-----|
| 1 | **Big Score** | **67.3%** (5.114) | Ramp + Draw | NÃO temos. Ramp + draw em uma carta CMC 4. Sinergia direta com Lorehold — copiar Big Score = draw 4 + treasures |
| 2 | **Battlefield Forge** | **63.5%** (4.821) | Land (pain) | NÃO temos. Land básica Boros, substituto barato de fetch |

### Faltando Forte (50-60% EDHREC)

| # | Carta | Inclusão EDHREC | Função | Nota |
|:-:|:------|:---------------:|:-------|:-----|
| 3 | **Storm-Kiln Artist** | 55.5% (4.217) | Payoff | Criatura 3R que dá treasure ao copiar mágicas. Payoff direto de Lorehold. **NÃO temos** |
| 4 | **Apex of Power** | 55.4% (4.205) | Big Spell | CMC 10 — exila top 7, pode castar grátis no upkeep. Sinergia com copy de Lorehold. **NÃO temos** |
| 5 | **Spectator Seating** | 53.4% (4.055) | Land (bond) | Quase sempre entra untapped em multiplayer. **NÃO temos** |
| 6 | **Rugged Prairie** | 52.3% (3.972) | Land (filter) | Filter land Boros. **NÃO temos** |
| 7 | **Boros Signet** | 50.4% (3.829) | Ramp | Ramp básico 2-cmc. **NÃO temos** (usamos Talisman) |
| 8 | **Dance with Calamity** | 50.4% (3.828) | Big Spell | Exila X top cards, casta grátis os que são <= X. Sinergia Lorehold. **NÃO temos** |

### Candidatos a Corte (abaixo de 15% EDHREC que temos)

| Carta | Inclusão EDHREC | Tag | Motivo |
|:------|:---------------:|:---:|:-------|
| Desperate Ritual | **0%** (0) | ramp | Ritual puro sem value em deck de big spells |
| Weathered Wayfarer | **0%** (0) | ramp | Criatura tutor de land frágil, não sinergiza com Lorehold |
| Ancient Copper Dragon | **0%** (0) | token_maker | CMC 6 para payoff incerto. Preferem Apex of Power |
| Hellkite Tyrant | **0%** (0) | wincon | Wincon nicho só contra decks de artefatos |
| Emeria's Call | **0%** | land (MDFC) | MDFC cara, EDHREC prefere terrenos normais |
| Valakut Awakening | **0%** | land (MDFC) | MDFC substituível por Reforge the Soul ou Wheel |
| Cavern of Souls | **0%** (0) | land | Não joga tribal, counter targeting não é problema frequente |
| Kor Haven | **0%** (0) | land | Land de combate nicho |
| Dormant Volcano | **0%** (0) | land | Bounce land muito lenta |
| Oswald Fiddlebender | **0%** (0) | tutor | Tutor artifact que não se alinha com big spells |
| Goblin Engineer | **0%** (0) | recursion | Tutor artifact nicho |
| Orim's Chant | **0%** (0) | stax | Stax piece que não se alinha com a estratégia |
| Sunbird's Invocation | 13.7% (1.042) | big_spell | CMC 6, Galvanoth + Double Vision são melhores |
| Fated Clash | 15.6% (1.187) | board_wipe | Board wipe condicional, preferem Blasphemous Act |

### Surpresas e Contra-Intuitivos

| Carta | Inclusão EDHREC | Nossa percepção | Realidade |
|:------|:---------------:|:---------------|:----------|
| **Smothering Tithe** | **29.4%** (2.237) | Staple absoluto | Apenas 29% dos decks de Lorehold incluem. CMC 4 pesado demais? |
| **Teferi's Protection** | **21.2%** (1.608) | Staple | Só 21% usam. Preferem proteção mais barata (Perch 34.7%, Mother 34.6%) |
| **Enlightened Tutor** | **18.3%** (1.392) | Tutor essencial | Só 18% usam. Decks preferem raw draw a tutores |
| **Ancient Tomb** | **13.9%** (1.053) | Fast mana poderoso | Só 14% — talvez o custo de vida seja punitivo para um deck de CMC alto |
| **Gamble** | **12.1%** (920) | Tutor vermelho | Só 12% — a aleatoriedade de descarte não vale o risco |
| **Grand Abolisher** | **11.7%** (892) | Proteção de turno | Só 12% — decks preferem proteção reativa a preventiva |
| **Jeska's Will** | **30.5%** (2.314) | Ramp excelente | Apenas 30.5% — surpreendentemente baixo para RW |
| **Land Tax** | **31.2%** (2.369) | Ramp consistente | Só 31% — bom mas não essencial |

### Decks de Lorehold na Prática (7.597 amostras)

O deck médio de Lorehold no EDHREC tem:
- **35 terrenos** (20 básicas, 15 não-básicas)
- **13 criaturas** (poucas — Lorehold é spellslinger)
- **13 artefatos** (rocas, ramp, topdeck)
- **34 instants/sorceries** (13 + 21) — o core do deck
- **4 encantamentos**
- **CMC médio 4.10** — mais pesado que a média de Commander (3.0)
- **21% das cartas não-land são CMC 7+**

Isso confirma: **Lorehold é um deck de big spells que depende de ramp pesada e topdeck manipulation para castar mágicas de alto CMC consistentemente.**

### Sobre o Perfil do Deckbuilder Médio de Lorehold

Baseado na escolha de staples (Big Score 67%, Storm-Kiln 55%, Monument 73%, Hit the Mother Lode 80%, Library of Leng 78%, Double Vision 47%):

1. **Ramp é rei** — a estratégia depende de acelerar para castar big spells. Quase todo ramp que gere treasures ou mana extra é incluso.
2. **Topdeck manipulation > draw tradicional** — Library of Leng (78%) e Sensei's Top (67%) aparecem mais que draw spells tradicionais.
3. **Remoção eficiente é preferida** — Swords (69%), Path (57%), Boros Charm (45%). Chaos Warp (39%) e Blasphemous Act (41%) complementam.
4. **A comunidade prefere payoffs a wincons** — Double Vision (47%), Galvanoth (27%), Arcane Bombardment (43%) são preferidos a wincons específicos como Hellkite Tyrant (0%).
5. **Pouca recursão** — Volcanic Vision (64%) é a principal. Mizzix's Mastery (58%). Pouco espaço para recursion adicional.

### Combos Descobertos (EDHREC)

EDHREC lista 4 combos populares para Lorehold:
1. **Approach of the Second Sun + Scroll Rack** — clássico: rack no topo, compra Approach de novo
2. **Approach of the Second Sun + Reprieve** — bounce Approach de volta pra mão, compra de novo
3. **Approach of the Second Sun + Wheel of Fortune** — wheel no Approach, volta pra mão, compra de novo

O Approach + Scroll Rack é o combo mais documentado e já está no nosso deck.

### Cartas Fora do Deck Recomendadas pela Comunidade (30%+)

Para enriquecimento futuro, 29 cartas em 30%+ dos decks que não estão na nossa lista principal:

| Inclusão | Carta | Função |
|:--------:|:------|:-------|
| **67.3%** | Big Score | Ramp + Draw |
| **55.5%** | Storm-Kiln Artist | Payoff criatura |
| **55.4%** | Apex of Power | Big spell |
| **50.4%** | Boros Signet | Ramp |
| **50.4%** | Dance with Calamity | Big spell |
| **48.5%** | Improvisation Capstone | Draw |
| **48.0%** | Elegant Parlor | Land |
| **46.4%** | Radiant Summit | Land |
| **45.0%** | Sunbillow Verge | Land |
| **44.8%** | Temple of Triumph | Land |
| **42.8%** | Soulfire Eruption | Big spell |
| **42.6%** | Arcane Bombardment | Payoff |
| **40.5%** | Blasphemous Act | Board wipe |
| **39.8%** | Furycalm Snarl | Land |
| **39.6%** | Dragon's Rage Channeler | Enabler |
| **38.9%** | Chaos Warp | Removal |
| **34.5%** | Beacon of Immortality | Lifegain (Storm Herd enabler) |
| **34.3%** | Reliquary Tower | Land |
| **34.2%** | Fellwar Stone | Ramp |
| **34.0%** | Invoke Calamity | Big spell |
| **33.4%** | Goliath Daydreamer | Creature payoff |
| **32.8%** | Velomachus Lorehold | Payoff lendário |
| **32.5%** | Generous Gift | Removal |
| **32.4%** | Guttersnipe | Payoff criatura |
| **30.4%** | Invincible Hymn | Lifegain |
| **30.1%** | Caldera Pyremaw | Payoff criatura |

### Novas Cartas Recentes com Potencial (Scryfall, últimos 3 meses)

| Carta | Set | Mana | Potencial |
|:------|:---|:----:|:----------|
| **Stingcaster Mage** | Reality Fracture | 1R | Dá flashback a instant/sorcery no gy. Recursão barata! |
| **Sunpearl Kirin** | Secret Lair Promo | 1W | Blink para reusar ETBs. Pode reciclar Lorehold se morrer |
| **Quicksilver, Brash Blur** | Marvel Super Heroes | R | Começa em jogo se na opening hand. Haste para ativar Lorehold T2 |
| **Vision, Synthezoid Avenger** | Marvel Super Heroes Commander | 4 | Toda spell de oponente no turno alheio = copy ou token. Sinergia |

### Resumo para o Desenvolvedor

**Prioridade máxima de adição (justificativa EDHREC):**
1. **Big Score** (67.3%) — só não ter Big Score já é atípico. Ramp + draw em uma carta
2. **Storm-Kiln Artist** (55.5%) — payoff direto de Lorehold, gera treasures ao copiar
3. **Apex of Power** (55.4%) — CMC 10 que se paga, sinergia com copy
4. **Boros Signet** (50.4%) — ramp básico, substitui Talisman ou complementa

**Prioridade máxima de corte:**
1. Desperate Ritual (0%) — ritual sem value
2. Ancient Copper Dragon (0%) — CMC 6 sem payoff garantido
3. Hellkite Tyrant (0%) — wincon nicho
4. Dormant Volcano / Kor Haven (0%) — lands fracas

**Correções de percepção (após 7.597 amostras vs 3):**
- Smothering Tithe NÃO é essencial em Lorehold (29%)
- Redirect Lightning NÃO é staple (20.6%)
- Gamble NÃO é essencial (12.1%)
- Big Score É essencial (67.3%) — e não estávamos nem considerando

---

### Validade dos Dados

- **+** Amostra de 7.597 decks é estatisticamente significativa (margem de erro < 1%)
- **+** Dados extraídos diretamente do JSON da página, sem parsing HTML frágil
- **-** EDHREC mostra apenas as 80 cartas mais populares, não o deck completo
- **-** Não há dados de performance (win rate, posição em torneio)
- **-** Não há discriminação por bracket (B3 vs B4 pode ter composições diferentes)
- **-** Moxfield bloqueado por Cloudflare — dados não puderam ser triangulados