# Optimize Async Executor Fix - 2026-05-19

## Veredito

`PASS` local, public proof pendente de deploy.

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

## Risco restante

O backend publico ainda precisa receber o commit da correcao. Depois do deploy,
rodar novamente o probe publico de optimize async completo antes de reavaliar
qualquer promocao da Semantic Layer v2.
