# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: c620053be201649cce03d8cad546eb13 -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 53 Game Changers.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-07 (execução #9 — hash rotacionou por enriquecimento de conteúdo)
**Fonte:** `scripts/knowledge.db` (53/53 GCs preenchidos com `why_game_changer`)
**Detectados pelo ManaLoom:** 24/53 (45%) — **sem mudança desde execução #2**
**Não detectados:** 29/53 (55%)
**Hash DB estrutural:** `c620053be201649cce03d8cad546eb13` (rotacionou do hash anterior `f232206364f9cb96846041e19fe33929` — causa: enriquecimento de `why_game_changer` e `notes` em 5+ cartas)

---

## Resumo Executivo

A nona execução registra rotação de hash estrutural causada pelo **enriquecimento de conteúdo** em 5+ cartas (Rhystic Study, Smothering Tithe, Ad Nauseam, Cyclonic Rift, Thassa's Oracle). Os campos `why_game_changer` e `notes` foram expandidos com análises detalhadas incluindo dados de Scryfall API, EDHREC, bracket policy, e diagnósticos de detecção.

**Melhoria de qualidade:** 12 cartas agora têm flags de diagnóstico no campo `notes` (CATEGORY_GAP, NOT_DETECTED, FALSE_FLAG, MISSING), documentando explicitamente suas próprias lacunas. Isso não altera a detecção mas melhora a visibilidade dos gaps para consumidores do DB.

**As 12 lacunas estruturais documentadas desde a execução #7 persistem integralmente.** Duas novas observações emergem do enriquecimento:

| Tipo de Lacuna | Execução #8 | Execução #9 | Mudança |
|:---------------|:-----------:|:-----------:|:-------|
| Categoria incorreta (erro de classificação) | 12 | 12 | — |
| Falso positivo de detecção (`det=1` indevido) | 1 | 1 | — |
| Falso negativo de detecção (`det=0` com código) | 1 | 1 | — |
| Colapso de categoria `other` com `det=1` | 16 | 14 | 🟢 ↓2: Rhystic Study + Ad Nauseam movidos para `card_advantage`/`card_advantage_gap` |
| Schema dual (`impact_category` vs `bracket_category`) | 53 | 53 | — |
| Heurística de código faltando | 3 | 3 | — |
| GC com `oracle_text` vazio | 1 (`''`) | 1 (`''`) | — (Tergrid persiste) |
| GCs sem `price_usd` | 8 | 8 | — |
| 🆕 **Novos valores de `bracket_category`** | — | 2 | 🆕 `card_advantage`, `card_advantage_gap` (não-standards, sem heurística) |
| 🆕 **Flags de diagnóstico em `notes`** | — | 12 (23%) | 🆕 Qualidade de dados melhorada |

---

## 🆕 Nova Observação #1: `bracket_category` com Valores Não-Standard

Duas cartas tiveram seu `manaloom_bracket_category` alterado de `other` para valores semanticamente mais ricos, mas que **não correspondem a nenhuma heurística de detecção no código Dart**:

| Carta | `bracket_category` atual | `det` | Heurística de código |
|:------|:------------------------|:-----:|:---------------------|
| Rhystic Study | `card_advantage` | 0 | **Nenhuma** — `edh_bracket_policy.dart` não tem categoria `card_advantage` |
| Ad Nauseam | `card_advantage_gap` | 0 | **Nenhuma** — `edh_bracket_policy.dart` não tem categoria `card_advantage_gap` |

**Impacto:** 7/10. O enriquecimento melhorou a semântica (antes ambas eram `other`) mas criou valores que o código Dart não reconhece. Consumidores do DB podem interpretar `card_advantage` como uma categoria suportada quando na verdade o código é cego para ela.

**Risco:** 🟡 Médio. Os valores são mais informativos que `other`, mas o `det=0` continua correto — o código realmente não as detecta. O risco é de falsa expectativa: um consumidor vendo `bracket_category='card_advantage'` pode assumir que o sistema tem heurística para essa categoria.

---

## 🆕 Nova Observação #2: 12 Cartas com Flags de Diagnóstico em `notes`

O processo de enriquecimento adicionou auto-diagnósticos ao campo `notes`. Cartas agora documentam explicitamente por que não são detectadas:

| Carta | Flags no `notes` | Diagnóstico |
|:------|:-----------------|:------------|
| Rhystic Study | NOT_DETECTED, CATEGORY_GAP | "N detecta - sem categoria card_advantage" |
| Smothering Tithe | CATEGORY_GAP, FALSE_FLAG | "categoria faltante" + reconhece que `impact_category='fast_mana'` é incompleto |
| Cyclonic Rift | CATEGORY_GAP | "edh_bracket_policy.dart cobre fastMana, tutor, freeInteraction, extraTurns, infiniteCombo. Cyclonic Rift não se encaixa em nenhuma" |
| Fierce Guardianship | CATEGORY_GAP | Detectada por heurística mas DB mostra `det=0` |
| The One Ring | MISSING, CATEGORY_GAP | Dados de detecção ausentes |
| Consecrated Sphinx | CATEGORY_GAP | — |
| Drannith Magistrate | CATEGORY_GAP | — |
| Farewell | CATEGORY_GAP | — |
| Mishra's Workshop | CATEGORY_GAP | — |
| Necropotence | CATEGORY_GAP | — |
| Opposition Agent | CATEGORY_GAP | — |
| Serra's Sanctum | CATEGORY_GAP | — |
| Teferi's Protection | CATEGORY_GAP | — |

**Impacto:** 5/10 (positivo). Isso é uma melhoria de qualidade de dados — o DB agora é auto-consciente de suas lacunas. Consumidores podem usar `notes LIKE '%CATEGORY_GAP%'` para identificar rapidamente cartas não cobertas.

---

## Lacunas Detectadas (Top 12 — Estado Atual, confirmado execução #9)

### 🔴 Lacuna 1 (PERSISTE): 14 Cartas Detectadas com `bracket_category='other'` — Colapso de Categoria

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 14/53 (26%) — ↓2 desde execução #8 (Rhystic Study e Ad Nauseam reclassificados) |
| **Problema** | `manaloom_detected=1` mas `manaloom_bracket_category='other'` |
| **Impacto** | 8/10 — O campo `bracket_category` perdeu valor semântico para 26% dos GCs detectados |
| **Evidência** | 12 tutores + 2 combo pieces são detectados pelo bracket system mas registrados sem categoria |
| **Risco de falso positivo** | 🔴 Alto |
| **Possível regra futura** | Re-popular `manaloom_bracket_category` baseado na heurística: `search your library` → `tutor`, `without paying` → `freeInteraction`, `infiniteCombo list` → `infiniteCombo` |

**Detalhamento dos 14 (↓2 vs execução #8):**

| Grupo | Cartas | Heurística de Detecção | Categoria Esperada |
|:------|:-------|:----------------------|:-------------------|
| Tutores (12) | Demonic Tutor, Vampiric Tutor, Enlightened Tutor, Mystical Tutor, Worldly Tutor, Imperial Seal, Gamble, Intuition, Gifts Ungiven, Natural Order, Survival of the Fittest, Crop Rotation | `search your library` | `tutor` |
| Combo (2) | Thassa's Oracle, Underworld Breach | Lista `_knownInfiniteComboPieces` | `infiniteCombo` |

> 🟢 **Mudança desde #8:** Rhystic Study (`card_advantage`) e Ad Nauseam (`card_advantage_gap`) foram reclassificados de `other` para categorias semanticamente corretas. Bolas's Citadel e Force of Will continuam como `other` (foram classificadas como `freeInteraction` por heurística no código mas o DB mostra `other`).

---

### 🔴 Lacuna 2 (PERSISTE): Field of the Dead — Falso Positivo + Categoria Errada

| Campo | Valor |
|:------|:------|
| **Carta** | Field of the Dead |
| **Categoria atual** | `fastMana` |
| **Categoria sugerida** | `value_engine` |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=1`, `manaloom_bracket_category='fastMana'` |
| **Evidência** | Oracle: "enters the battlefield tapped. {T}: Add {C}. ...create a 2/2 black Zombie." NÃO está na lista curada de fastMana. Re-simulação confirma: NENHUMA heurística detecta. |
| **Risco de falso positivo** | 🔴 **Alto** |
| **Possível regra futura** | Corrigir `det=1 → 0` e `bracket_category='fastMana' → 'other'`. |

**Diagnóstico:** Persiste desde a execução #1. O `notes` não tem flag de diagnóstico (290 bytes, sem CATEGORY_GAP).

---

### 🔴 Lacuna 3 (PERSISTE): Underworld Breach — Falso Positivo de Detecção

| Campo | Valor |
|:------|:------|
| **Carta** | Underworld Breach |
| **Categoria** | `other` (bracket), `combo_piece` (impact) |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=1`, `manaloom_bracket_category='other'` |
| **Evidência** | NENHUMA das 5 heurísticas funcionais de bracket o detecta. Não está na lista `fastMana`, não tem `search your library`, `extra turn`, `rather than pay`, `without paying`, nem está em `_knownInfiniteComboPieces`. |
| **Risco de falso positivo** | 🔴 **Alto** |
| **Possível regra futura** | Adicionar à lista `_knownInfiniteComboPieces` em `edh_bracket_policy.dart`. |

---

### 🟡 Lacuna 4 (PERSISTE): Fierce Guardianship — Falso Negativo (DB Desatualizado)

| Campo | Valor |
|:------|:------|
| **Carta** | Fierce Guardianship |
| **Categoria** | `freeInteraction` (correta no bracket) |
| **Impacto** | 6/10 |
| **DB** | `manaloom_detected=0` (desatualizado), `manaloom_bracket_category='freeInteraction'` |
| **Código** | `det=1` — heurística `without paying` detecta |
| **Evidência** | Oracle: "If you control a commander, you may cast this spell without paying its mana cost." A re-simulação confirma: `without paying` → `freeInteraction`. |
| **Risco de falso positivo** | 🟢 Baixo — é correção de DB |
| **Possível regra futura** | Re-simular `tagCardForBracket()` e atualizar `det=0 → 1`. **Nota:** O `notes` já flag `CATEGORY_GAP`, confirmando auto-consciência do gap. |

---

### 🟡 Lacuna 5 (PERSISTE): Gaea's Cradle — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Gaea's Cradle |
| **Categoria** | `other` (bracket), `fast_mana` (impact) |
| **Impacto** | 9/10 |
| **DB** | `manaloom_detected=0` |
| **Evidência** | Oracle: "{T}: Add {G} for each creature you control." Terras com output variável não cobertas. |
| **Risco de falso positivo** | 🟢 Baixo |
| **Possível regra futura** | `if 'land' in type_line and '{T}: Add' in oracle and 'for each' in oracle → fast_mana_land` |

---

### 🟡 Lacuna 6 (PERSISTE): Serra's Sanctum — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Serra's Sanctum |
| **Categoria** | `other` (bracket), `fast_mana` (impact) |
| **Impacto** | 6/10 |
| **DB** | `manaloom_detected=0` |
| **Evidência** | "{T}: Add {W} for each enchantment you control." Mesmo padrão de Gaea's Cradle. |
| **Risco de falso positivo** | 🟢 Baixo |
| **Possível regra futura** | Mesma regra da Lacuna 5. **Nota:** `notes` já flag `CATEGORY_GAP`. |

---

### 🟡 Lacuna 7 (PERSISTE): Mishra's Workshop — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Mishra's Workshop |
| **Categoria** | `other` (bracket), `fast_mana` (impact) |
| **Impacto** | 6/10 |
| **DB** | `manaloom_detected=0` |
| **Evidência** | "{T}: Add {C}{C}{C}. Spend this mana only to cast artifact spells." 3+ mana de uma terra. |
| **Risco de falso positivo** | 🟡 Médio |
| **Possível regra futura** | `if 'land' in type_line and oracle has 3+ consecutive '{C}' in tap ability → fast_mana_land`. **Nota:** `notes` já flag `CATEGORY_GAP`. |

---

### Lacuna 8 (PERSISTE): Schema Dual — `impact_category` Desconectado do `manaloom_bracket_category`

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 53/53 (100%) |
| **Problema** | `impact_category` ≠ `manaloom_bracket_category` para TODAS as cartas |
| **Impacto** | 8/10 |
| **Evidência** | `impact_category` tem 10 valores. `manaloom_bracket_category` tem 7 valores (5 standards + `card_advantantage` + `card_advantage_gap`). Nenhuma carta tem valores iguais. |
| **Risco de falso positivo** | 🟡 Médio |
| **Possível regra futura** | Unificar ou documentar claramente a diferença entre classificação funcional (`impact_category`) e categoria de detecção (`manaloom_bracket_category`). |

---

### Lacuna 9 (PERSISTE): Categorias `card_advantage` Sem Heurística de Detecção

| Campo | Valor |
|:------|:------|
| **Cartas** | Rhystic Study (`card_advantage`), Ad Nauseam (`card_advantage_gap`), Notion Thief (`card_advantage`), The One Ring (`card_advantage`), Consecrated Sphinx (`value_engine`), Necropotence (`value_engine`) |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=0` para todas |
| **Evidência** | `edh_bracket_policy.dart` não tem heurística para draw engines ou card advantage. Rhystic Study: "whenever an opponent casts a spell, you may draw a card unless that player pays {1}." |
| **Risco de falso positivo** | 🟡 Médio |
| **Possível regra futura** | Adicionar heurística ou lista curada por nome. |

> 🆕 **Mudança desde #8:** Rhystic Study e Ad Nauseam agora têm `bracket_category` semanticamente correto (`card_advantage`, `card_advantage_gap`) ao invés de `other`. Mas `det=0` confirma que o código ainda não as detecta.

---

### 🟡 Lacuna 10 (PERSISTE): `impact_category` com Erros de Classificação Funcional

Cartas cujo `impact_category` não reflete sua função primária no formato:

| Carta | `impact_category` atual | Categoria sugerida | Justificativa |
|:------|:------------------------|:-------------------|:--------------|
| Opposition Agent | `fast_mana` | `stax` | Não gera mana — restringe bibliotecas |
| Smothering Tithe | `fast_mana` | `card_advantage` + `fast_mana` | Gera tesouros E card advantage condicional. **Nota:** O próprio `notes` (2022 bytes) flag `FALSE_FLAG` — a carta reconhece sua própria classificação incompleta. |
| Farewell | `value_engine` | `board_wipe` | Board wipe flexível, não geração contínua de valor |
| Force of Will | `value_engine` | `free_interaction` | Free counterspell — o código Dart o detecta como `freeInteraction` |
| Field of the Dead | `fast_mana` | `value_engine` | Landfall token generator — terra entra TAPPED |

---

### 🟡 Lacuna 11 (PERSISTE): Tergrid — `oracle_text` Vazio Bloqueia Toda Heurística

| Campo | Valor |
|:------|:------|
| **Carta** | Tergrid, God of Fright // Tergrid's Lantern |
| **Problema** | `oracle_text` é string vazia (`''`) |
| **Impacto** | 8/10 |
| **DB** | `oracle_text=''`, `manaloom_detected=0`, `manaloom_bracket_category='other'` |
| **Evidência** | `oracle_text` vazio (len=0). O `why_game_changer` (483 bytes) e `notes` (295 bytes) estão preenchidos. Tergrid é invisível para heurísticas baseadas em oracle. |
| **Risco de falso positivo** | 🔴 **Alto** |
| **Possível regra futura** | Reimportar `oracle_text` via Scryfall API buscando "Tergrid, God of Fright" (face frontal, sem `//`). Verificar que o resultado NÃO é string vazia. |

---

### 🟡 Lacuna 12 (PERSISTE): 8 Cartas com `price_usd=NULL` — Dados de Mercado Incompletos

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 8/53 (15%) — Lion's Eye Diamond, Mishra's Workshop, Mox Diamond, Survival of the Fittest, The Tabernacle at Pendrell Vale, Glacial Chasm, Humility, Intuition |
| **Problema** | `price_usd IS NULL` — todas Reserved List |
| **Impacto** | 3/10 |
| **Risco de falso positivo** | 🟢 Baixo |
| **Possível regra futura** | Marcar como `RESERVED_LIST` ao invés de NULL. |

---

## Análise Cruzada: As 7 Categorias Faltantes no Bracket System

O `edh_bracket_policy.dart` atual cobre apenas 5 categorias + `gameChanger`. Para fechar o gap de 29/53 GCs não detectados, são necessárias **7 novas categorias funcionais**:

| Categoria Faltante | GCs Afetados | Heurística Proposta |
|:-------------------|:------------:|:--------------------|
| `card_advantage` | 5 (Rhystic, Tithe, Ring, Necropotence, Sphinx) | Trigger draw + opponent interaction |
| `board_wipe` | 2 (Cyclonic Rift, Farewell) | Mass bounce/exile + asymmetric |
| `stax` | 7 (Drannith, Opposition, Grand Arbiter, Braids, Humility, Glacial Chasm, Narset) | "can't" + "opponent" + restriction text |
| `value_engine` | 9 (Seedborn, Tergrid, Citadel, Aura Shards, Biorhythm, Coalition, Notion Thief, Bowmasters, Tabernacle) | Continuous/compounding value generation |
| `protection` | 1 (Teferi's Protection) | "protection from everything" / "phase out" |
| `free_interaction_flex` | 1 (Fierce Guardianship) | "without paying" + "if you control" + counter |
| `fast_mana_land` | 3 (Cradle, Sanctum, Workshop) | Land + tap for variable or 3+ mana |

---

## Distribuição de Categorias (Estado Atual — Execução #9)

### `manaloom_bracket_category` (7 valores, 40 = `other`)

| Categoria | Total | Detectados | Nota |
|:----------|:-----:|:----------:|:-----|
| `other` | 40 (75%) | 14 | ↓2 vs #8 (Rhystic + Ad Nauseam reclassificados) |
| `fastMana` | 7 (13%) | 7 | ✅ 100% detecção |
| `freeInteraction` | 2 (4%) | 1 | Fierce Guardianship = falso negativo |
| `card_advantage` | 1 (2%) | 0 | 🆕 Rhystic Study — sem heurística |
| `card_advantage_gap` | 1 (2%) | 0 | 🆕 Ad Nauseam — sem heurística |
| `extraTurns` | 1 (2%) | 1 | ✅ Panoptic Mirror |
| `infiniteCombo` | 1 (2%) | 1 | — (mas Thassa + Breach estão como `other`) |

### `impact_category` (10 valores)

| Categoria | Total | % |
|:----------|:-----:|:-:|
| `value_engine` | 17 | 32% |
| `fast_mana` | 13 | 25% |
| `tutor` | 12 | 23% |
| `card_advantage` | 4 | 8% |
| `free_interaction` | 2 | 4% |
| `combo_piece` | 2 | 4% |
| `board_wipe` | 1 | 2% |
| `stax` | 1 | 2% |
| `protection` | 1 | 2% |

---

## Métricas de Qualidade (Execução #9)

| Métrica | Valor | Tendência vs #8 |
|:--------|:-----:|:----------|
| GCs com `why_game_changer` preenchido | 53/53 (100%) | ✅ Estável |
| `why_game_changer` com < 20 chars | 0/53 (0%) | ✅ Estável |
| GCs enriquecidos (why > 800 chars) | 5/53 (9%) | 🆕 +5 — qualidade de dados melhorou |
| GCs com flags de diagnóstico em `notes` | 12/53 (23%) | 🆕 Nova feature |
| Falsos positivos (`det=1` sem heurística) | 3/53 (6%) | 🔴 +2: Field of the Dead + Underworld Breach + Force of Will |
| Falsos negativos (`det=0` com heurística) | 1/53 (2%) | → Fierce Guardianship persiste |
| `bracket_category='other'` com `det=1` | 14/53 (26%) | 🟢 ↓2 vs #8 |
| `bracket_category` não-standard (sem heurística) | 2/53 (4%) | 🆕 `card_advantage` + `card_advantage_gap` |
| `impact_category` com erro funcional | 5/53 (9%) | → 5 erros conhecidos persistem |
| Categorias faltantes no código Dart | 7 | → Sem mudança |
| `oracle_text` vazio (NULL ou `''`) | 1/53 (2%) | → Tergrid persiste |
| `price_usd IS NULL` | 8/53 (15%) | → Todas RL cards |

---

## Status por Categoria de Bracket

| Categoria | Total GCs | Detectados | DB diz `other` | Precisão do DB |
|:----------|:---------:|:----------:|:--------------:|:--------------|
| `fastMana` | 11 | 8 | 0 | 🟡 73% (3 lands não detectados) |
| `tutor` | 16 | 16 | 12 | 🔴 0% (todos colapsados para `other`) |
| `freeInteraction` | 2 | 1 | 0 | 🟡 50% (Fierce Guardianship falso negativo) |
| `extraTurns` | 1 | 1 | 0 | ✅ 100% |
| `infiniteCombo` | 5 | 3 | 2 | 🔴 40% (Thassa + Breach `other`) |
| `card_advantage` | 5 | 0 | 0 | 🔴 0% (heurística não existe) |
| `board_wipe` | 2 | 0 | 0 | 🔴 0% (heurística não existe) |
| `stax` | 7 | 0 | 0 | 🔴 0% (heurística não existe) |
| `value_engine` | 9 | 1 (Citadel) | 0 | 🔴 11% |
| `protection` | 1 | 0 | 0 | 🔴 0% (heurística não existe) |
| `fast_mana_land` | 3 | 0 | 0 | 🔴 0% (heurística não existe) |

---

## Conclusão

**Execução #9:** Hash estrutural rotacionou (`f23220...` → `c62005...`) devido ao enriquecimento de `why_game_changer` e `notes` em 5+ cartas. **Duas melhorias de qualidade de dados** emergem: (1) Rhystic Study e Ad Nauseam foram reclassificados de `other` para categorias semanticamente corretas (`card_advantage`, `card_advantage_gap`); (2) 12 cartas agora têm flags de diagnóstico em `notes` documentando suas próprias lacunas.

**Métricas de detecção permanecem inalteradas** (24/53 detectados, 45%). As 12 lacunas estruturais persistem integralmente. Duas novas observações foram registradas (valores não-standard de `bracket_category` e auto-diagnóstico em `notes`), mas não representam regressões.

**Próximos passos recomendados (externos ao cron):**
1. 🔴 Corrigir `det=1 → 0` e `bracket_category='fastMana' → 'other'` para Field of the Dead
2. Re-simular Fierce Guardianship: `det=0 → 1`
3. Re-popular `manaloom_bracket_category` para os 14 detectados com `other` baseado na heurística
4. Adicionar Underworld Breach à lista `_knownInfiniteComboPieces`
5. Corrigir 5 `impact_category` errados (Opposition Agent, Smothering Tithe, Farewell, Force of Will, Field of the Dead)
6. 🔴 **Reimportar `oracle_text` de Tergrid** — buscar Scryfall por "Tergrid, God of Fright" (sem `//`)
7. Distinguir `price_usd=NULL` como `RESERVED_LIST` para as 8 cartas afetadas
8. 🆕 Atualizar `edh_bracket_policy.dart` para reconhecer `card_advantage` e `card_advantage_gap` como categorias válidas (ou reverter para `other` se não houver heurística planejada)
9. 🆕 Aproveitar flags de diagnóstico em `notes` para queries de priorização de fixes

**O cron deve continuar em modo [SILENT] para execuções futuras enquanto o hash estrutural permanecer o mesmo.** Se o hash mudar (por razões não-cosméticas), reexecutar análise completa.
