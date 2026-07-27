# Tracker executável do ManaLoom Battle Lab e Coach

**Plano:** `docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md`

**Estado do programa:** `M3_LOCAL_IMPLEMENTED / BL10_PARTIAL / RELEASE_NO_GO`

**Rodada de execução:** 2026-07-26–27, na branch
`codex/free-beta-release-candidate-2026-07-17`.

O usuário ampliou explicitamente o escopo local para executar BL0–BL10. Isso
autoriza implementação, testes locais, documentação, commit e push; não
autoriza migration, deploy ou smoke mutante em ambiente live. O ADR 0004
emitiu GO técnico de BL7 somente para engenharia local/default-off de BL8; não
é autorização para publicar uma sessão humana.

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
7. BL8 foi desbloqueado pelo GO explícito do ADR 0004, implementado localmente
   e permanece default-off e sem autoridade live.
8. A partida humana completa permanece `DEFERRED_BY_SCOPE` até BL10.

## Estado executivo

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| BL-BOOT | `PASS_CAPACITY_RECOVERED` | ampliação explícita | Codex | limpeza somente de caches/artefatos descartáveis identificados e batching determinístico | `df -h`, inventário, duas execuções `full` | Evidência BL0 anterior; em 2026-07-27 foram removidos primeiro 10 GiB e, após os gates recriarem caches, mais 6,6 GiB de Xcode DerivedData reconstruível; 33 GiB ficaram livres |
| BL0 | `PASS_LOCAL` | BL-BOOT | Codex | migration/schema Battle; persistência/leitura/sanitização; ADR; contratos/testes | migration descartável, Battle, engine-capabilities | `docs/qa/MANALOOM_BATTLE_LAB_BL0_EVIDENCE_2026-07-26.md`; BL0-00..09 verdes localmente |
| BL1 | `PASS_LOCAL` | BL0 | Codex | Análise do deck; setup/preflight; modelos/serviços Battle; rotas/testes | app/server focados, ui-audit, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL1_EVIDENCE_2026-07-26.md` |
| BL2 | `PASS_LOCAL` | BL0 | Codex | parsers XMage/Forge/native; mesa/timeline; fixtures/testes | Flutter focado, performance, ui-audit, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL2_EVIDENCE_2026-07-26.md` |
| BL3 | `PASS_LOCAL_WITH_RUNTIME_RESIDUALS` | BL1, BL2 | Codex | relatório; anotações; comparação; Keep/Mulligan; séries 3/5/10; export/delete; testes | PostgreSQL isolado, app/server focados, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL3_EVIDENCE_2026-07-26.md`; UI/coordenação local concluídas, retomada server-side e decisão realmente cega dependem do runtime |
| BL4 | `PARTIAL_BLOCKED_PHYSICAL_AND_RELEASE` | BL3 | Codex | hardening e evidência Battle Lab | battle-lab, full, ui-audit, performance, report-retention, E2E | `docs/qa/MANALOOM_BATTLE_LAB_BL4_EVIDENCE_2026-07-26.md`; preflight p50/p95 e acessibilidade automatizada verdes, sem Android físico/TalkBack/carga alvo nem autorização live |
| BL5 | `PASS_LOCAL_FEATURE_OFF` | BL4 local | Codex | jobs, worker, lifecycle, quotas, observabilidade | fault injection, Battle, full | `docs/qa/MANALOOM_BATTLE_LAB_BL5_EVIDENCE_2026-07-26.md`; rollout desligado |
| BL6 | `PASS_LOCAL_FEATURE_OFF_WITH_DEVICE_BLOCK` | BL5 | Codex | stream incremental e Live Spectator Web/Android | carga, reconexão, auth/IDOR, runtime Web/Android | `docs/qa/MANALOOM_BATTLE_LAB_BL6_EVIDENCE_2026-07-26.md`; fanout sintético 64 streams/Web local passam, Android físico/sockets reais/live pendentes |
| BL7 | `PASS_DECISION_GO` | BL6 local | Codex | spike XMage humano isolado; ADR/capability experimental | Maven, callbacks, runtime, timeout, privacidade | `docs/qa/MANALOOM_BATTLE_LAB_BL7_EVIDENCE_2026-07-26.md`; 3/3 partidas, 251/251 respostas, zero deadlock/leak e timeout com concede/GAME_OVER; ADR 0004 |
| BL8 | `PASS_LOCAL_FEATURE_OFF` | BL7 GO | Codex | sessão/prompt/ação, visão privada, PostgreSQL append-only, runtime XMage separado | PostgreSQL isolado, API/security, sidecar real | `docs/qa/MANALOOM_BATTLE_LAB_BL8_EVIDENCE_2026-07-27.md`; BL8-01..07 verdes localmente, migration/deploy/rollout não executados |
| BL9 | `PASS_LOCAL_FEATURE_OFF_SCOPE_REFINED` | BL8 | Codex | prompts Coach, mesa privada, deep links e UX Web/Android | decisão por tipo, ui-audit, runtime, build Web | `docs/qa/MANALOOM_BATTLE_LAB_BL9_EVIDENCE_2026-07-27.md`; BL9-01..05/07/08 passam e BL9-06 mantém apenas delegação explícita por prompt |
| BL10 | `PARTIAL_LOCAL_RELEASE_NO_GO` | BL9 | Codex | hardening/rollout alpha | full, Battle, carga, E2E, same-SHA smoke | `docs/qa/MANALOOM_BATTLE_LAB_BL10_EVIDENCE_2026-07-27.md`; `battle-lab`, `full`, UI, engine e E2E determinístico verdes; Android físico/TalkBack/carga alvo/alertas/deploy/smoke pendentes |
| HUMAN-1V1 | `DEFERRED_BY_SCOPE` | BL10 GO | — | novo programa posterior | novo contrato e plano próprios | — |
| HUMAN-MULTI | `DEFERRED_BY_SCOPE` | HUMAN-1V1 PASS | — | novo programa posterior | novo contrato e plano próprios | — |

## Evidências da rodada

BL0–BL9 possuem evidência de implementação/decisão local. BL10 tem evidência
parcial, mas não satisfaz os gates externos e operacionais necessários para
GO. O gate completo passou com 1276 testes Flutter, 9 fluxos Patrol e schema
descartável de 79 tabelas/56 migrations; o E2E determinístico também passou.
As flags permanecem fixadas em `false` nos scripts de release.

Payloads extensos, traces e resultados por partida permanecem em `/tmp` ou
storage operacional governado. O documento versionado contém apenas resumo
sanitizado e referências reproduzíveis.
