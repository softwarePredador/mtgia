# Tag Accuracy Report — 2026-06-05

**Generated:** 2026-06-05T22:30:00+00:00
**Source:** `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` → `tag_accuracy`, `deck_cards`, `card_tags`, `discrepancies`
**Previous report:** 2026-06-03
**Schema:** 22 tags in `tag_accuracy` (unchanged since 2026-05-27 — **9 days stale**)

---

## 1. Mudanças desde o Último Relatório (2026-06-03 → 2026-06-05)

| Métrica | 2026-06-03 | 2026-06-05 | Delta |
|:--------|:----------:|:----------:|:-----:|
| `tag_accuracy` rows | 22 | 22 | 0 |
| `tag_accuracy` last_updated | 2026-05-27 | **2026-05-27** | **Nenhuma (9 dias)** |
| Discrepancies | 21 | 21 | 0 |
| `deck_cards` total | 543 | 543 | 0 |
| Decks | 7 | **8** | **+1** 🆕 |
| `functional_tag = 'unknown'` | 3 | 3 | 0 |
| `functional_tag IS NULL` | 32 | 32 | 0 |
| Double-null cards | 25 (4.6%) | 26 (4.8%) | +1 |
| Cards without multi-tag | 128 (23.6%) | **112 (20.6%)** | **-16** ✅ |
| Cards with `CMC = 0.0` (all decks) | ~36 (deck 6 only) | **142 (26.2%)** | **+106** 🔴 |
| New tags NOT in `tag_accuracy` | 4 | **12** | **+8** 🔴 |
| **Legacy tags ORPHANED** | 0 | **5** | **+5** 🔴 |
| New deck (Atraxa, bracket 4) | 0 | 1 (100 cards) | +1 🆕 |

> **Conclusão:** Duas mudanças estruturais ocorreram desde o último relatório:
> 1. **Fork do sistema de tags**: O classificador Python passou a gravar tags finas (`aristocrat_payoff`, `token_maker`, `big_spell`…) diretamente no banco, ignorando a função de mapeamento `_select_primary_role()` que converte para as categorias legadas. Resultado: 5 tags legadas ficaram órfãs (0 cartas) e 12 novas tags surgiram sem entrada em `tag_accuracy`.
> 2. **Corrupção de CMC generalizada**: O bug de CMC (antes restrito ao deck 6 com 36 cartas) se espalhou para TODOS os 7 decks do banco — 142 cartas (26.2% do total) com `CMC = 0.0`.
> 3. **Novo deck**: Atraxa, Praetors' Voice (deck 9, bracket 4, 100 cartas) — todas as 29 cartas com CMC inválido.

---

## 2. Precisão Por Tag — Sistema Bifurcado

### 2.1 Tags Legadas (INALTERADO desde 2026-05-27 — 9 dias)

Estas são as 22 tags em `tag_accuracy`. **5 delas (marcadas com ⚠️) não têm NENHUMA carta no banco** — foram completamente substituídas pelo novo sistema de tags finas.

| Tag | Correto | Total | Precisão | fp | fn | Cartas no DB | Risk |
|:----|:------:|:-----:|:--------:|:--:|:--:|:------------:|:-----|
| **payoff** ⚠️ | 11 | 31 | **35.5%** 🔴 | 0 | 0 | **0** | Órfã |
| **combo_piece** ⚠️ | 1 | 2 | **50.0%** 🔴 | 0 | 0 | **0** | Órfã |
| **enabler** ⚠️ | 21 | 42 | **50.0%** 🔴 | 0 | 0 | **0** | Órfã |
| **other** ⚠️ | 1 | 2 | **50.0%** 🔴 | 0 | 0 | **0** | Órfã |
| **finisher** ⚠️ | 2 | 2 | **100.0%** | 0 | 0 | **0** | Órfã |
| **protection** | 9 | 13 | **69.2%** 🔴 | 0 | 0 | 24 | Alto |
| **wincon** | 6 | 8 | **75.0%** 🟡 | 0 | 0 | 10 | Médio-Alto |
| **engine** | 6 | 8 | **75.0%** 🟡 | 0 | 0 | **1** ⚠️ | Colapso |
| land | 87 | 87 | 100.0% 🟢 | 0 | 0 | 127 | Baixo |
| ramp | 53 | 53 | 100.0% 🟢 | 0 | 0 | 98 | Baixo |
| draw | 32 | 32 | 100.0% 🟢 | 0 | 0 | 54 | Baixo |
| removal | 30 | 30 | 100.0% 🟢 | 0 | 0 | 39 | Baixo |
| utility | 76 | 76 | 100.0% 🟢 | 0 | 0 | 8 | Baixo |
| creature | 22 | 22 | 100.0% 🟢 | 0 | 0 | 52 | Baixo |
| tutor | 6 | 6 | 100.0% 🟢 | 0 | 0 | 13 | Baixo |
| board_wipe | 3 | 3 | 100.0% 🟢 | 0 | 0 | 2 | Baixo |
| recursion | 3 | 3 | 100.0% 🟢 | 0 | 0 | 10 | Baixo |
| enchantment | 3 | 3 | 100.0% 🟢 | 0 | 0 | 5 | Baixo |
| artifact | 2 | 2 | 100.0% 🟢 | 0 | 0 | 2 | Baixo |
| planeswalker | 2 | 2 | 100.0% 🟢 | 0 | 0 | 2 | Baixo |
| sacrifice_outlet | 1 | 1 | 100.0% 🟢 | 0 | 0 | 5 | Baixo |
| wipe | 1 | 1 | 100.0% 🟢 | 0 | 0 | 1 | Baixo |

⚠️ = Tag órfã: existe em `tag_accuracy` mas tem **0 cartas** com este `functional_tag` no banco.

### 2.2 🔴 12 Novas Tags Sem Precisão Conhecida

Estas tags existem como `functional_tag` no banco mas NÃO têm entrada em `tag_accuracy`:

| Tag | Cartas | Principal(is) Deck(s) | Precisão | Risco |
|:----|:------:|:----------------------|:--------:|:-----|
| **token_maker** | 16 | 4 (8), 5 (5), 7 (2) | ❌ Desconhecida | Alto |
| **big_spell** | 10 | 2 (4), 5 (4), 1 (1), 3 (1) | ❌ Desconhecida | Alto |
| **aristocrat_payoff** | 9 | 4 (8), 3 (1) | ❌ Desconhecida | Alto |
| **graveyard_synergy** | 5 | 2 (1), 4 (2), 5 (1), 1 (1) | ❌ Desconhecida | Médio |
| **exile_value** | 4 | 2 (4) | ❌ Desconhecida | Baixo |
| **drain** | 3 | 4 (3) | ❌ Desconhecida | Médio |
| **combo** | 3 | 6 (3) | ❌ Desconhecida | Médio-Alto |
| **stax** | 1 | 6 (1) | ❌ Desconhecida | Médio |
| **spellslinger** | 1 | 6 (1) | ❌ Desconhecida | Médio |
| **lifegain** | 1 | 5 (1) | ❌ Desconhecida | Baixo |
| **enchantment_synergy** | 1 | 2 (1) | ❌ Desconhecida | Baixo |
| **commander** | 1 | 6 (1) | ❌ Desconhecida | Baixo |

> **57 cartas (10.5% do total)** usam tags com precisão completamente desconhecida.
> Destas, **35 cartas (token_maker + aristocrat_payoff + big_spell)** são as mais impactantes.

### 2.3 Distribuição Bimodal (Quebrada)

O sistema agora tem **3 camadas de tags** em vez das 2 originais:
- **15 tags legadas a 100%** — tags mecânicas bem definidas (ainda funcionam)
- **5 tags legadas abaixo de 100%** — tags estratégicas/contextuais (3 delas órfãs!)
- **12 tags novas SEM precisão** — sistema bifurcado, sem métrica

---

## 3. 🔴 CMC Corruption Generalizada: 142 Cartas (26.2%)

O bug de CMC, antes restrito ao deck 6 (36 cartas), **se espalhou para todos os 7 decks**:

| Deck | Nome | Cartas com CMC=0.0 | % do deck |
|:-----|:-----|:------------------:|:---------:|
| 6 | Lorehold Best-of Learned | 36 | 36.0% |
| 9 | Atraxa EDHREC Average 🆕 | 29 | 29.0% |
| 7 | Boros Combat Trigger Humans | 22 | 22.0% |
| 2 | Dimir Ninja Topdeck Tempo | 19 | 22.6% |
| 5 | Aesi EDHREC Average | 19 | 24.1% |
| 4 | EDHREC Average Default | 15 | 18.8% |
| 1 | Kinnan, Bonder Prodigy | 2 | 15.4% |
| **Total** | | **142** | **26.2%** |

> **Impacto:** O Evolution Oracle, Mulligan Analyst, Validator, e qualquer análise de curva de mana
> operam com **¼ dos dados de CMC corrompidos**. Nenhum swap ou recomendação de mulligan pode
> ser confiável enquanto 142 cartas têm `CMC = 0.0`.

**Query de detecção:**
```sql
SELECT COUNT(*) FROM deck_cards WHERE cmc = 0.0;
-- Resultado: 142
```

---

## 4. 🔴 Fork do Sistema de Tags: Raiz do Problema

### 4.1 O que aconteceu

O classificador Python (`scryfall_classifier.py`) tem duas funções:

1. **`infer_functional_card_tags()`** (L573): Retorna tags finas como `aristocrat_payoff`, `token_maker`, `big_spell`, `graveyard_synergy`, etc.
2. **`classify_card()`** (L155): Chama `infer_functional_card_tags()` e depois **mapeia** os resultados via `_select_primary_role()` (L532) para as categorias legadas (`engine`, `wincon`, `creature`, `draw`, etc.)

**O mapeamento `_select_primary_role()` (L535-551) existe e funciona:**
```python
role_map = {
    "token_maker": "creature",
    "aristocrat_payoff": "engine",
    "spellslinger": "engine",
    "graveyard_synergy": "engine",
    "big_spell": "wincon",
    "drain": "wincon",
    "exile_value": "draw",
    "lifegain": "utility",
    ...
}
```

Mas os scripts que escrevem em `knowledge.db` **não estão usando `classify_card()`**. Em vez disso, usam `infer_functional_card_tags()` diretamente e gravam a primeira tag do resultado como `functional_tag`:

- `ciclo4_swaps.py` L91: `tags = infer_functional_card_tags(...)` — sem mapeamento
- `parse_collection.py` L110: `tags = infer_functional_card_tags(...)` — sem mapeamento

Isso fez com que as tags finas fossem gravadas diretamente no banco, ignorando o mapeamento `_select_primary_role()`.

### 4.2 Consequências

- **5 tags legadas órfãs**: `payoff`, `combo_piece`, `enabler`, `finisher`, `other` — 0 cartas
- **12 novas tags sem métrica**: Precisão completamente desconhecida para 57 cartas
- **Engine em colapso**: Apenas 1 carta com tag `engine` (Past in Flames). As outras 7 cartas que deviam ser `engine` foram distribuídas como `aristocrat_payoff`, `draw`, `ramp`, etc.
- **`tag_accuracy` mapeia tags que não existem mais**: As 5 tags órfãs em `tag_accuracy` têm `correct_count` e `total_count` baseados em cartas que já foram reclassificadas

### 4.3 Evidência no Código

| Arquivo | Linha | Problema |
|:--------|:-----:|:---------|
| `scripts/scryfall_classifier.py` | 535-551 | `_select_primary_role()` mapeia tags finas → legadas (FUNCIONA) |
| `scripts/scryfall_classifier.py` | 155-187 | `classify_card()` usa o mapeamento (FUNCIONA) |
| `scripts/ciclo4_swaps.py` | 91 | Usa `infer_functional_card_tags()` DIRETO — **ignora mapeamento** |
| `scripts/parse_collection.py` | 110 | Usa `infer_functional_card_tags()` DIRETO — **ignora mapeamento** |
| `scripts/knowledge_db.py` | 396 | Grava `functional_tag` como recebido — sem validação |
| `server/lib/ai/optimization_functional_roles.dart` | 55-125 | Classificador Dart — **não afetado** (usa sistema legado) |

---

## 5. Mudanças nos Sinais de Erro

### 5.1 Cards Without Multi-Tag: 128 → 112 (-16 ✅)

Redução de 16 cartas — o pipeline de `card_tags` foi executado em parte dos decks.
Porém 112 cartas (20.6%) ainda não têm entradas em `card_tags`.

### 5.2 Divergência func vs multi-tag: 255 Cartas Diferentes

255 cartas têm pelo menos uma entrada em `card_tags` com tag diferente do `functional_tag`.
Isso é esperado em um sistema multi-tag (uma carta pode ser `ramp` + `combo_piece`),
mas a divergência é alta e **não é rastreada**.

Exemplos notáveis de divergência:
- Basalt Monolith: func=`ramp`, multi=`combo_piece` (conf=0.72)
- Rhystic Study: func=`draw`, multi=`engine` (conf=0.70)
- Fierce Guardianship: func=`big_spell`, multi=`protection` (conf=0.62)
- The One Ring: func=`draw`, multi=`engine`+`lifegain`

### 5.3 Double-Null: 25 → 26 (+1)

Uma carta a mais ficou sem `functional_tag` e sem `card_tags`. Total: 26 (4.8%).

### 5.4 Discrepâncias: 21, Nenhuma Resolvida

As 21 discrepâncias documentadas permanecem não resolvidas (`resolved=0`).
Nenhuma nova discrepância foi detectada desde 2026-05-26.

### 5.5 `card_tags` com 66 Entradas 'Engine', Mas Só 1 Carta com `functional_tag='engine'`

O pipeline de multi-tag (`card_tags`) continua reconhecendo `engine` como tag secundária
em 66 cartas, mas o `functional_tag` (tag primária) colapsou de várias cartas para apenas 1.
Isso indica que os dois pipelines estão usando **classificadores diferentes**:
- `functional_tag` ← `infer_functional_card_tags()` (tags finas, sem mapeamento)
- `card_tags.tag` ← classificador multi-tag (ainda produz `engine`, `combo_piece`, etc.)

---

## 6. Recomendações de Código

### 6.1 🔴 P0: Unificar Classificador — Usar `classify_card()` em Todos os Scripts

**Problema:** Scripts de escrita no banco (`ciclo4_swaps.py`, `parse_collection.py`) usam `infer_functional_card_tags()` diretamente, ignorando o mapeamento `_select_primary_role()` que converte tags finas em legadas.

**Arquivos afetados:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/ciclo4_swaps.py` L91
- `docs/hermes-analysis/manaloom-knowledge/scripts/parse_collection.py` L110
- `docs/hermes-analysis/manaloom-knowledge/scripts/scryfall_classifier.py` L155 (classify_card — já funciona)

**Ação:**
1. Em `ciclo4_swaps.py`, substituir `infer_functional_card_tags(...)` por `classify_card(card_data)`
2. Em `parse_collection.py`, mesma substituição
3. Adicionar validação: todo `functional_tag` gravado deve existir em `tag_accuracy.tag_name` OU ser `'unknown'`
4. Após correção, re-classificar TODOS os decks para eliminar as 12 tags sem métrica

**Impacto:** 57 cartas (10.5%) voltam a ter precisão conhecida. As 5 tags órfãs voltam a ter cartas.

**Risco:** Baixo — `_select_primary_role()` já está implementado e testado. Só precisa ser chamado.

### 6.2 🔴 P0: Corrigir CMC para 142 Cartas

**Problema:** 142 cartas (26.2%) têm `CMC = 0.0`. O bug afeta todos os 7 decks.

**Arquivo provável:** `scripts/scryfall_classifier.py` — a função `_fetch_single()` ou o importador de decks não está populando o CMC. Ou o campo `cmc` está sendo sobrescrito com 0.0 durante a reclassificação.

**Query para correção:**
```sql
-- Buscar CMC real via Scryfall API para TODAS as cartas com CMC=0.0
SELECT DISTINCT card_name FROM deck_cards WHERE cmc = 0.0;
-- Resultado: ~142 nomes únicos para buscar
```

**Ação:**
1. Rodar script que busca CMC via Scryfall API para cada carta com `CMC = 0.0`
2. `UPDATE deck_cards SET cmc = <real> WHERE card_name = '<name>' AND cmc = 0.0`
3. Adicionar guarda: se `cmc IS NULL OR cmc = 0.0` após importação, NÃO gravar (usar valor do oracle)

### 6.3 🔴 P0: Adicionar 12 Novas Tags ao `tag_accuracy`

**Problema:** `token_maker` (16 cartas), `big_spell` (10), `aristocrat_payoff` (9), e outras 9 tags não têm entrada em `tag_accuracy`. Precisão completamente desconhecida.

**Ação (se mantiver tags finas):**
1. Adicionar 12 linhas em `tag_accuracy` com `tag_name` = cada nova tag
2. Popular `correct_count`, `total_count`, `false_positive`, `false_negative` via amostragem manual ou validação cross-reference com EDHREC/Scryfall

**Ação (se unificar com recomendação 6.1):**
Após correção do classificador, as 12 tags finas desaparecerão do `functional_tag` (serão mapeadas para categorias legadas). Neste caso, NÃO adicionar ao `tag_accuracy` — apenas limpar.

### 6.4 🔴 P1: Rodar Pipeline `tag_accuracy` Update (9 Dias Estagnado)

**Problema:** `tag_accuracy.last_updated` = 2026-05-27 para TODAS as 22 tags. A tabela é a única fonte de verdade sobre precisão das classificações e não é atualizada há 9 dias.

**Arquivo:** `scripts/knowledge_db.py` L269-278 (`_tag_accuracy_deltas`), L443-445 (chamada)

**Ação:**
1. Identificar qual script/cron chama `_tag_accuracy_deltas` e por que parou
2. Reativar o pipeline de atualização de `tag_accuracy`
3. Adicionar `last_updated` a cada nova tag adicionada

### 6.5 🟡 P2: Sincronizar `card_tags` com `functional_tag`

**Problema:** 112 cartas (20.6%) sem `card_tags`. O pipeline de multi-tag não é executado automaticamente após classificação.

**Arquivos:**
- `scripts/ciclo4_swaps.py` — classifica mas não popula `card_tags`
- `scripts/parse_collection.py` — classifica mas não popula `card_tags`

**Ação:**
1. Após `infer_functional_card_tags()`, gravar também em `card_tags` com `confidence` e `evidence`
2. Ou criar script separado que popula `card_tags` a partir dos resultados já existentes

### 6.6 🟡 P2: Popular `false_positive` / `false_negative` no `tag_accuracy`

**Status:** Colunas continuam zeradas em todas as 22 tags. Sem rastreamento de erros.

**Ação:** Após reativar pipeline de `tag_accuracy`, validar pelo menos 10% das cartas de cada tag contra fontes externas (EDHREC, Scryfall) e popular `fp`/`fn`.

### 6.7 🟡 P3: Unificar Classificador Dart e Python

**Problema:** O Dart (`optimization_functional_roles.dart`) e o Python (`scryfall_classifier.py`) têm pipelines de classificação diferentes. O Dart usa o sistema legado + semantic V2. O Python bifurcou para tags finas.

**Arquivos:**
- `server/lib/ai/optimization_functional_roles.dart` (L55-125) — Dart, sistema legado
- `scripts/scryfall_classifier.py` (L155-234) — Python, com `_select_primary_role()`

**Ação:** Alinhar os dois classificadores para produzirem o mesmo conjunto de tags.

---

## 7. Sumário Executivo

| Métrica | Valor | Mudança |
|:--------|:-----|:--------|
| Tags no sistema (`tag_accuracy`) | 22 | 0 |
| **Tags órfãs (0 cartas)** | **5** 🔴 | **+5** |
| Tags com 100% de precisão (não-órfãs) | 13 (59%) | -2 |
| Tags abaixo de 85% (não-órfãs) | 4 (18%) | -3 (viraram órfãs) |
| Pior precisão | **payoff (35.5%)** — órfã | — |
| **Novas tags sem `tag_accuracy`** | **12** 🔴 | **+8** |
| Cartas com tag sem precisão | **57 (10.5%)** 🔴 | **+53** |
| Cartas double-null | 26 (4.8%) | +1 |
| Cartas sem multi-tags | 112 (20.6%) | -16 ✅ |
| Cartas 'unknown' (classificador não rodou) | 3 | 0 |
| **Cartas com CMC = 0.0 (inválido)** | **142 (26.2%)** 🔴 | **+106** |
| Decks afetados por CMC inválido | **7 de 8** 🔴 | **+6** |
| fp/fn tracking implementado | NÃO | 0 |
| Discrepâncias documentadas | 21 | 0 |
| Discrepâncias resolvidas | 0 | 0 |
| **Estagnação `tag_accuracy`** | **9 dias** 🔴 | +2 dias |
| **Fork classificador Python vs Dart** | **ATIVO** 🔴 | **NOVO** |

### Conclusão

O sistema de tags sofreu uma **bifurcação não intencional**. O classificador Python passou a
gravar tags finas (`aristocrat_payoff`, `token_maker`, `big_spell`…) diretamente no banco,
ignorando o mapeamento `_select_primary_role()` que as converte para as categorias legadas
usadas pelo `tag_accuracy` e pelo classificador Dart.

**Impacto combinado:**
1. **57 cartas (10.5%)** têm tags sem precisão conhecida — o Evolution Oracle faz recomendações de swap às cegas para estas cartas
2. **142 cartas (26.2%)** têm CMC=0.0 — curva de mana e mulligan completamente inválidos para 7 dos 8 decks
3. **`tag_accuracy` estagnado há 9 dias** — a única tabela de verdade sobre qualidade das classificações está mapeando tags que não existem mais

**Top 3 ações imediatas:**
1. 🔴 Corrigir scripts (`ciclo4_swaps.py`, `parse_collection.py`) para usar `classify_card()` em vez de `infer_functional_card_tags()` direto — re-classificar decks
2. 🔴 Corrigir CMC=0.0 para 142 cartas via Scryfall API — essencial para qualquer análise de mana
3. 🔴 Reativar pipeline `tag_accuracy` e adicionar as tags que persistirem após unificação

**Risco de não agir:** O Evolution Oracle continua gerando recomendações de swap baseadas em
tags sem precisão conhecida para 10.5% das cartas e com CMC corrompido para 26.2% delas.
