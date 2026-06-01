# Tag Accuracy Report — 2026-06-01

**Generated:** 2026-06-01T14:41:27+00:00
**Source:** `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` → `tag_accuracy`
**Schema:** 22 tags, 7 columns (id, tag_name, correct_count, total_count, false_positive, false_negative, last_updated)
**Data period:** 2026-05-26 to 2026-05-27 (seeded from deck analysis imports)
**Status:** First report (no prior baseline)

---

## 1. Precisão Por Tag

| Tag | Correto | Total | Precisão | fp | fn | Risk |
|:----|:------:|:-----:|:--------:|:--:|:--:|:-----|
| **payoff** | 11 | 31 | **35.5%** 🔴 | 0 | 0 | Alto |
| **combo_piece** | 1 | 2 | **50.0%** 🔴 | 0 | 0 | Alto* |
| **enabler** | 21 | 42 | **50.0%** 🔴 | 0 | 0 | Alto |
| **other** | 1 | 2 | **50.0%** 🔴 | 0 | 0 | Baixo* |
| **protection** | 9 | 13 | **69.2%** 🔴 | 0 | 0 | Médio |
| **wincon** | 6 | 8 | **75.0%** 🟡 | 0 | 0 | Médio-Alto |
| **engine** | 6 | 8 | **75.0%** 🟡 | 0 | 0 | Médio-Alto |
| ramp | 53 | 53 | 100.0% 🟢 | 0 | 0 | Baixo |
| draw | 32 | 32 | 100.0% 🟢 | 0 | 0 | Baixo |
| removal | 30 | 30 | 100.0% 🟢 | 0 | 0 | Baixo |
| land | 87 | 87 | 100.0% 🟢 | 0 | 0 | Baixo |
| utility | 76 | 76 | 100.0% 🟢 | 0 | 0 | Baixo |
| creature | 22 | 22 | 100.0% 🟢 | 0 | 0 | Baixo |
| tutor | 6 | 6 | 100.0% 🟢 | 0 | 0 | Baixo |
| board_wipe | 3 | 3 | 100.0% 🟢 | 0 | 0 | Baixo |
| recursion | 3 | 3 | 100.0% 🟢 | 0 | 0 | Baixo |
| enchantment | 3 | 3 | 100.0% 🟢 | 0 | 0 | Baixo |
| finisher | 2 | 2 | 100.0% 🟢 | 0 | 0 | Baixo |
| planeswalker | 2 | 2 | 100.0% 🟢 | 0 | 0 | Baixo |
| artifact | 2 | 2 | 100.0% 🟢 | 0 | 0 | Baixo |
| sacrifice_outlet | 1 | 1 | 100.0% 🟢 | 0 | 0 | Baixo |
| wipe | 1 | 1 | 100.0% 🟢 | 0 | 0 | Baixo |

*`combo_piece` e `other` têm amostras muito pequenas (n=2) — baixa confiança estatística.

---

## 2. Análise: Tags Abaixo de 85%

### 2.1 Distribuição Bimodal

Os dados mostram uma **distribuição bimodal** clara:
- **15 tags a 100%** — tags mecânicas bem definidas (ramp, draw, removal, land, creature...)
- **7 tags abaixo de 85%** — tags estratégicas/contextuais (payoff, enabler, engine, wincon, combo_piece, protection)
- **NENHUMA tag no intervalo 85-99%** — a classificação ou é exata, ou é fraca

Isto indica que o sistema tem **dois perfis de classificador**: um determinístico e preciso para tags mecânicas, e um heurístico e impreciso para tags estratégicas.

### 2.2 Root Cause: Heurísticas Estreitas

As funções heurísticas para os tags estratégicos são **extremamente estreitas** — capturam apenas um subconjunto minúsculo do que o tag realmente significa:

| Tag | Heurística (Dart `_looksLike*`) | O que NÃO captura |
|:----|:--------------------------------|:------------------|
| **payoff** | `whenever + create token` OU `whenever you cast + copy/scry` | Aristocratas (Blood Artist, Zulaport Cutthroat), drain, "for each creature" pumps, ETB scaling |
| **enabler** | `cost less to cast` OU `spells cost...less` | Ashnod's Altar, Phyrexian Altar, haste enablers, extra land drops, mill engines, sacrifice outlets |
| **engine** | `at beginning of your upkeep + you may` OU `whenever + you may + draw/create/add` | Rhystic Study, Smothering Tithe, Esper Sentinel, Mystic Remora, triggered value sem "you may" |
| **wincon** | `you win the game` OU `opponent loses the game` | Triumph of the Hordes, Craterhoof Behemoth, Torment of Hailfire, Approach of the Second Sun (Dart-only) |
| **combo_piece** | `remove counter from among` OU `search + may cast without paying` | Basalt Monolith, Kiki-Jiki combos, Dramatic Reversal, infinite mana outlets |
| **protection** | `hexproof/indestructible/shroud/ward/phase out/protection from` | Counterspells como proteção (Fierce Guardianship, Force of Will), blink como proteção, Mother of Runes |

### 2.3 Impacto no Pipeline

Tags de baixa precisão afetam diretamente o Evolution Oracle:
- **payoff a 35.5%**: 20 das 31 cartas com esse tag são classificadas incorretamente. O Oracle pode remover payoff pieces pensando que são filler.
- **enabler a 50%**: 21 enablers invisíveis ao classificador. O Oracle pode cortar peças de suporte sem saber.
- **protection a 69.2%**: 4 proteções não detectadas. Fierce Guardianship e Force of Will são classificadas como `removal` em vez de `protection`.

---

## 3. Sinais que Precisam Virar Teste

### 3.1 Gap: false_positive / false_negative = 0

As colunas `false_positive` e `false_negative` existem no schema mas **NUNCA foram populadas** — estão zeradas em todas as 22 tags. O script `knowledge_db.py` só registra `tag_match` (0 ou 1) e atualiza `correct_count` e `total_count`. Não há como saber QUAIS cartas específicas foram classificadas errado — só o agregado.

**Sinal:** Precisamos de um mecanismo de rastreamento de erros individuais, não só contagem agregada.

### 3.2 Gap: 29 Double-Null Cards

29 cartas (7.4% das cartas não-terreno) são completamente invisíveis a AMBOS os classificadores:
- `functional_tag IS NULL` (single-tag não retornou nada)
- `card_tags` tem ZERO entradas (multi-tag também não retornou nada)

Exemplos críticos: **Scroll Rack** (engine de topdeck), **Lim-Dûl's Vault** (tutor), **Grand Abolisher** (proteção proativa), **Tetsuko Umezawa** (enabler de evasão).

**Sinal:** Qualquer ciclo de swap que proponha remover um double-null pode estar removendo uma peça essencial. O Lorehold pipeline já documenta este problema — agora é visível globalmente.

### 3.3 Gap: functional_tag vs card_tags Divergência (21.5%)

84 cartas (21.5% das cartas não-terreno) têm `functional_tag` que NÃO aparece nos `card_tags`:
- Single-tag diz `creature`, multi-tag diz `enabler`, `protection` ou `token_maker`
- Single-tag diz `wipe`, multi-tag diz `board_wipe, enabler, payoff`
- Single-tag diz `utility`, multi-tag diz `big_spell` ou `token_maker`

**Sinal:** O single-tag classifier (usado para `functional_tag` no deck_cards) e o multi-tag (usado para `card_tags`) discordam em 1 a cada 5 cartas. O `functional_tag` é o que o Evolution Oracle usa para calcular métrica de deck (ramp_count, draw_count, etc.) — uma classificação errada distorce os thresholds de ciclo.

### 3.4 Gap: 77 Cartas Sem Multi-Tags (19.7%)

77 cartas não-terreno não têm NENHUMA entrada em `card_tags`. Destas, 48 também têm `functional_tag = 'creature'` ou `'enchantment'` — são criaturas com oracle text vazio ou minimal (stax pieces como Drannith Magistrate, Ethersworn Canonist, Aven Mindcensor).

**Sinal:** O multi-tag classifier não está rodando em ~20% das cartas. Ou o oracle text está faltando, ou a função retorna lista vazia para certos padrões.

---

## 4. Recomendações de Código

### 4.1 Ampliar Heurísticas Estratégicas (Alta Prioridade)

**Arquivo:** `server/lib/ai/optimization_functional_roles.dart` (linhas 370-398)
**Arquivo:** `server/lib/ai/functional_card_tags.dart` (linhas 859-907)
**Arquivo:** `docs/hermes-analysis/manaloom-knowledge/scripts/scryfall_classifier.py` (linhas 155-221)

**Ação:** Expandir as funções `_looksLikeWincon`, `_looksLikeEngine`, `_looksLikeComboPiece`, `_looksLikePayoff`, `_looksLikeEnabler` com padrões adicionais:

```dart
// _looksLikeWincon — adicionar:
oracle.contains('each opponent loses') && oracle.contains('life') ||
oracle.contains('double') && oracle.contains('damage') ||
oracle.contains('deals damage equal to') && oracle.contains('power') ||

// _looksLikeEngine — adicionar:
oracle.contains('whenever') && oracle.contains('draw a card') && !oracle.contains('you may') ||
oracle.contains('whenever an opponent') && oracle.contains('you may draw') ||

// _looksLikeEnabler — adicionar:
oracle.contains('sacrifice a creature') && oracle.contains('add') ||
oracle.contains('creatures you control have haste') ||
oracle.contains('you may play an additional land') ||
```

**Nota:** O Python `classify_card()` (scryfall_classifier.py) sequer tem as chamadas para `_looksLikeWincon/Engine/ComboPiece/Payoff/Enabler` — o single-tag classifier Python é uma versão truncada. Isso significa que as análises Python (validators, scouts) usam um classificador mais limitado que o Dart.

### 4.2 Unificar Single-Tag e Multi-Tag (Média Prioridade)

**Problema:** Dois classificadores independentes produzem tags diferentes para 21.5% das cartas.

**Arquivos envolvidos:**
- `server/lib/ai/optimization_functional_roles.dart` → `classifyOptimizationFunctionalRole()` (single-tag)
- `server/lib/ai/functional_card_tags.dart` → `inferFunctionalCardTags()` (multi-tag)
- `docs/hermes-analysis/manaloom-knowledge/scripts/scryfall_classifier.py` → `classify_card()` e `infer_functional_card_tags()`

**Recomendação:** O single-tag classifier (`classifyOptimizationFunctionalRole`) deveria usar o multi-tag como fallback, não uma heurística independente. Quando `_classifySemanticV2FunctionalRole()` retorna null, o código atual roda heurísticas manuais (linhas 113-117 do optimization_functional_roles.dart). Em vez disso, deveria chamar `inferFunctionalCardTags()` e usar o tag de maior confidence.

```dart
// optimization_functional_roles.dart — sugerido:
if (semanticRole != null) return semanticRole;
// Fallback: usar multi-tag com confidence mínima
final multiTags = inferFunctionalCardTags(name: name, ...);
if (multiTags.isNotEmpty && multiTags.first.confidence >= 0.75) {
  return multiTags.first.tag;
}
// Só então rodar heurísticas manuais
```

### 4.3 Popular false_positive / false_negative (Média Prioridade)

**Arquivo:** `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge_db.py` (linha 429-439)

O código atual só registra `tag_match` booleano. Para popular `false_positive` e `false_negative`, precisamos de:

1. **false_positive**: Quando o sistema atribui um tag que o revisor humano considera INCORRETO. Exemplo: Force of Will → `removal` (false positive para removal, deveria ser `protection`).
2. **false_negative**: Quando o sistema NÃO atribui um tag que o revisor humano considera CORRETO. Exemplo: Basalt Monolith → sem tag `combo_piece` (false negative para combo_piece).

**Schema update sugerido:** Adicionar tabela `tag_errors` com `card_name, assigned_tag, expected_tag, error_type (fp/fn), reviewed_by, reviewed_at` para rastreamento granular.

### 4.4 Fechar o Gap Oracle Text (Baixa Prioridade)

**Problema:** 77 cartas (19.7%) sem multi-tags — muitas são criaturas com oracle text vazio.

**Verificação:** `card_oracle_data` tem 453 linhas, mas `deck_cards` pode ter mais. O classificador depende de oracle text para funcionar. Cartas sem oracle text no banco recebem apenas o type-based fallback.

**Ação:** Rodar um bulk fetch da Scryfall API para preencher oracle text de todas as cartas em `deck_cards` que não têm entrada em `card_oracle_data`.

---

## 5. Dados de Suporte (Discrepancies Table)

A tabela `discrepancies` (20 entradas) documenta casos específicos onde o tag ManaLoom diverge do esperado:

| Carta | ML Tag | Expected | Impacto |
|:------|:-------|:---------|:--------|
| Basalt Monolith | ramp | combo_piece | HIGH — subestima a carta |
| Blood Artist | removal | payoff | HIGH — ignora wincon |
| Underworld Breach | recursion | recursion + wincon | HIGH — missing wincon tag |
| Temporal Trespass | big_spell | wincon | HIGH — classificado como fardo |
| Shadow of Mortality | creature | wincon | HIGH — nunca jogada como criatura |
| Pitiless Plunderer | ramp | ramp + combo_piece | MEDIUM — dual function |
| Gaea's Cradle | land | ramp | MEDIUM — perde contexto |
| Fierce Guardianship | removal | protection | MEDIUM — counter = proteção |
| Mayhem Devil | removal | payoff + removal | MEDIUM — dual function |
| Thrasios (no 99) | engine | wincon | MEDIUM — outlet de mana |
| Dark Ritual | ritual | ramp | MEDIUM — ritual = ramp em Yuriko |
| Korvold | draw | engine | HIGH — sistema não tem tag engine |
| Mystic Remora | draw | stax_light | MEDIUM — missing stax tag |
| Commandeer | removal | protection | LOW — counter como proteção |

**Padrão:** O classificador frequentemente erra em:
1. **Dual-function cards** — o sistema retorna 1 tag, mas a carta tem 2 funções igualmente importantes
2. **Context-dependent cards** — a função da carta muda conforme o deck (counter = proteção em cEDH)
3. **Cards que não são jogados normalmente** — Shadow of Mortality e Temporal Trespass nunca são CAST em Yuriko

---

## 6. Sumário Executivo

| Métrica | Valor |
|:--------|:-----|
| Tags no sistema | 22 |
| Tags com 100% de precisão | 15 (68%) |
| Tags abaixo de 85% | 7 (32%) |
| Pior precisão | **payoff (35.5%)** |
| Cartas double-null | 29 (7.4% das não-terreno) |
| Divergência single vs multi tag | 84 cartas (21.5%) |
| Cartas sem multi-tags | 77 (19.7%) |
| fp/fn tracking implementado | NÃO (colunas zeradas) |
| Discrepâncias documentadas | 20 |

**Ações recomendadas (ordem de prioridade):**
1. 🔴 Ampliar heurísticas `_looksLike*` para payoff/enabler/engine/wincon — as funções atuais são demasiado estreitas
2. 🔴 Adicionar chamadas `_looksLike*` no Python `classify_card()` que hoje as omite
3. 🟡 Unificar single-tag e multi-tag — eliminar a divergência de 21.5%
4. 🟡 Implementar rastreamento granular de fp/fn com tabela `tag_errors`
5. 🟢 Preencher oracle text faltante para reduzir double-nulls e no-multi-tag
