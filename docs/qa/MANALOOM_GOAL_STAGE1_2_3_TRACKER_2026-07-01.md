# ManaLoom Goal Tracker - Produto E Release

Data de abertura: 2026-07-01
Goal: organizar o plano de produto e release do ManaLoom com evidencia objetiva e criterios claros.

## Status executivo

| Trilha | Etapa | Nome | Status | Resultado esperado |
|---|---|---|---|
| Produto | 1 | Diagnostico final do estado atual | Concluida | Produto mapeado por funcionalidade, disponibilidade, atratividade, riscos e lacunas |
| Produto | 2 | Fechar o core para lancamento | Concluida para teste interno | Core local/offline, smokes publicos controlados, smoke mobile Android e APK release instalado/aberto |
| Produto | 3 | Confiabilidade tecnica e observabilidade | Concluida para teste interno com bloqueios de release publico | Firebase Performance e device smoke validados; Sentry DSN, signing Android/iOS e aceite final seguem pendentes |
| Produto comercial | 4 | Produto Comercial e Monetizacao | MVP_IMPLEMENTADO_AUDITADO | Free/Pro, medidor de IA, limites, paywall, upgrade, checkout interno e textos legais |
| Produto comercial | 5 | Diferencial Principal | MVP_IMPLEMENTADO_AUDITADO_COM_LACUNA_BACKEND | Otimizacao por colecao/orcamento, explicacao de trocas e relatorio antes/depois compartilhavel |
| Produto comercial | 6 | Retencao e Uso Continuo | MVP_IMPLEMENTADO_AUDITADO_LOCAL | Historico local de partidas, notas pos-jogo, evolucao do deck e sugestoes automaticas |
| Produto comercial | 7 | Comunidade, Trade e Crescimento | MVP_IMPLEMENTADO_AUDITADO_PARCIAL | Decks publicos existentes, perfil, seguir, binder publico, trade match MVP e compartilhamento |
| Release tecnico | R4 | Observabilidade/Sentry | Concluida com bloqueio de credencial | Sentry integrado por codigo; DSN ausente bloqueia ingestao real |
| Release tecnico | R5 | Signing e distribuicao | Concluida com bloqueio de credencial | Android/iOS compilam; Android usa debug fallback e iOS esta sem codesign |
| Release tecnico | R6 | Aceite final em build | Concluida com blockers de UX | Android release instala/abre; aceite completo revelou blockers de import modal e optimize quality gate |

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

Status: `CONCLUIDA_PARA_TESTE_INTERNO`

Documento de saida:

- `docs/qa/MANALOOM_STAGE2_CORE_RELEASE_READINESS_2026-07-01.md`

Objetivo:

Validar que um usuario consegue concluir o fluxo principal sem perda de contexto:

`usuario novo -> onboarding -> gerar/importar deck -> abrir detalhes -> analisar -> otimizar -> aplicar -> validar -> exportar/compartilhar`

### Criterios de pronto

| Criterio | Status | Evidencia exigida |
|---|---|---|
| Onboarding em sessao limpa preserva formato escolhido | PASS_LOCAL | Teste/smoke com sessao limpa e registro do formato chegando em generate/import |
| Gerar deck via IA funciona contra backend publico | PASS_PUBLIC_CONTROLLED | `core_flow_smoke_test.dart` passou contra API publica |
| Importar deck funciona contra backend publico | PASS_PUBLIC_DEVICE | `import_to_deck_flow_test.dart` e `localized_import_runtime_test.dart` passaram |
| Deck details carrega estados de loading/erro/vazio/sucesso | PASS_LOCAL | Smoke de tela ou evidencia visual/logica atual |
| Analise mostra legalidade, curva, funcoes e amostras | PASS_CONTRACT | Deck analisado com payload e UI conferidos |
| Optimize focado retorna preview aplicavel | PASS_LOCAL | Sugestoes retornadas, preview exibido, selecao/apply executado |
| Apply salva e valida o deck final | PASS_LOCAL | `PUT`/bulk concluido e `validate` final registrado |
| Export/share/copy funciona no deck validado | PASS_CONTRACT | `deck_pricing_export_community_contract_test.dart` passou; share nativo ainda precisa aceite final |
| Falha de IA tem UX segura | PASS_LOCAL | Caso `needs_repair`, no-op ou erro amigavel documentado |
| Fluxo completo passa em build real | PARTIAL_DEVICE | APK release instalado/aberto e import mobile validado; falta aceite final em build assinado |

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

Status: `CONCLUIDA_PARA_TESTE_INTERNO_COM_BLOQUEIOS_RELEASE_PUBLICO`

Documento de saida:

- `docs/qa/MANALOOM_STAGE3_OBSERVABILITY_READINESS_2026-07-01.md`

Objetivo:

Garantir que o produto seja operavel com usuarios reais: quando algo falhar, deve ser possivel saber qual tela, qual request, qual usuario/test user, qual backend response e qual evento de erro.

### Criterios de pronto

| Criterio | Status | Evidencia exigida |
|---|---|---|
| Backend health/ready publico estavel | PASS | Ja validado na Etapa 1; repetido no fechamento |
| `x-request-id` manual preservado no backend | PASS | `/ready` preservou `stage3-observability-ready-20260701` |
| `x-request-id` do app aparece em response/log/breadcrumb | PASS_LOCAL_DEVICE_EVIDENCE | Testes unitarios cobrem envio/eco/erro e smoke mobile emitiu request-id/breadcrumb |
| Sentry backend com ingestao real confirmada | PASS_CODE_HISTORICAL | Documentado historicamente; nao reexecutado nesta etapa |
| Sentry mobile com ingestao real confirmada | BLOCKED_BY_DSN | Smoke Android retornou `not_configured`; exige DSN segura |
| Firebase Performance mobile | PASS_DEVICE | Smoke Android retornou `initialized` e `collection_enabled=true` |
| Release/internal build smoke com API publica | PASS_INTERNAL_UNSIGNED | APK release instalado/aberto em `R58T300SREH`; falta assinatura de distribuicao |
| Rate limit/paywall de IA nao quebra UX | NOT_STAGE3_CORE | Validar resposta `402`/headers/plano ou registrar como fora do release |
| Logs nao expõem segredo/token | PASS_LOCAL_WITH_REVIEW | Testes de sanitizacao passaram; scan heuristico listou caminhos para revisao |
| Scanner tem decisao explicita | PASS_SCOPE | Fora do release por default via `ENABLE_SCANNER_RELEASE=false`; falta sprint fisica para reativar |
| Push notification tem status explicito | PARTIAL | Codigo/config existem; revalidar build atual ou marcar fora do release publico |

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

## Etapas 4 a 7 - Produto comercial

Status: `MVP_IMPLEMENTADO`

Documento de saida:

- `docs/qa/MANALOOM_PRODUCT_ROADMAP_STAGES_4_7_2026-07-01.md`
- `docs/qa/MANALOOM_STAGE4_7_MVP_IMPLEMENTATION_AUDIT_2026-07-01.md`

### Etapa 4 - Produto Comercial e Monetizacao

Objetivo:

- Transformar recurso em oferta vendavel.

Implementar/definir:

- Tela Free/Pro.
- Medidor de uso de IA.
- Limites claros por plano.
- Paywall quando limite acabar.
- Pagina de upgrade.
- Checkout ou integracao de pagamento.
- Politica legal/IP para monetizacao.
- Termos, privacidade e disclaimer.

Criterio de pronto:

- O usuario entende o que e gratis, por que pagaria e como fazer upgrade.

Resultado 2026-07-01:

- Rotas `/plans`, `/upgrade`, `/checkout` e `/legal` adicionadas.
- `CommercialProvider` persiste plano e uso mensal de IA localmente.
- Medidor de uso de IA aparece no gerador e no perfil.
- Paywall bloqueia geracao, otimizacao e explicacao de carta quando o limite
  Free acaba.
- Checkout interno ativa Pro localmente para validacao de produto.
- Termos, privacidade, IP, disclaimer de IA e nota de monetizacao adicionados.

Limite:

- Checkout ainda nao cobra de verdade; producao exige integracao de pagamento e
  persistencia server-side do plano.

### Etapa 5 - Diferencial Principal

Objetivo:

- Sair de "mais um deck builder com IA".

Prioridades:

- Otimizacao por colecao.
- Otimizacao por orcamento.
- Explicacao de cada troca: funcao, risco, curva, preco e bracket.
- Relatorio antes/depois compartilhavel.
- Sugestoes por Commander Bracket/nivel da mesa.
- Rebuild guiado por intencao: casual, upgraded, optimized e cEDH.

Criterio de pronto:

- O usuario confia na recomendacao porque entende o motivo.

Resultado 2026-07-01:

- Sheet de otimizacao agora tem criterios de colecao, orcamento em R$,
  bracket e intencao `casual/upgraded/optimized/cEDH`.
- Payload `/ai/optimize` recebe `recommendation_context`.
- Preview mostra metadados de funcao, risco, curva, preco e bracket quando
  disponiveis.
- Relatorio antes/depois ganhou acao de compartilhamento externo.

Limite:

- Backend precisa honrar os novos criterios com dados reais de colecao/preco
  para o diferencial ser completo em producao.

### Etapa 6 - Retencao e Uso Continuo

Objetivo:

- Fazer o usuario voltar toda semana.

Ciclos a criar:

- Historico de partidas.
- Notas pos-jogo.
- Cartas que performaram bem/mal.
- Problemas de mana, compra, remocao ou win condition.
- Sugestao automatica depois da partida.
- Evolucao do deck ao longo do tempo.
- Alertas de melhoria, preco e cartas faltantes.

Criterio de pronto:

- O ManaLoom deixa de ser usado so para montar deck e passa a acompanhar a vida do deck.

Resultado 2026-07-01:

- Rota `/decks/:id/post-game` adicionada.
- Registro local por deck salva resultado, nivel da mesa, notas, problemas
  recorrentes, cartas boas e cartas ruins.
- Resumo de evolucao mostra padroes, top performers, cartas para revisar e
  sugestoes automaticas.

Limite:

- Historico ainda e local; sincronizacao, timeline server-side e alertas
  automaticos ficam para proxima iteracao.

### Etapa 7 - Comunidade, Trade e Crescimento

Objetivo:

- Transformar usuarios em rede.

Fortalecer:

- Decks publicos com analise visual.
- Perfil de jogador.
- Seguir jogadores.
- Comentarios ou feedback em decks.
- Binder publico.
- Lista de cartas para troca.
- Match entre cartas faltantes e usuarios que tem para trade.
- Compartilhamento externo do deck/analise.

Criterio de pronto:

- Usuarios descobrem decks, seguem jogadores, recebem feedback, encontram cartas para troca e compartilham analises fora do app.

Resultado 2026-07-01:

- Comunidade recebeu painel de rede/trade com acoes para fichario, want list,
  trades e busca de jogadores.
- `TradeMatchSummary` resume wishlist, faltantes, cartas para troca e
  duplicadas a partir de `BinderStats`.
- Relatorio de otimizacao agora pode ser compartilhado.
- Fluxos existentes de decks publicos, perfis, follow, binder publico e trades
  foram preservados.

Limite:

- Comentarios/moderacao e match real entre usuarios especificos ainda nao fazem
  parte deste MVP.

### Evidencia de validacao das etapas 4 a 7

- `flutter test test/features/commercial/commercial_provider_test.dart test/features/retention/post_game_note_store_test.dart test/features/growth/trade_match_summary_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart`
- `flutter analyze`

## Release tecnico R4 - Observabilidade/Sentry

Status: `CONCLUIDA_COM_BLOQUEIO_DE_CREDENCIAL`

Documento de saida:

- `docs/qa/MANALOOM_REMAINING_RELEASE_STAGES_GOAL_2026-07-01.md`

Resultado:

- Sentry mobile/backend esta integrado por codigo.
- Ambiente atual nao possui `SENTRY_DSN`, `SENTRY_MOBILE_DSN` ou `SENTRY_AUTH_TOKEN`.
- Smoke Android confirmou Firebase Performance ativo e Sentry `not_configured`.

Proxima acao:

- Injetar DSN segura por `--dart-define=SENTRY_DSN=...` e repetir `release_observability_smoke_test.dart`.

## Release tecnico R5 - Signing e distribuicao

Status: `CONCLUIDA_COM_BLOQUEIO_DE_CREDENCIAL`

Documento de saida:

- `docs/qa/MANALOOM_REMAINING_RELEASE_STAGES_GOAL_2026-07-01.md`

Resultado:

- Android: `build.gradle.kts` ja suporta keystore real via `key.properties`.
- Android: `key.properties`, `*.jks` e `*.keystore` estao ignorados no git.
- Android: APK/AAB release existem, mas o APK atual esta assinado como `C=US, O=Android, CN=Android Debug`.
- iOS: `flutter build ios --release --no-codesign` passou e gerou `build/ios/iphoneos/Runner.app`.
- iOS: `Runner.app` nao esta assinado.

Proxima acao:

- Criar `app/android/key.properties` com keystore real fora do git.
- Configurar Apple Team/provisioning para `com.mtgia.mtgApp`.

## Release tecnico R6 - Aceite final em build

Status: `CONCLUIDA_COM_BLOCKERS_DE_UX_ACEITE`

Documento de saida:

- `docs/qa/MANALOOM_REMAINING_RELEASE_STAGES_GOAL_2026-07-01.md`

Resultado positivo:

- APK release reinstalado e aberto no Android fisico `R58T300SREH`.
- `pidof com.mtgia.mtg_app` retornou `25211`.
- Smoke de importacao localizada mobile passou.

Blockers descobertos:

- `ACCEPTANCE_BLOCKER_IMPORT_MODAL_CLOSE`: segunda importacao `replace_all` retornou `POST /import/to-deck -> 200`, mas o modal `Importar Lista` nao fechou no timeout do aceite.
- `ACCEPTANCE_BLOCKER_OPTIMIZE_NEEDS_REPAIR_UX`: generate async salvou deck e abriu details, mas optimize retornou `422 OPTIMIZE_NEEDS_REPAIR` e o harness ficou preso em vez de concluir com rebuild guided/outcome seguro.

Decks de QA possivelmente residuais:

- `9b263ee1-f8ce-46e3-b1d0-b6cc4bf4a598`
- `4b5f542c-a546-4e10-a08a-eed5704140e3`

Proxima acao:

- Corrigir os dois blockers de UX/harness, limpar decks residuais com token/admin apropriado e repetir aceite Android completo.

## Dependencias e bloqueios conhecidos

| Item | Tipo | Impacto |
|---|---|---|
| Worktree ja estava suja antes deste tracker | Operacional | Evitar reverter ou misturar mudancas preexistentes |
| Scanner/OCR deferred | Produto | Deve ficar fora do marketing ate prova fisica |
| Sentry mobile sem DSN | Observabilidade | Bloqueia release publico confiavel ate configurar e confirmar ingestao |
| Keystore Android ausente | Release | Artefatos Android compilam/instalam, mas assinatura atual e Android Debug |
| iOS sem provisioning/signing | Release | Build iOS sem codesign passou, mas nao e distribuivel |
| Import modal nao fecha no aceite | UX | Bloqueia aceite completo do fluxo de importacao em build |
| Optimize quality gate prende harness | UX | Bloqueia aceite completo do fluxo generate -> optimize |
| Monetizacao incompleta | Comercial | Nao bloqueia teste interno, bloqueia produto pago |
| Fan Content Policy / IP | Legal | Precisa revisao antes de assinatura paga |

## Proximas acoes imediatas

1. Especificar e implementar Etapa 4 comercial: Free/Pro, medidor de IA, limites, paywall, upgrade e textos legais.
2. Especificar e implementar Etapa 5: otimizacao por colecao/orcamento, explicacao de trocas e relatorio antes/depois.
3. Especificar e implementar Etapa 6: historico de partidas, notas pos-jogo, evolucao do deck e alertas.
4. Especificar e implementar Etapa 7: deck publico, perfil, seguir, comentarios, binder publico, trade match e compartilhamento.
5. Corrigir `ACCEPTANCE_BLOCKER_IMPORT_MODAL_CLOSE`.
6. Corrigir `ACCEPTANCE_BLOCKER_OPTIMIZE_NEEDS_REPAIR_UX`.
7. Limpar decks residuais de QA com token/admin apropriado.
8. Repetir aceite Android completo.
9. Injetar `SENTRY_DSN`/`SENTRY_MOBILE_DSN` seguro e repetir smoke de observabilidade.
10. Configurar signing Android/iOS antes de release publico.

## Regra de conclusao do goal

O goal so pode ser marcado como completo quando:

1. Etapa 1 estiver documentada e concluida.
2. Etapa 2 tiver documento de fechamento com evidencias ou bloqueios objetivos.
3. Etapa 3 tiver documento de fechamento com evidencias ou bloqueios objetivos.
4. Etapas comerciais 4, 5, 6 e 7 estiverem inseridas com escopo, criterio de pronto e ordem de execucao.
5. Release tecnico R4, R5 e R6 tiverem documentos de fechamento com evidencias ou bloqueios objetivos.
6. Os bloqueios remanescentes estiverem classificados com proxima acao clara.
