# BrewTact Web Public

Camada publica React/Next.js do BrewTact.

Arquitetura corrente da Beta gratuita:

- `https://brewtact.com/*`: Next.js público canônico e informativo.
- `/app` é uma coordenada reservada, sem link ou CTA enquanto a matriz
  server-authoritative estiver totalmente `OFF`.
- Não há oferta Pro, checkout, marketplace, decks/perfis públicos, social ou
  trade nesta superfície.
- O único fetch público de produto preservado é `/reports/:id`; IDs ausentes
  fecham em `404` e não são substituídos por conteúdo demonstrativo.

`https://evolution-manaloom-web-public.2ta7qx.easypanel.host` permanece como
endpoint técnico de deploy, health check e rollback. Metadata, sitemap, links
compartilháveis e navegação pública usam `https://brewtact.com`.

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

- Public web: `https://brewtact.com`
- Flutter autenticado: reservado em `https://brewtact.com/app/`, inacessível na
  matriz corrente all-OFF
- Android: `https://brewtact.com/downloads/manaloom-android.apk`
- API BrewTact: `https://evolution-cartinhas.2ta7qx.easypanel.host`
- Endpoint técnico Web: `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`
- Serviço EasyPanel/Swarm: `evolution_manaloom-web-public`
- Serviço Flutter EasyPanel/Swarm: `evolution_manaloom-app`

## Build

```bash
cd web-public
npm run lint
npm run build
npm run test:contract
```

## Estrutura

```text
web-public/
  src/app/
    page.tsx
    pricing/page.tsx
    reports/[id]/page.tsx
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
    routes.ts
  scripts/
    capture-screens.mjs
  tests/
    free-beta-offer-contract.mjs
```

## Capturas

`scripts/capture-screens.mjs` fotografa as páginas públicas em Chrome ou
Chromium headless, pelo DevTools Protocol, sem dependência nova (Node 22+).
Ele só aceita `--base-url` de loopback e abre o navegador sem proxy e sem
resolver nenhum host além do loopback.

```bash
cd web-public
NEXT_PUBLIC_MANALOOM_API_BASE_URL=http://127.0.0.1:<porta-do-fixture> npm run build
# servir .next/standalone em 127.0.0.1, como faz scripts/manaloom_public_web_smoke.sh
node scripts/capture-screens.mjs --base-url http://127.0.0.1:3100 \
  --out ../docs/qa/execution/<data>/site-publico --prefix final \
  --routes /,/pricing,/blog,/legal/terms --full-page
```

- Viewports: `desktop_1440x900` (DPR 1) e `mobile_390x844` (DPR 2, PNG com
  780 px de largura).
- `--full-page` acrescenta a página inteira, com as alturas `svh`/`vh`
  travadas antes da captura.
- `CHROME_BIN` escolhe o navegador; sem ele, o script tenta o Chromium do
  Playwright e o Chrome do macOS.
- `capture-manifest.json` registra, por arquivo, sha256, bytes, dimensões,
  status HTTP, título e metadata, fontes carregadas, erros de console, topo do
  `#produto`, navegador e o SHA do commit; `build_inputs_dirty` indica quando
  o build não corresponde ao commit.
- Status diferente de 200 ou erro de console fazem o script sair com código 1.

## Dados reais

Não há fonte mockada para conteúdo público. A única leitura de produto é
`/reports/:id`, feita na própria rota de relatório. `src/lib/product-data.ts`
contém apenas copy estática da Beta gratuita, sem entitlement ou plano pago.

Quando um endpoint não retorna dados, a interface mostra estado vazio ou 404. Ela não preenche com exemplos fictícios.

Substituicao recomendada para novas áreas:

1. Só adicionar uma leitura pública depois de capability, contrato e fonte
   reais estarem aprovados.
2. Garantir que o backend aplique permissão e opt-in antes de retornar dados.
3. Não calcular recomendação, limite de plano, checkout, auth ou trade no
   frontend público.

## Decisoes

- O template usa Next.js App Router, TypeScript e Tailwind CSS.
- O estado all-OFF não renderiza CTA ou link para `/app`.
- Open Graph permanece disponível apenas nas superfícies realmente publicadas.
- `sitemap.ts` e `robots.ts` usam `https://brewtact.com` como origem canônica; `NEXT_PUBLIC_SITE_URL` só aceita a mesma coordenada no deploy de produção.
- Textos legais sao drafts operacionais e precisam de revisao juridica.

## Proximos passos

- Validar `/reports/[id]` com relatórios reais criados pelo app antes de campanha pública.
- Criar contrato editorial real antes de publicar posts em `/blog/[slug]`.
- Adicionar imagens OG reais quando a identidade visual publica estiver fechada.
- Rodar QA em mobile/desktop, refresh direto de rotas dinamicas, SEO e compartilhamento social.
