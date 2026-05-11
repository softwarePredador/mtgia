# Commander Archetype Reference Reuse — 2026-05-11

## Objetivo

Permitir que comandantes sem profile exato recebam ajuda dos pacotes ja curados
de comandantes parecidos, sem copiar decklists, sem criar dados novos em runtime
e sem relaxar legalidade, identidade de cor ou validacao final.

## Mudanca implementada

- `/ai/generate` continua priorizando `commander_reference_profiles` exato por
  `commander_name`.
- Quando nao existe profile exato, o backend tenta carregar stats de outros
  profiles aprovados em `commander_reference_card_stats`.
- A reutilizacao so entra se:
  - o comandante alvo for resolvido no banco;
  - a identidade de cor do profile fonte estiver contida na identidade do alvo;
  - prompt, temas, roles ou packages tiverem match com o pedido;
  - as cartas fonte estiverem resolvidas e com confidence minima configurada.
- Os stats reutilizados recebem score reduzido e source em memoria
  `archetype_reference_reuse_v1:<sourceCommander>`.
- O contrato retorna diagnostics separados:
  - `reference_profile_used=false`;
  - `reference_card_stats_used=false`;
  - `archetype_reference_used=true`;
  - `archetype_candidate_count`;
  - `archetype_package_keys`;
  - `archetype_source_commanders`;
  - `archetype_commander_color_identity`;
  - `archetype_confidence=medium_low`.

## Leitura de produto

Para `Lorehold, the Historian`, o fluxo segue usando o profile exato e os 34
stats curados. Para outro comandante Boros/spellslinger/big spells/topdeck sem
profile proprio, o backend pode aproveitar pacotes como topdeck/miracle setup,
big spells e engines de spells de forma conservadora.

Isso responde ao caso de uso: "se outro comandante for parecido com Lorehold,
as cartas do Lorehold ajudam?". Sim, mas como referencia de arquétipo de baixa
confiança, nao como lista fixa.

## Validacoes executadas

| Comando | Resultado |
| --- | --- |
| `cd server && dart analyze lib/ai routes/ai test/commander_reference_card_stats_support_test.dart` | PASS |
| `cd server && dart test test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_support_test.dart test/ai_generate_performance_support_test.dart -r expanded` | PASS, `+23` |

## Riscos e limites

- Prova publica/runtime ainda depende de deploy do backend com este commit.
- O fallback por arquétipo nao garante que todo comandante "parecido" usara
  Lorehold; ele precisa resolver identidade de cor e ter match de prompt/tema.
- O avaliador `reference_deck_evaluation` continua reservado para profile exato.
- O app deve tratar todos os diagnostics como opcionais.

## Proximo passo recomendado

Depois do deploy publico, rodar probe sanitizado com um comandante sem profile
exato mas com tema Boros/spellslinger/topdeck para confirmar
`archetype_reference_used=true`, deck com 100 cartas, comandante unico, 0
off-identity e validacao OK.
