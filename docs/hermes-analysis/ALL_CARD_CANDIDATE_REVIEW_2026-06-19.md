# All-Card Candidate Review — Battle/Deckbuilding

Data: 2026-06-19

## Objetivo

Validar o pipeline geral contra o catálogo inteiro disponível no PostgreSQL,
não apenas contra a janela Marvel (`msh,msc,mar`). Esta rodada mede a cobertura
de dados, fila `needs_rule_review`, evidência focada automática e promotion
gate para battle/deckbuilding.

Escopo exato:

- `cards_scanned`: cartas deduplicadas por identidade em
  `card_intelligence_snapshot`;
- `commanders_scanned`: comandantes rastreados por learned deck, usage ou
  force-include;
- `review_count`: pares carta/comandante avaliados;
- sem writes em PostgreSQL;
- sem auto-apply de decks;
- sem promoção automática para `card_battle_rules`;
- SQLite Hermes/manaloom-ops usado apenas como cache operacional e evidência.

## Comandos

```bash
python3 server/bin/manaloom_new_card_candidate_review.py \
  --scope full \
  --card-limit 0 \
  --commander-limit 24 \
  --output-dir server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2 \
  --knowledge-db server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2/knowledge.db \
  --hermes-rule-review-threshold 1

python3 server/bin/manaloom_card_data_gap_review.py \
  --knowledge-db server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2/knowledge.db \
  --output-dir server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2

python3 server/bin/manaloom_battle_rule_review_queue.py \
  --knowledge-db server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2/knowledge.db \
  --output-dir server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2 \
  --limit 0 \
  --no-llm-review

python3 server/bin/manaloom_battle_rule_focused_evidence.py \
  --knowledge-db server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2/knowledge.db \
  --output-dir server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2 \
  --limit 0

python3 server/bin/manaloom_battle_rule_promotion_gate.py \
  --knowledge-db server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2/knowledge.db \
  --output-dir server/test/artifacts/all_card_candidate_review_goal_2026-06-19_v2 \
  --limit 0
```

## Resultado Global

```json
{
  "cards_scanned": 34079,
  "commanders_scanned": 24,
  "review_count": 817896,
  "decisions": {
    "already_present": 24,
    "backlog": 44203,
    "ignore": 551330,
    "needs_data": 44096,
    "needs_rule_review": 159873,
    "test": 18370
  }
}
```

Persistência SQLite validada após correção de chave:

```json
{
  "summary_review_count": 817896,
  "persisted_reviews": 817896,
  "summary_needs_rule_review": 159873,
  "queue_rows": 159873,
  "distinct_queue_cards": 13883
}
```

Interpretação:

- a rotina realmente avaliou o catálogo inteiro disponível contra os 24
  comandantes rastreados;
- a fila bruta tem 159.873 ocorrências carta/comandante;
- após agregação por carta, existem 13.883 drafts únicos para revisão de regra;
- `hermes_lab_should_wake=true` por `new_test_candidates` e
  `rule_review_threshold`.

## Correção De Precisão Implementada

A primeira execução global expôs um bug no cache operacional: a tabela
`new_card_candidate_reviews` usava a chave
`(run_id, commander_name, card_name, set_code)`. Isso colapsava cartas com mesmo
nome e set quando `card_id`/`oracle_id` diferiam.

Correção:

- `new_card_candidate_reviews` agora usa `card_id` na chave;
- `new_card_battle_rule_review_queue` agora usa `card_id` na chave;
- o consumidor da fila faz join por `card_id` quando disponível;
- consumidores antigos continuam compatíveis com SQLite legado;
- `--limit 0` em queue/evidence/gate passou a significar “sem limite”, não
  “limite zero”.

Teste novo:

- duas cartas com mesmo `name` e `set_code`, mas `card_id` diferente, são
  persistidas como duas linhas e entram na fila separadamente.

## Data Gaps

```json
{
  "gap_rows": 44096,
  "unique_cards": 3232,
  "decisions": {
    "needs_legality_sync": 2874,
    "needs_oracle_sync": 358
  },
  "priorities": {
    "high": 3136,
    "medium": 96
  }
}
```

Leitura:

- o maior bloqueio de dados ainda é legalidade Commander ausente para parte do
  catálogo antigo/especial;
- 358 cartas ainda exigem oracle sync antes de qualquer regra battle confiável;
- `needs_data` deve continuar determinístico: Scryfall/MTGJSON/PostgreSQL,
  não LLM.

## Battle Rule Queue

```json
{
  "queue_rows": 159873,
  "draft_count": 13883,
  "confidence_counts": {
    "low": 13583,
    "medium": 300
  }
}
```

Famílias mais frequentes:

```text
graveyard_or_zone_recursion: 12081
protection_or_prevention: 12046
targeted_interaction: 6197
triggered_or_static_engine: 5982
card_advantage_or_selection: 3097
synergy_enabler: 2815
synergy_payoff: 2564
token_or_board_presence: 2131
commander_candidate: 1800
counter_manipulation: 1713
mass_removal_or_modal_wipe: 1646
mana_or_resource_acceleration: 1044
```

Próximos templates com maior retorno:

1. Recursion/zone-change genérico, mas separado por evento real
   (`dies`, `exile`, `graveyard cast`, `return to hand`, `return to battlefield`).
2. Protection/prevention com alvo, duração e escopo claros.
3. Targeted interaction além de counterspell simples e sacrifice damage.
4. Trigger/static engines com evento explícito e sem score hard antes de replay.
5. Mass removal/modal wipe.
6. Counter manipulation/counters.
7. Mana/resource acceleration permanente versus one-shot.

## Focused Evidence E Promotion Gate

```json
{
  "focused_evidence": {
    "evaluated_count": 13885,
    "evidence_count": 113
  },
  "promotion_gate": {
    "eligible_count": 113,
    "blocked_count": 13772
  }
}
```

Atualização do slice de 2026-06-19:

- foram adicionados templates focados para oracle text simples:
  - `Destroy target creature.`;
  - `Destroy all creatures.`;
- o executor de `board_wipe` em `battle_analyst_v9.py` foi corrigido para não
  perder permanentes não criatura ao destruir criaturas durante a iteração do
  battlefield;
- a rodada full read-only passou a gerar 113 evidências focadas:
  - 70 `destroy_target_creature_supported`;
  - 25 `destroy_all_creatures_supported`;
  - 15 `activated_sacrifice_creature_damage_supported`;
  - 1 `counterspell_stack_interaction_supported`;
  - 1 `attack_trigger_artifact_tutor_supported`;
  - 1 `extra_combat_flashback_supported`.

Atualização posterior do mesmo ciclo:

- foi adicionado template focado para `Destroy target nonland permanent.`;
- o executor ganhou caminho explícito `move_permanent_from_battlefield()` para
  permanentes não criatura, mantendo o wrapper antigo para compatibilidade;
- a seleção de alvo foi ajustada para não deixar `unknown` mascarar o efeito
  real do permanente;
- a prova controlada de consumidores passou de 6 para 7 drafts elegíveis. A
  rodada full não foi repetida neste sub-slice para evitar novo artefato gigante
  no disco local.

Os 13.772 bloqueios são esperados e corretos: todos faltam fonte oficial
revisada, teste focado e replay/auditoria. Isso impede que `needs_review` vire
comportamento duro por acidente.

Elegíveis para promoção manual futura aumentaram de 18 para 113. A lista abaixo
é apenas a amostra original do primeiro slice; o conjunto completo fica nos
artefatos da rodada e deve ser regenerado sob demanda para não versionar arquivo
gigante:

- `Barrage of Expendables` (`jmp`)
- `Blasting Station` (`5dn`)
- `Blood Rites` (`c13`)
- `Cancel` (`10e`)
- `Fiery Bombardment` (`eve`)
- `Fodder Cannon` (`8ed`)
- `Goblin Bombardment` (`mar`)
- `Iron Man, Titan of Innovation` (`mar`)
- `Krovikan Horror` (`all`)
- `Lyzolda, the Blood Witch` (`dis`)
- `Marjhan` (`hml`)
- `Orcish Bloodpainter` (`csp`)
- `Scorched Rusalka` (`ddk`)
- `Seize the Day` (`mar`)
- `Skirsdag Cultist` (`ddk`)
- `Skull Catapult` (`5ed`)
- `Tymaret, the Murder King` (`ths`)
- `Weaponize the Monsters` (`iko`)

Importante: `eligible_for_manual_verified_promotion` não é promoção automática.
Ainda exige revisão humana/owner ou etapa explícita aprovada para persistir
qualquer regra em PostgreSQL.

## Lorehold

Resumo do controle `Lorehold, the Historian` nesta rodada:

```json
{
  "already_present": 1,
  "backlog": 1389,
  "ignore": 24855,
  "needs_data": 1570,
  "needs_rule_review": 5612,
  "test": 652
}
```

Leitura:

- Lorehold tem candidatos suficientes para scorecards, mas 5.612 avaliações
  ainda dependem de regra battle confiável;
- existem 652 candidatos `test`, mas eles não devem virar swap/decklist sem
  scorecard e comparação contra baseline;
- os candidatos de score alto ainda mostram ruído de classificação ampla,
  especialmente cards que acumulam `protection/ramp/recursion/tutor` por texto
  genérico. Isso precisa de calibragem antes de usar score bruto para otimizar
  Lorehold.

Top amostral de Lorehold:

```text
Agatha's Soul Cauldron: test, rule verified
Alabaster Host Intercessor: needs_rule_review, rule missing
Alchemist's Talent: needs_rule_review, rule missing
Archaeomancer's Map: needs_rule_review, rule needs_review
Armillary Sphere: needs_rule_review, rule missing
Artist's Talent: test, rule verified
Ash Barrens: test, rule verified
Ashling, Flame Dancer: test, rule verified
Axgard Armory: test, rule verified
Balduvian Trading Post: test, rule verified
```

## Pendências Técnicas Reais

P1:

- reduzir `needs_data` com sync determinístico de legalidade/oracle para 3.232
  cartas únicas;
- criar templates focados para as famílias mais frequentes, começando por
  `recursion/zone`, `protection/prevention`, `triggered_or_static_engine`,
  `counter_manipulation` e `mana/resource_acceleration`;
- ampliar `targeted_interaction` e `mass_removal_or_modal_wipe` apenas para
  variantes que ainda não caem nos templates estreitos de `Destroy target
  creature.`, `Destroy target nonland permanent.` e `Destroy all creatures.`;
- calibrar roles inferidos por texto para diminuir scores 100 genéricos em
  cartas utilitárias que hoje acumulam papéis demais;
- rodar scorecard Lorehold usando apenas candidatos `test` ou
  `eligible/manual-reviewed`, nunca a fila bruta `needs_rule_review`.

P2:

- melhorar `draft_rule_key` para usar família/efeito principal em vez do
  primeiro role ordenado; exemplos atuais de sacrifice outlets aparecem como
  `__protection__draft_v1`, o que é legível ruim embora o gate continue correto;
- paginar ou compactar artefatos globais para evitar `latest_reviews.json`
  muito grande em runs full frequentes;
- criar resumo por comandante com ranking de candidatos `test` já verificados
  versus bloqueados por família de regra.

## Critério Para Continuar Lorehold

O próximo ciclo de Lorehold deve usar esta ordem:

1. Fechar `needs_data` material.
2. Filtrar candidatos Lorehold por `test` + regra `verified` ou gate elegível.
3. Separar candidatos por papel real: ramp, draw, removal, protection, engine,
   wincon, tutor, recursion.
4. Rodar scorecard/battle com baseline congelado.
5. Só então propor swaps ou learned-deck update.

Não usar:

- WR bruto isolado;
- score 100 sem fonte/rule coverage;
- `needs_review` como comportamento duro;
- draft de battle rule sem fonte oficial/teste/replay.

## Validações Executadas

```bash
python3 -m py_compile \
  server/bin/manaloom_new_card_candidate_review.py \
  server/bin/manaloom_battle_rule_review_queue.py \
  server/bin/manaloom_battle_rule_focused_evidence.py \
  server/bin/manaloom_battle_rule_promotion_gate.py

python3 server/test/manaloom_new_card_candidate_review_test.py
python3 server/test/manaloom_review_queue_consumers_test.py
```

Rodada global report-only:

- `new_card_candidate_review`: PASS
- `card_data_gap_review`: PASS
- `battle_rule_review_queue --limit 0`: PASS
- `battle_rule_focused_evidence --limit 0`: PASS
- `battle_rule_promotion_gate --limit 0`: PASS

## Veredito

O pipeline agora consegue varrer o catálogo inteiro e preservar todas as linhas
avaliadas sem colapsar cartas por nome/set. O gargalo não é mais “só 8 cartas”;
o gargalo real é transformar 13.883 drafts únicos em grupos de comportamento
testáveis, começando pelos templates de maior frequência e pelos candidatos que
afetam Lorehold/generator/optimize.
