# Sets Catalog iPhone 15 Simulator Handoff - 2026-04-28

## Escopo provado

Catalogo mobile de Colecoes/Sets do ManaLoom contra backend local real em `http://127.0.0.1:8082`.

Fluxo validado:

1. Abre a experiencia de catalogo.
2. Carrega lista de sets via `/sets`.
3. Busca set futuro/novo por nome (`Marvel`).
4. Abre detalhe de `Marvel Super Heroes`.
5. Carrega cards via `/cards?set=MSH`.
6. Renderiza cards ou estado parcial explicito.
7. Volta ao catalogo sem crash.

## Ambiente

- Simulator: `iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF)`
- Backend: Dart Frog local, porta `8082`
- API base usada pelo app: `http://127.0.0.1:8082`
- Teste: `app/integration_test/sets_catalog_runtime_test.dart`

## Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

```bash
xcrun simctl boot "iPhone 15" 2>/dev/null || true
xcrun simctl bootstatus "iPhone 15" -b
```

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

## Evidencia de runtime

Trechos relevantes do output:

```text
[ApiClient] GET http://127.0.0.1:8082/sets?limit=50&page=1
[ApiClient] GET /sets?limit=50&page=1 -> 200
[ApiClient] GET http://127.0.0.1:8082/sets?limit=50&page=1&q=Marvel
[ApiClient] GET /sets?limit=50&page=1&q=Marvel -> 200
[ApiClient] GET http://127.0.0.1:8082/cards?set=MSH&limit=100&page=1&dedupe=true
[ApiClient] GET /cards?set=MSH&limit=100&page=1&dedupe=true -> 200
All tests passed!
```

## Observacoes

- O simulador foi bootado durante a execucao.
- O build iOS mostrou aviso de dependencias MLKit sem suporte arm64 para simuladores Apple Silicon iOS 26+, mas o build concluiu e o teste passou.
- O teste usa a tela real `SetsCatalogScreen` e o `ApiClient` real, sem mock de rede.

## Resultado

`proved` no iPhone 15 Simulator.

## Not proven

Nada ficou `not proven` para o fluxo de catalogo de sets.

## Validacao complementar - Search Cards | Colecoes

Decisao de produto: **expor Colecoes tambem na area de Search**. O acesso `Colecao -> Colecoes` permanece, mas a descoberta por busca agora tambem existe em `CardSearchScreen` com abas `Cards | Colecoes`.

### Fluxos provados no iPhone 15

1. `Colecao -> Colecoes`
2. Busca `Marvel`
3. Abre `Marvel Super Heroes`
4. Carrega `/cards?set=MSH`
5. Volta ao catalogo sem crash
6. `Search -> Colecoes`
7. Busca `ECC`
8. Abre `Lorwyn Eclipsed Commander`
9. Carrega `/cards?set=ECC`
10. Volta ao catalogo sem crash

### Comandos complementares executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

### Evidencia complementar

```text
[ApiClient] GET http://127.0.0.1:8082/sets?limit=50&page=1
[ApiClient] GET /sets?limit=50&page=1 -> 200
[ApiClient] GET http://127.0.0.1:8082/sets?limit=50&page=1&q=Marvel
[ApiClient] GET /sets?limit=50&page=1&q=Marvel -> 200
[ApiClient] GET http://127.0.0.1:8082/cards?set=MSH&limit=100&page=1&dedupe=true
[ApiClient] GET /cards?set=MSH&limit=100&page=1&dedupe=true -> 200
All tests passed!

[ApiClient] GET http://127.0.0.1:8082/sets?limit=50&page=1
[ApiClient] GET /sets?limit=50&page=1 -> 200
[ApiClient] GET http://127.0.0.1:8082/sets?limit=50&page=1&q=ECC
[ApiClient] GET /sets?limit=50&page=1&q=ECC -> 200
[ApiClient] GET http://127.0.0.1:8082/cards?set=ECC&limit=100&page=1&dedupe=true
[ApiClient] GET /cards?set=ECC&limit=100&page=1&dedupe=true -> 200
All tests passed!
```

### Resultado complementar

`proved` para o acesso original por Colecao e para o novo acesso por Search no iPhone 15 Simulator.

## Revisao final de UX - 15h

### Ajustes aplicados

- `Search -> Cards | Colecoes` ficou `Search -> Cartas | Colecoes`.
- Placeholder do catalogo agora fala `codigo da colecao`.
- Empty state de futuro sem cards agora fala `Dados parciais de colecao futura`.
- A aba `Colecao -> Colecoes` usa o AppBar do hub `Colecao` e nao duplica o AppBar `Colecoes MTG`.

### Prova no iPhone 15

Fluxos provados novamente contra backend real `http://127.0.0.1:8082`:

1. `Search -> Cartas`: busca `Black Lotus`, provando ausencia de regressao na busca de cartas.
2. `Search -> Colecoes`: busca `ECC`, abre `Lorwyn Eclipsed Commander`, carrega `/cards?set=ECC`.
3. `Colecao -> Colecoes`: busca `Marvel`, abre `Marvel Super Heroes`, carrega `/cards?set=MSH`.
4. Busca `OM2`, abre `Through the Omenpaths 2`, renderiza empty state explicito de colecao futura sem cards.
5. Navegacao de volta ao catalogo sem crash.

Comandos:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter analyze lib/features/cards lib/features/collection test/features/cards test/features/collection
flutter test test/features/cards test/features/collection
flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Resultado: `All tests passed!` nos dois testes runtime. Houve aviso conhecido de MLKit sem suporte arm64 para simulador Apple Silicon iOS 26+, mas o build e os testes concluiram com sucesso.
