# Testes do backend ManaLoom

Este diretório contém testes determinísticos, contratos HTTP live opt-in e
algumas suites manuais históricas. O contrato vigente de perfis, autorização e
conclusão está em `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`.

## Regra principal

O comando local padrão nunca deve criar usuários/decks, aplicar migração,
chamar IA externa ou escrever em PostgreSQL:

```bash
cd server
RUN_INTEGRATION_TESTS=0 \
JWT_SECRET=local_test_secret_not_for_production \
dart test -P all-local
```

Na raiz, o equivalente integrado é:

```bash
./scripts/quality_gate.sh full
```

O preset `all-local` exclui `live`, `live_backend`, `live_db_write`,
`live_external` e `historical_external_snapshot`. A presença de uma API
acessível não ativa essas tags.

## Tags

| Tag | Significado |
| --- | --- |
| `live` | cenário HTTP opt-in |
| `live_backend` | exige backend acessível em `TEST_API_BASE_URL` |
| `live_db_write` | cria, altera ou remove dados pela API/DB |
| `live_external` | pode chamar OpenAI ou outro serviço externo |
| `historical_external_snapshot` | valida snapshot externa datada e não conta como cobertura local ativa |
| `battle_product_e2e` | contrato battle vivo, fora da suíte local |

Ter uma tag não é autorização. A camada live só deve ser iniciada pelo perfil
E2E guardado e com alvo explícito.

## Snapshots externas históricas de Commander meta

Três artefatos TopDeck/EDHTop16 de abril de 2026 foram removidos
deliberadamente do repositório no cleanup de `2026-06-29` e continuam
ignorados em `server/test/artifacts/`:

- `external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.json`;
- `topdeck_edhtop16_expansion_dry_run_latest.json`;
- `topdeck_edhtop16_expansion_dry_run_latest.validation.json`.

Eles não são fixtures determinísticas: o primeiro veio de revisão web manual;
o segundo depende de EDHTop16 GraphQL e páginas TopDeck; o terceiro depende do
segundo e pode consultar PostgreSQL para legalidade Commander mesmo em
`dry-run`. Por isso os três asserts data-specific usam
`historical_external_snapshot` e ficam fora de `all-local`/`full`.

A lógica pura de staging permanece cobertura ativa por payload contratual
construído em memória em `external_commander_meta_staging_support_test.dart`.
Parsers de GraphQL/HTML TopDeck também usam entradas locais controladas em
`external_commander_deck_expansion_support_test.dart`; nenhum dado externo é
fabricado para substituir a snapshot removida.

Para auditar uma snapshot regenerada em sessão externa aprovada, coloque os
três arquivos nos caminhos ignorados e rode:

```bash
dart test -P historical-external-snapshots
```

Sem os arquivos, esse perfil retorna três `SKIP` explicitamente classificados
como históricos; esse resultado não é cobertura ativa nem aprovação do
dataset.

## Entradas canônicas

| Objetivo | Comando na raiz | Escrita de produto |
| --- | --- | --- |
| server + app completos | `./scripts/quality_gate.sh full` | não |
| contratos de IA/app | `./scripts/quality_gate.sh ai-bridge` | não |
| dados + IA + deckbuilder | `./scripts/quality_gate.sh deep-ai` | leitura de PG |
| battle completo | `./scripts/quality_gate.sh battle` | não |
| corpus Commander read-only | `VALIDATION_PREFLIGHT_ONLY=1 ./scripts/quality_gate.sh resolution` | não |
| produto integrado | `./scripts/quality_gate.sh e2e` | não por padrão |

O corpus mutante e os testes HTTP live exigem os tokens textuais descritos no
contrato E2E. Não rode diretamente um arquivo marcado `live_db_write` contra
produção.

## Suites manuais legacy

`e2e_general_tests.py`, `e2e_ml_tests.py` e `e2e_trade_tests.py` preservam
cobertura HTTP histórica ainda não migrada por completo. Elas:

- exigem URL `http(s)` explícita;
- exigem `MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL`;
- bloqueiam o hostname conhecido de produção;
- são permitidas somente em local/staging;
- não fazem parte do gate determinístico nem do gate canônico de release.

Exemplo em staging aprovado:

```bash
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
python3 server/test/e2e_general_tests.py --api https://staging.example
```

O token não deve ser persistido em `.env` ou CI.

## Corpus Commander

A fixture estável é
`server/test/fixtures/optimization_resolution_corpus.json`. O preflight
read-only valida seleção, diversidade, commanders e contrato do corpus sem
subir API nem criar artefatos de produto:

```bash
VALIDATION_PREFLIGHT_ONLY=1 ./scripts/quality_gate.sh resolution
```

O modo completo cria usuário/decks temporários e por isso fica bloqueado sem
aprovação PostgreSQL específica.

## Como adicionar testes

- Regra pura, parser, validador ou adapter sem rede: teste determinístico.
- HTTP real: marque `live` e `live_backend`.
- Qualquer criação/alteração/remoção de dados: acrescente `live_db_write`.
- Chamada de provedor: acrescente `live_external`.
- Não esconda mutação atrás de `RUN_INTEGRATION_TESTS` sem tag e sem guard.
- Todo skip deve informar o pré-requisito ausente.
- Artefatos gerados vão para `/tmp` ou `server/test/artifacts/` ignorado; apenas
  evidência revisada pode ser versionada.

## Critério de aceite

Uma mudança de backend não está pronta só porque o teste focado passou. Rode o
gate proporcional à área e, antes da conclusão local, execute a matriz mínima
do contrato E2E. Camadas live/device não executadas permanecem pendências
explícitas de release.
