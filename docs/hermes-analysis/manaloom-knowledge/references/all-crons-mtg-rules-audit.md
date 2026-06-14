# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v11.0
**Data:** 2026-06-14T01:30:00+00:00
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`) — execução manual (cron automático continua broken por skill loading failure)
**Escopo:** Full pipeline Lorehold descomissionado (5 crons) + ecossistema ativo de 15+ crons + linha-a-linha battle_simulator.dart (879 linhas) + goldfish_simulator.dart (613 linhas) + functional_card_tags.dart (1092 linhas) + edh_bracket_policy.dart (547 linhas)

### Metodologia
- Leitura completa dos 5 arquivos-fonte do pipeline de produto
- Verificação linha a linha contra MTG Comprehensive Rules (CR)
- Comparação entre crons Lorehold descomissionados e código ativo em produção
- Consulta a `jobs.json` para prompts atuais (confirmado: Lorehold IDs removidos em v3.7)

---

## Sumário Executivo

### Pipeline Lorehold (Descomissionado v3.7, código permanece)

| Cron | Nota | Confiabilidade | Gaps Críticos |
|:-----|:----:|:--------------|:---------------|
| Scout | 4.0/10 | BAIXA | Prompt "Wincon Hunter" desalinhado; 94% [SILENT] no descomissionamento |
| Validator | 7.0/10 | MÉDIA | SYNERGY_MAP incompleto (stack interaction, gy hate ausentes); Archetype Mismatch não detectado |
| Mulligan | 6.5/10 | MÉDIA | Tapped lands ignorados; T1 ramp inflado; color screw não simulado |
| Battle | 2.0/10 | 🔴 CRÍTICA | 2-player, sem stack/priority, sem Commander damage/tax, sem multi-blocker |
| Evolution Oracle | 3.5/10 | BAIXA | Death loop autossustentável; dependia de dados inválidos de todos os outros crons |
| **PIPELINE** | **4.5/10** | **🔴 BAIXA** | **Descomissionado — código legado sem crons ativos** |

### Ecossistema Atual (Crons Ativos 2026-06-14)

| Cron | Nota | Status |
|:-----|:----:|:------:|
| Commander Knowledge Deep | 8.0/10 | ✅ Ativo, 113 execuções; sem "BATTLE-VALIDATED" desde Exec #13 |
| Game Changer Research | 7.0/10 | ✅ Ativo, 114 execuções; 15 GCs perdidos do card_oracle_cache 🔴 |
| Knowledge Synthesis | 7.5/10 | ✅ Ativo, 57 execuções; HTTP 404 resolvido; provider inconsistente 🟡 |
| Mana Base Validator | 7.0/10 | ✅ Ativo (no_agent); script funcional, 57 execuções |
| Master Optimizer Preflight | 7.5/10 | ✅ Estável, SQLite read-only resolvido; 207+ execuções |
| Goldfish Simulator (prod) | 7.0/10 | ✅ Ativo no endpoint; color tracking implementado 🆕 |
| **MTG Rules Auditor** | **0.0/10** | **🔴 CRON BROKEN** — skill loading failure (referencia skill inexistente) |
| **SCORE GERAL** | **4.5/10** | **🔴 BAIXA — estagnada** |

---

## Scout (f20ac299992b) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório `/opt/data/cron/output/f20ac299992b/` não existe (removido). Prompt removido de `jobs.json`.

**O que afirmava fazer:** Buscar cartas na user_collection e ranquear por sinergia (Score A+B+C).

### O que fazia certo
- **Score A+B+C: Sinergia + Custo + Evidência** — sistema conceitualmente sólido, inspirado em deckbuilding real
- **Padrões de sinergia corretos:** Token+Pump, Wipe+Proteção, Recursion Chain são padrões reais de Commander
- **Reconhecia cartas 0% EDHREC boas:** Spiteful Banditry, Xorn — conceito correto (EDHREC não é verdade absoluta)

### O que fazia errado (verificado contra CR e EDHREC)
1. **🔴 Prompt "Wincon Hunter" — função completamente diferente do original:** Nas últimas 10 execuções, 9 retornaram [SILENT]. O "Wincon Hunter" só buscava `card_deck_analysis` com speed/resilience/stealth — perdendo a busca EDHREC + coleção + sinergia original.

2. **🔴 94% [SILENT] — Short-circuit agressivo (Gap 17):** Se o deck não mudava (hash idêntico), respondia [SILENT] mesmo quando a análise anterior continha erros (Worldfire banida erroneamente, etc.). O short-circuit perpetuava erros permanentemente.

3. **🔴 Sem verificação de color identity:** Não havia filtro antes de recomendar cartas. Uma recomendação de carta fora da identidade de cor do commander é lixo — e o sistema não detectava. CR 903.4c violado por omissão.

4. **🟡 Sem verificação de banlist:** Não consultava Scryfall ou PG sync antes de recomendar. O banlist sync PG→SQLite (Gap 16) foi implementado depois do descomissionamento.

5. **🟡 Score A+B+C dependia de cache local stale:** A user_collection local podia estar desatualizada, gerando recomendações baseadas em dados obsoletos.

### Recomendações
- Se reativado: restaurar prompt original (EDHREC + coleção + sinergia A+B+C)
- Adicionar verificação obrigatória: `color_identity` do commander vs carta; `card_legalities.commander != 'banned'`
- Short-circuit deve verificar `discrepancies_found > 0` antes de decidir silêncio

---

## Validator (712579b15767) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido. Prompt removido de `jobs.json`.

**O que afirmava fazer:** Análise estrutural do deck + SYNERGY_MAP (5 eixos).

### O que fazia certo
1. **SYNERGY_MAP (Token+Pump, Wipe+Proteção, Recursion, Mana Explosiva, Combo Pieces):** Cobre os principais padrões de Commander. Conceitualmente correto.
2. **Níveis 1-5 de importância:** Wincon > proteção > draw > ramp > filler — alinhado com deckbuilding real.
3. **Detecção de double-null:** Identificava cartas sem função (Scroll Rack, Penance). Mesmo que o classificador não pudesse dar tag, reportava o gap.
4. **CMC curve analysis:** Detectava anomalias como CMC=0.0 e curva achatada.

### O que fazia errado
1. **🔴 SYNERGY_MAP incompleto (Gap 4):** 5 eixos não cobrem Commander:
   - **Stack Interaction** (CR 117) — counterspells, responses. Deck sem counters em meta azul = gap crítico
   - **Graveyard Hate** — Rest in Peace, Grafdigger's Cage são dimensão estratégica própria
   - **Life Gain** — relevante contra aggro/burn; Ad Nauseam protection
   - **Mill Protection** — nicho, mas real
   - **Stax/Tax** — Rhystic Study, Smothering Tithe, Drannith Magistrate — dimensão estratégica completa

2. **🔴 Archetype Mismatch não detectado (Gap 4 — agravado):** Quando deck reconstruído externamente (ex: spellslinger → cEDH combo), validator reportava CRITs em massa (+6 a +15) porque o perfil PG era do arquétipo original. Todos falsos positivos.

3. **🟡 Wincon vs payoff confundidos:** Tratava wincon e payoff como intercambiáveis. Torment of Hailfire (wincon) vs Guttersnipe (payoff) são conceitos diferentes:
   - **Wincon:** carta que fecha o jogo sozinha ou em combo
   - **Payoff:** carta que se beneficia do motor mas não ganha o jogo diretamente

4. **🟡 CMC corrompido (Gap 19):** 26.6-35% das cartas com CMC NULL/0.0. Curva de mana e ranges de perfil PG operavam com dados inválidos.

### Recomendações
- Expandir SYNERGY_MAP: Stack Interaction, Graveyard Hate, Stax/Tax
- Detectar Archetype Mismatch: comparar `decks.archetype` vs temas do perfil PG
- Separar wincon de payoff — são categorias diferentes no jogo real
- Executar `fix_cmc_batch.py` antes de qualquer validação

---

## Mulligan (08468451a06a) — Auditoria Detalhada vs GoldfishSimulator Ativo

**Estado do cron:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido. Prompt removido de `jobs.json`.

**Estado do código ativo:** 🟢 `server/lib/ai/goldfish_simulator.dart` (613 linhas) — presente em produção, endpoint ativo. **Não era o código do cron Lorehold, mas o herdeiro funcional.**

### O que o código Ativo (`goldfish_simulator.dart`) faz certo

O `GoldfishSimulator` é significativamente melhor que o cron Mulligan original:

1. **✅ Simula draws dos turnos 1-4** (linhas 159-205): O cron original só via mão inicial. O `GoldfishSimulator` compra cartas simuladas para turnos 1-4, melhorando precisão. **(Era fraqueza do cron original — Gap 9)**

2. **✅ Color source tracking implementado** (linhas 171, 268-290): Extrai `{W}`, `{U}`, `{B}`, `{R}`, `{G}` do `mana_cost` via regex e rastreia cores produzidas por terrenos. Mão com 3 Mountains + 2 spells azuis é corretamente sinalizada como não jogável. **(Era fraqueza do cron original — color screw não simulado)**

3. **✅ Land color detection** (linhas 293-301+): Usa tipo de terreno no type_line para determinar cores (Plains→W, Island→U, etc.). Shocks, duals, fetchlands parcialmente suportados.

4. **✅ N=1000 simulações** (linha 132): Amostra estatisticamente significativa. ∆ < 1.6pp.

5. **✅ London Mulligan tracking** (linhas 157-161): Mão inicial de 7 cartas.

### O que o código Ativo ainda faz errado — e o cron original também

1. **🔴 Tapped lands NÃO são detectados** (linhas 258-261): `_isLand()` só verifica `typeLine.contains('land')`. Terrenos como Temple of Triumph, Boros Garrison, Shocklands (quando não pagam 2 life) são tratados como untapped na hora que entram. **Herda Gap 9 do cron original.**

2. **🟡 T1 ramp detection é simplificado** (linha 176-178): `_canPlayOnTurn()` verifica se há carta com CMC ≤ lands disponíveis. Mas não filtra se a carta é realmente ramp que funciona no T1. Sol Ring ativa T1? ✅ Land Tax ativa T1? ❌ (não produz mana). **Herda Gap 15 parcialmente.**

3. **🟡 CMC safety wrapper** (linha 264-266): Usa `safeCmcForOptimization()` do `cmc_safety.dart` (3-tier fallback). Mitiga CMC=0.0, mas não corrige a raiz. CMC corrompido distorce a distribuição.

4. **🟡 Sem verificação de "enters tapped" no oracle_text:** Nenhum parsing de `oracle_text` para detectar "enters the battlefield tapped". Significa que o T3 reportado é melhor que o real em ~3-8pp.

5. **✅ Color screw significativamente melhor** que o cron original (que não simulava cor alguma). Agora simula color source tracking, mas só para cartas com `mana_cost` presente — cartas com `mana_cost=''` ou NULL (especialmente DFCs, cartas sem custo) são ignoradas.

### Comparação direta: Mulligan Cron vs GoldfishSimulator

| Característica | Cron Lorehold (descomissionado) | GoldfishSimulator (produção) |
|:---------------|:-------------------------------:|:--------------------------:|
| Simula draws T1-4 | ❌ Só mão inicial | ✅ Linhas 159-205 |
| Color screw check | ❌ | ✅ Linhas 171, 268-290 |
| Tapped land detection | ❌ | ❌ Nenhum dos dois |
| T1 ramp filter | ❌ | 🟡 Parcial |
| CMC safety fallback | ❌ | ✅ cmc_safety.dart |
| N=1000 | ✅ | ✅ |
| London Mulligan | ✅ | ✅ |
| **SCORE** | **6.5/10** | **7.0/10 🟢** |

### Recomendações
1. 🔴 **Adicionar detecção de "enters tapped":** Verificar `oracle_text.contains('enters the battlefield tapped')` ou `oracle_text.contains('tapped')` para terrenos
2. 🟡 **Refinar T1 ramp:** Filtrar `_canPlayOnTurn()` para só considerar ramp que efetivamente produz mana no turno em que é jogada (Sol Ring ✅, Land Tax ❌)
3. 🟡 **Melhorar land color detection para fetchlands:** Fetchlands não produzem mana diretamente — precisam buscar outra land. O `_getLandColors()` atual trata fetchlands como sem cor.

---

## Battle (94f8590b1beb) — Auditoria Detalhada (v8)

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório `/opt/data/cron/output/94f8590b1beb/` removido desde v3.4. Código `battle_simulator.dart` (879 linhas) permanece no repositório em `server/lib/ai/battle_simulator.dart`. **Endpoint de produto `/ai/simulate` usa este código.**

**O que afirmava fazer:** Simulação de jogo 4-player com Priority/Stack/Miracle.
**Realidade:** **2.0/10 🔴** — simulador 2-player sem regras fundamentais de Commander.

### Auditoria Linha a Linha contra MTG Comprehensive Rules

#### Estrutura Geral (linhas 1-279, 828-879) ✅ Parcial

| Característica | Status | Linha | Verificação CR |
|:--------------|:------:|:-----:|:---------------|
| Turnos alternados A→B | ✅ | 259-264 | CR 500.1 |
| Phases: untap→upkeep→draw→main1→combat→main2→end | ✅ | 356-384 | CR 500.2 |
| Life total 40 | ✅ | 140 | CR 903.7 |
| Shuffle, draw, discard to 7 | ✅ | 290-291, 398-401, 530-544 | CR 701.17, CR 120 |
| Max turns = 30 | ✅ | 247 | Timeout, não-MTG |
| 7 card initial hand | ✅ | 293-297 | CR 103.4c |

#### Priority/Stack (CR 117.3-117.4) ❌ NÃO IMPLEMENTADO

**Verificação linha 9:** `"Sem stack complexo (resolução imediata)"`

O simulador declara abertamente que não tem stack. Consequências:
- **Spells resolvem instantaneamente** — oponentes NUNCA podem responder (CR 117.3)
- **Counterspells são impossíveis** — todo o eixo de interação azul está ausente (CR 117.4)
- **Instants não têm vantagem de timing** — não há diferença entre instant e sorcery na execução
- **Triggered abilities na stack** — não há "stack" para colocar triggers
- **Split-second, Buyback, Kicker** — todos ignorados

**Score: 0/10** — sem stack, não é MTG. Isso não é Commander — é um jogo de cartas parecido com MTG.

#### Commander Damage (CR 903.10a) ❌ NÃO IMPLEMENTADO

`_determineWinner()` (linhas 851-862):
```dart
if (playerA.life <= 0) return playerB.name;
if (playerB.life <= 0) return playerA.name;
if (playerA.library.isEmpty) return playerB.name;
if (playerB.library.isEmpty) return playerA.name;
// Timeout: quem tem mais vida
if (playerA.life > playerB.life) return playerA;
```

**Nenhuma verificação de 21 damage de commander.** `GameCard` não tem flag `isCommander`. Combat damage tracking não diferencia damage de commander vs normal. **Score: 0/10**

#### Commander Tax (CR 903.8) ❌ NÃO IMPLEMENTADO

**Nenhum tracking de casts da command zone.** `PlayerState` (linhas 128-171) não tem `commandZone` list nem `commanderCastCount`. Toda carta custa seu CMC nominal — não +2 por cast anterior. **Score: 0/10**

#### Command Zone, Exile, Stack ❌ NÃO IMPLEMENTADO

`PlayerState` tem `battlefield`, `graveyard`, `library`, `hand` (linhas 135-138). Mas:
- **sem `commandZone`** (via commander)
- **sem `exile`** (separado de graveyard)
- **sem `stack`** (fila de resolução)

Spells vão direto para o graveyard após resolução (linhas 654-655, 667-668). Exile não existe como zona. **Score: 0/10**

#### Multiplayer (CR 802.1a) ❌ 2-PLAYER APENAS

```dart
late PlayerState playerA; // linha 239
late PlayerState playerB; // linha 240
```

Hardcoded 2 players. Sem loop para N players. **Split de ataque entre múltiplos oponentes impossível** (CR 802.1). Commander é formato multiplayer — jogar 1v1 não reflete o formato. **Score: 0/10**

#### State-Based Actions (CR 704) ❌ QUASE AUSENTE

`_checkGameOver()` (linhas 843-849): só verifica life ≤ 0 e library.isEmpty.

**SBA não implementados:**
- 10+ poison counters → perde (CR 704.5a) ❌
- Criatura com toughness ≤ 0 → morre (CR 704.5f/704.5g) 🟡 **Parcial:** `_destroyCreature` em combate existe (linha 523-528), mas não roda como SBA
- Planeswalker com 0 loyalty → morre (CR 704.5i) ❌
- Aura attached to illegal permanent → graveyard (CR 704.5m) ❌
- Legend Rule (CR 704.5j) ❌
- Token em zona não-battlefield → cease to exist (CR 704.5d) ❌

**Score: 1/10** (crédito por combat damage tracking parcial)

#### London Mulligan (CR 103.4c) ❌ NÃO IMPLEMENTADO

`_initGame()` (linhas 281-303): sempre 7 cartas, sem mulligan. Em Commander:
- Primeira mulligan é grátis (ainda 7 cartas) — CR 103.4c
- Segunda em diante: bottom N (CR 103.4d)
- `_initGame` pula tudo — sempre 7 cartas para ambos

**Score: 0/10**

#### Mana System (CR 601.2f) ❌ NÃO IMPLEMENTADO

```dart
int manaAvailable = 0; // linha 131
```

Mana é **inteiro puro** — sem tipo de mana. `{R}`, `{U}`, `{W}` são ignorados. Um deck monoblue pode pagar `{R}{R}{R}` sem problemas. Sem color screw possível. **Score: 0/10**

#### Combat (CR 509-510) 🟡 PARCIAL (melhor aspecto)

| Aspecto | Status | Linha |
|:--------|:------:|:-----:|
| Declare attackers | ✅ | 722-762 |
| Tap attackers (exceto vigilance) | ✅ | 429-434 |
| **Multi-blocker (CR 509.1a)** | **❌ 1 blocker por attacker** | `Map<GameCard, GameCard> blocks` (linha 768) |
| First strike timing | ✅ | 473-483 |
| Trample damage | ✅ | 497-499 |
| Lifelink (sem cap) | ✅ | 464-465, 502-504 |
| Deathtouch | ✅ | 476, 481, 489, 493 |
| Flying evasion | ✅ | 746-753 |
| Dano simultâneo | ✅ | 485-493 |
| **Commander damage tracking** | **❌** | N/A |

**Score: 5/10** — implementa as 5 keywords principais, mas multi-blocker está ausente.

#### AI Decisions 🟡 SIMPLIFICADO (linhas 551-622)

| Prioridade | Ação | Problema |
|:-----------|:-----|:---------|
| 1 | Play land (sempre) | ✅ Correto |
| 2 | Ramp T1-T4 | 🟡 Só checa isRamp (heuristic text match) |
| 3 | Draw se mão ≤ 3 | 🟡 Não considera card quality |
| 4 | Removal se threat ≥ 4 | 🟡 Threat = power ≥ 4 apenas. Ignora utility/combo |
| 5 | Board wipe se 3+ criaturas | 🟡 Somente numérico, não avalia board state |
| 6 | Creatures maiores primeiro | 🟡 Não considera keywords, enters-the-battlefield |

**Score: 4/10** — Estratégia simplista. Não simula tomada de decisão real de Commander.

#### Win Conditions (CR 104) ❌ INCOMPLETO

| Condição | Status | Nota |
|:---------|:------:|:-----|
| Life depletion | ✅ | CR 104.3a |
| Deck out | ✅ | CR 104.3c |
| **10+ poison counters** | **❌** | CR 104.3b |
| **Commander damage 21** | **❌** | CR 903.10a |
| **"You win the game" cards** | **❌** | Approach of Second Sun, etc. |
| **Timeout (mais vida)** | 🟡 | **Não é regra MTG** — é tiebreak artificial |

**Score: 2/10**

### Score Final: 2.0/10 🔴

| Componente | Max | Score |
|:-----------|:---:|:----:|
| Turn structure & phases | 1.0 | 1.0 ✅ |
| Priority/Stack (CR 117) | 1.5 | 0.0 ❌ |
| Commander Damage (CR 903.10a) | 1.0 | 0.0 ❌ |
| Commander Tax (CR 903.8) | 1.0 | 0.0 ❌ |
| Multiplayer (CR 802) | 1.5 | 0.0 ❌ |
| State-Based Actions (CR 704) | 1.0 | 0.1 🟡 |
| London Mulligan (CR 103.4c) | 0.5 | 0.0 ❌ |
| Combat (CR 509-510) | 1.5 | 0.8 🟡 |
| AI Decisions | 0.5 | 0.2 🟡 |
| Win Conditions | 0.5 | 0.1 🟡 |
| **Total** | **10.0** | **2.2 ≈ 2.0/10** |

### Impacto no Produto 🔴 CRÍTICO

O endpoint `/ai/simulate` usa este código e apresenta resultados como "simulação de batalha". A fidelidade ao MTG real é de **2/10**. Decisões de deckbuilding baseadas nestes resultados (Universal Optimizer propondo cortar Smothering Tithe, Imperial Recruiter, Generous Gift — Gap 20) são potencialmente contraproducentes.

### Comparação com Python battle_analyst_v8.py (5275 linhas)
- Python tem Priority System ✅, Stack LIFO ✅, Commander Damage ✅, Commander Tax ✅, Multiplayer ✅, London Mulligan ✅, State-Based Actions ✅, Colored Mana ✅
- **Score estimado: 7.0/10 🟡**
- **Não usado por nenhum cron ativo** — está em `docs/hermes-analysis/`

### Recomendações
1. **🔴 Imediato:** Adicionar disclaimer ao endpoint `/ai/simulate` que a simulação não segue regras oficiais de Commander
2. **🔴 Imediato:** Migrar produção para Python `battle_analyst_v8.py` ou reconstruir Dart com regras Commander
3. **🔴 Nunca usar "BATTLE-VALIDATED":** Dados do Battle Simulator são "SIMULATION-INDICATED" para comparação entre builds do mesmo simulador apenas
4. **🟡 Adicionar ao Dart:** stack LIFO, Commander damage tracking, Commander tax, multi-blocker, mana colorida

---

## Evolution Oracle (a50bef4c2a59) — Auditoria Detalhada

**Status:** 🔴 DECOMISSIONADO (v3.7, 2026-06-04). Diretório removido. Prompt removido de `jobs.json`.

**O que afirmava fazer:** Ler logs de todos os agentes e decidir swaps (0 a 3). Script `manaloom-wincon-oracle.sh` CONFIRMADO FUNCIONAL.

### O que fazia certo
1. **Base conceitual:** Sistema de swap baseado em logs de múltiplos agentes é boa arquitetura.
2. **Cadência 0-3 swaps:** Limita mudanças radicais.
3. **Script funcional:** `manaloom-wincon-oracle.sh` existe e roda.

### O que fazia errado
1. **🔴 Death Loop Autossustentável (Gap 12):** Oracle falha (timeout) → demais agentes SILENT → Oracle lê logs "nada mudou" → SILENT → repete. **Ciclo de feedback positivo confirmado.** Requer intervenção externa (`--force` ou mudança de deck).

2. **🔴 Miracle mechanic ERRADO no prompt:** O prompt afirmava que Lorehold "reduz CMC para {2}" via Miracle. **Lorehold COPIA spells do cemitério, não reduz CMC.** A redução de {2} é do keyword Miracle (CR 702.94), condicional a comprar como primeiro card do turno. **Análises baseadas em custo reduzido estavam incorretas.**

3. **🔴 Garbage In, Garbage Out:** Dependia de:
   - Scout (94% SILENT, Wincon Hunter desalinhado)
   - Validator (CMC 26.6% corrompido, análise com dados inválidos)
   - Mulligan (ramp tags corrompidas — 6 de 16 reais)
   - Battle (simulador 2/10 sem regras Commander)
   - **Todo dado de entrada era inválido ou incompleto → toda saída era inválida**

4. **🔴 Propunha cortar staples Commander (Gap 20):** Smothering Tithe (40%+ EDHREC), Imperial Recruiter (tutor em deck combo), Generous Gift, Past in Flames — todos candidatos a corte baseados em simulador 2/10.

5. **🟡 Provider timeout:** Provider `deepseek-v4-pro` causava timeout consistente, impedindo execução completa.

6. **🟡 Referência a `wincon_pipeline.py` inexistente:** Script mencionava arquivo que nunca existiu.

### Recomendações
- Se reativado: `--force` + timeout ≥ 300s + provider `deepseek-v4-flash`
- Corrigir prompt: Lorehold COPIA spells (não reduz CMC via Miracle)
- Proteção EDHREC ≥ 30% contra corte de staples
- Reset protocol: quando hash do deck diverge, recalcular métricas do zero

---

## functional_card_tags.dart (1092 linhas) — Auditoria de Heurísticas 🆕

**Não era um cron individual, mas o coração do sistema de classificação.** Usado por todos os crons e pelo endpoint `/decks/:id/analysis`.

### Escopo
- 27 tags funcionais definidas (linhas 7-36)
- ~40 heurísticas `_looksLike*` (linhas 319-948)
- Multi-tag system com `inferFunctionalCardTags()`

### O que faz certo (contra CR e deckbuilding real)
1. **Cobertura de tags: 27 tags** — cobre ramp, draw, removal, board_wipe, protection, recursion, token_maker, sacrifice_outlet, aristocrat_payoff, lifegain, drain, spellslinger, etc. Cobrindo a maioria dos papéis funcionais de Commander.
2. **Separação wincon vs payoff** (linhas 872-878 vs 900-920): `_looksLikeWincon` vs `_looksLikePayoff` — corretamente distintas.
3. **Heurística de ramp** (linhas ~700): `_looksLikeRamp` com `add {` mana patterns.
4. **Heurística de combo piece** (linhas 881-888): Reconhece Thassa's Oracle, Isochron Scepter + Dramatic Reversal, "copy target activated or triggered ability", "untap AND add".
5. **Heurística de protection** (linhas 713-731): hexproof, indestructible, shroud, ward, phase out — 17 padrões.

### Gaps contra CR
1. **🟡 Stax/Tax não são tags funcionais:** `functionalCardTagsV1` (linhas 7-36) não tem tags para stax ou tax effects (Rhystic Study, Drannith Magistrate). Essas cartas recebem tags genéricas como `engine` ou `draw`.
2. **🟡 "Land" detection simplificado:** Só verifica `typeLine.contains('land')`. MDFCs (Modal DFCs) com face traseira de terreno não são detectados.
3. **🟡 Ritual detection** (linhas 863-870): `_looksLikeRitual` verifica `add {` + `until end of turn` — cobre a maioria dos rituais, mas pode perder casos raros.
4. **🟡 ETB detection** (linhas 824-834): `_looksLikeEtb` verifica `when`/`whenever` + `enters the battlefield`. Não detecta ETBs que são "as [card] enters the battlefield".

### Cobertura de Tags — Análise de Cardinalidade
27 tags funcionais, das quais ~20 são tags ativas de classe com heurísticas próprias. 7 tags são meta/arquetipo (spellslinger, artifact_synergy, enchantment_synergy, graveyard_synergy, sac_outlet, aristocrat_payoff, drain).

**SCORE: 8.0/10** — sistema maduro e bem testado. Gaps residuais (stax/tax tag, MDFC land detection).

---

## edh_bracket_policy.dart (547 linhas) — Auditoria do Bracket System 🆕

**Não era um cron individual, mas o sistema de classificação de brackets.** Usado pelo endpoint de optimize.

### O que faz certo
1. **11 BracketCategories:** `fastMana`, `tutor`, `freeInteraction`, `extraTurns`, `infiniteCombo`, `boardWipe`, `cardAdvantage`, `stax`, `protection`, `valueEngine`, `gameChanger` — alinhado com sistema oficial de brackets (Bracket 1-4).
2. **54 Game Changers** na lista oficial (linhas 354-408): Cobre a lista oficial.
3. **Tag heuristic** `tagCardForBracket()` (linhas 115-192): Categoriza cartas por função bracket.
4. **Budget enforcement** `applyBracketPolicyToAdditions()` (linhas 247-310): Bloqueia cartas que excedem o bracket.

### Gaps contra CR e EDHREC
1. **🟡 Underworld Breach não está em `_knownInfiniteComboPieces`** (linha 347-351): É `gameChanger` na lista oficial, mas não é reconhecido como peça de combo infinito (com LED + Brain Freeze). **Gap 28 confirmado.**

2. **🟡 `_fastManaNames` tem Mana Drain** (linha 324): Mana Drain não é fast mana — é counterspell que dá mana. Deveria ser `freeInteraction` ou ter categoria própria.

3. **🟡 O nome 'tergrid, god of fright // tergrid's lantern'** (linha 401): O nome com `//` pode não fazer match com o nome normalizado de cartas DFC no banco. O sistema de variantes `_normalizedBracketNameVariants()` tenta split no `//`, mas só funciona se a string do banco também contém `//`.

4. **🔴 DFC names no SQLite**: `name` no `card_oracle_cache` para Tergrid pode ser `'Tergrid, God of Fright'` (face frontal sem `//`). O `_isOfficialGameChangerName()` split no `//` e check da face frontal pode ou não funcionar dependendo do formato do nome no banco.

### SCORE: 7.5/10 🟡 — sistema funcional, mas Underworld Breach e DFC name matching são gaps confirmados.

---

## MTG Rules Auditor (c0591cb18024) — Reflexão 🔴

**Este auditor é o cron que produziu v1.0-v11.0.** Estado atual:

### Estado Atual (2026-06-14)
- **Última auditoria real:** 2026-06-09 13:36Z (v9.0, 78858 bytes) — **5+ dias sem auditoria real no cron automático**
- **Última execução no cron:** 2026-06-13T13:15:34 (23h atrás) — "ok" no `last_status`, mas output foi apenas skill dump (60047 bytes do `manaloom-mtg-domain`)
- **53 execuções totais** — todas as execuções recentes (desde 2026-06-08 13:50Z) produzem skill dump, não auditoria
- **Skills carregados:** `manaloom-commander-knowledge` (❌ não encontrado), `manaloom-mtg-domain` (✅ disponível)
- **A última execução real foi MANUAL** (v10.0, 2026-06-13 01:30Z). A v11.0 (este relatório) também é manual.
- **Skill loading failure confirmado:** `log.delivery.error` não acusa erro porque o Hermes não considera skill faltante como erro fatal — apenas despeja o conteúdo do skill que carregou

### Pipeline score (autoavaliação): 0.0/10 🔴 (pior que v10.0 que era 1.0/10)

### Problemas do Prompt (linhas 566-590 de jobs.json)
1. **🔴 Skill loading failure:** `"skill": "manaloom-commander-knowledge"` (linha 586) — referência a skill que não existe. Desde a criação (2026-05-31), nunca funcionou.
2. **🔴 IDs stale:** `f20ac299992b`, `712579b15767`, `08468451a06a`, `94f8590b1beb`, `a50bef4c2a59` — todos descomissionados em v3.7 (2026-06-04). Diretórios de output **não existem mais**.
3. **🟡 Schedule 720min:** Reduzido de 180min para desperdiçar menos output/Delivery, mas só mascara o problema.

### Fix Necessário — URGENTE
1. 🔴 **Mudar `"skill": "manaloom-commander-knowledge"` para `"skill": "manaloom-mtg-domain"`** no `jobs.json`
2. 🔴 **Remover referências aos 5 IDs de Lorehold** do prompt (substituir por metodologia baseada em código-fonte e git diff)
3. 🟡 **Restaurar schedule para 180min** após correção

---

## Novos Gaps Identificados (v11.0)

### Gap 31: GoldfishSimulator — Tapped lands não detectados 🆕
**Severidade:** 🟡 ALTO
**Evidência:** `goldfish_simulator.dart:258-261` — `_isLand()` só verifica type_line. Nenhuma verificação de `oracleText.contains('enters the battlefield tapped')`.
**Impacto:** T3 inflado em 3-8pp para decks com 8+ terrenos que entram tapped (Temple, Shocklands sem pagar 2 life, Boros Garrison, etc.).
**Fix:** Adicionar detecção de "enters tapped" no oracle_text. Aplicar flag `entersTapped` na simulação de turns.

### Gap 32: Mana Drain classificado como fastMana 🆕
**Severidade:** 🟡 MÉDIO
**Evidência:** `edh_bracket_policy.dart:324` — `'mana drain'` na lista `_fastManaNames`. Mana Drain é counterspell que dá mana no próximo upkeep — não é fast mana.
**Impacto:** O bracket system pode limitar Mana Drain como se fosse fast mana, impedindo decks Bracket 2 de usá-lo.
**Fix:** Remover 'mana drain' de `_fastManaNames`. Se necessário, criar categoria freeInteraction para alternativos.

### Gap 33: functional_card_tags sem tag Stax/Tax 🆕
**Severidade:** 🟡 MÉDIO
**Evidência:** `functional_card_tags.dart:7-36` — 27 tags funcionais não incluem 'stax' ou 'tax'.
**Impacto:** Winter Orb, Drannith Magistrate, Rule of Law, Grand Abolisher são classificados como 'engine' genérico. O sistema não consegue recomendar ou avaliar stax pieces.
**Fix:** Adicionar tag 'stax' com heurísticas de restrição de ações (cast limits, search limits, untap limits).

### Gap 34: Underworld Breach — GC sem categoria combo 🆕 (confirmado do v10.0 Gap 28)
**Severidade:** 🟡 MÉDIO
**Evidência:** `edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` tem apenas 3 nomes: Thassa's Oracle, Demonic Consultation, Tainted Pact. Underworld Breach não está.
**Impacto:** Underworld Breach é detectado como `gameChanger` genérico, não como peça de combo infinito. Bracket system pode permitir Underworld Breach em Bracket 2 (que tem infiniteCombo=0) como se não fosse combo.
**Fix:** Adicionar 'underworld breach' a `_knownInfiniteComboPieces`.

### Gap 35: goldfish_simulator seed deterministic sem shuffle variation 🆕
**Severidade:** 🟢 BAIXO
**Evidência:** `goldfish_simulator.dart:236-255` — `_stableDeckSeed()` gera seed baseada em hash do deck. Shuffle usa `..shuffle(_random)` com seed estável.
**Impacto:** Mínimo. Simulações do mesmo deck produzem resultados consistentes (bom para A/B testing), mas podem não capturar variabilidade total entre runs.
**Fix:** Opcional. Usar seed fixa para baseline e seed variável para comparação.

---

## Plano de Correções (ordenado por impacto)

### 🔴 CRÍTICO (quebra o jogo ou distorce resultados gravemente)

1. **Battle Simulator Dart — 2/10 fidelidade MTG (Gap 8, Gap 29)**
   - **Impacto:** Endpoint `/ai/simulate` produz resultados que não refletem Commander real. Universal Optimizer propõe cortar staples baseado nestes dados.
   - **Código:** `server/lib/ai/battle_simulator.dart:9` — "Sem stack complexo (resolução imediata)"
   - **Fix:** Migrar para Python `battle_analyst_v8.py` (7/10 fidelity) ou reconstruir Dart com stack, Commander damage, tax, multiplayer, multi-blocker, mana colorida.

2. **MTG Rules Auditor — skill loading failure (Gap 29)**
   - **Impacto:** 8+ execuções consecutivas FAILED. Pipeline score: 0.0/10.
   - **Fix:** Migrar prompt de `manaloom-commander-knowledge` para `manaloom-mtg-domain` em `jobs.json`. Remover 5 IDs de crons descomissionados do prompt.

3. **CMC corrompido — 35/100 cartas (35%) no deck ativo (Gap 19)**
   - **Impacto:** Toda métrica que depende de CMC (curva de mana, goldfish simulator, quality gate) opera com dados inválidos.
   - **DB:** `deck_cards.cmc IS NULL OR cmc = 0` — 35 cartas no deck 6.
   - **Fix:** Executar script `fix_cmc_batch.py` para corrigir via PostgreSQL `cards.cmc`. Pendente desde 2026-06-05 (>8 dias).

4. **15 GCs perdidos do card_oracle_cache (28.3%) (Gap 27)**
   - **Impacto:** Game Changer Research não pode auditar GCs completos localmente. Sync PG→SQLite filtra banned cards, DFCs, e causa adicional desconhecida (Expropriate legal está missing).
   - **Fix:** Executar `scripts/gc_cache_analyzer.py` para verificar 53 GCs. Adicionar verificação pós-sync. Restaurar via Scryfall API.

### 🟡 ALTO (distorce resultados ou reduz confiabilidade)

5. **GoldfishSimulator — tapped lands não detectados (Gap 31 🆕)**
   - **Impacto:** T3 inflado 3-8pp. Métricas de consistência superestimadas.
   - **Fix:** Verificar `oracle_text.contains('enters the battlefield tapped')` em `_isLand()` ou `_playLandIfPossible()`.

6. **Bracket categories — SQLite reclassificou 3 categorias para `other` (Gap 25)**
   - **Impacto:** 3/5 categorias originais com zero cartas (`tutor=0`, `extraTurns=0`, `infiniteCombo=0`). 88% dos GCs detectados colapsaram em `other`.
   - **Fix:** Restaurar Force of Will, Bolas's Citadel. Reclassificar 12 tutores. Adicionar teste de regressão.

7. **Universal Optimizer — propõe cortar staples Commander (Gap 20)**
   - **Impacto:** Smothering Tithe, Imperial Recruiter candidatos a corte baseados em simulador 2/10.
   - **Blocked by:** PermissionError — mitigação acidental.
   - **Fix:** Proteção EDHREC ≥ 30% contra corte automático.

8. **Mana Drain classificado como fastMana (Gap 32 🆕)**
   - **Impacto:** Bracket system pode limitar Mana Drain em Bracket 2.
   - **Fix:** Remover de `_fastManaNames`, mover para lista de freeInteraction ou criar categoria própria.

9. **functional_card_tags sem tag Stax/Tax (Gap 33 🆕)**
   - **Impacto:** Stax pieces invisíveis ao sistema de classificação funcional.
   - **Fix:** Adicionar tag 'stax' + heurísticas.

### 🟢 MÉDIO (imprecisão ou melhoria)

10. **Underworld Breach sem categoria infiniteCombo (Gap 34 🆕)**
    - **Fix:** Adicionar 'underworld breach' a `_knownInfiniteComboPieces`.

11. **DFC name matching — Tergrid no bracket policy (Gap 27)**
    - **Fix:** Verificar formato do nome da face frontal no SQLite vs a lista oficial.

12. **Auto-promote-learned — quebrado (missing table `deck_promotions`)**
    - **Impacto:** 22 execuções com `no such table: deck_promotions`.
    - **Fix:** Criar tabela ou corrigir script.

### 🟢 BAIXO (cosmético ou procedural)

13. **Git push — commits ahead sem credenciais**
    - **Fix:** Configurar credenciais Git no ambiente cron.

14. **Prompt do MTG Rules Auditor — referências stale**
    - **Fix:** Atualização do prompt (parte do item #2 acima).

---

## Conclusão

A pipeline Lorehold (5 crons) foi **descomissionada em 2026-06-04 (v3.7)** por Death Loop autossustentável. O código permanece no repositório. A auditoria linha-a-linha confirma que **nenhum dos 5 crons tinha output confiável ou fidelidade MTG aceitável isoladamente.**

**A nota mais baixa é do Battle (2.0/10)** — um simulador 2-player sem stack, sem Commander damage/tax, sem multi-blocker. Confirma-se que a declaração no código (linha 9: "Sem stack complexo") torna impossível simular MTG real. **O endpoint `/ai/simulate` em produção usa este código** e apresenta resultados como se fossem "simulação de batalha" — isso precisa de disclaimer urgente.

**O GoldfishSimulator (produção) é significativamente melhor** que o Mulligan cron original (color source tracking implementado, draws T1-4 simulados), mas ainda não detecta tapped lands.

**O MTG Rules Auditor (este cron) tem pipeline score 0.0/10** — o prompt referencia skill inexistente `manaloom-commander-knowledge` e 5 IDs de crons descomissionados. O fix é trivial (mudar skill no jobs.json + limpar prompt) e está documentado neste relatório há 3 versões (v8.0, v9.0, v10.0, v11.0) sem ser implementado.

**O CMC corruption (35/100, 35%) persiste como o problema técnico mais antigo sem correção** — descoberto em 2026-06-05, >8 dias sem fix.

**Pipeline score geral: 4.5/10 🔴 BAIXA** — estagnada. Os mesmos problemas persistem sem intervenção.
