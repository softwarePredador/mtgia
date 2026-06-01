# Implementation Tasks — ManaLoom

> Gerado por sintese: cruzamento do conhecimento MTG do Hermes x codigo atual.
> Data: 2026-06-01T19:19:14+00:00 | Branch: origin/codex/hermes-analysis-docs | SHA: 2891aa53
> Ultima sintese anterior: 798317af | Novas tasks: P1-j, P1-k, P2-h, P2-i, P2-j

## Resumo de Status

| # | Prioridade | Titulo | Status |
|:--|:-----------|:-------|:-------|
| P1-a | P1 | BracketCategory enum nao detecta Game Changers | RESOLVIDO (ae886b11) |
| P1-b | P1 | card_deck_profiles nao consultado pelo optimize | RESOLVIDO (d8b7b26b) |
| P1-c | P1 | Weakness-analysis usa heuristicas legacy (sem adapter F1) | ATIVO |
| P1-d | P1 | Wincon detection fragil — battle_analyst + weakness-analysis usam hardcoded names | ATIVO |
| P1-e | P1 | GoldfishSimulator nao calcula "Sem Play T3" — metrica critica ausente | RESOLVIDO (798317af) |
| P1-f | P1 | optimize_request_support nao carrega card_function_tags — drift semantico | RESOLVIDO (6af73d87) |
| P1-g | P1 | card_rulings (76.991 rulings) nao integrado ao validator | ATIVO |
| P1-h | P1 | Python classify_card() nao chama _looksLike* — classificador truncado | ATIVO |
| P1-i | P1 | Dart single-tag _looksLike* heuristicas mais estreitas que multi-tag — 21.5% divergencia | ATIVO |
| **P1-j** | **P1** | **Pipeline Integrity: optimization_validator nao verifica hash do deck no step 0** | **ATIVO (NOVO)** |
| **P1-k** | **P1** | **resolveOptimizeArchetype duplicado com semantica divergente — risco de drift** | **ATIVO (NOVO)** |
| P2-a | P2 | _looksLikePayoff nao detecta payoffs de dano direto | RESOLVIDO (3fb17356) |
| P2-b | P2 | Tags ninja/stax_disruption com 0% de acuracia no SQLite | ATIVO |
| P2-c | P2 | Write-only tables: deck_matchups, deck_weakness_reports, ml_prompt_feedback | ATIVO |
| P2-d | P2 | Double-null cards invisiveis ao classificador — risco de swap auto | ATIVO |
| P2-e | P2 | Synergy-axis evaluation ausente do quality gate — so verifica role==role | ATIVO |
| P2-f | P2 | fp/fn tracking no tag_accuracy — colunas existem mas nunca populadas | ATIVO |
| P2-g | P2 | 77 cartas (19.7%) sem oracle text — multi-tag classifier nao roda | ATIVO |
| **P2-h** | **P2** | **PG card_deck_analysis (wincon scores: speed/resilience/stealth) — 0 refs no Dart** | **ATIVO (NOVO)** |
| **P2-i** | **P2** | **Evolution Oracle swap scripts lack post-execution verification** | **ATIVO (NOVO)** |
| **P2-j** | **P2** | **Basic land detection: 4 variantes incompatíveis em optimize/validation/meta/commander** | **ATIVO (NOVO)** |
| P3-a | P3 | CONTEXTO_PRODUTO_ATUAL.md desatualizado | RESOLVIDO (7ed5b863) |
| P3-b | P3 | Weakness-analysis wincon detection fragil (oracle text) | ATIVO |
| P3-c | P3 | manual-de-instrucao.md nao reflete F1/F3/bracket expansion | ATIVO |
| P3-d | P3 | THEMES.md 19 temas nao validados vs EDHREC | ATIVO |
| P3-e | P3 | MDFC duplicate detection ausente do deck validation | ATIVO |

---

### [P1] Pipeline Integrity: optimization_validator.dart lacks step-0 deck hash verification

**Conhecimento MTG:** O SCOUT_LOG #34 (2026-06-01) descobriu que 6+ agentes (Evolution Oracle C#18-C#22, SCOUT #30-#33, VALIDATOR v3.17-v3.18) copiaram o mesmo hash `a440c497da4280d6769238737062b3dd` sem re-verificar contra o DB. O hash real do deck era `30d00347764fc2a215edb4e668994871`. Se um swap manual tivesse ocorrido, NENHUM agente teria percebido. O VALIDATOR_LOG v3.20+ foi o primeiro a detectar a discrepancia.

**Evidencia no codigo:**
- optimization_validator.dart:28-86 — validate() salta diretamente para Monte Carlo (_runMonteCarloComparison) na linha 37 sem NENHUMA verificacao de estado do deck.
- Nao ha funcao _verifyDeckHash() ou equivalente em optimization_validator.dart.
- O metodo validate() recebe originalDeck e optimizedDeck como parametros mas nao verifica se correspondem ao estado real do DB.
- O pipeline de Evolution Oracle (manaloom-mtg-domain skill, protocolo de swap) documenta a necessidade de hash verification mas o codigo Dart nao implementa.

**Gap:** O validator (e por extensao o Evolution Oracle) opera sobre dados que podem estar STALE. Nao ha verificacao de que os decks recebidos como parametro batem com o estado atual do banco. Se o usuario fez swaps manuais ou um script de swap anterior falhou silenciosamente (caso Flare/Twinflame — ver P2-i), o sistema inteiro opera com premissas erradas.

**Impacto:**
1. Swaps manuais do usuario sao invisiveis ao pipeline — o sistema reporta "deck estavel" quando nao esta
2. Scripts de swap que falham silenciosamente (INSERT rejeitado, constraint violada) nao sao detectados
3. 6+ agentes operaram com hash errado por multiplos ciclos sem deteccao
4. A unica defesa atual e o SCOUT_LOG verificar manualmente — mas isso depende do scout rodar

**Acao recomendada:**
1. Adicionar funcao estatica `_computeDeckCardHash(String deckId)` que consulta `deck_cards` no PostgreSQL/SQLite e computa MD5 de `card_name` ordenado
2. No inicio de validate() (linha 29), chamar `_verifyDeckHash()` comparando com hash armazenado no header do ultimo VALIDATOR_LOG/EVOLUTION_LOG
3. Se mismatch: emitir `PipelineIntegrityWarning` no ValidationReport e recusar validacao com dados stale
4. Integrar o hash verification tambem no fluxo do Evolution Oracle (otimizacao) antes de propor swaps

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_validator.dart
dart test test/optimization_validator_test.dart
```

---

### [P1] resolveOptimizeArchetype duplicated with divergent semantics — code drift risk

**Conhecimento MTG:** O STRUCTURE_AUDIT.md (rodada 2026-06-01) identificou duplicacao critica de funcao com semantica divergente. O ManaLoom tem DUAS implementacoes de `resolveOptimizeArchetype` que tomam decisoes diferentes para os mesmos inputs.

**Evidencia no codigo:**
- `server/lib/ai/deck_state_analysis.dart:573-585` — Versao A:
  ```dart
  String resolveOptimizeArchetype({
    required String? requestedArchetype,  // NULLABLE
    required String? detectedArchetype,
  })
  ```
  Genericos: `{midrange, general, value, tempo}`. Se requested e null → retorna detected. Se detected e null → retorna requested. Se generico → retorna detected.

- `server/lib/ai/optimize_runtime_support.dart:3369-3389` — Versao B:
  ```dart
  String resolveOptimizeArchetype({
    required String requestedArchetype,    // NOT NULLABLE
    required String? detectedArchetype,
  })
  ```
  Genericos: `{midrange, value, goodstuff}` (diferente!). Especificos: `{aggro, control, combo, stax, tribal}`. Trata `unknown` como vazio. Nao inclui `general` nem `tempo` como genericos.

- Consumo divergente:
  - `rebuild_guided_service.dart:171` usa Versao A (deck_state_analysis)
  - `optimize_request_support.dart:289, :294` usa Versao B (optimize_runtime_support)

**Gap:** Dois fluxos de runtime (rebuild vs optimize) podem classificar o MESMO deck com arquetipos diferentes. Um deck "general" seria tratado como generico pela Versao A (retorna detected) mas como nao-mapeado pela Versao B (retorna requested porque 'general' nao esta em genericRequested).

**Impacto:**
1. Inconsistencia de arquetipo entre rebuild e optimize — mesmo deck pode ter estrategias diferentes
2. Drift silencioso: se uma versao for atualizada e a outra nao, a divergencia aumenta
3. Testes que cobrem uma versao nao validam a outra
4. Dificulta debug: mesma funcao, mesmo nome, comportamento diferente

**Acao recomendada:**
1. Extrair para helper compartilhado em `server/lib/ai/archetype_resolver.dart`
2. Suportar ambos os signatures (nullable e non-nullable requestedArchetype) com sobrecarga ou parametro opcional
3. Unificar conjuntos de genericos: `{midrange, general, value, tempo, goodstuff}`
4. Adicionar testes unitarios que cubram TODOS os casos de borda: null, vazio, unknown, general, tempo, goodstuff, midrange, aggro, control, combo, stax, tribal
5. Atualizar rebuild_guided_service.dart e optimize_request_support.dart para importar do helper unificado

**Validacao:**
```bash
cd server
dart analyze lib/ai/archetype_resolver.dart lib/ai/deck_state_analysis.dart lib/ai/optimize_runtime_support.dart
dart test test/archetype_resolver_test.dart
```

---

### [P2] PostgreSQL card_deck_analysis table has wincon scores but zero references in Dart backend

**Conhecimento MTG:** O SCOUT_LOG #35 (Wincon Audit, 2026-06-01) usou a tabela PostgreSQL `card_deck_analysis` para obter scores de wincon com 3 eixos: **speed** (rapidez, 1-10), **resilience** (resistencia a remocao, 1-10), **stealth** (furtividade, 1-10). Exemplos: Mizzix's Mastery (16/30), Worldfire (14/30, R=7 — IMBATIVEL), Approach of the Second Sun (12/30, S=6 — RAPIDA, ST=1 — ARQUI-INIMIGO). Esta e a unica tabela no sistema que avalia wincons com criterios de jogo real.

**Evidencia no codigo:**
- `rg -r card_deck_analysis server/lib/` → 0 resultados. NENHUM arquivo Dart referencia esta tabela.
- optimization_validator.dart:28-86 — validate() tem 3 camadas mas nenhuma consulta wincon scores
- optimization_quality_gate.dart:346-353 — _criticalRolesForArchetype() NAO inclui 'wincon' em nenhum arquetipo
- SCOUT_LOG (Python) usa a tabela via psql; o backend Dart nao

**Gap:** O ManaLoom tem dados de qualidade de wincon no PostgreSQL mas o backend Dart nunca os consulta. O quality gate nao consegue avaliar se um swap proposto remove uma wincon IMBATIVEL (R>=7) ou ARQUI-INIMIGO (ST=1). O validator nao reporta a qualidade das wincons do deck.

**Impacto:**
1. Evolution Oracle pode trocar uma wincon R=9 (Rise of the Eldrazi) por uma carta de draw sem saber o impacto
2. Abordagem do SCOUT_LOG (ST=1 — todo mundo ve e responde) nao e detectada pelo quality gate
3. Wincons com resilience baixa (R<=3 — morre pra qualquer remocao) nao sao flagadas
4. Dado rico existe mas e write-only para o backend — so o SCOUT_LOG (Python) usa

**Acao recomendada:**
1. Criar `CardDeckAnalysisService` em `server/lib/ai/card_deck_analysis_service.dart` que consulta PG
2. Metodo: `Future<Map<String, WinconScores>> fetchWinconScores(List<String> cardNames)` retorna speed/resilience/stealth por carta
3. Integrar no optimization_validator.dart como camada 2.7 (entre functional e critic): `_validateWinconQuality()`
4. Regras de warning:
   - Se swap remove unica wincon com R >= 7 → WARNING "removendo wincon imbatível"
   - Se ST <= 2 em deck sem protecao → INFO "wincon pinta alvo — considere Flare/Grand Abolisher"
   - Se R <= 3 → INFO "wincon frágil — morre pra qualquer remocao"
5. Adicionar `wincon` ao _criticalRolesForArchetype() no quality gate quando card_deck_analysis confirmar que a carta e wincon

**Validacao:**
```bash
cd server
dart analyze lib/ai/card_deck_analysis_service.dart lib/ai/optimization_validator.dart
dart test test/optimization_validator_test.dart
```

---

### [P2] Evolution Oracle swap scripts lack post-execution verification — Flare/Twinflame missing from DB

**Conhecimento MTG:** O SCOUT_LOG #35 (2026-06-01) emitiu um 🚨 ALERTA DE INTEGRIDADE: Flare of Duplication (CMC 3) e Twinflame (CMC 2) estao documentadas como adicionadas no Ciclo #10 pelo Evolution Oracle, mas NAO estao presentes no deck (deck_cards WHERE deck_id=6). Estas duas cartas sao as wincons de MAIOR IMPACTO na colecao: Flare permite combo deterministico com Approach of the Second Sun no mesmo turno; Twinflame permite combo infinito com Dualcaster Mage (ja no deck). Sem elas, Approach e ARQUI-INIMIGO (ST=1) e Dualcaster perde seu principal combo.

**Evidencia no codigo:**
- O protocolo de swap do Evolution Oracle (documentado no skill manaloom-commander-knowledge) inclui script Python com INSERT/DELETE e `conn.commit()` — mas NAO inclui verificacao pos-execucao.
- O template de swap script termina com verificacoes de integridade (SUM(quantity)=100, commander count=1, lands>=34) mas NAO verifica se as cartas ESPECIFICAS inseridas estao realmente la.
- SCOUT_LOG #35: "Estas duas cartas sao as wincons de MAIOR IMPACTO disponiveis na colecao que NAO estao no deck."

**Gap:** Scripts de swap podem falhar silenciosamente por diversos motivos (constraint violation, nome de carta com encoding diferente, race condition com outro cron, file ownership impedindo DB write) e o sistema nao detecta. O Flare e Twinflame estao ausentes ha 13 ciclos (C#10 → C#22) sem deteccao.

**Impacto:**
1. Duas wincons deterministicas estao AUSENTES do deck apesar de documentadas como presentes
2. Approach of the Second Sun (63.8% EDHREC) esta sem seu combo principal (Flare)
3. Dualcaster Mage esta sem seu payoff principal (Twinflame)
4. O deck e efetivamente mais fraco do que o sistema acredita
5. 13 ciclos de Evolution Oracle operaram com premissa errada sobre o estado do deck

**Acao recomendada:**
1. Adicionar ao template de swap script (Python) uma verificacao pos-INSERT:
   ```python
   # After conn.commit()
   for card_name in added_cards:
       c.execute("SELECT 1 FROM deck_cards WHERE deck_id=? AND card_name=?", (deck_id, card_name))
       assert c.fetchone() is not None, f"FALHA: {card_name} nao foi inserida!"
   ```
2. Re-executar o script de swap do Ciclo #10 para corrigir o estado atual (adicionar Flare + Twinflame)
3. Adicionar verificacao de hash no Evolution Oracle (ver P1-j) para detectar swaps nao-aplicados em ciclos futuros
4. Registrar no EVOLUTION_LOG quando um swap e verificado com sucesso (nao apenas quando e proposto)

**Validacao:**
```bash
cd docs/hermes-analysis/manaloom-knowledge
python3 -c "
import sqlite3
conn = sqlite3.connect('scripts/knowledge.db')
c = conn.cursor()
c.execute("SELECT card_name FROM deck_cards WHERE deck_id=6 AND card_name IN ('Flare of Duplication', 'Twinflame')")
missing = c.fetchall()
assert len(missing) == 2, f'Flare/Twinflame ainda ausentes! Encontradas: {missing}'
print('OK: Flare and Twinflame confirmed in deck')
conn.close()
"
```

---

### [P2] Basic land detection: 4 incompatible variants across optimize/validation/meta/commander-reference

**Conhecimento MTG:** O STRUCTURE_AUDIT.md (rodada 2026-06-01) identificou que a deteccao de terrenos basicos (incluindo snow basics) tem 4 implementacoes diferentes com comportamento INCOMPATIVEL. Snow basics (Snow-Covered Plains, etc.) sao tratados como basicos em alguns contextos e ignorados em outros.

**Evidencia no codigo:**
- `server/lib/ai/optimize_runtime_support.dart:4184-4197` — Match EXATO para `snow-covered ...` (com hifen). Nao reconhece variacoes sem hifen.
- `server/lib/generated_deck_validation_service.dart:752-763` — Usa `startsWith('snow-covered ...')` (prefixo). Mais abrangente que optimize mas ainda requer hifen.
- `server/lib/meta/meta_deck_reference_support.dart:890-903` — Procura `snow covered ...` SEM hifen. Nao detecta a forma canonica com hifen!
- `server/routes/ai/commander-reference/index.dart:621-628` — NAO INCLUI snow basics. Trata apenas os 5 basic land types.

**Gap:** Um deck com Snow-Covered Plains pode ser tratado como tendo lands basicas pelo meta reference (sem hifen → nao detecta), como nao tendo pelo optimize (com hifen → detecta), e como nao tendo pelo commander-reference (ignora snow). Isso causa contagem inconsistente de lands entre servicos.

**Impacto:**
1. Contagem de basic lands diverge entre optimize e generated validation
2. Decks com snow basics podem ter metricas de mana diferentes dependendo de qual servico consulta
3. Commander reference nao reconhece snow basics como opcoes de land para comandantes mono-color
4. Meta reference falha em detectar snow basics com a forma canonica (com hifen)

**Acao recomendada:**
1. Extrair funcao compartilhada `bool _isBasicLandName(String name)` em `server/lib/card_utils.dart`
2. Implementacao unificada que cobre TODAS as variantes:
   - 5 basic land names (Plains, Island, Swamp, Mountain, Forest)
   - Snow-Covered variants (com e sem hifen)
   - Case-insensitive matching
3. Atualizar optimize_runtime_support.dart, generated_deck_validation_service.dart, meta_deck_reference_support.dart, e commander-reference/index.dart para usar a funcao compartilhada
4. Adicionar testes unitarios com todas as variantes de nome

**Validacao:**
```bash
cd server
dart analyze lib/card_utils.dart lib/ai/optimize_runtime_support.dart lib/generated_deck_validation_service.dart
dart test test/card_utils_test.dart
```

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
