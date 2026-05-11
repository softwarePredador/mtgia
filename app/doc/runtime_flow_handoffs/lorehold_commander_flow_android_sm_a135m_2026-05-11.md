# Lorehold Commander flow Android SM A135M handoff - 2026-05-11

## Resultado

**BLOCKED** para runtime no device fisico alvo. **PASS WITH RISKS** para
contrato app/backend e prova publica sanitizada do Commander Reference Profile
v1.

## Data/hora

- 2026-05-11 12:25 BRT, rodada iniciada nesta sessao.

## Device discovery

Device alvo esperado:

- Modelo: `SM A135M`
- Serial: `R58T300SREH`

Descoberta observada:

- Primeira listagem Flutter mostrou Android `24117RN76L`
  (`g6nbaqugcij7yp9x`, Android 15), que nao e o device alvo.
- Nova listagem posterior nao mostrou nenhum Android em `flutter devices`.
- `adb devices -l` ficou vazio.
- `adb -s R58T300SREH get-state` retornou `device 'R58T300SREH' not found`.
- iPhone 15 Simulator disponivel: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`,
  iOS 17.4, mas nao e o target desta tarefa.

## Backend

- URL usada pelo app/API: `https://evolution-cartinhas.8ktevp.easypanel.host`
- `/health`: `200`, `status=healthy`,
  `git_sha=87d9b7c3814ea07c3e89d718976fb694efd57d1d`
- `/health/git_sha`: `404`; o SHA foi confirmado pelo payload de `/health`.

## Comandos executados

```bash
git status --short
git fetch origin master --quiet
git pull --ff-only origin master
flutter devices --no-version-check
adb devices -l
adb -s R58T300SREH get-state
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health/git_sha
cd app && flutter analyze lib/features/decks test/features/decks integration_test/lorehold_commander_edition_android_runtime_test.dart --no-version-check
cd app && flutter test test/features/decks --no-version-check
```

Prova publica sanitizada executada por script local com usuario QA descartavel:

```bash
POST /auth/register
POST /ai/generate {
  "prompt": "Deck Commander Boros miracle big spells with topdeck setup and fair interaction.",
  "format": "commander",
  "commander_name": "Lorehold, the Historian",
  "async": true
}
GET <poll_url> ate completed
```

## Resultado da prova publica

| Criterio | Resultado |
| --- | --- |
| Generate inicial | `202` |
| Polling | `processing`, depois `completed` |
| Commander | `Lorehold, the Historian` |
| Total com comandante | `100` |
| Lorehold nas 99 | `0` |
| Off-identity count | `0` |
| `validation.is_valid` | `true` |
| `diagnostics.reference_profile_used` | `true` |
| `profile_confidence` | `high` |
| `source_count` | `4` |

Validacao local focada:

- `flutter analyze ...`: PASS, sem issues.
- `flutter test test/features/decks --no-version-check`: PASS, `+156`.

## O que foi real, mockado e nao provado

- Real: backend publico, auth QA descartavel, `/ai/generate` async, polling,
  validacao de diagnostics e resumo estrutural do deck.
- Real no app source: campo `deck-generate-commander-field`, payload provider
  async/sync fallback e testes focados.
- Mockado: nada na prova publica de backend; testes unit/widget usam fake
  `ApiClient` por design.
- Nao provado: UI visual no `SM A135M` / `R58T300SREH`, screenshots, abrir Deck
  Details no device, salvar deck gerado pelo app e validar no device.

## Arquivos alterados

- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/lib/features/decks/providers/deck_provider.dart`
- `app/lib/features/decks/providers/deck_provider_support_generation.dart`
- `app/test/features/decks/providers/deck_provider_test.dart`
- `app/test/features/decks/screens/deck_runtime_widget_flow_test.dart`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `docs/qa/manaloom_lorehold_commander_flow_2026-05-11.md`

## Menor proxima acao

Conectar/desbloquear o `SM A135M` serial `R58T300SREH` e repetir o runtime
Android contra o backend publico. O fluxo visual deve preencher
`deck-generate-commander-field` com `Lorehold, the Historian`, gerar, salvar,
abrir Deck Details e confirmar comandante unico, Lorehold ausente das 99,
identidade R/W, total 100/legalidade e diagnostics quando expostos.
