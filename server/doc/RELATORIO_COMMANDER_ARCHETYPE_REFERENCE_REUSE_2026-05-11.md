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
| `cd server && dart analyze lib routes test` | PASS |
| `cd server && dart test -r expanded` | PASS, `+586` |

## Prova publica inicial

Depois do deploy publico em `e5d8d8a26d6692f0d038bdf05d1778ade2b43759`, foi
rodado probe sanitizado para `Velomachus Lorehold`, sem profile exato, com
prompt Boros `big spells/topdeck/miracle/spellslinger`.

Resultado observado:

- `status=200`;
- `archetype_reference_used=true`;
- `archetype_candidate_count=48`;
- `archetype_source_commanders=[Lorehold, the Historian, Quintorius, History Chaser]`;
- packages: `topdeck_and_miracle_setup`,
  `miracle_payoffs_expensive_spells`, `spell_payoff_copy_package`,
  `interaction_and_resets`, `interaction`, `graveyard_leave_enablers`;
- `validation_is_valid=true`.

O mesmo probe revelou um bug de fallback: quando a OpenAI excedia o timeout e
nao havia profile exato, o fallback deterministico preservava diagnostics de
arquetipo mas retornava `Isamaru, Hound of Konda` como comandante. O handler foi
ajustado para resolver e preservar `commander_name` tambem no fallback
deterministico sem profile exato.

## Riscos e limites

- A prova publica confirmou diagnostics de arquetipo, mas o patch de preservacao
  do comandante no fallback ainda precisa de deploy publico e novo probe.
- O fallback por arquétipo nao garante que todo comandante "parecido" usara
  Lorehold; ele precisa resolver identidade de cor e ter match de prompt/tema.
- O avaliador `reference_deck_evaluation` continua reservado para profile exato.
- O app deve tratar todos os diagnostics como opcionais.

## Proximo passo recomendado

Depois do deploy do patch de fallback, repetir o probe de `Velomachus Lorehold`
para confirmar simultaneamente `archetype_reference_used=true`,
`commander_returned=Velomachus Lorehold`, 100 cartas, 0 off-identity e validacao
OK.
