# ManaLoom Lorehold Commander flow - 2026-05-11

## Resultado

**PASS WITH RISKS** para contrato app/backend e profile publico. **BLOCKED** para
runtime fisico no device alvo `SM A135M` / `R58T300SREH`, porque o aparelho nao
estava conectado/detectavel nesta rodada.

## Escopo

- Fechar o piloto Lorehold Commander Reference Profile v1 no app sem testar
  Scanner/camera/OCR/MLKit.
- Confirmar que o backend publico esta no commit do profile Lorehold.
- Fazer o app enviar `commander_name` para `/ai/generate` quando o usuario
  informa o comandante no fluxo de gerar deck.
- Provar o uso real do profile de forma sanitizada e registrar o bloqueio de
  runtime fisico quando o device alvo nao aparece.

## Evidencia de ambiente

| Item | Resultado |
| --- | --- |
| Branch | `master`, sincronizada com `origin/master` |
| Backend publico | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| `/health` | `200`, `status=healthy`, `git_sha=87d9b7c3814ea07c3e89d718976fb694efd57d1d` |
| `/health/git_sha` | `404`; SHA obtido pelo payload de `/health` |
| Device alvo | `SM A135M` / `R58T300SREH` |
| Device discovery | `R58T300SREH` ausente em `flutter devices` e `adb devices -l` |
| Scanner/OCR | Nao testado por escopo |

## Mudanca app-side

- `DeckGenerateScreen` agora mostra `deck-generate-commander-field` em
  Commander/Brawl.
- `DeckProvider.generateDeck` aceita `commanderName` opcional.
- `deck_provider_support_generation.dart` envia `commander_name` no request
  async e preserva o campo nos fallbacks sync.
- Apps/fluxos que deixam o comandante vazio continuam omitindo `commander_name`.

## Prova publica sanitizada do profile

Fluxo executado por API publica com usuario QA descartavel, sem registrar JWT,
email real, token, payload sensivel ou secrets:

1. `POST /auth/register`
2. `POST /ai/generate` com `async=true`, `format=commander` e
   `commander_name=Lorehold, the Historian`
3. Poll de `poll_url` ate `completed`

Resumo do resultado:

| Criterio | Valor |
| --- | --- |
| HTTP inicial | `202` |
| Polls | `processing` x3, `completed` x1 |
| Commander | `Lorehold, the Historian` |
| Total main deck | `99` |
| Total com comandante | `100` |
| Lorehold nas 99 | `0` |
| Off-identity | `0` |
| `validation.is_valid` | `true` |
| `diagnostics.reference_profile_used` | `true` |
| `profile_confidence` | `high` |
| `source_count` | `4` |
| Themes | `boros_miracle_big_spells`, `topdeck_manipulation`, `opponent_turn_draw_rummage`, `spellslinger_copy_payoffs`, `token_burst_finishers`, `graveyard_flashback_recursion` |

## Avaliacao contra o reference profile

- PASS: exatamente um comandante Lorehold.
- PASS: Lorehold nao apareceu nas 99.
- PASS: total final 100.
- PASS: identidade de cor R/W ou colorless nos cards com `color_identity`
  exposto.
- PASS: diagnostics confirmam profile agregado usado de verdade.
- PASS WITH RISKS: a avaliacao visual no app e screenshots no SM A135M ficaram
  bloqueadas pela ausencia do device alvo.

## Comandos de validacao

```bash
git status --short
git fetch origin master --quiet
git pull --ff-only origin master
flutter devices --no-version-check
adb devices -l
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health/git_sha
cd app && flutter test test/features/decks/providers/deck_provider_test.dart --no-version-check
cd app && flutter analyze lib/features/decks test/features/decks integration_test/lorehold_commander_edition_android_runtime_test.dart --no-version-check
cd app && flutter test test/features/decks --no-version-check
```

Resultados desta rodada:

- `flutter analyze ...`: PASS, sem issues.
- `flutter test test/features/decks --no-version-check`: PASS, `+156`.

## Bloqueios e menor proxima acao

- **BLOCKED runtime fisico:** conectar/desbloquear o `SM A135M` serial
  `R58T300SREH` e repetir:

```bash
cd app
flutter test integration_test/lorehold_commander_edition_android_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

Para provar o fluxo de generate visual de ponta a ponta, usar o novo campo
`deck-generate-commander-field` com `Lorehold, the Historian` antes de tocar em
`deck-generate-submit-button`.
