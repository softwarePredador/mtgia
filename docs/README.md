# Documentacao ativa do ManaLoom

Este diretorio agora serve como indice curto. Relatorios antigos continuam no
repositorio como historico/prova, mas nao devem guiar implementacao sem checar
as fontes canônicas abaixo.

## Entrada canônica atual

1. `docs/qa/MANALOOM_FREE_BETA_RELEASE_CANDIDATE_2026-07-16.md`
   - decisão go/no-go da beta gratuita Web + Android: escopo, segurança,
     identidade de mesma SHA, evidências confirmadas, bloqueios, ordem de
     promoção, rollback e checklist final. E2E, resolution, Patrol, builds,
     runtime local, restore isolado e `full` já têm prova; gates externos
     e demais P0 permanecem abertos, portanto o estado continua NO-GO.
2. `docs/qa/MANALOOM_PRODUCT_EXPERIENCE_AUDIT_2026-07-16.md`
   - auditoria canônica de produto e experiência do app: inventário de rotas e
     telas, necessidades dos jogadores, sistema visual, fluxos interligados,
     correções, riscos P0-P2 e estado verificável dos gates.
3. `docs/qa/MANALOOM_FREE_BETA_RELEASE_OPS_GATE_2026-07-16.md`
   - contratos fail-closed de build/publicação, CORS, observabilidade,
     backup off-site, restore isolado, SBOM/provenance e provas externas.
4. `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`
   - perfis de execução, autorização de mutações, matriz de gates e critérios
     separados de conclusão local e de release.
5. `docs/CONTEXTO_PRODUTO_ATUAL.md`
   - prioridade operacional vigente e ponte para a evidência mais recente.
6. `docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md`
   - evidência fechada, remoções, resultados, resíduos e bloqueadores de release
     da rodada anterior; não substitui os gates do candidato de 2026-07-16.
7. `docs/qa/MANALOOM_BATTLE_DECKBUILDER_DEFINITIVE_2026-07-15.md`
   - auditoria final de battle, deckbuilder, famílias, cargas PostgreSQL,
     cobertura externa e pendências de produto.

## Referências técnicas e históricas

Os documentos abaixo preservam decisões e provas de suas datas. Consulte-os
quando a área exigir profundidade, mas não use um status antigo para substituir
o contrato ou a evidência corrente.

1. `docs/PROJECT_LOGIC_FULL_REPORT_2026-06-11.md`
   - relatório mestre de lógica atual do produto, app, backend, banco, IA,
     Hermes, crons, battle engine e validações.
2. `docs/hermes-analysis/DATA_MODEL_FINAL_VALIDATION_2026-06-15.md`
   - validação final source-backed de tabelas, views internas, fanout,
     relações app/backend, PostgreSQL real, Hermes/AWS, EasyPanel e fontes
     externas de Magic.
3. `docs/hermes-analysis/BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
   - detalhamento específico de battle simulator, geração IA, estratégia de
     melhoria/otimização de deck, Hermes e Lorehold.
4. `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
   - plano faseado para implementar agregação multi-função, snapshot Hermes,
     consumers set-based e validações.
5. `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
   - evidência do Slice 1 local: sync Hermes por `card_id`, arrays semânticos,
     hashes, bridge do optimizer e validação anti-fanout/Lorehold.
6. `docs/hermes-analysis/BATTLE_AI_PROJECT_DECISIONS_TO_VALIDATE_2026-06-11.md`
   - perguntas/dúvidas de produto, logística e política que precisam de validação
     antes das próximas mudanças estruturais.
7. `docs/hermes-analysis/BATTLE_AI_OWNER_VALIDATION_QUESTIONS_2026-06-11.md`
   - handoff objetivo de perguntas, furos, decisões logísticas e ideias que o
     owner deve validar antes das próximas fases de battle/IA/Hermes.
8. `docs/hermes-analysis/HERMES_FUNCTIONAL_TAG_CONSUMER_CLASSIFICATION_2026-06-11.md`
   - classificação dos consumidores Hermes de `functional_tag`, indicando quais
     já usam `functional_tags_json`, quais são indiretos e quais são manuais ou
     históricos.
9. `docs/hermes-analysis/DECK_GENERATION_FOCUS_READINESS_2026-06-16.md`
   - decisão operacional atual: battle/Hermes não bloqueia foco em geração e
     optimize; primeiro slice seguro adiciona sinal EDHREC bounded ao pipeline
     interno de candidate quality.
10. `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TRUTH_STUDY_2026-06-16.md`
   - estudo consolidado do estado real do battle simulator, da geracao de
     decks e do caso Lorehold; separa o que ja e dado util, o que ainda e
     heuristica operacional e a ordem correta dos proximos slices.
11. `docs/hermes-analysis/EASYPANEL_MANALOOM_OPS_CUTOVER_2026-06-17.md`
   - desenho operacional do cutover AWS Hermes -> EasyPanel para os jobs
     críticos do produto, com serviço `manaloom-ops`, volume, envs, limites e
     sequência de migração controlada.
12. `docs/hermes-analysis/EASYPANEL_CRON_MIGRATION_SLICE1_2026-06-17.md`
   - slice 1 de portabilidade dos entrypoints críticos (`pull-learning-events`,
     `auto-sync-learned-decks`, `master-optimizer-preflight`) para runtime
     server-owned.
13. `docs/hermes-analysis/NEW_CARD_CANDIDATE_REVIEW_2026-06-18.md`
   - contrato da rotina geral `manaloom_new_card_candidate_review` e de seus
     consumers `manaloom_card_data_gap_review` /
     `manaloom_battle_rule_review_queue`: detecção de cartas novas/alteradas,
     classificação de lacunas de dados, drafts `needs_review` de battle rules,
     report-only, sem LLM, sem auto-apply e com SQLite apenas como cache
     operacional.
14. `docs/hermes-analysis/ALL_CARD_CANDIDATE_REVIEW_2026-06-19.md`
   - rodada global full-scope contra 34.079 cartas e 24 comandantes
     rastreados; valida `needs_data`, `needs_rule_review`, focused evidence,
     promotion gate, correção de chave por `card_id` no cache operacional e
     próximos templates P1 para battle/deckbuilding.
15. `server/manual-de-instrucao.md`
   - diario operacional e ultimas decisoes aplicadas.
16. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
   - contratos app/backend, rotas, shapes e campos opcionais.
17. `app/doc/APP_AUDIT_2026-04-29.md`
   - status consolidado do app mobile, riscos e validacoes recentes.
18. `app/doc/UI_TEST_SURFACE_MAP.md`
   - keys e superficies que testes runtime devem usar.
19. `docs/qa/MANALOOM_INTERNAL_TEST_CHECKLIST_2026-05-15.md`
   - checklist para rodada interna non-scanner.
20. `server/doc/INTERNAL_TEST_ROUND_READY_2026-05-15.md`
   - status de distribuicao interna com riscos aceitos.
21. `server/doc/GLOBAL_PRODUCT_RIGOR_AUDIT_2026-05-18.md`
   - veredito global atual de produto, gates restantes e ordem de execucao.
22. `app/doc/runtime_flow_handoffs/README.md`
   - indice de runtime/handoffs e regra de evidencia fresca.
23. `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`
   - matriz de retencao KEEP/ACTIVE, KEEP/HISTORICAL, ARCHIVE e
     DELETE_CANDIDATE para docs e artefatos versionados.

## Relatorios recentes por tema

- Commander Reference: `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- Commander Reference Sprint 4: `server/doc/COMMANDER_REFERENCE_SPRINT4_EXECUTION_PLAN_2026-05-14.md`
- Push/FCM: `app/doc/runtime_flow_handoffs/push_delivery_android_sm_a135m_2026-05-11.md`
- Card entry/import: `docs/qa/manaloom_card_entry_qa_2026-05-08.md`
- Design Android: `docs/qa/manaloom_android_design_audit_sm_a135m_2026-05-07.md`
- Uniformidade de layout iPhone: `docs/qa/manaloom_layout_uniformity_audit_iphone15_2026-05-22.md`
- Gate visual premium: `docs/qa/MANALOOM_PREMIUM_VISUAL_QA_RUBRIC_2026-06-04.md` e
  baseline gerada em `docs/qa/manaloom_premium_visual_audit_latest.md`
- Tooling, custom_lint, Patrol e quality gates locais: `docs/qa/MANALOOM_TOOLING_VALIDATION_RUNBOOK_2026-07-06.md`
- Contrato E2E e de conclusão vigente: `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`
- Encerramento E2E corrente: `docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md`
- Battle/deckbuilder definitivo: `docs/qa/MANALOOM_BATTLE_DECKBUILDER_DEFINITIVE_2026-07-15.md`
- Prova runtime visual premium: `docs/qa/MANALOOM_PREMIUM_VISUAL_RUNTIME_PROOF_2026-06-04.md`
- Battle/generator truth (2026-06-17):
  `docs/hermes-analysis/BATTLE_GENERATOR_TRUTH_STUDY_2026-06-17.md`,
  `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md`,
  `docs/hermes-analysis/BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md`
- Lorehold miracle/topdeck audit (2026-06-17):
  `docs/hermes-analysis/LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md`
- Icone do app: `docs/qa/manaloom_app_icon_contact_sheet_2026-05-21.png`
- Splash art: `docs/qa/manaloom_splash_art_preview_2026-05-21.png`
- Auditoria de docs/artefatos: `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`
- Auditoria full-stack non-scanner: `server/doc/FULL_BACKEND_DATA_FLOW_AUDIT_2026-05-15.md`,
  `app/doc/FULL_APP_SCREEN_FIELD_AUDIT_2026-05-15.md`,
  `server/doc/FULL_STATE_REALTIME_CACHE_AUDIT_2026-05-15.md`,
  `server/doc/FULL_COMMANDER_AI_DECK_RULES_AUDIT_2026-05-15.md`,
  `server/doc/FULL_PROJECT_VALIDATION_MATRIX_2026-05-15.md` e
  `server/doc/FULL_PROJECT_AUDIT_MASTER_REPORT_2026-05-15.md`.
- Auditoria global de produto atual: `server/doc/GLOBAL_PRODUCT_RIGOR_AUDIT_2026-05-18.md`.
- Import localizado: `server/doc/RELATORIO_LOCALIZED_IMPORT_NAMES_2026-05-18.md`.
- Tags funcionais/deck analysis: `server/doc/RELATORIO_FUNCTIONAL_CARD_TAGS_V1_2026-05-18.md` e
  `server/doc/RELATORIO_FUNCTIONAL_CARD_TAGS_MASS_AUDIT_2026-05-18.md`.

## Scanner

Scanner/camera/OCR seguem fora do escopo da rodada interna atual. Nao use
documentos antigos de scanner como gate de release non-scanner.

## Como tratar documentos historicos

- Arquivos de marco/abril no root de `docs/` sao historicos, nao prioridade
  atual; documentos sem referencia ativa foram movidos para
  `docs/archive/2026-03/`.
- Proof folders com logs/prints devem ser preservados quando sustentam uma
  decisao ja tomada.
- Corpus, scorecards, summaries e readiness JSON de Commander Reference devem
  permanecer versionados enquanto forem usados para readiness/promocao.
- Artefatos com payload sensivel devem ser redigidos ou removidos; nao versionar
  JWT, tokens, `SENTRY_DSN`, `DATABASE_URL`, `OPENAI_API_KEY`, e-mails reais,
  decklists completas ou headers de Authorization.
- Ao criar nova decisao app-facing, atualize primeiro `server/manual-de-instrucao.md`
  e `server/doc/API_CONTRACTS_AND_DATA_MAP.md` quando houver contrato envolvido.
