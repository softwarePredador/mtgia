# ADR 0005 — Arquitetura do Battle Coach alpha interativo

- Estado: aceito para implementação local
- Data: 2026-07-27
- Programa: `BL8–BL10`
- Release: `NO_GO`, capacidade default-off

## Contexto

O GO limitado do ADR 0004 provou que um participante humano pode responder a
callbacks allowlisted do XMage sem deadlock ou vazamento e que o timeout pode
terminar a partida por concessão. Ele não transformou o replay nem o Live
Spectator em sessão restaurável e não autorizou rota pública.

O Coach precisa sobreviver a reload curto, rejeitar resposta repetida/obsoleta
e mostrar informação privada ao dono sem contaminar replay, logs ou métricas.
Também precisa impedir que execução batch e humana compartilhem capacidade de
forma silenciosa.

## Decisão

1. O contrato de produto é `interactive_battle_session_v1`, separado de
   `external_battle_request_v2`, `battle_job_v1` e do stream Live.
2. PostgreSQL é a verdade durável. `interactive_battle_sessions` mantém o
   snapshot privado atual e lifecycle; `interactive_battle_records` registra
   eventos append-only. O registro transitório Java existe somente para
   transportar a sessão ativa ao XMage.
3. Toda leitura e mutation é autenticada e owner-scoped. ID malformado,
   inexistente e pertencente a outro usuário converge para o mesmo 404.
4. Cada ação carrega `state_version`, prompt ID, resposta tipada e chave de
   idempotência. Opções usam IDs opacos; texto livre/comando XMage arbitrário
   nunca é aceito.
5. O usuário pode responder opções, inteiro, múltiplos valores ou delegar o
   prompt atual. A validação final de legalidade continua no XMage.
6. Não existe preferência automática de delegação para prompts futuros no
   alpha. Ela contradiz a política aprovada do ADR 0004: se o prazo acabar, a
   sessão concede e termina. Mudar isso exige novo contrato/prova de takeover.
7. A visão privada permite mão própria e zonas públicas. Para o oponente,
   zonas ocultas são somente contagens. Snapshot privado nunca é reutilizado
   como replay público, log ou analytics.
8. O sidecar inicia em exatamente um modo: `XMAGE_RUNTIME_MODE=batch` ou
   `XMAGE_RUNTIME_MODE=interactive`. Cada modo rejeita as rotas do outro. A
   capacidade interativa é limitada e publicada na readiness sem IDs.
9. O app retoma pela URL
   `/decks/:id/battle-coach/:sessionId`; `shared_preferences` não é fonte de
   sessão, prompt, ação ou replay.
10. Backend e app permanecem protegidos, respectivamente, por
    `INTERACTIVE_BATTLE_ENABLED=false` e
    `ENABLE_INTERACTIVE_BATTLE=false`. Os scripts de release fixam esses
    valores em `false`.

## Lifecycle

Estados não terminais são `starting`, `running`, `waiting_for_action` e
`action_pending`. Estados terminais são `completed`, `censored`, `conceded`,
`expired`, `timeout`, `abandoned`, `engine_error`, `process_lost` e
`persistence_error`.

Uma divergência de request hash, processo, sessão runtime, versão, prompt ou
resposta falha fechado. Nenhum erro operacional é convertido em empate,
conclusão ou replay fabricado. Quando o XMage termina normalmente, o serviço
persiste a tentativa/replay Battle sanitizado e referencia o replay na sessão.

## Consequências

- Reload curto e deep link podem reconstruir o estado pelo backend.
- A UI pode ser habilitada isoladamente em ambiente local sem expor a rota na
  release.
- Há custo de manter dois deployments/pools XMage, mas batch não sofre
  contenção silenciosa de partidas humanas.
- Queda irreversível do processo ainda termina como `process_lost`; não se
  promete restaurar um game state completo.
- BL10 continua necessário para carga integrada, Android físico/TalkBack,
  alertas, deploy/migration autorizados e smoke na mesma SHA.

## Evidência

- `docs/qa/MANALOOM_BATTLE_LAB_BL8_EVIDENCE_2026-07-27.md`
- `docs/qa/MANALOOM_BATTLE_LAB_BL9_EVIDENCE_2026-07-27.md`
- `docs/qa/MANALOOM_BATTLE_LAB_BL10_EVIDENCE_2026-07-27.md`
- migration 056 e gate PostgreSQL descartável
- testes Dart de contrato/service/store/rotas/readiness
- testes Maven do registry e runtime interativo
- testes Flutter de modelo, gateway, rota, mesa e viewports
