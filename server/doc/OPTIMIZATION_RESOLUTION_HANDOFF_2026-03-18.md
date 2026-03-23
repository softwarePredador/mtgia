# Optimization Resolution Handoff — 2026-03-18

> Handoff historico da baseline de `2026-03-18`.
> Para prioridade atual, corpus vigente e fila oficial do core, consultar primeiro:
> - `docs/CONTEXTO_PRODUTO_ATUAL.md`
> - `docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md`
> - `server/doc/RESOLUTION_CORPUS_WORKFLOW.md`

## Objetivo

Deixar salvo o estado atual da frente de `optimize -> rebuild -> validate`, com baseline congelada e próximos passos claros para retomada futura sem reconstruir contexto.

## Estado atual

A lógica principal já está funcional e consistente no fluxo fim a fim:

1. `POST /ai/optimize`
2. se necessário, `POST /ai/rebuild`
3. validação do deck final salvo

Hoje o sistema já decide entre:

- `optimized_directly`
- `rebuild_guided`
- `safe_no_change`

O app já acompanha isso sem exigir intenção extra do usuário quando cai em `needs_repair`.

## Baseline congelada desta rodada historica

Corpus oficial daquela rodada:

- `server/test/fixtures/optimization_resolution_corpus.json`

Resumo da execução estável daquela data:

- `server/test/artifacts/optimization_resolution_suite/latest_summary.json`
- `RELATORIO_RESOLUCAO_SUITE_COMMANDER_2026-03-18.md`

Numeros da baseline congelada em `2026-03-18`:

- `total = 10`
- `passed = 10`
- `failed = 0`
- `unresolved = 0`
- `direct_optimizations = 1`
- `rebuild_resolutions = 2`
- `safe_no_change = 7`

Distribuição da rodada congelada:

- `Auntie Ool, Cursewretch` -> `rebuild_guided`
- `Talrand, Sky Summoner` -> `rebuild_guided`
- `Edgar Markov` -> `optimized_directly`
- `Jin-Gitaxias // The Great Synthesis` -> `safe_no_change`
- `Atraxa, Praetors' Voice` -> `safe_no_change`
- `Muldrotha, the Gravetide` -> `safe_no_change`
- `Sythis, Harvest's Hand` -> `safe_no_change`
- `Isshin, Two Heavens as One` -> `safe_no_change`
- `Krenko, Mob Boss` -> `safe_no_change`
- `Urza, Lord High Artificer` -> `safe_no_change`

## Arquivos-chave

Fluxo e regras:

- `server/routes/ai/optimize/index.dart`
- `server/routes/ai/rebuild/index.dart`
- `server/lib/ai/rebuild_guided_service.dart`
- `server/lib/ai/deck_state_analysis.dart`

Runners e utilitários:

- `server/bin/run_three_commander_resolution_validation.dart`
- `server/bin/run_three_commander_optimization_validation.dart`
- `server/bin/audit_resolution_corpus.dart`
- `server/bin/add_resolution_corpus_entry.dart`
- `server/bin/bootstrap_resolution_corpus_decks.dart`

Corpus e documentação:

- `server/test/fixtures/optimization_resolution_corpus.json`
- `server/doc/RESOLUTION_CORPUS_WORKFLOW.md`
- `server/doc/OPTIMIZATION_RESOLUTION_HANDOFF_2026-03-18.md`

Artefatos da última suite:

- `server/test/artifacts/optimization_resolution_suite/`

## O que foi estabilizado

- Deck quebrado estruturalmente já não força micro-otimização.
- `needs_repair` já cai em `rebuild_guided`.
- O app já trata isso automaticamente.
- O gate oficial agora é o de resolução fim a fim, não o runner de `optimize` puro.
- Falha de execução da IA em deck saudável não deve mais virar `500` cego; o fallback preserva o deck em estado saudável.

## Volatilidade conhecida

Casos limítrofes podem oscilar entre `optimized_directly` e `safe_no_change`.

Isso é aceitável hoje para:

- `Jin-Gitaxias // The Great Synthesis`
- `Atraxa, Praetors' Voice`
- `Edgar Markov`

O corpus já foi configurado para aceitar múltiplos `expected_flow_paths` onde essa oscilação é tolerável.

## Como retomar esta frente

### 1. Subir API local

```bash
cd server
dart_frog dev -p 8080
```

### 2. Auditar o corpus antes de qualquer mudança

```bash
cd server
dart run bin/audit_resolution_corpus.dart
```

Verificar:

- decks elegíveis
- comandantes únicos
- shells duplicadas
- entradas do corpus ausentes na base

### 3. Rodar o gate oficial atual

```bash
cd server
VALIDATION_LIMIT=10 \
VALIDATION_CORPUS_PATH=test/fixtures/optimization_resolution_corpus.json \
VALIDATION_ARTIFACT_DIR=test/artifacts/optimization_resolution_suite \
VALIDATION_SUMMARY_JSON_PATH=test/artifacts/optimization_resolution_suite/latest_summary.json \
VALIDATION_SUMMARY_MD_PATH=../RELATORIO_RESOLUCAO_SUITE_COMMANDER_2026-03-18.md \
dart run bin/run_three_commander_resolution_validation.dart
```

### 4. Se precisar expandir o corpus

Dry-run de seed:

```bash
cd server
dart run bin/bootstrap_resolution_corpus_decks.dart --dry-run
```

Seed real:

```bash
cd server
dart run bin/bootstrap_resolution_corpus_decks.dart
```

Adicionar manualmente um deck:

```bash
cd server
dart run bin/add_resolution_corpus_entry.dart \
  --deck-id <uuid> \
  --label "Commander Name" \
  --expected-flow-path safe_no_change \
  --note "Motivo do caso"
```

Atualizar entrada existente:

```bash
cd server
dart run bin/add_resolution_corpus_entry.dart \
  --deck-id <uuid> \
  --expected-flow-paths optimized_directly,safe_no_change \
  --replace
```

## Próximos passos previstos naquela rodada

### Prioridade 1

Expandir o corpus de `10` para `15-20` decks reais.

Critério:

- comandantes distintos
- sem dominar a amostra com shells duplicadas
- aumentar principalmente casos de:
  - `optimized_directly`
  - `rebuild_guided`

Hoje o corpus está muito carregado em `safe_no_change`.

### Prioridade 2

Revisar manualmente os rebuilds mais agressivos:

- `Talrand`
- `Auntie`

Objetivo:

- confirmar jogabilidade real
- validar curva
- validar base de mana
- validar aderência ao comandante

### Prioridade 3

Instrumentar produção para medir:

- `% optimized_directly`
- `% rebuild_guided`
- `% safe_no_change`
- `% unresolved`

KPI correto:

- quantos usuários receberam um resultado útil

### Prioridade 4

Continuar usando o runner de `optimize` puro apenas como diagnóstico.

Ele não deve voltar a ser tratado como gate principal de release.

## Regra prática

Quando retomar:

- não começar reabrindo heurística às cegas
- primeiro rodar auditoria
- depois rodar a suíte congelada
- só então mexer em corpus, scoring ou heurística

## Critério de sucesso da retomada proposto na epoca

Considerar essa frente saudável quando:

- a suíte congelada de `10` decks continuar `10/10`
- o corpus crescer para `15-20` decks
- `unresolved` continuar em `0`
- houver mais casos úteis de `optimized_directly` e `rebuild_guided`
