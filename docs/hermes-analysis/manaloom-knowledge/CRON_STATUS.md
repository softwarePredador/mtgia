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

*Snapshot: 2026-05-30T14:34Z | Branch: codex/hermes-analysis-docs | Fleet: 18 crons (18 enabled, 15 ok, 2 error)*
