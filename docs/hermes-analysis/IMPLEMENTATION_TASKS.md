# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes x codigo atual.
> Data: 2026-06-02T19:20:00+00:00 | Branch: origin/master | SHA: `e754c0ec` | Analysis branch: codex/hermes-analysis-docs
> Ultima sintese anterior: 2026-06-01T19:19:14+00:00 (SHA 2891aa53) | Novas tasks: P1-l, P1-m, P1-n, P2-k, P2-l

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | ATIVO |
| P1-d | P1 | Wincon detection fragil | ATIVO |
| P1-e | P1 | GoldfishSimulator nao calcula Sem Play T3 | RESOLVIDO (798317af) |
| P1-f | P1 | optimize_request_support nao carrega card_function_tags | RESOLVIDO (6af73d87) |
| P1-g | P1 | card_rulings (76.991 rulings) nao integrado ao validator | ATIVO |
| P1-h | P1 | Python classify_card() nao chama _looksLike* | ATIVO |
| P1-i | P1 | Dart single-tag _looksLike* mais estreitas que multi-tag | ATIVO |
| P1-j | P1 | Pipeline Integrity: validator sem hash verification | ATIVO |
| P1-k | P1 | resolveOptimizeArchetype duplicado com semantica divergente | ATIVO |
| **P1-l** | **P1** | **verifySwapIntegrity (163 linhas) com zero call-sites — verif. inerte** | **NOVO** |
| **P1-m** | **P1** | **Bulk import bypassa classificadores — 20 tags 'unknown', 0 card_tags** | **NOVO** |
| **P1-n** | **P1** | **Ritual/fast-mana misclassified — 7/13 fontes ramp com tag errada** | **NOVO** |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia | ATIVO |
| P2-c | P2 | Write-only tables | ATIVO |
| P2-d | P2 | Double-null cards invisiveis ao classificador | ATIVO |
| P2-e | P2 | Synergy-axis ausente do quality gate | ATIVO |
| P2-f | P2 | fp/fn tracking nunca populado | ATIVO |
| P2-g | P2 | 77 cartas sem oracle text | ATIVO |
| P2-h | P2 | card_deck_analysis (wincon scores) — 0 refs no Dart | ATIVO |
| P2-i | P2 | Evolution Oracle swap scripts lack post-exec verification | ATIVO |
| P2-j | P2 | Basic land detection: 4 variantes incompatíveis | ATIVO |
| **P2-k** | **P2** | **archetypeToTheme() cobre apenas 12 patterns — misclassifica** | **NOVO** |
| **P2-l** | **P2** | **GoldfishSimulator nao simula tapped lands — T3 superestimado** | **NOVO** |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil | ATIVO |
| P3-c | P3 | manual-de-instrucao.md desatualizado | ATIVO |
| P3-d | P3 | THEMES.md 19 temas nao validados | ATIVO |
| P3-e | P3 | MDFC duplicate detection ausente | ATIVO |

---

### [P1] verifySwapIntegrity infrastructure exists but has zero call-sites

**Conhecimento MTG:** O SCOUT_LOG #35 (2026-06-01) descobriu que Flare of Duplication e Twinflame estao AUSENTES do deck apesar de documentadas como adicionadas no Ciclo #10. O sistema gerou os swaps, documentou a aplicacao, mas os swaps NUNCA OCORRERAM. Nenhum agente detectou por 13+ ciclos.

**Evidencia no codigo:**
- `server/lib/ai/optimize_swap_integrity.dart` — 163 linhas com `computeSwapIntegrity()` (linha 84), `verifySwapIntegrity()` (linha 112), classe `SwapIntegrity`
- `rg "optimize_swap_integrity" server/lib/ --glob '*.dart'` → 0 resultados — NENHUM import
- `rg "computeSwapIntegrity|verifySwapIntegrity" server/lib/ --glob '*.dart'` → 0 resultados — NENHUM call-site
- COMMIT_DIGEST (e754c0ec): "`verifySwapIntegrity` definido mas nunca chamado"

**Gap:** 163 linhas de codigo morto. Infraestrutura de verificacao de integridade de swaps existe mas e completamente inerte — o hash SHA-256 nunca e computado durante optimize e nunca verificado apos aplicacao.

**Impacto:**
1. Codigo que deveria prevenir o incidente Flare/Twinflame nunca e executado
2. Swaps que falham silenciosamente (INSERT rejeitado, constraint violation) nunca sao detectados
3. Evolution Oracle confia cegamente que seus swaps foram aplicados

**Risco:** P1 — quebra silenciosa do pipeline.

**Acao recomendada:**
1. Adicionar import de `optimize_swap_integrity.dart` no fluxo de optimize
2. Chamar `computeSwapIntegrity()` durante optimize e incluir no response body
3. Adicionar endpoint ou verificacao `verifySwapIntegrity()` no Evolution Oracle

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimize_swap_integrity.dart lib/ai/optimize_runtime_support.dart
dart test test/optimize_swap_integrity_test.dart
```

---

### [P1] Bulk import bypasses ALL classifiers — 20 'unknown' tags, 0/100 card_tags, no post-import health check

**Conhecimento MTG:** SCOUT_LOG #36 (2026-06-02T18:33:43) emitiu alerta de integridade: deck Lorehold reconstruido como cEDH. Purpose Analyzer v3.23 confirmou `alert-pipeline-integrity-crisis`. A skill documenta pitfall "Bulk Import Data Corruption — Classifier NEVER Ran": cards importados recebem `functional_tag='unknown'`, CMC=NULL, type_line=NULL, zero `card_tags`.

**Evidencia no codigo:**
- Nao ha post-import health check em nenhum arquivo Dart (`rg "bulk.import|post.import|health.check" server/lib/ --glob '*.dart'` → 0 resultados)
- Fluxo de import em Python (`scripts/import_*.py`) nao chama `classify_card()` ou `infer_functional_card_tags()`
- Query double-null (`WHERE functional_tag IS NULL`) nao pega 'unknown' (string, nao NULL)

**Evidencia no banco (SQLite, deck_id=6, 2026-06-02T19:20Z):**
- 20/100 cartas com `functional_tag='unknown'`
- 0/100 cartas com entradas em `card_tags` (multi-tag classifier NUNCA rodou)
- 7/100 cartas com `cmc=NULL`, 6/100 com `type_line=NULL`
- Hash atual: `f2241d994743e8142396c0f846917fde` (deck ja mudou 3x desde SCOUT #35)

**Gap:** Quando um deck e importado em massa, o classificador nunca roda. Metricas `ramp_count=6` (real: ~13), `draw_count=6` (real: ~9-10). Otimizador opera com dados corrompidos.

**Impacto:**
1. Optimization engine recomenda swaps baseados em metricas falsas
2. Mulligan simulator usa `functional_tag='ramp'` para keepability — 8.8pp de erro
3. Double-null query nao detecta as 20 cartas 'unknown'
4. Evolution Oracle pode cortar cartas essenciais achando que sao fillers

**Risco:** P1 — dados corrompidos no pipeline principal.

**Acao recomendada:**
1. Adicionar `_runPostImportHealthCheck(String deckId)` que detecta 'unknown' tags, NULL CMC, zero card_tags
2. Corrigir query double-null: `WHERE (dc.functional_tag IS NULL OR dc.functional_tag = 'unknown') AND ct.deck_card_id IS NULL`
3. Modificar scripts Python de import para chamar classificador apos INSERT
4. Executar correcao imediata no deck atual: re-classificar todas as 100 cartas

**Validacao:**
```bash
python3 -c "
import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
c = conn.cursor()
c.execute("SELECT COUNT(*) FROM deck_cards WHERE deck_id=6 AND functional_tag='unknown'")
assert c.fetchone()[0] == 0, 'Ainda ha cartas unknown!'
c.execute('SELECT COUNT(DISTINCT dc.id) FROM deck_cards dc JOIN card_tags ct ON ct.deck_card_id = dc.id WHERE dc.deck_id=6')
assert c.fetchone()[0] >= 85, 'Multi-tag nao rodou!'
print('OK')
"
```

---

### [P1] Ritual and fast-mana cards misclassified — 7 of 13 real ramp sources have wrong tag

**Conhecimento MTG:** Em cEDH, fast mana inclui rituais (Rite of Flame, Seething Song, Jeska's Will) e rocks (Mana Vault, Arcane Signet). O SCOUT_LOG #36 identificou que o deck tem fast mana package mas DB reporta `ramp_count=6`.

**Evidencia no codigo:**
- `optimization_functional_roles.dart:55-125` — `classifyOptimizationFunctionalRole()` so retorna 'ramp' para fetch-lands e ramp spells com 'search.*library.*land'. NAO detecta rituais (add {R}{R}{R}) nem rocks ({T}: Add).
- `scryfall_classifier.py:155-221` — `classify_card()`: mesmo problema.

**Evidencia no banco (SQLite, deck_id=6):**

| Card | Real Function | DB Tag | CMC |
|:-----|:--------------|:-------|:---:|
| Sol Ring | fast mana | **unknown** | 1 |
| Mana Vault | fast mana | **unknown** | - |
| Rite of Flame | ritual | **spell** | 1 |
| Seething Song | ritual | **spell** | 3 |
| Jeska's Will | ritual | **draw** | 3 |
| Mana Geyser | ritual | **spell** | 5 |
| Boros Signet | rock | **unknown** | 2 |

7/13 fontes de mana acelerada com tag errada. Apenas 6 corretas.

**Gap:** Classificador nao reconhece rituais nem mana rocks como 'ramp'. So busca de terrenos e mana dorks sao detectados. Em decks cEDH, causa subestimacao massiva (6 reportado vs 13 real — 54% de erro).

**Impacto:**
1. Otimizador acha que deck tem pouca ramp e recomenda adicionar mais
2. Mulligan simulator faz mulligan agressivo em maos com ritual/rock nao-detectado
3. Evolution Oracle pode trocar ritual (CMC 1-3) por ramp spell de fetch (CMC 2-4) achando que esta adicionando ramp

**Risco:** P1 — metricas estruturais corrompidas afetam todo o pipeline.

**Acao recomendada:**
1. Expandir `_looksLikeRamp()` com padroes para:
   - Rituais: oracle contem "add {R}" ou "add {W}" seguido de quantidade
   - Rocks: type_line contem 'artifact' + oracle contem '{T}: Add'
   - Treasure generators: oracle contem "create.*treasure token"
2. Re-executar classificador no deck atual apos correcao

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_functional_roles.dart
dart test test/optimization_functional_roles_test.dart
# Testes: Rite of Flame, Seething Song, Jeska's Will → tag 'ramp'
```

---

### [P2] archetypeToTheme() covers only 12 patterns — order-dependent matching causes misclassification

**Conhecimento MTG:** SCOUT_LOG #36 detectou deck Lorehold reconstruido como "cEDH-adjacent: fast mana + tutor denso + protection". Tema correto seria `cedh_combo`, mas `archetypeToTheme()` pode retornar 'spellslinger' por causa da ordem dos ifs.

**Evidencia no codigo:**
- `theme_contextual_rules_service.dart:54-68` — `archetypeToTheme()`:
  ```dart
  if (a.contains('spellslinger') || a.contains('spells')) return 'spellslinger'; // PRIMEIRO
  // ...
  if (a.contains('combo') || a.contains('cedh')) return 'cedh_combo';           // PENULTIMO
  ```
  "cEDH Boros Spellslinger" → match no primeiro if → retorna 'spellslinger' (ERRADO)

**Gap:** Genericos (spellslinger, token) sao verificados ANTES de especificos (cedh, combo). Apenas 12 padroes — THEMES.md tem 42 temas.

**Impacto:**
1. Deck cEDH classificado como 'spellslinger' — recebe regras de validacao erradas
2. Fallback `a.replaceAll(' ', '_')` cria nomes de tema inexistentes no PG → zero regras

**Risco:** P2 — servico de validacao tematica retorna regras erradas.

**Acao recomendada:**
1. Reordenar ifs: cedh/combo primeiro, spellslinger/token depois
2. Substituir cadeia de ifs por map lookup para todos os 42 temas

**Validacao:**
```bash
cd server
dart analyze lib/ai/theme_contextual_rules_service.dart
dart test test/theme_contextual_rules_service_test.dart
# "cEDH Boros Spellslinger" → 'cedh_combo' (nao 'spellslinger')
```

---

### [P2] GoldfishSimulator doesn't simulate tapped lands — T3 playable rate overestimated by 3-8pp

**Conhecimento MTG:** A skill documenta: "The mulligan simulation treats ALL lands as untapped on the turn they enter. Tapped lands (Temple of Triumph, Boros Garrison) are not simulated → T3 real is worse than reported by 3-8pp."

**Evidencia no codigo:**
- `goldfish_simulator.dart` — `_canPlayOnTurn()` (linha ~174): verifica `landsPlayed >= turn` mas NAO verifica se a land entra tapped
- `rg "tapped|enters the battlefield tapped" goldfish_simulator.dart` → 0 resultados
- `optimization_validator.dart:37` usa `GoldfishSimulator` diretamente

**Gap:** Simulador assume que toda land entra desvirada. Temple of Triumph T1 → so desvira T2. Boros Garrison T2 → so desvira T3. O validator toma decisoes estrategicas baseadas em T3 inflado.

**Impacto:**
1. T3 reportado 13% → real 16-18% → Evolution Oracle usa estrategia BALANCED quando deveria usar DEFENSIVE
2. Decks budget/casual com muitas tapped lands sao os mais afetados

**Risco:** P2 — validator superestima consistencia, levando a estrategias menos conservadoras.

**Acao recomendada:**
1. Adicionar `_isTappedLand(card)` que detecta "enters the battlefield tapped" no oracle
2. Modificar `_canPlayOnTurn()` para rastrear quais lands entram tapped
3. Como fallback: se >20% tapped lands, aplicar fator de correcao de -3-5pp no T3

**Validacao:**
```bash
cd server
dart analyze lib/ai/goldfish_simulator.dart lib/ai/optimization_validator.dart
dart test test/goldfish_simulator_test.dart
# Deck com 4 tapped lands → T3 playable < deck com 4 basics
```

---

## Tasks Ja Ativos (mantidos de sintese anterior)

### [P1] card_rulings (76.991 rulings) nao integrado ao validator — trocas sem validacao de regras

**Conhecimento MTG:** O VALIDATOR_LOG v3.20 (Purpose Analyzer) usa ativamente a tabela card_rulings do PostgreSQL para verificar interacoes entre cartas. Exemplos criticos encontrados: "Lorehold + Miracle: card com Miracle DEVE ser revelado antes de entrar na mao", "Dualcaster Mage: copia na stack NAO e conjurada", "Arcane Bombardment: se sair do campo, cartas exiladas PERMANECEM".

**Evidencia no codigo:**
- optimization_validator.dart:28-86 — validate() tem 3 camadas mas nenhuma consulta card_rulings
- optimization_quality_gate.dart:18-80 — filterUnsafeOptimizeSwapsByCardData() nao verifica interacoes de regras
- Nenhuma referencia a card_rulings em todo server/lib/ (0 resultados)
- Tabela existe no PostgreSQL com 76.991 rulings, mas e completamente write-only

**Gap:** O validator nao consegue detectar que uma troca proposta quebra interacoes documentadas nas rulings oficiais.

**Acao recomendada:**
1. Criar CardRulingsService que consulta card_rulings por nome de carta
2. Adicionar 4a camada _validateSwapRulings() no optimization_validator.dart
3. Foco inicial: verificar palavras-chave de interacao (cast vs copy, triggered vs activated)
4. Retornar warning (nao block) — a Critic IA decide com contexto

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_validator.dart
dart test test/optimization_validator_test.dart
```

---

### [P2] Synergy-axis evaluation ausente do quality gate — so verifica rolePreserved

**Conhecimento MTG:** O SYNERGY_MAP (7 eixos) classifica cada carta. O quality gate verifica APENAS removedRole == addedRole — mas duas cartas podem ter o mesmo role e afetar eixos DIFERENTES.

**Evidencia no codigo:**
- optimization_quality_gate.dart:55-56 — rolePreserved = removedRole == addedRole
- Nao ha verificacao de eixo estrategico ou synergy group

**Acao recomendada:**
1. Adicionar funcao _classifySynergyAxis(String oracle) que retorna um dos 7 eixos
2. No quality gate, verificar se o swap remove a ultima carta de um eixo → WARNING
3. Nao precisa bloquear — adicionar droppedReasons com warning

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_quality_gate.dart lib/ai/optimization_functional_roles.dart
dart test test/optimization_quality_gate_test.dart
```

---

### [P3] MDFC duplicate detection ausente do deck validation

**Conhecimento MTG:** O VALIDATOR_LOG v3.20 descobriu que o deck Lorehold tem DUAS linhas para a mesma carta MDFC: Valakut Awakening e Valakut Awakening // Valakut Stoneforge. O SUM(quantity)=100 conta a MESMA carta duas vezes.

**Evidencia no codigo:**
- optimization_validator.dart — verifica total cards, lands, singleton, mas NAO detecta MDFC duplicados
- deck_rules_service.dart — validacao sem MDFC awareness
- Nenhum arquivo em server/lib/ referencia MDFC ou double-faced

**Acao recomendada:**
1. Adicionar funcao _deduplicateMdfcCards() que detecta pares Name + Name // BackFace
2. Integrar no fluxo de importacao de deck (antes de INSERT) e no validator
3. Commit 798317af ja adicionou normalizePhysicalCardCopyName — estender para o deck validator

**Validacao:**
```bash
cd server
dart analyze lib/deck_rules_service.dart lib/ai/optimization_validator.dart
dart test test/deck_rules_service_test.dart
```

---

### [P1] ~~GoldfishSimulator nao calcula "Sem Play T3"~~ → RESOLVIDO (798317af)

**Commit:** 798317af — Harden deck rules and goldfish curve checks

**O que foi implementado:**
- Campo noPlayTurn3Rate adicionado ao GoldfishResult
- Teste novo: TC013b valida normalizePhysicalCardCopyName para MDFC/split
- Abordagem usa _canPlayOnTurn que verifica cores + custo

### [P1] Weakness-analysis usa heuristicas legacy — sem adapter F1

**Evidencia no codigo:**
- server/routes/ai/weakness-analysis/index.dart:114-170 — Conta ramp/draw/removal/wipes por oracle_text local
- server/routes/ai/weakness-analysis/index.dart:380-430 — Recomendacoes sao listas fixas de nomes

**Acao:** Refatorar para usar resolveCardFunctionalRoles() + queries em card_function_tags.

### [P1] Wincon detection fragil — battle_analyst + weakness-analysis

**Evidencia no codigo:**
- optimization_quality_gate.dart:346-353 — _criticalRolesForArchetype() NAO inclui wincon
- server/routes/ai/weakness-analysis/index.dart:400-420 — Patterns fixos

**Acao:** Adicionar wincon aos roles criticos; refatorar para usar adapter F1.

### [P2] Double-null cards invisiveis ao classificador — risco de swap auto

**Evidencia no codigo:**
- optimization_functional_roles.dart:55-125 — classifyOptimizationFunctionalRole() retorna artifact/enchantment/utility para Scroll Rack, Penance, etc.
- functional_card_tags.dart — Multi-tag classifier tambem falha

**Update 2026-06-01:** Commit 6af73d87 (P1-f) carrega card_function_tags nas queries SQL. TAG_ACCURACY_REPORT identificou 29 double-nulls (7.4% das nao-terreno). Verificar se as double-nulls restantes tem card_function_tags no PostgreSQL.

### [P2] Write-only tables — deck_matchups, deck_weakness_reports, ml_prompt_feedback

**Acao:** Adicionar SELECT para cache ou documentar como audit logs com retention policy.

### [P2] Tags ninja/stax_disruption com 0% de acuracia no SQLite

**Acao:** Investigar e corrigir heuristica de classificacao ou remover tags com 0% de precisao. Nota: TAG_ACCURACY_REPORT analisou 22 tags; ninja e stax_disruption nao estao entre elas — estas tags podem existir apenas no PostgreSQL card_function_tags.

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
| Resolve learning pipeline backlog (deck_advanced_analysis, simulate-matchup, combo detection) | **e754c0ec** | 2026-06-02 |
