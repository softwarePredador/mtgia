# Optimize Async Executor Fix - 2026-05-19

## Veredito

`PASS_WITH_RISKS`.

O executor async de `/ai/optimize` foi corrigido, publicado e validado no
backend publico. O erro antigo de resposta interna invalida nao reapareceu.

## Causa

`/ai/generate` ja resolvia a URL interna respeitando `x-forwarded-proto`, mas
`/ai/optimize` montava a chamada interna como `http://<host>/ai/optimize`.

Em producao atras de proxy TLS, isso podia retornar conteudo nao JSON para o
executor interno. O job async entao falhava com:

`Optimize async recebeu resposta invalida do executor interno.`

## Correcao

- Criado resolvedor generico `resolveInternalAiRouteUrl`.
- `resolveAiGenerateInternalUrl` passou a reutilizar esse resolvedor.
- `/ai/optimize` passou a usar o mesmo resolvedor para `/ai/optimize`,
  respeitando `x-forwarded-proto`, `request.uri.scheme`, fallback local e
  `AI_OPTIMIZE_INTERNAL_BASE_URL`.
- Teste unitario adicionado para rota arbitraria com proxy HTTPS.

## Validacao local

- `dart analyze lib/ai_generate_internal_url_support.dart routes/ai/optimize/index.dart test/ai_generate_internal_url_support_test.dart`: PASS.
- `dart test test/ai_generate_internal_url_support_test.dart test/optimize_runtime_support_test.dart -r expanded`: PASS.
- Servidor local `PORT=8082` + `dart test test/ai_optimize_flow_test.dart -r expanded`: PASS, `10` testes + `1` skip conhecido.

## Validacao publica pos-deploy

Backend publico validado em:

- `981a02f6b4f00b688903714d60138b596a244195`.

Resultados sanitizados:

- probe estrutural Talrand completo: jobs async aceitos, sem erro de executor
  interno invalido, mas terminal `failed` por quality gate e sem swaps;
- corpus real versionado Brago: deck temporario Commander com `commander=1`,
  `main=99`, `unresolved=0`, `off_identity=0`, `validation_ok=true`;
- optimize async Brago `focused`: `terminal=completed`, `mode=optimize`,
  `quality_error=false`, `suggestion_count=10`, `elapsed_ms=5130`.

Artifact:

- `server/test/artifacts/semantic_layer_v2_quality_gate_2026-05-19/optimize_async_executor_fix_summary.json`.

## Risco restante

O executor esta corrigido e ja produz swaps em corpus real. Ainda nao promover
Semantic Layer v2 para gate duro de optimize, porque a amostra publica com
swaps nao expos sinal semantico v2 nos diagnostics do optimize.
