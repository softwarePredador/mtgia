# ManaLoom Pending Backlog

Data: 2026-07-01
Escopo: app, backend publico, release, monetizacao e pendencias de produto
necessarias para lancamento.

## Estado executivo

| Frente | Status atual | Decisao |
|---|---|---|
| QA interna do app | `GO_WITH_RELEASE_BLOCKERS` | Pode seguir com testers controlados |
| Release publico gratuito | `NO-GO` | Falta aceite final, signing e observabilidade |
| Release publico pago | `NO-GO` | Falta billing/quota server-side e revisao legal |
| Backlog XMage/card-rule | `ONGOING_NOT_RELEASE_BLOCKER` | Tratar em trilha separada, sem misturar com release app |

## Ordem de execucao

1. Fechar reprise do aceite Android apos correcoes locais.
2. Propagar o DSN Sentry ja validado para o build assinado.
3. Configurar signing Android e gerar AAB/APK distribuivel.
4. Decidir se iOS entra no primeiro release; se sim, configurar signing/TestFlight.
5. Rodar aceite final em build assinado.
6. Fechar monetizacao real antes de qualquer oferta paga.
7. Fechar diferenciais server-side que sustentam o valor Pro.
8. Evoluir retencao/comunidade depois que o core pago estiver defensavel.

## P0 - Bloqueia release publico

| ID | Pendencia | Status | Bloqueio | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|---|
| P0-01 | Repetir aceite Android fisico apos correcoes locais | `PENDING_RERUN` | Teste live cria usuario/deck e pode consumir IA | Rodar `deck_runtime_m2006_test.dart` e `deck_generate_async_runtime_test.dart` no `R58T300SREH` | Ambos passam ou terminam com outcome seguro documentado |
| P0-02 | Sentry mobile com ingestao real | `CLOSED_DEVICE_STAGING` | Nenhum para staging/device; falta propagar no build assinado | Usar o DSN validado no build de distribuicao | `SENTRY_MOBILE_EVENT_ID=6f2080bf844d471588c1cc3dc852fc83`; `SENTRY_RELEASE_SMOKE_RESULT=captured` |
| P0-03 | Signing Android real | `BLOCKED_BY_SIGNING` | Falta keystore/key.properties fora do git | Criar `app/android/key.properties`, rebuildar APK/AAB release | `apksigner verify --print-certs` mostra certificado real, nao Android Debug |
| P0-04 | Aceite final em build assinado | `WAITING_P0_01_P0_03` | Depende de reteste e signing | Instalar build assinado no Android fisico e repetir fluxo core | Login/import/generate/details/optimize/share sem blocker |
| P0-05 | Decisao iOS do primeiro release | `DECISION_NEEDED` | iOS build existe sem codesign | Se iOS entra no release, configurar Team/provisioning/TestFlight; se nao, registrar fora do corte | Archive/TestFlight aceito ou decisao formal de excluir iOS do primeiro corte |
| P0-06 | Limpar decks residuais de QA | `PENDING_ACCESS` | Precisa token/admin adequado | Remover decks `9b263ee1-f8ce-46e3-b1d0-b6cc4bf4a598` e `4b5f542c-a546-4e10-a08a-eed5704140e3`, se ainda existirem | `GET /decks` ou consulta admin confirma ausencia |

## P0 pago - Bloqueia oferta comercial

| ID | Pendencia | Status | Bloqueio | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|---|
| C0-01 | Billing real | `NOT_IMPLEMENTED` | Checkout atual ativa Pro localmente | Integrar Stripe/Mercado Pago/backend ou decidir beta manual sem cobranca | Compra real/sandbox gera assinatura verificavel no backend |
| C0-02 | Plano/quota server-side | `MVP_LOCAL_ONLY` | `CommercialProvider` usa `SharedPreferences` | Criar modelo backend de plano, uso mensal e enforcement por conta | Limite aplicado pelo servidor em generate/optimize/explain |
| C0-03 | Webhook/cancelamento/reembolso | `NOT_IMPLEMENTED` | Depende do provedor de pagamento | Implementar eventos de assinatura e estados `active/canceled/past_due` | Teste de webhook atualiza conta e app reflete estado |
| C0-04 | Revisao legal/IP | `REVIEW_REQUIRED` | Textos atuais sao draft operacional | Revisar Fan Content Policy, termos, privacidade, disclaimer e monetizacao MTG | Documento legal aprovado para uso publico |

## P1 - Diferencial e confianca do produto

| ID | Pendencia | Status | Proxima acao | Evidencia para fechar |
|---|---|---|---|---|
| P1-01 | Backend honrar `recommendation_context` | `APP_CONTRACT_ONLY` | Aplicar colecao, orcamento, intencao e bracket em `/ai/optimize` | Teste backend prova que o resultado muda conforme contexto |
| P1-02 | Otimizacao por colecao real | `UI_READY_BACKEND_PENDING` | Cruzar binder/colecao do usuario com candidatos de upgrade | Sugestoes respeitam `prefer_collection=true` |
| P1-03 | Otimizacao por orcamento/preco real | `UI_READY_BACKEND_PENDING` | Usar fonte de preco confiavel e limite `budget_limit_brl` | Sugestoes ficam dentro do budget e exibem fonte/estimativa |
| P1-04 | Explicacao completa de trocas | `UI_IF_PAYLOAD` | Backend enviar funcao, risco, curva, preco e bracket por troca | Preview mostra explicacao estruturada em sugestoes reais |
| P1-05 | Teste visual autenticado | `PENDING_CREDENTIALS_RUN` | Exige `MANALOOM_VISUAL_EMAIL` e `MANALOOM_VISUAL_PASSWORD` | `app_existing_user_visual_audit_test.dart` passa em device/emulador |
| P1-06 | Smoke real de IA controlado | `PENDING_COST_MUTATION_DECISION` | Gera custo/decks reais | Rodar generate/optimize live com cleanup garantido | Logs mostram request, outcome seguro e cleanup |

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
| Q2-04 | Worktree hygiene | `DIRTY_OUT_OF_SCOPE` | Decidir destino de `.metadata`, `SceneDelegate.swift` e scripts Hermes/XMage sujos | Release branch/stage sem alteracoes fora de escopo |
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

1. P0-01 a P0-06 estiverem fechados ou formalmente excluidos do primeiro release.
2. Para release pago, C0-01 a C0-04 estiverem fechados.
3. As pendencias P1 escolhidas para o primeiro corte tiverem dono, teste e status.
4. O aceite final rodar em build assinado contra o backend publico esperado.
5. O documento de release final for atualizado com comandos, logs e resultado.
