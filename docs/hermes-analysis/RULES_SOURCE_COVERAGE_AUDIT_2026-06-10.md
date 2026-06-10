# Rules Source Coverage Audit — ManaLoom Battle Engine

> Data: 2026-06-10
> Escopo: battle engine/Hermes e validação Commander prática.
> Fonte de verdade: documentação oficial Wizards vigente em 2026-06-10.

## Fontes oficiais revalidadas

| Fonte | Uso no ManaLoom | Status |
|---|---|---|
| `https://magic.wizards.com/en/rules` | Fonte canônica para Comprehensive Rules e downloads oficiais. | Referência oficial. |
| `MagicCompRules 2026-04-17` | Base para CR 100-903, incluindo Omen/Station/Preparation. | Referência versionada atual nesta rodada. |
| `https://magic.wizards.com/en/formats/commander` | Commander 99+1, color identity, command zone, commander tax, 21 commander damage e multiplayer free-for-all. | Referência oficial de produto. |
| `Commander Brackets Beta Update 2026-02-10` | Confirma que hybrid mana continua contando como todas as cores da carta no Commander. | Regra documentada como invariável. |
| `Edge of Eternities Update Bulletin` | Station, Warp, Spacecraft e elegibilidade de Legendary Vehicle/Spacecraft com P/T como commander. | Implementado como suporte mínimo. |
| `Secrets of Strixhaven Mechanics` | Prepare, Repartee, Opus, Infusion, Increment, Paradigm, Flashback e Converge. | Implementado como suporte mínimo/telemetria. |

## Cobertura implementada nesta rodada

| Área | Status ManaLoom | Implementação |
|---|---|---|
| Legendary Vehicle/Spacecraft commander | **Implemented/basic** | `DeckRulesService` e `battle_analyst_v9.is_commander_eligible_card`. Exige `legendary`, `vehicle`/`spacecraft` e power/toughness. |
| Hybrid color identity | **Implemented/guarded** | Mantida como identidade combinada, sem flexibilização. Coberta por `color_identity_test.dart` e conformance Hermes. |
| Warp | **Implemented/basic** | Cast por custo alternativo, exílio no end step e recast normal do exile. Não modela texto específico de cada carta. |
| Station/Spacecraft | **Implemented/basic** | `activate_station_ability` adiciona charge counters pelo poder de outra criatura e destrava Spacecraft como criatura. |
| Prepare | **Implemented/basic** | Cria cópia preparada em exile vinculada a uma criatura e remove a cópia quando a criatura é desassociada. |
| Omen | **Implemented/basic** | `get_card_characteristics(..., cast_mode="omen")`; color identity agrega parte Omen e permanente. |
| Flashback | **Implemented/basic** | Cast do graveyard por custo alternativo e exile em resolução/counter. |
| Paradigm | **Implemented/basic telemetry** | Spell resolvida é rastreada em exile como fonte futura de cópia. |
| Lander token | **Implemented/basic** | Token 1/1 artifact creature com marca `lander_token`. |
| Void/Repartee/Opus/Increment/Infusion/Converge | **Implemented/telemetry-only** | `modern_ability_word_signals`; sem enforcement duro. |
| Commander multiplayer attack | **Implemented/basic** | Atacantes podem ser distribuídos entre múltiplos defensores; evento legado `combat` preservado. |

## Fora de escopo deliberado

| Área | Motivo |
|---|---|
| Judge engine completo CR 613/616 | ManaLoom precisa de simulação e análise Commander, não de adjudicação competitiva completa. |
| Escolha humana real para APNAP/replacement/layers | O simulador usa prioridade determinística/heurística. Interação humana completa fica fora do horizonte de 20 dias. |
| Efeitos card-specific de cada Omen/Prepare/Paradigm | Entram por curadoria/battle rule registry quando cards concretos forem usados no corpus. |
| Ability words como regra autônoma | Ability words não têm efeito próprio; ficam como sinal semântico/telemetria. |

## Comandos de validação desta rodada

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_battle_analyst_v10_3.py
```

## Próxima auditoria obrigatória

Antes de qualquer nova implementação de regras, reabrir `https://magic.wizards.com/en/rules` e confirmar se a data efetiva da Comprehensive Rules mudou após `2026-04-17`.
