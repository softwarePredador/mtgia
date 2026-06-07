# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: b8eec60a471c0ac508e71ffc094b1d38 -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 53 Game Changers.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-07 (execução #10 — hash rotacionou por mudanças de categorização)
**Fonte:** `scripts/knowledge.db` (53/53 GCs preenchidos com `why_game_changer`)
**Detectados pelo ManaLoom:** 24/53 (45%) — **sem mudança desde execução #2**
**Não detectados:** 29/53 (55%)
**Hash DB estrutural:** `b8eec60a471c0ac508e71ffc094b1d38` (rotacionou do hash anterior `c620053be201649cce03d8cad546eb13` — causa: **3 cartas reclassificadas**: Bolas's Citadel, Force of Will, Panoptic Mirror)

---

## Resumo Executivo

A décima execução registra rotação de hash estrutural causada por **3 reclassificações de `bracket_category`** entre a execução #9 e #10:

| Carta | Bracket #9 | Bracket #10 | Tipo de Mudança |
|:------|:-----------|:------------|:----------------|
| Panoptic Mirror | `extraTurns` | `freeInteraction` | Reclassificação (tecnicamente correta pela heurística "without paying") |
| Force of Will | `freeInteraction` | `other` | 🔴 Regressão — era corretamente classificado como `freeInteraction` |
| Bolas's Citadel | `infiniteCombo` | `other` | 🔴 Regressão — era corretamente classificado como `infiniteCombo` |

**Impacto estrutural:** Duas categorias de bracket (`extraTurns`, `infiniteCombo`) agora têm **0 cartas** — das 5 categorias originais do `edh_bracket_policy.dart`, apenas 2 permanecem com cartas atribuídas (`fastMana`, `freeInteraction`). A categoria `tutor` também tem 0 cartas (os 12 tutores detectados estão todos colapsados em `other`).

**`detected=1 & bracket='other'` aumentou de 14 → 16** com a adição de Force of Will e Bolas's Citadel — cartas que antes tinham categorização correta e agora estão no "limbo semântico".

---

## 🆕 Nova Lacuna: Reclassificação Estrutural de 3 Cartas

### 🔴 Lacuna 13 (NOVA): `extraTurns` e `infiniteCombo` — Categorias de Bracket Vazias

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 2 categorias / 3 cartas reclassificadas |
| **Problema** | `extraTurns` (0 cartas), `infiniteCombo` (0 cartas), `tutor` (0 cartas) — 3 das 5 categorias originais vazias |
| **Impacto** | 8/10 — Erosão estrutural: o sistema de bracket perdeu categorização para 3 das 5 categorias funcionais |
| **Evidência** | Panoptic Mirror (`extraTurns` → `freeInteraction`), Force of Will (`freeInteraction` → `other`), Bolas's Citadel (`infiniteCombo` → `other`) |
| **Risco de falso positivo** | 🔴 Alto |
| **Possível regra futura** | Verificar por que o batch de update reclassificou 3 cartas simultaneamente. Restaurar categorias corretas e adicionar teste de regressão. |

**Detalhamento das 3 reclassificações:**

| Carta | Bracket Antigo | Bracket Novo | Análise |
|:------|:--------------|:-------------|:--------|
| **Force of Will** | `freeInteraction` ✅ | `other` ❌ | Oracle: "rather than pay this spell's mana cost" → deveria ser `freeInteraction`. Regressão. |
| **Bolas's Citadel** | `infiniteCombo` ✅ | `other` ❌ | Oracle: "pay life equal to its mana value rather than pay its mana cost" + combo com Top/Reservoir. Regressão. |
| **Panoptic Mirror** | `extraTurns` 🟡 | `freeInteraction` 🟡 | Oracle: "cast the copy without paying its mana cost". Tecnicamente correto pela heurística, mas perde semântica de extra turns. |

---

## Lacunas Detectadas (Top 15 — Estado Atual)

### 🔴 Lacuna 1 (ATUALIZADA): 16 Cartas Detectadas com `bracket_category='other'` — Colapso de Categoria

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 16/53 (30%) — ↑2 desde execução #9 (Force of Will + Bolas's Citadel reclassificados) |
| **Problema** | `manaloom_detected=1` mas `manaloom_bracket_category='other'` |
| **Impacto** | 8/10 — O campo `bracket_category` perdeu valor semântico para 30% dos GCs detectados |
| **Evidência** | 12 tutores + 2 combo pieces + 2 recém-colapsados são detectados pelo bracket system mas registrados sem categoria |
| **Risco de falso positivo** | 🔴 Alto |
| **Possível regra futura** | Re-popular `manaloom_bracket_category` baseado na heurística: `search your library` → `tutor`, `rather than pay` → `freeInteraction`, `infiniteCombo list` → `infiniteCombo` |

**Detalhamento dos 16 (↑2 vs execução #9):**

| Grupo | Cartas | Heurística de Detecção | Categoria Esperada |
|:------|:-------|:----------------------|:-------------------|
| Tutores (12) | Demonic Tutor, Vampiric Tutor, Enlightened Tutor, Mystical Tutor, Worldly Tutor, Imperial Seal, Gamble, Intuition, Gifts Ungiven, Natural Order, Survival of the Fittest, Crop Rotation | `search your library` | `tutor` |
| Combo (2) | Thassa's Oracle, Underworld Breach | Lista `_knownInfiniteComboPieces` | `infiniteCombo` |
| 🆕 Free Interaction (1) | **Force of Will** | `rather than pay` → `freeInteraction` (regrediu de `freeInteraction` para `other`) | `freeInteraction` |
| 🆕 Combo Engine (1) | **Bolas's Citadel** | `rather than pay` + combo piece (regrediu de `infiniteCombo` para `other`) | `infiniteCombo` |

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
| **Possível regra futura** | Re-simular `tagCardForBracket()` e atualizar `det=0 → 1`. |

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
| **Possível regra futura** | Mesma regra da Lacuna 5. |

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
| **Possível regra futura** | `if 'land' in type_line and oracle has 3+ consecutive '{C}' in tap ability → fast_mana_land`. |

---

### Lacuna 8 (PERSISTE): Schema Dual — `impact_category` Desconectado do `manaloom_bracket_category`

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 53/53 (100%) |
| **Problema** | `impact_category` ≠ `manaloom_bracket_category` para TODAS as cartas |
| **Impacto** | 8/10 |
| **Evidência** | `impact_category` tem 10 valores. `manaloom_bracket_category` tem 5 valores (2 standards + `card_advantage` + `card_advantage_gap` + `other`). Nenhuma carta tem valores iguais. |
| **Risco de falso positivo** | 🟡 Médio |
| **Possível regra futura** | Unificar ou documentar claramente a diferença entre classificação funcional (`impact_category`) e categoria de detecção (`manaloom_bracket_category`). |

---

### Lacuna 9 (PERSISTE): Categorias `card_advantage` Sem Heurística de Detecção

| Campo | Valor |
|:------|:------|
| **Cartas** | Rhystic Study (`card_advantage`), Ad Nauseam (`card_advantage_gap`), Notion Thief (`card_advantage`), The One Ring (`card_advantage`), Consecrated Sphinx (`value_engine`), Necropotence (`value_engine`) |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=0` para todas |
| **Evidência** | `edh_bracket_policy.dart` não tem heurística para draw engines ou card advantage. |
| **Risco de falso positivo** | 🟡 Médio |
| **Possível regra futura** | Adicionar heurística ou lista curada por nome. |

---

### 🟡 Lacuna 10 (PERSISTE): `impact_category` com Erros de Classificação Funcional

Cartas cujo `impact_category` não reflete sua função primária no formato:

| Carta | `impact_category` atual | Categoria sugerida | Justificativa |
|:------|:------------------------|:-------------------|:--------------|
| Opposition Agent | `fast_mana` | `stax` | Não gera mana — restringe bibliotecas |
| Smothering Tithe | `fast_mana` | `card_advantage` | Gera tesouros E card advantage condicional |
| Farewell | `value_engine` | `board_wipe` | Board wipe flexível, não geração contínua de valor |
| Force of Will | `value_engine` | `free_interaction` | Free counterspell |
| Field of the Dead | `fast_mana` | `value_engine` | Landfall token generator — terra entra TAPPED |

---

### 🟡 Lacuna 11 (PERSISTE): Tergrid — `oracle_text` Vazio Bloqueia Toda Heurística

| Campo | Valor |
|:------|:------|
| **Carta** | Tergrid, God of Fright // Tergrid's Lantern |
| **Problema** | `oracle_text` é string vazia (`''`) |
| **Impacto** | 8/10 |
| **DB** | `oracle_text=''`, `manaloom_detected=0`, `manaloom_bracket_category='other'` |
| **Evidência** | `oracle_text` vazio (len=0). Tergrid é invisível para heurísticas baseadas em oracle. |
| **Risco de falso positivo** | 🔴 **Alto** |
| **Possível regra futura** | Reimportar `oracle_text` via Scryfall API buscando "Tergrid, God of Fright" (face frontal, sem `//`). |

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

### 🔴 Lacuna 13 (NOVA): `extraTurns`, `infiniteCombo`, `tutor` — Categorias de Bracket Vazias

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 3 categorias / 0 cartas cada |
| **Problema** | Três das cinco categorias originais do `edh_bracket_policy.dart` estão vazias: `extraTurns` (0), `infiniteCombo` (0), `tutor` (0) |
| **Impacto** | 9/10 — Erosão estrutural severa. O sistema de bracket categorizava 5 tipos funcionais; agora só 2 têm cartas (`fastMana`, `freeInteraction`) |
| **Evidência** | `SELECT COUNT(*) FROM game_changers WHERE manaloom_bracket_category IN ('extraTurns','infiniteCombo','tutor')` = 0 |
| **Risco de falso positivo** | 🔴 **Alto** — Consumidores do DB não conseguem filtrar GCs por tipo funcional |
| **Possível regra futura** | 1) Identificar o batch/migration que reclassificou as cartas. 2) Restaurar categorias: Force of Will → `freeInteraction`, Bolas's Citadel → `infiniteCombo`, Panoptic Mirror → `extraTurns`. 3) Re-popular 12 tutores: `other` → `tutor`. |

---

### 🔴 Lacuna 14 (NOVA): Force of Will — Regressão de `freeInteraction` para `other`

| Campo | Valor |
|:------|:------|
| **Carta** | Force of Will |
| **Bracket #9** | `freeInteraction` ✅ |
| **Bracket #10** | `other` ❌ |
| **Impacto** | 8/10 |
| **DB** | `manaloom_detected=1`, `manaloom_bracket_category='other'` |
| **Evidência** | Oracle: "You may pay 1 life and exile a blue card from your hand **rather than pay** this spell's mana cost. Counter target spell." A heurística `rather than pay` → `freeInteraction` o detecta corretamente. O `notes` confirma: "ManaLoom: detectado como freeInteraction." |
| **Risco de falso positivo** | 🔴 **Alto** — A detecção está correta (`det=1`) mas a categoria foi perdida |
| **Possível regra futura** | Restaurar `bracket_category` de `other` para `freeInteraction`. Investigar qual processo reclassificou a carta. |

---

### 🔴 Lacuna 15 (NOVA): Bolas's Citadel — Regressão de `infiniteCombo` para `other`

| Campo | Valor |
|:------|:------|
| **Carta** | Bolas's Citadel |
| **Bracket #9** | `infiniteCombo` ✅ |
| **Bracket #10** | `other` ❌ |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=1`, `manaloom_bracket_category='other'` |
| **Evidência** | Oracle: "pay life equal to its mana value **rather than pay** its mana cost" + forma combo infinito com Sensei's Divining Top + Aetherflux Reservoir. O `notes` confirma detecção como card_advantage. |
| **Risco de falso positivo** | 🔴 **Alto** — A detecção está correta (`det=1`) mas a categoria foi perdida |
| **Possível regra futura** | Restaurar `bracket_category` de `other` para `infiniteCombo`. Ou classificar como `freeInteraction` (já que o oracle tem "rather than pay"). |

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

## Distribuição de Categorias (Estado Atual — Execução #10)

### `manaloom_bracket_category` (5 valores, 42 = `other`)

| Categoria | Total | Detectados | Nota |
|:----------|:-----:|:----------:|:-----|
| `other` | 42 (79%) | 16 | ↑2 vs #9 (Force of Will + Bolas's Citadel) |
| `fastMana` | 7 (13%) | 7 | ✅ 100% detecção |
| `freeInteraction` | 2 (4%) | 1 | 🔄 Panoptic Mirror entrou, Force of Will saiu |
| `card_advantage` | 1 (2%) | 0 | Rhystic Study — sem heurística |
| `card_advantage_gap` | 1 (2%) | 0 | Ad Nauseam — sem heurística |
| ~~`extraTurns`~~ | **0** | — | ❌ Vazio (Panoptic Mirror → `freeInteraction`) |
| ~~`infiniteCombo`~~ | **0** | — | ❌ Vazio (Bolas's Citadel → `other`) |
| ~~`tutor`~~ | **0** | — | ❌ Vazio (12 tutores → `other`) |

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

## Métricas de Qualidade (Execução #10)

| Métrica | Valor | Tendência vs #9 |
|:--------|:-----:|:----------|
| GCs com `why_game_changer` preenchido | 53/53 (100%) | ✅ Estável |
| `why_game_changer` com < 20 chars | 0/53 (0%) | ✅ Estável |
| GCs com flags de diagnóstico em `notes` | 53/53 (100%) | ✅ Estável (todos têm notes) |
| Falsos positivos (`det=1` sem heurística) | 3/53 (6%) | → Field of the Dead + Underworld Breach + Bolas's Citadel |
| Falsos negativos (`det=0` com heurística) | 1/53 (2%) | → Fierce Guardianship persiste |
| `bracket_category='other'` com `det=1` | 16/53 (30%) | 🔴 ↑2 vs #9 (Force of Will + Bolas's Citadel regrediram) |
| `bracket_category` não-standard (sem heurística) | 2/53 (4%) | → `card_advantage` + `card_advantage_gap` |
| `impact_category` com erro funcional | 5/53 (9%) | → 5 erros conhecidos persistem |
| Categorias faltantes no código Dart | 7 | → Sem mudança |
| `oracle_text` vazio (NULL ou `''`) | 1/53 (2%) | → Tergrid persiste |
| `price_usd IS NULL` | 8/53 (15%) | → Todas RL cards |
| 🆕 Categorias de bracket vazias | 3/5 (60%) | 🔴 `extraTurns`, `infiniteCombo`, `tutor` = 0 cartas |

---

## Status por Categoria de Bracket

| Categoria | Total GCs | Detectados | DB diz `other` | Precisão do DB |
|:----------|:---------:|:----------:|:--------------:|:--------------|
| `fastMana` | 11 | 8 | 0 | 🟡 73% (3 lands não detectados) |
| `tutor` | 16 | 16 | 12 | 🔴 0% (todos colapsados para `other`) |
| `freeInteraction` | 2 | 1 | 0 | 🟡 50% (Fierce Guardianship falso negativo) |
| `extraTurns` | 1 | 1 | 0 | 🟡 Reclassificado para `freeInteraction` |
| `infiniteCombo` | 5 | 3 | 3 | 🔴 20% (Thassa + Breach + Bolas's → `other`) |
| `card_advantage` | 5 | 0 | 0 | 🔴 0% (heurística não existe) |
| `board_wipe` | 2 | 0 | 0 | 🔴 0% (heurística não existe) |
| `stax` | 7 | 0 | 0 | 🔴 0% (heurística não existe) |
| `value_engine` | 9 | 1 (Citadel) | 1 | 🔴 11% |
| `protection` | 1 | 0 | 0 | 🔴 0% (heurística não existe) |
| `fast_mana_land` | 3 | 0 | 0 | 🔴 0% (heurística não existe) |

---

## Conclusão

**Execução #10:** Hash estrutural rotacionou (`c62005...` → `b8eec6...`) devido a **3 reclassificações de `bracket_category`**: Force of Will (`freeInteraction` → `other`), Bolas's Citadel (`infiniteCombo` → `other`), e Panoptic Mirror (`extraTurns` → `freeInteraction`). **Duas destas são regressões** — Force of Will e Bolas's Citadel perderam categorização correta e foram colapsadas para `other`.

**A gravidade do colapso aumentou:** `detected=1 & bracket='other'` passou de 14 para 16 cartas. Três das cinco categorias originais de bracket (`tutor`, `extraTurns`, `infiniteCombo`) agora têm **zero cartas** atribuídas — o sistema perdeu a capacidade de distinguir 88% dos GCs detectados por tipo funcional.

**Métricas de detecção permanecem inalteradas** (24/53 detectados, 45%). As 12 lacunas anteriores persistem. Três novas lacunas foram identificadas (Lacunas 13-15) documentando as regressões de categorização.

**Próximos passos recomendados (externos ao cron):**
1. 🔴 **Restaurar `bracket_category` de Force of Will: `other` → `freeInteraction`**
2. 🔴 **Restaurar `bracket_category` de Bolas's Citadel: `other` → `infiniteCombo`**
3. 🟡 **Restaurar `bracket_category` de Panoptic Mirror: `freeInteraction` → `extraTurns`** (ou manter `freeInteraction` se for intencional)
4. 🔴 **Re-popular `bracket_category` para os 12 tutores detectados: `other` → `tutor`**
5. 🔴 Corrigir `det=1 → 0` e `bracket_category='fastMana' → 'other'` para Field of the Dead
6. Re-simular Fierce Guardianship: `det=0 → 1`
7. Corrigir 5 `impact_category` errados (Opposition Agent, Smothering Tithe, Farewell, Force of Will, Field of the Dead)
8. 🔴 **Reimportar `oracle_text` de Tergrid** — buscar Scryfall por "Tergrid, God of Fright" (sem `//`)
9. Distinguir `price_usd=NULL` como `RESERVED_LIST` para as 8 cartas afetadas
10. 🔴 **Investigar o processo/migration que reclassificou 3 cartas simultaneamente** — adicionar teste de regressão
11. 🆕 Adicionar trigger/validação para detectar quando todas as categorias de bracket padrão ficam vazias

**O cron deve continuar em modo [SILENT] para execuções futuras enquanto o hash estrutural permanecer o mesmo.** Se o hash mudar (por razões não-cosméticas), reexecutar análise completa.
