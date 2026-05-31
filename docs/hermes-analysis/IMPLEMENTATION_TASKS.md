# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes × codigo atual.
> Data: 2026-05-31 | Branch: origin/master | SHA: 2880a94c

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | ATIVO |
| P1-d | P1 | Wincon detection fragil — battle_analyst + weakness-analysis usam hardcoded names | ATIVO |
| P1-e | P1 | GoldfishSimulator nao calcula "Sem Play T3" — metrica critica ausente | ATIVO (NOVO) |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia no SQLite | ATIVO |
| P2-c | P2 | Write-only tables: deck_matchups, deck_weakness_reports, ml_prompt_feedback | ATIVO |
| P2-d | P2 | Double-null cards invisiveis ao classificador — risco de swap auto | ATIVO (NOVO) |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil (oracle text) | ATIVO |
| P3-c | P3 | manual-de-instrucao.md nao reflete F1/F3/bracket expansion | ATIVO |
| P3-d | P3 | THEMES.md 19 temas nao validados vs EDHREC | ATIVO (NOVO) |

---

### [P1] GoldfishSimulator nao calcula "Sem Play T3" — metrica critica ausente

**Conhecimento MTG:** A simulacao de mulligan do Lorehold (Execucoes #1-7) revelou que "Sem Play T3" (nenhum nao-terreno com CMC <= min(lands, 3) jogavel nos 3 primeiros turnos) e a metrica mais importante para consistencia de Fase 1. O deck Ciclo #1 tinha 3.3% -> Ciclo #2: 12.4% -> Ciclo #3: 16.4% -> Ciclo #4: 13.8%. O quality gate DECIDE a estrategia de swap (AGGRESSIVE/BALANCED/DEFENSIVO) baseada neste valor: < 8% = agressivo, 8-12% = balanceado, > 12% = defensivo. Sem esta metrica, o Ciclo #3 usou estrategia AGGRESSIVO (projetou 5.1%) quando era DEFENSIVO real (16.4%), atrasando a correcao em 1 ciclo completo. Empiricamente, cada ciclo defensivo (Delta CMC -5 a -15) reduz T3 em 2-4pp.

**Evidencia no codigo:**
- `server/lib/ai/goldfish_simulator.dart:28-40` -- `GoldfishResult` tem `turn1PlayRate..turn4PlayRate` mas NAO tem `noPlayTurn3Rate` ou similar
- `server/lib/ai/goldfish_simulator.dart:158-191` -- Loop de simulacao conta turn1Plays..turn4Plays mas nao verifica se ha spells CMC jogavel acumulado ate T3
- `server/lib/ai/optimization_quality_gate.dart:346-353` -- `_criticalRolesForArchetype()` NAO inclui consistencia de early-game como criterio
- `server/lib/ai/optimization_validator.dart:100` -- `_runMonteCarloComparison` usa GoldfishSimulator mas nao extrai metrica de "vazio de early game"

**Gap:** O Dart GoldfishSimulator mede "can play on T3" (existe 1 carta CMC<=3 jogavel T3) mas nao mede "nothing to play through T3-5" (todas as cartas sao CMC alto demais early). A metrica Python `sem_play_T3 = count(no nonland with CMC <= min(lands, 3)) / N` e fundamentalmente diferente e mais util que `turn3PlayRate`. Ciclo #3 demonstrou que a diferenca entre as duas metricas e de 3x (5.1% validate_mana.py vs 16.4% simulacao real).

**Impacto:**
1. O Ciclo #3 aplicou estrategia AGGRESSIVA errada por 1 ciclo completo (deveria ser DEFENSIVO)
2. Decks com CMC inflado passam no quality gate sem alerta de early-game deficit
3. Operator nao tem visibilidade da metrica mais importante para consistencia

**Acao recomendada:**
1. Adicionar `noPlayT3Rate` (e preferencialmente `noPlayT4Rate`, `noPlayT5Rate`) ao `GoldfishResult`
2. No loop de simulacao (linha ~180), rastrear: `minCastableCmc = min(nonland_cmc for nonland in cardsAvailable)`, verificar se `minCastableCmc <= min(landsPlayed, 3)` a cada turno, contar maos onde isso falha ate T3/T4/T5
3. Expor no JSON de resultado do GoldfishSimulator
4. Opcional: adicionar alerta no quality gate quando `noPlayT3Rate > 0.12`

**Validacao:**
```bash
cd server
dart analyze lib/ai/goldfish_simulator.dart
dart test test/optimization_validator_test.dart
```

---

### [P2] Double-null cards invisiveis ao classificador — risco de swap auto

**Conhecimento MTG:** A analise do Lorehold (Purpose Analyzer v3-v3.5) identificou 7 cartas onde AMBOS os classificadores falham: `functional_tag IS NULL` (classificador single-tag) E `card_tags` sem entradas (multi-tag). Essas cartas sao completamente invisiveis ao ManaLoom. O risco: o sistema de swap pode cortar Scroll Rack (engine central) ou Penance (miracle enabler) porque nao reconhece sua funcao. Destas 7: Scroll Rack e Penance sao engines criticos (risco de corte = CRITICO), Grand Abolisher e Ruby Medallion tem risco medio, Pearl Medallion e Galadriel's Dismissal tem risco baixo mas sao candidatos a corte indevido.

**Evidencia no codigo:**
- `server/lib/ai/optimization_functional_roles.dart:55-125` -- `classifyOptimizationFunctionalRole()` retorna `artifact`/`enchantment`/`utility` para estas cartas
- `server/lib/ai/functional_card_tags.dart` -- Multi-tag classifier tambem falha (cartas como "Scroll Rack" nao tem pattern compativel)
- `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` -- Query: `SELECT dc.card_name FROM deck_cards dc LEFT JOIN card_tags ct ON ct.deck_card_id = dc.id WHERE dc.deck_id = 6 AND dc.functional_tag IS NULL AND ct.deck_card_id IS NULL GROUP BY dc.card_name` retorna 7 cartas

**Gap:** Nao ha mecanismo de fallback para cartas que ambos classificadores falham. O quality gate trata essas cartas como `utility` sem funcao especifica, tornando-as candidatas a swap. Alem disso, Pearl/Ruby Medallion sao classificados como `ramp` (porque `oracle.contains('add')` em artifact) mas sao cost-reduction, gerando falsos positivos de contagem de ramp.

**Impacto:**
1. **Scroll Rack** (CMC 2, topdeck engine): Risco CRITICO de swap auto -- core do motor Lorehold
2. **Penance** (CMC 3, topdeck + anti-removal): Risco CRITICO -- miracle enabler
3. **Grand Abolisher** (protection): Risco alto
4. **Ruby/Pearl Medallion** (cost reduction): Risco medio -- classificados como `ramp` mas sao cost-reduction

**Acao recomendada:**
1. Criar tabela `protected_cards` (card_name, reason, override_role) no PostgreSQL -- whitelist manual
2. Adicionar check no `filterUnsafeOptimizeSwapsByCardData()`: consultar `protected_cards` antes de permitir swap
3. Adicionar tag `cost_reduction` ao classificador (diferente de `ramp`) para Medallions
4. Adicionar oracle patterns para "Scroll Rack" (look at top N + rearrange) e "Penance" (return to top of library)

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_quality_gate.dart lib/ai/optimization_functional_roles.dart
dart test test/optimization_quality_gate_test.dart
```

---

### [P3] THEMES.md 19 temas nao validados vs EDHREC

**Conhecimento MTG:** O THEMES.md contem 27 temas, dos quais apenas ~8 foram validados contra dados reais de EDHREC. Os seguintes temas estao marcados como "NAO VALIDADO": Spellslinger, Graveyard, Tokens, +1/+1 Counters, Voltron, Blink/Flicker, Wheels, Reanimator, Mill, Zombies, Knights, Merfolk, Humans, Stax/Prison, Combo (Proactive), Group Slug, Superfriends, Cascade. Estes temas representam a maioria do formato Commander -- decks desses archetypes recebem recomendacoes baseadas em ranges defasados ou chute.

**Evidencia no codigo:**
- `docs/hermes-analysis/manaloom-knowledge/THEMES.md:207-224` -- 19 temas marcados "NAO VALIDADO"
- `docs/hermes-analysis/manaloom-knowledge/THEMES.md:226-240` -- VALIDADOS mostram discrepancias significativas (ex: Goblins ramp SUPERESTIMADO 50-100%, Haste/Untap AUSENTE)
- `server/lib/ai/theme_contextual_rules_service.dart` -- Le `theme_contextual_rules` do PostgreSQL que alimenta o quality gate

**Gap:** Os `theme_contextual_rules` no PostgreSQL contem ranges nao-validados para 19/27 temas. O quality gate compara decks contra ranges potencialmente errados. Os temas validados (Goblins, Vampires) mostram discrepancias de 50-100% em metricas individuais.

**Impacto:** Decks de Reanimator, Mill, Voltron etc. sao validados contra ranges que podem estar 50-100% fora da realidade, gerando falsos positivos (bloqueiam swaps validos) ou falsos negativos (permitem decks desbalanceados).

**Acao recomendada:**
1. Priorizar validacao de Spellslinger (e o archetype do Lorehold, deck ativo no pipeline)
2. Reanimator e Graveyard sao os mais comuns na comunidade EDH -- segunda prioridade
3. Para cada tema: extrair metricas de EDHREC avg deck + commander profiles, comparar com THEMES.md, documentar discrepancias
4. Atualizar `theme_contextual_rules` no PostgreSQL com ranges corrigidos
5. Marcar temas VALIDADOS no THEMES.md com data e fontes

**Validacao:** Validacao manual contra EDHREC live data. Sem teste de codigo (mudanca de dados, nao de logica).

---

## Tasks Ja Ativos (mantidos de sintese anterior)

### [P1] Weakness-analysis usa heuristicas legacy -- sem adapter F1

**Evidencia no codigo:**
- `server/routes/ai/weakness-analysis/index.dart:114-170` -- Conta ramp/draw/removal/wipes por oracle_text local
- `server/routes/ai/weakness-analysis/index.dart:380-430` -- Recomendacoes sao listas fixas de nomes

**Acao:** Refatorar para usar `resolveCardFunctionalRoles()` + queries em card_function_tags

### [P1] Wincon detection fragil -- battle_analyst + weakness-analysis

**Evidencia no codigo:**
- `server/lib/ai/optimization_quality_gate.dart:346-353` -- `_criticalRolesForArchetype()` NAO inclui `wincon`
- `server/routes/ai/weakness-analysis/index.dart:400-420` -- Patterns fixos

**Acao:** Adicionar `wincon` aos roles criticos; refatorar para usar adapter F1

### [P2] Write-only tables -- deck_matchups, deck_weakness_reports, ml_prompt_feedback

**Evidencia no codigo:**
- `server/routes/ai/simulate-matchup/index.dart:360` -- INSERT em deck_matchups
- `server/routes/ai/weakness-analysis/index.dart:374` -- INSERT em deck_weakness_reports
- `server/lib/ml_knowledge_service.dart:251` -- INSERT em ml_prompt_feedback

**Acao:** Adicionar SELECT para cache ou documentar como audit logs com retention policy

### [P3] manual-de-instrucao.md desatualizado

**Evidencia:** Nao menciona F1, F3, bracket expansion, card_deck_profiles, payoff expansion, singleton reset (d3cfaf3b), dead code cleanup (8cab6400).

**Acao:** Atualizar com todos os commits desde a ultima atualizacao.

---

## Tasks Resolvidos (referencia historica)

| Task | Commit |
|:-----|:-------|
| BracketCategory enum (boardWipe, cardAdvantage, stax, protection, valueEngine) | ae886b11 |
| card_deck_profiles integration | d8b7b26b |
| _looksLikePayoff damage payoffs | 3fb17356 |
| CONTEXTO_PRODUTO_ATUAL.md update | 7ed5b863 |
