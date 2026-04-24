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
- `promoted` (legado/inativo neste fluxo)

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
- `legal_status`: `valid`, `warning_reviewed`, `warning_pending` ou `rejected`
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
      "legal_status": "valid",
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

### 2.2 Expansao dry-run EDHTop16 -> TopDeck deck page

Objetivo:

- sair de `EDHTop16 /tournament/<slug>`
- buscar `entries[].decklist` via GraphQL
- abrir paginas `topdeck.gg/deck/...`
- extrair `const deckObj = {...}`
- gerar candidatos com `card_list` completa de `100` cartas
- **sem** escrever em banco
- **sem** promover nada para `meta_decks`

Comando recomendado:

```bash
cd server
dart run bin/expand_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57 \
  --limit=8 \
  --output=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json
```

Validar o artefato gerado no stage 2:

```bash
cd server
dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json \
  --dry-run \
  --validation-profile=topdeck_edhtop16_stage2 \
  --validation-json-out=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json
```

Regra operacional do profile `topdeck_edhtop16_stage2`:

- bloqueia `--promote-validated`
- exige que o candidato passe no `topdeck_edhtop16_stage1`
- quando `cards`/`card_legalities` estiverem disponiveis, resolve os nomes contra o banco
- calcula `commander_color_identity` a partir dos commanders resolvidos
- valida que cada carta resolvida respeita a identidade dos commanders
- valida legalidade em `card_legalities` para o formato `commander`
- grava no artefato:
  - `commander_color_identity`
  - `unresolved_cards`
  - `illegal_cards`
  - `legal_status` (`legal`, `illegal`, `not_proven`)
- exige `card_count >= 98`
- exige `commander_name`
- exige `card_list`
- exige `format=commander`
- exige `subformat=competitive_commander`
- exige `research_payload.collection_method`
- exige `research_payload.source_context`
- exige `research_payload.total_cards=100` quando o campo existe
- rejeita `validation_status=promoted`
- rejeita `is_commander_legal=false`
- `unresolved_cards` continua como warning em `--dry-run`
- `illegal_cards` ou `is_commander_legal=false` bloqueiam o candidato
- persistencia real e permitida **somente** com este profile
- a escrita real acontece **somente** em `external_commander_meta_candidates`
- a escrita real reutiliza o aceite do stage 2 para staging seguro; `meta_decks` continua intocado

Resultado da rodada base:

- expansao: `expanded_count=4`, `rejected_count=4`
- validação stage 2 sobre os expandidos: `accepted_count=4`, `rejected_count=0`
- legalidade resolvida contra `cards`:
  - `legal=3`
  - `not_proven=1`
  - `illegal=0`
- caso `not_proven` atual:
  - `Scion of the Ur-Dragon` com `unresolved_cards=["Prismari, the Inspiration"]`
- rejeicoes de expansao observadas: `topdeck_deckobj_missing`

### 3. Persistir candidatos aprovados no stage 2

```bash
cd server
dart run bin/import_external_commander_meta_candidates.dart \
  test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json \
  --validation-profile=topdeck_edhtop16_stage2 \
  --imported-by=meta_deck_intelligence_2026_04_24
```

Comportamento comprovado:

- bloqueia qualquer `rejected`
- deduplica por `source_url` antes do `upsert`
- preserva `research_payload` completo em `JSONB`
- mantem `validation_status` recebido do payload
- nao escreve em `meta_decks`
- rejeita explicitamente `--promote-validated`

Regra de seguranca adicional:

- `commander` generico continua estagiado em `external_commander_meta_candidates`
- ele **nao** e promovido automaticamente para `meta_decks` enquanto a tabela principal ainda usar os codigos legados `EDH`/`cEDH`
- isso evita reclassificar Commander multiplayer amplo como `EDH` legado do MTGTop8, que no pipeline atual significa `Duel Commander`

### 4. Promover para `meta_decks` com gate separado

O fluxo de promocao **nao** reutiliza `--promote-validated` do importador antigo.

Existe agora um gate proprio:

- script: `server/bin/promote_external_commander_meta_candidates.dart`
- suporte: `server/lib/meta/external_commander_meta_promotion_support.dart`
- modo padrao: `dry-run`
- escrita real: somente com `--apply`

Comando recomendado para auditoria nao destrutiva:

```bash
cd server
dart run bin/promote_external_commander_meta_candidates.dart \
  --report-json-out=test/artifacts/external_commander_meta_candidates_promotion_gate_dry_run_2026-04-24.json
```

Regras do gate:

- seleciona candidatos direto de `external_commander_meta_candidates`
- promove **somente** `validation_status=validated`
- promove **somente** `subformat=competitive_commander`
- exige `card_count >= 98`

### 4.1 Auditoria source-aware apos o gate

Depois de qualquer dry-run ou promocao real, usar os relatórios source-aware:

```bash
cd server
dart run bin/extract_meta_insights.dart --report-only
dart run bin/meta_profile_report.dart
```

Leitura esperada:

- `extract_meta_insights.dart --report-only` expõe:
  - `by_source`
  - `by_source_format`
  - `by_source_subformat`
  - `top_commander_shells`
  - `top_commander_strategies`
- `meta_profile_report.dart` expõe:
  - `sources`
  - `source_formats`
  - `commander_shell_strategy_summary_by_source`
  - `top_groups_source_format_color_shell`
  - `top_groups_source_format_color_strategy`

Regra:

- se `source=external` ainda nao aparecer em `meta_profile_report.dart`, a cobertura live de externos em `meta_decks` segue **nao comprovada**
- exige `legal_status` em `valid` ou `warning_reviewed`
- exige `source_url` unico no staging e ausente em `meta_decks`
- exige `commander_name` presente
- exige `research_payload.source_chain` presente
- mapeia a promocao para `meta_decks.format='cEDH'`
- ao aplicar, marca o staging como `validation_status='promoted'`

Aplicacao real:

```bash
cd server
dart run bin/promote_external_commander_meta_candidates.dart --apply
```

Resultado comprovado no dry-run base desta rodada:

- `total=4`
- `promotable=0`
- `blocked=4`
- todos os `4` rows foram bloqueados por:
  - `validation_status_not_validated`
  - `missing_or_invalid_legal_status`

Leitura:

- a fila externa atual continua segura: nada entra em `meta_decks` sem revisao explicita
- o proximo passo operacional e revisar candidatos e atualizar `validation_status` + `legal_status` antes de qualquer `--apply`

## Por que isso existe

O produto precisa de duas coisas diferentes:

1. pesquisa externa ampla para entender o ecossistema Commander
2. corpus principal limpo o bastante para alimentar `extract_meta_insights`

Misturar as duas coisas direto em `meta_decks` enfraquece o controle de qualidade.

## Menor proximo passo

- automatizar descoberta de candidatos por fonte, ainda escrevendo primeiro em artefato JSON e nao em banco
- decidir se `external_commander_meta_candidates` vai aceitar mais de uma fonte por `source_url` canonicalizada
- criar relatorio de cobertura por `subformat` e identidade de cor nessa nova tabela
