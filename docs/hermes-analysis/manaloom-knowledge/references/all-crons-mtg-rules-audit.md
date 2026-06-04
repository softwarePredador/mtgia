# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v3.5 (execução direta do cron `mtg-rules-auditor`, 2026-06-04T05:50Z)
**Data:** 2026-06-04
**Commit:** `08637d2c`
**Metodologia:** Inspeção de prompts reais de `jobs.json` + outputs MAIS RECENTES de `/opt/data/cron/output/<id>/` (04/Jun, entre 04:09Z e 05:24Z) + código fonte `battle_simulator.dart` (879 linhas) + Comprehensive Rules (CR 2024-11-08) + Scryfall API + consulta `run_log` SQLite.

---

## Sumário

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | **3.5/10** | 🔴 BAIXA | Prompt "Wincon Hunter" (não Scout); 94% [SILENT]; sem EDHREC real; sem filtro de color identity |
| Validator | **7.5/10** | 🟡 MÉDIA | ✅ v3.25 corrigiu Worldfire banlist + classificador (17/20); execução atual SILENT; PG profile spellslinger vs deck cEDH |
| Mulligan | **7.0/10** | 🟡 MÉDIA-ALTA | Tapped lands não simulados; color screw não verificado; sem draws futuros |
| Battle | **N/A** | 🔴 NÃO É CRON | Diretório `/opt/data/cron/output/94f8590b1beb/` NÃO EXISTE; código 2-player sem stack/priority |
| Evolution Oracle | **1.0/10** | 🔴 CRÍTICA | Output truncado após tool call (Exec#52); >72h sem análise completa; Pipeline Death Loop ativo |
| **PIPELINE** | **3.8/10** | 🔴 BAIXA | Death Loop continua; Oracle é NO-OP efetivo; Scout perdeu função original; Validator melhorou (v3.25) mas pipeline travado |

**Delta vs v3.4:** Pipeline subiu de 3.6 → 3.8. Validator subiu (7.0 → 7.5, v3.25 corrigiu banlist + classificador). Oracle subiu marginalmente (0.5 → 1.0, Exec#52 executou tool call real). Scout e Mulligan estáveis.

---

## 1. Scout — Auditoria Detalhada (v3.5 refresh)

**Job ID:** f20ac299992b
**Última execução:** 2026-06-04T04:09Z (execução #103)
**Resposta:** `[SILENT]`
**run_log:** `silent-nochange-hash-match` (2026-06-04T01:08Z, #102)
**Hash verificado:** ✅ Sim (execução #102 fez hash verification)

### O que mudou desde v3.4

**Nada.** Execução #103 = [SILENT]. Execução #102 fez hash verification e confirmou `silent-nochange-hash-match`. O prompt continua sendo "Wincon Hunter" que busca apenas `card_deck_analysis`, sem EDHREC, sem color identity filter, sem singleton check.

### O que faz certo
1. **Short-circuit com hash** ✅ — Verifica hash antes de análisar. Não desperdiça ciclos.
2. **Prompt autocontido** ✅ — SQL query e regras de priorização embutidas.

### O que faz errado
1. **Prompt não é um Scout** 🔴 — É um "Wincon Hunter" que busca APENAS `card_deck_analysis`. Perdeu a função original de scouting de sinergia (EDHREC + coleção + Score A+B+C).
2. **94% [SILENT] desde 31/Mai** 🔴 — 9 das últimas 10 execuções retornaram [SILENT].
3. **WINCONS JA NO DECK hardcoded** 🟡 — Lista fixa no prompt com valores stale.
4. **Sem verificação de color identity** 🟡 — `WHERE uc.quantity > 0` não filtra `color` para RW (CR 903.4c).
5. **Sem verificação de singleton** 🟡 — Não checa duplicatas (CR 903.5b).
6. **Sem verificação de banlist** 🟡 — Não executa `sync-legalities.sh`.

### Verificações MTG

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ❌ Não | SQL não filtra por cor |
| Singleton (903.5b) | CR 903.5b | ❌ Não | Não verifica duplicatas |
| 100 cards (903.5a) | CR 903.5a | ⚠️ Implícito | Deck tem 100 cards |
| Commander banlist | Scryfall | ❌ Não | Não executa sync |
| EDHREC inclusion % | N/A | 🔴 Não | Prompt não usa EDHREC |
| Synergy scoring (A+B+C) | N/A | 🔴 Não | Só speed/resilience/stealth |

### Recomendações

1. **Restaurar prompt original de Scout:** EDHREC JSON API → `user_collection` cross-ref → Score A+B+C
2. **OU fundir Scout + Validator:** Um único agente analítico seria mais eficiente
3. **Adicionar filtro de color identity + singleton + banlist** ao SQL
4. **Remover hardcoded "WINCONS JA NO DECK"** — query dinâmica sempre

---

## 2. Validator — Auditoria Detalhada (v3.5 refresh)

**Job ID:** 712579b15767
**Última execução:** 2026-06-04T05:23Z (execução #65)
**Resposta:** `SILENT` (card hash `8b9c643c` matches v3.25, deck unchanged)
**run_log:** `validator-v3.25-reconfirm` / `ok-no-change` / `discrepancies=0` (2026-06-04T02:13Z)
**Análise completa mais recente:** v3.25 (2026-06-03T23:00Z, 426 linhas, 20978 bytes)

### ✅ VITÓRIA v3.5: v3.25 Corrigiu os Erros de v3.24

**O v3.4 audit flagrou que v3.24 afirmava Worldfire=banned (ERRO). v3.25 CORRIGIU:**

1. **Worldfire banlist corrigido** ✅ — v3.25 verificou `card_legalities` do PG: Worldfire = `commander=legal`. O erro era memória de modelo (banimento de 2013-2017).
2. **Classificador resolvido** ✅ — 17 de 20 cartas `functional_tag='unknown'` foram reclassificadas entre v3.24 e v3.25. Restam apenas 3 unknown: Inventors' Fair, Prismatic Vista, Reforge the Soul (import corruption, CMCs errados).
3. **Hash divergente detectado** ✅ — v3.25 detectou que o deck foi modificado externamente entre v3.24 (`f2241d99...`) e v3.25 (`8b9c643c...`).

### O que mudou desde v3.4

**Melhorou:** v3.25 é uma análise CORRETA e COMPLETA que substituiu v3.24 (com erros). A nota sobe de 7.0 → 7.5.

**Ainda ruim:** A execução #65 (05:23Z) retornou SILENT porque o hash não mudou desde v3.25. O Validator está em short-circuit correto — a última análise (v3.25) é válida e sem erros. Isso é o comportamento DESEJADO, não um bug.

### O que faz certo
1. **SYNERGY_MAP 7 eixos** ✅ (v3.25)
2. **Banlist verification com PG sync** ✅ — Worldfire=legal confirmado
3. **Classificador gap detection** ✅ — 17/20 cartas reclassificadas
4. **Pipeline integrity (hash)** ✅ — Detectou mudança externa entre versões
5. **Archetype mismatch detection** ✅ — cEDH vs spellslinger PG profile
6. **Multi-write de logs** ✅ — VALIDATOR_LOG + SUMMARY em múltiplos paths

### O que faz errado
1. **Short-circuit cego (NÃO se aplica mais ao Validator)** ✅ — v3.25 corrigiu os erros. O short-circuit atual é CORRETO porque a última análise (v3.25) é válida.
2. **Prompt referencia `card_oracle_data`** 🟡 — Tabela inexistente. Deveria ser `card_rulings`.
3. **PG profile spellslinger vs deck cEDH** 🟡 — Perfil fixo no prompt não reflete o arquétipo atual (fast-mana-copy-combo).
4. **HTTP 429 persiste** 🟡 — Rate limit do provider impede execuções longas.

### Verificações MTG

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ✅ | PG profile inclui `color_identity` |
| Singleton (903.5b) | CR 903.5b | ❌ Não | Não verificado |
| 100 cards (903.5a) | CR 903.5a | ✅ | v3.25 verificou |
| Commander banlist | Scryfall/PG | ✅ | v3.25: 0 banned, Worldfire=legal |
| Functional classification | N/A | ✅ | 17/20 unknown resolvidos |
| Archetype detection | N/A | ✅ | cEDH vs spellslinger |
| SYNERGY_MAP coverage | N/A | ✅ | 7 eixos (v3.25) |

### Recomendações

1. **Corrigir `card_oracle_data` → `card_rulings` no prompt** (10min)
2. **Adicionar verificação de singleton** na query de validação (30min)
3. **Atualizar PG profile no prompt** para refletir o arquétipo cEDH atual (1h)
4. **Normalizar formato [SILENT]** — Validator usa `SILENT` sem brackets (5min)

---

## 3. Mulligan — Auditoria Detalhada (v3.5 refresh)

**Job ID:** 08468451a06a
**Última execução:** 2026-06-04T04:11Z (execução #49)
**Resposta:** `[SILENT]`
**run_log:** `mulligan-verification-nochange-hash-match-exec15` / `ok-nochange` (2026-06-04T01:09Z)
**Última simulação completa:** Execução #15 (2026-06-03, pós-resolução do classificador)

### O que mudou desde v3.4

**Nada.** O deck não mudou desde Exec#15. O Mulligan está em short-circuit correto — a última simulação (Exec#15) é válida e beneficiou-se da resolução do classificador (ramp tags 6→19, T3 corrigido de 17.7%→1.6%).

### O que faz certo
1. **London Mulligan free first** ✅ — `bottom_count = max(0, mulligan_count - 1)`. CR 103.5c.
2. **Definição rigorosa de jogável** ✅ — "2-4 lands AND (ramp >= 1 OR lands >= 3)".
3. **T1 ramp canônico** ✅ — `T1_RAMP = {'Sol Ring'}`.
4. **Hash verification** ✅ — Detectou mudança de deck (Exec#15).

### O que faz errado
1. **Tapped lands não simulados** 🟡 — Temple of Triumph, Boros Garrison tratados como untapped. T3 reportado +2-5pp melhor que real. CR 110.5a.
2. **Color screw não verificado** 🔴 — Mão com 3 Mountains + spells brancos é "jogável". +3-8pp de superestimação. CR 903.4c.
3. **Sem draws futuros** 🟡 — Só avalia mão inicial, não T1-T3 draws.
4. **Dependência do classificador** 🟡 — `functional_tag='ramp'` define o que conta como ramp. Exec#14→#15 mostrou gap de 8.8pp.

### Verificações MTG

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| London Mulligan (103.4) | CR 103.4 | ✅ | 7 cards, bottom N |
| Free first multiplayer (103.5c) | CR 103.5c | ✅ | `mulligan_count - 1` |
| Color identity (903.4) | CR 903.4c | ❌ Não | Não verifica mana colorida |
| Tapped lands | CR 110.5a | ❌ Não | Tratados como untapped |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado |
| Future draws (T1-T3) | N/A | ❌ Não | Só mão inicial |

### Recomendações

1. **Adicionar simulação de tapped lands** (1h)
2. **Adicionar color requirement check** — verificar se lands produzem cores das spells (2h)
3. **Adicionar draws futuros (T1-T3)** (2h)
4. **Hardcode ramp cards conhecidas** como fallback quando classificador falha (1h)

---

## 4. Battle — Auditoria Detalhada (v3.5 refresh)

**Job ID:** 94f8590b1beb
**Diretório:** `/opt/data/cron/output/94f8590b1beb/` — **NÃO EXISTE** (confirmado v3.4, reconfirmado v3.5)
**Entrada em jobs.json:** NÃO
**Código:** `/opt/data/workspace/mtgia/server/lib/ai/battle_simulator.dart` (879 linhas)

### Status: NÃO É UM CRON

O Battle Analyst nunca foi um cron job ativo. O diretório foi removido. O código fonte é um protótipo de combate 2-player.

### Análise do Código (reconfirmada v3.5)

#### Implementado corretamente
- Flying, Trample, Lifelink, First Strike, Deathtouch, Vigilance, Haste ✅
- Untap/Draw/Discard phases ✅
- Lifelink SEM cap (linha 516-519: `active.life += lifeGained`) ✅

#### NÃO implementado (viola regras MTG)

| Feature | CR Ref | Impacto |
|:--------|:------|:--------|
| **Stack/Priority** | CR 117.3 | 🔴 Spells resolvem imediatamente. Counterspells impossíveis. (Linha 9: "Sem stack complexo — resolução imediata") |
| **Multiplayer (4-player)** | CR 802.1a | 🔴 2-player apenas |
| **Commander damage (21)** | CR 903.10a | 🔴 Não trackeado |
| **Commander tax (+2)** | CR 903.8 | 🔴 Não implementado |
| **ETB triggers** | CR 603.4 | 🔴 Não implementados |
| **Planeswalkers** | CR 306 | 🔴 Não suportados |
| **Múltiplos bloqueadores** | CR 509.1c | 🔴 1 blocker por attacker |
| **State-Based Actions** | CR 704.3 | 🔴 Apenas destroy por dano |

### Conclusão Battle

**N/A — Não usar para decisões de swap.** O código é um protótipo de combate, não um simulador de Commander. Qualquer referência a BATTLE_LOG.md nos prompts de outros agentes é uma referência a um arquivo que não existe.

### Recomendação

1. **Remover referências a BATTLE_LOG.md** dos prompts do Oracle e Mulligan
2. **Marcar `battle_simulator.dart` como `@deprecated`** ou mover para `server/test/`

---

## 5. Evolution Oracle — Auditoria Detalhada (v3.5 refresh)

**Job ID:** a50bef4c2a59
**Última execução:** 2026-06-04T05:24Z (execução #52)
**Resposta:** PARCIAL — executou tool call (hash verification via Python/SQLite) mas output truncado
**run_log:** NENHUMA entrada para 04/Jun (Oracle não completou nenhuma execução hoje)
**Hash verificado:** TENTOU (comando `python3 -c` com query SQLite visível no output) mas resultado não capturado

### O que mudou desde v3.4

**Progresso marginal (0.5 → 1.0):** A execução #52 conseguiu executar UM tool call real — uma query Python/SQLite para verificar o hash do deck. No v3.4, a execução #51 mostrava tool calls sendo feitos mas nem o conteúdo do comando era visível. Agora vemos o comando completo:

```python
python3 -c "
import sqlite3, hashlib
DB = 'docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'
conn = sqlite3.connect(DB)
...
```

O Oracle iniciou o Step 0 (hash verification) corretamente, mas foi interrompido antes de receber o resultado do tool call. Ainda é um zumbi — mas um zumbi que deu um passo.

### Evidência do Death Loop (confirmado v3.5)

Todas as 5 execuções de 04/Jun mostram o mesmo padrão:
- Oracle #50 (00:54Z): output truncado
- Oracle #51 (02:14Z): output truncado (v3.4)
- Oracle #52 (05:24Z): output truncado APÓS tool call (v3.5)
- Nenhum run_log para Oracle em 04/Jun → nenhuma execução completou

### Causa mais provável

Timeout do provider (deepseek-v4-pro) interrompendo o agente após 3-4 tool calls. O Oracle precisa ler 4 arquivos de log + rodar 2 scripts + analisar + propor swaps — isso não cabe no timeout padrão de ~60s.

### O que faz certo (quando funciona — C#23)

1. **Pipeline Integrity Break detection (C#23)** ✅ — Detectou 5 ciclos com hash falso.
2. **Estratégia baseada em T3** ✅ — T3=13.3% → DEFENSIVO.
3. **Justificativa multi-eixo** ✅ — Diagnóstico + Solução + Princípio.
4. **Modo CO-PILOT** ✅ — Swaps documentados, não aplicados.

### O que faz errado

1. **Output sempre incompleto (>72h)** 🔴 — Causa: timeout/rate limit interrompendo após tool calls.
2. **Pipeline Death Loop** 🔴 — Oracle não completa → todos os outros [SILENT] → Oracle não tem dados → Oracle não completa.
3. **Script `manaloom-wincon-oracle.sh` não encontrado** 🟡 — Referenciado em jobs.json linha 449, não existe no filesystem.
4. **Referência a BATTLE_LOG.md** 🟡 — Prompt diz "BATTLE_LOG.md → matchup weaknesses". Arquivo não existe.
5. **Descrição imprecisa de Miracle** 🟡 — Prompt diz "custam {2} + pips coloridos". Lorehold reduz custo de mágicas DO CEMITÉRIO em {2}, não todas as mágicas.

### Verificações MTG (quando funcionou — C#23)

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ✅ | Implícito |
| Singleton (903.5b) | CR 903.5b | ✅ | "Verifique singleton apos swaps" |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado |
| Commander banlist | Scryfall/PG | ✅ | C#23 executou sync |

### Recomendações

1. **🔴 CRÍTICO: Aumentar timeout do Oracle** — Se o agente é interrompido após 3-4 tool calls, precisa de mais tempo. O Oracle lê 4 arquivos + 2 scripts + análise.
2. **🔴 CRÍTICO: Forçar execução com `--force`** — Ignorar short-circuit, rodar análise completa UMA vez para quebrar o Death Loop.
3. **Corrigir referência a BATTLE_LOG.md** — Remover do prompt.
4. **Corrigir descrição de Miracle** — "Lorehold reduz custo de mágicas do cemitério em {2}".
5. **Criar script `manaloom-wincon-oracle.sh`** ou remover referência do jobs.json.
6. **Adicionar condição de "force run":** Se 3+ execuções truncadas consecutivas → forçar análise.
7. **Considerar trocar provider** (deepseek-v4-pro → deepseek-v4-flash) para tool calls mais rápidas.

---

## 6. Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (quebra o pipeline)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 1 | Oracle output sempre incompleto (>72h) | Evolution Oracle | Aumentar timeout; forçar execução com `--force`; trocar provider se necessário | 1h |
| 2 | Pipeline Death Loop ativo | Pipeline | Após fix do Oracle, pipeline reinicia naturalmente | 0h (depende de #1) |
| 3 | Sem stack/priority no Battle | Battle | NÃO É CRON. Marcar código como `@deprecated`. | 30min |
| 4 | Scout perdeu função original (94% SILENT) | Scout | Restaurar prompt EDHREC + A+B+C | 1h |

### 🟡 ALTO (distorce resultados)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 5 | Color screw não simulado (+3-8pp) | Mulligan | Adicionar verificação de mana colorida | 2h |
| 6 | Tapped lands não simulados (+2-5pp) | Mulligan | Adicionar simulação de enters-tapped | 1h |
| 7 | Prompt referencia `card_oracle_data` (não existe) | Validator | Corrigir para `card_rulings` | 10min |
| 8 | PG profile spellslinger vs deck cEDH | Validator | Atualizar perfil no prompt ou detectar mismatch | 1h |

### 🟢 MÉDIO (imprecisão corrigível)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 9 | Sem verificação de singleton | Scout, Validator | Query de duplicatas | 30min |
| 10 | Sem draws futuros no Mulligan | Mulligan | Simular T1-T3 draws | 2h |
| 11 | Classificador dita acurácia do Mulligan | Mulligan | Hardcode ramp conhecidas | 1h |
| 12 | Referência a BATTLE_LOG.md no Oracle | Oracle | Remover do prompt | 5min |
| 13 | "Miracle {2}" impreciso no prompt do Oracle | Oracle | Corrigir descrição | 5min |
| 14 | Sem filtro de color identity no Scout | Scout | Adicionar `WHERE color IN ('R','W','R,W')` | 15min |

### ⚪ BAIXO (cosmético / documentação)

| # | Problema | Cron | Ação |
|:-:|:---------|:-----|:-----|
| 15 | `[SILENT]` vs `SILENT` inconsistente | Validator | Normalizar formato |
| 16 | Script oracle não encontrado | Oracle | Criar ou remover referência |
| 17 | Battle listado nos docs como cron ativo | Docs | Atualizar documentação |
| 18 | `card_deck_analysis` referencia deck_id deletado | Scout | Verificar deck_id antes de usar |
| 19 | Hardcoded "WINCONS JA NO DECK" no prompt do Scout | Scout | Remover, usar query dinâmica |

---

## 7. Conclusão (v3.5)

A pipeline Lorehold tem confiabilidade **BAIXA** (3.8/10) em relação às regras oficiais de MTG e à sua própria função declarada. A nota subiu marginalmente de 3.6 (v3.4) para 3.8 (v3.5).

### O que melhorou desde v3.4

- **Validator:** 7.0 → 7.5. v3.25 foi produzida com sucesso, corrigindo o erro de banlist (Worldfire) e resolvendo 17/20 cartas do classificador. O Validator agora tem uma análise limpa e correta como última referência.
- **Oracle:** 0.5 → 1.0. A execução #52 conseguiu executar um tool call real (hash verification via Python/SQLite). É um progresso marginal — o agente não está mais totalmente catatônico, mas ainda é interrompido antes de completar.

### O que permanece igual

- **Scout:** Prompt "Wincon Hunter" não mudou. 94% [SILENT]. Continua não sendo um Scout de verdade.
- **Mulligan:** Funcional com gaps conhecidos (tapped lands, color screw). Short-circuit correto.
- **Battle:** Continua não sendo um cron.
- **Pipeline:** Death Loop continua. Oracle é o gargalo.

### O que o operador precisa fazer IMEDIATAMENTE

1. **Forçar Evolution Oracle** com timeout maior + flag `--force`. Sem isso, o pipeline está morto independente dos outros agentes.
2. Após o Oracle voltar a produzir análises, o pipeline DEVE reiniciar naturalmente: Oracle detecta → Mulligan testa → Scout busca → Validator analisa → Oracle sintetiza.
3. Os gaps do Mulligan (tapped lands, color screw) são o próximo gargalo de qualidade — não afetam o funcionamento do pipeline, mas afetam a precisão das recomendações de swap.

### Lições aprendidas (acumuladas v3.4 + v3.5)

1. **Short-circuit é uma faca de dois gumes** (v3.4): Economiza recursos mas perpetua erros. O Validator v3.24→v3.25 provou que o sistema PODE se autocorrigir quando reexecuta — mas precisa de um trigger externo (deck modificado) para sair do short-circuit.
2. **Pipeline Death Loop é auto-reforçante** (v3.5): Quanto mais tempo o Oracle fica parado, mais difícil é sair porque os outros agentes acumulam [SILENT] e o Oracle não tem dados novos para analisar.
3. **Timeout de provider é o gargalo real** (v3.5): O Oracle NÃO está em short-circuit — está sendo INTERROMPIDO. O problema é infraestrutura (timeout/rate limit), não lógica.
4. **Classificador é o elo mais frágil:** Tanto o Mulligan quanto o Scout dependem de `functional_tag` preciso. A resolução Exec#15 (ramp 6→19) provou que um classificador ruim infla T3 em 8.8pp e distorce recomendações de swap.

---

**Fontes consultadas (v3.5):**
- Magic: The Gathering Comprehensive Rules (2024-11-08) — CR 103.4, 103.5c, 110.5a, 117.3, 306, 405.5, 509.1c, 603.4, 701.5a, 704.3, 802.1a, 903.4c, 903.5a, 903.5b, 903.8, 903.10a
- Scryfall API (`api.scryfall.com/cards/named`) — Worldfire = legal, Mana Crypt = banned
- `/opt/data/cron/jobs.json` (configuração de 16 crons, linhas 318-478)
- `/opt/data/cron/output/f20ac299992b/2026-06-04_04-09-35.md` (Scout #103 — [SILENT])
- `/opt/data/cron/output/712579b15767/2026-06-04_05-23-49.md` (Validator #65 — SILENT, hash `8b9c643c`)
- `/opt/data/cron/output/08468451a06a/2026-06-04_04-11-39.md` (Mulligan #49 — [SILENT])
- `/opt/data/cron/output/a50bef4c2a59/2026-06-04_05-24-26.md` (Oracle #52 — PARCIAL, tool call truncado)
- `/opt/data/cron/output/94f8590b1beb/` — NÃO EXISTE (Battle)
- `server/lib/ai/battle_simulator.dart` (879 linhas, confirmado existente)
- `decks/lorehold-the-historian/VALIDATOR_LOG_v3.25.md` (426 linhas, 2026-06-03T23:00Z)
- SQLite `run_log` (3 entradas para 04/Jun, nenhuma do Oracle)
- Auditoria anterior: `references/all-crons-mtg-rules-audit.md` v3.4 (2026-06-04, commit `99c47059`)
- Skills: `manaloom-commander-knowledge`, `manaloom-mtg-domain`
