# ManaLoom Cron Status

> Relatório gerencial de todos os crons do projeto.
> Atualizado automaticamente pelo cron `manaloom-manager-watchdog`.
> Última atualização: **2026-05-30T07:39Z** (manaloom-manager-watchdog)

## Resumo

|| Métrica | Valor ||
|:--|:--:||
| Total de crons (`include_disabled=True`) | **17** ||
| Habilitados | 14/17 ||
| Desabilitados | **3** ||
| `last_status=error` | **13** ||
| Nunca executaram (`last_run_at=null`) | **1** ||
| Stale (>1.5× schedule atrás, `enabled=true`) | **8+** |
| Ações de recuperação nesta execução | 0 (bloqueado — ver abaixo) |
| Branch do workdir | `codex/hermes-analysis-docs` |

**Estado geral:** 17 crons no total, **3 desabilitados**, **13 com erro**, **3 OK**, 1 nunca executou. Degradação severa desde último snapshot (2026-05-28T06:57Z: 15 crons, 0 desabilitados, 5 erros).

**🚨 BLOQUEIO CRÍTICO:** O arquivo `/opt/data/cron/jobs.json` estava com permissão `0600` owned por `root` durante parte da execução. O processo Hermes roda como usuário `hermes` e **não conseguiu ler nem escrever** no banco de dados de crons no segundo pedido de listagem. Ações de `resume` e `run` **não puderam ser executadas**.

**Correção necessária (operador):**
```bash
chmod 644 /opt/data/cron/jobs.json
# ou
chown hermes:hermes /opt/data/cron/jobs.json
```

## Análise de Degradação

Último snapshot válido: **2026-05-28T06:57Z** (15 crons, 5 erros todos HTTP 502).
Este snapshot: **2026-05-30T07:39Z** (17 crons, 13 erros, 3 desabilitados, 1 never-run).

| Métrica | 2026-05-28T06:57Z | 2026-05-30T07:39Z | Delta |
|:--|:--:|:--:|:--:|
| Total crons | 15 | 17 | +2 🆕 |
| Desabilitados | 0 | **3** | **+3** 🔴 |
| Errors | 5 | **13** | **+8** 🔴 |
| OK | 10 | 3 | -7 |
| Never-run | 0 | **1** | +1 |

**Novos crons (não presentes no snapshot anterior):**
- `manaloom-logic-coherence-auditor` (de6fb777f5d1) — every 120m, 🔴 error
- `manaloom-knowledge-synthesis` (10a59b3bdf4d) — every 120m, never-run

## Crons de Auditoria / Gerenciais

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
|| `757eefb8738b` | manaloom-master-watchdog | every 30m | **não** | 2026-05-28T11:28Z | ~44h | 🟢 ok | **paused** | 🔴 **DESABILITADO** — precisa `resume` |
|| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | **não** | 2026-05-28T01:30Z | ~44h | 🟢 ok | **paused** | 🔴 **DESABILITADO** — precisa `resume` |
|| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | sim | 2026-05-28T01:36Z | ~44h | 🟢 ok | scheduled | próxima: dom 12:00Z |
|| `2d436c71bbf7` | manaloom-manager-watchdog | every 30m | sim | 2026-05-30T07:06Z | 33min | 🔴 error | scheduled | **esta execução** |
|| `577a0a669714` | manaloom-code-structure-auditor (weekly) | 0 6 * * 0 | **não** | 2026-05-28T02:22Z | ~49h | 🔴 error | **paused** | 🔴 **DESABILITADO** — precisa `resume` |
|| `bb03201b8911` | manaloom-code-structure-auditor (4h) | every 180m | sim | 2026-05-28T11:32Z | ~44h | 🔴 error | scheduled | ~44h sem rodar |
|| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 120m | sim | 2026-05-30T00:22Z | 7h17m | 🔴 error | scheduled | 🆕 desde snapshot anterior |

## Crons de Conhecimento Commander

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
|| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | sim | 2026-05-30T07:06Z | 33min | 🔴 error | scheduled |
|| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | sim | 2026-05-28T11:49Z | ~44h | 🔴 error | scheduled |
|| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | sim | 2026-05-28T11:37Z | ~44h | 🔴 error | scheduled |
|| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | sim | 2026-05-28T11:07Z | ~44h | 🔴 error | scheduled |
|| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | sim | 2026-05-28T11:28Z | ~44h | 🔴 error | scheduled |
|| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | sim | **nunca** | — | — | scheduled | 🆕 **NEVER-RUN** — precisa `run` |

## Lorehold Knowledge Pipeline

|| Job ID | Nome | Schedule | Enabled | Last run | Idade | Last status | State | Observação ||
|---|---|---|---|---|---|---|---|---|---|
|| `f20ac299992b` | lorehold-deck-scout | every 240m | sim | 2026-05-28T11:28Z | ~44h | 🔴 error | scheduled |
|| `712579b15767` | lorehold-deck-validator | every 480m | sim | 2026-05-28T11:19Z | ~44h | 🔴 error | scheduled |
|| `08468451a06a` | lorehold-mulligan-analyst | every 1440m | sim | 2026-05-28T11:26Z | ~44h | 🔴 error | scheduled |
|| `a50bef4c2a59` | lorehold-evolution-oracle | every 1440m | sim | 2026-05-28T07:23Z | ~48h | 🔴 error | scheduled |

## Ações Necessárias (bloqueadas por permissão)

> ⚠️ **As seguintes ações NÃO puderam ser executadas** porque o banco de crons ficou inacessível. Devem ser aplicadas assim que `/opt/data/cron/jobs.json` for corrigido.

### Crons Desabilitados (precisam `resume`)

|| Job ID | Nome | Motivo |
|:-------|:------|:------|
| `757eefb8738b` | manaloom-master-watchdog | `enabled=false`, último status ok |
| `660397bb97e1` | manaloom-hermes-normal-audit | `enabled=false`, último status ok |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | `enabled=false`, último status error |

### Cron Nunca Executado (precisa `run`)

|| Job ID | Nome | Motivo |
|:-------|:------|:------|
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | `last_run_at=null`, never-run |

## Alertas Pendentes

**🚨 P0 — Banco de crons inacessível:** `/opt/data/cron/jobs.json` com permissão 0600 owned por root. Operador deve corrigir manualmente.

**🔴 P1 — 3 crons desabilitados há ~44h+:** master-watchdog, hermes-normal-audit, code-structure-auditor (weekly).

**🔴 P1 — 13 crons com erro:** Todos os crons de conhecimento e import estão falhando há ~44h. Pipeline de conhecimento parado.

**🟡 P1 — Cron nunca executado:** knowledge-synthesis (10a59b3bdf4d) nunca rodou desde criação.

## Mudanças desde Snapshot Anterior

### Crons que Regrediram (🟢 → 🔴 ou 🟢 → desabilitado)

| Cron | Snapshot anterior (06:57Z) | Agora (07:39Z) |
|:-----|:---------------------------|:----------------|
| manaloom-master-watchdog | 🟢 ok | **DESABILITADO** |
| manaloom-hermes-normal-audit | 🟢 ok | **DESABILITADO** |
| manaloom-commander-knowledge-deep | 🟢 ok | 🔴 error |
| manaloom-gamechanger-research | 🟢 ok | 🔴 error |
| manaloom-manager-watchdog | 🟢 ok | 🔴 error |
| manaloom-tag-accuracy-reporter | 🟢 ok | 🔴 error |
| manaloom-mana-base-validator | 🟢 ok | 🔴 error |
| manaloom-knowledge-import | 🟢 ok | 🔴 error |
| code-structure-auditor (weekly) | 🔴 error | **DESABILITADO** |

### Novos Crons

| Cron | Status |
|:-----|:-------|
| manaloom-logic-coherence-auditor (de6fb777f5d1) | 🔴 error |
| manaloom-knowledge-synthesis (10a59b3bdf4d) | never-run |

## Observações Importantes

- **Branch era `codex/hermes-fixes-f0-f3`** no início da execução. Trocado para `codex/hermes-analysis-docs` com `git checkout --force`. Vários arquivos em `docs/hermes-analysis/` mostraram "Permission denial" na troca — possivelmente root-owned naquele momento por outra execução de cron.
- **`/opt/data/cron/jobs.json`** ficou inacessível (root 0600) durante parte da execução, bloqueando `resume`/`run`. Snapshot inicial de 17 crons foi obtido com sucesso.
- Os **3 crons desabilitados** provavelmente foram pausados por um branch switch (padrão documentado).
- A degradação de 5→13 erros em ~48h sugere que o manager-watchdog anterior também não conseguiu recuperar os crons (possivelmente mesmo bloqueio de permissão).

---

*Snapshot: 2026-05-30T07:39Z | Branch: codex/hermes-analysis-docs | Fleet: 17 crons*
