# Deck Runtime Handoff - iPhone 15 Simulator - 2026-05-05

## Atualizacao - Aggressive no-op diagnostics UI - 2026-05-06 08:59-09:05 BRT

**PASS WITH RISKS (runtime NOT RUN).** A rodada desta atualizacao foi app/backend-contract focada: a UI passou a consumir diagnostics agregados de `optimize_diagnostics.aggressive_candidate_quality` para explicar safe no-op/quality rejected no modo `Agressivo`, mas o fluxo iPhone 15 Simulator nao foi reexecutado.

| Item | Evidencia |
| --- | --- |
| Device primario conhecido | iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime conhecido | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Backend usado no app | **NOT RUN** nesta rodada; nenhuma porta local foi iniciada. |
| Health | **NOT RUN** nesta rodada. |
| Comando app | `cd app && flutter analyze lib/features/decks test/features/decks --no-version-check` -> PASS |
| Comando app tests | `cd app && flutter test test/features/decks --no-version-check` -> PASS `00:10 +153` |
| Comando backend | `cd server && dart analyze routes/ai/optimize/index.dart` -> PASS |
| Runtime command | **NOT RUN**: `flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" ...` nao executado apos esta mudanca. |
| Screenshots/logs runtime | Nao gerados nesta rodada. |
| Real vs mocked | Parser/support/widget tests usam payloads fake; nenhum device/UI real ou backend live foi executado nesta atualizacao. |
| Scanner fisico/camera/OCR | **DEFERRED / NOT PROVEN**, fora do escopo. |

Leitura de produto: quando aggressive encontra ideias mas o gate bloqueia as inseguras, a UI mostra "A IA encontrou ideias, mas o gate bloqueou as inseguras para preservar seu deck", contadores agregados de candidatos/pares/swaps e o principal bloqueio traduzido. Sem diagnostics, permanece o fallback amigavel existente. O backend async agora preserva `quality_error.optimize_diagnostics` no polling para que a UI consiga explicar o mesmo caso em jobs 202/failed sem expor payload bruto, JWT, secrets ou prompts.

Menor proxima acao: rerodar o runtime iPhone 15 com backend 8082 e um deck que reproduza `OPTIMIZE_QUALITY_REJECTED` para capturar screenshot da nova mensagem.

## Atualizacao - Aggressive Candidate Quality v2 runtime - 2026-05-06 08:29-08:40 BRT

**PASS WITH RISKS.** A rodada fresca no iPhone 15 Simulator contra backend local real `http://127.0.0.1:8082` provou que o app continua abrindo detalhes de deck Commander completo, selecionando `Agressivo`, enviando `intensity=aggressive`, recebendo aceite async de `/ai/optimize` e exibindo o branch seguro de quality gate sem crash, overflow, timeout cru, modal preso ou erro 4xx/5xx bruto. Nesta execucao o backend terminou em safe no-op/quality rejected, entao preview aplicavel, desmarcacao e apply parcial ficaram **NOT PROVEN nesta rodada**; a evidencia anterior de preview parcial/apply/validate permanece valida para o contrato Intensity v2 quando o backend retorna swaps.

| Item | Evidencia |
| --- | --- |
| Device | iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| Runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| `flutter devices` | `iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)` |
| `xcrun simctl` | `iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)` |
| Backend | `http://127.0.0.1:8082` |
| Health | `{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0"}` |
| App focused checks | `flutter analyze lib/features/decks test/features/decks --no-version-check` PASS; `flutter test test/features/decks --no-version-check` PASS `00:19 +147` |
| Backend sanity | `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_optimize_flow_test.dart --tags live -r expanded` PASS `02:45 +10 ~1` |
| Runtime command | `cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` |
| Runtime result | PASS `02:58 +1` |
| Optimize transport | `POST /ai/optimize -> 202 (169ms)`; polling `GET /ai/optimize/jobs/:id -> 200` observado 125 vezes |
| UI proof | Screenshots `01_login` a `08c_optimize_sheet_aggressive` e `09_quality_rejected_blocker` em `app/doc/runtime_flow_proofs_2026-05-06_iphone15_simulator/` |
| Log path | `app/doc/runtime_flow_proofs_2026-05-06_iphone15_simulator/deck_runtime_m2006_test_iphone15_8082.log` |
| Diagnostics marker | `optimize_diagnostics.aggressive_candidate_quality` **NOT CAPTURED** no log app desta rodada; a UI nao consome diagnostics e o job async falho nao imprimiu payload final. O contrato permanece backend-owned/aditivo. |

### Leitura de produto

- `aggressive_candidate_quality` nao deve virar UI principal agora: os contadores sao diagnostico operacional e podem confundir usuario final.
- Vale promover no futuro uma mensagem derivada e agregada quando houver `low_candidate_coverage` ou buckets de rejeicao recorrentes, por exemplo "encontramos poucas trocas seguras para este comandante/bracket"; a tela nao deve exibir nomes de buckets crus.
- Scanner fisico/camera/OCR ficou **DEFERRED / NOT PROVEN**, fora do escopo.

## Resultado

**PASS WITH RISKS.** Optimize Intensity v2 foi provado no app contra backend local real em `http://127.0.0.1:8082`: usuario escolheu `Agressivo`, o app enviou `intensity=aggressive`, exibiu preview selecionavel, desmarcou ao menos uma sugestao, aplicou somente a selecao e validou o deck final preservando o comandante.

## Atualizacao - Aggressive Candidate Quality v2 etapa 3 - 2026-05-05

**PASS WITH RISKS.** A etapa 3 alterou apenas backend/contrato aditivo: o app nao precisou mudar para consumir `optimize_diagnostics.aggressive_candidate_quality`, porque campos novos sao opcionais e a UI continua usando `removals`, `additions`, `*_detailed`, `quality_error`, `outcome_code` e polling existentes. Nao foi executada nova rodada iPhone 15 nesta etapa; a evidencia mobile anterior de aggressive preview/apply/validate permanece valida, e os testes app-side de contrato de decks passaram contra a nova forma de resposta.

| Marco | Evidencia |
| --- | --- |
| Backend 8082 vivo | `curl http://127.0.0.1:8082/health` retornou healthy. |
| Backend live optimize | `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test ...ai_optimize_flow_test.dart...` PASS `02:44 +77 ~1`. |
| App contract analyze | `flutter analyze lib/features/decks test/features/decks --no-version-check` PASS. |
| App deck tests | `flutter test deck_details_screen_smoke_test.dart deck_provider_test.dart deck_optimize_flow_support_test.dart --no-version-check` PASS `00:07 +46`. |
| iPhone 15 runtime | Nao rerodado nesta etapa por ausencia de mudanca app/UI; blocker/risco documentado como runtime nao revalidado para os novos campos diagnosticos opcionais. |

Leitura: o app preview/apply nao depende dos novos diagnosticos; se o backend retornar menos swaps ou safe no-op, o fluxo app ja validado continua mostrando o branch seguro existente.

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
