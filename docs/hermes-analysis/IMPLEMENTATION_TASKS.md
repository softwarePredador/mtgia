# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-15  
> **Cron:** manaloom-knowledge-synthesis  
> **Método:** Cross-referência do conhecimento MTG (skills + logs + SQLite) contra código Dart vivo  
> **Skills carregados:** manaloom-mtg-strategy (v1.1.0), manaloom-mtg-domain (v2.18.0)  
> **Base de conhecimento:** SCOUT_LOG, VALIDATOR_LOG, MANA_BASE_VALIDATION_REPORT, GAME_CHANGERS.md, THEMES.md, GAMECHANGER_RESEARCH_REPORT.md, LOGIC_COHERENCE_REPORT, STRUCTURE_AUDIT.md, SQLite knowledge.db (15 tabelas)  
> **Branch:** codex/hermes-analysis-docs  
> **Novas tasks nesta execução:** 5 (1×P0, 3×P1, 1×P2)

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
