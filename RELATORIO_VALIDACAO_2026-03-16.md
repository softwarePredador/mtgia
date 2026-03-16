# Relatorio de Validacao - 2026-03-16

## Escopo

Foram corrigidos e validados os seguintes pontos:

- `app`: `DeckProvider.createDeck()` nao pode mais criar deck incompleto quando `/cards/resolve/batch` falha ou retorna cartas nao resolvidas.
- `server/auth`: normalizacao consistente de `email` e `username` no fluxo de cadastro/login.
- `server/auth`: suporte seguro a senhas acima de 72 bytes com compatibilidade retroativa para hashes bcrypt ja existentes.
- `server/rate-limit`: fallback deixou de concentrar usuarios diferentes em `anonymous` quando ha headers suficientes para fingerprint.
- `server`: centralizacao dos helpers de URL do Scryfall e de deteccao de colunas opcionais dos decks.

## Evidencias

### App

- Novo teste unitario em `app/test/features/decks/providers/deck_provider_test.dart`.
- Coberturas adicionadas:
  - falha explicita quando `/cards/resolve/batch` responde erro;
  - falha explicita quando o backend retorna `unresolved`;
  - preservacao de cartas com `card_id` junto com cartas resolvidas por `name`.

### Backend

- Novo teste de integracao em `server/test/auth_flow_integration_test.dart`.
- Coberturas adicionadas:
  - cadastro persiste `username/email` normalizados;
  - login aceita email com caixa e espacos diferentes;
  - cadastro bloqueia duplicidade por variacao de caixa.

- `server/test/auth_service_test.dart` agora valida:
  - senha longa;
  - `normalizeEmail`;
  - `normalizeUsername`.

- `server/test/rate_limit_middleware_test.dart` agora valida:
  - uso do primeiro IP de `X-Forwarded-For`;
  - fallback por fingerprint;
  - manutencao de `anonymous` apenas sem headers suficientes.

## Comandos executados

- `app/flutter analyze`
- `app/flutter test`
- `server/dart analyze`
- `server/dart test test/auth_service_test.dart`
- `server/dart test test/rate_limit_middleware_test.dart`
- `server/dart test test/auth_flow_integration_test.dart` com `RUN_INTEGRATION_TESTS=1`
- `server/dart test test/import_to_deck_flow_test.dart` com `RUN_INTEGRATION_TESTS=1`
- `server/dart test test/decks_incremental_add_test.dart` com `RUN_INTEGRATION_TESTS=1`
- `server/dart test test/decks_crud_test.dart` com `RUN_INTEGRATION_TESTS=1`
- `server/dart test`

## Resultado

- `app/flutter analyze`: sem issues.
- `app/flutter test`: passando.
- `server/dart analyze`: 8 warnings preexistentes, sem erros.
- Testes direcionados do backend: passando.
- `server/dart test` completo: passando.

## Ajuste adicional apos o relatorio inicial

- Foi corrigido o calculo de `consistencyScore` em `server/lib/ai/goldfish_simulator.dart`.
- O score estava sendo multiplicado por `100` duas vezes, saturando quase qualquer deck em `100`.
- Efeito pratico:
  - o caso `TC052` voltou a diferenciar deck inconsistente de deck corrigido;
  - `server/dart test` completo passou a fechar sem falhas.
