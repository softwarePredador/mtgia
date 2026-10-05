# Receipt — D-82: `POST /ai/optimize` sem provedor de IA entrega as trocas determinísticas — 2026-09-28

- Decisão do dono de 2026-09-28 (D-82), trazida pela coordenação como tarefa prioritária da
  Frente A (servidor), branch `servidor/rodada2-2026-09-24`.
  - A sessão do gate depende dela para capturar o pacote `optimization-card-reader-web`
    antes do congelamento.
- Aceite pedido:
  - sem chave e com shortlist não vazia em modo `optimize`, a resposta sai de
    `buildDeterministicOptimizeResponse`;
  - nenhuma tentativa de provedor sem chave: nem a primária, nem o fallback, nem o Critic IA;
  - sem chave e com shortlist vazia, continua o mock;
  - com chave, nada muda;
  - `learning_eligible` e a telemetria de outcome dizem honestamente que a origem foi
    determinística e que não houve provedor.
- Nada tocou a produção. Os testes de banco e o E2E rodaram num PostgreSQL 17 descartável e
  numa API local presa ao loopback.

## O que mudou

`server/routes/ai/optimize/index.dart` (o blob de partida era `cd9e102350`, o mesmo da árvore
da sessão do gate):

1. **O galho do mock.** Antes, `if (deckOptimizer == null)` devolvia `mock_non_actionable`
   antes de olhar a shortlist. Agora o `deterministicFirstEnabled` é calculado antes, e o mock
   só sai quando não há provedor **e** não há shortlist (ou o modo não é `optimize`).
2. **Nenhuma tentativa de provedor sem chave:**
   - `runAiOptimizeAttempt` volta sem chamar nada quando não há `optimizer`;
   - os dois pontos de fallback por IA (`OPTIMIZE_NO_SAFE_SWAPS` e
     `OPTIMIZE_QUALITY_REJECTED`) exigem `optimizer != null`;
   - o Critic IA já pulava chave nula (`OptimizationValidator`, `openAiKey`).
3. **Proveniência.**
   - Toda resposta sem chave leva `ai_provider: {configured: false, attempted: false}`.
   - A resposta determinística diz, no `reasoning`, que nenhum provedor de IA está
     configurado e que não houve revisão por IA.
   - O `strategy_source` continua `deterministic_first`.
4. **Telemetria de outcome.** `recordOptimizeAnalysisOutcome` e
   `buildOptimizationAnalysisLogEntry` (`server/lib/ai/optimize_analysis_support.dart`,
   repassado por `server/lib/ai/optimize_route_internal.dart`) aceitam uma proveniência
   opcional. Sem chave, a rota grava `strategy_source` e `ai_provider` no
   `decisions_reasoning`.
5. **Cache.** A resposta sem provedor não entra no cache compartilhado de optimize. Assim ela
   nunca responde, mais tarde, a um pedido feito com provedor.
6. **EDHREC.** A validação continua igual à do caminho determinístico com chave, com
   `EdhrecService()` quando não há `optimizer`. A coleta tem chave própria
   (`MANALOOM_EDHREC_AUTOMATED_COLLECTION_AUTHORIZED`, desligada por padrão) e não é
   provedor de IA.

Continua como antes:

- com chave, tudo (o teste com chave falsa prova);
- na produção sem chave, o 503 `provider_unavailable`;
- as trocas passam pela validação, pela prévia assinada (`apply_authorization`,
  `swap_integrity`) e pela confirmação do usuário (D-27, D-29).

## Decisões, com a recomendação

- **`learning_eligible` não vira `false`.** Neste código ele está preso à aplicação: o app
  (`deck_optimize_flow_support.dart`, `canApply`) e o HMAC da prévia
  (`optimize_swap_integrity.dart`) recusam prévia com `learning_eligible: false`. Marcar
  `false` voltaria a entregar uma prévia não aplicável, que é justamente o que a D-82 tira.
  - A honestidade fica no `strategy_source: deterministic_first`, no
    `ai_provider: {configured: false, attempted: false}`, no texto do `reasoning` e na
    telemetria.
  - As escritas de aprendizado seguem desligadas pela capability `learning_writes`
    (DCK-P0-05).
  - *Recomendação:* separar "pode aplicar" de "pode aprender" quando o `DCK-P0-05` desenhar
    a máquina de estados do aprendizado.
- **Sem cache para a resposta sem provedor.** *Recomendação:* manter.
- **A produção sem chave continua 503.** Estender a D-82 à produção fica com o dono.
  *Recomendação:* manter; a produção tem provedor configurado.
- **EDHREC igual ao caminho com chave.** *Recomendação:* manter.
- **A telemetria de outcome grava em `optimization_analysis_logs`,** que o baseline canônico
  não cria (`BT-DB-005`). No banco descartável a gravação falha em silêncio, como antes. A
  proveniência é provada pelo teste da entrada e pela resposta.

## Evidência

Tudo contra um PostgreSQL 17 descartável (`LC_ALL=C`, loopback, 62 migrações, última 062) e
a API local, os dois parados ao fim.

- **Banco:** `optimize_without_provider_db_live_test.dart`, no worktree sobre `3812b6d08`, em duas
  rodadas.
  - Sem chave: 2/2.
  - Com chave falsa: 2/2.
  - O `HttpClient` do processo é trocado por um que registra e recusa toda conexão. Sem chave,
    zero conexões; com chave, a tentativa ao provedor aparece.
- **Foco:** 86 arquivos e 706 testes verdes, sem os `*_live_test`.
- **Na trava, às 13:11Z:** `dart analyze` de `lib`, `bin`, `routes` e `test` sem achados. O build da
  API é das 13:11:31Z. Antes do E2E, um `diff` confirmou que `lib`, `routes`, `bin` e `config` do
  build são iguais às fontes.
- **E2E por HTTP, das 14:17Z às 14:21Z.**
  - Ambiente da API: o build da D-82 em `127.0.0.1:58191`, com `ENVIRONMENT=development` e sem
    `OPENAI_API_KEY` no ambiente do processo.
    - O manifesto isolado liga `account_registration`, `decks_private` e
      `ai_analyze_optimize_advisory`.
    - O cadastro é por convite.
  - **Guarda de egress:** a mesma do `EGRESS_GUARD` de
    `scripts/manaloom_server_contract_e2e_isolated.sh`. É `sandbox-exec` com `(deny network*)`,
    liberando só entrada e saída no loopback, e cobre a API e o processo de teste.
    - Antes de subir, o autoteste viu `1.1.1.1:53` recusado (EPERM).
    - `sandbox_check` deu 1 no pid da API e 0 no shell de controle.
  - `optimize_without_provider_e2e_live_test.dart`: 2/2, em duas corridas (14:17Z e 14:19Z).
  - **Sonda HTTP**, fora do repositório, com a mesma semeadura e pela mesma API:
    - **Deck com shortlist:**
      - 200, com `outcome_code: optimized` e `strategy_source: deterministic_first`.
      - Sem `is_mock`, e com `ai_provider: {configured: false, attempted: false}`.
      - 10 adições e 10 remoções de cartas reais do catálogo semeado: entram as
        `D82 Candidata *` e saem as `D82 Azul *`.
      - Vêm `swap_integrity` e `apply_authorization`.
      - O deck continua com 100 cartas, porque a prévia não grava.
      - O `reasoning` diz que nenhum provedor de IA está configurado.
    - **Deck sem shortlist:** 200, com `mock_non_actionable`, `is_mock: true`,
      `can_apply: false` e o mesmo `ai_provider`.
  - **Nenhuma tentativa de provedor:**
    - O log da API tem zero `ClientSocketException`, `SocketException`, `Critic AI`,
      `request.ai_optimize_call` e `Optimization failed`.
    - O log registra "Optimize deterministic-first ativado com 10 swap(s) candidatos". Os
      estágios de timing não passam do `request.deterministic_shortlist` e do
      `request.normalize_payload`.
    - O log unificado do macOS tem zero recusas do sandbox para o pid da API nas duas corridas e na
      sonda.
    - O processo do `dart test` tem uma recusa de consulta DNS ao `mDNSResponder` logo ao iniciar
      (pid 42957). Ela é do launcher do SDK, não da API, e os testes passam.
  - **Controle positivo:** a mesma guarda e a mesma sonda, com a API subida com uma chave falsa.
    - O pid da API aparece nas recusas do sandbox: consulta DNS ao `mDNSResponder`, em 1 relato
      mais 3 duplicados.
    - O log tem `request.ai_optimize_call` (2), `Optimization failed type=_ClientSocketException`,
      `Critic AI unavailable type=_ClientSocketException` e 4 `ClientSocketException`.
    - O deck com shortlist sai `deterministic_first`, com 10 trocas e sem `ai_provider`.
    - O deck sem shortlist sai 422, com `no_safe_upgrade_found`.
    - Ou seja, a prova enxerga uma tentativa quando ela existe.

## Mutações

Cada mutação foi aplicada no worktree. Depois rodaram o teste de banco, nas duas rodadas, ou o
unitário. Por fim, o arquivo foi restaurado e conferido byte a byte. Todas falham como esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M82 | o mock volta a sair sempre que não há provedor (`if (deckOptimizer == null)`) | banco sem chave, 1/2 (com shortlist) |
| M84 | o Critic IA recebe uma chave inventada sem provedor | banco sem chave, 1/2 (a conexão ao provedor aparece) |
| M86 | a resposta sem provedor volta ao cache compartilhado | banco sem chave, 1/2 |
| M87 | a resposta perde o `ai_provider` | banco sem chave, 0/2 |
| M88 | `runAiOptimizeAttempt` nunca chama o provedor, nem com chave | banco com chave, 1/2 (sem shortlist, a IA é tentada) |
| M89 | o galho invertido: mock quando há shortlist | banco sem chave, 0/2 |
| M90 | a proveniência sai da telemetria de outcome | unitário, 16/17 |
| M91 | o `reasoning` honesto é desligado | banco sem chave, 1/2 |

- A M83 foi descartada no clone. Ela mexia na validação EDHREC sem provedor, que ficou igual à do
  caminho com chave. Com a coleta desligada por padrão, os dois lados respondem igual, e a
  mutação sobreviveu às duas rodadas. Não há comportamento da D-82 para ela medir.
- A numeração não tem M85.

## Arquivos (para a sessão do gate aplicar o mesmo diff)

- `server/routes/ai/optimize/index.dart`
- `server/lib/ai/optimize_analysis_support.dart`
- `server/lib/ai/optimize_route_internal.dart`
- `server/test/optimize_without_provider_db_live_test.dart` (novo)
- `server/test/optimize_without_provider_e2e_live_test.dart` (novo)
- `server/test/support/optimize_no_provider_fixture.dart` (novo)
- `server/test/optimize_learning_pipeline_test.dart`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` (linha de `POST /ai/optimize`)
- `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` (linha do `BT-AI-020`)
- este receipt e os gerados do `project_logic`

`scripts/manaloom_server_contract_e2e_isolated.sh` não mudou. Ele exporta `OPENAI_API_KEY=`
e roda testes que já aceitam os dois caminhos (`ai_optimize_flow_test.dart`: mock ou real).
Nenhum teste de rota esperava `mock_non_actionable` para um deck com shortlist.
