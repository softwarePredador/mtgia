# Receipt — a URL da OpenAI mora no `OpenAiRuntimeConfig` (D-83) — 2026-09-28

- **Decisão:** D-83. O dono aceitou em bloco as recomendações do `BT-AI-029`. O item 3 manda
  centralizar a URL no `OpenAiRuntimeConfig` e aceitar `OPENAI_BASE_URL` só fora da produção e só
  em loopback. Na produção a URL fica fixa. O registry e o teste (`url_configurable`) mudam
  juntos.
- **Dono no backlog:** `BT-AI-029`, cujo registry registrou o achado.
- **Frente A (servidor)**, branch `servidor/rodada2-2026-09-24`.
- Nada tocou a produção, nem a fixture isolada: `scripts/manaloom_server_contract_e2e_isolated.sh`
  é raiz do digest de UI e não mudou. Ela exporta `OPENAI_BASE_URL` vazia, e com a variável vazia
  a URL continua a fixa.

## O que havia

- **URL fixa em 8 pontos de 7 arquivos**, contados pelo registry:
  - `commander_ai_live_eval_support.dart`;
  - `optimization_validator.dart`;
  - `otimizacao.dart`, com 2 pontos;
  - as rotas `ai-analysis`, `explain`, `archetypes` e `generate`.
- **Nenhum código lia `OPENAI_BASE_URL`.** A fixture a exportava, mas só o entrypoint do
  laboratório Hermes a usava, para o próprio Hermes.
- **Consequência:** não havia como apontar o servidor para um provedor falso local. A sessão do
  gate precisou da D-82 para capturar sem chave.

## O que mudou

- **`OpenAiRuntimeConfig.chatCompletionsUri`** é o endpoint de toda chamada. A URL
  `https://api.openai.com/v1` aparece só em `server/lib/openai_runtime_config.dart`.
- **A regra da base:**
  - na produção (perfil `prod`: `ENVIRONMENT=production` ou `prod`, ou `OPENAI_PROFILE=prod`),
    a URL é sempre a fixa, mesmo com `OPENAI_BASE_URL` em loopback;
  - fora dela, `OPENAI_BASE_URL` só é aceita quando cumpre tudo isto:
    - o host é loopback: um literal de `127.0.0.0/8`, `::1` ou o nome `localhost`;
    - o esquema é http ou https;
    - não tem usuário, consulta nem fragmento.
  - a barra final sai; o endpoint é `<base>/chat/completions`;
  - qualquer outro valor é ignorado, e a chamada vai para a URL fixa, como antes. Isso inclui
    hosts como `10.0.0.1`, `api.example.com`, `localhost.example.com`, `0.0.0.0` e
    `127.0.0.1.example.com`. Assim a chave nunca é mandada a um host de fora escolhido por
    variável de ambiente;
  - `ignoresBaseUrlOverride` diz, para diagnóstico, quando a variável veio e foi recusada.
- **Os 8 pontos** usam `aiConfig.chatCompletionsUri`. A avaliação ao vivo de comandante
  (`commander_ai_live_eval_support.dart`, fora das rotas) aceita um `endpoint` opcional e, sem
  ele, usa o config do ambiente.
- **Registry:** `url_configurable: true`, com `url_env`, `url_source`, `url_rule` e
  `callsite_marker: chatCompletionsUri`. As ocorrências continuam 8 em 7 arquivos, agora contadas
  pelo marcador.
- **Testes de guarda:**
  - O `ai_route_registry_test.dart` conta os pontos pelo marcador. Ele exige o host só no
    config e o `OPENAI_BASE_URL` lido só no config. Exige também que a URL registrada seja a
    que a produção usa, mesmo com a variável em loopback.
  - O `ai_provider_callsite_contract_test.dart` acha as chamadas pelo endpoint do config e exige
    7 arquivos, cada um com timeout, identificador de segurança e limite de tokens. Um teste novo
    exige a URL num lugar só.
- **`.env.example`** documenta a variável e a regra.

## Evidência

- **Unidade:** `server/test/openai_runtime_config_test.dart` ganhou o grupo da base (4 testes):
  - sem a variável, a URL é a fixa em desenvolvimento, staging e produção;
  - na produção a URL é fixa mesmo com loopback, inclusive com `OPENAI_PROFILE=dev` sobre
    `ENVIRONMENT=production`;
  - fora da produção, 6 formas de loopback são aceitas, com e sem a barra final;
  - 13 formas fora do loopback ou estranhas são ignoradas.
- **Foco:** 14 arquivos e 94 testes (config, pontos de chamada, registry, avaliação ao vivo,
  generate, validador, explain, archetypes, contrato da API, autorização e pipeline do optimize).
- **E2E**, contra a API local buildada com a mudança às 22:11:27Z (`dart analyze` sem achados na
  mesma posse da trava). A API e o processo de teste rodaram sob a guarda de egress
  (`sandbox-exec`, só loopback; o autoteste recusou `1.1.1.1:53`). Capabilities
  `account_registration` e `ai_analyze_optimize_advisory`. A chave era falsa, e o provedor falso
  foi um servidor HTTP do próprio teste em `127.0.0.1:58193`.
  `server/test/openai_base_url_e2e_live_test.dart`, em duas subidas da API:
  - **Loopback aceito:** `OPENAI_BASE_URL=http://127.0.0.1:58193/v1`, 1/1.
    - `POST /ai/explain` respondeu 200 com o texto do provedor falso e `is_mock: false`.
    - O falso recebeu uma chamada em `/v1/chat/completions`, com a chave falsa no
      `Authorization`, o modelo e as mensagens.
    - A API não teve nenhuma recusa de rede no sandbox.
  - **Fora do loopback, ignorado:** `OPENAI_BASE_URL=http://10.255.255.1:9/v1`, 1/1.
    - A rota respondeu 503 `temporariamente indisponível`, e o falso não recebeu nada.
    - No log do sandbox, a única recusa da API foi uma consulta ao resolvedor de DNS
      (`mDNSResponder`). Ou seja, a API tentou resolver o nome da URL fixa, e não conectar
      direto no IP `10.255.255.1`. É a prova de que a base foi ignorada.
    - O log da API registrou a falha de transporte (`_ClientSocketException`).
- **Regressão da D-82:** o teste de banco do optimize sem provedor (`d82_dbtest.sh`, rodada sem
  chave e com chave falsa) passou 3 vezes seguidas; com chave, a tentativa segue indo para a
  URL fixa. Numa quarta rodada, anterior a essas, o caso sem chave falhou uma vez com 422: a
  validação Monte Carlo deu 68/100, contra o mínimo 70. É instabilidade do próprio teste (a
  fixture fica perto do limiar), sem relação com esta mudança; fica registrada no relatório.

## Mutações

Cada mutação foi aplicada no worktree. Rodaram então os testes do config, dos pontos de chamada e
do registry, e por fim o arquivo foi restaurado e conferido byte a byte. As 7 falham como
esperado.

| Mutação | O que muda | Falha em |
| --- | --- | --- |
| M138 | a produção aceita `OPENAI_BASE_URL` | config (produção) e registry |
| M139 | host fora do loopback é aceito | config (fora do loopback) |
| M140 | `localhost.algo` passa por loopback | config (fora do loopback) |
| M141 | a rota de explicação volta a ter a URL fixa | pontos de chamada (2) e registry |
| M142 | usuário, consulta e fragmento passam | config (fora do loopback) |
| M143 | a barra final não sai | config (loopback) |
| M144 | o diagnóstico não diz quando a base foi recusada | config (2) |
