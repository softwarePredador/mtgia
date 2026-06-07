# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualização manual segura por OpenCode após ajustes de governança.
> Última atualização: **2026-06-01T16:46:31Z** (opencode-operational-adjustment)

## Resumo Atual

| Métrica | Valor |
|:--|:--:|
| Total de crons | **23** |
| Habilitados | **20/23** |
| Pausados | **3/23** |
| Crons ativos em `opencode-go/deepseek-v4-pro` | **18** |
| Crons script-only ativos | **1** |
| Crons ativos sem provider explícito | **1** |
| OpenRouter ativo | **0** |
| `knowledge.db` journal mode | **WAL** |
| Backup antes do ajuste | `/opt/data/cron/jobs.json.bak.opencode_adjust_20260601164002` |

## Ajustes Aplicados

- `manaloom-master-watchdog` reativado (script-only, estava OK).
- `manaloom-hermes-weekly-parallel-audit` migrado para `opencode-go/deepseek-v4-pro` e reativado.
- `manaloom-code-structure-auditor` semanal migrado para `opencode-go/deepseek-v4-pro` e reativado.
- `manaloom-code-structure-auditor` de 3h mantido pausado como duplicado do semanal.
- `manaloom-manager-watchdog` mantido pausado: `superseded_by_report_only_cron_governor`.
- `manaloom-knowledge-import` mantido pausado: `blocked_until_secret_safe_import_flow_exists`.
- Frequências alinhadas com a política de governança para reduzir risco de rate limit.
- Pipeline `wincon-*` escalonado para evitar execução simultânea.
- `knowledge.db` colocado em WAL para reduzir risco de lock entre crons.

## Schedules Ajustados

| Cron | Novo schedule |
|:--|:--:|
| `lorehold-deck-scout` | every 180m |
| `lorehold-deck-validator` | every 180m |
| `lorehold-mulligan-analyst` | every 180m |
| `lorehold-evolution-oracle` | every 240m |
| `manaloom-knowledge-synthesis` | every 240m |
| `manaloom-hermes-normal-audit` | every 360m |
| `manaloom-tag-accuracy-reporter` | every 1440m |
| `manaloom-mana-base-validator` | every 360m |
| `manaloom-cron-governor-report` | every 720m |
| `lorehold-wincon-hunter` | every 360m |
| `lorehold-wincon-tester` | every 360m |
| `lorehold-wincon-builder` | every 360m |
| `lorehold-deckbuilding-methodology` | every 360m |

## Crons Pausados Intencionalmente

| Cron | Motivo |
|:--|:--|
| `manaloom-manager-watchdog` | Substituído pelo `manaloom-cron-governor-report`; não reativar sem nova decisão. |
| `manaloom-knowledge-import` | Bloqueado até existir fluxo de import seguro para segredos/PostgreSQL. |
| `manaloom-code-structure-auditor` (3h, `bb03201b8911`) | Duplicado; manter pausado enquanto o semanal estiver ativo. |

## Pendências Seguras

- Aparar `docs/hermes-analysis/STRUCTURE_AUDIT.md`, que está grande demais, em alteração documental separada.
- Decidir se o `cron-governor-report` deve manter este `CRON_STATUS.md` daqui para frente.
- Revisar próximo ciclo dos `wincon-*`; se voltarem com plano/código em vez de resultado executado, endurecer prompts ou consolidar pipeline.

---

## Histórico Anterior

# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-31T07:13:03Z** (manaloom-manager-watchdog)

## Resumo

| Métrica | Valor |
|:--|:--:|
| Total de crons (`include_disabled=True`) | **18** |
| Habilitados | 18/18 |
| Desabilitados | **0** |
| `last_status=error` | **3** |
| `last_status=ok` | **15** |
| Nunca executaram (`last_run_at=null`) | **0** |
| Stale (>1.5x schedule atrás, `enabled=true`) | **0** |
| Ações de recuperação nesta execução | 0 (rate limit lifting -- auto-recuperação em progresso) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 18 crons habilitados, **16 OK**, **2 com erro**. Estagnação quebrada: `code-structure-auditor` (weekly) recuperou em 06:37Z. Melhora acumulada: 12→2 erros (-83%).

## Análise de Recuperação

| Snapshot | Horário | OK | Erros | Delta Erros |
|:--|:--:|:--:|:--:|:--:|
| 1 | 2026-05-31T00:53Z | 6 | 12 | — |
| 2 | 2026-05-31T01:32Z | 10 | 8 | -4 |
| 3 | 2026-05-31T02:12Z | 12 | 6 | -2 |
| 4 | 2026-05-31T02:51Z | 13 | 5 | -1 |
| 5 | 2026-05-31T03:37Z | 14 | 4 | -1 |
| 6 | 2026-05-31T04:21:01Z | **15** | **3** | **-1** |
| 7 | 2026-05-31T04:52:00Z | **15** | **3** | **0** |
| 8 | 2026-05-31T06:37Z | **16** | **2** | **-1** |

**Recuperação acumulada: 12 → 2 erros (-83%)**

**✅ Estagnação quebrada: Snapshot 8 mostra recuperação do `code-structure-auditor` (weekly).**

**Mudanças desde snapshot anterior (04:52Z → 2026-05-31T07:13:03Z):**
- **1 cron recuperado (error → ok):**
  - `manaloom-code-structure-auditor` (weekly) — rodou OK às 06:37Z
- **Diagnóstico:** Estagnação de 4 snapshots quebrada. Rate limit do OpenRouter free-tier continuando recuperação gradual
- **Ação tomada:** Nenhuma — recuperação automática pelo scheduler
- **Próximo tick relevante:** `manaloom-logic-coherence-auditor` em ~07:50Z (~59min)

**Mudanças desde snapshot anterior (03:37Z → 2026-05-31T04:21:01Z):**
- **1 cron recuperado (error → ok):**
  - `manaloom-mana-base-validator` — rodou OK às 03:12Z
- **Diagnóstico:** Rate limit continuando a recuperar gradualmente
- **Ação tomada:** Nenhuma -- recuperação automática pelo scheduler

## Crons OK (15)

| Job ID | Nome | Schedule | Last run | Status | Observação |
|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | 2026-05-31T04:49Z | ok | script-based |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | **error** | 429 residual, next 16:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-30T14:30Z | ok | semanal |
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | 2026-05-31T02:47Z | ok | ✅ recuperado de 429 |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | 2026-05-31T03:28Z | ok | ✅ recuperado de 429 |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | 2026-05-31T04:52Z | ok | **esta execução** |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | 2026-05-30T14:42Z | ok | diário |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | 2026-05-31T03:12Z | ok | ✅ recuperado de 429 (agora!) |
| `f20ac299992b` | lorehold-deck-scout | every 120m | 2026-05-31T04:04Z | ok | ✅ recuperado de 429 |
| `712579b15767` | lorehold-deck-validator | every 180m | 2026-05-31T04:31Z | ok | ✅ recuperado de 429 |
| `08468451a06a` | lorehold-mulligan-analyst | every 360m | 2026-05-31T04:16Z | ok | ✅ recuperado de 429 |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 720m | 2026-05-31T04:48Z | ok | 12h schedule |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | 2026-05-31T03:55Z | ok | ✅ recuperado de 429 |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | 2026-05-31T03:37Z | ok | ✅ recuperado de 429 |
| `94f8590b1beb` | lorehold-battle-analyst | every 480m | 2026-05-31T01:18Z | ok | 8h schedule |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-31T01:59Z | ok | ✅ recuperado de 429 |

## Crons com Erro (3) -- Estagnação desde ~03:37Z

Os 3 erros abaixo estão estagnados desde ~03:37Z (sem recuperação nos últimos 3 snapshots). Provável rate limit residual do OpenRouter free-tier.

| Job ID | Nome | Schedule | Last run | Último erro | Próximo tick |
|---|---|---|---|---|---|
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | error | 2026-05-31T16:00Z |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-30T16:56Z | 429 | próximo domingo 06:00Z |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | 2026-05-31T03:26Z | error | ~05:27Z |

*Nota: `manaloom-logic-coherence-auditor` marcou FAILED mas output contém audit report válido com apenas P2 findings (doc drift). Erro provavelmente de tool-call limit, não de rate limit. Próximo tick natural para validar.

## Análise de Erro

**Causa raiz:** `HTTP 429: Rate limit exceeded: free-models-per-day-stealth` (recuperando)
**Provider:** OpenRouter (free-tier shared pool)
**Afetados:** 2/18 crons (redução de 12 para 2 -- melhora de 83%)
**Duração total do incidente:** ~10h (desde ~21:00Z 30/05)
**Status:** **RECUPERANDO** -- estagnação quebrada em snapshot 8 (06:37Z): `code-structure-auditor` (weekly) recuperou

**Por que nenhum `run` foi disparado neste cycle:**
- Ambos os crons de erro têm `next_run_at` no futuro (próximos ticks pendentes)
- `manaloom-logic-coherence-auditor`: próximo tick em ~07:50Z (~59min) — cron mais frequente, próximo a rodar
- `manaloom-hermes-normal-audit`: próximo tick em 16:00Z (~9h) — cron diário com horários fixos
- Disparar `run` em crons que estão prestes a rodar naturalmente desperdiçaria chamadas e poderia agravar rate limit

**Recuperação esperada:**
- `logic-coherence-auditor` deve auto-recuperar no próximo tick (~07:50Z) — **critério de validação:** se não recuperar em 2 ticks consecutivos, investigar output
- `hermes-normal-audit` deve auto-recuperar no tick das 16:00Z
- `code-structure-auditor` (weekly) ✅ **JÁ RECUPEROU** em 06:37Z

## Ações Realizadas Neste Cycle (2026-05-31T07:13:03Z)

| Ação | Cron | Resultado |
|:-----|:------|:----------|
| -- | Nenhuma (auto-recuperação em progresso) | 1 cron recuperado naturalmente (code-structure-auditor weekly) |

## Alertas Pendentes

**P2 -- 2 crons ainda com error:**
- **Sintoma:** 2 crons `openrouter/owl-alpha` mantendo `last_status=error`
- **Impacto:** Redução temporária de auditorias e análises
- **Tendência:** MELHORA -- estagnação quebrada no snapshot 8. Próxima validação: tick do `logic-coherence-auditor` (~07:50Z)
- **Recuperação:** Automática conforme scheduler tick. `logic-coherence-auditor` é o próximo a rodar (~07:50Z)
- **Ação do watchdog:** Monitorar tick do `logic-coherence-auditor` (~07:50Z). Se não recuperar em 2 ticks consecutivos, investigar output individual. `hermes-normal-audit` (16:00Z) tem tick mais distante.

## Mudanças desde Snapshot Anterior

### Crons que Recuperaram (ERROR → OK) -- 1 neste cycle (cumulativo -7)

| Cron | Schedule | Recuperou em |
|:-----|:--------|:-----------|
| manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | 2026-05-31T06:37Z |
| manaloom-mana-base-validator | every 360m | 2026-05-31T03:12Z |
| manaloom-commander-knowledge-deep | every 240m | 2026-05-31T02:47Z |

### Crons que Regrediram (OK → ERROR)
*(nenhum)*

### Outras Observações


---

## Mana Base Validation Report (manaloom-mana-base-validator)

> **Data:** 2026-06-06T00:17:32Z
> **Cron:** manaloom-mana-base-validator
> **Decks analisados:** 8
> **Fonte profiles:** commander_reference_profile_anchor30_batch_*_2026-05-12/profiles/*.json
> **Método:** SUM(dc.quantity) por functional_tag; mapping PROFILE_ROLE_TO_TAG

### Resumo Geral

| # | Deck | Cards | Status | Lands | Perfil Lands | Principais Deltas |
|---|------|:-----:|:------:|:-----:|:------------:|-------------------|
| 1 | Kinnan, Bonder Prodigy | 13/100 | INCOMPLETE | -- | -- | Apenas 13 cartas (seed parcial) |
| 2 | EDHREC Average Deck - Dimir Ninja Topdeck Tempo | 99/100 | CRIT* | 31 | 30-34 | interaction=6 vs [10-16] (CRIT d=4) |
| 3 | EDHREC Average Default | 11/100 | INCOMPLETE | -- | -- | Apenas 11 cartas (seed parcial) |
| 4 | EDHREC Average Default | 80/100 | CRIT* | 15 | 35-37 | lands=15 vs [35-37] (CRIT d=20); ramp=15 vs [9-11] (CRIT d=4); interaction=7 vs [8-11] (BLUE d=1); recursion=3 vs [4-7] (BLUE d=1); draw=8 vs [10-14] (WARN d=2) |
| 5 | Aesi EDHREC Average Default | 100/100 | CRIT* | 40 | 39-43 | ramp_extra_lands=28 vs [14-18] (CRIT d=10); supplemental_draw=4 vs [6-9] (WARN d=2); landfall_payoffs=0 vs [8-12] (CRIT d=8); finishers=0 vs [3-5] (WARN d=3); land_recursion_bounce=2 vs [4-8] (WARN d=2) |
| 6 | Lorehold Best-of Learned No Premium Mox 2026-06-02 | 100/100 | NO PROFILE | 31 | -- | Sem perfil EDHREC; 2 cartas "unknown"; avg_cmc corrompido (37/100 CMC NULL/0) |
| 7 | EDHREC Average Default — Boros Combat Trigger Humans | 100/100 | WARN* | 34 | 31-35 | protection=3 vs [5-8] (WARN d=2) |
| 9 | Atraxa, Praetors' Voice — EDHREC Average (41k decks) | 100/100 | CRIT* | 36 | 35-38 | interaction=6 vs [8-13] (WARN d=2); finishers=0 vs [4-7] (CRIT d=4) |

*Legenda: OK | BLUE (d=1) | WARN (d=2-3) | CRIT (d>=4) | INCOMPLETE (<50 cards)*
*\* = EDHREC aggregate parcial — metricas podem ser corpus artifacts, nao decks reais*

### Notas de Interpretação

1. **Decks INCOMPLETE (<50 cards):** Kinnan (#1, 13 cards) e Korvold (#3, 11 cards) são seeds parciais — métricas não acionáveis. Nenhuma mudança desde validações anteriores.

2. **Lorehold #6 (NO PROFILE):** Sem perfil EDHREC para este commander. 2/100 cartas com tag "unknown". Deck com 31 lands, 19 ramp, 9 draw, 10 protection, 10 wincon. **CMC corrompido:** 37/100 cartas têm CMC=NULL ou CMC=0.0 no `deck_cards` (já reportado no TAG_ACCURACY_REPORT).

3. **Teysa (#4):** 80-card aggregate EDHREC incompleto. `lands_tag=15` vs perfil [35-37] — discrepância de 20 lands. Perfil espera 35-37 lands, mas apenas 15 cartas têm functional_tag='land'. Falso positivo do aggregate incompleto — basic lands não foram inseridas como `deck_cards`. `ramp=15 vs [9-11]` (CRIT d=4) — possível over-tagging de ramp no aggregate.

4. **Yuriko (#2):** `interaction=6 vs [10-16]` — CRIT d=4. 99/100 cards (1 short). 21 cartas com functional_tag=None (incluindo Misdirection, Lim-Dûl's Vault, Commit//Memory que podem ter função de interaction). Tags de interaction sub-representadas.

5. **Atraxa (#9):** `finishers=0 vs [4-7]` — CRIT d=4. Natureza 'goodstuff' de Atraxa — finishers menos definidos em aggregates. `interaction=6 vs [8-13]` — WARN d=2.

6. **Winota (#7):** `protection=3 vs [5-8]` — WARN d=2. Aggregate EDHREC — proteção abaixo do perfil possivelmente por sub-representação de tags de proteção nos dados do corpus.

7. **Aesi (#5):** `ramp_extra_lands=28 vs [14-18]` — CRIT d=10. Tags de ramp super-representadas no aggregate (land ramp + extra land drops + mana dorks no mesmo bucket `functional_tag='ramp'`). `supplemental_draw=4 vs [6-9]` — WARN d=2. `landfall_payoffs=0 vs [8-12]` — CRIT d=8 (engine não captura landfall específico).

8. **Melhoria no validador:** `_mana_validator.py` atualizado com `PROFILE_ROLE_TO_TAG` mapping (54 entradas) para cobrir categorias específicas de commander (ramp_extra_lands, supplemental_draw, interaction_counter, etc.) que antes eram ignoradas por mismatch de chaves.

9. **Limitação conhecida:** Categorias específicas de commander (evasive_enablers, ninjas, topdeck_manipulation, sacrifice_outlets, landfall_payoffs, proliferate_engines, nonhuman_enablers, human_hits, combat_payoffs) mapeiam para `engine` mas como o deck_cards não tem essas tags específicas, aparecem como `engine=0` (CRIT falso positivo). Esses deltas NÃO aparecem na tabela resumo acima — apenas deltas de tags padrão.

---

*Validação gerada por manaloom-mana-base-validator em 2026-06-06T00:17:32Z*
## Precisão das Functional Tags (manaloom-tag-accuracy-reporter)

> Última atualização: **2026-06-03T06:00:00Z**
> Relatório completo: `TAG_ACCURACY_REPORT.md`

### Resumo Geral

| Métrica | 2026-06-02 | 2026-06-03 | Delta |
|:--------|:----------:|:----------:|:-----:|
| **Tags no sistema** | 22 | 22 | 0 |
| **Tags com 100% de precisão** | 15 (68%) | 15 (68%) | 0 |
| **Tags abaixo de 85%** | 7 (32%) | 7 (32%) | 0 |
| **Pior precisão** | payoff (35.5%) | payoff (35.5%) | 0 |
| **Novas tags sem `tag_accuracy`** | 0 | **4** 🟡 | **+4** |
| **Cartas double-null** | 25 (4.6%) | 25 (4.6%) | 0 |
| **Cartas 'unknown' (classif. não rodou)** | **20** 🔴 | 3 🟡 | **-17** |
| **Cartas com CMC inválido (deck 6)** | ~15 | **36** 🔴 | **+~21** |
| **Divergência single vs multi tag** | 36 (6.6%) | 36 (6.6%) | 0 |
| **Cartas sem multi-tags** | 124 (22.8%) | 128 (23.6%) | +4 |
| **fp/fn tracking** | NÃO implementado | NÃO implementado | 0 |
| **Discrepâncias documentadas** | 21 | 21 | 0 |

### `tag_accuracy` ESTAGNADO (7 dias sem atualização) 🔴

A tabela `tag_accuracy` contém os mesmos 22 registros desde 2026-05-27. Nenhuma
atualização de precisão, nenhum novo dado de fp/fn. O pipeline de tagging não está
evoluindo. **7 dias de estagnação é sinal de pipeline quebrado.**

### ✅ Bulk Import — 17/20 Cartas Reclassificadas (Progresso Parcial)

Das 20 cartas com `functional_tag='unknown'` no deck 6, **17 foram reclassificadas**
com tags apropriadas (`ramp`, `draw`, `protection`, `removal`, `combo`, `wincon`,
`stax`, `spellslinger`, `tutor`). Restam **3 cartas 'unknown'**: Inventors' Fair,
Prismatic Vista, Reforge the Soul — todas com CMC=3.0 (errado).

### 🔴 CMC Corruption Ampliada — 36 Cartas com CMC Inválido

A reclassificação corrigiu `functional_tag` mas **piorou** a situação de CMC:
**36 cartas no deck 6** (36%) têm `CMC IS NULL OR CMC = 0.0`. O deck é
completamente inanalisável para curva de mana, mulligan ou CMC médio.

### 🟡 4 Tags Novas Sem Métrica de Precisão

`stax`, `combo`, `commander`, `spellslinger` existem como valores de `functional_tag`
no banco mas não têm entrada em `tag_accuracy`. Suas precisões são desconhecidas.

### Recomendações de Código (Atualizadas)

| Prioridade | Ação | Arquivo |
|:----------:|:-----|:--------|
| 🔴 | **NOVO:** Corrigir CMCs do deck 6 — 36 cartas com CMC inválido | `scripts/reclassify_deck.py` ou `import_lorehold_decks.py` |
| 🔴 | **NOVO:** Adicionar `stax`, `combo`, `commander`, `spellslinger` ao `tag_accuracy` | `scripts/knowledge_db.py` |
| 🔴 | **NOVO:** Rodar atualização do `tag_accuracy` — estagnado 7 dias | Pipeline `tag_accuracy` update |
| 🔴 | Corrigir bulk import — executar classificador pós-insert | `scripts/import_lorehold_decks.py` |
| 🔴 | Ampliar heurísticas `_looksLike*` para payoff/enabler/engine/wincon | `server/lib/ai/optimization_functional_roles.dart` (L370-398) |
| 🔴 | Adicionar `_looksLike*` ao Python `classify_card()` (hoje as omite) | `scripts/scryfall_classifier.py` (L155-221) |
| 🟡 | Unificar single-tag com multi-tag como fallback | `optimization_functional_roles.dart` + `functional_card_tags.dart` |
| 🟡 | Implementar tabela `tag_errors` para rastreamento granular de fp/fn | `scripts/knowledge_db.py` |


---

*Status snapshot: 2026-05-31T07:13:03Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 16 ok, 2 error -- 12→2 erros / 83% melhora / estagnação quebrada)*

*Recuperação timeline: 00:53Z (12 erros) → 01:32Z (8 erros, -4) → 02:12Z (6 erros, -2) → 02:51Z (5 erros, -1) → 03:37Z (4 erros, -1) → 04:21Z (3 erros, -1) → 04:52Z (3 erros, 0) → 2026-05-31T07:13:03Z (2 erros, -1, estagnação quebrada) | Próxima validação: ~07:50Z (logic-coherence-auditor)*
