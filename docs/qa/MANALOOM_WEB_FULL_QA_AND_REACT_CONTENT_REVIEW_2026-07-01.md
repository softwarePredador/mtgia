# ManaLoom Web Full QA And React Content Review

Data: 2026-07-01

## Escopo

Validacao completa solicitada para:

- Flutter Web em `/app/`.
- Fluxos web com login, boot autenticado, rotas protegidas e deep links.
- Build, analise estatica e testes automatizados do app Flutter.
- Web publica React/Next em `web-public/`.
- Validacao tecnica, responsiva e editorial do conteudo publico React.

## Veredito

Flutter Web esta funcional no corte validado. O erro `RangeError` nao reapareceu nos testes automatizados, no build web, nas chamadas HTTP locais nem na navegacao real em navegador. Tambem foi corrigido um problema adicional encontrado durante a validacao: deep links protegidos eram perdidos enquanto o estado de autenticacao ainda estava carregando.

A web publica React esta tecnicamente saudavel e visualmente interessante, mas ainda nao esta forte o suficiente como produto comercial/publico. Ela apresenta bem a marca e a proposta geral, porem ainda precisa mostrar melhor o diferencial vendavel do ManaLoom: recomendacoes de IA explicaveis por colecao, orcamento, bracket e relatorio antes/depois.

## Evidencia Flutter Web

Comandos executados:

```bash
cd app
flutter test
flutter test --platform chrome test/features/auth/screens/splash_screen_redirect_test.dart test/core/api/api_client_request_id_test.dart test/features/auth/providers/auth_provider_log_sanitization_test.dart test/core/widgets/platform_unavailable_screen_test.dart
flutter analyze
flutter build web --base-href /app/
```

Resultado:

- `flutter test`: passou com 592 testes.
- Testes Chrome/web focados: passaram com 17 testes.
- `flutter analyze`: sem problemas apos ajuste de import desnecessario.
- `flutter build web --base-href /app/`: concluido com sucesso.

Checks HTTP locais em `http://127.0.0.1:8088/app/`:

- `/app/`: HTTP 200.
- `/app/main.dart.js`: HTTP 200.
- `/app/decks`: HTTP 200 com fallback SPA.
- HTML contem `<base href="/app/">`, `flutter_bootstrap.js` e `ManaLoom`.

Checks no navegador:

- Login/boot autenticado carregou sem `RangeError`.
- Logs observados: `/auth/me -> 200`, `/notifications/count -> 200`, `/conversations/unread-count -> 200`, `/decks -> 200`.
- Sentry local apareceu como desabilitado porque nao havia DSN configurado no ambiente local.
- Nenhum erro de console bloqueante foi observado durante os fluxos testados.

## Correcao Aplicada Durante A QA

Problema encontrado:

- Ao abrir uma rota protegida direta, por exemplo `#/life-counter`, o router mandava o usuario para `/` enquanto `AuthStatus` ainda estava em `loading`.
- Depois que a autenticacao terminava, o splash levava para `/home`, perdendo o deep link original.

Arquivos ajustados:

- `app/lib/main.dart`
- `app/lib/features/auth/screens/splash_screen.dart`
- `app/test/features/auth/screens/splash_screen_redirect_test.dart`

Comportamento novo:

- Rotas protegidas acessadas durante o carregamento passam por `/?redirect=<rota-original>`.
- Apos autenticacao, o splash redireciona para a rota original quando ela e segura.
- Rotas inseguras ou sem sentido para pos-login, como `/`, `/login`, `/register`, `https://...` e `//...`, sao descartadas e caem em `/home`.

Validacao manual apos o ajuste:

- URL testada: `http://127.0.0.1:8088/app/?qa=deep-link-fix-20260701#/life-counter`.
- Resultado: rota final permaneceu em `#/life-counter`.
- Tela exibida corretamente no Flutter Web: fallback "Contador disponivel no app mobile".
- Sem `RangeError` e sem erro de console bloqueante.

## Evidencia React/Next

Comandos executados:

```bash
cd web-public
npm run lint
npm run build
npm run dev -- --port 3000
```

Resultado:

- `npm run lint`: passou.
- `npm run build`: passou.
- Next.js gerou 12 rotas estaticas/SSG.
- Servidor local validado em `http://localhost:3000`.

Checks HTTP locais:

- `/`: HTTP 200.
- `/pricing`: HTTP 200.
- `/marketplace`: HTTP 200.
- `/blog`: HTTP 200.
- `/legal/terms`: HTTP 200.
- `/sitemap.xml`: HTTP 200.
- `/blog/teste`: HTTP 404 intencional no estado atual.
- `/reports/demo`: HTTP 404 intencional no estado atual.

Checks responsivos no navegador:

- Home desktop 1280x800: sem overflow horizontal.
- Pricing desktop 1280x800: sem overflow horizontal.
- Home mobile 390x844: sem overflow horizontal.
- Pricing mobile 390x844: sem overflow horizontal.

Observacao tecnica:

- Em ambiente de desenvolvimento, o Next emitiu aviso de LCP para `/branding/home_hero_banner.png`. O impacto e de performance/otimizacao, nao de funcionalidade.

## Avaliacao De Conteudo React

Pontos fortes:

- A identidade visual ja comunica bem ManaLoom: dark premium, cobre/dourado, assets de marca e composicao consistente.
- A home nao parece uma landing generica; mostra produto, decks, comunidade, marketplace e chamadas para o app.
- Os CTAs para `/app` estao presentes e fazem sentido para conversao.
- As paginas legais existem: termos, privacidade e disclaimer.
- SEO basico existe: metadata, sitemap e robots.
- O marketplace usa backend real e filtra dados internos de QA/teste.

Gaps que reduzem atratividade comercial:

- A promessa principal ainda esta generica. O texto fala em construir decks, colecao e trocas, mas nao coloca no centro a IA explicavel por colecao, orcamento, bracket e nivel da mesa.
- A home mostra `0 ofertas ativas` quando o marketplace esta vazio. Isso enfraquece a primeira impressao.
- A tela de pricing ainda nao deixa claro o preco real do Pro. O numero principal visto e `200`, que representa acoes de IA por mes, mas parece preco ou limite sem contexto suficiente.
- `/reports/[id]` ainda retorna 404. Isso bloqueia um diferencial importante: relatorio compartilhavel antes/depois.
- `/blog/[slug]` retorna 404 e `/blog` informa que guias chegam em breve. Isso limita SEO, autoridade e aquisicao organica.
- O sitemap ainda nao lista URLs dinamicas publicas de decks, perfis, relatorios ou artigos.
- O perfil publico contem texto tecnico voltado a desenvolvedor, como referencia a endpoint e ausencia de e-mail/senha. Isso deve virar copy de usuario final.
- A feature de otimizacao leva para disclaimer em vez de levar para uma demonstracao real de relatorio ou upgrade de deck.
- A experiencia visual e polida, mas ainda muito estatica. Para pagina publica de aquisicao, faltam 2 ou 3 microinteracoes ou estados ricos que deem sensacao de produto vivo.

## Prioridade Recomendada

1. Corrigir pricing para deixar claro Free, Pro, preco, limite de IA e motivo do upgrade.
2. Criar uma pagina publica de relatorio demo em `/reports/demo`, com antes/depois, trocas explicadas, curva, preco, risco e bracket.
3. Ajustar hero e secoes principais para vender o diferencial: "melhore com as cartas que voce tem" e "otimize ate R$ 100".
4. Trocar metricas vazias da home por beneficios estaveis quando nao houver dados publicos suficientes.
5. Publicar 3 artigos iniciais no blog e adicionar esses slugs ao sitemap.
6. Transformar copy tecnica de perfis/decks em texto de produto para usuario final.
7. Adicionar sitemap dinamico para decks, jogadores, relatorios e artigos assim que houver slugs publicos confiaveis.

## Criterio De Pronto Atual

Atendido:

- Flutter Web builda, carrega e passa nos testes executados.
- RangeError nao reproduziu.
- Login/boot autenticado validado no navegador.
- Deep link protegido preservado apos correcao.
- React builda, passa lint, responde nas rotas principais e e responsivo nos viewports testados.

Ainda pendente para ficar comercialmente pronto:

- Monetizacao clara no pricing.
- Relatorio compartilhavel publico real.
- Conteudo de blog inicial.
- Sitemap dinamico.
- Copy comercial mais forte para o diferencial de IA.
