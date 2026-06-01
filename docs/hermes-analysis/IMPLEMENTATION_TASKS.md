# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes x codigo atual.
> Data: 2026-06-01 | Branch: origin/master | SHA: 798317af
> Ultima sintese anterior: da7c4754 | Novas tasks: P1-h, P1-i, P2-f, P2-g

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | ATIVO |
| P1-d | P1 | Wincon detection fragil — battle_analyst + weakness-analysis usam hardcoded names | ATIVO |
| P1-e | P1 | GoldfishSimulator nao calcula "Sem Play T3" — metrica critica ausente | **RESOLVIDO (798317af)** |
| P1-f | P1 | optimize_request_support nao carrega card_function_tags — drift semantico | **RESOLVIDO (6af73d87)** |
| P1-g | P1 | card_rulings (76.991 rulings) nao integrado ao validator | ATIVO (NOVO — sintese anterior) |
| P1-h | P1 | Python classify_card() nao chama _looksLike* — classificador truncado | **ATIVO (NOVO)** |
| P1-i | P1 | Dart single-tag _looksLike* heuristicas mais estreitas que multi-tag — 21.5% divergencia | **ATIVO (NOVO)** |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia no SQLite | ATIVO |
| P2-c | P2 | Write-only tables: deck_matchups, deck_weakness_reports, ml_prompt_feedback | ATIVO |
| P2-d | P2 | Double-null cards invisiveis ao classificador — risco de swap auto | ATIVO |
| P2-e | P2 | Synergy-axis evaluation ausente do quality gate — so verifica role==role | ATIVO (NOVO — sintese anterior) |
| P2-f | P2 | fp/fn tracking no tag_accuracy — colunas existem mas nunca populadas | **ATIVO (NOVO)** |
| P2-g | P2 | 77 cartas (19.7%) sem oracle text — multi-tag classifier nao roda | **ATIVO (NOVO)** |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil (oracle text) | ATIVO |
| P3-c | P3 | manual-de-instrucao.md nao reflete F1/F3/bracket expansion | ATIVO |
| P3-d | P3 | THEMES.md 19 temas nao validados vs EDHREC | ATIVO |
| P3-e | P3 | MDFC duplicate detection ausente do deck validation | ATIVO (NOVO — sintese anterior) |

---

### [P1] Python classify_card() missing strategic _looksLike* calls — classificador truncado

**Conhecimento MTG:** O TAG_ACCURACY_REPORT (2026-06-01, commit 006d92c9) analisou 22 tags com 391 amostras. 7 tags estrategicas estao abaixo de 85% de precisao (payoff 35.5%, enabler 50%, combo_piece 50%, protection 69.2%, engine 75%, wincon 75%). A causa raiz: o classificador Python single-tag (classify_card()) e uma versao TRUNCADA do Dart — ele NAO chama _looksLikeWincon, _looksLikeEngine, _looksLikePayoff, _looksLikeEnabler, _looksLikeComboPiece. Isso significa que cartas como Blood Artist (payoff), Basalt Monolith (combo_piece), e Korvold (engine) sao classificadas apenas pelo type-based fallback (creature/artifact/enchantment/utility).

**Evidencia no codigo:**
- scryfall_classifier.py:155-221 — classify_card() retorna apenas: land, draw, removal, wipe, ramp, tutor, protection, creature, artifact, enchantment, planeswalker, utility. NENHUMA chamada a _looksLike* para tags estrategicos.
- scryfall_classifier.py:446-496 — As funcoes _looksLikeWincon/Engine/Payoff/Enabler/ComboPiece EXISTEM em Python, mas sao usadas apenas pelo infer_functional_card_tags() (multi-tag), NAO pelo classify_card() (single-tag).
- optimization_functional_roles.dart:113-117 — O Dart equivalent (classifyOptimizationFunctionalRole) CHAMA _looksLikeWincon/Engine/ComboPiece/Payoff/Enabler. O Python NAO.

**Gap:** Todas as analises baseadas em Python (validators, scouts, mana base validator, import_card_profiles, import_knowledge) usam classify_card() para determinar o functional_tag. Um classificador truncado significa que cartas estrategicas sao sistematicamente mal-classificadas em todo o pipeline Python.

**Impacto:**
1. Cartas como Blood Artist (payoff real) recebem tag removal — o Evolution Oracle pode corta-las achando que sao removal redundante
2. Basalt Monolith (combo_piece real) recebe tag ramp ou artifact — nao e tratado como peca de combo
3. 29 cartas double-null (7.4% das nao-terreno) sao parcialmente causadas por este gap no Python
4. O pipeline Lorehold (Scout, Validator, Oracle) processa dados Python com classificacao inferior

**Acao recomendada:**
1. Adicionar chamadas _looksLike* ao classify_card() entre protecao e type-based fallback (linha ~210 do scryfall_classifier.py):
   - if _looksLikeWincon(oracle, name_lower): return 'wincon'
   - if _looksLikeEngine(oracle): return 'engine'
   - if _looksLikeComboPiece(oracle, name_lower): return 'combo_piece'
   - if _looksLikePayoff(oracle, name_lower): return 'payoff'
   - if _looksLikeEnabler(oracle, name_lower): return 'enabler'
2. As funcoes _looksLike* ja existem no arquivo (linhas 446-496) — so precisam ser CHAMADAS
3. Rodar o script de validacao de tags apos a correcao para medir melhora na precisao

**Validacao:**
```bash
cd docs/hermes-analysis/manaloom-knowledge
python3 scripts/scryfall_classifier.py  # verificar que nao quebrou
python3 -c "
from scryfall_classifier import classify_card
print(classify_card({'name':'Blood Artist','type_line':'Creature','oracle_text':'Whenever Blood Artist or another creature dies, target player loses 1 life and you gain 1 life.','cmc':2}))
# Esperado: 'payoff'
"
```

---

### [P1] Dart single-tag _looksLike* narrower than multi-tag — 21.5% divergencia

**Conhecimento MTG:** O TAG_ACCURACY_REPORT revelou uma distribuicao bimodal de precisao: 15 tags a 100% (mecanicas) vs 7 tags abaixo de 85% (estrategicas). A causa: as heuristicas _looksLike* no classificador single-tag (optimization_functional_roles.dart) sao muito MAIS estreitas que as equivalentes no multi-tag (functional_card_tags.dart). Resultado: 84 cartas (21.5% das nao-terreno) tem functional_tag (single-tag) que NAO aparece nos card_tags (multi-tag). O sistema discorda de si mesmo em 1 a cada 5 cartas.

**Evidencia no codigo:**
- optimization_functional_roles.dart:370-398 — single-tag _looksLike*:
  - _looksLikeWincon: 3 patterns (you win / opponent loses / opponents lose). Falta: each opponent loses, damage equal to...opponent, hardcoded combo names.
  - _looksLikeEngine: requer you may + draw/create/add. Falta: whenever...draw sem you may (Rhystic Study, Mystic Remora, Esper Sentinel).
  - _looksLikePayoff: whenever...create token OU whenever you cast...copy/scry. Falta: for each, creature dies trigger (Blood Artist, Zulaport Cutthroat).
  - _looksLikeEnabler: cost less to cast. Falta: haste enablers, additional land drops, sacrifice->mana (Ashnod's Altar), mill engines.
  - _looksLikeComboPiece: 2 patterns. Falta: untap+add mana (Basalt Monolith), infinite, copy activated ability.
- functional_card_tags.dart:859-905 — multi-tag _looksLike*:
  - MESMAS funcoes, mas com MAIS patterns: hardcoded names, each opponent loses, for each, haste, mill, creature dies, untap && add, infinite.

**Gap:** O single-tag classifier (usado para functional_tag e metricas de deck como ramp_count, draw_count, etc.) tem heuristicas SIGNIFICATIVAMENTE mais estreitas que o multi-tag. Isso causa metricas de deck distorcidas e o Evolution Oracle toma decisoes baseadas em metricas erradas.

**Impacto:**
1. payoff a 35.5% de precisao: 20 das 31 cartas com tag payoff estao erradas
2. enabler a 50%: 21 enablers invisiveis ao single-tag
3. protection a 69.2%: counterspells como Fierce Guardianship classificados como removal
4. Divergencia single/multi de 21.5% prova que o sistema tem dados melhores que nao usa

**Acao recomendada:**
1. Curto prazo: Expandir _looksLike* no single-tag (optimization_functional_roles.dart:370-398) com patterns do multi-tag:
   - _looksLikeWincon: adicionar each opponent loses life, damage equal to opponent
   - _looksLikeEngine: adicionar whenever...draw sem you may, whenever an opponent...you may draw
   - _looksLikePayoff: adicionar for each, whenever...creature dies
   - _looksLikeEnabler: adicionar sacrifice creature add, haste, additional land
   - _looksLikeComboPiece: adicionar untap add, infinite, copy activated ability
2. Medio prazo: Unificar — usar multi-tag como fallback quando single-tag retorna type-based

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_functional_roles.dart lib/ai/functional_card_tags.dart
dart test test/optimization_functional_roles_test.dart
```

---

### [P2] fp/fn tracking no tag_accuracy — colunas existem mas nunca populadas

**Conhecimento MTG:** O TAG_ACCURACY_REPORT descobriu que as colunas false_positive e false_negative da tabela tag_accuracy existem desde a criacao do schema mas estao ZERADAS em todas as 22 tags. O script knowledge_db.py (linha 431) so registra tag_match booleano (0 ou 1) e atualiza correct_count e total_count. Sem tracking granular, e impossivel saber QUAIS cartas especificas foram classificadas errado — apenas o agregado.

**Evidencia no codigo:**
- knowledge_db.py:429-439 — tag_match = 1 if analysis.get("tag_match", 1) else 0 seguido de INSERT com correct_count + tag_match, total_count + 1. Nao ha nenhuma referencia a false_positive ou false_negative.
- SQLite: SELECT false_positive, false_negative FROM tag_accuracy — todas as 22 linhas retornam (0, 0)
- Schema: false_positive INTEGER DEFAULT 0, false_negative INTEGER DEFAULT 0 — colunas existem mas nunca sao escritas

**Gap:** O sistema de medicao de qualidade de tags e cego para erros especificos. Sabemos que payoff tem 35.5% de precisao, mas nao sabemos QUAIS 20 cartas estao erradas, nem POR QUE.

**Impacto:**
1. Impossivel medir melhora apos correcoes de heuristica (P1-h, P1-i)
2. Nao ha como priorizar quais heuristicas expandir primeiro
3. Erros de classificacao nao sao rastreaveis ao longo do tempo
4. O sistema nao aprende com seus proprios erros

**Acao recomendada:**
1. Adicionar tabela tag_errors ao knowledge_db.py com: card_name, deck_id, assigned_tag, expected_tag, error_type (fp/fn), oracle_text, type_line, cmc
2. Modificar knowledge_db.py para popular tag_errors quando tag_match = 0
3. Atualizar false_positive e false_negative no tag_accuracy com COUNT da tabela tag_errors
4. Adicionar query --stats que lista top erros por tag

**Validacao:**
```bash
cd docs/hermes-analysis/manaloom-knowledge
python3 scripts/knowledge_db.py --stats
sqlite3 scripts/knowledge.db "SELECT error_type, COUNT(*) FROM tag_errors GROUP BY error_type"
```

---

### [P2] 77 cartas (19.7%) sem oracle text — multi-tag classifier nao roda

**Conhecimento MTG:** O TAG_ACCURACY_REPORT identificou que 77 cartas nao-terreno (19.7%) nao tem NENHUMA entrada em card_tags. Destas, 48 tem functional_tag = creature ou enchantment — sao criaturas com oracle text vazio ou minimal (ex: Drannith Magistrate, Ethersworn Canonist, Aven Mindcensor). O multi-tag classifier (infer_functional_card_tags) depende de oracle_text para funcionar — sem ele, retorna lista vazia ou apenas type-based.

**Evidencia no codigo:**
- functional_card_tags.dart:180-200 — inferFunctionalCardTags() comeca chamando _classifyByOraclePatterns(oracle) — se oracle for vazio, retorna lista vazia
- scryfall_classifier.py:280-500 — infer_functional_card_tags() tambem requer oracle_text para as heuristicas _looksLike*
- As 77 cartas sem multi-tags se sobrepoem parcialmente com as 29 double-null (P2-d)
- PostgreSQL card_oracle_data tem 453 linhas, mas deck_cards pode ter mais — o gap e de dados, nao de codigo

**Gap:** Cartas sem oracle_text sao invisiveis ao multi-tag classifier. Elas recebem apenas type-based classification (creature/artifact/enchantment) e perdem toda a informacao estrategica que o multi-tag proveria.

**Impacto:**
1. 19.7% das cartas nao-terreno tem analise funcional incompleta
2. Cartas como Drannith Magistrate (stax piece) e Aven Mindcensor (tutor hate) sao classificadas apenas como creature
3. Agrava o problema double-null (P2-d)
4. O problema e transversal — afeta todos os decks, nao so o Lorehold

**Acao recomendada:**
1. Rodar bulk fetch da Scryfall API para preencher oracle_text de todas as cartas em deck_cards que nao tem entrada em card_oracle_data (PostgreSQL) ou oracle_text (SQLite)
2. Priorizar as 77 cartas identificadas no TAG_ACCURACY_REPORT
3. Adicionar verificacao no fluxo de importacao de deck: se oracle_text IS NULL, buscar da Scryfall API antes de classificar
4. Apos backfill, re-executar o multi-tag classifier (infer_functional_card_tags) para essas 77 cartas

**Validacao:**
```bash
cd docs/hermes-analysis/manaloom-knowledge
python3 -c "
import sqlite3
conn = sqlite3.connect('scripts/knowledge.db')
c = conn.cursor()
c.execute('''SELECT COUNT(*) FROM deck_cards WHERE type_line NOT LIKE '%land%' AND (oracle_text IS NULL OR oracle_text = '')''')
print(f'Cartas sem oracle_text: {c.fetchone()[0]}')
conn.close()
"
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
