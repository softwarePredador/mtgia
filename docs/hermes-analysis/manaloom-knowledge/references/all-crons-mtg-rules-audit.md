# Auditoria Completa — Regras MTG em Todas as Crons

**Data:** 2026-05-31T18:00:00+00:00  
**Auditor:** MTG Rules Auditor v3  
**Escopo:** 5 crons do pipeline Lorehold (Scout, Validator, Mulligan, Battle, Evolution Oracle)  

---

## Sumário

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | 6.5/10 | MÉDIA | Sem verificação de color identity/banlist; usa T3=3.7% (ERRADO) |
| Validator | 7/10 | MÉDIA | SYNERGY_MAP ignora Stack/Graveyard Hate; classificação subjetiva; usa T3=3.7% |
| Mulligan | 7.5/10 | MÉDIA-ALTA | T1 ramp inclui cartas que NÃO geram mana no T1; London free mulligan ausente |
| Battle | 3/10 | BAIXA | **Não é simulador de jogo** — sem stack, priority, SBAs, commander damage |
| Oracle | 6.5/10 | MÉDIA | Decisões baseadas em T3 errado (3.7% ≠ 16.9%); singleton não forçado em código |
| **PIPELINE** | **6.0/10** | **MÉDIA** | Battle é o elo fraco; erro T3=3.7% contamina Scout/Validator/Oracle |

---

## 1. Scout (f20ac299992b) — Auditoria Detalhada

### O que faz certo
- Entende que 0% EDHREC ≠ carta ruim (ex: Spiteful Banditry, Xorn documentados)
- Score A+B+C (Sinergia/Custo/Evidência) é um framework razoável
- Cross-reference triplo (deck vs EDHREC vs collection) validado
- Identifica cartas de alto impacto ignoradas em execuções anteriores (Akroma's Will, Sunforger)

### O que faz errado
1. **[ALTO] Color identity não verificada programaticamente.** O prompt carrega `color_identity` da `user_collection` mas NUNCA valida se a carta está dentro da identidade de cor do comandante (Lorehold = RW). O LLM "sabe" quais cartas são R/W, mas isso é conhecimento implícito, não regra aplicada. NÃO HÁ `WHERE color_identity IN ('R','W','RW')` em nenhuma query. Se uma carta como Counterspell (U) ou Demonic Tutor (B) estivesse na collection, o Scout poderia recomendá-la.

2. **[CRÍTICO] Usa T3=3.7% como justificativa para recomendar swaps AGGRESSIVE.** O Mulligan Agent (Execução #10) provou que T3 real é 16.9%. O valor 3.7% é a taxa de **free mulligan** (0 ou 7 lands na mão). Usar este número para recomendar ΔCMC +2 é perigoso — o deck já está acima do limite de 12%.

3. **[MÉDIO] Sem verificação de banlist Commander.** Cartas banidas (ex: Limited Resources, Braids Cabal Minion como commander) não são filtradas. O LLM "sabe" da banlist mas não aplica regra formal.

4. **[BAIXO] EDHREC inclusion % calculado corretamente**, mas `trend_zscore` é usado sem intervalo de confiança — flutuações de ±0.5 podem ser ruído.

### Recomendações
- Adicionar verificação explícita de color identity: cruzar `color_identity` da collection com a identidade do comandante
- Corrigir referência a T3: usar o valor do Mulligan Agent (16.9% post-C#9), não 3.7%
- Adicionar check de banlist: `WHERE card_name IN (SELECT card_name FROM commander_banlist)`

---

## 2. Validator (712579b15767) — Auditoria Detalhada

### O que faz certo
- Classificação de importância 1-5 cobre bem o espectro estratégico
- SYNERGY_MAP com 5 eixos (Token+Pump, Wipe+Proteção, Recursion, Mana Explosiva, Combo) captura a maioria das dimensões relevantes
- Identifica corretamente double-null cards (Scroll Rack, Penance)
- Reconhece quando functional_tags do banco estão erradas
- Documenta razões de cada classificação

### O que faz errado
1. **[ALTO] SYNERGY_MAP ignora dimensões críticas do Commander:**
   - **Stack Interaction:** Sem menção a counterspells, proteção na stack, respostas instant
   - **Graveyard Hate:** Nenhum eixo cobre Rest in Peace, Leyline of the Void — como o deck LIDA com hate?
   - **Commander-specific mechanics:** Commander tax, commander damage (21), zone changes (command zone vs graveyard/exile)
   - **Lifegain/Drain:** Relevante para matchup contra aggro
   - **Mana Denial/Stax:** Como o deck joga sob Rule of Law, Drannith Magistrate?

2. **[CRÍTICO] Reproduz T3=3.7% e baseia recomendação de estratégia nisso.** O v3.8 relatório diz "Com T3 = 3.7%, estratégia AGGRESSIVE liberada." Isto é falso. O Mulligan Agent já havia reportado T3=15.3% (pré-C#9). A estratégia correta seria DEFENSIVO.

3. **[MÉDIO] "Draw real = 7" é definido pelo LLM**, não por regras de jogo. O que constitui "draw real" vs "draw condicional" é subjetivo. Esper Sentinel é draw condicional mas ainda gera vantagem de carta.

4. **[BAIXO] A classificação "Nível 1-5" é inteiramente subjetiva.** Pearl Medallion (25.2% EDHREC) como Nível 1 vs Taunt from the Rampart (35.2% EDHREC) como Nível 2 — a diferença de 1 nível não tem critério objetivo.

### Recomendações
- Adicionar "Eixo F) Stack & Interaction" e "Eixo G) Hate Pieces & Resilience"
- Corrigir T3: ler do MULLIGAN_LOG.md, não calcular internamente
- Definir critérios objetivos para Nível de Importância (ex: Nível 5 = commander + cartas com EDHREC >80% + tutor targets)

---

## 3. Mulligan (08468451a06a) — Auditoria Detalhada

### O que faz certo
- **CRITICAL: Identificou o erro T3=3.7% do Evolution Oracle.** A Execução #10 foi a primeira a documentar que 3.7% = free mulligan, não Sem Play T3. Este é o achado mais importante de TODA a pipeline.
- Definição rigorosa de "jogável" (2-4 lands + ramp OU 3+ lands) é superior à definição broad
- Simulação com seed fixo (42) permite reprodutibilidade
- Documentação de distribuição de lands (0: 3.7%, 1: 20.8%, 2: 30.2%, ...)
- Métrica "Sem Play T3" é definition-independent e serve como comparador cross-execution

### O que faz errado
1. **[CRÍTICO] T1 Ramp inclui cartas que NÃO produzem mana no turno 1:**
   - **Land Tax (CMC 1):** Busca 3 terrenos básicos e coloca na MÃO. Não produz mana nenhuma no turno 1. Só produz "ramp virtual" no turno 2+ (garante land drops futuros).
   - **Weathered Wayfarer (CMC 1):** Busca 1 terreno e coloca na MÃO. Idem — zero mana no turno 1.
   - Apenas **Sol Ring** (CMC 1, produz 2 mana incolor) REALMENTE gera mana no T1.
   
   **Impacto:** O T1 Ramp de 18-21% reportado é superestimado. O T1 Ramp REAL (mana disponível para conjurar spells de CMC 1-2 no turno 1) é apenas ~7-8% (chance de ter Sol Ring na mão inicial). Land Tax e Wayfarer são ramp T2+, não T1.
   
   **Correção correta da regra MTG:** "Ramp T1" deve significar "produz mana adicional que pode ser usada para conjurar spells NO TURNO 1." Cartas que buscam terrenos para a mão NÃO se qualificam. Cartas que buscam terrenos para o campo (Rampant Growth, Nature's Lore — que não estão em RW) se qualificariam.

2. **[ALTO] London Mulligan não implementa free mulligan multiplayer.** Regra oficial: "In a multiplayer game, the first mulligan is free" (não reduz o tamanho da mão). O código `mulligan_decision` não distingue entre o primeiro e os mulligans subsequentes. A busca "max 3 mulligans" também é arbitrária — as regras oficiais permitem continuar até 0 cartas.

3. **[MÉDIO] Prompt difere da implementação real.** O prompt diz "Considere mulligan se: 0-1 lands OR 0 ramp + 2 lands" (definição rigorosa do skill), mas o código no `battle_analyst_v6.py` usa: `2 <= lands <= 5` (definição broad). Como o Mulligan Agent tipicamente escreve seu próprio Python inline (não usa battle_analyst_v6.py), há divergência entre o que o prompt pede e o que diferentes execuções implementam.

4. **[BAIXO] "Sem Play T3" verifica CMC ≤ min(lands, 3) mas não considera:**
   - **Terrenos que entram tapped** (Temple of Triumph, Wind-Scarred Crag, etc.) — esses atrasam a disponibilidade de mana em 1 turno
   - **Requisitos de cor** — ter 3 lands incolores + um spell {R}{R}{W} ainda é "sem play"
   - **Spells que requerem sacrifício** como custo adicional

### Recomendações
- **Corrigir T1 ramp canonical set** para incluir APENAS cartas que produzem mana no T1: `T1_RAMP = {'Sol Ring'}` (em RW, apenas Sol Ring)
- Separar "T1 ramp (mana imediata)" de "T1 ramp setup (land search para T2+)"
- Implementar free first mulligan no código de simulação
- Adicionar tracking de tapped lands no "Sem Play T3"

---

## 4. Battle (94f8590b1beb) — Auditoria Detalhada

### ⚠️ AVISO: Este não é um simulador de Magic. É um modelo abstrato de combate.

### O que faz certo
- Modela curva de mana, land drops, e CMC casting
- Implementa alguns efeitos de carta reais (Teferi's Protection, Approach of the Second Sun, Insurrection, board wipes + proteção)
- Usa London mulligan (com a ressalva do free mulligan)
- Seed fixo (42) permite reprodutibilidade
- Oponentes têm perfis de arquétipo distintos com estratégias diferentes

### O que faz ERRADO — Violações das Regras Oficiais de MTG

#### 4.1 Stack e Priority (Regra 117 — INEXISTENTE)
- **O stack não existe.** Spells são conjuradas e resolvem imediatamente. Não há janela de resposta.
- **Priority (117.3) ignorada.** O active player recebe priority primeiro e deve passá-la. Aqui, spells são conjuradas em sequência linear.
- **Counterspells NÃO FUNCIONAM.** Oponentes com "counters": 8 têm cartas marcadas como `effect: "counter"` mas não há stack para counterar nada. Essas cartas são efetivamente blanks.
- **Instants vs Sorceries:** Não há distinção de timing — tudo é "sorcery speed."

#### 4.2 Turn Structure (Regra 500 — ERRADA)
- **Turn order é SEQUENCIAL em vez de circular.** O código joga Lorehold primeiro, depois cada oponente age COMPLETAMENTE (main + combat), e o turno só avança depois que todos jogaram. Correto: turnos são circulares (P1 → P2 → P3 → P4 → P1...).
- **Turn phases não implementadas.** Sem untap step, upkeep, draw step, main phase 1, combat (declare attackers/blockers), main phase 2, end step. O código tem um "main phase" seguido de "combat phase" simplificados.
- **Draw step:** Primeiro jogador não pula draw no T1? O código tem `if turn > 1 or player.name != "Lorehold"` — correto para duel, mas em commander 4-player, só o primeiro jogador pula o draw do T1.

#### 4.3 Combat (Regra 500-511 — INEXISTENTE)
- **Sem declare attackers step.** Criaturas atacam automaticamente com dano total.
- **Sem declare blockers step.** Não há bloqueio — o dano é aplicado diretamente.
- **Sem first strike/double strike damage step.** Boros Charm "double strike" é modelado como `power * 2`, mas não segue a ordem correta de dano.
- **Sem combat tricks.** Não há janela para instants de combate.
- **Sem flying, trample, menace, etc.** Akroma's Will lista keywords mas o código não as implementa no combate (só dobra power).
- **"Smart targeting" de combate** não existe nas regras — é uma heurística do simulador que distorce resultados.

#### 4.4 Commander-Specific Rules (AUSENTES)
- **Commander damage (903.10a):** "21 combat damage from a single commander." Não rastreado.
- **Commander tax (903.8):** +{2} por cada conjuração anterior da command zone. Lorehold nunca morre/retorna no simulador, mas SE morresse, não haveria tax.
- **Color identity (903.4):** Não verificado na geração de decks oponentes.
- **Commander zone (903.1):** Não existe — comandante está no deck como carta normal.

#### 4.5 State-Based Actions (Regra 704 — AUSENTES)
- **704.5a:** Jogador com 0 ou menos de vida perde. Verificado apenas ao final do jogo.
- **704.5f:** Tentativa de comprar de library vazia faz perder. Não verificado.
- **704.5g/h:** 10 poison counters / commander damage 21. Não rastreado.
- **704.7:** Legend rule. Não aplicada.
- **704.8:** World rule. Não aplicada.

#### 4.6 Efeitos de Carta — Simplificações Extremas
- **Teferi's Protection:** "Phase out" modelado como `protected = True` por 2 turnos. Regra real: permanentes phase out (não existem), life total não pode mudar, proteção de tudo. O efeito real é MUITO mais complexo.
- **Boros Charm:** "Indestructible" modelado como `protected = True`. Só protege contra destroy, não contra exile, sacrifice, -X/-X, ou bounce. Com Akroma's Will (que dá indestructible + prot all colors), o modelo protected=True é uma supersimplificação.
- **Approach of the Second Sun:** Corretamente implementado (7 from top, 2 casts = win).
- **Insurrection:** "Rouba todas as criaturas" — mas não as devolve no end step (erro).
- **Mizzix's Mastery:** "Overload" modelado como dano = nº de spells no grave × 3. Não interage com tipos de carta, CMC, ou alvos. Com Double Vision, trata como ×2 spells.
- **Call Forth the Tempest:** "Cascade em Approach" mencionado mas cascade não implementado — só gera tokens e causa dano.
- **Scroll Rack e Sensei's Divining Top:** Ambos mapeados para `topdeck_manipulation` com efeito "draw 1". Completamente errado — o propósito real é manipular o topo do deck para Miracle (Dance with Calamity) e Approach.

#### 4.7 Oponentes — Decks Genéricos, Não Reais
- Oponentes são gerados por `generate_opponent_deck()` que cria cartas genéricas com nomes como "Ramp Card", "Board Wipe", "Filler Creature".
- **Não são decks reais.** São distribuições estatísticas baseadas em contagens por arquétipo.
- **Sem sinergia.** Um deck Krenko com 35 "Creature" genéricas não tem os efeitos reais de Krenko (goblin tokens, lords, sac outlets).
- **Sem comandante.** Oponentes não têm comandante — as 99 cartas são tratadas como um deck normal.
- **Win rate é contra modelos estatísticos, não contra decks.** O resultado "23% vs Aggro" NÃO significa que Lorehold perde para Krenko — significa que o modelo abstrato "aggro" com 35 criaturas genéricas consistentemente reduz a vida de Lorehold a 0.

### Conclusão sobre o Battle

O rótulo "REAL Game Simulator" é **enganoso**. Este é um modelo abstrato de combate que:
- Não implementa stack, priority, turn structure, ou commander-specific rules
- Modela efeitos de carta com simplificações extremas
- Usa oponentes genéricos, não decks reais
- Produz números que podem ser DIRECIONALMENTE corretos (Lorehold é fraco contra aggro) mas não são QUANTITATIVAMENTE confiáveis

**Os 48.3% WR reportados não são um win rate real contra decks reais.**

### Recomendações
- **Renomear** para "Battle Abstract Model" ou "Matchup Projection"
- Adicionar disclaimer no BATTLE_LOG: "Este não é um simulador de regras — é uma projeção baseada em perfil de arquétipo"
- NÃO usar estes números para decisões estratégicas de swap sem triangulação com os outros agentes
- Para um simulador real: implementar stack, priority, turn phases, e commander-specific rules (projeto de longo prazo)

---

## 5. Evolution Oracle (a50bef4c2a59) — Auditoria Detalhada

### O que faz certo
- PASSO 0 com 5 perguntas obrigatórias cobre bem o pensamento estratégico de Commander
- "Como ganha?", "Como evita perder?", "Como gera vantagem?" são perguntas de deckbuilding real
- Swap selection respeita CMC budget, depletion de collection, e necessidade estratégica
- Documenta candidatos rejeitados com justificativa (transparência)
- Ciclo #8 (0 swaps) demonstrou maturidade — nem todo ciclo precisa de swap

### O que faz errado
1. **[CRÍTICO] Ciclo #7, #8 e #9 usaram T3=3.7% para justificar estratégia AGGRESSIVE.** O Mulligan Agent depois provou que T3 real era ~16.9%. Net ΔCMC acumulado de +4 (C#7: +2, C#8: 0, C#9: +2) foi aplicado sob a premissa falsa de que o deck tinha ampla margem de T3. A consequência: o deck piorou em early-game por 3 ciclos consecutivos.

2. **[ALTO] Singleton rule (903.5b) não é forçada em código.** O prompt diz "Verificar: 100 cartas, commander qty=1, lands >= 34" mas a verificação é delegada ao LLM. O script de swap incluído no skill tem `assert c.fetchone()[0] == 100` mas não verifica se há cartas duplicadas não-básicas.

3. **[MÉDIO] A priorização "Necessidade Estratégica 0-5" é puramente subjetiva.** Akroma's Will recebeu Necessidade=4, mas Spiteful Banditry também receberia 4. Sem critérios objetivos, a escolha entre ambos depende do julgamento do LLM.

4. **[MÉDIO] CMC verification após Ciclo #6 foi corrigida, mas não cobre edge cases:**
   - Cartas com X no custo (ex: Finale of Promise) — CMC na stack ≠ CMC na mão
   - Cartas com Miracle (Dance with Calamity) — CMC efetivo pode ser menor
   - Cartas com Delve, Convoke, Affinity — CMC nominal ≠ CMC real pago

5. **[BAIXO] "Recomendações de Aquisição" (Skullclamp, Mana Vault, Chrome Mox, Wheel of Fortune) incluem cartas RESERVED LIST e Game Changers** sem mencionar:
   - Wheel of Fortune é Reserved List (~$300+)
   - Mana Vault é Game Changer
   - Chrome Mox é Game Changer em potencial
   Isso afeta decisões de bracket.

### Recomendações
- **CORRIGIR fonte de T3:** Ler MULLIGAN_LOG.md em vez de calcular internamente
- **Validar T3 contra Mulligan Agent** antes de decidir estratégia (AGGRESSIVE vs DEFENSIVE)
- Adicionar regra explícita: "Nenhum swap pode ser aplicado se T3 > 12% e ΔCMC > 0"
- Adicionar verificação de singleton no script de swap
- Incluir informação de preço/reserved list nas aquisições recomendadas

---

## Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO

| # | Problema | Afeta | Correção | Esforço |
|:--|:---------|:------|:---------|:--------|
| 1 | **T3=3.7% usado por 3 crons** (Scout, Validator, Oracle) | Pipeline inteira | Corrigir prompts para ler MULLIGAN_LOG.md. Adicionar verificação cruzada: se Oracle reporta T3 diferente do Mulligan, rejeitar Oracle. | Baixo |
| 2 | **T1 Ramp inclui cartas que não produzem mana no T1** (Land Tax, Weather Wayfarer) | Mulligan (superestima consistência early-game) | Corrigir canonical T1_RAMP para apenas cartas que produzem mana no T1: `{'Sol Ring'}`. Separar "T1 ramp (mana)" de "T1 land tutor". | Baixo |
| 3 | **Battle não é um simulador de regras** | Battle (48.3% WR não é confiável) | Renomear para "Matchup Projection". Adicionar disclaimer. NÃO usar para decisões de swap sem triangulação. Longo prazo: implementar stack + priority. | Alto |

### 🟡 ALTO

| # | Problema | Afeta | Correção | Esforço |
|:--|:---------|:------|:---------|:--------|
| 4 | **Color identity não verificada pelo Scout** | Scout (pode recomendar cartas ilegais) | Adicionar `WHERE color_identity IN ('R','W','RW')` nas queries. Criar tabela de color identity mapping. | Baixo |
| 5 | **London free mulligan ausente no Mulligan e Battle** | Mulligan, Battle (superestima mulligan rate) | Adicionar flag `is_first_mulligan = True`. Se true: draw 7 sem reduzir. | Baixo |
| 6 | **Singleton rule não forçada no Oracle** | Oracle (swap script pode criar deck ilegal) | Adicionar `SELECT card_name, COUNT(*) FROM deck_cards GROUP BY card_name HAVING COUNT(*) > 1 AND card_name NOT LIKE 'Mountain' AND ...` | Baixo |
| 7 | **SYNERGY_MAP ignora Stack/Interaction e Graveyard Hate** | Validator | Adicionar eixos F e G. | Médio |

### 🔵 MÉDIO

| # | Problema | Afeta | Correção | Esforço |
|:--|:---------|:------|:---------|:--------|
| 8 | **Battle não tem stack — counterspells são blanks** | Battle | Se não implementar stack completo, pelo menos remover counterspells dos perfis de oponente ou modelá-los como "draw adicional" | Baixo |
| 9 | **Commander damage/tax ausentes no Battle** | Battle | Adicionar tracking de commander damage (21) e tax (+2 por cast) | Médio |
| 10 | **Sem verificação de banlist no Scout** | Scout | Criar tabela `commander_banlist` ou hardcoded list | Baixo |

### 🟢 BAIXO

| # | Problema | Afeta | Correção |
|:--|:---------|:------|:---------|
| 11 | "Sem Play T3" não considera tapped lands | Mulligan | Filtrar terrenos que entram tapped (type_line contém "enters tapped") |
| 12 | CMC edge cases (X spells, Miracle, Delve) não tratados | Oracle | Documentar que CMC nominal é usado; listar exceções conhecidas |
| 13 | Recomendações de aquisição omitem preço/RL | Oracle | Adicionar coluna de preço/raridade |

---

## Conclusão

A pipeline Lorehold tem confiabilidade **MÉDIA** em relação às regras oficiais de MTG.

**O que funciona bem:**
- Mulligan Agent: consistentemente mede consistência de mão com metodologia reproduzível. Foi o ÚNICO agente a detectar o erro T3=3.7%.
- Evolution Oracle: framework estratégico (PASSO 0) é sólido como pensamento de deckbuilding
- Scout: score A+B+C captura sinergia bem, e entende limitações do EDHREC

**O que é preocupante:**
- **Battle:** O elo mais fraco. Chamá-lo de "REAL Game Simulator" é enganoso. É um modelo abstrato que não implementa a maioria das regras fundamentais de MTG (stack, priority, combat steps, SBAs, commander damage). Seus números de WR não devem ser usados sozinhos para decisões.
- **Erro T3=3.7%:** Este erro contamina 3 dos 5 agentes e causou 3 ciclos de estratégia AGGRESSIVE quando o deck precisava de DEFENSIVO. O Mulligan Agent já identificou e documentou o erro — agora os outros agentes precisam ser corrigidos.
- **T1 Ramp superestimado:** Land Tax e Weathered Wayfarer NÃO produzem mana no T1. O conjunto canônico `T1_RAMP = {'Sol Ring'}` é o correto.

**O que fazer AGORA (ordem de prioridade):**
1. Corrigir T3=3.7% → 16.9% nos prompts do Scout, Validator, e Oracle (esforço: 30 min)
2. Corrigir T1 Ramp canonical set (esforço: 15 min)
3. Renomear Battle + adicionar disclaimer (esforço: 15 min)
4. Adicionar verificação de color identity no Scout (esforço: 30 min)
5. Adicionar free first mulligan no código do Mulligan (esforço: 15 min)
