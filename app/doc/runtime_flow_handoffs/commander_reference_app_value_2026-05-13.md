# Commander Reference app value runtime - 2026-05-13

## Resultado

**PASS** em 2026-05-13T17:28-03:00 contra backend publico.

## Fonte lida antes da validacao

- `server/doc/RELATORIO_COMMANDER_REFERENCE_SPRINT2_FINAL_2026-05-13.md`
- `server/doc/COMMANDER_REFERENCE_SPRINT2_TRACKER_2026-05-13.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`

## Repositorio/branch

- Branch: `master`
- Sync: `git fetch origin master` + `git pull --ff-only origin master` retornou `Already up to date`.
- Base local/publica no inicio: `0ac7fa9`.

## Device/backend

- Device primario: Android fisico `SM A135M`, id `R58T300SREH`, Android 14/API 34.
- `flutter devices`: listou `SM A135M (mobile) • R58T300SREH • android-arm • Android 14 (API 34)`.
- `adb devices -l`: listou `R58T300SREH device ... model:SM_A135M`.
- Fallback disponivel, nao usado: iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, Booted.
- Backend usado pelo app: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- `/health`: HTTP 200, `status=healthy`, `git_sha=0ac7fa972daed1c16850d0384976aaedee9978a5`.

## Comando runtime final

```bash
cd app
flutter test integration_test/commander_reference_app_value_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

Resultado final: `01:38 +1: All tests passed!`

## Fluxo provado

- Register pela UI com usuario QA descartavel; e-mail/senha/token nao foram persistidos.
- Login pela UI.
- Geracao Commander async com `commander_name`.
- Feedback inicial claro (`Pedido aceito`/preview) em menos de 1s por comandante; conclusao async em aproximadamente 5-6s por comandante.
- Preview antes de salvar validado.
- Save do deck.
- Deck Details aberto.
- `/decks/:id/validate` chamado pelo app/API e retornando valido.
- Scanner/camera/OCR nao usados.

## Evidencia por comandante

| Commander | Preview | Details | Validation | Main | Total | Commander fora das 99 | Off identity |
| --- | --- | --- | --- | ---: | ---: | --- | ---: |
| Prosper, Tome-Bound | PASS | PASS | PASS | 99 | 100 | PASS | 0 |
| Edgar Markov | PASS | PASS | PASS | 99 | 100 | PASS | 0 |
| Aesi, Tyrant of Gyre Strait | PASS | PASS | PASS | 99 | 100 | PASS | 0 |

Aesi foi retornado pelo backend com nome de face duplicada (`Aesi, Tyrant of Gyre Strait // Aesi, Tyrant of Gyre Strait`) no slot de comandante; o harness normaliza face matching para confirmar o comandante correto sem copiar decklist.

## Correcoes implementadas

- `DeckGenerateScreen` agora salva o comandante informado em `commander_name` como `is_commander=true` quando o backend nao retorna objeto `generated_deck.commander`, preservando o comandante fora das 99 e mantendo compatibilidade com respostas antigas.
- O harness `commander_reference_app_value_runtime_test.dart` cobre Prosper, Edgar e Aesi com provas de preview/save/details/validate e normaliza nomes split `//` para comandantes faceados.

## Artefatos sanitizados

- Diretorio: `app/doc/runtime_flow_proofs_2026-05-13_commander_reference_app_value/`
- Log sanitizado: `sanitized_runtime_log_summary.md`
- Captures emitidos pelo teste foram indexados por nome/bytes; o stream bruto completo nao foi persistido para evitar e-mail, tokens ou decklists completas.

## Comandos de validacao

- `flutter analyze lib/features/decks test/features/decks integration_test --no-version-check`: PASS.
- `flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check`: PASS.
- Runtime Android final acima: PASS.

## Falhas intermediarias e menor acao tomada

- Primeira tentativa abriu Aesi Details, mas o harness aguardava texto visivel do comandante e falhou por seletor visual fragil; menor acao: validar details aberto por titulo e confirmar comandante/contagens via API sanitizada.
- Tentativas seguintes revelaram Aesi salvo/retornado com nome de face duplicada no comandante; menor acao: normalizar face matching no harness.
- Foi tambem aplicada protecao app-side para salvar o `commander_name` selecionado como comandante quando `generated_deck.commander` vier ausente.

## Riscos

- Prova depende do backend publico em producao; latencias lentas ocasionais foram observadas em endpoints auxiliares, mas sem timeout, raw error, overflow ou modal preso.
- Captures brutos nao foram persistidos como PNG para evitar vazamento acidental de dados; o log salvo e somente o resumo sanitizado.
