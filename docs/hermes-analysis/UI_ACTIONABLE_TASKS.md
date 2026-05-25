# Hermes Analysis: UI Actionable Tasks

> Tasks validadas no codigo (origin/master) em 2026-05-25.
> Nenhuma task foi criada por suposicao. Cada uma tem evidencia concreta.

## P1 — Precisa antes de release/core polish

### P1.1 deck_details_screen.dart ainda grande demais
- **Arquivo:** `app/lib/features/decks/screens/deck_details_screen.dart`
- **Evidencia:** 1705 linhas, 19 classes/methods. Apesar de ter caido de 3200+, ainda concentra AppBar, TabBar (3 abas: Visao Geral, Cartas, Analise), orquestracao de optimize, rebuild, botoes de acao e estado do deck.
- **Por que importa:** Tela critica do fluxo core. Qualquer bug aqui impacta diretamente a experiencia de produto. Arquivos grandes aumentam risco de regressao escondida.
- **Ajuste recomendado:** Extrair o TabBar + corpo (TabBarView) para um `DeckDetailsTabbedBody` widget dedicado. Extrair botoes de acao (otimizar, menu, etc.) para `DeckDetailsActionsBar`. Manter na tela apenas o AppBar + scaffold + estado mestre.
- **Criterio de pronto:** Tela abaixo de 800 linhas. `flutter analyze` verde. Smoke test da tela continua passando.
- **Teste:** `deck_details_screen_smoke_test.dart` deve continuar verde.

### P1.2 community_screen.dart com complexidade alta
- **Arquivo:** `app/lib/features/community/screens/community_screen.dart`
- **Evidencia:** 1725 linhas, 40 classes/methods. 4 tabs principais (Explorar, Seguindo, Usuarios, Cotacoes) + sub-tabs dentro de Cotacoes. Mistura feed de decks, feed de seguidores, busca de usuarios e cotacoes de mercado em um unico arquivo. Foi refatorado (+504/-367) mas continua muito denso.
- **Por que importa:** Telas com 40 classes internas sao dificeis de testar, dar manutencao e evolucionar sem risco de regressao.
- **Ajuste recomendado:** Quebrar em widgets de tab dedicados em arquivos separados: `_ExploreTab`, `_FollowingFeedTab`, `_UserSearchTab`, `_MarketMoversTab` para `community_tabs/` ou similar.
- **Criterio de pronto:** Tela abaixo de 600 linhas, tabs em arquivos separados. Navegacao entre tabs intacta.
- **Teste:** Teste de widget para pelo menos a tab principal (Explorar).

### P1.3 ProfileScreen sem baseline visual apos refatoracao
- **Arquivo:** `app/lib/features/profile/profile_screen.dart`
- **Evidencia:** Foi refatorado na Onda 6 (+388/-214, 588 linhas atuais). Nao ha golden test e o teste existente (`profile_screen_test.dart`) nao cobre layout visual.
- **Por que importa:** Tela de alta visibilidade (tab 4 do bottom nav). Qualquer regressao visual na apresentacao do perfil e estado do usuario impacta percepcao de produto premium.
- **Ajuste recomendado:** Adicionar teste de widget que verifique a presenca dos elementos principais (avatar, display name, stats, botoes de atalho). Verificar se cores/espacamentos seguem os tokens do AppTheme (nao tem hardcoded colors, mas nao custa confirmar).
- **Criterio de pronto:** Teste de widget para ProfileScreen criado e verde.
- **Teste:** `profile_screen_test.dart` ampliado com asserts de layout.

### P1.4 binder_screen + marketplace_screen sem AppBar proprio
- **Arquivos:** `app/lib/features/binder/screens/binder_screen.dart` (1628 linhas), `app/lib/features/binder/screens/marketplace_screen.dart` (851 linhas)
- **Evidencia:** Ambos sao "tab content" widgets embutidos no `CollectionScreen`. Nao tem Scaffold nem AppBar proprios. Isso e intencional (documentado em comentario), mas significa que qualquer rota direta para essas telas ficaria sem AppBar. O `binder_screen` tem seu proprio `TabBar` interno (2 sub-tabs), e `marketplace_screen` tem filtros e busca.
- **Por que importa:** Se no futuro alguem quiser navegar diretamente para `/binder` ou `/market`, nao tera AppBar. O `binder_screen` com 1628 linhas e TabBar interno merece seu proprio teste de widget.
- **Ajuste recomendado:** Nao mexer na estrutura (e intencional). Adicionar teste de widget para `BinderTabContent` e `MarketplaceTabContent` que verifique a renderizacao basica com dados mockados.
- **Criterio de pronto:** Testes de widget para ambos existem e passam.
- **Teste:** Novo teste para binder tab + marketplace tab.

### P1.5 community_screen AppBar fontWeight 800 foge do padrao
- **Arquivo:** `app/lib/features/community/screens/community_screen.dart`
- **Evidencia:** O AppBar da community_screen define `titleTextStyle` com `fontWeight: FontWeight.w800`, enquanto o tema define `w700` no AppBarTheme. O tema Onda 6 define AppBar com Fraunces w700. O w800 e um desvio.
- **Por que importa:** Inconsistencia visual entre telas. O titulo da Community aparece mais pesado que o resto do app.
- **Ajuste recomendado:** Remover o `titleTextStyle` override do AppBar e deixar o tema resolver. Se o Fraunces w700 do tema nao ficar bom, ajustar o tema (nao o override local).
- **Criterio de pronto:** AppBar usa o tema, w800 removido. Visualmente consistente com DeckList, Profile, etc.
- **Teste:** Verificacao visual ou snapshot.

## P2 — Importante, mas nao bloqueia

### P2.1 TabBar overrides redundantes em 4 arquivos
- **Arquivos:** `collection_screen.dart`, `binder_screen.dart`, `trade_inbox_screen.dart`, `community_screen.dart`
- **Evidencia:** Todos explicitam `indicatorColor: AppTheme.brass400`, `labelColor: AppTheme.brass400`, `unselectedLabelColor: AppTheme.textSecondary` — valores IDENTICOS aos definidos no `AppTheme.tabBarTheme`. Apenas `collection_screen.dart` tem `labelPadding: EdgeInsets.zero` e `isScrollable: false` que realmente diferem do tema.
- **Por que importa:** Manutencao futura do tema exige mudar em 5 lugares em vez de 1. Risco de uma tela ficar desalinhada se esquecer de atualizar o override.
- **Ajuste recomendado:** Remover overrides que sao identicos ao tema nos 4 arquivos. Manter apenas `dividerColor: AppTheme.transparent` (que e um comportamento especifico) e `labelPadding`/`isScrollable` onde diferem.
- **Criterio de pronto:** TabBars visualmente identicos, mas sem os overrides redundantes. `flutter analyze` verde.
- **Teste:** Verificacao visual (snapshot ou runtime).

### P2.2 life_counter_screen.dart com cores hardcoded no Flutter nativo
- **Arquivo:** `app/lib/features/home/life_counter_screen.dart`
- **Evidencia:** validacao local em 2026-05-25 encontrou muitas referencias
  `Color(0x...)` e `Colors.` no arquivo. O Lotus WebView ja recebeu
  `lotus_visual_skin.dart`, mas a tela/engine Flutter nativa continua com tokens
  locais/hardcoded.
- **Por que importa:** Se a experiencia nativa for usada ou alterada sem passar
  pelo Lotus skin, pode divergir do Premium Visual System.
- **Ajuste recomendado:** Nao converter mecanicamente todas as cores para
  `AppTheme`, porque parte delas representa cor de jogador/efeito de jogo.
  Separar em constantes semanticas locais ou tokens especificos de Life Counter:
  player accent, poison, commander damage, overlay scrim, glass border.
- **Criterio de pronto:** cores intencionais nomeadas e centralizadas; nenhum
  `Color(0x...)` disperso em widgets; prova viva de mesa, menus, overlays,
  settings e busca.
- **Teste:** verificacao estatica + prova viva no iPhone Simulator.

### P2.3 Navegacao tab 2 agrupa 3 modulos sob mesmo rotulo
- **Arquivo:** `app/lib/core/widgets/main_scaffold.dart`, `app/lib/features/collection/screens/collection_screen.dart`
- **Evidencia:** A tab "Colecao" (indice 2) engloba Fichario, Marketplace, Trades e Colecoes. Clicar no bottom nav sempre leva para `/collection`, mesmo se o usuario estava em `/trades`. O usuario precisa lembrar que Trades esta dentro de Colecao. A home tambem tem atalhos para "Marketplace" e "Trades" que vao direto para `/market` e `/trades` — mas estes ficam sem destaque no bottom nav.
- **Por que importa:** UX confusa. O usuario que receber uma notificacao de trade e for para `/trades` nao ve o bottom nav destacar "Trades" — ve "Colecao" destacado.
- **Ajuste recomendado:** Duas abordagens possiveis: (1) Criar tab dedicada para Trades como 5a tab (mas o bottom nav ja tem 5); (2) Manter como esta mas garantir que o bottom nav mostre "Colecao" destacado quando estiver em `/trades` ou `/market` (ja funciona). Documentar a decisao de design.
- **Criterio de pronto:** Decisao documentada. Navegacao funcional e previsivel.
- **Teste:** Teste de integracao de navegacao.

### P2.4 TradeDetailScreen (1479 linhas) sem teste de widget
- **Arquivo:** `app/lib/features/trades/screens/trade_detail_screen.dart`
- **Evidencia:** 1479 linhas, 142 references a AppTheme (usa bem o tema), mas nao ha teste de widget dedicado. So existem testes de provider e fluxo de confirmacao.
- **Por que importa:** Tela de troca e uma das mais complexas do app (status, timeline, chat, trust, itens). Sem teste, regressao pode passar.
- **Ajuste recomendado:** Adicionar teste de widget basico que renderize a tela com dados mockados e verifique a presenca dos elementos principais (status, itens, chat).
- **Criterio de pronto:** Teste de widget para TradeDetailScreen criado e verde.
- **Teste:** `trade_detail_screen_test.dart` com mock de provider.

## P3 — Melhoria futura

### P3.1 MainScaffold NavigationBar sem backgroundColor explicito
- **Arquivo:** `app/lib/core/widgets/main_scaffold.dart`
- **Evidencia:** O NavigationBar nao define backgroundColor — depende do `NavigationBarThemeData` no AppTheme. Funciona, mas qualquer mudanca no tema pode afetar a barra sem aviso.
- **Ajuste:** Adicionar `backgroundColor: AppTheme.surfaceSlate` explicito no NavigationBar, igualando ao valor do tema.
- **Criterio de pronto:** NavigationBar com backgroundColor explicito.

### P3.2 ProfileScreen (588 linhas) nao tem golden test
- **Arquivo:** `app/lib/features/profile/profile_screen.dart`
- **Evidencia:** Refatorado na Onda 6, sem golden test. HomeScreen tem golden, ProfileScreen nao.
- **Ajuste:** Adicionar golden test para ProfileScreen similar ao da Home.
- **Criterio de pronto:** Golden test passando com baseline revisada.

## Sem task por enquanto

| Area | Motivo |
|------|--------|
| **Auth (splash/login/register)** | Refatorados na Onda 6 com AuthVisualShell. Zero hardcoded colors. AppTheme OK (13-18 refs). Testes existem. |
| **HomeScreen** | Golden test adicionado. AppTheme 100 refs. Layout OK. |
| **DeckListScreen** | AppTheme 149 refs. AppBar segue padrao tema. Testes existem. |
| **DeckGenerateScreen / DeckImportScreen** | AppTheme 42-48 refs. Layout OK. |
| **DeckDetailsOverviewTab** | 93 refs AppTheme, componentes extraidos, teste dedicado existe. |
| **DeckAnalysisTab** | 74 refs AppTheme, functional tags integradas, teste existe. |
| **DeckOptimizeSheetWidgets / DeckOptimizeFlowSupport** | Widgets extraidos da tela principal. Estrutura OK. |
| **CollectionScreen** | 98 linhas, hub simples com 4 tabs. Navegacao funciona. |
| **MessageInboxScreen / ChatScreen** | AppTheme OK (28-26 refs), teste de tela existe para inbox. |
| **NotificationScreen** | AppTheme OK (32 refs), teste de tela existe. |
| **MainScaffold** | 91 linhas, simples. NavigationBar theme configurado no AppTheme. |
| **AppTheme** | 609 linhas, tema completo (AppBar, TabBar, NavigationBar, FilledButton, font scale). |
| **LotusVisualSkin** | CSS, fora do escopo do tema Flutter. Skin premium por jogador ja aplicada. |
| **LifeCounter tests** | 20+ arquivos de teste. Cobertura excelente. |

## Pontos que precisam inspecao manual

| Ponto | Onde | Por que |
|-------|------|---------|
| HomeScreen hero golden test | `app/test/features/home/home_screen_test.dart` | Precisa rodar localmente com Flutter para ver se a baseline PNG (`home_hero_sma135m.png`) esta atualizada |
| CommunityScreen 4 tabs | `community_screen.dart` linhas 85-88 | Nao ha (e dificil ter) teste de widget para tabs aninhadas. Precisa de runtime manual no simulador |
| TradeDetailScreen chat + timeline | `trade_detail_screen.dart` | Tela de 1479 linhas com chat, timeline, status, itens, trust. Teste automatizado complexo — validacao manual recomendada |
| BinderItemEditor | `binder_item_editor.dart` (1025 linhas) | Editor com foil, trade/sale, price, condition, quantity, notes. Sem teste de widget. Validacao manual. |
| LifeCounter cores hardcoded vs theme | `life_counter_screen.dart`, `lotus_visual_skin.dart` | Separar risco nativo Flutter do Lotus WebView. Lotus precisa de prova viva; nativo precisa de tokens semanticos ou excecao documentada. |
| NavigationBar backgroundColor sem Container | `main_scaffold.dart` | O Container ao redor do NavigationBar adiciona borda superior mas nao cor de fundo. O NavigationBar usa o tema como fundo. Verificar se a cor do Container interfere |
| Community inner sub-tab (Cotacoes) | `community_screen.dart` linha 1350 | Sub-TabBar dentro de Cotacoes com Valorizando/Desvalorizando. Navegacao aninhada pode ser confusa. Validacao UX manual |
