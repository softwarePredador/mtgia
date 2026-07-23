# Commander Deckbuilding Contract - 2026-06-29

Status: `frozen_operating_contract`.

Este é o contrato canônico compacto. O diário completo de decisões e pacotes
foi separado, sem perda de bytes, em
`archive/COMMANDER_DECKBUILDING_EVIDENCE_LOG_2026-06-29_TO_2026-07-15.md`.
O diário é evidência histórica; quando houver divergência, este contrato vence.

Battle inputs seguem
`GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`.
`battle_positive_evidence_v1` pode provar exposição ou comparação, mas nunca
autoriza swap. `promotion_allowed` continua falso até o gate estatístico e
estratégico próprio fechar.

Card-rule responde “o runtime executa esta carta corretamente?”. Deckbuilding
responde “o deck tem plano, densidade, legalidade, proveniência e prova?”.

## Operational Refresh - 2026-07-15

PostgreSQL/backend é a verdade de produto. Hermes/SQLite é cache/lab. Decks
incompletos de usuário não podem ser apagados, preenchidos ou reconstruídos
sem intenção do owner. Estrutura pronta, combo existente ou agregado de
batalha isolado não autoriza promoção.

Pacotes com cartas alteradas precisam de exposição natural tipada antes de
qualquer promoção. Forced access é apenas diagnóstico.

## Research-Backed Deck Planning Flow

O fluxo obrigatório é:

1. `format_legality_and_power_bracket`
2. `commander_intent_and_archetype`
3. `primary_and_backup_win_plan`
4. `mana_foundation_and_curve`
5. `card_flow_and_resource_engine`
6. `interaction_protection_and_resilience`
7. `commander_specific_packages`
8. `combo_synergy_and_finishers`
9. `reference_corpus_and_learned_usage`
10. `staple_impact_and_role_policy`
11. `lane_balanced_cuts_and_anchor_protection`
12. `goldfish_battle_replay_iteration`

Regras:

- validar formato, singleton, comandante e identidade de cor antes de otimizar;
- declarar plano principal e alternativo antes dos slots flexíveis;
- construir base de mana, curva e ramp considerando a janela do comandante;
- tratar draw, selection, rummage, tutor e engine como fluxo de recursos;
- preservar interação, proteção, wipes, recuperação e pressão;
- adicionar pacotes específicos do comandante antes de staples genéricos;
- comparar adição e corte na mesma lane ou declarar hipótese de pacote;
- exigir validação legal, matriz, gate e replay para promoção.

Fontes de pesquisa e seus limites:

| Fonte | URL | Uso permitido |
| --- | --- | --- |
| Wizards Commander | https://magic.wizards.com/en/formats/commander | `legal_identity`, singleton e `power_bracket` |
| EDHREC build guide | https://edhrec.com/articles/how-to-build-a-commander-deck | `role_counts_vs_targets` e `battle_and_replay_validation` |
| Command Zone template | https://edhrec.com/articles/the-command-zone-commander-deckbuilding-template-for-the-new-era-the-command-zone-658-mtg-edh-magic-gathering | `ramp`, `card_draw_selection`, `interaction_removal` |
| EDHREC ramp | https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander | `mana_foundation_and_curve` e `curve` |
| EDHREC staples | https://edhrec.com/top | `staple_impact_and_role_policy` e `staple_floor_and_context` |
| BinderBrew | https://binderbrew.com/commander-deck-building-template | `budget_collection_constraints` e `commander_specific_packages` |
| Card Kingdom | https://blog.cardkingdom.com/whats-better-in-commander-card-draw-or-ramp/ | `recursion_recovery` e `card_flow_and_resource_engine` |
| Commander Spellbook | https://commanderspellbook.com/ | `combo_synergy_and_finishers` e `combo_lines` |

Popularidade externa é descoberta, não legalidade, regra de Battle ou
qualidade final. EDHREC synergy é especificidade relativa à identidade de cor,
não score absoluto de carta.

Eventos externos são evidência positiva de limite inferior. Ausência de evento
não prova não uso. Seed XMage igual não é replay byte a byte. Registre engine
commit, processo, coorte, semântica do seed, timeout/censoring e exposição.

## Lane Order And Deck Overview Contract

Ordem canônica de lanes:

1. `legal_identity`
2. `power_bracket`
3. `commander_intent`
4. `win_plan`
5. `mana_base`
6. `ramp`
7. `curve`
8. `card_draw_selection`
9. `tutors_access`
10. `interaction_removal`
11. `protection_resilience`
12. `board_wipes`
13. `recursion_recovery`
14. `commander_synergy_engine`
15. `payoffs_finishers`
16. `combo_lines`
17. `meta_pressure_answers`
18. `budget_collection_constraints`
19. `staple_floor_and_context`
20. `same_lane_cuts`
21. `battle_and_replay_validation`

O diagnóstico `deckbuilding_contract` deve expor:

1. `commander_plan_sentence`
2. `power_bracket_target`
3. `primary_win_lines`
4. `backup_win_lines`
5. `role_counts_vs_targets`
6. `mana_curve_and_sources`
7. `package_lanes_with_key_cards`
8. `source_provenance_by_anchor`
9. `staple_impact_by_role`
10. `protected_anchors_and_cut_rules`
11. `known_risks_and_validation_status`

## Frozen Decision

Há uma pipeline Commander para todos os comandantes:

1. dados e legalidade oficiais;
2. perfil de intenção;
3. corpus externo/de referência;
4. learned deck e uso local;
5. shell legal determinístico;
6. proposta de optimizer/IA;
7. validação, matriz, Battle e replay.

Lorehold não é template universal. O contrato keeps deck `607` as
benchmark/regression only para o aprendizado global e o mantém como baseline
protegido da linha Lorehold.

## Global Commander Rollout - 2026-07-01

Antes de qualquer promoção global:

- `global_commander_deck_contract_audit.py` separa `user_product`,
  `registered_pg_variant`, Hermes/lab e fixtures;
- `global_commander_strategy_matrix.py` escolhe os comandantes com fontes e
  perfil suficientes;
- decks de usuário ambíguos exigem revisão do owner;
- PostgreSQL precisa estar carregado para prontidão de produto.

## Global Commander Core Pivot - 2026-07-05

O aprendizado prioriza core Commander global. Lorehold 607 continua somente
como benchmark/regressão. `global_commander_core_role_audit.py` mede lands,
ramp, draw, removal, wipes, protection, recursion, tutors, wincons e engines.

Gaps produzem hipóteses, não cópias. Nenhuma candidate DB, pacote, forced
access, natural gate ou promoção abre sem source lane, add/cut nomeado,
preservação de floors e exposição. O histórico completo de rotas, reports,
pacotes rejeitados e pivôs está no evidence log arquivado.

## Source Hierarchy

| Fonte | Prova | Não prova |
| --- | --- | --- |
| PostgreSQL/backend | verdade de produto, decks, cartas, legalidade e regras revisadas | qualidade de deck sem gate |
| Dados oficiais/Scryfall/MTGJSON | identidade, Oracle, layout, legalidade e rulings | intenção do comandante |
| EDHREC/corpus público | popularidade, sinergia e referência | regra de runtime ou promoção |
| Learned decks | candidatos e uso local | legalidade atual ou verdade de produto |
| Battle/replay | resultado e exposição positiva | regra individual não exercida |
| XMage/Forge | execução de regras pinada | popularidade, intenção ou qualidade |

## Staple Impact Policy

Classifique:

1. `structural_foundation`;
2. `commander_contextual_staple`;
3. `commander_synergy_candidate`;
4. `generic_or_low_context_signal`.

Use `inclusionRate = num_decks / potential_decks`. Uma staple não corta engine
específica entre lanes. `format_staples` é fonte de candidatos e filtro, não
prova do comandante.

## Required Contract Per Commander

Um comandante só fica deckbuilder-ready com:

- identidade e legalidade resolvidas;
- profile ou fallback explícito;
- targets de lands, ramp, draw, removal, protection, wipes, recursion, tutor,
  wincon e pacotes específicos;
- ao menos uma lane de referência;
- fallback legal determinístico;
- `GeneratedDeckValidationService`;
- proveniência por carta importante;
- matriz de estratégia;
- Battle para mudança estrutural.

Sem corpus confiável, retorne deck conservador e diagnóstico; não finja que
heurística genérica é prova específica.

## Lorehold Current Contract

Intenção:

> Preparar o topo, filtrar a mão e usar o desconto de Lorehold para lançar
> instant/sorcery de alto impacto antes da curva, convertendo a janela em
> finisher determinístico sem morrer para pressão rápida.

Lanes obrigatórias: `early_plan`, `topdeck_miracle_setup`, `hand_filter`,
`spell_chain_conversion`, `protection_window`, `pressure_absorber`,
`graveyard_recursion` e `deterministic_finisher`.

Para o contrato literal, deck `607` is the current protected structural
baseline. A decisão corrente é
keep `607` as protected baseline. `607` tem 100 cartas, um comandante, 34
lands e anchors protegidos. O estado `closed_current_607_champion` bloqueia
novos swaps um-a-um sem cut evidence novo.

O positivo histórico de `candidate_607_v615_mana_engine_v1` foi rebaixado a
`battle_cleared_with_cut_methodology_caveat`; não está
`ready_for_real_deck_change`. O schema de matriz é
`decks[] + ranked_deck_keys`.

## General Deckbuilding Gate

Todo deck Commander gerado/otimizado exige:

1. comandante e tamanho;
2. singleton e legalidade;
3. identidade de cor, incluindo faces/layouts;
4. zero carta não resolvida;
5. targets de papel/pacote;
6. proveniência;
7. zero fanout por join cru;
8. artifact contract;
9. Battle para promoção estrutural;
10. drawn/cast/used ou teste focado para conclusão de carta.

## Lorehold Promotion Gate

Um candidato só substitui 607 se:

- passar a matriz estrutural;
- preservar floors e anchors ou provar reposição same-lane;
- não usar corte cross-lane como prova;
- empatar ou vencer no mesmo conjunto/coorte;
- não regredir pressão rápida, especialmente Winota;
- mostrar topdeck/miracle e spell-chain antes da decisão.

Agregado positivo com matchup crítico regressivo é rejeitado.

## Current Validation Commands

Auditorias read-only:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/commander_deckbuilding_flow_research_audit.py \
  --out-prefix /tmp/manaloom_commander_flow
python3 docs/hermes-analysis/manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py \
  --out-prefix /tmp/manaloom_deckbuilding_contract
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py \
  --out-prefix /tmp/manaloom_lorehold_artifact
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_promotion_gate_decision_audit.py \
  --out-prefix /tmp/manaloom_lorehold_promotion
```

## Stop Rules

Pare se:

- carta forte isolada virar prova de deck;
- agregado sem exposição virar prova individual;
- baseline for trocado sem comparação equivalente;
- popularidade virar legalidade/regra;
- disponibilidade XMage virar inclusão no deck;
- staple global superar intenção/lane;
- carta não resolvida/off-color for reparada silenciosamente;
- artefato histórico for consumido sem
  `lorehold_artifact_contract_audit.py`.

## Next Product Step

Não promova nenhum candidato histórico listado no evidence log. O próximo
trabalho permitido precisa de nova source lane ou cut evidence, add/cut
nomeado, floor preservado, matriz, exposição natural e equal gate. Sem isso,
o resultado continua `keep_607`.
