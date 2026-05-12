# Commander Reference Deck Corpus v1 — 2026-05-12

## Verdict

**PASS WITH RISKS** para a fundacao do corpus de decks completos.

Esta entrega cria a infraestrutura para armazenar e analisar decks completos de
referencia por comandante, mas **nao importa decklists reais ainda** e **nao
altera o app nem o contrato de `/ai/generate`**.

## Objetivo

Evoluir de profiles curados por comandante para um corpus agregado de decks
completos, preservando a regra de produto: decks reais servem como evidencia
estatistica e estrutural, nao como lista a ser copiada pelo gerador.

## Entregas

- Novo suporte:
  `server/lib/ai/commander_reference_deck_corpus_support.dart`
- Novo runner:
  `server/bin/commander_reference_deck_corpus.dart`
- Novo teste:
  `server/test/commander_reference_deck_corpus_support_test.dart`

## Tabelas criadas pelo runner em `--apply`

| Tabela | Papel |
| --- | --- |
| `commander_reference_decks` | Cabeçalho do deck de referencia, fonte, tema, faixa de poder, quantidades, rejeições e role summary. |
| `commander_reference_deck_cards` | Cartas normalizadas por deck, board, quantidade, card_id resolvido, role, unresolved e off-color. |
| `commander_reference_deck_analysis` | Agregado por comandante/source: contagem de decks aceitos, médias por role, top cards e temas. |

## Gates de aceite

Um deck só pode ser aplicado quando todos os gates passam:

- comandante resolvido em `cards`;
- exatamente 1 comandante;
- exatamente 99 cartas no main;
- `unresolved=0`;
- `off_color=0`;
- sem violação singleton fora de terrenos básicos.

Se qualquer deck falhar, `--apply` aborta antes de gravar.

## Análise gerada

Para cada deck, o runner calcula:

- `main_quantity`;
- `commander_quantity`;
- `resolved_count`;
- `unresolved_card_names`;
- `off_color_card_names`;
- `singleton_violations`;
- `role_summary`;
- `accepted` e `rejection_reasons`.

Roles iniciais:

- `lands`;
- `ramp`;
- `draw_value`;
- `interaction`;
- `protection`;
- `board_wipe`;
- `win_condition`;
- `creature`;
- `other`.

## Segurança

- `--dry-run` nao cria tabelas e nao grava dados.
- `--apply` cria tabelas somente depois de todos os decks analisados passarem.
- O runner nao faz scraping.
- Nao registra payload sensivel.
- Nao copia decklist para prompt em runtime.
- Scanner/camera/OCR/MLKit ficam fora do escopo.

## Validações executadas

```bash
cd server && dart format lib/ai/commander_reference_deck_corpus_support.dart bin/commander_reference_deck_corpus.dart test/commander_reference_deck_corpus_support_test.dart
cd server && dart analyze lib/ai/commander_reference_deck_corpus_support.dart bin/commander_reference_deck_corpus.dart test/commander_reference_deck_corpus_support_test.dart
cd server && dart test test/commander_reference_deck_corpus_support_test.dart -r expanded
cd server && dart run bin/commander_reference_deck_corpus.dart --corpus-json=/tmp/lorehold_corpus_smoke.json --dry-run --artifact-dir=test/artifacts/commander_reference_deck_corpus_2026-05-12/smoke_dry_run
```

O smoke dry-run foi executado com deck sintético local apenas para provar o
runner contra DB real; o artifact foi removido para não versionar deck fake como
corpus de produto.

## Riscos

- Nenhuma decklist real foi importada nesta etapa.
- O classificador de roles ainda é heurístico.
- A integração com `/ai/generate` e `/ai/optimize` ainda não consome as novas
  tabelas.

## Próximo passo

Sprint 2: importar 3-5 decks reais de `Lorehold, the Historian` via JSON
curado/sanitizado, aplicar o corpus, gerar análise agregada e só então ligar o
resumo estrutural ao `/ai/generate` de forma opt-in para Lorehold.
