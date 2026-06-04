# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v3.8
**Data:** 2026-06-04T18:30:00+00:00
**Commit:** `1c082553` (HEAD: `6a828c6a`)
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`)
**Escopo:** Todos os 18 crons ativos + pipeline Lorehold (descomissionado) + novos crons
**Artefatos inspecionados:** `jobs.json` (721 linhas, 18 crons), outputs `/opt/data/cron/output/<id>/`, SQLite `knowledge.db` (6.4MB, 19 tabelas), Scryfall API, MTG Comprehensive Rules 2024-11-08
**Fontes de regras:** Scryfall API (banlist Commander atual), CR 103 (London Mulligan), CR 117.3-117.4 (Priority/Stack), CR 702.94 (Miracle), CR 903 (Commander), CR 510 (Combat Damage Step), CR 509 (Declare Blockers)

---

## Sumário Executivo

| Cron | Status | Nota | Confiabilidade | Novo em v3.8 |
|:-----|:------|:----:|:--------------|:-------------|
| Scout (`f20ac299992b`) | 🔴 DECOMISSIONADO | N/A | N/A | — |
| Validator (`712579b15767`) | 🔴 DECOMISSIONADO | N/A | N/A | — |
| Mulligan (`08468451a06a`) | 🔴 DECOMISSIONADO | N/A | N/A | — |
| Battle (`94f8590b1beb`) | 🔴 DECOMISSIONADO | N/A | N/A | — |
| Oracle (`a50bef4c2a59`) | 🔴 DECOMISSIONADO | N/A | N/A | — |
| **Multi-Commander Evolution** (`93a8ad77b251`) | ✅ Ativo | **7.5/10** | 🟡 MÉDIA | ✅ Primeira execução: Winota, 3 swaps |
| **Commander Knowledge Deep** (`75eed994c103`) | ✅ Ativo | **8.0/10** | 🟢 ALTA | 🔴 ACHADO: 6ª mudança de hash, pivot cEDH, push falhou |
| **Knowledge Synthesis** (`10a59b3bdf4d`) | ✅ Ativo | 7.0/10 | 🟡 MÉDIA | 5 novas tasks (2xP1, 3xP2) |
| Game Changer Research (`7915cc2377a0`) | ✅ Ativo | 8.0/10 | 🟢 ALTA | [SILENT] — 53/53 GCs pesquisados |
| Mana Base Validator (`444aa9510c2c`) | ✅ Ativo | 7.0/10 | 🟡 MÉDIA | Short-circuit, sem mudanças |
| **Auto-sync-learned-decks** (`7fcab928efd3`) | 🆕 Novo | **0/10** | 🔴 QUEBRADO | PermissionError no tracking file |
| **Pull-learning-events** (`262dc49e1be1`) | 🆕 Novo | **0/10** | 🔴 QUEBRADO | PostgreSQL UUID cast error |
| Auto-promote-learned (`104fd03a2ea2`) | 🆕 Novo | N/A | N/A | Nunca executou |
| Flutter UI Auditor (`cba438fd3a8b`) | 🆕 Novo | N/A | N/A | Script-based, status=ok |
| Tag Accuracy Reporter (`b340374bc4e7`) | ✅ Ativo | N/A* | N/A | Última execução 2026-06-03 |
| MTG Rules Auditor (`c0591cb18024`) | 🔴 PROMPT STALE | 6.0/10 | 🟡 MÉDIA | Prompt NÃO atualizado desde v3.7 |
| **PIPELINE LOREHOLD** | 🔴 DESCOMISSIONADO | **N/A** | **N/A** | 5/5 crons removidos |
| **PIPELINE ATUAL** | 🟡 Ativo, parcialmente quebrado | **4.5/10** | **🔴 BAIXA** | ⬇️ -0.5 vs v3.7 (2 novos crons quebrados) |

*Nota N/A: Crons não auditados em profundidade nesta execução.

**Tendência vs v3.7 (2026-06-04 15:00):** O pipeline score caiu de 5.0 para **4.5/10** porque 2 dos 4 novos crons (auto-sync, pull-learning-events) estão quebrados com erros de permissão e tipo. Por outro lado, o Multi-Commander Evolution produziu sua primeira análise real (Winota, 3 swaps) e o Commander Knowledge Deep detectou a 6ª mudança de hash com pivot estratégico para cEDH stax-combo. O prompt do MTG Rules Auditor **continua stale** — ainda referencia IDs de crons descomissionados (`f20ac299992b`, `712579b15767`, etc.).

---

## v3.8 — ACHADOS PRINCIPAIS

### 🔴 1. Deck Lorehold Sofreu 6ª Mudança de Hash — Pivot para cEDH Stax-Combo

**Evidência (Commander Knowledge Deep, 2026-06-04 17:26Z):**
- Hash: `763c3e0f...` → `7b0b3fa8...`
- **14+ cartas substituídas** — 14 adicionadas, 13+ removidas
- Pivot estratégico: spellslinger → **cEDH stax-combo**
- Adicionados: Drannith Magistrate, Pyroblast, Silence, Orim's Chant, Giver of Runes, Esper Sentinel, The One Ring, Wheel of Fortune, Scroll Rack, Past in Flames, Reiterate, Reverberate, Heat Shimmer
- Removidos: Akroma's Will, Lightning Greaves, Double Vision, Arcane Bombardment, Dawning Archaic, Ancient Den, Great Furnace
- CMC corruption: **RESOLVIDO** (36 cartas CMC=0 são lands/moxen legítimas)

**Pipeline Health Dashboard (do Commander Knowledge Deep):**

| Agent | Last Hash Analyzed | Current Hash | Lag | Status |
|-------|-------------------|--------------|-----|--------|
| Scout | `8b9c643c...` (#38) | `7b0b3fa8...` | 3 hashes behind | 🔴 STALE |
| Validator | `8b9c643c...` (v3.25) | `7b0b3fa8...` | 3 hashes behind | 🔴 STALE |
| Mulligan | `8b9c643c...` (#16) | `7b0b3fa8...` | 3 hashes behind | 🔴 STALE |
| Battle | `8b9c643c...` (v8) | `7b0b3fa8...` | 3 hashes behind | 🔴 STALE |
| Oracle | `30d00347...` (C#23) | `7b0b3fa8...` | 4+ hashes behind | 🔴 SILENT (72h+) |

**Interpretação:** O deck foi modificado externamente 6 vezes em 72h sem que nenhum agente do pipeline (todos descomissionados) detectasse. O Commander Knowledge Deep é o ÚNICO cron que detectou a mudança. O pipeline de otimização está completamente cego ao estado real do deck.

### 🔴 2. Dois Novos Crons Estão Quebrados

**Auto-sync-learned-decks (`7fcab928efd3`):**
```
PermissionError: [Errno 13] Permission denied: 
'/opt/data/scripts/../test/artifacts/hermes_auto_sync/synced_learned_ids.txt'
```
- O script `auto_sync_learned_decks.py` tenta escrever em um diretório sem permissão
- O diretório `test/artifacts/hermes_auto_sync/` não existe ou pertence a outro usuário
- **Impacto:** Nenhum deck learned é sincronizado automaticamente

**Pull-learning-events (`262dc49e1be1`):**
```
psycopg2.errors.UndefinedFunction: operator does not exist: uuid = text
LINE 1: ... SET synced_to_hermes = TRUE, synced_at = NOW() WHERE id = ANY(ARRA...
```
- O script `pull_learning_events.py` usa `id = ANY(%s)` sem cast explícito de `text → uuid`
- PostgreSQL exige `id = ANY(%s::uuid[])` quando a coluna é UUID
- **Impacto:** Eventos de aprendizado do PG nunca são marcados como sincronizados

### 🟡 3. Push Falhou no Commander Knowledge Deep

```
Push failed: No git credentials available in cron environment
```
- O commit `03e09d30` foi criado localmente mas NÃO foi pushado
- O arquivo `COMMANDER_DEEP_REPORT.md` foi atualizado (1531 linhas, +163/-9)
- O repositório está **ahead 2** commits (`6a828c6a` e `03e09d30`) que não foram pushados

### ✅ 4. Multi-Commander Evolution — Primeira Execução Bem-Sucedida

**Winota, Joiner of Forces** analisada em 2026-06-04T16:42Z:
- 3 swaps propostos com ΔCMC total = -5 (DEFENSIVO)
- Todos os swaps da collection (custo zero)
- Análise estrutural completa: lands=34, ramp=10, draw=4, removal=8, CMC médio=2.35
- **Gap:** `card_deck_analysis` vazio (0 entries) — o cron usou fallback de análise direta de `deck_cards` ✅
- **Gap:** O prompt referencia `wincon_catalog` que não foi documentado no schema do SQLite — a execução usou `deck_cards` diretamente com sucesso

**Avaliação MTG do Multi-Commander Evolution:**
- ✅ Color identity respeitada (Boros RW para Winota)
- ✅ CMC considerations (removeu CMC 7 adicionou CMC 2-3)
- ✅ Reconheceu stax/hatebears como tema (12+ cartas)
- ⚠️ Sem verificação explícita de banlist ou singleton no prompt
- ⚠️ Sem verificação de `card_count >= 100` após swaps
- ⚠️ O prompt usa `INSERT INTO run_log` mas o SQLite pode não ter a tabela `run_log` com as colunas esperadas

### 🟡 5. Knowledge Synthesis Produziu 5 Novas Tasks

**Commit `6a828c6a`** — 5 novas implementation tasks (2xP1, 3xP2):
1. **P1:** Sem `run_log` staleness check — short-circuit perpetua erros (Gap 17)
2. **P1:** 3 classificadores com drift — `classifyOptimizationFunctionalRole` ignora `functional_tags`
3. **P2:** `deck_learning_events` feedback loop quebrado — backend nunca lê eventos
4. **P2:** `card_deck_analysis` wincon scores não usados — quality gate não avalia wincon quality
5. **P2:** `GoldfishSimulator` keepable ignora color requirements — ~3-8pp superestimação

---

## Verificação MTG Rules — Fontes Oficiais (reconfirmado v3.8)

### Banlist Commander (Scryfall API, 2026-06-04)

| Card | Legalidade | Fonte |
|:-----|:-----------|:------|
| Worldfire | `commander=legal` | Scryfall API (confirmado v3.7) |
| Mana Crypt | `commander=banned` | Scryfall API (confirmado v3.7) |

### London Mulligan (CR 103.4c)

**Regra:** Primeiro mulligan gratuito em multiplayer. Mulligans subsequentes: bottom N-1 cartas.

**Status:** Implementado corretamente no mulligan simulator (documentado em execuções anteriores). O cron foi descomissionado mas a implementação era correta.

### Priority/Stack (CR 117.3-117.4)

**Status no código (`battle_simulator.dart`, 879 linhas):** NÃO implementado.
- Linha 9: "Sem stack complexo (resolução imediata)"
- Spells resolvem imediatamente — counterspells impossíveis
- O código nunca foi promovido a cron funcional

### Combat (CR 509-510)

**Status no código (`battle_simulator.dart`):**
- ✅ First Strike: timing correto (resolve antes do dano normal, linha 460-483)
- ✅ Trample: implementado (linha 497-499)
- ✅ Lifelink: implementado, **SEM cap em 40** (linha 502-503, 516-517)
- ✅ Deathtouch: implementado
- ✅ Flying evasion: implementado
- ❌ **1 blocker por attacker** — múltiplos bloqueadores não suportados (CR 509.2)
- ❌ **2-player apenas** — não simula split de ataque em Commander multiplayer (CR 802.1a)
- ❌ **Sem Commander damage (CR 903.10a)**
- ❌ **Sem Commander tax (CR 903.8)**

### Verificação: Afirmações Anteriores
- "Trample implementado" → ✅ **VERDADEIRO** (linha 497-499)
- "Lifelink sem cap em 40" → ✅ **VERDADEIRO** (linha 516-517)
- "1 blocker por attacker" → ✅ **VERDADEIRO** (código itera sobre attackers, bloco único por atacante)
- "2-player, sem Commander damage/tax" → ✅ **VERDADEIRO** (não há referências a commander_damage ou commander_tax no código)

---

## Pipeline Lorehold (Descomissionado) — Estado Final

Todos os 5 crons permanecem removidos do `jobs.json`. O código Dart (`battle_simulator.dart`, `functional_card_tags.dart`, `edh_bracket_policy.dart`) permanece no repositório.

### Gaps que SOBREVIVEM (código Dart ainda existe)

1. **Gap 6: Classificador "duplo nulo"** — `infer_functional_card_tags()` e `classify_card()` ainda podem falhar na mesma carta. O deck Lorehold (#6) tem 3 cartas com `functional_tag='unknown'`.

2. **Gap 3: Bracket policy incompleta** — `edh_bracket_policy.dart` cobre 5 categorias; 29/53 Game Changers não detectados.

3. **Gap 13: Bulk import data corruption** — Cartas importadas em massa recebem `functional_tag='unknown'` sem classificação.

4. **Gap 15: Ramp misclassification** — **PARCIALMENTE RESOLVIDO** (classificador corrigido 2026-06-03, ramp tags 6→19).

---

## Estado do Conhecimento Ativo

### Game Changer Research — 53/53 COMPLETO ✅

O cron retorna `[SILENT]` consistentemente (última execução: 2026-06-04T17:32Z). Todos os 53 Game Changers oficiais foram pesquisados. O hash-based fast path funciona corretamente.

### Commander Knowledge Deep — 6ª Mudança de Hash Detectada 🔴

O deck Lorehold sofreu 6 modificações externas em 72h. O pipeline de agentes (todos descomissionados) está 3-4+ hashes atrás do estado real. O Commander Knowledge Deep é o único cron que ainda monitora o deck ativamente.

---

## Plano de Correções (ordenado por impacto)

| # | Severidade | Alvo | Ação | Esforço |
|:-:|:----------:|:-----|:-----|:-------:|
| 1 | 🔴 CRÍTICO | Auto-sync-learned-decks | Corrigir permissão do tracking file (`chmod` ou criar diretório `hermes_auto_sync/`) | Baixo |
| 2 | 🔴 CRÍTICO | Pull-learning-events | Corrigir cast UUID: `id = ANY(%s::uuid[])` no script Python | Baixo |
| 3 | 🔴 CRÍTICO | Commander Knowledge Deep | Resolver git credentials para push automático — commit `03e09d30` está local apenas | Baixo |
| 4 | 🔴 CRÍTICO | MTG Rules Auditor | Atualizar prompt (`c0591cb18024`) — remover referências a crons descomissionados (IDs `f20ac`, `71257`, `08468`, `94f85`, `a50be`), focar nos crons ativos | Baixo |
| 5 | 🟡 ALTO | Multi-Commander Evolution | Adicionar verificação de banlist + singleton + card_count=100 no prompt | Baixo |
| 6 | 🟡 ALTO | Classificador Dart | Corrigir double-null: `infer_functional_card_tags()` e `classify_card()` falham nas mesmas cartas | Médio |
| 7 | 🟡 MÉDIO | Knowledge Synthesis | Verificar se as 5 novas tasks não duplicam tasks existentes em `IMPLEMENTATION_TASKS.md` | Baixo |
| 8 | 🟡 MÉDIO | Battle Simulator | Se for reativado: adicionar múltiplos bloqueadores, Commander damage/tax, stack básico | Alto |
| 9 | 🟢 BAIXO | Git push do repo | Push manual dos 2 commits ahead: `6a828c6a` (synthesis) e `03e09d30` (deep report) | Baixo |

---

## Conclusão

O pipeline Lorehold permanece descomissionado. O ecossistema de crons atual tem **18 crons**, dos quais **4 são novos** desde v3.7 — e **2 já estão quebrados**. O Multi-Commander Evolution produziu sua primeira análise real (Winota, 3 swaps, análise MTG sólida). O Commander Knowledge Deep detectou a 6ª mudança de hash do deck Lorehold (pivot para cEDH stax-combo) mas não conseguiu fazer push.

**Maior risco atual:** 2 crons de infraestrutura (auto-sync e pull-learning-events) estão quebrados com erros de permissão/tipo, impedindo a sincronização automática de decks learned entre Hermes e PostgreSQL. O pipeline de conhecimento está parcialmente cego.

**Maior gap de código:** O classificador de cartas (`functional_card_tags.dart`) ainda tem o problema de "duplo nulo" e o bracket policy (`edh_bracket_policy.dart`) ainda falha em detectar 29/53 Game Changers oficiais.

**Pipeline score: 4.5/10 🔴 BAIXA** (⬇️ -0.5 vs v3.7). A queda reflete os 2 novos crons quebrados, compensados parcialmente pela primeira execução bem-sucedida do Multi-Commander Evolution.
