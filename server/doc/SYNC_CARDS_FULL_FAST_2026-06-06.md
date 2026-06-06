# Sync Cards Full Fast - 2026-06-06

## Problema corrigido

O `dart run bin/sync_cards.dart --full` ficava lento e, em execucoes anteriores, chegou a parecer travado em transacao aberta no Postgres. O gargalo principal era o full sync tentando enviar milhares de upserts pelo caminho Dart/Postgres em lotes pequenos, com muitas viagens ao banco.

## Ajuste aplicado

- O Dart continua responsavel por orquestrar ambiente, versionamento MTGJSON, download e logs.
- O merge pesado de `AtomicCards.json` agora roda em `bin/sync_cards_full_fast.py`.
- O helper Python usa `psycopg2.extras.execute_values`, deduplica cartas por `scryfallOracleId` e legalidades por `(card_id, format)`.
- O full sync usa batch de `10000`, reduzindo centenas de round-trips/commits.
- O incremental continua no Dart com batch de `500`, adequado para sets pequenos.
- A sincronizacao de `sets` tambem deixou de usar transacao longa com `UPDATE` + `INSERT` por linha; agora usa upsert em batch no Dart.

## Evidencia real

Comando de prova pesada:

```powershell
cd C:\Users\rafae\OneDrive\Documents\mtgia\server
dart run bin\sync_cards.dart --full --force
```

Resultado:

- `Cards`: 34058 processadas
- `Legalities`: 322307 processadas
- `cards_total`: 34329
- `card_legalities_total`: 324538
- `mtgjson_meta_version`: 5.3.0+20260605
- `mtgjson_meta_date`: 2026-06-05

Medições do helper pesado com `AtomicCards.json` local:

- Batch `500`: aproximadamente 499s no trecho Python pesado.
- Batch `5000`: aproximadamente 129s.
- Batch `10000`: aproximadamente 119s.

Validacao do caminho normal sem reprocessar tudo:

```powershell
dart run bin\sync_cards.dart --full
```

Resultado: checagem completa de `SetList.json` + upsert de 864 sets + skip por versao atualizada em aproximadamente 15,9s.

Cobertura de metadados de combate no Postgres apos sync:

- `power_known`: 18851
- `toughness_known`: 18851
- `keywords_known`: 16589

## Comandos de validacao

```powershell
cd C:\Users\rafae\OneDrive\Documents\mtgia\server
dart analyze bin\sync_cards.dart
python -m py_compile bin\sync_cards_full_fast.py
python bin\sync_cards_full_fast.py --atomic-cards AtomicCards.json --batch-size 10000
```

## Observacoes

- `--full` sem `--force` pula corretamente quando `sync_state.mtgjson_meta_version` ja esta igual ao `Meta.json` remoto.
- `--full --force` deve ser usado quando for necessario provar o pipeline inteiro de novo.
- O arquivo `AtomicCards.json` e cache operacional local e nao deve ser versionado.
