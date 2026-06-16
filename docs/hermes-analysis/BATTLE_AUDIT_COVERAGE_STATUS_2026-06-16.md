# Battle Audit Coverage Status - 2026-06-16

## Resumo executivo

O battle/Hermes esta consistente para continuar como simulador Commander
heuristico e auditavel. A rodada integrada local mais recente fechou sem
findings `high`/`critical`, sem blockers estrategicos e com todas as categorias
principais marcadas como `coherent_in_sample`.

Isso nao significa que o engine joga Magic perfeitamente. Significa que, na
amostra auditada, as decisoes tomadas pelo simulador agora sao rastreaveis,
explicadas por `decision_trace_v1` e nao apresentam incoerencia critica nos
auditores atuais.

## Fonte de regras e criterio

Regras oficiais usadas como referencia:

- Wizards Comprehensive Rules: <https://magic.wizards.com/en/rules>
- Commander oficial: <https://magic.wizards.com/en/formats/commander>

Politica operacional:

- Regras oficiais definem legalidade.
- Artigos e comunidade so calibram estrategia; nao viram comportamento duro sem
  replay, teste e regra/fontes rastreaveis.
- `needs_review` continua auditavel/report-only.
- WR bruto nao deve alimentar aprendizado sozinho.

## Rodada integrada validada

Artefato local:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260616_041540`

Parametros:

- Seeds: `16`
- Start seed: `61616001`
- Eventos: `17069`
- Decision traces: `2301`
- Action findings: `3`
- Strategy findings: `0`
- Action high/critical seeds: `[]`
- Strategy blocked seeds: `[]`

Resumo dos findings restantes:

```json
{
  "review_rule_used": 3
}
```

Leitura correta: os tres findings restantes sao `low` e indicam uso de regra
`needs_review` em cartas especificas de oponentes. Eles nao quebram a partida,
mas impedem usar essas acoes como evidencia forte de aprendizado ate a regra
ser verificada.

## Melhoria aplicada nesta rodada

Antes da correcao, a mesma rodada de 16 seeds tinha:

- `action_findings`: `90`
- `low`: `72`
- `medium`: `18`
- codigos: `missing_decision_trace`, `missing_game_won`, `missing_turn`,
  `resolve_without_cast`, `review_rule_used`

Depois da correcao:

- `action_findings`: `3`
- `low`: `3`
- `medium/high/critical`: `0`
- unico codigo restante: `review_rule_used`

Correcoes feitas:

- `battle_analyst_v9.py`
  - Eventos sem `turn` agora herdam o turno ativo do replay quando emitidos
    dentro de `play_turn_v8`.
  - `commander_cast` passa a ter `decision_trace_v1` com score, custo efetivo,
    commander tax e motivo.
  - Protecoes usadas em resposta a stack de alta ameaca emitem `spell_cast`
    antes de `spell_resolved`, evitando falso `resolve_without_cast`.
- `battle_replay_v10_3.py`
  - Quando o wrapper detecta vencedor por eliminacao, emite `game_won` com
    `source=replay_wrapper_survivor_inference`.

## Cobertura de decisoes auditadas

Decision traces da rodada validada:

```json
{
  "board_wipe": 3,
  "cast_spell": 418,
  "combat_attack": 287,
  "mulligan_decision": 109,
  "pass_no_action": 1441,
  "response": 8,
  "tutor": 31,
  "wheel": 4
}
```

Outcomes registrados:

```json
{
  "attackers_declared": 287,
  "board_wipe_resolved": 3,
  "cast_and_resolve_ramp": 112,
  "cast_to_stack": 208,
  "commander_cast": 28,
  "counterspell_used": 2,
  "creature_to_battlefield": 70,
  "keep": 64,
  "mulligan": 45,
  "multiplayer_discard_draw_resolved": 4,
  "priority_pass": 1441,
  "protective_response_cast": 6,
  "tutor_target_selected": 31
}
```

Campos obrigatorios do trace:

- `missing_required_like_fields`: `{}`

## Categorias estrategicas

Todas as categorias avaliadas ficaram `coherent_in_sample`:

- mulligan;
- fast mana one-shot;
- Mox Diamond / descarte de land;
- sacrificio de land;
- cast de spell;
- response/counter/protection/removal;
- tutor;
- board wipe / wheel;
- combat attack;
- pass/no-action.

Isso prova coerencia na amostra, nao perfeicao geral. Cada categoria ainda
depende de corpus maior antes de virar heuristica final de aprendizado.

## O que esta sendo auditado corretamente

- Legalidade basica de turno, stack, mana, timing, alvos, ward, combate,
  state-based actions, commander damage e zonas.
- Mulligan nao depende apenas de quantidade de lands: considera plano inicial,
  cores, ramp barato e maos caras mortas.
- Fast mana one-shot nao e gasto apenas por estar disponivel.
- Mox Diamond e custos de land registram risco de ultima land/cor unica e
  exigem payoff contextual.
- Tutor registra alvo, alternativas e motivo por estado de jogo.
- Board wipe/wheel registra assimetria, risco e modelo multiplayer.
- Pass/no-action tem trace explicito.
- Cada replay gera action critic, strategy auditor e research review.

## O que ainda nao esta 100%

### P1 - verificar regras `needs_review`

Restaram 3 findings `review_rule_used` em cartas de oponentes:

- Tayam, Luminous Enigma #25, `spell_cast`, seed `61616005`, turno 5.
- Dargo, the Shipwrecker #74, `spell_cast`, seed `61616012`, turno 13.
- Dargo, the Shipwrecker #74, `spell_resolved`, seed `61616012`, turno 13.

Acao: revisar `card_battle_rules`/oracle dessas cartas, promover apenas se a
regra for trusted/traceable e mantiver teste focado.

### P1 - aumentar corpus

Rodada de 16 seeds e suficiente para validar regressao de instrumentacao. Nao e
suficiente para provar que WR de Lorehold ou qualquer swap e estatisticamente
confiavel.

Acao: rodadas maiores devem registrar baseline id/hash, unknown counts,
sample size e delta com/sem carta vista.

### P2 - decision quality

Ainda faltam refinamentos de qualidade decisoria:

- bottom-card selection do London Mulligan;
- rejected reasons mais ricos para spells jogaveis nao conjuradas;
- threat assessment por permanente/player;
- cleanup CR 514.3a completo;
- upkeep trigger queue generica;
- attack/block restrictions avancadas.

## Conclusao

Estado atual: `PASS_WITH_RISKS`.

O battle esta auditavel e coerente na amostra mais recente. A principal
melhoria objetiva foi reduzir os findings de cobertura de `90` para `3`, sem
alterar estrategia de jogo. O unico risco remanescente da rodada e o uso
pontual de regras `needs_review`, que deve continuar bloqueando aprendizado
forte ate verificacao.

Proximo passo recomendado: tratar os 3 `review_rule_used`, depois rodar corpus
maior com decision-impact metrics antes de usar resultado de battle para
alterar Lorehold ou promover heuristicas.
