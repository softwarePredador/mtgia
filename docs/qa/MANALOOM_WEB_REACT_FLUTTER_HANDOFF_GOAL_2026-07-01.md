# ManaLoom Web React + Flutter Handoff Goal

Data: 2026-07-01
Status: `HANDOFF_READY_FOR_REACT_AGENT`

## Objetivo

Estruturar a etapa anterior ao trabalho do agente React: definir a divisao entre
web publica em React/Next e app logado em Flutter Web, mapear rotas, contratos
de dados, limites de responsabilidade e criterios de pronto para evitar
retrabalho.

Este goal nao implementa a web React e nao muda banco de dados. Ele prepara o
handoff para que o outro agente crie o template publico com arquitetura coerente
com o app existente.

## Decisao de arquitetura

O ManaLoom deve ser tratado como um produto web unico com duas camadas:

```text
manaloom.com/*
React/Next publico: SEO, landing, pricing, blog, decks publicos, relatorios,
perfis publicos e marketplace indexavel.

manaloom.com/app/*
Flutter Web: app logado, deck builder, IA, colecao, pos-jogo, comunidade,
trade, notificacoes e fluxos interativos.

server/
Backend/API: fonte de verdade para dados, regras, planos, IA, permissao,
relatorios, decks, colecao, trade e marketplace.
```

O mesmo dominio pode hospedar as duas camadas. A separacao e por rota, nao por
produto.

## Evidencia do estado atual

O app Flutter atual esta em `app/` e usa `GoRouter` em
`app/lib/main.dart`. As rotas principais hoje incluem:

- publicas tecnicas do app: `/`, `/login`, `/register`.
- produto logado: `/home`, `/decks`, `/decks/generate`, `/decks/import`,
  `/decks/:id`, `/decks/:id/search`, `/decks/:id/scan`,
  `/decks/:id/post-game`, `/collection`, `/market`, `/community`, `/profile`,
  `/messages`, `/notifications`, `/trades`.
- comercial dentro do app: `/plans`, `/upgrade`, `/checkout`, `/legal`.

O redirect atual trata `/plans`, `/upgrade`, `/checkout` e `/legal` como rotas
protegidas. Para web publica, o React deve assumir as versoes publicas de
pricing e legal. O Flutter pode manter copias internas para usuario logado.

## Responsabilidades por camada

| Area | React/Next publico | Flutter Web logado | Backend/API |
|---|---|---|---|
| Landing | Dono | Link para `/app` | Nao aplica |
| Pricing | Pagina publica, SEO e CTA | Medidor, paywall e upgrade no contexto | Plano real, limite, checkout |
| Legal | Termos publicos | Link interno | Fonte versionada dos textos, se dinamico |
| Deck publico | Render indexavel | Edicao e analise logada | Dados publicos e permissoes |
| Relatorio antes/depois | Render compartilhavel | Geracao e aplicacao | Resultado, explicacoes, privacidade |
| Perfil publico | Render indexavel | Perfil logado e configuracoes | Perfil, decks e opt-ins |
| Marketplace | Descoberta publica | Trade operacional | Listings, preco, disponibilidade |
| Blog/conteudo | Dono | Nao aplica | Opcional se CMS/API |
| IA/recomendacao | Apenas exibe resultado publico | UX interativa | Logica e constraints reais |
| Auth | CTA para app | Dono | Sessao, conta, permissoes |

## Rotas publicas do React

Primeira versao do template:

| Rota | Proposito | Fonte inicial |
|---|---|---|
| `/` | Landing com proposta e CTAs | Mock |
| `/pricing` | Planos Free/Pro e motivo de upgrade | Mock ou API futura |
| `/decks/[id]` | Deck publico compartilhavel | Mock `PublicDeck` |
| `/reports/[id]` | Relatorio antes/depois compartilhavel | Mock `PublicReport` |
| `/players/[id]` | Perfil publico de jogador | Mock `PublicPlayer` |
| `/marketplace` | Descoberta publica de cartas/decks/trades | Mock `MarketplaceListing` |
| `/blog` | Lista de posts indexaveis | Mock/MDX futuro |
| `/blog/[slug]` | Post publico | Mock/MDX futuro |
| `/legal/terms` | Termos de uso | Draft publico |
| `/legal/privacy` | Privacidade | Draft publico |
| `/legal/disclaimer` | Disclaimer IA/IP/precos/brackets | Draft publico |

CTAs do React devem apontar para `/app` neste primeiro template. Links internos
mais profundos do Flutter so devem ser adicionados depois que o app estiver
pronto para rodar sob `/app/*`.

## Rotas do Flutter Web logado

Alvo final no mesmo dominio:

| Rota web final | Rota Flutter atual equivalente |
|---|---|
| `/app` | `/home` ou splash autenticado |
| `/app/home` | `/home` |
| `/app/decks` | `/decks` |
| `/app/decks/generate` | `/decks/generate` |
| `/app/decks/import` | `/decks/import` |
| `/app/decks/:id` | `/decks/:id` |
| `/app/decks/:id/search` | `/decks/:id/search` |
| `/app/decks/:id/scan` | `/decks/:id/scan` |
| `/app/decks/:id/post-game` | `/decks/:id/post-game` |
| `/app/collection` | `/collection` |
| `/app/market` | `/market` |
| `/app/community` | `/community` |
| `/app/profile` | `/profile` |
| `/app/messages` | `/messages` |
| `/app/notifications` | `/notifications` |
| `/app/trades` | `/trades` |

Antes de publicar em `manaloom.com/app`, o Flutter precisa de uma decisao
tecnica:

1. Preferido para mesmo dominio: adaptar as rotas web para prefixo `/app` e
   buildar Flutter Web com `--base-href /app/`.
2. Alternativa mais rapida: publicar o Flutter em `app.manaloom.com` e manter
   as rotas atuais, migrando para `/app` depois.

O agente React nao deve implementar nem simular as rotas internas de `/app`.

## Contratos publicos de API

O React deve comecar com mocks, mas os mocks precisam representar contratos
que o backend possa fornecer depois.

### `GET /api/public/pricing`

Retorna planos publicos.

Campos minimos:

- `id`: `free` ou `pro`.
- `name`.
- `priceLabel`.
- `aiLimitLabel`.
- `features`.
- `highlight`.
- `ctaLabel`.

### `GET /api/public/decks/:id`

Retorna deck publico se o dono permitiu compartilhamento.

Campos minimos:

- `id`, `slug`, `name`, `commander`, `colors`.
- `owner`: id, displayName, handle.
- `format`, `bracket`, `powerLevel`, `visibility`.
- `strategySummary`.
- `manaCurve`: custo convertido por bucket.
- `typeBreakdown`: terrenos, criaturas, ramp, draw, removal, protection,
  winConditions e outros.
- `cards`: nome, quantity, category, role, priceEstimate.
- `updatedAt`.

### `GET /api/public/reports/:id`

Retorna relatorio compartilhavel de otimizacao.

Campos minimos:

- `id`, `deckId`, `deckName`, `commander`.
- `intent`: casual, upgraded, optimized ou cEDH.
- `budgetLimitBrl`.
- `preferCollection`.
- `before`: curve, bracket, estimatedPrice, issueSummary.
- `after`: curve, bracket, estimatedPrice, expectedImpact.
- `swaps`: removeCard, addCard, reason, function, risk, curveImpact,
  priceBrl, bracketImpact, confidence.
- `shareTitle`, `shareDescription`.

### `GET /api/public/players/:id`

Retorna perfil publico com dados opt-in.

Campos minimos:

- `id`, `displayName`, `handle`, `avatarUrl`.
- `playStyle`, `favoriteFormats`, `tableLevel`.
- `publicDecks`.
- `tradeSummary`: opt-in, wishlistCount, forTradeCount, missingCardsCount.

### `GET /api/public/marketplace`

Retorna descoberta publica de cartas, decks e oportunidades de trade.

Campos minimos:

- `cards`: id, name, colors, priceEstimate, demandSignal.
- `tradeOpportunities`: cardName, wantedByCount, offeredByCount, regionLabel.
- `featuredDecks`: id, name, commander, bracket, owner.

## Regras para evitar retrabalho

- React nao calcula recomendacao de IA. Ele renderiza a explicacao entregue pela
  API ou mock.
- React nao decide limite real de plano. Ele mostra copy publica; o backend e o
  Flutter logado decidem quota e paywall.
- React nao implementa auth, colecao, trade operacional nem checkout real nesta
  etapa.
- O mesmo dado publico deve ter uma unica fonte futura de API.
- Campos sensiveis de colecao, binder e trade so aparecem com opt-in explicito.
- O template pode usar mocks, mas precisa isolar mocks em `web-public/src/lib`.
- Nao usar arte, marcas, logos ou simbolos oficiais de Magic/Wizards como se
  fossem propriedade do ManaLoom.
- Textos legais sao draft operacional e precisam revisao juridica antes de
  oferta paga publica.

## Estrutura esperada do template React

```text
web-public/
  README.md
  package.json
  next.config.ts
  src/
    app/
      page.tsx
      pricing/page.tsx
      decks/[id]/page.tsx
      reports/[id]/page.tsx
      players/[id]/page.tsx
      marketplace/page.tsx
      blog/page.tsx
      blog/[slug]/page.tsx
      legal/terms/page.tsx
      legal/privacy/page.tsx
      legal/disclaimer/page.tsx
      sitemap.ts
      robots.ts
    components/
    lib/
      mock-data.ts
      types.ts
      routes.ts
```

## Criterios de pronto para o agente React

- Projeto criado em `web-public/`.
- Todas as rotas publicas acima existem.
- Layout responsivo desktop/mobile.
- Metadata SEO por pagina.
- Open Graph em deck e relatorio.
- `sitemap.ts` e `robots.ts` presentes.
- CTAs de produto apontam para `/app`.
- Dados mockados centralizados em `src/lib/mock-data.ts`.
- Tipos centralizados em `src/lib/types.ts`.
- README explica instalacao, execucao, build e proximos passos.
- Nenhuma alteracao em `app/`, `server/` ou PostgreSQL.
- O projeto roda localmente e passa em lint/build, se as dependencias forem
  instaladas.

## Sequencia de execucao depois deste handoff

1. Passar o prompt de `docs/qa/MANALOOM_REACT_PUBLIC_TEMPLATE_AGENT_PROMPT_2026-07-01.md`
   para o outro agente.
2. Outro agente cria `web-public/` com Next.js.
3. Revisar o template React contra este documento.
4. Abrir novo goal para preparar Flutter Web em `/app` ou decidir subdominio.
5. Criar contratos reais no backend para substituir mocks publicos.
6. Configurar dominio/rewrite:
   - `manaloom.com/*` para React/Next.
   - `manaloom.com/app/*` para Flutter Web.
7. Rodar QA de refresh direto, SEO, sharing, mobile/desktop e navegacao entre
   React e Flutter.

