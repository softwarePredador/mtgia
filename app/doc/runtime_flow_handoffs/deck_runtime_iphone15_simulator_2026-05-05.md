# Deck Runtime Handoff - iPhone 15 Simulator - 2026-05-05

## Resultado

**PASS WITH RISKS.** Optimize Intensity v2 foi provado no app contra backend local real em `http://127.0.0.1:8082`: usuario escolheu `Agressivo`, o app enviou `intensity=aggressive`, exibiu preview selecionavel, desmarcou ao menos uma sugestao, aplicou somente a selecao e validou o deck final preservando o comandante.

## Ambiente

| Item | Valor |
| --- | --- |
| Repo | `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia` |
| Branch alvo | `master` |
| Device | iPhone 15 Simulator |
| Simulator id | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Backend | `http://127.0.0.1:8082` |
| Backend health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0"}` |

## Comandos executados

| Comando | Resultado |
| --- | --- |
| `cd app && flutter analyze lib/features/decks test/features/decks --no-version-check` | PASS |
| `cd app && flutter test test/features/decks --no-version-check` | PASS, `00:12 +145` |
| `cd server && PORT=8082 dart run .dart_frog/server.dart` | Backend iniciado localmente |
| `curl -sS http://127.0.0.1:8082/health` | PASS, healthy |
| `cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS, `02:41 +1` |

## Evidencia de runtime

Arquivo de saida da ultima execucao: `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/copilot-tool-output-1777996644561-nqkrug.txt`.

Resumo filtrado: `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/copilot-tool-output-1777996808719-kk46xt.txt`.

| Marco | Evidencia |
| --- | --- |
| Login/cadastro/deck | Screenshots `01_login`, `02_registered_home`, `03_decks`, `04_deck_created`, `05_empty_deck_details`. |
| Import completo | Screenshot `06_import_commander`; deck seed Commander 100/100 com `Talrand, Sky Summoner` e shell spellslinger mono-U. |
| Comandante preservado | Screenshot `07_commander_imported`; assert final encontrou `Talrand, Sky Summoner`. |
| Intensidade agressiva | Screenshot `08c_optimize_sheet_aggressive`; log sanitizado: `intensity: aggressive`, `bracket: 2`, `keep_theme: true`. |
| Resposta backend | `POST /ai/optimize -> 200 (108490ms)`, `mode=optimize`, `outcome_code=optimized`, `optimize_intensity.selected=aggressive`. |
| Swaps | Backend retornou 6 remocoes e 6 adicoes apos quality gate reduzir escopo abaixo do alvo nominal agressivo. |
| Preview selecionavel | Screenshot `09_preview`. |
| Partial apply | Screenshot `09b_preview_partial_selection`; uma checkbox foi desmarcada antes de aplicar. |
| Validacao final | Screenshot `10_complete_validated`; deck final validado 100/100. |

## O que foi real vs mocked

| Superficie | Status |
| --- | --- |
| Backend | Real, Dart Frog local na porta 8082. |
| Banco/dados MTG | Real via backend local configurado. |
| Device/UI | iPhone 15 Simulator real via `flutter test integration_test`. |
| App API base | Real via `API_BASE_URL` e `PUBLIC_API_BASE_URL` apontando para `127.0.0.1:8082`. |
| Scanner fisico/camera/OCR | Fora do escopo, nao executado. |
| Testes unit/widget | Mocks/fakes conforme suites de `test/features/decks`. |

## Checklist de aceite

| Criterio | Resultado |
| --- | --- |
| App envia `intensity` | PASS |
| Fallback legacy sem `intensity` | PASS por teste unitario |
| Explicacao clara por modo | PASS |
| Preview permite desmarcar | PASS por teste widget e runtime |
| Apply parcial | PASS por teste unitario e runtime |
| Commander preservado | PASS |
| `rebuild_guided` como CTA | PASS por teste smoke/widget |
| 4xx/5xx/timeouts amigaveis | PASS por mapper/testes; `OPTIMIZE_QUALITY_REJECTED` classificado como safe no-op |
| Sem secrets/log sensivel | PASS; breadcrumbs/logs app-side sanitizados |
| Sem crash/overflow/raw error/modal preso | PASS na ultima execucao |

## Riscos residuais

- Latencia live do optimize agressivo ficou alta (`108490ms`) no deck seed; o app manteve progresso/modal e concluiu sem travar.
- `aggressive` mirou 10-20, mas o backend retornou 6 swaps porque o quality gate removeu sugestoes inseguras. Produto deve comunicar "ate 10-20 quando houver swaps seguros" ou monitorar decks com reducao frequente.
- Scanner fisico/camera/OCR segue **NOT PROVEN** por estar fora do escopo.
