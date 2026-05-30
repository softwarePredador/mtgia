# Implementation Tasks — ManaLoom

> Gerado por sintese manual: cruzamento do conhecimento MTG do Hermes × codigo atual.
> Data: 2026-05-30 | Branch: master | SHA: 516e79c

---

### [P1] BracketCategory enum nao detecta 29/53 Game Changers oficiais

**Conhecimento MTG:** O Commander oficial definiu 53 Game Changers — cartas que distorcem o jogo e sao restritas por bracket. O Hermes pesquisou todas e identificou 10 categorias de impacto: fast_mana, tutor, card_advantage, free_interaction, board_wipe, stax, value_engine, combo_piece, protection, extra_turns.

**Evidencia no codigo:** `server/lib/edh_bracket_policy.dart:7-13`
```dart
enum BracketCategory {
  fastMana,
  tutor,
  freeInteraction,
  extraTurns,
  infiniteCombo,
}
```
Apenas 5 categorias. 29 GCs nao detectados incluindo: Rhystic Study, Cyclonic Rift, The One Ring, Smothering Tithe, Teferi's Protection, Drannith Magistrate, Opposition Agent, Grand Abolisher, etc.

**Gap:** O sistema de brackets do ManaLoom cobre 24/53 GCs (45%). Cartas como Cyclonic Rift (board wipe unilateral game-winning) e Rhystic Study (23% do formato EDHREC) passam sem deteccao.

**Impacto:** Decks em bracket 3 podem incluir GCs nao-detectados sem consumir o limite de 3. O sistema de otimizacao pode sugerir trocas que adicionam GCs sem alertar o usuario.

**Acao recomendada:**
1. Adicionar `boardWipe`, `cardAdvantage`, `stax`, `protection`, `valueEngine` ao `BracketCategory` enum
2. Expandir `tagCardForBracket()` com heuristicas para cada nova categoria
3. Adicionar `boardWipe` aos limites de bracket em `BracketPolicy.forBracket()`
4. Atualizar `applyBracketPolicyToAdditions()` para usar as novas categorias

**Validacao:**
```bash
cd server
dart analyze lib/edh_bracket_policy.dart
dart test test/edh_bracket_policy_test.dart
```

---

### [P1] card_deck_profiles (670 perfis) nao consultado pelo optimize

**Conhecimento MTG:** O Hermes importou 670 perfis de cartas por deck (`card_deck_profiles` no PostgreSQL) com dados de funcao, importancia e contexto estrategico por comandante. Estes perfis dizem quais cartas sao ESSENCIAIS vs FILLER em cada deck especifico.

**Evidencia no codigo:** `server/lib/ai/candidate_quality_data_support.dart` e `server/lib/ai/optimize_runtime_support.dart` — `filterUnsafeOptimizeSwapsByCardData` usa `card_meta_insights` e `card_function_tags`, mas NAO consulta `card_deck_profiles`.

**Gap:** 670 perfis de carta-por-deck existem no banco mas nao sao usados pelo fluxo de otimizacao. O optimize decide swaps baseado em metricas genericas (pop_score, usage_count), nao em conhecimento contextual ("esta carta e FILLER no deck X, pode ser removida").

**Impacto:** O optimize pode sugerir remover cartas que sao CORE no contexto do comandante, ou manter cartas que sao FILLER conhecido.

**Acao recomendada:**
1. Adicionar consulta a `card_deck_profiles` em `filterUnsafeOptimizeSwapsByCardData`
2. Usar `importance` e `functional_role` do perfil para ajustar scores de candidatos
3. Cartas marcadas como `importance=filler` devem ter prioridade de remocao aumentada
4. Cartas marcadas como `importance=core` devem ser protegidas contra remocao

**Validacao:**
```bash
cd server
dart analyze lib/ai/candidate_quality_data_support.dart lib/ai/optimize_runtime_support.dart
dart test test/candidate_quality_data_support_test.dart test/optimization_validator_test.dart
```

---

### [P2] Recommendations e weakness-analysis usam heuristicas legacy (sem semantic v2)

**Conhecimento MTG:** O fluxo core (analysis/optimize) ja usa `functional_tags` + `semantic_tags_v2` com cobertura de 72.3% das cartas. As tags semanticas v2 fornecem classificacao multi-tag com confidence score.

**Evidencia no codigo:**
- `server/routes/decks/[id]/recommendations/index.dart:110-130` — conta ramp/draw/removal/wipes por `oracle_text` local, sem `functional_tags` ou `semantic_tags_v2`
- `server/routes/ai/weakness-analysis/index.dart:114-163` — mesmo problema, + nomes hardcoded (`teferi's protection`, `heroic intervention`)
- `server/routes/ai/weakness-analysis/index.dart:206-248` — recomendacoes sao listas fixas de nomes de carta

**Gap:** Duas rotas publicas usam heuristica unidimensional enquanto o pipeline core ja tem classificacao multi-tag precisa. Se expostas ao app, o usuario recebe recomendacoes de qualidade inferior.

**Impacto:** Antes de serem promovidas a fluxo de produto, estas rotas precisam ser atualizadas para usar a mesma camada semantica do resto do sistema.

**Acao recomendada:**
1. Substituir contagem por `oracle_text` em recommendations por `summarizeFunctionalTagsForDeck()`
2. Substituir listas fixas de nomes em weakness-analysis por queries filtradas por `functional_tags` + identidade de cor + bracket
3. Adicionar `semantic_tags_v2` como fonte secundaria de classificacao

**Validacao:**
```bash
cd server
dart analyze routes/decks/[id]/recommendations/index.dart routes/ai/weakness-analysis/index.dart
dart test test/functional_card_tags_test.dart
```

---

### [P2] _looksLikePayoff nao detecta payoffs de dano direto com triggers ETB/cast

**Conhecimento MTG:** Em Commander, payoffs de dano direto como Impact Tremors, Guttersnipe, e Purphoros sao win conditions legitimas em decks de tokens/spellslinger. O Scout do Hermes identificou que Guttersnipe esta em 32.4% dos decks Lorehold.

**Evidencia no codigo:** `server/lib/ai/optimization_functional_roles.dart:388-392`
A funcao `_looksLikePayoff` detecta "whenever...create...token" e "whenever you cast...copy/scry" mas NAO detecta "whenever [trigger]...deals damage to [target]".

**Gap:** Cartas como Impact Tremors ("whenever a creature enters... deals 1 damage to each opponent") e Guttersnipe ("whenever you cast an instant or sorcery... deals 2 damage to each opponent") nunca sao classificadas como `payoff`.

**Impacto:** O quality gate pode permitir swaps que removem estas cartas sem reconhecer que sao win conditions, ou nao prioriza-las em decks onde sao o payoff principal.

**Acao recomendada:** Adicionar padrao em `_looksLikePayoff`: "whenever [trigger]...deals [X] damage to [target]" combinado com triggers ETB/cast/spell.

**Validacao:**
```bash
cd server
dart analyze lib/ai/optimization_functional_roles.dart
dart test test/optimization_quality_gate_test.dart -N "payoff"
```

---

### [P3] docs/CONTEXTO_PRODUTO_ATUAL.md desatualizado desde 2026-03-25

**Conhecimento MTG:** N/A (task de documentacao)

**Evidencia no codigo:** `docs/CONTEXTO_PRODUTO_ATUAL.md` — ultima atualizacao 2026-03-25. `server/manual-de-instrucao.md` vai ate 2026-05-21. Ha ~2 meses de decisoes nao refletidas na fonte de verdade operacional.

**Gap:** O documento que define a prioridade do produto esta 2 meses desatualizado. Decisoes recentes (F0-F3, extracao de gargalos, Semantic V2, Commander Reference Sprint 4, Life Counter benchmark clone) nao estao documentadas.

**Impacto:** Novos contribuidores ou agentes (Hermes) podem tomar decisoes baseadas em prioridades de marco/2025 que ja foram concluidas ou alteradas.

**Acao recomendada:** Atualizar `docs/CONTEXTO_PRODUTO_ATUAL.md` com:
- Status atual dos gargalos (F0-F3 aplicados)
- Semantic V2 status (partial mode, flag expandida)
- Life Counter status (benchmark clone concluido)
- Hermes agent integrado
- Novos modulos extraidos

**Validacao:** Revisao manual do documento.
