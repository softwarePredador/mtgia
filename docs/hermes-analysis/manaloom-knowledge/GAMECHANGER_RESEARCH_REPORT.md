# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: 36deb589c5b7d9644eb36c94b43bf254 -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 53 Game Changers.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-04 (execução #7 — 1 nova lacuna de qualidade de dados)
**Fonte:** `scripts/knowledge.db` (53/53 GCs preenchidos com `why_game_changer`)
**Detectados pelo ManaLoom:** 24/53 (45%) — **sem mudança desde execução #2**
**Não detectados:** 29/53 (55%) → 26 efetivamente não-detectados + 1 falso positivo + 1 falso negativo (+ 1 Underworld Breach detectado via sim mas bracket='other')
**Hash DB estrutural:** `36deb589c5b7d9644eb36c94b43bf254` (idêntico à execução #6 — sem mudança de métricas)

---

## Resumo Executivo

A sétima execução confirma que o hash estrutural permanece inalterado desde a execução #6 (`36deb589c5b7d9644eb36c94b43bf254`). As 10 lacunas de detecção/categorização persistem sem mudanças. **🆕 1 nova lacuna de qualidade de dados foi identificada:** Tergrid tem `oracle_text=NULL`, o que impede COMPLETAMENTE qualquer heurística baseada em texto de oracle de detectá-la. Esta é uma lacuna de completude de dados, não de lógica de detecção.

| Tipo de Lacuna | Execução #6 | Execução #7 | Mudança |
|:---------------|:-----------:|:-----------:|:-------|
| Categoria incorreta (erro de classificação) | 12 | 12 | — |
| Falso positivo de detecção (`det=1` indevido) | 1 | 1 | — (Field of the Dead persiste) |
| Falso negativo de detecção (`det=0` com código) | 1 | 1 | — (Fierce Guardianship persiste) |
| Colapso de categoria `other` com `det=1` | 16 | 16 | — (12 tutores + 2 combo + 2 value_engine) |
| Schema dual (`impact_category` vs `bracket_category`) | 53 | 53 | — todas as 53 cartas têm divergência |
| Heurística de código faltando | 3 | 3 | — (fast mana lands persistem) |
| 🆕 GC com `oracle_text=NULL` | 0 | 1 | **NOVA** — Tergrid sem oracle (bloqueia heurísticas) |
| 🆕 GCs sem `price_usd` | 0 | 8 | **NOVA** — 8 cartas sem preço (5 RL + 3 outras) |

**Hash estrutural permanece `36deb589...`** — sem alterações em `manaloom_detected`, `manaloom_bracket_category`, ou `impact_category` desde a execução #6. As novidades são de completude de dados, não de lógica de detecção.

---

## Lacunas Detectadas (Top 12 — Estado Atual, confirmado execução #7)

### Lacuna 1 (PERSISTE): 16 Cartas Detectadas com `bracket_category='other'` — Colapso de Categoria

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 16/53 (30%) |
| **Problema** | `manaloom_detected=1` mas `manaloom_bracket_category='other'` |
| **Impacto** | 9/10 — O campo `bracket_category` perdeu valor semântico para 30% dos GCs detectados |
| **Evidência** | 12 tutores + 2 combo pieces + 2 value engines são detectados pelo bracket system mas registrados sem categoria |
| **Risco de falso positivo** | 🔴 Alto — consumidores do DB (`bracket_category`) recebem `other` quando deveriam receber `tutor`, `infiniteCombo`, ou `freeInteraction` |
| **Possível regra futura** | Re-popular `manaloom_bracket_category` baseado na heurística que gerou `det=1`: `search your library` → `tutor`, `rather than pay`/`without paying` → `freeInteraction`, `extra turn` → `extraTurns`, `infiniteCombo list` → `infiniteCombo`, `fastMana list` → `fastMana` |

**Detalhamento dos 16 (confirmado execução #6):**

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
| **Evidência** | Oracle: "enters the battlefield tapped. {T}: Add {C}. ...create a 2/2 black Zombie." NÃO está na lista curada de fastMana. NÃO contém `search your library`, `extra turn`, `rather than pay`, `without paying`, nem está em `_knownInfiniteComboPieces`. **Re-simulação confirma: NENHUMA heurística detecta.** |
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
| **Código** | `det=1` — heurística `without paying` detecta |
| **Evidência** | Oracle: "If you control a commander, you may cast this spell without paying its mana cost." A re-simulação confirma: `without paying` → `freeInteraction`. O DB não foi re-simulado. |
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
| **Evidência** | Oracle: "{T}: Add {G} for each creature you control." A lista curada de fastMana contém apenas artefatos. Terras com output variável não são cobertas. Re-simulação confirma `det=0`. |
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

### Lacuna 8 (PERSISTE): Schema Dual — `impact_category` Desconectado do `manaloom_bracket_category`

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 53/53 (100%) |
| **Problema** | `impact_category` ≠ `manaloom_bracket_category` para TODAS as cartas |
| **Impacto** | 8/10 — Dois sistemas de categorização coexistem sem reconciliação |
| **Evidência** | `impact_category` tem 10 valores (value_engine=17, fast_mana=13, tutor=12, card_advantage=4, free_interaction=2, combo_piece=2, board_wipe=1, stax=1, protection=1). `manaloom_bracket_category` tem 5 valores (other=42, fastMana=7, freeInteraction=2, card_advantage=1, card_advantage_gap=1). Nenhuma carta tem valores iguais. |
| **Risco de falso positivo** | 🟡 Médio — Consumidores do DB precisam saber qual campo usar. `impact_category` é mais rico semanticamente mas não é usado pelo pipeline de detecção. |
| **Possível regra futura** | Unificar os dois campos OU documentar claramente que `impact_category` = classificação funcional do GC e `manaloom_bracket_category` = categoria do bracket system que o detecta. |

---

### Lacuna 9 (PERSISTE): Categorias `card_advantage` Sem Heurística de Detecção

| Campo | Valor |
|:------|:------|
| **Cartas** | Rhystic Study (`card_advantage`), Ad Nauseam (`card_advantage_gap`), Notion Thief (`card_advantage`), The One Ring (`card_advantage`) |
| **Impacto** | 7/10 |
| **DB** | `manaloom_detected=0` para todas |
| **Evidência** | Essas cartas têm `manaloom_bracket_category` = `card_advantage` ou `card_advantage_gap`, mas NENHUMA heurística de código as detecta. Rhystic Study: "Whenever an opponent casts a spell, you may draw a card unless that player pays {1}." Ad Nauseam: "Reveal the top card... put it into your hand... lose life equal to its mana value." |
| **Risco de falso positivo** | 🟡 Médio — criar heurística para `card_advantage` é complexo (muitas cartas de draw existem). |
| **Possível regra futura** | Adicionar à lista curada de GCs com detecção por nome (não por heurística de oracle). |

---

### 🟡 Lacuna 10 (PERSISTE): `impact_category` com Erros de Classificação Funcional

Cartas cujo `impact_category` não reflete sua função primária no formato (confirmado execução #6):

| Carta | `impact_category` atual | Categoria sugerida | Justificativa |
|:------|:------------------------|:-------------------|:--------------|
| Opposition Agent | `fast_mana` | `stax` | Não gera mana — restringe bibliotecas dos oponentes |
| Smothering Tithe | `fast_mana` | `card_advantage` + `fast_mana` | Gera tesouros (fast mana) E card advantage condicional |
| Farewell | `value_engine` | `board_wipe` | Board wipe flexível, não geração contínua de valor |
| Force of Will | `value_engine` | `free_interaction` | Free counterspell — o próprio código Dart o detecta como `freeInteraction` |
| Field of the Dead | `fast_mana` | `value_engine` | Landfall token generator — terra entra TAPPED |

---

### 🆕 Lacuna 11 (NOVA — Execução #7): Tergrid — `oracle_text=NULL` Bloqueia Toda Heurística

| Campo | Valor |
|:------|:------|
| **Carta** | Tergrid, God of Fright // Tergrid's Lantern |
| **Problema** | `oracle_text` está NULL no DB |
| **Impacto** | 8/10 — NENHUMA heurística baseada em oracle pode detectar esta carta |
| **DB** | `oracle_text=NULL`, `manaloom_detected=0`, `manaloom_bracket_category='other'` |
| **Evidência** | Query `SELECT oracle_text FROM game_changers WHERE card_name LIKE '%Tergrid%'` retorna NULL. O `why_game_changer` está preenchido (1018 chars) e o `notes` também (394 chars), confirmando que a carta foi pesquisada. Mas sem `oracle_text`, Tergrid é **completamente invisível** para qualquer heurística funcional: `search your library`, `without paying`, `extra turn`, `fastMana list`, `_knownInfiniteComboPieces` — todas dependem de `oracle_text`. |
| **Risco de falso positivo** | 🔴 **Alto** — A carta existe, é GC oficial, tem `why_game_changer` detalhado, mas o sistema NUNCA poderá detectá-la por heurística porque o campo mais fundamental está vazio. |
| **Possível regra futura** | 1. Imediato: corrigir `oracle_text` via Scryfall API. Nome fuzzy: "Tergrid, God of Fright" (buscar o lado front da MDFC). Oracle real: front side = "Menace. Whenever an opponent sacrifices a nontoken permanent or discards a permanent card, you may put that card onto the battlefield under your control from that player's graveyard." + back side = "{T}: Target opponent loses 3 life unless they sacrifice a nonland permanent or discard a card. {3}{B}: Untap Tergrid's Lantern." 2. Adicionar à lista curada de GCs por nome (fallback para quando oracle falta). |
| **Nota** | O `notes` já menciona: "EDHREC API indisponivel (slug mismatch)." Isso explica o `oracle_text` NULL — a busca no Scryfall pelo nome MDFC completo falhou. |

**Diagnóstico:** Esta é uma lacuna de **importação de dados**, não de lógica. O importador que popula `game_changers` provavelmente usou `scryfall.com/cards/named?fuzzy=Tergrid,+God+of+Fright+//+Tergrid's+Lantern` e o Scryfall não encontrou correspondência exata para o nome com `//`. O campo `oracle_text` ficou NULL como consequência. A carta tem `why_game_changer` (escrito manualmente ou via análise separada) mas sem o oracle que permite heurísticas automáticas.

---

### 🆕 Lacuna 12 (NOVA — Execução #7): 8 Cartas com `price_usd=NULL` — Dados de Mercado Incompletos

| Campo | Valor |
|:------|:------|
| **Cartas afetadas** | 8/53 (15%) |
| **Problema** | `price_usd IS NULL` em 8 Game Changers |
| **Impacto** | 3/10 — Baixo para detecção (preço não afeta heurísticas), mas relevante para qualidade de dados e priorização |
| **Evidência** | 5 Reserved List (Lion's Eye Diamond, Mishra's Workshop, Mox Diamond, Survival of the Fittest, The Tabernacle at Pendrell Vale) + 3 outras (Glacial Chasm, Humility, Intuition). Reserved List cards tipicamente não têm preço em APIs públicas (Scryfall marca como `not available`), o que é esperado. Glacial Chasm (RL, land), Humility (RL), Intuition (RL) seguem o mesmo padrão. |
| **Risco de falso positivo** | 🟢 **Baixo** — NULL price não gera falsos positivos de detecção. É puramente uma lacuna de completude de dados. |
| **Possível regra futura** | Para RL cards: marcar `price_usd` como `RESERVED_LIST` ao invés de NULL, indicando que o dado não é recuperável vs. simplesmente faltando. Para não-RL: reimportar via Scryfall API com backoff. |

**Diagnóstico:** Todas as 8 cartas são Reserved List. O importador provavelmente recebeu `null` da Scryfall API (que marca RL cards sem preço de mercado) e persistiu como NULL. Isso é esperado para RL, mas a falta de distinção entre "RL sem preço" e "dado faltante" reduz a qualidade do campo.

---

## Análise Cruzada: As 7 Categorias Faltantes no Bracket System

O `edh_bracket_policy.dart` atual cobre apenas 5 categorias + `gameChanger`. Para fechar o gap de 29/53 GCs não detectados, são necessárias **7 novas categorias funcionais** (6 após `without paying` adicionado):

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

## Distribuição de Categorias (Estado Atual)

### `manaloom_bracket_category` (5 valores, 42 = `other`)
- `other`: 42 (79%) — **incluindo 16 detectados com categoria colapsada**
- `fastMana`: 7 (13%)
- `freeInteraction`: 2 (4%)
- `card_advantage`: 1 (2%)
- `card_advantage_gap`: 1 (2%)

### `impact_category` (10 valores, distribuição funcional rica)
- `value_engine`: 17 (32%)
- `fast_mana`: 13 (25%)
- `tutor`: 12 (23%)
- `card_advantage`: 4 (8%)
- `free_interaction`: 2 (4%)
- `combo_piece`: 2 (4%)
- `board_wipe`: 1 (2%)
- `stax`: 1 (2%)
- `protection`: 1 (2%)

---

## Métricas de Qualidade (Execução #7)

| Métrica | Valor | Tendência |
|:--------|:-----:|:----------|
| GCs com `why_game_changer` preenchido | 53/53 (100%) | ✅ Estável desde #1 |
| `why_game_changer` com < 20 chars | 0/53 (0%) | ✅ Estável |
| Falsos positivos (`det=1` sem heurística) | 1/53 (2%) | → Field of the Dead persiste |
| Falsos negativos (`det=0` com heurística) | 1/53 (2%) | → Fierce Guardianship persiste |
| `bracket_category='other'` com `det=1` | 16/53 (30%) | → Colapso de categoria persiste |
| `impact_category` com erro funcional | 5/53 (9%) | → 5 erros conhecidos persistem |
| Categorias faltantes no código Dart | 7 | → Sem mudança |
| 🆕 `oracle_text IS NULL` | 1/53 (2%) | **NOVA** — Tergrid sem oracle |
| 🆕 `price_usd IS NULL` | 8/53 (15%) | **NOVA** — todas RL cards |

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

**Execução #7:** Hash estrutural inalterado desde #6 (`36deb589c5b7d9644eb36c94b43bf254`). As 10 lacunas de detecção/categorização persistem sem alteração. **2 novas lacunas de completude de dados** foram identificadas: Tergrid com `oracle_text=NULL` (impede heuristicas) e 8 cartas com `price_usd=NULL` (todas Reserved List).

**Próximos passos recomendados (externos ao cron):**
1. 🔴 Corrigir `det=1 → 0` e `bracket_category='fastMana' → 'other'` para Field of the Dead
2. Re-simular Fierce Guardianship: `det=0 → 1`
3. Re-popular `manaloom_bracket_category` para os 16 detectados com `other` baseado na heurística que os detectou
4. Adicionar Underworld Breach à lista `_knownInfiniteComboPieces`
5. Corrigir 5 `impact_category` errados (Opposition Agent, Smothering Tithe, Farewell, Force of Will, Field of the Dead)
6. 🆕 **Corrigir `oracle_text` de Tergrid** — reimportar via Scryfall API usando nome fuzzy sem `//`
7. 🆕 **Distinguir `price_usd=NULL` como RESERVED_LIST** para as 8 cartas afetadas

**O cron deve continuar em modo [SILENT] para execuções futuras enquanto o hash estrutural permanecer o mesmo.** Se o hash mudar, reexecutar análise completa. As lacunas 11 e 12 (dados) não afetam o hash estrutural e devem ser verificadas a cada execução independentemente do hash.
