# Documentacao ativa do ManaLoom

Este diretorio agora serve como indice curto. Relatorios antigos continuam no
repositorio como historico/prova, mas nao devem guiar implementacao sem checar
as fontes canônicas abaixo.

## Fontes canônicas atuais

1. `server/manual-de-instrucao.md`
   - diario operacional e ultimas decisoes aplicadas.
2. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
   - contratos app/backend, rotas, shapes e campos opcionais.
3. `app/doc/APP_AUDIT_2026-04-29.md`
   - status consolidado do app mobile, riscos e validacoes recentes.
4. `app/doc/UI_TEST_SURFACE_MAP.md`
   - keys e superficies que testes runtime devem usar.
5. `docs/qa/MANALOOM_INTERNAL_TEST_CHECKLIST_2026-05-15.md`
   - checklist para rodada interna non-scanner.
6. `server/doc/INTERNAL_TEST_ROUND_READY_2026-05-15.md`
   - status de distribuicao interna com riscos aceitos.
7. `app/doc/runtime_flow_handoffs/README.md`
   - indice de runtime/handoffs e regra de evidencia fresca.
8. `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`
   - matriz de retencao KEEP/ACTIVE, KEEP/HISTORICAL, ARCHIVE e
     DELETE_CANDIDATE para docs e artefatos versionados.

## Relatorios recentes por tema

- Commander Reference: `server/doc/COMMANDER_REFERENCE_SPRINT3_TRACKER_2026-05-13.md`
- Commander Reference Sprint 4: `server/doc/COMMANDER_REFERENCE_SPRINT4_EXECUTION_PLAN_2026-05-14.md`
- Push/FCM: `app/doc/runtime_flow_handoffs/push_delivery_android_sm_a135m_2026-05-11.md`
- Card entry/import: `docs/qa/manaloom_card_entry_qa_2026-05-08.md`
- Design Android: `docs/qa/manaloom_android_design_audit_sm_a135m_2026-05-07.md`
- Icone do app: `docs/qa/manaloom_app_icon_contact_sheet_2026-05-15.png`
- Auditoria de docs/artefatos: `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`

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
