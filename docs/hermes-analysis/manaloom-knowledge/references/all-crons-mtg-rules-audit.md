# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v3.4 (execução direta do cron `mtg-rules-auditor`, 2026-06-04T02:XXZ)
**Data:** 2026-06-04
**Commit:** `99c47059`
**Metodologia:** Inspeção de prompts reais de `jobs.json` + outputs MAIS RECENTES de `/opt/data/cron/output/<id>/` (04/Jun, todos após 01:08Z) + código fonte `battle_simulator.dart` (879 linhas) + Comprehensive Rules (CR 2024-11-08) + Scryfall API. Esta é a execução real do cron `mtg-rules-auditor`, NÃO uma re-análise indireta de relatórios anteriores.

---

## Sumário

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | **3.5/10** | 🔴 BAIXA | Prompt desalinhado ("Wincon Hunter", não Scout); 94% [SILENT]; recomendações sem EDHREC real; execução atual [SILENT] |
| Validator | **7.0/10** | 🟡 MÉDIA | Banlist Blindness corrigido (sync PG→SQLite); execução atual SILENT (sem brackets); PG profile fixo vs deck cEDH; HTTP 429 persiste; `card_oracle_data` no prompt |
| Mulligan | **7.0/10** | 🟡 MÉDIA-ALTA | Tapped lands não simulados; color screw não verificado; sem draws futuros; execução atual [SILENT]; depende do classificador para ramp |
| Battle | **N/A** | 🔴 NÃO É CRON | Diretório `/opt/data/cron/output/94f8590b1beb/` **NÃO EXISTE** (v3.4: removido, v3.3: existia vazio); sem entrada em `jobs.json`; código 2-player sem stack/priority |
| Evolution Oracle | **0.5/10** | 🔴 CRÍTICA | Output atual PARCIAL (leu Step 0, travou nos tool calls); última análise completa >72h atrás (C#23, 01/Jun); Script `manaloom-wincon-oracle.sh` não encontrado no filesystem; Pipeline Death Loop |
| **PIPELINE** | **3.6/10** | 🔴 BAIXA | Evolution Oracle é NO-OP efetivo; Scout perdeu função original; Validator parado por rate limit; Pipeline Death Loop confirmado em TODAS as execuções de 04/Jun |

**Delta vs v3.3:** Pipeline caiu de 4.1 → 3.6. Oracle piorou (1.0 → 0.5, output parcial ao invés de [SILENT] completo). Validator caiu (8.0 → 7.0, nova execução mostra SILENT ao invés de análise completa). Scout estável (4.0 → 3.5, perdeu 0.5 por confirmar que execução #40 e #41 são ambas [SILENT]).

---

## 1. Scout — Auditoria Detalhada (v3.4 refresh)

**Job ID:** f20ac299992b
**Última execução:** 2026-06-04T01:08Z (execução #102)
**Resposta:** `[SILENT]`
**Hash verificado:** NÃO (agente não verificou — foi direto para [SILENT])

### O que mudou desde v3.3

**Piorou:**
- **Execução #102 = [SILENT]** — O agente nem tentou verificar o deck. O prompt + skill enorme (1971 linhas) foi carregado mas a resposta foi apenas 3 caracteres: `[SILENT]`. Isso significa que literalmente NADA mudou na perspectiva do agente — nem o deck, nem os dados de `card_deck_analysis`, nem a coleção.

**Igual:**
- Prompt continua sendo "Wincon Hunter" (não Scout de sinergia A+B+C)
- Lista de "WINCONS JA NO DECK" continua stale (Rise of the Eldrazi listado como wincon, mas removido do deck em C#23)
- Sem referência a EDHREC, `user_collection.color`, singleton, ou banlist no prompt

### O que faz certo
1. **Short-circuit funciona** ✅ — Retorna [SILENT] rapidamente quando nada mudou. Não desperdiça ciclos.
2. **Prompt autocontido** ✅ — Tem SQL query e regras de priorização embutidas.

### O que faz errado
1. **Prompt não é um Scout** 🔴 — É um "Wincon Hunter" que busca APENAS `card_deck_analysis`. Perdeu toda a função de scouting de sinergia (EDHREC + coleção + Score A+B+C).
2. **94% [SILENT] desde 31/Mai** 🔴 — Confirmado pela execução #102.
3. **"WINCONS JA NO DECK" hardcoded e stale** 🟡 — Lista fixa no prompt com valores de `deck_id` que pode não existir mais.
4. **Sem verificação de color identity** 🟡 — `WHERE uc.quantity > 0` não filtra `color` para RW.
5. **Sem verificação de singleton** 🟡 — Não checa duplicatas (CR 903.5b).
6. **Sem verificação de banlist** 🟡 — Não executa `sync-legalities.sh`.

### Verificações MTG (atualizado v3.4)

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ❌ Não | SQL não filtra por cor |
| Singleton (903.5b) | CR 903.5b | ❌ Não | Não verifica duplicatas |
| 100 cards (903.5a) | CR 903.5a | ⚠️ Implícito | Deck tem 100 cards |
| Commander banlist | Scryfall | ❌ Não | Não executa sync |
| EDHREC inclusion % | N/A | 🔴 Não | Prompt não usa EDHREC |
| Synergy scoring | N/A | 🔴 Não | Só speed/resilience/stealth, sem A+B+C |

### Recomendações (atualizado v3.4)

1. **Restaurar prompt original de Scout:** EDHREC JSON API → `user_collection` cross-ref → Score A+B+C
2. **OU fundir Scout + Validator:** Como ambos analisam o deck, um único agente analítico (Validator) + um agente de busca (EDHREC/coleção) seria mais eficiente
3. **Adicionar filtro de color identity** + **singleton** + **banlist** ao SQL do prompt
4. **Remover hardcoded "WINCONS JA NO DECK"** — query dinâmica sempre

---

## 2. Validator — Auditoria Detalhada (v3.4 refresh)

**Job ID:** 712579b15767
**Última execução:** 2026-06-04T02:13Z (execução #64)
**Resposta:** `SILENT` (sem brackets — inconsistente com os outros agentes que usam `[SILENT]`)
**Hash verificado:** NÃO

### O que mudou desde v3.3

**Piorou:**
- **Execução #64 = SILENT** — O Validator, que era o agente MAIS CONFIÁVEL (8.0/10 em v3.3), agora também entrou no modo [SILENT]. Isso significa que o deck não mudou desde a última análise (v3.24, 02/Jun), e o Validator entrou em short-circuit.
- O Validator não sabe que sua última análise de sucesso (v3.24) continha um erro grave (afirmou que Worldfire estava banida). Como o deck não mudou, ele nunca vai reexecutar e corrigir esse erro.
- **Nota cai de 8.0 → 7.0** porque o agente está agora parado também.

**Igual:**
- Prompt ainda referencia `card_oracle_data` (tabela inexistente)
- PG profile ainda é fixo (spellslinger) enquanto deck é cEDH combo
- Banlist Blindness foi corrigido via sync PG→SQLite mas o agente não reexecutou desde então

### O que faz certo
1. **SYNERGY_MAP cobre 7 eixos** ✅ — Cobertura estratégica abrangente (v3.24).
2. **Detecção de corrupção de dados** ✅ — v3.24 identificou: 20 cartas `functional_tag='unknown'`, CMC corruption.
3. **Archetype mismatch detection** ✅ — cEDH vs spellslinger.
4. **Multi-write de logs** ✅ — v3.24 escreveu VALIDATOR_LOG + SUMMARY em múltiplos paths.

### O que faz errado
1. **Short-circuit cego** 🔴 — O Validator agora retorna SILENT porque o deck não mudou. Mas sua última análise (v3.24) continha um ERRO FATAL (Worldfire banned). Sem reexecução, esse erro permanece nos logs.
2. **Prompt referencia tabela inexistente** 🟡 — `card_oracle_data` não existe. A tabela correta é `card_rulings`.
3. **PG profile fixo vs deck dinâmico** 🟡 — O prompt lista um perfil spellslinger fixo; o deck atual é cEDH turbo-combo.
4. **HTTP 429 persiste** 🟡 — Rate limit do provider (deepseek-v4-pro) impede execuções longas.
5. **Timestamp de SILENT inconsistente** 🟢 — Usa `SILENT` sem brackets, diferente do padrão `[SILENT]` de outros agentes.

### Verificações MTG (atualizado v3.4)

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ✅ | PG profile inclui `color_identity` |
| Singleton (903.5b) | CR 903.5b | ❌ Não | Não verificado |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado (v3.24) |
| Commander banlist | Scryfall | 🔴 Erro | v3.24: Worldfire marcado como banned (errado!) |
| Functional classification | N/A | ✅ | Detecta unknown tags, CMC corruption |
| Archetype detection | N/A | ✅ | cEDH vs spellslinger |
| SYNERGY_MAP coverage | N/A | ✅ | 7 eixos |

### Recomendações (atualizado v3.4)

1. **Forçar reexecução do Validator** — A análise atual nos logs (v3.24) contém erro de banlist. O short-circuit está perpetuando o erro.
2. **Adicionar "erro conhecido na última execução" como condição de bypass do short-circuit**
3. **Corrigir `card_oracle_data` → `card_rulings` no prompt**
4. **Normalizar formato [SILENT]** — usar `[SILENT]` com brackets em todos os agentes
5. **Adicionar verificação de singleton** na query de validação

---

## 3. Mulligan — Auditoria Detalhada (v3.4 refresh)

**Job ID:** 08468451a06a
**Última execução:** 2026-06-04T01:09Z (execução #48)
**Resposta:** `[SILENT]`
**Hash verificado:** NÃO

### O que mudou desde v3.3

**Igual:**
- Execução #48 = [SILENT] — deck não mudou desde a última simulação (Exec#15, 03/Jun)
- London Mulligan free-first ✅
- Definição rigorosa de jogável ✅
- T1 ramp canônico ✅
- Prompt correto e bem documentado

**Nota caiu de 7.5 → 7.0:** O short-circuit está correto (deck não mudou), mas o agente NÃO deveria confiar que a última simulação é válida se o classificador foi corrigido desde então. A Exec#15 beneficiou-se da correção do classificador (ramp tags 6→19). Se o classificador for alterado novamente, o Mulligan não vai detectar porque está em short-circuit.

### O que faz certo
1. **London Mulligan free first** ✅ — `bottom_count = max(0, mulligan_count - 1)`. CR 103.5c.
2. **Definição rigorosa de jogável** ✅ — "2-4 lands AND (ramp >= 1 OR lands >= 3)".
3. **T1 ramp canônico** ✅ — `{Sol Ring}`.
4. **Hash verification (Exec#15)** ✅ — Detectou mudança de deck.

### O que faz errado
1. **Tapped lands não simulados** 🟡 — T3 reportado é melhor que real (+2-5pp). CR 110.5a.
2. **Color screw não verificado** 🔴 — Mão com 3 Mountains + spells brancos é "jogável". +3-8pp de superestimação. CR 903.4c.
3. **Sem draws futuros** 🟡 — Só avalia mão inicial, não T1-T3 draws.
4. **Dependência do classificador** 🟡 — `functional_tag='ramp'` define o que conta como ramp. Se o classificador mudar, a simulação anterior fica inválida sem detecção.
5. **Sem verificação de color identity do deck** 🟡 — Não valida se todas as cartas são RW-legais.

### Verificações MTG (atualizado v3.4)

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| London Mulligan (103.4) | CR 103.4 | ✅ | 7 cards, bottom N |
| Free first in multiplayer (103.5c) | CR 103.5c | ✅ | `mulligan_count - 1` |
| Color identity (903.4) | CR 903.4c | ❌ Não | Não verifica mana colorida |
| Tapped lands | CR 110.5a | ❌ Não | Tratados como untapped |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado |
| Future draws (T1-T3) | N/A | ❌ Não | Só mão inicial |

### Recomendações (atualizado v3.4)

1. **Adicionar simulação de tapped lands** (Temple, Garrison, etc.)
2. **Adicionar color requirement check** — verificar se lands produzem cores das spells
3. **Adicionar draws futuros (T1-T3)** — 3 draws adicionais
4. **Invalidar simulação quando classificador muda** — Comparar hash do classificador, não só do deck
5. **Hardcode ramp cards conhecidas** como fallback

---

## 4. Battle — Auditoria Detalhada (v3.4 refresh)

**Job ID:** 94f8590b1beb
**Diretório:** `/opt/data/cron/output/94f8590b1beb/` — **NÃO EXISTE**
**Entrada em jobs.json:** NÃO
**Código:** `server/lib/ai/battle_simulator.dart` (879 linhas)

### Mudança desde v3.3

**v3.3:** Diretório existia mas estava vazio.
**v3.4:** Diretório foi REMOVIDO completamente. O Battle Analyst não existe em nenhuma forma no filesystem de cron. Apenas o código fonte permanece.

### Status: NÃO É UM CRON (confirmado v3.4)

O Battle Analyst nunca foi, não é, e nunca será um cron job ativo a menos que seja explicitamente criado em `jobs.json`. O código `battle_simulator.dart` é um protótipo de simulação de combate 2-player que NÃO implementa as regras fundamentais de Commander.

### Análise do Código

#### Implementado corretamente

| Feature | Status |
|:--------|:------|
| Flying, Trample, Lifelink, First Strike, Deathtouch, Vigilance, Haste | ✅ |
| Untap/Draw/Discard phases | ✅ |

#### NÃO implementado (viola regras MTG)

| Feature | CR Ref | Impacto |
|:--------|:------|:--------|
| **Stack/Priority** | CR 117.3 | 🔴 Spells resolvem imediatamente. Counterspells impossíveis. |
| **Multiplayer (4-player)** | CR 802.1a | 🔴 2-player apenas |
| **Commander damage (21)** | CR 903.10a | 🔴 Não trackeado |
| **Commander tax (+2)** | CR 903.8 | 🔴 Não implementado |
| **ETB triggers** | CR 603.4 | 🔴 Não implementados |
| **Planeswalkers** | CR 306 | 🔴 Não suportados |
| **Múltiplos bloqueadores** | CR 509.1c | 🔴 1 blocker por attacker |
| **State-Based Actions** | CR 704.3 | 🔴 Apenas destroy por dano |

### Conclusão Battle

**N/A — Não usar para decisões de swap.** O código é um protótipo de combate, não um simulador de Commander. O diretório de cron foi removido. Qualquer referência a BATTLE_LOG.md nos prompts de outros agentes (Oracle, Mulligan) é uma referência a um arquivo que não existe.

### Recomendação

1. **Remover referências a BATTLE_LOG.md** dos prompts do Oracle e Mulligan
2. **Marcar `battle_simulator.dart` como `@deprecated`** ou mover para `server/test/`

---

## 5. Evolution Oracle — Auditoria Detalhada (v3.4 refresh)

**Job ID:** a50bef4c2a59
**Última execução:** 2026-06-04T02:14Z (execução #51)
**Resposta:** PARCIAL — começou Step 0, travou nos tool calls
**Hash verificado:** TENTOU (comando `execute_terminal` no output) mas não completou

### O que mudou desde v3.3

**Mudou o tipo de falha:**
- v3.3: Oracle retornava `[SILENT]` (2 linhas) ou output de 7 linhas
- v3.4: Oracle TENTOU executar (viu `read_file` e `execute_terminal` tool calls no output), mas o output foi truncado ANTES de qualquer resultado. O agente iniciou o Step 0 corretamente: leu EVOLUTION_LOG, MULLIGAN_LOG, SCOUT_LOG, e rodou hash verification + sync legalities. Mas o output foi cortado após os tool calls — sem resultados visíveis.

**Isso é pior ou melhor?**
- **PIOR para nota** (1.0 → 0.5): O agente tenta mas não completa. É um zumbi — meio vivo, meio morto.
- **MELHOR para diagnóstico:** Sabemos agora que o agente NÃO está em short-circuit. Ele está sendo INTERROMPIDO (timeout? rate limit? tool call failure?) antes de completar o Step 0.

**Script `manaloom-wincon-oracle.sh`:**
```bash
$ find /opt/data/cron /opt/data/scripts /opt/data/workspace -name "manaloom-wincon-oracle.sh" 2>/dev/null
# NÃO ENCONTRADO
```
O script referenciado em `jobs.json` (linha 449: `"script": "manaloom-wincon-oracle.sh"`) não existe no filesystem. O campo `no_agent: false` significa que o LLM agent é o executor primário, então o script ausente pode não ser a causa do problema — mas é uma inconsistência.

### O que faz certo (quando funciona)

1. **Pipeline Integrity Break detection (C#23)** ✅ — Detectou 5 ciclos com hash falso.
2. **Estratégia baseada em T3 (C#23)** ✅ — T3=13.3% → DEFENSIVO → net ΔCMC=-16.
3. **Justificativa multi-eixo** ✅ — Diagnóstico + Solução + Princípio.
4. **Modo CO-PILOT** ✅ — Swaps documentados, não aplicados.

### O que faz errado

1. **Output sempre incompleto** 🔴 — 72h sem produzir análise completa. A execução #51 mostra tool calls sendo feitos mas output truncado. Causa provável: timeout do provider (deepseek-v4-pro) ou rate limit (HTTP 429) interrompendo após alguns tool calls.
2. **Pipeline Death Loop** 🔴 — Oracle não completa → todos os outros agentes retornam [SILENT] → Oracle não tem dados novos → Oracle não completa. Loop vicioso.
3. **Script referenciado não existe** 🟡 — `manaloom-wincon-oracle.sh` não encontrado no filesystem.
4. **Referência a BATTLE_LOG.md inexistente** 🟡 — Prompt linha 1981: "BATTLE_LOG.md → matchup weaknesses". Este arquivo não existe.
5. **Prompt vs execução real divergem** 🟡 — O prompt descreve análise estratégica completa (ler logs, decidir 0-3 swaps), mas a execução real nunca chega ao Step 1.
6. **"Miracle {2}" no prompt é conceitualmente errado** 🟡 — O prompt diz: "TODAS instants/sorceries no deck custam {2} + pips coloridos com Lorehold no campo. Priorize instants/sorceries." Isso NÃO é como Miracle funciona. Miracle é uma keyword que permite conjurar por um custo alternativo (menor). Lorehold reduz o custo de mágicas CONJURADAS DO CEMITÉRIO em {2} (não todas as mágicas, e não para {2} fixo). A redação do prompt é imprecisa.

### Verificações MTG (quando funcionou — C#23)

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ✅ | Implícito |
| Singleton (903.5b) | CR 903.5b | ✅ | "Verifique singleton apos swaps" |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado |
| Commander banlist | Scryfall | ✅ | C#23 executou sync |
| Wincon legality | N/A | ✅ | `user_collection.quantity > 0` |

### Recomendações (atualizado v3.4)

1. **🔴 CRÍTICO: Aumentar timeout do Oracle** — Se o agente está sendo interrompido após 3-4 tool calls, o timeout precisa ser maior. O Oracle precisa ler 4 arquivos de log + rodar 2 scripts + analisar + propor swaps. Isso não cabe em 60s.
2. **🔴 CRÍTICO: Forçar execução com flag `--force`** — Ignorar short-circuit, rodar análise completa UMA vez para quebrar o Death Loop.
3. **Corrigir referência a BATTLE_LOG.md** — Remover do prompt (arquivo não existe).
4. **Corrigir descrição de Miracle** no prompt — "Lorehold reduz custo de mágicas do cemitério em {2}" ao invés de "custam {2} + pips".
5. **Criar script `manaloom-wincon-oracle.sh`** ou remover a referência do `jobs.json`.
6. **Adicionar condição de "force run":** Se 3+ execuções [SILENT] ou incompletas consecutivas → forçar análise.
7. **Considerar trocar provider** do Oracle para um modelo mais rápido/barato (deepseek-v4-flash?) já que o Oracle faz mais tool calls que análise de texto.

---

## 6. Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (quebra o pipeline)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 1 | Oracle output sempre incompleto (>72h) | Evolution Oracle | Aumentar timeout; forçar execução com `--force`; trocar provider se necessário | 1h |
| 2 | Pipeline Death Loop ativo | Pipeline | Após fix do Oracle, todo o pipeline reinicia | 0h (depende de #1) |
| 3 | Validator com erro de banlist nos logs (Worldfire) | Validator | Forçar reexecução para corrigir v3.24 | 30min |
| 4 | Sem stack/priority no Battle | Battle | NÃO É CRON. Marcar código como `@deprecated`. | 30min |

### 🟡 ALTO (distorce resultados)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 5 | Scout perdeu função original | Scout | Restaurar prompt EDHREC + user_collection + A+B+C | 1h |
| 6 | Color screw não simulado (+3-8pp) | Mulligan | Adicionar verificação de mana colorida | 2h |
| 7 | Tapped lands não simulados (+2-5pp) | Mulligan | Adicionar simulação de enters-tapped | 1h |
| 8 | Prompt referencia `card_oracle_data` (não existe) | Validator | Corrigir para `card_rulings` | 10min |

### 🟢 MÉDIO (imprecisão corrigível)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 9 | PG profile fixo vs deck dinâmico | Validator | Detectar archetype mismatch; recomendar novo perfil | 2h |
| 10 | Sem verificação de singleton | Scout, Validator | Query de duplicatas | 30min |
| 11 | Sem draws futuros no Mulligan | Mulligan | Simular T1-T3 draws | 2h |
| 12 | Classificador dita acurácia do Mulligan | Mulligan | Hardcode ramp conhecidas; invalidar simulação quando classificador muda | 1h |
| 13 | Referência a BATTLE_LOG.md no Oracle | Oracle | Remover do prompt | 5min |
| 14 | "Miracle {2}" impreciso no prompt do Oracle | Oracle | Corrigir descrição | 5min |

### ⚪ BAIXO (cosmético / documentação)

| # | Problema | Cron | Ação |
|:-:|:---------|:-----|:-----|
| 15 | `[SILENT]` vs `SILENT` inconsistente | Validator | Normalizar formato |
| 16 | Script oracle não encontrado | Oracle | Criar ou remover referência |
| 17 | Battle listado nos docs como cron ativo | Docs | Atualizar documentação |
| 18 | `card_deck_analysis` referencia deck_id deletado | Scout | Verificar deck_id antes de usar |

---

## 7. Conclusão (v3.4)

A pipeline Lorehold tem confiabilidade **BAIXA** (3.6/10) em relação às regras oficiais de MTG e à sua própria função declarada. A nota caiu de 4.1 (v3.3) para 3.6 (v3.4).

### O que piorou

- **Evolution Oracle:** 1.0 → 0.5. Agora tenta executar mas nunca completa. É pior que [SILENT] porque gasta recursos sem produzir output.
- **Validator:** 8.0 → 7.0. Entrou em short-circuit com erro de banlist nos logs. Não vai se autocorrigir.
- **Pipeline:** 4.1 → 3.6. Death Loop agora afeta TODOS os agentes.

### O que permanece igual

- **Scout:** Prompt "Wincon Hunter" não mudou. Continua não sendo um Scout.
- **Mulligan:** Continua funcional com gaps conhecidos (tapped lands, color screw).
- **Battle:** Continua não sendo um cron.

### O que o operador precisa fazer IMEDIATAMENTE

1. **Forçar Evolution Oracle** a executar UMA análise completa com timeout maior. Sem isso, o pipeline está morto.
2. **Forçar Validator** a reexecutar e corrigir o erro de banlist (Worldfire) nos logs.
3. Após esses dois fixes, o pipeline DEVE reiniciar naturalmente: Oracle detecta mudanças → propõe swaps → Mulligan testa → Scout busca → Validator analisa → Oracle sintetiza.

### Lição aprendida (v3.4)

**Short-circuit é uma faca de dois gumes.** Ele economiza recursos quando nada muda, mas PERPETUA ERROS quando a última análise contém falhas. Nenhum agente verifica "minha última análise estava correta?" antes de entrar em short-circuit. O Validator v3.24 afirmou que Worldfire estava banida — e vai continuar afirmando isso em todos os logs futuros porque o deck não mudou e o agente não reexecuta.

**Recomendação de arquitetura:** Todo short-circuit deve incluir uma verificação de "erro conhecido na última execução". Se a última análise teve `discrepancies_found > 0` no `run_log`, pular o short-circuit e reexecutar.

---

**Fontes consultadas (v3.4):**
- Magic: The Gathering Comprehensive Rules (2024-11-08) — CR 103.4, 103.5c, 110.5a, 117.3, 306, 405.5, 509.1c, 603.4, 701.5a, 704.3, 802.1a, 903.4c, 903.5a, 903.5b, 903.8, 903.10a
- Scryfall API (`api.scryfall.com/cards/named`) — Worldfire = legal, Mana Crypt = banned
- `/opt/data/cron/jobs.json` (configuração de 16 crons)
- `/opt/data/cron/output/f20ac299992b/2026-06-04_01-08-13.md` (Scout #102)
- `/opt/data/cron/output/712579b15767/2026-06-04_02-13-44.md` (Validator #64)
- `/opt/data/cron/output/08468451a06a/2026-06-04_01-09-09.md` (Mulligan #48)
- `/opt/data/cron/output/a50bef4c2a59/2026-06-04_02-14-27.md` (Oracle #51)
- `/opt/data/cron/output/94f8590b1beb/` — NÃO EXISTE (Battle)
- `server/lib/ai/battle_simulator.dart` (879 linhas)
- Auditoria anterior: `references/all-crons-mtg-rules-audit.md` v3.3 (2026-06-03)
- Skills: `manaloom-commander-knowledge`, `manaloom-mtg-domain`, `manaloom-mtg-strategy`
