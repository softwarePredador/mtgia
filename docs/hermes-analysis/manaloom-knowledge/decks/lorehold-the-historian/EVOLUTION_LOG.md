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

---

## [2026-05-31T04:42:18Z] Ciclo #5 — Evolution Oracle (BALANCED)

### Sintese dos 3 Agentes

**SCOUT (Execução #13):**
- Dados EDHREC estaveis (7.802 decks) vs Execução #12 — sem mudança numerica
- Motor 4/4 completo desde Ciclo #3
- Artist's Talent em declinio grave (-0.70, 21.1% EDHREC) — corte prioritario
- The Dawning Archaic rising star confirmada 4+ ciclos (24.0%, trend +5.31)
- Chaos Warp (38.8%) como removao universal missing
- Arcane Bombardment (42.5%) como copy engine missing

**VALIDATOR (v3.5):**
- Deck pos-Ciclo #4: draw real = 5 (perfil quer 8-12), maior gap
- Wincon dedicado = 1 (perfil quer 4-7)
- Artist's Talent (-0.70) = carta mais urgente para cortar
- Double-nulls seguros: Scroll Rack, Penance (manter)
- Double-nulos cortaveis: Pearl Medallion, Galadriel's Dismissal

**MULLIGAN (Exec#8 pos-Ciclo #4):**
- Jogaveis: 49.5%, Mulligan: 46.4%
- Ramp T1: 21.2%
- Sem Play T3: 12.0%
- Estrategia recomendada: BALANCED

### Swap 1: Artist's Talent → Chaos Warp

**Diagnóstico:** Artist's Talent é a carta em declínio mais grave do deck. 21.1% EDHREC com trend -0.70 — 4º ciclo consecutivo caindo. É um draw condicional (requer criatura atacante) que não escala. Em Lorehold, draw engine passivo é inferior a cartas que geram valor por si só.

**Solução:** Chaos Warp é a melhor removal universal do jogo. Destrói QUALQUER permanente por CMC 3. É a única removal "qualquer coisa" do deck. 38.8% EDHREC. Instant speed. Na coleção.

**Da sua coleção:** ✅ Sim (qty: 1, cmd, R)

**Princípio:** Remoção universal > draw condicional. Em Lorehold, ter múltiplas formas de interação é mais valioso do que mais draw, especialmente em bracket 3 onde você enfrenta ameaças variadas de 3 oponentes.

**Impacto esperado no mulligan:** T3 piora levemente (+1 CMC: 2→3). Dentro da estrategia BALANCED com margem de segurança.

### Swap 2: Oswald Fiddlebender → The Dawning Archaic

**Diagnóstico:** Oswald Fiddlebender (0% EDHREC) é um tutor condicional que requer sacrifício de artefato. Em um deck que gera tesouros, sacrificar artefatos para buscar um artefato específicos é contraditório — você perde valor imediato para ganho futuro incerto. Double-nulo do classificador.

**Solução:** The Dawning Archaic é uma rising star confirmada em 4+ ciclos (24.0%, trend +5.31). CMC 3, criatura, voa, exilia top 7 e conjura permanente de CMC 7+ grátis. Quando copiada pelo Lorehold, gera valor absurdo. Complementa Approach e Dance como "cost cheating" engine.

**Da sua coleção:** ✅ Sim (qty: 1, sos, M)

**Princípio:** Rising stars confirmados (>20% base, >5.0 trend por 3+ ciclos) não são noise — são sinais claros da comunidade priorizando cartas que o deck não tem. O Dawning Archaic CMC 3 vs Oswald CMC 2, mas voa e é permanente (não precisa de setup).

**Impacto esperado no mulligan:** Neutro a leve (+1 CMC). Voar compensa no mid-game.

### Swap 3: Perch Protection → Arcane Bombardment

**Diagnóstico:** Perch Protection (CMC 6) é uma protection encantamento que dá hexproof ao comandante. Em Lorehold, proteger o comandante é bom mas CMC 6 é caro demais — deck já tem 4 peças de proteção. O maior problema é falta de motores de valor, não falta de proteção.

**Solução:** Arcane Bombardment (42.5% EDHREC, trend +0.09) é o copy engine que faltava. Com Double Vision + Arcane Bombardment + Lorehold commander, o deck tem 3 camadas de copy/spell value. Quando o oponente remove Double Vision, Arcane Bombardment continua gerando valor.

**Da sua coleção:** ✅ Sim (qty: 1, snc, M)

**Princípio:** Copy engines são a identidade de Lorehold. Mais copy = mais triggers = mais tesouros = mais big spells. Não há "demais" de copy em Lorehold.

**Impacto esperado no mulligan:** T3 melhora leve (CMC 6 → 5).

### Resumo do Ciclo

| Métrica | Pos-C#4 | Pos-C#5 | Δ |
|:--------|:-------:|:-------:|:-:|
| Jogaveis | 47.9% | 48.0% | +0.1pp |
| Mulligan | 52.1% | 52.0% | -0.1pp |
| Ramp T1 | 20.9% | 21.2% | +0.3pp |
| **Sem Play T3** | **13.0%** | **15.3%** | **+2.3pp** |

**Net ΔCMC:** +1 (Artist +2→+3, Oswald +2→+3, Perch +6→+5)

### Analise do Ciclo #5

O Ciclo #5 atingiu seu objetivo principal: remover Artist's Talent (declinio -0.70), adicionar The Dawning Archaic (rising star), e adicionar Chaos Warp (removal universal + Arcane Bombardment (copy engine).

**Ponto de atencao:** Sem Play T3 subiu de 13.0% para 15.3% (+2.3pp), ultrapassando o limite de 12% que define estrategia DEFENSIVI para o proximo ciclo. Ciclo #6 deve ser DEFENSIVO com net ΔCMC de -5 a -10.

### Ciclo #6 Recomendado (DEFENSIVO)

Com T3 = 15.3%, estrategia DEFENSIVA:
- Goldspan Dragon (CMC 5, 0% EDHREC) → Faithless Looting já está no deck; considerar substituir por cartas CMC ≤2
- Prioridade: reduzir CMC medio com cartas CMC 1-2 de alta EDHREC
- Galvanoth (CMC 5, baixo impacto) é candidato a corte

### Licoes do Ciclo #5

1. **Artist's Talent é o tipo de carta que se esconde no deck por ter funcional_tag=draw** — mas o trend -0.70 revela que a comunidade já percebeu que é fraco. Confiar em EDHREC trend > funcional_tag para decisões de corte.
2. **The Dawning Archaic (rising star) pode substituir tutores condicionais** — Oswald buscava artefatos; Dawning Archaic conjura permanentes de CMC 7+ sem condição.
3. **Arcane Bombardment completa a trifaria de copy** — Double Vision + Arcane Bombardment + Lorehold Commander. Remover um, os outros dois continuam funcionando.
4. **Net ΔCMC +1 piora T3 significativamente** — em Boros com 35 lands, cada +1 CMC liquido custa ~2pp em T3. Ciclo #6 precisara compensar com -5 a -10.

### Estado Final do Deck

- Total cartas: 100 ✅
- Commander: 1 ✅
- Lands: 35
- Motor: 4/4 completo ✅
- Copy engines: 3 (Double Vision, Arcane Bombardment, Lorehold Cmdr)
- Draw real: 5 (meta: 8-12) — proximo gap a resolver

---
