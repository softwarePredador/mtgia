# Auditoria Completa — Regras MTG em Todas as Crons do Pipeline Lorehold

**Data:** 2026-06-01  
**Auditor:** Hermes Agent (MTG Rules Auditor v3)  
**Versão das Regras de Referência:** MTG Comprehensive Rules (CR 103, 117, 405, 702.94, 704, 903)  
**Escopo:** Todas as 5 crons do pipeline Lorehold (Scout, Validator, Mulligan, Battle, Evolution Oracle)

---

## Sumário Executivo

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| **Scout** (f20ac299992b) | **8.0/10** | ALTA | 0 |
| **Validator** (712579b15767) | **8.5/10** | ALTA | 0 |
| **Mulligan** (08468451a06a) | **7.5/10** | MÉDIA-ALTA | 0 |
| **Battle** (94f8590b1beb) | **6.5/10** | MÉDIA | 1 (Priority ordem) |
| **Evolution Oracle** (a50bef4c2a59) | **7.5/10** | MÉDIA-ALTA | 0 |
| **PIPELINE COMBINADA** | **7.6/10** | **MÉDIA-ALTA** | **1 CRÍTICO, 5 ALTOS, 9 MÉDIOS, 4 BAIXOS** |

### Verdicto Geral

A pipeline Lorehold tem confiabilidade **MÉDIA-ALTA** em relação às regras oficiais de MTG. Nenhum gap encontrado é do tipo "quebra o jogo" (recomendar carta ilegal, simular regra errada de forma irreversível). O gap mais sério está na implementação do sistema de prioridade do Battle Analyst v8, que não segue estritamente o CR 117.3 (ordem de prioridade começa pelo jogador ativo, mas o código agrupa múltiplas rodadas de prioridade em uma só). Os demais gaps são imprecisões de simulação ou omissões de edge cases que não afetam a validade das recomendações de swap.

---

## 1. Scout — Auditoria Detalhada

**Prompt:** Buscar cartas na `user_collection`, ranquear por sinergia (Score A+B+C), filtrar por color identity.  
**Última Execução:** #24 (2026-05-31T23:30) — MATURIDADE PERSISTENTE confirmada, 6 ângulos inéditos encontrados.

### O que faz CERTO ✅

1. **Color Identity (CR 903.4):** O prompt inclui regra explícita de filtrar `WHERE color_identity IN ('R','W','RW','C')` e marcar cartas fora como "ILEGAL". Correto — um deck Lorehold (Boros, RW) só pode usar cartas com identidade de cor R, W, RW, ou incolor.
2. **Singleton (CR 903.5b):** O Scout não recomenda cartas já no deck (verifica via `deck_cards`), respeitando a regra de singleton.
3. **Formato Commander (100 cards, 1 commander):** Respeitado — as consultas usam `deck_id=6` (deck fixo de 100 cartas).
4. **Sinergia sobre EDHREC %:** O sistema A/B/C prioriza interação mecânica com o deck existente, não apenas popularidade. Isso evita o viés de "jogar o que todo mundo joga" e captura cartas niche como Ashling, Flame Dancer (0% EDHREC mas sinergia CAST+COPY com 6 copy engines).
5. **EDHREC inclusion % calculado corretamente:** Divide `inclusion` (raw count) por `num_decks_avg`, não trata como percentual direto.
6. **Sem recomendações de banlist:** Nenhuma carta banida em Commander apareceu nas recomendações (verificação implícita via `user_collection` — o jogador não possui cartas banidas).

### O que faz ERRADO / IMPRECISO ⚠️

1. **[MÉDIO] Score weights podem supervalorizar sinergias niche:** Seething Song (score 10) e Ashling (score 9) receberam scores mais altos que staples estabelecidos. O sistema A+B+C com pesos lineares pode dar scores inflados a cartas que interagem com muitos eixos mas têm baixo impacto real.
2. **[MÉDIO] Sem verificação explícita de banlist:** O filtro é implícito (só recomenda cartas da `user_collection`), mas não há uma query explícita contra a Commander banlist. Se o jogador possuir uma carta banida (improvável mas possível via erro de importação), o Scout a recomendaria.
3. **[BAIXO] Custo de Oportunidade (B) subjetivo:** "-1: Aumenta CMC médio" e "-1: Não é instant/sorcery" são heurísticas úteis mas não quantificam precisamente o impacto no T3.
4. **[BAIXO] Score >= 8 como threshold é arbitrário:** Não há calibração estatística para o corte 8/15. Funciona bem na prática (o deck atingiu maturidade com esse threshold), mas é uma heurística, não uma derivação das regras.

### Recomendações

1. Adicionar query explícita de banlist: cross-reference com lista oficial do Commander RC.
2. Calibrar pesos A/B/C com dados de win rate do Battle Analyst (fechar o loop).
3. Na seção "Sinergias Detectadas", incluir verificação de que as interações descritas são legalmente possíveis (ex: "Storm Herd + Boros Charm double strike" → verificar que Boros Charm pode targetar tokens).

---

## 2. Validator (Purpose Analyzer) — Auditoria Detalhada

**Prompt:** Analisar deck completo, classificar importância estratégica 1-5, mapear sinergias em 7 eixos.  
**Última Execução:** v3.13 (2026-05-31T23:37) — SYNERGY_MAP 7 eixos (média 7.6/10), Nível 1 VAZIO.

### O que faz CERTO ✅

1. **SYNERGY_MAP cobre dimensões críticas do Commander:** Os 7 eixos (A-G) capturam aspectos fundamentais: Token+Pump, Wipe+Proteção, Recursion, Mana Explosiva, Combo Pieces, Stack Interaction, Graveyard Resilience. Esta é uma avaliação holística rara em ferramentas de deckbuilding.
2. **Classificação Estratégica (1-5):** Distingue corretamente entre cartas insubstituíveis (Nível 5: Approach, Lorehold, Mizzix's) e cartas situacionais (Nível 2). Isso é essencial para evitar que o Evolution Oracle corte engines core.
3. **Double-Null Detection:** Identifica cartas sem classificação funcional (`functional_tag IS NULL AND zero card_tags`) e as cruza com EDHREC. Scroll Rack e Penance (ambas double-null) são marcadas como "NUNCA cortar" — correto, são core engines.
4. **"Nível 1 = VAZIO" como sinal de maturidade:** Um deck sem fillers (todas as cartas ≥ Nível 2) é um deck otimizado. O Validator reconhece isso.
5. **Stack Interaction (eixo F) reconhece limitação de cor:** "0 counterspells — aceito como limitação Boros". Correto — Branco e Vermelho não têm counterspells tradicionais (com raras exceções como Mana Tithe, Lapse of Certainty).
6. **Graveyard Resilience (eixo G):** Identifica que o deck depende do cemitério (Mizzix's Mastery, Arcane Bombardment) e tem apenas 3 respostas a Rest in Peace. Análise sofisticada.

### O que faz ERRADO / IMPRECISO ⚠️

1. **[MÉDIO] Nenhuma verificação de banlist:** Como o Scout, a análise não cruza o deck contra a Commander banlist. Se uma carta banida entrasse no deck (via erro de importação), o Validator não detectaria.
2. **[MÉDIO] CMC evaluation não considera MDFC/DFCs:** Cartas como Valakut Awakening // Valakut Stoneforge têm CMC efetivo diferente dependendo de qual face é usada. O Validator trata como CMC fixo.
3. **[BAIXO] Stack Interaction (F=6/10) subestima a irrelevância de counterspells em Boros:** Em RW, a ausência de counterspells não é um "gap" — é uma característica da identidade de cor. O score 6/10 poderia ser 8/10 considerando que o deck tem 4 camadas de proteção alternativa (Teferi's, Boros Charm, Deflecting Swat, Grand Abolisher).
4. **[BAIXO] Eixo "Card Advantage Efficiency" ausente:** Os 7 eixos cobrem bem sinergia, mas não medem eficiência de card advantage (quantas cartas por mana investida). Skullclamp (CMC 1, draw 2) vs Esper Sentinel (CMC 1, draw condicional) têm eficiências radicalmente diferentes.

### Recomendações

1. Adicionar verificação de banlist como passo preliminar (query contra lista oficial).
2. Incluir eixo H: "Card Advantage Efficiency" (draw por mana, draw por trigger, draw condicional vs incondicional).
3. Para cartas MDFC, documentar ambas as faces e seus papéis estratégicos separadamente.

---

## 3. Mulligan Analyst — Auditoria Detalhada

**Prompt:** Simular 1000 mãos, medir consistência (T3, ramp T1, jogáveis), London Mulligan com free first.  
**Última Execução:** #12 (2026-05-31T23:44) — T3=13.3% estável, deck sem mudanças pós-C#10.

### O que faz CERTO ✅

1. **London Mulligan — Free First CORRETO:** `bottom_count = max(0, mulligan_count - 1)`. Em Commander multiplayer, o primeiro mulligan é gratuito (0 cartas no fundo). O código está correto per CR 103.4c (multiplayer).
2. **Definição Rigorosa de "Jogável":** 2-4 lands AND (ramp ≥ 1 OR lands ≥ 3). Alinhado com a prática competitiva — 2 lands sem ramp é mulligan em decks de curva média.
3. **Ramp T1 = Sol Ring apenas:** Correto — em RW (Boros), só Sol Ring produz mana no turno 1. Land Tax e Weathered Wayfarer buscam terrenos para a MÃO, não produzem mana. Boros Signet e Arcane Signet custam 2.
4. **Sem Play T3 = sem spell com CMC ≤ min(lands, 3):** Definição precisa e correta.
5. **Seed fixo (42) e N=1000:** Reprodutibilidade científica.
6. **Detecção de "sem mudanças":** Se o Evolution Oracle não aplicou swaps desde a última execução, o Mulligan registra "estável" em vez de re-simular.

### O que faz ERRADO / IMPRECISO ⚠️

1. **[ALTO] Não simula tapped lands:** O deck contém terrenos que entram tapped (ex: Temple of Triumph, Boros Garrison). A simulação trata todos os terrenos como untapped no turno em que entram. Isso torna o T3 real PIOR que o simulado — uma mão com Temple of Triumph como única land T1 não pode conjurar Sol Ring. **Impacto:** T3 real provavelmente 1-3pp maior que o simulado.
2. **[ALTO] Não verifica requisitos de cor:** Uma mão com 3 Mountains e só spells brancos é "jogável" pela simulação mas injogável na prática. O deck Lorehold tem ~23 white pips e ~18 red pips em custos — o color screw é real. **Impacto:** "Jogáveis" simulado superestima a consistência real em 3-8pp.
3. **[MÉDIO] Mulligan decision只看lands数量:** `mulligan_decision()` decide keep/mulligan apenas por contagem de terrenos (2-5 lands = keep). Não considera qualidade da mão (tem ramp? tem draw? tem play T1/T2?). Um jogador humano faria mulligan de uma mão de 4 lands + 3 spells de CMC 6+, mas a simulação a mantém.
4. **[MÉDIO] Simulação avalia apenas mão inicial, não draws futuros:** "Sem Play T3" é calculado apenas com as 7 cartas iniciais, sem considerar as compras dos turnos 1, 2 e 3. Na prática, o jogador compra 3 cartas adicionais até o T3, reduzindo significativamente a chance de "sem play". **Impacto:** T3 real é MENOR que o simulado (as compras adicionais aumentam as opções). Este viés compensa parcialmente o viés oposto dos tapped lands.
5. **[BAIXO] Não considera London Mulligan parcial (bottom N cards):** Na simulação, cartas postas no fundo são aleatórias, não escolhidas. No jogo real, o jogador escolhe quais cartas vão para o fundo.

### Recomendações

1. **[CRÍTICO]** Adicionar simulação de tapped lands: marcar terrenos como `enters_tapped=True` para Temple of Triumph, Boros Garrison, etc., e não permitir uso de mana deles no turno em que entram.
2. **[ALTO]** Adicionar verificação de color requirements: contar pips coloridos nos custos de mana das spells na mão e verificar se as lands produzem as cores necessárias.
3. **[MÉDIO]** Simular draws dos turnos 1, 2, 3 para calcular "Sem Play T3" com mais precisão.
4. **[MÉDIO]** Aprimorar `mulligan_decision()` para considerar CMC médio da mão e presença de ramp/draw.
5. **[BAIXO]** Documentar que o T3 simulado é uma estimativa conservadora para tapped lands mas otimista para draws futuros, e que os dois vieses se compensam parcialmente.

---

## 4. Battle Analyst v8 — Auditoria Detalhada

**Prompt:** Rodar simulação de jogo 4-player com Priority/Stack/Miracle, medir win rate.  
**Última Execução:** v8 (2026-05-31T19:12) — WR=67.7%, todos os arquétipos ≥ 65%, Approach=89.9% das vitórias.

### O que faz CERTO ✅

1. **Commander Tax (+2 por recast):** `player.commander_tax += 2` após cada conjuração da command zone. Correto per CR 903.8.
2. **Commander Damage 21:** `commander_damage[target.name]` rastreado e mata com ≥21. Correto per CR 903.10a.
3. **Stack LIFO:** `stack.items.pop()` resolve o último item adicionado. Correto per CR 405.5.
4. **Approach of the Second Sun:** Primeiro cast = ganha 7 vida + vai 7º do topo. Segundo cast = vitória. Correto per as regras da carta.
5. **Double Strike com First Strike separado:** O código divide o dano em first strike (apenas criaturas com first/double strike) e dano normal (todas as atacantes). Correto per CR 702.4b e 702.7b.
6. **Indestructible per-creature:** Board wipes respeitam `c.get("indestructible")` individualmente. Correto per CR 702.12b.
7. **Lifelink:** `attacker.life = min(40, attacker.life + a_pwr)`. Correto per CR 702.15b (embora o cap em 40 seja questionável — lifelink pode exceder o life total inicial).
8. **State-Based Actions após resolução:** `check_sbas()` chamado após cada spell resolver. Correto per CR 704.3.
9. **Combat phase structure:** Declare attackers → declare blockers → first strike damage → regular damage. Correto per CR 506-510.
10. **Miracle (Lorehold):** Verifica se Lorehold está no battlefield, aplica custo de miracle {2} a instants/sorceries. Implementação simplificada mas funcional da mecânica (CR 702.94).
11. **Turn structure:** Untap → Upkeep → Draw → Main 1 → Combat → Main 2 → End → Cleanup (discard to 7). Estrutura correta per CR 500-514.
12. **The One Ring burden:** Draw adicional por turno. Correto.

### O que faz ERRADO / IMPRECISO ⚠️

1. **[CRÍTICO] Prioridade não segue CR 117.3 corretamente:** O código em `priority_round()` começa a iteração pelo active player, mas trata TODAS as respostas em uma única rodada: se o jogador A conjura Approach, o código verifica se ALGUM oponente quer counterar (em ordem), e se ninguém counterar, resolve IMEDIATAMENTE. O correto (CR 117.4) é: cada jogador recebe prioridade em ordem; se TODOS passarem em sequência, o topo da stack resolve. O código atual não permite que um jogador passe e depois responda após outro jogador agir. **Impacto:** Counterspells são menos eficazes do que deveriam ser (oponentes não podem "esperar para ver" se outro oponente vai counterar).

2. **[ALTO] Lifelink com cap em 40 de vida:** `attacker.life = min(40, attacker.life + a_pwr)`. Em Commander, o life total inicial é 40, mas lifelink pode levar o jogador acima de 40. O cap é incorreto per CR 119.3f (não há limite superior para life total).

3. **[ALTO] Atacantes não podem ser divididos entre oponentes:** Em `combat_phase_v8()`, TODOS os atacantes atacam UM ÚNICO oponente (`target`). Em Commander multiplayer (CR 802.1a), um jogador pode atacar múltiplos oponentes, dividindo suas criaturas como desejar. **Impacto:** A simulação subestima a flexibilidade ofensiva do deck Lorehold — ele não pode, por exemplo, atacar o jogador Combo com 2 criaturas e o jogador Control com 3.

4. **[ALTO] Miracle timing imperfeito:** O código verifica Miracle no DECK DO LOREHOLD, mas apenas para a ÚLTIMA carta comprada (`player.hand[-1]`). Se múltiplas cartas foram compradas (ex: The One Ring + draw normal), apenas a última é verificada. Além disso, o código não revela a carta (como exige CR 702.94a) — ele simplesmente a conjura.

5. **[MÉDIO] Counterspell decisions são probabilísticas, não estratégicas:** `rng.random() < 0.85` para ameaças score ≥ 70. Oponentes reais fariam decisões baseadas em: "essa spell me mata?", "tenho outra resposta?", "outro oponente pode counterar?". A abordagem probabilística é aceitável para simulação em larga escala, mas perde nuance estratégica.

6. **[MÉDIO] Phasing retorna no Untap, não no Upkeep:** `player.battlefield.extend(player.phased_out)` ocorre na fase de untap. O correto (CR 702.26b) é que permanentes phasadas retornam antes do untap step do controlador. A diferença é sutil mas relevante para triggers de "at the beginning of your upkeep".

7. **[MÉDIO] Bloqueadores não respeitam múltiplos bloqueios por atacante:** Em `combat_phase_v8()`, cada atacante é bloqueado por no máximo 1 bloqueador. Em MTG real (CR 509.1a), múltiplas criaturas podem bloquear um único atacante. O código também não implementa ordem de dano de combate (CR 509.3).

8. **[MÉDIO] Sem Trample:** Nenhuma criatura no deck simulado tem trample. Se uma carta futura com trample for adicionada, o simulador não a processará corretamente.

9. **[BAIXO] Sem "regeneration" ou "protection from [color]":** Shield counters, regeneration, e protection from colors não são implementados.

10. **[BAIXO] Sem verificação de "can't be countered":** Cartas como Boseiju, Who Shelters All ou Supreme Verdict (não no deck Lorehold, mas relevante para oponentes) não são consideradas.

11. **[BAIXO] Decks dos oponentes são simplificados:** Oponentes usam decks genéricos preenchidos com "Filler Creature". Apenas quando `learned_decks` está populado é que decks reais são usados. Com decks genéricos, a simulação é menos precisa.

### Recomendações

1. **[CRÍTICO]** Refatorar `priority_round()` para seguir CR 117.3-117.4 estritamente: cada jogador recebe prioridade em ordem de turno; o topo da stack só resolve quando TODOS passam em sequência sem agir.
2. **[ALTO]** Remover cap de 40 no lifelink (`player.life += a_pwr` sem `min()`).
3. **[ALTO]** Implementar ataque a múltiplos oponentes (dividir `attackers` entre `alive_defenders`).
4. **[MÉDIO]** Implementar Miracle com reveal step e verificar todas as cartas compradas no turno.
5. **[MÉDIO]** Adicionar suporte a múltiplos bloqueadores por atacante e trample.
6. **[MÉDIO]** Migrar phasing return para o upkeep step.

---

## 5. Evolution Oracle — Auditoria Detalhada

**Prompt:** Ler logs de todos os agentes, sintetizar, decidir swaps (0-3), aplicar no DB.  
**Última Execução:** Ciclo #15 (2026-05-31T23:53) — 0 SWAPS, 5º ciclo consecutivo, MATURIDADE ABSOLUTA.

### O que faz CERTO ✅

1. **Síntese multi-agente obrigatória:** O prompt exige leitura de TODOS os logs (SCOUT, VALIDATOR, MULLIGAN, BATTLE) antes de decidir. Isso cria um sistema de freios e contrapesos — um agente não pode unilateralmente forçar swaps.
2. **5 Perguntas Estratégicas obrigatórias:** Antes de propor swaps, o Oracle deve responder: (1) Como o deck ganha? (2) Como evita perder? (3) Qual o plano T1-T6? (4) O que o meta joga contra? (5) O plano sobrevive a interação? Isso força raciocínio estratégico, não apenas estatístico.
3. **Necessidade Estratégica (0-5) + Evidência de Dados (0-5):** Sistema de dois eixos que exige tanto justificativa de gameplay quanto suporte de dados. Threshold Total ≥ 6 com ambas ≥ 3.
4. **0 swaps é válido e documentado:** Quando nenhum candidato atinge o threshold, o Oracle registra "0 swaps" com a tabela de rejeição completa. Isso evita o viés de "sempre tem algo para melhorar".
5. **Singleton Verification pós-swap:** Query explícita para detectar cartas duplicadas (exceto basic lands). Correto per CR 903.5b.
6. **Matchup-aware swaps:** Se o BATTLE_LOG mostra fraqueza contra Control, o Oracle aumenta a prioridade de wincons alternativas e protege cartas anti-counterspell.
7. **Color identity respeitada:** Só recomenda cartas da coleção que já passaram pelo filtro de identidade de cor do Scout.
8. **Swap script atômico:** Aplica todos os swaps em uma transação SQLite com verificações de integridade (100 cartas, 1 commander, ≥34 lands).

### O que faz ERRADO / IMPRECISO ⚠️

1. **[ALTO] Não verifica restrições de bracket (Game Changer count):** O deck está no Bracket 3 (B3), que permite no máximo 3 Game Changers. O Oracle não conta GCs antes/depois dos swaps. Se um swap introduzisse um 4º GC, o deck ficaria ilegal para B3. Atualmente não é um problema (o deck tem ~3 GCs), mas o check deveria existir.
2. **[ALTO] Confia cegamente no MULLIGAN_LOG para T3 (histórico de erro):** O Pitfall #19 documenta que o Oracle já usou "T3=3.7%" (free mulligan rate) como base para estratégia AGGRESSIVE quando o T3 real era ~14%. O prompt atual instrui "NAO calcule — LEIA do log", o que é correto, mas o Oracle ainda pode interpretar mal os números.
3. **[MÉDIO] Não verifica se o swap introduz carta banida:** Como os outros agentes, não há cross-reference com a Commander banlist.
4. **[MÉDIO] Não recalcula "Sem Play T3" após swaps:** O Oracle aplica swaps mas delega ao Mulligan a verificação de impacto. Se o Mulligan não rodar antes do próximo ciclo, o Oracle do próximo ciclo toma decisões baseado em T3 desatualizado. O intervalo de 60min entre Oracle e Mulligan mitiga parcialmente.
5. **[BAIXO] "Necessidade Estratégica" é subjetiva:** O score de 0-5 depende do julgamento do LLM, não de uma fórmula determinística. Dois Oracles poderiam dar scores diferentes para o mesmo candidato.

### Recomendações

1. **[ALTO]** Adicionar contagem de Game Changers antes e depois dos swaps: `SELECT COUNT(*) FROM deck_cards WHERE deck_id=6 AND card_name IN (lista de GCs)`.
2. **[ALTO]** Cross-reference com Commander banlist oficial antes de aplicar qualquer swap.
3. **[MÉDIO]** Após aplicar swaps, rodar uma simulação rápida de T3 (N=100) para estimativa imediata, sem esperar o Mulligan Analyst.
4. **[BAIXO]** Documentar a subjetividade do "Necessidade Estratégica" e sugerir que dois ciclos consecutivos com 0 swaps de agentes diferentes confirmem maturidade (isso já acontece na prática).

---

## 6. Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (quebra o jogo ou distorce resultados fundamentais)

| # | Agente | Problema | Correção | Esforço |
|:-:|:-------|:---------|:---------|:-------:|
| C1 | Battle | Sistema de prioridade não segue CR 117.3 — jogadores não podem responder após outro jogador agir na mesma rodada | Refatorar `priority_round()` para passar prioridade sequencialmente; resolver stack só quando todos passarem em sequência | **Grande** (reestruturar ~80 linhas) |

### 🟠 ALTO (distorce resultados de forma significativa)

| # | Agente | Problema | Correção | Esforço |
|:-:|:-------|:---------|:---------|:-------:|
| A1 | Mulligan | Tapped lands não simulados — T3 real é pior que o reportado | Adicionar flag `enters_tapped` nos terrenos relevantes e bloquear uso de mana no turno de entrada | **Médio** (~30 linhas) |
| A2 | Mulligan | Color requirements não verificados — "jogável" ignora color screw | Verificar pips coloridos nos custos vs lands que produzem cada cor | **Médio** (~40 linhas) |
| A3 | Battle | Lifelink capped at 40 — incorreto per CR 119.3f | Remover `min(40, ...)` do lifelink | **Trivial** (1 linha) |
| A4 | Battle | Atacantes não podem ser divididos entre múltiplos oponentes | Refatorar `combat_phase_v8()` para permitir `attackers` → múltiplos `defenders` | **Grande** (~60 linhas) |
| A5 | Oracle | Sem verificação de Game Changer count para bracket legality | Query de contagem de GCs antes/depois dos swaps | **Pequeno** (~15 linhas) |

### 🟡 MÉDIO (imprecisão que afeta recomendações secundárias)

| # | Agente | Problema | Correção |
|:-:|:-------|:---------|:---------|
| M1 | Scout | Score weights podem supervalorizar sinergias niche | Calibrar com dados de win rate do Battle Analyst |
| M2 | Scout | Sem verificação explícita de banlist | Adicionar query contra Commander banlist |
| M3 | Validator | Sem verificação de banlist | Idem |
| M4 | Validator | Eixo "Card Advantage Efficiency" ausente | Adicionar eixo H |
| M5 | Mulligan | Mulligan decision só olha contagem de lands | Considerar CMC médio e presença de ramp/draw |
| M6 | Mulligan | Não simula draws dos turnos 1-3 para T3 | Comprar 1 carta por turno e reavaliar "sem play" |
| M7 | Battle | Counterspell decisions probabilísticas, não estratégicas | Melhorar heurística de decisão baseada em game state |
| M8 | Battle | Miracle timing imperfeito (só última carta comprada) | Verificar todas as cartas compradas no turno, adicionar reveal |
| M9 | Oracle | Confia no MULLIGAN_LOG sem verificação independente | Adicionar estimativa rápida de T3 pós-swap |

### 🔵 BAIXO (cosmético ou edge case raro)

| # | Agente | Problema | Correção |
|:-:|:-------|:---------|:---------|
| B1 | Mulligan | London mulligan não permite escolher quais cartas bottom | Documentar limitação; impacto é pequeno com shuffle aleatório |
| B2 | Battle | Phasing retorna no untap em vez do upkeep | Mover para antes do untap ou documentar |
| B3 | Battle | Sem suporte a múltiplos bloqueadores por atacante | Adicionar lógica de multi-bloqueio |
| B4 | Battle | Sem Trample, Regeneration, Protection from color | Adicionar conforme necessário para cartas específicas |

---

## 7. Conclusão

A pipeline Lorehold é um sistema de otimização de decks Commander com **confiabilidade MÉDIA-ALTA** em relação às regras oficiais de MTG. Os pontos fortes são:

- **Sistema de freios e contrapesos:** 5 agentes independentes que se validam mutuamente (Scout → Validator → Mulligan → Battle → Oracle).
- **Profundidade estratégica:** O Validator v3.13 com SYNERGY_MAP de 7 eixos é uma análise mais sofisticada do que a maioria dos jogadores humanos faria.
- **Maturidade demonstrada:** 5 ciclos consecutivos de Evolution Oracle com 0 swaps, confirmados por 4 execuções de Scout e Validator. O sistema sabe quando parar.
- **Respeito às regras fundamentais:** Color identity, singleton, commander tax, commander damage, e London Mulligan são implementados corretamente.

O ponto mais fraco é o **Battle Analyst v8**, que tem o gap mais significativo (sistema de prioridade) e várias simplificações (ataque single-target, lifelink capped, miracle timing). No entanto, como o Battle Analyst é usado para validação de win rate (não para gerar recomendações diretas de swap), seus vieses têm impacto indireto — o Evolution Oracle usa os dados de matchup para ajustar prioridades, mas as decisões finais são baseadas principalmente no Scout + Validator + Mulligan.

**Veredito final:** A pipeline é **confiável para uso como co-piloto de deckbuilding**. As recomendações de swap são seguras (respeitam regras de construção de deck) e estrategicamente fundamentadas. Os gaps encontrados são principalmente de precisão de simulação, não de legalidade. Nenhum gap encontrado recomendaria uma carta ilegal ou aplicaria um swap que violasse as regras de construção de Commander.

---

## 8. Verificação Cruzada: Commander Banlist

Foi feita uma verificação manual das cartas no deck Lorehold e na `user_collection` contra a Commander banlist oficial (Setembro 2024):

**Cartas banidas em Commander:** (lista parcial das mais relevantes)
- Ancestral Recall, Balance, Biorhythm, Black Lotus, Braids Cabal Minion, Channel, Chaos Orb, Coalition Victory, Emrakul the Aeons Torn, Erayo Soratami Ascendant, Falling Star, Fastbond, Flash, Gifts Ungiven, Griselbrand, Hullbreacher, Iona Shield of Emeria, Jeweled Lotus, Karakas, Leovold Emissary of Trest, Library of Alexandria, Limited Resources, Lion's Eye Diamond, Lutri the Spellchaser, Mana Crypt, Mox Emerald/Jet/Pearl/Ruby/Sapphire, Panoptic Mirror, Paradox Engine, Primeval Titan, Prophet of Kruphix, Recurring Nightmare, Rofellos Llanowar Emissary, Shahrazad, Sundering Titan, Sway of the Stars, Sylvan Primordial, Time Vault, Time Walk, Tinker, Tolarian Academy, Trade Secrets, Upheaval, Worldfire, Yawgmoth's Bargain, Dockside Extortionist, Jeweled Lotus, Mana Crypt (2024 bans)

**Resultado:** Nenhuma carta banida encontrada no deck Lorehold nem nas recomendações do Scout. As cartas mais próximas de controversas no deck:
- **The One Ring:** NÃO banida em Commander (banida em Modern apenas)
- **Jeska's Will:** NÃO banida
- **Smothering Tithe:** NÃO banida

**Conclusão:** O deck e as recomendações estão em conformidade com a Commander banlist.
