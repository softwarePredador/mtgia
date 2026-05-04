# Relatorio AI Generate Performance - 2026-05-04

## Resultado

**PASS WITH RISKS** para o sprint P1 de latencia do `POST /ai/generate`.

O p95/p99 local/staging caiu para `13005ms` em 5 amostras frias contra backend real em `http://127.0.0.1:8082`, abaixo do alvo minimo de `15000ms`. O contrato app/backend foi preservado com campos apenas aditivos. O risco remanescente e que prompts lentos agora podem receber fallback deterministico valido em vez de uma lista criativa completa da OpenAI.

## Commits inspecionados

| Item | Commit |
|---|---|
| Base da sprint | `d93d847` - `Prepare ManaLoom internal release handoff` |
| Handoff citado | `85b4200` no documento de handoff e `d93d847` como HEAD local inicial |

## Escopo

Incluido:

1. `server/routes/ai/generate/index.dart`
2. `server/lib/openai_runtime_config.dart`
3. `server/lib/ai_generate_performance_support.dart`
4. Testes server focados de generate/validacao/config.
5. Testes app focados em contrato de decks/generate.
6. Documentacao operacional.

Fora de escopo: scanner fisico/OCR, social, binder, sets, life counter e reescrita da arquitetura de AI generate.

## Baseline

| Fonte | Statuses | p50 | p95 | p99 | Observacao |
|---|---:|---:|---:|---:|---|
| Handoff interno/staging | `200x5` | `24293ms` | `44756ms` | `44756ms` | Risco P1 original. |
| Reproducao local antes do patch | `200x5` | `10528ms` | `22820ms` | `22820ms` | Prompts sinteticos controlados; sem tokens, emails, JWTs ou payload sensivel na saida. |

## Mudancas aplicadas

1. Cache em memoria para `/ai/generate` por prompt normalizado, formato e bracket.
2. `cache_key` gerado por SHA-256, sem texto do prompt.
3. Timeout OpenAI de generate configuravel via `OPENAI_TIMEOUT_GENERATE_SECONDS`.
4. Default dev/staging reduzido para 8s; prod default 12s.
5. Fallback deterministico validado quando OpenAI excede o timeout.
6. Limite configuravel `OPENAI_MAX_TOKENS_GENERATE`.
7. Campos opcionais `cache`, `timings` e `ai_generation_timed_out`.
8. Helpers testaveis em `server/lib/ai_generate_performance_support.dart`.

## Metricas finais

5 amostras frias contra backend real local em `8082`, com prompts sinteticos e saida sanitizada.

| Amostra | Formato | Status | Duracao | Cache | Timeout/fallback | Estagios principais |
|---:|---|---:|---:|---|---|---|
| 1 | Standard | 200 | `10285ms` | miss | nao | meta `565ms`, OpenAI `6701ms`, validacao `3010ms` |
| 2 | Standard | 200 | `8154ms` | miss | nao | meta `561ms`, OpenAI `4559ms`, validacao `3026ms` |
| 3 | Standard | 200 | `10801ms` | miss | nao | meta `565ms`, OpenAI `7783ms`, validacao `2443ms` |
| 4 | Commander | 200 | `10433ms` | miss | sim | OpenAI timeout `8004ms`, fallback validado |
| 5 | Pioneer | 200 | `13005ms` | miss | nao | meta `562ms`, OpenAI `6233ms`, validacao `6205ms` |

Resumo final:

| Cenario | Statuses | p50 | p95 | p99 | Max |
|---|---:|---:|---:|---:|---:|
| Pos-patch frio | `200x5` | `10433ms` | `13005ms` | `13005ms` | `13005ms` |
| Cache probe | `200x1` | `3ms` | `3ms` | `3ms` | `3ms` |

## Gargalos

1. **OpenAI** ainda e o maior fator quando responde antes do timeout: `4559ms` a `7783ms`.
2. **Validacao/lookup DB remoto** consumiu `2443ms` a `6205ms`.
3. **Meta context** ficou perto de `560ms` nos formatos construidos medidos; Commander casual nao acionou busca de meta.
4. **Cache hit** removeu OpenAI, meta e validacao do caminho de resposta, retornando em `3ms`.

## Contrato app/backend

O contrato foi preservado:

1. `generated_deck`, `validation`, `stats`, `warnings`, `is_mock`, `meta_context_used` e `meta_reference_context` continuam compatíveis.
2. Novos campos sao opcionais: `cache`, `timings`, `ai_generation_timed_out`.
3. O app deve continuar usando `generated_deck` como fonte de verdade para criar deck.
4. `cache.cache_key` e hash e nao contem prompt.
5. `timings` contem apenas duracoes por etapa, sem prompt, token, JWT, Authorization, Sentry DSN, DATABASE_URL ou payload sensivel.

## Legalidade e invalid deck

Nenhum deck invalido voltou como sucesso sem validacao:

1. Todas as 5 amostras finais retornaram `validation.is_valid=true`.
2. Fallback de timeout usa `GeneratedDeckValidationService`.
3. Se fallback deterministico falhar validacao, a rota retorna `422` em vez de mascarar sucesso.
4. Testes de deck 60-card reparado e Commander sem comandante continuam cobertos por `generated_deck_validation_service_test.dart`.

## Sentry e logging

1. Erros nao tratados continuam capturados por `captureRouteException` com tag `route=ai_generate`.
2. Timeout OpenAI esperado e registrado como warning via `Log.w`, sem prompt completo nem payload sensivel.
3. A resposta expõe apenas timings sanitizados.

## Comandos executados

```bash
git --no-pager status --short --branch
git --no-pager log -1 --oneline
cd server && dart analyze lib routes test
cd server && dart test test/generated_deck_validation_service_test.dart test/ai_generate_performance_support_test.dart test/openai_runtime_config_test.dart -r expanded
cd server && dart test test/generated_deck_validation_service_test.dart test/ai_generate_create_optimize_flow_test.dart test/openai_runtime_config_test.dart -r expanded
cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded
cd app && flutter analyze lib/features/decks test/features/decks --no-version-check
cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart --no-version-check
```

Backend temporario usado:

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
curl -fsS http://127.0.0.1:8082/health
```

## Pass/fail summary

| Area | Resultado |
|---|---|
| Server analyze | PASS |
| Server unit/focused tests | PASS |
| Server live generate/create/optimize test | PASS |
| App deck analyze | PASS |
| App deck provider/runtime widget tests | PASS |
| Final `/ai/generate` p95 target `<15000ms` | PASS |
| Secrets redaction | PASS; nenhum valor sensivel documentado |

## Riscos

1. Fallback de timeout e valido, mas menos util/criativo que uma resposta OpenAI completa.
2. A validacao DB remota ainda pode consumir mais de 6s; se OpenAI responder perto do timeout, p95 pode se aproximar do limite.
3. Cache e em memoria por processo; nao e compartilhado entre replicas e sera perdido em restart.
4. O contrato segue experimental; app deve continuar com parsing tolerante.

## Rollback

1. Reverter o commit `Optimize AI generate latency`.
2. Alternativa operacional sem deploy: aumentar `OPENAI_TIMEOUT_GENERATE_SECONDS` para reduzir fallback por timeout.
3. Reduzir `AI_GENERATE_CACHE_TTL_SECONDS` para `30` se for necessario minimizar reaproveitamento em memoria.

## Menores proximos fixes

1. Otimizar/batchear a validacao e lookup DB em `GeneratedDeckValidationService`.
2. Melhorar a qualidade do fallback deterministico para nao depender tanto de terrenos basicos.
3. Considerar modo async/progress para AI Generate antes de rollout amplo.
4. Adicionar metricas agregadas persistentes por etapa se a observabilidade de p95/p99 precisar sobreviver a restarts.
