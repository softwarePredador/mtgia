# ManaLoom Deck Generation Performance Audit

Data: 2026-07-06
Escopo: montagem de decks pelo app Flutter usando o backend publico de producao.

## Veredito

O fluxo esta dentro de um padrao aceitavel para uma geracao de deck com IA:

- Feedback inicial ao usuario: PASS, 329 ms.
- Aceite do job no backend: PASS, 467 ms.
- Conclusao do job async pelo app: PASS, 10,6 s.
- Fluxo completo gerar + resolver cartas + salvar + voltar da tela: PASS WITH CAUTION, 20,2 s.
- Qualidade basica do deck gerado: PASS no teste frio direto, com 99 cartas no main deck + commander, invalid_cards=0.

O ponto que ainda impede uma experiencia "premium fast" nao e a chamada de IA em si. O gargalo atual esta no pos-processamento e nas telas seguintes, principalmente resolucao de cartas, analise e archetypes.

## Criterios usados

| Area | Padrao desejado | Resultado | Status |
| --- | ---: | ---: | --- |
| Primeiro feedback visual | <= 1 s | 329 ms | PASS |
| POST /ai/generate | <= 1 s | 467 ms | PASS |
| Job async de geracao | <= 30 s | 10,6 s app / 16,0 s cold API | PASS |
| Fluxo completo da tela gerar | <= 30 s | 20,2 s | PASS WITH CAUTION |
| Polling sem 429/quota falsa | Sem consumir quota de IA | Corrigido localmente | PASS LOCAL |
| Deck Commander valido | 100 cartas, commander, invalid_cards=0 | PASS no probe frio | PASS |

## Evidencia medida

Backend publico:

- URL: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Health: HTTP 200.
- Git SHA reportado em producao durante a medicao: `d1d3abe2343ba2ef0f2a20a2ba98a084f560ecb8`.

Teste real pelo app:

- Dispositivo: `iPhone 15 Pro Max` simulator.
- Comando: `flutter test integration_test/deck_generate_async_runtime_test.dart -d 'iPhone 15 Pro Max' ...`
- Resultado: `00:51 +1: All tests passed!`
- `ASYNC_GENERATE_INITIAL_FEEDBACK_MS`: 329 ms.
- `POST /ai/generate`: 202 em 467 ms.
- Job `GET /ai/generate/jobs/...`: 200 em 279 ms e 296 ms.
- Breadcrumb `ai_generate_async_completed`: 10.611 ms.
- `POST /cards/resolve/batch`: 200 em 5.727 ms.
- `POST /decks`: 200 em 425 ms.
- Tela `generate`: POP em 20.226 ms.
- `POST /decks/:id/validate`: 200 em 416 ms.
- `POST /decks/:id/pricing`: 200 em 430 ms.
- `GET /decks/:id/analysis`: 200 em 3.450 ms.
- `POST /ai/archetypes`: 200 em 5.916 ms.
- `POST /ai/optimize`: 422 em 2.408 ms, com safe outcome esperado: `OPTIMIZE_NEEDS_REPAIR_SAFE_OUTCOME rebuild_guided_available`.

Probe frio direto na API, com commander e prompt unicos:

- `POST /ai/generate`: 202 em 344 ms.
- `result_async_completed_ms`: 16.028 ms.
- `result_total_ms`: 15.745 ms.
- `openai_ms`: 15.377 ms.
- `validation_ms`: 217 ms.
- `reference_profile_ms`: 142 ms.
- `cache_hit`: false.
- `invalid_cards`: 0.
- Quantidade estimada: 99 cartas no main deck + commander = 100.
- Warnings tratados: uma carta fora da identidade foi removida; lands basicos completaram o deck.

## Achados

1. A geracao por IA esta saudavel para o padrao atual.

O backend completou geracao fria em aproximadamente 16 s, e o teste pelo app concluiu o job em 10,6 s. Para uma montagem de deck Commander com validacao, isso esta dentro do esperado.

2. O usuario recebe resposta rapida.

O app deu feedback inicial em 329 ms e o backend aceitou o job em 467 ms. Isso evita a percepcao de tela travada.

3. O polling tinha dois problemas.

O app aguardava duas vezes por ciclo em job pendente. Na pratica, com intervalo de 5 s, os polls podiam acontecer perto de 5 s, 15 s e 25 s, em vez de 5 s, 10 s e 15 s.

Tambem havia risco de o endpoint de status `GET /ai/generate/jobs/:id` consumir rate-limit/quota de IA, porque passava pelo middleware de chamadas custosas. Isso podia causar 429 em clientes que respeitavam o `poll_interval_ms` bruto de 1000 ms.

4. O maior gargalo restante e `POST /cards/resolve/batch`.

O endpoint levou 5.727 ms no teste real pelo app. Isso representa uma parte grande do tempo total de 20,2 s da tela de geracao.

5. Telas pos-geracao ainda tem chamadas lentas.

`GET /decks/:id/analysis` levou 3.450 ms e `POST /ai/archetypes` levou 5.916 ms. Essas chamadas nao quebram a geracao, mas afetam a sensacao de fluidez ao abrir detalhes e seguir para otimizacao.

6. Ha ruido de imagem de carta.

O teste registrou tentativas de imagem Scryfall com retorno 400 para URL no padrao `cards/named?exact=...&set=...&format=image`. Isso nao derrubou o fluxo, mas pode prejudicar carregamento visual e logs.

## Correcoes aplicadas localmente

1. `app/lib/features/decks/providers/deck_provider_support_generation.dart`

Removido o segundo delay no loop de polling. Agora o app espera uma vez por ciclo, reduzindo a latencia percebida quando o job conclui entre polls.

2. `server/routes/ai/_middleware.dart`

`/ai/generate/jobs/*` e `/ai/optimize/jobs/*` agora ficam em fluxo auth-only, igual `/ai/commander-learning`. Polling de status continua autenticado, mas deixa de consumir quota/rate-limit de chamada custosa de IA.

3. `server/test/commander_learned_deck_support_test.dart`

Teste ampliado para garantir que rotas read-only de suporte de IA fiquem antes de `costlyAiHandler`.

## Validacoes executadas

Server:

```bash
dart test test/commander_learned_deck_support_test.dart test/ai_generate_job_authorization_source_test.dart test/rate_limit_middleware_test.dart
```

Resultado: `+32`, todos passaram.

App:

```bash
flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart --no-version-check
```

Resultado: `+65`, todos passaram.

Analyze:

```bash
flutter analyze lib/features/decks/providers/deck_provider_support_generation.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart --no-version-check
```

Resultado: sem issues.

Integracao real app -> backend publico:

```bash
flutter test integration_test/deck_generate_async_runtime_test.dart -d 'iPhone 15 Pro Max' --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=DISABLE_FIREBASE_STARTUP=true --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true --reporter expanded --no-version-check
```

Resultado: `00:51 +1: All tests passed!`

## Pendencias recomendadas

P1. Otimizar `POST /cards/resolve/batch`.

Opcao preferida: a resposta de geracao ja devolver identificadores/campos suficientes para salvar o deck sem precisar resolver todas as cartas novamente em chamada lenta.

P1. Deploy das correcoes locais de polling e middleware.

A medicao de producao ainda reportou SHA `d1d3abe2343ba2ef0f2a20a2ba98a084f560ecb8`. A correcao do middleware so protege o backend publico depois do deploy.

P2. Ajustar `poll_interval_ms` retornado pelo backend.

Mesmo com o app protegendo com minimo de 5 s, clientes externos podem usar o valor bruto de 1000 ms. O backend deveria devolver um intervalo mais conservador ou aplicar um rate-limit leve separado para status read-only.

P2. Revisar `GET /decks/:id/analysis` e `POST /ai/archetypes`.

As chamadas estao funcionais, mas lentas o suficiente para afetar a percepcao de continuidade depois da geracao.

P2. Corrigir URLs Scryfall antigas com `cards/named?exact=...&set=...&format=image`.

Essas URLs retornaram 400 durante o teste. O ideal e normalizar para image URL direta da carta ou reparar a fonte no cache/banco.

## Conclusao

A montagem de deck pelo app esta funcional e em tempo aceitavel. O produto ja entrega uma experiencia valida para usuario final, com feedback rapido e geracao dentro da janela esperada. Para virar diferencial premium, a prioridade tecnica agora e reduzir o pos-processamento de cartas e garantir que polling/status nunca consuma quota nem gere 429 indevido.
