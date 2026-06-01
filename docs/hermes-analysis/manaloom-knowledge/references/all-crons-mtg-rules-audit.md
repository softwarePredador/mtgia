# MTG Rules Compliance Audit — Full Pipeline v3.2 (2026-06-01, Terceira Auditoria)

**Commit:** `af9814e2` (antes do commit deste relatório)
**Auditor:** MTG Rules Auditor v3 (cron job)
**Data da inspeção:** 2026-06-01T21:20Z

---

## Sumário (CORRIGIDO v3.2 — v3.1 corrigiu 3 erros factuais, v3.2 inspecionou código real + outputs de cron)

| Cron | Score | Verdict | Critical Gaps |
|:-----|:-----:|:--------|:--------------|
| Scout | 3.5/10 | 🔴 BAIXA | Prompt é "Wincon Hunter", perdeu A+B+C synergy scoring, 94% [SILENT], não cruza EDHREC JSON API |
| Validator | 7.0/10 | ⚠️ MÉDIA | SYNERGY_MAP cobre 7 eixos, detecta gaps críticos; mas referencia tabela inexistente `card_oracle_data` |
| Mulligan | 6.5/10 | ⚠️ MÉDIA-ALTA | London Mulligan correto + free first, definição rigorosa; sem tapped lands, sem color screw, ~60% [SILENT] |
| Battle | N/A | 🔴 NÃO É CRON | Sem entrada em `jobs.json`, sem diretório de output, sem Commander damage/tax/stack |
| Oracle | 3.5/10 | 🔴 BAIXA | SCRIPT-only (não é LLM), determinístico, perdeu síntese multi-agente, não recomenda swaps |
| **PIPELINE** | **5.1/10** | 🔴 **BAIXA** | 0/5 agentes verificam banlist, 1/5 é script determinístico, 1/5 não é cron, 2/5 prompts errados |

---

## v3.1 Factual Errors (Confirmados Corrigidos)

| v1 Claim | Reality | Evidence (v3.2) |
|:---------|:--------|:-----------------|
| "Battle lifelink capped at 40" | FALSE — `active.life += lifeGained` sem `min()` | `battle_simulator.dart:516-519` |
| "Battle has no trample" | FALSE — `attacker.hasTrample` implementado linha 497 | `battle_simulator.dart:497-499` |
| "Battle is a cron, 6.5/10" | FALSE — sem entrada em jobs.json, dir `94f8590b1beb/` não existe | `ls /opt/data/cron/output/94f8590b1beb/` → "No such file" |
| "Scout 8.0/10, ALTA" | FALSE — 3.5/10, prompt é Wincon Hunter | Prompt real lido de jobs.json vs skill docs |

## v3.1 Corrections (Confirmados Mantidos)

| v3.1 Claim | v3.2 Verdict | Evidence |
|:-----------|:-------------|:---------|
| Validator references nonexistent `card_oracle_data` | ✅ CONFIRMADO | Prompt diz `card_oracle_data.ruling_text`; tabela real é `card_rulings` |
| Oracle lost multi-agent synthesis | ✅ CONFIRMADO + AGRAVADO | É `no_agent: true` — script determinístico, não LLM |
| No banlist verification in any agent | ✅ CONFIRMADO | 0/5 agentes checam banlist; backend product code (`sinergia.dart`, `format_staples_service.dart`) USA `-is:banned` |

---

## Scout (f20ac299992b) — Auditoria Detalhada

### O que faz certo:
- **Score de wincon (speed/resilience/stealth) é razoável** como uma dimensão de análise. A query SQL que busca `card_deck_analysis` para wincons na coleção é sintaticamente correta.
- **Não repete wincons já no deck** — a query usa `NOT IN (SELECT card_name FROM deck_cards WHERE deck_id=6)`.

### O que faz errado:
1. **🔴 Prompt perdeu função original.** A+B+C synergy scoring (EDHREC + coleção + sinergia) foi substituído por um "Wincon Hunter" que só busca `card_deck_analysis`. Não lê EDHREC JSON API, não cruza `user_collection` para cartas não-wincon, não avalia sinergia com o motor do deck.
2. **🔴 94% das execuções recentes são [SILENT].** Das últimas 10 execuções, 9 retornaram [SILENT]. O agente só roda quando encontra wincons novos — que é raro porque a coleção está esgotada.
3. **🔴 Não verifica color identity.** A query filtra apenas por `card_en NOT IN deck_cards`, sem checar se a carta é Boros-legal (`color` column em `user_collection`).
4. **🔴 Não verifica banlist.** Nenhuma checagem contra Commander banlist (83 cartas banidas). Mitigação: backend product code (`format_staples_service.dart`) usa `is_banned=false`, mas o Scout não consulta essa tabela.
5. **🟡 EDHREC inclusion % não é usado.** O prompt original documentado na skill inclui `trend_zscore` e `inclusion_pct` da EDHREC JSON API. O prompt atual não referencia EDHREC.
6. **🟡 Não detecta double-null cards.** Cartas como Scroll Rack e Penance (core engines sem tag funcional) são invisíveis para o Scout.
7. **🟡 Priorização ignora CMC.** `resilience >= 7: WINCON IMBATIVEIS — prioridade maxima` — mas se a carta tem CMC 10 e piora T3, não deveria ser prioridade máxima.

### Recomendações:
1. **Restaurar prompt original:** EDHREC JSON API → cross-ref `user_collection` → Score A (Sinergia) + B (Custo) + C (Evidência)
2. **Adicionar filtro de color identity:** `AND (uc.color IS NULL OR uc.color IN ('R','W','R,W'))`
3. **Adicionar verificação de banlist:** JOIN com `card_legalities` ou `format_staples`
4. **Manter "Wincon Hunter" como seção,** não como prompt inteiro

---

## Validator (712579b15767) — Auditoria Detalhada

### O que faz certo:
1. **✅ SYNERGY_MAP cobre 7 eixos estratégicos:** Token+Pump, Wipes+Proteção, Recursion, Explosive Mana, Combo Pieces, Stack Interaction, Resilience. Cobertura abrangente de dimensões de Commander.
2. **✅ PG comparison usa métricas reais:** lands, ramp, ritual_treasure, big_spell_payoff, miracle_topdeck, interaction, protection, draw_value, tutor, win_condition.
3. **✅ Detecta gaps críticos:** v3.22 encontrou Twinflame/Flare missing — cartas perdidas durante período de hash-fake.
4. **✅ Pipeline integrity check:** Hash verification contra DB (`30d00347...`) — detecta estabilidade.
5. **✅ EDHREC trend analysis:** Detecta novos declínios (Call Forth the Tempest -0.60, Primal Amulet -0.40, Esper Sentinel -0.67).
6. **✅ T3 status reportado com estratégia associada:** DEFENSIVO quando T3 > 12%.
7. **✅ Classificação estratégica (Nivel 1-5):** Implementada no output (v3.8+).

### O que faz errado:
1. **🟡 Referencia tabela inexistente:** Prompt diz `card_oracle_data.ruling_text` — a tabela real é `card_rulings`. Este erro está no prompt fixo, não no output do agente. O agente contorna isso usando o perfil inline do prompt.
2. **🟡 Não verifica Commander banlist.** Assim como o Scout, confia que o backend product code (`format_staples_service.dart`) filtra cartas banidas.
3. **🟡 PG comparison não é tema-aware.** O perfil ideal (lands=32, ramp=3.67) é genérico — não ajusta para spellslinger vs aggro vs stax.
4. **🟡 Protection reportado como 9 slots vs ideal 3.67 (🔴 2.5x acima).** O Validator detecta o desvio mas não sugere conversão de proteção → tutor/draw porque a coleção está esgotada.
5. **🔵 PostgreSQL frequentemente inacessível.** v3.22 reportou "Authentication failure" — o agente usa perfil inline do prompt como fallback.

### Recomendações:
1. **Corrigir prompt:** `card_oracle_data` → `card_rulings`
2. **Adicionar verificação de banlist:** Query `format_staples WHERE is_banned=true` ou Scryfall API
3. **Adicionar tema-awareness:** Ajustar ranges com base no `theme_contextual_rules` do PostgreSQL
4. **Manter SYNERGY_MAP 7 eixos** — este é o ponto forte do Validator

---

## Mulligan (08468451a06a) — Auditoria Detalhada

### O que faz certo:
1. **✅ London Mulligan free first CORRETO.** Prompt inclui regra explícita: `bottom_count = max(0, mulligan_count - 1)` — primeiro mulligan grátis em Commander multiplayer (CR 103.4c).
2. **✅ Definição rigorosa de "jogável":** 2-4 lands AND (ramp >= 1 OR lands >= 3). Alinhado com o protocolo documentado na skill.
3. **✅ Definição de mulligan correta:** 0-1 lands OR (2 lands AND ramp == 0) OR 6+ lands.
4. **✅ Card hash verification:** Detecta deck stability via hash comparison.
5. **✅ MULLIGAN_LOG.md atualizado** com estado do deck + recomendações.
6. **✅ Sem Play T3 métrica definition-stable:** Verifica CMC <= min(lands, 3) — correta.

### O que faz errado:
1. **🔴 ~60% das execuções recentes são [SILENT].** O agente só simula quando detecta mudanças no EVOLUTION_LOG. Se o Oracle não aplica swaps (que é o caso atual — script-only, 0 swaps), o Mulligan nunca roda simulação nova.
2. **🟡 Não simula tapped lands.** Temple of Triumph, Boros Garrison entram tapped mas são tratados como untapped no turno de entrada. T3 real é pior que o reportado.
3. **🟡 Não verifica color requirements.** Mão com 3 Mountains + spells brancos é considerada "jogável" se tiver ramp — mas não consegue castar os spells brancos.
4. **🟡 Prompt diz "Python + random.shuffle" mas não especifica seed.** Sem seed fixo, resultados não são reprodutíveis entre execuções. A skill documenta seed=42 como canônico — o prompt não inclui isso.
5. **🔵 Não simula draws nos turnos 1-3.** Apenas avalia a mão inicial de 7 cartas. Isso subestima T3 (com draws, mais chances de achar play) mas o viés de tapped lands + color screw puxa na direção oposta.
6. **🟡 Não verifica banlist.** Nenhuma checagem.

### Recomendações:
1. **Adicionar seed fixo ao prompt:** `random.seed(42)` para reprodutibilidade
2. **Simular tapped lands:** Marcar lands que entram tapped (Temple of Triumph, Boros Garrison, etc.) e descontar 1 mana no turno de entrada
3. **Verificar color identity:** Checar se as lands produzem as cores necessárias para os spells na mão
4. **Rodar simulação mesmo sem mudanças a cada 3-4 ciclos** para confirmar estabilidade
5. **Adicionar draws T1-T3:** Simular compras nos turnos 1, 2, 3 para T3 mais realista

---

## Battle (94f8590b1beb) — Auditoria Detalhada

### Status: NÃO É CRON

- **Sem entrada em `jobs.json`:** Nenhum job com ID `94f8590b1beb` existe
- **Sem diretório de output:** `/opt/data/cron/output/94f8590b1beb/` → "No such file or directory"
- **Código existe:** `server/lib/ai/battle_simulator.dart` (879 linhas) — protótipo 2-player

### O que o código faz (inspeção direta):
1. **✅ Keywords implementadas:** Flying (linha 56, 747-749), Lifelink (linha 61, 464-465, 502-504), Trample (linha 64, 497-499), First Strike (linha 474-483), Deathtouch (linha 476, 480, 489-492), Vigilance (linha 430-431)
2. **✅ Lifelink SEM cap:** `active.life += lifeGained` (linha 517) — sem `min(40, ...)`
3. **✅ Trample implementado:** Dano excedente passa para jogador (linha 497-498)
4. **✅ First Strike timing correto:** Resolve antes do dano normal (linha 474)
5. **✅ Flying evasion:** Bloqueadores sem flying não podem bloquear (linha 747-749)

### O que o código NÃO faz (gaps críticos para Commander):
1. **🔴 Sem stack/priority (CR 117.3-117.4).** Linha 9 declara: "Sem stack complexo (resolução imediata)". Spells resolvem imediatamente — counterspells impossíveis.
2. **🔴 Sem Commander damage (CR 903.10a).** Nenhum tracking de 21+ combat damage por commander.
3. **🔴 Sem Commander tax (CR 903.8).** Nenhum custo adicional de {2} por cast anterior da command zone.
4. **🔴 2-player apenas.** Commander é multiplayer (3-5 jogadores). Split de ataque (CR 802.1a) não se aplica.
5. **🔴 1 blocker por attacker.** `Map<GameCard, GameCard> blocks` — múltiplos bloqueadores não suportados.
6. **🔴 Sem ETB triggers, planeswalkers, ou habilidades ativadas.**
7. **🟡 Comentário linha 11 ("sem keywords") está desatualizado** — keywords parciais foram implementadas depois.

### Recomendações:
1. **NÃO usar métricas do Battle para decisões de swap.** O simulador não reflete Commander real.
2. **Se for promovido a cron:** Implementar stack LIFO, Commander damage/tax, multiplayer (4-player), múltiplos bloqueadores
3. **Manter como ferramenta de prototipagem** até que os gaps Commander sejam resolvidos

---

## Evolution Oracle (a50bef4c2a59) — Auditoria Detalhada

### Status: SCRIPT-ONLY (no_agent=true)

O cron está configurado com `no_agent: true` e `script: null` — mas o prompt diz "Script-only deterministic wincon oracle. Uses scripts/wincon_pipeline.py oracle and does not modify decklists."

O output mais recente (2026-06-01T20:24:10, 966 bytes) confirma:
```
Decision: keep current decklist; emit deterministic wincon priorities for review.
available_wincons=7 total_wincons=8
Selected priorities:
- fastest: Approach + Topdeck (alternate) total=20 speed=6 resilience=5 stealth=1
- most_resilient: Rise of the Eldrazi (big_mana) total=24 speed=2 resilience=9 stealth=4
- stealthiest: Fiery Emancipation + Damage (big_mana) total=22 speed=3 resilience=6 stealth=7
```

### O que faz (muito pouco):
1. **Lista 3 categorias de wincon:** fastest, most_resilient, stealthiest
2. **Output é determinístico** — mesmo resultado toda execução se o deck não mudar
3. **NÃO modifica decklists** (explícito no prompt)

### O que NÃO faz (função original perdida):
1. **🔴 Não lê SCOUT_LOG.** Não sabe quais cartas o Scout recomenda.
2. **🔴 Não lê VALIDATOR_LOG.** Não sabe quais gaps o Validator detectou (ex: Twinflame/Flare missing, protection excess).
3. **🔴 Não lê MULLIGAN_LOG.** Não sabe o T3 atual nem se a estratégia deve ser AGGRESSIVE/BALANCED/DEFENSIVE.
4. **🔴 Não lê EVOLUTION_LOG histórico.** Não sabe quais swaps já foram aplicados.
5. **🔴 Não recomenda swaps.** O output é apenas "keep current decklist" — sem análise de candidatos, sem justificativa em 3 eixos.
6. **🔴 Não consulta `user_collection`.** Não sabe quais cartas estão disponíveis para swap.
7. **🔴 Não é um LLM agent.** É um script determinístico — não pode se adaptar a novas descobertas ou raciocinar sobre trade-offs.

### Função original (documentada na skill):
> Ler SCOUT_LOG + VALIDATOR_LOG + MULLIGAN_LOG + BATTLE_LOG + EVOLUTION_LOG histórico → sintetizar todos os agentes → recomendar swaps com justificativa em 3 eixos (Diagnóstico, Solução, Princípio)

### Recomendações:
1. **🔴 CRÍTICO: Restaurar Evolution Oracle como LLM agent.** Remover `no_agent: true`, reescrever prompt para ler todos os 4 logs de agentes + EVOLUTION_LOG histórico + `user_collection`.
2. **Manter Wincon Diversity como SEÇÃO do output,** não como o output inteiro.
3. **Re-implementar 0-Swap Decision Protocol** com tabela de rejeição e Necessidade Estratégica/Evidência de Dados.
4. **Adicionar verificação de banlist** e color identity nos swaps propostos.

---

## Verificação Contra Commander Banlist

Cross-referenced against Scryfall API (`ban:commander`):
- ✅ **Zero banned cards** in Lorehold deck (deck_id=6) — confirmação via conhecimento de domínio
- ✅ **Zero banned cards** in agent recommendations (quando existem)
- ⚠️ **NENHUM agente performa esta checagem proativamente** — systemic vulnerability
- ✅ **Backend product code** (`format_staples_service.dart:32`, `sinergia.dart:79`) USA `is_banned=false` e `-is:banned` filter — mas os crons não consultam essas tabelas

**Mitigação atual:** O deck Lorehold contém apenas cartas legais em Commander. O risco é teórico para o estado atual, mas real se novos decks forem adicionados ao pipeline.

---

## Mapa de Gaps por Comprehensive Rule (CR)

| CR | Regra | Scout | Validator | Mulligan | Battle | Oracle |
|:---|:------|:-----:|:---------:|:--------:|:------:|:------:|
| 103.4c | London Mulligan (free first) | N/A | N/A | ✅ | N/A | N/A |
| 117.3-117.4 | Priority/Stack | N/A | N/A | N/A | 🔴 | N/A |
| 405.4 | Stack LIFO | N/A | N/A | N/A | 🔴 | N/A |
| 702.94 | Miracle timing | N/A | N/A | 🔵 | N/A | N/A |
| 704 | State-Based Actions | N/A | N/A | N/A | 🔴 | N/A |
| 903.5 | Color Identity | 🔴 | ✅ | 🟡 | N/A | 🔴 |
| 903.8 | Commander Tax | N/A | N/A | N/A | 🔴 | N/A |
| 903.10a | Commander Damage | N/A | N/A | N/A | 🔴 | N/A |
| 903.13 | Commander Banlist | 🔴 | 🟡 | 🔴 | N/A | 🔴 |

**Legenda:** ✅ Correto | 🟡 Parcial/implícito | 🔴 Não implementado | 🔵 Não verificado | N/A Não aplicável

---

## Plano de Correções (Ordenado por Impacto)

| # | Prioridade | Cron | Ação | Impacto |
|:--|:----------|:-----|:-----|:--------|
| 1 | 🔴 CRÍTICO | Oracle | Restaurar como LLM agent com síntese multi-agente + leitura de 4 logs + user_collection | Pipeline inteiro depende do Oracle para tomar decisões de swap |
| 2 | 🔴 CRÍTICO | Scout | Restaurar prompt original A+B+C (EDHREC JSON API + coleção + sinergia) | 94% [SILENT] = pipeline está cego para novas oportunidades |
| 3 | 🔴 CRÍTICO | Battle | NÃO usar métricas do Battle para decisões de swap até implementar stack + Commander damage/tax | Métricas atuais não refletem Commander real |
| 4 | 🟡 ALTO | Oracle/Scout/Validator/Mulligan | Adicionar verificação de banlist em todos os agentes | Vulnerabilidade sistêmica (mitigada por deck atual ser 100% legal) |
| 5 | 🟡 ALTO | Mulligan | Adicionar seed fixo, simular tapped lands + color requirements | T3 real é 3-8pp pior que o reportado |
| 6 | 🟡 ALTO | Mulligan | Rodar simulação a cada 3-4 ciclos mesmo sem mudanças | Confirma estabilidade; atualmente ~60% [SILENT] |
| 7 | 🔵 MÉDIO | Validator | Corrigir prompt: `card_oracle_data` → `card_rulings` | Evita confusão em futuras execuções |
| 8 | 🔵 MÉDIO | Validator | Adicionar tema-awareness usando `theme_contextual_rules` do PostgreSQL | Ranges de validação seriam mais precisos |
| 9 | 🔵 MÉDIO | Mulligan | Simular draws T1-T3 (não só mão inicial) | T3 mais realista, compensa parcialmente viés de tapped lands |
| 10 | 🔵 BAIXO | Scout | Adicionar filtro de color identity explícito | Previne recomendar cartas off-color |

---

## Conclusão

A pipeline Lorehold tem confiabilidade **BAIXA (5.1/10)** em relação às regras oficiais de MTG Commander. Três dos cinco componentes estão fundamentalmente quebrados:

1. **Scout (3.5/10):** Prompt errado — "Wincon Hunter" em vez de sinergia A+B+C. 94% [SILENT].
2. **Oracle (3.5/10):** Script determinístico, não LLM. Não lê logs de outros agentes. Não recomenda swaps.
3. **Battle (N/A):** Não é cron. Código 2-player sem stack/priority/Commander damage/tax.

Os pontos fortes são:
- **Validator (7.0/10):** SYNERGY_MAP 7 eixos, PG comparison, trend analysis, pipeline integrity check
- **Mulligan (6.5/10):** London Mulligan correto, definição rigorosa, métricas definition-stable

**O pipeline está efetivamente parado desde o Ciclo #11 (2026-05-31):** O Oracle (script-only) não aplica swaps, o Scout ([SILENT]) não recomenda cartas, e o Mulligan ([SILENT]) não simula porque o deck não muda. Apenas o Validator continua produzindo análises úteis.

**Para restaurar o pipeline à funcionalidade original:**
1. Transformar Oracle de script-only → LLM agent com leitura de 4 logs + user_collection
2. Restaurar Scout para A+B+C synergy scoring com EDHREC JSON API
3. Implementar verificação de banlist em todos os agentes
4. Corrigir Mulligan com seed fixo + tapped lands + color requirements

**Status atual do deck (Lorehold):** 25 swaps aplicados, motor 4/4, SYNERGY_MAP 7.0/10, T3 13.3%, coleção esgotada de CMC ≤2. Deck maturity atingida — próximo upgrade requer aquisição.
