# Relatorio MTG Data Integrity - 2026-05-06

## Resultado

**PASS WITH RISKS.** O follow-up de release classificou os 82 grupos duplicados por casing em `sets.code` como backlog tecnico com compatibilidade preservada por query-level dedupe. Nenhuma mutacao foi aplicada em `sets`, `cards`, `card_legalities`, legalidade Commander, identidade de cor ou bracket.

## Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia && git fetch origin master && git pull --ff-only origin master
cd server && dart run bin/mtg_data_integrity.dart --artifact-dir=test/artifacts/release_data_readiness_2026-05-06/follow_up_mtg_data_integrity_dry_run
cd server && dart analyze bin lib routes/cards routes/sets test
cd server && dart test test/sets_route_test.dart test/cards_route_test.dart test/candidate_quality_data_support_test.dart -r expanded
PORT=8082 dart run .dart_frog/server.dart
curl -sS 'http://127.0.0.1:8082/sets?code=soc&limit=10&page=1'
curl -sS 'http://127.0.0.1:8082/cards?set=SOC&limit=3&page=1'
curl -sS 'http://127.0.0.1:8082/cards?set=ECC&limit=3&page=1'
```

Linhas de conexao DB foram tratadas como configuracao operacional e nao sao reproduzidas. Nenhum `DATABASE_URL`, JWT, token, prompt ou payload sensivel foi documentado.

## Dry-run/apply

| Item | Resultado |
|---|---|
| `mtg_data_integrity.dart` | dry-run |
| `--apply-color-identity` | nao usado |
| Mutacao em `cards`, `sets`, `card_legalities` | nao |
| Artefatos | `server/test/artifacts/release_data_readiness_2026-05-06/follow_up_mtg_data_integrity_dry_run/` |

## Duplicate set-code counts

| Metrica | Valor |
|---|---:|
| Grupos `LOWER(sets.code)` duplicados | 82 |
| Variantes duplicadas de `sets.code` | 164 |
| `cards.color_identity IS NULL` | 0 |
| Null color identity em sets recentes/futuros | 0 |
| Null color identity em sets futuros | 0 |
| Candidatos deterministicos de backfill | 0 |
| Unresolved color identity | 0 |

Artefatos principais:

- `duplicate_set_codes.csv/json`
- `duplicate_set_card_references.csv/json`
- `summary_dry_run.json/md`

## Impacto e decisao

Variantes com casing nao canonico ainda sao referenciadas por `cards.set_code`, por exemplo `10e`, `2x2`, `2xm`, `30a`, `8ed`, `blc`, `c13`, `c14`, `clb`, `cmm` e `cmr`. Por isso, remover linhas duplicadas em `sets` ou normalizar fisicamente `cards.set_code` nesta etapa seria uma migracao ampla e potencialmente destrutiva.

Decisao: manter o saneamento fisico como backlog tecnico e depender, para o release interno, do comportamento ja implementado:

- `/sets` particiona por `LOWER(code)` e escolhe uma linha canonica por `release_date`, casing uppercase e `name`;
- `/cards` filtra `set` com `LOWER(c.set_code) = LOWER(@set)` e deduplica por `(name, LOWER(set_code))`;
- `sync_cards.dart` ja normaliza novos `set_code` para uppercase e faz update case-insensitive de sets antes de inserir.

## Prova de endpoint

| Endpoint | Resultado |
|---|---|
| `/sets?code=soc&limit=10&page=1` | PASS, 1 set canonico `SOC`, `card_count=12` |
| `/cards?set=SOC&limit=3&page=1` | PASS, retorna cartas de `SOC` com join de set |
| `/cards?set=ECC&limit=3&page=1` | PASS, retorna cartas de `ECC` com join de set |

## Code changes

Nenhuma mudanca em rotas cards/sets, contratos ou sync foi necessaria nesta frente. O code change da rodada ficou restrito ao helper de candidate quality descrito no relatorio especifico.

## DB changes

Nenhuma mudanca em `cards`, `sets`, `card_legalities` ou tabelas source-of-truth MTG.

## Remaining unresolved

| Item | Status |
|---|---|
| 82 grupos duplicados `LOWER(sets.code)` | backlog tecnico; query-level dedupe provado |
| Normalizacao fisica de `sets.code` / `cards.set_code` | not applied |
| Unique index case-insensitive em `sets.code` | not applied; requer migracao previa |
