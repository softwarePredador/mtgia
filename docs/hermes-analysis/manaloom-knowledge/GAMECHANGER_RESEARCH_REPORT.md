# Game Changer Research Report — Lacunas e Recomendações

<!-- DB_HASH: 0ae3f1c8b2 (card_oracle_cache: 3108 distinct cards, 3217 rows) -->
<!-- EXEC: 13 | 2026-06-13 -->
> Gerado automaticamente pelo cron `manaloom-gamechanger-research`.
> Objetivo: identificar lacunas de explicação, categoria ou detecção nos 53 Game Changers.
> Este relatório é **read-only** — não altera DB nem produto.

**Data:** 2026-06-13 (execução #13)
**Fonte:** `scripts/knowledge.db` + `server/lib/edh_bracket_policy.dart`
**Nota:** A tabela `game_changers` não existe no SQLite local (apenas no PostgreSQL). A análise usa `card_oracle_cache` + simulação da `tagCardForBracket()` do Dart.
**card_oracle_cache:** 3.217 cartas — **NOVA reimport PG→SQLite em 2026-06-13T00:26:34Z** (4ª reimport desde 12/Jun)

---

## 🔴 Resumo Executivo — Mudanças desde Execução #12 (2026-06-12 12:33Z)

### DB Reimportado Novamente (00:26Z): 9 New GCs Missing — Total 15

O `card_oracle_cache` foi reimportado do PostgreSQL pela **quarta vez** (3ª em 12/Jun, 1ª em 13/Jun). O total de cartas continua 3.217. **9 GCs adicionais estão agora confirmados como ausentes** que não estavam na contagem de "47/53 presentes" da Exec #12.

| Métrica | Exec #12 (12:33Z) | Exec #13 (00:26Z) | Delta |
|:--------|:-----------------:|:-----------------:|:------|
| GCs missing | **6** (11.3%) | **15** (28.3%) | 🔴 **+9 (REGRESSÃO)** |
| GCs presentes no cache | **47** (88.7%) | **38** (71.7%) | 🔴 **-9 (REGRESSÃO)** |
| Detection rate | 24/53 (~45%) | 24/53 (~45%) | → Estável (não verificável localmente) |
| Total cards | 3.217 | 3.217 | → Estável |
| GCs sem categoria funcional | 22 | 22+ | → Estimado |
| DB reimport timestamp | 2026-06-12T12:33Z | 2026-06-13T00:26Z | 🔄 Nova reimport |

### 🔴 REGRESSÃO CRÍTICA: 9 Novos GCs Perdidos desde Exec #12

A Exec #12 reportava **47/53 GCs presentes** no cache. Agora são **38/53**. 9 GCs adicionais estão ausentes:

| GC | Formato | Hipótese |
|:---|:--------|:---------|
| **Expropriate** | 🟢 Legal no Commander | **🔴 Refuta hipótese de filtro de banned.** Carta legal está faltando. |
| **Channel** | ❌ Banido no Commander | Corrobora filtro de banned? Mas Expropriate legal também falta. |
| **Dockside Extortionist** | ❌ Banido no Commander | Pode ser vítima de filtro OU exclusão separada. |
| **Emrakul, the Aeons Torn** | ❌ Banido no Commander | `Emrakul, the Promised End` (legal) está presente. Padrão: Emrakul banida foi excluída. |
| **Fastbond** | ❌ Banido no Commander | Carta clássica banida. |
| **Hermit Druid** | ❌ Banido no Commander | Carta banida. |
| **Jeweled Lotus** | ❌ Banido no Commander | Carta banida recentemente (set/2024). |
| **Tinker** | ❌ Banido no Commander | Carta banida. |
| **Tolarian Academy** | ❌ Banido no Commander | Carta banida. |

**8 das 9 cartas perdidas são banidas no Commander.** Expropriate é a exceção — e a mais preocupante, pois é **legal** e amplamente jogada (EDHREC ~25% dos decks azuis). Se uma carta legal como Expropriate está sendo excluída do sync, o problema é mais amplo que "filtro de banned."

**Hipótese revisada:** O sync PG→SQLite tem **múltiplas causas de exclusão**:
1. **Filtro de cards banned** (8/15 missing GCs são banned) — responsável pela maioria
2. **DFC handling incorreto** (Tergrid — única DFC entre os 53 GCs)
3. **Causa desconhecida** (Expropriate, Panoptic Mirror, Serra's Sanctum — legais e não-DFC)

---

## 🔴 Lacuna 20 (NOVA): 9 New Missing GCs + Expropriate Refuta Filtro de Banned

| Campo | Valor |
|:------|:------|
| **GCs afetados** | 9 novos: Channel, Dockside Extortionist, Emrakul the Aeons Torn, **Expropriate**, Fastbond, Hermit Druid, Jeweled Lotus, Tinker, Tolarian Academy |
| **Problema** | Exec #12 contava 47/53 presentes. Agora são 38/53. Os 6 originais (Tergrid, Panoptic, Sanctum, Biorhythm, Coalition Victory, Braids) permanecem missing. 9 adicionais foram perdidos ou detectados pela primeira vez. |
| **Evidência** | `SELECT LOWER(name) FROM card_oracle_cache WHERE LOWER(name) = 'expropriate'` → 0 rows. `LIKE '%expropriate%'` → 0 rows. A carta não existe no cache local. |
| **Impacto** | 9/10 — 28% dos GCs não podem ser analisados localmente. A detecção de GCs em decks depende exclusivamente do PG. |
| **Risco de falso positivo** | 🟢 Baixo — Consulta direta ao cache confirma ausência. |
| **Possível regra futura** | Pós-sync: verificar que os 53 GCs estão no cache. Se < 53, alertar imediatamente. |

### Detalhamento: Status de Cada GC no card_oracle_cache

| Status | Contagem | GCs |
|:-------|:--------:|:----|
| **✅ Presente** | **38** | Ancient Tomb, Armageddon, Bolas's Citadel, Cryptic Command, Cyclonic Rift, Demonic Consultation, Demonic Tutor, Enlightened Tutor, Field of the Dead, Fierce Guardianship, Force of Will, Gaea's Cradle, Grim Monolith, Imperial Seal, Imperial Recruiter, Intuition, Lim-Dûl's Vault, Lion's Eye Diamond, Mana Crypt, Mana Drain, Mana Vault, Mishra's Workshop, Mox Diamond, Mox Opal, Mystic Remora, Mystical Tutor, Natural Order, Necropotence, Palinchron, Personal Tutor, Ravages of War, Rhystic Study, Smothering Tithe, Sneak Attack, Sol Ring, Survival of the Fittest, The Tabernacle at Pendrell Vale, Timetwister |
| **❌ Missing** | **15** | Biorhythm, Braids-Cabal Minion, Channel, Coalition Victory, Dockside Extortionist, Emrakul-the Aeons Torn, Expropriate, Fastbond, Hermit Druid, Jeweled Lotus, Panoptic Mirror, Serra's Sanctum, Tergrid-God of Fright, Tinker, Tolarian Academy |

### Distribuição por Categoria (simulação tagCardForBracket)

| Categoria | GCs | Cartas |
|:----------|:---:|:-------|
| `fastMana` | 9 | Ancient Tomb, Grim Monolith, Lion's Eye Diamond, Mana Crypt, Mana Vault, Mishra's Workshop, Mox Diamond, Mox Opal, Sol Ring |
| `tutor` | 10 | Demonic Consultation, Demonic Tutor, Enlightened Tutor, Imperial Recruiter, Imperial Seal, Intuition, Mystical Tutor, Natural Order, Personal Tutor, Survival of the Fittest |
| `freeInteraction` | 6 | Cyclonic Rift, Fierce Guardianship, Force of Will, Mana Drain, Mystic Remora, Rhystic Study |
| `card_advantage` | 3 | Cryptic Command, Smothering Tithe, Timetwister |
| `board_wipe` | 2 | Armageddon, Ravages of War |
| `infiniteCombo` | 2 | Bolas's Citadel, Palinchron |
| `value_engine` | 1 | The Tabernacle at Pendrell Vale |
| `other` | 5 | Field of the Dead, Gaea's Cradle, Lim-Dûl's Vault, Necropotence, Sneak Attack |
| **Total presentes** | **38** | |

**Nota:** A simulação de `tagCardForBracket()` é uma simplificação baseada em heurísticas de oracle_text. O Dart code v8+ tem 11 categorias oficiais com heurísticas completas.

### Deck #6: GCs Presentes no Deck Ativo

O deck único no DB (`Runtime Lorehold Learned`) contém **6 GCs**: Ancient Tomb, Enlightened Tutor, Imperial Recruiter, Mana Vault, Smothering Tithe, Sol Ring. Todos presentes no cache com oracle_text OK.

---

## 🟡 Lacuna 17 (PERSISTE): DB SQLite sem game_changers Table

Inalterado desde Exec #11. A tabela `game_changers` não existe no SQLite, apenas no PG. Scripts que dependem dela falham localmente. Sem esta tabela, o detection rate oficial (24/53) não pode ser verificado localmente — apenas simulado contra `card_oracle_cache`.

---

## 🔴 Lacuna 21 (NOVA): Bracket Category Collapse — 3/5 Categorias com Zero Cartas

Este problema, identificado originalmente na Exec #10, **não foi corrigido**. As 3 categorias continuam vazias no DB PG (não verificável localmente sem `game_changers` table):

- `tutor`: 0 cartas
- `extraTurns`: 0 cartas
- `infiniteCombo`: 0 cartas

Apenas `fastMana` (7) e `freeInteraction` (2) retêm cartas. Consumidores do DB não conseguem distinguir GCs por tipo funcional.

---

## 📊 Métricas de Qualidade — Exec #12 vs Exec #13

| Métrica | Exec #12 | Exec #13 | Delta |
|:--------|:--------:|:--------:|:------|
| GCs detectados (oficial) | 24/53 (45%) | 24/53 (45%) | → Estimado estável |
| GCs missing do cache | **6 (11.3%)** | **15 (28.3%)** | 🔴 **+9 REGRESSÃO** |
| GCs presentes | 47 (88.7%) | 38 (71.7%) | 🔴 **-9 REGRESSÃO** |
| Tabela game_changers no SQLite | ❌ Ausente | ❌ Ausente | → Persiste |
| DB reimports (últimas 24h) | 3 | 4 | 🔄 +1 |
| Última atualização do cache | 2026-06-12T12:33Z | 2026-06-13T00:26Z | 🔄 Nova reimport |
| GCs com price_usd=NULL | 30+ | 36/38 (95%) | 🟡 Piorou |
| GCs com cmc=0.0 (non-land) | ~5 | 6/38 | → Estável |
| GCs com mana_cost vazio | ~3 | 5/38 | 🟡 Piorou |

### Problemas Persistentes de Dados nos 38 GCs Presentes

| Problema | Contagem | Exemplos |
|:---------|:--------:|:---------|
| `price_usd=NULL` (Reserved List/Legacy) | 36/38 (95%) | Quase todas — apenas 2 têm preço |
| `oracle_text` vazio (cache-wide) | 3 | Dwarven Trader, Memnite, Phyrexian Walker |
| `cmc=0.0` non-land (cache-wide) | 69 | Várias cartas com CMC não preenchido |
| `mana_cost` vazio (GCs) | 5 | Ancient Tomb, Field of the Dead, Gaea's Cradle, Mishra's Workshop, The Tabernacle |

---

## 🎯 Recomendações (novas/mantidas desde exec #12)

1. **🔴 CRÍTICO — Investigar script de sync PG→SQLite:** 15 GCs (28%) estão ausentes. A hipótese anterior ("filtro de banned") é insuficiente — **Expropriate** (legal) também está missing. Investigar se há filtro de nome, tipo, ou se o script está truncando cartas sem oracle_text, sem cmc, ou sem mana_cost.

2. **🔴 CRÍTICO — Restaurar 15 GCs perdidos:** Reimportar manualmente via Scryfall API ou corrigir o sync para incluir todas as cartas PG, inclusive banned.

3. **🔴 CRÍTICO — Verificar DFC handling:** Tergrid continua ausente. O sync pode estar excluindo cartas DFC (com `//` no nome).

4. **🔴 CRÍTICO — Adicionar alerta pós-sync:** Após cada reimport, verificar se os 53 nomes de GCs estão no `card_oracle_cache`. Se < 53, alertar imediatamente.

5. **🔴 CRÍTICO — Criar tabela game_changers no SQLite local:** A dependência exclusiva do PG para dados estruturados de GCs impede auditoria local.

6. **🟡 Atualizar `_knownInfiniteComboPieces` no Dart:** Adicionar Underworld Breach e Bolas's Citadel.

7. **🟡 Corrigir bracket_category no DB PG:** Force of Will → `freeInteraction`, Bolas's Citadel → `infiniteCombo`, 12 tutores → `tutor`.

8. **🟡 Sanitizar price_usd:** Marcar Reserved List como `RESERVED_LIST` ao invés de NULL para não contaminar métricas de preço.

9. **🟡 Corrigir 69 non-land cards com cmc=0.0** no card_oracle_cache — distorce análise de CMC.

---

## ⚠️ Observações Metodológicas

- A análise desta execução (#13) é puramente local (SQLite + simulação). Sem `game_changers` table, várias métricas não podem ser validadas contra o PG.
- A simulação da `tagCardForBracket()` é uma simplificação. O Dart code v8+ tem 11 categorias com heurísticas completas.
- **Não é possível provar se os 9 GCs adicionais foram perdidos na reimport das 00:26Z ou se a contagem de "47/53" da Exec #12 foi imprecisa.** O que é certo: o cache local contém apenas **38/53 GCs** — queda de 17% na cobertura desde Exec #12.
- **Próxima execução:** Verificar se os 15 GCs foram restaurados ou se mais foram perdidos. Executar alerta pós-sync como primeira ação.
