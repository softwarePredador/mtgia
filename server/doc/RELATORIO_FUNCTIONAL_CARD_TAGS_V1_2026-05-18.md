# Functional Card Tags v1 - 2026-05-18

## Verdict

**PASS_WITH_RISKS** para backend local no commit inspecionado `086778c`.

Sem runtime mobile, scanner, camera ou OCR. Nenhum secret, token, JWT, DSN, DATABASE_URL,
OPENAI_API_KEY, e-mail QA completo ou decklist completa foi registrado.

## Commits inspecionados

- `086778c43c3331739d6c02f7d4ac3caa35f029d7` - baseline local antes deste patch.

## O que foi auditado

Antes do patch, Deck Analysis calculava buckets funcionais com buscas diretas em
`oracle_text`:

- `GET /decks/:id/analysis`: contava ramp por `add {`, busca de terreno, treasure e
  `put a land card from your hand`; draw só por `draw a card`/`draw cards`; removal por
  `destroy target`/`exile target`/dano em alvo; wipes por `destroy all`/`exile all`.
- `POST /decks/:id/ai-analysis`: tinha outra variação, com `draw && card`, proteção
  simples e sem explicabilidade por carta.
- Optimize candidate quality tinha `card_function_tags`, mas com vocabulário menor e
  aliases antigos como `token`, `aristocrats`, `graveyard` e `sacrifice`.

Cartas ficavam fora da contagem quando usavam textos como `draw two cards`, blink que mira
criatura própria, recursion, aristocrats/drain, token maker, spellslinger, exile-value ou
big-turn. Também havia falso positivo: blink/proteção com `exile target creature you
control` podia ser contado como removal. Em `/decks/:id/analysis`, `totalCards` era somado
duas vezes por linha.

## Implementação

- Criado `server/lib/ai/functional_card_tags.dart`.
- Tags v1 determinísticas: `land`, `ramp`, `ritual`, `draw`, `loot`, `tutor`,
  `removal`, `board_wipe`, `protection`, `recursion`, `token_maker`,
  `sacrifice_outlet`, `aristocrat_payoff`, `lifegain`, `drain`, `spellslinger`,
  `artifact_synergy`, `enchantment_synergy`, `graveyard_synergy`, `etb`, `blink`,
  `big_spell`, `exile_value`.
- `FunctionalDeckSummary` retorna `counts`, `samples` limitados e `coverage`
  (`tagged`/`other`) para explicabilidade sem full decklist.
- `GET /decks/:id/analysis` passou a:
  - filtrar o deck por `user_id`;
  - corrigir `total_cards` duplicado;
  - manter `stats.composition` e adicionar `protection`;
  - retornar `functional_tags` opcional.
- `POST /decks/:id/ai-analysis` passou a usar a mesma camada para os counts enviados ao
  heurístico/IA e adiciona `metrics.functional_tags`.
- `candidate_quality_data_support.dart` agora consome o inferer v1 e mantém aliases antigos
  para não quebrar Optimize nem dados persistidos em `card_function_tags`.

## Prova sanitizada em 3 comandantes

Prova executada em fatias sanitizadas, sem decklists completas:

| Comandante/slice | Legacy other rows | V1 other rows | Ganhos principais |
|---|---:|---:|---|
| Lorehold | 4 | 1 | Skullclamp entra em draw; Ephemerate vira blink/protection e deixa de ser removal; Young Pyromancer entra em token_maker/spellslinger; Jeska's Will ganha ritual/big_spell/exile_value. |
| Dina | 6 | 0 | Blood Artist entra em aristocrat_payoff/drain/lifegain; Reanimate entra em recursion/graveyard; Village Rites entra em draw; Essence Warden em lifegain. |
| Feather | 3 | 1 | Feather/Young Pyromancer entram em spellslinger; Ephemerate/Gods Willing em protection/blink; Jeska's Will em ritual/big_spell/exile_value. |

Falso positivo conhecido reduzido: efeitos que miram `target creature you control` nao contam
como removal apenas por conter `exile target`.

## Contrato/API

Campos existentes foram preservados. Campos aditivos:

- `GET /decks/:id/analysis`: `functional_tags.{schema_version,counts,samples,coverage}` e
  `stats.composition.protection`.
- `POST /decks/:id/ai-analysis`: `metrics.functional_tags`.

`server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi atualizado.

## Comandos executados

```bash
cd server && dart format lib/ai/functional_card_tags.dart lib/ai/candidate_quality_data_support.dart routes/decks/[id]/analysis/index.dart routes/decks/[id]/ai-analysis/index.dart test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart
cd server && dart analyze lib/ai/functional_card_tags.dart lib/ai/candidate_quality_data_support.dart routes/decks/[id]/analysis/index.dart routes/decks/[id]/ai-analysis/index.dart test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart
cd server && dart test test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart -r expanded
cd server && dart analyze test/functional_card_tags_commander_probe_test.dart
cd server && dart test test/functional_card_tags_test.dart test/functional_card_tags_commander_probe_test.dart -r expanded
cd server && dart analyze lib/ai routes/ai bin test
cd server && dart test test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart test/external_commander_meta_promotion_support_test.dart test/functional_card_tags_test.dart test/functional_card_tags_commander_probe_test.dart test/candidate_quality_data_support_test.dart -r expanded
cd server && RUN_INTEGRATION_TESTS=0 dart test test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/optimize_complete_support_test.dart test/external_commander_meta_promotion_support_test.dart test/functional_card_tags_test.dart test/functional_card_tags_commander_probe_test.dart test/candidate_quality_data_support_test.dart -r expanded
cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run
cd server && PORT=8080 dart run .dart_frog/server.dart
cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run
git --no-pager diff --check
grep -RInE "<secret-value-patterns>" <changed-files>
```

## Pass/fail

- Functional tag unit tests: PASS.
- Candidate quality compatibility tests: PASS.
- Commander proof slices: PASS.
- Focused analyzer on touched backend files: PASS.
- `dart analyze lib/ai routes/ai bin test`: PASS.
- Required optimize-focused tests: PASS with `RUN_INTEGRATION_TESTS=0`; first raw run failed only because `ai_optimize_flow_test.dart` is tagged live and no local server was listening on `127.0.0.1:8082`.
- Commander-only dry-run: first attempt failed because no backend was listening on `127.0.0.1:8080`; after starting a temporary local backend with `PORT=8080`, dry-run PASS with 19 candidates enumerated and no optimize/apply mutation.
- `git diff --check`: PASS.
- Simple secret scan: PASS_WITH_RISKS; matches were environment variable names, redaction labels and pre-existing example emails in docs, not secret values.

## Riscos e limites

- A camada e as provas sao deterministicas; nao houve runtime mobile nem prova live com backend
  publico nesta rodada.
- As heuristicas ainda podem produzir falsos positivos em textos raros de MTG. A mitigacao foi
  adicionar negativas focadas para owner-target blink e ETB hate, e manter confidence/evidence
  para ajustes futuros.
- `card_function_tags` persistido pode conter fontes antigas; este patch nao remove rows antigas.
  O runtime preserva aliases para compatibilidade. Uma future backfill job pode recalcular tudo
  com `source=deterministic_functional_tags_v1`.

## Menores proximos fixes

1. Criar backfill idempotente para popular `card_function_tags` com `functional_card_tags_v1`.
2. Ampliar fixtures negativas para Howling Mine, Torpor Orb/Hushwing-like, sacrifice-as-cost e
   cards simetricos de draw.
3. Rodar prova live em decks reais sanitizados quando houver janela segura de backend publico.
