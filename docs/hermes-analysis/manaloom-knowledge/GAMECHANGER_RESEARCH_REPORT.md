# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: product-check from 3217 rows, 3108 distinct cards -->
<!-- EXEC: 16 | 2026-06-15 -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 53 Game Changers oficiais do produto (`edh_bracket_policy.dart`).
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-15 (execução #16)
**Fonte:** `scripts/knowledge.db` + `edh_bracket_policy.dart` + análise local de `card_oracle_cache`
**Nota:** A tabela `game_changers` não existe no SQLite local (apenas no PostgreSQL). Usamos `card_oracle_cache` + heurísticas para análise.
**card_oracle_cache:** 3.217 rows, 3.108 nomes únicos

---

## 🔴 CRÍTICO: Relatório Anterior Usava Lista de GCs EQUIVOCADA

**As execuções #10-#15 do gamechanger-research usavam uma lista de "54 GCs oficiais do Wizards" que NÃO corresponde à lista real do produto.**

O produto (`edh_bracket_policy.dart` linhas 354-408) define **53 Game Changers** — uma lista CUSTOM que difere significativamente da lista standard da Wizards. Das cartas que o relatório anterior considerava "missing":

| Cartas na lista "22 missing" do Exec #15 | Na lista do produto? |
|:------------------------------------------|:-------------------:|
| Biorhythm | ✅ Sim — mas BANIDO |
| Braids, Cabal Minion | ✅ Sim — mas BANIDO |
| Coalition Victory | ✅ Sim — mas BANIDO |
| Panoptic Mirror | ✅ Sim — 🟢 LEGAL |
| Serra's Sanctum | ✅ Sim — 🟢 LEGAL |
| Tergrid, God of Fright | ✅ Sim — mas como DFC |
| Aeon Engine | ❌ **Não é GC do produto** |
| Back to Basics | ❌ **Não é GC do produto** |
| Channel | ❌ **Não é GC do produto** |
| Dark Depths | ❌ **Não é GC do produto** |
| Dockside Extortionist | ❌ **Não é GC do produto** |
| Emrakul, the Aeons Torn | ❌ **Não é GC do produto** |
| Expropriate | ❌ **Não é GC do produto** |
| Fastbond | ❌ **Não é GC do produto** |
| Hermit Druid | ❌ **Não é GC do produto** |
| Jeweled Lotus | ❌ **Não é GC do produto** |
| Library of Alexandria | ❌ **Não é GC do produto** |
| Mind Twist | ❌ **Não é GC do produto** |
| Moat | ❌ **Não é GC do produto** |
| Nether Void | ❌ **Não é GC do produto** |
| Tinker | ❌ **Não é GC do produto** |
| Tolarian Academy | ❌ **Não é GC do produto** |

**17/22 cartas que o relatório antigo reportava como "missing" simplesmente não são Game Changers no produto ManaLoom.** A cobertura REAL é **88.7% (47/53)** — não 59.3%.

---

## Cobertura Real: 47/53 (88.7%) dos GCs do Produto

| Métrica | Valor |
|:--------|:-----|
| GCs do produto (Dart code) | 53 |
| Presentes no card_oracle_cache | **47 (88.7%)** |
| Missing | **6 (11.3%)** |
| Tabela game_changers no SQLite | ❌ Ausente (PG-only) |
| Cache rows | 3.217 |
| mana_cost null/empty | 364 (11.3%) |
| CMC=0.0 | 431 (13.4%) |
| oracle_text null/empty | 4 (0.1%) |

---

## 🔴 Lacuna A: 6 GCs do Produto Missing do card_oracle_cache

| GC | Status Legal | Causa Provável |
|:---|:-----------:|:---------------|
| Biorhythm | ❌ BANIDO | Removido por filtro de banned no sync |
| Braids, Cabal Minion | ❌ BANIDO | Removido por filtro de banned. "Braids, Arisen Nightmare" (carta diferente) existe no cache |
| Coalition Victory | ❌ BANIDO | Removido por filtro de banned |
| Panoptic Mirror | 🟢 **LEGAL** | Causa desconhecida — não é banned, não é DFC. SYNCHRONIZATION GAP |
| Serra's Sanctum | 🟢 **LEGAL** | Causa desconhecida — não é banned, não é DFC. SYNCHRONIZATION GAP |
| Tergrid, God of Fright // Tergrid's Lantern | 🟢 LEGAL | DFC — `//` no nome quebra sincronização. NENHUM registro "tergrid*" existe no cache |

**3/6 missing são cartas BANIDAS** — podem estar sendo removidas intencionalmente pelo script de sync PG→SQLite (se o sync filtra banned cards). **Mas 3/6 são LEGAIS** e deveriam estar no cache: Panoptic Mirror, Serra's Sanctum, Tergrid. A ausência delas é um bug.

---

## Lacuna B: Cobertura de Categorias Funcionais

Os 47 GCs presentes foram verificados no cache. Destes:
- **Todos têm oracle_text** (0 GCs com oracle_text nulo)
- **Todos têm nome correto no cache** (case-insensitive match OK)
- **DFCs**: Apenas Tergrid está missing (confirmado). Os outros DFCs não estão na lista de GCs.

**Cartas notáveis presentes no cache:**
- `Force of Will`, `Fierce Guardianship` — free interaction spells
- `Cyclonic Rift`, `Rhystic Study`, `Smothering Tithe` — staples do formato
- `Thassa's Oracle`, `Demonic Tutor`, `Vampiric Tutor` — combos e tutores
- `The One Ring`, `Orcish Bowmasters` — cartas recentes de alto impacto

**Cartas LEGAIS e de alto valor no cache:**
- `Gaea's Cradle` ($500+), `Mishra's Workshop` ($2000+), `The Tabernacle at Pendrell Vale` ($2000+)
- Todas as 8 cartas tipo "fast mana" (Mox Diamond, Mana Crypt, Mana Vault, Chrome Mox, Lion's Eye Diamond, Grim Monolith, Ancient Tomb, Mishra's Workshop)
- Todos os 7 tutores (Vampiric, Demonic, Enlightened, Mystical, Worldly, Gamble, Imperial Seal)

---

## 📊 Comparação: Exec #15 (relatório antigo) vs Exec #16 (corrigido)

| Métrica | Exec #15 (antigo) | Exec #16 (corrigido) | Delta |
|:--------|:-----------------:|:--------------------:|:------|
| Lista de GCs usada | 54 "Wizards oficiais" | **53 do produto (Dart)** | 🔴 Lista errada corrigida |
| GCs missing | 22 (40.7%) | **6 (11.3%)** | ✅ Dramaticamente melhor |
| GCs cobertos | 32 (59.3%) | **47 (88.7%)** | ✅ Realidade muito melhor |
| Cache rows | 3.217 | 3.217 | → Idêntico |
| Cache expulsão | Aeon Engine + Library of Alexandria sumiram | Aeon Engine e Library NÃO SÃO GCs do produto | ⚠️ Falso alarme |
| mana_cost null | 364 (11.3%) | 364 (11.3%) | → Idêntico |
| CMC=0.0 | 431 (13.4%) | 431 (13.4%) | → Idêntico |
| oracle_text null | 4 (0.1%) | 4 (0.1%) | → Idêntico |

---

## 🎯 Recomendações

### 🔴 Prioridade Crítica

1. **Corrigir metodologia do relatório**: A fonte de verdade para GCs é `edh_bracket_policy.dart` (linhas 354-408), NÃO uma lista externa da Wizards. O relatório anterior gerou 6+ execuções de falsos alarmes.
2. **Adicionar Panoptic Mirror e Serra's Sanctum ao card_oracle_cache**: Ambas são legais e parte da lista de GCs do produto. A ausência afeta detecção de GCs.
3. **Corrigir DFC handling para Tergrid**: Tergrid está completamente ausente (nem no cache). A função `_isOfficialGameChangerName()` no Dart lida com `//` no nome, mas o script de sync não importa a carta. O problema não é do software — é de sincronização PG→SQLite.

### 🟡 Prioridade Média

4. **Sincronizar documentação**: `manaloom-mtg-domain` §Gap 27, 29 e o relatório `GAMECHANGER_RESEARCH_REPORT.md` antigo devem ser corrigidos para refletir a lista real do produto.
5. **Verificar filtro de banned no sync**: Se o sync PG→SQLite remove cartas banned antes de inserir no `card_oracle_cache`, isso explica Biorhythm, Braids, e Coalition Victory. Mas é um design questionável — o cache de oracle card deve ter TODAS as cartas, independente de banlist.
6. **Auditar game_changers no SQLite**: A tabela `game_changers` é PG-only. Se um dia for sincronizada para SQLite, deve usar a lista do Dart, não a lista Wizards.

### 🟢 Baixa Prioridade

7. **Os 3 GCs banned (Biorhythm, Braids, Coalition Victory) não são urgentes** — estão banned e não impactam análise de legalidade. Mas idealmente deveriam estar no cache para análises completas de conjunto.

---

## ⚠️ Observações Metodológicas

- **Fonte de verdade para GCs:** `edh_bracket_policy.dart:354-408` — 53 cartas em lower case.
- A análise é 100% local (SQLite + heurísticas). Sem a tabela `game_changers` (PG-only), métricas oficiais de detecção não são verificáveis.
- **Cache row count em 3.217** — estável desde Exec #14.
- **Próxima execução:** Repetir contra a lista de 53 GCs do produto. Verificar se os 6 missing foram restaurados.
