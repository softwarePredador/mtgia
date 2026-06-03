# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v3.3 (re-auditado, com verificação de Scryfall + Comprehensive Rules)
**Data:** 2026-06-03
**Commit:** (a ser gerado)
**Metodologia:** Inspeção de prompts reais de `jobs.json` + outputs recentes de `/opt/data/cron/output/<id>/` + código fonte `battle_simulator.dart` (879 linhas) + `wincon_pipeline.py` (289 linhas) + consultas à Scryfall API + Comprehensive Rules (CR 2024-11-08).

---

## Sumário

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | **4.0/10** | 🔴 BAIXA | Prompt desalinhado ("Wincon Hunter", não Scout); 94% [SILENT]; recomendações sem checar EDHREC real; misclassifications não filtradas |
| Validator | **8.0/10** | 🟢 ALTA | Banlist Blindness pré-sync (corrigido 2026-06-03); PG profile vs archetype mismatch documentado; `card_oracle_data` referenciado (não existe) |
| Mulligan | **7.5/10** | 🟡 MÉDIA-ALTA | Tapped lands não simulados; color screw não verificado; sem draws futuros (T2/T3); London Mulligan free-first ✅ implementado |
| Battle | **N/A** | 🔴 NÃO É CRON | Diretório existe mas vazio; sem entrada em `jobs.json`; código 2-player sem stack/priority; NUNCA executado por cron |
| Evolution Oracle | **1.0/10** | 🔴 CRÍTICA | 9+ execuções consecutivas [SILENT]; último output incompleto (7 linhas); 5 ciclos operaram com hash falso; não detecta rebuilds externos |
| **PIPELINE** | **4.1/10** | 🔴 BAIXA | Evolution Oracle é NO-OP; Scout perdeu função original; Validator é o único agente confiável; Pipeline Death Loop confirmado |

---

## 1. Scout — Auditoria Detalhada

**Job ID:** f20ac299992b
**Última execução:** Execução #38 (2026-06-03T21:43Z)
**Status:** `ok-nochange-deck-saturated`
**Hash verificado:** `8b9c643c...` (recomputado do DB, divergente do Scout #37)

### O que faz certo

1. **Banlist check** ✅ — Execução #38 verificou Worldfire e Mana Vault via `card_legalities` (PG-sync). Constatou 0 banned cards.
2. **Misclassification detection** ✅ — Identificou Trouble in Pairs e Perch Protection como "⚠️ MISCLASSIFIED" (draw engine e fog, não wincons).
3. **Hash recomputation** ✅ — Detectou divergência de hash vs Scout #37 (4ª mudança consecutiva de deck por força externa).
4. **Deck saturated** ✅ — Reconheceu corretamente que 13 wincons (13% do deck) é supersaturação para cEDH (meta usa 3-5).

### O que faz errado

1. **Prompt desalinhado com função original** 🔴 — O prompt atual é um "Wincon Hunter" que busca APENAS `card_deck_analysis` com `role_in_deck IN ('wincon','engine','token_maker')`. A função original do Scout era: EDHREC JSON API → cross-ref `user_collection` → Score A+B+C (Sinergia + Custo + Evidência). O prompt perdeu completamente a busca EDHREC, a análise de sinergia qualitativa, e a verificação de tendências (`trend_zscore`).

2. **Não consulta EDHREC** 🔴 — O Scout NÃO busca `json.edhrec.com/pages/commanders/lorehold-the-historian.json`. As recomendações são baseadas exclusivamente em `card_deck_analysis` scores, que são gerados pelo sistema para decks que podem não existir mais (ver Pitfall `card_deck_analysis` com deck_id deletado).

3. **94% [SILENT] rate** 🔴 — Das últimas 10 execuções, 9 retornaram [SILENT] ou "no-change". O prompt atual só produz output quando há mudança no `card_deck_analysis` ou no deck — mas nunca busca dados novos do EDHREC.

4. **Wincons no deck estão stale** 🟡 — O prompt lista "WINCONS JA NO DECK" com valores fixos (Rise of the Eldrazi: 15, Mizzix's Mastery: 16, etc.). Estes valores são do `card_deck_analysis` de um `deck_id` que pode não existir mais. A Execução #38 mostra que Rise of the Eldrazi foi removido do deck (substituído por Longshot + Surge to Victory).

5. **Sem verificação de color identity** 🟡 — O prompt não verifica se as cartas recomendadas da `user_collection` são legais em RW (Boros). O filtro `uc.quantity > 0` não garante `color IN ('R','W','R,W',NULL)`.

6. **Sem verificação de singleton** 🟡 — Não verifica se adicionar uma carta violaria a regra CR 903.5b (singleton, exceto basic lands).

7. **Sem priorização por CMC** 🟡 — Os candidatos são ordenados por `wincon_total_score` sem considerar CMC. No contexto DEFENSIVO (>12% T3), cartas CMC alto deveriam ser despriorizadas.

### Verificações MTG

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ⚠️ Parcial | SQL não filtra por cor |
| Singleton (903.5b) | CR 903.5b | ❌ Não | Não verifica duplicatas |
| 100 cards (903.5a) | CR 903.5a | ⚠️ Implícito | Deck tem 100 cards |
| Commander banlist | Scryfall | ✅ Sim | Via PG-sync `card_legalities` |
| EDHREC inclusion % | N/A | 🔴 Não | Prompt não usa EDHREC |
| Wincon = payoff | Regra não-oficial | ⚠️ Parcial | Detecta misclassifications |

### Recomendações

1. **Restaurar prompt original:** EDHREC JSON API → `user_collection` cross-ref → Score A+B+C (ver `references/synergy-first-scout-methodology.md`)
2. **Adicionar filtro de color identity:** `AND (uc.color IS NULL OR uc.color IN ('R','W','R,W'))`
3. **Adicionar verificação de singleton** antes de recomendar
4. **Remover hardcoded "WINCONS JA NO DECK"** — query dinâmica do DB sempre
5. **Priorizar por CMC quando T3 > 12%** (modo DEFENSIVO)

---

## 2. Validator — Auditoria Detalhada

**Job ID:** 712579b15767
**Última execução bem-sucedida:** v3.24 (2026-06-02T21:52Z)
**Última execução:** Falhou com HTTP 429 (2026-06-03T19:03Z)
**Status:** `purpose-analyzer-v3.24-corrupted-import`

### O que faz certo

1. **SYNERGY_MAP com 7 eixos** ✅ — Cobre: Combo Pieces, Explosive Mana, Recursion, Resilience, Stack Interaction, Wipes+Proteção, Token+Pump. Pontuação de 3-9/10 por eixo. Cobertura estratégica abrangente.

2. **Detecção de corrupção de dados** ✅ — v3.24 identificou: 20 cartas com `functional_tag='unknown'`, 6 cartas com `CMC=NULL`, múltiplas cartas com `CMC=0.0` incorreto. Diagnosticou que o classificador nunca rodou (bulk import).

3. **Detecção de archetype mismatch** ✅ — Identificou que o deck atual é "cEDH Turbo-Combo" (Dualcaster+Twinflame, Approach+Top), não "spellslinger" como o PG profile assume. Reconheceu que as discrepâncias são diferenças de arquétipo, não deficiências.

4. **Multi-hash verification** ✅ — Detectou 3 mudanças de hash, recalculou métricas do zero.

5. **DB metrics garbage detection** ✅ — Identificou que `decks.board_wipe_count=4` mas tag real = 1; `engine_count=4` mas real = 0-1.

6. **Escrita de logs completa** ✅ — `VALIDATOR_LOG_v3.24.md` + `VALIDATOR_LOG.md` + `VALIDATOR_SUMMARY.md` (per-deck + root-level) + `run_log`. Verificação pós-write implementada.

### O que faz errado

1. **Banlist Blindness (v3.24)** 🔴 — O Validator v3.24 afirmou: "Worldfire is BANNED in Commander since the format's inception." **ISTO É FALSO.** Scryfall confirma: Worldfire = `commander: legal`. O Validator não executou `/opt/data/scripts/manaloom-sync-legalities.sh` antes da análise. A correção (sync PG → SQLite) foi implementada em 2026-06-03, mas o Validator não rodou com sucesso desde então (HTTP 429).

2. **Referência a tabela inexistente** 🟡 — O prompt menciona `card_oracle_data.ruling_text`, mas a tabela correta é `card_rulings` (com `ruling_text`). `card_oracle_data` não existe.

3. **PG profile fixo vs deck dinâmico** 🟡 — O prompt lista um perfil fixo (`lands: 32, ramp: 3.67, ritual_treasure: 10...`) de um corpus de 3 decks spellslinger. Quando o deck muda de arquétipo (spellslinger → cEDH combo), o perfil se torna irrelevante. O Validator detectou isso (v3.24), mas o prompt não orienta a buscar um perfil alternativo ou gerar um novo.

4. **Sem validação de singleton pós-análise** 🟡 — O Validator analisa o deck mas não emite alerta se houver cartas duplicadas (CR 903.5b).

### Verificações MTG

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ✅ | PG profile inclui `color_identity` |
| Singleton (903.5b) | CR 903.5b | ❌ Não | Não verificado |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado (100 cards) |
| Commander banlist | Scryfall | 🔴 Falhou | Afirmou Worldfire banned (errado) |
| Functional classification | N/A | ✅ | Detecta unknown tags, CMC corruption |
| Archetype detection | N/A | ✅ | cEDH vs spellslinger identificado |
| SYNERGY_MAP coverage | N/A | ✅ | 7 eixos, 3-9/10 |

### Recomendações

1. **Executar sync_legalities.sh no início** — já documentado no skill, validar que o Validator o faz
2. **Corrigir referência no prompt:** `card_rulings.ruling_text` (não `card_oracle_data`)
3. **Adicionar verificação de singleton:** query `GROUP BY card_name HAVING SUM(quantity) > 1 AND card_name NOT LIKE '%Plains%' AND card_name NOT LIKE '%Mountain%'`
4. **Detectar archetype mismatch e buscar perfil alternativo** quando o deck mudar de estratégia
5. **Resolver HTTP 429** — o Validator não roda há 24h por rate limit do provider

---

## 3. Mulligan — Auditoria Detalhada

**Job ID:** 08468451a06a
**Última execução:** Execução #15 (2026-06-03T21:47Z)
**Status:** `mulligan-simulation-1000-exec15` (ok)

### O que faz certo

1. **London Mulligan free first** ✅ — Implementado corretamente: `bottom_count = max(0, mulligan_count - 1)`. CR 103.5c: "In a multiplayer game... the first mulligan a player takes doesn't count toward the number of cards that player will put on the bottom."

2. **Definição rigorosa de jogável** ✅ — "2-4 lands AND (ramp >= 1 OR lands >= 3)". Esta é a definição correta e mais conservadora, evitando o viés de +20pp da definição ampla.

3. **T1 ramp canônico** ✅ — Usa `{Sol Ring}` como definição estrita (correto: apenas Sol Ring produz mana no T1 em RW). Fast mana detection (Mana Vault, Lotus Petal, etc.) como banda separada.

4. **Detecção de gap do classificador** ✅ — Execução #15 detectou que o salto de 8.9% → 1.6% T3 foi causado pela correção do classificador (6 → 19 ramp tags), não por mudanças no deck. Documentou o gap de 16.1pp.

5. **Hash verification** ✅ — Detectou que o deck mudou desde Exec#14.

6. **Métricas estáveis** ✅ — Sem Play T3 é tratado como métrica primária (definition-independent). Ramp T1 é documentado com definição explícita para permitir comparação.

### O que faz errado

1. **Tapped lands não simulados** 🟡 — Temple of Triumph, Boros Garrison, e outras dual lands que entram tapped são tratadas como untapped no turno de entrada. Isto faz o T3 reportado ser MELHOR que o real. Impacto estimado: 2-5pp.

2. **Color screw não verificado** 🔴 — Uma mão com 3 Mountains + spells brancos (sem fonte de W) é considerada "jogável" porque o simulador não verifica se as lands produzem as cores necessárias. Impacto estimado: 3-8pp de superestimação. CR 903.4c exige que toda mana produzida esteja na color identity do commander.

3. **Sem draws futuros** 🟡 — O simulador avalia apenas a mão inicial (7 cartas após mulligans). Não simula as compras dos turnos 1, 2, 3. Isto cria um viés oposto: subestima a probabilidade de encontrar a 3ª land ou 1º ramp nos draws. Os vieses #1 e #2 vs #3 se compensam parcialmente, mas a direção e magnitude são desconhecidas.

4. **Sem verificação de commander color identity** 🟡 — Não valida se todas as cartas do deck são legais em RW (CR 903.4c). Assumindo que o deck já é legal (construído por humano), mas não deve assumir para decks importados.

5. **Dependência do classificador para ramp** 🟡 — A definição de "jogável" depende de `functional_tag='ramp'`. Quando o classificador falha (Exec#14: 6/16 ramp), o T3 é artificialmente inflado em 8.8-16.1pp. O Exec#15 corrigiu isso, mas o problema fundamental permanece: a acurácia do simulador é limitada pela acurácia do classificador.

### Verificações MTG

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| London Mulligan (103.4) | CR 103.4 | ✅ | 7 cards, bottom N |
| Free first in multiplayer (103.5c) | CR 103.5c | ✅ | `mulligan_count - 1` |
| Color identity (903.4) | CR 903.4c | ❌ Não | Não verifica mana colorida |
| Tapped lands | CR 110.5a | ❌ Não | Tratados como untapped |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado |
| Future draws (T1-T3) | N/A | ❌ Não | Só mão inicial |

### Recomendações

1. **Adicionar simulação de tapped lands:** `enters_tapped = 'Temple' in name or 'Garrison' in name or 'enter the battlefield tapped' in oracle_text`
2. **Adicionar color requirement check:** Para cada spell na mão, verificar se `lands_produced_colors ⊇ spell_required_colors`
3. **Adicionar draws futuros (T1-T3):** Simular 3 draws adicionais, verificando se o T3 se torna jogável
4. **Hardcode ramp cards conhecidas** como fallback quando o classificador falhar: `KNOWN_RAMP = {'Sol Ring', 'Mana Vault', 'Mana Crypt', 'Boros Signet', ...}`
5. **Documentar o intervalo de confiança** para T3: [T3_simulado, T3_simulado + viés_tapped + viés_color - viés_draws]

---

## 4. Battle — Auditoria Detalhada

**Job ID:** 94f8590b1beb (diretório existe, mas sem entrada em `jobs.json`)
**Última execução:** NUNCA (diretório vazio)
**Código:** `server/lib/ai/battle_simulator.dart` (879 linhas)

### Status: NÃO É UM CRON

O diretório `/opt/data/cron/output/94f8590b1beb/` existe mas está vazio. Não há entrada correspondente em `jobs.json`. O Battle Analyst nunca foi executado como cron job.

### Análise do Código (battle_simulator.dart)

O código existe como protótipo 2-player com as seguintes características:

#### Implementado corretamente

| Feature | Linha | Status |
|:--------|:-----:|:------|
| Flying evasion | 56 | ✅ Implementado |
| Trample | 64, 497-499 | ✅ Excesso de dano passa ao jogador |
| Lifelink | 60, 464-466, 502-503 | ✅ Sem cap (linha 517: `active.life += lifeGained`) |
| First Strike | 65, 474-483 | ✅ Resolve antes do dano normal |
| Deathtouch | 62, 476, 489 | ✅ Mata com 1 de dano |
| Vigilance | 58, 430 | ✅ Não tapa ao atacar |
| Haste | 57 | ✅ Detectado |
| Untap phase | 386-395 | ✅ Todas as permanentes |
| Draw phase | 397-404 | ✅ Draw 1 (exceto T1 do primeiro jogador) |
| Discard to 7 | 532-537 | ✅ End step |
| Damage cleanup | 539-542 | ✅ End step |

#### NÃO implementado (viola regras MTG)

| Feature | CR Ref | Impacto |
|:--------|:------|:--------|
| **Stack/Priority** | CR 117.3, 405.5 | 🔴 Spells resolvem imediatamente (linha 9). Counterspells impossíveis. |
| **Multiplayer (4-player)** | CR 802.1a | 🔴 2-player apenas. Sem split de ataque. Sem política. |
| **Counterspells** | CR 701.5a | 🔴 Impossível com resolução imediata |
| **Commander damage (21)** | CR 903.10a | 🔴 Não trackeado |
| **Commander tax (+2)** | CR 903.8 | 🔴 Não implementado |
| **ETB triggers** | CR 603.4 | 🔴 Não implementados |
| **Planeswalkers** | CR 306 | 🔴 Tipo não suportado |
| **Múltiplos bloqueadores** | CR 509.1c | 🔴 1 blocker por attacker (linha 459: `blocker` singular) |
| **State-Based Actions** | CR 704.3 | 🔴 Apenas destroy por dano; sem SBAs |
| **Color production tracking** | CR 106.1a | 🔴 Mana = land count, sem tracking de cores |

#### Conclusão Battle

O código é um protótipo de simulação de combate, não um simulador de Commander. **NÃO DEVE SER USADO** para decisões de swap. O score é **N/A** — não é um cron ativo.

---

## 5. Evolution Oracle — Auditoria Detalhada

**Job ID:** a50bef4c2a59
**Última execução com output:** C#23 (2026-06-01T08:25Z)
**Últimas 9+ execuções:** [SILENT] ou incompletas
**Última execução:** 2026-06-03T20:59Z — incompleta (7 linhas, parou no Step 0)

### Configuração

- `no_agent: false` — roda como LLM agent
- `script: "manaloom-wincon-oracle.sh"` — script existe? (não encontrado no filesystem)
- O script `wincon_pipeline.py oracle` é determinístico e sempre retorna "keep current decklist"

### O que faz certo (quando funciona — C#23, 2026-06-01)

1. **Pipeline Integrity Break detection** ✅ — C#23 detectou que 5 ciclos (C#18–C#22) operaram com hash falso `a440c497...` vs DB real `30d00347...`. Nenhum outro agente havia detectado.

2. **Estratégia baseada em T3** ✅ — C#23 identificou T3=13.3% → zona DEFENSIVA (>12%) → propôs swaps com net ΔCMC = -16.

3. **Justificativa multi-eixo** ✅ — Diagnóstico + Solução + Princípio para cada swap.

4. **Modo CO-PILOT** ✅ — Swaps documentados, não aplicados automaticamente.

### O que faz errado

1. **9+ execuções [SILENT] consecutivas** 🔴 — Desde 2026-06-01T14:26, todas as execuções retornaram [SILENT] (2 linhas) ou output incompleto. O Oracle não está produzindo análise há >48h.

2. **Output atual incompleto** 🔴 — Execução mais recente (2026-06-03T20:59Z) parou após 7 linhas: "We will execute the required sync script and validate the active Lorehold deck." Não completou Step 0.

3. **Cego a reconstruções externas** 🔴 — Quando o deck foi completamente reconstruído 2x em ~1h (2026-06-02), o Scout, Validator e Mulligan detectaram. O Oracle permaneceu [SILENT] — não tem reset protocol.

4. **Pipeline Death Loop** 🔴 — Oracle ([SILENT]) → Mulligan ([SILENT]) → Scout ([SILENT]) → Oracle (mesmo [SILENT]). Sem o Oracle propor swaps, nenhum agente tem motivo para rodar análise nova. O pipeline para completamente.

5. **Sem leitura real de logs** 🟡 — O prompt instrui a ler MULLIGAN_LOG, BATTLE_LOG, SCOUT_LOG, mas quando o Oracle está em modo [SILENT], não lê nada.

6. **Prompt vs script conflitante** 🟡 — O prompt do LLM descreve análise completa (ler logs, decidir swaps, etc.), mas o `script` associado (`wincon_pipeline.py oracle`) é determinístico e imutável. Não está claro qual dos dois realmente executa.

### Verificações MTG (quando funcionou — C#23)

| Regra | CR Ref | Verificado? | Nota |
|:------|:------|:-----------|:-----|
| Color Identity (903.4) | CR 903.4c | ✅ | Implícito (deck já construído) |
| Singleton (903.5b) | CR 903.5b | ✅ | "Verifique singleton apos swaps" no prompt |
| 100 cards (903.5a) | CR 903.5a | ✅ | Verificado: "100 (86 rows, 35 lands)" |
| Commander banlist | Scryfall | ✅ | C#23 executou sync |
| Wincon legality | N/A | ✅ | Verificou `user_collection.quantity > 0` |
| Swap justification | N/A | ✅ | 3 eixos (Diagnóstico, Solução, Princípio) |

### Recomendações

1. **Diagnosticar por que o Oracle está [SILENT] há 48h** — verificar se o script `manaloom-wincon-oracle.sh` existe; verificar logs de erro
2. **Implementar reset protocol:** Quando hash divergir → resetar contador de ciclos → reconstruir EVOLUTION_LOG do zero
3. **Remover script determinístico** se o LLM agent for o caminho desejado; ou remover o prompt LLM se o script for o caminho
4. **Adicionar condição de "force run":** Se `run_log` mostra 3+ execuções [SILENT] consecutivas, forçar análise completa
5. **Timeout maior:** Se o Oracle está sendo interrompido antes de completar, aumentar timeout

---

## 6. Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (quebra o pipeline)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 1 | Oracle 48h [SILENT] — pipeline parado | Evolution Oracle | Diagnosticar causa; forçar execução com hash verification forçada | 1h |
| 2 | Oracle cego a rebuilds externos | Evolution Oracle | Implementar reset protocol quando hash divergir | 2h |
| 3 | Sem stack/priority no Battle | Battle | Não é cron ativo — baixa prioridade. Marcar código como `@deprecated` | 30min |
| 4 | Banlist Blindness (Worldfire) | Validator | Já corrigido via sync PG→SQLite (2026-06-03). Requer re-execução do Validator. | 0h (fix existe) |
| 5 | Validator HTTP 429 — não roda há 24h | Validator | Aguardar reset de rate limit ou trocar provider | 0h (aguardar) |

### 🟡 ALTO (distorce resultados)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 6 | Scout perdeu função original (Wincon Hunter ≠ Scout) | Scout | Restaurar prompt: EDHREC JSON API + user_collection + A+B+C | 1h |
| 7 | Color screw não simulado (+3-8pp erro) | Mulligan | Adicionar verificação de mana colorida | 2h |
| 8 | Tapped lands não simulados (+2-5pp erro) | Mulligan | Adicionar simulação de enters-tapped | 1h |
| 9 | Classificador dita acurácia do Mulligan | Mulligan | Hardcode ramp conhecidas como fallback | 1h |

### 🟢 MÉDIO (imprecisão corrigível)

| # | Problema | Cron | Ação | Esforço |
|:-:|:---------|:-----|:-----|:-------|
| 10 | Prompt referencia `card_oracle_data` (não existe) | Validator | Corrigir para `card_rulings` | 10min |
| 11 | PG profile fixo vs deck dinâmico | Validator | Detectar archetype mismatch; buscar perfil alternativo | 2h |
| 12 | Sem verificação de singleton | Scout, Validator | Adicionar query de duplicatas | 30min |
| 13 | Sem draws futuros no Mulligan | Mulligan | Simular T1-T3 draws (3 cartas adicionais) | 2h |

### ⚪ BAIXO (cosmético / documentação)

| # | Problema | Cron | Ação |
|:-:|:---------|:-----|:-----|
| 14 | Battle Analyst listado como cron ativo | Docs | Atualizar documentação: Battle NÃO é cron |
| 15 | `card_deck_analysis` referencia deck_id deletado | Scout | Verificar deck_id antes de usar scores |

---

## 7. Conclusão

A pipeline Lorehold tem confiabilidade **BAIXA** (4.1/10) em relação às regras oficiais de MTG e à sua própria função declarada.

### O que funciona

- **Validator** é o agente mais confiável (8.0/10): SYNERGY_MAP cobre 7 eixos, detecta corrupção de dados, identifica archetype mismatch. O gap de banlist (Worldfire) foi corrigido via sync PG→SQLite.
- **Mulligan** é funcional (7.5/10): London mulligan free-first implementado corretamente, definição rigorosa de jogável, métricas estáveis. Tapped lands e color screw são gaps conhecidos e documentados.
- **Scout** tem boa detecção de misclassifications e banlist (4.0/10), mas perdeu a função original de scout de sinergia.

### O que está quebrado

- **Evolution Oracle** está efetivamente morto (1.0/10): 48h sem produzir análise. Sem o Oracle, o pipeline é um corpo sem cérebro — os outros agentes produzem dados que ninguém sintetiza em swaps.
- **Battle** não existe como cron.
- **Pipeline Death Loop** está ativo: Oracle [SILENT] → todos os outros perdem propósito → pipeline para.

### Próximo passo imediato

**Forçar o Evolution Oracle a executar uma análise completa**, com hash verification forçada e ignore do estado [SILENT]. Sem o Oracle funcionando, os outros 3 agentes estão girando em falso.

---

**Fontes consultadas:**
- Magic: The Gathering Comprehensive Rules (2024-11-08)
- Scryfall API (`api.scryfall.com/cards/named`)
- `/opt/data/cron/jobs.json` (configuração de todas as crons)
- `/opt/data/cron/output/f20ac299992b/` (Scout — 101 execuções)
- `/opt/data/cron/output/712579b15767/` (Validator — 62 execuções)
- `/opt/data/cron/output/08468451a06a/` (Mulligan — 47 execuções)
- `/opt/data/cron/output/a50bef4c2a59/` (Evolution Oracle — 48 execuções)
- `server/lib/ai/battle_simulator.dart` (879 linhas)
- `docs/hermes-analysis/manaloom-knowledge/scripts/wincon_pipeline.py` (289 linhas)
