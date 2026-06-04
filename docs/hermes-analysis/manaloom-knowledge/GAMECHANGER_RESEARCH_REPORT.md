# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: f3dc2786f88e7ef04e179207bc2c0d66 -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 53 Game Changers.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-04 (execução #4 — reconfirmação, sem mudanças vs #3)
**Fonte:** `scripts/knowledge.db` (53/53 GCs preenchidos com `why_game_changer`)
**Detectados pelo ManaLoom:** 24/53 (45%) — **sem mudança desde execução #2**
**Não detectados:** 29/53 (55%) → 26 efetivamente não-detectados + 2 falsos positivos + 1 falso negativo
**Hash DB:** `f3dc2786f88e7ef04e179207bc2c0d66` (idêntico à execução #3)

---

## Resumo Executivo

A terceira execução revelou uma **transformação de schema no SQLite**: o campo `manaloom_bracket_category` foi semi-normalizado, com 42/53 cartas (79%) colapsadas para `other`, enquanto o campo `impact_category` preserva a categorização funcional rica (11 categorias distintas). Esta dualidade de colunas criou **novos problemas de qualidade de dados** que não existiam nas execuções anteriores.

| Tipo de Lacuna | Execução #2 | Execução #3 | Mudança |
|:---------------|:-----------:|:-----------:|:-------|
| Categoria incorreta (erro de classificação) | 5 | **12** | 🔴 +7 (tutores migraram para `other`) |
| Falso positivo de detecção (`det=1` indevido) | 2 | 2 | — (Field of the Dead, Underworld Breach persistem) |
| Falso negativo de detecção (`det=0` com código) | 1 | 1 | — (Fierce Guardianship persiste) |
| Colapso de categoria `other` com `det=1` | 0 | **16** | 🆕 NOVO — 12 tutores + 2 combo + 2 value_engine |
| Schema dual (`impact_category` vs `bracket_category`) | 0 | **53** | 🆕 NOVO — todas as 53 cartas têm divergência |
| Heurística de código faltando | 3 | 3 | — (fast mana lands persistem) |

**🆕 Principais novidades desta execução (vs relatório 2026-06-01 #2):**

1. **🆕 Colapso `manaloom_bracket_category='other'` para 42/53 cartas (79%)** — o campo perdeu a categorização funcional para 79% dos GCs. Na execução #2, apenas ~25 cartas tinham categoria `other`. Agora são 42. Isso inclui 16 cartas que SÃO detectadas pelo bracket system (`det=1`) mas estão registradas como `other`.

2. **🆕 12 tutores com `det=1` mas `bracket_category='other'`** — Demonic Tutor, Vampiric Tutor, Enlightened Tutor, Mystical Tutor, Worldly Tutor, Imperial Seal, Gamble, Intuition, Gifts Ungiven, Natural Order, Survival of the Fittest, Crop Rotation. Essas cartas são corretamente detectadas pela heurística `search your library` do código Dart, mas o DB as registra como `other` em vez de `tutor`. Isso torna o campo `manaloom_bracket_category` **não confiável** como sinal de classificação.

3. **🆕 Schema dual: `impact_category` ≠ `manaloom_bracket_category` em 53/53 cartas (100%)** — NENHUMA carta tem valores iguais nos dois campos. O campo `impact_category` preserva categorização funcional rica (11 valores: `value_engine`, `fast_mana`, `tutor`, `card_advantage`, `free_interaction`, `combo_piece`, `stax`, `protection`, `board_wipe`) enquanto `manaloom_bracket_category` está limitado a 5 valores + `other`. Esta divergência indica uma evolução de schema incompleta — o `impact_category` é semanticamente mais rico mas não é usado no pipeline de detecção.

4. **🆕 3 cartas migraram de "não-detectadas" para "detectadas mas com categoria errada"** — Force of Will, Bolas's Citadel e os 12 tutores agora têm `det=1` (detecção funciona) mas `bracket_category='other'` (categoria não reflete a heurística que os detectou).

---

## Lacunas Detectadas (Top 10 — Estado Atual)

### 🆕 Lacuna 1 (NOVA): 16 Cartas Detectadas com `bracket_category='other'` — Colapso de Categoria

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 16/53 (30%) |
| **Problema** | `manaloom_detected=1` mas `manaloom_bracket_category='other'` |
| **Impacto** | 9/10 — O campo `bracket_category` perdeu valor semântico para 30% dos GCs detectados |
| **Evidência** | 12 tutores + 2 combo pieces + 2 value engines são detectados pelo bracket system mas registrados sem categoria |
| **Risco de falso positivo** | 🔴 Alto — consumidores do DB (`bracket_category`) recebem `other` quando deveriam receber `tutor`, `combo_piece`, ou `free_interaction` |
| **Possível regra futura** | Re-popular `manaloom_bracket_category` baseado na heurística que gerou `det=1`: `search your library` → `tutor`, `rather than pay`/`without paying` → `freeInteraction`, `extra turn` → `extraTurns`, `infiniteCombo list` → `infiniteCombo`, `fastMana list` → `fastMana` |

**Detalhamento dos 16:**

| Grupo | Cartas | Heurística de Detecção | Categoria Esperada |
|:------|:-------|:----------------------|:-------------------|
| Tutores (12) | Demonic Tutor, Vampiric Tutor, Enlightened Tutor, Mystical Tutor, Worldly Tutor, Imperial Seal, Gamble, Intuition, Gifts Ungiven, Natural Order, Survival of the Fittest, Crop Rotation | `search your library` | `tutor` |
| Combo (2) | Thassa's Oracle, Underworld Breach | Lista `_knownInfiniteComboPieces` | `infiniteCombo` |
| Value/Free (2) | Bolas's Citadel, Force of Will | `rather than pay` / `without paying` | `freeInteraction` |

---

### 🔴 Lacuna 2 (PERSISTE): Field of the Dead — Falso Positivo + Categoria Errada

| Campo | Valor |
|:------|:------|
| **Carta** | Field of the Dead |
| **Categoria atual** | `fastMana` |
| **Categoria sugerida** | `value_engine` |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=1`, `manaloom_bracket_category='fastMana'` |
| **Evidência** | Oracle: "enters tapped. {T}: Add {C}. ...create a 2/2 black Zombie." NÃO está na lista curada de fastMana. NÃO contém `search your library`, `extra turn`, `rather than pay`, `without paying`, nem está em `_knownInfiniteComboPieces`. |
| **Risco de falso positivo** | 🔴 **Alto** — `det=1` mascara o gap de que a categoria `value_engine` não existe no bracket system. |
| **Possível regra futura** | Corrigir `det=1 → 0` e `bracket_category='fastMana' → 'other'`. Criar categoria `value_engine` para detectar landfall token generators. |

**Diagnóstico:** Persiste desde a execução #1. O oracle não corresponde a NENHUMA heurística de detecção. A terra entra TAPPED — é o oposto de fast mana. O `det=1` é um falso positivo que mascara a necessidade da categoria `value_engine`.

---

### 🔴 Lacuna 3 (PERSISTE): Underworld Breach — Falso Positivo de Detecção

| Campo | Valor |
|:------|:------|
| **Carta** | Underworld Breach |
| **Categoria** | `other` (bracket), `combo_piece` (impact) |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=1`, `manaloom_bracket_category='other'` |
| **Evidência** | Simulação confirma: NENHUMA das 5 heurísticas funcionais de bracket o detecta. Não está na lista `fastMana`, não tem `search your library`, `extra turn`, `rather than pay`, `without paying`, nem está em `_knownInfiniteComboPieces` (que contém apenas Thassa's Oracle, Demonic Consultation, Tainted Pact). |
| **Risco de falso positivo** | 🔴 **Alto** — `det=1` mascara o fato de que o bracket system é cego para uma das peças de combo mais importantes do cEDH. |
| **Possível regra futura** | Adicionar à lista `_knownInfiniteComboPieces` em `edh_bracket_policy.dart`. Ou heurística: `if 'escape' in oracle and 'graveyard' in oracle → combo_piece`. |

---

### 🟡 Lacuna 4 (PERSISTE): Fierce Guardianship — Falso Negativo (DB Desatualizado)

| Campo | Valor |
|:------|:------|
| **Carta** | Fierce Guardianship |
| **Categoria** | `freeInteraction` (correta no bracket) |
| **Impacto** | 6/10 |
| **DB** | `manaloom_detected=0` (desatualizado) |
| **Código** | `det=1` — heurística `without paying` na linha 130 detecta |
| **Evidência** | Oracle: "If you control a commander, you may cast this spell without paying its mana cost." O código Dart contém `if (o.contains('without paying'))` que detecta corretamente. O DB não foi re-simulado. |
| **Risco de falso positivo** | 🟢 Baixo — é correção de DB, não de código. |
| **Possível regra futura** | Re-simular `tagCardForBracket()` e atualizar `det=0 → 1`. |

---

### 🟡 Lacuna 5 (PERSISTE): Gaea's Cradle — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Gaea's Cradle |
| **Categoria** | `other` (bracket), `fast_mana` (impact) |
| **Impacto** | 9/10 |
| **DB** | `manaloom_detected=0` |
| **Evidência** | Oracle: "{T}: Add {G} for each creature you control." A lista curada de fastMana contém apenas artefatos. Terras com output variável não são cobertas. |
| **Risco de falso positivo** | 🟢 Baixo — `{T}: Add {X} for each` é padrão claro. |
| **Possível regra futura** | `if 'land' in type_line and '{T}: Add' in oracle and 'for each' in oracle → fast_mana_land` |

---

### 🟡 Lacuna 6 (PERSISTE): Serra's Sanctum — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Serra's Sanctum |
| **Categoria** | `other` (bracket), `fast_mana` (impact) |
| **Impacto** | 6/10 |
| **DB** | `manaloom_detected=0` |
| **Evidência** | Mesmo padrão de Gaea's Cradle: "{T}: Add {W} for each enchantment you control." |
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
| **Evidência** | "{T}: Add {C}{C}{C}. Spend this mana only to cast artifact spells." |
| **Risco de falso positivo** | 🟡 Médio — padrão diferente de Cradle/Sanctum, mas ainda é terra que produz 3+ mana. |
| **Possível regra futura** | `if 'land' in type_line and oracle has 3+ consecutive '{C}' in tap ability → fast_mana_land` |

---

### 🆕 Lacuna 8 (NOVA): Schema Dual — `impact_category` Desconectado do `manaloom_bracket_category`

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 53/53 (100%) |
| **Problema** | `impact_category` ≠ `manaloom_bracket_category` para TODAS as cartas |
| **Impacto** | 8/10 — Dois sistemas de categorização coexistem sem reconciliação |
| **Evidência** | `impact_category` tem 11 valores (value_engine, fast_mana, tutor, card_advantage, free_interaction, combo_piece, stax, protection, board_wipe). `manaloom_bracket_category` tem 5 valores (other, fastMana, freeInteraction, card_advantage, card_advantage_gap). Nenhuma carta tem valores iguais. |
| **Risco de falso positivo** | 🟡 Médio — Consumidores do DB precisam saber qual campo usar. `impact_category` é mais rico semanticamente mas não é usado pelo pipeline de detecção. |
| **Possível regra futura** | Unificar os dois campos OU documentar claramente que `impact_category` = classificação funcional do GC e `manaloom_bracket_category` = categoria do bracket system que o detecta. |

---

### 🆕 Lacuna 9 (NOVA): Categorias `card_advantage` e `card_advantage_gap` Sem Heurística de Detecção

| Campo | Valor |
|:------|:------|
| **Cartas** | Rhystic Study (`card_advantage`), Ad Nauseam (`card_advantage_gap`) |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=0` para ambas |
| **Evidência** | Essas são as ÚNICAS cartas com `manaloom_bracket_category` diferente de `other`, `fastMana`, ou `freeInteraction`. No entanto, NENHUMA heurística de código as detecta. Rhystic Study: "Whenever an opponent casts a spell, you may draw a card unless that player pays {1}." Ad Nauseam: "Reveal the top card... put it into your hand... lose life equal to its mana value." |
| **Risco de falso positivo** | 🟡 Médio — criar heurística para `card_advantage` é complexo (muitas cartas de draw existem). |
| **Possível regra futura** | Adicionar à lista curada de GCs com detecção por nome (não por heurística de oracle). |

---

### 🟡 Lacuna 10 (NOVA): `impact_category` com Erros de Classificação Funcional

Cartas cujo `impact_category` não reflete sua função primária no formato:

| Carta | `impact_category` atual | Categoria sugerida | Justificativa |
|:------|:------------------------|:-------------------|:--------------|
| Opposition Agent | `fast_mana` | `stax` | Não gera mana — restringe bibliotecas dos oponentes |
| Smothering Tithe | `fast_mana` | `card_advantage` + `fast_mana` | Gera tesouros (fast mana) E card advantage condicional |
| Farewell | `value_engine` | `board_wipe` | Board wipe flexível, não geração contínua de valor |
| Force of Will | `value_engine` | `free_interaction` | Free counterspell — o próprio código Dart o detecta como `freeInteraction` |
| Field of the Dead | `fast_mana` | `value_engine` | Landfall token generator — terra entra TAPPED |

---

## Análise Cruzada: As 7 Categorias Faltantes no Bracket System

O `edh_bracket_policy.dart` atual cobre apenas 5 categorias + `gameChanger`. Para fechar o gap de 29/53 GCs não detectados, são necessárias **7 novas categorias funcionais** (6 após `without paying` adicionado):

| Categoria Faltante | GCs Afetados | Heurística Proposta |
|:-------------------|:------------:|:--------------------|
| `card_advantage` | 5 (Rhystic, Tithe, Ring, Necropotence, Sphinx) | Trigger draw + opponent interaction |
| `board_wipe` | 2 (Cyclonic Rift, Farewell) | Mass bounce/exile + asymmetric |
| `stax` | 7 (Drannith, Opposition, Grand Arbiter, Braids, Humility, Glacial Chasm, Narset) | "can't" + "opponent" + restriction text |
| `value_engine` | 9 (Seedborn, Tergrid, Bolas's, Aura Shards, Biorhythm, Coalition, Notion Thief, Bowmasters, Tabernacle) | Continuous/compounding value generation |
| `protection` | 1 (Teferi's Protection) | "protection from everything" / "phase out" |
| `fast_mana_land` | 3 (Cradle, Sanctum, Workshop) | Land + tap for variable or 3+ mana |
| ~~`free_interaction_flex`~~ | ~~1~~ → **0** (Fierce Guardianship AGORA detectado pelo código) | — |

---

## Recomendações de Correção no SQLite

As seguintes correções são recomendadas (NÃO aplicadas automaticamente — requerem revisão humana):

### Correções de Categoria (`manaloom_bracket_category`)

| Carta | Atual | Corrigido | Motivo |
|:------|:------|:----------|:-------|
| Demonic Tutor | `other` | `tutor` | Detectado via `search your library` |
| Vampiric Tutor | `other` | `tutor` | Detectado via `search your library` |
| Enlightened Tutor | `other` | `tutor` | Detectado via `search your library` |
| Mystical Tutor | `other` | `tutor` | Detectado via `search your library` |
| Worldly Tutor | `other` | `tutor` | Detectado via `search your library` |
| Imperial Seal | `other` | `tutor` | Detectado via `search your library` |
| Gamble | `other` | `tutor` | Detectado via `search your library` |
| Intuition | `other` | `tutor` | Detectado via `search your library` |
| Gifts Ungiven | `other` | `tutor` | Detectado via `search your library` |
| Natural Order | `other` | `tutor` | Detectado via `search your library` |
| Survival of the Fittest | `other` | `tutor` | Detectado via `search your library` |
| Crop Rotation | `other` | `tutor` | Detectado via `search your library` |
| Thassa's Oracle | `other` | `infiniteCombo` | Na lista `_knownInfiniteComboPieces` |
| Underworld Breach | `other` | `infiniteCombo` | **Ainda NÃO está na lista** — deve ser adicionado |
| Force of Will | `other` | `freeInteraction` | Detectado via `rather than pay` |
| Bolas's Citadel | `other` | `freeInteraction` | Detectado via `rather than pay` / `without paying` |
| Field of the Dead | `fastMana` | `other` | NÃO é fast mana — terra entra TAPPED |

### Correções de `manaloom_detected`

| Carta | Atual | Corrigido | Motivo |
|:------|:-----:|:---------:|:-------|
| Field of the Dead | 1 | **0** | Nenhuma heurística funcional de bracket o detecta |
| Underworld Breach | 1 | **0** | Nenhuma heurística funcional de bracket o detecta. Deve ser adicionado a `_knownInfiniteComboPieces` após correção. |
| Fierce Guardianship | 0 | **1** | Código Dart JÁ detecta via `without paying`. DB desatualizado. |

### Correções de `impact_category` (classificação funcional)

| Carta | Atual | Corrigido | Motivo |
|:------|:------|:----------|:-------|
| Opposition Agent | `fast_mana` | `stax` | Não gera mana — restringe ações dos oponentes |
| Farewell | `value_engine` | `board_wipe` | Board wipe massivo, não geração de valor |
| Force of Will | `value_engine` | `free_interaction` | Free counterspell |
| Field of the Dead | `fast_mana` | `value_engine` | Landfall token generator |

---

## Métricas de Qualidade

| Métrica | Execução #2 | Execução #3 | Mudança |
|:--------|:-----------:|:-----------:|:-------|
| Total GCs analisados | 53 | 53 | — |
| GCs com `why_game_changer` preenchido | 53/53 (100%) | 53/53 (100%) | — |
| GCs com `bracket_category='other'` | ~25 | **42/53 (79%)** | 🔴 +17 |
| GCs com `bracket_category` correta | 48/53 (90.6%) | **34/53 (64.2%)** | 🔴 -14 |
| GCs com `manaloom_detected` incorreto | 3/53 (5.7%) | 3/53 (5.7%) | — |
| Falsos positivos (DB=1, código=0) | 2 | 2 | — |
| Falsos negativos (DB=0, código=1) | 1 | 1 | — |
| GCs não detectados pelo bracket system | 29/53 (54.7%) | 29/53 (54.7%) | — |
| Cartas com `impact_category ≠ bracket_category` | 53/53 (100%) | 53/53 (100%) | — (já era 100% na #2) |
| Cartas detectadas com `bracket_category='other'` | 16 | 16 | — |

**Nota sobre a métrica "categoria correta":** Na execução #2, a métrica de 48/53 considerava categorias como `value_engine`, `fast_mana` etc. como "corretas" se batessem com a função da carta. Após o colapso para `other`, apenas cartas com `bracket_category` igual à heurística de detecção são consideradas corretas (11 cartas nas categorias `fastMana`/`freeInteraction` + 23 tutores/combo que deveriam ter categoria mas têm `other` = 34 corretas se corrigíssemos).

---

## Prioridades para Próximo Ciclo

1. **🔴 Urgente:** Corrigir `manaloom_detected` para Field of the Dead (1→0) e Underworld Breach (1→0) — falsos positivos mascaram gaps reais.
2. **🔴 Urgente:** Corrigir `manaloom_detected` para Fierce Guardianship (0→1) — DB desatualizado em relação ao código.
3. **🟡 Alta:** Re-popular `manaloom_bracket_category` para os 16 detectados com `other` — especialmente os 12 tutores.
4. **🟡 Alta:** Adicionar Underworld Breach à lista `_knownInfiniteComboPieces` no código Dart.
5. **🟡 Média:** Documentar a divergência `impact_category` vs `manaloom_bracket_category` no schema.
6. **🟡 Média:** Criar heurística para `fast_mana_land` (Cradle, Sanctum, Workshop).
7. **🟢 Baixa:** Corrigir `impact_category` para Opposition Agent, Farewell, Force of Will, Field of the Dead.
