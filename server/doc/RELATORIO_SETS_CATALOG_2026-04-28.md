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
