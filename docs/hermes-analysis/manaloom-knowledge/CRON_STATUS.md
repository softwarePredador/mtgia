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

> **Data:** 2026-06-07T12:54:26Z
> **Cron:** manaloom-mana-base-validator
> **Decks analisados:** 8 (IDs 1-7, 9)
> **Fonte profiles:** 32 profiles (4 dirs, commander_reference_profile_*)
> **Método:** Normalized name matching (underscore↔space); lands via `role_targets.lands.{min,max}`; dados complementares via deck_cards.functional_tag

### Resumo Geral — Validação de Lands vs Perfil EDHREC

| # | Deck | Cards (rec/qty) | Status | Lands | Perfil Lands | Dados Corrompidos |
|---|------|:-----:|:------:|:-----:|:------------:|-------------------|
| 1 | Kinnan, Bonder Prodigy | 13/13 | INCOMPLETE | 29 | [29-34] | 2/13 CMC NULL; 1/13 tag NULL; 13 cards total |
| 2 | Yuriko — Dimir Ninja Topdeck Tempo | 84/99 | OK | 33 | [30-34] | 19/84 CMC NULL (23%); 21/84 tag NULL (25%) |
| 3 | Korvold — EDHREC Average Default | 11/11 | INCOMPLETE | 25 | — | 11 cards total; CMC stored=3.2 vs computed=2.64 |
| 4 | Teysa Karlov — EDHREC Average | 80/80 | LANDS OK | 35 | [35-37] | lands_tag=15 vs perfil[35-37] — basic lands não em deck_cards; 15/80 CMC NULL; 4/80 tag NULL |
| 5 | Aesi EDHREC Average Default | 79/100 | LANDS OK | 40 | [39-43] | 19/79 CMC NULL (24%); 6/79 tag NULL; CMC stored=2.61 vs computed=3.40 |
| 6 | Lorehold Best-of Learned No Premium Mox | 100/100 | NO PROFILE | 33 | — | 36/100 CMC NULL (36%!); CMC stored=1.79 vs computed=3.14 (maior divergência) |
| 7 | Winota — Boros Combat Trigger Humans | 85/100 | LANDS OK | 34 | [31-35] | 22/85 CMC NULL (26%) |
| 9 | Atraxa, Praetors' Voice — EDHREC (41k) | 91/100 | LANDS OK | 36 | [35-38] | 29/91 CMC NULL (32%); CMC mais preciso (stored=2.97 vs computed=2.98) |

*Legenda: OK | INCOMPLETE (<50 cards) | NO PROFILE | CORRUPT (CMC/tag)*

### Diagnóstico de Dados — CMC Sistemicamente Corrompido 🔴

**TODOS os decks** exceto Atraxa (#9) têm CMC stored vs computed divergente (>0.1 de diferença):

| Deck | Stored CMC | Computed CMC | Delta | CMC NULL/0 |
|------|:----------:|:------------:|:-----:|:----------:|
| Kinnan #1 | 1.80 | 2.82 | **+1.02** | 2/13 (15%) |
| Yuriko #2 | 2.80 | 3.29 | **+0.49** | 19/84 (23%) |
| Korvold #3 | 3.20 | 2.64 | -0.56 | 0/11 |
| Teysa #4 | 2.90 | 2.74 | -0.16 | 15/80 (19%) |
| Aesi #5 | 2.61 | 3.40 | **+0.79** | 19/79 (24%) |
| **Lorehold #6** | **1.79** | **3.14** | **+1.35** 🔴 | 36/100 (36%) |
| Winota #7 | 2.35 | 2.56 | +0.21 | 22/85 (26%) |
| Atraxa #9 | 2.97 | 2.98 | +0.01 ✅ | 29/91 (32%) |

**Hipótese:** O `avg_cmc` armazenado em `decks.avg_cmc` foi calculado com um subconjunto diferente de cartas do que `AVG(cmc) WHERE cmc > 0`. Possíveis causas:
1. Cálculo original usou `WHERE cmc IS NOT NULL` (incluindo cmc=0, puxando média pra baixo)
2. Ou o cálculo foi feito antes de bulk inserts com CMC=0
3. Lorehold (#6) tem 36% de cartas com CMC NULL — mais de 1/3 do deck sem CMC válido

**Recomendação:** Recomputar `decks.avg_cmc` para todos os decks, excluindo CMC=0 e NULL.

### Perfis EDHREC — Coverage e Lacunas

- **7/8 comandantes matched** (Kinnan, Yuriko, Korvold, Teysa, Aesi, Winota, Atraxa)
- **1/8 sem perfil:** Lorehold (não está nos 32 profiles)
- **Limitação estrutural:** Os `role_targets` dos perfis usam nomes específicos por commander (`ramp_extra_lands`, `supplemental_draw`, `draw_value`, `interaction`, `fodder_tokens`, `death_payoffs`, `mana_dorks`, `artifact_mana`, etc.) que **não mapeiam 1:1** para os `functional_tag` genéricos em `deck_cards` (`ramp`, `draw`, `removal`, `engine`, etc.). Apenas `lands` é diretamente comparável.
- Para validação completa de ramp/draw/interaction/finishers, seria necessário um mapping commander-específico (como o `PROFILE_ROLE_TO_TAG` de 54 entradas mencionado na validação anterior).

### Tags NULL/Unknown por Deck

| Deck | Tags NULL/Unknown | % | Cartas Afetadas (exemplos) |
|------|:---:|:---:|------|
| Kinnan #1 | 1/13 | 8% | — |
| Yuriko #2 | 21/84 | 25% | 21 cartas sem tag — inclui Misdirection, Lim-Dûl's Vault, Commit//Memory |
| Korvold #3 | 0/11 | 0% | — |
| Teysa #4 | 4/80 | 5% | — |
| Aesi #5 | 6/79 | 8% | — |
| Lorehold #6 | 3/100 | 3% | — |
| Winota #7 | 0/85 | 0% | — |
| Atraxa #9 | 0/91 | 0% | — |

**Yuriko (#2) é o pior caso:** 25% das cartas sem functional_tag — o classificador não rodou em 1/4 das cartas.

### Mudanças vs Validação Anterior (2026-06-06)

1. **Profile matching corrigido:** De 4/8 → 7/8 commanders matched (normalização de nomes com underscore↔space)
2. **Identificado CMC corruption sistêmico:** Descoberto que TODOS os decks (exceto Atraxa) têm `avg_cmc` divergente — problema estrutural, não pontual
3. **Lorehold #6 pior caso:** 36% CMC NULL (antes reportado como 37/100, confirmado)
4. **Lands validation agora usa ranges reais** dos perfis (min/max), não estimativas
5. **Tags NULL:** Yuriko #2 piorou relativo (continua 21/84 NULL, 25%)

---

*Validação gerada por manaloom-mana-base-validator em 2026-06-07T12:54:26Z*
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
