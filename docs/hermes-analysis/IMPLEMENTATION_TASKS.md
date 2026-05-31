# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes x codigo atual.
> Data: 2026-05-31 | Branch: origin/master | SHA: 23cfc061

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | ATIVO |
| P1-d | P1 | Wincon detection fragil — battle_analyst + weakness-analysis usam hardcoded names | ATIVO |
| P1-e | P1 | GoldfishSimulator nao calcula "Sem Play T3" — metrica critica ausente | ATIVO |
| P1-f | P1 | optimize_request_support nao carrega card_function_tags — drift semantico confirmado | ATIVO (NOVO) |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia no SQLite | ATIVO |
| P2-c | P2 | Write-only tables: deck_matchups, deck_weakness_reports, ml_prompt_feedback | ATIVO |
| P2-d | P2 | Double-null cards invisiveis ao classificador — risco de swap auto | ATIVO |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil (oracle text) | ATIVO |
| P3-c | P3 | manual-de-instrucao.md nao reflete F1/F3/bracket expansion | ATIVO |
| P3-d | P3 | THEMES.md 19 temas nao validados vs EDHREC | ATIVO |

---

### [P1] optimize_request_support nao carrega card_function_tags — drift semantico confirmado

**Conhecimento MTG:** O EDHREC e os dados funcionais persistidos (card_function_tags) representam a classificacao mais precisa da funcao real de cada carta — foi construida a partir de dados reais de uso (milhares de decks). Quando o optimize pipeline usa apenas semantic_tags_v2 (que e um modelo unico de role por carta) e nao carrega functional_tags persistidas, uma carta como "Scroll Rack" (que deveria ser engine) pode ser classificada como utility porque o v2 nao tem pattern para ela (double-null). Isso significa que cartas funcionais criticas sao tratadas como filler pelo optimize.

**Evidencia no codigo:**
- `server/routes/ai/optimize/index.dart:2068-2099` — Carrega semantic_tags_v2 mas NAO carrega card_function_tags nas queries de deck_cards do deck original
- `server/routes/ai/optimize/index.dart:3197-3213` — Repete o mesmo padrao para dados de adicoes (additions)
- `server/lib/ai/optimize_request_support.dart:91-109` — Monta allCardData com semantic_tags_v2 mas sem functional_tags
- `server/routes/decks/[id]/analysis/index.dart:80-96` — Em contraste, a rota de analise DECK carrega ambos card_function_tags E semantic_tags_v2 (padrao correto)
- `server/lib/ai/functional_card_tags.dart:400-465` — O classificador ja prefere functional_tags persistidos quando existem

**Gap:** Existe um adapter unificado em functional_card_tags.dart que resolve roles por ordem: functional_tags persistidos -> semantic_tags_v2 -> fallback textual. Porem, o optimize pipeline NAO carrega functional_tags na query SQL, entao o classificador nao tem acesso a esses dados. O resultado: uma carta pode aparecer como engine na aba de analise (que carrega functional_tags) mas ser tratada como utility no optimize (que so carrega semantic_tags_v2). Isso e o "drift semantico" confirmado na auditoria de estrutura card-semantics (STRUCTURE_AUDIT.md, rodada card-semantics).

**Impacto:**
1. Cartas double-null (Scroll Rack, Penance) sao classificadas como utility no optimize — candidatas a swap/remocao
2. Cartas multi-funcao podem perder roles secundarios (ex: uma carta que e draw + engine na analise vira so engine no optimize/quality gate)
3. O quality gate pode bloquear swaps validos ou permitir swaps perigosos porque o role_delta e calculado com base em dados incompletos
4. O deck analysis mostra uma realidade e o optimize opera com outra — incoerencia sistemica

**Acao recomendada:**
1. Adicionar card_function_tags nas queries SQL de optimize_request_support.dart e optimize/index.dart (tanto para deck original quanto para additions)
2. Criar funcao resolveCardFunctionalRoles() que retorne roles multi-valor + primary_role, usando ordem: functional_tags persistidos -> semantic_tags_v2 -> fallback textual
3. Manter compatibilidade serializando primary_role antigo enquanto o validator/gate calcula deltas multi-role
4. Atualizar _classifySemanticV2FunctionalRole() para tambem consultar functional_tags quando disponivel

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_functional_roles.dart lib/ai/functional_card_tags.dart routes/ai/optimize/index.dart
dart test test/optimization_quality_gate_test.dart
dart test test/functional_card_tags_test.dart
```

---

### [P1] GoldfishSimulator nao calcula "Sem Play T3" — metrica critica ausente

**Conhecimento MTG:** A simulacao de mulligan do Lorehold (Execucoes #1-9) revelou que "Sem Play T3" (nenhum nao-terreno com CMC <= min(lands, 3) jogavel nos 3 primeiros turnos) e a metrica mais importante para consistencia de Fase 1. O deck Ciclo #1 tinha 3.3% -> Ciclo #2: 12.4% -> Ciclo #3: 16.4% -> Ciclo #4: 13.8% -> Ciclo #5: 15.3%. O quality gate DECIDE a estrategia de swap (AGGRESSIVE/BALANCED/DEFENSIVO) baseada neste valor: < 8% = agressivo, 8-12% = balanceado, > 12% = defensivo. Ciclo #6 e DEFENSIVO (T3 = 15.3%). Empiricamente, cada ciclo defensivo (Delta CMC -5 a -15) reduz T3 em 2-4pp.

**Evidencia no codigo:**
- `server/lib/ai/goldfish_simulator.dart:28-40` — GoldfishResult tem turn1PlayRate..turn4PlayRate mas NAO tem noPlayTurn3Rate ou similar
- `server/lib/ai/goldfish_simulator.dart:158-191` — Loop de simulacao conta turn1Plays..turn4Plays mas nao verifica se ha spells CMC jogavel acumulado ate T3
- `server/lib/ai/optimization_quality_gate.dart:346-353` — _criticalRolesForArchetype() NAO inclui consistencia de early-game como criterio
- `server/lib/ai/optimization_validator.dart:100` — _runMonteCarloComparison usa GoldfishSimulator mas nao extrai metrica de "vazio de early game"

**Gap:** O Dart GoldfishSimulator mede "can play on T3" (existe 1 carta CMC<=3 jogavel T3) mas nao mede "nothing to play through T3-5" (todas as cartas sao CMC alto demais early). A metrica Python sem_play_T3 = count(no nonland with CMC <= min(lands, 3)) / N e fundamentalmente diferente e mais util que turn3PlayRate.

**Impacto:**
1. O Ciclo #3 aplicou estrategia AGGRESSIVA errada por 1 ciclo completo (deveria ser DEFENSIVO)
2. Decks com CMC inflado passam no quality gate sem alerta de early-game deficit
3. Operator nao tem visibilidade da metrica mais importante para consistencia

**Acao recomendada:**
1. Adicionar noPlayT3Rate (e preferencialmente noPlayT4Rate, noPlayT5Rate) ao GoldfishResult
2. No loop de simulacao (linha ~180), rastrear: minCastableCmc = min(nonland_cmc for nonland in cardsAvailable), verificar se minCastableCmc <= min(landsPlayed, 3) a cada turno, contar maos onde isso falha ate T3/T4/T5
3. Expor no JSON de resultado do GoldfishSimulator
4. Opcional: adicionar alerta no quality gate quando noPlayT3Rate > 0.12

**Validacao:**
```bash
cd server
dart analyze lib/ai/goldfish_simulator.dart
dart test test/optimization_validator_test.dart
```

---

### [P2] Double-null cards invisiveis ao classificador — risco de swap auto

**Conhecimento MTG:** A analise do Lorehold (Purpose Analyzer v3-v3.6) identificou 6 cartas double-null restantes: Scroll Rack, Penance, Grand Abolisher, Ruby Medallion, Pearl Medallion, Galadriel's Dismissa. Scroll Rack e Penance sao engines criticos (risco de corte = CRITICO). Pearl Medallion (25.2% EDHREC, trend -0.46) e cut candidato prioritario para Ciclo #6 DEFENSIVO.

**Evidencia no codigo:**
- `server/lib/ai/optimization_functional_roles.dart:55-125` — classifyOptimizationFunctionalRole() retorna artifact/enchantment/utility para estas cartas
- `server/lib/ai/functional_card_tags.dart` — Multi-tag classifier tambem falha para Scroll Rack e Penance

**Gap:** Nao ha mecanismo de fallback para cartas que ambos classificadores falham. O quality gate trata essas cartas como utility sem funcao especifica, tornando-as candidatas a swap.

**Impacto:**
1. Scroll Rack (CMC 2, topdeck engine): Risco CRITICO de swap auto — core do motor Lorehold
2. Penance (CMC 3, topdeck + anti-removal): Risco CRITICO — miracle enabler
3. Grand Abolisher (protection): Risco alto
4. Ruby/Pearl Medallion (cost reduction): Risco medio — classificados como ramp mas sao cost-reduction

**Acao recomendada:**
1. Criar tabela protected_cards (card_name, reason, override_role) no PostgreSQL — whitelist manual
2. Adicionar check no filterUnsafeOptimizeSwapsByCardData(): consultar protected_cards antes de permitir swap
3. Adicionar tag cost_reduction ao classificador (diferente de ramp) para Medallions
4. Adicionar oracle patterns para "Scroll Rack" (look at top N + rearrange) e "Penance" (return to top of library)

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_quality_gate.dart lib/ai/optimization_functional_roles.dart
dart test test/optimization_quality_gate_test.dart
```

---

### [P3] THEMES.md 19 temas nao validados vs EDHREC

**Conhecimento MTG:** O THEMES.md contem 27 temas, dos quais apenas ~8 foram validados contra dados reais de EDHREC. Os seguintes temas estao marcados como "NAO VALIDADO": Spellslinger, Graveyard, Tokens, +1/+1 Counters, Voltron, Blink/Flicker, Wheels, Reanimator, Mill, Zombies, Knights, Merfolk, Humans, Stax/Prison, Combo (Proactive), Group Slug, Superfriends, Cascade.

**Evidencia no codigo:**
- `docs/hermes-analysis/manaloom-knowledge/THEMES.md` — 19 temas marcados "NAO VALIDADO"
- `server/lib/ai/theme_contextual_rules_service.dart` — Le theme_contextual_rules do PostgreSQL que alimenta o quality gate

**Gap:** Os theme_contextual_rules no PostgreSQL contem ranges nao-validados para 19/27 temas. O quality gate compara decks contra ranges potencialmente errados.

**Acao recomendada:**
1. Priorizar validacao de Spellslinger (archetype do Lorehold, deck ativo no pipeline)
2. Reanimator e Graveyard sao os mais comuns na comunidade EDH — segunda prioridade
3. Para cada tema: extrair metricas de EDHREC avg deck + commander profiles, comparar com THEMES.md
4. Atualizar theme_contextual_rules no PostgreSQL com ranges corrigidos

**Validacao:** Validacao manual contra EDHREC live data.

---

## Tasks Ja Ativos (mantidos de sintese anterior)

### [P1] Weakness-analysis usa heuristicas legacy — sem adapter F1

**Evidencia no codigo:**
- `server/routes/ai/weakness-analysis/index.dart:114-170` — Conta ramp/draw/removal/wipes por oracle_text local
- `server/routes/ai/weakness-analysis/index.dart:380-430` — Recomendacoes sao listas fixas de nomes

**Acao:** Refatorar para usar resolveCardFunctionalRoles() + queries em card_function_tags

### [P1] Wincon detection fragil — battle_analyst + weakness-analysis

**Evidencia no codigo:**
- `server/lib/ai/optimization_quality_gate.dart:346-353` — _criticalRolesForArchetype() NAO inclui wincon
- `server/routes/ai/weakness-analysis/index.dart:400-420` — Patterns fixos

**Acao:** Adicionar wincon aos roles criticos; refatorar para usar adapter F1

### [P2] Write-only tables — deck_matchups, deck_weakness_reports, ml_prompt_feedback

**Evidencia no codigo:**
- `server/routes/ai/simulate-matchup/index.dart:360` — INSERT em deck_matchups
- `server/routes/ai/weakness-analysis/index.dart:374` — INSERT em deck_weakness_reports
- `server/lib/ml_knowledge_service.dart:251` — INSERT em ml_prompt_feedback

**Acao:** Adicionar SELECT para cache ou documentar como audit logs com retention policy

### [P3] manual-de-instrucao.md desatualizado

**Evidencia:** Nao menciona F1, F3, bracket expansion, card_deck_profiles, payoff expansion, singleton reset (d3cfaf3b), dead code cleanup (8cab6400, 23cfc061).

**Acao:** Atualizar com todos os commits desde a ultima atualizacao.

---

## Tasks Resolvidos (referencia historica)

| Task | Commit |
|:-----|:-------|
| BracketCategory enum (boardWipe, cardAdvantage, stax, protection, valueEngine) | ae886b11 |
| card_deck_profiles integration | d8b7b26b |
| _looksLikePayoff damage payoffs | 3fb17356 |
| CONTEXTO_PRODUTO_ATUAL.md update | 7ed5b863 |
