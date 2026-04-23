# External Commander Meta Candidates Workflow

Data: 2026-04-23

## Objetivo

Separar pesquisa web multi-fonte de `Commander/cEDH` do corpus principal `meta_decks`.

Regra operacional:

- `external_commander_meta_candidates` = fila controlada de candidatos pesquisados externamente
- `meta_decks` = corpus principal ja aceito pelo motor de `extract_meta_insights`

Nao gravar pesquisa web crua direto em `meta_decks`.

## Novos artefatos

- tabela: `external_commander_meta_candidates`
- migration: `server/bin/migrate_external_commander_meta_candidates.dart`
- suporte: `server/lib/meta/external_commander_meta_candidate_support.dart`
- import: `server/bin/import_external_commander_meta_candidates.dart`

## Status aceitos

- `candidate`
- `validated`
- `rejected`
- `promoted`

## Contrato minimo do candidato

Campos obrigatorios:

- `source_name`
- `source_url`
- `deck_name`
- `card_list` ou `cards/card_entries`

Campos recomendados:

- `commander_name`
- `partner_commander_name`
- `subformat`: `EDH` ou `cEDH`
- `archetype`
- `placement`
- `color_identity`
- `is_commander_legal`
- `validation_status`
- `validation_notes`
- `research_payload`

## Exemplo de payload

```json
{
  "candidates": [
    {
      "source_name": "Moxfield",
      "source_url": "https://www.moxfield.com/decks/example",
      "deck_name": "Atraxa Fast Infect",
      "commander_name": "Atraxa, Praetors' Voice",
      "subformat": "cEDH",
      "archetype": "Combo-Control",
      "color_identity": ["W", "U", "B", "G"],
      "is_commander_legal": true,
      "validation_status": "validated",
      "validation_notes": "Lista marcada como cEDH e coerente com shell competitiva.",
      "cards": [
        { "quantity": 1, "name": "Sol Ring" },
        { "quantity": 1, "name": "Mana Crypt" }
      ],
      "research_payload": {
        "web_sources": ["moxfield", "edhrec"],
        "reasoning": "Shell compacta de fast mana + infect/proliferate."
      }
    }
  ]
}
```

## Fluxo recomendado

### 1. Criar schema

```bash
cd server
dart run bin/migrate_external_commander_meta_candidates.dart
```

### 2. Validar payload sem gravar

```bash
cd server
dart run bin/import_external_commander_meta_candidates.dart ../candidates.json --dry-run
```

### 3. Persistir candidatos

```bash
cd server
dart run bin/import_external_commander_meta_candidates.dart ../candidates.json
```

### 4. Promover somente os `validated`

```bash
cd server
dart run bin/import_external_commander_meta_candidates.dart ../candidates.json --promote-validated
```

## Regra de promocao

Hoje o import so promove para `meta_decks` quando:

- `validation_status == validated`
- `subformat` normaliza para `EDH` ou `cEDH`
- `card_list` existe

Ao promover:

- faz `upsert` em `meta_decks` por `source_url`
- marca o candidato como `promoted`
- grava `promoted_to_meta_decks_at`

## Por que isso existe

O produto precisa de duas coisas diferentes:

1. pesquisa externa ampla para entender o ecossistema Commander
2. corpus principal limpo o bastante para alimentar `extract_meta_insights`

Misturar as duas coisas direto em `meta_decks` enfraquece o controle de qualidade.

## Menor proximo passo

- adicionar `--dry-run` e parser mais forte em `fetch_meta.dart`
- decidir se `external_commander_meta_candidates` vai aceitar mais de uma fonte por `source_url` canonicalizada
- criar relatorio de cobertura por `subformat` e identidade de cor nessa nova tabela
