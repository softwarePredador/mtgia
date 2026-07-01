# ManaLoom Product Diagnostic - Etapa 1

Data: 2026-07-01
Escopo: diagnostico de produto, funcionalidades, disponibilidade, atratividade, uso continuo e lacunas antes de organizar as proximas etapas.
Status da etapa: completa.

## 1. Veredito executivo

O ManaLoom ja tem base de produto real, nao apenas prototipo. A proposta mais forte e ser um companion Commander-first que fecha o ciclo:

`criar/importar -> analisar -> otimizar/rebuild -> aplicar -> validar -> usar na mesa -> conectar colecao/trade`

O produto esta apto como base de teste interno/controlado, mas ainda nao deve ser tratado como lancamento publico/comercial limpo. O estado mais honesto e:

- Produto interno/testadores: `GO WITH RISKS`.
- Produto publico/comercial: `NO-GO` ate fechar observabilidade mobile, release build, escopo de scanner, plano/paywall e prova do fluxo principal em build real.
- Melhor posicionamento: IA Commander explicavel e validada, nao apenas "gerador de deck com IA".

## 2. Evidencias verificadas nesta etapa

### Repo local

- CWD: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch: `codex/session-agent-xmage-mapper-20260630`
- HEAD atual apos pacote de readiness/visual: `470dd95a5`
- Commits locais relevantes desta rodada:
  - `835ef0209` commander contract analysis summary.
  - `faf9f3bea` commander contract readiness no app.
  - `6ba586fcf` explicacoes estruturadas para optimize.
  - `5be5e3f22` battle readiness por carta.
  - `44032705d` launch capabilities/feature flags.
  - `84790d261` skips explicitos para fixtures opcionais ausentes.
  - `470dd95a5` disciplina visual de tokens/touch targets.
- Worktree remanescente: alteracoes de plataforma iOS/metadata e frente XMage/docs ainda fora deste pacote; nao misturadas nos commits de app readiness.
- Observacao: esta auditoria reflete o estado local atual apos os commits de readiness e polimento visual, mas ainda nao substitui prova em build assinado ou smoke real em device.

### Disponibilidade publica executada agora

Backend publico: `https://evolution-cartinhas.8ktevp.easypanel.host`

- `GET /health`: HTTP 200, `status=healthy`, `environment=production`, `version=1.0.0`, `git_sha=9a7d9518bd9a341f5bbf07d5be98bc69d7ab2bb1`.
- `GET /ready`: HTTP 200, `status=ready`, database healthy, `cards_data.card_count=34331`.
- `GET /cards?limit=1`: HTTP 200, retornou carta do catalogo.
- `GET /ready` com `x-request-id: stage1-product-diagnostic-20260701`: header retornou o mesmo request id.

Conclusao: a API publica e o catalogo de cartas estao disponiveis agora. Isso nao prova app publicado em loja, build assinado ou smoke real em device.

### Validacao tecnica executada agora

- `flutter analyze lib test --no-version-check` em `app/`: passou, sem issues.
- Testes focados do app:
  - `test/features/decks/providers/deck_provider_support_test.dart`
  - `test/features/decks/providers/deck_provider_test.dart`
  - `test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - `test/core/api/api_client_request_id_test.dart`
  - Resultado: 76 testes/casos passaram.
- Testes focados do backend:
  - `test/cards_route_test.dart`
  - `test/card_resolution_support_test.dart`
  - `test/ai_generate_performance_support_test.dart`
  - `test/openai_runtime_config_test.dart`
  - `test/deck_validation_route_support_test.dart`
  - `test/api_contracts_data_map_guard_test.dart`
  - Resultado: 40 testes/casos passaram.
- QA amplo posterior da rodada de readiness:
  - `server dart analyze`: passou.
  - `server dart test`: passou com 9 skips explicitos de fixtures externas opcionais ausentes.
  - `app flutter analyze`: passou.
  - `app flutter test`: passou.
- Gate visual premium atual:
  - `python3 server/bin/premium_visual_audit.py --include-life-counter --output /tmp/manaloom_premium_visual_audit_current.md`
  - Resultado: `VISUAL_PREMIUM_QA_RESULT: signals=0 P1=0 P2=0 visual_pass=false`.
  - Interpretacao: sem sinais estaticos objetivos restantes, mas `visual_pass=false` permanece correto porque app-facing visual change ainda exige screenshots de iPhone Simulator revisadas manualmente.

### Inventario atual

- App unit/widget tests: 124 arquivos.
- App integration tests: 133 arquivos.
- Server tests: 203 arquivos.
- Arquivos em `docs`, `app/doc` e `server/doc`: 6525 arquivos.
- `server/routes`: 89 arquivos Dart de rota.
- Superficie app por classes `Screen`/`Provider`: 69 ocorrencias.

## 3. Funcionalidades existentes

### App Flutter

- Auth/register/login/profile.
- Home e onboarding core flow.
- Deck list, deck details, deck generate, deck import.
- Analise de deck com functional tags, curva, composicao, legalidade e preco.
- IA para generate, optimize, rebuild guiado e commander-learning.
- Busca de cartas, detalhes, sets/collection.
- Binder/colecao, marketplace, trades.
- Social/community, perfis, follows e decks publicos.
- Mensagens diretas.
- Notificacoes.
- Life counter Lotus/native fallback.
- Scanner/OCR/camera existe no codigo, mas nao deve ser vendido como pronto.

### Backend Dart Frog/PostgreSQL

- Auth/JWT/profile/FCM token.
- Deck CRUD, cards, validate, analysis, pricing, export, import.
- AI generate/optimize/rebuild/simulate/commander-learning.
- Cards, printings, resolve, resolve batch.
- Binder, marketplace, trades, messages, notifications, community.
- Health/readiness.
- Plano Free/Pro e limite de IA em middleware.
- Dados de inteligencia: functional tags, semantic tags, card battle rules, commander learned/reference decks.

## 4. Matriz de status por modulo

| Modulo | Status de produto | Evidencia principal | Risco / lacuna |
|---|---|---|---|
| Auth/Profile | Pronto com risco | Contratos `stable`, rotas app/backend, testes de auth existentes | UX de erro/sucesso e plano ainda podem melhorar |
| Home/Onboarding | Pronto com risco | Fluxo documentado e rotas protegidas; testes focados verdes | Precisa smoke de sessao limpa em build real |
| Deck Builder core | Pronto com risco | Tests focados passaram; fluxo `details -> optimize -> apply -> validate` coberto | Ainda precisa prova ponta a ponta em build assinado/public backend |
| Importacao | Pronto com risco | Parser, aliases localizados e backend contracts | PT provado; outras linguas nao devem ser prometidas sem sync/prova |
| Cards/Sets | Pronto | `/cards?limit=1` publico respondeu; contratos `stable` | Scanner usa cards, mas scanner em si nao esta pronto |
| Deck Analysis | Pronto com risco | Functional tags, commander contract, battle readiness e launch capabilities app-facing | Heuristico; nao e juiz perfeito de todas as cartas |
| AI Generate | Pronto com risco | Async generate, cache, commander reference, fallback; testes focados | Qualidade melhor em commanders com perfil/reference; generico e experimental |
| AI Optimize focado | Pronto com risco | Preview/apply/testes verdes e explicacoes estruturadas por recomendacao | Qualidade depende de candidatos; precisa prova runtime ampla |
| AI Optimize agressivo | Parcial | Documentado como safe no-op/friendly failure | Falta prova de apply real de sugestoes boas em deck nao vazio |
| AI Rebuild guiado | Pronto com risco | Rota e app flow existem; testes focados cobrem rebuild | Ainda deve ser provado em runtime publico com exemplos fortes |
| Commander learned decks | Pronto com risco | Flow `/ai/commander-learning`, dados aprendidos/reference | Diferencial forte, mas precisa virar narrativa visivel ao usuario |
| Collection/Binder | Pronto com risco | Contratos `stable`, provider/telas, runtime docs | Ainda nao e diferencial sem ligacao direta com optimize/budget |
| Marketplace/Trades | Pronto com risco | Contratos `stable`, timeline/chat/trust metrics | Precisa polimento de estados vazios/erro e prova fisica/release |
| Social/Community | Pronto com risco | Perfis, follow graph, public decks, copy | Ainda nao deve competir com core; falta moderacao/report/block |
| Messages | Pronto com risco | Inbox/chat/unread/read; contratos `stable` | Precisa prova em build real e UX de falha |
| Notifications | Pronto com risco | Lista/count/read/read-all/FCM code | Push real atual/APNs/FCM para build corrente ainda nao fechado |
| Life Counter | Pronto com risco | Lotus-first, route `/life-counter`, grande harness historico | Overlays/layout precisam prova visual continua; nao fecha o produto todo |
| Scanner/OCR | Nao pronto / deferred | Codigo camera/MLKit existe | Precisa sprint fisica dedicada; nao deve entrar no marketing de release |
| Monetizacao Free/Pro | Parcial | `PlanService`, `aiPlanLimitMiddleware`, `/users/me/plan` | Falta tela de plano, checkout, billing, paywall app e revisao legal/IP |
| Observabilidade | Parcial | Backend Sentry/documentado, `x-request-id` ecoado agora | App Sentry real e correlacao mobile ponta a ponta ainda pendentes |
| Release/Distribuicao | Nao pronto | Checklist go-live tem itens abertos | Falta build assinado/TestFlight/Play internal smoke com API publica |
| Sync/Operacao de dados | Parcial | Docs e scripts existem | Sync jobs, load test e plano 10k MAU ainda abertos no checklist |
| Legal/IP/Compliance | Nao pronto comercial | WotC Fan Content Policy exige cuidado com monetizacao | Precisa revisao juridica antes de assinatura paga com IP/conteudo MTG |

## 5. O que esta realmente funcionando agora

Com prova executada nesta etapa:

- Backend publico responde health/readiness/cards.
- Banco publico responde com catalogo de cartas.
- `x-request-id` e preservado em `/ready` quando enviado manualmente.
- App passa `flutter analyze`.
- Testes focados do fluxo de deck/AI/app request-id passam.
- Testes focados de cards/resolucao/AI generate/cache/config/deck validate/API docs passam.

Com prova forte documental/codigo, mas nao reexecutada nesta etapa:

- Auth/profile, community, binder, trades, messages, notifications e life counter tem contratos, providers, telas e historico de runtime.
- Functional tags, learned decks, semantic/battle-rule data e commander reference existem como base de inteligencia.

## 6. O que existe, mas nao esta pronto para vender

- Scanner/OCR: codigo existe, mas o proprio produto marca como deferred/not proven.
- Monetizacao: backend tem limite e plano, mas falta produto comercial completo.
- Paywall/checkout: nao ha experiencia app fechada.
- Release mobile: falta prova de build assinado e distribuicao.
- Observabilidade mobile: Sentry app e request-id ponta a ponta real ainda pendentes.
- Push real para build atual: nao deve ser prometido sem nova prova.
- Multi-idioma de importacao: PT esta forte; outros idiomas precisam sync/prova.
- Optimize agressivo: UX segura existe, mas falta demonstracao de qualidade/apply.

## 7. Atratividade para clientes

O que atrai:

- Reduz tempo para montar e ajustar Commander.
- Explica por que o deck esta fraco, nao apenas lista cartas.
- Ajuda a preservar legalidade, identidade de cor e bracket.
- Pode conectar deck, colecao, trade e mesa no mesmo produto.
- Tem oportunidade forte no Brasil: PT, R$, trade local, comunidade local.
- Pode usar dados aprendidos e regras auditadas como diferencial defensavel.

O que pode gerar confianca:

- Preview antes de aplicar IA.
- Aplicacao seletiva de swaps.
- Validacao final.
- Relatorio antes/depois.
- Explicacao por funcao: ramp, draw, removal, wipes, protection, wincon, engine.

## 8. Uso continuo esperado

Hoje o produto ja cobre bem:

- Criar/importar deck.
- Analisar.
- Otimizar/rebuild.
- Validar.
- Usar life counter.
- Interagir com binder/trade/community.

O loop de uso continuo ainda precisa ser produto, nao so modulo:

- Registrar partidas.
- Marcar cartas que performaram bem/mal.
- Registrar mulligans, problemas de mana e faltas de resposta.
- Sugerir ajustes apos a partida.
- Gerar lista de compra/troca a partir dos gaps.
- Otimizar com base na colecao e no orcamento.

Esse e o maior salto de retencao: transformar deck builder em acompanhamento vivo do deck.

## 9. Comparativo externo

Referencias verificadas em 2026-07-01:

- ManaBox: busca offline, scanner, collection management, deck builder, charts, simulator e news feed. Fonte: https://manabox.app/
- TopDecked: deck builder, playtest simulator, collection value e life counter sincronizado mobile/web. Fonte: https://www.topdecked.com/index.html
- Moxfield: deck builder moderno, visualizacao texto/imagem, ordenacao por nome/preco. Fonte: https://moxfield.com/
- Archidekt: deck builder visual, search, stats, price compare, dados de Scryfall/EDHREC. Fonte: https://archidekt.com/
- MTG Agents: AI deck builder/rules assistant com Scryfall/rules data. Fonte: https://mtg-agents.com/ai-deck-builder
- ManaTap: AI, budget swaps, collection-aware AI, deck checker, mulligan lab e Pro. Fonte: https://www.manatap.ai/
- DeckCheck: estrategia, smart search e recomendacoes baseadas no plano do deck. Fonte: https://deckcheck.co/
- Wizards Commander Brackets: brackets e Game Changers seguem relevantes para Commander em 2026. Fonte: https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026
- WotC Fan Content Policy: Fan Content usando IP da Wizards deve ser gratuito para acesso; pagamentos/subscriptions exigem cuidado juridico. Fonte: https://company.wizards.com/en/legal/fancontentpolicy

Leitura competitiva:

- Concorrentes fortes ja existem em deckbuilding, collection, scanner, life counter e IA.
- ManaLoom nao deve se posicionar apenas como "tem IA".
- O diferencial potencial e: Commander-first, bracket-aware, explainable AI, validation-first, collection/trade aware, e aprendizado por uso real.

## 10. Pontos fortes atuais

- Produto tem um core claro e documentado.
- Backend publico esta vivo e com catalogo.
- Arquitetura separa mobile de APIs externas: app consome ManaLoom, backend controla Scryfall/OpenAI/dados/regras.
- Ha muita cobertura de testes e documentacao operacional.
- IA nao e uma tela solta: esta ligada a generate, optimize, rebuild, validation, learned decks e functional tags.
- Life counter e ecossistema social/trade aumentam retencao quando o core estiver fechado.
- PT/localizacao e mercado brasileiro podem virar vantagem.

## 11. Pontos fracos atuais

- Produto ainda tem muitos modulos laterais; risco de parecer amplo, mas nao fechado.
- Comercializacao ainda esta incompleta: plano existe no backend, nao na experiencia de usuario.
- Scanner e um risco de promessa: existe codigo, mas nao ha aceitacao de produto.
- Observabilidade mobile ainda nao esta fechada.
- Release publico ainda nao tem prova final.
- Diferencial de IA ja comecou a aparecer mais explicitamente na UI: plano Commander, explicacoes de recomendacao, battle readiness por carta e capabilities. Ainda falta prova runtime ampla e narrativa comercial final.
- Falta loop pos-jogo para uso continuo.
- Falta ligacao forte entre colecao/budget/trade e otimizacao.

## 12. Conclusao da Etapa 1

O ManaLoom tem uma base rara: deck builder, IA, dados de cartas, validacao, aprendizado, colecao, trade e mesa no mesmo ecossistema. O risco nao e falta de funcionalidades. O risco e empacotamento, confiabilidade final e foco comercial.

O proximo passo correto e a Etapa 2: fechar o core para lancamento com um criterio unico de aceite:

`usuario novo -> onboarding -> gerar/importar deck -> abrir detalhes -> analisar -> otimizar -> aplicar -> validar -> exportar/compartilhar`

Esse fluxo precisa passar em build real contra backend publico. Todo o resto deve ficar secundario ate essa jornada virar prova repetivel.
