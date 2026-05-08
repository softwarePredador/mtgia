# Commander Edition Runtime — iPhone 15 Simulator — 2026-05-08

## Resultado

**PASS** no iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`,
runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`, contra backend local
real `http://127.0.0.1:8081`.

Fluxo provado sem Scanner/camera/OCR/MLKit:

- Registrar usuario QA descartavel.
- Criar deck Commander real.
- Inserir `Lorehold, the Historian` como comandante na edicao `PSOS #201p`.
- Abrir busca de comandante e confirmar metadados de edicao visiveis.
- Abrir Deck Detail, aba `Cartas`, dialog de detalhes e picker de edicao.
- Trocar comandante para a edicao `SOS #284`.
- Confirmar via API que existe exatamente 1 comandante e que a carta nao foi
  adicionada ao `main_board` das 99.

## Comandos

```bash
cd app && flutter analyze integration_test/commander_edition_runtime_test.dart --no-version-check
```

```bash
cd app && flutter test integration_test/commander_edition_runtime_test.dart -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF --dart-define=API_BASE_URL=http://127.0.0.1:8081 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 --dart-define=DISABLE_FIREBASE_STARTUP=true --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true --reporter expanded --no-version-check
```

## Evidencias

Marcadores do runtime:

- `COMMANDER_EDITION_RUNTIME_COMMANDER Lorehold, the Historian`
- `COMMANDER_EDITION_INITIAL PSOS #201p`
- `COMMANDER_EDITION_TARGET SOS #284`
- `COMMANDER_EDITION_RUNTIME_RESULT PASS`
- `00:45 +1: All tests passed!`

Screenshots locais decodificados:

- `app/doc/runtime_flow_proofs_2026-05-08_iphone15_commander_edition/01_commander_search_edition_visible.png`
- `app/doc/runtime_flow_proofs_2026-05-08_iphone15_commander_edition/02_commander_detail_before_edition_change.png`
- `app/doc/runtime_flow_proofs_2026-05-08_iphone15_commander_edition/03_commander_card_dialog_current_edition.png`
- `app/doc/runtime_flow_proofs_2026-05-08_iphone15_commander_edition/04_commander_edition_picker_target_visible.png`
- `app/doc/runtime_flow_proofs_2026-05-08_iphone15_commander_edition/04_commander_detail_after_edition_change.png`

## Bugs encontrados e corrigidos

- O picker de edicao era aberto enquanto o dialog de detalhes ainda estava por
  cima. Resultado: a lista existia na arvore, mas o toque acertava o dialog
  antigo. Corrigido fechando o dialog antes de abrir o picker.
- `GET /decks/:id` duplicava cartas quando `sets.code` tinha variantes por
  casing, por causa do `LEFT JOIN sets`. Corrigido usando `DISTINCT ON
  (LOWER(code))` no join de metadados de colecao.

## Riscos

- Latencias observadas em backend local remoto: `POST /decks/:id/cards` ~7.7s e
  `POST /decks/:id/cards/replace` ~6.9s. Funcionalmente passou, mas esses
  endpoints continuam bons candidatos para otimizacao futura.
- O picker usa `/cards/printings?sync=true`; nessa base local, a lista aplicavel
  exposta pelo app foi `PSOS #201p` e `SOS #284`.
