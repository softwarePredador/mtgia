# Auditoria Completa — Regras MTG em Todas as Crons

**Versão:** v8.0
**Data:** 2026-06-07T22:00:00+00:00
**Commit:** `f70bcf84` (HEAD local, codex/hermes-analysis-docs)
**Auditor:** MTG Rules Auditor v3 (cron `c0591cb18024`)
**Escopo:** Auditoria completa dos 24 crons ativos + delta desde v7.0 (2026-06-07 18:45Z)
**Status:** v7.0 → v8.0 (~3h desde última auditoria). **8ª execução consecutiva com prompt stale.**

**⚠️ AVISO CRÍTICO:** O prompt deste cron contém 5 IDs de crons descomissionados desde v3.7 (2026-06-04). Esta é a **8ª execução consecutiva** com prompt desatualizado. Os diretórios `/opt/data/cron/output/f20ac299992b/`, `/opt/data/cron/output/712579b15767/`, `/opt/data/cron/output/08468451a06a/`, `/opt/data/cron/output/94f8590b1beb/`, e `/opt/data/cron/output/a50bef4c2a59/` **não existem**. O auditor opera usando o skill `manaloom-mtg-domain` v2.10.0 e inspeção direta dos outputs ativos.

---

## Sumário Executivo (v8.0)

| Cron | ID | Status | Nota MTG | Mudança vs v7.0 |
|:-----|:--|:-------|:--------:|:----------------|
| **Pipeline Lorehold** | — | 🔴 DESCOMISSIONADO | N/A | — |
| Master Watchdog | `757eefb8738b` | ✅ script-only | N/A | — |
| Normal Audit | `660397bb97e1` | ✅ Ativo | 8.0/10 | — |
| Weekly Parallel Audit | `aeaeb666d377` | 🔴 HTTP 429 | N/A | 🔴 (persiste) |
| **Commander Knowledge Deep** | `75eed994c103` | 🟡 MELHOROU | 5.0/10 | ↑ (+2.0) Exec #13 sem "BATTLE-VALIDATED" |
| Game Changer Research | `7915cc2377a0` | 🟡 Regressão | 3.0/10 | ↓ (-0.5) 3 bracket categories vazias |
| Tag Accuracy Reporter | `b340374bc4e7` | ⏳ Pendente | 5.0/10 | — (último run 23:12Z, antes de v7.0) |
| Mana Base Validator | `444aa9510c2c` | ✅ Ativo | 6.0/10 | — |
| Knowledge Import | `b2f5c21ce2d7` | ✅ script-only | N/A | — |
| **Knowledge Synthesis** | `10a59b3bdf4d` | ✅ Voltou | 6.0/10 | ↑ (+6.0) Exec #11 funcionou (74KB) |
| Logic Coherence Auditor | `de6fb777f5d1` | ✅ Ativo | 8.0/10 | — |
| Code Structure Auditor | `577a0a669714` | ✅ Ativo | N/A | — |
| Cron Governor Report | `21fa86eb0d84` | ✅ Ativo | N/A | — |
| Auto-sync-learned-decks | `7fcab928efd3` | 🔴 script-only | 0/10 | — (PermissionError persiste) |
| Pull-learning-events | `262dc49e1be1` | ✅ script-only | N/A | — (UUID cast persiste) |
| Auto-promote-learned | `104fd03a2ea2` | ✅ script-only | N/A | — |
| Knowncards Generator | `b9c8a7d6e5f4` | 🔴 QUEBRADO | 0/10 | — (script path + root-owned) |
| Universal Optimizer | `c8d9e0f1a2b3` | ⛔ PAUSADO | 1.0/10 | — (corta staples) |
| Knowncards Validator | `d4e5f6a7b8c9` | ✅ OK | 7.0/10 | — (lock resolvido) |
| Master Optimizer Preflight | `mmo-preflight01` | ✅ OK | 7.5/10 | — (estável) |
| Master Optimizer Auto-Cycle | `mmo-auto-cycle01` | 🔴 Timeout | N/A | 🆕 Timeout 120s |
| Manager Watchdog | `2d436c71bbf7` | ⛔ PAUSADO | N/A | — |
| **MTG Rules Auditor** | `c0591cb18024` | 🔴 PROMPT STALE | 2.0/10 | — (8ª exec stale) |
| **PIPELINE SCORE** | | | **3.5/10** 🟡 | **↑0.5 vs v7.0** |

**Pipeline score subiu de 3.0/10 para 3.5/10.** Motivo: Commander Knowledge Deep Exec #13 abandonou o padrão "BATTLE-VALIDATED" e agora investiga regressões em vez de gerar tasks P0 de apply; Knowledge Synthesis voltou a funcionar; CMC safety module implementado no produto. Porém, **0/11 correções do plano v4.0 ainda não aplicadas** (entrando no 3º dia).

---

## Mudanças desde v7.0 (2026-06-07 18:45Z → 22:00Z)

### 🟢 1. Commander Knowledge Deep — IMPROVEMENT (Exec #13, 21:38Z)

**Exec #13 rompeu o padrão "BATTLE-VALIDATED"** que persistiu por 4 execuções consecutivas (#9-12):

- ❌ **ANTES (Exec #9-12):** "BATTLE-VALIDATED", "6 swaps battle-validados", tasks P0 "Apply Slot Optimizer Phase 3 Findings", "Flow remaining 5 Slot Optimizer swaps"
- ✅ **AGORA (Exec #13):** Menções a Battle WR qualificadas como "opponent-pool-driven", task P0 virou "**Investigate** WR Regression" (investigar, não aplicar), tasks P1/P2 focadas em effect_map e estabilidade
- **Sem menção a "BATTLE-VALIDATED"** — léxico abandonado
- **5 tasks geradas:** P0 Investigate WR Regression, P1 effect_map, P1 KC Validator sampling, P2 re-baseline cron, P2 cross-deck confidence. Nenhuma propõe aplicar swaps automaticamente.

**Avaliação MTG:** 5.0/10 🟡 (subiu de 3.0). Ainda discute dados do Battle Simulator, mas não os trata como validação de Commander real e não gera tasks de apply. O "Investigate" é uma postura correta.

**Risco:** Exec #13 é uma única execução. O padrão pode retornar. Monitorar Exec #14.

### 🟢 2. Knowledge Synthesis — Voltou a Funcionar (Exec #11, 20:34Z)

- **Exec #9 (12:23Z):** `RuntimeError: HTTP 404 — Not Found | opencode`
- **Exec #10 (16:29Z):** Voltou, 74KB output
- **Exec #11 (20:34Z):** **Funcionou novamente**, 74KB de output com análise completa de código Dart + conhecimento MTG
- **Provider:** `opencode-go` (diferente do resto da frota `deepseek-pro`) — inconsistência permanece como risco de falha futura

**Avaliação MTG:** 6.0/10 🟡 (subiu de 0.0). Funcionando, mas provider instável. Migrar para `deepseek-pro` evitaria falhas futuras.

### 🟢 3. CMC Safety Module — IMPLEMENTADO NO PRODUTO (Gap 19 Parcialmente Resolvido)

**Descoberto pelo Logic Coherence Auditor (Exec #52, 21:49Z):**

- `server/lib/ai/cmc_safety.dart` (80 linhas): **3-tier fallback para CMC**
  1. DB `cmc` → parse `_parseRawCmc()`
  2. `mana_cost` string → parse `parseManaCostCmc()` (ex: `{2}{R}{W}` → 4)
  3. Fallback final: `unknownNonLandFallback=99` para não-lands
- Wireado em: `optimization_validator.dart:737`, `optimization_quality_gate.dart:607`, `goldfish_simulator.dart:265,577`
- 57 linhas de teste. Todos passam.
- **Defesa contra CMC=0.0 corruption ativa no código de produto.**

**Avaliação:** O DB ainda tem 142/543 (26.2%) cartas com CMC corrompido, mas o produto agora tem uma camada de defesa que usa `mana_cost` como fallback. `fix_cmc_batch.py` ainda pendente para corrigir a raiz no DB.

### 🟢 4. 53 Game Changers no Bracket Policy + 11 Categorias (Gap 3 Parcialmente Resolvido)

**Descoberto pelo Logic Coherence Auditor:**

- `server/lib/edh_bracket_policy.dart`: **11 valores em `BracketCategory`** (eram 5)
  - Novas: `boardWipe`, `cardAdvantage`, `stax`, `protection`, `valueEngine`, `gameChanger`
- **All 53 official GC names** em `officialGameChangerNamesForBracketPolicy` (linhas 354-408)
- Heurísticas para categorias novas: `_looksLikeGameChangerBoardWipe()`, `_looksLikeGameChangerCardAdvantage()`, `_looksLikeGameChangerStax()`, `_looksLikeGameChangerProtection()`
- `_knownValueEngineNames` — lista curada de value engines

**Avaliação:** O código Dart agora cobre todas as 12 categorias (5 originais + 7 novas). Porém o **SQLite ainda tem apenas 24/53 (45%) detectados** — a implementação no código não foi retroaplicada ao DB. Gap 3 passa de 🔴 para 🟡: código existe, mas dados históricos não foram reclassificados.

---

## 🔴 Regressões e Problemas Persistentes

### 🔴 5. Bracket Categories Esvaziadas — 3/5 Categorias Originais com ZERO Cartas

**Gamechanger Research Exec #10 (21:42Z):** Hash rotacionou (`c62005...` → `b8eec6...`) por 3 reclassificações de `bracket_category`:

| Carta | Categoria Anterior | Categoria Atual | Diagnóstico |
|:------|:-------------------|:----------------|:------------|
| Force of Will | `freeInteraction` ✅ | `other` ❌ | Regressão. "rather than pay" → freeInteraction |
| Bolas's Citadel | `infiniteCombo` ✅ | `other` ❌ | Regressão. Combo piece Top/Reservoir |
| Panoptic Mirror | `extraTurns` 🟡 | `freeInteraction` 🟡 | Reclassificação ambígua |

**Impacto:** `detected=1 & bracket='other'` subiu de 14 → 16. 3/5 categorias originais vazias: `tutor` (0), `extraTurns` (0), `infiniteCombo` (0). Apenas `fastMana` (7) e `freeInteraction` (2) retêm cartas. Consumidores do DB não conseguem distinguir tipo funcional de 88% dos GCs detectados.

**Avaliação MTG:** 3.0/10 🔴 (piorou de 4.0 no v7.0). O código Dart tem as 11 categorias, mas o SQLite está regredindo por batch/migration que reclassifica incorretamente.

### 🔴 6. CMC Corruption — 142/543 (26.2%) Inalterado (3º dia sem correção)

**Query confirmada (22:00Z):**
```sql
SELECT COUNT(*) FROM deck_cards WHERE cmc IS NULL OR cmc = 0.0;
-- 142/543 (26.2%) — INALTERADO desde v5.0
```

**`fix_cmc_batch.py`** continua pendente desde 2026-06-05. O `cmc_safety.dart` mitiga no produto, mas o DB permanece corrompido — qualquer ferramenta que leia `deck_cards.cmc` diretamente recebe dado inválido.

### 🔴 7. Tergrid oracle_text Vazio — Regressão Persiste (3º dia)

- Scryfall: oracle_text está em `card_faces[0].oracle_text` (DFC)
- DB: `oracle_text = ''` (string vazia)
- A "resolução" documentada no skill converteu NULL → `''` sem popular o oracle real
- Tergrid permanece invisível para heurísticas baseadas em oracle_text

### 🔴 8. Prompt Stale — 8ª Execução Consecutiva

O `mtg-rules-auditor` (c0591cb18024) está na **8ª execução consecutiva** com prompt que referencia 5 IDs de crons descomissionados. O prompt no `jobs.json` nunca foi atualizado desde v3.7 (2026-06-04).

### 🟡 9. Git Push Failures — Multi-Cron

**Cróns afetados:**
- Commander Knowledge Deep (Exec #13): commit `3ccbc1ee` local, push blocked (`.git-credentials missing`)
- Gamechanger Research (Exec #10): commit `f70bcf84` local, push blocked
- Knowledge Synthesis: provável mesmo problema

Nenhum cron tem credenciais Git no ambiente. Commits acumulam localmente sem push.

### 🟡 10. Master Optimizer Auto-Cycle — Timeout (NOVA)

**Exec #1 (20:07Z):** `Script timed out after 120s`. Primeiro run do novo cron `mmo-auto-cycle01` falhou com timeout. Aguardando Exec #2 para diagnóstico.

---

## Tabela Completa de Gaps (atualizada v8.0)

| Gap | Descrição | Severidade | Status | Mudança vs v7.0 |
|:----|:----------|:-----------|:-------|:-----------------|
| 1 | EDHREC inclusion rate não usado | 🟡 P1 | Aberto | — |
| 2 | Single-tag vs multi-tag ordem | 🟢 P2 | Aberto | — |
| 3 | Bracket detection incompleta | 🟡 P1 | **Parcialmente resolvido** | ↑ Código: 11 cats + 53 GCs. DB: 24/53 detectados |
| 4 | Sem tema-aware validation | 🟡 P1 | **Parcialmente resolvido** | ↑ `theme_contextual_rules_service.dart` criado |
| 5 | Co-pilot vs auto-pilot | 🟢 P3 | Aberto | — |
| 6 | Classificador duplo-nulo | 🟡 P1 | Aberto | — |
| 7 | Cartas novas fora do deck | 🟢 P3 | Maturidade atingida | — |
| 8 | Battle Analyst não é cron | 🔴 P0 | Documentado | — |
| 9 | Mulligan tapped lands | 🟡 P1 | Aberto | — |
| 10 | Battle 2-player apenas | 🔴 P0 | Documentado | — |
| 11 | Scout 94% SILENT | N/A | Cron descomissionado | — |
| 12 | Evolution Oracle parado | N/A | Cron descomissionado | — |
| 13 | Bulk import corruption | 🟡 P1 | Aberto | — |
| 14 | Pipeline staleness | 🟡 P1 | Aberto | — |
| 15 | Ramp misclassification | 🟢 P3 | **Resolvido** | ✅ Classificador corrigido (6→19) |
| 16 | Banlist blindness | 🟢 P3 | **Resolvido** | ✅ sync PG→SQLite |
| 17 | Short-circuit perpetua erros | 🟡 P1 | Aberto | — |
| 18 | CKC Deep cita Battle Analyst | 🔴 P0 | **Melhorou** | ↑ Exec #13: "Investigate" ao invés de "Apply" |
| 19 | CMC corruption (26.2%) | 🔴 P0 | **Parcialmente resolvido** | ↑ cmc_safety.dart no produto. DB ainda corrompido |
| 20 | Universal Optimizer corta staples | 🔴 P0 | Bloqueado (perm error) | — |
| 21 | Knowledge Synthesis HTTP 404 | 🟡 P1 | **Resolvido** | ✅ Exec #11 funcionou |
| 22 | Master Optimizer Preflight SQLite | 🟢 P3 | **Resolvido** | ✅ Exec #51+ passando |
| 23 | KC Validator LOCKED | 🟢 P3 | **Resolvido** | ✅ Lock resolvido |
| 24 | Stored metrics não atualizam | 🔴 P0 | Aberto | — |
| 25 | Bracket categories esvaziadas | 🔴 P0 | 🆕 NOVO | Force of Will, Bolas's Citadel → `other` |
| 26 | Auto-cycle timeout | 🟡 P1 | 🆕 NOVO | Primeiro run falhou 120s |

---

## Plano de Correções (ordenado por impacto, atualizado v8.0)

### 🔴 P0 — Imediato
1. **Atualizar prompt do mtg-rules-auditor** no `jobs.json` — remover 5 IDs descomissionados, referenciar crons ativos (8ª exec stale)
2. **Corrigir CMC no DB** — rodar `fix_cmc_batch.py` (142 cartas, 26.2%, 3º dia)
3. **Reimportar Tergrid oracle_text** — buscar face frontal via Scryfall, popular `card_faces[0].oracle_text`
4. **Restaurar bracket_category no SQLite** para Force of Will (`freeInteraction`), Bolas's Citadel (`infiniteCombo`), tutores (`tutor`)
5. **Configurar Git credentials** no ambiente cron para destravar push de 3+ crons

### 🟡 P1 — Alto
6. Migrar Knowledge Synthesis de `opencode-go` para `deepseek-pro`
7. Investigar timeout do auto-cycle (mmo-auto-cycle01)
8. Implementar stored-vs-actual metric recomputation após correção de classificador (Gap 24)
9. Retroaplicar classificação de bracket no SQLite usando novas 11 categorias do `edh_bracket_policy.dart`
10. Adicionar disclaimer obrigatório no Commander Knowledge Deep sobre limitações do Battle Simulator

### 🟢 P2 — Médio
11. Adicionar contract tests para `theme_contextual_rules_service.dart`
12. Atualizar `API_CONTRACTS_AND_DATA_MAP.md` com 11 bracket categories
13. Corrigir UUID cast no `pull-learning-events`
14. Corrigir PermissionError no `auto-sync-learned-decks`
15. Corrigir script path do `knowncards-generator`

---

## Conclusão

A pipeline de conhecimento Commander está em **3.5/10** — melhora marginal (+0.5 vs v7.0). 

**Progresso real:**
- ✅ Commander Knowledge Deep abandonou "BATTLE-VALIDATED" e agora investiga em vez de aplicar
- ✅ Knowledge Synthesis voltou a funcionar (2 execuções consecutivas)
- ✅ CMC safety module implementado no produto (defesa contra corrupção)
- ✅ 53 GCs + 11 categorias no código Dart
- ✅ Theme-aware validation service criado

**Preocupações:**
- 🔴 0/11 correções do plano v4.0 aplicadas em 3 dias
- 🔴 CMC corruption (26.2%) persiste no DB
- 🔴 Tergrid oracle_text vazio persiste
- 🔴 Bracket categories regredindo no SQLite (3/5 vazias)
- 🔴 Git push bloqueado para múltiplos crons (sem credenciais)
- 🔴 Este auditor está na 8ª execução com prompt stale

**Tendência:** 🟡 ESTÁVEL COM VIÉS POSITIVO. O produto está melhorando (cmc_safety, bracket expansion, theme service) mas o pipeline de conhecimento e o DB permanecem com problemas crônicos não resolvidos.

---

*Relatório gerado pelo MTG Rules Auditor v8.0 — 2026-06-07 22:00Z*
*Próxima execução programada: ~01:00Z (se prompt for atualizado)*
