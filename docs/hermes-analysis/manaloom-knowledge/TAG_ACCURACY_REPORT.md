# Tag Accuracy Report — 2026-06-07

**Generated:** 2026-06-07T23:30:00+00:00
**Source:** `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` → `tag_accuracy`, `deck_cards`, `card_tags`, `discrepancies`
**Previous report:** 2026-06-05
**Schema:** 22 tags in `tag_accuracy` (unchanged since 2026-05-27 — **11 days stale**)

---

## 1. Mudanças desde o Último Relatório (2026-06-05 → 2026-06-07)

| Métrica | 2026-06-05 | 2026-06-07 | Delta |
|:--------|:----------:|:----------:|:-----:|
| `tag_accuracy` rows | 22 | 22 | 0 |
| `tag_accuracy` last_updated | 2026-05-27 | **2026-05-27** | **Nenhuma (11 dias)** |
| Discrepancies | 21 | 21 | 0 |
| `deck_cards` total | 543 | 543 | 0 |
| Decks | 8 | 8 | 0 |
| `functional_tag = 'unknown'` | 3 | 3 | 0 |
| `functional_tag IS NULL` | 32 | 32 | 0 |
| Double-null cards | 26 (4.8%) | 26 (4.8%) | 0 |
| Cards without multi-tag | 112 (20.6%) | **113 (20.8%)** | **+1** |
| Cards with `CMC = 0.0` (all decks) | 142 (26.2%) | 142 (26.2%) | 0 |
| New tags NOT in `tag_accuracy` | 12 | 12 | 0 |
| Legacy tags ORPHANED | 5 | 5 | 0 |
| Divergência func vs multi | 255 | **256** | **+1** |

> **Conclusão:** Mudanças mínimas. Duas cartas foram reclassificadas de `protection` → `engine` (correção parcial do colapso de engine). Apenas +1 carta perdeu cobertura multi-tag e +1 nova divergência. `tag_accuracy` continua estagnado (11 dias), CMC corruption inalterado (142 cartas), e fork do classificador ainda ativo.

---

## 2. 🔵 Recuperação Parcial da Tag `engine`: 1 → 3 Cartas

A tag `engine` (crítica para identificar o núcleo de valor do deck) estava em **colapso** no relatório anterior com apenas **1 carta** (Past in Flames). Duas cartas foram reclassificadas de `protection` para `engine`:

| Carta | Deck | Tag Anterior | Nova Tag | Correção? |
|:------|:-----|:-------------|:---------|:----------|
| Reiterate | 6 (Lorehold) | `protection` | `engine` | ✅ Correto — copy spell, engine de combo |
| Reverberate | 6 (Lorehold) | `protection` | `engine` | ✅ Correto — copy spell, engine de combo |

**Impacto:** `protection` caiu de 24 → **22 cartas**, `engine` subiu de 1 → **3 cartas**. Ambas as reclassificações são semanticamente corretas — cartas que copiam spells são engines, não proteção.

**Porém:** O `tag_accuracy` ainda reporta `engine` com precisão 75.0% (6/8) baseado em dados de 2026-05-27 — essa métrica é **irrelevante** para as 3 cartas atuais (foram classificadas pelo fork de tags finas, não pelo sistema legado).

---

## 3. Precisão Por Tag — Sistema Bifurcado (INALTERADO)

### 3.1 Tags Legadas

| Tag | Correto | Total | Precisão | Cartas no DB | Status |
|:----|:------:|:-----:|:--------:|:------------:|:------|
| **payoff** ⚠️ | 11 | 31 | 35.5% | **0** | Órfã |
| **combo_piece** ⚠️ | 1 | 2 | 50.0% | **0** | Órfã |
| **enabler** ⚠️ | 21 | 42 | 50.0% | **0** | Órfã |
| **other** ⚠️ | 1 | 2 | 50.0% | **0** | Órfã |
| **finisher** ⚠️ | 2 | 2 | 100.0% | **0** | Órfã |
| **protection** | 9 | 13 | 69.2% 🔴 | **22** (-2) | Alto |
| **wincon** | 6 | 8 | 75.0% 🟡 | 10 | Médio-Alto |
| **engine** | 6 | 8 | 75.0% 🟡 | **3** (+2) | Recuperando |
| land | 87 | 87 | 100.0% | 127 | Baixo |
| ramp | 53 | 53 | 100.0% | 98 | Baixo |
| draw | 32 | 32 | 100.0% | 54 | Baixo |
| removal | 30 | 30 | 100.0% | 39 | Baixo |
| utility | 76 | 76 | 100.0% | 8 | Baixo |
| creature | 22 | 22 | 100.0% | 52 | Baixo |
| tutor | 6 | 6 | 100.0% | 13 | Baixo |
| board_wipe | 3 | 3 | 100.0% | 2 | Baixo |
| recursion | 3 | 3 | 100.0% | 10 | Baixo |
| enchantment | 3 | 3 | 100.0% | 5 | Baixo |
| artifact | 2 | 2 | 100.0% | 2 | Baixo |
| planeswalker | 2 | 2 | 100.0% | 2 | Baixo |
| sacrifice_outlet | 1 | 1 | 100.0% | 5 | Baixo |
| wipe | 1 | 1 | 100.0% | 1 | Baixo |

⚠️ = Tag órfã: existe em `tag_accuracy` mas tem **0 cartas** com este `functional_tag` no banco.

### 3.2 🔴 12 Novas Tags Sem Precisão (INALTERADO)

Mesmo conjunto do relatório anterior — 57 cartas (10.5%) sem métrica:

| Tag | Cartas | Delta |
|:----|:------:|:-----:|
| token_maker | 16 | 0 |
| big_spell | 10 | 0 |
| aristocrat_payoff | 9 | 0 |
| graveyard_synergy | 5 | 0 |
| exile_value | 4 | 0 |
| drain | 3 | 0 |
| combo | 3 | 0 |
| stax | 1 | 0 |
| spellslinger | 1 | 0 |
| lifegain | 1 | 0 |
| enchantment_synergy | 1 | 0 |
| commander | 1 | 0 |

---

## 4. 🔴 CMC Corruption: 142 Cartas (INALTERADO)

Nenhuma mudança — todos os 7 decks com `CMC = 0.0` permanecem corrompidos.

| Deck | Cartas com CMC=0.0 | % do deck |
|:-----|:------------------:|:---------:|
| 6 (Lorehold) | 36 | 36.0% |
| 9 (Atraxa) | 29 | 31.9% |
| 7 (Boros) | 22 | 25.9% |
| 2 (Dimir Ninja) | 19 | 22.6% |
| 5 (Aesi) | 19 | 24.1% |
| 4 (EDHREC Default) | 15 | 18.8% |
| 1 (Kinnan) | 2 | 15.4% |
| **Total** | **142** | **26.2%** |

---

## 5. Sinais que Precisam Virar Teste

### 5.1 🔴 Teste de Regressão: `engine` Não Pode Ter < 3 Cartas em Deck Lorehold

O deck 6 (Lorehold) é um deck de spellslinger/storm — espera-se múltiplas engines. O colapso para 1 carta foi detectado pelo relatório anterior. A recuperação para 3 cartas é positiva, mas **não há teste que impeça o colapso de `engine`**.

**Recomendação:** Adicionar teste de sanidade em `server/lib/ai/optimization_functional_roles.dart` ou no script de validação que verifique:
- Deck spellslinger/storm deve ter ≥ 2 cartas com tag `engine`
- Nenhuma tag deve colapsar para 0 se tinha > 5 cartas na classificação anterior

**Arquivo provável:** `server/lib/ai/optimization_functional_roles.dart` L55-125

### 5.2 🔴 Teste de Regressão: CMC Nunca Pode Ser 0.0

142 cartas (26.2%) com `CMC = 0.0` é inaceitável. Adicionar guarda no importador:

**Arquivo provável:** `docs/hermes-analysis/manaloom-knowledge/scripts/scryfall_classifier.py` — função de importação ou `knowledge_db.py` L396 (gravação de deck_cards)

**Ação:** `assert cmc > 0.0 or card_type == 'Land'` antes de gravar em `deck_cards`.

### 5.3 🟡 Teste de Estagnação: `tag_accuracy` com > 7 Dias sem Update

11 dias sem atualização de `tag_accuracy`. Adicionar alerta no CRON_STATUS.md quando `MAX(last_updated) < now() - 7 days`.

### 5.4 🟡 Teste de Divergência: `functional_tag` vs `card_tags`

256 cartas com divergência (+1 desde último relatório). Criar query de monitoramento que alerte quando a divergência crescer > 5% entre relatórios.

---

## 6. Recomendações de Código (Reiteradas — Nenhuma Implementada)

### 6.1 🔴 P0: Unificar Classificador (MESMO STATUS)

**Problema:** `ciclo4_swaps.py` L91 e `parse_collection.py` L110 usam `infer_functional_card_tags()` direto, ignorando `_select_primary_role()`.

**Arquivos afetados:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/ciclo4_swaps.py` L91
- `docs/hermes-analysis/manaloom-knowledge/scripts/parse_collection.py` L110
- `docs/hermes-analysis/manaloom-knowledge/scripts/scryfall_classifier.py` L155 (classify_card — funciona)

**Ação:** Substituir chamadas diretas por `classify_card(card_data)`.

### 6.2 🔴 P0: Corrigir CMC para 142 Cartas (MESMO STATUS)

**Arquivo provável:** `docs/hermes-analysis/manaloom-knowledge/scripts/scryfall_classifier.py` — importador não está populando CMC ou está sobrescrevendo com 0.0.

### 6.3 🔴 P0: Adicionar 12 Novas Tags ao `tag_accuracy` (MESMO STATUS)

OU unificar classificador (6.1) e as tags finas desaparecerão do `functional_tag`.

### 6.4 🔴 P1: Reativar Pipeline `tag_accuracy` (11 Dias Estagnado — +2 Dias)

**Arquivo:** `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge_db.py` L269-278 (`_tag_accuracy_deltas`)

O pipeline não é executado há 11 dias. A tabela `tag_accuracy` é a única fonte de verdade sobre qualidade das classificações e está mapeando um sistema de tags que não é mais usado (5 tags órfãs).

---

## 7. Sumário Executivo

| Métrica | 2026-06-05 | 2026-06-07 | Mudança |
|:--------|:----------:|:----------:|:--------|
| Tags no sistema | 22 | 22 | 0 |
| Tags órfãs (0 cartas) | 5 🔴 | 5 🔴 | 0 |
| Tags abaixo de 85% (não-órfãs) | 4 | 4 | 0 |
| Novas tags sem `tag_accuracy` | 12 🔴 | 12 🔴 | 0 |
| Cartas com tag sem precisão | 57 (10.5%) | 57 (10.5%) | 0 |
| **Engine (tag colapsada)** | **1 carta** 🔴 | **3 cartas** 🟡 | **+2** ✅ |
| Protection (perdeu cartas) | 24 | **22** | **-2** |
| Cartas double-null | 26 (4.8%) | 26 (4.8%) | 0 |
| Cartas sem multi-tags | 112 (20.6%) | 113 (20.8%) | +1 |
| Divergência func vs multi | 255 | 256 | +1 |
| **Cartas com CMC = 0.0** | **142 (26.2%)** 🔴 | **142 (26.2%)** 🔴 | **0** |
| Decks afetados por CMC inválido | 7 de 8 | 7 de 8 | 0 |
| **Estagnação `tag_accuracy`** | **9 dias** 🔴 | **11 dias** 🔴 | **+2** |
| Fork classificador | ATIVO 🔴 | ATIVO 🔴 | 0 |

### Conclusão

**Mudança real detectada:** Duas cartas (Reiterate, Reverberate) foram reclassificadas de `protection` → `engine` no deck 6 (Lorehold). É uma correção semanticamente correta que começa a recuperar o colapso da tag `engine`.

**Sem progresso nos problemas estruturais:**
- Fork do classificador Python ainda ativo (12 tags sem métrica, 5 órfãs)
- CMC corruption em 142 cartas (26.2%) — zero mudança
- `tag_accuracy` agora 11 dias estagnado
- Nenhuma recomendação P0 implementada desde 2026-06-05

**Top 3 ações imediatas (inalteradas desde 2026-06-05):**
1. 🔴 Corrigir scripts para usar `classify_card()` em vez de `infer_functional_card_tags()` direto
2. 🔴 Corrigir CMC=0.0 para 142 cartas via Scryfall API
3. 🔴 Reativar pipeline `tag_accuracy` (11 dias parado)
