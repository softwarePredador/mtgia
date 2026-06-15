# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-15
> **Cron:** manaloom-knowledge-synthesis
> **Método:** Cross-referência do conhecimento MTG (skills + logs + SQLite) contra código Dart vivo
> **Skills carregados:** manaloom-mtg-strategy (v1.1.0) — manaloom-mtg-domain não encontrado
> **Base de conhecimento:** SCOUT_LOG, VALIDATOR_LOG, MANA_BASE_VALIDATION_REPORT, GAME_CHANGERS.md, THEMES.md, LOGIC_COHERENCE_REPORT, STRUCTURE_AUDIT.md, SQLite knowledge.db (15 tabelas)
> **Branch:** codex/hermes-analysis-docs
> **Novas tasks nesta execução:** 5 (2×P1, 3×P2)

---

## [P0] Underworld Breach ausente de `_knownInfiniteComboPieces`

**Conhecimento MTG:** Underworld Breach é um Game Changer (53 GCs do produto) e peça de combo infinito critical no cEDH (LED + Breach + Brain Freeze = win). É uma das cartas mais impactantes do formato competitivo.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:405` — Underworld Breach em `officialGameChangerNamesForBracketPolicy` → recebe `gameChanger`.
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` só tem `thassa's oracle`, `demonic consultation`, `tainted pact`. **Underworld Breach AUSENTE**.
- `server/lib/edh_bracket_policy.dart:162-164` — `tagCardForBracket()` usa `_knownInfiniteComboPieces.contains(n)` para `infiniteCombo`. Breach nunca recebe esta tag.

**Gap:** Underworld Breach é detectado como GC mas não como peça de combo infinito. Orçamento `infiniteCombo` não o contabiliza.

**Impacto:** Bracket 3 (infiniteCombo=2): deck com Breach + Oracle + Consultation conta como 1 combo piece (Oracle) em vez de 2. GAMECHANGER_RESEARCH_REPORT.md Lacuna 3 confirma: `det=1` mascara cegueira do sistema.

**Risco:** P0 — Bracket sub-notifica densidade de combo.

**Ação recomendada:** Adicionar `'underworld breach'` a `_knownInfiniteComboPieces`. Considerar `'bolas\'s citadel'`.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## [P1] Goldfish simulator trata terrenos tapped como untapped

**Conhecimento MTG:** Muitas non-basic lands entram tapped (Temples, bounce lands, check lands). VALIDATOR_LOG v3.23: deck Lorehold com 2/33 basics. Tapped = mana atrasada 1 turno. Domínio §13 Gap 9 confirma: T3 reportado é melhor que o real.

**Evidência no código:**
- `server/lib/ai/goldfish_simulator.dart:258-261` — `_isLand()` só checa typeLine.
- `server/lib/ai/goldfish_simulator.dart:352-367` — `_playLandIfPossible()` sempre incrementa `landsPlayed`, sem verificar `enters tapped` no oracle text.
- `server/lib/ai/goldfish_simulator.dart:328-349` — `_canPlayOnTurn()` assume todas as terras untapped.
- `server/lib/ai/optimization_validator.dart:98-114` — Monte Carlo usa GoldfishSimulator, propagando o erro.

**Gap:** Nenhum terreno é "tapped on entry". `turn1PlayRate`, `noPlayTurn3Rate` incorretos.

**Impacto:** Otimizador aceita swaps que pioram tempo de mana. Relatórios superestimam consistência.

**Risco:** P1 — Superestimação sistemática da performance early-game.

**Ação recomendada:** Adicionar verificação de oracle text em `_playLandIfPossible()`: se oracle contém `enters the battlefield tapped` ou `enters tapped`, não incrementar `landsPlayed` neste turno.

**Validação:**
```bash
cd server && dart test test/goldfish_simulator_test.dart && dart analyze lib/ai/goldfish_simulator.dart
```

---

## [P1] `classifyOptimizationFunctionalRole()` ignora functional_tags persistidas

**Conhecimento MTG:** Prioridade documentada: persisted tags → semantic_v2 → heuristic. Pipeline precisa de classificação consistente.

**Evidência no código:**
- `server/lib/ai/functional_card_tags.dart:455-465` — `summarizeFunctionalTagsForDeck()` prioriza `persistedTags` corretamente.
- `server/lib/ai/optimization_functional_roles.dart:55-85` — `classifyOptimizationFunctionalRole()` usa `_classifySemanticV2FunctionalRole()` como fonte principal, **ignorando `functional_tags` persistidas**.
- `server/lib/ai/optimization_functional_roles.dart:37-91` — `CardRoles.resolveCardFunctionalRoles()` existe como adapter unificado mas `classifyOptimizationFunctionalRole()` não o usa.

**Gap:** Adapter `CardRoles` existe mas não é usado pelo classificador principal do optimize.

**Impacto:** Mesma carta pode ter `draw` em deck analysis e `utility` no quality gate. LOGIC_COHERENCE_REPORT flagrou como P1.

**Risco:** P1 — Drift de classificação entre estágios do pipeline.

**Ação recomendada:** Modificar `classifyOptimizationFunctionalRole()` para usar `CardRoles.resolveCardFunctionalRoles()` internamente, passando `functionalTags` primeiro.

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart
```

---

## [P1] `CandidateQualityData` sem taxa de inclusão EDHREC

**Conhecimento MTG:** % de inclusão EDHREC é sinal critical. Sol Ring 90.5%, Arcane Signet 88.1%. Metodologia SKILL.md §2.2 exige avaliar inclusão antes de swap.

**Evidência no código:**
- `server/lib/ai/candidate_quality_data_support.dart` — Schemas para `card_function_tags`, `card_role_scores`, `commander_card_synergy`. Sem `edhrecInclusionPct`.
- `server/lib/ai/commander_fallback_policy.dart` — Só usa `meta_deck_count` (EDHTop16 torneios).
- `server/lib/ai/optimize_filler_loader_support.dart` — Sem ponderação EDHREC.
- Busca por `edhrec_inclusion` em server/lib: **0 resultados**.
- Domínio §13 Gap 1: "CandidateQualityData não tem edhrec_inclusion_pct."

**Gap:** Sistema cego para o sinal mais usado pela comunidade Commander.

**Impacto:** Não distingue staple 40%+ de nicho 0%. Swap pode cortar staple em favor de lixo.

**Risco:** P1 — Decisões de otimização sem referência de popularidade/prova social.

**Ação recomendada:**
1. Adicionar `edhrecInclusionPct` a `CandidateQualityData`.
2. Popular de `card_meta_insights` (PG) ou `edhrec_rank` no cache.
3. Ponderar score: `role_match * 0.6 + edhrec_pct * 0.4`.

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart
```

---

## [P2] `_knownValueEngineNames` muito restrito (5 nomes)

**Conhecimento MTG:** Value engines geram vantagem recorrente. GCs como Consecrated Sphinx, Field of the Dead, Smothering Tithe e The One Ring são value engines clássicas.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:541-547` — Só 5 nomes: seedborn muse, tergrid, bolas's citadel, sensei's divining top, aetherflux reservoir.
- Consecrated Sphinx (line 363), Field of the Dead (line 370), Smothering Tithe (line 398), The One Ring (line 403): no GC list, NOT in value engines.
- `_looksLikeGameChangerCardAdvantage()` detecta alguns como `cardAdvantage` — categoria separada.
- GAMECHANGER_RESEARCH_REPORT.md Lacuna 2: Field of the Dead com falso positivo `fastMana` quando deveria ser `valueEngine`.

**Gap:** 4 GCs value engine não recebem categoria `valueEngine`. Orçamento `valueEngine` sub-notificado.

**Impacto:** Bracket 3 (valueEngine=6): Sphinx + Field + Ring sem consumir budget value engine. Só `gameChanger` (limite 3).

**Risco:** P2 — Imprecisão semântica. Mitigado por detecção `gameChanger`, mas categoria funcional perdida.

**Ação recomendada:**
```dart
const _knownValueEngineNames = <String>{
  'seedborn muse', 'tergrid, god of fright', 'bolas\'s citadel',
  'sensei\'s divining top', 'aetherflux reservoir',
  'consecrated sphinx', 'field of the dead', 'smothering tithe', 'the one ring',
};
```

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## Summary

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 1 | **P0** | Underworld Breach ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351,405` | 🔴 Quebra |
| 2 | **P1** | Goldfish trata tapped lands como untapped | `goldfish_simulator.dart:258-261,352-367` | 🟡 Incoerência |
| 3 | **P1** | classifyOptimizationFunctionalRole ignora persisted tags | `optimization_functional_roles.dart:55-85` | 🟡 Incoerência |
| 4 | **P1** | CandidateQualityData sem EDHREC inclusion | `candidate_quality_data_support.dart` | 🟡 Incoerência |
| 5 | **P2** | _knownValueEngineNames muito restrito (5→9) | `edh_bracket_policy.dart:541-547` | 🟢 Melhoria |

## Validação dos Dados

- **SQLite knowledge.db:** 15 tabelas (sem game_changers, sem tag_accuracy — conf. schema documentado)
- **card_oracle_cache GCs:** 28/31 amostrados (90.3%)
- **card_oracle_cache oracle_text vazio:** 4 cartas (Birds of Paradise DFC, Dwarven Trader, Memnite, Phyrexian Walker)
- **Deck 6 (Lorehold) tags:** ramp=41, draw=16, removal=7, protection=6, board_wipe=2, wincon=2 — perfil cEDH

---

## New Tasks (2026-06-15 — Cron #12, Execution #2)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 6 | **P1** | Grand Arbiter Augustin IV e Narset fora de `_looksLikeGameChangerStax` | `edh_bracket_policy.dart:493-518` | 🟡 Incoerência |
| 7 | **P1** | `_looksLikeRitual` não captura "Add {mana}" simples (Seething Song, Pyretic Ritual) | `functional_card_tags.dart:870-877` | 🟡 Incoerência |
| 8 | **P2** | Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility sem sub-categoria bracket | `edh_bracket_policy.dart:354-408,493-547` | 🟢 Melhoria |
| 9 | **P2** | Cobertura de teste bracket policy para Narset stax, GAA IV stax, Underworld Breach infiniteCombo | `edh_bracket_policy_test.dart` | 🟢 Melhoria |

### [P1] Grand Arbiter Augustin IV e Narset, Parter of Veils ausentes de `_looksLikeGameChangerStax`

**Conhecimento MTG:**
- **Narset, Parter of Veils** — "Each opponent can't draw more than one card each turn." Wheel hate/stax de card advantage. GC oficial.
- **Grand Arbiter Augustin IV** — "Spells your opponents cast cost {1} more to cast." Tax stax clássico. GC oficial.
Ambos restringem oponentes passivamente como Drannith Magistrate e Winter Orb, mas não são detectados pelo bracket policy como stax.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:493-518` — `_looksLikeGameChangerStax()` tem lista curada de ~10 nomes (`drannith magistrate`, `opposition agent`, `grand abolisher`, `winter orb`, `static orb`, `torpor orb`, `rule of law`, `deafening silence`, `eidolon of rhetoric`, `ethersworn canonist`, `archon of emeria`). **NÃO inclui** `grand arbiter augustin iv` nem `narset, parter of veils`.
- As heurísticas de oracle text detectam "can't cast more than one spell" e "creatures entering...don't cause abilities" — mas NÃO detectam "can't draw more than one card" (Narset) nem "cost more to cast" (GAA IV).

**Gap:** Ambos recebem apenas `gameChanger` genérico. Bracket 2 (max 1 stax) permite Narset + 1 stax real sem exceder budget.

**Impacto:** Budget de stax sub-notificado para dois GCs muito jogados (Narset: 207k+ decks EDHREC).

**Risco:** P1 — Stax density pode ser maior que o reportado.

**Ação recomendada:**
1. Adicionar `'narset, parter of veils'` e `'grand arbiter augustin iv'` à lista curada em `_looksLikeGameChangerStax()` (linhas 495-505)
2. Adicionar heurística de oracle text: `"can't draw more than one card"` para draw-hate stax
3. Adicionar heurística de oracle text: `"spells your opponents cast cost"` para tax stax (cobre GAA IV, God-Pharaoh's Statue, etc.)

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

### [P1] `_looksLikeRitual` não captura "Add {mana}" simples — Seething Song, Pyretic Ritual

**Conhecimento MTG:** Rituais clássicos como Seething Song (`"Add {R}{R}{R}{R}{R}."`) e Pyretic Ritual (`"Add {R}{R}{R}."`) têm oracle text minimalista sem "until end of turn". A heurística atual só detecta rituais com qualificador temporal ou escalável.

**Evidência no código:**
- `server/lib/ai/functional_card_tags.dart:870-877` — `_looksLikeRitual()`:
  ```dart
  return normalizedName == 'jeska\'s will' ||
      oracle.contains('add {') &&
          (oracle.contains('until end of turn') ||
              oracle.contains('for each') ||
              oracle.contains('for every') ||
              oracle.contains('your mana pool'));
  ```
- `server/lib/ai/functional_card_tags.dart:226-233` — `looksLikeOptimizationRampText()` detecta `'add {'` sem filtro → Seething Song ganha `ramp` mas **nunca** `ritual`.
- Oracle texts verificados no SQLite: Seething Song `"Add {R}{R}{R}{R}{R}."`, Pyretic Ritual `"Add {R}{R}{R}."` — nenhum contém os qualificadores exigidos.

**Gap:** A tag `ritual` (temporary mana burst) não é atribuída a rituais simples. O quality gate não distingue ramp permanente (rocks, dorks) de ramp temporária (rituals). Em decks combo com múltiplos rituais, o sistema trata tudo como ramp permante.

**Impacto:** Quality gate pode bloquear substituições legítimas de ritual → rock (sidegrade de one-shot para sustentável) ou aprovar corte de rocks em decks que dependem de ramp permanente.

**Risco:** P1 — Classificação de ramp incompleta afeta decisões de swap.

**Ação recomendada:**
1. Ampliar `_looksLikeRitual()` para detectar instant/sorcery com "add {" sem indicadores de permanência:
   ```dart
   bool _looksLikeRitual(String oracle, String normalizedName) {
     return normalizedName == 'jeska\'s will' ||
         (oracle.contains('add {') &&
             (oracle.contains('until end of turn') ||
              oracle.contains('for each') ||
              oracle.contains('for every') ||
              oracle.contains('your mana pool') ||
              // Se não tem indicadores de permanência, é ritual
              (!oracle.contains('at the beginning') &&
               !oracle.contains('each upkeep') &&
               !oracle.contains('each combat'))));
   ```
2. Alternativa: `typeLine.contains('instant') && oracle.contains('add {')` como condição curta.
3. Adicionar testes para Seething Song, Pyretic Ritual, Desperate Ritual.

**Validação:**
```bash
cd server && dart test test/ai/functional_card_tags_test.dart && dart analyze lib/ai/functional_card_tags.dart
```

---

### [P2] Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility sem sub-categoria de bracket

**Conhecimento MTG:** Estes 4 GCs oficiais da lista de 53 caem em `gameChanger` genérico sem sub-categoria:
- **Notion Thief:** Draw hate — stax
- **Orcish Bowmasters:** Draw punishment + removal — stax/removal
- **Glacial Chasm:** Previne todo dano a você — protection/value engine
- **Humility:** Todas as criaturas viram 1/1 sem habilidades — stax

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:354-408` — Todos os 4 estão em `officialGameChangerNamesForBracketPolicy` (Notion Thief: line 391, Bowmasters: 393, Glacial: 376, Humility: 379).
- `server/lib/edh_bracket_policy.dart:493-518` — `_looksLikeGameChangerStax()` não detecta Notion Thief, Bowmasters, Humility.
- `server/lib/edh_bracket_policy.dart:520-539` — `_looksLikeGameChangerProtection()` não detecta Glacial Chasm (prevenção passiva de dano).
- `server/lib/edh_bracket_policy.dart:541-547` — `_knownValueEngineNames` não inclui Glacial Chasm.

**Gap:** Budget allocation de stax/protection/value engine fica subestimada para estes 4 GCs.

**Impacto:** Bracket policy perde informação semântica sobre a composição funcional do deck.

**Risco:** P2 — Melhoria incremental. Mitigado pela detecção `gameChanger` genérica que limita a 3 em bracket 3.

**Ação recomendada:**
1. Notion Thief: adicionar padrão `"if an opponent would draw a card except"` → stax
2. Orcish Bowmasters: adicionar `'orcish bowmasters'` à lista curada de stax + `"whenever an opponent draws"` + dano → removal
3. Glacial Chasm: adicionar `'glacial chasm'` à `_knownValueEngineNames` + detecção de "prevent all damage" → protection
4. Humility: adicionar `'humility'` a stax + `"all creatures lose all abilities"` → stax
5. Adicionar teste unitário para cada GC com oracle text real

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

### [P2] Cobertura de teste bracket policy para GCs conhecidos

**Conhecimento MTG:** O arquivo de teste `edh_bracket_policy_test.dart` tem 87 linhas e 4 testes. Underworld Breach é testado (só `gameChanger`, sem `infiniteCombo`). Narset, GAA IV, Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility **não têm testes**.

**Evidência no código:**
- `server/test/edh_bracket_policy_test.dart:35-44` — Teste de Underworld Breach verifica APENAS `contains(BracketCategory.gameChanger)`. Sem assertion de `infiniteCombo`.
- `server/test/edh_bracket_policy_test.dart` — Nenhum teste para Narset, GAA IV, Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility.
- Cobertura atual: 4 testes / ~54 GCs = 7.4% de cobertura de GCs individuais.

**Gap:** Sem testes de regressão para as sub-categorias dos GCs mais impactantes.

**Impacto:** Alterações nas heurísticas ou listas curadas podem introduzir regressão não detectada.

**Risco:** P2 — Complementar às tasks acima.

**Ação recomendada:**
1. No teste existente "keeps official gamechanger names" (linha 27), adicionar `expect(breach.categories, contains(BracketCategory.infiniteCombo))` (APÓS adicionar Breach a `_knownInfiniteComboPieces`, task P0 acima).
2. Adicionar `test('detects Narset, Parter of Veils as stax')` com oracle real que verifica `contains(BracketCategory.stax)` e `contains(BracketCategory.gameChanger)`.
3. Adicionar `test('detects Grand Arbiter Augustin IV as stax')`.
4. Adicionar `test('detects Notion Thief as stax')`.
5. Adicionar `test('detects Orcish Bowmasters as stax and removal')`.
6. Adicionar `test('detects Glacial Chasm as valueEngine and protection')`.
7. Adicionar `test('detects Humility as stax')`.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze test/edh_bracket_policy_test.dart
```

---

## New Tasks (2026-06-15 — Cron #12, Execution #3)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 10 | **P1** | Import pipeline SQLite usa heurísticas Python básicas em vez do classificador Dart | `sync_pg_target_deck_to_hermes.py:60-93` | 🟡 Incoerência |
| 11 | **P1** | `_criticalRolesForArchetype` limitado a 3 arquétipos | `optimization_quality_gate.dart:493-500` | 🟡 Incoerência |
| 12 | **P2** | `_looksLikeGameChangerBoardWipe` diverge de `looksLikeOptimizationBoardWipeText` | `edh_bracket_policy.dart:454-467` vs `optimization_functional_roles.dart:345-360` | 🟢 Melhoria |
| 13 | **P2** | Detecção automática de tema a partir de decklist não implementada | `THEMES.md` (documentado, sem código) | 🟢 Melhoria |
| 14 | **P2** | Bolas's Citadel ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |

### [P1] Import pipeline SQLite usa heurísticas Python básicas em vez do classificador Dart

**Conhecimento MTG:** A classificação funcional de cartas é crítica para todas as análises downstream (quality gate, validator, mulligan, battle analyst). VALIDATOR_LOG v3.23 detectou 20 cartas com `functional_tag='unknown'` e 6 cartas com `CMC=NULL` na importação — dados corrompidos que invalidam toda a análise do pipeline.

**Evidência no código:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:60-93` — `infer_tag()` usa heurísticas Python minimalistas:
  ```python
  def infer_tag(row):
      # ... tenta battle_role ...
      # ... tenta battle_effect ...
      if "land" in type_line: return "land"
      if "destroy target" in oracle or "exile target" in oracle: return "removal"
      if "draw" in oracle: return "draw"
      if "add " in oracle and "mana" in oracle: return "ramp"
      if "creature" in type_line: return "creature"
      return "unknown"  # ← 20+ cartas caem aqui
  ```
- `server/lib/ai/functional_card_tags.dart` — O classificador Dart tem 1092 linhas de heurísticas sofisticadas (oracle text parsing, type_line analysis, name matching, speed inference, card advantage type, etc.). NUNCA é chamado durante a importação.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:118-125` — `deck_cards` schema: `cmc REAL` sem default. PG pode retornar `cmc=NULL` para cartas onde `cmc` não está populado ou é nulo.
- VALIDATOR_LOG v3.23 evidencia: Sol Ring (CMC 1 → 0.0), Mana Vault (CMC 1 → 0.0), Aetherflux (CMC 4 → NULL), Past in Flames (CMC 4 → NULL).

**Gap:** O script de importação Python não chama o classificador Dart (API ou CLI). Tags funcionais e CMCs são importados crus do PostgreSQL sem validação ou enriquecimento. O classificador Dart só roda no servidor, durante análise de deck — mas os dados no SQLite ficam permanentemente corrompidos até a próxima sincronização que substitui as tags.

**Impacto:** QUALQUER análise que leia do SQLite (battle_analyst_v8.py, VALIDATOR_LOG, optimization quality gate via PG sync) trabalha com dados corrompidos. CMC=0.0 artificialmente reduz o CMC médio do deck. Tags 'unknown' fazem o quality gate ignorar funções críticas.

**Risco:** P1 — Corrupção sistemática de dados na fonte de verdade local.

**Ação recomendada:**
1. **Curto prazo:** Adicionar pós-processamento em `sync_pg_target_deck_to_hermes.py` que corrige CMCs contra `card_oracle_cache` e aplica heurísticas Python melhoradas (cobrindo Sol Ring, mana rocks, etc.) como fallback imediato.
2. **Médio prazo:** Criar um endpoint Dart (`POST /api/classify-cards`) ou script CLI que aceite lista de cartas e retorne functional_tags + cmc corrigido. Invocar do Python via subprocess.
3. **Alternativa:** Migrar o sync script para Dart, executando o classificador nativamente.
4. Adicionar validação: se >5% das cartas têm 'unknown', abortar importação e reportar erro.

**Validação:**
```bash
# Validar que Sol Ring, Mana Vault, Aetherflux Reservoir têm functional_tag='ramp' e CMC correto
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -c "
import sqlite3
conn = sqlite3.connect('knowledge.db')
cur = conn.execute('SELECT card_name, functional_tag, cmc FROM deck_cards WHERE deck_id=6')
for row in cur:
    name, tag, cmc = row
    if tag == 'unknown' or cmc is None or cmc == 0.0:
        print(f'ISSUE: {name} -> tag={tag}, cmc={cmc}')
    if name in ('Sol Ring', 'Mana Vault', 'Aetherflux Reservoir'):
        print(f'{name}: tag={tag}, cmc={cmc}')
conn.close()
"
```

---

### [P1] `_criticalRolesForArchetype` limitado a 3 arquétipos

**Conhecimento MTG:** Cada arquétipo de Commander tem necessidades diferentes. Um deck de **Combo** precisa proteger `combo_piece` e `tutor`. Um deck de **Spellslinger** precisa de `draw` e `engine`. Um deck de **Go-wide Tokens** precisa de `creature` e `token_maker`. Um deck de **Aristocrats** precisa de `sacrifice` e `drain`. Usar o mesmo conjunto crítico para todos os decks genéricos subestima sistematicamente riscos de swap.

**Evidência no código:**
- `server/lib/ai/optimization_quality_gate.dart:493-500` — `_criticalRolesForArchetype()`:
  ```dart
  Set<String> _criticalRolesForArchetype(String archetype) {
    return switch (archetype.trim().toLowerCase()) {
      'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
      'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
      'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
      _ => {'removal', 'ramp', 'wipe', 'wincon'}, // ← fallback genérico
    };
  }
  ```
- `server/test/edh_bracket_policy_test.dart` — Sem testes para archetype-specific critical roles.
- `server/decks` do SQLite: deck 6 (Lorehold) tem `archetype='unknown'` — cai no fallback genérico.
- THEMES.md lista 42 temas específicos de Commander — nenhum refletido aqui.
- `docs/CONTEXTO_PRODUTO_ATUAL.md` — Commander Reference Profiles para 48+ comandantes com `role_targets` que incluem draw, ramp, removal, protection, wincon — métricas que o quality gate devia usar.

**Gap:** O quality gate não protege roles essenciais para arquétipos como combo (`combo_piece`, `tutor`), spellslinger (`draw`, `engine`), aristocrats (`sacrifice`, `drain`), enchantress (`engine`, `draw`), goblins (`creature`, `token_maker`), dragons (`ramp`, `creature`, `engine`).

**Impacto:** Swaps que removem `combo_piece` de um deck combo passam pelo quality gate porque `combo_piece` não está em `criticalRoles` para o fallback. Similarmente, trocar `draw` essencial em spellslinger por removal genérico não é bloqueado.

**Risco:** P1 — O quality gate falha em proteger swaps destrutivos para arquétipos não-tradicionais.

**Ação recomendada:**
1. Expandir `_criticalRolesForArchetype()` para cobrir pelo menos 10 arquétipos de Commander:
   ```dart
   Set<String> _criticalRolesForArchetype(String archetype) {
     return switch (archetype.trim().toLowerCase()) {
       'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
       'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
       'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
       'combo' => {'combo_piece', 'tutor', 'ramp', 'draw', 'wincon', 'removal'},
       'spellslinger' => {'draw', 'engine', 'ramp', 'removal', 'wincon'},
       'aristocrats' => {'sacrifice', 'drain', 'creature', 'removal', 'draw'},
       'enchantress' => {'engine', 'draw', 'ramp', 'protection'},
       'tokens' => {'token_maker', 'creature', 'ramp', 'draw'},
       'reanimator' => {'recursion', 'engine', 'draw', 'ramp', 'removal'},
       'voltron' => {'protection', 'enabler', 'wincon', 'ramp', 'removal'},
       _ => {'removal', 'ramp', 'wipe', 'wincon', 'draw'},
     };
   }
   ```
2. Adicionar fallback de Commander Reference Profile: se existir perfil para o commander, usar `role_targets` do perfil em vez do archetype genérico.
3. Adicionar logging: quando archetype='unknown' ou não reconhecido, logar o commander para debug.

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart test/optimization_quality_gate_test.dart && dart analyze lib/ai/optimization_quality_gate.dart
```

---

### [P2] `_looksLikeGameChangerBoardWipe` diverge de `looksLikeOptimizationBoardWipeText`

**Conhecimento MTG:** Board wipes são definidos consistentemente: qualquer spell que destrói/remova/exila/bouncia múltiplas permanentes de oponentes ou de todos os jogadores. O sistema tem DUAS implementações para detectar board wipes, com cobertura diferente.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:454-467` — `_looksLikeGameChangerBoardWipe()` (10 linhas):
  ```dart
  if (normalizedName == 'cyclonic rift' || normalizedName == 'farewell') return true;
  if (oracleLower.contains('exile all') && oracleLower.contains('opponents control')) return true;
  if (oracleLower.contains('destroy all') && oracleLower.contains('opponents control')) return true;
  if (oracleLower.contains('return all') && oracleLower.contains('opponents control') && oracleLower.contains('hand')) return true;
  return false;
  ```
  **Problema:** Só detecta wipes assimétricos (apenas "opponents control"). Perde wipes simétricos como "destroy all creatures" (Wrath of God), "each player sacrifices" (Pox, Cataclysm), "damage to each creature" (Blasphemous Act).

- `server/lib/ai/optimization_functional_roles.dart:345-360` — `looksLikeOptimizationBoardWipeText()` (16 linhas):
  ```dart
  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('all creatures get -') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('each player sacrifices all') ||
      oracle.contains('each opponent sacrifices all') ||
      oracle.contains('damage to each creature') ||
      (oracle.contains('deals') && oracle.contains('damage') && oracle.contains('to each creature'));
  ```
  **Mais abrangente:** detecta wipes simétricos e assimétricos.

- **DRY Violation:** Mesma lógica (detecção de board wipe via oracle text) implementada duas vezes com cobertura diferente. Nenhuma função chama a outra.

**Gap:** Bracket policy subnotifica board wipes simétricos (Wrath of God, Blasphemous Act não são detectados como `boardWipe` pelo bracket, embora Blasphemous Act seja detectado por `looksLikeOptimizationBoardWipeText`).

**Impacto:** Deck com Wrath of God + Blasphemous Act + Cyclonic Rift + Farewell tem 4 wipes, mas bracket policy conta só 2 (Cyclonic + Farewell). Budget `boardWipe` (bracket 2 max=2) não reflete a densidade real.

**Risco:** P2 — Subnotificação de board wipes impacta análise de bracket.

**Ação recomendada:**
1. Extrair `_looksLikeGameChangerBoardWipe()` para usar a lógica mais abrangente de `looksLikeOptimizationBoardWipeText()`.
2. Unificar as duas funções em um módulo compartilhado (`board_wipe_utils.dart`?).
3. Alternativa: modificar `_looksLikeGameChangerBoardWipe()` para:
   ```dart
   bool _looksLikeGameChangerBoardWipe(String normalizedName, String oracleLower) {
     return looksLikeOptimizationBoardWipeText(oracleLower);
   }
   ```
4. Adicionar testes para Wrath of God, Austere Command, Blasphemous Act no bracket policy test.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart lib/ai/optimization_functional_roles.dart
```

---

### [P2] Detecção automática de tema a partir de decklist não implementada

**Conhecimento MTG:** THEMES.md documenta 42 temas de Commander com regras de detecção completas (Passo 1-3: contar tribos, contar mecânicas, score de confiança). A metodologia está documentada mas NENHUM código implementa a detecção automática. O otimizador usa `detectedTheme` que vem do campo `theme` do deck, não de análise real da decklist.

**Evidência no código:**
- `docs/hermes-analysis/manaloom-knowledge/THEMES.md:128-151` — Metodologia completa de detecção de temas:
  - Passo 1: Contar tribos (20+ cartas mesmo tipo de criatura → TRIBAL)
  - Passo 2: Contar mecânicas (20+ instants/sorceries → SPELLSLINGER, etc.)
  - Passo 3: Score de confiança (3+ sinais = CONFIRMADO)
  - Tabelas com thresholds por tema (Goblins: 25+ goblins, Dragons: 18-24 dragons)
- `server/lib/ai/optimize_runtime_support.dart` — Usa `card['theme']` ou `commanderName` para inferir tema, NÃO analisa a decklist.
- Busca por `detectedTheme` em server/lib: **0 resultados** (campo lido de PG, não computado).
- `server/lib/ai/theme_contextual_rules_service.dart` — Existe como serviço mas depende de `theme` fornecido externamente.
- `docs/hermes-analysis/manaloom-knowledge/THEMES.md:180-185` — "O que precisa ser adicionado" lista 6 itens, NENHUM implementado.

**Gap:** Não há código que, dada uma decklist + commander, produza `detectedTheme` com score de confiança. A otimização não pode ser theme-aware porque não sabe em qual tema o deck está.

**Impacto:** O otimizador trata todos os decks como genéricos. Não pode aplicar regras como "em Goblins, 25+ criaturas goblin é critical" ou "em Enchantress, 15+ encantamentos é critical". Swaps que quebram o tema (ex: remover goblins de um deck tribal goblin) não são detectados.

**Risco:** P2 — Otimização cega para identidade temática do deck.

**Ação recomendada:**
1. Criar `server/lib/ai/theme_detector.dart` com:
   - `detectTheme(List<Map<String, dynamic>> deckCards, String commanderName) → DetectedTheme`
   - Contagem de tribos por `type_line`
   - Contagem de mecânicas por heurísticas de oracle text
   - Score de confiança (0.0-1.0) baseado em quantos sinais bateram
2. Implementar regras de detecção para os 10 temas mais comuns inicialmente (Spellslinger, Goblins, Dragons, Elves, Aristocrats, Enchantress, Artifacts, Tokens, Graveyard, Landfall)
3. Integrar no pipeline: `_bootstrapSparseCompleteInput` deve chamar `detectTheme()` com as cartas disponíveis e armazenar resultado.
4. Adicionar ao `OptimizationSwapGateResult` o campo `theme` para auditoria.
5. Escrever testes com decklists reais (SQLite learned_decks) para verificar detecção.

**Validação:**
```bash
cd server && dart test test/theme_detector_test.dart && dart analyze lib/ai/theme_detector.dart
```
(Testes precisam ser criados — usar decklists do SQLite `learned_decks` como fixtures.)

---

### [P2] Bolas's Citadel ausente de `_knownInfiniteComboPieces`

**Conhecimento MTG:** Bolas's Citadel + Aetherflux Reservoir + Sensei's Divining Top forma um combo deterministico: Top no topo do library → paga 1 vida com Citadel → conjura Top de graça → compra com Top → repete → ganha vida infinita com Reservoir → vitoria. Bolas's Citadel é Game Changer oficial (linha 359 da GC list) e está em `_knownValueEngineNames` mas NÃO em `_knownInfiniteComboPieces`.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:359` — `'bolas\'s citadel'` em `officialGameChangerNamesForBracketPolicy` → GC detectado.
- `server/lib/edh_bracket_policy.dart:541-547` — `_knownValueEngineNames` → Citadel detectado como value engine.
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` → Citadel AUSENTE (só Oracle, Consultation, Tainted Pact).
- `server/lib/edh_bracket_policy.dart:162-164` — `tagCardForBracket()` usa `_knownInfiniteComboPieces.contains(n)`. Citadel nunca recebe `infiniteCombo`.

**Gap:** Citadel é GC + valueEngine mas falta a tag `infiniteCombo`. Um deck com Citadel + Reservoir + Top conta como 0 combo pieces para o bracket.

**Impacto:** Se um deck já tem Thassa's Oracle + Demonic Consultation + Citadel + Top + Reservoir, o bracket conta 1 combo piece (Oracle) em vez de 2 (Oracle + Citadel como enabler de combo). Pode exceder o limite bracket 3 (max 2 infiniteCombo) sem ser detectado.

**Risco:** P2 — Mitigado por detecção `gameChanger` (limite 3 em B3) e `valueEngine`. Mas a categoria funcional `infiniteCombo` é perdida.

**Ação recomendada:**
```dart
const _knownInfiniteComboPieces = <String>{
  'thassa\'s oracle',
  'demonic consultation',
  'tainted pact',
  'underworld breach',
  'bolas\'s citadel',
};
```

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## Full Summary (All 14 Tasks)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 1 | **P0** | Underworld Breach ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351,405` | 🔴 Quebra |
| 2 | **P1** | Goldfish trata tapped lands como untapped | `goldfish_simulator.dart:258-261,352-367` | 🟡 Incoerência |
| 3 | **P1** | `classifyOptimizationFunctionalRole` ignora persisted tags | `optimization_functional_roles.dart:55-85` | 🟡 Incoerência |
| 4 | **P1** | `CandidateQualityData` sem EDHREC inclusion | `candidate_quality_data_support.dart` | 🟡 Incoerência |
| 5 | **P2** | `_knownValueEngineNames` muito restrito (5→9) | `edh_bracket_policy.dart:541-547` | 🟢 Melhoria |
| 6 | **P1** | GAA IV e Narset fora de `_looksLikeGameChangerStax` | `edh_bracket_policy.dart:493-518` | 🟡 Incoerência |
| 7 | **P1** | `_looksLikeRitual` não captura rituais simples | `functional_card_tags.dart:870-877` | 🟡 Incoerência |
| 8 | **P2** | Notion Thief, Bowmasters, Glacial Chasm, Humility sem sub-categoria | `edh_bracket_policy.dart:354-408,493-547` | 🟢 Melhoria |
| 9 | **P2** | Cobertura de teste bracket policy para GCs | `edh_bracket_policy_test.dart` | 🟢 Melhoria |
| 10 | **P1** | Import pipeline SQLite usa heurísticas Python (20+ unknown tags) | `sync_pg_target_deck_to_hermes.py:60-93` | 🟡 Incoerência |
| 11 | **P1** | `_criticalRolesForArchetype` limitado a 3 arquétipos | `optimization_quality_gate.dart:493-500` | 🟡 Incoerência |
| 12 | **P2** | Board wipe detection divergente (bracket vs optimization) | `edh_bracket_policy.dart:454-467` vs `optimization_functional_roles.dart:345-360` | 🟢 Melhoria |
| 13 | **P2** | Detecção automática de tema não implementada | `theme_detector.dart` (não existe) | 🟢 Melhoria |
| 14 | **P2** | Bolas's Citadel ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
## New Tasks (2026-06-15 — Cron #12, Execution #4 — Current)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 15 | **P1** | Quality gate `_isTemporaryManaBurstCard` omite rituais sem qualificador temporal | `optimization_quality_gate.dart:349-364` | 🟡 Incoerência |
| 16 | **P2** | Drift: `_knownComboPieceNames` (optimization) vs `_knownInfiniteComboPieces` (bracket) | `optimization_functional_roles.dart:515-522` vs `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
| 17 | **P2** | `_knownProtectionNames` em optimization_functional_roles.dart com cobertura insuficiente | `optimization_functional_roles.dart:524-529` | 🟢 Melhoria |
| 18 | **P2** | SQLite: 35/100 cartas do deck 6 com CMC=0.0 — agravante da import pipeline | `sync_pg_target_deck_to_hermes.py:118-125` | 🟢 Melhoria |

---

### [P1] Quality gate `_isTemporaryManaBurstCard` omite rituais sem qualificador temporal

**Conhecimento MTG:** Rituais são mana burst temporária (one-shot), diferente de ramp permanente (rocks, dorks, land ramp). Rituais como Dark Ritual (`"Add {B}{B}{B}."`), Seething Song (`"Add {R}{R}{R}{R}{R}."`) e Pyretic Ritual (`"Add {R}{R}{R}."`) geram mana instantânea sem "until end of turn" no oracle text porque o mana já desaparece naturalmente nas fases. O quality gate precisa distinguir ramp temporária de permanente para bloquear swaps que trocam ramp sustentável por burst.

**Evidência no código:**
- `server/lib/ai/optimization_quality_gate.dart:349-364` — `_isTemporaryManaBurstCard()`:
  ```dart
  bool _isTemporaryManaBurstCard(Map<String, dynamic> card) {
    final name = ((card['name'] as String?) ?? '').toLowerCase();
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
    final generatesMana =
        oracle.contains('add {') || oracle.contains('add one mana');
    if (!generatesMana) return false;
    if (!(typeLine.contains('instant') || typeLine.contains('sorcery'))) return false;
    return name.contains('ritual') ||
        oracle.contains('until end of turn') ||
        oracle.contains('for each');
  }
  ```
  **Problema:** `oracle.contains('until end of turn')` exige qualificador temporal que rituais simples não têm. Seething Song (`seething song` não contém "ritual") → NOT detected. Pyretic Ritual → detected (contém "ritual" no nome). Dark Ritual → detected (`'dark ritual'.contains('ritual')` = true).

- SQLite `deck_cards` confirma: Seething Song no deck 6 tem `type_line=Sorcery`, `oracle_text=Add {R}{R}{R}{R}{R}.`, sem "ritual" no nome.

- Em decks não-combo, swaps que trocam ramp permanente (Sol Ring, Signet) por Seething Song não são bloqueados porque `_isTemporaryManaBurstCard()` retorna false para Seething Song.

- **Achado adicional:** 123 quality reviews no SQLite, 70+ deles avaliando Blasphemous Act como 'ramp' quando deveria ser 'wipe'. Quality reviews mostram `role_mismatch:Blasphemous Act role=ramp add_roles=wipe`. Isso indica que o classificador `classifyOptimizationFunctionalRole()` está retornando papel inesperado, provavelmente porque os functional_tags persistidos (`["board_wipe","enabler","payoff","big_spell"]`) não estão disponíveis no mapa da carta em tempo de execução.

**Gap:** `_isTemporaryManaBurstCard()` não detecta Seething Song como mana temporária. O ramp count do optimizer inclui rituais como ramp permanente, inflando a contagem.

**Impacto:** Em decks não-combo, swap de Sol Ring (ramp permanente) → Seething Song (ramp temporária) passa pelo quality gate sem bloqueio, degradando a sustentabilidade da mana base.

**Risco:** P1 — Degradação silenciosa de mana base em non-combo. Blasphemous Act mal classificado gera warnings espúrios (70+ reviews).

**Ação recomendada:**
1. Corrigir `_isTemporaryManaBurstCard()` para detectar qualquer instant/sorcery que gere mana como temporário:
   ```dart
   bool _isTemporaryManaBurstCard(Map<String, dynamic> card) {
     final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
     final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
     final generatesMana =
         oracle.contains('add {') || oracle.contains('add one mana');
     if (!generatesMana) return false;
     // Instants e sorceries que geram mana são sempre temporários
     if (typeLine.contains('instant') || typeLine.contains('sorcery')) return true;
     return false;
   }
   ```
2. Remover `name.contains('ritual')`, `oracle.contains('until end of turn')` e `oracle.contains('for each')` — redundantes após a correção.
3. Investigar Blasphemous Act classification: verificar se functional_tags chegam ao quality gate. Se não chegam, adicionar `card['functional_tags']` propagation no pipeline.

**Validação:**
```bash
cd server && dart test test/optimization_quality_gate_test.dart && dart analyze lib/ai/optimization_quality_gate.dart
```

---

### [P2] Drift: `_knownComboPieceNames` (optimization) vs `_knownInfiniteComboPieces` (bracket)

**Conhecimento MTG:** Combo pieces são cartas que, combinadas com outra(s), geram loop infinito ou wincondition determinística. O sistema tem DOIS registros separados de combo pieces que não sincronizam.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` (3 cartas): thassa's oracle, demonic consultation, tainted pact.
- `server/lib/ai/optimization_functional_roles.dart:515-522` — `_knownComboPieceNames` (6 cartas):
  ```dart
  const _knownComboPieceNames = <String>{
    'basalt monolith',
    'dramatic reversal',
    'underworld breach',
    'grand architect',
    'sensei\'s divining top',
    'power artifact',
  };
  ```
- **Interseção:** 0 cartas (nenhum nome está em ambas as listas).

**Gap:** Underworld Breach é combo piece no optimization mas não no bracket (embora seja GC). Basalt Monolith, Dramatic Reversal, Grand Architect, Sensei's Divining Top e Power Artifact são combo pieces conhecidos pelo optimization mas o bracket policy nunca os classifica como `infiniteCombo`.

**Impacto:** Bracket policy subnotifica densidade de combo. Ex: deck com Dramatic Reversal + Isochron Scepter (combo infinito de mana) não gera alerta no bracket.

**Risco:** P2 — Inconsistência entre módulos. Um módulo sabe que a carta é combo piece, o outro não.

**Ação recomendada:**
1. Adicionar `'basalt monolith'`, `'dramatic reversal'`, `'grand architect'`, `'sensei\'s divining top'`, `'power artifact'` a `_knownInfiniteComboPieces`.
2. Considerar criar `shared/combo_constants.dart` como fonte única de verdade para combo pieces.
3. Adicionar teste de consistência: verificar que ambas as listas contêm os mesmos elementos.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart lib/ai/optimization_functional_roles.dart
```

---

### [P2] `_knownProtectionNames` em optimization_functional_roles.dart com cobertura insuficiente

**Conhecimento MTG:** Proteção em Commander inclui spells que concedem indestrutível, hexproof, ou phase out. Flawless Maneuver, Heroic Intervention, Boros Charm e Teferi's Protection são staples de proteção.

**Evidência no código:**
- `server/lib/ai/optimization_functional_roles.dart:524-529` — `_knownProtectionNames` (4 nomes):
  ```dart
  const _knownProtectionNames = <String>{
    'fierce guardianship',
    'deflecting swat',
    'swiftfoot boots',
    'endurance',
  };
  ```
- `edh_bracket_policy.dart:520-528` — `_looksLikeGameChangerProtection()` tem 6 nomes curados incluindo Flawless Maneuver, Heroic Intervention, Teferi's Protection, Deadly Rollick.
- `_resolveHeuristicRoles()` detecta oracle text de proteção (hexproof, indestructible, etc.) independentemente da lista curada. A lista curada é usada para PRIORIZAÇÃO: `_selectPrimaryRole()` escolhe 'protection' como papel primário se a carta está na lista.

**Gap:** Flawless Maneuver (free protection, 19.8% EDHREC Lorehold), Heroic Intervention (staple verde em 35%+ decks), Boros Charm (staple Boros), Teferi's Protection (GC) não estão em `_knownProtectionNames`. O classificador heurístico pode detectá-los, mas a lista curada prioriza o papel primário.

**Impacto:** Quality gate pode tratar Teferi's Protection como 'utility' em vez de 'protection', permitindo swap que remove proteção essencial sem flag.

**Risco:** P2 — Priorização de papel funcional sub-ótima.

**Ação recomendada:**
```dart
const _knownProtectionNames = <String>{
  'fierce guardianship',
  'deflecting swat',
  'swiftfoot boots',
  'endurance',
  'flawless maneuver',
  'heroic intervention',
  'boros charm',
  'teferi\'s protection',
  'deadly rollick',
};
```

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart && dart analyze lib/ai/optimization_functional_roles.dart
```

---

### [P2] SQLite: 35/100 cartas do deck 6 com CMC=0.0 — validação pós-import ausente

**Conhecimento MTG:** Terrenos têm CMC 0 (regra do jogo). No entanto, o VALIDATOR_LOG v3.23 reportou 16 cartas não-land com CMC=0.0. Verificação nesta execução: apenas 35 lands têm CMC=0.0 — as 16 não-lands foram corrigidas. A correção parcial indica ajuste manual ou execução corretiva do import. Falta validação automatizada.

**Evidência no código:**
- SQLite verificado nesta execução: 35 cartas CMC=0.0 — todas com `type_line` contendo 'Land'. 0 cartas não-land com CMC=0.0.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:118-125` — Schema sem validação pós-write.
- `server/lib/ai/cmc_safety.dart` — `safeCmcForOptimization()` existe no Dart mas não na importação Python.

**Gap:** Não há validação pós-importação que verifique `cmc` para cartas não-land. Se o PG retornar CMC=NULL para cartas não-land no futuro, a regressão não seria detectada automaticamente.

**Impacto:** Menor — situação atual está corrigida (0 não-lands com CMC=0.0). Mas sem validação, a regressão pode acontecer novamente.

**Risco:** P2 — Prevenção de regressão.

**Ação recomendada:**
1. Adicionar query de validação pós-import no sync script: `SELECT card_name, cmc, type_line FROM deck_cards WHERE deck_id=? AND cmc = 0.0 AND type_line NOT LIKE '%Land%'`. Se retornar >0, abortar e logar erro.
2. Alternativa: adicionar CONSTRAINT CHECK (`cmc > 0 OR type_line LIKE '%Land%'`) se o SQLite suportar (precisa de alter table, complexo).

**Validação:**
```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -c "
import sqlite3
conn = sqlite3.connect('knowledge.db')
bad = conn.execute(\"\"\"
  SELECT card_name, cmc, type_line
  FROM deck_cards
  WHERE deck_id=6 AND cmc = 0.0 AND type_line NOT LIKE '%Land%'
\"\"\").fetchall()
print(f'Non-lands with CMC=0: {len(bad)}')
for r in bad:
    print(f'  {r[0]}: cmc={r[1]}, type={r[2]}')
conn.close()
"
```

---

## Full Summary (All 18 Tasks)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 1 | **P0** | Underworld Breach ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351,405` | 🔴 Quebra |
| 2 | **P1** | Goldfish trata tapped lands como untapped | `goldfish_simulator.dart:258-261,352-367` | 🟡 Incoerência |
| 3 | **P1** | `classifyOptimizationFunctionalRole` ignora persisted tags | `optimization_functional_roles.dart:55-85` | 🟡 Incoerência |
| 4 | **P1** | `CandidateQualityData` sem EDHREC inclusion | `candidate_quality_data_support.dart` | 🟡 Incoerência |
| 5 | **P2** | `_knownValueEngineNames` muito restrito (5→9) | `edh_bracket_policy.dart:541-547` | 🟢 Melhoria |
| 6 | **P1** | GAA IV e Narset fora de `_looksLikeGameChangerStax` | `edh_bracket_policy.dart:493-518` | 🟡 Incoerência |
| 7 | **P1** | `_looksLikeRitual` não captura rituais simples | `functional_card_tags.dart:870-877` | 🟡 Incoerência |
| 8 | **P2** | Notion Thief, Bowmasters, Glacial Chasm, Humility sem sub-categoria | `edh_bracket_policy.dart:354-408,493-547` | 🟢 Melhoria |
| 9 | **P2** | Cobertura de teste bracket policy para GCs | `edh_bracket_policy_test.dart` | 🟢 Melhoria |
| 10 | **P1** | Import pipeline SQLite usa heurísticas Python (20+ unknown tags) | `sync_pg_target_deck_to_hermes.py:60-93` | 🟡 Incoerência |
| 11 | **P1** | `_criticalRolesForArchetype` limitado a 3 arquétipos | `optimization_quality_gate.dart:493-500` | 🟡 Incoerência |
| 12 | **P2** | Board wipe detection divergente (bracket vs optimization) | `edh_bracket_policy.dart:454-467` vs `optimization_functional_roles.dart:345-360` | 🟢 Melhoria |
| 13 | **P2** | Detecção automática de tema não implementada | `theme_detector.dart` (não existe) | 🟢 Melhoria |
| 14 | **P2** | Bolas's Citadel ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
| 15 | **P1** | Quality gate `_isTemporaryManaBurstCard` omite rituais sem qualificador | `optimization_quality_gate.dart:349-364` | 🟡 Incoerência |
| 16 | **P2** | Drift: `_knownComboPieceNames` vs `_knownInfiniteComboPieces` | `optimization_functional_roles.dart:515-522` vs `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
| 17 | **P2** | `_knownProtectionNames` com cobertura insuficiente (4 nomes) | `optimization_functional_roles.dart:524-529` | 🟢 Melhoria |
| 18 | **P2** | SQLite: validação pós-import para CMC de não-lands ausente | `sync_pg_target_deck_to_hermes.py:118-125` | 🟢 Melhoria |

## Strategic Notes

- **Tarefa #11** (criticalRolesForArchetype) — a ação recomendada expande para 10 arquétipos mas o código atual do aggro ainda omite `'draw'`. A expansão proposta já cobre essa omissão ao adicionar novos arquétipos com draw.
- **Tarefas #1, #14, #16** compartilham a mesma causa raiz: `_knownInfiniteComboPieces` desatualizado. Idealmente resolvidas no mesmo commit unificando as listas.
- **Tarefa #7 e #15** compartilham a mesma causa raiz (detecção de rituais sem qualificador) mas em funções diferentes (`_looksLikeRitual` em functional_card_tags.dart vs `_isTemporaryManaBurstCard` em optimization_quality_gate.dart). Ambas precisam da mesma correção.
- **SQLite freshness:** `optimizer_quality_reviews` 53→123 (70 novos), `slot_benchmarks` 45→115 (70 novos) — optimizer ativo. `swap_benchmarks` estagnado em 2 e `user_learning_events` em 51 — aprendizado/benchmarking parado.
