# Commander Reference Profile v1 - Lorehold

Data: 2026-05-11

Resultado: **PASS WITH RISKS**

## Escopo

- Implementar piloto local-first para guiar `POST /ai/generate` apenas quando
  `commander_name = Lorehold, the Historian`.
- Usar o relatorio `docs/qa/lorehold_reference_profile_2026-05-11.md` como fonte
  agregada, sem scraping pesado e sem copiar listas publicas.
- Manter compatibilidade: apps que omitem `commander_name` continuam no fluxo
  legado.
- Fora de escopo: Scanner/camera/OCR/MLKit e runtime mobile visual.

## Commit inspecionado

- Base inicial: `7c4a298652661554c2111380185d05cc825e466d`

## Implementacao

- Novo suporte: `server/lib/ai/commander_reference_profile_support.dart`.
- Novo runner: `server/bin/commander_reference_profile_lorehold.dart`.
- Integracao: `server/routes/ai/generate/index.dart`.
- Testes:
  - `server/test/commander_reference_profile_support_test.dart`
  - `server/test/commander_reference_profile_generate_live_test.dart`
  - `server/test/ai_generate_performance_support_test.dart`
- Contrato/documentacao:
  - `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  - `server/manual-de-instrucao.md`
  - `app/doc/APP_AUDIT_2026-04-29.md`

## Persistencia e tabelas

O runner auditou as tabelas antes de qualquer criacao/mutacao:

| Tabela | Existe |
| --- | --- |
| `commander_reference_profiles` | sim |
| `commander_card_synergy` | sim |
| `card_role_scores` | sim |
| `card_function_tags` | sim |

`--apply` persistiu o profile Lorehold em `commander_reference_profiles` com:

- `source = aggregate_reference_profile_v1`
- `deck_count = 0` porque o profile e agregado, nao uma contagem de decklists
  copiadas.
- `profile_json.confidence = high`
- `profile_json.source_count = 4`
- `profile_json.version = lorehold_reference_profile_v1_2026-05-11`

Artefatos sanitizados:

- `server/test/artifacts/commander_reference_profile_lorehold_2026-05-11/summary_dry_run.json`
- `server/test/artifacts/commander_reference_profile_lorehold_2026-05-11/summary_apply.json`
- `server/test/artifacts/commander_reference_profile_lorehold_2026-05-11/generate_local_summary.json`

## Contrato de `/ai/generate`

Campo novo opcional:

```json
{
  "prompt": "...",
  "format": "Commander",
  "commander_name": "Lorehold, the Historian"
}
```

Regras:

- O profile so ativa para nome exato normalizado `Lorehold, the Historian`.
- O profile so ativa se `confidence >= medium`.
- Outros comandantes e requests sem `commander_name` mantem o fluxo legado.
- O cache inclui `commander_name` e versao do profile somente quando o profile e
  usado.

Diagnosticos opcionais quando ativo:

```json
{
  "diagnostics": {
    "reference_profile_used": true,
    "reference_profile_source": "aggregate_reference_profile_v1",
    "reference_profile_version": "lorehold_reference_profile_v1_2026-05-11",
    "profile_confidence": "high",
    "themes": ["boros_miracle_big_spells"],
    "source_count": 4
  }
}
```

## Comparativo antes/depois

| Item | Antes | Depois Lorehold profile |
| --- | --- | --- |
| Comandante | Escolhido pelo prompt/IA; nao fixado | Fixado como `Lorehold, the Historian` |
| Identidade | Validada depois, mas sem guia especifico | Guia R/W antes da selecao + validacao final |
| Total | Validacao/reparo generico | Validacao final exige 100 cartas |
| Lands | Heuristica generica Commander | Meta 36-38 |
| Ramp | Heuristica generica | Meta 10-13 mana rocks/treasure |
| Draw/setup | Generico | 8-12 draw/rummage e 6-9 topdeck/miracle setup |
| Removal | Generico | 4-6 spot + 3-5 wipes/resets |
| Protection | Generico | Pacote de suporte, sem substituir legalidade |
| Payoffs | Generico | 10-16 haymakers miracle + 5-8 copy/spell payoffs |
| Off-theme | Possivel por heuristica generica | Evita azul, cEDH nao provado, banned fast mana e haymakers sem role |

Resumo local sanitizado de generate:

| Evidencia | Valor |
| --- | --- |
| HTTP | 200 |
| Commander | `Lorehold, the Historian` |
| Total incluindo commander | 100 |
| `validation.is_valid` | true |
| `diagnostics.reference_profile_used` | true |
| `profile_confidence` | high |
| `source_count` | 4 |
| Lands nomeados | 37 |
| Ramp nomeado | 11 |
| Draw/setup nomeado | 14 |
| Removal/wipes nomeados | 9 |
| Protection nomeada | 4 |
| Payoffs nomeados | 21 |
| Classificacao on-theme/generic/questionable/off-theme | 35 / 24 / 0 / 0 |

## Comandos executados

| Comando | Resultado |
| --- | --- |
| `git status`, `git fetch origin master` | PASS |
| `dart analyze lib/ai/commander_reference_profile_support.dart lib/ai_generate_performance_support.dart routes/ai/generate/index.dart bin/commander_reference_profile_lorehold.dart test/commander_reference_profile_support_test.dart test/ai_generate_performance_support_test.dart` | PASS |
| `dart test test/commander_reference_profile_support_test.dart test/ai_generate_performance_support_test.dart` | PASS |
| `dart run bin/commander_reference_profile_lorehold.dart --dry-run` | PASS WITH RISKS; sem mutacao |
| `dart run bin/commander_reference_profile_lorehold.dart --apply` | PASS; profile persistido |
| `RUN_LOREHOLD_REFERENCE_PROFILE_LIVE=1 TEST_API_BASE_URL=http://127.0.0.1:18082 dart test test/commander_reference_profile_generate_live_test.dart` | PASS |
| `dart analyze lib/ai routes/ai bin test` | PASS |
| `dart test test/commander_reference_profile_support_test.dart test/ai_generate_performance_support_test.dart test/generated_deck_validation_service_test.dart` | PASS |
| `dart test` | PASS, 584 tests |
| `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/decks_crud_test.dart` com servidor local temporario | PASS, 2 skips por falta de cartas de amostra |
| Sanity `/health` no backend publico informado | PASS |

Observacao: uma tentativa inicial de `decks_crud_test.dart` sem backend em
`127.0.0.1:8082` falhou por `connection refused`; o teste foi repetido com
servidor local temporario e passou.

## Riscos

- **PASS WITH RISKS** porque o backend publico foi usado apenas para sanity de
  `/health`; a feature ainda precisa ser publicada para prova no ambiente
  publico.
- O app atual nao envia `commander_name`; consumo mobile do profile depende de
  uma futura superficie/parametro de geracao.
- O profile e piloto Lorehold-only; outros comandantes continuam sem profile
  dedicado por design.

## Menores proximos ajustes

1. Expor selecao de comandante no fluxo mobile de generate quando o produto
   decidir consumir profiles.
2. Adicionar runtime mobile apenas depois que o app enviar `commander_name`.
3. Criar novos profiles somente com o mesmo padrao: evidencia agregada,
   confidence gate, legalidade local e sem copia de decklist.
