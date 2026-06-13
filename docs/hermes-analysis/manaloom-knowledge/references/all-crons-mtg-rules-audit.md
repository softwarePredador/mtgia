# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v10.0
**Data:** 2026-06-13T01:30:00+00:00
**Commit:** `bb134a18` (HEAD, master)
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`) — execução manual
**Escopo:** Auditoria completa linha-a-linha dos 5 crons do pipeline Lorehold descomissionado + ecossistema atual de 15 tabelas SQLite + código Dart de produto

---

## Sumário Executivo

### Pipeline Lorehold (Descomissionado v3.7, código permanece)

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | 4.0/10 | BAIXA | Prompt "Wincon Hunter" desalinhado; 94% [SILENT] antes do descomissionamento |
| Validator | 7.0/10 | MÉDIA | SYNERGY_MAP incompleto (falta stack interaction, gy hate); Archetype Mismatch não detectado |
| Mulligan | 6.5/10 | MÉDIA | Tapped lands ignorados; T1 ramp inflado; color screw não simulado |
| Battle | 2.0/10 | 🔴 CRÍTICA | 2-player, sem stack/priority, sem Commander damage/tax, 1 blocker |
| Evolution Oracle | 3.5/10 | BAIXA | Death loop autossustentável; dependia de dados inválidos; prompt com Miracle errôneo |
| **PIPELINE** | **4.5/10** | **🔴 BAIXA** | **Descomissionado — código legado sem crons ativos** |

### Ecossistema Atual (Crons Ativos 2026-06-13)

| Cron | Nota | Status |
|:-----|:----:|::------|
| Commander Knowledge Deep | 8.0/10 | ✅ Ativo, 109 execuções; sem referências a "BATTLE-VALIDATED" desde Exec #13 |
| Game Changer Research | 7.0/10 | ✅ Ativo, 112 execuções; 15 GCs perdidos do card_oracle_cache 🔴 |
| Knowledge Synthesis | 7.5/10 | ✅ Ativo, 53 execuções; HTTP 404 resolvido; provider inconsistente 🟡 |
| MTG Rules Auditor | 0.0/10 | 🔴 CRON BROKEN — skill loading failure (referencia skill inexistente) |
| Mana Base Validator | 7.0/10 | ✅ Ativo; confirmado estável |
| Master Optimizer Preflight | 7.5/10 | ✅ Ativo, 207 execuções; resolveu SQLite read-only |
| **SCORE GERAL** | **4.5/10** | **🔴 BAIXA** |

---

## Scout (f20ac299992b) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório `/opt/data/cron/output/f20ac299992b/` não existe. Prompt não está mais em `jobs.json`.

**O que fazia:** Buscar cartas na user_collection e ranquear por sinergia (Score A+B+C).

### O que fazia certo
- Sistema de Score A (Sinergia) + B (Custo) + C (Evidência) é conceitualmente sólido
- Busca de sinergia Token+Pump, Wipe+Proteção, Recursion são padrões reais de Commander
- Cartas com 0% EDHREC que são boas (Spiteful Banditry, Xorn) — conceito correto, limitação de dados

### O que fazia errado
1. **Prompt virou "Wincon Hunter" (Gap 11 do MTG Domain):** Nas últimas 10 execuções antes do descomissionamento, 9 retornaram [SILENT]. O prompt original era uma busca completa EDHREC JSON → cross-ref user_collection → Score A+B+C. O "Wincon Hunter" só buscava `card_deck_analysis` com speed/resilience/stealth scoring — função radicalmente diferente.

2. **94% [SILENT]:** O short-circuit era excessivamente agressivo. Se o deck não mudava (hash idêntico), respondia [SILENT] mesmo quando a análise anterior continha erros (Gap 17 — Short-Circuit Perpetua Erros).

3. **Sem verificação de color identity (impacto ALTO):** O prompt e o código não tinham verificação explícita de color identity antes de recomendar cartas. Uma recomendação de carta que não pode estar no deck por restrição de cor é lixo — e o sistema não detectava.

4. **Sem verificação de banlist (impacto MÉDIO):** Não havia verificação Scryfall ou PG de legalidade Commander antes de recomendar. O banlist sync PG→SQLite (Gap 16) foi implementado posteriormente, após o descomissionamento.

5. **Score A+B+C não usava dados reais:** Dependia de cache local da user_collection que podia estar stale.

### Recomendações
- Se reativado, o prompt deve RESTAURAR a busca EDHREC + coleção + sinergia A+B+C
- Adicionar verificação obrigatória de color identity e banlist antes de recomendar
- Nunca usar pure % EDHREC como métrica única — contexto de sinergia pesa mais
- Quebrar o short-circuit quando a última análise teve discrepâncias

---

## Validator (712579b15767) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório não existe. Última execução foi SILENT. Prompt não está mais em `jobs.json`.

**O que fazia:** Análise estrutural do deck + SYNERGY_MAP (5 eixos: Token+Pump, Wipe+Proteção, Recursion, Mana Explosiva, Combo Pieces).

### O que fazia certo
1. **SYNERGY_MAP de 5 eixos:** Cobre os principais padrões de Commander (aggro/token, control/wipe, recursion/graveyard, fast mana/ritual, combo).
2. **Níveis de importância 1-5:** Sistema conceitual de priorização — wincon tem impacto maior que filler.
3. **Detecção de double-null:** Identificava cartas sem função clara (ex: Scroll Rack, Penance — Gap 6). Isso é valioso mesmo que o sistema não pudesse classificá-las.
4. **CMC curve analysis:** Monitorava distribuição de CMC e detectava anomalias (CMC=0.0, curva achatada).

### O que fazia errado
1. **SYNERGY_MAP incompleto (impacto ALTO — Gap 4):** 5 eixos não cobrem Commander completo. Faltam dimensões estratégicas essenciais:
   - **Stack Interaction** — counterspells, responses. Deck sem counters em meta azul = grande gap
   - **Graveyard Hate** — sem graveyard hate em meta de recursion = receita para perder
   - **Life Gain** — relevante contra aggro/burn; relevante para ad nauseam/pay life engines
   - **Mill Protection** — nicho, mas em meta de mill, um deck sem proteção é frágil
   - **Stax/Tax Effects** — Rhystic Study, Smothering Tithe, Drannith Magistrate — dimensão estratégica própria

2. **Archetype Mismatch não detectado (Gap 4 — agravado 2026-06-03):** Quando o deck é reconstruído externamente para um arquétipo diferente, o validator reportava CRITs em massa (+6 a +15 em todas as métricas) porque o perfil PG pertencia ao arquétipo original. Isso gera falsos positivos que desperdiçam atenção.

3. **Distinção wincon vs payoff ausente (impacto MÉDIO):** O Validator tratava wincon e payoff como intercambiáveis, mas são conceitos diferentes:
   - **Wincon:** carta que fecha o jogo (Torment of Hailfire, Approach of the Second Sun)
   - **Payoff:** carta que se beneficia do motor do deck (Guttersnipe em spellslinger, mas não ganha o jogo)

4. **Análise de CMC considerava dados corrompidos (impacto ALTO):** O Gap 19 (CMC corrompido — 26.6-35% das cartas com CMC=NULL/0.0) persistiu por toda a vida do Validator. A curva de mana e os ranges de perfil PG operavam com dados inválidos.

### Recomendações
- Expandir SYNERGY_MAP para incluir Stack Interaction, Graveyard Hate, Tax/Stax, Life Gain
- Adicionar detecção de Archetype Mismatch: comparar `decks.archetype` contra temas do perfil PG
- Separar wincon de payoff no classificador
- Nunca operar com CMC corrompido — rodar fix_cmc_batch.py antes de validar
- Adicionar verificação de legalidade Commander (banlist + color identity)

---

## Mulligan (08468451a06a) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório não existe. Prompt não está mais em `jobs.json`.

**O que fazia:** Simulação de 1.000 mãos, mede T3 consistency (Sem Play T3).

### O que fazia certo
1. **London Mulligan implementado:** 7 cards iniciais, bottom N (número igual ao número de mulligans), primeira mão grátis em multiplayer. ✅ Conforme CR 103.4c.
2. **Definição de "jogável":** 2-4 lands + pelo menos 1 ramp, OU 3+ lands. ✅ Conceito correto para Commander.
3. **T3 consistency:** Verifica se há spell com CMC ≤ min(terrenos desvirados, 3) no turno 3. ✅ Métrica útil.
4. **N=1000:** Amostra estatisticamente significativa para detecção de mudanças > 1pp.

### O que fazia errado
1. **Tapped lands ignorados (impacto ALTO — Gap 9):** Terrenos que entram tapped (Temple of Triumph, Boros Garrison, etc.) eram tratados como untapped no turno de entrada. Isso infla o T3 reportado — na realidade, o jogador teria 1 mana a menos no turno em que a land entra.

2. **T1 ramp definition inflada (impacto ALTO — Gap 15 original):** A definição de "ramp que funciona no T1" não filtrava por CMC e função real:
   - Sol Ring (CMC 1 → 2 mana) ✅ correto
   - Land Tax (CMC 1 → busca 3 lands, NÃO dá mana no T1) ❌ falso ramp
   - Weathered Wayfarer (CMC 1 → busca land, NÃO dá mana no T1) ❌ falso ramp
   
   Isso infla a % de mãos jogáveis no T1 em ~3-8pp. **Corrigido post-mortem** (Gap 15 resolvido em 2026-06-03, após o descomissionamento).

3. **Color screw não simulado (impacto MÉDIO — Gap 9):** Mão com 3 Mountains + 2 spells brancos era considerada "jogável" mesmo sem mana branca disponível. Em Commander 2-3 cores, isso é uma falha grave — mão sem a cor certa = mulligan na vida real.

4. **Sem draws futuros (impacto BAIXO):** Só avaliava mão inicial, não draws dos turnos 1-3. Isso subestima ligeiramente a jogabilidade (draws podem consertar a mão).

5. **Dependia de tags corrompidas (impacto ALTO — Gap 19):** O classificador de ramp (Gap 15 original) só detectava 6 das 16 cartas de ramp reais no deck Lorehold. O Mulligan baseava sua definição de "mão jogável" no número de cartas tagged 'ramp' — com apenas 6 tags, o T3 era drasticamente subestimado no caso real (17.7% vs 8.9% real).

### Recomendações
- Implementar tapped land tracking: se a land tem "enters the battlefield tapped" no oracle_text, não conta como mana disponível no turno em que entra
- Filtrar T1 ramp: só cartas com CMC ≤ 1 que efetivamente produzem mana adicional no mesmo turno
- Simular color screw: tracking de cores disponíveis vs cores necessárias para spells na mão
- Simular draws dos turnos 1-3 para melhor precisão
- Sincronizar definição de ramp com o classificador funcional corrigido

---

## Battle (94f8590b1beb) — Auditoria Detalhada (v8)

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório `/opt/data/cron/output/94f8590b1beb/` foi removido desde v3.4. Código `battle_simulator.dart` (879 linhas) permanece no repositório em `server/lib/ai/battle_simulator.dart`. **Endpoint de produto `/ai/simulate` usa este código.**

**O que afirmava fazer:** Simulação de jogo 4-player com Priority/Stack/Miracle.

### Realidade — Auditoria Linha a Linha contra CR

#### Estrutura Geral ✅
- Turnos alternados playerA → playerB ✅
- Phases: untap → upkeep → draw → main1 → combat → main2 → end ✅
- Life total inicial 40 (Commander default) ✅
- Shuffle, draw, discard to hand size ✅

#### Priority/Stack (CR 117.3-117.4) ❌ NÃO IMPLEMENTADO
Linha 9: `"Sem stack complexo (resolução imediata)"`. Isso significa:
- Spells resolvem instantaneamente — oponentes NÃO podem responder
- Counterspells são impossíveis — todo o eixo de interação azul está ausente
- **Score: 0/10** — sem stack, não é MTG

#### Commander Damage (CR 903.10a) ❌ NÃO IMPLEMENTADO
- `_determineWinner()` (linha 851-862): só verifica life ≤ 0 ou library.isEmpty
- Nenhuma verificação de 21 damage de commander
- Nenhum conceito de "commander" no código (não há flag `isCommander`)
- **Score: 0/10**

#### Commander Tax (CR 903.8) ❌ NÃO IMPLEMENTADO
- Nenhum tracking de quantas vezes um commander foi jogado da command zone
- Nenhum aumento de CMC em +2 por cast
- Nenhuma command zone no modelo
- **Score: 0/10**

#### Command Zone & Graveyard ❌ NÃO IMPLEMENTADO
- `PlayerState` (linha 128-171): tem `battlefield`, `graveyard`, `library`, `hand`
- Mas não tem command zone, exile, ou stack
- Spells exile/resolvem para o graveyard, mas não há tracking de exílio separado
- **Score: 0/10**

#### Multiplayer (CR 802.1a) ❌ 2-PLAYER APENAS
- `playerA` e `playerB` (linha 239-240) — hardcoded 2 players
- Nenhum loop ou estrutura para N players
- Split de ataque (dividir atacantes entre múltiplos oponentes) impossível
- **Score: 0/10**

#### State-Based Actions (CR 704) ❌ NÃO IMPLEMENTADO
- `_checkGameOver()` (linha 843-849): só verifica life e library
- Não verifica:
  - Jogador com 10+ poison counters (perde) ❌
  - Criatura com toughness ≤ 0 (morre) — **parcialmente implementado** via `_destroyCreature` em combate, mas não como SBA
  - Planeswalker com 0 loyalty ❌
  - Auras anexadas a permanentes ilegais ❌
  - Legend Rule (CR 704.5j) ❌
- **Score: 1/10** (parcial para combat damage tracking)

#### Combat (CR 509-510) 🟡 PARCIAL
- Declare attackers (linha 722-762): ✅ IA escolhe atacantes
- Tap attackers (exceto vigilance): ✅ Correto
- **1 blocker per attacker** (linha 764-815) ❌ — MTG permite múltiplos bloqueadores (CR 509.1a)
- First strike timing: ✅ par correto — resolve antes do dano normal
- Trample (linha 497-499): ✅ implementado — dano excedente passa para jogador
- Lifelink (linha 464-465, 502-504): ✅ sem cap
- Deathtouch (linha 476, 481, 489, 493): ✅ implementado — qualquer dano é letal
- Flying evasion: ✅ parcial — só flyers bloqueiam flyers
- Dano simultâneo (linha 485-493): ✅ correto — ambos aplicam dano antes de verificar morte
- **Score: 5/10**

#### IA Decisions 🟡 SIMPLIFICADO
- AI prioritiza: land → ramp (T1-T4) → draw (se mão ≤ 3) → removal (se threat ≥ 4 power) → wipe (se 3+ criaturas oponente) → criaturas (maiores primeiro)
- **Score: 4/10** — estratégia simplista, não simula tomada de decisão real

#### Win Conditions (CR 104) ❌ INCOMPLETO
- Life depletion ✅
- Deck out (library vazia ao draw) ✅
- Timeout (vida > ou battlefield >) ❌ — não é regra MTG
- **Score: 2/10**

### Impacto no Produto 🔴 CRÍTICO
O endpoint `/ai/simulate` usa este código. Os resultados são apresentados como "simulação de batalha" para o usuário/Codex, mas a fidelidade ao MTG real é de aproximadamente **2/10**. Qualquer decisão de deckbuilding baseada nestes resultados (como os cortes propostos pelo Universal Optimizer — Smothering Tithe, Imperial Recruiter, Generous Gift) é potencialmente contraproducente.

### Comparação com Python battle_analyst_v8.py (5275 linhas)
- Python tem Priority System, Stack LIFO, Commander Damage, Commander Tax, Multiplayer, London Mulligan, State-Based Actions, Colored Mana
- **Score estimado: 7.0/10**
- Não é usado por nenhum cron ativo — está em `docs/hermes-analysis/`

### Recomendações
1. 🔴 **Imediato:** Adicionar disclaimer ao endpoint `/ai/simulate` que a simulação não segue regras oficiais de Commander
2. 🔴 **Imediato:** Migrar produção para o Python `battle_analyst_v8.py` ou reconstruir o Dart com regras Commander
3. 🔴 **Nunca usar "BATTLE-VALIDATED":** Dados do Battle Simulator são "SIMULATION-INDICATED" apenas — comparação entre builds do mesmo simulador, não validação contra jogo real
4. 🟡 Adicionar stack, Commander damage, Commander tax, multi-blocker ao Dart

---

## Evolution Oracle (a50bef4c2a59) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório não existe. Prompt não está mais em `jobs.json`. Script `manaloom-wincon-oracle.sh` CONFIRMADO FUNCIONAL.

**O que fazia:** Ler logs de todos os agentes e decidir swaps (0 a 3).

### O que fazia certo
1. **Base conceitual:** Sistema de swap baseado em logs de múltiplos agentes é uma boa arquitetura — cruzar Scout + Validator + Mulligan para decidir swaps. **Se todos os agentes funcionassem.**
2. **Cadência 0-3 swaps:** Limitar swaps por execução evita mudanças radicais em um único ciclo.
3. **Script funcional:** `manaloom-wincon-oracle.sh` existe, roda e produz output.

### O que fazia errado
1. **Death Loop Autossustentável (Gap 12, confirmado v3.6-v3.10):** Oracle falha (timeout) → demais agentes SILENT → Oracle lê logs "nada mudou" → SILENT → repete. O ciclo não se autocorrige — requer intervenção externa (--force ou mudança de deck).

2. **Miracle mechanic mal interpretado (Gap 12, 🔴 CRÍTICO):** O prompt afirmava que Lorehold "reduz CMC para {2}" via Miracle. Lorehold COPIA spells do cemitério, não reduz CMC. A redução de {2} é do keyword Miracle (CR 702.94), condicional a comprar como primeiro card do turno. Análises baseadas em custo reduzido estavam incorretas.

3. **Dados de entrada inválidos:** O Oracle dependia de:
   - Scout (94% SILENT, prompt era Wincon Hunter)
   - Validator (análise com CMC corrompido — 26.6%)
   - Mulligan (análise com ramp tags corrompidas — 6 de 16)
   - Battle (simulador 2/10 sem regras Commander)
   - **Entrada inválida → saída inválida.** Garbage in, garbage out.

4. **Priorização questionável (impacto ALTO):** O Oracle propunha cortar staples Commander (Smothering Tithe, Imperial Recruiter, Generous Gift, Past in Flames — Gap 20) baseado exclusivamente em dados de simulador inválido. Cortar cartas com 40%+ de inclusão EDHREC sem revisão humana é contraproducente.

5. **Prompt 48h+ sem execução completa (v3.6-v3.10):** Devido ao timeout do provider (deepseek-v4-pro), o Oracle nunca completava análise. Output truncado após 1 tool call.

6. **Referência a wincon_pipeline.py inexistente:** Script mencionava arquivo que nunca existiu.

### Recomendações
- Se reativado, executar com `--force` e timeout ≥ 300s
- Corrigir prompt: Lorehold COPIA spells, não reduz CMC (remover referência a Miracle)
- Nunca usar dados do Battle Simulator 2-player para decisões de swap
- Adicionar verificação EDHREC ≥ 30% como proteção contra corte de staples
- Implementar reset protocol: quando hash do deck diverge, recalcular métricas do zero
- Trocar provider para deepseek-v4-flash (mais rápido, menos timeout)

---

## MTG Rules Auditor (c0591cb18024) — Reflexão 🔴

**Este auditor é o cron que produziu v1.0-v10.0.** É imperativo documentar seu próprio estado:

### Estado Atual
- **Última auditoria real:** 2026-06-09 13:36Z (v9.0, 78858 bytes)
- **3+ dias sem auditoria real** (desde 2026-06-09 13:36Z)
- **8+ execuções FAILED consecutivas** desde 2026-06-08 13:50Z
- Skills carregados: `manaloom-commander-knowledge` (❌ não encontrado), `manaloom-mtg-domain` (✅ disponível)
- Prompt ainda referencia 5 IDs de crons descomissionados (f20ac299992b, 712579b15767, etc.)
- **Pipeline score (autoavaliação): 1.0/10 🔴**

### Problemas do Prompt
1. **Skill loading failure:** Referencia `manaloom-commander-knowledge` que não existe no repositório. Quando falha, o agente despeja 60047 bytes do `manaloom-mtg-domain` e termina.
2. **IDs stale:** `f20ac299992b`, `712579b15767`, `08468451a06a`, `94f8590b1beb`, `a50bef4c2a59` — todos descomissionados em v3.7.
3. **Schedule:** Foi reduzido de 180min para 720min (menos desperdício), mas isso só mascara o problema.

### Fix Necessário
1. Migrar prompt para usar `manaloom-mtg-domain` (disponível) ao invés de `manaloom-commander-knowledge` (ausente)
2. Remover IDs de crons descomissionados do prompt
3. Reduzir schedule para 360min após fix (original era 180min)
4. Adicionar verificação de skill loading no início do prompt

---

## Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (quebra o jogo ou distorce resultados gravemente)

1. **Battle Simulator Dart — 2/10 fidelidade MTG (Gap 8, Gap 29)**
   - **Impacto:** Endpoint `/ai/simulate` produz resultados que não refletem Commander real. Universal Optimizer propõe cortar staples baseado nestes dados.
   - **Código:** `server/lib/ai/battle_simulator.dart:9` — "Sem stack complexo (resolução imediata)"
   - **Fix:** Migrar para Python `battle_analyst_v8.py` (7/10 fidelity) ou reconstruir Dart com stack, Commander damage, tax, multiplayer, multi-blocker.

2. **MTG Rules Auditor — skill loading failure (Gap 29)**
   - **Impacto:** 8+ execuções consecutivas FAILED. Pipeline score: 1.0/10.
   - **Fix:** Migrar prompt de `manaloom-commander-knowledge` para `manaloom-mtg-domain`. Remover 5 IDs de crons descomissionados.

3. **CMC corrompido — 35/100 cartas (35%) no deck ativo (Gap 19)**
   - **Impacto:** Toda métrica que depende de CMC (curva de mana, goldfish simulator, mulligan simulation, quality gate) opera com dados inválidos.
   - **DB:** `deck_cards.cmc IS NULL OR cmc = 0` — 35 cartas no deck 6.
   - **Fix:** Executar script `fix_cmc_batch.py` para corrigir via PostgreSQL `cards.cmc`. Pendente desde 2026-06-05 (>7 dias).

4. **15 GCs perdidos do card_oracle_cache (28.3%) (Gap 27)**
   - **Impacto:** Game Changer Research não pode auditar GCs completos localmente. Hipótese: sync PG→SQLite filtra banned cards e DFCs.
   - **Fix:** Executar `scripts/gc_cache_analyzer.py` para verificar 53 GCs. Adicionar verificação pós-sync. Restaurar via Scryfall API ou corrigir script de import.

### 🟡 ALTO (distorce resultados ou reduz confiabilidade)

5. **Bracket categories — SQLite reclassificou 3 categorias para `other` (Gap 25)**
   - **Impacto:** 3/5 categorias originais com zero cartas (`tutor=0`, `extraTurns=0`, `infiniteCombo=0`). 88% dos GCs detectados colapsaram em `other`.
   - **Fix:** Restaurar `bracket_category` para Force of Will, Bolas's Citadel. Reclassificar 12 tutores. Adicionar teste de regressão.

6. **Universal Optimizer — propõe cortar staples Commander (Gap 20)**
   - **Impacto:** Smothering Tithe, Imperial Recruiter, Generous Gift, Past in Flames todos candidatos a corte baseados em simulador 2/10.
   - **Blocked by:** PermissionError em `battle_analyst_v8.py` (root-owned) — mitigação acidental.
   - **Fix:** Adicionar proteção: nunca cortar cartas com EDHREC ≥ 30% sem revisão humana.

7. **Commander Knowledge Deep — provider inconsistente**
   - **Impacto:** Usa `opencode-go` enquanto resto da frota usa `deepseek-pro`. HTTP 429 e 404 já causaram falhas (Gap 21 — resolvido).
   - **Risk:** Risco de falha futura. Migrar para `deepseek-pro`.

8. **Auto-promote-learned — quebrado (missing table `deck_promotions`)**
   - **Impacto:** 22 execuções, erro consistente: `OperationalError: no such table: deck_promotions`
   - **Fix:** Criar tabela `deck_promotions` no SQLite ou corrigir script para usar tabelas existentes.

### 🟢 MÉDIO (imprecisão ou melhoria)

9. **Double-null detection — 10%+ cartas invisíveis (Gap 6)**
   - **Impacto:** Cartas essenciais (Scroll Rack, Penance, Grand Abolisher) podem ser recomendadas para corte por serem "invisíveis" ao classificador.
   - **Fix:** Adicionar heurísticas de fallback para cartas conhecidas como double-null.
   - **Nota:** Atual DB de 1 deck tem 0 unknown tags — pode ter melhorado com sync, mas código Dart ainda vulnerável.

10. **Speed da frota — deepseek-v4-pro causa timeouts históricos**
    - **Impacto:** Evolution Oracle histórico tinha timeout consistente (Gap 12). Commander Knowledge Deep usava deepseek-v4-pro e falhava.
    - **Recomendação:** Manter deepseek-v4-flash para crons de curto ciclo (<360min) e deepseek-v4-pro apenas para análises profundas (>720min).

### 🟢 BAIXO (cosmético ou procedural)

11. **Git push — 18+ commits ahead sem credenciais**
    - **Impacto:** Commits locais não pushados. Perda de rastreabilidade.
    - **Fix:** Configurar credenciais Git no ambiente cron ou push manual.

12. **Prompt do MTG Rules Auditor — referências stale**
    - **Impacto:** Confusão documental. 5 IDs de crons que não existem mais.
    - **Fix:** Atualização do prompt (parte do item #2 acima).

---

## Conclusão

A pipeline Lorehold (5 crons) foi **descomissionada em 2026-06-04 (v3.7)** por Death Loop autossustentável. O código permanece no repositório e pode ser reativado, mas **nenhum dos 5 crons tem output confiável ou fidelidade MTG aceitável isoladamente.**

**A nota mais baixa é do Battle (2.0/10)** — um simulador 2-player sem stack, sem Commander damage, sem Commander tax, sem multi-blocker. É o gap mais crítico porque o endpoint `/ai/simulate` está em produção e resultados são usados como "simulação de batalha".

**A nota do MTG Rules Auditor caiu para 0.0/10** porque o cron referencia um skill que não existe (`manaloom-commander-knowledge`), produzindo apenas skill dumps em vez de auditorias. A última auditoria real foi há **3+ dias**.

**O ecossistema atual está dividido:**
- Camada de conhecimento (Commander Deep, Game Changer, Synthesis): ✅ Funcionando, 53-112 execuções acumuladas
- Camada de infraestrutura (scripts sem agente): 🟡 Funcionando com gaps conhecidos (PermissionErrors, tabelas faltantes)
- **Camada de auditoria (MTG Rules Auditor):** 🔴 Quebrada — zero output útil

**O CMC corruption (35/100, 35%) persiste como o problema técnico mais antigo sem correção** — descoberto em 2026-06-05, >7 dias sem fix. Qualquer métrica que dependa de CMC (curva, mulligan, quality gate) opera com dados parcialmente inválidos.

**Pipeline score geral: 4.5/10 🔴 BAIXA** — estável, mas estagnada. Os mesmos problemas persistem sem intervenção há dias.
