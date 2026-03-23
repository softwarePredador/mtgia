# Resolution Corpus Workflow

## Objetivo

O corpus de resolução fixa a amostra usada pelo gate real do fluxo:

1. `POST /ai/optimize`
2. se necessário, `POST /ai/rebuild`
3. validação do deck final salvo

Isso evita drift da regressão quando o banco muda, quando decks gerados aparecem na base, ou quando a seleção automática do runner encontra poucas listas úteis.

Arquivo atual do corpus:

- `server/test/fixtures/optimization_resolution_corpus.json`

Handoff de continuidade desta frente:

- `server/doc/OPTIMIZATION_RESOLUTION_HANDOFF_2026-03-18.md`

## Quando adicionar um deck novo

Adicione um deck ao corpus quando ele:

- for `Commander`
- tiver `100` cartas
- tiver exatamente `1` comandante
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

Rodar o gate principal:

```bash
./scripts/quality_gate_carro_chefe.sh
```

## Critério para expandir de 3 para 10+

Antes de aumentar `VALIDATION_LIMIT`, garantir:

- pelo menos `10` comandantes realmente distintos na base
- ausência de shells duplicadas dominando a amostra
- pelo menos:
  - `3-4` casos de `optimized_directly`
  - `3-4` casos de `rebuild_guided`
  - `2-3` casos de `safe_no_change`

Enquanto o banco não tiver diversidade suficiente, o corpus deve continuar curado manualmente.

## Regra prática

O gate oficial é o de resolução fim a fim.

O runner de `optimize` puro continua útil para diagnosticar o quão conservador o motor está, mas não deve ser tratado sozinho como critério final de release.
