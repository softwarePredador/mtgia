# Tracker executável do ManaLoom Battle Lab e Coach

**Plano:** `docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md`

**Estado do programa:** `PLANNED_POST_S10`

**Condição de início:** `S10-11=GO`, capacidade segura do host e owner
declarado. Uma ampliação explícita da release atual pode substituir a primeira
condição, mas exige recongelar escopo/SHA e repetir os gates afetados.

Este arquivo registra o estado operacional dos marcos. O plano define todos os
passos e critérios de aceite. Nenhuma linha recebe crédito herdado da Sprint 5:
S5 prova o runtime/replay v2 existente, não Battle Lab, streaming ou
human-in-loop.

## Protocolo

1. Antes de iniciar, preencher owner, arquivos pretendidos e evidência-base.
2. Uma sprint só muda para `IN_PROGRESS` quando todas as dependências estão
   `PASS` e não há conflito de arquivos.
3. Cada task `BLn-mm` do plano precisa aparecer na evidência da sprint com
   resultado individual.
4. `PASS` exige mesma SHA, comandos, exit codes, ambiente, dados criados,
   cleanup, skips e riscos residuais.
5. Mudança de API, schema, sidecar ou UI atualiza, quando realmente
   implementada, API/data map, UI surface map, contratos e project logic.
6. Gates live, PostgreSQL mutante e deploy exigem as autorizações do contrato
   E2E; este tracker não as concede.
7. BL8 permanece `BLOCKED` até BL7 emitir GO explícito.
8. A partida humana completa permanece `DEFERRED_BY_SCOPE` até BL10.

## Estado executivo

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| BL-BOOT | `BLOCKED` | S10-11 GO | — | capacidade do host; plano/tracker somente até o início | `df -h`, inventário, project logic | volume local com ~3,3 GiB livres em 2026-07-24; sem autorização para limpeza cega |
| BL0 | `TODO` | BL-BOOT | — | migration/schema Battle; persistência/leitura/sanitização; ADR; contratos/testes | migration descartável, Battle, engine-capabilities | — |
| BL1 | `TODO` | BL0 | — | Análise do deck; setup/preflight; modelos/serviços Battle; rotas/testes | app/server focados, ui-audit, Battle | — |
| BL2 | `TODO` | BL0 | — | parsers XMage/Forge/native; mesa/timeline; fixtures/goldens | Flutter focado, performance, ui-audit, Battle | — |
| BL3 | `TODO` | BL1, BL2 | — | relatório; anotações; comparação; export/delete; testes | PostgreSQL isolado, app/server focados, Battle | — |
| BL4 | `TODO` | BL3 | — | hardening e evidência Battle Lab | battle-lab, full, ui-audit, performance, report-retention, E2E | — |
| BL5 | `TODO` | BL4 | — | jobs, worker, lifecycle, quotas, observabilidade | fault injection, Battle, full | — |
| BL6 | `TODO` | BL5 | — | stream incremental e Live Spectator Web/Android | carga, reconexão, auth/IDOR, runtime Web/Android | — |
| BL7 | `TODO` | BL6 | — | spike XMage humano isolado; ADR/capability experimental | Maven, callbacks, segurança, relatório GO/NO-GO | — |
| BL8 | `BLOCKED` | BL7 GO | — | sessão/prompt/ação, visão privada, pool XMage | PostgreSQL isolado, API/security, sidecar | — |
| BL9 | `TODO` | BL8 | — | prompts Coach e UX Web/Android | decisão por tipo, ui-audit, runtime | — |
| BL10 | `TODO` | BL9 | — | hardening/rollout alpha | full, Battle, carga, E2E, same-SHA smoke | — |
| HUMAN-1V1 | `DEFERRED_BY_SCOPE` | BL10 GO | — | novo programa posterior | novo contrato e plano próprios | — |
| HUMAN-MULTI | `DEFERRED_BY_SCOPE` | HUMAN-1V1 PASS | — | novo programa posterior | novo contrato e plano próprios | — |

## Evidências previstas

Cada sprint cria somente depois da execução:

```text
docs/qa/MANALOOM_BATTLE_LAB_BL0_EVIDENCE_<data>.md
...
docs/qa/MANALOOM_BATTLE_LAB_BL10_EVIDENCE_<data>.md
```

Payloads extensos, traces e resultados por partida permanecem em `/tmp` ou
storage operacional governado. O documento versionado contém apenas resumo
sanitizado e referências reproduzíveis.
