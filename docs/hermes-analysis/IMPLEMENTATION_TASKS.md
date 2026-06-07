# Implementation Tasks — Knowledge Synthesis

> **Data:** 2026-06-07 18:00Z (aproximado)
> **Cron:** manaloom-knowledge-synthesis (Exec #10)
> **Fontes:** SQLite knowledge.db, SCOUT_LOG.md, VALIDATOR_LOG.md, MANA_BASE_VALIDATION_REPORT.md, GAME_CHANGERS.md, THEMES.md, STRUCTURE_AUDIT.md, LOGIC_COHERENCE_REPORT_2026-05-29_E2E.md
> **Codigo analisado:** edh_bracket_policy.dart, functional_card_tags.dart, optimization_functional_roles.dart, optimize_runtime_support.dart, optimization_quality_gate.dart, deck_rules_service.dart

---

## Resumo

Esta execucao cruzou o conhecimento MTG acumulado (53 Game Changers, 8 decks no DB, metricas de tag accuracy, CMC corruption, ramp misclassification) com o codigo Dart que implementa a logica de classificacao e otimizacao. **5 tasks geradas** — 2 P0 (criticas), 3 P1 (alta prioridade).

---

## Tasks

### [P0] Expandir BracketCategory enum com 7 categorias faltantes para detectar 29/53 Game Changers

**Conhecimento MTG:** 29 dos 53 Game Changers oficiais nao sao detectados pelo ManaLoom (54.7%). O SQLite confirma: manaloom_detected=0 para Rhystic Study, Cyclonic Rift, The One Ring, Smothering Tithe, Drannith Magistrate, Necropotence, Opposition Agent, e 22 outros. As categorias faltantes sao: card_advantage (5 GCs), stax (7 GCs), value_engine (9 GCs), board_wipe (2 GCs), protection (1 GC), fast_mana_land (3 GCs), free_interaction_flex (1 GC).

**Evidencia no codigo:** server/lib/edh_bracket_policy.dart:7-14 — BracketCategory enum define apenas fastMana, tutor, freeInteraction, extraTurns, infiniteCombo, gameChanger.

**Evidencia no DB:**
```sql
SELECT COUNT(*) FROM game_changers WHERE manaloom_detected=0;
-- Resultado: 29 (de 53)
```

**Gap:** O enum nao tem categorias para classificar 54.7% dos Game Changers. O bracket policy nao consegue limitar esses GCs em brackets 1-3, permitindo que decks incluam Rhystic Study, Cyclonic Rift, The One Ring etc. sem consumir o budget de Game Changer.

**Impacto:** O bracket system esta funcionalmente incompleto. Decks em bracket 2 (max 0 GCs) podem incluir Rhystic Study e outros GCs nao detectados, violando as regras do formato. O applyBracketPolicyToAdditions() permite a adicao dessas cartas como se fossem "normais".

**Risco:** P0 — quebra regras oficiais de Commander. O bracket system e a camada de power level que diferencia brackets 1-4. Sem detectar 54.7% dos GCs, a classificacao de power level e imprecisa e permite decks fora do bracket declarado.

**Acao recomendada:**
1. Adicionar 7 novas categorias ao BracketCategory enum em edh_bracket_policy.dart:7:
   cardAdvantage, boardWipe, stax, valueEngine, protection, fastManaLand, freeInteractionFlex
2. Adicionar heuristicas em tagCardForBracket() (linhas 91-148):
   - cardAdvantage: oracle contem "draw a card" + trigger condicional (opponent casts, upkeep, etc.) — cobre Rhystic Study, Mystic Remora, The One Ring, Necropotence, Consecrated Sphinx
   - boardWipe: oracle contem "each" + "return to" ou "exile all" — cobre Cyclonic Rift, Farewell
   - stax: oracle contem "can't" + referencia a opponent (can't cast, can't search, can't draw) — cobre Drannith Magistrate, Opposition Agent, Narset, Notion Thief, Humility
   - valueEngine: oracle contem "whenever" + trigger repetivel + gera valor (tokens, draw, mana, damage) — cobre Seedborn Muse, Aura Shards, Tergrid, Orcish Bowmasters, Biorhythm
   - protection: oracle contem "protection from everything" ou "phase out" (all) — cobre Teferi's Protection
   - fastManaLand: type contem "land" + oracle contem "add {C}{C}" ou "add X" — cobre Gaea's Cradle, Serra's Sanctum, Mishra's Workshop
   - freeInteractionFlex: oracle contem "without paying" + "if you control" + counter/removal — cobre Fierce Guardianship
3. As novas categorias devem ser incluidas em BracketPolicy.forBracket() com limites apropriados por bracket.
4. Game Changers oficiais devem consumir APENAS o budget de gameChanger, NAO tambem o da categoria especifica. A logica ja existe na linha 103: _isOfficialGameChangerName(n) retorna apenas BracketCategory.gameChanger. As novas categorias servem para cartas NAO-GC que se encaixam nos padroes (ex: Mystic Remora nao e GC mas e cardAdvantage).

**Validacao:**
```bash
cd server && /opt/data/tools/flutter/bin/dart analyze lib/edh_bracket_policy.dart
cd server && /opt/data/tools/flutter/bin/dart test test/edh_bracket_policy_test.dart
```

---

### [P0] Adicionar validacao de CMC em _getCmc() para detectar e mitigar dados corrompidos

**Conhecimento MTG:** 142/543 cartas (26.2%) no knowledge.db tem CMC=NULL ou CMC=0.0. O deck 6 (Lorehold) e o pior: 36 cartas com CMC corrompido, incluindo Sol Ring (CMC real=1, DB=0.0), Mana Vault (CMC real=1, DB=0.0), Boros Signet (CMC real=2, DB=0.0). O CMC corruption se espalhou de 1 deck para 7 decks entre v4.0 e v5.0. O Mana Base Validator Exec #3 confirmou que decks.avg_cmc armazenado (1.79) diverge do AVG(cmc) WHERE cmc>0 (3.14) para Lorehold — delta de +1.35.

**Evidencia no codigo:** server/lib/ai/optimize_runtime_support.dart — funcao _getCmc(). server/lib/ai/optimization_quality_gate.dart:55 — final cmcDelta = _getCmc(addedCard) - _getCmc(removedCard); usa CMC para decidir se swap e seguro. server/lib/ai/cmc_safety.dart — importado pelo quality gate para validacao de CMC.

**Evidencia no DB:**
```sql
SELECT COUNT(*) FROM deck_cards WHERE cmc IS NULL OR cmc = 0.0;
-- Resultado: 142/543 (26.2%), inalterado desde v5.0
-- Distribuicao: deck 1=2, deck 2=19, deck 4=15, deck 5=19, deck 6=36, deck 7=22, deck 9=29
```

**Gap:** O quality gate usa _getCmc() para calcular cmcDelta e decidir se um swap e seguro (ex: nao trocar land por CMC 6). Quando CMC=0.0 para cartas que deveriam ter CMC 2-6, o delta e incorreto e swaps invalidos podem passar pelo gate. Alem disso, o mulligan simulator usa CMC para avaliar jogabilidade de maos — com 36 cartas CMC=0, a curva parece artificialmente baixa.

**Impacto:**
- Quality gate aprova swaps baseados em CMC incorreto (ex: trocar Sol Ring "CMC=0" por carta CMC=5 passa como "CMC sobe 5", mas na verdade sobe 4)
- Mulligan simulation infla maos jogaveis (cartas CMC 5+ tratadas como CMC 0, aumentando artificialmente T3 playability)
- Metricas de CMC medio no frontend mostram 1.79 para Lorehold quando o real e 3.14

**Risco:** P0 — dados corrompidos contaminam todas as decisoes de otimizacao e simulacao.

**Acao recomendada:**
1. Adicionar warning log em _getCmc() quando retornar 0 para cartas que nao sao lands
2. No quality gate (optimization_quality_gate.dart:55), adicionar check: se CMC=0 && !isLand, pular o swap com reason "CMC data corrupted"
3. Correcao raiz (fora do escopo Dart): Executar script fix_cmc_batch.py para corrigir CMCs no SQLite via PostgreSQL cards.cmc.

**Validacao:**
```bash
cd server && /opt/data/tools/flutter/bin/dart analyze lib/ai/optimization_quality_gate.dart
cd server && /opt/data/tools/flutter/bin/dart analyze lib/ai/optimize_runtime_support.dart
cd server && /opt/data/tools/flutter/bin/dart test test/ai/optimization_quality_gate_test.dart
```

---

### [P1] Fazer classifyOptimizationFunctionalRole() ler functional_tags persistidas do BD como fonte primaria

**Conhecimento MTG:** O Logic Coherence Report (2026-05-29) identificou drift entre os dois classificadores: functional_card_tags.dart usa prioridade functional_tags -> semantic_v2 -> heuristic, enquanto optimization_functional_roles.dart pula functional_tags e vai direto para semantic_tags_v2 -> heuristic. A tag accuracy no SQLite mostra protection=69.2%, payoff=35.5%, enabler=50% — as heuristicas estao errando, e o quality gate esta usando essas heuristicas para decidir swaps.

**Evidencia no codigo:**
- server/lib/ai/functional_card_tags.dart:125 — summarizeFunctionalTagsForDeck() prioriza persistedTags primeiro, depois semanticV2, depois inferredTags. Correto.
- server/lib/ai/optimization_functional_roles.dart:55-61 — classifyOptimizationFunctionalRole() chama _classifySemanticV2FunctionalRole(card['semantic_tags_v2']) e so. NAO consulta card['functional_tags']. Drift.

**Gap:** O quality gate (optimization_quality_gate.dart:53-57) usa classifyOptimizationFunctionalRole() para determinar removedRole e addedRole. Se a classificacao estiver errada (ex: protection com 69.2% accuracy, payoff com 35.5%), o gate pode aprovar swaps que removem protecao essencial ou rejeitar swaps que adicionam payoffs corretos.

**Impacto:** Swaps sao aprovados/rejeitados com base em heuristicas de oracle text que tem baixa precisao (35.5% para payoff). O sistema ignora tags validadas e persistidas no BD.

**Risco:** P1 — decisoes de swap baseadas em classificacoes imprecisas.

**Acao recomendada:**
1. Em classifyOptimizationFunctionalRole() (linha 55), adicionar leitura de card['functional_tags'] ANTES de _classifySemanticV2FunctionalRole()
2. Adicionar _extractPrimaryPersistedTag() que extrai a tag primaria de functional_tags
3. Mapear tags do classificador Python (fine-grained) para os roles do quality gate (coarse)

**Validacao:**
```bash
cd server && /opt/data/tools/flutter/bin/dart analyze lib/ai/optimization_functional_roles.dart
cd server && /opt/data/tools/flutter/bin/dart test test/ai/optimization_quality_gate_test.dart
```

---

### [P1] Adicionar heuristicas de ramp para rituais e treasure generators no classificador Dart

**Conhecimento MTG:** O classificador Python foi corrigido em 2026-06-03 para detectar rituais e mana rocks. O Gap 15 documentou que 10 cartas de ramp nao eram detectadas. O Dart functional_card_tags.dart e optimization_functional_roles.dart podem ter o mesmo gap.

**Evidencia no codigo:**
- server/lib/ai/optimization_functional_roles.dart:23-28 — looksLikeOptimizationRampText() verifica apenas add { ou mana of any. NAO verifica: rituais com add {R} ou add {W}, nem create treasure token.
- server/lib/ai/functional_card_tags.dart:219-226 — mesma funcao usada.

**Evidencia no DB:** Deck 6 (Lorehold) mostra ramp_count=6, mas o deck tem 16+ fontes de ramp reais. A discrepancia infla o "Sem Play T3" no mulligan simulator.

**Gap:** looksLikeOptimizationRampText() nao detecta rituais, treasure generators, e alguns mana rocks.

**Impacto:** Metricas de ramp subestimadas -> mulligan simulator infla maos nao-jogaveis -> otimizador pode recomendar adicionar ramp quando ja ha suficiente.

**Risco:** P1 — metricas de ramp incorretas distorcem simulacao e recomendacoes de swap.

**Acao recomendada:**
1. Expandir looksLikeOptimizationRampText() para detectar rituais (add {R} etc.), treasure tokens, e mana rocks por nome
2. Adicionar hardcoded ramp names: mana vault, fellwar stone, victory chimes
3. Reclassificar decks no SQLite apos a correcao

**Validacao:**
```bash
cd server && /opt/data/tools/flutter/bin/dart analyze lib/ai/optimization_functional_roles.dart
cd server && /opt/data/tools/flutter/bin/dart test test/ai/functional_card_tags_test.dart
```

---

### [P1] Adicionar disclaimer obrigatorio no prompt do Commander Knowledge Deep sobre Battle Simulator

**Conhecimento MTG:** O battle_simulator.dart (879 linhas, linha 9) declara "Sem stack complexo (resolucao imediata)". O simulador e 2-player, sem Commander damage (CR 903.10a), sem Commander tax (CR 903.8). Apesar disso, o Commander Knowledge Deep (Exec #11) gerou TASKS P0 baseadas em "BATTLE-VALIDATED" com WR de 87-89%.

**Evidencia no codigo:** server/lib/ai/battle_simulator.dart:9 — "Sem stack complexo (resolucao imediata)".

**Evidencia no log:** Commander Knowledge Deep Exec #11 gerou tasks P0 baseadas em dados do Battle Simulator.

**Gap:** O cron cita dados do simulador como "BATTLE-VALIDATED" e gera TASKS P0 instruindo aplicar mudancas no pipeline.

**Impacto:** Tasks P0 geradas com dados invalidos deslocam recursos de tarefas legitimos. Se aplicadas, degradam o deck contra jogo real.

**Risco:** P1 — tasks P0 baseadas em simulacao invalida podem causar regressoes.

**Acao recomendada:**
1. Adicionar ao prompt do cron manaloom-commander-knowledge-deep: disclaimer obrigatorio sobre as limitacoes do Battle Simulator
2. Proibir o uso de "BATTLE-VALIDATED" — substituir por "SIMULATION-INDICATED"
3. Proibir geracao de tasks P0/P1 baseadas exclusivamente em dados do simulador
4. Atualizar jobs.json com o novo prompt

**Validacao:** Verificar output da proxima execucao — nao deve conter "BATTLE-VALIDATED" nem tasks P0 baseadas em dados do simulador.

---

## Notas

- **CMC Corruption (142/543, 26.2%):** Correcao raiz requer script Python (fix_cmc_batch.py). A task P0 #2 mitiga o impacto no Dart.
- **Pipeline Lorehold descomissionado:** 5 crons removidos. Codigo Dart permanece no repo sem execucao ativa.
- **Knowledge Synthesis quebrou com HTTP 404 na execucao anterior (#9):** Provider/endpoint precisa ser verificado.
- **Tag accuracy com baixa precisao:** payoff=35.5%, enabler=50%, combo_piece=50% — melhoria continua (P2/P3), nao incluida neste ciclo.
