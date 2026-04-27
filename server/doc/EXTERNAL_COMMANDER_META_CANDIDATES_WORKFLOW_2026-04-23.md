# External Commander Meta Candidates Workflow

Data: 2026-04-23

## Objetivo

Separar pesquisa web multi-fonte de `Commander/cEDH` do corpus principal `meta_decks`.

Regra operacional:

- `external_commander_meta_candidates` = fila controlada de candidatos pesquisados externamente
- `meta_decks` = corpus principal ja aceito pelo motor de `extract_meta_insights`

Nao gravar pesquisa web crua direto em `meta_decks`.

## Politica de fontes auditada em 2026-04-24

Classificacao operacional para `external_commander_meta_candidates`:

| Fonte | Classificacao | Status operacional atual | Leitura |
| --- | --- | --- | --- |
| EDHTop16 | accept-with-validation | ativo | fonte de standings/evento competitiva; entra somente com decklist completa, `competitive_commander`, legalidade Commander e `source_context` explicito |
| TopDeck.gg | accept-with-validation | ativo como elo da expansao; staging direto ainda nao provado | pagina de deck consegue expor lista completa; usar com validacao estrutural e nunca como promocao automatica |
| cEDH Decklist Database | enrichment-only | fora do staging | bom para shell/archetype/primer; nao e tratado como lista primaria de evento |
| EDHREC | enrichment-only | fora do staging | agregado e heuristico; nao representa deck competitivo canonico por `source_url` |
| Commander Spellbook | enrichment-only | fora do staging | referencia de combo; nao e host de decklist Commander de 100 cartas |
| Archidekt | accept-with-validation | policy-approved, ainda nao implementado | deck host publico util, mas precisa prova de contexto competitivo e adapter explicito antes de qualquer escrita |
| Moxfield | accept-with-validation | policy-approved, fetch live direto ainda nao provado | deck host publico relevante, mas neste ambiente houve `403` no sample auditado; so pode entrar com adapter/source proof explicitos |

Regras:

1. Nenhuma fonte esta classificada como `accept` hoje.
2. `accept-with-validation` nao autoriza escrita direta; apenas habilita staging com gate estrutural + commander-aware + `--apply` explicito.
3. `enrichment-only` nunca deve virar `source_url/source_name` canonico em `external_commander_meta_candidates`; entra apenas em `research_payload` ou em interpretacao humana.
4. `reject` permanece vazio nesta rodada porque nao houve evidencia suficiente para banimento total de host; isso **nao** significa aprovacao para staging.

### Fatos provados por codigo/local

No codigo atual, a allowlist controlada implementada continua menor do que a politica auditada:

- `EDHTop16` -> hosts `edhtop16.com` / path `/tournament/`
- `TopDeck.gg` -> hosts `topdeck.gg` / path `/event/`

Prova local:

- `server/lib/meta/external_commander_meta_candidate_support.dart`
- `server/test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json`
- `server/test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json`

Leitura:

- `EDHTop16 -> TopDeck deck page -> 100 cartas` esta provado para o fluxo atual
- `Archidekt` e `Moxfield` ficam apenas como policy-approved; nao entram ate existir adapter/source proof dedicados
- `cEDH Decklist Database`, `EDHREC` e `Commander Spellbook` permanecem fora da fila de staging

## Novos artefatos

- tabela: `external_commander_meta_candidates`
- migration: `server/bin/migrate_external_commander_meta_candidates.dart`
- suporte: `server/lib/meta/external_commander_meta_candidate_support.dart`
- import: `server/bin/import_external_commander_meta_candidates.dart`
- staging seguro: `server/bin/stage_external_commander_meta_candidates.dart`
- suporte de staging: `server/lib/meta/external_commander_meta_staging_support.dart`

## Status aceitos

- `candidate`
- `staged`
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
dart run bin/migrate_external_commander_meta_candidates.dart --apply
```

Regra:

- sem `--apply`, a migration e apenas dry-run
- qualquer alteracao real de schema para `external_commander_meta_candidates` deve usar `--apply`

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
  --target-valid=6 \
  --max-standing=24 \
  --output=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json
```

Leitura operacional atual:

- `--limit` continua aceito, mas agora e alias de `--target-valid`
- `--target-valid=<n>` = quantidade de decks expandidos validos que queremos coletar
- `--max-standing=<n>` = teto de standings pedidos ao GraphQL
- o expansor continua tentando standings ate:
  1. bater `target-valid`, ou
  2. esgotar o lote retornado
- standings rejeitados por `topdeck_deckobj_missing` nao encerram a rodada sozinhos

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
- continua **dry-run only**
- nao escreve em `external_commander_meta_candidates`
- nao promove nada para `meta_decks`

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

Resultado da rodada scan-through em `2026-04-27`:

- comando: `--target-valid=6 --max-standing=24`
- `entries_available=14`
- `attempted_count=10`
- `expanded_count=6`
- `rejected_count=4`
- `goal_reached=true`
- novos decks validos alem do lote anterior:
  - `standing-9` `Kefka, Court Mage // Kefka, Ruler of Ruin`
  - `standing-10` `Thrasios, Triton Hero + Yoshimaru, Ever Faithful`

Exemplo adicional reaproveitado na mesma data:

```bash
cd server
dart run bin/expand_external_commander_meta_candidates.dart \
  --source-url=https://edhtop16.com/tournament/jokers-are-wild-monthly-1k-hosted-by-trenton \
  --target-valid=3 \
  --max-standing=12 \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/jokers_edhtop16_expansion_target3_max12_2026-04-27.json
```

Resultado observado:

- `entries_available=10`
- `attempted_count=5`
- `expanded_count=3`
- `rejected_count=2`
- `goal_reached=true`
- rejeicoes:
  - `standing-1` -> `topdeck_deckobj_missing`
  - `standing-4` -> `topdeck_deckobj_missing`

### 3. Persistencia segura do stage 2 em `external_commander_meta_candidates`

```bash
cd server
dart run bin/stage_external_commander_meta_candidates.dart \
  --expansion-artifact=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json \
  --validation-artifact=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json \
  --report-json-out=test/artifacts/external_commander_meta_stage2_staging_dry_run_2026-04-24.json
```

Aplicacao real:

```bash
cd server
dart run bin/stage_external_commander_meta_candidates.dart \
  --apply \
  --expansion-artifact=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json \
  --validation-artifact=test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.validation.json \
  --imported-by=meta_deck_intelligence_2026_04_24
```

Comportamento comprovado:

- modo padrao continua sendo `dry-run`
- escrita real exige `--apply`
- persistencia ocorre **somente** em `external_commander_meta_candidates`
- nao escreve em `meta_decks`
- bloqueia se `validation_profile != topdeck_edhtop16_stage2`
- bloqueia se `validation.rejected_count > 0`
- bloqueia se faltar `card_list` ou `cards/card_entries`
- bloqueia se faltar `research_payload.collection_method`
- bloqueia se faltar `research_payload.source_context`
- bloqueia se `source_name/source_url` forem invalidos
- bloqueia se `is_commander_legal=false`
- faz dedupe por `source_url`
- preserva `research_payload` completo e adiciona `research_payload.staging_audit`
- marca `validation_status='staged'`
- converte `legal_status` do stage 2 para staging:
  - `legal` -> `valid`
  - `not_proven` -> `warning_pending`
  - `illegal` -> `rejected`

Resultado do dry-run base:

- `accepted_count=4`
- `validation_rejected_count=0`
- `expansion_rejected_count=4`
- `to_persist_count=4`
- `duplicate_source_url_count=0`
- distribuicao de `legal_status` no staging planejado:
  - `valid=3`
  - `warning_pending=1`

Snapshot observado:

- `Scion of the Ur-Dragon` -> `validation_status=staged`, `legal_status=warning_pending`
- `Norman Osborn // Green Goblin` -> `validation_status=staged`, `legal_status=valid`
- `Malcolm + Vial Smasher` -> `validation_status=staged`, `legal_status=valid`
- `Kraum + Tymna` -> `validation_status=staged`, `legal_status=valid`

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
- promove **somente** `validation_status=staged`
- promove **somente** `subformat=competitive_commander`
- exige decklist completa de `100` cartas
- exige `is_commander_legal=true`
- exige source allowlisted
- exige `research_payload.source_chain`
- exige `research_payload.staging_audit`
- bloqueia `unresolved_cards`
- bloqueia `illegal_cards`
- bloqueia `warning_pending`
- bloqueia duplicidade por `source_url`
- bloqueia duplicidade por deck fingerprint
- preserva auditabilidade por `source_url`, mantendo `source_name` e `research_payload` no staging para `JOIN` posterior

Resultado do dry-run live atual:

- `total=4`
- `promotable=0`
- `blocked=4`
- bloqueios observados:
  - `validation_status_not_staged`
  - `missing_or_invalid_legal_status`
  - `commander_legality_not_confirmed`
  - `missing_staging_audit`

Leitura:

- o gate de promocao ficou pronto
- a base live ainda nao mostra promocao possivel porque o staging real ainda nao recebeu `stage --apply`
- isso mantem `meta_decks` protegido por default

Rollback operacional de uma promocao real:

```bash
psql $DATABASE_URL -c "
DELETE FROM meta_decks
WHERE source_url = '<source_url_promovida>';

UPDATE external_commander_meta_candidates
SET validation_status = 'staged',
    promoted_to_meta_decks_at = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE source_url = '<source_url_promovida>';
"
```

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

### 4.2 Provar consumo real em `optimize` e `generate`

Depois de qualquer promocao pequena, rodar:

```bash
cd server
dart run bin/meta_reference_probe.dart \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/meta_reference_probe_latest.json
```

Esse probe usa os mesmos helpers reais do runtime e grava:

- quando a referencia externa entra em `optimize`
- quando ela entra em `generate`
- `selection_reason`
- `source_breakdown`
- `priority_cards`
- se houve ou nao vazamento para casual/duel

Fatos confirmados em `2026-04-27`:

- antes do segundo evento:
  - os `5` externos promovidos entravam como `rank 1` em `optimize` competitivo e `generate` competitivo
  - casual/duel ficaram `5/5` verdes
- apos a promocao pequena de `Jokers`:
  - `promoted_external_count=7`
  - `optimize_competitive_external_match_count=7`
  - `generate_competitive_external_match_count=7`
  - guards casual/duel `7/7` verdes

Observacao obrigatoria:

- esse passo encontrou um bug real no caminho keyword-only de `generate`
- o fix ficou em `server/lib/meta/meta_deck_reference_support.dart`
- nao remover esse probe do workflow

### 4.3 Medir cobertura real de identidade de cor

Para medir cobertura por identidade de cor sem depender de probes SQL frageis:

```bash
cd server
dart run bin/meta_commander_color_identity_report.dart \
  --output=test/artifacts/meta_deck_intelligence_2026-04-27/commander_color_identity_coverage_latest.json
```

Esse report usa a heuristica real do projeto:

- `color_identity`
- `colors`
- `mana_cost`
- `oracle_text`

E preserva, por nome, a melhor identidade encontrada entre printings duplicados.

Estado medido em `2026-04-27` apos `Jokers`:

- `external cEDH`: `7/7` resolvidos
- `mtgtop8 cEDH`: `187/214` resolvidos
- `mtgtop8 EDH`: `155/162` resolvidos

### 5. Consumo por `optimize` e `generate`

Regra operacional:

- `generate` continua podendo usar referencias Commander meta apenas quando o prompt comprova o escopo:
  - `competitive_commander`
  - `duel_commander`
- `optimize` e `complete` agora resolvem `competitive_commander` apenas quando:
  - `deckFormat == 'commander'`
  - `bracket >= 3`
- Commander casual (`bracket < 3`) nao deve consultar prioridade competitiva externa por default

Leitura:

- referencias externas competitivas entram como sinal estrategico para high power/cEDH
- Commander casual continua priorizando perfil/reference cache casual em vez de staples competitivos
- isso evita copiar a pressao de cEDH para listas multiplayer genericas

Garantias mantidas:

- nenhuma promocao automatica para `meta_decks`
- nenhuma escrita real sem `--apply`
- `source_chain` segue auditavel e resumido, sem despejar `research_payload` bruto no prompt
- filtros de identidade de cor do comandante continuam ativos no pipeline de sugestao
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

Resultado comprovado apos `stage --apply` + promocao pequena em `2026-04-27`:

- `Kinnan, Bonder Prodigy` -> `promoted/valid`
- `Rograkh, Son of Rohgahh + Silas Renn, Seeker Adept` -> `promoted/valid`
- estado final da fila:
  - `promoted/valid=7`
  - `staged/warning_pending=1`

## Por que isso existe

O produto precisa de duas coisas diferentes:

1. pesquisa externa ampla para entender o ecossistema Commander
2. corpus principal limpo o bastante para alimentar `extract_meta_insights`

Misturar as duas coisas direto em `meta_decks` enfraquece o controle de qualidade.

## Menor proximo passo

- automatizar descoberta de candidatos por fonte, ainda escrevendo primeiro em artefato JSON e nao em banco
- decidir se `external_commander_meta_candidates` vai aceitar mais de uma fonte por `source_url` canonicalizada
- criar relatorio de cobertura por `subformat` e identidade de cor nessa nova tabela
