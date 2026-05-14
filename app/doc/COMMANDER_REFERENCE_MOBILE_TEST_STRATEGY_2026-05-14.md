# Commander Reference Mobile Test Strategy - 2026-05-14

## Resultado

**AUDITADO / DOC-ONLY.** Esta estrategia cobre o fluxo mobile de Generate
Commander para os 20 comandantes promovidos sem exigir que todos rodem em device.
Nao houve alteracao de codigo, harness ou contrato.

Fontes consultadas:

- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/lib/features/decks/providers/deck_provider_support_generation.dart`
- `app/integration_test/runtime_test_helpers.dart`
- `app/integration_test/commander_reference_app_value_runtime_test.dart`
- `app/integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart`
- `app/integration_test/commander_reference_sprint3_lot_b_app_runtime_test.dart`
- `app/integration_test/commander_reference_sprint3_lot_c_app_runtime_test.dart`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- handoffs recentes de Commander Reference em
  `app/doc/runtime_flow_handoffs/`
- relatorios backend de Commander Reference Sprint 2, mini-batch, Sprint 3 A+B e
  Lote C em `server/doc/`

## Universo auditado: 20 promovidos

| Grupo | Promovidos |
| --- | --- |
| Mini-batch inicial | `Lorehold, the Historian`, `Prosper, Tome-Bound`, `Aesi, Tyrant of Gyre Strait`, `Edgar Markov`, `Dina, Essence Brewer`, `Zimone, Infinite Analyst` |
| Sprint 2 | `Kinnan, Bonder Prodigy`, `Muldrotha, the Gravetide`, `Yuriko, the Tiger's Shadow`, `Winota, Joiner of Forces`, `Atraxa, Praetors' Voice` |
| Sprint 3 A+B | `Krenko, Mob Boss`, `Light-Paws, Emperor's Voice`, `Niv-Mizzet, Parun`, `Teysa Karlov`, `Meren of Clan Nel Toth`, `Korvold, Fae-Cursed King`, `Sythis, Harvest's Hand`, `Urza, Lord High Artificer` |
| Sprint 3 C | `Brago, King Eternal` |

Observacao: `Purphoros, God of the Forge` passou em app-runtime adjunto no Lote C,
mas nao entra nos 20 promovidos porque o backend/scorecard segue
`promoted=false`.

## Matriz smoke/representative runtime

### 5 comandantes que melhor cobrem UX mobile

| Prioridade | Commander | Por que cobre melhor UX | O que provar no device |
| ---: | --- | --- | --- |
| 1 | `Atraxa, Praetors' Voice` | Maior pressao de identidade de cor entre promovidos: quatro cores, nome com apostrofo e shell amplo. Cobre risco de off-identity e comparacao de nome com pontuacao. | Campo comandante envia nome exato, preview mostra comandante, save preserva 1 comandante fora das 99, `/validate` retorna valido e `off_identity_count=0`. |
| 2 | `Korvold, Fae-Cursed King` | Tricolor Jund com hifen/apostrofo, historico de bloqueio antes de promocao e risco de lane power/value. | Garante que o app consome o caminho promovido sem regressao do antigo risco; preview/save/details sem erro cru ou timeout. |
| 3 | `Brago, King Eternal` | Unico promovido do Lote C e cobre o gap Azorius WU/blink, mais recente e mais sensivel a drift de deploy. | Runtime deve confirmar `promoted_on_backend=true` no handoff e nao confundir com Purphoros adjunto. |
| 4 | `Krenko, Mob Boss` | Mono-red go-wide/baixa curva ja provado no app; cobre UX de deck simples/rapido e contagem de 99 sem duplicar comandante. | Smoke curto de regressao para progresso async, preview, save e details. |
| 5 | `Urza, Lord High Artificer` | Mono-blue artifacts/control com risco de lane high-power/cEDH e ja provado em runtime app. | Confirmar que nao ha copy tecnica, modal preso ou overflow em preview/details e que validacao final permanece limpa. |

Racional: esses 5 maximizam cobertura de device para UX e contratos sem rodar os
20: mono-color simples (`Krenko`), mono-color high-power (`Urza`), guilda WU
recente (`Brago`), tricolor com historico de risco (`Korvold`) e quatro cores
com pontuacao no nome (`Atraxa`). O conjunto deixa de fora alguns temas
importantes, mas eles ficam cobertos por smoke sem device ou por provas Android
recentes: Voltron (`Light-Paws`), aristocrats (`Teysa`/`Dina`), graveyard
(`Meren`/`Muldrotha`), ninjas (`Yuriko`) e enchantress (`Sythis`).

### Classificacao dos 20 por nivel de prova recomendado

| Commander | Identidade/tema | Nivel recomendado | Status mobile atual |
| --- | --- | --- | --- |
| `Atraxa, Praetors' Voice` | WUBG proliferate/counters | **Representative iPhone runtime** | Sem app target-specific recente; backend public proof PASS. |
| `Korvold, Fae-Cursed King` | BRG sacrifice/treasure | **Representative iPhone runtime** | Sem app target-specific recente apos promocao; backend public proof PASS no Lote B. |
| `Brago, King Eternal` | WU blink/ETB | **Representative iPhone runtime** | App runtime Android PASS_WITH_RISKS; iPhone 15 ainda nao provado. |
| `Krenko, Mob Boss` | R Goblins go-wide | **Representative iPhone runtime** | App runtime Android PASS_WITH_RISKS no Lote A. |
| `Urza, Lord High Artificer` | U artifacts/control | **Representative iPhone runtime** | App runtime Android PASS_WITH_RISKS no Lote B. |
| `Lorehold, the Historian` | RW spells/topdeck | Contract/widget smoke | App runtime Android PASS em 2026-05-11. |
| `Prosper, Tome-Bound` | BR exile/treasure | Contract/widget smoke | App runtime Android PASS em app value. |
| `Aesi, Tyrant of Gyre Strait` | GU lands | Contract/widget smoke | App runtime Android PASS em app value; normalizacao de face duplicada ja tratada no harness. |
| `Edgar Markov` | BRW Vampires | Contract/widget smoke | App runtime Android PASS em app value. |
| `Dina, Essence Brewer` | BG drain/aristocrats | Contract/widget smoke | App runtime Android PASS em Strixhaven profiles. |
| `Zimone, Infinite Analyst` | GU counters/X-spells | Contract/widget smoke | App runtime Android PASS em Strixhaven profiles. |
| `Kinnan, Bonder Prodigy` | GU ramp/combo | Contract/API smoke | Sem app target-specific recente; backend public proof PASS. |
| `Muldrotha, the Gravetide` | BGU graveyard value | Contract/API smoke | Sem app target-specific recente; backend public proof PASS. |
| `Yuriko, the Tiger's Shadow` | UB ninjas/topdeck | Contract/API smoke | Sem app target-specific recente; backend public proof PASS. |
| `Winota, Joiner of Forces` | RW combat engine | Contract/API smoke | Sem app target-specific recente; backend public proof PASS. |
| `Light-Paws, Emperor's Voice` | W Auras/Voltron | Contract/API smoke, candidato alternativo se Atraxa/Korvold falharem no device | Sem app target-specific recente; backend public proof PASS. |
| `Niv-Mizzet, Parun` | UR spellslinger | Contract/API smoke | Sem app target-specific recente; backend public proof PASS. |
| `Teysa Karlov` | WB aristocrats | Contract/widget smoke | App runtime Android PASS_WITH_RISKS no Lote A. |
| `Meren of Clan Nel Toth` | BG graveyard recursion | Contract/widget smoke | App runtime Android PASS_WITH_RISKS no Lote B. |
| `Sythis, Harvest's Hand` | GW enchantress | Contract/API smoke | Sem app target-specific recente; backend public proof PASS. |

## Asserts que faltam

| Lacuna | Evidencia atual | Assert recomendado |
| --- | --- | --- |
| Diagnostics de Commander Reference nao sao assertados no runtime app para todos os promovidos. | Lote A/B/C validam preview/save/details/`/validate`, mas nao verificam `reference_profile_used`, `reference_card_stats_used`, `reference_deck_corpus_used`, `on_theme_candidate_count` ou `unresolved_reference_cards` no resultado de generate. | No harness representativo, capturar o resultado de `/ai/generate` quando possivel ou chamar API sanitizada com o mesmo `commander_name` antes/depois do runtime e assertar profile/stats/corpus ativos, unresolved `0` e sem timeout fallback. |
| Preview valida mais por texto do que por estrutura. | Harnesses usam `find.text('Preview antes de salvar')` e `expect(find.text(commanderName), findsWidgets)`. | Assertar por key de container, total `100`, comandante `1x`, main `99` e ausencia do comandante nas linhas do main antes de salvar. |
| `deck_commander_name_matches` esta instavel. | Handoffs Lote B/C registram `commander` correto e `/validate` PASS, mas `commander_name` agregado em `GET /decks/:id` nao refletiu o comandante salvo. | Manter `commander`/`deck_cards.is_commander` como fonte de verdade no gate; registrar `deck_commander_name_matches=false` como warning ate o backend/agregado ser corrigido. |
| Seletores de navegacao ainda usam labels. | UI map aceita fallback para `Decks`/`Meus Decks`; harnesses usam `find.text('Decks').first` e `find.text('Meus Decks')`. | Quando mexer em shell/decks, adicionar/usar keys de tab/rota para abrir a lista sem `.first`. |
| Comandantes com pontuacao/face split nao estao centralizados. | Aesi exigiu normalizacao de `//`; Chulane teve retorno double-face em docs backend; helpers de cada harness duplicam `_matchesCardName`. | Extrair normalizacao de nome de comandante para helper compartilhado de integration test. |
| Prova iPhone 15 segue ausente. | Handoffs recentes descobriram iPhone 15 `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, mas nao rodaram por blocker historico de `MLImage.framework`/scanner. | Antes de declarar PASS iOS, rodar batch no iPhone 15 com backend local ou documentar `NOT PROVEN` com output de discovery/build. |
| Batch exato de 5 comandantes ainda nao existe. | Harnesses atuais rodam grupos fixos: app value, Lote A, Lote B, Lote C. | Parametrizar casos via `--dart-define=COMMANDER_CASES=...` ou criar um harness unico `commander_reference_representative_runtime_test.dart` que aceite a matriz dos 5. |
| Rate limit publico pode contaminar auditoria em lote. | Lote B encontrou `429` em disparo continuo e precisou backoff. | No batch local/publico, usar backend local quando possivel; se usar publico, inserir backoff por arquivo e registrar `429` como risco operacional, nao falha de deck. |

## Keys e test helpers faltantes

Keys existentes suficientes para acao principal:

- `deck-generate-format-field`
- `deck-generate-commander-field`
- `deck-generate-prompt-field`
- `deck-generate-submit-button`
- `deck-generate-name-field`
- `deck-generate-save-button`

Keys recomendadas para reduzir seletores frageis em P1 Generate:

| Superficie | Key sugerida | Motivo |
| --- | --- | --- |
| Painel de progresso | `deck-generate-progress-panel` | Hoje o runtime valida progresso por copy (`Pedido aceito`, `Tecendo lista`). |
| Chip de progresso | `deck-generate-progress-step-<index>` | Permite assertar estado async sem depender de texto/localizacao. |
| Preview root | `deck-generate-preview-section` | O titulo `Preview antes de salvar` e o unico anchor estrutural atual. |
| Total do preview | `deck-generate-preview-total` | Permite assertar `100 cartas` sem parsear texto solto. |
| Linha do comandante | `deck-generate-preview-commander` | Permite provar comandante no slot correto. |
| Lista main do preview | `deck-generate-preview-main-list` | Permite conferir quantidade/linhas sem depender de `Scrollable.first`. |
| Linha de card preview | `deck-generate-preview-card-<index>` ou hash sanitizado | Necessario para provar que comandante nao aparece nas 99 antes do save. |
| Avisos do preview | `deck-generate-preview-warnings` | Ancora warnings/mock sem depender de copy. |
| Erros de validacao | `deck-generate-preview-validation-errors` | Ancora falhas amigaveis e ausencia de raw 4xx/5xx. |
| Dialog de salvamento | `deck-generate-save-blocking-dialog` | Hoje o loading usa `DeckBlockingTaskDialog` sem key especifica de Generate. |

Helpers recomendados:

1. `runCommanderGenerateCase(...)` em `runtime_test_helpers.dart`: abrir Generate,
   preencher comandante/prompt, aguardar preview, salvar, abrir details e retornar
   resumo sanitizado.
2. `validateCommanderDeckByApi(...)`: centralizar flatten de `main_board/cards`,
   normalizacao `//`, contagens `main_qty`, `commander_count`,
   `commander_in_99_count` e `off_identity_count`.
3. `openDeckListFromShell(...)`: evitar `find.text('Decks').first`.
4. `expectGenerateReferenceDiagnostics(...)`: helper para asserts opcionais de
   diagnostics sem persistir decklist ou prompt completo.

## Comando para runtime batch

Uso recomendado para iPhone 15 com backend local vivo. Este batch reaproveita os
harnesses existentes; por isso roda mais do que os 5 representantes ate existir
um harness parametrizavel por comandante.

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"

cd server
PORT=8081 dart run .dart_frog/server.dart
```

Em outro terminal:

```bash
curl -sS http://127.0.0.1:8081/health

cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
for test_file in \
  integration_test/commander_reference_app_value_runtime_test.dart \
  integration_test/commander_reference_sprint3_lot_a_app_runtime_test.dart \
  integration_test/commander_reference_sprint3_lot_b_app_runtime_test.dart \
  integration_test/commander_reference_sprint3_lot_c_app_runtime_test.dart
do
  flutter test "$test_file" \
    -d "iPhone 15" \
    --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
    --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
    --dart-define=DISABLE_FIREBASE_STARTUP=true \
    --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
    --reporter expanded \
    --no-version-check
done
```

Resultado esperado do batch atual:

- cobre UI real de register/login, Generate Commander, preview, save, Deck
  Details e `/decks/:id/validate`;
- cobre diretamente Prosper, Edgar, Aesi, Krenko, Teysa, Urza, Meren e Brago;
- tambem roda Purphoros como adjunto do Lote C, mas ele deve continuar marcado
  como nao promovido;
- nao cobre Atraxa/Korvold/Light-Paws/Niv/Sythis/Yuriko/Winota/Kinnan/Muldrotha
  em app runtime target-specific sem novo harness ou parametrizacao.

## Menor proxima acao

Criar, em uma rodada futura de codigo, um unico harness parametrizavel para os 5
representantes (`Atraxa`, `Korvold`, `Brago`, `Krenko`, `Urza`) usando os helpers
compartilhados acima. Ate la, a estrategia segura e: rodar o batch existente no
iPhone 15 para provar o fluxo mobile amplo e manter os demais promovidos sob
contract/API smoke, sem declarar device proof individual para os 20.
