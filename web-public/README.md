# ManaLoom Web Public

Camada publica React/Next.js do ManaLoom.

Arquitetura alvo:

- `manaloom.com/*`: Next.js publico para SEO, descoberta, compartilhamento e conversao.
- `manaloom.com/app/*`: Flutter Web logado para deck builder, IA, colecao, pos-jogo, comunidade, trade e notificacoes.
- Integração atual: home e marketplace leem status, anúncios, imagens, preços, decks públicos e market movers do servidor ManaLoom quando disponível.
- Planos e capacidades públicas refletem contratos existentes do app/backend; não há cards, posts, perfis ou relatórios de demonstração.

## Instalar

```bash
cd web-public
npm install
```

## Rodar localmente

```bash
cd web-public
npm run dev
```

Abra `http://localhost:3000`.

Para apontar para outro backend público:

```bash
NEXT_PUBLIC_MANALOOM_API_BASE_URL=https://seu-backend.example.com npm run dev
```

## Deploy atual

- Public web: `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`
- API ManaLoom: `https://evolution-cartinhas.2ta7qx.easypanel.host`
- Serviço EasyPanel/Swarm: `evolution_manaloom-web-public`

## Build

```bash
cd web-public
npm run lint
npm run build
```

## Estrutura

```text
web-public/
  src/app/
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
  src/components/
  src/lib/
    product-data.ts
    public-server.ts
    routes.ts
    types.ts
```

## Dados reais

Não há fonte mockada para conteúdo público. As fontes atuais ficam em:

- `src/lib/public-server.ts`: `/health`, `/community/marketplace`, `/market/movers`, `/community/decks`, `/community/decks/:id`, `/community/users/:id`.
- `src/lib/product-data.ts`: capacidades reais do produto e planos espelhados do contrato do app (`app/lib/features/commercial/models/manaloom_plan.dart`).

Quando um endpoint não retorna dados, a interface mostra estado vazio ou 404. Ela não preenche com exemplos fictícios.

Substituicao recomendada para novas áreas:

1. Criar clientes de leitura publica em `src/lib/public-server.ts` quando existir uma fonte real.
2. Manter os mesmos tipos de `types.ts`.
3. Só publicar deck, relatório, perfil ou post quando houver contrato público real.
4. Garantir que o backend aplique permissao e opt-in antes de retornar dados publicos.
5. Nao calcular recomendacao, limite de plano, checkout, auth ou trade operacional no frontend publico.

## Decisoes

- O template usa Next.js App Router, TypeScript e Tailwind CSS.
- CTAs de produto apontam para `/app`.
- Open Graph foi configurado para deck e relatorio via metadata das paginas.
- `sitemap.ts` e `robots.ts` usam `NEXT_PUBLIC_SITE_URL` quando definido; fallback: `https://manaloom.com`.
- Textos legais sao drafts operacionais e precisam de revisao juridica.

## Proximos passos

- Criar contrato público real para relatórios compartilháveis antes de reativar `/reports/[id]`.
- Criar contrato editorial real antes de publicar posts em `/blog/[slug]`.
- Definir deploy/rewrite para servir Flutter Web em `/app`.
- Adicionar imagens OG reais quando a identidade visual publica estiver fechada.
- Rodar QA em mobile/desktop, refresh direto de rotas dinamicas, SEO e compartilhamento social.
