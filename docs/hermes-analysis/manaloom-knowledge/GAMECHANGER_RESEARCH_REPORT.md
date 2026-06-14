# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: computed from 3108 distinct cards, 3217 rows -->
<!-- EXEC: 14 | 2026-06-14 -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 54 Game Changers oficiais.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-14 (execução #14)
**Fonte:** `scripts/knowledge.db` + simulação local de `tagCardForBracket()`
**Nota:** A tabela `game_changers` não existe no SQLite local (apenas no PostgreSQL). Usamos `card_oracle_cache` + heurísticas para análise.
**card_oracle_cache:** 3.217 rows, 3.108 nomes únicos — reimport em 2026-06-14T00:56:17Z

---

## 🔴 Resumo Executivo — Mudanças desde Execução #13 (2026-06-13)

### Cobertura de GCs PIOROU: 20/54 (37.0%) Missing vs ~28.3% na Exec #13

| Métrica | Exec #13 (06-13) | Exec #14 (06-14) | Delta |
|:--------|:----------------:|:----------------:|:------|
| GCs missing | ~15 (~28%) | **20 (37.0%)** | 🔴 **+5 (REGRESSÃO)** |
| GCs presentes | ~38 (~72%) | **34 (63.0%)** | 🔴 **-4 (REGRESSÃO)** |
| Última reimport | 2026-06-13T00:26Z | 2026-06-14T00:56Z | 🔄 Nova reimport |
| Nulos oracle_text | 3 | 4 | 🟡 +1 |
| Nulos mana_cost | — | 364 (11.3%) | 🟡 Novo |
| Zero-CMC (all) | 69 (GCs only) | 432 (13.4% do cache) | 🟡 Generalizado |

**⚠️ Nota metodológica:** A Exec #13 usou uma lista expandida (não-oficial) de 53 GCs que incluía cartas como Armageddon, Fierce Guardianship, Enlightened Tutor, etc. — cartas que **não estão na lista oficial de Game Changers do Wizards Bracket System**. A Exec #14 usa a lista oficial de 54 GCs. A cobertura REAL de GCs oficiais sempre foi pior do que a Exec #13 reportava.

---

## 🔴 Lacuna A (AGRAVADA): 20/54 GCs (37%) Missing do card_oracle_cache

**Nenhum dos 15 GCs originais foi restaurado.** 5 GCs adicionais foram identificados como ausentes.

### Os 15 GCs originais (ainda missing, nenhuma restauração):

| GC | Status | Observação |
|:---|:-------|:-----------|
| Biorhythm | ❌ Missing | Banido |
| Braids, Cabal Minion | ❌ Missing | Banido |
| Channel | ❌ Missing | Banido |
| Coalition Victory | ❌ Missing | Banido |
| Dockside Extortionist | ❌ Missing | Banido |
| Emrakul, the Aeons Torn | ❌ Missing | Banido |
| Expropriate | ❌ Missing | 🟢 **LEGAL — refuta filtro de banned** |
| Fastbond | ❌ Missing | Banido |
| Hermit Druid | ❌ Missing | Banido |
| Jeweled Lotus | ❌ Missing | Banido |
| Panoptic Mirror | ❌ Missing | 🟢 **LEGAL — refuta filtro de banned** |
| Serra's Sanctum | ❌ Missing | 🟢 LEGAL |
| Tergrid, God of Fright | ❌ Missing | DFC — handling quebrado |
| Tinker | ❌ Missing | Banido |
| Tolarian Academy | ❌ Missing | Banido |

### 5 GCs NOVAMENTE confirmados como ausentes (não apareciam na Exec #13 porque a lista dela era diferente):

| GC | Observação |
|:---|:-----------|
| **Back to Basics** | 🟢 LEGAL, carta azul de stax |
| **Dark Depths** | 🟢 LEGAL, combo com Thespian's Stage |
| **Mind Twist** | ❌ Banido |
| **Moat** | 🟢 LEGAL, carta branca de controle |
| **Nether Void** | 🟢 LEGAL, stax preta |

**Total: 20 missing (37.0%).** 5 cartas LEGAIS estão entre os missing: Expropriate, Panoptic Mirror, Serra's Sanctum, Back to Basics, Dark Depths, Moat, Nether Void = 7 cartas legais. Isto confirma que **não é apenas filtro de banned** — há pelo menos 2 causas adicionais (DFC handling + causa desconhecida).

### Hipótese Revisada (v14):
1. **Filtro de banned** → remove ~13 das 20 missing (Biorhythm, Braids, Channel, Coalition Victory, Dockside, Emrakul, Fastbond, Hermit Druid, Jeweled Lotus, Mind Twist, Tinker, Tolarian Academy)
2. **DFC handling quebrado** → Tergrid (// no nome) excluído
3. **Causa desconhecida** → Expropriate, Panoptic Mirror, Serra's Sanctum, Back to Basics, Dark Depths, Moat, Nether Void (7 cartas legais, não-DFC)

---

## Lacuna B: 13/34 GCs Presentes (38%) com Categoria 'other' — Gap de Heurística

A simulação de `tagCardForBracket()` não consegue classificar funcionalmente 13 dos 34 GCs presentes no cache. Todos caem em `other`:

| GC | Categoria Esperada | Oracle Text (resumo) |
|:---|:------------------|:---------------------|
| Food Chain | `infiniteCombo` | Exila criatura → adiciona mana X+1 |
| Gaea's Cradle | `fastMana` | T: Adiciona G por criatura |
| Humility | `stax` | Todas as criaturas perdem habilidades, base 1/1 |
| Lion's Eye Diamond | `fastMana` | Descarta mão, saca → 3 mana |
| Loyal Retainers | `tutor` (de GY) | Sac: retorna lendária do GY |
| Mox Diamond | `fastMana` | Entra se descartar land, T: Add 1 |
| Necropotence | `valueEngine` | Skip draw step, pay life → exile top card |
| Parallel Lives | `valueEngine` | Dobra tokens |
| Tainted Pact | `tutor` (conditional) | Exile top até achar nome duplicado |
| Torment of Hailfire | `boardWipe` | Cada oponente perde 3 life ou sacrifica |
| Underworld Breach | `infiniteCombo` | Escape do GY por 3 exiles |
| Urza, Lord High Artificer | `valueEngine` | Tap artifact → add U, construct token |
| Yawgmoth's Will | `valueEngine` | Play lands and cast spells from GY |

**Impacto:** 38% dos GCs presentes não podem ser categorizados funcionalmente por heurística, comprometendo qualquer análise de bracket que dependa exclusivamente de oracle_text.

---

## 🟡 Lacuna C: Dados Corrompidos — mana_cost Vazio e CMC=0.0

| Problema | Contagem | % do cache | Exemplos |
|:---------|:--------:|:----------:|:---------|
| `mana_cost` nulo/vazio | 364 | 11.3% | Terrenos, MDFCs sem face de feitiço |
| CMC = 0.0 | 432 | 13.4% | Inclui 364 sem mana_cost + 68 terrenos |
| `oracle_text` nulo/vazio | 4 | 0.1% | Dwarven Trader, Memnite, Phyrexian Walker |

**Impacto:** O CMC fallback chain (`cmc_safety.dart`) mitiga no código de produto, mas análises em batch e scripts diretos contra o cache produzem métricas distorcidas.

---

## GCs no Deck #6 (Lorehold)

O deck ativo contém **4 GCs oficiais**, todos presentes no cache com dados adequados:

| GC | CMC | Bracket (simulado) | Oracle Text OK? |
|:---|:---:|:------------------:|:---------------:|
| Ancient Tomb | 0.0 | fastMana | ✅ |
| Mana Vault | 1.0 | fastMana | ✅ |
| Sol Ring | 1.0 | fastMana | ✅ |
| Wheel of Fortune | 3.0 | cardAdvantage | ✅ |

**Nada a reportar — dados do deck GCs estão íntegros.**

---

## 📊 Métricas de Qualidade — Exec #13 vs Exec #14

| Métrica | Exec #13 | Exec #14 | Delta |
|:--------|:--------:|:--------:|:------|
| GCs missing (oficiais) | ~15/53 (usando lista errada) | **20/54 (oficial)** | 🔴 **+5 vs baseline correto** |
| GCs presentes no cache (reais) | ~34 | 34 | → Estável |
| Tabela game_changers no SQLite | ❌ Ausente | ❌ Ausente | → Persiste |
| Última reimport | 2026-06-13T00:26Z | 2026-06-14T00:56Z | 🔄 Nova |
| GCs sem categoria funcional | 22+ (estimado) | 13/34 (38%) | 🟡 Confirmado |
| GCs com mana_cost vazio | 5 (entre GCs) | 364 (cache-wide) | 🟡 Piorou (dado amplo) |
| GCs com price_usd=NULL | 36/38 | N/A (sem coluna no SQLite) | — |
| DFCs no cache | 221 | 221 | → Estável |

---

## 🎯 Recomendações

1. **🔴 CRÍTICO — Restaurar 20 GCs perdidos:** Investigar script de sync PG→SQLite. Há pelo menos 3 causas de exclusão (banned filter, DFC, desconhecida). Expropriate e 6 outras cartas legais estão ausentes — o filtro não é só de banned.

2. **🔴 CRÍTICO — Adicionar validação pós-sync:** Após cada reimport, verificar que os 54 GCs oficiais estão no cache. Se < 54, abortar ou alertar.

3. **🔴 CRÍTICO — Corrigir DFC handling:** Tergrid continua ausente em 4+ reimports consecutivas. O `//` no nome quebra o match.

4. **🟡 Melhorar heurísticas de bracket:** 38% dos GCs presentes caem em `other`. Adicionar heurísticas para `fastMana` (terrenos que produzem >1 mana, rochas com mana), `valueEngine` (engines de upkeep/cast), `infiniteCombo` (combos conhecidos: Underworld Breach + LED, Food Chain + Eternal Scourge).

5. **🟡 Corrigir 364 mana_cost vazios e 432 CMC=0.0:** O fallback `cmc_safety.dart` mitiga no produto, mas scripts contra o raw DB produzem métricas inválidas.

6. **🟡 Sanitizar price_usd=NULL:** Cards Reserved List têm preço NULL da Scryfall. Marcar como `RESERVED_LIST` ao invés de NULL.

---

## ⚠️ Observações Metodológicas

- A análise é 100% local (SQLite + heurísticas). Sem a tabela `game_changers` (PG-only), métricas oficiais de detecção não são verificáveis.
- A lista de GCs oficiais do Wizards Bracket System tem 54 cartas (não 53). Cartas como Armageddon, Fierce Guardianship, Enlightened Tutor **não são GCs oficiais** — estavam na lista da Exec #13 erroneamente.
- A simulação `tagCardForBracket()` é simplificada. O código Dart `edh_bracket_policy.dart` tem 11 categorias oficiais com heurísticas mais precisas.
- **Próxima execução:** Verificar se os 20 GCs foram restaurados. Se o cache continuar perdendo GCs após reimports, o problema é no script de sync e precisa de correção no código.
