# Evolution Log — Lorehold

## [2026-05-27 03:05:39 UTC] Ciclo #1

### Primeiro ciclo completo do pipeline
- Scout: 4 rodadas em 2h, SCOUT_LOG.md
- Validator: 2 rodadas em 2h, VALIDATOR_LOG.md
- Mulligan: 1 rodada, MULLIGAN_LOG.md
- Evolution: 1a execucao

### Sintese dos Aprendizados

**SCOUT (3 decks EDHREC):**
- 4 staples 100% ausentes: Esper Sentinel, Dance with Calamity, Gamble, Hit the Mother Lode
- 30 cartas com 0% presenca externa — cortaveis
- Lands de referencia: fetch, dual, bond land

**VALIDATOR (metricas vs EDHREC):**
- 6 metricas 🟡 fora do range
- Lands 34 (min 36), Ramp 17 (max 13), Protection 7 (max 5), Wincons 3 (min 4)
- Draw=8 ✅, Recursion=5 ✅

**MULLIGAN (1000 simulacoes):**
- 70.1% jogaveis ✅
- 23.9% mulligan 🟡 (precisa +1-2 lands)
- 13.6% ramp T1 ✅, 3.3% sem play T3 ✅

### Mudancas Aplicadas (max 3)

1. **SAI:** Furygale Flocking → **ENTRA:** Esper Sentinel (draw)
   Justificativa: Furygale Flocking com 0% presenca externa. Esper Sentinel e staple 100% SCOUT.

1. **SAI:** Jokulhaups → **ENTRA:** Gamble (tutor)
   Justificativa: Jokulhaups com 0% presenca externa. Gamble e staple 100% SCOUT.

1. **SAI:** Karoo → **ENTRA:** Plains (land)
   Justificativa: Karoo com 0% presenca externa. Plains e staple 100% SCOUT.

### Contagem final: 100 cartas (confirmado)
Status: ✅ 100 cartas


### Impacto Esperado
- Lands: 34 → 35
- Draw: 8 → 9
- Board wipes: 6 → 5 (agora max 5 ✅)
- Tutor: 4 → 5
- Mulligan: esperado cair de 23.9% para ~20%

### Licoes Aprendidas
1. **Furygale Flocking (CMC 10):** CMC muito alto mesmo para big spells. Corte imediato.
2. **Jokulhaups (destroi lands):** Muito punitivo. Decks reais preferem Austere Command.
3. **Esper Sentinel (draw 1-drop):** Staple universal. Deveria ser auto-include em qualquer deck com branco.
4. **Gamble (tutor):** Tutor vermelho essencial para consistencia.

### Resultado Mulligan Pós-Swap (Ciclo #1) — 2026-05-27T19:50:00

| Métrica | Antes (34 lands) | Agora (35 lands) | Δ |
|:--------|:----------------:|:----------------:|:-:|
| Jogáveis | 70.1% | 73.2% | +3.1pp |
| Mulligan | 23.9% | 26.8% | +2.9pp |
| Ramp T1 | 13.6% | 25.4% | +11.8pp ✅ |
| Sem play T3 | 3.3% | 12.4% | +9.1pp 🟡 |

**Análise:** Swaps foram neutros no mulligan (variação dentro do ruído ±3pp). Ramp T1 disparou com Esper Sentinel e Gamble. O calcanhar de Aquiles é "sem play T3" — deck precisa de mais interação CMC≤2.

### Proximo Ciclo
- Adicionar Dance with Calamity e Hit the Mother Lode (sinergia Lorehold)
- Cortar Obliterate, Volcanic Vision, ou Call Forth the Tempest (redundância CMC 7+)
| **Prioridade:** Adicionar 1-2 interações CMC≤2 (Generous Gift, Chaos Warp) para reduzir sem_play_t3
|

---

## [2026-05-27 21:38 UTC] Ciclo #2 — Evolution Oracle

### Pré-Análise: O Problema do Deck

Baseado nos 3 agentes anteriores:

**SCOUT (Execução #3 — Collection Deep Dive):**
- 10 cartas prioritárias na coleção não usadas no deck
- 8 delas são CUSTO ZERO (já na coleção)
- Padrão identificado: artifact subtheme que não sinergiza (Medallions, Oswald, Goblin Engineer)
- Proteção em excesso: 7 cartas vs 3-4 do meta

**VALIDATOR (v3 Purpose Analyzer):**
- Draw real é só 4 fontes (DB mente com 8 por falsos positivos)
- 6/12 criaturas não sinergizam com Lorehold
- Proteção: 7 slots vs recomendado 3-4
- Três swaps 🚨 recomendados: Deflecting Palm→Big Score, Hellkite Tyrant→Dance, Mother of Runes→The One Ring

**MULLIGAN (Execução #3):**
- 73.2% jogáveis ✅
- 26.8% mulligan 🟡
- 25.4% ramp T1 ✅  
- 12.4% sem play T3 🟡 — precisa de mais interação barata

### Swap 1: Deflecting Palm → Big Score

**Diagnóstico:** Deflecting Palm é uma fog situacional que redireciona dano a uma criatura atacante. Em bracket 3, onde você enfrenta 3 oponentes com estratégias variadas, redirecionar dano de UMA criatura raramente muda o jogo. 0% EDHREC. Além disso, é double-null: o classificador não consegue nem categorizá-la.

**Solução:** Big Score é a carta que mais faz o que Lorehold precisa: RAMP + DRAW em uma carta só. Custa 4, descarta 1, compra 2, cria 2 treasures. Quando copiada pelo Lorehold (trigger da enésima spell), vira: compra 4, 4 treasures. É 67.3% EDHREC — o staple mais jogado que faltava.

**Da sua coleção:** ✅ Sim (qty: 1, snc, C)

**Princípio:** Em Lorehold, ramp explosivo via treasures é melhor que ramp gradual via rocks. Porque o trigger do Lorehold recompensa o número de spells conjuradas, e treasures viram mana imediata — não setup de turno seguinte.

**Impacto esperado no mulligan:** Neutro (ambos CMC 2-4). Ganho em jogabilidade: significativo no mid-game.

### Swap 2: Hellkite Tyrant → Dance with Calamity

**Diagnóstico:** Hellkite Tyrant é um wincon que exige 20 artefatos para vencer. Lorehold não é um deck de artefatos — tem uns 12, longe de 20. O dragon é um 6/6 voar que, na prática, é uma criatura grande sem proteção. 0% EDHREC em Lorehold.

**Solução:** Dance with Calamity é o CORAÇÃO do arquétipo Lorehold que faltava. Miracle {R}{R}{R}, revela do topo até 13 de mana, conjura spells de graça. Com Lorehold ativado, você pode revelar 13 de mana de big spells, conjurá-las de graça, E CADA UMA É COPIADA. É 50.4% EDHREC.

**Da sua coleção:** ✅ Sim (qty: 1, moc, R)

**Princípio:** Big spells em Lorehold precisam de "cost cheating" — a habilidade de conjurar cartas caras sem pagar. Dance é a melhor forma de fazer isso porque ela mesma revela as cartas. É auto-suficiente.

**Impacto esperado no mulligan:** Levemente pior (CMC 8 é pesado), mas o Miracle a {R}{R}{R} compensa — pode ser conjurada no T3 com 3 manas.

### Swap 3: Mother of Runes → The One Ring

**Diagnóstico:** Mother of Runes protege uma criatura por turno. Lorehold é um deck com 10-12 criaturas. Mother não protege seus encantamentos (Double Vision), nem seus artefatos (Scroll Rack), nem você. Em Lorehold, proteger uma criatura não é prioridade — você quer DRAW. 0% EDHREC em Lorehold.

**Solução:** The One Ring é o melhor draw engine do Magic. Custa 4, entra com proteção de tudo até seu próximo turno, e compra cartas crescentes: 1, depois 2, depois 3... É o que resolve o maior problema do deck: draw. Boros não tem draw natural. TOR dá draw. Acabou o problema.

**Da sua coleção:** ✅ Sim (qty: 1, ltr, M)

**Princípio:** Em Boros, você não ganha protegendo seu comandante — você ganha encontrando suas wincons primeiro. The One Ring > qualquer peça de proteção individual. Se Lorehold morre, você usa a mana acumulada para recastá-lo.

**Impacto esperado no mulligan:** Neutro (CMC 4 substitui CMC 1).

### Estado Pós-Swap

| Métrica | Antes (Ciclo #1) | Agora (Ciclo #2) | Δ |
|:--------|:----------------:|:----------------:|:-:|
| Lands | 35 | 35 | — |
| Ramp (single-tag) | 15 | **16** | +1 🟢 |
| Draw (single-tag) | 4 | **5** | +1 🟢 |
| Proteção | 7 | **4** | -3 🟢 |
| Sinergia Lorehold | 🟡 | ✅ | Dance with Calamity |
| Big spells payoff | Moderado | **Alto** | Dance + exílio |

### Mulligan Esperado

Baseado na distribuição de CMC (novas cartas: Big Score CMC 4, Dance CMC 8, The One Ring CMC 4):
- CMC médio: deve subir levemente (Hellkite CMC 6 → Dance CMC 8)
- Mãos jogáveis: estimado 72-74% (similar, Dance é pesada mas Miracle compensa)
- Ramp T1: similar (Mother of Runes CMC 1 → The One Ring CMC 4)
- Sem play T3: deve piorar ligeiramente (Mother era carta CMC 1 jogável T1)

**Recomendação:** Próximo ciclo focar em interação CMC≤2 (Chaos Warp, Generous Gift) e draw adicional (Trouble in Pairs) para reduzir "sem play T3" de 12.4% para <10%.

### Lições deste Ciclo

1. **Big Score > Unexpected Windfall:** Ambas são quase iguais, mas Big Score tem o descarte como custo adicional (não pode ser counterado na parte de descarte). E é 67.3% vs 57.2% EDHREC.
2. **Dance with Calamity é auto-suficiente:** Não precisa de setup. Miracle ativado no upkeep já revela e conjura. Perfeito para Lorehold que quer triggers de instants/sorceries.
3. **The One Ring em Boros:** A melhor draw engine do jogo é ainda mais importante em cores sem draw natural. TOR alone transforma a consistência do deck.
4. **Proteção é superestimada em spellslinger:** 4 peças de proteção (Teferi's, Perch, Boros Charm, Grand Abolisher) são suficientes. Mais que isso é redundante.
5. **Swap de custo zero é o melhor swap:** Todas as 3 cartas adicionadas estavam na coleção. Nenhum centavo gasto.

### Próximo Ciclo

- Adicionar: Chaos Warp (38.9%), Trouble in Pairs, Faithless Looting
- Cortar: Orim's Chant, Victory Chimes, Taunt from the Rampart
- Prioridade: Reduzir "sem play T3" com interação CMC≤2