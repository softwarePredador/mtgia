# Resolution Corpus Workflow

> Documento ativo de apoio para o corpus de resolucao.
> A prioridade operacional continua sendo definida por `docs/CONTEXTO_PRODUTO_ATUAL.md`.

## Objetivo

O corpus de resolução fixa a amostra usada pelo gate real do fluxo:

1. `POST /ai/optimize`
2. se necessário, `POST /ai/rebuild`
3. validação do deck final salvo

Isso evita drift da regressão quando o banco muda, quando decks gerados aparecem na base, ou quando a seleção automática do runner encontra poucas listas úteis.

Arquivo atual do corpus estavel:

- `server/test/fixtures/optimization_resolution_corpus.json`

Handoff historico desta frente:

- `server/doc/OPTIMIZATION_RESOLUTION_HANDOFF_2026-03-18.md`

## Quando adicionar um deck novo

Adicione um deck ao corpus quando ele:

- for `Commander`
- tiver `100` cartas
- tiver exatamente `1` comandante, ou `2` comandantes legais (`partner/background`)
- não for deck gerado pelo próprio fluxo de validação
- representar um caso útil de produto:
  - `optimized_directly`
  - `rebuild_guided`
  - `safe_no_change`

## Checklist de onboarding

1. Confirmar que o deck é elegível no banco.
2. Verificar se ele não duplica a mesma shell de um caso já existente.
3. Decidir o desfecho esperado:
   - `optimized_directly`
   - `rebuild_guided`
   - `safe_no_change`
4. Se o caso for limítrofe, aceitar múltiplos desfechos:
   - exemplo: `["optimized_directly", "safe_no_change"]`
5. Adicionar a entrada ao corpus.
6. Rodar a auditoria do corpus.
7. Rodar o runner de resolução com o corpus.
8. Só manter no corpus se o resultado for estável e útil.

## Comandos

Auditar o corpus e a cobertura atual da base:

```bash
cd server
dart run bin/audit_resolution_corpus.dart
```

Adicionar um deck novo em dry-run:

```bash
cd server
dart run bin/add_resolution_corpus_entry.dart \
  --deck-id <uuid> \
  --label "Commander Name" \
  --expected-flow-path rebuild_guided \
  --note "Deck precisa de rebuild" \
  --dry-run
```

Gravar a entrada no corpus:

```bash
cd server
dart run bin/add_resolution_corpus_entry.dart \
  --deck-id <uuid> \
  --label "Commander Name" \
  --expected-flow-path rebuild_guided \
  --note "Deck precisa de rebuild"
```

Atualizar uma entrada já existente:

```bash
cd server
dart run bin/add_resolution_corpus_entry.dart \
  --deck-id <uuid> \
  --expected-flow-paths optimized_directly,safe_no_change \
  --replace
```

Rodar o runner oficial de resolução usando o corpus:

```bash
cd server
VALIDATION_CORPUS_PATH=test/fixtures/optimization_resolution_corpus.json \
dart run bin/run_three_commander_resolution_validation.dart
```

Bootstrap de novos seeds a partir de commander-reference:

```bash
cd server
TEST_API_BASE_URL=http://127.0.0.1:8080 \
VALIDATION_COMMANDERS="Jodah, the Unifier;Kozilek, the Great Distortion" \
dart run bin/bootstrap_resolution_corpus_decks.dart --dry-run
```

Para seed com dois comandantes legais, usar `A + B` na mesma entrada:

```bash
cd server
TEST_API_BASE_URL=http://127.0.0.1:8080 \
VALIDATION_COMMANDERS="Wilson, Refined Grizzly + Sword Coast Sailor" \
dart run bin/bootstrap_resolution_corpus_decks.dart --dry-run
```

Rodar o gate principal:

```bash
./scripts/quality_gate_carro_chefe.sh
```

Rodar o gate recorrente oficial do corpus estavel:

```bash
./scripts/quality_gate_resolution_corpus.sh
```

Ou pelo wrapper geral:

```bash
./scripts/quality_gate.sh resolution
```

## Critério atual para manter ou expandir o corpus

Antes de aumentar `VALIDATION_LIMIT` ou ampliar a amostra, garantir:

- pelo menos `16` decks uteis e estaveis na amostra
- comandantes realmente distintos na base
- ausência de shells duplicadas dominando a amostra
- pelo menos:
  - casos suficientes de `optimized_directly`
  - casos suficientes de `rebuild_guided`
  - casos suficientes de `safe_no_change`

Enquanto o banco nao tiver diversidade suficiente, o corpus deve continuar curado manualmente.

## Regra prática

O gate oficial é o de resolução fim a fim.

O runner de `optimize` puro continua útil para diagnosticar o quão conservador o motor está, mas não deve ser tratado sozinho como critério final de release.

## Regra operacional nova

Em `2026-03-23`, o corpus estavel passou a ter gate proprio recorrente:

- `scripts/quality_gate_resolution_corpus.sh`

Esse script:

1. sobe a API local se necessario
2. conta automaticamente o corpus configurado
3. executa o runner oficial de resolucao com `VALIDATION_LIMIT` coerente
4. falha explicitamente se houver `failed`, `unresolved` ou `total` inconsistente

Na Sprint 1, esse passa a ser o caminho correto para validar o corpus antes de release local do core.

## Aditivo de 2026-03-23

Estado atual da cobertura dirigida:

- bootstrap agora aceita seed pareado via `A + B`
- casos dirigidos promovidos ao corpus estavel:
  - `Jodah, the Unifier` -> `safe_no_change`
  - `Kozilek, the Great Distortion` -> `rebuild_guided`
  - `Wilson, Refined Grizzly + Sword Coast Sailor` -> `safe_no_change`
- o runner de resolucao agora valida `1` ou `2` comandantes legais com base no deck fonte
- reminder text inline nao pode mais inflar identidade de cor; o caso `Blind Obedience` em `Sythis` passou a validar no gate recorrente
- o corpus estavel passou a cobrir explicitamente:
  - `optimized_directly`
  - `partner/background`
  - five-color
  - colorless
- revalidacao mais recente do gate recorrente:
  - `19/19 passed`
  - `0 failed`
  - `0 unresolved`
