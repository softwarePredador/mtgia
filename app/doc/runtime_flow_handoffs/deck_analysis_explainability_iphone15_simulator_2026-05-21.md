# Deck Analysis Explainability - iPhone 15 Simulator - 2026-05-21

## Status

PASS.

## Escopo

Validar que a aba de análise do deck explica quais cartas entram em cada função
do deck e por que foram classificadas, usando `functional_tags` e metadados da
Semantic Layer v2 já retornados pelo backend.

Scanner/camera/OCR fora do escopo.

## Ambiente

- App local com backend público:
  `https://evolution-cartinhas.8ktevp.easypanel.host`;
- device: iPhone 15 Pro Max Simulator
  `DABB9D79-2FDB-4585-94DB-E31F1288EE74`;
- backend git SHA pós-deploy:
  `a02fe90673334ed2fa3a7b7b2a61066760486581`.

## Fluxo validado

1. Registro/autenticação QA descartável.
2. Criação de deck Commander pequeno com fixture sanitizada.
3. `GET /decks/:id/analysis`.
4. Render da aba `DeckAnalysisTab`.
5. Expansão do bucket `Ramp`.
6. Verificação de:
   - origem da contagem;
   - cobertura;
   - texto `Como é contado`;
   - texto `Cartas consideradas`;
   - carta exemplo visível;
   - razão de classificação visível.

## Resultado

Runtime:

```text
00:16 +1: All tests passed!
```

Resumo sanitizado:

```json
{
  "functional_tags_schema_version": "functional_card_tags_v1_2026_05_18",
  "semantic_schema_version": "semantic_layer_v2_2026_05_18",
  "source_priority": "persisted_then_heuristic",
  "persisted_rows": 6,
  "persisted_copies": 6,
  "heuristic_rows": 1,
  "heuristic_copies": 1,
  "counts": {
    "ramp": 2,
    "draw": 1,
    "removal": 2,
    "board_wipe": 0,
    "protection": 0
  },
  "ramp_sample_count": 2,
  "ramp_sample_detail_count": 2,
  "has_explainability_reason": true,
  "ui_rendered": true,
  "sol_ring_visible": true,
  "explainability_visible": true,
  "considered_cards_copy_visible": true
}
```

## Observações

- O teste usa fixture mínima e não salva decklist completa.
- A UI agora diferencia contagem total da função e amostras visíveis.
- Produção continua com `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=disabled`; esta
  mudança é apenas explicabilidade da análise.
- A reprova foi rodada após `/health` confirmar o deploy do commit da UI.
