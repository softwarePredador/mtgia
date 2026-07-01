# ManaLoom Pending Backlog

Data: 2026-07-01
Escopo: app, backend publico, release, monetizacao e pendencias de produto
necessarias para lancamento.

Escopo atual desta continuidade: ajustar readiness funcional do app/backend sem
configurar signing/AAB/APK, sem iOS e sem billing server-side por enquanto.

## Estado executivo

| Frente | Status atual | Decisao |
|---|---|---|
| QA interna do app | `GO_WITH_RELEASE_BLOCKERS` | Pode seguir com testers controlados |
| QA interna com backend publico | `CLOSED_DEVICE_LIVE_SCOPE` | Aceites Android live passaram; Sentry staging fechado |
| Release publico gratuito | `DEFERRED_SIGNING_SCOPE` | Signing/AAB/APK fora do corte atual |
| Release publico pago | `DEFERRED_BILLING_SCOPE` | Billing/quota server-side fora do corte atual |
| Backlog XMage/card-rule | `ONGOING_NOT_RELEASE_BLOCKER` | Tratar em trilha separada, sem misturar com release app |

## Ordem de execucao

1. Fechar reprise do aceite Android live apos correcoes locais. `DONE`
2. Fechar backend/app para `recommendation_context` dentro do contrato atual. `DONE`
3. Registrar cleanup de residuos QA sem executar write destrutivo sem aprovacao
   explicita.
4. Atualizar docs/checks e commitar o pacote funcional atual.
5. Retomar signing Android/AAB/APK, iOS e billing server-side em goal separado.

## P0 - Bloqueia release publico

| ID | Pendencia | Status | Bloqueio | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|---|
| P0-01 | Repetir aceite Android fisico apos correcoes locais | `CLOSED_LIVE_DEVICE` | Nenhum no escopo atual | Manter logs em `/tmp/manaloom_runtime_m2006_acceptance.log` e `/tmp/manaloom_generate_async_acceptance.log` ate o proximo ciclo | `deck_runtime_m2006_test.dart`: PASS em 1m45; `POST /ai/optimize` 200 em 11.008s; `deck_generate_async_runtime_test.dart`: PASS em 1m22; generate async aceito em 636ms, concluido em 15.622s, optimize retornou outcome seguro rebuild |
| P0-02 | Sentry mobile com ingestao real | `CLOSED_DEVICE_STAGING` | Nenhum para staging/device | Manter DSN validado fora do git e reutilizar quando signing voltar ao escopo | `SENTRY_MOBILE_EVENT_ID=6f2080bf844d471588c1cc3dc852fc83`; `SENTRY_RELEASE_SMOKE_RESULT=captured` |
| P0-03 | Limpar decks residuais de QA | `PENDING_EXPLICIT_DATA_WRITE_APPROVAL` | Requer delete/admin write em backend/PostgreSQL | Nao remover automaticamente; pedir aprovacao explicita antes de qualquer delete | `GET /decks` ou consulta admin confirma ausencia |

## P0 pago - Bloqueia oferta comercial

| ID | Pendencia | Status | Bloqueio | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|---|
| C0-01 | Billing real | `DEFERRED_BY_CURRENT_SCOPE` | Checkout atual ativa Pro localmente | Retomar em goal de monetizacao | Compra real/sandbox gera assinatura verificavel no backend |
| C0-02 | Plano/quota server-side | `DEFERRED_BY_CURRENT_SCOPE` | `CommercialProvider` usa `SharedPreferences` | Retomar em goal de monetizacao | Limite aplicado pelo servidor em generate/optimize/explain |
| C0-03 | Webhook/cancelamento/reembolso | `DEFERRED_BY_CURRENT_SCOPE` | Depende do provedor de pagamento | Retomar em goal de monetizacao | Teste de webhook atualiza conta e app reflete estado |
| C0-04 | Revisao legal/IP | `REVIEW_REQUIRED_DEFERRED` | Textos atuais sao draft operacional | Retomar antes de qualquer oferta publica paga | Documento legal aprovado para uso publico |

## P1 - Diferencial e confianca do produto

| ID | Pendencia | Status | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|
| P1-01 | Backend honrar `recommendation_context` | `CLOSED_CONTRACT_ACK` | Parser/cache/diagnostics implementados; colecao/preco real ficam em P1-02/P1-03 | Testes backend provam parser, cache scope e diagnostics do contexto |
| P1-02 | Otimizacao por colecao real | `UI_READY_BACKEND_PENDING` | Cruzar binder/colecao do usuario com candidatos de upgrade | Sugestoes respeitam `prefer_collection=true` |
| P1-03 | Otimizacao por orcamento/preco real | `UI_READY_BACKEND_PENDING` | Usar fonte de preco confiavel e limite `budget_limit_brl` | Sugestoes ficam dentro do budget e exibem fonte/estimativa |
| P1-04 | Explicacao completa de trocas | `UI_IF_PAYLOAD` | Backend enviar funcao, risco, curva, preco e bracket por troca | Preview mostra explicacao estruturada em sugestoes reais |
| P1-05 | Teste visual autenticado | `PENDING_CREDENTIALS_RUN` | Exige `MANALOOM_VISUAL_EMAIL` e `MANALOOM_VISUAL_PASSWORD` | `app_existing_user_visual_audit_test.dart` passa em device/emulador |
| P1-06 | Smoke real de IA controlado | `CLOSED_WITH_QA_RESIDUE_PENDING_CLEANUP` | Gera custo/decks reais | Nao apagar residuos sem aprovacao explicita | Logs mostram request, outcome seguro; cleanup fica em P0-03 |

## P1 - Retencao

| ID | Pendencia | Status | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|
| R1-01 | Sincronizar pos-jogo no servidor | `LOCAL_ONLY` | Criar API/modelo para notas pos-jogo por conta/deck | Nota criada em um device aparece em outro login |
| R1-02 | Timeline de versoes do deck | `PARTIAL_MVP` | Persistir snapshots/mudancas aplicadas e motivo | Tela mostra historico antes/depois por deck |
| R1-03 | Alertas de preco/cartas faltantes/trade | `NOT_IMPLEMENTED` | Criar job/agendador e preferencias de notificacao | Usuario recebe alerta opt-in com acao util |
| R1-04 | Push notification em build atual | `PARTIAL_REVALIDATE` | Revalidar config atual ou declarar fora do corte | Smoke/registro de token ou decisao formal de exclusao |

## P1 - Comunidade e crescimento

| ID | Pendencia | Status | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|
| G1-01 | Match real entre usuarios para trade | `PARTIAL_MVP` | Endpoint cruzando want list com ficharios publicos opt-in | Tela lista usuarios/cartas compativeis |
| G1-02 | Comentarios/feedback em decks | `NOT_IMPLEMENTED` | Criar API/UI com moderacao, denuncia e privacidade | Usuario comenta, dono ve, moderacao funciona |
| G1-03 | Deep link/share com preview publico | `PARTIAL_MVP` | Criar URLs publicas de deck/relatorio antes-depois | Link abre preview consistente fora do app |
| G1-04 | Privacidade opt-in de binder/trade | `NEEDS_POLICY_REVIEW` | Revisar defaults e controles por usuario | Teste prova que dados privados nao aparecem publicamente |

## P2 - Qualidade, UX e operacao

| ID | Pendencia | Status | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|
| Q2-01 | Scanner/OCR | `DEFERRED_HIDDEN_BY_DEFAULT` | Manter fora do marketing ou rodar prova fisica completa | Scanner passa em device real antes de divulgar |
| Q2-02 | Auditoria visual renderizada | `STATIC_CLEAN_RENDER_DEPENDENT` | Rodar screenshots/visual audit em device com dados reais | Nenhum P0/P1 visual em screenshots atuais |
| Q2-03 | Contraste/overflow em dados reais | `MONITOR` | Validar telas densas com textos longos e escala de fonte | Screenshots sem overflow relevante |
| Q2-04 | Worktree hygiene | `DIRTY_OUT_OF_SCOPE` | Ha alteracoes paralelas em `.metadata`, `SceneDelegate.swift` e scripts Hermes/XMage/PG321; nao misturar neste pacote | Release branch/stage sem alteracoes fora de escopo |
| Q2-05 | Public deploy freshness | `VERIFY_BEFORE_RELEASE` | Conferir `/health` e SHA publico antes de aceite final | Backend publico roda commit esperado |
| Q2-06 | Migration status | `VERIFY_BEFORE_DATA_CHANGES` | Rodar status de migracoes se backend/data mudar | Todas migracoes aplicadas, sem drift |

## Trilhas separadas, nao bloqueadoras do app release

| Trilha | Status | Regra |
|---|---|---|
| XMage/card-rule adapters | Em andamento | Nao promover regra executavel sem runtime adapter, teste focado e pacote PostgreSQL aprovado |
| Battle/Lorehold deck quality | Em andamento | Nao tratar estrutura forte como deck ideal sem gate de batalha e decision traces |
| Hermes/SQLite reports | Apoio/auditoria | Nao sobrescrever verdade do backend/PostgreSQL com cache Hermes |

## Checklist de fechamento do goal

O goal pode ser marcado completo quando:

1. P0-01 a P0-03 do escopo atual estiverem fechados ou explicitamente
   documentados.
2. Signing/AAB/APK, iOS e billing server-side estiverem registrados como fora
   do escopo atual.
3. As pendencias P1 escolhidas para o primeiro corte tiverem dono, teste e status.
4. O aceite final do escopo atual rodar contra o backend publico esperado.
5. O documento de release final for atualizado com comandos, logs e resultado.

## Evidencia live adicionada nesta continuidade

```sh
flutter test integration_test/deck_runtime_m2006_test.dart -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=RUNTIME_OPTIMIZE_INTENSITY_LABEL=Focado \
  --no-version-check --reporter expanded

flutter test integration_test/deck_generate_async_runtime_test.dart -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --no-version-check --reporter expanded
```

Resultados:

- M2006 live: PASS em 1m45; import commander 200; import sem commander 200;
  `POST /ai/optimize` 200 em 11.008s; preview e aplicacao parcial validados em
  `10_complete_validated`.
- Generate async live: PASS em 1m22; feedback inicial 666ms; `POST
  /ai/generate` 202 em 636ms; job concluido em 15.622s; deck salvo; detalhe
  aberto; optimize retornou 422 com outcome seguro `rebuild_guided_available`.
