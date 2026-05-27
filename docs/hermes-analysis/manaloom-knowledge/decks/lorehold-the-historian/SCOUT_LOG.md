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