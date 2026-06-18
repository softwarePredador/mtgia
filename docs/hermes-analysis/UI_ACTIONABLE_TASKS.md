# Hermes Analysis: UI Actionable Tasks

> Status atual: backlog UI/produto.
> Nao e contrato Hermes runtime. Revalide visualmente no app antes de tratar
> qualquer item como atual.

> Tasks validadas no codigo (origin/master) em 2026-05-28.
> Nenhuma task foi criada por suposicao. Cada uma tem evidencia concreta.

## Life Counter / Lotus — Pendencias Ativas

Baseadas em `docs/TASK_LIFE_COUNTER_PERFEICAO_2026-03-26.md` e validacao no codigo.

### Status atual apos `771c9318`

- **PARTIAL_PROVEN:** mesa 4p, cores por jogador, controles `+/-` visiveis em
  todos os jogadores, radial menu, history overlay, settings overlay e card
  search overlay com resultado real (`Sol Ring`) foram validados por prova viva
  no iPhone Simulator.
- **OPEN:** geometria 2p/3p/4p contra benchmark, centragem otica, hub central,
  DICE overlay, PLAYERS overlay, commander damage, motion final e side-by-side.
- **Regra:** nao marcar Life Counter como DONE sem side-by-side final contra
  benchmark arquivado/goldens atuais e sem documento de freeze. O dump bruto
  antigo `dddddd/` nao e mais fonte operacional versionada.

### LC.1 — Geometria fina 2p/3p/4p nao travada
- **Arquivo:** `app/lib/features/home/life_counter_screen.dart` / `lotus_visual_skin.dart`
- **Status:** OPEN
- **Evidencia:** Task doc seccao 1: "travar proporcoes finais de 2p, 3p e 4p", "revisar gutters, bordas, raios e massa dos quadrantes". Sem commit especifico de travamento de geometria desde a task (2026-03-26); `origin/master` 7329fbbd mantem `life_counter_screen.dart` com 6400 linhas e `lotus_visual_skin.dart` com 1991 linhas.
- **Por que importa:** Base geometrica errada = todo refinamento visual fica em cima de proporcao errada. Afeta a primeira impressao da mesa.
- **Ajuste recomendado:** Revisar largura/altura dos quadrantes em 3p. Verificar se compact ainda comprime mais que o benchmark. Revisar massa visual dos cantos arredondados. Verificar se o centro da mesa respira como no benchmark.
- **Criterio de pronto:** Screenshot lado a lado passa como mesma familia visual. Nenhum quadrante parece "card". A mesa pode ser lida como poster antes de qualquer detalhe.
- **Teste:** Prova visual com screenshot + comparacao com benchmark.

### LC.2 — Centragem otica dos numerais por assento
- **Arquivo:** `app/lib/features/home/life_counter_screen.dart`
- **Status:** OPEN
- **Evidencia:** Task doc seccao 2: "sair de matematicamente centralizado para oticamente correto". Validar quarterTurns atuais por assento. Revisar massa visual de numeros como 7, 10, 23, 41.
- **Por que importa:** Numeros podem parecer centrados no codigo mas tortos a olho. Impacta leitura em todos os assentos.
- **Ajuste recomendado:** Aplicar vieses pequenos por assento e por estado (normal, SET LIFE, takeover, special). Validar em 2p/3p/4p/5p/6p.
- **Criterio de pronto:** Numeros parecem centrados, nao apenas calculados. Nenhuma orientacao parece torta. Leitura obvia em todos os assentos.
- **Teste:** Prova visual em device/simulador.

### LC.3 — Hub central ainda polido demais
- **Arquivo:** `app/lib/features/home/lotus/lotus_visual_skin.dart`
- **Status:** OPEN
- **Evidencia:** Task doc seccao 3: "reduzir o que ainda parece premium product UI". Revisar escala do hexagono central vs petalas. Revisar espessura do contorno e glow. Revisar peso do bloco de ultimo evento. `origin/master` 7329fbbd contem skin Lotus extensa (1991 linhas), mas nao ha side-by-side/freeze que feche este aceite.
- **Por que importa:** O hub deve parecer ferramenta de mesa, nao menu bonito. Contrasta com a tese de mesa brutal/fisica.
- **Ajuste recomendado:** Reduzir brilho premium do centro. Aproximar anatomia do benchmark. Legenda de ultimo evento mais seca.
- **Criterio de pronto:** Hub parece ferramenta de mesa. Leitura de PLAYERS, SETTINGS, HIGH ROLL, RESTART e HELP e imediata. Centro nao compete com quadrantes.
- **Teste:** Prova visual + comparacao com benchmark.

### LC.4 — DICE overlay precisa endurecer
- **Arquivo:** `app/lib/features/home/lotus/lotus_visual_skin.dart`
- **Status:** OPEN
- **Evidencia:** Task doc seccao 4: "endurecer mais DICE". `lotus_visual_skin.dart` em `origin/master` 7329fbbd contem markup/estilos de dice/high roll, mas os commits recentes priorizaram Settings/History/Card Search e nao ha prova de aceite benchmark para DICE. HIGH ROLL deve ser acao primaria dominante do overlay.
- **Por que importa:** Overlay de dado ainda pode parecer "utilitario de app" em vez de ferramenta de mesa.
- **Ajuste recomendado:** HIGH ROLL como acao primaria dominante. D20/COIN/ROLL 1ST como utilitarios secos. Ultimo evento como texto cru.
- **Criterio de pronto:** DICE overlay parece da mesma familia do benchmark. Nenhum elemento parece "card ornamental".
- **Teste:** Prova visual.

### LC.5 — PLAYERS overlay precisa perder acabamento
- **Arquivo:** `app/lib/features/home/lotus/lotus_visual_skin.dart`
- **Status:** OPEN
- **Evidencia:** Task doc seccao 4: "PLAYERS ainda precisa perder acabamento". `lotus_visual_skin.dart` em `origin/master` 7329fbbd contem estilos de players, mas nao ha prova de aceite benchmark/freeze. Deve parecer ferramenta de mesa, nao modal de app.
- **Por que importa:** Overlay de configuracao de jogadores nao deve quebrar a ilusao de mesa fisica.
- **Ajuste recomendado:** Deixar overlay mais seco, menos polido. Remover linguagem residual de "sheet generica".
- **Criterio de pronto:** Overlay parece camada da mesa, nao modal generico.
- **Teste:** Prova visual.

### LC.6 — Commander damage overlay com linguagem residual de adaptacao
- **Arquivo:** `app/lib/features/home/lotus/lotus_visual_skin.dart` / `life_counter_native_commander_damage_sheet.dart`
- **Status:** OPEN / PARTIAL_VISUAL_PROOF
- **Evidencia:** Task doc seccao 7: "reduzir linguagem residual de feature adaptada". `origin/master` 7329fbbd contem CSS/markup de commander damage no Lotus skin, mas sem aceite side-by-side; overlay rapido pode manter cheiro de "counter row" ornamental.
- **Nota:** existe prova viva do overlay, mas ela ainda nao equivale a aceite
  contra benchmark nem revisao de linguagem.
- **Por que importa:** Contadores MTG precisam soar nativos da shell clone, nao como "adaptacao em cima".
- **Ajuste recomendado:** Revisar como poison e tax aparecem no painel sem sujar o clone. Overlay rapido de commander damage com linhas por fonte mais cruas.
- **Criterio de pronto:** Contadores extras convivem com a mesa clone sem quebrar o benchmark. Rapidos. Nao reintroduzem UI de card/painel auxiliar.
- **Teste:** Prova visual + fluxo funcional.

### LC.7 — Motion final: takeover, SET LIFE, KO'D!
- **Arquivo:** `app/lib/features/home/lotus/lotus_visual_skin.dart` / `life_counter_screen.dart`
- **Status:** OPEN
- **Evidencia:** Task doc seccao 8: Motion compartilhado (fade + scale + slide) existe nos overlays. Mas, em `origin/master` 7329fbbd, nao ha documento/prova final revisando duracoes/easing do takeover de High Roll, transicao de SET LIFE e presenca de KO'D! contra o benchmark.
- **Por que importa:** Sem motion final, a tela pode estar viva mas nao no nivel de impacto do benchmark.
- **Ajuste recomendado:** Revisar duracao/easing do takeover de High Roll. Revisar entrada/saida dos overlays. Revisar transicao de SET LIFE. Revisar presenca de KO'D! e lethal states.
- **Criterio de pronto:** Motion melhora leitura. Visivel em gravacao curta. Nao parece ornamental.
- **Teste:** Prova visual gravada + comparacao com benchmark.

### LC.8 — Side-by-side final com benchmark + freeze
- **Arquivo:** `app/doc/runtime_flow_handoffs/` / novo documento
- **Status:** OPEN / RELEASE_GATE
- **Evidencia:** Task doc seccao Fase E: "side-by-side final com benchmark". O dump bruto antigo com capturas do benchmark foi removido do versionamento; nao ha documento de comparacao visual publicado desde 2026-03-26 usando goldens atuais ou artefato arquivado.
- **Por que importa:** Sem comparacao direta, nao e possivel provar que o clone esta no nivel aceitavel.
- **Ajuste recomendado:** Gerar screenshots do estado atual, comparar com benchmark arquivado/goldens atuais. Documentar discrepancias. Congelar aceite.
- **Criterio de pronto:** Documento de side-by-side publicado. Todos os 8 gaps acima fechados ou aceitos como "risco aceito". Life counter marcado como DONE.
- **Teste:** Screenshots + documento comparativo.

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
- **Evidencia:** validacao em `origin/master` 7329fbbd confirmou
  `app/lib/features/community/screens/community_screen.dart` com 1729 linhas,
  14 classes, 9 `Widget build`, 4 tabs principais (Explorar, Seguindo,
  Usuarios, Cotacoes) + sub-tabs dentro de Cotacoes. Mistura feed de decks,
  feed de seguidores, busca de usuarios e cotacoes de mercado em um unico
  arquivo. Nao ha teste de widget unitario para `CommunityScreen`; ha cobertura
  runtime em `app/integration_test/profile_community_runtime_test.dart`.
- **Por que importa:** Tela de 1729 linhas com tabs aninhadas e multiplos dominios e dificil de testar, dar manutencao e evolucionar sem risco de regressao.
- **Ajuste recomendado:** Quebrar em widgets de tab dedicados em arquivos separados: `_ExploreTab`, `_FollowingFeedTab`, `_UserSearchTab`, `_MarketMoversTab` para `community_tabs/` ou similar.
- **Criterio de pronto:** Tela abaixo de 600 linhas, tabs em arquivos separados. Navegacao entre tabs intacta.
- **Teste:** Teste de widget para pelo menos a tab principal (Explorar).

### P1.3 ProfileScreen sem baseline visual apos refatoracao
- **Arquivo:** `app/lib/features/profile/profile_screen.dart`
- **Evidencia:** validacao em `origin/master` 7329fbbd confirmou `app/lib/features/profile/profile_screen.dart` com 590 linhas. Existe teste funcional (`app/test/features/profile/profile_screen_test.dart`) cobrindo edicao/refresh de dados, mas nao ha golden/baseline visual da refatoracao Onda 6.
- **Por que importa:** Tela de alta visibilidade (tab 4 do bottom nav). Qualquer regressao visual na apresentacao do perfil e estado do usuario impacta percepcao de produto premium.
- **Ajuste recomendado:** Manter o teste funcional existente e adicionar golden/baseline visual ou snapshot focado que verifique avatar, display name, stats, botoes de atalho e aderencia aos tokens do AppTheme.
- **Criterio de pronto:** Baseline visual/golden de ProfileScreen criado, revisado e verde.
- **Teste:** `profile_screen_test.dart` mantido verde + novo golden/snapshot revisado.

### P1.4 binder_screen grande e cobertura de widget ainda parcial
- **Arquivos:** `app/lib/features/binder/screens/binder_screen.dart` (1628 linhas), `app/lib/features/binder/screens/marketplace_screen.dart` (566 linhas)
- **Evidencia:** ambos sao "tab content" widgets embutidos no `CollectionScreen` e nao tem Scaffold/AppBar proprios; isso e intencional no hub atual. Validacao em `origin/master` 7329fbbd confirmou `binder_screen.dart` com 1628 linhas e TabBar interno (2 sub-tabs). `marketplace_screen.dart` caiu para 566 linhas e ja possui teste de widget em `app/test/features/binder/screens/marketplace_screen_overflow_test.dart` cobrindo overflow e estados loading/error/empty.
- **Por que importa:** O maior risco restante e `binder_screen.dart`: 1628 linhas, sub-tabs e editor/listas ainda podem regredir sem teste de widget dedicado. A ausencia de AppBar propria e decisao de arquitetura do hub, nao bug isolado.
- **Ajuste recomendado:** Nao mexer na estrutura do hub sem decisao de produto. Adicionar teste de widget para `BinderTabContent` com dados mockados; manter/expandir o teste existente de `MarketplaceTabContent` conforme novos estados surgirem.
- **Criterio de pronto:** Teste de widget para `BinderTabContent` existe e passa; cobertura de Marketplace permanece verde.
- **Teste:** novo teste de binder tab + `marketplace_screen_overflow_test.dart` verde.

### P1.5 ChatScreen mascara falha de carregamento como conversa vazia
- **Arquivo:** `app/lib/features/messages/screens/chat_screen.dart`; `app/lib/features/messages/providers/message_provider.dart`
- **Evidencia:** `MessageProvider.fetchMessages` grava `_error = 'Não foi possível carregar as mensagens.'` em falha HTTP e `_error = '$e'` em exception (`message_provider.dart` linhas 347-357). `ChatScreen` trata apenas loading e `provider.messages.isEmpty`; quando ha erro com lista vazia, renderiza `AppStatePanel` com key `chat-empty-state` e titulo `Conversa pronta` (`chat_screen.dart` linhas 147-161). Busca em `app/test` por `ChatScreen|chat-empty-state|chat-message-field` retornou 0 ocorrencias.
- **Por que importa:** Falhas de API/rede em uma conversa podem aparecer para o usuario como chat vazio/pronto, escondendo outage e contexto perdido de trades/mensagens.
- **Ajuste recomendado:** Adicionar branch de erro antes do empty state quando `provider.error != null && provider.messages.isEmpty`, com copy amigavel, retry e key estavel `chat-error-state`.
- **Criterio de pronto:** Falha de carregamento mostra erro, nao empty state; retry refaz `fetchMessages`.
- **Teste:** Widget test com provider/API fake falhando valida `chat-error-state`, ausencia de `chat-empty-state` e retry.

### P1.6 ChatScreen limpa o rascunho antes de confirmar envio
- **Arquivo:** `app/lib/features/messages/screens/chat_screen.dart`; `app/lib/features/messages/providers/message_provider.dart`
- **Evidencia:** `_sendMessage` le o texto e limpa `_messageController` antes de aguardar `sendMessage` (`chat_screen.dart` linhas 69-80). `MessageProvider.sendMessage` retorna `false` para status nao-201 ou exception, sem expor feedback de erro para UI (`message_provider.dart` linhas 375-400). O campo e o botao ja tem keys `chat-message-field` e `chat-message-send-button` (`chat_screen.dart` linhas 200-228), mas nao ha teste de falha de envio.
- **Por que importa:** Em falha de rede/API, o usuario perde o texto digitado sem feedback visivel, especialmente sensivel em negociacoes de troca.
- **Ajuste recomendado:** Limpar o campo apenas apos `sendMessage == true`, ou restaurar o rascunho em falha; mostrar SnackBar/erro inline e considerar `sendError` amigavel no provider.
- **Criterio de pronto:** Falha preserva/restaura texto e mostra feedback; sucesso limpa o campo e insere/superficie a mensagem.
- **Teste:** Widget test com `sendMessage` fake falhando e passando.

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
- **Evidencia:** validacao em `origin/master` 7329fbbd encontrou 68 ocorrencias de `Color(0x...)` e 134 de `Colors.` em `life_counter_screen.dart` (ex.: linhas 108-113 com acentos de jogador; linhas 550/884/893/912 com scrims/fundos). O Lotus WebView ja recebeu `lotus_visual_skin.dart`, mas a tela/engine Flutter nativa continua com tokens locais/hardcoded.
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

### P2.4 TradeDetailScreen grande, mas com cobertura de widget parcial
- **Arquivo:** `app/lib/features/trades/screens/trade_detail_screen.dart`
- **Evidencia:** validacao em `origin/master` 7329fbbd confirmou 1479 linhas. Existe cobertura de widget em `app/test/features/trades/screens/trade_confirmation_flow_test.dart`, que renderiza `TradeDetailScreen` com provider fake e cobre confirmacao de aceite/entrega; tambem ha runtime em `binder_marketplace_trade_runtime_test.dart`. Ainda nao ha teste basico cobrindo layout completo de status, itens, timeline/chat/trust.
- **Por que importa:** Tela de troca e uma das mais complexas do app. A cobertura atual protege fluxos de acao, mas nao baseline amplo de apresentacao.
- **Ajuste recomendado:** Adicionar teste de widget basico que renderize a tela com dados mockados e verifique presenca dos elementos principais (status, itens, chat/timeline/trust), sem substituir os testes de confirmacao existentes.
- **Criterio de pronto:** Teste de layout/estado para TradeDetailScreen criado e verde.
- **Teste:** novo `trade_detail_screen_test.dart` ou expansao segura de `trade_confirmation_flow_test.dart`.

### P2.5 Market screen/provider sem cobertura deterministica de estados e cache
- **Arquivo:** `app/lib/features/market/screens/market_screen.dart`; `app/lib/features/market/providers/market_provider.dart`
- **Evidencia:** `MarketScreen` dispara `fetchMovers()` no primeiro frame (`market_screen.dart` linhas 21-27) e possui branches de loading, erro, empty, `needsMoreData`, abas gainers/losers e refresh (`market_screen.dart` linhas 86-128, 197-317). `MarketProvider` tem cache TTL de 5 minutos, erro HTTP/exception, refresh e clear state (`market_provider.dart` linhas 21-78). Busca em `app/test` encontrou apenas testes de modelo `CardMover` e uso indireto de `MarketProvider` em `home_screen_test.dart`; nao ha `MarketScreen`/`MarketProvider` unit-widget dedicado.
- **Por que importa:** Regressao em loading/retry/empty/needs-data/tab switching/cache/refresh pode passar sem rede deterministica; smoke live pode falhar por ambiente ou passar sem cobrir branches.
- **Ajuste recomendado:** Adicionar unit tests de `MarketProvider` com `ApiClient` fake e widget tests de `MarketScreen` para loading, erro+retry, empty, needs-data, gainers/losers, refresh; adicionar keys como `market-loading`, `market-error`, `market-empty`, `market-needs-data`, `market-gainers-list`, `market-losers-list`, `market-mover-card-<cardId>`.
- **Criterio de pronto:** Estados principais cobertos sem rede live; runtime smoke continua apenas como prova complementar.
- **Teste:** Novos testes unit/widget + `flutter analyze`.

## P3 — Melhoria futura

### P3.1 MainScaffold NavigationBar sem backgroundColor explicito
- **Arquivo:** `app/lib/core/widgets/main_scaffold.dart`
- **Evidencia:** O NavigationBar nao define backgroundColor — depende do `NavigationBarThemeData` no AppTheme. Funciona, mas qualquer mudanca no tema pode afetar a barra sem aviso.
- **Ajuste:** Adicionar `backgroundColor: AppTheme.surfaceSlate` explicito no NavigationBar, igualando ao valor do tema.
- **Criterio de pronto:** NavigationBar com backgroundColor explicito.

### P3.2 ProfileScreen (590 linhas) nao tem golden test
- **Arquivo:** `app/lib/features/profile/profile_screen.dart`
- **Evidencia:** Refatorado na Onda 6; validacao em `origin/master` 7329fbbd confirmou 590 linhas e ausencia de golden test. HomeScreen tem golden, ProfileScreen nao.
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
| **MessageInboxScreen / ChatScreen** | Inbox tem teste de erro/lista; ChatScreen agora tem tasks P1 para erro de carregamento e falha de envio. |
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
