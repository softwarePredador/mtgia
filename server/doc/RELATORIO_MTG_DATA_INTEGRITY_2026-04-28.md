# Relatorio MTG Data Integrity - 2026-04-28

## Objetivo

Fechar o backlog nao bloqueante do catalogo Sets/Colecoes com saneamento DB-backed para:

- duplicidade de `sets.code` por diferenca de casing;
- `cards.color_identity IS NULL`, especialmente em sets recentes/futuros;
- rotina operacional de `sync_cards.dart` para futuras colecoes.

## Etapa 1 - Auditoria dry-run

### Comandos executados

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
dart format lib/mtg_data_integrity_support.dart bin/mtg_data_integrity.dart test/mtg_data_integrity_support_test.dart
dart test test/mtg_data_integrity_support_test.dart
dart run bin/mtg_data_integrity.dart --artifact-dir=test/artifacts/mtg_data_integrity_2026-04-28
```

### Artefatos gerados

Diretorio:

```text
server/test/artifacts/mtg_data_integrity_2026-04-28/
```

Arquivos principais:

- `summary_dry_run.json`
- `summary_dry_run.md`
- `duplicate_set_codes.csv/json`
- `duplicate_set_card_references.csv/json`
- `null_color_identity_by_set.csv/json`
- `null_color_identity_by_type.csv/json`
- `color_identity_backfill_dry_run.csv/json`
- `color_identity_unresolved_dry_run.csv/json`

### Duplicidade de sets.code por casing

Resultado do dry-run:

| Metrica | Valor |
|---|---:|
| Grupos `LOWER(sets.code)` com mais de uma linha | 80 |
| Variantes totais nesses grupos | 160 |

Amostra confirmada nos artefatos:

| lower_code | variantes | observacao |
|---|---|---|
| `10e` | `10E`, `10e` | uppercase tem 362 cards referenciados; lowercase tem 2 |
| `2x2` | `2X2`, `2x2` | uppercase tem 311 cards; lowercase tem 5 |
| `2xm` | `2XM`, `2xm` | uppercase tem 312 cards; lowercase tem 6 |
| `30a` | `30A`, `30a` | lowercase tem 6 cards; uppercase tem 0 |
| `8ed` | `8ED`, `8ed` | uppercase tem 114 cards; lowercase tem 2 |

Decisao da etapa 1: **nao aplicar migracao destrutiva em `sets`**. A duplicidade e ampla, algumas variantes lowercase ainda sao referenciadas por `cards.set_code`, e os endpoints `/sets` e `/cards` ja operam com comparacao case-insensitive e dedupe query-level. A correcao segura para esta frente sera hardening do sync para nao introduzir novos codigos nao canonicos.

### cards.color_identity IS NULL

Resultado do dry-run:

| Metrica | Valor |
|---|---:|
| `cards.color_identity IS NULL` | 33.138 |
| Nulls em sets recentes/futuros (`release_date >= CURRENT_DATE - 180 dias`) | 899 |
| Nulls em sets futuros | 0 |
| Candidatos determinísticos de backfill | 33.138 |
| Linhas unresolved | 0 |

Distribuicao dos candidatos:

| Fonte / motivo | Linhas |
|---|---:|
| `identity_symbols_found` | 29.754 |
| `explicit_empty_colors_without_identity_symbols` | 3.384 |

Critério de determinismo usado no dry-run:

- `colors` existente no banco;
- simbolos em `mana_cost`;
- simbolos em `oracle_text`, ignorando reminder text entre parenteses pelo helper existente;
- subtipos de land em `type_line` (`Plains`, `Island`, `Swamp`, `Mountain`, `Forest`);
- identidade vazia apenas quando `colors` esta presente e vazia e nenhum simbolo confiavel foi encontrado.

### DB changes

Nenhuma alteracao de dados foi executada na etapa 1. O comando `mtg_data_integrity.dart` em modo padrao e dry-run e grava apenas artefatos locais.

### Code changes

- `server/bin/mtg_data_integrity.dart`
  - novo comando dry-run DB-backed;
  - mede duplicidade de set codes, referencias por `cards.set_code`, nulls por set/type e candidatos determinísticos.
- `server/lib/mtg_data_integrity_support.dart`
  - helpers puros para backfill deterministico e normalizacao de set code.
- `server/test/mtg_data_integrity_support_test.dart`
  - cobertura de cores, mana/oracle text, subtipos de land, incolor deterministico e unresolved.

### Validacao da etapa 1

```text
dart test test/mtg_data_integrity_support_test.dart
All tests passed!
```

### Dry-run/apply distinction

Etapa 1 e somente dry-run. O apply de `color_identity` sera implementado com flag explicita e `WHERE color_identity IS NULL`, registrando contagem pre e pos-alteracao.

### Remaining unresolved

Nenhuma linha unresolved no dry-run de `color_identity`.
