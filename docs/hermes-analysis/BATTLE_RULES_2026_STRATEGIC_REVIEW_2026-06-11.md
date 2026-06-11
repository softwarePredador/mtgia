# Battle Rules 2026 Strategic Review

> Data: 2026-06-11  
> Escopo: battle engine, Hermes e gaps de regras para o horizonte prático de 20 dias.  
> Resultado: documentação/matriz atualizadas contra fontes oficiais; sem ampliar escopo para judge engine completo.
> Rechecagem web: 2026-06-11, usando apenas fontes oficiais Wizards para regra/formato.

## Fontes oficiais verificadas

| Fonte | Fato usado no ManaLoom | Decisão |
|---|---|---|
| `https://magic.wizards.com/en/rules` | Página oficial expõe downloads DOCX/PDF/TXT das Comprehensive Rules atuais. | `server/magicrules.txt` deve continuar preso ao snapshot 2026-04-17 até novo update oficial. |
| `https://media.wizards.com/2026/downloads/MagicCompRules%2020260417.txt` / `.pdf` | Regras efetivas em 2026-04-17; contém CR 720/721/722, 702.184/702.185, 802 e 903. | Usar TXT local para testes automáticos e PDF/TXT oficial como fonte de auditoria. |
| `https://magic.wizards.com/en/formats/commander` | Commander é 99+1, color identity, command zone, commander tax, 21 commander damage e free-for-all com ataque a múltiplos jogadores. | Produto e Hermes devem tratar multi-defender como Commander normal, não exceção. |
| `https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026` | Hybrid mana não mudou; continua funcionando como "and" para identidade Commander. | Não implementar modelo "or" sem novo update oficial. O plano externo citava 2026-02-10, mas a fonte oficial publicada é 2026-02-09. |
| `https://magic.wizards.com/en/news/announcements/edge-of-eternities-update-bulletin` | Update oficial que adiciona Lander `111.10u`, Station Cards `721`, Station `702.184`, Warp `702.185` e Legendary Vehicle/Spacecraft com P/T como commander em `903.3`/`903.12c`. | Fonte primária para números de regra, commander legality moderno e status de conformance. |
| `https://magic.wizards.com/en/news/feature/edge-of-eternities-mechanics` | Explicação operacional de Station, Spacecraft, Warp, Void e Lander. | Fonte suplementar; não substitui o update bulletin para números de regra. |
| `https://magic.wizards.com/en/news/feature/edge-of-eternities-release-notes` | Release notes detalham station counters, striations, Warp e regra de Commander para Vehicle/Spacecraft. | Fonte suplementar para regressões card-specific futuras. |
| `https://magic.wizards.com/en/news/feature/secrets-of-strixhaven-mechanics` | Prepare, Repartee, Opus, Infusion, Flashback, Increment, Paradigm e Converge. | Ability words entram como telemetria; Prepare/Omen/Paradigm exigem card-specific só quando usados. |

## Rechecagem oficial 2026-06-11

- A fonte de verdade continua sendo a página oficial de Rules da Wizards; ela
  aponta para as versões DOCX/PDF/TXT atuais das Comprehensive Rules.
- O snapshot local `server/magicrules.txt` já contém as âncoras guardiãs:
  Omen `720`, Station `721`/`702.184`, Preparation `722`, Warp `702.185`,
  attack multiple players `802`, Commander `903.3`/`903.12c` e hybrid mana em
  `107.4e`.
- A política de Commander permanece estrita para mana híbrida: não aplicar a
  proposta "or" sem update oficial posterior.
- O plano recebido citava o update Commander Brackets como 2026-02-10; a URL e
  artigo oficial disponíveis pela Wizards estão datados como 2026-02-09, então
  toda documentação local usa essa data.
- Vehicle/Spacecraft commander deve ser ancorado no Edge of Eternities Update
  Bulletin, não apenas no artigo de mecânicas, porque o bulletin cita
  explicitamente `903.3`/`903.12c`.
- A lista de gaps abaixo é deliberadamente uma matriz de produto/simulação, não
  uma promessa de judge engine completo.

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

## Status do plano solicitado em 2026-06-11

| Etapa | Status atual | Evidência | Decisão |
|---|---|---|---|
| 1. Documentação e matriz de gaps | Implemented | Este documento, `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md`, `IMPLEMENTATION_GAPS.md`, `PENDING_TASKS.md` | Manter como primeira etapa obrigatória antes de qualquer regra nova. |
| 2. Commander legality 2026 | Implemented | `commander_eligibility.dart`, `commander_eligibility_test.dart`, `magic_rules_source_test.dart` | Não abrir nova implementação salvo drift real. |
| 3. Warp / Flashback / cast-from-exile | Partial mínimo | `battle_rules_2026_tests.py` cobre warp e flashback básicos | Evoluir somente por carta real no corpus. |
| 4. Station / Spacecraft | Partial mínimo | `activate_station_ability`, conformance Station/Spacecraft | Múltiplas striations e escolha humana ficam tracked gap. |
| 5. Prepare / Omen / Paradigm | Partial mínimo | helpers de characteristics/copy/exile tracking | Não implementar efeito genérico pesado sem carta concreta. |
| 6. Multiplayer combat Commander | Implemented básico | `assign_attackers_to_defenders`, evento `multi_defender_attack` | Requirements por defensor e blockers APNAP ficam gap separado. |
| 7. Ability words como telemetry | Implemented como sinal | `modern_ability_word_signals` | Continuar sem enforcement porque ability words não têm texto de regra próprio. |

## O que não deve ser implementado agora

| Pedido possível | Decisão | Motivo |
|---|---|---|
| Implementar todos os textos de Warp/Station/Prepare/Omen/Paradigm genericamente | Não executar | Alto risco de falso rigor; cada carta tem texto próprio e precisa de replay real. |
| Transformar ability words em enforcement global | Não executar | Void/Repartee/Opus/Infusion/Increment/Converge são sinais; o efeito vem do texto da carta. |
| Flexibilizar hybrid mana em Commander | Não executar | Fonte oficial de Commander Brackets confirmou que a regra não mudou. |
| Misturar layout/UX em `IMPLEMENTATION_GAPS.md` | Não executar | Esse arquivo é para battle engine/regras; UI fica em docs de UX/QA. |

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
