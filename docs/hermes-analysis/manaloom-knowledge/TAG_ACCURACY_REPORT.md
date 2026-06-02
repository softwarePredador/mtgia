# Tag Accuracy Report — 2026-06-02

**Generated:** 2026-06-02T18:45:00+00:00
**Source:** `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` → `tag_accuracy`, `deck_cards`, `card_tags`, `discrepancies`
**Previous report:** 2026-06-01
**Schema:** 22 tags in `tag_accuracy` (unchanged since 2026-05-27)

---

## 1. Mudanças desde o Último Relatório (2026-06-01 → 2026-06-02)

| Métrica | 2026-06-01 | 2026-06-02 | Delta |
|:--------|:----------:|:----------:|:-----:|
| `tag_accuracy` rows | 22 | 22 | 0 |
| `tag_accuracy` data updated | 2026-05-27 | **2026-05-27** | **Nenhuma** |
| Discrepancies | 20 | **21** | **+1** |
| `deck_cards` total | ~460 | **543** | **+83** |
| Decks | ~6 | **7** | **+1** |
| Double-null cards | 29 (7.4%) | **25 (4.6%)** | -4 |
| Single vs multi divergence | 84 (21.5%) | **36 (6.6%)** | -48 |
| No multi-tag cards | 77 (19.7%) | **124 (22.8%)** | +47 |
| `functional_tag = 'unknown'` | 0 | **20** | **+20** 🔴 |
| `functional_tag IS NULL` | 32 | **32** | 0 |

> **Conclusão:** A tabela `tag_accuracy` **não foi atualizada** desde o último relatório. Porém houve uma mudança significativa nos dados subjacentes: um novo deck foi importado em bulk com **20 cartas não classificadas** (`functional_tag='unknown'`, CMC=NULL). Este é um sinal de alerta que merece documentação.

---

## 2. Precisão Por Tag (INALTERADO desde 2026-05-27)

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

## 3. 🔴 NOVO: Bulk Import Corruption — 20 Cartas Não Classificadas

**Descoberto em:** 2026-06-02

Um novo deck ("Lorehold Best-of Learned No Premium Mox 2026-06-02") foi importado em bulk com **20 cartas** (20% do deck) que:

- Têm `functional_tag = 'unknown'` (string, NÃO null — a query de double-null não as detecta)
- Têm `CMC = NULL` ou `CMC = 0.0`
- Têm `type_line = NULL` ou vazio
- Têm **zero** entradas em `card_tags`

**Isso é o padrão "Classifier NEVER Ran" documentado na skill** (`Pitfall: Bulk Import Data Corruption`). O classificador NÃO foi executado nestas cartas — elas foram inseridas cruas, sem análise de oracle text, sem atribuição de tags.

### Cartas Afetadas

| Carta | CMC no DB | type_line | Problema |
|:------|:---------:|:----------|:---------|
| Electroduplicate | NULL | NULL | Sem oracle, sem tipo, sem CMC |
| Heat Shimmer | NULL | NULL | Sem oracle, sem tipo, sem CMC |
| Past in Flames | NULL | NULL | Sem oracle, sem tipo, sem CMC |
| Reiterate | NULL | NULL | Sem oracle, sem tipo, sem CMC |
| Birgi, God of Storytelling | 0.0 | "" | CMC errado, sem tipo |
| Boros Charm | 0.0 | "" | CMC errado, sem tipo |
| Flawless Maneuver | 0.0 | "" | CMC errado, sem tipo |
| Lightning Greaves | 0.0 | "" | CMC errado, sem tipo |
| Mana Vault | 0.0 | "" | CMC errado, sem tipo |
| Orim's Chant | 0.0 | "" | CMC errado, sem tipo |
| Pyroblast | 0.0 | "" | CMC errado, sem tipo |
| Reforge the Soul | 0.0 | "" | CMC errado, sem tipo |
| Reverberate | 0.0 | "" | CMC errado, sem tipo |
| Valakut Awakening | 0.0 | "" | CMC errado, sem tipo |
| Victory Chimes | 0.0 | "" | CMC errado, sem tipo |
| Sol Ring | 1.0 | Artifact | Tem tipo mas 'unknown' |
| Boros Signet | 2.0 | Artifact | Tem tipo mas 'unknown' |
| Ruby Medallion | 2.0 | Artifact | Tem tipo mas 'unknown' |
| Scroll Rack | 2.0 | Artifact | Tem tipo mas 'unknown' |
| Talisman of Conviction | 2.0 | Artifact | Tem tipo mas 'unknown' |

**Impacto:** Este deck é **completamente invisível** para qualquer pipeline de análise que use `functional_tag` ou `card_tags`. O Evolution Oracle não pode propor swaps. O Mulligan Analyst não pode classificar ramp/draw. O Validator não pode calcular métricas.

**Ação recomendada:** Rodar o classificador (`classify_card()` ou equivalente) neste deck antes de qualquer análise. O script de importação (`scripts/import_lorehold_decks.py`) precisa ser corrigido para executar classificação pós-import.

---

## 4. Mudanças nos Sinais de Erro

### 4.1 Nova Discrepância: Blade Historian (#21)

| Campo | Valor |
|:------|:------|
| Card | Blade Historian |
| ML Tag | creature |
| Expected | combat_payoff |
| Motivo | Single-tag creature não captura que é payoff de dano/clock |
| Impacto | medium |
| Resolvida? | Não |
| Data | 2026-05-27 (já existia, só não estava listada no relatório de 2026-06-01) |

> Esta discrepância já existia desde 2026-05-27 mas não foi incluída nas 20 listadas no relatório anterior. Detectada agora na re-varredura completa da tabela `discrepancies`.

### 4.2 Divergência Single vs Multi-Tag: 84 → 36

A divergência caiu de **84 (21.5%)** para **36 (6.6%)**. Esta métrica é instável porque:

1. O novo deck tem 20 cartas com `functional_tag='unknown'` que NÃO participam do cálculo (query filtra `WHERE functional_tag IS NOT NULL`)
2. O denominador aumentou (+83 cartas no total)
3. Sem baseline por deck, não é possível isolar a divergência real vs artefato estatístico

**Recomendação:** Esta métrica deve ser calculada por deck, não globalmente, para ser interpretável.

### 4.3 No Multi-Tag: 77 → 124

Aumento de **47 cartas** sem multi-tags. Praticamente todo vindo do novo deck (20 cartas sem classificação) + novas cartas em decks existentes sem oracle text. Cartas sem multi-tag são um problema porque o Evolution Oracle perde o contexto multi-dimensional que o `card_tags` fornece.

### 4.4 Double-Null: 29 → 25

Redução de 4 cartas double-null. As 25 restantes são todas de decks EDHREC Average (Dimir Ninja, Aesi, Kinnan, Default) — **nenhuma** é do Lorehold ativo. Isso indica que o Lorehold pipeline (Evolution Oracle, Scout) está mantendo seu deck limpo enquanto os decks de referência acumulam double-nulls.

---

## 5. Recomendações de Código (Atualizadas)

### 5.1 🔴 CORRIGIR Bulk Import — Classificador NÃO Executado (NOVA)

**Arquivo provável:** `docs/hermes-analysis/manaloom-knowledge/scripts/import_lorehold_decks.py`

O script de importação não executa o classificador após inserir as cartas. 20 cartas entraram com `functional_tag='unknown'`, CMC NULL, type_line NULL.

**Ação:**
1. Adicionar `classify_card()` ao pipeline de importação
2. Ou criar script `reclassify_deck.py` que roda o classificador em todas as cartas de um deck
3. Validar pós-import: `SELECT COUNT(*) FROM deck_cards WHERE deck_id = ? AND (functional_tag = 'unknown' OR cmc IS NULL)` — se > 0, ABORTAR

### 5.2 🔴 Ampliar Heurísticas Estratégicas (REITERADA)

**Status:** Não implementada.
**Arquivos:** `server/lib/ai/optimization_functional_roles.dart` (L370-398), `functional_card_tags.dart` (L859-907), `scryfall_classifier.py` (L155-221)

Heurísticas `_looksLike*` continuam demasiado estreitas. Payoff a 35.5% e enabler a 50% são inaceitáveis para decisões de swap automatizadas.

### 5.3 🟡 Unificar Single-Tag e Multi-Tag (REITERADA)

**Status:** Não implementada. Divergência entre os dois classificadores persiste.

### 5.4 🟡 Popular false_positive / false_negative (REITERADA)

**Status:** Colunas `false_positive` e `false_negative` continuam zeradas em todas as 22 tags. Sem rastreamento granular de erros.

### 5.5 🟢 Adicionar `combat_payoff` como Tag (NOVA — Blade Historian)

O padrão "creatures you control have double strike" (e similares como "creatures you control get +X/+X") é payoff de combate, não type-based creature. Sugerir novo tag `combat_payoff` ou expandir `payoff` para incluir combat keywords.

---

## 6. Sumário Executivo

| Métrica | Valor | Mudança |
|:--------|:-----|:--------|
| Tags no sistema | 22 | 0 |
| Tags com 100% de precisão | 15 (68%) | 0 |
| Tags abaixo de 85% | 7 (32%) | 0 |
| Pior precisão | **payoff (35.5%)** | 0 |
| Cartas double-null | 25 (4.6%) | -4 |
| Divergência single vs multi tag | 36 (6.6%) | -48* |
| Cartas sem multi-tags | 124 (22.8%) | +47 |
| Cartas 'unknown' (classificador não rodou) | **20** 🔴 | **+20** |
| fp/fn tracking implementado | NÃO | 0 |
| Discrepâncias documentadas | 21 | +1 |
| Novos decks | 1 | +1 |

*\* Mudança na divergência é parcialmente artefato do novo deck com tags 'unknown'*

### Conclusão

**`tag_accuracy` ESTAGNADO há 6 dias.** Os mesmos 22 registros desde 2026-05-27 — nenhuma atualização de precisão, nenhum novo dado de fp/fn. O pipeline de tagging não está evoluindo.

**Achado crítico:** Importação em bulk de 20 cartas sem classificação no deck "Lorehold Best-of Learned No Premium Mox 2026-06-02". Nenhum agente do pipeline (Scout, Validator, Mulligan, Evolution Oracle) consegue analisar este deck. O script de importação precisa ser corrigido.

**Top 3 ações:**
1. 🔴 Rodar classificador no novo deck Lorehold (20 cartas 'unknown')
2. 🔴 Corrigir script de importação para executar classificação pós-insert
3. 🟡 Atualizar `tag_accuracy` com dados dos decks existentes
