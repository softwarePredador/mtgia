# Battle Rules 2026 Strategic Review

> Data: 2026-06-11  
> Escopo: battle engine, Hermes e gaps de regras para o horizonte prático de 20 dias.  
> Resultado: documentação/matriz atualizadas contra fontes oficiais; sem ampliar escopo para judge engine completo.

## Fontes oficiais verificadas

| Fonte | Fato usado no ManaLoom | Decisão |
|---|---|---|
| `https://magic.wizards.com/en/rules` | Comprehensive Rules atuais apontam para `MagicCompRules 20260417.txt`. | `server/magicrules.txt` deve continuar preso ao snapshot 2026-04-17 até novo update oficial. |
| `https://media.wizards.com/2026/downloads/MagicCompRules%2020260417.txt` | Regras efetivas em 2026-04-17; contém CR 720/721/722, 702.184/702.185, 802 e 903. | Usar como fonte local de teste e auditoria. |
| `https://magic.wizards.com/en/formats/commander` | Commander é 99+1, color identity, command zone, commander tax, 21 commander damage e free-for-all com ataque a múltiplos jogadores. | Produto e Hermes devem tratar multi-defender como Commander normal, não exceção. |
| `https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026` | Hybrid mana não mudou; continua funcionando como "and" para identidade Commander. | Não implementar modelo "or" sem novo update oficial. |
| `https://magic.wizards.com/en/news/feature/edge-of-eternities-mechanics` | Station, Spacecraft, Warp, Void, Lander e Vehicle/Spacecraft commander. | Suporte mínimo está correto; efeitos específicos por carta ficam por corpus. |
| `https://magic.wizards.com/en/news/feature/edge-of-eternities-release-notes` | Release notes detalham station counters, striations e Vehicle/Spacecraft commander. | Usar para regressões quando novas Spacecraft entrarem no corpus. |
| `https://magic.wizards.com/en/news/feature/secrets-of-strixhaven-mechanics` | Prepare, Repartee, Opus, Infusion, Flashback, Increment, Paradigm e Converge. | Ability words entram como telemetria; Prepare/Omen/Paradigm exigem card-specific só quando usados. |

## Status ManaLoom por regra

| Área | Status | Evidência local | Próxima ação |
|---|---|---|---|
| Vehicle/Spacecraft commander | Implemented | `server/lib/commander_eligibility.dart`, `server/test/commander_eligibility_test.dart`, `battle_rules_2026_tests.py` | Manter teste guardião de CR 903.3. |
| Hybrid identity strict | Implemented | `server/test/color_identity_test.dart`, `server/test/magic_rules_source_test.dart`, `battle_rules_2026_tests.py` | Não flexibilizar. |
| Commander attack multiple players | Implemented básico | `assign_attackers_to_defenders`, `battle_rules_2026_tests.py` | Requirements/restrictions avançadas ficam gap separado. |
| Warp | Partial | `cast_warp_spell_from_hand`, `process_warp_end_step`, `cast_warp_card_from_exile` | Adicionar efeitos por carta quando aparecer no corpus real. |
| Station/Spacecraft | Partial | `activate_station_ability`, `battle_rules_2026_tests.py` | Escolha humana e striations múltiplas avançadas ficam backlog. |
| Prepare | Partial | `prepare_spell_copy`, `cleanup_prepared_copies` | Cast completo da cópia preparada por UI/interação fica backlog. |
| Omen | Partial | `get_card_characteristics(..., cast_mode="omen")`, `compute_color_identity` | Omen resolve/shuffle e efeitos específicos entram por carta concreta. |
| Paradigm | Partial | `resolve_paradigm_spell` | Cópia automática em main phase futura fica tracked gap. |
| Flashback | Implemented básico | `cast_flashback_spell_from_graveyard`, `battle_rules_2026_tests.py` | Custo/restrição especial por carta fica card-specific. |
| Lander | Implemented básico | `create_lander_token` | Variantes por carta só quando necessário. |
| Void/Repartee/Opus/Increment/Infusion/Converge | Telemetry | `modern_ability_word_signals` | Não virar enforcement pesado; ability words não têm regra própria. |
| No sideboard/outside-game Commander | Tracked Gap | Produto não expõe sideboard operacional; meta import usa sideboard como fonte de commander em EDH/cEDH. | Revalidar se surgir wishboard/sideboard no app/API. |

## Ordem real de execução

1. Manter documentação e testes guardiões atualizados contra as regras oficiais.  
2. Corrigir apenas gaps que afetem decks reais ou auditorias Hermes.  
3. Priorizar Commander legality e color identity quando houver divergência de produto.  
4. Implementar efeitos card-specific de Warp/Station/Prepare/Omen/Paradigm somente com carta concreta, replay e teste.  
5. Separar battle engine de UX/produto: layout, prova viva e app visual não entram em `IMPLEMENTATION_GAPS.md`.  

## Gaps que ficam fora do horizonte de 20 dias

| Gap | Motivo |
|---|---|
| Judge engine completo de layers/dependencies/replacement APNAP | Alto custo e pouco retorno imediato para recomendação de deck. |
| Escolha humana completa de prioridade/APNAP/replacement | Hermes é simulador heurístico, não mesa interativa completa. |
| Todas as cards de Omen/Prepare/Station/Warp | Deve ser incremental por corpus para evitar falso rigor. |
| Ability words como regra autônoma | Oficialmente são palavras de habilidade; o texto da carta define o efeito. |

## Validação exigida depois de cada mudança nessa área

```bash
cd server && dart analyze bin lib routes test
cd server && dart test test/magic_rules_source_test.dart test/commander_eligibility_test.dart test/color_identity_test.dart test/mtg_rules_validation_test.dart --reporter compact
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -m py_compile battle_analyst_v9.py battle_*_support.py battle_*_tests.py test_battle_analyst_v10_3.py
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_battle_analyst_v10_3.py
```

## Conclusão

O plano atual não exige reescrever a engine agora. O suporte mínimo das regras modernas já existe e está testado; o trabalho correto é manter a matriz honesta, impedir drift de fonte oficial e implementar card-specific somente quando o corpus ou uma falha real justificar.
