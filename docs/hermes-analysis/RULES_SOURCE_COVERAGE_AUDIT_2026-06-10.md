# Rules Source Coverage Audit — ManaLoom Battle Engine

> Data: 2026-06-10
> Escopo: battle engine/Hermes e validação Commander prática.
> Fonte de verdade: documentação oficial Wizards vigente em 2026-06-10.
> Objetivo: manter `IMPLEMENTATION_GAPS.md`, `PENDING_TASKS.md` e a matriz
> Hermes alinhados com regras oficiais, sem tentar transformar ManaLoom em
> judge engine completo.

## Fontes oficiais revalidadas

| Fonte | Uso no ManaLoom | Status |
|---|---|---|
| `https://magic.wizards.com/en/rules` | Fonte canônica para Comprehensive Rules e downloads oficiais. | Referência oficial revalidada em 2026-06-10. |
| `https://media.wizards.com/2026/downloads/MagicCompRules%2020260417.txt` | Base para CR 100-903, incluindo Omen/Station/Preparation. | Referência versionada atual nesta rodada; efetiva em 2026-04-17. |
| `https://magic.wizards.com/en/formats/commander` | Commander 99+1, color identity, command zone, commander tax, 21 commander damage e multiplayer free-for-all com ataque a múltiplos jogadores. | Referência oficial de produto revalidada em 2026-06-10. |
| `https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026` | Confirma que hybrid mana continua contando como todas as cores da carta no Commander; não houve mudança para modelo "or". | Regra documentada como invariável. |
| `https://magic.wizards.com/en/news/announcements/edge-of-eternities-update-bulletin` | Station, Warp, Spacecraft, Lander/Void e elegibilidade de Legendary Vehicle/Spacecraft com P/T como commander. | Implementado como suporte mínimo. |
| `https://magic.wizards.com/en/news/feature/edge-of-eternities-mechanics` | Mecânica operacional de Spacecraft/Station e Warp em linguagem de produto. | Usada para validar o comportamento mínimo do simulador. |
| `https://magic.wizards.com/en/news/feature/secrets-of-strixhaven-mechanics` | Prepare, Repartee, Opus, Infusion, Increment, Paradigm, Flashback e Converge. | Implementado como suporte mínimo/telemetria. |
| `https://magic.wizards.com/en/news/feature/secrets-of-strixhaven-release-notes` | Release notes com detalhes de Prepare, Increment e Paradigm. | Usada para classificar o que é engine mínimo vs card-specific. |

## Taxonomia de status

| Status | Significado prático |
|---|---|
| `Implemented` | Existe lógica executável e teste focado/conformance cobrindo o comportamento mínimo. |
| `Partial` | Existe lógica executável, mas falta escolha humana/interação completa ou efeito específico de carta concreta. |
| `Tracked Gap` | Gap real e conhecido; fica em backlog com ação recomendada e validação necessária. |
| `Out of Scope` | Não é necessário para o horizonte de 20 dias ou exigiria judge engine completo. |

## Cobertura implementada nesta rodada

| Área | Status ManaLoom | Implementação | Próxima ação |
|---|---|---|---|
| Legendary Vehicle/Spacecraft commander | `Implemented` | `commander_eligibility.dart`, `DeckRulesService`, `POST /decks/:id/cards` e `battle_analyst_v9.is_commander_eligible_card`. Exige `legendary`, `vehicle`/`spacecraft` e power/toughness. | Manter teste de regra 903.3/903.12c e rota incremental. |
| Hybrid color identity | `Implemented` | Mantida como identidade combinada, sem flexibilização. Coberta por `color_identity_test.dart` e conformance Hermes. | Não implementar modelo "or" enquanto a Wizards não alterar a regra. |
| Warp | `Partial` | Cast por custo alternativo, exílio no end step e recast normal do exile. | Só adicionar efeitos card-specific quando aparecerem no corpus. |
| Station/Spacecraft | `Partial` | `activate_station_ability` adiciona charge counters pelo poder de outra criatura e destrava Spacecraft como criatura. | Interação humana/escolha de criatura fica fora do mínimo atual. |
| Prepare | `Partial` | Cria cópia preparada em exile vinculada a uma criatura e remove a cópia quando a criatura é desassociada. | Cast completo da cópia preparada fica por carta/corpus. |
| Omen | `Partial` | `get_card_characteristics(..., cast_mode="omen")`; color identity agrega parte Omen e permanente. | Efeito concreto de cada Omen entra no rule registry. |
| Flashback | `Implemented` | Cast do graveyard por custo alternativo e exile em resolução/counter. | Expandir apenas para cartas com custo/restrição especial. |
| Paradigm | `Partial` | Spell resolvida é rastreada em exile como fonte futura de cópia. | Cópia automática na primeira main phase é tracked gap. |
| Lander token | `Implemented` | Token 1/1 artifact creature com marca `lander_token`. | Variantes card-specific só via corpus. |
| Void/Repartee/Opus/Increment/Infusion/Converge | `Implemented` | `modern_ability_word_signals`; sem enforcement duro. | Permanecem telemetria/semântica, não regra autônoma. |
| Commander multiplayer attack | `Implemented` | Atacantes podem ser distribuídos entre múltiplos defensores; evento legado `combat` preservado. | Requirements/restrictions avançadas continuam gap separado. |
| Commander no sideboard/outside-game | `Tracked Gap` | Documentado em `IMPLEMENTATION_GAPS.md`; produto ainda não expõe sideboard operacional. | Validar rotas se algum fluxo futuro adicionar wishboard/sideboard. |

## Separação de backlog

| Tipo | Entra nesta matriz? | Exemplo |
|---|---|---|
| Battle engine / regra executável | Sim | Warp, Station, Prepare, commander damage, targeting formal. |
| Semântica de deckbuilding/IA | Sim, quando afeta melhoria de deck | `functional_tags`, `semantic_tags_v2`, role deltas e quality gate. |
| UX/layout/app visual | Não | Provas visuais, botões, tipografia, estados vazios. Esses itens ficam em `UI_ACTIONABLE_TASKS.md` ou docs QA de UI. |
| Operação Hermes/cron | Só quando valida regra/engine | Timeout, report-only e sync entram como suporte operacional, não como gap de regra. |

## Fora de escopo deliberado

| Área | Motivo |
|---|---|
| Judge engine completo CR 613/616 | ManaLoom precisa de simulação e análise Commander, não de adjudicação competitiva completa. |
| Escolha humana real para APNAP/replacement/layers | O simulador usa prioridade determinística/heurística. Interação humana completa fica fora do horizonte de 20 dias. |
| Efeitos card-specific de cada Omen/Prepare/Paradigm | Entram por curadoria/battle rule registry quando cards concretos forem usados no corpus. |
| Ability words como regra autônoma | Ability words não têm efeito próprio; ficam como sinal semântico/telemetria. |

## Comandos de validação desta rodada

```bash
python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rules_2026_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_battle_analyst_v10_3.py
```

## Próxima auditoria obrigatória

Antes de qualquer nova implementação de regras, reabrir `https://magic.wizards.com/en/rules` e confirmar se a data efetiva da Comprehensive Rules mudou após `2026-04-17`.
