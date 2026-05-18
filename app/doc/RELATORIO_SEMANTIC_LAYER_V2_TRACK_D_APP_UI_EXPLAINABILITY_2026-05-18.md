# Semantic Layer v2 Track D - App/UI Explainability - 2026-05-18

## Veredito

PASS.

## Entrega

- `DeckAnalysisData` parseia `functional_tags.sample_details`.
- `DeckAnalysisTab` mostra explicacao amigavel por carta/tag, confidence,
  velocidade e eficiencia de mana quando enviados pelo backend.
- Fallback legado para `stats.composition` e `samples` em string foi preservado.
- Buckets visuais adicionados: Tutors, Recursao e Wincons.

## Validacao

- Testes focados de model/provider/widget passaram.
