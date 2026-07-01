# ManaLoom Goal Tracker - Etapas 1, 2 e 3

Data de abertura: 2026-07-01
Goal: concluir as Etapas 1, 2 e 3 do plano de produto do ManaLoom com evidencia objetiva e registrada.

## Status executivo

| Etapa | Nome | Status | Resultado esperado |
|---|---|---|---|
| 1 | Diagnostico final do estado atual | Concluida | Produto mapeado por funcionalidade, disponibilidade, atratividade, riscos e lacunas |
| 2 | Fechar o core para lancamento | Concluida com bloqueios | Core local/offline validado; build Android compilado; E2E publico com escrita e smoke instalado pendentes |
| 3 | Confiabilidade tecnica e observabilidade | Em andamento | App/backend rastreaveis em falhas reais, com release smoke instalado e evidencias operacionais |

## Etapa 1 - Diagnostico final do estado atual

Status: `CONCLUIDA`

Documento de saida:

- `docs/qa/MANALOOM_PRODUCT_DIAGNOSTIC_STAGE1_2026-07-01.md`

Evidencias ja registradas:

- Backend publico respondeu `GET /health`, `GET /ready` e `GET /cards?limit=1` com HTTP 200.
- `/ready` preservou `x-request-id` manual.
- Banco publico reportou `cards_data.card_count=34331`.
- `flutter analyze` passou sem issues.
- Testes focados do app passaram: 76 casos.
- Testes focados do backend passaram: 40 casos.
- Matriz de status por modulo foi consolidada.
- Comparativo externo e riscos comerciais foram registrados.

Resultado:

- Produto interno/testadores: `GO WITH RISKS`.
- Produto publico/comercial: `NO-GO` ate fechar Etapas 2 e 3, monetizacao, release e compliance.

## Etapa 2 - Fechar o core para lancamento

Status: `CONCLUIDA_COM_BLOQUEIOS`

Documento de saida:

- `docs/qa/MANALOOM_STAGE2_CORE_RELEASE_READINESS_2026-07-01.md`

Objetivo:

Validar que um usuario consegue concluir o fluxo principal sem perda de contexto:

`usuario novo -> onboarding -> gerar/importar deck -> abrir detalhes -> analisar -> otimizar -> aplicar -> validar -> exportar/compartilhar`

### Criterios de pronto

| Criterio | Status | Evidencia exigida |
|---|---|---|
| Onboarding em sessao limpa preserva formato escolhido | PASS_LOCAL | Teste/smoke com sessao limpa e registro do formato chegando em generate/import |
| Gerar deck via IA funciona contra backend publico | BLOCKED_BY_APPROVAL | Runtime smoke com usuario real/teste, job async concluido e deck salvo |
| Importar deck funciona contra backend publico | BLOCKED_BY_APPROVAL | Lista importada, commander preservado quando aplicavel, deck salvo |
| Deck details carrega estados de loading/erro/vazio/sucesso | PASS_LOCAL | Smoke de tela ou evidencia visual/logica atual |
| Analise mostra legalidade, curva, funcoes e amostras | PASS_CONTRACT | Deck analisado com payload e UI conferidos |
| Optimize focado retorna preview aplicavel | PASS_LOCAL | Sugestoes retornadas, preview exibido, selecao/apply executado |
| Apply salva e valida o deck final | PASS_LOCAL | `PUT`/bulk concluido e `validate` final registrado |
| Export/share/copy funciona no deck validado | PARTIAL | Acao executada sem erro em build alvo |
| Falha de IA tem UX segura | PASS_LOCAL | Caso `needs_repair`, no-op ou erro amigavel documentado |
| Fluxo completo passa em build real | PARTIAL_BUILD_ARTIFACT | Android APK debug/release e AAB release compilados com `API_BASE_URL` publico; falta instalar/executar |

### Subtarefas operacionais

1. Rodar smoke automatizado/local do core existente.
2. Identificar se ja existe integration test cobrindo onboarding -> generate/import -> details -> optimize -> validate.
3. Rodar ou criar smoke faltante, sem ampliar escopo visual.
4. Registrar logs, comandos e saida em documento de QA da Etapa 2.
5. Classificar bloqueios como `produto`, `backend`, `toolchain`, `dados`, `credencial` ou `UX`.

### Nao faz parte desta etapa

- Melhorar community, binder, trade ou scanner alem do necessario para nao quebrar o core.
- Implementar monetizacao completa.
- Refatorar arquivos grandes sem relacao direta com o fluxo principal.

## Etapa 3 - Confiabilidade tecnica e observabilidade

Status: `EM ANDAMENTO`

Objetivo:

Garantir que o produto seja operavel com usuarios reais: quando algo falhar, deve ser possivel saber qual tela, qual request, qual usuario/test user, qual backend response e qual evento de erro.

### Criterios de pronto

| Criterio | Status | Evidencia exigida |
|---|---|---|
| Backend health/ready publico estavel | Parcial | Ja validado na Etapa 1; repetir no fechamento |
| `x-request-id` manual preservado no backend | Parcial | Ja validado em `/ready`; falta app -> backend ponta a ponta |
| `x-request-id` do app aparece em response/log/breadcrumb | Parcial | Testes unitarios cobrem envio/eco/erro; falta smoke app real com request rastreavel |
| Sentry backend com ingestao real confirmada | Parcial | Documentado historicamente; confirmar se necessario |
| Sentry mobile com ingestao real confirmada | Pendente | Evento real vindo do app/build alvo |
| Release/internal build smoke com API publica | Parcial | APK debug, APK release e AAB release compilados; falta instalar/executar fluxo core minimo |
| Rate limit/paywall de IA nao quebra UX | Pendente | Validar resposta `402`/headers/plano ou registrar como fora do release |
| Logs nao expõem segredo/token | Pendente | Secret/log scan no escopo de release |
| Scanner tem decisao explicita | Concluido | Fora do release por default via `ENABLE_SCANNER_RELEASE=false`; falta sprint fisica para reativar |
| Push notification tem status explicito | Pendente | Revalidar build atual ou marcar fora do release publico |

### Subtarefas operacionais

1. Rodar probes publicos `health`, `ready`, `cards` e request-id.
2. Verificar configuracao app de Sentry e breadcrumbs de deck/AI.
3. Rodar smoke mobile ou simulator com backend publico.
4. Produzir evento Sentry mobile controlado, se houver DSN/config local segura.
5. Confirmar headers/logs de `x-request-id` no fluxo do app.
6. Revisar checklist go-live e atualizar status real.
7. Registrar saidas em documento de QA da Etapa 3.

### Nao faz parte desta etapa

- Criar billing completo.
- Fazer campanha de lancamento.
- Prometer scanner, push ou app store sem prova real.

## Dependencias e bloqueios conhecidos

| Item | Tipo | Impacto |
|---|---|---|
| Worktree ja estava suja antes deste tracker | Operacional | Evitar reverter ou misturar mudancas preexistentes |
| Scanner/OCR deferred | Produto | Deve ficar fora do marketing ate prova fisica |
| Sentry mobile pendente | Observabilidade | Bloqueia release publico confiavel |
| Release build smoke instalado pendente | Release | Artefatos Android compilam, mas falta instalar/executar e usar keystore real |
| Monetizacao incompleta | Comercial | Nao bloqueia teste interno, bloqueia produto pago |
| Fan Content Policy / IP | Legal | Precisa revisao antes de assinatura paga |

## Proximas acoes imediatas

1. Criar/atualizar `docs/qa/MANALOOM_STAGE3_OBSERVABILITY_READINESS_2026-07-01.md`.
2. Rodar secret/log scan no escopo de release.
3. Instalar APK debug ou release interno em device/simulator e executar fluxo core minimo com API publica/staging.
4. Confirmar evento Sentry mobile real ou registrar bloqueio de DSN/credencial.
5. Preparar keystore Android real antes de qualquer AAB de distribuicao.

## Regra de conclusao do goal

O goal so pode ser marcado como completo quando:

1. Etapa 1 estiver documentada e concluida.
2. Etapa 2 tiver documento de fechamento com evidencias ou bloqueios objetivos.
3. Etapa 3 tiver documento de fechamento com evidencias ou bloqueios objetivos.
4. Os bloqueios remanescentes estiverem classificados com proxima acao clara.
