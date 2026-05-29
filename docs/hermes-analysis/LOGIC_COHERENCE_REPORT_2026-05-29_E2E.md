# Relatório de Coerência Lógica E2E — Pipeline de Decks

> Data: 2026-05-29T20:15Z
> Commit analisado: `3f7d784f` (Guard expanded semantic roles behind flag) + análise de todo o pipeline
> Validação: `dart analyze` PASS, `dart test` 599/599 PASS

---

## Resumo Executivo

A análise E2E do pipeline de decks (importação → validação → análise funcional → otimização → construção completa) encontrou **3 achados relevantes** na rodada atual:

- **P1**: Flag `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` implementada corretamente, mas o nome da flag tem defaults seguros — inconsistência semântica entre doc e código no manual
- **P1**: `classifyOptimizationFunctionalRole` não usa `semantic_tags_v2` persisted como fonte primária — drift entre classificadores
- **P2**: `looksLikePayoff` ainda frágil para cartas com múltiplos triggers

As seções abaixo detalham cada achado com evidência de código.

---

## 1. Validação de Cartas

### 1.1 Anti-alucinação ✅

**Local:** `server/lib/card_validation_service.dart:67-88`

`_findCard()` valida contra o banco via `LOWER(name) = LOWER(@name)` (case-insensitive, exato). `_findSimilarCards()` usa `ILIKE` com wildcards para fuzzy search. Coberto.

**Verificação de edge cases:** `import_card_lookup_service.dart:6-17` trata acentos (áàâãä → a, ç → c, etc.) via `foldImportLookupKey()`. Localized aliases mapeiam nomes PT-BR para EN. ✅

**Nenhum achado.** A validação anti-alucinação está robusta.

### 1.2 Caminho sem validação — Nenhum achado

Todas as rotas de importação passam por `CardValidationService.validateCardNames()` e `ImportCardLookupService`. O `import_list_service.dart` faz parsing mas a resolução real é feita pelo lookup service que consulta o BD. Não existem "caminhos secretos".

### 1.3 Sugestões de cartas similares ✅

`card_validation_service.dart:91-113`: `_findSimilarCards()` usa `ILIKE '%cleanName%'` com sanitização de caracteres especiais. Descarta nomes vazios. Adequado para produção.

---

## 2. Classificação Funcional

### 2.1 Prioridade de source em FunctionalDeckSummary — ✅ Resolvido em `cf285841`

**Local:** `server/lib/ai/functional_card_tags.dart:125`

A prioridade agora é `functional_tags_then_semantic_v2_then_heuristic`:
1. `functional_tags` persistidas no BD (mais confiável)
2. `semantic_tags_v2` (inferidas heuristicamente se não há persistidas)
3. `inferFunctionalCardTags()` (oracle text fallback)

**Validação:** O código em `summarizeFunctionalTagsForDeck()` (linhas 432-465) implementa corretamente essa cadeia: tenta `persistedTags` primeiro, depois cai para `semanticV2` + `inferredTags`. ✅

### 2.2 Drift entre `functional_card_tags.dart` e `optimization_functional_roles.dart` — P1

**Local:** `server/lib/ai/optimization_functional_roles.dart:55-124`

`classifyOptimizationFunctionalRole()` NÃO consulta `functional_tags` persistidas. Ela consulta apenas `semantic_tags_v2` (via `_classifySemanticV2FunctionalRole()`, linha 56-58) como fonte secundária, mas cai PRIMEIRO para heurísticas de oracle text.

**Impacto:** O `FunctionalDeckSummary` (deck analysis) diz que uma carta é `draw`, mas o `classifyOptimizationFunctionalRole` (usado no validator/optimize) pode dizer `utility` — porque o caminho de classificação é diferente.

**Evidência:**
- `functional_card_tags.dart:455-465` — prioriza `persistedTags` → `semanticV2` → `inferredTags`
- `optimization_functional_roles.dart:56-58` — consulta apenas `semantic_tags_v2`, ignora `functional_tags`
- `optimization_functional_roles.dart:127-181` — `_classifySemanticV2FunctionalRole()` só retorna um papel (maior confiança), não multi-tag

**Recomendação:** Alinhar `classifyOptimizationFunctionalRole()` para consultar `functional_tags` como fonte primária (mesmo padrão de `summarizeFunctionalTagsForDeck`).

**Validação:** Criar teste unitário que compara o output de `classifyOptimizationOptimizationFunctionalRole()` vs `inferFunctionalCardTags()` para um corpus de 20 cartas conhecidas e verificar divergências.

### 2.3 Classificação multi-tag — Nenhum achado relevante

O sistema de multi-tag em `functional_card_tags.dart` (via `inferFunctionalCardTags()`) retorna múltiplos `FunctionalCardTag` com confiança. A conversão para `Set<String>` em `summarizeFunctionalTagsForDeck:466` preserva todos os tags. ✅

### 2.4 Ordem de prioridade de classificação — Nenhum achado

A ordem em `classifyOptimizationFunctionalRole()` (linhas 63-117) está correta:
1. semantic_tags_v2 (via `_classifySemanticV2FunctionalRole`)
2. land → wipe → protection → removal → ramp → draw → tutor → wincon → engine → combo_piece → payoff → enabler → creature → artifact → enchantment → planeswalker → utility

Wipe antes de protection (importante para Boros Charm), protection antes de removal, ramp antes de draw (Smothering Tithe). ✅

### 2.5 Helpers `_looksLike*` — P2

**Local:** `server/lib/ai/optimization_functional_roles.dart:370-398`

**`_looksLikePayoff`** (linha 388-392) é frágil:
```dart
return (oracle.contains('whenever') && oracle.contains('create') && oracle.contains('token')) ||
    (oracle.contains('whenever you cast') && oracle.contains('copy')) ||
    (oracle.contains('whenever you cast') && oracle.contains('scry'));
```
- Não detecta payoffs como "whenever a creature enters, deal 1 damage" (Impact Tremors)
- Detecta `Adrix and Nev, Twincasters` como payoff (create token — mas é mais "engine")

**Impacto:** Payoffs de dano direto e alguns engines classificados incorretamente.

**Recomendação:** Adicionar padrões para "deals *damage* to any target" combinado com triggers.

**Validação:** Rodar `validate_kinnan_tags.py` expandido com corpus de payoffs conhecidos.

---

## 3. Regras de Tema/Arquetipo

### 3.1 Cobertura de arquetipos — Nenhum achado crítico

**Local:** `server/lib/ai/theme_contextual_rules_service.dart:54-68`

`archetypeToTheme()` cobre: spellslinger, goblins, elves, vampires, dragons, landfall, graveyard, tokens, voltron, aristocrats, cedh_combo. Outros arquetipos passam pelo fallback (lowerCase + `_`).

**Nota:** O fallback genérico (`a.replaceAll(' ', '_')`) funciona para arquetipos compostos, mas pode gerar chares que não existem na tabela `theme_contextual_rules`. Nesse caso, o retorno é `[]` (sem regras), sem erro. Isso é seguro (graceful degradation).

### 3.2 Validação temática no validator — ✅

**Local:** `server/lib/ai/optimization_validator.dart:50-64`

`themeValidation` é chamado como step 2.5 no validator. Se `themeService` for null, simplesmente pula (sem quebrar). Se falhar, captura exceção e loga warning. ✅

---

## 4. Sistema de Brackets

### 4.1 Consistência do bracket state — Resolvido

**Local:** `server/lib/edh_bracket_policy.dart:7-14`

`BracketCategory.gameChanger` existe. `BracketPolicy.forBracket()` retorna policies corretas por bracket (1-4). Bracket 4 (cEDH) sem limites práticos (99). ✅

### 4.2 Propagação no optimize — Resolvido em `1aa4da71`

`loadBroadCommanderNonLandFillers` agora recebe `currentDeckCards` real (não `const []`). ✅

---

## 5. Otimização e Trocas

### 5.1 Flag `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` — P1 (doc inconsistency)

**Local:** `server/lib/ai/optimization_functional_roles.dart:326-331` (commit `3f7d784f`)

```dart
bool resolveSemanticV2ExpandedCriticalRoles(String? rawValue) {
  final normalized = rawValue?.trim().toLowerCase();
  return switch (normalized) {
    '1' || 'true' || 'yes' || 'on' || 'expanded' => true,
    _ => false,
  };
}
```

**Comportamento implementado:**
- Padrão = false (expanded roles NÃO bloqueiam)
- Com flag = true: wincon/combo_piece/engine/payoff/enabler passam de review-only para critical

**Achado — Inconsistência entre API_CONTRACTS_AND_DATA_MAP.md e código:**

No `API_CONTRACTS_AND_DATA_MAP.md` (pós-commit), a descrição diz:
> `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES=true` promotes the expanded roles to critical

Mas o código aceita `'1' || 'true' || 'yes' || 'on' || 'expanded'` como truthy. A documentação menciona apenas `true`. Não há menção a `1`, `yes`, `on`, `expanded`.

**Impacto:** Baixo (P1 por inconsistência de contrato). Operadores/quem configura podem não descobrir os valores aceitos sem ler o código.

**Recomendação:** Atualizar `API_CONTRACTS_AND_DATA_MAP.md` ou `manual-de-instrucao.md` para listar todos os valores truthy aceitos.

### 5.2 Trocas que pioram o deck são bloqueadas — ✅

**Local:** `server/lib/ai/optimization_validator.dart:28-80`

O validator executa 3 camadas:
1. Monte Carlo (antes vs depois)
2. Análise funcional (swap-by-swap)
3. Critic IA (segunda opinião)

O veredito final combina todos: `_computeVerdict()` rejeita se Monte Carlo piorou significativamente OU se análise funcional mostra perda crítica. ✅

### 5.3 Re-validation after swaps — ✅

Após trocas aprovadas, o deck resultante é re-validado estruturalmente (via `validateFormatAndRepair()` em optimize/index.dart). Duplicatas e legalidade são verificadas no response. ✅

### 5.4 Infinite loop / degradação iterativa — Nenhum achado

O optimize é single-pass (não iterativo). Não existe loop de "otimiza → otimiza de novo". A qualidade é binária (aprovado/rejeitado). Não há risco de degradação. ✅

---

## 6. Validação de Formato

### 6.1 Banlist ✅

**Local:** `server/lib/deck_rules_service.dart:74-120`

Verifica `card_legalities` por formato. Status `legal` ou `restricted` = permitido. Erro = assume ilegal (fail-safe). Commander limita a 1 cópia (non-basic). ✅

### 6.2 Limite de cópias por NOME (não ID) ✅

**Local:** `server/lib/deck_rules_service.dart:43-53`

Usa `info.name.trim().toLowerCase()` como chave. Cartas com múltiplas edições (diferentes IDs) são corretamente agregadas. ✅

### 6.3 Commander validado separadamente ✅

**Local:** `server/lib/deck_rules_service.dart:37`

`isCommander` pula a verificação de cópias. Commander sempre quantidade 1. ✅

### 6.4 `color_identity` — Nenhum achado na rodada

O `color_identity.dart` valida que todas as cartas estão dentro da identidade de cores do commander. Não verifiquei drift nesta rodada (fora do escopo do commit analisado).

---

## 7. Análise do Commit `3f7d784f`

### O que foi feito

O commit implementa o feature flag `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` para controlar se os 5 papéis semânticos expandidos (`wincon`, `combo_piece`, `engine`, `payoff`, `enabler`) são tratados como critical (bloqueiam trocas) ou review-only (apenas informam).

### Arquivos alterados (7)

| Arquivo | Tipo | Avaliação |
|:--------|:-----|:----------|
| `.hermes.md` | novo | Protocolo Hermes operacional — ✅ consistente com esta análise |
| `API_CONTRACTS_AND_DATA_MAP.md` | doc | ⚠️ Descrição não lista todos os valores truthy aceitos |
| `optimization_functional_roles.dart` | código | ✅ Implementação correta, defaults seguros |
| `manual-de-instrucao.md` | doc | ✅ Documenta o flag e o comportamento padrão |
| `optimize/index.dart` | código | ✅ Flag propagada em todos os call sites |
| `ai_optimize_semantic_enforcement_route_contract_test.dart` | teste | ✅ Contrato atualizado |
| `optimization_validator_test.dart` | teste | ✅ Testes para default (review-only) + expanded (critical) |

### Pontos fortes
1. **Default seguro** — expanded roles começam como review-only. Precisa opt-in para bloquear.
2. **Testes abrangentes** — o test verifica ambos os cenários (default=false e expanded=true).
3. **Propagação consistente** — `expandedCriticalRoles` passado em TODOS os call sites de evaluate.
4. **toDiagnostics inclui flag** — o response informa `expanded_critical_roles` para debugging.

### Pontos de atenção
1. **Doc incomplete** (P1) — API_CONTRACTS não lista todos os valores aceitos.
2. **Nenhum scorecard pré-commit** — o commit foi feito sem scorecard de qualidade validando os 5 novos papéis contra um corpus real de decks (o próprio manual alerta "NÃO habilitar em produção sem scorecard maior").

---

## Resumo de Achados

| # | Severidade | Título | Arquivo |
|:--|:-----------|:-------|:--------|
| 1 | **P1** | Doc não lista todos os valores truthy de `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` | `API_CONTRACTS_AND_DATA_MAP.md` |
| 2 | **P1** | `classifyOptimizationFunctionalRole` não usa `functional_tags` persistidas como fonte primária (drift vs `summarizeFunctionalTagsForDeck`) | `optimization_functional_roles.dart:55-58` |
| 3 | **P2** | `looksLikePayoff` frágil — não detecta payoffs de dano direto | `optimization_functional_roles.dart:388-392` |

### Top 3 Prioridades

1. **P1** — Alinhar `classifyOptimizationFunctionalRole()` para consultar `functional_tags` persistidas (mesmo padrão do deck analysis). Isso elimina o drift entre módulos e garante consistência de classificação em todo o pipeline.

2. **P1** — Completar a documentação do flag `SEMANTIC_LAYER_V2_EXPANDED_CRITICAL_ROLES` com todos os valores aceitos (`1`, `true`, `yes`, `on`, `expanded`).

3. **P2** — Expandir `looksLikePayoff` para detectar payoffs de dano direto (ex: Impact Tremors, Guttersnipe).
