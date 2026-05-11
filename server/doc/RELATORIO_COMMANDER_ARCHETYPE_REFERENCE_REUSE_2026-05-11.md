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

## Prova publica

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

Depois do deploy publico em `637054b9a706b0a232bab7fab72cc21c0db6ecd7`, o
probe sanitizado foi repetido com cache bypass. Resultado final:

- `status=200`;
- `commander_requested=Velomachus Lorehold`;
- `commander_returned=Velomachus Lorehold`;
- `commander_preserved=true`;
- `main_quantity=99`;
- `validation_is_valid=true`;
- `reference_profile_used=false`;
- `reference_card_stats_used=false`;
- `archetype_reference_used=true`;
- `archetype_candidate_count=48`;
- `archetype_source_commanders=[Lorehold, the Historian, Quintorius, History Chaser]`;
- `warning_code=openai_timeout_deterministic_fallback`.

Leitura: mesmo quando a OpenAI excedeu o timeout, o fallback deterministico
preservou o comandante pedido e manteve os diagnostics de arquetipo.

## Riscos e limites

- A prova publica inicial confirmou diagnostics de arquetipo e preservacao do
  comandante no fallback.
- Em nova rodada publica no mesmo dia, no backend
  `f3bac2bb2fa8de53430acd940732a77e1cd2e133`, houve resposta OpenAI real para
  `Velomachus Lorehold` sem `ai_generation_timed_out`: `status=200`,
  `commander_returned=Velomachus Lorehold`, `main_quantity=99`,
  `validation.is_valid=true`, `archetype_reference_used=true`,
  `archetype_candidate_count=48`, zero off-identity reportado e sem
  `Lorehold, the Historian` nas 99.
- Comparacao sanitizada contra baseline sem `commander_name` mostrou maior
  densidade tematica aproximada na resposta com archetype reuse
  (`on_theme=18` vs `on_theme=4`), sem expor decklists.
- O fallback por arquétipo nao garante que todo comandante "parecido" usara
  Lorehold; ele precisa resolver identidade de cor e ter match de prompt/tema.
- O avaliador `reference_deck_evaluation` continua reservado para profile exato.
- O app deve tratar todos os diagnostics como opcionais.

## Proximo passo recomendado

Medir uma amostra maior antes de alterar timeout/modelo de producao, porque a
rodada de qualidade teve OpenAI real valido, mas 3 de 4 probes com
`commander_name` ainda cairam no fallback por timeout.

Relatorio de qualidade:
`server/doc/RELATORIO_COMMANDER_ARCHETYPE_REFERENCE_QUALITY_PROOF_2026-05-11.md`.
