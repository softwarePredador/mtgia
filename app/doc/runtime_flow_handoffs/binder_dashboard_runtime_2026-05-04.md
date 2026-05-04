# Binder/Fichario Dashboard Runtime - 2026-05-04

## Status

Verdict: `PASS` no iPhone 15 Simulator para dashboard/filtros/lifecycle do fichario contra backend local real.

## Data/hora

- Inicio da rodada: `2026-05-04T08:38:38-03:00`
- Runtime PASS observado: `2026-05-04T08:55-03:00`

## Ambiente

- Repo: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch alvo: `master`
- Backend usado pelo app: `http://127.0.0.1:8082`
- Backend health:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-05-04T08:45:13.376228","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

## Device discovery

`flutter devices` confirmou:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
SM A135M (mobile)  • R58T300SREH                          • android-arm • Android 14 (API 34)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` confirmou:

```text
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
```

## Backend/probes reais

Backend temporario iniciado com:

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
```

Probes reais executados em `http://127.0.0.1:8082`:

| Endpoint | Resultado |
| --- | --- |
| `GET /health` | `200`, healthy |
| `POST /auth/register` | `201`, usuario QA criado |
| `GET /cards?name=Sol%20Ring&limit=1` | `200`, `Sol Ring`, set `drc` |
| `POST /binder` | `201`, item criado |
| `GET /binder?search=Sol%20Ring&set=drc&rarity=...&language=pt&foil=false&sort=price&order=desc` | `200`, filtro novo retornou 1 item |
| `GET /binder/stats` | `200`, `total_items=2`, `unique_cards=1`, `duplicate_copies=1`, `estimated_value=21.0`, `set_progress_len=1`, distributions `condition/foil/language/rarity` |
| `GET /sets?limit=2&page=1` | `200`, 2 sets |
| `GET /cards?set=ECC&limit=2&page=1` | `200`, 2 cartas |

## Runtime iPhone 15

Comando executado:

```bash
cd app
flutter test integration_test/binder_dashboard_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Resultado final:

```text
00:36 +1: All tests passed!
```

## O que foi real

- UI real Flutter no iPhone 15 Simulator.
- Backend local real em `http://127.0.0.1:8082`.
- Auth real via `POST /auth/register` e `POST /auth/login`.
- Fluxo real em `CollectionScreen -> Fichario`.
- Dashboard real carregando `/binder/stats`.
- Busca real em `/cards`.
- Criacao real via `POST /binder`.
- Edicao real via `PUT /binder/:id`.
- Filtro real por set em `GET /binder?...&set=DRC`.
- Remocao real via `DELETE /binder/:id`.
- Stats reais conferidos apos edit/delete.

## O que foi mockado

- Nada no backend.
- Nada no contrato HTTP.
- O teste controla dados de QA criando usuario e itens temporarios.

## Cobertura funcional

- Dashboard mostra resumo de valor/progresso/distribuicoes quando ha dados.
- Wishlist/cartas faltantes aparecem a partir de itens `list_type=want`.
- Duplicadas ficam claras por `duplicate_copies`.
- Filtros/ordenacao aceitos pelo backend: nome, set, raridade, condicao, idioma, foil/non-foil, quantidade, preco e atualizacao.
- Empty/loading/error states permanecem amigaveis no app; o harness nao observou erro tecnico cru.
- Sem crash, overflow fatal, timeout de teste ou 4xx/5xx inesperado no runtime PASS.

## Observacoes de console

- O build iOS Simulator continua emitindo o aviso conhecido de pods sem suporte `arm64` para Apple Silicon/iOS 26+; o iPhone 15 iOS 17.4 executou e passou.
- `Firebase Performance indisponivel` aparece por ausencia de `Firebase.initializeApp()` no harness de teste; o app segue com metricas HTTP desativadas nessa sessao, sem crash.
- Requests ficaram abaixo de 2s no runtime PASS final.

## Android fisico opcional

Sanity Android fisico solicitado como opcional ficou `not proven`.

Comando tentado:

```bash
adb devices
adb -s R58T300SREH reverse tcp:8082 tcp:8082
```

Resultado:

```text
List of devices attached

adb: device 'R58T300SREH' not found
```

Owner: ambiente/device. Menor proxima acao: reconectar/desbloquear o SM A135M, garantir `adb devices` listando `R58T300SREH`, aplicar `adb reverse tcp:8082 tcp:8082` e rodar o mesmo `binder_dashboard_runtime_test.dart` em `-d R58T300SREH`.

## Validacoes associadas

| Comando | Resultado |
| --- | --- |
| `cd server && dart analyze routes/binder routes/cards routes/sets lib test` | PASS |
| `cd server && dart test -r expanded` | PASS, `00:04 +556` |
| `cd app && flutter analyze lib/features/binder lib/features/collection lib/features/cards test/features/binder test/features/collection test/features/cards --no-version-check` | PASS |
| `cd app && flutter test test/features/binder test/features/collection test/features/cards --no-version-check` | PASS, `00:03 +11` |
| `cd app && flutter analyze integration_test/binder_dashboard_runtime_test.dart --no-version-check` | PASS |
| `cd app && flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" ...` | PASS, `00:36 +1` |

## Blockers

- Nenhum blocker para iPhone 15 Simulator.
- Android fisico opcional bloqueado por `adb` nao encontrar `R58T300SREH`.

## Menores proximas acoes

1. Retestar Android fisico quando `adb devices` listar o SM A135M.
2. Se o dashboard crescer, considerar um componente dedicado de analytics do fichario para reduzir densidade visual no topo da lista.
