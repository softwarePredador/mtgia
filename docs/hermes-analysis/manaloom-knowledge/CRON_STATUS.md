# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-30T14:34Z** (manaloom-manager-watchdog)

## Resumo

|| Métrica | Valor ||
|:--|:--:||
| Total de crons (`include_disabled=True`) | **18** ||
| Habilitados | 18/18 ||
| Desabilitados | **0** ||
| `last_status=error` | **2** ||
| Nunca executaram (`last_run_at=null`) | **0** ||
| Stale (>1.5× schedule atrás, `enabled=true`) | **0** ||
| Ações de recuperação nesta execução | 1 resume (master-watchdog) + 1 run (battle-analyst) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 18 crons habilitados, **15 OK**, **2 com erro**, 0 desabilitados. Novo cron `lorehold-battle-analyst` detectado e inicializado.

## Análise de Recuperação

Snapshot anterior: **2026-05-30T13:41Z** (14 OK, 3 error, 0 desabilitados)
Este snapshot: **2026-05-30T14:34Z** (15 OK, 2 error, 0 desabilitados)

|| Métrica | 13:41Z | 14:34Z | Delta |
|:--|:--:|:--:|:--:|
| Total crons | 17 | 18 | +1 🆕 |
| Habilitados | 17 | 18 | +1 ✅ |
| Errors | 3 | 2 | **-1** ✅ |
| OK | 14 | 15 | **+1** ✅ |

**Mudanças desde snapshot anterior:**
- 🆕 `lorehold-beck-analyst` (94f8590b1beb) — **novo cron detectado** (every 480m), nunca havia rodado. Scheduler trigger aceito; next_run_at: ~14:34Z.
- ✅ `manaloom-master-watchdog` (757eefb8738b) — reabilitado (enabled=false → true) via `resume`. Next run: ~15:04Z.
- ✅ `manaloom-manager-watchdog` (2d436c71bbf7) — recuperado (🔴 429 → 🟢 ok). Este ciclo executou com sucesso.

## Crons de Auditoria / Gerenciais

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-30T13:51Z | 43min | 🟢 ok | scheduled | **esta execução** — auto-recuperado |
| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-30T13:51Z | 43min | 🟢 ok | scheduled | ✅ **resume neste run** (estava disabled) |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-30T14:28Z | 6min | 🟢 ok | scheduled | ✅ recuperado — próximo: 16:00Z |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | sim | 2026-05-30T14:30Z | 4min | 🟢 ok | scheduled | ✅ próximo: dom 12:00Z |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | sim | 2026-05-28T02:22Z | ~64h | 🔴 error | scheduled | erro HTTP 502 em último run; próximo: dom 06:00Z; schedule semanal = não stale |
| `bb03201b8911` | manaloom-code-structure-auditor (4h) | every 180m | sim | 2026-05-30T12:34Z | 2h00m | 🟢 ok | scheduled | ✅ |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | sim | 2026-05-30T11:52Z | 2h42m | 🟢 ok | scheduled | ✅ |

## Crons de Conhecimento Commander

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | sim | 2026-05-30T14:32Z | 2min | 🟢 ok | scheduled | ✅ |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | sim | 2026-05-30T14:33Z | 1min | 🟢 ok | scheduled | ✅ |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | sim | 2026-05-30T10:43Z | 3h51m | 🟢 ok | scheduled | ✅ |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | sim | 2026-05-30T10:51Z | 3h43m | 🟢 ok | scheduled | ✅ |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | sim | 2026-05-30T12:27Z | 2h07m | 🟢 ok | scheduled | ✅ |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | sim | 2026-05-30T12:18Z | 2h16m | 🔴 error | scheduled | erro persistente (empty output); último trigger foi em 13:41Z; aguardando próximo tick |

## Lorehold Knowledge Pipeline

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
| `94f8590b1beb` | lorehold-battle-analyst | every 480m | sim | null | nunca | ⏳ scheduled | 🆕 **novo** — `run` disparado neste cycle; next_run: ~14:34Z |
| `f20ac299992b` | lorehold-deck-scout | every 120m | sim | 2026-05-30T11:04Z | 2h30m | 🟢 ok | scheduled | ✅ |
| `712579b15767` | lorehold-deck-validator | every 180m | sim | 2026-05-30T11:26Z | 3h08m | 🟢 ok | scheduled | ✅ |
| `08468451a06a` | lorehold-mulligan-analyst | every 360m | sim | 2026-05-30T11:28Z | 3h06m | 🟢 ok | scheduled | ✅ |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 720m | sim | 2026-05-30T11:36Z | 2h58m | 🟢 ok | scheduled | ✅ |

## Crons com Erro Ativo (2)

### 1. manaloom-code-structure-auditor weekly (577a0a669714) — 🔴 HTTP 502
- **Erro:** `RuntimeError: HTTP 502: Provider returned error` (em 2026-05-28T02:22Z)
- **Diagnóstico:** Erro de provider transiente. O cron é semanal (dom 06:00Z). Próximo run: 2026-06-01T06:00Z.
- **Ação:** Nenhuma necessária. O cron 4h (bb03201b8911) cobre a estrutura com mais frequência.
- **Classificação:** Transiente, next run já agendado.

### 2. manaloom-knowledge-synthesis (10a59b3bdf4d) — 🔴 Empty Output
- **Erro:** Output file 0 bytes, diretório de output root-owned (último run: 2026-05-30T12:18Z)
- **Diagnóstico:** O cron rodou mas não produziu output. Provável problema de permissão no diretório de output (root-owned). Último trigger (em 13:41Z) ainda não produziu resultado.
- **Ação:** Aguardando scheduler processar o próximo tick. Se falhar novamente, investigar `/opt/data/cron/output/10a59b3bdf4d/` (root-owned).
- **Classificação:** Persistente, aguardando retry.

## Ações Realizadas Neste Cycle (2026-05-30T14:34Z)

|| Ação | Cron | Resultado |
|:-----|:------|:----------|
| `resume` | manaloom-master-watchdog | Aceito — reabilitado (enabled=true); next_run: ~15:04Z |
| `run` | lorehold-battle-analyst | Aceito — next_run_at rescheduled to ~14:34Z |

**Nota:** `cronjob(action='run')` apenas re-agenda o next_run_at. A execução real ocorre quando o scheduler tick processar o job.

## Alertas Pendentes

**🟡 P2 — knowledge-synthesis com output vazio:** Se o próximo run também falhar, investigar permissão no diretório `/opt/data/cron/output/10a59b3bdf4d/` (root-owned). Correção: `chown -R hermes:hermes /opt/data/cron/output/10a59b3bdf4d/`

**🟢 Resolvido — master-watchdog desabilitado:** Estava `enabled=false` (artifact de branch switch). `resume` aplicado com sucesso neste cycle.

## Mudanças desde Snapshot Anterior (13:41Z → 14:34Z)

### Recuperações / Reabilitações

| Cron | 13:41Z | 14:34Z |
|:-----|:--------|:--------|
| manaloom-master-watchdog | disabled (paused) | 🟢 ok (resume) |
| manaloom-manager-watchdog | 🟢 ok | 🟢 ok (executou este cycle) |
| lorehold-battle-analyst | 🆕 não existia | ⏳ run triggered |

### Crons Ainda em Erro

| Cron | 13:41Z | 14:34Z |
|:-----|:--------|:--------|
| code-structure-auditor (weekly) | 🔴 error (502) | 🔴 error (502, semanal) |
| manaloom-knowledge-synthesis | 🔴 error (empty) | 🔴 error (empty, aguardando retry) |

## Observações Importantes

- **Fleet cresceu de 17 → 18 crons:** Novo cron `lorehold-battle-analyst` adicionado à pipeline Lorehold.
- **master-watchdog reabilitado:** Estava disabled desde artifact de branch switch. Resolvido neste cycle.
- **Todas as mudanças são configuração de scheduler:** Nenhum arquivo de produto foi modificado. Apenas cron config + CRON_STATUS.md.
- **Branch limpo:** `git status --short` mostra apenas cron artifacts não-intencionais (`__pycache__`, battle scripts, deck BATTLE_LOG).

---

## Mana Base Validation Report (manaloom-mana-base-validator)

> Relatório gerado automaticamente. Última atualização: **2026-05-30T14:47Z**

**Decks analisados:** 8
**Critérios:** Lands vs perfil EDHREC, Ramp/Draw/Remoção vs ranges do perfil
**Thresholds:** diff=0 ✅ OK | diff=1 🔵 BLUE | diff 2-3 🟡 WARN | diff≥4 🔴 CRIT
**Regras especiais:** SUM(quantity) < 50 → ⚪ INCOMPLETE DATA | Sem perfil → ✅ OK (sem perfil) | 99/100 cards = 🟡 WARN (within tolerance)

### Resumo Geral

| # | Deck | Total Cards | Status | Lands SQLite | Lands Perfil | Observação |
|---|------|:-----------:|:------:|:------------:|:------------:|------------|
| 1 | Kinnan, Bonder Prodigy | 13/100 | ⚪ INCOMPLETE | 0 | 29-34 | Apenas 13/100 cartas inseridas |
| 2 | EDHREC Average - Dimir Ninja Topdeck Tempo | 99/100 | 🟡 WARN | 35 | 30-34 | 99/100 cards (1 short); Lands 35 vs 30-34 |
| 3 | EDHREC Average Default (Korvold) | 11/100 | ⚪ INCOMPLETE | 0 | 34-37 | Apenas 11/100 cartas inseridas |
| 4 | EDHREC Average Default (Teysa) | 80/100 | 🔴 CRIT | 15 | 35-37 | Teysa: 80 cards, lands=15 (perfil 35-37), ramp CRIT |
| 5 | Aesi EDHREC Average Default | 100/100 | 🟡 WARN | 40 | 39-43 | protection: DB=7 vs perfil [2-4] |
| 6 | Lorehold Spellslinger | 100/100 | ✅ OK | 35 | — | Sem perfil de referência |
| 7 | EDHREC Average - Boros Combat Trigger Humans | 100/100 | 🟡 WARN | 34 | 31-35 | protection: DB=10 vs perfil [5-8] |
| 9 | Atraxa EDHREC Average (41k decks) | 100/100 | ✅ OK | 36 | 35-38 | Dentro do perfil |

### Detalhamento — Decks Com Perfis EDHREC

**Deck #4: EDHREC Average Default (Teysa Karlov)** — 🔴 CRIT
- Total: 80/100 cards | Lands: 15 (perfil: 35-37)
- 🔴 Incomplete deck: apenas 80/100 cartas inseridas (faltam 20)
- 🔴 Lands 15 está 20 abaixo do perfil [35-37]
- 🔴 ramp: DB=15 vs perfil [9-11] (4 acima)
- 🔵 board_wipes: DB=1 vs perfil [2-4]
- 🔵 recursion: DB=3 vs perfil [4-7]
- **Nota:** EDHREC aggregate parcial — deck não está completo, métricas podem não representar deck real.

**Deck #5: Aesi EDHREC Average Default** — 🟡 WARN
- Total: 100/100 cards | Lands: 40 (perfil: 39-43)
- 🟡 protection: DB=7 vs perfil [2-4] (d=3)
- ✅ Lands 40 in [39-43]

**Deck #7: EDHREC Average - Boros Combat Trigger Humans (Winota)** — 🟡 WARN
- Total: 100/100 cards | Lands: 34 (perfil: 31-35)
- 🟡 protection: DB=10 vs perfil [5-8] (d=2)
- ✅ Lands 34 in [31-35]

**Deck #9: Atraxa EDHREC Average (41k decks)** — ✅ OK
- Total: 100/100 cards | Lands: 36 (perfil: 35-38)
- ✅ Lands 36 in [35-38]

### Decks com Dados Incompletos (SUM(quantity) < 50)

| # | Deck | Total Cards | Motivo |
|---|------|:-----------:|--------|
| 1 | Kinnan, Bonder Prodigy | 13/100 | cEDH seed — apenas 13 cartas inseridas |
| 3 | EDHREC Average Default (Korvold) | 11/100 | Estatística agregada EDHREC, não deck real |

**Ação:** Estes decks precisam de inserção completa. Métricas de mana não são significativas.

### Decks Sem Perfil de Referência

| # | Deck | Total Cards | Nota |
|---|------|:-----------:|------|
| 6 | Lorehold Spellslinger | 100/100 | Sem profile no artifact — validação manual |

**Nota:** Sem perfil não podem ser validados contra EDHREC. ✅ OK (sem perfil).

---
*Validação: 2026-05-30T14:47Z | validate_mana.py | 8 decks (5 c/ perfil, 2 incompletos, 1 s/ perfil)*

**Legenda:** ✅ OK | 🟡 WARN (d=2-3) | 🔴 CRIT (d≥4) | ⚪ INCOMPLETE (<50 cards)

---

## Precisão das Functional Tags (manaloom-tag-accuracy-reporter)

> Relatório gerado automaticamente. Última atualização: **2026-05-30T14:34Z**

### Resumo Geral

| Métrica | Valor |
|:--------|:-----:|
| **Precisão total** | **83.3%** (378/454 classificações corretas) |
| Tags avaliadas | 29 |
| Tags com 100% | 14 |
| Tags com < 50% | 7 |

### Tags com Precisão 100% (14)

`land` (87/87), `ramp` (53/53), `draw` (32/32), `removal` (30/30), `tutor` (6/6), `board_wipe` (3/3), `recursion` (3/3), `wipe` (1/1), `sacrifice_outlet` (1/1), `finisher` (2/2), `utility` (76/76), `creature` (22/22), `planeswalker` (2/2), `artifact` (2/2), `enchantment` (3/3)

### Tags com Precisão < 50% — Atenção Requerida (7)

| Tag | Precisão | Amostra | Problema |
|:----|:--------:|:-------:|:---------|
| `ninja` | 0.0% | 17/17 erradas | Tag muito específica — classificador não reconhece ninja como função |
| `ramp + combo_piece` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `recursion + wincon` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `ramp + payoff` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `payoff + removal` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `payoff + token_maker` | 0.0% | 1/1 errada | Tag composta rara — amostra insuficiente |
| `stax_disruption` | 0.0% | 3/3 erradas | Classificador não possui categoria stax |

### Tags com Precisão 50-75% (3)

| Tag | Precisão | Amostra |
|:----|:--------:|:-------:|
| `payoff` | 35.5% | 11/31 |
| `combo_piece` | 50.0% | 1/2 |
| `enabler` | 50.0% | 21/42 |
| `other` | 50.0% | 1/2 |
| `protection` | 69.2% | 9/13 |
| `wincon` | 75.0% | 6/8 |
| `engine` | 75.0% | 6/8 |

### Análise

**Pontos fortes:** Tags estruturais (`land`, `creature`, `artifact`, `enchantments`) e funções primárias (`ramp`, `draw`, `removal`, `tutor`) têm precisão perfeita. O classificador é confiável para categorias básicas.

**Pontos fracos:**
1. **Tags compostas** (ex: `ramp + combo_piece`, `payoff + removal`) têm amostra mínima (1 caso cada) e 0% de precisão — o classificador não lida bem com multi-função composta.
2. **`stax_disruption` (0/3):** O classificador não possui uma categoria dedicada para stax. Cartas como `Orim's Chant` são classificadas como algo diferente.
3. **`ninja` (0/17):** Tag muito específica de tribo — o classificador funcional não captura tribos como função.
4. **`payoff` (35.5%):** Tag ambígua — o classificador confunde payoff com wincon ou engine.
5. **`enabler` (50.0%):** Fronteira difícil — distinção entre enabler e engine é sutil.

**Recomendações:**
- Tags compostas com amostra = 1 devem ser ignoradas estatisticamente (ruído).
- `stax_disruption` precisa de uma categoria dedicada no classificador.
- `payoff` e `enabler` precisam de regras mais claras na classificação.
- `ninja` deve ser reclassificada como `creature` (tribo não é função).

---

*Snapshot: 2026-05-30T14:34Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 15 ok, 2 error)*
