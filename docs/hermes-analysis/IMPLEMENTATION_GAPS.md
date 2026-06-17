# Implementation Gaps — PDF Spec vs Codebase

> Mapeamento da "Especificação técnica de regras faltantes para o ManaLoom Commander"
> para o código atual do battle_analyst_v9.py (engine ativo).
> Status: 2026-06-11
> Fonte oficial revalidada nesta rodada:
> `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md`.
> Revisão estratégica complementar:
> `BATTLE_RULES_2026_STRATEGIC_REVIEW_2026-06-11.md`.
> Esta lista separa battle engine/regras de gaps de produto/UX. Itens visuais
> não devem entrar aqui.

## Resumo

### Atualizacao de ciclo — 2026-06-12

- Incorporado no backend: `POST /decks/:id/recommendations` manteve contrato
  experimental, mas o fallback deixou de usar `Command Tower` literal e raridade
  como proxy de impacto. As sugestoes agora buscam cartas no PostgreSQL por
  `card_function_tags`, `card_semantic_tags_v2`, `card_legalities` e
  `cards.color_identity` quando disponiveis, com fallback textual parametrizado.
- Continua pendente: consolidar esses lookups em um service compartilhado com
  `/ai/weakness-analysis`, `/ai/optimize` e prompts runtime; remover nomes fixos
  restantes apenas quando houver policy/dado versionado equivalente.

### Atualizacao de ciclo — 2026-06-15

- Implementado primeiro slice Hermes-only de `decision_trace_v1`:
  `battle_analyst_v9.py` emite decisoes auditaveis como side-channel opcional,
  `battle_replay_v10_3.py` grava `*.decision_trace.jsonl` e
  `replay_decision_auditor.py` passa a auditar decisoes alem dos eventos finais.
- O trace cobre cast de spell/ramp/criatura/high-threat, respostas com
  counter/protection, ataque/combat target e pass/no-action de prioridade.
- `card_impact_analyzer.py` passou a expor `WR sem carta vista`,
  `delta_vs_not_seen`, `sample_size` e `sample_quality`; `loss_mode_suggester.py`
  bloqueia recomendacoes com amostra baixa.
- Continua pendente: rodar o full replay no Hermes AWS com SQLite completo,
  persistir apenas artefatos JSON/MD neste ciclo e adiar tabela SQLite/PG ate o
  formato estabilizar. WR alto de Lorehold segue `needs_more_samples` quando
  houver `unknown_effect`, `heuristic_effect` ou amostra baixa.

### Atualizacao de ciclo — 2026-06-15 / Strategy Audit v1

- Implementado complemento Hermes-only para diferenciar "acao legal" de "acao
  estrategicamente defensavel". O novo documento canônico é
  `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`.
- `decision_trace_v1` agora possui campos de estratégia:
  `strategic_principle`, `heuristic_version`, `resource_delta`, `risk_flags`,
  `alternatives_considered` e `rejected_reason`.
- Mulligan deixou de ser apenas contagem de terrenos no trace: agora registra
  cores, curva inicial, ramp barato, cartas caras, riscos e motivo de
  keep/mulligan. Em 2026-06-17 o bottom do London Mulligan tambem deixou de
  ser aleatorio: cartas caras/mortas sao priorizadas para o fundo, lands
  necessarias e jogadas iniciais sao preservadas, e excesso de land so vai para
  o fundo quando nao houver spell morta melhor.
- Mox Diamond/land discard e Crop Rotation/Harrow/land sacrifice agora
  registram opções de land, motivo de escolha e riscos como
  `spending_last_land` e `spending_unique_color_land`.
- Criado `battle_decision_strategy_auditor.py` para flagar decisões legais mas
  ruins/mal explicadas: keep sem plano inicial, one-shot mana sem payoff,
  custo de land sem contexto e pass/no-action sem motivo.
- Criado `battle_decision_research_review.py` para agregar replays contra matriz
  de fontes oficiais/estratégicas e classificar cada categoria como
  `coherent_in_sample`, `blocked_or_needs_review`, `tracked_gap_not_observed`
  ou `not_observed`.
- Rodada local inicial de 16 seeds (`20260615_151841`) analisou `17200` eventos e
  `2270` decisões: mulligan, fast mana one-shot, cast, response, combat, pass e
  sacrifice-land ficaram coerentes na amostra; `mox_land_discard` ficou
  `blocked_or_needs_review`; `tutor` e `board_wipe_wheel` ainda não tinham
  `decision_type` próprio naquela janela.
- Achado P1 concreto na primeira rodada: Mox Diamond descartava última/única
  land sem payoff imediato comprovado. O auditor diferencia o caso coerente
  onde a land descartada destrava `commander_cast` no mesmo turno.
- Implementado em `battle_analyst_v9.py`: permanent fast mana com
  `requires_discard_land` agora passa exclusivamente pelo loop de ramp e só
  pode gastar última/única land se destravar comandante ou spell de alto impacto
  no mesmo turno. Testes focados cobrem o caso permitido e o caso bloqueado.
- Rodada reproduzida pós-ajuste (`20260615_153120`) analisou `17295` eventos e
  `2259` decisões: `strategy_findings=0`, `seeds_with_strategy_blockers=[]` e
  `mox_land_discard=coherent_in_sample` naquela janela.
- Rodada expandida depois de instrumentar tutor/board wipe/wheel
  (`20260615_160111`) analisou `18254` eventos e `2468` decisões:
  `tutor=coherent_in_sample`, mas `mox_land_discard=blocked_or_needs_review`
  e `board_wipe_wheel=blocked_or_needs_review`. Achados: `spending_last_land=3`,
  `spending_unique_color_land=3`, `board_wipe_without_clear_asymmetry=3`,
  `wheel_model_simplified=7` e `wheel_opponent_refill_risk=5`.
- Correção aplicada: o loop de ramp agora revalida o guardrail de resource
  spend no momento exato do cast, e permanent fast mana que gasta land escassa
  também precisa provar payoff por mana nominal. Esse ajuste eliminou o blocker
  de Mox na rodada reproduzida, mas a instrumentação de tutor/wipe/wheel expôs
  novos casos de land sacrifice sem benefício líquido claro.
- Rodada pós-correção de land-sacrifice (`20260615_162840`) analisou `18667`
  eventos e `2526` decisões: `strategy_findings=14`, todos `medium`,
  `seeds_with_strategy_blockers=[]`, `mox_land_discard=coherent_in_sample` e
  `sacrifice_land=coherent_in_sample`.
- Correção aplicada: `Crop Rotation`/`Harrow` distinguem land untapped de
  ramp tapped; land sacrifice agora escolhe alvo por score mínimo e bloqueia
  fetch/tapped sem benefício claro quando gastaria última/única fonte. O replay
  registra `land_ramp_target_options` e `strategic_benefit_reason`.
- Continua pendente: avaliação de board wipe/wheel em corpus maior, pass
  reasons mais ricos, threat assessment por player/permanent, explicacao
  comparativa mais completa do bottom do London Mulligan e ampliação de corpus
  para confirmar Mox/land-sacrifice.
- Rodada pós-correção de board wipe/wheel (`20260615_172608`) analisou `19226`
  eventos e `2564` decisões: `strategy_findings=0`,
  `seeds_with_strategy_blockers=[]` e todas as categorias do
  `battle_decision_research_review.py` ficaram `coherent_in_sample`.
- Correção aplicada: board wipe agora exige timing justificado
  (assimetria, lethal pressure, estar atrás ou plano de rebuild), e Wheel-like
  draw usa modelo multiplayer v1 com discard/draw para todos os jogadores vivos,
  refill risk e payoff mínimo de `Smothering Tithe`.
- Pendente real após esse slice: ampliar corpus e melhorar hand-quality,
  payoff-denial e score por arquétipo para Wheel/board wipe. Não tratar o batch
  limpo como prova universal de ótima jogada.

### Atualizacao de ciclo — 2026-06-16 / Battle Phase Rules Deep Audit

- Criado `BATTLE_PHASE_RULES_DEEP_AUDIT_2026-06-16.md` para cruzar regras
  oficiais atuais (CR 103/117/500-514/Commander) com o `battle_analyst_v9.py`.
- Confirmado que o engine ativo esta mais avancado que a descricao historica:
  possui priority loop APNAP, passos formais de combate, multi-defender,
  end-of-combat triggers, decision trace e suite de regressao focada.
- Achado P1 concreto: `activate_land_tutor_creatures()` ainda sacrificava a
  primeira land e buscava a primeira land da biblioteca, bypassando os
  guardrails recentes de land-sacrifice/target scoring usados por
  Crop Rotation/Harrow.
- Implementado em `battle_analyst_v9.py`: criatura land-tutor agora usa
  `choose_land_for_resource_cost()`, `choose_land_ramp_targets()` e
  `land_sacrifice_has_strategic_benefit()`. Jogadas legais porem ruins emitem
  `activated_ability_skipped` com motivo e contexto auditavel.
- Testes adicionados em `battle_summoning_sickness_tests.py`:
  `test_elvish_reclaimer_does_not_sacrifice_unique_color_for_tapped_basic` e
  `test_elvish_reclaimer_prefers_redundant_tapped_land_for_high_value_target`.
- Validacao: `python3 -m py_compile` nos arquivos alterados e
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
  passaram.
- Pendencias restantes apos esta auditoria: explicacao comparativa mais rica do
  London Mulligan, pass/no-action reasons mais ricos, cleanup 514.3a completo,
  upkeep generico, attack/block restrictions avancadas e threat assessment por
  player/permanent.

### Atualizacao de ciclo — 2026-06-16 / Known Cards Runtime Fallback Audit

- Criado `audit_known_cards_runtime_fallback.py` para medir a distancia real
  entre `known_cards_generated.json` e o cache canonico `battle_card_rules`.
- Resultado validado nesta rodada:
  - `3158` regras canonicas em SQLite;
  - `1970` nomes em overlap com o JSON legado;
  - `1457` matches exatos de runtime;
  - `297` diferencas apenas estruturais apos normalizacao;
  - `216` diferencas reais de `effect` apos a mesma normalizacao aplicada aos
    dois lados;
  - `1188` cartas existem no cache canonico e nao existem no JSON legado.
- Isso confirma que o problema residual nao e mais "conflito ativo de
  precedencia" no battle runtime, e sim "fallback degradado semanticamente mais
  pobre" quando algum fluxo cai no JSON legado.
- Revalidado tambem:
  - `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`;
  - `test_sync_battle_card_rules_manual_preserve.py`;
  - override de `battle_card_rules` sobre fallback dentro de
    `battle_card_specific_tests`.
- Ajuste aplicado:
  - `universal_optimizer.py` deixou de consumir `known_cards_generated.json`
    cru e agora sobrepoe `battle_card_rules`, igual ao `slot_optimizer.py`.
- Reclassificacao aplicada nesta rodada:
  - `server/bin/loss_mode_suggester.py` nao deve mais ser tratado como
    consumidor ativo do fallback legado; o script hoje usa apenas `loss_tags`
    e `card_impact` derivados de replay, e o texto antigo que mencionava
    `known_cards_generated.json` era apenas drift documental.
- Guardrail aplicado nesta rodada:
  - `test_known_cards_consumer_guardrail.py` passou a proteger a fronteira de
    consumidores ativos: `slot_optimizer.py`, `universal_optimizer.py`,
    `battle_effect_coverage_audit.py` e `sync_pg_card_metadata_to_hermes.py`
    agora ficam cobertos contra regressao para leitura crua do fallback legado,
    e `battle_analyst_v9.py` fica coberto quanto a ordem
    `battle_card_rules -> snapshot canonico -> legado`.
- Ajuste aplicado nesta continuidade:
  - `battle_analyst_v9.py` agora tenta `known_cards_canonical_snapshot.json`
    antes do fallback legado;
  - `sync_battle_card_rules_pg.py --apply-sqlite-from-pg` agora exporta o
    snapshot canonico junto com o refresh do cache SQLite;
  - `battle_forensic_audit.py` passou a distinguir snapshot canonico de fallback
    legado, reduzindo falso positivo de drift quando o runtime degradado ainda
    esta semanticamente alinhado ao cache.
- Pendente correto daqui para frente:
  - garantir rollout Hermes/AWS desse snapshot nos jobs reais;
  - manter o JSON legado apenas como ultimo historico/seed ate a troca completa;
  - auditar outros consumidores secundarios para garantir que nao restou leitura
    crua do fallback em caminhos ativos.
- Revalidacao desta continuidade:
  - `audit_known_cards_runtime_environment.py` voltou `PASS` com
    `handcrafted_count=0` e `manual_waiver_count=0`;
  - `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`,
    `test_known_cards_consumer_guardrail.py`,
    `test_sync_battle_card_rules_manual_preserve.py` e
    `test_battle_analyst_v10_3.py` permaneceram verdes;
  - o harness focado de `known_cards`/snapshot/reviewed layer fechou em
    `29` testes `OK` sem `ResourceWarning` remanescente de SQLite, entao
    warning de conexao deixou de mascarar possiveis regressões de precedence;
  - o conflito residual deixou de ser de precedencia e ficou reduzido a
    cobertura faltante de cartas ainda nao promovidas para uma camada revisada
    ou com semantica apenas simplificada.
- Atualizacao adicional desta mesma rodada:
  - foi criada uma camada versionada de regras revisadas
    (`reviewed_battle_card_rules.json` + loader dedicado) para evitar novo
    crescimento de overrides manuais em codigo;
  - `Angel's Grace` foi promovida para `curated/verified` com
    `effect=cannot_lose_turn` e comportamento minimo executavel no battle;
  - `Chromatic Star` foi promovida para `curated/active` com
    `effect=cantrip_mana_filter_artifact` e
    `battle_model_scope=sacrifice_mana_filter_cantrip_v2`;
  - o battle agora ativa esse perfil de forma generica em precombat/postcombat:
    desbloqueia spell off-color quando houver payoff contextual e faz
    cash-in por compra quando a mao fica curta, sem reintroduzir hardcode por
    nome de carta;
  - a auditoria de fallback revalidada passou a mostrar
    `canonical_snapshot_rows=3159`, `runtime_effect_different=217`,
    `source_review_counts` contendo `curated/active=1` e o runtime resolvendo
    esses dois casos pela camada revisada, nao pelo fallback legado.
- P1 aberto a partir desta revalidacao:
  - promover cartas ainda relevantes ao corpus Lorehold/oponentes de
    `generated/needs_review`, `heuristic` ou `active` para regras canônicas
    `trusted/traceable`, em vez de tratar isso como bug de precedence.
- Atualizacao de continuidade — 2026-06-17:
  - a auditoria revalidada fechou `generated_only_names=0`, ou seja,
    `known_cards_generated.json` nao entrega mais nenhuma carta exclusiva ao
    runtime quando o snapshot canonico esta presente;
  - o mesmo audit ainda mostrou `runtime_effect_different=219`, entao manter o
    JSON gerado como fallback executavel era pior do que cair para `unknown`
    auditavel;
  - `battle_analyst_v9.py` deixou de carregar `known_cards_generated.json` em
    runtime. A ordem operacional agora e `battle_card_rules`/SQLite/PG ->
    `known_cards_canonical_snapshot.json` -> tags/heuristicas -> `unknown`;
  - `test_runtime_canonical_snapshot_fallback.py` e
    `test_known_cards_consumer_guardrail.py` agora falham se o fallback gerado
    voltar a ser fonte executavel da batalha.
  - pendencia restante: reduzir/remover consumidores secundarios que ainda usam
    `load_layered_known_cards(... generated_path=...)` em optimizer/auditoria,
    mas so depois de teste especifico desses fluxos. Eles nao devem influenciar
    o replay/battle runtime.
- P2 operacional:
  - `battle_analyst_v9.py --help` nao pode disparar simulacao; a CLI precisa
    responder com parse deterministico para nao contaminar jobs de auditoria.

### Atualizacao de ciclo — 2026-06-16 / Generator Ownership + Learned Deck Boundary

- Revalidado o pipeline real de `server/routes/ai/generate/index.dart`.
  O fluxo atual usa:
  - `commander_reference_profiles`;
  - `commander_reference_card_stats`;
  - `commander_reference_deck_corpus`;
  - `commander_card_usage` como guidance textual;
  - filtro/refill deterministico;
  - `GeneratedDeckValidationService` + `DeckRulesService`.
- Confirmado tecnicamente: `/ai/generate` **nao** usa
  `commander_learned_decks` nem `commander_learning_snapshot` como fonte
  primaria de montagem do deck.
- Learned deck hoje e um canal de produto separado:
  `GET /ai/commander-learning` entrega `recommended_deck` validado para o app
  revisar/salvar, com metadata Hermes escondida do usuario comum.
- Ajuste aplicado nesta continuidade:
  - `buildCommanderReferenceDiagnostics()` passou a expor
    `runtime_profile_origin` e `runtime_profile_reason` quando o profile
    utilizavel vier do fallback runtime, sem alterar decklist nem exigir
    consumo app-facing obrigatorio.
- `commander_learning_snapshot` existe e consolida:
  - learned decks ativos;
  - `commander_card_usage`;
  - `commander_card_synergy`;
  mas ainda nao foi adotado como loader analitico unificado nos pipelines
  internos de generate/optimize/diagnostics.
- Lorehold permanece parcialmente fallback-curated:
  `buildDeterministicReferenceDeck()` ainda injeta
  `loreholdDeterministicReferenceFallbackCards` como rede de seguranca depois de
  stats/corpus/expected packages.
- Gaps corretos abertos a partir desta revalidacao:
  1. definir fronteira explicita entre "deck gerado" e "deck carregado de
     learned deck" para scorecards nao misturarem canais;
  2. promover explainability backend-owned por carta gerada com provenance
     (`profile`, `corpus`, `usage`, `learned_rank`, `fallback`, `repair`);
  3. decidir se learned decks entram como ranking interno opcional no
     `/ai/generate` ou continuam estritamente como fluxo paralelo;
  4. adotar `commander_learning_snapshot` como fonte diagnostica agregada,
     evitando consumidores paralelos recalculando learned/usage/synergy.
- Ajuste aplicado nesta continuidade:
  - `server/bin/export_hermes_learned_deck.py` voltou como wrapper de
    compatibilidade apontando para
    `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py`;
  - o exporter canonico continua unico e compartilhado entre Hermes e
    tooling operacional do repo;
  - teste de paridade protege contra reintroducao de drift entre entrypoint de
    `server/bin` e implementacao Hermes.

| Categoria | Implementado | Parcial | Ausente/Tracked |
|---|---|---|---|
| Turno e Prioridade | 4/10 | 4/10 | 2/10 |
| SBAs e Triggers | 15/15 | 0/15 | 0/15 |
| Commander Rules | 5/8 | 2/8 | 1/8 |
| Mana e Custos | 2/6 | 4/6 | 0/6 |
| Targeting | 5/5 | 0/5 | 0/5 |
| Combate | 5/10 | 4/10 | 1/10 |
| Efeitos Contínuos | 4/5 | 1/5 | 0/5 |
| Tipos Complexos | 5/6 | 1/6 | 0/6 |
| Zonas e Objetos | 5/5 | 0/5 | 0/5 |
| Qualidade/QA | 7/7 | 0/7 | 0/7 |
| Regras oficiais 2026 | 10/12 | 2/12 | 0/12 tracked |

---

## 1. Turno e Prioridade (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Fases completas (untap,upkeep,draw,main1,combat,main2,end,cleanup) | ✅ Parcial | 4605-4828 | Upkeep só tem One Ring trigger. Falta janela de prioridade no upkeep |
| Passos de combate (beg.combat,decl.atk,decl.blk,damage,end.combat) | ⚠️ Parcial | 4773-5065 | Funções formais existem; faltam escolhas/restrições avançadas |
| Prioridade formal (APNAP pass sequence) | ✅ Básico | v9: `priority_order_from`, `emit_priority_pass_sequence`, `priority_round` | Passes APNAP são emitidos para pilha vazia e antes de resolver topo sem resposta; escolha humana/interativa e respostas card-specific seguem fora |
| Prioridade com pilha vazia | ✅ OK | 2563-2645 | `priority_round(..., phase=main)` permite ação sorcery-speed e o turno usa `run_priority_loop` |
| Sem prioridade em untap/resolução | ✅ OK | 4622-4633 | Untap não chama priority |
| Passos/fases extras (extra turn, extra combat) | ✅ Básico | v9: `extra_turns`, `extra_combats`, `play_turn_v8` | Extra turn e extra combat são suportados com cap anti-loop; fases extras arbitrárias seguem fora |
| Ações especiais (play land, morph) | ✅ OK | 4675-4700 | Land play tratado como ação especial |
| First draw em multiplayer | ✅ OK | 4642 | Ninguém pula draw no turno 1 |

**Ações imediatas**: 
- [ ] Adicionar `check_sbas_until_stable` nos pontos de prioridade ✅ FEITO
- [x] Adicionar janela de prioridade com pilha vazia nos main phases ✅
- [x] Separar passos de combate (beg.combat, decl.atk, decl.blk, damage, end) ✅

---

## 2. SBAs e Triggers (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Life <= 0 | ✅ OK | 2532-2535 | |
| Draw from empty library | ✅ OK | 2527-2531 | |
| Commander damage >= 21 | ✅ OK | 2538-2550 | |
| Deck out | ✅ Básico | v9: `Player.draw`, `check_sbas` | `failed_draw_from_empty_library` perde mesmo com cartas na mão |
| **Creature toughness <= 0 / lethal damage** | ✅ Básico | v9: `check_sbas` | Remove criatura por toughness/lethal damage |
| **Legend rule** | ✅ Básico | v9: `check_legend_rule` | Mantém a legenda mais recente por timestamp básico |
| Token fora do battlefield | ✅ Básico | v9: `check_token_lifecycle` | Token em graveyard/exile/hand deixa de existir no SBA loop |
| Aura/Equipment ilegal | ✅ Básico | v9: `check_illegal_attachments` | Aura ilegal vai ao graveyard; Equipment ilegal fica no battlefield e desanexa |
| +1/+1 e -1/-1 cancel | ✅ Básico | v9: `cancel_plus_minus_counters` | Cancela pares de marcadores via SBA e preserva aliases normalizados |
| Planeswalker 0 loyalty | ✅ Básico | v9: `check_sbas` | loyalty <= 0 move para graveyard |
| Saga capítulo final | ✅ Básico | v9: `check_saga_final_chapter` | Saga com capítulo final alcançado vai ao graveyard quando a habilidade de capítulo não está pendente |
| Battle defense 0 | ✅ Básico | v9: `check_sbas` | defense <= 0 move para exile |
| Commander em GY/exile → CZ (SBA) | ✅ Básico | v9: `ReplacementRegistry` | Zone change de commander para GY/exile/hand/library redireciona para command zone salvo escolha explícita |
| **Loop SBA até estabilizar** | ✅ Básico | v9: `check_sbas_until_stable` | Loop roda até estabilizar |
| **APNAP trigger ordering** | ✅ Básico | v9 | Triggers atuais entram como `triggered_ability`; falta player-choice avançado/aninhamento complexo |

**Ações imediatas**:
- [x] Creature SBA ✅
- [x] SBA loop ✅
- [x] Legend rule ✅
- [x] Adicionar deck out correto (trigger no draw, não check de biblioteca vazia)
- [x] APNAP ordering básico para triggers atuais

---

## 3. Commander Rules (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Commander tax (+2 por cast do CZ) | ✅ OK | 2253, 3532-3550 | |
| Commander damage tracking | ✅ Básico | v9: `commander_damage_by_source` | Ledger por `defender::commander_origin_id`; agregado legado por defensor preservado para compatibilidade |
| Commander replacement (GY/exile → CZ opcional) | ✅ Básico | v9: `ReplacementRegistry` | Redireciona para command zone salvo `commander_replacement_choice` |
| Commander replacement (hand/library → CZ opcional) | ✅ Básico | v9: `ReplacementRegistry` | Coberto no mesmo pipeline de zone change |
| Deck construction (100 cards, singleton, color ID) | ✅ Básico/diagnóstico | v9: `load_deck_with_construction_report` | Battle engine agora emite relatório de construção Commander para quantidade 99+1, singleton e off-color sem bloquear simulação; app/backend continuam sendo fonte de verdade para save/import |
| Partner/Background/Friends Forever | ⚠️ Parcial | server: `commander_pairing.dart`; v9: damage ledger por origem | Servidor valida pares oficiais; battle engine ainda não modela UX/interação completa de dois commanders na command zone |
| Commander ninjutsu do CZ | ❌ Ausente | — | |
| Color identity de DFC/Adventure | ✅ Básico | v9: `compute_color_identity` | Agrega faces/partes/modos complexos |
| Legendary Vehicle/Spacecraft com P/T como commander | ✅ Básico | server + v9 | `commander_eligibility.dart`, `DeckRulesService`, `POST /decks/:id/cards` e `is_commander_eligible_card` cobrem regra 2026 |
| Hybrid mana em Commander | ✅ Guardado | server + v9 | Continua contando como todas as cores; sem regra "or" |

**Ações imediatas**:
- [x] Commander replacement opcional (GY/exile → CZ)
- [x] Commander damage keyed por origin ID, não nome

---

## 4. Mana e Custos (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Custo de mana básico | ✅ OK | 3532 | `cost = cmd["cmc"] + player.commander_tax` |
| Pipeline 601.2 (modes→targets→cost→lock→pay) | ⚠️ Parcial | v9: `CastingContext` | Contexto captura modes/targets/X/alt/additional costs; targeting legal formal fica separado |
| Custos alternativos (kicker, flashback, etc.) | ⚠️ Parcial | v9: `alternative_cost`, `additional_costs` | Suporte contextual/custo travado; falta semântica card-specific |
| X spells | ✅ Básico | v9: `x_value` | X entra no custo travado |
| Hybrid/Phyrexian mana | ✅ Básico | v9: `parse_mana_cost`, `Player._payment_plan` | Cobre híbrido colorido `{W/U}`, monocolored hybrid `{2/W}`, Phyrexian colorido `{W/P}` e hybrid Phyrexian `{W/U/P}`; restrições card-specific seguem pendentes |
| Mana pool com spend restrictions | ✅ Básico | v9: `restricted_mana`, `card_spend_tags` | Cobre restrições por categoria de spell (`creature_spell_only`, `artifact_spell_only`, `instant_or_sorcery_spell_only`, `noncreature_spell_only`); restrições arbitrárias por carta ainda exigem handler dedicado |

**Ações imediatas**:
- [x] Pipeline 601.2 mínimo: lock-in de custo antes de pagar
- [x] Expandir 601.2 para modes, X e alternative/additional costs
- [x] Levar targeting legal formal para o bloco Targeting
- [x] Adicionar pagamento básico de hybrid colorido e Phyrexian colorido

---

## 5. Targeting (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Seleção de alvos legais | ✅ Básico | v9: `target_matches_type`, `is_legal_target`, `removal_target_candidates` | Remoções filtram target type, hexproof, shroud, protection e proteção global |
| Alvos ilegais na resolução (partial resolution) | ✅ Básico | v9: `targeting_decision`, `resolve_multi_target_removal` | Single-target valida antes de resolver; multi-target declarado resolve alvos legais e ignora ilegais |
| Hexproof/Shroud | ✅ OK | — | Respeitado via `can_target` |
| Protection | ✅ Básico | v9: `is_legal_target` | `protection_from` por cor e `protection_from_everything` bloqueiam alvo |
| Ward | ✅ Básico | v9: `check_ward`, `apply_effect_immediate`, `resolve_multi_target_removal` | Remoção é anulada para o alvo com ward não pago; pagamento permite resolução. Abilities card-specific ainda ficam fora do modelo genérico |

---

## 6. Combate (P1)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Declaração de atacantes | ⚠️ Parcial | v9: `declare_attackers_step`, `apply_basic_attack_requirements` | Função formal existe, com suporte básico a `must_attack*` e `cant_attack_alone`; escolha ainda é heurística/automática |
| Declaração de bloqueadores | ⚠️ Parcial | 4421-4462 | Bloqueadores calculados, não declarados |
| Blocked state persistente | ✅ OK | — | Bloqueado permanece mesmo se blocker morre |
| First/Double strike | ✅ OK | 4576-4580 | |
| Trample | ✅ Básico | v9: `combat_damage_assignment_order` | Excesso usa ordem formal determinística de damage assignment; escolha interativa/card-specific segue fora do modelo |
| Deathtouch | ✅ OK | 4523-4528 | |
| Lifelink | ✅ OK | 4510-4511 | |
| Damage assignment multiplayer | ✅ Básico | v9: `assign_attackers_to_defenders`, `multi_defender_attack` | Atacantes podem ser distribuídos entre múltiplos defensores; requirements/restrictions por defensor ainda pendem |
| End of combat triggers | ✅ Básico | v9: `trigger_end_of_combat` | Permanentes com `trigger=end_of_combat` entram na stack por APNAP e resolvem efeitos genéricos seguros |
| Requirements/restrictions (must attack, can't attack alone) | ✅ Básico | v9: `must_attack_if_able`, `cant_attack_alone`, `apply_basic_attack_requirements` | Cobre flags explícitas `must_attack*` e `cant_attack_alone`; custos/requisitos por defensor, "attacks if able" condicionais e escolha interativa seguem fora |

---

## 7. Zonas, LKI e Instance ID (P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Zone change → novo objeto | ✅ Básico | v9: `_zone_id` | Mantém o dict Python, mas avança identidade lógica por `_zone_id` em zone changes modelados |
| LKI (last known information) | ✅ Básico | v9: `get_lki`, `_lki_snapshot` | Snapshot antes de mover criatura do battlefield |
| Command zone | ✅ OK | 2252, 2828 | |
| Exile (face up/down) | ✅ Básico | v9: `move_to_exile` | Registra metadados `_exile_face_down`, `_exile_public`, motivo e turno sem quebrar a lista `player.exile` existente |
| Token lifecycle | ✅ Básico | v9: `check_token_lifecycle` | Token em graveyard/exile/hand deixa de existir via SBA |

---

## 8. Efeitos Contínuos / Layers (P1-P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Layer 1 (copiable values) | ✅ Básico | v9: `apply_continuous_effects` | `copy` aplica snapshot |
| Layer 2-6 (control, text, type, color, abilities) | ✅ Básico | v9: `apply_continuous_effects` | set controller/text/type/color/abilities |
| Layer 7 (P/T com subcamadas) | ✅ Básico | v9: `apply_continuous_effects` | 7b/7c/7d/7e testados |
| Timestamps e dependencies | ✅ Básico | v9: `order_continuous_effects` | dependências declaradas; sem inferência automática |
| Replacement/prevention effects | ⚠️ Parcial | v9: `ReplacementRegistry` | Ordem determinística, prevention/life/shields/commander zone-change; faltam self-replacements card-specific |

---

## 9. IA e Métricas (P1-P2)

| Item | Status | Linhas v8 | Ação |
|---|---|---|---|
| Loss tagging | ✅ OK | 4885-4920 | classify_loss implementado |
| WDWR/WPWR | ✅ OK | card_impact_analyzer.py | |
| Forensic audit | ✅ OK | battle_forensic_audit.py | |
| Quality gate | ✅ OK | master_optimizer_quality_gate.py | |
| Taxonomia canônica de derrota | ✅ Básico | `classify_loss` | Cobre `poison`, `effect_says_lose`, `concede` e tags heurísticas de screw/flood/mulligan/value |
| Telemetria de saúde do motor | ✅ Básico | v9: `EngineMetrics` | Contadores de stack, priority, SBA, replacements e replay events |
| Suite de conformidade | ✅ Básico | `test_battle_analyst_v10_3.py` | 15 cenários versionados em `CONFORMANCE_SCENARIOS` |
| Persistência operacional da telemetria | ✅ Operacional | v9: `write_engine_metrics_snapshot`, `MANALOOM_ENGINE_METRICS_DIR`, `master_optimizer_auto_cycle_cron.sh`, `engine_metrics_report.py` | Auto-cycle gera snapshots por rodada e publica `latest_engine_metrics_report.json` sanitizado |
| Persistência app-facing de `/ai/simulate` | ✅ Corrigido | `routes/ai/simulate/index.dart`, `database_setup.sql`, `test/ai_simulate_authorization_live_test.dart` | Owner-scope live test cobre privado/público; rota grava `battle_simulations.simulation_type` e `metrics` quando schema migrado existe, mantendo fallback legado |
| Diagnóstico de roles do optimize | ✅ OK | `optimization_functional_roles.dart`, `optimization_validator_test.dart` | `role_delta` usa `functional_tags` persistido antes de `semantic_tags_v2`, alinhando decisão de swap com a análise exibida ao usuário |
| Arquétipo efetivo do optimize/rebuild | ✅ OK | `optimize_archetype_support.dart`, `optimize_archetype_support_test.dart` | Política única para request genérico/específico e arquétipo detectado, removendo drift entre runtime e deck-state analysis |
| Roles estratégicos de cartas | ✅ OK | `functional_card_tags.dart`, `optimization_functional_roles.dart`, `functional_card_tags_test.dart` | `wincon`, `combo_piece`, `engine`, `payoff` e `enabler` passam pelo adapter único `resolveCardFunctionalRoles` |
| Decision Trace v1 | ✅ Slice expandido | `battle_analyst_v9.py`, `battle_replay_v10_3.py`, `replay_decision_auditor.py`, `battle_decision_trace_tests.py`, `battle_decision_strategy_auditor.py` | Side-channel cobre mulligan, cast, resposta, combat, pass, tutor, land-sacrifice, board wipe e wheel. Batch local `20260615_172608` ficou com `strategy_findings=0` e todas as categorias `coherent_in_sample`; gaps restantes são corpus maior, hand-quality/payoff-denial e tuning de threat assessment |
| Estatística Commander-safe | ⚠️ Parcial | `card_impact_analyzer.py`, `loss_mode_suggester.py` | WR com/sem carta vista e sample gate existem; ainda falta baseline hash fresco por rodada e segmentação por arquétipo/turno antes de confiar em swaps |

### 9.1 Arquivos grandes / modularização (P1)

| Arquivo | Linhas em 2026-06-10 | Status | Próxima ação |
|---|---:|---|---|
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py` | 7311 | ⚠️ Split iniciado | Seis cortes moveram helpers de mana/custo, características/identidade, lands/fontes, zone transitions, replacement/prevention e SBAs; próximo split seguro é novo domínio com conformance suite verde |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_cost_support.py` | 101 | ✅ Extraído | Centraliza parser/merge/snapshot de custo de mana sem dependência de fluxo de jogo |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_characteristics_support.py` | 173 | ✅ Extraído | Centraliza faces/modos, identidade de cor e elegibilidade Commander sem dependência de fluxo de jogo |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_land_support.py` | 110 | ✅ Extraído | Centraliza lands conhecidas, cores de fontes, normalização de nomes e `is_land` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py` | 118 | ✅ Extraído | Centraliza zone transitions parametrizadas, LKI, exile e resolution sem acoplar diretamente ao engine global |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py` | 231 | ✅ Extraído | Centraliza replacement/prevention, vida/dano e escudos; engine mantém wrappers locais para replay ativo |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py` | 381 | ✅ Extraído | Centraliza SBAs, anexos ilegais, Saga final, token lifecycle e loop de estabilização com callbacks explícitos para replay/métricas/zone move |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` | 238 | ✅ Orquestrador fino | Todos os `def test_` foram extraídos para módulos por domínio; runner mantém imports, helpers, registry e lista agregada |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rules_2026_tests.py` | 304 | ✅ Extraído | Mantém cenários e testes oficiais 2026 isolados |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py` | 330 | ✅ Extraído | Mantém regressões de combate isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_tests.py` | 151 | ✅ Extraído | Mantém regressões de replacement/prevention isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_commander_tests.py` | 145 | ✅ Extraído | Mantém regressões Commander isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py` | 112 | ✅ Extraído | Mantém regressões diretas de mana/custos isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` | 289 | ✅ Extraído | Mantém regressões de stack, priority e casting pipeline 601.2 isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py` | 328 | ✅ Extraído | Mantém regressões card-specific de Lorehold, Boros Charm, Akroma's Will e Silence isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py` | 241 | ✅ Extraído | Mantém regressões de targeting formal, hexproof/protection/ward, metadata e multi-target partial resolution isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_summoning_sickness_tests.py` | 362 | ✅ Extraído | Mantém regressões de summoning sickness, haste, vigilance, tokens, landfall token, mana source creature e Elvish Reclaimer isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py` | 229 | ✅ Extraído | Mantém regressões de zone transitions, lifecycle de tokens, remoção/tutor sem falsos positivos, land ramp/recursion e reanimation isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_import_tests.py` | 278 | ✅ Extraído | Mantém regressões de import/oracle, cache, rules table verificada, lands, artefatos curados e sync de regras normalizado |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py` | 147 | ✅ Extraído | Mantém regressões de turn flow, draw step, Approach win/turn stop, failed draw, extra turns e Unexpected Windfall isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py` | 171 | ✅ Extraído | Mantém regressões de SBA, cleanup, counters, anexos ilegais, Saga final, LKI/zone id e exile visibility isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_permanents_complex_tests.py` | 246 | ✅ Extraído | Mantém regressões de planeswalker, battle/siege, DFC, adventure, prototype e split isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_continuous_effects_tests.py` | 155 | ✅ Extraído | Mantém regressões de continuous effects/layers, sublayers 7b-7e, timestamps e dependencies isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_engine_metrics_tests.py` | 133 | ✅ Extraído | Mantém regressões de EngineMetrics, snapshot JSON sanitizado e agregador de métricas isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_conformance_tests.py` | 201 | ✅ Extraído | Mantém registry base de conformidade e regressões transversais de blocked/APNAP/prevention isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_trigger_tests.py` | 228 | ✅ Extraído | Mantém regressões de replay events, fim de combate, APNAP/timestamp e spell-cast trigger isoladas |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_misc_regression_tests.py` | 198 | ✅ Extraído | Mantém regressões auxiliares de loss taxonomy, token/land recursion, proteção de jogador e auditoria isoladas |
| `server/routes/ai/optimize/index.dart` | 2321 | ⚠️ Split iniciado | Response/cache, envelope async, request parsing, payload final, warnings finais, diagnostics finais, fallback vazio, payloads de rejeição, validação pós-processamento, retry orchestration, filtro inicial de sugestões, filtro de identidade de cor, filtro de bracket, top-up deterministic/complete, proteção de remoção de lands, reequilíbrio pós-filtros, coleta EDHREC, query de dados completos das adições/quality gate, análise virtual pós-swap, execução do `OptimizationValidator`, decisão final pós-validator, outcome code e final response do modo complete foram movidos/reutilizados; manter rota como orquestração fina e só extrair novos blocos quando houver teste de support isolado |
| `server/lib/ai/optimize_runtime_support.dart` | 551 | ⚠️ Split iniciado | Cache, quality ranking, role/scoring funcional, utilitários de filler, seleção determinística de remoções, swap building, payload/response shaping e telemetry de fallback foram movidos para support dedicado; ainda falta extrair preferências de IA ou loaders de referência do comandante |
| `server/lib/ai/optimize_payload_support.dart` | 489 | ✅ Extraído | Normalização de payload, intensidade, parser de sugestões, response shaping, retry deterministic-first e recommendation detail |
| `server/lib/ai/optimize_fallback_telemetry_support.dart` | 148 | ✅ Extraído | Escrita e aggregate de telemetry do fallback vazio do optimize |
| `server/lib/ai/optimize_functional_role_support.dart` | 323 | ✅ Extraído | Centraliza inferência funcional, matching de necessidades e score de substituta; runtime mantém export compatível |
| `server/lib/ai/optimize_removal_candidate_support.dart` | 274 | ✅ Extraído | Centraliza seleção determinística de cartas a cortar, incluindo excesso de lands, proteção de core cards e escopo agressivo |
| `server/lib/ai/optimize_swap_candidate_support.dart` | 491 | ✅ Extraído | Centraliza `findSynergyReplacements`, ranking de pares de swap e montagem determinística de candidatos sem acoplar ao runtime monolítico; runtime mantém export compatível |
| `server/lib/ai/optimize_filler_loader_support.dart` | 1222 | ⚠️ Parcial | Centraliza loaders SQL de fillers, lands e structural recovery; helpers puros de dedupe/identity/quality foram extraídos para `optimize_filler_candidate_support.dart` |
| `server/lib/ai/optimize_filler_candidate_support.dart` | 203 | ✅ Modularizado | Dedupe por nome, filtro de identidade Commander, score de filler e helpers de land fixing com teste isolado |
| `server/lib/ai/optimize_cache_support.dart` | 119 | ✅ Extraído | Centraliza assinatura de deck, cache key estável e load/save de `ai_optimize_cache` com wrappers compatíveis no runtime |
| `server/lib/ai/optimize_candidate_quality_support.dart` | 327 | ✅ Extraído | Centraliza sinais de qualidade agressiva, ranking, buckets de rejeição e loader SQL com export compatível no runtime |
| `server/lib/ai/optimize_archetype_support.dart` | 29 | ✅ Extraído | Centraliza resolução de arquétipo efetivo para optimize, rebuild e deck-state analysis |
| `server/lib/ai/optimize_route_response_support.dart` | 136 | ✅ Extraído | Centraliza contagem de swaps, resposta cacheada, diagnostics agressivos e payload `rebuild_guided` |
| `server/lib/ai/optimize_route_async_support.dart` | 179 | ✅ Extraído | Centraliza criação de job, fire-and-forget e payloads `202 Accepted` de optimize/complete async |
| `server/lib/ai/optimize_route_request_support.dart` | 65 | ✅ Extraído | Centraliza parsing inicial de request, defaults, overrides e tri-state de async |
| `server/lib/ai/optimize_route_payload_support.dart` | 186 | ✅ Extraído | Centraliza balanceamento/filtro final de sugestões e mantém `recommendations` alinhado ao payload final |
| `server/lib/ai/optimize_route_warnings_support.dart` | 61 | ✅ Extraído | Centraliza montagem de warnings finais de optimize: cartas inválidas, identidade de cor, bracket, tema e fallback vazio |
| `server/lib/ai/optimize_route_diagnostics_support.dart` | 37 | ✅ Extraído | Centraliza `optimize_diagnostics` de fallback vazio e merge incremental de diagnostics sem sobrescrita |
| `server/lib/ai/optimize_route_empty_fallback_support.dart` | 103 | ✅ Extraído | Centraliza seleção de candidatas de remoção, aplicação de swaps e razões do fallback de sugestões vazias |
| `server/lib/ai/optimize_route_quality_rejection_support.dart` | 48 | ✅ Extraído | Centraliza payloads de rejeição `OPTIMIZE_NO_SAFE_SWAPS` e `OPTIMIZE_QUALITY_REJECTED` |
| `server/lib/ai/optimize_route_post_validation_support.dart` | 146 | ✅ Extraído | Centraliza warnings/improvements pós-processamento de identidade de cor, coleta EDHREC, tema e análise antes/depois |
| `server/lib/ai/optimize_route_retry_support.dart` | 64 | ✅ Extraído | Centraliza plano de retry deterministic-first → IA e metadata de respostas IA |
| `server/lib/ai/optimize_route_suggestion_filter_support.dart` | 76 | ✅ Extraído | Centraliza balanceamento/sanitização inicial de sugestões, proteção de comandante/core e filtro de no-op |
| `server/lib/ai/optimize_route_color_identity_filter_support.dart` | 38 | ✅ Extraído | Centraliza filtro puro de adições por identidade de cor do comandante |
| `server/lib/ai/optimize_route_bracket_policy_filter_support.dart` | 47 | ✅ Extraído | Centraliza filtro de adições por política de bracket preservando ordem/repetição da lista validada |
| `server/lib/ai/optimize_route_complete_top_up_support.dart` | 91 | ✅ Extraído | Centraliza top-up determinístico de básicos no modo complete sem acoplar SQL |
| `server/lib/ai/optimize_route_land_removal_protection_support.dart` | 62 | ✅ Extraído | Centraliza proteção contra remoção de terrenos quando a contagem de lands está baixa |
| `server/lib/ai/optimize_route_rebalance_support.dart` | 128 | ✅ Extraído | Centraliza plano de reequilíbrio pós-filtros, aplicação de substitutas e truncamento final |
| `server/lib/ai/optimize_route_final_gate_support.dart` | 156 | ✅ Extraído | Centraliza decisão final de quality gate, validação serializada e Semantic Layer v2 após o `OptimizationValidator` |
| `server/lib/ai/optimize_complete_support.dart` | 1450 | ⚠️ Split iniciado | Orquestra modo complete DB-backed; helpers puros de mana foram extraídos para suporte dedicado, mas o arquivo ainda concentra seed/filler/final response |
| `server/lib/ai/optimize_complete_mana_support.dart` | 118 | ✅ Extraído | Centraliza limite de básicos, demanda de cores e plano ponderado de terrenos básicos do modo complete com export compatível |
| `server/lib/commander_eligibility.dart` | 23 | ✅ Extraído | Centraliza elegibilidade Commander 2026 para DeckRulesService e rotas incrementais |
| `server/lib/commander_pairing.dart` | 105 | ✅ Extraído | Centraliza pares Partner, Partner with, Background, Friends Forever, Doctor's companion e normalização de nome físico |
| `server/lib/ai/optimization_validator.dart` | 904 | Aceitável por enquanto | Não splitar antes de isolar o optimize route/runtime |
| `server/lib/ai/optimization_functional_roles.dart` | 768 | Aceitável por enquanto | Manter coeso; split só se crescer com novas políticas |

---

## O Que Já Foi Implementado (2026-06-09)

| Fix | Status |
|---|---|
| SBA loop (check_sbas_until_stable) | ✅ |
| Creature toughness/damage SBA | ✅ |
| Legend rule SBA | ✅ |
| 2 call sites updated to until_stable | ✅ |
| APNAP trigger ordering básico | ✅ |

## Próximos Passos (Ordem de Impacto)

1. **Rollout controlado no Hermes runtime** — fazer backup do SQLite real, aplicar snapshot agregado e rodar report-only contra o DB real
2. **Identidade semântica de carta** — separar explicitamente printing id/oracle id/faces para DFC/MDFC, localized names, rulings e dedupe de regra
3. **Agregação segura de multi-função por carta** — manter o sync PG -> Hermes agregado por `card_id` e aplicar no SQLite runtime real somente após consumidores críticos compatíveis
4. **Learned decks Commander completo** — evoluir contrato de learned decks de 1 commander + 99 main para também aceitar pares oficiais quando houver corpus validado
5. **Integração avançada de tipos complexos** — efeitos específicos de Omen/Prepare/Paradigm/Station por carta concreta
6. **Modularização segura** — continuar split do engine Hermes por domínio e depois route/runtime de optimize
7. **Targeting avançado** — seleção complexa/card-specific além de remoções declaradas; o bloco formal mínimo já está isolado em `battle_targeting_tests.py`
8. **Suite de conformidade expandida** — triggers aninhadas, escolha de ordenação e regressões v9
9. **Operacionalização Hermes** — plugar relatório agregado de telemetria nas crons se necessário

---

## 10. Regras oficiais 2026 / Mecânicas modernas (P1-P2)

Fonte consolidada: `RULES_SOURCE_COVERAGE_AUDIT_2026-06-10.md` e
`BATTLE_RULES_2026_STRATEGIC_REVIEW_2026-06-11.md`.
Fonte primária para números novos de Edge of Eternities:
`https://magic.wizards.com/en/news/announcements/edge-of-eternities-update-bulletin`.
Esta mesma fonte é também a âncora primária para Legendary Vehicle/Spacecraft
com P/T como commander em `903.3`/`903.12c`; o artigo de mecânicas fica apenas
como explicação operacional.
Fonte Commander/hybrid: `https://magic.wizards.com/en/formats/commander` e
`https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026`.

| Item | Status | Implementação | Limite restante |
|---|---|---|---|
| Omen cards | ✅ Parcial | `get_card_characteristics(..., cast_mode="omen")` e `compute_color_identity` | Efeitos card-specific por carta concreta |
| Station cards | ✅ Parcial | `activate_station_ability` | Escolha humana/interativa de criatura a stationar |
| Spacecraft | ✅ Parcial | `is_vehicle_or_spacecraft_card`, `activate_station_ability` | Efeitos específicos de cada Spacecraft |
| Warp | ✅ Parcial | `cast_warp_spell_from_hand`, `process_warp_end_step`, `cast_warp_card_from_exile` | Interações card-specific e permissões complexas |
| Prepare / Preparation cards | ✅ Parcial | `prepare_spell_copy`, `cleanup_prepared_copies` | Cast completo da cópia preparada por UI/interação |
| Paradigm | ✅ Parcial | `resolve_paradigm_spell` rastreia a fonte | Cópia automática na primeira main phase futura segue como tracked gap |
| Flashback | ✅ Básico | `cast_flashback_spell_from_graveyard`, exile replacement | Custos/restrições específicas por carta |
| Lander tokens | ✅ Básico | `create_lander_token` | Token variants por carta concreta |
| Void/Repartee/Opus/Increment/Infusion/Converge | ✅ Telemetria | `modern_ability_word_signals` | Sem enforcement porque ability words não têm efeito próprio |
| Multiplayer attack distribution | ✅ Básico | `assign_attackers_to_defenders` + `multi_defender_attack` | Requirements/restrictions por defensor e escolha interativa |
| Hybrid mana em Commander | ✅ Guardado | servidor + v9 preservam identidade combinada | Não flexibilizar; Wizards confirmou que a regra não mudou em 2026-02-09 |
| `is_commander` fora de Commander/Brawl | ✅ Guardado | `DeckRulesService.validateCommanderSlotAllowedForFormat` | Mantém todas as rotas que delegam ao serviço alinhadas com a regra de formato |
| No sideboard/outside-game em Commander | ✅ Guardado | `DeckRulesService.validateNoUnsupportedDeckSections`, parser de import e rotas de cards | ManaLoom ainda não modela sideboard/wishboard/outside-game em decks salvos; entradas com `zone/board/section=sideboard`, flags sideboard/wishboard/maybeboard ou cabeçalho textual `Sideboard` agora falham cedo em vez de serem persistidas como main deck |

### 10.1 Decisão estratégica 2026-06-11

O suporte atual é intencionalmente mínimo e orientado a simulação Commander.
Não transformar `battle_analyst_v9.py` em judge engine completo neste ciclo.
As etapas do plano estratégico estão classificadas assim:

| Etapa | Classificação atual |
|---|---|
| Documentação/matriz oficial | Implemented |
| Commander legality 2026 e hybrid estrito | Implemented |
| Warp/Flashback/cast-from-exile | Partial mínimo testado |
| Station/Spacecraft | Partial mínimo testado |
| Prepare/Omen/Paradigm | Partial mínimo testado |
| Multiplayer Commander combat | Implemented básico |
| Ability words modernos | Telemetry, sem enforcement |

Ordem de implementação quando houver corpus concreto:

1. **Warp/Flashback/cast-from-exile card-specific** — validar custo, timing e
   exile replacement por carta real antes de promover efeito.
2. **Station/Spacecraft striations** — suportar múltiplos thresholds e efeitos
   impressos somente para Spacecraft que apareçam em deck real.
3. **Prepare/Omen/Paradigm** — adicionar resolução completa apenas por carta
   usada; manter características/cópia/exile tracking como base genérica.
4. **Multiplayer combat avançado** — requirements/restrictions por defensor,
   custos para atacar, blockers em APNAP e efeitos que referenciam
   "defending player". O suporte genérico a `must_attack*` e
   `cant_attack_alone` já existe como camada básica.
5. **Ability-word telemetry** — permanecer como sinal semântico; enforcement só
   se o texto da carta tiver regra executável própria.

Gate obrigatório: não criar regra genérica nova para Warp, Station, Prepare,
Omen, Paradigm ou ability words sem carta real no corpus, replay incorreto e
teste focado. Caso contrário, manter como tracked gap.

---

## 11. Multi-função por carta e agregação segura PG -> Hermes (P1)

### Status

Partially implemented. O bug operacional de 2026-06-11 foi contido no sync do
target deck para Hermes sem usar `LEFT JOIN LATERAL (...) LIMIT 1` para
`card_battle_rules`. O sync agora agrega funções/regras por `card_id` e grava
`functional_tags_json`, `semantic_tags_v2_json`, `battle_rules_json`,
`deck_hash`, `semantics_hash`, `ruleset_hash` e `sync_run_id`. A aplicação no
SQLite runtime real do Hermes foi executada em 2026-06-11 com backup e
validação. O gap permanece aberto por política e cobertura: scripts
históricos/manuais ainda podem assumir `functional_tag` único, e a derivação de
`card_battle_rules` para `card_function_tags` ainda precisa de taxonomia, gate
de confiança/revisão e limpeza de stale tags. O dedupe lógico por
`logical_rule_key` foi implementado e aplicado no Hermes AWS, mas ainda não
autoriza derivação automática de tags funcionais.

### Evidência

- PostgreSQL `deck_cards` é a fonte canônica de cardinalidade do deck:
  `server/database_setup.sql` define `UNIQUE(deck_id, card_id)` e `quantity`.
- PostgreSQL `card_battle_rules` permite múltiplas regras por carta:
  `card_id` é indexado, mas não único; a chave primária é `normalized_name`.
- `card_function_tags` é multi-tag por desenho:
  a chave efetiva usada pela camada de IA é `(card_id, tag, source)`.
- O sync Hermes corrigido tem guard de soma de quantidade e agregação semântica
  por `card_id`; a evidência está em
  `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`.

### Invariante obrigatório

Todo consumidor em contexto de deck deve preservar:

```text
SUM(deck_cards.quantity) antes do enriquecimento
==
SUM(deck_cards.quantity) depois do enriquecimento
```

Uma carta pode ter múltiplas funções e múltiplas regras executáveis, mas isso
não pode criar múltiplas cartas no deck. Contadores de papel podem somar mais
que 100 porque uma carta pode contar como `ramp` e `engine`, por exemplo; o
total legal do deck continua vindo somente de `deck_cards.quantity`.

### Modelo correto

Separar três contratos:

| Contrato | Fonte | Uso |
|---|---|---|
| Cardinalidade do deck | `deck_cards.quantity` | total 100, main 99, hash de deck, validação Commander |
| Função de deckbuilding | `card_function_tags`, `card_semantic_tags_v2` | ramp/draw/removal/wipe/protection/engine/payoff/wincon |
| Regra executável | `card_battle_rules` | battle engine, replay, forensic audit, simulação |

Nenhum consumidor deve fazer join bruto de `deck_cards` com tabelas que possam
ter múltiplas linhas por `card_id`. Antes de tocar `deck_cards`, essas tabelas
devem ser reduzidas para uma linha por carta.

### Fechamentos obrigatórios do contrato

- **Taxonomia canônica**: normalizar categorias antes de escolher
  `functional_tag`. Exemplo: `board_wipe` deve virar `wipe`; `unknown` não
  deve ser promovido; tipos estruturais (`artifact`, `creature`, `land`) só
  devem ser fallback quando não houver papel funcional real.
- **Buckets sobrepostos**: `functional_tags_json` é membership overlay, não
  partição. Uma carta pode contar em `ramp` e `engine`; por isso
  `SUM(role_qty.values())` pode ser maior que `SUM(deck_cards.quantity)` sem
  indicar deck overfull.
- **Dedupe lógico de regras**: agregar por `card_id` evita duplicar cartas,
  mas não impede duas regras equivalentes no mesmo `battle_rules_json`.
  Definir `logical_rule_key` por carta/face/efeito/papel antes de agregar e
  manter somente o melhor exemplar por chave lógica.
- **Promoção confiável para `card_function_tags`**: tags derivadas de
  `card_battle_rules` só podem virar fonte canônica quando passarem por gate.
  No schema atual, `curated` é `source`, não `review_status`. Portanto, o gate
  deve considerar algo como `review_status IN ('verified', 'active')`,
  `source IN ('manual', 'curated')` quando aplicável e piso mínimo de
  `confidence`.
- **Limpeza de stale tags derivadas**: se a futura derivação usar
  `source='card_battle_rules_v1'`, cada rodada deve remover desse source as
  tags que não aparecem mais no conjunto derivado atual para os `card_id`
  tocados.
- **Hashes separados**: `deck_hash` deve representar somente estrutura do deck
  (`card_id`, `quantity`, `is_commander`). Mudanças em tags/regras devem gerar
  `semantics_hash` separado, para não quebrar baseline/quality gate quando só a
  camada semântica mudou.
- **Autoridade SQLite vs PostgreSQL**: `functional_tags_json` e
  `battle_rules_json` no SQLite Hermes são cache/snapshot operacional. A fonte
  de verdade continua sendo PostgreSQL (`card_function_tags`,
  `card_semantic_tags_v2`, `card_battle_rules`). A tabela SQLite normalizada de
  battle rules continua sendo a fonte para executor/auditor; o JSON agregado é
  para consumidores em contexto de deck.

### Task aberta - canonização de `card_battle_rules`

Problema original:

- a arquitetura documentada diz que PostgreSQL `card_battle_rules` é a fonte
  de verdade revisável;
- o runtime de battle resolvia `HANDCRAFTED_KNOWN_CARDS` antes do registry PG;
- hotfixes recentes de cartas críticas foram promovidos diretamente em código
  para fechar coerência do simulador rápido, o que era aceitável como
  contenção, mas não como modelo permanente.

Task:

1. Inventariar todo o conteúdo de `HANDCRAFTED_KNOWN_CARDS`.
2. Classificar cada entrada em:
   - `engine_primitive`
   - `card_rule_promotable`
   - `temporary_hotfix`
3. Migrar para `card_battle_rules` todas as `card_rule_promotable` estáveis,
   com `source`, `review_status`, `confidence`, `oracle_hash` e
   `logical_rule_key`.
4. Sincronizar PG -> SQLite Hermes e provar que o replay continua coerente sem
   depender do override manual para essas cartas.
5. Adicionar guard rail que falha quando carta auditada/promovível fica só no
   código sem waiver explícito.

Primeira rodada executada em 2026-06-16:

- auditor: `audit_handcrafted_battle_rule_canonicalization.py`
- artefato: `server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16/summary.json`
- resumo: `486` overrides manuais, `456` já batem com PG, `30` ainda estão em
  drift, sendo `17` classificados como `temporary_hotfix` e `13` como
  `card_rule_promotable` legados a reconciliar
- refresh-only no SQLite: `Crop Rotation`, `Harrow`, `Mox Diamond`,
  `Roiling Regrowth`

Segunda rodada executada em 2026-06-16:

- os `17` hotfixes foram reconciliados seletivamente para PostgreSQL
  `card_battle_rules` e SQLite `battle_card_rules`
- auditor pós-sync: `473` `pg_state=exact_match`, `13` `pg_state=drift`,
  `469` `sqlite_state=exact_match`, `17` `sqlite_state=drift`
- o runtime local do `battle_analyst_v9.py` foi corrigido para resolver
  `MANALOOM_KNOWLEDGE_DB`/`MANALOOM_KNOWLEDGE_DIR`, depois `/opt/...` se existir,
  e cair para `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
  quando estiver fora do Hermes AWS
- teste focado
  `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` passou, provando
  que as `17` cartas promovidas resolvem via SQLite/PG sem depender do override
  manual em `KNOWN_CARDS`

Terceira rodada executada em 2026-06-16:

- a tentativa inicial de promover os `13` drifts legados expôs um bug no sync:
  `sync_battle_card_rules.py` estava aplicando oracle normalization tambem em
  `source='manual'`, distorcendo a semantica antes de persistir
- o sync foi corrigido para normalizar apenas regras `generated`
- depois disso, os `13` drifts legados foram promovidos corretamente e os `4`
  casos SQLite-only receberam refresh
- auditor final:
  - `486` `pg_state=exact_match`
  - `486` `sqlite_state=exact_match`
  - `486` `already_canonicalized`
- o guard rail do fallback runtime foi expandido para cobrir os `17` hotfixes,
  os `13` drifts legados e os `4` casos refresh-only dentro do regression pack
  principal `test_battle_analyst_v10_3.py`

Quarta rodada executada em 2026-06-16:

- o runtime foi limpo do primeiro lote seguro de overrides canonizados;
- `34` cartas sairam de `KNOWN_CARDS` / `HANDCRAFTED_KNOWN_CARDS` e agora
  resolvem exclusivamente via SQLite/PG no fluxo normal;
- o teste
  `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` foi atualizado para
  exigir ausencia em `HANDCRAFTED_KNOWN_CARDS` e equivalencia direta com o
  `logical_rule_key` do registry;
- o auditor pos-limpeza fechou em:
  - `452` overrides manuais restantes
  - `452` `pg_state=exact_match`
  - `452` `sqlite_state=exact_match`
  - `452` `already_canonicalized`

Quinta rodada executada em 2026-06-16:

- o runtime deixou de manter inventario manual ativo;
- `HANDCRAFTED_KNOWN_CARDS` passa a ser zerado no import e so volta a conter
  entradas em cenarios de teste ou waiver operacional explicito;
- `sync_battle_card_rules.py --skip-generated` agora produz `0` linhas
  manuais no estado normal;
- auditor final pos-remocao total do inventario ativo:
  - `0` overrides manuais restantes
  - `0` classificacoes pendentes
  - runtime battle dependente apenas de SQLite/PG para regras canonizadas
- o regression pack principal `test_battle_analyst_v10_3.py` permaneceu verde
  nesse estado.

Critério de pronto:

- cartas promovidas passam a resolver via `card_battle_rules`;
- overrides em código ficam limitados a primitivas do motor e hotfixes
  temporários documentados;
- existe relatório de inventário `primitive/promotable/hotfix`;
- battle tests e replay audit passam antes e depois da migração;
- docs Hermes e docs locais deixam claro que override manual é exceção, não
  caminho normal.

### Próxima implementação recomendada

Concluído no Slice 1:

1. Criar uma query/helper compartilhado para agregação por `card_id`:
   - `functional_tags_json`: array ordenado de tags funcionais distintas;
   - `semantic_tags_v2_json`: JSON/array agregado quando aplicável;
   - `battle_rules_json`: array ordenado de regras com `effect_json`,
     `deck_role_json`, `source`, `confidence`, `review_status`,
     `rule_version` e `normalized_name`.
2. Usar `jsonb_agg(... ORDER BY ...)` no PostgreSQL e
   `COALESCE(..., '[]'::jsonb)` para saída determinística.
3. Atualizar `sync_pg_target_deck_to_hermes.py` para persistir esses campos no
   SQLite Hermes como JSON text, mantendo campos legados somente como projeção:
   - `functional_tag` pode continuar como primary/legacy role;
   - `functional_tags_json` deve preservar o conjunto completo;
   - `battle_rules_json` deve preservar todas as regras da carta.
4. Adicionar migração idempotente no SQLite Hermes para novas colunas JSON.
5. Validar suporte JSON do SQLite em runtime; se `json_each/json_extract` não
   estiverem disponíveis, os scripts devem fazer parse em Python.

Concluído no bridge de consumidores ativos:

6. Atualizar `master_optimizer_common.py` e `slot_optimizer.py` para consumir
   `functional_tags_json` com fallback para `functional_tag`.
7. Separar `deck_hash` estrutural de `semantics_hash`.
8. Atualizar `_mana_validator.py`, `_run_validation.py` e
   `_update_cron_status.py` para usar membership de `functional_tags_json`,
   mantendo `SUM(deck_cards.quantity)` como cardinalidade.

Ainda pendente:

9. Manter `card_battle_rules` fora da contagem de deckbuilding quando o objetivo
   for função de deck; usar essa tabela apenas como regra executável/revisável.
10. Revisar manualmente os candidatos positivos do slot scan Lorehold
   `semantic_snapshot_smoke` antes de qualquer apply:
   `Loran's Escape`, `Chain Lightning`, `Erode`, `Steelshaper's Gift`,
   `Furygale Flocking` e `The Battle of Bywater`.
11. Adicionar derivação controlada de `card_battle_rules` para
   `card_function_tags` somente depois de definir taxonomia canônica,
   gate de `source/review_status/confidence` e limpeza de stale tags.

Concluído no Slice 2:

12. Aplicar no Hermes AWS a implementação local de `semantics_hash`/`ruleset_hash`
   em baseline, quality gate, slot scan e apply; validado com backup,
   apply controlado e slot smoke. Evidência: backup
   `knowledge.db.pre-ruleset-76d828d2.20260611T194820Z`, baseline `id=2` com
   `60` jogos, `7` linhas de `slot_benchmarks` na phase `ruleset_hash_smoke`
   contendo `baseline_semantics_hash` e `baseline_ruleset_hash`, deck restaurado
   com `100` rows, `100` quantity e `1` commander.

Concluído no Slice 3:

13. Implementar `logical_rule_key` no snapshot Hermes, deduplicar regras
    equivalentes por face/variante/efeito/papel e manter o melhor exemplar por
    prioridade de `review_status`, `source`, `confidence` e `rule_version`.
    Smoke PG -> SQLite temporário e Hermes AWS real de Lorehold: `100` cards,
    `100` quantity, `1` commander, `100` regras vistas, `98` regras escritas,
    `2` deduped e `0` regras sem `logical_rule_key`.
14. Aplicar Slice 3 no Hermes AWS com backup
    `knowledge.db.pre-logical-rule-55af86c4.20260611T201027Z`; smoke remoto:
    baseline `id=3`, `36` jogos, phase `logical_rule_smoke`, `8` slot rows
    com `baseline_semantics_hash` e `baseline_ruleset_hash`, deck restaurado
    com `100` rows, `100` quantity, `1` commander e sem Mox premium.

Concluído no Slice 4 report-only:

15. Criar `derive_functional_tags_from_battle_rules.py` para propor, sem
    aplicar, candidatos `card_function_tags` derivados de regras confiáveis.
    Gate atual: `card_id` obrigatório, `review_status` `verified/active`,
    `source` `manual/curated`, confidence >= `0.75` e tag derivável.
    Smoke PG report-only revisado em `86ef9062`: `3156` regras vistas, `89`
    novos candidatos, `261` já presentes, `2806` rejeitados por gate, `27`
    candidatos low-risk review e `62` manual-review; `apply=false`.

Concluído no Slice 5 backend snapshot:

16. Criar `card_intelligence_snapshot` no backend como view agregada por
    `card_id`, sem API pública nova. A view reduz previamente
    `card_function_tags`, `card_role_scores`, `commander_card_synergy`,
    `card_semantic_tags_v2`, `card_battle_rules`, `card_legalities` e
    `card_rulings` para uma linha por carta antes de juntar com `cards`. Isso
    preserva múltiplas funções/regras sem multiplicar linhas de deck.
17. Ligar a criação da view nos scripts de fundação/backfill/meta-signals:
    `candidate_quality_data_foundation.dart`,
    `semantic_layer_v2_backfill.dart` e
    `candidate_quality_meta_signals.dart`.
18. Adicionar teste anti-fanout em `candidate_quality_data_support_test.dart`
    para garantir que a view não faz `LEFT JOIN` bruto em
    `card_battle_rules`, `card_function_tags` ou `card_semantic_tags_v2`.
19. Criar `card_identity_bridge` em `import_card_lookup_service.dart`,
    materializando aliases canônicos e localizados com `card_id`, `oracle_id`,
    `scryfall_id`, lookup normalizado, idioma, source e prioridade de match.
    A bridge é garantida junto de `card_localized_names`, sem substituir ainda
    todos os consumidores históricos.
20. Migrar consumidores seguros para `card_intelligence_snapshot` com fallback:
    `GET /decks/:id/analysis`, `POST /decks/:id/ai-analysis`,
    `POST /decks/:id/recommendations` e
    `POST /ai/weakness-analysis`. Em 2026-06-17,
    `/decks/:id/analysis` foi alinhada ao mesmo padrão: quando a view existe,
    lê `function_tag_details` e `semantic_tags_v2` já agregados; quando não
    existe, mantém fallback por subquery `jsonb_agg` por `card_id`, sem
    multiplicar linhas de `deck_cards`.
21. Validar SQL real das duas views em PostgreSQL com transação rollback:
    `card_identity_bridge=305.905` aliases/identidades e
    `card_intelligence_snapshot=34.329` cartas.

Concluido no Slice 6 persistencia PostgreSQL:

21.1. Resultado da validação global de dados em 2026-06-15:
   `docs/hermes-analysis/DATA_MODEL_FINAL_VALIDATION_2026-06-15.md`
   confirmou em PostgreSQL real que `card_identity_bridge`,
   `card_intelligence_snapshot` e `optimize_candidate_quality_summary` estão
   persistidas. A migration `022_create_card_identity_and_intelligence_views`
   cria as dependências idempotentes, `card_meta_insights`,
   `card_localized_names`, tabelas/índices de candidate quality e as três
   views. Contagens pós-migração: `card_identity_bridge=305.905`
   aliases/identidades e `card_intelligence_snapshot=34.329` cartas.
21.2. A mesma validação confirmou que o join direto
   `deck_cards -> card_battle_rules` multiplica linhas (`36.440` rows contra
   `35.992` `deck_cards` distintos, `448` linhas extras), enquanto
   `card_battle_rules` tem `10` cards com múltiplas regras e
   `card_function_tags` tem `22.675` cards com múltiplas tags. Portanto,
   qualquer consumidor de deckbuilding deve usar snapshot/agregação por
   `card_id`, nunca `LEFT JOIN` bruto em tabelas multi-linha.
21.3. A branch `origin/codex/hermes-analysis-docs` foi triada em 2026-06-15
   até `9adb0989`. Achados recentes sobre `deck_matchups` e
   `deck_weakness_reports` como write-only foram rejeitados contra o `master`
   atual porque `server/routes/ai/simulate-matchup/index.dart` lê
   `deck_matchups` e `server/routes/ai/weakness-analysis/index.dart` lê
   `deck_weakness_reports`. Se o Hermes repetir esse achado, a query de
   auditoria dele precisa restringir melhor runtime/produto e branch analisada.
21.4. Hermes AWS segue apto como laboratório: container `hermes_agent` ativo,
   Flutter `3.44.0`, Dart `3.12.0`, Python `3.13.5`, `25` crons registrados e
   `13` habilitados. Porém o workspace remoto está dirty/out-of-sync; não
   promover artefatos Hermes sem triagem e sem revalidação local/source-backed.

Concluido no Slice 7 commander learning snapshot:

21.5. Criada a view interna `commander_learning_snapshot` via migration
   `023_create_commander_learning_snapshot`. A view agrega por
   `commander_name_normalized` os sinais de `commander_learned_decks`,
   `commander_card_usage` e `commander_card_synergy`, resolve nomes de uso por
   `card_identity_bridge` quando possível e preserva listas como JSON agregado.
   Ela não expõe `metadata` bruto do Hermes; apenas campos seguros como nome do
   deck aprendido, arquétipo, contagem, score, legalidade, wincons e cobertura.
21.6. O auditor `server/bin/audit_data_model_links.dart` passou a tratar
   `commander_learning_snapshot` como view crítica. Se a view existir, a ação
   recomendada muda de "criar" para "adotar em loaders futuros"; se faltar, a
   validação aponta pendência de migration/deploy.
21.7. Testes estáticos foram adicionados para garantir que a migration `023`
   cria as tabelas base necessárias antes da view, que a snapshot usa
   `card_identity_bridge`, que agrega por comandante e que não carrega
   `metadata` bruto do Hermes.

Concluido no Slice 8 candidate quality anti-fanout:

21.8. A view interna `optimize_candidate_quality_summary` deixou de juntar
   diretamente `card_function_tags`, `card_role_scores` e
   `card_semantic_tags_v2` em `cards`. Ela agora agrega cada fonte em CTE por
   `card_id` antes do join final, mantendo o mesmo shape (`function_tags`,
   `best_role_score`, `scored_roles`, `semantic_tags_v2`) sem cross-product
   interno entre fontes multi-linha.
21.9. `candidate_quality_data_support_test.dart` recebeu guarda estática para
   impedir regressão para `LEFT JOIN` bruto nessas tabelas multi-linha dentro
   de `optimize_candidate_quality_summary`.

Concluido no Slice 9 commander learning contract/middleware:

21.10. A rodada Hermes `module-coherence-server-lib-routes-app-lib`
   (`22ba2e62`) foi triada contra o `master`. O achado sobre
   `deck_rebuild_created` foi rejeitado como stale porque
   `server/routes/users/me/activation-events/index.dart` já aceita o evento e
   `activation_events_contract_test.dart` cobre a emissão app/backend.
21.11. O endpoint app-facing `GET /ai/commander-learning` foi documentado em
   `server/doc/API_CONTRACTS_AND_DATA_MAP.md` com consumidores Flutter, payloads
   sem/com `commander`, fonte `commander_learned_decks` e restrição de não
   expor `metadata` bruto do Hermes.
21.12. `server/routes/ai/_middleware.dart` agora mantém
   `/ai/commander-learning` autenticado, mas fora de `aiPlanLimitMiddleware` e
   `aiRateLimit`, pois o handler atual faz leitura local de PostgreSQL e não
   chama OpenAI/fonte externa. `commander_learned_deck_support_test.dart`
   recebeu guarda estática para esse comportamento.

Concluido no Slice 10 commander learning safe summary/runtime adoption:

21.13. O caminho sem `commander` de `GET /ai/commander-learning` foi validado
   no iPhone Simulator contra produção em 2026-06-16. A tentativa de usar a
   view completa `commander_learning_snapshot` no hot path levou cerca de
   13,9s-15,3s e estourou o timeout mobile de 15s em prova viva. A rota agora
   usa uma agregação leve e segura de `commander_learned_decks` ativos, sem
   `metadata`, com `source=pg_commander_learned_deck_summary`.
21.14. O caminho com `commander` continua lendo `commander_learned_decks`,
   porque precisa do `card_list` persistido para montar o preview/salvamento
   do deck aprendido. A arquitetura prática fica: tabela PostgreSQL como fonte
   operacional controlada para disponibilidade/detalhe, e
   `commander_learning_snapshot` como snapshot interna de linhagem/diagnóstico
   até ser materializada ou otimizada para uso em hot path.
21.15. Payloads públicos de `commander-learning` e `commander-reference`
   deixaram de expor `metadata` bruto do Hermes. Metadata segue disponível
   internamente para `role_summary`/contagens, mas usuários normais recebem
   apenas campos agregados seguros.
21.16. Revalidação local em 2026-06-17 contra
   `origin/codex/hermes-analysis-docs@b53295fe` confirmou que os achados
   estruturais Hermes sobre `deck_rebuild_created`, contrato
   `/ai/commander-learning` e middleware de IA já estão resolvidos no `master`.
   A mesma triagem marcou como stale os achados de knowledge synthesis sobre
   Underworld Breach, tapped lands no goldfish, `functional_tags` persistidas no
   classificador principal, sinal EDHREC e value engines: todos possuem código
   ou teste vivo no backend atual. Não reabrir esses itens sem nova evidência
   de regressão em `master`.

22. `loadOptimizeDeckContext` passou a preferir `card_intelligence_snapshot`
    quando a view existe, preservando fallback por subquery agregada para bancos
    antigos. Isso remove duplicação de leitura de `card_function_tags` e
    `card_semantic_tags_v2` no contexto que alimenta optimize/quality gate. O
    sync Hermes `sync_pg_target_deck_to_hermes.py` já prefere
    `card_intelligence_snapshot` quando a view existe e mantém fallback CTE
    agregado para bancos antigos.
23. Adotar `commander_learning_snapshot` em futuros loaders profundos de
    aprendizado/diagnóstico em vez de remontar `commander_learned_decks`,
    `commander_card_usage` e `commander_card_synergy` manualmente. Qualquer
    exposição app-facing deve continuar escondendo metadata Hermes bruta.
24. Criar teste com banco temporário para provar cardinalidade real em runtime:
    uma carta com duas tags e duas regras deve continuar retornando uma linha
    de carta/deck pelos caminhos de produto.
25. Adicionar snapshots opcionais separados para fontes que não são garantidas
    em todo ambiente local (`card_localized_names`, `price_history`,
    `commander_reference_deck_cards`) sem tornar a view principal frágil.

### Testes obrigatórios antes de merge

- Unit test do helper SQL: uma carta com duas `card_battle_rules` e duas
  `card_function_tags` continua retornando uma linha de deck.
- Regressão PG -> Hermes: `cards_seen`, `quantity_seen`, `quantity_written` e
  `SUM(deck_cards.quantity)` permanecem 100 em Commander.
- Teste de determinismo: duas execuções sem mudança geram JSON byte-identical.
- Teste de idempotência: rerodar derivação/sync não duplica tags nem regras.
- Teste de stale cleanup: uma tag derivada com
  `source='card_battle_rules_v1'` some quando a regra que a originou deixa de
  derivar essa tag.
- Teste de gate de revisão: regra `needs_review` ou com baixa confiança aparece
  em `battle_rules_json`, mas não é promovida para `card_function_tags`.
- Teste de dedupe lógico: duas linhas equivalentes de regra geram uma entrada
  canônica em `battle_rules_json`, preservando metadados suficientes para
  auditoria.
- Teste de preservação: `battle_rules_json` contém todas as regras esperadas da
  carta; `functional_tags_json` contém todas as tags esperadas.
- Teste de hash: mudar somente tags/regras altera `semantics_hash`, mas não
  altera `deck_hash`.
- Teste de overlay: carta multi-role conta em todos os papéis aplicáveis, mas
  validadores não tratam `SUM(role_qty.values()) > total_cards` como overfull.
- Teste de separação semântica: land-back MDFC pode entrar como heurística
  `land_like`, mas não vira land real para tutor, legalidade ou castabilidade
  zone-sensitive.

### Fora de escopo desta correção

- Trocar todo o battle engine para judge engine completo.
- Achatar carta para uma única função definitiva.
- Usar `card_battle_rules` como tabela principal de papéis de deckbuilding.
- Criar enforcement novo de IA baseado em tags sem scorecard e replay real.

### Critério de conclusão

Este gap só deve ser fechado quando o sync PG -> Hermes, os scorecards e os
consumidores de deck enriquecido estiverem usando agregados por `card_id`, sem
`LIMIT 1` como mecanismo de preservação de cardinalidade, e com validação
automática impedindo que qualquer enriquecimento altere o total de cartas.

---

## 12. Battle/AI/Hermes/Lorehold - mapa para próximas tratativas (P1)

### Documento base

O detalhamento atual da lógica foi consolidado em:

- `docs/hermes-analysis/BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md`

Usar este documento antes de aceitar qualquer plano novo sobre:

- battle simulator;
- geração de decks com IA;
- optimize/rebuild;
- Hermes crons;
- learned decks;
- Lorehold best-of learned;
- migração de conhecimento Hermes para backend.

O deep dive descreve o estado atual. O plano de implementação define a ordem
segura para codar. O documento de decisões separa dúvidas de produto/logística
que precisam de validação antes de virarem comportamento de produção.
O handoff `BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md` lista as
perguntas que o owner deve responder quando uma fase sair dos defaults já
aprovados.

Decisão do owner em 2026-06-11: seguir com estabilidade de release primeiro,
sem ban global de Mox, learned decks apenas single-commander por enquanto,
duplicidade singleton Commander bloqueando save/import, metadados Hermes
ocultos para usuários normais, Hermes propondo e backend mandando,
`needs_review` fora de execução dura, `card_battle_rules` derivando tags só
quando confiável/rastreável, e primeiro slice limitado a agregação + snapshot
Hermes + testes.

Triagem Hermes 2026-06-12: a branch `codex/hermes-analysis-docs` apontou
incoerência real no funil de ativação: o app emitia `deck_rebuild_created` após
`/ai/rebuild`, mas `POST /users/me/activation-events` rejeitava o evento por
allowlist. A correção aceita esse evento no backend e adiciona teste de guarda.
Os achados antigos sobre owner-scope em `/ai/optimize`, jobs async de optimize e
jobs async de generate foram revalidados contra `master` e já estavam cobertos
por source guards (`ai_optimize_authorization_source_test.dart` e
`ai_generate_job_authorization_source_test.dart`).

Triagem 2026-06-16: battle/Hermes nao bloqueia o foco em geracao/optimize neste
ciclo. Os blockers recentes de decisao de recurso, tapped lands, ritual simples,
stax/value engine e combo pieces ja foram tratados em `master` com testes
focados. O primeiro slice seguro de geracao foi aplicado no pipeline interno de
candidate quality: `buildCandidateRoleScores` passa a aceitar sinal EDHREC
bounded e `candidate_quality_data_foundation.dart` le
`edhrec_card_snapshots` opcionalmente, agregando por nome antes do join com
`cards`. Dry-run real em 2026-06-16 escaneou `33839` cartas, encontrou `4183`
com sinal EDHREC e planejou `54417` role scores sem mutacao. Evidencia:
`DECK_GENERATION_FOCUS_READINESS_2026-06-16.md`.

### Gaps adicionais derivados do deep dive

| Prioridade | Gap | Evidência | Ação esperada |
|---|---|---|---|
| P1 | Identidade semântica de carta ainda em transição | Slice 2026-06-12 adicionou contrato/migration aditiva para `cards.oracle_id`, `cards.layout` e `cards.card_faces_json`; `scryfall_id` passa a ser tratado como printing id nas rotas/sync alterados; `DeckRulesService` agora usa `oracle_id` quando presente para bloquear singleton Commander e comandante duplicado no main deck em save/import/validate final, com fallback por nome físico normalizado; `/import/validate` chama a regra central em modo aviso; em 2026-06-12 a migração `021` foi aplicada no PostgreSQL real e o backfill preencheu `oracle_id` em `34325/34329` cartas; o auditor learned-opponent v4 adiciona candidato de printing canônica apenas em modo report-only e somente quando há vencedor único por evidência explícita; validação Hermes AWS em `babf800c` com 50 decks/5.000 instâncias manteve `semantic_identity_coverage=1.0`, `unresolved_instances=0`, `ambiguous_instances=0` e `canonical_printing_candidate_instances=0` | Manter fallback para as 4 cartas sem `oracle_id`; não persistir learned-opponent `card_id` ainda; como o scorecard v4 não encontrou candidato único na amostra ampliada, qualquer apply segue bloqueado até existir política backend-owned/allowlist com falso positivo zero |
| P1 | Learned deck ainda é single-commander | `validateCommanderLearnedDeckInput` exige `commanderQuantity == 1` e `mainQuantity == 99` | Evoluir contrato para pares oficiais somente quando houver corpus partner/background validado |
| P1 | Candidate quality agora usa EDHREC, mas apply ainda nao foi promovido | `buildCandidateRoleScores` aceita `edhrecInclusionRate`/`edhrecSampleDecks`; `candidate_quality_data_foundation.dart --dry-run` confirmou `4183` cartas com sinal EDHREC e `3263` stale `card_role_scores` heurísticos antes do apply; em 2026-06-16 o `--apply` passou a abortar stale prune grande por padrao e exigir `--allow-large-stale-prune` para janela controlada | Revisar preview/stale rows e executar `--apply` somente em janela controlada; depois rodar scorecard generate/optimize com Lorehold e comandantes de controle |
| P1 | Mecanismo de waiver manual deve continuar explícito e vazio por padrão | Em 2026-06-16 `battle_analyst_v9.py#get_card_effect` foi invertido para consultar waiver manual-first explicito, depois `battle_rule_registry.lookup_battle_card_rule(DB, name)`, e so entao cair em `HANDCRAFTED_KNOWN_CARDS`. Na quinta rodada do mesmo dia, o inventario manual ativo foi zerado: `HANDCRAFTED_KNOWN_CARDS=[]` no runtime normal, `sync_battle_card_rules.py --skip-generated` gera `0` linhas manuais e o auditor `audit_handcrafted_battle_rule_canonicalization.py` fechou `handcrafted_count=0`. Na limpeza seguinte do mesmo dia, o snapshot literal legado foi removido de `battle_analyst_v9.py`, os engines `battle_analyst.py`/v6/v7/v8 e patchers v8 foram apagados do tree operacional, e `test_known_cards_consumer_guardrail.py` passou a falhar se eles voltarem | Manter apenas waivers explícitos para incidentes/testes; a pendência real agora é higienizar a proveniência `source='manual'` já persistida em PG/SQLite quando houver janela controlada, não manter código manual morto |
| P1 | Derivação de regra executável para função de deck ainda não tem aprovação de dados para apply | `derive_functional_tags_from_battle_rules.py` agora propõe candidatos report-only; após correção de taxonomia e overrides card-specific são `89` novos candidatos: `27` low-risk review e `62` manual-review; `BATTLE_RULE_DERIVED_TAG_LOW_RISK_ALLOWLIST_2026-06-12.json` versiona os 27 low-risk para dry-run; validação Hermes AWS em `51328ea7` retornou `allowlisted_candidates_count=27`, `allowlist_blocked_manual_review_count=0`, `allowlist_unmatched_count=0`, `apply=false`; o dry-run transacional PostgreSQL posterior foi reexecutado localmente e no Hermes AWS, exercitando stale cleanup + upsert em rollback: `would_upsert_allowlisted_count=27`, `would_delete_stale_count=0`, `rolled_back=true`, `apply=false`; o caminho `--apply-reviewed-allowlist` existe, mas a allowlist atual bloqueia apply por `apply_approved=false` | O próximo passo seguro é revisão de falso positivo e criação de uma nova allowlist operator-controlled com `apply_approved=true`, se o produto aprovar. Os 62 candidatos seguem manual-only até existir taxonomia/faces suficiente |
| P1 | Consumidores Hermes históricos ainda podem assumir papel único | Consumidores ativos (`master_optimizer_common.py`, `slot_optimizer.py`, `_mana_validator.py`, `_run_validation.py`, `_update_cron_status.py`, `battle_analyst_v9.py`, `master_optimizer_apply.py`) já leem arrays; em 2026-06-12 `materialize_learned_deck_to_deck_cards.py`, `knowledge_db.py`, `import_lorehold_decks.py`, `scryfall_classifier.py`, `export_hermes_learned_deck.py`, `wincon_pipeline.py` e `reimport_lorehold_scryfall.py` passaram a preservar multi-tags mantendo campos legados (`functional_tag` ou `role_in_deck`) para compatibilidade; scripts históricos ainda consultam `functional_tag` direto | Classificação atualizada em `HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`; migrar só scripts que virarem ativos |
| P1 | Seed/classifier manual podia fixar identidade `RW` fora de Lorehold | `scryfall_classifier.py` usava `color_identity: "RW"` em `build_deck_json()`, o que contaminaria qualquer reuso manual para Kinnan/Atraxa/etc. | Em 2026-06-12, o classifier passou a carregar `color_identity` por carta e inferir a identidade do deck a partir do comandante; `RW` permanece apenas como fallback legado para Lorehold sem dados Scryfall |
| P1 | Simulação app-facing Dart e engine Hermes Python ainda divergem | `/decks/:id/simulate` / `server/lib/ai/battle_simulator.dart` continuam sendo simulação leve de abertura/curva; `battle_analyst_v9.py` é o laboratório Commander 4-player e recebeu ordem formal de dano/trample em 2026-06-12 | Não vender `/decks/:id/simulate` como battle engine; migrar para Python canonical engine ou recriar o Dart com contrato/testes equivalentes antes de usar resultados em produto/IA |
| P2 | Ownership de arquivos no container Hermes pode bloquear crons legítimas | Hermes report-only do commit `29916949` confirmou arquivos alterados como `root:root` dentro do container; em 2026-06-12 o repo remoto foi normalizado para `hermes:hermes`, a verificação retornou `NON_GIT_COUNT=0`, `ROOT_ANY_COUNT=0`, e `docker exec -u hermes` foi validado com `uid=10000(hermes)` | Manter como risco operacional recorrente: comandos `docker exec` sem `-u hermes` podem recriar arquivos root-owned; crons/manutenção devem escrever como `hermes` ou rodar checagem de ownership após manutenção |
| P2 | `ml_prompt_feedback` coleta, mas ainda não decide política | `/ai/optimize` registra feedback automático | Usar feedback em ranking/prompt policy somente após scorecard e teste de regressão |
| P2 | Replay sem snapshot semântico completo | Hermes replays e forensic ainda dependem de nomes/effects legados em partes do pipeline; Slice 5 adicionou `logical_rule_key`, `oracle_hash`, `card_id`, `semantic_hash` e contagem de cobertura no forensic quando esses campos já existem no snapshot, sem mudar execução; Slice 6 report-only atualizou `audit_learned_opponent_card_identity.py` para separar `card_id` resolvido de `oracle_id` resolvido por múltiplas printings do mesmo oracle, sem escolher printing arbitrária; após migração/backfill, Hermes AWS confirmou `oracle_id_column_present=true`, `semantic_identity_coverage=1.0`, `oracle_resolved_instances=50`, `ambiguous_instances=0` e `unresolved_instances=0` no corpus de `1200` instâncias; Slice 7/v4 adiciona `canonical_printing_candidate_*` report-only e foi ampliado para 50 decks/5.000 instâncias com `207` resoluções por `oracle_id`, `0` unresolved/ambiguous e `0` candidatos de printing | Próximo passo: manter replays learned-opponent em identidade semântica por `oracle_id`; só voltar a discutir persistência de `card_id` quando houver fonte de printing canônica explícita ou allowlist backend-owned revisada manualmente |
| P2 | Lorehold no-mox é política manual, não heurística universal | Learned deck 82 remove `Chrome Mox`, `Mox Diamond`, `Mox Opal` por decisão do produto | Não generalizar bloqueio de Mox para todos os comandantes/brackets sem regra explícita |
| P2 | Decisões de produto base aprovadas; exceções ainda precisam validação | `BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md` registra os defaults aprovados em 2026-06-11 | Seguir Slice 1; qualquer mudança fora dos defaults exige nova validação |

Atualização 2026-06-11: Slice 1 foi implementado localmente em
`sync_pg_target_deck_to_hermes.py`. O sync agora exige `card_id`, agrega
`functional_tags_json`, `semantic_tags_v2_json` e `battle_rules_json`, grava
`deck_hash`, `semantics_hash` e `sync_run_id`, rejeita duplicatas antes de
escrever SQLite e não usa mais `LEFT JOIN LATERAL (...) LIMIT 1` para
`card_battle_rules`. Evidência em
`BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`. Slice 2 foi implementado
em `76d828d2` e aplicado no Hermes AWS real: `ruleset_hash` agora é persistido
em `deck_cards`, baseline/quality/slot/apply carregam hashes separados e o
smoke remoto confirmou `100` rows, `100` quantity, `1` commander, um
`deck_hash`, um `semantics_hash`, um `ruleset_hash` e `7` benchmarks
`ruleset_hash_smoke` com ambos hashes. Pendente real: revisar candidatos
Lorehold, ampliar amostra e definir política de derivação de
`card_battle_rules`. Slice 3 adicionou `logical_rule_key` e dedupe lógico ao
sync, com smoke PG -> SQLite temporário e Hermes AWS real mantendo 100/1,
deduplicando 2 regras equivalentes e gravando 98 regras com chave lógica.
Slice 4 adicionou derivação report-only de `card_battle_rules_v1` para
`card_function_tags`, sem escrita em PG. A revisão
`BATTLE_RULE_DERIVED_TAG_REVIEW_2026-06-11.md` corrigiu o mapeamento de
efeitos concretos de recursão para `recursion` em vez de `engine`; o relatório
atual propõe `89` candidatos, sendo `27` low-risk review e `62` manual-review.
Slice 5 adicionou proveniência semântica de replay sem alterar comportamento:
`battle_rule_registry.py` agora calcula `logical_rule_key` e carrega
`oracle_hash`; `battle_analyst_v9.py` carrega `card_id`/`semantics_hash` do
SQLite Hermes quando existem e propaga `card_id`, `semantic_hash`,
`logical_rule_key` e `oracle_hash` para eventos via `replay_rule_fields`;
`battle_forensic_audit.py` mede cobertura desses campos. Evidência em
`BATTLE_REPLAY_SEMANTIC_PROVENANCE_SLICE_2026-06-12.md`. Validação no Hermes
AWS em `74850947` mostrou `45/45` eventos com `logical_rule_key` e `24/45` com
`card_id`/`semantic_hash`; inspeção posterior mostrou que os `21` ausentes
vieram de decks reais aprendidos de oponentes, não do deck Lorehold
sincronizado. Ainda pende resolver IDs estáveis para learned-opponent cardlists
via PG/resolver confiável e definir se o `semantic_hash` deck-level atual deve
virar hash semântico por carta.

### Ordem recomendada de implementação

1. Revisar manualmente os candidatos positivos do slot scan Lorehold antes de
   qualquer apply.
2. Rodar nova amostra maior report-only para confirmar que `ruleset_hash` não
   mascara alteração semântica/regra como alteração estrutural.
3. A allowlist dry-run dos 27 low-risk está versionada em
   `BATTLE_RULE_DERIVED_TAG_LOW_RISK_ALLOWLIST_2026-06-12.json` e validada no
   Hermes AWS; stale cleanup e transaction dry-run PostgreSQL já foram
   exercitados com rollback. Ainda não é autorização de apply.
4. Adicionar IDs estáveis a learned-opponent cardlists via PG-backed resolver
   ou sync dedicado; não sintetizar IDs dentro do replay. O primeiro passo
   report-only é `audit_learned_opponent_card_identity.py`. Validação Hermes
   AWS em `191ead51`: `12` decks, `1200` instâncias, `1149` resolvidas,
   `1` não resolvida, `50` ambíguas, cobertura `0.9575`; antes de apply,
   resolver as ambiguidades explicitamente. Slice 6 atualiza o auditor para
   separar resolução concreta por `card_id` de resolução semântica por
   `oracle_id`; múltiplas printings do mesmo oracle passam a contar como
   cobertura semântica quando a coluna existe, mas continuam não persistindo
   `card_id` até existir política de printing canônica. Validação Hermes AWS
   em `9c6f44c9`: `oracle_id_column_present=false`, `1200` instâncias, `1150`
   resolvidas por `card_id`, `50` ambíguas, `0` não resolvidas e cobertura
   `0.958333`; portanto o bloqueio real era migration/backfill do banco, não o
   parser do auditor. Em 2026-06-12, a migração `021` foi aplicada e o
   backfill controlado preencheu `cards.oracle_id` em `34325/34329` cartas; nova
   validação Hermes AWS retornou `oracle_id_column_present=true`,
   `semantic_identity_coverage=1.0`, `oracle_resolved_instances=50`,
   `ambiguous_instances=0` e `unresolved_instances=0` para `1200` instâncias.
   Amostra `dbbf4ab1`: ambiguidades principais eram
   múltiplas printings (`Sol Ring`, `Ancient Tomb`, `Command Tower`,
   `Birds of Paradise`, `Phyrexian Metamorph`, `Cyclonic Rift`), então a
   próximo passo deve definir política de oracle/canonical-printing identity;
   não usar `LIMIT 1`. `unaccent` continua indisponível no PostgreSQL, então o
   auditor deve separar `card_id` exato, match diagnóstico por acento e
   resolução semântica por `oracle_id`. Persistência de `card_id` continua
   bloqueada até existir política de printing canônica. Slice 7 adiciona essa
   política apenas como diagnóstico report-only: um `card_id` candidato só é
   emitido se uma printing tiver pontuação de evidência estritamente maior que
   todas as demais (`scryfall_id` de printing, imagem direta Scryfall, layout,
   collector number, set code, rarity). Empates seguem semantic-only.
5. Decidir se o `semantic_hash` deck-level atual é suficiente para auditoria de
   replay ou se o produto precisa de hash semântico por carta.
6. Criar helper/query de agregação por `card_id` em PG/backend se o contrato
   precisar ser consumido fora do sync Hermes.
7. Completar a formalização de identidade semântica de carta e faces antes de
   expandir regras DFC/MDFC: colunas `oracle_id`, `layout` e
   `card_faces_json` já foram introduzidas no backend/sync e a migração/backfill
   real preencheu `oracle_id` em `34325/34329` cartas. Ainda falta resolver ou
   classificar as 4 cartas remanescentes e definir política de printing
   canônica para consumidores que precisam persistir `card_id`. A primeira
   versão dessa política existe no auditor v4, mas sem apply e sem alteração de
   contrato runtime.
8. Só depois evoluir learned decks para dois comandantes.
9. Só depois usar feedback ML como input de política.

### Atualizacao 2026-06-16 - estudo profundo battle + generator + Lorehold

Estudo canônico novo:

- `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md`

Conclusao operacional consolidada:

- battle nao e mais o blocker principal para focar em geracao/optimize;
- o battle atual serve como laboratorio auditavel e gate de regressao para as
  decisoes ja modeladas, mas ainda nao como verdade final de qualidade de
  jogada;
- o generator ja e hibrido e usa PG/reference/corpus/usage/validation, mas
  ainda depende de fallback curado literal, especialmente no caso Lorehold;
- Lorehold ja e caso de controle valido para medir criacao, optimize e replay,
  mas ainda nao pode ser tratado como prova universal de qualidade por causa de
  utility lands parciais, cobertura incompleta de cartas de oponentes e
  ausencia de metricas fortes de decisao.
- revalidacao source-backed desta continuidade:
  - regra oficial de mulligan continua sendo London Mulligan, sem "free
    mulligan" embutido no formato;
  - Commander oficial continua exigindo 99+1, singleton, identidade de cor,
    commander tax, commander damage e combate multiplayer com ataques
    distribuidos;
  - a calibracao estrategica minima de mulligan segue `curve + color + plan +
    sequencing + interaction`, nao apenas numero de lands;
  - `Mox Amber` so pode contar como aceleração inicial quando a mana condicional
    estiver realmente "live" com lendaria/planeswalker relevante.
- correcao local validada nesta continuidade:
  - o seed problematico de Lorehold que antes mantinha `4 lands + Mox Amber +
    Mizzix's Mastery + Rise of the Eldrazi` agora mulliga com
    `reason=no_early_game_plan`;
  - o quality gate de optimize deixou de tratar `combo` como fallback generico
    de `removal/ramp/wipe/wincon`; agora `combo` protege explicitamente
    `tutor`, `engine`, `wincon`, `protection` e `combo_piece`, e o filtro
    off-theme aceita apenas trocas dentro da banda real de suporte de combo;
  - os falsos criticos do auditor forense para `copy_creature_token`
    (`Electroduplicate`) e `hand_filter`
    (`Valakut Awakening // Valakut Stoneforge`) foram removidos ao alinhar a
    lista de `SUPPORTED_EFFECTS` com o engine real;
  - o runtime local de `known_cards` continua `PASS` com
    `known_cards_count=3159`, `canonical_fallback_count=3159` e sem waiver
    manual ativo depois de promover a regra canônica local de `Mox Amber` para
    SQLite + snapshot com
    `requires_legendary_creature_or_planeswalker_for_mana=true`.
  - em 2026-06-16 o slice seguinte promoveu tambem `Natural Order` para a
    camada `reviewed_battle_card_rules`, com snapshot canonico exportado e
    runtime local corrigido para pagar `requires_sacrifice_green_creature` no
    cast e bloquear o spell quando nao existir criatura verde sacrificavel.

Triagem da branch `codex/hermes-analysis-docs` revalidada em 2026-06-17:

- `origin/codex/hermes-analysis-docs` foi lida antes de fechar este slice.
- Achados Hermes que ja estavam cobertos no `master` atual e nao exigiram novo
  codigo:
  - `Underworld Breach` ja esta em `_knownInfiniteComboPieces` e tem teste em
    `server/test/edh_bracket_policy_test.dart`;
  - `Narset, Parter of Veils` e `Grand Arbiter Augustin IV` ja entram como
    stax/gamechanger por nome e por texto;
  - `Consecrated Sphinx`, `Field of the Dead`, `Smothering Tithe` e
    `The One Ring` ja entram como value engines;
  - `GoldfishSimulator` ja nao conta land tapped como mana no mesmo turno;
  - `classifyOptimizationFunctionalRole` e wrappers correlatos ja priorizam
    `functional_tags` persistidos, depois `semantic_tags_v2`, depois heuristica.
- Achado Hermes ainda valido, mas fora deste slice para evitar mistura de
  escopos: limpar consumidores secundarios que ainda aceitam
  `known_cards_generated.json` como input de auditoria/sync. A parte operacional
  ja foi reduzida neste ciclo: `slot_optimizer.py`, `universal_optimizer.py`,
  `battle_effect_coverage_audit.py` e `sync_pg_card_metadata_to_hermes.py`
  consomem o loader canonico sem `include_generated=True`. O JSON gerado fica
  restrito a geradores, validadores e auditorias de drift.

Tasks priorizadas derivadas do estudo:

| Prioridade | Task | Motivo real | Resultado esperado |
|---|---|---|---|
| P1 | Refinar `Urza's Saga` depois do slice minimo ja implementado | Em 2026-06-16 o battle passou a inicializar capitulo/lore, avancar no upkeep, criar Construct no capitulo II e tutorar artefato cmc<=1 seguro no capitulo III antes do SBA. O gap remanescente e de refinamento: sizing dinamico do Construct e generalizacao prudente do fluxo de Saga | Menos ambiguidade medium-risk no Lorehold sem abrir uma engine de Saga agressiva demais |
| P1 | Fechar cartas recorrentes de oponentes que ainda aparecem como `review_rule_used` | O ruido residual do audit ainda passa por regras parciais de oponentes, nao por quebradeira do Lorehold | Cobertura mais limpa para usar scorecards sem inflar `unknown`/`needs_review` |
| P1 | Evoluir `decision_trace_v1` para decisao comparativa | O replay atual ja mostra o que foi feito, mas ainda nao explica sempre por que A venceu B | Base auditavel para julgar qualidade de decisao, nao so legalidade |
| P1 | Criar scorecard Commander-safe de decisao/impacto (com/sem carta vista, com/sem carta castada, delta vs baseline, amostra minima) | WR bruto continua fraco como sinal de verdade | Aprendizado menos enganado por variance e jogos longos |
| P1 | Promover a mesma semântica canônica de `Mox Amber` também no rollout PG/Hermes remoto | O cache local ja foi corrigido para incluir `requires_legendary_creature_or_planeswalker_for_mana=true` e o waiver runtime foi removido; o risco restante e divergencia entre ambiente local e rollout remoto | Mulligan, mana refresh e fast-mana scoring coerentes em todos os ambientes, sem depender de hotfix local |
| P1 | Formalizar a politica de mulligan Commander no auditor/trace como `curve + color + plan + sequencing + interaction` | A parte legal ja esta fechada; em 2026-06-17 o London Mulligan passou a escolher bottom por politica auditavel, preservando lands necessarias/early plays e priorizando bombas mortas. O gap restante e enriquecer o trace comparativo com alternativas rejeitadas e calibrar em corpus maior | Abertura de maos mais reproduzivel e melhor rastreabilidade do porquê keep/mull/bottom |
| P1 | Sair do bucket hardcoded de arquétipo no quality gate e passar a usar `role_targets`/assinatura do profile | O erro mais gritante de `combo` ja foi corrigido, mas o gate ainda usa buckets grossos e land counts genericos por arquétipo | Optimize mais aderente ao profile real do comandante, inclusive Lorehold |
| P1 | Promover `card_role_scores` em janela controlada com stale prune revisado | O slice EDHREC bounded ja existe, mas ainda nao foi aplicado como base mais forte do pipeline | Candidate pool mais data-backed para generate/optimize |
| P1 | Provar consumo live do profile persistido do Lorehold e reduzir fallback literal | Em 2026-06-16 o recheck read-only de `commander_reference_profile_lorehold.dart --dry-run` fechou com `usable_after_run=true`, `confidence=high`, `source_count=4` e `34/34` reference stats resolvidos; em 2026-06-17 o auditor local com `usage_hot_cards` ampliado para 50 manteve `profile_usable=true`, `stats_count=34`, `corpus_accepted_deck_count=3` e reduziu `built_in_fallback_only_count` para `2` cartas (`Mind Stone`, `Fellwar Stone`) | O consumo ainda materializa `usable_runtime_origin=built_in_fallback` quando a row persistida não é considerada usável pelo loader; o próximo passo não é remover fallback, e sim tornar o profile persistido canônico/usável e curar o residual de 2 cartas por evidência de uso/corpus |
| P1 | Fechar paridade entre banco auditado localmente e backend publico no generator Lorehold | A prova publica antiga no SHA `9c1ca349` mostrava `reference_profile_used=false`; em 2026-06-17, depois do rollout `f53e3286`, o auditor publico passou para `reference_profile_used=true`, `reference_card_stats_used=true`, `learning_profile_present=false`, `recommended_deck_source=promoted_learned_deck_pg` e health publico alinhado ao SHA esperado | Paridade principal fechada; risco residual: `/ai/generate` ainda pode retornar `is_mock=true` quando usa caminho determinístico/fallback, e `/ai/commander-learning` segue expondo learned deck como canal paralelo sem `profile/card_stats/deck_corpus` completos nesse endpoint |
| P1 | Reduzir dependencia do fallback literal Lorehold no builder deterministico | Em 2026-06-16 o builder passou a consumir `usage_hot_cards` antes do fallback literal, reduzindo `fallback_only` de `25` para `16`; em 2026-06-17 o limite de candidatos aprendidos do generator subiu para `50`, e o auditor real reduziu `source_usage_counts.deterministic_fallback` de `59` para `45` e `built_in_fallback_only_count` de `16` para `2` | Ação correta agora: atacar apenas o residual `Mind Stone`/`Fellwar Stone` e decidir a fronteira entre `/ai/generate` e deck aprendido promovido; não remover o fallback inteiro enquanto o profile persistido ainda cair em `built_in_fallback` |
| P1 | Manter explainability backend-owned do deck determinístico | Em 2026-06-16 o builder passou a emitir `reference_deterministic_deck` com `source_mix_counts`, `source_usage_counts`, `built_in_fallback_used_count` e `built_in_fallback_only_count`; se isso regredir, voltamos a perder a distinção entre profile/stats/corpus e preset | Preserva QA real do generator e impede que Lorehold pareça “aprendido” quando ainda estiver fortemente ancorado em fallback |
| P1 | Curar o bucket residual `fallback_only` do Lorehold por papel, não por nome solto | Depois da ampliação para 50 hot cards, o residual medido ficou restrito a `Mind Stone` e `Fellwar Stone`, ambos ramp/fixing genéricos que ainda só aparecem via fallback literal no deck determinístico local | Próximo slice seguro: promover esses slots para `usage_hot_cards`, `reference_corpus_packages` ou `reference_card_stats` somente se houver cobertura real; se não houver, manter como fallback explícito e documentado |
| P1 | Fechar rollout/versionamento do snapshot canonico de `known_cards` | O suporte local ja foi implementado: `battle_analyst_v9.py` consulta `known_cards_canonical_snapshot.json` como unico fallback JSON executavel, `sync_battle_card_rules_pg.py --apply-sqlite-from-pg` exporta o snapshot e a auditoria local fechou em `PASS` com `canonical_fallback_count=3159`. Em 2026-06-17, como `known_cards_generated.json` nao tinha nomes exclusivos e ainda tinha `219` efeitos divergentes, ele foi removido do runtime da batalha e dos consumidores operacionais do optimizer/sync | Menor degradacao semantica quando SQLite/PG nao estiverem disponiveis; replay local/remoto cai para snapshot canonico ou `unknown` auditavel, nao para regra gerada antiga |
| P1 | Formalizar por commit/deploy o rollout do snapshot canonico de `known_cards` no Hermes AWS | Em 2026-06-16 o `master` local validou `HANDCRAFTED_KNOWN_CARDS=[]`, `MANUAL_RULE_RUNTIME_WAIVERS=[]`, precedencia `battle_card_rules -> known_cards_canonical_snapshot -> known_cards_generated`, snapshot materializado localmente e auditoria `PASS` com `known_cards_count=3159`. Em 2026-06-17 a precedencia versionada mudou para `battle_card_rules -> known_cards_canonical_snapshot -> heuristicas/unknown`, sem fallback gerado executavel. A rodada operacional no Hermes AWS anterior ja comprovou materializacao do snapshot, mas precisa absorver essa nova remocao do fallback gerado no proximo deploy/cron | O risco de logica/runtime foi reduzido; o risco restante agora e operacional: garantir que rebuild/container Hermes rode o SHA com fallback gerado removido e mantenha snapshot canonico materializado |
| P1 | Promover reviewed rules de cartas recorrentes que ainda caiam em `unknown`/heuristica apesar de terem semantica oficial clara | O conflito estrutural de fontes foi fechado, e o runtime da batalha nao usa mais `known_cards_generated.json`. `Natural Order` ja foi promovido para `curated/verified` com custo verde sacrificavel e tutor verde ao campo. Em 2026-06-17, `Dismember` tambem foi promovido para `curated/verified` como modificador `-5/-5` ate EOT, e o SBA foi corrigido para matar criatura com resistencia `<= 0` mesmo se for indestrutivel; a rodada `20260617_005901` ficou com `action_findings=0` e `strategy_findings=0`. O mesmo criterio deve ser aplicado aos proximos outliers recorrentes dos replays/auditorias | Menos distorcoes de battle e de scorecard causadas por cartas reais que ainda nao possuem regra revisada; ausencia agora vira `unknown` auditavel em vez de efeito gerado incorreto |
| P1 | Adicionar explainability backend-owned por carta gerada | O produto ainda nao responde bem "por que essa carta entrou?" | Transparencia de criacao, QA melhor e comparacao de fontes por carta |
| P1 | Higienizar proveniencia das regras promovidas hoje marcadas como `source='manual'` em PG/SQLite | Runtime manual ativo ja esta zerado, mas a proveniencia historica ainda confunde auditoria | Menos ruido conceitual sem mudar comportamento de runtime |

Regras mantidas por este estudo:

- nao fazer ban global de Mox;
- nao promover SQLite Hermes a fonte final;
- nao usar WR bruto como verdade;
- nao usar join cru `deck_cards -> card_battle_rules`;
- nao reescrever o battle do zero neste ciclo.

### Critério de bloqueio

Qualquer plano futuro deve ser rejeitado ou reescrito se:

- tratar `card_battle_rules` como fonte principal de papel de deckbuilding;
- achatar toda carta para uma única função definitiva;
- usar `LIMIT 1` como solução final;
- alterar total de cartas por enriquecimento semântico;
- confundir `source='curated'` com `review_status`;
- tratar `rule_version` como string;
- transformar Hermes SQLite em fonte final do produto;
- aplicar swap Lorehold direto no produto sem handoff.

### Proximo handoff para validacao do owner

Quando uma decisão sair dos defaults aprovados, usar:

- `docs/hermes-analysis/BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`

Esse documento pergunta explicitamente sobre apply no Hermes real, migracao de
identidade semantica, singleton por identidade, visibilidade de metadados Hermes
no app, excecao no-mox, explicacao "por que esta carta", execucao de
`needs_review`, automacao futura de crons e prioridade do contrato
`deck_card_semantics_v1`.
