# Relatorio Commander Optimize Flow Audit - 2026-05-04

## Resultado

**PASS.** A instabilidade live do fluxo `/ai/generate -> POST /decks -> /decks/:id/validate -> /ai/optimize` foi reproduzida e corrigida. A causa confirmada foi geracao Standard recuperavel abaixo do minimo de 60 cartas validas; o backend agora repara decks construidos antes de responder e so retorna 422 quando nao ha fallback seguro.

## Commits inspecionados

| Ref | Observacao |
|---|---|
| `fb85c33` | `HEAD` inicial em `master` / `origin/master` antes da correcao local. |

## Comandos executados

| Comando | Resultado |
|---|---|
| `cd server && dart analyze lib/ai routes/ai bin test` | PASS |
| `cd server && PORT=8082 dart run .dart_frog/server.dart` | PASS; `/health` healthy em `http://127.0.0.1:8082`. |
| `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded` | FAIL antes da correcao: tres prompts retornaram 422 `Generated deck failed validation`. |
| Probe sanitizado de `/ai/generate` em 8082 | Confirmou mono red com 58 cartas validas e erro `deck standard precisa de pelo menos 60 cartas`. |
| `cd server && dart test test/generated_deck_validation_service_test.dart -r expanded` | PASS |
| `cd server && dart analyze lib routes test` | PASS |
| `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded` | PASS apos correcao, `01:33 +2`. |
| `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded` | PASS, `02:51 +167 ~3`. |
| `cd server && dart test test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart test/external_commander_meta_promotion_support_test.dart -r expanded` | PASS, `02:43 +56 ~1`. |
| `cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run` | FAIL esperado por default 8080 inacessivel neste trabalho. |
| `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/run_commander_only_optimization_validation.dart --dry-run` | PASS; 19 candidatos seriam validados, sem auth/deck/optimize/bulk/validate. |
| `cd app && flutter analyze lib/features/decks test/features/decks --no-version-check` | PASS |
| `cd app && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check` | PASS, `00:05 +35`. |

## Pass/fail summary

| Area | Status | Evidencia |
|---|---|---|
| Reproducao da falha | PASS | Teste live focado falhou antes da correcao com 422 nos tres prompts candidatos. |
| Correcao backend generate/create/validate | PASS | Teste live focado passou apos correcao. |
| Suite live ampla | PASS | `dart test -P live` passou; Social Trading tambem executou dentro do profile sem falha. |
| Contrato app decks | PASS | Analyze e testes Flutter de decks passaram. |
| Social Trading/Scanner/Sets/Binder/Life Counter | PASS por nao alteracao | Nenhum arquivo desses modulos foi modificado. |

## Timing summary

| Fluxo | Tempo observado | Concentracao |
|---|---:|---|
| Live focado generate/create/validate/optimize | `01:33` total | Chamadas OpenAI/AI generate e optimize job/polling. |
| Live amplo `-P live` | `02:51` total | Optimize complete async e testes live com DB. |
| Server optimize audit tests | `02:43` total | Optimize complete async; exemplo de job com `total_ms` ~9.2s. |
| Optimize complete job observado | `total_ms` ~9.2s | `complete.fill_remainder` ~2.9s, `complete.ai_suggestion_loop` ~1.8s, `complete.build_final_response` ~1.1s, `complete.prepare_commander_seed` ~0.6s. |

## Optimize/generate path matrix

| Entrada | Caminho antes | Caminho apos correcao | Resultado apos correcao |
|---|---|---|---|
| mono red aggro / Standard | AI primary -> validation strict -> 422 por 58 cartas validas | AI primary -> resolve legal printing -> constructed repair -> response 200 | 60 cartas, `validation.is_valid=true`, sem fallback, warnings de reparo/remocao. |
| mono black midrange / Standard | AI primary podia retornar 422 por invalidas/tamanho em execucoes variaveis | AI primary -> constructed repair se necessario -> response 200 | >=60 cartas, `validation.is_valid=true`, sem fallback. |
| azorius control / Standard | AI primary podia retornar 422 por invalidas/tamanho em execucoes variaveis | AI primary -> constructed repair se necessario -> response 200 | >=60 cartas, `validation.is_valid=true`, sem fallback. |
| Commander optimize complete | Async job 202 quando deck incompleto | Sem alteracao arquitetural | Polling e `timings/stages_ms` coerentes nos testes. |
| AI invalid irreparavel | 422 | 422 preservado, exceto fallback deterministico valido quando seguro | Erro real nao e mascarado por skip. |

## App/backend contract findings

- `POST /ai/generate` continua respondendo `generated_deck` como fonte de verdade para o app criar payload por nome.
- Campos opcionais novos documentados: `ai_generation_repaired_by_fallback` e `original_validation_errors`.
- `warnings.messages` pode indicar reparo automatico quando cartas invalidas foram removidas ou terrenos basicos foram adicionados.
- `POST /decks` agora resolve nomes preferindo impressao legal/restrita no formato solicitado, reduzindo divergencia entre a impressao validada por `/ai/generate` e a impressao persistida por create.
- Testes app confirmaram que preview/apply/validate seguem consumindo exatamente o contrato backend esperado para otimização de decks.

## Legalidade e identidade de cor

- Para formatos construidos, o reparo limita nao-basicas a 4 copias, remove/ajusta carta ofensora em falha recuperavel e completa ate 60 cartas com terrenos basicos guiados por demanda de cor.
- Commander/Brawl mantem reparo existente de comandante, tamanho exato, singleton e identidade de cor; nao houve relaxamento de legalidade Commander.
- Validate strict continua sendo a decisao final antes de `/ai/generate` retornar 200.

## Sentry/logging findings

- Erros inesperados de `/ai/generate` continuam passando por `captureRouteException` com tag `route=ai_generate`.
- Geracao invalida recuperavel agora e logada com `Log.w` e contexto de formato/erros, sem incluir secrets, tokens, DSN, DATABASE_URL ou payload sensivel.
- `POST /decks` mantem captura de excecoes com tag `route=decks_create` e extras limitados a formato/contagem de cartas.

## Blockers

- Nenhum blocker restante para o fluxo solicitado.
- O primeiro dry-run Commander-only falhou por default `8080`, mas passou ao apontar explicitamente para `TEST_API_BASE_URL=http://127.0.0.1:8082`.

## Menores proximos fixes

1. Adicionar no futuro um campo estruturado `repair_actions[]` em `/ai/generate` para o app exibir reparos sem parsear mensagens textuais.
2. Reduzir verbosidade dos logs de testes app que imprimem listas grandes de cartas durante apply.
3. Se o produto quiser qualidade maior nos decks Standard gerados, substituir o fallback basico minimo por um pool deterministico de cartas legais por arquétipo; esta auditoria limitou-se a estabilidade/validade do fluxo.
