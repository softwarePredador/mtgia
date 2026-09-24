# Receipt — Landing coerente com a oferta e o escopo da beta (`BT-WEB-001`) — 2026-09-24

Status: `PASS_LOCAL · BRANCH nuvem/site-publico-2026-09-24 · SEM DEPLOY`

Este receipt registra a execução local de `BT-WEB-001` por uma sessão em nuvem. A sessão mexeu só em
`web-public/` e nesta pasta. Nada aqui autoriza deploy, merge em `master`, escrita live ou promoção.
O `BT-WEB-001` continua `BLOCKED_BY_P0` no backlog até a coordenação integrar estes commits pelos hooks
e existir prova same-SHA do deploy.

## Identidade

- Branch: `nuvem/site-publico-2026-09-24`, criada de `origin/master` =
  `41bab49c949134cbea27e81d0020da47ce442be5`.
- Commits, do mais antigo ao mais novo:
  1. `d9d1d64` fix(BT-WEB-001): drop the explainable-AI and shareable-report claims from the site metadata (D-46)
  2. `941e8de` fix(BT-WEB-001): stop pointing every page's og:url at the home page
  3. `49fecbc` feat(BT-WEB-001): state the invite-only first-wave scope on the site (D-07, D-16)
  4. `601acc3` fix(BT-WEB-001): declare the variable weight range of the self-hosted fonts
  5. `21bd6d3` feat(BT-WEB-001): add a headless capture script for the public pages
  6. `c1663f0` feat(BT-WEB-001): add the life counter tile primitives to the public site
  7. `0a34a62` feat(BT-WEB-001): rebuild the landing and the beta page as counter tiles
  8. `bee2a06` fix(BT-WEB-001): keep git's stderr out of the capture log
  9. `aff00f0` fix(BT-WEB-001): close Chrome before removing the capture profile
  10. o commit `docs` deste receipt.
- Código capturado: `bee2a0619`. As entradas do build (`src`, `public`, `package*.json` e configs) são
  idênticas de `0a34a62` a `aff00f0`; os dois últimos commits de código mexem só no script de captura.
- Ferramentas: Node 22.22.2, npm 10.9.7, Next.js 15.5.25, Chromium 141.0.7390.37 headless
  (`/opt/pw-browsers/chromium`).
- Project logic: não regenerado. `web-public/src` entra no digest
  (`tools/project_logic/lib/project_logic_generator.dart:2545-2570`), então o `--check` vai acusar drift
  até a coordenação rodar `./scripts/manaloom_project_logic.sh --write` na integração. Esta máquina não
  tem Dart, e o `--check` também não rodou aqui.
- Hooks: não instalados, por instrução da coordenação. Nenhum commit passou pelo `pre-commit` nem pelo
  `pre-push`.
- Produção: nenhuma chamada. O build e o servidor apontaram para um fixture em `127.0.0.1:4010`, com
  dados fictícios. O Chrome das capturas rodou sem proxy e sem resolver nenhum host além do loopback.

## Decisões aplicadas

- **D-46.** Saem "Commander com IA explicável" do título e do OG, e "relatórios compartilháveis" da
  descrição e da oferta. Continuam os textos condicionais ("quando a IA estiver habilitada").
- **D-07.** A primeira coorte é o núcleo (decks, coleção privada, catálogo) mais o contador de vida; a
  análise com IA vem numa segunda onda. Na copy pública, "coorte", que é jargão interno, virou "onda":
  "primeira onda" e "segunda onda".
- **D-16.** O acesso é por convite, em lotes pequenos, com cadastro fechado. Não há lista de espera nem
  formulário.
- **Decisões do dono nesta sessão:**
  - régua do protótipo para gradiente: vidro a 160° nas peças neutras, latão a 158° na ação principal
    e nenhum gradiente decorativo;
  - linguagem nova na home, no cabeçalho, no rodapé e no `/pricing`, incluindo o `BrandPageIntro`;
  - commitar o script de captura.

## O que mudou

| Arquivo | Mudança |
| --- | --- |
| `web-public/src/app/layout.tsx:10,13-14,22-24` | Título "BrewTact - Decks, coleção e contador de vida para Commander". Descrição e OG em frases nominais, sem IA e sem relatório. Sai o `openGraph.url`, que apontava todas as páginas para a home. `icons:` fica. |
| `web-public/src/app/page.tsx:21-23` | A home herda o título descritivo e ganha uma descrição sem IA. |
| `web-public/src/app/page.tsx:46-122` | Hero "Mesa" (variação A): H1 "Monte melhor. Jogue melhor.", a oferta numa frase e o `AccessPending`. O tabuleiro traz Decks 100, Coleção e Catálogo; a peça de latão "Beta gratuita / Por convite" leva a `/pricing`; o hub tem a marca, que é a imagem `priority` com `fetchPriority="high"`; depois vêm o Contador de vida 40 e a Análise com IA em "Segunda onda". |
| `web-public/src/app/page.tsx:124-179` | `#produto` com as capabilities por onda, "Como funciona" com numerais 1-2-3 e a oferta em dois azulejos (gratuita e por convite), ao lado do status de acesso. |
| `web-public/src/app/pricing/page.tsx:23-59` | Oferta em azulejos, capabilities por onda e disponibilidade. Continuam "beta", "gratuita" e "sem cobrança". |
| `web-public/src/lib/product-data.ts:1-79` | Cada capability tem `id`, `wave` e numeral opcional; o contador de vida entra na primeira onda e a IA fica na segunda. A oferta passa a "Acesso por convite", e sai `features`, com o item "Relatórios compartilháveis". |
| `web-public/src/components/tiles.tsx` (novo) | Peças do contador: o azulejo de vidro com palavra de estado, rótulo e numeral Fraunces; a peça de latão com seta; o hub; a peça de fato; os ícones de traço. |
| `web-public/src/components/product-waves.tsx` (novo) | Grade de capabilities por onda, compartilhada pela home e pelo `/pricing`. |
| `web-public/src/components/ui.tsx:24-43,45-61,79` | O `AccessPending` vira pílula de vidro e mantém `role="status"` e o texto. O `ButtonLink` passa a latão ou vidro. O eyebrow sai do latão para a névoa. |
| `web-public/src/components/site-shell.tsx:11,17,27,43,53` | Nav "Avisos" no lugar de "IA e dados". Cabeçalho e rodapé sem borda, brilho e tagline em latão. O rodapé fala do convite e do contador de vida. |
| `web-public/src/components/brand-page-intro.tsx` | Abertura de página como azulejo de vidro, sem o banner e sem o véu em gradiente. Afeta o visual do pricing, do blog e das páginas legais, sem mudar o texto delas. |
| `web-public/src/app/globals.css:5-21` | `font-weight: 100 900` nos dois `@font-face`. As fontes são variáveis, e antes o navegador sintetizava negrito: o manifesto lia "Fraunces normal", agora lê "Fraunces 100 900". |
| `web-public/tailwind.config.ts:36-58` | Tokens do kit (`docs/design/ui-kit/kit.css`): vidro, latão, brilho diagonal, sombras de azulejo, latão, seta e hub, e raios 22 e 16. Sai a sombra `brass`, um brilho decorativo que ficou sem uso. |
| `web-public/tests/free-beta-offer-contract.mjs:24-46,48-60,96-137` | D-46, D-16 sem lista de espera, D-07 e negativos de Battle, Scanner, Generate/Rebuild, Learning e social público. Cada padrão negativo tem uma amostra que precisa casar. |
| `web-public/scripts/capture-screens.mjs` (novo) e `web-public/README.md:86` | Captura headless por CDP, sem dependência nova, com manifesto de sha256. O README documenta o uso. |

Literais travados fora de `web-public/` que continuam, conferidos por emulação dos testes Dart, porque
não há Dart aqui:
- 2× `min-h-[calc(100svh-11rem)]` e `id="produto" className="pb-20 pt-12 sm:py-20"` no `page.tsx`;
- `fetchPriority="high"`, sem `loading="eager"`;
- `<AccessPending` no shell, na home, no pricing e no report;
- `export function AccessPending`, `role="status"` e `Acesso ainda não liberado` no `ui.tsx`;
- `icons:` e as duas URLs de fonte;
- "Monte melhor. Jogue melhor." em `site-shell.tsx:28` e `page.tsx:54`;
- `id: "free-beta"` e `name: "Beta gratuita"`;
- no report, "Relatorio compartilhavel" e "Alterações sugeridas", intocados.

## Evidência local

| Camada | Resultado |
| --- | --- |
| `npm ci` (ponta `0a34a62`) | `PASS`; 0 vulnerabilidades |
| `npm run lint` | `PASS` (`--max-warnings=0`) |
| `npx eslint tests/*.mjs scripts/*.mjs` | `PASS`. O `eslint .` só lê `.ts`/`.tsx`, então os `.mjs` foram lintados pelo nome. |
| `npm run build` (com typecheck) | `PASS`; 12 rotas, sem rota nova nem removida |
| `node tests/free-beta-offer-contract.mjs` | `PASS` em `0a34a62` e em `aff00f0` |
| `npm audit` | `PASS`; 0 vulnerabilidades |
| `npm audit --omit=dev --audit-level=moderate` | `PASS`; 0 vulnerabilidades |
| `scripts/manaloom_public_web_smoke.sh` (árvore de `0a34a62`, raiz no scratchpad) | `PASS`. Checou rotas 200, rotas removidas, relatório de fixture, 404 sem `Location`, contrato de oferta no HTML renderizado, `Acesso ainda não liberado`, nenhum `href="/app"` e headers. |
| Emulação dos testes Dart `public_web_product_contract_test`, `user_facing_brand_contract_test` e `product_retention_report_contract_test` | `PASS` em cada commit. Os testes reais não rodaram aqui, por falta de Dart. |
| Cada commit num `git archive` limpo | lint, build, contrato, literais e HTML verdes nos 9 commits |
| `./scripts/manaloom_project_logic.sh --check` | não executado (sem Dart); drift esperado, ver Identidade |
| `./scripts/quality_gate.sh ui-proof` | não se aplica: o `SOURCE_ROOTS` do digest de UI cobre só o app Flutter |

### O contrato novo falha sem a mudança

O teste final rodou, com cada `assert` registrado em vez de lançado, contra três árvores.

**Fontes de `41bab49c9`** (`git archive`): 8 falhas.
- D-46: site metadata must not claim explainable AI
- D-46: site metadata must not claim shareable reports
- D-46: public source must not claim explainable AI
- D-46: landing and offer must not promise shareable reports
- D-16: the site must say that access is by invitation
- D-07: the life counter belongs to the first cohort
- D-07: AI analysis must be presented as a second wave
- D-07: the site must say that AI comes in a second wave

**Fontes de `d9d1d64`** (só a D-46 corrigida): falham as 3 de D-07.

**Mutante da ponta** (formulário de espera, rota `app/api/espera/route.ts` e IA na primeira onda): 5
falhas.
- D-16: public source must not offer a waitlist (waitlist copy)
- D-16: public source must not offer a waitlist (form control)
- D-16: only /healthz may handle requests; no sign-up endpoint
- D-07: AI analysis must not be offered as part of the first cohort
- D-07: AI analysis must be presented as a second wave

Os negativos de lista de espera não têm o que pegar na linha de base, porque ela não tem lista de
espera. A mutação mostra que eles mordem.

## Evidência de UI

`web-public` fica fora do digest de UI e do `docs/qa/ui-live/latest.json`. Esta evidência vale para a
revisão do dono e para a integração; ela não credita release.

- **`PASS_AUTOMATED`.** Lint, typecheck, build, contrato `.mjs`, emulação dos testes Dart e smoke com as
  regex do HTML renderizado. Não existe teste de widget ou golden para o site Next.js, e acessibilidade
  automatizada não rodou.
- **`PASS_RUNTIME`.** Build de produção real (`next build`, servidor standalone em `127.0.0.1:3100`,
  como no Dockerfile) com o Chromium 141 headless.
  - O `capture-manifest.json` registra 28 PNGs com sha256, bytes e dimensões, todos com HTTP 200 e zero
    erro de console.
  - O topo do `#produto` fica em 790 de 900 px no desktop e em 739 de 844 px no celular, então a seção
    seguinte aparece na primeira dobra, como exige o teste de landing.
  - As fontes carregadas são "Inter 100 900" e "Fraunces 100 900".
- **`PASS_VISUAL_REVIEWED`.** Os 28 arquivos foram abertos um a um. As páginas inteiras do celular
  também foram revisadas em segmentos da altura do viewport.
  - **Tese visual:** a mesa de azulejos do contador. Obsidiana, vidro escuro com filete marfim e latão
    só na ação principal (a peça "Beta gratuita / Por convite") e no aro do hub. Não há vitral, porque
    nada do produto está valendo hoje: a matriz está toda OFF.
  - **Plano de conteúdo:** marca, depois oferta e estado ("Beta gratuita · acesso por convite" e
    "Acesso ainda não liberado"), depois escopo por onda no tabuleiro, detalhe por capability, "Como
    funciona" e oferta.
  - **Tese de interação:** a única ação é conhecer a beta (`/pricing`). O status de acesso não é
    clicável e não há CTA para `/app`, cadastro ou lista.
  - **Hierarquia:** OK. Um herói de latão por tela, e os numerais 100 e 40 fazem de objeto.
  - **Identidade MTG:** OK. Commander pelos numerais 100 e 40, sem arte de carta.
  - **Cor e contraste:** OK. Marfim e névoa sobre vidro, latão só na ação e o estado apagado em névoa
    fraca. O contraste não foi medido por ferramenta.
  - **Tipografia:** OK. Fraunces no eixo de peso real e Inter 800 nos rótulos.
  - **Espaçamento e densidade:** OK.
  - **Adaptação:** OK em 1440 e em 390, sem rolagem horizontal.
  - **Clareza de interação:** OK. Uma ação, e o status é neutro.
  - **Estados:** OK. Acesso não liberado e segunda onda.
  - **Acessibilidade visual:** OK. As pílulas têm 44 px de alvo, o foco é em latão e os rótulos têm 11,5
    px ou mais.
  - **Atratividade:** OK.
  - **Bloqueadores:** nenhum.
  - **Fora do escopo:** o blog mantém o cartão `Surface` antigo, e o report mantém eyebrow e borda em
    latão.

## Capturas

Pasta: `docs/qa/execution/2026-09-24/site-publico/`. Os hashes completos estão em
`capture-manifest.json` (schema `brewtact_public_web_capture_v1`).

Viewports:
- desktop 1440×900 CSS a DPR 1;
- celular 390×844 CSS a DPR 2, o que gera PNGs com 780 px de largura.

"Página inteira" é a página toda com as alturas `svh`/`vh` travadas.

Reprodução: build com
`NEXT_PUBLIC_MANALOOM_API_BASE_URL=http://127.0.0.1:<fixture>`, servir `.next/standalone` em
`127.0.0.1:3100` e rodar:

```bash
node scripts/capture-screens.mjs --base-url http://127.0.0.1:3100 --out <pasta> --prefix final \
  --routes /,/pricing,/blog,/legal/terms,/reports/brewtact-fixture-report --full-page
```

O fixture do relatório segue o formato de `scripts/manaloom_public_web_smoke.sh`, com dados fictícios.

| Arquivo | Rota | Tipo | PNG (px) | SHA-256 (12) | Build |
| --- | --- | --- | --- | --- | --- |
| `antes_home_desktop_1440x900.png` | `/` | viewport | 1440×900 | `6742051e98c4` | fonte de 41bab49c9 (git archive) |
| `antes_home_mobile_390x844.png` | `/` | viewport | 780×1688 | `51dd57d5eb39` | fonte de 41bab49c9 (git archive) |
| `final_blog_desktop_1440x900_full.png` | `/blog` | página inteira | 1440×924 | `1d2c5d307254` | bee2a0619 |
| `final_blog_desktop_1440x900.png` | `/blog` | viewport | 1440×900 | `b66ca1737061` | bee2a0619 |
| `final_blog_mobile_390x844_full.png` | `/blog` | página inteira | 780×2648 | `c3dfbd601881` | bee2a0619 |
| `final_blog_mobile_390x844.png` | `/blog` | viewport | 780×1688 | `3a4221fd0c6f` | bee2a0619 |
| `final_home_desktop_1440x900_full.png` | `/` | página inteira | 1440×2749 | `fa2e084b6a5d` | bee2a0619 |
| `final_home_desktop_1440x900.png` | `/` | viewport | 1440×900 | `1b288c1eb9cb` | bee2a0619 |
| `final_home_mobile_390x844_full.png` | `/` | página inteira | 780×8734 | `ad2a42d9b773` | bee2a0619 |
| `final_home_mobile_390x844.png` | `/` | viewport | 780×1688 | `5111622d81c4` | bee2a0619 |
| `final_legal-terms_desktop_1440x900_full.png` | `/legal/terms` | página inteira | 1440×1023 | `4eb34f69dfed` | bee2a0619 |
| `final_legal-terms_desktop_1440x900.png` | `/legal/terms` | viewport | 1440×900 | `e843ef61b608` | bee2a0619 |
| `final_legal-terms_mobile_390x844_full.png` | `/legal/terms` | página inteira | 780×2870 | `1cc3e4631fda` | bee2a0619 |
| `final_legal-terms_mobile_390x844.png` | `/legal/terms` | viewport | 780×1688 | `6318582abbf6` | bee2a0619 |
| `final_pricing_desktop_1440x900_full.png` | `/pricing` | página inteira | 1440×1690 | `7359e776103e` | bee2a0619 |
| `final_pricing_desktop_1440x900.png` | `/pricing` | viewport | 1440×900 | `677b0dd9ce99` | bee2a0619 |
| `final_pricing_mobile_390x844_full.png` | `/pricing` | página inteira | 780×5724 | `422c72d753ab` | bee2a0619 |
| `final_pricing_mobile_390x844.png` | `/pricing` | viewport | 780×1688 | `38da7c6c4880` | bee2a0619 |
| `final_reports-brewtact-fixture-report_desktop_1440x900_full.png` | `/reports/brewtact-fixture-report` | página inteira | 1440×1085 | `ac6e73cdde68` | bee2a0619 |
| `final_reports-brewtact-fixture-report_desktop_1440x900.png` | `/reports/brewtact-fixture-report` | viewport | 1440×900 | `a30d6f66ca43` | bee2a0619 |
| `final_reports-brewtact-fixture-report_mobile_390x844_full.png` | `/reports/brewtact-fixture-report` | página inteira | 780×3666 | `23ebdbc00ca6` | bee2a0619 |
| `final_reports-brewtact-fixture-report_mobile_390x844.png` | `/reports/brewtact-fixture-report` | viewport | 780×1688 | `e8a797ca2497` | bee2a0619 |
| `hero-a-mesa_home_desktop_1440x900.png` | `/` | viewport | 1440×900 | `1b288c1eb9cb` | bee2a0619 |
| `hero-a-mesa_home_mobile_390x844.png` | `/` | viewport | 780×1688 | `5111622d81c4` | bee2a0619 |
| `hero-b-numeral_home_desktop_1440x900.png` | `/` | viewport | 1440×900 | `f9e7e0ee97b6` | aff00f0f8 + variação não commitada |
| `hero-b-numeral_home_mobile_390x844.png` | `/` | viewport | 780×1688 | `6a79808dd0a8` | aff00f0f8 + variação não commitada |
| `hero-c-faixa_home_desktop_1440x900.png` | `/` | viewport | 1440×900 | `dbb32a6d2063` | aff00f0f8 + variação não commitada |
| `hero-c-faixa_home_mobile_390x844.png` | `/` | viewport | 780×1688 | `02e4ab7475e8` | aff00f0f8 + variação não commitada |

## Variações do hero

As três trocam só a seção do hero e mantêm os literais travados; o resto da página é o mesmo.

- **A — "Mesa"** (aplicada): `hero-a-mesa_*`, igual byte a byte às capturas de viewport `final_home_*`.
  - É o tabuleiro do menu do contador (`provas-iphone/vt-02-menu-vivo.png`): uma peça de latão para a
    ação, o hub com a marca, azulejos de vidro com numeral e a IA com estado no canto.
  - No celular vira 2+1+1, com o hub entre Decks e Contador.
- **B — "Numeral"**: `hero-b-numeral_*`, build da variação sobre `aff00f0` sem commit.
  - Um card de vidro com o "40" gigante em Fraunces, como o card de jogador na mesa, mais Decks 100 e a
    IA em "Segunda onda". A ação é uma pílula de latão, "Conhecer a beta".
- **C — "Faixa"**: `hero-c-faixa_*`, build da variação sobre `aff00f0` sem commit.
  - Hero tipográfico, com "BrewTact" enorme, o slogan como subtítulo e uma faixa de cinco azulejos com
    estado.

**Recomendação: A.**
- É a única que usa a gramática do contador inteira no primeiro olhar: latão só na ação principal, hub,
  numerais como objeto e estado no canto.
- Mostra o escopo da primeira onda, a IA adiada e a oferta sem precisar rolar.
- Cabe nos dois tamanhos com o `#produto` visível.

A B é a alternativa mais dramática. Ela vale se o dono quiser o contador de vida como protagonista, mas
tira os decks do centro. A C é a mais conservativa e repete a marca que já está no cabeçalho.

<details>
<summary>JSX do hero B ("Numeral"): imports e seção</summary>

```tsx
import {
  AnalysisIcon,
  Azulejo,
  DeckIcon,
  FactTile,
  Hub,
  LifeIcon,
  Numeral,
  StateWord,
  TileLabel
} from "@/components/tiles";

      <section className="relative min-h-[calc(100svh-11rem)] overflow-hidden border-b border-ivory-100/10">
        <Container className="relative flex min-h-[calc(100svh-11rem)] items-center py-8 sm:py-10">
          <div className="grid w-full items-center gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)] lg:gap-12">
            <div className="min-w-0">
              <div className="flex items-center gap-3">
                <Hub className="h-11 w-11">
                  <Image
                    src="/branding/brewtact_mark.svg"
                    alt="BrewTact"
                    width={26}
                    height={26}
                    priority
                    fetchPriority="high"
                    className="h-6 w-6"
                  />
                </Hub>
                <p className="text-[11.5px] font-extrabold uppercase tracking-[0.085em] text-mist-300">
                  Beta gratuita · acesso por convite
                </p>
              </div>
              <h1 className="mt-5 text-balance font-display text-[2.6rem] font-semibold leading-[0.98] text-ivory-100 sm:text-6xl lg:text-[3.6rem] xl:text-[3.75rem]">
                Monte melhor. Jogue melhor.
              </h1>
              <p className="mt-5 max-w-xl text-base leading-7 text-mist-300 sm:text-lg sm:leading-8">
                Deck builder de Commander, coleção privada, catálogo de cartas e contador de vida. A primeira onda entra por convite e sem cobrança; a análise com IA chega na segunda.
              </p>
              <div className="mt-5 flex flex-wrap gap-3 sm:mt-8">
                <AccessPending />
                <ButtonLink href={routes.pricing}>Conhecer a beta</ButtonLink>
              </div>
            </div>

            <div className="grid min-w-0 gap-2 sm:grid-cols-[minmax(0,1.6fr)_minmax(0,1fr)]">
              <div className="relative flex min-h-[208px] flex-col justify-between overflow-hidden rounded-azulejo bg-azulejo px-5 pb-4 pt-4 text-ivory-100 shadow-azulejo sm:row-span-2 sm:min-h-[380px]">
                <div className="flex items-start gap-3">
                  <LifeIcon />
                  <StateWord word="1ª onda" spoken="Primeira onda" />
                </div>
                <Numeral value="40" className="self-center text-[132px] leading-[0.72] tracking-[-0.03em] sm:text-[220px]" />
                <TileLabel>Contador de vida · vida inicial</TileLabel>
              </div>
              <Azulejo label="Decks" icon={<DeckIcon />} numeral="100" className="hidden min-h-[186px] sm:flex" />
              <Azulejo
                label="Análise com IA"
                icon={<AnalysisIcon className="h-[34px] w-[34px] text-mist-500" />}
                state={{ word: "Segunda onda", off: true }}
                className="hidden min-h-[186px] sm:flex"
              />
            </div>
          </div>
        </Container>
      </section>
```

</details>

<details>
<summary>JSX do hero C ("Faixa"): imports e seção</summary>

```tsx
import {
  AnalysisIcon,
  Azulejo,
  CatalogIcon,
  CollectionIcon,
  DeckIcon,
  FactTile,
  Hub,
  LifeIcon,
  Numeral
} from "@/components/tiles";

      <section className="relative min-h-[calc(100svh-11rem)] overflow-hidden border-b border-ivory-100/10">
        <Container className="relative flex min-h-[calc(100svh-11rem)] flex-col justify-center gap-7 py-8 sm:gap-10 sm:py-10">
          <div className="max-w-4xl">
            <div className="flex items-center gap-3">
              <Hub className="h-11 w-11">
                <Image
                  src="/branding/brewtact_mark.svg"
                  alt=""
                  width={26}
                  height={26}
                  priority
                  fetchPriority="high"
                  className="h-6 w-6"
                />
              </Hub>
              <p className="text-[11.5px] font-extrabold uppercase tracking-[0.085em] text-mist-300">
                Beta gratuita · acesso por convite
              </p>
            </div>
            <h1 className="mt-5 font-display text-[4rem] font-semibold leading-[0.9] tracking-[-0.02em] text-ivory-100 sm:text-[6.5rem] lg:text-[8rem]">
              BrewTact
            </h1>
            <p className="mt-3 font-display text-2xl font-semibold text-mist-300 sm:text-3xl">Monte melhor. Jogue melhor.</p>
            <p className="mt-4 max-w-2xl text-base leading-7 text-mist-300 sm:text-lg sm:leading-8">
              Deck builder de Commander, coleção privada, catálogo de cartas e contador de vida. A primeira onda entra por convite e sem cobrança; a análise com IA chega na segunda.
            </p>
            <div className="mt-5 flex flex-wrap gap-3 sm:mt-7">
              <AccessPending />
              <ButtonLink href={routes.pricing}>Conhecer a beta</ButtonLink>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-5">
            <Azulejo label="Decks" icon={<DeckIcon />} numeral="100" className="min-h-[96px] sm:min-h-[112px]" numeralClassName="text-[36px] sm:text-[44px]" />
            <Azulejo label="Coleção" icon={<CollectionIcon />} className="hidden min-h-[112px] sm:flex" />
            <Azulejo label="Catálogo" icon={<CatalogIcon />} className="hidden min-h-[112px] sm:flex" />
            <Azulejo
              label="Contador de vida"
              icon={<LifeIcon />}
              numeral="40"
              className="min-h-[96px] sm:min-h-[112px]"
              numeralClassName="text-[36px] sm:text-[44px]"
            />
            <Azulejo
              label="Análise com IA"
              icon={<AnalysisIcon className="h-[34px] w-[34px] text-mist-500" />}
              state={{ word: "Segunda onda", off: true }}
              className="col-span-2 min-h-[80px] sm:col-span-1 sm:min-h-[112px]"
            />
          </div>
        </Container>
      </section>
```

</details>

## Achados sem aplicar

- **Termos** (`web-public/src/app/legal/terms/page.tsx:22`). Prometem "compartilhar relatórios
  autorizados e analisar decks" sem condição, mas a criação de relatório depende do `gallery_public` e
  a análise está na segunda onda. Redação proposta, sujeita ao advogado:
  > O BrewTact oferece ferramentas para criar e organizar decks e coleções e para acompanhar partidas
  > com o contador de vida. Recursos como análise de decks e compartilhamento de relatórios só ficam
  > disponíveis quando estiverem habilitados para a conta. O usuário é responsável pelo conteúdo que
  > registra e pelas decisões tomadas a partir das recomendações exibidas.
- **Blog** (`web-public/src/app/blog/page.tsx:18`). Diz "continue pelo app para montar decks…" com o
  acesso fechado. Proposta: "Enquanto a área editorial não abre, as novidades da beta aparecem aqui."
- **Sitemap** (`web-public/src/app/sitemap.ts:17`). O `lastModified` é fixo em 2026-08-13; a data do
  build ou a do commit seriam mais corretas.
- **Contrato `.mjs`.** Não roda em nenhum gate. O smoke e o `quality_gate.sh web` chamam lint, build e
  audit, mas não o `npm run test:contract`.
- **Project logic.** O digest vai divergir: é preciso rodar `--write` na integração (quatro arquivos
  gerados fora de `web-public`).
- **Capturas antigas da landing.** As de 2026-08-11
  (`docs/qa/evidence/brewtact_brand_2026-08-11/public_home_*.png`) são anteriores à copy all-OFF. Os
  nomes também mentem: "1440x900" mede 1425×891 e "390x844" mede 375×812. As capturas desta pasta as
  substituem como referência corrente.
- **Metadata PWA do `/app`** (`app/web/manifest.json:8`). Diz "Build, analyze, test, and track"; "test"
  sugere Battle. É do app e está travada por
  `app/test/core/branding/product_identity_contract_test.dart`.
- **Sem uso.** `web-public/src/components/data-visuals.tsx` não é usado e ainda tem uma barra em
  gradiente. A classe `text-mist-400`, que não existia no tema, saiu da home e do pricing.
- **Report** (`reports/[id]/page.tsx`). Mantém eyebrow e borda em latão; os literais do texto são
  travados e o visual ficou fora do escopo.

## Decisões para o dono

1. Qual hero: A (recomendada), B ou C.
2. Como alguém pede convite. Hoje o site não oferece canal, o que segue a D-16 (sem lista de espera);
   um contato público funcionaria na prática como fila.
3. Imagem OG. Não existe. Se entrar, precisa ser PNG estático de 1200×630 em `public/og/`, porque o
   `next/og` não lê woff2 e o `public_web_product_contract_test.dart` proíbe `Inter.ttf` e
   `Fraunces.ttf` em `public/fonts`.
4. Redação dos Termos e do blog (propostas acima).
5. Plugar `npm run test:contract` no smoke e no gate.
6. Se "primeira onda" e "segunda onda" ficam como termos públicos, no lugar de "coorte".
7. Se a nav "Avisos" (antes "IA e dados") fica.

## O que continua aberto

- Integração pela coordenação com os hooks, `--write` do project logic e os testes Dart reais.
- Merge em `master`, deploy do site com a palavra do dono e prova same-SHA na superfície (`BT-REL-002`
  e smoke live).
- TalkBack e teclado real no Web continuam verificações separadas de release.
