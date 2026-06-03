# Tag Accuracy Report — 2026-06-03

**Generated:** 2026-06-03T06:00:00+00:00
**Source:** `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` → `tag_accuracy`, `deck_cards`, `card_tags`, `discrepancies`
**Previous report:** 2026-06-02
**Schema:** 22 tags in `tag_accuracy` (unchanged since 2026-05-27 — **7 days stale**)

---

## 1. Mudanças desde o Último Relatório (2026-06-02 → 2026-06-03)

| Métrica | 2026-06-02 | 2026-06-03 | Delta |
|:--------|:----------:|:----------:|:-----:|
| `tag_accuracy` rows | 22 | 22 | 0 |
| `tag_accuracy` last_updated | 2026-05-27 | **2026-05-27** | **Nenhuma (7 dias)** |
| Discrepancies | 21 | 21 | 0 |
| `deck_cards` total | 543 | 543 | 0 |
| Decks | 7 | 7 | 0 |
| `functional_tag = 'unknown'` | **20** | **3** | **-17** ✅ |
| `functional_tag IS NULL` | 32 | 32 | 0 |
| Double-null cards | 25 (4.6%) | 25 (4.6%) | 0 |
| Single vs multi divergence | 36 (6.6%) | 36 (6.6%) | 0 |
| No multi-tag cards | 124 (22.8%) | **128 (23.6%)** | **+4** |
| CMC NULL or 0.0 (deck 6) | ~15 | **36** | **+~21** 🔴 |
| New tags NOT in `tag_accuracy` | 0 | **4** | **+4** 🟡 |

> **Conclusão:** 17 das 20 cartas com `functional_tag='unknown'` foram reclassificadas — progresso operacional significativo. Porém a reclassificação introduziu **4 novos tipos de tag** (`stax`, `combo`, `commander`, `spellslinger`) que NÃO existem na tabela `tag_accuracy`, deixando suas precisões desconhecidas. E o número de cartas com CMC corrompido (NULL ou 0.0) no deck 6 **aumentou** para 36 — a reclassificação parece ter zerado CMCs em vez de corrigi-los.

---

## 2. Precisão Por Tag (INALTERADO desde 2026-05-27 — 7 dias)

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

*Tags com total ≤ 2 têm baixa confiança estatística.

**Distribuição Bimodal (INALTERADA):**
- 15 tags a 100% — tags mecânicas bem definidas
- 7 tags abaixo de 85% — tags estratégicas/contextuais
- 0 tags no intervalo 85-99%

---

## 3. 🔴 CMC Corruption Ampliada: 36 Cartas com CMC Inválido no Deck 6

A reclassificação de 17 cartas corrigiu o `functional_tag` mas **PIOROU** a situação do CMC.
Antes, as cartas afetadas tinham CMC=NULL ou CMC=0.0. Agora, após a reclassificação parcial,
**36 cartas no deck 6** (36% do deck!) têm `CMC IS NULL OR CMC = 0.0`.

Isso torna qualquer análise de curva de mana, mulligan, ou CMC médio **completamente inválida**
para este deck. O Evolution Oracle, Mulligan Analyst, e Validator não podem operar com 36%
das cartas sem CMC conhecido.

**Query de detecção:**
```sql
SELECT COUNT(*) FROM deck_cards
WHERE deck_id = 6 AND (cmc IS NULL OR cmc = 0.0);
-- Resultado: 36
```

### Cartas com CMC=3.0 (suspeito — CMC errado para estas cartas)

| Carta | CMC DB | CMC Real | Problema |
|:------|:------:|:--------:|:---------|
| Inventors' Fair | 3.0 | 0 (land) | Land tratada como spell |
| Prismatic Vista | 3.0 | 0 (land) | Land tratada como spell |
| Reforge the Soul | 3.0 | 5 (sorcery) | Miracle CMC alternativo confundiu o importador |

Estas 3 são as últimas remanescentes com `functional_tag='unknown'`.

---

## 4. ✅ Bulk Import Partial Recovery — 17/20 Cartas Reclassificadas

### O que mudou

O deck "Lorehold Best-of Learned No Premium Mox 2026-06-02" (deck_id=6) tinha **20 cartas**
com `functional_tag='unknown'` no relatório anterior. Destas:

- **17 foram reclassificadas** com tags apropriadas: `ramp`, `draw`, `protection`, `removal`,
  `combo`, `wincon`, `stax`, `spellslinger`, `tutor`
- **3 continuam 'unknown'**: Inventors' Fair, Prismatic Vista, Reforge the Soul

### Distribuição de tags pós-reclassificação (deck 6)

| Tag | Count |
|:----|:-----:|
| land | 31 |
| ramp | 19 |
| wincon | 10 |
| protection | 10 |
| draw | 9 |
| tutor | 5 |
| unknown | 3 |
| removal | 3 |
| engine | 3 |
| combo | 3 |
| stax | 1 |
| spellslinger | 1 |
| commander | 1 |
| board_wipe | 1 |
| **Total** | **100** |

---

## 5. 🟡 NOVO: 4 Tags Sem Entrada em `tag_accuracy`

A reclassificação introduziu 4 novos valores de `functional_tag` que **não têm linha correspondente**
na tabela `tag_accuracy`:

| Tag | Cartas no deck 6 | tag_accuracy entry? | Precisão conhecida? |
|:----|:----------------:|:-------------------:|:-------------------:|
| `stax` | 1 | ❌ | ❌ Desconhecida |
| `combo` | 3 | ❌ | ❌ Desconhecida |
| `commander` | 1 | ❌ | ❌ Desconhecida |
| `spellslinger` | 1 | ❌ | ❌ Desconhecida |

> `tag_accuracy` cobre apenas 22 tags. Qualquer classificação que produza estas novas tags
> opera sem métrica de precisão — não sabemos se estão corretas ou erradas.

**Query de verificação:**
```sql
SELECT DISTINCT dc.functional_tag FROM deck_cards dc
WHERE dc.functional_tag NOT IN (
    SELECT tag_name FROM tag_accuracy
) AND dc.functional_tag IS NOT NULL;
```

---

## 6. Mudanças nos Sinais de Erro

### 6.1 No Multi-Tag: 124 → 128 (+4)

Quatro cartas a mais agora não possuem entradas em `card_tags`. A maior concentração está
no deck 6 (64 cartas sem multi-tag). O `card_tags` não foi populado junto com a reclassificação
do `functional_tag` — são pipelines separados.

### 6.2 Divergência Single vs Multi-Tag: Estável em 36

A divergência single vs multi permanece em 36 (6.6%). Para o deck 6 especificamente,
a divergência é **zero** — todas as cartas com `functional_tag` têm o mesmo tag via multi-tag.
Isso sugere que a reclassificação foi feita por um classificador unificado, não pelo antigo
dual-classifier que causava divergência.

### 6.3 Double-Null: Estável em 25

As 25 cartas double-null permanecem as mesmas, todas em decks EDHREC Average (Dimir Ninja,
Aesi, Kinnan, Default). Nenhuma double-null no deck Lorehold ativo.

### 6.4 Discrepâncias: Sem Alteração

21 discrepâncias documentadas. Nenhuma nova desde 2026-05-27. Nenhuma resolvida (todas `resolved=0`).

---

## 7. Recomendações de Código (Atualizadas)

### 7.1 🔴 CORRIGIR CMC na Reclassificação (NOVA)

**Problema:** Das 17 cartas reclassificadas, muitas ficaram com CMC=0.0. A reclassificação
corrigiu o `functional_tag` mas não preencheu o CMC com o valor real do oracle. **36 cartas
no deck 6 têm CMC inválido** — pior que as 20 originais.

**Arquivo provável:** `docs/hermes-analysis/manaloom-knowledge/scripts/import_lorehold_decks.py`
ou qualquer script de reclassificação (`reclassify_deck.py`).

**Ação:**
1. Buscar CMC real via Scryfall para TODAS as cartas do deck 6
2. `UPDATE deck_cards SET cmc = <real> WHERE deck_id = 6 AND (cmc IS NULL OR cmc = 0.0)`
3. Adicionar validação pós-reclassificação: se CMC permanece NULL/0.0 após classificação, ABORTAR

### 7.2 🔴 Adicionar Novas Tags ao `tag_accuracy` (NOVA)

**Problema:** `stax`, `combo`, `commander`, `spellslinger` existem como valores de
`functional_tag` no banco mas não têm entrada em `tag_accuracy`. A precisão destas
classificações é completamente desconhecida.

**Ação:**
1. Adicionar linhas em `tag_accuracy` para cada nova tag
2. Popular `correct_count` e `total_count` com amostragem das cartas existentes
3. Rodar `import_knowledge.py` se necessário para sincronizar

### 7.3 🔴 3 Cartas 'Unknown' Restantes — Classificador Cego (REITERADA — 2026-06-02)

**Problema:** Inventors' Fair, Prismatic Vista, Reforge the Soul continuam com
`functional_tag='unknown'`. Todas com CMC=3.0 (errado).

- **Inventors' Fair**: Land lendária — classificador não reconhece lands não-básicas com
  habilidade ativada complexa?
- **Prismatic Vista**: Fetch land — classificador pode estar confundindo com spell
  por causa do sacrifício?
- **Reforge the Soul**: Miracle com CMC alternativo — o classificador provavelmente
  confundiu o CMC de miracle com o CMC normal?

### 7.4 🔴 Ampliar Heurísticas Estratégicas (REITERADA — 3ª semana)

**Status:** Não implementada.
**Arquivos:** `server/lib/ai/optimization_functional_roles.dart` (L370-398), `functional_card_tags.dart` (L859-907), `scryfall_classifier.py` (L155-221)

Payoff a 35.5% e enabler a 50% continuam sendo as piores precisões. Nenhuma melhoria
na tabela `tag_accuracy` em 7 dias confirma que o classificador não está evoluindo.

### 7.5 🟡 Popular `false_positive` / `false_negative` (REITERADA — 3ª semana)

**Status:** Colunas continuam zeradas em todas as 22 tags. Sem rastreamento de erros.

### 7.6 🟡 Unificar Single-Tag e Multi-Tag (REITERADA — 3ª semana)

**Status:** Não implementada. A divergência entre classificadores persiste globalmente
(36 cartas), mas é zero no deck 6 — sugerindo que o classificador unificado foi usado
na reclassificação recente mas não nos decks mais antigos.

### 7.7 🟡 Pipeline `card_tags`: Sincronizar com Reclassificação

**Problema:** 64 cartas no deck 6 sem `card_tags` — o pipeline de multi-tag não foi
executado junto com a reclassificação do `functional_tag`. Se a reclassificação usou
um classificador unificado, o `card_tags` deveria ter sido populado simultaneamente.

---

## 8. Sumário Executivo

| Métrica | Valor | Mudança |
|:--------|:-----|:--------|
| Tags no sistema (`tag_accuracy`) | 22 | 0 |
| Tags com 100% de precisão | 15 (68%) | 0 |
| Tags abaixo de 85% | 7 (32%) | 0 |
| Pior precisão | **payoff (35.5%)** | 0 |
| **Novas tags sem `tag_accuracy`** | **4** 🔴 | **+4** |
| Cartas double-null | 25 (4.6%) | 0 |
| Divergência single vs multi tag | 36 (6.6%) | 0 |
| Cartas sem multi-tags | 128 (23.6%) | +4 |
| Cartas 'unknown' (classificador não rodou) | **3** 🟡 | **-17** |
| Cartas com CMC inválido (deck 6) | **36** 🔴 | **+~21** |
| fp/fn tracking implementado | NÃO | 0 |
| Discrepâncias documentadas | 21 | 0 |
| **Estagnação `tag_accuracy`** | **7 dias** | +1 dia |

### Conclusão

**Progresso parcial na reclassificação do deck 6:** 17 das 20 cartas `'unknown'` foram
reclassificadas. Porém a reclassificação foi **incompleta e bugada**:

1. **3 cartas continuam 'unknown'** — classificador cego para lands não-básicas e miracles
2. **36 cartas com CMC inválido** — a reclassificação zerou CMCs em vez de corrigi-los
3. **4 novas tags sem métrica de precisão** — `stax`, `combo`, `commander`, `spellslinger`
   existem no banco mas não em `tag_accuracy`
4. **64 cartas sem multi-tags** no deck 6 — `card_tags` não foi populado

**`tag_accuracy` ESTAGNADO há 7 dias.** O pipeline de avaliação de precisão das tags
não roda desde 2026-05-27. Sem ele, todas as recomendações de swap do Evolution Oracle
são baseadas em tags com precisão potencialmente baixa (payoff a 35.5%, enabler a 50%).

**Top 3 ações:**
1. 🔴 Corrigir CMCs no deck 6 — buscar oracle via Scryfall para as 36 cartas com CMC inválido
2. 🔴 Adicionar `stax`, `combo`, `commander`, `spellslinger` ao `tag_accuracy` com amostragem
3. 🔴 Rodar `tag_accuracy` update — está 7 dias sem atualização, a tabela é a única fonte de verdade sobre precisão das classificações
