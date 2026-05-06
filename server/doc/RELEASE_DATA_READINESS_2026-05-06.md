# Release Data Readiness - 2026-05-06

## Resultado

**PASS WITH RISKS** para release interno de dados apos a base de candidate quality, meta signals e consumo pelo optimize.

Na rodada inicial nao houve `--apply`, migracao destrutiva, `UPDATE`, `DELETE` ou alteracao em dados source-of-truth. No follow-up de riscos nao bloqueantes foi aplicado somente um `DELETE` idempotente e guardado em metadata gerada (`card_role_scores`, `source='deterministic_heuristic_v1'`), apos dry-run com preview e limite `--max-prune=1`. Nao houve alteracao em `cards`, `sets`, `card_legalities`, legalidade Commander, identidade de cor, bracket, rotas app-facing, tokens, JWT, `DATABASE_URL`, prompts ou payloads sensiveis.

## Sincronizacao do branch

- Branch alvo: `master`.
- `git status --short --branch`: `## master...origin/master` antes da sincronizacao, sem arquivos modificados.
- `git fetch origin master`: PASS.
- `git pull --ff-only origin master`: PASS, `Already up to date`.
- Nao havia mudancas de usuario a preservar no inicio.

## Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia && git --no-pager status --short --branch && git --no-pager remote -v
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia && git fetch origin master && git --no-pager status --short --branch && git pull --ff-only origin master && git --no-pager status --short --branch
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/dry_run
cd server && dart run bin/mtg_data_integrity.dart --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/mtg_data_integrity_dry_run
cd server && dart run bin/candidate_quality_meta_signals.dart --dry-run --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/meta_signals_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/dry_run_idempotency_check
cd server && psql ... -c "<release readiness aggregate counts>"
cd server && dart analyze bin lib routes test
cd server && dart test test/candidate_quality_data_support_test.dart test/cards_route_test.dart test/sets_route_test.dart -r expanded
```

Observacao: as linhas de conexao DB impressas pelos helpers foram tratadas como configuracao operacional e nao sao reproduzidas aqui.

### Follow-up 13:22 - riscos nao bloqueantes

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia && git fetch origin master && git pull --ff-only origin master
cd server && dart run bin/mtg_data_integrity.dart --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_mtg_data_integrity_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --prune-stale-only --target=card_role_scores --max-prune=1 --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_prune_only
cd server && dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_post_prune_dry_run
cd server && dart run bin/candidate_quality_data_foundation.dart --prune-stale-only --target=card_role_scores --max-prune=1 --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_prune_idempotence
cd server && dart analyze bin lib routes/cards routes/sets test
cd server && dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart -r expanded
PORT=8082 dart run .dart_frog/server.dart
curl -sS 'http://127.0.0.1:8082/sets?code=soc&limit=10&page=1'
curl -sS 'http://127.0.0.1:8082/cards?set=SOC&limit=3&page=1'
curl -sS 'http://127.0.0.1:8082/cards?set=ECC&limit=3&page=1'
```

O helper de candidate quality agora grava `stale_generated_rows_preview.*` em dry-run e possui modo operacional explicito `--prune-stale-only --target=card_role_scores --max-prune=1`. Esse modo nao executa upserts e aborta se o conjunto stale mudar entre preview e transacao.

## Dry-run/apply

| Item | Resultado |
|---|---|
| `candidate_quality_data_foundation.dart` | `--dry-run`, sem mutacao |
| `candidate_quality_data_foundation.dart` follow-up | dry-run com preview, depois `--prune-stale-only --target=card_role_scores --max-prune=1` |
| `mtg_data_integrity.dart` | dry-run, sem `--apply-color-identity` |
| `candidate_quality_meta_signals.dart` | `--dry-run`, sem mutacao |
| DB mutations | `false` na rodada inicial; follow-up `true` somente para remover 1 row stale gerada em `card_role_scores` |
| Migrations destrutivas | Nao executadas |
| Alteracao em `cards`, `sets`, `card_legalities` | Nao executada |

## Candidate quality foundation

Fonte: dry-run inicial e repeticao de idempotencia.

| Metrica | Valor |
|---|---:|
| `cards` no banco | 33774 |
| cards canonicas escaneadas | 33312 |
| cards com tags planejadas | 20007 |
| cobertura de tags planejada | 60.06% |
| function tag rows planejadas | 33021 |
| role score rows planejadas | 30997 |
| commander synergy rows planejadas | 5000 |
| rejection penalty rows planejadas | 371 |
| sample candidate pools | 3 |

### Contagens principais atuais

| Objeto | Linhas |
|---|---:|
| `card_function_tags` | 33011 |
| `card_role_scores` | 31898 |
| `commander_card_synergy` | 7179 |
| `optimize_rejection_penalties` | 358 |
| `optimize_candidate_quality_summary` | 33774 |

### Idempotencia

O dry-run foi executado duas vezes. Em ambas as execucoes:

| Tabela | Pre | Post | Mutacao |
|---|---:|---:|---|
| `card_function_tags` | 33011 | 33011 | nao |
| `card_role_scores` | 31898 | 31898 | nao |
| `commander_card_synergy` | 7179 | 7179 | nao |
| `optimize_rejection_penalties` | 358 | 358 | nao |

Stale generated rows reportados em dry-run:

| Fonte/tabela | Stale rows |
|---|---:|
| `card_function_tags` | 0 |
| `card_role_scores` | 1 |
| `commander_card_synergy` | 0 |
| `optimize_rejection_penalties` | 0 |

Follow-up: o stale foi classificado como metadata gerada (`source='deterministic_heuristic_v1'`, role `ramp`, `format='commander'`, `bracket_scope='any'`) e podado com modo prune-only guardado. Contagens: `card_role_scores` 31.898 -> 31.897; demais tabelas de candidate quality inalteradas. Post dry-run: stale generated rows = 0 em todas as quatro tabelas. Reexecucao prune-only de idempotencia removeu 0 rows e `db_mutations=false`. A linha removida era advisory e nao alterava legalidade, identidade de cor ou bracket.

## MTG data integrity

| Checagem | Valor |
|---|---:|
| grupos duplicados `LOWER(sets.code)` | 82 |
| variantes duplicadas de `sets.code` | 164 |
| `cards.color_identity IS NULL` | 0 |
| null color identity em sets recentes/futuros | 0 |
| null color identity em sets futuros | 0 |
| candidatos deterministicos de backfill | 0 |
| unresolved color identity | 0 |
| linhas atualizadas | 0 |

Resultado: `cards.color_identity` esta pronta para os fluxos validados. A duplicidade case-insensitive de `sets.code` segue conhecida e nao foi saneada nesta rodada; rotas de cards/sets continuam cobertas pelos testes focados.

Follow-up: a duplicidade foi mantida como **backlog tecnico/query-level dedupe**. O dry-run atual mediu 82 grupos `LOWER(sets.code)` e 164 variantes. Variantes lowercase ainda sao referenciadas por `cards.set_code` (ex.: `10e`, `2x2`, `2xm`, `30a`, `8ed`), portanto a remocao fisica de `sets` ou normalizacao ampla de `cards.set_code` nao foi considerada segura para esta etapa de release. Sanity live confirmou `/sets?code=soc`, `/cards?set=SOC` e `/cards?set=ECC` com resposta 200 e dados deduplicados/case-insensitive.

## aggressive_meta_signal_v1

Fonte: `candidate_quality_meta_signals.dart --dry-run` e consulta agregada.

| Metrica | Valor |
|---|---:|
| source | `aggressive_meta_signal_v1` |
| `meta_decks` disponiveis | 650 |
| `external_commander_meta_candidates` disponiveis | 10 |
| `commander_reference_profiles` disponiveis | 18 |
| meta decks Commander/cEDH escaneados | 385 |
| candidatos externos confiaveis escaneados | 9 |
| reference profiles escaneados | 18 |
| commander signal rows planejadas | 2179 |
| role score rows planejadas | 910 |
| `commander_card_synergy` rows atuais com `source='aggressive_meta_signal_v1'` | 2179 |
| `card_role_scores` rows atuais com `source='aggressive_meta_signal_v1'` | 910 |
| stale generated rows antes de apply | 0 |

### Cobertura dos sinais

| Dimensao | Valor |
|---|---:|
| commander decks com identidade resolvida | 360 |
| commander decks com identidade desconhecida | 34 |
| commander decks com candidate signals | 360 |
| `competitive_commander` | 232 |
| `duel_commander` | 162 |

Principais identidades de cor cobertas: `UR` 34, `WUBRG` 28, `UBR` 25, `WUBR` 25, `UG` 23, `WUB` 18, `WUBG` 16.

Principais estrategias cobertas: `combo` 139, `control` 115, `aggro` 69, `ramp_value` 21, `tribal` 21, `midrange` 12, `aristocrats` 8.

Guardrails confirmados pelo summary:

- dry-run e default; apply exige `--apply`;
- writes de meta signal seriam apenas `source='aggressive_meta_signal_v1'`;
- candidatos exigem Commander legality `legal/restricted/null`;
- color identity do candidato deve ser subset da identidade resolvida do comandante;
- identidades desconhecidas ficam reportadas e nao persistidas;
- sinais sao advisory, nunca swaps forcados.

## Validacao

```bash
cd server && dart analyze bin lib routes test
```

Resultado: PASS.

```bash
cd server && dart test test/candidate_quality_data_support_test.dart test/cards_route_test.dart test/sets_route_test.dart -r expanded
```

Resultado: PASS, `+11`.

Live sanity em backend local `8082`:

| Endpoint | Resultado |
|---|---|
| `/sets?code=soc&limit=10&page=1` | PASS, 1 set canonico `SOC`, `card_count=12` |
| `/cards?set=SOC&limit=3&page=1` | PASS, dados retornados com join de set case-insensitive |
| `/cards?set=ECC&limit=3&page=1` | PASS, dados retornados com join de set case-insensitive |

## Code changes

- `server/bin/candidate_quality_data_foundation.dart`
  - adiciona preview auditavel `stale_generated_rows_preview.json/csv`;
  - adiciona modo `--prune-stale-only --target=card_role_scores --max-prune=N`;
  - prune-only nao executa upsert, revalida o mesmo conjunto stale dentro da transacao e grava `stale_generated_rows_pruned.json/csv`.
- Nao houve mudanca de runtime de rotas, query contract, legalidade, color identity, bracket ou schema app-facing.

## DB changes

Rodada inicial: nenhuma alteracao aplicada no banco. Follow-up: 1 row gerada e obsoleta em `card_role_scores` foi removida por `DELETE` idempotente/guardado, com `source='deterministic_heuristic_v1'`. Nenhuma alteracao em `cards`, `sets`, `card_legalities`, `decks`, `deck_cards`, rotas ou tabelas source-of-truth.

Rollback note: se for necessario restaurar exatamente a linha removida, usar o payload em `server/test/artifacts/release_data_readiness_2026-05-06/follow_up_candidate_quality_prune_only/stale_generated_rows_pruned.json` para reinserir a chave composta em `card_role_scores`. Restaurar nao e recomendado para operacao padrao porque a row nao aparece mais no plano deterministico atual.

## Contratos/API

Nao houve alteracao app-facing. `server/doc/API_CONTRACTS_AND_DATA_MAP.md` foi usado como contexto e nao precisou ser atualizado.

## Unresolved / not proven

| Item | Status |
|---|---|
| 82 grupos duplicados `LOWER(sets.code)` | risco conhecido; mantido em backlog tecnico com query-level dedupe provado |
| 1 stale generated row em `card_role_scores` no dry-run foundation | saneado por prune-only; post dry-run = 0 |
| human reviewed tags | not proven |
| AI-generated tags | not used |
| budget tier amplo | `unknown` segue predominante nas rows deterministic heuristic |
| event date freshness dos meta signals | not proven; usa `created_at`/`updated_at` local |
| `commander_reference_profiles` como prova cEDH | not proven; tratado so como enriquecimento |
| web interpretation no comando meta signals | not used |
| scanner fisico/camera/OCR | fora do escopo / not proven |

## Gaps e riscos

- Duplicate set-code cleanup ainda precisa de etapa propria; para este release interno, a readiness depende da compatibilidade de query ja coberta por `/sets`, `/cards` e sanity live.
- O stale count de `card_role_scores` foi saneado; manter o preview artifact como regressao operacional para futuras rodadas.
- Tags funcionais continuam heuristicas deterministicas com `source`/`confidence`, nao curadoria humana.
- Meta signals cobrem 360 shells/decks com identidade resolvida, mas 34 labels continuam sem identidade resolvida e nao entram na persistencia.

## Resultado final

**PASS WITH RISKS.**

Dados essenciais para release interno estao prontos: `cards.color_identity IS NULL = 0`, candidate quality tables/view existem com contagens estaveis, stale generated rows = 0 apos prune-only, meta signals aplicados estao presentes e os testes/analyzer obrigatorios passaram. O risco restante principal e a duplicidade case-insensitive de `sets.code`, mantida como backlog tecnico porque variantes ainda sao referenciadas por `cards.set_code`; esse risco nao envolve bypass de legalidade, identidade de cor, bracket ou quality gate.
