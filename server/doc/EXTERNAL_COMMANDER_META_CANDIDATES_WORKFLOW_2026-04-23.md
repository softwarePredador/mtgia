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
- `subformat`: `commander`, `duel_commander` ou `competitive_commander`
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
      "subformat": "competitive_commander",
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

### 2.1 Stage 1 controlado para TopDeck.gg + EDHTop16

Objetivo:

- validar schema
- validar politica de origem
- gerar relatorio `accept/reject`
- **sem** escrever em banco
- **sem** promover nada para `meta_decks`

Comando recomendado:

```bash
cd server
dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage1 \
  --validation-json-out=test/artifacts/external_commander_meta_candidates_topdeck_edhtop16_stage1_2026-04-24.validation.json
```

Regra operacional do profile `topdeck_edhtop16_stage1`:

- exige `--dry-run`
- bloqueia `--promote-validated`
- rejeita qualquer source fora de `TopDeck.gg` e `EDHTop16`
- aceita apenas `competitive_commander`
- exige `research_payload.collection_method`
- exige `research_payload.source_context`
- exige URL de evento coerente com a fonte:
  - `TopDeck.gg` -> `/event/...`
  - `EDHTop16` -> `/tournament/...`

Saida esperada:

- linhas `[ACCEPT]` / `[REJECT]` no terminal
- artefato JSON com candidatos normalizados e lista de issues

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
- `subformat` normaliza para `duel_commander` ou `competitive_commander`
- `card_list` existe

Regra de seguranca adicional:

- `commander` generico continua estagiado em `external_commander_meta_candidates`
- ele **nao** e promovido automaticamente para `meta_decks` enquanto a tabela principal ainda usar os codigos legados `EDH`/`cEDH`
- isso evita reclassificar Commander multiplayer amplo como `EDH` legado do MTGTop8, que no pipeline atual significa `Duel Commander`

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

- automatizar descoberta de candidatos por fonte, ainda escrevendo primeiro em artefato JSON e nao em banco
- decidir se `external_commander_meta_candidates` vai aceitar mais de uma fonte por `source_url` canonicalizada
- criar relatorio de cobertura por `subformat` e identidade de cor nessa nova tabela
