# Relatorio Sets/Colecoes Catalog - 2026-04-28

## Baseline encontrado

- `GET /sets` existia em `server/routes/sets/index.dart`, com `q`, `code`, `limit` e `page`, mas retornava apenas metadados basicos.
- `GET /cards?set=<code>` existia em `server/routes/cards/index.dart` e ja comparava `set_code` com `LOWER(...)`, permitindo `ECC` e `ecc`.
- `server/bin/sync_cards.dart` baixa `SetList.json`, cria a tabela `sets` e faz upsert de `code`, `name`, `release_date`, `type`, `block`, `is_online_only` e `is_foreign_only`.
- A base local em `127.0.0.1:8082` ja tinha sets futuros e novos, incluindo `MSH`, `MSC`, `OM2`, `SOS` e `SOC`.
- A duplicidade real `soc`/`SOC` foi confirmada no baseline; a correcao aplicada e query-level, sem migracao destrutiva.

## Arquivos alterados

- Backend:
  - `server/routes/sets/index.dart`
  - `server/routes/cards/index.dart`
  - `server/lib/sets_catalog_contract.dart`
  - `server/lib/card_query_contract.dart`
  - `server/test/sets_route_test.dart`
  - `server/test/cards_route_test.dart`
- App:
  - `app/lib/main.dart`
  - `app/lib/features/collection/models/mtg_set.dart`
  - `app/lib/features/collection/screens/collection_screen.dart`
  - `app/lib/features/collection/screens/latest_set_collection_screen.dart`
  - `app/lib/features/collection/screens/set_cards_screen.dart`
  - `app/lib/features/collection/screens/sets_catalog_screen.dart`
  - `app/test/features/collection/sets_catalog_screen_test.dart`
  - `app/integration_test/sets_catalog_runtime_test.dart`
- Documentacao:
  - `server/doc/RELATORIO_SETS_CATALOG_2026-04-28.md`
  - `server/manual-de-instrucao.md`
  - `app/doc/runtime_flow_handoffs/sets_catalog_iphone15_simulator_2026-04-28.md`

## Contrato backend

`GET /sets` preserva os parametros existentes:

- `q`: busca por nome ou codigo.
- `code`: filtro por codigo, normalizado de forma case-insensitive.
- `limit`: minimo 1, maximo 200, default 50.
- `page`: minimo 1, default 1.

Cada item de `data` agora inclui, sem remover campos legados:

```json
{
  "code": "MSH",
  "name": "Marvel Super Heroes",
  "release_date": "2026-06-26",
  "type": "expansion",
  "block": null,
  "is_online_only": false,
  "is_foreign_only": null,
  "card_count": 14,
  "status": "future"
}
```

`card_count` e calculado no banco local com `LEFT JOIN cards ON LOWER(cards.set_code) = LOWER(sets.code)`.

`status` e calculado a partir de `release_date`:

- `future`: release date depois de hoje.
- `new`: lancado nos ultimos 30 dias.
- `current`: lancado entre 31 e 180 dias.
- `old`: mais antigo que 180 dias ou sem `release_date`.

A ordenacao segue `release_date DESC NULLS LAST, name ASC`.

Para duplicatas de casing, a query usa `ROW_NUMBER() OVER (PARTITION BY LOWER(code))` e prefere codigo em maiusculas. No baseline, `code=soc` retorna apenas `SOC`.

`GET /cards?set=<code>` segue DB-backed e case-insensitive. A tela de detalhe usa:

```text
GET /cards?set=<code>&limit=100&page=<page>&dedupe=true
```

## Sync de future/new sets

`server/bin/sync_cards.dart` baixa `SetList.json` e persiste metadados futuros em `sets` antes de cards existirem. As cartas aparecem somente quando o JSON do set ou o sync incremental/full ja trouxe cards locais.

Comando oficial de refresh:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
dart run bin/sync_cards.dart
```

## UX implementada no app

- Nova aba `Colecoes` dentro da area `Colecao`.
- Atalho no app bar da area `Colecao` para abrir o catalogo.
- Tela `Colecoes MTG` lista nome, codigo, data de lancamento, tipo, quantidade de cartas e badge `Futura`, `Nova`, `Atual` ou `Antiga`.
- Busca por nome/codigo usa `GET /sets?q=...`.
- Filtros visuais locais por status ajudam a separar futuras, novas, atuais e antigas.
- Detalhe de set usa `SetCardsScreen`, tambem reutilizado pela antiga tela de ultima edicao.
- Set futuro sem cartas locais mostra estado explicito de dados parciais, sem crash.

## Comandos executados

Backend:

```bash
curl -s 'http://127.0.0.1:8082/sets?limit=10&page=1'
curl -s 'http://127.0.0.1:8082/cards?set=ECC&limit=3&page=1'
cd server
dart format lib/sets_catalog_contract.dart lib/card_query_contract.dart routes/sets/index.dart routes/cards/index.dart test/sets_route_test.dart test/cards_route_test.dart
dart analyze routes/sets routes/cards bin test
dart test test/sets_route_test.dart test/cards_route_test.dart
curl -s 'http://127.0.0.1:8082/sets?limit=10&page=1'
curl -s 'http://127.0.0.1:8082/sets?q=Marvel&limit=10&page=1'
curl -s 'http://127.0.0.1:8082/sets?code=soc&limit=10&page=1'
curl -s 'http://127.0.0.1:8082/cards?set=ECC&limit=3&page=1'
```

App:

```bash
cd app
dart format lib/features/collection/models/mtg_set.dart lib/features/collection/screens/set_cards_screen.dart lib/features/collection/screens/sets_catalog_screen.dart lib/features/collection/screens/latest_set_collection_screen.dart lib/features/collection/screens/collection_screen.dart lib/main.dart test/features/collection/sets_catalog_screen_test.dart
flutter analyze lib/features/cards lib/features/collection test/features/cards test/features/collection
flutter test test/features/cards test/features/collection
flutter analyze lib/main.dart
flutter analyze integration_test/sets_catalog_runtime_test.dart
```

Runtime iPhone 15:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
xcrun simctl boot "iPhone 15" 2>/dev/null || true
xcrun simctl bootstatus "iPhone 15" -b
cd app
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

## Resultado iPhone 15 Simulator

Proven em iPhone 15 Simulator:

- abriu a tela de catalogo;
- carregou `/sets?limit=50&page=1`;
- buscou `Marvel` via `/sets?limit=50&page=1&q=Marvel`;
- abriu `Marvel Super Heroes`;
- carregou `/cards?set=MSH&limit=100&page=1&dedupe=true`;
- renderizou lista de cards ou estado parcial aceito;
- voltou ao catalogo sem crash.

Resultado final: `All tests passed!`.

Observacao: o build iOS emitiu aviso conhecido de plugins MLKit sem suporte arm64 para simuladores Apple Silicon iOS 26+, mas o build e o teste finalizaram com sucesso.

## Limitacoes conhecidas

- Os filtros de status no app sao visuais sobre a pagina carregada; a busca por nome/codigo continua sendo o caminho recomendado para sets antigos distantes.
- `card_count` reflete cartas locais sincronizadas, nao o total oficial remoto em tempo real.
- Sets futuros podem aparecer com `card_count=0` ate o proximo sync trazer cards.

## Pendencias / not proven

Nenhuma pendencia funcional da sprint ficou `not proven`.

## Validacao final de prontidao de produto - 2026-04-28 14h

### Decisao sobre Search `Cards | Colecoes`

Decisao: **sim, Sets/Colecoes tambem deve aparecer na area de Search**.

Motivo: o acesso em `Colecao -> Colecoes` esta correto e claro para quem ja esta no hub de colecao, mas a busca e o comportamento esperado para descoberta de conteudo MTG. A integracao foi feita como abas `Cards | Colecoes` dentro de `CardSearchScreen`, preservando a busca atual de cards e reaproveitando `SetsCatalogScreen`/`SetCardsScreen`.

Arquivos adicionados/alterados nesta validacao:

- `app/lib/features/cards/screens/card_search_screen.dart`
- `app/lib/features/collection/screens/sets_catalog_screen.dart`
- `app/test/features/cards/screens/card_search_screen_test.dart`
- `app/integration_test/sets_search_catalog_runtime_test.dart`
- `server/doc/RELATORIO_SETS_CATALOG_2026-04-28.md`
- `server/manual-de-instrucao.md`
- `app/doc/runtime_flow_handoffs/sets_catalog_iphone15_simulator_2026-04-28.md`

### Auditoria tecnica e dados com backend real em 8082

Com backend local em `http://127.0.0.1:8082`:

- `/sets?limit=10&page=1` retornou `status` e `card_count` para futuros, novos e atuais.
- `/sets?q=Marvel&limit=10&page=1` encontrou sets futuros `MSH` e `MSC`, alem de sets antigos Marvel ja sincronizados.
- `/sets?code=soc&limit=10&page=1` retornou uma unica entrada canonica `SOC`, provando dedupe query-level para `SOC/soc`.
- `/cards?set=MSH&limit=3&page=1` retornou 3 cards reais de `Marvel Super Heroes`.
- `/cards?set=OM2&limit=3&page=1` retornou `data: []`, comportamento esperado para set futuro catalogado com `card_count=0`; a UI mostra estado explicito de dados parciais.

Trechos auditados:

```text
MSH | Marvel Super Heroes | 2026-06-26 | card_count=14 | status=future
MSC | Marvel Super Heroes Commander | 2026-06-26 | card_count=7 | status=future
OM2 | Through the Omenpaths 2 | 2026-06-26 | card_count=0 | status=future
SOC | Secrets of Strixhaven Commander | 2026-04-24 | card_count=11 | status=new
```

Set futuro com `card_count=0` encontrado:

```text
OM2 | Through the Omenpaths 2 | 2026-06-26 | expansion
```

Duplicidades de `sets.code` por casing:

```text
80 codigos com duplicidade de casing.
Primeiros exemplos: 10e/10E, 2x2/2X2, 2xm/2XM, 30a/30A, 8ed/8ED, blc/BLC, c13/C13, ecc/ECC, mar/MAR, soc/SOC.
```

Conclusao: a duplicidade e ampla na tabela `sets`, mas o contrato novo esta protegido por `PARTITION BY LOWER(code)` e preferencia por codigo uppercase. Nao foi feita migracao destrutiva nesta etapa.

Cartas recentes/futuras com `color_identity IS NULL`:

```text
SCH | Store Championships | 2026-02-06 | 1
SLD | Secret Lair Drop | 2026-01-26 | 90
ECC | Lorwyn Eclipsed Commander | 2026-01-23 | 264
ECL | Lorwyn Eclipsed | 2026-01-23 | 180
PECL | Lorwyn Eclipsed Promos | 2026-01-23 | 87
PF26 | MagicFest 2026 | 2026-01-01 | 1
PW26 | Wizards Play Network 2026 | 2026-01-01 | 2
TLA | Avatar: The Last Airbender | 2025-11-21 | 540
TLE | Avatar: The Last Airbender Eternal | 2025-11-21 | 272
```

Impacto: no catalogo de Sets isso e apenas qualidade de dado, porque a tela nao filtra por identidade de cor e mapeia `null` como lista vazia sem crash. Em fluxos de busca/adicao para Commander, uma carta com identidade nula pode ser tratada como incolor pelos filtros client-side; isso e uma limitacao de dados pre-existente e deve ser tratado em uma task dedicada de saneamento/sync, nao como bloqueio do catalogo.

### Comandos executados nesta validacao final

Backend:

```bash
cd server
dart analyze routes/sets routes/cards bin test
dart test test/sets_route_test.dart test/cards_route_test.dart
curl -sS http://127.0.0.1:8082/health
curl -sS "http://127.0.0.1:8082/sets?limit=10&page=1"
curl -sS "http://127.0.0.1:8082/sets?q=Marvel&limit=10&page=1"
curl -sS "http://127.0.0.1:8082/sets?code=soc&limit=10&page=1"
curl -sS "http://127.0.0.1:8082/cards?set=MSH&limit=3&page=1"
curl -sS "http://127.0.0.1:8082/cards?set=OM2&limit=3&page=1"
```

App:

```bash
cd app
dart format lib/features/cards/screens/card_search_screen.dart lib/features/collection/screens/sets_catalog_screen.dart test/features/cards/screens/card_search_screen_test.dart integration_test/sets_search_catalog_runtime_test.dart
flutter analyze lib/features/cards lib/features/collection test/features/cards test/features/collection --no-version-check
flutter test test/features/cards test/features/collection --no-version-check
flutter analyze lib/main.dart --no-version-check
```

iPhone 15 Simulator:

```bash
cd app
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check

flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

### Resultado iPhone 15 final

Proven:

- `Colecao -> Colecoes -> buscar Marvel -> abrir Marvel Super Heroes -> voltar`
- `Search -> Colecoes -> buscar ECC -> abrir Lorwyn Eclipsed Commander -> voltar`

Ambos os testes terminaram com `All tests passed!` contra backend real `127.0.0.1:8082`.

### Pendencias depois da validacao final

Nenhuma pendencia funcional de produto ficou `not proven`.

Pendencias nao bloqueantes para backlog:

- sanear duplicidades historicas de `sets.code` por casing com migracao segura;
- sanear `cards.color_identity IS NULL` em sets recentes/futuros para evitar permissividade indevida em filtros Commander client-side.

## Revisao final de UX - 2026-04-28 15h

Objetivo: validar se `Search -> Cartas | Colecoes` e `Colecao -> Colecoes` estao claros, consistentes e prontos para usuario final.

Ajustes pequenos aplicados:

- Aba de busca renomeada de `Cards` para `Cartas`, mantendo `Colecoes` ao lado.
- Placeholder do catalogo alterado de `codigo do set` para `codigo da colecao`.
- Empty state de futuro sem cartas alterado para `Dados parciais de colecao futura`.
- `Colecao -> Colecoes` agora renderiza o catalogo sem AppBar interna duplicada, mantendo o AppBar do hub `Colecao`.

Itens revisados:

- labels em portugues: OK apos ajustes acima;
- badges `Futura`, `Nova`, `Atual`, `Antiga`: OK;
- empty state para colecao futura sem cards: OK com `OM2`;
- loading/error state: preservados via progress indicator e `AppStatePanel`;
- ordenacao e busca: preservadas pelo contrato `/sets` e busca `q`;
- detalhe do set: preservado via `SetCardsScreen` com `/cards?set=<code>`;
- responsividade no iPhone 15: provada em simulador;
- regressao na busca de cartas: nao houve regressao; `Search -> Cartas` buscou `Black Lotus` antes de abrir a aba `Colecoes`.

Comandos executados nesta revisao:

```bash
cd app
dart format lib/features/cards/screens/card_search_screen.dart lib/features/collection/screens/collection_screen.dart lib/features/collection/screens/set_cards_screen.dart lib/features/collection/screens/sets_catalog_screen.dart test/features/collection/sets_catalog_screen_test.dart integration_test/sets_catalog_runtime_test.dart integration_test/sets_search_catalog_runtime_test.dart
flutter analyze lib/features/cards lib/features/collection test/features/cards test/features/collection
flutter test test/features/cards test/features/collection
flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/sets_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

Resultado final: todos os comandos passaram. O primeiro run do teste de catalogo em paralelo ficou preso por concorrencia/lock de Flutter/Xcode e foi encerrado pelo PID especifico; o teste foi reexecutado sozinho e passou com `All tests passed!`.
