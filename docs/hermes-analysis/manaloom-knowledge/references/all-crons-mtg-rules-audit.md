# Auditoria Completa — Regras MTG em Todas as Crons

**Data:** 2026-06-01T14:45:00+00:00  
**Versão:** v3.1 (re-auditoria com outputs reais)  
**Escopo:** 5 crons do pipeline Lorehold  
**Fonte:** Prompts de `/opt/data/cron/jobs.json`, outputs em `/opt/data/cron/output/*/`, código Dart em `server/lib/ai/battle_simulator.dart`

---

## Sumário

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | 3.5/10 | BAIXA | Prompt desalinhado com função real; retorna [SILENT] 94% das execuções |
| Validator | 8.5/10 | ALTA | SYNERGY_MAP cobre 7 eixos; PG comparison funcional; hash verificado |
| Mulligan | 7.0/10 | MÉDIA-ALTA | London Mulligan correto; sem tapped lands/color screw; T3 13.3% estável |
| Battle | 5.0/10 | BAIXA | 2-player apenas; sem stack; sem Commander damage/tax; NÃO é cron |
| Oracle | 7.5/10 | MÉDIA-ALTA | Wincon diversity sólido; 0 swaps válido; recomenda mas não aplica |
| **PIPELINE** | **6.3/10** | **MÉDIA** | **Hash integrity gap (C#17-C#22) comprometeu 5 ciclos inteiros** |

---

## 1. Scout (f20ac299992b) — Auditoria Detalhada

### O que faz (pelo prompt)
Busca wincons na `user_collection` via `card_deck_analysis`, ranqueia por speed/resilience/stealth, prioriza gaps nas 3 categorias (RÁPIDA/RESILIENTE/STEALTH).

### O que faz certo
- ✅ **Color identity respeitada:** O prompt usa `user_collection` que já filtra por coleção do usuário. Mas não há verificação explícita de color identity no prompt.
- ✅ **Resilience floor:** Rejeita cartas com resilience ≤ 2 corretamente (morrem pra qualquer remoção).
- ✅ **Proteção requerida:** Identifica quais wincons precisam de proteção extra (Approach → Grand Abolisher/Silence).
- ✅ **EDHREC cross-reference:** O skill carregado documenta o uso correto de `trend_zscore` e `inclusion_pct`.

### O que faz errado
- 🔴 **Prompt desalinhado com a função histórica do Scout:** O Scout originalmente fazia busca completa de cartas na coleção × EDHREC, ranqueando por sinergia (Score A+B+C). O prompt atual só busca wincons via `card_deck_analysis` — perdeu a função de "scout de sinergia". O EDHREC JSON API, `user_collection` cross-ref, e análise de tendências estão documentados no skill mas NÃO são executados pelo prompt.
- 🔴 **94% das execuções retornam [SILENT]:** Das últimas 10 execuções, apenas 1 produziu análise (Execução #21 de 2026-05-31). As outras 9 retornaram [SILENT]. Isso significa que o Scout efetivamente NÃO está funcionando como scout de deck — só como verificador de "há algo novo?".
- 🔴 **Não verifica banlist Commander:** O prompt não menciona verificação de cartas banidas. Cartas como Limited Resources, Worldfire (banida em alguns formatos), etc. não são filtradas.
- 🟡 **Score de sinergia usa `card_deck_analysis` estático:** Os scores (speed/resilience/stealth) vêm de dados pré-calculados, não de análise dinâmica do deck atual. Se o `card_deck_analysis` está desatualizado (ex: Twinflame tem scores DEFAULT 5/5/5 em vez do combo real), o Scout recomenda com base em dados ruins.
- 🟡 **Não verifica singleton rule:** O prompt não verifica se a carta já está no deck (exceto pelo `NOT IN (SELECT card_name FROM deck_cards WHERE deck_id=6)`).

### Recomendações
1. **[CRÍTICO]** Restaurar o prompt do Scout para a função original: busca completa EDHREC + coleção + sinergia A+B+C. O prompt atual é um "Wincon Hunter" disfarçado de Scout.
2. **[ALTO]** Adicionar verificação de Commander banlist (`web_search "mtg commander banlist 2025"`).
3. **[MÉDIO]** Adicionar verificação de singleton rule + basic land exception.
4. **[MÉDIO]** Recalcular scores de sinergia dinamicamente em vez de confiar em `card_deck_analysis` estático.

---

## 2. Validator (712579b15767) — Auditoria Detalhada

### O que faz (pelo prompt)
Análise estrutural do deck vs PG `commander_reference_deck_analysis` + SYNERGY_MAP com 7 eixos + `card_rulings` para interações.

### O que faz certo
- ✅ **Hash verification (v3.14+):** O Validator agora computa `md5(card_names)` do DB no início de cada execução (desde a descoberta do hash-fake C#17-C#22). Output v3.21 confirma: `30d00347764fc2a215edb4e668994871`.
- ✅ **SYNERGY_MAP cobre 7 eixos estratégicos:** A) Token+Pump, B) Wipes+Proteção, C) Recursion, D) Explosive Mana, E) Combo Pieces, F) Stack Interaction, G) Resilience. Cobertura abrangente.
- ✅ **PG Comparison funcional:** Compara métricas do deck vs perfil PostgreSQL. Identificou gap de tutor (-1.67).
- ✅ **Double-null detection:** Auditoria de cartas com `functional_tag IS NULL` e zero `card_tags`. Reporta 4 double-nulls no deck.
- ✅ **MDFC duplicate detection:** Query para detectar linhas duplicadas de MDFC (ex: Valakut Awakening id=350 e id=653).
- ✅ **Collection-aware swap table:** Recomenda apenas cartas que existem na `user_collection`.
- ✅ **Run log:** Registra cada execução com status (`ok-no-change` quando deck inalterado).

### O que faz errado
- 🟡 **Stack Interaction (Eixo F) pontua apenas 5/10:** O Validator identifica corretamente que o deck tem pouca interação na stack (apenas Deflecting Swat, Boros Charm, Chaos Warp). Mas não quantifica quantos counterspells/stifle effects seriam ideais para o arquetipo spellslinger.
- 🟡 **PG indisponível não bloqueia análise:** v3.21 reportou "PostgreSQL unavailable this run (connection refused)" e usou dados cacheados da v3.19. Isso é aceitável mas deve ser sinalizado como degradação.
- 🟢 **Sem tema-aware validation:** Usa ranges genéricos independente do tema. Documentado como Gap 4 conhecido.

### Recomendações
1. **[MÉDIO]** Adicionar recomendação quantitativa de stack interaction baseada no arquetipo (spellslinger = 3-5 counters/interações de stack).
2. **[BAIXO]** Cache de PG data localmente para evitar dependência de conexão.

---

## 3. Mulligan (08468451a06a) — Auditoria Detalhada

### O que faz (pelo prompt)
Simulação de 1000 mãos com Python + random.shuffle, mede T3 consistency, London Mulligan com free first.

### O que faz certo
- ✅ **London Mulligan — free first:** O prompt documenta corretamente: `bottom_count = max(0, mulligan_count - 1)`. O primeiro mulligan é grátis em Commander multiplayer (CR 103.4c).
- ✅ **Definição rigorosa de "jogável":** 2-4 lands AND (ramp >= 1 OR lands >= 3). Correta para Commander.
- ✅ **T1 ramp estrita:** Apenas `{Sol Ring}` como T1 mana producer. Land Tax e Weathered Wayfarer corretamente excluídos (buscam para a mão, não produzem mana).
- ✅ **Seed fixa (42):** Reprodutibilidade entre execuções.
- ✅ **Hash verification:** Verifica `card_hash` do DB antes de simular.
- ✅ **Detecta swaps não aplicados:** Identificou que C#23 swaps (Apex→Demand Answers, Storm Herd→Thrill) NÃO foram aplicados no DB.

### O que faz errado
- 🟡 **Tapped lands não simulados:** Temple of Triumph, Boros Garrison, e outros tapped duals são tratados como untapped. Num deck com ~5 tapped lands, isso subestima "Sem Play T3" em ~1-3pp.
- 🟡 **Color requirements não verificados:** Mão com 3 Mountains + todos spells brancos é considerada "jogável" se tiver 3+ lands. Na realidade, é um mulligan. Superestima consistência em ~3-8pp.
- 🟡 **Sem draws futuros:** Só avalia mão inicial. Não simula draws dos turnos 1-3, o que subestima a probabilidade de encontrar lands/ramp nos primeiros turns. Este viés é oposto ao dos tapped lands (compensa parcialmente).
- 🟡 **Commander não está na mão inicial:** O Commander começa na Command Zone. A simulação não modela o acesso garantido ao Commander — que é uma fonte confiável de "ação" nos primeiros turnos.
- 🟢 **Mulligan definition no prompt:** "0-1 lands OR 0 ramp + 2 lands" é uma simplificação. O London Mulligan real permite decidir com base na qualidade da mão, não apenas contagem de lands/ramp. Mas para simulação estatística, é aceitável.

### Recomendações
1. **[ALTO]** Adicionar simulação de tapped lands (entram tapped → -1 mana no turno).
2. **[MÉDIO]** Adicionar verificação básica de color requirements (pelo menos 1 fonte de cada cor necessária para spells na mão).
3. **[MÉDIO]** Simular draws dos turnos 1-3 para refinar T3 (já documentado no protocolo).
4. **[BAIXO]** Considerar Commander como "sempre disponível" (CMC + tax) para T3.

---

## 4. Battle Analyst (94f8590b1beb) — Auditoria Detalhada

### Status: NÃO é um cron ativo
O Battle Analyst **não existe** como cron job em `/opt/data/cron/jobs.json`. Não há diretório de output em `/opt/data/cron/output/94f8590b1beb/`. O código existe em `server/lib/ai/battle_simulator.dart` (879 linhas) mas não é executado por nenhum cron automático.

### O que o código faz (battle_simulator.dart)
Simulador de combate 2-player simplificado:
- 2 jogadores (Deck A vs Deck B)
- Turnos alternados até maxTurns
- Fases: Untap → Upkeep → Draw → Main 1 → Combat → Main 2 → End
- Sem stack: "Sem stack complexo (resolução imediata)" — linha 9
- Suporte a keywords: flying, haste, vigilance, lifelink, deathtouch, trample, first strike
- Bloqueio: 1 blocker por attacker
- Dano: simultâneo (exceto first strike)
- Sem Commander damage tracking
- Sem Commander tax
- Sem multiplayer (2-player duel apenas)

### O que faz certo
- ✅ **Combat damage com trample:** Linha 497-499, dano excedente passa para o jogador.
- ✅ **First strike vs regular damage:** Linha 474-483, first strike resolve antes.
- ✅ **Deathtouch interaction:** Verificado em first strike (linha 476) e dano normal (linha 489).
- ✅ **Lifelink sem cap:** Linha 516-519, `active.life += lifeGained` — sem `min(40, ...)`. Diferente do que o audit anterior reportava.
- ✅ **Flying evasion:** Criaturas com flying só podem ser bloqueadas por outras com flying/reach.
- ✅ **Mulligan implícito:** 7 cartas iniciais sem opção de mulligan (simplificação aceitável para simulação).

### O que faz errado
- 🔴 **Sem stack/priority (CR 117):** "Sem stack complexo (resolução imediata)". Isso significa que:
  - Não há janela de resposta para counterspells
  - Spells resolvem imediatamente sem passar prioridade
  - Nenhum jogador pode responder a spells do oponente
  - **Impacto:** Counterspells, removal em resposta, e proteção são inúteis. O simulador não testa interação real.
- 🔴 **2-player apenas (não Commander multiplayer):** Commander é 4-player. O simulador é 1v1. Não modela:
  - Política de mesa (quem atacar?)
  - Arqui-inimigo dinâmico
  - 3 oponentes com recursos independentes
- 🔴 **Sem Commander damage (CR 903.10a):** 21 dano de commander = derrota. Não implementado.
- 🔴 **Sem Commander tax (CR 903.8):** Commander não pode ser re-conjurado da command zone com +{2} por cast anterior.
- 🟡 **1 blocker por attacker:** Em MTG real, múltiplos bloqueadores podem bloquear um atacante.
- 🟡 **Sem multiple attackers por oponente:** Em Commander multiplayer, ataques podem ser divididos entre oponentes (CR 802.1a). No simulador 2-player, isso não se aplica.
- 🟡 **Sem ETB triggers:** Criaturas que entram no campo não disparam abilities.
- 🟡 **Sem planeswalkers:** Apenas criaturas e terrenos são modelados.
- 🟡 **Mana simplificado:** `player.manaAvailable = player.lands.length` — trata todos os terrenos como produtores de 1 mana da cor correta. Ignora color requirements e mana rocks.

### Verdict
O `battle_simulator.dart` é um **protótipo educacional**, não um simulador de Commander funcional. Ele modela combate básico 1v1 mas não simula stack, prioridade, commander tax/damage, ou multiplayer. **Não deve ser usado para decisões de swap** — suas métricas de win rate não refletem jogos reais de Commander.

### Recomendações
1. **[CRÍTICO]** Não usar métricas do Battle Analyst para decisões de swap até implementar stack e multiplayer.
2. **[ALTO]** Se o simulador for priorizado: implementar stack LIFO mínimo (spell → prioridade → resolve).
3. **[ALTO]** Expandir para 4-player com política de ataque simples.
4. **[MÉDIO]** Adicionar Commander damage tracking e Commander tax.

---

## 5. Evolution Oracle (a50bef4c2a59) — Auditoria Detalhada

### O que faz (pelo prompt)
Wincon Diversity Oracle: verifica 3 categorias (RÁPIDA/RESILIENTE/STEALTH), busca gaps, recomenda swaps.

### O que faz certo
- ✅ **Pipeline integrity check:** Linha 1670 do output 11:38: verifica `card_hash` contra DB (`30d00347...`). Detecta swaps não aplicados.
- ✅ **Wincon diversity framework sólido:** 3 categorias com thresholds claros. Identificou STEALTH gap (vazio, stealth ≥ 7).
- ✅ **Proteção requerida mapeada:** Para cada wincon frágil, lista proteção necessária (Approach → Grand Abolisher/Silence/Boseiju).
- ✅ **Twinflame combo detection:** Identificou que Twinflame (CMC 2) + Dualcaster Mage (já no deck) = combo infinito stealth, e que `card_deck_analysis` tem scores DEFAULT.
- ✅ **0 swaps válido:** Quando não há candidatos viáveis, recomenda 0 swaps com justificativa.
- ✅ **Priorização correta:** CRÍTICA (re-adicionar cartas perdidas) > MÉDIA (novas adições) > BAIXA (aquisições).
- ✅ **Aquisição recommendations:** Lista cartas para comprar com custo estimado.
- ✅ **Singleton check implícito:** Ao recomendar re-adicionar Twinflame, verifica que não está no deck.

### O que faz errado
- 🔴 **Não aplica swaps — mas o prompt sugere que deveria:** O título "Evolution Oracle" e o framework de "Ciclos" implicam que swaps são aplicados. Na realidade, o Oracle só recomenda. Os swaps do C#23 (recomendados há 24h+) NUNCA foram aplicados no `knowledge.db`. Isso cria uma desconexão perigosa: o pipeline acredita que o deck está evoluindo quando na verdade está estagnado.
- 🔴 **Desconexão com EVOLUTION_LOG.md histórico:** O Oracle atual é "Wincon Diversity Oracle", não o "Evolution Oracle" histórico que lia SCOUT_LOG + VALIDATOR_LOG + MULLIGAN_LOG + BATTLE_LOG e sintetizava todos os agentes. A função de síntese multi-agente foi perdida.
- 🟡 **Wincon scoring é estático:** Usa `card_deck_analysis` pré-calculado. Scores DEFAULT (5/5/5) para cartas não enriquecidas distorcem recomendações.
- 🟡 **Não lê MULLIGAN_LOG para T3:** Não verifica o impacto de T3 das recomendações. O Oracle recomenda ΔCMC -13 (Storm Herd CMC 10 + Call Forth CMC 8 → Twinflame CMC 2 + Flare CMC 3) mas não projeta o novo T3.
- 🟡 **Não verifica Commander deck construction rules explicitamente:** 100 cards, 1 commander, color identity. Confia que o DB está correto.
- 🟢 **Worldfire como "wincon simbólico":** Corretamente identificado como resiliente mas impraticável (14+ mana, sem follow-up).

### Recomendações
1. **[CRÍTICO]** Restaurar a função de síntese multi-agente: ler SCOUT_LOG + VALIDATOR_LOG + MULLIGAN_LOG + EVOLUTION_LOG histórico antes de recomendar.
2. **[CRÍTICO]** Implementar aplicação de swaps no `knowledge.db` OU renomear o cron para "Oracle (Recommendation Only)" e deixar claro que swaps são manuais.
3. **[ALTO]** Adicionar projeção de T3 para cada recomendação de swap.
4. **[MÉDIO]** Recalcular wincon scores dinamicamente considerando o deck atual (ex: Approach speed sobe com mais topdeck manipulation).

---

## 6. Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (quebra o pipeline)

1. **Pipeline Integrity — Hash verification failure (C#17-C#22):** 5 ciclos consecutivos operaram com hash falso. Swaps do C#10 (Twinflame, Flare of Duplication) foram revertidos silenciosamente. **Fix:** Todo agente DEVE recomputar hash do DB no início. Já implementado no Validator (v3.14+) e Mulligan (Exec#13+). Precisa ser estendido ao Scout e Oracle.

2. **Scout retornando [SILENT] 94% das execuções:** O Scout perdeu sua função original. Precisa de prompt restoration para busca completa EDHREC + sinergia.

3. **Evolution Oracle não aplica swaps:** O pipeline acredita que o deck evolui mas o DB está estagnado desde C#10 (hash-fake recovery). Swaps do C#23 recomendados há 24h+ nunca aplicados.

4. **Battle Analyst não é funcional para Commander:** 2-player, sem stack, sem Commander damage/tax. Métricas de win rate não são confiáveis. Remover da pipeline de decisão até implementar stack + multiplayer.

### 🟡 ALTO (distorce resultados)

5. **Mulligan — Tapped lands não simulados:** ~5 tapped lands no deck → T3 subestimado em 1-3pp. Adicionar `enters_tapped` flag às lands.

6. **Mulligan — Color requirements não verificados:** Mão mono-cor com spells da outra cor é falsamente "jogável". Superestima em 3-8pp.

7. **Oracle — Prompt perdeu síntese multi-agente:** Deve ler todos os logs antes de recomendar swaps.

### 🔵 MÉDIO (imprecisão significativa)

8. **Scout — Prompt é só "Wincon Hunter":** Não faz o que o nome sugere (scout de sinergia EDHREC + coleção).

9. **Validator — Stack Interaction (Eixo F) não quantificado:** Sabe que é 5/10 mas não recomenda quantos counterspells seriam ideais.

10. **Battle — Sem ETB triggers e planeswalkers:** Limita severamente a utilidade do simulador mesmo para 1v1.

### ⚪ BAIXO (cosmético ou documentação)

11. **Oracle — Nome "Evolution Oracle" vs função real:** O cron recomenda mas não evolui o deck. Renomear para "Wincon Diversity Oracle" ou implementar swap application.

12. **Validator — Dependência de PG connection:** Usa cache quando PG offline, mas não sinaliza degradação no output.

---

## 7. Conclusão

A pipeline Lorehold tem confiabilidade **MÉDIA (6.3/10)** em relação às regras oficiais de MTG. Os pontos fortes são:

- **Validator (8.5/10):** Análise estrutural sólida com SYNERGY_MAP de 7 eixos, PG comparison, hash verification. É o agente mais confiável da pipeline.
- **Mulligan (7.0/10):** London Mulligan correto, T1 ramp estrita, seed fixa. As limitações (tapped lands, color screw, sem draws futuros) são conhecidas e documentadas.
- **Oracle (7.5/10):** Wincon diversity analysis é boa, mas perdeu a função de síntese multi-agente e não aplica swaps.

Os pontos fracos críticos são:

- **Scout (3.5/10):** Praticamente inoperante (94% [SILENT]). Prompt atual é um "Wincon Hunter", não um Scout de sinergia.
- **Battle (5.0/10):** Não é um cron ativo. O código existe mas é um protótipo 2-player sem stack, inútil para Commander.
- **Pipeline Integrity Gap (C#17-C#22):** 5 ciclos de decisões baseadas em hash falso. Este é o problema mais grave já detectado — agentes confiaram em dados de logs em vez de verificar o DB.

**A pipeline funciona para análise e recomendação, mas NÃO para evolução automática do deck.** O gap entre "recomendar swap" e "aplicar swap" não é técnico — é de design. Até que os swaps sejam aplicados automaticamente (ou o pipeline seja redesignado como recommendation-only), o deck está efetivamente congelado no estado pós-C#10.

**Hash integrity é o "canário na mina de carvão":** Se 5 ciclos passaram sem ninguém detectar que o deck mudou, a pipeline não tem os checks básicos de integridade que qualquer sistema de produção exige. A correção (hash verification no início de cada agente) é simples e já está parcialmente implementada — precisa ser universal.
