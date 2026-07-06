# ManaLoom - Fechamento Dos 7 Blocos De Produto

Data: 2026-07-06

Objetivo do goal: organizar e executar os 7 blocos de produto para deixar o
ManaLoom mais vendavel, confiavel e diferenciado, cobrindo app Flutter, backend
ManaLoom, web publica React/Next.js e deploy no novo EasyPanel ManaLoom.

## Status executivo

| Etapa | Bloco | Status 2026-07-06 | Criterio de pronto |
|---|---|---|---|
| 1 | Diagnostico produto | Concluido em documento anterior | Estado real do produto mapeado com riscos e lacunas |
| 2 | Core para lancamento | Concluido para teste interno | Fluxo principal do app validado por testes e smokes focados |
| 3 | Confiabilidade e observabilidade | Concluido para teste interno | Backend, request-id, Sentry/Firebase e release readiness mapeados |
| 4 | Produto comercial e monetizacao | Implementado e revalidado | Usuario entende Free/Pro, limite de IA, paywall e upgrade |
| 5 | Diferencial principal | Implementado e revalidado | Recomendacao explica colecao, orcamento, troca, risco, curva, preco e bracket |
| 6 | Retencao e uso continuo | Implementado e revalidado | Deck passa a ter historico pos-jogo e evolucao local |
| 7 | Comunidade, trade e crescimento | Implementado e revalidado | Usuario pode publicar, explorar, seguir, usar binder, marketplace e trade |

## Etapa 1 - Diagnostico Produto

Entregue em:

- `docs/qa/MANALOOM_PRODUCT_DIAGNOSTIC_STAGE1_2026-07-01.md`

Resumo:

- Produto foi auditado por funcionalidade, disponibilidade, atratividade,
  riscos de uso continuo e lacunas comerciais.
- Resultado anterior apontou que o produto era forte para teste interno, mas
  precisava fechar monetizacao, diferencial, retencao e comunidade antes de
  parecer vendavel.

## Etapa 2 - Core Para Lancamento

Entregue em:

- `docs/qa/MANALOOM_STAGE2_CORE_RELEASE_READINESS_2026-07-01.md`

Resumo:

- Core de deck, importacao, analise, otimizacao, validacao e export/share ficou
  sustentado por testes focados.
- O app ja tinha fluxo suficiente para usuario interno testar a proposta de
  valor sem depender da web publica.

## Etapa 3 - Confiabilidade E Observabilidade

Entregue em:

- `docs/qa/MANALOOM_STAGE3_OBSERVABILITY_READINESS_2026-07-01.md`

Resumo:

- Observabilidade e readiness foram documentados.
- Backend publico foi validado por health/ready.
- Sentry/Firebase e release readiness ficaram mapeados com bloqueios externos
  quando dependiam de credenciais, assinatura ou configuracao fora do repo.

## Etapa 4 - Produto Comercial E Monetizacao

Implementado/revalidado agora:

- Plano Free/Pro no app:
  - `app/lib/features/commercial/models/manaloom_plan.dart`
  - `app/lib/features/commercial/screens/plan_screen.dart`
  - `app/lib/features/commercial/screens/upgrade_screen.dart`
  - `app/lib/features/commercial/screens/checkout_screen.dart`
- Uso de IA e paywall:
  - `app/lib/features/commercial/providers/commercial_provider.dart`
  - `app/lib/features/commercial/widgets/ai_usage_gate.dart`
  - integracao em `app/lib/main.dart`
- Plano server-side e checkout backend:
  - `server/lib/plan_service.dart`
  - `server/routes/users/me/plan/index.dart`
  - `server/routes/users/me/plan/checkout/index.dart`
- Configuracao:
  - `server/.env.example`

Estado atual:

- Free tem limite mensal claro.
- Pro tem limite maior e preco exibido no app.
- App sincroniza plano remoto quando autenticado.
- Quando o limite de IA termina, o fluxo abre paywall/upgrade.
- Checkout backend nao ativa Pro sem configuracao explicita.
- Se houver URL de checkout externa, o backend retorna caminho de pagamento.
- Se habilitar ativacao interna por env, backend ativa Pro para validacao
  controlada.

Pendencia externa:

- Integrar provedor real de pagamento, como Stripe ou Mercado Pago, e revisar
  juridicamente termos, privacidade, disclaimer e politica de IP antes de
  cobrar usuario final.

## Etapa 5 - Diferencial Principal

Implementado/revalidado agora:

- App envia contexto de recomendacao:
  - `prefer_collection`
  - `budget_limit_brl`
  - `rebuild_intent`
  - `report=before_after_shareable`
  - `explain_swaps=true`
  - `include_price_risk_curve_bracket=true`
- Backend agora honra o contexto no optimize:
  - `server/lib/ai/optimize_route_request_support.dart`
  - `server/lib/ai/optimize_route_recommendation_context_support.dart`
  - `server/lib/ai/optimize_swap_candidate_support.dart`
  - `server/routes/ai/optimize/index.dart`
- O diagnostico antigo `pending_collection_inventory_join` foi substituido por
  suporte real:
  - `accepted_for_binder_priority`
  - `accepted_for_budget_filter`
- O backend consulta `user_binder_items` para priorizar cartas do fichario.
- O backend usa `cards.price_usd`/`price_usd_foil` com taxa BRL configurada no
  helper para estimar custo em reais e filtrar adicoes acima do orcamento.
- A resposta final inclui:
  - `collection_match`
  - `owned_quantity`
  - `purchase_required`
  - `estimated_price_brl`
  - `price_brl`
  - diagnostico `recommendation_constraints`
- O preview Flutter ja mostra funcao, risco, curva, preco e bracket quando o
  backend envia esses campos.
- Relatorio antes/depois compartilhavel continua disponivel no preview.

Resultado:

- O ManaLoom deixa de ser apenas "IA sugere cartas" e passa a explicar se a
  troca usa o que o usuario tem, quanto custaria comprar e por que a troca
  passou pelos gates.

## Etapa 6 - Retencao E Uso Continuo

Implementado/revalidado:

- Historico local de partidas:
  - `app/lib/features/retention/models/post_game_note.dart`
  - `app/lib/features/retention/services/post_game_note_store.dart`
  - `app/lib/features/retention/screens/post_game_notes_screen.dart`
- Rota ligada ao deck:
  - `/decks/:id/post-game` em `app/lib/main.dart`
  - acao no menu de detalhes do deck em
    `app/lib/features/decks/screens/deck_details_screen.dart`
- O usuario registra:
  - resultado da partida;
  - nivel da mesa;
  - notas;
  - cartas que performaram bem;
  - cartas que performaram mal;
  - problemas de mana, compra, remocao, win condition, velocidade e protecao.
- O app consolida resumo de evolucao por deck.

Limite consciente:

- O historico pos-jogo ainda e local no dispositivo. Para retencao multi-device,
  o proximo passo e persistir essas notas no backend e usar os sinais como
  input automatico do optimize.

## Etapa 7 - Comunidade, Trade E Crescimento

Implementado/revalidado:

- Comunidade:
  - `app/lib/features/community/providers/community_provider.dart`
  - `app/lib/features/community/screens/community_screen.dart`
  - `app/lib/features/community/screens/community_deck_detail_screen.dart`
  - `server/routes/community/decks`
  - `server/routes/community/users`
- Perfil e seguir jogadores:
  - `server/routes/users/[id]/follow`
  - `server/routes/users/[id]/followers`
  - `server/routes/users/[id]/following`
- Binder publico, marketplace e trade:
  - `app/lib/features/binder/providers/binder_provider.dart`
  - `app/lib/features/binder/screens/binder_screen.dart`
  - `app/lib/features/binder/screens/marketplace_screen.dart`
  - `server/routes/binder`
  - `server/routes/community/binders/[userId].dart`
  - `server/routes/community/marketplace/index.dart`
  - `server/routes/trades`
- Painel de crescimento:
  - `app/lib/features/growth/widgets/community_trade_growth_panel.dart`
  - `app/lib/features/growth/models/trade_match_summary.dart`
- O painel mostra sinais de:
  - cartas faltantes;
  - want list;
  - cartas para troca;
  - duplicadas;
  - atalhos para fichario, want list, trades e busca de jogadores.

Limite consciente:

- Comentarios em deck e ranking social mais avancado ainda podem virar uma
  etapa posterior. O MVP atual ja cria rede por decks publicos, perfil, follow,
  binder publico, marketplace e trade.

## Web Publica React/Next.js

Implementado/deploy:

- Projeto: `web-public`
- Docker:
  - `web-public/Dockerfile`
  - `web-public/.dockerignore`
  - `web-public/next.config.ts` com `output: "standalone"`
- URL atual:
  - `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`
- API atual:
  - `https://evolution-cartinhas.2ta7qx.easypanel.host`

Papel do React publico:

- SEO, landing, pricing, marketplace publico, decks publicos, perfis publicos,
  blog/legal e compartilhamento.

Papel do Flutter Web/app:

- Experiencia logada: deck builder, IA, colecao, pos-jogo, comunidade, trade e
  notificacoes.

## Infra E Banco

Estado atual:

- Novo host ManaLoom EasyPanel:
  - `manaloom-easypanel-parallel-20260703`
- API no novo ambiente:
  - `evolution_cartinhas`
  - `https://evolution-cartinhas.2ta7qx.easypanel.host`
- Web publica:
  - `evolution_manaloom-web-public`
  - `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`
- PostgreSQL novo:
  - `evolution_manaloom-postgres`
  - banco `halder`
- Migracao validada:
  - `public_tables=78`
  - `cards=34331`
  - `users=1134`
  - `decks=1348`

## Validacoes Rodadas

App Flutter:

```bash
flutter test test/features/commercial/commercial_provider_test.dart \
  test/features/retention/post_game_note_store_test.dart \
  test/features/growth/trade_match_summary_test.dart \
  test/features/community/providers/community_provider_test.dart \
  test/features/community/providers/social_provider_test.dart \
  test/features/binder/providers/binder_provider_test.dart \
  test/features/decks/providers/deck_recommendation_context_payload_test.dart \
  test/features/decks/widgets/deck_optimize_flow_support_test.dart \
  --no-version-check
```

Resultado: `51 tests passed`.

Backend:

```bash
dart test test/plan_checkout_contract_test.dart \
  test/optimize_route_request_support_test.dart \
  test/optimize_payload_support_test.dart \
  test/optimize_swap_candidate_support_test.dart \
  test/optimize_route_recommendation_context_support_test.dart \
  --reporter expanded
```

Resultado: `18 tests passed`.

Backend analyze:

```bash
dart analyze lib/plan_service.dart \
  routes/users/me/plan/checkout/index.dart \
  lib/ai/optimize_route_recommendation_context_support.dart \
  lib/ai/optimize_swap_candidate_support.dart \
  lib/ai/optimize_payload_support.dart \
  lib/ai/optimize_route_request_support.dart \
  routes/ai/optimize/index.dart \
  test/plan_checkout_contract_test.dart \
  test/optimize_route_recommendation_context_support_test.dart \
  test/optimize_route_request_support_test.dart \
  test/optimize_payload_support_test.dart
```

Resultado: `No issues found`.

Web publica:

```bash
npm run lint
npm run build
```

Resultado: passou antes do deploy do servico publico.

Deploy/health:

- Web publica:
  - `/`, `/pricing`, `/marketplace` responderam HTTP 200.
- API:
  - `/health` e `/ready` responderam OK no novo ambiente.
  - `/cards?limit=1&page=1` retornou 1 carta apos cutover de banco.

## Pendencias Reais Depois Dos 7 Blocos

Estas pendencias nao bloqueiam o MVP dos 7 blocos, mas bloqueiam venda publica
sem risco operacional/juridico:

1. Conectar pagamento real e webhook de billing.
2. Revisao juridica final de termos, privacidade, disclaimer de IA e politica
   de IP/uso de cartas.
3. Persistir notas pos-jogo no backend para multi-device.
4. Criar contrato publico real para relatorios compartilhaveis persistentes.
5. Definir dominio final e rewrites:
   - `/` e paginas publicas no React/Next.js;
   - `/app` no Flutter Web;
   - API em subdominio ou rota propria.
6. Revalidar Sentry/observabilidade em build de producao apos deploy final.
7. Rodar aceite visual completo em desktop/mobile contra dominio final.

## Conclusao

Os 7 blocos estao organizados e executados em nivel MVP funcional. O maior gap
registrado anteriormente na etapa 5 foi fechado: o backend agora usa binder e
orcamento na recomendacao, e a resposta carrega explicacao suficiente para o
usuario entender cada troca.
