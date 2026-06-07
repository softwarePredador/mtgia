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

> **Data:** 2026-06-07T19:00:00Z
> **Cron:** manaloom-mana-base-validator
> **Decks analisados:** 8
> **Profiles:** 24 profiles (3 batch dirs: anchor30 A/B/C)
> **Método:** Profile matching via JSON file names; lands/ramp/draw via `role_targets.{min,max}`; CMC computed from `deck_cards` excluding NULL/0 and lands

### Resumo Geral — Validação vs Perfis EDHREC

| # | Deck | Cards | Status | Lands (stored) | Perfil Lands | CMC (stored/computed) | Ramp (stored/perfil) | Draw (stored/perfil) | Dados Corrompidos |
|---|------|:---:|:------:|:---:|:------------:|:---:|:---:|:---:|:---|
| 1 | Kinnan, Bonder Prodigy | 13 | INCOMPLETE | 29 | 29-34 | 1.8/2.8 ⚠️ | 4/— | 3/— | CMC NULL/0: 2/13 (15%); tag NULL: 1/13 (8%) |
| 2 | Yuriko — Dimir Ninja Topdeck Tempo | 84 | OK | 33 | 30-34 ✅ | 2.8/3.43 ⚠️ | 8/— | 14/— | CMC NULL/0: 19/84 (23%); tag NULL: 21/84 (25%) |
| 3 | Korvold — EDHREC Average Default | 11 | INCOMPLETE | 25 | 34-37 ⚠️ | 3.2/2.64 ⚠️ | 3/10-14 ⚠️ | 1/6-10 ⚠️ | CMC delta: +0.56; lands under profile min |
| 4 | Teysa Karlov — EDHREC Average | 80 | OK | 35 | 35-37 ✅ | 2.9/2.64 ⚠️ | 15/9-11 ⚠️ | 11/10-14 ✅ | CMC NULL/0: 15/80 (19%); ramp stored acima do perfil |
| 5 | Aesi EDHREC Average Default | 79 | OK | 40 | 39-43 ✅ | 2.61/3.35 ⚠️ | 28/14-18 ⚠️ | 12/6-9 ⚠️ | CMC NULL/0: 19/79 (24%); ramp/draw stored acima do perfil |
| 6 | Lorehold Best-of Learned No Premium Mox | 100 | NO PROFILE | 33 | — | 1.79/3.14 🔴 | 6 (stored) / 19 (actual) | 6 (stored) / 9 (actual) | CMC NULL/0: 36/100 (36%); CMC delta: -1.35 (maior); ramp stored=6 vs actual=19 (classificador corrigido) |
| 7 | Winota — Boros Combat Trigger Humans | 85 | CMC CORRUPT | 34 | 31-35 ✅ | 2.35/2.54 ✅ | 10/— | 3/— | CMC NULL/0: 22/85 (26%) |
| 9 | Atraxa, Praetors' Voice — EDHREC (41k) | 91 | CMC CORRUPT | 36 | 35-38 ✅ | 2.97/2.98 ✅ | 14/10-13 ⚠️ | 12/8-12 ✅ | CMC NULL/0: 29/91 (32%); ramp stored levemente acima |

*Legenda: OK | INCOMPLETE (<50 cards) | NO PROFILE | CMC CORRUPT (>25% NULL)*

### Diagnóstico Detalhado por Deck

#### Deck #1: Kinnan, Bonder Prodigy (13 cards — INCOMPLETO)
- **Profile:** `kinnan_bonder_prodigy.json` (anchor30 batch A) — lands [29-34], nonland_mana_sources [18-26]
- **Lands:** Stored 29 ✅ (no range). Apenas 13 cartas não-land no DB — lands não populadas.
- **CMC:** Stored 1.80 vs computed 2.80 (nonland, >0). Delta -1.00: stored inclui CMC=0 de Chrome Mox/Walking Ballista.
- **Corrupção:** 2/13 CMC NULL/0, 1/13 tag NULL (Freed from the Real)

#### Deck #2: Yuriko, the Tiger's Shadow (84 cards — OK)
- **Profile:** `yuriko_the_tigers_shadow.json` (anchor30 batch A) — lands [30-34], evasive_enablers [10-15], ninjas [10-17]
- **Lands:** Stored 33 ✅. 16/84 tagged as land (lands = CMC=0 tagged land, +4 land CMC=0 not tagged).
- **CMC:** Stored 2.80 vs computed 3.43. Delta -0.63: 19 lands com CMC=0 puxando stored para baixo.
- **Corrupção:** 🔴 21/84 (25%) tag NULL — pior caso. Un evasivos, ninjas e split cards sem classificação.

#### Deck #3: Korvold, Fae-Cursed King (11 cards — INCOMPLETO)
- **Profile:** `korvold_fae_cursed_king.json` (anchor30 batch A) — lands [34-37], ramp_treasure [10-14], draw_value [6-10]
- **Lands:** Stored 25 ⚠️ (abaixo do perfil 34-37). Apenas 11 cartas no DB.
- **Ramp:** Stored 3 vs ramp_treasure [10-14] ⚠️
- **Draw:** Stored 1 vs draw_value [6-10] ⚠️
- **Status:** Deck truncado — precisa de import completo (99 cartas esperadas).

#### Deck #4: Teysa Karlov (80 cards — OK)
- **Profile:** `teysa_karlov.json` (anchor30 batch B) — lands [35-37], ramp [9-11], draw_value [10-14]
- **Lands:** Stored 35 ✅. 15/80 tagged as land (20 basic lands não populadas no DB).
- **Ramp:** Stored 15 ⚠️ vs ramp [9-11] — 4 acima do máximo. Possível over-count de ramp (signets e rocks contados como ramp mas podem incluir mana dorks e rituais).
- **Draw:** Stored 11 ✅ vs draw_value [10-14].
- **CMC:** Stored 2.90 vs computed 2.64. Delta +0.26 — stored mais alto que real.

#### Deck #5: Aesi, Tyrant of Gyre Strait (79 cards — OK)
- **Profile:** `aesi_tyrant_of_gyre_strait.json` (anchor30 batch B) — lands [39-43], ramp_extra_lands [14-18], supplemental_draw [6-9]
- **Lands:** Stored 40 ✅. 19/79 tagged as land (21 basic lands não populadas).
- **Ramp:** Stored 28 ⚠️ vs ramp_extra_lands [14-18] — 10 acima do máximo. Aesi tem muita ramp (land ramp + artifact ramp + dorks) — stored pode superestimar.
- **Draw:** Stored 12 ⚠️ vs supplemental_draw [6-9] — Aesi é comandante que draw por landfall, então draw extra é esperado.

#### Deck #6: Lorehold, the Historian (100 cards — NO PROFILE)
- **Profile:** NÃO ENCONTRADO — Lorehold é comandante custom do sistema, não está nos profiles anchor30.
- **Lands:** Stored 33. 31/100 tagged as land, 2 lands (Inventors' Fair, Prismatic Vista) com tag 'unknown'.
- **CMC:** Stored 1.79 vs computed 3.14. Delta -1.35 🔴 — maior divergência. 36% CMC NULL/0.
- **Ramp:** Stored 6 vs actual 19 (via deck_cards `functional_tag='ramp'`). O stored foi calculado ANTES da correção do classificador (Gap 15 resolvido). Após correção, 19 cartas têm tag 'ramp'. O stored NÃO reflete a realidade.
- **Draw:** Stored 6 vs actual 9 (via deck_cards).

#### Deck #7: Winota, Joiner of Forces (85 cards — CMC CORRUPT)
- **Profile:** `winota_joiner_of_forces.json` (anchor30 batch A) — lands [31-35], nonhuman_enablers [18-28], human_hits [16-24]
- **Lands:** Stored 34 ✅. 19/85 tagged as land (15 basic lands não populadas).
- **CMC:** Stored 2.35 vs computed 2.54 — delta baixo (-0.19), mais preciso que a maioria ✅.
- **Corrupção:** 22/85 (26%) CMC NULL/0 — acima do threshold de 25%.

#### Deck #9: Atraxa, Praetors' Voice (91 cards — CMC CORRUPT)
- **Profile:** `atraxa_praetors_voice.json` (anchor30 batch A) — lands [35-38], ramp_fixing [10-13], card_advantage [8-12]
- **Lands:** Stored 36 ✅. 27/91 tagged as land (9 basic lands não populadas).
- **CMC:** Stored 2.97 vs computed 2.98 — delta -0.01 ✅ mais preciso da frota.
- **Ramp:** Stored 14 ⚠️ vs ramp_fixing [10-13] — 1 acima.
- **Draw:** Stored 12 ✅ vs card_advantage [8-12].
- **Corrupção:** 29/91 (32%) CMC NULL/0 — maioria são lands com CMC=0 (correto), mas inclui Astral Cornucopia (X=0) e Everflowing Chalice (X=0).

---

### CMC Corruption — Análise Sistêmica 🔴

| Deck | Stored CMC | Computed CMC (nonland, >0) | Delta | CMC NULL/0 | % NULL |
|------|:----------:|:--------------------------:|:-----:|:----------:|:-----:|
| Kinnan #1 | 1.80 | 2.80 | -1.00 🔴 | 2 | 15% |
| Yuriko #2 | 2.80 | 3.43 | -0.63 🔴 | 19 | 23% |
| Korvold #3 | 3.20 | 2.64 | +0.56 🔴 | 0 | 0% |
| Teysa #4 | 2.90 | 2.64 | +0.26 ⚠️ | 15 | 19% |
| Aesi #5 | 2.61 | 3.35 | -0.74 🔴 | 19 | 24% |
| Lorehold #6 | 1.79 | 3.14 | -1.35 🔴 | 36 | 36% |
| Winota #7 | 2.35 | 2.54 | -0.19 ✅ | 22 | 26% |
| Atraxa #9 | 2.97 | 2.98 | -0.01 ✅ | 29 | 32% |

**Diagnóstico:**
- **Todos os decks** exceto Korvold (#3) têm cartas com CMC=0.0 (lands + Chrome Mox/Everflowing Chalice/Astral Cornucopia).
- O CMC stored parece incluir CMC=0 (puxa média para baixo), enquanto o computed exclui CMC=0 e lands (mais preciso para não-lands).
- **Lorehold #6 é o pior:** 36% CMC NULL/0, delta -1.35 — o deck é inanalisável para curva de mana com dados atuais.
- **Korvold #3:** Stored MAIOR que computed (+0.56) — único caso onde stored > computed, sugere que as 11 cartas têm CMCs altos e o stored foi calculado diferentemente.
- **Winota #7 e Atraxa #9** têm os CMCs mais precisos (delta < 0.2) apesar de alta % de NULL — porque a maioria dos NULL são lands.

**Recomendação:** Corrigir `decks.avg_cmc` para todos os decks. O stored atual é inconfiável. Usar `AVG(cmc) FROM deck_cards WHERE cmc > 0 AND functional_tag != 'land'` como fonte de verdade.

### Tags NULL/Unknown — Piora em Yuriko e Melhora em Lorehold

| Deck | Tags NULL/Unknown | % | Pior caso |
|------|:---:|:---:|------|
| Kinnan #1 | 1/13 | 8% | Freed from the Real |
| Yuriko #2 | 21/84 | 25% 🔴 | 21 cartas: unblockable creatures, ninjas, split cards |
| Korvold #3 | 0/11 | 0% | — |
| Teysa #4 | 4/80 | 5% | Dictate of Erebos, Grave Pact, Luminous Broodmoth, Teysa Karlov |
| Aesi #5 | 6/79 | 8% | Ashaya, Azusa, Mossborn Hydra, Murkfiend Liege, Retreat to Coralhelm, Whelming Wave |
| Lorehold #6 | 3/100 | 3% 🟢 | Inventors' Fair, Prismatic Vista, Reforge the Soul (tag='unknown') |
| Winota #7 | 0/85 | 0% ✅ | — |
| Atraxa #9 | 0/91 | 0% ✅ | — |

**Yuriko #2 permanece o pior caso** com 25% de cartas sem tag. Lorehold #6 melhorou de ~30% para 3% após correção do classificador.

### Mudanças vs Validação Anterior (2026-06-07 12:54Z)

1. **Ramp e Draw agora com perfil:** Mapeamento de `role_targets` específicos → comparação direta (ramp_treasure, draw_value, ramp, ramp_fixing, card_advantage, etc.)
2. **Lorehold ramp stored vs actual:** Identificada divergência massiva: stored=6 vs actual=19. O stored foi calculado ANTES da correção do classificador (Gap 15, resolvido 2026-06-03). O `decks.ramp_count` e `decks.draw_count` NÃO foram atualizados após a reclassificação.
3. **Status CMC CORRUPT:** Winota #7 e Atraxa #9 agora marcados como CMC CORRUPT (>25% NULL). O threshold foi aplicado corretamente.
4. **7/8 commanders com profile:** Mantido. Lorehold sem perfil (comandante custom).
5. **CMC delta:** Lorehold #6 piorou de +1.35 para -1.35 (sinal corrigido — stored é MENOR que computed, confirmando que stored inclui CMC=0 puxando média para baixo).

### Decks com INSERT INCOMPLETO ou Dados Corrompidos

| Deck | Problema | Severidade |
|------|------|:---:|
| Kinnan #1 | 13/100 cards. Lands não populadas. Deck truncado. | 🔴 |
| Korvold #3 | 11/100 cards. Lands não populadas. Deck truncado. | 🔴 |
| Yuriko #2 | 84 cards (faltam 16). 25% tags NULL. 23% CMC NULL. | 🟡 |
| Lorehold #6 | `ramp_count`=6 vs actual=19. `draw_count`=6 vs actual=9. Stored desatualizado. | 🔴 |
| Aesi #5 | 79 cards (faltam 21). `ramp_count`=28 vs perfil 14-18. | 🟡 |

**Ação recomendada:** Rodar script de recomputação de `decks.avg_cmc`, `decks.ramp_count`, `decks.draw_count` a partir de `deck_cards` para sincronizar stored com actual.

---

*Validação gerada por manaloom-mana-base-validator em 2026-06-07T19:00:00Z*
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
