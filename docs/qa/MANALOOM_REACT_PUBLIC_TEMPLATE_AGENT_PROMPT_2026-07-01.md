# ManaLoom React Public Template Agent Prompt

Data: 2026-07-01
Uso: copiar e passar para o outro agente que vai gerar o template React/Next.

## Comando base sugerido

Se o agente precisar iniciar o projeto do zero, usar:

```sh
npx create-next-app@latest web-public --ts --tailwind --eslint --app --src-dir --import-alias "@/*"
```

Depois aplicar o prompt abaixo.

## Prompt para o outro agente

```text
Crie o template React/Next.js da camada publica do ManaLoom dentro deste
repositorio, em `web-public/`.

Leia primeiro:
`docs/qa/MANALOOM_WEB_REACT_FLUTTER_HANDOFF_GOAL_2026-07-01.md`

Contexto:
ManaLoom e uma plataforma para Magic: The Gathering com deck builder, IA para
otimizacao de decks, colecao, planos Free/Pro, relatorios compartilhaveis,
historico de partidas, comunidade e trade. O app logado sera Flutter Web em
`/app`. O projeto React/Next sera apenas a camada publica, focada em SEO,
compartilhamento, descoberta e conversao.

Arquitetura:
- `manaloom.com/*`: React/Next publico.
- `manaloom.com/app/*`: Flutter Web logado.
- `server/`: fonte futura de verdade para dados, plano, IA, deck, colecao,
  relatorio, trade, marketplace e permissoes.

Escopo permitido:
- Criar `web-public/`.
- Criar paginas, componentes, estilos, mocks, tipos e README do template
  publico.
- Usar dados mockados bem estruturados, preparados para substituir por API.

Fora de escopo:
- Nao alterar `app/`.
- Nao alterar `server/`.
- Nao escrever em PostgreSQL.
- Nao implementar auth real.
- Nao implementar IA, recomendacao, checkout real ou trade operacional.
- Nao duplicar regra de negocio que deve viver no backend.

Stack:
- Next.js com App Router.
- TypeScript.
- Tailwind CSS.
- Componentes reutilizaveis.
- Metadata SEO por pagina.
- Open Graph para deck e relatorio.
- `sitemap.ts` e `robots.ts`.
- Estrutura pronta para deploy em Vercel ou similar.

Estrutura esperada:
`web-public/README.md`
`web-public/src/app/page.tsx`
`web-public/src/app/pricing/page.tsx`
`web-public/src/app/decks/[id]/page.tsx`
`web-public/src/app/reports/[id]/page.tsx`
`web-public/src/app/players/[id]/page.tsx`
`web-public/src/app/marketplace/page.tsx`
`web-public/src/app/blog/page.tsx`
`web-public/src/app/blog/[slug]/page.tsx`
`web-public/src/app/legal/terms/page.tsx`
`web-public/src/app/legal/privacy/page.tsx`
`web-public/src/app/legal/disclaimer/page.tsx`
`web-public/src/app/sitemap.ts`
`web-public/src/app/robots.ts`
`web-public/src/components/*`
`web-public/src/lib/types.ts`
`web-public/src/lib/mock-data.ts`
`web-public/src/lib/routes.ts`

Paginas obrigatorias:

1. `/`
Landing publica do ManaLoom.
Proposta central: "Construa, otimize e acompanhe decks de Commander com IA."
Deve ter CTA para `/app` e `/pricing`.

2. `/pricing`
Planos Free e Pro.
Mostrar limite de IA, beneficios, upgrade e motivo para pagar.
Nao implementar checkout real. CTA principal deve apontar para `/app` ou
`/app?upgrade=pro`.

3. `/decks/[id]`
Deck publico compartilhavel.
Mostrar comandante, cores, dono, formato, bracket/power, resumo de estrategia,
curva de mana, distribuicao por funcoes, cartas principais e CTA para abrir no
app.

4. `/reports/[id]`
Relatorio publico antes/depois de otimizacao.
Mostrar trocas sugeridas, motivo, funcao, risco, preco estimado, curva, bracket
e impacto esperado. Deve parecer confiavel porque explica a recomendacao.

5. `/players/[id]`
Perfil publico de jogador.
Mostrar decks publicos, estilo de jogo, nivel de mesa e resumo publico de
trade apenas quando houver opt-in no mock.

6. `/marketplace`
Descoberta publica de cartas, decks, listas de troca e oportunidades de trade.
Pode usar mocks. Nao implementar compra/venda real.

7. `/blog`
Lista de artigos indexaveis.

8. `/blog/[slug]`
Post publico usando dados mockados ou estrutura simples.

9. `/legal/terms`
Termos de uso.

10. `/legal/privacy`
Politica de privacidade.

11. `/legal/disclaimer`
Disclaimer sobre IA, precos, cartas, Commander Brackets, propriedade
intelectual e recomendacoes.

Requisitos visuais:
- Produto SaaS/game tool, utilitario e sofisticado.
- Nao fazer landing generica.
- Evitar excesso de cards decorativos.
- Boa hierarquia, leitura rapida e densidade adequada para desktop.
- Mobile responsivo.
- Usar identidade propria do ManaLoom sem copiar marcas, arte, logos ou
  simbolos oficiais de Magic/Wizards.
- Botoes "Abrir app" devem apontar para `/app`.

Requisitos de dados:
- Criar tipos fortes em `src/lib/types.ts`.
- Criar mocks em `src/lib/mock-data.ts`.
- Os mocks devem cobrir:
  - planos Free/Pro;
  - deck publico;
  - relatorio antes/depois;
  - perfil publico;
  - marketplace;
  - posts do blog.
- Nao calcular recomendacao no frontend. Renderizar campos vindos do mock/API.

Requisitos de SEO:
- Metadata por pagina.
- Open Graph para `/decks/[id]` e `/reports/[id]`.
- URLs limpas.
- `sitemap.ts`.
- `robots.ts`.
- Conteudo textual real nas paginas publicas, nao apenas canvas/app shell.

README:
Incluir:
- Como instalar.
- Como rodar localmente.
- Como buildar.
- Estrutura de pastas.
- Como substituir mocks por API.
- Decisao de arquitetura: React publico + Flutter Web em `/app`.
- Proximos passos.

Validacao:
- Rodar lint/build se possivel.
- Informar comandos executados e resultado.
- Se alguma dependencia impedir validacao, explicar claramente.

Criterio de pronto:
- O projeto `web-public/` existe.
- Todas as paginas obrigatorias existem.
- Layout responsivo.
- Dados mockados centralizados.
- Tipos centralizados.
- SEO base implementado.
- CTAs levam para `/app`.
- Nenhuma mudanca fora de `web-public/`, salvo arquivos estritamente
  necessarios de workspace e com justificativa.
```

