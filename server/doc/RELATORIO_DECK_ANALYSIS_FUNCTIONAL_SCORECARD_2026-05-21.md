# Deck Analysis Functional Scorecard - 2026-05-21

## Veredito

**PASS_WITH_RISKS** para o gate público de `GET /decks/:id/analysis` em decks
Commander completos.

O payload explicável de `functional_tags` foi medido sobre 10 corpora
Commander Reference versionados. Não houve divergência entre
`stats.composition` e `functional_tags.counts`, ausência de amostras/detalhes
para bucket primário contado, shape incompleto ou corpus inválido nesta rodada.

## O que foi validado

- criação de decks temporários Commander a partir dos mesmos corpora
  sanitizados usados pelo scorecard Semantic v2;
- validação dos 100 cards persistidos por deck antes da leitura da análise;
- leitura pública de `/decks/:id/analysis`;
- presença de `functional_tags.schema_version`,
  `functional_tags.semantic_schema_version`, `coverage` e `source`;
- coerência de `ramp`, `draw`, `removal`, `board_wipe` e `protection` entre
  `stats.composition` e `functional_tags.counts`;
- amostras e `sample_details` explicáveis para bucket primário com contagem
  positiva, sem salvar nomes das cartas no artifact.

## Runner e artifact

- Runner: `server/bin/deck_analysis_functional_scorecard.py`.
- Artifact público sanitizado:
  `server/test/artifacts/deck_analysis_functional_scorecard_2026-05-21/public_summary.json`.
- Backend público provado:
  `5b7153d4db5e4e1df465050d65ea399fa8ad6f3b`.

O runner reutiliza os corpora versionados e a criação de deck temporário do
scorecard de Optimize, mas mede apenas análise de deck. O artifact não salva
token, e-mail QA, deck id, card id, decklist, nome de carta nem resposta bruta.

## Scorecard público

| Métrica | Valor |
|---|---:|
| Corpora tentados | 10 |
| Corpora elegíveis | 10 |
| `/analysis` HTTP 200 | 10 |
| Shapes explicáveis OK | 10 |
| Blockers | 0 |
| Warnings | 0 |
| Decisão | `analysis_payload_ready_for_real_deck_qa` |

Cobertura por deck ficou entre 75 e 96 cópias tagueadas sobre 100. Todos os
decks lidos carregaram prioridade `persisted_then_heuristic`; as cópias
persistidas ficaram entre 75 e 96 e o fallback heurístico ficou entre 4 e 25
cópias conforme o corpus.

## Runtime app

O harness `app/integration_test/deck_functional_tags_runtime_test.dart` foi
executado no iPhone 15 Pro Max Simulator
`DABB9D79-2FDB-4585-94DB-E31F1288EE74` contra o mesmo backend público.

Resultado:

- `00:09 +1: All tests passed!`;
- backend SHA confirmado em runtime:
  `5b7153d4db5e4e1df465050d65ea399fa8ad6f3b`;
- `functional_tags.schema_version=functional_card_tags_v1_2026_05_18`;
- `semantic_schema_version=semantic_layer_v2_2026_05_18`;
- UI renderizou a seção de funções, motivo de explicabilidade e texto de
  cartas consideradas.

## Comandos executados

```bash
python3 -m py_compile \
  server/bin/deck_analysis_functional_scorecard.py \
  server/bin/semantic_layer_v2_optimize_scorecard.py
python3 server/bin/deck_analysis_functional_scorecard.py \
  --expected-sha 5b7153d4db5e4e1df465050d65ea399fa8ad6f3b \
  --limit 10 \
  --output server/test/artifacts/deck_analysis_functional_scorecard_2026-05-21/public_summary.json
cd app && flutter test integration_test/deck_functional_tags_runtime_test.dart \
  -d DABB9D79-2FDB-4585-94DB-E31F1288EE74 \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=DISABLE_FIREBASE_STARTUP=true \
  --dart-define=DISABLE_FIREBASE_PERFORMANCE_INIT=true \
  --reporter expanded \
  --no-version-check
```

## Riscos remanescentes

- Este gate prova coerência do payload explicável e cobertura dos corpora
  versionados; não substitui revisão humana quando um usuário discorda da tag
  de uma carta específica.
- O scorecard não muda heurísticas, persistência ou enforcement Semantic v2. Ele
  barra regressão de shape/coerência na leitura da Deck Analysis.
- O artifact não retém nomes das cartas justamente para não transformar a prova
  em decklist; triagem de falso positivo/negativo continua usando fixtures
  focadas ou feedback explícito.

## Próximo passo

Usar esse runner como gate antes de ampliar regras semânticas de Deck Analysis.
Se feedback real apontar carta/tag divergente, criar fixture focada e rerodar o
mass audit/scorecard antes de alterar heurística global.
