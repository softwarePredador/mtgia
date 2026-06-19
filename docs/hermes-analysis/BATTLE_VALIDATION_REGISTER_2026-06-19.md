# Battle Validation Register - 2026-06-19

## Objetivo

Este documento e o registro vivo deste chat para validacao especializada do
battle ManaLoom. Use como ponto de entrada para anotar falhas encontradas em:

- `replay.txt` e logs humanos;
- `replay.events.jsonl`;
- `replay.decision_trace.jsonl`;
- auditores `battle_action_critic.py` e `battle_decision_strategy_auditor.py`;
- logica de simulacao, legalidade, alvo, custo, prioridade e aprendizagem.

Regra operacional: toda falha deve ter evidencia concreta antes de virar
implementacao. Nao aplicar swaps, nao alterar PostgreSQL e nao tratar WR ou
replay aprovado como prova absoluta sem auditoria.

## Artefato base desta rodada

- Run manual: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/manual-battle-simulation/20260619_135854/`
- Seed: `786135854`
- Log humano: `replay.txt`
- Eventos estruturados: `replay.events.jsonl`
- Decision trace: `replay.decision_trace.jsonl`
- Action critic desta rodada: `action_critic.json`
- Strategy audit desta rodada: `strategy_audit.json`

Resultado dos auditores atuais:

- `battle_action_critic`: `0` findings, `462` acoes `ok`.
- `battle_decision_strategy_auditor`: `0` findings, verdict
  `usable_for_strategy_learning`.

Conclusao desta rodada: o pipeline atual aprova o replay, mas a inspecao manual
achou lacunas de observabilidade e pelo menos um caso que deveria ser validado
com mais rigor antes de confiar em aprendizagem automatica.

## Achados abertos

| ID | Severidade | Area | Evidencia | Risco | Avaliar / ajustar | Criterio de fechamento |
| --- | --- | --- | --- | --- | --- | --- |
| BV-001 | P1 | `replay.txt` | No turno 1, o texto nao mostra `Sunbillow Verge`, `Dryad Arbor`, `Scrubland` e `Breeding Pool`, embora existam como `land_played` em `replay.events.jsonl`. | O replay humano parece ilegal ou incompleto; um leitor ve `MANA 0` seguido de spell de custo 1. | Renderizar `PLAY LAND` no texto e ordenar a linha de mana/custo para explicar como o spell foi pago. | O turno 1 pode ser auditado pelo `replay.txt` sem abrir o JSONL para descobrir land drops. |
| BV-002 | P1 | Counter / alvo | `Mental Misstep` aparece no JSONL como `end_step_instant` e `spell_resolved` sem `target`, depois de `Sensei's Divining Top` ja ter `spell_resolved`. | O simulador pode estar aceitando counter sem alvo valido, ou o log esta escondendo o alvo/resultado. | Verificar se counterspells sempre registram alvo, objeto na pilha e resultado (`countered`, `fizzled`, `no_legal_target`). | `Mental Misstep` declara alvo e resultado legal, ou o auditor marca finding bloqueante quando nao houver alvo valido. |
| BV-003 | P1 | Auditoria | `battle_action_critic` classificou `Mental Misstep` como `ok` apenas com `rule=curated/verified; effect=counter`, sem evidenciar alvo ou stack legality. | O auditor pode aprovar interacoes reativas invalidas e liberar replay ruim para aprendizagem. | Adicionar regra no action critic: `counter` precisa de alvo/stack object valido ou finding high/critical. | Counter sem alvo, sem stack object, ou resolvido fora da janela correta gera finding. |
| BV-004 | P2 | Custo / mana | `replay.txt` mostra `MANA ... 0 available` antes de casts; o JSONL mostra land drops, mas nao mostra tap/pagamento no texto. | Fica impossivel validar se custos foram pagos corretamente lendo o log humano. | Renderizar `TAP`, `PAY COST`, mana produzida, mana gasta e mana restante para casts relevantes. | Todo `CAST/RESOLVE` de spell com custo no texto tem custo pago rastreavel. |
| BV-005 | P2 | Mudanca de vida | Thrasios comeca em `Life=38`; o JSONL tem `Breeding Pool`, mas o texto nao explica o pagamento de 2 vidas. | Perdas de vida parecem arbitrarias; dificulta auditar shock lands, Phyrexian mana, custos e dano. | Renderizar causa de mudanca de vida: shock land, custo, dano, trigger ou efeito. | Toda mudanca de vida fora de combate aponta causa no `replay.txt`. |
| BV-006 | P2 | Board state | `END ... Board=2` lista apenas contador, sem permanentes. | Decisoes de combate, alvo, mana e engines nao sao auditaveis pelo texto. | Adicionar snapshot resumido de permanentes relevantes no fim do turno, pelo menos lands, criaturas, artifacts/engines e commanders. | O fim do turno permite reconstruir estado essencial sem abrir JSONL. |
| BV-007 | P2 | Spell vs ability | Mais tarde o texto repete `RESOLVE Lorehold: Sensei's Divining Top`; nao fica claro se e cast, trigger ou habilidade ativada. | O log humano mistura resolucao de spell e ability, escondendo regras diferentes. | Diferenciar `CAST`, `ACTIVATE`, `TRIGGER`, `RESOLVE SPELL`, `RESOLVE ABILITY`. | Ativacoes de Top/Scroll Rack/Brainstone nao aparecem como spell cast/resolution ambigua. |
| BV-008 | P2 | Tentativas ilegais | O JSONL registra muitos `cast_illegal` (`cannot_pay_locked_cost`), mas o `replay.txt` omite. | Debug estrategico perde informacao sobre o que o agente tentou e por que nao podia fazer. | Incluir tentativas ilegais relevantes em modo audit/debug, ou pelo menos sumarizar por turno. | Replays auditaveis mostram por que linhas candidatas foram rejeitadas quando isso afeta decisao. |
| BV-009 | P3 | Aprovacao de aprendizagem | Strategy auditor retornou `usable_for_strategy_learning` apesar das lacunas textuais e do counter sem alvo visivel. | A palavra "usable" pode ser interpretada como garantia maior do que ela realmente e. | Separar verdicts: `structured_trace_usable` vs `human_replay_complete` vs `rules_interaction_trusted`. | Relatorios deixam claro qual camada foi aprovada e qual ainda precisa validacao. |

## Checklist para proximas validacoes battle

1. Sempre comparar `replay.txt` contra `replay.events.jsonl`.
2. Para cada `spell_resolved`, confirmar se houve `cast` ou trigger/ability
   correspondente.
3. Para cada `counter`, exigir alvo, stack object, janela de prioridade e
   resultado.
4. Para cada cast com custo, exigir fonte de mana, custo travado e pagamento.
5. Para cada mudanca de vida, exigir causa.
6. Para cada fim de turno, verificar se o board textual permite auditar estado.
7. Nao aceitar `usable_for_strategy_learning` como prova de que o log humano esta
   completo.
8. Quando houver divergencia entre texto e JSONL, o JSONL e a fonte primaria, mas
   o texto deve ser corrigido para nao induzir decisao errada.

## Pontos de implementacao sugeridos

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - revisar emissao de eventos para counter/target/stack object;
  - revisar renderizacao do `replay.txt`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
  - adicionar finding para counter sem alvo valido;
  - adicionar finding para spell/ability resolvida sem evento causal suficiente.
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
  - separar confianca de estrategia da completude do log humano.
- Testes focados:
  - fixture de turno 1 com land drop, spell de custo 1 e counterspell;
  - fixture em que counter tenta resolver sem alvo;
  - fixture de shock land com perda de vida explicita;
  - fixture de habilidade ativada de `Sensei's Divining Top`.

## Relacao com a matriz de tarefas

A task resumida correspondente foi registrada na matriz:

- `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md`
  - task P1: `Replay textual auditavel e coerente com JSONL`.

