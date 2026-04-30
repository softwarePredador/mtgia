# ManaLoom UX Psychology Design Audit — 2026-04-30

## Patch status — P1 visual fora de Trades — 2026-04-30 14:58 -0300

Sprint visual P1 aplicada fora de Trades, preservando contratos JSON, rotas backend, meta pipeline, scanner/OCR, Life Counter/Lotus, secrets, assets oficiais de MTG e release builds.

| Finding | Status | Evidência |
| --- | --- | --- |
| UX-001 Theme inconsistency | `parcial` | Home, Deck Detail, Generate/Optimize, Binder, Marketplace, Search/Cards, Sets/Coleções e Collection hub migraram call-sites tocados para semântica `brass500/brass400` como ação/valor e `frost400` como IA/suporte/filtro. Aliases legados ainda existem em módulos não tocados. |
| UX-007 Home CTA hierarchy | `resolvido` | Home reorganizada por intenção: `Jogar agora`, `Construir deck`, `IA de decks`, `Minha coleção`, `Trocas e mercado`, com copy curta e CTA menos sobrecarregado. |
| UX-014 Optimize AI explainability | `parcial` | `OptimizationPreviewDialog` ganhou bloco `Controle antes de aplicar` com plano, quantidade de mudanças, cartas depois e terrenos; botão técnico aparece só em debug e foi renomeado para `Copiar relatório técnico`. |
| UX-015 Optimize debug copy | `resolvido` | `Copiar debug` não aparece fora de `kDebugMode`; copy final é menos técnica. |
| UX-017 Binder collection progress | `parcial` | Fichário ganhou `Resumo da coleção` com total, únicas, duplicadas, troca, venda e valor estimado quando stats já existem. |
| UX-018 Marketplace trust hierarchy | `resolvido` | Marketplace ganhou header de confiança, filtros mais legíveis, cards com quantidade, condição, idioma, set, preço, owner/localização/notas e CTA `Propor troca/compra`. |
| UX-023 Search/Cards + Coleções discovery | `parcial` | Search mantém tabs `Cartas`/`Coleções`, melhora empty state para explicar busca mínima e runtime iPhone 15 provou busca de coleções e detalhe via backend real. Decisão de produto sobre Search global continua P2/P3. |
| UX-026 Contrast/token risk | `parcial` | Foregrounds `Colors.white` em CTAs tocados foram removidos onde geravam contraste ruim; `DeckMetaChip` agora trunca texto para evitar overflow em largura estreita. Auditoria global de contraste permanece pendente. |

Validação executada:

| comando | resultado |
| --- | --- |
| `cd app && flutter analyze lib/features/home lib/features/decks lib/features/cards lib/features/collection lib/features/binder lib/features/market lib/core test --no-version-check` | `PASS`, sem issues. |
| `cd app && flutter test test/features/home test/features/decks test/features/cards test/features/collection test/features/binder test/features/market test/core --no-version-check` | `PASS`, `00:23 +463: All tests passed!`. |
| `flutter devices` | iPhone 15 Simulator disponível: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`. |
| `xcrun simctl list devices available \| grep -E "iPhone 15\|Booted"` | iPhone 15 `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` Booted. |
| `cd server && PORT=8082 dart run .dart_frog/server.dart` + `curl -sS --max-time 5 http://127.0.0.1:8082/health` | `PASS`, backend temporário healthy em `http://127.0.0.1:8082`. |
| `cd app && flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | `PASS`, `00:18 +1: All tests passed!`. |

Runtime iPhone 15 provou UI real + backend real para Search/Cards -> Coleções: `GET /cards?name=Black+Lotus 200`, `GET /sets 200`, `GET /sets?q=ECC 200`, `GET /cards?set=ECC 200`. Evidências: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_visual_p1/` e handoff `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-04-30.md`.

Pendências P2/P3 reais: decisão de produto para Search global e Meta Deck Intelligence surface; prova visual/screenshot de Home/Deck Detail/Generate/Binder/Marketplace em device; auditoria global de aliases legados fora dos módulos tocados; Life Counter/Lotus e Scanner seguem fora de escopo desta sprint. Follow-up de Scanner em 2026-04-30 corrigiu a resolução de tokens (`Phyrexian Horror`) no app/backend, mas a prova física final ainda exige reteste com a ficha isolada no guia.

## Patch status — P1 UX trust/errors/trades — 2026-04-30 12:12 -0300

Sprint aplicada no app sem alterar contratos JSON, providers externos, endpoints, rotas backend, Life Counter/Lotus, Sets pipeline, meta pipeline, optimize/generate core, scanner ou FCM.

| Finding | Status | Evidência |
| --- | --- | --- |
| UX-001 Theme inconsistency | `parcial` | Trades/CreateTrade/TradeDetail migraram usos seguros de `manaViolet`, `primarySoft`, `mythicGold` e `Colors.white` para `brass500/brass400/frost400/textPrimary/backgroundAbyss`; aliases legados ainda existem em outros módulos fora do escopo cirúrgico. |
| UX-002 Sets/Coleções raw errors | `resolvido` | `SetsCatalogScreen` e `SetCardsScreen` usam `FriendlyErrorMapper`; estados/snackbars não exibem `Exception`, status code bruto ou `RequestOptions`. |
| UX-003 Auth raw errors | `resolvido` | `AuthProvider` mapeia login/register/profile para mensagens amigáveis e mantém `AppObservability.captureProviderException` com contexto técnico sanitizado. |
| UX-004 Generate AI raw errors | `resolvido` | `DeckGenerateScreen` usa mapper para falha de geração/salvamento; `DeckProvider`/helpers de deck também evitam status code cru em detalhes/validação/mutações tocadas. |
| UX-005 Trade critical actions | `resolvido` | `TradeDetailScreen` exige confirmação contextual para aceitar, recusar, cancelar, confirmar entrega, finalizar e disputar; envio agora inclui confirmação com método/rastreio e consequência. |
| UX-019 Trades raw errors | `resolvido` | `TradeProvider`, `CreateTradeScreen` e `TradeDetailScreen` mapeiam falhas de proposta/status/mensagem para copy amigável. |
| UX-026 Contrast/token risk | `parcial` | Fluxos de Trades tocados evitam `Colors.white` em CTA Brass e usam `frost400` para texto/acento suportivo; auditoria global de contraste permanece pendente fora de Trades. |

Validação executada:

| comando | resultado |
| --- | --- |
| `cd app && flutter analyze lib/features/auth lib/features/decks lib/features/collection lib/features/trades lib/features/binder lib/features/market lib/core test --no-version-check` | `PASS`, sem issues. O warning preexistente em `test/features/community/providers/social_provider_test.dart` foi removido de forma neutra. |
| `cd app && flutter test test/features/auth test/features/decks test/features/collection test/features/trades test/features/binder test/features/market test/core --no-version-check` | `PASS`, `01:02 +178: All tests passed!`. |
| `flutter devices` + `xcrun simctl list devices available \| grep -E "iPhone 15\|Booted"` | iPhone 15 Simulator real encontrado: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, Booted. |
| `curl -sS --max-time 5 http://127.0.0.1:8082/health` | `not run runtime`: backend 8082 recusou conexão (`curl: (7) Failed to connect`). |
| Follow-up `PORT=8082 dart run .dart_frog/server.dart` + `/health` | `PASS`: backend temporario ficou healthy em 8082. |
| Follow-up `flutter analyze integration_test/binder_marketplace_trade_runtime_test.dart --no-version-check` | `PASS`: harness atualizado para confirmar `Revisar proposta`, `Aceitar trade?`, `Confirmar entrega?` e `Finalizar trade?`. |
| Follow-up `flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" ...` | `BLOCKED`: build iOS Simulator falhou antes do app abrir por link de `Pods/MLImage.framework/MLImage` compilado para `iOS` ao buildar `iOS-simulator`. |

Runtime Social Trading iPhone 15 (`integration_test/binder_marketplace_trade_runtime_test.dart`) saiu de `not run por backend indisponivel` para `blocked by simulator build`. Menor próxima ação: resolver/contornar o link do MLKit/MLImage no simulador ou rodar o mesmo teste em device iOS físico, mantendo backend 8082 healthy.

## Executive summary

- **Visão geral:** auditoria first-pass estática do ManaLoom cobrindo design system, navegação, Home, Auth, busca/cartas, coleções, scanner, Life Counter/Lotus, decks Commander, geração/otimização/validação com IA, meta intelligence, fichário, marketplace, trades, mensagens, notificações, perfil e comunidade. Não houve alteração em app/backend.
- **Principais riscos:** drift visual por tokens legados `manaViolet/primarySoft/mythicGold`, erros técnicos chegando ao usuário (`$e`, `Exception`, status code), ações críticas de trades sem confirmação, pouca hierarquia de confiança em marketplace/trades, e Life Counter com paleta própria muito vibrante que exige prova visual em device.
- **Principais pontos fortes:** `AppTheme` já implementa a identidade oficial Obsidian + Brass + Frost Blue; tipografia Manrope/Fraunces está centralizada; superfícies principais usam slate/obsidian; decks/IA já têm preview antes de aplicar; card images usam cache; coleções e fichário têm estados vazios e navegação funcional.
- **Blockers:** nenhum P0 encontrado nesta auditoria estática. Há P1 de UX/confiança em trades e P1 de erro user-facing cru em coleções/generate/auth/decks que devem ser tratados antes de polimento visual fino.
- **Recomendação geral:** fazer agora melhorias de confiança, microcopy, erro amigável e hierarquia de CTA; fazer depois refino estético em cards/tabs; evitar fantasy excessiva, WUBRG como tema global, arte oficial de cartas como background global e blur pesado em listas.

## What actually makes sense to improve

| melhoria | módulo | impacto | esforço | risco | recomendação | motivo |
| --- | --- | --- | --- | --- | --- | --- |
| Mapear mensagens técnicas para mensagens amigáveis | Coleções, Sets, Generate, Auth, Decks, Trades | alto | baixo-médio | baixo | Fazer agora | Reduz ansiedade e evita expor `Exception/status code` em fluxos comuns. |
| Adicionar confirmação para ações irreversíveis de trades | Trades | alto | baixo | baixo | Fazer agora | Aceitar, recusar, cancelar, disputar, finalizar e confirmar entrega afetam confiança/segurança. |
| Re-hierarquizar CTAs da Home por intenção | Home | alto | médio | baixo | Fazer agora | O posicionamento promete jogar/construir/colecionar/trocar; a Home deve vender esses caminhos sem overload. |
| Consolidar uso visual de Brass vs Frost Blue | App inteiro | alto | médio | baixo | Fazer agora | Brass deve liderar ação; Frost deve sinalizar IA/suporte. Hoje aliases legados confundem a leitura. |
| Melhorar explicabilidade de IA com custo, legalidade, curva e risco visíveis | Generate/Optimize/Validate | alto | médio | médio | Fazer agora | Otimização precisa transmitir controle e confiança, não só “mágica”. |
| Criar surface de confiança para Marketplace/Trades | Marketplace/Trades | alto | médio | baixo | Fazer agora | Preço, condição, idioma, quantidade, histórico e status precisam dominar mais que fantasia visual. |
| Unificar estados de loading/empty/error via `AppStatePanel` | App inteiro | médio | médio | baixo | Fazer depois | Já existe base; padronização reduz ruído e melhora consistência. |
| Auditar Life Counter em iPhone 15 com screenshot | Life Counter/Lotus | médio-alto | médio | baixo | Fazer depois | Visual é separado e vibrante; precisa prova real para números, contraste e performance. |
| Reduzir asset `app/assets/symbols/logo.png` se usado em runtime | Assets | médio | baixo | baixo | Fazer depois | Asset de 2MB é grande para símbolo; confirmar uso antes de otimizar. |
| Melhorar scanner pós-scan com ações explícitas | Scanner | médio | médio | médio | Fazer depois | Scanner deve transformar reconhecimento em “adicionar ao fichário/deck/troca”. |
| Refino de cards e tabs com menos borda/acento | Cards/tabs | médio | médio | baixo | Fazer depois | Polimento ajuda, mas perde ROI se feito antes de confiança/erros/CTAs. |
| Efeitos atmosféricos globais com arte de cartas | Global visual | baixo | alto | alto | Evitar | Alto risco legal/performance/contraste e desalinhado com regra do usuário. |

## What not to do

- Não usar backgrounds com arte oficial de cartas nem screenshots/imagens oficiais como textura global.
- Não usar imagens oficiais de cartas como background global; card art deve ficar como conteúdo de carta, detalhe ou thumbnail contextual.
- Não adicionar excesso de blur em listas densas, marketplace, binder, chat ou deck lists.
- Não colocar fantasia visual forte em fluxo financeiro/crítico: marketplace/trades precisam parecer claros, auditáveis e seguros.
- Não usar WUBRG como tema global; WUBRG deve representar identidade de mana, gráficos e pips.
- Não adicionar animações caras em listas densas, grids de cartas, marketplace ou mensagens.
- Não trocar Obsidian + Brass + Frost por neon/púrpura; aliases legados devem migrar semanticamente, não virar nova identidade.
- Não esconder informações críticas atrás de ícones sem label em trades, validação e optimize.

## Commands run

| comando | diretório | resultado | observações |
| --- | --- | --- | --- |
| `git status --short && find app/lib ... && find app/assets ...` | repo root | passou | Inventário inicial de telas/assets/docs. |
| `grep -RInE ... app/lib app/test app/integration_test` | repo root | passou com saída grande | `rg` não está instalado; auditoria usou `grep/find`. |
| `flutter devices` | repo root | passou | iPhone 15 Simulator disponível: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, Booted. |
| `xcrun simctl list devices available \| grep -E "iPhone 15\|Booted"` | repo root | passou | Confirmou iPhone 15 Booted e runtimes iPhone 15 Pro/Plus disponíveis. |
| `du -ah app/assets \| sort -hr \| head -80` | repo root | passou | `app/assets/symbols/logo.png` 2.0MB; Lotus 1.8MB; day/night jpg 228K/192K. |
| `flutter analyze lib test integration_test --no-version-check` | repo root | falhou | Comando executado fora de `app/`; Flutter procurou `/mtgia/lib`. Registrado como erro operacional, não app. |
| `flutter analyze lib test integration_test --no-version-check` | `app/` | falhou com 1 warning | `unused_element_parameter` em `test/features/community/providers/social_provider_test.dart:8:65`; pre-existing/test-only. |
| `flutter test test --no-version-check` | `app/` | passou | `All tests passed!` com 506+ testes; saída inclui logs de observabilidade/debug esperados. |
| Script Python de contraste WCAG aproximado | repo root | passou | Ratios calculados para tokens principais; ver seção de acessibilidade. |

## Design system review

### Paleta

`app/lib/core/theme/app_theme.dart` já contém a base correta:

- Obsidian: `backgroundAbyss #0F1115`
- Slate: `surfaceSlate #171A21`, `surfaceElevated #232735`
- Brass: `brass500 #C58B2A`, `brass400 #E0A93B`, `brass700 #8E641B`
- Frost: `frost400 #6FA8DC`, `frost600 #3E5F8A`
- Texto: `textPrimary #F3EFE3`, `textSecondary #B8C0CC`, `textHint #8A93A3`
- Semânticos e WUBRG definidos de forma consistente.

O maior problema é semântico: aliases legados (`manaViolet`, `primarySoft`, `mythicGold`) ainda são usados em muitas telas. Como hoje `manaViolet = brass500`, o app visualmente pode estar correto, mas o código comunica uma intenção antiga e facilita novos desvios.

### Tipografia

- `AppTheme.uiFontFamily = Manrope` e `displayFontFamily = Fraunces`.
- `pubspec.yaml` registra Manrope e Fraunces a partir de `assets/lotus/fonts/`.
- A estratégia é boa: Fraunces para momentos de marca/títulos, Manrope para UI.
- Risco: Life Counter nativo antigo usa `Dosis`, o que pode ser aceitável para placar, mas precisa ser tratado como subproduto separado.

### Surfaces

- App principal usa `backgroundAbyss`, `surfaceSlate`, `surfaceElevated`, `cardGradient` flat e `scaffoldGradient`.
- Cards, dialogs, bottom sheets e navigation bar estão centralizados em `AppTheme`.
- Risco: muitas telas ainda constroem containers manualmente; a família visual existe, mas não há componente único para card/list tile/action tile.

### Botões

- `ElevatedButtonTheme` usa Brass com foreground `backgroundAbyss`, contraste bom.
- Algumas telas usam `AppTheme.manaViolet` ou `primarySoft` como CTA por legado; visual atual pode bater, mas a regra mental Brass/Frost fica difusa.
- Trades usam botões tonalizados por status (`success/error/disabled`) em ações críticas; isso é útil, mas falta confirmação/explicação.

### Inputs

- Input global usa surface slate, border muted e focused border Frost. Está alinhado: Frost comunica suporte técnico/filtro/foco.
- Search e filtros em coleções/marketplace seguem padrão geral.

### Estados

- `AppStatePanel` é bom para empty/error states com accent controlado.
- Nem todas as telas usam `AppStatePanel`; algumas exibem texto bruto ou provider error direto.
- Snackbars globais usam surface elevated; snackbars locais às vezes usam semânticos diretamente.

### Hardcoded colors

Arquivos com hardcoded colors relevantes fora de `AppTheme`:

| arquivo | evidência | avaliação |
| --- | --- | --- |
| `app/lib/features/home/life_counter_screen.dart` | ~194 ocorrências `Color(...)`/`Colors.*` | Aceitável parcialmente por subproduto de placar, mas precisa tokens internos e prova de contraste. |
| `app/lib/features/home/life_counter/life_counter_native_*_sheet.dart` | overlays `Color(0x66000000)`, `Colors.white`, pink neon | Visualmente plausível para Life Counter; risco de drift se replicado fora. |
| `app/lib/features/home/lotus/lotus_visual_skin.dart` | CSS com `#78a8ff`, `#f3c46b`, rgba e blur | Aproxima Frost/Brass mas não usa hex oficial exato; precisa decisão se Lotus deve ser tokenized. |
| `app/lib/features/scanner/screens/card_scanner_screen.dart` | várias cores e camera overlay | Pode ser exceção por câmera/overlay; precisa prova runtime. |
| `app/lib/features/cards/screens/card_detail_screen.dart` | `Colors.transparent`, white fallback em pips | Pequeno risco; pips especiais X/número podem ser tokenizados. |
| `app/lib/features/binder/widgets/binder_item_editor.dart` | alguns hardcodes | Revisar por consistência em fluxo de coleção/valor. |
| `app/lib/features/trades/screens/create_trade_screen.dart`, `trade_detail_screen.dart` | `Colors.white`, status colors | Baixo risco visual; maior risco é UX/confirmação. |

## Screen/module matrix

| módulo | motivação psicológica | cor dominante esperada | cor/visual atual | classificação | risco | recomendação |
| --- | --- | --- | --- | --- | --- | --- |
| Home | Jogar, Construir, Colecionar, Trocar | Brass para ação principal, slate estrutural, Frost para IA | Hero/gradiente, CTA principal e muitos quick actions | UX OK + Visual drift | CTA overload médio | Re-hierarquizar em 4 intenções. |
| Auth/Login/Register | Entrar com segurança | Obsidian/slate, Brass no submit | Hero gradient + card elevated, bom contraste | UX OK | baixo | Melhorar erro amigável de conexão. |
| Search/Cards | Encontrar e agir | Frost para busca/filtros, Brass para ação | Search integrado em deck/binder com tabs Cards/Coleções | UX OK | médio por discoverability global | Criar entrada global clara se produto exigir Search top-level. |
| Card Detail | Aprender/decidir | Card art como conteúdo, slate para texto | Imagem grande + detalhes limpos | UX OK | baixo | Manter; não usar card art como background global. |
| Sets/Coleções | Colecionar/explorar | Frost/filtros, Brass para valor | Header hero + lista local | UX OK + User-facing error risk | médio | Mapear erros e reforçar “coleção local”. |
| Scanner | Colecionar/construir | Camera-first, Frost feedback, Brass confirmar | Câmera + overlay + OCR | Needs runtime proof | alto para câmera real | Validar em device físico; ação pós-scan mais explícita. |
| Life Counter/Lotus | Jogar | Vibrante controlado, números dominam | Lotus WebView + skin CSS própria | Needs runtime proof | contraste/performance médio | Screenshot iPhone 15 e teste mesa 2-6 jogadores. |
| Decks | Construir | Brass para criar/importar, Frost para análise | Cards e actions usam tokens, boa base | UX OK | médio | Priorizar Commander clarity e CTA hierarchy. |
| Deck Detail | Construir/Otimizar | Brass decisão, Frost análise/validar | Tabs Overview/Cartas/Análise + optimize icon | UX OK + Copy risk | médio | Mostrar legalidade/Commander/curva/preço mais perto do topo. |
| Generate AI | Aprender/Otimizar | Frost para IA, Brass para gerar/salvar | Form simples, preview depois | UX OK + raw error risk | médio | Explicar controles e custos/limites antes de gerar. |
| Optimize AI | Otimizar/controle | Frost análise, Brass aplicar | Preview antes de apply, bons sections | UX OK | médio | Mais preço/risco/legalidade e reduzir “Copiar debug” para dev. |
| Validate Deck | Confiança Commander | Frost/Success/Error | Menu e auto-validation parcial | Needs visual proof | médio | Tornar status de legalidade persistente/visível. |
| Meta Deck Intelligence | Aprender/Competitivo | Frost técnico + Brass insights valiosos | Backend/docs fortes; superfície app pouco evidente | Needs product decision | médio | Decidir onde aparece no app e qual CTA. |
| Binder/Fichário | Posse/coleção/progresso | Slate + Frost, Brass para valor | Tenho/Quero, filtros, editor | UX OK | médio | Adicionar valor total, duplicadas, wishlist/faltantes. |
| Marketplace | Trocar/Vender com confiança | Slate legível, Brass preço/valor, mínimo fantasy | Lista com filtros Troca/Venda | UX OK + trust gap | médio-alto | Card de confiança com condição/idioma/preço/owner/histórico. |
| Trades | Segurança/acordo | Trust-first, status claro | Timeline/chat/actions | Blocker P1 UX | alto | Confirmação antes de ações críticas. |
| Messages | Socializar/negociar | Slate, Frost/social quieto | Chat bubbles usam `manaViolet`/brass para “me” | Visual drift | baixo-médio | Usar Frost/Slate para social; Brass só ação decisiva. |
| Notifications | Orientar atenção | Brass para unread/action, semânticos por tipo | Tiles com typeColor e unread tint | UX OK + Visual drift | baixo | Separar unread de type color; mapear trade critical. |
| Profile | Identidade/confiança | Slate, avatar, trust indicators | Perfil editável e public profile | UX OK | médio | Adicionar sinais de confiança/trade readiness. |
| Community/Social | Socializar/descobrir | Frost/social, Brass copiar/seguir importante | Explore/follow/users | UX OK | médio | Evitar virar marketplace visual; diferenciar social vs trade. |

## Background image audit

| tela/componente | asset ou tipo de background | classificação | contraste | performance | recomendação |
| --- | --- | --- | --- | --- | --- |
| App principal `MainScaffold` | `AppTheme.scaffoldGradient` | OK atmospheric | bom | baixo | Manter. |
| Auth | `AppTheme.heroGradient` + surface card 0.94 | OK atmospheric | bom | baixo | Manter; não adicionar imagem. |
| Home hero/actions | Gradients/ShaderMask | OK atmospheric | bom provável | baixo | Reduzir quantidade de acentos, não efeito. |
| Card Detail | `CachedCardImage` como conteúdo | OK content image | depende da imagem, texto fora da imagem | baixo-médio mitigado por cache | Manter como conteúdo. |
| Fullscreen card image | `CachedCardImage` + barrier obsidian 0.94 | OK content image | texto quase ausente | baixo | Manter. |
| Deck/cards lists | Gradients flat/cards | OK solid surface | bom | baixo | Manter surfaces sólidas. |
| Marketplace/binder lists | Thumbnails de cartas + surfaces | OK content image | bom se texto fora da thumbnail | médio por lista | Manter cache e evitar background image em list item. |
| Scanner | Camera preview + overlay | Needs runtime proof | depende de luz/câmera | alto em device real | Testar câmera real; overlay precisa fallback forte. |
| Lotus WebView | CSS gradients + `day.jpg/night.jpg` em assets Lotus | OK atmospheric / Needs runtime proof | desconhecido sem screenshot | médio | Validar números sobre fundos; overlay 70-85% quando texto sobre imagem. |
| Lotus CSS blur | `backdrop-filter: blur(16px)` e pseudo-elements | Performance risk | bom provável | médio-alto em WebView | Medir jank em iPhone 15 antes de ampliar. |
| App assets `symbols/logo.png` | PNG 2.0MB | Performance risk if used | n/a | médio | Confirmar uso; otimizar se renderizado. |
| Avatar/profile/social | `NetworkImage` avatar | OK content image | texto separado | baixo | Manter; adicionar placeholder tokenizado. |
| Official card art as global bg | não encontrado | Copyright/licensing risk if added | alto risco | alto | Evitar explicitamente. |

## Accessibility and contrast audit

Contraste estático aproximado dos tokens principais:

| par | ratio aproximado | status |
| --- | ---: | --- |
| `textPrimary` em `backgroundAbyss` | 16.44:1 | OK |
| `textSecondary` em `backgroundAbyss` | 10.30:1 | OK |
| `textHint` em `backgroundAbyss` | 6.10:1 | OK |
| `brass500` em `backgroundAbyss` | 6.39:1 | OK |
| `backgroundAbyss` em `brass500` | 6.39:1 | OK para CTA |
| `brass500` em `surfaceSlate` | 5.89:1 | OK |
| `frost400` em `backgroundAbyss` | 7.48:1 | OK |
| `frost600` em `backgroundAbyss` | 2.89:1 | risco para texto normal |
| `success` em `backgroundAbyss` | 6.97:1 | OK |
| `warning` em `backgroundAbyss` | 6.72:1 | OK |
| `error` em `backgroundAbyss` | 4.46:1 | borderline para texto normal |
| white em `brass500` | 2.96:1 | não usar para texto normal |
| `textPrimary` em `brass500` | 2.57:1 | não usar |
| black/obsidian em `brass500` | 7.10/6.39:1 | OK |

Achados:

- AppTheme acerta CTA Brass com foreground `backgroundAbyss`.
- `frost600` deve ser evitado como texto pequeno.
- `error #C65A46` em fundo obsidian fica perto de 4.5:1; para texto pequeno, preferir ícone + label ou surface com fundo/error tint.
- Life Counter usa muitas cores próprias e texto branco/preto dinâmico; precisa **Needs visual proof** em telas com 2, 4 e 6 jogadores.
- Chat bubble “me” usa `manaViolet`/brass com `textPrimary` em alguns contextos similares; se Brass for fundo sólido, texto ivory não passa. Revisar visual real.

## Life Counter/Lotus audit

- **Legibilidade:** objetivo correto é números dominarem; o Life Counter nativo tem fontes grandes, haptics e layouts específicos. Porém usa paleta neon própria (`#FF0A5B`, `#4B57FF`, `#44E063`, `#40B9FF`, etc.) e muitos overlays. Isso pode ser aceitável para mesa, mas não deve contaminar app principal.
- **Lotus WebView:** `lotus_visual_skin.dart` injeta Manrope/Fraunces e reduz saturação/contraste dos cards. Boa direção. Ainda usa Frost/Brass aproximados (`#78a8ff`, `#f3c46b`) e `backdrop-filter: blur(16px)`, que exige prova de performance.
- **Estados:** `LotusLoadingOverlay` e `LotusErrorOverlay` usam `AppTheme`, mas microcopy está em inglês (`Preparing the life counter`, `Life counter unavailable`, `Retry`). Isso destoa do restante em português.
- **Performance/animações:** Lotus tem WebView + CSS + blur + assets. Testes unitários passaram, mas runtime visual/jank não foi provado nesta auditoria.
- **Coerência ManaLoom:** Bom isolamento como “jogar agora”; manter mais vivo que o app principal é adequado, desde que números e estado do jogador venham antes de decoração.

## AI/Deck intelligence audit

### Generate

- Tela `DeckGenerateScreen` é funcional e direta: formato, prompt, exemplos, gerar, preview e salvar.
- Risco: erros de geração/salvamento usam `Erro ao gerar deck: $e` e `Erro ao salvar deck: $e`, expondo exceções.
- O botão principal usa Brass via `theme.colorScheme.primary`, bom.
- Falta comunicar limites de Commander, tempo estimado, “você revisa antes de salvar”, e qualidade/risco esperado.

### Optimize

- `OptimizationPreviewDialog` é um ponto forte: mostra leitura da IA, avisos, antes/depois, remover/adicionar e só aplica após revisão.
- Usa Frost para leitura da IA e semânticos para remover/adicionar; faz sentido.
- Risco: “Copiar debug” pode aparecer para usuário final se `onCopyDebug` for passado fora de debug. Deve ser dev-only ou escondido em overflow.
- O antes/depois ainda é pouco estratégico: CMC e curva aparecem, mas preço, legalidade Commander, risco de identidade de cor, bracket, sinergia e motivo de remoção poderiam ser mais visíveis.

### Validate

- Validação está no menu do Deck Detail e auto-valida em alguns casos.
- Risco psicológico: legalidade Commander precisa ser status persistente e visível, não só ação em overflow.
- Sugestão: chip de legalidade no topo do Deck Detail, com “Validar agora” Frost quando desconhecido e Success/Error após resultado.

### Meta Deck Intelligence

- Docs backend mostram fluxo competitivo/cEDH forte e auditado.
- Superfície visual app não ficou claramente identificada nos arquivos auditados. Precisa decisão de produto: onde mostrar “metagame competitivo” sem confundir com decks públicos/community.

## Binder/Marketplace/Trades audit

### Binder/Fichário

- `BinderTabContent` tem “Tenho/Quero”, busca, filtros, add por busca e scanner; boa motivação de posse e wishlist.
- Já captura quantidade, condição, foil, trade/sale, preço, notas e idioma via editor.
- Oportunidades reais: valor total, duplicadas, faltantes, wishlist, cartas usadas em decks, cards com preço ausente e progresso por set.

### Marketplace

- `MarketplaceTabContent` tem busca, filtros Troca/Venda e card com owner/trade action.
- Visual está relativamente limpo; precisa mais trust hierarchy: condição, idioma, quantidade, preço, owner, localização/nota de troca, atualização e disponibilidade devem estar sempre escaneáveis.
- Evitar excesso mágico aqui. Marketplace deve parecer seguro e verificável.

### Trades

- `TradeDetailScreen` possui status header, participantes, itens, pagamento, rastreio, timeline, ações e chat. A estrutura é boa.
- Risco P1: ações críticas (`Aceitar`, `Recusar`, `Cancelar`, `Marcar como Enviado`, `Confirmar Entrega`, `Disputar`, `Finalizar`) disparam direto sem confirmação contextual, exceto envio que abre dialog. Isso é o maior risco de UX/confiança encontrado.
- `CreateTradeScreen` envia proposta com mensagem e pagamento, mas poderia ter resumo final antes de enviar, principalmente em venda/mixed.
- Sugestão: confirmation dialog/sheet com resumo de itens, preço, método, consequência e CTA claro.

## User-facing error audit

Padrões encontrados:

| padrão | arquivos | risco | mensagem amigável sugerida |
| --- | --- | --- | --- |
| `_error = e.toString()` | `sets_catalog_screen.dart`, `set_cards_screen.dart` | User-facing raw error | “Não foi possível carregar agora. Verifique a conexão e tente novamente.” |
| `SnackBar(content: Text('Erro ...: $e'))` | `deck_generate_screen.dart`, `sets_catalog_screen.dart`, `set_cards_screen.dart` | User-facing raw error | “A ação não pôde ser concluída. Tente novamente em instantes.” |
| `_errorMessage = 'Erro de conexão: $e'` | `auth_provider.dart`, `deck_provider.dart`, `trade_provider.dart` | User-facing raw error se exibido por screen | “Sem conexão com o servidor. Confira sua internet ou tente novamente.” |
| `provider.errorMessage!` direto | `card_search_screen.dart`, `trade_inbox_screen.dart`, `marketplace_screen.dart` | Depende do provider; pode vazar status/backend message | Mapear por erro tipado antes de mostrar. |
| `response.statusCode` em erro | `card_provider.dart`, `deck_provider_support_fetch.dart`, `sets_catalog_screen.dart`, `set_cards_screen.dart` | Copy técnica | Mostrar copy amigável e request id apenas em “Detalhes técnicos”. |
| `debugPrint` com exceções | `api_client.dart`, providers, scanner | Internal only se não mostrado | OK para logs/observability. |

## Detailed findings

### UX-001

- **classificação:** Theme inconsistency
- **prioridade:** P1
- **módulo:** Design system/app inteiro
- **arquivo(s):** `app/lib/core/theme/app_theme.dart`, múltiplas telas usando `AppTheme.manaViolet`, `primarySoft`, `mythicGold`
- **componente/trecho:** aliases legados e chamadas de CTA/status
- **problema observado:** aliases antigos continuam presentes, apesar de a identidade oficial ser Brass/Frost. Visual pode estar correto porque os aliases apontam para tokens novos, mas a semântica no código induz drift.
- **impacto psicológico/UX:** equipe tende a usar “violet/cyan/gold” como cor de sistema, enfraquecendo Brass = decisão e Frost = inteligência.
- **risco:** médio
- **sugestão de correção:** migrar call-sites gradualmente para `brass500/brass400/frost400` ou tokens semânticos (`primaryAction`, `aiAccent`, `valueAccent`) sem mudar visual.
- **validação sugerida:** `flutter analyze`, golden/smoke em Home, Deck Detail, Collection, Trades.
- **recomendação:** Fazer agora
- **esforço estimado:** médio
- **confiança da análise:** alta

### UX-002

- **classificação:** Copy/microcopy issue + User-facing error risk
- **prioridade:** P1
- **módulo:** Coleções/Sets
- **arquivo(s):** `app/lib/features/collection/screens/sets_catalog_screen.dart`, `set_cards_screen.dart`
- **componente/trecho:** `_error = e.toString()`, SnackBar com `$e`, `Exception('Falha... (${response.statusCode})')`
- **problema observado:** exceções e status code podem aparecer diretamente no AppStatePanel/SnackBar.
- **impacto psicológico/UX:** usuário percebe instabilidade técnica e não sabe o que fazer.
- **risco:** médio
- **sugestão de correção:** mapear exceptions para copy amigável e registrar detalhe técnico só em logs/observability.
- **validação sugerida:** testes de erro 500/timeout para sets catalog/detail.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo
- **confiança da análise:** alta

### UX-003

- **classificação:** User-facing error risk
- **prioridade:** P1
- **módulo:** Auth
- **arquivo(s):** `app/lib/features/auth/providers/auth_provider.dart`, `login_screen.dart`
- **componente/trecho:** `_errorMessage = 'Erro de conexão: $e'`; SnackBar mostra `authProvider.errorMessage`
- **problema observado:** exceção de rede pode chegar à tela de login/registro.
- **impacto psicológico/UX:** login é momento de confiança; erro cru passa sensação de produto quebrado.
- **risco:** médio
- **sugestão de correção:** copy amigável por classe de erro; request id/log apenas interno.
- **validação sugerida:** provider tests com timeout/socket e screen test de snackbar.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo
- **confiança da análise:** alta

### UX-004

- **classificação:** Copy/microcopy issue
- **prioridade:** P1
- **módulo:** Generate AI
- **arquivo(s):** `app/lib/features/decks/screens/deck_generate_screen.dart`
- **componente/trecho:** `Erro ao gerar deck: $e`, `Erro ao salvar deck: $e`
- **problema observado:** exceptions de IA/salvamento são exibidas diretamente.
- **impacto psicológico/UX:** IA precisa parecer confiável e controlável; erro cru quebra a confiança.
- **risco:** médio
- **sugestão de correção:** mensagens por estado: timeout, sem conexão, deck inválido, limite/indisponibilidade da IA.
- **validação sugerida:** widget tests para falha de `generateDeck`/`createDeck`.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo
- **confiança da análise:** alta

### UX-005

- **classificação:** Blocker
- **prioridade:** P1
- **módulo:** Trades
- **arquivo(s):** `app/lib/features/trades/screens/trade_detail_screen.dart`
- **componente/trecho:** `_respondTrade`, `_updateStatus`, action buttons
- **problema observado:** ações críticas disparam direto sem confirmação contextual.
- **impacto psicológico/UX:** usuários podem aceitar/recusar/finalizar/disputar por toque acidental; prejudica confiança financeira/social.
- **risco:** alto
- **sugestão de correção:** confirmation sheet antes de aceitar, recusar, cancelar, confirmar entrega, disputar e finalizar, com resumo e consequência.
- **validação sugerida:** widget tests confirmando que toque abre dialog e só executa após confirmar.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo-médio
- **confiança da análise:** alta

### UX-006

- **classificação:** Needs product decision
- **prioridade:** P1
- **módulo:** Meta Deck Intelligence
- **arquivo(s):** `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-24.md`, app surfaces não evidentes
- **componente/trecho:** metagame competitivo documentado no backend sem superfície clara no app auditado
- **problema observado:** inteligência competitiva existe como capability, mas a UX de descoberta/uso no app não está clara.
- **impacto psicológico/UX:** usuário pode não perceber diferencial “Commander inteligente/competitivo”.
- **risco:** médio
- **sugestão de correção:** decidir ponto de entrada: Deck Detail Análise, Generate, Optimize ou Community/Meta.
- **validação sugerida:** teste de navegação e copy com usuários-alvo Commander/cEDH.
- **recomendação:** Precisa decisão de produto
- **esforço estimado:** médio
- **confiança da análise:** média

### UX-007

- **classificação:** UX OK + Visual drift
- **prioridade:** P2
- **módulo:** Home
- **arquivo(s):** `app/lib/features/home/home_screen.dart`
- **componente/trecho:** Quick Actions e CTA stack
- **problema observado:** Home cobre muitas ações, mas as quatro intenções do produto não ficam igualmente claras: Jogar agora, Construir deck, Minha coleção, Trocas/mercado.
- **impacto psicológico/UX:** usuário novo pode ver “muitas funções” antes de entender “o que faço agora”.
- **risco:** médio
- **sugestão de correção:** reorganizar em quatro cards de intenção, com Brass só no principal recomendado e Frost em IA/análise.
- **validação sugerida:** widget/golden e teste de first-session navigation.
- **recomendação:** Fazer agora
- **esforço estimado:** médio
- **confiança da análise:** alta

### UX-008

- **classificação:** UX OK
- **prioridade:** P2
- **módulo:** Card Detail
- **arquivo(s):** `app/lib/features/cards/screens/card_detail_screen.dart`
- **componente/trecho:** card image, oracle text, details grid
- **problema observado:** boa separação entre imagem como conteúdo e texto em surfaces. Pequeno hardcode com `Colors.transparent/white` em fullscreen/pips genéricos.
- **impacto psicológico/UX:** tela comunica consulta e aprendizado de forma limpa.
- **risco:** baixo
- **sugestão de correção:** manter; apenas tokenizar pips genéricos se houver sprint de design debt.
- **validação sugerida:** visual proof em cartas sem imagem, cartas colorless e cartas com mana híbrida.
- **recomendação:** Fazer depois
- **esforço estimado:** baixo
- **confiança da análise:** alta

### UX-009

- **classificação:** Needs runtime proof
- **prioridade:** P1
- **módulo:** Scanner
- **arquivo(s):** `app/lib/features/scanner/screens/card_scanner_screen.dart`, `scanner_overlay.dart`, `scanned_card_preview.dart`
- **componente/trecho:** camera preview, OCR, permission, live stream throttle
- **problema observado:** fluxo depende de câmera real e iluminação; iOS Simulator não prova câmera.
- **impacto psicológico/UX:** scanner só tem valor se o reconhecimento virar ação clara e confiável.
- **risco:** alto
- **sugestão de correção:** validar device físico; reforçar ações pós-scan: adicionar ao Binder, adicionar ao Deck, ver prints, trocar/vender.
- **validação sugerida:** teste manual em device físico com 10 cartas/condições de luz.
- **recomendação:** Fazer depois
- **esforço estimado:** médio
- **confiança da análise:** média

### UX-010

- **classificação:** Performance risk
- **prioridade:** P2
- **módulo:** Assets
- **arquivo(s):** `app/assets/symbols/logo.png`, `app/pubspec.yaml`
- **componente/trecho:** asset 2.0MB incluído em `assets/symbols/`
- **problema observado:** PNG grande para símbolo/logo; risco só se renderizado em runtime ou carregado em lista.
- **impacto psicológico/UX:** jank ou consumo desnecessário degrada percepção premium.
- **risco:** médio
- **sugestão de correção:** confirmar uso; se usado, gerar versão otimizada/resolution-aware.
- **validação sugerida:** `flutter build`/asset inspection em sprint técnico; não feito nesta auditoria.
- **recomendação:** Fazer depois
- **esforço estimado:** baixo
- **confiança da análise:** média

### UX-011

- **classificação:** Performance risk + Needs runtime proof
- **prioridade:** P2
- **módulo:** Life Counter/Lotus
- **arquivo(s):** `app/lib/features/home/lotus/lotus_visual_skin.dart`
- **componente/trecho:** `backdrop-filter: ... blur(16px)`, CSS gradients/pseudo-elements
- **problema observado:** blur em WebView pode ser aceitável em overlays, mas é custo visual maior que surfaces sólidas.
- **impacto psicológico/UX:** se houver jank durante partida, o contador deixa de parecer confiável.
- **risco:** médio-alto
- **sugestão de correção:** medir no iPhone 15 e reduzir blur se afetar interação.
- **validação sugerida:** runtime iPhone 15 com 2/4/6 jogadores e gravação/screenshot.
- **recomendação:** Fazer depois
- **esforço estimado:** médio
- **confiança da análise:** média

### UX-012

- **classificação:** Copy/microcopy issue
- **prioridade:** P2
- **módulo:** Life Counter/Lotus
- **arquivo(s):** `app/lib/features/home/lotus/lotus_host_overlays.dart`
- **componente/trecho:** `Preparing the life counter`, `Life counter unavailable`, `Retry`
- **problema observado:** overlays Lotus estão em inglês enquanto o app principal usa português.
- **impacto psicológico/UX:** quebra consistência e pode parecer componente externo não integrado.
- **risco:** baixo-médio
- **sugestão de correção:** traduzir microcopy: “Preparando contador de vida”, “Contador indisponível”, “Tentar novamente”.
- **validação sugerida:** widget tests existentes de Lotus overlay.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo
- **confiança da análise:** alta

### UX-013

- **classificação:** Accessibility risk
- **prioridade:** P1
- **módulo:** Life Counter
- **arquivo(s):** `app/lib/features/home/life_counter_screen.dart`
- **componente/trecho:** `_playerColors`, múltiplas surfaces neon e texto white/black
- **problema observado:** contraste depende de cores dinâmicas, quantidade de jogadores e estados.
- **impacto psicológico/UX:** em mesa real, números precisam ser instantaneamente legíveis sob distância/luz.
- **risco:** médio-alto
- **sugestão de correção:** snapshot visual por jogador e regra luminance/token interna para texto/controles.
- **validação sugerida:** screenshot iPhone 15 e device físico, 2/4/6 players, day/night/counters.
- **recomendação:** Fazer depois
- **esforço estimado:** médio
- **confiança da análise:** média

### UX-014

- **classificação:** UX OK + improvement opportunity
- **prioridade:** P2
- **módulo:** Optimize AI
- **arquivo(s):** `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart`
- **componente/trecho:** `OptimizationPreviewDialog`
- **problema observado:** preview/apply está correto, mas a leitura poderia destacar legalidade Commander, preço, risco de curva, bracket e motivo da troca com mais hierarquia.
- **impacto psicológico/UX:** aumenta confiança e sensação de controle.
- **risco:** médio
- **sugestão de correção:** cards “Por que remover/adicionar”, “Impacto esperado”, “Risco” e “Legalidade”.
- **validação sugerida:** widget test para preview com warnings/qualityWarning.
- **recomendação:** Fazer agora
- **esforço estimado:** médio
- **confiança da análise:** alta

### UX-015

- **classificação:** Copy/microcopy issue
- **prioridade:** P2
- **módulo:** Optimize AI
- **arquivo(s):** `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart`
- **componente/trecho:** botão `Copiar debug`
- **problema observado:** debug copy pode aparecer em contexto de usuário final.
- **impacto psicológico/UX:** linguagem técnica reduz confiança em fluxo de IA.
- **risco:** baixo-médio
- **sugestão de correção:** exibir só em debug/dev ou renomear para “Copiar relatório técnico” dentro de detalhes.
- **validação sugerida:** test em release/profile flags ou widget test.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo
- **confiança da análise:** média

### UX-016

- **classificação:** UX OK + Theme inconsistency
- **prioridade:** P2
- **módulo:** Collection hub
- **arquivo(s):** `app/lib/features/collection/screens/collection_screen.dart`
- **componente/trecho:** TabBar Fichário/Marketplace/Trades/Coleções
- **problema observado:** hub é bom, mas tabs usam `manaViolet` legacy para indicador/label; psicologicamente Coleção/Marketplace/Trades têm intenções distintas.
- **impacto psicológico/UX:** coleção e comércio podem parecer uma coisa só.
- **risco:** médio
- **sugestão de correção:** manter tab bar neutra; usar cor semântica dentro de cada módulo.
- **validação sugerida:** visual smoke/narrow layouts.
- **recomendação:** Fazer depois
- **esforço estimado:** baixo
- **confiança da análise:** alta

### UX-017

- **classificação:** UX OK + opportunity
- **prioridade:** P2
- **módulo:** Binder/Fichário
- **arquivo(s):** `app/lib/features/binder/screens/binder_screen.dart`
- **componente/trecho:** tabs Tenho/Quero, filtros, add search/scan
- **problema observado:** comunica posse/wishlist, mas ainda não comunica progresso/valor/faltantes/duplicadas no topo.
- **impacto psicológico/UX:** colecionador quer senso de patrimônio e progresso.
- **risco:** baixo-médio
- **sugestão de correção:** summary cards: valor total, itens para troca, duplicadas, wishlist, usados em decks.
- **validação sugerida:** provider/widget tests de stats.
- **recomendação:** Fazer depois
- **esforço estimado:** médio
- **confiança da análise:** alta

### UX-018

- **classificação:** Theme inconsistency + Trust gap
- **prioridade:** P1
- **módulo:** Marketplace
- **arquivo(s):** `app/lib/features/binder/screens/marketplace_screen.dart`
- **componente/trecho:** filtros e `_MarketplaceCard`
- **problema observado:** Troca/Venda funcionam, mas confiança visual deve ser mais forte que estética: preço, condição, idioma, quantidade, owner e status precisam estar no primeiro scan.
- **impacto psicológico/UX:** marketplace sem sinais claros aumenta medo de erro/golpe.
- **risco:** médio-alto
- **sugestão de correção:** card de marketplace trust-first, com labels consistentes e CTA único “Propor troca/compra”.
- **validação sugerida:** widget tests de item sale/trade/mixed.
- **recomendação:** Fazer agora
- **esforço estimado:** médio
- **confiança da análise:** alta

### UX-019

- **classificação:** User-facing error risk
- **prioridade:** P1
- **módulo:** Trades
- **arquivo(s):** `app/lib/features/trades/providers/trade_provider.dart`, `trade_inbox_screen.dart`, `create_trade_screen.dart`
- **componente/trecho:** `_errorMessage = 'Erro de conexão: $e'`, provider error direto em UI/snackbar
- **problema observado:** erro técnico pode chegar a fluxo financeiro/social.
- **impacto psicológico/UX:** em trade, clareza e serenidade são obrigatórias.
- **risco:** médio
- **sugestão de correção:** error mapper específico para trade: indisponível, item não disponível, permissão, status inválido, conexão.
- **validação sugerida:** provider tests para 400/401/409/500/timeout.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo-médio
- **confiança da análise:** alta

### UX-020

- **classificação:** Visual drift
- **prioridade:** P2
- **módulo:** Messages
- **arquivo(s):** `app/lib/features/messages/screens/chat_screen.dart`
- **componente/trecho:** message bubble “me” com `AppTheme.manaViolet.withValues(alpha: 0.85)`
- **problema observado:** mensagens/social usam cor de ação primária, que deveria ser reservada para decisão/valor.
- **impacto psicológico/UX:** chat compete com CTA e reduz disciplina Brass.
- **risco:** baixo-médio
- **sugestão de correção:** usar Frost/slate para bolhas e Brass apenas para enviar/ações importantes.
- **validação sugerida:** contrast check das bolhas.
- **recomendação:** Fazer depois
- **esforço estimado:** baixo
- **confiança da análise:** média

### UX-021

- **classificação:** UX OK + Visual drift
- **prioridade:** P3
- **módulo:** Notifications
- **arquivo(s):** `app/lib/features/notifications/screens/notification_screen.dart`
- **componente/trecho:** unread tint e `_typeColor`
- **problema observado:** usa tint brass/legacy para unread e tipo; funcional, mas pode misturar importância com categoria.
- **impacto psicológico/UX:** usuário pode não distinguir “não lida” de “trade crítico”.
- **risco:** baixo
- **sugestão de correção:** unread = estrutura/weight; tipo = ícone/chip; trade critical = semântico.
- **validação sugerida:** widget test de unread/read/type.
- **recomendação:** Fazer depois
- **esforço estimado:** baixo
- **confiança da análise:** média

### UX-022

- **classificação:** Background risk
- **prioridade:** P0 if proposed, current P3
- **módulo:** Global branding
- **arquivo(s):** app inteiro
- **componente/trecho:** nenhum uso global encontrado de official card art background
- **problema observado:** não há problema atual, mas é uma tentação visual explícita a evitar.
- **impacto psicológico/UX:** card art global geraria ruído, baixa legibilidade e risco legal.
- **risco:** alto se implementado
- **sugestão de correção:** usar texturas abstratas próprias, gradients e surfaces; nunca artes oficiais como fundo global.
- **validação sugerida:** revisão de assets/licenciamento em qualquer PR visual.
- **recomendação:** Evitar
- **esforço estimado:** n/a
- **confiança da análise:** alta

### UX-023

- **classificação:** UX OK + Needs visual proof
- **prioridade:** P2
- **módulo:** Search/Cards + Coleções
- **arquivo(s):** `app/lib/features/cards/screens/card_search_screen.dart`, `sets_catalog_screen.dart`
- **componente/trecho:** TabController Cards/Coleções e route `/decks/:id/search`
- **problema observado:** busca de cartas funciona em contexto de deck/binder; “Search -> Cards | Coleções” global não é claramente uma rota primária.
- **impacto psicológico/UX:** usuário pode não descobrir busca sem estar no deck/coleção.
- **risco:** médio
- **sugestão de correção:** decidir se Search é global; se sim, criar entrada top-level ou Home action.
- **validação sugerida:** runtime navigation proof e analytics de entradas.
- **recomendação:** Precisa decisão de produto
- **esforço estimado:** médio
- **confiança da análise:** média

### UX-024

- **classificação:** UX OK
- **prioridade:** P2
- **módulo:** Deck Analysis
- **arquivo(s):** `app/lib/features/decks/widgets/deck_analysis_tab.dart`
- **componente/trecho:** AI summary, mana curve, color distribution
- **problema observado:** boa base de análise, com `quantity` considerada em curva/cor. Falta transformar problema em próxima ação (“otimizar”, “adicionar land”, “corrigir identidade”).
- **impacto psicológico/UX:** análise deve reduzir incerteza e apontar próximo passo.
- **risco:** baixo-médio
- **sugestão de correção:** adicionar action row contextual nos insights críticos.
- **validação sugerida:** widget tests de deck com curva ruim/sem commander/invalid cards.
- **recomendação:** Fazer depois
- **esforço estimado:** médio
- **confiança da análise:** alta

### UX-025

- **classificação:** Theme inconsistency
- **prioridade:** P2
- **módulo:** Life Counter native sheets
- **arquivo(s):** `app/lib/features/home/life_counter/life_counter_native_*_sheet.dart`
- **componente/trecho:** transparent backgrounds, `Color(0x66000000)`, white foregrounds, pink destructive accents
- **problema observado:** componentes do Life Counter têm linguagem visual própria; aceitável como subproduto, mas deve ficar isolado.
- **impacto psicológico/UX:** se esse estilo vazar para app principal, ManaLoom perde maturidade premium.
- **risco:** médio
- **sugestão de correção:** criar tokens internos `LifeCounterTheme` e documentar exceções.
- **validação sugerida:** screenshot sheets e contrast check.
- **recomendação:** Fazer depois
- **esforço estimado:** médio
- **confiança da análise:** média

### UX-026

- **classificação:** Accessibility risk
- **prioridade:** P2
- **módulo:** AppTheme
- **arquivo(s):** `app/lib/core/theme/app_theme.dart`
- **componente/trecho:** `frost600`, `error`, foreground em CTA
- **problema observado:** tokens principais são fortes, mas `frost600` em fundo escuro fica ~2.89:1 e `error` é borderline ~4.46:1 para texto normal.
- **impacto psicológico/UX:** textos pequenos em blue dark/error podem falhar para baixa visão.
- **risco:** médio
- **sugestão de correção:** reservar `frost600` para fundo/borda/gráfico; para texto usar `frost400`. Evitar `error` pequeno sem ícone/surface.
- **validação sugerida:** lint visual/manual contrast checks em PRs.
- **recomendação:** Fazer agora
- **esforço estimado:** baixo
- **confiança da análise:** alta

## Recommended next patches

1. Criar um `FriendlyErrorMapper` no app para Auth/Decks/Sets/Trades/Generate e substituir `$e/e.toString/statusCode` user-facing por copy amigável.
2. Adicionar confirmation sheet para ações críticas em `TradeDetailScreen` e resumo final antes de enviar proposta em `CreateTradeScreen`.
3. Migrar semanticamente usos de `manaViolet/primarySoft/mythicGold` nos módulos principais para tokens Brass/Frost claros, sem alteração visual inicial.
4. Reorganizar Home em quatro intenções: Jogar agora, Construir deck, Minha coleção, Trocas e mercado.
5. Melhorar `OptimizationPreviewDialog` com blocos explícitos de legalidade Commander, preço, risco, curva e motivo das mudanças.
6. Traduzir overlays Lotus para PT-BR e manter regression visual do Life Counter/Lotus no iPhone 15.
7. Adicionar summary/trust cards em Binder/Marketplace: valor total, condição, idioma, quantidade, owner, preço, status e disponibilidade.
8. Decidir produto para Meta Deck Intelligence: superfície própria ou integração em Deck Detail/Generate/Optimize.

## Runtime update - Life Counter/Lotus - 2026-04-30T15:30-03:00

Verdict: `PASS` no iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.

O novo `app/integration_test/life_counter_lotus_visual_runtime_proof_test.dart` abriu `LotusLifeCounterScreen` em WKWebView, validou 4 jogadores, controles `+1/-1`, legibilidade do numero principal por area renderizada, cor clara e text-shadow, ausencia de overflow horizontal, ausencia de erro WebView, persistencia do life total e reopen.

Evidencias: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_life_counter_lotus/` e handoff `app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_2026-04-30.md`.

## Not verified

- Prova visual real de Life Counter/Lotus em iPhone 15 Simulator foi executada e passou; fluxos de IA continuam separados.
- Scanner teve follow-up em device Android físico: câmera/MLKit abriram, token fallback foi corrigido e `Phyrexian Horror` token foi provado via backend live. Clean retest físico ainda precisa ficha isolada dentro do guia, sem textos externos.
- Contraste/legibilidade real de Life Counter/Lotus foi provado no cenario 4 jogadores; 2/6 jogadores e sheets especificas ficam como regressao P2.
- Performance de WebView Lotus, blur CSS e assets ainda precisa profiling dedicado se houver relato de jank.
- Uso real de `app/assets/symbols/logo.png` em runtime não foi confirmado.
- Fluxo completo register/login/generate/optimize/apply/validate não foi rodado nesta auditoria porque o pedido era first-pass sem implementação.
- Decisão de produto pendente para Search global e Meta Deck Intelligence.

## Final checklist

- Verified: design system, telas principais, assets/backgrounds, hardcoded colors, error patterns, contraste estático aproximado e testes Flutter app.
- Visual/UX gaps: CTA hierarchy da Home, semantics Brass/Frost, confiança em Marketplace/Trades, explicabilidade de IA e descoberta de Search/Meta.
- Background risks: evitar arte oficial de cartas global; Lotus blur/assets precisam runtime proof; `logo.png` 2MB precisa confirmação de uso.
- Accessibility risks: `frost600` texto, `error` pequeno, Life Counter neon/dinâmico em cenarios alem do proof 4P e bolhas/status tonalizados.
- Performance risks: Lotus WebView blur/CSS, assets grandes, camera scanner e listas com muitas thumbnails.
- Needs runtime proof: Scanner câmera real, screenshots adicionais 2P/6P/sheets Life Counter e jank/performance visual.
- Needs product decision: Meta Deck Intelligence surface, Search global, nível de separação visual do Life Counter.
- Blocked by: nenhum blocker P0; P1 UX em trades sem confirmação e P1 raw errors user-facing.
- Next step: aplicar primeiro friendly error mapping e confirmações de trade; depois re-hierarquizar Home/IA e rodar prova visual iPhone 15.
