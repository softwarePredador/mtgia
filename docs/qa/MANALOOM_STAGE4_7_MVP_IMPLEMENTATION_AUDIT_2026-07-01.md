# ManaLoom Stage 4-7 MVP Implementation Audit

Data: 2026-07-01
Status: MVP auditado com correcoes.

Objetivo: revisar se o MVP das Etapas 4 a 7 esta bem instruido,
implementado e funcional, separando o que esta pronto para validacao interna
do que ainda nao prova prontidao comercial completa.

## Veredito executivo

O MVP das Etapas 4 a 7 esta funcional para validacao interna de produto no
device Android fisico contra o backend publico.

Nao esta pronto como monetizacao comercial completa porque checkout, billing e
limites ainda sao locais; o backend agora reconhece o novo
`recommendation_context` para contrato/cache/diagnostico, mas colecao e preco
real ainda nao sao aplicados na escolha das cartas; comentarios/moderacao e
match real entre usuarios seguem pendentes.

## Evidencia executada

Comandos:

```sh
flutter test test/features/commercial/commercial_provider_test.dart test/features/retention/post_game_note_store_test.dart test/features/growth/trade_match_summary_test.dart test/features/decks/providers/deck_recommendation_context_payload_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/profile/profile_screen_test.dart test/features/community/providers/community_provider_test.dart test/features/community/providers/social_provider_test.dart
flutter analyze
git diff --check
```

Resultado:

- Testes focados: PASS, 67 casos.
- `flutter analyze`: PASS, sem issues.
- `git diff --check`: PASS.

## Correcoes feitas durante a auditoria

| Area | Problema encontrado | Correcao |
|---|---|---|
| Comunidade/trade | `CommunityScreen` e `CommunityTradeGrowthPanel` dependiam rigidamente de `BinderProvider`; isso quebraria composicoes/testes sem o provider | `BinderProvider` passou a ser opcional para carregamento de stats e renderizacao do painel |
| Retencao | `PostGameNoteStore.loadNotes` poderia quebrar com JSON local corrompido | Payload corrompido agora retorna lista vazia sem crash |
| Otimizacao | O bloco de diferencial empurrava as opcoes de estrategia para fora do primeiro viewport do bottom sheet, quebrando o smoke | `RecommendationContextSection` foi movida para depois da selecao/configuracao principal |
| Testes | Faltava prova direta de rollover mensal, payload de recomendacao, store corrompido e painel sem provider | Testes adicionados para os quatro cenarios |

## Matriz de requisitos

### Etapa 4 - Produto Comercial e Monetizacao

| Requisito | Status | Evidencia | Observacao |
|---|---|---|---|
| Tela Free/Pro | PASS_MVP | `app/lib/features/commercial/screens/plan_screen.dart`; rota `/plans` | Mostra planos, limites e CTA |
| Medidor de uso de IA | PASS_MVP | `AiUsageMeter`; usado no gerador e perfil | Provider tolera composicao sem `CommercialProvider` |
| Limites claros por plano | PASS_MVP_LOCAL | `CommercialProvider`, `commercial_provider_test.dart` | Free=5/mes, Pro=200/mes local |
| Paywall quando limite acabar | PASS_MVP_LOCAL | `reserveAiActionOrShowPaywall`; testes de limite Free | Bloqueia chamadas de IA quando limite local acaba |
| Pagina de upgrade | PASS_MVP | `upgrade_screen.dart` | Explica valor do Pro |
| Checkout/integracao de pagamento | PARTIAL_MVP | `checkout_screen.dart` | Checkout ativa Pro localmente; nao cobra de verdade |
| Politica legal/IP, termos, privacidade, disclaimer | PASS_DRAFT | `legal_screen.dart` | Texto operacional; exige revisao juridica antes de venda |

Riscos residuais:

- Plano e uso nao sao server-side nem por conta.
- Checkout local nao e integracao real com Stripe/Mercado Pago.
- Consumo de IA e debitado antes da chamada terminar; pode ser injusto se a IA falhar.

### Etapa 5 - Diferencial Principal

| Requisito | Status | Evidencia | Observacao |
|---|---|---|---|
| Otimizacao por colecao | PARTIAL_BACKEND_CONTEXT_ACK | `RecommendationContextSection`, `prefer_collection`; diagnostics `/ai/optimize` | Backend reconhece o pedido, mas ainda nao cruza inventario real |
| Otimizacao por orcamento | PARTIAL_BACKEND_CONTEXT_ACK | Slider `budget_limit_brl`; parser/cache scope backend | Backend separa cache por budget, mas ainda nao filtra preco real |
| Explicacao de troca: funcao, risco, curva, preco, bracket | PASS_UI_IF_PAYLOAD | `deck_optimize_sheet_widgets.dart` | UI exibe campos quando o backend os envia |
| Relatorio antes/depois compartilhavel | PASS_MVP | Botao `Compartilhar relatorio` no preview | Usa `share_plus` |
| Sugestoes por bracket | PASS_EXISTING_PLUS_MVP | `selectedBracket`, payload `/ai/optimize` | Bracket ja era parte do optimize |
| Rebuild guiado por intencao | PARTIAL_BACKEND_CONTEXT_ACK | `rebuild_intent` no `recommendation_context` | Backend reconhece/cacheia por intencao; estrategia fina ainda pendente |

Evidencia adicional:

- O smoke de `DeckDetailsScreen` registrou request de optimize com
  `recommendation_context`.
- Atualizacao posterior: `server/lib/ai/optimize_route_request_support.dart`
  agora parseia `recommendation_context`, separa cache por assinatura do
  contexto e anexa diagnostics/constraints no retorno de `/ai/optimize`.
- Testes: `dart test test/optimize_route_request_support_test.dart
  test/optimize_cache_support_test.dart` passou com 11 casos.
- Aceite Android live M2006: `deck_runtime_m2006_test.dart` passou em 1m45 no
  device `R58T300SREH`; `POST /ai/optimize` retornou 200 em 11.008s, abriu
  preview, aplicou selecao parcial e validou `10_complete_validated`.
- Aceite Android live generate async: `deck_generate_async_runtime_test.dart`
  passou em 1m22 no mesmo device; `POST /ai/generate` retornou 202 em 636ms,
  job concluiu em 15.622s, salvou deck, abriu detalhes e retornou outcome seguro
  `rebuild_guided_available` no optimize.

Risco residual:

- O diferencial competitivo saiu de contrato apenas app/UX para contrato
  backend rastreavel. Ainda so vira criterio real quando o backend cruzar
  colecao do usuario e fonte de preco na selecao das cartas.

### Etapa 6 - Retencao e Uso Continuo

| Requisito | Status | Evidencia | Observacao |
|---|---|---|---|
| Historico de partidas | PASS_MVP_LOCAL | `PostGameNotesScreen`, `PostGameNoteStore` | Local por deck via SharedPreferences |
| Notas pos-jogo | PASS_MVP_LOCAL | Campos de resultado, mesa, notas | Teste cobre salvamento e leitura |
| Cartas boas/ruins | PASS_MVP_LOCAL | `performedWell`, `underperformed` | Resumo agrega top/review candidates |
| Problemas de mana/compra/remocao/win condition | PASS_MVP_LOCAL | `PostGameIssue` | Sugestoes automaticas rule-based |
| Sugestao automatica depois da partida | PASS_MVP_LOCAL | `automaticSuggestions`, `DeckEvolutionSummary` | Nao usa IA ainda |
| Evolucao do deck ao longo do tempo | PARTIAL_MVP | Resumo de notas | Falta timeline de versoes/mudancas reais |
| Alertas de melhoria, preco e cartas faltantes | GAP | Nao implementado | Requer backend/agendador/notificacoes |

Riscos residuais:

- Historico local pode sumir em troca de aparelho/reinstalacao.
- Sem sincronizacao server-side, retencao fica limitada ao dispositivo.

### Etapa 7 - Comunidade, Trade e Crescimento

| Requisito | Status | Evidencia | Observacao |
|---|---|---|---|
| Decks publicos com analise visual | PASS_EXISTING | `CommunityScreen`, `CommunityDeckDetailScreen` | Fluxo existente preservado |
| Perfil de jogador | PASS_EXISTING | `UserProfileScreen`, `ProfileScreen` | Perfil e campos de troca ja existem |
| Seguir jogadores | PASS_EXISTING | `SocialProvider` e testes | Feed de seguidos preservado |
| Comentarios/feedback em decks | GAP | Busca por comments/feedback nao encontrou fluxo de comunidade | Precisa API, UI e moderacao |
| Binder publico | PASS_EXISTING | `BinderProvider.fetchPublicBinder*` | Existente |
| Lista de cartas para troca | PASS_EXISTING | `BinderItem.forTrade`, trades | Existente |
| Match entre cartas faltantes e usuarios que tem para trade | PARTIAL_MVP | `TradeMatchSummary`, `CommunityTradeGrowthPanel` | Resume potencial; nao lista usuarios especificos |
| Compartilhamento externo do deck/analise | PASS_MVP_PARTIAL | Relatorio optimize compartilhavel; share/export existentes | Preview social/deep link ainda pendente |

Riscos residuais:

- Match real precisa endpoint que cruze want list com ficharios publicos.
- Comentarios exigem moderacao, abuso/report e privacidade.

## Conclusao de pronto

Pronto para validacao interna de produto:

- Usuario entende Free/Pro, limite local e caminho de upgrade.
- Fluxos de IA tem paywall local.
- O sheet de otimizacao mostra diferencial de colecao/orcamento/intencao e
  preserva preview antes de aplicar.
- Pos-jogo registra partidas e gera resumo de evolucao local.
- Comunidade/trade tem painel de crescimento e usa estruturas existentes.

Nao pronto para venda publica completa:

- Billing real ausente.
- Limites e assinatura nao sao server-side.
- Backend implementa reconhecimento/cache/diagnostico de
  `recommendation_context`, mas ainda nao aplica colecao/preco real.
- Os residuos dos aceites live desta continuidade foram removidos com filtro
  restrito por IDs/nome/usuario QA e validados no PostgreSQL com contagem zero
  para usuarios, decks, deck_cards, job generate, cache optimize e telemetry
  fallback alvos.
- Comentarios/moderacao ausentes.
- Alertas e timeline server-side ausentes.
- Textos legais precisam revisao juridica.
