# Lorehold Miracle + Topdeck Readiness Audit - 2026-06-17

> Status 2026-06-19: documento historico. Use como contexto de miracle/topdeck,
> nao como prova de estado atual depois dos fixes e event-contract findings.
> Fonte viva: [BATTLE_VALIDATION_REGISTER_2026-06-19.md](BATTLE_VALIDATION_REGISTER_2026-06-19.md).
> Indice: [BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md](BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md).

## Objetivo

Validar, com evidência de código e artefatos, se o projeto hoje realmente
suporta o plano central de `Lorehold, the Historian`:

- miracle em instants/sorceries;
- setup de topo;
- draw/rummage em turnos de oponentes;
- wincons que dependem de manipulação de topo e primeiro draw do turno.

Pergunta central:

- o deck final parece `miracle/topdeck/spellslinger` só na lista,
  ou battle + generator já sustentam esse plano de forma coerente?

## Atualização de implementação — 2026-06-17

Depois da primeira rodada deste audit, o runtime local recebeu o primeiro slice
seguro para Lorehold:

- `Lorehold, the Historian` passou a ter regra revisada com
  `grants_miracle_cost=2` e `opponent_upkeep_rummage=true`;
- `Library of Leng` deixou de ser modelada como `ramp_permanent` e passou a
  carregar `no_max_hand_size` +
  `discard_effect_to_top_replacement=true`;
- `Sensei's Divining Top` ganhou suporte seguro para
  `peek_top_count=3` + `reorder_top=true` e para a linha
  `draw -> put self on top` quando o topo atual já é o melhor first draw
  castável do turno;
- `Scroll Rack` ganhou o primeiro slice executável:
  no upkeep do próprio turno, ele pode trocar uma instant/sorcery de alta
  prioridade da mão para o topo e preparar a próxima compra de miracle;
- o contador `cards_drawn_this_turn` passou a resetar por turno global, e não
  apenas no começo do próprio turno;
- o upkeep de oponente agora pode emitir
  `lorehold_upkeep_rummage` + `miracle_cast` com `decision_trace_v1`.
- o sync do cache local passou a limpar linhas `manual` obsoletas e regras
  `curated` superseded do mesmo card, evitando que
  `known_cards_canonical_snapshot.json` escolhesse uma versão antiga do
  `Top`/`Scroll Rack` por ordem incidental.
- o espelho `sync_battle_card_rules_pg.py --apply-sqlite-from-pg` passou a
  filtrar linhas `curated` históricas do PostgreSQL que já não pertencem ao
  reviewed layer atual antes de repovoar o SQLite Hermes, impedindo que uma
  irmã antiga volte a sombrear a versão revisada logo após o refresh.

Validação local desta rodada:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`
  -> `Ran 13 tests ... OK`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_manual_preserve.py`
  -> `Ran 5 tests ... OK`
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  -> suíte principal `PASS`
- provas controladas geradas em:
  - [lorehold_controlled_miracle_summary.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/test/artifacts/lorehold_battle_validation_2026-06-17/lorehold_controlled_miracle_summary.json)
  - [lorehold_controlled_miracle_cast_summary.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/test/artifacts/lorehold_battle_validation_2026-06-17/lorehold_controlled_miracle_cast_summary.json)

## Fontes usadas

### Código

- [battle_analyst_v9.py](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py)
- [known_cards_canonical_snapshot.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json)
- [commander_reference_profile_support.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/ai/commander_reference_profile_support.dart)
- [commander_reference_card_stats_support.dart](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/lib/ai/commander_reference_card_stats_support.dart)

### Artefatos

- [lorehold_public_generator_parity_2026-06-17_post_profile_fix/summary.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/test/artifacts/lorehold_public_generator_parity_2026-06-17_post_profile_fix/summary.json)
- [commander_generate_provenance_summary.json](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server/test/artifacts/commander_generate_provenance_2026-06-17_live5/commander_generate_provenance_summary.json)
- [LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md)
- [LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md](/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md)

### Fontes externas rechecadas

- [Miracles Every Turn With Lorehold, the Historian](https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander)
- [Lorehold, the Historian - EDHREC commander page](https://edhrec.com/commanders/lorehold-the-historian)
- [Lorehold, the Historian - official/Gatherer listing](https://gatherer.wizards.com/SOS/en-us/284/lorehold-the-historian)
- [Lorehold, the Historian oracle text snippet](https://starcitygames.com/lorehold-the-historian-sgl-mtg-sos-201-enn/?srsltid=AfmBOopM2DXb2H2pn-WVnoycAVoMaV_1Ql4K9XN5OAaYrgv-3ekNGRdY)
- [Sensei's Divining Top oracle text snippet](https://scryfall.com/search?as=full&q=%2B%2B%21%22sensei%27s+divining+top%22)
- [Library of Leng oracle text snippet](https://scryfall.com/search?as=full&dir=desc&order=usd&q=%2B%2B%21%22Library+of+Leng%22)

## Verdade atual do generator

## O que já está alinhado

O generator está mais próximo do plano do comandante do que o battle.

Evidências:

- o profile do Lorehold declara explicitamente:
  - `boros_miracle_big_spells`
  - `topdeck_manipulation`
  - `opponent_turn_draw_rummage`
  - `spellslinger_copy_payoffs`
- os `expected_packages` incluem:
  - `Sensei's Divining Top`
  - `Scroll Rack`
  - `Library of Leng`
  - `Brainstone`
  - `Temple Bell`
  - `Mikokoro, Center of the Sea`
  - `Victory Chimes`
- o artifact de parity público de 2026-06-17 mostra preview gerado com:
  - `Brainstone`
  - `Library of Leng`
  - `Mikokoro, Center of the Sea`
  - `Scroll Rack`
  - `Sensei's Divining Top`

Conclusão:

- o generator já entende que o núcleo do Lorehold não é só “bombas vermelhas”;
- ele já injeta setup de topo e first-draw support no pacote canônico.

## O que ainda não está plenamente fechado

- o generator ainda não prova que o ranking final favorece esse plano por policy
  explícita;
- `learned_deck_parallel_not_ranked_in_generate` continua aberto;
- ainda existem 42 cartas tocadas por fallback e buckets residuais conhecidos.

## Verdade atual do battle

## O que já existe

Há suporte parcial e simplificado para o plano do Lorehold:

- o runtime detecta `Lorehold, the Historian` no battlefield;
- há um branch de `miracle_cast`;
- cards com `effect = topdeck_manipulation` são reconhecidos;
- `Approach of the Second Sun` já é `manual/verified`.

## O que está simplificado demais

### 1. O comandante não está modelado como habilidade completa

Status desta afirmação após o slice local:

- parcialmente resolvida.

No snapshot canônico, `Lorehold, the Historian` aparece apenas como:

- `effect = commander`
- `haste = true`
- `is_commander = true`

Não há metadata explícita do texto funcional do comandante para:

- “each instant and sorcery card in your hand has miracle {2}”
- “at the beginning of each opponent's upkeep, you may discard a card; if you
  do, draw a card”

Conclusão:

- o comportamento central do comandante já deixou de ser apenas branch ad hoc;
- ainda falta transformar o pacote inteiro em capabilities mais granulares e
  usáveis por linhas mais ricas de topo/engine.

### 2. `miracle_cast` está preso ao draw step do turno ativo

Status desta afirmação após o slice local:

- resolvida no caso base do Lorehold.

O trecho atual do battle:

- só roda após `drawn_for_turn = player.draw(1, rng)`;
- checa `player.cards_drawn_this_turn == 1`;
- detecta Lorehold no battlefield;
- se a carta comprada é instant/sorcery e há mana, empilha `miracle_cast`.

Isso significa que a implementação atual está centrada no draw do próprio turno.

Não há evidência de implementação explícita do texto:

- “at the beginning of each opponent's upkeep, you may discard a card. If you
  do, draw a card.”

Busca direta no código:

- `beginning of each opponent` → ausente
- `discard a card, and if you do, draw a card` → ausente
- `opponent_turn_draw_rummage` → ausente

Conclusão atual:

- o battle agora modela explicitamente o motor de first-draw nos turnos dos
  oponentes para o caso base do Lorehold;
- o que ainda falta não é mais "existência do trigger", e sim enriquecer as
  escolhas de discard/topdeck em linhas mais complexas.

### 3. `topdeck_manipulation` ainda é modelado de forma rasa, mas deixou de ser só metadata

Status desta afirmação após o slice local:

- ainda válida, mas com primeiro fechamento parcial.

No resolve de `effect == topdeck_manipulation`, o runtime hoje:

- coloca o permanente no battlefield;
- chama `player.draw(1, rng)`.

Isso é insuficiente para representar corretamente:

- `Sensei's Divining Top`
  - olhar as três do topo
  - reorganizar
  - habilidade de comprar e recolocar o Top no topo
- `Scroll Rack`
  - exilar cartas da mão
  - comprar a mesma quantidade do topo
  - recolocar as exiladas no topo
- outras peças de setup/topdeck de valor comparável.

Conclusão:

- o battle reconhece a classe `topdeck_manipulation`;
- `Sensei's Divining Top` já cobre:
  - reorder do topo para first draw;
  - compra imediata do topo + recolocação do próprio `Top` quando isso abre
    uma janela concreta de miracle;
- `Scroll Rack` já cobre um slice seguro:
  - trocar uma carta forte da mão para o topo no upkeep do próprio turno para
    converter a draw step em miracle;
- o que ainda continua pendente é a política genérica/arbitrária dessas peças,
  não mais o caso base do plano do Lorehold.

### 4. `Library of Leng` deixou de ser um falso mana rock no fallback canônico

Status desta afirmação após o slice local:

- resolvida no runtime revisado local e no snapshot canônico regenerado.

No snapshot atual, `Library of Leng` aparece como:

- `effect = passive`
- `discard_effect_to_top_replacement = true`
- `no_max_hand_size = true`
- `battle_rule_source = curated`
- `battle_rule_review_status = active`

Esse estado agora está coerente com o uso real da carta no plano do comandante.

Pelo oracle atual, o valor da carta é:

- no maximum hand size;
- substituir descarte indo para o topo da biblioteca.

No contexto do Lorehold, isso importa porque:

- o comandante descarta e compra;
- wheels e rummage tornam o descarte relevante;
- colocar card descartado no topo reforça miracle/topdeck lines.

Conclusão atual:

- `Library of Leng` deixou de ser `ramp_permanent` no runtime e no fallback
  canônico versionado;
- a carta agora atua como peça de hand/topdeck/discard replacement, que é o
  papel coerente para o plano do comandante.

## Matriz de alinhamento

| Camada | Estado atual | Veredito |
| --- | --- | --- |
| Profile/reference data | tema do comandante bem descrito | bom |
| Public generator parity | inclui setup de topo real | bom |
| Deterministic builder | coerente com o plano, mas ainda com fallback residual | parcial |
| Battle miracle no próprio draw | existe | bom |
| Battle rummage no upkeep do oponente | implementado e validado em cenário controlado | parcial |
| Battle topdeck engines reais (`Top`, `Rack`) | `Top` cobre reorder + draw mode seguro; `Rack` cobre exchange simples de upkeep | parcial forte |
| Battle `Library of Leng` | corrigida no runtime local, incluindo discard por efeito em wheel-like draw | parcial fechado |

## Gaps reais consolidados

### P1 — expandir o trigger de upkeep do Lorehold

Status:

- fechado no slice local para o caso base;
- permanece aberto para enriquecer política de discard e payoff comparativo.

### P1 — consolidar `Lorehold, the Historian` como regra canônica expressiva

Status:

- fechado no dado revisado local e no runtime;
- o guardrail residual é manter compatibilidade com permanentes antigos ainda
  não enriquecidos, sem depender disso como fonte principal.

### P1 — substituir `topdeck_manipulation` genérico por capabilities reais

Necessário separar pelo menos:

- `topdeck_peek_reorder_v1`
- `topdeck_draw_put_self_on_top_v1`
- `hand_to_top_exchange_v1`

Sem isso, o battle sabe que a carta “é de topo”, mas não sabe por que ela muda
o jogo.

Status incremental desta rodada:

- `Top` já cobre `topdeck_peek_reorder_v1` e o primeiro slice de
  `topdeck_draw_put_self_on_top_v1`;
- `Scroll Rack` já cobre o primeiro slice de `hand_to_top_exchange_v1`;
- falta transformar isso em policy genérica por capability, em vez de manter
  o caminho seguro acoplado ao plano do Lorehold.

### P1 — consolidar replacement de `Library of Leng` fora do caso base

Status:

- fechado para os caminhos já modelados de discard por efeito:
  - upkeep rummage do Lorehold;
  - `wheel_resolved` / discard-all-then-draw;
  - helper canônico `resolve_effect_discard_cards(...)`.
- permanece aberto apenas para futuros fluxos de discard que ainda não usam o
  helper canônico.

### P2 — revalidar `Approach + Topdeck` como linha auditável

O deck rationale e relatórios históricos apontam `Approach of the Second Sun`
mais `Sensei's Top`/`Scroll Rack` como linha real.

Isso pede:

- replay de linha controlada;
- prova de que o battle entende essa sequência sem heurística solta;
- decision trace que mostre por que a linha foi escolhida.

## Veredito

O generator já está mais perto da verdade temática do Lorehold do que o battle.

O battle já saiu do estado quebrado, e o descompasso do Lorehold ficou bem mais
estreito. O ponto correto agora é:

- ele já representa e executa o caso base do plano `miracle/topdeck`;
- ele ainda não executa, de forma completa, as peças mais ricas que tornam esse
  plano repetível e forte em partidas longas.

Leitura correta hoje:

- Lorehold já é um bom caso de controle para generator/source mix;
- Lorehold continua sendo um caso parcialmente modelado no battle, mas agora o
  residual está concentrado em:
  - `Scroll Rack` multi-card/full exchange;
  - policy genérica do draw mode do `Sensei's Divining Top`;
  - políticas mais comparativas de discard/topdeck.
