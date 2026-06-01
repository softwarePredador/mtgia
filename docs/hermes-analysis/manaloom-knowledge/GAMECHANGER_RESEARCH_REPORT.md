# Game Changer Research Report — Lacunas e Recomendações

> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 53 Game Changers.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-01
**Fonte:** `scripts/knowledge.db` (53/53 GCs preenchidos com `why_game_changer`)
**Detectados pelo ManaLoom:** 24/53 (45%)
**Não detectados:** 29/53 (55%)

---

## Resumo Executivo

Embora todos os 53 Game Changers tenham `why_game_changer` e `notes` preenchidos no SQLite, a auditoria de qualidade revelou **10 lacunas** distribuídas em 4 categorias de problema:

| Tipo de Lacuna | Quantidade | Impacto |
|:---------------|:----------:|:--------|
| Categoria incorreta (erro de classificação) | 4 | 🔴 Alto — afeta análise de função e swap |
| Falso positivo de detecção (`manaloom_detected=1` indevido) | 1 | 🔴 Alto — mascara gap real |
| Heurística de detecção faltando | 4 | 🟡 Médio — cartas conhecidas sem cobertura |
| Categoria incompleta (função dual) | 1 | 🟡 Médio — subestima impacto |

---

## Lacunas Detectadas (Top 10)

### 🔴 Lacuna 1: Force of Will — Categoria Errada

| Campo | Valor |
|:------|:------|
| **Carta** | Force of Will |
| **Categoria atual** | `value_engine` |
| **Categoria sugerida** | `free_interaction` |
| **Impacto** | 9/10 |
| **Evidência** | Oracle: "You may pay 1 life and exile a blue card from your hand rather than pay this spell's mana cost. Counter target spell." É o free counterspell definitivo. EDHREC: Kinnan (61.1%), Kraum/Tymna (87.5%), Thrasios/Tymna (83.4%). |
| **Risco de falso positivo** | 🟢 Baixo — o texto é inequívoco. É free interaction, não value engine. |
| **Possível regra futura** | `if 'rather than pay' in oracle and 'counter target' in oracle → free_interaction` |

**Diagnóstico:** Force of Will está classificado como `value_engine` no SQLite, mas sua função primária é `free_interaction` (contramágica gratuita). O bracket system do ManaLoom já o detecta corretamente via heurística `rather than pay`, confirmando que a categoria correta é `free_interaction`.

---

### 🔴 Lacuna 2: Panoptic Mirror — Categoria Errada

| Campo | Valor |
|:------|:------|
| **Carta** | Panoptic Mirror |
| **Categoria atual** | `free_interaction` |
| **Categoria sugerida** | `combo_piece` |
| **Impacto** | 7/10 |
| **Evidência** | Oracle: "Imprint — {X}, {T}: You may exile an instant or sorcery... At the beginning of your upkeep, you may copy a card exiled... you may cast the copy without paying its mana cost." Combo determinístico com extra turn spells (Time Warp, etc.). |
| **Risco de falso positivo** | 🟢 Baixo — a carta não interage com oponentes, apenas gera valor próprio. |
| **Possível regra futura** | `if 'copy' in oracle and 'upkeep' in oracle and 'without paying' in oracle → combo_piece` |

**Diagnóstico:** Panoptic Mirror é uma peça de combo (tranca o jogo com extra turns), não free interaction. O ManaLoom já o detecta como `infiniteCombo` no bracket system, reforçando que `combo_piece` é a categoria correta.

---

### 🔴 Lacuna 3: Opposition Agent — Categoria Errada

| Campo | Valor |
|:------|:------|
| **Carta** | Opposition Agent |
| **Categoria atual** | `fast_mana` |
| **Categoria sugerida** | `stax` |
| **Impacto** | 6/10 |
| **Evidência** | Oracle: "Flash. You control your opponents while they're searching their libraries." Flash + impede/rouba tutors dos oponentes. EDHREC: Thrasios/Tymna (53.8%), Kraum/Tymna (42.1%), Tivit (35.2%). |
| **Risco de falso positivo** | 🟢 Baixo — a carta não produz mana. Categoria `fast_mana` é inequivocamente errada. |
| **Possível regra futura** | `if 'control your opponents while' in oracle → stax` |

**Diagnóstico:** Opposition Agent é uma peça de stax (restringe ações dos oponentes), não gera mana. A classificação como `fast_mana` é um erro claro — provavelmente confusão com outro GC durante inserção batch.

---

### 🔴 Lacuna 4: Field of the Dead — Falso Positivo de Detecção

| Campo | Valor |
|:------|:------|
| **Carta** | Field of the Dead |
| **Categoria atual** | `fast_mana` (errada — deveria ser `value_engine`) |
| **Categoria sugerida** | `value_engine` |
| **Impacto** | 7/10 |
| **Evidência** | Oracle: "This land enters tapped. {T}: Add {C}. Whenever this land or another land you control enters, if you control seven or more lands with different names, create a 2/2 black Zombie." NÃO contém "search your library", "extra turn", "rather than pay", nem está na lista curada de fastMana. |
| **Risco de falso positivo** | 🔴 **Alto** — `manaloom_detected=1` no DB, mas o oracle NÃO corresponde a nenhuma das 5 heurísticas do `tagCardForBracket()`. A terra entra TAPPED e gera {C} — é o oposto de fast mana. |
| **Possível regra futura** | **Corrigir `manaloom_detected=1 → 0`**. A heurística para detectar Field of the Dead como GC precisaria de categoria `value_engine` (landfall token generator), que ainda não existe. |

**Diagnóstico:** Este é o gap mais perigoso: Field of the Dead tem `manaloom_detected=1` mas NENHUMA das 5 categorias de bracket o detecta. É um falso positivo que mascara um gap real no sistema. A terra gera tokens passivamente por landfall — é um `value_engine`, não `fast_mana`.

---

### 🟡 Lacuna 5: Farewell — Categoria de Board Wipe

| Campo | Valor |
|:------|:------|
| **Carta** | Farewell |
| **Categoria atual** | `value_engine` |
| **Categoria sugerida** | `board_wipe` |
| **Impacto** | 6/10 |
| **Evidência** | Oracle: "Choose one or more — Exile all artifacts / creatures / enchantments / graveyards." EDHREC rank #33, $6.22. É o board wipe mais flexível já impresso. O próprio `notes` do SQLite diz "NAO detectado - precisa categoria board_wipe". |
| **Risco de falso positivo** | 🟢 Baixo — `value_engine` descreve geração de valor contínuo; Farewell é remoção pontual massiva. |
| **Possível regra futura** | `if 'exile all' in oracle and 'choose one or more' in oracle → board_wipe` |

**Diagnóstico:** Farewell é um board wipe, não um value engine. A categoria no DB contradiz o próprio diagnóstico do campo `notes` ("precisa categoria board_wipe"). É um resquício de inserção batch onde cartas foram agrupadas sob `value_engine` como categoria genérica para "não detectado".

---

### 🟡 Lacuna 6: Fierce Guardianship — Heurística de Free Spell Faltando

| Campo | Valor |
|:------|:------|
| **Carta** | Fierce Guardianship |
| **Categoria** | `free_interaction` (correta) |
| **Impacto** | 6/10 |
| **Detectado pelo ML** | ❌ Não (`manaloom_detected=0`) |
| **Evidência** | Oracle: "If you control a commander, you may cast this spell without paying its mana cost. Counter target noncreature spell." A heurística atual busca `rather than pay` — Fierce Guardianship usa `without paying its mana cost` + `if you control a commander`. EDHREC: Kinnan (66.2%), Kraum/Tymna (88.4%). |
| **Risco de falso positivo** | 🟡 Médio — `without paying its mana cost` aparece em muitas cartas que NÃO são free interaction (cascade, cheat-into-play). O contexto `if you control a commander` + `counter target` é necessário para restringir. |
| **Possível regra futura** | `if 'without paying its mana cost' in oracle and 'if you control' in oracle and 'counter target' in oracle → free_interaction` |

**Diagnóstico:** A heurística atual de `freeInteraction` só detecta o padrão `rather than pay` (Force of Will, Force of Negation). Fierce Guardianship usa `without paying` + condição de commander. É o free counterspell #2 mais jogado e está invisível ao bracket system.

---

### 🟡 Lacuna 7: Jeska's Will — Categoria Incompleta (Função Dual)

| Campo | Valor |
|:------|:------|
| **Carta** | Jeska's Will |
| **Categoria atual** | `fast_mana` |
| **Categoria sugerida** | `fast_mana` + `card_advantage` (dual) |
| **Impacto** | 6/10 |
| **Detectado pelo ML** | ❌ Não (`manaloom_detected=0`) |
| **Evidência** | Oracle: "Choose one. If you control a commander, you may choose both — Add {R} for each card in target opponent's hand / Exile the top three cards of your library. You may play them this turn." Modo 1 = ritual explosivo. Modo 2 = impulsive draw. Com commander = ambos. EDHREC: Storm (80.9%), Etali (64.2%), Vivi (48.6%). |
| **Risco de falso positivo** | 🟢 Baixo — `fast_mana` é correto para o modo ritual, mas incompleto. A carta também é `card_advantage` quando usada no modo impulsive draw. |
| **Possível regra futura** | Considerar sistema de tags múltiplas para GCs com funções duais (Jeska's Will, Smothering Tithe, The One Ring). |

**Diagnóstico:** Jeska's Will é `fast_mana` + `card_advantage` simultaneamente. O impacto real da carta é maior do que `fast_mana` sozinho sugere porque também gera vantagem de cartas. A pontuação `impact=6` pode estar subestimada.

---

### 🟡 Lacuna 8: Gaea's Cradle — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Gaea's Cradle |
| **Categoria** | `fast_mana` (correta) |
| **Impacto** | 9/10 |
| **Detectado pelo ML** | ❌ Não (`manaloom_detected=0`) |
| **Evidência** | Oracle: "{T}: Add {G} for each creature you control." Terra que gera mana explosiva baseada em criaturas. A lista curada de fastMana no `edh_bracket_policy.dart` contém apenas artefatos — terras com output variável (Cradle, Sanctum, Workshop) não são cobertas. |
| **Risco de falso positivo** | 🟢 Baixo — `{T}: Add {X} for each` é um padrão claro e raro. |
| **Possível regra futura** | Expandir fastMana para incluir terras: `if 'land' in type_line and '{T}: Add' in oracle and ('for each' in oracle or oracle.count('{') >= 3) → fast_mana` |

**Diagnóstico:** As 3 terras de fast mana (Cradle, Sanctum, Workshop) são GCs oficiais mas escapam da detecção porque o bracket system só verifica uma lista curada de artefatos. Gaea's Cradle é a mais impactante (preço: $1,459).

---

### 🟡 Lacuna 9: Serra's Sanctum — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Serra's Sanctum |
| **Categoria** | `fast_mana` (correta) |
| **Impacto** | 6/10 |
| **Detectado pelo ML** | ❌ Não (`manaloom_detected=0`) |
| **Evidência** | Oracle: "{T}: Add {W} for each enchantment you control." Mesmo padrão de Gaea's Cradle, mas para encantamentos. Menos onipresente que Cradle, mas igualmente explosiva no deck certo (enchantress, shrines). |
| **Risco de falso positivo** | 🟢 Baixo — mesmo padrão de Cradle. |
| **Possível regra futura** | Mesma regra da Lacuna 8. |

---

### 🟡 Lacuna 10: Mishra's Workshop — Fast Mana Land Não Detectado

| Campo | Valor |
|:------|:------|
| **Carta** | Mishra's Workshop |
| **Categoria** | `fast_mana` (correta) |
| **Impacto** | 6/10 |
| **Detectado pelo ML** | ❌ Não (`manaloom_detected=0`) |
| **Evidência** | Oracle: "{T}: Add {C}{C}{C}. Spend this mana only to cast artifact spells." Terra que gera 3 manas incolores para artefatos. Padrão diferente de Cradle/Sanctum (quantidade fixa, não variável). |
| **Risco de falso positivo** | 🟡 Médio — `{T}: Add {C}{C}{C}` é um padrão específico, mas outras terras (Ancient Tomb, City of Traitors) produzem 2 manas e são detectadas pela lista curada. Workshop produz 3. |
| **Possível regra futura** | `if 'land' in type_line and oracle_text has 3+ consecutive '{C}' in tap ability → fast_mana` |

---

## Análise Cruzada: As 7 Categorias Faltantes no Bracket System

O `edh_bracket_policy.dart` atual cobre apenas 5 categorias. Para fechar o gap de 29/53 GCs não detectados, são necessárias **7 novas categorias**:

| Categoria Faltante | GCs Afetados | Heurística Proposta |
|:-------------------|:------------:|:--------------------|
| `card_advantage` | 5 (Rhystic, Tithe, Ring, Necropotence, Sphinx) | Trigger draw + opponent interaction |
| `board_wipe` | 2 (Cyclonic Rift, Farewell) | Mass bounce/exile + asymmetric |
| `stax` | 7 (Drannith, Opposition, Grand Arbiter, Braids, Humility, Glacial Chasm, Narset) | "can't" + "opponent" + restriction text |
| `value_engine` | 9 (Seedborn, Tergrid, Bolas's, Aura Shards, Biorhythm, Coalition, Notion Thief, Bowmasters, Tabernacle) | Continuous/compounding value generation |
| `protection` | 1 (Teferi's Protection) | "protection from everything" / "phase out" |
| `free_interaction_flex` | 1 (Fierce Guardianship) | "without paying" + "if you control" + counter |
| `fast_mana_land` | 3 (Cradle, Sanctum, Workshop) | Land + tap for variable or 3+ mana |

---

## Recomendações de Correção no SQLite

As seguintes correções de categoria são recomendadas (NÃO aplicadas automaticamente — requerem revisão humana):

| Carta | Categoria Atual | Categoria Corrigida | Motivo |
|:------|:----------------|:--------------------|:-------|
| Force of Will | `value_engine` | `free_interaction` | Free counterspell, não value engine |
| Panoptic Mirror | `free_interaction` | `combo_piece` | Combo enabler, não interage com oponentes |
| Opposition Agent | `fast_mana` | `stax` | Restringe oponentes, não gera mana |
| Field of the Dead | `fast_mana` | `value_engine` | Token generator, não fast mana |
| Farewell | `value_engine` | `board_wipe` | Board wipe, não value engine |

**Correção de `manaloom_detected`:**
| Carta | Atual | Corrigido | Motivo |
|:------|:-----:|:---------:|:-------|
| Field of the Dead | 1 | **0** | Nenhuma heurística de bracket o detecta; é falso positivo |

---

## Métricas de Qualidade

| Métrica | Valor |
|:--------|:-----|
| Total GCs analisados | 53 |
| GCs com `why_game_changer` preenchido | 53/53 (100%) |
| GCs com categoria correta | 48/53 (90.6%) |
| GCs com categoria incorreta | 5/53 (9.4%) |
| GCs com `manaloom_detected` incorreto | 1/53 (1.9%) |
| GCs não detectados pelo bracket system | 29/53 (54.7%) |
| Categorias de bracket faltando | 7 |
