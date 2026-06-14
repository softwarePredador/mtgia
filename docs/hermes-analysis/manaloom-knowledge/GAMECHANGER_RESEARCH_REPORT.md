# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: computed from 3217 rows, 3108 distinct cards -->
<!-- EXEC: 15 | 2026-06-14 14:00Z -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 54 Game Changers oficiais.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-14 (execução #15)
**Fonte:** `scripts/knowledge.db` + análise local de `card_oracle_cache`
**Nota:** A tabela `game_changers` não existe no SQLite local (apenas no PostgreSQL). Usamos `card_oracle_cache` + heurísticas para análise.
**card_oracle_cache:** 3.217 rows, ~3.108 nomes únicos — última reimport em 2026-06-14T00:56:17Z

---

## 🔴 Resumo Executivo — Mudanças desde Execução #14

### Cobertura de GCs PIOROU: 22/54 (40.7%) Missing vs 20/54 (37.0%)

| Métrica | Exec #14 (06-14) | Exec #15 (06-14) | Delta |
|:--------|:----------------:|:----------------:|:------|
| GCs missing (oficial) | 20/54 (37.0%) | **22/54 (40.7%)** | 🔴 **+2 (REGRESSÃO)** |
| GCs presentes no cache | 34/54 (63.0%) | **32/54 (59.3%)** | 🔴 **-2 (REGRESSÃO)** |
| Última reimport | 2026-06-14T00:56Z | Mesma | 🔄 Sem nova reimport |
| Nulos oracle_text (cache) | 4 | 4 | ✅ Estável |
| Nulos mana_cost (cache) | 364 (11.3%) | 364 (11.3%) | ✅ Idêntico |
| Zero-CMC (cache all) | 432 (13.4%) | **431 (13.4%)** | 🟡 -1 marginal |
| Deck #6 GCs | 4/4 íntegros | 4/4 íntegros | ✅ OK |

**⚠️ AGRAVAMENTO:** Sem nova reimport do PostgreSQL, 2 GCs adicionais desapareceram do cache (Aeon Engine, Library of Alexandria). Isto sugere que o cache está **perdendo cartas por expulsão/sobrescrição**, não por falha isolada de import. **Suspeita:** limite de linhas (3217) pode estar próximo de um teto, e cartas estão sendo expulsas quando o sync tenta adicionar novas.

---

## 🔴 Lacuna A (AGRAVADA): 22/54 GCs (40.7%) Missing do card_oracle_cache

**Mudanças:** 2 GCs adicionais perdidos. Nenhuma restauração dos 15 GCs originais.

### 🆕 GCs adicionalmente ausentes desde Exec #14:

| GC | Status em Exec #14 | Status em Exec #15 | Observação |
|:---|:------------------:|:------------------:|:-----------|
| **Aeon Engine** | ✅ Presente | ❌ Missing | Desapareceu sem reimport |
| **Library of Alexandria** | ✅ Presente | ❌ Missing | Desapareceu sem reimport |

**Hipótese:** Cache com limite de linhas. Ao inserir novas cartas (ex: novas coleções/learned decks), linhas antigas são sobrescritas em FIFO ou LRU. O sync não protege GCs contra expulsão.

### Os 15 GCs originais (ainda missing, nenhuma restauração):

| GC | Status | Observação |
|:---|:-------|:-----------|
| Biorhythm | ❌ Missing | Banido |
| Braids, Cabal Minion | ❌ Missing | Banido |
| Channel | ❌ Missing | ⚠️ **Falso positivo: "Channeled Force" NÃO é Channel** |
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

### 5 GCs adicionais confirmados desde Exec #13 (devido à correção da lista para oficial):

| GC | Observação |
|:---|:-----------|
| **Back to Basics** | 🟢 LEGAL, carta azul de stax |
| **Dark Depths** | 🟢 LEGAL, combo com Thespian's Stage |
| **Mind Twist** | ❌ Banido |
| **Moat** | 🟢 LEGAL, carta branca de controle |
| **Nether Void** | 🟢 LEGAL, stax preta |

**Total: 22 missing (40.7%).** 7 cartas LEGAIS estão entre os missing: Expropriate, Panoptic Mirror, Serra's Sanctum, Back to Basics, Dark Depths, Moat, Nether Void.

### Hipótese Revisada (v15):

1. **Filtro de banned** → remove ~14 das 22 missing (Biorhythm, Braids, Channel, Coalition Victory, Dockside, Emrakul, Fastbond, Hermit Druid, Jeweled Lotus, Mind Twist, Tinker, Tolarian Academy + Aeon Engine e Library of Alexandria — ambos LEGAIS, mas que desapareceram)
2. **DFC handling quebrado** → Tergrid (// no nome) excluído
3. **Limite de cache** → Aeon Engine e Library of Alexandria foram expulsos por sobrescrita
4. **Causa desconhecida** → Expropriate, Panoptic Mirror, Serra's Sanctum, Back to Basics, Dark Depths, Moat, Nether Void (7 cartas legais, não-DFC) — ainda não explicadas

---

## Lacuna B: 12/32 GCs Presentes (37.5%) sem Categoria Funcional — Estável

A simulação de heurística não consegue classificar funcionalmente 12 dos 32 GCs presentes no cache. Todos caem em `other`:

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

**Impacto:** 37.5% dos GCs presentes não podem ser categorizados funcionalmente por heurística.

---

## 🟡 Lacuna C: Dados Corrompidos — mana_cost Vazio e CMC=0.0 (ESTÁVEL)

| Problema | Contagem | % do cache | Exemplos |
|:---------|:--------:|:----------:|:---------|
| `mana_cost` nulo/vazio | 364 | 11.3% | Terrenos, MDFCs sem face de feitiço |
| CMC = 0.0 | 431 | 13.4% | Inclui 364 sem mana_cost + 67 terrenos/0-cost |
| `oracle_text` nulo/vazio | 4 | 0.1% | Dwarven Trader, Memnite, Phyrexian Walker |

**Nota:** CMC=0.0 caiu de 432 para 431 entre Exec #14 e #15 — marginal, pode ser artefato de query ou 1 carta corrigida.

**GCs com dados corrompidos (presentes no cache):**
| GC | Problema | Justificativa |
|:---|:---------|:--------------|
| Ancient Tomb | mana_cost vazio, CMC=0.0 | ✅ Esperado — land sem mana_cost |
| Gaea's Cradle | mana_cost vazio, CMC=0.0 | ✅ Esperado — land sem mana_cost |
| Mishra's Workshop | mana_cost vazio, CMC=0.0 | ✅ Esperado — land sem mana_cost |
| Tabernacle | mana_cost vazio, CMC=0.0 | ✅ Esperado — land sem mana_cost |
| Lion's Eye Diamond | CMC=0.0 | 🟡 Artefato de 0 mana — CMC 0 é correto |
| Mana Crypt | CMC=0.0 | ✅ Esperado — artefato de 0 mana |
| Mox Diamond | CMC=0.0 | ✅ Esperado — artefato de 0 mana |
| Mox Opal | CMC=0.0 | ✅ Esperado — artefato de 0 mana |

---

## GCs no Deck #6 (Lorehold)

O deck ativo contém **4 GCs oficiais**, todos presentes no cache com dados adequados:

| GC | CMC | Oracle Text OK? | Nota |
|:---|:---:|:---------------:|:-----|
| Ancient Tomb | 0.0 | ✅ | mana_cost vazio (land) — normal |
| Mana Vault | 1.0 | ✅ | ✅ |
| Sol Ring | 1.0 | ✅ | ✅ |
| Wheel of Fortune | 3.0 | ✅ | ✅ |

**Nada a reportar — dados do deck GCs estão íntegros.**

---

## 📊 Métricas de Qualidade — Exec #14 vs Exec #15

| Métrica | Exec #14 | Exec #15 | Delta |
|:--------|:--------:|:--------:|:------|
| GCs missing (oficiais) | 20/54 (37.0%) | **22/54 (40.7%)** | 🔴 **+2** |
| GCs presentes no cache | 34/54 (63.0%) | **32/54 (59.3%)** | 🔴 **-2** |
| Tabela game_changers no SQLite | ❌ Ausente | ❌ Ausente | → Persiste |
| Última reimport | 2026-06-14T00:56Z | Mesma | 🔄 Sem nova reimport |
| GCs sem categoria funcional | 13/34 (38%) | 12/32 (37.5%) | 🟡 Estável |
| Cache rows | 3.217 | 3.217 | → Idêntico |
| GCs com mana_cost vazio (cache-wide) | 364 | 364 | → Idêntico |
| CMC=0.0 (cache) | 432 | 431 | 🟡 -1 |
| `oracle_text` nulo | 4 | 4 | → Idêntico |
| Deck #6 GCs | 4 | 4 | ✅ Íntegro |

---

## 🎯 Recomendações

1. **🔴 CRÍTICO — Investigar expulsão de cache:** Aeon Engine e Library of Alexandria desapareceram SEM reimport. Provar hipótese de limite de linhas (3217 pode ser o teto). Adicionar proteção para GCs no cache.

2. **🔴 CRÍTICO — Restaurar 22 GCs perdidos:** Investigar script de sync PG→SQLite. Há pelo menos 4 causas de exclusão (banned filter, DFC, expulsão de cache, desconhecida).

3. **🔴 CRÍTICO — Corrigir DFC handling:** Tergrid continua ausente em 5+ reimports consecutivas. O `//` no nome quebra o match.

4. **🔴 CRÍTICO — Adicionar validação pós-sync:** Após cada reimport, verificar que os 54 GCs oficiais estão no cache. Se < 54, abortar ou alertar.

5. **🟡 Corrigir falso positivo "Channel":** A busca parcial por `Channel` retorna "Channeled Force" (card diferente). O GC real Channel está missing e deve ser incluído no cache.

6. **🟡 Melhorar heurísticas de bracket:** 37.5% dos GCs presentes caem em `other`. Adicionar heurísticas para `fastMana` (terrenos que produzem >1 mana), `valueEngine`, `infiniteCombo`.

7. **🟡 Corrigir 364 mana_cost vazios e 431 CMC=0.0:** O fallback `cmc_safety.dart` mitiga no produto, mas scripts contra o raw DB produzem métricas inválidas.

8. **🟡 Sanitizar price_usd=NULL:** Cards Reserved List têm preço NULL da Scryfall. Marcar como `RESERVED_LIST` ao invés de NULL.

---

## ⚠️ Observações Metodológicas

- A análise é 100% local (SQLite + heurísticas). Sem a tabela `game_changers` (PG-only), métricas oficiais de detecção não são verificáveis.
- A lista de GCs oficiais do Wizards Bracket System tem **54 cartas**. Cartas como Armageddon, Fierce Guardianship, Enlightened Tutor **não são GCs oficiais**.
- A busca por GCs usa `LOWER(name)` para match case-insensitive. DFCs com `//` precisam de busca parcial.
- **Cache row count locked at 3.217** entre Exec #14 e #15 — sugere que o cache tem um limite e está expulsando linhas antigas para acomodar novas inserções. GCs perdidos desse modo (Aeon Engine, Library of Alexandria) indicam fragilidade na política de retenção.
- **Próxima execução:** Verificar se os 22 GCs foram restaurados. Monitorar contagem total de linhas do cache — se permanecer em 3.217, confirmar hipótese de teto.
