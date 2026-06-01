# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes x codigo atual.
> Data: 2026-06-01 | Branch: origin/master | SHA: 798317af

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | ATIVO |
| P1-d | P1 | Wincon detection fragil — battle_analyst + weakness-analysis usam hardcoded names | ATIVO |
| P1-e | P1 | GoldfishSimulator nao calcula "Sem Play T3" — metrica critica ausente | **RESOLVIDO (798317af)** |
| P1-f | P1 | optimize_request_support nao carrega card_function_tags — drift semantico | **RESOLVIDO (6af73d87)** |
| P1-g | P1 | card_rulings (76.991 rulings) nao integrado ao validator | **ATIVO (NOVO)** |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia no SQLite | ATIVO |
| P2-c | P2 | Write-only tables: deck_matchups, deck_weakness_reports, ml_prompt_feedback | ATIVO |
| P2-d | P2 | Double-null cards invisiveis ao classificador — risco de swap auto | ATIVO |
| P2-e | P2 | Synergy-axis evaluation ausente do quality gate — so verifica role==role | **ATIVO (NOVO)** |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil (oracle text) | ATIVO |
| P3-c | P3 | manual-de-instrucao.md nao reflete F1/F3/bracket expansion | ATIVO |
| P3-d | P3 | THEMES.md 19 temas nao validados vs EDHREC | ATIVO |
| P3-e | P3 | MDFC duplicate detection ausente do deck validation | **ATIVO (NOVO)** |

---

### [P1] card_rulings (76.991 rulings) nao integrado ao validator — trocas sem validacao de regras

**Conhecimento MTG:** O VALIDATOR_LOG v3.20 (Purpose Analyzer) usa ativamente a tabela `card_rulings` do PostgreSQL para verificar interacoes entre cartas. Exemplos criticos encontrados: "Lorehold + Miracle: card com Miracle DEVE ser revelado antes de entrar na mao — draw vs tutor: efeitos que colocam cartas na mao sem usar 'draw' NAO ativam Miracle", "Dualcaster Mage: copia na stack NAO e 'conjurada' — nao ativa Lorehold nem Bombardment", "Arcane Bombardment: se sair do campo, cartas exiladas PERMANECEM — nova copia nao acessa exilio anterior". Estas regras sao essenciais para validar swaps — trocar Dualcaster por uma carta que depende de "conjurar" muda radicalmente as sinergias.

**Evidencia no codigo:**
- `server/lib/ai/optimization_validator.dart:28-86` — `validate()` tem 3 camadas (Monte Carlo, Analise Funcional, Critic IA) mas nenhuma consulta `card_rulings`
- `server/lib/ai/optimization_quality_gate.dart:18-80` — `filterUnsafeOptimizeSwapsByCardData()` verifica role, CMC delta, land trim, structural recovery — mas nao verifica interacoes de regras
- Nenhuma referencia a `card_rulings` em TODO o diretorio `server/lib/` (0 resultados)
- Tabela existe no PostgreSQL com 76.991 rulings, mas e completamente write-only do ponto de vista do backend

**Gap:** O validator nao consegue detectar que uma troca proposta (ex: remover Dualcaster Mage para adicionar um payoff de "conjurar") quebra interacoes documentadas nas rulings oficiais. A Critic IA pode capturar parcialmente, mas rulings oficiais sao deterministicas.

**Impacto:**
1. Swaps que parecem bons (CMCs compativeis, roles preservados) podem quebrar sinergias documentadas
2. Exemplo real: trocar Dualcaster Mage (copy na stack, nao-conjurada) por Primal Amulet (so conta spells CONJURADOS) — ambos sao "engine" mas interagem com o deck de forma OPOSTA
3. A Critic IA (3a camada) e a unica protecao — e depende de prompt engineering, nao de dados deterministicos
4. O quality gate aprovaria o swap porque removedRole=engine == addedRole=engine

**Acao recomendada:**
1. Criar `CardRulingsService` que consulta `card_rulings` por nome de carta
2. Adicionar 4a camada `_validateSwapRulings()` no `optimization_validator.dart`
3. Para cada swap (removal → addition), verificar se ha rulings conflitantes com o commander ou com outras cartas do deck
4. Foco inicial: verificar palavras-chave de interacao (cast vs copy, triggered ability vs activated ability, "whenever you cast" vs "whenever you copy")
5. Retornar warning (nao block) quando rulings sugerem anti-sinergia — a Critic IA decide com contexto

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_validator.dart
dart test test/optimization_validator_test.dart
```

---

### [P2] Synergy-axis evaluation ausente do quality gate — so verifica rolePreserved

**Conhecimento MTG:** O SYNERGY_MAP (v3.8+, 7 eixos: Token/Pump, Board Wipes+Protection, Recursion, Explosive Mana, Combo Pieces, Stack Interaction, Resilience) classifica cada carta do deck em seu eixo estrategico. O quality gate atual verifica APENAS se `removedRole == addedRole` — mas duas cartas podem ter o mesmo role (ex: ambas "engine") e afetar eixos DIFERENTES. Exemplo real do Lorehold: trocar Dualcaster Mage (engine, eixo F: Stack Interaction) por Primal Amulet (engine, eixo D: Explosive Mana) preserva role mas reduz Stack Interaction de 5→4 (ja e o eixo mais fraco do deck, score 5/10).

**Evidencia no codigo:**
- `server/lib/ai/optimization_quality_gate.dart:55-56` — `final rolePreserved = removedRole == addedRole || (removedRole == 'utility' && addedRole == 'utility');`
- `server/lib/ai/optimization_quality_gate.dart:58-60` — `final losingCriticalRole = criticalRoles.contains(removedRole) && !rolePreserved;`
- Nao ha nenhuma verificacao de "eixo estrategico" ou "synergy group" — apenas role atomico
- `server/lib/ai/optimization_functional_roles.dart:370-398` — As funcoes `_looksLikeWincon`, `_looksLikeEngine`, `_looksLikeComboPiece`, `_looksLikePayoff`, `_looksLikeEnabler` sao booleanas e nao capturam eixos

**Gap:** O quality gate opera em granularidade de role atomico (1 carta = 1 role), mas a realidade estrategica opera em granularidade de eixo (varias cartas colaboram). Uma troca que remove 1 de 2 cartas de stack interaction e uma perda de 50% no eixo — mas o quality gate ve "engine → engine: aprovado".

**Impacto:**
1. Swaps que diluem eixos criticos passam no quality gate silenciosamente
2. O deck Lorehold perdeu Flare of Duplication e Twinflame (Stack Interaction) em ciclos recentes — o quality gate nao alertou porque o role era preservado
3. Stack Interaction (eixo F) caiu de 6/10 para 5/10 sem nenhum alerta do sistema
4. O problema e especialmente grave em Boros (RW) que ja tem stack interaction naturalmente fraca

**Acao recomendada:**
1. Adicionar funcao `_classifySynergyAxis(String oracle)` que retorna um dos 7 eixos baseado em patterns de oracle text:
   - TOKEN_PUMP: "create...token" + "double strike"/"gets +"
   - WIPES_PROTECTION: board wipe patterns + "indestructible"/"hexproof"/"phase out"
   - RECURSION: "return...from your graveyard" + "flashback"/"overload"
   - EXPLOSIVE_MANA: "add {R}" + "treasure" + ritual patterns
   - COMBO_PIECES: "you win the game" + deterministic patterns
   - STACK_INTERACTION: "counter target" + "copy target" + "can't be countered"
   - RESILIENCE: "prevent all damage" + "protection from" + fog patterns
2. No quality gate, verificar se o swap remove a ultima carta de um eixo (count_before=1, count_after=0) → WARNING
3. Nao precisa bloquear — apenas adicionar `droppedReasons` com "⚠️ Este swap remove a ultima carta do eixo Stack Interaction (score atual: 5/10)"
4. A Critic IA usa esse warning para tomar decisao final

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_quality_gate.dart lib/ai/optimization_functional_roles.dart
dart test test/optimization_quality_gate_test.dart
```

---

### [P3] MDFC duplicate detection ausente do deck validation

**Conhecimento MTG:** O VALIDATOR_LOG v3.20 descobriu que o deck Lorehold tem DUAS linhas no DB para a mesma carta fisica MDFC (Modal Double-Faced Card): `Valakut Awakening` (id=653, tag=draw) e `Valakut Awakening // Valakut Stoneforge` (id=350, tag=land). O `SUM(quantity)=100` conta a MESMA carta duas vezes. O deck real tem 99 cartas fisicas. Este e um problema recorrente documentado no skill `manaloom-commander-knowledge` (pitfall MDFC).

**Evidencia no codigo:**
- `server/lib/ai/optimization_validator.dart` — O validator verifica total cards, lands, e singleton, mas NAO detecta MDFC duplicados
- `server/lib/deck_rules_service.dart` — Validacao de deck (commander, singleton, color identity) sem MDFC awareness
- Nenhum arquivo em `server/lib/` referencia "MDFC" ou "double-faced" ou "//"

**Gap:** O sistema de validacao de deck nao reconhece que `Card Name` e `Card Name // Card Name` representam a MESMA carta fisica. Isso infla contagens (total cards, draw_count, land_count) e mascara a contagem real.

**Impacto:**
1. Deck reporta 100 cartas mas tem 99 fisicas — singleton check e misleading
2. draw_count inflado em +1 (Valakut Awakening front-face conta como draw)
3. O problema afeta QUALQUER deck com MDFC — nao e exclusivo do Lorehold
4. Agentes downstream (Scout, Evolution Oracle) operam com metricas infladas

**Acao recomendada:**
1. Adicionar funcao `_deduplicateMdfcCards(List<Map<String, dynamic>> cards)` que detecta pares `Name` + `Name // BackFace` e remove a linha front-face-only
2. Integrar no fluxo de importacao de deck (antes de INSERT) e no validator
3. Heuristica: se existe `card_name LIKE '% // %'` e tambem existe `card_name = substring before ' //'`, o front-face-only e duplicado
4. Manter a linha MDFC completa (com `//`) que tem tag mais abrangente

**Validacao:**
```bash
cd server
dart analyze lib/deck_rules_service.dart lib/ai/optimization_validator.dart
dart test test/deck_rules_service_test.dart
```

---

## Tasks Ja Ativos (mantidos de sintese anterior)

### [P1] ~~GoldfishSimulator nao calcula "Sem Play T3"~~ → RESOLVIDO (798317af)

**Commit:** `798317af` — Harden deck rules and goldfish curve checks

**O que foi implementado:**
- Campo `noPlayTurn3Rate` adicionado ao `GoldfishResult`
- Rastreamento: `noPlayTurn3Hands` incrementado quando `!_canPlayOnTurn(cardsAvailable, 3, ...)` 
- Recomendacao quando >12%: sugere ramp, compra ou interacao barata
- Exposicao no JSON: `no_play_turn_3`
- Teste novo: `test/optimization_rules_test.dart` — TC013b valida `normalizePhysicalCardCopyName` para MDFC/split
- Abordagem difere da sugestao original (`minCastableCmc`) — usa o metodo existente `_canPlayOnTurn` que e mais robusto (verifica cores + custo)

### [P1] Weakness-analysis usa heuristicas legacy — sem adapter F1

**Evidencia no codigo:**
- `server/routes/ai/weakness-analysis/index.dart:114-170` — Conta ramp/draw/removal/wipes por oracle_text local
- `server/routes/ai/weakness-analysis/index.dart:380-430` — Recomendacoes sao listas fixas de nomes

**Acao:** Refatorar para usar `resolveCardFunctionalRoles()` + queries em `card_function_tags`.

### [P1] Wincon detection fragil — battle_analyst + weakness-analysis

**Evidencia no codigo:**
- `server/lib/ai/optimization_quality_gate.dart:346-353` — `_criticalRolesForArchetype()` NAO inclui wincon
- `server/routes/ai/weakness-analysis/index.dart:400-420` — Patterns fixos

**Acao:** Adicionar wincon aos roles criticos; refatorar para usar adapter F1.

### [P2] Double-null cards invisiveis ao classificador — risco de swap auto

**Evidencia no codigo:**
- `server/lib/ai/optimization_functional_roles.dart:55-125` — `classifyOptimizationFunctionalRole()` retorna artifact/enchantment/utility para Scroll Rack, Penance, etc.
- `server/lib/ai/functional_card_tags.dart` — Multi-tag classifier tambem falha

**Update 2026-06-01:** Commit `6af73d87` (P1-f) carrega `card_function_tags` nas queries SQL do optimize — isso REDUZ mas nao ELIMINA o problema. Cartas que ambos classificadores falham (double-null) continuam invisiveis. Verificar se as 4 double-nulls restantes (Scroll Rack, Penance, Grand Abolisher, Taunt) tem `card_function_tags` populados no PostgreSQL.

### [P2] Write-only tables — deck_matchups, deck_weakness_reports, ml_prompt_feedback

**Acao:** Adicionar SELECT para cache ou documentar como audit logs com retention policy.

### [P2] Tags ninja/stax_disruption com 0% de acuracia no SQLite

**Acao:** Investigar e corrigir heuristica de classificacao ou remover tags com 0% de precisao.

### [P3] Weakness-analysis wincon detection fragil (oracle text)

**Acao:** Refatorar deteccao de wincon para usar adapter F1 + card_function_tags.

### [P3] manual-de-instrucao.md desatualizado

**Evidencia:** Nao menciona F1, F3, bracket expansion, card_deck_profiles, payoff expansion, singleton reset (d3cfaf3b), dead code cleanup (8cab6400, 23cfc061), semantic drift fix (6af73d87).

**Acao:** Atualizar com todos os commits desde a ultima atualizacao.

### [P3] THEMES.md 19 temas nao validados vs EDHREC

**Acao:** Validar temas prioritarios (Spellslinger, Reanimator, Graveyard) contra EDHREC live data.

---

## Tasks Resolvidos (referencia historica)

| Task | Commit | Data |
|:-----|:-------|:-----|
| BracketCategory enum (boardWipe, cardAdvantage, stax, protection, valueEngine) | ae886b11 | 2026-05-31 |
| card_deck_profiles integration | d8b7b26b | 2026-05-31 |
| _looksLikePayoff damage payoffs | 3fb17356 | 2026-05-31 |
| CONTEXTO_PRODUTO_ATUAL.md update | 7ed5b863 | 2026-05-31 |
| optimize_request_support semantic drift fix (card_function_tags) | **6af73d87** | 2026-05-31 |
| GoldfishSimulator noPlayTurn3Rate + MDFC copy normalization | **798317af** | 2026-06-01 |
