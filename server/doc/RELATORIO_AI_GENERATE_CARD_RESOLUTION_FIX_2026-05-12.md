# AI Generate Card Resolution Fix - 2026-05-12

## Resultado final complementar - matriz publica 8/8

**PASS complementar.** A matriz publica completa dos 8 Commander Reference
Profiles Strixhaven lot2 foi reexecutada apos o commit
`1dcf7ff31832d5fa9a6e53009a9e8caaf92d4701` e fechou `8/8` com `HTTP 200`,
comandante preservado, `main_quantity=99`, `validation.is_valid=true`,
`reference_profile_used=true` e `reference_card_stats_used=true`.

Esta rodada confirma que o reparo de resolucao de card desbloqueou nao apenas a
amostra Aziza/Excava/Zaffai, mas todos os 8 comandantes do lote:

| Commander | `/cards` exact | HTTP | Commander preservado | Main qty | Validation | Profile/stats | On-theme | Fallback/warning |
| --- | ---: | ---: | --- | ---: | --- | --- | ---: | --- |
| Aziza, Mage Tower Captain | 2 | 200 | true | 99 | true | true / true | 46 | `validation_warnings` |
| Berta, Wise Extrapolator | 2 | 200 | true | 99 | true | true / true | 44 | `validation_warnings` |
| Excava, the Risen Past | 1 | 200 | true | 99 | true | true / true | 44 | `openai_timeout_deterministic_fallback` |
| Gorma, the Gullet | 1 | 200 | true | 99 | true | true / true | 44 | `validation_warnings` |
| Muddle, the Ever-Changing | 1 | 200 | true | 99 | true | true / true | 45 | `openai_timeout_deterministic_fallback` |
| Primo, the Unbounded | 1 | 200 | true | 99 | true | true / true | 43 | `validation_warnings` |
| Scriv, the Obligator | 1 | 200 | true | 99 | true | true / true | 39 | `validation_warnings` |
| Zaffai and the Tempests | 2 | 200 | true | 99 | true | true / true | 52 | `validation_warnings` |

Excava e Muddle foram repetidos por terem acionado timeout/fallback na amostra
primaria; as repeticoes tambem retornaram deck valido, comandante preservado e
main 99. Os invalid cards observados foram removidos com seguranca antes da
validacao final e ficaram no bucket sanitizado `unresolved_or_not_in_public_db`.
Nenhum 422, 5xx, auth/deploy blocker ou drift de contrato app-facing foi
observado.

## Resultado

**PASS.** Os 422 publicos da amostra Strixhaven lot2 foram desbloqueados sem
aliases perigosos: os 8 comandantes faltantes foram resolvidos por nome exato via
`POST /cards/resolve`, passaram a existir em `GET /cards`, e 3 probes
sanitizados de `/ai/generate` retornaram `200`, `validation.is_valid=true`,
comandante preservado e `main_quantity=99`.

Full matrix 12/12 nao foi reexecutada nesta rodada; a evidencia runtime cobre
Aziza, Excava e Zaffai, incluindo os casos prioritarios de SOS/SOC.

## Escopo e sanitizacao

- Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Branch alvo: `master` em `5cc92a3`.
- Nenhum token, JWT, senha, prompt completo, decklist completa, `DATABASE_URL`,
  Sentry DSN, `OPENAI_API_KEY` ou segredo foi registrado.
- Scanner/camera/OCR fora do escopo.

## Lista sanitizada de nomes com `total_returned=0`

Os artifacts existentes do lote 2 nao gravaram os nomes internos de cartas
invalidas retornadas pela IA; eles gravaram somente contagens e a disponibilidade
dos comandantes. A lista sanitizada extraida de
`public_card_availability.json` e do relatorio runtime e:

| Nome | Bucket | Causa | Correcao |
| --- | --- | --- | --- |
| Aziza, Mage Tower Captain | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |
| Berta, Wise Extrapolator | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |
| Excava, the Risen Past | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |
| Gorma, the Gullet | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |
| Muddle, the Ever-Changing | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |
| Primo, the Unbounded | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |
| Scriv, the Obligator | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |
| Zaffai and the Tempests | Carta real ausente no DB publico | Set SOS/SOC novo nao sincronizado no publico | `/cards/resolve` exact -> Scryfall |

Buckets descartados para estes 8 nomes: alucinacao, acento/pontuacao, face
split, alias/fuzzy inseguro, token/variant e legalidade Commander. A checagem
Scryfall exact confirmou os 8 como cards reais, sets `sos`/`soc`, legalidade
Commander `legal`.

## Diagnostico tecnico

- `/ai/generate` forca o comandante do reference profile antes da validacao.
- `GeneratedDeckValidationService` resolve nomes por
  `resolveImportCardNames`, que e DB-only e correto para nao amplificar
  alucinacoes da IA.
- O fallback deterministico para `referenceProfile` tambem usa o comandante do
  profile e valida DB-only.
- O bug claro era no fluxo operacional de profile: `commander_reference_profile.dart`
  validava packages e off-color, mas nao bloqueava `--apply` quando o proprio
  comandante do profile nao resolvia em `cards`.
- Nao houve alteracao de contrato app-facing. `API_CONTRACTS_AND_DATA_MAP.md`
  permanece atual.

## Mudancas de codigo

- `server/lib/ai/commander_reference_card_stats_support.dart`
  - adiciona resolucao DB-only do card do comandante do profile;
  - exige match exato normalizado, sem aceitar fuzzy/alias para outro card;
  - expoe `commander_card_resolution` sanitizado para reports.
- `server/bin/commander_reference_profile.dart`
  - inclui `commander_card_resolution` no summary;
  - bloqueia `--apply` quando o comandante nao resolve em `cards`;
  - adiciona override explicito `--allow-unresolved-commander` apenas para
    curadoria pre-release nao runtime-ready.
- `server/test/commander_reference_card_stats_support_test.dart`
  - cobre match exato de comandante e rejeicao de match incorreto como
    `Zaffai, Thunder Conductor` para `Zaffai and the Tempests`.

## DB changes

Mutacao publica nao destrutiva e idempotente via rota existente
`POST /cards/resolve`, apos dry-run de disponibilidade em `/cards`.

| Commander | Antes `/cards` | Resolve status/source | Match exato | Depois `/cards` |
| --- | ---: | --- | --- | ---: |
| Aziza, Mage Tower Captain | 0 | 200 / scryfall | true | 2 |
| Berta, Wise Extrapolator | 0 | 200 / scryfall | true | 2 |
| Excava, the Risen Past | 0 | 200 / scryfall | true | 1 |
| Gorma, the Gullet | 0 | 200 / scryfall | true | 1 |
| Muddle, the Ever-Changing | 0 | 200 / scryfall | true | 1 |
| Primo, the Unbounded | 0 | 200 / scryfall | true | 1 |
| Scriv, the Obligator | 0 | 200 / scryfall | true | 1 |
| Zaffai and the Tempests | 0 | 200 / scryfall | true | 2 |

Rollback pratico: a operacao e additive/idempotente (`cards` por
`scryfall_id`, legalities por `card_id/format`) e os cards sao oficiais; nao foi
necessario remover dados. Se algum registro precisasse ser revertido, a remocao
deveria ser feita por `scryfall_id` dos printings inseridos, apos relatorio
pre-delete.

## Probes publicos sanitizados

| Commander | HTTP | Commander preservado | Main qty | Validation | Profile | Stats | On-theme | Invalid count | Fallback |
| --- | ---: | --- | ---: | --- | --- | --- | ---: | ---: | --- |
| Aziza, Mage Tower Captain | 200 | true | 99 | true | true | true | 46 | 1 | false |
| Excava, the Risen Past | 200 | true | 99 | true | true | true | 44 | 0 | false |
| Zaffai and the Tempests | 200 | true | 99 | true | true | true | 52 | 0 | false |

Aziza ainda teve 1 nome gerado removido com seguranca, mas o deck final ficou
valido, 100 cartas totais e comandante preservado.

## Probes locais em 8082

| Commander | `/cards` depois | HTTP | Commander preservado | Main qty | Validation | Profile | Stats | Fallback |
| --- | ---: | ---: | --- | ---: | --- | --- | --- | --- |
| Aziza, Mage Tower Captain | 2 | 200 | true | 99 | true | true | true | timeout deterministic |
| Excava, the Risen Past | 1 | 200 | true | 99 | true | true | true | false |
| Zaffai and the Tempests | 2 | 200 | true | 99 | true | true | true | false |

## Comandos executados

```bash
git fetch origin master --quiet
git status --short --branch
curl -sS 'https://evolution-cartinhas.8ktevp.easypanel.host/cards?name=<commander>&limit=5&page=1'
curl -sS https://api.scryfall.com/cards/named?exact=<commander>
python3 <sanitized public /cards/resolve exact runner>
python3 <sanitized public ai/generate probe runner>
cd server && dart format lib/ai/commander_reference_card_stats_support.dart bin/commander_reference_profile.dart test/commander_reference_card_stats_support_test.dart
cd server && dart analyze lib routes test
cd server && dart test test/generated_deck_validation_service_test.dart test/cards_route_test.dart test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_generate_live_test.dart -r expanded
cd server && dart run bin/commander_reference_profile.dart --profile-json=test/artifacts/commander_reference_profile_strixhaven_lot2_2026-05-11/profiles/aziza_mage_tower_captain.json --dry-run --artifact-dir=test/artifacts/commander_reference_profile_strixhaven_lot2_resolution_fix_2026-05-12
cd server && PORT=8082 dart run .dart_frog/server.dart
curl -fsS http://127.0.0.1:8082/health
curl -fsS http://127.0.0.1:8082/health/ready
python3 <sanitized local ai/generate probe runner>
```

## Validacao

- `dart analyze lib routes test`: PASS.
- Testes focados: PASS, `20 passed`, `1 skipped` live-gated.
- Dry-run do runner atualizado para Aziza: PASS_WITH_RISKS sem mutacao,
  `commander_card_resolved=true`, `resolved_count=46`, `unresolved_count=0`,
  `off_color_count=0`; artifact em
  `server/test/artifacts/commander_reference_profile_strixhaven_lot2_resolution_fix_2026-05-12/aziza_mage_tower_captain_dry_run_summary.json`.
- Backend local 8082: `/health` healthy e `/health/ready` ready com
  `cards_data.card_count=33791`.
- Public runtime amostra: 3/3 `status=200`, `validation.is_valid=true`,
  comandante preservado e `main_quantity=99`.

## Pendencias / riscos

- Full matrix publica 12/12 do relatorio original nao foi reexecutada nesta
  rodada.
- A causa operacional maior permanece: o refresh oficial de sets novos deve ser
  rodado no ambiente publico para evitar que outros cards SOS/SOC fiquem
  dependentes de self-healing pontual via `/cards/resolve`.
