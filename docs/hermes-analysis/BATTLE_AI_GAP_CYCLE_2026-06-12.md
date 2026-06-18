# Battle/AI Gap Cycle — 2026-06-12

## Escopo

Primeiro ciclo seguro de implementação após triagem da branch
`origin/codex/hermes-analysis-docs`.

Foco do ciclo:

- manter PostgreSQL/backend como fonte de verdade;
- manter Hermes como laboratório/auditor, sem promover SQLite a fonte final;
- reduzir recomendações por nomes fixos em rota experimental;
- preservar estabilidade de release e contrato app-facing.

## Triagem Hermes

Branch validada antes da implementação:

- `origin/codex/hermes-analysis-docs` existe e foi acessada via `git fetch`.
- A branch tinha divergência grande contra `origin/master` e não foi mergeada.
- Achados úteis foram lidos em `TECHNICAL_MAP.md`, `PLANO_CORRECAO.md`,
  `IMPLEMENTATION_GAPS.md` e
  `BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`.

### Incorporado agora

- `/decks/:id/recommendations` ainda tinha fallback com recomendação literal de
  `Command Tower`.
- A mesma rota usava raridade como proxy genérico de impacto.
- A busca de recomendações montava filtros de cor por string SQL.

### Documentado como pendência

- Consolidar lookup semântico em service compartilhado entre
  `/decks/:id/recommendations`, `/ai/weakness-analysis`, `/ai/optimize` e
  prompts runtime.
- Remover listas/nomeações restantes apenas quando existir policy ou dado
  versionado equivalente.
- Manter `card_battle_rules` como camada executável/reviewable; ela não deve
  substituir `card_function_tags` para deckbuilding.

### Rejeitado ou fora do ciclo

- Mergear a branch Hermes docs direto na `master`: rejeitado por divergência
  ampla e risco de copiar conclusões sem triagem.
- Ban global de Mox: fora do escopo e explicitamente rejeitado pela decisão de
  produto.
- Mudança Flutter/runtime: fora do ciclo porque o contrato HTTP e o payload
  app-facing foram preservados.

## Código alterado

Arquivo:

- `server/routes/decks/[id]/recommendations/index.dart`

Mudanças:

- usa `cards.color_identity` para filtrar recomendações por identidade de cor;
- preserva `recommendations.add/remove`, `analysis`, `statistics`, `colors`,
  `trending`, `source` e `message`;
- busca candidatos por `card_function_tags`, `card_semantic_tags_v2`,
  `card_legalities` e fallback textual parametrizado;
- remove recomendação literal de `Command Tower`;
- remove raridade como proxy de impacto;
- evita `ARRAY[$colorFilter]` e passa a usar `TypedValue(Type.textArray)`;
- não usa `LIMIT 1` para conter fanout semântico;
- usa `EXISTS` para reconhecer múltiplas funções/tags sem multiplicar linhas
  de deck.

Teste de fonte atualizado:

- `server/test/experimental_deck_ai_authorization_source_test.dart`

## Lorehold

Validação Lorehold executada no ciclo:

- `commander_reference_profile_support_test.dart`
- `commander_reference_card_stats_support_test.dart`
- `functional_card_tags_commander_probe_test.dart`

Resultado: passou. O ciclo não alterou generate/optimize/app runtime, então a
prova Lorehold aqui valida ausência de regressão na referência Lorehold e na
classificação funcional usada como base semântica. A rota de recommendations
permanece experimental e não é o caminho app-facing principal; `/ai/optimize`
continua preferido para otimização no produto.

## Validações executadas

```bash
cd server
dart format routes/decks/[id]/recommendations/index.dart test/experimental_deck_ai_authorization_source_test.dart
dart analyze routes/decks/[id]/recommendations/index.dart test/experimental_deck_ai_authorization_source_test.dart
dart test test/experimental_deck_ai_authorization_source_test.dart --reporter compact
dart analyze bin lib routes test
dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/functional_card_tags_commander_probe_test.dart --reporter compact
```

## Pendências restantes

P1:

- Extrair um service compartilhado de recomendação semântica para evitar drift
  entre weakness-analysis, recommendations e optimize.
- Remover nomes fixos restantes no mock runtime de `/ai/optimize` quando
  `deckOptimizer == null`, desde que exista fallback DB-backed equivalente.
- Threadar o mesmo lookup DB-backed para prompts runtime em vez de exemplos
  soltos de cartas.

P2:

- Criar teste live opcional para `/decks/:id/recommendations` em backend sem
  `OPENAI_API_KEY`, garantindo exercício do fallback sem chamar OpenAI.
- Medir qualidade das sugestões DB-backed em corpus maior antes de promover a
  rota experimental para qualquer tela principal.

P3:

- Persistir histórico de recomendações úteis ou rejeitadas somente depois de
  existir consumidor real do dado.
