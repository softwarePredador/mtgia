# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-04 por ManaLoom Knowledge Synthesis (Cron)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 498eb1a8
> **Metodo:** 5 gaps priorizados entre conhecimento MTG (crons + SQLite) e codigo Dart

---

### [P1] Bracket Policy: Adicionar 5 categorias mecanicas de Game Changer ao `BracketCategory` enum

**Conhecimento MTG:** O SQLite `game_changers` (53 cartas) classifica GCs em 9 `impact_category`: `value_engine` (17), `fast_mana` (13), `tutor` (12), `card_advantage` (4), `free_interaction` (2), `combo_piece` (2), `stax` (1), `protection` (1), `board_wipe` (1). GAME_CHANGERS.md documenta que 29/53 GCs nao tem deteccao mecanica — sao pegos apenas por nome. Ex: Rhystic Study (`card_advantage`), Cyclonic Rift (`board_wipe`), Drannith Magistrate (`stax`), The One Ring (`value_engine`), Teferi's Protection (`protection`) — todos detectados como `gameChanger` mas sem categoria mecanica.

**Evidencia no codigo:** `server/lib/edh_bracket_policy.dart:7-14` — `BracketCategory` enum tem 6 valores: `fastMana`, `tutor`, `freeInteraction`, `extraTurns`, `infiniteCombo`, `gameChanger`. O `_gameChangerNames` (linhas 280-334) lista todas 53 cartas, mas `tagCardForBracket()` (91-146) so aplica `BracketCategory.gameChanger` via nome (141-143), sem heuristica de oracle text para `card_advantage`, `board_wipe`, `stax`, `value_engine`, ou `protection`.

**Gap:** O sistema detecta QUE uma carta e Game Changer, mas nao POR QUE. As 5 categorias faltantes no enum impedem: (a) limites por categoria mecanica no bracket, (b) deteccao automatica de novos GCs via oracle text, (c) explicacao do impacto estrategico para o usuario.

**Impacto:** `🔴 P1` — Quando Wizards adicionar novos GCs ou ajustar a lista, o sistema so os detectara se forem manualmente adicionados ao `_gameChangerNames`. A falta de heuristicas de oracle text torna a deteccao fragil e nao-escalavel. Alem disso, o bracket policy nao consegue aplicar limites diferentes por tipo de impacto (ex: permitir mais `value_engine` que `stax` no bracket 3).

**Acao recomendada:**
1. Adicionar ao `BracketCategory` enum: `cardAdvantage`, `boardWipe`, `stax`, `valueEngine`, `protection`
2. Implementar heuristicas de oracle text em `tagCardForBracket()` para cada nova categoria:
   - `cardAdvantage`: `"draw a card"` + trigger condition (opponent casts, each upkeep, etc.)
   - `boardWipe`: `"exile all"` ou `"return all"` + `"don't control"` (assimetrico como Cyclonic Rift)
   - `stax`: `"can't"` + restriction on opponents
   - `valueEngine`: continuous/repeatable value generation (The One Ring, Seedborn Muse)
   - `protection`: `"phase out"` ou `"protection from everything"` (Teferi's Protection)
3. Validar contra os 53 GCs do SQLite — conferir se cada um e detectado por categoria mecanica
4. Atualizar `BracketPolicy.forBracket()` com limites por categoria nova nos brackets 2 e 3

**Validacao:**
```bash
cd server && dart analyze lib/edh_bracket_policy.dart
cd server && dart test test/edh_bracket_policy_test.dart
# Rodar script Python que cruza 53 GCs do SQLite com output de tagCardForBracket()
```

---

### [P1] `classifyOptimizationFunctionalRole`: Usar `functional_tags` persistidas como fonte primaria

**Conhecimento MTG:** O LOGIC_COHERENCE_REPORT (2026-05-29, P1) identificou que `classifyOptimizationFunctionalRole()` em `optimization_functional_roles.dart` ignora `functional_tags` persistidas no banco. O VALIDATOR_LOG v3.23 mostra que 20+ cartas importadas em massa ficam com `functional_tag='unknown'` e CMC incorreto — o classificador nunca rodou. O `summarizeFunctionalTagsForDeck()` (functional_card_tags.dart) ja prioriza persisted → semantic_v2 → heuristic, mas o `classifyOptimizationFunctionalRole()` usa apenas semantic_v2 → heuristic.

**Evidencia no codigo:** `server/lib/ai/optimization_functional_roles.dart:55-124` — `classifyOptimizationFunctionalRole()`:
- Linha 56-58: Tenta `_classifySemanticV2FunctionalRole()` (semantic_tags_v2 apenas)
- Linha 60-124: Cai para heuristicas de oracle text (`looksLikeOptimizationBoardWipeText`, `looksLikeOptimizationRampText`, etc.)
- **NAO consulta** `card_function_tags` persistidas (tabela PG/SQLite com `functional_tag`).
Enquanto isso, `server/lib/ai/functional_card_tags.dart:432-465` (`summarizeFunctionalTagsForDeck`) prioriza `persistedTags` → `semanticV2` → `inferredTags`.

**Gap:** Duas pipelines de classificacao com prioridades diferentes. O validator/quality-gate pode classificar uma carta como `utility` enquanto a analise de deck a classifica como `draw` — causando falsos negativos no quality gate (bloqueia swap que preserva funcao) e falsos positivos (aprova swap que perde funcao critica).

**Impacto:** `🔴 P1` — Swaps validos sao bloqueados pelo quality gate porque o `classifyOptimizationFunctionalRole` nao reconhece a tag persistida. Swaps que removem funcoes criticas (removal, draw, ramp) podem ser aprovados se a tag persistida nao for consultada. O deck analysis reporta metricas diferentes do que o optimize/validator usa.

**Acao recomendada:**
1. Adicionar `List<Map<String, dynamic>>? persistedFunctionalTags` como parametro opcional de `classifyOptimizationFunctionalRole()`
2. Consultar `card_function_tags` para a carta ANTES de cair para heuristicas
3. Se existir tag persistida com `confidence >= 0.7`, usar como papel funcional
4. Alinhar com a mesma prioridade: `persisted > semantic_v2 > heuristic`

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_functional_roles.dart
cd server && dart test test/ai/optimization_functional_roles_test.dart
# Verificar que o mesmo corpus de 20 cartas produz o mesmo papel em ambos os classificadores
```

---

### [P1] Quality Gate: Integrar `theme_contextual_rules` nas decisoes de swap

**Conhecimento MTG:** THEMES.md documenta 42 temas de Commander com metricas especificas: Elfball precisa de 25-30 elfos (nao 35 lands genericos), Spellslinger precisa de 25+ instants/sorceries, Landfall precisa de 40+ lands. A tabela PG `theme_contextual_rules` (27 regras) existe mas NAO e lida pelo backend. O `manaloom-mtg-domain` skill (Gap 7) documenta: "Metrics nao sao por tema — validator usa ranges genericos independente do tema detectado."

**Evidencia no codigo:** `server/lib/ai/optimization_quality_gate.dart:170-176` — `_recommendedLandCountForArchetype()` so reconhece 3 arquetipos + default:
```dart
if (normalized.contains('aggro')) return 34;
if (normalized.contains('combo')) return 33;
if (normalized.contains('control')) return 37;
return 35;
```
Nao ha awareness de `spellslinger` (precisa de 33-35 lands, mas +5 ramp), `landfall` (precisa de 40+ lands), `elfball` (precisa de 28-30 lands com mana dorks), etc.
`server/lib/ai/optimization_validator.dart:52` — `themeService` existe mas e usado APENAS para validacao, nao para gate de swap.

**Gap:** O quality gate aplica regras genericas de arquetipo para todos os temas. Um swap `land → spell` que e correto para Elfball (precisa de menos lands) e bloqueado. Um swap que remove um enabler critico de tema (ex: cortar um Goblin de Krenko) pode ser aprovado.

**Impacto:** `🔴 P1` — Falsos positivos e negativos no quality gate para decks com temas especificos. O sistema nao entende que um deck de Elves pode operar com 28 lands, ou que um deck Landfall PRECISA de 40+ lands. O theme service ja existe e esta conectado ao PostgreSQL — so falta integra-lo ao quality gate.

**Acao recomendada:**
1. Modificar `_recommendedLandCountForArchetype()` para aceitar `theme` como parametro e consultar `theme_contextual_rules` do PG
2. Adicionar `themeService` ao `filterUnsafeOptimizeSwapsByCardData()` via parametro ou injecao
3. Para cada tema detectado, ajustar: land target, ramp target, draw target, e critical roles
4. Nao bloquear swap `land → spell` quando o deck esta acima do target do tema (ex: 40 lands em Elfball)
5. Nao aprovar swap que remove um `theme_enabler` (carta que o tema define como core)

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_quality_gate.dart
cd server && dart analyze lib/ai/theme_contextual_rules_service.dart
cd server && dart test test/ai/optimization_quality_gate_test.dart
# Testar com deck de Elves (28 lands) vs deck Landfall (42 lands) — ambos devem passar
```

---

### [P2] Candidate Quality: Adicionar `edhrec_inclusion_pct` como metrica de qualidade

**Conhecimento MTG:** O pipeline Hermes (Scout, Validator, Evolution Oracle) usa extensivamente EDHREC inclusion % para avaliar cartas. Ex: Victory Chimes tem 53.6% EDHREC em Lorehold (7.851 decks) mas 0% em torneios. O reverse tambem: Mana Crypt tem 0% EDHREC em Lorehold casual mas e staple cEDH. O `manaloom-mtg-domain` skill (Gap 1) documenta: "EDHREC inclusion rate nao usado — CandidateQualityData so tem meta_deck_count (EDHTop16), nao edhrec_inclusion_pct."

**Evidencia no codigo:** `server/lib/ai/candidate_quality_data_support.dart` — define `candidateQualityAllowedTags` (43 tags) e esquema PG com tabelas `card_role_scores`, `commander_card_synergy`, `optimize_rejection_penalties`, `card_semantic_tags_v2`. NENHUMA tabela ou coluna para `edhrec_inclusion_pct`. O `CandidateQualityData` (definido em optimize_runtime_support.dart) usa `meta_deck_count` de EDHTop16. O PG tem `card_meta_insights` com `usage_count` mas nao `edhrec_inclusion_pct`.

**Gap:** O sistema avalia qualidade de carta usando apenas dados de torneio (~650 meta decks), ignorando o dataset muito maior do EDHREC (~7.800+ decks so para Lorehold). Cartas populares no Commander casual mas ausentes de torneios sao subvalorizadas. Cartas super-representadas em torneios mas raras no casual sao supervalorizadas.

**Impacto:** `🟡 P2` — O optimize pode recomendar cartas de torneio que nao funcionam no contexto casual do deck (ex: fast mana cEDH em deck bracket 2), e pode subestimar cartas casuais fortes (ex: Storm Herd a 75% EDHREC). Nao quebra o sistema, mas reduz a qualidade das recomendacoes.

**Acao recomendada:**
1. Adicionar coluna `edhrec_inclusion_pct NUMERIC(5,2)` a tabela PG `card_deck_profiles` (ja existe)
2. Popular com dados da EDHREC JSON API (`https://json.edhrec.com/pages/commanders/<name>.json`)
3. Criar `CandidateQualityData.edhrecInclusionPct` e peso no scoring
4. Para commanders sem perfil EDHREC, usar `card_meta_insights.usage_count` como proxy

**Validacao:**
```bash
cd server && dart analyze lib/ai/candidate_quality_data_support.dart
# Verificar que card_deck_profiles tem edhrec_inclusion_pct populado
```

---

### [P2] Deck Import: Re-classificar automaticamente cartas com `functional_tag='unknown'`

**Conhecimento MTG:** VALIDATOR_LOG v3.23 (2026-06-02) documenta que apos bulk import, 20 cartas ficaram com `functional_tag='unknown'` (string, nao NULL) e 6 cartas com `CMC=NULL`. O `manaloom-commander-knowledge` skill documenta o pitfall: "Bulk Import Data Corruption — Classifier NEVER Ran". A query de health check mostra resultados em 5 decks (Aesi: 6, Dimir Ninja: 21, Default: 4, Kinnan: 1, Lorehold: 3).

**Evidencia no codigo:** `server/lib/ai/functional_card_tags.dart:432-465` — `summarizeFunctionalTagsForDeck()` prioriza `persistedTags` → `semanticV2` → `inferredTags`. Quando `functional_tag='unknown'` (string), o sistema trata como tag valida e NAO cai para o fallback heuristico. O `'unknown'` e um valor sentinela que deveria trigger reclassificacao, mas nao trigger. Nao ha codigo que detecta `functional_tag='unknown'` e re-executa `inferFunctionalCardTags()`.

**Gap:** Cartas importadas em massa sem classificacao permanecem permanentemente como `'unknown'`. O sistema nunca tenta reclassifica-las. Metricas de ramp, draw, removal etc. ficam incorretas para estes decks. Mulligan simulation produz T3 errado porque cartas de ramp com `tag='unknown'` nao sao contadas.

**Impacto:** `🟡 P2` — 5 decks no sistema tem metricas incorretas. O Lorehold deck (deck_id=6) ainda tem 3 cartas nao classificadas. O mulligan tester, mana-base-validator, e evolution oracle operam com dados errados. Nao quebra o sistema, mas produz recomendacoes incorretas.

**Acao recomendada:**
1. Adicionar `_reclassifyUnknownTags(List<Map<String, dynamic>> cards)` no import pipeline
2. Para cada carta com `functional_tag == 'unknown'` ou `functional_tag IS NULL`, executar `inferFunctionalCardTags()` com oracle_text da carta
3. Atualizar `functional_tag` no banco (SQLite `deck_cards` e PG `card_function_tags`)
4. Tambem corrigir `CMC` quando for NULL ou 0.0 — buscar da tabela `cards` do PG
5. Adicionar este passo como `PASSO 0` no mana-base-validator e no purpose-analyzer

**Validacao:**
```bash
cd server && dart analyze lib/ai/functional_card_tags.dart
# Rodar query de health check e confirmar 0 unknown tags
python3 -c "
import sqlite3
conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db')
count = conn.execute('SELECT COUNT(*) FROM deck_cards WHERE functional_tag=\"unknown\" OR functional_tag IS NULL').fetchone()[0]
print(f'Unknown tags: {count}')  # Deve ser 0 apos fix
"
```
