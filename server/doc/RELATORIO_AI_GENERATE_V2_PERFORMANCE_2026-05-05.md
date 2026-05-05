# Relatorio AI Generate v2 Performance - 2026-05-05

## Plano curto antes das alteracoes

Objetivo: reduzir latencia percebida e aumentar estabilidade do `POST /ai/generate` sem migrar de OpenAI agora, preservando o contrato sincrono atual.

Escopo planejado:

1. Medir baseline sanitizado em backend local `8082` com 10 amostras frias e 10 cache hits quando a infraestrutura local permitir.
2. Manter `OPENAI_MODEL_GENERATE` configuravel e reversivel; nao trocar o default sem evidencia live suficiente para `gpt-5.4-mini`.
3. Adicionar modo async opt-in para generate, com `202`, `job_id`, `poll_url`, progresso e polling ate resultado validado.
4. Reaproveitar o padrao operacional de jobs do optimize, mas em tabela propria de generate porque generate nao recebe `deck_id`.
5. Preservar o endpoint sincrono atual para compatibilidade com app e testes existentes.
6. Otimizar validacao/lookup deduplicando nomes antes de resolver cartas e medindo `validation_ms`.
7. Manter fallback deterministico validado para timeout/credencial dev, retornando `422` se o fallback tambem falhar validacao.
8. Documentar cache persistente/compartilhavel como implementado apenas se houver suporte seguro; caso contrario manter cache in-memory e marcar risco/BLOCKED parcial.
9. Adicionar testes focados para cache key/async key, lifecycle do job, contrato sync preservado, timeout/fallback por suporte testavel e deduplicacao de lookup.
10. Rodar analyze/testes server focados, teste live quando backend `8082` estiver disponivel, e app tests apenas se o consumidor mobile passar a usar async.

## Commits inspecionados

| Item | Commit |
|---|---|
| HEAD inicial | `f30bdd5b437bb5aaa39a1a60a4a01c9179564c79` |

## Status inicial

Branch `master` alinhada com `origin/master` no inicio da sprint. Nenhum segredo sera registrado neste relatorio.

## Baseline

Backend local real em `http://127.0.0.1:8082`, prompts sinteticos, sem tokens/JWT/segredos/payload sensivel no relatorio.

| Cenario | Statuses | p50 | p95 | p99 | Max | Leitura |
|---|---:|---:|---:|---:|---:|---|
| Frio sync antes do patch v2 | `200x10` | `11149ms` | `12271ms` | `12271ms` | `12271ms` | Abaixo de 15s, mas acima do alvo desejado de 10s e ainda bloqueante para UX sem progresso. |
| Cache hit antes do patch v2 | `200x10` | `1ms` | `1ms` | `1ms` | `1ms` | Cache em memoria efetivo, mas nao compartilhado entre replicas/restarts. |
| Cache seed antes do patch v2 | `200x1` | `11285ms` | `11285ms` | `11285ms` | `11285ms` | Seed caiu em timeout/fallback validado. |

Gargalos baseline:

1. `openai_ms` variou de `5500ms` a `8003ms` quando medido nos samples.
2. `validation_ms` variou de `2580ms` a `4435ms`.
3. `meta_context_ms` ficou perto de `594..614ms` em formatos construidos medidos.
4. Uma amostra fria caiu em `openai_timeout_deterministic_fallback`, retornando deck valido.

## Mudancas implementadas

1. **Async opt-in em `/ai/generate`**:
   - request com `async=true`, `profile=async`, `response_mode=background` ou `mode=async` retorna `202`;
   - resposta inclui `job_id`, `poll_url=/ai/generate/jobs/:id`, `poll_interval_ms`, `total_stages`, `cache.cache_key` e `timings.accepted_ms`;
   - contrato sync atual continua default e backward-compatible.
2. **Polling de generate**:
   - nova rota fonte `server/routes/ai/generate/jobs/[id].dart`;
   - `GET /ai/generate/jobs/:id` retorna status `pending|processing|completed|failed`, stage, progresso, `result_status_code`, `result` ou `error`;
   - acesso e isolado por `user_id`, com 404 para job inexistente/de outro usuario.
3. **Job store proprio para generate**:
   - novo `server/lib/ai_generate_job.dart`;
   - tabela `ai_generate_jobs` via migration `014` e schema runtime idempotente;
   - generate nao reutilizou `ai_optimize_jobs` porque nao possui `deck_id`.
4. **Execucao async segura**:
   - job async chama o mesmo contrato sync internamente, removendo flags async antes da execucao;
   - um token interno randômico de processo evita que a self-call consuma o rate limit publico de IA;
   - o token nao e configuravel por env, nao e logado e nao e documentado como segredo operacional.
5. **Validacao/lookup otimizado**:
   - `GeneratedDeckValidationService` deduplica nomes antes de resolver cartas, evitando lookup repetido para cartas repetidas/casing diferente.
6. **Modelo OpenAI configuravel**:
   - `OPENAI_MODEL_GENERATE` ja era suportado por `OpenAiRuntimeConfig`;
   - teste novo prova que staging pode usar `OPENAI_MODEL_GENERATE=gpt-5.4-mini`;
   - default permanece `gpt-4o-mini` porque nao houve evidencia live comparativa suficiente para trocar default de forma segura.
7. **Cache persistente/compartilhavel**:
   - **BLOCKED/PENDENTE** para cache de payload: nao ha infraestrutura segura ja usada por `/ai/generate` equivalente ao `ai_optimize_cache`;
   - mantido cache in-memory `EndpointCache`, sem fingir persistencia;
   - persistencia adicionada apenas para lifecycle de jobs async.

## Evidencias e comandos

Comandos executados:

```bash
git --no-pager status --short --branch
git --no-pager rev-parse HEAD
git --no-pager log -1 --oneline

cd server
PORT=8082 dart run .dart_frog/server.dart
curl -fsS http://127.0.0.1:8082/health

# baseline/post-patch: probes HTTP sanitizados com 10 frios, 10 cache hits e async
python3 <probe_sanitizado_generate_v2>

dart format lib/ai_generate_job.dart lib/internal_ai_request_token.dart lib/ai_generate_performance_support.dart lib/generated_deck_validation_service.dart lib/rate_limit_middleware.dart routes/ai/generate/index.dart routes/ai/generate/jobs/[id].dart bin/migrate.dart bin/verify_schema.dart test/ai_generate_performance_support_test.dart test/generated_deck_validation_service_test.dart test/openai_runtime_config_test.dart
dart analyze .dart_frog/server.dart lib routes test
dart analyze lib routes test
dart test test/ai_generate_performance_support_test.dart test/generated_deck_validation_service_test.dart test/openai_runtime_config_test.dart -r expanded
dart test test/ai_generate_performance_support_test.dart test/generated_deck_validation_service_test.dart test/openai_runtime_config_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart -r expanded
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded
```

Pass/fail:

| Area | Resultado |
|---|---|
| Server analyze `lib routes test` | PASS |
| Server analyze incluindo `.dart_frog/server.dart` local | PASS |
| Generate/config/validation unit tests | PASS: `+18` |
| Generate + optimize/complete focused tests | PASS: `+44` |
| Live generate -> create -> validate/optimize | PASS: `01:41 +2` |
| Async single proof | PASS: `202`, completed, `validation.is_valid=true` |

## Metricas pos-patch

Backend local real em `8082`, prompts sinteticos.

| Cenario | Statuses | p50 | p95 | p99 | Max | Leitura |
|---|---:|---:|---:|---:|---:|---|
| Frio sync pos-patch | `200x10` | `10033ms` | `11212ms` | `11212ms` | `11212ms` | Melhorou vs baseline v2, mas nao atingiu `<10000ms` p95. |
| Cache hit pos-patch | `200x10` | `2ms` | `7ms` | `7ms` | `7ms` | Continua muito rapido; variacao por HTTP local. |
| Async accepted pos-fix | `202x10` | `558ms` | `562ms` | `562ms` | `562ms` | Atende alvo minimo de aceite p95 `<1000ms`. |
| Async completed interno | amostra detalhada | `12089ms` | `12089ms` | `12089ms` | `12089ms` | `result.async.completed_ms`, abaixo de `15000ms`. |
| Async completion observado por polling | `completedx10` | `15604ms` | `15620ms` | `15620ms` | `15620ms` | Inclui intervalo de polling + custo do endpoint de job; nao e tempo interno do executor. |

Primeira tentativa async antes do token interno:

| Cenario | Resultado | Causa |
|---|---|---|
| Async inicial | `202x2`, `429x8`, jobs sem polling conclusivo | A self-call/polling disputava o rate limit publico e a rota nova nao estava disponivel no server Dart Frog local gerado. |

Correcoes aplicadas depois da tentativa inicial:

1. token interno de processo para self-call nao consumir `aiRateLimit`;
2. rota `/ai/generate/jobs/:id` adicionada ao server Dart Frog local para prova runtime;
3. medicao async repetida com schema aquecido: `202x10`, `completedx10`.

## Contrato app/backend

O app atual continua consumindo o caminho sync por `deck_provider_support_generation.dart`; nenhum ajuste app foi necessario porque async e opt-in.

Contrato sync preservado:

1. `POST /ai/generate` sem `async` continua retornando `200` ou `422` com `generated_deck`, `validation`, `stats`, `warnings`, `cache`, `timings` opcionais.
2. `generated_deck` continua fonte de verdade para criar deck.
3. `cache.cache_key` continua hash sem prompt.
4. `timings` contem duracoes por etapa, sem tokens, JWT, Authorization, Sentry DSN, database URL ou prompt completo.

Contrato async novo:

1. `POST /ai/generate` com opt-in retorna `202`.
2. `GET /ai/generate/jobs/:id` retorna progresso e, quando completo, `result` com o mesmo corpo que o sync retornaria.
3. `result_status_code` preserva se o resultado final foi `200` ou `422`.
4. Jobs expiram por cleanup de 30 minutos.

## Legalidade e validade

1. Todos os samples medidos retornaram `validation.is_valid=true`.
2. O teste live criou deck a partir de generate, validou e executou optimize.
3. Fallback deterministico permanece validado; se fallback falhar, o endpoint retorna `422`.
4. Deduplicacao de lookup nao altera output, apenas evita resolver o mesmo nome varias vezes.

## Sentry/logging

1. Erros nao tratados no sync continuam capturados por `captureRouteException` com tag `route=ai_generate`.
2. Crashes no job async sao logados com `Log.e` e marcam o job como `failed`.
3. Timeouts esperados de OpenAI continuam logados como warning sanitizado.
4. Nenhum segredo foi registrado neste relatorio.

## Bloqueadores e riscos

| Item | Status | Leitura |
|---|---|---|
| Cache persistente/compartilhavel de `/ai/generate` | BLOCKED/PENDENTE | Nao ha infraestrutura segura existente para payload de generate; manter in-memory por enquanto. |
| Sync p95 `<10000ms` | NOT MET | Pos-patch ficou `11212ms`; async opt-in atende alternativa de UX. |
| Async observed polling p95 `<15000ms` | WATCH | Observado via polling ficou `15620ms`; tempo interno do executor ficou `12089ms`. Custo vem de intervalo/poll endpoint. |
| Modelo `gpt-5.4-mini` default | NOT CHANGED | Suportado via env para staging/prod, mas default nao foi alterado sem evidencia comparativa. |
| Rota gerada Dart Frog local | WATCH | Fonte da rota foi adicionada; o server gerado local precisou incluir o mount para a prova em `8082`. Ambientes que regeneram Dart Frog pegam a rota pelo filesystem. |

## Menores proximos fixes

1. Criar cache persistente seguro para `/ai/generate`, separado por hash e TTL, sem prompt em claro.
2. Reduzir custo de polling de jobs de IA ou separar middleware de polling para nao pagar checks caros a cada GET.
3. Testar `OPENAI_MODEL_GENERATE=gpt-5.4-mini` em staging com amostras comparaveis antes de alterar default.
4. Otimizar queries de `GeneratedDeckValidationService`/`DeckRulesService` para reduzir `validation_ms`.

## Resultado final

**PASS WITH RISKS.**

O objetivo minimo foi atingido pela via async: `accepted_p95=562ms` e tempo interno de conclusao `12089ms`, com contrato sync preservado e teste live passando. O sync melhorou de p95 `12271ms` para `11212ms`, mas nao atingiu `<10000ms`; cache persistente segue pendente por falta de infraestrutura segura ja existente.
