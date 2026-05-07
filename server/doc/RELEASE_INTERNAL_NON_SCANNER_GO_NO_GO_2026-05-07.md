# Release interno non-scanner GO/NO-GO - 2026-05-07

## Veredito

`GO WITH RISKS`

O release interno non-scanner do ManaLoom esta apto para distribuicao controlada em `master`, usando o backend publico `https://evolution-cartinhas.8ktevp.easypanel.host`, com Android fisico SM A135M validado via adb. O veredito nao e `GO` puro porque a prova positiva de Optimize agressivo com preview aplicavel e partial apply continua `NOT PROVEN` no backend vivo desta bateria; a UI, porem, validou falha amigavel/safe no-op sem crash nem erro bruto user-facing.

Scanner, camera, OCR e MLKit scanner foram explicitamente `DEFERRED / IGNORED` e nao fazem parte deste release interno.

## Ambiente

| Item | Resultado |
| --- | --- |
| Data/hora de inicio | 2026-05-07 14:44 BRT |
| Branch alvo | `master` |
| HEAD local/origin | `56aed49` (`Polish ManaLoom mobile UX design`) |
| Sync | `git fetch --prune origin` + `git pull --ff-only origin master` -> already up to date |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Backend `/health` | `200`, `status=healthy`, `environment=production`, `version=1.0.0` |
| Backend `git_sha` | `56aed49c36642148abc99a553459ee584967d47d` |
| Device alvo | `SM A135M`, adb id `R58T300SREH`, Android 14 API 34 |
| Scanner | Fora de escopo; `integration_test/scanner_controlled_harness_runtime_test.dart` nao executado |

## Gates locais

| Comando | Resultado |
| --- | --- |
| `flutter analyze lib test integration_test --no-version-check` | `PASS`, no issues found |
| `flutter test test --no-version-check` | `PASS`, `+551` |

Observacao: a suite unitaria inclui testes de scanner existentes, mas eles rodam em ambiente mock/unitario e nao provam nem bloqueiam scanner fisico. O escopo runtime/device desta decisao excluiu scanner/camera/OCR.

## Runtime Android fisico non-scanner

Todos os testes abaixo foram executados com:

```bash
cd app
flutter test <integration_test_file> \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

| Fluxo | Teste | Resultado | Duracao |
| --- | --- | --- | ---: |
| Search/sets catalog | `integration_test/sets_catalog_runtime_test.dart` | `PASS` | 64s |
| Search -> Cards/Colecoes | `integration_test/sets_search_catalog_runtime_test.dart` | `PASS` | 65s |
| Collection entrypoints | `integration_test/collection_entrypoints_runtime_test.dart` | `PASS` | 59s |
| Profile/community | `integration_test/profile_community_runtime_test.dart` | `PASS` | 82s |
| Life Counter/Lotus runtime | `integration_test/life_counter_lotus_visual_runtime_proof_test.dart` | `PASS` | 97s |
| Auth/create/detail/optimize/validate deck | `integration_test/deck_runtime_m2006_test.dart` | `PASS` | 111s |
| Generate async/save/detail/optimize | `integration_test/deck_generate_async_runtime_test.dart` | `PASS` | 128s |
| Binder dashboard CRUD/filter | `integration_test/binder_dashboard_runtime_test.dart` | `PASS` | 91s |
| Marketplace/trades/messages/notifications | `integration_test/binder_marketplace_trade_runtime_test.dart` | `PASS` | 138s |
| Lotus card search overlay | `integration_test/life_counter_lotus_card_search_visual_smoke_test.dart` | `PASS` | 54s |
| Lotus settings overlay | `integration_test/life_counter_lotus_settings_visual_smoke_test.dart` | `PASS` | 53s |
| Life Counter clock visual | `integration_test/life_counter_clock_visual_smoke_test.dart` | `PASS` | 48s |

Total runtime device: 12/12 `PASS`, 990s somados.

## Classificacao de erros, riscos e latencia

| Categoria | Classificacao | Evidencia |
| --- | --- | --- |
| 4xx esperados | `PASS WITH RISKS` | `POST /ai/optimize -> 422` em deck gerado retornou `OPTIMIZE_NEEDS_REPAIR`; UI exibiu CTA/copy de `rebuild_guided` sem payload bruto. |
| 4xx inesperados | `NONE` | Nenhum 4xx inesperado derrubou teste runtime. |
| 5xx | `NONE` | Nenhum 5xx runtime nos logs de device. |
| Timeout | `NONE BLOCKING` | Nenhum teste falhou por timeout. O screenshot interno do Lotus registrou `LOTUS_SCREENSHOT_NOT_PROVEN`, mas o runtime DOM/state/reopen passou. |
| Crash/tela branca/overflow | `NONE OBSERVED` | Suites device finalizaram `All tests passed`; grep de logs nao encontrou crash, tela branca ou overflow Flutter bloqueante. |
| Erro bruto user-facing | `NONE OBSERVED` | O deck optimize logou falha interna do job, mas o teste validou que a UI nao exibia `executor interno` nem `resposta invalida/invalidada`. |
| Latencia >5s | `RISK ACCEPTED` | `/market/movers?limit=5&min_price=1.0` levou 5303ms; `POST /ai/archetypes` levou 7733ms; AI generate async completou em 15851ms, com feedback inicial em 770ms. |

## Optimize agressivo

Status: `SAFE NO-OP VALIDATED`, `POSITIVE PREVIEW/APPLY NOT PROVEN`.

- `deck_runtime_m2006_test.dart` selecionou intensidade `Agressivo` e enviou `intensity=aggressive`.
- Backend aceitou o start async (`POST /ai/optimize -> 202`) e o polling retornou job terminal com falha de executor.
- A UI apresentou falha amigavel capturada como `09_friendly_optimize_failure`; o teste garantiu ausencia de copy crua user-facing como `executor interno`, `resposta invalida` ou `resposta inválida`.
- `deck_generate_async_runtime_test.dart` recebeu `422 OPTIMIZE_NEEDS_REPAIR` e exibiu `rebuild_guided` como acao de produto (`10_rebuild_guided_blocker`).
- Como o backend vivo nao retornou sugestoes aplicaveis nesta execucao, preview positivo com multiplas sugestoes, deselect e apply parcial seguem `NOT PROVEN` para esta decisao. Isso e risco aceito para release interno, nao P0/P1, porque o app falhou de forma segura e compreensivel.

## Evidencias locais

Diretorio de evidencias local, nao versionado por politica de `.gitignore`:

`app/doc/runtime_flow_proofs_2026-05-07_android_sm_a135m_non_scanner/`

Arquivos principais:

- `logs/git_status_sync.log`
- `logs/device_discovery.log`
- `logs/public_backend_health.log`
- `logs/flutter_analyze_lib_test_integration_test.log`
- `logs/flutter_test_test.log`
- `runtime_summary.tsv`
- `logs/deck_runtime_m2006_test.log`
- `logs/deck_generate_async_runtime_test.log`
- `logs/binder_dashboard_runtime_test.log`
- `logs/binder_marketplace_trade_runtime_test.log`
- `logs/sets_catalog_runtime_test.log`
- `logs/sets_search_catalog_runtime_test.log`
- `logs/collection_entrypoints_runtime_test.log`
- `logs/profile_community_runtime_test.log`
- `logs/life_counter_lotus_visual_runtime_proof_test.log`
- `logs/life_counter_lotus_card_search_visual_smoke_test.log`
- `logs/life_counter_lotus_settings_visual_smoke_test.log`
- `logs/life_counter_clock_visual_smoke_test.log`

Os logs foram redigidos durante a captura para evitar persistencia de JWTs ou headers `Bearer`. Nenhum segredo, token, Sentry DSN, `DATABASE_URL`, chave OpenAI, credencial ou senha foi documentado neste relatorio.

## Decisao

`GO WITH RISKS` para release interno non-scanner.

Condicoes aceitas:

1. Scanner/camera/OCR/MLKit permanecem fora do release interno.
2. Optimize agressivo pode retornar safe no-op/falha amigavel/rebuild guiado; preview positivo/apply parcial deve continuar marcado `NOT PROVEN` ate um backend vivo retornar sugestoes aplicaveis.
3. Latencias >5s em `/market/movers`, `/ai/archetypes` e AI generate async devem ser monitoradas, mas nao bloquearam navegacao, feedback visual ou testes device.
