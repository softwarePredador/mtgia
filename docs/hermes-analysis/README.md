# Hermes Analysis Docs — leitura canonica

> Status atual: canonico.
> Esta e a porta de entrada para decidir quais docs ler e quais ignorar em
> tarefas Hermes.

Updated: 2026-07-05

Esta pasta mistura contrato operacional, historico de auditoria, relatorios de
rodadas e memorias antigas. Para evitar confusao, use esta ordem de leitura.

## Indice operacional rapido

- `MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md`
  - Status: `current_lookup_index`.
  - Primeira consulta pratica antes de executar ManaLoom/Hermes/XMage/Lorehold:
    onde consultar, como consultar, quais parametros usar, quais scripts sao
    legados/bloqueados e quais auditorias provaram alinhamento.
  - Use para evitar criar runner, tabela, campo, artefato ou fluxo redundante
    antes de verificar a superficie existente.

- `MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md`
  - Status: `current_failure_mode_gate`.
  - Checklist transversal antes de declarar alinhamento entre battle, regras de
    carta, deckbuilding, Hermes/SQLite e PostgreSQL.
  - Cobre os bugs antigos que nao podem voltar: fanout por join cru, baseline
    `deck_6` como shell atual, artefato legado sem normalizador, EDHREC por
    `inclusion` absoluto, PostgreSQL/Hermes fora de ordem e conclusao por
    batalha sem carta comprada/usada.
  - O baseline `LEGACY_CONTAMINATION_BASELINE_2026-06-30.json` e a auditoria
    `manaloom-knowledge/scripts/legacy_contamination_audit.py` registram o
    historico tolerado e falham se essas classes antigas crescerem de novo.

## Contrato de dados / aliases

- `DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md`
  - Status: `current_guardrail`.
  - Define os campos canonicos para evitar trabalho duplicado entre
    `oracle*`, `card_id`, nomes normalizados, `logical_rule_key`,
    `oracle_hash` e referencias.
  - Regra principal: `card_id` vence alias de nome; `oracle_id` vence
    `scryfall_id` para identidade jogavel; `logical_rule_key` vence labels de
    efeito; `oracle_hash` e o campo de drift para regra de battle.
  - Auditoria ativa:
    `manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py`.
    Evidencia atual:
    `master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260630_alias_guardrail_final.md`.

## Decisoes atuais XMage -> ManaLoom

- `BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md`
  - Status: `frozen_operating_contract`.
  - Contrato congelado de seguimento: rode um checkpoint curto de invariantes e
    siga para family mapping/subpadroes; nao reabra a estrategia inteira quando
    o checkpoint passar.
  - Define a ordem padrao: pacote exato nao-generico pronto, `ramp_permanent`,
    `targeted_interaction`, `tutor`, `free_cast`, depois familias residuais por
    evidencia de replay/deck.
  - Bloqueia promocao de `xmage_*_review_v1`, execucao de pattern registry,
    Hermes como verdade acima do PostgreSQL e battle agregado sem carta
    comprada/usada ou focused test.

- `XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
  - Status: `current_operating_standard`.
  - Fluxo operacional atual para absorver XMage/Oracle/Fonte externa em
    ManaLoom por familias e subpadroes, tratando XMage local resolvido como
    fonte autoritativa de comportamento e bloqueando apenas a promocao
    executavel sem adaptador runtime.
  - Define a hierarquia de fontes: regras oficiais + Scryfall/MTGJSON para
    identidade/oracle/rulings, XMage local como verdade de engine para cartas
    com classe resolvida,
    Forge/Magarena/Cockatrice apenas como comparacao quando necessario,
    PostgreSQL como fonte duravel e Hermes/SQLite como cache/lab.
  - Evidencia atual:
    `master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg323_creature_etb_add_counters_wave_commander_legal.md`.
  - Manifesto de replay corrente para o checkpoint operacional:
    `master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg276_assemble_the_players_manifest.md`.
  - Auditoria de alinhamento:
    `manaloom-knowledge/scripts/xmage_strategy_consistency_audit.py`.
  - Auditoria geral de superficie operacional:
    `manaloom-knowledge/scripts/operational_surface_alignment_audit.py`.
  - A partir de 2026-07-01, a fila de cartas e global sobre `cards`, nao
    limitada a Lorehold/decks cadastrados. Rode
    `manaloom-knowledge/scripts/global_card_oracle_battle_readiness.py` para
    separar sync Oracle/legalities, blank Oracle text esperado, cobertura por
    `card_id`/`normalized_name`, propagacao real por `oracle_id` e familias
    XMage. Evidencia corrente:
    `master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg323_creature_etb_add_counters_wave_recheck.md`.
  - Para acelerar a adaptacao de todas as cartas, rode tambem
    `manaloom-knowledge/scripts/global_card_adaptation_acceleration_model.py`.
    Ele prova a fila no grao correto sem usar decks cadastrados como demanda:
    `31772` rows com gap viram `28835` identidades Commander-legais,
    `345` identidades com sinal externo de popularidade, e `28` unidades de
    planejamento por template/familia. As `1511` identidades em decks
    cadastrados e `232` em ready-product sao QA seeds apenas. Evidencia
    corrente:
    `master_optimizer_reports/global_card_adaptation_acceleration_model_20260701_demand_corrected.md`.
  - Para aplicar a decisao "XMage como verdade final" em massa, rode
    `manaloom-knowledge/scripts/xmage_authoritative_adaptation_queue.py`.
    Depois rode
    `manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py` para
    transformar apenas assinaturas exatas/runtime-backed em candidato PG.
    Evidencia corrente pos-PG323:
    `master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg323_creature_etb_add_counters_wave_commander_legal.md`.
    Resultado all-card: `27312` identidades ainda com gap, `26998` com fonte
    XMage autoritativa resolvida, `314` excecoes sem fonte local, `0` parser
    gaps e `11429` work units de adaptador ManaLoom por assinatura/effect
    XMage. O PG283 promoveu/sincronizou `312` regras exatas de instant/sorcery
    simples (`draw`, `direct_damage`, `destroy target`). O PG284 adicionou
    `53` regras exatas utilitarias (`29` mana sources simples, `18` exile
    target, `6` life gain). O PG285 fechou `8` residuos all-card ja suportados,
    o PG286 adicionou `12` counters puros com restricao real de alvo na stack,
    o PG287 adicionou `7` bounce spells com `destination=hand`, o PG288
    adicionou `22` recursion spells graveyard-to-hand, e o PG289 adicionou
    `13` mass-removal spells por destroy-all/fixed damage-all. O PG290
    adicionou `3` add-counters spells de alvo criatura (`Battlegrowth`,
    `Blight Rot`, `Scar`). O PG291 adicionou `42` boost/debuff spells de alvo
    criatura com modificador de poder/resistencia ate o fim do turno. O PG292
    adicionou `409` criaturas com keyword estatica de combate propria. O PG293
    adicionou `85` criaturas com keyword estatica propria, incluindo multiline
    Oracle e `hexproof`/`shroud`/`indestructible` seguros. O PG294 adicionou
    `37` criaturas com ganho de vida fixo ao entrar no campo de batalha,
    bloqueando casos proporcionais como "for each". O PG295 adicionou `28`
    criaturas com draw fixo ao entrar no campo de batalha, bloqueando draw
    proporcional/dinamico. O PG296 adicionou `6` criaturas com habilidade
    ativada `{T}` de dano fixo a alvo, criando a base runtime para
    `SimpleActivatedAbility` sem custo de mana/sacrificio. O PG297 adicionou
    `19` criaturas com destroy de alvo ao entrar no campo de batalha, bloqueando
    textos restritos como power/toughness, subtipo e condicoes. Do PG298 ao
    PG317 foram adicionados ETB recursion, graveyard-to-battlefield recursion,
    dies-draw, ETB damage, token spells/ETB tokens, boost+keyword, damage/destroy
    com life gain, alvo restrito, permanentes ativados de draw/damage/recursion/
    destroy/self-boost/target-keyword/target-boost e target-boost com sacrificio
    da propria fonte, alem de target-keyword com keyword estatica propria. O
    PG318 adicionou `13` tutors de biblioteca exatos para campo de batalha/topo
    do grimorio, incluindo land tutors como `Farseek`/`Nature's Lore` e
    `Personal Tutor`. O PG319 adicionou `6` permanentes com habilidade simples
    de retorno da propria carta do cemiterio para a mao, incluindo
    `Sanitarium Skeleton` e `Firewing Phoenix`. O PG320 adicionou `14`
    permanentes com habilidade ativada simples de ganho de vida fixo, incluindo
    `Bottle Gnomes`, `Fountain of Youth`, `Tower of Eons` e `Zarichi Tiger`.
    O PG321 adicionou `32` estaticas exatas de poder/resistencia para criaturas
    controladas via `BoostControlledEffect + SimpleStaticAbility`, incluindo
    anthem/lord, subtipo, artefato criatura e criatura lendaria. O PG322
    adicionou `19` spells one-shot de boost para criaturas controladas ate o
    fim do turno via `BoostControlledEffect` fixo, com runtime
    `controlled_stat_modifier_until_eot`. O PG323 adicionou `11` criaturas com
    ETB que coloca counter fixo em uma criatura alvo via
    `AddCountersTargetEffect + EntersBattlefieldTriggeredAbility`, mantendo a
    fonte no campo e bloqueando multi-target/filtros. Todos os pacotes
    PG285-PG323
    passaram postcheck PostgreSQL e E2E em PG/SQLite/snapshot/runtime. O
    splitter PG323 selecionou `11` propostas, o recheck pos-PG323 voltou
    `proposal_count=0`, e a fila pos-PG323 caiu para `26998` adapters XMage
    pendentes; a
    proxima etapa deve continuar em novos subpadroes runtime-backed de maior
    reducao reutilizavel, partindo da fila global e nao de decks cadastrados.

- `XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md` e
  `XMAGE_ABSORPTION_WORKFLOW_V2_2026-06-24.md`
  - Historico ainda util para entender por que rejeitamos full-XMage-first e
    card-by-card como metodo primario.
  - Nao devem ser usados como contrato operacional quando divergirem do fluxo
    definitivo de 2026-06-29.

## Decisao atual Commander deckbuilding global

- `COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`
  - Status: `frozen_operating_contract`.
  - Contrato atual para montar decks Commander: legalidade/identidade,
    commander intent profile, corpus externo/referencia, learned deck/uso
    local, fallback deterministico, validacao, matriz de estrategia e battle
    gate.
  - Para Lorehold, `607` e baseline estrutural protegido; `615` e `614`
    seguem como challengers. Nenhum candidato substitui `607` sem equal battle
    gate e trace de cartas compradas/usadas.
  - A rota `/ai/generate` agora expõe `deckbuilding_contract`, montado por
    `server/lib/ai/commander_deckbuilding_contract_support.dart`, para ligar
    profile, stats, corpus, learned deck, usage hot cards, validacao e proximo
    gate em um unico diagnostico.
  - A partir de 2026-07-01, o tratamento de decks deve ser globalizado pelo
    metodo, nao pelo conteudo do Lorehold: rode
    `manaloom-knowledge/scripts/global_commander_deck_contract_audit.py` para
    separar `user_product`, `registered_pg_variant`, Hermes/lab e fixtures
    antes de qualquer promocao, e depois rode
    `manaloom-knowledge/scripts/global_commander_strategy_matrix.py` para
    decidir quais comandantes entram em matriz estrategica especifica.
  - Evidencia global atual:
    `master_optimizer_reports/global_commander_deck_contract_audit_20260701_post_scope_legalities.md`
    e
    `master_optimizer_reports/global_commander_strategy_matrix_20260701_current.md`.
    Resultado: 13 variantes PostgreSQL registradas `structure_ready`; Hermes
    local 6/606-621 estruturalmente pronto; deck 607 do usuario
    `rafaelhalder@gmail.com` com 100 cartas, 1 comandante e legalidades
    Commander completas. A matriz global considera 10 comandantes, 36 decks
    prontos, 19 decks de produto prontos e 8 decks de produto bloqueados;
    `Lorehold`, `Kaalia`, `Kefka` e `Y'shtola` ja podem seguir para matriz
    estrategica especifica, enquanto comandantes sem fonte/perfil ficam
    bloqueados antes de battle/otimizacao.
  - Pivot operacional de 2026-07-05: o foco do aprendizado passa a ser o core
    global de montagem Commander; `607` fica como benchmark/regressao, nao como
    objetivo principal nem template universal. Evidencia local degradada sem
    PostgreSQL: `master_optimizer_reports/global_commander_deck_contract_audit_20260705_global_core_pivot_hermes_only.md`
    e `master_optimizer_reports/global_commander_strategy_matrix_20260705_global_core_pivot_hermes_only.md`.
    Esses relatorios validam Hermes/lab, mas source lanes ficam indisponiveis;
    portanto nao substituem a matriz com PostgreSQL para readiness de produto.
    Para diagnostico global de papeis/core antes da matriz estrategica, rode
    `manaloom-knowledge/scripts/global_commander_core_role_audit.py`; evidencia
    local atual:
    `master_optimizer_reports/global_commander_core_role_audit_20260705_global_goal_hermes_only.md`.
    Para transformar gaps criticos em hipoteses seguras antes de qualquer
    materializacao, rode
    `manaloom-knowledge/scripts/global_commander_core_repair_hypothesis.py`;
    evidencia local atual:
    `master_optimizer_reports/global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.md`.
    Para gaps de land, rode
    `manaloom-knowledge/scripts/global_commander_mana_base_profile.py` antes de
    nomear cartas: ele mede identidade de cor, fontes diretas/fetchaveis, lands
    viradas, colorless-only e risco de utility lands. Evidencia local atual:
    `master_optimizer_reports/global_commander_mana_base_profile_20260705_global_goal_hermes_only.md`.
    Quando o perfil estiver pronto, rode
    `manaloom-knowledge/scripts/global_commander_named_land_candidate_pool.py`
    para gerar um pool nomeado review-only por identidade de cor e legalidade
    Commander, ainda sem materializar decks. Evidencia local atual:
    `master_optimizer_reports/global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.md`.
    Em seguida, rode
    `manaloom-knowledge/scripts/global_commander_land_cut_candidate_model.py`
    para transformar candidatos de land e excesso de papeis em hipoteses
    add/cut review-only, bloqueando cartas que carregam roles ainda faltantes.
    Evidencia local atual:
    `master_optimizer_reports/global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.md`.
    Para gaps nonland, rode
    `manaloom-knowledge/scripts/global_commander_nonland_core_candidate_model.py`
    depois das hipoteses de reparo: ele expande pools locais de `format_staples`
    para roles suportados, filtra por identidade de cor, legalidade Commander,
    cartas ja no deck, tipo nonland e texto Oracle que confirme a funcao. Gaps
    de wincon continuam bloqueados ate existir source-lane/plano de vitoria do
    comandante, e cortes por excesso generico precisam respeitar payoffs do
    comandante; em Kaalia, criaturas Angel/Demon/Dragon ficam bloqueadas ate
    source-lane provar que sao cortaveis. Evidencia local atual:
    `master_optimizer_reports/global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.md`.
    O suporte runtime de profiles agora tambem tem fallback agregado para
    `Kaalia of the Vast` em
    `server/lib/ai/commander_reference_profile_support.dart`: esse fallback
    desbloqueia prompts com identidade `B/R/W`, protecao/haste, interacao real,
    payoffs Angel/Demon/Dragon e plano B, mas nao substitui matriz estrategica,
    battle gate nem replay trace.
    Para ordenar o proximo aprendizado global sem voltar a focar no `607`,
    rode `manaloom-knowledge/scripts/global_commander_learning_priority_audit.py`;
    evidencia local atual:
    `master_optimizer_reports/global_commander_learning_priority_audit_20260706_source_exhaustion_current.md`.
    Essa fila agora consome o router de exaustao de fontes externas/nonpayoff:
    quando o minerador revisado encontra `fresh_seeded_same_lane_cut_source_count=0`
    e o router volta para `expand_external_nonpayoff_source_candidate_pool`,
    o proximo passo global passa a ser expansao de fonte antes de qualquer
    candidate-copy.
    Essa auditoria tambem registra que a fonte oficial atual usa 5 Commander
    Brackets + Game Changers; o backend agora aceita `1..5` em
    `server/lib/edh_bracket_policy.dart`, mas bracket continua sendo sinal de
    pregame/power e nao prova final de qualidade estrategica.
    Quando uma hipotese add/cut estiver pronta, rode
    `manaloom-knowledge/scripts/global_commander_candidate_copy_materializer.py`
    para materializar uma unica troca em copia isolada do Hermes SQLite. A
    primeira evidencia global materializou `+Feed the Swarm / -Birgi, God of
    Storytelling // Harnfel, Horn of Bounty` no deck `619`, com source DB
    intacto e gate de batalha/promocao ainda fechado:
    `master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair.md`.
    O materializer agora tambem bloqueia fonte encadeada/stale: o source DB
    precisa bater com o `source_db` do relatorio de pares, salvo override
    explicito, e payoffs protegidos em `blocked_cut_candidates` precisam
    continuar presentes. Isso invalida a cadeia antiga de cinco swaps de Kaalia,
    onde `Bloodthirster` ja havia sido removido antes do probe.
    Depois da copia candidata, rode
    `manaloom-knowledge/scripts/global_commander_candidate_battle_probe_audit.py`
    sobre um probe pequeno base-vs-candidato com replay estruturado. A primeira
    evidencia Kaalia mostrou o alvo correto (`Kaalia of the Vast`) e zero
    contaminacao de `Lorehold`, mas bloqueou promocao: candidato `33.3%` vs
    base `66.7%`, e nenhuma das cinco remocoes adicionadas foi exercida nos
    eventos do replay:
    `master_optimizer_reports/global_commander_candidate_battle_probe_audit_20260705_kaalia_nonland_floor_dynamic_target.md`.
    A candidata limpa de uma troca (`+Feed the Swarm / -Birgi, God of
    Storytelling // Harnfel, Horn of Bounty`) reabriu o proximo gate no probe
    pequeno: base `33.3%`, candidata `66.7%`, `battle_probe_ready_for_larger_gate`,
    sem contaminacao `Lorehold`, e replay com `Demonic Tutor` buscando `Feed the
    Swarm`; a carta foi conjurada/resolvida e removeu `Kinnan, Bonder Prodigy`.
    O gate maior de 9 jogos bloqueou promocao: base `66.7%`, candidata `22.2%`,
    blocker `candidate_underperformed_base_probe`. Licao global: a carta
    adicionada pode ser util, mas o corte de `Birgi` esta errado para essa shell
    sem substituto de mesma lane e gate maior aprovado.
    O modelo nonland agora bloqueia cortes cross-lane de ramp com
    `cross_lane_ramp_cut_requires_same_lane_source_or_gate`, removendo `Birgi`
    dos cuts genericos de removal. O novo top pair `+Feed the Swarm /
    -Archaeomancer's Map` tambem falhou no gate maior: base `66.7%`, candidata
    `33.3%`, blocker `candidate_underperformed_base_probe`, mesmo com `Feed the
    Swarm` exercido no replay. Proxima busca: corte mais seguro de mesma lane ou
    pacote diferente, nao promocao.
    Depois dos probes/gates, rode
    `manaloom-knowledge/scripts/global_commander_battle_feedback_model.py` para
    consolidar o historico por assinatura add/cut exata antes de reabrir a fila
    de aprendizado. Evidencia local atual:
    `master_optimizer_reports/global_commander_battle_feedback_model_20260705_current.md`.
    O modelo marcou `2` pares como `pair_blocked_by_failed_gate`
    (`+Feed the Swarm / -Birgi, God of Storytelling // Harnfel, Horn of Bounty`
    e `+Feed the Swarm / -Archaeomancer's Map`) e `1` pacote como
    `pair_needs_exposure_replay_before_gate`. A recomendacao reutilizavel para
    os pares exercitados que falharam e `block_pair_until_new_source_lane_or_cut`;
    o probe pequeno positivo de `+Feed / -Birgi` fica supersedido pelo gate maior
    reprovado.
    O modelo nonland consome esse feedback antes de emitir pares frescos:
    pares exatos bloqueados entram em `blocked_by_global_battle_feedback` /
    `blocked_pair_hypotheses`, entao `+Feed the Swarm / -Archaeomancer's Map`
    nao deve continuar como top par review-ready sem nova source lane, novo
    corte ou pacote diferente.
    Quando varias copias candidatas forem encadeadas, rode
    `manaloom-knowledge/scripts/global_commander_candidate_package_chain_audit.py`.
    Evidencia local atual:
    `master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_removal_floor_step5.md`.
    A cadeia Kaalia step5 ficou estruturalmente pronta como pacote de piso de
    removal em DB copiado: adds `Path to Exile`, `Feed the Swarm`,
    `Swords to Plowshares`, `Rakdos Charm` e `Terminate`; cuts
    `Archaeomancer's Map`, `Genji Glove`, `Karlach, Fury of Avernus`,
    `Ardenn, Intrepid Archaeologist` e `Grim Tutor`. Resultado:
    `core_floor_repaired=true`, `removal=6`, `strategy_ready=true`, mas
    `battle_gate_allowed_now=false` e `promotion_allowed=false`. Proximo gate:
    `run_commander_specific_strategy_matrix_for_package_before_battle`.
    A matriz especifica do pacote tambem foi rodada em
    `manaloom-knowledge/scripts/global_commander_candidate_package_strategy_matrix.py`.
    Evidencia local atual:
    `master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.md`.
    Resultado: `package_strategy_blocks_battle`, com blockers
    `profile_lands_below_target`, `profile_angels_demons_dragons_payoffs_below_target`,
    `profile_spot_interaction_below_target` e
    `attack_window_cut_without_replacement`. Mesmo apos o pacote subir
    spot interaction de `1` para `6`, Kaalia ainda fica abaixo do alvo `8-12`,
    com lands `34` contra `35-37` e payoffs Angel/Demon/Dragon `4` contra
    `22-30`; `battle_gate_allowed_now=false`, `promotion_allowed=false` e o
    proximo gate passa a ser `repair_commander_profile_blockers_before_battle`.
    O plano de reparo read-only fica em
    `manaloom-knowledge/scripts/global_commander_profile_blocker_repair_plan.py`
    com evidencia local
    `master_optimizer_reports/global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5.md`.
    Sequencia exigida: `repair_or_restore_commander_attack_window_before_more_interaction`,
    `repair_mana_base_to_commander_land_floor`,
    `repair_commander_payoff_density_with_legal_source_lanes`,
    `finish_spot_interaction_floor_with_same_lane_cut` e
    `rerun_global_commander_candidate_package_strategy_matrix`; papeis acima do
    alvo como mana acceleration, card draw e tutors sao pressao de revisao, nao
    autorizacao automatica de corte.
    O modelo de candidatos de reparo fica em
    `manaloom-knowledge/scripts/global_commander_profile_repair_candidate_model.py`
    com evidencia local
    `master_optimizer_reports/global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.md`.
    Resultado: `profile_repair_candidate_model_blocks_materialization`.
    Land, spot interaction e attack-window ja tem pools legais/review-only,
    incluindo `Arena of Glory`, `Hall of the Bandit Lord`, `Despark` e
    `Anguished Unmaking`; porem ADD payoff segue bloqueado porque o shortfall e
    `18` e ha apenas `5` candidatos prontos no expected package local.
    Portanto `candidate_copy_allowed_now=false`, `battle_gate_allowed_now=false`
    e o proximo gate e `expand_commander_payoff_source_lane_before_candidate_copy`.
    A expansao da source lane de payoffs fica em
    `manaloom-knowledge/scripts/global_commander_payoff_source_lane_expander.py`
    com evidencia local
    `master_optimizer_reports/global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5.md`.
    Resultado: `commander_payoff_source_lane_expanded`; a varredura local
    Oracle/Hermes encontrou `30` candidatos ADD legais/WBR contra shortfall `18`,
    incluindo `Balefire Dragon`, `Ancient Copper Dragon`, `Angel of the Ruins`,
    `Hoarding Broodlord`, `Hellkite Charger` e `Avacyn, Angel of Hope`.
    Mesmo assim `candidate_copy_allowed_now=false`, `battle_gate_allowed_now=false`
    e o proximo gate passa a ser
    `synthesize_commander_payoff_package_before_candidate_copy`.
    A sintese do pacote de payoffs fica em
    `manaloom-knowledge/scripts/global_commander_payoff_package_synthesizer.py`
    com evidencia local
    `master_optimizer_reports/global_commander_payoff_package_synthesizer_20260705_kaalia_removal_floor_step5.md`.
    Resultado: `commander_payoff_package_synthesis_blocks_candidate_copy`.
    O modelo usa `Arena of Glory` para cobrir ataque/land, inclui `Despark`,
    `Anguished Unmaking` e `18` payoffs Angel/Demon/Dragon, mas isso vira `21`
    adds contra apenas `10` cuts review-only. Como ficam `11` adds sem par e o
    pacote passa do limite de `8` swaps, `candidate_copy_allowed_now=false`,
    `battle_gate_allowed_now=false` e o proximo gate e
    `expand_commander_cut_source_lane_for_full_profile_package`.
    A expansao da source lane de cortes fica em
    `manaloom-knowledge/scripts/global_commander_cut_source_lane_expander.py`
    com evidencia local
    `master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_removal_floor_step5.md`.
    Resultado: `commander_cut_source_lane_expanded_stage_split_required`.
    O modelo ampliou de `10` para `18` cuts value-safe, mas ainda falta `3`
    para cobrir os `21` adds. Ele mantem `17` cuts como stage-only por staple,
    ancora do pacote esperado ou feedback de batalha, incluindo `Birgi`,
    `Necropotence`, `Demonic Tutor`, `Vampiric Tutor`, `Enlightened Tutor`,
    `Esper Sentinel`, `Smothering Tithe`, `Mana Vault`, `Arcane Signet` e
    `Sol Ring`. Portanto `candidate_copy_allowed_now=false`,
    `battle_gate_allowed_now=false` e o proximo gate e
    `split_synthesized_package_into_value_safe_stages`.
    O split de estagios value-safe fica em
    `manaloom-knowledge/scripts/global_commander_value_safe_stage_splitter.py`
    com evidencia local
    `master_optimizer_reports/global_commander_value_safe_stage_splitter_20260705_kaalia_removal_floor_step5.md`.
    Resultado: `commander_value_safe_stage_split_ready_for_stage_candidate_copy`.
    O modelo pareou `18` swaps em `3` estagios sob limite `8`; stage 1 tem `8`
    pares e pode seguir apenas para copia candidata isolada. O pacote completo
    segue bloqueado porque `The Balrog of Moria`, `Wrathful Red Dragon` e
    `Akroma, Angel of Wrath` estao sem cuts. Portanto
    `stage_candidate_copy_allowed_now=true`,
    `full_package_candidate_copy_allowed_now=false`,
    `battle_gate_allowed_now=false` e o proximo gate e
    `materialize_value_safe_stage_1_candidate_copy`.
    A materializacao do stage 1 agora foi executada apenas em copia isolada por
    `manaloom-knowledge/scripts/global_commander_candidate_copy_materializer.py`
    com evidencia local
    `master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1.md`.
    Resultado: `candidate_materialized_structure_ready_next_gate_closed` com
    `8` swaps, `source_unchanged=true`, `source_matches_pair_report=true`,
    `all_adds_present_once=true`, `all_cuts_absent=true`,
    `total_cards_100=true`, `commander_count_1=true`,
    `allow_battle_gate_now=false` e `promotion_allowed=false`. A copia final
    fica em
    `master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_candidate/knowledge_candidate.db`.
    Os audits posteriores do stage 1 estao em
    `master_optimizer_reports/global_commander_core_role_audit_20260705_kaalia_value_safe_stage1_hermes_only.md`,
    `master_optimizer_reports/global_commander_strategy_matrix_20260705_kaalia_value_safe_stage1_hermes_only.md`,
    `master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1.md`
    e
    `master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1.md`.
    A cadeia continua bloqueada antes de batalha: `final_core_status=core_role_gap`,
    `removal=3` abaixo do piso `6`, e a matriz especifica retorna
    `package_strategy_blocks_battle` por
    `package_core_floor_not_repaired`,
    `profile_angels_demons_dragons_payoffs_below_target` e
    `profile_spot_interaction_below_target`. Proximo gate:
    `repair_commander_profile_blockers_before_battle`.
    A sequencia de reparo encadeada aplicou mais dois stages em copias
    isoladas:
    `master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_stage1.md`
    e
    `master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_stage2.md`.
    O segundo stage usa `allow_chained_source=true`; isso so e aceito porque a
    fonte permaneceu imutavel e a promocao continuou fechada. A cadeia
    consolidada em
    `master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_stage2.md`
    ficou `pass`, com `core_floor_repaired=true`, `final_core_status=core_review_ready`,
    `removal=8`, `land=35` e `ramp=16`. Mesmo assim, a matriz especifica
    `master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_stage2.md`
    bloqueia batalha por `profile_angels_demons_dragons_payoffs_below_target`
    e `profile_reanimation_plan_b_below_target`.
    Aprendizado aplicado: `package_core_floor_not_repaired` precisa virar eixo
    concreto (`core_removal_floor` -> `spot_interaction`), `reanimation_plan_b`
    precisa entrar no candidate model/synthesizer, `Birgi` fica bloqueado por
    feedback global de batalha, e staples estruturais como `Demonic Tutor`,
    `Vampiric Tutor`, `Enlightened Tutor`, `Smothering Tithe`, `Mana Vault`,
    `Arcane Signet` e `Sol Ring` nao podem ser cortes automaticos. Com essas
    protecoes, o pacote final em
    `master_optimizer_reports/global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_stage2.md`
    fica corretamente bloqueado: `7` reparos, `6` cuts seguros, `Necromancy`
    sem par. O cut expander
    `master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_stage2.md`
    confirma `value_safe_cut_shortfall:required_7_ready_1`. Proximo gate:
    `backfill_value_safe_cuts_or_reduce_package_scope`.
    O novo gate de reducao de escopo fica em
    `manaloom-knowledge/scripts/global_commander_package_scope_reducer.py`
    com evidencia local
    `master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_stage2.md`.
    Resultado: `commander_package_scope_reduced_ready_for_candidate_copy`.
    Como so havia `1` cut value-safe, o reducer abriu apenas
    `+Necromancy / -Cabal Ritual`, fechando `reanimation_plan_b` de `1` para
    `0`, mas manteve o pacote completo bloqueado (`full_package_candidate_copy_allowed_now=false`)
    e roteou o proximo gate para `materialize_reduced_scope_candidate_copy`.
    `angels_demons_dragons_payoffs` ainda fica aberto. A materializacao
    isolada fica em
    `master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1.md`;
    ela prova `source_unchanged=true`, `source_matches_pair_report=true`,
    `allow_battle_gate_now=false` e `promotion_allowed=false`. A chain
    consolidada fica em
    `master_optimizer_reports/global_commander_candidate_package_chain_audit_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    e passa com `swap_count=21`, `core_floor_repaired=true` e
    `final_core_status=core_review_ready`. A matriz especifica final fica em
    `master_optimizer_reports/global_commander_candidate_package_strategy_matrix_20260705_kaalia_value_safe_stage1_repair_scope1.md`;
    nela `reanimation_plan_b` esta em faixa, mas
    `angels_demons_dragons_payoffs` segue `16` contra alvo `22-30`, entao o
    battle continua fechado e o proximo gate e
    `repair_commander_profile_blockers_before_battle`.
    Esse gate ja foi seguido em modo read-only: o plano
    `master_optimizer_reports/global_commander_profile_blocker_repair_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    mostra um unico eixo, `angels_demons_dragons_payoffs`, com shortfall `6`.
    O modelo estreito
    `master_optimizer_reports/global_commander_profile_repair_candidate_model_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    bloqueia materializacao e manda expandir a source lane; a expansao
    `master_optimizer_reports/global_commander_payoff_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    encontra `30` candidatos prontos. A sintese
    `master_optimizer_reports/global_commander_payoff_package_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    seleciona `Dragon Mage`, `Bonehoard Dracosaur`,
    `Drakuseth, Maw of Flames`, `The Balrog of Moria`,
    `Wrathful Red Dragon` e `Akroma, Angel of Wrath`, mas so tem `5` cortes
    tentativos. O cut expander
    `master_optimizer_reports/global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    confirma `value_safe_cut_count=0` e `stage_only_cut_count=15`; o reducer
    `master_optimizer_reports/global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    bloqueia ate escopo reduzido com `no_value_safe_reduced_scope_pair_ready`.
    O novo planner
    `manaloom-knowledge/scripts/global_commander_stage_only_cut_evidence_plan.py`
    gera
    `master_optimizer_reports/global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Menor onus de aprendizado: `Professional Face-Breaker`, `Diabolic Intent`
    e `Ornithopter of Paradise` precisam de
    `contextual_staple_same_lane_usage_review` antes de qualquer
    reclassificacao value-safe. Proximo gate:
    `collect_stage_only_cut_evidence_before_value_safe_reclassification`.
    Esse gate ja avançou por trace contextual: o reviewer confirmou uso real
    das tres cartas pelo deck alvo e manteve reclassificacao fechada. Em
    seguida rode
    `manaloom-knowledge/scripts/global_commander_same_lane_replacement_model.py`;
    evidencia:
    `master_optimizer_reports/global_commander_same_lane_replacement_model_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `usage_blocked_cut_count=3`,
    `same_lane_replacement_route_count=0`,
    `incidental_role_overlap_count=4` e
    `remaining_stage_only_cut_source_count=12`. Incidental role overlap de
    payoff como `Bonehoard Dracosaur`/`The Balrog of Moria` nao prova a mesma
    lane de `Professional Face-Breaker` ou `Ornithopter of Paradise`; o proximo
    passo e uma new cut-source-lane evidence pass, nao candidate copy, battle
    ou promocao.
    Essa passagem tambem ja foi coletada sem nova batalha por
    `manaloom-knowledge/scripts/global_commander_new_cut_source_lane_trace_collector.py`;
    evidencia:
    `master_optimizer_reports/global_commander_new_cut_source_lane_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: dos `12` cortes restantes, `9` foram usados pelo deck alvo,
    `2` foram vistos sem uso e `1` nao apareceu; o proximo gate e
    `force_access_or_expand_cut_source_lane_for_unresolved_remaining_cuts`.
    O gate de force-access foi globalizado para o evaluation target atual e
    executado por
    `manaloom-knowledge/scripts/global_commander_forced_cut_access_trace_generator.py`;
    evidencia:
    `master_optimizer_reports/global_commander_forced_cut_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `Alicia Masters, Skilled Sculptor`, `Vampiric Tutor` e
    `Dark Ritual` foram forcados para acesso inicial em `3` seeds e todos foram
    usados pelo deck alvo. A lane atual de cortes segue fechada; o proximo gate
    e `expand_cut_source_lane_after_forced_access_blocks_current_unresolved_cuts`.
    Esse gate foi executado com o relatorio de force-access como entrada em
    `global_commander_cut_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md`
    e depois reduzido por
    `global_commander_package_scope_reducer_20260705_kaalia_value_safe_stage1_repair_scope1_post_forced.md`.
    Resultado: `value_safe_cut_count=0`, `scoped_pair_count=0`,
    `forced_usage_blocked_count=3`; candidate copy, battle e promocao seguem
    fechados. O proximo gate e
    `synthesize_new_value_safe_cut_source_or_smaller_package_after_forced_access_block`.
    Esse gate foi sintetizado por
    `global_commander_post_forced_recovery_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`:
    `selected_add_count=6`, `required_cut_count=6`, `value_safe_cut_count=0`,
    `stage_only_cut_count=15`, `scoped_pair_count=0`. A decisao atual e
    `mine_new_value_safe_cut_source_before_package_resynthesis`; o pacote atual
    segue fechado para candidate copy, battle, promocao e mutacao.
    A mineracao fresca foi executada por
    `global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `hypothesis_count=8`, com `Biotransference`, `Maskwood Nexus`,
    `Sigarda's Aid`, `Necromancy`, `Necropotence`, `Trouble in Pairs`,
    `Puresteel Paladin` e `Sram, Senior Edificer`. Elas ainda nao sao cortes
    value-safe; o proximo gate e
    `collect_usage_trace_for_new_cut_source_hypotheses`.
    Esse trace foi coletado por
    `global_commander_cut_source_hypothesis_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`
    usando os `8` replay seeds existentes. Resultado:
    `usage_blocked_hypothesis_count=6`, `seen_without_usage_count=2`,
    `not_seen_count=0`; `Biotransference`, `Maskwood Nexus`, `Sigarda's Aid`,
    `Necromancy`, `Necropotence` e `Sram, Senior Edificer` foram usados pelo deck
    alvo. Proximo gate: `mine_more_hypotheses_or_build_same_lane_proof`.
    O proof de mesma lane foi executado por
    `global_commander_cut_hypothesis_same_lane_proof_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `explicit_same_lane_route_count=0`,
    `incidental_role_overlap_count=9` e
    `package_explicit_add_axes=angels_demons_dragons_payoffs`. As sobreposicoes
    de card draw/dedicated win em payoffs como `Dragon Mage` ou
    `The Balrog of Moria` sao incidentais porque o pacote foi selecionado para
    cobrir payoffs Angel/Demon/Dragon, nao para substituir as lanes de corte.
    Proximo gate: `mine_more_hypotheses_or_external_cut_source_research`;
    candidate copy, battle, promocao e reclassificacao value-safe seguem
    fechados.
    A pesquisa externa foi registrada por
    `global_commander_external_cut_source_research_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_cut_source_research_plan_ready_no_deck_action`, com
    `external_source_count=6` e proximo gate
    `collect_external_commander_reference_corpus_for_cut_candidates`. As fontes
    externas atuais sustentam bracket/power context, payoff density,
    attack-window e metodologia de categorias, mas nao substituem trace do deck
    alvo nem abrem permissao de corte.
    O corpus externo foi coletado em
    `global_commander_external_reference_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_reference_corpus_collected_no_cut_permission`, com
    `corpus_present_count=3`, `corpus_absent_count=5`, `usage_blocked_count=6`
    e `seen_without_usage_count=2`. `Necromancy`, `Necropotence` e
    `Trouble in Pairs` tem presenca no corpus Kaalia checado; as outras cinco
    hipoteses nao apareceram nessas fontes. A ausencia externa nao vence uso no
    deck alvo, e a presenca externa exige prova same-lane/equal-gate ou revisao
    negativa antes de corte. Proximo gate:
    `map_external_corpus_to_cut_policy_before_rerun_miner`.
    O mapper de politica fica em
    `global_commander_external_corpus_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_corpus_cut_policy_blocks_current_hypotheses`, com
    `excluded_from_rerun_miner_count=6`,
    `held_for_negative_review_count=2` e
    `rerun_miner_allowed_card_count=0`. O proximo minerador precisa consumir
    essas exclusoes antes de emitir novas hipoteses.
    O rerun do minerador com politica externa fica em
    `global_commander_value_safe_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md`.
    Resultado: `value_safe_cut_source_mining_blocks_package_resynthesis`, com
    `hypothesis_count=0`, `blocked_hypothesis_count=88` e
    `external_policy_exclusion_count=8`. Proximo gate:
    `broaden_commander_package_axis_or_external_cut_research`.
    O plano de broadening fica em
    `global_commander_package_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1_external_policy.md`.
    Resultado: `commander_package_axis_broadening_plan_ready_no_deck_action`,
    com `selected_add_count=6`, `selected_cut_count=5`,
    `value_safe_cut_count=0` e
    `lane_alignment_status=package_axis_mismatch_with_exhausted_cut_lanes`.
    O pacote atual adiciona `angels_demons_dragons_payoffs`, mas os cortes
    esgotados estao em `haste_protection_silence`, `mana_acceleration` e
    `tutors_access`; texto secundario nos payoffs e incidental, nao prova
    same-lane. Proximo gate:
    `resynthesize_package_with_same_lane_axis_requirements`.
    A resintese same-lane fica em
    `global_commander_same_lane_package_resynthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado:
    `same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes`,
    com `held_payoff_add_count=6`,
    `same_lane_axis_requirement_count=3`,
    `satisfied_same_lane_axis_count=0`, `value_safe_cut_count=0` e
    `ready_pair_count=0`. Os eixos requeridos agora sao
    `commander_attack_window`, `mana_acceleration_replacement` e
    `tutors_access_replacement`. Proximo gate:
    `expand_same_lane_add_source_lanes_for_target_cut_roles`.
    O expander dessas source-lanes fica em
    `global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_add_source_lanes_expanded_no_deck_action`, com
    `requirement_count=3`, `ready_axis_count=3` e `missing_axis_count=0`.
    As top lanes locais agora incluem `Boros Charm`, `Swiftfoot Boots` e
    `Flawless Maneuver` para attack-window; `Fellwar Stone`, signets e
    talismans para mana; e `Gamble`, `Wishclaw Talisman`, `Entomb` e
    `Imperial Seal` para acesso/tutor. Isso ainda e source-lane de revisao,
    nao par add/cut. Proximo gate:
    `resynthesize_same_lane_package_from_source_lanes_before_cut_pairing`.
    A sintese de pacote same-lane fica em
    `global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_source_package_synthesized_no_cut_pairs`, com
    `package_size_limit=8`, `selected_add_count=8`, `axes_covered_count=3`,
    `unpaired_add_count=8` e `ready_pair_count=0`. Adds selecionados:
    `Boros Charm`, `Fellwar Stone`, `Gamble`, `Swiftfoot Boots`,
    `Wishclaw Talisman`, `Entomb`, `Imperial Seal` e `Diabolic Tutor`.
    Proximo gate:
    `collect_value_safe_same_lane_cut_pairs_for_resynthesized_package`.
    A coleta de pares same-lane fica em
    `global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_cut_pair_collection_blocks_candidate_copy`, com
    `selected_add_count=8`, `required_pair_count=8`, `ready_pair_count=0`,
    `unpaired_add_count=8`, `stage_only_cut_candidate_count=28` e
    `blocked_cut_candidate_count=19`. Nenhum add pode ser copiado ainda; o
    proximo gate e
    `collect_more_same_lane_cut_evidence_or_broaden_cut_source_lanes`.
    O plano de evidencia desses cortes fica em
    `global_commander_same_lane_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_cut_evidence_plan_ready_no_deck_action`, com
    `stage_only_cut_evidence_count=28`, `hard_blocked_cut_count=19` e
    `ready_pair_count=0`. O proximo gate e
    `collect_trace_or_external_evidence_for_same_lane_stage_only_cuts`.
    A coleta de trace desses cortes fica em
    `global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_stage_cut_trace_collection_blocks_used_cuts`, com
    `stage_cut_count=28`, `usage_blocked_count=19`,
    `seen_without_usage_count=4`, `external_reference_only_count=1` e
    `needs_trace_or_external_research_count=4`. O proximo gate e
    `build_same_lane_replacement_or_find_new_cut_source_for_used_stage_cuts`.
    O roteador desses cortes usados fica em
    `global_commander_same_lane_used_cut_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_used_cut_recovery_routes_to_new_cut_source`, com
    `used_cut_count=19`, `strict_recovery_count=10`,
    `same_lane_replacement_proof_count=9` e `no_same_lane_route_count=0`. O
    proximo gate e
    `mine_or_research_new_same_lane_cut_source_before_candidate_copy`.
    O minerador de fonte nova fica em
    `global_commander_same_lane_new_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_new_cut_source_mining_exhausted_current_deck`, com
    `target_role_count=3`, `scanned_same_lane_source_count=47`,
    `fresh_same_lane_cut_source_count=0` e
    `blocked_recycled_cut_source_count=47`. O proximo gate e
    `broaden_same_lane_cut_research_or_package_axis_before_candidate_copy`.
    O plano de ampliacao de eixo fica em
    `global_commander_same_lane_cut_axis_broadening_plan_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `same_lane_cut_axis_broadening_plan_ready_no_deck_action`, com
    `ready_pair_count=0`, `unpaired_add_count=8` e os tres papeis
    (`haste_protection_silence`, `mana_acceleration`, `tutors_access`)
    exauridos no deck atual. O proximo gate e
    `collect_external_nonpayoff_same_lane_cut_corpus_for_exhausted_roles`.
    O coletor de corpus externo/nonpayoff fica em
    `global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_nonpayoff_same_lane_corpus_collected_no_cut_permission`,
    com `external_source_count=6`, `role_corpus_count=3`,
    `exhausted_role_count=3`, `ready_pair_count=0` e
    `external_cut_permission_now=false`. O proximo gate e
    `map_external_nonpayoff_same_lane_corpus_to_cut_policy_before_source_discovery`.
    O mapper de politica desse corpus fica em
    `global_commander_external_nonpayoff_same_lane_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_nonpayoff_same_lane_policy_ready_no_cut_permission`,
    com `role_policy_count=3`, `source_discovery_required_role_count=3`,
    `rerun_miner_allowed_role_count=0` e
    `card_level_cut_permission_count=0`. O proximo gate e
    `discover_external_nonpayoff_same_lane_source_candidates_before_miner`.
    O descobridor de candidatos externos/nonpayoff fica em
    `global_commander_external_nonpayoff_same_lane_source_candidate_discoverer_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission`,
    com `source_candidate_count=16`, `role_count=3`,
    `current_deck_present_count=6`, `outside_current_deck_count=10`,
    `local_identity_found_count=15`, `selected_as_package_add_count=4` e
    `card_level_cut_permission_count=0`. O proximo gate e
    `review_external_nonpayoff_same_lane_source_candidates_locally_before_miner`.
    O reviewer local desses candidatos fica em
    `global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action`,
    com `reviewed_candidate_count=16`, `miner_source_seed_allowed_count=5`,
    `current_deck_trace_required_count=6`, `held_package_pair_required_count=4`,
    `identity_resolution_required_count=1`, `role_mismatch_blocked_count=0`,
    `card_level_cut_permission_count=0` e `candidate_copy_allowed_count=0`.
    O proximo gate e
    `rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates`.
    O miner rerodado com seeds externos revisados fica em
    `global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `reviewed_external_seeded_cut_source_hypotheses_ready_for_trace`,
    com `reviewed_seed_count=5`, `seeded_role_count=2`,
    `target_role_count=3`, `unseeded_target_role_count=1`,
    `scanned_seeded_same_lane_source_count=34`,
    `fresh_seeded_same_lane_cut_source_count=10`,
    `blocked_recycled_seeded_cut_source_count=21`,
    `blocked_new_seeded_cut_source_count=3`,
    `card_level_cut_permission_count=0` e `candidate_copy_allowed_count=0`.
    O proximo gate e
    `collect_trace_for_reviewed_external_seeded_cut_source_hypotheses`.
    O collector de trace dessas hipoteses fica em
    `global_commander_reviewed_external_seeded_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `reviewed_external_seeded_cut_trace_needs_force_access`,
    com `hypothesis_count=10`, `usage_blocked_hypothesis_count=0`,
    `seen_without_usage_count=0`, `not_seen_count=10`,
    `seed_report_count=8`, `card_level_cut_permission_count=0` e
    `candidate_copy_allowed_count=0`. O proximo gate e
    `force_access_or_expand_replay_window_for_seeded_hypotheses`.
    O forced-access seedado fica em
    `global_commander_reviewed_external_seeded_force_access_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `reviewed_external_seeded_forced_access_blocks_absent_hypotheses`,
    com `source_hypothesis_count=10`, `focus_hypothesis_count=10`,
    `seed_count=3`, `selected_db_absent_count=10`,
    `card_level_cut_permission_count=0` e `candidate_copy_allowed_count=0`.
    Isso prova que as 10 hipoteses seedadas nao existem na DB candidata scope1
    atual; elas nao podem virar corte, copia candidata ou battle. O miner
    rerodado na DB scope1 atual (`rerun_seeded_cut_source_miner_against_current_evaluation_db`)
    fica em
    `global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260705_kaalia_value_safe_stage1_repair_scope1_current_db.md`.
    Resultado: `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`,
    com `fresh_seeded_same_lane_cut_source_count=0`,
    `blocked_recycled_seeded_cut_source_count=31` e proximo gate
    `expand_external_nonpayoff_seed_research_or_collect_current_deck_negative_review_before_candidate_copy`.
    O roteador pos-esgotamento fica em
    `global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_nonpayoff_seed_exhaustion_recovery_routes_to_current_deck_negative_review`,
    com `target_role_count=3`, `seeded_exhausted_role_count=2`,
    `unseeded_role_count=1`,
    `current_deck_negative_review_candidate_count=6`,
    `held_package_pair_required_count=4`,
    `identity_resolution_required_count=1` e
    `force_access_selected_db_absent_count=10`. O proximo gate e
    `collect_current_deck_negative_review_for_external_nonpayoff_candidates`.
    O coletor de negative review para candidatos ja presentes no deck fica em
    `global_commander_external_nonpayoff_current_deck_negative_review_collector_20260705_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `external_current_deck_negative_review_blocks_used_candidates`,
    com `current_deck_candidate_count=6`, `usage_blocked_candidate_count=5`,
    `seen_without_usage_count=1`, `not_seen_count=0`,
    `negative_review_cleared_count=0` e `candidate_copy_allowed_now=false`.
    Lightning Greaves, Arcane Signet, Demonic Tutor, Diabolic Intent e
    Enlightened Tutor foram usados pelo alvo; Vampiric Tutor foi visto sem uso
    e ainda precisa de negative review manual. O proximo gate e
    `find_new_external_source_or_explicit_same_lane_replacement_proof`.
    O finder de fonte nova/prova de substituicao fica em
    `global_commander_external_nonpayoff_new_source_or_replacement_finder_20260706_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado: `new_external_source_candidates_ready_for_local_review`, com
    `current_deck_usage_blocked_count=5`,
    `explicit_same_lane_replacement_proof_count=0`,
    `new_external_candidate_count=22` e
    `new_external_ready_for_review_count=19`. As fontes novas cobrem
    `haste_protection_silence=8`, `mana_acceleration=7` e `tutors_access=4`,
    mas seguem como seed/review apenas. O proximo gate e
    `review_new_external_nonpayoff_source_candidates_locally_before_seeded_miner`.
    O reviewer local dessas fontes novas fica em
    `global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1.md`.
    Resultado:
    `new_external_source_candidates_reviewed_seed_ready_no_deck_action`, com
    `finder_ready_candidate_count=19`, `reviewed_candidate_count=19`,
    `miner_source_seed_allowed_count=19`, cobertura
    `haste_protection_silence=8`, `mana_acceleration=7` e `tutors_access=4`,
    e `candidate_copy_allowed_now=false`. A rerodada do minerador com essas
    sementes fica em
    `global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`.
    Resultado:
    `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`,
    com `reviewed_seed_count=19`, `seeded_role_count=3`,
    `unseeded_target_role_count=0`, `scanned_seeded_same_lane_source_count=47`,
    `fresh_seeded_same_lane_cut_source_count=0`,
    `blocked_recycled_seeded_cut_source_count=47` e
    `blocked_new_seeded_cut_source_count=0`. Ou seja: seed coverage melhorou,
    mas ainda nao existe cut-source fresco para abrir copy, battle, promocao ou
    value-safe reclassification.
    O router dessa exaustao fica em
    `global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`.
    Resultado:
    `external_nonpayoff_seed_exhaustion_recovery_routes_to_source_expansion`,
    com `target_role_count=3`, `seeded_exhausted_role_count=3`,
    `unseeded_role_count=0`, `current_deck_negative_review_candidate_count=0`
    e `prior_blocked_recycled_seeded_cut_source_count=47`. O expander de pool
    externo fica em
    `global_commander_external_nonpayoff_source_candidate_pool_expander_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`.
    Resultado:
    `external_nonpayoff_source_candidate_pool_expanded_ready_for_local_review`,
    com `expanded_candidate_count=26`, `expanded_ready_for_review_count=22`,
    cobertura `haste_protection_silence=8`, `mana_acceleration=8` e
    `tutors_access=6`. `Mana Vault` foi bloqueada por ja estar no deck atual;
    `Mana Crypt`, `Jeweled Lotus` e `Dockside Extortionist` foram bloqueadas
    por banned/current legality. Nenhuma dessas linhas abre copy, battle,
    promocao ou value-safe reclassification; o proximo gate e
    `review_expanded_external_nonpayoff_source_candidates_locally_before_seeded_miner`.
    O reviewer do pool expandido fica em
    `global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources.md`.
    Resultado:
    `expanded_external_source_candidates_reviewed_seed_ready_no_deck_action`,
    com `reviewed_candidate_count=26`,
    `miner_source_seed_allowed_count=22`, `blocked_current_deck_count=1` e
    `blocked_commander_banned_count=3`. A rerodada do minerador fica em
    `global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md`.
    Resultado:
    `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`,
    com `reviewed_seed_count=22`, `scanned_seeded_same_lane_source_count=47`,
    `fresh_seeded_same_lane_cut_source_count=0` e
    `blocked_recycled_seeded_cut_source_count=47`. O router seguinte fica em
    `global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md`
    e roteia para negative review de `Mana Vault`. O coletor fica em
    `global_commander_external_nonpayoff_current_deck_negative_review_collector_20260706_kaalia_value_safe_stage1_repair_scope1_expanded_sources.md`.
    Resultado: `external_current_deck_negative_review_blocks_used_candidates`,
    com `current_deck_candidate_count=1`, `usage_blocked_candidate_count=1`,
    `seen_without_usage_count=0`, `not_seen_count=0` e
    `candidate_copy_allowed_now=false`. Mana Vault foi usada pelo alvo nos
    traces atuais, entao nao e safe cut nem justificativa para copy.
    O gate follow-up fica em
    `global_commander_external_nonpayoff_followup_source_candidate_expander_20260706_kaalia_value_safe_stage1_repair_scope1_after_mana_vault.md`.
    Resultado:
    `external_nonpayoff_followup_source_candidate_pool_expanded_ready_for_local_review`,
    com `cumulative_previous_candidate_name_count=55`,
    `followup_candidate_count=34` e `followup_ready_for_review_count=34`.
    O reviewer follow-up fica em
    `global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md`.
    Resultado:
    `expanded_external_source_candidates_reviewed_seed_ready_no_deck_action`,
    com `miner_source_seed_allowed_count=34` e cobertura dos tres roles
    alvo. A rerodada do minerador fica em
    `global_commander_reviewed_external_nonpayoff_seeded_cut_source_miner_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md`.
    Resultado:
    `reviewed_external_seeded_cut_source_mining_exhausted_current_deck_no_cut_permission`,
    com `reviewed_seed_count=34`, `fresh_seeded_same_lane_cut_source_count=0`
    e `blocked_recycled_seeded_cut_source_count=47`. O router follow-up fica em
    `global_commander_external_nonpayoff_seed_exhaustion_recovery_router_20260706_kaalia_value_safe_stage1_repair_scope1_followup_after_mana_vault.md`
    e volta para `expand_external_nonpayoff_source_candidate_pool`, sem abrir
    candidate copy, battle, promocao ou value-safe reclassification.
    Observacao operacional: snapshots historicos de candidate-copy, battle-probe,
    battle-feedback e package-chain dependem de artefatos locais ignorados. Se
    faltarem ou forem regenerados sem esses artefatos, a auditoria de superficie
    deve mostrar `warn`, nao falha ativa; antes de qualquer nova copia, batalha,
    requeue ou promocao, a evidencia exata precisa ser regenerada.
  - Auditoria de alinhamento:
    `manaloom-knowledge/scripts/deckbuilding_contract_surface_audit.py`.
  - Auditoria obrigatoria de artefatos Lorehold antes de usar historico em
    nova decisao:
    `manaloom-knowledge/scripts/lorehold_artifact_contract_audit.py`.
    O schema canonico atual da matrix e `decks[] + ranked_deck_keys`;
    `ranked_decks` e legado e so pode ser consumido via normalizador.
  - Auditoria de decisao do promotion gate Lorehold:
    `manaloom-knowledge/scripts/lorehold_promotion_gate_decision_audit.py`.
    Resultado atual: manter `607` como baseline protegido; `615` e fonte para
    teste estreito de pacote, nao troca direta de deck.
  - Modelos ativos de corte/acesso Lorehold devem usar `607` como baseline
    default. Evidencia corrente pos-PG276 com correcao de lane por Oracle e
    bloqueio de nucleo free-cast/paradigm:
    `master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.md`.
    Brainstone, Chaos Wand e Assemble the Players agora estao `verified/auto`
    com escopos executaveis, mas ainda nao ha pacote gate-ready porque falta
    corte seguro; a correcao bloqueia falsos cortes de interacao como
    `Redirect Lightning` tratados como draw e bloqueia `Improvisation
    Capstone` como nucleo de spell-chain, nao flex topdeck.
  - Fila runtime atual:
    `master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg282_final_eight.md`.
    PG281/PG282 fecharam a fila residual: `61` cards brutos bloqueados por
    runtime foram filtrados como regras `verified/auto`, e o total atual de
    runtime gaps e `0`. O gerador de foco atual
    `master_optimizer_reports/lorehold_focus_access_package_generator_20260630_after_profiled_gate.md`
    continua com `0` pacotes gate-ready por corte/trace/gate natural, nao por
    falta de regra runtime.
  - O auditor geral `operational_surface_alignment_audit.py` deve passar antes
    de declarar que scripts e docs estao conversando entre si.
  - `LOREHOLD_IDEAL_DECK_WORKFLOW_2026-06-24.md` fica como historico/metodologia
    de apoio quando nao divergir do contrato novo.
  - `build_optimized_deck.py` e `universal_optimizer.py` ficam como historicos
    bloqueados/legados, nao como caminho de handoff.

## Triagens recentes

- `BRANCH_RETENTION_AUDIT_2026-06-11.md`
  - Politica de retencao de branches: manter somente `master` e
    `codex/hermes-analysis-docs`.
  - Define `master` como fonte canonica e `codex/hermes-analysis-docs` como
    fila/staging Hermes, sem merge bruto para `master`.

- `CODEX_HERMES_COLLABORATION_PROTOCOL_2026-06-11.md`
  - Contrato operacional entre Codex local e Hermes/AWS.
  - Use para decidir quando Hermes pode escrever docs, quando Codex deve chamar
    report-only e como transformar achados Hermes em tarefas reais.

- `HERMES_RUNTIME_CRON_ALIGNMENT_2026-06-11.md`
  - Snapshot do runtime AWS depois do prune de branches e ajuste das crons.
  - Registra jobs habilitados/pausados, scripts alterados e validações feitas.

- `HERMES_DOCS_BRANCH_SYNC_CRON_2026-06-13.md`
  - Guardrail novo para auditorias Hermes na branch
    `codex/hermes-analysis-docs`.
  - Define a cron `manaloom-docs-branch-sync`, que deve mergear
    `origin/master` na branch docs antes de qualquer auditoria publicar achados
    sobre código vivo.
  - Use quando uma auditoria de docs/estrutura parecer stale ou antes de
    reativar crons como code-structure, normal-audit, weekly-audit ou
    logic-coherence.

- `HERMES_CRON_VALUE_AND_MIGRATION_AUDIT_2026-06-11.md`
  - Auditoria uma a uma das crons Hermes, com decisão de manter/pausar e plano
  para migrar o loop para o servidor ManaLoom.
  - Atualizado com a primeira rodada real pós-ajuste: watchdog OK, falha de
    ownership SQLite corrigida e sync de target deck com duplicatas tratado.

- `BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
  - Mapa detalhado da lógica atual de battle simulator, geração IA,
    otimização, Hermes e Lorehold.
  - Use para comparar novos planos de implementação antes de alterar
    `IMPLEMENTATION_GAPS.md` ou código.

- `BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
  - Plano de implementação faseado para agregação multi-função, snapshot
    Hermes, tags funcionais, `card_battle_rules`, learned decks e validação.
  - Use como checklist técnico antes de alterar schema, sync ou consumidores
    Hermes.

- `BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
  - Evidência da implementação local do primeiro slice: agregação por
    `card_id`, arrays JSON, hashes, testes anti-fanout e validação Lorehold em
    SQLite temporário.
  - Também registra o bridge de `master_optimizer_common.py` e
    `slot_optimizer.py` para ler `functional_tags_json`.
  - Use antes de avançar para validadores/report-only crons restantes ou apply
    no Hermes real.

- `BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md`
  - Lista de dúvidas, decisões de produto, logística e políticas que precisam
  de validação do owner antes das próximas fases.
  - Use quando uma alteração depender de regra de negócio e não só de código.

- `BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`
  - Handoff direto para o owner responder dúvidas, furos, logística e ideias
    antes das próximas fases de battle/IA/Hermes.
  - Use para separar o que já pode ser implementado dos pontos que ainda
    precisam de validação explícita.

- `HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`
  - Classifica scripts que ainda mencionam `functional_tag` como ativos,
    indiretos, manuais/importers ou históricos/pausados.
  - Use antes de aplicar o snapshot agregado no Hermes runtime real.

- `HERMES_DOCS_TRIAGE_2026-06-11.md`
  - Triagem curada dos commits `13a10128`, `372cdfca` e `76ec897f` da branch
    `codex/hermes-analysis-docs`.
  - Use antes de abrir tarefas a partir de `PLANO_CORRECAO.md`,
    `STRUCTURE_AUDIT.md` ou `TECHNICAL_MAP.md`.
  - Nao fazer merge bruto desses relatórios na `master` sem revalidar contra o
    código vivo.

- `HERMES_DOCS_TRIAGE_2026-06-19.md`
  - Triagem curada da branch `origin/codex/hermes-analysis-docs@7db89b40`.
  - Incorpora o achado P1 de `swap_integrity` no fluxo app de optimize/apply.
  - Mantem como pendencia separada sync Hermes de tags/CMC/Game Changers,
    limpeza de widgets/classes legados e refactor de optimize response.

- `DECISION_TRACE_V1_SLICE_2026-06-15.md`
  - Slice Hermes-only que adiciona `decision_trace_v1` aos replays de battle.
  - Use para auditar por que o simulador escolheu cast/resposta/ataque/pass
    antes de confiar em WR bruto ou sugerir swaps Lorehold.
  - Nao altera app/API/PostgreSQL; persistencia atual e JSON/MD.

- `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`
  - Complementa o trace com auditoria estrategica: mulligan, Lotus Petal,
    Mox Diamond, sacrificio de land, tutor, board wipe/wheel,
    removal/counter/protection, combate e pass/no-action.
  - Use para diferenciar jogada legal de jogada estrategicamente defensavel.
  - Estado atual: todas as categorias ficaram `coherent_in_sample` na rodada
    `20260615_172608`; ainda falta corpus maior para tratar isso como
    heuristica final.
  - Fontes de comunidade/artigos calibram heuristica; comportamento duro ainda
    exige regra oficial, replay e teste focado.

- `INFORMATION_BANK_DIAGNOSTIC_2026-06-15.md`
  - Diagnóstico do banco de informações do produto: PostgreSQL, SQLite Hermes,
    tags funcionais, semantic v2, battle rules, learned decks, Commander
    Reference, telemetria de IA/optimize e price history.
  - Use antes de criar novos pipelines de IA/battle para evitar fanout, fonte
    duplicada ou aprendizado a partir de tabela incompleta.
  - Recomendação central: criar snapshot agregado por `card_id` e bridge de
    identidade antes de promover novos sinais para lógica app-facing.

- `DATA_AND_CRON_HEALTH_AUDIT_2026-06-16.md`
  - Validação source-backed do preenchimento de dados e da efetividade das
    crons locais/Hermes AWS.
  - Confirma que PostgreSQL/views criticas estao coerentes, candidate quality e
    meta signals geram dados uteis, e o principal risco segue sendo join direto
    de deck com fontes multi-linha.
  - Use para decidir proximos applies controlados: candidate quality, auto
    promote learned decks e metricas de decision impact.

- `CRON_EFFICIENCY_REVALIDATION_2026-06-17.md`
  - Revalida uma a uma as crons Hermes/ManaLoom sob criterio de valor real,
    ruido e gasto de token.
  - Separa o que deve ficar no `manaloom-ops`, o que ainda faz sentido com
    provider e o que deve permanecer manual/pausado.
  - Use antes de reativar crons antigas ou trocar provider por custo.

- `EASYPANEL_HERMES_LAB_CONTAINER_2026-06-17.md`
  - Contrato operacional do container `hermes-lab` no EasyPanel.
  - Agora tambem documenta a frota de crons bootstrapada no startup e os jobs
    pausados/removidos por reconciliacao.

- `EASYPANEL_MANALOOM_OPS_CUTOVER_2026-06-17.md`
  - Contrato operacional do worker deterministico `manaloom-ops`.
  - Use para conferir cadencias reais, volume persistente e ordem de cutover.

- `EASYPANEL_AWS_RETIREMENT_CRON_MATRIX_2026-06-17.md`
  - Matriz final cron por cron para desligar a AWS sem manter duplicidade.
  - Use para decidir o que fica em `manaloom-ops`, o que continua em
    `hermes-lab` e o que deve ser definitivamente removido.

- `EASYPANEL_CRON_RUNTIME_AUDIT_2026-06-18.md`
  - Prova live da topologia final `manaloom-ops` vs `hermes-lab` ja no
    EasyPanel.
  - Confirma quais jobs usam provider/OpenAI, quais sao deterministicas e quais
    jobs provider-backed ja executaram com `last_status=ok`.
  - Use antes de declarar a AWS dispensavel ou de reabrir discussao sobre qual
    cron deve carregar `OPENAI_API_KEY`.

- `BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md`
  - Status pos-correcao da auditoria de battle: 16 seeds, 17069 eventos,
    2301 decision traces, 0 high/critical, 0 strategy blockers e apenas
    3 findings low `review_rule_used`.
  - Use para responder se cada etapa/jogada esta sendo auditada e quais gaps
    reais ainda impedem usar WR bruto como aprendizado forte.

- `NEW_CARD_CANDIDATE_REVIEW_2026-06-18.md`
  - Contrato da rotina geral de cartas novas/alteradas, incluindo
    `needs_data`, `needs_rule_review`, focused evidence e promotion gate.
  - Use para entender a cadencia normal das crons e o contrato report-only.

- `ALL_CARD_CANDIDATE_REVIEW_2026-06-19.md`
  - Rodada full-scope contra 34.079 cartas e 24 comandantes rastreados.
  - Use quando a pergunta for "todas as cartas", cobertura global de battle
    rules, backlog real de templates ou impacto em Lorehold/generator/optimize.
  - Registra a correcao de chave por `card_id` no SQLite operacional e a
    validacao de `--limit 0` como modo sem limite para runs globais.

- `BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md`
  - Consolidacao canônica do estado real do battle simulator, do generator e do
  caso Lorehold.
  - Use quando a pergunta for "o que ja esta suficientemente certo?" versus
  "o que ainda precisa virar dado util para criacao/optimize?".
  - Mantem a separacao entre laboratorio auditavel, fallback curado e verdade
    de produto/backend.

- `NEW_CARD_CANDIDATE_REVIEW_2026-06-18.md`
  - Contrato da rotina geral de cartas novas em `manaloom-ops`.
  - Use para entender o pipeline `candidate_review -> card_data_gap_review ->
    battle_rule_review_queue`.
  - Guardrail central: `needs_data` e `needs_rule_review` viram artefato/fila,
    nao regra verificada, nao swap automatico e nao write em PostgreSQL.

## Fonte de verdade atual

1. `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md`
   - Contrato operacional ponta a ponta.
   - Use para saber quais bancos, tabelas, scripts, parametros, guardrails e
     comandos devem ser usados.
   - Este e o documento principal para agentes.

2. `HERMES_MASTER_OPTIMIZER_LOOP_2026-06-06.md`
   - Diario tecnico/evidencial do battle + optimizer.
   - Use para entender decisoes recentes, aplicacoes bloqueadas, revalidacoes e
     estado atual do Lorehold.
   - Nao use sozinho como autorizacao de apply.

3. `BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
   - Explica a divisao entre simulador leve do backend, battle analyzer Hermes,
     generate/optimize app-facing e pipeline Lorehold learned deck.
   - Use como mapa atual antes de propor migracao Hermes -> backend.

4. `BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
   - Transforma o deep dive e as validações externas em plano executável.
   - Use como ordem padrão para implementar agregação por `card_id`, snapshot
     Hermes e consumidores set-based.

5. `BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
   - Evidência fresca de Slice 1 implementado localmente e validado, incluindo
     bridge do optimizer para arrays semânticos.
   - Use como baseline antes de aplicar no Hermes real ou migrar
     validadores/report-only crons restantes.

6. `BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md`
   - Perguntas e políticas pendentes para o owner validar.
   - Use antes de transformar heurística/cron/Hermes em comportamento de
     produção.

7. `BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`
   - Lista objetiva de perguntas, furos e decisões logísticas a retornar para
     Codex antes de promover comportamento novo.

8. `HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`
   - Inventário dos consumidores Hermes de `functional_tag` e quais já foram
     migrados para `functional_tags_json`.

9. `DECISION_TRACE_V1_SLICE_2026-06-15.md`
   - Contrato inicial de rastreabilidade de decisoes do battle.
   - Use antes de tratar WR alto como evidencia confiavel.

10. `BATTLE_DECISION_STRATEGY_AUDIT_2026-06-15.md`
   - Matriz oficial de estrategia versus legalidade para decisoes do simulador.
   - Use antes de implementar mulligan, fast mana, tutor, removal, wipe,
     combate ou pass/no-action como heuristica dura.

11. `HERMES_CRON_PIPELINE_ORDER_2026-06-07.md`
   - Snapshot da ordem e estado das crons.
   - Use para entender a frota atual, mas valide contra `/opt/data/cron/jobs.json`
     e artefatos frescos no container.

12. `master_optimizer_reports/`
   - Evidencias de execucoes.
   - Use sempre o report mais fresco que bate com `baseline_id`, `baseline_hash`
     e o SQLite vivo.

13. `HERMES_DOCS_VALIDATION_MATRIX_2026-06-07.md`
   - Classificacao de todos os docs raiz desta pasta.
   - Use para saber se um arquivo e canonico, operacional, historico ou backlog.

## Historico util, mas nao operacional

Estes arquivos podem explicar por que algo foi criado, mas nao devem guiar
execucao atual sem cruzar com o contrato E2E:

- `HERMES_CRON_GOVERNANCE_REPORT.md`
- `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md`
- `AUDIT_REPORT_2026-05-27.md`
- `AUDIT_REPORT_2026-05-30.md`
- `AUDIT_REPORT_2026-05-31.md`
- `COMMIT_DIGEST.md`
- `PROJECT_MEMORY.md`

## Docs gerais fora do Hermes runtime

Estes documentos falam do app/backend/produto em geral. Nao use para decidir
swaps, crons ou battle Hermes:

- `TECHNICAL_MAP.md`
- `STRUCTURE_AUDIT.md`
- `IMPLEMENTATION_TASKS.md`
- `PLANO_CORRECAO.md`
- `BACKEND_ACTIONABLE_TASKS.md`
- `FLUTTER_UI_AUDIT.md`
- `UI_ACTIONABLE_TASKS.md`
- `LOGIC_COHERENCE_REPORT_2026-05-29.md`
- `LOGIC_COHERENCE_REPORT_2026-05-29_E2E.md`
- `OPEN_RISKS.md`
- `PRODUCT_DIRECTION.md`
- `modules_coherence.md`

## Politica de exclusao

Nao deletar relatorios historicos que tenham evidencias de baseline, hash, apply,
rollback, provider, cron ou replay. Eles sao memoria auditavel.

Se uma doc antiga estiver confundindo agentes:

- prefira adicionar aviso de snapshot/historico no topo;
- ou mover para uma pasta de arquivo morto em uma PR separada;
- so delete se nao houver referencia, evidencia unica ou valor de auditoria.

## Furos adicionais identificados nesta organizacao

- `HERMES_CRON_GOVERNANCE_REPORT.md` e snapshot de 2026-06-05 e nao reflete a
  frota atual de 23 jobs.
- `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md` ainda descreve crons Lorehold antigas
  e uma politica de frequencia que nao e mais o contrato atual.
- `HERMES_CRON_PIPELINE_ORDER_2026-06-07.md` e util, mas parte dele foi
  superada pelo contrato E2E depois que `master_optimizer_end_to_end.sh` passou a
  executar slot scan.
- `STRUCTURE_AUDIT.md` e muito grande e pode contaminar contexto de agentes; use
  apenas quando a tarefa for auditoria estrutural ampla.
