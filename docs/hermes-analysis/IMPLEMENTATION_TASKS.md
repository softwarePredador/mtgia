# Implementation Tasks — MTG Knowledge ↔ Code Cross-Reference

> **Gerado:** 2026-06-15
> **Cron:** manaloom-knowledge-synthesis
> **Método:** Cross-referência do conhecimento MTG (skills + logs + SQLite) contra código Dart vivo
> **Skills carregados:** manaloom-mtg-strategy (v1.1.0) — manaloom-mtg-domain não encontrado
> **Base de conhecimento:** SCOUT_LOG, VALIDATOR_LOG, MANA_BASE_VALIDATION_REPORT, GAME_CHANGERS.md, THEMES.md, LOGIC_COHERENCE_REPORT, STRUCTURE_AUDIT.md, SQLite knowledge.db (15 tabelas)
> **Branch:** codex/hermes-analysis-docs
> **HEAD:** 565b73af
> **Metodo:** Cruzamento do conhecimento MTG (VALIDATOR_LOG 2026-06-02 — pipeline integrity crisis + CMC corruption, GAME_CHANGERS.md — 53 GCs com double-counting detectado, SCOUT_LOG — Lorehold maturity, TAG_ACCURACY — payoff 35% accuracy) com codigo Dart (edh_bracket_policy, optimization_quality_gate, optimization_functional_roles, goldfish_simulator)
> **Base de conhecimento:** VALIDATOR_LOG (deck rebuild + 37 CMCs corrompidos + 20 unknown tags + only 3 removals), GAME_CHANGERS (53 GCs com 23 double-tagged), tag_accuracy (payoff 35%, enabler 50%), SCOUT_LOG (deck em maturidade persistente)
> **Novas tasks nesta execucao:** 5 (1xP1, 4xP2) — Game Changer double-counting fix, payoff tag accuracy improvement, contextual enabler/payoff heuristics, goldfish CMC validation hardening, GC list sync mechanism
> **Atualizacao Codex 2026-06-06:** P1 Game Changer double-counting foi reavaliado contra o codigo vivo. A politica atual preserva `gameChanger` + papeis secundarios (`fastMana`, `tutor`, `freeInteraction`, `infiniteCombo`) para diagnostico e budgets multi-tag; testes em `server/test/optimize_runtime_support_test.dart` e `server/test/edh_bracket_policy_test.dart` cobrem Mana Vault, Demonic Tutor, Force of Will e Thassa's Oracle.
> **Atualizacao Codex 2026-06-06:** P2 payoff/enabler contextual resolvido em `server/lib/ai/optimization_functional_roles.dart`; testes em `server/test/optimization_quality_gate_test.dart` cobrem spellslinger, aristocrats e tokens.
> **Atualizacao Codex 2026-06-06:** P2 goldfish CMC hardening resolvido em `server/lib/ai/cmc_safety.dart`; `GoldfishSimulator`, `OptimizationValidator` e `OptimizationSwapGate` agora recuperam CMC pelo `mana_cost` quando o CMC bruto esta corrompido e tratam CMC desconhecido non-land como custo alto, nunca como carta gratis.
> **Atualizacao Codex 2026-06-06:** P2 Game Changer drift guard resolvido com bloco Dart gerado a partir do SQLite, script `docs/hermes-analysis/manaloom-knowledge/scripts/sync_game_changers_to_dart.py --check` e teste cobrindo lista com 53 entradas + nome MDFC de Tergrid.
> **Atualizacao Codex 2026-06-09:** P1 Job Polling NULL `user_id` resolvido no backend. `OptimizeJob` e `AiGenerateJob` agora usam `userId` non-nullable no modelo, rows legadas com `user_id=NULL` viram owner vazio e os pollers `/ai/optimize/jobs/:id` e `/ai/generate/jobs/:id` retornam 404 para jobs sem dono ou de outro usuario. `AiGenerateJobStore.create` exige `required String userId`, e a rota async de generate retorna `Authentication required` antes de criar job sem usuario. Testes: `ai_optimize_authorization_source_test.dart`, `ai_generate_job_authorization_source_test.dart`, `ai_generate_performance_support_test.dart`.
> **Atualizacao Codex 2026-06-16:** Achados recentes da branch `codex/hermes-analysis-docs` foram revalidados contra o codigo vivo antes de qualquer merge. Implementado o slice seguro: Underworld Breach agora consome `infiniteCombo`, Narset/GAA IV e heuristicas de tax/draw-hate entram em `stax`, Consecrated Sphinx/Field of the Dead/Smothering Tithe/The One Ring entram em `valueEngine`, rituais simples como Seething Song/Pyretic Ritual recebem `ritual`, e `GoldfishSimulator` deixou de contar terrenos que entram tapped como mana disponivel no mesmo turno. Testes focados: `edh_bracket_policy_test.dart`, `functional_card_tags_test.dart`, `optimize_runtime_support_test.dart`, `goldfish_simulator_test.dart`, `optimization_validator_test.dart`, `optimization_quality_gate_test.dart`.
> **Atualizacao Codex 2026-06-16 — pendencias nao incorporadas neste slice:** `CandidateQualityData.edhrecInclusionPct` permanece P1, mas exige schema/fonte versionada (`card_meta_insights`/EDHREC cache) e ponderacao calibrada; nao deve ser improvisado com campo opcional sem backfill. A ampliacao de categorias para Notion Thief/Orcish Bowmasters/Glacial Chasm/Humility permanece P2 ate existir matriz de expected categories + testes.

### [P1][OBSOLETO/RESOLVIDO COMO MULTI-TAG] Bracket Policy: double-counting de Game Changers

**Status em 2026-06-11:** OBSOLETO como tarefa de implementacao. A premissa "somente `gameChanger`" foi substituida pela estrategia multi-tag: cartas oficiais Game Changer preservam `gameChanger` e tambem papeis mecanicos secundarios. Isso e usado como diagnostico/budget de risco, nao como erro de regra. Nao alterar o codigo para early-return exclusivo sem nova decisao de produto.

**Evidencia viva:**
- `server/test/optimize_runtime_support_test.dart` — `preserves secondary tags for official Game Changers` espera `gameChanger` + papel secundario.
- `server/test/optimize_runtime_support_test.dart` — `game changer budget also consumes secondary role budgets` valida budget multi-tag.
- `server/test/edh_bracket_policy_test.dart` — `keeps official gamechanger names tagged without suppressing roles`.

**Conclusao operacional:** manter esta secao apenas como historico do problema original. A acao recomendada antiga abaixo nao deve ser executada.

**Conhecimento historico original:** esta tarefa nasceu de uma leitura inicial de que Game Changers deveriam consumir apenas budget de GC. A politica atual do ManaLoom divergiu disso de proposito: `gameChanger` e uma tag oficial, mas papeis secundarios continuam preservados para explicar risco funcional e limitar concentracao de fast mana/tutor/free interaction quando a decisao de produto assim exigir.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:405` — Underworld Breach em `officialGameChangerNamesForBracketPolicy` → recebe `gameChanger`.
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` só tem `thassa's oracle`, `demonic consultation`, `tainted pact`. **Underworld Breach AUSENTE**.
- `server/lib/edh_bracket_policy.dart:162-164` — `tagCardForBracket()` usa `_knownInfiniteComboPieces.contains(n)` para `infiniteCombo`. Breach nunca recebe esta tag.

**Gap:** Underworld Breach é detectado como GC mas não como peça de combo infinito. Orçamento `infiniteCombo` não o contabiliza.

**Impacto:** Bracket 3 (infiniteCombo=2): deck com Breach + Oracle + Consultation conta como 1 combo piece (Oracle) em vez de 2. GAMECHANGER_RESEARCH_REPORT.md Lacuna 3 confirma: `det=1` mascara cegueira do sistema.

**Gap historico:** `tagCardForBracket()` acumula categorias. Isso era tratado como bug, mas agora e comportamento esperado e coberto por teste.

**Impacto atual:** Nenhuma acao de codigo pendente neste item. Qualquer alteracao para `gameChanger` exclusivo deve passar por nova decisao de produto e nova matriz de testes.

**Risco atual:** Reabrir esta tarefa automaticamente criaria regressao contra os testes multi-tag atuais.

**Acao recomendada antiga (NAO EXECUTAR sem nova decisao):**
1. Em `tagCardForBracket()`: se a carta esta em `_gameChangerNames`, retornar somente `{BracketCategory.gameChanger}`.
2. OU: apos todos os checks, se `categories.contains(BracketCategory.gameChanger)`, remover as outras categorias.
3. Atualizar `applyBracketPolicyToAdditions()` para tratar GCs como categoria exclusiva.
4. Adicionar teste unitario confirmando que Mana Vault retorna somente `gameChanger`.

**Validacao:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## [P1] Goldfish simulator trata terrenos tapped como untapped

**Conhecimento MTG:** Muitas non-basic lands entram tapped (Temples, bounce lands, check lands). VALIDATOR_LOG v3.23: deck Lorehold com 2/33 basics. Tapped = mana atrasada 1 turno. Domínio §13 Gap 9 confirma: T3 reportado é melhor que o real.

**Evidência no código:**
- `server/lib/ai/goldfish_simulator.dart:258-261` — `_isLand()` só checa typeLine.
- `server/lib/ai/goldfish_simulator.dart:352-367` — `_playLandIfPossible()` sempre incrementa `landsPlayed`, sem verificar `enters tapped` no oracle text.
- `server/lib/ai/goldfish_simulator.dart:328-349` — `_canPlayOnTurn()` assume todas as terras untapped.
- `server/lib/ai/optimization_validator.dart:98-114` — Monte Carlo usa GoldfishSimulator, propagando o erro.

**Gap:** Nenhum terreno é "tapped on entry". `turn1PlayRate`, `noPlayTurn3Rate` incorretos.

**Impacto:** Otimizador aceita swaps que pioram tempo de mana. Relatórios superestimam consistência.

**Risco:** P1 — Superestimação sistemática da performance early-game.

**Ação recomendada:** Adicionar verificação de oracle text em `_playLandIfPossible()`: se oracle contém `enters the battlefield tapped` ou `enters tapped`, não incrementar `landsPlayed` neste turno.

**Validação:**
```bash
cd server && dart test test/goldfish_simulator_test.dart && dart analyze lib/ai/goldfish_simulator.dart
```

---

## [P1] `classifyOptimizationFunctionalRole()` ignora functional_tags persistidas

**Conhecimento MTG:** Prioridade documentada: persisted tags → semantic_v2 → heuristic. Pipeline precisa de classificação consistente.

**Evidência no código:**
- `server/lib/ai/functional_card_tags.dart:455-465` — `summarizeFunctionalTagsForDeck()` prioriza `persistedTags` corretamente.
- `server/lib/ai/optimization_functional_roles.dart:55-85` — `classifyOptimizationFunctionalRole()` usa `_classifySemanticV2FunctionalRole()` como fonte principal, **ignorando `functional_tags` persistidas**.
- `server/lib/ai/optimization_functional_roles.dart:37-91` — `CardRoles.resolveCardFunctionalRoles()` existe como adapter unificado mas `classifyOptimizationFunctionalRole()` não o usa.

**Gap:** Adapter `CardRoles` existe mas não é usado pelo classificador principal do optimize.

**Impacto:** Mesma carta pode ter `draw` em deck analysis e `utility` no quality gate. LOGIC_COHERENCE_REPORT flagrou como P1.

**Risco:** P1 — Drift de classificação entre estágios do pipeline.

**Ação recomendada:** Modificar `classifyOptimizationFunctionalRole()` para usar `CardRoles.resolveCardFunctionalRoles()` internamente, passando `functionalTags` primeiro.

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart
```

---

## [P1] `CandidateQualityData` sem taxa de inclusão EDHREC

**Conhecimento MTG:** % de inclusão EDHREC é sinal critical. Sol Ring 90.5%, Arcane Signet 88.1%. Metodologia SKILL.md §2.2 exige avaliar inclusão antes de swap.

**Evidência no código:**
- `server/lib/ai/candidate_quality_data_support.dart` — Schemas para `card_function_tags`, `card_role_scores`, `commander_card_synergy`. Sem `edhrecInclusionPct`.
- `server/lib/ai/commander_fallback_policy.dart` — Só usa `meta_deck_count` (EDHTop16 torneios).
- `server/lib/ai/optimize_filler_loader_support.dart` — Sem ponderação EDHREC.
- Busca por `edhrec_inclusion` em server/lib: **0 resultados**.
- Domínio §13 Gap 1: "CandidateQualityData não tem edhrec_inclusion_pct."

**Gap:** Sistema cego para o sinal mais usado pela comunidade Commander.

**Impacto:** Não distingue staple 40%+ de nicho 0%. Swap pode cortar staple em favor de lixo.

**Risco:** P1 — Decisões de otimização sem referência de popularidade/prova social.

**Ação recomendada:**
1. Adicionar `edhrecInclusionPct` a `CandidateQualityData`.
2. Popular de `card_meta_insights` (PG) ou `edhrec_rank` no cache.
3. Ponderar score: `role_match * 0.6 + edhrec_pct * 0.4`.

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart
```

---

## [P2] `_knownValueEngineNames` muito restrito (5 nomes)

**Conhecimento MTG:** Value engines geram vantagem recorrente. GCs como Consecrated Sphinx, Field of the Dead, Smothering Tithe e The One Ring são value engines clássicas.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:541-547` — Só 5 nomes: seedborn muse, tergrid, bolas's citadel, sensei's divining top, aetherflux reservoir.
- Consecrated Sphinx (line 363), Field of the Dead (line 370), Smothering Tithe (line 398), The One Ring (line 403): no GC list, NOT in value engines.
- `_looksLikeGameChangerCardAdvantage()` detecta alguns como `cardAdvantage` — categoria separada.
- GAMECHANGER_RESEARCH_REPORT.md Lacuna 2: Field of the Dead com falso positivo `fastMana` quando deveria ser `valueEngine`.

**Gap:** 4 GCs value engine não recebem categoria `valueEngine`. Orçamento `valueEngine` sub-notificado.

**Impacto:** Bracket 3 (valueEngine=6): Sphinx + Field + Ring sem consumir budget value engine. Só `gameChanger` (limite 3).

**Risco:** P2 — Imprecisão semântica. Mitigado por detecção `gameChanger`, mas categoria funcional perdida.

**Ação recomendada:**
```dart
const _knownValueEngineNames = <String>{
  'seedborn muse', 'tergrid, god of fright', 'bolas\'s citadel',
  'sensei\'s divining top', 'aetherflux reservoir',
  'consecrated sphinx', 'field of the dead', 'smothering tithe', 'the one ring',
};
```

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## Summary

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 1 | **P0** | Underworld Breach ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351,405` | 🔴 Quebra |
| 2 | **P1** | Goldfish trata tapped lands como untapped | `goldfish_simulator.dart:258-261,352-367` | 🟡 Incoerência |
| 3 | **P1** | classifyOptimizationFunctionalRole ignora persisted tags | `optimization_functional_roles.dart:55-85` | 🟡 Incoerência |
| 4 | **P1** | CandidateQualityData sem EDHREC inclusion | `candidate_quality_data_support.dart` | 🟡 Incoerência |
| 5 | **P2** | _knownValueEngineNames muito restrito (5→9) | `edh_bracket_policy.dart:541-547` | 🟢 Melhoria |

**Atualizacao Codex 2026-06-16:** RESOLVIDO para o slice operacional seguro.
`server/bin/auto_promote_learned_decks.py` agora cria/atualiza o schema
`deck_promotions` de forma idempotente, suporta o schema Hermes reduzido sem
`decks.commander_id`, e só grava promoção quando o deck alvo materializado tem
contagem compatível e `migration_verified=1`. `auto_sync_learned_decks.py` e
`export_hermes_learned_deck.py` passaram a ignorar promoções não verificadas
quando a coluna `migration_verified` existe. No Hermes AWS, o script corrigido
compilou e rodou contra o `knowledge.db` operacional: criou a tabela
`deck_promotions`, promoveu `0` decks e classificou candidatos não-Lorehold como
`no_target_deck`, evitando dados fantasmas. O status antigo do job no
`jobs.json` só será limpo na próxima execução agendada do scheduler.

**Conhecimento MTG:** O Commander Knowledge Deep Report S44 (2026-06-05) documenta uma crise de integridade de dados: o Multi-Commander Evolution promoveu 4 decks em 24 minutos (2026-06-04), mas NENHUM teve as cartas migradas completamente:
- Winota: claim=100, actual=85 (-15)
- Atraxa: claim=100, actual=91 (-9)  
- Kinnan: claim=100, actual=13 (-87)
- Korvold: claim=90, actual=11 (-79)

- **SQLite knowledge.db:** 15 tabelas (sem game_changers, sem tag_accuracy — conf. schema documentado)
- **card_oracle_cache GCs:** 28/31 amostrados (90.3%)
- **card_oracle_cache oracle_text vazio:** 4 cartas (Birds of Paradise DFC, Dwarven Trader, Memnite, Phyrexian Walker)
- **Deck 6 (Lorehold) tags:** ramp=41, draw=16, removal=7, protection=6, board_wipe=2, wincon=2 — perfil cEDH

---

## New Tasks (2026-06-15 — Cron #12, Execution #2)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 6 | **P1** | Grand Arbiter Augustin IV e Narset fora de `_looksLikeGameChangerStax` | `edh_bracket_policy.dart:493-518` | 🟡 Incoerência |
| 7 | **P1** | `_looksLikeRitual` não captura "Add {mana}" simples (Seething Song, Pyretic Ritual) | `functional_card_tags.dart:870-877` | 🟡 Incoerência |
| 8 | **P2** | Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility sem sub-categoria bracket | `edh_bracket_policy.dart:354-408,493-547` | 🟢 Melhoria |
| 9 | **P2** | Cobertura de teste bracket policy para Narset stax, GAA IV stax, Underworld Breach infiniteCombo | `edh_bracket_policy_test.dart` | 🟢 Melhoria |

### [P1] Grand Arbiter Augustin IV e Narset, Parter of Veils ausentes de `_looksLikeGameChangerStax`

**Conhecimento MTG:**
- **Narset, Parter of Veils** — "Each opponent can't draw more than one card each turn." Wheel hate/stax de card advantage. GC oficial.
- **Grand Arbiter Augustin IV** — "Spells your opponents cast cost {1} more to cast." Tax stax clássico. GC oficial.
Ambos restringem oponentes passivamente como Drannith Magistrate e Winter Orb, mas não são detectados pelo bracket policy como stax.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:493-518` — `_looksLikeGameChangerStax()` tem lista curada de ~10 nomes (`drannith magistrate`, `opposition agent`, `grand abolisher`, `winter orb`, `static orb`, `torpor orb`, `rule of law`, `deafening silence`, `eidolon of rhetoric`, `ethersworn canonist`, `archon of emeria`). **NÃO inclui** `grand arbiter augustin iv` nem `narset, parter of veils`.
- As heurísticas de oracle text detectam "can't cast more than one spell" e "creatures entering...don't cause abilities" — mas NÃO detectam "can't draw more than one card" (Narset) nem "cost more to cast" (GAA IV).

**Gap:** Ambos recebem apenas `gameChanger` genérico. Bracket 2 (max 1 stax) permite Narset + 1 stax real sem exceder budget.

**Impacto:** Budget de stax sub-notificado para dois GCs muito jogados (Narset: 207k+ decks EDHREC).

**Risco:** P1 — Stax density pode ser maior que o reportado.

**Ação recomendada:**
1. Adicionar `'narset, parter of veils'` e `'grand arbiter augustin iv'` à lista curada em `_looksLikeGameChangerStax()` (linhas 495-505)
2. Adicionar heurística de oracle text: `"can't draw more than one card"` para draw-hate stax
3. Adicionar heurística de oracle text: `"spells your opponents cast cost"` para tax stax (cobre GAA IV, God-Pharaoh's Statue, etc.)

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

### [P1] `_looksLikeRitual` não captura "Add {mana}" simples — Seething Song, Pyretic Ritual

**Status em 2026-06-11:** RESOLVIDO no código backend/app-facing e no código
operacional Hermes; PENDENTE apenas a execução do sync no AWS com `knowledge.db`
populado.
`resolveImportCardNames(...)` agora carrega `cards.cmc`; `GeneratedDeckValidationService`
propaga esse campo internamente e emite warning para CMC não-terreno
ausente/zerado suspeito; `CardValidationService.validateDeckCards(...)`
compara CMC informado contra `cards.cmc`; `DeckRulesService._loadCardsData(...)`
passou a consultar `cmc`. `sync_pg_card_metadata_to_hermes.py` agora faz
backfill de `deck_cards.cmc/type_line/oracle_text` a partir de
`card_oracle_cache`, `import_lorehold_decks.py` prefere esse cache autoritativo
e as crons `known_cards_*` executam o sync antes de operar.

**Conhecimento MTG:** O TAG_ACCURACY_REPORT (2026-06-05) documenta que 142 cartas (26.2%) tem CMC=0.0. A corrupcao se espalhou de 1 deck para TODOS os 7. Cartas como Sol Ring (CMC=1), Mana Vault (1), Boros Signet (2), Aetherflux Reservoir (4) estao com CMC=0.0. Atraxa (deck 9, 100 cartas) importada com 29 CMCs invalidos.

**Evidencia no codigo:**
- `server/lib/ai/cmc_safety.dart` — fallback conservador já recupera CMC por `mana_cost` e evita tratar non-land desconhecido como grátis.
- `server/lib/generated_deck_validation_service.dart` — emite warning de CMC suspeito no fluxo de validação de decks gerados/importados.
- `server/lib/card_validation_service.dart` — compara CMC informado contra `cards.cmc` no validador genérico.
- `server/lib/deck_rules_service.dart` — `_loadCardsData()` agora consulta `cmc`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py` — backfill idempotente de `deck_cards` a partir do cache PG.
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_pg_card_metadata_to_hermes.py` — prova backfill e dry-run em SQLite in-memory.

**Gap remanescente:** Executar a rotina no Hermes/AWS após popular `knowledge.db`
com decks reais; o report precisa mostrar `deck_cards_table_present=true` e
`suspicious_nonland_zero_cmc_after=0` para o corpus alvo.
**Impacto:** P1 — GoldfishSimulator, quality gate, e mulligan usam CMC corrompido.
**Risco:** P1 — Se o SQLite Hermes ficar desatualizado, crons de mulligan/optimizer podem continuar usando CMC local corrompido.

**Acao recomendada:**
1. ~~Adicionar `cmc` ao SELECT em `_loadCardsData()`~~
2. ~~Carregar `cmc` no resolver de nomes usado por import/deck generation~~
3. ~~Emitir warning app-facing quando CMC resolvido for suspeito~~
4. ~~Criar rotina Hermes para corrigir SQLite local e scripts Python de importação aprendida~~
5. Rodar a rotina no Hermes/AWS com DB populado e anexar o report operacional

**Validacao:**
```bash
cd server && dart test test/generated_deck_validation_service_test.dart test/cmc_safety_test.dart
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_sync_pg_card_metadata_to_hermes.py
```

---

### [P2] Tag Accuracy: Adicionar tracking de precisao para as 12 novas tags finas — 45% da taxonomia sem cobertura

**Conhecimento MTG:** TAG_ACCURACY_REPORT documenta fork no sistema de tags: 12 novas tags finas (token_maker, big_spell, aristocrat_payoff, etc.) sem entrada em `tag_accuracy`. 5 tags legadas orfas (0 cartas). `tag_accuracy` congelado desde 2026-05-27 (9 dias).

**Evidencia no codigo:**
- `functional_card_tags.dart:38-54` — `deckAnalysisMainFunctionalBuckets` INCLUI tags finas.
- `candidate_quality_data_support.dart:343-365` — Mapeia fine→legacy via switch-case.
- MAS: `rg "tag_accuracy" server/lib/` → ZERO resultados.

**Gap:** 12 tags operam sem metricas de qualidade. Sistema de auto-healing nao pode funcionar sem saber quais tags monitorar.
**Impacto:** P2 — Precisao das novas tags e desconhecida.
**Risco:** P2 — Fork de tags pode crescer descontroladamente.

**Acao recomendada:**
1. Atualizar `tag_accuracy_reporter.py` para detectar novas tags e criar entradas em `tag_accuracy`
2. Validacao cruzada com PG `card_function_tags` como fonte de verdade

**Validacao:**
```bash
python3 -c "import sqlite3; conn = sqlite3.connect('docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db'); new = conn.execute('SELECT DISTINCT dc.functional_tag FROM deck_cards dc WHERE dc.functional_tag NOT IN (SELECT tag_name FROM tag_accuracy) AND dc.functional_tag IS NOT NULL AND dc.functional_tag != \"unknown\"').fetchall(); print(f'Untracked tags: {len(new)} (target: 0)')"
```

---

### [P2] Quality Gate: Adicionar deteccao de densidade de stax como atributo estrutural — Winota 14 stax pieces

**Conhecimento MTG:** Commander Deep Report S44.4: Winota tem 14 stax pieces (~16.5% das nao-lands). Domain Skill Gap 3: stax e uma das 7 categorias GC faltando. Quality gate trata Winota como "aggro" generico.

**Evidencia no codigo:**
- `optimization_quality_gate.dart:346-353` — `_criticalRolesForArchetype()` sem case 'stax'.
- `functional_card_tags.dart:16-36` — `_taggableRoleNames` NAO inclui 'stax'.
- `theme_contextual_rules_service.dart` — NAO tem tema 'stax' ou 'hatebears'.

**Gap:** Quality gate cego a stax. Swaps que removem stax pieces nao sao bloqueados.
**Impacto:** P2 — Pipeline pode cortar stax pieces de Winota.
**Risco:** P2 — Afeta decks com stax density > 10%.

**Acao recomendada:**
1. Adicionar 'stax' ao `_taggableRoleNames`
2. Heuristica de deteccao: oracle text com "can't" + "opponent"
3. `_criticalRolesForArchetype`: case 'stax' → {'stax', 'creature', 'protection', 'ramp'}
4. Metrica `staxDensity` e flag `heavyStax` quando > 0.15

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_quality_gate.dart && dart analyze lib/ai/functional_card_tags.dart
```

---

### [P2] Optimization Validator: Adicionar deteccao de split archetype — Atraxa 3 sub-arquetipos (infect + superfriends + counters)

**Conhecimento MTG:** Commander Deep Report S44.3: Atraxa tem 3 sub-arquetipos competindo: infect (~8), superfriends (~6), counters (~10). 0 board wipes, 3 protection em bracket 4.

**Evidencia no codigo:**
- `optimization_validator.dart:28-86` — Sem deteccao de split archetype.
- `optimization_functional_roles.dart:55-124` — Classifica cartas individualmente, sem visao de cluster.
- `theme_contextual_rules_service.dart` — Nao detecta multiplos sub-temas.

**Gap:** Validator avalia metricas mas nao a coerencia estrategica. Deck pode ter metricas perfeitas mas ser injogavel por split archetype.
**Impacto:** P2 — Falso positivo "deck saudavel". Swaps podem piorar o split.
**Risco:** P2 — Afeta qualquer deck goodstuff com multiplos mini-temas.

**Acao recomendada:**
1. `_detectArchetypeFocus()` no validator: agrupar por functional_tag fino, detectar clusters >=5 cartas
2. `ValidationReport.archetypeFocus` com `isSplitArchetype` flag
3. Quality gate: se split, priorizar swaps que consolidam
4. Alerta "Deck has N competing sub-archetypes"

**Validacao:**
```bash
cd server && dart analyze lib/ai/optimization_validator.dart && dart test test/ai/optimization_validator_test.dart
```

## Resumo de Tasks Novas (2026-06-05 @ 3f7266d6 — Cron #10)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Deck Promotion: Adicionar verificacao de migracao de cartas pos-promocao | Commander Deep Report S44 (4/4 promotions failed) |
| 2 | P1 | CMC Batch Correction: Script para corrigir 142 cartas + hardening `_getCmc()` | TAG_ACCURACY_REPORT (CMC=0.0 spread to 26.2%) |
| 3 | P2 | Tag Accuracy: Adicionar tracking para 12 novas tags finas (45% sem cobertura) | TAG_ACCURACY_REPORT (tag system fork) |
| 4 | P2 | Quality Gate: Adicionar deteccao de densidade de stax como atributo estrutural | Commander Deep Report S44.4 (Winota 14 stax) |
| 5 | P2 | Optimization Validator: Adicionar deteccao de split archetype (Atraxa 3 sub-arquetipos) | Commander Deep Report S44.3 (Atraxa infect+superfriends+counters) |

> **Nota:** Tasks #1 e #2 sao correcoes de integridade de dados — a base de conhecimento esta corrompida (promotions sem cartas, CMCs zerados). Estas tasks DESBLOQUEIAM as tasks de analise (Atraxa, Winota) que dependem de dados completos.
> **Nota:** Task #3 complementa a task P2 pendente "Tag Accuracy Auto-Healing" (Cron #7) — enquanto aquela foca em melhorar precisao de tags existentes, esta garante que as NOVAS tags tambem sejam monitoradas.
> **Nota:** Tasks #4 e #5 abordam gaps de classificacao de arquetipo — o quality gate atual so reconhece aggro/control/midrange/combo. Stax e split archetype sao dimensoes novas que o sistema precisa entender.

---


### [P1] Deck Import: Adicionar validacao de completude — verificar que o numero de cartas importadas corresponde ao total esperado (previne pipeline operando sobre decks fantasmas)

**Atualizacao Codex 2026-06-11:** PARCIALMENTE RESOLVIDO na camada Hermes/local. Foi adicionado guard compartilhado em `docs/hermes-analysis/manaloom-knowledge/scripts/learned_deck_completeness.py`; `generate_known_cards.py` ignora learned decks com menos de 90 cartas; `materialize_learned_deck_to_deck_cards.py` deixa de preencher decks parciais com terrenos basicos por padrao; `export_hermes_learned_deck.py` bloqueia export parcial e normaliza lista main-99 + comandante; `import_lorehold_decks.py` so aceita deck Commander completo. O backend PG de learned decks ja possui gate forte em `server/lib/ai/commander_learned_deck_support.dart` (100 total, 1 comandante, 99 main). Ainda nao foi adicionada coluna `import_completeness` em `decks`, pois isso exigiria migracao/schema separado.

**Conhecimento MTG:** O Commander Knowledge Deep S42-43 (2026-06-05) documenta que 3 dos 8 decks no SQLite estao gravemente incompletos:
- Korvold, Fae-Cursed King: 11/100 cartas importadas (89 cartas faltando)
- Kinnan, Bonder Prodigy: 13/100 cartas importadas (87 cartas faltando)
- Teysa Karlov: 80/100 cartas (20 faltando, EDHREC aggregate parcial)

Os decks Korvold e Kinnan sao funcionalmente INUTEIS para qualquer analise — tem apenas 11-13 cartas seed de um deck de 100. No entanto, o sistema os trata como decks validos: aparecem no MANA_BASE_VALIDATION_REPORT como "INCOMPLETE", sao consultados por crons, e o Multi-Commander Evolution precisou aprender a filtra-los manualmente. O Mana Base Validator reporta "INCOMPLETE (<50 cards)" mas isso e um diagnostico pos-falha — o sistema nao impede a importacao parcial e nao alerta no momento da importacao.

**Evidencia no codigo:**
- `server/lib/deck_rules_service.dart:412-447` — `_loadCardsData()` consulta cartas do PG mas **nao valida** se o numero de cartas retornadas corresponde ao `total_cards` esperado.
- `server/lib/card_validation_service.dart:67-80` — `_findCard()` consulta apenas `id, name`. Sem validacao de completude.
- `rg "total_cards|card_count|completeness|missing.*cards" server/lib/` — ZERO resultados para validacao de completude.
- A importacao e feita via scripts Python (`auto_sync_learned_decks.py`) que inserem `deck_cards` mas nao verificam se `COUNT(*)` de cartas inseridas == `total_cards` do deck.

**Gap:** Quando um deck e importado (via script Python ou API), nao ha verificacao de que TODAS as cartas foram inseridas com sucesso. Falhas parciais (ex: 11/100 cartas) sao aceitas silenciosamente. O sistema downstream (Mana Base Validator, Commander Knowledge Deep, Multi-Commander Evolution) herda dados incompletos e produz analises enganosas ou quebra.

**Impacto:** `P1` — Decks fantasmas (Korvold 11/100, Kinnan 13/100) consomem recursos de todos os crons, produzem relatorios enganosos (MANA_BASE_VALIDATION_REPORT mostra "INCOMPLETE" sem explicar que e 89% vazio), e exigem workarounds manuais em cada cron (Multi-Commander Evolution precisou aprender a filtrar `total_cards < 90`).

**Risco:** P1 — Dados incompletos se propagam para toda a pipeline de analise. Decks com 11% das cartas sao tratados como decks reais, desperdicando ciclos de cron e produzindo recomendacoes baseadas em dados fantasmas.

**Acao recomendada:**
1. No script de importacao Python (`auto_sync_learned_decks.py` ou equivalente): apos inserir `deck_cards`, executar `SELECT COUNT(*) FROM deck_cards WHERE deck_id = ?` e comparar com `total_cards` do deck. Se `COUNT(*) < total_cards * 0.9`, marcar o deck como `import_status='partial'` e logar warning.
2. Em `card_validation_service.dart`: Adicionar metodo `validateDeckCompleteness(int deckId, int expectedCardCount)` que retorna `DeckCompletenessResult` com `importedCount`, `expectedCount`, `missingCards`.
3. No `deck_rules_service.dart`: apos `_loadCardsData()`, verificar se `cards.length >= expectedTotal * 0.9`. Se nao, retornar erro ou warning.
4. No endpoint de analise de deck (`server/routes/decks/[id]/analysis/`), verificar completude antes de executar Monte Carlo/analise funcional.
5. Adicionar coluna `import_completeness` (0.0-1.0) a tabela `decks` para tracking.

**Validacao:**
```bash
cd server && dart analyze lib/card_validation_service.dart
cd server && dart analyze lib/deck_rules_service.dart
cd server && dart test test/deck_rules_service_test.dart
```

---

### [P1] Commander Selection: Query both `decks` AND `learned_decks` tables — verificar `total_cards >= 90` em pelo menos uma tabela antes de selecionar comandante para otimizacao

**Atualizacao Codex 2026-06-11:** PARCIALMENTE RESOLVIDO no pipeline Hermes. `sync_pg_meta_decks_to_hermes.py` agora usa `--min-cards=90` por padrao e `sync_pg_target_deck_to_hermes.py` recusa deck PG alvo com `total_qty < 90` ou sem comandante. Isso reduz o risco de crons/battle tooling selecionarem seeds parciais. A validacao do endpoint de optimize do app permanece baseada no deck do usuario e nas regras atuais do backend; nao foi introduzido bloqueio global por comandante desconhecido para evitar falsos negativos em decks reais recem-criados.

**Conhecimento MTG:** O Multi-Commander Evolution Pipeline (Execucao #1, 2026-06-04, documentado no Commander Knowledge Deep S42-43) descobriu empiricamente que comandantes podem ter dados parciais:
- Korvold: 11/100 cards em `decks` (89% vazio)
- Kinnan: 13/100 cards em `decks` (87% vazio)
- Aesi, Teysa, Yuriko: tem decks parciais em `decks` mas NAO tem `learned_decks` completos (card_count < 90)

Se o otimizador selecionar Korvold (11 cartas) para evolucao, o pipeline inteiro quebra: analise de wincon sobre 11 cartas, swap em deck fantasma, validacao contra dados incompletos. O Multi-Commander Evolution precisou aprender manualmente a filtrar `total_cards >= 90`. Mas esse filtro deveria estar no codigo, nao no prompt do cron.

**Evidencia no codigo:**
- `rg "total_cards|card_count|learned_deck" server/lib/ai/optimize_runtime_support.dart` — Referencias a `learned_deck` existem para `loadCommanderReferenceProfileFromCache()` (linha 3820), mas nao para filtrar comandantes elegiveis.
- `rg "WHERE.*total_cards|WHERE.*card_count" server/lib/` — ZERO resultados com threshold de completude.
- `server/lib/ai/commander_fallback_policy.dart` — Politica de fallback para comandantes desconhecidos, mas nao verifica se os dados do comandante sao completos.
- O endpoint de optimize (`server/routes/ai/optimize/index.dart`) seleciona comandante baseado no deck do usuario, sem verificar se o deck esta completo.

**Gap:** Quando o otimizador ou o pipeline de evolucao seleciona um comandante para analise, nao verifica se os dados disponiveis sao suficientes (>=90 cartas). Decks com 11-13 cartas passam pela selecao e produzem analises invalidas. O filtro `total_cards >= 90` existe apenas no prompt do cron (documentado no skill), nao no codigo.

**Impacto:** `P1` — O optimize pipeline pode operar sobre dados incompletos, produzindo recomendacoes de swap baseadas em 11% do deck real. O Multi-Commander Evolution gastou uma execucao inteira aprendendo isso (e documentando o workaround). Sem o fix no codigo, qualquer novo cron ou endpoint que selecione comandantes repetira o mesmo erro.

**Risco:** P1 — Recomendacoes de swap baseadas em decks fantasmas (Korvold 11 cartas, Kinnan 13 cartas). Afeta diretamente a confiabilidade do optimize pipeline para esses comandantes.

**Acao recomendada:**
1. Criar funcao `isCommanderEligibleForOptimization(String commanderName)` que:
   - Consulta `decks` WHERE `total_cards >= 90`
   - Consulta `learned_decks` WHERE `card_count >= 90`
   - Retorna `true` se PELO MENOS UMA das duas tabelas tem dados completos
2. Integrar ao `commander_fallback_policy.dart`: antes de aplicar fallback, verificar se os dados do comandante sao completos.
3. No endpoint de optimize: antes de iniciar analise, verificar `isCommanderEligibleForOptimization()` e retornar erro 422 se nao for elegivel.
4. Adicionar mensagem de erro informativa: "Commander X has insufficient data (Y/100 cards). Please import a complete decklist first."

**Validacao:**
```bash
cd server && dart analyze lib/ai/commander_fallback_policy.dart
cd server && dart test test/ai/commander_fallback_policy_test.dart
```

---

### [P2] Game Changer Import: Auto-detectar `oracle_text=NULL` e disparar reimportacao via Scryfall fuzzy search com fallback para nomes MDFC sem `//`

**Conhecimento MTG:** O Gamechanger Research Report (Exec #7-#9, 2026-06-04/05) documenta que Tergrid, God of Fright // Tergrid's Lantern ficou com `oracle_text=NULL` por multiplas execucoes consecutivas. A causa: o nome MDFC contem `//`, e o Scryfall fuzzy search (`/cards/named?fuzzy=...`) falha quando o nome inclui `//`. A solucao manual (reimportar via `fuzzy=Tergrid, God of Fright` sem `//`) funcionou, mas o sistema deveria auto-curar. As heuristicas de deteccao de GC (`tagCardForBracket()`) dependem de `oracle_text` para detectar tutores, free interaction, e infinite combos — com `oracle_text=NULL`, TODAS as heuristicas ficam cegas para a carta.

**Evidencia no codigo:**
- `server/lib/edh_bracket_policy.dart:91-145` — `tagCardForBracket()` usa `oracleText` para detectar `tutor` (linha 111: `o.contains('search your library')`), `extraTurns` (116), `freeInteraction` (121-132). Com `oracle_text=NULL`, `o` e string vazia -> nenhuma categoria detectada.
- `server/lib/edh_bracket_policy.dart:140-143` — A deteccao por nome (`_gameChangerNames`) ainda funciona, mas a carta e marcada apenas como `gameChanger`, sem a categoria de impacto correta (ex: Tergrid deveria ser `stax`/`value_engine`).
- O script `gc_hash_check.py` (linhas 82-90) detecta `oracle_text IS NULL` mas apenas reporta — nao corrige.
- O script de importacao inicial (que popula `game_changers` no SQLite) deve lidar com falhas de fuzzy search para nomes MDFC.

**Gap:** Cartas MDFC com `//` no nome falham na importacao do Scryfall (oracle_text=NULL) e permanecem nesse estado por multiplas execucoes. O `tagCardForBracket()` perde TODAS as heuristicas de deteccao para essas cartas. O sistema detecta o problema (`gc_hash_check.py` reporta NULLs) mas nao auto-corrige.

**Impacto:** `P2` — 1 carta (Tergrid) foi afetada e ja corrigida manualmente. Mas o padrao pode se repetir para qualquer MDFC futuro adicionado a lista de Game Changers. A deteccao por nome ainda funciona, mas a categorizacao de impacto fica incompleta.

**Risco:** P2 — Baixa frequencia (1/53 GCs afetado), mas alta severidade quando ocorre (todas as heuristicas cegas). A correcao e preventiva para futuras adicoes de MDFCs.

**Acao recomendada:**
1. No script de importacao de Game Changers (Python): ao detectar `oracle_text IS NULL` apos importacao, tentar fallback com fuzzy search sem `//`:
   ```python
   if '//' in card_name:
       fallback_name = card_name.split('//')[0].strip()
       # Refazer Scryfall fuzzy search com fallback_name
   ```
2. Alternativa: `typeLine.contains('instant') && oracle.contains('add {')` como condição curta.
3. Adicionar testes para Seething Song, Pyretic Ritual, Desperate Ritual.

**Validação:**
```bash
cd server && dart test test/ai/functional_card_tags_test.dart && dart analyze lib/ai/functional_card_tags.dart
```

---

### [P2] Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility sem sub-categoria de bracket

**Conhecimento MTG:** Estes 4 GCs oficiais da lista de 53 caem em `gameChanger` genérico sem sub-categoria:
- **Notion Thief:** Draw hate — stax
- **Orcish Bowmasters:** Draw punishment + removal — stax/removal
- **Glacial Chasm:** Previne todo dano a você — protection/value engine
- **Humility:** Todas as criaturas viram 1/1 sem habilidades — stax

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:354-408` — Todos os 4 estão em `officialGameChangerNamesForBracketPolicy` (Notion Thief: line 391, Bowmasters: 393, Glacial: 376, Humility: 379).
- `server/lib/edh_bracket_policy.dart:493-518` — `_looksLikeGameChangerStax()` não detecta Notion Thief, Bowmasters, Humility.
- `server/lib/edh_bracket_policy.dart:520-539` — `_looksLikeGameChangerProtection()` não detecta Glacial Chasm (prevenção passiva de dano).
- `server/lib/edh_bracket_policy.dart:541-547` — `_knownValueEngineNames` não inclui Glacial Chasm.

**Gap:** Budget allocation de stax/protection/value engine fica subestimada para estes 4 GCs.

**Impacto:** Bracket policy perde informação semântica sobre a composição funcional do deck.

**Risco:** P2 — Melhoria incremental. Mitigado pela detecção `gameChanger` genérica que limita a 3 em bracket 3.

**Ação recomendada:**
1. Notion Thief: adicionar padrão `"if an opponent would draw a card except"` → stax
2. Orcish Bowmasters: adicionar `'orcish bowmasters'` à lista curada de stax + `"whenever an opponent draws"` + dano → removal
3. Glacial Chasm: adicionar `'glacial chasm'` à `_knownValueEngineNames` + detecção de "prevent all damage" → protection
4. Humility: adicionar `'humility'` a stax + `"all creatures lose all abilities"` → stax
5. Adicionar teste unitário para cada GC com oracle text real

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

### [P2] Cobertura de teste bracket policy para GCs conhecidos

**Conhecimento MTG:** O arquivo de teste `edh_bracket_policy_test.dart` tem 87 linhas e 4 testes. Underworld Breach é testado (só `gameChanger`, sem `infiniteCombo`). Narset, GAA IV, Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility **não têm testes**.

**Evidência no código:**
- `server/test/edh_bracket_policy_test.dart:35-44` — Teste de Underworld Breach verifica APENAS `contains(BracketCategory.gameChanger)`. Sem assertion de `infiniteCombo`.
- `server/test/edh_bracket_policy_test.dart` — Nenhum teste para Narset, GAA IV, Notion Thief, Orcish Bowmasters, Glacial Chasm, Humility.
- Cobertura atual: 4 testes / ~54 GCs = 7.4% de cobertura de GCs individuais.

**Gap:** Sem testes de regressão para as sub-categorias dos GCs mais impactantes.

**Impacto:** Alterações nas heurísticas ou listas curadas podem introduzir regressão não detectada.

**Risco:** P2 — Complementar às tasks acima.

**Ação recomendada:**
1. No teste existente "keeps official gamechanger names" (linha 27), adicionar `expect(breach.categories, contains(BracketCategory.infiniteCombo))` (APÓS adicionar Breach a `_knownInfiniteComboPieces`, task P0 acima).
2. Adicionar `test('detects Narset, Parter of Veils as stax')` com oracle real que verifica `contains(BracketCategory.stax)` e `contains(BracketCategory.gameChanger)`.
3. Adicionar `test('detects Grand Arbiter Augustin IV as stax')`.
4. Adicionar `test('detects Notion Thief as stax')`.
5. Adicionar `test('detects Orcish Bowmasters as stax and removal')`.
6. Adicionar `test('detects Glacial Chasm as valueEngine and protection')`.
7. Adicionar `test('detects Humility as stax')`.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze test/edh_bracket_policy_test.dart
```

---

## New Tasks (2026-06-15 — Cron #12, Execution #3)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 10 | **P1** | Import pipeline SQLite usa heurísticas Python básicas em vez do classificador Dart | `sync_pg_target_deck_to_hermes.py:60-93` | 🟡 Incoerência |
| 11 | **P1** | `_criticalRolesForArchetype` limitado a 3 arquétipos | `optimization_quality_gate.dart:493-500` | 🟡 Incoerência |
| 12 | **P2** | `_looksLikeGameChangerBoardWipe` diverge de `looksLikeOptimizationBoardWipeText` | `edh_bracket_policy.dart:454-467` vs `optimization_functional_roles.dart:345-360` | 🟢 Melhoria |
| 13 | **P2** | Detecção automática de tema a partir de decklist não implementada | `THEMES.md` (documentado, sem código) | 🟢 Melhoria |
| 14 | **P2** | Bolas's Citadel ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |

### [P1] Import pipeline SQLite usa heurísticas Python básicas em vez do classificador Dart

**Conhecimento MTG:** A classificação funcional de cartas é crítica para todas as análises downstream (quality gate, validator, mulligan, battle analyst). VALIDATOR_LOG v3.23 detectou 20 cartas com `functional_tag='unknown'` e 6 cartas com `CMC=NULL` na importação — dados corrompidos que invalidam toda a análise do pipeline.

**Evidência no código:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:60-93` — `infer_tag()` usa heurísticas Python minimalistas:
  ```python
  def infer_tag(row):
      # ... tenta battle_role ...
      # ... tenta battle_effect ...
      if "land" in type_line: return "land"
      if "destroy target" in oracle or "exile target" in oracle: return "removal"
      if "draw" in oracle: return "draw"
      if "add " in oracle and "mana" in oracle: return "ramp"
      if "creature" in type_line: return "creature"
      return "unknown"  # ← 20+ cartas caem aqui
  ```
- `server/lib/ai/functional_card_tags.dart` — O classificador Dart tem 1092 linhas de heurísticas sofisticadas (oracle text parsing, type_line analysis, name matching, speed inference, card advantage type, etc.). NUNCA é chamado durante a importação.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:118-125` — `deck_cards` schema: `cmc REAL` sem default. PG pode retornar `cmc=NULL` para cartas onde `cmc` não está populado ou é nulo.
- VALIDATOR_LOG v3.23 evidencia: Sol Ring (CMC 1 → 0.0), Mana Vault (CMC 1 → 0.0), Aetherflux (CMC 4 → NULL), Past in Flames (CMC 4 → NULL).

**Gap:** O script de importação Python não chama o classificador Dart (API ou CLI). Tags funcionais e CMCs são importados crus do PostgreSQL sem validação ou enriquecimento. O classificador Dart só roda no servidor, durante análise de deck — mas os dados no SQLite ficam permanentemente corrompidos até a próxima sincronização que substitui as tags.

**Impacto:** QUALQUER análise que leia do SQLite (battle_analyst_v8.py, VALIDATOR_LOG, optimization quality gate via PG sync) trabalha com dados corrompidos. CMC=0.0 artificialmente reduz o CMC médio do deck. Tags 'unknown' fazem o quality gate ignorar funções críticas.

**Risco:** P1 — Corrupção sistemática de dados na fonte de verdade local.

**Ação recomendada:**
1. **Curto prazo:** Adicionar pós-processamento em `sync_pg_target_deck_to_hermes.py` que corrige CMCs contra `card_oracle_cache` e aplica heurísticas Python melhoradas (cobrindo Sol Ring, mana rocks, etc.) como fallback imediato.
2. **Médio prazo:** Criar um endpoint Dart (`POST /api/classify-cards`) ou script CLI que aceite lista de cartas e retorne functional_tags + cmc corrigido. Invocar do Python via subprocess.
3. **Alternativa:** Migrar o sync script para Dart, executando o classificador nativamente.
4. Adicionar validação: se >5% das cartas têm 'unknown', abortar importação e reportar erro.

**Validação:**
```bash
# Validar que Sol Ring, Mana Vault, Aetherflux Reservoir têm functional_tag='ramp' e CMC correto
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -c "
import sqlite3
conn = sqlite3.connect('knowledge.db')
cur = conn.execute('SELECT card_name, functional_tag, cmc FROM deck_cards WHERE deck_id=6')
for row in cur:
    name, tag, cmc = row
    if tag == 'unknown' or cmc is None or cmc == 0.0:
        print(f'ISSUE: {name} -> tag={tag}, cmc={cmc}')
    if name in ('Sol Ring', 'Mana Vault', 'Aetherflux Reservoir'):
        print(f'{name}: tag={tag}, cmc={cmc}')
conn.close()
"
```

---

### [P1] `_criticalRolesForArchetype` limitado a 3 arquétipos

**Conhecimento MTG:** Cada arquétipo de Commander tem necessidades diferentes. Um deck de **Combo** precisa proteger `combo_piece` e `tutor`. Um deck de **Spellslinger** precisa de `draw` e `engine`. Um deck de **Go-wide Tokens** precisa de `creature` e `token_maker`. Um deck de **Aristocrats** precisa de `sacrifice` e `drain`. Usar o mesmo conjunto crítico para todos os decks genéricos subestima sistematicamente riscos de swap.

**Evidência no código:**
- `server/lib/ai/optimization_quality_gate.dart:493-500` — `_criticalRolesForArchetype()`:
  ```dart
  Set<String> _criticalRolesForArchetype(String archetype) {
    return switch (archetype.trim().toLowerCase()) {
      'aggro' => {'creature', 'ramp', 'removal', 'protection', 'wipe', 'wincon'},
      'control' => {'removal', 'draw', 'wipe', 'ramp', 'protection', 'wincon'},
      'midrange' => {'removal', 'ramp', 'draw', 'wipe', 'wincon'},
      _ => {'removal', 'ramp', 'wipe', 'wincon'}, // ← fallback genérico
    };
  }
  ```
- `server/test/edh_bracket_policy_test.dart` — Sem testes para archetype-specific critical roles.
- `server/decks` do SQLite: deck 6 (Lorehold) tem `archetype='unknown'` — cai no fallback genérico.
- THEMES.md lista 42 temas específicos de Commander — nenhum refletido aqui.
- `docs/CONTEXTO_PRODUTO_ATUAL.md` — Commander Reference Profiles para 48+ comandantes com `role_targets` que incluem draw, ramp, removal, protection, wincon — métricas que o quality gate devia usar.

**Gap:** O quality gate não protege roles essenciais para arquétipos como combo (`combo_piece`, `tutor`), spellslinger (`draw`, `engine`), aristocrats (`sacrifice`, `drain`), enchantress (`engine`, `draw`), goblins (`creature`, `token_maker`), dragons (`ramp`, `creature`, `engine`).

**Impacto:** Swaps que removem `combo_piece` de um deck combo passam pelo quality gate porque `combo_piece` não está em `criticalRoles` para o fallback. Similarmente, trocar `draw` essencial em spellslinger por removal genérico não é bloqueado.

**Risco:** P2 — Afeta a confiabilidade das metricas exibidas. Nao causa falhas funcionais (swaps nao sao bloqueados por isso), mas reduz a utilidade do relatorio para diagnostico humano.

**Acao recomendada:**
1. No script `_run_validation.py`: adicionar query separada para `SUM(dc.quantity) WHERE functional_tag IS NULL` por deck e incluir como coluna "untagged" na tabela de relatorio.
2. No `MANA_BASE_VALIDATION_REPORT.md`: adicionar coluna "Untagged" a tabela de Resumo Geral.
3. No status do deck: se `untagged >= 10% do total`, mostrar aviso de que metricas podem estar subestimadas.
4. No `FunctionalDeckSummary` (Dart): distinguir `untaggedRows`/`untaggedCopies` de cartas classificadas como `utility`/`other`.

**Validacao:**
```bash
cd server && dart analyze lib/ai/functional_card_tags.dart
```

---

## Resumo de Tasks Novas (2026-06-05 @ 94b620a6 — Cron #8)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Deck Import: Validar completude (imported vs expected card count) | Commander Knowledge Deep S42-43 (Korvold 11/100, Kinnan 13/100) |
| 2 | P1 | Commander Selection: Query both `decks` AND `learned_decks` for `total_cards >= 90` | Multi-Commander Evolution aprendizado empirico |
| 3 | P2 | Game Changer Import: Auto-heal `oracle_text=NULL` via MDFC name fallback | Gamechanger Research #7-#9 (Tergrid resolvido, padrao preventivo) |
| 4 | P2 | Game Changer: Marcar `price_usd=NULL` de Reserved List como `RESERVED_LIST` | Gamechanger Research #7-#9 (8 cartas RL) |
| 5 | P2 | Mana Base Validator: Reportar `functional_tag=NULL` separadamente | MANA_BASE_VALIDATION_REPORT (Yuriko 25% untagged) |

> **Nota:** Tasks #1 e #2 sao complementares — ambas abordam a protecao do pipeline contra dados incompletos (import completeness + commander eligibility).
> **Nota:** Tasks #3 e #4 sao complementares — ambas melhoram a integridade dos dados de Game Changers (oracle_text MDFC + price_usd RL).
> **Nota:** Task #5 complementa a task pendente P2 "Tag Accuracy Auto-Healing" — enquanto aquela foca em melhorar a precisao das tags, esta foca em reportar a AUSENCIA de tags.


### [P1] ✅ Resolvido em 2026-06-11 — Unificar roles estratégicos entre `functional_card_tags.dart` e `optimization_functional_roles.dart`

**Conhecimento MTG:** Cartas como Thassa's Oracle (wincon/combo), Blood Artist (aristocrat payoff), Isochron Scepter (combo piece), e Lightning Greaves (protection/enabler) têm papéis funcionais bem definidos no Commander. A classificação correta desses papéis é essencial para que o quality gate tome decisões corretas de swap — trocar um "wincon" por "engine" requer regras diferentes de trocar "utility" por "utility".

**Status:** resolvido sem criar módulo extra: o módulo canônico já existente
`server/lib/ai/optimization_functional_roles.dart` expõe o adapter
`resolveCardFunctionalRoles`. `server/lib/ai/functional_card_tags.dart` removeu
as cópias privadas de `_looksLikeWincon`, `_looksLikeComboPiece`,
`_looksLikeEngine`, `_looksLikePayoff` e `_looksLikeEnabler` e passou a
consultar esse adapter para `wincon`, `combo_piece`, `engine`, `payoff` e
`enabler`.

**Evidência atual:**
- `functional_card_tags.dart`: `inferFunctionalCardTags` chama
  `resolveCardFunctionalRoles(...)` e usa `strategicRoles` para os cinco roles.
- `optimization_functional_roles.dart`: continua sendo a fonte única para
  classificação multi-role e `primary_role`.
- `functional_card_tags_test.dart`: adiciona teste cruzado com `Impact Tremors`,
  `Isochron Scepter`, `The One Ring`, `Aetherflux Reservoir` e `Demonic Tutor`,
  além de impedir que `Nature's Lore` vire `enabler`.

**Impacto:** o tagger exibido na análise e o classificador usado por
optimize/validator/quality gate deixam de discordar nesses roles estratégicos.

**Próxima pendência relacionada:** conectar feedback runtime de qualidade de
prompt/optimize (`MLKnowledgeService.recordFeedback`) e continuar a redução de
drift em trust/request/log/CMC.

**Validação:**
```bash
cd server && dart analyze lib/ai/functional_card_tags.dart lib/ai/optimization_functional_roles.dart test/functional_card_tags_test.dart
cd server && dart test test/functional_card_tags_test.dart test/optimization_quality_gate_test.dart test/optimization_validator_test.dart test/optimize_runtime_support_test.dart --reporter compact
```

---

### [P2] ✅ Resolvido em 2026-06-11 — Centralizar `_isBasicLandName` em utilitário único de domínio

**Conhecimento MTG:** Terrenos básicos (Plains, Island, Swamp, Mountain, Forest, Wastes, e suas variantes Snow-Covered) são fundamentais para as regras de deckbuilding do Commander: singleton não se aplica a eles, e a contagem correta afeta validação de legalidade, análise de mana base, e simulação de mulligan. Diferentes partes do sistema precisam concordar sobre o que constitui um "basic land" — especialmente as variantes Snow-Covered e Wastes.

**Status:** resolvido no código com fonte canônica em
`server/lib/basic_land_utils.dart`. O arquivo expõe
`regularBasicLandNames`, `snowBasicLandNames`, `basicLandNames`,
`normalizeBasicLandName`, `isBasicLandName`, `isBasicLandTypeLine` e
`isBasicLandCard`.

**Evidência atual:**

- `server/lib/basic_land_utils.dart`: normaliza hifens Unicode, case e
  espaços; cobre basics regulares, Wastes e variantes Snow-Covered, incluindo
  `Snow-Covered Wastes`.
- `server/lib/ai/optimize_runtime_support.dart`: preserva a API pública
  `isBasicLandName` como wrapper fino para o utilitário canônico.
- `server/lib/ai/commander_reference_deck_corpus_support.dart`: preserva o
  símbolo público `basicLandNames` como alias de `basic_lands.basicLandNames`,
  sem manter lista local divergente.
- Testes de regras/optimize importam `package:server/basic_land_utils.dart`
  em vez de copiar helpers privados.

**Impacto:** validação de singleton/copy-limit, optimize, Commander
Reference e testes passam a responder a mesma pergunta de domínio com a mesma
normalização. Snow basics deixam de depender do fluxo que processou o deck.

**Validação executável:**
```bash
cd server && dart analyze lib/basic_land_utils.dart lib/ai/commander_reference_deck_corpus_support.dart test/basic_land_utils_test.dart test/mtg_rules_validation_test.dart test/optimization_final_validation_test.dart test/optimization_rules_test.dart test/optimization_pipeline_integration_test.dart test/ai_optimize_flow_test.dart
cd server && dart test test/basic_land_utils_test.dart test/mtg_rules_validation_test.dart test/optimization_final_validation_test.dart test/optimization_rules_test.dart test/optimization_pipeline_integration_test.dart --reporter compact
```

---

### [P2] ✅ Resolvido 2026-06-11: conectar `MLKnowledgeService.recordFeedback` a fluxo runtime de optimize — `ml_prompt_feedback` passa a ser alimentada automaticamente

**Conhecimento MTG:** O optimize pipeline gera prompts para IA que sugerem swaps de cartas. A qualidade desses prompts afeta diretamente a qualidade das recomendações. Sem um ciclo de feedback, o sistema não sabe se prompts anteriores produziram boas ou más recomendações — e não pode melhorar.

**Evidência atual no código:**
- `server/routes/ai/optimize/index.dart` chama `optimize_feedback.recordOptimizeMlFeedback(...)` dentro de `respondWithOptimizeTelemetry`, após montar telemetry/log de análise.
- `server/lib/ai/optimize_feedback_support.dart` converte resultado do optimize em feedback automático: cartas aceitas, cartas rejeitadas, score 1-5 e comentário sanitizado.
- `server/lib/ml_knowledge_service.dart` segue como writer canônico em `recordFeedback(...)`.
- `server/database_setup.sql` declara `ml_prompt_feedback` e índices operacionais.
- `server/bin/verify_schema.dart` inclui `ml_prompt_feedback` no schema esperado.
- `server/routes/ai/ml-status/index.dart` trata `ml_prompt_feedback` como tabela obrigatória do schema ML antes de contar registros.

**Status:** Resolvido para coleta automática server-side. O gap original "helper sem chamador" não é mais válido.

**Impacto:** A partir de cada resposta de `/ai/optimize`, o backend passa a registrar feedback mínimo sobre sucesso, rejeição de qualidade, blockers de identidade/bracket e warnings. Isso cria base histórica para ranking futuro de templates/prompts por comandante/arquetipo.

**Risco restante:** Ainda não há endpoint manual de feedback do usuário nem seleção ativa de prompt baseada em métricas históricas. Isso fica como evolução futura; não deve ser reaberto como "tabela sem writer".

**Ação futura recomendada:**
1. Adicionar feedback manual do usuário após aplicar/recusar sugestões.
2. Criar agregação de qualidade por commander/archetype/prompt_version.
3. Usar métricas históricas apenas como sinal de ranking, não como gate duro.

**Validação:**
```bash
cd server && dart analyze lib/ai/optimize_feedback_support.dart lib/ml_knowledge_service.dart routes/ai/optimize/index.dart routes/ai/ml-status/index.dart bin/verify_schema.dart test/optimize_feedback_support_test.dart test/optimize_learning_pipeline_test.dart
cd server && dart test test/optimize_feedback_support_test.dart test/optimize_learning_pipeline_test.dart --reporter compact
```

---

### [P2] Expandir `_run_validation.py` para buscar profiles batch_c — 8 comandantes sem cobertura de validação de mana base

**Conhecimento MTG:** O Mana Base Validator compara decks contra perfis EDHREC com ranges ideais de lands, ramp, draw, etc. por comandante. O projeto tem 24 profiles JSON (8 batch_a + 8 batch_b + 8 batch_c), mas o script de validação só consulta 16 deles (batch_a + batch_b). Comandantes dos profiles batch_c — incluindo potenciais comandantes futuros no `knowledge.db` — ficam sem validação de mana base.

**Evidencia no código:**
- `docs/hermes-analysis/manaloom-knowledge/scripts/_run_validation.py` — O script (criado 2026-06-04) carrega profiles de `batch_a` e `batch_b` apenas. A lógica de busca de profiles (aproximadamente linhas 30-60) percorre apenas estes dois diretórios.
- `server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/profiles/` — 8 profiles JSON existem mas não são lidos.
- O Commander Knowledge Skill (2026-06-05, Mana Base Validator Exec #2) documenta: "Só busca profiles em batch_a e batch_b (não batch_c)" e "Seção de notas (L258-272) é hardcoded — pode divergir dos dados reais".

**Gap:** Se um deck para um comandante do batch_c for adicionado ao `knowledge.db` (ex: Krenko, Mob Boss; Muldrotha, the Gravetide; ou outro dos 8 profiles batch_c), o Mana Base Validator reportará "NO PROFILE" em vez de validar contra os ranges ideais. A seção de notas do relatório também é hardcoded — se novos decks forem adicionados, as notas não refletirão a realidade.

**Impacto:** `P2` — Atualmente nenhum deck no `knowledge.db` corresponde a comandantes do batch_c (são Kinnan, Yuriko, Korvold, Teysa, Aesi, Winota, Atraxa, Lorehold — batch_a/batch_b). Mas o sistema não escala: qualquer novo deck de batch_c ficará sem validação. A seção de notas hardcoded também falseará o relatório quando novos decks aparecerem.

**Risco:** P2 — Baixo impacto imediato (0 decks batch_c no DB), mas impede expansão futura. A nota hardcoded é um risk de integridade de relatório.

**Ação recomendada:**
1. Adicionar `batch_c` ao loop de busca de profiles em `_run_validation.py`:
   ```python
   profile_dirs = [
       "server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles/",
       "server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/profiles/",
       "server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/profiles/",
   ]
   ```
2. Substituir seção de notas hardcoded (L258-272) por geração dinâmica baseada nos dados reais de cada deck
3. Adicionar contagem de "profiles available vs profiles used" no output do script para transparência

**Validação:**
```bash
cd /opt/data/workspace/mtgia && /opt/hermes/.venv/bin/python3 docs/hermes-analysis/manaloom-knowledge/scripts/_run_validation.py
# Verificar que o relatório gerado referencia 24 profiles (não 16)
grep -c "profile" docs/hermes-analysis/manaloom-knowledge/MANA_BASE_VALIDATION_REPORT.md
```

---

### [P3] Superseded 2026-06-15: `deck_weakness_reports` nao e mais ausencia total de leitura

**Status atual:** o achado original dizia que `deck_weakness_reports` era um
log sem consumidor. A validacao de modelo de dados de 2026-06-15 reclassificou
isso como historico: a rota de weakness-analysis le/persiste historico no fluxo
runtime. O problema remanescente e mais especifico: transformar fraquezas
historicas em sinal de priorizacao no optimize e em resolucao/feedback loop.

**Evidencia atual:**
- `server/routes/ai/weakness-analysis/index.dart` consome/persiste a tabela no
  fluxo da propria analise.
- `docs/hermes-analysis/DATA_MODEL_FINAL_VALIDATION_2026-06-15.md` lista
  `deck_weakness_reports` como tabela presente no PostgreSQL real, com 15
  linhas no snapshot auditado.
- A tarefa antiga foi mantida aqui apenas como historico para evitar reabertura
  automatica por reports Hermes antigos.

**Gap remanescente:** usar fraquezas historicas nao resolvidas como sinal
explicito no optimize/quality gate e marcar resolucao quando as metricas do deck
melhorarem. Isso deve ser tratado como melhoria de aprendizado, nao como bug de
persistencia sem consumidor.

**Ação futura recomendada:**
1. Criar leitura agregada segura de fraquezas recentes por `deck_id`.
2. No optimize pipeline, priorizar categorias coerentes com fraquezas abertas
   sem expor metadata interna Hermes ao app normal.
3. Depois de aplicar swaps, marcar fraquezas como resolvidas apenas quando a
   metrica correspondente melhorar em analise backend-owned.

**Validação futura:**
```bash
cd server && dart analyze lib/ai/optimize_runtime_support.dart routes/ai/weakness-analysis/index.dart
cd server && dart test test/ai_weakness_analysis_live_test.dart
rg "deck_weakness_reports" server/lib server/routes server/bin
```

---

## Resumo de Tasks Novas (2026-06-05 — Cron #9)

| # | Prioridade | Task | Origem |
|:-:|:----------|:-----|:-------|
| 1 | P1 | Unificar heurísticas `_looksLike{Wincon,Engine,ComboPiece,Payoff,Enabler}` entre `functional_card_tags.dart` e `optimization_functional_roles.dart` | STRUCTURE_AUDIT 2026-06-05 (divergent heuristic implementations) |
| 2 | P2 | ✅ Resolvido 2026-06-11: centralizar `_isBasicLandName` em utilitário único com normalização canônica | STRUCTURE_AUDIT 2026-06-05 (4 conflicting implementations) |
| 3 | P2 | ✅ Resolvido 2026-06-11: `MLKnowledgeService.recordFeedback` conectado ao fluxo runtime de `/ai/optimize`; `ml_prompt_feedback` declarada no schema e verificador | STRUCTURE_AUDIT 2026-06-05 (functions not called: recordFeedback) |
| 4 | P2 | Expandir `_run_validation.py` para buscar profiles batch_c | Commander Knowledge Skill (Mana Base Validator Exec #2 limitations) |
| 5 | P3 | Superseded: `deck_weakness_reports` tem fluxo runtime; proximo gap e usar historico como sinal no optimize | DATA_MODEL_FINAL_VALIDATION 2026-06-15 |

> **Nota:** Task #1 complementa a tarefa pendente P1 "classifyOptimizationFunctionalRole: Usar functional_tags persistidas como fonte primária" (Cron #7) — enquanto aquela aborda a CADEIA DE PRIORIDADE de fontes, esta aborda a DIVERGÊNCIA NAS IMPLEMENTAÇÕES das heurísticas de fallback.
> **Nota:** Task #3 complementa a tarefa pendente P2 "deck_learning_events: Fechar o loop de aprendizado" (Cron #7) — enquanto aquela foca em eventos de gameplay, esta foca em feedback de qualidade de prompts.
> **Nota:** Task #2 resolve um problema de integridade de dados que afeta múltiplos validadores — centralizar evita que correções futuras sejam aplicadas em apenas um local.

### [P1] Deck Import: Validar CMC das cartas importadas contra a tabela `cards` do PostgreSQL — previne corrupção de dados que afeta toda a pipeline de análise

**Status em 2026-06-11:** RESOLVIDO no código. O caminho de resolução/import
app-facing passa a carregar `cards.cmc` e gerar warnings de integridade; o
payload público foi preservado. A rotina Hermes de backfill/sync de
`deck_cards.cmc` existe e está testada; falta apenas execução operacional no
AWS com `knowledge.db` populado.

**Conhecimento MTG:** O VALIDATOR_LOG v3.23 (2026-06-02) documenta corrupção massiva de CMC na importação do deck Lorehold: 14+ cartas com `CMC=0.0` (Sol Ring, Mana Vault, Boros Signet, Orim's Chant, etc.) e 6 cartas com `CMC=NULL` (Aetherflux Reservoir, Past in Flames, Electroduplicate, etc.). A CMC média reportada de 2.15 é subestimada — a CMC real do deck está ~2.8-3.0. Todos os cálculos downstream (curva de mana, Mulligan Simulation T3, GoldfishSimulator keepable, quality gate ΔCMC) são afetados.

**Evidencia no código:**
- `server/lib/import_card_lookup_service.dart` — queries de exact/localized/split agora retornam `c.cmc`.
- `server/lib/generated_deck_validation_service.dart` — cards resolvidos carregam `cmc` internamente e geram warning de integridade.
- `server/lib/card_validation_service.dart` — `_getCardInfo()` retorna `mana_cost`/`cmc` e `validateDeckCards()` compara contra o valor informado.
- `server/lib/deck_rules_service.dart` — `_loadCardsData()` consulta e armazena `cmc` em `_CardData`.
- `server/lib/ai/cmc_safety.dart` — funções compartilhadas identificam CMC suspeito e recuperam fallback por `mana_cost`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py` — corrige `deck_cards.cmc/type_line/oracle_text` a partir de `card_oracle_cache`.
- `docs/hermes-analysis/manaloom-knowledge/scripts/import_lorehold_decks.py` — usa `card_oracle_cache` antes de `card_oracle_data`.

**Gap remanescente:** Operacional: rodar o sync no Hermes/AWS depois de popular
`knowledge.db` com decks reais. Se o banco continuar vazio, o relatório expõe
`deck_cards_table_present=false`.

**Impacto:** `P1` — Dados corrompidos em cadeia. Swaps podem ser aprovados/rejeitados baseados em ΔCMC errado. O Mulligan Simulation reporta T3 inflado (mascara color screw). A análise de curva de mana mostra valores incorretos para o usuário. O problema é silencioso — não há logs, warnings, ou alertas.

**Risco:** P1 — Corrupção de dados se propaga para todas as camadas de análise sem detecção. Afeta diretamente a confiabilidade do optimize pipeline e da exibição de métricas para o usuário.

**Ação recomendada:**
1. ~~Adicionar campo `cmc` à `_CardData` e ao SELECT de `DeckRulesService`~~
2. ~~Carregar `cmc` no resolver de import/localized/split~~
3. ~~Emitir warning em validação app-facing para CMC suspeito/divergente~~
4. ~~Criar rotina Hermes para corrigir SQLite local e scripts Python de importação aprendida~~
5. Rodar rotina no AWS e anexar relatório `deck_cards_backfill`

**Validação:**
```bash
cd server && dart analyze lib/deck_rules_service.dart lib/card_validation_service.dart lib/generated_deck_validation_service.dart lib/import_card_lookup_service.dart
cd server && dart test test/generated_deck_validation_service_test.dart test/cmc_safety_test.dart
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 test_sync_pg_card_metadata_to_hermes.py
```

---

### [P2] `_looksLikeGameChangerBoardWipe` diverge de `looksLikeOptimizationBoardWipeText`

**Conhecimento MTG:** Board wipes são definidos consistentemente: qualquer spell que destrói/remova/exila/bouncia múltiplas permanentes de oponentes ou de todos os jogadores. O sistema tem DUAS implementações para detectar board wipes, com cobertura diferente.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:454-467` — `_looksLikeGameChangerBoardWipe()` (10 linhas):
  ```dart
  if (normalizedName == 'cyclonic rift' || normalizedName == 'farewell') return true;
  if (oracleLower.contains('exile all') && oracleLower.contains('opponents control')) return true;
  if (oracleLower.contains('destroy all') && oracleLower.contains('opponents control')) return true;
  if (oracleLower.contains('return all') && oracleLower.contains('opponents control') && oracleLower.contains('hand')) return true;
  return false;
  ```
  **Problema:** Só detecta wipes assimétricos (apenas "opponents control"). Perde wipes simétricos como "destroy all creatures" (Wrath of God), "each player sacrifices" (Pox, Cataclysm), "damage to each creature" (Blasphemous Act).

- `server/lib/ai/optimization_functional_roles.dart:345-360` — `looksLikeOptimizationBoardWipeText()` (16 linhas):
  ```dart
  return oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('all creatures get -') ||
      oracle.contains('all colored permanents') ||
      oracle.contains('each player sacrifices all') ||
      oracle.contains('each opponent sacrifices all') ||
      oracle.contains('damage to each creature') ||
      (oracle.contains('deals') && oracle.contains('damage') && oracle.contains('to each creature'));
  ```
  **Mais abrangente:** detecta wipes simétricos e assimétricos.

- **DRY Violation:** Mesma lógica (detecção de board wipe via oracle text) implementada duas vezes com cobertura diferente. Nenhuma função chama a outra.

**Gap:** Bracket policy subnotifica board wipes simétricos (Wrath of God, Blasphemous Act não são detectados como `boardWipe` pelo bracket, embora Blasphemous Act seja detectado por `looksLikeOptimizationBoardWipeText`).

**Impacto:** Deck com Wrath of God + Blasphemous Act + Cyclonic Rift + Farewell tem 4 wipes, mas bracket policy conta só 2 (Cyclonic + Farewell). Budget `boardWipe` (bracket 2 max=2) não reflete a densidade real.

**Risco:** P2 — Subnotificação de board wipes impacta análise de bracket.

**Ação recomendada:**
1. Extrair `_looksLikeGameChangerBoardWipe()` para usar a lógica mais abrangente de `looksLikeOptimizationBoardWipeText()`.
2. Unificar as duas funções em um módulo compartilhado (`board_wipe_utils.dart`?).
3. Alternativa: modificar `_looksLikeGameChangerBoardWipe()` para:
   ```dart
   bool _looksLikeGameChangerBoardWipe(String normalizedName, String oracleLower) {
     return looksLikeOptimizationBoardWipeText(oracleLower);
   }
   ```
4. Adicionar testes para Wrath of God, Austere Command, Blasphemous Act no bracket policy test.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart lib/ai/optimization_functional_roles.dart
```

---

### [P2] Detecção automática de tema a partir de decklist não implementada

**Conhecimento MTG:** THEMES.md documenta 42 temas de Commander com regras de detecção completas (Passo 1-3: contar tribos, contar mecânicas, score de confiança). A metodologia está documentada mas NENHUM código implementa a detecção automática. O otimizador usa `detectedTheme` que vem do campo `theme` do deck, não de análise real da decklist.

**Evidência no código:**
- `docs/hermes-analysis/manaloom-knowledge/THEMES.md:128-151` — Metodologia completa de detecção de temas:
  - Passo 1: Contar tribos (20+ cartas mesmo tipo de criatura → TRIBAL)
  - Passo 2: Contar mecânicas (20+ instants/sorceries → SPELLSLINGER, etc.)
  - Passo 3: Score de confiança (3+ sinais = CONFIRMADO)
  - Tabelas com thresholds por tema (Goblins: 25+ goblins, Dragons: 18-24 dragons)
- `server/lib/ai/optimize_runtime_support.dart` — Usa `card['theme']` ou `commanderName` para inferir tema, NÃO analisa a decklist.
- Busca por `detectedTheme` em server/lib: **0 resultados** (campo lido de PG, não computado).
- `server/lib/ai/theme_contextual_rules_service.dart` — Existe como serviço mas depende de `theme` fornecido externamente.
- `docs/hermes-analysis/manaloom-knowledge/THEMES.md:180-185` — "O que precisa ser adicionado" lista 6 itens, NENHUM implementado.

**Gap:** Não há código que, dada uma decklist + commander, produza `detectedTheme` com score de confiança. A otimização não pode ser theme-aware porque não sabe em qual tema o deck está.

**Impacto:** O otimizador trata todos os decks como genéricos. Não pode aplicar regras como "em Goblins, 25+ criaturas goblin é critical" ou "em Enchantress, 15+ encantamentos é critical". Swaps que quebram o tema (ex: remover goblins de um deck tribal goblin) não são detectados.

**Risco:** P2 — Otimização cega para identidade temática do deck.

**Ação recomendada:**
1. Criar `server/lib/ai/theme_detector.dart` com:
   - `detectTheme(List<Map<String, dynamic>> deckCards, String commanderName) → DetectedTheme`
   - Contagem de tribos por `type_line`
   - Contagem de mecânicas por heurísticas de oracle text
   - Score de confiança (0.0-1.0) baseado em quantos sinais bateram
2. Implementar regras de detecção para os 10 temas mais comuns inicialmente (Spellslinger, Goblins, Dragons, Elves, Aristocrats, Enchantress, Artifacts, Tokens, Graveyard, Landfall)
3. Integrar no pipeline: `_bootstrapSparseCompleteInput` deve chamar `detectTheme()` com as cartas disponíveis e armazenar resultado.
4. Adicionar ao `OptimizationSwapGateResult` o campo `theme` para auditoria.
5. Escrever testes com decklists reais (SQLite learned_decks) para verificar detecção.

**Validação:**
```bash
cd server && dart test test/theme_detector_test.dart && dart analyze lib/ai/theme_detector.dart
```
(Testes precisam ser criados — usar decklists do SQLite `learned_decks` como fixtures.)

---

### [P2] Bolas's Citadel ausente de `_knownInfiniteComboPieces`

**Conhecimento MTG:** Bolas's Citadel + Aetherflux Reservoir + Sensei's Divining Top forma um combo deterministico: Top no topo do library → paga 1 vida com Citadel → conjura Top de graça → compra com Top → repete → ganha vida infinita com Reservoir → vitoria. Bolas's Citadel é Game Changer oficial (linha 359 da GC list) e está em `_knownValueEngineNames` mas NÃO em `_knownInfiniteComboPieces`.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:359` — `'bolas\'s citadel'` em `officialGameChangerNamesForBracketPolicy` → GC detectado.
- `server/lib/edh_bracket_policy.dart:541-547` — `_knownValueEngineNames` → Citadel detectado como value engine.
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` → Citadel AUSENTE (só Oracle, Consultation, Tainted Pact).
- `server/lib/edh_bracket_policy.dart:162-164` — `tagCardForBracket()` usa `_knownInfiniteComboPieces.contains(n)`. Citadel nunca recebe `infiniteCombo`.

**Gap:** Citadel é GC + valueEngine mas falta a tag `infiniteCombo`. Um deck com Citadel + Reservoir + Top conta como 0 combo pieces para o bracket.

**Impacto:** Se um deck já tem Thassa's Oracle + Demonic Consultation + Citadel + Top + Reservoir, o bracket conta 1 combo piece (Oracle) em vez de 2 (Oracle + Citadel como enabler de combo). Pode exceder o limite bracket 3 (max 2 infiniteCombo) sem ser detectado.

**Risco:** P2 — Mitigado por detecção `gameChanger` (limite 3 em B3) e `valueEngine`. Mas a categoria funcional `infiniteCombo` é perdida.

**Ação recomendada:**
```dart
const _knownInfiniteComboPieces = <String>{
  'thassa\'s oracle',
  'demonic consultation',
  'tainted pact',
  'underworld breach',
  'bolas\'s citadel',
};
```

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart
```

---

## Full Summary (All 14 Tasks)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 1 | **P0** | Underworld Breach ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351,405` | 🔴 Quebra |
| 2 | **P1** | Goldfish trata tapped lands como untapped | `goldfish_simulator.dart:258-261,352-367` | 🟡 Incoerência |
| 3 | **P1** | `classifyOptimizationFunctionalRole` ignora persisted tags | `optimization_functional_roles.dart:55-85` | 🟡 Incoerência |
| 4 | **P1** | `CandidateQualityData` sem EDHREC inclusion | `candidate_quality_data_support.dart` | 🟡 Incoerência |
| 5 | **P2** | `_knownValueEngineNames` muito restrito (5→9) | `edh_bracket_policy.dart:541-547` | 🟢 Melhoria |
| 6 | **P1** | GAA IV e Narset fora de `_looksLikeGameChangerStax` | `edh_bracket_policy.dart:493-518` | 🟡 Incoerência |
| 7 | **P1** | `_looksLikeRitual` não captura rituais simples | `functional_card_tags.dart:870-877` | 🟡 Incoerência |
| 8 | **P2** | Notion Thief, Bowmasters, Glacial Chasm, Humility sem sub-categoria | `edh_bracket_policy.dart:354-408,493-547` | 🟢 Melhoria |
| 9 | **P2** | Cobertura de teste bracket policy para GCs | `edh_bracket_policy_test.dart` | 🟢 Melhoria |
| 10 | **P1** | Import pipeline SQLite usa heurísticas Python (20+ unknown tags) | `sync_pg_target_deck_to_hermes.py:60-93` | 🟡 Incoerência |
| 11 | **P1** | `_criticalRolesForArchetype` limitado a 3 arquétipos | `optimization_quality_gate.dart:493-500` | 🟡 Incoerência |
| 12 | **P2** | Board wipe detection divergente (bracket vs optimization) | `edh_bracket_policy.dart:454-467` vs `optimization_functional_roles.dart:345-360` | 🟢 Melhoria |
| 13 | **P2** | Detecção automática de tema não implementada | `theme_detector.dart` (não existe) | 🟢 Melhoria |
| 14 | **P2** | Bolas's Citadel ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
## New Tasks (2026-06-15 — Cron #12, Execution #4 — Current)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 15 | **P1** | Quality gate `_isTemporaryManaBurstCard` omite rituais sem qualificador temporal | `optimization_quality_gate.dart:349-364` | 🟡 Incoerência |
| 16 | **P2** | Drift: `_knownComboPieceNames` (optimization) vs `_knownInfiniteComboPieces` (bracket) | `optimization_functional_roles.dart:515-522` vs `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
| 17 | **P2** | `_knownProtectionNames` em optimization_functional_roles.dart com cobertura insuficiente | `optimization_functional_roles.dart:524-529` | 🟢 Melhoria |
| 18 | **P2** | SQLite: 35/100 cartas do deck 6 com CMC=0.0 — agravante da import pipeline | `sync_pg_target_deck_to_hermes.py:118-125` | 🟢 Melhoria |

---

### [P1] Quality gate `_isTemporaryManaBurstCard` omite rituais sem qualificador temporal

**Conhecimento MTG:** Rituais são mana burst temporária (one-shot), diferente de ramp permanente (rocks, dorks, land ramp). Rituais como Dark Ritual (`"Add {B}{B}{B}."`), Seething Song (`"Add {R}{R}{R}{R}{R}."`) e Pyretic Ritual (`"Add {R}{R}{R}."`) geram mana instantânea sem "until end of turn" no oracle text porque o mana já desaparece naturalmente nas fases. O quality gate precisa distinguir ramp temporária de permanente para bloquear swaps que trocam ramp sustentável por burst.

**Evidência no código:**
- `server/lib/ai/optimization_quality_gate.dart:349-364` — `_isTemporaryManaBurstCard()`:
  ```dart
  bool _isTemporaryManaBurstCard(Map<String, dynamic> card) {
    final name = ((card['name'] as String?) ?? '').toLowerCase();
    final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
    final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
    final generatesMana =
        oracle.contains('add {') || oracle.contains('add one mana');
    if (!generatesMana) return false;
    if (!(typeLine.contains('instant') || typeLine.contains('sorcery'))) return false;
    return name.contains('ritual') ||
        oracle.contains('until end of turn') ||
        oracle.contains('for each');
  }
  ```
  **Problema:** `oracle.contains('until end of turn')` exige qualificador temporal que rituais simples não têm. Seething Song (`seething song` não contém "ritual") → NOT detected. Pyretic Ritual → detected (contém "ritual" no nome). Dark Ritual → detected (`'dark ritual'.contains('ritual')` = true).

- SQLite `deck_cards` confirma: Seething Song no deck 6 tem `type_line=Sorcery`, `oracle_text=Add {R}{R}{R}{R}{R}.`, sem "ritual" no nome.

- Em decks não-combo, swaps que trocam ramp permanente (Sol Ring, Signet) por Seething Song não são bloqueados porque `_isTemporaryManaBurstCard()` retorna false para Seething Song.

- **Achado adicional:** 123 quality reviews no SQLite, 70+ deles avaliando Blasphemous Act como 'ramp' quando deveria ser 'wipe'. Quality reviews mostram `role_mismatch:Blasphemous Act role=ramp add_roles=wipe`. Isso indica que o classificador `classifyOptimizationFunctionalRole()` está retornando papel inesperado, provavelmente porque os functional_tags persistidos (`["board_wipe","enabler","payoff","big_spell"]`) não estão disponíveis no mapa da carta em tempo de execução.

**Gap:** `_isTemporaryManaBurstCard()` não detecta Seething Song como mana temporária. O ramp count do optimizer inclui rituais como ramp permanente, inflando a contagem.

**Impacto:** Em decks não-combo, swap de Sol Ring (ramp permanente) → Seething Song (ramp temporária) passa pelo quality gate sem bloqueio, degradando a sustentabilidade da mana base.

**Risco:** P1 — Degradação silenciosa de mana base em non-combo. Blasphemous Act mal classificado gera warnings espúrios (70+ reviews).

**Ação recomendada:**
1. Corrigir `_isTemporaryManaBurstCard()` para detectar qualquer instant/sorcery que gere mana como temporário:
   ```dart
   bool _isTemporaryManaBurstCard(Map<String, dynamic> card) {
     final typeLine = ((card['type_line'] as String?) ?? '').toLowerCase();
     final oracle = ((card['oracle_text'] as String?) ?? '').toLowerCase();
     final generatesMana =
         oracle.contains('add {') || oracle.contains('add one mana');
     if (!generatesMana) return false;
     // Instants e sorceries que geram mana são sempre temporários
     if (typeLine.contains('instant') || typeLine.contains('sorcery')) return true;
     return false;
   }
   ```
2. Remover `name.contains('ritual')`, `oracle.contains('until end of turn')` e `oracle.contains('for each')` — redundantes após a correção.
3. Investigar Blasphemous Act classification: verificar se functional_tags chegam ao quality gate. Se não chegam, adicionar `card['functional_tags']` propagation no pipeline.

**Validação:**
```bash
cd server && dart test test/optimization_quality_gate_test.dart && dart analyze lib/ai/optimization_quality_gate.dart
```

---

### [P2] Drift: `_knownComboPieceNames` (optimization) vs `_knownInfiniteComboPieces` (bracket)

**Conhecimento MTG:** Combo pieces são cartas que, combinadas com outra(s), geram loop infinito ou wincondition determinística. O sistema tem DOIS registros separados de combo pieces que não sincronizam.

**Evidência no código:**
- `server/lib/edh_bracket_policy.dart:347-351` — `_knownInfiniteComboPieces` (3 cartas): thassa's oracle, demonic consultation, tainted pact.
- `server/lib/ai/optimization_functional_roles.dart:515-522` — `_knownComboPieceNames` (6 cartas):
  ```dart
  const _knownComboPieceNames = <String>{
    'basalt monolith',
    'dramatic reversal',
    'underworld breach',
    'grand architect',
    'sensei\'s divining top',
    'power artifact',
  };
  ```
- **Interseção:** 0 cartas (nenhum nome está em ambas as listas).

**Gap:** Underworld Breach é combo piece no optimization mas não no bracket (embora seja GC). Basalt Monolith, Dramatic Reversal, Grand Architect, Sensei's Divining Top e Power Artifact são combo pieces conhecidos pelo optimization mas o bracket policy nunca os classifica como `infiniteCombo`.

**Impacto:** Bracket policy subnotifica densidade de combo. Ex: deck com Dramatic Reversal + Isochron Scepter (combo infinito de mana) não gera alerta no bracket.

**Risco:** P2 — Inconsistência entre módulos. Um módulo sabe que a carta é combo piece, o outro não.

**Ação recomendada:**
1. Adicionar `'basalt monolith'`, `'dramatic reversal'`, `'grand architect'`, `'sensei\'s divining top'`, `'power artifact'` a `_knownInfiniteComboPieces`.
2. Considerar criar `shared/combo_constants.dart` como fonte única de verdade para combo pieces.
3. Adicionar teste de consistência: verificar que ambas as listas contêm os mesmos elementos.

**Validação:**
```bash
cd server && dart test test/edh_bracket_policy_test.dart && dart analyze lib/edh_bracket_policy.dart lib/ai/optimization_functional_roles.dart
```

---

### [P2] `_knownProtectionNames` em optimization_functional_roles.dart com cobertura insuficiente

**Conhecimento MTG:** Proteção em Commander inclui spells que concedem indestrutível, hexproof, ou phase out. Flawless Maneuver, Heroic Intervention, Boros Charm e Teferi's Protection são staples de proteção.

**Evidência no código:**
- `server/lib/ai/optimization_functional_roles.dart:524-529` — `_knownProtectionNames` (4 nomes):
  ```dart
  const _knownProtectionNames = <String>{
    'fierce guardianship',
    'deflecting swat',
    'swiftfoot boots',
    'endurance',
  };
  ```
- `edh_bracket_policy.dart:520-528` — `_looksLikeGameChangerProtection()` tem 6 nomes curados incluindo Flawless Maneuver, Heroic Intervention, Teferi's Protection, Deadly Rollick.
- `_resolveHeuristicRoles()` detecta oracle text de proteção (hexproof, indestructible, etc.) independentemente da lista curada. A lista curada é usada para PRIORIZAÇÃO: `_selectPrimaryRole()` escolhe 'protection' como papel primário se a carta está na lista.

**Gap:** Flawless Maneuver (free protection, 19.8% EDHREC Lorehold), Heroic Intervention (staple verde em 35%+ decks), Boros Charm (staple Boros), Teferi's Protection (GC) não estão em `_knownProtectionNames`. O classificador heurístico pode detectá-los, mas a lista curada prioriza o papel primário.

**Impacto:** Quality gate pode tratar Teferi's Protection como 'utility' em vez de 'protection', permitindo swap que remove proteção essencial sem flag.

**Risco:** P2 — Priorização de papel funcional sub-ótima.

**Ação recomendada:**
```dart
const _knownProtectionNames = <String>{
  'fierce guardianship',
  'deflecting swat',
  'swiftfoot boots',
  'endurance',
  'flawless maneuver',
  'heroic intervention',
  'boros charm',
  'teferi\'s protection',
  'deadly rollick',
};
```

**Validação:**
```bash
cd server && dart test test/optimization_validator_test.dart && dart analyze lib/ai/optimization_functional_roles.dart
```

---

### [P2] SQLite: 35/100 cartas do deck 6 com CMC=0.0 — validação pós-import ausente

**Conhecimento MTG:** Terrenos têm CMC 0 (regra do jogo). No entanto, o VALIDATOR_LOG v3.23 reportou 16 cartas não-land com CMC=0.0. Verificação nesta execução: apenas 35 lands têm CMC=0.0 — as 16 não-lands foram corrigidas. A correção parcial indica ajuste manual ou execução corretiva do import. Falta validação automatizada.

**Evidência no código:**
- SQLite verificado nesta execução: 35 cartas CMC=0.0 — todas com `type_line` contendo 'Land'. 0 cartas não-land com CMC=0.0.
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py:118-125` — Schema sem validação pós-write.
- `server/lib/ai/cmc_safety.dart` — `safeCmcForOptimization()` existe no Dart mas não na importação Python.

**Gap:** Não há validação pós-importação que verifique `cmc` para cartas não-land. Se o PG retornar CMC=NULL para cartas não-land no futuro, a regressão não seria detectada automaticamente.

**Impacto:** Menor — situação atual está corrigida (0 não-lands com CMC=0.0). Mas sem validação, a regressão pode acontecer novamente.

**Risco:** P2 — Prevenção de regressão.

**Ação recomendada:**
1. Adicionar query de validação pós-import no sync script: `SELECT card_name, cmc, type_line FROM deck_cards WHERE deck_id=? AND cmc = 0.0 AND type_line NOT LIKE '%Land%'`. Se retornar >0, abortar e logar erro.
2. Alternativa: adicionar CONSTRAINT CHECK (`cmc > 0 OR type_line LIKE '%Land%'`) se o SQLite suportar (precisa de alter table, complexo).

**Validação:**
```bash
cd docs/hermes-analysis/manaloom-knowledge/scripts && python3 -c "
import sqlite3
conn = sqlite3.connect('knowledge.db')
bad = conn.execute(\"\"\"
  SELECT card_name, cmc, type_line
  FROM deck_cards
  WHERE deck_id=6 AND cmc = 0.0 AND type_line NOT LIKE '%Land%'
\"\"\").fetchall()
print(f'Non-lands with CMC=0: {len(bad)}')
for r in bad:
    print(f'  {r[0]}: cmc={r[1]}, type={r[2]}')
conn.close()
"
```

---

## Full Summary (All 18 Tasks)

| # | Prio | Título | Arquivo(s) | Risco |
|:-:|:----:|:-------|:-----------|:------|
| 1 | **P0** | Underworld Breach ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351,405` | 🔴 Quebra |
| 2 | **P1** | Goldfish trata tapped lands como untapped | `goldfish_simulator.dart:258-261,352-367` | 🟡 Incoerência |
| 3 | **P1** | `classifyOptimizationFunctionalRole` ignora persisted tags | `optimization_functional_roles.dart:55-85` | 🟡 Incoerência |
| 4 | **P1** | `CandidateQualityData` sem EDHREC inclusion | `candidate_quality_data_support.dart` | 🟡 Incoerência |
| 5 | **P2** | `_knownValueEngineNames` muito restrito (5→9) | `edh_bracket_policy.dart:541-547` | 🟢 Melhoria |
| 6 | **P1** | GAA IV e Narset fora de `_looksLikeGameChangerStax` | `edh_bracket_policy.dart:493-518` | 🟡 Incoerência |
| 7 | **P1** | `_looksLikeRitual` não captura rituais simples | `functional_card_tags.dart:870-877` | 🟡 Incoerência |
| 8 | **P2** | Notion Thief, Bowmasters, Glacial Chasm, Humility sem sub-categoria | `edh_bracket_policy.dart:354-408,493-547` | 🟢 Melhoria |
| 9 | **P2** | Cobertura de teste bracket policy para GCs | `edh_bracket_policy_test.dart` | 🟢 Melhoria |
| 10 | **P1** | Import pipeline SQLite usa heurísticas Python (20+ unknown tags) | `sync_pg_target_deck_to_hermes.py:60-93` | 🟡 Incoerência |
| 11 | **P1** | `_criticalRolesForArchetype` limitado a 3 arquétipos | `optimization_quality_gate.dart:493-500` | 🟡 Incoerência |
| 12 | **P2** | Board wipe detection divergente (bracket vs optimization) | `edh_bracket_policy.dart:454-467` vs `optimization_functional_roles.dart:345-360` | 🟢 Melhoria |
| 13 | **P2** | Detecção automática de tema não implementada | `theme_detector.dart` (não existe) | 🟢 Melhoria |
| 14 | **P2** | Bolas's Citadel ausente de `_knownInfiniteComboPieces` | `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
| 15 | **P1** | Quality gate `_isTemporaryManaBurstCard` omite rituais sem qualificador | `optimization_quality_gate.dart:349-364` | 🟡 Incoerência |
| 16 | **P2** | Drift: `_knownComboPieceNames` vs `_knownInfiniteComboPieces` | `optimization_functional_roles.dart:515-522` vs `edh_bracket_policy.dart:347-351` | 🟢 Melhoria |
| 17 | **P2** | `_knownProtectionNames` com cobertura insuficiente (4 nomes) | `optimization_functional_roles.dart:524-529` | 🟢 Melhoria |
| 18 | **P2** | SQLite: validação pós-import para CMC de não-lands ausente | `sync_pg_target_deck_to_hermes.py:118-125` | 🟢 Melhoria |

## Strategic Notes

- **Tarefa #11** (criticalRolesForArchetype) — a ação recomendada expande para 10 arquétipos mas o código atual do aggro ainda omite `'draw'`. A expansão proposta já cobre essa omissão ao adicionar novos arquétipos com draw.
- **Tarefas #1, #14, #16** compartilham a mesma causa raiz: `_knownInfiniteComboPieces` desatualizado. Idealmente resolvidas no mesmo commit unificando as listas.
- **Tarefa #7 e #15** compartilham a mesma causa raiz (detecção de rituais sem qualificador) mas em funções diferentes (`_looksLikeRitual` em functional_card_tags.dart vs `_isTemporaryManaBurstCard` em optimization_quality_gate.dart). Ambas precisam da mesma correção.
- **SQLite freshness:** `optimizer_quality_reviews` 53→123 (70 novos), `slot_benchmarks` 45→115 (70 novos) — optimizer ativo. `swap_benchmarks` estagnado em 2 e `user_learning_events` em 51 — aprendizado/benchmarking parado.
