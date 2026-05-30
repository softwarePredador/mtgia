# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-30T13:41Z** (manaloom-manager-watchdog)

## Resumo

|| Métrica | Valor ||
|:--|:--:||
| Total de crons (`include_disabled=True`) | **17** ||
| Habilitados | 17/17 ||
| Desabilitados | **0** ||
| `last_status=error` | **3** ||
| Nunca executaram (`last_run_at=null`) | **0** ||
| Stale (>1.5× schedule atrás, `enabled=true`) | **0** ||
| Ações de recuperação nesta execução | 2 (`run` em hermes-normal-audit + knowledge-synthesis) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 17 crons habilitados, **14 OK**, **3 com erro**, 0 desabilitados. Recuperação significativa desde snapshot anterior (2026-05-30T07:39Z: 3 OK, 13 error, 3 desabilitados).

## Análise de Recuperação

Snapshot anterior: **2026-05-30T07:39Z** (3 OK, 13 error, 3 desabilitados, bloqueado por jobs.json root-owned).
Este snapshot: **2026-05-30T13:41Z** (14 OK, 3 error, 0 desabilitados).

|| Métrica | 07:39Z | 13:41Z | Delta |
|:--|:--:|:--:|:--:|
| Total crons | 17 | 17 | 0 |
| Habilitados | 14 | 17 | +3 ✅ |
| Errors | 13 | 3 | **-10** ✅ |
| OK | 3 | 14 | **+11** ✅ |

**Crons recuperados (error → ok):**
- `manaloom-master-watchdog` — desabilitado → 🟢 ok
- `manaloom-hermes-normal-audit` — desabilitado → 🟢 ok (last_status agora ok)
- `manaloom-commander-knowledge-deep` — error → 🟢 ok
- `manaloom-gamechanger-research` — error → 🟢 ok
- `manaloom-tag-accuracy-reporter` — error → 🟢 ok
- `manaloom-mana-base-validator` — error → 🟢 ok
- `manaloom-knowledge-import` — error → 🟢 ok
- `lorehold-deck-scout` — error → 🟢 ok
- `lorehold-deck-validator` — error → 🟢 ok
- `lorehold-mulligan-analyst` — error → 🟢 ok
- `lorehold-evolution-oracle` — error → 🟢 ok
- `code-structure-auditor (4h)` — error → 🟢 ok
- `code-structure-auditor (weekly)` — desabilitado → habilitado (⏳ pending next run)
- `manaloom-logic-coherence-auditor` — error → 🟢 ok
- `manaloom-knowledge-synthesis` — never-run → triggered (⏳ pending)

## Crons de Auditoria / Gerenciais

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
| `757eefb8738b` | manaloom-master-watchdog | every 30m | sim | 2026-05-30T13:07Z | 34min | 🟢 ok | scheduled | recuperado |
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | sim | 2026-05-28T01:30Z | ~64h | 🟢 ok | scheduled | ⏳ **trigger neste run** — next_run_at rescheduled to ~13:41 |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | sim | 2026-05-28T01:36Z | ~64h | 🟢 ok | scheduled | próxima: dom 12:00Z |
| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-30T13:07Z | 34min | 🔴 error | scheduled | **esta execução** — erro HTTP 429 (rate limit transiente) |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | sim | 2026-05-28T02:22Z | ~63h | 🔴 error | scheduled | erro HTTP 502 em último run; próximo: dom 06:00Z; schedule semanal = não stale |
| `bb03201b8911` | manaloom-code-structure-auditor (4h) | every 180m | sim | 2026-05-30T12:34Z | 1h07m | 🟢 ok | scheduled | recuperado |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | sim | 2026-05-30T11:52Z | 1h49m | 🟢 ok | scheduled | recuperado |

## Crons de Conhecimento Commander

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | sim | 2026-05-30T10:40Z | 3h01m | 🟢 ok | scheduled | recuperado |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | sim | 2026-05-30T12:42Z | 59min | 🟢 ok | scheduled | recuperado |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | sim | 2026-05-30T10:43Z | 2h58m | 🟢 ok | scheduled | recuperado |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | sim | 2026-05-30T10:51Z | 2h50m | 🟢 ok | scheduled | recuperado |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | sim | 2026-05-30T12:27Z | 1h14m | 🟢 ok | scheduled | recuperado |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | sim | 2026-05-30T12:18Z | 1h23m | 🔴 error | scheduled | ⏳ **trigger neste run** — output anterior era 0 bytes (root-owned dir); next_run rescheduled |

## Lorehold Knowledge Pipeline

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
| `f20ac299992b` | lorehold-deck-scout | every 240m | sim | 2026-05-30T11:04Z | 2h37m | 🟢 ok | scheduled | recuperado |
| `712579b15767` | lorehold-deck-validator | every 480m | sim | 2026-05-30T11:26Z | 2h15m | 🟢 ok | scheduled | recuperado |
| `08468451a06a` | lorehold-mulligan-analyst | every 1440m | sim | 2026-05-30T11:28Z | 2h13m | 🟢 ok | scheduled | recuperado |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 1440m | sim | 2026-05-30T11:36Z | 2h05m | 🟢 ok | scheduled | recuperado |

## Crons com Erro Ativo (3)

### 1. manaloom-manager-watchdog (2d436c71bbf7) — 🔴 HTTP 429
- **Erro:** `RuntimeError: HTTP 429: Provider returned error`
- **Diagnóstico:** Rate limit transiente no provider openrouter/owl-alpha. Este cron é a própria instância que está rodando agora — o erro ocorreu no ciclo anterior.
- **Ação:** Nenhuma necessária. O cron já está executando (este run). Auto-recovery no próximo tick.
- **Classificação:** Transiente, não exige intervenção.

### 2. manaloom-code-structure-auditor weekly (577a0a669714) — 🔴 HTTP 502
- **Erro:** `RuntimeError: HTTP 502: Provider returned error` (em 2026-05-28T02:22Z)
- **Diagnóstico:** Erro de provider transiente. O cron é semanal (dom 06:00Z). Próximo run: 2026-05-31T06:00Z.
- **Ação:** Nenhuma necessária. O cron 4h (bb03201b8911) cobre a estrutura com mais frequência.
- **Classificação:** Transiente, next run já agendado.

### 3. manaloom-knowledge-synthesis (10a59b3bdf4d) — 🔴 Empty Output
- **Erro:** Output file 0 bytes, diretório de output root-owned
- **Diagnóstico:** O cron rodou mas não produziu output. Provável problema de permissão no diretório de output (root-owned).
- **Ação:** `cronjob(action='run')` disparado neste cycle. Aguardando resultado.
- **Classificação:** Parcialmente recuperado via trigger.

## Ações Realizadas Neste Cycle (2026-05-30T13:41Z)

|| Ação | Cron | Resultado |
|:-----|:------|:----------|
| `run` | manaloom-hermes-normal-audit | Aceito — next_run_at rescheduled to ~13:41Z |
| `run` | manaloom-knowledge-synthesis | Aceito — next_run_at rescheduled to ~13:41Z |

**Nota:** `cronjob(action='run')` apenas re-agenda o next_run_at. A execução real ocorre quando o scheduler tick processar o job.

## Alertas Pendentes

**🟡 P2 — knowledge-synthesis com output vazio:** Se o próximo run também falhar, investigar permissão no diretório `/opt/data/cron/output/10a59b3bdf4d/` (root-owned). Correção: `chown -R hermes:hermes /opt/data/cron/output/10a59b3bdf4d/`

## Mudanças desde Snapshot Anterior (07:39Z → 13:41Z)

### Crons Recuperados (error/desabilitado → ok)

| Cron | 07:39Z | 13:41Z |
|:-----|:--------|:--------|
| manaloom-master-watchdog | DESABILITADO | 🟢 ok |
| manaloom-hermes-normal-audit | DESABILITADO | 🟢 ok |
| manaloom-commander-knowledge-deep | 🔴 error | 🟢 ok |
| manaloom-gamechanger-research | 🔴 error | 🟢 ok |
| manaloom-tag-accuracy-reporter | 🔴 error | 🟢 ok |
| manaloom-mana-base-validator | 🔴 error | 🟢 ok |
| manaloom-knowledge-import | 🔴 error | 🟢 ok |
| manaloom-logic-coherence-auditor | 🔴 error | 🟢 ok |
| code-structure-auditor (4h) | 🔴 error | 🟢 ok |
| lorehold-deck-scout | 🔴 error | 🟢 ok |
| lorehold-deck-validator | 🔴 error | 🟢 ok |
| lorehold-mulligan-analyst | 🔴 error | 🟢 ok |
| lorehold-evolution-oracle | 🔴 error | 🟢 ok |

### Crons Ainda em Erro

| Cron | 07:39Z | 13:41Z |
|:-----|:--------|:--------|
| manaloom-manager-watchdog | 🔴 error | 🔴 error (429, esta execução) |
| code-structure-auditor (weekly) | DESABILITADO + error | 🔴 error (502, semanal) |
| manaloom-knowledge-synthesis | never-run | 🔴 error (empty output) |

## Observações Importantes

- **Recuperação massiva:** O snapshot 07:39Z estava bloqueado por jobs.json root-owned. Entre 07:39Z e 13:41Z, o scheduler conseguiu processar a maioria dos crons, recuperando 14 deles.
- **Provider errorsTodos os erros de 07:39Z eram HTTP 502 (provider outage). Os 3 erros restantes neste snapshot são: 429 (rate limit neste cron), 502 no weekly (transiente), e empty output no knowledge-synthesis (permissão).
- **Branch estava limpo:** `git status --short` mostra apenas `__pycache__` de cron artifact. Nenhuma alteração de produto.

---

*Snapshot: 2026-05-30T13:41Z | Branch: codex/hermes-analysis-docs | Fleet: 17 crons (17 enabled, 14 ok, 3 error)*
*Tag Accuracy: 2026-05-30T08:00Z | Global: 83.3% (378/454) | Tags: 29 avaliadas, 14 perfeitas, 8 críticas (<50%)*

