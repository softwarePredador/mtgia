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

> **Data:** 2026-06-08T01:17:41Z
> **Cron:** manaloom-mana-base-validator
> **Decks analisados:** 8
> **Profiles:** 24 profiles (3 batch dirs: anchor30 A/B/C)
> **Método:** Profile matching via commander name; lands/ramp/draw via `role_targets.{min,max}`; CMC computed from `deck_cards` excluding NULL/0 and lands; ramp/draw tagged count from `functional_tag`

### Resumo Geral — Validação vs Perfis EDHREC

| # | Deck | Cards | Status | Lands (stored) | Perfil Lands | CMC (stored/computed) | Ramp (stored/perfil) | Draw (stored/perfil) | Dados Corrompidos |
|---|------|:---:|:------:|:---:|:------------:|:---:|:---:|:---:|:---|
| 1 | Kinnan, Bonder Prodigy | 13 | INCOMPLETE | 29 | 29-34 ✅ | 1.80/2.82 🔴 | 4/— — | 3/— — | tag NULL: 1 (7%); CMC=0 nonland: 2; lands stored(29)≠tagged(0) |
| 2 | Yuriko — Dimir Ninja Topdeck Tempo | 99 | OK | 33 | 30-34 ✅ | 2.80/3.23 ⚠️ | 8/— — | 14/— — | tag NULL: 21 (21%); CMC=0 nonland: 2; lands stored(33)≠tagged(35); draw stored(14)≠tagged(12) |
| 3 | Korvold — EDHREC Average Default | 11 | INCOMPLETE | 25 | 34-37 ⚠️ | 3.20/2.64 ⚠️ | 3/10-14 ⚠️ | 1/6-10 ⚠️ | lands stored(25)≠tagged(0) |
| 4 | Teysa Karlov — EDHREC Average | 80 | OK | 35 | 35-37 ✅ | 2.90/2.74 ✅ | 15/9-11 ⚠️ | 11/10-14 ✅ | tag NULL: 4 (5%); lands stored(35)≠tagged(15); draw stored(11)≠tagged(8) |
| 5 | Aesi EDHREC Average Default | 100 | OK | 40 | 39-43 ✅ | 2.61/3.40 ⚠️ | 28/14-18 ⚠️ | 12/6-9 ⚠️ | tag NULL: 6 (6%); draw stored(12)≠tagged(4) |
| 6 | Lorehold Best-of Learned No Premium Mox | 100 | NO PROFILE | 33 | — — | 1.79/3.11 🔴 | 6/— | 6/— | CMC=0 nonland: 6; lands stored(33)≠tagged(32); ramp stored(6)≠tagged(20); draw stored(6)≠tagged(9) |
| 7 | Winota — Boros Combat Trigger Humans | 100 | OK | 34 | 31-35 ✅ | 2.35/2.54 ✅ | 10/— — | 3/— — | CMC=0 nonland: 5; draw stored(3)≠tagged(4) |
| 9 | Atraxa, Praetors' Voice — EDHREC (41k) | 100 | OK | 36 | 35-38 ✅ | 2.97/2.98 ✅ | 14/10-13 ⚠️ | 12/8-12 ✅ | CMC=0 nonland: 2; ramp stored(14)≠tagged(11); draw stored(12)≠tagged(13) |

*Legenda: OK | INCOMPLETE (<50 cards) | NO PROFILE | CMC CORRUPT (>25% NULL)*

### Diagnóstico Detalhado por Deck

#### Deck #1: Kinnan, Bonder Prodigy (13 cards, stored=13 — INCOMPLETE)
- **Profile:** `kinnan_bonder_prodigy.json` (anchor30 batch A) — lands [29-34], nonland_mana_sources [18-26], mana_dorks [10-16], artifact_mana [6-11], infinite_mana_pieces [4-8], payoffs_outlets [5-9], interaction_protection [9-14]
- **Lands:** Stored 29, tagged 0 vs perfil 29-34 ✅
- **CMC:** Stored 1.80 vs computed 2.82 (nonland, CMC>0). Delta +1.02.
- **Ramp:** Stored 4, tagged 4 vs perfil — —
- **Draw:** Stored 3, tagged 3 vs perfil — —
- **Corrupção:** tag NULL: 1 (7%); CMC=0 nonland: 2; lands stored(29)≠tagged(0)

#### Deck #2: Yuriko, the Tiger's Shadow (99 cards, stored=84 — OK)
- **Profile:** `yuriko_the_tigers_shadow.json` (anchor30 batch A) — lands [30-34], evasive_enablers [10-15], ninjas [10-17], topdeck_manipulation [7-12], high_mv_reveals [4-8], interaction [10-16], combo_finishers [0-5]
- **Lands:** Stored 33, tagged 35 vs perfil 30-34 ✅
- **CMC:** Stored 2.80 vs computed 3.23 (nonland, CMC>0). Delta +0.43.
- **Ramp:** Stored 8, tagged 8 vs perfil — —
- **Draw:** Stored 14, tagged 12 vs perfil — —
- **Corrupção:** tag NULL: 21 (21%); CMC=0 nonland: 2; lands stored(33)≠tagged(35); draw stored(14)≠tagged(12)

#### Deck #3: Korvold, Fae-Cursed King (11 cards, stored=11 — INCOMPLETE)
- **Profile:** `korvold_fae_cursed_king.json` (anchor30 batch A) — lands [34-37], ramp_treasure [10-14], sacrifice_fodder [10-16], sacrifice_outlets [6-10], aristocrat_payoffs [5-9], draw_value [6-10], interaction [8-12], combo_finishers [3-7]
- **Lands:** Stored 25, tagged 0 vs perfil 34-37 ⚠️
- **CMC:** Stored 3.20 vs computed 2.64 (nonland, CMC>0). Delta -0.56.
- **Ramp:** Stored 3, tagged 3 vs perfil 10-14 ⚠️
- **Draw:** Stored 1, tagged 1 vs perfil 6-10 ⚠️
- **Corrupção:** lands stored(25)≠tagged(0)

#### Deck #4: Teysa Karlov (80 cards, stored=80 — OK)
- **Profile:** `teysa_karlov.json` (anchor30 batch B) — lands [35-37], ramp [9-11], draw_value [10-14], interaction [8-11], board_wipes [2-4], protection [2-4], sacrifice_outlets [7-10], fodder_tokens [10-15], death_payoffs [7-10], recursion [4-7]
- **Lands:** Stored 35, tagged 15 vs perfil 35-37 ✅
- **CMC:** Stored 2.90 vs computed 2.74 (nonland, CMC>0). Delta -0.16.
- **Ramp:** Stored 15, tagged 15 vs perfil 9-11 ⚠️
- **Draw:** Stored 11, tagged 8 vs perfil 10-14 ✅
- **Corrupção:** tag NULL: 4 (5%); lands stored(35)≠tagged(15); draw stored(11)≠tagged(8)

#### Deck #5: Aesi, Tyrant of Gyre Strait (100 cards, stored=79 — OK)
- **Profile:** `aesi_tyrant_of_gyre_strait.json` (anchor30 batch B) — lands [39-43], ramp_extra_lands [14-18], supplemental_draw [6-9], interaction_counter [8-11], board_wipes_bounce [2-3], protection [2-4], landfall_payoffs [8-12], land_recursion_bounce [4-8], finishers [3-5]
- **Lands:** Stored 40, tagged 40 vs perfil 39-43 ✅
- **CMC:** Stored 2.61 vs computed 3.40 (nonland, CMC>0). Delta +0.79.
- **Ramp:** Stored 28, tagged 28 vs perfil 14-18 ⚠️
- **Draw:** Stored 12, tagged 4 vs perfil 6-9 ⚠️
- **Corrupção:** tag NULL: 6 (6%); draw stored(12)≠tagged(4)

#### Deck #6: Lorehold, the Historian (100 cards, stored=100 — NO PROFILE)
- **Profile:** NÃO ENCONTRADO — Lorehold, the Historian não está nos profiles anchor30.
- **Lands:** Stored 33, tagged 32
- **CMC:** Stored 1.79 vs computed 3.11 (nonland, CMC>0). Delta +1.32.
- **Ramp:** Stored 6, tagged 20
- **Draw:** Stored 6, tagged 9
- **Corrupção:** CMC=0 nonland: 6; lands stored(33)≠tagged(32); ramp stored(6)≠tagged(20); draw stored(6)≠tagged(9)

#### Deck #7: Winota, Joiner of Forces (100 cards, stored=100 — OK)
- **Profile:** `winota_joiner_of_forces.json` (anchor30 batch A) — lands [31-35], nonhuman_enablers [18-28], human_hits [16-24], stax_disruption [5-10], protection [5-8], combat_payoffs [4-8], interaction [6-10]
- **Lands:** Stored 34, tagged 34 vs perfil 31-35 ✅
- **CMC:** Stored 2.35 vs computed 2.54 (nonland, CMC>0). Delta +0.19.
- **Ramp:** Stored 10, tagged 10 vs perfil — —
- **Draw:** Stored 3, tagged 4 vs perfil — —
- **Corrupção:** CMC=0 nonland: 5; draw stored(3)≠tagged(4)

#### Deck #9: Atraxa, Praetors' Voice (100 cards, stored=100 — OK)
- **Profile:** `atraxa_praetors_voice.json` (anchor30 batch A) — lands [35-38], ramp_fixing [10-13], proliferate_engines [6-10], counter_payoffs [8-14], planeswalkers_superfriends [4-9], card_advantage [8-12], interaction [8-13], finishers [4-7]
- **Lands:** Stored 36, tagged 36 vs perfil 35-38 ✅
- **CMC:** Stored 2.97 vs computed 2.98 (nonland, CMC>0). Delta +0.01.
- **Ramp:** Stored 14, tagged 11 vs perfil 10-13 ⚠️
- **Draw:** Stored 12, tagged 13 vs perfil 8-12 ✅
- **Corrupção:** CMC=0 nonland: 2; ramp stored(14)≠tagged(11); draw stored(12)≠tagged(13)

---

### CMC Delta — Análise Sistêmica

| Deck | Stored CMC | Computed (nonland>0) | Delta | CMC NULL | % NULL |
|------|:----------:|:--------------------:|:-----:|:--------:|:-----:|
| Lorehold #6 | 1.79 | 3.11 | +1.32 🔴 | 0 | 0% |
| Kinnan #1 | 1.80 | 2.82 | +1.02 🔴 | 0 | 0% |
| Aesi #5 | 2.61 | 3.40 | +0.79 ⚠️ | 0 | 0% |
| Korvold #3 | 3.20 | 2.64 | -0.56 ⚠️ | 0 | 0% |
| Yuriko #2 | 2.80 | 3.23 | +0.43 ⚠️ | 0 | 0% |
| Winota #7 | 2.35 | 2.54 | +0.19 ✅ | 0 | 0% |
| Teysa #4 | 2.90 | 2.74 | -0.16 ✅ | 0 | 0% |
| Atraxa #9 | 2.97 | 2.98 | +0.01 ✅ | 0 | 0% |

**Diagnóstico:**
- 2 decks com delta CMC > 1.0 🔴 — stored significativamente diferente do computed.
- 5 decks com delta CMC > 0.3 ⚠️.
- A maioria dos stored CMCs são mais baixos que computed porque incluem CMC=0 (lands, moxes) que puxam a média para baixo.
- Nenhum deck tem CMC NULL — todos os CMCs estão populados no `deck_cards` (melhora vs validação anterior).
- **Recomendação:** Recomputation de `decks.avg_cmc` a partir de `AVG(cmc) FROM deck_cards WHERE cmc > 0 AND functional_tag != 'land'`.

### Stored vs Tagged — Divergências de Contagem

| Deck | Lands (stored/tagged) | Ramp (stored/tagged) | Draw (stored/tagged) |
|------|:---:|:---:|:---:|
| Kinnan #1 | 29/0 🔴 | 4/4 🟢 | 3/3 🟢 |
| Yuriko #2 | 33/35 🔴 | 8/8 🟢 | 14/12 🔴 |
| Korvold #3 | 25/0 🔴 | 3/3 🟢 | 1/1 🟢 |
| Teysa #4 | 35/15 🔴 | 15/15 🟢 | 11/8 🔴 |
| Aesi #5 | 40/40 🟢 | 28/28 🟢 | 12/4 🔴 |
| Lorehold #6 | 33/32 🔴 | 6/20 🔴 | 6/9 🔴 |
| Winota #7 | 34/34 🟢 | 10/10 🟢 | 3/4 🔴 |
| Atraxa #9 | 36/36 🟢 | 14/11 🔴 | 12/13 🔴 |

**Nota:** 🔴 indica divergência entre o valor armazenado em `decks` e a contagem via `functional_tag` em `deck_cards`. Isto sugere que `decks.ramp_count`/`draw_count`/`total_lands` não foram atualizados após reclassificações de tag.

### Mudanças vs Validação Anterior (2026-06-07 19:00Z)

1. **CMC computed refinado:** Agora exclui CMC=0 não-land também (antes incluía). Torna o computed mais preciso para curva de mana real.
2. **CMC NULL zerado:** Ao contrário da validação anterior que reportava 15-36% CMC NULL/0, a análise atual mostra que todas as cartas têm CMC populado no `deck_cards`. A divergência está no stored vs computed (inclusão de CMC=0), não em dados faltantes.
3. **Stored vs Tagged:** Nova métrica mostrando divergências entre `decks` e `deck_cards.functional_tag`. Lorehold #6 é o pior caso: ramp stored=6 vs tagged=20.
4. **Tags NULL:** Yuriko #2 com 21/99 (21%) permanece o pior caso. Lorehold #6 zerou tags NULL.
5. **Status de perfil:** 7/8 decks com profile EDHREC (mantido). Lorehold sem perfil (comandante custom).
6. **Winota e Atraxa já não são CMC CORRUPT:** Com CMC populado para todas as cartas, o status CMC CORRUPT (>25% NULL) não se aplica mais. Ambos têm CMC delta baixo (✅).

### Decks com INSERT INCOMPLETO ou Dados Corrompidos

| Deck | Problema | Severidade |
|------|------|:---:|
| Kinnan #1 | 13/100 cards. Lands não populadas no DB. Deck truncado. | 🔴 |
| Korvold #3 | 11/100 cards. Lands não populadas no DB. Deck truncado. | 🔴 |
| Yuriko #2 | 99 cards DB, stored=84. 21 tags NULL (21%). | 🟡 |
| Lorehold #6 | ramp stored(6)≠tagged(20), draw stored(6)≠tagged(9). Stored desatualizado pós-reclassificação. | 🔴 |
| Aesi #5 | 100 cards DB, stored=79. draw stored(12)≠tagged(4). | 🟡 |

**Ação recomendada:** Rodar recomputação de `decks.avg_cmc`, `decks.ramp_count`, `decks.draw_count`, `decks.total_lands` a partir de `deck_cards` para sincronizar stored com actual.

---

*Validação gerada por manaloom-mana-base-validator em 2026-06-08T01:17:41Z*
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
