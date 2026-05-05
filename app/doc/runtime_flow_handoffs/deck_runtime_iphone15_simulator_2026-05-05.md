# Deck Runtime Handoff - iPhone 15 Simulator - 2026-05-05

## Resultado

**PASS WITH RISKS.** Optimize Intensity v2 foi provado no app contra backend local real em `http://127.0.0.1:8082`: usuario escolheu `Agressivo`, o app enviou `intensity=aggressive`, exibiu preview selecionavel, desmarcou ao menos uma sugestao, aplicou somente a selecao e validou o deck final preservando o comandante.

## Atualizacao - aggressive async UX - 2026-05-05

**PASS WITH RISKS.** A nova rodada iPhone 15 contra backend 8082 provou que `aggressive` nao bloqueia mais a UI esperando a resposta HTTP: `/ai/optimize` retornou `202` e o app fez polling com progresso. Nesta rodada especifica, o quality gate final rejeitou as trocas e o app exibiu o branch seguro "Nenhuma melhoria segura encontrada"; portanto nao houve preview/apply nesse rerun. A prova anterior de preview parcial/apply/validate permanece registrada abaixo para o contrato Intensity v2 sync.

| Marco | Evidencia |
| --- | --- |
| Backend accepted async | `POST /ai/optimize -> 202 (181ms)` no iPhone 15 runtime. |
| Polling app | Varios `GET /ai/optimize/jobs/:id -> 200` durante o processamento; app manteve progresso em vez de travar a request inicial. |
| Gate preservado | Job terminou com `OPTIMIZE_QUALITY_REJECTED`; screenshot `09_quality_rejected_blocker`; sem apply inseguro. |
| Harness ajustado | `DeckProvider` agora calcula timeout por duracao real de 5 minutos, mesmo com `poll_interval_ms=1000`. |
| Resultado runtime | `flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" ...8082` PASS `02:22 +1`. |

Leitura: o alvo de performance para preview/accepted foi atendido no app (`202` em <1s). O completion completo continuou dependente do job background e do quality gate; quando o gate rejeita, o app apresenta safe no-op em vez de aplicar swaps.

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
