# Tracker executável do ManaLoom Battle Lab e Coach

**Plano:** `docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md`

**Estado do programa:** `M3_ALPHA_DEPLOYED / BL10_SOFTWARE_PASS / HARDWARE_GO_PENDING`

**Rodada de execução:** 2026-07-26–2026-08-02, na branch
`codex/free-beta-release-candidate-2026-07-17`.

O usuário ampliou explicitamente o escopo para executar BL0–BL10 e, em
2026-08-02, concedeu autorização explícita para backup, migrations, escrita de
QA, deploy e smoke mutante no ambiente live. O ADR 0004 continua delimitando o
produto: Battle Coach é uma sessão humana assistida e privada; não transforma
o replay externo nem a simulação automática em jogo humano completo.

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
7. BL8 foi desbloqueado pelo GO explícito do ADR 0004; o rollout alpha foi
   habilitado somente após backup, migration 056, gates e E2E live.
8. A partida humana completa permanece `DEFERRED_BY_SCOPE` até BL10.

## Estado executivo

| ID | Estado | Depende de | Owner | Arquivos pretendidos | Gate mínimo | Evidência |
|---|---|---|---|---|---|---|
| BL-BOOT | `PASS_CAPACITY_RECOVERED` | ampliação explícita | Codex | limpeza somente de caches/artefatos descartáveis identificados e batching determinístico | `df -h`, inventário, duas execuções `full` | Evidência BL0 anterior; em 2026-07-27 foram removidos primeiro 10 GiB e, após os gates recriarem caches, mais 6,6 GiB de Xcode DerivedData reconstruível; 33 GiB ficaram livres |
| BL0 | `PASS_LOCAL` | BL-BOOT | Codex | migration/schema Battle; persistência/leitura/sanitização; ADR; contratos/testes | migration descartável, Battle, engine-capabilities | `docs/qa/MANALOOM_BATTLE_LAB_BL0_EVIDENCE_2026-07-26.md`; BL0-00..09 verdes localmente |
| BL1 | `PASS_LOCAL` | BL0 | Codex | Análise do deck; setup/preflight; modelos/serviços Battle; rotas/testes | app/server focados, ui-audit, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL1_EVIDENCE_2026-07-26.md` |
| BL2 | `PASS_LOCAL` | BL0 | Codex | parsers XMage/Forge/native; mesa/timeline; fixtures/testes | Flutter focado, performance, ui-audit, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL2_EVIDENCE_2026-07-26.md` |
| BL3 | `PASS_LOCAL_WITH_RUNTIME_RESIDUALS` | BL1, BL2 | Codex | relatório; anotações; comparação; Keep/Mulligan; séries 3/5/10; export/delete; testes | PostgreSQL isolado, app/server focados, Battle | `docs/qa/MANALOOM_BATTLE_LAB_BL3_EVIDENCE_2026-07-26.md`; UI/coordenação local concluídas, retomada server-side e decisão realmente cega dependem do runtime |
| BL4 | `PASS_RUNTIME_EMULATOR_HARDWARE_PENDING` | BL3 | Codex | hardening e evidência Battle Lab | battle-lab, full, ui-audit, performance, report-retention, E2E | evidência anterior mais `docs/qa/MANALOOM_BATTLE_FLOW_RELEASE_EVIDENCE_2026-08-02.md`; runtime Web/Android emulator e live passaram; Android físico/TalkBack seguem como gate humano separado |
| BL5 | `PASS_DEPLOYED` | BL4 local | Codex | jobs, worker, lifecycle, quotas, observabilidade | fault injection, Battle, full | worker e jobs assíncronos implantados; simulação automática concluiu e persistiu replay live |
| BL6 | `PASS_DEPLOYED_EMULATOR_HARDWARE_PENDING` | BL5 | Codex | stream incremental e Live Spectator Web/Android | carga, reconexão, auth/IDOR, runtime Web/Android | polling/reconexão e replay live implantados; Web real e Android emulator validados; hardware/TalkBack continuam separados |
| BL7 | `PASS_DECISION_GO` | BL6 local | Codex | spike XMage humano isolado; ADR/capability experimental | Maven, callbacks, runtime, timeout, privacidade | `docs/qa/MANALOOM_BATTLE_LAB_BL7_EVIDENCE_2026-07-26.md`; 3/3 partidas, 251/251 respostas, zero deadlock/leak e timeout com concede/GAME_OVER; ADR 0004 |
| BL8 | `PASS_DEPLOYED` | BL7 GO | Codex | sessão/prompt/ação, visão privada, PostgreSQL append-only, runtime separado | PostgreSQL isolado, API/security, sidecar real | migration 056 aplicada; sessão live manteve mão, passou prioridade, avançou turno, concedeu e persistiu replay |
| BL9 | `PASS_DEPLOYED_SCOPE_REFINED` | BL8 | Codex | prompts Coach, mesa privada, deep links e UX Web/Android | decisão por tipo, ui-audit, runtime, build Web | Coach live e replay de decisões validados; somente delegação explícita por prompt permanece no alpha |
| BL10 | `PASS_SOFTWARE_DEPLOYED_HARDWARE_PENDING` | BL9 | Codex | hardening/rollout alpha | full, Battle, carga, E2E, same-SHA smoke | `docs/qa/MANALOOM_BATTLE_FLOW_RELEASE_EVIDENCE_2026-08-02.md`; backup, migration, flags, deploy, conta/deck do zero, otimização, sessão interativa, simulação automática e replay passaram; Android físico/TalkBack permanecem checks humanos não reivindicados |
| HUMAN-1V1 | `DEFERRED_BY_SCOPE` | BL10 GO | — | novo programa posterior | novo contrato e plano próprios | — |
| HUMAN-MULTI | `DEFERRED_BY_SCOPE` | HUMAN-1V1 PASS | — | novo programa posterior | novo contrato e plano próprios | — |

## Evidências da rodada

BL0–BL10 possuem evidência local e operacional. Em 2026-08-02 o backend, o Web
release, os sidecars e o serviço de operações foram publicados com Battle Live
e Battle Coach explicitamente habilitados; a migration 056 foi confirmada no
PostgreSQL live depois de backup restaurável. Uma conta criada do zero percorreu
cadastro, importação Commander, validação, reconstrução guiada para bracket 2,
preflight, sessão interativa, simulação automática e os dois tipos de replay.

O GO registrado aqui é de software alpha. O Samsung físico não estava conectado
na captura final, portanto smoke de hardware e TalkBack humano continuam
pendentes e não recebem crédito implícito. A ausência desses dois checks não
reverte a prova Web/emulador nem autoriza chamá-los de concluídos.

Payloads extensos, traces e resultados por partida permanecem em `/tmp` ou
storage operacional governado. O documento versionado contém apenas resumo
sanitizado e referências reproduzíveis.
