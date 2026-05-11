# Commander Reference Profiles — Secrets of Strixhaven — 2026-05-11

## Resultado

**PASS WITH RISKS.** Os 10 Commander Reference Profiles v1 curados para o lote 1 de Secrets of Strixhaven foram validados em dry-run, aplicados no banco remoto e provados por probes sanitizados de `/ai/generate`.

Risco aceito: a curadoria original marcou o lote como **PASS WITH RISKS** porque a evidencia publica para comandantes novos ainda e fina e nao prova relevancia cEDH. Os profiles foram tratados como referencias agregadas de Commander casual/funcional, nao como shell competitivo obrigatorio.

## Commits inspecionados

- `cad71230e4f27b06b54e66f7238d9ec6bb8703b2` — `docs: add secrets of strixhaven commander profiles`.

## Profiles aplicados

| Commander | Resolved | Unresolved | Off-color | Loaded usable after apply |
|---|---:|---:|---:|---:|
| Dina, Essence Brewer | 39 | 0 | 0 | 39 |
| Killian, Decisive Mentor | 38 | 0 | 0 | 38 |
| Lorehold, the Historian | 34 | 0 | 0 | 34 |
| Prismari, the Inspiration | 38 | 0 | 0 | 38 |
| Quandrix, the Proof | 39 | 0 | 0 | 39 |
| Quintorius, History Chaser | 39 | 0 | 0 | 39 |
| Rootha, Mastering the Moment | 39 | 0 | 0 | 39 |
| Silverquill, the Disputant | 34 | 0 | 0 | 34 |
| Witherbloom, the Balancer | 38 | 0 | 0 | 38 |
| Zimone, Infinite Analyst | 42 | 0 | 0 | 42 |

## Mudanca pequena aplicada durante a auditoria

O runner generico `server/bin/commander_reference_profile.dart` agora registra `off_color_count` e `off_color_reference_cards` no summary e bloqueia `--apply` quando uma carta resolvida fica fora da identidade de cor do comandante. O suporte ganhou `findOffColorCommanderReferenceCards` e teste focado em `commander_reference_card_stats_support_test.dart`.

## Probes sanitizados de `/ai/generate`

Backend local: `http://127.0.0.1:8082`. Usuario QA descartavel registrado localmente; token/JWT e payload completo nao foram registrados.

| Commander | HTTP | Profile | Card stats | On-theme candidates | Deck total | Commander unico | Off-identity | Validation | Cache | Mock | Total ms |
|---|---:|---|---|---:|---:|---|---:|---|---|---|---:|
| Lorehold, the Historian | 200 | true | true | 34 | 100 | true | 0 | true | false | true | 12640 |
| Dina, Essence Brewer | 200 | true | true | 39 | 100 | true | 0 | true | false | true | 13705 |
| Zimone, Infinite Analyst | 200 | true | true | 42 | 100 | true | 0 | true | false | false | 15367 |

Timing observado: `reference_profile_ms` ficou em ~1.1s nos tres probes; `openai_ms` concentrou ~7.6-8.0s; `validation_ms` apareceu no probe Zimone com ~6.0s. Lorehold e Dina cairam no fallback mock valido por timeout local de OpenAI; Zimone retornou resposta nao-mock valida.

Artifact sanitizado:

- `server/test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11_apply/generate_probes_summary.json`

## Comandos executados

```bash
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --dry-run --artifact-dir=test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11_apply
cd server && dart run bin/commander_reference_profile.dart --profile-json=<profile> --apply --artifact-dir=test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11_apply
cd server && dart analyze lib/ai routes/ai bin test
cd server && dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_generate_live_test.dart test/ai_generate_performance_support_test.dart -r expanded
cd app && flutter analyze lib/features/decks test/features/decks --no-version-check
cd app && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check
```

## Pass/fail summary

- Dry-run dos 10 profiles: **PASS**, todos com `unresolved=0` e `off_color=0`.
- Apply dos 10 profiles: **PASS**, todos carregando profile e card stats utilizaveis apos escrita.
- `dart analyze lib/ai routes/ai bin test`: **PASS**.
- Testes focados: **PASS**, com `commander_reference_profile_generate_live_test.dart` mantido skipado por flag de live externo.
- App deck contract checks: **PASS** para `flutter analyze lib/features/decks test/features/decks` e testes focados de Deck Details/Provider/Optimize flow support.
- Probes locais de `/ai/generate`: **PASS**, 3/3 com `reference_profile_used=true`, `reference_card_stats_used=true`, 100 cartas, comandante unico, 0 off-identity inferido por validacao final e `validation.is_valid=true`.

## Contrato app/backend

- `commander_name` continua opcional e backward-compatible.
- Apps antigos que omitem `commander_name` seguem no fluxo legado.
- Quando ha profile persistido com `confidence >= medium`, `/ai/generate` retorna diagnostics opcionais (`reference_profile_used`, `reference_card_stats_used`, `on_theme_candidate_count`, `unresolved_reference_cards`, `package_keys`, `reference_deck_evaluation` quando disponivel).
- `generated_deck` e `validation` seguem como fonte de verdade para preview/create/apply.

## Legalidade e identidade de cor

- O apply agora tem gate explicito contra off-color em resolved card stats.
- Os probes confirmaram deck final valido, 100 cartas e comandante unico para tres comandantes do lote.
- Unresolved ficou zerado em todos os packages aplicados; portanto nenhuma referencia unresolved entrou como guidance ativa.

## Sentry/logging

- O fluxo de runner nao emite payload sensivel e os artifacts gravam somente contagens, nomes de cartas/profile e cache hashes.
- `/ai/generate` ja registra indisponibilidade de Commander Reference Profile/Card Stats como warning e segue fallback legado; nenhum segredo/JWT foi documentado nos artifacts desta auditoria.

## Blockers

- Nenhum blocker para consumo backend/app do contrato.
- Risco de produto permanece: estes profiles nao provam cEDH e nao devem ser promovidos como meta competitivo.

## Menores proximos fixes

1. Expandir probes para Killian/Prismari/Quintorius quando houver janela de runtime maior.
2. Adicionar um teste live opcional parametrizavel para multiplos `commander_name`, reduzindo dependencia do teste Lorehold-only.
3. Considerar reduzir latencia de `reference_profile_ms` com cache DB leve se os probes mobile mostrarem impacto perceptivel.
