# Tracker executável do ManaLoom Battle Lab e Coach

**Plano:** `docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md`

**Estado do programa:** `M2_LOCAL_IMPLEMENTED / BL7_NO_GO / RELEASE_NO_GO`

**Rodada de execução:** 2026-07-26, na branch
`codex/free-beta-release-candidate-2026-07-17`.

O usuário ampliou explicitamente o escopo local para executar BL0–BL10. Isso
autoriza implementação, testes locais, documentação, commit e push; não
autoriza migration, deploy ou smoke mutante em ambiente live. BL8 continua
condicionado a um GO técnico de BL7: a ampliação de escopo não transforma um
NO-GO em autorização para publicar uma sessão humana insegura.

Este arquivo registra o estado operacional dos marcos. O plano define todos os
passos e critérios de aceite. Nenhuma linha recebe crédito herdado da Sprint 5:
S5 prova o runtime/replay v2 existente, não Battle Lab, streaming ou
human-in-loop.

## Protocolo

1. Antes de iniciar, preencher owner, arquivos pretendidos e evidência-base.
2. Uma sprint só muda para `IN_PROGRESS` quando todas as dependências estão
   `PASS` e não há conflito de arquivos. Uma decisão `NO_GO` fecha a sprint de
   spike, mas bloqueia as dependentes.
3. Cada task `BLn-mm` do plano precisa aparecer na evidência da sprint com
   resultado individual.
4. `PASS` exige mesma SHA, comandos, exit codes, ambiente, dados criados,
   cleanup, skips e riscos residuais.
5. Mudança de API, schema, sidecar ou UI atualiza, quando realmente
   implementada, API/data map, UI surface map, contratos e project logic.
6. Gates live, PostgreSQL mutante e deploy exigem as autorizações do contrato
   E2E; este tracker não as concede.
7. BL8 permanece `BLOCKED_BL7_NO_GO` até um novo spike emitir GO explícito.
8. A partida humana completa permanece `DEFERRED_BY_SCOPE` até BL10.

## Estado executivo

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| BL-BOOT | `PASS_CAPACITY_RECOVERED` | ampliação explícita | Codex | limpeza somente de caches/artefatos descartáveis identificados e batching determinístico | `df -h`, inventário, duas execuções `full` | `docs/qa/MANALOOM_BATTLE_LAB_BL0_EVIDENCE_2026-07-26.md`; ~1,8 GiB livres preservados e duas execuções integradas consecutivas verdes |
| BL0 | `PASS_LOCAL` | BL-BOOT | Codex | migration/schema Battle; persistência/leitura/sanitização; ADR; contratos/testes | migration descartável, Battle, engine-capabilities | `docs/qa/MANALOOM_BATTLE_LAB_BL0_EVIDENCE_2026-07-26.md`; BL0-00..09 verdes localmente |
| BL1 | `PASS_LOCAL` | BL0 | Codex | Análise do deck; setup/preflight; modelos/serviços Battle; rotas/testes | app/server focados, ui-audit, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL1_EVIDENCE_2026-07-26.md` |
| BL2 | `PASS_LOCAL` | BL0 | Codex | parsers XMage/Forge/native; mesa/timeline; fixtures/testes | Flutter focado, performance, ui-audit, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL2_EVIDENCE_2026-07-26.md` |
| BL3 | `PASS_LOCAL_WITH_RUNTIME_RESIDUALS` | BL1, BL2 | Codex | relatório; anotações; comparação; Keep/Mulligan; séries 3/5/10; export/delete; testes | PostgreSQL isolado, app/server focados, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL3_EVIDENCE_2026-07-26.md`; UI/coordenação local concluídas, retomada server-side e decisão realmente cega dependem do runtime |
| BL4 | `PARTIAL_BLOCKED_PHYSICAL_AND_RELEASE` | BL3 | Codex | hardening e evidência Battle Lab | battle-lab, full, ui-audit, performance, report-retention, E2E | `docs/qa/MANALOOM_BATTLE_LAB_BL4_EVIDENCE_2026-07-26.md`; preflight p50/p95 e acessibilidade automatizada verdes, sem Android físico/TalkBack/carga alvo nem autorização live |
| BL5 | `PASS_LOCAL_FEATURE_OFF` | BL4 local | Codex | jobs, worker, lifecycle, quotas, observabilidade | fault injection, Battle, full | `docs/qa/MANALOOM_BATTLE_LAB_BL5_EVIDENCE_2026-07-26.md`; rollout desligado |
| BL6 | `PASS_LOCAL_FEATURE_OFF_WITH_DEVICE_BLOCK` | BL5 | Codex | stream incremental e Live Spectator Web/Android | carga, reconexão, auth/IDOR, runtime Web/Android | `docs/qa/MANALOOM_BATTLE_LAB_BL6_EVIDENCE_2026-07-26.md`; fanout sintético 64 streams/Web local passam, Android físico/sockets reais/live pendentes |
| BL7 | `PASS_DECISION_NO_GO` | BL6 local | Codex | spike XMage humano isolado; ADR/capability experimental | Maven, callbacks, segurança, relatório GO/NO-GO | `docs/qa/MANALOOM_BATTLE_LAB_BL7_EVIDENCE_2026-07-26.md`; seis famílias adicionais tipadas, `GAME_PLAY_MANA` e runtime humano completo ainda bloqueiam GO; ADR 0003 |
| BL8 | `BLOCKED_BL7_NO_GO` | BL7 GO | — | sessão/prompt/ação, visão privada, pool XMage | PostgreSQL isolado, API/security, sidecar | `docs/qa/MANALOOM_BATTLE_LAB_BL8_EVIDENCE_2026-07-26.md`; implementação deliberadamente não iniciada |
| BL9 | `NOT_STARTED_DEPENDENCY_BLOCKED` | BL8 | — | prompts Coach e UX Web/Android | decisão por tipo, ui-audit, runtime | `docs/qa/MANALOOM_BATTLE_LAB_BL9_EVIDENCE_2026-07-26.md` |
| BL10 | `NOT_STARTED_DEPENDENCY_BLOCKED` | BL9 | — | hardening/rollout alpha | full, Battle, carga, E2E, same-SHA smoke | `docs/qa/MANALOOM_BATTLE_LAB_BL10_EVIDENCE_2026-07-26.md` |
| HUMAN-1V1 | `DEFERRED_BY_SCOPE` | BL10 GO | — | novo programa posterior | novo contrato e plano próprios | — |
| HUMAN-MULTI | `DEFERRED_BY_SCOPE` | HUMAN-1V1 PASS | — | novo programa posterior | novo contrato e plano próprios | — |

## Evidências da rodada

BL0–BL7 possuem evidência de implementação/decisão local. BL8–BL10 possuem
evidência negativa de dependência: ela prova por que a implementação não pode
ser iniciada, sem converter bloqueio em sucesso.

Payloads extensos, traces e resultados por partida permanecem em `/tmp` ou
storage operacional governado. O documento versionado contém apenas resumo
sanitizado e referências reproduzíveis.
